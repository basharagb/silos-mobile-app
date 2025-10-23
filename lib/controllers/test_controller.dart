import 'dart:async';
import 'package:flutter/material.dart';
import '../services/api_service.dart';

enum TestMode { none, manual, auto }

class TestController extends ChangeNotifier {
  // Test state
  TestMode _currentMode = TestMode.none;
  bool _isRunning = false;
  int? _currentSilo;
  double _progress = 0.0;
  String _status = 'Ready';
  
  // Auto test configuration
  final List<int> _allSilos = List.generate(195, (index) => index + 1);
  int _currentSiloIndex = 0;
  Timer? _testTimer;
  Timer? _progressTimer;
  
  // Manual test configuration
  static const int manualTestDuration = 3; // 3 seconds
  static const int autoTestDuration = 24; // 24 seconds per silo
  
  // Disconnected silos tracking
  final List<int> _disconnectedSilos = [];
  int _retryCount = 0;
  static const int maxRetries = 3;
  bool _isRetryPhase = false;

  // Getters
  TestMode get currentMode => _currentMode;
  bool get isRunning => _isRunning;
  int? get currentSilo => _currentSilo;
  double get progress => _progress;
  String get status => _status;
  List<int> get disconnectedSilos => List.unmodifiable(_disconnectedSilos);
  int get retryCount => _retryCount;
  bool get isRetryPhase => _isRetryPhase;

  /// Start manual test for a specific silo
  Future<void> startManualTest(int siloNumber) async {
    if (_isRunning) return;

    _currentMode = TestMode.manual;
    _isRunning = true;
    _currentSilo = siloNumber;
    _progress = 0.0;
    _status = 'Manual test running...';
    notifyListeners();

    // Start progress animation
    _startProgressAnimation(manualTestDuration);

    try {
      // Fetch real sensor data during test
      final sensorData = await ApiService.getSiloSensorData(siloNumber);
      
      // Wait for test duration
      await Future.delayed(Duration(seconds: manualTestDuration));
      
      _status = sensorData != null 
          ? 'Manual test completed - Max temp: ${sensorData.maxTemp.toStringAsFixed(1)}°C'
          : 'Manual test completed - No data received';
      
    } catch (e) {
      _status = 'Manual test failed: $e';
    }

    _stopTest();
  }

  /// Start auto test for all silos
  Future<void> startAutoTest() async {
    if (_isRunning) return;

    _currentMode = TestMode.auto;
    _isRunning = true;
    _currentSiloIndex = 0;
    _progress = 0.0;
    _disconnectedSilos.clear();
    _retryCount = 0;
    _isRetryPhase = false;
    _status = 'Auto test starting...';
    notifyListeners();

    await _runAutoTestCycle();
  }

  /// Run the main auto test cycle
  Future<void> _runAutoTestCycle() async {
    for (int i = _currentSiloIndex; i < _allSilos.length; i++) {
      if (!_isRunning) break;

      _currentSilo = _allSilos[i];
      _currentSiloIndex = i;
      _progress = (i / _allSilos.length) * 100;
      _status = 'Testing silo $_currentSilo (${i + 1}/${_allSilos.length})';
      notifyListeners();

      // Start progress animation for this silo
      _startProgressAnimation(autoTestDuration);

      try {
        // Fetch sensor data for current silo
        final sensorData = await ApiService.getSiloSensorData(_currentSilo!);
        
        if (sensorData == null || _isSiloDisconnected(sensorData)) {
          _disconnectedSilos.add(_currentSilo!);
          print('Silo $_currentSilo is disconnected');
        }

        // Wait for test duration
        await Future.delayed(Duration(seconds: autoTestDuration));
        
      } catch (e) {
        _disconnectedSilos.add(_currentSilo!);
        print('Error testing silo $_currentSilo: $e');
      }
    }

    // Handle disconnected silos with retry mechanism
    if (_disconnectedSilos.isNotEmpty && _retryCount < maxRetries) {
      await _startRetryPhase();
    } else {
      _completeAutoTest();
    }
  }

