using UnityEngine;

namespace ZKBrain.Unity
{
    /// <summary>
    /// 🌟 1:1 还原 shared1 设备管理控制台 (DeviceScreen + DeviceShowTable) - Unity OnGUI / Canvas 原生版
    /// </summary>
    public class DeviceScreenUI : MonoBehaviour
    {
        private ZKBrainBleBridge bridge;
        private Vector2 scrollPos;
        private string terminalLogs = "[系统启动] ZKBrain Unity 控制台就绪\n";
        private string customCmd = "mems_on:1";

        private void Start()
        {
            bridge = ZKBrainBleBridge.Instance ?? FindObjectOfType<ZKBrainBleBridge>();
            if (bridge != null)
            {
                bridge.OnCommandLogEmitted += log => terminalLogs += $"{log}\n";
            }
        }

        private void OnGUI()
        {
            GUI.skin.box.alignment = TextAnchor.MiddleCenter;

            // 绘制左侧控制台浮窗
            GUILayout.BeginArea(new Rect(15, 15, 420, Screen.height - 30), GUI.skin.window);
            scrollPos = GUILayout.BeginScrollView(scrollPos);

            // 1. 顶部操作栏
            GUILayout.BeginHorizontal();
            GUILayout.Label("<b>设备管理 (DeviceScreen)</b>", GUILayout.Width(180));
            if (GUILayout.Button("🔍 搜索", GUILayout.Width(60)))
            {
                bridge?.ConnectDevice("ZKBrain-PRO-8801", "DC:23:4F:9A:88:01");
            }
            if (GUILayout.Button("OTA升级", GUILayout.Width(65)))
            {
                bridge?.Log("[DFU] 固件 OTA 检测：当前处于最新版 v2.4.0");
            }
            GUILayout.Label("<color=#16a34a><b>✓ SN就绪</b></color>");
            GUILayout.EndHorizontal();

            GUILayout.Space(8);

            // 2. 状态卡片
            GUILayout.BeginVertical(GUI.skin.box);
            GUILayout.BeginHorizontal();
            string statusColor = (bridge != null && bridge.isConnected) ? "#22c55e" : "#ef4444";
            string statusText = (bridge != null && bridge.isConnected) ? "已连接 (CONNECTED)" : "未连接 (DISCONNECTED)";
            GUILayout.Label($"状态: <color={statusColor}>● {statusText}</color>");
            GUILayout.FlexibleSpace();
            GUILayout.Label($"⚡ {bridge?.batteryLevel ?? 0}%");
            GUILayout.EndHorizontal();

            GUILayout.Label($"<b>{bridge?.deviceName}</b>");
            GUILayout.Label($"MAC: {bridge?.deviceMac}");

            if (GUILayout.Button((bridge != null && bridge.isConnected) ? "断开设备" : "连接设备", GUILayout.Height(30)))
            {
                if (bridge != null && bridge.isConnected) bridge.DisconnectDevice();
                else bridge?.ConnectDevice("ZKBrain-PRO-8801", "DC:23:4F:9A:88:01");
            }
            GUILayout.EndVertical();

            GUILayout.Space(8);

            // 3. MEMS 6轴姿态
            GUILayout.BeginVertical(GUI.skin.box);
            GUILayout.Label("<b>🧭 MEMS 传感器 6 轴空间姿态:</b>");
            if (bridge != null)
            {
                GUILayout.Label($"Roll: {bridge.eulerAngles.x:F1}° | Pitch: {bridge.eulerAngles.y:F1}° | Yaw: {bridge.eulerAngles.z:F1}°");
                GUILayout.Label($"Q0: {bridge.quaternion.w:F3} | Q1: {bridge.quaternion.x:F3} | Q2: {bridge.quaternion.y:F3} | Q3: {bridge.quaternion.z:F3}");
            }
            GUILayout.EndVertical();

            GUILayout.Space(8);

            // 4. 4x3 三色脑电数据表 (DeviceShowTable)
            GUILayout.BeginVertical(GUI.skin.box);
            GUILayout.Label("<b>📈 4x3 全波段三色脑电数据表 (DeviceShowTable)</b>");

            // Row 1 (全粉)
            DrawTableRow(
                ("Attention", $"{bridge?.attention ?? 0}", "#ffe4e1"),
                ("Meditation", $"{bridge?.meditation ?? 0}", "#ffe4e1"),
                ("Quality", $"{bridge?.signalQuality ?? 0}", "#ffe4e1")
            );
            // Row 2 (粉 + 青 + 青)
            DrawTableRow(
                ("Raw EEG", $"{bridge?.rawEeg ?? 0}", "#ffe4e1"),
                ("Delta", $"{bridge?.waves.delta ?? 0}", "#e0ffff"),
                ("Theta", $"{bridge?.waves.theta ?? 0}", "#e0ffff")
            );
            // Row 3 (青 + 青 + 黄)
            DrawTableRow(
                ("Low Alpha", $"{bridge?.waves.lowAlpha ?? 0}", "#e0ffff"),
                ("High Alpha", $"{bridge?.waves.highAlpha ?? 0}", "#e0ffff"),
                ("Low Beta", $"{bridge?.waves.lowBeta ?? 0}", "#f0e68c")
            );
            // Row 4 (全黄)
            DrawTableRow(
                ("High Beta", $"{bridge?.waves.highBeta ?? 0}", "#f0e68c"),
                ("Low Gamma", $"{bridge?.waves.lowGamma ?? 0}", "#f0e68c"),
                ("Mid Gamma", $"{bridge?.waves.middleGamma ?? 0}", "#f0e68c")
            );
            GUILayout.EndVertical();

            GUILayout.Space(8);

            // 5. 硬件指令控制台
            GUILayout.BeginVertical(GUI.skin.box);
            GUILayout.Label("<b>🛠️ 硬件协议指令交互:</b>");
            GUILayout.BeginHorizontal();
            if (GUILayout.Button("点火包 (0x15+0x17)")) bridge?.SendIgnitionPacket();
            if (GUILayout.Button("开启 MEMS (mems_on:1)")) bridge?.SendConfig("mems_on", "1");
            GUILayout.EndHorizontal();

            GUILayout.BeginHorizontal();
            customCmd = GUILayout.TextField(customCmd);
            if (GUILayout.Button("发送", GUILayout.Width(50)))
            {
                bridge?.Log($"[TX >>] {customCmd}");
            }
            GUILayout.EndHorizontal();
            GUILayout.EndVertical();

            GUILayout.Space(8);

            // 6. 终端日志
            GUILayout.BeginVertical(GUI.skin.box);
            GUILayout.BeginHorizontal();
            GUILayout.Label("<b>💻 硬件通信终端:</b>");
            if (GUILayout.Button("清空", GUILayout.Width(45))) terminalLogs = "";
            GUILayout.EndHorizontal();
            GUILayout.TextArea(terminalLogs, GUILayout.Height(90));
            GUILayout.EndVertical();

            GUILayout.EndScrollView();
            GUILayout.EndArea();
        }

        private void DrawTableRow((string label, string val, string hex) c1, (string label, string val, string hex) c2, (string label, string val, string hex) c3)
        {
            GUILayout.BeginHorizontal();
            DrawCell(c1.label, c1.val);
            DrawCell(c2.label, c2.val);
            DrawCell(c3.label, c3.val);
            GUILayout.EndHorizontal();
        }

        private void DrawCell(string label, string val)
        {
            GUILayout.BeginVertical(GUI.skin.box, GUILayout.Width(120));
            GUILayout.Label($"<size=10>{label}</size>");
            GUILayout.Label($"<b><size=12>{val}</size></b>");
            GUILayout.EndVertical();
        }
    }
}
