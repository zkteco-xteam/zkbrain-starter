package com.zkteco.zkbrain.starter

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.zkteco.zkbrain.bean.ZKBrainConnectionState

/**
 * 🌟 极简全能脑机交互控制台 (包含 8 频段频谱、实时示波器与心流/疲劳评估)
 */
@Composable
fun SampleScreen(
    state: SampleState,
    onIntent: (SampleIntent) -> Unit,
    modifier: Modifier = Modifier
) {
    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("ZKBrain 脑机交互控制台", fontSize = 18.sp) },
                actions = {
                    Button(
                        onClick = { onIntent(SampleIntent.ToggleScan) },
                        colors = ButtonDefaults.buttonColors(
                            backgroundColor = if (state.isScanning) Color(0xFFE53935) else Color(0xFF2563EB)
                        ),
                        shape = RoundedCornerShape(8.dp),
                        modifier = Modifier.padding(end = 8.dp)
                    ) {
                        Text(if (state.isScanning) "停止扫描" else "⚡ 扫描设备", color = Color.White)
                    }
                },
                backgroundColor = Color(0xFF1E293B),
                contentColor = Color.White
            )
        },
        modifier = modifier.fillMaxSize()
    ) { padding ->
        val scrollState = rememberScrollState()

        Column(
            modifier = Modifier
                .padding(padding)
                .fillMaxSize()
                .verticalScroll(scrollState)
                .padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            // ==========================================
            // 1. 蓝牙连接状态卡片
            // ==========================================
            Card(
                shape = RoundedCornerShape(12.dp),
                elevation = 4.dp,
                backgroundColor = Color(0xFF1E293B),
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
                                    color = when (state.connectionState) {
                                        ZKBrainConnectionState.CONNECTED -> Color(0xFF22C55E)
                                        ZKBrainConnectionState.CONNECTING -> Color(0xFFF59E0B)
                                        else -> Color(0xFFEF4444)
                                    },
                                    shape = CircleShape
                                )
                        )
                        Spacer(modifier = Modifier.width(12.dp))
                        Column {
                            Text(
                                "链路状态: ${state.connectionState.name}",
                                style = MaterialTheme.typography.subtitle1,
                                color = Color.White
                            )
                            Text(
                                text = state.connectedDevice?.let { "已配对: ${it.name ?: "未知"} (${it.address})" }
                                    ?: "未连接脑电设备 (请先扫描周围设备)",
                                style = MaterialTheme.typography.caption,
                                color = Color(0xFF94A3B8)
                            )
                        }
                    }

                    if (state.connectionState == ZKBrainConnectionState.CONNECTED) {
                        OutlinedButton(
                            onClick = { onIntent(SampleIntent.Disconnect) },
                            colors = ButtonDefaults.outlinedButtonColors(contentColor = Color(0xFFF87171))
                        ) {
                            Text("断开")
                        }
                    }
                }
            }

            // ==========================================
            // 2. 512Hz 原始脑电示波器 (Raw EEG Canvas)
            // ==========================================
            Card(
                shape = RoundedCornerShape(12.dp),
                elevation = 4.dp,
                backgroundColor = Color(0xFF1E293B),
                modifier = Modifier.fillMaxWidth()
            ) {
                Column(modifier = Modifier.padding(16.dp)) {
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Text("Raw EEG 原始脑电微伏波形", style = MaterialTheme.typography.subtitle1, color = Color.White)
                        Text(
                            text = if (state.rawSampleRate > 0) "⚡ 采样率: ${state.rawSampleRate} Hz" else "512 Hz",
                            fontSize = 12.sp,
                            color = Color(0xFF38BDF8)
                        )
                    }
                    Spacer(modifier = Modifier.height(10.dp))
                    Canvas(
                        modifier = Modifier
                            .fillMaxWidth()
                            .height(140.dp)
                            .background(Color(0xFF090D16), shape = RoundedCornerShape(8.dp))
                    ) {
                        // 绘制背景微网格
                        val gridStep = size.width / 10f
                        for (i in 0..10) {
                            drawLine(
                                color = Color(0xFF1E293B),
                                start = Offset(i * gridStep, 0f),
                                end = Offset(i * gridStep, size.height),
                                strokeWidth = 1f
                            )
                        }
                        drawLine(
                            color = Color(0xFF334155),
                            start = Offset(0f, size.height / 2f),
                            end = Offset(size.width, size.height / 2f),
                            strokeWidth = 1f
                        )

                        // 绘制脑电曲线
                        val points = state.rawWaveBuffer
                        if (points.size >= 2) {
                            val path = Path()
                            val stepX = size.width / (points.size - 1)
                            val centerY = size.height / 2f

                            points.forEachIndexed { i, raw ->
                                val y = centerY - (raw / 1500f) * centerY
                                if (i == 0) path.moveTo(0f, y) else path.lineTo(i * stepX, y)
                            }
                            drawPath(path, color = Color(0xFF00E676), style = Stroke(width = 2.dp.toPx()))
                        }
                    }
                }
            }

            // ==========================================
            // 3. 实时认知与生理指标大屏 (1Hz)
            // ==========================================
            val eeg = state.brainData
            Card(
                shape = RoundedCornerShape(12.dp),
                elevation = 4.dp,
                backgroundColor = Color(0xFF1E293B),
                modifier = Modifier.fillMaxWidth()
            ) {
                Column(modifier = Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(14.dp)) {
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween
                    ) {
                        Text("实时脑波生理指标 (1Hz)", style = MaterialTheme.typography.subtitle1, color = Color.White)
                        Text(state.flowStateLevel, fontSize = 13.sp, color = Color(0xFFFBBF24))
                    }

                    // 专注度
                    Column {
                        Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
                            Text("专注度 (Attention)", color = Color(0xFFCBD5E1), fontSize = 14.sp)
                            Text("${eeg?.attention ?: 0} / 100", color = Color(0xFF60A5FA), fontSize = 14.sp)
                        }
                        Spacer(modifier = Modifier.height(4.dp))
                        LinearProgressIndicator(
                            progress = (eeg?.attention ?: 0) / 100f,
                            color = Color(0xFF3B82F6),
                            backgroundColor = Color(0xFF334155),
                            modifier = Modifier.fillMaxWidth().height(8.dp)
                        )
                    }

                    // 放松度
                    Column {
                        Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
                            Text("放松度 (Meditation)", color = Color(0xFFCBD5E1), fontSize = 14.sp)
                            Text("${eeg?.meditation ?: 0} / 100", color = Color(0xFF4ADE80), fontSize = 14.sp)
                        }
                        Spacer(modifier = Modifier.height(4.dp))
                        LinearProgressIndicator(
                            progress = (eeg?.meditation ?: 0) / 100f,
                            color = Color(0xFF22C55E),
                            backgroundColor = Color(0xFF334155),
                            modifier = Modifier.fillMaxWidth().height(8.dp)
                        )
                    }

                    // 疲劳指数预警
                    Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
                        Text("疲劳预警指数 (Theta/Beta 比值):", color = Color(0xFF94A3B8), fontSize = 13.sp)
                        Text("${state.fatigueIndex}%", color = if (state.fatigueIndex >= 60) Color(0xFFEF4444) else Color(0xFF22C55E), fontSize = 13.sp)
                    }

                    // 电极接触状态
                    Text(
                        text = "电极皮肤接触: ${if (eeg?.poorSignal == 0) "🟢 良好佩戴 (0)" else "🔴 接触不良或脱落 (${eeg?.poorSignal})"}",
                        color = if (eeg?.poorSignal == 0) Color(0xFF4ADE80) else Color(0xFFF87171),
                        fontSize = 13.sp
                    )
                }
            }

            // ==========================================
            // 4. 脑电 8 频段功率谱能量分布 (Band Powers)
            // ==========================================
            if (eeg != null) {
                Card(
                    shape = RoundedCornerShape(12.dp),
                    elevation = 4.dp,
                    backgroundColor = Color(0xFF1E293B),
                    modifier = Modifier.fillMaxWidth()
                ) {
                    Column(modifier = Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
                        Text("脑电 8 频段绝对功率分布", style = MaterialTheme.typography.subtitle1, color = Color.White)
                        BandPowerRow("Delta (0.5-2.75Hz 深度睡眠)", eeg.delta, Color(0xFF818CF8))
                        BandPowerRow("Theta (3.5-6.75Hz 潜意识/冥想)", eeg.theta, Color(0xFF38BDF8))
                        BandPowerRow("Low Alpha (7.5-9.25Hz 放松心流)", eeg.lowAlpha, Color(0xFF34D399))
                        BandPowerRow("High Alpha (10-11.75Hz 心流静定)", eeg.highAlpha, Color(0xFFA7F3D0))
                        BandPowerRow("Low Beta (13-16.75Hz 警觉专注)", eeg.lowBeta, Color(0xFFFBBF24))
                        BandPowerRow("High Beta (17-29.75Hz 计算焦虑)", eeg.highBeta, Color(0xFFFB923C))
                        BandPowerRow("Low Gamma (31-39.75Hz 认知加工)", eeg.lowGamma, Color(0xFFF472B6))
                        BandPowerRow("Mid Gamma (41-49.75Hz 高阶感知)", eeg.midGamma, Color(0xFFE879F9))
                    }
                }
            }

            // ==========================================
            // 5. 发现的脑电设备列表
            // ==========================================
            if (state.scannedDevices.isNotEmpty()) {
                Text("周围发现的脑电设备 (点击配对建连):", color = Color(0xFF94A3B8), fontSize = 14.sp)
                state.scannedDevices.forEach { dev ->
                    Card(
                        modifier = Modifier
                            .fillMaxWidth()
                            .clickable { onIntent(SampleIntent.ConnectDevice(dev)) },
                        backgroundColor = Color(0xFF1E293B),
                        shape = RoundedCornerShape(8.dp)
                    ) {
                        Row(
                            modifier = Modifier.padding(14.dp),
                            horizontalArrangement = Arrangement.SpaceBetween,
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Column {
                                Text(dev.name ?: "未知脑电设备", color = Color.White, fontSize = 15.sp)
                                Text(dev.address, color = Color(0xFF64748B), fontSize = 12.sp)
                            }
                            Text("${dev.rssi} dBm", color = Color(0xFF38BDF8), fontSize = 13.sp)
                        }
                    }
                }
            }
        }
    }
}

@Composable
private fun BandPowerRow(name: String, power: Int, barColor: Color) {
    Column {
        Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
            Text(name, color = Color(0xFF94A3B8), fontSize = 12.sp)
            Text(power.toString(), color = Color.White, fontSize = 12.sp)
        }
        Spacer(modifier = Modifier.height(2.dp))
        LinearProgressIndicator(
            progress = (power % 100000) / 100000f,
            color = barColor,
            backgroundColor = Color(0xFF334155),
            modifier = Modifier.fillMaxWidth().height(4.dp)
        )
    }
}
