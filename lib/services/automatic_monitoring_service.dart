import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'api_service.dart';

/// Automatic monitoring service that performs batch checks every 3 minutes
class AutomaticMonitoringService extends ChangeNotifier {
  static const String baseUrl = 'http://192.168.1.65:3000';
  static const String batchReadingsEndpoint = '/readings/avg/latest/batch';
  static const Duration monitoringInterval = Duration(minutes: 3);
  static const Duration batchTimeout = Duration(seconds: 3);
  
  // Singleton instance
  static final AutomaticMonitoringService _instance = AutomaticMonitoringService._internal();
  factory AutomaticMonitoringService() => _instance;
  AutomaticMonitoringService._internal();

  // State
  Timer? _monitoringTimer;
  bool _isRunning = false;
  bool _isBatchChecking = false;
  DateTime? _lastBatchCheck;
  Map<int, SiloSensorData> _cachedSiloData = {};
  Map<int, DateTime> _lastUpdated = {};
  
  // All silo numbers (195 silos total)
  final List<int> _allSilos = [
    // Group 1
    1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11,
    // Group 2  
    12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22,
    // Group 3
    23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33,
    // Group 4
    34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44,
    // Group 5
    45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55,
    // Group 6
    101, 102, 103, 104, 105, 106, 107, 108, 109, 110, 111, 112, 113, 114, 115, 116, 117, 118, 119,
    // Group 7
    120, 121, 122, 123, 124, 125, 126, 127, 128, 129, 130, 131, 132, 133, 134, 135, 136, 137, 138,
    // Group 8
    139, 140, 141, 142, 143, 144, 145, 146, 147, 148, 149, 150, 151, 152, 153, 154, 155, 156, 157,
    // Group 9
    158, 159, 160, 161, 162, 163, 164, 165, 166, 167, 168, 169, 170, 171, 172, 173, 174, 175, 176,
    // Group 10
    177, 178, 179, 180, 181, 182, 183, 184, 185, 186, 187, 188, 189, 190, 191, 192, 193, 194, 195,
  ];

  // Getters
  bool get isRunning => _isRunning;
  bool get isBatchChecking => _isBatchChecking;
  DateTime? get lastBatchCheck => _lastBatchCheck;
  Map<int, SiloSensorData> get cachedSiloData => Map.unmodifiable(_cachedSiloData);
  Map<int, DateTime> get lastUpdated => Map.unmodifiable(_lastUpdated);
  int get totalSilos => _allSilos.length;
  
  /// Start automatic monitoring with 3-minute intervals
  void startMonitoring() {
    if (_isRunning) return;
    
    _isRunning = true;
    debugPrint('🔄 [AUTO MONITOR] Starting automatic monitoring (3-minute intervals)');
    
    // Perform initial batch check immediately
    _performBatchCheck();
    
    // Set up periodic timer for 3-minute intervals
    _monitoringTimer = Timer.periodic(monitoringInterval, (timer) {
      _performBatchCheck();
    });
    
    notifyListeners();
  }
  
  /// Stop automatic monitoring
  void stopMonitoring() {
    if (!_isRunning) return;
    
    _monitoringTimer?.cancel();
    _monitoringTimer = null;
    _isRunning = false;
    _isBatchChecking = false;
    
    debugPrint('🛑 [AUTO MONITOR] Stopped automatic monitoring');
    notifyListeners();
  }
  
  /// Perform fast batch check for all silos (< 3 seconds)
  Future<void> _performBatchCheck() async {
    if (_isBatchChecking) {
      debugPrint('⚠️ [AUTO MONITOR] Batch check already in progress, skipping');
      return;
    }
    
    _isBatchChecking = true;
    final startTime = DateTime.now();
    
    debugPrint('🚀 [AUTO MONITOR] Starting batch check for ${_allSilos.length} silos');
    notifyListeners();
    
    try {
      // Use batch API endpoint for fast checking
      final batchData = await _fetchBatchSiloData();
      
      if (batchData != null) {
        // Update cache with batch results
        _updateCacheFromBatch(batchData);
        
        final duration = DateTime.now().difference(startTime);
        _lastBatchCheck = DateTime.now();
        
        debugPrint('✅ [AUTO MONITOR] Batch check completed in ${duration.inMilliseconds}ms');
        debugPrint('📊 [AUTO MONITOR] Updated ${batchData.length} silos in cache');
      } else {
        debugPrint('❌ [AUTO MONITOR] Batch check failed - no data received');
      }
    } catch (e) {
      final duration = DateTime.now().difference(startTime);
      debugPrint('❌ [AUTO MONITOR] Batch check failed after ${duration.inMilliseconds}ms: $e');
    } finally {
      _isBatchChecking = false;
      notifyListeners();
    }
  }
  
