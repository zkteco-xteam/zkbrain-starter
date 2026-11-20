package com.zkteco.zkbrain.nativeapp

import android.Manifest
import android.content.pm.PackageManager
import android.os.Build
import android.os.Bundle
import android.widget.*
import androidx.activity.result.contract.ActivityResultContracts
import androidx.appcompat.app.AppCompatActivity
import androidx.core.content.ContextCompat
import androidx.lifecycle.lifecycleScope
import com.zkteco.zkbrain.ZKBrainManager
import com.zkteco.zkbrain.bean.MultiBrainEeg
import com.zkteco.zkbrain.bean.ZKBrainConnectionState
import kotlinx.coroutines.flow.collectLatest
import kotlinx.coroutines.launch

/**
 * 🌟 纯原生 Android 开发者极速样板 (纯 Kotlin + LifecycleScope)
 * 包含：动态蓝牙权限申请、8 频段频谱、专注/放松度、512Hz 原始波与 MEMS/硬件指令下发
 * 技术支持：熵基科技脑机事业部 (ZKTeco Brain-Computer Interface Division)
 */
class MainActivity : AppCompatActivity() {

    // 🌟 运行时动态蓝牙权限申请器 (兼容 Android 12+ 及 Android 6~11)
    private val blePermissionLauncher = registerForActivityResult(
        ActivityResultContracts.RequestMultiplePermissions()
    ) { results ->
        val allGranted = results.values.all { it }
        if (allGranted) {
            Toast.makeText(this, "Bluetooth permissions granted, scanning for BCI devices...", Toast.LENGTH_SHORT).show()
            ZKBrainManager.startScan(timeoutMillis = 10000L)
        } else {
            Toast.makeText(this, "Bluetooth permission denied. Please enable in App Settings.", Toast.LENGTH_LONG).show()
        }
    }

