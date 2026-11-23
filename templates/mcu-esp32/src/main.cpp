/**
 * ============================================================================
 * ZKBrain Embedded BCI Firmware for ESP32 / ESP32-S3 / ESP32-C3
 * Maintainer: ZKTeco Brain-Computer Interface Division
 * Description: Production-grade firmware powered by official ZKBrain Embedded SDK.
 *   - 100% black-box SDK abstraction (Zero protocol or ignition byte exposure)
 *   - Dual-mode support (Wireless BLE Central vs TGAM Hardware UART)
 *   - 0.96" I2C SSD1306 OLED cognitive dashboard
 *   - Physical actuators (PWM LED, Distraction Buzzer, Mind-Triggered Relay)
 *   - 100% pure English runtime serial telemetry
 * ============================================================================
 */

#include <Arduino.h>
#include <Wire.h>
#include <Adafruit_GFX.h>
#include <Adafruit_SSD1306.h>

#include "Config.h"
#include <ZKBrain.h>

// ----------------------------------------------------------------------------
// Global Instances & State
// ----------------------------------------------------------------------------
static ZKBrain bci;
static Adafruit_SSD1306 display(OLED_SCREEN_WIDTH, OLED_SCREEN_HEIGHT, &Wire, -1);
static bool hasOled = false;

// Cached BCI Telemetry Data
static ZKBrainData g_eeg;
static unsigned long lastTelemetryTime = 0;
static unsigned long lastDisplayTime = 0;

// ----------------------------------------------------------------------------
// OLED Display Renderer
// ----------------------------------------------------------------------------
void updateOledDisplay() {
    if (!hasOled) return;

    display.clearDisplay();
    display.setTextColor(SSD1306_WHITE);

    // Header: Mode & Status
    display.setTextSize(1);
    display.setCursor(0, 0);
    display.printf("ZKBrain SDK [%s]", MODE_BLE_CENTRAL ? "BLE" : "UART");

    display.setCursor(0, 10);
    if (g_eeg.isGoodContact()) {
        display.print("Signal: GOOD [0]");
    } else if (g_eeg.isOffHead()) {
        display.print("Signal: OFF-HEAD");
    } else {
        display.printf("Signal: NOISY [%d]", g_eeg.signal);
    }

    // Attention Bar
    display.setCursor(0, 22);
    display.printf("ATTN: %3d ", g_eeg.attention);
    display.drawRect(55, 22, 70, 7, SSD1306_WHITE);
    int attnBarW = map(g_eeg.attention, 0, 100, 0, 68);
    display.fillRect(56, 23, attnBarW, 5, SSD1306_WHITE);

    // Meditation Bar
    display.setCursor(0, 32);
    display.printf("MEDI: %3d ", g_eeg.meditation);
    display.drawRect(55, 32, 70, 7, SSD1306_WHITE);
    int mediBarW = map(g_eeg.meditation, 0, 100, 0, 68);
    display.fillRect(56, 33, mediBarW, 5, SSD1306_WHITE);

    // Dominant Rhythm & Flow State
    display.setCursor(0, 44);
    if (g_eeg.highAlpha > g_eeg.lowBeta && g_eeg.highAlpha > g_eeg.theta) {
        display.print("State: FLOW (Alpha)");
    } else if (g_eeg.highBeta > g_eeg.lowBeta) {
        display.print("State: ACTIVE FOCUS");
    } else if (g_eeg.theta > g_eeg.lowAlpha) {
        display.print("State: DROWSY (Theta)");
    } else {
        display.print("State: BALANCED");
    }

    // Bottom telemetry line: Relay & Battery
    display.setCursor(0, 54);
    display.printf("Relay:%s  Bat:%d%%", 
                   (digitalRead(PIN_RELAY_TRIGGER) == HIGH) ? "ON " : "OFF", 
                   g_eeg.battery > 0 ? g_eeg.battery : 100);

    display.display();
}

