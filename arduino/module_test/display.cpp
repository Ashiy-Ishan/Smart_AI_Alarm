#include <Wire.h>
#include <Adafruit_GFX.h>
#include <Adafruit_SSD1306.h>

//  I2C Pin
#define OLED_SDA 19
#define OLED_SCL 18

//  Display Settings
#define SCREEN_WIDTH 128
#define SCREEN_HEIGHT 64
#define OLED_RESET    -1

Adafruit_SSD1306 display(SCREEN_WIDTH, SCREEN_HEIGHT, &Wire, OLED_RESET);

void setup() {
  Serial.begin(115200);

  // Assign pin for display
  Wire.begin(OLED_SDA, OLED_SCL);

  // OLED display power up
  if(!display.begin(SSD1306_SWITCHCAPVCC, 0x3C)) {
    Serial.println(F("OLED connection failed! Check your wiring."));
    for(;;); // Stop display work if display not found
  }

  Serial.println(F("OLED Initialized Successfully!"));

  // Start Test Graphics
  display.clearDisplay();

  // Draw a Border
  display.drawRect(0, 0, 128, 64, WHITE);

  // Text Properties
  display.setTextSize(1);
  display.setTextColor(WHITE);

  // Center Text
  display.setCursor(25, 20);
  display.println("SMART ALARM");

  display.setCursor(35, 35);
  display.setTextSize(2);
  display.println("READY");

  // Display
  display.display();
}

void loop() {
  // blink affect
  delay(1000);
  display.invertDisplay(true);
  delay(1000);
  display.invertDisplay(false);
}