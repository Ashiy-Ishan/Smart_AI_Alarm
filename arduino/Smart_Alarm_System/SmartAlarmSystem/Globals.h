#pragma once
#include <Arduino.h>

enum AlarmState { IDLE, RINGING, RESTING };

extern AlarmState currentAlarmState;

extern float temperature;
extern float humidity;
extern String lightStatus;
extern int lightValue;
extern int motionDetected;
extern String atlasStatus;

extern String alarmTime;
extern int soundLevel;
extern int selectedTone;

extern bool isMenuMode;
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

// --- LOGIC: Relay & Lamp Switches ---
extern bool isRelayEnabled;     
extern bool isRelayActuallyOn;  
extern bool isManualLampOn;  
extern bool isLampOnByAlarm;
extern String userUID;