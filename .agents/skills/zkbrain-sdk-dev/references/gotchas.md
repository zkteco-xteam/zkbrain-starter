# ZKBrain SDK Cross-Platform Gotchas & DO/DON'T Rules (gotchas.md)
# ZKBrain SDK 跨端避坑与 DO/DON'T 铁律

> **Core Principle / 核心原则**：The following points represent battle-tested production lessons learned across real hardware compatibility, BLE protocol discrepancies, multi-platform concurrency, and UI rendering performance.
> 以下收录了在真机测试、硬件兼容性、蓝牙通信与多端渲染中踩过的真实生产级血泪教训。

---

## 🛑 1. Hardware Communication & Protocol Safeguards / 硬件通信与协议分流避坑

### ❌ DON'T: Assume connecting to Bluetooth immediately yields EEG data
### ❌ DON'T: 以为连上蓝牙设备就能直接收到脑电数据
- **Pitfall / 陷阱**: For **NeuroSky MindWave** hardware, after physical BLE connection succeeds, **the hardware will NOT actively send any EEG data**!
  对于 **NeuroSky MindWave** 系列硬件，物理建连成功后，**硬件不会主动发送任何脑电数据**！
- **✅ DO**:
  - The SDK automatically sends the 20-byte ignition packet (`0x15` for 512Hz Raw + `0x17` for 8 bands) upon connection.
    SDK 内部已在建连成功后自动下发 20 字节点火包（`0x15` 开启 512Hz Raw + `0x17` 开启 8 频段）；
  - During hardware debugging, do NOT arbitrarily disable the Raw stream, or the 1Hz composite data stream will be truncated by hardware firmware.
    若进行硬件调试，切勿手动关闭 Raw 流，否则将导致整个 1Hz 综合数据流被硬件截断。

### ❌ DON'T: Immediately reconnect when user rapidly toggles hardware power switch
### ❌ DON'T: 用户物理秒关秒开设备时频繁发起重连
- **Pitfall / 陷阱**: Devices like MindWave use physical toggle switches. When turned off, **the hardware capacitor requires 2~3 seconds to fully discharge**. If toggled off and immediately on, the BLE chip enters a half-reset deadlock state, causing 100% reconnection timeout.
  NeuroSky 等设备采用物理拨动开关，关机时**硬件电容残留电量需要 2~3 秒完全放电**。如果秒关秒开，BLE 芯片处于未完全复位的死锁半状态，直接重连会百分之百超时。
- **✅ DO**:
  - Prompt user in UI: "If restarting the device, please wait 3 seconds before powering back on."
    当监测到设备断开时，UI 提示用户：“若重启设备，请等待 3 秒后再打开电源”。

---

## 🛑 2. BLE State Machine & Auto-Healing Debounce / 蓝牙连接状态机与断连自愈防抖

### ❌ DON'T: Show "Device Disconnected" dialogs during initial retry or auto-healing
### ❌ DON'T: 在建连握手重试或自愈中向用户弹出“设备已掉线”
- **Pitfall / 陷阱**: Brief 2.4GHz interference causing packet loss or retry is normal. Triggering error dialogs on transient link jitter ruins user experience.
  BLE 在周围有 2.4G 强干扰时，偶发重传是正常现象。如果一有链路抖动就弹窗，用户体验会极度糟糕。
- **✅ DO**:
  - Listen to `ZKBrainManager.disconnectedEvent` (only emitted when a **previously ready and functioning device** encounters an abnormal link drop).
    监听 `ZKBrainManager.disconnectedEvent`（该事件仅在设备**曾经真正连接成功就绪后**发生异常断开时发射）；
  - Observe `ZKBrainManager.connState`. When `RECONNECTING`, display a subtle "Auto-healing link..." indicator without interrupting user measurement flow.
    界面通过 `ZKBrainManager.connState` 观察状态，当处于 `RECONNECTING` 时仅展示“信号自愈中”，严禁中断用户测量。

---

## 🛑 3. Compose & UI High-Frequency Stream Rendering / Compose 与 UI 渲染高频数据防卡顿

### ❌ DON'T: Declare `val raw by rawdata.collectAsState()` at Compose screen root
### ❌ DON'T: 直接在 Compose 顶层使用 `val raw by rawdata.collectAsState()`
- **Pitfall / 陷阱**: `rawdata` emits at **512Hz (every 1.95ms)**. Declaring it at screen root causes the entire Composable tree to recompose 512 times per second, triggering extreme frame drops and ANR!
  `rawdata` 以 **512Hz（每 1.95 毫秒一次）** 的极高频度发射。在顶层声明状态变量会导致整个 Screen 每秒 Recompose 512 次，直接触发掉帧与 ANR 卡死！
- **✅ DO**:
  - Use an isolated `Canvas` + `remember { mutableStateListOf }` fixed-size RingBuffer.
    使用局部 `Canvas` + `remember { mutableStateListOf }` 定长 RingBuffer；
  - Or downsample the raw wave (e.g. 10:1) before feeding to high-level UI charts.
    或对原始波进行 10:1 抽样（Downsample）后再用于大屏展示。

---

## 🛑 4. Platform Native Permissions / 平台端原生权限要求

### Android Manifest Requirements (AndroidManifest.xml)
For Android 12 (API 31) and higher, runtime permissions are mandatory:
```xml
<!-- BLE Scanning and Connection -->
<uses-permission android:name="android.permission.BLUETOOTH_SCAN"
                 android:usesPermissionFlags="neverForLocation" />
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />

<!-- Legacy permissions (Android 11 and lower) -->
<uses-permission android:name="android.permission.BLUETOOTH" android:maxSdkVersion="30" />
<uses-permission android:name="android.permission.BLUETOOTH_ADMIN" android:maxSdkVersion="30" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" android:maxSdkVersion="30" />
```

### iOS Info.plist Declarations
```xml
<key>NSBluetoothAlwaysUsageDescription</key>
<string>This app requires Bluetooth to connect to BCI headbands for EEG streaming.</string>
<key>NSBluetoothPeripheralUsageDescription</key>
<string>This app requires Bluetooth to connect to BCI headbands for EEG streaming.</string>
```

---

## 🛑 5. Cloud 3-Table Session Packing Iron Rules / 云端三表封包铁律

1. **`events.csv` Event Chronology / 事件时序**:
   - Outermost container event `recording_start` (code 1) must be fixed at $0\text{ms}$.
     最外层容器事件 `recording_start` (code 1) 必须固定在 $0\text{ms}$；
   - Baseline resting events `resting_start` (code 51, $0\text{ms}$) and `resting_end` (code 52, $30000\text{ms}$) must be $\ge 30\text{s}$.
     静息基线事件 `resting_start` 与 `resting_end` 必须保持 $\ge 30\text{s}$；
   - Final closing event `recording_end` (code 9) must terminate the package at the very end.
     容器封闭事件 `recording_end` (code 9) 必须处于最尾部封闭全包。
2. **`meta.json` Real Duration Alignment / 真实时长严格对齐**:
   - Must satisfy `end_time - start_time == duration_seconds == CSV actual rows`.
     严格保证 `end_time - start_time == duration_seconds == CSV 实际行数`，三方完全一致。
