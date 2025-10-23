import 'package:flutter_test/flutter_test.dart';
import 'package:silo_monitoring_mobile/controllers/auto_test_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('AutoTestController Tests', () {
    late AutoTestController controller;

    setUp(() async {
      // Mock SharedPreferences
      SharedPreferences.setMockInitialValues({});
      controller = AutoTestController();
      await controller.initialize();
    });

    tearDown(() {
      controller.dispose();
    });

    test('should initialize with correct default values', () {
      expect(controller.mode, AutoTestMode.none);
      expect(controller.isRunning, false);
      expect(controller.currentSilo, null);
      expect(controller.progress, 0.0);
      expect(controller.isCompleted, false);
      expect(controller.currentGroupIndex, 0);
      expect(controller.disconnectedSilos, isEmpty);
      expect(controller.retryCount, 0);
      expect(controller.isRetryPhase, false);
      expect(controller.totalGroups, 10);
    });

    test('should have correct silo groups structure', () {
      expect(controller.totalGroups, 10);
      expect(controller.totalSilos, 195); // Total silos across all groups
      
      // Test first group silos
      controller.navigateToGroup(0);
      final group1Silos = controller.getCurrentGroupSilos();
      expect(group1Silos, contains(1));
      expect(group1Silos, contains(11));
      expect(group1Silos.length, 11);
    });

    test('should navigate between groups correctly', () {
      // Start at group 0
      expect(controller.currentGroupIndex, 0);
      
      // Navigate to next group
      controller.nextGroup();
      expect(controller.currentGroupIndex, 1);
      
      // Navigate to previous group
      controller.previousGroup();
      expect(controller.currentGroupIndex, 0);
      
      // Navigate to specific group
      controller.navigateToGroup(5);
      expect(controller.currentGroupIndex, 5);
      
      // Test boundaries
      controller.navigateToGroup(-1);
      expect(controller.currentGroupIndex, 5); // Should not change
      
      controller.navigateToGroup(15);
      expect(controller.currentGroupIndex, 5); // Should not change
    });

    test('should not navigate beyond boundaries', () {
      // Test previous at start
      controller.navigateToGroup(0);
      controller.previousGroup();
      expect(controller.currentGroupIndex, 0);
      
      // Test next at end
      controller.navigateToGroup(9);
      controller.nextGroup();
      expect(controller.currentGroupIndex, 9);
    });

    test('should start auto test correctly', () async {
      expect(controller.isRunning, false);
      
      await controller.startAutoTest();
      
      expect(controller.mode, AutoTestMode.auto);
      expect(controller.isRunning, true);
      expect(controller.progress, greaterThan(0.0));
      expect(controller.isCompleted, false);
      expect(controller.phase, AutoTestPhase.scanning);
    });

    test('should stop auto test correctly', () async {
      await controller.startAutoTest();
      expect(controller.isRunning, true);
      
      await controller.stopAutoTest();
      
      expect(controller.mode, AutoTestMode.none);
      expect(controller.isRunning, false);
      expect(controller.currentSilo, null);
    });

    test('should track silo states correctly', () {
      const testSilo = 112;
      
      // Initially idle
      expect(controller.isSiloScanning(testSilo), false);
      expect(controller.isSiloCompleted(testSilo), false);
      expect(controller.isSiloDisconnected(testSilo), false);
      
      // When not running, all should be false
      expect(controller.getSiloProgress(testSilo), 0.0);
    });

    test('should handle group silo retrieval correctly', () {
      // Test each group has correct silos
      for (int i = 0; i < controller.totalGroups; i++) {
        controller.navigateToGroup(i);
        final groupSilos = controller.getCurrentGroupSilos();
        
        expect(groupSilos, isNotEmpty);
        expect(groupSilos.length, greaterThan(0));
        
        // All silo numbers should be positive
        for (final silo in groupSilos) {
          expect(silo, greaterThan(0));
          expect(silo, lessThanOrEqualTo(195));
        }
      }
    });

    test('should get all silos correctly', () {
      final allSilos = controller.getAllSilos();
      
      expect(allSilos.length, 195);
      expect(allSilos, contains(1));
      expect(allSilos, contains(195));
      
      // Should not have duplicates
      final uniqueSilos = allSilos.toSet();
      expect(uniqueSilos.length, allSilos.length);
    });

    test('should handle invalid group navigation gracefully', () {
      controller.navigateToGroup(999);
      final silos = controller.getCurrentGroupSilos();
      expect(silos, isEmpty);
    });
  });

  group('AutoTestState Tests', () {
    test('should serialize and deserialize correctly', () {
      final originalState = AutoTestState(
        isActive: true,
        currentIndex: 5,
        progress: 25.5,
        startTime: 1234567890,
        readingSilo: 112,
        disconnectedSilos: [1, 2, 3],
        retryCount: 2,
        isRetryPhase: true,
        currentGroupIndex: 3,
      );

      final json = originalState.toJson();
      final deserializedState = AutoTestState.fromJson(json);

      expect(deserializedState.isActive, originalState.isActive);
      expect(deserializedState.currentIndex, originalState.currentIndex);
      expect(deserializedState.progress, originalState.progress);
      expect(deserializedState.startTime, originalState.startTime);
      expect(deserializedState.readingSilo, originalState.readingSilo);
      expect(deserializedState.disconnectedSilos, originalState.disconnectedSilos);
      expect(deserializedState.retryCount, originalState.retryCount);
      expect(deserializedState.isRetryPhase, originalState.isRetryPhase);
      expect(deserializedState.currentGroupIndex, originalState.currentGroupIndex);
    });

    test('should handle null values in deserialization', () {
      final json = <String, dynamic>{};
      final state = AutoTestState.fromJson(json);

      expect(state.isActive, false);
      expect(state.currentIndex, 0);
      expect(state.progress, 0.0);
      expect(state.startTime, 0);
      expect(state.readingSilo, null);
      expect(state.disconnectedSilos, isEmpty);
      expect(state.retryCount, 0);
      expect(state.isRetryPhase, false);
      expect(state.currentGroupIndex, 0);
    });
  });
}
