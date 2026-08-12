#pragma once
#include <Arduino.h>

void setupMemory();
void saveConfigAsJSON(String ssid, String pass, String user);
void factoryReset();