    private fun getRequiredBlePermissions(): Array<String> {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
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

    private fun checkAndRequestBlePermissionsThenScan() {
        val perms = getRequiredBlePermissions()
        val missing = perms.filter {
            ContextCompat.checkSelfPermission(this, it) != PackageManager.PERMISSION_GRANTED
        }
        if (missing.isEmpty()) {
            Toast.makeText(this, "Scanning for nearby BCI devices...", Toast.LENGTH_SHORT).show()
            ZKBrainManager.startScan(timeoutMillis = 10000L)
        } else {
            blePermissionLauncher.launch(missing.toTypedArray())
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        val scrollView = ScrollView(this)
        val layout = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(32, 32, 32, 32)
        }
        scrollView.addView(layout)

        // 1. 状态与连接卡片
        val tvStatus = TextView(this).apply {
            text = "链路状态: 未连接"
            textSize = 17f
        }
        val btnScan = Button(this).apply {
            text = "⚡ 扫描并连接脑电设备"
        }

        // 2. 专注与放松核心指标
        val tvAttention = TextView(this).apply { text = "实时专注度 (Attention): 0 / 100" }
        val pbAttention = ProgressBar(this, null, android.R.attr.progressBarStyleHorizontal).apply { max = 100 }
        val tvMeditation = TextView(this).apply { text = "实时放松度 (Meditation): 0 / 100" }
        val pbMeditation = ProgressBar(this, null, android.R.attr.progressBarStyleHorizontal).apply { max = 100 }

        // 3. 脑波 8 频段绝对功率
        val tvBandsTitle = TextView(this).apply {
            text = "\n📊 脑波 8 频段能量分布 (EEG Power Spectrum):"
            textSize = 15f
        }
        val tvBands = TextView(this).apply {
            text = "Delta: 0 | Theta: 0 | LowAlpha: 0 | HighAlpha: 0\nLowBeta: 0 | HighBeta: 0 | LowGamma: 0 | MidGamma: 0"
            textSize = 13f
        }

        // 4. 🌟 MEMS 传感器与硬件指令交互区 (命令发送模板)
        val tvCmdTitle = TextView(this).apply {
            text = "\n🛠️ MEMS 传感器与硬件指令交互控制台:"
            textSize = 15f
        }
        val btnMemsStream = Button(this).apply {
            text = "📡 开启 MEMS 惯导/姿态流 (mems_on:1)"
        }
        val btnIgnite = Button(this).apply {
            text = "🔥 下发点火指令 (0x15 Raw + 0x17 Band)"
        }
        val etCustomCmd = EditText(this).apply {
            hint = "输入自定义键值对或 ASCII 指令 (如 eeg_data_rate:512)"
        }
        val btnSendCustom = Button(this).apply {
            text = "📤 发送自定义指令"
        }
        val tvCmdLog = TextView(this).apply {
            text = "指令回包监控: 暂无数据"
            textSize = 12f
        }

        // 组装视图
        layout.addView(tvStatus)
        layout.addView(btnScan)
        layout.addView(tvAttention)
        layout.addView(pbAttention)
        layout.addView(tvMeditation)
        layout.addView(pbMeditation)
        layout.addView(tvBandsTitle)
        layout.addView(tvBands)
        layout.addView(tvCmdTitle)
        layout.addView(btnMemsStream)
        layout.addView(btnIgnite)
        layout.addView(etCustomCmd)
        layout.addView(btnSendCustom)
        layout.addView(tvCmdLog)
        setContentView(scrollView)

        // ==========================================
        // 逻辑处理
        // ==========================================

        // 1. 扫描与连接 (点击时自动检查并申请运行时蓝牙权限)
        btnScan.setOnClickListener {
            checkAndRequestBlePermissionsThenScan()
        }

        lifecycleScope.launch {
            ZKBrainManager.scannedDevices.collectLatest { devices ->
                val target = devices.firstOrNull()
                if (target != null && ZKBrainManager.connState.value == ZKBrainConnectionState.DISCONNECTED) {
                    ZKBrainManager.stopScan()
                    ZKBrainManager.connect(target)
                }
            }
        }

        lifecycleScope.launch {
            ZKBrainManager.connState.collectLatest { state ->
                tvStatus.text = "链路状态: ${state.name}"
            }
        }

        // 2. 监听 1Hz 专注度、放松度与 8 频段数据
        lifecycleScope.launch {
            ZKBrainManager.brainData.collectLatest { eeg ->
                tvAttention.text = "实时专注度 (Attention): ${eeg.attentionLevel} / 100"
                pbAttention.progress = eeg.attentionLevel

                tvMeditation.text = "实时放松度 (Meditation): ${eeg.meditationDepth} / 100"
                pbMeditation.progress = eeg.meditationDepth

                val bw = eeg.brainWaves
                tvBands.text = "Delta: ${bw.delta} | Theta: ${bw.theta} | LowAlpha: ${bw.lowAlpha} | HighAlpha: ${bw.highAlpha}\n" +
                        "LowBeta: ${bw.lowBeta} | HighBeta: ${bw.highBeta} | LowGamma: ${bw.lowGamma} | MidGamma: ${bw.middleGamma}"
            }
        }

        // 3. 🌟 硬件指令下发逻辑 / Hardware command dispatching
        fun sendDeviceCommand(bytes: ByteArray, desc: String) {
            val dev = ZKBrainManager.connectedDevice.value
            if (dev == null) {
                Toast.makeText(this, "Device not connected. Please connect first.", Toast.LENGTH_SHORT).show()
                return
            }
            ZKBrainManager.writeCommand(dev.address, bytes)
            Toast.makeText(this, "Command dispatched: $desc", Toast.LENGTH_SHORT).show()
            tvCmdLog.text = "[TX >>] $desc\n${tvCmdLog.text}"
        }

        fun sendConfig(key: String, value: String) {
            // sendConfigCommand with 2s deduplication
            ZKBrainManager.sendConfigCommand(mapOf(key to value))
            Toast.makeText(this, "Config sent: $key:$value", Toast.LENGTH_SHORT).show()
            tvCmdLog.text = "[TX >> sendConfig] $key:$value\n${tvCmdLog.text}"
        }

        btnMemsStream.setOnClickListener {
            // 1. ZKTeco 开启 MEMS 惯导流 (mems_on:1)
            sendConfig("mems_on", "1")
        }

        btnIgnite.setOnClickListener {
            // 2. Sky (NeuroSky) 标准 20 字节点火包 (0x15 Raw + 0x17 Band)
            val ignitionBytes = byteArrayOf(0x02, 0x15, 0x17)
            sendDeviceCommand(ignitionBytes, "点火包 (0x15 Raw + 0x17 Band)")
        }

        btnSendCustom.setOnClickListener {
            val input = etCustomCmd.text.toString().trim()
            if (input.isNotEmpty()) {
                if (input.contains(":")) {
                    val parts = input.split(":", limit = 2)
                    sendConfig(parts[0].trim(), parts[1].trim())
                } else {
                    sendDeviceCommand("$input\n".toByteArray(Charsets.UTF_8), input)
                }
            }
        }

        // 4. 监听设备指令回包与响应
        lifecycleScope.launch {
            ZKBrainManager.commandResponse.collectLatest { resp ->
                tvCmdLog.text = "[RX << 硬件回包] $resp\n${tvCmdLog.text}"
            }
        }
    }
}

// 🌟 便捷兼容扩展：支持开发者使用简写 .attention / .meditation
val MultiBrainEeg.attention: Int get() = attentionLevel
val MultiBrainEeg.meditation: Int get() = meditationDepth
