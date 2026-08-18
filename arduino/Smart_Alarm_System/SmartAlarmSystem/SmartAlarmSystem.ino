#include "arduino_secrets.h"
#include <BLEDevice.h>
#include "freertos/ringbuf.h"
#include "Config.h"
#include "Globals.h"
#include "SoundEngine.h"
#include "DisplayUI.h"
#include "CloudSync.h"
#include "DeviceMemory.h"   
#include "BluetoothSetup.h" 
#include <DHT.h>
#include "time.h"

// GLOBAL VARIABLES
// ==========================================
AlarmState currentAlarmState = IDLE;
float temperature = 0.0;
float humidity = 0.0;
String lightStatus = "NORMAL";
int lightValue = 0;
int motionDetected = 0;
String atlasStatus = "CONNECTED";
String alarmTime = "00:00"; 
int soundLevel = 5; 
int selectedTone = 1; 

String wifiSSID = "";
String wifiPass = "";
String userName = "";
bool isProvisioned = false;
bool isBleSetupMode = false;

bool isMenuMode = false; 
bool isStopped = false;      
bool wokeUpFlagPushed = false;
int buttonPressedLog = 0; 
char currentTimeStr[6]; 
char dateStr[12];       

unsigned long lastDHTRead = 0; 
unsigned long stateTimer = 0;

unsigned long btnPressTime = 0;
bool btnIsPressed = false;
bool longPressTriggered = false;
bool isPreviewing = false;

bool isResetPending = false;
unsigned long resetPendingStartTime = 0;
int resetConfirmPresses = 0;
int multiPressCount = 0;
unsigned long lastMultiPressTime = 0;

float smoothedLightValue = 0.0; 

// Relay Variables
bool isRelayActuallyOn = false;
bool isManualLampOn = false; 

DHT dht(DHTPIN, DHTTYPE);

// ==========================================
// SETUP ROUTINE
// ==========================================
void setup() {
  Serial.begin(115200);
  
  pinMode(BUTTON_PIN, INPUT_PULLUP); 
  pinMode(SPEAKER_PIN, OUTPUT);
  pinMode(PIR_PIN, INPUT); 
  
  // Standard OUTPUT to give the relay full power
  pinMode(RELAY_PIN, OUTPUT); 
  
  // Ensure Active-High relay starts completely OFF
  digitalWrite(RELAY_PIN, LOW); 
  isRelayActuallyOn = false;
  
  dht.begin();
  setupDisplay();

  drawBootScreen("Powering Up...");
  delay(500);

  smoothedLightValue = analogRead(LDR_PIN);

  setupMemory();

  if (!isProvisioned) {
    drawBootScreen("Starting Bluetooth");
    startBluetooth(); 
  } else {
    setupNetworkAndTime();
    drawBootScreen("System Ready!");
    delay(1000);
  }
}

