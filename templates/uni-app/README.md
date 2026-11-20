# ZKBrain Uni-app (Vue 3 + TypeScript) 跨全端脚手架

> 🚀 **一套代码，发布 10+ 平台**：同时支持微信小程序、支付宝小程序、抖音/头条小程序、百度小程序、快手小程序与 iOS / Android 原生 App。

---

## 🌟 核心特性

1. **1:1 逐项还原官方 `DeviceScreen` + `DeviceShowTable` 控制台**：
   - 顶部搜索设备、DFU 固件升级与 SN 鉴权状态；
   - 12 项生理指标 4x3 三色数据表（粉色、青色、黄色标准配色）；
   - 6 轴 MEMS 姿态传感看板（欧拉角 Roll/Pitch/Yaw 与四元数 Q0~Q3）；
   - NeuroSky XMW 二进制点火包（`0x15`/`0x17`）与 ZKTeco 硬件配置指令控制台。
2. **跨平台原生蓝牙权限自愈**：
   - 内置微信/支付宝/App 蓝牙运行时权限自动核验与引导弹窗。

---

## 🛠️ 快速启动

```bash
# 1. 安装依赖
npm install

# 2. 编译为微信小程序
npm run dev:mp-weixin

# 3. 编译为支付宝小程序
npm run dev:mp-alipay

# 4. 运行 H5 网页预览
npm run dev:h5
```
