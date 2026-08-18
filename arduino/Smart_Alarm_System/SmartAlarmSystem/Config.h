#pragma once

// --- 1. Cloud Database Credentials ---
const char* const SERVER_URL = "http://10.198.184.122:2000/api/data";
#define API_KEY "AIzaSyBQlTD6zBHUBr2_aUHf4yoWkMAubsjxbak"
#define DATABASE_URL "https://smart-ai-alarm-2f71d-default-rtdb.asia-southeast1.firebasedatabase.app/"

// --- 2. Bluetooth Configuration ---
#define BLE_SERVICE_UUID           "4fafc201-1fb5-459e-8fcc-c5c9c331914b"
#define BLE_CHARACTERISTIC_UUID_RX "beb5483e-36e1-4688-b7f5-ea07361b26a8" 
// Updated to match the app's MAC_READ_UUID
#define BLE_CHARACTERISTIC_UUID_TX "beb5483e-36e1-4688-b7f5-ea07361b26a9" 

// --- 3. Hardware Pin Layout ---
#define BUTTON_PIN 10  
#define SPEAKER_PIN 17 
#define OLED_SDA 5     
#define OLED_SCL 18    
#define DHTPIN   4     
#define PIR_PIN  13    
#define LDR_PIN  1     
#define RELAY_PIN 12   
#define DHTTYPE  DHT22