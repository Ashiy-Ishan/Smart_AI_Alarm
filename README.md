# Smart AI Alarm System

The Smart AI Alarm System is a modern, IoT-enabled alarm clock solution that uses Machine Learning to adjust your wake-up time based on real-world factors like weather, traffic, and your historical sleep patterns. 

This repository contains all three major components of the system:
1. **Frontend (`fontend/alarm_frontend/`)**: A Flutter mobile application (iOS & Android) that allows users to manage their alarms, view sleep insights, and synchronize schedules with Google Calendar.
2. **Backend (`backend/ai_alarm_sytem/`)**: A Python-based Flask API that handles the AI (LightGBM) predictions, fetches real-time environmental data (Traffic & Weather), and securely stores user models in MongoDB.
3. **Hardware (`arduino/Smart_Alarm_System/`)**: An ESP32-based physical alarm clock featuring temperature/humidity sensors, motion detection, an OLED display, and a physical "Hard Wake" button mechanism.

---

## Environment Setup & Credentials

For security purposes, all sensitive API keys, database URLs, and passwords have been removed from this public repository. **You must configure your own credentials before running the system.**

### 1. Backend Configuration (Python)
Navigate to `backend/ai_alarm_sytem/.env` and provide your keys:

- `MONGO_URI`: Your MongoDB Atlas connection string. Make sure to whitelist your IP or 0.0.0.0.
- `DB_ENCRYPTION_KEY`: A 32-byte URL-safe base64-encoded string used by `cryptography.fernet` to encrypt user data. (You can generate one using Python: `from cryptography.fernet import Fernet; print(Fernet.generate_key().decode())`).
- `GOOGLE_MAPS_API_KEY`: A Google Cloud API Key with the **Distance Matrix API** and **Directions API** enabled.
- `GOOGLE_OAUTH_CLIENT_ID` & `SECRET`: Created in Google Cloud Credentials for Web Applications. Used for Google Calendar integration.
- `SMTP_PASSWORD`: An App Password generated from your Google Account settings (do not use your real Gmail password).

### 2. Frontend Configuration (Flutter)
Navigate to `fontend/alarm_frontend/.env` and provide your keys:

- `API_BASE_URL`: The URL where your Python backend is hosted (e.g., your Ngrok URL or Google Cloud Run URL).
- `WEATHER_API`: Your API key from **OpenWeatherMap**.
- `FIREBASE_*`: Your Firebase project credentials. Create a new Firebase project, enable Authentication and Realtime Database, and copy the Web/Android/iOS keys here.
- `GEOAPIFY_API_KEY`: Your API key from Geoapify (used for location autocomplete).

### 3. Hardware Configuration (ESP32 / Arduino)
Navigate to `arduino/Smart_Alarm_System/SmartAlarmSystem/Config.h`:

- `API_KEY`: Your Firebase Web API Key (found in Firebase Project Settings).
- `DATABASE_URL`: The URL to your Firebase Realtime Database.

**Note:** You do not need to hardcode your Wi-Fi credentials. The Flutter app sends them to the ESP32 via Bluetooth (BLE) during the initial setup!

---

## Running the Project

### Start the Backend
```bash
cd backend/ai_alarm_sytem
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
pip install -r requirements.txt
python main.py
```

### Start the Frontend
```bash
cd fontend/alarm_frontend
flutter pub get
flutter run
```

### Flash the Hardware
Open `arduino/Smart_Alarm_System/SmartAlarmSystem/SmartAlarmSystem.ino` in the Arduino IDE. Install the required libraries (Firebase ESP Client, DHT sensor library, Adafruit SSD1306) and upload it to your ESP32 board.
