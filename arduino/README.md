# Smart AI Alarm System – Device & Server Documentation

## 1. Project Overview
This part of the project handles the physical smart alarm clock (using an ESP32 microchip) and a Python server. The ESP32 is the actual alarm clock that sits on your table. It reads room sensors, shows information on a screen, makes sounds, and turns a lamp on or off. The Python server collects all the sensor data and saves it in a database (MongoDB) so the AI can use it later.

**Main technologies used:**
- **C++ (Arduino)** – The programming language used to code the ESP32.
- **Firebase** – A cloud database that lets the device talk to the mobile app instantly.
- **Interrupts** – A special hardware trick that makes physical buttons react instantly without any lag.
- **TFT Screen** – The code used to draw things on the physical LCD screen.
- **NTP (Network Time)** – Getting the exact world time from the internet.
- **Python & Flask** – A small program that acts like a bridge between the ESP32 and MongoDB.

## 2. Hardware Architecture
The hardware code is split into small pieces so the device can do many things at once without freezing.

```
Sensors (Temperature, Light, Motion)
         ↓
    ESP32 Microchip
         ↓
  Instant Button Clicks (Interrupts)
         ↓
   Firebase (Cloud)  ←→  Python Server
         ↓                  ↓
    Flutter App          MongoDB (Database)
```

**Main files:**
- `SmartAlarmSystem.ino` – The main file that runs everything.
- `CloudSync` – Talks to Firebase.
- `DisplayManager` – Controls the screen.
- `NetworkManager` – Connects to Wi-Fi and gets the time.
- `SensorManager` – Reads the physical sensors.
- `SoundEngine` – Plays the alarm sounds.
- `server.py` – The Python program that saves data.

## 3. How the Device Starts Up
When you plug the alarm clock into the wall, here is what it does:
1. Turns on the screen and shows a "Boot" message.
2. Connects to Wi-Fi.
3. Asks the internet for the exact current time.
4. Connects to Firebase.
5. Downloads your saved alarm time and checks if the lamp should be ON or OFF.
6. Starts running normally.

## 4. Instant Button Reactions (Hardware Interrupts)
Normally, an Arduino reads the code line by line. If it is busy talking to the internet, it might ignore you pressing a button for a second. That feels slow and laggy.
To fix this, we used **Hardware Interrupts**. 
When you press the button, the ESP32 drops whatever it is doing, instantly turns on the lamp, and then goes back to its work. This guarantees a **zero-lag** response every time.

## 5. Sound Engine (Buzzer)
We used a **passive buzzer**. Unlike cheap buzzers that only make one annoying flat beep, a passive buzzer lets us play real musical notes. 
The code creates a classic digital alarm clock pattern (fast high-pitch beeps, followed by a delay, then lower-pitch beeps) that loops perfectly until you turn it off.

## 6. Firebase (Real-time Sync)
The alarm clock connects to Firebase every 0.5 seconds (half a second) to see if you pressed anything on the mobile app. 

**Flow:**
- Checks if you pressed "Stop Alarm" on your phone.
- Checks if you toggled the "Lamp" switch on your phone.
- Sends the room's temperature and humidity to your phone.
- Tells your phone if the alarm is currently ringing.

## 7. Python Server (`server.py`)
Firebase is great for fast, real-time buttons, but it is bad for storing months of data. 
So, we send all the historical sensor data to a Python server instead. The Python server receives the data, adds a correct timestamp to it, and saves it safely in a MongoDB database so the AI can use it in the future.

## 8. Example: How Stopping the Alarm Works
This is a great example to explain to your teachers:
1. The alarm clock sees that it is 07:00 AM.
2. It starts making the beeping sound.
3. It tells Firebase "I am ringing". The Flutter app sees this and shows the Alarm screen.
4. The user reaches out and presses the physical STOP button on the clock.
5. The Hardware Interrupt instantly stops the sound.
6. The clock tells Firebase "I stopped ringing". 
7. The Flutter app sees this and closes the Alarm screen.

## 9. Security Methods
1. **No direct Database access:** The ESP32 does not have the MongoDB password. It only talks to the Python server, which keeps the database safe.
2. **Database Rules:** Firebase rules stop strangers from controlling your alarm.

## 10. Weaknesses and Limitations
- **Wi-Fi Dependency:** If your house Wi-Fi drops, the clock cannot get new alarm times from your phone.
- **Python Server Location:** Right now, the Python server runs on your local computer. For a real product, it needs to run on a cloud website like AWS or Google Cloud.

## 11. Testing Strategy
- **Serial Monitor:** We used the Arduino Serial Monitor to print out errors and check if the Wi-Fi was working.
- **Postman:** We used Postman to send fake data to the Python server to make sure it saves to MongoDB correctly.
- **Physical Stress Testing:** We pressed the physical lamp button extremely fast to make sure the device doesn't crash or lag.

---

## 12. Viva Questions and Simple Answers

**What is the role of the ESP32 in this project?**
**Answer:** It is the brain of the physical alarm clock. It reads sensors, controls the screen, makes alarm sounds, and talks to the internet.

**Why did you use Interrupts for the button instead of a normal loop?**
**Answer:** If the device is busy downloading data from Wi-Fi, a normal button press might feel slow or be ignored. An interrupt stops everything and turns the light on instantly, with zero lag.

**Why do you have a Python server if you already use Firebase?**
**Answer:** We use Firebase for real-time things like turning on the lamp instantly. But we use the Python server and MongoDB to store huge amounts of old sensor data to train our AI later.

**How does the ESP32 know what time it is?**
**Answer:** It connects to the internet and uses NTP (Network Time Protocol) to download the exact world time.

**What is the difference between an active and passive buzzer?**
**Answer:** An active buzzer can only make one single boring sound. We used a passive buzzer, which let us program different pitches and make a nice alarm melody.

**How does the physical clock update the Flutter app?**
**Answer:** The clock changes a value in Firebase (like saying "Alarm is Ringing"). The Flutter app is always watching Firebase, so it reacts instantly.

**What happens if the Python server crashes?**
**Answer:** The device won't be able to save historical data to MongoDB, but the alarm clock and the mobile app will still work perfectly because they use Firebase.

**What does `IRAM_ATTR` do in your Arduino code?**
**Answer:** It saves the button code in the fastest memory possible (RAM), so when a user presses the button, the ESP32 reacts instantly.

**How do you stop the button from double-clicking itself?**
**Answer:** We added a "debounce" timer. If the button is clicked twice in a split second, the code ignores the second click.

**What was your biggest challenge on the hardware side?**
**Answer:** Trying to run the Wi-Fi, read sensors, and sync with Firebase at the same time without making the physical buttons lag. Moving the button code to "Interrupts" fixed it.
