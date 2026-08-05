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
#include "esp_mac.h" 

FirebaseData fbdo;
FirebaseAuth auth;
FirebaseConfig config;

unsigned long lastFirebaseSync = 0;
unsigned long lastAtlasSync = 0;
unsigned long lastWiFiCheck = 0;
unsigned long atlasSyncInterval = 60000; 
bool isFirebaseInitialized = false; 

String devicePath = ""; 

String getBluetoothMAC() {
  uint8_t mac[6];
  esp_read_mac(mac, ESP_MAC_BT);
  char macStr[18];
  sprintf(macStr, "%02X:%02X:%02X:%02X:%02X:%02X", mac[0], mac[1], mac[2], mac[3], mac[4], mac[5]);
  return String(macStr);
}

void setupNetworkAndTime() {
  WiFi.begin(wifiSSID.c_str(), wifiPass.c_str());
  int dotCount = 0;
  int wifiTimeout = 0;
  
  while (WiFi.status() != WL_CONNECTED && wifiTimeout < 20) { 
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
    if (userUID != "") {
      devicePath = "Users/" + userUID + "/Devices/" + getBluetoothMAC();
    } else {
      devicePath = "Unclaimed_Devices/" + getBluetoothMAC();
    }
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
  if (currentMillis - lastFirebaseSync >= 5000) {
    lastFirebaseSync = currentMillis;
    
    if (Firebase.ready() && devicePath != "") {
      
      if (!isFirebaseInitialized) {
        if (Firebase.RTDB.get(&fbdo, devicePath + "/AlarmTime")) {
          if (fbdo.dataType() == "null") {
            FirebaseJson defaultAppKeys;
            defaultAppKeys.set("AlarmTime", "07:00");     
            defaultAppKeys.set("AlarmEnabled", true);   
            defaultAppKeys.set("SoundLevel", 5);          
            defaultAppKeys.set("SelectedTone", 0);        
            defaultAppKeys.set("RelayEnabled", false);    
            defaultAppKeys.set("MobileStop", false);   
            defaultAppKeys.set("FactoryReset", false); 
            defaultAppKeys.set("AlarmStatus", 0); // NEW: Add default state
            
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
      json.set("RelayStatus", isRelayActuallyOn ? "ON" : "OFF");

      // NEW: Send 1 if ringing, 0 if not ringing
      json.set("AlarmStatus", (currentAlarmState == RINGING) ? 1 : 0);

      // Old text-based status kept for backup
      if (currentAlarmState == RINGING) json.set("UserStatus", "ringing");
      else if (currentAlarmState == RESTING) json.set("UserStatus", "snooze");
      else if (currentAlarmState == IDLE && !wokeUpFlagPushed) json.set("UserStatus", "idle");

      Firebase.RTDB.updateNode(&fbdo, devicePath, &json);

      if (Firebase.RTDB.getString(&fbdo, devicePath + "/AlarmTime")) alarmTime = fbdo.stringData();
      
      if (Firebase.RTDB.get(&fbdo, devicePath + "/AlarmEnabled")) {
        if (fbdo.dataType() == "string") {
          String val = fbdo.stringData(); val.toLowerCase();
          isAlarmEnabled = (val == "true" || val == "1" || val == "on");
        } else isAlarmEnabled = fbdo.boolData();
      }

      if (Firebase.RTDB.get(&fbdo, devicePath + "/SoundLevel")) {
        soundLevel = (fbdo.dataType() == "string") ? fbdo.stringData().toInt() : fbdo.intData(); 
      }
      
      if (Firebase.RTDB.get(&fbdo, devicePath + "/SelectedTone")) {
        selectedTone = (fbdo.dataType() == "string") ? fbdo.stringData().toInt() : fbdo.intData(); 
      }

      bool previousRelayState = isRelayEnabled;
      if (Firebase.RTDB.get(&fbdo, devicePath + "/RelayEnabled")) {
        if (fbdo.dataType() == "string") {
          String val = fbdo.stringData(); val.toLowerCase();
          isRelayEnabled = (val == "true" || val == "1" || val == "on");
        } else isRelayEnabled = fbdo.boolData();
      }

      if (previousRelayState == true && isRelayEnabled == false) {
        isLampOnByAlarm = false;
      }

      if (Firebase.RTDB.getBool(&fbdo, devicePath + "/MobileStop")) {
        if (fbdo.boolData() == true) {
          isStopped = true;
          playTonePattern(0, 0, 0, true); 
          
          isLampOnByAlarm = false; 
          isRelayEnabled = false; 
          
          Firebase.RTDB.setBool(&fbdo, devicePath + "/RelayEnabled", false);
          
          currentAlarmState = IDLE; 
          Firebase.RTDB.setBool(&fbdo, devicePath + "/MobileStop", false); 
          Firebase.RTDB.setString(&fbdo, devicePath + "/UserStatus", "stopped_by_mobile");
        }
      }

      if (Firebase.RTDB.getBool(&fbdo, devicePath + "/FactoryReset")) {
        if (fbdo.boolData() == true && !isCloudResetPending && !pushResetCancelToCloud) {
            isCloudResetPending = true;
            cloudResetStartTime = millis();
        }
      }

      if (pushResetCancelToCloud) {
          Firebase.RTDB.setBool(&fbdo, devicePath + "/FactoryReset", false);
          pushResetCancelToCloud = false;
      }
    }
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
      
      String jsonPayload = "{\"device_id\":\"" + getBluetoothMAC() + "\",\"temperature\":" + String(temperature, 1) + ",\"humidity\":" + String(humidity, 1) + ",\"light\":\"" + lightStatus + "\",\"light_value\":" + String(lightValue) + ",\"motion\":" + String(motionDetected) + ",\"alarm_time\":\"" + alarmTime + "\",\"button_pressed\":" + String(buttonPressedLog) + "}";
      
      int httpResponseCode = http.POST(jsonPayload);
      if (httpResponseCode == 200) { atlasStatus = "SUCCESS"; atlasSyncInterval = 60000; } 
      else { atlasStatus = "FAILED"; atlasSyncInterval = 5000; }
      http.end(); 
    } else {
      atlasStatus = "WIFI LOST"; atlasSyncInterval = 5000; 
    }
  }
}