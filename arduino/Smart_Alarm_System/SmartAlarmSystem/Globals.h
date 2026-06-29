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

extern String userUID; 

extern bool isAlarmEnabled;     
extern bool isRelayEnabled;     
extern bool isRelayActuallyOn;  
extern bool isLampOnByAlarm;  

extern bool isCloudResetPending;
extern unsigned long cloudResetStartTime;
extern bool pushResetCancelToCloud;

// --- LOGIC: 10s Offline Hardware Reset ---
extern bool hardwareResetTriggered;