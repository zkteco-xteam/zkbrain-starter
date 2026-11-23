/**
 * ============================================================================
 * Example 02: BLE Central Wireless Connection to BCI Headband (ESP32)
 * Platform: ESP32 / ESP32-S3 / ESP32-C3
 * Maintainer: ZKTeco Brain-Computer Interface Division
 * Description: Scans wirelessly for BCI headbands, establishes GATT link,
 *   subscribes to Notify, sends NeuroSky ignition packet, and prints telemetry.
 * ============================================================================
 */

#include <Arduino.h>
#include <BLEDevice.h>
#include <BLEUtils.h>
#include <BLEScan.h>
#include <BLEAdvertisedDevice.h>
#include <BLEClient.h>

static BLEUUID SERVICE_UUID("0000ffe0-0000-1000-8000-00805f9b34fb");
static BLEUUID CHAR_NOTIFY_UUID("0000ffe1-0000-1000-8000-00805f9b34fb");
static BLEUUID SERVICE_NORDIC("6e400001-b5a3-f393-e0a9-e50e24dcca9e");
static BLEUUID CHAR_NORDIC_TX("6e400003-b5a3-f393-e0a9-e50e24dcca9e");
static BLEUUID CHAR_NORDIC_RX("6e400002-b5a3-f393-e0a9-e50e24dcca9e");

static BLEAdvertisedDevice* targetDevice = nullptr;
static BLEClient* pClient = nullptr;
static BLERemoteCharacteristic* pNotifyChar = nullptr;
static BLERemoteCharacteristic* pWriteChar = nullptr;
static bool doConnect = false;
static bool isConnected = false;

// NeuroSky ignition command (0x15 Raw ON + 0x17 Band ON)
static const uint8_t IGNITION_PKT[] = { 0x02, 0x15, 0x17 };

// Minimal packet parser
static uint8_t parseState = 0, pLen = 0, pIdx = 0, pBuf[256];
static uint32_t csum = 0;
static uint8_t bciSignal = 200, bciAttention = 0, bciMeditation = 0;

void parsePayload(uint8_t len) {
    size_t i = 0;
    while (i < len) {
        uint8_t code = pBuf[i++];
        if (code == 0x55) continue;
        switch (code) {
            case 0x02: if (i < len) bciSignal = pBuf[i++]; break;
            case 0x04: if (i < len) bciAttention = pBuf[i++]; break;
            case 0x05: if (i < len) bciMeditation = pBuf[i++]; break;
            case 0x80: i += 2; break;
            case 0x83: i += 24; break;
            default: if (code >= 0x80 && i < len) { uint8_t l = pBuf[i++]; i += l; } break;
        }
    }
}

void parseByte(uint8_t b) {
    switch (parseState) {
        case 0: if (b == 0xAA) parseState = 1; break;
        case 1: parseState = (b == 0xAA) ? 2 : 0; break;
        case 2:
            if (b > 170) { parseState = 0; }
            else { pLen = b; pIdx = 0; csum = 0; parseState = (pLen == 0) ? 0 : 3; }
            break;
        case 3:
            pBuf[pIdx++] = b; csum += b;
            if (pIdx >= pLen) parseState = 4;
            break;
        case 4:
            if (b == ((~csum) & 0xFF)) parsePayload(pLen);
            parseState = 0;
            break;
    }
}

static void notifyCallback(BLERemoteCharacteristic* pChar, uint8_t* pData, size_t length, bool isNotify) {
    for (size_t i = 0; i < length; ++i) parseByte(pData[i]);
}

class AdvertisedCallbacks : public BLEAdvertisedDeviceCallbacks {
    void onResult(BLEAdvertisedDevice dev) override {
        String name = dev.getName().c_str();
        if (name.indexOf("MindWave") >= 0 || name.indexOf("BrainLink") >= 0 || 
            name.indexOf("ZKBrain") >= 0 || name.indexOf("MW") >= 0) {
            Serial.printf("[ESP32] [BLE] Discovered target BCI: %s [%s]\n", name.c_str(), dev.getAddress().toString().c_str());
            BLEDevice::getScan()->stop();
            targetDevice = new BLEAdvertisedDevice(dev);
            doConnect = true;
        }
    }
};

bool connectToServer() {
    Serial.printf("[ESP32] [BLE] Connecting to %s...\n", targetDevice->getAddress().toString().c_str());
    pClient = BLEDevice::createClient();
    if (!pClient->connect(targetDevice)) return false;

    BLERemoteService* pSvc = pClient->getService(SERVICE_UUID);
    if (!pSvc) pSvc = pClient->getService(SERVICE_NORDIC);
    if (!pSvc) { pClient->disconnect(); return false; }

    pNotifyChar = pSvc->getCharacteristic(CHAR_NOTIFY_UUID);
    if (!pNotifyChar) pNotifyChar = pSvc->getCharacteristic(CHAR_NORDIC_TX);
    if (pNotifyChar && pNotifyChar->canNotify()) {
        pNotifyChar->registerForNotify(notifyCallback);
    } else {
        pClient->disconnect(); return false;
    }

    pWriteChar = pSvc->getCharacteristic(CHAR_NOTIFY_UUID);
    if (!pWriteChar || !pWriteChar->canWrite()) pWriteChar = pSvc->getCharacteristic(CHAR_NORDIC_RX);
    if (pWriteChar && pWriteChar->canWrite()) {
        delay(200);
        pWriteChar->writeValue((uint8_t*)IGNITION_PKT, sizeof(IGNITION_PKT), true);
        Serial.println("[ESP32] [BLE] Sent NeuroSky ignition packet (0x15 Raw + 0x17 Band).");
    }

    isConnected = true;
    return true;
}

void setup() {
    Serial.begin(115200);
    delay(500);
    Serial.println("\n[ESP32] [BLE] Initializing BLE Central Scanner for BCI Headbands...");
    BLEDevice::init("ESP32-BCI-Central");
    BLEScan* pScan = BLEDevice::getScan();
    pScan->setAdvertisedDeviceCallbacks(new AdvertisedCallbacks());
    pScan->setInterval(1349);
    pScan->setWindow(449);
    pScan->setActiveScan(true);
    pScan->start(15, false);
    Serial.println("[ESP32] [BLE] Scanner listening for nearby headbands...");
}

void loop() {
    if (doConnect) {
        if (connectToServer()) {
            Serial.println("[ESP32] [BLE] Connected and subscribed to BCI telemetry!");
        } else {
            Serial.println("[ESP32] [BLE] Connection failed. Retrying scan in 3 seconds...");
            delay(3000);
            BLEDevice::getScan()->start(10, false);
        }
        doConnect = false;
    }

    static unsigned long lastLog = 0;
    if (millis() - lastLog >= 1000) {
        lastLog = millis();
        if (isConnected) {
            Serial.printf("[ESP32] [BCI-BLE] Signal: %3d | Attention: %3d | Meditation: %3d\n",
                          bciSignal, bciAttention, bciMeditation);
        } else {
            Serial.println("[ESP32] [BLE] Waiting for BCI headband connection...");
        }
    }
    delay(10);
}
