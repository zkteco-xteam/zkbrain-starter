<template>
  <view class="container">
    <!-- 板块 1：顶部操作栏 (Header Bar) -->
    <view class="header-bar">
      <view class="header-title">设备管理 (DeviceScreen)</view>
      <view class="header-actions">
        <button class="btn-top btn-search" @tap="openScanModal">🔍 搜索设备</button>
        <button class="btn-top btn-dfu" @tap="handleDfuUpgrade">OTA升级</button>
        <view class="badge-auth">✓ SN就绪</view>
      </view>
    </view>

    <!-- 板块 2：设备链路状态卡片 (Status Card) -->
    <view class="card">
      <view class="status-row">
        <view class="status-badge-wrap">
          <view class="status-dot" :class="{ connected: isConnected }"></view>
          <text class="status-text" :class="{ connected: isConnected }">
            {{ isConnected ? "已连接 (CONNECTED)" : "未连接 (DISCONNECTED)" }}
          </text>
        </view>
        <view class="battery-capsule">⚡ {{ batteryLevel }}%</view>
      </view>

      <view class="device-name">{{ deviceName }}</view>
      <view class="device-mac">MAC: {{ deviceMac }}</view>

      <view class="badges-row">
        <view class="chip chip-blue">Nordic BLE 5.0</view>
        <view class="chip chip-teal">ASCII 512Hz</view>
        <view class="chip chip-purple">NeuroSky XMW</view>
      </view>

      <button
        class="btn-connect"
        :class="{ connected: isConnected }"
        @tap="toggleConnect"
      >
        {{ isConnected ? "断开当前连接" : "连接设备" }}
      </button>
    </view>

    <!-- 板块 3：硬件通道配置 -->
    <view class="card">
      <view class="card-title">🎧 脑电测量通道 (Channels)</view>
      <view class="card-subtitle">单导联额贴固定使用前额左侧 (FP1) 测量点</view>
      <view class="channel-options">
        <label class="channel-label">
          <switch :checked="isFp1Checked" color="#2563eb" @change="onChannelChange" />
          <text>Left (FP1) [激活中]</text>
        </label>
        <label class="channel-label disabled">
          <switch :checked="false" disabled />
          <text>Right (FP2) [硬件不支持]</text>
        </label>
      </view>
    </view>

    <!-- 板块 4：图表显隐过滤矩阵 -->
    <view class="card">
      <view class="card-title">📊 12项生理指标图表显隐过滤</view>
      <view class="card-subtitle">实时联动控制下方 4x3 三色脑电指标表格</view>
      <view class="chart-chips">
        <view
          v-for="item in chartToggles"
          :key="item.key"
          class="chart-chip-btn"
          :class="{ active: item.checked }"
          @tap="toggleChartItem(item.key)"
        >
          {{ item.checked ? "✓ " : "" }}{{ item.key }}
        </view>
      </view>
    </view>

    <!-- 板块 5：NeuroSky XMW 二进制协议硬件控制台 -->
    <view class="card">
      <view class="card-title">⚡ NeuroSky XMW 二进制硬件控制台</view>
      <view class="card-subtitle">直接控制 TGAM / MindWave 芯片底层寄存器与传输开关</view>
      <view class="btn-console-grid">
        <button class="btn-act act-green" @tap="handleIgnition">点火包 (0x15+0x17)</button>
        <button class="btn-act act-red" @tap="handleStopXmw">停止传输 (0x16+0x18)</button>
        <button class="btn-act act-blue" @tap="handleFilter50Hz">50Hz 陷波 (0x1B)</button>
        <button class="btn-act act-blue" @tap="handleFilter60Hz">60Hz 陷波 (0x1C)</button>
        <button class="btn-act act-orange" @tap="handleQueryBatterySky">读电量 (0x06)</button>
        <button class="btn-act act-gray" @tap="handleQuerySn">查询 SN (0xF4)</button>
        <button class="btn-act act-teal" @tap="handleDetectMac">探测经典MAC (0xFC)</button>
      </view>

      <view class="input-row">
        <input
          v-model="writeSnInput"
          class="input-field"
          placeholder="输入新设备 SN (例如: ZK20261120001)"
        />
        <button class="btn-sn-send" @tap="handleWriteSn">写入 SN (0xF2)</button>
      </view>
    </view>

    <!-- 板块 6：ZKBrain 自研脑电设备官方控制台 -->
    <view class="card">
      <view class="card-title">🧠 ZKBrain 自研脑电设备官方控制台</view>
      <view class="card-subtitle">支持 ASCII 控制指令与 MEMS 6轴姿态惯导流</view>

      <!-- MEMS 传感器姿态看板 -->
      <view class="mems-box">
        <view class="mems-header">🧭 MEMS 传感器 6 轴空间姿态 (Euler 欧拉角 & 四元数):</view>
        <view class="mems-text">
          Roll(横滚): {{ memsRoll }}° | Pitch(俯仰): {{ memsPitch }}° | Yaw(偏航): {{ memsYaw }}°
        </view>
        <view class="mems-text text-dim">
          Q0: {{ memsQ0 }} | Q1: {{ memsQ1 }} | Q2: {{ memsQ2 }} | Q3: {{ memsQ3 }}
        </view>
      </view>

      <view class="btn-console-grid">
        <button class="btn-act act-gray" @tap="handleQueryLicense">license:?</button>
        <button class="btn-act act-orange" @tap="handleQueryBatteryZk">battery:?</button>
        <button class="btn-act act-gray" @tap="handleQueryVersion">version:?</button>
        <button class="btn-act act-green" @tap="handleEegOn">eeg_data_on:1</button>
        <button class="btn-act act-red" @tap="handleEegOff">eeg_data_on:0</button>
        <button class="btn-act act-blue" @tap="handleRate256">256Hz (rate:2)</button>
        <button class="btn-act act-blue" @tap="handleRate512">512Hz (rate:1)</button>
        <button class="btn-act act-purple" @tap="handleMemsOn">开启 MEMS (mems_on:1)</button>
        <button class="btn-act act-gray" @tap="handleMemsOff">关闭 MEMS (mems_on:0)</button>
        <button class="btn-act act-orange" @tap="handleDfuScan">空中升级 (dfu_scan:1)</button>
      </view>

      <view class="input-row">
        <input
          v-model="customCmdInput"
          class="input-field"
          placeholder="自定义指令 (例如: mems_on:1 或 led:1)"
        />
        <button class="btn-input-send" @tap="handleSendCustomCmd">发送指令</button>
      </view>

      <!-- 终端回包监控 -->
      <view class="terminal-box">
        <view class="terminal-header">
          <text>💻 指令下发与硬件回包监控终端:</text>
          <text class="btn-clear" @tap="clearLogs">清空</text>
        </view>
        <scroll-view scroll-y class="terminal-logs" :scroll-top="9999">
          <text>{{ commandLogs }}</text>
        </scroll-view>
      </view>
    </view>

    <!-- 板块 7：DeviceShowTable 4x3 三色脑电指标表格 -->
    <view class="card">
      <view class="card-title">📈 4x3 全波段三色脑电数据表 (DeviceShowTable)</view>
      <view class="card-subtitle">
        1:1 逐项还原 shared1 测量看板；粉色：认知与信号，青色：慢波与Alpha，黄色：高频能谱
      </view>

      <view class="table-mac-header">MAC: {{ deviceMac }}</view>

      <view class="table-container">
        <!-- Row 1: Attention(粉) | Meditation(粉) | SignalQuality(粉) -->
        <view class="table-row">
          <view class="table-cell bg-pink">
            <view class="cell-label">Attention</view>
            <view class="cell-val">{{ attention }}</view>
          </view>
          <view class="table-cell bg-pink">
            <view class="cell-label">Meditation</view>
            <view class="cell-val">{{ meditation }}</view>
          </view>
          <view class="table-cell bg-pink">
            <view class="cell-label">Quality</view>
            <view class="cell-val">{{ signalQuality }}</view>
          </view>
        </view>

        <!-- Row 2: Raw EEG(粉) | Delta(青) | Theta(青) -->
        <view class="table-row">
          <view class="table-cell bg-pink">
            <view class="cell-label">Raw EEG</view>
            <view class="cell-val">{{ rawEeg }}</view>
          </view>
          <view class="table-cell bg-cyan">
            <view class="cell-label">Delta</view>
            <view class="cell-val">{{ waves.delta }}</view>
          </view>
          <view class="table-cell bg-cyan">
            <view class="cell-label">Theta</view>
            <view class="cell-val">{{ waves.theta }}</view>
          </view>
        </view>

        <!-- Row 3: Low Alpha(青) | High Alpha(青) | Low Beta(黄) -->
        <view class="table-row">
          <view class="table-cell bg-cyan">
            <view class="cell-label">Low Alpha</view>
            <view class="cell-val">{{ waves.lowAlpha }}</view>
          </view>
          <view class="table-cell bg-cyan">
            <view class="cell-label">High Alpha</view>
            <view class="cell-val">{{ waves.highAlpha }}</view>
          </view>
          <view class="table-cell bg-yellow">
            <view class="cell-label">Low Beta</view>
            <view class="cell-val">{{ waves.lowBeta }}</view>
          </view>
        </view>

        <!-- Row 4: High Beta(黄) | Low Gamma(黄) | Mid Gamma(黄) -->
        <view class="table-row">
          <view class="table-cell bg-yellow">
            <view class="cell-label">High Beta</view>
            <view class="cell-val">{{ waves.highBeta }}</view>
          </view>
          <view class="table-cell bg-yellow">
            <view class="cell-label">Low Gamma</view>
            <view class="cell-val">{{ waves.lowGamma }}</view>
          </view>
          <view class="table-cell bg-yellow">
            <view class="cell-label">Mid Gamma</view>
            <view class="cell-val">{{ waves.middleGamma }}</view>
          </view>
        </view>
      </view>
    </view>

    <!-- 板块 8：蓝牙搜索连接弹窗 (Scan Modal) -->
    <view v-if="showScanModal" class="modal-mask" @tap="closeScanModal">
      <view class="modal-content" @tap.stop>
        <view class="modal-header">
          <text class="modal-title">🔍 搜索周围低功耗蓝牙脑电设备</text>
          <text class="modal-close" @tap="closeScanModal">✕</text>
        </view>

        <view class="modal-status">
          <text>{{ isScanning ? "正在扫描周围 BLE 设备..." : "扫描完成，请点击连接" }}</text>
        </view>

        <scroll-view scroll-y class="device-list">
          <view
            v-for="item in scannedDevices"
            :key="item.mac"
            class="device-item"
          >
            <view class="device-info">
              <text class="item-name">{{ item.name }}</text>
              <text class="item-mac">{{ item.mac }} | RSSI: {{ item.rssi }} dBm</text>
            </view>
            <button class="btn-item-connect" @tap="connectScannedDevice(item)">连接</button>
          </view>
        </scroll-view>

        <button class="btn-rescan" :disabled="isScanning" @tap="startScan">
          {{ isScanning ? "正在搜索中..." : "重新扫描周边设备" }}
        </button>
      </view>
    </view>
  </view>
