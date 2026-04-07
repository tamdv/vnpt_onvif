import 'package:flutter/material.dart';
import 'package:vnpt_onvif/vnpt_onvif.dart';

void main() {
  runApp(const OnvifManagerApp());
}

class OnvifManagerApp extends StatelessWidget {
  const OnvifManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ONVIF Flutter Manager',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.indigo, brightness: Brightness.dark),
        useMaterial3: true,
      ),
      home: const DiscoveryPage(),
    );
  }
}

class DiscoveryPage extends StatefulWidget {
  const DiscoveryPage({super.key});

  @override
  State<DiscoveryPage> createState() => _DiscoveryPageState();
}

class _DiscoveryPageState extends State<DiscoveryPage> {
  final OnvifDiscovery _discovery = OnvifDiscovery();
  final List<OnvifDevice> _devices = [];
  bool _isScanning = false;

  @override
  void initState() {
    super.initState();
    _discovery.deviceStream.listen((device) {
      if (!mounted) return;
      setState(() {
        if (!_devices.any((d) => d.uuid == device.uuid)) {
          _devices.add(device);
        }
      });
    });
    _startScan();
  }

  void _startScan() async {
    setState(() {
      _devices.clear();
      _isScanning = true;
    });
    await _discovery.probe();
    if (mounted) {
      setState(() {
        _isScanning = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ONVIF Devices'),
        actions: [
          if (_isScanning)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else
            IconButton(icon: const Icon(Icons.refresh), onPressed: _startScan),
        ],
      ),
      body: _devices.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.videocam_off, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                      _isScanning
                          ? 'Searching for devices...'
                          : 'No devices found',
                      style: const TextStyle(fontSize: 18, color: Colors.grey)),
                ],
              ),
            )
          : ListView.builder(
              itemCount: _devices.length,
              itemBuilder: (context, index) {
                final device = _devices[index];
                return ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.videocam)),
                  title: Text(device.name),
                  subtitle: Text(device.xAddrs.first),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            DeviceDetailsPage(device: device)),
                  ),
                );
              },
            ),
    );
  }
}

class DeviceDetailsPage extends StatefulWidget {
  final OnvifDevice device;
  const DeviceDetailsPage({super.key, required this.device});

  @override
  State<DeviceDetailsPage> createState() => _DeviceDetailsPageState();
}

class _DeviceDetailsPageState extends State<DeviceDetailsPage> {
  Map<String, String>? _info;
  List<OnvifProfile>? _profiles;
  bool _isLoading = false;
  String? _error;

  final TextEditingController _userController =
      TextEditingController(text: 'admin');
  final TextEditingController _passController =
      TextEditingController(text: 'Aa123456');

  @override
  void initState() {
    super.initState();
    _fetchInfo();
  }

  Future<void> _fetchInfo() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      print('DEBUG: --- ĐANG KẾT NỐI CAMERA ---');
      print('DEBUG: URL: ${widget.device.xAddrs.first}');
      print('DEBUG: User: ${_userController.text}');
      print('DEBUG: Pass: ${_passController.text}');
      print('DEBUG: -------------------------');

      final client = OnvifClient(
        xaddr: widget.device.xAddrs.first,
        username: _userController.text,
        password: _passController.text,
      );
      final devService = DeviceService(client);
      final mediaService = MediaService(client);

      // Bước 1: Đồng bộ thời gian (Time Sync)
      try {
        final cameraTime = await devService.getSystemDateAndTime();
        final phoneTime = DateTime.now().toUtc();
        client.timeOffset = cameraTime.difference(phoneTime);
        print('DEBUG: --- ĐỒNG BỘ THỜI GIAN ---');
        print('DEBUG: Giờ điện thoại (UTC): $phoneTime');
        print('DEBUG: Giờ Camera (UTC): $cameraTime');
        print('DEBUG: Độ lệch (Offset): ${client.timeOffset}');
      } catch (e) {
        print(
            'DEBUG: Không thể lấy giờ Camera (có thể do lỗi mạng hoặc không hỗ trợ): $e');
        // Vẫn tiếp tục thử kết nối bằng giờ điện thoại nếu không lấy được giờ camera
      }

      final info = await devService.getDeviceInformation();
      final profiles = await mediaService.getProfiles();

      print('DEBUG: --- KẾT NỐI THÀNH CÔNG ---');

      print('\n${info.toString()}\n');

      print('DEBUG: Nhà SX: ${info['Manufacturer']}');
      print('DEBUG: Model: ${info['Model']}');
      print('DEBUG: Firmware: ${info['FirmwareVersion']}');
      print('DEBUG: Serial: ${info['SerialNumber']}');
      print('DEBUG: Số lượng Profile: ${profiles.length}');
      for (var p in profiles) {
        print('DEBUG:  - Profile: ${p.name} (Token: ${p.token})');
      }
      print('DEBUG: -------------------------');

      setState(() {
        _info = info;
        _profiles = profiles;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error =
            'Lỗi kết nối: ${e.toString()}\n(Vui lòng kiểm tra Username/Password hoặc cài đặt ONVIF trên Camera)';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.device.name)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Xác thực Camera',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    TextField(
                      controller: _userController,
                      decoration: const InputDecoration(
                          labelText: 'Username', icon: Icon(Icons.person)),
                    ),
                    TextField(
                      controller: _passController,
                      decoration: const InputDecoration(
                          labelText: 'Password', icon: Icon(Icons.lock)),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: _fetchInfo,
                      icon: const Icon(Icons.login),
                      label: const Text('Kết nối & Tải thông tin'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_error != null)
              Text(_error!, style: const TextStyle(color: Colors.red))
            else if (_info != null) ...[
              const Text('Thông tin phần cứng',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              _buildInfoTile('Manufacturer', _info!['Manufacturer']),
              _buildInfoTile('Model', _info!['Model']),
              _buildInfoTile('Firmware', _info!['FirmwareVersion']),
              _buildInfoTile('Serial', _info!['SerialNumber']),
            ],
            if (_profiles != null) ...[
              _buildSectionTitle('Video Profiles'),
              ..._profiles!.map((p) => ListTile(
                    leading: const Icon(Icons.video_settings),
                    title: Text(p.name),
                    subtitle: Text('Token: ${p.token}'),
                    onTap: () => _showRtspDialog(context, p.token,
                        _userController.text, _passController.text),
                  )),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Container(
      padding: const EdgeInsets.all(16),
      width: double.infinity,
      color: Colors.indigo.withOpacity(0.2),
      child: Text(title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
    );
  }

  Widget _buildInfoTile(String label, String? value) {
    return ListTile(
      title:
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      subtitle: Text(value ?? 'N/A', style: const TextStyle(fontSize: 16)),
    );
  }

  void _showRtspDialog(BuildContext context, String profileToken, String user,
      String pass) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final client = OnvifClient(
        xaddr: widget.device.xAddrs.first,
        username: user,
        password: pass,
      );
      final mediaService = MediaService(client);
      final uri = await mediaService.getStreamUri(profileToken);
      print('DEBUG: URI: $uri');

      if (mounted) {
        Navigator.pop(context); // Đóng Loading
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('RTSP Stream URI'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Bạn có thể dùng link này trong VLC Player:'),
                const SizedBox(height: 10),
                SelectableText(uri,
                    style: const TextStyle(
                        color: Colors.indigo, fontWeight: FontWeight.bold)),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Đóng'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Đóng Loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không lấy được URI: $e')),
        );
      }
    }
  }
}
