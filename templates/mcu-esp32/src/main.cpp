/**
 * ============================================================================
 * ZKBrain Embedded BCI Firmware for ESP32 / ESP32-S3 / ESP32-C3
 * Maintainer: ZKTeco Brain-Computer Interface Division
 * Description: Production-grade embedded BCI controller supporting:
 *   1. BLE Central wireless connection to BCI headbands
 *   2. Hardware Serial2 UART direct connection to TGAM ASIC chip
 *   3. 0.96" I2C SSD1306 OLED real-time cognitive metrics display
 *   4. Mind-controlled actuators (PWM LED, Buzzer, Servo / Relay triggers)
 *   5. 100% pure English runtime serial telemetry
 * ============================================================================
 */

#include <Arduino.h>
#include <Wire.h>
#include <Adafruit_GFX.h>
#include <Adafruit_SSD1306.h>

#include "Config.h"
#include "ZKBrainParser.h"

#if MODE_BLE_CENTRAL
#include <BLEDevice.h>
#include <BLEUtils.h>
#include <BLEScan.h>
#include <BLEAdvertisedDevice.h>
#include <BLEClient.h>
#endif

// ----------------------------------------------------------------------------
// Global Instances & State
// ----------------------------------------------------------------------------
static ZKBrainParser bciParser;
static Adafruit_SSD1306 display(OLED_SCREEN_WIDTH, OLED_SCREEN_HEIGHT, &Wire, -1);
static bool hasOled = false;

// Real-time cached BCI metrics
static volatile uint8_t g_signal = 200;
static volatile uint8_t g_attention = 0;
static volatile uint8_t g_meditation = 0;
static volatile uint8_t g_battery = 0;
static volatile uint32_t g_delta = 0;
static volatile uint32_t g_theta = 0;
static volatile uint32_t g_lowAlpha = 0;
static volatile uint32_t g_highAlpha = 0;
static volatile uint32_t g_lowBeta = 0;
static volatile uint32_t g_highBeta = 0;
static volatile uint32_t g_lowGamma = 0;
static volatile uint32_t g_midGamma = 0;

static unsigned long lastTelemetryTime = 0;
static unsigned long lastDisplayTime = 0;

#if MODE_BLE_CENTRAL
static BLEAdvertisedDevice* targetDevice = nullptr;
static BLEClient* pClient = nullptr;
static BLERemoteCharacteristic* pNotifyCharacteristic = nullptr;
static BLERemoteCharacteristic* pWriteCharacteristic = nullptr;
static bool isBleConnected = false;
static bool doConnect = false;

// Standard NeuroSky & ZKBrain UUID definitions
static BLEUUID SERVICE_UUID("0000ffe0-0000-1000-8000-00805f9b34fb");
static BLEUUID CHAR_NOTIFY_UUID("0000ffe1-0000-1000-8000-00805f9b34fb");
static BLEUUID SERVICE_UUID_FALLBACK("6e400001-b5a3-f393-e0a9-e50e24dcca9e"); // Nordic UART
static BLEUUID CHAR_NOTIFY_FALLBACK("6e400003-b5a3-f393-e0a9-e50e24dcca9e");
static BLEUUID CHAR_WRITE_FALLBACK("6e400002-b5a3-f393-e0a9-e50e24dcca9e");

// NeuroSky 20-byte ignition command (0x15 Raw ON + 0x17 Band ON)
static const uint8_t NEUROSKY_IGNITION_PKT[] = {
    0x02, 0x15, 0x17
};

class AdvertisedDeviceCallbacks : public BLEAdvertisedDeviceCallbacks {
    void onResult(BLEAdvertisedDevice advertisedDevice) override {
        String name = advertisedDevice.getName().c_str();
        String addr = advertisedDevice.getAddress().toString().c_str();
        
        Serial.printf("[ESP32] [BLE] Discovered device: %s [%s] RSSI: %d dBm\n", 
                      name.length() > 0 ? name.c_str() : "Unknown", 
                      addr.c_str(), 
                      advertisedDevice.getRSSI());

        // Check matching device names: MindWave, BrainLink, ZKBrain
        if (name.indexOf("MindWave") >= 0 || 
            name.indexOf("BrainLink") >= 0 || 
            name.indexOf("ZKBrain") >= 0 ||
            name.indexOf("MW") >= 0) {
            
            Serial.printf("[ESP32] [BLE] Target BCI peripheral found: %s. Initiating link...\n", name.c_str());
            BLEDevice::getScan()->stop();
            targetDevice = new BLEAdvertisedDevice(advertisedDevice);
            doConnect = true;
        }
    }
};

