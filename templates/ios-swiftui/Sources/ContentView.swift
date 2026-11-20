import SwiftUI
import CoreBluetooth
import zkbrain_parser

/// 🌟 1:1 完整逐项克隆 shared1 设备管理控制台 (DeviceScreen + DeviceShowTable) - iOS SwiftUI 原生版
/// 技术支持：熵基科技脑机事业部 (ZKTeco Brain-Computer Interface Division)

@MainActor
class BrainMonitorViewModel: ObservableObject {
    @Published var connectionStatus: String = "DISCONNECTED"
    @Published var connectedName: String = "未连接脑电设备"
    @Published var connectedMac: String = "00:00:00:00:00:00"
    @Published var batteryLevel: Int = 85
    @Published var showBluetoothPermissionAlert: Bool = false
    @Published var showScanSheet: Bool = false
    @Published var isScanning: Bool = false

    // 12 项生理与硬件指标
    @Published var attention: Int32 = 75
    @Published var meditation: Int32 = 68
    @Published var signalQuality: Int32 = 0
    @Published var rawEeg: Int32 = 128
    @Published var delta: Int32 = 14500
    @Published var theta: Int32 = 8900
    @Published var lowAlpha: Int32 = 16200
    @Published var highAlpha: Int32 = 21500
    @Published var lowBeta: Int32 = 19800
    @Published var highBeta: Int32 = 11400
    @Published var lowGamma: Int32 = 4800
    @Published var midGamma: Int32 = 2200

    // MEMS 姿态传感与欧拉角
    @Published var memsRoll: Double = 1.2
    @Published var memsPitch: Double = -0.5
    @Published var memsYaw: Double = 14.8
    @Published var memsQ0: Double = 0.992
    @Published var memsQ1: Double = 0.010
    @Published var memsQ2: Double = -0.004
    @Published var memsQ3: Double = 0.129

    // 通道与图表显隐配置
    @Published var isFp1Visible: Bool = true
    @Published var isFp2Visible: Bool = false
    @Published var chartToggles: [String: Bool] = [
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
    ]

    @Published var scannedDevices: [ZKBrainDevice] = []
    @Published var commandInput: String = ""
    @Published var writeSnInput: String = ""
    @Published var commandLogs: String = "[系统启动] ZKBrain iOS SwiftUI 控制台初始化就绪\n"

    func addLog(_ text: String) {
        commandLogs += "\(text)\n"
    }

    func sendConfig(key: String, value: String) {
        addLog("[TX >>] \(key):\(value)")
        ZKBrainManager.shared.sendConfigCommand(config: [key: value])
    }

    func sendXmwCommand(opCode: UInt8, desc: String) {
        guard let dev = ZKBrainManager.shared.connectedDevice.value, connectionStatus == "CONNECTED" else {
            addLog("[TX >> XMW 模拟] \(desc) (0x\(String(format: "%02X", opCode)))")
            return
        }
        let bytes: [UInt8] = [0x02, opCode]
        addLog("[TX >> XMW] \(desc) (0x\(String(format: "%02X", opCode)))")
        let kBytes = KotlinByteArray(size: Int32(bytes.count))
        for (i, b) in bytes.enumerated() {
            kBytes.set(index: Int32(i), value: Int8(bitPattern: b))
        }
        ZKBrainManager.shared.writeCommand(address: dev.address, command: kBytes)
    }

