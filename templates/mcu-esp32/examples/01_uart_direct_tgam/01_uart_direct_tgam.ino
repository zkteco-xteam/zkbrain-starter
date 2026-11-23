/**
 * ============================================================================
 * Example 01: TGAM ASIC Direct Hardware UART Connection (ESP32)
 * Platform: ESP32 / ESP32-S3 / ESP32-C3
 * Maintainer: ZKTeco Brain-Computer Interface Division
 * Description: Connects directly to the physical TX/RX pins of a TGAM EEG module.
 *   - Baud rate: 57600 bps
 *   - Pinout: TGAM TX -> ESP32 GPIO16 (RX2), TGAM RX -> ESP32 GPIO17 (TX2)
 *   - Power: 3.3V VCC and GND
 * ============================================================================
 */

#include <Arduino.h>

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

// Parser state
enum ParseState { STATE_SYNC_1, STATE_SYNC_2, STATE_LEN, STATE_PAYLOAD, STATE_CHECKSUM };
static ParseState parseState = STATE_SYNC_1;
static uint8_t pLen = 0, pIdx = 0, pBuf[256];
static uint32_t csumAcc = 0;

static uint8_t eegSignal = 200;
static uint8_t eegAttention = 0;
static uint8_t eegMeditation = 0;
static unsigned long lastLogTime = 0;

uint32_t readBe24(const uint8_t* p) {
    return ((uint32_t)p[0] << 16) | ((uint32_t)p[1] << 8) | (uint32_t)p[2];
}

void parsePayload(uint8_t len) {
    size_t i = 0;
    while (i < len) {
        uint8_t code = pBuf[i++];
        if (code == 0x55) continue;
        switch (code) {
            case 0x02: // Poor signal quality (0: Good, 200: Off-head)
                if (i < len) eegSignal = pBuf[i++];
                break;
            case 0x04: // eSense Attention (0 ~ 100)
                if (i < len) eegAttention = pBuf[i++];
                break;
            case 0x05: // eSense Meditation (0 ~ 100)
                if (i < len) eegMeditation = pBuf[i++];
                break;
            case 0x80: // Raw wave
                i += 2;
                break;
            case 0x83: // 8-Band power spectrum (24 bytes)
                i += 24;
                break;
            default:
                if (code >= 0x80 && i < len) {
                    uint8_t l = pBuf[i++];
                    i += l;
                }
                break;
        }
    }
}

void processByte(uint8_t b) {
    switch (parseState) {
        case STATE_SYNC_1:
            if (b == 0xAA) parseState = STATE_SYNC_2;
            break;
        case STATE_SYNC_2:
            parseState = (b == 0xAA) ? STATE_LEN : STATE_SYNC_1;
            break;
        case STATE_LEN:
            if (b > 170) {
                parseState = STATE_SYNC_1;
            } else {
                pLen = b; pIdx = 0; csumAcc = 0;
                parseState = (pLen == 0) ? STATE_SYNC_1 : STATE_PAYLOAD;
            }
            break;
        case STATE_PAYLOAD:
            pBuf[pIdx++] = b;
            csumAcc += b;
            if (pIdx >= pLen) parseState = STATE_CHECKSUM;
            break;
        case STATE_CHECKSUM: {
            uint8_t expected = (~csumAcc) & 0xFF;
            if (b == expected) parsePayload(pLen);
            parseState = STATE_SYNC_1;
            break;
        }
    }
}

void setup() {
    Serial.begin(115200);
    delay(500);

    Serial.println("\n[ESP32] [INIT] Starting TGAM ASIC Direct UART Reader...");
    Serial.printf("[ESP32] [UART] Initializing Serial2: RX=GPIO%d, TX=GPIO%d at %d bps\n",
                  PIN_TGAM_RX, PIN_TGAM_TX, TGAM_BAUD);
    
    Serial2.begin(TGAM_BAUD, SERIAL_8N1, PIN_TGAM_RX, PIN_TGAM_TX);
    Serial.println("[ESP32] [UART] Direct connection ready. Listening for hardware packets...");
}

void loop() {
    while (Serial2.available()) {
        uint8_t b = Serial2.read();
        processByte(b);
    }

    if (millis() - lastLogTime >= 1000) {
        lastLogTime = millis();
        Serial.printf("[ESP32] [BCI-UART] Signal: %3d [%s] | Attention: %3d | Meditation: %3d\n",
                      eegSignal,
                      eegSignal == 0 ? "GOOD" : (eegSignal >= 200 ? "OFF-HEAD" : "NOISY"),
                      eegAttention,
                      eegMeditation);
    }
}
