const { app, BrowserWindow, ipcMain } = require('electron');
const path = require('path');

let mainWindow;

function createWindow() {
  mainWindow = new BrowserWindow({
    width: 1024,
    height: 860,
    title: "ZKBrain 脑机接口专业桌面工作站",
    backgroundColor: "#f1f5f9",
    webPreferences: {
      nodeIntegration: false,
      contextIsolation: true,
      preload: path.join(__dirname, 'preload.js')
    }
  });

  mainWindow.loadFile('index.html');

  // 🌟 启用 Electron 原生 Web Bluetooth 设备选择器与配对
  mainWindow.webContents.on('select-bluetooth-device', (event, deviceList, callback) => {
    event.preventDefault();
    if (deviceList && deviceList.length > 0) {
      // 优先选择包含 ZKBrain 或 MindWave 的设备
      const target = deviceList.find(d => 
        d.deviceName.includes('ZKBrain') || 
        d.deviceName.includes('MindWave') || 
        d.deviceName.includes('MW')
      ) || deviceList[0];
      callback(target.deviceId);
    } else {
      callback('');
    }
  });

  mainWindow.webContents.session.setBluetoothPairingHandler((details, callback) => {
    callback({ response: 'confirm' });
  });
}

app.whenReady().then(createWindow);

app.on('window-all-closed', () => {
  if (process.platform !== 'darwin') app.quit();
});
