#include "DeviceMemory.h"
#include "Globals.h"
#include <Preferences.h>
#include <ArduinoJson.h>

Preferences prefs;

void setupMemory() {
  prefs.begin("smartAlarm", false); 
  String savedJSON = prefs.getString("config", "");
  
  if (savedJSON != "") {
    JsonDocument doc; // <-- Updated for ArduinoJson v7
    DeserializationError error = deserializeJson(doc, savedJSON);
    
    if (!error) {
      wifiSSID = doc["ssid"].as<String>();
      wifiPass = doc["pass"].as<String>();
      userName = doc["user"].as<String>();
      isProvisioned = true;
      Serial.println("Memory Loaded for User: " + userName);
      return;
    }
  }
  isProvisioned = false; 
}

void saveConfigAsJSON(String ssid, String pass, String user) {
  JsonDocument doc; // <-- Updated for ArduinoJson v7
  doc["ssid"] = ssid;
  doc["pass"] = pass;
  doc["user"] = user;
  
  String jsonOutput;
  serializeJson(doc, jsonOutput);
  
  prefs.begin("smartAlarm", false);
  prefs.putString("config", jsonOutput); 
  prefs.end();
}

void factoryReset() {
  prefs.begin("smartAlarm", false);
  prefs.clear(); 
  prefs.end();
  Serial.println("Device Factory Reset!");
}