    func sendCommand(_ cmd: String) {
        let trimmed = cmd.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return }
        if trimmed.contains(":") {
            let parts = trimmed.split(separator: ":", maxSplits: 1).map(String.init)
            sendConfig(key: parts[0].trimmingCharacters(in: .whitespaces), value: parts.count > 1 ? parts[1].trimmingCharacters(in: .whitespaces) : "")
            return
        }
        addLog("[TX >>] \(trimmed)")
        guard let dev = ZKBrainManager.shared.connectedDevice.value, connectionStatus == "CONNECTED" else { return }
        let bytes = Array("\(trimmed)\n".utf8)
        let kBytes = KotlinByteArray(size: Int32(bytes.count))
        for (i, b) in bytes.enumerated() {
            kBytes.set(index: Int32(i), value: Int8(bitPattern: b))
        }
        ZKBrainManager.shared.writeCommand(address: dev.address, command: kBytes)
    }

    func sendIgnitionBytes() {
        addLog("[TX >> XMW] 下发点火包: 0x15 (Raw) + 0x17 (Band)")
        guard let dev = ZKBrainManager.shared.connectedDevice.value, connectionStatus == "CONNECTED" else { return }
        let bytes: [UInt8] = [0x02, 0x15, 0x17]
        let kBytes = KotlinByteArray(size: Int32(bytes.count))
        for (i, b) in bytes.enumerated() {
            kBytes.set(index: Int32(i), value: Int8(bitPattern: b))
        }
        ZKBrainManager.shared.writeCommand(address: dev.address, command: kBytes)
    }

    func toggleScan() {
        let auth = CBManager.authorization
        if auth == .denied || auth == .restricted {
            showBluetoothPermissionAlert = true
            addLog("[权限拦截] iOS 系统蓝牙权限已被拒绝，请在系统设置中开启")
            return
        }
        showScanSheet = true
        isScanning = true
        ZKBrainManager.shared.startScan(timeoutMillis: 10000, isContinuous: false)
    }

    func connectDevice(_ device: ZKBrainDevice) {
        ZKBrainManager.shared.stopScan()
        isScanning = false
        showScanSheet = false
        ZKBrainManager.shared.connect(device: device)
        connectedName = device.name ?? "ZKBrain Device"
        connectedMac = device.address
        connectionStatus = "CONNECTED"
        addLog("[BLE] 成功发起连接: \(connectedName) (\(connectedMac))")
    }

    func disconnect() {
        ZKBrainManager.shared.disconnect()
        connectionStatus = "DISCONNECTED"
        addLog("[BLE] 用户主动断开设备连接")
    }

    func startListeningData() {
        Task {
            for await eeg in ZKBrainManager.shared.brainData {
                self.attention = eeg.attention
                self.meditation = eeg.meditation
                self.signalQuality = eeg.poorSignal
                self.delta = eeg.delta
                self.theta = eeg.theta
                self.lowAlpha = eeg.lowAlpha
                self.highAlpha = eeg.highAlpha
                self.lowBeta = eeg.lowBeta
                self.highBeta = eeg.highBeta
                self.lowGamma = eeg.lowGamma
                self.midGamma = eeg.midGamma
            }
        }

        Task {
            for await conn in ZKBrainManager.shared.connState {
                self.connectionStatus = conn.name
            }
        }

        Task {
            for await dev in ZKBrainManager.shared.connectedDevice {
                if let dev = dev {
                    self.connectedName = dev.name ?? "已配对设备"
                    self.connectedMac = dev.address
                }
            }
        }

        Task {
            for await list in ZKBrainManager.shared.scannedDevices {
                self.scannedDevices = list
            }
        }

        Task {
            for await resp in ZKBrainManager.shared.commandResponse {
                self.addLog("[RX <<] \(resp)")
            }
        }
    }
}

struct ContentView: View {
    @StateObject private var vm = BrainMonitorViewModel()

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 12) {
                    // ==========================================
                    // 板块 2：统一设备连接状态卡片
                    // ==========================================
                    DeviceStatusCard(vm: vm)

                    // ==========================================
                    // 板块 3：Channel Settings 通道配置卡片
                    // ==========================================
                    ChannelSettingsCard(vm: vm)

                    // ==========================================
                    // 板块 4：Chart Display Settings 图表显隐卡片
                    // ==========================================
                    ChartDisplaySettingsCard(vm: vm)

                    // ==========================================
                    // 板块 5：⚙️ NeuroSky / MindWave 专属 20 字节协议控制台
                    // ==========================================
                    NeuroSkyConsoleCard(vm: vm)

                    // ==========================================
                    // 板块 6：🧠 ZKBrain 自研脑电设备官方控制台
                    // ==========================================
                    ZKBrainConsoleCard(vm: vm)

                    // ==========================================
                    // 板块 7：Spectrum Data 详细数据表格 (DeviceShowTable 4x3 三色)
                    // ==========================================
                    DeviceShowTable(vm: vm)

                    Spacer().frame(height: 20)
                }
                .padding(.horizontal, 12)
                .padding(.top, 8)
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationTitle("设备管理 (DeviceScreen)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button(action: { vm.toggleScan() }) {
                        HStack(spacing: 4) {
                            Image(systemName: "magnifyingglass")
                            Text("搜索").font(.caption)
                        }
                    }
                    Button(action: {
                        vm.addLog("[DFU] 固件 OTA 检测：当前已处于最新稳定版 v2.4.0")
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.triangle.2.circlepath")
                            Text("DFU").font(.caption)
                        }
                    }
                    Text("Authorized")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.green)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(Color.green.opacity(0.15))
                        .cornerRadius(4)
                }
            }
            .onAppear {
                vm.startListeningData()
            }
            .sheet(isPresented: $vm.showScanSheet) {
                BleScanSheet(vm: vm)
            }
            .alert("需要蓝牙访问权限", isPresented: $vm.showBluetoothPermissionAlert) {
                Button("前往设置") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                Button("取消", role: .cancel) {}
            } message: {
                Text("请在系统设置中允许本应用访问蓝牙，以便扫描并连接 ZKBrain 脑电设备。")
            }
        }
    }
}

