# ZKBrain Starter Kit (AI-Ready 脑机应用开发脚手架)

> 🚀 **官方开源脚手架** | 面向二次开发者与 AI 编程助手（Cursor, Antigravity, Windsurf, Copilot）的跨平台脑机接口 (BCI) 开箱即用全栈模板。

本项目是 **ZKBrain 跨平台脑机接口 SDK** 的官方公开脚手架，内置 Android/KMP、iOS、Web H5、微信小程序 4 大平台的最简运行模板，并深度整合了 **AI 上下文工程（Skill + llms.txt + Cursorrules）**。

开发者（或您的 AI）无需关心底层复杂的硬件点火包、协议解包与加解密，克隆后**只需对 AI 说一句话，即可秒级生成专属脑电应用**！

---

## 📂 多端极简模板导航

| 平台 / 技术栈 | 模板目录 | SDK 接入形式 | 核心亮点 |
| :--- | :--- | :--- | :--- |
| **Android & Desktop (KMP)** | [`templates/kmp-compose/`](templates/kmp-compose/) | Maven 一行依赖 | Compose Multiplatform MVI 架构，自带防卡顿 512Hz 脑波画布 |
| **原生 iOS (Swift)** | [`templates/ios-swiftui/`](templates/ios-swiftui/) | Swift Package Manager (SPM) | SwiftUI 现代声明式 UI，原生 `async/await` 消费脑电数据流 |
| **Web 浏览器 (H5)** | [`templates/web-ts/`](templates/web-ts/) | NPM (`@zkteco/zkbrain-web-sdk`) | Vite + TypeScript，基于 W3C Web Bluetooth 直连脑电设备 |
| **微信小程序** | [`templates/miniprogram/`](templates/miniprogram/) | NPM (`@zkteco/zkbrain-miniprogram-sdk`) | 原生小程序架构，内置低功耗蓝牙 (BLE) 扫描与专注度仪表盘 |

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

#### 💡 提示词范例 A（KMP / Android 脑波监控）：
> *"请参考 templates/kmp-compose 模板，使用 ZKBrain SDK 为我新增一个脑电专注度训练页面。要求：包含设备扫描弹窗、一个展示专注度与放松度的仪表盘、以及一个实时跳动的 512Hz 原始脑波图。"*

#### 💡 提示词范例 B（iOS 原生开发）：
> *"请基于 templates/ios-swiftui，用 SwiftUI 帮我写一个心流状态监测 App，实时监听 ZKBrainManager.shared.brainData，当专注度超过 80 时播放鼓励动画。"*

#### 💡 提示词范例 C（Web / 小程序）：
> *"请基于 templates/web-ts 模板，帮我增加一个脑电数据历史回放列表，并支持一键将当前数据导出为 CSV。"*

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
- 底层 `zkbrain` 跨平台 SDK 核心包由 **ZKTeco (中控科技)** 团队提供技术支持。
