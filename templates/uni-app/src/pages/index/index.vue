<template>
  <view class="container">
    <!-- Section 1: Header Bar -->
    <view class="header-bar">
      <view class="header-title">Device Management (DeviceScreen)</view>
      <view class="header-actions">
        <button class="btn-top btn-search" @tap="openScanModal">Search BLE</button>
        <button class="btn-top btn-dfu" @tap="handleDfuUpgrade">DFU OTA</button>
        <view class="badge-auth">Authorized</view>
      </view>
    </view>

    <!-- Section 2: Device Link Status Card -->
    <view class="card">
      <view class="status-row">
        <view class="status-badge-wrap">
          <view class="status-dot" :class="{ connected: isConnected }"></view>
          <text class="status-text" :class="{ connected: isConnected }">
            {{ isConnected ? "CONNECTED" : "DISCONNECTED" }}
          </text>
        </view>
        <view class="battery-capsule">⚡ {{ batteryLevel }}%</view>
      </view>

      <view class="device-name">{{ deviceName }}</view>
      <view class="device-mac">MAC: {{ deviceMac }}</view>

      <view class="badges-row">
        <view class="chip chip-blue">Nordic BLE 5.0</view>
        <view class="chip chip-teal">ASCII 512Hz</view>
        <view class="chip chip-purple">NeuroSky XMW</view>
      </view>

      <button
        class="btn-connect"
        :class="{ connected: isConnected }"
        @tap="toggleConnect"
      >
        {{ isConnected ? "Disconnect" : "Connect Device" }}
      </button>
    </view>

    <!-- Section 3: EEG Channels -->
    <view class="card">
      <view class="card-title">EEG Measurement Channels</view>
      <view class="card-subtitle">Single-channel forehead placement fixed at front-left (FP1)</view>
      <view class="channel-options">
        <label class="channel-label">
          <switch :checked="isFp1Checked" color="#2563eb" @change="onChannelChange" />
          <text>Left (FP1) [Active]</text>
        </label>
        <label class="channel-label disabled">
          <switch :checked="false" disabled />
          <text>Right (FP2) [Unsupported]</text>
        </label>
      </view>
    </view>

    <!-- Section 4: Chart Display Filter Matrix -->
    <view class="card">
      <view class="card-title">12 Metrics Filter Matrix</view>
      <view class="card-subtitle">Controls the 4x3 spectrum matrix visibility in real time</view>
      <view class="chart-chips">
        <view
          v-for="item in chartToggles"
          :key="item.key"
          class="chart-chip-btn"
          :class="{ active: item.checked }"
          @tap="toggleChartItem(item.key)"
        >
          {{ item.checked ? "✓ " : "" }}{{ item.key }}
        </view>
      </view>
    </view>

    <!-- Section 5: NeuroSky XMW Binary Protocol Console -->
    <view class="card">
      <view class="card-title">NeuroSky XMW Binary Hardware Console</view>
      <view class="card-subtitle">Directly control TGAM / MindWave registers and streaming switches</view>
      <view class="btn-console-grid">
        <button class="btn-act act-green" @tap="handleIgnition">Ignition (0x15+0x17)</button>
        <button class="btn-act act-red" @tap="handleStopXmw">Stop (0x16+0x18)</button>
        <button class="btn-act act-blue" @tap="handleFilter50Hz">50Hz Notch (0x1B)</button>
        <button class="btn-act act-blue" @tap="handleFilter60Hz">60Hz Notch (0x1C)</button>
        <button class="btn-act act-orange" @tap="handleQueryBatterySky">Battery (0x06)</button>
        <button class="btn-act act-gray" @tap="handleQuerySn">Query SN (0xF4)</button>
        <button class="btn-act act-teal" @tap="handleDetectMac">Probe Classic MAC (0xFC)</button>
      </view>

      <view class="input-row">
        <input
          v-model="writeSnInput"
          class="input-field"
          placeholder="Enter device SN (e.g. ZK20261120001)"
        />
        <button class="btn-sn-send" @tap="handleWriteSn">Write SN (0xF2)</button>
      </view>
    </view>

    <!-- Section 6: ZKBrain Native Device Official Console -->
    <view class="card">
      <view class="card-title">ZKBrain Native Device Official Console</view>
      <view class="card-subtitle">Supports ASCII control commands and MEMS 6-axis motion stream</view>
      
      <!-- MEMS Spatial Attitude -->
      <view class="mems-box">
        <view class="mems-header">MEMS 6-Axis Spatial Attitude (Euler Angles & Quaternions):</view>
        <view class="mems-text">
          Roll: {{ memsRoll }}° | Pitch: {{ memsPitch }}° | Yaw: {{ memsYaw }}°
        </view>
        <view class="mems-text text-dim">
          Q0: {{ memsQ0 }} | Q1: {{ memsQ1 }} | Q2: {{ memsQ2 }} | Q3: {{ memsQ3 }}
        </view>
      </view>

      <view class="btn-console-grid">
        <button class="btn-act act-gray" @tap="handleQueryLicense">license:?</button>
        <button class="btn-act act-orange" @tap="handleQueryBatteryZk">battery:?</button>
        <button class="btn-act act-gray" @tap="handleQueryVersion">version:?</button>
        <button class="btn-act act-green" @tap="handleEegOn">eeg_data_on:1</button>
        <button class="btn-act act-red" @tap="handleEegOff">eeg_data_on:0</button>
        <button class="btn-act act-blue" @tap="handleRate256">256Hz (rate:2)</button>
        <button class="btn-act act-blue" @tap="handleRate512">512Hz (rate:1)</button>
        <button class="btn-act act-purple" @tap="handleMemsOn">MEMS ON (mems_on:1)</button>
        <button class="btn-act act-gray" @tap="handleMemsOff">MEMS OFF (mems_on:0)</button>
        <button class="btn-act act-orange" @tap="handleDfuScan">DFU Scan (dfu_scan:1)</button>
      </view>

      <view class="input-row">
        <input
          v-model="customCmdInput"
          class="input-field"
          placeholder="Custom command (e.g. mems_on:1 or led:1)"
        />
        <button class="btn-input-send" @tap="handleSendCustomCmd">Send Command</button>
      </view>

      <!-- Terminal Output Monitor -->
      <view class="terminal-box">
        <view class="terminal-header">
          <text>Command Transmission & Feedback Terminal:</text>
          <text class="btn-clear" @tap="clearLogs">Clear</text>
        </view>
        <scroll-view class="terminal-logs" scroll-y>
          <text class="terminal-text">{{ commandLogs }}</text>
        </scroll-view>
      </view>
    </view>

    <!-- Section 7: DeviceShowTable 4x3 Spectrum Metrics Table -->
    <view class="card">
      <view class="card-title">4x3 Full-Band Spectrum Metrics (DeviceShowTable)</view>
      <view class="card-subtitle">
        1:1 realization of shared1 console; Pink: Cognitive & Quality, Cyan: Slow & Alpha, Yellow: High Frequency
      </view>

      <view class="table-mac-header">
        <text class="table-mac-text">MAC: {{ deviceMac }}</text>
      </view>

      <view class="table-container">
        <!-- Row 1: Attention | Meditation | SignalQuality -->
        <view class="table-row">
          <view class="table-cell bg-pink">
            <text class="cell-label">Attention</text>
            <text class="cell-val">{{ attention }}</text>
          </view>
          <view class="table-cell bg-pink">
            <text class="cell-label">Meditation</text>
            <text class="cell-val">{{ meditation }}</text>
          </view>
          <view class="table-cell bg-pink">
            <text class="cell-label">Quality</text>
            <text class="cell-val">{{ signalQuality }}</text>
          </view>
        </view>

        <!-- Row 2: Raw EEG | Delta | Theta -->
        <view class="table-row">
          <view class="table-cell bg-pink">
            <text class="cell-label">Raw EEG</text>
            <text class="cell-val">{{ rawEeg }}</text>
          </view>
          <view class="table-cell bg-cyan">
            <text class="cell-label">Delta</text>
            <text class="cell-val">{{ waves.delta }}</text>
          </view>
          <view class="table-cell bg-cyan">
            <text class="cell-label">Theta</text>
            <text class="cell-val">{{ waves.theta }}</text>
          </view>
        </view>

        <!-- Row 3: Low Alpha | High Alpha | Low Beta -->
        <view class="table-row">
          <view class="table-cell bg-cyan">
            <text class="cell-label">Low Alpha</text>
            <text class="cell-val">{{ waves.lowAlpha }}</text>
          </view>
          <view class="table-cell bg-cyan">
            <text class="cell-label">High Alpha</text>
            <text class="cell-val">{{ waves.highAlpha }}</text>
          </view>
          <view class="table-cell bg-yellow">
            <text class="cell-label">Low Beta</text>
            <text class="cell-val">{{ waves.lowBeta }}</text>
          </view>
        </view>

        <!-- Row 4: High Beta | Low Gamma | Mid Gamma -->
        <view class="table-row">
          <view class="table-cell bg-yellow">
            <text class="cell-label">High Beta</text>
            <text class="cell-val">{{ waves.highBeta }}</text>
          </view>
          <view class="table-cell bg-yellow">
            <text class="cell-label">Low Gamma</text>
            <text class="cell-val">{{ waves.lowGamma }}</text>
          </view>
          <view class="table-cell bg-yellow">
            <text class="cell-label">Mid Gamma</text>
            <text class="cell-val">{{ waves.middleGamma }}</text>
          </view>
        </view>
      </view>
    </view>

    <!-- Section 8: Bluetooth Scan Dialog -->
    <view v-if="showScanModal" class="modal-mask">
      <view class="modal-content">
        <view class="modal-header">
          <text class="modal-title">Search Nearby BLE BCI Devices</text>
          <text class="modal-close" @tap="closeScanModal">✕</text>
        </view>

        <view class="modal-status">
          <text>{{ isScanning ? "Scanning nearby BLE devices..." : "Scan complete, tap to connect" }}</text>
        </view>

        <scroll-view class="device-list" scroll-y>
          <view
            v-for="(item, index) in scannedDevices"
            :key="index"
            class="device-item"
          >
            <view class="device-info">
              <text class="device-item-name">{{ item.name }}</text>
              <text class="device-item-mac">{{ item.mac }} | {{ item.rssi }} dBm</text>
            </view>
            <button class="btn-item-connect" @tap="connectScannedDevice(item)">Connect</button>
          </view>
        </scroll-view>

        <button class="btn-rescan" :disabled="isScanning" @tap="startScan">
          {{ isScanning ? "Searching..." : "Rescan Nearby Devices" }}
        </button>
      </view>
    </view>
  </view>
