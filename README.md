# Speech-to-Noise Ratio Feedback (SNF) App 
Description: A pure Flutter-based cross-platform (Android and IOS) app for SNF by using the Flutter 'Sound' package

Hardware: Rode AI Micro
          Sound Professionals MS-EHB-2
          Headphones with a 3.5mm jack

Usage: After compiling and installing the app on a mobile phone by using Android Studio, install the Rode Central Mobile app and make sure the Rode Micro Ai works under the stereo mode (0 gain, HPF applied(optional, can select 100Hz)) before launching the SNF app

V1.0 Descriptions: 
    Structure: 3-page circular offline system
    Settings page:
        Own voice detection (OVD) related:
        1) Coherence threshold: 0 to 1, can be obtained when using Debug Mode
        2) Variance threshold (dBFS): can be obtained when using Debug Mode
        Feedback related:
        1) Alarm threshold (SNR in dB): SNR threshold for triggering the feedback 
        2) Alarm counter: total window numbers for max SNR calculation
        
    Display page:
        Wait 5 seconds for system initialization
    Summary page;
        Display the total beeping times during one record
        
TODOs:
    1) May need optimization for low-end mobile phones
    2) The OVD method may need improvement

    
     
