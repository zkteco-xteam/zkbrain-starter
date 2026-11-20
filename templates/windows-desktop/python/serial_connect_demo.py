#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
=============================================================================
🌟 ZKBrain Windows SDK - 经典蓝牙/虚拟串口 (COM 端口) 自动扫描连接工程
=============================================================================
适用场景:
  1. MindWave 原装 USB 蓝牙适配器 (插在电脑上直接识别为 COM 串口);
  2. 电脑自带蓝牙配对后生成的 Bluetooth SPP 虚拟串口;
  3. CP2102 / CH340 / FTDI 等 USB 转串口模块。

前置环境要求:
  pip install pyserial
=============================================================================
"""

import os
import sys
import time
import ctypes

# 解决 Windows 控制台默认 GBK 打印 Emoji 字符抛出 UnicodeEncodeError
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
    print("\n[错误] 检测到当前环境未安装 pyserial 串口库！")
    print("请在控制台执行安装命令: pip install pyserial\n")
    sys.exit(1)

# =========================================================================
# 1. 加载 ZKBrain Windows 核心动态库
# =========================================================================
DLL_REL_PATH = os.path.join(os.path.dirname(__file__), "../../bin/x64/zkbrain_sec.dll")
DLL_PATH = os.path.abspath(DLL_REL_PATH)

if not os.path.exists(DLL_PATH):
    print(f"[致命错误] 未找到核心动态库: {DLL_PATH}")
    sys.exit(1)

zkbrain = ctypes.CDLL(DLL_PATH)

# C 接口签名
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
        print(f"🌟 [状态优良] 专注度: {attention:3d} | 放松度: {meditation:3d} | 电量: {battery:2d}% | 额温: {temp:.1f}°C")
    elif signal == 200:
        print("🚨 [脱落警告] 电极完全未佩戴 (Signal=200)")
    else:
        print(f"⚠️  [信号接触不良] 信号质量码: {signal}")
    print("-" * 60)

c_brain_cb = BRAIN_DATA_CB(on_brain_data)

def main():
    print("================================================================")
    print("      ZKBrain Windows 串口 / 经典蓝牙 SPP 数据解调客户端       ")
    print("================================================================")

    # 1. 验证授权
    lic_path = os.path.join(os.path.dirname(__file__), "license.lic")
    if not os.path.exists(lic_path):
        lic_path = os.path.join(os.path.dirname(__file__), "../../license.lic")

    with open(lic_path, "r", encoding="utf-8") as f:
        lic_content = f.read()

    auth_code = zkbrain.zkbrain_sec_init(lic_content.encode("utf-8"))
    if auth_code != 1024:
        print(f"[错误] License 鉴权失败，错误码: {auth_code}")
        return

    print("✅ License 授权成功 (Code: 1024)！")

    # 2. 列出系统可用串口
    ports = list(serial.tools.list_ports.comports())
    if not ports:
        print("❌ 未检测到任何可用的 COM 端口！请插入 USB 接收器或在系统蓝牙中配对头环。")
        return

    print(f"\n检测到 {len(ports)} 个可用端口:")
    for idx, p in enumerate(ports):
        print(f"  [{idx + 1}] {p.device} - {p.description}")

    sel = 0
    if len(ports) > 1:
        sel = int(input("\n请选择要连接的端口序号: ").strip()) - 1
    selected_port = ports[sel].device

    # 3. 创建解析器并打开串口
    parser = zkbrain.zkbrain_parser_create()
    zkbrain.zkbrain_parser_set_callbacks(parser, c_brain_cb, None, None, None, None, None)

    # 标称波特率通常为 57600 (ThinkGear) 或 115200
    BAUDRATE = 57600
    print(f"\n🔌 正在打开端口 {selected_port} (波特率 {BAUDRATE}) ...")
    try:
        ser = serial.Serial(selected_port, BAUDRATE, timeout=1.0)
    except Exception as e:
        print(f"❌ 打开串口失败: {e}")
        zkbrain.zkbrain_parser_destroy(parser)
        return

    print("🚀 串口已就绪！开始持续读取字节流并送入 SDK 解调 (按 Ctrl+C 退出)...")
    try:
        while True:
            raw_chunk = ser.read(64)
            if raw_chunk:
                c_buf = (ctypes.c_uint8 * len(raw_chunk)).from_buffer_copy(raw_chunk)
                zkbrain.zkbrain_parser_parse(parser, c_buf, len(raw_chunk))
            else:
                time.sleep(0.01)
    except KeyboardInterrupt:
        print("\n用户手动退出。")
    finally:
        ser.close()
        zkbrain.zkbrain_parser_destroy(parser)
        print("✅ 串口已关闭，解析器已安全注销。")

if __name__ == "__main__":
    main()
