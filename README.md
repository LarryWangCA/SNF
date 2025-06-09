# Speech-to-Noise Ratio Feedback (SNF) App

**Description**  
A pure Flutter-based cross-platform (Android & iOS) application that provides real-time speech-to-noise-ratio feedback, built with the Flutter `sound` package.

### Hardware
- **Audio interface:** RØDE AI-Micro  
- **Headset microphones:** Sound Professionals MS-EHB-2  
- **Monitoring:** Any headphones with a 3.5 mm jack

### Usage
1. Compile and install the app on your phone with Android Studio.  
2. Install the **RØDE Central Mobile** app and set the AI-Micro to **Stereo, 0 dB gain**, HPF 100 Hz *(optional)*.  
3. Launch the SNF app.

---

## v1.0 Features

### Structure
3-page circular **offline** workflow:

| Page | Notes |
|------|-------|
| **Settings** | Configure own-voice detection (OVD) and feedback thresholds. |
| **Display**  | Wait ~5 s for system initialisation; then live SNR & status. |
| **Summary**  | Shows total number of beeps generated during the session. |

### Settings parameters
- **Own-voice detection (OVD)**  
  1. *Coherence threshold* `0 – 1` (derive via Debug Mode)  
  2. *Variance threshold* (dBFS, derive via Debug Mode)
- **Feedback**  
  1. *Alarm threshold* (SNR dB) — triggers the beep  
  2. *Alarm counter* (window count for max-SNR calculation)

---

## TODO
1. Performance optimisation on low-end mobile devices  
2. Possible refinement of the OVD algorithm

    
     
