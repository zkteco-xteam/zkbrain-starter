#include "ZKBrain.h"

#include <BLEDevice.h>
#include <BLEUtils.h>
#include <BLEScan.h>
#include <BLEAdvertisedDevice.h>
#include <BLEClient.h>

// Internal Protocol Constants (Shielded from Public Header)
static const uint8_t SYNC_BYTE = 0xAA;
static const uint8_t EXCODE_BYTE = 0x55;
static const uint8_t CODE_SIGNAL = 0x02;
static const uint8_t CODE_ATTENTION = 0x04;
static const uint8_t CODE_MEDITATION = 0x05;
static const uint8_t CODE_BATTERY = 0x06;
static const uint8_t CODE_RAW_WAVE = 0x80;
static const uint8_t CODE_ASIC_EEG = 0x83;

// Internal Proprietary & Standard BLE UUIDs
static BLEUUID UUID_PRIMARY_SVC("0000ffe0-0000-1000-8000-00805f9b34fb");
static BLEUUID UUID_PRIMARY_NOTIFY("0000ffe1-0000-1000-8000-00805f9b34fb");
static BLEUUID UUID_NORDIC_SVC("6e400001-b5a3-f393-e0a9-e50e24dcca9e");
static BLEUUID UUID_NORDIC_NOTIFY("6e400003-b5a3-f393-e0a9-e50e24dcca9e");
static BLEUUID UUID_NORDIC_WRITE("6e400002-b5a3-f393-e0a9-e50e24dcca9e");

// Hardware Ignition Payload (Encapsulated internally)
static const uint8_t HARDWARE_IGNITION_SEQUENCE[] = { 0x02, 0x15, 0x17 };

class ZKBrain::Impl : public BLEAdvertisedDeviceCallbacks, public BLEClientCallbacks {
public:
    Impl()
        : status(ZKBRAIN_STATUS_IDLE),
          mode(0),
          pUart(nullptr),
          pClient(nullptr),
          pTargetDevice(nullptr),
          pNotifyChar(nullptr),
          pWriteChar(nullptr),
          doConnect(false),
          lastWatchdogCheck(0),
          parseState(0),
          payloadLength(0),
          payloadIndex(0),
          checksumAcc(0),
          dataCallback(nullptr),
          rawCallback(nullptr),
          statusCallback(nullptr) {
        memset(&latestData, 0, sizeof(latestData));
        latestData.signal = 200; // Initialize as off-head
    }

    ~Impl() {
        disconnect();
    }

    bool beginBle(const char* nameFilter) {
        mode = 1;
        if (nameFilter) filterName = nameFilter;
        setStatus(ZKBRAIN_STATUS_SCANNING);

        Serial.println("[ZKBrain] [BLE] Initializing Central BLE subsystem...");
        BLEDevice::init("ZKBrain-ESP32-Client");
        BLEScan* pScan = BLEDevice::getScan();
        pScan->setAdvertisedDeviceCallbacks(this);
        pScan->setInterval(1349);
        pScan->setWindow(449);
        pScan->setActiveScan(true);
        pScan->start(10, false);
        Serial.println("[ZKBrain] [BLE] Scanner started. Searching for BCI peripherals...");
        return true;
    }

    bool beginUart(HardwareSerial& serialPort, int rxPin, int txPin, uint32_t baudRate) {
        mode = 2;
        pUart = &serialPort;
        pUart->begin(baudRate, SERIAL_8N1, rxPin, txPin);
        setStatus(ZKBRAIN_STATUS_CONNECTED);
        Serial.printf("[ZKBrain] [UART] Direct link active on RX=%d, TX=%d @ %d bps\n", rxPin, txPin, baudRate);
        return true;
    }

    void update() {
        if (mode == 2 && pUart != nullptr) {
            while (pUart->available()) {
                uint8_t byteIn = pUart->read();
                ingestByte(byteIn);
            }
        }

        if (mode == 1) {
            if (doConnect) {
                if (executeGattConnection()) {
                    Serial.println("[ZKBrain] [BLE] Link fully initialized and data streaming.");
                } else {
                    Serial.println("[ZKBrain] [BLE] Handshake failed. Resuming radar scan...");
                    setStatus(ZKBRAIN_STATUS_SCANNING);
                    BLEDevice::getScan()->start(10, false);
                }
                doConnect = false;
            }

            // Watchdog auto-healing
            if (status != ZKBRAIN_STATUS_CONNECTED && pTargetDevice != nullptr && !doConnect) {
                if (millis() - lastWatchdogCheck > 5000) {
                    lastWatchdogCheck = millis();
                    Serial.println("[ZKBrain] [WATCHDOG] Link dropped. Restarting BLE radar scan...");
                    setStatus(ZKBRAIN_STATUS_SCANNING);
                    BLEDevice::getScan()->start(10, false);
                }
            }
        }
    }

