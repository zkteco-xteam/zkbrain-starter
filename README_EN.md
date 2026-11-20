# ZKBrain Starter Kit (AI-Ready BCI Application Scaffolding)

[English](README_EN.md) | [中文](README.md)

> 🚀 **Official Open-Source Scaffolding** | Ready-to-use cross-platform Brain-Computer Interface (BCI) templates for secondary developers and AI coding assistants (Cursor, Antigravity, Windsurf, Copilot).

This repository is the official starter kit for the **ZKBrain Cross-Platform BCI SDK**, fully covering **14 major developer ecosystems** (Mobile Native, Cross-Platform Mobile & MiniProgram, Web & Light Apps, Professional Desktop, Unity 3D / XR, Python Neuroscience Research, and Linux IoT Edge Computing). All templates adhere to the unified **1:1 `DeviceScreen + DeviceShowTable` standard UI visual architecture**, and are deeply integrated with **AI context engineering (Skills + llms.txt + Cursorrules + Chinese/Global AI guidelines)**.

Developers (or your AI assistants) do not need to deal with low-level binary ignition packets, protocol decoding, or cryptography. Simply clone and give your AI a single prompt to generate production-ready BCI applications!

---

## 📂 Cross-Platform Template Directory (14 Major Ecosystems)

### 1. 📱 Mobile Native Development
| Platform / Stack | Directory | SDK Integration | Key Highlights |
| :--- | :--- | :--- | :--- |
| **Android Compose (Recommended)** | [`templates/android-compose/`](templates/android-compose/) | Maven Central (`io.github.zkteco-xteam:zkbrain-android:1.2.1`) | Modern Jetpack Compose declarative dashboard with 8-band spectrum, MEMS motion, and runtime permissions |
| **Android Native (Kotlin)** | [`templates/android-native/`](templates/android-native/) | Maven Central (`io.github.zkteco-xteam:zkbrain-android:1.2.1`) | Pure Kotlin + ViewBinding, zero boilerplate, plug-and-play |
| **Huawei HarmonyOS (Next)** | [`templates/harmonyos/`](templates/harmonyos/) | ArkTS / Stage Model | Native ArkUI declarative dashboard, system-level BLE scanning, 1:1 tricolor data table |
| **Apple iOS (Swift)** | [`templates/ios-swiftui/`](templates/ios-swiftui/) | Swift Package Manager (SPM) | Modern SwiftUI, native `async/await` stream consumption, and CoreBluetooth permission alerts |

### 2. 🚀 Cross-Platform & MiniPrograms
| Platform / Stack | Directory | SDK Integration | Key Highlights |
| :--- | :--- | :--- | :--- |
| **Flutter Cross-Platform** | [`templates/flutter/`](templates/flutter/) | `flutter_blue_plus` reactive stream | Dart for Android & iOS, 1:1 tricolor EEG table, and command terminal |
| **Uni-app (Vue 3 + TS)** | [`templates/uni-app/`](templates/uni-app/) | Vue 3 + TypeScript | **Write once, deploy to 10+ platforms**: WeChat, Alipay, Douyin, Baidu MiniPrograms & native Apps |
| **React Native (TS)** | [`templates/react-native/`](templates/react-native/) | `react-native-ble-plx` | Global mobile standard, Android 12+ / iOS 13+ runtime permissions & full console |
| **WeChat MiniProgram** | [`templates/miniprogram/`](templates/miniprogram/) | NPM (`@zkteco/zkbrain-miniprogram-sdk`) | Native MiniProgram TS, BLE watchdog auto-reconnect, 1:1 tricolor indicators |
| **Web Browser (H5)** | [`templates/web-ts/`](templates/web-ts/) | NPM (`@zkteco/zkbrain-web-sdk`) | Vite + TypeScript, W3C Web Bluetooth direct hardware connection |

