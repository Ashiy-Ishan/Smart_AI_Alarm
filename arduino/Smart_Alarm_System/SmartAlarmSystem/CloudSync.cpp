#include "CloudSync.h"
#include "Config.h"
#include "Globals.h"
#include "SoundEngine.h"
#include "DisplayUI.h"

#include <WiFi.h>
#include <HTTPClient.h>
#include <Firebase_ESP_Client.h>
#include "time.h"

#include <addons/TokenHelper.h>
#include <addons/RTDBHelper.h>

FirebaseData fbdo;
FirebaseAuth auth;
FirebaseConfig config;

unsigned long lastFirebaseSync = 0;
unsigned long lastAtlasSync = 0;
unsigned long lastWiFiCheck = 0;
unsigned long atlasSyncInterval = 60000; 
bool isFirebaseInitialized = false; 

String devicePath = ""; 

void setupNetworkAndTime() {
  WiFi.begin(wifiSSID.c_str(), wifiPass.c_str());
  int dotCount = 0;
  int wifiTimeout = 0;

  while (WiFi.status() != WL_CONNECTED && wifiTimeout < 60) {
    String dots = "";
    for(int i = 0; i < dotCount; i++) dots += ".";
    drawBootScreen("Connecting WiFi" + dots);
    delay(500);
    dotCount++;
    wifiTimeout++;
    if(dotCount > 3) dotCount = 0;
  }

  if (WiFi.status() == WL_CONNECTED) {
    drawBootScreen("Connected!");
    // Construct path: Users/<userName>/Devices/<macAddress>
    devicePath = "Users/" + userName + "/Devices/" + WiFi.macAddress();
  } else {
    drawBootScreen("Offline Mode!");
  }
  delay(500);

  config.api_key = API_KEY;
  config.database_url = DATABASE_URL;
  Firebase.signUp(&config, &auth, "", "");
  Firebase.begin(&config, &auth);
  Firebase.reconnectWiFi(true);

  configTime(19800, 0, "pool.ntp.org");
  drawBootScreen("Syncing Time...");
  struct tm timeinfo;
  int timeTimeout = 0;
  while (!getLocalTime(&timeinfo) || timeinfo.tm_year < 120) {
    delay(500);
    timeTimeout++;
    if(timeTimeout > 6) break;
  }
}

void handleWiFiHealer(unsigned long currentMillis) {
  if (WiFi.status() != WL_CONNECTED) {
    if (currentMillis - lastWiFiCheck >= 10000) {
      lastWiFiCheck = currentMillis;
      WiFi.disconnect();
      WiFi.begin(wifiSSID.c_str(), wifiPass.c_str());
    }
  }
}

