import '../core/onvif_client.dart';
export '../core/onvif_client.dart';

/// Base class for all ONVIF services (e.g., Device, Media, Imaging).
abstract class OnvifBaseService {
  /// The client used to communicate with the ONVIF device.
  final OnvifClient client;

  /// Creates a new [OnvifBaseService] with the given [client].
  OnvifBaseService(this.client);
}
