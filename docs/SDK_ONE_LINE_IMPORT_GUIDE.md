# ZKBrain 多端 SDK 一行代码极速接入指南

> **适用场景**：本文档旨在帮助下游开发者在 1 分钟内将 ZKBrain SDK 集成到 iOS (Swift)、Android、KMP 跨平台、Web H5 或微信小程序工程中，实现**“一行依赖/一行命令，开箱即用”**。

---

## 🍎 1. iOS 原生 (Swift) 极速接入

ZKBrain iOS SDK 采用预编译 **XCFramework 静态架构** 并深度集成了 **Touchlab SKIE**，原生 Swift 开发者可享受纯正的 Swift API 与 `async/await` 语法。

### 方式 A：Swift Package Manager (SPM，推荐)
彻底告别复杂的 CocoaPods 环境与版本冲突：
1. 打开您的 Xcode 工程，点击顶部菜单 **File** -> **Add Package Dependencies...**；
2. 在右上角搜索栏粘贴公司官方仓库 Git 地址：
   ```
   https://github.com/zkteco-xteam/zkbrain.git
   ```
3. Dependency Rule 选择 `Up to Next Major Version`（或指定当前 Release Tag），点击 **Add Package** 即可一键完成拉取！

### 方式 B：手动拖入 XCFramework
1. 在公司的 [GitHub Releases](https://github.com/zkteco-xteam/zkbrain/releases) 页面直接下载预编译好的 `zkbrain_parser.xcframework.zip` 并解压；
2. 将 `zkbrain_parser.xcframework` 拖入 Xcode 工程的 **Frameworks, Libraries, and Embedded Content**，并选择 **Embed & Sign**。

### 原生 Swift 极速调用范例：
```swift
import zkbrain_parser

// 1. 扫描与连接脑机设备
ZKBrainManager.shared.startScan(timeoutMillis: 10000, isContinuous: false)

// 2. 原生 Swift async/await 优雅消费脑电数据流 (由 SKIE 自动赋能)
Task {
    for await eeg in ZKBrainManager.shared.brainData {
        print("当前专注度: \(eeg.attention), 放松度: \(eeg.meditation)")
    }
}
```

---

## 📱 2. Android (Native & Jetpack Compose) 接入

### 方式 A：国际官方 Maven Central 直连（推荐！免 Token、零门槛、秒级下载）

在您的应用根目录 `settings.gradle.kts` 中确认包含 `mavenCentral()`：
```kotlin
dependencyResolutionManagement {
    repositories {
        google()
        mavenCentral() // 🌟 国际官方中央仓库
    }
}
```

在模块级 `build.gradle.kts` 的 `dependencies` 中添加一行依赖即可：
```kotlin
dependencies {
    // 🌟 熵基科技脑机事业部官方 Android 脑机 SDK (无需配置任何私有 Token，全球加速)
    implementation("io.github.zkteco-xteam:zkbrain-android:1.2.1")
}
```

### 极速调用范例：
```kotlin
import com.zkteco.zkbrain.ZKBrainManager
import com.zkteco.zkbrain.bean.ZKBrainConnectionState

// 1. 扫描与连接设备
ZKBrainManager.startScan(timeoutMillis = 10000L)

// 2. 响应式监听连接状态与 1Hz 脑电指标
lifecycleScope.launch {
    ZKBrainManager.brainData.collectLatest { eeg ->
        println("当前专注度: ${eeg.attentionLevel}, 放松度: ${eeg.meditationDepth}, 信号质量: ${eeg.signal}")
    }
}
```

---

## 🦋 3. Flutter 跨平台接入

参考 `templates/flutter/` 模板工程：
* 依赖 `flutter_blue_plus` 响应式低功耗蓝牙；
* 预置 Android 12+ 运行时权限与 iOS 13+ 蓝牙权限；
* 开箱即用 Attention / Meditation 环形进度条、8 频段彩色能量柱状图与 512Hz Canvas 示波器。

---

## ⚡ 4. 华为鸿蒙 (HarmonyOS Next) 接入

参考 `templates/harmonyos/` 鸿蒙 Next 原生 ArkTS / Stage 模型模板工程：
* 在 `module.json5` 中声明系统级低功耗蓝牙权限；
* 原生 ArkUI 声明式大屏，实时呈现专注度、放松度、8 频段能量与 512Hz 示波器 Canvas 动效。

---

## 🌐 2. Web / 浏览器 H5 端接入 (NPM)

一行命令安装 NPM 依赖：

```bash
# 使用 npm
npm install @zkteco/zkbrain-web-sdk

# 或使用 pnpm / yarn
pnpm add @zkteco/zkbrain-web-sdk
```

### 极速使用示例 (TypeScript / JavaScript)：
```typescript
import { ZKBrainWebSdk } from '@zkteco/zkbrain-web-sdk';

const sdk = new ZKBrainWebSdk();

// 1. 扫描与连接 Web Bluetooth 脑机设备
await sdk.requestDeviceAndConnect();

// 2. 监听 512Hz 实时脑电与 8 频段状态
sdk.on('brain_data', (data) => {
  console.log('实时专注度:', data.attention, '放松度:', data.meditation);
});
```

---

## 💬 3. 微信小程序端接入 (NPM)

在微信小程序项目根目录下执行：

```bash
npm install @zkteco/zkbrain-miniprogram-sdk
```

在微信开发者工具中点击 **【工具】 -> 【构建 npm】** 即可完成集成。

### 极速使用示例：
```typescript
import { ZKBrainMiniProgramSdk } from '@zkteco/zkbrain-miniprogram-sdk';

const sdk = new ZKBrainMiniProgramSdk();
sdk.init();

// 开始搜索并建连
sdk.startScanAndConnect({
  onConnected: () => console.log('脑机设备已就绪'),
  onBrainData: (eeg) => console.log('EEG 数据:', eeg)
});
```

---

## 🛠️ 4. CI/CD 自动化发版机制（供管理员参考）

项目已配置统一的 GitHub Actions 自动化工作流：
- 配置文件位置：[`.github/workflows/ci-publish.yml`](file:///e:/zkt_git_project/blink/project_kpm/.github/workflows/ci-publish.yml)
- **触发方式**：
  1. **Tag 自动触发**：推送版本标签即可全量构建并发布：
     ```bash
     git tag v1.2.0
     git push origin v1.2.0
     ```
  2. **界面一键手动触发**：在 GitHub 仓库的 **Actions -> ZKBrain SDK 自动化构建与统一分发** 页面点击 `Run workflow` 即可单独选择发布 Maven、NPM 或执行 Dry Run 演练测试。
