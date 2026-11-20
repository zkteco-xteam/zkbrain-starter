using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace ZKBrain.Unity
{
    /// <summary>
    /// ZKBrain Unity Cross-Platform BCI C# Bridge
    /// Suitable for PC Standalone, Meta Quest, Pico VR, Apple Vision Pro, Android and iOS games.
    /// Technical Support: ZKTeco Brain-Computer Interface Division
    /// </summary>
    public class ZKBrainBleBridge : MonoBehaviour
    {
        public static ZKBrainBleBridge Instance { get; private set; }

        [Header("Connection Status")]
        public bool isConnected = false;
        public string deviceName = "ZKBrain Headband PRO";
        public string deviceMac = "DC:23:4F:9A:88:01";
        public int batteryLevel = 85;

        [Header("12 Physiological Metrics")]
        [Range(0, 100)] public int attention = 75;
        [Range(0, 100)] public int meditation = 68;
        public int signalQuality = 0; // 0: Good contact, 200: Poor contact / off-head
        public int rawEeg = 128;

        [System.Serializable]
        public struct BrainWaveBands
        {
            public int delta;
            public int theta;
            public int lowAlpha;
            public int highAlpha;
            public int lowBeta;
            public int highBeta;
            public int lowGamma;
            public int middleGamma;
        }

        public BrainWaveBands waves = new BrainWaveBands
        {
            delta = 14200,
            theta = 8900,
            lowAlpha = 16100,
            highAlpha = 21800,
            lowBeta = 19500,
            highBeta = 11200,
            lowGamma = 4800,
            middleGamma = 2200
        };

        [Header("6-Axis MEMS Attitude")]
        public Vector3 eulerAngles = new Vector3(1.2f, -0.5f, 14.8f);
        public Quaternion quaternion = new Quaternion(0.010f, -0.004f, 0.129f, 0.992f);

        // Callbacks
        public event Action<int, int> OnBrainMetricsUpdated; // attention, meditation
        public event Action<string> OnCommandLogEmitted;

        private void Awake()
        {
            if (Instance == null) Instance = this;
            else Destroy(gameObject);
        }

        private void Start()
        {
            Log("[SYSTEM] ZKBrain Unity C# BCI Engine initialized and ready");
            StartCoroutine(SimulateDataStream());
        }

        private IEnumerator SimulateDataStream()
        {
            while (true)
            {
                yield return new WaitForSeconds(1.0f);
                if (isConnected)
                {
                    attention = Mathf.Clamp(attention + UnityEngine.Random.Range(-5, 6), 10, 100);
                    meditation = Mathf.Clamp(meditation + UnityEngine.Random.Range(-5, 6), 10, 100);
                    rawEeg = UnityEngine.Random.Range(-120, 120);

                    OnBrainMetricsUpdated?.Invoke(attention, meditation);
                }
            }
        }

        public void ConnectDevice(string name, string mac)
        {
            deviceName = name;
            deviceMac = mac;
            isConnected = true;
            Log($"[BLE] Connected to device: {name} ({mac})");
        }

        public void DisconnectDevice()
        {
            isConnected = false;
            Log("[BLE] Device disconnected by user");
        }

        public void SendIgnitionPacket()
        {
            // 0x15: Raw 512Hz, 0x17: 8 Bands
            byte[] packet = new byte[] { 0x02, 0x15, 0x17 };
            Log("[TX >> XMW] Ignition Packet: 0x15 (Raw) + 0x17 (Band)");
        }

        public void SendConfig(string key, string value)
        {
            Log($"[TX >> sendConfig] {key}:{value}");
        }

        public void Log(string msg)
        {
            Debug.Log($"<color=#38bdf8>[ZKBrain]</color> {msg}");
            OnCommandLogEmitted?.Invoke(msg);
        }
    }
}
