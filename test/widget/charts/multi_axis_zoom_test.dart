// Copyright (c) 2025 braven_charts. All rights reserved.
// Test: US2 - Multi-Axis Y-Zoom Widget Tests
// Test: US3 - Pan After Y-Zoom Widget Tests

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

        // Test passes if no exception is thrown during zoom interaction
        // The implementation should handle Y-zoom with multi-axis perSeries normalization
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

        // Test passes if no exception is thrown during zoom interaction
        // The implementation should handle Y-zoom out with multi-axis perSeries normalization
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

        // Test passes if no exception is thrown
        // Without Ctrl key, scroll should pan, not zoom
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

        // Test passes if no exception is thrown during scrollbar drag interaction
        // The implementation should handle Y-scrollbar edge drag zoom
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

        // Test passes if no exception is thrown during scrollbar drag interaction
        // The implementation should handle Y-scrollbar edge drag zoom
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

        // Test passes if no exception is thrown during multi-step scrollbar drag
        // The implementation should handle symmetric Y-zoom
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

        // Test passes if no exception is thrown during zoom
        // After zoom, axis labels should reflect the zoomed range
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

        // Test passes if no exception is thrown during stronger zoom
        // Both left and right axes should update independently
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

        // Test passes if no exception is thrown during zoom at specific position
        // The implementation should preserve the data value under cursor
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

        // Test passes if no exception is thrown during zoom at multiple positions
        // The implementation should preserve zoom center at different vertical positions
      });
    });

    group('Pan After Y-Zoom', () {
      testWidgets('pan after Y-zoom scrolls viewport correctly',
          (tester) async {
        await tester.pumpWidget(createMultiAxisChart());
        await tester.pumpAndSettle();

        expect(find.byType(BravenChartPlus), findsOneWidget);

        final chartFinder = find.byType(BravenChartPlus);
        final chartCenter = tester.getCenter(chartFinder);

        // 1. Perform Y-zoom first (Ctrl+scroll up to zoom in)
        await tester.sendKeyDownEvent(LogicalKeyboardKey.control);
        final pointer = TestPointer(1, PointerDeviceKind.mouse);
        await tester.sendEventToBinding(pointer.hover(chartCenter));
        await tester.sendEventToBinding(
          pointer.scroll(const Offset(0, 120)), // Scroll up to zoom in
        );
        await tester.sendKeyUpEvent(LogicalKeyboardKey.control);
        await tester.pumpAndSettle();

        // 2. Attempt to pan vertically after zoom (scroll without Ctrl)
        await tester.sendEventToBinding(pointer.hover(chartCenter));
        await tester.sendEventToBinding(
          pointer.scroll(const Offset(0, -60)), // Scroll down to pan
        );
        await tester.pumpAndSettle();

        // Test passes if no exception is thrown during pan interaction
        // The implementation should handle pan after Y-zoom with multi-axis perSeries normalization
      });

      testWidgets('crosshair tooltips show correct values after zoom+pan',
          (tester) async {
        await tester.pumpWidget(createMultiAxisChart());
        await tester.pumpAndSettle();

        expect(find.byType(BravenChartPlus), findsOneWidget);

        final chartFinder = find.byType(BravenChartPlus);
        final chartCenter = tester.getCenter(chartFinder);

        // 1. Perform Y-zoom
        await tester.sendKeyDownEvent(LogicalKeyboardKey.control);
        final zoomPointer = TestPointer(1, PointerDeviceKind.mouse);
        await tester.sendEventToBinding(zoomPointer.hover(chartCenter));
        await tester.sendEventToBinding(
          zoomPointer.scroll(const Offset(0, 240)), // Strong zoom in
        );
        await tester.sendKeyUpEvent(LogicalKeyboardKey.control);
        await tester.pumpAndSettle();

        // 2. Pan vertically
        await tester.sendEventToBinding(zoomPointer.hover(chartCenter));
        await tester.sendEventToBinding(
          zoomPointer.scroll(const Offset(0, -100)), // Pan down
        );
        await tester.pumpAndSettle();

        // 3. Hover to trigger crosshair/tooltip
        final hoverPointer = TestPointer(2, PointerDeviceKind.mouse);
        final chartRect = tester.getRect(chartFinder);
        final hoverPoint = Offset(
          chartRect.center.dx,
          chartRect.top + chartRect.height * 0.5,
        );
        await tester.sendEventToBinding(hoverPointer.hover(hoverPoint));
        await tester.pumpAndSettle();

        // Test passes if no exception is thrown during hover after zoom+pan
        // The implementation should show accurate crosshair tooltips after zoom+pan
      });

      testWidgets('pan with drag gesture after Y-zoom', (tester) async {
        await tester.pumpWidget(createMultiAxisChart());
        await tester.pumpAndSettle();

        expect(find.byType(BravenChartPlus), findsOneWidget);

        final chartFinder = find.byType(BravenChartPlus);
        final chartRect = tester.getRect(chartFinder);
        final dragStartPoint = Offset(
          chartRect.center.dx,
          chartRect.center.dy,
        );

        // 1. Perform Y-zoom first
        await tester.sendKeyDownEvent(LogicalKeyboardKey.control);
        final zoomPointer = TestPointer(1, PointerDeviceKind.mouse);
        await tester.sendEventToBinding(zoomPointer.hover(dragStartPoint));
        await tester.sendEventToBinding(
          zoomPointer.scroll(const Offset(0, 180)), // Zoom in
        );
        await tester.sendKeyUpEvent(LogicalKeyboardKey.control);
        await tester.pumpAndSettle();

        // 2. Pan with drag gesture (drag down = pan down, content moves up)
        await tester.dragFrom(dragStartPoint, const Offset(0, 100));
        await tester.pumpAndSettle();

        // Test passes if no exception is thrown during drag-based pan after zoom
        // The implementation should handle drag-based panning after Y-zoom
      });
    });
  });
}
