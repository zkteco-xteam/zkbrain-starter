/**
 * EEG 8-band absolute power model
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
 * 1Hz comprehensive cognitive metrics model
 */
export interface BrainData {
  attention: number;     // Attention index (0-100)
  meditation: number;    // Meditation index (0-100)
  signalQuality: number; // Electrode contact quality (0: Good, 200: Poor/Off)
  waves: BrainWaves;
}

/**
 * Calculate fatigue index
 */
export function calculateFatigue(waves: BrainWaves): number {
  const active = Math.max(1, waves.lowBeta + waves.highBeta + waves.lowAlpha);
  const ratio = Math.floor((waves.theta / active) * 80);
  return Math.min(100, Math.max(0, ratio));
}

/**
 * Evaluate cognitive flow state
 */
export function evaluateFlowState(attention: number, meditation: number, fatigue: number): string {
  if (attention >= 75 && meditation >= 60) return "Deep Flow";
  if (attention >= 65) return "Focused";
  if (meditation >= 70) return "Meditation";
  if (fatigue >= 65) return "Fatigued";
  return "Normal";
}
