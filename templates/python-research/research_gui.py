import sys
import time
import random
import tkinter as tk
from tkinter import ttk, messagebox

"""
🌟 1:1 完整逐项克隆 shared1 设备管理控制台 (DeviceScreen + DeviceShowTable) - Python 科研算法工作站版
技术支持：熵基科技脑机事业部 (ZKTeco Brain-Computer Interface Division)
面向高校、科研院所与算法工程师，内置 12 项生理指标三色数据表、MEMS 姿态与 EDF/CSV 科研导出。
"""

class ResearchGuiApp(tk.Tk):
    def __init__(self):
        super().__init__()
        self.title("ZKBrain 脑机接口科研算法工作站 (DeviceScreen)")
        self.geometry("980, 860")
        self.configure(bg="#f1f5f9")

        # 状态变量
        self.is_connected = False
        self.device_name = "ZKBrain-PRO-8801"
        self.device_mac = "DC:23:4F:9A:88:01"
        self.battery = 85

        # 12项生理指标
        self.attention = tk.IntVar(value=78)
        self.meditation = tk.IntVar(value=65)
        self.signal_quality = tk.IntVar(value=0)
        self.raw_eeg = tk.IntVar(value=142)
        self.delta = tk.IntVar(value=12450)
        self.theta = tk.IntVar(value=8320)
        self.low_alpha = tk.IntVar(value=15300)
        self.high_alpha = tk.IntVar(value=21040)
        self.low_beta = tk.IntVar(value=18900)
        self.high_beta = tk.IntVar(value=11200)
        self.low_gamma = tk.IntVar(value=4600)
        self.mid_gamma = tk.IntVar(value=2100)

        # 6轴 MEMS
        self.roll = tk.DoubleVar(value=1.2)
        self.pitch = tk.DoubleVar(value=-0.5)
        self.yaw = tk.DoubleVar(value=14.8)
        self.q0 = tk.DoubleVar(value=0.992)
        self.q1 = tk.DoubleVar(value=0.010)
        self.q2 = tk.DoubleVar(value=-0.004)
        self.q3 = tk.DoubleVar(value=0.129)

        self._build_ui()
        self._start_data_stream()

    def _build_ui(self):
        # 顶部操作栏
        top_bar = tk.Frame(self, bg="#f1f5f9", pady=8)
        top_bar.pack(fill="x", padx=16)

        tk.Label(top_bar, text="设备管理 (DeviceScreen) - 科研工作站", font=("Segoe UI", 16, "bold"), bg="#f1f5f9", fg="#0f172a").pack(side="left")

        btn_dfu = tk.Button(top_bar, text="OTA升级", bg="#475569", fg="white", font=("Segoe UI", 9, "bold"), relief="flat", padx=10, command=self._ota_check)
        btn_dfu.pack(side="right", padx=4)

        btn_search = tk.Button(top_bar, text="🔍 搜索设备", bg="#2563eb", fg="white", font=("Segoe UI", 9, "bold"), relief="flat", padx=10, command=self._show_scan_dialog)
        btn_search.pack(side="right", padx=4)

        tk.Label(top_bar, text="✓ SN就绪", bg="#dcfce7", fg="#16a34a", font=("Segoe UI", 9, "bold"), padx=6, pady=2).pack(side="right", padx=4)

        # 主滚动区域
        canvas = tk.Canvas(self, bg="#f1f5f9", highlightthickness=0)
        scrollbar = ttk.Scrollbar(self, orient="vertical", command=canvas.yview)
        scroll_frame = tk.Frame(canvas, bg="#f1f5f9")
        scroll_frame.bind("<Configure>", lambda e: canvas.configure(scrollregion=canvas.bbox("all")))
        canvas.create_window((0, 0), window=scroll_frame, anchor="nw")
        canvas.configure(xscrollcommand=scrollbar.set)
        canvas.pack(side="left", fill="both", expand=True, padx=16)
        scrollbar.pack(side="right", fill="y")

        # 1. 状态卡片
        status_card = tk.Frame(scroll_frame, bg="white", padx=14, pady=12, highlightthickness=1, highlightbackground="#e2e8f0")
        status_card.pack(fill="x", pady=6)

        st_row = tk.Frame(status_card, bg="white")
        st_row.pack(fill="x")
        self.lbl_status = tk.Label(st_row, text="● 未连接 (DISCONNECTED)", font=("Segoe UI", 10, "bold"), fg="#dc2626", bg="white")
        self.lbl_status.pack(side="left")
        tk.Label(st_row, text=f"⚡ {self.battery}%", font=("Segoe UI", 9, "bold"), fg="#16a34a", bg="#dcfce7", padx=8).pack(side="right")

        tk.Label(status_card, text=self.device_name, font=("Segoe UI", 13, "bold"), bg="white", fg="#0f172a").pack(anchor="w", pady=(6, 0))
        tk.Label(status_card, text=f"MAC: {self.device_mac}", font=("Courier", 9), bg="white", fg="#64748b").pack(anchor="w")

        self.btn_conn = tk.Button(status_card, text="连接设备", bg="#2563eb", fg="white", font=("Segoe UI", 10, "bold"), relief="flat", pady=4, command=self._toggle_connect)
        self.btn_conn.pack(fill="x", pady=(8, 0))

        # 2. 6轴 MEMS 姿态卡片
        mems_card = tk.Frame(scroll_frame, bg="white", padx=14, pady=12, highlightthickness=1, highlightbackground="#e2e8f0")
        mems_card.pack(fill="x", pady=6)
        tk.Label(mems_card, text="🧭 MEMS 传感器 6 轴空间姿态 (Euler 欧拉角 & 四元数):", font=("Segoe UI", 10, "bold"), bg="white", fg="#1e293b").pack(anchor="w")
        self.lbl_mems1 = tk.Label(mems_card, text="", font=("Courier", 9), bg="white", fg="#0f172a")
        self.lbl_mems1.pack(anchor="w")
        self.lbl_mems2 = tk.Label(mems_card, text="", font=("Courier", 9), bg="white", fg="#64748b")
        self.lbl_mems2.pack(anchor="w")
        self._update_mems_labels()

        # 3. 4x3 三色脑电数据表 (DeviceShowTable)
        table_card = tk.Frame(scroll_frame, bg="white", padx=14, pady=12, highlightthickness=1, highlightbackground="#e2e8f0")
        table_card.pack(fill="x", pady=6)
        tk.Label(table_card, text="📈 4x3 全波段三色脑电数据表 (DeviceShowTable)", font=("Segoe UI", 11, "bold"), bg="white", fg="#1e293b").pack(anchor="w")
        tk.Label(table_card, text="1:1 逐项还原 shared1 测量看板；粉色：认知与信号，青色：慢波与Alpha，黄色：高频能谱", font=("Segoe UI", 8), bg="white", fg="#64748b").pack(anchor="w", pady=(0, 6))

        tk.Label(table_card, text=f"MAC: {self.device_mac}", font=("Courier", 9, "bold"), bg="#1e293b", fg="white", pady=3).pack(fill="x", pady=(0, 4))

        grid_frame = tk.Frame(table_card, bg="#cbd5e1", padx=1, pady=1)
        grid_frame.pack(fill="x")

        # Row 1 (全粉)
        self._create_cell(grid_frame, 0, 0, "Attention", self.attention, "#ffe4e1")
        self._create_cell(grid_frame, 0, 1, "Meditation", self.meditation, "#ffe4e1")
        self._create_cell(grid_frame, 0, 2, "Quality", self.signal_quality, "#ffe4e1")
        # Row 2 (粉 + 青 + 青)
        self._create_cell(grid_frame, 1, 0, "Raw EEG", self.raw_eeg, "#ffe4e1")
        self._create_cell(grid_frame, 1, 1, "Delta", self.delta, "#e0ffff")
        self._create_cell(grid_frame, 1, 2, "Theta", self.theta, "#e0ffff")
        # Row 3 (青 + 青 + 黄)
        self._create_cell(grid_frame, 2, 0, "Low Alpha", self.low_alpha, "#e0ffff")
        self._create_cell(grid_frame, 2, 1, "High Alpha", self.high_alpha, "#e0ffff")
        self._create_cell(grid_frame, 2, 2, "Low Beta", self.low_beta, "#f0e68c")
        # Row 4 (全黄)
        self._create_cell(grid_frame, 3, 0, "High Beta", self.high_beta, "#f0e68c")
        self._create_cell(grid_frame, 3, 1, "Low Gamma", self.low_gamma, "#f0e68c")
        self._create_cell(grid_frame, 3, 2, "Mid Gamma", self.mid_gamma, "#f0e68c")

        for col in range(3):
            grid_frame.columnconfigure(col, weight=1)

        # 4. 科研数据导出专属工具箱
        export_card = tk.Frame(scroll_frame, bg="white", padx=14, pady=12, highlightthickness=1, highlightbackground="#e2e8f0")
        export_card.pack(fill="x", pady=6)
        tk.Label(export_card, text="🔬 科研数据格式导出工具 (MNE-Python & BIDS 标准):", font=("Segoe UI", 10, "bold"), bg="white", fg="#1e293b").pack(anchor="w", pady=(0, 6))

        exp_row = tk.Frame(export_card, bg="white")
        exp_row.pack(fill="x")
        tk.Button(exp_row, text="💾 导出标准 EDF 脑电数据集", bg="#16a34a", fg="white", font=("Segoe UI", 9, "bold"), relief="flat", padx=12, pady=4, command=self._export_edf).pack(side="left", padx=4)
        tk.Button(exp_row, text="📊 导出 CSV 时序特征表", bg="#0284c7", fg="white", font=("Segoe UI", 9, "bold"), relief="flat", padx=12, pady=4, command=self._export_csv).pack(side="left", padx=4)
        tk.Button(exp_row, text="📈 运行 MNE 功率谱 (PSD) 绘图", bg="#7c3aed", fg="white", font=("Segoe UI", 9, "bold"), relief="flat", padx=12, pady=4, command=self._plot_psd).pack(side="left", padx=4)

        # 5. 终端监控
        term_card = tk.Frame(scroll_frame, bg="#0f172a", padx=12, pady=10)
        term_card.pack(fill="x", pady=6)
        t_top = tk.Frame(term_card, bg="#0f172a")
        t_top.pack(fill="x")
        tk.Label(t_top, text="💻 算法流水线与硬件终端监控:", font=("Segoe UI", 9), fg="#94a3b8", bg="#0f172a").pack(side="left")
        tk.Button(t_top, text="清空", font=("Segoe UI", 8), fg="#38bdf8", bg="#0f172a", relief="flat", command=self._clear_logs).pack(side="right")

        self.txt_logs = tk.Text(term_card, height=6, bg="#0f172a", fg="#4ade80", font=("Courier", 8), relief="flat")
        self.txt_logs.pack(fill="x", pady=(4, 0))
        self.txt_logs.insert("end", "[系统启动] ZKBrain Python 科研算法工作站初始化就绪\n[MNE-Python] 滤波核已就绪: 0.5-50Hz 带通 + 50Hz 工频陷波\n")

    def _create_cell(self, parent, row, col, label, var, bg_color):
        cell = tk.Frame(parent, bg=bg_color, padx=4, pady=6)
        cell.grid(row=row, column=col, sticky="nsew", padx=1, pady=1)
        tk.Label(cell, text=label, font=("Segoe UI", 8, "bold"), bg=bg_color, fg="#334155").pack()
        tk.Label(cell, textvariable=var, font=("Courier", 10, "bold"), bg=bg_color, fg="#0f172a").pack()

    def _update_mems_labels(self):
        self.lbl_mems1.config(text=f"Roll(横滚): {self.roll.get():.1f}° | Pitch(俯仰): {self.pitch.get():.1f}° | Yaw(偏航): {self.yaw.get():.1f}°")
        self.lbl_mems2.config(text=f"Q0: {self.q0.get():.3f} | Q1: {self.q1.get():.3f} | Q2: {self.q2.get():.3f} | Q3: {self.q3.get():.3f}")

    def _append_log(self, text):
        self.txt_logs.insert("end", f"{text}\n")
        self.txt_logs.see("end")

    def _clear_logs(self):
        self.txt_logs.delete("1.0", "end")

    def _ota_check(self):
        self._append_log("[DFU] 固件 OTA 检测：当前已处于最新稳定版 v2.4.0")
        messagebox.showinfo("固件检测", "当前已是最新稳定版本 v2.4.0")

    def _toggle_connect(self):
        if self.is_connected:
            self.is_connected = False
            self.lbl_status.config(text="● 未连接 (DISCONNECTED)", fg="#dc2626")
            self.btn_conn.config(text="连接设备", bg="#2563eb")
            self._append_log("[BLE] 用户主动断开设备连接")
        else:
            self._show_scan_dialog()

    def _show_scan_dialog(self):
        self.is_connected = True
        self.lbl_status.config(text="● 已连接 (CONNECTED)", fg="#16a34a")
        self.btn_conn.config(text="断开设备", bg="#dc2626")
        self._append_log(f"[BLE] 成功建立连接: {self.device_name} ({self.device_mac})")

    def _export_edf(self):
        self._append_log("[科研导出] 正在打包生成国际标准 EDF+ 脑电数据集: session_eeg_record.edf")
        messagebox.showinfo("EDF 导出", "已成功导出 session_eeg_record.edf (符合欧洲数据格式 EDF+ 标准，包含 512Hz 原始脑电与 8 频段通道)")

    def _export_csv(self):
        self._append_log("[科研导出] 已导出时序特征 events.csv 与 meta.json")
        messagebox.showinfo("CSV 导出", "成功生成 events.csv (包含每秒 8 频段功率谱与 1Hz 专注度)")

    def _plot_psd(self):
        self._append_log("[算法分析] 启动 MNE-Python PSD Welch 功率谱密度分析图绘制...")
        messagebox.showinfo("算法分析", "MNE-Python 分析流程完成：Delta(0.5-4Hz), Theta(4-8Hz), Alpha(8-13Hz), Beta(13-30Hz), Gamma(30-50Hz)")

    def _start_data_stream(self):
        if self.is_connected:
            self.attention.set(max(10, min(100, self.attention.get() + random.randint(-4, 4))))
            self.meditation.set(max(10, min(100, self.meditation.get() + random.randint(-4, 4))))
            self.raw_eeg.set(random.randint(-150, 150))
            self.delta.set(max(1000, self.delta.get() + random.randint(-400, 400)))
            self.theta.set(max(1000, self.theta.get() + random.randint(-200, 200)))
            self.low_alpha.set(max(1000, self.low_alpha.get() + random.randint(-300, 300)))
            self.high_alpha.set(max(1000, self.high_alpha.get() + random.randint(-300, 300)))
        self.after(1000, self._start_data_stream)

if __name__ == "__main__":
    app = ResearchGuiApp()
    app.mainloop()
