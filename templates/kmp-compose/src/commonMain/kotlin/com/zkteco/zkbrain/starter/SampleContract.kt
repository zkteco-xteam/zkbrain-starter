package com.zkteco.zkbrain.starter

import com.zkteco.zkbrain.bean.MultiBrainEeg
import com.zkteco.zkbrain.bean.ZKBrainConnectionState
import com.zkteco.zkbrain.bean.ZKBrainDevice

/**
 * 🌟 MVI 架构黄金契约定义
 * 供下游开发者与 AI 直接扩展业务状态
 */
data class SampleState(
    val connectionState: ZKBrainConnectionState = ZKBrainConnectionState.DISCONNECTED,
    val connectedDevice: ZKBrainDevice? = null,
    val isScanning: Boolean = false,
    val scannedDevices: List<ZKBrainDevice> = emptyList(),
    val brainData: MultiBrainEeg? = null,
    val rawWaveBuffer: List<Float> = emptyList(), // 512Hz 原始波微伏采样点缓冲 (定长)
    val rawSampleRate: Int = 0,                   // 动态采样率 (Hz，如 512)
    val fatigueIndex: Int = 0,                    // 疲劳预警指数 (0-100，基于 Theta/Beta 功率比值)
    val flowStateLevel: String = "安静待命"        // 心流状态评估
)

sealed interface SampleIntent {
    data object ToggleScan : SampleIntent
    data class ConnectDevice(val device: ZKBrainDevice) : SampleIntent
    data object Disconnect : SampleIntent
    data object RequestBlePermission : SampleIntent
}

sealed interface SampleEffect {
    data class ShowToast(val message: String) : SampleEffect
}
