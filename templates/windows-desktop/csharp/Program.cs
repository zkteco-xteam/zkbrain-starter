using System;
using System.IO;
using System.Runtime.InteropServices;
using System.Threading.Tasks;

namespace ZKBrain.Windows.Demo
{
    /// <summary>
    /// ZKBrain Windows C/C++ DLL P/Invoke Interface Wrapper
    /// </summary>
    public static class ZKBrainNative
    {
        private const string DllName = "zkbrain_sec.dll";

        [UnmanagedFunctionPointer(CallingConvention.Cdecl)]
        public delegate void BrainDataCallback(IntPtr intData, double hw, float temp, IntPtr userData);

        [UnmanagedFunctionPointer(CallingConvention.Cdecl)]
        public delegate void RawWaveCallback(int raw, IntPtr userData);

        [DllImport(DllName, CallingConvention = CallingConvention.Cdecl)]
        public static extern int zkbrain_sec_init([MarshalAs(UnmanagedType.LPUTF8Str)] string licenseJsonStr);

        [DllImport(DllName, CallingConvention = CallingConvention.Cdecl)]
        public static extern IntPtr zkbrain_get_app_id();

        [DllImport(DllName, CallingConvention = CallingConvention.Cdecl)]
        [return: MarshalAs(UnmanagedType.I1)]
        public static extern bool zkbrain_sec_has_feature([MarshalAs(UnmanagedType.LPUTF8Str)] string featureName);

        [DllImport(DllName, CallingConvention = CallingConvention.Cdecl)]
        public static extern IntPtr zkbrain_parser_create();

        [DllImport(DllName, CallingConvention = CallingConvention.Cdecl)]
        public static extern void zkbrain_parser_destroy(IntPtr handle);

        [DllImport(DllName, CallingConvention = CallingConvention.Cdecl)]
        public static extern void zkbrain_parser_reset(IntPtr handle);

        [DllImport(DllName, CallingConvention = CallingConvention.Cdecl)]
        public static extern void zkbrain_parser_parse(IntPtr handle, byte[] data, int len);

        [DllImport(DllName, CallingConvention = CallingConvention.Cdecl)]
        public static extern void zkbrain_parser_set_callbacks(
            IntPtr handle,
            BrainDataCallback onData,
            RawWaveCallback onRaw,
            IntPtr onGravity,
            IntPtr onRRInterval,
            IntPtr onQuaternion,
            IntPtr userData
        );
    }

    class Program
    {
        // Static fields to hold delegates and prevent premature GC collection
        private static ZKBrainNative.BrainDataCallback s_onBrainData;
        private static ZKBrainNative.RawWaveCallback s_onRawWave;

        static async Task Main(string[] args)
        {
            Console.WriteLine("================================================================");
            Console.WriteLine("   ZKBrain Windows C# (.NET) Native BLE Scan & Parser Demo   ");
            Console.WriteLine("================================================================");

            // 1. Read license.lic and initialize authorization
            string licPath = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "license.lic");
            if (!File.Exists(licPath))
            {
                licPath = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "../../license.lic");
            }

            if (!File.Exists(licPath))
            {
                Console.WriteLine($"[Error] License file not found: {licPath}");
                return;
            }

            string licJson = File.ReadAllText(licPath);
            int authCode = ZKBrainNative.zkbrain_sec_init(licJson);
            if (authCode != 1024)
            {
                Console.WriteLine($"[Fatal Error] License verification failed, code: {authCode}");
                return;
            }
            Console.WriteLine("License authorized successfully (Code: 1024). Core algorithm engine unlocked.");

            // 2. Create parser instance
            IntPtr parser = ZKBrainNative.zkbrain_parser_create();
            if (parser == IntPtr.Zero)
            {
                Console.WriteLine("[Error] Parser instantiation failed.");
                return;
            }

            // 3. Register 1Hz metrics and 512Hz raw waveform callbacks
            s_onBrainData = (pIntData, hw, temp, userData) =>
            {
                int[] data = new int[15];
                Marshal.Copy(pIntData, data, 0, 15);

                int signal = data[0];
                int attention = data[1];
                int meditation = data[2];
                int battery = data[4];

                Console.WriteLine(new string('-', 60));
                if (signal == 0)
                {
                    Console.WriteLine($"[1Hz EEG] Attention: {attention,3} | Meditation: {meditation,3} | Battery: {battery,2}% | Temp: {temp:F1} C");
                    Console.WriteLine($"[Power Spectrum] Delta={data[7]}, Theta={data[8]}, LowAlpha={data[9]}, HighAlpha={data[10]}");
                    Console.WriteLine($"                 LowBeta={data[11]}, HighBeta={data[12]}, LowGamma={data[13]}, MidGamma={data[14]}");
                }
                else if (signal == 200)
                {
                    Console.WriteLine("[Off-Head Warning] Sensor detached from forehead (Signal=200). Please fit headband.");
                }
                else
                {
                    Console.WriteLine($"[Poor Signal Contact] Signal quality code: {signal} (Algorithm in hold mode)");
                }
                Console.WriteLine(new string('-', 60));
            };

            s_onRawWave = (raw, userData) =>
            {
                // 512Hz raw microvolt waveform, ready for oscilloscope UI plotting
            };

            ZKBrainNative.zkbrain_parser_set_callbacks(
                parser, 
                s_onBrainData, 
                s_onRawWave, 
                IntPtr.Zero, IntPtr.Zero, IntPtr.Zero, IntPtr.Zero
            );

            // 4. Start Windows Native BLE Auto Scan & Connect
            var bleManager = new BleManager(data =>
            {
                // BLE Notify bytes directly piped to SDK parser
                ZKBrainNative.zkbrain_parser_parse(parser, data, data.Length);
            });

            try
            {
                // Auto scan for nearby devices containing brain, mind, eeg, tgam, zkt keywords
                await bleManager.StartAutoScanAndConnectAsync(timeoutSeconds: 15);

                if (bleManager.CanWrite)
                {
                    Console.WriteLine("\n[Hardware Protocol Command Examples]:");
                    Console.WriteLine("  1. ZKTeco Enable MEMS motion stream: await bleManager.SendCommandAsync(\"mems_on:1;\\n\");");
                    Console.WriteLine("  2. ZKTeco Set 512Hz sample rate:     await bleManager.SendCommandAsync(\"eeg_data_rate:512;\\n\");");
                    Console.WriteLine("  3. ZKTeco Query battery level:       await bleManager.SendCommandAsync(\"battery:?\\n\");");
                    Console.WriteLine("  4. Sky (NeuroSky) Ignition packet:   await bleManager.SendBytesAsync(new byte[] { 0x02, 0x15, 0x17 });");
                    Console.WriteLine("  5. Sky 50Hz Notch filter:            await bleManager.SendBytesAsync(new byte[] { 0x02, 0x1B });");
                }

                Console.WriteLine("\nPress Enter to disconnect and exit...\n");
                Console.ReadLine();
            }
            finally
            {
                bleManager.Disconnect();
                ZKBrainNative.zkbrain_parser_destroy(parser);
                Console.WriteLine("Application exited cleanly. Resources released.");
            }
        }
    }
}
