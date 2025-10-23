import 'dart:convert';
import 'package:http/http.dart' as http;

/// Alert API Response interface matching the alerts API structure
class AlertApiResponse {
  final String siloGroup;
  final int siloNumber;
  final int? cableNumber;
  final double? level0;
  final String color0;
  final double? level1;
  final String color1;
  final double? level2;
  final String color2;
  final double? level3;
  final String color3;
  final double? level4;
  final String color4;
  final double? level5;
  final String color5;
  final double? level6;
  final String color6;
  final double? level7;
  final String color7;
  final String siloColor;
  final DateTime timestamp;
  final AlertType alertType;
  final List<int> affectedLevels;
  final DateTime activeSince;

  AlertApiResponse({
    required this.siloGroup,
    required this.siloNumber,
    this.cableNumber,
    this.level0,
    required this.color0,
    this.level1,
    required this.color1,
    this.level2,
    required this.color2,
    this.level3,
    required this.color3,
    this.level4,
    required this.color4,
    this.level5,
    required this.color5,
    this.level6,
    required this.color6,
    this.level7,
    required this.color7,
    required this.siloColor,
    required this.timestamp,
    required this.alertType,
    required this.affectedLevels,
    required this.activeSince,
  });

  factory AlertApiResponse.fromJson(Map<String, dynamic> json) {
    return AlertApiResponse(
      siloGroup: json['silo_group']?.toString() ?? '',
      siloNumber: json['silo_number']?.toInt() ?? 0,
      cableNumber: json['cable_number']?.toInt(),
      level0: json['level_0']?.toDouble(),
      color0: json['color_0']?.toString() ?? '#ffffff',
      level1: json['level_1']?.toDouble(),
      color1: json['color_1']?.toString() ?? '#ffffff',
      level2: json['level_2']?.toDouble(),
      color2: json['color_2']?.toString() ?? '#ffffff',
      level3: json['level_3']?.toDouble(),
      color3: json['color_3']?.toString() ?? '#ffffff',
      level4: json['level_4']?.toDouble(),
      color4: json['color_4']?.toString() ?? '#ffffff',
      level5: json['level_5']?.toDouble(),
      color5: json['color_5']?.toString() ?? '#ffffff',
      level6: json['level_6']?.toDouble(),
      color6: json['color_6']?.toString() ?? '#ffffff',
      level7: json['level_7']?.toDouble(),
      color7: json['color_7']?.toString() ?? '#ffffff',
      siloColor: json['silo_color']?.toString() ?? '#ffffff',
      timestamp: DateTime.parse(json['timestamp']?.toString() ?? DateTime.now().toIso8601String()),
      alertType: _parseAlertType(json['alert_type']?.toString()),
      affectedLevels: json['affected_level'] != null 
          ? [json['affected_level'].toInt()]
          : (json['affected_levels'] as List<dynamic>?)?.map((e) => (e as num).toInt()).toList() ?? [],
      activeSince: DateTime.parse(json['active_since']?.toString() ?? DateTime.now().toIso8601String()),
    );
  }

  static AlertType _parseAlertType(String? type) {
    switch (type?.toLowerCase()) {
      case 'critical':
        return AlertType.critical;
      case 'warn':
      case 'warning':
        return AlertType.warning;
      case 'disconnect':
        return AlertType.disconnect;
      default:
        return AlertType.warning;
    }
  }
}

/// Alert types
enum AlertType { critical, warning, disconnect }

/// Alert priority levels
enum AlertPriority { normal, warning, critical }

/// Alert status
enum AlertStatus { ok, yellow, red }

/// Sensor reading data
class SensorReading {
  final String id;
  final double value;
  final AlertStatus status;

  SensorReading({
    required this.id,
    required this.value,
    required this.status,
  });
}

/// Processed alert data for internal use
class ProcessedAlert {
  final String id;
  final int siloNumber;
  final String siloGroup;
  final AlertType alertType;
  final List<int> affectedLevels;
  final List<double> sensors;
  final List<String> sensorColors;
  final String siloColor;
  final double maxTemp;
  final DateTime timestamp;
  final DateTime activeSince;
  final String duration;
  final AlertPriority priority;
  final AlertStatus overallStatus;
  final List<SensorReading> sensorReadings;
  final int alertCount;

