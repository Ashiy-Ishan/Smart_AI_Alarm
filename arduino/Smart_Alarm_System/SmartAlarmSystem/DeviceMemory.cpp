#include "DeviceMemory.h"
#include "Globals.h"
#include <Preferences.h>

Preferences preferences;
String userUID = ""; 

void setupMemory() {
  preferences.begin("alarm-app", false);
  
  wifiSSID = preferences.getString("ssid", "");
  wifiPass = preferences.getString("pass", "");
  userUID = preferences.getString("uid", ""); 
  
  if (wifiSSID != "") {
    isProvisioned = true;
  }
}

void saveProvisioningData(String ssid, String pass, String uid) {
  preferences.putString("ssid", ssid);
  preferences.putString("pass", pass);
  preferences.putString("uid", uid); 
}

void factoryReset() {
  preferences.begin("alarm-app", false);
  preferences.clear();
  preferences.end();
}