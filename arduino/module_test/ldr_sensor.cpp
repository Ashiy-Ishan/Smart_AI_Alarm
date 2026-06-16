#include <Wire.h>
#include <Adafruit_GFX.h>
#include <Adafruit_SSD1306.h>

// Pin
#define OLED_SDA 19
#define OLED_SCL 18
#define LDR_PIN   1

Adafruit_SSD1306 display(128, 64, &Wire, -1);

void setup() {
    Serial.begin(115200);
    analogReadResolution(10);

    Wire.begin(OLED_SDA, OLED_SCL);
    if(!display.begin(SSD1306_SWITCHCAPVCC, 0x3C)) {
        for(;;);
    }

    display.clearDisplay();
    display.setTextColor(WHITE);
    display.setTextSize(1);
}

void loop() {
    int ldrValue = analogRead(LDR_PIN);
    String status = "";

    // Logic for ldr values
    if (ldrValue < 5) {
        status = "DIRECT LIGHT";
    } else if (ldrValue < 300) {
        status = "BRIGHT";
    } else if (ldrValue >= 400 && ldrValue <= 700) {
        status = "DIM";
    } else if (ldrValue > 700) {
        status = "DARK";
    } else {
        status = "TRANSITIONING";
    }

    // Display status
    display.clearDisplay();

    display.setCursor(0, 0);
    display.setTextSize(1);
    display.println("LDR TEST (0-1023)");

    display.setCursor(0, 25);
    display.setTextSize(2);
    display.print("VAL: ");
    display.println(ldrValue);

    display.setCursor(0, 50);
    display.setTextSize(1);
    display.print("STATUS: ");
    display.print(status);

    display.display();

    // serial print
    Serial.print("Value: ");
    Serial.print(ldrValue);
    Serial.print(" | Status: ");
    Serial.println(status);

    delay(500);
}