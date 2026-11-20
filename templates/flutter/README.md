# ZKBrain Flutter Cross-Platform BCI Starter Template

Official cross-platform Flutter BCI starter project supporting both Android and iOS.

> **Technical Support**: ZKTeco Brain-Computer Interface Division

---

## Key Features

- **Out of the box**: Integrated `flutter_blue_plus` reactive Bluetooth Low Energy (BLE) scan and connection.
- **Android & iOS Permissions Ready**: Pre-configured Android 12+ runtime permissions and iOS 13+ BLE usage descriptions.
- **Comprehensive Interactive Dashboard**:
  - 1Hz Attention and Meditation progress indicators;
  - 8-band power spectrum color bars (Delta, Theta, Alpha, Beta, Gamma);
  - Flow depth index and fatigue alert model based on theta / (alpha + beta) power ratio;
  - 512Hz raw EEG waveform CustomPaint oscilloscope with real-time sample rate stats.

---

## Quickstart

```bash
# 1. Fetch dependencies
flutter pub get

# 2. Run on device
flutter run
```
