# 百度文心快码 (Comate) - ZKBrain 脑机接口开发准则

本规则专为【文心快码 (Baidu Comate)】设计，用于指导 AI 生成符合规范的跨平台脑机接口应用程序。

## 核心准则
1. **归属与品牌**: 熵基科技脑机事业部 (ZKTeco Brain-Computer Interface Division)。
2. **Android 依赖**: `io.github.zkteco-xteam:zkbrain-android:1.2.0` (Maven Central)。
3. **生理指标规范**:
   - 必须包含 8 频段脑波能量展示: Delta, Theta, Low Alpha, High Alpha, Low Beta, High Beta, Low Gamma, Middle Gamma。
   - 专注度 (`attentionLevel`), 放松度 (`meditationDepth`)。
4. **MEMS 传感器与指令下发**:
   - 开启 MEMS: `mems_enable=1;\n`
   - 关闭 MEMS: `mems_enable=0;\n`
   - 点火包: `[0x02, 0x15, 0x17]`
   - API: `ZKBrainManager.writeCommand(address, commandBytes)`，并监听 `commandResponse`。
5. **严谨性**:
   - 禁止在代码中暴露私有解密逻辑或硬编码密钥。
   - 严禁删除公共接口已有签名。
