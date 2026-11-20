import SwiftUI
import zkbrain_parser

@MainActor
class BrainMonitorViewModel: ObservableObject {
    @Published var connectionStatus: String = "DISCONNECTED"
    @Published var connectedName: String = "未连接脑电设备"
    @Published var attention: Int32 = 0
    @Published var meditation: Int32 = 0
    @Published var isGoodContact: Bool = false
    @Published var isScanning: Bool = false
    @Published var flowLevel: String = "平静日常"
    @Published var fatigueRate: Int = 0

    // 8 频段绝对功率
    @Published var delta: Int32 = 0
    @Published var theta: Int32 = 0
    @Published var lowAlpha: Int32 = 0
    @Published var highAlpha: Int32 = 0
    @Published var lowBeta: Int32 = 0
    @Published var highBeta: Int32 = 0
    @Published var lowGamma: Int32 = 0
    @Published var midGamma: Int32 = 0

    @Published var scannedDevices: [ZKBrainDevice] = []

    func toggleScan() {
        if isScanning {
            ZKBrainManager.shared.stopScan()
            isScanning = false
        } else {
            isScanning = true
            ZKBrainManager.shared.startScan(timeoutMillis: 10000, isContinuous: false)
        }
    }

    func connectDevice(_ device: ZKBrainDevice) {
        ZKBrainManager.shared.stopScan()
        isScanning = false
        ZKBrainManager.shared.connect(device: device)
    }

    func disconnect() {
        ZKBrainManager.shared.disconnect()
    }

    func startListeningData() {
        // 🌟 核心：借助 Touchlab SKIE 自动生成的 AsyncSequence，使用原生 Swift async/await 消费
        Task {
            for await eeg in ZKBrainManager.shared.brainData {
                self.attention = eeg.attention
                self.meditation = eeg.meditation
                self.isGoodContact = (eeg.poorSignal == 0)

                self.delta = eeg.delta
                self.theta = eeg.theta
                self.lowAlpha = eeg.lowAlpha
                self.highAlpha = eeg.highAlpha
                self.lowBeta = eeg.lowBeta
                self.highBeta = eeg.highBeta
                self.lowGamma = eeg.lowGamma
                self.midGamma = eeg.midGamma

                // 计算疲劳与心流
                let active = max(1, Int(eeg.lowBeta + eeg.highBeta + eeg.lowAlpha))
                self.fatigueRate = min(100, Int((Double(eeg.theta) / Double(active)) * 80))

                if eeg.attention >= 75 && eeg.meditation >= 60 {
                    self.flowLevel = "✨ 深度心流 (Deep Flow)"
                } else if eeg.attention >= 65 {
                    self.flowLevel = "🎯 高度专注 (Focused)"
                } else if eeg.meditation >= 70 {
                    self.flowLevel = "🧘 放松冥想 (Meditation)"
                } else {
                    self.flowLevel = "平静日常 (Normal)"
                }
            }
        }

        Task {
            for await conn in ZKBrainManager.shared.connState {
                self.connectionStatus = conn.name
            }
        }

        Task {
            for await dev in ZKBrainManager.shared.connectedDevice {
                self.connectedName = dev?.name ?? "已配对设备"
            }
        }

        Task {
            for await list in ZKBrainManager.shared.scannedDevices {
                self.scannedDevices = list
            }
        }
    }
}

struct ContentView: View {
    @StateObject private var vm = BrainMonitorViewModel()

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // ==========================================
                    // 1. 蓝牙设备状态卡片
                    // ==========================================
                    HStack {
                        Circle()
                            .fill(vm.connectionStatus == "CONNECTED" ? Color.green : (vm.connectionStatus == "CONNECTING" ? Color.orange : Color.red))
                            .frame(width: 12, height: 12)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("蓝牙状态: \(vm.connectionStatus)")
                                .font(.headline)
                            Text(vm.connectedName)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        if vm.connectionStatus == "CONNECTED" {
                            Button("断开") { vm.disconnect() }
                                .foregroundColor(.red)
                        } else {
                            Button(vm.isScanning ? "停止扫描" : "⚡ 扫描设备") {
                                vm.toggleScan()
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                        }
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)

                    // ==========================================
                    // 2. 专注度与心流大屏
                    // ==========================================
                    VStack(alignment: .leading, spacing: 14) {
                        HStack {
                            Text("认知指标")
                                .font(.headline)
                            Spacer()
                            Text(vm.flowLevel)
                                .font(.subheadline).bold()
                                .foregroundColor(.orange)
                        }

                        // 专注度
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("专注度 (Attention)")
                                Spacer()
                                Text("\(vm.attention) / 100").bold().foregroundColor(.blue)
                            }
                            ProgressView(value: Double(vm.attention), total: 100.0)
                                .accentColor(.blue)
                        }