static void notifyCallback(BLERemoteCharacteristic* pBLERemoteCharacteristic,
                           uint8_t* pData, size_t length, bool isNotify) {
    bciParser.parseBuffer(pData, length);
}

class ClientCallback : public BLEClientCallbacks {
    void onConnect(BLEClient* pclient) override {
        isBleConnected = true;
        Serial.println("[ESP32] [BLE] GATT connection established successfully.");
    }

    void onDisconnect(BLEClient* pclient) override {
        isBleConnected = false;
        g_signal = 200; // Reset signal to off-head
        Serial.println("[ESP32] [BLE] Connection lost. Re-enabling scanner...");
    }
};

bool connectToBciServer() {
    Serial.printf("[ESP32] [BLE] Connecting to BCI server at %s...\n", targetDevice->getAddress().toString().c_str());

    pClient = BLEDevice::createClient();
    pClient->setClientCallbacks(new ClientCallback());

    if (!pClient->connect(targetDevice)) {
        Serial.println("[ESP32] [BLE] Failed to connect to physical link.");
        return false;
    }

    // Attempt primary service
    BLERemoteService* pRemoteService = pClient->getService(SERVICE_UUID);
    if (pRemoteService == nullptr) {
        Serial.println("[ESP32] [BLE] Primary service not found, trying Nordic UART fallback...");
        pRemoteService = pClient->getService(SERVICE_UUID_FALLBACK);
    }

    if (pRemoteService == nullptr) {
        Serial.println("[ESP32] [BLE] Failed to find compatible BCI service UUID.");
        pClient->disconnect();
        return false;
    }

    // Discover Notify Characteristic
    pNotifyCharacteristic = pRemoteService->getCharacteristic(CHAR_NOTIFY_UUID);
    if (pNotifyCharacteristic == nullptr) {
        pNotifyCharacteristic = pRemoteService->getCharacteristic(CHAR_NOTIFY_FALLBACK);
    }

    if (pNotifyCharacteristic != nullptr && pNotifyCharacteristic->canNotify()) {
        pNotifyCharacteristic->registerForNotify(notifyCallback);
        Serial.println("[ESP32] [BLE] Registered notification callback.");
    } else {
        Serial.println("[ESP32] [BLE] Characteristic does not support notify.");
        pClient->disconnect();
        return false;
    }

    // Discover Write Characteristic for ignition packet
    pWriteCharacteristic = pRemoteService->getCharacteristic(CHAR_NOTIFY_UUID);
    if (pWriteCharacteristic == nullptr || !pWriteCharacteristic->canWrite()) {
        pWriteCharacteristic = pRemoteService->getCharacteristic(CHAR_WRITE_FALLBACK);
    }

    // Dispatch ignition packet
    if (pWriteCharacteristic != nullptr && pWriteCharacteristic->canWrite()) {
        delay(200);
        pWriteCharacteristic->writeValue((uint8_t*)NEUROSKY_IGNITION_PKT, sizeof(NEUROSKY_IGNITION_PKT), true);
        Serial.println("[ESP32] [BLE] Dispatched NeuroSky ignition packet (0x15 Raw + 0x17 Band).");
    }

    return true;
}
#endif

