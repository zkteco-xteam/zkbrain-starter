# ZKBrain Flutter 跨平台脑机接口开发模板

官方跨平台 Flutter 脑机接口模板工程，支持 Android 与 iOS 双端编译运行。

> **技术支持**：熵基科技脑机事业部 (ZKTeco Brain-Computer Interface Division)

---

## 🌟 核心特性

- **开箱即用**：集成 `flutter_blue_plus` 响应式低功耗蓝牙 (BLE) 扫描与连接。
- **Android & iOS 权限声明就绪**：预置 Android 12+ 运行时权限与 iOS 13+ 蓝牙权限。
- **全要素交互大屏**：
  - 1Hz 专注度 (Attention) 与 放松度 (Meditation) 进度条；
  - 脑波 8 频段绝对能量动态彩色能量柱 (Delta, Theta, Alpha, Beta, Gamma)；
  - 心流深度评估与基于 $\theta / (\alpha+\beta)$ 功率比值的疲劳预警算法；
  - 512Hz 原始脑电波 (Raw EEG, μV) CustomPaint 示波器与实时采样率统计。

---

## 🚀 极速运行

```bash
# 1. 获取依赖
flutter pub get

# 2. 运行至 Android 或 iOS 真机
flutter run
```
