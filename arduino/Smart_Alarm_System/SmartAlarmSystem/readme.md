# ESP32 Smart AI Alarm System

An advanced, IoT-enabled bedside smart alarm built on the Arduino framework. This ESP32-S3 device goes beyond a standard clock by featuring environmental monitoring, an intelligent 15-minute wake-up lamp relay, multi-click hardware controls, and dual-cloud synchronization (Firebase RTDB for real-time app control & MongoDB Atlas for long-term data logging).

---

## Project Structure (File Purposes)

The codebase is organized into modular components for easier maintenance, memory management, and scalability:

* **`SmartAlarmSystem.ino`**: The main brain of the device. Contains the core execution flow, sensor reading logic, the 15-minute lamp timer, button multi-click tracking, and the Unified Relay Controller.
* **`Globals.h` / `Config.h`**: The "Bulletin Board" of the device. Stores global state variables (like `isManualLampOn`), pin definitions, and shared configuration constants so all files can talk to each other.
* **`CloudSync.cpp` / `.h`**: Manages all network connectivity. It handles 5-second Firebase updates for real-time app control, self-provisions the database on first boot, and pushes 60-second environmental logs to MongoDB Atlas.
* **`DisplayUI.cpp` / `.h`**: Controls the SSD1306 OLED screen. It renders the dynamic dashboard (Time, Temp, Humidity, Light, Lamp Status), the Sound Menu, and the live 10-second Factory Reset countdown.
* **`SoundEngine.cpp` / `.h`**: Controls the PWM buzzer melodies, audio output channels, and generates different alarm ringtones (Classic vs. Urgent).
* **`BluetoothSetup.cpp` / `.h`**: Handles BLE (Bluetooth Low Energy) initialization and communication protocols for securely passing Wi-Fi credentials from the mobile app to the device.
* **`DeviceMemory.cpp` / `.h`**: Manages local non-volatile storage (Preferences/Flash) to save Wi-Fi credentials and provisioning status across reboots.
* **`arduino_secrets.h`**: A protected configuration template for storing sensitive credentials like API tokens and database URLs.

---

## 📖 Device User Manual: How It Works

### 1. First Boot & Provisioning
When you power on the device for the very first time, it will enter **Bluetooth Setup Mode**. 
1. Use your companion mobile app to connect to the device via BLE.
2. Send your local Wi-Fi SSID and Password. 
3. The device will connect to Wi-Fi, sync the exact local time via NTP, and auto-generate its required database switches in Firebase.

### 2. The Main Dashboard (Idle Mode)
During normal operation, the OLED screen acts as an environmental dashboard. It displays:
* **Current Time & Date**
* **Temperature & Humidity** (via DHT sensor)
* **Light Level** (DARK, DIM, NORMAL, BRIGHT via smoothed LDR sensor)
* **Lamp Status** (ON/OFF - shows the actual physical state of the relay)
* **Sync Status** (Confirms cloud connection)

### 3. Alarm & Relay Logic
When the current time matches the target `AlarmTime` set in Firebase:
* **The Buzzer:** Rings for 1 minute. If not stopped, it enters a 5-minute "Snooze" state, then rings again.
* **The Lamp (Relay):** If `RelayEnabled` is true in the app, the relay turns ON to power a bedside lamp. A hidden **15-minute timer** starts. Even if the buzzer stops or snoozes, the lamp stays on for 15 minutes to help you wake up, then shuts off automatically.

### 4. Hardware Button Controls
The device features a single, smart multi-purpose button:
* **1 Quick Click:** * If the alarm is ringing: Acts as **STOP** (Instantly kills the buzzer, the lamp, and the 15-minute timer).
    * If in the Menu: Changes the selected Ringtone.
* **Hold for 5 Seconds:** Enters or Exits the **Sound Menu** to preview ringtones.
* **5 Quick Clicks:** Triggers the **Factory Reset Warning** (Screen shows a 10-second countdown).
* **2 Quick Clicks (During Warning):** Confirms the factory reset. Deletes Wi-Fi memory and reboots the device.
* *(If you do nothing during the 10-second warning, the screen safely returns to the dashboard).*

### 5. Mobile App / Firebase Controls
The device constantly listens to Firebase for these specific commands:
* `AlarmTime`: Sets the wake-up time (e.g., "07:00").
* `RelayEnabled` (Permission Switch): Tells the device if it is allowed to turn on the lamp when the morning alarm rings.
* `ManualLamp` (Smart Plug Override): Turns the bedside lamp ON or OFF instantly at any time of day, completely bypassing the alarm clock.
* `MobileStop`: An emergency remote kill-switch that stops the ringing alarm and lamp from your phone.

---

## 🛠️ Getting Started & Hardware Setup

### Prerequisites
* **Arduino IDE** (v2.0+) 
* **Partition Scheme Requirement:** Due to heavy Cloud and BLE libraries, you **MUST** set your partition scheme in the Arduino IDE to **"Huge APP (3MB No OTA/1MB SPIFFS)"** before uploading.

### Hardware Components Used
* **Microcontroller:** ESP32-S3 (With Wi-Fi & BLE)
* **Display:** 0.96" SSD1306 I2C OLED
* **Sensors:** * DHT11 / DHT22 (Temperature & Humidity)
    * LDR Photoresistor (Ambient Light)
    * HC-SR501 PIR (Motion Detection)
* **Actuators:**
    * Active-High Relay Module (Controls 120V/240V external lamp)
    * Active Piezo Buzzer
* **Input:** Single Tactile Push Button