</template>

<script setup lang="ts">
import { ref, reactive, onMounted, onUnmounted } from "vue";

// 链路与设备状态
const isConnected = ref(false);
const deviceName = ref("ZKBrain Headband PRO");
const deviceMac = ref("DC:23:4F:9A:88:01");
const batteryLevel = ref(85);

// 12项生理指标
const attention = ref(78);
const meditation = ref(65);
const signalQuality = ref(0);
const rawEeg = ref(136);

const waves = reactive({
  delta: 14200,
  theta: 8900,
  lowAlpha: 16100,
  highAlpha: 21800,
  lowBeta: 19500,
  highBeta: 11200,
  lowGamma: 4800,
  middleGamma: 2200,
});

// MEMS 姿态与欧拉角
const memsRoll = ref(1.2);
const memsPitch = ref(-0.5);
const memsYaw = ref(14.8);
const memsQ0 = ref(0.992);
const memsQ1 = ref(0.01);
const memsQ2 = ref(-0.004);
const memsQ3 = ref(0.129);

// 通道与图表显隐
const isFp1Checked = ref(true);

const chartToggles = reactive([
  { key: "Raw EEG", checked: true },
  { key: "Signal Quality", checked: true },
  { key: "Attention", checked: true },
  { key: "Meditation", checked: true },
  { key: "Delta", checked: true },
  { key: "Theta", checked: true },
  { key: "Low Alpha", checked: true },
  { key: "High Alpha", checked: true },
  { key: "Low Beta", checked: true },
  { key: "High Beta", checked: true },
  { key: "Low Gamma", checked: true },
  { key: "Middle Gamma", checked: true },
]);

