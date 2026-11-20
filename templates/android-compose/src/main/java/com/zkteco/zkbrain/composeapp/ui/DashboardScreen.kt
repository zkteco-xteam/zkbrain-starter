package com.zkteco.zkbrain.composeapp.ui

import android.Manifest
import android.content.pm.PackageManager
import android.os.Build
import android.widget.Toast
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.window.Dialog
import androidx.compose.ui.window.DialogProperties
import androidx.core.content.ContextCompat
import com.zkteco.zkbrain.ZKBrainManager
import com.zkteco.zkbrain.bean.MultiBrainEeg
import com.zkteco.zkbrain.bean.ZKBrainConnectionState
import com.zkteco.zkbrain.bean.ZKBrainDevice
import kotlinx.coroutines.flow.collectLatest
import kotlinx.coroutines.launch
import kotlin.math.round

/**
 * 🌟 1:1 完整逐项还原 shared1 设备管理控制台 (DeviceScreen) - Jetpack Compose 原生版
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun DashboardScreen() {
    val context = LocalContext.current
    val coroutineScope = rememberCoroutineScope()

    // 响应式流状态收集
    val connState by ZKBrainManager.connState.collectAsState()
    val connectedDevice by ZKBrainManager.connectedDevice.collectAsState()
    val scannedDevices by ZKBrainManager.scannedDevices.collectAsState()
    val scanState by ZKBrainManager.scanState.collectAsState()

    var brainData by remember { mutableStateOf<MultiBrainEeg?>(null) }
    var batteryLevel by remember { mutableIntStateOf(0) }
    var terminalLogs by remember { mutableStateOf<List<String>>(emptyList()) }
    var showScanDialog by remember { mutableStateOf(false) }

    // MEMS 姿态与欧拉角
    var memsX by remember { mutableFloatStateOf(0f) }
    var memsY by remember { mutableFloatStateOf(0f) }
    var memsZ by remember { mutableFloatStateOf(0f) }
    var memsQ0 by remember { mutableFloatStateOf(1f) }
    var memsQ1 by remember { mutableFloatStateOf(0f) }
    var memsQ2 by remember { mutableFloatStateOf(0f) }
    var memsQ3 by remember { mutableFloatStateOf(0f) }

    // 通道与图表显隐配置
    var isFp1Visible by remember { mutableStateOf(true) }
    var isFp2Visible by remember { mutableStateOf(false) }
    val chartToggles = remember {
        mutableStateMapOf(
            "Raw EEG" to true,
            "Signal Quality" to true,
            "Attention" to true,
            "Meditation" to true,
            "Delta" to true,
            "Theta" to true,
            "Low Alpha" to true,
            "High Alpha" to true,
            "Low Beta" to true,
            "High Beta" to true,
            "Low Gamma" to true,
            "Middle Gamma" to true
        )
    }

    var customCmdInput by remember { mutableStateOf("") }
    var writeSnInput by remember { mutableStateOf("") }
    var dfuStatus by remember { mutableStateOf("DFU: 空闲就绪") }

    val isConnected = (connState == ZKBrainConnectionState.READY || connState == ZKBrainConnectionState.CONNECTED)
    val deviceName = connectedDevice?.name ?: "ZKBrain"
    val isNeuroSky = deviceName.contains("MindWave", ignoreCase = true) ||
            deviceName.contains("MW", ignoreCase = true) ||
            deviceName.contains("TGAM", ignoreCase = true) ||
            deviceName.contains("xpain", ignoreCase = true)

    // Android 运行时动态蓝牙权限申请
    val requiredBlePermissions = remember {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            arrayOf(
                Manifest.permission.BLUETOOTH_SCAN,
                Manifest.permission.BLUETOOTH_CONNECT
            )
        } else {
            arrayOf(
                Manifest.permission.ACCESS_FINE_LOCATION,
                Manifest.permission.ACCESS_COARSE_LOCATION
            )
        }
    }

    val blePermissionLauncher = rememberLauncherForActivityResult(
        contract = ActivityResultContracts.RequestMultiplePermissions()
    ) { results ->
        if (results.values.all { it }) {
            ZKBrainManager.startScan(timeoutMillis = 10000L)
            showScanDialog = true
        } else {
            Toast.makeText(context, "未授予蓝牙权限，无法扫描设备", Toast.LENGTH_SHORT).show()
        }
    }

    fun checkAndStartScan() {
        val missing = requiredBlePermissions.filter {
            ContextCompat.checkSelfPermission(context, it) != PackageManager.PERMISSION_GRANTED
        }
        if (missing.isEmpty()) {
            ZKBrainManager.startScan(timeoutMillis = 10000L)
            showScanDialog = true
        } else {
            blePermissionLauncher.launch(missing.toTypedArray())
        }
    }

    fun appendTerminal(msg: String) {
        terminalLogs = (listOf(msg) + terminalLogs).take(50)
    }

    // 状态流监听
    LaunchedEffect(Unit) {
        launch {
            ZKBrainManager.brainData.collectLatest { eeg ->
                brainData = eeg
                if (eeg.batteryCapacity in 1..100) batteryLevel = eeg.batteryCapacity
            }
        }
        launch {
            ZKBrainManager.commandResponse.collectLatest { resp ->
                appendTerminal("[RX <<] $resp")
            }
        }
        launch {
            ZKBrainManager.gravityData.collectLatest { g ->
                memsX = g.x
                memsY = g.y
                memsZ = g.z
            }
        }
        launch {
            ZKBrainManager.quaternionData.collectLatest { q ->
                memsQ0 = q.q0
                memsQ1 = q.q1
                memsQ2 = q.q2
                memsQ3 = q.q3
            }
        }
    }

    LazyColumn(
        modifier = Modifier
            .fillMaxSize()
            .background(Color.White)
            .padding(horizontal = 14.dp),
        contentPadding = PaddingValues(top = 14.dp, bottom = 32.dp),
        verticalArrangement = Arrangement.spacedBy(16.dp)
    ) {
        // ==========================================
        // 板块 1：顶部操作栏 (蓝牙搜索 + DFU 升级 + License Badge)
        // ==========================================
        item {
            Row(
                modifier = Modifier.fillMaxWidth(),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                Button(
                    onClick = { checkAndStartScan() },
                    shape = RoundedCornerShape(6.dp),
                    colors = ButtonDefaults.buttonColors(containerColor = Color(0xFF1E88E5)),
                    contentPadding = PaddingValues(horizontal = 8.dp, vertical = 6.dp),
                    modifier = Modifier.weight(1f)
                ) {
                    Text(
                        text = if (scanState == com.zkteco.zkbrain.bean.ZKBrainScanState.SCANNING) "搜索中..." else "🔍 蓝牙搜索",
                        fontSize = 13.sp,
                        fontWeight = FontWeight.Bold,
                        color = Color.White,
                        maxLines = 1
                    )
                }

                Button(
                    onClick = {
                        Toast.makeText(context, "DFU 固件升级管理器已就绪", Toast.LENGTH_SHORT).show()
                    },
                    shape = RoundedCornerShape(6.dp),
                    colors = ButtonDefaults.buttonColors(containerColor = Color(0xFFE65100)),
                    contentPadding = PaddingValues(horizontal = 8.dp, vertical = 6.dp),
                    modifier = Modifier.weight(1f)
                ) {
                    Text(
                        text = "🚀 DFU 升级",
                        fontSize = 13.sp,
                        fontWeight = FontWeight.Bold,
                        color = Color.White,
                        maxLines = 1
                    )
                }

                Box(
                    modifier = Modifier
                        .clip(RoundedCornerShape(4.dp))
                        .background(Color(0xFFE8F5E9))
                        .padding(horizontal = 8.dp, vertical = 6.dp)
                ) {
                    Text(
                        text = "License: 已授权",
                        fontSize = 11.sp,
                        fontWeight = FontWeight.Bold,
                        color = Color(0xFF2E7D32),
                        maxLines = 1
                    )
                }
            }
        }

        // ==========================================
        // 板块 2：统一当前设备连接状态卡片
        // ==========================================
        item {
            Card(
                modifier = Modifier.fillMaxWidth(),
                shape = RoundedCornerShape(12.dp),
                colors = CardDefaults.cardColors(
                    containerColor = when (connState) {
                        ZKBrainConnectionState.READY -> Color(0xFFF1F8E9)
                        ZKBrainConnectionState.CONNECTING, ZKBrainConnectionState.CONNECTED, ZKBrainConnectionState.DISCOVERING_SERVICES -> Color(0xFFFFF8E1)
                        ZKBrainConnectionState.DISCONNECTED -> Color(0xFFF5F5F5)
                        else -> Color(0xFFFFEBEE)
                    }
                ),
                border = androidx.compose.foundation.BorderStroke(
                    width = 1.dp,
                    color = when (connState) {
                        ZKBrainConnectionState.READY -> Color(0xFFC8E6C9)
                        ZKBrainConnectionState.CONNECTING, ZKBrainConnectionState.CONNECTED, ZKBrainConnectionState.DISCOVERING_SERVICES -> Color(0xFFFFE082)
                        ZKBrainConnectionState.DISCONNECTED -> Color(0xFFE0E0E0)
                        else -> Color(0xFFFFCDD2)
                    }
                )
            ) {
                Column(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(14.dp)
                ) {
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.SpaceBetween
                    ) {
                        Row(
                            verticalAlignment = Alignment.CenterVertically,
                            modifier = Modifier.weight(1f, fill = false)
                        ) {
                            Box(
                                modifier = Modifier
                                    .size(10.dp)
                                    .clip(CircleShape)
                                    .background(
                                        when (connState) {
                                            ZKBrainConnectionState.READY -> Color(0xFF4CAF50)
                                            ZKBrainConnectionState.CONNECTING, ZKBrainConnectionState.CONNECTED, ZKBrainConnectionState.DISCOVERING_SERVICES -> Color(0xFFFF9800)
                                            ZKBrainConnectionState.DISCONNECTED -> Color.Gray
                                            else -> Color(0xFFF44336)
                                        }
                                    )
                            )
                            Spacer(modifier = Modifier.width(8.dp))
                            Text(
                                text = when (connState) {
                                    ZKBrainConnectionState.READY -> "已连接 (就绪)"
                                    ZKBrainConnectionState.CONNECTING -> "正在连接..."
                                    ZKBrainConnectionState.DISCOVERING_SERVICES -> "服务发现中..."
                                    ZKBrainConnectionState.CONNECTED -> "物理已连接"
                                    ZKBrainConnectionState.DISCONNECTED -> "未连接设备"
                                    else -> "连接异常 (${connState.name})"
                                },
                                fontSize = 14.sp,
                                fontWeight = FontWeight.Bold,
                                color = when (connState) {
                                    ZKBrainConnectionState.READY -> Color(0xFF2E7D32)
                                    ZKBrainConnectionState.CONNECTING, ZKBrainConnectionState.CONNECTED, ZKBrainConnectionState.DISCOVERING_SERVICES -> Color(0xFFE65100)
                                    ZKBrainConnectionState.DISCONNECTED -> Color(0xFF616161)
                                    else -> Color(0xFFC62828)
                                },
                                maxLines = 1,
                                overflow = TextOverflow.Ellipsis
                            )
                        }

                        if (isConnected) {
                            Button(
                                onClick = { ZKBrainManager.disconnect() },
                                shape = RoundedCornerShape(6.dp),
                                colors = ButtonDefaults.buttonColors(containerColor = Color(0xFFD32F2F)),
                                contentPadding = PaddingValues(horizontal = 10.dp, vertical = 4.dp),
                                modifier = Modifier.height(30.dp)
                            ) {
                                Text("断开连接", fontSize = 12.sp, color = Color.White)
                            }
                        } else {
                            Button(
                                onClick = { checkAndStartScan() },
                                shape = RoundedCornerShape(6.dp),
                                colors = ButtonDefaults.buttonColors(containerColor = Color(0xFF1E88E5)),
                                contentPadding = PaddingValues(horizontal = 10.dp, vertical = 4.dp),
                                modifier = Modifier.height(30.dp)
                            ) {
                                Text("搜索并连接", fontSize = 12.sp, color = Color.White)
                            }
                        }
                    }

                    Spacer(modifier = Modifier.height(10.dp))

                    if (isConnected && connectedDevice != null) {
                        val dev = connectedDevice!!
                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.SpaceBetween,
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Text(
                                text = dev.name.ifEmpty { "ZKBrain" },
                                fontSize = 16.sp,
                                fontWeight = FontWeight.Bold,
                                color = Color(0xFF212121),
                                maxLines = 1,
                                overflow = TextOverflow.Ellipsis,
                                modifier = Modifier.weight(1f, fill = false)
                            )
                            Spacer(modifier = Modifier.width(8.dp))
                            Box(
                                modifier = Modifier
                                    .clip(RoundedCornerShape(6.dp))
                                    .background(Color(0xFFE8F5E9))
                                    .padding(horizontal = 8.dp, vertical = 4.dp)
                            ) {
                                Text(
                                    text = "🔋 电量: ${if (batteryLevel > 0) "$batteryLevel%" else "--"}",
                                    fontSize = 12.sp,
                                    fontWeight = FontWeight.Bold,
                                    color = Color(0xFF2E7D32)
                                )
                            }
                        }

                        Spacer(modifier = Modifier.height(6.dp))

                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            verticalAlignment = Alignment.CenterVertically,
                            horizontalArrangement = Arrangement.spacedBy(6.dp)
                        ) {
                            Box(
                                modifier = Modifier
                                    .clip(RoundedCornerShape(4.dp))
                                    .background(if (isNeuroSky) Color(0xFFFFF3E0) else Color(0xFFE8F5E9))
                                    .padding(horizontal = 6.dp, vertical = 2.dp)
                            ) {
                                Text(
                                    text = if (isNeuroSky) "NeuroSky (MindWave)" else "ZKBrain 自研设备",
                                    fontSize = 11.sp,
                                    fontWeight = FontWeight.Bold,
                                    color = if (isNeuroSky) Color(0xFFE65100) else Color(0xFF2E7D32)
                                )
                            }

                            Box(
                                modifier = Modifier
                                    .clip(RoundedCornerShape(4.dp))
                                    .background(Color(0xFFEDE7F6))
                                    .padding(horizontal = 6.dp, vertical = 2.dp)
                            ) {
                                Text(
                                    text = "⚡ Raw采样率: 512Hz",
                                    fontSize = 11.sp,
                                    fontWeight = FontWeight.Bold,
                                    color = Color(0xFF512DA8)
                                )
                            }

                            Box(
                                modifier = Modifier
                                    .clip(RoundedCornerShape(4.dp))
                                    .background(Color(0xFFE1F5FE))
                                    .padding(horizontal = 6.dp, vertical = 2.dp)
                            ) {
                                Text(
                                    text = "FW: ${dev.deviceVersion.ifEmpty { "V1.2.1" }}",
                                    fontSize = 11.sp,
                                    fontWeight = FontWeight.Bold,
                                    color = Color(0xFF0288D1)
                                )
                            }
                        }

                        Spacer(modifier = Modifier.height(6.dp))

                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.SpaceBetween,
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Text(
                                text = "MAC: ${dev.address}",
                                fontSize = 11.sp,
                                fontFamily = FontFamily.Monospace,
                                color = Color(0xFF616161)
                            )
                            if (dev.sn.isNotEmpty()) {
                                Text(
                                    text = "SN: ${dev.sn}",
                                    fontSize = 11.sp,
                                    fontFamily = FontFamily.Monospace,
                                    color = Color(0xFF757575)
                                )
                            }
                        }
                    } else {
                        Text(
                            text = "未连接任何脑电设备，请点击“搜索并连接”或右上角“蓝牙搜索”进行配对。",
                            fontSize = 12.sp,
                            color = Color(0xFF757575),
                            lineHeight = 18.sp
                        )
                    }
                }
            }
        }

        // ==========================================
        // 板块 3：Channel Settings (通道配置)
        // ==========================================
        item {
            Column {
                Text(
                    text = "Channel Settings (通道配置)",
                    fontSize = 15.sp,
                    fontWeight = FontWeight.Bold,
                    color = Color.Black
                )
                Spacer(modifier = Modifier.height(6.dp))

                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(16.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Checkbox(checked = isFp1Visible, onCheckedChange = { isFp1Visible = it })
                        Text(text = "Left (FP1)", fontSize = 14.sp, color = Color.Black)
                    }

                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Checkbox(checked = isFp2Visible, onCheckedChange = { }, enabled = false)
                        Text(
                            text = "Right (FP2 - 暂未支持/仅支持单通道FP1)",
                            fontSize = 14.sp,
                            color = Color.Gray
                        )
                    }
                }
            }
        }

        // ==========================================
        // 板块 4：Chart Display Settings (11 个图表显隐 CheckBox 矩阵)
        // ==========================================
        item {
            Column {
                Text(
                    text = "Chart Display Settings (图表显示筛选)",
                    fontSize = 15.sp,
                    fontWeight = FontWeight.Bold,
                    color = Color.Black
                )
                Spacer(modifier = Modifier.height(6.dp))

                val pairs = listOf(
                    "Raw EEG" to "Signal Quality",
                    "Attention" to "Meditation",
                    "Delta" to "Theta",
                    "Low Alpha" to "High Alpha",
                    "Low Beta" to "High Beta",
                    "Low Gamma" to "Middle Gamma"
                )

                pairs.forEach { (first, second) ->
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.spacedBy(16.dp),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Row(modifier = Modifier.weight(1f), verticalAlignment = Alignment.CenterVertically) {
                            Checkbox(
                                checked = chartToggles[first] ?: true,
                                onCheckedChange = { chartToggles[first] = it }
                            )
                            Text(text = first, fontSize = 13.sp, color = Color.Black)
                        }
                        Row(modifier = Modifier.weight(1f), verticalAlignment = Alignment.CenterVertically) {
                            Checkbox(
                                checked = chartToggles[second] ?: true,
                                onCheckedChange = { chartToggles[second] = it }
                            )
                            Text(text = second, fontSize = 13.sp, color = Color.Black)
                        }
                    }
                }
            }
        }

        // ==========================================
        // 板块 5：⚙️ NeuroSky / MindWave 专属 20 字节协议控制台
        // ==========================================
        item {
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .clip(RoundedCornerShape(10.dp))
                    .background(Color(0xFFFFFDF5))
                    .border(1.dp, Color(0xFFFFE082), RoundedCornerShape(10.dp))
                    .padding(14.dp)
            ) {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.SpaceBetween
                ) {
                    Text(
                        text = "⚙️ NeuroSky / MindWave 专属 20 字节协议控制台",
                        fontSize = 14.sp,
                        fontWeight = FontWeight.Bold,
                        color = Color(0xFFE65100),
                        modifier = Modifier.weight(1f, fill = false)
                    )
                    Text(
                        text = "经典 20B XMW 协议",
                        fontSize = 11.sp,
                        fontWeight = FontWeight.Medium,
                        color = Color(0xFFE65100),
                        modifier = Modifier
                            .clip(RoundedCornerShape(4.dp))
                            .background(Color(0xFFFFECB3))
                            .padding(horizontal = 6.dp, vertical = 2.dp)
                    )
                }

                Spacer(modifier = Modifier.height(10.dp))

                // 1. 点火与停止
                Text("1. 数据流启停控制 (Raw & 8 频段功率)", fontSize = 12.sp, fontWeight = FontWeight.SemiBold, color = Color(0xFF424242))
                Spacer(modifier = Modifier.height(4.dp))
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(6.dp)
                ) {
                    Button(
                        onClick = {
                            connectedDevice?.let { dev ->
                                ZKBrainManager.writeCommand(dev.address, byteArrayOf(0x02, 0x15))
                                appendTerminal("[TX >>] 开启 Raw 流 (0x15)")
                            }
                        },
                        modifier = Modifier.weight(1f),
                        shape = RoundedCornerShape(6.dp),
                        contentPadding = PaddingValues(horizontal = 2.dp, vertical = 4.dp),
                        colors = ButtonDefaults.buttonColors(containerColor = Color(0xFF2E7D32))
                    ) {
                        Text("开启Raw(0x15)", fontSize = 10.sp, color = Color.White)
                    }

                    Button(
                        onClick = {
                            connectedDevice?.let { dev ->
                                ZKBrainManager.writeCommand(dev.address, byteArrayOf(0x02, 0x16))
                                appendTerminal("[TX >>] 停止 Raw 流 (0x16)")
                            }
                        },
                        modifier = Modifier.weight(1f),
                        shape = RoundedCornerShape(6.dp),
                        contentPadding = PaddingValues(horizontal = 2.dp, vertical = 4.dp),
                        colors = ButtonDefaults.buttonColors(containerColor = Color(0xFFC62828))
                    ) {
                        Text("停止Raw(0x16)", fontSize = 10.sp, color = Color.White)
                    }

                    Button(
                        onClick = {
                            connectedDevice?.let { dev ->
                                ZKBrainManager.writeCommand(dev.address, byteArrayOf(0x02, 0x17))
                                appendTerminal("[TX >>] 开启 8频段 (0x17)")
                            }
                        },
                        modifier = Modifier.weight(1f),
                        shape = RoundedCornerShape(6.dp),
                        contentPadding = PaddingValues(horizontal = 2.dp, vertical = 4.dp),
                        colors = ButtonDefaults.buttonColors(containerColor = Color(0xFF1565C0))
                    ) {
                        Text("开启8频段(0x17)", fontSize = 10.sp, color = Color.White)
                    }

                    Button(
                        onClick = {
                            connectedDevice?.let { dev ->
                                ZKBrainManager.writeCommand(dev.address, byteArrayOf(0x02, 0x18))
                                appendTerminal("[TX >>] 停止 8频段 (0x18)")
                            }
                        },
                        modifier = Modifier.weight(1f),
                        shape = RoundedCornerShape(6.dp),
                        contentPadding = PaddingValues(horizontal = 2.dp, vertical = 4.dp),
                        colors = ButtonDefaults.buttonColors(containerColor = Color(0xFF6A1B9A))
                    ) {
                        Text("停止8频段(0x18)", fontSize = 10.sp, color = Color.White)
                    }
                }

                Spacer(modifier = Modifier.height(10.dp))

                // 2. 滤波
                Text("2. 50Hz/60Hz 工频陷波滤波配置", fontSize = 12.sp, fontWeight = FontWeight.SemiBold, color = Color(0xFF424242))
                Spacer(modifier = Modifier.height(4.dp))
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    Button(
                        onClick = {
                            connectedDevice?.let { dev ->
                                ZKBrainManager.writeCommand(dev.address, byteArrayOf(0x02, 0x1B))
                                appendTerminal("[TX >>] 设置 50Hz 陷波 (0x1B)")
                            }
                        },
                        modifier = Modifier.weight(1f),
                        shape = RoundedCornerShape(6.dp),
                        colors = ButtonDefaults.buttonColors(containerColor = Color(0xFF00695C))
                    ) {
                        Text("50Hz 陷波 (0x1B)", fontSize = 12.sp, color = Color.White)
                    }

                    Button(
                        onClick = {
                            connectedDevice?.let { dev ->
                                ZKBrainManager.writeCommand(dev.address, byteArrayOf(0x02, 0x1C))
                                appendTerminal("[TX >>] 设置 60Hz 陷波 (0x1C)")
                            }
                        },
                        modifier = Modifier.weight(1f),
                        shape = RoundedCornerShape(6.dp),
                        colors = ButtonDefaults.buttonColors(containerColor = Color(0xFF0277BD))
                    ) {
                        Text("60Hz 陷波 (0x1C)", fontSize = 12.sp, color = Color.White)
                    }
                }

                Spacer(modifier = Modifier.height(10.dp))

                // 3. 硬件信息
                Text("3. 硬件静态信息读取", fontSize = 12.sp, fontWeight = FontWeight.SemiBold, color = Color(0xFF424242))
                Spacer(modifier = Modifier.height(4.dp))
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    Button(
                        onClick = {
                            connectedDevice?.let { dev ->
                                ZKBrainManager.writeCommand(dev.address, byteArrayOf(0x02, 0x06))
                                appendTerminal("[TX >>] 读电量 (0x06)")
                            }
                        },
                        modifier = Modifier.weight(1f),
                        shape = RoundedCornerShape(6.dp),
                        colors = ButtonDefaults.buttonColors(containerColor = Color(0xFF4527A0))
                    ) {
                        Text("读电量 (0x06)", fontSize = 12.sp, color = Color.White)
                    }

                    Button(
                        onClick = {
                            connectedDevice?.let { dev ->
                                ZKBrainManager.writeCommand(dev.address, byteArrayOf(0x02, 0xF4.toByte()))
                                appendTerminal("[TX >>] 读硬件 SN (0xF4)")
                            }
                        },
                        modifier = Modifier.weight(1f),
                        shape = RoundedCornerShape(6.dp),
                        colors = ButtonDefaults.buttonColors(containerColor = Color(0xFFAD1457))
                    ) {
                        Text("读硬件 SN (0xF4)", fontSize = 12.sp, color = Color.White)
                    }
                }

                Spacer(modifier = Modifier.height(10.dp))

                // 4. 探测经典 MAC
                Text("4. 探测经典蓝牙 MAC 地址 (0xFC)", fontSize = 12.sp, fontWeight = FontWeight.SemiBold, color = Color(0xFF424242))
                Spacer(modifier = Modifier.height(4.dp))
                Button(
                    onClick = {
                        connectedDevice?.let { dev ->
                            ZKBrainManager.writeCommand(dev.address, byteArrayOf(0x02, 0xFC.toByte()))
                            appendTerminal("[TX >>] 探测经典 MAC (0xFC)")
                        }
                    },
                    modifier = Modifier.fillMaxWidth(),
                    shape = RoundedCornerShape(6.dp),
                    colors = ButtonDefaults.buttonColors(containerColor = Color(0xFF37474F))
                ) {
                    Text("探测经典 MAC (0xFC)", fontSize = 12.sp, color = Color.White)
                }

                Spacer(modifier = Modifier.height(10.dp))

                // 5. 写入 SN (0xF2)
                Text("5. 写入设备 SN (OpCode 0xF2, 最多 16 字节 ASCII)", fontSize = 12.sp, fontWeight = FontWeight.SemiBold, color = Color(0xFF424242))
                Spacer(modifier = Modifier.height(4.dp))
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    OutlinedTextField(
                        value = writeSnInput,
                        onValueChange = { if (it.length <= 16) writeSnInput = it },
                        modifier = Modifier.weight(1f),
                        placeholder = { Text("输入 SN (如 MW_001)", fontSize = 12.sp) },
                        singleLine = true
                    )
                    Button(
                        onClick = {
                            if (writeSnInput.isNotBlank()) {
                                connectedDevice?.let { dev ->
                                    val snBytes = writeSnInput.trim().toByteArray().take(16).toByteArray()
                                    val packet = byteArrayOf(0x02, 0xF2.toByte()) + snBytes
                                    ZKBrainManager.writeCommand(dev.address, packet)
                                    appendTerminal("[TX >>] 写入 SN (0xF2): $writeSnInput")
                                }
                            }
                        },
                        shape = RoundedCornerShape(6.dp),
                        enabled = writeSnInput.isNotBlank(),
                        colors = ButtonDefaults.buttonColors(containerColor = Color(0xFF4E342E))
                    ) {
                        Text("写入 (0xF2)", fontSize = 12.sp, color = Color.White)
                    }
                }
            }
        }

        // ==========================================
        // 板块 6：🧠 ZKBrain 自研脑电设备官方控制台
        // ==========================================
        item {
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .clip(RoundedCornerShape(10.dp))
                    .background(Color(0xFFF5F9FF))
                    .border(1.dp, if (!isNeuroSky) Color(0xFF42A5F5) else Color(0xFFD0E1FD), RoundedCornerShape(10.dp))
                    .padding(14.dp)
            ) {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.SpaceBetween
                ) {
                    Text(
                        text = "🧠 ZKBrain 自研脑电设备官方控制台",
                        fontSize = 15.sp,
                        fontWeight = FontWeight.Bold,
                        color = Color(0xFF0D47A1)
                    )
                    Text(
                        text = if (!isNeuroSky) "🌟 当前适配 (官方 ASCII)" else "自研设备专属 (ASCII)",
                        fontSize = 11.sp,
                        fontWeight = FontWeight.Medium,
                        color = if (!isNeuroSky) Color(0xFF1565C0) else Color(0xFF757575),
                        modifier = Modifier
                            .clip(RoundedCornerShape(4.dp))
                            .background(if (!isNeuroSky) Color(0xFFE3F2FD) else Color(0xFFEEEEEE))
                            .padding(horizontal = 6.dp, vertical = 2.dp)
                    )
                }

                Spacer(modifier = Modifier.height(10.dp))

                Row(
                    modifier = Modifier.fillMaxWidth(),
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.SpaceBetween
                ) {
                    Text(
                        text = "License: 正式授权 (永久有效)",
                        fontSize = 12.sp,
                        color = Color(0xFF333333)
                    )
                    Button(
                        onClick = {
                            ZKBrainManager.sendConfigCommand(mapOf("zk_check_license" to ""))
                            appendTerminal("[TX >>] 查询授权 (zk_check_license)")
                        },
                        shape = RoundedCornerShape(6.dp),
                        contentPadding = PaddingValues(horizontal = 10.dp, vertical = 4.dp)
                    ) {
                        Text("查询授权", fontSize = 12.sp)
                    }
                }

                Spacer(modifier = Modifier.height(6.dp))

                Row(
                    modifier = Modifier.fillMaxWidth(),
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.SpaceBetween
                ) {
                    Text(
                        text = "设备电量: ${if (batteryLevel > 0) "$batteryLevel%" else "--"} (正常供电)",
                        fontSize = 12.sp,
                        color = Color(0xFF333333)
                    )
                    Button(
                        onClick = {
                            ZKBrainManager.sendConfigCommand(mapOf("battery" to "?"))
                            appendTerminal("[TX >>] battery:?")
                        },
                        shape = RoundedCornerShape(6.dp),
                        contentPadding = PaddingValues(horizontal = 10.dp, vertical = 4.dp)
                    ) {
                        Text("读取电量", fontSize = 12.sp)
                    }
                }

                Spacer(modifier = Modifier.height(6.dp))

                Row(
                    modifier = Modifier.fillMaxWidth(),
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.SpaceBetween
                ) {
                    Text(
                        text = "固件版本: ${connectedDevice?.deviceVersion?.ifEmpty { "V1.2.1" } ?: "V1.2.1"} (已适配)",
                        fontSize = 12.sp,
                        color = Color(0xFF333333)
                    )
                    Button(
                        onClick = {
                            ZKBrainManager.sendConfigCommand(mapOf("version" to "?"))
                            appendTerminal("[TX >>] version:?")
                        },
                        shape = RoundedCornerShape(6.dp),
                        contentPadding = PaddingValues(horizontal = 10.dp, vertical = 4.dp)
                    ) {
                        Text("读取版本", fontSize = 12.sp)
                    }
                }

                Spacer(modifier = Modifier.height(10.dp))

                Text(
                    text = "脑电数据开关 (eeg_data_on)",
                    fontSize = 12.sp,
                    fontWeight = FontWeight.Bold,
                    color = Color(0xFF555555)
                )
                Spacer(modifier = Modifier.height(4.dp))
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(6.dp)
                ) {
                    Button(
                        onClick = {
                            ZKBrainManager.sendConfigCommand(mapOf("eeg_data_on" to "1"))
                            appendTerminal("[TX >>] eeg_data_on:1")
                        },
                        modifier = Modifier.weight(1f),
                        shape = RoundedCornerShape(6.dp)
                    ) {
                        Text("开 (:1)", fontSize = 12.sp)
                    }
                    Button(
                        onClick = {
                            ZKBrainManager.sendConfigCommand(mapOf("eeg_data_on" to "0"))
                            appendTerminal("[TX >>] eeg_data_on:0")
                        },
                        modifier = Modifier.weight(1f),
                        shape = RoundedCornerShape(6.dp)
                    ) {
                        Text("关 (:0)", fontSize = 12.sp)
                    }
                    Button(
                        onClick = {
                            ZKBrainManager.sendConfigCommand(mapOf("eeg_data_on" to "?"))
                            appendTerminal("[TX >>] eeg_data_on:?")
                        },
                        modifier = Modifier.weight(1f),
                        shape = RoundedCornerShape(6.dp)
                    ) {
                        Text("查询 (:?)", fontSize = 12.sp)
                    }
                }

                Spacer(modifier = Modifier.height(10.dp))

                Text(
                    text = "脑电采样率 (eeg_data_rate)",
                    fontSize = 12.sp,
                    fontWeight = FontWeight.Bold,
                    color = Color(0xFF555555)
                )
                Spacer(modifier = Modifier.height(4.dp))
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(4.dp)
                ) {
                    Button(
                        onClick = {
                            ZKBrainManager.sendConfigCommand(mapOf("eeg_data_rate" to "128"))
                            appendTerminal("[TX >>] eeg_data_rate:128")
                        },
                        modifier = Modifier.weight(1f),
                        shape = RoundedCornerShape(4.dp),
                        contentPadding = PaddingValues(horizontal = 2.dp, vertical = 4.dp)
                    ) {
                        Text("128H", fontSize = 11.sp)
                    }
                    Button(
                        onClick = {
                            ZKBrainManager.sendConfigCommand(mapOf("eeg_data_rate" to "256"))
                            appendTerminal("[TX >>] eeg_data_rate:256")
                        },
                        modifier = Modifier.weight(1f),
                        shape = RoundedCornerShape(4.dp),
                        contentPadding = PaddingValues(horizontal = 2.dp, vertical = 4.dp)
                    ) {
                        Text("256H", fontSize = 11.sp)
                    }
                    Button(
                        onClick = {
                            ZKBrainManager.sendConfigCommand(mapOf("eeg_data_rate" to "512"))
                            appendTerminal("[TX >>] eeg_data_rate:512")
                        },
                        modifier = Modifier.weight(1f),
                        shape = RoundedCornerShape(4.dp),
                        contentPadding = PaddingValues(horizontal = 2.dp, vertical = 4.dp)
                    ) {
                        Text("512H", fontSize = 11.sp)
                    }
                    Button(
                        onClick = {
                            ZKBrainManager.sendConfigCommand(mapOf("eeg_data_rate" to "?"))
                            appendTerminal("[TX >>] eeg_data_rate:?")
                        },
                        modifier = Modifier.weight(1f),
                        shape = RoundedCornerShape(4.dp),
                        contentPadding = PaddingValues(horizontal = 2.dp, vertical = 4.dp)
                    ) {
                        Text("查询", fontSize = 11.sp)
                    }
                }

                Spacer(modifier = Modifier.height(10.dp))

                Text(
                    text = "惯导/MEMS 姿态传感控制 (mems_on)",
                    fontSize = 12.sp,
                    fontWeight = FontWeight.Bold,
                    color = Color(0xFF555555)
                )
                Spacer(modifier = Modifier.height(4.dp))
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(6.dp)
                ) {
                    Button(
                        onClick = {
                            ZKBrainManager.sendConfigCommand(mapOf("mems_on" to "1"))
                            appendTerminal("[TX >>] mems_on:1")
                        },
                        modifier = Modifier.weight(1f),
                        shape = RoundedCornerShape(6.dp)
                    ) {
                        Text("开 (:1)", fontSize = 12.sp)
                    }
                    Button(
                        onClick = {
                            ZKBrainManager.sendConfigCommand(mapOf("mems_on" to "0"))
                            appendTerminal("[TX >>] mems_on:0")
                        },
                        modifier = Modifier.weight(1f),
                        shape = RoundedCornerShape(6.dp)
                    ) {
                        Text("关 (:0)", fontSize = 12.sp)
                    }
                    Button(
                        onClick = {
                            ZKBrainManager.sendConfigCommand(mapOf("mems_on" to "?"))
                            appendTerminal("[TX >>] mems_on:?")
                        },
                        modifier = Modifier.weight(1f),
                        shape = RoundedCornerShape(6.dp)
                    ) {
                        Text("查询 (:?)", fontSize = 12.sp)
                    }
                }

                Spacer(modifier = Modifier.height(8.dp))

                // 实时欧拉角展示
                Column(
                    modifier = Modifier
                        .fillMaxWidth()
                        .clip(RoundedCornerShape(6.dp))
                        .background(Color(0xFFE8EEF5))
                        .padding(8.dp)
                ) {
                    Text(
                        text = "MEMS 空间姿态角 (mems_type:1 / Euler Angles):",
                        fontSize = 11.sp,
                        fontWeight = FontWeight.Bold,
                        color = Color(0xFF1565C0)
                    )
                    Spacer(modifier = Modifier.height(4.dp))
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween
                    ) {
                        Text("Pitch(俯仰): ${round(memsX * 10) / 10f}°", fontSize = 11.sp, fontFamily = FontFamily.Monospace, color = Color(0xFF0D47A1))
                        Text("Roll(翻滚): ${round(memsY * 10) / 10f}°", fontSize = 11.sp, fontFamily = FontFamily.Monospace, color = Color(0xFF0D47A1))
                        Text("Yaw(偏航): ${round(memsZ * 10) / 10f}°", fontSize = 11.sp, fontFamily = FontFamily.Monospace, color = Color(0xFF0D47A1))
                    }
                    Spacer(modifier = Modifier.height(4.dp))
                    Text(
                        text = "MEMS 旋转四元数 (mems_type:0 / Quaternions):",
                        fontSize = 11.sp,
                        fontWeight = FontWeight.Bold,
                        color = Color(0xFF2E7D32)
                    )
                    Spacer(modifier = Modifier.height(2.dp))
                    Text(
                        text = "q0: ${round(memsQ0 * 100) / 100f}, q1: ${round(memsQ1 * 100) / 100f}, q2: ${round(memsQ2 * 100) / 100f}, q3: ${round(memsQ3 * 100) / 100f}",
                        fontSize = 11.sp,
                        fontFamily = FontFamily.Monospace,
                        color = Color(0xFF1B5E20)
                    )
                }

                Spacer(modifier = Modifier.height(10.dp))

                Text(
                    text = "下发自定义键值对指令",
                    fontSize = 12.sp,
                    fontWeight = FontWeight.Bold,
                    color = Color(0xFF555555)
                )
                Spacer(modifier = Modifier.height(4.dp))
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(6.dp)
                ) {
                    OutlinedTextField(
                        value = customCmdInput,
                        onValueChange = { customCmdInput = it },
                        placeholder = { Text("输入指令如 mems_type:0 或 sn:?", fontSize = 12.sp) },
                        modifier = Modifier.weight(1f),
                        singleLine = true,
                        textStyle = androidx.compose.ui.text.TextStyle(fontSize = 12.sp)
                    )

                    Button(
                        onClick = {
                            val trimmed = customCmdInput.trim()
                            if (trimmed.isNotBlank()) {
                                if (trimmed.contains(":")) {
                                    val parts = trimmed.split(":", limit = 2)
                                    ZKBrainManager.sendConfigCommand(mapOf(parts[0].trim() to parts[1].trim()))
                                } else {
                                    connectedDevice?.let { dev ->
                                        ZKBrainManager.writeCommand(dev.address, "$trimmed\n".toByteArray())
                                    }
                                }
                                appendTerminal("[TX >>] $trimmed")
                                customCmdInput = ""
                            }
                        },
                        shape = RoundedCornerShape(6.dp),
                        contentPadding = PaddingValues(horizontal = 10.dp, vertical = 6.dp)
                    ) {
                        Text("发送指令", fontSize = 12.sp)
                    }
                }

                Spacer(modifier = Modifier.height(10.dp))

                Row(
                    modifier = Modifier.fillMaxWidth(),
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.SpaceBetween
                ) {
                    Text(
                        text = "📥 硬件回包监控 (commandResponse)",
                        fontSize = 12.sp,
                        fontWeight = FontWeight.Bold,
                        color = Color(0xFF2E7D32)
                    )
                    OutlinedButton(
                        onClick = { terminalLogs = emptyList() },
                        shape = RoundedCornerShape(4.dp),
                        contentPadding = PaddingValues(horizontal = 8.dp, vertical = 2.dp)
                    ) {
                        Text("清空", fontSize = 11.sp)
                    }
                }

                Spacer(modifier = Modifier.height(4.dp))

                Box(
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(110.dp)
                        .clip(RoundedCornerShape(6.dp))
                        .background(Color(0xFF1E1E1E))
                        .padding(8.dp)
                ) {
                    LazyColumn(modifier = Modifier.fillMaxSize()) {
                        items(terminalLogs) { log ->
                            Text(
                                text = log,
                                fontSize = 11.sp,
                                fontFamily = FontFamily.Monospace,
                                color = Color(0xFF00E676)
                            )
                        }
                    }
                }

                Spacer(modifier = Modifier.height(10.dp))

                Row(
                    modifier = Modifier.fillMaxWidth(),
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    Button(
                        onClick = {
                            ZKBrainManager.sendConfigCommand(mapOf("zk_dfu_scan" to ""))
                            dfuStatus = "DFU: 正在扫描 DFU 升级广播..."
                            appendTerminal("[TX >>] zk_dfu_scan")
                        },
                        shape = RoundedCornerShape(6.dp),
                        contentPadding = PaddingValues(horizontal = 10.dp, vertical = 4.dp)
                    ) {
                        Text("扫描 DFU 设备", fontSize = 11.sp)
                    }

                    Text(
                        text = dfuStatus,
                        fontSize = 11.sp,
                        color = Color(0xFF333333),
                        modifier = Modifier.weight(1f)
                    )
                }
            }
        }

        // ==========================================
        // 板块 7：Spectrum Data 详细表格 (DeviceShowTable)
        // ==========================================
        item {
            Column {
                Text(
                    text = "Spectrum Data",
                    fontSize = 15.sp,
                    fontWeight = FontWeight.Bold,
                    color = Color.Black
                )
                Spacer(modifier = Modifier.height(6.dp))

                DeviceShowTable(
                    macAddress = if (connectedDevice != null) "MAC: ${connectedDevice!!.address}" else "MAC: 未连接",
                    data = brainData
                )
            }
        }
    }

    // ==========================================
    // 蓝牙搜索选择弹窗 (BleScanDialog)
    // ==========================================
    if (showScanDialog) {
        Dialog(
            onDismissRequest = {
                ZKBrainManager.stopScan()
                showScanDialog = false
            },
            properties = DialogProperties(usePlatformDefaultWidth = false)
        ) {
            Card(
                modifier = Modifier
                    .fillMaxWidth(0.92f)
                    .fillMaxHeight(0.72f),
                shape = RoundedCornerShape(16.dp),
                colors = CardDefaults.cardColors(containerColor = Color.White)
            ) {
                Column(
                    modifier = Modifier
                        .fillMaxSize()
                        .padding(16.dp)
                ) {
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Column {
                            Text(
                                text = "🔍 搜索周围脑电设备",
                                fontSize = 17.sp,
                                fontWeight = FontWeight.Bold,
                                color = Color(0xFF1E293B)
                            )
                            Text(
                                text = "点击列表条目即可一键连接",
                                fontSize = 12.sp,
                                color = Color(0xFF64748B)
                            )
                        }
                        Button(
                            onClick = { ZKBrainManager.startScan(10000L) },
                            shape = RoundedCornerShape(8.dp),
                            contentPadding = PaddingValues(horizontal = 10.dp, vertical = 6.dp)
                        ) {
                            Text("🔄 刷新", fontSize = 12.sp)
                        }
                    }

                    Spacer(modifier = Modifier.height(12.dp))

                    if (scannedDevices.isEmpty()) {
                        Box(
                            modifier = Modifier
                                .weight(1f)
                                .fillMaxWidth(),
                            contentAlignment = Alignment.Center
                        ) {
                            Column(horizontalAlignment = Alignment.CenterHorizontally) {
                                CircularProgressIndicator(color = Color(0xFF3B82F6), modifier = Modifier.size(36.dp))
                                Spacer(modifier = Modifier.height(10.dp))
                                Text("正在扫描广播中的脑机硬件...", color = Color(0xFF64748B), fontSize = 13.sp)
                            }
                        }
                    } else {
                        LazyColumn(
                            modifier = Modifier
                                .weight(1f)
                                .fillMaxWidth(),
                            verticalArrangement = Arrangement.spacedBy(8.dp)
                        ) {
                            items(scannedDevices) { dev ->
                                Row(
                                    modifier = Modifier
                                        .fillMaxWidth()
                                        .clip(RoundedCornerShape(8.dp))
                                        .background(Color(0xFFF8FAFC))
                                        .border(1.dp, Color(0xFFE2E8F0), RoundedCornerShape(8.dp))
                                        .clickable {
                                            ZKBrainManager.stopScan()
                                            ZKBrainManager.connect(dev)
                                            showScanDialog = false
                                        }
                                        .padding(12.dp),
                                    verticalAlignment = Alignment.CenterVertically,
                                    horizontalArrangement = Arrangement.SpaceBetween
                                ) {
                                    Column(modifier = Modifier.weight(1f)) {
                                        Text(
                                            text = dev.name.ifEmpty { "未知脑电设备" },
                                            fontSize = 14.sp,
                                            fontWeight = FontWeight.Bold,
                                            color = Color(0xFF0F172A)
                                        )
                                        Spacer(modifier = Modifier.height(2.dp))
                                        Text(
                                            text = "MAC: ${dev.address} | RSSI: ${dev.rssi} dBm",
                                            fontSize = 11.sp,
                                            fontFamily = FontFamily.Monospace,
                                            color = Color(0xFF64748B)
                                        )
                                    }
                                    Button(
                                        onClick = {
                                            ZKBrainManager.stopScan()
                                            ZKBrainManager.connect(dev)
                                            showScanDialog = false
                                        },
                                        shape = RoundedCornerShape(6.dp),
                                        contentPadding = PaddingValues(horizontal = 12.dp, vertical = 4.dp),
                                        colors = ButtonDefaults.buttonColors(containerColor = Color(0xFF1E88E5))
                                    ) {
                                        Text("连接", fontSize = 12.sp, color = Color.White)
                                    }
                                }
                            }
                        }
                    }

                    Spacer(modifier = Modifier.height(12.dp))

                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.End
                    ) {
                        OutlinedButton(
                            onClick = {
                                ZKBrainManager.stopScan()
                                showScanDialog = false
                            },
                            shape = RoundedCornerShape(8.dp)
                        ) {
                            Text("关闭")
                        }
                    }
                }
            }
        }
    }
}

/**
 * 🌟 1:1 还原 shared1 device_show_item.xml 的 4x3 三色指标表格
 */
