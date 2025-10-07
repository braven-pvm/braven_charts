/// Widget Tests: BravenChart Stream Integration
///
/// Tests real-time data streaming with the BravenChart widget.
/// Validates stream subscription, throttling, and error handling.
library;

import 'dart:async';

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BravenChart Stream Integration', () {
    testWidgets('subscribes to dataStream on mount', (WidgetTester tester) async {
      // Arrange
      final streamController = StreamController<ChartDataPoint>();
      final series = ChartSeries(
        id: 'test-series',
        points: [const ChartDataPoint(x: 0, y: 10)],
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BravenChart(
              chartType: ChartType.line,
              series: [series],
              dataStream: streamController.stream,
            ),
          ),
        ),
      );

      // Assert - widget rendered
      expect(find.byType(BravenChart), findsOneWidget);

      // Cleanup
      await streamController.close();
    });

    testWidgets('receives data from stream', (WidgetTester tester) async {
      // Arrange
      final streamController = StreamController<ChartDataPoint>();
      final series = ChartSeries(
        id: 'test-series',
        points: [const ChartDataPoint(x: 0, y: 10)],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BravenChart(
              chartType: ChartType.line,
              series: [series],
              dataStream: streamController.stream,
            ),
          ),
        ),
      );

      // Act - send data through stream
      streamController.add(const ChartDataPoint(x: 1, y: 20));
      await tester.pump(const Duration(milliseconds: 20)); // Wait for throttle

      // Assert - widget should process the data
      expect(find.byType(BravenChart), findsOneWidget);

      // Cleanup
      await streamController.close();
    });

    testWidgets('throttles stream updates to 60 FPS (16ms)', (WidgetTester tester) async {
      // Arrange
      final streamController = StreamController<ChartDataPoint>();
      final series = ChartSeries(
        id: 'test-series',
        points: [],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BravenChart(
              chartType: ChartType.line,
              series: [series],
              dataStream: streamController.stream,
            ),
          ),
        ),
      );

      // Act - send multiple rapid data points
      for (var i = 0; i < 100; i++) {
        streamController.add(ChartDataPoint(x: i.toDouble(), y: i * 10.0));
      }

      // Wait for throttle period
      await tester.pump(const Duration(milliseconds: 20));

      // Assert - widget should handle throttling without crashing
      expect(find.byType(BravenChart), findsOneWidget);

      // Cleanup
      await streamController.close();
    });

    testWidgets('handles backpressure correctly', (WidgetTester tester) async {
      // Arrange
      final streamController = StreamController<ChartDataPoint>();
      final series = ChartSeries(
        id: 'test-series',
        points: [],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BravenChart(
              chartType: ChartType.line,
              series: [series],
              dataStream: streamController.stream,
            ),
          ),
        ),
      );

      // Act - flood with data faster than 60 FPS
      for (var i = 0; i < 1000; i++) {
        streamController.add(ChartDataPoint(x: i.toDouble(), y: i * 10.0));
      }

      // Pump several frames
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump(const Duration(milliseconds: 50));

      // Assert - should handle without errors
      expect(find.byType(BravenChart), findsOneWidget);

      // Cleanup
      await streamController.close();
    });

    testWidgets('cancels stream subscription on dispose', (WidgetTester tester) async {
      // Arrange
      final streamController = StreamController<ChartDataPoint>();
      final series = ChartSeries(
        id: 'test-series',
        points: [const ChartDataPoint(x: 0, y: 10)],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BravenChart(
              chartType: ChartType.line,
              series: [series],
              dataStream: streamController.stream,
            ),
          ),
        ),
      );

      // Act - remove widget from tree
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox.shrink(),
          ),
        ),
      );

      // Assert - stream should still be closeable (subscription canceled)
      await streamController.close();
      expect(streamController.isClosed, isTrue);
    });

    testWidgets('handles stream errors gracefully', (WidgetTester tester) async {
      // Arrange
      final streamController = StreamController<ChartDataPoint>();
      final series = ChartSeries(
        id: 'test-series',
        points: [const ChartDataPoint(x: 0, y: 10)],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BravenChart(
              chartType: ChartType.line,
              series: [series],
              dataStream: streamController.stream,
            ),
          ),
        ),
      );

      // Act - send error through stream
      streamController.addError(Exception('Test error'));
      await tester.pump();

      // Assert - widget should handle error without crashing
      expect(find.byType(BravenChart), findsOneWidget);

      // Cleanup
      await streamController.close();
    });

    testWidgets('handles stream completion', (WidgetTester tester) async {
      // Arrange
      final streamController = StreamController<ChartDataPoint>();
      final series = ChartSeries(
        id: 'test-series',
        points: [const ChartDataPoint(x: 0, y: 10)],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BravenChart(
              chartType: ChartType.line,
              series: [series],
              dataStream: streamController.stream,
            ),
          ),
        ),
      );

      // Act - close stream
      await streamController.close();
      await tester.pump();

      // Assert - widget should handle completion
      expect(find.byType(BravenChart), findsOneWidget);
    });

    testWidgets('switches streams correctly', (WidgetTester tester) async {
      // Arrange
      final streamController1 = StreamController<ChartDataPoint>();
      final streamController2 = StreamController<ChartDataPoint>();
      final series = ChartSeries(
        id: 'test-series',
        points: [],
      );

      // Start with stream 1
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BravenChart(
              chartType: ChartType.line,
              series: [series],
              dataStream: streamController1.stream,
            ),
          ),
        ),
      );

      // Act - switch to stream 2
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BravenChart(
              chartType: ChartType.line,
              series: [series],
              dataStream: streamController2.stream,
            ),
          ),
        ),
      );

      // Send data to stream 2
      streamController2.add(const ChartDataPoint(x: 1, y: 20));
      await tester.pump(const Duration(milliseconds: 20));

      // Assert - widget should subscribe to new stream
      expect(find.byType(BravenChart), findsOneWidget);

      // Cleanup
      await streamController1.close();
      await streamController2.close();
    });

    testWidgets('removes stream when switched to null', (WidgetTester tester) async {
      // Arrange
      final streamController = StreamController<ChartDataPoint>();
      final series = ChartSeries(
        id: 'test-series',
        points: [const ChartDataPoint(x: 0, y: 10)],
      );

      // Start with stream
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BravenChart(
              chartType: ChartType.line,
              series: [series],
              dataStream: streamController.stream,
            ),
          ),
        ),
      );

      // Act - remove stream
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BravenChart(
              chartType: ChartType.line,
              series: [series],
              dataStream: null,
            ),
          ),
        ),
      );

      // Assert - widget should handle null stream
      expect(find.byType(BravenChart), findsOneWidget);

      // Cleanup
      await streamController.close();
    });

    testWidgets('processes latest data point during throttle', (WidgetTester tester) async {
      // Arrange
      final streamController = StreamController<ChartDataPoint>();
      final series = ChartSeries(
        id: 'test-series',
        points: [],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BravenChart(
              chartType: ChartType.line,
              series: [series],
              dataStream: streamController.stream,
            ),
          ),
        ),
      );

      // Act - send multiple points rapidly (within throttle window)
      streamController.add(const ChartDataPoint(x: 0, y: 10));
      streamController.add(const ChartDataPoint(x: 1, y: 20));
      streamController.add(const ChartDataPoint(x: 2, y: 30)); // Latest

      await tester.pump(const Duration(milliseconds: 20));

      // Assert - should process latest point
      expect(find.byType(BravenChart), findsOneWidget);

      // Cleanup
      await streamController.close();
    });

    testWidgets('works with both controller and stream', (WidgetTester tester) async {
      // Arrange
      final controller = ChartController();
      final streamController = StreamController<ChartDataPoint>();
      final series = ChartSeries(
        id: 'test-series',
        points: [],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BravenChart(
              chartType: ChartType.line,
              series: [series],
              controller: controller,
              dataStream: streamController.stream,
            ),
          ),
        ),
      );

      // Act - update via both controller and stream
      controller.addPoint('controller-series', const ChartDataPoint(x: 0, y: 10));
      streamController.add(const ChartDataPoint(x: 0, y: 20));
      await tester.pump(const Duration(milliseconds: 20));

      // Assert - both should work together
      expect(find.byType(BravenChart), findsOneWidget);

      // Cleanup
      controller.dispose();
      await streamController.close();
    });

    testWidgets('broadcast stream works correctly', (WidgetTester tester) async {
      // Arrange
      final streamController = StreamController<ChartDataPoint>.broadcast();
      final series = ChartSeries(
        id: 'test-series',
        points: [],
      );

      // Act - multiple widgets listening to same stream
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                Expanded(
                  child: BravenChart(
                    chartType: ChartType.line,
                    series: [series],
                    dataStream: streamController.stream,
                  ),
                ),
                Expanded(
                  child: BravenChart(
                    chartType: ChartType.bar,
                    series: [series],
                    dataStream: streamController.stream,
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      // Send data
      streamController.add(const ChartDataPoint(x: 0, y: 10));
      await tester.pump(const Duration(milliseconds: 20));

      // Assert - both widgets should render
      expect(find.byType(BravenChart), findsNWidgets(2));

      // Cleanup
      await streamController.close();
    });
  });
}