  ProcessedAlert({
    required this.id,
    required this.siloNumber,
    required this.siloGroup,
    required this.alertType,
    required this.affectedLevels,
    required this.sensors,
    required this.sensorColors,
    required this.siloColor,
    required this.maxTemp,
    required this.timestamp,
    required this.activeSince,
    required this.duration,
    required this.priority,
    required this.overallStatus,
    required this.sensorReadings,
    required this.alertCount,
  });
}

/// Pagination information
class PaginationInfo {
  final int currentPage;
  final int totalPages;
  final int totalItems;
  final int itemsPerPage;
  final bool hasPreviousPage;
  final bool hasNextPage;

  PaginationInfo({
    required this.currentPage,
    required this.totalPages,
    required this.totalItems,
    required this.itemsPerPage,
    required this.hasPreviousPage,
    required this.hasNextPage,
  });

  factory PaginationInfo.fromJson(Map<String, dynamic> json) {
    return PaginationInfo(
      currentPage: json['current_page']?.toInt() ?? 1,
      totalPages: json['total_pages']?.toInt() ?? 1,
      totalItems: json['total_items']?.toInt() ?? 0,
      itemsPerPage: json['per_page']?.toInt() ?? 20,
      hasPreviousPage: json['has_previous_page'] ?? false,
      hasNextPage: json['has_next_page'] ?? false,
    );
  }
}

/// Backend API response wrapper
class BackendApiResponse {
  final bool success;
  final String message;
  final List<AlertApiResponse> data;
  final PaginationInfo? pagination;

  BackendApiResponse({
    required this.success,
    required this.message,
    required this.data,
    this.pagination,
  });

  factory BackendApiResponse.fromJson(Map<String, dynamic> json) {
    return BackendApiResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: (json['data'] as List<dynamic>?)
          ?.map((e) => AlertApiResponse.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      pagination: json['pagination'] != null 
          ? PaginationInfo.fromJson(json['pagination'] as Map<String, dynamic>)
          : null,
    );
  }
}

/// Fetch alerts result
class FetchAlertsResult {
  final List<ProcessedAlert> alerts;
  final PaginationInfo? pagination;
  final bool isLoading;
  final String? error;

  FetchAlertsResult({
    required this.alerts,
    this.pagination,
    required this.isLoading,
    this.error,
  });
}

/// Alerts cache for storing fetched data
class AlertsCache {
  static final AlertsCache _instance = AlertsCache._internal();
  factory AlertsCache() => _instance;
  AlertsCache._internal();

  List<ProcessedAlert> _cache = [];
  DateTime? _lastFetch;
  static const int _cacheDurationMs = 3600000; // 1 hour cache
  bool _isLoading = false;
  String? _lastError;

  /// Check if cache is still valid
  bool isCacheValid() {
    if (_lastFetch == null) return false;
    return DateTime.now().millisecondsSinceEpoch - _lastFetch!.millisecondsSinceEpoch < _cacheDurationMs;
  }

  /// Check if currently loading
  bool isCurrentlyLoading() => _isLoading;

  /// Set loading state
  void setLoading(bool loading) => _isLoading = loading;

  /// Get last error
  String? getLastError() => _lastError;

  /// Set last error
  void setLastError(String? error) => _lastError = error;

  /// Get cached alerts
  List<ProcessedAlert> getAlerts() => _cache;

  /// Set alerts in cache
  void setAlerts(List<ProcessedAlert> alerts) {
    _cache = alerts;
    _lastFetch = DateTime.now();
    _isLoading = false;
    _lastError = null;
  }

  /// Clear cache
  void clear() {
    _cache = [];
    _lastFetch = null;
    _isLoading = false;
    _lastError = null;
  }
}

/// Alerts API Service
class AlertsApiService {
  static const String baseUrl = 'http://idealchiprnd.pythonanywhere.com';
  static const String alertsEndpoint = '/alerts/active';
  
