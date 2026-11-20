# ZKBrain React Native (TypeScript) Cross-Platform Starter

> Cross-platform iOS and Android starter based on `react-native-ble-plx`, supporting native BLE communication with Android 12+ and iOS 13+ runtime permissions.

---

## Key Features

1. **1:1 Realization of official `DeviceScreen` + `DeviceShowTable` Console**:
   - Header action bar (device scan, OTA check, and license badge);
   - 12-metric 4x3 color-coded table (Pink, Cyan, Yellow standard palette);
   - 6-axis MEMS spatial attitude board (Euler angles Roll/Pitch/Yaw & Quaternions Q0~Q3);
   - NeuroSky XMW binary ignition packet (`0x15`/`0x17`) and ZKTeco hardware configuration console;
   - Terminal monitor with bidirectional packet logs.
2. **Dynamic Mobile Bluetooth Permissions**:
   - Android 12+ dynamic request for `BLUETOOTH_SCAN` and `BLUETOOTH_CONNECT`;
   - iOS automatic system prompt for Bluetooth authorization.

---

## Quickstart

```bash
# 1. Install dependencies
npm install

# 2. Run on Android
npm run android

# 3. Run on iOS (requires macOS and pod install)
cd ios && pod install && cd ..
npm run ios
```