// ----------------------------------------------------------------------------
// BCI Data Callbacks
// ----------------------------------------------------------------------------
void onBrainDataReceived(const MultiBrainEeg& data) {
    g_signal = data.signal;
    g_attention = data.attention;
    g_meditation = data.meditation;
    g_battery = data.battery;
    g_delta = data.delta;
    g_theta = data.theta;
    g_lowAlpha = data.lowAlpha;
    g_highAlpha = data.highAlpha;
    g_lowBeta = data.lowBeta;
    g_highBeta = data.highBeta;
    g_lowGamma = data.lowGamma;
    g_midGamma = data.midGamma;

    // Actuator Control Logic
    // 1. Attention PWM LED (GPIO2)
    uint8_t pwmValue = map(g_attention, 0, 100, 0, 255);
    analogWrite(PIN_LED_ATTENTION, pwmValue);

    // 2. High Attention Relay / Servo Trigger (GPIO19)
    if (g_attention >= THRESHOLD_ATTENTION_HIGH && g_signal == 0) {
        digitalWrite(PIN_RELAY_TRIGGER, HIGH);
    } else {
        digitalWrite(PIN_RELAY_TRIGGER, LOW);
    }

    // 3. Fatigue / Distraction Buzzer (GPIO18)
    if (g_attention > 0 && g_attention < THRESHOLD_ATTENTION_LOW && g_signal == 0) {
        digitalWrite(PIN_BUZZER_ALARM, HIGH);
    } else {
        digitalWrite(PIN_BUZZER_ALARM, LOW);
    }
}

// ----------------------------------------------------------------------------
// OLED Display Renderer
// ----------------------------------------------------------------------------
void updateOledDisplay() {
    if (!hasOled) return;

    display.clearDisplay();
    display.setTextColor(SSD1306_WHITE);

    // Header: Mode & Signal Status
    display.setTextSize(1);
    display.setCursor(0, 0);
    display.printf("ZKBrain MCU [%s]", MODE_BLE_CENTRAL ? "BLE" : "UART");

    display.setCursor(0, 10);
    if (g_signal == 0) {
        display.print("Signal: GOOD [0]");
    } else if (g_signal >= 200) {
        display.print("Signal: OFF-HEAD");
    } else {
        display.printf("Signal: NOISY [%d]", g_signal);
    }

    // Attention Bar
    display.setCursor(0, 22);
    display.printf("ATTN: %3d ", g_attention);
    display.drawRect(55, 22, 70, 7, SSD1306_WHITE);
    int attnBarW = map(g_attention, 0, 100, 0, 68);
    display.fillRect(56, 23, attnBarW, 5, SSD1306_WHITE);

    // Meditation Bar
    display.setCursor(0, 32);
    display.printf("MEDI: %3d ", g_meditation);
    display.drawRect(55, 32, 70, 7, SSD1306_WHITE);
    int mediBarW = map(g_meditation, 0, 100, 0, 68);
    display.fillRect(56, 33, mediBarW, 5, SSD1306_WHITE);

    // Dominant Band & Status
    display.setCursor(0, 44);
    if (g_highAlpha > g_lowBeta && g_highAlpha > g_theta) {
        display.print("State: FLOW (Alpha)");
    } else if (g_highBeta > g_lowBeta) {
        display.print("State: ACTIVE FOCUS");
    } else if (g_theta > g_lowAlpha) {
        display.print("State: DROWSY (Theta)");
    } else {
        display.print("State: BALANCED");
    }

    // Bottom telemetry line: Relay & Battery
    display.setCursor(0, 54);
    display.printf("Relay:%s  Bat:%d%%", 
                   (digitalRead(PIN_RELAY_TRIGGER) == HIGH) ? "ON " : "OFF", 
                   g_battery > 0 ? g_battery : 100);

    display.display();
}

