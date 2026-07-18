#include "DisplayUI.h"
#include "Config.h"
#include "Globals.h"
#include <Wire.h>
#include <Adafruit_GFX.h>
#include <Adafruit_SSD1306.h>

Adafruit_SSD1306 display(128, 64, &Wire, -1);

void setupDisplay() {
  Wire.begin(OLED_SDA, OLED_SCL);
  if(!display.begin(SSD1306_SWITCHCAPVCC, 0x3C)) {
    Serial.println(F("SSD1306 allocation failed"));
    for(;;); 
  }
}

void drawBootScreen(String message) {
  display.clearDisplay();
  display.drawCircle(64, 24, 16, WHITE);         
  display.fillCircle(64, 24, 2, WHITE);         
  display.drawLine(64, 24, 64, 14, WHITE);      
  display.drawLine(64, 24, 72, 30, WHITE);       
  display.setTextSize(1);
  display.setTextColor(WHITE);
  int16_t x1, y1; uint16_t w, h;
  display.getTextBounds(message, 0, 0, &x1, &y1, &w, &h);
  display.setCursor((128 - w) / 2, 50); 
  display.print(message);
  display.display();
}

void drawBleSetupScreen() {
  display.clearDisplay();
  display.drawRect(0, 0, 128, 64, WHITE);
  display.setTextSize(1);
  display.setTextColor(WHITE);
  display.setCursor(10, 10);
  display.println("BLUETOOTH MODE");
  display.setCursor(10, 30);
  display.println("Connect App to:");
  display.setCursor(10, 45);
  display.println("Smart_AI_Alarm");
  display.display();
}

void renderMainScreen() {
  display.clearDisplay();
  display.setTextColor(WHITE);

  if (isCloudResetPending) {
    display.drawRect(0, 0, 128, 64, WHITE);
    display.setTextSize(2);
    display.setCursor(15, 5);
    display.print("APP RESET");
    
    display.setTextSize(1);
    display.setCursor(10, 25);
    display.print("Press Btn to Cancel");
    
    int timeLeft = 10 - ((millis() - cloudResetStartTime) / 1000);
    if (timeLeft < 0) timeLeft = 0; 
    
    display.setCursor(20, 45);
    display.print("Wiping in: ");
    display.print(timeLeft);
    display.print("s");
  }
  else if (isResetPending) {
    display.drawRect(0, 0, 128, 64, WHITE);
    display.setTextSize(2);
    display.setCursor(30, 5);
    display.print("RESET?");
    
    display.setTextSize(1);
    display.setCursor(15, 25);
    display.print("Press 2x to Confirm");
    
    int timeLeft = 10 - ((millis() - resetPendingStartTime) / 1000);
    if (timeLeft < 0) timeLeft = 0; 
    
    display.setCursor(20, 45);
    display.print("Auto Cancel: ");
    display.print(timeLeft);
    display.print("s");
  } 
  else if (isMenuMode) {
    display.setTextSize(1);
    display.setCursor(15, 5);
    display.print("--- SOUND MENU ---");
    
    display.setTextSize(2);
    String toneName = (selectedTone == 0) ? "1: CLASSIC" : "2: URGENT";
    
    int16_t x1, y1; uint16_t w, h;
    display.getTextBounds(toneName, 0, 0, &x1, &y1, &w, &h);
    display.setCursor((128 - w) / 2, 25);
    display.print(toneName);

    display.setTextSize(1);
    display.setCursor(20, 50);
    display.print("Hold 5s to Save");
  } 
  else {
    if (currentAlarmState == RINGING) {
      display.setTextSize(2);
      display.setCursor(16, 10);
      display.print("WAKE UP!");
      display.setTextSize(3);
      display.setCursor(20, 35);
      display.print(currentTimeStr);
    } 
    else {
      display.setTextSize(2);
      display.setCursor(0, 0);
      display.print(currentTimeStr);
      
      display.setTextSize(1);
      display.setCursor(65, 5);
      display.print(dateStr);
      
      display.drawFastHLine(0, 18, 128, WHITE);

      display.setCursor(0, 22);
      display.print("Temp : "); display.print(temperature, 1); display.print("C");
      
      display.setCursor(0, 32);
      display.print("Humid: "); display.print(humidity, 1); display.print("%");
      
      display.setCursor(0, 42);
      display.print("Light: "); display.print(lightStatus);
      
      display.setCursor(0, 52);
      display.print("Lamp : "); 
      display.print(isRelayActuallyOn ? "ON" : "OFF");
      
      display.setCursor(65, 52);
      if (atlasStatus == "WIFI LOST") display.print("NO WIFI");
      else display.print("SYNC OK");

      if (currentAlarmState == RESTING) {
        display.drawRect(75, 22, 53, 38, WHITE);
        display.setCursor(80, 36);
        display.print("SNOOZE");
      }
    }
  }
  display.display();
}