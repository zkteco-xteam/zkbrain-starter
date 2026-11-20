# ZKBrain Uni-app (Vue 3 + TypeScript) Cross-Platform Starter

> One codebase targeting 10+ platforms: simultaneously supports WeChat, Alipay, Douyin, Baidu, Kuaishou Mini-Programs, and native iOS / Android Apps.

---

## Key Features

1. **1:1 Realization of official `DeviceScreen` + `DeviceShowTable` Console**:
   - Header bar with device search, DFU OTA firmware upgrade, and license badge;
   - 12-metric 4x3 color-coded table (Pink, Cyan, Yellow standard palette);
   - 6-axis MEMS spatial attitude board (Euler angles Roll/Pitch/Yaw & Quaternions Q0~Q3);
   - NeuroSky XMW binary ignition packet (`0x15`/`0x17`) and ZKTeco hardware configuration console.
2. **Cross-Platform Bluetooth Permissions**:
   - Built-in runtime Bluetooth permission checks and prompts for WeChat, Alipay, and native Apps.

---

## Quickstart

```bash
# 1. Install dependencies
npm install

# 2. Build for WeChat Mini-Program
npm run dev:mp-weixin

# 3. Build for Alipay Mini-Program
npm run dev:mp-alipay

# 4. Run H5 Web Preview
npm run dev:h5
```