  static final AlertsCache _cache = AlertsCache();

  /// Calculate human-readable duration
  static String calculateDuration(DateTime activeSince) {
    final now = DateTime.now();
    final diffMs = now.millisecondsSinceEpoch - activeSince.millisecondsSinceEpoch;
    
    final minutes = (diffMs / (1000 * 60)).floor();
    final hours = (minutes / 60).floor();
    final days = (hours / 24).floor();
    
    if (days > 0) {
      return '${days}d ${hours % 24}h';
    } else if (hours > 0) {
      return '${hours}h ${minutes % 60}m';
    } else {
      return '${minutes}m';
    }
  }

  /// Convert color to status
  static AlertStatus colorToStatus(String? color) {
    if (color == null) return AlertStatus.ok;
    final c = color.trim().toLowerCase();

    if (c == 'red' || c == '#d14141') return AlertStatus.red;
    if (c == 'yellow' || c == '#c7c150') return AlertStatus.yellow;
    if (c == 'green' || c == '#46d446') return AlertStatus.ok;

    final hexMatch = RegExp(r'^#?([0-9a-f]{6})$').firstMatch(c);
    if (hexMatch != null) {
      final hex = hexMatch.group(1)!;
      final r = int.parse(hex.substring(0, 2), radix: 16);
      final g = int.parse(hex.substring(2, 4), radix: 16);
      final b = int.parse(hex.substring(4, 6), radix: 16);

      if (r > g + 40 && r > b + 40) return AlertStatus.red;
      if (g > r + 40 && g > b + 40) return AlertStatus.ok;
      if (r > 140 && g > 140 && b < 120) return AlertStatus.yellow;

      return AlertStatus.ok;
    }

    return AlertStatus.ok;
  }

  /// Convert API response to processed alert data
  static ProcessedAlert processAlertResponse(AlertApiResponse apiData) {
    // Handle null values by converting them to 0
    final sensors = [
      apiData.level0 ?? 0, apiData.level1 ?? 0, apiData.level2 ?? 0, apiData.level3 ?? 0,
      apiData.level4 ?? 0, apiData.level5 ?? 0, apiData.level6 ?? 0, apiData.level7 ?? 0
    ];
    
    final sensorColors = [
      apiData.color0, apiData.color1, apiData.color2, apiData.color3,
      apiData.color4, apiData.color5, apiData.color6, apiData.color7
    ];
    
    // Filter out null/zero values when calculating max temperature
    final validTemperatures = sensors.where((temp) => temp > 0).toList();
    final maxTemp = validTemperatures.isNotEmpty ? validTemperatures.reduce((a, b) => a > b ? a : b) : 0.0;
    
    // Create sensor readings
    final sensorReadings = <SensorReading>[];
    int alertCount = 0;
    
    for (int i = 0; i < sensors.length; i++) {
      final value = sensors[i];
      final color = sensorColors[i];
      final status = colorToStatus(color);
      
      if (status == AlertStatus.red || status == AlertStatus.yellow) alertCount++;
      
      sensorReadings.add(SensorReading(
        id: 'sensor-${i + 1}',
        value: value,
        status: status,
      ));
    }
    
    final overallStatus = colorToStatus(apiData.siloColor);
    AlertPriority priority = AlertPriority.normal;
    if (apiData.alertType == AlertType.critical || overallStatus == AlertStatus.red) {
      priority = AlertPriority.critical;
    } else if (apiData.alertType == AlertType.warning || 
               apiData.alertType == AlertType.disconnect || 
               overallStatus == AlertStatus.yellow || 
               alertCount > 0) {
      priority = AlertPriority.warning;
    }
    
    // Create alert ID
    final alertId = '${apiData.siloNumber}-${apiData.alertType.name}-${apiData.affectedLevels.join(',')}';
    
    return ProcessedAlert(
      id: alertId,
      siloNumber: apiData.siloNumber,
      siloGroup: apiData.siloGroup,
      alertType: apiData.alertType,
      affectedLevels: apiData.affectedLevels,
      sensors: sensors,
      sensorColors: sensorColors,
      siloColor: apiData.siloColor,
      maxTemp: maxTemp,
      timestamp: apiData.timestamp,
      activeSince: apiData.activeSince,
      duration: calculateDuration(apiData.activeSince),
      priority: priority,
      overallStatus: overallStatus,
      sensorReadings: sensorReadings,
      alertCount: alertCount,
    );
  }

