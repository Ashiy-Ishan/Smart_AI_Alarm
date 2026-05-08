#include <Wire.h>
#include <Adafruit_GFX.h>
#include <Adafruit_SSD1306.h>
#include <DHT.h>

// pind
#define OLED_SDA 5
#define OLED_SCL 18
#define DHTPIN   4      
#define DHTTYPE  DHT22 

#define SCREEN_WIDTH 128 
#define SCREEN_HEIGHT 64 

// Create display
Adafruit_SSD1306 display(SCREEN_WIDTH, SCREEN_HEIGHT, &Wire, -1);
DHT dht(DHTPIN, DHTTYPE);

void setup() {
  Serial.begin(115200);

  Wire.begin(OLED_SDA, OLED_SCL);

  dht.begin();

  if(!display.begin(SSD1306_SWITCHCAPVCC, 0x3C)) { 
    Serial.println(F("OLED failed to initialize"));
    for(;;);
  }
  
  display.clearDisplay();
  display.setTextColor(SSD1306_WHITE);
}

void loop() {
  delay(2000);

  float h = dht.readHumidity();

  if (isnan(h)) {
    Serial.println("Failed to read DHT sensor!");
    return;
  }

  display.clearDisplay();
  
  display.setTextSize(1);
  display.setCursor(0, 5);
  display.print("HUMIDITY LEVEL");
  
  display.drawLine(0, 15, 128, 15, SSD1306_WHITE);

  //  Humidity Value
  display.setTextSize(3);
  display.setCursor(10, 30);
  display.print(h, 1); 
  display.print("%");

  display.display(); 
}