// 终端监控与指令
const writeSnInput = ref("");
const customCmdInput = ref("");
const commandLogs = ref("[系统启动] ZKBrain Uni-app (Vue 3 + TS) 控制台初始化就绪\n");

// 弹窗与蓝牙扫描
const showScanModal = ref(false);
const isScanning = ref(false);
const scannedDevices = reactive([
  { name: "ZKBrain-PRO-8801", mac: "DC:23:4F:9A:88:01", rssi: -58 },
  { name: "MindWave Mobile 2", mac: "AA:BB:CC:11:22:33", rssi: -72 },
  { name: "ZKBrain Headband Lite", mac: "DC:23:4F:55:66:77", rssi: -64 },
]);

let mockTimer: any = null;

onMounted(() => {
  appendLog("[BLE] 系统准备就绪，支持微信/支付宝/抖音小程序及 App 多端蓝牙");
  // 模拟心跳脑电数据流
  mockTimer = setInterval(() => {
    if (isConnected.value) {
      attention.value = Math.min(100, Math.max(10, attention.value + Math.floor((Math.random() - 0.5) * 6)));
      meditation.value = Math.min(100, Math.max(10, meditation.value + Math.floor((Math.random() - 0.5) * 6)));
      rawEeg.value = Math.floor((Math.random() - 0.5) * 240);
    }
  }, 1000);
});