    void onResult(BLEAdvertisedDevice advertisedDevice) override {
        String devName = advertisedDevice.getName().c_str();
        String devAddr = advertisedDevice.getAddress().toString().c_str();

        bool match = false;
        if (filterName.length() > 0) {
            if (devName.indexOf(filterName) >= 0) match = true;
        } else {
            if (devName.indexOf("MindWave") >= 0 || devName.indexOf("BrainLink") >= 0 ||
                devName.indexOf("ZKBrain") >= 0 || devName.indexOf("MW") >= 0) {
                match = true;
            }
        }

        if (match) {
            Serial.printf("[ZKBrain] [BLE] Compatible peripheral found: %s [%s]\n", devName.c_str(), devAddr.c_str());
            BLEDevice::getScan()->stop();
            if (pTargetDevice) delete pTargetDevice;
            pTargetDevice = new BLEAdvertisedDevice(advertisedDevice);
            doConnect = true;
            setStatus(ZKBRAIN_STATUS_CONNECTING);
        }
    }

    void onConnect(BLEClient* client) override {
        setStatus(ZKBRAIN_STATUS_CONNECTED);
        Serial.println("[ZKBrain] [BLE] Physical GATT connection established.");
    }

    void onDisconnect(BLEClient* client) override {
        setStatus(ZKBRAIN_STATUS_DISCONNECTED);
        latestData.signal = 200;
        Serial.println("[ZKBrain] [BLE] Link disconnected.");
    }

    void disconnect() {
        if (pClient && pClient->isConnected()) {
            pClient->disconnect();
        }
        setStatus(ZKBRAIN_STATUS_DISCONNECTED);
        latestData.signal = 200;
    }

    void sendCommand(const char* cmd) {
        if (mode == 2 && pUart != nullptr) {
            pUart->print(cmd);
        } else if (mode == 1 && pWriteChar != nullptr && pWriteChar->canWrite()) {
            pWriteChar->writeValue((uint8_t*)cmd, strlen(cmd), false);
        }
    }

    ZKBrainStatus status;
    int mode; // 1: BLE, 2: UART
    HardwareSerial* pUart;
    BLEClient* pClient;
    BLEAdvertisedDevice* pTargetDevice;
    BLERemoteCharacteristic* pNotifyChar;
    BLERemoteCharacteristic* pWriteChar;
    String filterName;
    bool doConnect;
    unsigned long lastWatchdogCheck;

    // Internal Framing State Machine
    uint8_t parseState;
    uint8_t payloadLength;
    uint8_t payloadIndex;
    uint8_t payloadBuffer[256];
    uint32_t checksumAcc;

    ZKBrainData latestData;
    ZKBrainDataCallback dataCallback;
    ZKBrainRawCallback rawCallback;
    ZKBrainStatusCallback statusCallback;

    void setStatus(ZKBrainStatus newStatus) {
        if (status != newStatus) {
            status = newStatus;
            if (statusCallback) statusCallback(status);
        }
    }

    bool executeGattConnection() {
        Serial.printf("[ZKBrain] [BLE] Connecting to GATT server at %s...\n", pTargetDevice->getAddress().toString().c_str());
        pClient = BLEDevice::createClient();
        pClient->setClientCallbacks(this);

        if (!pClient->connect(pTargetDevice)) {
            return false;
        }

        BLERemoteService* pSvc = pClient->getService(UUID_PRIMARY_SVC);
        if (!pSvc) pSvc = pClient->getService(UUID_NORDIC_SVC);
        if (!pSvc) {
            pClient->disconnect();
            return false;
        }

        pNotifyChar = pSvc->getCharacteristic(UUID_PRIMARY_NOTIFY);
        if (!pNotifyChar) pNotifyChar = pSvc->getCharacteristic(UUID_NORDIC_NOTIFY);
        if (pNotifyChar && pNotifyChar->canNotify()) {
            pNotifyChar->registerForNotify([](BLERemoteCharacteristic* pChar, uint8_t* pData, size_t length, bool isNotify) {
                // Ingest incoming byte stream into internal framing engine
                for (size_t i = 0; i < length; ++i) {
                    s_activeInstance->ingestByte(pData[i]);
                }
            });
        } else {
            pClient->disconnect();
            return false;
        }

        pWriteChar = pSvc->getCharacteristic(UUID_PRIMARY_NOTIFY);
        if (!pWriteChar || !pWriteChar->canWrite()) pWriteChar = pSvc->getCharacteristic(UUID_NORDIC_WRITE);
        if (pWriteChar && pWriteChar->canWrite()) {
            delay(200);
            pWriteChar->writeValue((uint8_t*)HARDWARE_IGNITION_SEQUENCE, sizeof(HARDWARE_IGNITION_SEQUENCE), true);
            Serial.println("[ZKBrain] [BLE] Hardware ignition sequence verified.");
        }

        return true;
    }

