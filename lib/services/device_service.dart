import 'package:xml/xml.dart';
import '../core/onvif_logger.dart';
import '../models/onvif_network_interface.dart';
import 'onvif_base_service.dart';

/// Service to handle Device management (tds) operations.
class DeviceService extends OnvifBaseService {
  static const _tag = 'DeviceService';

  DeviceService(super.client);

  /// Retrieves the device information (Manufacturer, Model, Serial, etc.).
  Future<Map<String, String>> getDeviceInformation() async {
    const String body = '<tds:GetDeviceInformation/>';
    final response = await client.soapRequest(body,
        action: 'http://www.onvif.org/ver10/device/wsdl/GetDeviceInformation');

    final document = XmlDocument.parse(response);
    const tdsNs = 'http://www.onvif.org/ver10/device/wsdl';
    final element = document
        .findAllElements('GetDeviceInformationResponse', namespace: tdsNs)
        .first;

    final result = {
      'Manufacturer': element
          .findElements('Manufacturer', namespace: tdsNs)
          .first
          .innerText,
      'Model': element.findElements('Model', namespace: tdsNs).first.innerText,
      'FirmwareVersion': element
          .findElements('FirmwareVersion', namespace: tdsNs)
          .first
          .innerText,
      'SerialNumber': element
          .findElements('SerialNumber', namespace: tdsNs)
          .first
          .innerText,
      'HardwareId':
          element.findElements('HardwareId', namespace: tdsNs).first.innerText,
    };
    OnvifLogger.instance.log(
      'GetDeviceInformation manufacturer=${result['Manufacturer']} model=${result['Model']} serial=${result['SerialNumber']}',
      name: _tag,
    );
    return result;
  }

  Future<List<String>> getRelayOutputs() async {
    const String body = '<tds:GetRelayOutputs/>';
    final response = await client.soapRequest(body,
        action: 'http://www.onvif.org/ver10/device/wsdl/GetRelayOutputs');

    final document = XmlDocument.parse(response);
    const tdsNs = 'http://www.onvif.org/ver10/device/wsdl';

    final result = document
        .findAllElements('RelayOutputs', namespace: tdsNs)
        .map((e) => e.getAttribute('token') ?? '')
        .where((token) => token.isNotEmpty)
        .toList(growable: false);

    OnvifLogger.instance.log(
      'GetRelayOutputs count=${result.length} tokens=${result.join(',')}',
      name: _tag,
    );
    return result;
  }

  Future<void> setRelayOutputState(
    String token, {
    bool active = true,
  }) async {
    final logicalState = active ? 'active' : 'inactive';
    OnvifLogger.instance.log(
      'SetRelayOutputState token=$token state=$logicalState',
      name: _tag,
    );
    final String body = '<tds:SetRelayOutputState>'
        '<tds:RelayOutputToken>$token</tds:RelayOutputToken>'
        '<tds:LogicalState>$logicalState</tds:LogicalState>'
        '</tds:SetRelayOutputState>';
    await client.soapRequest(body,
        action: 'http://www.onvif.org/ver10/device/wsdl/SetRelayOutputState');
    OnvifLogger.instance.log(
      'SetRelayOutputState OK token=$token',
      name: _tag,
    );
  }

