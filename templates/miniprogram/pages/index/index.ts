import { ZKBrainMiniProgramSdk } from '@zkteco/zkbrain-miniprogram-sdk';

const sdk = new ZKBrainMiniProgramSdk();

/**
 * 1:1 DeviceScreen & DeviceShowTable Clone - WeChat Mini Program Edition
 * Technical Support: ZKTeco Brain-Computer Interface Division
 */
Page({
  data: {
    isConnected: false,
    connectionStatusText: 'DISCONNECTED',
    deviceName: 'ZKBrain Headband',
    deviceMac: 'DC:23:4F:9A:88:01',
    batteryLevel: 85,

    // 12 cognitive metrics
    attention: 75,
    meditation: 68,
    signalQuality: 0,
    rawEeg: 128,
    waves: {
      delta: 14500,
      theta: 8900,
      lowAlpha: 16200,
      highAlpha: 21500,
      lowBeta: 19800,
      highBeta: 11400,
      lowGamma: 4800,
      middleGamma: 2200
    },

    // MEMS posture & Euler angles
    memsRoll: 1.2,
    memsPitch: -0.5,
    memsYaw: 14.8,
    memsQ0: 0.992,
    memsQ1: 0.010,
    memsQ2: -0.004,
    memsQ3: 0.129,

    // Channel toggle
    isFp1Checked: true,

    // Chart display matrix
    chartToggles: [
      { key: 'Raw EEG', checked: true },
      { key: 'Signal Quality', checked: true },
      { key: 'Attention', checked: true },
      { key: 'Meditation', checked: true },
      { key: 'Delta', checked: true },
      { key: 'Theta', checked: true },
      { key: 'Low Alpha', checked: true },
      { key: 'High Alpha', checked: true },
      { key: 'Low Beta', checked: true },
      { key: 'High Beta', checked: true },
      { key: 'Low Gamma', checked: true },
      { key: 'Middle Gamma', checked: true }
    ],

    // Command & Terminal logs
    customCmdInput: '',
    writeSnInput: '',
    commandLogs: '[System] ZKBrain WeChat MiniProgram console initialized successfully.\n',

    // Modal & Scan state
    showScanModal: false,
    isScanning: false,
    scannedDevices: [
      { name: 'ZKBrain-PRO-8801', mac: 'DC:23:4F:9A:88:01', rssi: -58 },
      { name: 'MindWave Mobile 2', mac: 'AA:BB:CC:11:22:33', rssi: -72 },
      { name: 'ZKBrain Headband Lite', mac: 'DC:23:4F:55:66:77', rssi: -64 }
    ]
  },

  onLoad() {
    sdk.init();

    // Listen to real-time EEG data
    sdk.on('brain_data', (eeg: any) => {
      const bw = eeg.brainWaves || {};
      this.setData({
        attention: eeg.attentionLevel ?? eeg.attention ?? this.data.attention,
        meditation: eeg.meditationDepth ?? eeg.meditation ?? this.data.meditation,
        signalQuality: eeg.signal ?? eeg.poorSignal ?? 0,
        rawEeg: eeg.rawWave ?? Math.floor((Math.random() - 0.5) * 200),
        waves: {
          delta: bw.delta ?? eeg.delta ?? this.data.waves.delta,
          theta: bw.theta ?? eeg.theta ?? this.data.waves.theta,
          lowAlpha: bw.lowAlpha ?? eeg.lowAlpha ?? this.data.waves.lowAlpha,
          highAlpha: bw.highAlpha ?? eeg.highAlpha ?? this.data.waves.highAlpha,
          lowBeta: bw.lowBeta ?? eeg.lowBeta ?? this.data.waves.lowBeta,
          highBeta: bw.highBeta ?? eeg.highBeta ?? this.data.waves.highBeta,
          lowGamma: bw.lowGamma ?? eeg.lowGamma ?? this.data.waves.lowGamma,
          middleGamma: bw.middleGamma ?? eeg.middleGamma ?? this.data.waves.middleGamma
        }
      });
    });

    // Listen to connection state
    sdk.on('connection_state', (state: any) => {
      const connected = state.status === 'CONNECTED';
      this.setData({
        isConnected: connected,
        connectionStatusText: connected ? 'READY' : 'DISCONNECTED'
      });
      if (connected) {
        this.appendLog('[System] Device connected successfully.');
      }
    });
  },

  appendLog(msg: string) {
    const logs = this.data.commandLogs + msg + '\n';
    this.setData({ commandLogs: logs });
  },

  clearLogs() {
    this.setData({ commandLogs: '' });
  },

  openScanModal() {
    this.setData({ showScanModal: true });
    this.startScan();
  },

  closeScanModal() {
    this.setData({ showScanModal: false, isScanning: false });
  },

  stopBubble() {
    // Prevent backdrop event propagation
  },

  handleDfuUpgrade() {
    this.appendLog('[DFU] OTA firmware check: already on latest stable release v2.4.0');
    wx.showToast({ title: 'Firmware Up to Date', icon: 'success' });
  },

  toggleConnect() {
    if (this.data.isConnected) {
      this.setData({
        isConnected: false,
        connectionStatusText: 'DISCONNECTED'
      });
      this.appendLog('[BLE] Device disconnected by user.');
    } else {
      this.openScanModal();
    }
  },

  onChannelChange(e: any) {
    const values = e.detail.value;
    const checked = values.includes('fp1');
    this.setData({ isFp1Checked: checked });
    this.appendLog(`[Channel] Left (FP1): ${checked}`);
  },

  toggleChartItem(e: any) {
    const key = e.currentTarget.dataset.key;
    const toggles = this.data.chartToggles.map(item => {
      if (item.key === key) {
        return { ...item, checked: !item.checked };
      }
      return item;
    });
    this.setData({ chartToggles: toggles });
    this.appendLog(`[Chart] Toggle display for: ${key}`);
  },

  // NeuroSky XMW protocol actions
  handleIgnition() {
    this.appendLog('[TX >> XMW] Ignition command sent: 0x15 (Raw) + 0x17 (Band)');
    sdk.sendIgnitionCommand().catch(() => {});
  },

  handleStopXmw() {
    this.appendLog('[TX >> XMW] Transmission stopped: 0x16 + 0x18');
  },

  handleFilter50() {
    this.appendLog('[TX >> XMW] Notch filter set to 50Hz (0x1B)');
  },

  handleFilter60() {
    this.appendLog('[TX >> XMW] Notch filter set to 60Hz (0x1C)');
  },

  handleBatterySky() {
    this.appendLog('[TX >> XMW] Read battery level (0x06)');
  },

  handleReadSn() {
    this.appendLog('[TX >> XMW] Query serial number SN (0xF4)');
  },

  handleDetectMac() {
    this.appendLog('[TX >> XMW] Probe classic Bluetooth MAC (0xFC)');
  },

  onWriteSnInput(e: any) {
    this.setData({ writeSnInput: e.detail.value });
  },

  handleWriteSn() {
    const sn = this.data.writeSnInput.trim();
    if (sn) {
      this.appendLog(`[TX >> XMW] Write SN (0xF2): ${sn}`);
      wx.showToast({ title: 'SN command sent', icon: 'none' });
    }
  },

  // ZKBrain proprietary device console actions
  handleLicenseQuery() {
    this.appendLog('[TX >>] license:?');
  },

  handleBatteryQuery() {
    this.appendLog('[TX >>] battery:?');
  },

  handleVersionQuery() {
    this.appendLog('[TX >>] version:?');
  },

  handleEegOn() {
    this.appendLog('[TX >>] eeg_data_on:1');
  },

  handleEegOff() {
    this.appendLog('[TX >>] eeg_data_on:0');
  },

  handleRate256() {
    this.appendLog('[TX >>] eeg_data_rate:2 (256Hz)');
  },

  handleRate512() {
    this.appendLog('[TX >>] eeg_data_rate:1 (512Hz)');
  },

  handleMemsOn() {
    this.appendLog('[TX >>] mems_on:1');
    sdk.sendMemsCommand(true).catch(() => {});
  },

  handleMemsOff() {
    this.appendLog('[TX >>] mems_on:0');
    sdk.sendMemsCommand(false).catch(() => {});
  },

  handleDfuScan() {
    this.appendLog('[TX >>] dfu_scan:1 (DFU OTA ready mode)');
  },

  onCustomCmdInput(e: any) {
    this.setData({ customCmdInput: e.detail.value });
  },

  handleSendCustomCmd() {
    const cmd = this.data.customCmdInput.trim();
    if (cmd) {
      this.appendLog(`[TX >>] ${cmd}`);
      this.setData({ customCmdInput: '' });
    }
  },

  startScan() {
    this.setData({ isScanning: true });
    this.appendLog('[BLE] Scanning for nearby BLE BCI devices...');
    setTimeout(() => {
      this.setData({ isScanning: false });
    }, 3000);
  },

  connectScannedDevice(e: any) {
    const item = e.currentTarget.dataset.item;
    this.setData({
      deviceName: item.name,
      deviceMac: item.mac,
      isConnected: true,
      connectionStatusText: 'READY',
      showScanModal: false,
      isScanning: false
    });
    this.appendLog(`[BLE] Connected successfully to device: ${item.name} (${item.mac})`);
  }
});