void syncWithFirebase(unsigned long currentMillis) {
  // 1. FAST POLL FOR STOP SIGNAL (every 500ms)
  static unsigned long lastStopCheck = 0;
  if (currentMillis - lastStopCheck >= 500) {
    lastStopCheck = currentMillis;
    if (Firebase.ready() && devicePath != "") {
      if (Firebase.RTDB.getBool(&fbdo, devicePath + "/MobileStop")) {
        if (fbdo.boolData() == true) {
          isStopped = true;
          isPreviewing = false;
          playTonePattern(0, 0, 0, true);
          currentAlarmState = IDLE;

          // Clear flags immediately
          Firebase.RTDB.setBool(&fbdo, devicePath + "/MobileStop", false);
          Firebase.RTDB.setString(&fbdo, devicePath + "/AlarmStatus", "IDLE");
          Serial.println("Alarm Stopped via Mobile (Fast Poll)");
        }
      }
    }
  }

  // 2. CHECK FOR FACTORY RESET (every 1 second)
  static unsigned long lastResetCheck = 0;
  if (currentMillis - lastResetCheck >= 1000) {
    lastResetCheck = currentMillis;
    if (Firebase.ready() && devicePath != "") {
      if (Firebase.RTDB.getBool(&fbdo, devicePath + "/FactoryReset")) {
        if (fbdo.boolData() == true) {
          if (!isResetPending) {
            isResetPending = true;
            resetPendingStartTime = currentMillis;
            resetConfirmPresses = 0;
            multiPressCount = 0;
            playTonePattern(0, 0, 0, true);
            Serial.println("Remote Factory Reset Triggered!");
          }
        } else if (isResetPending) {
          isResetPending = false;
          Serial.println("Remote Factory Reset Cancelled!");
        }
      }
    }
  }

  if (currentMillis - lastFirebaseSync >= 5000) {
    lastFirebaseSync = currentMillis;
    
    if (Firebase.ready() && devicePath != "") {
      if (!isFirebaseInitialized) {
        if (Firebase.RTDB.get(&fbdo, devicePath + "/AlarmTime")) {
          if (fbdo.dataType() == "null") {
            FirebaseJson defaultAppKeys;
            defaultAppKeys.set("AlarmTime", "07:00");     
            defaultAppKeys.set("SoundLevel", 5);          
            defaultAppKeys.set("SelectedTone", 1); // Default to Tech Sound Track (Index 1)
            defaultAppKeys.set("ManualLamp", false);
            defaultAppKeys.set("MobileStop", false);      

            Firebase.RTDB.updateNode(&fbdo, devicePath, &defaultAppKeys);
          }
        }
        isFirebaseInitialized = true; 
      }

      FirebaseJson json;
      json.set("Temperature", temperature);
      json.set("Humidity", humidity);
      json.set("LightStatus", lightStatus);
      json.set("MotionDetected", motionDetected);

      // Report physical relay status
      json.set("RelayStatus", isRelayActuallyOn ? "ON" : "OFF");

      if (currentAlarmState == RINGING) json.set("AlarmStatus", "RINGING");
      else json.set("AlarmStatus", "IDLE");

      Firebase.RTDB.updateNode(&fbdo, devicePath, &json);

      if (Firebase.RTDB.getString(&fbdo, devicePath + "/AlarmTime")) alarmTime = fbdo.stringData();

      // READ SENSOR DATA FROM FIREBASE (as requested)
      if (Firebase.RTDB.getFloat(&fbdo, devicePath + "/Temperature")) {
        if (fbdo.dataType() != "null") temperature = fbdo.floatData();
      }
      if (Firebase.RTDB.getFloat(&fbdo, devicePath + "/Humidity")) {
        if (fbdo.dataType() != "null") humidity = fbdo.floatData();
      }
      if (Firebase.RTDB.getString(&fbdo, devicePath + "/LightStatus")) {
        if (fbdo.dataType() != "null") lightStatus = fbdo.stringData();
      }

      if (Firebase.RTDB.get(&fbdo, devicePath + "/SoundLevel")) {
        soundLevel = (fbdo.dataType() == "string") ? fbdo.stringData().toInt() : fbdo.intData();
      }

      if (Firebase.RTDB.get(&fbdo, devicePath + "/SelectedTone")) {
        selectedTone = (fbdo.dataType() == "string") ? fbdo.stringData().toInt() : fbdo.intData();
      }

      if (Firebase.RTDB.get(&fbdo, devicePath + "/ManualLamp")) {
        if (fbdo.dataType() == "string") {
          String val = fbdo.stringData();
          val.toLowerCase();
          isManualLampOn = (val == "true" || val == "1" || val == "on");
        }
        else if (fbdo.dataType() == "boolean") {
          isManualLampOn = fbdo.boolData();
        }
        else if (fbdo.dataType() == "int" || fbdo.dataType() == "float") {
          isManualLampOn = (fbdo.intData() > 0);
        }
      }

      // Physical stop check (optional extra sync)
      if (Firebase.RTDB.getString(&fbdo, devicePath + "/AlarmStatus")) {
        if (fbdo.stringData() == "IDLE" && currentAlarmState == RINGING) {
           isStopped = true;
           playTonePattern(0, 0, 0, true);
           currentAlarmState = IDLE;
        }
      }

      // REMOTE FACTORY RESET LOGIC
      if (Firebase.RTDB.getBool(&fbdo, devicePath + "/FactoryReset")) {
        if (fbdo.boolData() == true) {
          if (!isResetPending) {
            isResetPending = true;
            resetPendingStartTime = millis();
            resetConfirmPresses = 0;
            multiPressCount = 0;
            playTonePattern(0, 0, 0, true); // Stop any noise
            Serial.println("Remote Factory Reset Triggered!");
          }
        } else {
          // If flag is set to false from cloud, cancel pending reset if it was a remote one
          if (isResetPending) {
             isResetPending = false;
             Serial.println("Remote Factory Reset Cancelled!");
          }
        }
      }
    }
  }
}

void deleteDeviceNode() {
  if (WiFi.status() == WL_CONNECTED && devicePath != "") {
    Firebase.RTDB.deleteNode(&fbdo, devicePath);
  }
}

void stopAlarmInCloud() {
  if (Firebase.ready() && devicePath != "") {
    Firebase.RTDB.setBool(&fbdo, devicePath + "/MobileStop", true);
    Firebase.RTDB.setString(&fbdo, devicePath + "/AlarmStatus", "IDLE");
  }
}

void syncWithAtlas(unsigned long currentMillis) {
  if (currentMillis - lastAtlasSync >= atlasSyncInterval) {
    lastAtlasSync = currentMillis;
    if (WiFi.status() == WL_CONNECTED) {
      HTTPClient http;
      http.begin(SERVER_URL);
      http.setTimeout(2500); 
      http.addHeader("Content-Type", "application/json");
      
      String jsonPayload = "{\"device_id\":\"" + WiFi.macAddress() + "\",\"temperature\":" + String(temperature, 1) + ",\"humidity\":" + String(humidity, 1) + ",\"light\":\"" + lightStatus + "\",\"light_value\":" + String(lightValue) + ",\"motion\":" + String(motionDetected) + ",\"alarm_time\":\"" + alarmTime + "\",\"button_pressed\":" + String(buttonPressedLog) + "}";
      
      int httpResponseCode = http.POST(jsonPayload);
      if (httpResponseCode == 200) { atlasStatus = "SUCCESS"; atlasSyncInterval = 60000; } 
      else { atlasStatus = "FAILED"; atlasSyncInterval = 5000; }
      http.end(); 
    } else {
      atlasStatus = "WIFI LOST"; atlasSyncInterval = 5000; 
    }
  }
}
