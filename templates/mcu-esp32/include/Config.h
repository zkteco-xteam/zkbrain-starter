#pragma once

/**
 * ============================================================================
 * ZKBrain Embedded BCI Hardware Configuration
 * Hardware Platform: Espressif ESP32 / ESP32-S3 / ESP32-C3
 * Maintainer: ZKTeco Brain-Computer Interface Division
 * ============================================================================
 */

#include <Arduino.h>

// ----------------------------------------------------------------------------
// Operation Mode Selection
// ----------------------------------------------------------------------------
// Set MODE_BLE_CENTRAL to 1 to connect wirelessly to ZKBrain / NeuroSky headband
// Set MODE_UART_DIRECT to 1 to read directly from TGAM module pins (Serial2)
#define MODE_BLE_CENTRAL    1
#define MODE_UART_DIRECT    0

// ----------------------------------------------------------------------------
// Hardware Serial Pins (For TGAM / Direct ASIC Connection)
// ----------------------------------------------------------------------------
#if defined(CONFIG_IDF_TARGET_ESP32C3)
  #define PIN_TGAM_RX       4   // ESP32-C3 RX
  #define PIN_TGAM_TX       5   // ESP32-C3 TX
#elif defined(CONFIG_IDF_TARGET_ESP32S3)
  #define PIN_TGAM_RX       16  // ESP32-S3 RX
  #define PIN_TGAM_TX       17  // ESP32-S3 TX
#else
  #define PIN_TGAM_RX       16  // Classic ESP32 GPIO16 (RX2)
  #define PIN_TGAM_TX       17  // Classic ESP32 GPIO17 (TX2)
#endif

#define TGAM_BAUD_RATE      57600

// ----------------------------------------------------------------------------
// I2C OLED Display Pins (0.96" SSD1306 128x64)
// ----------------------------------------------------------------------------
#if defined(CONFIG_IDF_TARGET_ESP32C3)
  #define PIN_OLED_SDA      8
  #define PIN_OLED_SCL      9
#else
  #define PIN_OLED_SDA      21
  #define PIN_OLED_SCL      22
#endif

#define OLED_I2C_ADDR       0x3C
#define OLED_SCREEN_WIDTH   128
#define OLED_SCREEN_HEIGHT  64

// ----------------------------------------------------------------------------
// Physical Actuator & Indicator Pins
// ----------------------------------------------------------------------------
#define PIN_LED_ATTENTION   2   // On-board LED / Green LED: Brightness reflects Attention
#define PIN_BUZZER_ALARM    18  // Active Buzzer: Sounds on high fatigue or severe distraction
#define PIN_RELAY_TRIGGER   19  // Relay or Servo control signal pin

// ----------------------------------------------------------------------------
// BCI Cognitive Thresholds
// ----------------------------------------------------------------------------
#define THRESHOLD_ATTENTION_HIGH    75  // Trigger mind-controlled action when Attention >= 75
#define THRESHOLD_ATTENTION_LOW     30  // Trigger distraction warning when Attention < 30
#define THRESHOLD_FATIGUE_ALARM     70  // Trigger buzzer alarm when Fatigue Index >= 70
#define THRESHOLD_SIGNAL_DETACHED   200 // Off-head detached code