// MAIN LOOP
// ==========================================
void loop() {
  unsigned long currentMillis = millis();

  if (isBleSetupMode) {
    handleBluetooth();
    drawBleSetupScreen();
    delay(100);
    return; 
  }

  handleWiFiHealer(currentMillis);

  struct tm timeinfo;
  if(getLocalTime(&timeinfo)) {
    strftime(currentTimeStr, sizeof(currentTimeStr), "%H:%M", &timeinfo);
    strftime(dateStr, sizeof(dateStr), "%d/%m/%Y", &timeinfo);
  }
  
  // 1. SENSOR READINGS
  motionDetected = digitalRead(PIR_PIN);

  int rawLight = analogRead(LDR_PIN);
  smoothedLightValue = (smoothedLightValue * 0.95) + (rawLight * 0.05);
  lightValue = (int)smoothedLightValue; 

  if (lightValue > 1000)
      lightStatus = "DARK";
  else if (lightValue > 700)
      lightStatus = "DIM";
  else if (lightValue > 400)
      lightStatus = "NORMAL";
  else
      lightStatus = "BRIGHT";

  if (currentMillis - lastDHTRead >= 2000) {
    lastDHTRead = currentMillis;
    float dynamicTemp = dht.readTemperature();
    float dynamicHumid = dht.readHumidity();
    if (!isnan(dynamicTemp)) temperature = dynamicTemp;
    if (!isnan(dynamicHumid)) humidity = dynamicHumid;
  }

  // 2. CLOUD SYNCING
  syncWithFirebase(currentMillis);
  if (currentAlarmState == IDLE) {
    syncWithAtlas(currentMillis);
  }


  // 4. BUTTON LOGIC
  int btnState = digitalRead(BUTTON_PIN);
  if (btnState == LOW) { 
    if (!btnIsPressed) {
      btnIsPressed = true;
      btnPressTime = currentMillis; 
      longPressTriggered = false;
    }

    unsigned long holdTime = currentMillis - btnPressTime;

    if (holdTime >= 5000 && !longPressTriggered && !isResetPending) {
      longPressTriggered = true;
      playTonePattern(0, 0, 0, true); 

      if (isMenuMode) {
        isMenuMode = false;
        isPreviewing = false; 
      } else {
        isMenuMode = true;
        isStopped = true; 
        currentAlarmState = IDLE;
        isPreviewing = true; // <-- THIS LINE MAKES IT PLAY INSTANTLY
      }
    }
  } 
  else { 
    if (btnIsPressed) {
      btnIsPressed = false;
      unsigned long pressDuration = currentMillis - btnPressTime;
      
      if (!longPressTriggered && pressDuration > 50) {
        if (currentMillis - lastMultiPressTime > 1000) multiPressCount = 0;
        multiPressCount++;
        lastMultiPressTime = currentMillis;

        if (isResetPending) {
          resetConfirmPresses++;
          if (resetConfirmPresses >= 2) {
            playTonePattern(0, 0, 0, true); 
            drawBootScreen("FACTORY RESET...");
            deleteDeviceNode(); // Placed here so it executes exactly when confirmed
            factoryReset();
            delay(2000);
            ESP.restart(); 
          }
        } 
        else {
          if (multiPressCount == 5) {
            isResetPending = true;
            resetPendingStartTime = currentMillis;
            resetConfirmPresses = 0;
            multiPressCount = 0; 
            playTonePattern(0, 0, 0, true); 
          } 
          else if (multiPressCount == 1) { 
            if (isMenuMode) {
              if (isPreviewing) {
                // STOP Preview if it is currently playing
                isPreviewing = false;
                playTonePattern(0, 0, 0, true);
                Serial.println("Sound Preview Stopped by Button");
              } else {
                // START Preview with next tone
                selectedTone++;
                if (selectedTone > 2) selectedTone = 0;
                isPreviewing = true;
                Serial.print("Sound Preview Started: Tone ");
                Serial.println(selectedTone);
              }
            } 
            else {
              // ALARM STOP LOGIC
              if (currentAlarmState == RINGING) {
                // Signal stop to both local and mobile via Firebase key
                stopAlarmInCloud();
                isStopped = true;
                currentAlarmState = IDLE;
                playTonePattern(0, 0, 0, true);

                if (String(currentTimeStr) == alarmTime) buttonPressedLog = 1; 
                Serial.println("Alarm Stopped by Physical Button");
              }
            }
          }
        }
      }
    }
  }

  // 5. RESET LOGIC (Timeout Warning)
  // This gives the screen 15 seconds to safely show the warning before cancelling.
  if (isResetPending && (currentMillis - resetPendingStartTime >= 15000)) {
    isResetPending = false;
    resetConfirmPresses = 0;
  }

  // 6. ALARM TIMING LOGIC
  if (isMenuMode) {
    if (isPreviewing) {
       playTonePattern(selectedTone, currentMillis, soundLevel, false); 
    } else {
       playTonePattern(0, 0, 0, true); 
    }
  } 
  else {
    // Check if the clock matches the target time to trigger the alarm
    if (String(currentTimeStr) == alarmTime && !isStopped && currentAlarmState == IDLE) {
      currentAlarmState = RINGING;
      stateTimer = currentMillis;
    }

    // Once ringing, rely on the 10-minute timer so it doesn't get cut off early
    if (currentAlarmState == RINGING) {
      playTonePattern(selectedTone, currentMillis, soundLevel, false);
      
      // Auto-stop after 10 minutes of continuous ringing to prevent burning out the buzzer
      if (currentMillis - stateTimer >= 600000) {
        isStopped = true;
        currentAlarmState = IDLE;
        playTonePattern(0, 0, 0, true); 
      }
    }

    // Reset the system flags for tomorrow once the alarm minute rolls over
    if (String(currentTimeStr) != alarmTime) {
      if (currentAlarmState == IDLE) {
        isStopped = false;
        wokeUpFlagPushed = false;
        buttonPressedLog = 0; 
      }
    }
  }

  // 7. UNIFIED RELAY CONTROLLER (Manual Only)
  // ==========================================
  if (isManualLampOn) {
    if (!isRelayActuallyOn) {
      digitalWrite(RELAY_PIN, HIGH); // Send HIGH to turn ON Active-High Relay
      isRelayActuallyOn = true;
      Serial.println("Relay: ON (Manual)");
    }
  } else {
    if (isRelayActuallyOn) {
      digitalWrite(RELAY_PIN, LOW); // Send LOW to turn OFF
      isRelayActuallyOn = false;
      Serial.println("Relay: OFF (Manual)");
    }
  }

  // 8. UPDATE SCREEN
  renderMainScreen();
  delay(10); 
}