  /// Returns service URLs extracted from GetCapabilities.
  /// Keys: 'Device', 'Events', 'Imaging', 'Media', 'PTZ', 'DeviceIO', etc.
  Future<Map<String, String>> getServiceUrls() async {
    const String body =
        '<tds:GetCapabilities>'
        '<tds:Category>All</tds:Category>'
        '</tds:GetCapabilities>';
    final response = await client.soapRequest(
      body,
      action: 'http://www.onvif.org/ver10/device/wsdl/GetCapabilities',
    );

    final document = XmlDocument.parse(response);
    const ttNs = 'http://www.onvif.org/ver10/schema';
    final result = <String, String>{};

    for (final name in ['Device', 'Events', 'Imaging', 'Media', 'PTZ', 'Analytics']) {
      final el = document.findAllElements(name, namespace: ttNs).firstOrNull;
      final xaddr = el?.findElements('XAddr', namespace: ttNs).firstOrNull;
      if (xaddr != null) result[name] = xaddr.innerText.trim();
    }

    for (final name in ['DeviceIO', 'Recording', 'Search', 'Replay', 'Receiver']) {
      final el = document.findAllElements(name, namespace: ttNs).firstOrNull;
      final xaddr = el?.findElements('XAddr', namespace: ttNs).firstOrNull;
      if (xaddr != null) result[name] = xaddr.innerText.trim();
    }

    OnvifLogger.instance.log(
      'GetCapabilities services=${result.keys.join(',')}',
      name: _tag,
    );
    return result;
  }

  Future<DateTime> getSystemDateAndTime() async {
    const String body = '<tds:GetSystemDateAndTime/>';
    final response = await client.soapRequest(body,
        action: 'http://www.onvif.org/ver10/device/wsdl/GetSystemDateAndTime');

    final document = XmlDocument.parse(response);
    const ttNs = 'http://www.onvif.org/ver10/schema';

    final systemDateAndTimeTo =
        document.findAllElements('SystemDateAndTime', namespace: ttNs).first;
    final utcTime =
        systemDateAndTimeTo.findElements('UTCDateTime', namespace: ttNs).first;

    final time = utcTime.findElements('Time', namespace: ttNs).first;
    final date = utcTime.findElements('Date', namespace: ttNs).first;

    final result = DateTime.utc(
      int.parse(date.findElements('Year', namespace: ttNs).first.innerText),
      int.parse(date.findElements('Month', namespace: ttNs).first.innerText),
      int.parse(date.findElements('Day', namespace: ttNs).first.innerText),
      int.parse(time.findElements('Hour', namespace: ttNs).first.innerText),
      int.parse(time.findElements('Minute', namespace: ttNs).first.innerText),
      int.parse(time.findElements('Second', namespace: ttNs).first.innerText),
    );
    OnvifLogger.instance.log(
      'GetSystemDateAndTime result=$result',
      name: _tag,
    );
    return result;
  }

  /// Returns the list of network interfaces on the device.
  Future<List<OnvifNetworkInterface>> getNetworkInterfaces() async {
    const String body = '<tds:GetNetworkInterfaces/>';
    final response = await client.soapRequest(
      body,
      action: 'http://www.onvif.org/ver10/device/wsdl/GetNetworkInterfaces',
    );

    final document = XmlDocument.parse(response);
    const tdsNs = 'http://www.onvif.org/ver10/device/wsdl';
    const ttNs = 'http://www.onvif.org/ver10/schema';
    final result = <OnvifNetworkInterface>[];

    for (final iface in document.findAllElements('NetworkInterfaces', namespace: tdsNs)) {
      final token = iface.getAttribute('token') ?? '';
      final enabled = iface.findElements('Enabled', namespace: ttNs).firstOrNull?.innerText.trim().toLowerCase() == 'true';
      final hwAddress = iface.findElements('HwAddress', namespace: ttNs).firstOrNull?.innerText.trim();

      final ipv4Config = iface.findAllElements('Config', namespace: ttNs).firstOrNull;
      final dhcp = ipv4Config?.findElements('DHCP', namespace: ttNs).firstOrNull?.innerText.trim().toLowerCase() == 'true';

      final manualIp = ipv4Config?.findAllElements('Manual', namespace: ttNs).firstOrNull;
      final dhcpIp = ipv4Config?.findAllElements('FromDHCP', namespace: ttNs).firstOrNull;
      final ipNode = manualIp ?? dhcpIp;
      final ipv4Address = ipNode?.findElements('Address', namespace: ttNs).firstOrNull?.innerText.trim();
      final prefixStr = ipNode?.findElements('PrefixLength', namespace: ttNs).firstOrNull?.innerText.trim();

      result.add(OnvifNetworkInterface(
        token: token,
        enabled: enabled,
        dhcp: dhcp,
        ipv4Address: (ipv4Address == null || ipv4Address.isEmpty) ? null : ipv4Address,
        prefixLength: prefixStr != null ? int.tryParse(prefixStr) : null,
        hwAddress: (hwAddress == null || hwAddress.isEmpty) ? null : hwAddress,
      ));
    }

    OnvifLogger.instance.log(
      'GetNetworkInterfaces count=${result.length} ${result.map((i) => '${i.token}:${i.ipv4Address}/${i.prefixLength} dhcp=${i.dhcp}').join(' ')}',
      name: _tag,
    );
    return result;
  }

