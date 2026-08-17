# **Smart AI Alarm System (Bedside Hub)**

An intelligent, context-aware alarm system that dynamically calculates wake-up times based on real-time traffic, weather, calendar events, and personalized sleep habits.

Built as a Capstone Project for the Faculty of Computing, Sabaragamuwa University of Sri Lanka.

## **Design & Prototype**

The complete UI/UX design, including the dashboard, IoT controls, and sleep insights, is documented in Figma:

👉 [**Figma Design Link**](https://www.figma.com/design/yCJvUqUl9FE1qCY64u1bO5/AI-Alarm-System?node-id=0-1&t=8qysfc3kRac0s7Fr-1)

---

## **Overview**

The **Smart AI Alarm System** transforms the traditional wake-up experience into a proactive "Sense-Think-Act" cycle. By using an **ESP32-S3** microcontroller as a bedside hub, the system monitors environmental conditions and coordinates with a **Firebase/Cloud Functions** backend to make intelligent decisions.

### **Key Features:**

*   **Dynamic Alarm Scaling:** Automatically adjusts wake-up times based on live traffic data and weather forecasts.
*   **Smart Scheduling:** Local Google Calendar integration ensures your home screen always shows the next relevant event.
*   **IoT Bedside Hub:** Continuous monitoring of room temperature, humidity, light, and motion.
*   **Assertive Alarm Control:** Stop or Snooze alarms instantly via the app UI or interactive notifications.
*   **High-Speed Response:** Hardware polls for stop signals every **500ms** for near-instant silence.
*   **Personalized Habit Learning:** Uses ML to calculate optimal "Buffer Time" based on historical preparation habits.

---

## **System Architecture**

*   **Hardware:** ESP32-S3-N16R8 (MCU with 8MB PSRAM).
*   **Backend:** Python (Cloud Functions/Flask) - Handles API orchestration and AI logic.
*   **Mobile App:** Flutter - Provides a responsive interface for analytics and settings.
*   **Databases:**
    *   **Firebase Realtime DB:** Low-latency alarm triggers and real-time device status.
    *   **MongoDB Atlas:** Long-term telemetry logs and user habit datasets for AI training.

---

## **🛠️ Hardware Setup (Bedside Hub)**

### **Component List:**
1.  **MCU:** ESP32-S3-N16R8 DevKitC-1
2.  **Display:** SSD1306 OLED (128x64 I2C)
3.  **Sensors:** DHT22 (Temp/Hum), PIR HC-SR501 (Motion), LDR (Light).
4.  **Actuators:** 5V Relay Module & Speaker with Amplifier.

### **Pin Configuration (Arduino IDE):**
| Component | ESP32-S3 Pin (GPIO) | Mode | Purpose |
| :--- | :--- | :--- | :--- |
| **OLED SDA** | 19 | I2C | Visual interface |
| **OLED SCL** | 18 | I2C | Clock for display |
| **DHT22 Data** | 4 | Input | Temp/Humidity context |
| **PIR Motion** | 13 | Input | Awake state verification |
| **LDR Light** | 1 | Analog | Ambient light detection |
| **Relay** | 12 | Output | Bedside light control |
| **Speaker** | 17 | PWM | Audio alarm buzzer |

---

## **Setup & Installation**

### **1. Backend Setup (Cloud Functions)**
The backend is located in `backend/ai_alarm_sytem/`.

1.  **Navigate to directory**:
    ```bash
    cd backend/ai_alarm_sytem/
    ```
2.  **Create Environment**:
    ```bash
    python3.14 -m venv venv
    source venv/bin/activate
    pip install -r requirements.txt
    ```
3.  **Configure Environment**:
    Ensure your `.env` file contains valid API keys for Google Maps, OpenWeather, and MongoDB Atlas.
4.  **Local Execution**:
    ```bash
    firebase emulators:start --only functions
    ```
5.  **Expose API (ngrok)**:
    ```bash
    ngrok http 5002
    ```

### **2. Mobile App Setup (Flutter)**
The app is located in `fontend/alarm_frontend/`.

1.  **Navigate to directory**:
    ```bash
    cd fontend/alarm_frontend/
    ```
2.  **Install Dependencies**:
    ```bash
    flutter pub get
    ```
3.  **Update API URL**:
    Open `lib/services/api_service.dart` and update `baseUrl` with your current `ngrok` URL.
4.  **Run App**:
    ```bash
    flutter run
    ```

### **3. Hardware Firmware (Arduino)**
The firmware is located in `arduino/Smart_Alarm_System/SmartAlarmSystem/`.

1.  Open `SmartAlarmSystem.ino` in Arduino IDE.
2.  **Required Libraries**: `Firebase ESP32 Client`, `DHT sensor library`, `Adafruit GFX`, `Adafruit SSD1306`.
3.  Configure `arduino_secrets.h` with your WiFi credentials and Firebase URL.
4.  Upload to your ESP32-S3.

---

## **Repository Structure**

*   `/arduino/Smart_Alarm_System`: ESP32 firmware and hardware logic.
*   `/backend/ai_alarm_sytem`: Firebase Functions and Python API logic.
*   `/fontend/alarm_frontend`: Flutter mobile application source code.
*   `/database_schema.md`: Overview of the MongoDB collection structure.

---

© 2026 Sabaragamuwa University of Sri Lanka - Faculty of Computing
