import 'package:xml/xml.dart';
import '../core/onvif_logger.dart';
import 'onvif_base_service.dart';

enum OnvifIrCutFilter { on, off, auto }

class ImagingService extends OnvifBaseService {
  static const _tag = 'ImagingService';

  ImagingService(super.client);

  Future<OnvifIrCutFilter?> getIrCutFilter(String videoSourceToken) async {
    OnvifLogger.instance.log(
      'GetImagingSettings videoSource=$videoSourceToken',
      name: _tag,
    );
    final String body =
        '<timg:GetImagingSettings xmlns:timg="http://www.onvif.org/ver20/imaging/wsdl">'
        '<timg:VideoSourceToken>$videoSourceToken</timg:VideoSourceToken>'
        '</timg:GetImagingSettings>';
    final response = await client.soapRequest(
      body,
      action: 'http://www.onvif.org/ver20/imaging/wsdl/GetImagingSettings',
    );

    final document = XmlDocument.parse(response);
    const ttNs = 'http://www.onvif.org/ver10/schema';
    final element =
        document.findAllElements('IrCutFilter', namespace: ttNs).firstOrNull;
    OnvifIrCutFilter? result;
    switch (element?.innerText.trim().toUpperCase()) {
      case 'ON':
        result = OnvifIrCutFilter.on;
      case 'OFF':
        result = OnvifIrCutFilter.off;
      case 'AUTO':
        result = OnvifIrCutFilter.auto;
    }
    OnvifLogger.instance.log(
      'GetImagingSettings IrCutFilter=${result?.name ?? 'unknown'} videoSource=$videoSourceToken',
      name: _tag,
    );
    return result;
  }

  Future<void> setIrCutFilter(
    String videoSourceToken,
    OnvifIrCutFilter mode,
  ) async {
    final modeStr = switch (mode) {
      OnvifIrCutFilter.on => 'ON',
      OnvifIrCutFilter.off => 'OFF',
      OnvifIrCutFilter.auto => 'AUTO',
    };
    OnvifLogger.instance.log(
      'SetImagingSettings IrCutFilter=$modeStr videoSource=$videoSourceToken',
      name: _tag,
    );
    final String body =
        '<timg:SetImagingSettings xmlns:timg="http://www.onvif.org/ver20/imaging/wsdl">'
        '<timg:VideoSourceToken>$videoSourceToken</timg:VideoSourceToken>'
        '<timg:ImagingSettings>'
        '<tt:IrCutFilter xmlns:tt="http://www.onvif.org/ver10/schema">$modeStr</tt:IrCutFilter>'
        '</timg:ImagingSettings>'
        '<timg:ForcePersistence>false</timg:ForcePersistence>'
        '</timg:SetImagingSettings>';
    await client.soapRequest(
      body,
      action: 'http://www.onvif.org/ver20/imaging/wsdl/SetImagingSettings',
    );
    OnvifLogger.instance.log(
      'SetImagingSettings OK IrCutFilter=$modeStr videoSource=$videoSourceToken',
      name: _tag,
    );
  }
}
