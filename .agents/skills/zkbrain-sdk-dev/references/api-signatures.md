# ZKBrain SDK Official API Signatures Reference (api-signatures.md)
# ZKBrain SDK 官方纯契约签名速查

> **Version / 版本**：v1.2.1 (Maven Central)
> **Description / 说明**：This document contains all public core interfaces, data structures, and Flow reactive streams of the ZKBrain SDK, stripped of internal private fields for zero-hallucination developer reference and AI direct code generation.
> 本文档包含 ZKBrain SDK 对外公开的全部核心接口与 Flow 数据通道签名，剥离所有底层实现与私有字段，供开发者查阅及 AI 零幻觉直接调用。

---

## 1. Core Controller: `ZKBrainManager` / 核心控制器

Package / 包路径：`com.zkteco.zkbrain.ZKBrainManager`

```kotlin
object ZKBrainManager {
    // ---------------- Reactive Streams & State / 核心状态与响应式数据流 ----------------
    val connState: StateFlow<ZKBrainConnectionState>          // Current connection state / 当前连接状态 (DISCONNECTED, CONNECTING, CONNECTED)
    val connectedDevice: StateFlow<ZKBrainDevice?>            // Current connected device info / 当前已连接成功的脑机设备信息
    val scanState: StateFlow<ZKBrainScanState>                // BLE scanner radar state / 扫描雷达状态 (IDLE, SCANNING)
    val scannedDevices: StateFlow<List<ZKBrainDevice>>        // List of discovered peripheral devices / 扫描发现的外设列表
    
    val brainData: SharedFlow<MultiBrainEeg>                  // 1Hz comprehensive BCI packet (attention, meditation, 8-band, signal quality)
    val rawdata: SharedFlow<Int>                              // 512Hz raw EEG microvolt sample points (for waveform rendering)
    val disconnectedEvent: SharedFlow<ZKBrainDisconnectEvent> // Abnormal disconnection event (for alert dialogs)
    val quaternionData: SharedFlow<Quaternion>                // 6-axis MEMS spatial posture (q0, q1, q2, q3)
    val commandResponse: SharedFlow<String>                   // Hardware ASCII / OpCode response stream
    
    // ---------------- Device Scan & Connection / 设备扫描与连接控制 ----------------
    fun startScan(timeoutMillis: Long = 10000L, isContinuous: Boolean = false)
    fun stopScan()
    
    fun connect(device: ZKBrainDevice)
    fun connect(address: String)
    fun connectBySn(sn: String)
    fun disconnect()                                          // Disconnect current physical link / 断开当前连接
    
    // ---------------- Hardware Commands / 硬件指令下发 ----------------
    fun sendConfigCommand(config: Map<String, String>)        // Config map with 2s deduplication shield / 推荐配置字典
    fun writeCommand(address: String, command: ByteArray)     // Direct byte array dispatch / 底层透传字节流
    
    // ---------------- Local Recording Entry / 录制子系统入口 ----------------
    val recordManager: ZKBrainRecordManager                   // Local offline session recorder
}
```

---

## 2. BCI Data Model: `MultiBrainEeg` / 脑电数据结构

Package / 包路径：`com.zkteco.zkbrain.bean.MultiBrainEeg`

```kotlin
data class MultiBrainEeg(
    val attentionLevel: Int = 0,    // Attention / Focus index (0 ~ 100, alias: attention)
    val meditationDepth: Int = 0,   // Meditation / Relaxation index (0 ~ 100, alias: meditation)
    val signal: Int = 200,          // Contact quality (0: Good contact, 200: Off-head / Detached)
    val batteryCapacity: Int = 0,   // Battery level percentage (0 ~ 100)
    val heartRateBPM: Int = 0,      // Heart rate BPM (if supported by hardware)
    
    // 8-Band Power Spectrum / 脑波 8 频段绝对功率 (Encapsulated in brainWaves)
    val brainWaves: BrainWaves = BrainWaves(
        val delta: Int = 0,         // Delta (0.5 ~ 2.75Hz: Deep sleep / 深度睡眠)
        val theta: Int = 0,         // Theta (3.5 ~ 6.75Hz: Drowsiness, meditation, creativity / 浅睡、潜意识)
        val lowAlpha: Int = 0,      // Low Alpha (7.5 ~ 9.25Hz: Relaxed, calm / 放松)
        val highAlpha: Int = 0,     // High Alpha (10 ~ 11.75Hz: Flow state, eyes closed / 安静闭眼、心流)
        val lowBeta: Int = 0,       // Low Beta (13 ~ 16.75Hz: Alertness, active thinking / 警觉、轻度专注)
        val highBeta: Int = 0,      // High Beta (17 ~ 29.75Hz: High focus, anxiety, computing / 高度专注、计算)
        val lowGamma: Int = 0,      // Low Gamma (31 ~ 39.75Hz: Cognitive processing / 认知加工)
        val middleGamma: Int = 0    // Mid Gamma (41 ~ 49.75Hz: Multisensory integration / 高阶感知整合)
    )
)
```

