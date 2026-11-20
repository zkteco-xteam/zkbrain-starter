const { app, BrowserWindow, ipcMain } = require('electron');
const path = require('path');

let mainWindow;

function createWindow() {
  mainWindow = new BrowserWindow({
    width: 1024,
    height: 860,
    title: "ZKBrain Professional BCI Desktop Workstation",
    backgroundColor: "#f1f5f9",
    webPreferences: {
      nodeIntegration: false,
      contextIsolation: true,
      preload: path.join(__dirname, 'preload.js')
    }
  });

  mainWindow.loadFile('index.html');

  // Electron native Web Bluetooth device selection handler
  mainWindow.webContents.on('select-bluetooth-device', (event, deviceList, callback) => {
    event.preventDefault();
    if (deviceList && deviceList.length > 0) {
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
