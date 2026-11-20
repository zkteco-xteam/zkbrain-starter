import http.server
import socketserver
import os

"""
ZKBrain Raspberry Pi LAN 1:1 Web Monitoring Dashboard (DeviceScreen)
Starts a lightweight HTTP static server. Open http://<Pi_IP>:8080 from any browser on the LAN.
"""

PORT = 8080

HTML_CONTENT = """<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Device Management (DeviceScreen) - Raspberry Pi Edge Dashboard</title>
  <style>
    * { box-sizing: border-box; margin: 0; padding: 0; }
    body { font-family: -apple-system, sans-serif; background: #f1f5f9; padding: 14px; color: #0f172a; }
    .container { max-width: 900px; margin: 0 auto; }
    .header-bar { display: flex; justify-content: space-between; align-items: center; margin-bottom: 12px; }
    .header-title { font-size: 18px; font-weight: bold; }
    .card { background: white; border-radius: 12px; padding: 14px; margin-bottom: 12px; box-shadow: 0 1px 3px rgba(0,0,0,0.05); }
    .card-title { font-size: 14px; font-weight: bold; margin-bottom: 4px; color: #1e293b; }
    .status-row { display: flex; justify-content: space-between; align-items: center; }
    .status-badge { color: #16a34a; font-weight: bold; font-size: 13px; }
    .table-mac { background: #1e293b; color: white; text-align: center; padding: 6px; font-family: monospace; border-radius: 4px; margin-bottom: 8px; font-size: 12px; }
    .table-container { border: 1px solid #cbd5e1; border-radius: 4px; overflow: hidden; }
    .table-row { display: flex; border-bottom: 1px solid #cbd5e1; }
    .table-row:last-child { border-bottom: none; }
    .table-cell { flex: 1; padding: 8px 4px; text-align: center; border-right: 1px solid #cbd5e1; }
    .table-cell:last-child { border-right: none; }
    .cell-label { font-size: 10px; font-weight: bold; color: #334155; }
    .cell-val { font-family: monospace; font-size: 13px; font-weight: bold; }
    .bg-pink { background: #ffe4e1; }
    .bg-cyan { background: #e0ffff; }
    .bg-yellow { background: #f0e68c; }
    .mems-box { background: #f8fafc; border: 1px solid #e2e8f0; border-radius: 6px; padding: 10px; font-family: monospace; font-size: 11px; margin-bottom: 8px; }
    .terminal-box { background: #0f172a; border-radius: 6px; padding: 10px; color: #4ade80; font-family: monospace; font-size: 11px; height: 100px; overflow-y: auto; }
  </style>
</head>
<body>
  <div class="container">
    <div class="header-bar">
      <div class="header-title">Device Management (DeviceScreen) - Raspberry Pi Edge Gateway</div>
      <div style="background:#dcfce7; color:#16a34a; padding:3px 8px; border-radius:4px; font-size:11px; font-weight:bold;">Watchdog Active</div>
    </div>

    <div class="card">
      <div class="status-row">
        <span class="status-badge">CONNECTED</span>
        <span style="background:#dcfce7; color:#16a34a; padding:2px 8px; border-radius:10px; font-size:11px; font-weight:bold;">85%</span>
      </div>
      <div style="font-size:16px; font-weight:bold; margin-top:6px;">ZKBrain-PRO-8801 (Smart Helmet / In-Vehicle Terminal)</div>
      <div style="font-size:11px; color:#64748b; font-family:monospace; margin-bottom:8px;">MAC: DC:23:4F:9A:88:01 | GPIO Pin 18 Alert Armed</div>
    </div>

    <div class="card">
      <div class="card-title">MEMS 6-Axis Spatial Attitude</div>
      <div class="mems-box">
        Roll: 1.2 | Pitch: -0.5 | Yaw: 14.8<br>
        Q0: 0.992 | Q1: 0.010 | Q2: -0.004 | Q3: 0.129
      </div>
    </div>

    <div class="card">
      <div class="card-title">4x3 Full-Band Spectrum Metrics (DeviceShowTable)</div>
      <div class="table-mac">MAC: DC:23:4F:9A:88:01</div>
      <div class="table-container">
        <div class="table-row">
          <div class="table-cell bg-pink"><div class="cell-label">Attention</div><div class="cell-val">78</div></div>
          <div class="table-cell bg-pink"><div class="cell-label">Meditation</div><div class="cell-val">65</div></div>
          <div class="table-cell bg-pink"><div class="cell-label">Quality</div><div class="cell-val">0</div></div>
        </div>
        <div class="table-row">
          <div class="table-cell bg-pink"><div class="cell-label">Raw EEG</div><div class="cell-val">142</div></div>
          <div class="table-cell bg-cyan"><div class="cell-label">Delta</div><div class="cell-val">12450</div></div>
          <div class="table-cell bg-cyan"><div class="cell-label">Theta</div><div class="cell-val">8320</div></div>
        </div>
        <div class="table-row">
          <div class="table-cell bg-cyan"><div class="cell-label">Low Alpha</div><div class="cell-val">15300</div></div>
          <div class="table-cell bg-cyan"><div class="cell-label">High Alpha</div><div class="cell-val">21040</div></div>
          <div class="table-cell bg-yellow"><div class="cell-label">Low Beta</div><div class="cell-val">18900</div></div>
        </div>
        <div class="table-row">
          <div class="table-cell bg-yellow"><div class="cell-label">High Beta</div><div class="cell-val">11200</div></div>
          <div class="table-cell bg-yellow"><div class="cell-label">Low Gamma</div><div class="cell-val">4600</div></div>
          <div class="table-cell bg-yellow"><div class="cell-label">Mid Gamma</div><div class="cell-val">2100</div></div>
        </div>
      </div>
    </div>

    <div class="card">
      <div class="card-title">Edge Gateway Daemon Logs</div>
      <div class="terminal-box">
        [System] Edge gateway watchdog daemon started<br>
        [BLE] Physical BLE link ready, streaming 512Hz raw EEG<br>
        [GPIO] Pin 18 ready: Fatigue status normal (Fatigue: 18, Threshold: 75)
      </div>
    </div>
  </div>
</body>
</html>
"""

class CustomHandler(http.server.SimpleHTTPRequestHandler):
    def do_GET(self):
        self.send_response(200)
        self.send_header("Content-type", "text/html; charset=utf-8")
        self.end_headers()
        self.wfile.write(HTML_CONTENT.encode("utf-8"))

def run():
    with socketserver.TCPServer(("", PORT), CustomHandler) as httpd:
        print(f"ZKBrain Raspberry Pi Edge Web Console running at: http://0.0.0.0:{PORT}")
        print("Accessible via phone or industrial tablet browser on the same LAN.")
        try:
            httpd.serve_forever()
        except KeyboardInterrupt:
            print("\nService stopped.")

if __name__ == "__main__":
    run()
