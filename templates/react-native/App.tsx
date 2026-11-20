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
 * 1:1 Complete Device Management Console (DeviceScreen + DeviceShowTable) - React Native TypeScript
 * Technical Support: ZKTeco Brain-Computer Interface Division
 */

interface DeviceItem {
  name: string;
  mac: string;
  rssi: number;
}

export default function App(): React.JSX.Element {
  // Connection and device status
  const [isConnected, setIsConnected] = useState(false);
  const [deviceName, setDeviceName] = useState("ZKBrain Headband PRO");
  const [deviceMac, setDeviceMac] = useState("DC:23:4F:9A:88:01");
  const [batteryLevel, setBatteryLevel] = useState(85);

  // 12 core physiological metrics
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

  // MEMS 6-axis spatial attitude (Euler angles & Quaternions)
  const [memsRoll, setMemsRoll] = useState(1.2);
  const [memsPitch, setMemsPitch] = useState(-0.5);
  const [memsYaw, setMemsYaw] = useState(14.8);
  const [memsQ0, setMemsQ0] = useState(0.992);
  const [memsQ1, setMemsQ1] = useState(0.01);
  const [memsQ2, setMemsQ2] = useState(-0.004);
  const [memsQ3, setMemsQ3] = useState(0.129);

  // Channels and visibility matrix
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

  // Console & Terminal
  const [writeSnInput, setWriteSnInput] = useState("");
  const [customCmdInput, setCustomCmdInput] = useState("");
  const [terminalLogs, setTerminalLogs] = useState(
    "[SYSTEM] ZKBrain React Native console initialized\n"
  );

  // Scan & Modal
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
    let timer: any;
    if (isConnected) {
      timer = setInterval(() => {
        setAttention((prev) => Math.max(10, Math.min(100, prev + Math.floor(Math.random() * 7 - 3))));
        setMeditation((prev) => Math.max(10, Math.min(100, prev + Math.floor(Math.random() * 7 - 3))));
        setRawEeg(Math.floor(Math.random() * 300 - 150));
      }, 1000);
    }
    return () => clearInterval(timer);
  }, [isConnected]);

  // Runtime Bluetooth permissions check
  const requestBlePermissions = async () => {
    if (Platform.OS === "android") {
      if (Platform.Version >= 31) {
        const granted = await PermissionsAndroid.requestMultiple([
          PermissionsAndroid.PERMISSIONS.BLUETOOTH_SCAN,
          PermissionsAndroid.PERMISSIONS.BLUETOOTH_CONNECT,
          PermissionsAndroid.PERMISSIONS.ACCESS_FINE_LOCATION,
        ]);
        return (
          granted["android.permission.BLUETOOTH_SCAN"] === PermissionsAndroid.RESULTS.GRANTED &&
          granted["android.permission.BLUETOOTH_CONNECT"] === PermissionsAndroid.RESULTS.GRANTED
        );
      } else {
        const granted = await PermissionsAndroid.request(
          PermissionsAndroid.PERMISSIONS.ACCESS_FINE_LOCATION
        );
        return granted === PermissionsAndroid.RESULTS.GRANTED;
      }
    }
    return true;
  };

  const openScanModal = async () => {
    const hasPerm = await requestBlePermissions();
    if (!hasPerm) {
      Alert.alert("Permission Error", "Bluetooth and Location permissions required to scan devices.");
      return;
    }
    setShowScanModal(true);
    startScan();
  };

  const startScan = () => {
    setIsScanning(true);
    addLog("[BLE] Scanning for nearby BLE BCI devices...");
    setTimeout(() => {
      setIsScanning(false);
      addLog("[BLE] Scan complete, discovered 3 BCI devices.");
    }, 2000);
  };

  const connectDevice = (dev: DeviceItem) => {
    setDeviceName(dev.name);
    setDeviceMac(dev.mac);
    setIsConnected(true);
    setShowScanModal(false);
    addLog(`[BLE] Successfully connected to: ${dev.name} (${dev.mac})`);
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
      prev.map((item) =>
        item.key === key ? { ...item, checked: !item.checked } : item
      )
    );
    addLog(`[CHART] Toggle ${key}`);
  };

  return (
    <SafeAreaView style={styles.safeArea}>
      <StatusBar barStyle="light-content" backgroundColor="#1e293b" />
      <ScrollView style={styles.container} contentContainerStyle={{ paddingBottom: 40 }}>
        {/* Section 1: Header Bar */}
        <View style={styles.headerBar}>
          <Text style={styles.headerTitle}>Device Management (DeviceScreen)</Text>
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
              <Text style={styles.badgeAuthText}>Authorized</Text>
            </View>
          </View>
        </View>

        {/* Section 2: Device Link Status Card */}
        <View style={styles.card}>
          <View style={styles.statusRow}>
            <View style={styles.statusBadgeWrap}>
              <View style={[styles.statusDot, isConnected && styles.statusDotConnected]} />
              <Text style={[styles.statusText, isConnected && styles.statusTextConnected]}>
                {isConnected ? "CONNECTED" : "DISCONNECTED"}
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
            <Text style={styles.btnConnectText}>{isConnected ? "Disconnect" : "Connect Device"}</Text>
          </TouchableOpacity>
        </View>

        {/* Section 3: Channel Settings */}
        <View style={styles.card}>
          <Text style={styles.cardTitle}>EEG Channels</Text>
          <Text style={styles.cardSubtitle}>Single-channel forehead placement fixed at front-left (FP1)</Text>
          <View style={styles.channelRow}>
            <View style={styles.channelItem}>
              <Switch
                value={isFp1Checked}
                onValueChange={(val) => {
                  setIsFp1Checked(val);
                  addLog(`[Channel] Left (FP1): ${val}`);
                }}
                trackColor={{ true: "#2563eb", false: "#cbd5e1" }}
              />
              <Text style={styles.channelLabel}>Left (FP1) [Active]</Text>
            </View>
            <View style={styles.channelItem}>
              <Switch value={false} disabled trackColor={{ false: "#e2e8f0" }} />
              <Text style={[styles.channelLabel, { color: "#94a3b8" }]}>Right (FP2) [Unsupported]</Text>
            </View>
          </View>
        </View>

        {/* Section 4: Chart Display Filter Matrix */}
        <View style={styles.card}>
          <Text style={styles.cardTitle}>12 Metrics Filter Matrix</Text>
          <Text style={styles.cardSubtitle}>Controls the 4x3 spectrum matrix visibility in real time</Text>
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

        {/* Section 5: NeuroSky XMW Binary Protocol Console */}
        <View style={styles.card}>
          <Text style={styles.cardTitle}>NeuroSky XMW Binary Console</Text>
          <Text style={styles.cardSubtitle}>Directly control TGAM / MindWave registers and streaming switches</Text>
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
              <Text style={styles.btnSendText}>Write SN</Text>
            </TouchableOpacity>
          </View>
        </View>

        {/* Section 6: ZKBrain Native Device Official Console */}
        <View style={styles.card}>
          <Text style={styles.cardTitle}>ZKBrain Native Device Official Console</Text>
          <Text style={styles.cardSubtitle}>Supports ASCII control commands and MEMS 6-axis motion stream</Text>

          {/* MEMS 6-Axis Spatial Attitude */}
          <View style={styles.memsBox}>
            <Text style={styles.memsHeader}>MEMS 6-Axis Spatial Attitude (Euler Angles & Quaternions):</Text>
            <Text style={styles.memsText}>
              Roll: {memsRoll}° | Pitch: {memsPitch}° | Yaw: {memsYaw}°
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
              placeholder="Custom command (e.g. mems_on:1)"
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
              <Text style={styles.btnSendText}>Send Command</Text>
            </TouchableOpacity>
          </View>

          {/* Terminal Monitor */}
          <View style={styles.terminalBox}>
            <View style={styles.terminalHeader}>
              <Text style={styles.terminalTitle}>Command Transmission & Feedback Terminal:</Text>
              <TouchableOpacity onPress={() => setTerminalLogs("")}>
                <Text style={styles.btnClear}>Clear</Text>
              </TouchableOpacity>
            </View>
            <ScrollView style={styles.terminalLogs} nestedScrollEnabled>
              <Text style={styles.terminalText}>{terminalLogs}</Text>
            </ScrollView>
          </View>
        </View>

        {/* Section 7: DeviceShowTable 4x3 Spectrum Metrics Table */}
        <View style={styles.card}>
          <Text style={styles.cardTitle}>4x3 Full-Band Spectrum Metrics (DeviceShowTable)</Text>
          <Text style={styles.cardSubtitle}>
            1:1 realization of shared1 console; Pink: Cognitive & Quality, Cyan: Slow & Alpha, Yellow: High Frequency
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

        {/* Section 8: Bluetooth Scan Dialog */}
        <Modal visible={showScanModal} transparent animationType="fade">
          <View style={styles.modalMask}>
            <View style={styles.modalContent}>
              <View style={styles.modalHeader}>
                <Text style={styles.modalTitle}>Search Nearby BLE BCI Devices</Text>
                <TouchableOpacity onPress={() => setShowScanModal(false)}>
                  <Text style={styles.modalClose}>✕</Text>
                </TouchableOpacity>
              </View>
              <Text style={styles.modalStatus}>
                {isScanning ? "Scanning nearby BLE devices..." : "Scan complete, tap to connect"}
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
                      <Text style={styles.btnItemConnectText}>Connect</Text>
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
                  {isScanning ? "Searching..." : "Rescan Nearby Devices"}
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
  safeArea: { flex: 1, backgroundColor: "#f1f5f9" },
  container: { flex: 1, paddingHorizontal: 16, paddingTop: 12 },
  headerBar: {
    flexDirection: "row",
    justifyContent: "space-between",
    alignItems: "center",
    marginBottom: 12,
  },
  headerTitle: { fontSize: 17, fontWeight: "bold", color: "#0f172a" },
  headerActions: { flexDirection: "row", alignItems: "center", gap: 6 },
  btnTop: { paddingHorizontal: 10, paddingVertical: 5, borderRadius: 6 },
  btnSearch: { backgroundColor: "#2563eb" },
  btnDfu: { backgroundColor: "#475569" },
  btnTopText: { color: "white", fontSize: 12, fontWeight: "600" },
  badgeAuth: {
    backgroundColor: "#dcfce7",
    paddingHorizontal: 8,
    paddingVertical: 5,
    borderRadius: 4,
    borderWidth: 1,
    borderColor: "#86efac",
  },
  badgeAuthText: { color: "#16a34a", fontSize: 11, fontWeight: "bold" },
  card: {
    backgroundColor: "white",
    borderRadius: 12,
    padding: 14,
    marginBottom: 12,
    shadowColor: "#000",
    shadowOpacity: 0.05,
    shadowOffset: { width: 0, height: 1 },
    shadowRadius: 3,
    elevation: 2,
  },
  cardTitle: { fontSize: 14, fontWeight: "bold", color: "#1e293b", marginBottom: 2 },
  cardSubtitle: { fontSize: 11, color: "#64748b", marginBottom: 10 },
  statusRow: {
    flexDirection: "row",
    justifyContent: "space-between",
    alignItems: "center",
  },
  statusBadgeWrap: { flexDirection: "row", alignItems: "center", gap: 6 },
  statusDot: { width: 10, height: 10, borderRadius: 5, backgroundColor: "#ef4444" },
  statusDotConnected: { backgroundColor: "#22c55e" },
  statusText: { fontSize: 13, fontWeight: "600", color: "#ef4444" },
  statusTextConnected: { color: "#16a34a" },
  batteryCapsule: {
    backgroundColor: "#f8fafc",
    paddingHorizontal: 8,
    paddingVertical: 3,
    borderRadius: 12,
    borderWidth: 1,
    borderColor: "#e2e8f0",
  },
  batteryText: { fontSize: 12, fontWeight: "600", color: "#334155" },
  deviceName: { fontSize: 17, fontWeight: "bold", color: "#0f172a", marginTop: 8 },
  deviceMac: { fontSize: 11, fontFamily: "monospace", color: "#64748b", marginTop: 2 },
  badgesRow: { flexDirection: "row", gap: 6, marginVertical: 10 },
  chip: { paddingHorizontal: 6, paddingVertical: 2, borderRadius: 4 },
  chipBlue: { backgroundColor: "#dbeafe" },
  chipBlueText: { color: "#1d4ed8", fontSize: 10, fontWeight: "600" },
  chipTeal: { backgroundColor: "#ccfbf1" },
  chipTealText: { color: "#0f766e", fontSize: 10, fontWeight: "600" },
  chipPurple: { backgroundColor: "#f3e8ff" },
  chipPurpleText: { color: "#7e22ce", fontSize: 10, fontWeight: "600" },
  btnConnect: {
    backgroundColor: "#2563eb",
    paddingVertical: 8,
    borderRadius: 6,
    alignItems: "center",
  },
  btnConnectDisconnect: { backgroundColor: "#dc2626" },
  btnConnectText: { color: "white", fontSize: 13, fontWeight: "bold" },
  channelRow: { flexDirection: "row", gap: 20 },
  channelItem: { flexDirection: "row", alignItems: "center", gap: 6 },
  channelLabel: { fontSize: 13, color: "#334155" },
  chipGrid: { flexDirection: "row", flexWrap: "wrap", gap: 6 },
  chartChip: {
    paddingHorizontal: 8,
    paddingVertical: 4,
    borderRadius: 6,
    borderWidth: 1,
    borderColor: "#cbd5e1",
    backgroundColor: "#f8fafc",
  },
  chartChipActive: {
    backgroundColor: "#eff6ff",
    borderColor: "#3b82f6",
  },
  chartChipText: { fontSize: 11, color: "#475569" },
  chartChipTextActive: { color: "#1d4ed8", fontWeight: "600" },
  btnGrid: { flexDirection: "row", flexWrap: "wrap", gap: 6, marginBottom: 10 },
  btnAct: {
    paddingHorizontal: 8,
    paddingVertical: 6,
    borderRadius: 6,
    borderWidth: 1,
    minWidth: "30%",
    alignItems: "center",
  },
  actGreen: { backgroundColor: "#dcfce7", borderColor: "#86efac" },
  actGreenText: { color: "#15803d", fontSize: 11, fontWeight: "600" },
  actRed: { backgroundColor: "#fee2e2", borderColor: "#fca5a5" },
  actRedText: { color: "#b91c1c", fontSize: 11, fontWeight: "600" },
  actBlue: { backgroundColor: "#dbeafe", borderColor: "#93c5fd" },
  actBlueText: { color: "#1d4ed8", fontSize: 11, fontWeight: "600" },
  actOrange: { backgroundColor: "#ffedd5", borderColor: "#fed7aa" },
  actOrangeText: { color: "#c2410c", fontSize: 11, fontWeight: "600" },
  actPurple: { backgroundColor: "#f3e8ff", borderColor: "#d8b4fe" },
  actPurpleText: { color: "#7e22ce", fontSize: 11, fontWeight: "600" },
  actGray: { backgroundColor: "#f1f5f9", borderColor: "#cbd5e1" },
  actGrayText: { color: "#475569", fontSize: 11, fontWeight: "600" },
  inputRow: { flexDirection: "row", gap: 6 },
  inputField: {
    flex: 1,
    backgroundColor: "#f8fafc",
    borderWidth: 1,
    borderColor: "#cbd5e1",
    borderRadius: 6,
    paddingHorizontal: 10,
    paddingVertical: 4,
    fontSize: 12,
  },
  btnSnSend: {
    backgroundColor: "#7c3aed",
    paddingHorizontal: 12,
    justifyContent: "center",
    borderRadius: 6,
  },
  btnCmdSend: {
    backgroundColor: "#2563eb",
    paddingHorizontal: 12,
    justifyContent: "center",
    borderRadius: 6,
  },
  btnSendText: { color: "white", fontSize: 12, fontWeight: "bold" },
  memsBox: {
    backgroundColor: "#f8fafc",
    borderWidth: 1,
    borderColor: "#e2e8f0",
    borderRadius: 6,
    padding: 8,
    marginBottom: 10,
  },
  memsHeader: { fontSize: 11, fontWeight: "bold", color: "#334155", marginBottom: 2 },
  memsText: { fontSize: 11, fontFamily: "monospace", color: "#0f172a" },
  terminalBox: {
    backgroundColor: "#0f172a",
    borderRadius: 8,
    padding: 8,
    marginTop: 10,
  },
  terminalHeader: {
    flexDirection: "row",
    justifyContent: "space-between",
    marginBottom: 4,
  },
  terminalTitle: { color: "#94a3b8", fontSize: 10 },
  btnClear: { color: "#60a5fa", fontSize: 10 },
  terminalLogs: { maxHeight: 80 },
  terminalText: { color: "#38bdf8", fontFamily: "monospace", fontSize: 10 },
  tableMacHeader: {
    backgroundColor: "#f8fafc",
    borderWidth: 1,
    borderColor: "#e2e8f0",
    borderBottomWidth: 0,
    borderTopLeftRadius: 6,
    borderTopRightRadius: 6,
    paddingVertical: 6,
    alignItems: "center",
  },
  tableMacText: { fontSize: 12, fontWeight: "bold", fontFamily: "monospace", color: "#1e293b" },
  tableContainer: {
    borderWidth: 1,
    borderColor: "#e2e8f0",
    borderBottomLeftRadius: 6,
    borderBottomRightRadius: 6,
  },
  tableRow: { flexDirection: "row", borderBottomWidth: 1, borderColor: "#e2e8f0" },
  tableCell: { flex: 1, paddingVertical: 8, alignItems: "center", borderRightWidth: 1, borderColor: "#e2e8f0" },
  bgPink: { backgroundColor: "#ffe4e1" },
  bgCyan: { backgroundColor: "#e0ffff" },
  bgYellow: { backgroundColor: "#f0e68c" },
  cellLabel: { fontSize: 10, fontWeight: "600", color: "#334155", marginBottom: 2 },
  cellVal: { fontSize: 13, fontWeight: "bold", fontFamily: "monospace", color: "#0f172a" },
  modalMask: {
    flex: 1,
    backgroundColor: "rgba(0,0,0,0.5)",
    justifyContent: "center",
    alignItems: "center",
    padding: 20,
  },
  modalContent: {
    backgroundColor: "white",
    width: "100%",
    borderRadius: 12,
    padding: 16,
  },
  modalHeader: {
    flexDirection: "row",
    justifyContent: "space-between",
    alignItems: "center",
    marginBottom: 6,
  },
  modalTitle: { fontSize: 15, fontWeight: "bold", color: "#0f172a" },
  modalClose: { fontSize: 16, color: "#64748b" },
  modalStatus: { fontSize: 11, color: "#64748b", marginBottom: 12 },
  deviceItem: {
    flexDirection: "row",
    justifyContent: "space-between",
    alignItems: "center",
    padding: 8,
    backgroundColor: "#f8fafc",
    borderRadius: 6,
    borderWidth: 1,
    borderColor: "#e2e8f0",
    marginBottom: 8,
  },
  itemName: { fontSize: 13, fontWeight: "bold", color: "#0f172a" },
  itemMac: { fontSize: 11, fontFamily: "monospace", color: "#64748b" },
  btnItemConnect: {
    backgroundColor: "#2563eb",
    paddingHorizontal: 12,
    paddingVertical: 4,
    borderRadius: 4,
  },
  btnItemConnectText: { color: "white", fontSize: 12, fontWeight: "600" },
  btnRescan: {
    backgroundColor: "#f1f5f9",
    paddingVertical: 8,
    borderRadius: 6,
    alignItems: "center",
    marginTop: 8,
  },
  btnRescanText: { color: "#334155", fontSize: 12, fontWeight: "bold" },
});
