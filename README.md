# ZKBrain Starter Kit (AI-Ready 脑机应用开发脚手架)

[English](README_EN.md) | [中文](README.md)

> 🚀 **官方开源脚手架** | 面向二次开发者与 AI 编程助手（Cursor, Antigravity, Windsurf, Copilot）的跨平台脑机接口 (BCI) 开箱即用全栈模板。

本项目是 **ZKBrain 跨平台脑机接口 SDK** 的官方公开脚手架，全面覆盖 **13 大主流开发平台与生态**（涵盖移动原生、全网跨端、轻应用、专业桌面、Unity 游戏/XR、Python 科研算法与树莓派工业边缘计算），统一采用 **1:1 官方 `DeviceScreen + DeviceShowTable` 标准 UI 视觉**，并深度整合了 **AI 上下文工程（Skill + llms.txt + Cursorrules + 中国主流 AI 开发工具规范）**。

开发者（或您的 AI）无需关心底层复杂的硬件点火包、协议解包与加解密，克隆后**只需对 AI 说一句话，即可秒级生成专属脑电应用**！

---

## 📂 多端全栈模板导航 (13 大主流生态)

### 1. 📱 移动原生开发 (Mobile Native)
| 平台 / 技术栈 | 模板目录 | SDK 接入形式 | 核心亮点 |
| :--- | :--- | :--- | :--- |
| **Android Compose (推荐)** | [`templates/android-compose/`](templates/android-compose/) | Maven Central (`io.github.zkteco-xteam:zkbrain-android:1.2.1`) | 现代 Jetpack Compose 声明式大屏，内置 8 频段频谱、MEMS 姿态与运行时蓝牙权限 |
| **华为鸿蒙 (HarmonyOS Next)** | [`templates/harmonyos/`](templates/harmonyos/) | ArkTS / Stage 模型 | 鸿蒙原生 ArkUI 声明式大屏，系统级低功耗蓝牙扫描与 1:1 三色数据看板 |
| **原生 iOS (Swift)** | [`templates/ios-swiftui/`](templates/ios-swiftui/) | Swift Package Manager (SPM) | SwiftUI 现代声明式 UI，原生 `async/await` 消费脑电数据流与系统授权拦截 |

### 2. 🚀 跨端与全网小程序 (Cross-Platform & MiniProgram)
| 平台 / 技术栈 | 模板目录 | SDK 接入形式 | 核心亮点 |
| :--- | :--- | :--- | :--- |
| **Flutter 跨平台** | [`templates/flutter/`](templates/flutter/) | `flutter_blue_plus` 响应式流 | Dart 跨 Android / iOS 双端，1:1 克隆三色脑电数据表与指令终端 |
| **Uni-app (Vue 3 + TS)** | [`templates/uni-app/`](templates/uni-app/) | Vue 3 + TypeScript | **一套代码发布 10+ 平台**：同时支持微信/支付宝/抖音/百度小程序及 iOS/Android App |
| **React Native (TS)** | [`templates/react-native/`](templates/react-native/) | `react-native-ble-plx` | 跨 iOS/Android 全球主流技术栈，内置动态蓝牙权限与完整控制台 |
| **微信小程序** | [`templates/miniprogram/`](templates/miniprogram/) | NPM (`@zkteco/zkbrain-miniprogram-sdk`) | 原生微信小程序架构，内置低功耗蓝牙 (BLE) 扫描与 1:1 三色仪表盘 |
| **Web 浏览器 (H5)** | [`templates/web-ts/`](templates/web-ts/) | NPM (`@zkteco/zkbrain-web-sdk`) | Vite + TypeScript，基于 W3C Web Bluetooth 直连脑电设备 |

### 3. 💻 桌面端与专业工作站 (Desktop Workstation)
| 平台 / 技术栈 | 模板目录 | SDK 接入形式 | 核心亮点 |
| :--- | :--- | :--- | :--- |
| **Electron 跨平台桌面端** | [`templates/electron-desktop/`](templates/electron-desktop/) | Electron + Web Bluetooth | 一键打包 Windows (`.exe`)、macOS (`.dmg`) 与 Linux (`.deb`) 商业分析软件 |
| **Windows 桌面端 (C#/Python)** | [`templates/windows-desktop/`](templates/windows-desktop/) | C++ 动态库 (`zkbrain_sec.dll`) | 原生 BLE/串口直连，内置 Python Tkinter 可视化大屏与 C# WinUI 桌面工程 |

### 4. 🎮 游戏、XR、科研算法与 AIoT 边缘计算
| 平台 / 技术栈 | 模板目录 | SDK 接入形式 | 核心亮点 |
| :--- | :--- | :--- | :--- |
| **Unity 3D / XR 脑控** | [`templates/unity/`](templates/unity/) | Unity C# 桥接器 | **脑控念力悬浮小球 Demo**：专注度越高物体悬浮越高，支持 Meta Quest / Pico / Vision Pro |
| **Python 科研算法工作站** | [`templates/python-research/`](templates/python-research/) | MNE-Python / Jupyter | 0.5-50Hz 带通滤波、Welch PSD 功率谱密度分析，一键导出国际标准 **EDF+** 与 CSV 数据集 |
| **树莓派 / Linux IoT 边缘网关** | [`templates/iot-raspberrypi/`](templates/iot-raspberrypi/) | Python Bleak + RPi.GPIO | 智慧工地/车载预警守护进程，疲劳超限触发硬件 GPIO 蜂鸣器，自带局域网 Web 监控大屏 |

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
