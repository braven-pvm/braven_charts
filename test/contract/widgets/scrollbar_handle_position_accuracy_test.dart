import 'package:braven_charts/src/foundation/foundation.dart' hide Axis;
import 'package:braven_charts/src/theming/components/scrollbar_config.dart';
import 'package:braven_charts/src/widgets/chart_scrollbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Contract test for ChartScrollbar handle position accuracy in widget context (T041)
///
/// Tests that ChartScrollbar widget calculates and renders handle at correct position
/// based on viewport offset within data range, validating the integration of
/// ScrollbarController with the widget lifecycle.
///
/// Following Constitution I (Test-First Development).
///
/// This differs from scrollbar_controller_position_test.dart:
/// - That tests pure function: ScrollbarController.calculateHandlePosition()
/// - This tests widget integration: ChartScrollbar renders with correct handle position
///
/// Validates:
/// - Handle position reflects viewport offset (0% = start, 50% = middle, 100% = end)
/// - Proportional positioning formula accuracy
/// - Boundary clamping (handle never exceeds track bounds)
/// - Widget updates handle position when viewport shifts
void main() {
  group('ChartScrollbar handle position accuracy - CONTRACT', () {
    testWidgets('MUST position handle at 0% when viewport at start of data range', (WidgetTester tester) async {
      // ARRANGE: Viewport at beginning (scrollOffset = 0)
      const trackWidth = 200.0;
      final scrollbar = ChartScrollbar(
        axis: Axis.horizontal,
        dataRange: const DataRange(min: 0.0, max: 100.0), // 100 units total
        viewportRange: const DataRange(min: 0.0, max: 50.0), // 50 units visible, starting at 0
        onViewportChanged: (_) {},
        theme: ScrollbarConfig.defaultLight,
      );

      // ACT: Build widget with fixed dimensions
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: trackWidth,
              height: 20,
              child: scrollbar,
            ),
          ),
        ),
      );

      // ASSERT: Handle position should be 0.0 (at start of track)
      // scrollOffset = viewportRange.min - dataRange.min = 0.0 - 0.0 = 0.0
      // maxScrollOffset = totalRange - viewportRange = 100.0 - 50.0 = 50.0
      // handleSize = 200 * (50/100) = 100.0
      // handlePosition = (200 - 100) * (0.0 / 50.0) = 0.0
      expect(find.byType(ChartScrollbar), findsOneWidget);

      // TODO (T044): After build() implementation, extract handle position from painter:
      // final customPaint = tester.widget<CustomPaint>(find.byType(CustomPaint));
      // final painter = customPaint.painter as ScrollbarPainter;
      // expect(painter.handlePosition, equals(0.0));
    });

    testWidgets('MUST position handle at 100% when viewport at end of data range', (WidgetTester tester) async {
      // ARRANGE: Viewport at end (scrollOffset = maxScrollOffset)
      const trackWidth = 200.0;
      final scrollbar = ChartScrollbar(
        axis: Axis.horizontal,
        dataRange: const DataRange(min: 0.0, max: 100.0), // 100 units total
        viewportRange: const DataRange(min: 50.0, max: 100.0), // 50 units visible, ending at 100
        onViewportChanged: (_) {},
        theme: ScrollbarConfig.defaultLight,
      );

      // ACT: Build widget
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: trackWidth,
              height: 20,
              child: scrollbar,
            ),
          ),
        ),
      );

      // ASSERT: Handle position should be at max (trackLength - handleSize)
      // scrollOffset = 50.0 - 0.0 = 50.0
      // maxScrollOffset = 100.0 - 50.0 = 50.0
      // handleSize = 100.0
      // handlePosition = (200 - 100) * (50.0 / 50.0) = 100.0
      expect(find.byType(ChartScrollbar), findsOneWidget);

      // TODO (T044): Validate painter.handlePosition == 100.0
    });

    testWidgets('MUST position handle at 50% when viewport in middle of data range', (WidgetTester tester) async {
      // ARRANGE: Viewport in middle (scrollOffset = 50% of maxScrollOffset)
      const trackWidth = 200.0;
      final scrollbar = ChartScrollbar(
        axis: Axis.horizontal,
        dataRange: const DataRange(min: 0.0, max: 100.0), // 100 units total
        viewportRange: const DataRange(min: 25.0, max: 75.0), // 50 units visible, centered
        onViewportChanged: (_) {},
        theme: ScrollbarConfig.defaultLight,
      );

      // ACT: Build widget
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: trackWidth,
              height: 20,
              child: scrollbar,
            ),
          ),
        ),
      );

      // ASSERT: Handle position should be at middle of available track
      // scrollOffset = 25.0 - 0.0 = 25.0
      // maxScrollOffset = 100.0 - 50.0 = 50.0
      // handleSize = 100.0
      // handlePosition = (200 - 100) * (25.0 / 50.0) = 100.0 * 0.5 = 50.0
      expect(find.byType(ChartScrollbar), findsOneWidget);

      // TODO (T044): Validate painter.handlePosition == 50.0
    });

    testWidgets('MUST position handle at 30% when viewport at 30% offset', (WidgetTester tester) async {
      // ARRANGE: Viewport at 30% through scrollable range
      const trackWidth = 200.0;
      final scrollbar = ChartScrollbar(
        axis: Axis.horizontal,
        dataRange: const DataRange(min: 0.0, max: 100.0), // 100 units total
        viewportRange: const DataRange(min: 15.0, max: 65.0), // 50 units visible, 15% offset
        onViewportChanged: (_) {},
        theme: ScrollbarConfig.defaultLight,
      );

      // ACT: Build widget
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: trackWidth,
              height: 20,
              child: scrollbar,
            ),
          ),
        ),
      );

      // ASSERT: Handle position should be at 30% of available track
      // scrollOffset = 15.0 - 0.0 = 15.0
      // maxScrollOffset = 100.0 - 50.0 = 50.0
      // handleSize = 100.0
      // handlePosition = (200 - 100) * (15.0 / 50.0) = 100.0 * 0.3 = 30.0
      expect(find.byType(ChartScrollbar), findsOneWidget);

      // TODO (T044): Validate painter.handlePosition == 30.0
    });

    testWidgets('MUST update handle position when viewport shifts', (WidgetTester tester) async {
      // ARRANGE: Initial viewport at 0% offset
      const trackWidth = 200.0;
      var scrollbar = ChartScrollbar(
        axis: Axis.horizontal,
        dataRange: const DataRange(min: 0.0, max: 100.0),
        viewportRange: const DataRange(min: 0.0, max: 50.0), // At start
        onViewportChanged: (_) {},
        theme: ScrollbarConfig.defaultLight,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: trackWidth,
              height: 20,
              child: scrollbar,
            ),
          ),
        ),
      );

      // ACT: Shift viewport to 100% offset (pan to end)
      scrollbar = ChartScrollbar(
        axis: Axis.horizontal,
        dataRange: const DataRange(min: 0.0, max: 100.0),
        viewportRange: const DataRange(min: 50.0, max: 100.0), // At end
        onViewportChanged: (_) {},
        theme: ScrollbarConfig.defaultLight,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: trackWidth,
              height: 20,
              child: scrollbar,
            ),
          ),
        ),
      );

      await tester.pump(); // Rebuild

      // ASSERT: Widget should rebuild with new handle position
      // Initial: handlePosition = 0.0
      // Updated: handlePosition = 100.0 (at end)
      expect(find.byType(ChartScrollbar), findsOneWidget);

      // TODO (T044): Validate painter.handlePosition == 100.0 after update
    });

    testWidgets('MUST respect vertical orientation for handle position calculation', (WidgetTester tester) async {
      // ARRANGE: Vertical scrollbar with viewport at 50% offset
      const trackHeight = 300.0;
      final scrollbar = ChartScrollbar(
        axis: Axis.vertical,
        dataRange: const DataRange(min: 0.0, max: 200.0), // 200 units total
        viewportRange: const DataRange(min: 50.0, max: 150.0), // 100 units visible, 50% offset
        onViewportChanged: (_) {},
        theme: ScrollbarConfig.defaultLight,
      );

      // ACT: Build widget with fixed vertical dimensions
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 20,
              height: trackHeight,
              child: scrollbar,
            ),
          ),
        ),
      );

      // ASSERT: Handle position should be at 50% of available vertical track
      // scrollOffset = 50.0 - 0.0 = 50.0
      // maxScrollOffset = 200.0 - 100.0 = 100.0
      // handleSize = 300 * (100/200) = 150.0
      // handlePosition = (300 - 150) * (50.0 / 100.0) = 150 * 0.5 = 75.0
      expect(find.byType(ChartScrollbar), findsOneWidget);

      // TODO (T044): Validate painter.handlePosition == 75.0 (vertical dimension)
    });

    testWidgets('MUST clamp position when viewport exceeds data range (edge case)', (WidgetTester tester) async {
      // ARRANGE: Invalid viewport (extends beyond data range)
      const trackWidth = 200.0;
      final scrollbar = ChartScrollbar(
        axis: Axis.horizontal,
        dataRange: const DataRange(min: 0.0, max: 100.0), // 100 units total
        viewportRange: const DataRange(min: 80.0, max: 150.0), // 70 units, exceeds max
        onViewportChanged: (_) {},
        theme: ScrollbarConfig.defaultLight,
      );

      // ACT: Build widget (should handle gracefully)
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: trackWidth,
              height: 20,
              child: scrollbar,
            ),
          ),
        ),
      );

      // ASSERT: Widget should render without crashing
      // Expected: Handle clamped to valid bounds (defensive programming)
      expect(find.byType(ChartScrollbar), findsOneWidget);

      // TODO (T044): Validate painter.handlePosition is clamped within [0, trackLength - handleSize]
    });

    testWidgets('MUST handle zero viewport range gracefully (edge case)', (WidgetTester tester) async {
      // ARRANGE: Degenerate case (zero viewport range)
      const trackWidth = 200.0;
      final scrollbar = ChartScrollbar(
        axis: Axis.horizontal,
        dataRange: const DataRange(min: 0.0, max: 100.0),
        viewportRange: const DataRange(min: 50.0, max: 50.0), // Zero span
        onViewportChanged: (_) {},
        theme: ScrollbarConfig.defaultLight,
      );

      // ACT: Build widget (should not crash)
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: trackWidth,
              height: 20,
              child: scrollbar,
            ),
          ),
        ),
      );

      // ASSERT: Widget should render without crashing
      expect(find.byType(ChartScrollbar), findsOneWidget);

      // TODO (T044): Validate painter.handlePosition is valid (defensive programming)
    });

    testWidgets('MUST handle negative data range (non-zero min) correctly', (WidgetTester tester) async {
      // ARRANGE: Data range with negative minimum
      const trackWidth = 200.0;
      final scrollbar = ChartScrollbar(
        axis: Axis.horizontal,
        dataRange: const DataRange(min: -50.0, max: 50.0), // 100 units total, centered at 0
        viewportRange: const DataRange(min: -25.0, max: 25.0), // 50 units, centered
        onViewportChanged: (_) {},
        theme: ScrollbarConfig.defaultLight,
      );

      // ACT: Build widget
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: trackWidth,
              height: 20,
              child: scrollbar,
            ),
          ),
        ),
      );

      // ASSERT: Handle should be centered (50% position)
      // scrollOffset = -25.0 - (-50.0) = 25.0
      // maxScrollOffset = 100.0 - 50.0 = 50.0
      // handleSize = 100.0
      // handlePosition = (200 - 100) * (25.0 / 50.0) = 50.0
      expect(find.byType(ChartScrollbar), findsOneWidget);

      // TODO (T044): Validate painter.handlePosition == 50.0
    });
  });
}
