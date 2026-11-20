import { ZKBrainWebSdk } from '@zkteco/zkbrain-web-sdk';

const sdk = new ZKBrainWebSdk();

const statusText = document.getElementById('statusText')!;
const connectBtn = document.getElementById('connectBtn')!;
const attentionVal = document.getElementById('attentionVal')!;
const attentionBar = document.getElementById('attentionBar')!;
const meditationVal = document.getElementById('meditationVal')!;
const meditationBar = document.getElementById('meditationBar')!;
const contactStatus = document.getElementById('contactStatus')!;
const canvas = document.getElementById('waveCanvas') as HTMLCanvasElement;
const ctx = canvas.getContext('2d')!;

// 波形环形缓冲
const waveBuffer: number[] = [];
const MAX_POINTS = 300;

// 1. 扫描与连接 (前置检查 Web Bluetooth 权限环境与蓝牙适配器可用性)
connectBtn.addEventListener('click', async () => {
  if (!navigator.bluetooth) {
    statusText.innerText = '❌ 当前浏览器不支持 Web Bluetooth（请使用 Chrome/Edge 并通过 HTTPS 或 localhost 访问）';
    return;
  }
  try {
    if (typeof navigator.bluetooth.getAvailability === 'function') {
      const available = await navigator.bluetooth.getAvailability();
      if (!available) {
        statusText.innerText = '⚠️ 未检测到可用的系统蓝牙适配器，请打开电脑/手机蓝牙';
        return;
      }
    }
    statusText.innerText = '正在唤起 Web Bluetooth 授权与设备选择器...';
    await sdk.requestDeviceAndConnect();
    statusText.innerText = '🟢 已连接脑电设备';
    connectBtn.innerText = '已就绪';
    (connectBtn as HTMLButtonElement).disabled = true;
  } catch (err: any) {
    statusText.innerText = `❌ 授权或连接失败: ${err.message}`;
  }
});

// 2. 监听 1Hz 综合脑电
sdk.on('brain_data', (eeg: any) => {
  attentionVal.innerText = `${eeg.attention} / 100`;
  attentionBar.style.width = `${eeg.attention}%`;

  meditationVal.innerText = `${eeg.meditation} / 100`;
  meditationBar.style.width = `${eeg.meditation}%`;

  contactStatus.innerHTML = eeg.poorSignal === 0 
    ? '<span style="color: #4ade80;">🟢 良好佩戴 (0)</span>' 
    : `<span style="color: #f87171;">🔴 接触不良 (${eeg.poorSignal})</span>`;

  // 8 频段功率展示
  document.getElementById('pDelta')!.innerText = eeg.delta;
  document.getElementById('pTheta')!.innerText = eeg.theta;
  document.getElementById('pLowAlpha')!.innerText = eeg.lowAlpha;
  document.getElementById('pHighAlpha')!.innerText = eeg.highAlpha;
  document.getElementById('pLowBeta')!.innerText = eeg.lowBeta;
  document.getElementById('pHighBeta')!.innerText = eeg.highBeta;
  document.getElementById('pLowGamma')!.innerText = eeg.lowGamma;
  document.getElementById('pMidGamma')!.innerText = eeg.midGamma;

  const flowBadge = document.getElementById('flowBadge')!;
  if (eeg.attention >= 75 && eeg.meditation >= 60) {
    flowBadge.innerText = '✨ 深度心流';
    flowBadge.style.background = '#22c55e';
  } else if (eeg.attention >= 65) {
    flowBadge.innerText = '🎯 高度专注';
    flowBadge.style.background = '#3b82f6';
  } else {
    flowBadge.innerText = '平静日常';
    flowBadge.style.background = '#f59e0b';
  }
});

// 3. 监听 512Hz 原始脑波
sdk.on('raw_data', (raw: number) => {
  if (waveBuffer.length >= MAX_POINTS) waveBuffer.shift();
  waveBuffer.push(raw);
});

// 4. Canvas 平滑绘制循环
function renderWave() {
  ctx.clearRect(0, 0, canvas.width, canvas.height);
  if (waveBuffer.length > 1) {
    ctx.beginPath();
    ctx.strokeStyle = '#00e676';
    ctx.lineWidth = 2;

    const stepX = canvas.width / MAX_POINTS;
    const centerY = canvas.height / 2;

    waveBuffer.forEach((p, i) => {
      const y = centerY - (p / 1500) * centerY;
      if (i === 0) ctx.moveTo(0, y);
      else ctx.lineTo(i * stepX, y);
    });
    ctx.stroke();
  }
  requestAnimationFrame(renderWave);
}
requestAnimationFrame(renderWave);

