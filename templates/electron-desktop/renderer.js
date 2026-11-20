// 状态与逻辑
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
  addLog('[BLE] Electron Web Bluetooth 扫描周边脑电设备...');
});

modalCloseBtn.addEventListener('click', () => {
  scanModal.classList.remove('open');
});

topDfuBtn.addEventListener('click', () => {
  addLog('[DFU] 固件 OTA 检测：当前已处于最新稳定版 v2.4.0');
  alert('固件检测：当前已是最新稳定版本 v2.4.0');
});

mainConnectBtn.addEventListener('click', () => {
  if (isConnected) {
    isConnected = false;
    statusDot.classList.remove('connected');
    statusText.classList.remove('connected');
    statusText.textContent = '未连接 (DISCONNECTED)';
    mainConnectBtn.classList.remove('connected');
    mainConnectBtn.textContent = '连接设备';
    addLog('[BLE] 用户主动断开设备连接');
  } else {
    scanModal.classList.add('open');
  }
});

window.connectMock = function(name, mac) {
  isConnected = true;
  statusDot.classList.add('connected');
  statusText.classList.add('connected');
  statusText.textContent = '已连接 (CONNECTED)';
  mainConnectBtn.classList.add('connected');
  mainConnectBtn.textContent = '断开当前连接';
  scanModal.classList.remove('open');
  addLog(`[BLE] 成功建立连接: ${name} (${mac})`);
};

// 12项图表过滤器
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
    addLog(`[图表显隐] ${name} 状态切换: ${on}`);
  };
  chartContainer.appendChild(btn);
});

// 指令事件绑定
const bindCmd = (id, log) => {
  const el = document.getElementById(id);
  if (el) el.addEventListener('click', () => addLog(log));
};

bindCmd('btnIgnition', '[TX >> XMW] 下发点火包: 0x15 (Raw) + 0x17 (Band)');
bindCmd('btnStopXmw', '[TX >> XMW] 停止数据传输: 0x16 + 0x18');
bindCmd('btn50Hz', '[TX >> XMW] 设置 50Hz 工频陷波滤波 (0x1B)');
bindCmd('btn60Hz', '[TX >> XMW] 设置 60Hz 工频陷波滤波 (0x1C)');
bindCmd('btnBatterySky', '[TX >> XMW] 读取硬件电量 (0x06)');
bindCmd('btnReadSn', '[TX >> XMW] 查询序列号 SN (0xF4)');
bindCmd('btnDetectMac', '[TX >> XMW] 探测经典蓝牙 MAC (0xFC)');

document.getElementById('btnSendSn').addEventListener('click', () => {
  const sn = document.getElementById('inputWriteSn').value.trim();
  if (sn) {
    addLog(`[TX >> XMW] 写入 SN (0xF2): ${sn}`);
    alert(`SN 写入指令已下发: ${sn}`);
  }
});

bindCmd('btnLicense', '[TX >>] license:?');
bindCmd('btnBatteryZk', '[TX >>] battery:?');
bindCmd('btnVersion', '[TX >>] version:?');
bindCmd('btnEegOn', '[TX >>] eeg_data_on:1');
bindCmd('btnEegOff', '[TX >>] eeg_data_on:0');
bindCmd('btnRate256', '[TX >>] eeg_data_rate:2 (256Hz)');
bindCmd('btnRate512', '[TX >>] eeg_data_rate:1 (512Hz)');
bindCmd('btnMemsOn', '[TX >>] mems_on:1 (开启MEMS空间姿态流)');
bindCmd('btnMemsOff', '[TX >>] mems_on:0 (关闭MEMS空间姿态流)');
bindCmd('btnDfuScan', '[TX >>] dfu_scan:1 (进入空中升级广播模式)');

document.getElementById('btnSendCustomCmd').addEventListener('click', () => {
  const input = document.getElementById('inputCustomCmd');
  const val = input.value.trim();
  if (val) {
    addLog(`[TX >>] ${val}`);
    input.value = '';
  }
});

// 数据模拟
setInterval(() => {
  if (isConnected) {
    const att = Math.min(100, Math.max(10, parseInt(document.getElementById('cellAttention').textContent) + Math.floor((Math.random() - 0.5) * 6)));
    const med = Math.min(100, Math.max(10, parseInt(document.getElementById('cellMeditation').textContent) + Math.floor((Math.random() - 0.5) * 6)));
    document.getElementById('cellAttention').textContent = att;
    document.getElementById('cellMeditation').textContent = med;
    document.getElementById('cellRawEeg').textContent = Math.floor((Math.random() - 0.5) * 240);
  }
}, 1000);
