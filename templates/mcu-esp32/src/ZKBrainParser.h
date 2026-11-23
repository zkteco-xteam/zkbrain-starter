#pragma once

#include <Arduino.h>

/**
 * ============================================================================
 * ZKBrain Embedded Protocol Parser
 * Supports TGAM ASIC, NeuroSky ThinkGear, and ZKBrain binary packet streams
 * Optimized for resource-constrained microcontrollers (Zero dynamic allocation)
 * ============================================================================
 */

struct MultiBrainEeg {
    uint8_t signal;         // Signal contact quality (0: Good contact, 200: Off-head)
    uint8_t attention;      // Attention / Mental Focus index (0 ~ 100)
    uint8_t meditation;     // Meditation / Mental Calmness index (0 ~ 100)
    uint8_t battery;        // Battery level percentage (0 ~ 100)
    int16_t rawWave;        // 512Hz Raw microvolt sample
    
    // 8-Band Power Spectrum
    uint32_t delta;         // 0.5 ~ 2.75Hz: Deep sleep
    uint32_t theta;         // 3.5 ~ 6.75Hz: Daydream, drowsiness
    uint32_t lowAlpha;      // 7.5 ~ 9.25Hz: Calm, relaxed
    uint32_t highAlpha;     // 10 ~ 11.75Hz: Flow state, eyes closed
    uint32_t lowBeta;       // 13 ~ 16.75Hz: Active thinking, alertness
    uint32_t highBeta;      // 17 ~ 29.75Hz: High focus, calculation
    uint32_t lowGamma;      // 31 ~ 39.75Hz: Cognitive processing
    uint32_t midGamma;      // 41 ~ 49.75Hz: Multi-sensory binding
};

typedef void (*BrainDataCallback)(const MultiBrainEeg& data);
typedef void (*RawWaveCallback)(int16_t rawValue);

class ZKBrainParser {
public:
    ZKBrainParser();
    
    void reset();
    void parseByte(uint8_t byte);
    void parseBuffer(const uint8_t* buffer, size_t length);

    void setBrainDataCallback(BrainDataCallback cb) { brainDataCallback = cb; }
    void setRawWaveCallback(RawWaveCallback cb)     { rawWaveCallback = cb; }

    const MultiBrainEeg& getLatestData() const { return currentData; }

private:
    enum ParserState {
        STATE_SYNC_1,
        STATE_SYNC_2,
        STATE_LENGTH,
        STATE_PAYLOAD,
        STATE_CHECKSUM
    };

    ParserState state;
    uint8_t payloadLength;
    uint8_t payloadIndex;
    uint8_t payload[256];
    uint32_t checksumAcc;

    MultiBrainEeg currentData;
    BrainDataCallback brainDataCallback;
    RawWaveCallback rawWaveCallback;

    void processPayload();
    uint32_t readBigEndian24(const uint8_t* ptr);
};
