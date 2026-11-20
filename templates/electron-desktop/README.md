# ZKBrain Electron 桌面工作站 (Windows / macOS / Linux)

> 🚀 **跨平台桌面端应用**：基于 Electron + Web Bluetooth API，可一键打包生成 macOS (`.dmg`)、Windows (`.exe`) 与 Linux (`.deb`) 原生客户端。

---

## 🌟 核心特性

1. **1:1 逐项还原官方 `DeviceScreen` + `DeviceShowTable` 控制台**：
   - 顶部操作栏（设备搜索、OTA 升级检测、SN 鉴权状态）；
   - 12 项生理指标 4x3 三色数据表（粉色、青色、黄色标准配色）；
   - 6 轴 MEMS 姿态传感看板（欧拉角 Roll/Pitch/Yaw 与四元数 Q0~Q3）；
   - NeuroSky XMW 二进制点火包（`0x15`/`0x17`）与 ZKTeco 硬件配置指令控制台；
   - 终端监控与双向回包日志。
2. **免浏览器权限限制**：
   - 桌面端直接由 Electron 主进程接管蓝牙握手与配对选择器。

---

## 🛠️ 快速启动

```bash
# 1. 安装依赖
npm install

# 2. 启动桌面应用
npm start

# 3. 打包为 Windows 可执行程序 (.exe)
npm run build:win

# 4. 打包为 macOS 镜像 (.dmg)
npm run build:mac
```
