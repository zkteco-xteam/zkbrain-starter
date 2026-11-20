using System;
using System.IO;
using System.Runtime.InteropServices;
using System.Threading.Tasks;

namespace ZKBrain.Windows.Demo
{
    /// <summary>
    /// ZKBrain Windows C/C++ 动态链接库 P/Invoke 接口封装
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
        // 🌟 必须使用静态字段持有委托引用，绝对不能定义在局部变量内，杜绝 GC 提前回收！
        private static ZKBrainNative.BrainDataCallback s_onBrainData;
        private static ZKBrainNative.RawWaveCallback s_onRawWave;

        static async Task Main(string[] args)
        {
            Console.WriteLine("================================================================");
            Console.WriteLine("   ZKBrain Windows C# (.NET) 原生 BLE 自动扫描与解调工程   ");
            Console.WriteLine("================================================================");

            // 1. 读取 license.lic 并初始化授权
            string licPath = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "license.lic");
            if (!File.Exists(licPath))
            {
                licPath = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "../../license.lic");
            }

            if (!File.Exists(licPath))
            {
                Console.WriteLine($"[错误] 未找到授权文件: {licPath}");
                return;
            }

            string licJson = File.ReadAllText(licPath);
            int authCode = ZKBrainNative.zkbrain_sec_init(licJson);
            if (authCode != 1024)
            {
                Console.WriteLine($"[致命错误] License 鉴权失败，错误代码: {authCode}");
                return;
            }
            Console.WriteLine("✅ License 授权成功 (Code: 1024)！核心算法引擎已解锁。");

            // 2. 创建解析器实例
            IntPtr parser = ZKBrainNative.zkbrain_parser_create();
            if (parser == IntPtr.Zero)
            {
                Console.WriteLine("[错误] 解析器实例化失败！");
                return;
            }

            // 3. 注册 1Hz 综合特征与 512Hz 原始波回调
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
                    Console.WriteLine($"🌟 [1Hz 特征] 专注度: {attention,3} | 放松度: {meditation,3} | 电量: {battery,2}% | 额温: {temp:F1}°C");
                    Console.WriteLine($"   频段能量: Delta={data[7]}, Theta={data[8]}, LowAlpha={data[9]}, HighAlpha={data[10]}, LowBeta={data[11]}");
                }
                else if (signal == 200)
                {
                    Console.WriteLine("🚨 [佩戴告警] 导联完全脱落未佩戴 (Signal=200)，请佩戴好额头电极与耳夹！");
                }
                else
                {
                    Console.WriteLine($"⚠️  [信号接触不良] 信号质量码: {signal} (ASIC算法进入保持模式)");
                }
                Console.WriteLine(new string('-', 60));
            };

            s_onRawWave = (raw, userData) =>
            {
                // 512Hz 原始微伏波形，可在 UI 示波器中批量绘制
            };

            ZKBrainNative.zkbrain_parser_set_callbacks(
                parser, 
                s_onBrainData, 
                s_onRawWave, 
                IntPtr.Zero, IntPtr.Zero, IntPtr.Zero, IntPtr.Zero
            );

            // 4. 启动 Windows 原生 BLE 自动扫描与连接
            var bleManager = new BleManager(data =>
            {
                // 物理层收到 BLE Notify 字节，直接喂给 SDK 解析
                ZKBrainNative.zkbrain_parser_parse(parser, data, data.Length);
            });

            try
            {
                // 自动扫描周围包含 brain, mind, eeg, tgam, zkt 关键字的设备并自动连接
                await bleManager.StartAutoScanAndConnectAsync(timeoutSeconds: 15);

                Console.WriteLine("\n按回车键 (Enter) 断开并退出程序...\n");
                Console.ReadLine();
            }
            finally
            {
                bleManager.Disconnect();
                ZKBrainNative.zkbrain_parser_destroy(parser);
                Console.WriteLine("✅ 程序已安全退出，资源已释放。");
            }
        }
    }
}
