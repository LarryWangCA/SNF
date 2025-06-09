//Name: SNF app
//Author: Liwei Wang
// Try to solve the unstable issue with buffer protection (failed right now)
// Unstable issue seems Rode AI micro related

import 'dart:async';
import 'dart:typed_data';
import 'dart:math';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:collection';

enum AppMode { debug, test }

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Real-Time Coherence and SNR Display',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const SettingsPage(), // Start with the settings page
    );
  }
}

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  SettingsPageState createState() => SettingsPageState();
}

class SettingsPageState extends State<SettingsPage> {
  // Controllers for text fields
  final _cohrThresholdController = TextEditingController();
  final _varDBThresholdController = TextEditingController();
  final _alarmThresholdController = TextEditingController();
  final _alarmCounterController = TextEditingController();

  // Focus nodes
  final _cohrThresholdFocusNode = FocusNode();
  final _varDBThresholdFocusNode = FocusNode();
  final _alarmThresholdFocusNode = FocusNode();
  final _alarmCounterFocusNode = FocusNode();

  // Default values
  double defaultCohrThreshold = 0.4;
  double defaultVarDBThreshold = -32.0;
  double defaultAlarmThreshold = 20.0;
  int defaultAlarmCounter = 10;
  AppMode _selectedMode = AppMode.debug; // Default to Debug mode

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _setupFocusListeners();
  }

  @override
  void dispose() {
    // Dispose controllers and focus nodes
    _cohrThresholdController.dispose();
    _varDBThresholdController.dispose();
    _alarmThresholdController.dispose();
    _alarmCounterController.dispose();

    _cohrThresholdFocusNode.dispose();
    _varDBThresholdFocusNode.dispose();
    _alarmThresholdFocusNode.dispose();
    _alarmCounterFocusNode.dispose();

    super.dispose();
  }

  Future<void> _loadSettings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    setState(() {
      _cohrThresholdController.text =
          (prefs.getDouble('cohrThreshold') ?? defaultCohrThreshold).toString();
      _varDBThresholdController.text =
          (prefs.getDouble('varDBThreshold') ?? defaultVarDBThreshold)
              .toString();
      _alarmThresholdController.text =
          (prefs.getDouble('alarmThreshold') ?? defaultAlarmThreshold)
              .toString();
      _alarmCounterController.text =
          (prefs.getInt('alarmCounter') ?? defaultAlarmCounter).toString();
      int modeIndex = prefs.getInt('selectedMode') ?? 0;
      _selectedMode = AppMode.values[modeIndex];
    });
  }

  Future<void> _saveSettings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(
        'cohrThreshold', double.parse(_cohrThresholdController.text));
    await prefs.setDouble(
        'varDBThreshold', double.parse(_varDBThresholdController.text));
    await prefs.setDouble(
        'alarmThreshold', double.parse(_alarmThresholdController.text));
    await prefs.setInt('alarmCounter', int.parse(_alarmCounterController.text));
    await prefs.setInt('selectedMode', _selectedMode.index);
  }

  void _setupFocusListeners() {
    _cohrThresholdFocusNode.addListener(() {
      if (!_cohrThresholdFocusNode.hasFocus) {
        _clampAndCorrectValues();
      }
    });
    _varDBThresholdFocusNode.addListener(() {
      if (!_varDBThresholdFocusNode.hasFocus) {
        _clampAndCorrectValues();
      }
    });
    _alarmThresholdFocusNode.addListener(() {
      if (!_alarmThresholdFocusNode.hasFocus) {
        _clampAndCorrectValues();
      }
    });
    _alarmCounterFocusNode.addListener(() {
      if (!_alarmCounterFocusNode.hasFocus) {
        _clampAndCorrectValues();
      }
    });
  }

  void _clampAndCorrectValues() {
    setState(() {
      double cohrThreshold = (double.tryParse(_cohrThresholdController.text) ??
              defaultCohrThreshold)
          .clamp(0.0, 1.0);
      double varDBThreshold =
          (double.tryParse(_varDBThresholdController.text) ??
                  defaultVarDBThreshold)
              .clamp(-100.0, 0.0);
      double alarmThreshold =
          (double.tryParse(_alarmThresholdController.text) ??
                  defaultAlarmThreshold)
              .clamp(-100.0, 100.0);
      int alarmCounter =
          (int.tryParse(_alarmCounterController.text) ?? defaultAlarmCounter)
              .clamp(1, 1000);

      // Update controllers with clamped values
      _cohrThresholdController.text = cohrThreshold.toString();
      _varDBThresholdController.text = varDBThreshold.toString();
      _alarmThresholdController.text = alarmThreshold.toString();
      _alarmCounterController.text = alarmCounter.toString();

      _saveSettings(); // Save settings when values are clamped and corrected
    });
  }

  void _startRecording() {
    _clampAndCorrectValues(); // Ensure values are valid before starting

    // Parse the parameters
    double cohrThreshold = double.parse(_cohrThresholdController.text);
    double varDBThreshold = double.parse(_varDBThresholdController.text);
    double alarmThreshold = double.parse(_alarmThresholdController.text);
    int alarmCounter = int.parse(_alarmCounterController.text);

    // Navigate to DisplayPage and pass parameters
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DisplayPage(
          cohrThreshold: cohrThreshold,
          varDBThreshold: varDBThreshold,
          alarmThreshold: alarmThreshold,
          alarmCounter: alarmCounter,
          mode: _selectedMode,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: GestureDetector(
        behavior: HitTestBehavior
            .translucent, // Ensure the GestureDetector catches taps
        onTap: () {
          FocusScope.of(context).unfocus();
          _clampAndCorrectValues();
        },
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Quick Settings Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              // Set values for Silent mode
                              _cohrThresholdController.text = '0.4';
                              _varDBThresholdController.text = '-50';
                              _alarmThresholdController.text = '30';
                              _alarmCounterController.text = '10';
                              _clampAndCorrectValues();
                              _saveSettings();
                            });
                          },
                          child: const Text('Silent'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              // Set values for 65dB mode
                              _cohrThresholdController.text = '0.15';
                              _varDBThresholdController.text = '-34';
                              _alarmThresholdController.text = '12';
                              _alarmCounterController.text = '10';
                              _clampAndCorrectValues();
                              _saveSettings();
                            });
                          },
                          child: const Text('65dB'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              // Set values for 70dB mode
                              _cohrThresholdController.text = '0.15';
                              _varDBThresholdController.text = '-34';
                              _alarmThresholdController.text = '12';
                              _alarmCounterController.text = '10';
                              _clampAndCorrectValues();
                              _saveSettings();
                            });
                          },
                          child: const Text('70dB'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Coherence Threshold
                  TextField(
                    controller: _cohrThresholdController,
                    focusNode: _cohrThresholdFocusNode,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                    ],
                    decoration: InputDecoration(
                      labelText: 'Coherence Threshold',
                      hintText: defaultCohrThreshold.toString(),
                    ),
                  ),
                  // Variance Threshold in dB
                  TextField(
                    controller: _varDBThresholdController,
                    focusNode: _varDBThresholdFocusNode,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                          RegExp(r'^-?\d*\.?\d*')),
                    ],
                    decoration: InputDecoration(
                      labelText: 'Variance Threshold (dB)',
                      hintText: defaultVarDBThreshold.toString(),
                    ),
                  ),
                  // Alarm Threshold
                  TextField(
                    controller: _alarmThresholdController,
                    focusNode: _alarmThresholdFocusNode,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                          RegExp(r'^-?\d*\.?\d*')),
                    ],
                    decoration: InputDecoration(
                      labelText: 'Alarm Threshold (SNR in dB)',
                      hintText: defaultAlarmThreshold.toString(),
                    ),
                  ),
                  // Alarm Counter
                  TextField(
                    controller: _alarmCounterController,
                    focusNode: _alarmCounterFocusNode,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    decoration: InputDecoration(
                      labelText: 'Alarm Counter',
                      hintText: defaultAlarmCounter.toString(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Mode Selection
                  const Text(
                    'Select Mode:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  ListTile(
                    title: const Text('Debug Mode'),
                    leading: Radio<AppMode>(
                      value: AppMode.debug,
                      groupValue: _selectedMode,
                      onChanged: (AppMode? value) {
                        setState(() {
                          _selectedMode = value!;
                          _saveSettings(); // Save the mode selection
                        });
                      },
                    ),
                  ),
                  ListTile(
                    title: const Text('Test Mode'),
                    leading: Radio<AppMode>(
                      value: AppMode.test,
                      groupValue: _selectedMode,
                      onChanged: (AppMode? value) {
                        setState(() {
                          _selectedMode = value!;
                          _saveSettings(); // Save the mode selection
                        });
                      },
                    ),
                  ),

                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _startRecording,
                    child: const Text('Start Recording'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class DisplayPage extends StatefulWidget {
  final double cohrThreshold;
  final double varDBThreshold;
  final double alarmThreshold;
  final int alarmCounter;
  final AppMode mode;

  const DisplayPage({
    super.key,
    required this.cohrThreshold,
    required this.varDBThreshold,
    required this.alarmThreshold,
    required this.alarmCounter,
    required this.mode,
  });

  @override
  State<DisplayPage> createState() => _DisplayPageState();
}

class _DisplayPageState extends State<DisplayPage> {
  // ignore: prefer_final_fields
  FlutterSoundRecorder? _recorder = FlutterSoundRecorder();
  bool _isRecorderInitialized = false;
  bool _isRecording = false;
  bool _isRecorderReady =
      false; // New flag to indicate when to start processing
  StreamSubscription? _recorderSubscription;
  final List<double> _coherenceData = []; // For debugging
  final List<double> _dBData = []; // For debugging
  final List<double> _snrData = [];
  final Queue<double> _leftChannelData = Queue<double>();
  final Queue<double> _rightChannelData = Queue<double>();
  final int _sampleRate = 16000;
  final int _windowSizeSamples = 512; // Matching MATLAB code
  final int _nFFT = 512;
  late CoherenceCalculator _coherenceCalculator;

  // Variables for SNR estimation
  int _counter = 0;
  int _j = 0;
  int _ownCounter = 0;
  bool _initFlag = true;
  double _cohrAvgDisp = 0.0;
  late List<double> _leftBuffersSNR;
  late List<double> _rightBuffersSNR;
  List<double> _varLatest3Left = [5e-5, 5e-5, 5e-5];
  List<double> _varLatest3Right = [5e-5, 5e-5, 5e-5];
  double _varNoiseLeft = 4e-5;
  double _varNoiseRight = 4e-5;
  double _avgSNRMax = -20.0;
  int _beepCount = 0;

  // For playing beep as alarm
  // ignore: prefer_final_fields
  FlutterSoundPlayer _player = FlutterSoundPlayer();
  bool _beepPlayed = false; // Flag to prevent repeated beeps

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  void _initialize() async {
    await _player.openPlayer(); // Initialize the player
    await _openRecorder();
    _coherenceCalculator = CoherenceCalculator(
      sampleRate: _sampleRate,
      winSizeSamples: _windowSizeSamples,
      nFFT: _nFFT,
    );
    _leftBuffersSNR =
        List<double>.filled(_windowSizeSamples * 10, 0.0, growable: false);
    _rightBuffersSNR =
        List<double>.filled(_windowSizeSamples * 10, 0.0, growable: false);

    // Start recording after initialization
    _startRecording();
  }

  @override
  void dispose() {
    _recorderSubscription?.cancel();
    _recorder?.closeRecorder();
    _player.closePlayer(); // Close the audio session
    super.dispose();
  }

  Future<void> _openRecorder() async {
    if (!kIsWeb) {
      var status = await Permission.microphone.request();
      if (status != PermissionStatus.granted) {
        throw RecordingPermissionException('Microphone permission not granted');
      }
    }
    await _recorder!.openRecorder();
    setState(() {
      _isRecorderInitialized = true;
    });
  }

  Future<void> _playBeep() async {
    // Load the asset as ByteData
    ByteData bytes = await rootBundle.load('assets/beep.mp3');
    Uint8List soundData = bytes.buffer.asUint8List();

    await _player.startPlayer(
      fromDataBuffer: soundData,
      codec: Codec.mp3,
    );
  }

  void _startRecording() async {
    if (!_isRecorderInitialized || _recorder!.isRecording) return;

    // Initialize variables
    _leftChannelData.clear();
    _rightChannelData.clear();
    _coherenceData.clear();
    _dBData.clear();
    _snrData.clear();
    _cohrAvgDisp = 0.0;
    _counter = 0; //counter for accumulate to 10 windows
    _j = 0;
    _ownCounter = 0; //counter for OVD
    _initFlag = true;
    _avgSNRMax = -20.0;
    _beepCount = 0;

    // Initialize SNR buffers
    _leftBuffersSNR =
        List<double>.filled(_windowSizeSamples * 10, 0.0, growable: false);
    _rightBuffersSNR =
        List<double>.filled(_windowSizeSamples * 10, 0.0, growable: false);
    _varLatest3Left = [5e-5, 5e-5, 5e-5];
    _varLatest3Right = [5e-5, 5e-5, 5e-5];
    _varNoiseLeft = 4e-5;
    _varNoiseRight = 4e-5;

    // Set recorder ready flag to false
    _isRecorderReady = false;

    // Wait for 5 seconds before setting the recorder as ready
    Future.delayed(const Duration(seconds: 5), () {
      setState(() {
        _isRecorderReady = true;
      });
      //print('Recorder is now ready.');
    });

    StreamController<Uint8List> recordingDataController = StreamController();

    _recorderSubscription = recordingDataController.stream.listen((buffer) {
      _processAudioBuffer(buffer);
    });

    await _recorder!.startRecorder(
      toStream: recordingDataController.sink,
      codec: Codec.pcm16,
      numChannels: 2,
      sampleRate: _sampleRate,
      bitRate: 512000,
    );

    setState(() {
      _isRecording = true;
    });
  }

  void _stopRecording() async {
    if (!_recorder!.isRecording) return;

    await _recorder!.stopRecorder();
    _recorderSubscription?.cancel();
    _recorderSubscription = null;

    setState(() {
      _isRecording = false;
    });
  }

  //Original buffer processing logic, works but not stable
  void _processAudioBuffer(Uint8List data) {
    if (!_isRecorderReady) {
      // Skip processing until the recorder is ready
      return;
    }

    try {
      ByteData byteData = ByteData.sublistView(data);

      int numBytes = byteData.lengthInBytes;
      if (numBytes % 4 != 0) {
        //print('Warning: Incomplete audio frame received.');
        numBytes -= numBytes % 4; // Adjust to nearest multiple of 4
      }

      for (int i = 0; i < numBytes; i += 4) {
        int sampleLeft = byteData.getInt16(i, Endian.little);
        int sampleRight = byteData.getInt16(i + 2, Endian.little);

        _leftChannelData.addLast(sampleLeft / 32768.0);
        _rightChannelData.addLast(sampleRight / 32768.0);
      }

      const int requiredSamples = 512; // _windowSizeSamples
      const int maxBufferSize = 2048; // Define a maximum buffer size

      // Protection against buffer overrun
      if (_leftChannelData.length > maxBufferSize) {
        //print('Left channel buffer overrun. Clearing buffer.');
        _leftChannelData.clear();
      }

      if (_rightChannelData.length > maxBufferSize) {
        //print('Right channel buffer overrun. Clearing buffer.');
        _rightChannelData.clear();
      }

      while (_leftChannelData.length >= requiredSamples &&
          _rightChannelData.length >= requiredSamples) {
        // Extract windowed data
        List<double> leftWindow =
            _leftChannelData.take(requiredSamples).toList();
        List<double> rightWindow =
            _rightChannelData.take(requiredSamples).toList();

        // Ensure we have the required number of samples
        if (leftWindow.length != requiredSamples ||
            rightWindow.length != requiredSamples) {
          //print('Insufficient samples for processing.');
          break; // Wait for more data
        }

        // Apply high-pass filter at 100 Hz to the current window
        List<double> filteredLeft = _coherenceCalculator.applyHighPassFilter(
            leftWindow, _coherenceCalculator.filterStateLeft);
        List<double> filteredRight = _coherenceCalculator.applyHighPassFilter(
            rightWindow, _coherenceCalculator.filterStateRight);

        // Calculate coherence
        double coherence = _coherenceCalculator.calculateCoherence(
            filteredLeft, filteredRight);
        _cohrAvgDisp += coherence;
        _counter++;

        // Accumulate buffers for SNR estimation
        int startIdx = (_counter - 1) * requiredSamples;
        int endIdx = startIdx + requiredSamples;

        // Ensure indices are within bounds
        if (startIdx >= 0 &&
            endIdx <= _leftBuffersSNR.length &&
            filteredLeft.length == requiredSamples &&
            filteredRight.length == requiredSamples) {
          _leftBuffersSNR.setRange(startIdx, endIdx, filteredLeft);
          _rightBuffersSNR.setRange(startIdx, endIdx, filteredRight);
        } else {
          //print(
          //    'SNR buffer index out of bounds or filtered data length mismatch.');
          // Handle error or skip this iteration
          break;
        }

        if (_counter == 10) {
          double cohrAvgDispUse = _cohrAvgDisp / 10.0;
          _cohrAvgDisp = 0.0;

          if (_initFlag) {
            _initFlag = false;
            _varNoiseLeft = 4e-5;
            _varNoiseRight = 4e-5;
          }

          _j++; // alarm counting related
          // Calculate variance
          double varLeft = _calculateVariance(_leftBuffersSNR);
          double varRight = _calculateVariance(_rightBuffersSNR);

          // Update latest variances
          _varLatest3Left.removeAt(0);
          _varLatest3Left.add(varLeft);
          _varLatest3Right.removeAt(0);
          _varLatest3Right.add(varRight);

          // Calculate variance in dB
          double epsilon = 1e-10; // To avoid log(0)
          double varLeftDB = 10 * log(varLeft + epsilon) / ln10;
          double varRightDB = 10 * log(varRight + epsilon) / ln10;
          double avgDB = (varLeftDB + varRightDB) / 2.0;

          double snrLeft = -20.0;
          double snrRight = -20.0;

          if (cohrAvgDispUse >= widget.cohrThreshold &&
              avgDB >= widget.varDBThreshold &&
              varLeft >= _varNoiseLeft &&
              varRight >= _varNoiseRight) {
            snrLeft = 10 *
                log((varLeft - _varNoiseLeft + epsilon) /
                    (_varNoiseLeft + epsilon)) /
                ln10;
            snrRight = 10 *
                log((varRight - _varNoiseRight + epsilon) /
                    (_varNoiseRight + epsilon)) /
                ln10;
            _ownCounter = 0;
          } else if (_ownCounter < 3) {
            _ownCounter++;
            snrLeft = -20.0;
            snrRight = -20.0;
          } else {
            _varNoiseLeft = _varLatest3Left.reduce(min);
            _varNoiseRight = _varLatest3Right.reduce(min);
            snrLeft = -20.0;
            snrRight = -20.0;
            _ownCounter = 0;
          }

          double avgSNR = (snrLeft + snrRight) / 2.0;

          // Update max SNR
          if (_avgSNRMax < avgSNR) {
            _avgSNRMax = avgSNR;
          }

          // Alarm handling
          if (_j % widget.alarmCounter == 0) {
            if (_avgSNRMax > -20 && _avgSNRMax <= widget.alarmThreshold) {
              // Trigger alarm
              if (!_beepPlayed) {
                _playBeep();
                _beepPlayed = true;
                _beepCount++;
              } else {
                _beepPlayed = false;
              }
            }
            _avgSNRMax = -20.0;
            _j = 0;
          }

          // Update UI
          setState(() {
            _coherenceData.add(cohrAvgDispUse);
            _snrData.add(avgSNR);
            _dBData.add(avgDB);

            // Keep only the latest 100 values for display
            if (_coherenceData.length > 100) {
              _coherenceData.removeRange(0, _coherenceData.length - 100);
            }
            if (_snrData.length > 100) {
              _snrData.removeRange(0, _snrData.length - 100);
            }
            if (_dBData.length > 100) {
              _dBData.removeRange(0, _dBData.length - 100);
            }
          });

          // Reset counter
          _counter = 0;
        }

        // Remove used samples from the queues
        for (int i = 0; i < requiredSamples; i++) {
          _leftChannelData.removeFirst();
          _rightChannelData.removeFirst();
        }
      }
    } catch (e) {
      //print('Exception in _processAudioBuffer: $e');
      // Optionally handle the exception or log it
    }
  }

  double _calculateVariance(List<double> data) {
    int n = data.length;
    if (n < 2) return 0.0; // Prevent division by zero
    double mean = data.reduce((a, b) => a + b) / n;
    double variance =
        data.map((x) => pow(x - mean, 2)).reduce((a, b) => a + b) / (n - 1);
    return variance;
  }

  @override
  Widget build(BuildContext context) {
    String buttonText = _isRecording ? 'Stop' : 'Back';
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.mode == AppMode.debug
              ? 'Debug Mode Display'
              : 'Real-Time SNR Graph',
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              flex: 8,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: CustomPaint(
                  // Display graphs based on the selected mode
                  painter: widget.mode == AppMode.debug
                      ? DBGraphPainter(_dBData)
                      : SNRGraphPainter(_snrData),
                  child: Container(),
                ),
              ),
            ),
            if (widget.mode == AppMode.debug)
              Expanded(
                flex: 8,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: CustomPaint(
                    painter: CoherenceGraphPainter(_coherenceData),
                    child: Container(),
                  ),
                ),
              ),
            Expanded(
              flex: 2,
              child: Center(
                child: ElevatedButton(
                  onPressed: () {
                    if (_isRecording) {
                      _stopRecording();
                      // Navigate to SummaryPage after stopping the recording
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              SummaryPage(beepCount: _beepCount),
                        ),
                      );
                    } else {
                      Navigator.pop(context);
                    }
                  },
                  child: Text(buttonText),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CoherenceGraphPainter extends CustomPainter {
  final List<double> coherenceData;

  CoherenceGraphPainter(this.coherenceData);

  @override
  void paint(Canvas canvas, Size size) {
    Paint solidPaint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 2.0;

    Paint gridPaint = Paint()
      ..color = Colors.grey.withOpacity(0.3)
      ..strokeWidth = 1.0;

    TextPainter textPainter = TextPainter(
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );

    double maxValue = 1.0; // Coherence ranges from 0 to 1
    double leftMargin = 40.0; // Add a margin to the left

    // Draw grid lines and Y-axis labels
    for (double y = 0; y <= size.height; y += size.height / 5) {
      canvas.drawLine(Offset(leftMargin, y), Offset(size.width, y), gridPaint);
      String label =
          (maxValue - (y / size.height) * maxValue).toStringAsFixed(1);
      textPainter.text = TextSpan(
        text: label,
        style: const TextStyle(color: Colors.black, fontSize: 12),
      );
      textPainter.layout();
      textPainter.paint(
          canvas, Offset(leftMargin - 30, y - textPainter.height / 2));
    }

    // Draw Y-axis
    Paint axisPaint = Paint()
      ..color = Colors.black
      ..strokeWidth = 2.0;
    canvas.drawLine(
        Offset(leftMargin, 0), Offset(leftMargin, size.height), axisPaint);

    // Adjust the size for the grid to account for the left margin
    double adjustedWidth = size.width - leftMargin;

    // Draw coherence graph
    if (coherenceData.isNotEmpty) {
      double widthStep = adjustedWidth / coherenceData.length;

      for (int i = 0; i < coherenceData.length - 1; i++) {
        double x1 = leftMargin + i * widthStep;
        double y1 = size.height - (coherenceData[i] / maxValue * size.height);
        double x2 = leftMargin + (i + 1) * widthStep;
        double y2 =
            size.height - (coherenceData[i + 1] / maxValue * size.height);

        canvas.drawLine(Offset(x1, y1), Offset(x2, y2), solidPaint);
      }
    }

    // Title
    textPainter.text = const TextSpan(
      text: 'Coherence',
      style: TextStyle(color: Colors.black, fontSize: 16),
    );
    textPainter.layout();
    textPainter.paint(
        canvas, Offset(size.width / 2 - textPainter.width / 2, 0));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class DBGraphPainter extends CustomPainter {
  final List<double> dbData;

  DBGraphPainter(this.dbData);

  @override
  void paint(Canvas canvas, Size size) {
    Paint solidPaint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 2.0;

    Paint gridPaint = Paint()
      ..color = Colors.grey.withOpacity(0.3)
      ..strokeWidth = 1.0;

    TextPainter textPainter = TextPainter(
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );

    // Adjusted min and max values based on avgDB expected range
    double minValue = -100.0;
    double maxValue = 0.0;
    double valueRange = maxValue - minValue;
    double leftMargin = 40.0; // Add a margin to the left

    // Draw grid lines and Y-axis labels
    for (double y = 0; y <= size.height; y += size.height / 5) {
      canvas.drawLine(Offset(leftMargin, y), Offset(size.width, y), gridPaint);
      double value = maxValue - (y / size.height) * valueRange;
      String label = value.toStringAsFixed(1);
      textPainter.text = TextSpan(
        text: label,
        style: const TextStyle(color: Colors.black, fontSize: 12),
      );
      textPainter.layout();
      textPainter.paint(
          canvas, Offset(leftMargin - 35, y - textPainter.height / 2));
    }

    // Draw Y-axis
    Paint axisPaint = Paint()
      ..color = Colors.black
      ..strokeWidth = 2.0;
    canvas.drawLine(
        Offset(leftMargin, 0), Offset(leftMargin, size.height), axisPaint);

    // Adjust the size for the grid to account for the left margin
    double adjustedWidth = size.width - leftMargin;

    // Draw avgDB graph
    if (dbData.isNotEmpty) {
      double widthStep = adjustedWidth / dbData.length;

      for (int i = 0; i < dbData.length - 1; i++) {
        double x1 = leftMargin + i * widthStep;
        double y1 =
            size.height - ((dbData[i] - minValue) / valueRange * size.height);
        double x2 = leftMargin + (i + 1) * widthStep;
        double y2 = size.height -
            ((dbData[i + 1] - minValue) / valueRange * size.height);

        canvas.drawLine(Offset(x1, y1), Offset(x2, y2), solidPaint);
      }
    }

    // Title
    textPainter.text = const TextSpan(
      text: 'Avg Variance (dB)',
      style: TextStyle(color: Colors.black, fontSize: 16),
    );
    textPainter.layout();
    textPainter.paint(
        canvas, Offset(size.width / 2 - textPainter.width / 2, 0));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Custom painter for displaying SNR graph
class SNRGraphPainter extends CustomPainter {
  final List<double> snrData;

  SNRGraphPainter(this.snrData);

  @override
  void paint(Canvas canvas, Size size) {
    Paint solidPaint = Paint()
      ..color = Colors.green
      ..strokeWidth = 2.0;

    Paint gridPaint = Paint()
      ..color = Colors.grey.withOpacity(0.3)
      ..strokeWidth = 1.0;

    TextPainter textPainter = TextPainter(
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );

    double minValue = -20.0; // Minimum SNR value
    double maxValue = 40.0; // Maximum SNR value
    double valueRange = maxValue - minValue;
    double leftMargin = 40.0; // Add a margin to the left

    // Draw grid lines and Y-axis labels
    for (double y = 0; y <= size.height; y += size.height / 6) {
      canvas.drawLine(Offset(leftMargin, y), Offset(size.width, y), gridPaint);
      double value = maxValue - (y / size.height) * valueRange;
      String label = value.toStringAsFixed(0);
      textPainter.text = TextSpan(
        text: label,
        style: const TextStyle(color: Colors.black, fontSize: 12),
      );
      textPainter.layout();
      textPainter.paint(
          canvas, Offset(leftMargin - 30, y - textPainter.height / 2));
    }

    // Draw Y-axis
    Paint axisPaint = Paint()
      ..color = Colors.black
      ..strokeWidth = 2.0;
    canvas.drawLine(
        Offset(leftMargin, 0), Offset(leftMargin, size.height), axisPaint);

    // Adjust the size for the grid to account for the left margin
    double adjustedWidth = size.width - leftMargin;

    // Draw SNR graph
    if (snrData.isNotEmpty) {
      double widthStep = adjustedWidth / snrData.length;

      for (int i = 0; i < snrData.length - 1; i++) {
        double x1 = leftMargin + i * widthStep;
        double y1 =
            size.height - ((snrData[i] - minValue) / valueRange * size.height);
        double x2 = leftMargin + (i + 1) * widthStep;
        double y2 = size.height -
            ((snrData[i + 1] - minValue) / valueRange * size.height);

        canvas.drawLine(Offset(x1, y1), Offset(x2, y2), solidPaint);
      }
    }

    // Title
    textPainter.text = const TextSpan(
      text: 'SNR (dB)',
      style: TextStyle(color: Colors.black, fontSize: 16),
    );
    textPainter.layout();
    textPainter.paint(
        canvas, Offset(size.width / 2 - textPainter.width / 2, 0));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class SummaryPage extends StatelessWidget {
  final int beepCount;

  const SummaryPage({super.key, required this.beepCount});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Summary'),
      ),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Number of alarms (beeps): $beepCount',
                style: const TextStyle(fontSize: 24),
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: () {
                  // Navigate back to the settings page
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                        builder: (context) => const SettingsPage()),
                    (Route<dynamic> route) => false,
                  );
                },
                child: const Text('Back to Settings'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// CoherenceCalculator class
class CoherenceCalculator {
  final int sampleRate;
  final int winSizeSamples; // Window size in samples
  final int nFFT; // FFT length

  CoherenceCalculator({
    required this.sampleRate,
    required this.winSizeSamples,
    required this.nFFT,
  });

  // High-pass filter coefficients (2nd-order Butterworth)
  final List<double> b = [
    0.97454364129458,
    -1.94908728258915,
    0.97454364129458
  ];
  final List<double> a = [
    1.00000000000000,
    -1.94867812998528,
    0.94930254674312
  ];

  // State variables for the filter
  List<double> filterStateLeft = [0.0, 0.0];
  List<double> filterStateRight = [0.0, 0.0];

  // Apply high-pass filter using filter (single-direction)
  List<double> applyHighPassFilter(
      List<double> signal, List<double> filterState) {
    List<double> filteredSignal = _filter(b, a, signal, filterState);
    return filteredSignal;
  }

  // Implement the filter function with state
  List<double> _filter(
      List<double> b, List<double> a, List<double> x, List<double> z) {
    int n = x.length;
    int nb = b.length;
    List<double> y = List<double>.filled(n, 0.0);
    List<double> zi = List<double>.from(z);

    for (int i = 0; i < n; i++) {
      double xi = x[i];
      double yi = b[0] * xi + zi[0];
      y[i] = yi;

      for (int j = 1; j < nb; j++) {
        if (j < nb) {
          double zj = (j < zi.length) ? zi[j] : 0.0;
          zi[j - 1] = b[j] * xi - a[j] * yi + zj;
        }
      }
    }

    // Update filter state
    for (int j = 0; j < zi.length; j++) {
      z[j] = zi[j];
    }

    return y;
  }

  // Method to calculate coherence for two buffers
  double calculateCoherence(
      List<double> filteredLeft, List<double> filteredRight) {
    // Prepare signals (zero-padding to nFFT)
    List<Complex> leftFFT = _computeFFT(filteredLeft, nFFT);
    List<Complex> rightFFT = _computeFFT(filteredRight, nFFT);

    // Compute spectra
    List<double> Sxx = List.filled(nFFT, 0.0);
    List<double> Syy = List.filled(nFFT, 0.0);
    List<Complex> Sxy = List.filled(nFFT, Complex(0.0, 0.0));

    for (int k = 0; k < nFFT; k++) {
      Complex X = leftFFT[k];
      Complex Y = rightFFT[k];
      Sxx[k] = X.abs() * X.abs(); // |X(k)|^2
      Syy[k] = Y.abs() * Y.abs(); // |Y(k)|^2
      Sxy[k] = X * Y.conjugate(); // Cross-spectrum
    }

    // Keep half of the spectrum
    int halfNFFT = nFFT ~/ 2;
    Sxx = Sxx.sublist(0, halfNFFT);
    Syy = Syy.sublist(0, halfNFFT);
    Sxy = Sxy.sublist(0, halfNFFT);

    // Compute coherence
    List<Complex> Cohr = List.filled(halfNFFT, Complex(0.0, 0.0));
    for (int k = 0; k < halfNFFT; k++) {
      Complex numerator = Sxy[k];
      double denominator = sqrt(Sxx[k]) * sqrt(Syy[k]);
      if (denominator != 0.0) {
        Cohr[k] = numerator / denominator;
      } else {
        Cohr[k] = Complex(0.0, 0.0);
      }
    }

    // Take average of real part between k = 4 to 31 (indices 3 to 30)
    int startIdx = 3; // MATLAB indices start at 1, Dart at 0
    int endIdx = 30;
    List<double> CohrReal =
        Cohr.sublist(startIdx, endIdx + 1).map((c) => c.real).toList();

    // Average the real parts over the selected frequency bins
    double CohrAvgDisp = CohrReal.reduce((a, b) => a + b) / CohrReal.length;

    return CohrAvgDisp;
  }

  // Compute FFT of a real-valued signal
  List<Complex> _computeFFT(List<double> signal, int nFFT) {
    // Zero-padding if necessary
    List<Complex> complexSignal = signal
        .map((e) => Complex(e, 0.0))
        .toList()
        .followedBy(
          List<Complex>.generate(
              nFFT - signal.length, (_) => Complex(0.0, 0.0)),
        )
        .toList();

    fft(complexSignal);
    return complexSignal;
  }

  // FFT function
  void fft(List<Complex> x) {
    int N = x.length;
    if (N <= 1) return;

    // Bit reversal permutation
    int bits = (log(N) / log(2)).round();
    for (int i = 0; i < N; i++) {
      int j = reverseBits(i, bits);
      if (j > i) {
        Complex temp = x[i];
        x[i] = x[j];
        x[j] = temp;
      }
    }

    // Cooley-Tukey FFT
    for (int size = 2; size <= N; size *= 2) {
      double angle = -2 * pi / size;
      Complex wPhaseStep = Complex(cos(angle), sin(angle));
      for (int k = 0; k < N; k += size) {
        Complex w = Complex(1.0, 0.0);
        for (int m = 0; m < size ~/ 2; m++) {
          Complex u = x[k + m];
          Complex t = w * x[k + m + size ~/ 2];
          x[k + m] = u + t;
          x[k + m + size ~/ 2] = u - t;
          w = w * wPhaseStep;
        }
      }
    }
  }

  // Helper function to reverse bits
  int reverseBits(int x, int bits) {
    int y = 0;
    for (int i = 0; i < bits; i++) {
      y = (y << 1) | (x & 1);
      x = x >> 1;
    }
    return y;
  }
}

class Complex {
  final double real;
  final double imag;

  Complex(this.real, this.imag);

  // Conjugate
  Complex conjugate() => Complex(real, -imag);

  // Magnitude
  double abs() => sqrt(real * real + imag * imag);

  // Addition
  Complex operator +(Complex other) =>
      Complex(real + other.real, imag + other.imag);

  // Subtraction
  Complex operator -(Complex other) =>
      Complex(real - other.real, imag - other.imag);

  // Multiplication
  Complex operator *(Complex other) => Complex(
        real * other.real - imag * other.imag,
        real * other.imag + imag * other.real,
      );

  // Division by a double
  Complex operator /(double other) => Complex(real / other, imag / other);
}
