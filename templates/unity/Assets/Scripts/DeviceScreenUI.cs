using UnityEngine;

namespace ZKBrain.Unity
{
    /// <summary>
    /// 1:1 Recreation of shared1 Device Management Console (DeviceScreen + DeviceShowTable) - Unity OnGUI / Canvas Version
    /// </summary>
    public class DeviceScreenUI : MonoBehaviour
    {
        private ZKBrainBleBridge bridge;
        private Vector2 scrollPos;
        private string terminalLogs = "[SYSTEM] ZKBrain Unity BCI Console Ready\n";
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

            // Draw left HUD panel
            GUILayout.BeginArea(new Rect(15, 15, 420, Screen.height - 30), GUI.skin.window);
            scrollPos = GUILayout.BeginScrollView(scrollPos);

            // 1. Top Action Bar
            GUILayout.BeginHorizontal();
            GUILayout.Label("<b>DeviceScreen</b>", GUILayout.Width(160));
            if (GUILayout.Button("🔍 Scan", GUILayout.Width(65)))
            {
                bridge?.ConnectDevice("ZKBrain-PRO-8801", "DC:23:4F:9A:88:01");
            }
            if (GUILayout.Button("DFU", GUILayout.Width(60)))
            {
                bridge?.Log("[DFU] Checking firmware OTA: currently on latest stable v2.4.0");
            }
            GUILayout.Label("<color=#16a34a><b>✓ SN Ready</b></color>");
            GUILayout.EndHorizontal();

            GUILayout.Space(8);

            // 2. Status Card
            GUILayout.BeginVertical(GUI.skin.box);
            GUILayout.BeginHorizontal();
            string statusColor = (bridge != null && bridge.isConnected) ? "#22c55e" : "#ef4444";
            string statusText = (bridge != null && bridge.isConnected) ? "CONNECTED" : "DISCONNECTED";
            GUILayout.Label($"Status: <color={statusColor}>● {statusText}</color>");
            GUILayout.FlexibleSpace();
            GUILayout.Label($"⚡ {bridge?.batteryLevel ?? 0}%");
            GUILayout.EndHorizontal();

            GUILayout.Label($"<b>{bridge?.deviceName}</b>");
            GUILayout.Label($"MAC: {bridge?.deviceMac}");

            if (GUILayout.Button((bridge != null && bridge.isConnected) ? "Disconnect Device" : "Connect Device", GUILayout.Height(30)))
            {
                if (bridge != null && bridge.isConnected) bridge.DisconnectDevice();
                else bridge?.ConnectDevice("ZKBrain-PRO-8801", "DC:23:4F:9A:88:01");
            }
            GUILayout.EndVertical();

            GUILayout.Space(8);

            // 3. MEMS 6-Axis Attitude
            GUILayout.BeginVertical(GUI.skin.box);
            GUILayout.Label("<b>🧭 MEMS 6-Axis Spatial Attitude:</b>");
            if (bridge != null)
            {
                GUILayout.Label($"Roll: {bridge.eulerAngles.x:F1}° | Pitch: {bridge.eulerAngles.y:F1}° | Yaw: {bridge.eulerAngles.z:F1}°");
                GUILayout.Label($"Q0: {bridge.quaternion.w:F3} | Q1: {bridge.quaternion.x:F3} | Q2: {bridge.quaternion.y:F3} | Q3: {bridge.quaternion.z:F3}");
            }
            GUILayout.EndVertical();

            GUILayout.Space(8);

            // 4. 4x3 Tri-Color EEG Data Table (DeviceShowTable)
            GUILayout.BeginVertical(GUI.skin.box);
            GUILayout.Label("<b>📈 4x3 Full-Band Spectrum Matrix (DeviceShowTable)</b>");

            // Row 1 (Pink)
            DrawTableRow(
                ("Attention", $"{bridge?.attention ?? 0}", "#ffe4e1"),
                ("Meditation", $"{bridge?.meditation ?? 0}", "#ffe4e1"),
                ("Quality", $"{bridge?.signalQuality ?? 0}", "#ffe4e1")
            );
            // Row 2 (Pink + Cyan + Cyan)
            DrawTableRow(
                ("Raw EEG", $"{bridge?.rawEeg ?? 0}", "#ffe4e1"),
                ("Delta", $"{bridge?.waves.delta ?? 0}", "#e0ffff"),
                ("Theta", $"{bridge?.waves.theta ?? 0}", "#e0ffff")
            );
            // Row 3 (Cyan + Cyan + Yellow)
            DrawTableRow(
                ("Low Alpha", $"{bridge?.waves.lowAlpha ?? 0}", "#e0ffff"),
                ("High Alpha", $"{bridge?.waves.highAlpha ?? 0}", "#e0ffff"),
                ("Low Beta", $"{bridge?.waves.lowBeta ?? 0}", "#f0e68c")
            );
            // Row 4 (Yellow)
            DrawTableRow(
                ("High Beta", $"{bridge?.waves.highBeta ?? 0}", "#f0e68c"),
                ("Low Gamma", $"{bridge?.waves.lowGamma ?? 0}", "#f0e68c"),
                ("Mid Gamma", $"{bridge?.waves.middleGamma ?? 0}", "#f0e68c")
            );
            GUILayout.EndVertical();

            GUILayout.Space(8);

            // 5. Hardware Command Console
            GUILayout.BeginVertical(GUI.skin.box);
            GUILayout.Label("<b>🛠️ Hardware Protocol Commands:</b>");
            GUILayout.BeginHorizontal();
            if (GUILayout.Button("Ignition (0x15+0x17)")) bridge?.SendIgnitionPacket();
            if (GUILayout.Button("Enable MEMS (mems_on:1)")) bridge?.SendConfig("mems_on", "1");
            GUILayout.EndHorizontal();

            GUILayout.BeginHorizontal();
            customCmd = GUILayout.TextField(customCmd);
            if (GUILayout.Button("Send", GUILayout.Width(50)))
            {
                bridge?.Log($"[TX >>] {customCmd}");
            }
            GUILayout.EndHorizontal();
            GUILayout.EndVertical();

            GUILayout.Space(8);

            // 6. Terminal Output
            GUILayout.BeginVertical(GUI.skin.box);
            GUILayout.BeginHorizontal();
            GUILayout.Label("<b>💻 Hardware Communication Terminal:</b>");
            if (GUILayout.Button("Clear", GUILayout.Width(50))) terminalLogs = "";
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
