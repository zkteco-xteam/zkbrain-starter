# ZKBrain Starter Kit - AI 开发红线与行为准则 (AGENTS.md)

本文件是 `zkbrain-starter` 模板工程的顶级 AI 指引。当开发者使用 AI 助手（Cursor, Antigravity, Windsurf, Copilot 等）介入开发时，AI 必须严格遵循以下约定：

---

## 1. 核心上下文与契约约束（杜绝幻觉）

1. **绝对禁止瞎编脑电 API**：
   - 所有的脑机设备连接、数据消费与控制方法，必须严格参考 `.agents/skills/zkbrain-sdk-dev/references/api-signatures.md`；
   - 任何高频代码必须优先复用 `.agents/skills/zkbrain-sdk-dev/references/recipes.md` 中的 20 行黄金样板。

2. **硬件特性铁律（强制记忆）**：
   - **NeuroSky 硬件不会主动吐数据**：SDK 会在建连后自动下发 20 字节点火包（`0x15` Raw + `0x17` Band），切勿在业务层重复或误关 Raw 流；
   - **高频原始波防卡顿**：`rawdata` 是 512Hz（每秒 512 次采样），UI 绘制必须使用 Canvas 离屏缓冲或 RingBuffer，严禁在 Compose / React 顶层高频触发全屏 Re-render；
   - **蓝牙断连自愈防抖**：仅在 `disconnectedEvent` 发射时才向用户弹窗报错，建连或重连中状态显示为 `RECONNECTING`，切勿误报断开。

---

## 2. 跨端模块规范

- **Android Compose 模板**：位于 `templates/android-compose/`，基于最新 Jetpack Compose + Material 3 声明式大屏，通过国际 Maven Central 依赖引入；
- **Android Native 模板**：位于 `templates/android-native/`，纯 Kotlin 极简样板；
- **Flutter 模板**：位于 `templates/flutter/`，基于 `flutter_blue_plus` 的 Dart 跨端交互大屏；
- **华为鸿蒙模板**：位于 `templates/harmonyos/`，基于 ArkTS / Stage 模型的鸿蒙原生交互工程；
- **iOS SwiftUI 模板**：位于 `templates/ios-swiftui/`，充分利用 SKIE 提供的 `async/await` 语法糖消费 `ZKBrainManager.shared.brainData`；
- **Web 模板**：位于 `templates/web-ts/`，使用 `@zkteco/zkbrain-web-sdk`；
- **微信小程序模板**：位于 `templates/miniprogram/`，使用 `@zkteco/zkbrain-miniprogram-sdk`；
- **Windows 桌面模板**：位于 `templates/windows-desktop/`，使用 C# / Python 驱动 `zkbrain_sec.dll`。
