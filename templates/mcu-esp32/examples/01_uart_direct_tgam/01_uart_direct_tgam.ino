/**
 * ============================================================================
 * Example 01: TGAM ASIC Direct Hardware UART Connection (ESP32 SDK)
 * Platform: ESP32 / ESP32-S3 / ESP32-C3
 * Maintainer: ZKTeco Brain-Computer Interface Division
 * Description: Connects directly to TGAM ASIC chip pins using official ZKBrain SDK.
 *   - Completely shields all low-level binary protocols and framing logic
 *   - Pinout: TGAM TX -> ESP32 GPIO16 (RX2), TGAM RX -> ESP32 GPIO17 (TX2)
 *   - Power: 3.3V VCC and GND
 * ============================================================================
 */

#include <Arduino.h>
#include <ZKBrain.h>

#if defined(CONFIG_IDF_TARGET_ESP32C3)
  #define PIN_TGAM_RX 4
  #define PIN_TGAM_TX 5
#elif defined(CONFIG_IDF_TARGET_ESP32S3)
  #define PIN_TGAM_RX 16
  #define PIN_TGAM_TX 17
#else
  #define PIN_TGAM_RX 16 // Classic ESP32 RX2
  #define PIN_TGAM_TX 17 // Classic ESP32 TX2
#endif

#define TGAM_BAUD 57600

static ZKBrain bci;
static unsigned long lastLogTime = 0;

void setup() {
    Serial.begin(115200);
    delay(500);

    Serial.println("\n[ESP32] [INIT] Starting TGAM Direct UART with ZKBrain SDK...");

    // 1. Register reactive data listener
    bci.onBrainData([](const ZKBrainData& data) {
        if (millis() - lastLogTime >= 1000) {
            lastLogTime = millis();
            Serial.printf("[ESP32] [BCI-UART] Signal: %3d [%s] | Attn: %3d | Medi: %3d | Bat: %d%%\n",
                          data.signal,
                          data.isGoodContact() ? "GOOD" : (data.isOffHead() ? "OFF-HEAD" : "NOISY"),
                          data.attention,
                          data.meditation,
                          data.battery > 0 ? data.battery : 100);
        }
    });

    // 2. Initialize SDK in Hardware UART Direct Mode
    bci.beginUart(Serial2, PIN_TGAM_RX, PIN_TGAM_TX, TGAM_BAUD);
    Serial.println("[ESP32] [UART] Direct connection ready. Streaming data...");
}

void loop() {
    // 3. Poll SDK tasks
    bci.update();
}
