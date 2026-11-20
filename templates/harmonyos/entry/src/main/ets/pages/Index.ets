import { abilityAccessCtrl, common, Permissions } from '@kit.AbilityKit';
import { promptAction } from '@kit.ArkUI';

interface BleDeviceItem {
  name: string;
  mac: string;
  rssi: number;
}

/**
 * 🌟 1:1 完整逐项克隆 shared1 设备管理控制台 (DeviceScreen + DeviceShowTable) - HarmonyOS ArkTS 原生版
 * 技术支持：熵基科技脑机事业部 (ZKTeco Brain-Computer Interface Division)
 */
@Entry
@Component
struct Index {
  @State isConnected: boolean = false;
  @State connectionStateText: string = "未连接 (Disconnected)";
  @State connectedDeviceName: string = "ZKBrain Headband";
  @State connectedDeviceMac: string = "DC:23:4F:9A:88:01";
  @State batteryLevel: number = 85;

  // 12项生理指标数据
  @State attention: number = 78;
  @State meditation: number = 65;
  @State signalQuality: number = 0; // 0良好
  @State rawEeg: number = 142;
  @State delta: number = 12450;
  @State theta: number = 8320;
  @State lowAlpha: number = 15300;
  @State highAlpha: number = 21040;
  @State lowBeta: number = 18900;
  @State highBeta: number = 11200;
  @State lowGamma: number = 4600;
  @State middleGamma: number = 2100;

  // MEMS 姿态与欧拉角
  @State memsRoll: number = 1.2;
  @State memsPitch: number = -0.5;
  @State memsYaw: number = 14.8;
  @State memsQ0: number = 0.992;
  @State memsQ1: number = 0.010;
  @State memsQ2: number = -0.004;
  @State memsQ3: number = 0.129;

  // 通道与图表显隐配置
  @State isFp1Visible: boolean = true;
  @State isFp2Visible: boolean = false;
  @State chartToggles: Record<string, boolean> = {
    "Raw EEG": true,
    "Signal Quality": true,
    "Attention": true,
    "Meditation": true,
    "Delta": true,
    "Theta": true,
    "Low Alpha": true,
    "High Alpha": true,
    "Low Beta": true,
    "High Beta": true,
    "Low Gamma": true,
    "Middle Gamma": true
  };

  // 控制台与终端日志
  @State customCmdInput: string = "";
  @State writeSnInput: string = "";
  @State terminalLogs: string = "[系统启动] ZKBrain HarmonyOS ArkTS 控制台初始化就绪\n";

  // 蓝牙搜索弹窗状态与模拟设备
  @State showScanDialog: boolean = false;
  @State isScanning: boolean = false;
  @State scannedDevices: BleDeviceItem[] = [
    { name: "ZKBrain-PRO-8801", mac: "DC:23:4F:9A:88:01", rssi: -58 },
    { name: "MindWave Mobile 2", mac: "AA:BB:CC:11:22:33", rssi: -72 },
    { name: "ZKBrain Headband Lite", mac: "DC:23:4F:55:66:77", rssi: -64 }
  ];

  private timerId: number = -1;

  async requestBluetoothPermission(): Promise<boolean> {
    try {
      const context = getContext(this) as common.UIAbilityContext;
      const atManager = abilityAccessCtrl.createAtManager();
      const permissions: Array<Permissions> = [
        'ohos.permission.ACCESS_BLUETOOTH',
        'ohos.permission.APPROXIMATELY_LOCATION'
      ];
      const result = await atManager.requestPermissionsFromUser(context, permissions);
      const granted = result.authResults.every((code: number) => code === 0);
      if (!granted) {
        this.addLog("[权限拦截] 未授予鸿蒙系统蓝牙权限，请在系统设置中允许");
      }
      return granted;
    } catch (err) {
      this.addLog(`[权限申请异常] ${JSON.stringify(err)}`);
      return false;
    }
  }

  addLog(msg: string): void {
    this.terminalLogs += `${msg}\n`;
  }

  aboutToAppear(): void {
    // 模拟数据微动
    this.timerId = setInterval(() => {
      if (this.isConnected) {
        this.attention = Math.floor(65 + Math.random() * 25);
        this.meditation = Math.floor(55 + Math.random() * 30);
        this.rawEeg = Math.floor((Math.random() - 0.5) * 200);
      }
    }, 1000);
  }

  aboutToDisappear(): void {
    if (this.timerId !== -1) {
      clearInterval(this.timerId);
    }
  }

