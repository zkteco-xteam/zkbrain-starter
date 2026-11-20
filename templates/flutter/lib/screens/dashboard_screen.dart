import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/zkbrain_ble_service.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ble = context.watch<ZKBrainBleService>();
    final data = ble.currentBrainData;
    final waves = data.waves;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text("ZKBrain Flutter 脑机交互看板", style: TextStyle(fontSize: 18, color: Colors.white)),
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // 1. 链路控制卡片
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: ble.connectionState == BleConnectionState.connected
                              ? const Color(0xFF22C55E)
                              : ble.connectionState == BleConnectionState.connecting
                                  ? const Color(0xFFF59E0B)
                                  : const Color(0xFFEF4444),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "链路: ${ble.connectionState.name.toUpperCase()}",
                        style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  ElevatedButton(
                    onPressed: () {
                      if (ble.connectionState == BleConnectionState.disconnected) {
                        ble.startScan();
                      } else {
                        ble.disconnect();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ble.connectionState == BleConnectionState.connected
                          ? const Color(0xFFDC2626)
                          : const Color(0xFF2563EB),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Text(
                      ble.connectionState == BleConnectionState.connected
                          ? "断开连接"
                          : ble.isScanning
                              ? "扫描中..."
                              : "⚡ 扫描脑电设备",
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 2. 专注与放松核心指标
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("核心认知指标 (1Hz eSense)", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  _buildProgressBar("专注度 (Attention)", data.attention, const Color(0xFF38BDF8)),
                  const SizedBox(height: 12),
                  _buildProgressBar("放松度 (Meditation)", data.meditation, const Color(0xFF4ADE80)),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("心流状态: ${data.flowState}", style: const TextStyle(color: Color(0xFFFBBF24), fontSize: 13)),
                      Text("疲劳指数: ${data.fatigueIndex}%", style: TextStyle(color: data.fatigueIndex >= 60 ? const Color(0xFFF87171) : const Color(0xFF94A3B8), fontSize: 13)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 3. 512Hz 实时示波器
            Container(
              height: 160,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF334155)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("512Hz 实时示波器 (Raw EEG, μV)", style: TextStyle(color: Color(0xFF38BDF8), fontSize: 13)),
                      Text("${ble.sampleRate} Hz", style: const TextStyle(color: Color(0xFF4ADE80), fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: CustomPaint(
                      painter: WaveformPainter(ble.rawWaveBuffer),
                      size: Size.infinite,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 4. 8 频段功率谱
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("脑波 8 频段绝对能量分布 (Power Spectrum)", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  _buildBandRow("Delta (0.5-2.75Hz 深度睡眠)", waves.delta, const Color(0xFF818CF8)),
                  _buildBandRow("Theta (3.5-6.75Hz 冥想/创意)", waves.theta, const Color(0xFF38BDF8)),
                  _buildBandRow("Low Alpha (7.5-9.25Hz 放松闭眼)", waves.lowAlpha, const Color(0xFF34D399)),
                  _buildBandRow("High Alpha (10-11.75Hz 静心心流)", waves.highAlpha, const Color(0xFF4ADE80)),
                  _buildBandRow("Low Beta (13-16.75Hz 轻度专注)", waves.lowBeta, const Color(0xFFFBBF24)),
                  _buildBandRow("High Beta (17-29.75Hz 紧张计算)", waves.highBeta, const Color(0xFFFB923C)),
                  _buildBandRow("Low Gamma (31-39.75Hz 认知加工)", waves.lowGamma, const Color(0xFFF43F5E)),
                  _buildBandRow("Mid Gamma (41-49.75Hz 多感官整合)", waves.middleGamma, const Color(0xFFE11D48)),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 5. 🌟 MEMS 传感器与指令下发控制台
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("🛠️ MEMS 传感器与指令下发控制台", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => ble.sendCommandString("mems_enable=1;\n"),
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0284C7)),
                          child: const Text("📡 开启 MEMS", style: TextStyle(color: Colors.white, fontSize: 12)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => ble.sendCommandBytes([0x02, 0x15, 0x17], "0x15/0x17 点火包"),
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEA580C)),
                          child: const Text("🔥 点火指令", style: TextStyle(color: Colors.white, fontSize: 12)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      "最新指令响应: ${ble.lastCommandResponse}",
                      style: const TextStyle(color: Color(0xFF4ADE80), fontSize: 12, fontFamily: 'monospace'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar(String title, int value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14)),
            Text("$value / 100", style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 6),
        LinearProgressIndicator(
          value: value / 100.0,
          backgroundColor: const Color(0xFF334155),
          valueColor: AlwaysStoppedAnimation(color),
          minHeight: 8,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }

  Widget _buildBandRow(String title, int power, Color color) {
    final norm = (power / 50000.0).clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 12)),
              Text("$power", style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 3),
          LinearProgressIndicator(
            value: norm,
            backgroundColor: const Color(0xFF334155),
            valueColor: AlwaysStoppedAnimation(color),
            minHeight: 4,
            borderRadius: BorderRadius.circular(2),
          ),
        ],
      ),
    );
  }
}

class WaveformPainter extends CustomPainter {
  final List<double> points;
  WaveformPainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    final midY = size.height / 2;
    final gridPaint = Paint()
      ..color = const Color(0xFF334155)
      ..strokeWidth = 1.0;
    canvas.drawLine(Offset(0, midY), Offset(size.width, midY), gridPaint);

    if (points.length < 2) return;

    final wavePaint = Paint()
      ..color = const Color(0xFF00E5FF)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final path = Path();
    final stepX = size.width / (points.length - 1);

    for (int i = 0; i < points.length; i++) {
      final x = i * stepX;
      final y = (midY - (points[i] / 200.0) * (size.height / 2.5)).clamp(0.0, size.height);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, wavePaint);
  }

  @override
  bool shouldRepaint(covariant WaveformPainter oldDelegate) => true;
}
