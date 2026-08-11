# **Smart AI Alarm System (Bedside Hub)**

An intelligent, context-aware alarm system that dynamically calculates wake-up times based on real-time traffic, weather, calendar events, and personalized sleep habits.

Built as a Capstone Project for the Faculty of Computing, Sabaragamuwa University of Sri Lanka.

## **Design & Prototype**

The complete UI/UX design, including the dashboard, IoT controls, and sleep insights, is documented in Figma:

👉 [**Figma Design Link**](https://www.figma.com/design/yCJvUqUl9FE1qCY64u1bO5/AI-Alarm-System?node-id=0-1&t=8qysfc3kRac0s7Fr-1)

## **Overview**

The **Smart AI Alarm System** transforms the traditional wake-up experience into a proactive "Sense-Think-Act" cycle. By using an **ESP32-S3** microcontroller as a bedside hub, the system monitors environmental conditions and coordinates with a **FastAPI** backend to make intelligent decisions.

### **Key Features:**

* **Dynamic Alarm Scaling:** Automatically adjusts wake-up times based on live traffic data (Google Maps) and weather forecasts (OpenWeatherMap).  
* **Smart Scheduling:** Integrates with Google Calendar and Gmail to detect canceled meetings or early appointments.  
* **IoT Bedside Hub:** Continuous monitoring of room temperature, humidity, and motion to verify the user's awake status.  
* **Personalized Habit Learning:** Uses Machine Learning to calculate "Buffer Time" based on how long a user historically takes to prepare for the day.  
* **Smart Home Integration:** Automation routines to trigger a relay for a coffee machine or bedside lighting.

## **System Architecture**

* **Hardware:** ESP32-S3-N16R8 (High-performance MCU with 8MB PSRAM for local processing).  
* **Backend:** Python (FastAPI) \- Handles API orchestration and AI logic.  
* **Mobile App:** Flutter \- Provides a responsive interface for analytics and settings.  
* **Databases:**  
  * **Firebase Realtime DB:** Used for low-latency alarm triggers and device status.  
  * **MongoDB Atlas:** Stores long-term telemetry logs and user habit datasets for AI training.

## **🛠️ Hardware Setup (Bedside Hub)**

### **Component List:**

1. **MCU:** ESP32-S3-N16R8 DevKitC-1  
2. **Display:** SSD1306 OLED (128x64 I2C)  
3. **Sensors:** DHT22 (Temp/Hum), PIR HC-SR501 (Motion), LDR (Light).  
4. **Actuators:** 5V Relay Module & Speaker with Amplifier.

### **Pin Configuration (Arduino IDE):**

| Component | ESP32-S3 Pin (GPIO) | Mode | Purpose |
| :---- | :---- | :---- | :---- |
| **OLED SDA** | 19 | I2C | Visual interface for AI reasoning |
| **OLED SCL** | 18 | I2C | Clock for display sync |
| **DHT22 Data** | 4 | Input | Environmental context |
| **PIR Motion** | 13 | Input | Awake state verification |
| **LDR Light** | 1 | Analog | Ambient light detection (ADC1) |
| **Relay** | 12 | Output | Coffee machine/Light routine |
| **Speaker** | 17 | PWM | Audio alarm and morning briefing |

# **Backend and Frontend Setup**

## 1. Prerequisites

Install the following:

- Python 3.14
- Node.js and npm
- Firebase CLI
- Flutter SDK
- Android SDK
- Android Platform Tools (adb)
- Java/JDK compatible with the Flutter/Gradle Android setup
- ngrok

Verify the main tools:

- python3 --version
- node --version
- npm --version
- firebase --version
- flutter --version
- adb version
- ngrok version
- java -version

## 2. Backend Setup

Go to the backend directory

`cd ~/Smart_AI_Alarm/backend/ai_alarm_system`

Create and activate python environment

`python3.14 -m venv .venv`

`source .venv/bin/activate`

Install dependencies:

`pip install -r requirements.txt`

Make sure the backend .env file contains the required configuration

## 3. Firebase Emulator

The backend uses the Firebase Functions Emulator for local development.

From:

`backend/ai_alarm_sytem/`

run:

`firebase emulators:start --only functions`

The Functions Emulator should normally be available at:

http://127.0.0.1:5002

The API base path is:

http://127.0.0.1:5002/ai-alarm-system/us-central1/api

## 4. Expose the Backend with ngrok

Use ngrok to expose the local Firebase Functions Emulator.

Keep the Firebase emulator running in Terminal 1.

Open Terminal 2:

`ngrok http 5002`

You should get a forwarding address similar to:

https://YOUR-NGROK-DOMAIN.ngrok-free.dev

Keep ngrok running while using the Flutter application.

## 5. Test the ngrok API

Replace the domain with the current ngrok URL:

`curl https://YOUR-NGROK-DOMAIN.ngrok-free.dev/ai-alarm-system/us-central1/api/health`

Expected:

`{"status":"ok"}`

If this works, the API is reachable through the internet and can be accessed by the Android application.

## 6. Configure Flutter API URL

Open:

`fontend/alarm_frontend/lib/services/api_service.dart`

Set the API base URL to the current ngrok address:

`class ApiService {
  static const String baseUrl =
      'https://YOUR-NGROK-DOMAIN.ngrok-free.dev/ai-alarm-system/us-central1/api';
}`


when using the ngrok URL.

The complete URL should look like:

https://YOUR-NGROK-DOMAIN.ngrok-free.dev/ai-alarm-system/us-central1/api

Because free ngrok URLs can change, update this value whenever a new ngrok tunnel is created.

## 7. Flutter Setup

Go to the Flutter application:

`cd ~/Smart_AI_Alarm/fontend/alarm_frontend`

Install Flutter dependencies:

`flutter pub get`

Check available devices:

`flutter devices`

If the phone does not appear, verify:

`adb devices`

The phone should appear as an authorized device.

## 8. Firebase Configuration in Flutter

The Flutter application uses:

`lib/firebase_options.dart`

Firebase initialization occurs in:

`lib/main.dart`

The application calls:

`Firebase.initializeApp(
  options: DefaultFirebaseOptions.currentPlatform,
);`

Firebase initialization must succeed before Firebase Authentication, Realtime Database, or Firebase Messaging are accessed.

## 9. Run the Flutter Application on Android

Make sure all three components are running:

### Terminal 1 — Firebase
`cd ~/Smart_AI_Alarm/backend/ai_alarm_sytem
source .venv/bin/activate`

`firebase emulators:start --only functions`

### Terminal 2 — ngrok
`ngrok http 5002`

### Terminal 3 — Flutter
`cd ~/Smart_AI_Alarm/fontend/alarm_frontend
flutter run`

If multiple devices are available:

`flutter run -d DEVICE_ID`

For example:

`flutter run -d VUY9K19903900177`

## 10. Restarting the Entire System

When starting the project again, use this sequence.

### Terminal 1
`cd ~/Workspace/projects/capstone_project/Smart_AI_Alarm/backend/ai_alarm_sytem
source .venv/bin/activate`

`firebase emulators:start --only functions`

Confirm the Functions Emulator is running on port 5002.

### Terminal 2
`ngrok http 5002`

Copy the new HTTPS forwarding URL.

### Terminal 3

Update:

`fontend/alarm_frontend/lib/services/api_service.dart`

with the new ngrok URL.

Then:

`cd ~/Smart_AI_Alarm/fontend/alarm_frontend`

`flutter pub get`

`flutter run`

# Quick Start

For an already-configured development environment:

### Terminal 1
`cd ~/Smart_AI_Alarm/backend/ai_alarm_sytem`

`source .venv/bin/activate`

`firebase emulators:start --only functions`

### Terminal 2
`ngrok http 5002`

Update the ngrok URL in:

`fontend/alarm_frontend/lib/services/api_service.dart`

Then:

### Terminal 3
`cd ~/Smart_AI_Alarm/fontend/alarm_frontend`

`flutter pub get`

`flutter devices`

`flutter run`

Verify the backend before launching Flutter:

curl https://YOUR-NGROK-DOMAIN.ngrok-free.dev/ai-alarm-system/us-central1/api/health

Expected:

{"status":"ok"}

If that response works and the Android device is detected by Flutter, the local backend-to-mobile development environment is ready.

## **Repository Structure**

* /hardware: Arduino/C++ source code for the Bedside Hub.  
* /backend: FastAPI server scripts and AI model integration.  
* /app: Flutter application source code.  
* /docs: Project journals, circuit diagrams, and research documentation.

---

© 2026 Sabaragamuwa University of Sri Lanka \- Faculty of Computing
