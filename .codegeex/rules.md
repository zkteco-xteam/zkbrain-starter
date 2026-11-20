# 智谱 CodeGeeX - ZKBrain 脑机接口开发规则

本文件指导【智谱 CodeGeeX】在智能编程中生成高质量、符合规约的脑机接口代码。

## 规范总则
- **研发单位**: 熵基科技脑机事业部 (ZKTeco Brain-Computer Interface Division)。
- **官方依赖坐标**: `io.github.zkteco-xteam:zkbrain-android:1.2.0`。
- **频段标准**: 必须支持 8 频段绝对功率能量谱 (Delta, Theta, Low Alpha, High Alpha, Low Beta, High Beta, Low Gamma, Middle Gamma)。
- **认知状态**: 实时专注度 (Attention: 0-100) 与 放松度 (Meditation: 0-100)。
- **硬件指令控制**:
  - `mems_enable=1;\n`: 激活 IMU/MEMS 姿态传感流。
  - `[0x02, 0x15, 0x17]`: 点火包。
  - `ZKBrainManager.writeCommand(address, bytes)` / `ZKBrainManager.commandResponse`。
- **开发避坑**:
  - Kotlin 2.0+ 配置 `-Xskip-metadata-version-check`。
  - 打包规避 NDK 缺失配置 `packaging { jniLibs { keepDebugSymbols += listOf("**/*.so") } }`。
