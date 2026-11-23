/**
 * ============================================================================
 * Example 02: BLE Central Wireless Connection to BCI Headband (ESP32 SDK)
 * Platform: ESP32 / ESP32-S3 / ESP32-C3
 * Maintainer: ZKTeco Brain-Computer Interface Division
 * Description: Scans wirelessly for BCI headbands using official ZKBrain SDK.
 *   - Auto-discovers, establishes GATT connection, sends ignition, and streams EEG
 *   - 100% black-box SDK abstraction (No raw BLE UUIDs or ignition bytes needed)
 * ============================================================================
 */

#include <Arduino.h>
#include <ZKBrain.h>

static ZKBrain bci;
static unsigned long lastLog = 0;

void setup() {
    Serial.begin(115200);
    delay(500);

    Serial.println("\n[ESP32] [INIT] Starting BLE Central Scanner with ZKBrain SDK...");

    // 1. Register reactive data and status listeners
    bci.onBrainData([](const ZKBrainData& data) {
        if (millis() - lastLog >= 1000) {
            lastLog = millis();
            Serial.printf("[ESP32] [BCI-BLE] Signal: %3d [%s] | Attention: %3d | Meditation: %3d\n",
                          data.signal,
                          data.isGoodContact() ? "GOOD" : (data.isOffHead() ? "OFF-HEAD" : "NOISY"),
                          data.attention,
                          data.meditation);
        }
    });

    bci.onStatusChanged([](ZKBrainStatus status) {
        switch (status) {
            case ZKBRAIN_STATUS_SCANNING:
                Serial.println("[ESP32] [SDK] Scanning for nearby BCI headbands...");
                break;
            case ZKBRAIN_STATUS_CONNECTING:
                Serial.println("[ESP32] [SDK] Found compatible BCI device. Handshaking...");
                break;
            case ZKBRAIN_STATUS_CONNECTED:
                Serial.println("[ESP32] [SDK] Connected successfully. Hardware ignition active.");
                break;
            case ZKBRAIN_STATUS_DISCONNECTED:
                Serial.println("[ESP32] [SDK] Disconnected. Resuming automatic scan...");
                break;
            default:
                break;
        }
    });

    // 2. Start SDK in Wireless BLE Central Mode
    bci.beginBle();
}

void loop() {
    // 3. Poll SDK tasks and data ingestion
    bci.update();
}
