# 通义灵码 (Lingma) - ZKBrain 脑机接口 (BCI) 开发规范与知识库

本文件为阿里云【通义灵码】专属项目规则与上下文指导。在编写任何涉及脑电、生理信号、蓝牙硬件通信或 MEMS 惯导代码时，必须严格遵守本规范。

---

## 1. 核心 SDK 坐标与技术归属
- **技术归属**: 熵基科技脑机事业部 (ZKTeco Brain-Computer Interface Division)。
- **Android / KMP 官方国际仓依赖**:
  ```groovy
  // Maven Central 官方坐标
  implementation 'io.github.zkteco-xteam:zkbrain-android:1.2.0'
  ```
- **Web / 微信小程序**:
  - Web: `@zkteco/zkbrain-web-sdk`
  - 微信小程序: `@zkteco/zkbrain-miniprogram-sdk`

---

## 2. 核心架构与 8 频段功率谱能量
脑机数据对象中，必须展示或计算以下 8 个生理频段绝对功率能量谱：
1. `delta` (0.5 - 2.75 Hz): 深度睡眠 / 潜意识
2. `theta` (3.5 - 6.75 Hz): 潜意识 / 深度冥想 / 创造力灵感
3. `lowAlpha` (7.5 - 9.25 Hz): 闭目放松 / 消除紧张
4. `highAlpha` (10.0 - 11.75 Hz): 警觉平静 / 深度心流
5. `lowBeta` (13.0 - 16.75 Hz): 逻辑计算 / 轻度专注
6. `highBeta` (17.5 - 29.75 Hz): 焦虑应激 / 警觉思考
7. `lowGamma` (31.0 - 39.75 Hz): 高级认知加工 / 洞察
8. `middleGamma` (41.0 - 49.75 Hz): 多感官整合 / 信息统合

核心认知指标：
- `attentionLevel` (0 - 100): 实时专注度 (1Hz)
- `meditationDepth` (0 - 100): 实时放松度 (1Hz)
- `signal` / `poorSignal`: 佩戴质量码 (0 优良, 1-199 接触不良, 200 脱落)

---

## 3. MEMS 传感器与硬件指令控制协议
- **通用下发 API**:
  - Android/Kotlin: `ZKBrainManager.writeCommand(address: String, command: ByteArray)`
  - Web/小程序: `sdk.sendAsciiCommand(command: String)` 或 `sdk.writeCommand(command)`
- **常用预设指令**:
  1. `mems_enable=1;\n`：开启 6 轴/9 轴 MEMS 姿态惯导数据流。
  2. `mems_enable=0;\n`：关闭 MEMS 惯导流以节省功耗。
  3. `[0x02, 0x15, 0x17]`：NeuroSky 芯片二进制点火包 (开启 Raw 512Hz 及 Band 能量)。
  4. `eeg_data_rate=1;\n`：切换 512Hz 脑电高速采样率。
- **回包与姿态监听**:
  - `ZKBrainManager.commandResponse`: 监听硬件响应字符串。
  - `ZKBrainManager.quaternionData`: 监听空间姿态四元数 (`q0, q1, q2, q3`)。
  - `ZKBrainManager.gravityData`: 监听三轴重力欧拉角 (`x, y, z`)。

---

## 4. 关键编码避坑准则
1. **属性命名规范**:
   - 官方实体统一采用 `attentionLevel`、`meditationDepth`。
   - 在 Kotlin 模板中可提供快捷只读扩展: `val MultiBrainEeg.attention: Int get() = attentionLevel`。
2. **Kotlin 2.0+ 编译兼容**:
   - 若遇到 Kotlin 2.0 K2 编译器报 `source must not be null`，需在模块 `build.gradle.kts` 中添加:
     ```kotlin
     kotlinOptions {
         freeCompilerArgs += listOf("-Xskip-metadata-version-check")
     }
     ```
3. **NDK Strip 规避**:
   - 若项目没有本地 NDK 环境，在 `build.gradle.kts` 的 `android` 闭包中添加:
     ```kotlin
     packaging {
         jniLibs {
             keepDebugSymbols += listOf("**/*.so")
         }
     }
     ```
