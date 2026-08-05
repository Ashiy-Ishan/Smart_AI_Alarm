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

AlarmState currentAlarmState = IDLE;
float temperature = 0.0;
float humidity = 0.0;
String lightStatus = "NORMAL";
int lightValue = 0;
int motionDetected = 0;
String atlasStatus = "CONNECTED";
String alarmTime = "00:00"; 
int soundLevel = 5; 
int selectedTone = 0; 

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
unsigned long previewEndTime = 0;
bool isPreviewing = false;

bool isResetPending = false;
unsigned long resetPendingStartTime = 0;
int resetConfirmPresses = 0;
int multiPressCount = 0;
unsigned long lastMultiPressTime = 0;

bool isCloudResetPending = false;
unsigned long cloudResetStartTime = 0;
bool pushResetCancelToCloud = false;

bool hardwareResetTriggered = false; // NEW 10s RESET FLAG

float smoothedLightValue = 0.0; 

bool isAlarmEnabled = true;     
bool isRelayEnabled = false;     
bool isRelayActuallyOn = false; 
unsigned long lampTurnedOnTime = 0;
bool isLampOnByAlarm = false;

int lastKnownSoundLevel = -1; 
int lastKnownTone = -1;
bool isCloudPreviewing = false;
unsigned long cloudPreviewEndTime = 0;

DHT dht(DHTPIN, DHTTYPE);

