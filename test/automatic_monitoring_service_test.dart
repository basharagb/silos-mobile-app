import 'package:flutter_test/flutter_test.dart';
import '../lib/services/automatic_monitoring_service.dart';
import '../lib/services/api_service.dart';

void main() {
  group('AutomaticMonitoringService', () {
    late AutomaticMonitoringService service;

    setUp(() {
      service = AutomaticMonitoringService();
      service.clearCache(); // Clear any existing cache
    });

    tearDown(() {
      service.stopMonitoring();
      service.clearCache();
    });

    test('should be a singleton', () {
      final service1 = AutomaticMonitoringService();
      final service2 = AutomaticMonitoringService();
      expect(service1, equals(service2));
    });

    test('should start and stop monitoring correctly', () {
      expect(service.isRunning, isFalse);
      
      service.startMonitoring();
      expect(service.isRunning, isTrue);
      
      service.stopMonitoring();
      expect(service.isRunning, isFalse);
    });

    test('should not start monitoring if already running', () {
      service.startMonitoring();
      expect(service.isRunning, isTrue);
      
      // Try to start again - should remain running but not create duplicate timers
      service.startMonitoring();
      expect(service.isRunning, isTrue);
    });

    test('should return correct monitoring stats', () {
      final stats = service.getMonitoringStats();
      
      expect(stats['totalSilos'], equals(195));
      expect(stats['cachedSilos'], equals(0)); // Initially empty
      expect(stats['freshSilos'], equals(0)); // Initially empty
      expect(stats['isRunning'], isFalse);
      expect(stats['isBatchChecking'], isFalse);
    });

    test('should detect disconnected silos correctly', () {
      // Test with no cached data
      expect(service.isSiloDisconnected(1), isTrue);
      
      // Test with valid cached data
      final validData = SiloSensorData(
        siloNumber: 1,
        sensors: [25.0, 26.0, 24.0, 25.5, 0.0, 0.0, 0.0, 0.0],
        sensorColors: List.filled(8, '#46d446'),
        maxTemp: 26.0,
        siloColor: '#46d446',
        timestamp: DateTime.now(),
      );
      
      service.cachedSiloData[1] = validData;
      expect(service.isSiloDisconnected(1), isFalse);
      
      // Test with disconnected data (all sensors 0)
      final disconnectedData = SiloSensorData(
        siloNumber: 2,
        sensors: [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0],
        sensorColors: List.filled(8, '#ffffff'),
        maxTemp: 0.0,
        siloColor: '#ffffff',
        timestamp: DateTime.now(),
      );
      
      service.cachedSiloData[2] = disconnectedData;
      expect(service.isSiloDisconnected(2), isTrue);
      
      // Test with -127.0 temperature (sensor error)
      final errorData = SiloSensorData(
        siloNumber: 3,
        sensors: [-127.0, -127.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0],
        sensorColors: List.filled(8, '#ffffff'),
        maxTemp: -127.0,
        siloColor: '#ffffff',
        timestamp: DateTime.now(),
      );
      
      service.cachedSiloData[3] = errorData;
      expect(service.isSiloDisconnected(3), isTrue);
    });

    test('should return correct silo colors', () {
      // Test default wheat color when no data
      expect(service.getSiloColor(1), equals(ApiService.wheatColor));
      
      // Test API color when available
      final dataWithColor = SiloSensorData(
        siloNumber: 1,
        sensors: [25.0, 26.0, 24.0, 25.5, 0.0, 0.0, 0.0, 0.0],
        sensorColors: List.filled(8, '#46d446'),
        maxTemp: 26.0,
        siloColor: '#d14141', // Red color
        timestamp: DateTime.now(),
      );
      
      service.cachedSiloData[1] = dataWithColor;
      expect(service.getSiloColor(1), equals('#d14141'));
      
      // Test wheat color fallback when silo color is wheat
      final dataWithWheatColor = SiloSensorData(
        siloNumber: 2,
        sensors: [25.0, 26.0, 24.0, 25.5, 0.0, 0.0, 0.0, 0.0],
        sensorColors: List.filled(8, '#46d446'),
        maxTemp: 26.0,
        siloColor: ApiService.wheatColor,
        timestamp: DateTime.now(),
      );
      
      service.cachedSiloData[2] = dataWithWheatColor;
      expect(service.getSiloColor(2), equals(ApiService.wheatColor));
    });

    test('should check data freshness correctly', () {
      final now = DateTime.now();
      
      // Test with no data
      expect(service.isSiloDataFresh(1), isFalse);
      
      // Test with fresh data (within 5 minutes)
      service.lastUpdated[1] = now.subtract(const Duration(minutes: 2));
      expect(service.isSiloDataFresh(1), isTrue);
      
      // Test with stale data (older than 5 minutes)
      service.lastUpdated[2] = now.subtract(const Duration(minutes: 10));
      expect(service.isSiloDataFresh(2), isFalse);
    });

    test('should clear cache correctly', () {
      // Add some test data
      final testData = SiloSensorData(
        siloNumber: 1,
        sensors: [25.0, 26.0, 24.0, 25.5, 0.0, 0.0, 0.0, 0.0],
        sensorColors: List.filled(8, '#46d446'),
        maxTemp: 26.0,
        siloColor: '#46d446',
        timestamp: DateTime.now(),
      );
      
      service.cachedSiloData[1] = testData;
      service.lastUpdated[1] = DateTime.now();
      
      expect(service.cachedSiloData.length, equals(1));
      expect(service.lastUpdated.length, equals(1));
      
      service.clearCache();
      
      expect(service.cachedSiloData.length, equals(0));
      expect(service.lastUpdated.length, equals(0));
    });

    test('should have correct total silo count', () {
      expect(service.totalSilos, equals(195));
    });

    test('should handle batch checking state correctly', () {
      expect(service.isBatchChecking, isFalse);
      
      // Note: Testing actual batch checking would require mocking HTTP calls
      // and is more complex. This test just verifies the initial state.
    });

    group('Performance Requirements', () {
      test('should complete batch operations within timeout', () async {
        // This test verifies that the batch timeout is set correctly
        // The actual timeout is 3 seconds as per requirements
        expect(AutomaticMonitoringService.batchTimeout, equals(const Duration(seconds: 3)));
      });

      test('should use correct monitoring interval', () {
        // Verify 3-minute interval as per requirements
        expect(AutomaticMonitoringService.monitoringInterval, equals(const Duration(minutes: 3)));
      });
    });

    group('Error Handling', () {
      test('should handle null data gracefully', () {
        expect(service.getCachedSiloData(999), isNull);
        expect(service.getSiloMaxTemp(999), isNull);
        expect(service.isSiloDisconnected(999), isTrue); // No data = disconnected
      });

      test('should handle invalid silo numbers', () {
        expect(service.getCachedSiloData(-1), isNull);
        expect(service.getCachedSiloData(0), isNull);
        expect(service.getCachedSiloData(1000), isNull);
      });
    });
  });
}
