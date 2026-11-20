# ZKBrain Unity 3D / XR BCI Interaction Scaffold

> 🎮 **Designed for Game Development, VR/XR (Apple Vision Pro, Meta Quest, Pico 4) and 3D Telekinesis Interaction**: Built-in real-time attention telekinesis levitation, particle emission feedback, and 1:1 `DeviceScreen + DeviceShowTable` console.

---

## 🌟 Key Features

1. **Mind-Controlled Telekinesis Levitation Sphere (`ForceLevitationController.cs`)**:
   - Real-time attention monitoring (Attention 0-100);
   - Higher attention causes 3D objects to float higher, accompanied by aura intensity and smooth color transition (Blue -> Yellow);
   - Ready to use, attachable to any 3D GameObject.
2. **1:1 Device Management Console (`DeviceScreenUI.cs`)**:
   - Full 4x3 tri-color EEG Spectrum matrix (Pink, Cyan, Yellow);
   - 6-axis MEMS Euler angles and Quaternion spatial attitude mapping;
   - NeuroSky XMW binary ignition packet and hardware command terminal.
3. **Cross-Platform Deployment**:
   - Supports Windows / Mac Standalone, Android / iOS native build, Meta Quest 2/3/Pro, Pico 4, Apple Vision Pro.

---

## 🛠️ Quick Start Guide

1. Open Unity Editor (Recommended: Unity 2021.3 LTS / 2022.3 LTS / Unity 6);
2. Drag `Assets/Scripts/` into your Unity project's `Assets/` directory;
3. In the Hierarchy scene, create an empty GameObject and attach `ZKBrainBleBridge.cs` and `DeviceScreenUI.cs`;
4. Create a 3D Sphere, attach `ForceLevitationController.cs`, and click Play to start the mind-controlled levitation experience!
