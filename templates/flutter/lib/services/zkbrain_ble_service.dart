import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/brain_data.dart';

enum BleConnectionState { disconnected, connecting, connected }

/// ZKBrain BLE communication and protocol dispatch service
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

  /// Request runtime Bluetooth and Location permissions across Android & iOS
  Future<bool> ensureBluetoothPermissions() async {
    if (!kIsWeb && Platform.isAndroid) {
      final statuses = await [
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.locationWhenInUse,
      ].request();

      final bleGranted = (statuses[Permission.bluetoothScan]?.isGranted ?? false) &&
          (statuses[Permission.bluetoothConnect]?.isGranted ?? false);
      final locGranted = statuses[Permission.locationWhenInUse]?.isGranted ?? false;

      if (!bleGranted && !locGranted) {
        lastCommandResponse = "[Permission] Bluetooth or location permission denied. Please grant in settings.";
        notifyListeners();
        return false;
      }
    } else if (!kIsWeb && Platform.isIOS) {
      final status = await Permission.bluetooth.request();
      if (!status.isGranted) {
        lastCommandResponse = "[Permission] Please allow Bluetooth access in iOS Settings.";
        notifyListeners();
        return false;
      }
    }

    final adapterState = await FlutterBluePlus.adapterState.first;
    if (adapterState != BluetoothAdapterState.on) {
      lastCommandResponse = "[Bluetooth Disabled] Please turn on Bluetooth in system settings.";
      notifyListeners();
      return false;
    }
    return true;
  }

  /// Start scanning nearby BLE BCI devices
  Future<void> startScan() async {
    final hasPerm = await ensureBluetoothPermissions();
    if (!hasPerm) return;

    scanResults.clear();
    isScanning = true;
    notifyListeners();

    _scanSub?.cancel();
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
  String lastCommandResponse = "No response received yet.";

  /// Connect to selected BLE device
  Future<void> connect(BluetoothDevice device) async {
    await stopScan();
    connectionState = BleConnectionState.connecting;
    notifyListeners();

    try {
      await device.connect(autoConnect: false);
      connectedDevice = device;
      connectionState = BleConnectionState.connected;
      notifyListeners();

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

  /// Send key-value configuration commands (ASCII protocol)
  Future<void> sendConfigCommand(Map<String, String> config) async {
    for (final entry in config.entries) {
      final cmd = "${entry.key}:${entry.value};\n";
      await sendCommandString(cmd, "Config: ${entry.key}:${entry.value}");
    }
  }

  /// Send 20-byte binary XMW commands (NeuroSky / MindWave series)
  Future<void> sendXmwCommand(int opCode, [String desc = ""]) async {
    final packet = List<int>.filled(20, 0);
    packet[0] = 0x77;
    packet[1] = 0x02;
    packet[2] = opCode & 0xFF;
    int sum = 0;
    for (int i = 1; i <= 18; i++) {
      sum += packet[i];
    }
    packet[19] = (sum ^ 0xFF) & 0xFF;

    await sendCommandBytes(packet, desc.isNotEmpty ? desc : "XMW OpCode 0x${opCode.toRadixString(16).toUpperCase()}");
  }

  /// Write byte stream to peripheral characteristic
  Future<void> sendCommandBytes(List<int> bytes, [String desc = ""]) async {
    if (_writeCharacteristic != null) {
      await _writeCharacteristic!.write(bytes, withoutResponse: false);
      lastCommandResponse = "[TX >>] ${desc.isNotEmpty ? desc : bytes.toString()}";
      notifyListeners();
    } else {
      lastCommandResponse = "[Disconnected] Cannot send: $desc";
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

  void _onDataReceived(List<int> bytes) {
    _rawCount++;
    if (rawWaveBuffer.length >= 300) {
      rawWaveBuffer.removeAt(0);
    }
    if (bytes.isNotEmpty) {
      rawWaveBuffer.add((bytes[0] - 128).toDouble());
    }
    notifyListeners();
  }

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