  /// Consolidate duplicate alerts by merging alerts with same silo number and alert type
  static List<ProcessedAlert> consolidateAlerts(List<ProcessedAlert> alerts) {
    final alertMap = <String, ProcessedAlert>{};
    
    for (final alert in alerts) {
      // Group by silo number and alert type only (not by affected levels)
      final key = '${alert.siloNumber}-${alert.alertType.name}';
      
      if (alertMap.containsKey(key)) {
        final existingAlert = alertMap[key]!;
        
        // Merge affected levels from both alerts (remove duplicates)
        final mergedAffectedLevels = <int>{...existingAlert.affectedLevels, ...alert.affectedLevels}.toList()..sort();
        
        // Keep the alert with the most recent timestamp for sensor data, but merge affected levels
        final mergedAlert = alert.timestamp.isAfter(existingAlert.timestamp) 
            ? alert.copyWith(
                affectedLevels: mergedAffectedLevels,
                id: '${alert.siloNumber}-${alert.alertType.name}-${mergedAffectedLevels.join(',')}',
              )
            : existingAlert.copyWith(
                affectedLevels: mergedAffectedLevels,
                id: '${existingAlert.siloNumber}-${existingAlert.alertType.name}-${mergedAffectedLevels.join(',')}',
              );
        
        alertMap[key] = mergedAlert;
      } else {
        alertMap[key] = alert;
      }
    }
    
    return alertMap.values.toList();
  }

