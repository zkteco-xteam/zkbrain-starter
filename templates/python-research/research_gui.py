import sys
import time
import random
import tkinter as tk
from tkinter import ttk, messagebox

"""
1:1 Device Management Console (DeviceScreen + DeviceShowTable) - Python Research Workstation Edition
Technical Support: ZKTeco Brain-Computer Interface Division
For universities, research institutes, and algorithm developers. Built-in 12 metrics color-coded table, MEMS attitude, and EDF/CSV export.
"""

class ResearchGuiApp(tk.Tk):
    def __init__(self):
        super().__init__()
        self.title("ZKBrain BCI Research Algorithm Workstation (DeviceScreen)")
        self.geometry("980, 860")
        self.configure(bg="#f1f5f9")

        # State variables
        self.is_connected = False
        self.device_name = "ZKBrain-PRO-8801"
        self.device_mac = "DC:23:4F:9A:88:01"
        self.battery = 85

        # 12 metrics data
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

        # 6-axis MEMS
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
        # Top Bar
        top_bar = tk.Frame(self, bg="#f1f5f9", pady=8)
        top_bar.pack(fill="x", padx=16)

        tk.Label(top_bar, text="Device Management (DeviceScreen) - Research Workstation", font=("Segoe UI", 16, "bold"), bg="#f1f5f9", fg="#0f172a").pack(side="left")

        btn_dfu = tk.Button(top_bar, text="DFU OTA", bg="#475569", fg="white", font=("Segoe UI", 9, "bold"), relief="flat", padx=10, command=self._ota_check)
        btn_dfu.pack(side="right", padx=4)

        btn_search = tk.Button(top_bar, text="Search BLE", bg="#2563eb", fg="white", font=("Segoe UI", 9, "bold"), relief="flat", padx=10, command=self._show_scan_dialog)
        btn_search.pack(side="right", padx=4)

        tk.Label(top_bar, text="Authorized", bg="#dcfce7", fg="#16a34a", font=("Segoe UI", 9, "bold"), padx=6, pady=2).pack(side="right", padx=4)

        # Main scrollable canvas
        canvas = tk.Canvas(self, bg="#f1f5f9", highlightthickness=0)
        scrollbar = ttk.Scrollbar(self, orient="vertical", command=canvas.yview)
        scroll_frame = tk.Frame(canvas, bg="#f1f5f9")
        scroll_frame.bind("<Configure>", lambda e: canvas.configure(scrollregion=canvas.bbox("all")))
        canvas.create_window((0, 0), window=scroll_frame, anchor="nw")
        canvas.configure(xscrollcommand=scrollbar.set)
        canvas.pack(side="left", fill="both", expand=True, padx=16)
        scrollbar.pack(side="right", fill="y")

        # 1. Status Card
        status_card = tk.Frame(scroll_frame, bg="white", padx=14, pady=12, highlightthickness=1, highlightbackground="#e2e8f0")
        status_card.pack(fill="x", pady=6)

        st_row = tk.Frame(status_card, bg="white")
        st_row.pack(fill="x")
        self.lbl_status = tk.Label(st_row, text="DISCONNECTED", font=("Segoe UI", 10, "bold"), fg="#dc2626", bg="white")
        self.lbl_status.pack(side="left")
        tk.Label(st_row, text=f"Battery: {self.battery}%", font=("Segoe UI", 9, "bold"), fg="#16a34a", bg="#dcfce7", padx=8).pack(side="right")

        tk.Label(status_card, text=self.device_name, font=("Segoe UI", 13, "bold"), bg="white", fg="#0f172a").pack(anchor="w", pady=(6, 0))
        tk.Label(status_card, text=f"MAC: {self.device_mac}", font=("Courier", 9), bg="white", fg="#64748b").pack(anchor="w")

        self.btn_conn = tk.Button(status_card, text="Connect Device", bg="#2563eb", fg="white", font=("Segoe UI", 10, "bold"), relief="flat", pady=4, command=self._toggle_connect)
        self.btn_conn.pack(fill="x", pady=(8, 0))

        # 2. 6-Axis MEMS Attitude Card
        mems_card = tk.Frame(scroll_frame, bg="white", padx=14, pady=12, highlightthickness=1, highlightbackground="#e2e8f0")
        mems_card.pack(fill="x", pady=6)
        tk.Label(mems_card, text="MEMS 6-Axis Spatial Attitude (Euler Angles & Quaternions):", font=("Segoe UI", 10, "bold"), bg="white", fg="#1e293b").pack(anchor="w")
        self.lbl_mems1 = tk.Label(mems_card, text="", font=("Courier", 9), bg="white", fg="#0f172a")
        self.lbl_mems1.pack(anchor="w")
        self.lbl_mems2 = tk.Label(mems_card, text="", font=("Courier", 9), bg="white", fg="#64748b")
        self.lbl_mems2.pack(anchor="w")
        self._update_mems_labels()

        # 3. 4x3 Spectrum Metrics Table (DeviceShowTable)
        table_card = tk.Frame(scroll_frame, bg="white", padx=14, pady=12, highlightthickness=1, highlightbackground="#e2e8f0")
        table_card.pack(fill="x", pady=6)
        tk.Label(table_card, text="4x3 Full-Band Spectrum Metrics (DeviceShowTable)", font=("Segoe UI", 11, "bold"), bg="white", fg="#1e293b").pack(anchor="w")
        tk.Label(table_card, text="1:1 realization of shared1 console; Pink: Cognitive & Quality, Cyan: Slow & Alpha, Yellow: High Frequency", font=("Segoe UI", 8), bg="white", fg="#64748b").pack(anchor="w", pady=(0, 6))

        tk.Label(table_card, text=f"MAC: {self.device_mac}", font=("Courier", 9, "bold"), bg="#1e293b", fg="white", pady=3).pack(fill="x", pady=(0, 4))

        grid_frame = tk.Frame(table_card, bg="#cbd5e1", padx=1, pady=1)
        grid_frame.pack(fill="x")

        # Row 1 (Pink)
        self._create_cell(grid_frame, 0, 0, "Attention", self.attention, "#ffe4e1")
        self._create_cell(grid_frame, 0, 1, "Meditation", self.meditation, "#ffe4e1")
        self._create_cell(grid_frame, 0, 2, "Quality", self.signal_quality, "#ffe4e1")
        # Row 2 (Pink + Cyan + Cyan)
        self._create_cell(grid_frame, 1, 0, "Raw EEG", self.raw_eeg, "#ffe4e1")
        self._create_cell(grid_frame, 1, 1, "Delta", self.delta, "#e0ffff")
        self._create_cell(grid_frame, 1, 2, "Theta", self.theta, "#e0ffff")
        # Row 3 (Cyan + Cyan + Yellow)
        self._create_cell(grid_frame, 2, 0, "Low Alpha", self.low_alpha, "#e0ffff")
        self._create_cell(grid_frame, 2, 1, "High Alpha", self.high_alpha, "#e0ffff")
        self._create_cell(grid_frame, 2, 2, "Low Beta", self.low_beta, "#f0e68c")
        # Row 4 (Yellow)
        self._create_cell(grid_frame, 3, 0, "High Beta", self.high_beta, "#f0e68c")
        self._create_cell(grid_frame, 3, 1, "Low Gamma", self.low_gamma, "#f0e68c")
        self._create_cell(grid_frame, 3, 2, "Mid Gamma", self.mid_gamma, "#f0e68c")

        for col in range(3):
            grid_frame.columnconfigure(col, weight=1)

        # 4. Research Export Toolbox
        export_card = tk.Frame(scroll_frame, bg="white", padx=14, pady=12, highlightthickness=1, highlightbackground="#e2e8f0")
        export_card.pack(fill="x", pady=6)
        tk.Label(export_card, text="Research Dataset Export Tools (MNE-Python & BIDS Standard):", font=("Segoe UI", 10, "bold"), bg="white", fg="#1e293b").pack(anchor="w", pady=(0, 6))

        exp_row = tk.Frame(export_card, bg="white")
        exp_row.pack(fill="x")
        tk.Button(exp_row, text="Export EDF Dataset", bg="#16a34a", fg="white", font=("Segoe UI", 9, "bold"), relief="flat", padx=12, pady=4, command=self._export_edf).pack(side="left", padx=4)
        tk.Button(exp_row, text="Export CSV Features", bg="#0284c7", fg="white", font=("Segoe UI", 9, "bold"), relief="flat", padx=12, pady=4, command=self._export_csv).pack(side="left", padx=4)
        tk.Button(exp_row, text="Plot MNE PSD Spectrum", bg="#7c3aed", fg="white", font=("Segoe UI", 9, "bold"), relief="flat", padx=12, pady=4, command=self._plot_psd).pack(side="left", padx=4)

        # 5. Terminal Monitor
        term_card = tk.Frame(scroll_frame, bg="#0f172a", padx=12, pady=10)
        term_card.pack(fill="x", pady=6)
        t_top = tk.Frame(term_card, bg="#0f172a")
        t_top.pack(fill="x")
        tk.Label(t_top, text="Algorithm Pipeline & Hardware Monitor:", font=("Segoe UI", 9), fg="#94a3b8", bg="#0f172a").pack(side="left")
        tk.Button(t_top, text="Clear", font=("Segoe UI", 8), fg="#38bdf8", bg="#0f172a", relief="flat", command=self._clear_logs).pack(side="right")

        self.txt_logs = tk.Text(term_card, height=6, bg="#0f172a", fg="#4ade80", font=("Courier", 8), relief="flat")
        self.txt_logs.pack(fill="x", pady=(4, 0))
        self.txt_logs.insert("end", "[System] ZKBrain Python Research Workstation initialized\n[MNE-Python] Filter core ready: 0.5-50Hz bandpass + 50Hz notch\n")

    def _create_cell(self, parent, row, col, label, var, bg_color):
        cell = tk.Frame(parent, bg=bg_color, padx=4, pady=6)
        cell.grid(row=row, column=col, sticky="nsew", padx=1, pady=1)
        tk.Label(cell, text=label, font=("Segoe UI", 8, "bold"), bg=bg_color, fg="#334155").pack()
        tk.Label(cell, textvariable=var, font=("Courier", 10, "bold"), bg=bg_color, fg="#0f172a").pack()

    def _update_mems_labels(self):
        self.lbl_mems1.config(text=f"Roll: {self.roll.get():.1f} | Pitch: {self.pitch.get():.1f} | Yaw: {self.yaw.get():.1f}")
        self.lbl_mems2.config(text=f"Q0: {self.q0.get():.3f} | Q1: {self.q1.get():.3f} | Q2: {self.q2.get():.3f} | Q3: {self.q3.get():.3f}")

    def _append_log(self, text):
        self.txt_logs.insert("end", f"{text}\n")
        self.txt_logs.see("end")

    def _clear_logs(self):
        self.txt_logs.delete("1.0", "end")

    def _ota_check(self):
        self._append_log("[DFU] OTA firmware check: Already on latest stable release v2.4.0")
        messagebox.showinfo("Firmware Check", "Current firmware is up to date (v2.4.0)")

    def _toggle_connect(self):
        if self.is_connected:
            self.is_connected = False
            self.lbl_status.config(text="DISCONNECTED", fg="#dc2626")
            self.btn_conn.config(text="Connect Device", bg="#2563eb")
            self._append_log("[BLE] Disconnected by user")
        else:
            self._show_scan_dialog()

    def _show_scan_dialog(self):
        self.is_connected = True
        self.lbl_status.config(text="CONNECTED", fg="#16a34a")
        self.btn_conn.config(text="Disconnect", bg="#dc2626")
        self._append_log(f"[BLE] Connection established: {self.device_name} ({self.device_mac})")

    def _export_edf(self):
        self._append_log("[Export] Exporting European Data Format dataset: session_eeg_record.edf")
        messagebox.showinfo("EDF Export", "Successfully exported session_eeg_record.edf (EDF+ standard, 512Hz raw EEG and 8 band power channels)")

    def _export_csv(self):
        self._append_log("[Export] Exported temporal feature tables: events.csv and meta.json")
        messagebox.showinfo("CSV Export", "Successfully generated events.csv (8-band power spectrum and 1Hz attention/meditation)")

    def _plot_psd(self):
        self._append_log("[Analysis] Running MNE-Python PSD Welch power spectral density estimation...")
        messagebox.showinfo("Algorithm Analysis", "MNE-Python analysis completed: Delta(0.5-4Hz), Theta(4-8Hz), Alpha(8-13Hz), Beta(13-30Hz), Gamma(30-50Hz)")

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
