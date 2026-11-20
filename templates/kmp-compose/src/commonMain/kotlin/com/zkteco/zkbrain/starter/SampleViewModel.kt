package com.zkteco.zkbrain.starter

import com.zkteco.zkbrain.ZKBrainManager
import com.zkteco.zkbrain.bean.ZKBrainScanState
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.MutableSharedFlow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharedFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asSharedFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch

/**
 * 🌟 MVI 架构状态容器 (纯 Kotlin 实现，跨 Android / Desktop 通用)
 */
class SampleViewModel(private val scope: CoroutineScope) {

    private val _state = MutableStateFlow(SampleState())
    val state: StateFlow<SampleState> = _state.asStateFlow()

    private val _effect = MutableSharedFlow<SampleEffect>()
    val effect: SharedFlow<SampleEffect> = _effect.asSharedFlow()

    private val ringBuffer = ArrayDeque<Float>(300)

    init {
        // 1. 响应式监听蓝牙连接状态
        scope.launch {
            ZKBrainManager.connState.collect { conn ->
                _state.update { it.copy(connectionState = conn) }
            }
        }

        // 2. 响应式监听当前已连接设备
        scope.launch {
            ZKBrainManager.connectedDevice.collect { device ->
                _state.update { it.copy(connectedDevice = device) }
            }
        }

        // 3. 响应式监听 1Hz 综合脑电指标 (专注度/放松度/8频段)
        scope.launch {
            ZKBrainManager.brainData.collect { eeg ->
                _state.update { it.copy(brainData = eeg) }
            }
        }

        // 4. 响应式监听 512Hz 原始微伏脑电波 (定长 300 点滑动窗口)
        scope.launch(Dispatchers.Default) {
            ZKBrainManager.rawdata.collect { raw ->
                synchronized(ringBuffer) {
                    if (ringBuffer.size >= 300) ringBuffer.removeFirst()
                    ringBuffer.add(raw.toFloat())
                    _state.update { it.copy(rawWaveBuffer = ringBuffer.toList()) }
                }
            }
        }

        // 5. 监听扫描结果
        scope.launch {
            ZKBrainManager.scannedDevices.collect { list ->
                _state.update { it.copy(scannedDevices = list) }
            }
        }
        scope.launch {
            ZKBrainManager.scanState.collect { s ->
                _state.update { it.copy(isScanning = s == ZKBrainScanState.SCANNING) }
            }
        }
    }

    fun handleIntent(intent: SampleIntent) {
        when (intent) {
            is SampleIntent.ToggleScan -> {
                if (_state.value.isScanning) {
                    ZKBrainManager.stopScan()
                } else {
                    ZKBrainManager.startScan(timeoutMillis = 10000L)
                }
            }
            is SampleIntent.ConnectDevice -> {
                ZKBrainManager.stopScan()
                ZKBrainManager.connect(intent.device)
            }
            is SampleIntent.Disconnect -> {
                ZKBrainManager.disconnect()
            }
        }
    }
}