// ----------------------------------------------------------------------------
// Actuator Trigger Logic
// ----------------------------------------------------------------------------
void handleActuators(const ZKBrainData& data) {
    if (data.isOffHead()) {
        analogWrite(PIN_LED_ATTENTION, 0);
        digitalWrite(PIN_BUZZER_ALARM, LOW);
        digitalWrite(PIN_RELAY_TRIGGER, LOW);
        return;
    }

    // 1. Attention PWM LED (GPIO2)
    uint8_t pwmValue = map(data.attention, 0, 100, 0, 255);
    analogWrite(PIN_LED_ATTENTION, pwmValue);

    // 2. High Attention Relay Trigger (GPIO19)
    if (data.attention >= THRESHOLD_ATTENTION_HIGH && data.isGoodContact()) {
        digitalWrite(PIN_RELAY_TRIGGER, HIGH);
    } else {
        digitalWrite(PIN_RELAY_TRIGGER, LOW);
    }

    // 3. Low Attention Distraction Buzzer (GPIO18)
    if (data.attention > 0 && data.attention < THRESHOLD_ATTENTION_LOW && data.isGoodContact()) {
        digitalWrite(PIN_BUZZER_ALARM, HIGH);
    } else {
        digitalWrite(PIN_BUZZER_ALARM, LOW);
    }
}

// ----------------------------------------------------------------------------
// Setup & Loop
// ----------------------------------------------------------------------------
void setup() {
    Serial.begin(115200);
    delay(500);

    Serial.println("\n========================================================");
    Serial.println("  ZKBrain Embedded BCI Controller (SDK Powered)");
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

    // Initialize I2C OLED
    Wire.begin(PIN_OLED_SDA, PIN_OLED_SCL);
    if (display.begin(SSD1306_SWITCHCAPVCC, OLED_I2C_ADDR)) {
        hasOled = true;
        display.clearDisplay();
        display.setTextSize(1);
        display.setTextColor(SSD1306_WHITE);
        display.setCursor(15, 20);
        display.println("ZKBrain BCI SDK");
        display.setCursor(10, 35);
        display.println("Initializing link...");
        display.display();
        Serial.println("[ESP32] [HARDWARE] SSD1306 OLED initialized at 0x3C.");
    }

    // Register Reactive SDK Callbacks
    bci.onBrainData([](const ZKBrainData& data) {
        g_eeg = data;
        handleActuators(data);
    });

    bci.onStatusChanged([](ZKBrainStatus status) {
        switch (status) {
            case ZKBRAIN_STATUS_SCANNING:
                Serial.println("[ESP32] [SDK] Status -> SCANNING for BCI devices...");
                break;
            case ZKBRAIN_STATUS_CONNECTING:
                Serial.println("[ESP32] [SDK] Status -> CONNECTING to BCI device...");
                break;
            case ZKBRAIN_STATUS_CONNECTED:
                Serial.println("[ESP32] [SDK] Status -> CONNECTED. EEG data streaming.");
                break;
            case ZKBRAIN_STATUS_DISCONNECTED:
                Serial.println("[ESP32] [SDK] Status -> DISCONNECTED. Triggering auto-recovery...");
                break;
            default:
                break;
        }
    });

    // Initialize SDK with Selected Connection Mode
#if MODE_UART_DIRECT
    Serial.printf("[ESP32] [INIT] Starting SDK in Hardware UART Direct Mode (RX=%d, TX=%d)...\n",
                  PIN_TGAM_RX, PIN_TGAM_TX);
    bci.beginUart(Serial2, PIN_TGAM_RX, PIN_TGAM_TX, TGAM_BAUD_RATE);
#else
    Serial.println("[ESP32] [INIT] Starting SDK in Wireless BLE Central Mode...");
    bci.beginBle();
#endif

    Serial.println("[ESP32] [SYSTEM] Initialization complete. Entering main control loop.");
}

void loop() {
    // Poll SDK internal state and data ingestion
    bci.update();

    // Refresh OLED Display (10Hz)
    if (millis() - lastDisplayTime >= 100) {
        lastDisplayTime = millis();
        updateOledDisplay();
    }

    // Telemetry Serial Output (1Hz periodic log)
    if (millis() - lastTelemetryTime >= 1000) {
        lastTelemetryTime = millis();
        Serial.printf("[ESP32] [BCI] Signal: %3d (%s) | Attn: %3d | Medi: %3d | Bat: %2d%% | Actuator: %s\n",
                      g_eeg.signal,
                      g_eeg.isGoodContact() ? "GOOD" : (g_eeg.isOffHead() ? "OFF_HEAD" : "NOISY"),
                      g_eeg.attention,
                      g_eeg.meditation,
                      g_eeg.battery > 0 ? g_eeg.battery : 100,
                      (digitalRead(PIN_RELAY_TRIGGER) == HIGH) ? "ACTIVE" : "STANDBY");
    }

    delay(2);
}
