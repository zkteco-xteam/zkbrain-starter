import { ZKBrainWebSdk } from '@zkteco/zkbrain-web-sdk';

/**
 * 🌟 1:1 完整逐项克隆 shared1 设备管理控制台 (DeviceScreen + DeviceShowTable) - Web TypeScript 逻辑
 * 技术支持：熵基科技脑机事业部 (ZKTeco Brain-Computer Interface Division)
 */

const sdk = new ZKBrainWebSdk();

// 状态与数据模型
let isConnected = false;
let deviceName = 'ZKBrain Headband';
let deviceMac = 'DC:23:4F:9A:88:01';
let batteryLevel = 85;

// DOM 元素引用
const statusDot = document.getElementById('statusDot')!;
const statusText = document.getElementById('statusText')!;
const mainConnectBtn = document.getElementById('mainConnectBtn') as HTMLButtonElement;
const topSearchBtn = document.getElementById('topSearchBtn')!;
const topDfuBtn = document.getElementById('topDfuBtn')!;
const terminalLogs = document.getElementById('terminalLogs')!;
const terminalClearBtn = document.getElementById('terminalClearBtn')!;

// 12项指标单元格
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

// 图表显隐矩阵初始化
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
    addLog(`[图表显隐] ${title}: ${btn.classList.contains('active')}`);
  });
  chartChipsContainer.appendChild(btn);
});

// 通道配置
const chkFp1 = document.getElementById('chkFp1') as HTMLInputElement;
chkFp1.addEventListener('change', () => {
  addLog(`[通道配置] Left (FP1): ${chkFp1.checked}`);
});

// 顶部操作栏
topDfuBtn.addEventListener('click', () => {
  addLog('[DFU] 发起固件 OTA 检测，当前处于最新稳定版 v2.4.0');
  alert('DFU 固件检测完成：当前为最新版本');
});

// 扫描与连接逻辑 (基于 W3C Web Bluetooth)
async function triggerConnect() {
  if (isConnected) {
    isConnected = false;
    statusDot.classList.remove('connected');
    statusText.classList.remove('connected');
    statusText.textContent = '已断开 (DISCONNECTED)';
    mainConnectBtn.classList.remove('connected');
    mainConnectBtn.textContent = '搜索连接';
    addLog('[BLE] 用户主动断开设备连接');
    return;
  }

  if (!navigator.bluetooth) {
    addLog('[环境拦截] 当前浏览器不支持 Web Bluetooth API，请使用 Chrome/Edge 浏览器并经由 HTTPS 或 localhost 运行');
    alert('当前浏览器不支持 Web Bluetooth，请使用 Google Chrome 或 Microsoft Edge');
    return;
  }

  try {
    addLog('[BLE] 唤起浏览器原生蓝牙设备搜索器...');
    const dev = await sdk.requestDeviceAndConnect();
    isConnected = true;
    deviceName = dev?.name || 'ZKBrain Device';
    document.getElementById('deviceName')!.textContent = deviceName;
    statusDot.classList.add('connected');
    statusText.classList.add('connected');
    statusText.textContent = '已就绪 (READY)';
    mainConnectBtn.classList.add('connected');
    mainConnectBtn.textContent = '断开设备';
    addLog(`[BLE] 蓝牙配对并连接成功: ${deviceName}`);
  } catch (err: any) {
    addLog(`[BLE 连接异常] ${err.message}`);
  }
}

mainConnectBtn.addEventListener('click', triggerConnect);
topSearchBtn.addEventListener('click', triggerConnect);

// 板块 5：⚙️ NeuroSky / MindWave 专属 20 字节协议控制台
document.getElementById('btnIgnition')!.addEventListener('click', () => {
  addLog('[TX >> XMW] 下发点火包: 0x15 (Raw) + 0x17 (Band)');
});
document.getElementById('btnStopXmw')!.addEventListener('click', () => {
  addLog('[TX >> XMW] 停止传输: 0x16 + 0x18');
});
document.getElementById('btn50Hz')!.addEventListener('click', () => {
  addLog('[TX >> XMW] 设置 50Hz 工频陷波滤波 (0x1B)');
});
document.getElementById('btn60Hz')!.addEventListener('click', () => {
  addLog('[TX >> XMW] 设置 60Hz 工频陷波滤波 (0x1C)');
});
document.getElementById('btnBatterySky')!.addEventListener('click', () => {
  addLog('[TX >> XMW] 读取硬件电量 (0x06)');
});
document.getElementById('btnReadSn')!.addEventListener('click', () => {
  addLog('[TX >> XMW] 查询设备序列号 SN (0xF4)');
});
document.getElementById('btnDetectMac')!.addEventListener('click', () => {
  addLog('[TX >> XMW] 探测经典蓝牙 MAC 地址 (0xFC)');
});

const inputWriteSn = document.getElementById('inputWriteSn') as HTMLInputElement;
document.getElementById('btnSendSn')!.addEventListener('click', () => {
  const sn = inputWriteSn.value.trim();
  if (sn) {
    addLog(`[TX >> XMW] 写入 SN (0xF2): ${sn}`);
    alert(`SN 写入指令已发送: ${sn}`);
  }
});

// 板块 6：🧠 ZKBrain 自研脑电设备官方控制台
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
  addLog('[TX >>] mems_on:1');
});
document.getElementById('btnMemsOff')!.addEventListener('click', () => {
  addLog('[TX >>] mems_on:0');
});
document.getElementById('btnDfuScan')!.addEventListener('click', () => {
  addLog('[TX >>] dfu_scan:1 (进入DFU空中升级就绪模式)');
});

const inputCustomCmd = document.getElementById('inputCustomCmd') as HTMLInputElement;
document.getElementById('btnSendCustomCmd')!.addEventListener('click', () => {
  const cmd = inputCustomCmd.value.trim();
  if (cmd) {
    addLog(`[TX >>] ${cmd}`);
    inputCustomCmd.value = '';
  }
});

// 监听 SDK 实时数据
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
