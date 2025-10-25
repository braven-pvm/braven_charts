import 'package:braven_charts/src/foundation/foundation.dart' hide Axis;
import 'package:braven_charts/src/theming/components/scrollbar_config.dart';
import 'package:braven_charts/src/widgets/chart_scrollbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Contract test for ChartScrollbar widget rendering (T039)
///
/// Tests that ChartScrollbar widget renders correctly with proper structure.
/// Following Constitution I (Test-First Development).
///
/// Validates:
/// - Widget builds without errors
/// - Correct widget tree structure
/// - ValueNotifier state management
/// - Theme application
/// - Orientation handling
void main() {
  group('ChartScrollbar rendering - CONTRACT', () {
    testWidgets('MUST render horizontal scrollbar without errors', (WidgetTester tester) async {
      // ARRANGE: Create horizontal scrollbar
      final scrollbar = ChartScrollbar(
        axis: Axis.horizontal,
        dataRange: const DataRange(min: 0.0, max: 100.0),
        viewportRange: const DataRange(min: 0.0, max: 50.0),
        onViewportChanged: (_) {},
        theme: ScrollbarConfig.defaultLight,
      );

      // ACT: Build widget
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 200,
              height: 20,
              child: scrollbar,
            ),
          ),
        ),
      );

      // ASSERT: Widget should build without errors
      expect(find.byType(ChartScrollbar), findsOneWidget);
    });

    testWidgets('MUST render vertical scrollbar without errors', (WidgetTester tester) async {
      // ARRANGE: Create vertical scrollbar
      final scrollbar = ChartScrollbar(
        axis: Axis.vertical,
        dataRange: const DataRange(min: 0.0, max: 100.0),
        viewportRange: const DataRange(min: 0.0, max: 50.0),
        onViewportChanged: (_) {},
        theme: ScrollbarConfig.defaultLight,
      );

      // ACT: Build widget
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 20,
              height: 200,
              child: scrollbar,
            ),
          ),
        ),
      );

      // ASSERT: Widget should build without errors
      expect(find.byType(ChartScrollbar), findsOneWidget);
    });

    testWidgets('MUST contain CustomPaint widget for rendering', (WidgetTester tester) async {
      // ARRANGE: Create scrollbar
      final scrollbar = ChartScrollbar(
        axis: Axis.horizontal,
        dataRange: const DataRange(min: 0.0, max: 100.0),
        viewportRange: const DataRange(min: 0.0, max: 50.0),
        onViewportChanged: (_) {},
        theme: ScrollbarConfig.defaultLight,
      );

      // ACT: Build widget
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 200,
              height: 20,
              child: scrollbar,
            ),
          ),
        ),
      );

      // ASSERT: Should contain CustomPaint for rendering (check descendant to avoid MaterialApp's CustomPaint)
      expect(
        find.descendant(
          of: find.byType(ChartScrollbar),
          matching: find.byType(CustomPaint),
        ),
        findsOneWidget,
      );
    });

    testWidgets('MUST update when viewport changes', (WidgetTester tester) async {
      // ARRANGE: Create scrollbar with initial viewport
      var scrollbar = ChartScrollbar(
        axis: Axis.horizontal,
        dataRange: const DataRange(min: 0.0, max: 100.0),
        viewportRange: const DataRange(min: 0.0, max: 50.0),
        onViewportChanged: (_) {},
        theme: ScrollbarConfig.defaultLight,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 200,
              height: 20,
              child: scrollbar,
            ),
          ),
        ),
      );

      // ACT: Update with new viewport
      scrollbar = ChartScrollbar(
        axis: Axis.horizontal,
        dataRange: const DataRange(min: 0.0, max: 100.0),
        viewportRange: const DataRange(min: 25.0, max: 75.0), // Changed viewport
        onViewportChanged: (_) {},
        theme: ScrollbarConfig.defaultLight,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 200,
              height: 20,
              child: scrollbar,
            ),
          ),
        ),
      );

      await tester.pump();

      // ASSERT: Widget should rebuild without errors
      expect(find.byType(ChartScrollbar), findsOneWidget);
    });

    testWidgets('MUST handle full viewport (100% visible)', (WidgetTester tester) async {
      // ARRANGE: Viewport = total range (fully zoomed out)
      final scrollbar = ChartScrollbar(
        axis: Axis.horizontal,
        dataRange: const DataRange(min: 0.0, max: 100.0),
        viewportRange: const DataRange(min: 0.0, max: 100.0), // Full range visible
        onViewportChanged: (_) {},
        theme: ScrollbarConfig.defaultLight,
      );

      // ACT: Build widget
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 200,
              height: 20,
              child: scrollbar,
            ),
          ),
        ),
      );

      // ASSERT: Should render without errors
      expect(find.byType(ChartScrollbar), findsOneWidget);
    });

    testWidgets('MUST handle minimum viewport (highly zoomed in)', (WidgetTester tester) async {
      // ARRANGE: Very small viewport (extreme zoom)
      final scrollbar = ChartScrollbar(
        axis: Axis.horizontal,
        dataRange: const DataRange(min: 0.0, max: 10000.0),
        viewportRange: const DataRange(min: 5000.0, max: 5050.0), // 0.5% visible
        onViewportChanged: (_) {},
        theme: ScrollbarConfig.defaultLight,
      );

      // ACT: Build widget
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 200,
              height: 20,
              child: scrollbar,
            ),
          ),
        ),
      );

      // ASSERT: Should render without errors
      expect(find.byType(ChartScrollbar), findsOneWidget);
    });

    testWidgets('MUST apply theme configuration', (WidgetTester tester) async {
      // ARRANGE: Scrollbar with custom theme
      final customConfig = ScrollbarConfig.defaultDark.copyWith(
        thickness: 16.0,
        trackColor: const Color(0x33FFFFFF),
        handleColor: const Color(0x99FFFFFF),
      );

      final scrollbar = ChartScrollbar(
        axis: Axis.horizontal,
        dataRange: const DataRange(min: 0.0, max: 100.0),
        viewportRange: const DataRange(min: 0.0, max: 50.0),
        onViewportChanged: (_) {},
        theme: customConfig,
      );

      // ACT: Build widget
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 200,
              height: 20,
              child: scrollbar,
            ),
          ),
        ),
      );

      // ASSERT: Should render without errors
      expect(find.byType(ChartScrollbar), findsOneWidget);
    });

    testWidgets('MUST handle zero-size container gracefully', (WidgetTester tester) async {
      // ARRANGE: Scrollbar in zero-size container (edge case)
      final scrollbar = ChartScrollbar(
        axis: Axis.horizontal,
        dataRange: const DataRange(min: 0.0, max: 100.0),
        viewportRange: const DataRange(min: 0.0, max: 50.0),
        onViewportChanged: (_) {},
        theme: ScrollbarConfig.defaultLight,
      );

      // ACT: Build in zero-size container
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 0,
              height: 0,
              child: scrollbar,
            ),
          ),
        ),
      );

      // ASSERT: Should handle gracefully
      expect(find.byType(ChartScrollbar), findsOneWidget);
    });

    testWidgets('MUST dispose resources properly', (WidgetTester tester) async {
      // ARRANGE: Create scrollbar
      final scrollbar = ChartScrollbar(
        axis: Axis.horizontal,
        dataRange: const DataRange(min: 0.0, max: 100.0),
        viewportRange: const DataRange(min: 0.0, max: 50.0),
        onViewportChanged: (_) {},
        theme: ScrollbarConfig.defaultLight,
      );

      // ACT: Build and dispose
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 200,
              height: 20,
              child: scrollbar,
            ),
          ),
        ),
      );

      // Remove widget
      await tester.pumpWidget(const MaterialApp(home: Scaffold()));

      // ASSERT: Should dispose without memory leaks
      expect(find.byType(ChartScrollbar), findsNothing);
    });
  });
}
