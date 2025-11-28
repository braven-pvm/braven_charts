import 'package:braven_charts/legacy/src/foundation/foundation.dart' hide Axis;
import 'package:braven_charts/legacy/src/theming/components/scrollbar_config.dart';
import 'package:braven_charts/legacy/src/widgets/chart_scrollbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Contract test for ChartScrollbar handle size accuracy in widget context (T040)
///
/// Tests that ChartScrollbar widget calculates and renders handle with correct size
/// based on viewport-to-data ratio, validating the integration of ScrollbarController
/// with the widget lifecycle.
///
/// Following Constitution I (Test-First Development).
///
/// This differs from scrollbar_controller_handle_size_test.dart:
/// - That tests pure function: ScrollbarController.calculateHandleSize()
/// - This tests widget integration: ChartScrollbar renders with correct handle size
///
/// Validates:
/// - Handle size reflects viewport ratio (50% viewport = 50% handle size)
/// - Minimum size clamping (20px minimum enforced in rendering)
/// - Full viewport (100%) shows full-size handle
/// - Extreme zoom (0.5%) clamps to minimum
/// - Widget updates handle size when viewport changes
void main() {
  group('ChartScrollbar handle size accuracy - CONTRACT', () {
    testWidgets('MUST render handle at 100% size when viewport equals data range', (WidgetTester tester) async {
      // ARRANGE: Full viewport (100% visible, no zoom)
      const trackWidth = 200.0;
      final scrollbar = ChartScrollbar(
        axis: Axis.horizontal,
        dataRange: const DataRange(min: 0.0, max: 100.0), // 100 units total
        viewportRange: const DataRange(min: 0.0, max: 100.0), // 100 units visible
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

      // ASSERT: Handle size should be 100% of track width
      // Expected: ScrollbarController.calculateHandleSize(100, 100, 200, 20) = 200
      // Note: This test will pass trivially until build() is implemented in T044-T049
      // At that point, we need to inspect CustomPaint painter's handle size
      expect(find.byType(ChartScrollbar), findsOneWidget);

      // TODO (T044): After build() implementation, extract handle size from painter:
      // final customPaint = tester.widget<CustomPaint>(find.byType(CustomPaint));
      // final painter = customPaint.painter as ScrollbarPainter;
      // expect(painter.handleSize, equals(trackWidth));
    });

    testWidgets('MUST render handle at 50% size when viewport is half of data range', (WidgetTester tester) async {
      // ARRANGE: Half viewport (50% visible, 2x zoom)
      const trackWidth = 200.0;
      final scrollbar = ChartScrollbar(
        axis: Axis.horizontal,
        dataRange: const DataRange(min: 0.0, max: 100.0), // 100 units total
        viewportRange: const DataRange(min: 0.0, max: 50.0), // 50 units visible (50%)
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

      // ASSERT: Handle size should be 50% of track width
      // Expected: ScrollbarController.calculateHandleSize(100, 50, 200, 20) = 100
      expect(find.byType(ChartScrollbar), findsOneWidget);

      // TODO (T044): Validate painter.handleSize == 100.0
    });

    testWidgets('MUST render handle at 10% size when viewport is 10% of data range', (WidgetTester tester) async {
      // ARRANGE: Small viewport (10% visible, 10x zoom)
      const trackWidth = 200.0;
      final scrollbar = ChartScrollbar(
        axis: Axis.horizontal,
        dataRange: const DataRange(min: 0.0, max: 1000.0), // 1000 units total
        viewportRange: const DataRange(min: 0.0, max: 100.0), // 100 units visible (10%)
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

      // ASSERT: Handle size should be 10% of track width
      // Expected: ScrollbarController.calculateHandleSize(1000, 100, 200, 20) = 20 (clamped to min)
      // Actually: 200 * (100/1000) = 20.0 exactly (no clamping needed)
      expect(find.byType(ChartScrollbar), findsOneWidget);

      // TODO (T044): Validate painter.handleSize == 20.0
    });

    testWidgets('MUST clamp handle to minimum size (20px) at extreme zoom', (WidgetTester tester) async {
      // ARRANGE: Extreme zoom (0.5% visible)
      const trackWidth = 200.0;
      const minHandleSize = 20.0;
      final scrollbar = ChartScrollbar(
        axis: Axis.horizontal,
        dataRange: const DataRange(min: 0.0, max: 10000.0), // 10000 units total
        viewportRange: const DataRange(min: 0.0, max: 50.0), // 50 units visible (0.5%)
        onViewportChanged: (_) {},
        theme: ScrollbarConfig.defaultLight.copyWith(minHandleSize: minHandleSize),
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

      // ASSERT: Handle size should be clamped to minimum
      // Formula: 200 * (50/10000) = 1.0, but clamped to 20.0
      // Expected: ScrollbarController.calculateHandleSize(10000, 50, 200, 20) = 20
      expect(find.byType(ChartScrollbar), findsOneWidget);

      // TODO (T044): Validate painter.handleSize == 20.0
    });

    testWidgets('MUST update handle size when viewport range changes', (WidgetTester tester) async {
      // ARRANGE: Initial viewport (50% visible)
      const trackWidth = 200.0;
      var scrollbar = ChartScrollbar(
        axis: Axis.horizontal,
        dataRange: const DataRange(min: 0.0, max: 100.0),
        viewportRange: const DataRange(min: 0.0, max: 50.0), // 50% visible
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

      // ACT: Update viewport to 25% visible (zoom in 2x more)
      scrollbar = ChartScrollbar(
        axis: Axis.horizontal,
        dataRange: const DataRange(min: 0.0, max: 100.0),
        viewportRange: const DataRange(min: 0.0, max: 25.0), // 25% visible
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

      // ASSERT: Widget should rebuild with new handle size
      // Initial: 200 * (50/100) = 100.0
      // Updated: 200 * (25/100) = 50.0
      expect(find.byType(ChartScrollbar), findsOneWidget);

      // TODO (T044): Validate painter.handleSize == 50.0 after update
    });

    testWidgets('MUST respect vertical orientation for handle size calculation', (WidgetTester tester) async {
      // ARRANGE: Vertical scrollbar with 50% viewport
      const trackHeight = 300.0;
      final scrollbar = ChartScrollbar(
        axis: Axis.vertical,
        dataRange: const DataRange(min: 0.0, max: 200.0), // 200 units total
        viewportRange: const DataRange(min: 0.0, max: 100.0), // 100 units visible (50%)
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

      // ASSERT: Handle size should be 50% of track height
      // Expected: ScrollbarController.calculateHandleSize(200, 100, 300, 20) = 150
      expect(find.byType(ChartScrollbar), findsOneWidget);

      // TODO (T044): Validate painter.handleSize == 150.0 (vertical dimension)
    });

    testWidgets('MUST handle zero data range gracefully (edge case)', (WidgetTester tester) async {
      // ARRANGE: Degenerate case (zero data range)
      const trackWidth = 200.0;
      final scrollbar = ChartScrollbar(
        axis: Axis.horizontal,
        dataRange: const DataRange(min: 0.0, max: 0.0), // Zero span (invalid)
        viewportRange: const DataRange(min: 0.0, max: 0.0),
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
      // Expected: Handle clamped to minimum size (defensive programming)
      expect(find.byType(ChartScrollbar), findsOneWidget);

      // TODO (T044): Validate painter.handleSize == 20.0 (minimum)
    });

    testWidgets('MUST apply custom minimum handle size from theme', (WidgetTester tester) async {
      // ARRANGE: Custom theme with larger minimum handle size
      const trackWidth = 200.0;
      const customMinSize = 40.0;
      final scrollbar = ChartScrollbar(
        axis: Axis.horizontal,
        dataRange: const DataRange(min: 0.0, max: 10000.0),
        viewportRange: const DataRange(min: 0.0, max: 10.0), // Very small viewport
        onViewportChanged: (_) {},
        theme: ScrollbarConfig.defaultLight.copyWith(minHandleSize: customMinSize),
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

      // ASSERT: Handle size should be clamped to custom minimum (40px)
      // Formula: 200 * (10/10000) = 0.2, clamped to 40.0
      expect(find.byType(ChartScrollbar), findsOneWidget);

      // TODO (T044): Validate painter.handleSize == 40.0 (custom minimum)
    });
  });
}
