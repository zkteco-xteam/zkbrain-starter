# ZKBrain Electron Desktop Workstation (Windows / macOS / Linux)

> Cross-platform desktop application based on Electron + Web Bluetooth API. Can be packaged into macOS (`.dmg`), Windows (`.exe`), and Linux (`.deb`) native clients.

---

## Key Features

1. **1:1 Complete realization of official `DeviceScreen` + `DeviceShowTable` Console**:
   - Top action bar (device search, OTA upgrade check, license badge);
   - 12-metric 4x3 color-coded table (Pink, Cyan, Yellow standard palette);
   - 6-axis MEMS spatial attitude board (Euler angles Roll/Pitch/Yaw & Quaternions Q0~Q3);
   - NeuroSky XMW binary ignition packet (`0x15`/`0x17`) and ZKTeco hardware configuration console;
   - Terminal monitor with bidirectional packet logs.
2. **Native Bluetooth Management**:
   - Electron main process manages Bluetooth handshake and pairing selection.

---

## Quickstart

```bash
# 1. Install dependencies
npm install

# 2. Start desktop app
npm start

# 3. Build Windows executable (.exe)
npm run build:win

# 4. Build macOS disk image (.dmg)
npm run build:mac
```
