/// 🌟 脑电 8 频段绝对功率数据实体
class BrainWaves {
  final int delta;
  final int theta;
  final int lowAlpha;
  final int highAlpha;
  final int lowBeta;
  final int highBeta;
  final int lowGamma;
  final int middleGamma;

  const BrainWaves({
    this.delta = 0,
    this.theta = 0,
    this.lowAlpha = 0,
    this.highAlpha = 0,
    this.lowBeta = 0,
    this.highBeta = 0,
    this.lowGamma = 0,
    this.middleGamma = 0,
  });
}

/// 🌟 ZKBrain 综合脑电指标数据实体 (1Hz)
class BrainData {
  final int attention;       // 专注度 (0-100)
  final int meditation;      // 放松度 (0-100)
  final int signalQuality;   // 接触质量 (0: 良好, 200: 脱落)
  final BrainWaves waves;

  const BrainData({
    this.attention = 0,
    this.meditation = 0,
    this.signalQuality = 200,
    this.waves = const BrainWaves(),
  });

  /// 计算疲劳指数 (基于 Theta / (Alpha + Beta) 比值模型)
  int get fatigueIndex {
    final active = (waves.lowBeta + waves.highBeta + waves.lowAlpha).clamp(1, 9999999);
    final ratio = ((waves.theta / active) * 80).toInt();
    return ratio.clamp(0, 100);
  }

  /// 计算心流状态描述
  String get flowState {
    if (attention >= 75 && meditation >= 60) return "✨ 深度心流 (Deep Flow)";
    if (attention >= 65) return "🎯 高度专注 (Focused)";
    if (meditation >= 70) return "🧘 放松冥想 (Meditation)";
    if (fatigueIndex >= 65) return "💤 疲劳预警 (Fatigued)";
    return "平静日常 (Normal)";
  }
}