onUnmounted(() => {
  if (mockTimer) clearInterval(mockTimer);
});

function appendLog(msg: string) {
  commandLogs.value += msg + "\n";
}

function clearLogs() {
  commandLogs.value = "";
}

// 🌟 统一运行时蓝牙权限与蓝牙适配器核验
async function ensureBluetoothPermission(): Promise<boolean> {
  return new Promise((resolve) => {
    // #ifdef MP-WEIXIN
    uni.getSetting({
      success: (res) => {
        if (res.authSetting["scope.bluetooth"] === false) {
          uni.showModal({
            title: "需要蓝牙权限",
            content: "连接脑电设备需要系统蓝牙权限，请在设置中开启",
            confirmText: "去开启",
            success: (modalRes) => {
              if (modalRes.confirm) uni.openSetting();
              resolve(false);
            },
          });
        } else if (res.authSetting["scope.bluetooth"] === undefined) {
          uni.authorize({
            scope: "scope.bluetooth",
            success: () => resolve(true),
            fail: () => resolve(false),
          });
        } else {
          resolve(true);
        }
      },
      fail: () => resolve(false),
    });
    // #endif

    // #ifndef MP-WEIXIN
    resolve(true);
    // #endif
  });
}

async function startScan() {
  const ok = await ensureBluetoothPermission();
  if (!ok) {
    appendLog("[BLE] 未获得蓝牙权限或用户取消授权");
    return;
  }

  uni.openBluetoothAdapter({
    success: () => {
      isScanning.value = true;
      appendLog("[BLE] 蓝牙适配器启动成功，正在扫描周边脑电设备...");
      setTimeout(() => {
        isScanning.value = false;
        appendLog("[BLE] 扫描完成，发现 3 台可用脑电设备");
      }, 2500);
    },
    fail: (err) => {
      appendLog(`[BLE] 蓝牙适配器开启失败: ${err.errMsg}，请检查系统蓝牙开关`);
      isScanning.value = false;
    },
  });
}

function openScanModal() {
  showScanModal.value = true;
  startScan();
}

function closeScanModal() {
  showScanModal.value = false;
  isScanning.value = false;
}

function connectScannedDevice(item: any) {
  deviceName.value = item.name;
  deviceMac.value = item.mac;
  isConnected.value = true;
  showScanModal.value = false;
  isScanning.value = false;
  appendLog(`[BLE] 成功建立连接: ${item.name} (${item.mac})`);
}

function toggleConnect() {
  if (isConnected.value) {
    isConnected.value = false;
    appendLog("[BLE] 用户主动断开设备连接");
  } else {
    openScanModal();
  }
}

function handleDfuUpgrade() {
  appendLog("[DFU] 发起固件 OTA 检测：当前已处于最新稳定版 v2.4.0");
  uni.showToast({ title: "固件检测：已是最新版", icon: "success" });
}

function onChannelChange(e: any) {
  isFp1Checked.value = e.detail.value;
  appendLog(`[通道配置] Left (FP1): ${isFp1Checked.value}`);
}

function toggleChartItem(key: string) {
  const target = chartToggles.find((item) => item.key === key);
  if (target) {
    target.checked = !target.checked;
    appendLog(`[图表显隐] ${key} 状态切换为: ${target.checked}`);
  }
}