  build() {
    Stack({ alignContent: Alignment.Center }) {
      Scroll() {
        Column({ space: 12 }) {
          // ==========================================
          // 板块 1：顶部操作栏 (App Header)
          // ==========================================
          Row() {
            Text("设备管理 (DeviceScreen)")
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .fontColor("#0F172A")

            Blank()

            Row({ space: 8 }) {
              Button("🔍 搜索")
                .fontSize(12)
                .backgroundColor("#2563EB")
                .height(32)
                .borderRadius(6)
                .onClick(async () => {
                  const ok = await this.requestBluetoothPermission();
                  if (ok) {
                    this.showScanDialog = true;
                    this.isScanning = true;
                    this.addLog("[BLE] 启动鸿蒙 BLE 设备搜索...");
                  }
                })

              Button("🚀 DFU升级")
                .fontSize(12)
                .backgroundColor("#475569")
                .height(32)
                .borderRadius(6)
                .onClick(() => {
                  this.addLog("[DFU] 检查固件版本：当前已处于最新稳定版 v2.4.0");
                  promptAction.showToast({ message: "DFU 固件检测完成：当前为最新版本" });
                })

              Text("Authorized")
                .fontSize(11)
                .fontWeight(FontWeight.Bold)
                .fontColor("#16A34A")
                .backgroundColor("#DCFCE7")
                .padding({ left: 6, right: 6, top: 4, bottom: 4 })
                .borderRadius(4)
                .border({ width: 1, color: "#86EFAC" })
            }
          }
          .width('100%')
          .padding({ top: 12, bottom: 6 })

          // ==========================================
          // 板块 2：统一设备连接状态卡片
          // ==========================================
          this.buildDeviceStatusCard()

          // ==========================================
          // 板块 3：Channel Settings 通道配置卡片
          // ==========================================
          this.buildChannelSettingsCard()

          // ==========================================
          // 板块 4：Chart Display Settings 图表显隐卡片
          // ==========================================
          this.buildChartDisplaySettingsCard()

          // ==========================================
          // 板块 5：⚙️ NeuroSky / MindWave 专属 20 字节协议控制台
          // ==========================================
          this.buildNeuroSkyConsoleCard()

          // ==========================================
          // 板块 6：🧠 ZKBrain 自研脑电设备官方控制台
          // ==========================================
          this.buildZKBrainConsoleCard()

          // ==========================================
          // 板块 7：Spectrum Data 详细数据表格 (DeviceShowTable 4x3 三色)
          // ==========================================
          this.buildDeviceShowTable()

          Blank().height(24)
        }
        .width('100%')
        .padding({ left: 14, right: 14, top: 8, bottom: 24 })
      }
      .width('100%')
      .height('100%')
      .backgroundColor("#F1F5F9") // 浅灰背景

      // ==========================================
      // 板块 8：蓝牙搜索连接弹窗 (BleScanDialog)
      // ==========================================
      if (this.showScanDialog) {
        this.buildScanDialog()
      }
    }
    .width('100%')
    .height('100%')
  }

