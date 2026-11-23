# ZKBrain ESP32 Precompiled Static Binary Archives

> **Organization**: **ZKTeco Brain-Computer Interface Division**  
> **Purpose**: Commercial binary distribution & IP protection. Contains precompiled static archives with zero exposed protocol source code.

---

## 1. Precompiled Targets

| Target Architecture | Chip Model | Precompiled Archive | Toolchain / ABI |
| :--- | :--- | :--- | :--- |
| **Xtensa LX6 (Dual Core)** | Classic ESP32 (WROOM-32, NodeMCU-32S) | [`esp32/libzkbrain_esp32_lx6.a`](esp32/libzkbrain_esp32_lx6.a) | `xtensa-esp32-elf` (ESP-IDF v5 / Arduino 3.x) |
| **Xtensa LX7 (Dual Core)** | ESP32-S3 (DevKitC-1, Feather ESP32-S3) | [`esp32s3/libzkbrain_esp32_s3.a`](esp32s3/libzkbrain_esp32_s3.a) | `xtensa-esp32s3-elf` (ESP-IDF v5 / Arduino 3.x) |
| **RISC-V 32-bit (Single Core)** | ESP32-C3 (DevKitM-1, Stamp C3) | [`esp32c3/libzkbrain_esp32_c3.a`](esp32c3/libzkbrain_esp32_c3.a) | `riscv32-esp-elf` (ESP-IDF v5 / Arduino 3.x) |

---

## 2. Integration in PlatformIO (`platformio.ini`)

To link the precompiled `.a` directly without compiling SDK source code:

```ini
[env:esp32dev]
platform = espressif32
board = esp32dev
framework = arduino
build_flags =
    -I lib/ZKBrain/src
    -L precompiled/esp32
    -lzkbrain_esp32_lx6

[env:esp32-s3-devkitc-1]
platform = espressif32
board = esp32-s3-devkitc-1
framework = arduino
build_flags =
    -I lib/ZKBrain/src
    -L precompiled/esp32s3
    -lzkbrain_esp32_s3

[env:esp32-c3-devkitm-1]
platform = espressif32
board = esp32-c3-devkitm-1
framework = arduino
build_flags =
    -I lib/ZKBrain/src
    -L precompiled/esp32c3
    -lzkbrain_esp32_c3
```

---

## 3. Integration in Arduino IDE

For closed-source distribution to external customers:
1. Provide only [`lib/ZKBrain/src/ZKBrain.h`](../lib/ZKBrain/src/ZKBrain.h) and the corresponding `.a` file.
2. Place the `.a` in the library's `src/esp32/`, `src/esp32s3/`, or `src/esp32c3/` directory.
3. Arduino IDE 2.0+ automatically links architecture-specific `.a` archives found inside the library folder.