void setup() {
  Serial.begin(115200);
  
  pinMode(BUTTON_PIN, INPUT_PULLUP); 
  pinMode(SPEAKER_PIN, OUTPUT);
  pinMode(PIR_PIN, INPUT); 
  pinMode(RELAY_PIN, OUTPUT); 
  
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
  
  motionDetected = digitalRead(PIR_PIN);

  int rawLight = analogRead(LDR_PIN);
  smoothedLightValue = (smoothedLightValue * 0.95) + (rawLight * 0.05);
  lightValue = (int)smoothedLightValue; 

  if (lightValue > 120) lightStatus = "DARK";
  else if (lightValue > 70) lightStatus = "DIM";
  else if (lightValue > 40) lightStatus = "NORMAL";
  else lightStatus = "BRIGHT";

  if (currentMillis - lastDHTRead >= 2000) {
    lastDHTRead = currentMillis;
    float dynamicTemp = dht.readTemperature();
    float dynamicHumid = dht.readHumidity();
    if (!isnan(dynamicTemp)) temperature = dynamicTemp;
    if (!isnan(dynamicHumid)) humidity = dynamicHumid;
  }

  if (!isMenuMode) {
    syncWithFirebase(currentMillis);
    syncWithAtlas(currentMillis);
  }

  if (!isMenuMode && currentAlarmState == IDLE) { 
    if (lastKnownSoundLevel == -1) {
       lastKnownSoundLevel = soundLevel;
       lastKnownTone = selectedTone;
    } 
    else if (soundLevel != lastKnownSoundLevel || selectedTone != lastKnownTone) {
       lastKnownSoundLevel = soundLevel;
       lastKnownTone = selectedTone;
       isCloudPreviewing = true;
       cloudPreviewEndTime = currentMillis + 3000; 
    }
  }

  if (isLampOnByAlarm) {
    if (currentMillis - lampTurnedOnTime >= 900000) {
      isLampOnByAlarm = false; 
    }
  }

  // ==========================================
  // BUTTON MULTI-CLICK & HOLD LOGIC
  // ==========================================
  int btnState = digitalRead(BUTTON_PIN);
  if (btnState == LOW) { 
    if (!btnIsPressed) {
      btnIsPressed = true;
      btnPressTime = currentMillis; 
      longPressTriggered = false;
      hardwareResetTriggered = false; // Reset the 10s flag on new press
    }

    unsigned long holdTime = currentMillis - btnPressTime;

    // 1. OFFLINE HARDWARE RESET (Hold 10 seconds)
    if (holdTime >= 10000 && !hardwareResetTriggered && !isResetPending) {
      hardwareResetTriggered = true;
      playTonePattern(0, 0, 0, true); 
      drawBootScreen("HARDWARE RESET...");
      factoryReset();
      delay(2000);
      ESP.restart(); 
    }
    // 2. MENU MODE (Hold 5 seconds)
    else if (holdTime >= 5000 && !longPressTriggered && !hardwareResetTriggered && !isResetPending) {
      longPressTriggered = true;
      playTonePattern(0, 0, 0, true); 

      if (isMenuMode) {
        isMenuMode = false;
        isPreviewing = false; 
        tone(SPEAKER_PIN, 1500, 200); 
      } else {
        isMenuMode = true;
        isStopped = true; 
        currentAlarmState = IDLE;
        
        isLampOnByAlarm = false;
        isRelayEnabled = false; 
        
        isPreviewing = true;
        previewEndTime = currentMillis + 4000; 
      }
    }
  } 
  else { 
    if (btnIsPressed) {
      btnIsPressed = false;
      unsigned long pressDuration = currentMillis - btnPressTime;
      
      if (!longPressTriggered && !hardwareResetTriggered && pressDuration > 50) {
        if (currentMillis - lastMultiPressTime > 1000) multiPressCount = 0;
        multiPressCount++;
        lastMultiPressTime = currentMillis;

        if (isResetPending) {
          resetConfirmPresses++;
          if (resetConfirmPresses >= 2) {
            playTonePattern(0, 0, 0, true); 
            drawBootScreen("FACTORY RESET...");
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
            
            if (isCloudResetPending) {
              isCloudResetPending = false;
              pushResetCancelToCloud = true;
              tone(SPEAKER_PIN, 1500, 200); 
            }
            else if (isMenuMode) {
              selectedTone++;
              if (selectedTone > 1) selectedTone = 0; 
              isPreviewing = true;
              previewEndTime = currentMillis + 4000; 
            } 
            else {
              // THIS IS WHERE A 1-CLICK STOPS THE ALARM!
              if (!isStopped) {
                isStopped = true; 
                if (currentAlarmState != IDLE) playTonePattern(0, 0, 0, true); 
                if (String(currentTimeStr) == alarmTime) buttonPressedLog = 1; 
                isCloudPreviewing = false;
              }
            }
          }
        }
      }
    }
  }

  if (isResetPending) {
    if (currentMillis - resetPendingStartTime >= 10000) {
      isResetPending = false; 
      resetConfirmPresses = 0;
      multiPressCount = 0;
    }
  }

  if (isCloudResetPending) {
    if (currentMillis - cloudResetStartTime >= 10000) {
      playTonePattern(0, 0, 0, true); 
      drawBootScreen("WIPING DEVICE...");
      factoryReset();
      delay(2000);
      ESP.restart(); 
    }
  }

  if (isMenuMode) {
    if (currentMillis < previewEndTime) {
       playTonePattern(selectedTone, currentMillis, soundLevel, false); 
    } else if (isPreviewing) {
       playTonePattern(0, 0, 0, true); 
       isPreviewing = false;
    }
  } 
  else if (isCloudPreviewing) {
    if (currentMillis < cloudPreviewEndTime) {
       playTonePattern(selectedTone, currentMillis, soundLevel, false); 
    } else {
       playTonePattern(0, 0, 0, true); 
       isCloudPreviewing = false;
    }
  }
  else {
    if (String(currentTimeStr) == alarmTime && isAlarmEnabled) {
      if (isStopped) {
        if (currentAlarmState != IDLE) {
          currentAlarmState = IDLE;
          playTonePattern(0, 0, 0, true); 
          
          isLampOnByAlarm = false;
          isRelayEnabled = false;
        }
        if (motionDetected == HIGH && !wokeUpFlagPushed) wokeUpFlagPushed = true; 
      } 
      else {
        if (currentAlarmState == IDLE) {
          currentAlarmState = RINGING;
          stateTimer = currentMillis;
          
          isLampOnByAlarm = true; 
          lampTurnedOnTime = currentMillis;
        }

        if (currentAlarmState == RINGING) {
          playTonePattern(selectedTone, currentMillis, soundLevel, false);
          
          if (currentMillis - stateTimer >= 60000) { 
            currentAlarmState = RESTING;
            stateTimer = currentMillis;
            playTonePattern(0, 0, 0, true); 
          }
        } 
        else if (currentAlarmState == RESTING) {
          if (currentMillis - stateTimer >= 300000) { 
            currentAlarmState = RINGING;
            stateTimer = currentMillis;
          }
        }
      }
    } 
    else {
      if (currentAlarmState != IDLE) {
        currentAlarmState = IDLE;
        playTonePattern(0, 0, 0, true);
      }
      isStopped = false;
      wokeUpFlagPushed = false;
      buttonPressedLog = 0; 
    }
  }

  bool targetRelayState = false;

  if (isLampOnByAlarm) targetRelayState = true;
  if (isRelayEnabled) targetRelayState = true; 

  if (targetRelayState) {
    digitalWrite(RELAY_PIN, HIGH); 
    isRelayActuallyOn = true;
  } else {
    digitalWrite(RELAY_PIN, LOW); 
    isRelayActuallyOn = false;
  }

  renderMainScreen();
  delay(10); 
}