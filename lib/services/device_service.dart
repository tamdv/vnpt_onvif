import 'package:xml/xml.dart';
import 'onvif_base_service.dart';

/// Service to handle Device management (tds) operations.
class DeviceService extends OnvifBaseService {
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

    return {
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

    return DateTime.utc(
      int.parse(date.findElements('Year', namespace: ttNs).first.innerText),
      int.parse(date.findElements('Month', namespace: ttNs).first.innerText),
      int.parse(date.findElements('Day', namespace: ttNs).first.innerText),
      int.parse(time.findElements('Hour', namespace: ttNs).first.innerText),
      int.parse(time.findElements('Minute', namespace: ttNs).first.innerText),
      int.parse(time.findElements('Second', namespace: ttNs).first.innerText),
    );
  }
}