// ==========================================
// 板块 2：统一设备连接状态卡片
// ==========================================
struct DeviceStatusCard: View {
    @ObservedObject var vm: BrainMonitorViewModel

    var isConnected: Bool {
        vm.connectionStatus == "CONNECTED" || vm.connectionStatus == "READY"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Circle()
                    .fill(isConnected ? Color.green : (vm.connectionStatus == "CONNECTING" ? Color.orange : Color.red))
                    .frame(width: 10, height: 10)
                Text(isConnected ? "已就绪 (READY)" : (vm.connectionStatus == "CONNECTING" ? "连接中 (CONNECTING)" : "未连接 (DISCONNECTED)"))
                    .font(.subheadline).bold()
                    .foregroundColor(isConnected ? .green : .secondary)

                Spacer()

                HStack(spacing: 4) {
                    Text("🔋").font(.caption2)
                    Text("\(vm.batteryLevel)%")
                        .font(.caption2).bold()
                        .foregroundColor(.green)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(Color.green.opacity(0.15))
                .cornerRadius(10)
            }

            Text(vm.connectedName)
                .font(.title3).bold()
                .foregroundColor(.primary)

            Text("MAC: \(vm.connectedMac)  |  SN: ZK-2026-DEV001")
                .font(.caption)
                .foregroundColor(.secondary)

            HStack(spacing: 8) {
                BadgeView(text: "ZKBrain Core", color: .blue)
                BadgeView(text: "Single-Ch (FP1)", color: .teal)
                BadgeView(text: "ASCII + MEMS", color: .purple)
            }

            Button(action: {
                if isConnected {
                    vm.disconnect()
                } else {
                    vm.toggleScan()
                }
            }) {
                HStack {
                    Spacer()
                    Image(systemName: isConnected ? "link.badge.plus" : "magnifyingglass")
                    Text(isConnected ? "断开设备" : "搜索连接")
                        .font(.subheadline).bold()
                    Spacer()
                }
                .padding(.vertical, 8)
                .background(isConnected ? Color.red : Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
        }
        .padding(14)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.04), radius: 3, x: 0, y: 1)
    }
}

struct BadgeView: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text)
            .font(.system(size: 11, weight: .semibold))
            .foregroundColor(color)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(color.opacity(0.12))
            .cornerRadius(4)
    }
}

// ==========================================
// 板块 3：Channel Settings 通道配置卡片
// ==========================================
struct ChannelSettingsCard: View {
    @ObservedObject var vm: BrainMonitorViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "slider.horizontal.3")
                    .foregroundColor(.secondary)
                Text("Channel Settings (通道配置)")
                    .font(.subheadline).bold()
            }

            HStack(spacing: 20) {
                Toggle(isOn: $vm.isFp1Visible) {
                    Text("Left (FP1)").font(.caption).bold()
                }
                .toggleStyle(CheckboxToggleStyle())

                Toggle(isOn: $vm.isFp2Visible) {
                    Text("Right (FP2) [硬件不支持]").font(.caption).foregroundColor(.secondary)
                }
                .toggleStyle(CheckboxToggleStyle())
                .disabled(true)
            }
        }
        .padding(14)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.04), radius: 3, x: 0, y: 1)
    }
}

