#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
=============================================================================
🌟 ZKBrain Windows SDK - 低功耗蓝牙 (BLE) 自动扫描、连接与脑电解调工程
=============================================================================
功能特性:
  1. 使用 Windows 10/11 原生 BLE 协议栈 (基于 bleak 异步库);
  2. 自动扫描周围所有广播中的脑电硬件设备 (自动按信号强度 RSSI 排序);
  3. 支持根据设备名称关键字 (如 MindWave, Brain, EEG, TGAM, ZKT) 自动过滤匹配;
  4. 自动检索 GATT 服务与具有 Notify 权限的特征值 (支持 039AFFF8 / 0000FFF0 等);
  5. 物理层收到原始蓝牙分包后直接喂给 zkbrain_sec.dll 进行实时状态机解调;
  6. 回调输出 1Hz 专注度 (Attention)、放松度 (Meditation)、信号质量与 8 频段能量谱。

前置环境要求:
  pip install bleak
=============================================================================
"""

import os
import sys
import asyncio
import ctypes
from typing import Optional

# 解决 Windows 控制台默认 GBK 打印 Emoji 字符抛出 UnicodeEncodeError
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
    print("\n[错误] 检测到当前环境未安装 bleak 蓝牙库！")
    print("请在控制台执行安装命令: pip install bleak\n")
    sys.exit(1)

# =========================================================================
# 1. 加载 ZKBrain Windows x64 核心动态库
# =========================================================================
DLL_REL_PATH = os.path.join(os.path.dirname(__file__), "../../bin/x64/zkbrain_sec.dll")
DLL_PATH = os.path.abspath(DLL_REL_PATH)

if not os.path.exists(DLL_PATH):
    print(f"[致命错误] 未找到核心动态库: {DLL_PATH}")
    sys.exit(1)

zkbrain = ctypes.CDLL(DLL_PATH)

# C 接口签名声明
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
# 2. 全局状态与回调定义
# =========================================================================
parser_handle = None
g_packet_count = 0

def on_brain_data(data_ptr, hw_ver, temp, user_data):
    """
    1Hz 综合特征包回调函数
    """
    data = [data_ptr[i] for i in range(15)]
    signal = data[0]
    attention = data[1]
    meditation = data[2]
    preference = data[3]
    battery = data[4]
    grind = data[5]
    heart_rate = data[6]

    # 频段能量 (7~14)
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
        print(f"🌟 [状态优良] 专注度: \033[1;32m{attention:3d}\033[0m | 放松度: \033[1;34m{meditation:3d}\033[0m | 电量: {battery:2d}% | 额温: {temp:.1f}°C")
        print(f"📊 [8频段功率] Delta: {delta} | Theta: {theta} | LowAlpha: {low_alpha} | HighAlpha: {high_alpha}")
        print(f"             LowBeta: {low_beta} | HighBeta: {high_beta} | LowGamma: {low_gamma} | MidGamma: {mid_gamma}")
    elif signal == 200:
        print("🚨 \033[1;31m[佩戴脱落] 检测到电极完全未佩戴 (Signal: 200)，请佩戴好额头电极与耳夹！\033[0m")
    else:
        print(f"⚠️  [信号接触不良] 信号质量码: {signal} (ASIC算法暂时处于噪声保持模式)")
    print("=" * 65)

def on_raw_wave(raw_value, user_data):
    """
    512Hz 原始脑电微伏波回调
    """
    global g_packet_count
    g_packet_count += 1
    # 为避免控制台刷屏，仅每 256 个点提示一次波形微伏状态
    if g_packet_count % 256 == 0:
        # print(f"[Raw 512Hz] 实时微伏点: {raw_value}")
        pass

c_brain_cb = BRAIN_DATA_CB(on_brain_data)
c_raw_cb = RAW_WAVE_CB(on_raw_wave)

# =========================================================================
# 3. 蓝牙通知处理逻辑
# =========================================================================
def handle_ble_notification(characteristic: BleakGATTCharacteristic, data: bytearray):
    """
    当蓝牙特征值收到 Notify 字节流时，直接灌入 ZKBrain 动态库状态机
    """
    if parser_handle and len(data) > 0:
        c_bytes = (ctypes.c_uint8 * len(data)).from_buffer_copy(data)
        zkbrain.zkbrain_parser_parse(parser_handle, c_bytes, len(data))

# =========================================================================
# 4. BLE 自动扫描与连接流程
# =========================================================================
async def run_ble_workflow():
    global parser_handle

    print("================================================================")
    print("       ZKBrain Windows x64 原生低功耗蓝牙 (BLE) 连接客户端      ")
    print("================================================================")

    # 1. 验证授权
    lic_path = os.path.join(os.path.dirname(__file__), "license.lic")
    if not os.path.exists(lic_path):
        lic_path = os.path.join(os.path.dirname(__file__), "../../license.lic")

    with open(lic_path, "r", encoding="utf-8") as f:
        lic_content = f.read()

    auth_code = zkbrain.zkbrain_sec_init(lic_content.encode("utf-8"))
    if auth_code != 1024:
        print(f"[致命错误] License 鉴权失败，错误码: {auth_code}")
        print("请检查证书文件或参考 README.md 错误码指南。")
        return

    print("✅ License 授权成功 (Code: 1024)！核心算法引擎已解锁。")

    # 2. 创建解析器
    parser_handle = zkbrain.zkbrain_parser_create()
    if not parser_handle:
        print("[错误] 解析器实例化失败！")
        return

    zkbrain.zkbrain_parser_set_callbacks(
        parser_handle,
        c_brain_cb,
        c_raw_cb,
        None, None, None, None
    )

    # 3. 开始扫描周围的 BLE 设备
    print("\n🔍 正在通过 Windows 原生蓝牙搜索周围脑电硬件设备 (耗时约 5 秒)...")
    devices = await BleakScanner.discover(timeout=5.0)

    if not devices:
        print("❌ 未发现任何周围蓝牙设备！请确认：")
        print("   1. Windows 电脑已开启蓝牙；")
        print("   2. 脑电头环已开机且处于配对/广播状态 (指示灯蓝灯闪烁)。")
        zkbrain.zkbrain_parser_destroy(parser_handle)
        return

    # 4. 筛选脑电相关设备
    KEYWORDS = ["brain", "mind", "eeg", "tgam", "zkt", "neuro", "macrotellect"]
    candidates = []

    print(f"\n共扫描到 {len(devices)} 个广播设备:")
    for idx, d in enumerate(devices):
        name = d.name or "未知设备 (Unknown)"
        rssi = getattr(d, 'rssi', -100)
        is_matched = any(kw in name.lower() for kw in KEYWORDS)
        mark = "👉 [匹配到脑电设备]" if is_matched else ""
        print(f"  [{idx + 1:2d}] {name:30s} (MAC: {d.address}) RSSI: {rssi} dBm {mark}")
        if is_matched:
            candidates.append(d)

    # 5. 确定目标设备
    target_device = None
    if len(candidates) == 1:
        target_device = candidates[0]
        print(f"\n🎯 自动选择已识别的脑电设备: {target_device.name} ({target_device.address})")
    elif len(candidates) > 1:
        print(f"\n找到多个潜在脑电设备，请选择连接 (1 - {len(candidates)}):")
        for i, c in enumerate(candidates):
            print(f"  [{i + 1}] {c.name} ({c.address})")
        sel = int(input("请输入序号: ").strip()) - 1
        target_device = candidates[sel]
    else:
        # 手动输入序号连接
        print("\n未自动匹配到包含 Brain/EEG 关键字的设备，请手动输入上方列表序号连接:")
        choice = int(input("请输入设备序号 (1 - N): ").strip()) - 1
        target_device = devices[choice]

    # 6. 发起 GATT 物理连接
    print(f"\n🔌 正在连接设备: {target_device.name} [{target_device.address}] ...")
    async with BleakClient(target_device.address) as client:
        if not client.is_connected:
            print("❌ 连接失败！请重试。")
            zkbrain.zkbrain_parser_destroy(parser_handle)
            return

        print("✅ 蓝牙物理链路已连通！正在发现 GATT 特征值...")

        # 7. 自动寻找具有 Notify 属性的数据通道
        notify_chars = []
        for service in client.services:
            for char in service.characteristics:
                if "notify" in char.properties:
                    notify_chars.append(char)
                    # print(f"  发现可订阅通道: {char.uuid} (属性: {char.properties})")

        if not notify_chars:
            print("❌ 未在设备上找到任何具备 Notify 属性的脑电数据通道！")
            zkbrain.zkbrain_parser_destroy(parser_handle)
            return

        # 优先匹配官方脑电通道 (039AFFF8 / 0000FFF4 / 0000FFF0 等)
        selected_chars = []
        for ch in notify_chars:
            u = ch.uuid.lower()
            if "fff8" in u or "fff4" in u or "fff0" in u or len(notify_chars) <= 2:
                selected_chars.append(ch)

        if not selected_chars:
            selected_chars = notify_chars

        print(f"🎯 正在订阅 {len(selected_chars)} 个特征值通道...")
        for ch in selected_chars:
            print(f"  -> 启动通知监听: {ch.uuid}")
            await client.start_notify(ch.uuid, handle_ble_notification)

        # 查找可写通道以支持 MEMS 与控制指令下发
        write_char = None
        for service in client.services:
            for char in service.characteristics:
                if "write" in char.properties or "write-without-response" in char.properties:
                    write_char = char
                    break
            if write_char:
                break

        if write_char:
            print(f"📡 发现硬件指令写通道: {write_char.uuid}")
            # 示例：开启 MEMS 惯导流指令下发
            # await client.write_gatt_char(write_char.uuid, b"mems_enable=1;\n")
            # 示例：NeuroSky 点火包 [0x02, 0x15, 0x17]
            # await client.write_gatt_char(write_char.uuid, bytearray([0x02, 0x15, 0x17]))

        print("\n🚀 数据解调已点火！正在实时接收脑电波...")
        print("提示: 脑电算法需要约 3~5 秒滑动窗口进行初次基线校准。按 Ctrl+C 可停止采集。\n")

        try:
            # 持续保持通信
            while client.is_connected:
                await asyncio.sleep(1.0)
        except asyncio.CancelledError:
            pass
        except KeyboardInterrupt:
            print("\n用户手动终止采集。")
        finally:
            for ch in selected_chars:
                try:
                    await client.stop_notify(ch.uuid)
                except Exception:
                    pass

    # 8. 资源释放
    if parser_handle:
        zkbrain.zkbrain_parser_destroy(parser_handle)
        parser_handle = None
    print("\n✅ 设备已断开，ZKBrain 解析器已安全注销。")

if __name__ == "__main__":
    try:
        asyncio.run(run_ble_workflow())
    except KeyboardInterrupt:
        print("\n程序已退出。")
