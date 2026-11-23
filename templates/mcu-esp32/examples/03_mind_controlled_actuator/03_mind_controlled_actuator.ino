/**
 * ============================================================================
 * Example 03: Mind-Controlled Actuator & Haptic Feedback (ESP32 SDK)
 * Platform: ESP32 / ESP32-S3 / ESP32-C3
 * Maintainer: ZKTeco Brain-Computer Interface Division
 * Description: Mind-controlled physical actuation system built on ZKBrain SDK:
 *   - Attention >= 75: Triggers Relay / Servo (Mind-controlled lock / actuator)
 *   - Attention < 30 (with good contact): Triggers Distraction Buzzer Warning
 *   - PWM LED brightness mirrors real-time cognitive attention
 *   - Automatic safety interlock: Cuts off actuators if headband is off-head
 * ============================================================================
 */

#include <Arduino.h>
#include <ZKBrain.h>

#define PIN_LED_ATTENTION 2   // PWM LED
#define PIN_BUZZER_WARN   18  // Distraction Alarm Buzzer
#define PIN_RELAY_OUTPUT  19  // Mind-Triggered Relay / Actuator

static ZKBrain bci;

void handleActuators(const ZKBrainData& data) {
    // Safety check: If headband is detached or signal is noisy, cut off all actuators
    if (data.isOffHead()) {
        analogWrite(PIN_LED_ATTENTION, 0);
        digitalWrite(PIN_BUZZER_WARN, LOW);
        digitalWrite(PIN_RELAY_OUTPUT, LOW);
        Serial.println("[ESP32] [SAFETY] Headband off-head (Signal=200). Actuators disabled.");
        return;
    }

    // 1. Smooth PWM LED brightness mapped to mental attention
    uint8_t pwmVal = map(data.attention, 0, 100, 0, 255);
    analogWrite(PIN_LED_ATTENTION, pwmVal);

    // 2. High Attention Relay Trigger (e.g., Mind-controlled switch / motor)
    if (data.attention >= 75 && data.isGoodContact()) {
        digitalWrite(PIN_RELAY_OUTPUT, HIGH);
        Serial.printf("[ESP32] [ACTUATOR] Mind trigger ACTIVATED! Attention: %d >= 75\n", data.attention);
    } else {
        digitalWrite(PIN_RELAY_OUTPUT, LOW);
    }

    // 3. Low Attention / Fatigue Buzzer Alert
    if (data.attention > 0 && data.attention < 30 && data.isGoodContact()) {
        digitalWrite(PIN_BUZZER_WARN, HIGH);
        Serial.printf("[ESP32] [ALERT] Distraction warning! Attention: %d < 30\n", data.attention);
    } else {
        digitalWrite(PIN_BUZZER_WARN, LOW);
    }
}

void setup() {
    Serial.begin(115200);
    delay(500);

    Serial.println("\n[ESP32] [ACTUATOR] Initializing Mind-Controlled Actuator Controller...");
    pinMode(PIN_LED_ATTENTION, OUTPUT);
    pinMode(PIN_BUZZER_WARN, OUTPUT);
    pinMode(PIN_RELAY_OUTPUT, OUTPUT);

    digitalWrite(PIN_LED_ATTENTION, LOW);
    digitalWrite(PIN_BUZZER_WARN, LOW);
    digitalWrite(PIN_RELAY_OUTPUT, LOW);

    // 1. Register reactive listener
    bci.onBrainData([](const ZKBrainData& data) {
        handleActuators(data);
    });

    // 2. Start wireless BLE scanner
    bci.beginBle();

    Serial.println("[ESP32] [ACTUATOR] ZKBrain SDK listening for BCI headband...");
}

void loop() {
    // 3. Poll SDK tasks
    bci.update();
}
