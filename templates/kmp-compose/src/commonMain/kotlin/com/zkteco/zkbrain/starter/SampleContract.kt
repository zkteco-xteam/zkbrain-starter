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
    val rawWaveBuffer: List<Float> = emptyList() // 512Hz 原始波微伏采样点缓冲 (定长)
)

sealed interface SampleIntent {
    data object ToggleScan : SampleIntent
    data class ConnectDevice(val device: ZKBrainDevice) : SampleIntent
    data object Disconnect : SampleIntent
}

sealed interface SampleEffect {
    data class ShowToast(val message: String) : SampleEffect
}
