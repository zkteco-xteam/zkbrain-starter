#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
=============================================================================
ZKBrain Windows SDK - Classic Bluetooth / Virtual Serial Port (COM) Client
=============================================================================
Use cases:
  1. MindWave original USB Bluetooth receiver dongle (identified as COM port);
  2. Bluetooth SPP virtual serial port paired in Windows;
  3. CP2102 / CH340 / FTDI USB-to-UART bridge modules.

Prerequisites:
  pip install pyserial
=============================================================================
"""

import os
import sys
import time
import ctypes

# Fix Windows console UTF-8 stdout encoding
if sys.platform == "win32":
    try:
        sys.stdout.reconfigure(encoding='utf-8')
        sys.stderr.reconfigure(encoding='utf-8')
    except Exception:
        pass

try:
    import serial
    import serial.tools.list_ports
except ImportError:
    print("\n[Error] pyserial library is not installed in current environment!")
    print("Please run: pip install pyserial\n")
    sys.exit(1)

# =========================================================================
# 1. Load ZKBrain Windows Core Dynamic Library
# =========================================================================
DLL_REL_PATH = os.path.join(os.path.dirname(__file__), "../../bin/x64/zkbrain_sec.dll")
DLL_PATH = os.path.abspath(DLL_REL_PATH)

if not os.path.exists(DLL_PATH):
    print(f"[Fatal Error] Core library not found: {DLL_PATH}")
    sys.exit(1)

zkbrain = ctypes.CDLL(DLL_PATH)

# C function signatures
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

def on_brain_data(data_ptr, hw_ver, temp, user_data):
    data = [data_ptr[i] for i in range(15)]
    signal = data[0]
    attention = data[1]
    meditation = data[2]
    battery = data[4]

    print("-" * 60)
    if signal == 0:
        print(f"[Good Signal] Attention: {attention:3d} | Meditation: {meditation:3d} | Battery: {battery:2d}% | Temp: {temp:.1f} C")
    elif signal == 200:
        print("[Off-Head Warning] Sensor detached from forehead (Signal=200)")
    else:
        print(f"[Poor Signal Contact] Signal quality code: {signal}")
    print("-" * 60)

c_brain_cb = BRAIN_DATA_CB(on_brain_data)

def main():
    print("================================================================")
    print("      ZKBrain Windows Serial / Classic SPP BCI Client          ")
    print("================================================================")

    # 1. License check
    lic_path = os.path.join(os.path.dirname(__file__), "license.lic")
    if not os.path.exists(lic_path):
        lic_path = os.path.join(os.path.dirname(__file__), "../../license.lic")

    with open(lic_path, "r", encoding="utf-8") as f:
        lic_content = f.read()

    auth_code = zkbrain.zkbrain_sec_init(lic_content.encode("utf-8"))
    if auth_code != 1024:
        print(f"[Error] License verification failed, code: {auth_code}")
        return

    print("License authorized successfully (Code: 1024)!")

    # 2. List available COM ports
    ports = list(serial.tools.list_ports.comports())
    if not ports:
        print("No available COM ports found! Please plug in USB receiver or pair via Bluetooth.")
        return

    print(f"\nDiscovered {len(ports)} available port(s):")
    for idx, p in enumerate(ports):
        print(f"  [{idx + 1}] {p.device} - {p.description}")

    sel = 0
    if len(ports) > 1:
        sel = int(input("\nSelect port index to connect: ").strip()) - 1
    selected_port = ports[sel].device

    # 3. Create parser and open port
    parser = zkbrain.zkbrain_parser_create()
    zkbrain.zkbrain_parser_set_callbacks(parser, c_brain_cb, None, None, None, None, None)

    BAUDRATE = 57600
    print(f"\nOpening port {selected_port} (Baudrate {BAUDRATE}) ...")
    try:
        ser = serial.Serial(selected_port, BAUDRATE, timeout=1.0)
    except Exception as e:
        print(f"Failed to open serial port: {e}")
        zkbrain.zkbrain_parser_destroy(parser)
        return

    print("Serial port ready! Streaming bytes into SDK parser (Press Ctrl+C to stop)...")
    try:
        while True:
            raw_chunk = ser.read(64)
            if raw_chunk:
                c_buf = (ctypes.c_uint8 * len(raw_chunk)).from_buffer_copy(raw_chunk)
                zkbrain.zkbrain_parser_parse(parser, c_buf, len(raw_chunk))
            else:
                time.sleep(0.01)
    except KeyboardInterrupt:
        print("\nSession stopped by user.")
    finally:
        ser.close()
        zkbrain.zkbrain_parser_destroy(parser)
        print("Serial port closed, parser destroyed safely.")

if __name__ == "__main__":
    main()
