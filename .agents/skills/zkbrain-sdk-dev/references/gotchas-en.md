# ZKBrain SDK Cross-Platform Gotchas & DO/DON'T Rules (gotchas-en.md)

> **Core Principle**: The following points represent battle-tested production lessons learned across real hardware compatibility, BLE protocol discrepancies, multi-platform concurrency, and UI rendering performance.

---

## 🛑 1. Hardware Communication & Protocol Safeguards

### ❌ DON'T: Assume connecting to Bluetooth immediately yields EEG data
- **Pitfall**: For **NeuroSky MindWave** hardware, after physical BLE connection succeeds, **the hardware will NOT actively send any EEG data**!
- **✅ DO**:
  - The SDK automatically sends the 20-byte ignition packet (`0x15` for 512Hz Raw + `0x17` for 8 bands) upon connection.
  - During hardware debugging, do NOT arbitrarily disable the Raw stream, or the 1Hz composite data stream will be truncated by hardware firmware.

### ❌ DON'T: Immediately reconnect when user rapidly toggles hardware power switch
- **Pitfall**: Devices like MindWave use physical toggle switches. When turned off, **the hardware capacitor requires 2~3 seconds to fully discharge**. If toggled off and immediately on, the BLE chip enters a half-reset deadlock state, causing 100% reconnection timeout.
- **✅ DO**:
  - Prompt user in UI: "If restarting the device, please wait 3 seconds before powering back on."

---

## 🛑 2. BLE State Machine & Auto-Healing Debounce

### ❌ DON'T: Show "Device Disconnected" dialogs during initial retry or auto-healing
- **Pitfall**: Brief 2.4GHz interference causing packet loss or retry is normal. Triggering error dialogs on transient link jitter ruins user experience.
- **✅ DO**:
  - Listen to `ZKBrainManager.disconnectedEvent` (only emitted when a **previously ready and functioning device** encounters an abnormal link drop).
  - Observe `ZKBrainManager.connState`. When `RECONNECTING`, display a subtle "Auto-healing link..." indicator without interrupting user measurement flow.

---

## 🛑 3. Compose & UI High-Frequency Stream Rendering

### ❌ DON'T: Declare `val raw by rawdata.collectAsState()` at Compose screen root
- **Pitfall**: `rawdata` emits at **512Hz (every 1.95ms)**. Declaring it at screen root causes the entire Composable tree to recompose 512 times per second, triggering extreme frame drops and ANR!
- **✅ DO**:
  - Use an isolated `Canvas` + `remember { mutableStateListOf }` fixed-size RingBuffer.
  - Or downsample the raw wave (e.g. 10:1) before feeding to high-level UI charts.

---

## 🛑 4. Platform Native Permissions

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

## 🛑 5. Cloud 3-Table Session Packing Iron Rules

1. **`events.csv` Event Chronology**:
   - Outermost container event `recording_start` (code 1) must be fixed at $0\text{ms}$.
   - Baseline resting events `resting_start` (code 51, $0\text{ms}$) and `resting_end` (code 52, $30000\text{ms}$) must be $\ge 30\text{s}$.
   - Final closing event `recording_end` (code 9) must terminate the package at the very end.
2. **`meta.json` Real Duration Alignment**:
   - Must satisfy `end_time - start_time == duration_seconds == CSV actual rows`.
