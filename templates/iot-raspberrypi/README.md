# ZKBrain Raspberry Pi / Linux IoT Edge Gateway Starter

> Designed for smart helmets, driver fatigue monitoring, intelligent wheelchairs, and industrial edge computing: boot-time auto-restart BLE daemon, hardware GPIO buzzer alerts, and LAN 1:1 `DeviceScreen + DeviceShowTable` web dashboard.

---

## Key Features

1. **Background Fatigue Alert Daemon (`daemon_fatigue_alert.py`)**:
   - Auto-scans and reconnects to ZKBrain / NeuroSky hardware in seconds;
   - Real-time distraction and fatigue index evaluation;
   - Triggers Raspberry Pi physical GPIO pin 18 (driving high-level buzzer, vibration motor, or relay) upon threshold breach.
2. **LAN 1:1 Web Monitoring Dashboard (`edge_web_dashboard.py`)**:
   - Zero-dependency lightweight HTTP service. Accessible via `http://<IP>:8080` from mobile, tablet, or central console to view the 1:1 color-coded EEG spectrum table and MEMS attitude in real time.

---

## Quickstart

```bash
# 1. Install dependencies
pip install -r requirements.txt

# 2. Start fatigue alert daemon
python daemon_fatigue_alert.py

# 3. Start LAN Web Dashboard
python edge_web_dashboard.py
```
