# ZKBrain Unity 3D / XR 脑控交互脚手架

> 🎮 **专为游戏开发、VR/XR (Apple Vision Pro, Meta Quest, Pico 4) 与 3D 念力交互打造**：内置实时专注力控制物体念力浮空、粒子光效反馈与 1:1 还原的 `DeviceScreen + DeviceShowTable` 控制台。

---

## 🌟 核心特性

1. **脑控念力悬浮小球 (`ForceLevitationController.cs`)**：
   - 实时监听脑电专注度 (Attention 0~100)；
   - 专注度越高，3D 物体悬浮越高，伴随光晕强弱与颜色平滑渐变（蓝 -> 黄）；
   - 开箱即用，可直接挂载到任何 3D 游戏物体上。
2. **1:1 设备管理控制台 (`DeviceScreenUI.cs`)**：
   - 完整还原 4x3 三色脑电 Spectrum 表格（粉色、青色、黄色）；
   - 6 轴 MEMS 欧拉角与四元数空间姿态实时映射；
   - NeuroSky XMW 二进制点火包与硬件指令下发终端。
3. **多平台发布**：
   - 支持 Windows / Mac Standalone、Android / iOS 原生打包、Meta Quest 2/3/Pro、Pico 4、Apple Vision Pro。

---

## 🛠️ 快速接入指南

1. 打开 Unity 编辑器 (推荐 Unity 2021.3 LTS / 2022.3 LTS / Unity 6)；
2. 将 `Assets/Scripts/` 拖入您的 Unity 工程 `Assets/` 目录；
3. 在 Hierarchy 场景中创建一个空物体，挂载 `ZKBrainBleBridge.cs` 与 `DeviceScreenUI.cs`；
4. 创建一个 3D Sphere 小球，挂载 `ForceLevitationController.cs`，点击 Play 即可开始脑控念力悬浮体验！
