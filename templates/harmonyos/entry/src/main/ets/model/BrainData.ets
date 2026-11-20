/**
 * 🌟 脑波 8 频段绝对功率实体
 */
export interface BrainWaves {
  delta: number;
  theta: number;
  lowAlpha: number;
  highAlpha: number;
  lowBeta: number;
  highBeta: number;
  lowGamma: number;
  middleGamma: number;
}

/**
 * 🌟 综合脑电指标数据实体 (1Hz)
 */
export interface BrainData {
  attention: number;     // 专注度 (0-100)
  meditation: number;    // 放松度 (0-100)
  signalQuality: number; // 接触质量 (0 良好, 200 脱落)
  waves: BrainWaves;
}

/**
 * 疲劳指数计算
 */
export function calculateFatigue(waves: BrainWaves): number {
  const active = Math.max(1, waves.lowBeta + waves.highBeta + waves.lowAlpha);
  const ratio = Math.floor((waves.theta / active) * 80);
  return Math.min(100, Math.max(0, ratio));
}

/**
 * 心流状态判定
 */
export function evaluateFlowState(attention: number, meditation: number, fatigue: number): string {
  if (attention >= 75 && meditation >= 60) return "✨ 深度心流 (Deep Flow)";
  if (attention >= 65) return "🎯 高度专注 (Focused)";
  if (meditation >= 70) return "🧘 放松冥想 (Meditation)";
  if (fatigue >= 65) return "💤 疲劳预警 (Fatigued)";
  return "平静日常 (Normal)";
}
