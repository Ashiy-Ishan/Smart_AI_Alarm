/**
 * Project: Smart AI Alarm System - Bedside Hub Diagnostic
 * Board: ESP32-S3-N16R8 DevKitC-1
 * results on the 128x64 OLED screen using your specific pin assignments.
 */

#include <Wire.h>
#include <Adafruit_GFX.h>
#include <Adafruit_SSD1306.h>
#include <DHT.h>

// --- I2C Communication (OLED Display) ---
#define OLED_SDA          19    
#define OLED_SCL          18    

// --- Input Sensors (Context Data) ---
#define PIN_DHT22          4    
#define PIN_PIR_MOTION    13    
#define PIN_LDR_LIGHT      1    

// --- Output & Automation ---
#define PIN_RELAY_COFFEE  12    
#define PIN_SPEAKER_ALARM 17    

// OLED Configuration
#define SCREEN_WIDTH 128
#define SCREEN_HEIGHT 64
#define OLED_RESET    -1 
Adafruit_SSD1306 display(SCREEN_WIDTH, SCREEN_HEIGHT, &Wire, OLED_RESET);

// DHT Configuration
#define DHTTYPE DHT22
DHT dht(PIN_DHT22, DHTTYPE);

void setup() {
  // Initialize Serial for debugging
  Serial.begin(115200);

  // 1. Initialize I2C with your specific S3 pins
  Wire.begin(OLED_SDA, OLED_SCL);

  // 2. Initialize OLED
  if(!display.begin(SSD1306_SWITCHCAPVCC, 0x3C)) { 
    Serial.println(F("SSD1306 allocation failed"));
    for(;;); 
  }

  // 3. Initialize Sensors
  dht.begin();
  pinMode(PIN_PIR_MOTION, INPUT);
  pinMode(PIN_LDR_LIGHT, INPUT); // ADC pin
  
  // 4. Initialize Outputs
  pinMode(PIN_RELAY_COFFEE, OUTPUT);
  digitalWrite(PIN_RELAY_COFFEE, LOW); // Keep off initially

  // Initial Splash Screen
  display.clearDisplay();
  display.setTextSize(1);
  display.setTextColor(SSD1306_WHITE);
  display.setCursor(10, 20);
  display.println(F("AI ALARM SYSTEM"));
  display.setCursor(10, 35);
  display.println(F("Initializing..."));
  display.display();
  delay(2000);
}

void loop() {
  // Read Sensor Data
  float humidity = dht.readHumidity();
  float temperature = dht.readTemperature();
  int motion = digitalRead(PIN_PIR_MOTION);
  int lightLevel = analogRead(PIN_LDR_LIGHT);

  // Clear display buffer
  display.clearDisplay();
  display.setTextSize(1);
  display.setTextColor(SSD1306_WHITE);

  // --- Title ---
  display.setCursor(0, 0);
  display.println(F("DEVICE STATUS (W7)"));
  display.drawLine(0, 10, 128, 10, SSD1306_WHITE);

  // --- Row 1: Temp & Humidity ---
  display.setCursor(0, 15);
  display.print(F("TEMP: "));
  if (isnan(temperature)) display.print(F("ERR"));
  else { display.print(temperature, 1); display.print(F("C")); }

  display.setCursor(70, 15);
  display.print(F("H: "));
  if (isnan(humidity)) display.print(F("ERR"));
  else { display.print(humidity, 0); display.print(F("%")); }

  // --- Row 2: Motion Status ---
  display.setCursor(0, 30);
  display.print(F("MOTION: "));
  if (motion == HIGH) {
    display.print(F("ACTIVE!")); // Triggers AI Calculation
  } else {
    display.print(F("STILL"));
  }

  // --- Row 3: Light Levels ---
  display.setCursor(0, 45);
  display.print(F("LIGHT: "));
  display.print(lightLevel); // Raw ADC value 
  
  // --- Footer ---
  display.setCursor(0, 57);
  display.print(F("S3-N16R8 Online"));

  // Push buffer to hardware
  display.display();

  // Serial log for monitoring
  Serial.print(F("T:")); Serial.print(temperature);
  Serial.print(F(" H:")); Serial.print(humidity);
  Serial.print(F(" M:")); Serial.println(motion);

  delay(1000); // Update every second
}