// ----------------------------------------------------------------------------
// Arduino Setup & Loop
// ----------------------------------------------------------------------------
void setup() {
    Serial.begin(115200);
    delay(500);

    Serial.println("\n========================================================");
    Serial.println("  ZKBrain Embedded BCI Controller Firmware");
    Serial.println("  Platform: Espressif ESP32 / ESP32-S3 / ESP32-C3");
    Serial.println("  ZKTeco Brain-Computer Interface Division");
    Serial.println("========================================================\n");

    // Initialize Actuator & Indicator Pins
    pinMode(PIN_LED_ATTENTION, OUTPUT);
    pinMode(PIN_BUZZER_ALARM, OUTPUT);
    pinMode(PIN_RELAY_TRIGGER, OUTPUT);
    digitalWrite(PIN_LED_ATTENTION, LOW);
    digitalWrite(PIN_BUZZER_ALARM, LOW);
    digitalWrite(PIN_RELAY_TRIGGER, LOW);

    // Initialize I2C OLED Display
    Wire.begin(PIN_OLED_SDA, PIN_OLED_SCL);
    if (display.begin(SSD1306_SWITCHCAPVCC, OLED_I2C_ADDR)) {
        hasOled = true;
        display.clearDisplay();
        display.setTextSize(1);
        display.setTextColor(SSD1306_WHITE);
        display.setCursor(15, 20);
        display.println("ZKBrain BCI Node");
        display.setCursor(10, 35);
        display.println("Initializing link...");
        display.display();
        Serial.println("[ESP32] [HARDWARE] SSD1306 OLED initialized at 0x3C.");
    } else {
        Serial.println("[ESP32] [HARDWARE] SSD1306 OLED not found. Continuing headless.");
    }

    // Configure BCI Parser Callbacks
    bciParser.setBrainDataCallback(onBrainDataReceived);

#if MODE_UART_DIRECT
    // Mode 1: Direct TGAM ASIC Hardware UART Connection
    Serial.printf("[ESP32] [UART] Initializing Serial2 on RX=GPIO%d, TX=GPIO%d at %d baud...\n",
                  PIN_TGAM_RX, PIN_TGAM_TX, TGAM_BAUD_RATE);
    Serial2.begin(TGAM_BAUD_RATE, SERIAL_8N1, PIN_TGAM_RX, PIN_TGAM_TX);
    Serial.println("[ESP32] [UART] Serial2 direct link established.");
#endif

#if MODE_BLE_CENTRAL
    // Mode 2: Wireless BLE Central Client
    Serial.println("[ESP32] [BLE] Initializing BLE Central stack...");
    BLEDevice::init("ESP32-BCI-Host");
    BLEScan* pBLEScan = BLEDevice::getScan();
    pBLEScan->setAdvertisedDeviceCallbacks(new AdvertisedDeviceCallbacks());
    pBLEScan->setInterval(1349);
    pBLEScan->setWindow(449);
    pBLEScan->setActiveScan(true);
    pBLEScan->start(10, false);
    Serial.println("[ESP32] [BLE] Scanner active, listening for BCI headbands...");
#endif

    Serial.println("[ESP32] [SYSTEM] Initialization complete. Entering main control loop.");
}

void loop() {
#if MODE_UART_DIRECT
    // Ingest data from TGAM UART
    while (Serial2.available()) {
        uint8_t byteIn = Serial2.read();
        bciParser.parseByte(byteIn);
    }
#endif

#if MODE_BLE_CENTRAL
    // Handle deferred BLE connection
    if (doConnect) {
        if (connectToBciServer()) {
            Serial.println("[ESP32] [BLE] Connected and synchronized with BCI peripheral.");
        } else {
            Serial.println("[ESP32] [BLE] Connection failed. Resuming scan...");
            BLEDevice::getScan()->start(10, false);
        }
        doConnect = false;
    }

    // Auto-reconnect watchdog if disconnected
    if (!isBleConnected && targetDevice != nullptr && !doConnect) {
        static unsigned long lastRetry = 0;
        if (millis() - lastRetry > 5000) {
            lastRetry = millis();
            Serial.println("[ESP32] [WATCHDOG] Link dropped. Restarting BLE radar scan...");
            BLEDevice::getScan()->start(10, false);
        }
    }
#endif

    // Update OLED Display (10Hz refresh)
    if (millis() - lastDisplayTime >= 100) {
        lastDisplayTime = millis();
        updateOledDisplay();
    }

    // Telemetry Serial Output (1Hz periodic log)
    if (millis() - lastTelemetryTime >= 1000) {
        lastTelemetryTime = millis();
        Serial.printf("[ESP32] [BCI] Signal: %3d (%s) | Attn: %3d | Medi: %3d | Bat: %2d%% | Actuator: %s\n",
                      g_signal,
                      g_signal == 0 ? "GOOD" : (g_signal >= 200 ? "OFF_HEAD" : "NOISY"),
                      g_attention,
                      g_meditation,
                      g_battery > 0 ? g_battery : 100,
                      (digitalRead(PIN_RELAY_TRIGGER) == HIGH) ? "ACTIVE" : "STANDBY");
    }

    delay(2);
}
