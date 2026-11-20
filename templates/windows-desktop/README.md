# ZKBrain Windows Desktop Starter Template

> Supported Technologies: **Python 3.x**, **C# (.NET / WPF / WinUI)**, **C/C++**

This project provides rapid integration examples based on the native Windows x64 dynamic link library (`bin/x64/zkbrain_sec.dll`), supporting direct connectivity with NeuroSky and ZKTeco BCI hardware via **Bluetooth Low Energy (BLE)** or **USB Serial (COM)**.

---

## 1. Python Quickstart

Enter the `python/` directory:
```bash
cd python
# Run the 1:1 DeviceScreen Desktop GUI Console (Tkinter, zero external dependencies)
python gui_demo.py

# Or run the command-line BLE auto-scan and demodulation script
pip install bleak numpy
python ble_connect_demo.py
```
- **`gui_demo.py`**: Complete 1:1 realization of the shared1 device management console (7 core sections, 4x3 color-coded spectrum matrix, and BLE device scan dialog).
- **`ble_connect_demo.py`**: Automatically scans nearby BLE BCI devices, natively demodulating 512Hz raw waveform and 1Hz attention/meditation.

---

## 2. C# (.NET / WPF) Quickstart

Enter the `csharp/` directory:
```bash
cd csharp
dotnet run
```
- Built on Windows.Devices.Bluetooth native WinRT BLE protocol stack;
- Built-in `BleManager.cs` automatically handles device reconnection and data flow dispatch.
