import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class ApiService {
  // Use local backend server (LAN-based system)
  static const String baseUrl = 'http://192.168.1.65:3000';
  
  // Wheat color for unscanned silos (matching React implementation)
  static const String wheatColor = '#93856b';
  
  // API Endpoints matching React implementation
  static const String readingsEndpoint = '/readings/avg/latest/by-silo-number';
  static const String envTempEndpoint = '/env_temp';
  static const String levelEstimateEndpoint = '/silos/level-estimate/by-number';
  
  static const Duration timeout = Duration(seconds: 10);

  /// Get latest sensor readings for a specific silo
  static Future<SiloSensorData?> getSiloSensorData(int siloNumber) async {
    try {
      final url = '$baseUrl$readingsEndpoint?silo_number=$siloNumber&_t=${DateTime.now().millisecondsSinceEpoch}';
      
      final response = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      ).timeout(timeout);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        if (data.isNotEmpty) {
          return SiloSensorData.fromJson(data[0]);
        }
      }
      return null;
    } catch (e) {
      print('Error fetching silo $siloNumber sensor data: $e');
      return null;
    }
  }

  /// Get environment temperature (cottage inside/outside)
  static Future<WeatherStationData?> getWeatherStationData() async {
    try {
      final url = '$baseUrl$envTempEndpoint';
      
      final response = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      ).timeout(timeout);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return WeatherStationData.fromJson(data);
      }
      return null;
    } catch (e) {
      print('Error fetching weather station data: $e');
      return null;
    }
  }

  /// Get grain level estimate for a specific silo
  static Future<double?> getSiloLevelEstimate(int siloNumber) async {
    try {
      final url = '$baseUrl$levelEstimateEndpoint?silo_number=$siloNumber';
      
      final response = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      ).timeout(timeout);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return data['fill_percent']?.toDouble();
      }
      return null;
    } catch (e) {
      print('Error fetching silo $siloNumber level estimate: $e');
      return null;
    }
  }
}

/// Data model for silo sensor readings
class SiloSensorData {
  final int siloNumber;
  final List<double> sensors; // S1-S8 temperatures
  final List<String> sensorColors; // Color codes for each sensor
  final double maxTemp;
  final String siloColor;
  final DateTime timestamp;

  SiloSensorData({
    required this.siloNumber,
    required this.sensors,
    required this.sensorColors,
    required this.maxTemp,
    required this.siloColor,
    required this.timestamp,
  });

  factory SiloSensorData.fromJson(Map<String, dynamic> json) {
    // Extract sensor readings (level_0 to level_7)
    final sensors = <double>[
      (json['level_0'] ?? 0).toDouble(),
      (json['level_1'] ?? 0).toDouble(),
      (json['level_2'] ?? 0).toDouble(),
      (json['level_3'] ?? 0).toDouble(),
      (json['level_4'] ?? 0).toDouble(),
      (json['level_5'] ?? 0).toDouble(),
      (json['level_6'] ?? 0).toDouble(),
      (json['level_7'] ?? 0).toDouble(),
    ];

    // Extract sensor colors (color_0 to color_7)
    final sensorColors = <String>[
      json['color_0']?.toString() ?? ApiService.wheatColor,
      json['color_1']?.toString() ?? ApiService.wheatColor,
      json['color_2']?.toString() ?? ApiService.wheatColor,
      json['color_3']?.toString() ?? ApiService.wheatColor,
      json['color_4']?.toString() ?? ApiService.wheatColor,
      json['color_5']?.toString() ?? ApiService.wheatColor,
      json['color_6']?.toString() ?? ApiService.wheatColor,
      json['color_7']?.toString() ?? ApiService.wheatColor,
    ];

    // Calculate max temperature from valid sensors
    final validTemperatures = sensors.where((temp) => temp > 0).toList();
    final maxTemp = validTemperatures.isNotEmpty ? validTemperatures.reduce((a, b) => a > b ? a : b) : 0.0;

    return SiloSensorData(
      siloNumber: json['silo_number'] ?? 0,
      sensors: sensors,
      sensorColors: sensorColors,
      maxTemp: maxTemp,
      siloColor: json['silo_color']?.toString() ?? ApiService.wheatColor,
      timestamp: DateTime.tryParse(json['timestamp'] ?? '') ?? DateTime.now(),
    );
  }

}

/// Data model for weather station (cottage) temperatures
class WeatherStationData {
  final double? insideTemp;
  final double? outsideTemp;
  final DateTime timestamp;

  WeatherStationData({
    required this.insideTemp,
    required this.outsideTemp,
    required this.timestamp,
  });

  factory WeatherStationData.fromJson(List<dynamic> json) {
    double? inside;
    double? outside;

    for (var reading in json) {
      if (reading['slave_id'] == 21) {
        inside = reading['temperature_c']?.toDouble();
      } else if (reading['slave_id'] == 22) {
        outside = reading['temperature_c']?.toDouble();
      }
    }

    return WeatherStationData(
      insideTemp: inside,
      outsideTemp: outside,
      timestamp: DateTime.now(),
    );
  }
}