  /// Fetch active alerts from API
  static Future<FetchAlertsResult> fetchActiveAlerts({
    bool forceRefresh = false,
    int page = 1,
    int limit = 20,
  }) async {
    print('🚨 [ALERTS API] Fetching active alerts (page: $page, limit: $limit, forceRefresh: $forceRefresh)');

    // Return cached data if valid and not forcing refresh
    if (!forceRefresh && _cache.isCacheValid()) {
      print('🚨 [ALERTS API] Returning cached data');
      return FetchAlertsResult(
        alerts: _cache.getAlerts(),
        pagination: null,
        isLoading: false,
        error: null,
      );
    }

    // If already loading, return current state
    if (_cache.isCurrentlyLoading()) {
      print('🚨 [ALERTS API] Already loading, returning current state');
      return FetchAlertsResult(
        alerts: _cache.getAlerts(),
        pagination: null,
        isLoading: true,
        error: null,
      );
    }

    // Set loading state
    _cache.setLoading(true);
    _cache.setLastError(null);

    try {
      final url = '$baseUrl$alertsEndpoint';
      print('🚨 [ALERTS API] Fetching active alerts from: $url (page: $page, limit: $limit)');

      // Build URL with pagination parameters
      final uri = Uri.parse(url).replace(queryParameters: {
        'page': page.toString(),
        'limit': limit.toString(),
        '_t': DateTime.now().millisecondsSinceEpoch.toString(), // Cache busting
      });

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(minutes: 10)); // 10 minute timeout

      if (response.statusCode != 200) {
        throw Exception('Alerts API request failed: ${response.statusCode} ${response.reasonPhrase}');
      }

      final responseBody = json.decode(response.body);
      
      // Handle direct array response (no wrapper)
      List<AlertApiResponse> apiData;
      PaginationInfo? paginationInfo;
      
      if (responseBody is List) {
        // Direct array response
        apiData = responseBody
            .map((e) => AlertApiResponse.fromJson(e as Map<String, dynamic>))
            .toList();
        paginationInfo = null;
      } else if (responseBody is Map<String, dynamic>) {
        // Wrapped response
        final wrappedResponse = BackendApiResponse.fromJson(responseBody);
        apiData = wrappedResponse.data;
        paginationInfo = wrappedResponse.pagination;
      } else {
        throw Exception('Unexpected response format');
      }
      
      print('🚨 [ALERTS API] Received ${apiData.length} active alerts (page $page/${paginationInfo?.totalPages ?? 1})');
      
      if (apiData.isEmpty) {
        print('🚨 [ALERTS API] No active alerts found');
        _cache.setAlerts([]);
        return FetchAlertsResult(
          alerts: [],
          pagination: paginationInfo,
          isLoading: false,
          error: null,
        );
      }

      // Process all alerts and consolidate duplicates
      final processedAlerts = apiData.map(processAlertResponse).toList();
      
      // Consolidate duplicate alerts
      final consolidatedAlerts = consolidateAlerts(processedAlerts);
      
      // Sort alerts by severity and then by active time (most recent first)
      consolidatedAlerts.sort((a, b) {
        // Priority order: critical > warning > disconnect
        const severityOrder = {
          AlertType.critical: 3,
          AlertType.warning: 2,
          AlertType.disconnect: 1,
        };
        final severityDiff = (severityOrder[b.alertType] ?? 0) - (severityOrder[a.alertType] ?? 0);
        
        if (severityDiff != 0) {
          return severityDiff;
        }
        
        // If same severity, sort by active time (most recent first)
        return b.activeSince.compareTo(a.activeSince);
      });
      
      // Filter out normal priority alerts (only show warnings and critical)
      final filtered = consolidatedAlerts.where((alert) => alert.priority != AlertPriority.normal).toList();
      
      // Cache the processed data
      _cache.setAlerts(filtered);
      
      print('🚨 [ALERTS API] Successfully processed ${apiData.length} raw alerts, consolidated to ${consolidatedAlerts.length} unique alerts, filtered to ${filtered.length} alerts');
      return FetchAlertsResult(
        alerts: filtered,
        pagination: paginationInfo,
        isLoading: false,
        error: null,
      );

    } catch (error) {
      final errorMessage = error.toString();
      print('🚨 [ALERTS API] Failed to fetch active alerts: $errorMessage');
      
      _cache.setLastError(errorMessage);
      _cache.setLoading(false);
      
      return FetchAlertsResult(
        alerts: _cache.getAlerts(), // Return cached data on error
        pagination: null,
        isLoading: false,
        error: errorMessage,
      );
    }
  }

  /// Clear alerts cache
  static void clearAlertsCache() {
    print('🚨 [ALERTS API] Clearing alerts cache');
    _cache.clear();
  }

  /// Format alert timestamp
  static String formatAlertTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  /// Format alert duration
  static String formatAlertDuration(String duration) {
    return duration;
  }
}

/// Extension to add copyWith method to ProcessedAlert
extension ProcessedAlertExtension on ProcessedAlert {
  ProcessedAlert copyWith({
    String? id,
    int? siloNumber,
    String? siloGroup,
    AlertType? alertType,
    List<int>? affectedLevels,
    List<double>? sensors,
    List<String>? sensorColors,
    String? siloColor,
    double? maxTemp,
    DateTime? timestamp,
    DateTime? activeSince,
    String? duration,
    AlertPriority? priority,
    AlertStatus? overallStatus,
    List<SensorReading>? sensorReadings,
    int? alertCount,
  }) {
    return ProcessedAlert(
      id: id ?? this.id,
      siloNumber: siloNumber ?? this.siloNumber,
      siloGroup: siloGroup ?? this.siloGroup,
      alertType: alertType ?? this.alertType,
      affectedLevels: affectedLevels ?? this.affectedLevels,
      sensors: sensors ?? this.sensors,
      sensorColors: sensorColors ?? this.sensorColors,
      siloColor: siloColor ?? this.siloColor,
      maxTemp: maxTemp ?? this.maxTemp,
      timestamp: timestamp ?? this.timestamp,
      activeSince: activeSince ?? this.activeSince,
      duration: duration ?? this.duration,
      priority: priority ?? this.priority,
      overallStatus: overallStatus ?? this.overallStatus,
      sensorReadings: sensorReadings ?? this.sensorReadings,
      alertCount: alertCount ?? this.alertCount,
    );
  }
}
