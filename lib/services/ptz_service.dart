import '../core/onvif_logger.dart';
import 'onvif_base_service.dart';

class PtzService extends OnvifBaseService {
  static const _tag = 'PtzService';

  PtzService(super.client);

  Future<void> continuousMove(
    String profileToken, {
    double panSpeed = 0.0,
    double tiltSpeed = 0.0,
    double zoomSpeed = 0.0,
  }) async {
    OnvifLogger.instance.log(
      'ContinuousMove token=$profileToken pan=$panSpeed tilt=$tiltSpeed zoom=$zoomSpeed',
      name: _tag,
    );
    final String body =
        '<tptz:ContinuousMove xmlns:tptz="http://www.onvif.org/ver20/ptz/wsdl">'
        '<tptz:ProfileToken>$profileToken</tptz:ProfileToken>'
        '<tptz:Velocity>'
        '<tt:PanTilt xmlns:tt="http://www.onvif.org/ver10/schema" x="$panSpeed" y="$tiltSpeed"/>'
        '<tt:Zoom xmlns:tt="http://www.onvif.org/ver10/schema" x="$zoomSpeed"/>'
        '</tptz:Velocity>'
        '</tptz:ContinuousMove>';
    await client.soapRequest(
      body,
      action: 'http://www.onvif.org/ver20/ptz/wsdl/ContinuousMove',
    );
  }

  Future<void> sendAuxiliaryCommand(
    String profileToken,
    String auxiliaryData,
  ) async {
    OnvifLogger.instance.log(
      'SendAuxiliaryCommand token=$profileToken data="$auxiliaryData"',
      name: _tag,
    );
    final String body =
        '<tptz:SendAuxiliaryCommand xmlns:tptz="http://www.onvif.org/ver20/ptz/wsdl">'
        '<tptz:ProfileToken>$profileToken</tptz:ProfileToken>'
        '<tptz:AuxiliaryData>$auxiliaryData</tptz:AuxiliaryData>'
        '</tptz:SendAuxiliaryCommand>';
    await client.soapRequest(
      body,
      action: 'http://www.onvif.org/ver20/ptz/wsdl/SendAuxiliaryCommand',
    );
    OnvifLogger.instance.log(
      'SendAuxiliaryCommand OK data="$auxiliaryData"',
      name: _tag,
    );
  }

  Future<void> stop(String profileToken) async {
    OnvifLogger.instance.log(
      'Stop token=$profileToken',
      name: _tag,
    );
    final String body =
        '<tptz:Stop xmlns:tptz="http://www.onvif.org/ver20/ptz/wsdl">'
        '<tptz:ProfileToken>$profileToken</tptz:ProfileToken>'
        '<tptz:PanTilt>true</tptz:PanTilt>'
        '<tptz:Zoom>false</tptz:Zoom>'
        '</tptz:Stop>';
    await client.soapRequest(
      body,
      action: 'http://www.onvif.org/ver20/ptz/wsdl/Stop',
    );
  }
}
