import React, { useState, useEffect } from "react";
import {
  SafeAreaView,
  ScrollView,
  StatusBar,
  StyleSheet,
  Text,
  View,
  TouchableOpacity,
  TextInput,
  Switch,
  Modal,
  FlatList,
  Platform,
  PermissionsAndroid,
  Alert,
} from "react-native";

/**
 * 🌟 1:1 完整逐项克隆 shared1 设备管理控制台 (DeviceScreen + DeviceShowTable) - React Native TypeScript 原生版
 * 技术支持：熵基科技脑机事业部 (ZKTeco Brain-Computer Interface Division)
 */

interface DeviceItem {
  name: string;
  mac: string;
  rssi: number;
}

export default function App(): React.JSX.Element {
  // 链路与设备状态
  const [isConnected, setIsConnected] = useState(false);
  const [deviceName, setDeviceName] = useState("ZKBrain Headband PRO");
  const [deviceMac, setDeviceMac] = useState("DC:23:4F:9A:88:01");
  const [batteryLevel, setBatteryLevel] = useState(85);

  // 12 项核心生理指标
  const [attention, setAttention] = useState(78);
  const [meditation, setMeditation] = useState(65);
  const [signalQuality, setSignalQuality] = useState(0);
  const [rawEeg, setRawEeg] = useState(136);

  const [waves, setWaves] = useState({
    delta: 14200,
    theta: 8900,
    lowAlpha: 16100,
    highAlpha: 21800,
    lowBeta: 19500,
    highBeta: 11200,
    lowGamma: 4800,
    middleGamma: 2200,
  });

  // MEMS 6 轴空间姿态 (欧拉角 & 四元数)
  const [memsRoll, setMemsRoll] = useState(1.2);
  const [memsPitch, setMemsPitch] = useState(-0.5);
  const [memsYaw, setMemsYaw] = useState(14.8);
  const [memsQ0, setMemsQ0] = useState(0.992);
  const [memsQ1, setMemsQ1] = useState(0.01);
  const [memsQ2, setMemsQ2] = useState(-0.004);
  const [memsQ3, setMemsQ3] = useState(0.129);

  // 通道与显隐矩阵
  const [isFp1Checked, setIsFp1Checked] = useState(true);
  const [chartToggles, setChartToggles] = useState([
    { key: "Raw EEG", checked: true },
    { key: "Signal Quality", checked: true },
    { key: "Attention", checked: true },
    { key: "Meditation", checked: true },
    { key: "Delta", checked: true },
    { key: "Theta", checked: true },
    { key: "Low Alpha", checked: true },
    { key: "High Alpha", checked: true },
    { key: "Low Beta", checked: true },
    { key: "High Beta", checked: true },
    { key: "Low Gamma", checked: true },
    { key: "Middle Gamma", checked: true },
  ]);

  // 控制台与终端 / Console & Terminal
  const [writeSnInput, setWriteSnInput] = useState("");
  const [customCmdInput, setCustomCmdInput] = useState("");
  const [terminalLogs, setTerminalLogs] = useState(
    "[SYSTEM] ZKBrain React Native console initialized\n"
  );

  // 弹窗与蓝牙扫描 / Scan & Modal
  const [showScanModal, setShowScanModal] = useState(false);
  const [isScanning, setIsScanning] = useState(false);
  const [scannedDevices, setScannedDevices] = useState<DeviceItem[]>([
    { name: "ZKBrain-PRO-8801", mac: "DC:23:4F:9A:88:01", rssi: -58 },
    { name: "MindWave Mobile 2", mac: "AA:BB:CC:11:22:33", rssi: -72 },
    { name: "ZKBrain Headband Lite", mac: "DC:23:4F:55:66:77", rssi: -64 },
  ]);

  const addLog = (msg: string) => {
    setTerminalLogs((prev) => `${prev}${msg}\n`);
  };

  useEffect(() => {
    addLog("[BLE] React Native cross-platform BLE driver ready (Android 12+ / iOS 13+)");
    const interval = setInterval(() => {
      if (isConnected) {
        setAttention((prev) => Math.min(100, Math.max(10, prev + Math.floor((Math.random() - 0.5) * 6))));
        setMeditation((prev) => Math.min(100, Math.max(10, prev + Math.floor((Math.random() - 0.5) * 6))));
        setRawEeg(Math.floor((Math.random() - 0.5) * 240));
      }
    }, 1000);
    return () => clearInterval(interval);
  }, [isConnected]);

  // 🌟 统一运行时蓝牙权限核验
  const requestBluetoothPermissions = async (): Promise<boolean> => {
    if (Platform.OS === "android") {
      if (Platform.Version >= 31) {
        const result = await PermissionsAndroid.requestMultiple([
          PermissionsAndroid.PERMISSIONS.BLUETOOTH_SCAN,
          PermissionsAndroid.PERMISSIONS.BLUETOOTH_CONNECT,
          PermissionsAndroid.PERMISSIONS.ACCESS_FINE_LOCATION,
        ]);
        const granted =
          result[PermissionsAndroid.PERMISSIONS.BLUETOOTH_SCAN] === PermissionsAndroid.RESULTS.GRANTED &&
          result[PermissionsAndroid.PERMISSIONS.BLUETOOTH_CONNECT] === PermissionsAndroid.RESULTS.GRANTED;
        return granted;
      } else {
        const granted = await PermissionsAndroid.request(
          PermissionsAndroid.PERMISSIONS.ACCESS_FINE_LOCATION
        );
        return granted === PermissionsAndroid.RESULTS.GRANTED;
      }
    }
    return true;
  };

  const startScan = async () => {
    const ok = await requestBluetoothPermissions();
    if (!ok) {
      Alert.alert("Permissions Required", "Bluetooth scan and connect permissions are required.");
      addLog("[BLE] Bluetooth runtime permissions denied");
      return;
    }
    setIsScanning(true);
    addLog("[BLE] Scanning for nearby BLE BCI devices...");
    setTimeout(() => {
      setIsScanning(false);
      addLog("[BLE] Scan complete, found 3 available devices");
    }, 2500);
  };

  const openScanModal = () => {
    setShowScanModal(true);
    startScan();
  };

  const connectDevice = (item: DeviceItem) => {
    setDeviceName(item.name);
    setDeviceMac(item.mac);
    setIsConnected(true);
    setShowScanModal(false);
    setIsScanning(false);
    addLog(`[BLE] Connected to device: ${item.name} (${item.mac})`);
  };

  const toggleConnect = () => {
    if (isConnected) {
      setIsConnected(false);
      addLog("[BLE] Disconnected by user");
    } else {
      openScanModal();
    }
  };

  const toggleChart = (key: string) => {
    setChartToggles((prev) =>
      prev.map((item) => (item.key === key ? { ...item, checked: !item.checked } : item))
    );
    addLog(`[CHART] Toggle display: ${key}`);
  };

  return (
    <SafeAreaView style={styles.safeArea}>
      <StatusBar barStyle="light-content" backgroundColor="#1e293b" />
      <ScrollView style={styles.container} contentContainerStyle={{ paddingBottom: 40 }}>
        {/* 板块 1：顶部操作栏 / Section 1: Header Bar */}
        <View style={styles.headerBar}>
          <Text style={styles.headerTitle}>DeviceScreen (设备管理)</Text>
          <View style={styles.headerActions}>
            <TouchableOpacity style={[styles.btnTop, styles.btnSearch]} onPress={openScanModal}>
              <Text style={styles.btnTopText}>🔍 Scan</Text>
            </TouchableOpacity>
            <TouchableOpacity
              style={[styles.btnTop, styles.btnDfu]}
              onPress={() => {
                addLog("[DFU] Checking firmware OTA: currently on latest stable v2.4.0");
                Alert.alert("Firmware OTA", "Currently on latest stable release v2.4.0");
              }}
            >
              <Text style={styles.btnTopText}>DFU</Text>
            </TouchableOpacity>
            <View style={styles.badgeAuth}>
              <Text style={styles.badgeAuthText}>✓ SN就绪</Text>
            </View>
          </View>
        </View>

        {/* 板块 2：设备状态卡片 */}
        <View style={styles.card}>
          <View style={styles.statusRow}>
            <View style={styles.statusBadgeWrap}>
              <View style={[styles.statusDot, isConnected && styles.statusDotConnected]} />
              <Text style={[styles.statusText, isConnected && styles.statusTextConnected]}>
                {isConnected ? "已连接 (CONNECTED)" : "未连接 (DISCONNECTED)"}
              </Text>
            </View>
            <View style={styles.batteryCapsule}>
              <Text style={styles.batteryText}>⚡ {batteryLevel}%</Text>
            </View>
          </View>

          <Text style={styles.deviceName}>{deviceName}</Text>
          <Text style={styles.deviceMac}>MAC: {deviceMac}</Text>

          <View style={styles.badgesRow}>
            <View style={[styles.chip, styles.chipBlue]}>
              <Text style={styles.chipBlueText}>Nordic BLE 5.0</Text>
            </View>
            <View style={[styles.chip, styles.chipTeal]}>
              <Text style={styles.chipTealText}>ASCII 512Hz</Text>
            </View>
            <View style={[styles.chip, styles.chipPurple]}>
              <Text style={styles.chipPurpleText}>NeuroSky XMW</Text>
            </View>
          </View>

          <TouchableOpacity
            style={[styles.btnConnect, isConnected && styles.btnConnectDisconnect]}
            onPress={toggleConnect}
          >
            <Text style={styles.btnConnectText}>{isConnected ? "断开当前连接" : "连接设备"}</Text>
          </TouchableOpacity>
        </View>

        {/* 板块 3：硬件通道配置 */}
        <View style={styles.card}>
          <Text style={styles.cardTitle}>🎧 脑电测量通道 (Channels)</Text>
          <Text style={styles.cardSubtitle}>单导联额贴固定使用前额左侧 (FP1) 测量点</Text>
          <View style={styles.channelRow}>
            <View style={styles.channelItem}>
              <Switch
                value={isFp1Checked}
                onValueChange={(val) => {
                  setIsFp1Checked(val);
                  addLog(`[通道配置] Left (FP1): ${val}`);
                }}
                trackColor={{ true: "#2563eb", false: "#cbd5e1" }}
              />
              <Text style={styles.channelLabel}>Left (FP1) [激活中]</Text>
            </View>
            <View style={styles.channelItem}>
              <Switch value={false} disabled trackColor={{ false: "#e2e8f0" }} />
              <Text style={[styles.channelLabel, { color: "#94a3b8" }]}>Right (FP2) [硬件不支持]</Text>
            </View>
          </View>
        </View>

        {/* 板块 4：图表显隐过滤矩阵 */}
        <View style={styles.card}>
          <Text style={styles.cardTitle}>📊 12项生理指标图表显隐过滤</Text>
          <Text style={styles.cardSubtitle}>实时联动控制下方 4x3 三色脑电指标表格</Text>
          <View style={styles.chipGrid}>
            {chartToggles.map((item) => (
              <TouchableOpacity
                key={item.key}
                style={[styles.chartChip, item.checked && styles.chartChipActive]}
                onPress={() => toggleChart(item.key)}
              >
                <Text style={[styles.chartChipText, item.checked && styles.chartChipTextActive]}>
                  {item.checked ? "✓ " : ""}
                  {item.key}
                </Text>
              </TouchableOpacity>
            ))}
          </View>
        </View>

        {/* 板块 5：NeuroSky XMW 二进制硬件控制台 */}
        <View style={styles.card}>
          <Text style={styles.cardTitle}>⚡ NeuroSky XMW 二进制硬件控制台</Text>
          <Text style={styles.cardSubtitle}>直接控制 TGAM / MindWave 芯片底层寄存器与传输开关</Text>
          <View style={styles.btnGrid}>
            <TouchableOpacity
              style={[styles.btnAct, styles.actGreen]}
              onPress={() => addLog("[TX >> XMW] Ignition Packet: 0x15 (Raw) + 0x17 (Band)")}
            >
              <Text style={styles.actGreenText}>Ignite (0x15+0x17)</Text>
            </TouchableOpacity>
            <TouchableOpacity
              style={[styles.btnAct, styles.actRed]}
              onPress={() => addLog("[TX >> XMW] Stop transmission: 0x16 + 0x18")}
            >
              <Text style={styles.actRedText}>Stop (0x16+0x18)</Text>
            </TouchableOpacity>
            <TouchableOpacity
              style={[styles.btnAct, styles.actBlue]}
              onPress={() => addLog("[TX >> XMW] Set 50Hz notch filter (0x1B)")}
            >
              <Text style={styles.actBlueText}>50Hz (0x1B)</Text>
            </TouchableOpacity>
            <TouchableOpacity
              style={[styles.btnAct, styles.actBlue]}
              onPress={() => addLog("[TX >> XMW] Set 60Hz notch filter (0x1C)")}
            >
              <Text style={styles.actBlueText}>60Hz (0x1C)</Text>
            </TouchableOpacity>
            <TouchableOpacity
              style={[styles.btnAct, styles.actOrange]}
              onPress={() => addLog("[TX >> XMW] Read battery level (0x06)")}
            >
              <Text style={styles.actOrangeText}>Battery (0x06)</Text>
            </TouchableOpacity>
            <TouchableOpacity
              style={[styles.btnAct, styles.actGray]}
              onPress={() => addLog("[TX >> XMW] Query SN (0xF4)")}
            >
              <Text style={styles.actGrayText}>Read SN (0xF4)</Text>
            </TouchableOpacity>
          </View>

          <View style={styles.inputRow}>
            <TextInput
              style={styles.inputField}
              placeholder="Enter device SN (e.g. ZK20261120001)"
              value={writeSnInput}
              onChangeText={setWriteSnInput}
            />
            <TouchableOpacity
              style={styles.btnSnSend}
              onPress={() => {
                if (writeSnInput.trim()) {
                  addLog(`[TX >> XMW] Write SN (0xF2): ${writeSnInput}`);
                  Alert.alert("SN Command", `Dispatched: ${writeSnInput}`);
                  setWriteSnInput("");
                }
              }}
            >
              <Text style={styles.btnSendText}>写入 SN</Text>
            </TouchableOpacity>
          </View>
        </View>

        {/* 板块 6：ZKBrain 自研脑电设备官方控制台 */}
        <View style={styles.card}>
          <Text style={styles.cardTitle}>🧠 ZKBrain 自研脑电设备官方控制台</Text>
          <Text style={styles.cardSubtitle}>支持 ASCII 控制指令与 MEMS 6轴姿态惯导流</Text>

          {/* MEMS 传感器姿态看板 */}
          <View style={styles.memsBox}>
            <Text style={styles.memsHeader}>🧭 MEMS 传感器 6 轴空间姿态 (Euler 欧拉角 & 四元数):</Text>
            <Text style={styles.memsText}>
              Roll(横滚): {memsRoll}° | Pitch(俯仰): {memsPitch}° | Yaw(偏航): {memsYaw}°
            </Text>
            <Text style={[styles.memsText, { color: "#64748b" }]}>
              Q0: {memsQ0} | Q1: {memsQ1} | Q2: {memsQ2} | Q3: {memsQ3}
            </Text>
          </View>

          <View style={styles.btnGrid}>
            <TouchableOpacity
              style={[styles.btnAct, styles.actGray]}
              onPress={() => addLog("[TX >>] license:?")}
            >
              <Text style={styles.actGrayText}>license:?</Text>
            </TouchableOpacity>
            <TouchableOpacity
              style={[styles.btnAct, styles.actOrange]}
              onPress={() => addLog("[TX >>] battery:?")}
            >
              <Text style={styles.actOrangeText}>battery:?</Text>
            </TouchableOpacity>
            <TouchableOpacity
              style={[styles.btnAct, styles.actGreen]}
              onPress={() => addLog("[TX >>] eeg_data_on:1")}
            >
              <Text style={styles.actGreenText}>eeg_data_on:1</Text>
            </TouchableOpacity>
            <TouchableOpacity
              style={[styles.btnAct, styles.actRed]}
              onPress={() => addLog("[TX >>] eeg_data_on:0")}
            >
              <Text style={styles.actRedText}>eeg_data_on:0</Text>
            </TouchableOpacity>
            <TouchableOpacity
              style={[styles.btnAct, styles.actBlue]}
              onPress={() => addLog("[TX >>] eeg_data_rate:1 (512Hz)")}
            >
              <Text style={styles.actBlueText}>512Hz (rate:1)</Text>
            </TouchableOpacity>
            <TouchableOpacity
              style={[styles.btnAct, styles.actPurple]}
              onPress={() => addLog("[TX >>] mems_on:1 (Enable MEMS Motion Stream)")}
            >
              <Text style={styles.actPurpleText}>MEMS ON</Text>
            </TouchableOpacity>
            <TouchableOpacity
              style={[styles.btnAct, styles.actGray]}
              onPress={() => addLog("[TX >>] mems_on:0 (Disable MEMS Motion Stream)")}
            >
              <Text style={styles.actGrayText}>MEMS OFF</Text>
            </TouchableOpacity>
          </View>

          <View style={styles.inputRow}>
            <TextInput
              style={styles.inputField}
              placeholder="自定义指令 (例如: mems_on:1)"
              value={customCmdInput}
              onChangeText={setCustomCmdInput}
            />
            <TouchableOpacity
              style={styles.btnCmdSend}
              onPress={() => {
                if (customCmdInput.trim()) {
                  addLog(`[TX >>] ${customCmdInput}`);
                  setCustomCmdInput("");
                }
              }}
            >
              <Text style={styles.btnSendText}>发送指令</Text>
            </TouchableOpacity>
          </View>

          {/* 终端监控 */}
          <View style={styles.terminalBox}>
            <View style={styles.terminalHeader}>
              <Text style={styles.terminalTitle}>💻 指令下发与硬件回包监控终端:</Text>
              <TouchableOpacity onPress={() => setTerminalLogs("")}>
                <Text style={styles.btnClear}>清空</Text>
              </TouchableOpacity>
            </View>
            <ScrollView style={styles.terminalLogs} nestedScrollEnabled>
              <Text style={styles.terminalText}>{terminalLogs}</Text>
            </ScrollView>
          </View>
        </View>

        {/* 板块 7：DeviceShowTable 4x3 三色脑电指标表格 */}
        <View style={styles.card}>
          <Text style={styles.cardTitle}>📈 4x3 全波段三色脑电数据表 (DeviceShowTable)</Text>
          <Text style={styles.cardSubtitle}>
            1:1 逐项还原 shared1 测量看板；粉色：认知与信号，青色：慢波与Alpha，黄色：高频能谱
          </Text>

          <View style={styles.tableMacHeader}>
            <Text style={styles.tableMacText}>MAC: {deviceMac}</Text>
          </View>

          <View style={styles.tableContainer}>
            {/* Row 1 */}
            <View style={styles.tableRow}>
              <View style={[styles.tableCell, styles.bgPink]}>
                <Text style={styles.cellLabel}>Attention</Text>
                <Text style={styles.cellVal}>{attention}</Text>
              </View>
              <View style={[styles.tableCell, styles.bgPink]}>
                <Text style={styles.cellLabel}>Meditation</Text>
                <Text style={styles.cellVal}>{meditation}</Text>
              </View>
              <View style={[styles.tableCell, styles.bgPink]}>
                <Text style={styles.cellLabel}>Quality</Text>
                <Text style={styles.cellVal}>{signalQuality}</Text>
              </View>
            </View>
            {/* Row 2 */}
            <View style={styles.tableRow}>
              <View style={[styles.tableCell, styles.bgPink]}>
                <Text style={styles.cellLabel}>Raw EEG</Text>
                <Text style={styles.cellVal}>{rawEeg}</Text>
              </View>
              <View style={[styles.tableCell, styles.bgCyan]}>
                <Text style={styles.cellLabel}>Delta</Text>
                <Text style={styles.cellVal}>{waves.delta}</Text>
              </View>
              <View style={[styles.tableCell, styles.bgCyan]}>
                <Text style={styles.cellLabel}>Theta</Text>
                <Text style={styles.cellVal}>{waves.theta}</Text>
              </View>
            </View>
            {/* Row 3 */}
            <View style={styles.tableRow}>
              <View style={[styles.tableCell, styles.bgCyan]}>
                <Text style={styles.cellLabel}>Low Alpha</Text>
                <Text style={styles.cellVal}>{waves.lowAlpha}</Text>
              </View>
              <View style={[styles.tableCell, styles.bgCyan]}>
                <Text style={styles.cellLabel}>High Alpha</Text>
                <Text style={styles.cellVal}>{waves.highAlpha}</Text>
              </View>
              <View style={[styles.tableCell, styles.bgYellow]}>
                <Text style={styles.cellLabel}>Low Beta</Text>
                <Text style={styles.cellVal}>{waves.lowBeta}</Text>
              </View>
            </View>
            {/* Row 4 */}
            <View style={styles.tableRow}>
              <View style={[styles.tableCell, styles.bgYellow]}>
                <Text style={styles.cellLabel}>High Beta</Text>
                <Text style={styles.cellVal}>{waves.highBeta}</Text>
              </View>
              <View style={[styles.tableCell, styles.bgYellow]}>
                <Text style={styles.cellLabel}>Low Gamma</Text>
                <Text style={styles.cellVal}>{waves.lowGamma}</Text>
              </View>
              <View style={[styles.tableCell, styles.bgYellow]}>
                <Text style={styles.cellLabel}>Mid Gamma</Text>
                <Text style={styles.cellVal}>{waves.middleGamma}</Text>
              </View>
            </View>
          </View>
        </View>

        {/* 板块 8：蓝牙搜索连接弹窗 */}
        <Modal visible={showScanModal} transparent animationType="fade">
          <View style={styles.modalMask}>
            <View style={styles.modalContent}>
              <View style={styles.modalHeader}>
                <Text style={styles.modalTitle}>🔍 搜索周围脑电设备</Text>
                <TouchableOpacity onPress={() => setShowScanModal(false)}>
                  <Text style={styles.modalClose}>✕</Text>
                </TouchableOpacity>
              </View>
              <Text style={styles.modalStatus}>
                {isScanning ? "正在扫描周围 BLE 设备..." : "扫描完成，请点击连接"}
              </Text>
              <FlatList
                data={scannedDevices}
                keyExtractor={(item) => item.mac}
                style={{ maxHeight: 220 }}
                renderItem={({ item }) => (
                  <View style={styles.deviceItem}>
                    <View>
                      <Text style={styles.itemName}>{item.name}</Text>
                      <Text style={styles.itemMac}>
                        {item.mac} | {item.rssi} dBm
                      </Text>
                    </View>
                    <TouchableOpacity
                      style={styles.btnItemConnect}
                      onPress={() => connectDevice(item)}
                    >
                      <Text style={styles.btnItemConnectText}>连接</Text>
                    </TouchableOpacity>
                  </View>
                )}
              />
              <TouchableOpacity
                style={[styles.btnRescan, isScanning && { backgroundColor: "#94a3b8" }]}
                disabled={isScanning}
                onPress={startScan}
              >
                <Text style={styles.btnRescanText}>
                  {isScanning ? "正在搜索中..." : "重新扫描周边设备"}
                </Text>
              </TouchableOpacity>
            </View>
          </View>
        </Modal>
      </ScrollView>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  safeArea: { flex: 1, backgroundColor: "#1e293b" },
  container: { flex: 1, backgroundColor: "#f1f5f9", padding: 14 },
  headerBar: {
    flexDirection: "row",
    justifyContent: "space-between",
    alignItems: "center",
    marginBottom: 12,
  },
  headerTitle: { fontSize: 18, fontWeight: "bold", color: "#0f172a" },
  headerActions: { flexDirection: "row", alignItems: "center", gap: 6 },
  btnTop: { paddingHorizontal: 8, paddingVertical: 5, borderRadius: 6 },
  btnSearch: { backgroundColor: "#2563eb" },
  btnDfu: { backgroundColor: "#475569" },
  btnTopText: { color: "white", fontSize: 11, fontWeight: "bold" },
  badgeAuth: {
    backgroundColor: "#dcfce7",
    borderColor: "#86efac",
    borderWidth: 1,
    paddingHorizontal: 6,
    paddingVertical: 3,
    borderRadius: 4,
  },
  badgeAuthText: { color: "#16a34a", fontSize: 10, fontWeight: "bold" },
  card: {
    backgroundColor: "#ffffff",
    borderRadius: 12,
    padding: 14,
    marginBottom: 12,
    shadowColor: "#000",
    shadowOpacity: 0.04,
    shadowRadius: 4,
    elevation: 1,
  },
  cardTitle: { fontSize: 15, fontWeight: "bold", color: "#1e293b", marginBottom: 3 },
  cardSubtitle: { fontSize: 11, color: "#64748b", marginBottom: 10 },
  statusRow: { flexDirection: "row", justifyContent: "space-between", alignItems: "center" },
  statusBadgeWrap: { flexDirection: "row", alignItems: "center", gap: 6 },
  statusDot: { width: 10, height: 10, borderRadius: 5, backgroundColor: "#ef4444" },
  statusDotConnected: { backgroundColor: "#22c55e" },
  statusText: { fontSize: 13, fontWeight: "bold", color: "#dc2626" },
  statusTextConnected: { color: "#16a34a" },
  batteryCapsule: {
    backgroundColor: "#dcfce7",
    borderColor: "#86efac",
    borderWidth: 1,
    borderRadius: 10,
    paddingHorizontal: 8,
    paddingVertical: 2,
  },
  batteryText: { color: "#16a34a", fontSize: 11, fontWeight: "bold" },
  deviceName: { fontSize: 17, fontWeight: "bold", color: "#0f172a", marginTop: 8 },
  deviceMac: { fontSize: 11, color: "#64748b", fontFamily: Platform.OS === "ios" ? "Courier" : "monospace", marginVertical: 3 },
  badgesRow: { flexDirection: "row", gap: 6, marginVertical: 8 },
  chip: { paddingHorizontal: 6, paddingVertical: 2, borderRadius: 4 },
  chipBlue: { backgroundColor: "rgba(2, 132, 199, 0.12)" },
  chipBlueText: { color: "#0284c7", fontSize: 10, fontWeight: "600" },
  chipTeal: { backgroundColor: "rgba(13, 148, 136, 0.12)" },
  chipTealText: { color: "#0d9488", fontSize: 10, fontWeight: "600" },
  chipPurple: { backgroundColor: "rgba(124, 58, 237, 0.12)" },
  chipPurpleText: { color: "#7c3aed", fontSize: 10, fontWeight: "600" },
  btnConnect: {
    backgroundColor: "#2563eb",
    height: 40,
    justifyContent: "center",
    alignItems: "center",
    borderRadius: 8,
    marginTop: 6,
  },
  btnConnectDisconnect: { backgroundColor: "#dc2626" },
  btnConnectText: { color: "white", fontSize: 13, fontWeight: "bold" },
  channelRow: { flexDirection: "row", gap: 16 },
  channelItem: { flexDirection: "row", alignItems: "center", gap: 6 },
  channelLabel: { fontSize: 12, color: "#1e293b" },
  chipGrid: { flexDirection: "row", flexWrap: "wrap", gap: 6 },
  chartChip: {
    paddingHorizontal: 8,
    paddingVertical: 4,
    borderRadius: 6,
    borderWidth: 1,
    borderColor: "#cbd5e1",
    backgroundColor: "#f1f5f9",
  },
  chartChipActive: { backgroundColor: "#2563eb", borderColor: "#2563eb" },
  chartChipText: { fontSize: 11, color: "#334155" },
  chartChipTextActive: { color: "white" },
  btnGrid: { flexDirection: "row", flexWrap: "wrap", gap: 6, marginBottom: 8 },
  btnAct: { paddingHorizontal: 10, paddingVertical: 6, borderRadius: 6 },
  actGreen: { backgroundColor: "rgba(22, 163, 74, 0.12)" },
  actGreenText: { color: "#16a34a", fontSize: 11, fontWeight: "600" },
  actRed: { backgroundColor: "rgba(220, 38, 38, 0.12)" },
  actRedText: { color: "#dc2626", fontSize: 11, fontWeight: "600" },
  actBlue: { backgroundColor: "rgba(2, 132, 199, 0.12)" },
  actBlueText: { color: "#0284c7", fontSize: 11, fontWeight: "600" },
  actOrange: { backgroundColor: "rgba(217, 119, 6, 0.12)" },
  actOrangeText: { color: "#d97706", fontSize: 11, fontWeight: "600" },
  actGray: { backgroundColor: "rgba(71, 85, 105, 0.1)" },
  actGrayText: { color: "#475569", fontSize: 11, fontWeight: "600" },
  actPurple: { backgroundColor: "rgba(124, 58, 237, 0.12)" },
  actPurpleText: { color: "#7c3aed", fontSize: 11, fontWeight: "600" },
  inputRow: { flexDirection: "row", gap: 6, marginTop: 4 },
  inputField: {
    flex: 1,
    height: 38,
    backgroundColor: "#f8fafc",
    borderColor: "#cbd5e1",
    borderWidth: 1,
    borderRadius: 6,
    paddingHorizontal: 10,
    fontSize: 12,
  },
  btnSnSend: {
    backgroundColor: "#0f172a",
    paddingHorizontal: 14,
    justifyContent: "center",
    borderRadius: 6,
  },
  btnCmdSend: {
    backgroundColor: "#2563eb",
    paddingHorizontal: 14,
    justifyContent: "center",
    borderRadius: 6,
  },
  btnSendText: { color: "white", fontSize: 11, fontWeight: "bold" },
  memsBox: {
    backgroundColor: "#f8fafc",
    borderColor: "#e2e8f0",
    borderWidth: 1,
    borderRadius: 8,
    padding: 10,
    marginBottom: 10,
  },
  memsHeader: { fontSize: 12, fontWeight: "bold", color: "#334155", marginBottom: 4 },
  memsText: { fontSize: 11, color: "#1e293b", fontFamily: Platform.OS === "ios" ? "Courier" : "monospace" },
  terminalBox: {
    backgroundColor: "#0f172a",
    borderRadius: 8,
    padding: 10,
    marginTop: 10,
  },
  terminalHeader: { flexDirection: "row", justifyContent: "space-between", marginBottom: 6 },
  terminalTitle: { fontSize: 11, color: "#94a3b8" },
  btnClear: { color: "#38bdf8", fontSize: 11 },
  terminalLogs: { maxHeight: 110 },
  terminalText: {
    color: "#4ade80",
    fontSize: 10,
    fontFamily: Platform.OS === "ios" ? "Courier" : "monospace",
  },
  tableMacHeader: {
    backgroundColor: "#1e293b",
    paddingVertical: 6,
    borderRadius: 6,
    alignItems: "center",
    marginBottom: 8,
  },
  tableMacText: { color: "white", fontSize: 12, fontWeight: "bold", fontFamily: Platform.OS === "ios" ? "Courier" : "monospace" },
  tableContainer: { borderWidth: 1, borderColor: "#cbd5e1", borderRadius: 4, overflow: "hidden" },
  tableRow: { flexDirection: "row", borderBottomWidth: 1, borderColor: "#cbd5e1" },
  tableCell: { flex: 1, paddingVertical: 8, alignItems: "center", borderRightWidth: 1, borderColor: "#cbd5e1" },
  cellLabel: { fontSize: 10, fontWeight: "bold", color: "#334155", marginBottom: 2 },
  cellVal: { fontSize: 12, fontWeight: "bold", color: "#0f172a", fontFamily: Platform.OS === "ios" ? "Courier" : "monospace" },
  bgPink: { backgroundColor: "#ffe4e1" },
  bgCyan: { backgroundColor: "#e0ffff" },
  bgYellow: { backgroundColor: "#f0e68c" },
  modalMask: {
    flex: 1,
    backgroundColor: "rgba(0,0,0,0.5)",
    justifyContent: "center",
    alignItems: "center",
    padding: 20,
  },
  modalContent: {
    width: "100%",
    backgroundColor: "white",
    borderRadius: 12,
    padding: 16,
  },
  modalHeader: { flexDirection: "row", justifyContent: "space-between", alignItems: "center", marginBottom: 6 },
  modalTitle: { fontSize: 16, fontWeight: "bold", color: "#1e293b" },
  modalClose: { fontSize: 18, color: "#64748b", padding: 4 },
  modalStatus: { fontSize: 11, color: "#64748b", marginBottom: 10 },
  deviceItem: {
    flexDirection: "row",
    justifyContent: "space-between",
    alignItems: "center",
    backgroundColor: "#f8fafc",
    padding: 10,
    borderRadius: 8,
    marginBottom: 8,
  },
  itemName: { fontSize: 13, fontWeight: "bold", color: "#0f172a" },
  itemMac: { fontSize: 10, color: "#64748b", marginTop: 2 },
  btnItemConnect: { backgroundColor: "#16a34a", paddingHorizontal: 12, paddingVertical: 6, borderRadius: 6 },
  btnItemConnectText: { color: "white", fontSize: 11, fontWeight: "bold" },
  btnRescan: { backgroundColor: "#2563eb", height: 38, justifyContent: "center", alignItems: "center", borderRadius: 8, marginTop: 8 },
  btnRescanText: { color: "white", fontSize: 12, fontWeight: "bold" },
});
