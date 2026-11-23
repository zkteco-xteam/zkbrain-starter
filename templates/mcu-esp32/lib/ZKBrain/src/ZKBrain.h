#pragma once

/**
 * ============================================================================
 * ZKBrain Embedded BCI SDK for ESP32 / ESP32-S3 / ESP32-C3
 * Maintainer: ZKTeco Brain-Computer Interface Division
 * Description: Official high-level black-box BCI SDK. Encapsulates low-level
 *   binary packet framing, hardware ignition sequences, and GATT state machines.
 * ============================================================================
 */

#include <Arduino.h>
#include <functional>

/**
 * High-level BCI Telemetry Data Structure
 */
struct ZKBrainData {
    uint8_t signal;         // Signal contact quality (0: Good contact, 200: Off-head)
    uint8_t attention;      // Mental attention / focus index (0 ~ 100)
    uint8_t meditation;     // Mental meditation / calmness index (0 ~ 100)
    uint8_t battery;        // Battery level percentage (0 ~ 100)
    int16_t rawWave;        // Real-time raw microvolt sample point
    
    // 8-Band Power Spectrum
    uint32_t delta;         // 0.5 ~ 2.75Hz: Deep sleep
    uint32_t theta;         // 3.5 ~ 6.75Hz: Drowsiness, meditation
    uint32_t lowAlpha;      // 7.5 ~ 9.25Hz: Calm, relaxed
    uint32_t highAlpha;     // 10 ~ 11.75Hz: Flow state, eyes closed
    uint32_t lowBeta;       // 13 ~ 16.75Hz: Active thinking, alertness
    uint32_t highBeta;      // 17 ~ 29.75Hz: High focus, calculation
    uint32_t lowGamma;      // 31 ~ 39.75Hz: Cognitive processing
    uint32_t midGamma;      // 41 ~ 49.75Hz: Multi-sensory binding

    // Quality check helpers
    bool isGoodContact() const { return signal == 0; }
    bool isOffHead() const     { return signal >= 200; }
};

/**
 * Connection and Link State
 */
enum ZKBrainStatus {
    ZKBRAIN_STATUS_IDLE,
    ZKBRAIN_STATUS_SCANNING,
    ZKBRAIN_STATUS_CONNECTING,
    ZKBRAIN_STATUS_CONNECTED,
    ZKBRAIN_STATUS_DISCONNECTED
};

/**
 * Reactive Callback Signatures
 */
typedef std::function<void(const ZKBrainData& data)> ZKBrainDataCallback;
typedef std::function<void(int16_t rawValue)> ZKBrainRawCallback;
typedef std::function<void(ZKBrainStatus status)> ZKBrainStatusCallback;

/**
 * Official ZKBrain High-Level Controller Class
 */
class ZKBrain {
public:
    ZKBrain();
    ~ZKBrain();

    /**
     * Start BCI Client in Wireless BLE Central Mode
     * Automatically scans, bonds, sends hardware ignition, and begins streaming.
     * @param targetNameFilter Optional advertising name prefix filter (e.g., "MindWave", "ZKBrain")
     * @return true if BLE stack initialized successfully
     */
    bool beginBle(const char* targetNameFilter = nullptr);

    /**
     * Start BCI Client in Direct Hardware UART Mode
     * Reads directly from embedded ASIC pins (e.g. inside helmets or eye masks).
     * @param serialPort HardwareSerial reference (e.g. Serial2)
     * @param rxPin RX GPIO pin
     * @param txPin TX GPIO pin
     * @param baudRate Baud rate (default 57600)
     * @return true if serial port opened successfully
     */
    bool beginUart(HardwareSerial& serialPort, int rxPin, int txPin, uint32_t baudRate = 57600);

    /**
     * Periodic Task Poller
     * Must be called inside Arduino loop() to process data buffers and watchdog timers.
     */
    void update();

    /**
     * Register Reactive Event Listeners
     */
    void onBrainData(ZKBrainDataCallback callback);
    void onRawWave(ZKBrainRawCallback callback);
    void onStatusChanged(ZKBrainStatusCallback callback);

    /**
     * Disconnect current physical link and reset state
     */
    void disconnect();

    /**
     * Send High-Level ASCII Command to BCI device
     * @param command Command string (e.g., "mems_on:1;")
     */
    void sendCommand(const char* command);

    /**
     * Telemetry & Link Status Getters
     */
    const ZKBrainData& getLatestData() const;
    ZKBrainStatus getStatus() const;
    bool isConnected() const;

private:
    class Impl;
    Impl* pImpl; // Opaque Pointer: Completely isolates internal protocol & framing logic
};
