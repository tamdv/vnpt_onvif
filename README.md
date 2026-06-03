# vnpt_onvif

Thư viện Flutter để giao tiếp với thiết bị ONVIF (camera IP). Hỗ trợ discovery mạng LAN, xác thực WS-Security (Digest), và đầy đủ các thao tác quản lý camera qua SOAP/XML thuần.

---

## Cài đặt

```yaml
dependencies:
  vnpt_onvif:
    path: ../vnpt_onvif   # hoặc git: { url: ... }
```

```dart
import 'package:vnpt_onvif/vnpt_onvif.dart';
```

---

## Kiến trúc

```
OnvifClient              ← HTTP/SOAP + WS-Security (Digest)
    │
    ├── DeviceService    ← Device management (tds)
    ├── DeviceIoService  ← Device I/O – relay outputs (tmd)
    ├── ImagingService   ← Imaging settings – IR cut, exposure (timg)
    ├── MediaService     ← Profiles, stream URIs, video sources (trt)
    └── PtzService       ← PTZ movement, auxiliary commands (tptz)
```

---

## Tạo client

```dart
final client = OnvifClient(
  xaddr: 'http://192.168.1.100/onvif/device_service',
  username: 'admin',
  password: 'password',
);
```

Client xử lý tự động:
- Sinh Nonce ngẫu nhiên mỗi request
- Tính PasswordDigest (Base64(SHA1(nonce + created + password)))
- Đồng bộ thời gian lệch qua `timeOffset`

---

## Discovery

```dart
final discovery = OnvifDiscovery();

discovery.deviceStream.listen((device) {
  print('${device.name} – ${device.xAddrs.first}');
});

await discovery.probe();
```

---

## DeviceService

Quản lý thiết bị qua ONVIF Device Management Service (`tds`).

```dart
final service = DeviceService(client);
```

### Thông tin thiết bị

| Method | Trả về | Mô tả |
|---|---|---|
| `getDeviceInformation()` | `Map<String, String>` | Manufacturer, Model, Serial, Firmware, HardwareId |
| `getSystemDateAndTime()` | `DateTime` | Thời gian UTC hiện tại trên thiết bị |
| `getServiceUrls()` | `Map<String, String>` | URL của từng service (Device, Media, PTZ, DeviceIO, ...) |

```dart
final info = await service.getDeviceInformation();
// → {Manufacturer: HeroSpeed, Model: IPCamera, ...}

final urls = await service.getServiceUrls();
// → {Media: http://192.168.1.100/onvif/media_service, PTZ: ..., DeviceIO: ...}
```

### Relay Output

| Method | Trả về | Mô tả |
|---|---|---|
| `getRelayOutputs()` | `List<String>` | Danh sách token relay output |
| `setRelayOutputState(token, active)` | `void` | Bật/tắt relay output |

```dart
final tokens = await service.getRelayOutputs();
// → ['RelayOutputs0']

await service.setRelayOutputState(tokens.first, active: true);
await Future.delayed(Duration(seconds: 2));
await service.setRelayOutputState(tokens.first, active: false);
```

### Cấu hình mạng

| Method | Trả về | Mô tả |
|---|---|---|
| `getNetworkInterfaces()` | `List<OnvifNetworkInterface>` | Danh sách interface với IP, subnet, DHCP mode |
| `setNetworkInterfaces(token, ip, prefixLength)` | `bool rebootNeeded` | Đặt IP tĩnh trên interface |
| `getNetworkDefaultGateway()` | `String?` | Gateway hiện tại |
| `setNetworkDefaultGateway(ip)` | `void` | Đặt gateway |
| `setDhcp(token)` | `bool rebootNeeded` | Chuyển sang chế độ DHCP |
| `setDns(addresses)` | `void` | Đặt DNS server thủ công |
| `systemReboot()` | `void` | Khởi động lại thiết bị |

> **Lưu ý:** `setNetworkInterfaces`, `setDhcp`, `setStaticIp` đều trả về `rebootNeeded`. Gọi `systemReboot()` theo ý muốn **sau khi** đã thực hiện các thao tác cần thiết (ví dụ: cập nhật backend).

#### Convenience method – đặt IP tĩnh