@Composable
fun DeviceShowTable(
    macAddress: String,
    data: MultiBrainEeg?,
    modifier: Modifier = Modifier
) {
    val bgPink = Color(0xFFFFE4E1)    // #FFE4E1 (粉)
    val bgCyan = Color(0xFFE0FFFF)    // #E0FFFF (青)
    val bgYellow = Color(0xFFF0E68C)  // #F0E68C (黄)

    val waves = data?.brainWaves

    Column(
        modifier = modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(8.dp))
            .background(Color.White)
            .padding(8.dp)
    ) {
        // 顶部 MAC 地址居中
        Text(
            text = macAddress,
            fontSize = 16.sp,
            fontWeight = FontWeight.Bold,
            color = Color.Black,
            modifier = Modifier
                .fillMaxWidth()
                .padding(vertical = 6.dp),
            textAlign = TextAlign.Center
        )

        // 3列表格行 1: Signal | Attention | Meditation
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.spacedBy(4.dp)
        ) {
            TableCell(title = "Signal (SQ)", value = "${data?.signal ?: 200}", bgColor = bgPink, modifier = Modifier.weight(1f))
            TableCell(title = "Attention", value = "${data?.attentionLevel ?: 0}", bgColor = bgCyan, modifier = Modifier.weight(1f))
            TableCell(title = "Meditation", value = "${data?.meditationDepth ?: 0}", bgColor = bgYellow, modifier = Modifier.weight(1f))
        }

        Spacer(modifier = Modifier.height(6.dp))

        // 3列表格行 2: Delta | Theta | Low Alpha
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.spacedBy(4.dp)
        ) {
            TableCell(title = "Delta (δ)", value = "${waves?.delta ?: 0}", bgColor = bgPink, modifier = Modifier.weight(1f))
            TableCell(title = "Theta (θ)", value = "${waves?.theta ?: 0}", bgColor = bgCyan, modifier = Modifier.weight(1f))
            TableCell(title = "Low Alpha (α1)", value = "${waves?.lowAlpha ?: 0}", bgColor = bgYellow, modifier = Modifier.weight(1f))
        }

        Spacer(modifier = Modifier.height(6.dp))

        // 3列表格行 3: Low Beta | High Beta | Low Gamma
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.spacedBy(4.dp)
        ) {
            TableCell(title = "Low Beta (β1)", value = "${waves?.lowBeta ?: 0}", bgColor = bgPink, modifier = Modifier.weight(1f))
            TableCell(title = "High Beta (β2)", value = "${waves?.highBeta ?: 0}", bgColor = bgCyan, modifier = Modifier.weight(1f))
            TableCell(title = "Low Gamma (γ1)", value = "${waves?.lowGamma ?: 0}", bgColor = bgYellow, modifier = Modifier.weight(1f))
        }

        Spacer(modifier = Modifier.height(6.dp))

        // 3列表格行 4: Mid Gamma | Battery | Raw 采样率 (4x3 完美对称布局)
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.spacedBy(4.dp)
        ) {
            TableCell(title = "Mid Gamma (γ2)", value = "${waves?.middleGamma ?: 0}", bgColor = bgPink, modifier = Modifier.weight(1f))
            TableCell(title = "Battery", value = "${data?.batteryCapacity ?: 0}%", bgColor = bgCyan, modifier = Modifier.weight(1f))
            TableCell(title = "Raw 采样率", value = "512 Hz", bgColor = bgYellow, modifier = Modifier.weight(1f))
        }
    }
}

@Composable
private fun TableCell(
    title: String,
    value: String,
    bgColor: Color,
    modifier: Modifier = Modifier
) {
    Column(
        modifier = modifier
            .clip(RoundedCornerShape(4.dp))
            .background(bgColor)
            .padding(horizontal = 6.dp, vertical = 6.dp),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Text(
            text = title,
            fontSize = 11.sp,
            fontWeight = FontWeight.SemiBold,
            color = Color(0xFF333333),
            maxLines = 1,
            overflow = TextOverflow.Ellipsis
        )
        Spacer(modifier = Modifier.height(2.dp))
        Text(
            text = value,
            fontSize = 13.sp,
            fontWeight = FontWeight.Bold,
            color = Color.Black,
            maxLines = 1,
            overflow = TextOverflow.Ellipsis
        )
    }
}
