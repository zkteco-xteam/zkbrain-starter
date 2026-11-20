# ZKBrain Starter Kit (AI-Ready 脑机应用开发脚手架)

> 🚀 **官方开源脚手架** | 面向二次开发者与 AI 编程助手（Cursor, Antigravity, Windsurf, Copilot）的跨平台脑机接口 (BCI) 开箱即用全栈模板。

本项目是 **ZKBrain 跨平台脑机接口 SDK** 的官方公开脚手架，内置 Android Compose、Flutter、华为鸿蒙 (HarmonyOS Next)、iOS SwiftUI、Web H5、微信小程序、Windows 桌面 7 大主流平台的最简运行模板，并深度整合了 **AI 上下文工程（Skill + llms.txt + Cursorrules）**。

开发者（或您的 AI）无需关心底层复杂的硬件点火包、协议解包与加解密，克隆后**只需对 AI 说一句话，即可秒级生成专属脑电应用**！

---

## 📂 多端极简模板导航

| 平台 / 技术栈 | 模板目录 | SDK 接入形式 | 核心亮点 |
| :--- | :--- | :--- | :--- |
| **Android Compose (推荐)** | [`templates/android-compose/`](templates/android-compose/) | Maven Central (`io.github.zkteco-xteam:zkbrain-android:1.2.1`) | 现代 Jetpack Compose 声明式大屏，内置 8 频段频谱、心流与示波器 |
| **Android 原生 (Kotlin)** | [`templates/android-native/`](templates/android-native/) | Maven Central (`io.github.zkteco-xteam:zkbrain-android:1.2.1`) | 纯 Kotlin + Lifecycle 极简调用，开箱即用 |
| **Flutter 跨平台** | [`templates/flutter/`](templates/flutter/) | `flutter_blue_plus` 响应式流 | Dart 跨 Android / iOS 双端，Material 3 脑电交互大屏 |
| **华为鸿蒙 (HarmonyOS Next)** | [`templates/harmonyos/`](templates/harmonyos/) | ArkTS / Stage 模型 | 鸿蒙原生 ArkUI 声明式大屏，系统级低功耗蓝牙扫描与高帧率 Canvas |
| **原生 iOS (Swift)** | [`templates/ios-swiftui/`](templates/ios-swiftui/) | Swift Package Manager (SPM) | SwiftUI 现代声明式 UI，原生 `async/await` 消费脑电数据流 |
| **Web 浏览器 (H5)** | [`templates/web-ts/`](templates/web-ts/) | NPM (`@zkteco/zkbrain-web-sdk`) | Vite + TypeScript，基于 W3C Web Bluetooth 直连脑电设备 |
| **微信小程序** | [`templates/miniprogram/`](templates/miniprogram/) | NPM (`@zkteco/zkbrain-miniprogram-sdk`) | 原生小程序架构，内置低功耗蓝牙 (BLE) 扫描与专注度仪表盘 |
| **Windows 桌面端 (C#/Python)** | [`templates/windows-desktop/`](templates/windows-desktop/) | C++ 动态库 (`zkbrain_sec.dll`) | 原生 BLE/串口直连，支持 Python 算法开发与 C# WinUI 桌面开发 |

---

## 🤖 AI 二次开发黄金体验（3 分钟上手）

### 步骤 1：克隆本仓库并用 AI 编辑器打开
```bash
git clone https://github.com/zkteco-xteam/zkbrain-starter.git
cd zkbrain-starter
```
使用 **Cursor**、**Antigravity** 或 **Windsurf** 打开该文件夹。编辑器会自动识别根目录的 `AGENTS.md`、`.cursorrules` 与 `.agents/skills/zkbrain-sdk-dev/` 官方技能。

### 步骤 2：复制 Starter Prompt 发给 AI
在 AI 对话框中直接粘贴以下任一提示词，AI 将自动读取技能与黄金样板，零报错生成功能：

#### 💡 提示词范例 A（Android Compose 脑波监控）：
> *"请参考 templates/android-compose 模板，使用 ZKBrain SDK 为我新增一个脑电专注度训练页面。要求：包含设备扫描弹窗、一个展示专注度与放松度的仪表盘、以及一个实时跳动的 512Hz 原始脑波图。"*

#### 💡 提示词范例 B（Flutter 跨端开发）：
> *"请基于 templates/flutter 模板，用 Flutter 帮我写一个心流状态监测 App，实时监听脑电数据，当专注度超过 80 时播放鼓励动画。"*

#### 💡 提示词范例 C（鸿蒙 Next 原生）：
> *"请参考 templates/harmonyos 模板，使用 ArkUI 帮我实现一个鸿蒙脑机数据分析大屏，包含 8 频段彩色能量柱状图与疲劳指数预警。"*

---

## 📚 官方文档与资源索引
- [AI 入口契约索引 (llms.txt)](docs/llms.txt)
- [纯接口签名契约速查 (.agents/skills/zkbrain-sdk-dev/references/api-signatures.md)](.agents/skills/zkbrain-sdk-dev/references/api-signatures.md)
- [20 行黄金代码样板 (.agents/skills/zkbrain-sdk-dev/references/recipes.md)](.agents/skills/zkbrain-sdk-dev/references/recipes.md)
- [跨端避坑与 DO/DON'T 铁律 (.agents/skills/zkbrain-sdk-dev/references/gotchas.md)](.agents/skills/zkbrain-sdk-dev/references/gotchas.md)
- [多端 SDK 一行代码极速接入指南 (docs/SDK_ONE_LINE_IMPORT_GUIDE.md)](docs/SDK_ONE_LINE_IMPORT_GUIDE.md)

---

## 📄 开源与商业授权说明
- 本 Starter 模板工程遵循 **MIT License** 开源，开发者可自由修改并商用；
- 底层 `zkbrain` 跨平台 SDK 核心包由 **熵基科技脑机事业部** 提供技术支持。
