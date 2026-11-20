using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using Windows.Devices.Bluetooth;
using Windows.Devices.Bluetooth.Advertisement;
using Windows.Devices.Bluetooth.GenericAttributeProfile;
using Windows.Storage.Streams;

namespace ZKBrain.Windows.Demo
{
    /// <summary>
    /// 基于 Windows 10/11 原生 WinRT 协议栈的低功耗蓝牙 (BLE) 扫描与连接管理器
    /// 无需任何第三方驱动或外部 NuGet 包，直接利用 Windows 系统原生能力
    /// </summary>
    public class BleManager
    {
        private BluetoothLEAdvertisementWatcher _watcher;
        private BluetoothLEDevice _currentDevice;
        private List<GattCharacteristic> _subscribedCharacteristics = new List<GattCharacteristic>();
        private Action<byte[]> _onDataReceived;

        public bool IsConnected => _currentDevice != null && _currentDevice.ConnectionStatus == BluetoothConnectionStatus.Connected;

        public BleManager(Action<byte[]> onDataReceived)
        {
            _onDataReceived = onDataReceived;
        }

        /// <summary>
        /// 自动扫描周围设备，并在匹配到关键字 (如 MindWave, Brain, EEG, TGAM) 时自动建立连接
        /// </summary>
        public async Task StartAutoScanAndConnectAsync(string[] nameFilters = null, int timeoutSeconds = 10)
        {
            if (nameFilters == null || nameFilters.Length == 0)
            {
                nameFilters = new[] { "brain", "mind", "eeg", "tgam", "zkt" };
            }

            var tcs = new TaskCompletionSource<ulong>();

            _watcher = new BluetoothLEAdvertisementWatcher
            {
                ScanningMode = BluetoothLEScanningMode.Active
            };

            Console.WriteLine("\n[BLE] 正在通过 Windows 原生蓝牙广播扫描周围脑电硬件...");

            _watcher.Received += (sender, args) =>
            {
                string localName = args.Advertisement.LocalName;
                if (!string.IsNullOrEmpty(localName))
                {
                    Console.WriteLine($"  发现广播设备: {localName} (MAC: {args.BluetoothAddress:X}, RSSI: {args.RawSignalStrengthInDBm} dBm)");

                    foreach (var filter in nameFilters)
                    {
                        if (localName.IndexOf(filter, StringComparison.OrdinalIgnoreCase) >= 0)
                        {
                            Console.WriteLine($"\n🎯 命中目标脑电设备关键字 [{filter}] -> {localName}");
                            _watcher.Stop();
                            tcs.TrySetResult(args.BluetoothAddress);
                            break;
                        }
                    }
                }
            };

            _watcher.Start();

            var timeoutTask = Task.Delay(TimeSpan.FromSeconds(timeoutSeconds));
            var completedTask = await Task.WhenAny(tcs.Task, timeoutTask);

            _watcher.Stop();

            if (completedTask == tcs.Task)
            {
                ulong targetAddress = await tcs.Task;
                await ConnectToDeviceAsync(targetAddress);
            }
            else
            {
                Console.WriteLine("[BLE] 扫描超时，未在指定时间内发现目标设备。");
            }
        }

        /// <summary>
        /// 连接到指定的蓝牙硬件地址
        /// </summary>
        public async Task<bool> ConnectToDeviceAsync(ulong bluetoothAddress)
        {
            Console.WriteLine($"[BLE] 正在连接设备 (地址: {bluetoothAddress:X}) ...");

            _currentDevice = await BluetoothLEDevice.FromBluetoothAddressAsync(bluetoothAddress);
            if (_currentDevice == null)
            {
                Console.WriteLine("[BLE] 连接建立失败 (无法获取设备对象)。");
                return false;
            }

            Console.WriteLine($"[BLE] 物理链路已连通: {_currentDevice.Name}");

            // 枚举 GATT 服务
            var gattResult = await _currentDevice.GetGattServicesAsync(BluetoothCacheMode.Uncached);
            if (gattResult.Status != GattCommunicationStatus.Success)
            {
                Console.WriteLine($"[BLE] 检索 GATT 服务失败: {gattResult.Status}");
                return false;
            }

            // 查找所有具备 Notify 权限的特征值
            foreach (var service in gattResult.Services)
            {
                var charResult = await service.GetCharacteristicsAsync(BluetoothCacheMode.Uncached);
                if (charResult.Status == GattCommunicationStatus.Success)
                {
                    foreach (var ch in charResult.Characteristics)
                    {
                        if (ch.CharacteristicProperties.HasFlag(GattCharacteristicProperties.Notify))
                        {
                            await SubscribeCharacteristicAsync(ch);
                        }
                    }
                }
            }

            if (_subscribedCharacteristics.Count == 0)
            {
                Console.WriteLine("[BLE] 未在设备上找到支持 Notify 的数据通道！");
                return false;
            }

            Console.WriteLine($"\n🚀 成功订阅 {_subscribedCharacteristics.Count} 个脑电特征值通道！正在实时解调...");
            return true;
        }

        private async Task SubscribeCharacteristicAsync(GattCharacteristic ch)
        {
            try
            {
                // 写入客户端特征值配置描述符 (CCCD) 开启通知
                var status = await ch.WriteClientCharacteristicConfigurationDescriptorAsync(
                    GattClientCharacteristicConfigurationDescriptorValue.Notify);

                if (status == GattCommunicationStatus.Success)
                {
                    ch.ValueChanged += OnCharacteristicValueChanged;
                    _subscribedCharacteristics.Add(ch);
                    Console.WriteLine($"  -> 成功监听特征值: {ch.Uuid}");
                }
            }
            catch (Exception ex)
            {
                Console.WriteLine($"  -> 监听特征值 {ch.Uuid} 失败: {ex.Message}");
            }
        }

        private void OnCharacteristicValueChanged(GattCharacteristic sender, GattValueChangedEventArgs args)
        {
            // 从 IBuffer 提取原始字节流
            var reader = DataReader.FromBuffer(args.CharacteristicValue);
            byte[] bytes = new byte[args.CharacteristicValue.Length];
            reader.ReadBytes(bytes);

            // 触发数据回调，直接送入 ZKBrain 解析器
            _onDataReceived?.Invoke(bytes);
        }

        public void Disconnect()
        {
            foreach (var ch in _subscribedCharacteristics)
            {
                try
                {
                    ch.ValueChanged -= OnCharacteristicValueChanged;
                }
                catch { }
            }
            _subscribedCharacteristics.Clear();

            if (_currentDevice != null)
            {
                _currentDevice.Dispose();
                _currentDevice = null;
            }
            Console.WriteLine("[BLE] 蓝牙连接已断开并释放资源。");
        }
    }
}
