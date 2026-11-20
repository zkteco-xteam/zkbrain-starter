// swift-tools-version:5.7
import PackageDescription

let package = Package(
    name: "ZKBrainIosStarter",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .executable(name: "BrainMonitorApp", targets: ["BrainMonitorApp"])
    ],
    dependencies: [
        // 🌟 核心：通过 Swift Package Manager (SPM) 一行直接拉取 ZKBrain iOS SDK
        .package(url: "https://github.com/zkteco-xteam/zkbrain.git", from: "1.2.0")
    ],
    targets: [
        .executableTarget(
            name: "BrainMonitorApp",
            dependencies: [
                .product(name: "ZKBrainSDK", package: "zkbrain")
            ],
            path: "Sources"
        )
    ]
)
