import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

enum AutoTestMode { none, manual, auto }

enum AutoTestPhase { scanning, retry }

class AutoTestState {
  final bool isActive;
  final int currentIndex;
  final double progress;
  final int startTime;
  final int? readingSilo;
  final List<int> disconnectedSilos;
  final int retryCount;
  final bool isRetryPhase;
  final int currentGroupIndex;

  AutoTestState({
    required this.isActive,
    required this.currentIndex,
    required this.progress,
    required this.startTime,
    this.readingSilo,
    this.disconnectedSilos = const [],
    this.retryCount = 0,
    this.isRetryPhase = false,
    this.currentGroupIndex = 0,
  });

  Map<String, dynamic> toJson() => {
    'isActive': isActive,
    'currentIndex': currentIndex,
    'progress': progress,
    'startTime': startTime,
    'readingSilo': readingSilo,
    'disconnectedSilos': disconnectedSilos,
    'retryCount': retryCount,
    'isRetryPhase': isRetryPhase,
    'currentGroupIndex': currentGroupIndex,
  };

  factory AutoTestState.fromJson(Map<String, dynamic> json) => AutoTestState(
    isActive: json['isActive'] ?? false,
    currentIndex: json['currentIndex'] ?? 0,
    progress: (json['progress'] ?? 0.0).toDouble(),
    startTime: json['startTime'] ?? 0,
    readingSilo: json['readingSilo'],
    disconnectedSilos: List<int>.from(json['disconnectedSilos'] ?? []),
    retryCount: json['retryCount'] ?? 0,
    isRetryPhase: json['isRetryPhase'] ?? false,
    currentGroupIndex: json['currentGroupIndex'] ?? 0,
  );
}

class AutoTestController extends ChangeNotifier {
  static const String _storageKey = 'silo_mobile_auto_test_state';
  static const int _maxRetries = 6;
  static const int _siloTestDuration = 24000; // 24 seconds per silo
  static const int _retryTestDuration = 12000; // 12 seconds for retries

  // Core state
  AutoTestMode _mode = AutoTestMode.none;
  bool _isRunning = false;
  int? _currentSilo;
  double _progress = 0.0;
  bool _isCompleted = false;
  int _currentGroupIndex = 0;
  
  // Auto test state
  List<int> _allSilos = [];
  int _currentSiloIndex = 0;
  List<int> _disconnectedSilos = [];
  int _retryCount = 0;
  bool _isRetryPhase = false;
  AutoTestPhase _phase = AutoTestPhase.scanning;
  
  // Timers
  Timer? _siloTimer;
  Timer? _progressTimer;
  
  // Silo groups for pagination (10 groups total)
  final List<List<List<int>>> _siloGroups = [
    // Group 1
    [
      [11, 7, 3],
      [10, 8, 6, 4, 2],
      [9, 5, 1],
    ],
    // Group 2
    [
      [22, 18, 14],
      [21, 19, 17, 15, 13],
      [20, 16, 12],
    ],
    // Group 3
    [
      [33, 29, 25],
      [32, 30, 28, 26, 24],
      [31, 27, 23],
    ],
    // Group 4
    [
      [44, 40, 36],
      [43, 41, 39, 37, 35],
      [42, 38, 34],
    ],
    // Group 5
    [
      [55, 51, 47],
      [54, 52, 50, 48, 46],
      [53, 49, 45],
    ],
    // Group 6
    [
      [119, 112, 105],
      [118, 114, 111, 107, 104],
      [117, 110, 103],
      [116, 113, 109, 106, 102],
      [115, 108, 101],
    ],
    // Group 7
    [
      [138, 131, 124],
      [137, 133, 130, 126, 123],
      [136, 129, 122],
      [135, 132, 128, 125, 121],
      [134, 127, 120],
    ],
    // Group 8
    [
      [157, 150, 143],
      [156, 152, 149, 145, 142],
      [155, 148, 141],
      [154, 151, 147, 144, 140],
      [153, 146, 139],
    ],
    // Group 9
    [
      [176, 169, 162],
      [175, 171, 168, 164, 161],
      [174, 167, 160],
      [173, 170, 166, 163, 159],
      [172, 165, 158],
    ],
    // Group 10
    [
      [195, 188, 181],
      [194, 190, 187, 183, 180],
      [193, 186, 179],
      [192, 189, 185, 182, 178],
      [191, 184, 177],
    ],
  ];

