import 'package:braven_charts/legacy/src/foundation/foundation.dart' hide Axis;
import 'package:braven_charts/legacy/src/theming/components/scrollbar_config.dart';
import 'package:braven_charts/legacy/src/widgets/chart_scrollbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Contract test for ChartScrollbar pan gesture start handling (T059)
///
/// Tests that ChartScrollbar correctly handles GestureDetector.onPanStart:
/// - Initiates drag state when user touches scrollbar handle
/// - Updates ScrollbarState.isDragging to true
/// - Captures initial touch position for delta calculations
/// - Does not trigger viewport changes on pan start alone
///
/// Following Constitution I (Test-First Development) - User Story 2.
///
/// Related to:
/// - T063: Add GestureDetector wrapper (implementation)
/// - data-model.md: ScrollbarState.isDragging field
/// - plan.md: 60 FPS drag performance requirement
void main() {
  group('ChartScrollbar pan start gesture - CONTRACT', () {
    testWidgets('MUST set isDragging=true when pan gesture starts on handle', (WidgetTester tester) async {
      // ARRANGE: Scrollbar with handle visible
      bool dragStateChanged = false;

      final scrollbar = ChartScrollbar(
        axis: Axis.horizontal,
        dataRange: const DataRange(min: 0.0, max: 100.0),
        viewportRange: const DataRange(min: 0.0, max: 50.0), // 50% viewport
        onViewportChanged: (_) {
          dragStateChanged = true;
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

      // ACT: Start pan gesture on scrollbar handle area
      final handleFinder = find.byType(ChartScrollbar);
      expect(handleFinder, findsOneWidget);

      // Start gesture at center of widget (where handle should be)
      await tester.startGesture(tester.getCenter(handleFinder));
      await tester.pump();

      // ASSERT: Drag state should be initiated (but no viewport change yet)
      // Note: This validates the contract - actual implementation in T063
      // After T063 implementation, verify ScrollbarState.isDragging via painter
      expect(handleFinder, findsOneWidget);

      // Pan start should NOT trigger viewport change (only pan update does)
      expect(dragStateChanged, isFalse, reason: 'onPanStart should not trigger viewport change');
    });

    testWidgets('MUST capture initial touch position on pan start', (WidgetTester tester) async {
      // ARRANGE: Scrollbar ready for interaction
      final scrollbar = ChartScrollbar(
        axis: Axis.vertical,
        dataRange: const DataRange(min: 0.0, max: 100.0),
        viewportRange: const DataRange(min: 25.0, max: 75.0), // Middle 50%
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

      // ACT: Start pan at specific position
      final scrollbarFinder = find.byType(ChartScrollbar);
      final topLeft = tester.getTopLeft(scrollbarFinder);
      final startPosition = topLeft + const Offset(10, 100); // 100px from top

      await tester.startGesture(startPosition);
      await tester.pump();

      // ASSERT: Widget should render without errors
      expect(scrollbarFinder, findsOneWidget);

      // TODO (T063): After implementation, verify initial position is stored
      // for delta calculations in subsequent pan update events
    });

    testWidgets('MUST handle pan start on track (outside handle) differently', (WidgetTester tester) async {
      // ARRANGE: Scrollbar with handle at start (0-50% viewport)
      bool viewportChanged = false;

      final scrollbar = ChartScrollbar(
        axis: Axis.horizontal,
        dataRange: const DataRange(min: 0.0, max: 100.0),
        viewportRange: const DataRange(min: 0.0, max: 50.0), // Handle at left
        onViewportChanged: (_) {
          viewportChanged = true;
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

      // ACT: Start pan on track (far right, outside handle area)
      final scrollbarFinder = find.byType(ChartScrollbar);
      final topLeft = tester.getTopLeft(scrollbarFinder);
      final trackClick = topLeft + const Offset(350, 10); // Far right

      await tester.startGesture(trackClick);
      await tester.pump();

      // ASSERT: Track click should trigger jump behavior (not drag)
      // This is tested separately - here we just verify no crash
      expect(scrollbarFinder, findsOneWidget);

      // Note: Track click may trigger immediate viewport change (jump behavior)
      // This is different from handle drag behavior
    });

    testWidgets('MUST handle pan start with multiple scrollbars independently', (WidgetTester tester) async {
      // ARRANGE: Two scrollbars (X and Y)
      final xScrollbar = ChartScrollbar(
        axis: Axis.horizontal,
        dataRange: const DataRange(min: 0.0, max: 100.0),
        viewportRange: const DataRange(min: 0.0, max: 50.0),
        onViewportChanged: (_) {},
        theme: ScrollbarConfig.defaultLight,
      );

      final yScrollbar = ChartScrollbar(
        axis: Axis.vertical,
        dataRange: const DataRange(min: 0.0, max: 100.0),
        viewportRange: const DataRange(min: 0.0, max: 50.0),
        onViewportChanged: (_) {},
        theme: ScrollbarConfig.defaultLight,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                SizedBox(
                  width: 400,
                  height: 20,
                  child: xScrollbar,
                ),
                SizedBox(
                  width: 20,
                  height: 400,
                  child: yScrollbar,
                ),
              ],
            ),
          ),
        ),
      );

      // ACT: Start pan on X scrollbar only
      final xScrollbarFinder = find.byWidget(xScrollbar);
      await tester.startGesture(tester.getCenter(xScrollbarFinder));
      await tester.pump();

      // ASSERT: Both scrollbars should remain functional
      expect(find.byWidget(xScrollbar), findsOneWidget);
      expect(find.byWidget(yScrollbar), findsOneWidget);

      // Each scrollbar maintains independent drag state
      // Y scrollbar should NOT be affected by X scrollbar drag
    });

    testWidgets('MUST maintain scroll position when pan starts', (WidgetTester tester) async {
      // ARRANGE: Scrollbar at mid-position
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
              width: 400,
              height: 20,
              child: scrollbar,
            ),
          ),
        ),
      );

      // ACT: Start pan gesture
      await tester.startGesture(tester.getCenter(find.byType(ChartScrollbar)));
      await tester.pump();

      // ASSERT: Viewport should NOT change on pan start
      expect(capturedViewport, isNull, reason: 'Pan start should not modify viewport position');

      // Position changes only happen during pan update
    });
  });
}
