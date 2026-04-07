import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';
import 'dart:math';
import 'package:xml/xml.dart';
import '../models/onvif_device.dart';

/// A class to handle ONVIF WS-Discovery using UDP Multicast.
///
/// It sends Probe messages to '239.255.255.250' on port 3702.
class OnvifDiscovery {
  /// The standard ONVIF multicast address.
  static const String multicastAddress = '239.255.255.250';

  /// The standard ONVIF multicast port.
  static const int multicastPort = 3702;

  final StreamController<OnvifDevice> _deviceController =
      StreamController<OnvifDevice>.broadcast();

  /// A stream of [OnvifDevice] discovered in the network.
  Stream<OnvifDevice> get deviceStream => _deviceController.stream;

  /// Sends a WS-Discovery Probe message to find devices in the local network.
  ///
  /// The [timeout] defines how long to wait for responses (default: 5 seconds).
  Future<void> probe({Duration timeout = const Duration(seconds: 5)}) async {
    // Tìm địa chỉ IP Wifi hiện tại của thiết bị
    InternetAddress? wifiAddress;
    try {
      final interfaces = await NetworkInterface.list(
        includeLinkLocal: false,
        type: InternetAddressType.IPv4,
      );
      for (var interface in interfaces) {
        for (var addr in interface.addresses) {
          if (!addr.isLoopback &&
              (addr.address.startsWith('192.168.') ||
                  addr.address.startsWith('10.') ||
                  addr.address.startsWith('172.'))) {
            wifiAddress = addr;
            break;
          }
        }
        if (wifiAddress != null) break;
      }
    } catch (e) {
      developer.log('Lỗi khi lấy danh sách interface: $e', name: 'Discovery');
    }

    final bindAddr = wifiAddress ?? InternetAddress.anyIPv4;
    developer.log('Binding socket tại ${bindAddr.address}', name: 'Discovery');

    final RawDatagramSocket socket = await RawDatagramSocket.bind(bindAddr, 0);
    socket.readEventsEnabled = true;
    socket.broadcastEnabled = true;
    socket.multicastLoopback = true;

    // Join Multicast Group
    try {
      socket.joinMulticast(InternetAddress(multicastAddress));
    } catch (e) {
      // Ignore if fail
    }

    final List<String> probeMessages = [
      _buildProbeXml(null),
      _buildProbeXml('dn:NetworkVideoTransmitter'),
      _buildProbeXml('tds:Device'),
    ];

    for (var msg in probeMessages) {
      final List<int> data = utf8.encode(msg);
      socket.send(data, InternetAddress(multicastAddress), multicastPort);
      developer.log('Đã gửi Probe Multicast', name: 'Discovery');
      await Future.delayed(const Duration(milliseconds: 200));
    }

    final List<String> discoveredUuids = [];
    final timer = Timer(timeout, () => socket.close());

    socket.listen((RawSocketEvent event) {
      if (event == RawSocketEvent.read) {
        final Datagram? dg = socket.receive();
        if (dg != null) {
          final String response = utf8.decode(dg.data);
          developer.log('Nhận được phản hồi từ ${dg.address.address}',
              name: 'Discovery');
          _parseProbeResponse(response, discoveredUuids);
        }
      }
    });

    await Future.delayed(timeout + const Duration(seconds: 1));
    if (timer.isActive) timer.cancel();
    socket.close();
  }

