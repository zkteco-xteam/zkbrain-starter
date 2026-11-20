package com.zkteco.zkbrain.composeapp.ui

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.zkteco.zkbrain.ZKBrainManager
import com.zkteco.zkbrain.bean.MultiBrainEeg
import com.zkteco.zkbrain.bean.ZKBrainConnectionState
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.collectLatest
import kotlinx.coroutines.launch
import kotlin.math.min

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun DashboardScreen() {
    val connState by ZKBrainManager.connState.collectAsState()
    val scannedDevices by ZKBrainManager.scannedDevices.collectAsState()
    var latestEeg by remember { mutableStateOf<MultiBrainEeg?>(null) }
    var waveBuffer by remember { mutableStateOf<List<Float>>(emptyList()) }
    val ringBuffer = remember { ArrayDeque<Float>(300) }

    // 监听 1Hz 综合脑电指标
    LaunchedEffect(Unit) {
        ZKBrainManager.brainData.collectLatest { eeg ->
            latestEeg = eeg
        }
    }

    // 监听 512Hz 原始波微伏采样
    LaunchedEffect(Unit) {
        launch(Dispatchers.Default) {
            ZKBrainManager.rawdata.collectLatest { raw ->
                synchronized(ringBuffer) {
                    if (ringBuffer.size >= 300) ringBuffer.removeFirst()
                    ringBuffer.add(raw.toFloat())
                    waveBuffer = ringBuffer.toList()
                }
            }
        }
    }

    // 计算心流与疲劳
    val eeg = latestEeg
    val bw = eeg?.brainWaves
    val activePower = ((bw?.lowBeta ?: 0) + (bw?.highBeta ?: 0) + (bw?.lowAlpha ?: 0)).coerceAtLeast(1)
    val fatigue = min(100, (((bw?.theta ?: 0).toDouble() / activePower) * 80).toInt())
    val flowLevel = when {
        (eeg?.attentionLevel ?: 0) >= 75 && (eeg?.meditationDepth ?: 0) >= 60 -> "✨ 深度心流 (Deep Flow)"
        (eeg?.attentionLevel ?: 0) >= 65 -> "🎯 高度专注 (Focused)"
        (eeg?.meditationDepth ?: 0) >= 70 -> "🧘 放松冥想 (Meditation)"
        fatigue >= 65 -> "💤 疲劳预警 (Fatigued)"
        else -> "平静日常 (Normal)"
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("ZKBrain Jetpack Compose 交互看板", fontSize = 18.sp) },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = Color(0xFF0F172A),
                    titleContentColor = Color.White
                )
            )
        }
    ) { padding ->
        Column(
            modifier = Modifier
                .padding(padding)
                .fillMaxSize()
                .verticalScroll(rememberScrollState())
                .padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            // 1. 链路控制卡片
            Card(
                shape = RoundedCornerShape(12.dp),
                colors = CardDefaults.cardColors(containerColor = Color(0xFF1E293B)),
                modifier = Modifier.fillMaxWidth()
            ) {
                Row(
                    modifier = Modifier.padding(16.dp),
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.SpaceBetween
                ) {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Box(
                            modifier = Modifier
                                .size(12.dp)
                                .background(
                                    color = when (connState) {
                                        ZKBrainConnectionState.CONNECTED -> Color(0xFF22C55E)
                                        ZKBrainConnectionState.CONNECTING -> Color(0xFFF59E0B)
                                        else -> Color(0xFFEF4444)
                                    },
                                    shape = CircleShape
                                )
                        )
                        Spacer(modifier = Modifier.width(8.dp))
                        Text(
                            text = "链路: ${connState.name}",
                            color = Color.White,
                            fontSize = 15.sp
                        )
                    }

                    Button(
                        onClick = {
                            if (connState == ZKBrainConnectionState.DISCONNECTED) {
                                ZKBrainManager.startScan(timeoutMillis = 10000L)
                                val target = scannedDevices.firstOrNull()
                                if (target != null) ZKBrainManager.connect(target)
                            } else {
                                ZKBrainManager.disconnect()
                            }
                        },
                        colors = ButtonDefaults.buttonColors(
                            containerColor = if (connState == ZKBrainConnectionState.CONNECTED) Color(0xFFDC2626) else Color(0xFF2563EB)
                        )
                    ) {
                        Text(if (connState == ZKBrainConnectionState.CONNECTED) "断开设备" else "⚡ 扫描并连接")
                    }
                }
            }

            // 2. 专注与放松核心指标
            Card(
                shape = RoundedCornerShape(12.dp),
                colors = CardDefaults.cardColors(containerColor = Color(0xFF1E293B)),
                modifier = Modifier.fillMaxWidth()
            ) {
                Column(modifier = Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
                    Text("核心认知指标 (1Hz eSense)", color = Color.White, fontSize = 16.sp)

                    Column {
                        Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
                            Text("专注度 (Attention)", color = Color(0xFF94A3B8), fontSize = 14.sp)
                            Text("${eeg?.attentionLevel ?: 0} / 100", color = Color(0xFF38BDF8), fontSize = 14.sp)
                        }
                        LinearProgressIndicator(
                            progress = { (eeg?.attentionLevel ?: 0) / 100f },
                            modifier = Modifier.fillMaxWidth().height(8.dp),
                            color = Color(0xFF38BDF8)
                        )
                    }

                    Column {
                        Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
                            Text("放松度 (Meditation)", color = Color(0xFF94A3B8), fontSize = 14.sp)
                            Text("${eeg?.meditationDepth ?: 0} / 100", color = Color(0xFF4ADE80), fontSize = 14.sp)
                        }
                        LinearProgressIndicator(
                            progress = { (eeg?.meditationDepth ?: 0) / 100f },
                            modifier = Modifier.fillMaxWidth().height(8.dp),
                            color = Color(0xFF4ADE80)
                        )
                    }

                    Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
                        Text("当前心流状态: $flowLevel", color = Color(0xFFFBBF24), fontSize = 13.sp)
                        Text("疲劳指数: $fatigue%", color = if (fatigue >= 60) Color(0xFFF87171) else Color(0xFF94A3B8), fontSize = 13.sp)
                    }
                }
            }

            // 3. 512Hz 示波器波形
            Card(
                shape = RoundedCornerShape(12.dp),
                colors = CardDefaults.cardColors(containerColor = Color(0xFF0F172A)),
                modifier = Modifier.fillMaxWidth().height(160.dp)
            ) {
                Column(modifier = Modifier.padding(12.dp)) {
                    Text("512Hz 实时脑电波示波器 (Raw EEG, μV)", color = Color(0xFF38BDF8), fontSize = 13.sp)
                    Spacer(modifier = Modifier.height(8.dp))
                    Canvas(modifier = Modifier.fillMaxSize()) {
                        val w = size.width
                        val h = size.height
                        val midY = h / 2f

                        // 绘制微弱基线
                        drawLine(Color(0xFF334155), Offset(0f, midY), Offset(w, midY), strokeWidth = 1f)

                        if (waveBuffer.size >= 2) {
                            val path = Path()
                            val stepX = w / (waveBuffer.size - 1)
                            waveBuffer.forEachIndexed { i, value ->
                                val x = i * stepX
                                val y = (midY - (value / 250f) * (h / 2.5f)).coerceIn(0f, h)
                                if (i == 0) path.moveTo(x, y) else path.lineTo(x, y)
                            }
                            drawPath(path, color = Color(0xFF00E5FF), style = Stroke(width = 2.dp.toPx()))
                        }
                    }
                }
            }

            // 4. 8 频段绝对能量分布
            Card(
                shape = RoundedCornerShape(12.dp),
                colors = CardDefaults.cardColors(containerColor = Color(0xFF1E293B)),
                modifier = Modifier.fillMaxWidth()
            ) {
                Column(modifier = Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
                    Text("脑波 8 频段能量分布 (EEG Power Spectrum)", color = Color.White, fontSize = 16.sp)
                    PowerBarRow("Delta (0.5-2.75Hz 深度睡眠)", bw?.delta ?: 0, Color(0xFF818CF8))
                    PowerBarRow("Theta (3.5-6.75Hz 冥想/创意)", bw?.theta ?: 0, Color(0xFF38BDF8))
                    PowerBarRow("Low Alpha (7.5-9.25Hz 放松闭眼)", bw?.lowAlpha ?: 0, Color(0xFF34D399))
                    PowerBarRow("High Alpha (10-11.75Hz 心流静心)", bw?.highAlpha ?: 0, Color(0xFF4ADE80))
                    PowerBarRow("Low Beta (13-16.75Hz 轻度专注)", bw?.lowBeta ?: 0, Color(0xFFFBBF24))
                    PowerBarRow("High Beta (17-29.75Hz 紧张计算)", bw?.highBeta ?: 0, Color(0xFFFB923C))
                    PowerBarRow("Low Gamma (31-39.75Hz 认知加工)", bw?.lowGamma ?: 0, Color(0xFFF43F5E))
                    PowerBarRow("Middle Gamma (41-49.75Hz 高阶多感官)", bw?.middleGamma ?: 0, Color(0xFFE11D48))
                }
            }
        }
    }
}

@Composable
private fun PowerBarRow(name: String, power: Int, color: Color) {
    val norm = (power / 50000f).coerceIn(0f, 1f)
    Column(modifier = Modifier.fillMaxWidth().padding(vertical = 2.dp)) {
        Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
            Text(name, color = Color(0xFFCBD5E1), fontSize = 12.sp)
            Text("$power", color = color, fontSize = 12.sp)
        }
        LinearProgressIndicator(
            progress = { norm },
            modifier = Modifier.fillMaxWidth().height(4.dp),
            color = color
        )
    }
}
