import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

/// Cable sensor data from API
class CableSensorData {
  final double level;
  final String color;

  CableSensorData({
    required this.level,
    required this.color,
  });

  factory CableSensorData.fromJson(Map<String, dynamic> json) {
    return CableSensorData(
      level: (json['level'] as num?)?.toDouble() ?? 0.0,
      color: json['color'] as String? ?? '#46d446',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'level': level,
      'color': color,
    };
  }
}

/// Cable data containing sensors
class CableData {
  final int cableIndex;
  final List<CableSensorData> sensors;

  CableData({
    required this.cableIndex,
    required this.sensors,
  });

  factory CableData.fromJson(Map<String, dynamic> json) {
    return CableData(
      cableIndex: json['cableIndex'] as int? ?? 0,
      sensors: (json['sensors'] as List<dynamic>?)
          ?.map((sensor) => CableSensorData.fromJson(sensor as Map<String, dynamic>))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'cableIndex': cableIndex,
      'sensors': sensors.map((sensor) => sensor.toJson()).toList(),
    };
  }
}

/// Processed maintenance silo data
class MaintenanceSiloData {
  final int siloNumber;
  final String siloGroup;
  final int cableCount;
  final String timestamp;
  final String siloColor;
  final List<CableData> cables;
  final List<double> sensorValues; // S1-S8 calculated values
  final List<String> sensorColors; // S1-S8 colors

  MaintenanceSiloData({
    required this.siloNumber,
    required this.siloGroup,
    required this.cableCount,
    required this.timestamp,
    required this.siloColor,
    required this.cables,
    required this.sensorValues,
    required this.sensorColors,
  });

  factory MaintenanceSiloData.fromJson(Map<String, dynamic> json) {
    return MaintenanceSiloData(
      siloNumber: json['siloNumber'] as int? ?? 0,
      siloGroup: json['siloGroup'] as String? ?? '',
      cableCount: json['cableCount'] as int? ?? 1,
      timestamp: json['timestamp'] as String? ?? '',
      siloColor: json['siloColor'] as String? ?? '#46d446',
      cables: (json['cables'] as List<dynamic>?)
          ?.map((cable) => CableData.fromJson(cable as Map<String, dynamic>))
          .toList() ?? [],
      sensorValues: (json['sensorValues'] as List<dynamic>?)
          ?.map((value) => (value as num?)?.toDouble() ?? 0.0)
          .toList() ?? [],
      sensorColors: (json['sensorColors'] as List<dynamic>?)
          ?.map((color) => color as String? ?? '#46d446')
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'siloNumber': siloNumber,
      'siloGroup': siloGroup,
      'cableCount': cableCount,
      'timestamp': timestamp,
      'siloColor': siloColor,
      'cables': cables.map((cable) => cable.toJson()).toList(),
      'sensorValues': sensorValues,
      'sensorColors': sensorColors,
    };
  }
}

/// Raw API response structure for maintenance silo data
class MaintenanceSiloApiData {
  final String siloGroup;
  final int siloNumber;
  final int cableCount;
  final String timestamp;
  final String? siloColor;
  
  // Cable 0 sensors (all silos have at least 1 cable)
  final double cable0Level0;
  final String cable0Color0;
  final double cable0Level1;
  final String cable0Color1;
  final double cable0Level2;
  final String cable0Color2;
  final double cable0Level3;
  final String cable0Color3;
  final double cable0Level4;
  final String cable0Color4;
  final double cable0Level5;
  final String cable0Color5;
  final double cable0Level6;
  final String cable0Color6;
  final double cable0Level7;
  final String cable0Color7;
  
  // Cable 1 sensors (only for circular silos 1-61)
  final double? cable1Level0;
  final String? cable1Color0;
  final double? cable1Level1;
  final String? cable1Color1;
  final double? cable1Level2;
  final String? cable1Color2;
  final double? cable1Level3;
  final String? cable1Color3;
  final double? cable1Level4;
  final String? cable1Color4;
  final double? cable1Level5;
  final String? cable1Color5;
  final double? cable1Level6;
  final String? cable1Color6;
  final double? cable1Level7;
  final String? cable1Color7;