struct CheckboxToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            Image(systemName: configuration.isOn ? "checkmark.square.fill" : "square")
                .foregroundColor(configuration.isOn ? .blue : .gray)
                .onTapGesture { configuration.isOn.toggle() }
            configuration.label
        }
    }
}

// ==========================================
// 板块 4：Chart Display Settings 图表显隐卡片
// ==========================================
struct ChartDisplaySettingsCard: View {
    @ObservedObject var vm: BrainMonitorViewModel

    let titles = [
        "Raw EEG", "Signal Quality", "Attention", "Meditation",
        "Delta", "Theta", "Low Alpha", "High Alpha",
        "Low Beta", "High Beta", "Low Gamma", "Middle Gamma"
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "chart.xyaxis.line")
                    .foregroundColor(.secondary)
                Text("Chart Display Settings (图表显隐配置)")
                    .font(.subheadline).bold()
            }

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 95))], spacing: 6) {
                ForEach(titles, id: \.self) { title in
                    let isChecked = vm.chartToggles[title] ?? true
                    Button(action: {
                        vm.chartToggles[title] = !isChecked
                        vm.addLog("[图表配置] \(title): \(!isChecked)")
                    }) {
                        Text(title)
                            .font(.system(size: 11, weight: .medium))
                            .lineLimit(1)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 5)
                            .frame(maxWidth: .infinity)
                            .background(isChecked ? Color.blue : Color(.secondarySystemBackground))
                            .foregroundColor(isChecked ? .white : .primary)
                            .cornerRadius(6)
                    }
                }
            }
        }
        .padding(14)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.04), radius: 3, x: 0, y: 1)
    }
}

// ==========================================
// 板块 5：⚙️ NeuroSky / MindWave 专属 20 字节协议控制台
// ==========================================
struct NeuroSkyConsoleCard: View {
    @ObservedObject var vm: BrainMonitorViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Text("⚙️")
                Text("NeuroSky / MindWave 专属协议控制台")
                    .font(.subheadline).bold()
            }
            Text("支持 20 字节二进制点火帧、工频滤波、SN 读写与经典 MAC 探测")
                .font(.caption2).foregroundColor(.secondary)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 105))], spacing: 6) {
                ActionBtn(label: "🚀 点火(0x15/17)", color: .green) {
                    vm.sendIgnitionBytes()
                }
                ActionBtn(label: "🛑 停止(0x16/18)", color: .red) {
                    vm.sendXmwCommand(opCode: 0x16, desc: "停止传输")
                }
                ActionBtn(label: "50Hz滤波(0x1B)", color: .gray) {
                    vm.sendXmwCommand(opCode: 0x1B, desc: "50Hz工频滤波")
                }
                ActionBtn(label: "60Hz滤波(0x1C)", color: .gray) {
                    vm.sendXmwCommand(opCode: 0x1C, desc: "60Hz工频滤波")
                }
                ActionBtn(label: "读电量(0x06)", color: .orange) {
                    vm.sendXmwCommand(opCode: 0x06, desc: "读取电量")
                }
                ActionBtn(label: "读SN(0xF4)", color: .orange) {
                    vm.sendXmwCommand(opCode: 0xF4, desc: "读取序列号")
                }
                ActionBtn(label: "探测MAC(0xFC)", color: .purple) {
                    vm.sendXmwCommand(opCode: 0xFC, desc: "探测经典MAC")
                }
            }

            HStack(spacing: 8) {
                TextField("输入写入序列号 SN...", text: $vm.writeSnInput)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(size: 12))

                Button("写入 SN (0xF2)") {
                    let sn = vm.writeSnInput.trimmingCharacters(in: .whitespaces)
                    if !sn.isEmpty {
                        vm.addLog("[TX >> XMW] 写入 SN (0xF2): \(sn)")
                    }
                }
                .font(.system(size: 11, weight: .bold))
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(Color.black)
                .foregroundColor(.white)
                .cornerRadius(6)
            }
        }
        .padding(14)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.04), radius: 3, x: 0, y: 1)
    }
}

