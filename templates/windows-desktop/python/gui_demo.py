# -*- coding: utf-8 -*-
"""
🌟 1:1 完整逐项克隆 shared1 设备管理控制台 (DeviceScreen + DeviceShowTable) - Windows 桌面 GUI 版 (Python Tkinter)
技术支持：熵基科技脑机事业部 (ZKTeco Brain-Computer Interface Division)
"""

import tkinter as tk
from tkinter import ttk, messagebox
import random

class DeviceScreenApp(tk.Tk):
    def __init__(self):
        super().__init__()
        self.title("设备管理 (DeviceScreen) - ZKBrain Windows Desktop")
        self.geometry("860", "920")
        self.configure(bg="#F1F5F9")
        self.resizable(True, True)

        # 核心状态变量
        self.is_connected = False
        self.device_name = "ZKBrain Headband"
        self.device_mac = "DC:23:4F:9A:88:01"
        self.battery_val = 85

        # 12项生理指标数据
        self.val_attention = 75
        self.val_meditation = 68
        self.val_quality = 0
        self.val_raw_eeg = 128
        self.val_delta = 14500
        self.val_theta = 8900
        self.val_low_alpha = 16200
        self.val_high_alpha = 21500
        self.val_low_beta = 19800
        self.val_high_beta = 11400
        self.val_low_gamma = 4800
        self.val_mid_gamma = 2200

        # MEMS 姿态与欧拉角
        self.mems_roll = 1.2
        self.mems_pitch = -0.5
        self.mems_yaw = 14.8
        self.mems_q0 = 0.992
        self.mems_q1 = 0.010
        self.mems_q2 = -0.004
        self.mems_q3 = 0.129

        self._build_ui()
        self.add_log("[系统启动] ZKBrain Windows Desktop 控制台初始化就绪")

    def _build_ui(self):
        # 创建可滚动的主容器
        canvas = tk.Canvas(self, bg="#F1F5F9", highlightthickness=0)
        scrollbar = ttk.Scrollbar(self, orient="vertical", command=canvas.yview)
        scrollable_frame = tk.Frame(canvas, bg="#F1F5F9")

        scrollable_frame.bind(
            "<Configure>",
            lambda e: canvas.configure(scrollregion=canvas.bbox("all"))
        )
        canvas.create_window((0, 0), window=scrollable_frame, anchor="nw", width=840)
        canvas.configure(yscrollcommand=scrollbar.set)

        canvas.pack(side="left", fill="both", expand=True, padx=10, pady=10)
        scrollbar.pack(side="right", fill="y")

        # ==========================================
        # 板块 1：顶部操作栏
        # ==========================================
        header_frame = tk.Frame(scrollable_frame, bg="#F1F5F9")
        header_frame.pack(fill="x", pady=(0, 10))

        title_lbl = tk.Label(header_frame, text="设备管理 (DeviceScreen)", font=("Segoe UI", 16, "bold"), bg="#F1F5F9", fg="#0F172A")
        title_lbl.pack(side="left")

        auth_badge = tk.Label(header_frame, text="Authorized", font=("Segoe UI", 9, "bold"), bg="#DCFCE7", fg="#16A34A", padx=8, pady=4, relief="solid", bd=1)
        auth_badge.pack(side="right", padx=(6, 0))

        dfu_btn = tk.Button(header_frame, text="🚀 DFU升级", font=("Segoe UI", 9), bg="#475569", fg="white", padx=10, pady=3, relief="flat", cursor="hand2", command=self._on_dfu)
        dfu_btn.pack(side="right", padx=6)

        search_btn = tk.Button(header_frame, text="🔍 搜索设备", font=("Segoe UI", 9, "bold"), bg="#2563EB", fg="white", padx=10, pady=3, relief="flat", cursor="hand2", command=self._show_scan_dialog)
        search_btn.pack(side="right", padx=6)

        # ==========================================
        # 板块 2：统一设备连接状态卡片
        # ==========================================
        card2 = tk.Frame(scrollable_frame, bg="white", padx=16, pady=14, relief="ridge", bd=1)
        card2.pack(fill="x", pady=6)

        row2_1 = tk.Frame(card2, bg="white")
        row2_1.pack(fill="x")

        self.dot_canvas = tk.Canvas(row2_1, width=12, height=12, bg="white", highlightthickness=0)
        self.dot_canvas.pack(side="left")
        self.dot_item = self.dot_canvas.create_oval(1, 1, 11, 11, fill="#EF4444", outline="")

        self.status_lbl = tk.Label(row2_1, text="已断开 (DISCONNECTED)", font=("Segoe UI", 10, "bold"), fg="#DC2626", bg="white")
        self.status_lbl.pack(side="left", padx=8)

        bat_capsule = tk.Label(row2_1, text=f"🔋 {self.battery_val}%", font=("Segoe UI", 9, "bold"), bg="#DCFCE7", fg="#16A34A", padx=8, pady=2, relief="solid", bd=1)
        bat_capsule.pack(side="right")

        self.dev_name_lbl = tk.Label(card2, text=self.device_name, font=("Segoe UI", 14, "bold"), fg="#0F172A", bg="white")
        self.dev_name_lbl.pack(anchor="w", pady=(8, 2))

        self.dev_mac_lbl = tk.Label(card2, text=f"MAC: {self.device_mac}  |  SN: ZK-2026-DEV001", font=("Segoe UI", 9), fg="#64748B", bg="white")
        self.dev_mac_lbl.pack(anchor="w", pady=(0, 8))

        badges_frame = tk.Frame(card2, bg="white")
        badges_frame.pack(anchor="w", pady=(0, 10))
        self._build_chip(badges_frame, "ZKBrain Core", "#0284C7", "#E0F2FE")
        self._build_chip(badges_frame, "Single-Ch (FP1)", "#0D9488", "#CCFBF1")
        self._build_chip(badges_frame, "ASCII + MEMS", "#7C3AED", "#EDE9FE")

        self.btn_toggle_connect = tk.Button(card2, text="搜索连接", font=("Segoe UI", 10, "bold"), bg="#2563EB", fg="white", relief="flat", pady=6, cursor="hand2", command=self._toggle_connection)
        self.btn_toggle_connect.pack(fill="x")

        # ==========================================
        # 板块 3：Channel Settings 通道配置卡片
        # ==========================================
        card3 = tk.Frame(scrollable_frame, bg="white", padx=16, pady=12, relief="ridge", bd=1)
        card3.pack(fill="x", pady=6)
        tk.Label(card3, text="⚙️ Channel Settings (通道配置)", font=("Segoe UI", 11, "bold"), fg="#1E293B", bg="white").pack(anchor="w", pady=(0, 8))

        ch_frame = tk.Frame(card3, bg="white")
        ch_frame.pack(anchor="w")

        self.fp1_var = tk.BooleanVar(value=True)
        cb_fp1 = tk.Checkbutton(ch_frame, text="Left (FP1)", variable=self.fp1_var, font=("Segoe UI", 10), bg="white", activebackground="white", command=lambda: self.add_log(f"[通道配置] Left (FP1): {self.fp1_var.get()}"))
        cb_fp1.pack(side="left", padx=(0, 20))

        cb_fp2 = tk.Checkbutton(ch_frame, text="Right (FP2) [硬件不支持]", state="disabled", font=("Segoe UI", 10), bg="white", fg="#94A3B8")
        cb_fp2.pack(side="left")

        # ==========================================
        # 板块 4：Chart Display Settings 图表显隐卡片
        # ==========================================
        card4 = tk.Frame(scrollable_frame, bg="white", padx=16, pady=12, relief="ridge", bd=1)
        card4.pack(fill="x", pady=6)
        tk.Label(card4, text="📈 Chart Display Settings (图表显隐配置)", font=("Segoe UI", 11, "bold"), fg="#1E293B", bg="white").pack(anchor="w", pady=(0, 8))

        chips_frame = tk.Frame(card4, bg="white")
        chips_frame.pack(fill="x")
        chart_titles = [
            "Raw EEG", "Signal Quality", "Attention", "Meditation",
            "Delta", "Theta", "Low Alpha", "High Alpha",
            "Low Beta", "High Beta", "Low Gamma", "Middle Gamma"
        ]
        col_idx = 0
        row_idx = 0
        for title in chart_titles:
            btn = tk.Button(chips_frame, text=title, font=("Segoe UI", 9), bg="#2563EB", fg="white", relief="flat", padx=8, pady=3, cursor="hand2")
            btn.config(command=lambda b=btn, t=title: self._toggle_chart_chip(b, t))
            btn.grid(row=row_idx, column=col_idx, padx=4, pady=3, sticky="w")
            col_idx += 1
            if col_idx >= 4:
                col_idx = 0
                row_idx += 1

        # ==========================================
        # 板块 5：⚙️ NeuroSky / MindWave 专属 20 字节协议控制台
        # ==========================================
        card5 = tk.Frame(scrollable_frame, bg="white", padx=16, pady=12, relief="ridge", bd=1)
        card5.pack(fill="x", pady=6)
        tk.Label(card5, text="⚙️ NeuroSky / MindWave 专属协议控制台", font=("Segoe UI", 11, "bold"), fg="#1E293B", bg="white").pack(anchor="w")
        tk.Label(card5, text="支持 20 字节二进制点火帧、工频滤波、SN 读写与经典 MAC 探测", font=("Segoe UI", 8), fg="#64748B", bg="white").pack(anchor="w", pady=(2, 8))

        btn_grid5 = tk.Frame(card5, bg="white")
        btn_grid5.pack(fill="x", pady=(0, 8))
        self._build_action_btn(btn_grid5, "🚀 点火启动 (0x15/17)", "#16A34A", lambda: self.add_log("[TX >> XMW] 点火启动包: 0x15 (Raw) + 0x17 (Band)"))
        self._build_action_btn(btn_grid5, "🛑 停止传输 (0x16/18)", "#DC2626", lambda: self.add_log("[TX >> XMW] 停止传输: 0x16 + 0x18"))
        self._build_action_btn(btn_grid5, "50Hz 工频滤波 (0x1B)", "#475569", lambda: self.add_log("[TX >> XMW] 设置 50Hz 工频陷波滤波 (0x1B)"))
        self._build_action_btn(btn_grid5, "60Hz 工频滤波 (0x1C)", "#475569", lambda: self.add_log("[TX >> XMW] 设置 60Hz 工频陷波滤波 (0x1C)"))
        self._build_action_btn(btn_grid5, "读电量 (0x06)", "#D97706", lambda: self.add_log("[TX >> XMW] 读取硬件电量 (0x06)"))
        self._build_action_btn(btn_grid5, "读序列号 (0xF4)", "#D97706", lambda: self.add_log("[TX >> XMW] 查询设备序列号 SN (0xF4)"))
        self._build_action_btn(btn_grid5, "探测经典MAC (0xFC)", "#7C3AED", lambda: self.add_log("[TX >> XMW] 探测经典蓝牙 MAC 地址 (0xFC)"))

        sn_row = tk.Frame(card5, bg="white")
        sn_row.pack(fill="x")
        self.sn_entry = tk.Entry(sn_row, font=("Segoe UI", 9), relief="solid", bd=1)
        self.sn_entry.pack(side="left", fill="x", expand=True, padx=(0, 6), ipady=3)
        btn_write_sn = tk.Button(sn_row, text="写入 SN (0xF2)", font=("Segoe UI", 9, "bold"), bg="#0F172A", fg="white", relief="flat", padx=10, pady=3, cursor="hand2", command=self._on_write_sn)
        btn_write_sn.pack(side="right")

        # ==========================================
        # 板块 6：🧠 ZKBrain 自研脑电设备官方控制台
        # ==========================================
        card6 = tk.Frame(scrollable_frame, bg="white", padx=16, pady=12, relief="ridge", bd=1)
        card6.pack(fill="x", pady=6)
        tk.Label(card6, text="🧠 ZKBrain 自研脑电设备官方控制台", font=("Segoe UI", 11, "bold"), fg="#1E293B", bg="white").pack(anchor="w")
        tk.Label(card6, text="支持 ASCII 控制、MEMS 姿态传感、采样率切换与终端实时回显", font=("Segoe UI", 8), fg="#64748B", bg="white").pack(anchor="w", pady=(2, 8))

        btn_grid6 = tk.Frame(card6, bg="white")
        btn_grid6.pack(fill="x", pady=(0, 8))
        self._build_action_btn(btn_grid6, "查询授权 (license:?)", "#0284C7", lambda: self.add_log("[TX >>] license:?"))
        self._build_action_btn(btn_grid6, "读电量 (battery:?)", "#0284C7", lambda: self.add_log("[TX >>] battery:?"))
        self._build_action_btn(btn_grid6, "固件版本 (version:?)", "#0284C7", lambda: self.add_log("[TX >>] version:?"))
        self._build_action_btn(btn_grid6, "开启脑电 (eeg_data_on:1)", "#16A34A", lambda: self.add_log("[TX >>] eeg_data_on:1"))
        self._build_action_btn(btn_grid6, "关闭脑电 (eeg_data_on:0)", "#DC2626", lambda: self.add_log("[TX >>] eeg_data_on:0"))
        self._build_action_btn(btn_grid6, "256Hz采样率", "#475569", lambda: self.add_log("[TX >>] eeg_data_rate:2 (256Hz)"))
        self._build_action_btn(btn_grid6, "512Hz采样率", "#475569", lambda: self.add_log("[TX >>] eeg_data_rate:1 (512Hz)"))
        self._build_action_btn(btn_grid6, "开启MEMS (mems_on:1)", "#0D9488", lambda: self.add_log("[TX >>] mems_on:1"))
        self._build_action_btn(btn_grid6, "关闭MEMS (mems_on:0)", "#94A3B8", lambda: self.add_log("[TX >>] mems_on:0"))
        self._build_action_btn(btn_grid6, "DFU 扫描模式", "#7C3AED", lambda: self.add_log("[TX >>] dfu_scan:1 (进入DFU空中升级就绪模式)"))

        # MEMS 姿态卡片
        mems_card = tk.Frame(card6, bg="#F8FAFC", padx=10, pady=8, relief="solid", bd=1)
        mems_card.pack(fill="x", pady=(0, 8))
        tk.Label(mems_card, text="📐 实时 MEMS 空间姿态 (Euler & Quaternion)", font=("Segoe UI", 9, "bold"), fg="#334155", bg="#F8FAFC").pack(anchor="w")
        self.mems_euler_lbl = tk.Label(mems_card, text=f"Euler:  Roll: {self.mems_roll}°   Pitch: {self.mems_pitch}°   Yaw: {self.mems_yaw}°", font=("Consolas", 9), fg="#1E293B", bg="#F8FAFC")
        self.mems_euler_lbl.pack(anchor="w")
        self.mems_quat_lbl = tk.Label(mems_card, text=f"Quat:   Q0: {self.mems_q0}  Q1: {self.mems_q1}  Q2: {self.mems_q2}  Q3: {self.mems_q3}", font=("Consolas", 9), fg="#64748B", bg="#F8FAFC")
        self.mems_quat_lbl.pack(anchor="w")

        cmd_row = tk.Frame(card6, bg="white")
        cmd_row.pack(fill="x", pady=(0, 8))
        self.cmd_entry = tk.Entry(cmd_row, font=("Segoe UI", 9), relief="solid", bd=1)
        self.cmd_entry.pack(side="left", fill="x", expand=True, padx=(0, 6), ipady=3)
        btn_send_cmd = tk.Button(cmd_row, text="发送指令", font=("Segoe UI", 9, "bold"), bg="#2563EB", fg="white", relief="flat", padx=12, pady=3, cursor="hand2", command=self._on_send_cmd)
        btn_send_cmd.pack(side="right")

        # 终端回显监控窗口
        term_frame = tk.Frame(card6, bg="#0F172A", padx=8, pady=8)
        term_frame.pack(fill="x")
        term_head = tk.Frame(term_frame, bg="#0F172A")
        term_head.pack(fill="x", pady=(0, 4))
        tk.Label(term_head, text="终端响应监控 (Terminal Monitor):", font=("Segoe UI", 8), fg="#94A3B8", bg="#0F172A").pack(side="left")
        clear_btn = tk.Label(term_head, text="清空", font=("Segoe UI", 8, "underline"), fg="#38BDF8", bg="#0F172A", cursor="hand2")
        clear_btn.pack(side="right")
        clear_btn.bind("<Button-1>", lambda e: self._clear_logs())

        self.term_text = tk.Text(term_frame, height=5, font=("Consolas", 8), bg="#0F172A", fg="#4ADE80", relief="flat", wrap="none")
        self.term_text.pack(fill="x")

        # ==========================================
        # 板块 7：Spectrum Data 详细数据表格 (DeviceShowTable 4x3 三色)
        # ==========================================
        card7 = tk.Frame(scrollable_frame, bg="white", padx=16, pady=12, relief="ridge", bd=1)
        card7.pack(fill="x", pady=6)

        mac_bar = tk.Label(card7, text=f"Device MAC: {self.device_mac}", font=("Consolas", 10, "bold"), bg="#1E293B", fg="white", pady=6)
        mac_bar.pack(fill="x", pady=(0, 8))

        # 4x3 网格
        tbl_frame = tk.Frame(card7, bg="#CBD5E1", bd=1)
        tbl_frame.pack(fill="x")

        # Row 1 (粉 #FFE4E1)
        self.cell_att = self._build_table_cell(tbl_frame, 0, 0, "Attention", str(self.val_attention), "#FFE4E1")
        self.cell_med = self._build_table_cell(tbl_frame, 0, 1, "Meditation", str(self.val_meditation), "#FFE4E1")
        self.cell_qua = self._build_table_cell(tbl_frame, 0, 2, "Quality", str(self.val_quality), "#FFE4E1")

        # Row 2 (粉 + 青 + 青)
        self.cell_raw = self._build_table_cell(tbl_frame, 1, 0, "Raw EEG", str(self.val_raw_eeg), "#FFE4E1")
        self.cell_del = self._build_table_cell(tbl_frame, 1, 1, "Delta", str(self.val_delta), "#E0FFFF")
        self.cell_the = self._build_table_cell(tbl_frame, 1, 2, "Theta", str(self.val_theta), "#E0FFFF")

        # Row 3 (青 + 青 + 黄)
        self.cell_l_alp = self._build_table_cell(tbl_frame, 2, 0, "Low Alpha", str(self.val_low_alpha), "#E0FFFF")
        self.cell_h_alp = self._build_table_cell(tbl_frame, 2, 1, "High Alpha", str(self.val_high_alpha), "#E0FFFF")
        self.cell_l_bet = self._build_table_cell(tbl_frame, 2, 2, "Low Beta", str(self.val_low_beta), "#F0E68C")

        # Row 4 (全黄 #F0E68C)
        self.cell_h_bet = self._build_table_cell(tbl_frame, 3, 0, "High Beta", str(self.val_high_beta), "#F0E68C")
        self.cell_l_gam = self._build_table_cell(tbl_frame, 3, 1, "Low Gamma", str(self.val_low_gamma), "#F0E68C")
        self.cell_m_gam = self._build_table_cell(tbl_frame, 3, 2, "Mid Gamma", str(self.val_mid_gamma), "#F0E68C")

        for c in range(3):
            tbl_frame.columnconfigure(c, weight=1)

    def _build_chip(self, parent, text, fg, bg):
        lbl = tk.Label(parent, text=text, font=("Segoe UI", 8, "bold"), fg=fg, bg=bg, padx=6, pady=2, relief="solid", bd=1)
        lbl.pack(side="left", padx=(0, 6))

    def _build_action_btn(self, parent, text, color, cmd):
        btn = tk.Button(parent, text=text, font=("Segoe UI", 8, "bold"), fg=color, bg="#F1F5F9", relief="solid", bd=1, padx=6, pady=3, cursor="hand2", command=cmd)
        btn.pack(side="left", padx=3, pady=3)

    def _build_table_cell(self, parent, r, c, label, val, bg):
        cell = tk.Frame(parent, bg=bg, padx=6, pady=8)
        cell.grid(row=r, column=c, sticky="nsew", padx=1, pady=1)
        lbl_title = tk.Label(cell, text=label, font=("Segoe UI", 8, "bold"), fg="#334155", bg=bg)
        lbl_title.pack()
        lbl_val = tk.Label(cell, text=val, font=("Consolas", 11, "bold"), fg="#0F172A", bg=bg)
        lbl_val.pack()
        return lbl_val

    def _toggle_chart_chip(self, btn, title):
        curr_bg = btn.cget("bg")
        if curr_bg == "#2563EB":
            btn.config(bg="#F1F5F9", fg="#334155")
            self.add_log(f"[图表显隐] {title}: False")
        else:
            btn.config(bg="#2563EB", fg="white")
            self.add_log(f"[图表显隐] {title}: True")

    def add_log(self, msg):
        self.term_text.insert("end", f"{msg}\n")
        self.term_text.see("end")

    def _clear_logs(self):
        self.term_text.delete("1.0", "end")

    def _on_dfu(self):
        self.add_log("[DFU] 发起固件 OTA 检测，当前处于最新稳定版 v2.4.0")
        messagebox.showinfo("DFU 升级", "DFU 固件检测完成：当前为最新版本 v2.4.0")

    def _on_write_sn(self):
        sn = self.sn_entry.get().strip()
        if sn:
            self.add_log(f"[TX >> XMW] 写入 SN (0xF2): {sn}")
            messagebox.showinfo("SN 写入", f"SN 写入指令已发送: {sn}")

    def _on_send_cmd(self):
        cmd = self.cmd_entry.get().strip()
        if cmd:
            self.add_log(f"[TX >>] {cmd}")
            self.cmd_entry.delete(0, "end")

    def _toggle_connection(self):
        if self.is_connected:
            self.is_connected = False
            self.dot_canvas.itemconfig(self.dot_item, fill="#EF4444")
            self.status_lbl.config(text="已断开 (DISCONNECTED)", fg="#DC2626")
            self.btn_toggle_connect.config(text="搜索连接", bg="#2563EB")
            self.add_log("[BLE] 用户主动断开设备连接")
        else:
            self._show_scan_dialog()

    def _show_scan_dialog(self):
        dialog = tk.Toplevel(self)
        dialog.title("🔍 搜索周围脑电设备")
        dialog.geometry("450", "360")
        dialog.configure(bg="white")
        dialog.transient(self)
        dialog.grab_set()

        tk.Label(dialog, text="🔍 搜索周围脑电设备", font=("Segoe UI", 12, "bold"), fg="#1E293B", bg="white").pack(anchor="w", padx=16, pady=(14, 4))
        tk.Label(dialog, text="正在扫描低功耗蓝牙 (BLE) 脑电设备...", font=("Segoe UI", 8), fg="#64748B", bg="white").pack(anchor="w", padx=16, pady=(0, 10))

        list_frame = tk.Frame(dialog, bg="white")
        list_frame.pack(fill="both", expand=True, padx=16)

        devices = [
            ("ZKBrain-PRO-8801", "DC:23:4F:9A:88:01", -58),
            ("MindWave Mobile 2", "AA:BB:CC:11:22:33", -72),
            ("ZKBrain Headband Lite", "DC:23:4F:55:66:77", -64)
        ]

        for name, mac, rssi in devices:
            item_frame = tk.Frame(list_frame, bg="#F8FAFC", relief="solid", bd=1, padx=10, pady=8)
            item_frame.pack(fill="x", pady=4)

            info_f = tk.Frame(item_frame, bg="#F8FAFC")
            info_f.pack(side="left")
            tk.Label(info_f, text=name, font=("Segoe UI", 10, "bold"), fg="#0F172A", bg="#F8FAFC").pack(anchor="w")
            tk.Label(info_f, text=f"{mac} | RSSI: {rssi} dBm", font=("Segoe UI", 8), fg="#64748B", bg="#F8FAFC").pack(anchor="w")

            conn_btn = tk.Button(item_frame, text="连接", font=("Segoe UI", 9, "bold"), bg="#16A34A", fg="white", relief="flat", padx=10, pady=2, cursor="hand2")
            conn_btn.config(command=lambda n=name, m=mac, d=dialog: self._connect_device(n, m, d))
            conn_btn.pack(side="right")

    def _connect_device(self, name, mac, dialog):
        self.device_name = name
        self.device_mac = mac
        self.dev_name_lbl.config(text=name)
        self.dev_mac_lbl.config(text=f"MAC: {mac}  |  SN: ZK-2026-DEV001")
        self.is_connected = True
        self.dot_canvas.itemconfig(self.dot_item, fill="#22C55E")
        self.status_lbl.config(text="已就绪 (READY)", fg="#16A34A")
        self.btn_toggle_connect.config(text="断开设备", bg="#DC2626")
        self.add_log(f"[BLE] 成功连接至设备: {name} ({mac})")
        dialog.destroy()

if __name__ == "__main__":
    app = DeviceScreenApp()
    app.mainloop()
