// State & logic
let isConnected = false;

const statusDot = document.getElementById('statusDot');
const statusText = document.getElementById('statusText');
const mainConnectBtn = document.getElementById('mainConnectBtn');
const topSearchBtn = document.getElementById('topSearchBtn');
const topDfuBtn = document.getElementById('topDfuBtn');
const scanModal = document.getElementById('scanModal');
const modalCloseBtn = document.getElementById('modalCloseBtn');
const terminalLogs = document.getElementById('terminalLogs');
const terminalClearBtn = document.getElementById('terminalClearBtn');

function addLog(msg) {
  terminalLogs.textContent += `${msg}\n`;
  terminalLogs.scrollTop = terminalLogs.scrollHeight;
}

terminalClearBtn.addEventListener('click', () => {
  terminalLogs.textContent = '';
});

topSearchBtn.addEventListener('click', () => {
  scanModal.classList.add('open');
  addLog('[BLE] Scanning for nearby BLE BCI devices...');
});

modalCloseBtn.addEventListener('click', () => {
  scanModal.classList.remove('open');
});

topDfuBtn.addEventListener('click', () => {
  addLog('[DFU] Checking firmware OTA: currently on latest stable v2.4.0');
  alert('Firmware check: currently on latest stable version v2.4.0');
});

mainConnectBtn.addEventListener('click', () => {
  if (isConnected) {
    isConnected = false;
    statusDot.classList.remove('connected');
    statusText.classList.remove('connected');
    statusText.textContent = 'DISCONNECTED';
    mainConnectBtn.classList.remove('connected');
    mainConnectBtn.textContent = 'Connect Device';
    addLog('[BLE] Disconnected by user');
  } else {
    scanModal.classList.add('open');
  }
});

window.connectMock = function(name, mac) {
  isConnected = true;
  statusDot.classList.add('connected');
  statusText.classList.add('connected');
  statusText.textContent = 'CONNECTED';
  mainConnectBtn.classList.add('connected');
  mainConnectBtn.textContent = 'Disconnect';
  scanModal.classList.remove('open');
  addLog(`[BLE] Connected to device: ${name} (${mac})`);
};

// 12-metric chart filters
const chartList = [
  "Raw EEG", "Signal Quality", "Attention", "Meditation",
  "Delta", "Theta", "Low Alpha", "High Alpha",
  "Low Beta", "High Beta", "Low Gamma", "Middle Gamma"
];
const chartContainer = document.getElementById('chartChipsContainer');
chartList.forEach(name => {
  const btn = document.createElement('div');
  btn.className = 'chart-chip-btn active';
  btn.textContent = `✓ ${name}`;
  btn.onclick = () => {
    btn.classList.toggle('active');
    const on = btn.classList.contains('active');
    btn.textContent = `${on ? '✓ ' : ''}${name}`;
    addLog(`[CHART] Toggle ${name}: ${on}`);
  };
  chartContainer.appendChild(btn);
});

// Hardware command bindings
const bindCmd = (id, log) => {
  const el = document.getElementById(id);
  if (el) el.addEventListener('click', () => addLog(log));
};

bindCmd('btnIgnition', '[TX >> XMW] Ignition Packet: 0x15 (Raw) + 0x17 (Band)');
bindCmd('btnStopXmw', '[TX >> XMW] Stop transmission: 0x16 + 0x18');
bindCmd('btn50Hz', '[TX >> XMW] Set 50Hz notch filter (0x1B)');
bindCmd('btn60Hz', '[TX >> XMW] Set 60Hz notch filter (0x1C)');
bindCmd('btnBatterySky', '[TX >> XMW] Read battery level (0x06)');
bindCmd('btnReadSn', '[TX >> XMW] Query SN (0xF4)');
bindCmd('btnDetectMac', '[TX >> XMW] Detect classic Bluetooth MAC (0xFC)');

document.getElementById('btnSendSn').addEventListener('click', () => {
  const sn = document.getElementById('inputWriteSn').value.trim();
  if (sn) {
    addLog(`[TX >> XMW] Write SN (0xF2): ${sn}`);
    alert(`SN command sent: ${sn}`);
  }
});

bindCmd('btnLicense', '[TX >>] license:?');
bindCmd('btnBatteryZk', '[TX >>] battery:?');
bindCmd('btnVersion', '[TX >>] version:?');
bindCmd('btnEegOn', '[TX >>] eeg_data_on:1');
bindCmd('btnEegOff', '[TX >>] eeg_data_on:0');
bindCmd('btnRate256', '[TX >>] eeg_data_rate:2 (256Hz)');
bindCmd('btnRate512', '[TX >>] eeg_data_rate:1 (512Hz)');
bindCmd('btnMemsOn', '[TX >>] mems_on:1');
bindCmd('btnMemsOff', '[TX >>] mems_on:0');
bindCmd('btnDfuScan', '[TX >>] dfu_scan:1 (DFU OTA Ready Mode)');

document.getElementById('btnSendCustomCmd').addEventListener('click', () => {
  const cmd = document.getElementById('inputCustomCmd').value.trim();
  if (cmd) {
    addLog(`[TX >>] ${cmd}`);
    document.getElementById('inputCustomCmd').value = '';
  }
});
