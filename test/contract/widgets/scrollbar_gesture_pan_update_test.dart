import 'package:braven_charts/legacy/src/foundation/foundation.dart' hide Axis;
import 'package:braven_charts/legacy/src/theming/components/scrollbar_config.dart';
import 'package:braven_charts/legacy/src/widgets/chart_scrollbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Contract test for ChartScrollbar pan gesture update handling (T060)
///
/// Tests that ChartScrollbar correctly handles GestureDetector.onPanUpdate:
/// - Calculates viewport delta from drag distance
/// - Triggers onViewportChanged callback with new range
/// - Maintains drag state during continuous updates
/// - Handles rapid pan updates (>60 FPS input rate)
/// - Clamps viewport within data range boundaries
///
/// Following Constitution I (Test-First Development) - User Story 2.
///
/// Related to:
/// - T063-T066: Pan gesture implementation
/// - T062: Throttling test (60 FPS limit)
/// - data-model.md: ScrollbarController.handleToDataRange()
void main() {
  group('ChartScrollbar pan update gesture - CONTRACT', () {
    testWidgets('MUST trigger onViewportChanged when dragging handle', (WidgetTester tester) async {
      // ARRANGE: Scrollbar with handle at start
      DataRange? capturedViewport;
      int callbackCount = 0;

      final scrollbar = ChartScrollbar(
        axis: Axis.horizontal,
        dataRange: const DataRange(min: 0.0, max: 100.0),
        viewportRange: const DataRange(min: 0.0, max: 50.0), // Handle at left
        onViewportChanged: (newViewport) {
          capturedViewport = newViewport;
          callbackCount++;
        },
        theme: ScrollbarConfig.defaultLight,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400, // Track width
              height: 20,
              child: scrollbar,
            ),
          ),
        ),
      );

      // ACT: Drag handle to the right (pan right 100px)
      final scrollbarFinder = find.byType(ChartScrollbar);
      await tester.drag(scrollbarFinder, const Offset(100, 0));
      await tester.pumpAndSettle();

      // ASSERT: onViewportChanged should be called with new range
      expect(callbackCount, greaterThan(0), reason: 'onViewportChanged should be called during pan update');

      expect(capturedViewport, isNotNull, reason: 'Viewport should be updated');

      // TODO (T063-T066): After implementation, verify viewport shift
      // Dragging right should shift viewport right (increase both min and max)
    });

    testWidgets('MUST shift viewport proportionally to drag distance', (WidgetTester tester) async {
      // ARRANGE: Scrollbar in middle position
      DataRange? capturedViewport;

      final scrollbar = ChartScrollbar(
        axis: Axis.horizontal,
        dataRange: const DataRange(min: 0.0, max: 100.0),
        viewportRange: const DataRange(min: 25.0, max: 75.0), // Middle 50%
        onViewportChanged: (newViewport) {
          capturedViewport = newViewport;
        },
        theme: ScrollbarConfig.defaultLight,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400, // Track = 400px, viewport = 50 units (50%)
              height: 20,
              child: scrollbar,
            ),
          ),
        ),
      );

      // ACT: Drag 50px to the right
      // Track = 400px for 100 data units → 1px = 0.25 data units
      // 50px drag = 12.5 data units shift
      await tester.drag(find.byType(ChartScrollbar), const Offset(50, 0));
      await tester.pumpAndSettle();

      // ASSERT: Viewport should shift right
      expect(capturedViewport, isNotNull);

      // TODO (T063-T066): Verify exact shift calculation
      // Expected: min shifts from 25 to ~37.5, max from 75 to ~87.5
      // This validates ScrollbarController.handleToDataRange() integration
    });

    testWidgets('MUST clamp viewport at data range boundaries', (WidgetTester tester) async {
      // ARRANGE: Scrollbar near end of range
      DataRange? capturedViewport;

      final scrollbar = ChartScrollbar(
        axis: Axis.horizontal,
        dataRange: const DataRange(min: 0.0, max: 100.0),
        viewportRange: const DataRange(min: 40.0, max: 90.0), // Near end
        onViewportChanged: (newViewport) {
          capturedViewport = newViewport;
        },
        theme: ScrollbarConfig.defaultLight,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 20,
              child: scrollbar,
            ),
          ),
        ),
      );

      // ACT: Drag far to the right (attempting to exceed data range)
      await tester.drag(find.byType(ChartScrollbar), const Offset(200, 0));
      await tester.pumpAndSettle();

      // ASSERT: Viewport should be clamped at max boundary
      expect(capturedViewport, isNotNull, reason: 'onViewportChanged should be called during pan');

      expect(capturedViewport!.max, lessThanOrEqualTo(100.0), reason: 'Viewport max should not exceed data range max');

      // Viewport size (50 units) should be preserved
      expect(capturedViewport!.span, equals(50.0), reason: 'Viewport size should remain constant during pan');
    });

    testWidgets('MUST handle vertical scrollbar pan updates', (WidgetTester tester) async {
      // ARRANGE: Vertical scrollbar
      DataRange? capturedViewport;

      final scrollbar = ChartScrollbar(
        axis: Axis.vertical,
        dataRange: const DataRange(min: 0.0, max: 100.0),
        viewportRange: const DataRange(min: 0.0, max: 50.0),
        onViewportChanged: (newViewport) {
          capturedViewport = newViewport;
        },
        theme: ScrollbarConfig.defaultLight,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 20,
              height: 400, // Vertical track
              child: scrollbar,
            ),
          ),
        ),
      );

      // ACT: Drag down (positive Y direction)
      await tester.drag(find.byType(ChartScrollbar), const Offset(0, 100));
      await tester.pumpAndSettle();

      // ASSERT: Vertical drag should update viewport
      expect(capturedViewport, isNotNull, reason: 'Vertical scrollbar should respond to vertical drag');

      // TODO (T063-T066): Verify Y-axis direction mapping
      // Dragging down should shift viewport appropriately
    });

    testWidgets('MUST maintain viewport size during pan', (WidgetTester tester) async {
      // ARRANGE: Scrollbar with 30% viewport
      final initialViewportSize = 30.0;
      DataRange? capturedViewport;

      final scrollbar = ChartScrollbar(
        axis: Axis.horizontal,
        dataRange: const DataRange(min: 0.0, max: 100.0),
        viewportRange: DataRange(min: 0.0, max: initialViewportSize),
        onViewportChanged: (newViewport) {
          capturedViewport = newViewport;
        },
        theme: ScrollbarConfig.defaultLight,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 20,
              child: scrollbar,
            ),
          ),
        ),
      );

      // ACT: Perform multiple pan updates
      final scrollbarFinder = find.byType(ChartScrollbar);
      await tester.drag(scrollbarFinder, const Offset(50, 0));
      await tester.pump();

      await tester.drag(scrollbarFinder, const Offset(30, 0));
      await tester.pump();

      // ASSERT: Viewport size should remain constant (only position changes)
      expect(capturedViewport, isNotNull, reason: 'onViewportChanged should be called during pan');

      expect(capturedViewport!.span, equals(initialViewportSize), reason: 'Pan should shift viewport position, not change size');
    });

    testWidgets('MUST handle rapid pan updates without errors', (WidgetTester tester) async {
      // ARRANGE: Scrollbar ready for rapid updates
      int updateCount = 0;

      final scrollbar = ChartScrollbar(
        axis: Axis.horizontal,
        dataRange: const DataRange(min: 0.0, max: 100.0),
        viewportRange: const DataRange(min: 25.0, max: 75.0),
        onViewportChanged: (_) {
          updateCount++;
        },
        theme: ScrollbarConfig.defaultLight,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 20,
              child: scrollbar,
            ),
          ),
        ),
      );

      // ACT: Simulate rapid drag (multiple small updates)
      final scrollbarFinder = find.byType(ChartScrollbar);
      final gesture = await tester.startGesture(tester.getCenter(scrollbarFinder));

      // Simulate many rapid updates (>60 FPS input)
      for (int i = 0; i < 20; i++) {
        await gesture.moveBy(const Offset(5, 0));
        await tester.pump(const Duration(milliseconds: 8)); // ~120 FPS
      }

      await gesture.up();
      await tester.pumpAndSettle();

      // ASSERT: Should handle rapid updates without crashing
      expect(updateCount, greaterThan(0), reason: 'Should process pan updates');

      // Note: T062 tests throttling to 60 FPS
      // This test verifies we can RECEIVE >60 FPS input without errors
    });
  });
}
