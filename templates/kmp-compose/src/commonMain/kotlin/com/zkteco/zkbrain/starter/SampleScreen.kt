package com.zkteco.zkbrain.starter

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.unit.dp
import com.zkteco.zkbrain.bean.ZKBrainConnectionState

/**
 * 🌟 极简脑电监控与波形展示 Screen
 * 结构最清晰、注释最完备的垂直切片 UI 黄金范式
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
                title = { Text("ZKBrain 脑机交互控制台") },
                actions = {
                    Button(
                        onClick = { onIntent(SampleIntent.ToggleScan) },
                        colors = ButtonDefaults.buttonColors(
                            backgroundColor = if (state.isScanning) Color.Red else MaterialTheme.colors.primary
                        )
                    ) {
                        Text(if (state.isScanning) "停止扫描" else "扫描设备", color = Color.White)
                    }
                }
            )
        },
        modifier = modifier.fillMaxSize()
    ) { padding ->
        Column(
            modifier = Modifier
                .padding(padding)
                .padding(16.dp)
                .fillMaxSize(),
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            // 1. 连接状态卡片
            Card(
                shape = RoundedCornerShape(8.dp),
                elevation = 4.dp,
                modifier = Modifier.fillMaxWidth()
            ) {
                Row(
                    modifier = Modifier.padding(16.dp),
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.SpaceBetween
                ) {
                    Column {
                        Text("链路状态: ${state.connectionState.name}", style = MaterialTheme.typography.subtitle1)
                        Text(
                            text = state.connectedDevice?.let { "已连接: ${it.name ?: "未知"} (${it.address})" }
                                ?: "未连接任何脑电设备",
                            style = MaterialTheme.typography.caption
                        )
                    }
                    if (state.connectionState == ZKBrainConnectionState.CONNECTED) {
                        OutlinedButton(onClick = { onIntent(SampleIntent.Disconnect) }) {
                            Text("断开")
                        }
                    }
                }
            }

            // 2. 核心指标：专注度与放松度进度卡片
            val eeg = state.brainData
            Card(
                shape = RoundedCornerShape(8.dp),
                elevation = 4.dp,
                modifier = Modifier.fillMaxWidth()
            ) {
                Column(
                    modifier = Modifier.padding(16.dp),
                    verticalArrangement = Arrangement.spacedBy(12.dp)
                ) {
                    Text("实时脑波生理指标 (1Hz)", style = MaterialTheme.typography.h6)

                    // 专注度
                    Text("专注度 (Attention): ${eeg?.attention ?: 0} / 100")
                    LinearProgressIndicator(
                        progress = (eeg?.attention ?: 0) / 100f,
                        color = Color(0xFF2196F3),
                        modifier = Modifier.fillMaxWidth().height(8.dp)
                    )

                    // 放松度
                    Text("放松度 (Meditation): ${eeg?.meditation ?: 0} / 100")
                    LinearProgressIndicator(
                        progress = (eeg?.meditation ?: 0) / 100f,
                        color = Color(0xFF4CAF50),
                        modifier = Modifier.fillMaxWidth().height(8.dp)
                    )

                    Text(
                        text = "接触阻抗/信号质量: ${if (eeg?.poorSignal == 0) "🟢 良好接触 (0)" else "🔴 接触不良 (${eeg?.poorSignal})"}",
                        style = MaterialTheme.typography.caption
                    )
                }
            }

            // 3. 512Hz 原始微伏脑电波实时波形画布 (防掉帧 Canvas)
            Card(
                shape = RoundedCornerShape(8.dp),
                elevation = 4.dp,
                modifier = Modifier.fillMaxWidth()
            ) {
                Column(modifier = Modifier.padding(16.dp)) {
                    Text("Raw EEG 原始脑电波形 (512Hz)", style = MaterialTheme.typography.subtitle1)
                    Spacer(modifier = Modifier.height(8.dp))
                    Canvas(
                        modifier = Modifier
                            .fillMaxWidth()
                            .height(140.dp)
                            .background(Color(0xFF1E1E1E), shape = RoundedCornerShape(4.dp))
                    ) {
                        val points = state.rawWaveBuffer
                        if (points.size < 2) return@Canvas

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

            // 4. 扫描到的设备列表
            if (state.scannedDevices.isNotEmpty()) {
                Text("发现的脑电设备 (点击连接):", style = MaterialTheme.typography.subtitle1)
                LazyColumn(
                    modifier = Modifier.fillMaxWidth().weight(1f),
                    verticalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    items(state.scannedDevices) { dev ->
                        Card(
                            modifier = Modifier
                                .fillMaxWidth()
                                .clickable { onIntent(SampleIntent.ConnectDevice(dev)) },
                            backgroundColor = Color(0xFFF5F5F5)
                        ) {
                            Row(
                                modifier = Modifier.padding(12.dp),
                                horizontalArrangement = Arrangement.SpaceBetween,
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                Column {
                                    Text(dev.name ?: "未知设备", style = MaterialTheme.typography.body1)
                                    Text(dev.address, style = MaterialTheme.typography.caption)
                                }
                                Text("RSSI: ${dev.rssi} dBm", style = MaterialTheme.typography.caption)
                            }
                        }
                    }
                }
            }
        }
    }
}
