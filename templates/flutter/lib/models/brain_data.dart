/// EEG 8-band absolute power data model
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

/// ZKBrain 1Hz cognitive metrics data model
class BrainData {
  final int attention;       // Attention index (0-100)
  final int meditation;      // Meditation index (0-100)
  final int signalQuality;   // Electrode contact quality (0: Good, 200: Poor/Off)
  final BrainWaves waves;

  const BrainData({
    this.attention = 0,
    this.meditation = 0,
    this.signalQuality = 200,
    this.waves = const BrainWaves(),
  });

  /// Calculate fatigue index based on Theta / (Alpha + Beta) ratio model
  int get fatigueIndex {
    final active = (waves.lowBeta + waves.highBeta + waves.lowAlpha).clamp(1, 9999999);
    final ratio = ((waves.theta / active) * 80).toInt();
    return ratio.clamp(0, 100);
  }

  /// Evaluate cognitive flow state
  String get flowState {
    if (attention >= 75 && meditation >= 60) return "Deep Flow";
    if (attention >= 65) return "Focused";
    if (meditation >= 70) return "Meditation";
    if (fatigueIndex >= 65) return "Fatigued";
    return "Normal";
  }
}
