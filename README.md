# VNPT ONVIF Manager - Flutter Package

Thư viện Flutter chuyên dụng để quản lý thiết bị ONVIF, được chuyển thể từ **ODM (ONVIF Device Manager)**. Hỗ trợ tìm kiếm thiết bị, xác thực bảo mật và lấy luồng video RTSP một cách chuyên nghiệp.

## Cài đặt (Installation)

Thêm package vào `pubspec.yaml` của bạn bằng cách trỏ đường dẫn (Path) hoặc thông qua Git:

```yaml
dependencies:
  vnpt_onvif:
    path: ../vnpt_onvif
```

Sau đó chạy: `flutter pub get`

## Hướng dẫn sử dụng (Usage Guide)

Chỉ cần import một dòng duy nhất để sử dụng toàn bộ tính năng:
```dart
import 'package:vnpt_onvif/vnpt_onvif.dart';
```

### 1. Tìm kiếm thiết bị (Discovery)
```dart
final discovery = OnvifDiscovery();

// Lắng nghe kết quả từ mạng LAN
discovery.deviceStream.listen((device) {
  print('Tìm thấy: ${device.name} at ${device.xAddrs.first}');
});

await discovery.probe(); // Bắt đầu quét đa hướng (Multicast)
```

### 2. Quản lý Camera (Client & Services)
```dart
final client = OnvifClient(
  xaddr: 'http://192.168.1.100/onvif/device_service',
  username: 'admin',
  password: 'password',
);

final deviceService = DeviceService(client);
final mediaService = MediaService(client);

// Lấy thông tin thiết bị
final info = await deviceService.getDeviceInformation();

// Lấy link RTSP Stream cho Profile đầu tiên
final profiles = await mediaService.getProfiles();
final streamUri = await mediaService.getStreamUri(profiles.first.token);
```

## Kiến trúc & Tính năng nổi bật

*   **⚡ Native Performance**: Không sử dụng thư viện ONVIF bên thứ ba, tối ưu hóa SOAP/XML thủ công.
*   **⏰ Time Sync**: Tự động đồng bộ thời gian với Camera để xử lý lỗi xác thực `Created` lệch múi giờ.
*   **🌐 Namespace-Aware**: Tương thích 100% với mọi hãng Camera (Hikvision, Dahua, IPC...) nhờ cơ chế parse XML theo URI.
*   **🛡️ WS-Security**: Triển khai đầy đủ UsernameToken Digest (Nonce + Created + Password SHA1).

## ⚠️ Quyền hạn (Permissions)

*   **Android**: Cần `CHANGE_WIFI_MULTICAST_STATE` trong `AndroidManifest.xml`.
*   **iOS**: Cần `NSLocalNetworkUsageDescription` và đăng ký `Multicast Entitlement` với Apple.

## 🚀 Đóng góp & Phát triển
Dự án được duy trì bởi đội ngũ **VNPT Technology**. Mọi yêu cầu hỗ trợ vui lòng liên hệ qua hệ thống Git nội bộ.
