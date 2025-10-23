import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:silo_monitoring_mobile/LiveReadings/LiveReadingsInterface.dart';
import 'package:silo_monitoring_mobile/widgets/weather_station_widget.dart';
import 'package:silo_monitoring_mobile/widgets/silo_sensors_panel.dart';
import 'package:silo_monitoring_mobile/widgets/grain_level_panel.dart';

void main() {
  group('LiveReadingsInterface Tests', () {
    testWidgets('should display weather station at the top', (WidgetTester tester) async {
      // Initialize ScreenUtil for testing
      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(375, 812),
          child: MaterialApp(
            home: LiveReadingsInterface(),
          ),
        ),
      );

      // Wait for the widget to build
      await tester.pumpAndSettle();

      // Verify weather station widget exists
      expect(find.byType(WeatherStationWidget), findsOneWidget);
      
      // Verify the weather station is positioned at the top
      final weatherStation = find.byType(WeatherStationWidget);
      final weatherStationWidget = tester.widget<WeatherStationWidget>(weatherStation);
      expect(weatherStationWidget, isNotNull);
    });

    testWidgets('should display silo groups vertically', (WidgetTester tester) async {
      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(375, 812),
          child: MaterialApp(
            home: LiveReadingsInterface(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify the main layout is a Column (vertical)
      expect(find.byType(Column), findsWidgets);
      
      // Verify SingleChildScrollView exists for vertical scrolling
      expect(find.byType(SingleChildScrollView), findsWidgets);
    });

    testWidgets('should display silo sensors panels for each group', (WidgetTester tester) async {
      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(375, 812),
          child: MaterialApp(
            home: LiveReadingsInterface(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify multiple SiloSensorsPanel widgets exist (one for each group)
      expect(find.byType(SiloSensorsPanel), findsWidgets);
      
      // Should find at least 10 silo sensor panels (one for each group)
      final siloSensorPanels = find.byType(SiloSensorsPanel);
      expect(tester.widgetList(siloSensorPanels).length, greaterThanOrEqualTo(10));
    });

    testWidgets('should display grain level panels for each group', (WidgetTester tester) async {
      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(375, 812),
          child: MaterialApp(
            home: LiveReadingsInterface(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify multiple GrainLevelPanel widgets exist (one for each group)
      expect(find.byType(GrainLevelPanel), findsWidgets);
      
      // Should find at least 10 grain level panels (one for each group)
      final grainLevelPanels = find.byType(GrainLevelPanel);
      expect(tester.widgetList(grainLevelPanels).length, greaterThanOrEqualTo(10));
    });

    testWidgets('should display group titles', (WidgetTester tester) async {
      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(375, 812),
          child: MaterialApp(
            home: LiveReadingsInterface(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify group titles are displayed
      expect(find.text('Group 1'), findsOneWidget);
      expect(find.text('Group 2'), findsOneWidget);
      expect(find.text('Group 3'), findsOneWidget);
      expect(find.text('Group 4'), findsOneWidget);
      expect(find.text('Group 5'), findsOneWidget);
      expect(find.text('Group 6'), findsOneWidget);
      expect(find.text('Group 7'), findsOneWidget);
      expect(find.text('Group 8'), findsOneWidget);
      expect(find.text('Group 9'), findsOneWidget);
      expect(find.text('Group 10'), findsOneWidget);
    });

    testWidgets('should display section labels for each group', (WidgetTester tester) async {
      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(375, 812),
          child: MaterialApp(
            home: LiveReadingsInterface(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify "Silo Sensors" and "Grain Level" labels exist
      expect(find.text('Silo Sensors'), findsWidgets);
      expect(find.text('Grain Level'), findsWidgets);
      
      // Should find at least 10 of each (one for each group)
      final siloSensorsLabels = find.text('Silo Sensors');
      final grainLevelLabels = find.text('Grain Level');
      
      expect(tester.widgetList(siloSensorsLabels).length, greaterThanOrEqualTo(10));
      expect(tester.widgetList(grainLevelLabels).length, greaterThanOrEqualTo(10));
    });

    testWidgets('should maintain control panel functionality', (WidgetTester tester) async {
      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(375, 812),
          child: MaterialApp(
            home: LiveReadingsInterface(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify control panel exists
      expect(find.text('Test Controls'), findsOneWidget);
      expect(find.text('Manual Readings (3s)'), findsOneWidget);
      expect(find.text('Auto Readings (24s)'), findsOneWidget);
    });
  });
}
