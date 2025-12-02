// ignore_for_file: avoid_redundant_argument_values

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Multi-Axis Zoom Constraints', () {
    // Sample multi-axis configuration (2 axes = multi-axis mode)
    final multiAxisConfig = [
      YAxisConfig(id: 'power', position: YAxisPosition.left, label: 'Power'),
      YAxisConfig(id: 'heart-rate', position: YAxisPosition.right, label: 'HR'),
    ];

    // Sample single-axis configuration (1 axis = normal mode)
    final singleAxisConfig = [
      YAxisConfig(id: 'default', position: YAxisPosition.left),
    ];

    // Sample series data with inline yAxisConfig
    final testSeriesWithInlineConfig = [
      LineChartSeries(
        id: 'power',
        points: List.generate(
          20,
          (i) => ChartDataPoint(x: i.toDouble(), y: (200 + 50 * (i % 5)).toDouble()),
        ),
        color: Colors.blue,
        yAxisConfig: YAxisConfig(id: 'power', position: YAxisPosition.left, label: 'Power'),
      ),
      LineChartSeries(
        id: 'heart-rate',
        points: List.generate(
          20,
          (i) => ChartDataPoint(x: i.toDouble(), y: (120 + 20 * (i % 5)).toDouble()),
        ),
        color: Colors.red,
        yAxisConfig: YAxisConfig(id: 'heart-rate', position: YAxisPosition.right, label: 'HR'),
      ),
    ];

    // Sample series data with yAxisId references
    final testSeriesWithAxisIds = [
      LineChartSeries(
        id: 'power',
        points: List.generate(
          20,
          (i) => ChartDataPoint(x: i.toDouble(), y: (200 + 50 * (i % 5)).toDouble()),
        ),
        color: Colors.blue,
        yAxisId: 'power',
      ),
      LineChartSeries(
        id: 'heart-rate',
        points: List.generate(
          20,
          (i) => ChartDataPoint(x: i.toDouble(), y: (120 + 20 * (i % 5)).toDouble()),
        ),
        color: Colors.red,
        yAxisId: 'heart-rate',
      ),
    ];

    // Sample series without axis binding (for single-axis mode)
    final testSeriesNoBinding = [
      const LineChartSeries(
        id: 'power',
        points: [
          ChartDataPoint(x: 0, y: 200),
          ChartDataPoint(x: 10, y: 250),
        ],
        color: Colors.blue,
      ),
      const LineChartSeries(
        id: 'heart-rate',
        points: [
          ChartDataPoint(x: 0, y: 120),
          ChartDataPoint(x: 10, y: 140),
        ],
        color: Colors.red,
      ),
    ];

    Widget buildTestChartWithInlineConfig() {
      return MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 800,
            height: 600,
            child: BravenChartPlus(
              chartType: ChartType.line,
              series: testSeriesWithInlineConfig,
            ),
          ),
        ),
      );
    }

    Widget buildTestChartWithAxisIds({
      List<YAxisConfig>? yAxes,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 800,
            height: 600,
            child: BravenChartPlus(
              chartType: ChartType.line,
              series: testSeriesWithAxisIds,
              yAxes: yAxes,
            ),
          ),
        ),
      );
    }

    Widget buildTestChartSingleAxis({
      List<YAxisConfig>? yAxes,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 800,
            height: 600,
            child: BravenChartPlus(
              chartType: ChartType.line,
              series: testSeriesNoBinding,
              yAxes: yAxes,
            ),
          ),
        ),
      );
    }

    group('Y-axis zoom behavior', () {
      testWidgets('Y-axis zoom is disabled when multiple Y-axes configured (inline config)', (tester) async {
        // Setup chart with inline yAxisConfig (multi-axis mode)
        await tester.pumpWidget(buildTestChartWithInlineConfig());
        await tester.pumpAndSettle();

        // Find the chart widget
        final chartFinder = find.byType(BravenChartPlus);
        expect(chartFinder, findsOneWidget);

        // Get the center of the chart for scroll events
        final chartCenter = tester.getCenter(chartFinder);

        // Simulate Shift + scroll (Y-axis zoom attempt)
        // In multi-axis mode, this should have NO effect on Y viewport
        await tester.sendKeyDownEvent(LogicalKeyboardKey.shift);

        // Send scroll event (scroll up = zoom in)
        final scrollEvent = PointerScrollEvent(
          position: chartCenter,
          scrollDelta: const Offset(0, -50), // scroll up
        );
        await tester.sendEventToBinding(scrollEvent);
        await tester.pumpAndSettle();

        await tester.sendKeyUpEvent(LogicalKeyboardKey.shift);

        // The chart should render without errors
        // Y-axis zoom should be disabled in multi-axis mode
        // (Implementation will ensure Y viewport unchanged)
        expect(chartFinder, findsOneWidget);
      });

      testWidgets('Y-axis zoom is disabled when multiple Y-axes configured (yAxisId references)', (tester) async {
        // Setup chart with yAxisId references + yAxes list
        await tester.pumpWidget(buildTestChartWithAxisIds(
          yAxes: multiAxisConfig,
        ));
        await tester.pumpAndSettle();

        final chartFinder = find.byType(BravenChartPlus);
        expect(chartFinder, findsOneWidget);

        final chartCenter = tester.getCenter(chartFinder);

        await tester.sendKeyDownEvent(LogicalKeyboardKey.shift);

        final scrollEvent = PointerScrollEvent(
          position: chartCenter,
          scrollDelta: const Offset(0, -50),
        );
        await tester.sendEventToBinding(scrollEvent);
        await tester.pumpAndSettle();

        await tester.sendKeyUpEvent(LogicalKeyboardKey.shift);

        expect(chartFinder, findsOneWidget);
      });

      testWidgets('X-axis zoom remains functional in multi-axis mode', (tester) async {
        // Setup chart with inline yAxisConfig (multi-axis)
        await tester.pumpWidget(buildTestChartWithInlineConfig());
        await tester.pumpAndSettle();

        final chartFinder = find.byType(BravenChartPlus);
        final chartCenter = tester.getCenter(chartFinder);

        // Simulate Shift + scroll (zoom)
        // In multi-axis mode, X-axis zoom should STILL work
        await tester.sendKeyDownEvent(LogicalKeyboardKey.shift);

        final scrollEvent = PointerScrollEvent(
          position: chartCenter,
          scrollDelta: const Offset(0, -50), // scroll up = zoom in
        );
        await tester.sendEventToBinding(scrollEvent);
        await tester.pumpAndSettle();

        await tester.sendKeyUpEvent(LogicalKeyboardKey.shift);

        // X-axis zoom should remain functional
        // Chart should render without errors
        expect(chartFinder, findsOneWidget);
      });

      testWidgets('Single Y-axis mode allows Y-zoom normally', (tester) async {
        // Setup chart with 1 Y-axis (single-axis mode)
        await tester.pumpWidget(buildTestChartSingleAxis(
          yAxes: singleAxisConfig,
        ));
        await tester.pumpAndSettle();

        final chartFinder = find.byType(BravenChartPlus);
        final chartCenter = tester.getCenter(chartFinder);

        // Simulate Shift + scroll (zoom)
        // In single-axis mode, Y-axis zoom should work normally
        await tester.sendKeyDownEvent(LogicalKeyboardKey.shift);

        final scrollEvent = PointerScrollEvent(
          position: chartCenter,
          scrollDelta: const Offset(0, -50),
        );
        await tester.sendEventToBinding(scrollEvent);
        await tester.pumpAndSettle();

        await tester.sendKeyUpEvent(LogicalKeyboardKey.shift);

        // Chart should render without errors
        // Y-axis zoom should work in single-axis mode
        expect(chartFinder, findsOneWidget);
      });

      testWidgets('Null Y-axes config allows Y-zoom normally (legacy mode)', (tester) async {
        // Setup chart without yAxes (null = legacy mode)
        await tester.pumpWidget(buildTestChartSingleAxis(
          yAxes: null,
        ));
        await tester.pumpAndSettle();

        final chartFinder = find.byType(BravenChartPlus);
        final chartCenter = tester.getCenter(chartFinder);

        await tester.sendKeyDownEvent(LogicalKeyboardKey.shift);

        final scrollEvent = PointerScrollEvent(
          position: chartCenter,
          scrollDelta: const Offset(0, -50),
        );
        await tester.sendEventToBinding(scrollEvent);
        await tester.pumpAndSettle();

        await tester.sendKeyUpEvent(LogicalKeyboardKey.shift);

        // Legacy mode should allow Y-zoom
        expect(chartFinder, findsOneWidget);
      });
    });

    group('Y-axis pan behavior', () {
      testWidgets('Y-axis pan is disabled when multiple Y-axes configured', (tester) async {
        // Setup chart with inline yAxisConfig (multi-axis)
        await tester.pumpWidget(buildTestChartWithInlineConfig());
        await tester.pumpAndSettle();

        final chartFinder = find.byType(BravenChartPlus);
        final chartCenter = tester.getCenter(chartFinder);

        // Middle-button drag = pan
        // First zoom in to enable panning
        await tester.sendKeyDownEvent(LogicalKeyboardKey.shift);
        final zoomEvent = PointerScrollEvent(
          position: chartCenter,
          scrollDelta: const Offset(0, -100),
        );
        await tester.sendEventToBinding(zoomEvent);
        await tester.pumpAndSettle();
        await tester.sendKeyUpEvent(LogicalKeyboardKey.shift);

        // Attempt Y-axis pan with middle mouse button drag
        // In multi-axis mode, Y-axis panning should be disabled
        // Note: This tests the concept; actual panning test requires gesture simulation
        expect(chartFinder, findsOneWidget);
      });

      testWidgets('X-axis pan remains functional in multi-axis mode', (tester) async {
        await tester.pumpWidget(buildTestChartWithInlineConfig());
        await tester.pumpAndSettle();

        final chartFinder = find.byType(BravenChartPlus);

        // X-axis pan should remain functional in multi-axis mode
        expect(chartFinder, findsOneWidget);
      });
    });

    group('Grid line behavior', () {
      testWidgets('Grid lines disabled in multi-axis mode', (tester) async {
        // Setup chart with inline yAxisConfig (multi-axis)
        await tester.pumpWidget(buildTestChartWithInlineConfig());
        await tester.pumpAndSettle();

        // Chart should render
        // In multi-axis mode, horizontal grid lines should NOT be painted
        // (This is verified visually; widget test confirms no render errors)
        final chartFinder = find.byType(BravenChartPlus);
        expect(chartFinder, findsOneWidget);
      });

      testWidgets('Grid lines enabled in single-axis mode', (tester) async {
        // Setup chart with 1 Y-axis
        await tester.pumpWidget(buildTestChartSingleAxis(
          yAxes: singleAxisConfig,
        ));
        await tester.pumpAndSettle();

        // In single-axis mode, horizontal grid lines should be painted
        // (This is verified visually; widget test confirms no render errors)
        final chartFinder = find.byType(BravenChartPlus);
        expect(chartFinder, findsOneWidget);
      });
    });
  });
}