// NeuroSky XMW 指令
function handleIgnition() {
  appendLog("[TX >> XMW] 下发点火包: 0x15 (Raw) + 0x17 (Band)");
}
function handleStopXmw() {
  appendLog("[TX >> XMW] 停止数据传输 (0x16 + 0x18)");
}
function handleFilter50Hz() {
  appendLog("[TX >> XMW] 设置 50Hz 工频陷波滤波 (0x1B)");
}
function handleFilter60Hz() {
  appendLog("[TX >> XMW] 设置 60Hz 工频陷波滤波 (0x1C)");
}
function handleQueryBatterySky() {
  appendLog("[TX >> XMW] 读取硬件电量 (0x06)");
}
function handleQuerySn() {
  appendLog("[TX >> XMW] 查询序列号 SN (0xF4)");
}
function handleDetectMac() {
  appendLog("[TX >> XMW] 探测经典蓝牙 MAC 地址 (0xFC)");
}
function handleWriteSn() {
  const sn = writeSnInput.value.trim();
  if (sn) {
    appendLog(`[TX >> XMW] 写入 SN (0xF2): ${sn}`);
    uni.showToast({ title: `SN 已下发: ${sn}`, icon: "none" });
  }
}

// ZKBrain 指令
function handleQueryLicense() {
  appendLog("[TX >>] license:?");
}
function handleQueryBatteryZk() {
  appendLog("[TX >>] battery:?");
}
function handleQueryVersion() {
  appendLog("[TX >>] version:?");
}
function handleEegOn() {
  appendLog("[TX >>] eeg_data_on:1");
}
function handleEegOff() {
  appendLog("[TX >>] eeg_data_on:0");
}
function handleRate256() {
  appendLog("[TX >>] eeg_data_rate:2 (256Hz)");
}
function handleRate512() {
  appendLog("[TX >>] eeg_data_rate:1 (512Hz)");
}
function handleMemsOn() {
  appendLog("[TX >>] mems_on:1 (开启MEMS空间姿态流)");
}
function handleMemsOff() {
  appendLog("[TX >>] mems_on:0 (关闭MEMS空间姿态流)");
}
function handleDfuScan() {
  appendLog("[TX >>] dfu_scan:1 (进入DFU固件升级广播模式)");
}
function handleSendCustomCmd() {
  const cmd = customCmdInput.value.trim();
  if (cmd) {
    appendLog(`[TX >>] ${cmd}`);
    customCmdInput.value = "";
  }
}
</script>

<style scoped>
.container {
  padding: 24rpx;
  max-width: 900rpx;
  margin: 0 auto;
}

/* 顶部操作栏 */
.header-bar {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 20rpx;
}
.header-title {
  font-size: 32rpx;
  font-weight: bold;
  color: #0f172a;
}
.header-actions {
  display: flex;
  align-items: center;
  gap: 12rpx;
}
.btn-top {
  font-size: 22rpx;
  padding: 6rpx 16rpx;
  height: 52rpx;
  line-height: 52rpx;
  margin: 0;
  border-radius: 8rpx;
  color: white;
}
.btn-search {
  background-color: #2563eb;
}
.btn-dfu {
  background-color: #475569;
}
.badge-auth {
  font-size: 20rpx;
  font-weight: bold;
  color: #16a34a;
  background-color: #dcfce7;
  border: 1rpx solid #86efac;
  padding: 4rpx 10rpx;
  border-radius: 6rpx;
}

/* 卡片基类 */
.card {
  background-color: #ffffff;
  border-radius: 16rpx;
  padding: 24rpx;
  margin-bottom: 20rpx;
  box-shadow: 0 2rpx 8rpx rgba(0, 0, 0, 0.04);
}
.card-title {
  font-size: 28rpx;
  font-weight: bold;
  color: #1e293b;
  margin-bottom: 6rpx;
}
.card-subtitle {
  font-size: 22rpx;
  color: #64748b;
  margin-bottom: 16rpx;
}

