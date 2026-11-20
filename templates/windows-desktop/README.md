# ZKBrain Windows 桌面端二次开发样板

> 适用技术栈：**Python 3.x**、**C# (.NET / WPF / WinUI)**、**C/C++**

本项目提供了基于 Windows 原生底层动态库 (`bin/x64/zkbrain_sec.dll`) 的快速接入示例，支持通过 **BLE 蓝牙** 或 **USB 串口** 直连 NeuroSky 与 ZKTeco 脑电设备。

---

## 🐍 1. Python 极速上手 (5 行代码)

进入 `python/` 目录：
```bash
cd python
pip install bleak numpy
python ble_connect_demo.py
```
- 自动扫描周围蓝牙脑电设备；
- 原生解析 512Hz 原始脑电波形与 1Hz 专注度/放松度。

---

## 🔷 2. C# (.NET / WPF) 极速上手

进入 `csharp/` 目录：
```bash
cd csharp
dotnet run
```
- 基于 Windows.Devices.Bluetooth 原生 WinRT 蓝牙协议栈；
- 内置 `BleManager.cs` 自动处理设备重连与数据流分发。
