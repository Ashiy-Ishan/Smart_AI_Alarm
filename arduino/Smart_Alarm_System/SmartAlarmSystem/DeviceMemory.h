#pragma once
#include <Arduino.h>

void setupMemory();
void saveProvisioningData(String ssid, String pass, String uid); 
void factoryReset();