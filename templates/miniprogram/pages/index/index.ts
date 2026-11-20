import { ZKBrainMiniProgramSdk } from '@zkteco/zkbrain-miniprogram-sdk';

const sdk = new ZKBrainMiniProgramSdk();

Page({
  data: {
    statusText: '未连接脑电设备',
    isConnected: false,
    isScanning: false,
    attention: 0,
    meditation: 0,
    poorSignal: 200,
    waves: {
      delta: 0,
      theta: 0,
      lowAlpha: 0,
      highAlpha: 0,
      lowBeta: 0,
      highBeta: 0,
      lowGamma: 0,
      middleGamma: 0
    },
    commandInput: 'mems_enable=1;\n',
    commandLogs: '等待下发指令...\n'
  },

  onLoad() {
    sdk.init();

    // 监听脑电数据 (含 8 频段)
    sdk.on('brain_data', (eeg: any) => {
      const bw = eeg.brainWaves || {};
      this.setData({
        attention: eeg.attentionLevel ?? eeg.attention ?? 0,
        meditation: eeg.meditationDepth ?? eeg.meditation ?? 0,
        poorSignal: eeg.signal ?? eeg.poorSignal ?? 200,
        waves: {
          delta: bw.delta ?? eeg.delta ?? 0,
          theta: bw.theta ?? eeg.theta ?? 0,
          lowAlpha: bw.lowAlpha ?? eeg.lowAlpha ?? 0,
          highAlpha: bw.highAlpha ?? eeg.highAlpha ?? 0,
          lowBeta: bw.lowBeta ?? eeg.lowBeta ?? 0,
          highBeta: bw.highBeta ?? eeg.highBeta ?? 0,
          lowGamma: bw.lowGamma ?? eeg.lowGamma ?? 0,
          middleGamma: bw.middleGamma ?? eeg.middleGamma ?? 0
        }
      });
    });

    // 监听连接状态
    sdk.on('connection_state', (state: any) => {
      const connected = state.status === 'CONNECTED';
      this.setData({
        isConnected: connected,
        statusText: connected ? '🟢 脑机设备已就绪' : '未连接设备'
      });
      if (connected) {
        this.appendLog('[系统] 设备连接成功并就绪');
      }
    });
  },

  toggleScan() {
    this.setData({ isScanning: true, statusText: '正在搜索脑电设备...' });
    sdk.startScanAndConnect({
      timeout: 10000,
      onConnected: () => {
        this.setData({ isScanning: false, isConnected: true, statusText: '🟢 脑机设备已就绪' });
      },
      onFailed: (err: any) => {
        this.setData({ isScanning: false, statusText: `连接失败: ${err.message}` });
      }
    });
  },

  appendLog(msg: string) {
    this.setData({
      commandLogs: this.data.commandLogs + msg + '\n'
    });
  },

  onCommandInput(e: any) {
    this.setData({ commandInput: e.detail.value });
  },

  async sendCmd(cmd: string) {
    if (!this.data.isConnected) {
      this.appendLog(`[错误] 设备未连接，无法下发: ${cmd.trim()}`);
      return;
    }
    this.appendLog(`[TX >>] ${cmd.trim()}`);
    try {
      if (typeof (sdk as any).sendAsciiCommand === 'function') {
        await (sdk as any).sendAsciiCommand(cmd);
      } else if (typeof (sdk as any).writeCommand === 'function') {
        await (sdk as any).writeCommand(cmd);
      }
      this.appendLog(`[RX <<] 下发成功: ${cmd.trim()}`);
    } catch (err: any) {
      this.appendLog(`[错误] 下发异常: ${err.message}`);
    }
  },

  handleSendCommand() {
    this.sendCmd(this.data.commandInput);
  },

  handleMemsOn() {
    this.setData({ commandInput: 'mems_enable=1;\n' });
    this.sendCmd('mems_enable=1;\n');
  },

  handleMemsOff() {
    this.setData({ commandInput: 'mems_enable=0;\n' });
    this.sendCmd('mems_enable=0;\n');
  },

  handleIgnition() {
    this.appendLog('[TX >>] 点火包: [0x02, 0x15, 0x17]');
    if (typeof (sdk as any).writeCommand === 'function') {
      const buf = new Uint8Array([0x02, 0x15, 0x17]).buffer;
      (sdk as any).writeCommand(buf);
      this.appendLog('[RX <<] 点火包已下发');
    }
  },

  handleRate512() {
    this.setData({ commandInput: 'eeg_data_rate=1;\n' });
    this.sendCmd('eeg_data_rate=1;\n');
  }
});
