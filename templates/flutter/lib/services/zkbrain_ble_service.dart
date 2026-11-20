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
          if (char.properties.notify || char.properties.indicate) {
            await char.setNotifyValue(true);
            _dataSub = char.lastValueStream.listen(_onDataReceived);
            break;
          }
        }
      }
    } catch (e) {
      debugPrint("BLE connection error: $e");
      connectionState = BleConnectionState.disconnected;
      notifyListeners();
    }
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
