import 'package:xml/xml.dart';
import '../core/onvif_logger.dart';
import 'onvif_base_service.dart';

class OnvifProfile {
  final String token;
  final String name;

  OnvifProfile({required this.token, required this.name});
}

/// Service to handle Media (trt) operations like getting profiles and stream URIs.
class MediaService extends OnvifBaseService {
  static const _tag = 'MediaService';

  /// Creates a new [MediaService] using an [OnvifClient].
  MediaService(OnvifClient client) : super(client);

  /// Retrieves all available video profiles from the device.
  Future<List<OnvifProfile>> getProfiles() async {
    const String body =
        '<trt:GetProfiles xmlns:trt="http://www.onvif.org/ver10/media/wsdl"/>';
    final response = await client.soapRequest(body,
        action: 'http://www.onvif.org/ver10/media/wsdl/GetProfiles');

    final document = XmlDocument.parse(response);
    const trtNs = 'http://www.onvif.org/ver10/media/wsdl';
    const ttNs = 'http://www.onvif.org/ver10/schema';

    final profiles = document.findAllElements('Profiles', namespace: trtNs);

    final result = profiles.map((p) {
      return OnvifProfile(
        token: p.getAttribute('token') ?? '',
        name: p.findElements('Name', namespace: ttNs).first.innerText,
      );
    }).toList();

    OnvifLogger.instance.log(
      'GetProfiles count=${result.length} tokens=${result.map((p) => p.token).join(',')}',
      name: _tag,
    );
    return result;
  }

  Future<List<String>> getVideoSources() async {
    const String body =
        '<trt:GetVideoSources xmlns:trt="http://www.onvif.org/ver10/media/wsdl"/>';
    final response = await client.soapRequest(
      body,
      action: 'http://www.onvif.org/ver10/media/wsdl/GetVideoSources',
    );

    final document = XmlDocument.parse(response);
    const trtNs = 'http://www.onvif.org/ver10/media/wsdl';

    final result = document
        .findAllElements('VideoSources', namespace: trtNs)
        .map((e) => e.getAttribute('token') ?? '')
        .where((token) => token.isNotEmpty)
        .toList(growable: false);

    OnvifLogger.instance.log(
      'GetVideoSources count=${result.length} tokens=${result.join(',')}',
      name: _tag,
    );
    return result;
  }

  Future<String> getStreamUri(String profileToken) async {
    final String body = '''
<trt:GetStreamUri xmlns:trt="http://www.onvif.org/ver10/media/wsdl">
  <trt:StreamSetup>
    <tt:Stream xmlns:tt="http://www.onvif.org/ver10/schema">RTP-Unicast</tt:Stream>
    <tt:Transport xmlns:tt="http://www.onvif.org/ver10/schema">
      <tt:Protocol>RTSP</tt:Protocol>
    </tt:Transport>
  </trt:StreamSetup>
  <trt:ProfileToken>$profileToken</trt:ProfileToken>
</trt:GetStreamUri>
'''
        .trim();

    final response = await client.soapRequest(body,
        action: 'http://www.onvif.org/ver10/media/wsdl/GetStreamUri');

    final document = XmlDocument.parse(response);
    const trtNs = 'http://www.onvif.org/ver10/media/wsdl';
    const ttNs = 'http://www.onvif.org/ver10/schema';

    final mediaUri =
        document.findAllElements('MediaUri', namespace: trtNs).first;
    final uri = mediaUri.findElements('Uri', namespace: ttNs).first.innerText;

    OnvifLogger.instance.log(
      'GetStreamUri token=$profileToken uri=$uri',
      name: _tag,
    );
    return uri;
  }
}