/* 状态卡片 */
.status-row {
  display: flex;
  justify-content: space-between;
  align-items: center;
}
.status-badge-wrap {
  display: flex;
  align-items: center;
  gap: 12rpx;
}
.status-dot {
  width: 16rpx;
  height: 16rpx;
  border-radius: 50%;
  background-color: #ef4444;
}
.status-dot.connected {
  background-color: #22c55e;
}
.status-text {
  font-size: 26rpx;
  font-weight: bold;
  color: #dc2626;
}
.status-text.connected {
  color: #16a34a;
}
.battery-capsule {
  background-color: #dcfce7;
  border: 1rpx solid #86efac;
  border-radius: 20rpx;
  padding: 4rpx 14rpx;
  font-size: 22rpx;
  font-weight: bold;
  color: #16a34a;
}
.device-name {
  font-size: 32rpx;
  font-weight: bold;
  color: #0f172a;
  margin-top: 12rpx;
}
.device-mac {
  font-size: 22rpx;
  color: #64748b;
  margin: 6rpx 0 16rpx 0;
  font-family: monospace;
}
.badges-row {
  display: flex;
  gap: 12rpx;
  margin-bottom: 20rpx;
}
.chip {
  font-size: 20rpx;
  font-weight: 600;
  padding: 4rpx 12rpx;
  border-radius: 6rpx;
}
.chip-blue {
  background: rgba(2, 132, 199, 0.12);
  color: #0284c7;
  border: 1rpx solid rgba(2, 132, 199, 0.3);
}
.chip-teal {
  background: rgba(13, 148, 136, 0.12);
  color: #0d9488;
  border: 1rpx solid rgba(13, 148, 136, 0.3);
}
.chip-purple {
  background: rgba(124, 58, 237, 0.12);
  color: #7c3aed;
  border: 1rpx solid rgba(124, 58, 237, 0.3);
}
.btn-connect {
  width: 100%;
  height: 72rpx;
  line-height: 72rpx;
  font-size: 26rpx;
  font-weight: bold;
  border-radius: 12rpx;
  background-color: #2563eb;
  color: white;
}
.btn-connect.connected {
  background-color: #dc2626;
}

/* 通道 */
.channel-options {
  display: flex;
  gap: 30rpx;
}
.channel-label {
  display: flex;
  align-items: center;
  gap: 10rpx;
  font-size: 24rpx;
  color: #1e293b;
}
.channel-label.disabled {
  color: #94a3b8;
}

/* 图表芯片 */
.chart-chips {
  display: flex;
  flex-wrap: wrap;
  gap: 12rpx;
}
.chart-chip-btn {
  padding: 8rpx 16rpx;
  font-size: 22rpx;
  border-radius: 10rpx;
  border: 1rpx solid #cbd5e1;
  background-color: #f1f5f9;
  color: #334155;
}
.chart-chip-btn.active {
  background-color: #2563eb;
  color: white;
  border-color: #2563eb;
}

/* 按钮网格 */
.btn-console-grid {
  display: flex;
  flex-wrap: wrap;
  gap: 12rpx;
  margin-bottom: 16rpx;
}
.btn-act {
  font-size: 22rpx;
  height: 56rpx;
  line-height: 56rpx;
  padding: 0 18rpx;
  margin: 0;
  border-radius: 10rpx;
  border: 1rpx solid transparent;
}
.act-green {
  background-color: rgba(22, 163, 74, 0.12);
  color: #16a34a;
  border-color: rgba(22, 163, 74, 0.3);
}
.act-red {
  background-color: rgba(220, 38, 38, 0.12);
  color: #dc2626;
  border-color: rgba(220, 38, 38, 0.3);
}
.act-blue {
  background-color: rgba(2, 132, 199, 0.12);
  color: #0284c7;
  border-color: rgba(2, 132, 199, 0.3);
}
.act-orange {
  background-color: rgba(217, 119, 6, 0.12);
  color: #d97706;
  border-color: rgba(217, 119, 6, 0.3);
}
.act-gray {
  background-color: rgba(71, 85, 105, 0.1);
  color: #475569;
  border-color: rgba(71, 85, 105, 0.3);
}
.act-purple {
  background-color: rgba(124, 58, 237, 0.12);
  color: #7c3aed;
  border-color: rgba(124, 58, 237, 0.3);
}
.act-teal {
  background-color: rgba(13, 148, 136, 0.12);
  color: #0d9488;
  border-color: rgba(13, 148, 136, 0.3);
}

/* 输入行 */
.input-row {
  display: flex;
  gap: 12rpx;
  margin-top: 12rpx;
}
.input-field {
  flex: 1;
  height: 64rpx;
  background-color: #f8fafc;
  border: 1rpx solid #cbd5e1;
  border-radius: 10rpx;
  padding: 0 16rpx;
  font-size: 24rpx;
}
.btn-input-send {
  font-size: 22rpx;
  height: 64rpx;
  line-height: 64rpx;
  background-color: #2563eb;
  color: white;
  padding: 0 24rpx;
  margin: 0;
  border-radius: 10rpx;
}
.btn-sn-send {
  font-size: 22rpx;
  height: 64rpx;
  line-height: 64rpx;
  background-color: #0f172a;
  color: white;
  padding: 0 24rpx;
  margin: 0;
  border-radius: 10rpx;
}

