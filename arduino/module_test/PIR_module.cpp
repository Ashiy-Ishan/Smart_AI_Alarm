#define PIR_PIN 13   // Pin D13
#define LDR_PIN 1    // Pin GPIO 1

void setup() {
  Serial.begin(115200);
  pinMode(PIR_PIN, INPUT);
}

void loop() {
  int motion = digitalRead(PIR_PIN);
  int lightLevel = analogRead(LDR_PIN);

  Serial.print("Light Level: "); Serial.print(lightLevel);
  if (motion == HIGH) {
    Serial.println(" | MOTION DETECTED!");
  } else {
    Serial.println(" | No Motion.");
  }
  delay(500);
}