  String _buildProbeXml(String? type) {
    final String messageId = 'uuid:${_generateUuid()}';
    final String typeElement =
        type != null ? '<wsd:Types>$type</wsd:Types>' : '<wsd:Types/>';

    return '''
<?xml version="1.0" encoding="utf-8"?>
<soap:Envelope xmlns:soap="http://www.w3.org/2003/05/soap-envelope" 
               xmlns:wsa="http://schemas.xmlsoap.org/ws/2004/08/addressing" 
               xmlns:wsd="http://schemas.xmlsoap.org/ws/2005/04/discovery" 
               xmlns:tds="http://www.onvif.org/ver10/device/wsdl"
               xmlns:dn="http://www.onvif.org/ver10/network/wsdl">
  <soap:Header>
    <wsa:MessageID>$messageId</wsa:MessageID>
    <wsa:To>urn:schemas-xmlsoap.org:ws:2005:04:discovery</wsa:To>
    <wsa:Action>http://schemas.xmlsoap.org/ws/2005/04/discovery/Probe</wsa:Action>
  </soap:Header>
  <soap:Body>
    <wsd:Probe> $typeElement </wsd:Probe>
  </soap:Body>
</soap:Envelope>
'''
        .trim();
  }

  void _parseProbeResponse(String xmlResponse, List<String> discoveredUuids) {
    try {
      String prettyXml = xmlResponse;
      try {
        final doc = XmlDocument.parse(xmlResponse);
        prettyXml = doc.toXmlString(pretty: true, indent: '  ');
      } catch (e) {
        // Nếu không parse được thì dùng bản thô
      }

      developer.log('--- NHẬN BẢN TIN DISCOVERY ---', name: 'Discovery');
      _printLongString(prettyXml);
      developer.log('-----------------------------', name: 'Discovery');

      final document = XmlDocument.parse(xmlResponse);
      const wsdNs = 'http://schemas.xmlsoap.org/ws/2005/04/discovery';
      const wsaNs = 'http://schemas.xmlsoap.org/ws/2004/08/addressing';

      final probeMatches =
          document.findAllElements('ProbeMatch', namespace: wsdNs);
      for (var match in probeMatches) {
        final endpointRef =
            match.findAllElements('EndpointReference', namespace: wsaNs).first;
        final address = endpointRef
            .findAllElements('Address', namespace: wsaNs)
            .first
            .innerText;

        if (discoveredUuids.contains(address)) continue;
        discoveredUuids.add(address);

        final xAddrs = match
            .findAllElements('XAddrs', namespace: wsdNs)
            .first
            .innerText
            .split(' ');
        final types =
            match.findAllElements('Types', namespace: wsdNs).first.innerText;
        final scopesArr = match
            .findAllElements('Scopes', namespace: wsdNs)
            .first
            .innerText
            .split(' ');

        String name = 'Unknown Device';
        for (var scope in scopesArr) {
          if (scope.contains('onvif://www.onvif.org/name/')) {
            name =
                Uri.decodeComponent(scope.split('/').last).replaceAll('_', ' ');
            break;
          }
        }

        final device = OnvifDevice(
          uuid: address,
          xAddrs: xAddrs,
          types: types,
          scopes: scopesArr.join(', '),
          name: name,
        );

        developer.log('[FOUND] Thiết bị: ${device.name}', name: 'Discovery');
        developer.log('[UUID] ${device.uuid}', name: 'Discovery');
        developer.log('[XAddrs] ${device.xAddrs}', name: 'Discovery');
        developer.log('[Types] ${device.types}', name: 'Discovery');
        developer.log('[Scopes] ${device.scopes}', name: 'Discovery');

        _deviceController.add(device);
      }
    } catch (e) {
      developer.log('Lỗi khi phân tích bản tin: $e', name: 'Discovery');
    }
  }

  String _generateUuid() {
    final random = Random();
    String generateHex(int length) {
      return List.generate(length, (i) => random.nextInt(16).toRadixString(16))
          .join();
    }

    return '${generateHex(8)}-${generateHex(4)}-4${generateHex(3)}-${(8 + random.nextInt(4)).toRadixString(16)}${generateHex(3)}-${generateHex(12)}';
  }

  void _printLongString(String text) {
    final RegExp pattern = RegExp('.{1,800}'); // Clipped at 800 characters
    pattern.allMatches(text).forEach(
        (match) => developer.log(match.group(0) ?? '', name: 'Discovery'));
  }

  void dispose() => _deviceController.close();
}
