#pragma once
#include <Arduino.h>

void setupNetworkAndTime();
void handleWiFiHealer(unsigned long currentMillis);
void syncWithFirebase(unsigned long currentMillis);
void syncWithAtlas(unsigned long currentMillis);
void deleteDeviceNode();
void stopAlarmInCloud();