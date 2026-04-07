import 'package:flutter_test/flutter_test.dart';
import 'package:vnpt_onvif/vnpt_onvif.dart';

void main() {
  test('OnvifDeviceInfo model creation', () {
    final device = OnvifDevice(
      uuid: 'uuid-123',
      xAddrs: ['http://1.1.1.1'],
      types: 'dn:NetworkVideoTransmitter',
      scopes: 'onvif://www.onvif.org/name/Test_Camera',
      name: 'Test Camera',
    );
    expect(device.name, 'Test Camera');
    expect(device.uuid, 'uuid-123');
  });
}