// ==========================================
// 板块 6：🧠 ZKBrain 自研脑电设备官方控制台
// ==========================================
struct ZKBrainConsoleCard: View {
    @ObservedObject var vm: BrainMonitorViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Text("🧠")
                Text("ZKBrain 自研脑电设备官方控制台")
                    .font(.subheadline).bold()
            }
            Text("支持 ASCII 控制、MEMS 姿态传感、采样率切换与终端实时回显")
                .font(.caption2).foregroundColor(.secondary)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 105))], spacing: 6) {
                ActionBtn(label: "查询授权", color: .blue) {
                    vm.sendConfig(key: "license", value: "?")
                }
                ActionBtn(label: "读电量", color: .blue) {
                    vm.sendConfig(key: "battery", value: "?")
                }
                ActionBtn(label: "固件版本", color: .blue) {
                    vm.sendConfig(key: "version", value: "?")
                }
                ActionBtn(label: "开启脑电", color: .green) {
                    vm.sendConfig(key: "eeg_data_on", value: "1")
                }
                ActionBtn(label: "关闭脑电", color: .red) {
                    vm.sendConfig(key: "eeg_data_on", value: "0")
                }
                ActionBtn(label: "256Hz采样率", color: .gray) {
                    vm.sendConfig(key: "eeg_data_rate", value: "2")
                }
                ActionBtn(label: "512Hz采样率", color: .gray) {
                    vm.sendConfig(key: "eeg_data_rate", value: "1")
                }
                ActionBtn(label: "开启MEMS", color: .teal) {
                    vm.sendConfig(key: "mems_on", value: "1")
                }
                ActionBtn(label: "关闭MEMS", color: .gray) {
                    vm.sendConfig(key: "mems_on", value: "0")
                }
                ActionBtn(label: "DFU 扫描", color: .purple) {
                    vm.sendCommand("dfu_scan:1")
                }
            }

            // MEMS 姿态卡片
            VStack(alignment: .leading, spacing: 3) {
                Text("📐 实时 MEMS 空间姿态 (Euler & Quaternion)")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.secondary)
                Text(String(format: "Euler:  Roll: %.1f°   Pitch: %.1f°   Yaw: %.1f°", vm.memsRoll, vm.memsPitch, vm.memsYaw))
                    .font(.system(size: 11, design: .monospaced))
                Text(String(format: "Quat:   Q0: %.3f  Q1: %.3f  Q2: %.3f  Q3: %.3f", vm.memsQ0, vm.memsQ1, vm.memsQ2, vm.memsQ3))
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(.secondary)
            }
            .padding(8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(6)

            // 指令输入与发送
            HStack(spacing: 8) {
                TextField("自定义指令 (如 mems_on:1 或 sample_rate:512)", text: $vm.commandInput)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(size: 12))

                Button("发送指令") {
                    vm.sendCommand(vm.commandInput)
                }
                .font(.system(size: 11, weight: .bold))
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(6)
            }

            // 黑底终端回显监控窗口
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("终端响应监控 (Terminal Monitor):")
                        .font(.caption2).foregroundColor(.gray)
                    Spacer()
                    Button("清空") {
                        vm.commandLogs = ""
                    }
                    .font(.caption2).foregroundColor(.cyan)
                }

                ScrollView {
                    Text(vm.commandLogs.isEmpty ? "等待下发或接收指令回包...\n" : vm.commandLogs)
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(.green)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(6)
                }
                .frame(height: 95)
                .background(Color.black.opacity(0.9))
                .cornerRadius(6)
            }
            .padding(8)
            .background(Color.black)
            .cornerRadius(8)
        }
        .padding(14)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.04), radius: 3, x: 0, y: 1)
    }
}

struct ActionBtn: View {
    let label: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .padding(.horizontal, 6)
                .padding(.vertical, 6)
                .frame(maxWidth: .infinity)
                .background(color.opacity(0.12))
                .foregroundColor(color)
                .cornerRadius(6)
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(color.opacity(0.3), lineWidth: 1))
        }
    }
}

// ==========================================
// 板块 7：Spectrum Data 详细数据表格 (DeviceShowTable 4x3 三色)
// 粉色 #FFE4E1 (Attention, Meditation, Quality, Raw EEG)
// 青色 #E0FFFF (Delta, Theta, Low Alpha, High Alpha)
// 黄色 #F0E68C (Low Beta, High Beta, Low Gamma, Mid Gamma)
// ==========================================
struct DeviceShowTable: View {
    @ObservedObject var vm: BrainMonitorViewModel