  /// Fetch batch silo data using optimized endpoint
  Future<List<SiloSensorData>?> _fetchBatchSiloData() async {
    try {
      // Create batch request with all silo numbers
      final siloNumbers = _allSilos.join(',');
      final url = '$baseUrl$batchReadingsEndpoint?silo_numbers=$siloNumbers&_t=${DateTime.now().millisecondsSinceEpoch}';
      
      final response = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      ).timeout(batchTimeout);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => SiloSensorData.fromJson(json)).toList();
      } else {
        debugPrint('❌ [AUTO MONITOR] Batch API returned ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('❌ [AUTO MONITOR] Batch API error: $e');
      // Fallback to individual requests if batch fails
      return await _fallbackIndividualRequests();
    }
  }
  
  /// Fallback to individual requests if batch API fails
  Future<List<SiloSensorData>?> _fallbackIndividualRequests() async {
    debugPrint('🔄 [AUTO MONITOR] Using fallback individual requests');
    
    final results = <SiloSensorData>[];
    final futures = <Future<SiloSensorData?>>[];
    
    // Create concurrent requests for all silos
    for (final siloNumber in _allSilos) {
      futures.add(ApiService.getSiloSensorData(siloNumber));
    }
    
    try {
      // Wait for all requests to complete with timeout
      final responses = await Future.wait(futures).timeout(batchTimeout);
      
      for (final data in responses) {
        if (data != null) {
          results.add(data);
        }
      }
      
      debugPrint('✅ [AUTO MONITOR] Fallback completed: ${results.length}/${_allSilos.length} silos');
      return results;
    } catch (e) {
      debugPrint('❌ [AUTO MONITOR] Fallback failed: $e');
      return null;
    }
  }
  
  /// Update cache from batch results
  void _updateCacheFromBatch(List<SiloSensorData> batchData) {
    final now = DateTime.now();
    
    for (final data in batchData) {
      _cachedSiloData[data.siloNumber] = data;
      _lastUpdated[data.siloNumber] = now;
    }
    
    debugPrint('💾 [AUTO MONITOR] Cache updated with ${batchData.length} silos');
  }
  
  /// Get cached silo data
  SiloSensorData? getCachedSiloData(int siloNumber) {
    return _cachedSiloData[siloNumber];
  }
  
  /// Check if silo data is fresh (updated within last 5 minutes)
  bool isSiloDataFresh(int siloNumber) {
    final lastUpdate = _lastUpdated[siloNumber];
    if (lastUpdate == null) return false;
    
    final age = DateTime.now().difference(lastUpdate);
    return age.inMinutes < 5;
  }
  
  /// Update individual silo data on-demand (when clicked)
  Future<SiloSensorData?> updateSiloOnDemand(int siloNumber) async {
    debugPrint('🎯 [AUTO MONITOR] On-demand update for silo $siloNumber');
    
    try {
      final data = await ApiService.getSiloSensorData(siloNumber);
      
      if (data != null) {
        _cachedSiloData[siloNumber] = data;
        _lastUpdated[siloNumber] = DateTime.now();
        
        debugPrint('✅ [AUTO MONITOR] On-demand update completed for silo $siloNumber');
        notifyListeners();
        return data;
      } else {
        debugPrint('❌ [AUTO MONITOR] On-demand update failed for silo $siloNumber - no data');
        return null;
      }
    } catch (e) {
      debugPrint('❌ [AUTO MONITOR] On-demand update error for silo $siloNumber: $e');
      return null;
    }
  }
  
  /// Get silo color from cache or default
  String getSiloColor(int siloNumber) {
    final data = _cachedSiloData[siloNumber];
    if (data != null && data.siloColor.isNotEmpty) {
      return data.siloColor;
    }
    return ApiService.wheatColor; // Default wheat color
  }
  
  /// Get silo max temperature from cache
  double? getSiloMaxTemp(int siloNumber) {
    final data = _cachedSiloData[siloNumber];
    return data?.maxTemp;
  }
  
  /// Check if silo is disconnected based on cached data
  bool isSiloDisconnected(int siloNumber) {
    final data = _cachedSiloData[siloNumber];
    if (data == null) return true; // No data = disconnected
    
    // Check if all sensors are 0 or very low temperature
    return data.sensors.every((temp) => temp <= 0) || data.maxTemp <= 0 || data.maxTemp == -127.0;
  }
  
  /// Get monitoring statistics
  Map<String, dynamic> getMonitoringStats() {
    final now = DateTime.now();
    final freshCount = _lastUpdated.values.where((lastUpdate) {
      return now.difference(lastUpdate).inMinutes < 5;
    }).length;
    
    return {
      'totalSilos': _allSilos.length,
      'cachedSilos': _cachedSiloData.length,
      'freshSilos': freshCount,
      'lastBatchCheck': _lastBatchCheck?.toIso8601String(),
      'isRunning': _isRunning,
      'isBatchChecking': _isBatchChecking,
    };
  }
  
  /// Clear all cached data
  void clearCache() {
    _cachedSiloData.clear();
    _lastUpdated.clear();
    debugPrint('🗑️ [AUTO MONITOR] Cache cleared');
    notifyListeners();
  }
  
  @override
  void dispose() {
    stopMonitoring();
    super.dispose();
  }
}
