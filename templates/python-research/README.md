# ZKBrain Python Research & Algorithm Workstation

> Designed for academic research teams, neuroscience laboratories, and algorithm engineers: integrated MNE-Python filtering pipeline, Welch PSD power spectral density estimation, standard EDF+/CSV dataset export, and 1:1 `DeviceScreen + DeviceShowTable` desktop console.

---

## Key Features

1. **Interactive Jupyter Notebook Algorithm Pipeline (`zkbrain_eeg_analysis.ipynb`)**:
   - 0.5~50Hz zero-phase Butterworth bandpass filter + 50Hz notch filter;
   - Standard 10-20 system forehead single-channel (FP1) montage montage assembly;
   - Welch PSD algorithm computing Delta / Theta / Alpha / Beta / Gamma 8-band absolute power;
   - One-click export to international clinical and research standard **EDF+** and **CSV** files, seamlessly compatible with **EEGLAB**, **BrainVision Analyzer**, and **Polyman**.
2. **1:1 Desktop Console (`research_gui.py`)**:
   - 4x3 color-coded EEG spectrum metrics table;
   - 6-axis MEMS attitude sensing and command terminal monitor;
   - One-click EDF/CSV export and PSD spectrum analysis.

---

## Quickstart

```bash
# 1. Install research dependencies
pip install -r requirements.txt

# 2. Launch 1:1 Research GUI Console
python research_gui.py

# 3. Or launch interactive Jupyter Notebook pipeline
jupyter notebook zkbrain_eeg_analysis.ipynb
```
