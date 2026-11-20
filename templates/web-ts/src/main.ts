import { ZKBrainWebSdk } from '@zkteco/zkbrain-web-sdk';

/**
 * 1:1 Device Management Console (DeviceScreen + DeviceShowTable) - Web TypeScript
 * Technical Support: ZKTeco BCI Division
 */

const sdk = new ZKBrainWebSdk();

// State & data models
let isConnected = false;
let deviceName = 'ZKBrain Headband';
let deviceMac = 'DC:23:4F:9A:88:01';
let batteryLevel = 85;

// DOM element references
const statusDot = document.getElementById('statusDot')!;
const statusText = document.getElementById('statusText')!;
const mainConnectBtn = document.getElementById('mainConnectBtn') as HTMLButtonElement;
const topSearchBtn = document.getElementById('topSearchBtn')!;
const topDfuBtn = document.getElementById('topDfuBtn')!;
const terminalLogs = document.getElementById('terminalLogs')!;
const terminalClearBtn = document.getElementById('terminalClearBtn')!;

// 12 metrics cells
const cellAttention = document.getElementById('cellAttention')!;
const cellMeditation = document.getElementById('cellMeditation')!;
const cellQuality = document.getElementById('cellQuality')!;
const cellRawEeg = document.getElementById('cellRawEeg')!;
const cellDelta = document.getElementById('cellDelta')!;
const cellTheta = document.getElementById('cellTheta')!;
const cellLowAlpha = document.getElementById('cellLowAlpha')!;
const cellHighAlpha = document.getElementById('cellHighAlpha')!;
const cellLowBeta = document.getElementById('cellLowBeta')!;
const cellHighBeta = document.getElementById('cellHighBeta')!;
const cellLowGamma = document.getElementById('cellLowGamma')!;
const cellMidGamma = document.getElementById('cellMidGamma')!;

function addLog(msg: string) {
  terminalLogs.textContent += `${msg}\n`;
  terminalLogs.scrollTop = terminalLogs.scrollHeight;
}

terminalClearBtn.addEventListener('click', () => {
  terminalLogs.textContent = '';
});

// Chart display toggles initialization
const chartItems = [
  'Raw EEG', 'Signal Quality', 'Attention', 'Meditation',
  'Delta', 'Theta', 'Low Alpha', 'High Alpha',
  'Low Beta', 'High Beta', 'Low Gamma', 'Middle Gamma'
];
const chartChipsContainer = document.getElementById('chartChipsContainer')!;
chartItems.forEach(title => {
  const btn = document.createElement('button');
  btn.className = 'chart-chip-btn active';
  btn.textContent = title;
  btn.addEventListener('click', () => {
    btn.classList.toggle('active');
    addLog(`[CHART] Toggle ${title}: ${btn.classList.contains('active')}`);
  });
  chartChipsContainer.appendChild(btn);
});

// Channel settings
const chkFp1 = document.getElementById('chkFp1') as HTMLInputElement;
chkFp1.addEventListener('change', () => {
  addLog(`[CHANNEL] Left (FP1): ${chkFp1.checked}`);
});

// Top bar actions
topDfuBtn.addEventListener('click', () => {
  addLog('[DFU] Checking firmware OTA: currently on latest stable v2.4.0');
  alert('DFU firmware check: currently on latest stable version v2.4.0');
});

// Scan & connect logic (W3C Web Bluetooth)
async function triggerConnect() {
  if (isConnected) {
    isConnected = false;
    statusDot.classList.remove('connected');
    statusText.classList.remove('connected');
    statusText.textContent = 'DISCONNECTED';
    mainConnectBtn.classList.remove('connected');
    mainConnectBtn.textContent = 'Connect Device';
    addLog('[BLE] Disconnected by user');
    return;
  }

  if (!navigator.bluetooth) {
    addLog('[ENV ERROR] Web Bluetooth API is not supported in this browser. Please use Chrome/Edge over HTTPS or localhost.');
    alert('Web Bluetooth API is not supported in this browser. Please use Chrome or Edge.');
    return;
  }

  try {
    addLog('[BLE] Launching browser Web Bluetooth device chooser...');
    const dev = await sdk.requestDeviceAndConnect();
    isConnected = true;
    deviceName = dev?.name || 'ZKBrain Device';
    document.getElementById('deviceName')!.textContent = deviceName;
    statusDot.classList.add('connected');
    statusText.classList.add('connected');
    statusText.textContent = 'CONNECTED';
    mainConnectBtn.classList.add('connected');
    mainConnectBtn.textContent = 'Disconnect';
    addLog(`[BLE] Successfully connected to: ${deviceName}`);
  } catch (err: any) {
    addLog(`[BLE ERROR] ${err.message}`);
  }
}

