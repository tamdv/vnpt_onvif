class OnvifNetworkInterface {
  const OnvifNetworkInterface({
    required this.token,
    required this.enabled,
    required this.dhcp,
    this.ipv4Address,
    this.prefixLength,
    this.hwAddress,
  });

  /// Interface token used in SetNetworkInterfaces (e.g. 'eth0', 'NetworkInterface_1').
  final String token;

  final bool enabled;

  /// true = currently using DHCP.
  final bool dhcp;

  /// Current IPv4 address (manual or from DHCP).
  final String? ipv4Address;

  /// Subnet prefix length: 24 → 255.255.255.0, 16 → 255.255.0.0.
  final int? prefixLength;

  final String? hwAddress;

  @override
  String toString() =>
      'OnvifNetworkInterface(token=$token, ip=$ipv4Address/$prefixLength, dhcp=$dhcp)';
}
