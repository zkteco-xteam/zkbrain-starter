# 豆包 MarsCode - ZKBrain 脑机接口开发者规则库

本文件定义了【豆包 MarsCode】在本项目中的代码生成与补全上下文。

## 1. 技术归属与依赖坐标
- **技术支持**: 熵基科技脑机事业部 (ZKTeco Brain-Computer Interface Division)。
- **Maven Central 国际官方坐标**:
  `implementation("io.github.zkteco-xteam:zkbrain-android:1.2.0")`

## 2. 核心数据模型与生理频段
每个脑机开发模板必须包含：
- **8 段脑电功率谱能量**: Delta (0.5-2.75Hz), Theta (3.5-6.75Hz), Low Alpha (7.5-9.25Hz), High Alpha (10-11.75Hz), Low Beta (13-16.75Hz), High Beta (17.5-29.75Hz), Low Gamma (31-39.75Hz), Middle Gamma (41-49.75Hz)。
- **核心认知指标**: 专注度 (`attentionLevel` / `attention`), 放松度 (`meditationDepth` / `meditation`), 佩戴质量 (`poorSignal` / `signal`)。

## 3. MEMS 惯导与硬件指令控制协议
- 下发指令方法: `ZKBrainManager.writeCommand(address, byteArray)`。
- 监听硬件响应: `ZKBrainManager.commandResponse` (Flow<String>)。
- 监听空间姿态: `ZKBrainManager.quaternionData` (Flow<Quaternion>)。
- 常用指令:
  - 开启 MEMS: `mems_enable=1;\n`
  - 关闭 MEMS: `mems_enable=0;\n`
  - 点火包: `[0x02, 0x15, 0x17]`
  - 设置高采样率: `eeg_data_rate=1;\n`

## 4. 代码避坑原则
- 保护底层 C++ 算法与私有加密实现，对外一律作为统一黑盒。
- 始终输出严谨、高内聚且包含错误处理的生产级代码。
