#include "SoundEngine.h"
#include "Config.h"

// --- TONE: Smooth Alarm Beep ---
const int melody[] = {
  500, 0, 500, 0, 500, 0
};
const int durations[] = {
  10, 10, 10, 10, 10, 100
};
const int arrayLength = 6;

void playTonePattern(unsigned long currentMillis, bool stopTone) {
  static int currentNote = 0;
  static unsigned long noteStartTime = 0;
  static bool isPlayingNote = false;

  if (stopTone) {
    currentNote = 0; 
    noTone(SPEAKER_PIN);
    return;
  }

  int noteDuration = durations[currentNote];

  if (currentMillis - noteStartTime >= noteDuration) {
    currentNote++;
    if (currentNote >= arrayLength) currentNote = 0;
    noteStartTime = currentMillis;
    isPlayingNote = false;
  }

  if (!isPlayingNote) {
    int pitch = melody[currentNote];
    if (pitch > 0) {
      tone(SPEAKER_PIN, pitch);
    } else {
      noTone(SPEAKER_PIN);
    }
    isPlayingNote = true;
  }
}
