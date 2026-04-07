/// A model representing an ONVIF device found during discovery.
class OnvifDevice {
  /// The unique identifier of the device (often a UUID or Address).
  final String uuid;

  /// The list of XAddrs (URLs) where the device services are hosted.
  final List<String> xAddrs;

  /// The types of the device (e.g., dn:NetworkVideoTransmitter).
  final String types;

  /// The scopes defined for the device.
  final String scopes;

  /// The human-readable name of the device, extracted from scopes.
  final String name;

  /// Creates a new [OnvifDevice].
  OnvifDevice({
    required this.uuid,
    required this.xAddrs,
    required this.types,
    required this.scopes,
    required this.name,
  });
}