  MaintenanceSiloApiData({
    required this.siloGroup,
    required this.siloNumber,
    required this.cableCount,
    required this.timestamp,
    this.siloColor,
    required this.cable0Level0,
    required this.cable0Color0,
    required this.cable0Level1,
    required this.cable0Color1,
    required this.cable0Level2,
    required this.cable0Color2,
    required this.cable0Level3,
    required this.cable0Color3,
    required this.cable0Level4,
    required this.cable0Color4,
    required this.cable0Level5,
    required this.cable0Color5,
    required this.cable0Level6,
    required this.cable0Color6,
    required this.cable0Level7,
    required this.cable0Color7,
    this.cable1Level0,
    this.cable1Color0,
    this.cable1Level1,
    this.cable1Color1,
    this.cable1Level2,
    this.cable1Color2,
    this.cable1Level3,
    this.cable1Color3,
    this.cable1Level4,
    this.cable1Color4,
    this.cable1Level5,
    this.cable1Color5,
    this.cable1Level6,
    this.cable1Color6,
    this.cable1Level7,
    this.cable1Color7,
  });

  factory MaintenanceSiloApiData.fromJson(Map<String, dynamic> json) {
    return MaintenanceSiloApiData(
      siloGroup: json['silo_group'] as String? ?? '',
      siloNumber: json['silo_number'] as int? ?? 0,
      cableCount: json['cable_count'] as int? ?? 1,
      timestamp: json['timestamp'] as String? ?? '',
      siloColor: json['silo_color'] as String?,
      cable0Level0: (json['cable_0_level_0'] as num?)?.toDouble() ?? 0.0,
      cable0Color0: json['cable_0_color_0'] as String? ?? '#46d446',
      cable0Level1: (json['cable_0_level_1'] as num?)?.toDouble() ?? 0.0,
      cable0Color1: json['cable_0_color_1'] as String? ?? '#46d446',
      cable0Level2: (json['cable_0_level_2'] as num?)?.toDouble() ?? 0.0,
      cable0Color2: json['cable_0_color_2'] as String? ?? '#46d446',
      cable0Level3: (json['cable_0_level_3'] as num?)?.toDouble() ?? 0.0,
      cable0Color3: json['cable_0_color_3'] as String? ?? '#46d446',
      cable0Level4: (json['cable_0_level_4'] as num?)?.toDouble() ?? 0.0,
      cable0Color4: json['cable_0_color_4'] as String? ?? '#46d446',
      cable0Level5: (json['cable_0_level_5'] as num?)?.toDouble() ?? 0.0,
      cable0Color5: json['cable_0_color_5'] as String? ?? '#46d446',
      cable0Level6: (json['cable_0_level_6'] as num?)?.toDouble() ?? 0.0,
      cable0Color6: json['cable_0_color_6'] as String? ?? '#46d446',
      cable0Level7: (json['cable_0_level_7'] as num?)?.toDouble() ?? 0.0,
      cable0Color7: json['cable_0_color_7'] as String? ?? '#46d446',
      cable1Level0: (json['cable_1_level_0'] as num?)?.toDouble(),
      cable1Color0: json['cable_1_color_0'] as String?,
      cable1Level1: (json['cable_1_level_1'] as num?)?.toDouble(),
      cable1Color1: json['cable_1_color_1'] as String?,
      cable1Level2: (json['cable_1_level_2'] as num?)?.toDouble(),
      cable1Color2: json['cable_1_color_2'] as String?,
      cable1Level3: (json['cable_1_level_3'] as num?)?.toDouble(),
      cable1Color3: json['cable_1_color_3'] as String?,
      cable1Level4: (json['cable_1_level_4'] as num?)?.toDouble(),
      cable1Color4: json['cable_1_color_4'] as String?,
      cable1Level5: (json['cable_1_level_5'] as num?)?.toDouble(),
      cable1Color5: json['cable_1_color_5'] as String?,
      cable1Level6: (json['cable_1_level_6'] as num?)?.toDouble(),
      cable1Color6: json['cable_1_color_6'] as String?,
      cable1Level7: (json['cable_1_level_7'] as num?)?.toDouble(),
      cable1Color7: json['cable_1_color_7'] as String?,
    );
  }
}
///hhhhhhhhhhhhhhhhhhhhhhhh
/// Maintenance API Service
class MaintenanceApiService {
  static const String _baseUrl = 'http://localhost:3000';
  static const Duration _timeout = Duration(seconds: 10);

  /// Fetch maintenance cable data for a specific silo
  static Future<MaintenanceSiloData> fetchMaintenanceSiloData(int siloNumber) async {
    try {
      print('🔧 [MAINTENANCE API] Fetching data for silo $siloNumber...');
      
      // Add timestamp to prevent browser caching
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final url = '$_baseUrl/readings/latest/by-silo-number?silo_number=$siloNumber&_t=$timestamp';
      
      print('🔧 [MAINTENANCE API] URL: $url');
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
        },
      ).timeout(_timeout);

      if (response.statusCode != 200) {
        throw Exception('API request failed: ${response.statusCode} ${response.reasonPhrase}');
      }

