# ZKBrain Python 科研算法与数据分析工作站

> 🔬 **专为高校科研团队、神经科学实验室与算法工程师打造**：集成 MNE-Python 滤波流水线、Welch PSD 功率谱分析、国际标准 EDF+/CSV 导出与 1:1 `DeviceScreen + DeviceShowTable` 桌面控制台。

---

## 🌟 核心特性

1. **Jupyter Notebook 科研算法交互流水线 (`zkbrain_eeg_analysis.ipynb`)**：
   - 0.5~50Hz 双向巴特沃斯带通滤波 + 50Hz 工频陷波；
   - 国际 10-20 系统单导额贴 (FP1) 脑电蒙太奇封装；
   - Welch 算法计算 Delta / Theta / Alpha / Beta / Gamma 8 频段功率谱密度；
   - 一键导出符合国际医学与科研标准的 **EDF+** 与 **CSV** 文件，无缝对接 **EEGLAB**、**BrainVision Analyzer** 与 **Polyman**。
2. **1:1 桌面控制台 (`research_gui.py`)**：
   - 包含 4x3 三色脑电 Spectrum 数据表；
   - 6 轴 MEMS 姿态传感与终端指令监控；
   - 一键执行科研导出与 PSD 功率谱分析。

---

## 🛠️ 快速启动

```bash
# 1. 安装科研算法依赖
pip install -r requirements.txt

# 2. 启动 1:1 可视化科研控制台
python research_gui.py

# 3. 或启动交互式 Jupyter Notebook 流水线
jupyter notebook zkbrain_eeg_analysis.ipynb
```
