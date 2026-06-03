/// Snapshot of a camera's current network configuration fetched via ONVIF.
class OnvifNetworkConfig {
  const OnvifNetworkConfig({
    required this.interfaceToken,
    required this.ip,
    required this.prefixLength,
    required this.gateway,
    required this.isDhcp,
  });

  /// Token used in SetNetworkInterfaces / setStaticIp / setDhcp.
  final String interfaceToken;

  /// Current IPv4 address (empty string if unavailable).
  final String ip;

  /// Subnet prefix length (e.g. 24 = 255.255.255.0).
  final int prefixLength;

  /// Default gateway IP (empty string if unavailable).
  final String gateway;

  /// true = currently using DHCP, false = static IP.
  final bool isDhcp;
}