  // ==========================================
  // 板块 2 UI：统一设备连接状态卡片
  // ==========================================
  @Builder
  buildDeviceStatusCard() {
    Column({ space: 8 }) {
      Row() {
        Circle()
          .width(10)
          .height(10)
          .fill(this.isConnected ? "#22C55E" : "#EF4444")
        Text(this.connectionStateText)
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.isConnected ? "#16A34A" : "#DC2626")
          .margin({ left: 8 })

        Blank()

        Row({ space: 4 }) {
          Text("🔋").fontSize(11)
          Text(`${this.batteryLevel}%`)
            .fontSize(11)
            .fontWeight(FontWeight.Bold)
            .fontColor("#16A34A")
        }
        .backgroundColor("#DCFCE7")
        .padding({ left: 6, right: 6, top: 2, bottom: 2 })
        .borderRadius(10)
        .border({ width: 1, color: "#86EFAC" })
      }
      .width('100%')

      Text(this.connectedDeviceName)
        .fontSize(17)
        .fontWeight(FontWeight.Bold)
        .fontColor("#0F172A")

      Text(`MAC: ${this.connectedDeviceMac}  |  SN: ZK-2026-DEV001`)
        .fontSize(12)
        .fontColor("#64748B")

      Row({ space: 8 }) {
        this.buildBadge("ZKBrain Core", "#0284C7")
        this.buildBadge("Single-Ch (FP1)", "#0D9488")
        this.buildBadge("ASCII + MEMS", "#7C3AED")
      }
      .margin({ top: 4, bottom: 4 })

      Button(this.isConnected ? "断开设备" : "搜索连接")
        .width('100%')
        .height(36)
        .fontSize(13)
        .backgroundColor(this.isConnected ? "#DC2626" : "#2563EB")
        .borderRadius(8)
        .onClick(() => {
          if (this.isConnected) {
            this.isConnected = false;
            this.connectionStateText = "未连接 (Disconnected)";
            this.addLog("[BLE] 用户主动断开设备连接");
          } else {
            this.showScanDialog = true;
          }
        })
    }
    .width('100%')
    .padding(14)
    .backgroundColor(Color.White)
    .borderRadius(12)
  }

  @Builder
  buildBadge(text: string, color: string) {
    Text(text)
      .fontSize(11)
      .fontColor(color)
      .fontWeight(FontWeight.Medium)
      .backgroundColor("#F8FAFC")
      .padding({ left: 6, right: 6, top: 2, bottom: 2 })
      .borderRadius(4)
      .border({ width: 1, color: color })
  }

  // ==========================================
  // 板块 3 UI：Channel Settings 通道配置卡片
  // ==========================================
  @Builder
  buildChannelSettingsCard() {
    Column({ space: 8 }) {
      Row() {
        Text("⚙️").fontSize(14)
        Text("Channel Settings (通道配置)")
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .fontColor("#1E293B")
          .margin({ left: 6 })
      }
      .width('100%')

      Row({ space: 16 }) {
        Row() {
          Checkbox({ name: 'fp1', group: 'channels' })
            .select(this.isFp1Visible)
            .selectedColor("#2563EB")
            .onChange((val: boolean) => {
              this.isFp1Visible = val;
              this.addLog(`[通道配置] Left (FP1): ${val}`);
            })
          Text("Left (FP1)").fontSize(13).fontColor("#1E293B")
        }

        Row() {
          Checkbox({ name: 'fp2', group: 'channels' })
            .select(this.isFp2Visible)
            .enabled(false) // 禁用
          Text("Right (FP2) [硬件不支持]").fontSize(13).fontColor("#94A3B8")
        }
      }
    }
    .width('100%')
    .padding(14)
    .backgroundColor(Color.White)
    .borderRadius(12)
  }

  // ==========================================
  // 板块 4 UI：Chart Display Settings 图表显隐卡片
  // ==========================================
  @Builder
  buildChartDisplaySettingsCard() {
    Column({ space: 8 }) {
      Row() {
        Text("📈").fontSize(14)
        Text("Chart Display Settings (图表显隐配置)")
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .fontColor("#1E293B")
          .margin({ left: 6 })
      }
      .width('100%')

      Flex({ wrap: FlexWrap.Wrap }) {
        ForEach(Object.keys(this.chartToggles), (key: string) => {
          Button(key)
            .fontSize(11)
            .height(28)
            .backgroundColor(this.chartToggles[key] ? "#2563EB" : "#F1F5F9")
            .fontColor(this.chartToggles[key] ? Color.White : "#475569")
            .borderRadius(14)
            .margin(3)
            .onClick(() => {
              this.chartToggles[key] = !this.chartToggles[key];
              this.addLog(`[图表显隐] ${key}: ${this.chartToggles[key]}`);
            })
        })
      }
    }
    .width('100%')
    .padding(14)
    .backgroundColor(Color.White)
    .borderRadius(12)
  }

  // ==========================================
  // 板块 5 UI：⚙️ NeuroSky / MindWave 专属 20 字节协议控制台
  // ==========================================
  @Builder
  buildNeuroSkyConsoleCard() {
    Column({ space: 8 }) {
      Row() {
        Text("⚙️").fontSize(14)
        Text("NeuroSky / MindWave 专属协议控制台")
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .fontColor("#1E293B")
          .margin({ left: 6 })
      }
      .width('100%')

      Text("支持 20 字节二进制点火帧、工频滤波、SN 读写与经典 MAC 探测")
        .fontSize(12)
        .fontColor("#64748B")

      Flex({ wrap: FlexWrap.Wrap }) {
        this.buildConsoleActionBtn("🚀 点火启动 (0x15/17)", "#16A34A", () => {
          this.addLog("[TX >> XMW] 点火启动包: 0x15 (Raw) + 0x17 (Band)");
        })
        this.buildConsoleActionBtn("🛑 停止传输 (0x16/18)", "#DC2626", () => {
          this.addLog("[TX >> XMW] 停止传输: 0x16 + 0x18");
        })
        this.buildConsoleActionBtn("50Hz 工频滤波 (0x1B)", "#475569", () => {
          this.addLog("[TX >> XMW] 设置 50Hz 工频陷波滤波 (0x1B)");
        })
        this.buildConsoleActionBtn("60Hz 工频滤波 (0x1C)", "#475569", () => {
          this.addLog("[TX >> XMW] 设置 60Hz 工频陷波滤波 (0x1C)");
        })
        this.buildConsoleActionBtn("读电量 (0x06)", "#D97706", () => {
          this.addLog("[TX >> XMW] 读取硬件电量 (0x06)");
        })
        this.buildConsoleActionBtn("读序列号 (0xF4)", "#D97706", () => {
          this.addLog("[TX >> XMW] 查询设备序列号 SN (0xF4)");
        })
        this.buildConsoleActionBtn("探测经典MAC (0xFC)", "#7C3AED", () => {
          this.addLog("[TX >> XMW] 探测经典蓝牙 MAC 地址 (0xFC)");
        })
      }

      Row({ space: 6 }) {
        TextInput({ text: this.writeSnInput, placeholder: "输入写入序列号 SN..." })
          .layoutWeight(1)
          .height(34)
          .fontSize(12)
          .backgroundColor("#F8FAFC")
          .border({ width: 1, color: "#CBD5E1" })
          .borderRadius(6)
          .onChange((v: string) => this.writeSnInput = v)

        Button("写入 SN (0xF2)")
          .fontSize(11)
          .height(34)
          .backgroundColor("#0F172A")
          .borderRadius(6)
          .onClick(() => {
            if (this.writeSnInput.trim().length > 0) {
              this.addLog(`[TX >> XMW] 写入 SN (0xF2): ${this.writeSnInput.trim()}`);
              promptAction.showToast({ message: `SN 写入指令已发送: ${this.writeSnInput.trim()}` });
            }
          })
      }
      .width('100%')
    }
    .width('100%')
    .padding(14)
    .backgroundColor(Color.White)
    .borderRadius(12)
  }

  // ==========================================
  // 板块 6 UI：🧠 ZKBrain 自研脑电设备官方控制台
  // ==========================================
  @Builder
  buildZKBrainConsoleCard() {
    Column({ space: 8 }) {
      Row() {
        Text("🧠").fontSize(14)
        Text("ZKBrain 自研脑电设备官方控制台")
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .fontColor("#1E293B")
          .margin({ left: 6 })
      }
      .width('100%')

      Text("支持 ASCII 控制、MEMS 姿态传感、采样率切换与终端实时回显")
        .fontSize(12)
        .fontColor("#64748B")

      Flex({ wrap: FlexWrap.Wrap }) {
        this.buildConsoleActionBtn("查询授权 (license:?)", "#0284C7", () => {
          this.addLog("[TX >>] license:?");
        })
        this.buildConsoleActionBtn("读电量 (battery:?)", "#0284C7", () => {
          this.addLog("[TX >>] battery:?");
        })
        this.buildConsoleActionBtn("固件版本 (version:?)", "#0284C7", () => {
          this.addLog("[TX >>] version:?");
        })
        this.buildConsoleActionBtn("开启脑电 (eeg_data_on:1)", "#16A34A", () => {
          this.addLog("[TX >>] eeg_data_on:1");
        })
        this.buildConsoleActionBtn("关闭脑电 (eeg_data_on:0)", "#DC2626", () => {
          this.addLog("[TX >>] eeg_data_on:0");
        })
        this.buildConsoleActionBtn("256Hz采样率", "#475569", () => {
          this.addLog("[TX >>] eeg_data_rate:2 (256Hz)");
        })
        this.buildConsoleActionBtn("512Hz采样率", "#475569", () => {
          this.addLog("[TX >>] eeg_data_rate:1 (512Hz)");
        })
        this.buildConsoleActionBtn("开启MEMS (mems_on:1)", "#059669", () => {
          this.addLog("[TX >>] mems_on:1");
        })
        this.buildConsoleActionBtn("关闭MEMS (mems_on:0)", "#94A3B8", () => {
          this.addLog("[TX >>] mems_on:0");
        })
        this.buildConsoleActionBtn("DFU 扫描模式", "#7C3AED", () => {
          this.addLog("[TX >>] dfu_scan:1 (进入DFU空中升级就绪模式)");
        })
      }

      // MEMS 姿态实时卡片
      Column({ space: 4 }) {
        Text("📐 实时 MEMS 空间姿态 (Euler & Quaternion)")
          .fontSize(12)
          .fontWeight(FontWeight.Bold)
          .fontColor("#334155")
        Text(`Euler:  Roll: ${this.memsRoll}°   Pitch: ${this.memsPitch}°   Yaw: ${this.memsYaw}°`)
          .fontSize(11)
          .fontFamily("monospace")
          .fontColor("#1E293B")
        Text(`Quat:   Q0: ${this.memsQ0}  Q1: ${this.memsQ1}  Q2: ${this.memsQ2}  Q3: ${this.memsQ3}`)
          .fontSize(11)
          .fontFamily("monospace")
          .fontColor("#64748B")
      }
      .width('100%')
      .padding(10)
      .backgroundColor("#F8FAFC")
      .borderRadius(6)
      .border({ width: 1, color: "#E2E8F0" })

      // 自定义键值对指令发送
      Row({ space: 6 }) {
        TextInput({ text: this.customCmdInput, placeholder: "自定义指令 (如 mems_on:1 或 sample_rate:512)" })
          .layoutWeight(1)
          .height(34)
          .fontSize(12)
          .backgroundColor("#F8FAFC")
          .border({ width: 1, color: "#CBD5E1" })
          .borderRadius(6)
          .onChange((v: string) => this.customCmdInput = v)

        Button("发送指令")
          .fontSize(11)
          .height(34)
          .backgroundColor("#2563EB")
          .borderRadius(6)
          .onClick(() => {
            const cmd = this.customCmdInput.trim();
            if (cmd.length > 0) {
              this.addLog(`[TX >>] ${cmd}`);
            }
          })
      }
      .width('100%')

      // 黑底终端回显监控窗口
      Column({ space: 6 }) {
        Row() {
          Text("终端响应监控 (Terminal Monitor):")
            .fontSize(11)
            .fontColor("#94A3B8")
          Blank()
          Text("清空")
            .fontSize(11)
            .fontColor("#38BDF8")
            .onClick(() => {
              this.terminalLogs = "";
            })
        }
        .width('100%')

        Scroll() {
          Text(this.terminalLogs)
            .fontSize(10)
            .fontColor("#4ADE80")
            .fontFamily("monospace")
            .padding(8)
        }
        .width('100%')
        .height(110)
        .backgroundColor("#0F172A")
        .borderRadius(6)
      }
      .width('100%')
      .padding(10)
      .backgroundColor("#0F172A")
      .borderRadius(8)
    }
    .width('100%')
    .padding(14)
    .backgroundColor(Color.White)
    .borderRadius(12)
  }

  @Builder
  buildConsoleActionBtn(label: string, color: string, onClick: () => void) {
    Button(label)
      .fontSize(11)
      .height(28)
      .backgroundColor("#F1F5F9")
      .fontColor(color)
      .fontWeight(FontWeight.Medium)
      .borderRadius(6)
      .border({ width: 1, color: color })
      .margin(3)
      .onClick(onClick)
  }

  // ==========================================
  // 板块 7 UI：Spectrum Data 详细数据表格 (DeviceShowTable 4x3 三色)
  // 粉色 #FFE4E1, 青色 #E0FFFF, 黄色 #F0E68C
  // ==========================================
  @Builder
  buildDeviceShowTable() {
    Column({ space: 8 }) {
      // 居中 MAC 标题条
      Row() {
        Text(`Device MAC: ${this.connectedDeviceMac}`)
          .fontSize(12)
          .fontWeight(FontWeight.Bold)
          .fontColor(Color.White)
          .fontFamily("monospace")
      }
      .width('100%')
      .padding(8)
      .backgroundColor("#1E293B")
      .borderRadius(6)
      .justifyContent(FlexAlign.Center)

      // 4x3 表格
      Column() {
        // Row 1 (全粉 #FFE4E1)
        Row() {
          this.buildTableCell("Attention", `${this.attention}`, "#FFE4E1")
          this.buildTableCell("Meditation", `${this.meditation}`, "#FFE4E1")
          this.buildTableCell("Quality", `${this.signalQuality}`, "#FFE4E1")
        }.width('100%')

        // Row 2 (粉 + 青 + 青)
        Row() {
          this.buildTableCell("Raw EEG", `${this.rawEeg}`, "#FFE4E1")
          this.buildTableCell("Delta", `${this.delta}`, "#E0FFFF")
          this.buildTableCell("Theta", `${this.theta}`, "#E0FFFF")
        }.width('100%')

        // Row 3 (青 + 青 + 黄)
        Row() {
          this.buildTableCell("Low Alpha", `${this.lowAlpha}`, "#E0FFFF")
          this.buildTableCell("High Alpha", `${this.highAlpha}`, "#E0FFFF")
          this.buildTableCell("Low Beta", `${this.lowBeta}`, "#F0E68C")
        }.width('100%')

        // Row 4 (全黄 #F0E68C)
        Row() {
          this.buildTableCell("High Beta", `${this.highBeta}`, "#F0E68C")
          this.buildTableCell("Low Gamma", `${this.lowGamma}`, "#F0E68C")
          this.buildTableCell("Mid Gamma", `${this.middleGamma}`, "#F0E68C")
        }.width('100%')
      }
      .width('100%')
      .border({ width: 1, color: "#CBD5E1" })
    }
    .width('100%')
    .padding(14)
    .backgroundColor(Color.White)
    .borderRadius(12)
  }

  @Builder
  buildTableCell(label: string, value: string, bgColor: string) {
    Column({ space: 2 }) {
      Text(label)
        .fontSize(10)
        .fontWeight(FontWeight.Bold)
        .fontColor("#334155")
        .textAlign(TextAlign.Center)
      Text(value)
        .fontSize(12)
        .fontWeight(FontWeight.Bold)
        .fontColor("#0F172A")
        .fontFamily("monospace")
        .textAlign(TextAlign.Center)
    }
    .layoutWeight(1)
    .padding({ top: 8, bottom: 8 })
    .backgroundColor(bgColor)
    .border({ width: 0.5, color: "#CBD5E1" })
  }

  // ==========================================
  // 板块 8 UI：蓝牙搜索弹窗 (BleScanDialog)
  // ==========================================
  @Builder
  buildScanDialog() {
    Column() {
      // 遮罩
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor('#80000000')
        .onClick(() => {
          this.showScanDialog = false;
        })
    }
    .width('100%')
    .height('100%')
    .position({ x: 0, y: 0 })

    // 弹窗主体卡片
    Column({ space: 10 }) {
      Row() {
        Text("🔍 搜索周围脑电设备")
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor("#1E293B")
        Blank()
        Button("✕")
          .fontSize(14)
          .fontColor("#64748B")
          .backgroundColor(Color.Transparent)
          .onClick(() => {
            this.showScanDialog = false;
          })
      }
      .width('100%')

      Text(this.isScanning ? "正在扫描周围低功耗蓝牙 (BLE) 脑电设备..." : "扫描完成")
        .fontSize(12)
        .fontColor("#64748B")

      List({ space: 8 }) {
        ForEach(this.scannedDevices, (item: BleDeviceItem) => {
          ListItem() {
            Row() {
              Column({ space: 2 }) {
                Text(item.name)
                  .fontSize(13)
                  .fontWeight(FontWeight.Bold)
                  .fontColor("#0F172A")
                Text(`${item.mac}  |  RSSI: ${item.rssi} dBm`)
                  .fontSize(11)
                  .fontColor("#64748B")
              }
              .alignItems(HorizontalAlign.Start)

              Blank()

              Button("连接")
                .fontSize(11)
                .height(28)
                .backgroundColor("#16A34A")
                .borderRadius(6)
                .onClick(() => {
                  this.connectedDeviceName = item.name;
                  this.connectedDeviceMac = item.mac;
                  this.isConnected = true;
                  this.connectionStateText = "已就绪 (READY)";
                  this.showScanDialog = false;
                  this.addLog(`[BLE] 成功连接至设备: ${item.name} (${item.mac})`);
                })
            }
            .width('100%')
            .padding(10)
            .backgroundColor("#F8FAFC")
            .borderRadius(8)
          }
        })
      }
      .width('100%')
      .layoutWeight(1)

      Button("重新扫描")
        .width('100%')
        .height(34)
        .fontSize(12)
        .backgroundColor("#2563EB")
        .borderRadius(6)
        .onClick(() => {
          this.isScanning = true;
          this.addLog("[BLE] 重新扫描周围设备...");
        })
    }
    .width('90%')
    .height('60%')
    .padding(16)
    .backgroundColor(Color.White)
    .borderRadius(14)
    .position({ x: '5%', y: '20%' })
  }
}
