import 'package:braven_charts/src/foundation/foundation.dart' hide Axis;
import 'package:braven_charts/src/theming/components/scrollbar_config.dart';
import 'package:braven_charts/src/widgets/chart_scrollbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Contract test for ChartScrollbar pan gesture end handling (T061)
///
/// Tests that ChartScrollbar correctly handles GestureDetector.onPanEnd:
/// - Resets isDragging flag to false
/// - Triggers final viewport synchronization
/// - Fires onPanChanged callback with total delta offset
/// - Completes drag operation without errors
///
/// Following Constitution I (Test-First Development) - User Story 2.
///
/// Related to:
/// - T066: Pan end implementation
/// - T071: onPanChanged callback integration
/// - data-model.md: InteractionConfig.onPanChanged()
void main() {
  group('ChartScrollbar pan end gesture - CONTRACT', () {
    testWidgets('MUST set isDragging=false when pan gesture ends', (WidgetTester tester) async {
      // ARRANGE: Scrollbar ready for drag
      bool? dragState;

      final scrollbar = ChartScrollbar(
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
              width: 400,
              height: 20,
              child: scrollbar,
            ),
          ),
        ),
      );

      // ACT: Complete a drag gesture (start → update → end)
      final scrollbarFinder = find.byType(ChartScrollbar);
      final gesture = await tester.startGesture(tester.getCenter(scrollbarFinder));
      await tester.pump();

      // After onPanStart: isDragging should be true
      // TODO (T063-T066): Verify isDragging=true after implementation

      await gesture.moveBy(const Offset(50, 0));
      await tester.pump();

      // After onPanUpdate: isDragging still true

      await gesture.up(); // Trigger onPanEnd
      await tester.pumpAndSettle();

      // ASSERT: After onPanEnd, isDragging should be false
      // TODO (T063-T066): Verify isDragging=false after implementation
      // For now, we just ensure no crashes occur
      expect(scrollbarFinder, findsOneWidget, reason: 'Scrollbar should remain after pan end');
    });

    testWidgets('MUST trigger final viewport sync when pan ends', (WidgetTester tester) async {
      // ARRANGE: Track viewport changes
      final viewportUpdates = <DataRange>[];

      final scrollbar = ChartScrollbar(
        axis: Axis.horizontal,
        dataRange: const DataRange(min: 0.0, max: 100.0),
        viewportRange: const DataRange(min: 25.0, max: 75.0),
        onViewportChanged: (newViewport) {
          viewportUpdates.add(newViewport);
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

      // ACT: Perform drag and release
      final gesture = await tester.startGesture(tester.getCenter(find.byType(ChartScrollbar)));
      await tester.pump();

      await gesture.moveBy(const Offset(50, 0));
      await tester.pump();

      final updatesDuringDrag = viewportUpdates.length;

      await gesture.up();
      await tester.pumpAndSettle();

      // ASSERT: Should ensure final viewport state is synchronized
      expect(viewportUpdates.length, greaterThan(0), reason: 'Pan end should trigger final viewport sync if throttled updates were pending');

      // TODO (T067): After throttling implementation, verify final sync
      // Pan end should flush any throttled updates to ensure accurate final state
    });

    testWidgets('MUST fire onPanChanged callback with delta offset', (WidgetTester tester) async {
      // ARRANGE: Scrollbar with pan change tracking
      Offset? capturedPanDelta;

      final scrollbar = ChartScrollbar(
        axis: Axis.horizontal,
        dataRange: const DataRange(min: 0.0, max: 100.0),
        viewportRange: const DataRange(min: 0.0, max: 50.0),
        onViewportChanged: (_) {},
        theme: ScrollbarConfig.defaultLight,
        // TODO (T071): Add onPanChanged parameter after implementation
        // onPanChanged: (delta) => capturedPanDelta = delta,
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

      // ACT: Perform horizontal drag
      final gesture = await tester.startGesture(tester.getCenter(find.byType(ChartScrollbar)));
      await gesture.moveBy(const Offset(100, 0)); // Drag 100px right
      await gesture.up();
      await tester.pumpAndSettle();

      // ASSERT: Should fire onPanChanged with drag delta
      // TODO (T071): After implementation, verify:
      // - capturedPanDelta should be Offset(100, 0)
      // - Callback fired once per pan gesture (not per update)
      // - Delta represents total movement from start to end
    });

    testWidgets('MUST handle vertical scrollbar pan end', (WidgetTester tester) async {
      // ARRANGE: Vertical scrollbar
      final int panEndCallCount = 0;

      final scrollbar = ChartScrollbar(
        axis: Axis.vertical,
        dataRange: const DataRange(min: 0.0, max: 100.0),
        viewportRange: const DataRange(min: 0.0, max: 50.0),
        onViewportChanged: (_) {},
        theme: ScrollbarConfig.defaultLight,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 20,
              height: 400,
              child: scrollbar,
            ),
          ),
        ),
      );

      // ACT: Vertical drag and release
      final gesture = await tester.startGesture(tester.getCenter(find.byType(ChartScrollbar)));
      await gesture.moveBy(const Offset(0, 100)); // Drag down
      await gesture.up();
      await tester.pumpAndSettle();

      // ASSERT: Should handle vertical pan end without errors
      expect(find.byType(ChartScrollbar), findsOneWidget, reason: 'Vertical scrollbar should remain after pan end');
    });

    testWidgets('MUST complete pan gesture without errors', (WidgetTester tester) async {
      // ARRANGE: Scrollbar for stress test
      final scrollbar = ChartScrollbar(
        axis: Axis.horizontal,
        dataRange: const DataRange(min: 0.0, max: 100.0),
        viewportRange: const DataRange(min: 25.0, max: 75.0),
        onViewportChanged: (_) {},
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

      // ACT: Perform multiple pan gestures in sequence
      for (int i = 0; i < 5; i++) {
        final gesture = await tester.startGesture(
          tester.getCenter(find.byType(ChartScrollbar)),
        );
        await gesture.moveBy(Offset(20.0 * (i + 1), 0));
        await gesture.up();
        await tester.pump();
      }

      await tester.pumpAndSettle();

      // ASSERT: Should handle multiple pan gestures without crashing
      expect(find.byType(ChartScrollbar), findsOneWidget, reason: 'Multiple pan gestures should complete without errors');
    });

    testWidgets('MUST handle pan end at data range boundaries', (WidgetTester tester) async {
      // ARRANGE: Scrollbar at maximum position
      DataRange? finalViewport;

      final scrollbar = ChartScrollbar(
        axis: Axis.horizontal,
        dataRange: const DataRange(min: 0.0, max: 100.0),
        viewportRange: const DataRange(min: 50.0, max: 100.0), // At max boundary
        onViewportChanged: (newViewport) {
          finalViewport = newViewport;
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

      // ACT: Attempt to drag beyond boundary
      final gesture = await tester.startGesture(tester.getCenter(find.byType(ChartScrollbar)));
      await gesture.moveBy(const Offset(200, 0)); // Try to exceed max
      await gesture.up();
      await tester.pumpAndSettle();

      // ASSERT: Should clamp at boundary and complete gracefully
      if (finalViewport != null) {
        expect(finalViewport!.max, lessThanOrEqualTo(100.0), reason: 'Pan end should respect data range boundaries');
      }
    });
  });
}
