package com.zkteco.zkbrain.starter

import com.zkteco.zkbrain.bean.MultiBrainEeg

/**
 * 🌟 脑电实体便捷扁平化扩展属性
 * 兼容 .attention / .meditation 以及 8 频段快捷访问
 */
val MultiBrainEeg.attention: Int get() = attentionLevel
val MultiBrainEeg.meditation: Int get() = meditationDepth
val MultiBrainEeg.delta: Int get() = brainWaves.delta
val MultiBrainEeg.theta: Int get() = brainWaves.theta
val MultiBrainEeg.lowAlpha: Int get() = brainWaves.lowAlpha
val MultiBrainEeg.highAlpha: Int get() = brainWaves.highAlpha
val MultiBrainEeg.lowBeta: Int get() = brainWaves.lowBeta
val MultiBrainEeg.highBeta: Int get() = brainWaves.highBeta
val MultiBrainEeg.lowGamma: Int get() = brainWaves.lowGamma
val MultiBrainEeg.middleGamma: Int get() = brainWaves.middleGamma