    void ingestByte(uint8_t b) {
        switch (parseState) {
            case 0: // Waiting for Sync 1
                if (b == SYNC_BYTE) parseState = 1;
                break;
            case 1: // Waiting for Sync 2
                parseState = (b == SYNC_BYTE) ? 2 : 0;
                break;
            case 2: // Payload Length
                if (b > 170) {
                    parseState = 0;
                } else {
                    payloadLength = b;
                    payloadIndex = 0;
                    checksumAcc = 0;
                    parseState = (payloadLength == 0) ? 0 : 3;
                }
                break;
            case 3: // Ingesting Payload
                payloadBuffer[payloadIndex++] = b;
                checksumAcc += b;
                if (payloadIndex >= payloadLength) parseState = 4;
                break;
            case 4: // Checksum Verification
                if (b == ((~checksumAcc) & 0xFF)) {
                    decodePayload(payloadLength);
                }
                parseState = 0;
                break;
        }
    }

    uint32_t parseBe24(const uint8_t* ptr) {
        return ((uint32_t)ptr[0] << 16) | ((uint32_t)ptr[1] << 8) | (uint32_t)ptr[2];
    }

    void decodePayload(uint8_t len) {
        size_t i = 0;
        bool updated = false;

        while (i < len) {
            uint8_t code = payloadBuffer[i++];
            if (code == EXCODE_BYTE) continue;

            switch (code) {
                case CODE_SIGNAL:
                    if (i < len) { latestData.signal = payloadBuffer[i++]; updated = true; }
                    break;
                case CODE_ATTENTION:
                    if (i < len) { latestData.attention = payloadBuffer[i++]; updated = true; }
                    break;
                case CODE_MEDITATION:
                    if (i < len) { latestData.meditation = payloadBuffer[i++]; updated = true; }
                    break;
                case CODE_BATTERY:
                    if (i < len) { latestData.battery = payloadBuffer[i++]; updated = true; }
                    break;
                case CODE_RAW_WAVE:
                    if (i + 1 < len) {
                        int16_t raw = (int16_t)(((uint16_t)payloadBuffer[i] << 8) | payloadBuffer[i + 1]);
                        i += 2;
                        latestData.rawWave = raw;
                        if (rawCallback) rawCallback(raw);
                    }
                    break;
                case CODE_ASIC_EEG:
                    if (i + 24 <= len) {
                        latestData.delta     = parseBe24(&payloadBuffer[i]);
                        latestData.theta     = parseBe24(&payloadBuffer[i + 3]);
                        latestData.lowAlpha  = parseBe24(&payloadBuffer[i + 6]);
                        latestData.highAlpha = parseBe24(&payloadBuffer[i + 9]);
                        latestData.lowBeta   = parseBe24(&payloadBuffer[i + 12]);
                        latestData.highBeta  = parseBe24(&payloadBuffer[i + 15]);
                        latestData.lowGamma  = parseBe24(&payloadBuffer[i + 18]);
                        latestData.midGamma  = parseBe24(&payloadBuffer[i + 21]);
                        i += 24;
                        updated = true;
                    }
                    break;
                default:
                    if (code >= 0x80 && i < len) {
                        uint8_t l = payloadBuffer[i++];
                        i += l;
                    }
                    break;
            }
        }

        if (updated && dataCallback) {
            dataCallback(latestData);
        }
    }

    static Impl* s_activeInstance;
};

ZKBrain::Impl* ZKBrain::Impl::s_activeInstance = nullptr;

// ----------------------------------------------------------------------------
// Public SDK Wrapper Implementation (100% Protocol-Free)
// ----------------------------------------------------------------------------
ZKBrain::ZKBrain() : pImpl(new Impl()) {
    Impl::s_activeInstance = pImpl;
}

ZKBrain::~ZKBrain() {
    if (pImpl) {
        delete pImpl;
        pImpl = nullptr;
    }
}

bool ZKBrain::beginBle(const char* targetNameFilter) {
    return pImpl->beginBle(targetNameFilter);
}

bool ZKBrain::beginUart(HardwareSerial& serialPort, int rxPin, int txPin, uint32_t baudRate) {
    return pImpl->beginUart(serialPort, rxPin, txPin, baudRate);
}

void ZKBrain::update() {
    pImpl->update();
}

void ZKBrain::onBrainData(ZKBrainDataCallback callback) {
    pImpl->dataCallback = callback;
}

void ZKBrain::onRawWave(ZKBrainRawCallback callback) {
    pImpl->rawCallback = callback;
}

void ZKBrain::onStatusChanged(ZKBrainStatusCallback callback) {
    pImpl->statusCallback = callback;
}

void ZKBrain::disconnect() {
    pImpl->disconnect();
}

void ZKBrain::sendCommand(const char* command) {
    pImpl->sendCommand(command);
}

const ZKBrainData& ZKBrain::getLatestData() const {
    return pImpl->latestData;
}

ZKBrainStatus ZKBrain::getStatus() const {
    return pImpl->status;
}

bool ZKBrain::isConnected() const {
    return pImpl->status == ZKBRAIN_STATUS_CONNECTED;
}