      final List<dynamic> data = json.decode(response.body);
      
      if (data.isEmpty) {
        throw Exception('No data received from API');
      }

      // Use the first record (API returns array but we only need first element)
      final apiData = MaintenanceSiloApiData.fromJson(data[0] as Map<String, dynamic>);
      
      print('🔧 [MAINTENANCE API] Successfully fetched data for silo $siloNumber');
      print('🔧 [MAINTENANCE API] Cable count: ${apiData.cableCount}');
      
      // Process the API data
      final processedData = _processMaintenanceSiloData(apiData);
      
      return processedData;
    } catch (error) {
      print('🚨 [MAINTENANCE API ERROR] Failed to fetch data for silo $siloNumber: $error');
      
      // Provide specific error messages for different error types
      String errorMessage = 'Unknown error occurred';
      if (error is SocketException) {
        errorMessage = 'Network error - unable to connect to maintenance API';
      } else if (error is http.ClientException) {
        errorMessage = 'Request timed out after 10 seconds';
      } else if (error is Exception) {
        errorMessage = error.toString().replaceFirst('Exception: ', '');
      }
      
      throw Exception('Maintenance API Error: $errorMessage');
    }
  }

  /// Process raw API data into structured maintenance data
  static MaintenanceSiloData _processMaintenanceSiloData(MaintenanceSiloApiData apiData) {
    final cables = <CableData>[];
    final sensorValues = <double>[];
    final sensorColors = <String>[];

    final isCircularSilo = apiData.siloNumber >= 1 && apiData.siloNumber <= 61;
    final actualCableCount = apiData.cableCount;
    
    print('📡 [MAINTENANCE] Processing silo ${apiData.siloNumber}:');
    print('📡 [MAINTENANCE] Silo type: ${isCircularSilo ? 'Circular (1-61)' : 'Square (101-189)'}');
    print('📡 [MAINTENANCE] API cable count: $actualCableCount');

    // Process Cable 0 (all silos have this)
    final cable0Sensors = <CableSensorData>[];
    final cable0Levels = [
      apiData.cable0Level0, apiData.cable0Level1, apiData.cable0Level2, apiData.cable0Level3,
      apiData.cable0Level4, apiData.cable0Level5, apiData.cable0Level6, apiData.cable0Level7,
    ];
    final cable0Colors = [
      apiData.cable0Color0, apiData.cable0Color1, apiData.cable0Color2, apiData.cable0Color3,
      apiData.cable0Color4, apiData.cable0Color5, apiData.cable0Color6, apiData.cable0Color7,
    ];
    
    for (int i = 0; i < 8; i++) {
      cable0Sensors.add(CableSensorData(
        level: cable0Levels[i],
        color: cable0Colors[i],
      ));
    }
    cables.add(CableData(cableIndex: 0, sensors: cable0Sensors));

    // Process Cable 1 (only for circular silos with cable_count = 2)
    if (actualCableCount == 2) {
      final cable1Sensors = <CableSensorData>[];
      final cable1Levels = [
        apiData.cable1Level0, apiData.cable1Level1, apiData.cable1Level2, apiData.cable1Level3,
        apiData.cable1Level4, apiData.cable1Level5, apiData.cable1Level6, apiData.cable1Level7,
      ];
      final cable1Colors = [
        apiData.cable1Color0, apiData.cable1Color1, apiData.cable1Color2, apiData.cable1Color3,
        apiData.cable1Color4, apiData.cable1Color5, apiData.cable1Color6, apiData.cable1Color7,
      ];
      
      // Check if Cable 1 data is available
      bool cable1DataAvailable = false;
      for (int i = 0; i < 8; i++) {
        final level = cable1Levels[i];
        if (level != null && !level.isNaN) {
          cable1DataAvailable = true;
          break;
        }
      }
      
      if (!cable1DataAvailable) {
        print('📡 [MAINTENANCE] No Cable 1 data available for silo ${apiData.siloNumber}, using simulated data');
      }
      
      for (int i = 0; i < 8; i++) {
        final level = cable1Levels[i];
        final color = cable1Colors[i];
        
        if (level != null && color != null && !level.isNaN && color.isNotEmpty) {
          // Use real API data (including -127 for disconnected sensors)
          cable1Sensors.add(CableSensorData(level: level, color: color));
        } else {
          // Generate simulated data based on Cable 0 with slight variation
          final baseLevel = cable0Sensors[i].level;
          final variation = (DateTime.now().millisecond % 100 - 50) / 25.0; // ±2°C variation
          final simulatedLevel = (baseLevel + variation).clamp(15.0, 50.0);
          final simulatedColor = simulatedLevel > 40 ? '#d14141' : simulatedLevel > 30 ? '#ff9800' : '#46d446';
          
          cable1Sensors.add(CableSensorData(level: simulatedLevel, color: simulatedColor));
        }
      }
      cables.add(CableData(cableIndex: 1, sensors: cable1Sensors));

      // Use Cable 0 values directly for circular silos (no averaging)
      for (int i = 0; i < 8; i++) {
        final cable0Level = cable0Sensors[i].level;
        
        // Handle disabled sensors (-127 values)
        if (cable0Level == -127) {
          sensorValues.add(-127);
          sensorColors.add('#9ca3af'); // Grey color for disabled sensors
        } else {
          sensorValues.add(cable0Level);
          sensorColors.add(cable0Sensors[i].color);
        }
      }
    } else {
      // For square silos, S1-S8 are direct cable 0 values
      for (int i = 0; i < 8; i++) {
        final cable0Level = cable0Sensors[i].level;
        
        // Handle disabled sensors (-127 values)
        if (cable0Level == -127) {
          sensorValues.add(-127);
          sensorColors.add('#9ca3af'); // Grey color for disabled sensors
        } else {
          sensorValues.add(cable0Level);
          sensorColors.add(cable0Sensors[i].color);
        }
      }
    }

    return MaintenanceSiloData(
      siloNumber: apiData.siloNumber,
      siloGroup: apiData.siloGroup,
      cableCount: actualCableCount,
      timestamp: apiData.timestamp,
      siloColor: apiData.siloColor ?? '#46d446',
      cables: cables,
      sensorValues: sensorValues,
      sensorColors: sensorColors,
    );
  }

  /// Generate simulated maintenance data as fallback
  static MaintenanceSiloData generateSimulatedMaintenanceData(int siloNumber) {
    final isCircular = siloNumber >= 1 && siloNumber <= 61;
    final cableCount = isCircular ? 2 : 1;
    
    final cables = <CableData>[];
    final sensorValues = <double>[];
    final sensorColors = <String>[];

    // Generate cable 0 data
    final cable0Sensors = <CableSensorData>[];
    for (int i = 0; i < 8; i++) {
      final level = 20 + (DateTime.now().millisecond % 100) / 4.0; // 20-45°C
      final color = level > 40 ? '#d14141' : level > 30 ? '#ff9800' : '#46d446';
      cable0Sensors.add(CableSensorData(level: level, color: color));
    }
    cables.add(CableData(cableIndex: 0, sensors: cable0Sensors));

    if (isCircular) {
      // Generate cable 1 data for circular silos
      final cable1Sensors = <CableSensorData>[];
      for (int i = 0; i < 8; i++) {
        final level = 20 + (DateTime.now().millisecond % 100) / 4.0; // 20-45°C
        final color = level > 40 ? '#d14141' : level > 30 ? '#ff9800' : '#46d446';
        cable1Sensors.add(CableSensorData(level: level, color: color));
      }
      cables.add(CableData(cableIndex: 1, sensors: cable1Sensors));

      // Use Cable 0 values directly (no averaging)
      for (int i = 0; i < 8; i++) {
        final level = cable0Sensors[i].level;
        final isDisabled = level == -127;
        sensorValues.add(level);
        sensorColors.add(isDisabled ? '#9ca3af' : cable0Sensors[i].color);
      }
    } else {
      // Direct mapping for square silos
      for (int i = 0; i < 8; i++) {
        final level = cable0Sensors[i].level;
        final isDisabled = level == -127;
        sensorValues.add(level);
        sensorColors.add(isDisabled ? '#9ca3af' : cable0Sensors[i].color);
      }
    }

    // Determine overall silo color (most critical sensor)
    final siloColor = sensorColors.fold('#46d446', (mostCritical, current) => 
        _getMoreCriticalColor(mostCritical, current));

    return MaintenanceSiloData(
      siloNumber: siloNumber,
      siloGroup: 'Group ${(siloNumber / 10).ceil()}',
      cableCount: cableCount,
      timestamp: DateTime.now().toIso8601String(),
      siloColor: siloColor,
      cables: cables,
      sensorValues: sensorValues,
      sensorColors: sensorColors,
    );
  }

  /// Get the more critical color between two sensor colors
  static String _getMoreCriticalColor(String color1, String color2) {
    const colorPriority = {
      '#d14141': 3, // Red - critical
      '#ff9800': 2, // Orange/Yellow - warning
      '#46d446': 1, // Green - normal
    };

    final priority1 = colorPriority[color1] ?? 1;
    final priority2 = colorPriority[color2] ?? 1;

    return priority1 >= priority2 ? color1 : color2;
  }
}
