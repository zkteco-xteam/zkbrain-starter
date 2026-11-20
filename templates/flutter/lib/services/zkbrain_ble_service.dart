import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../models/brain_data.dart';

enum BleConnectionState { disconnected, connecting, connected }

/// 🌟 ZKBrain 蓝牙 BLE 跨平台通信与解析服务
/// 技术支持：熵基科技脑机事业部 (ZKTeco BCI Team)
class ZKBrainBleService extends ChangeNotifier {
  BleConnectionState connectionState = BleConnectionState.disconnected;
  BluetoothDevice? connectedDevice;
  List<ScanResult> scanResults = [];
  bool isScanning = false;

  BrainData currentBrainData = const BrainData();
  final List<double> rawWaveBuffer = [];
  int sampleRate = 0;
  int _rawCount = 0;

  StreamSubscription? _scanSub;
  StreamSubscription? _dataSub;
  Timer? _rateTimer;

  ZKBrainBleService() {
    _rateTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      sampleRate = _rawCount;
      _rawCount = 0;
      notifyListeners();
    });
  }

  /// 扫描周围脑电设备 (过滤常见脑电设备前缀: MindWave, BrainLink, ZK-EEG 等)
  Future<void> startScan() async {
    scanResults.clear();
    isScanning = true;
    notifyListeners();

    _scanSub = FlutterBluePlus.scanResults.listen((results) {
      scanResults = results;
      notifyListeners();
    });

    await FlutterBluePlus.startScan(timeout: const Duration(seconds: 10));
    isScanning = false;
    notifyListeners();
  }

  Future<void> stopScan() async {
    await FlutterBluePlus.stopScan();
    isScanning = false;
    notifyListeners();
  }

  BluetoothCharacteristic? _writeCharacteristic;
  String lastCommandResponse = "暂无回包数据";

  /// 连接目标设备
  Future<void> connect(BluetoothDevice device) async {
    await stopScan();
    connectionState = BleConnectionState.connecting;
    notifyListeners();

    try {
      await device.connect(autoConnect: false);
      connectedDevice = device;
      connectionState = BleConnectionState.connected;
      notifyListeners();

      // 发现服务并监听脑电特征值通道
      final services = await device.discoverServices();
      for (final service in services) {
        for (final char in service.characteristics) {
          if (char.properties.write || char.properties.writeWithoutResponse) {
            _writeCharacteristic = char;
          }
          if (char.properties.notify || char.properties.indicate) {
            await char.setNotifyValue(true);
            _dataSub = char.lastValueStream.listen(_onDataReceived);
          }
        }
      }
    } catch (e) {
      debugPrint("BLE connection error: $e");
      connectionState = BleConnectionState.disconnected;
      notifyListeners();
    }
  }

  /// 🌟 下发 ZKTeco (自研脑电系列) 键值对配置指令 (如 mems_on:1, eeg_data_rate:512)
  Future<void> sendConfigCommand(Map<String, String> config) async {
    for (final entry in config.entries) {
      final cmd = "${entry.key}:${entry.value};\n";
      await sendCommandString(cmd, "ZKTeco配置: ${entry.key}:${entry.value}");
    }
  }

  /// 🌟 下发 Sky (NeuroSky / MindWave 系列) 20 字节二进制 XMW 指令
  Future<void> sendXmwCommand(int opCode, [String desc = ""]) async {
    // 构造标准 20 字节 XMW 指令帧: 0x77, dlen=2, opCode, padding..., checksum
    final packet = List<int>.filled(20, 0);
    packet[0] = 0x77;
    packet[1] = 0x02; // dlen
    packet[2] = opCode & 0xFF;
    int sum = 0;
    for (int i = 1; i <= 18; i++) {
      sum += packet[i];
    }
    packet[19] = (sum ^ 0xFF) & 0xFF; // 取反校验和

    await sendCommandBytes(packet, desc.isNotEmpty ? desc : "XMW OpCode 0x${opCode.toRadixString(16).toUpperCase()}");
  }

  /// 🌟 下发通用字节流或自定义硬件指令
  Future<void> sendCommandBytes(List<int> bytes, [String desc = ""]) async {
    if (_writeCharacteristic != null) {
      await _writeCharacteristic!.write(bytes, withoutResponse: false);
      lastCommandResponse = "[TX >>] ${desc.isNotEmpty ? desc : bytes.toString()}";
      notifyListeners();
    } else {
      lastCommandResponse = "[未连接] 无法发送: $desc";
      notifyListeners();
    }
  }

  Future<void> sendCommandString(String text, [String desc = ""]) async {
    await sendCommandBytes(text.codeUnits, desc.isNotEmpty ? desc : text.trim());
  }

  Future<void> disconnect() async {
    await _dataSub?.cancel();
    await connectedDevice?.disconnect();
    connectedDevice = null;
    connectionState = BleConnectionState.disconnected;
    notifyListeners();
  }

  /// 模拟与真实数据接收流水线
  void _onDataReceived(List<int> bytes) {
    _rawCount++;
    if (rawWaveBuffer.length >= 300) {
      rawWaveBuffer.removeAt(0);
    }
    // 假设接收到的时域波形点
    if (bytes.isNotEmpty) {
      rawWaveBuffer.add((bytes[0] - 128).toDouble());
    }
    notifyListeners();
  }

  /// 供演示注入与测试
  void updateDemoData(BrainData data) {
    currentBrainData = data;
    notifyListeners();
  }

  @override
  void dispose() {
    _scanSub?.cancel();
    _dataSub?.cancel();
    _rateTimer?.cancel();
    super.dispose();
  }
}
