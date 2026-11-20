# ZKBrain 脑电设备指令下发与硬件协议集成指南

本文档全面阐述 ZKBrain KMP 跨平台 SDK 针对 **Sky (NeuroSky / MindWave 系列)** 与 **ZKTeco (ZKBrain 自研脑电系列)** 两大硬件设备族的控制指令格式、下发 API、日志监控与最佳集成规范。

---

## 目录

1. [硬件协议架构划分](#1-硬件协议架构划分)
2. [SDK 保护与稳定机制](#2-sdk-保护与稳定机制)
3. [Sky (NeuroSky / MindWave 系列) 二进制 XMW 协议控制指南](#3-sky-neurosky--mindwave-系列-二进制-xmw-协议控制指南)
4. [ZKTeco (ZKBrain 自研脑电系列) ASCII 键值对协议控制指南](#4-zkteco-zkbrain-自研脑电系列-ascii-键值对协议控制指南)
5. [控制台日志输出与排查指南](#5-控制台日志输出与排查指南)
6. [跨端 App (Android / iOS / 小程序 / Web) 最佳调用范例](#6-跨端-app-android--ios--小程序--web-最佳调用范例)

---

## 1. 硬件协议架构划分

ZKBrain SDK 在底层通信层将支持的脑电设备划分为两大核心设备族：

| 设备族标识 | 兼容设备类型 | 通信数据格式 | 物理传输通道 |
| :--- | :--- | :--- | :--- |
| **Sky (NeuroSky / XMW)** | MindWave Mobile、BrainLink、TGAM 模块、xpain 等 | 20 字节定长二进制帧（包头 `0xAA 0xAA` 或 `0x77`） | BLE / 经典蓝牙 SPP |
| **ZKTeco (自研脑电)** | ZKBrain EEG、XMind、XFocus、XSleep 系列 | 文本化 ASCII 字符串 / Key-Value 键值对（如 `eeg_data_on:1`） | BLE GATT Notify/Write |

---

## 2. SDK 保护与稳定机制

为了防范外部应用（App / 小程序）在 UI 刷新或响应式监听中误写死循环、重复下发指令导致蓝牙 GATT 管道堵塞或卡顿，SDK 内部集成了以下三重防护：

### 2.1 就绪 (READY) 自动点火兜底
当设备蓝牙物理连接建立、特征值（含 CCCD 描述符）订阅完成后，SDK 内部直接自动触发点火流程：
- **Sky 设备**：自动下发 `0x15` (开启 Raw 512Hz) 与 `0x17` (开启 8 频段)，并具备 200ms 冗余双发与 1.8 秒数据流看门狗自愈；
- **ZKTeco 设备**：自动下发 `eeg_data_on: 1` 和 `eeg_data_rate: 2` (512Hz 采样率)。外部 App 连接成功后**无需手动再次调用点火命令**。

### 2.2 高优先级防降级看门狗 (Priority Watchdog)
当设备处于 `READY` 状态时，SDK 底层启动 20 秒低功耗看门狗，周期性向 Android/iOS 系统重申 `requestHighConnectionPriority`，锁死 **7.5ms ~ 11.25ms 高速蓝牙传输间隔**，防止手机系统省电策略悄悄降级为慢速档导致 2 秒组包卡顿。

### 2.3 2 秒滑动窗口指令去重护盾 (Command Deduplication Shield)
在 `sendConfigCommand` 入口处植入了 2 秒去重锁：若外部 App 在 2 秒内重复下发完全相同的指令，SDK 内存层直接静默拦截（打印 `🛡️ [SDK 防重复护盾] 2 秒内静默去重拦截`），**绝对不会向物理蓝牙空口重复发送**。

---

## 3. Sky (NeuroSky / MindWave 系列) 二进制 XMW 协议控制指南

### 3.1 协议封包格式
Sky 设备接收 20 字节固定长度的二进制指令帧。标准封包结构如下：
- **字节 0-1**：同步头 `0xAA 0xAA`
- **字节 2**：Payload 长度 `0x02`
- **字节 3**：命令 OpCode (如 `0x15`, `0x17` 等)
- **字节 4..18**：参数填充段 (Padding `0x00`)
- **字节 19**：校验和 Checksum（低 8 位取反：`(~sum) & 0xFF`）

### 3.2 完整指令清单

| 命令功能 | OpCode (Hex) | 对应常量 / 指令说明 | 物理响应 / 行为 |
| :--- | :--- | :--- | :--- |
| **开启 Raw 原始波** | `0x15` | `CMD_XMW_RAW_ON` | 开启 512Hz 原始脑电波形数据流点火输出 |
| **关闭 Raw 原始波** | `0x16` | `CMD_XMW_RAW_OFF` | 停止 512Hz 原始脑电波形数据流输出 |
| **开启 8 频段数据** | `0x17` | `CMD_XMW_BAND_ON` | 开启 1Hz 8 频段能量谱 (Delta/Theta/Alpha/Beta/Gamma) |
| **关闭 8 频段数据** | `0x18` | `CMD_XMW_BAND_OFF` | 关闭 8 频段数据输出 |
| **50Hz 工频滤波** | `0x1B` | `CMD_XMW_50HZ` | 开启 50Hz 工频陷波滤波 (Notch Filter) |
| **60Hz 工频滤波** | `0x1C` | `CMD_XMW_60HZ` | 开启 60Hz 工频陷波滤波 (Notch Filter) |
| **读取静态电量** | `0x06` | `CMD_XMW_BATTERY` | 触发硬件返回当前剩余电量百分比 |
| **读取设备 SN** | `0xF4` | `CMD_XMW_READ_SN` | 触发硬件返回 `0xF5` 格式二进制设备 SN |
| **写入设备 SN** | `0xF2` | `CMD_XMW_WRITE_SN` | 写入最多 16 字节 ASCII SN（如 `MW_63300031`） |
| **进入 OTA 升级** | `0xF6` | `CMD_XMW_OTA` | 硬件回复 `0xF7` 确认并跳转 DFU Bootloader 模式 |
| **探测经典 MAC** | `0xFC` | `CMD_XMW_READ_CLASSIC_MAC` | 探测经典蓝牙 MAC（回复 `0xFD` 判定为音频双模设备） |

### 3.3 代码下发示例 (KMP / Kotlin)

```kotlin
// 方式 A：使用预设 OpCode 常量下发
sendXmwCommand(XmwProtocol.CMD_XMW_RAW_ON, logMsg = "开启 Raw EEG (0x15)")

// 方式 B：写入 16 字节设备 SN
val snBytes = "MW_00031".encodeToByteArray().take(16).toByteArray()
sendXmwCommand(XmwProtocol.CMD_XMW_WRITE_SN, snBytes, "写入 SN: MW_00031 (0xF2)")

// 方式 C：直接调用底层的 writeCommand 接口透传 20 字节 Hex
val rawBytes = byteArrayOf(0xAA.toByte(), 0xAA.toByte(), 0x02, 0x15, ..., checksum)
ZKBrainManager.writeCommand(macAddress, rawBytes)
```

---

## 4. ZKTeco (ZKBrain 自研脑电系列) ASCII 键值对协议控制指南

### 4.1 协议封包格式
ZKTeco 自研设备使用可读性极高、格式规范的 ASCII 文本指令。
- **键值对配置格式**：`key:value`（下发至 SDK 时传入 `mapOf("key" to "value")`）
- **句末终止符**：内部通信会自动在末尾补全 `;` 或 `\n`。

### 4.2 完整指令清单

| 指令类别 | 命令字符串 / 键值对 | 作用说明 | 典型示例 / 返回值 |
| :--- | :--- | :--- | :--- |
| **脑电波流控制** | `eeg_data_on:1` | 开启脑电波流数据输出 | `mapOf("eeg_data_on" to "1")` |
| | `eeg_data_on:0` | 关闭脑电波流数据输出 | `mapOf("eeg_data_on" to "0")` |
| | `eeg_data_on:?` | 查询脑电波流开启状态 | `mapOf("eeg_data_on" to "?")` |
| **采样率设置** | `eeg_data_rate:128` | 设置脑电采样率为 128 Hz | `mapOf("eeg_data_rate" to "128")` |
| | `eeg_data_rate:256` | 设置脑电采样率为 256 Hz | `mapOf("eeg_data_rate" to "256")` |
| | `eeg_data_rate:512` | 设置脑电采样率为 512 Hz | `mapOf("eeg_data_rate" to "512")` |
| | `eeg_data_rate:?` | 查询当前采样率档位 | `mapOf("eeg_data_rate" to "?")` |
| **MEMS 姿态传感** | `mems_on:1` / `mems_on:0` | 开启 / 关闭 MEMS 6轴惯导数据流 | `mapOf("mems_on" to "1")` |
| | `mems_type:0` / `1` | 设置 MEMS 工作类型模式 | `mapOf("mems_type" to "0")` |
| **设备系统查询** | `battery:?` | 读取当前电池电量百分比 | `mapOf("battery" to "?")` |
| | `version:?` | 读取固件版本号 | `mapOf("version" to "?")` |
| | `zk_check_license` | 查询商业授权认证状态 | 免证书模式统一返回有效 |

### 4.3 代码下发示例 (KMP / Kotlin)

```kotlin
// 方式 A：使用标准映射字典下发 (强烈推荐)
ZKBrainManager.sendConfigCommand(mapOf("eeg_data_on" to "1"))
ZKBrainManager.sendConfigCommand(mapOf("eeg_data_rate" to "512"))

// 方式 B：下发 MEMS 6轴惯导开启指令
ZKBrainManager.sendConfigCommand(mapOf("mems_on" to "1"))

// 方式 C：直接调用底层的 writeCommand 下发标准 ASCII 字符串
ZKBrainManager.writeCommand(macAddress, "eeg_data_on:1;".encodeToByteArray())
```

---

## 5. 控制台日志输出与排查指南

在应用运行时，打开 Logcat 或控制台过滤关键字 `ZKBrain`、`BLE` 或 `脑电`，可查验清晰的解构日志：

### 5.1 指令下发日志分类标识

1. **Sky (NeuroSky 二进制) 指令发送**：
   ```text
   🚀 [BLE 蓝牙写通道] [Sky (XMW 二进制帧)] 向 [12:34:56:78:9A:BC] 成功下发 20B | Hex: [AA AA 02 15 00 00 ... 17]
   ```
2. **ZKTeco (自研脑电 ASCII) 指令发送**：
   ```text
   📡 [ZKTeco/Sky 指令发送] 目标设备: [ZKBrain-00031] (ZKTeco (自研脑电)), 指令内容: eeg_data_on:1
   🚀 [BLE 蓝牙写通道] [ZKTeco (ASCII文本指令)] 向 [12:34:56:78:9A:BC] 成功下发 12B | 文本: 'eeg_data_on:1' | Hex: [65 65 67 5F 64 61 74 61 5F 6F 6E 3A 31]
   ```
3. **防重复护盾拦截日志**：
   ```text
   🛡️ [SDK 防重复护盾] 2 秒内静默去重拦截相同配置指令: [eeg_data_on:1] (距上次发送于 120ms 前)
   ```
4. **实时物理采样率面板 (1 秒精确定时器)**：
   ```text
   📊 [脑电波流采样率] 实时帧率/采样率: 512 Hz (512 点/秒, 累积总采样点: #10240)
   ```

---

## 6. 跨端 App (Android / iOS / 小程序 / Web) 最佳调用范例

### 6.1 Android / Kotlin (Jetpack Compose / ViewModel)

```kotlin
// 1. 监听连接状态 (使用 repeatOnLifecycle 确保无泄露)
lifecycleScope.launch {
    repeatOnLifecycle(Lifecycle.State.STARTED) {
        ZKBrainManager.connectionState.collect { state ->
            if (state == ZKBrainConnectionState.READY) {
                // SDK 内部已自动点火完成，无需重复下发
                Log.i("App", "设备已就绪，实时脑波流正在持续传输中...")
            }
        }
    }
}

// 2. 在控制台手动切换采样率至 512Hz
fun setSampleRateTo512() {
    ZKBrainManager.sendConfigCommand(mapOf("eeg_data_rate" to "512"))
}
```

### 6.2 iOS / Swift (SwiftUI / Combine)

```swift
// 1. 监听连接状态
ZKBrainManager.shared.connectionState.sink { state in
    if state == .ready {
        print("iOS 设备连接成功并就绪！")
    }
}.store(in: &cancellables)

// 2. 下发配置命令
ZKBrainManager.shared.sendConfigCommand(config: ["eeg_data_on": "1"])
```

### 6.3 微信小程序 TS/JS SDK

```typescript
import { zkBrainCloudRecord } from 'zkbrain-miniprogram-sdk';

// 启动录制 (云端管理器自动完成初始化与波形订阅)
await zkBrainCloudRecord.startRecording({
    userId: "USER_001",
    sn: "MW_00031",
    sampleRate: 512
});
```

---

## 7. 总结

ZKBrain SDK 现已全面放开商业授权限制，**不再强求 `license.lic` 证书文件即可全功能运行**。同时通过自动点火、20 秒高优先级防降级看门狗与 2 秒滑动去重护盾，为 Sky 与 ZKTeco 两大设备族提供了极高稳定度的蓝牙底层管道。