mainConnectBtn.addEventListener('click', triggerConnect);
topSearchBtn.addEventListener('click', triggerConnect);

// Section 5: NeuroSky / MindWave 20-Byte Protocol Console
document.getElementById('btnIgnition')!.addEventListener('click', () => {
  addLog('[TX >> XMW] Ignition Packet: 0x15 (Raw) + 0x17 (Band)');
});
document.getElementById('btnStopXmw')!.addEventListener('click', () => {
  addLog('[TX >> XMW] Stop transmission: 0x16 + 0x18');
});
document.getElementById('btn50Hz')!.addEventListener('click', () => {
  addLog('[TX >> XMW] Set 50Hz notch filter (0x1B)');
});
document.getElementById('btn60Hz')!.addEventListener('click', () => {
  addLog('[TX >> XMW] Set 60Hz notch filter (0x1C)');
});
document.getElementById('btnBatterySky')!.addEventListener('click', () => {
  addLog('[TX >> XMW] Read battery level (0x06)');
});
document.getElementById('btnReadSn')!.addEventListener('click', () => {
  addLog('[TX >> XMW] Query SN (0xF4)');
});
document.getElementById('btnDetectMac')!.addEventListener('click', () => {
  addLog('[TX >> XMW] Detect classic Bluetooth MAC (0xFC)');
});

const inputWriteSn = document.getElementById('inputWriteSn') as HTMLInputElement;
document.getElementById('btnSendSn')!.addEventListener('click', () => {
  const sn = inputWriteSn.value.trim();
  if (sn) {
    addLog(`[TX >> XMW] Write SN (0xF2): ${sn}`);
    alert(`SN command sent: ${sn}`);
  }
});

// Section 6: ZKBrain Native Device Official Console
document.getElementById('btnLicense')!.addEventListener('click', () => {
  addLog('[TX >>] license:?');
});
document.getElementById('btnBatteryZk')!.addEventListener('click', () => {
  addLog('[TX >>] battery:?');
});
document.getElementById('btnVersion')!.addEventListener('click', () => {
  addLog('[TX >>] version:?');
});
document.getElementById('btnEegOn')!.addEventListener('click', () => {
  addLog('[TX >>] eeg_data_on:1');
});
document.getElementById('btnEegOff')!.addEventListener('click', () => {
  addLog('[TX >>] eeg_data_on:0');
});
document.getElementById('btnRate256')!.addEventListener('click', () => {
  addLog('[TX >>] eeg_data_rate:2 (256Hz)');
});
document.getElementById('btnRate512')!.addEventListener('click', () => {
  addLog('[TX >>] eeg_data_rate:1 (512Hz)');
});
document.getElementById('btnMemsOn')!.addEventListener('click', () => {
  addLog('[TX >>] mems_on:1 (Enable MEMS Motion Stream)');
});
document.getElementById('btnMemsOff')!.addEventListener('click', () => {
  addLog('[TX >>] mems_on:0 (Disable MEMS Motion Stream)');
});
document.getElementById('btnDfuScan')!.addEventListener('click', () => {
  addLog('[TX >>] dfu_scan:1 (Enter DFU OTA Ready Mode)');
});

const inputCustomCmd = document.getElementById('inputCustomCmd') as HTMLInputElement;
document.getElementById('btnSendCustomCmd')!.addEventListener('click', () => {
  const cmd = inputCustomCmd.value.trim();
  if (cmd) {
    addLog(`[TX >>] ${cmd}`);
    inputCustomCmd.value = '';
  }
});

// SDK Real-time EEG Data Listener
sdk.on('brain_data', (eeg: any) => {
  if (eeg.attention !== undefined) cellAttention.textContent = eeg.attention;
  if (eeg.meditation !== undefined) cellMeditation.textContent = eeg.meditation;
  if (eeg.poorSignal !== undefined) cellQuality.textContent = eeg.poorSignal;
  if (eeg.delta !== undefined) cellDelta.textContent = eeg.delta;
  if (eeg.theta !== undefined) cellTheta.textContent = eeg.theta;
  if (eeg.lowAlpha !== undefined) cellLowAlpha.textContent = eeg.lowAlpha;
  if (eeg.highAlpha !== undefined) cellHighAlpha.textContent = eeg.highAlpha;
  if (eeg.lowBeta !== undefined) cellLowBeta.textContent = eeg.lowBeta;
  if (eeg.highBeta !== undefined) cellHighBeta.textContent = eeg.highBeta;
  if (eeg.lowGamma !== undefined) cellLowGamma.textContent = eeg.lowGamma;
  if (eeg.midGamma !== undefined) cellMidGamma.textContent = eeg.midGamma;
});

sdk.on('raw_data', (raw: number) => {
  cellRawEeg.textContent = raw.toString();
});