// 5. 硬件指令下发与 MEMS 控制台 (遵循《硬件协议集成指南》)
const cmdInput = document.getElementById('cmdInput') as HTMLInputElement;
const sendCmdBtn = document.getElementById('sendCmdBtn')!;
const cmdLogs = document.getElementById('cmdLogs')!;
const btnMemsOn = document.getElementById('btnMemsOn')!;
const btnMemsOff = document.getElementById('btnMemsOff')!;
const btnRate512 = document.getElementById('btnRate512')!;
const btnBatteryZk = document.getElementById('btnBatteryZk')!;
const btnIgnition = document.getElementById('btnIgnition')!;
const btn50Hz = document.getElementById('btn50Hz')!;
const btnBatterySky = document.getElementById('btnBatterySky')!;

function appendLog(msg: string) {
  cmdLogs.innerText = msg + '\n' + cmdLogs.innerText;
}

async function sendConfig(key: string, value: string) {
  try {
    appendLog(`[TX >> sendConfig] ${key}:${value}`);
    if (typeof (sdk as any).sendConfigCommand === 'function') {
      await (sdk as any).sendConfigCommand({ [key]: value });
    } else {
      await (sdk as any).sendAsciiCommand(`${key}:${value};\n`);
    }
    appendLog(`[RX <<] 配置下发成功: ${key}:${value}`);
  } catch (err: any) {
    appendLog(`[错误] 下发失败: ${err.message}`);
  }
}

async function sendCommand(cmd: string) {
  try {
    const trimmed = cmd.trim();
    if (trimmed.includes(':')) {
      const [k, v] = trimmed.split(':');
      await sendConfig(k.trim(), v ? v.trim() : '');
      return;
    }
    appendLog(`[TX >>] ${trimmed}`);
    if (typeof (sdk as any).sendAsciiCommand === 'function') {
      await (sdk as any).sendAsciiCommand(trimmed + ';\n');
    } else if (typeof (sdk as any).writeCommand === 'function') {
      await (sdk as any).writeCommand(trimmed + ';\n');
    }
    appendLog(`[RX <<] 指令下发完成`);
  } catch (err: any) {
    appendLog(`[错误] 下发失败: ${err.message}`);
  }
}

sendCmdBtn?.addEventListener('click', () => {
  if (cmdInput.value) sendCommand(cmdInput.value);
});

btnMemsOn?.addEventListener('click', () => {
  cmdInput.value = 'mems_on:1';
  sendConfig('mems_on', '1');
});

btnMemsOff?.addEventListener('click', () => {
  cmdInput.value = 'mems_on:0';
  sendConfig('mems_on', '0');
});

btnRate512?.addEventListener('click', () => {
  cmdInput.value = 'eeg_data_rate:512';
  sendConfig('eeg_data_rate', '512');
});

btnBatteryZk?.addEventListener('click', () => {
  cmdInput.value = 'battery:?';
  sendConfig('battery', '?');
});

btnIgnition?.addEventListener('click', async () => {
  try {
    appendLog('[TX >> XMW] 点火包 0x15(Raw) + 0x17(Band)');
    if (typeof (sdk as any).writeCommand === 'function') {
      await (sdk as any).writeCommand(new Uint8Array([0x02, 0x15, 0x17]));
    }
    appendLog('[RX <<] 点火包已送达物理层');
  } catch (err: any) {
    appendLog(`[错误] 点火失败: ${err.message}`);
  }
});

btn50Hz?.addEventListener('click', async () => {
  try {
    appendLog('[TX >> XMW] 0x1B (设置50Hz工频滤波)');
    if (typeof (sdk as any).writeCommand === 'function') {
      await (sdk as any).writeCommand(new Uint8Array([0x02, 0x1B]));
    }
    appendLog('[RX <<] 50Hz滤波指令已下发');
  } catch (err: any) {
    appendLog(`[错误] 50Hz滤波失败: ${err.message}`);
  }
});

btnBatterySky?.addEventListener('click', async () => {
  try {
    appendLog('[TX >> XMW] 0x06 (读取静态电量)');
    if (typeof (sdk as any).writeCommand === 'function') {
      await (sdk as any).writeCommand(new Uint8Array([0x02, 0x06]));
    }
    appendLog('[RX <<] 电量查询包已发送');
  } catch (err: any) {
    appendLog(`[错误] 失败: ${err.message}`);
  }
});
