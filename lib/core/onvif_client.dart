import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';
import 'package:intl/intl.dart';

/// A client to handle SOAP requests to ONVIF devices.
///
/// It supports WS-Security (UsernameToken Digest) and [timeOffset] sync.
class OnvifClient {
  /// The absolute URL of the device service (e.g., http://192.168.1.100/onvif/device_service).
  final String xaddr;

  /// Optional username for authentication.
  final String? username;

  /// Optional password for authentication.
  final String? password;

  /// The difference between the camera's time and the phone's time.
  ///
  /// This is used to synchronize the [created] timestamp in the SOAP header.
  Duration timeOffset = Duration.zero;

  /// Creates a new [OnvifClient].
  OnvifClient({
    required this.xaddr,
    this.username,
    this.password,
  });

  /// Sends a SOAP 1.2 request to the device.
  ///
  /// [body] is the XML fragment within the <soap:Body>.
  /// [action] is the optional SOAPAction header URI.
  Future<String> soapRequest(String body, {String? action}) async {
    final String soapEnvelope = '''
<?xml version="1.0" encoding="utf-8"?>
<soap:Envelope xmlns:soap="http://www.w3.org/2003/05/soap-envelope" 
               xmlns:tds="http://www.onvif.org/ver10/device/wsdl" 
               xmlns:trt="http://www.onvif.org/ver10/media/wsdl"
               xmlns:tt="http://www.onvif.org/ver10/schema"
               xmlns:wsse="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd" 
               xmlns:wsu="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd">
  ${_buildHeader()}
  <soap:Body>
    $body
  </soap:Body>
</soap:Envelope>
'''
        .trim();

    final response = await http.post(
      Uri.parse(xaddr),
      headers: {
        'Content-Type': 'application/soap+xml; charset=utf-8',
        if (action != null) 'SOAPAction': action,
      },
      body: soapEnvelope,
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return response.body;
    } else {
      throw Exception(
          'SOAP Request failed with status: ${response.statusCode}\n${response.body}');
    }
  }

  String _buildHeader() {
    if (username == null || password == null) return '';

    final String nonce = _generateNonce();
    final DateTime now = DateTime.now().toUtc().add(timeOffset);
    final String created = DateFormat("yyyy-MM-dd'T'HH:mm:ss'Z'").format(now);
    final String passwordDigest =
        _generatePasswordDigest(nonce, created, password!);

    return '''
  <soap:Header>
    <wsse:Security xmlns:wsse="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd" 
                   xmlns:wsu="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd">
      <wsse:UsernameToken>
        <wsse:Username>$username</wsse:Username>
        <wsse:Password Type="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-username-token-profile-1.0#PasswordDigest">$passwordDigest</wsse:Password>
        <wsse:Nonce EncodingType="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-soap-message-security-1.0#Base64Binary">$nonce</wsse:Nonce>
        <wsu:Created>$created</wsu:Created>
      </wsse:UsernameToken>
    </wsse:Security>
  </soap:Header>
''';
  }

  String _generateNonce() {
    final random = Random.secure();
    final values = List<int>.generate(16, (i) => random.nextInt(256));
    return base64.encode(values);
  }

  String _generatePasswordDigest(
      String nonce, String created, String password) {
    final List<int> nonceBytes = base64.decode(nonce);
    final List<int> createdBytes = utf8.encode(created);
    final List<int> passwordBytes = utf8.encode(password);

    final List<int> combined = [
      ...nonceBytes,
      ...createdBytes,
      ...passwordBytes,
    ];

    return base64.encode(sha1.convert(combined).bytes);
  }
}
