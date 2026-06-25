#include "SoundEngine.h"
#include "Config.h"

const int melody0[] = {1000, 1200, 1000, 1200};
const int durations0[] = {100, 100, 100, 100, 100, 500};

const int melody1[] = {1500, 1700, 1900, 2100};
const int durations1[] = {80, 80, 80, 80, 80, 80, 80, 80};

const int* const melodies[] = {melody0, melody1};
const int* const durations[] = {durations0, durations1};
const int arrayLengths[] = {4, 4};

void playTonePattern(int toneIndex, unsigned long currentMillis, int level, bool stopTone) {
  static int lastToneIndex = -1;
  static int currentNote = 0;
  static unsigned long noteStartTime = 0;
  static bool isPlayingNote = false;

  if (stopTone) {
    lastToneIndex = -1;
    noTone(SPEAKER_PIN);
    return;
  }

  if (toneIndex < 0) toneIndex = 0;
  if (toneIndex > 1) toneIndex = 1;

  if (toneIndex != lastToneIndex) {
    lastToneIndex = toneIndex;
    currentNote = 0;
    noteStartTime = currentMillis;
    isPlayingNote = false;
  }

  const int* melody = melodies[toneIndex];
  const int* durationArray = durations[toneIndex];
  int len = arrayLengths[toneIndex];
  int totalSteps = len + 1;
  int noteDuration = durationArray[currentNote];

  if (currentMillis - noteStartTime >= noteDuration) {
    currentNote++;
    if (currentNote >= totalSteps) currentNote = 0; 
    noteStartTime = currentMillis;
    isPlayingNote = false;
  }

  if (!isPlayingNote) {
    if (currentNote >= len) {
      noTone(SPEAKER_PIN); 
    } else {
      int pitch = melody[currentNote];
      int shiftedPitch = pitch + ((level - 5) * 150); 
      if (shiftedPitch < 100) shiftedPitch = 100;
      tone(SPEAKER_PIN, shiftedPitch);
    }
    isPlayingNote = true;
  } 
  else if (currentNote < len && (currentMillis - noteStartTime >= (noteDuration - 20))) {
    noTone(SPEAKER_PIN);
  }
}