```dart
final interfaces = await service.getNetworkInterfaces();
final token = interfaces.first.token;

// setStaticIp = setNetworkInterfaces + setNetworkDefaultGateway
// trả về rebootNeeded, KHÔNG tự reboot
final rebootNeeded = await service.setStaticIp(
  interfaceToken: token,
  ip: '192.168.1.100',
  prefixLength: 24,   // 24 = 255.255.255.0
  gateway: '192.168.1.1',
);

// Thực hiện các thao tác trước khi reboot tại đây
// (ví dụ: cập nhật backend)

if (rebootNeeded) await service.systemReboot();
// → Kết nối mất sau dòng này
```

#### Chuyển về DHCP

```dart
final interfaces = await service.getNetworkInterfaces();
final rebootNeeded = await service.setDhcp(interfaces.first.token);

// Cập nhật backend (xóa IP cũ) trước khi reboot
if (rebootNeeded) await service.systemReboot();
```

---

## ImagingService

Điều khiển các thiết lập hình ảnh qua Imaging Service (`timg`).

```dart
final imaging = ImagingService(
  OnvifClient(xaddr: 'http://192.168.1.100/onvif/imaging_service', ...),
);
```

### IR Cut Filter

```dart
enum OnvifIrCutFilter { on, off, auto }
```

| Method | Trả về | Mô tả |
|---|---|---|
| `getIrCutFilter(videoSourceToken)` | `OnvifIrCutFilter?` | Trạng thái IR cut filter hiện tại |
| `setIrCutFilter(videoSourceToken, mode)` | `void` | Đặt trạng thái IR cut filter |

```dart
// Lấy video source token
final sources = await MediaService(client).getVideoSources();
final vsToken = sources.first;

// Đọc trạng thái hiện tại
final current = await imaging.getIrCutFilter(vsToken);
// → OnvifIrCutFilter.auto

// Toggle: ON (ban ngày) / OFF (ban đêm – bật đèn IR)
final next = current == OnvifIrCutFilter.on
    ? OnvifIrCutFilter.off
    : OnvifIrCutFilter.on;
await imaging.setIrCutFilter(vsToken, next);
```

> **Mô tả giá trị:**
> - `ON` → filter IR cut bật → chế độ ban ngày, đèn IR tắt
> - `OFF` → filter IR cut tắt → chế độ ban đêm, đèn IR bật (nếu đủ tối)
> - `AUTO` → camera tự quyết theo ánh sáng môi trường

---

## MediaService

```dart
final media = MediaService(client);
```

| Method | Trả về | Mô tả |
|---|---|---|
| `getProfiles()` | `List<OnvifProfile>` | Danh sách profile (token + name) |
| `getVideoSources()` | `List<String>` | Danh sách VideoSource token |
| `getStreamUri(profileToken)` | `String` | RTSP stream URI |

```dart
final profiles = await media.getProfiles();
final streamUri = await media.getStreamUri(profiles.first.token);
// → rtsp://admin:password@192.168.1.100/stream1

final videoSources = await media.getVideoSources();
// → ['VideoSource_1']
```

---

## PtzService

```dart
final ptz = PtzService(
  OnvifClient(xaddr: 'http://192.168.1.100/onvif/ptz_service', ...),
);
```

| Method | Trả về | Mô tả |
|---|---|---|
| `continuousMove(token, panSpeed, tiltSpeed, zoomSpeed)` | `void` | Di chuyển liên tục theo tốc độ (-1.0 đến 1.0) |
| `stop(token)` | `void` | Dừng di chuyển |
| `sendAuxiliaryCommand(token, data)` | `void` | Gửi lệnh phụ trợ |

```dart
final token = profiles.first.token;

// Pan phải 0.6s rồi trả về
await ptz.continuousMove(token, panSpeed: 0.4);
await Future.delayed(Duration(milliseconds: 600));
await ptz.stop(token);
await Future.delayed(Duration(milliseconds: 300));
await ptz.continuousMove(token, panSpeed: -0.4);
await Future.delayed(Duration(milliseconds: 600));
await ptz.stop(token);
```

#### Auxiliary Commands phổ biến

| Data | Chức năng |
|---|---|
| `tt:IRLamp\|on` | Bật đèn IR (nếu camera hỗ trợ) |
| `tt:IRLamp\|off` | Tắt đèn IR |
| `tt:IRLamp\|auto` | IR chế độ tự động |
| `tt:Wiper\|on` | Bật gạt nước (outdoor camera) |

```dart
// Thử bật đèn IR qua auxiliary command
try {
  await ptz.sendAuxiliaryCommand(token, 'tt:IRLamp|on');
} catch (_) {
  // Không phải camera nào cũng hỗ trợ
}
```

---

## DeviceIoService

