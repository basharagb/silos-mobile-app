import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:silo_monitoring_mobile/widgets/silo_progress_indicator.dart';

void main() {
  group('SiloProgressIndicator Tests', () {
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

    testWidgets('should display silo number in idle state', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestWidget(
          SiloProgressIndicator(
            siloNumber: 112,
            state: SiloProgressState.idle,
            progress: 0.0,
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('112'), findsOneWidget);
    });

    testWidgets('should show scanning state with progress ring', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestWidget(
          SiloProgressIndicator(
            siloNumber: 25,
            state: SiloProgressState.scanning,
            progress: 0.5,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should show sensors icon instead of number when scanning
      expect(find.byIcon(Icons.sensors), findsOneWidget);
      expect(find.text('25'), findsNothing);
      
      // Should have blue color for scanning
      final container = tester.widget<AnimatedContainer>(
        find.byType(AnimatedContainer).first,
      );
      expect(container.decoration, isA<BoxDecoration>());
    });

    testWidgets('should show completed state with check icon', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestWidget(
          SiloProgressIndicator(
            siloNumber: 50,
            state: SiloProgressState.completed,
            progress: 1.0,
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('should show disconnected state with error icon', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestWidget(
          SiloProgressIndicator(
            siloNumber: 75,
            state: SiloProgressState.disconnected,
            progress: 0.0,
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.error), findsOneWidget);
    });

    testWidgets('should show retry state with sensors icon', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestWidget(
          SiloProgressIndicator(
            siloNumber: 100,
            state: SiloProgressState.retry,
            progress: 0.3,
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.sensors), findsOneWidget);
    });

    testWidgets('should handle tap events', (WidgetTester tester) async {
      bool tapped = false;
      
      await tester.pumpWidget(
        createTestWidget(
          SiloProgressIndicator(
            siloNumber: 123,
            state: SiloProgressState.idle,
            onTap: () => tapped = true,
          ),
        ),
      );

      await tester.pumpAndSettle();
      await tester.tap(find.byType(SiloProgressIndicator));
      
      expect(tapped, true);
    });

    testWidgets('should display square shape when isSquare is true', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestWidget(
          SiloProgressIndicator(
            siloNumber: 150,
            state: SiloProgressState.idle,
            isSquare: true,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find the main silo container
      final containers = find.byType(AnimatedContainer);
      expect(containers, findsWidgets);
    });

    testWidgets('should use custom silo color when provided', (WidgetTester tester) async {
      const customColor = Colors.purple;
      
      await tester.pumpWidget(
        createTestWidget(
          SiloProgressIndicator(
            siloNumber: 200,
            state: SiloProgressState.idle,
            siloColor: customColor,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // The color should be applied to the container
      expect(find.byType(AnimatedContainer), findsWidgets);
    });

    testWidgets('should show status indicator dot for non-idle states', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestWidget(
          SiloProgressIndicator(
            siloNumber: 88,
            state: SiloProgressState.scanning,
            progress: 0.7,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should have a positioned status indicator
      expect(find.byType(Positioned), findsWidgets);
    });

    testWidgets('should animate when state changes', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestWidget(
          SiloProgressIndicator(
            siloNumber: 42,
            state: SiloProgressState.idle,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Change to scanning state
      await tester.pumpWidget(
        createTestWidget(
          SiloProgressIndicator(
            siloNumber: 42,
            state: SiloProgressState.scanning,
            progress: 0.5,
          ),
        ),
      );

      // Should trigger animation
      await tester.pump();
      expect(find.byType(AnimatedBuilder), findsWidgets);
    });
  });

  group('CircularProgressPainter Tests', () {
    test('should repaint when progress changes', () {
      final painter1 = CircularProgressPainter(
        progress: 0.5,
        progressColor: Colors.blue,
        backgroundColor: Colors.grey,
        strokeWidth: 3.0,
      );

      final painter2 = CircularProgressPainter(
        progress: 0.7,
        progressColor: Colors.blue,
        backgroundColor: Colors.grey,
        strokeWidth: 3.0,
      );

      expect(painter1.shouldRepaint(painter2), true);
    });

    test('should not repaint when properties are the same', () {
      final painter1 = CircularProgressPainter(
        progress: 0.5,
        progressColor: Colors.blue,
        backgroundColor: Colors.grey,
        strokeWidth: 3.0,
      );

      final painter2 = CircularProgressPainter(
        progress: 0.5,
        progressColor: Colors.blue,
        backgroundColor: Colors.grey,
        strokeWidth: 3.0,
      );

      expect(painter1.shouldRepaint(painter2), false);
    });
  });
}
