import { abilityAccessCtrl, common, Permissions } from '@kit.AbilityKit';
import { promptAction } from '@kit.ArkUI';

interface BleDeviceItem {
  name: string;
  mac: string;
  rssi: number;
}

/**
 * 1:1 DeviceScreen & DeviceShowTable Clone - HarmonyOS ArkTS Edition
 * Technical Support: ZKTeco Brain-Computer Interface Division
 */
@Entry
@Component
struct Index {
  @State isConnected: boolean = false;
  @State connectionStateText: string = "Disconnected";
  @State connectedDeviceName: string = "ZKBrain Headband";
  @State connectedDeviceMac: string = "DC:23:4F:9A:88:01";
  @State batteryLevel: number = 85;

  // 12 cognitive & hardware metrics
  @State attention: number = 78;
  @State meditation: number = 65;
  @State signalQuality: number = 0;
  @State rawEeg: number = 142;
  @State delta: number = 12450;
  @State theta: number = 8320;
  @State lowAlpha: number = 15300;
  @State highAlpha: number = 21040;
  @State lowBeta: number = 18900;
  @State highBeta: number = 11200;
  @State lowGamma: number = 4600;
  @State middleGamma: number = 2100;

  // MEMS motion posture
  @State memsRoll: number = 1.2;
  @State memsPitch: number = -0.5;
  @State memsYaw: number = 14.8;
  @State memsQ0: number = 0.992;
  @State memsQ1: number = 0.010;
  @State memsQ2: number = -0.004;
  @State memsQ3: number = 0.129;

  // Channel & Chart Display Toggles
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

  // Console & Terminal logs
  @State customCmdInput: string = "";
  @State writeSnInput: string = "";
  @State terminalLogs: string = "[System] ZKBrain HarmonyOS ArkTS console initialized successfully.\n";