/* MEMS 姿态卡片 */
.mems-box {
  background-color: #f8fafc;
  border: 1rpx solid #e2e8f0;
  border-radius: 12rpx;
  padding: 16rpx;
  margin-bottom: 16rpx;
}
.mems-header {
  font-size: 24rpx;
  font-weight: bold;
  color: #334155;
  margin-bottom: 8rpx;
}
.mems-text {
  font-family: monospace;
  font-size: 22rpx;
  color: #1e293b;
  line-height: 1.5;
}
.text-dim {
  color: #64748b;
}

/* 终端监控 */
.terminal-box {
  background-color: #0f172a;
  border-radius: 14rpx;
  padding: 18rpx;
  margin-top: 18rpx;
}
.terminal-header {
  display: flex;
  justify-content: space-between;
  font-size: 22rpx;
  color: #94a3b8;
  margin-bottom: 10rpx;
}
.btn-clear {
  color: #38bdf8;
  cursor: pointer;
}
.terminal-logs {
  height: 180rpx;
  font-family: monospace;
  font-size: 20rpx;
  color: #4ade80;
  line-height: 1.4;
}

/* DeviceShowTable 4x3 三色表格 */
.table-mac-header {
  background-color: #1e293b;
  color: white;
  text-align: center;
  font-family: monospace;
  font-size: 24rpx;
  font-weight: bold;
  padding: 12rpx 0;
  border-radius: 10rpx;
  margin-bottom: 14rpx;
}
.table-container {
  border: 1rpx solid #cbd5e1;
  border-radius: 6rpx;
  overflow: hidden;
}
.table-row {
  display: flex;
  border-bottom: 1rpx solid #cbd5e1;
}
.table-row:last-child {
  border-bottom: none;
}
.table-cell {
  flex: 1;
  padding: 14rpx 6rpx;
  text-align: center;
  border-right: 1rpx solid #cbd5e1;
}
.table-cell:last-child {
  border-right: none;
}
.cell-label {
  font-size: 20rpx;
  font-weight: bold;
  color: #334155;
  margin-bottom: 4rpx;
}
.cell-val {
  font-family: monospace;
  font-size: 24rpx;
  font-weight: bold;
  color: #0f172a;
}
.bg-pink {
  background-color: #ffe4e1;
}
.bg-cyan {
  background-color: #e0ffff;
}
.bg-yellow {
  background-color: #f0e68c;
}

/* 弹窗遮罩 */
.modal-mask {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background-color: rgba(0, 0, 0, 0.5);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 999;
}
.modal-content {
  width: 88%;
  background-color: white;
  border-radius: 18rpx;
  padding: 28rpx;
  box-sizing: border-box;
}
.modal-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 10rpx;
}
.modal-title {
  font-size: 30rpx;
  font-weight: bold;
  color: #1e293b;
}
.modal-close {
  font-size: 32rpx;
  color: #64748b;
  padding: 8rpx;
}
.modal-status {
  font-size: 22rpx;
  color: #64748b;
  margin-bottom: 16rpx;
}
.device-list {
  max-height: 480rpx;
  margin-bottom: 16rpx;
}
.device-item {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 16rpx;
  background-color: #f8fafc;
  border-radius: 10rpx;
  margin-bottom: 12rpx;
}
.device-info {
  display: flex;
  flex-direction: column;
}
.item-name {
  font-size: 26rpx;
  font-weight: bold;
  color: #0f172a;
}
.item-mac {
  font-size: 20rpx;
  color: #64748b;
  margin-top: 4rpx;
}
.btn-item-connect {
  font-size: 22rpx;
  height: 52rpx;
  line-height: 52rpx;
  background-color: #16a34a;
  color: white;
  padding: 0 18rpx;
  margin: 0;
  border-radius: 8rpx;
}
.btn-rescan {
  width: 100%;
  height: 64rpx;
  line-height: 64rpx;
  font-size: 24rpx;
  background-color: #2563eb;
  color: white;
  border-radius: 10rpx;
}
</style>
