#include "ZKBrainParser.h"

ZKBrainParser::ZKBrainParser()
    : state(STATE_SYNC_1),
      payloadLength(0),
      payloadIndex(0),
      checksumAcc(0),
      brainDataCallback(nullptr),
      rawWaveCallback(nullptr) {
    reset();
}

void ZKBrainParser::reset() {
    state = STATE_SYNC_1;
    payloadLength = 0;
    payloadIndex = 0;
    checksumAcc = 0;
    memset(&currentData, 0, sizeof(currentData));
    currentData.signal = 200; // Initialize as detached until proven otherwise
}

void ZKBrainParser::parseBuffer(const uint8_t* buffer, size_t length) {
    for (size_t i = 0; i < length; ++i) {
        parseByte(buffer[i]);
    }
}

void ZKBrainParser::parseByte(uint8_t b) {
    switch (state) {
        case STATE_SYNC_1:
            if (b == 0xAA) {
                state = STATE_SYNC_2;
            }
            break;

        case STATE_SYNC_2:
            if (b == 0xAA) {
                state = STATE_LENGTH;
            } else {
                state = STATE_SYNC_1;
            }
            break;

        case STATE_LENGTH:
            if (b > 170) {
                // Plausibility check: TGAM packets rarely exceed 170 bytes
                state = STATE_SYNC_1;
            } else {
                payloadLength = b;
                payloadIndex = 0;
                checksumAcc = 0;
                state = (payloadLength == 0) ? STATE_SYNC_1 : STATE_PAYLOAD;
            }
            break;

        case STATE_PAYLOAD:
            payload[payloadIndex++] = b;
            checksumAcc += b;
            if (payloadIndex >= payloadLength) {
                state = STATE_CHECKSUM;
            }
            break;

        case STATE_CHECKSUM: {
            uint8_t expectedChecksum = (~checksumAcc) & 0xFF;
            if (b == expectedChecksum) {
                processPayload();
            }
            state = STATE_SYNC_1;
            break;
        }
    }
}

uint32_t ZKBrainParser::readBigEndian24(const uint8_t* ptr) {
    return ((uint32_t)ptr[0] << 16) | ((uint32_t)ptr[1] << 8) | (uint32_t)ptr[2];
}

void ZKBrainParser::processPayload() {
    size_t i = 0;
    bool hasBrainDataUpdated = false;

    while (i < payloadLength) {
        uint8_t code = payload[i++];

        // Extended Code Level
        if (code == 0x55) {
            continue;
        }

        switch (code) {
            case 0x02: // Poor Signal Quality (0 ~ 200)
                if (i < payloadLength) {
                    currentData.signal = payload[i++];
                    hasBrainDataUpdated = true;
                }
                break;

            case 0x04: // eSense Attention (0 ~ 100)
                if (i < payloadLength) {
                    currentData.attention = payload[i++];
                    hasBrainDataUpdated = true;
                }
                break;

            case 0x05: // eSense Meditation (0 ~ 100)
                if (i < payloadLength) {
                    currentData.meditation = payload[i++];
                    hasBrainDataUpdated = true;
                }
                break;

            case 0x06: // 8-bit Raw Battery percentage
                if (i < payloadLength) {
                    currentData.battery = payload[i++];
                    hasBrainDataUpdated = true;
                }
                break;

            case 0x80: // Raw EEG Wave (2 bytes signed 16-bit)
                if (i + 1 < payloadLength) {
                    int16_t raw = (int16_t)(((uint16_t)payload[i] << 8) | payload[i + 1]);
                    i += 2;
                    currentData.rawWave = raw;
                    if (rawWaveCallback) {
                        rawWaveCallback(raw);
                    }
                }
                break;

            case 0x83: // ASIC 8-Band EEG Power Spectrum (24 bytes)
                if (i + 24 <= payloadLength) {
                    currentData.delta     = readBigEndian24(&payload[i]);
                    currentData.theta     = readBigEndian24(&payload[i + 3]);
                    currentData.lowAlpha  = readBigEndian24(&payload[i + 6]);
                    currentData.highAlpha = readBigEndian24(&payload[i + 9]);
                    currentData.lowBeta   = readBigEndian24(&payload[i + 12]);
                    currentData.highBeta  = readBigEndian24(&payload[i + 15]);
                    currentData.lowGamma  = readBigEndian24(&payload[i + 18]);
                    currentData.midGamma  = readBigEndian24(&payload[i + 21]);
                    i += 24;
                    hasBrainDataUpdated = true;
                }
                break;

            default:
                // Skip unhandled single-byte codes or multi-byte lengths
                if (code >= 0x80 && i < payloadLength) {
                    uint8_t length = payload[i++];
                    i += length;
                }
                break;
        }
    }

    if (hasBrainDataUpdated && brainDataCallback) {
        brainDataCallback(currentData);
    }
}
