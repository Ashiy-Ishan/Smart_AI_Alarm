#include "SoundEngine.h"
#include "Config.h"

// --- TONE 0: Gentle Sunrise ---
// A rising melodic sequence using a major pentatonic scale
const int melody0[] = {
  262, 330, 392, 440, 523, // C4, E4, G4, A4, C5
  523, 440, 392, 330, 262  // Descending
};
const int durations0[] = {
  300, 300, 300, 300, 600, // Rising
  300, 300, 300, 300, 1000 // Descending + Pause
};

// --- TONE 1: Digital Arpeggio ---
// A faster, more urgent "tech" sound
const int melody1[] = {
  880, 1318, 1760, 1318, // A5, E6, A6, E6
  880, 1318, 1760, 1318  // Repeat
};
const int durations1[] = {
  100, 100, 100, 100,
  100, 100, 100, 300 // Short pause at end
};

// --- TONE 2: Agent Sound Track (Urgent) ---
const int melody2[] = {
  1500, 1200, 1500, 1200, 2000, 2000, 1000
};
const int durations2[] = {
  150, 150, 150, 150, 200, 200, 500
};

const int* const melodies[] = {melody0, melody1, melody2};
const int* const durations[] = {durations0, durations1, durations2};
const int arrayLengths[] = {10, 8, 7};

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
  if (toneIndex > 2) toneIndex = 2;

  if (toneIndex != lastToneIndex) {
    lastToneIndex = toneIndex;
    currentNote = 0;
    noteStartTime = currentMillis;
    isPlayingNote = false;
  }

  const int* melody = melodies[toneIndex];
  const int* durationArray = durations[toneIndex];
  int len = arrayLengths[toneIndex];
  int totalSteps = len; // Removed the +1 for blank pause as I handled it in durations
  int noteDuration = durationArray[currentNote];

  if (currentMillis - noteStartTime >= noteDuration) {
    currentNote++;
    if (currentNote >= len) currentNote = 0;
    noteStartTime = currentMillis;
    isPlayingNote = false;
  }

  if (!isPlayingNote) {
    int pitch = melody[currentNote];
    // Scale pitch based on SoundLevel (1-10 range)
    int shiftedPitch = pitch + ((level - 5) * 50);
    if (shiftedPitch < 50) shiftedPitch = 50;

    tone(SPEAKER_PIN, shiftedPitch);
    isPlayingNote = true;
  } 
  else if (currentMillis - noteStartTime >= (noteDuration - 10)) {
    // Small gap between notes for clarity
    noTone(SPEAKER_PIN);
  }
}
