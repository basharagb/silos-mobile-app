import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:silo_monitoring_mobile/widgets/group_pagination_widget.dart';

void main() {
  group('Numbered Pagination Tests', () {
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

    testWidgets('should display numbered page buttons for small total groups', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestWidget(
          GroupPaginationWidget(
            currentGroup: 2,
            totalGroups: 5,
            onGroupChanged: (index) {},
            isAutoTestRunning: false,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should show all page numbers 1-5
      expect(find.text('1'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
      expect(find.text('4'), findsOneWidget);
      expect(find.text('5'), findsOneWidget);
      
      // Should not show ellipsis for small total
      expect(find.text('...'), findsNothing);
    });

    testWidgets('should display ellipsis for large total groups at beginning', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestWidget(
          GroupPaginationWidget(
            currentGroup: 1, // Second page
            totalGroups: 10,
            onGroupChanged: (index) {},
            isAutoTestRunning: false,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should show: 1 2 3 4 5 ... 10
      expect(find.text('1'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
      expect(find.text('4'), findsOneWidget);
      expect(find.text('5'), findsOneWidget);
      expect(find.text('10'), findsOneWidget);
      expect(find.text('...'), findsOneWidget);
      
      // Should not show middle pages
      expect(find.text('6'), findsNothing);
      expect(find.text('7'), findsNothing);
      expect(find.text('8'), findsNothing);
      expect(find.text('9'), findsNothing);
    });

    testWidgets('should display ellipsis for large total groups at end', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestWidget(
          GroupPaginationWidget(
            currentGroup: 8, // Ninth page (near end)
            totalGroups: 10,
            onGroupChanged: (index) {},
            isAutoTestRunning: false,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should show: 1 ... 6 7 8 9 10
      expect(find.text('1'), findsOneWidget);
      expect(find.text('6'), findsOneWidget);
      expect(find.text('7'), findsOneWidget);
      expect(find.text('8'), findsOneWidget);
      expect(find.text('9'), findsOneWidget);
      expect(find.text('10'), findsOneWidget);
      expect(find.text('...'), findsOneWidget);
      
      // Should not show early middle pages
      expect(find.text('2'), findsNothing);
      expect(find.text('3'), findsNothing);
      expect(find.text('4'), findsNothing);
      expect(find.text('5'), findsNothing);
    });

    testWidgets('should display double ellipsis for large total groups in middle', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestWidget(
          GroupPaginationWidget(
            currentGroup: 5, // Sixth page (middle)
            totalGroups: 12,
            onGroupChanged: (index) {},
            isAutoTestRunning: false,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should show: 1 ... 5 6 7 ... 12
      expect(find.text('1'), findsOneWidget);
      expect(find.text('5'), findsOneWidget);
      expect(find.text('6'), findsOneWidget);
      expect(find.text('7'), findsOneWidget);
      expect(find.text('12'), findsOneWidget);
      expect(find.text('...'), findsNWidgets(2)); // Two ellipsis
      
      // Should not show other pages
      expect(find.text('2'), findsNothing);
      expect(find.text('3'), findsNothing);
      expect(find.text('4'), findsNothing);
      expect(find.text('8'), findsNothing);
      expect(find.text('9'), findsNothing);
      expect(find.text('10'), findsNothing);
      expect(find.text('11'), findsNothing);
    });

    testWidgets('should highlight current page button', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestWidget(
          GroupPaginationWidget(
            currentGroup: 2, // Third page
            totalGroups: 5,
            onGroupChanged: (index) {},
            isAutoTestRunning: false,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find all page buttons
      final pageButtons = find.byType(GestureDetector);
      expect(pageButtons, findsWidgets);
      
      // The current page (3) should be highlighted
      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('should handle page button taps', (WidgetTester tester) async {
      int selectedPage = 0;
      
      await tester.pumpWidget(
        createTestWidget(
          GroupPaginationWidget(
            currentGroup: 0,
            totalGroups: 5,
            onGroupChanged: (index) {
              selectedPage = index;
            },
            isAutoTestRunning: false,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap on page 3
      await tester.tap(find.text('3'));
      
      expect(selectedPage, 2); // Zero-indexed, so page 3 = index 2
    });

    testWidgets('should show navigation arrows', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestWidget(
          GroupPaginationWidget(
            currentGroup: 2,
            totalGroups: 5,
            onGroupChanged: (index) {},
            isAutoTestRunning: false,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should show previous and next buttons
      expect(find.byIcon(Icons.chevron_left), findsOneWidget);
      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
    });

    testWidgets('should disable navigation arrows at boundaries', (WidgetTester tester) async {
      // Test at first page
      await tester.pumpWidget(
        createTestWidget(
          GroupPaginationWidget(
            currentGroup: 0, // First page
            totalGroups: 5,
            onGroupChanged: (index) {},
            isAutoTestRunning: false,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Previous button should be disabled (grayed out)
      final prevButton = find.byIcon(Icons.chevron_left);
      expect(prevButton, findsOneWidget);
      
      // Test at last page
      await tester.pumpWidget(
        createTestWidget(
          GroupPaginationWidget(
            currentGroup: 4, // Last page (index 4 for 5 total)
            totalGroups: 5,
            onGroupChanged: (index) {},
            isAutoTestRunning: false,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Next button should be disabled (grayed out)
      final nextButton = find.byIcon(Icons.chevron_right);
      expect(nextButton, findsOneWidget);
    });

    testWidgets('should show quick navigation buttons for large groups', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestWidget(
          GroupPaginationWidget(
            currentGroup: 3,
            totalGroups: 10, // More than 5, should show First/Last buttons
            onGroupChanged: (index) {},
            isAutoTestRunning: false,
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('First'), findsOneWidget);
      expect(find.text('Last'), findsOneWidget);
    });

    testWidgets('should not show quick navigation buttons for small groups', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestWidget(
          GroupPaginationWidget(
            currentGroup: 2,
            totalGroups: 4, // 4 or less, should not show First/Last buttons
            onGroupChanged: (index) {},
            isAutoTestRunning: false,
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('First'), findsNothing);
      expect(find.text('Last'), findsNothing);
    });

    testWidgets('should show auto test running indicator', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestWidget(
          GroupPaginationWidget(
            currentGroup: 1,
            totalGroups: 5,
            onGroupChanged: (index) {},
            isAutoTestRunning: true,
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('AUTO SCANNING'), findsOneWidget);
    });
  });
}
