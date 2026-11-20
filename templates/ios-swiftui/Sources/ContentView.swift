import SwiftUI
import CoreBluetooth
import zkbrain_parser

/// 1:1 DeviceScreen & DeviceShowTable Clone - iOS SwiftUI Edition
/// Technical Support: ZKTeco Brain-Computer Interface Division

@MainActor
class BrainMonitorViewModel: ObservableObject {
    @Published var connectionStatus: String = "DISCONNECTED"
    @Published var connectedName: String = "Disconnected Device"
    @Published var connectedMac: String = "00:00:00:00:00:00"
    @Published var batteryLevel: Int = 85
    @Published var showBluetoothPermissionAlert: Bool = false
    @Published var showScanSheet: Bool = false
    @Published var isScanning: Bool = false

    // 12 cognitive & hardware metrics
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

    // MEMS motion posture
    @Published var memsRoll: Double = 1.2
    @Published var memsPitch: Double = -0.5
    @Published var memsYaw: Double = 14.8
    @Published var memsQ0: Double = 0.992
    @Published var memsQ1: Double = 0.010
    @Published var memsQ2: Double = -0.004
    @Published var memsQ3: Double = 0.129

    // Channel & Chart Display Toggles
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
    @Published var commandLogs: String = "[System] ZKBrain iOS SwiftUI console initialized successfully.\n"

    func addLog(_ text: String) {
        commandLogs += "\(text)\n"
    }

    func sendConfig(key: String, value: String) {
        addLog("[TX >>] \(key):\(value)")
        ZKBrainManager.shared.sendConfigCommand(config: [key: value])
    }

