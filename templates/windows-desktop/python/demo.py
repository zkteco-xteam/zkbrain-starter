"""
ZKBrain Windows SDK Python (ctypes) 快速接入示例
适用于 Windows 平台进行科研数据采集、机器学习离线分析或快速原型验证。
"""

import os
import sys
import ctypes

# 1. 动态加载 Windows DLL (位于 ../../bin/x64/zkbrain_sec.dll)
script_dir = os.path.dirname(os.path.abspath(__file__))
dll_path = os.path.abspath(os.path.join(script_dir, "..", "..", "bin", "x64", "zkbrain_sec.dll"))

if not os.path.exists(dll_path):
    raise FileNotFoundError(f"未找到 SDK 动态库: {dll_path}")

zkbrain = ctypes.CDLL(dll_path)

# 2. 定义 C 回调类型签名
BRAIN_DATA_CB = ctypes.CFUNCTYPE(None, ctypes.POINTER(ctypes.c_int), ctypes.c_double, ctypes.c_float, ctypes.c_void_p)
RAW_WAVE_CB = ctypes.CFUNCTYPE(None, ctypes.c_int, ctypes.c_void_p)

# 3. 设置导出函数参数和返回值类型
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

# 4. 实现回调函数
def on_brain_data(int_data_ptr, hw, temp, user_data):
    int_data = [int_data_ptr[i] for i in range(15)]
    signal = int_data[0]
    attention = int_data[1]
    meditation = int_data[2]
    battery = int_data[4]
    
    delta, theta, low_alpha, high_alpha = int_data[7], int_data[8], int_data[9], int_data[10]
    low_beta, high_beta, low_gamma, mid_gamma = int_data[11], int_data[12], int_data[13], int_data[14]
    
    print("\n================ [Python 收到 1Hz 脑电特征数据] ================")
    print(f"信号质量: {signal} ({'正常佩戴' if signal == 0 else '接触不良/脱落'})")
    print(f"专注度 (Attention) : {attention}")
    print(f"放松度 (Meditation): {meditation}")
    print(f"剩余电量: {battery}% | 体温: {temp:.1f} °C | 硬件版本: {hw}")
    print(f"8频段能量谱: Delta={delta}, Theta={theta}, Alpha={low_alpha}+{high_alpha}, Beta={low_beta}+{high_beta}")
    print("================================================================")

def on_raw_wave(raw_value, user_data):
    # 原始 512Hz / 256Hz 微伏波形
    pass

# 持久引用防止被 Python GC 垃圾回收
c_brain_data_cb = BRAIN_DATA_CB(on_brain_data)
c_raw_wave_cb = RAW_WAVE_CB(on_raw_wave)

def main():
    print("========================================")
    print("    ZKBrain Windows Python SDK 演示     ")
    print("========================================")
    
    app_id = zkbrain.zkbrain_get_app_id()
    print(f"当前识别 AppID: {app_id.decode('utf-8', errors='ignore') if app_id else 'unknown'}")
    
    # 5. 加载并初始化 License 授权
    lic_file = os.path.join(script_dir, "license.lic")
    if not os.path.exists(lic_file):
        lic_file = os.path.join(script_dir, "..", "..", "license.lic")
    
    if os.path.exists(lic_file):
        with open(lic_file, "r", encoding="utf-8") as f:
            lic_json = f.read()
        ret = zkbrain.zkbrain_sec_init(lic_json.encode("utf-8"))
        print(f"License 验证状态码: {ret} {'[授权成功!]' if ret == 1024 else '[授权失败]'}")
    else:
        print("[!] 未找到 license.lic 文件，尝试直接创建解析器...")
    
    # 6. 创建解析器
    parser = zkbrain.zkbrain_parser_create()
    if not parser:
        print("提示: 解析器未初始化 (若正式商用请先调用 zkbrain_sec_init 授权)")
        return
    
    # 6. 绑定回调
    zkbrain.zkbrain_parser_set_callbacks(
        parser,
        c_brain_data_cb,
        c_raw_wave_cb,
        None, None, None, None
    )
    print("解析器已启动，等待喂入数据...")
    
    # 7. 模拟喂入硬件字节流 (如 pyserial 读取到的 COM 串口数据)
    dummy_bytes = bytes([
        0xAA, 0xAA, 0x20, 0x02, 0x00, 0x83, 0x18,
        0x00, 0x00, 0x20, 0x00, 0x00, 0x30, 0x00, 0x00, 0x40, 0x00, 0x00, 0x50,
        0x00, 0x00, 0x60, 0x00, 0x00, 0x70, 0x00, 0x00, 0x80, 0x00, 0x00, 0x90,
        0x04, 0x55, 0x05, 0x40, 0x81
    ])
    
    buf = (ctypes.c_uint8 * len(dummy_bytes))(*dummy_bytes)
    zkbrain.zkbrain_parser_parse(parser, buf, len(dummy_bytes))
    
    # 8. 销毁实例
    zkbrain.zkbrain_parser_destroy(parser)
    print("解析器已释放。")

if __name__ == '__main__':
    main()
