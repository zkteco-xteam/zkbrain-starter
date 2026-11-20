"""
ZKBrain Windows SDK Python (ctypes) Quickstart Example
Suitable for research data acquisition, machine learning offline analysis, or rapid prototyping on Windows.
"""

import os
import sys
import ctypes

# 1. Dynamically load Windows DLL (located at ../../bin/x64/zkbrain_sec.dll)
script_dir = os.path.dirname(os.path.abspath(__file__))
dll_path = os.path.abspath(os.path.join(script_dir, "..", "..", "bin", "x64", "zkbrain_sec.dll"))

if not os.path.exists(dll_path):
    raise FileNotFoundError(f"SDK dynamic library not found: {dll_path}")

zkbrain = ctypes.CDLL(dll_path)

# 2. Define C callback type signatures
BRAIN_DATA_CB = ctypes.CFUNCTYPE(None, ctypes.POINTER(ctypes.c_int), ctypes.c_double, ctypes.c_float, ctypes.c_void_p)
RAW_WAVE_CB = ctypes.CFUNCTYPE(None, ctypes.c_int, ctypes.c_void_p)

# 3. Set exported function parameter and return types
zkbrain.zkbrain_get_app_id.restype = ctypes.c_char_p
zkbrain.zkbrain_sec_init.argtypes = [ctypes.c_char_p]
zkbrain.zkbrain_sec_init.restype = ctypes.c_int

zkbrain.zkbrain_sec_has_feature.argtypes = [ctypes.c_char_p]
zkbrain.zkbrain_sec_has_feature.restype = ctypes.c_bool

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

# 4. Implement callback functions
def on_brain_data(int_data_ptr, hw, temp, user_data):
    int_data = [int_data_ptr[i] for i in range(15)]
    signal = int_data[0]
    attention = int_data[1]
    meditation = int_data[2]
    battery = int_data[4]
    
    delta, theta, low_alpha, high_alpha = int_data[7], int_data[8], int_data[9], int_data[10]
    low_beta, high_beta, low_gamma, mid_gamma = int_data[11], int_data[12], int_data[13], int_data[14]
    
    print("\n================ [Python Received 1Hz BCI Data] ================")
    print(f"Signal Quality : {signal} ({'Good / Normal' if signal == 0 else 'Poor Signal / Off-Head'})")
    print(f"Attention      : {attention}")
    print(f"Meditation     : {meditation}")
    print(f"Battery        : {battery}% | Temp: {temp:.1f} C | HW Ver: {hw}")
    print(f"8-Band Spectrum: Delta={delta}, Theta={theta}, Alpha={low_alpha}+{high_alpha}, Beta={low_beta}+{high_beta}")
    print("================================================================")

def on_raw_wave(raw_value, user_data):
    # 512Hz / 256Hz raw microvolt waveform
    pass

# Keep persistent reference to avoid Python GC collection
c_brain_data_cb = BRAIN_DATA_CB(on_brain_data)
c_raw_wave_cb = RAW_WAVE_CB(on_raw_wave)

def main():
    print("========================================")
    print("    ZKBrain Windows Python SDK Demo     ")
    print("========================================")
    
    app_id = zkbrain.zkbrain_get_app_id()
    print(f"Current AppID: {app_id.decode('utf-8', errors='ignore') if app_id else 'unknown'}")
    
    # Load and initialize License authorization
    lic_file = os.path.join(script_dir, "license.lic")
    if not os.path.exists(lic_file):
        lic_file = os.path.join(script_dir, "..", "..", "license.lic")
    
    if os.path.exists(lic_file):
        with open(lic_file, "r", encoding="utf-8") as f:
            lic_json = f.read()
        ret = zkbrain.zkbrain_sec_init(lic_json.encode("utf-8"))
        print(f"License verification status: {ret} {'[AUTHORIZED]' if ret == 1024 else '[FAILED]'}")
    else:
        print("[!] license.lic not found, attempting parser creation directly...")
    
    # Create parser
    parser = zkbrain.zkbrain_parser_create()
    if not parser:
        print("Note: Parser uninitialized (please invoke zkbrain_sec_init first for commercial use)")
        return
    
    # Bind callbacks
    zkbrain.zkbrain_parser_set_callbacks(
        parser,
        c_brain_data_cb,
        c_raw_wave_cb,
        None, None, None, None
    )
    print("Parser initialized and ready, feeding data stream...")
    
    # Simulate feeding hardware byte stream
    dummy_bytes = bytes([
        0xAA, 0xAA, 0x20, 0x02, 0x00, 0x83, 0x18,
        0x00, 0x00, 0x20, 0x00, 0x00, 0x30, 0x00, 0x00, 0x40, 0x00, 0x00, 0x50,
        0x00, 0x00, 0x60, 0x00, 0x00, 0x70, 0x00, 0x00, 0x80, 0x00, 0x00, 0x90,
        0x04, 0x55, 0x05, 0x40, 0x81
    ])
    
    buf = (ctypes.c_uint8 * len(dummy_bytes))(*dummy_bytes)
    zkbrain.zkbrain_parser_parse(parser, buf, len(dummy_bytes))
    
    # Destroy parser instance
    zkbrain.zkbrain_parser_destroy(parser)
    print("Parser released.")

if __name__ == '__main__':
    main()
