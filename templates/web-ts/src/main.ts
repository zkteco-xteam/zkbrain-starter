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

// 1. 扫描与连接
connectBtn.addEventListener('click', async () => {
  try {
    statusText.innerText = '正在唤起 Web Bluetooth 选择器...';
    await sdk.requestDeviceAndConnect();
    statusText.innerText = '🟢 已连接脑电设备';
    connectBtn.innerText = '已就绪';
    (connectBtn as HTMLButtonElement).disabled = true;
  } catch (err: any) {
    statusText.innerText = `❌ 连接失败: ${err.message}`;
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
