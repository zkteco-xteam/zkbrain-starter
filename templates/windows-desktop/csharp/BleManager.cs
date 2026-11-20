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
    /// Native Windows 10/11 WinRT Bluetooth Low Energy (BLE) Scanner and Connection Manager.
    /// Uses native OS APIs without any external NuGet dependencies.
    /// </summary>
    public class BleManager
    {
        private BluetoothLEAdvertisementWatcher _watcher;
        private BluetoothLEDevice _currentDevice;
        private List<GattCharacteristic> _subscribedCharacteristics = new List<GattCharacteristic>();
        private GattCharacteristic _writeCharacteristic;
        private Action<byte[]> _onDataReceived;

        public bool IsConnected => _currentDevice != null && _currentDevice.ConnectionStatus == BluetoothConnectionStatus.Connected;
        public bool CanWrite => _writeCharacteristic != null;

        public BleManager(Action<byte[]> onDataReceived)
        {
            _onDataReceived = onDataReceived;
        }

        /// <summary>
        /// Auto-scans nearby BLE devices and establishes connection upon keyword match (e.g. MindWave, Brain, EEG, TGAM).
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

            Console.WriteLine("\n[BLE] Scanning for nearby BCI hardware via Windows native BLE advertisement...");

            _watcher.Received += (sender, args) =>
            {
                string localName = args.Advertisement.LocalName;
                if (!string.IsNullOrEmpty(localName))
                {
                    Console.WriteLine($"  Discovered device: {localName} (MAC: {args.BluetoothAddress:X}, RSSI: {args.RawSignalStrengthInDBm} dBm)");

                    foreach (var filter in nameFilters)
                    {
                        if (localName.IndexOf(filter, StringComparison.OrdinalIgnoreCase) >= 0)
                        {
                            Console.WriteLine($"\nMatched target BCI device keyword [{filter}] -> {localName}");
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
                Console.WriteLine("[BLE] Scan timeout. No matching device found within the specified duration.");
            }
        }

        /// <summary>
        /// Connects to specified Bluetooth address.
        /// </summary>
        public async Task<bool> ConnectToDeviceAsync(ulong bluetoothAddress)
        {
            Console.WriteLine($"[BLE] Connecting to device (Address: {bluetoothAddress:X}) ...");

            _currentDevice = await BluetoothLEDevice.FromBluetoothAddressAsync(bluetoothAddress);
            if (_currentDevice == null)
            {
                Console.WriteLine("[BLE] Connection failed: unable to acquire device object.");
                return false;
            }

            Console.WriteLine($"[BLE] Physical link established: {_currentDevice.Name}");

            // Enumerate GATT services
            var gattResult = await _currentDevice.GetGattServicesAsync(BluetoothCacheMode.Uncached);
            if (gattResult.Status != GattCommunicationStatus.Success)
            {
                Console.WriteLine($"[BLE] Failed to retrieve GATT services: {gattResult.Status}");
                return false;
            }

            // Find all characteristics with Notify permission
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
                        if (ch.CharacteristicProperties.HasFlag(GattCharacteristicProperties.Write) ||
                            ch.CharacteristicProperties.HasFlag(GattCharacteristicProperties.WriteWithoutResponse))
                        {
                            _writeCharacteristic = ch;
                            Console.WriteLine($"  Discovered command write channel: {ch.Uuid}");
                        }
                    }
                }
            }

            if (_subscribedCharacteristics.Count == 0)
            {
                Console.WriteLine("[BLE] No notify-capable characteristic channel found on device!");
                return false;
            }

            Console.WriteLine($"\nSuccessfully subscribed to {_subscribedCharacteristics.Count} EEG notify channels. Real-time demodulation active.");
            return true;
        }

        private async Task SubscribeCharacteristicAsync(GattCharacteristic ch)
        {
            try
            {
                // Write CCCD to enable notifications
                var status = await ch.WriteClientCharacteristicConfigurationDescriptorAsync(
                    GattClientCharacteristicConfigurationDescriptorValue.Notify);

                if (status == GattCommunicationStatus.Success)
                {
                    ch.ValueChanged += OnCharacteristicValueChanged;
                    _subscribedCharacteristics.Add(ch);
                    Console.WriteLine($"  -> Successfully subscribed to characteristic: {ch.Uuid}");
                }
            }
            catch (Exception ex)
            {
                Console.WriteLine($"  -> Failed to subscribe to characteristic {ch.Uuid}: {ex.Message}");
            }
        }

        private void OnCharacteristicValueChanged(GattCharacteristic sender, GattValueChangedEventArgs args)
        {
            var reader = DataReader.FromBuffer(args.CharacteristicValue);
            byte[] bytes = new byte[args.CharacteristicValue.Length];
            reader.ReadBytes(bytes);

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
            _writeCharacteristic = null;

            if (_currentDevice != null)
            {
                _currentDevice.Dispose();
                _currentDevice = null;
            }
            Console.WriteLine("[BLE] Bluetooth connection closed and resources released.");
        }

        /// <summary>
        /// Sends ASCII command to hardware (e.g. mems_on:1\n, eeg_data_rate:512\n)
        /// </summary>
        public async Task<bool> SendCommandAsync(string command)
        {
            if (_writeCharacteristic == null) return false;
            try
            {
                var writer = new DataWriter();
                writer.WriteString(command);
                var status = await _writeCharacteristic.WriteValueAsync(writer.DetachBuffer());
                return status == GattCommunicationStatus.Success;
            }
            catch (Exception ex)
            {
                Console.WriteLine($"[BLE] Command transmission failed: {ex.Message}");
                return false;
            }
        }

        /// <summary>
        /// Sends raw binary command packet (e.g. NeuroSky ignition packet new byte[] { 0x02, 0x15, 0x17 })
        /// </summary>
        public async Task<bool> SendBytesAsync(byte[] bytes)
        {
            if (_writeCharacteristic == null) return false;
            try
            {
                var writer = new DataWriter();
                writer.WriteBytes(bytes);
                var status = await _writeCharacteristic.WriteValueAsync(writer.DetachBuffer());
                return status == GattCommunicationStatus.Success;
            }
            catch (Exception ex)
            {
                Console.WriteLine($"[BLE] Binary packet transmission failed: {ex.Message}");
                return false;
            }
        }
    }
}
