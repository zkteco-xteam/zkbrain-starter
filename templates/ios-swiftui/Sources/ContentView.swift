import SwiftUI
import zkbrain_parser

@MainActor
class BrainMonitorViewModel: ObservableObject {
    @Published var connectionStatus: String = "未连接"
    @Published var attention: Int32 = 0
    @Published var meditation: Int32 = 0
    @Published var isGoodContact: Bool = false
    @Published var isScanning: Bool = false

    func startScan() {
        isScanning = true
        ZKBrainManager.shared.startScan(timeoutMillis: 10000, isContinuous: false)
    }

    func startListeningData() {
        // 🌟 核心：借助 Touchlab SKIE 自动生成的 AsyncSequence，使用原生 Swift async/await 消费
        Task {
            for await eeg in ZKBrainManager.shared.brainData {
                self.attention = eeg.attention
                self.meditation = eeg.meditation
                self.isGoodContact = (eeg.poorSignal == 0)
            }
        }

        Task {
            for await conn in ZKBrainManager.shared.connState {
                self.connectionStatus = conn.name
            }
        }
    }
}

struct ContentView: View {
    @StateObject private var vm = BrainMonitorViewModel()

    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // 1. 状态指示卡片
                HStack {
                    Circle()
                        .fill(vm.connectionStatus == "CONNECTED" ? Color.green : Color.orange)
                        .frame(width: 12, height: 12)
                    Text("设备状态: \(vm.connectionStatus)")
                        .font(.headline)
                    Spacer()
                    Button(action: { vm.startScan() }) {
                        Text(vm.isScanning ? "正在扫描..." : "扫描设备")
                            .font(.subheadline)
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

                // 2. 专注度 (Attention) 仪表
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("专注度 (Attention)")
                            .font(.headline)
                        Spacer()
                        Text("\(vm.attention) / 100")
                            .font(.title2).bold()
                            .foregroundColor(.blue)
                    }
                    ProgressView(value: Double(vm.attention), total: 100.0)
                        .accentColor(.blue)
                        .scaleEffect(x: 1, y: 2, anchor: .center)
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)

                // 3. 放松度 (Meditation) 仪表
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("放松度 (Meditation)")
                            .font(.headline)
                        Spacer()
                        Text("\(vm.meditation) / 100")
                            .font(.title2).bold()
                            .foregroundColor(.green)
                    }
                    ProgressView(value: Double(vm.meditation), total: 100.0)
                        .accentColor(.green)
                        .scaleEffect(x: 1, y: 2, anchor: .center)
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)

                // 4. 信号接触指示
                HStack {
                    Text("电极皮肤接触:")
                    Spacer()
                    Text(vm.isGoodContact ? "🟢 良好接触" : "🔴 接触不良或脱落")
                        .bold()
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)

                Spacer()
            }
            .padding()
            .navigationTitle("ZKBrain iOS 监控台")
            .onAppear {
                vm.startListeningData()
            }
        }
    }
}
