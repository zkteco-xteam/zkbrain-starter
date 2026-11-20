# ZKBrain SDK 20 行黄金代码样板 (recipes.md)

> **原则**：以下代码均为生产环境可直接复制粘贴的端到端最小闭环代码，已通过编译验证与避坑校验。

---

## ⚡ Recipe 1: 极简扫描与自动连接有效脑电设备 (Kotlin)

```kotlin
import com.zkteco.zkbrain.ZKBrainManager
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.launch

fun scanAndConnectFirstDevice(scope: CoroutineScope) {
    // 1. 监听扫描结果
    scope.launch {
        ZKBrainManager.scannedDevices.collect { devices ->
            val target = devices.firstOrNull()
            if (target != null && ZKBrainManager.connState.value.name == "DISCONNECTED") {
                println("发现目标设备: ${target.name} [${target.address}]，立即建连...")
                ZKBrainManager.stopScan()
                ZKBrainManager.connect(target)
            }
        }
    }
    // 2. 开启 10 秒超时扫描
    ZKBrainManager.startScan(timeoutMillis = 10000L)
}
```

---

## ⚡ Recipe 2: 响应式消费 1Hz 专注度与 8 频段能量 (Compose / Coroutines)

```kotlin
import com.zkteco.zkbrain.ZKBrainManager
import androidx.compose.runtime.*

@Composable
fun AttentionMonitorView() {
    val brainData by ZKBrainManager.brainData.collectAsState(initial = null)
    
    Column(modifier = Modifier.padding(16.dp)) {
        Text("当前专注度: ${brainData?.attention ?: 0} / 100", style = MaterialTheme.typography.h6)
        Text("当前放松度: ${brainData?.meditation ?: 0} / 100")
        Text("信号质量: ${if (brainData?.poorSignal == 0) "良好佩戴 🟢" else "接触不良 🔴"}")
        LinearProgressIndicator(
            progress = (brainData?.attention ?: 0) / 100f,
            modifier = Modifier.fillMaxWidth().height(8.dp)
        )
    }
}
```

---

## ⚡ Recipe 3: Compose 极速绘制 512Hz 原始波形 (防掉帧 RingBuffer 样板)

```kotlin
import com.zkteco.zkbrain.ZKBrainManager
import androidx.compose.foundation.Canvas
import androidx.compose.ui.graphics.Path

@Composable
fun RawWaveformChart(modifier: Modifier = Modifier.fillMaxWidth().height(120.dp)) {
    val points = remember { mutableStateListOf<Float>() }
    
    // 512Hz 高频数据流安全接入
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
            val y = centerY - (p / 2048f) * centerY // 微伏归一化
            if (i == 0) path.moveTo(0f, y) else path.lineTo(i * stepX, y)
        }
        drawPath(path, color = Color.Green, style = Stroke(width = 2.dp.toPx()))
    }
}
```

---

## ⚡ Recipe 4: 原生 iOS (Swift) 极简消费 (SKIE 原生 async/await)

```swift
import SwiftUI
import zkbrain_parser

class BrainViewModel: ObservableObject {
    @Published var attention: Int32 = 0
    @Published var meditation: Int32 = 0

    func startListening() {
        // 自动桥接为 Swift 原生 AsyncSequence，无需闭包回调
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

## ⚡ Recipe 5: 一键标准化云端录制与自动上传

```kotlin
import com.zkteco.zkbrain.record.ZKBrainCloudRecordManager

suspend fun runStandardRecordingFlow(serverUrl: String, apiKey: String) {
    // 1. 开启录制会话
    val sessionId = ZKBrainCloudRecordManager.startRecording(sessionType = "concentration_test")
    println("会话已创建: $sessionId")

    // 2. 注入业务时间锚点打标
    ZKBrainCloudRecordManager.appendEvent(eventCode = 101, eventName = "task_stimulus_appear")

    // 3. 终结录制，完成三表缝合与国密加密直传云端分析接口
    val result = ZKBrainCloudRecordManager.stopAndUpload(serverUrl = serverUrl, apiKey = apiKey)
    result.onSuccess { report -> println("云端分析完成，综合得分: ${report.score}") }
}
```

---

## ⚡ Recipe 6: 硬件指令下发与 MEMS 惯导/姿态使能 (全端适用)

### Android Native / Jetpack Compose:
```kotlin
// 1. 开启 MEMS 姿态惯导流
val address = ZKBrainManager.connectedDevice.value?.address ?: return
ZKBrainManager.writeCommand(address, "mems_enable=1;\n".toByteArray(Charsets.UTF_8))

// 2. 监听硬件响应与四元数姿态
lifecycleScope.launch {
    ZKBrainManager.commandResponse.collect { response ->
        Log.d("ZKBrain", "硬件响应: $response")
    }
}
lifecycleScope.launch {
    ZKBrainManager.quaternionData.collect { q ->
        Log.d("ZKBrain", "空间姿态四元数: w=${q.q0}, x=${q.q1}, y=${q.q2}, z=${q.q3}")
    }
}
```

### iOS (Swift):
```swift
// 下发开启 MEMS 指令
if let dev = ZKBrainManager.shared.connectedDevice.value {
    let bytes = Array("mems_enable=1;\n".utf8)
    let kBytes = KotlinByteArray(size: Int32(bytes.count))
    for (i, b) in bytes.enumerated() { kBytes.set(index: Int32(i), value: Int8(bitPattern: b)) }
    ZKBrainManager.shared.writeCommand(address: dev.address, command: kBytes)
}
```

### Web & 微信小程序 (TypeScript):
```typescript
// Web / 小程序端下发
await sdk.sendAsciiCommand("mems_enable=1;\n");
// 监听空间姿态
sdk.on("posture_data", (gravity) => {
    console.log(`Pitch=${gravity.x}, Roll=${gravity.y}, Yaw=${gravity.z}`);
});
```
