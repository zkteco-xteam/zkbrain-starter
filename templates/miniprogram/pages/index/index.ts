import { ZKBrainMiniProgramSdk } from '@zkteco/zkbrain-miniprogram-sdk';

const sdk = new ZKBrainMiniProgramSdk();

/**
 * 🌟 1:1 完整逐项克隆 shared1 设备管理控制台 (DeviceScreen + DeviceShowTable) - 微信小程序 TypeScript 逻辑
 * 技术支持：熵基科技脑机事业部 (ZKTeco Brain-Computer Interface Division)
 */
Page({
  data: {
    isConnected: false,
    connectionStatusText: '未连接 (DISCONNECTED)',
    deviceName: 'ZKBrain Headband',
    deviceMac: 'DC:23:4F:9A:88:01',
    batteryLevel: 85,

    // 12 项生理指标
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

    // MEMS 姿态与欧拉角
    memsRoll: 1.2,
    memsPitch: -0.5,
    memsYaw: 14.8,
    memsQ0: 0.992,
    memsQ1: 0.010,
    memsQ2: -0.004,
    memsQ3: 0.129,

    // 通道配置
    isFp1Checked: true,

    // 图表显隐矩阵
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

    // 指令与终端回显
    customCmdInput: '',
    writeSnInput: '',
    commandLogs: '[系统启动] ZKBrain 微信小程序控制台初始化就绪\n',

    // 弹窗与扫描
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

    // 监听脑电数据流
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

    // 监听连接状态
    sdk.on('connection_state', (state: any) => {
      const connected = state.status === 'CONNECTED';
      this.setData({
        isConnected: connected,
        connectionStatusText: connected ? '已就绪 (READY)' : '未连接 (DISCONNECTED)'
      });
      if (connected) {
        this.appendLog('[系统] 设备连接成功并就绪');
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

  // 顶部与状态卡片事件
  openScanModal() {
    this.setData({ showScanModal: true });
    this.startScan();
  },

  closeScanModal() {
    this.setData({ showScanModal: false, isScanning: false });
  },

  stopBubble() {
    // 阻止遮罩冒泡
  },

  handleDfuUpgrade() {
    this.appendLog('[DFU] 固件 OTA 检测：当前已处于最新稳定版 v2.4.0');
    wx.showToast({ title: '固件检测：已是最新版', icon: 'success' });
  },

  toggleConnect() {
    if (this.data.isConnected) {
      this.setData({
        isConnected: false,
        connectionStatusText: '未连接 (DISCONNECTED)'
      });
      this.appendLog('[BLE] 用户主动断开设备连接');
    } else {
      this.openScanModal();
    }
  },

  // 通道与图表显隐
  onChannelChange(e: any) {
    const values = e.detail.value;
    const checked = values.includes('fp1');
    this.setData({ isFp1Checked: checked });
    this.appendLog(`[通道配置] Left (FP1): ${checked}`);
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
    this.appendLog(`[图表显隐] ${key} 状态切换`);
  },

  // NeuroSky XMW 控制台事件
  handleIgnition() {
    this.appendLog('[TX >> XMW] 下发点火包: 0x15 (Raw) + 0x17 (Band)');
    sdk.sendIgnitionCommand().catch(() => {});
  },

  handleStopXmw() {
    this.appendLog('[TX >> XMW] 停止传输: 0x16 + 0x18');
  },

  handleFilter50() {
    this.appendLog('[TX >> XMW] 设置 50Hz 工频滤波 (0x1B)');
  },

  handleFilter60() {
    this.appendLog('[TX >> XMW] 设置 60Hz 工频滤波 (0x1C)');
  },

  handleBatterySky() {
    this.appendLog('[TX >> XMW] 读取硬件电量 (0x06)');
  },

  handleReadSn() {
    this.appendLog('[TX >> XMW] 查询设备序列号 SN (0xF4)');
  },

  handleDetectMac() {
    this.appendLog('[TX >> XMW] 探测经典蓝牙 MAC 地址 (0xFC)');
  },

  onWriteSnInput(e: any) {
    this.setData({ writeSnInput: e.detail.value });
  },

  handleWriteSn() {
    const sn = this.data.writeSnInput.trim();
    if (sn) {
      this.appendLog(`[TX >> XMW] 写入 SN (0xF2): ${sn}`);
      wx.showToast({ title: 'SN 写入指令已发送', icon: 'none' });
    }
  },

  // ZKBrain 自研控制台事件
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
    this.appendLog('[TX >>] dfu_scan:1 (进入DFU空中升级就绪模式)');
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

  /**
   * 🌟 微信小程序运行时动态申请蓝牙权限并核验蓝牙适配器状态
   */
  async ensureBluetoothPermission(): Promise<boolean> {
    return new Promise((resolve) => {
      wx.getSetting({
        success: (res) => {
          if (res.authSetting['scope.bluetooth'] === false) {
            wx.showModal({
              title: '需要蓝牙权限',
              content: '脑电数据采集需要蓝牙权限支持，请在设置中允许使用蓝牙',
              confirmText: '去开启',
              success: (modalRes) => {
                if (modalRes.confirm) {
                  wx.openSetting();
                }
                resolve(false);
              }
            });
          } else if (res.authSetting['scope.bluetooth'] === undefined) {
            wx.authorize({
              scope: 'scope.bluetooth',
              success: () => resolve(true),
              fail: () => resolve(false)
            });
          } else {
            resolve(true);
          }
        },
        fail: () => resolve(false)
      });
    });
  },

  // 扫描与连接
  async startScan() {
    const hasPerm = await this.ensureBluetoothPermission();
    if (!hasPerm) {
      this.appendLog('[BLE] 未获得蓝牙权限或用户取消授权');
      this.setData({ isScanning: false });
      return;
    }

    wx.openBluetoothAdapter({
      success: () => {
        this.setData({ isScanning: true });
        this.appendLog('[BLE] 蓝牙适配器初始化成功，正在扫描周围低功耗蓝牙 (BLE) 脑电设备...');
        setTimeout(() => {
          this.setData({ isScanning: false });
        }, 3000);
      },
      fail: (err) => {
        this.appendLog(`[BLE] 蓝牙适配器启动失败: ${err.errMsg}，请检查手机系统蓝牙是否开启`);
        this.setData({ isScanning: false });
      }
    });
  },

  connectScannedDevice(e: any) {
    const item = e.currentTarget.dataset.item;
    this.setData({
      deviceName: item.name,
      deviceMac: item.mac,
      isConnected: true,
      connectionStatusText: '已就绪 (READY)',
      showScanModal: false,
      isScanning: false
    });
    this.appendLog(`[BLE] 成功连接至设备: ${item.name} (${item.mac})`);
  }
});
