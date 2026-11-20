# ZKBrain SDK 跨端避坑与 DO/DON'T 铁律 (gotchas.md)

> **核心原则**：以下收录了在真机测试、硬件兼容性、蓝牙通信与多端渲染中踩过的真实生产级血泪教训。

---

## 🛑 1. 硬件通信与协议分流避坑

### ❌ DON'T: 以为连上蓝牙设备就能直接收到脑电数据
- **陷阱**：对于 **NeuroSky MindWave** 系列硬件，物理建连成功后，**硬件不会主动发送任何脑电数据**！
- **✅ DO**:
  - SDK 内部已在建连成功后自动下发 20 字节点火包（`0x15` 开启 512Hz Raw + `0x17` 开启 8 频段）；
  - 若进行硬件调试，切勿手动关闭 Raw 流，否则将导致整个 1Hz 综合数据流被硬件截断。

### ❌ DON'T: 用户物理秒关秒开设备时频繁发起重连
- **陷阱**：NeuroSky 等设备采用物理拨动开关，关机时**硬件电容残留电量需要 2~3 秒完全放电**。如果秒关秒开，BLE 芯片处于未完全复位的死锁半状态，直接重连会百分之百超时。
- **✅ DO**:
  - 当监测到设备断开时，UI 提示用户“若重启设备，请等待 3 秒后再打开电源”。

---

## 🛑 2. 蓝牙连接状态机与断连自愈防抖

### ❌ DON'T: 在建连握手重试或自愈中向用户弹出“设备已掉线”
- **陷阱**：BLE 在周围有 2.4G 强干扰时，偶发重传是正常现象。如果一有链路抖动就弹窗，用户体验会极度糟糕。
- **✅ DO**:
  - 监听 `ZKBrainManager.disconnectedEvent`（该事件仅在设备**曾经真正连接成功就绪后**发生异常断开时发射）；
  - 界面可通过 `ZKBrainManager.connState` 观察状态，当处于 `RECONNECTING` 时，仅展示“信号自愈中”图标，严禁中断用户测量流程。

---

## 🛑 3. Compose 与 UI 渲染高频数据防卡顿

### ❌ DON'T: 直接在 Compose 顶层使用 `val raw by rawdata.collectAsState()`
- **陷阱**：`rawdata` 以 **512Hz（每 1.95 毫秒一次）** 的极高频度发射。如果在顶层声明状态变量，会导致整个 Screen 每秒 Recompose 512 次，直接触发严重的界面掉帧与 ANR 卡死！
- **✅ DO**:
  - 使用局部 `Canvas` + `remember { mutableStateListOf }` 定长 RingBuffer；
  - 或对原始波进行 10:1 抽样（Downsample）后再用于大屏展示。

---

## 🛑 4. 平台端原生权限要求

### Android 端清单声明 (AndroidManifest.xml)
Android 12 (API 31) 及以上必须声明并运行时动态申请：
```xml
<!-- 蓝牙扫描与连接 -->
<uses-permission android:name="android.permission.BLUETOOTH_SCAN"
                 android:usesPermissionFlags="neverForLocation" />
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />

<!-- 传统兼容权限 (Android 11 及以下) -->
<uses-permission android:name="android.permission.BLUETOOTH" android:maxSdkVersion="30" />
<uses-permission android:name="android.permission.BLUETOOTH_ADMIN" android:maxSdkVersion="30" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" android:maxSdkVersion="30" />
```

### iOS 端权限声明 (Info.plist)
```xml
<key>NSBluetoothAlwaysUsageDescription</key>
<string>本应用需要使用蓝牙连接脑机接口设备以获取脑电信号</string>
<key>NSBluetoothPeripheralUsageDescription</key>
<string>本应用需要使用蓝牙连接脑机接口设备以获取脑电信号</string>
```

---

## 🛑 5. 云端三表封包铁律

1. **`events.csv` 事件时序**：
   - 最外层容器事件 `recording_start` (code 1) 必须锚定在 $0\text{ms}$；
   - 静息基线事件 `resting_start` (code 51, $0\text{ms}$) 与 `resting_end` (code 52, $30000\text{ms}$) 必须保持 $\ge 30\text{s}$；
   - 容器封闭事件 `recording_end` (code 9) 必须处于最尾部。
2. **`meta.json` 真实时长对齐**：
   - 严格保证 `end_time - start_time == duration_seconds == CSV 实际行数`，否则云端算法质检将拦截判定为数据篡改。