  /// Sets a static IPv4 address on the given interface.
  /// Returns true if the camera requires a reboot to apply changes.
  Future<bool> setNetworkInterfaces(
    String interfaceToken, {
    required String ip,
    required int prefixLength,
  }) async {
    OnvifLogger.instance.log(
      'SetNetworkInterfaces token=$interfaceToken ip=$ip/$prefixLength',
      name: _tag,
    );
    final String body =
        '<tds:SetNetworkInterfaces>'
        '<tds:InterfaceToken>$interfaceToken</tds:InterfaceToken>'
        '<tds:NetworkInterface>'
        '<tt:IPv4>'
        '<tt:Enabled>true</tt:Enabled>'
        '<tt:Manual>'
        '<tt:Address>$ip</tt:Address>'
        '<tt:PrefixLength>$prefixLength</tt:PrefixLength>'
        '</tt:Manual>'
        '<tt:DHCP>false</tt:DHCP>'
        '</tt:IPv4>'
        '</tds:NetworkInterface>'
        '</tds:SetNetworkInterfaces>';
    final response = await client.soapRequest(
      body,
      action: 'http://www.onvif.org/ver10/device/wsdl/SetNetworkInterfaces',
    );

    final document = XmlDocument.parse(response);
    const tdsNs = 'http://www.onvif.org/ver10/device/wsdl';
    final rebootNeeded = document
            .findAllElements('RebootNeeded', namespace: tdsNs)
            .firstOrNull
            ?.innerText
            .trim()
            .toLowerCase() ==
        'true';
    OnvifLogger.instance.log(
      'SetNetworkInterfaces OK ip=$ip/$prefixLength rebootNeeded=$rebootNeeded',
      name: _tag,
    );
    return rebootNeeded;
  }

  /// Switches the interface to DHCP mode.
  /// Returns true if the camera requires a reboot to apply changes.
  /// Call [systemReboot] manually after any necessary pre-reboot operations.
  Future<bool> setDhcp(String interfaceToken) async {
    OnvifLogger.instance.log(
      'SetDhcp token=$interfaceToken',
      name: _tag,
    );
    final String body =
        '<tds:SetNetworkInterfaces>'
        '<tds:InterfaceToken>$interfaceToken</tds:InterfaceToken>'
        '<tds:NetworkInterface>'
        '<tt:IPv4>'
        '<tt:Enabled>true</tt:Enabled>'
        '<tt:DHCP>true</tt:DHCP>'
        '</tt:IPv4>'
        '</tds:NetworkInterface>'
        '</tds:SetNetworkInterfaces>';
    final response = await client.soapRequest(
      body,
      action: 'http://www.onvif.org/ver10/device/wsdl/SetNetworkInterfaces',
    );

    final document = XmlDocument.parse(response);
    const tdsNs = 'http://www.onvif.org/ver10/device/wsdl';
    final rebootNeeded = document
            .findAllElements('RebootNeeded', namespace: tdsNs)
            .firstOrNull
            ?.innerText
            .trim()
            .toLowerCase() ==
        'true';
    OnvifLogger.instance.log(
      'SetDhcp OK rebootNeeded=$rebootNeeded',
      name: _tag,
    );
    return rebootNeeded;
  }