### 3. 💻 Desktop Workstations
| Platform / Stack | Directory | SDK Integration | Key Highlights |
| :--- | :--- | :--- | :--- |
| **Electron Desktop** | [`templates/electron-desktop/`](templates/electron-desktop/) | Electron + Web Bluetooth | Builds native installers for Windows (`.exe`), macOS (`.dmg`), and Linux (`.deb`) |
| **Windows Desktop (C#/Python)** | [`templates/windows-desktop/`](templates/windows-desktop/) | C++ Dynamic Library (`zkbrain_sec.dll`) | High-speed BLE/UART streaming, Python Tkinter GUI & C# WinUI desktop projects |

### 4. 🎮 Gaming, XR, Neuroscience Research & AIoT Edge
| Platform / Stack | Directory | SDK Integration | Key Highlights |
| :--- | :--- | :--- | :--- |
| **Unity 3D / XR Brain-Control** | [`templates/unity/`](templates/unity/) | Unity C# Bridge | **Force Levitation Demo**: Attention controls 3D object height and particle aura, ready for Quest, Pico, Vision Pro |
| **Python Neuroscience Research** | [`templates/python-research/`](templates/python-research/) | MNE-Python / Jupyter | 0.5-50Hz bandpass + 50Hz notch filters, Welch PSD analysis, export to international **EDF+** & CSV |
| **Raspberry Pi / Linux IoT Edge** | [`templates/iot-raspberrypi/`](templates/iot-raspberrypi/) | Python Bleak + RPi.GPIO | Driver fatigue & construction safety daemon, triggers GPIO pin 18 buzzer, local LAN Web dashboard |

---

## 🤖 3-Minute Quickstart with AI

### Step 1: Clone and open in an AI-powered IDE
```bash
git clone https://github.com/zkteco-xteam/zkbrain-starter.git
cd zkbrain-starter
```
Open the folder in **Cursor**, **Antigravity**, or **Windsurf**. The editor will automatically index `AGENTS.md`, `.cursorrules`, and the official SDK skill in `.agents/skills/zkbrain-sdk-dev/`.

### Step 2: Send Starter Prompts to your AI

#### 💡 Starter Prompt A (Android Compose BCI App):
> *"Based on templates/android-compose, build an EEG focus training screen using ZKBrain SDK. Requirements: include a device scan dialog, attention/meditation gauges, and a real-time 512Hz raw waveform graph."*

#### 💡 Starter Prompt B (Flutter Flow State App):
> *"Using templates/flutter, create a flow state monitor app in Flutter that listens to brainwaves and triggers an achievement animation when attention exceeds 80."*

#### 💡 Starter Prompt C (Unity XR Brain-Control Game):
> *"Reference templates/unity to attach ForceLevitationController to my VR game object, modulating object elevation and light aura based on real-time attention."*

---

## 📚 Official Documentation & References
- [AI Entry Contract (llms.txt)](docs/llms.txt)
- [API Signatures Cheat Sheet (.agents/skills/zkbrain-sdk-dev/references/api-signatures.md)](.agents/skills/zkbrain-sdk-dev/references/api-signatures.md)
- [20-Line Golden Code Recipes (.agents/skills/zkbrain-sdk-dev/references/recipes.md)](.agents/skills/zkbrain-sdk-dev/references/recipes.md)
- [Cross-Platform DOs and DON'Ts (.agents/skills/zkbrain-sdk-dev/references/gotchas.md)](.agents/skills/zkbrain-sdk-dev/references/gotchas.md)
- [One-Line SDK Import Guide (docs/SDK_ONE_LINE_IMPORT_GUIDE.md)](docs/SDK_ONE_LINE_IMPORT_GUIDE.md)

---

## 📄 License & Commercial Support
- This starter kit is open-source under the **MIT License**. Developers are free to modify and commercialize;
- The core cross-platform `zkbrain` SDK engine is engineered and maintained by the **ZKTeco Brain-Computer Interface Division** (熵基科技脑机事业部).
