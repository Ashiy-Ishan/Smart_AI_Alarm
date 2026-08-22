#pragma once
#include <Arduino.h>

enum AlarmState { IDLE, RINGING };

extern AlarmState currentAlarmState;

extern float temperature;
extern float humidity;
extern String lightStatus;
extern int lightValue;
extern int motionDetected;
extern String atlasStatus;

extern String alarmTime;
extern bool isStopped;
extern bool wokeUpFlagPushed;
extern int buttonPressedLog;

extern char currentTimeStr[6];
extern char dateStr[12];

extern String wifiSSID;
extern String wifiPass;
extern String userName;
extern bool isProvisioned; 
extern bool isBleSetupMode; 

extern bool isResetPending;
extern unsigned long resetPendingStartTime;
extern int resetConfirmPresses;
extern int multiPressCount;

// --- LOGIC: Relay & Lamp Switches ---
extern bool isRelayActuallyOn;
extern bool isManualLampOn;