  /// Returns the current default IPv4 gateway address, or null if unavailable.
  Future<String?> getNetworkDefaultGateway() async {
    const String body = '<tds:GetNetworkDefaultGateway/>';
    final response = await client.soapRequest(
      body,
      action:
          'http://www.onvif.org/ver10/device/wsdl/GetNetworkDefaultGateway',
    );

    final document = XmlDocument.parse(response);
    const tdsNs = 'http://www.onvif.org/ver10/device/wsdl';
    final value = document
        .findAllElements('IPv4Address', namespace: tdsNs)
        .firstOrNull
        ?.innerText
        .trim();
    final result = (value == null || value.isEmpty) ? null : value;
    OnvifLogger.instance.log(
      'GetNetworkDefaultGateway gateway=${result ?? 'none'}',
      name: _tag,
    );
    return result;
  }

  /// Sets the default IPv4 gateway.
  Future<void> setNetworkDefaultGateway(String ipv4Address) async {
    OnvifLogger.instance.log(
      'SetNetworkDefaultGateway gateway=$ipv4Address',
      name: _tag,
    );
    final String body =
        '<tds:SetNetworkDefaultGateway>'
        '<tds:IPv4Address>$ipv4Address</tds:IPv4Address>'
        '</tds:SetNetworkDefaultGateway>';
    await client.soapRequest(
      body,
      action:
          'http://www.onvif.org/ver10/device/wsdl/SetNetworkDefaultGateway',
    );
    OnvifLogger.instance.log(
      'SetNetworkDefaultGateway OK gateway=$ipv4Address',
      name: _tag,
    );
  }

  /// Sets DNS servers manually.
  Future<void> setDns(List<String> ipv4Addresses) async {
    OnvifLogger.instance.log(
      'SetDNS servers=${ipv4Addresses.join(',')}',
      name: _tag,
    );
    final dnsEntries = ipv4Addresses
        .map(
          (ip) =>
              '<tds:DNSManual>'
              '<tt:Type>IPv4</tt:Type>'
              '<tt:IPv4Address>$ip</tt:IPv4Address>'
              '</tds:DNSManual>',
        )
        .join();
    final String body =
        '<tds:SetDNS>'
        '<tds:FromDHCP>false</tds:FromDHCP>'
        '$dnsEntries'
        '</tds:SetDNS>';
    await client.soapRequest(
      body,
      action: 'http://www.onvif.org/ver10/device/wsdl/SetDNS',
    );
    OnvifLogger.instance.log(
      'SetDNS OK servers=${ipv4Addresses.join(',')}',
      name: _tag,
    );
  }

  /// Convenience: sets static IP + gateway.
  /// Returns true if the camera requires a reboot to apply changes.
  /// Call [systemReboot] manually after any necessary pre-reboot operations.
  Future<bool> setStaticIp({
    required String interfaceToken,
    required String ip,
    required int prefixLength,
    required String gateway,
  }) async {
    OnvifLogger.instance.log(
      'setStaticIp token=$interfaceToken ip=$ip/$prefixLength gateway=$gateway',
      name: _tag,
    );
    final rebootNeeded = await setNetworkInterfaces(
      interfaceToken,
      ip: ip,
      prefixLength: prefixLength,
    );
    await setNetworkDefaultGateway(gateway);
    OnvifLogger.instance.log(
      'setStaticIp done rebootNeeded=$rebootNeeded',
      name: _tag,
    );
    return rebootNeeded;
  }

  /// Reboots the device. Connection will be lost after this call.
  Future<void> systemReboot() async {
    OnvifLogger.instance.log('SystemReboot', name: _tag);
    const String body = '<tds:SystemReboot/>';
    await client.soapRequest(
      body,
      action: 'http://www.onvif.org/ver10/device/wsdl/SystemReboot',
    );
    OnvifLogger.instance.log('SystemReboot sent', name: _tag);
  }
}
