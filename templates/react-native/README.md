# ZKBrain React Native (TypeScript) 跨端脚手架

> 🚀 **跨 iOS 与 Android 原生双端**：基于 `react-native-ble-plx`，具备纯原生 BLE 驱动支持与 Android 12+ / iOS 13+ 运行时蓝牙权限核验。

---

## 🌟 核心特性

1. **1:1 逐项还原官方 `DeviceScreen` + `DeviceShowTable` 控制台**：
   - 顶部操作栏（搜索设备、OTA升级与 SN 鉴权）；
   - 12 项生理指标 4x3 三色数据表（粉色、青色、黄色标准配色）；
   - 6 轴 MEMS 姿态传感看板（欧拉角 Roll/Pitch/Yaw 与四元数 Q0~Q3）；
   - NeuroSky XMW 二进制点火包（`0x15`/`0x17`）与 ZKTeco 硬件配置指令控制台；
   - 终端监控与双向回包日志。
2. **移动双端蓝牙动态权限**：
   - Android 12+ 动态申请 `BLUETOOTH_SCAN` 与 `BLUETOOTH_CONNECT`；
   - iOS 自动弹窗提示开启蓝牙系统设置。

---

## 🛠️ 快速启动

```bash
# 1. 安装依赖
npm install

# 2. 运行 Android
npm run android

# 3. 运行 iOS (需在 macOS 下执行 pod install)
cd ios && pod install && cd ..
npm run ios
```
