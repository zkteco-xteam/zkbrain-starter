#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
=============================================================================
ZKBrain Windows SDK - Bluetooth Low Energy (BLE) Auto Scan & Demodulation
=============================================================================
Features:
  1. Uses Windows 10/11 native BLE protocol stack via bleak asynchronous library;
  2. Automatically scans for nearby BCI hardware devices sorted by RSSI;
  3. Filters candidate devices by keywords (MindWave, Brain, EEG, TGAM, ZKT);
  4. Discovers GATT services and notify-capable characteristics;
  5. Feeds physical byte stream directly to zkbrain_sec.dll state machine parser;
  6. Outputs 1Hz Attention, Meditation, Signal Quality, and 8-band power spectrum.

Prerequisites:
  pip install bleak
=============================================================================
"""

import os
import sys
import asyncio
import ctypes
from typing import Optional

# Fix Windows console UTF-8 stdout encoding
if sys.platform == "win32":
    try:
        sys.stdout.reconfigure(encoding='utf-8')
        sys.stderr.reconfigure(encoding='utf-8')
    except Exception:
        pass

try:
    from bleak import BleakScanner, BleakClient
    from bleak.backends.characteristic import BleakGATTCharacteristic
except ImportError:
    print("\n[Error] bleak BLE library is not installed in current environment!")
    print("Please run: pip install bleak\n")
    sys.exit(1)

# =========================================================================
# 1. Load ZKBrain Windows x64 Core Dynamic Library
# =========================================================================
DLL_REL_PATH = os.path.join(os.path.dirname(__file__), "../../bin/x64/zkbrain_sec.dll")
DLL_PATH = os.path.abspath(DLL_REL_PATH)

if not os.path.exists(DLL_PATH):
    print(f"[Fatal Error] Core dynamic library not found: {DLL_PATH}")
    sys.exit(1)

zkbrain = ctypes.CDLL(DLL_PATH)

# C interface signatures
BRAIN_DATA_CB = ctypes.CFUNCTYPE(None, ctypes.POINTER(ctypes.c_int), ctypes.c_double, ctypes.c_float, ctypes.c_void_p)
RAW_WAVE_CB = ctypes.CFUNCTYPE(None, ctypes.c_int, ctypes.c_void_p)

zkbrain.zkbrain_sec_init.argtypes = [ctypes.c_char_p]
zkbrain.zkbrain_sec_init.restype = ctypes.c_int

zkbrain.zkbrain_parser_create.restype = ctypes.c_void_p
zkbrain.zkbrain_parser_destroy.argtypes = [ctypes.c_void_p]
zkbrain.zkbrain_parser_reset.argtypes = [ctypes.c_void_p]
zkbrain.zkbrain_parser_parse.argtypes = [ctypes.c_void_p, ctypes.POINTER(ctypes.c_uint8), ctypes.c_int]
zkbrain.zkbrain_parser_set_callbacks.argtypes = [
    ctypes.c_void_p,
    BRAIN_DATA_CB,
    RAW_WAVE_CB,
    ctypes.c_void_p,
    ctypes.c_void_p,
    ctypes.c_void_p,
    ctypes.c_void_p
]

# =========================================================================
# 2. Global State & Callbacks
# =========================================================================
parser_handle = None
g_packet_count = 0

def on_brain_data(data_ptr, hw_ver, temp, user_data):
    """
    1Hz composite metrics callback
    """
    data = [data_ptr[i] for i in range(15)]
    signal = data[0]
    attention = data[1]
    meditation = data[2]
    preference = data[3]
    battery = data[4]
    grind = data[5]
    heart_rate = data[6]

    # Power spectrum bands (7~14)
    delta = data[7]
    theta = data[8]
    low_alpha = data[9]
    high_alpha = data[10]
    low_beta = data[11]
    high_beta = data[12]
    low_gamma = data[13]
    mid_gamma = data[14]

    print("\n" + "=" * 65)
    if signal == 0:
        print(f"[Good Signal] Attention: \033[1;32m{attention:3d}\033[0m | Meditation: \033[1;34m{meditation:3d}\033[0m | Battery: {battery:2d}% | Temp: {temp:.1f} C")
        print(f"[8-Band Spectrum] Delta: {delta} | Theta: {theta} | LowAlpha: {low_alpha} | HighAlpha: {high_alpha}")
        print(f"                  LowBeta: {low_beta} | HighBeta: {high_beta} | LowGamma: {low_gamma} | MidGamma: {mid_gamma}")
    elif signal == 200:
        print("[Off-Head Warning] Sensor detached from forehead (Signal: 200)!")
    else:
        print(f"[Poor Signal Contact] Signal quality code: {signal} (ASIC algorithm in noise holding mode)")
    print("=" * 65)

def on_raw_wave(raw_value, user_data):
    """
    512Hz raw EEG microvolt waveform callback
    """
    global g_packet_count
    g_packet_count += 1
    if g_packet_count % 256 == 0:
        pass

c_brain_cb = BRAIN_DATA_CB(on_brain_data)
c_raw_cb = RAW_WAVE_CB(on_raw_wave)

# =========================================================================
# 3. BLE Notification Handler
# =========================================================================
def handle_ble_notification(characteristic: BleakGATTCharacteristic, data: bytearray):
    """
    Feed incoming Notify bytes directly to ZKBrain parser state machine
    """
    if parser_handle and len(data) > 0:
        c_bytes = (ctypes.c_uint8 * len(data)).from_buffer_copy(data)
        zkbrain.zkbrain_parser_parse(parser_handle, c_bytes, len(data))

# =========================================================================
# 4. BLE Auto-Scan & Connection Workflow
# =========================================================================
async def run_ble_workflow():
    global parser_handle

    print("================================================================")
    print("       ZKBrain Windows x64 Native BLE BCI Client               ")
    print("================================================================")

    # 1. License check
    lic_path = os.path.join(os.path.dirname(__file__), "license.lic")
    if not os.path.exists(lic_path):
        lic_path = os.path.join(os.path.dirname(__file__), "../../license.lic")

    with open(lic_path, "r", encoding="utf-8") as f:
        lic_content = f.read()

    auth_code = zkbrain.zkbrain_sec_init(lic_content.encode("utf-8"))
    if auth_code != 1024:
        print(f"[Fatal Error] License verification failed, code: {auth_code}")
        print("Please check license file or refer to README.md.")
        return

    print("License authorized successfully (Code: 1024)! Core algorithm engine unlocked.")

    # 2. Create parser
    parser_handle = zkbrain.zkbrain_parser_create()
    if not parser_handle:
        print("[Error] Failed to instantiate parser!")
        return

    zkbrain.zkbrain_parser_set_callbacks(
        parser_handle,
        c_brain_cb,
        c_raw_cb,
        None, None, None, None
    )

    # 3. Scan for nearby BLE devices
    print("\nScanning for nearby BLE BCI devices via Windows native Bluetooth (5s)...")
    devices = await BleakScanner.discover(timeout=5.0)

    if not devices:
        print("No Bluetooth devices discovered! Please verify:")
        print("   1. Windows Bluetooth is turned ON;")
        print("   2. Headband is powered on and in pairing/advertising mode (LED blinking).")
        zkbrain.zkbrain_parser_destroy(parser_handle)
        return

    # 4. Filter BCI devices
    KEYWORDS = ["brain", "mind", "eeg", "tgam", "zkt", "neuro", "macrotellect"]
    candidates = []

    print(f"\nDiscovered {len(devices)} advertising device(s):")
    for idx, d in enumerate(devices):
        name = d.name or "Unknown Device"
        rssi = getattr(d, 'rssi', -100)
        is_matched = any(kw in name.lower() for kw in KEYWORDS)
        mark = "-> [BCI DEVICE MATCH]" if is_matched else ""
        print(f"  [{idx + 1:2d}] {name:30s} (MAC: {d.address}) RSSI: {rssi} dBm {mark}")
        if is_matched:
            candidates.append(d)

    # 5. Select target device
    target_device = None
    if len(candidates) == 1:
        target_device = candidates[0]
        print(f"\nAutomatically selected BCI device: {target_device.name} ({target_device.address})")
    elif len(candidates) > 1:
        print(f"\nFound multiple candidate BCI devices, select one (1 - {len(candidates)}):")
        for i, c in enumerate(candidates):
            print(f"  [{i + 1}] {c.name} ({c.address})")
        sel = int(input("Enter index: ").strip()) - 1
        target_device = candidates[sel]
    else:
        print("\nNo devices matching Brain/EEG keywords found, enter index from list above:")
        choice = int(input("Enter device index (1 - N): ").strip()) - 1
        target_device = devices[choice]

    # 6. Establish GATT physical connection
    print(f"\nConnecting to device: {target_device.name} [{target_device.address}] ...")
    async with BleakClient(target_device.address) as client:
        if not client.is_connected:
            print("Connection failed! Please retry.")
            zkbrain.zkbrain_parser_destroy(parser_handle)
            return

        print("BLE physical link connected! Discovering GATT characteristics...")

        # 7. Find Notify characteristics
        notify_chars = []
        for service in client.services:
            for char in service.characteristics:
                if "notify" in char.properties:
                    notify_chars.append(char)

        if not notify_chars:
            print("No Notify-capable EEG data characteristics found on device!")
            zkbrain.zkbrain_parser_destroy(parser_handle)
            return

        selected_chars = []
        for ch in notify_chars:
            u = ch.uuid.lower()
            if "fff8" in u or "fff4" in u or "fff0" in u or len(notify_chars) <= 2:
                selected_chars.append(ch)

        if not selected_chars:
            selected_chars = notify_chars

        print(f"Subscribing to {len(selected_chars)} characteristic channel(s)...")
        for ch in selected_chars:
            print(f"  -> Starting notify on: {ch.uuid}")
            await client.start_notify(ch.uuid, handle_ble_notification)

        # Look for writable characteristic
        write_char = None
        for service in client.services:
            for char in service.characteristics:
                if "write" in char.properties or "write-without-response" in char.properties:
                    write_char = char
                    break
            if write_char:
                break

        if write_char:
            print(f"Found hardware write channel: {write_char.uuid}")
            print("   [Hardware Protocol Guide]:")
            print("   1. ZKTeco (Custom BCI/MEMS) ASCII Protocol:")
            print("      - Enable MEMS stream:   await client.write_gatt_char(write_char.uuid, b'mems_on:1;\\n')")
            print("      - Switch 512Hz rate:    await client.write_gatt_char(write_char.uuid, b'eeg_data_rate:512;\\n')")
            print("      - Query battery level:  await client.write_gatt_char(write_char.uuid, b'battery:?\\n')")
            print("   2. Sky (NeuroSky / MindWave) XMW 20B Binary Protocol:")
            print("      - Ignition packet (0x15 Raw + 0x17 Band): await client.write_gatt_char(write_char.uuid, bytearray([0x02, 0x15, 0x17]))")
            print("      - 50Hz notch filter (0x1B):              await client.write_gatt_char(write_char.uuid, bytearray([0x02, 0x1B]))")

        print("\nBCI stream ignited! Receiving real-time EEG packets...")
        print("Note: Algorithm requires 3-5s rolling window for baseline calibration. Press Ctrl+C to stop.\n")

        try:
            while client.is_connected:
                await asyncio.sleep(1.0)
        except asyncio.CancelledError:
            pass
        except KeyboardInterrupt:
            print("\nSession stopped by user.")
        finally:
            for ch in selected_chars:
                try:
                    await client.stop_notify(ch.uuid)
                except Exception:
                    pass

    # 8. Release parser
    if parser_handle:
        zkbrain.zkbrain_parser_destroy(parser_handle)
        parser_handle = None
    print("\nDevice disconnected, ZKBrain parser destroyed safely.")

if __name__ == "__main__":
    try:
        asyncio.run(run_ble_workflow())
    except KeyboardInterrupt:
        print("\nProgram terminated.")
