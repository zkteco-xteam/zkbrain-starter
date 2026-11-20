# ZKBrain 华为鸿蒙 (HarmonyOS Next) 脑机接口模板

官方华为鸿蒙 Next (ArkTS / Stage 模型) 脑机接口原生工程。

> **技术支持**：熵基科技脑机事业部 (ZKTeco Brain-Computer Interface Division)

---

## 🌟 核心特性

- **纯原生 ArkUI 声明式大屏**：支持手机、折叠屏与平板响应式适配。
- **系统级蓝牙权限声明**：在 `module.json5` 中声明 `ohos.permission.USE_BLUETOOTH` 与 `DISCOVER_BLUETOOTH`。
- **全景数据指标呈现**：
  - 1Hz 专注度 (Attention) 与 放松度 (Meditation) 动态进度条；
  - 脑波 8 频段绝对能量动态彩色柱 (Delta, Theta, Alpha, Beta, Gamma)；
  - 心流状态与疲劳预警评估模型；
  - 512Hz 原始脑电波 (Raw EEG) 原生 Canvas 实时高帧率示波器。

---

## 🚀 极速运行

在 **DevEco Studio** 中直接打开本目录，连接鸿蒙 Next 真机或模拟器，点击运行即可。