  /// Start retry phase for disconnected silos
  Future<void> _startRetryPhase() async {
    _isRetryPhase = true;
    _retryCount++;
    _status = 'Retry phase $_retryCount/$maxRetries - ${_disconnectedSilos.length} disconnected silos';
    notifyListeners();

    final silosToRetry = List<int>.from(_disconnectedSilos);
    _disconnectedSilos.clear();

    for (int i = 0; i < silosToRetry.length; i++) {
      if (!_isRunning) break;

      final siloNumber = silosToRetry[i];
      _currentSilo = siloNumber;
      _progress = 100 + (_retryCount - 1) * 10 + ((i + 1) / silosToRetry.length) * 10;
      _status = 'Retry $_retryCount: Testing silo $siloNumber (${i + 1}/${silosToRetry.length})';
      notifyListeners();

      try {
        final sensorData = await ApiService.getSiloSensorData(siloNumber);
        
        if (sensorData == null || _isSiloDisconnected(sensorData)) {
          _disconnectedSilos.add(siloNumber);
        }

        // Shorter duration for retries
        await Future.delayed(const Duration(seconds: 12));
        
      } catch (e) {
        _disconnectedSilos.add(siloNumber);
      }
    }

    // Check if we need another retry
    if (_disconnectedSilos.isNotEmpty && _retryCount < maxRetries) {
      await _startRetryPhase();
    } else {
      _completeAutoTest();
    }
  }

  /// Complete the auto test
  void _completeAutoTest() {
    _progress = 100.0;
    _isRetryPhase = false;
    
    if (_disconnectedSilos.isEmpty) {
      _status = 'Auto test completed successfully - All silos connected';
    } else {
      _status = 'Auto test completed - ${_disconnectedSilos.length} silos remain disconnected';
    }
    
    _stopTest();
  }

  /// Check if a silo is disconnected based on sensor data
  bool _isSiloDisconnected(SiloSensorData sensorData) {
    // Check if silo color is gray (disconnected)
    if (sensorData.siloColor == '#9ca3af' || sensorData.siloColor == '#8c9494') {
      return true;
    }
    
    // Check if all sensors are zero or invalid
    final validSensors = sensorData.sensors.where((temp) => temp > 0 && temp != -127.0).toList();
    return validSensors.isEmpty;
  }

  /// Start progress animation
  void _startProgressAnimation(int durationSeconds) {
    _progressTimer?.cancel();
    
    const updateInterval = Duration(milliseconds: 100);
    final totalUpdates = (durationSeconds * 1000) / updateInterval.inMilliseconds;
    int currentUpdate = 0;

    _progressTimer = Timer.periodic(updateInterval, (timer) {
      if (!_isRunning) {
        timer.cancel();
        return;
      }

      currentUpdate++;
      final siloProgress = (currentUpdate / totalUpdates) * 100;
      
      if (_currentMode == TestMode.auto) {
        final baseProgress = (_currentSiloIndex / _allSilos.length) * 100;
        final siloContribution = (1 / _allSilos.length) * 100;
        _progress = baseProgress + (siloProgress / 100) * siloContribution;
      } else {
        _progress = siloProgress;
      }
      
      notifyListeners();

      if (currentUpdate >= totalUpdates) {
        timer.cancel();
      }
    });
  }

  /// Stop current test
  void stopTest() {
    _stopTest();
  }

  void _stopTest() {
    _isRunning = false;
    _currentSilo = null;
    _testTimer?.cancel();
    _progressTimer?.cancel();
    
    if (_currentMode != TestMode.auto || _progress >= 100) {
      _currentMode = TestMode.none;
      _progress = 0.0;
    }
    
    notifyListeners();
  }

  /// Toggle manual test mode
  void toggleManualMode() {
    if (_currentMode == TestMode.manual) {
      _currentMode = TestMode.none;
      _status = 'Manual mode disabled';
    } else {
      _stopTest();
      _currentMode = TestMode.manual;
      _status = 'Manual mode enabled - Click silos to test';
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _testTimer?.cancel();
    _progressTimer?.cancel();
    super.dispose();
  }
}