---

## 3. Device Info: `ZKBrainDevice` / 设备信息结构

Package / 包路径：`com.zkteco.zkbrain.bean.ZKBrainDevice`

```kotlin
data class ZKBrainDevice(
    val address: String,            // Hardware MAC address (Android/Win) or UUID string (iOS/macOS)
    val name: String?,              // Advertising Bluetooth name (e.g. "ZKBrain-PRO-8801", "MindWave Mobile")
    val rssi: Int = 0,              // Signal RSSI (dBm)
    val sn: String? = null,         // Hardware Serial Number SN
    val isNeuroSky: Boolean = false // Whether device uses NeuroSky XMW protocol
)
```

---

## 4. Connection State Enum: `ZKBrainConnectionState` / 连接状态枚举

Package / 包路径：`com.zkteco.zkbrain.bean.ZKBrainConnectionState`

```kotlin
enum class ZKBrainConnectionState {
    DISCONNECTED,   // Idle / Disconnected / 未连接
    CONNECTING,     // Handshake & GATT discovery in progress / 建立物理链路与服务发现中
    CONNECTED,      // Fully ready, data streaming / 设备完全就绪，开始供应脑电数据流
    RECONNECTING    // Link interrupted, watchdog auto-healing / 底层自愈重连中
}
```

---

## 5. Cloud Recording Manager: `ZKBrainCloudRecordManager` / 云端标准化录制管理器

Package / 包路径：`com.zkteco.zkbrain.record.ZKBrainCloudRecordManager`

```kotlin
object ZKBrainCloudRecordManager {
    val isRecording: StateFlow<Boolean>
    val currentDurationSeconds: StateFlow<Int>
    
    // Start standard recording session / 启动标准化录制会话
    suspend fun startRecording(
        sessionType: String = "attention_task", // Session type / 会话类型
        reusedBaselineSessionId: String? = null // Optional baseline session ID to reuse / 可选基线复用 ID
    ): String                                   // Returns active sessionId / 返回会话 ID
    
    // Append structured event tag / 写入结构化事件 (events.csv)
    fun appendEvent(eventCode: Int, eventName: String)
    
    // End session, stitch 3-table format, encrypt envelope, and upload to cloud analysis
    suspend fun stopAndUpload(
        serverUrl: String,
        apiKey: String
    ): Result<CloudAnalysisResult>
}
```

---

## 6. Hardware Command Dispatch API & Protocols / 硬件指令下发 API 与协议标准

### 6.1 Dispatch Interfaces / 指令下发接口
```kotlin
// Mode A: Standard configuration map (Recommended, 2-second anti-repetition shield)
fun sendConfigCommand(config: Map<String, String>)

// Mode B: Transparent byte stream (Used for OpCode firmware or ignition packets)
fun writeCommand(address: String, command: ByteArray)

// Response channel
val commandResponse: SharedFlow<String>
```

### 6.2 Hardware Protocol Specifications / 硬件协议划分与标准指令
1. **ZKTeco Proprietary Protocol (ASCII / MEMS)**:
   - `mems_on:1` / `mems_on:0`: Enable / disable 6-axis MEMS IMU stream
   - `eeg_data_on:1` / `eeg_data_on:0`: Enable / disable EEG data streaming
   - `eeg_data_rate:512` / `256` / `128`: Set sampling rate
   - `battery:?`: Query battery level percentage
   - `version:?`: Query hardware firmware version
2. **NeuroSky XMW 20B Binary Protocol**:
   - `0x15` (`CMD_XMW_RAW_ON`): Start Raw 512Hz stream
   - `0x16` (`CMD_XMW_RAW_OFF`): Stop Raw 512Hz stream
   - `0x17` (`CMD_XMW_BAND_ON`): Start 8-band power spectrum
   - `0x18` (`CMD_XMW_BAND_OFF`): Stop 8-band power spectrum
   - `0x1B` (`CMD_XMW_50HZ`): 50Hz notch filter
   - `0x1C` (`CMD_XMW_60HZ`): 60Hz notch filter
   - `0x06` (`CMD_XMW_BATTERY`): Read hardware battery level
   - `0xF4` (`CMD_XMW_READ_SN`): Read device serial number SN