Điều khiển I/O qua Device IO Service (`tmd`). Endpoint thường là `/onvif/deviceio_service` hoặc cổng khác (lấy từ `getServiceUrls()`).

```dart
final deviceIoUrl = (await DeviceService(client).getServiceUrls())['DeviceIO']
    ?? 'http://192.168.1.100/onvif/deviceio_service';

final ioService = DeviceIoService(
  OnvifClient(xaddr: deviceIoUrl, ...),
);
```

| Method | Trả về | Mô tả |
|---|---|---|
| `setRelayOutputSettings(token, mode, delayTime, idleState)` | `void` | Cấu hình relay (Monostable/Bistable, delay, idle state) |
| `setRelayOutputState(token, active)` | `void` | Bật/tắt relay qua DeviceIO |

```dart
// Cấu hình Monostable 5 giây rồi trigger
await ioService.setRelayOutputSettings(
  'RELAY_OUTPUT_000',
  mode: 'Monostable',   // tự reset sau delayTime
  delayTime: 'PT5S',    // ISO 8601: 5 giây
  idleState: 'open',    // trạng thái mặc định khi idle
);
await ioService.setRelayOutputState('RELAY_OUTPUT_000', active: true);
```

---

## Models

### `OnvifNetworkInterface`

| Field | Type | Mô tả |
|---|---|---|
| `token` | `String` | Dùng cho `setNetworkInterfaces`, `setDhcp` |
| `enabled` | `bool` | Interface có đang bật không |
| `dhcp` | `bool` | `true` nếu đang dùng DHCP |
| `ipv4Address` | `String?` | IP hiện tại (manual hoặc từ DHCP) |
| `prefixLength` | `int?` | Subnet prefix (24 = 255.255.255.0) |
| `hwAddress` | `String?` | MAC address |

### `OnvifNetworkConfig`

Model tổng hợp từ `getNetworkInterfaces()` + `getNetworkDefaultGateway()`:

| Field | Type | Mô tả |
|---|---|---|
| `interfaceToken` | `String` | Token dùng để set lại |
| `ip` | `String` | IP hiện tại |
| `prefixLength` | `int` | Subnet prefix |
| `gateway` | `String` | Gateway hiện tại |
| `isDhcp` | `bool` | Đang dùng DHCP hay IP tĩnh |

---

## Logging

Thư viện dùng `OnvifLogger` để log mọi request/response. Mặc định dùng `dart:developer.log`.

```dart
// Tích hợp với hệ thống log của app
OnvifLogger.initialize((message, {name}) {
  print('[$name] $message');
  // hoặc Firebase, Sentry, v.v.
});
```

Mỗi service log theo format:
```
[DeviceService] GetNetworkInterfaces count=1 eth0:192.168.1.100/24 dhcp=false
[PtzService] ContinuousMove token=Profile_1 pan=0.4 tilt=0.0 zoom=0.0
[ImagingService] SetImagingSettings OK IrCutFilter=OFF videoSource=VideoSource_1
```

---

## Quyền hạn

**Android** – thêm vào `AndroidManifest.xml`:
```xml
<uses-permission android:name="android.permission.CHANGE_WIFI_MULTICAST_STATE"/>
```

**iOS** – thêm vào `Info.plist`:
```xml
<key>NSLocalNetworkUsageDescription</key>
<string>Cần quyền truy cập mạng nội bộ để tìm kiếm camera ONVIF</string>
```
Và đăng ký **Multicast Entitlement** với Apple.

---

## Changelog

### Added
- `ImagingService` – `getIrCutFilter`, `setIrCutFilter`, enum `OnvifIrCutFilter`
- `PtzService` – `continuousMove`, `stop`, `sendAuxiliaryCommand`
- `DeviceIoService` – `setRelayOutputSettings`, `setRelayOutputState` (tmd namespace)
- `MediaService` – `getVideoSources`
- `DeviceService` – `getRelayOutputs`, `setRelayOutputState`, `getServiceUrls`, `getNetworkInterfaces`, `setNetworkInterfaces`, `setNetworkDefaultGateway`, `getNetworkDefaultGateway`, `setDhcp`, `setDns`, `setStaticIp` (convenience), `systemReboot`
- Model `OnvifNetworkInterface`, `OnvifNetworkConfig`
- Logging đầy đủ cho tất cả service methods qua `OnvifLogger`

### Changed
- `setStaticIp` và `setDhcp` **không tự động reboot** — trả về `bool rebootNeeded` để caller kiểm soát timing (ví dụ: cập nhật backend trước khi reboot)