</template>

<script setup lang="ts">
import { ref, reactive, onMounted, onUnmounted } from "vue";

// Connection and device status
const isConnected = ref(false);
const deviceName = ref("ZKBrain Headband PRO");
const deviceMac = ref("DC:23:4F:9A:88:01");
const batteryLevel = ref(85);

// 12 physiological metrics
const attention = ref(78);
const meditation = ref(65);
const signalQuality = ref(0);
const rawEeg = ref(136);

const waves = reactive({
  delta: 14200,
  theta: 8900,
  lowAlpha: 16100,
  highAlpha: 21800,
  lowBeta: 19500,
  highBeta: 11200,
  lowGamma: 4800,
  middleGamma: 2200,
});

// MEMS attitude & Euler angles
const memsRoll = ref(1.2);
const memsPitch = ref(-0.5);
const memsYaw = ref(14.8);
const memsQ0 = ref(0.992);
const memsQ1 = ref(0.01);
const memsQ2 = ref(-0.004);
const memsQ3 = ref(0.129);

// Channels & chart visibility
const isFp1Checked = ref(true);

const chartToggles = reactive([
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

// Terminal & commands
const writeSnInput = ref("");
const customCmdInput = ref("");
const commandLogs = ref("[SYSTEM] ZKBrain Uni-app (Vue 3 + TS) console initialized\n");

// Scan & Bluetooth dialog
const showScanModal = ref(false);
const isScanning = ref(false);
const scannedDevices = reactive([
  { name: "ZKBrain-PRO-8801", mac: "DC:23:4F:9A:88:01", rssi: -58 },
  { name: "MindWave Mobile 2", mac: "AA:BB:CC:11:22:33", rssi: -72 },
  { name: "ZKBrain Headband Lite", mac: "DC:23:4F:55:66:77", rssi: -64 },
]);

let mockTimer: any = null;

onMounted(() => {
  appendLog("[BLE] Bluetooth engine ready, supporting WeChat, Alipay, ByteDance & native Apps");
  mockTimer = setInterval(() => {
    if (isConnected.value) {
      attention.value = Math.min(100, Math.max(10, attention.value + Math.floor((Math.random() - 0.5) * 6)));
      meditation.value = Math.min(100, Math.max(10, meditation.value + Math.floor((Math.random() - 0.5) * 6)));
      rawEeg.value = Math.floor((Math.random() - 0.5) * 240);
    }
  }, 1000);
});

onUnmounted(() => {
  if (mockTimer) clearInterval(mockTimer);
});

function appendLog(msg: string) {
  commandLogs.value += msg + "\n";
}

function clearLogs() {
  commandLogs.value = "";
}

// Runtime Bluetooth permissions check
async function ensureBluetoothPermission(): Promise<boolean> {
  return new Promise((resolve) => {
    // #ifdef MP-WEIXIN
    uni.getSetting({
      success: (res) => {
        if (res.authSetting["scope.bluetooth"] === false) {
          uni.showModal({
            title: "Bluetooth Permission Required",
            content: "Connecting to BCI hardware requires Bluetooth access. Please enable it in Settings.",
            confirmText: "Settings",
            success: (modalRes) => {
              if (modalRes.confirm) uni.openSetting();
              resolve(false);
            },
          });
        } else if (res.authSetting["scope.bluetooth"] === undefined) {
          uni.authorize({
            scope: "scope.bluetooth",
            success: () => resolve(true),
            fail: () => resolve(false),
          });
        } else {
          resolve(true);
        }
      },
      fail: () => resolve(false),
    });
    // #endif

    // #ifndef MP-WEIXIN
    resolve(true);
    // #endif
  });
}

async function startScan() {
  const ok = await ensureBluetoothPermission();
  if (!ok) {
    appendLog("[BLE] Bluetooth permissions denied or cancelled by user");
    return;
  }

  uni.openBluetoothAdapter({
    success: () => {
      isScanning.value = true;
      appendLog("[BLE] Bluetooth adapter initialized, scanning for nearby BCI devices...");
      setTimeout(() => {
        isScanning.value = false;
        appendLog("[BLE] Scan complete, found 3 available BCI devices");
      }, 2500);
    },
    fail: (err) => {
      appendLog(`[BLE] Failed to initialize Bluetooth adapter: ${err.errMsg}`);
      isScanning.value = false;
    },
  });
}

function openScanModal() {
  showScanModal.value = true;
  startScan();
}

function closeScanModal() {
  showScanModal.value = false;
  isScanning.value = false;
}

function connectScannedDevice(item: any) {
  deviceName.value = item.name;
  deviceMac.value = item.mac;
  isConnected.value = true;
  showScanModal.value = false;
  isScanning.value = false;
  appendLog(`[BLE] Connected to device: ${item.name} (${item.mac})`);
}

function toggleConnect() {
  if (isConnected.value) {
    isConnected.value = false;
    appendLog("[BLE] Disconnected by user");
  } else {
    openScanModal();
  }
}

function handleDfuUpgrade() {
  appendLog("[DFU] Checking firmware OTA: currently on latest stable release v2.4.0");
  uni.showToast({ title: "Firmware up to date: v2.4.0", icon: "success" });
}

function onChannelChange(e: any) {
  isFp1Checked.value = e.detail.value;
  appendLog(`[CHANNEL] Left (FP1): ${isFp1Checked.value}`);
}

function toggleChartItem(key: string) {
  const target = chartToggles.find((item) => item.key === key);
  if (target) {
    target.checked = !target.checked;
    appendLog(`[CHART] Toggle display for ${key}: ${target.checked}`);
  }
}

// NeuroSky XMW commands
function handleIgnition() {
  appendLog("[TX >> XMW] Ignition Packet: 0x15 (Raw) + 0x17 (Band)");
}
function handleStopXmw() {
  appendLog("[TX >> XMW] Stop transmission: 0x16 + 0x18");
}
function handleFilter50Hz() {
  appendLog("[TX >> XMW] Set 50Hz notch filter (0x1B)");
}
function handleFilter60Hz() {
  appendLog("[TX >> XMW] Set 60Hz notch filter (0x1C)");
}
function handleQueryBatterySky() {
  appendLog("[TX >> XMW] Read battery level (0x06)");
}
function handleQuerySn() {
  appendLog("[TX >> XMW] Query SN (0xF4)");
}
function handleDetectMac() {
  appendLog("[TX >> XMW] Detect classic Bluetooth MAC (0xFC)");
}
function handleWriteSn() {
  const sn = writeSnInput.value.trim();
  if (sn) {
    appendLog(`[TX >> XMW] Write SN (0xF2): ${sn}`);
    uni.showToast({ title: `SN dispatched: ${sn}`, icon: "none" });
  }
}

// ZKBrain commands
function handleQueryLicense() {
  appendLog("[TX >>] license:?");
}
function handleQueryBatteryZk() {
  appendLog("[TX >>] battery:?");
}
function handleQueryVersion() {
  appendLog("[TX >>] version:?");
}
function handleEegOn() {
  appendLog("[TX >>] eeg_data_on:1");
}
function handleEegOff() {
  appendLog("[TX >>] eeg_data_on:0");
}
function handleRate256() {
  appendLog("[TX >>] eeg_data_rate:2 (256Hz)");
}
function handleRate512() {
  appendLog("[TX >>] eeg_data_rate:1 (512Hz)");
}
function handleMemsOn() {
  appendLog("[TX >>] mems_on:1 (Enable MEMS Motion Stream)");
}
function handleMemsOff() {
  appendLog("[TX >>] mems_on:0 (Disable MEMS Motion Stream)");
}
function handleDfuScan() {
  appendLog("[TX >>] dfu_scan:1 (Enter DFU OTA Ready Mode)");
}
function handleSendCustomCmd() {
  const cmd = customCmdInput.value.trim();
  if (cmd) {
    appendLog(`[TX >>] ${cmd}`);
    customCmdInput.value = "";
  }
}
</script>

<style scoped>
.container {
  padding: 24rpx;
  max-width: 900rpx;
  margin: 0 auto;
}

/* Header bar */
.header-bar {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 20rpx;
}
.header-title {
  font-size: 32rpx;
  font-weight: bold;
  color: #0f172a;
}
.header-actions {
  display: flex;
  align-items: center;
  gap: 12rpx;
}
.btn-top {
  margin: 0;
  padding: 8rpx 18rpx;
  font-size: 24rpx;
  font-weight: 500;
  border-radius: 8rpx;
  line-height: 1.5;
  color: #ffffff;
}
.btn-search {
  background-color: #2563eb;
}
.btn-dfu {
  background-color: #475569;
}
.badge-auth {
  font-size: 22rpx;
  font-weight: bold;
  color: #16a34a;
  background-color: #dcfce7;
  border: 1px solid #86efac;
  padding: 6rpx 14rpx;
  border-radius: 8rpx;
}

/* Base Card */
.card {
  background-color: #ffffff;
  border-radius: 16rpx;
  padding: 24rpx;
  margin-bottom: 20rpx;
  box-shadow: 0 2rpx 6rpx rgba(0, 0, 0, 0.04);
}
.card-title {
  font-size: 28rpx;
  font-weight: bold;
  color: #1e293b;
  margin-bottom: 6rpx;
}
.card-subtitle {
  font-size: 22rpx;
  color: #64748b;
  margin-bottom: 16rpx;
}

/* Status Card */
.status-row {
  display: flex;
  justify-content: space-between;
  align-items: center;
}
.status-badge-wrap {
  display: flex;
  align-items: center;
  gap: 12rpx;
}
.status-dot {
  width: 16rpx;
  height: 16rpx;
  border-radius: 50%;
  background-color: #ef4444;
}
.status-dot.connected {
  background-color: #22c55e;
}
.status-text {
  font-size: 26rpx;
  font-weight: 600;
  color: #ef4444;
}
.status-text.connected {
  color: #16a34a;
}
.battery-capsule {
  font-size: 22rpx;
  font-weight: 600;
  color: #334155;
  background-color: #f8fafc;
  border: 1px solid #e2e8f0;
  padding: 4rpx 16rpx;
  border-radius: 20rpx;
}
.device-name {
  font-size: 32rpx;
  font-weight: bold;
  color: #0f172a;
  margin-top: 14rpx;
}
.device-mac {
  font-size: 22rpx;
  font-family: monospace;
  color: #64748b;
  margin-top: 4rpx;
}
.badges-row {
  display: flex;
  gap: 12rpx;
  margin-top: 14rpx;
}
.chip {
  font-size: 20rpx;
  padding: 4rpx 14rpx;
  border-radius: 6rpx;
  font-weight: 500;
}
.chip-blue {
  background-color: #dbeafe;
  color: #1d4ed8;
}
.chip-teal {
  background-color: #ccfbf1;
  color: #0f766e;
}
.chip-purple {
  background-color: #f3e8ff;
  color: #7e22ce;
}
.btn-connect {
  width: 100%;
  margin-top: 20rpx;
  background-color: #2563eb;
  color: #ffffff;
  border-radius: 12rpx;
  font-size: 28rpx;
  font-weight: 600;
}
.btn-connect.connected {
  background-color: #dc2626;
}

/* Channels */
.channel-options {
  display: flex;
  gap: 32rpx;
}
.channel-label {
  display: flex;
  align-items: center;
  gap: 10rpx;
  font-size: 26rpx;
  color: #334155;
}
.channel-label.disabled {
  color: #94a3b8;
}

/* Chart Chips */
.chart-chips {
  display: flex;
  flex-wrap: wrap;
  gap: 12rpx;
}
.chart-chip-btn {
  font-size: 22rpx;
  padding: 8rpx 16rpx;
  border-radius: 8rpx;
  border: 1px solid #cbd5e1;
  background-color: #f8fafc;
  color: #475569;
}
.chart-chip-btn.active {
  background-color: #eff6ff;
  border-color: #3b82f6;
  color: #1d4ed8;
  font-weight: 600;
}

/* Button Grid */
.btn-console-grid {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 12rpx;
  margin-bottom: 16rpx;
}
.btn-act {
  margin: 0;
  padding: 12rpx 8rpx;
  font-size: 22rpx;
  font-weight: 500;
  border-radius: 8rpx;
  line-height: 1.4;
  border: 1px solid transparent;
}
.act-green {
  background-color: #dcfce7;
  color: #15803d;
  border-color: #86efac;
}
.act-red {
  background-color: #fee2e2;
  color: #b91c1c;
  border-color: #fca5a5;
}
.act-blue {
  background-color: #dbeafe;
  color: #1d4ed8;
  border-color: #93c5fd;
}
.act-orange {
  background-color: #ffedd5;
  color: #c2410c;
  border-color: #fed7aa;
}
.act-teal {
  background-color: #ccfbf1;
  color: #0f766e;
  border-color: #5eead4;
}
.act-purple {
  background-color: #f3e8ff;
  color: #7e22ce;
  border-color: #d8b4fe;
}
.act-gray {
  background-color: #f1f5f9;
  color: #475569;
  border-color: #cbd5e1;
}

/* Input Row */
.input-row {
  display: flex;
  gap: 12rpx;
  margin-top: 12rpx;
}
.input-field {
  flex: 1;
  background-color: #f8fafc;
  border: 1px solid #cbd5e1;
  border-radius: 8rpx;
  padding: 10rpx 16rpx;
  font-size: 24rpx;
}
.btn-sn-send,
.btn-input-send {
  margin: 0;
  padding: 0 24rpx;
  font-size: 24rpx;
  font-weight: 600;
  border-radius: 8rpx;
  display: flex;
  align-items: center;
  justify-content: center;
  color: #ffffff;
}
.btn-sn-send {
  background-color: #7c3aed;
}
.btn-input-send {
  background-color: #2563eb;
}

/* MEMS attitude card */
.mems-box {
  background-color: #f8fafc;
  border: 1px solid #e2e8f0;
  border-radius: 10rpx;
  padding: 14rpx;
  margin-bottom: 16rpx;
}
.mems-header {
  font-size: 22rpx;
  font-weight: bold;
  color: #334155;
  margin-bottom: 6rpx;
}
.mems-text {
  font-family: monospace;
  font-size: 22rpx;
  color: #0f172a;
}
.text-dim {
  color: #64748b;
  margin-top: 4rpx;
}

/* Terminal Monitor */
.terminal-box {
  background-color: #0f172a;
  border-radius: 12rpx;
  padding: 16rpx;
  margin-top: 16rpx;
}
.terminal-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  color: #94a3b8;
  font-size: 20rpx;
  margin-bottom: 8rpx;
}
.btn-clear {
  color: #60a5fa;
  cursor: pointer;
}
.terminal-logs {
  height: 140rpx;
}
.terminal-text {
  font-family: monospace;
  font-size: 20rpx;
  color: #38bdf8;
  white-space: pre-wrap;
  word-break: break-all;
}

/* DeviceShowTable 4x3 Spectrum Table */
.table-mac-header {
  background-color: #f8fafc;
  border: 1px solid #e2e8f0;
  border-bottom: none;
  border-radius: 12rpx 12rpx 0 0;
  padding: 10rpx;
  text-align: center;
}
.table-mac-text {
  font-family: monospace;
  font-size: 24rpx;
  font-weight: bold;
  color: #1e293b;
}
.table-container {
  border: 1px solid #e2e8f0;
  border-radius: 0 0 12rpx 12rpx;
  background-color: #ffffff;
}
.table-row {
  display: flex;
  border-bottom: 1px solid #e2e8f0;
}
.table-row:last-child {
  border-bottom: none;
}
.table-cell {
  flex: 1;
  padding: 14rpx 6rpx;
  display: flex;
  flex-direction: column;
  align-items: center;
  border-right: 1px solid #e2e8f0;
}
.table-cell:last-child {
  border-right: none;
}
.cell-label {
  font-size: 20rpx;
  font-weight: bold;
  color: #334155;
  margin-bottom: 4rpx;
}
.cell-val {
  font-family: monospace;
  font-size: 26rpx;
  font-weight: bold;
  color: #0f172a;
}
.bg-pink {
  background-color: #ffe4e1;
}
.bg-cyan {
  background-color: #e0ffff;
}
.bg-yellow {
  background-color: #f0e68c;
}

/* Modal */
.modal-mask {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background-color: rgba(0, 0, 0, 0.5);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 999;
}
.modal-content {
  background-color: #ffffff;
  border-radius: 20rpx;
  width: 85%;
  max-width: 620rpx;
  padding: 24rpx;
}
.modal-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 12rpx;
}
.modal-title {
  font-size: 28rpx;
  font-weight: bold;
  color: #0f172a;
}
.modal-close {
  font-size: 32rpx;
  color: #64748b;
  padding: 0 8rpx;
}
.modal-status {
  font-size: 22rpx;
  color: #64748b;
  margin-bottom: 16rpx;
}
.device-list {
  max-height: 380rpx;
}
.device-item {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 16rpx;
  background-color: #f8fafc;
  border: 1px solid #e2e8f0;
  border-radius: 10rpx;
  margin-bottom: 12rpx;
}
.device-info {
  display: flex;
  flex-direction: column;
}
.device-item-name {
  font-size: 26rpx;
  font-weight: bold;
  color: #0f172a;
}
.device-item-mac {
  font-size: 20rpx;
  font-family: monospace;
  color: #64748b;
  margin-top: 4rpx;
}
.btn-item-connect {
  margin: 0;
  padding: 6rpx 20rpx;
  font-size: 22rpx;
  font-weight: 600;
  background-color: #2563eb;
  color: #ffffff;
  border-radius: 6rpx;
}
.btn-rescan {
  margin-top: 16rpx;
  background-color: #f1f5f9;
  color: #334155;
  font-size: 24rpx;
  font-weight: 600;
  border-radius: 8rpx;
}
</style>
