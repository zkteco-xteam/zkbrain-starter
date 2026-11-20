import { ZKBrainMiniProgramSdk } from '@zkteco/zkbrain-miniprogram-sdk';

const sdk = new ZKBrainMiniProgramSdk();

Page({
  data: {
    statusText: '未连接脑电设备',
    isConnected: false,
    isScanning: false,
    attention: 0,
    meditation: 0,
    poorSignal: 200
  },

  onLoad() {
    sdk.init();

    // 监听脑电数据
    sdk.on('brain_data', (eeg: any) => {
      this.setData({
        attention: eeg.attention,
        meditation: eeg.meditation,
        poorSignal: eeg.poorSignal
      });
    });

    // 监听连接状态
    sdk.on('connection_state', (state: any) => {
      this.setData({
        isConnected: state.status === 'CONNECTED',
        statusText: state.status === 'CONNECTED' ? '🟢 脑机设备已就绪' : '未连接设备'
      });
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
  }
});
