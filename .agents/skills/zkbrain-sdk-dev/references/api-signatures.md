# ZKBrain SDK 官方纯契约签名速查 (api-signatures.md)

> **版本**：v1.2.0
> **说明**：本文档包含 ZKBrain SDK 对外公开的全部核心接口与 Flow 数据通道签名，剥离所有底层实现与私有字段，供开发者查阅及 AI 零幻觉直接调用。

---

## 1. 核心控制器：`ZKBrainManager`

包路径：`com.zkteco.zkbrain.ZKBrainManager`

```kotlin
object ZKBrainManager {
    // ---------------- 核心状态与响应式数据流 ----------------
    val connState: StateFlow<ZKBrainConnectionState>          // 当前连接状态 (DISCONNECTED, CONNECTING, CONNECTED)
    val connectedDevice: StateFlow<ZKBrainDevice?>            // 当前已连接成功的脑机设备信息
    val scanState: StateFlow<ZKBrainScanState>                // 扫描雷达状态 (IDLE, SCANNING)
    val scannedDevices: StateFlow<List<ZKBrainDevice>>        // 扫描发现的外设列表
    
    val brainData: SharedFlow<MultiBrainEeg>                  // 1Hz 综合脑电数据包 (专注度, 放松度, 8频段能量, 信号质量)
    val rawdata: SharedFlow<Int>                              // 512Hz 原始脑电采样点 (Raw EEG 微伏采样，用于绘制波形)
    val disconnectedEvent: SharedFlow<ZKBrainDisconnectEvent> // 异常掉线事件 (用于业务弹窗提示)
    
    // ---------------- 设备扫描与连接控制 ----------------
    fun startScan(timeoutMillis: Long = 10000L, isContinuous: Boolean = false)
    fun stopScan()
    
    fun connect(device: ZKBrainDevice)
    fun connect(address: String)
    fun connectBySn(sn: String)
    fun disconnect()                                          // 断开当前连接
    
    // ---------------- 录制子系统入口 ----------------
    val recordManager: ZKBrainRecordManager                   // 本地离线录制管理器
}
```

---

## 2. 脑电数据结构：`MultiBrainEeg`

包路径：`com.zkteco.zkbrain.bean.MultiBrainEeg`

```kotlin
data class MultiBrainEeg(
    val attentionLevel: Int = 0,    // 专注度指数 (0 ~ 100，便捷别名: attention)
    val meditationDepth: Int = 0,   // 放松度/冥想指数 (0 ~ 100，便捷别名: meditation)
    val signal: Int = 200,          // 接触信号质量 (0: 信号极佳良好佩戴, 200: 完全脱落/未接触皮肤)
    val batteryCapacity: Int = 0,   // 电池电量 (0 ~ 100)
    val heartRateBPM: Int = 0,      // 心率 (若设备支持心率传感器)
    
    // 脑波 8 频段绝对功率 (封装于 brainWaves 实体中)
    val brainWaves: BrainWaves = BrainWaves(
        val delta: Int = 0,         // Delta 波 (0.5 ~ 2.75Hz，深度睡眠)
        val theta: Int = 0,         // Theta 波 (3.5 ~ 6.75Hz，浅睡、潜意识、创意)
        val lowAlpha: Int = 0,      // 低 Alpha 波 (7.5 ~ 9.25Hz，放松、冥想)
        val highAlpha: Int = 0,     // 高 Alpha 波 (10 ~ 11.75Hz，安静闭眼、心流)
        val lowBeta: Int = 0,       // 低 Beta 波 (13 ~ 16.75Hz，警觉、轻度专注)
        val highBeta: Int = 0,      // 高 Beta 波 (17 ~ 29.75Hz，高度警觉、焦虑、计算)
        val lowGamma: Int = 0,      // 低 Gamma 波 (31 ~ 39.75Hz，认知加工)
        val middleGamma: Int = 0    // 中 Gamma 波 (41 ~ 49.75Hz，高阶多感官整合)
    )
)
```

---

## 3. 设备信息结构：`ZKBrainDevice`

包路径：`com.zkteco.zkbrain.bean.ZKBrainDevice`

```kotlin
data class ZKBrainDevice(
    val address: String,            // 硬件 MAC 地址 (Android) 或 UUID 标识 (iOS)
    val name: String?,              // 蓝牙广播广播名称 (例如 "MindWave Mobile", "BrainLink", "ZK-EEG")
    val rssi: Int = 0,              // 蓝牙信号强度 (dBm)
    val sn: String? = null,         // 设备唯一序列号 (若硬件支持广播解析)
    val isNeuroSky: Boolean = false // 是否属于 NeuroSky XMW 协议设备
)
```

---

## 4. 连接状态枚举：`ZKBrainConnectionState`

包路径：`com.zkteco.zkbrain.bean.ZKBrainConnectionState`

```kotlin
enum class ZKBrainConnectionState {
    DISCONNECTED,   // 未连接 / 空闲
    CONNECTING,     // 正在进行物理链路连接与协议握手
    CONNECTED,      // 已完全连接就绪，数据流开始供给
    RECONNECTING    // 异常断开，底层自愈看门狗正在静默重连
}
```

---

## 5. 云端标准化录制管理器：`ZKBrainCloudRecordManager`

包路径：`com.zkteco.zkbrain.record.ZKBrainCloudRecordManager`

```kotlin
object ZKBrainCloudRecordManager {
    // ---------------- 录制状态与控制 ----------------
    val isRecording: StateFlow<Boolean>
    val currentDurationSeconds: StateFlow<Int>
    
    // 开始标准化录制会话
    suspend fun startRecording(
        sessionType: String = "attention_task", // 会话类型
        reusedBaselineSessionId: String? = null // 可选：复用已标定的基线会话 ID
    ): String                                   // 返回当前会话 ID
    
    // 插入结构化事件打标 (events.csv)
    fun appendEvent(eventCode: Int, eventName: String)
    
    // 结束录制、执行三表缝合、国密数字信封加密并直传云端分析服务
    suspend fun stopAndUpload(
        serverUrl: String,
        apiKey: String
    ): Result<CloudAnalysisResult>
}
```
