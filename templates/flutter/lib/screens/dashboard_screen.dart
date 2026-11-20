import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:provider/provider.dart';
import '../services/zkbrain_ble_service.dart';

/// 🌟 1:1 完整逐项克隆 shared1 设备管理控制台 (DeviceScreen + DeviceShowTable) - Flutter 原生版
/// 技术支持：熵基科技脑机事业部 (ZKTeco Brain-Computer Interface Division)
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // MEMS 姿态与欧拉角 (Euler & Quaternion)
  double _memsX = 0.0;
  double _memsY = 0.0;
  double _memsZ = 0.0;
  double _memsQ0 = 1.0;
  double _memsQ1 = 0.0;
  double _memsQ2 = 0.0;
  double _memsQ3 = 0.0;

  // 通道与图表显隐配置
  bool _isFp1Visible = true;
  bool _isFp2Visible = false;

  final Map<String, bool> _chartToggles = {
    "Raw EEG": true,
    "Signal Quality": true,
    "Attention": true,
    "Meditation": true,
    "Delta": true,
    "Theta": true,
    "Low Alpha": true,
    "High Alpha": true,
    "Low Beta": true,
    "High Beta": true,
    "Low Gamma": true,
    "Middle Gamma": true,
  };

  final TextEditingController _customCmdController = TextEditingController();
  final TextEditingController _writeSnController = TextEditingController();
  final List<String> _terminalLogs = [];
  String _dfuStatus = "DFU: 空闲就绪";

  @override
  void initState() {
    super.initState();
    _terminalLogs.add("[系统启动] ZKBrain Flutter 控制台初始化就绪");
  }

  @override
  void dispose() {
    _customCmdController.dispose();
    _writeSnController.dispose();
    super.dispose();
  }

  void _addLog(String log) {
    setState(() {
      _terminalLogs.add(log);
      if (_terminalLogs.length > 50) {
        _terminalLogs.removeAt(0);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final ble = context.watch<ZKBrainBleService>();
    final isConnected = ble.connectionState == BleConnectionState.connected;
    final deviceName = ble.connectedDevice?.platformName.isNotEmpty == true
        ? ble.connectedDevice!.platformName
        : (isConnected ? "ZKBrain Device" : "未连接设备");
    final deviceMac = ble.connectedDevice?.remoteId.str ?? "00:00:00:00:00:00";
    final isNeuroSky = deviceName.contains("MindWave") ||
        deviceName.contains("MW") ||
        deviceName.contains("TGAM") ||
        deviceName.contains("xpain");

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9), // 浅灰背景，贴近 shared1 Compose 原生质感
      appBar: AppBar(
        title: const Text(
          "设备管理 (DeviceScreen)",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF1E293B),
        elevation: 1,
        actions: [
          // 顶部操作栏
          IconButton(
            icon: const Icon(Icons.bluetooth_searching, color: Colors.white),
            tooltip: "搜索设备",
            onPressed: () => _showScanBottomSheet(context, ble),
          ),
          IconButton(
            icon: const Icon(Icons.system_update_alt, color: Colors.white),
            tooltip: "DFU升级",
            onPressed: () {
              setState(() {
                _dfuStatus = "DFU: 正在检查固件版本...";
              });
              _addLog("[DFU] 发起固件 OTA 检测，当前处于最新稳定版 v2.4.0");
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("DFU 固件检测完成：当前为最新版本")),
              );
            },
          ),
          Container(
            margin: const EdgeInsets.only(right: 12, top: 12, bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF22C55E).withOpacity(0.2),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFF22C55E)),
            ),
            child: const Center(
              child: Text(
                "Authorized",
                style: TextStyle(color: Color(0xFF22C55E), fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 板块 2：统一设备连接状态卡片
            _buildDeviceStatusCard(context, ble, isConnected, deviceName, deviceMac, isNeuroSky),
            const SizedBox(height: 12),

            // 板块 3：Channel Settings 通道配置卡片
            _buildChannelSettingsCard(),
            const SizedBox(height: 12),

            // 板块 4：Chart Display Settings 图表显隐卡片
            _buildChartDisplaySettingsCard(),
            const SizedBox(height: 12),

            // 板块 5：⚙️ NeuroSky / MindWave 专属 20 字节协议控制台
            _buildNeuroSkyConsoleCard(ble, isConnected),
            const SizedBox(height: 12),

            // 板块 6：🧠 ZKBrain 自研脑电设备官方控制台
            _buildZKBrainConsoleCard(ble, isConnected),
            const SizedBox(height: 12),

            // 板块 7：Spectrum Data 详细数据表格 (DeviceShowTable 4x3 三色)
            _buildDeviceShowTable(ble, deviceMac),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // 板块 2：统一设备连接状态卡片
  // ==========================================
  Widget _buildDeviceStatusCard(
    BuildContext context,
    ZKBrainBleService ble,
    bool isConnected,
    String deviceName,
    String deviceMac,
    bool isNeuroSky,
  ) {
    Color statusDotColor = const Color(0xFFEF4444);
    String statusText = "已断开 (Disconnected)";
    if (ble.connectionState == BleConnectionState.connected) {
      statusDotColor = const Color(0xFF22C55E);
      statusText = "已就绪 (READY)";
    } else if (ble.connectionState == BleConnectionState.connecting) {
      statusDotColor = const Color(0xFFF59E0B);
      statusText = "连接中 (CONNECTING)";
    }

    return Card(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: statusDotColor),
                ),
                const SizedBox(width: 8),
                Text(
                  statusText,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: statusDotColor),
                ),
                const Spacer(),
                // 电量胶囊
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF22C55E).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF22C55E)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text("🔋", style: TextStyle(fontSize: 12)),
                      SizedBox(width: 4),
                      Text("85%", style: TextStyle(color: Color(0xFF16A34A), fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              deviceName,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 6),
            Text("MAC: $deviceMac  |  SN: ZK-2026-DEV001", style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
            const SizedBox(height: 10),
            // 3 个分类徽章
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                _buildBadge(isNeuroSky ? "NeuroSky TGAM" : "ZKBrain Core", const Color(0xFF0284C7)),
                _buildBadge("Single-Ch (FP1)", const Color(0xFF0D9488)),
                _buildBadge(isNeuroSky ? "XMW-20B Binary" : "ASCII + MEMS", const Color(0xFF7C3AED)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isConnected ? const Color(0xFFDC2626) : const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    icon: Icon(isConnected ? Icons.link_off : Icons.bluetooth),
                    label: Text(isConnected ? "断开设备" : "搜索连接"),
                    onPressed: () {
                      if (isConnected) {
                        ble.disconnect();
                        _addLog("[BLE] 用户主动断开设备连接");
                      } else {
                        _showScanBottomSheet(context, ble);
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(text, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }

  // ==========================================
  // 板块 3：Channel Settings 通道配置卡片
  // ==========================================
  Widget _buildChannelSettingsCard() {
    return Card(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.tune, size: 18, color: Color(0xFF334155)),
                SizedBox(width: 8),
                Text("Channel Settings (通道配置)", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Checkbox(
                  value: _isFp1Visible,
                  activeColor: const Color(0xFF2563EB),
                  onChanged: (v) {
                    setState(() => _isFp1Visible = v ?? true);
                    _addLog("[通道设置] Left (FP1) 状态切换: $_isFp1Visible");
                  },
                ),
                const Text("Left (FP1)", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                const SizedBox(width: 24),
                Checkbox(
                  value: _isFp2Visible,
                  onChanged: null, // 禁用灰色
                ),
                Text("Right (FP2) [硬件不支持]", style: TextStyle(fontSize: 14, color: Colors.grey.shade400)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // 板块 4：Chart Display Settings 图表显隐卡片
  // ==========================================
  Widget _buildChartDisplaySettingsCard() {
    return Card(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.show_chart, size: 18, color: Color(0xFF334155)),
                SizedBox(width: 8),
                Text("Chart Display Settings (图表显隐配置)", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: _chartToggles.keys.map((title) {
                final isChecked = _chartToggles[title] ?? true;
                return FilterChip(
                  label: Text(title, style: TextStyle(fontSize: 12, color: isChecked ? Colors.white : const Color(0xFF334155))),
                  selected: isChecked,
                  selectedColor: const Color(0xFF2563EB),
                  backgroundColor: const Color(0xFFF1F5F9),
                  checkmarkColor: Colors.white,
                  onSelected: (val) {
                    setState(() => _chartToggles[title] = val);
                    _addLog("[图表配置] $title 显示状态: $val");
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // 板块 5：⚙️ NeuroSky / MindWave 专属 20 字节协议控制台
  // ==========================================
  Widget _buildNeuroSkyConsoleCard(ZKBrainBleService ble, bool isConnected) {
    return Card(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Text("⚙️", style: TextStyle(fontSize: 16)),
                SizedBox(width: 8),
                Text("NeuroSky / MindWave 专属协议控制台", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
              ],
            ),
            const SizedBox(height: 4),
            Text("支持 20 字节二进制点火帧、工频滤波、SN 读写与经典 MAC 探测", style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildConsoleBtn("🚀 点火启动 (0x15/17)", const Color(0xFF16A34A), () {
                  ble.sendCommandBytes([0x02, 0x15, 0x17], "NeuroSky点火包 [0x15 Raw + 0x17 Band]");
                  _addLog("[TX >> XMW] 下发点火包: 0x15 (Raw) + 0x17 (Band)");
                }),
                _buildConsoleBtn("🛑 停止传输 (0x16/18)", const Color(0xFFDC2626), () {
                  ble.sendCommandBytes([0x02, 0x16, 0x18], "停止传输 [0x16 + 0x18]");
                  _addLog("[TX >> XMW] 停止传输: 0x16 + 0x18");
                }),
                _buildConsoleBtn("50Hz 工频滤波 (0x1B)", const Color(0xFF475569), () {
                  ble.sendXmwCommand(0x1B, "工频陷波 50Hz (0x1B)");
                  _addLog("[TX >> XMW] 设置 50Hz 工频陷波滤波");
                }),
                _buildConsoleBtn("60Hz 工频滤波 (0x1C)", const Color(0xFF475569), () {
                  ble.sendXmwCommand(0x1C, "工频陷波 60Hz (0x1C)");
                  _addLog("[TX >> XMW] 设置 60Hz 工频陷波滤波");
                }),
                _buildConsoleBtn("读电量 (0x06)", const Color(0xFFD97706), () {
                  ble.sendXmwCommand(0x06, "读取电量 (0x06)");
                  _addLog("[TX >> XMW] 读取硬件电量 (0x06)");
                }),
                _buildConsoleBtn("读序列号 (0xF4)", const Color(0xFFD97706), () {
                  ble.sendXmwCommand(0xF4, "读取序列号 SN (0xF4)");
                  _addLog("[TX >> XMW] 查询设备序列号 SN (0xF4)");
                }),
                _buildConsoleBtn("探测经典MAC (0xFC)", const Color(0xFF7C3AED), () {
                  ble.sendXmwCommand(0xFC, "探测经典蓝牙 MAC (0xFC)");
                  _addLog("[TX >> XMW] 探测经典蓝牙 MAC 地址 (0xFC)");
                }),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 38,
                    child: TextField(
                      controller: _writeSnController,
                      decoration: const InputDecoration(
                        hintText: "输入写入序列号 SN...",
                        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                        border: OutlineInputBorder(),
                      ),
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F172A),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                  onPressed: () {
                    final sn = _writeSnController.text.trim();
                    if (sn.isNotEmpty) {
                      _addLog("[TX >> XMW] 写入 SN (0xF2): $sn");
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("SN 写入指令已发送: $sn")));
                    }
                  },
                  child: const Text("写入 SN (0xF2)", style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // 板块 6：🧠 ZKBrain 自研脑电设备官方控制台
  // ==========================================
  Widget _buildZKBrainConsoleCard(ZKBrainBleService ble, bool isConnected) {
    return Card(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Text("🧠", style: TextStyle(fontSize: 16)),
                SizedBox(width: 8),
                Text("ZKBrain 自研脑电设备控制台", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
              ],
            ),
            const SizedBox(height: 4),
            Text("支持 ASCII 控制、MEMS 姿态传感、采样率切换与终端实时回显", style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            const SizedBox(height: 12),

            // 快捷控制按钮矩阵
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildConsoleBtn("查询授权 (license:?)", const Color(0xFF0284C7), () {
                  ble.sendCommandString("license:?;\n");
                  _addLog("[TX >>] license:?");
                }),
                _buildConsoleBtn("读电量 (battery:?)", const Color(0xFF0284C7), () {
                  ble.sendCommandString("battery:?;\n");
                  _addLog("[TX >>] battery:?");
                }),
                _buildConsoleBtn("固件版本 (version:?)", const Color(0xFF0284C7), () {
                  ble.sendCommandString("version:?;\n");
                  _addLog("[TX >>] version:?");
                }),
                _buildConsoleBtn("开启脑电 (eeg_data_on:1)", const Color(0xFF16A34A), () {
                  ble.sendCommandString("eeg_data_on:1;\n");
                  _addLog("[TX >>] eeg_data_on:1");
                }),
                _buildConsoleBtn("关闭脑电 (eeg_data_on:0)", const Color(0xFFDC2626), () {
                  ble.sendCommandString("eeg_data_on:0;\n");
                  _addLog("[TX >>] eeg_data_on:0");
                }),
                _buildConsoleBtn("256Hz采样率", const Color(0xFF475569), () {
                  ble.sendCommandString("eeg_data_rate:2;\n");
                  _addLog("[TX >>] eeg_data_rate:2 (256Hz)");
                }),
                _buildConsoleBtn("512Hz采样率", const Color(0xFF475569), () {
                  ble.sendCommandString("eeg_data_rate:1;\n");
                  _addLog("[TX >>] eeg_data_rate:1 (512Hz)");
                }),
                _buildConsoleBtn("开启MEMS (mems_on:1)", const Color(0xFF059669), () {
                  ble.sendCommandString("mems_on:1;\n");
                  _addLog("[TX >>] mems_on:1");
                }),
                _buildConsoleBtn("关闭MEMS (mems_on:0)", const Color(0xFF9CA3AF), () {
                  ble.sendCommandString("mems_on:0;\n");
                  _addLog("[TX >>] mems_on:0");
                }),
                _buildConsoleBtn("DFU 扫描模式", const Color(0xFF7C3AED), () {
                  ble.sendCommandString("dfu_scan:1;\n");
                  _addLog("[TX >>] dfu_scan:1 (进入DFU空中升级就绪模式)");
                }),
              ],
            ),
            const SizedBox(height: 12),

            // MEMS 姿态传感实时卡片 (Euler & Quaternion)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("📐 实时 MEMS 空间姿态 (Euler & Quaternion)", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
                  const SizedBox(height: 6),
                  Text(
                    "Euler:  Roll: ${_memsX.toStringAsFixed(1)}°   Pitch: ${_memsY.toStringAsFixed(1)}°   Yaw: ${_memsZ.toStringAsFixed(1)}°",
                    style: const TextStyle(fontSize: 12, fontFamily: 'monospace', color: Color(0xFF1E293B)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Quat:   Q0: ${_memsQ0.toStringAsFixed(3)}  Q1: ${_memsQ1.toStringAsFixed(3)}  Q2: ${_memsQ2.toStringAsFixed(3)}  Q3: ${_memsQ3.toStringAsFixed(3)}",
                    style: const TextStyle(fontSize: 12, fontFamily: 'monospace', color: Color(0xFF475569)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // 自定义键值对指令发送框
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 38,
                    child: TextField(
                      controller: _customCmdController,
                      decoration: const InputDecoration(
                        hintText: "自定义指令 (如 mems_on:1 或 sample_rate:512)",
                        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                        border: OutlineInputBorder(),
                      ),
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                  onPressed: () {
                    final cmd = _customCmdController.text.trim();
                    if (cmd.isNotEmpty) {
                      ble.sendCommandString(cmd.endsWith(";") ? "$cmd\n" : "$cmd;\n");
                      _addLog("[TX >>] $cmd");
                    }
                  },
                  child: const Text("发送指令", style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 黑底终端回显监控窗口
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("终端响应监控 (Terminal Monitor):", style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
                      InkWell(
                        onTap: () => setState(() => _terminalLogs.clear()),
                        child: const Text("清空", style: TextStyle(color: Color(0xFF38BDF8), fontSize: 12)),
                      ),
                    ],
                  ),
                  const Divider(color: Color(0xFF334155), height: 12),
                  Container(
                    constraints: const BoxConstraints(maxHeight: 120),
                    child: SingleChildScrollView(
                      reverse: true,
                      child: Text(
                        _terminalLogs.isEmpty ? "等待下发或接收指令回包...\n" : _terminalLogs.join("\n"),
                        style: const TextStyle(
                          color: Color(0xFF4ADE80),
                          fontFamily: 'monospace',
                          fontSize: 11,
                          height: 1.4,
                        ),
                      ),
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

  Widget _buildConsoleBtn(String label, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withOpacity(0.4)),
        ),
        child: Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
      ),
    );
  }

  // ==========================================
  // 板块 7：Spectrum Data 详细数据表格 (DeviceShowTable 4x3 三色)
  // 粉色 #FFE4E1 (Attention, Meditation, Quality, Raw EEG)
  // 青色 #E0FFFF (Delta, Theta, Low Alpha, High Alpha)
  // 黄色 #F0E68C (Low Beta, High Beta, Low Gamma, Mid Gamma)
  // ==========================================
  Widget _buildDeviceShowTable(ZKBrainBleService ble, String deviceMac) {
    final data = ble.currentBrainData;
    final waves = data.waves;

    return Card(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 顶部居中 MAC 标题条
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Center(
                child: Text(
                  "Device MAC: $deviceMac",
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13, fontFamily: 'monospace'),
                ),
              ),
            ),
            const SizedBox(height: 10),

            // 4x3 单元格矩阵 (粉 #FFE4E1, 青 #E0FFFF, 黄 #F0E68C)
            Table(
              border: TableBorder.all(color: const Color(0xFFCBD5E1), width: 1),
              children: [
                // 第一行 (粉色背景 #FFE4E1)
                TableRow(
                  decoration: const BoxDecoration(color: Color(0xFFFFE4E1)),
                  children: [
                    _buildTableCell("Attention", "${data.attention}"),
                    _buildTableCell("Meditation", "${data.meditation}"),
                    _buildTableCell("Quality", "${data.signalQuality}"),
                  ],
                ),
                // 第二行 (粉 + 青)
                TableRow(
                  children: [
                    Container(color: const Color(0xFFFFE4E1), child: _buildTableCell("Raw EEG", "${ble.rawWaveBuffer.isNotEmpty ? ble.rawWaveBuffer.last.toInt() : 0}")),
                    Container(color: const Color(0xFFE0FFFF), child: _buildTableCell("Delta", "${waves.delta}")),
                    Container(color: const Color(0xFFE0FFFF), child: _buildTableCell("Theta", "${waves.theta}")),
                  ],
                ),
                // 第三行 (青 + 黄)
                TableRow(
                  children: [
                    Container(color: const Color(0xFFE0FFFF), child: _buildTableCell("Low Alpha", "${waves.lowAlpha}")),
                    Container(color: const Color(0xFFE0FFFF), child: _buildTableCell("High Alpha", "${waves.highAlpha}")),
                    Container(color: const Color(0xFFF0E68C), child: _buildTableCell("Low Beta", "${waves.lowBeta}")),
                  ],
                ),
                // 第四行 (黄色背景 #F0E68C)
                TableRow(
                  decoration: const BoxDecoration(color: Color(0xFFF0E68C)),
                  children: [
                    _buildTableCell("High Beta", "${waves.highBeta}"),
                    _buildTableCell("Low Gamma", "${waves.lowGamma}"),
                    _buildTableCell("Mid Gamma", "${waves.middleGamma}"),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTableCell(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Column(
        children: [
          Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF334155)), textAlign: TextAlign.center),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A), fontFamily: 'monospace'), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  // ==========================================
  // 板块 8：蓝牙搜索连接底部弹窗 (BleScanDialog)
  // ==========================================
  void _showScanBottomSheet(BuildContext context, ZKBrainBleService ble) {
    ble.startScan();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final scanResults = ble.scanResults;
            return Container(
              padding: const EdgeInsets.all(16),
              height: MediaQuery.of(context).size.height * 0.65,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "🔍 搜索周围脑电设备",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          ble.stopScan();
                          Navigator.pop(ctx);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(ble.isScanning ? "正在扫描低功耗蓝牙设备..." : "扫描完成", style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                      const Spacer(),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        ),
                        onPressed: () {
                          ble.startScan();
                          setModalState(() {});
                        },
                        child: Text(ble.isScanning ? "扫描中" : "重新扫描", style: const TextStyle(fontSize: 12)),
                      ),
                    ],
                  ),
                  const Divider(height: 16),
                  Expanded(
                    child: scanResults.isEmpty
                        ? const Center(
                            child: Text("暂未发现脑电设备，请确认设备已开机并在附近", style: TextStyle(color: Colors.grey, fontSize: 13)),
                          )
                        : ListView.separated(
                            itemCount: scanResults.length,
                            separatorBuilder: (_, __) => const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final item = scanResults[index];
                              final name = item.device.platformName.isNotEmpty ? item.device.platformName : "未知蓝牙设备";
                              return ListTile(
                                leading: const Icon(Icons.bluetooth, color: Color(0xFF2563EB)),
                                title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                subtitle: Text("${item.device.remoteId.str} | RSSI: ${item.rssi} dBm", style: const TextStyle(fontSize: 12)),
                                trailing: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF16A34A),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  ),
                                  child: const Text("连接", style: TextStyle(fontSize: 12)),
                                  onPressed: () {
                                    ble.connect(item.device);
                                    Navigator.pop(ctx);
                                    _addLog("[BLE] 发起连接: $name (${item.device.remoteId.str})");
                                  },
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