  // Scan modal state & scanned devices
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
        this.addLog("[Permission] Bluetooth permission denied. Please allow in system settings.");
      }
      return granted;
    } catch (err) {
      this.addLog(`[Permission] Permission request exception: ${JSON.stringify(err)}`);
      return false;
    }
  }

  addLog(msg: string): void {
    this.terminalLogs += `${msg}\n`;
  }

  aboutToAppear(): void {
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
          // Section 1: Top Navigation Bar
          // ==========================================
          Row() {
            Text("Device Management (DeviceScreen)")
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .fontColor("#0F172A")

            Blank()

            Row({ space: 8 }) {
              Button("🔍 Search")
                .fontSize(12)
                .backgroundColor("#2563EB")
                .height(32)
                .borderRadius(6)
                .onClick(async () => {
                  const ok = await this.requestBluetoothPermission();
                  if (ok) {
                    this.showScanDialog = true;
                    this.isScanning = true;
                    this.addLog("[BLE] Scanning for nearby BLE BCI devices...");
                  }
                })

              Button("🚀 DFU Upgrade")
                .fontSize(12)
                .backgroundColor("#475569")
                .height(32)
                .borderRadius(6)
                .onClick(() => {
                  this.addLog("[DFU] OTA firmware check: already on latest stable release v2.4.0");
                  promptAction.showToast({ message: "DFU check complete: Current firmware is up to date" });
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
          // Section 2: Unified Device Status Card
          // ==========================================
          this.buildDeviceStatusCard()

          // ==========================================
          // Section 3: Channel Settings Card
          // ==========================================
          this.buildChannelSettingsCard()

          // ==========================================
          // Section 4: Chart Display Settings Card
          // ==========================================
          this.buildChartDisplaySettingsCard()

          // ==========================================
          // Section 5: NeuroSky / MindWave 20-Byte Protocol Console
          // ==========================================
          this.buildNeuroSkyConsoleCard()

          // ==========================================
          // Section 6: ZKBrain Proprietary Device Console
          // ==========================================
          this.buildZKBrainConsoleCard()

          // ==========================================
          // Section 7: Spectrum Data Table (DeviceShowTable 4x3)
          // ==========================================
          this.buildDeviceShowTable()

          Blank().height(24)
        }
        .width('100%')
        .padding({ left: 14, right: 14, top: 8, bottom: 24 })
      }
      .width('100%')
      .height('100%')
      .backgroundColor("#F1F5F9")

      // ==========================================
      // Section 8: Bluetooth Scan Modal (BleScanDialog)
      // ==========================================
      if (this.showScanDialog) {
        this.buildScanDialog()
      }
    }
    .width('100%')
    .height('100%')
  }

  // ==========================================
  // Section 2 UI: Unified Device Status Card
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

      Button(this.isConnected ? "Disconnect" : "Scan & Connect")
        .width('100%')
        .height(36)
        .fontSize(13)
        .backgroundColor(this.isConnected ? "#DC2626" : "#2563EB")
        .borderRadius(8)
        .onClick(() => {
          if (this.isConnected) {
            this.isConnected = false;
            this.connectionStateText = "Disconnected";
            this.addLog("[BLE] Device disconnected by user.");
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
  // Section 3 UI: Channel Settings Card
  // ==========================================
  @Builder
  buildChannelSettingsCard() {
    Column({ space: 8 }) {
      Row() {
        Text("⚙️").fontSize(14)
        Text("Channel Settings")
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
              this.addLog(`[Channel] Left (FP1): ${val}`);
            })
          Text("Left (FP1)").fontSize(13).fontColor("#1E293B")
        }

        Row() {
          Checkbox({ name: 'fp2', group: 'channels' })
            .select(this.isFp2Visible)
            .enabled(false)
          Text("Right (FP2) [Unsupported]").fontSize(13).fontColor("#94A3B8")
        }
      }
    }
    .width('100%')
    .padding(14)
    .backgroundColor(Color.White)
    .borderRadius(12)
  }

  // ==========================================
  // Section 4 UI: Chart Display Settings Card
  // ==========================================
  @Builder
  buildChartDisplaySettingsCard() {
    Column({ space: 8 }) {
      Row() {
        Text("📈").fontSize(14)
        Text("Chart Display Settings")
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
              this.addLog(`[Chart] Toggle display for ${key}: ${this.chartToggles[key]}`);
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
  // Section 5 UI: NeuroSky / MindWave 20-Byte Protocol Console
  // ==========================================
  @Builder
  buildNeuroSkyConsoleCard() {
    Column({ space: 8 }) {
      Row() {
        Text("⚙️").fontSize(14)
        Text("NeuroSky / MindWave Protocol Console")
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .fontColor("#1E293B")
          .margin({ left: 6 })
      }
      .width('100%')

      Text("Supports 20-byte binary ignition frame, notch filter, SN read/write and classic MAC probing")
        .fontSize(12)
        .fontColor("#64748B")

      Flex({ wrap: FlexWrap.Wrap }) {
        this.buildConsoleActionBtn("🚀 Ignition (0x15/17)", "#16A34A", () => {
          this.addLog("[TX >> XMW] Ignition command sent: 0x15 (Raw) + 0x17 (Band)");
        })
        this.buildConsoleActionBtn("🛑 Stop (0x16/18)", "#DC2626", () => {
          this.addLog("[TX >> XMW] Transmission stopped: 0x16 + 0x18");
        })
        this.buildConsoleActionBtn("50Hz Notch (0x1B)", "#475569", () => {
          this.addLog("[TX >> XMW] Notch filter set to 50Hz (0x1B)");
        })
        this.buildConsoleActionBtn("60Hz Notch (0x1C)", "#475569", () => {
          this.addLog("[TX >> XMW] Notch filter set to 60Hz (0x1C)");
        })
        this.buildConsoleActionBtn("Battery (0x06)", "#D97706", () => {
          this.addLog("[TX >> XMW] Read battery level (0x06)");
        })
        this.buildConsoleActionBtn("Serial SN (0xF4)", "#D97706", () => {
          this.addLog("[TX >> XMW] Query serial number SN (0xF4)");
        })
        this.buildConsoleActionBtn("Classic MAC (0xFC)", "#7C3AED", () => {
          this.addLog("[TX >> XMW] Probe classic Bluetooth MAC (0xFC)");
        })
      }

      Row({ space: 6 }) {
        TextInput({ text: this.writeSnInput, placeholder: "Enter serial number SN..." })
          .layoutWeight(1)
          .height(34)
          .fontSize(12)
          .backgroundColor("#F8FAFC")
          .border({ width: 1, color: "#CBD5E1" })
          .borderRadius(6)
          .onChange((v: string) => this.writeSnInput = v)

        Button("Write SN (0xF2)")
          .fontSize(11)
          .height(34)
          .backgroundColor("#0F172A")
          .borderRadius(6)
          .onClick(() => {
            if (this.writeSnInput.trim().length > 0) {
              this.addLog(`[TX >> XMW] Write SN (0xF2): ${this.writeSnInput.trim()}`);
              promptAction.showToast({ message: `SN command sent: ${this.writeSnInput.trim()}` });
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
  // Section 6 UI: ZKBrain Proprietary Device Console
  // ==========================================
  @Builder
  buildZKBrainConsoleCard() {
    Column({ space: 8 }) {
      Row() {
        Text("🧠").fontSize(14)
        Text("ZKBrain Proprietary Device Console")
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .fontColor("#1E293B")
          .margin({ left: 6 })
      }
      .width('100%')

      Text("Supports ASCII control, MEMS posture sensing, sample rate switching and terminal monitor")
        .fontSize(12)
        .fontColor("#64748B")

      Flex({ wrap: FlexWrap.Wrap }) {
        this.buildConsoleActionBtn("License (license:?)", "#0284C7", () => {
          this.addLog("[TX >>] license:?");
        })
        this.buildConsoleActionBtn("Battery (battery:?)", "#0284C7", () => {
          this.addLog("[TX >>] battery:?");
        })
        this.buildConsoleActionBtn("Version (version:?)", "#0284C7", () => {
          this.addLog("[TX >>] version:?");
        })
        this.buildConsoleActionBtn("Start EEG (eeg_data_on:1)", "#16A34A", () => {
          this.addLog("[TX >>] eeg_data_on:1");
        })
        this.buildConsoleActionBtn("Stop EEG (eeg_data_on:0)", "#DC2626", () => {
          this.addLog("[TX >>] eeg_data_on:0");
        })
        this.buildConsoleActionBtn("256Hz Rate", "#475569", () => {
          this.addLog("[TX >>] eeg_data_rate:2 (256Hz)");
        })
        this.buildConsoleActionBtn("512Hz Rate", "#475569", () => {
          this.addLog("[TX >>] eeg_data_rate:1 (512Hz)");
        })
        this.buildConsoleActionBtn("Start MEMS", "#059669", () => {
          this.addLog("[TX >>] mems_on:1");
        })
        this.buildConsoleActionBtn("Stop MEMS", "#94A3B8", () => {
          this.addLog("[TX >>] mems_on:0");
        })
        this.buildConsoleActionBtn("DFU Scan", "#7C3AED", () => {
          this.addLog("[TX >>] dfu_scan:1 (DFU OTA ready mode)");
        })
      }

      Column({ space: 4 }) {
        Text("📐 Realtime MEMS Posture (Euler & Quaternion)")
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

      Row({ space: 6 }) {
        TextInput({ text: this.customCmdInput, placeholder: "Custom command (e.g. mems_on:1)" })
          .layoutWeight(1)
          .height(34)
          .fontSize(12)
          .backgroundColor("#F8FAFC")
          .border({ width: 1, color: "#CBD5E1" })
          .borderRadius(6)
          .onChange((v: string) => this.customCmdInput = v)

        Button("Send")
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

      Column({ space: 6 }) {
        Row() {
          Text("Terminal Monitor:")
            .fontSize(11)
            .fontColor("#94A3B8")
          Blank()
          Text("Clear")
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
  // Section 7 UI: Spectrum Data Table (DeviceShowTable 4x3)
  // Pink #FFE4E1, Cyan #E0FFFF, Yellow #F0E68C
  // ==========================================
  @Builder
  buildDeviceShowTable() {
    Column({ space: 8 }) {
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

      Column() {
        Row() {
          this.buildTableCell("Attention", `${this.attention}`, "#FFE4E1")
          this.buildTableCell("Meditation", `${this.meditation}`, "#FFE4E1")
          this.buildTableCell("Quality", `${this.signalQuality}`, "#FFE4E1")
        }.width('100%')

        Row() {
          this.buildTableCell("Raw EEG", `${this.rawEeg}`, "#FFE4E1")
          this.buildTableCell("Delta", `${this.delta}`, "#E0FFFF")
          this.buildTableCell("Theta", `${this.theta}`, "#E0FFFF")
        }.width('100%')

        Row() {
          this.buildTableCell("Low Alpha", `${this.lowAlpha}`, "#E0FFFF")
          this.buildTableCell("High Alpha", `${this.highAlpha}`, "#E0FFFF")
          this.buildTableCell("Low Beta", `${this.lowBeta}`, "#F0E68C")
        }.width('100%')

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
  // Section 8 UI: Bluetooth Scan Modal (BleScanDialog)
  // ==========================================
  @Builder
  buildScanDialog() {
    Column() {
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

    Column({ space: 10 }) {
      Row() {
        Text("🔍 Search Nearby BCI Devices")
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

      Text(this.isScanning ? "Scanning for nearby BLE BCI devices..." : "Scan completed")
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

              Button("Connect")
                .fontSize(11)
                .height(28)
                .backgroundColor("#16A34A")
                .borderRadius(6)
                .onClick(() => {
                  this.connectedDeviceName = item.name;
                  this.connectedDeviceMac = item.mac;
                  this.isConnected = true;
                  this.connectionStateText = "READY";
                  this.showScanDialog = false;
                  this.addLog(`[BLE] Connected successfully to device: ${item.name} (${item.mac})`);
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

      Button("Rescan")
        .width('100%')
        .height(34)
        .fontSize(12)
        .backgroundColor("#2563EB")
        .borderRadius(6)
        .onClick(() => {
          this.isScanning = true;
          this.addLog("[BLE] Rescanning for nearby devices...");
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