                        // 放松度
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("放松度 (Meditation)")
                                Spacer()
                                Text("\(vm.meditation) / 100").bold().foregroundColor(.green)
                            }
                            ProgressView(value: Double(vm.meditation), total: 100.0)
                                .accentColor(.green)
                        }

                        HStack {
                            Text("疲劳预警指数:")
                                .font(.caption).foregroundColor(.secondary)
                            Spacer()
                            Text("\(vm.fatigueRate)%")
                                .font(.caption).bold()
                                .foregroundColor(vm.fatigueRate >= 60 ? .red : .green)
                        }

                        HStack {
                            Text("电极接触:")
                                .font(.caption).foregroundColor(.secondary)
                            Spacer()
                            Text(vm.isGoodContact ? "🟢 接触良好 (0)" : "🔴 接触不良或脱落")
                                .font(.caption).bold()
                                .foregroundColor(vm.isGoodContact ? .green : .red)
                        }
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)

                    // ==========================================
                    // 3. 脑电 8 频段功率谱能量
                    // ==========================================
                    VStack(alignment: .leading, spacing: 8) {
                        Text("8 频段绝对功率谱分布 (Band Powers)")
                            .font(.headline)
                        BandPowerBar(title: "Delta (0.5-2.75Hz 深度睡眠)", value: vm.delta, color: .indigo)
                        BandPowerBar(title: "Theta (3.5-6.75Hz 潜意识/冥想)", value: vm.theta, color: .teal)
                        BandPowerBar(title: "Low Alpha (7.5-9.25Hz 放松心流)", value: vm.lowAlpha, color: .green)
                        BandPowerBar(title: "High Alpha (10-11.75Hz 心流静定)", value: vm.highAlpha, color: .mint)
                        BandPowerBar(title: "Low Beta (13-16.75Hz 警觉专注)", value: vm.lowBeta, color: .yellow)
                        BandPowerBar(title: "High Beta (17-29.75Hz 计算焦虑)", value: vm.highBeta, color: .orange)
                        BandPowerBar(title: "Low Gamma (31-39.75Hz 认知加工)", value: vm.lowGamma, color: .pink)
                        BandPowerBar(title: "Mid Gamma (41-49.75Hz 高阶感知)", value: vm.midGamma, color: .purple)
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)

                    // ==========================================
                    // 4. 周围发现的脑电设备列表
                    // ==========================================
                    if !vm.scannedDevices.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("发现的脑电设备 (点击配对建连)")
                                .font(.headline)
                            ForEach(vm.scannedDevices, id: \.address) { dev in
                                Button(action: { vm.connectDevice(dev) }) {
                                    HStack {
                                        VStack(alignment: .leading) {
                                            Text(dev.name ?? "未知脑电设备")
                                                .font(.body).foregroundColor(.primary)
                                            Text(dev.address)
                                                .font(.caption).foregroundColor(.secondary)
                                        }
                                        Spacer()
                                        Text("\(dev.rssi) dBm")
                                            .font(.caption).foregroundColor(.blue)
                                    }
                                    .padding(8)
                                    .background(Color(.tertiarySystemBackground))
                                    .cornerRadius(8)
                                }
                            }
                        }
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(12)
                    }
                }
                .padding()
            }
            .navigationTitle("ZKBrain 脑机交互")
            .onAppear {
                vm.startListeningData()
            }
        }
    }
}

struct BandPowerBar: View {
    let title: String
    let value: Int32
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text(title).font(.caption2).foregroundColor(.secondary)
                Spacer()
                Text("\(value)").font(.caption2).bold()
            }
            ProgressView(value: Double(value % 100000), total: 100000.0)
                .accentColor(color)
                .scaleEffect(x: 1, y: 1.5, anchor: .center)
        }
    }
}
