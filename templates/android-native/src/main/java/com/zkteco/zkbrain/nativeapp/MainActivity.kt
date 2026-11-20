package com.zkteco.zkbrain.nativeapp

import android.os.Bundle
import android.widget.Button
import android.widget.ProgressBar
import android.widget.TextView
import android.widget.Toast
import androidx.appcompat.app.AppCompatActivity
import androidx.lifecycle.lifecycleScope
import com.zkteco.zkbrain.ZKBrainManager
import com.zkteco.zkbrain.bean.ZKBrainConnectionState
import kotlinx.coroutines.flow.collectLatest
import kotlinx.coroutines.launch

/**
 * 🌟 纯原生 Android 开发者极速样板 (纯 Kotlin + LifecycleScope)
 */
class MainActivity : AppCompatActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // 编程式极简布局，开箱直接编译运行
        val layout = android.widget.LinearLayout(this).apply {
            orientation = android.widget.LinearLayout.VERTICAL
            setPadding(48, 48, 48, 48)
        }

        val tvStatus = TextView(this).apply {
            text = "链路状态: 未连接"
            textSize = 18f
        }
        val btnScan = Button(this).apply {
            text = "⚡ 扫描并连接脑电设备"
        }
        val tvAttention = TextView(this).apply {
            text = "实时专注度: 0 / 100"
            textSize = 16f
        }
        val pbAttention = ProgressBar(this, null, android.R.attr.progressBarStyleHorizontal).apply {
            max = 100
        }
        val tvMeditation = TextView(this).apply {
            text = "实时放松度: 0 / 100"
            textSize = 16f
        }
        val pbMeditation = ProgressBar(this, null, android.R.attr.progressBarStyleHorizontal).apply {
            max = 100
        }

        layout.addView(tvStatus)
        layout.addView(btnScan)
        layout.addView(tvAttention)
        layout.addView(pbAttention)
        layout.addView(tvMeditation)
        layout.addView(pbMeditation)
        setContentView(layout)

        // 1. 扫描与连接
        btnScan.setOnClickListener {
            Toast.makeText(this, "正在扫描周围有效脑电设备...", Toast.LENGTH_SHORT).show()
            ZKBrainManager.startScan(timeoutMillis = 10000L)
        }

        // 2. 自动匹配首个扫描到的设备并建连
        lifecycleScope.launch {
            ZKBrainManager.scannedDevices.collectLatest { devices ->
                val target = devices.firstOrNull()
                if (target != null && ZKBrainManager.connState.value == ZKBrainConnectionState.DISCONNECTED) {
                    ZKBrainManager.stopScan()
                    ZKBrainManager.connect(target)
                }
            }
        }

        // 3. 监听连接状态
        lifecycleScope.launch {
            ZKBrainManager.connState.collectLatest { state ->
                tvStatus.text = "链路状态: ${state.name}"
            }
        }

        // 4. 监听 1Hz 专注度与放松度 (官方标准字段: attentionLevel / meditationDepth)
        lifecycleScope.launch {
            ZKBrainManager.brainData.collectLatest { eeg ->
                tvAttention.text = "实时专注度 (Attention): ${eeg.attentionLevel} / 100"
                pbAttention.progress = eeg.attentionLevel

                tvMeditation.text = "实时放松度 (Meditation): ${eeg.meditationDepth} / 100"
                pbMeditation.progress = eeg.meditationDepth
            }
        }
    }
}

// 🌟 便捷兼容扩展：支持开发者使用简写 .attention / .meditation
val com.zkteco.zkbrain.bean.MultiBrainEeg.attention: Int get() = attentionLevel
val com.zkteco.zkbrain.bean.MultiBrainEeg.meditation: Int get() = meditationDepth
