# ZKBrain 树莓派 / Linux IoT 边缘网关脚手架

> ⚡ **专为智慧工地安全帽、车载司机疲劳监测、智能轮椅与工业边缘计算打造**：开机自启 BLE 守护进程、硬件 GPIO 蜂鸣器超限报警与局域网 1:1 `DeviceScreen + DeviceShowTable` Web 监控看板。

---

## 🌟 核心特性

1. **后台边缘疲劳守护进程 (`daemon_fatigue_alert.py`)**：
   - 自动扫描并秒级静默重连 ZKBrain / NeuroSky 脑电设备；
   - 实时计算注意力涣散与疲劳指数；
   - 超出阈值时触发树莓派物理 GPIO 引脚 18（驱动高电平蜂鸣器、震动电机或车载继电器）。
2. **局域网 1:1 Web 监控看板 (`edge_web_dashboard.py`)**：
   - 内置零依赖轻量 Web 服务，在车间局域网或车载 Wi-Fi 下，手机、平板或中控屏打开 `http://<IP>:8080` 即可实时查看 1:1 三色脑电数据表与 MEMS 姿态。

---

## 🛠️ 快速启动

```bash
# 1. 安装边缘依赖
pip install -r requirements.txt

# 2. 启动疲劳报警守护进程
python daemon_fatigue_alert.py

# 3. 启动局域网 Web 监控看板
python edge_web_dashboard.py
```
