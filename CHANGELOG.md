## 1.0.0

* Initial release of `vnpt_onvif`.
* Ported core features from ONVIF Device Manager (ODM).
* Supported WS-Discovery (UDP Multicast).
* Supported WS-Security (UsernameToken Digest).
* Supported Device Service (GetDeviceInformation, GetSystemDateAndTime).
* Supported Media Service (GetProfiles, GetStreamUri).
* Automatic Time Synchronization (Time Sync).
* Namespace-Aware XML Parsing.

## 1.0.1

* Update coding convention 

## 1.0.2

* Update README.md

## 1.0.3

* Cập nhật dò tìm thiết bị trong toàn mạng, ưu tiên IP 192.x.x.x

## 1.0.4

### Added

**Services mới:**
* `ImagingService` — `getIrCutFilter`, `setIrCutFilter`, enum `OnvifIrCutFilter` (on/off/auto)
* `PtzService` — `continuousMove`, `stop`, `sendAuxiliaryCommand`
* `DeviceIoService` — `setRelayOutputSettings`, `setRelayOutputState` (tmd namespace, endpoint `/deviceio_service`)
* `MediaService.getVideoSources()` — lấy danh sách VideoSource token

**DeviceService — methods mới:**
* `getRelayOutputs()` — danh sách relay output token
* `setRelayOutputState(token, active)` — bật/tắt relay (tds)
* `getServiceUrls()` — URL của từng ONVIF service từ GetCapabilities
* `getNetworkInterfaces()` — thông tin interface mạng (IP, subnet, DHCP mode)
* `setNetworkInterfaces(token, ip, prefixLength)` — đặt IP tĩnh, trả về `rebootNeeded`
* `setDhcp(token)` — chuyển sang DHCP, trả về `rebootNeeded`
* `getNetworkDefaultGateway()` — gateway hiện tại
* `setNetworkDefaultGateway(ip)` — đặt gateway
* `setStaticIp(...)` — convenience: `setNetworkInterfaces` + `setNetworkDefaultGateway`, trả về `rebootNeeded`
* `setDns(addresses)` — đặt DNS server thủ công
* `systemReboot()` — khởi động lại thiết bị

**Models mới:**
* `OnvifNetworkInterface` — dữ liệu interface mạng (token, IP, prefix, DHCP, MAC)
* `OnvifNetworkConfig` — snapshot cấu hình mạng tổng hợp (IP + gateway + DHCP mode + token)

**Logging:**
* Tất cả service methods log qua `OnvifLogger.instance.log(...)` với `name` theo service

### Changed

* `setStaticIp` và `setDhcp` **không còn tự gọi `systemReboot()`** — trả về `bool rebootNeeded` để caller kiểm soát thứ tự thao tác (ví dụ: cập nhật backend trước khi reboot)