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

## **Repository Structure**

* /hardware: Arduino/C++ source code for the Bedside Hub.  
* /backend: FastAPI server scripts and AI model integration.  
* /app: Flutter application source code.  
* /docs: Project journals, circuit diagrams, and research documentation.

---

© 2026 Sabaragamuwa University of Sri Lanka \- Faculty of Computing