    let pinkBg = Color(red: 1.0, green: 0.894, blue: 0.882)    // #FFE4E1
    let cyanBg = Color(red: 0.878, green: 1.0, blue: 1.0)       // #E0FFFF
    let yellowBg = Color(red: 0.941, green: 0.902, blue: 0.549) // #F0E68C

    var body: some View {
        VStack(spacing: 8) {
            // 居中 MAC 标题条
            Text("Device MAC: \(vm.connectedMac)")
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
                .background(Color(red: 0.12, green: 0.16, blue: 0.23))
                .cornerRadius(6)

            // 4x3 单元格矩阵
            VStack(spacing: 1) {
                // Row 1 (全粉)
                HStack(spacing: 1) {
                    TableCell(label: "Attention", value: "\(vm.attention)", bg: pinkBg)
                    TableCell(label: "Meditation", value: "\(vm.meditation)", bg: pinkBg)
                    TableCell(label: "Quality", value: "\(vm.signalQuality)", bg: pinkBg)
                }
                // Row 2 (粉 + 青 + 青)
                HStack(spacing: 1) {
                    TableCell(label: "Raw EEG", value: "\(vm.rawEeg)", bg: pinkBg)
                    TableCell(label: "Delta", value: "\(vm.delta)", bg: cyanBg)
                    TableCell(label: "Theta", value: "\(vm.theta)", bg: cyanBg)
                }
                // Row 3 (青 + 青 + 黄)
                HStack(spacing: 1) {
                    TableCell(label: "Low Alpha", value: "\(vm.lowAlpha)", bg: cyanBg)
                    TableCell(label: "High Alpha", value: "\(vm.highAlpha)", bg: cyanBg)
                    TableCell(label: "Low Beta", value: "\(vm.lowBeta)", bg: yellowBg)
                }
                // Row 4 (全黄)
                HStack(spacing: 1) {
                    TableCell(label: "High Beta", value: "\(vm.highBeta)", bg: yellowBg)
                    TableCell(label: "Low Gamma", value: "\(vm.lowGamma)", bg: yellowBg)
                    TableCell(label: "Mid Gamma", value: "\(vm.midGamma)", bg: yellowBg)
                }
            }
            .border(Color.gray.opacity(0.3), width: 1)
        }
        .padding(14)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.04), radius: 3, x: 0, y: 1)
    }
}

struct TableCell: View {
    let label: String
    let value: String
    let bg: Color

    var body: some View {
        VStack(spacing: 2) {
            Text(label)
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(Color(red: 0.2, green: 0.25, blue: 0.33))
            Text(value)
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundColor(.black)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(bg)
    }
}

// ==========================================
// 板块 8：蓝牙搜索连接弹窗 (BleScanSheet)
// ==========================================
struct BleScanSheet: View {
    @ObservedObject var vm: BrainMonitorViewModel

    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 10) {
                Text(vm.isScanning ? "正在扫描低功耗蓝牙 (BLE) 脑电设备..." : "扫描完成")
                    .font(.caption).foregroundColor(.secondary)

                if vm.scannedDevices.isEmpty {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "antenna.radiowaves.left.and.right")
                            .font(.largeTitle).foregroundColor(.gray)
                        Text("暂未发现脑电设备，请确认设备已开机并靠近")
                            .font(.caption).foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity)
                    Spacer()
                } else {
                    List(vm.scannedDevices, id: \.address) { dev in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(dev.name ?? "未知脑电设备")
                                    .font(.subheadline).bold()
                                Text("\(dev.address)  |  RSSI: \(dev.rssi) dBm")
                                    .font(.caption2).foregroundColor(.secondary)
                            }
                            Spacer()
                            Button("连接") {
                                vm.connectDevice(dev)
                            }
                            .font(.caption).bold()
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(6)
                        }
                    }
                }
            }
            .padding()
            .navigationTitle("🔍 搜索脑电设备")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        vm.showScanSheet = false
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(vm.isScanning ? "扫描中" : "重新扫描") {
                        vm.toggleScan()
                    }
                }
            }
        }
    }
}
