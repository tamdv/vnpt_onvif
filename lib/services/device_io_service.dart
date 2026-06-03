import '../core/onvif_logger.dart';
import 'onvif_base_service.dart';

/// Service for ONVIF DeviceIO operations (tmd namespace).
/// Endpoint: /onvif/deviceio_service
class DeviceIoService extends OnvifBaseService {
  static const _tag = 'DeviceIoService';

  DeviceIoService(super.client);

  /// Configures relay output settings.
  /// [mode]: 'Monostable' (auto-reset after delay) or 'Bistable' (latching).
  /// [delayTime]: ISO 8601 duration, e.g. 'PT5S' = 5 seconds.
  /// [idleState]: 'open' (normally open) or 'closed' (normally closed).
  Future<void> setRelayOutputSettings(
    String relayOutputToken, {
    String mode = 'Monostable',
    String delayTime = 'PT5S',
    String idleState = 'open',
  }) async {
    OnvifLogger.instance.log(
      'SetRelayOutputSettings token=$relayOutputToken mode=$mode delay=$delayTime idleState=$idleState',
      name: _tag,
    );
    final String body =
        '<tmd:SetRelayOutputSettings xmlns:tmd="http://www.onvif.org/ver10/deviceIO/wsdl">'
        '<tmd:RelayOutputToken>$relayOutputToken</tmd:RelayOutputToken>'
        '<tmd:Properties>'
        '<tt:Mode xmlns:tt="http://www.onvif.org/ver10/schema">$mode</tt:Mode>'
        '<tt:DelayTime xmlns:tt="http://www.onvif.org/ver10/schema">$delayTime</tt:DelayTime>'
        '<tt:IdleState xmlns:tt="http://www.onvif.org/ver10/schema">$idleState</tt:IdleState>'
        '</tmd:Properties>'
        '</tmd:SetRelayOutputSettings>';
    await client.soapRequest(
      body,
      action:
          'http://www.onvif.org/ver10/deviceIO/wsdl/SetRelayOutputSettings',
    );
    OnvifLogger.instance.log(
      'SetRelayOutputSettings OK token=$relayOutputToken',
      name: _tag,
    );
  }

  /// Sets the logical state of a relay output.
  /// [active]: true = active (trigger), false = inactive (reset).
  Future<void> setRelayOutputState(
    String relayOutputToken, {
    bool active = true,
  }) async {
    final logicalState = active ? 'active' : 'inactive';
    OnvifLogger.instance.log(
      'SetRelayOutputState token=$relayOutputToken state=$logicalState',
      name: _tag,
    );
    final String body =
        '<tmd:SetRelayOutputState xmlns:tmd="http://www.onvif.org/ver10/deviceIO/wsdl">'
        '<tmd:RelayOutputToken>$relayOutputToken</tmd:RelayOutputToken>'
        '<tmd:LogicalState>$logicalState</tmd:LogicalState>'
        '</tmd:SetRelayOutputState>';
    await client.soapRequest(
      body,
      action: 'http://www.onvif.org/ver10/deviceIO/wsdl/SetRelayOutputState',
    );
    OnvifLogger.instance.log(
      'SetRelayOutputState OK token=$relayOutputToken',
      name: _tag,
    );
  }
}