  // Getters
  AutoTestMode get mode => _mode;
  bool get isRunning => _isRunning;
  int? get currentSilo => _currentSilo;
  double get progress => _progress;
  bool get isCompleted => _isCompleted;
  int get currentGroupIndex => _currentGroupIndex;
  List<int> get disconnectedSilos => List.unmodifiable(_disconnectedSilos);
  int get retryCount => _retryCount;
  bool get isRetryPhase => _isRetryPhase;
  AutoTestPhase get phase => _phase;
  int get maxRetries => _maxRetries;
  int get totalSilos => _allSilos.length;
  int get totalGroups => _siloGroups.length;

  // Get current group silos
  List<int> getCurrentGroupSilos() {
    if (_currentGroupIndex >= _siloGroups.length) return [];
    return _siloGroups[_currentGroupIndex].expand((row) => row).toList();
  }

  // Get all silos from all groups
  List<int> getAllSilos() {
    return _siloGroups.expand((group) => group.expand((row) => row)).toList();
  }

  // Initialize controller
  Future<void> initialize() async {
    _allSilos = getAllSilos();
    await _loadState();
  }

  // Save state to persistent storage
  Future<void> _saveState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final state = AutoTestState(
        isActive: _isRunning,
        currentIndex: _currentSiloIndex,
        progress: _progress,
        startTime: DateTime.now().millisecondsSinceEpoch,
        readingSilo: _currentSilo,
        disconnectedSilos: _disconnectedSilos,
        retryCount: _retryCount,
        isRetryPhase: _isRetryPhase,
        currentGroupIndex: _currentGroupIndex,
      );
      await prefs.setString(_storageKey, jsonEncode(state.toJson()));
    } catch (e) {
      debugPrint('Failed to save auto test state: $e');
    }
  }

  // Load state from persistent storage
  Future<void> _loadState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stateJson = prefs.getString(_storageKey);
      if (stateJson != null) {
        final state = AutoTestState.fromJson(jsonDecode(stateJson));
        if (state.isActive) {
          // Resume from saved state
          _currentSiloIndex = state.currentIndex;
          _progress = state.progress;
          _currentSilo = state.readingSilo;
          _disconnectedSilos = List.from(state.disconnectedSilos);
          _retryCount = state.retryCount;
          _isRetryPhase = state.isRetryPhase;
          _currentGroupIndex = state.currentGroupIndex;
          
          // Resume auto test
          _resumeAutoTest();
        }
      }
    } catch (e) {
      debugPrint('Failed to load auto test state: $e');
    }
  }

  // Clear saved state
  Future<void> _clearState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_storageKey);
    } catch (e) {
      debugPrint('Failed to clear auto test state: $e');
    }
  }

  // Start auto test
  Future<void> startAutoTest() async {
    if (_isRunning) {
      await stopAutoTest();
      return;
    }

    _mode = AutoTestMode.auto;
    _isRunning = true;
    _progress = 0.0;
    _isCompleted = false;
    _currentSiloIndex = 0;
    _currentGroupIndex = 0;
    _disconnectedSilos.clear();
    _retryCount = 0;
    _isRetryPhase = false;
    _phase = AutoTestPhase.scanning;

    notifyListeners();
    await _saveState();

    debugPrint('🚀 [AUTO TEST] Starting auto test for ${_allSilos.length} silos');
    await _scanNextSilo();
  }

  // Stop auto test
  Future<void> stopAutoTest() async {
    _siloTimer?.cancel();
    _progressTimer?.cancel();
    
    _mode = AutoTestMode.none;
    _isRunning = false;
    _currentSilo = null;
    
    await _clearState();
    notifyListeners();
    
    debugPrint('🛑 [AUTO TEST] Auto test stopped');
  }

  // Resume auto test from saved state
  Future<void> _resumeAutoTest() async {
    if (_currentSiloIndex < _allSilos.length) {
      _mode = AutoTestMode.auto;
      _isRunning = true;
      notifyListeners();
      
      debugPrint('🔄 [AUTO TEST] Resuming auto test from silo index $_currentSiloIndex');
      await _scanNextSilo();
    }
  }

  // Scan next silo
  Future<void> _scanNextSilo() async {
    if (!_isRunning || _currentSiloIndex >= _allSilos.length) {
      if (_disconnectedSilos.isNotEmpty && _retryCount < _maxRetries) {
        await _startRetryPhase();
      } else {
        await _completeAutoTest();
      }
      return;
    }

    final siloNumber = _allSilos[_currentSiloIndex];
    _currentSilo = siloNumber;
    
    // Update group index based on current silo
    _updateCurrentGroupIndex(siloNumber);
    
    // Update progress
    _progress = ((_currentSiloIndex + 1) / _allSilos.length) * 100;
    
    notifyListeners();
    await _saveState();

    debugPrint('🔍 [AUTO TEST] Scanning silo $siloNumber (${_currentSiloIndex + 1}/${_allSilos.length})');

    // Start progress animation for this silo
    _startSiloProgressAnimation();

    // Test the silo
    try {
      final data = await ApiService.getSiloSensorData(siloNumber);
      
      if (data == null || _isSiloDisconnected(data)) {
        _disconnectedSilos.add(siloNumber);
        debugPrint('🔌 [DISCONNECTED] Silo $siloNumber is disconnected');
      } else {
        debugPrint('✅ [CONNECTED] Silo $siloNumber - Max temp: ${data.maxTemp}°C');
      }
    } catch (e) {
      debugPrint('❌ [ERROR] Failed to test silo $siloNumber: $e');
      _disconnectedSilos.add(siloNumber);
    }

    // Wait for test duration, then move to next silo
    _siloTimer = Timer(Duration(milliseconds: _siloTestDuration), () {
      _currentSiloIndex++;
      _scanNextSilo();
    });
  }

  // Start retry phase for disconnected silos
  Future<void> _startRetryPhase() async {
    if (_disconnectedSilos.isEmpty || _retryCount >= _maxRetries) {
      await _completeAutoTest();
      return;
    }

    _isRetryPhase = true;
    _retryCount++;
    _phase = AutoTestPhase.retry;
    
    debugPrint('🔄 [RETRY] Starting retry phase ${_retryCount}/$_maxRetries for ${_disconnectedSilos.length} silos');
    
    final silosToRetry = List<int>.from(_disconnectedSilos);
    _disconnectedSilos.clear();
    
    await _retrySilos(silosToRetry);
  }

  // Retry disconnected silos
  Future<void> _retrySilos(List<int> silosToRetry) async {
    for (int i = 0; i < silosToRetry.length; i++) {
      if (!_isRunning) break;
      
      final siloNumber = silosToRetry[i];
      _currentSilo = siloNumber;
      _updateCurrentGroupIndex(siloNumber);
      
      // Update retry progress
      final retryProgress = 100 + (_retryCount - 1) * 5 + ((i + 1) / silosToRetry.length) * 5;
      _progress = retryProgress.clamp(0.0, 130.0);
      
      notifyListeners();
      await _saveState();

      debugPrint('🔍 [RETRY $_retryCount.$i] Testing silo $siloNumber');

      // Start progress animation
      _startSiloProgressAnimation();

      try {
        final data = await ApiService.getSiloSensorData(siloNumber);
        
        if (data != null && !_isSiloDisconnected(data)) {
          debugPrint('✅ [RETRY $_retryCount.$i] Silo $siloNumber now connected!');
        } else {
          _disconnectedSilos.add(siloNumber);
          debugPrint('❌ [RETRY $_retryCount.$i] Silo $siloNumber still disconnected');
        }
      } catch (e) {
        debugPrint('❌ [RETRY $_retryCount.$i] Failed to test silo $siloNumber: $e');
        _disconnectedSilos.add(siloNumber);
      }

      // Wait for retry duration
      await Future.delayed(Duration(milliseconds: _retryTestDuration));
    }

    // Check if we need another retry cycle
    if (_disconnectedSilos.isNotEmpty && _retryCount < _maxRetries) {
      await Future.delayed(Duration(seconds: 5)); // Wait 5 seconds between retry cycles
      await _startRetryPhase();
    } else {
      await _completeAutoTest();
    }
  }

  // Complete auto test
  Future<void> _completeAutoTest() async {
    _siloTimer?.cancel();
    _progressTimer?.cancel();
    
    _isRunning = false;
    _currentSilo = null;
    _progress = 100.0;
    _isCompleted = true;
    _isRetryPhase = false;
    
    await _clearState();
    notifyListeners();

    final disconnectedCount = _disconnectedSilos.length;
    debugPrint('🏁 [AUTO TEST COMPLETE] Scanned ${_allSilos.length} silos. $disconnectedCount disconnected.');
  }

  // Start progress animation for current silo
  void _startSiloProgressAnimation() {
    _progressTimer?.cancel();
    
    const updateInterval = Duration(milliseconds: 100);
    final totalDuration = _isRetryPhase ? _retryTestDuration : _siloTestDuration;
    final steps = totalDuration ~/ updateInterval.inMilliseconds;
    int currentStep = 0;

    _progressTimer = Timer.periodic(updateInterval, (timer) {
      if (!_isRunning || currentStep >= steps) {
        timer.cancel();
        return;
      }
      
      currentStep++;
      // This will trigger UI updates for circular progress indicators
      notifyListeners();
    });
  }

  // Update current group index based on silo number
  void _updateCurrentGroupIndex(int siloNumber) {
    for (int i = 0; i < _siloGroups.length; i++) {
      final groupSilos = _siloGroups[i].expand((row) => row).toList();
      if (groupSilos.contains(siloNumber)) {
        _currentGroupIndex = i;
        break;
      }
    }
  }

  // Check if silo is disconnected based on sensor data
  bool _isSiloDisconnected(SiloSensorData data) {
    // Consider disconnected if all sensors are 0 or very low temperature
    return data.sensors.every((temp) => temp <= 0) || data.maxTemp <= 0;
  }

  // Navigate to specific group page
  void navigateToGroup(int groupIndex) {
    if (groupIndex >= 0 && groupIndex < _siloGroups.length) {
      _currentGroupIndex = groupIndex;
      notifyListeners();
    }
  }

  // Navigate to next group
  void nextGroup() {
    if (_currentGroupIndex < _siloGroups.length - 1) {
      _currentGroupIndex++;
      notifyListeners();
    }
  }

  // Navigate to previous group
  void previousGroup() {
    if (_currentGroupIndex > 0) {
      _currentGroupIndex--;
      notifyListeners();
    }
  }

  // Get progress for specific silo (0.0 to 1.0)
  double getSiloProgress(int siloNumber) {
    if (_currentSilo != siloNumber || !_isRunning) return 0.0;
    
    // This is a simplified calculation - in real implementation, 
    // you'd track the actual elapsed time for the current silo
    return 0.5; // Placeholder - implement actual progress calculation
  }

  // Check if silo is currently being scanned
  bool isSiloScanning(int siloNumber) {
    return _currentSilo == siloNumber && _isRunning;
  }

  // Check if silo is completed
  bool isSiloCompleted(int siloNumber) {
    if (!_isRunning) return false;
    
    final siloIndex = _allSilos.indexOf(siloNumber);
    return siloIndex >= 0 && siloIndex < _currentSiloIndex;
  }

  // Check if silo is disconnected
  bool isSiloDisconnected(int siloNumber) {
    return _disconnectedSilos.contains(siloNumber);
  }


  // Set silo as scanning (for manual scan simulation only)
  void setSiloScanning(int siloNumber) {
    // Only allow manual scanning if auto test is not already running
    if (_isRunning) {
      debugPrint('⚠️ [AUTO TEST] Cannot set manual scanning - auto test is running');
      return;
    }
    _currentSilo = siloNumber;
    _isRunning = true;
    notifyListeners();
  }

  // Set silo as completed (for manual scan simulation only)
  void setSiloCompleted(int siloNumber) {
    // Only complete manual scanning if we're not in auto test mode
    if (_currentSilo == siloNumber && !_isCompleted) {
      _currentSilo = null;
      _isRunning = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _siloTimer?.cancel();
    _progressTimer?.cancel();
    super.dispose();
  }
}
