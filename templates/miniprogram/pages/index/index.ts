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
    commandInput: 'mems_on:1',
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

  /**
   * 🌟 微信小程序动态申请蓝牙权限 (scope.bluetooth) 并检测蓝牙适配器状态
   */
  ensureBluetoothPermission(): Promise<boolean> {
    return new Promise((resolve) => {
      wx.getSetting({
        success: (res: any) => {
          const auth = res.authSetting['scope.bluetooth'];
          if (auth === true) {
            this.checkBluetoothAdapter(resolve);
          } else if (auth === false) {
            wx.showModal({
              title: '需要蓝牙权限',
              content: '请在小程序设置中开启“蓝牙”权限，以便搜索并连接脑电设备。',
              confirmText: '去设置',
              success: (modalRes: any) => {
                if (modalRes.confirm) {
                  wx.openSetting({
                    success: (settingRes: any) => {
                      if (settingRes.authSetting['scope.bluetooth']) {
                        this.checkBluetoothAdapter(resolve);
                      } else {
                        resolve(false);
                      }
                    },
                    fail: () => resolve(false)
                  });
                } else {
                  resolve(false);
                }
              }
            });
          } else {
            wx.authorize({
              scope: 'scope.bluetooth',
              success: () => this.checkBluetoothAdapter(resolve),
              fail: () => {
                this.appendLog('[权限拦截] 用户拒绝了小程序蓝牙授权');
                resolve(false);
              }
            });
          }
        },
        fail: () => resolve(false)
      });
    });
  },

  checkBluetoothAdapter(resolve: (ok: boolean) => void) {
    wx.openBluetoothAdapter({
      success: () => resolve(true),
      fail: (err: any) => {
        this.appendLog(`[蓝牙未开启] 请打开手机系统蓝牙开关 (${err.errMsg || err.errCode})`);
        wx.showToast({ title: '请先打开手机蓝牙', icon: 'none' });
        resolve(false);
      }
    });
  },

  async toggleScan() {
    const granted = await this.ensureBluetoothPermission();
    if (!granted) {
      this.setData({ statusText: '未开启蓝牙权限或系统蓝牙' });
      return;
    }

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
      commandLogs: msg + '\n' + this.data.commandLogs
    });
  },

  onCommandInput(e: any) {
    this.setData({ commandInput: e.detail.value });
  },

  async sendConfig(key: string, value: string) {
    if (!this.data.isConnected) {
      this.appendLog(`[错误] 设备未连接，无法下发: ${key}:${value}`);
      return;
    }
    this.appendLog(`[TX >> sendConfig] ${key}:${value}`);
    try {
      if (typeof (sdk as any).sendConfigCommand === 'function') {
        await (sdk as any).sendConfigCommand({ [key]: value });
      } else if (typeof (sdk as any).sendAsciiCommand === 'function') {
        await (sdk as any).sendAsciiCommand(`${key}:${value};\n`);
      }
      this.appendLog(`[RX <<] 下发成功: ${key}:${value}`);
    } catch (err: any) {
      this.appendLog(`[错误] 下发异常: ${err.message}`);
    }
  },

  async sendCmd(cmd: string) {
    const trimmed = cmd.trim();
    if (trimmed.includes(':')) {
      const [k, v] = trimmed.split(':');
      await this.sendConfig(k.trim(), v ? v.trim() : '');
      return;
    }
    if (!this.data.isConnected) {
      this.appendLog(`[错误] 设备未连接，无法下发: ${trimmed}`);
      return;
    }
    this.appendLog(`[TX >>] ${trimmed}`);
    try {
      if (typeof (sdk as any).sendAsciiCommand === 'function') {
        await (sdk as any).sendAsciiCommand(`${trimmed};\n`);
      } else if (typeof (sdk as any).writeCommand === 'function') {
        await (sdk as any).writeCommand(`${trimmed};\n`);
      }
      this.appendLog(`[RX <<] 指令已送达`);
    } catch (err: any) {
      this.appendLog(`[错误] 下发异常: ${err.message}`);
    }
  },

  handleSendCommand() {
    this.sendCmd(this.data.commandInput);
  },

  handleMemsOn() {
    this.setData({ commandInput: 'mems_on:1' });
    this.sendConfig('mems_on', '1');
  },

  handleMemsOff() {
    this.setData({ commandInput: 'mems_on:0' });
    this.sendConfig('mems_on', '0');
  },

  handleRate512() {
    this.setData({ commandInput: 'eeg_data_rate:512' });
    this.sendConfig('eeg_data_rate', '512');
  },

  handleBatteryZk() {
    this.setData({ commandInput: 'battery:?' });
    this.sendConfig('battery', '?');
  },

  handleIgnition() {
    this.appendLog('[TX >> XMW] 点火包 0x15(Raw) + 0x17(Band)');
    if (typeof (sdk as any).writeCommand === 'function') {
      const buf = new Uint8Array([0x02, 0x15, 0x17]).buffer;
      (sdk as any).writeCommand(buf);
      this.appendLog('[RX <<] 点火包已下发');
    }
  },

  handle50Hz() {
    this.appendLog('[TX >> XMW] 0x1B (设置50Hz工频滤波)');
    if (typeof (sdk as any).writeCommand === 'function') {
      const buf = new Uint8Array([0x02, 0x1B]).buffer;
      (sdk as any).writeCommand(buf);
      this.appendLog('[RX <<] 50Hz滤波指令已下发');
    }
  },

  handleBatterySky() {
    this.appendLog('[TX >> XMW] 0x06 (读取静态电量)');
    if (typeof (sdk as any).writeCommand === 'function') {
      const buf = new Uint8Array([0x02, 0x06]).buffer;
      (sdk as any).writeCommand(buf);
      this.appendLog('[RX <<] 电量查询包已下发');
    }
  }
});
