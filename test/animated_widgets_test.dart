import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:silo_monitoring_mobile/widgets/animated_grain_level.dart';
import 'package:silo_monitoring_mobile/widgets/animated_sensor_readings.dart';

void main() {
  group('Animated Widgets Tests', () {
    Widget createTestWidget(Widget child) {
      return ScreenUtilInit(
        designSize: const Size(375, 812),
        child: MaterialApp(
          home: Scaffold(
            body: child,
          ),
        ),
      );
    }

    group('AnimatedGrainLevel Tests', () {
      testWidgets('should display grain level widget with title', (WidgetTester tester) async {
        await tester.pumpWidget(
          createTestWidget(
            AnimatedGrainLevel(
              selectedSilo: 112,
              isReading: false,
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('Grain Level'), findsOneWidget);
        expect(find.text('Silo 112'), findsOneWidget);
      });

      testWidgets('should show FILLING indicator when reading', (WidgetTester tester) async {
        await tester.pumpWidget(
          createTestWidget(
            AnimatedGrainLevel(
              selectedSilo: 25,
              isReading: true,
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('FILLING'), findsOneWidget);
        expect(find.text('Silo 25'), findsOneWidget);
      });

      testWidgets('should display level indicators L1 to L8', (WidgetTester tester) async {
        await tester.pumpWidget(
          createTestWidget(
            AnimatedGrainLevel(
              selectedSilo: 50,
              isReading: false,
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Should find all level indicators
        for (int i = 1; i <= 8; i++) {
          expect(find.text('L$i'), findsOneWidget);
        }
      });

      testWidgets('should show refresh button', (WidgetTester tester) async {
        await tester.pumpWidget(
          createTestWidget(
            AnimatedGrainLevel(
              selectedSilo: 75,
              isReading: false,
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.refresh), findsOneWidget);
      });

      testWidgets('should handle tap on refresh button', (WidgetTester tester) async {
        bool refreshCalled = false;

        await tester.pumpWidget(
          createTestWidget(
            AnimatedGrainLevel(
              selectedSilo: 100,
              isReading: false,
              onRefresh: () => refreshCalled = true,
            ),
          ),
        );

        await tester.pumpAndSettle();
        await tester.tap(find.byIcon(Icons.refresh));
        
        expect(refreshCalled, true);
      });

      testWidgets('should show loading indicator when loading', (WidgetTester tester) async {
        await tester.pumpWidget(
          createTestWidget(
            AnimatedGrainLevel(
              selectedSilo: 123,
              isReading: false,
            ),
          ),
        );

        // Initially should show loading
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });
    });

    group('AnimatedSensorReadings Tests', () {
      testWidgets('should display sensor readings widget with title', (WidgetTester tester) async {
        await tester.pumpWidget(
          createTestWidget(
            AnimatedSensorReadings(
              selectedSilo: 112,
              isReading: false,
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('Silo Sensors'), findsOneWidget);
        expect(find.text('Silo: 112'), findsOneWidget);
      });

      testWidgets('should show READING indicator when reading', (WidgetTester tester) async {
        await tester.pumpWidget(
          createTestWidget(
            AnimatedSensorReadings(
              selectedSilo: 25,
              isReading: true,
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('READING'), findsOneWidget);
        expect(find.text('Reading Silo: 25'), findsOneWidget);
      });

      testWidgets('should show refresh button', (WidgetTester tester) async {
        await tester.pumpWidget(
          createTestWidget(
            AnimatedSensorReadings(
              selectedSilo: 75,
              isReading: false,
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.refresh), findsOneWidget);
      });

      testWidgets('should handle tap on refresh button', (WidgetTester tester) async {
        bool refreshCalled = false;

        await tester.pumpWidget(
          createTestWidget(
            AnimatedSensorReadings(
              selectedSilo: 100,
              isReading: false,
              onRefresh: () => refreshCalled = true,
            ),
          ),
        );

        await tester.pumpAndSettle();
        await tester.tap(find.byIcon(Icons.refresh));
        
        expect(refreshCalled, true);
      });

      testWidgets('should show loading indicator when loading', (WidgetTester tester) async {
        await tester.pumpWidget(
          createTestWidget(
            AnimatedSensorReadings(
              selectedSilo: 123,
              isReading: false,
            ),
          ),
        );

        // Initially should show loading
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });

      testWidgets('should show error message when no data available', (WidgetTester tester) async {
        await tester.pumpWidget(
          createTestWidget(
            AnimatedSensorReadings(
              selectedSilo: 999,
              isReading: false,
            ),
          ),
        );

        await tester.pumpAndSettle();
        
        // Wait for loading to complete and show error
        await tester.pump(Duration(seconds: 2));

        expect(find.text('No sensor data available'), findsOneWidget);
        expect(find.byIcon(Icons.error_outline), findsOneWidget);
      });
    });

    group('Animation Tests', () {
      testWidgets('should have animation controllers', (WidgetTester tester) async {
        await tester.pumpWidget(
          createTestWidget(
            Column(
              children: [
                AnimatedGrainLevel(
                  selectedSilo: 112,
                  isReading: true,
                ),
                AnimatedSensorReadings(
                  selectedSilo: 112,
                  isReading: true,
                ),
              ],
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Should have AnimatedBuilder widgets for animations
        expect(find.byType(AnimatedBuilder), findsWidgets);
      });

      testWidgets('should update when isReading changes', (WidgetTester tester) async {
        await tester.pumpWidget(
          createTestWidget(
            AnimatedGrainLevel(
              selectedSilo: 112,
              isReading: false,
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Should not show FILLING when not reading
        expect(find.text('FILLING'), findsNothing);

        // Update to reading state
        await tester.pumpWidget(
          createTestWidget(
            AnimatedGrainLevel(
              selectedSilo: 112,
              isReading: true,
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Should show FILLING when reading
        expect(find.text('FILLING'), findsOneWidget);
      });

      testWidgets('should update when selectedSilo changes', (WidgetTester tester) async {
        await tester.pumpWidget(
          createTestWidget(
            AnimatedSensorReadings(
              selectedSilo: 112,
              isReading: false,
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('Silo: 112'), findsOneWidget);

        // Update silo number
        await tester.pumpWidget(
          createTestWidget(
            AnimatedSensorReadings(
              selectedSilo: 25,
              isReading: false,
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('Silo: 25'), findsOneWidget);
      });
    });
  });
}
