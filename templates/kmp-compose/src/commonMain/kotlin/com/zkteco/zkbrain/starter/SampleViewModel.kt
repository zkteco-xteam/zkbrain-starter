package com.zkteco.zkbrain.starter

import com.zkteco.zkbrain.ZKBrainManager
import com.zkteco.zkbrain.bean.ZKBrainScanState
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableSharedFlow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharedFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asSharedFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.isActive
import kotlinx.coroutines.launch
import kotlin.math.min

/**
 * 🌟 MVI 架构状态容器 (纯 Kotlin 实现，跨 Android / Desktop 通用)
 */
class SampleViewModel(private val scope: CoroutineScope) {

    private val _state = MutableStateFlow(SampleState())
    val state: StateFlow<SampleState> = _state.asStateFlow()

    private val _effect = MutableSharedFlow<SampleEffect>()
    val effect: SharedFlow<SampleEffect> = _effect.asSharedFlow()

    private val ringBuffer = ArrayDeque<Float>(300)
    private var rawPacketCount = 0

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

        // 3. 响应式监听 1Hz 综合脑电指标 (专注度/放松度/8频段 + 心流评估算法)
        scope.launch {
            ZKBrainManager.brainData.collect { eeg ->
                // 计算疲劳指数 (基于 Theta / (Alpha + Beta) 比值模型)
                val activePower = (eeg.lowBeta + eeg.highBeta + eeg.lowAlpha).coerceAtLeast(1)
                val fatigue = min(100, ((eeg.theta.toDouble() / activePower) * 80).toInt())

                // 心流状态评估
                val flowLevel = when {
                    eeg.attention >= 75 && eeg.meditation >= 60 -> "✨ 深度心流 (Deep Flow)"
                    eeg.attention >= 65 -> "🎯 高度专注 (Focused)"
                    eeg.meditation >= 70 -> "🧘 放松冥想 (Meditation)"
                    fatigue >= 65 -> "💤 疲劳预警 (Fatigued)"
                    else -> "平静日常 (Normal)"
                }

                _state.update { 
                    it.copy(
                        brainData = eeg,
                        fatigueIndex = fatigue,
                        flowStateLevel = flowLevel
                    ) 
                }
            }
        }

        // 4. 响应式监听 512Hz 原始微伏脑电波 (定长 300 点滑动窗口)
        scope.launch(Dispatchers.Default) {
            ZKBrainManager.rawdata.collect { raw ->
                rawPacketCount++
                synchronized(ringBuffer) {
                    if (ringBuffer.size >= 300) ringBuffer.removeFirst()
                    ringBuffer.add(raw.toFloat())
                    _state.update { it.copy(rawWaveBuffer = ringBuffer.toList()) }
                }
            }
        }

        // 5. 1秒窗口实时动态计算采样率 (Hz)
        scope.launch {
            while (isActive) {
                delay(1000L)
                val currentRate = rawPacketCount
                rawPacketCount = 0
                _state.update { it.copy(rawSampleRate = currentRate) }
            }
        }

        // 6. 监听扫描结果
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
            is SampleIntent.RequestBlePermission -> {
                scope.launch {
                    _effect.emit(SampleEffect.ShowToast("请检查并在系统设置中授予蓝牙扫描与连接权限"))
                }
            }
        }
    }
}
