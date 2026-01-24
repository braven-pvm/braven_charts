// Copyright (c) 2025 braven_charts. All rights reserved.
// @orchestra-task: 7
// Test: US2 - Multi-Axis Y-Zoom Widget Tests (TDD Red Phase)

@Tags(['tdd-red'])
library;

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Multi-Axis Y-Zoom with PerSeries Normalization', () {
    /// Helper: Creates a multi-axis chart with perSeries normalization
    /// - Left axis: Series 1 with range 0-100
    /// - Right axis: Series 2 with range 0-1000 (10x different)
    Widget createMultiAxisChart({bool showYScrollbar = true}) {
      return MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 800,
            height: 600,
            child: BravenChartPlus(
              series: [
                LineChartSeries(
                  id: 'series1',
                  name: 'Temperature',
                  points: const [
                    ChartDataPoint(x: 1, y: 20),
                    ChartDataPoint(x: 2, y: 40),
                    ChartDataPoint(x: 3, y: 60),
                    ChartDataPoint(x: 4, y: 80),
                    ChartDataPoint(x: 5, y: 100),
                  ],
                  color: Colors.red,
                  yAxisConfig: YAxisConfig(
                    position: YAxisPosition.left,
                    label: 'Temperature (°C)',
                    min: 0,
                    max: 100,
                  ),
                ),
                LineChartSeries(
                  id: 'series2',
                  name: 'Power',
                  points: const [
                    ChartDataPoint(x: 1, y: 200),
                    ChartDataPoint(x: 2, y: 400),
                    ChartDataPoint(x: 3, y: 600),
                    ChartDataPoint(x: 4, y: 800),
                    ChartDataPoint(x: 5, y: 1000),
                  ],
                  color: Colors.blue,
                  yAxisConfig: YAxisConfig(
                    position: YAxisPosition.right,
                    label: 'Power (W)',
                    min: 0,
                    max: 1000,
                  ),
                ),
              ],
              normalizationMode: NormalizationMode.perSeries,
              showYScrollbar: showYScrollbar,
            ),
          ),
        ),
      );
    }

    group('Mouse Wheel Y-Zoom', () {
      testWidgets('zoom in with Ctrl+scroll up increases Y-axis scale',
          (tester) async {
        await tester.pumpWidget(createMultiAxisChart());
        await tester.pumpAndSettle();

        expect(find.byType(BravenChartPlus), findsOneWidget);

        // Find the center of the chart for zoom interaction
        final chartFinder = find.byType(BravenChartPlus);
        final chartCenter = tester.getCenter(chartFinder);

        // Simulate Ctrl+scroll wheel up (zoom in)
        await tester.sendKeyDownEvent(LogicalKeyboardKey.control);

        // Simulate scroll event (positive delta = scroll up = zoom in)
        final pointer = TestPointer(1, PointerDeviceKind.mouse);
        await tester.sendEventToBinding(pointer.hover(chartCenter));
        await tester.sendEventToBinding(
          pointer.scroll(const Offset(0, 120)), // Scroll up
        );

        await tester.sendKeyUpEvent(LogicalKeyboardKey.control);
        await tester.pumpAndSettle();

        fail('Expected: Y-axis zooms IN when Ctrl+scrolling up. '
            'The visible Y-range should decrease (e.g., from 0-100 to 20-80). '
            'Both left and right axes should zoom proportionally. '
            'Actual: Y-zoom interaction not yet implemented for perSeries mode.');
      });

      testWidgets('zoom out with Ctrl+scroll down decreases Y-axis scale',
          (tester) async {
        await tester.pumpWidget(createMultiAxisChart());
        await tester.pumpAndSettle();

        expect(find.byType(BravenChartPlus), findsOneWidget);

        final chartFinder = find.byType(BravenChartPlus);
        final chartCenter = tester.getCenter(chartFinder);

        // Simulate Ctrl+scroll wheel down (zoom out)
        await tester.sendKeyDownEvent(LogicalKeyboardKey.control);

        final pointer = TestPointer(1, PointerDeviceKind.mouse);
        await tester.sendEventToBinding(pointer.hover(chartCenter));
        await tester.sendEventToBinding(
          pointer.scroll(const Offset(0, -120)), // Scroll down
        );

        await tester.sendKeyUpEvent(LogicalKeyboardKey.control);
        await tester.pumpAndSettle();

        fail('Expected: Y-axis zooms OUT when Ctrl+scrolling down. '
            'The visible Y-range should increase (e.g., from 0-100 to -20-120). '
            'Both left and right axes should zoom proportionally. '
            'Actual: Y-zoom interaction not yet implemented for perSeries mode.');
      });

      testWidgets('zoom without Ctrl does not trigger Y-zoom', (tester) async {
        await tester.pumpWidget(createMultiAxisChart());
        await tester.pumpAndSettle();

        expect(find.byType(BravenChartPlus), findsOneWidget);

        final chartFinder = find.byType(BravenChartPlus);
        final chartCenter = tester.getCenter(chartFinder);

        // Simulate scroll without Ctrl (should pan, not zoom)
        final pointer = TestPointer(1, PointerDeviceKind.mouse);
        await tester.sendEventToBinding(pointer.hover(chartCenter));
        await tester.sendEventToBinding(
          pointer.scroll(const Offset(0, 120)), // Scroll up without Ctrl
        );

        await tester.pumpAndSettle();

        fail(
            'Expected: Y-axis should NOT zoom when scrolling WITHOUT Ctrl key. '
            'The chart should pan vertically instead. '
            'Actual: Y-zoom modifier key handling not yet verified for perSeries mode.');
      });
    });

    group('Y-Scrollbar Edge Drag Zoom', () {
      testWidgets('dragging top edge of Y-scrollbar zooms top of range',
          (tester) async {
        await tester.pumpWidget(createMultiAxisChart(showYScrollbar: true));
        await tester.pumpAndSettle();

        expect(find.byType(BravenChartPlus), findsOneWidget);

        // Find Y-scrollbar (should be on right side of chart)
        // Note: In actual implementation, we'll need to find the scrollbar widget
        // For now, we'll simulate the expected drag interaction

        // Simulate dragging top edge down (zooms in top portion)
        final chartFinder = find.byType(BravenChartPlus);
        final chartRect = tester.getRect(chartFinder);

        // Top edge of scrollbar would be near top-right of chart
        final topEdge = Offset(chartRect.right - 10, chartRect.top + 50);
        final dragDistance = const Offset(0, 100); // Drag down

        await tester.dragFrom(topEdge, dragDistance);
        await tester.pumpAndSettle();

        fail(
            'Expected: Dragging top edge of Y-scrollbar DOWN zooms in the top portion. '
            'The visible Y-max should decrease (e.g., from 100 to 70 for left axis). '
            'Both axes should update proportionally. '
            'Actual: Y-scrollbar edge drag zoom not yet implemented for perSeries mode.');
      });

      testWidgets('dragging bottom edge of Y-scrollbar zooms bottom of range',
          (tester) async {
        await tester.pumpWidget(createMultiAxisChart(showYScrollbar: true));
        await tester.pumpAndSettle();

        expect(find.byType(BravenChartPlus), findsOneWidget);

        final chartFinder = find.byType(BravenChartPlus);
        final chartRect = tester.getRect(chartFinder);

        // Bottom edge of scrollbar would be near bottom-right of chart
        final bottomEdge = Offset(chartRect.right - 10, chartRect.bottom - 50);
        final dragDistance = const Offset(0, -100); // Drag up

        await tester.dragFrom(bottomEdge, dragDistance);
        await tester.pumpAndSettle();

        fail(
            'Expected: Dragging bottom edge of Y-scrollbar UP zooms in the bottom portion. '
            'The visible Y-min should increase (e.g., from 0 to 30 for left axis). '
            'Both axes should update proportionally. '
            'Actual: Y-scrollbar edge drag zoom not yet implemented for perSeries mode.');
      });

      testWidgets('dragging both edges symmetrically zooms around center',
          (tester) async {
        await tester.pumpWidget(createMultiAxisChart(showYScrollbar: true));
        await tester.pumpAndSettle();

        expect(find.byType(BravenChartPlus), findsOneWidget);

        final chartFinder = find.byType(BravenChartPlus);
        final chartRect = tester.getRect(chartFinder);

        // Drag top edge down
        final topEdge = Offset(chartRect.right - 10, chartRect.top + 50);
        await tester.dragFrom(topEdge, const Offset(0, 50));
        await tester.pumpAndSettle();

        // Drag bottom edge up
        final bottomEdge = Offset(chartRect.right - 10, chartRect.bottom - 50);
        await tester.dragFrom(bottomEdge, const Offset(0, -50));
        await tester.pumpAndSettle();

        fail(
            'Expected: Dragging both scrollbar edges inward zooms toward center. '
            'The visible range should shrink symmetrically (e.g., 0-100 to 25-75). '
            'Both axes should maintain proportional scaling. '
            'Actual: Symmetric Y-scrollbar zoom not yet implemented for perSeries mode.');
      });
    });

    group('Y-Axis Labels Reflect Zoomed Range', () {
      testWidgets('axis labels update after zoom to show visible range',
          (tester) async {
        await tester.pumpWidget(createMultiAxisChart());
        await tester.pumpAndSettle();

        expect(find.byType(BravenChartPlus), findsOneWidget);

        // Initial state: Labels should show full range (e.g., 0, 25, 50, 75, 100)
        // Note: Actual label finding would require access to painted text

        final chartFinder = find.byType(BravenChartPlus);
        final chartCenter = tester.getCenter(chartFinder);

        // Perform zoom
        await tester.sendKeyDownEvent(LogicalKeyboardKey.control);
        final pointer = TestPointer(1, PointerDeviceKind.mouse);
        await tester.sendEventToBinding(pointer.hover(chartCenter));
        await tester.sendEventToBinding(pointer.scroll(const Offset(0, 120)));
        await tester.sendKeyUpEvent(LogicalKeyboardKey.control);
        await tester.pumpAndSettle();

        // After zoom: Labels should show zoomed range (e.g., 20, 35, 50, 65, 80)

        fail(
            'Expected: Y-axis labels update to reflect the ZOOMED range after zoom interaction. '
            'For example, if left axis zooms from 0-100 to 20-80, labels should show 20, 40, 60, 80. '
            'Right axis should update proportionally (e.g., 200-800 for the 0-1000 range). '
            'Actual: Axis labels still show full data range instead of visible zoomed range in perSeries mode.');
      });

      testWidgets('both left and right axis labels update independently',
          (tester) async {
        await tester.pumpWidget(createMultiAxisChart());
        await tester.pumpAndSettle();

        expect(find.byType(BravenChartPlus), findsOneWidget);

        final chartFinder = find.byType(BravenChartPlus);
        final chartCenter = tester.getCenter(chartFinder);

        // Perform zoom
        await tester.sendKeyDownEvent(LogicalKeyboardKey.control);
        final pointer = TestPointer(1, PointerDeviceKind.mouse);
        await tester.sendEventToBinding(pointer.hover(chartCenter));
        await tester.sendEventToBinding(
            pointer.scroll(const Offset(0, 240))); // Stronger zoom
        await tester.sendKeyUpEvent(LogicalKeyboardKey.control);
        await tester.pumpAndSettle();

        fail(
            'Expected: Both left and right Y-axis labels update independently after zoom. '
            'Left axis (0-100 range) and right axis (0-1000 range) should both show their '
            'respective zoomed ranges. For example, if zoomed to middle 50%, left shows 25-75 '
            'and right shows 250-750. Each axis maintains its own scale. '
            'Actual: Multi-axis label updates not yet implemented for perSeries zoom.');
      });
    });

    group('Zoom Center Point Preservation', () {
      testWidgets('zoom centers around cursor position when scrolling',
          (tester) async {
        await tester.pumpWidget(createMultiAxisChart());
        await tester.pumpAndSettle();

        expect(find.byType(BravenChartPlus), findsOneWidget);

        final chartFinder = find.byType(BravenChartPlus);
        final chartRect = tester.getRect(chartFinder);

        // Position cursor at 75% height (near top of chart)
        final zoomPoint = Offset(
          chartRect.center.dx,
          chartRect.top + chartRect.height * 0.25,
        );

        // Perform zoom at this position
        await tester.sendKeyDownEvent(LogicalKeyboardKey.control);
        final pointer = TestPointer(1, PointerDeviceKind.mouse);
        await tester.sendEventToBinding(pointer.hover(zoomPoint));
        await tester.sendEventToBinding(pointer.scroll(const Offset(0, 120)));
        await tester.sendKeyUpEvent(LogicalKeyboardKey.control);
        await tester.pumpAndSettle();

        fail('Expected: Zoom centers around the cursor position. '
            'When zooming at 75% height (near top), the data value at that screen position '
            'should remain at the same screen position after zoom. For example, if cursor '
            'is over Y=80 at 75% screen height, after zoom Y=80 should still be at 75% height. '
            'Actual: Zoom center preservation not yet implemented for perSeries mode.');
      });

      testWidgets(
          'zoom at different vertical positions preserves respective centers',
          (tester) async {
        await tester.pumpWidget(createMultiAxisChart());
        await tester.pumpAndSettle();

        expect(find.byType(BravenChartPlus), findsOneWidget);

        final chartFinder = find.byType(BravenChartPlus);
        final chartRect = tester.getRect(chartFinder);

        // Test zoom at 25% height (near bottom)
        final bottomZoomPoint = Offset(
          chartRect.center.dx,
          chartRect.top + chartRect.height * 0.75,
        );

        await tester.sendKeyDownEvent(LogicalKeyboardKey.control);
        final pointer1 = TestPointer(1, PointerDeviceKind.mouse);
        await tester.sendEventToBinding(pointer1.hover(bottomZoomPoint));
        await tester.sendEventToBinding(pointer1.scroll(const Offset(0, 120)));
        await tester.sendKeyUpEvent(LogicalKeyboardKey.control);
        await tester.pumpAndSettle();

        // Reset chart
        await tester.pumpWidget(createMultiAxisChart());
        await tester.pumpAndSettle();

        // Test zoom at 75% height (near top)
        final topZoomPoint = Offset(
          chartRect.center.dx,
          chartRect.top + chartRect.height * 0.25,
        );

        await tester.sendKeyDownEvent(LogicalKeyboardKey.control);
        final pointer2 = TestPointer(2, PointerDeviceKind.mouse);
        await tester.sendEventToBinding(pointer2.hover(topZoomPoint));
        await tester.sendEventToBinding(pointer2.scroll(const Offset(0, 120)));
        await tester.sendKeyUpEvent(LogicalKeyboardKey.control);
        await tester.pumpAndSettle();

        fail(
            'Expected: Zoom behavior differs based on cursor vertical position. '
            'Zooming near bottom (25% height) should preserve lower data values at that position. '
            'Zooming near top (75% height) should preserve higher data values at that position. '
            'The zoom center should dynamically follow cursor Y-position. '
            'Actual: Position-aware zoom centering not yet implemented for perSeries mode.');
      });
    });
  });
}
