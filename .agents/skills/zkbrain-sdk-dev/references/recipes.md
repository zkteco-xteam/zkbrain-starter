# ZKBrain SDK 20-Line Golden Code Recipes (recipes.md)
# ZKBrain SDK 20 行黄金代码样板

> **Principle / 原则**：All code snippets below are verified, copy-paste ready minimal end-to-end closed loops for production environments, complying with anti-freeze and anti-collapse guidelines.
> 以下代码均为生产环境可直接复制粘贴的端到端最小闭环代码，已通过编译验证与避坑校验。

---

## ⚡ Recipe 1: Minimal Scan & Auto-Connect (Kotlin) / 极简扫描与自动连接有效脑电设备

```kotlin
import com.zkteco.zkbrain.ZKBrainManager
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.launch

fun scanAndConnectFirstDevice(scope: CoroutineScope) {
    // 1. Observe scan radar results / 监听扫描结果
    scope.launch {
        ZKBrainManager.scannedDevices.collect { devices ->
            val target = devices.firstOrNull()
            if (target != null && ZKBrainManager.connState.value.name == "DISCONNECTED") {
                println("Discovered target device: ${target.name} [${target.address}], connecting...")
                ZKBrainManager.stopScan()
                ZKBrainManager.connect(target)
            }
        }
    }
    // 2. Start 10s timeout scan / 开启 10 秒超时扫描
    ZKBrainManager.startScan(timeoutMillis = 10000L)
}
```

---

## ⚡ Recipe 2: Reactive 1Hz Attention & 8-Band Stream (Compose / Coroutines) / 响应式消费 1Hz 专注度与 8 频段能量

```kotlin
import com.zkteco.zkbrain.ZKBrainManager
import androidx.compose.runtime.*
import androidx.compose.foundation.layout.*
import androidx.compose.material.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp

@Composable
fun AttentionMonitorView() {
    val brainData by ZKBrainManager.brainData.collectAsState(initial = null)
    
    Column(modifier = Modifier.padding(16.dp)) {
        Text("Attention: ${brainData?.attention ?: 0} / 100", style = MaterialTheme.typography.h6)
        Text("Meditation: ${brainData?.meditation ?: 0} / 100")
        Text("Signal: ${if (brainData?.poorSignal == 0) "Good Contact 🟢" else "Poor Signal / Off-Head 🔴"}")
        LinearProgressIndicator(
            progress = (brainData?.attention ?: 0) / 100f,
            modifier = Modifier.fillMaxWidth().height(8.dp)
        )
    }
}
```

---

## ⚡ Recipe 3: High-Frequency 512Hz Raw Waveform Canvas (RingBuffer) / Compose 极速绘制 512Hz 原始波形

```kotlin
import com.zkteco.zkbrain.ZKBrainManager
import androidx.compose.foundation.Canvas
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.unit.dp
import androidx.compose.foundation.layout.*

@Composable
fun RawWaveformChart(modifier: Modifier = Modifier.fillMaxWidth().height(120.dp)) {
    val points = remember { mutableStateListOf<Float>() }
    
    // Safely consume 512Hz high-frequency stream with RingBuffer / 512Hz 定长环形缓冲接入
    LaunchedEffect(Unit) {
        ZKBrainManager.rawdata.collect { raw ->
            if (points.size > 300) points.removeFirst()
            points.add(raw.toFloat())
        }
    }

    Canvas(modifier = modifier) {
        if (points.size < 2) return@Canvas
        val path = Path()
        val stepX = size.width / 300f
        val centerY = size.height / 2f
        points.forEachIndexed { i, p ->
            val y = centerY - (p / 2048f) * centerY // Microvolt normalization / 微伏归一化
            if (i == 0) path.moveTo(0f, y) else path.lineTo(i * stepX, y)
        }
        drawPath(path, color = Color.Green, style = Stroke(width = 2.dp.toPx()))
    }
}
```

---

## ⚡ Recipe 4: Native iOS (Swift) Consumer (SKIE async/await) / 原生 iOS (Swift) 极简消费

```swift
import SwiftUI
import zkbrain_parser

class BrainViewModel: ObservableObject {
    @Published var attention: Int32 = 0
    @Published var meditation: Int32 = 0

    func startListening() {
        // Automatically bridged as native Swift AsyncSequence / 自动桥接为 Swift 原生 AsyncSequence
        Task {
            for await eeg in ZKBrainManager.shared.brainData {
                await MainActor.run {
                    self.attention = eeg.attention
                    self.meditation = eeg.meditation
                }
            }
        }
    }
}
```

---

## ⚡ Recipe 5: One-Click Standard Cloud Recording & Upload / 一键标准化云端录制与自动上传

```kotlin
import com.zkteco.zkbrain.record.ZKBrainCloudRecordManager

suspend fun runStandardRecordingFlow(serverUrl: String, apiKey: String) {
    // 1. Start recording session / 开启录制会话
    val sessionId = ZKBrainCloudRecordManager.startRecording(sessionType = "concentration_test")
    println("Session created: $sessionId")

    // 2. Inject business event tag / 注入业务时间锚点打标
    ZKBrainCloudRecordManager.appendEvent(eventCode = 101, eventName = "task_stimulus_appear")

    // 3. Conclude recording, stitch 3-table dataset, and upload / 终结录制并直传云端
    val result = ZKBrainCloudRecordManager.stopAndUpload(serverUrl = serverUrl, apiKey = apiKey)
    result.onSuccess { report -> println("Cloud analysis completed, score: ${report.score}") }
}
```

---

## ⚡ Recipe 6: Hardware Command Dispatch & 6-Axis MEMS (Cross-Platform) / 硬件指令下发与 MEMS 姿态使能

### Android Native / Jetpack Compose:
```kotlin
// 1. Enable 6-axis MEMS IMU stream / 开启 MEMS 姿态惯导流
val address = ZKBrainManager.connectedDevice.value?.address ?: return
ZKBrainManager.writeCommand(address, "mems_on:1;\n".toByteArray(Charsets.UTF_8))

// 2. Listen to hardware response and quaternion posture / 监听硬件响应与四元数姿态
lifecycleScope.launch {
    ZKBrainManager.commandResponse.collect { response ->
        Log.d("ZKBrain", "Hardware response: $response")
    }
}
lifecycleScope.launch {
    ZKBrainManager.quaternionData.collect { q ->
        Log.d("ZKBrain", "Spatial quaternion: w=${q.q0}, x=${q.q1}, y=${q.q2}, z=${q.q3}")
    }
}
```

### iOS (Swift):
```swift
// Dispatch MEMS enable command / 下发开启 MEMS 指令
if let dev = ZKBrainManager.shared.connectedDevice.value {
    let bytes = Array("mems_on:1;\n".utf8)
    let kBytes = KotlinByteArray(size: Int32(bytes.count))
    for (i, b) in bytes.enumerated() { kBytes.set(index: Int32(i), value: Int8(bitPattern: b)) }
    ZKBrainManager.shared.writeCommand(address: dev.address, command: kBytes)
}
```

### Web & WeChat MiniProgram (TypeScript):
```typescript
// Web / MiniProgram dispatch / Web 与小程序端下发
await sdk.sendAsciiCommand("mems_on:1;\n");
// Listen to posture data / 监听空间姿态
sdk.on("posture_data", (gravity) => {
    console.log(`Pitch=${gravity.x}, Roll=${gravity.y}, Yaw=${gravity.z}`);
});
```
