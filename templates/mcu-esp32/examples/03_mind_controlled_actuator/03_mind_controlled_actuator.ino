/**
 * ============================================================================
 * Example 03: Mind-Controlled Actuator & Haptic Feedback (ESP32)
 * Platform: ESP32 / ESP32-S3 / ESP32-C3
 * Maintainer: ZKTeco Brain-Computer Interface Division
 * Description: Mind-controlled physical actuation system:
 *   - Attention >= 75: Triggers Relay / Servo (Mind-controlled lock / actuator)
 *   - Attention < 30 (with good contact): Triggers Distraction Buzzer Warning
 *   - PWM LED brightness mirrors real-time cognitive attention
 *   - Automatic safety interlock: Cuts off actuators if headband is off-head
 * ============================================================================
 */

#include <Arduino.h>

#define PIN_LED_ATTENTION 2   // PWM LED
#define PIN_BUZZER_WARN   18  // Distraction Alarm Buzzer
#define PIN_RELAY_OUTPUT  19  // Mind-Triggered Relay / Actuator

// Simulated or received EEG values
static uint8_t g_signal = 0;       // 0: Good contact, 200: Off-head
static uint8_t g_attention = 45;   // 0 ~ 100
static uint8_t g_meditation = 50;  // 0 ~ 100

void applyActuatorLogic(uint8_t signal, uint8_t attention, uint8_t meditation) {
    // Safety check: If headband is detached or signal is noisy, cut off all actuators
    if (signal >= 200) {
        analogWrite(PIN_LED_ATTENTION, 0);
        digitalWrite(PIN_BUZZER_WARN, LOW);
        digitalWrite(PIN_RELAY_OUTPUT, LOW);
        Serial.println("[ESP32] [SAFETY] Headband off-head (Signal=200). Actuators disabled.");
        return;
    }

    // 1. Smooth PWM LED brightness mapped to mental attention
    uint8_t pwmVal = map(attention, 0, 100, 0, 255);
    analogWrite(PIN_LED_ATTENTION, pwmVal);

    // 2. High Attention Relay Trigger (e.g., Mind-controlled switch / motor)
    if (attention >= 75) {
        digitalWrite(PIN_RELAY_OUTPUT, HIGH);
        Serial.printf("[ESP32] [ACTUATOR] Mind trigger ACTIVATED! Attention: %d >= 75\n", attention);
    } else {
        digitalWrite(PIN_RELAY_OUTPUT, LOW);
    }

    // 3. Low Attention / Fatigue Buzzer Alert
    if (attention > 0 && attention < 30) {
        digitalWrite(PIN_BUZZER_WARN, HIGH);
        Serial.printf("[ESP32] [ALERT] Distraction warning! Attention: %d < 30\n", attention);
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

    Serial.println("[ESP32] [ACTUATOR] Ready. Simulating cognitive state transitions...");
}

void loop() {
    // Demonstration loop: Simulates cognitive attention fluctuation
    static int phase = 0;
    static unsigned long lastTick = 0;

    if (millis() - lastTick >= 2000) {
        lastTick = millis();
        phase = (phase + 1) % 6;

        switch (phase) {
            case 0: g_signal = 0; g_attention = 25; break; // Distracted -> Buzzer
            case 1: g_signal = 0; g_attention = 50; break; // Normal
            case 2: g_signal = 0; g_attention = 82; break; // High Focus -> Relay ON
            case 3: g_signal = 0; g_attention = 95; break; // Peak Focus -> Relay ON
            case 4: g_signal = 0; g_attention = 60; break; // Relaxed Focus -> Relay OFF
            case 5: g_signal = 200; g_attention = 0; break; // Off-head -> Safety Cutoff
        }

        applyActuatorLogic(g_signal, g_attention, g_meditation);
    }
}