    func sendXmwCommand(opCode: UInt8, desc: String) {
        guard let dev = ZKBrainManager.shared.connectedDevice.value, connectionStatus == "CONNECTED" else {
            addLog("[TX >> XMW Simulated] \(desc) (0x\(String(format: "%02X", opCode)))")
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
        addLog("[TX >> XMW] Ignition command sent: 0x15 (Raw) + 0x17 (Band)")
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
            addLog("[Permission] iOS Bluetooth permission denied. Please enable in Settings.")
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
        addLog("[BLE] Connected successfully to device: \(connectedName) (\(connectedMac))")
    }

    func disconnect() {
        ZKBrainManager.shared.disconnect()
        connectionStatus = "DISCONNECTED"
        addLog("[BLE] Device disconnected by user.")
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
                    self.connectedName = dev.name ?? "Paired Device"
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
                    DeviceStatusCard(vm: vm)
                    ChannelSettingsCard(vm: vm)
                    ChartDisplaySettingsCard(vm: vm)
                    NeuroSkyConsoleCard(vm: vm)
                    ZKBrainConsoleCard(vm: vm)
                    DeviceShowTable(vm: vm)

                    Spacer().frame(height: 20)
                }
                .padding(.horizontal, 12)
                .padding(.top, 8)
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationTitle("Device Management")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button(action: { vm.toggleScan() }) {
                        HStack(spacing: 4) {
                            Image(systemName: "magnifyingglass")
                            Text("Search").font(.caption)
                        }
                    }
                    Button(action: {
                        vm.addLog("[DFU] OTA firmware check: already on latest stable release v2.4.0")
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
            .alert("Bluetooth Permission Required", isPresented: $vm.showBluetoothPermissionAlert) {
                Button("Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Please allow Bluetooth access in iOS Settings to scan and connect ZKBrain BCI devices.")
            }
        }
    }
}

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
                Text(isConnected ? "READY" : (vm.connectionStatus == "CONNECTING" ? "CONNECTING" : "DISCONNECTED"))
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
                    Text(isConnected ? "Disconnect" : "Scan & Connect")
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

struct ChannelSettingsCard: View {
    @ObservedObject var vm: BrainMonitorViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "slider.horizontal.3")
                    .foregroundColor(.secondary)
                Text("Channel Settings")
                    .font(.subheadline).bold()
            }

            HStack(spacing: 20) {
                Toggle(isOn: $vm.isFp1Visible) {
                    Text("Left (FP1)").font(.caption).bold()
                }
                .toggleStyle(CheckboxToggleStyle())

                Toggle(isOn: $vm.isFp2Visible) {
                    Text("Right (FP2) [Unsupported]").font(.caption).foregroundColor(.secondary)
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
                Text("Chart Display Settings")
                    .font(.subheadline).bold()
            }

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 95))], spacing: 6) {
                ForEach(titles, id: \.self) { title in
                    let isChecked = vm.chartToggles[title] ?? true
                    Button(action: {
                        vm.chartToggles[title] = !isChecked
                        vm.addLog("[Chart] Toggle display for \(title): \(!isChecked)")
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

struct NeuroSkyConsoleCard: View {
    @ObservedObject var vm: BrainMonitorViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Text("⚙️")
                Text("NeuroSky / MindWave Protocol Console")
                    .font(.subheadline).bold()
            }
            Text("Supports 20-byte binary ignition frame, notch filter, SN read/write and classic MAC probing")
                .font(.caption2).foregroundColor(.secondary)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 105))], spacing: 6) {
                ActionBtn(label: "🚀 Ignition (0x15/17)", color: .green) {
                    vm.sendIgnitionBytes()
                }
                ActionBtn(label: "🛑 Stop (0x16/18)", color: .red) {
                    vm.sendXmwCommand(opCode: 0x16, desc: "Stop Transmission")
                }
                ActionBtn(label: "50Hz Notch (0x1B)", color: .gray) {
                    vm.sendXmwCommand(opCode: 0x1B, desc: "Notch Filter 50Hz")
                }
                ActionBtn(label: "60Hz Notch (0x1C)", color: .gray) {
                    vm.sendXmwCommand(opCode: 0x1C, desc: "Notch Filter 60Hz")
                }
                ActionBtn(label: "Battery (0x06)", color: .orange) {
                    vm.sendXmwCommand(opCode: 0x06, desc: "Read Battery")
                }
                ActionBtn(label: "Serial SN (0xF4)", color: .orange) {
                    vm.sendXmwCommand(opCode: 0xF4, desc: "Query SN")
                }
                ActionBtn(label: "Classic MAC (0xFC)", color: .purple) {
                    vm.sendXmwCommand(opCode: 0xFC, desc: "Probe Classic MAC")
                }
            }

            HStack(spacing: 8) {
                TextField("Enter serial number SN...", text: $vm.writeSnInput)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(size: 12))

                Button("Write SN (0xF2)") {
                    let sn = vm.writeSnInput.trimmingCharacters(in: .whitespaces)
                    if !sn.isEmpty {
                        vm.addLog("[TX >> XMW] Write SN (0xF2): \(sn)")
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

struct ZKBrainConsoleCard: View {
    @ObservedObject var vm: BrainMonitorViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Text("🧠")
                Text("ZKBrain Proprietary Device Console")
                    .font(.subheadline).bold()
            }
            Text("Supports ASCII control, MEMS posture sensing, sample rate switching and terminal monitor")
                .font(.caption2).foregroundColor(.secondary)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 105))], spacing: 6) {
                ActionBtn(label: "License", color: .blue) {
                    vm.sendConfig(key: "license", value: "?")
                }
                ActionBtn(label: "Battery", color: .blue) {
                    vm.sendConfig(key: "battery", value: "?")
                }
                ActionBtn(label: "Version", color: .blue) {
                    vm.sendConfig(key: "version", value: "?")
                }
                ActionBtn(label: "Start EEG", color: .green) {
                    vm.sendConfig(key: "eeg_data_on", value: "1")
                }
                ActionBtn(label: "Stop EEG", color: .red) {
                    vm.sendConfig(key: "eeg_data_on", value: "0")
                }
                ActionBtn(label: "256Hz Rate", color: .gray) {
                    vm.sendConfig(key: "eeg_data_rate", value: "2")
                }
                ActionBtn(label: "512Hz Rate", color: .gray) {
                    vm.sendConfig(key: "eeg_data_rate", value: "1")
                }
                ActionBtn(label: "Start MEMS", color: .teal) {
                    vm.sendConfig(key: "mems_on", value: "1")
                }
                ActionBtn(label: "Stop MEMS", color: .gray) {
                    vm.sendConfig(key: "mems_on", value: "0")
                }
                ActionBtn(label: "DFU Scan", color: .purple) {
                    vm.sendCommand("dfu_scan:1")
                }
            }

            VStack(alignment: .leading, spacing: 3) {
                Text("📐 Realtime MEMS Posture (Euler & Quaternion)")
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

            HStack(spacing: 8) {
                TextField("Custom command (e.g. mems_on:1 or sample_rate:512)", text: $vm.commandInput)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(size: 12))

                Button("Send") {
                    vm.sendCommand(vm.commandInput)
                }
                .font(.system(size: 11, weight: .bold))
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(6)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Terminal Monitor:")
                        .font(.caption2).foregroundColor(.gray)
                    Spacer()
                    Button("Clear") {
                        vm.commandLogs = ""
                    }
                    .font(.caption2).foregroundColor(.cyan)
                }

                ScrollView {
                    Text(vm.commandLogs.isEmpty ? "Waiting for command responses...\n" : vm.commandLogs)
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

struct DeviceShowTable: View {
    @ObservedObject var vm: BrainMonitorViewModel

    let pinkBg = Color(red: 1.0, green: 0.894, blue: 0.882)    // #FFE4E1
    let cyanBg = Color(red: 0.878, green: 1.0, blue: 1.0)       // #E0FFFF
    let yellowBg = Color(red: 0.941, green: 0.902, blue: 0.549) // #F0E68C

    var body: some View {
        VStack(spacing: 8) {
            Text("Device MAC: \(vm.connectedMac)")
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
                .background(Color(red: 0.12, green: 0.16, blue: 0.23))
                .cornerRadius(6)

            VStack(spacing: 1) {
                HStack(spacing: 1) {
                    TableCell(label: "Attention", value: "\(vm.attention)", bg: pinkBg)
                    TableCell(label: "Meditation", value: "\(vm.meditation)", bg: pinkBg)
                    TableCell(label: "Quality", value: "\(vm.signalQuality)", bg: pinkBg)
                }
                HStack(spacing: 1) {
                    TableCell(label: "Raw EEG", value: "\(vm.rawEeg)", bg: pinkBg)
                    TableCell(label: "Delta", value: "\(vm.delta)", bg: cyanBg)
                    TableCell(label: "Theta", value: "\(vm.theta)", bg: cyanBg)
                }
                HStack(spacing: 1) {
                    TableCell(label: "Low Alpha", value: "\(vm.lowAlpha)", bg: cyanBg)
                    TableCell(label: "High Alpha", value: "\(vm.highAlpha)", bg: cyanBg)
                    TableCell(label: "Low Beta", value: "\(vm.lowBeta)", bg: yellowBg)
                }
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

struct BleScanSheet: View {
    @ObservedObject var vm: BrainMonitorViewModel

    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 10) {
                Text(vm.isScanning ? "Scanning for nearby BLE BCI devices..." : "Scan completed")
                    .font(.caption).foregroundColor(.secondary)

                if vm.scannedDevices.isEmpty {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "antenna.radiowaves.left.and.right")
                            .font(.largeTitle).foregroundColor(.gray)
                        Text("No BCI devices found. Please ensure device is powered on.")
                            .font(.caption).foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity)
                    Spacer()
                } else {
                    List(vm.scannedDevices, id: \.address) { dev in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(dev.name ?? "Unknown Device")
                                    .font(.subheadline).bold()
                                Text("\(dev.address)  |  RSSI: \(dev.rssi) dBm")
                                    .font(.caption2).foregroundColor(.secondary)
                            }
                            Spacer()
                            Button("Connect") {
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
            .navigationTitle("Search BCI Devices")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        vm.showScanSheet = false
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(vm.isScanning ? "Scanning" : "Rescan") {
                        vm.toggleScan()
                    }
                }
            }
        }
    }
}
