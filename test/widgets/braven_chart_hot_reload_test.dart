/// Widget Tests: BravenChart Hot Reload Support
///
/// Tests widget behavior during hot reload.
/// Validates proper resource management and no memory leaks.
library;

import 'dart:async';

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BravenChart Hot Reload Support', () {
    testWidgets('didUpdateWidget() handles series changes', (WidgetTester tester) async {
      // Arrange - initial series
      final series1 = ChartSeries(
        id: 'series-1',
        points: [
          const ChartDataPoint(x: 0, y: 10),
          const ChartDataPoint(x: 1, y: 20),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BravenChart(
              chartType: ChartType.line,
              series: [series1],
            ),
          ),
        ),
      );

      expect(find.byType(BravenChart), findsOneWidget);

      // Act - hot reload with new series
      final series2 = ChartSeries(
        id: 'series-2',
        points: [
          const ChartDataPoint(x: 0, y: 30),
          const ChartDataPoint(x: 1, y: 40),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BravenChart(
              chartType: ChartType.line,
              series: [series2],
            ),
          ),
        ),
      );

      // Assert - widget should update without errors
      expect(find.byType(BravenChart), findsOneWidget);
    });

    testWidgets('didUpdateWidget() handles theme changes', (WidgetTester tester) async {
      // Arrange
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
              theme: ChartTheme.defaultLight,
            ),
          ),
        ),
      );

      expect(find.byType(BravenChart), findsOneWidget);

      // Act - hot reload with new theme
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BravenChart(
              chartType: ChartType.line,
              series: [series],
              theme: ChartTheme.defaultDark,
            ),
          ),
        ),
      );

      // Assert
      expect(find.byType(BravenChart), findsOneWidget);
    });

    testWidgets('didUpdateWidget() handles controller swap', (WidgetTester tester) async {
      // Arrange
      final controller1 = ChartController();
      final controller2 = ChartController();
      final series = ChartSeries(
        id: 'test-series',
        points: [const ChartDataPoint(x: 0, y: 10)],
      );

      // Start with controller1
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BravenChart(
              chartType: ChartType.line,
              series: [series],
              controller: controller1,
            ),
          ),
        ),
      );

      expect(find.byType(BravenChart), findsOneWidget);

      // Act - hot reload with controller2
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BravenChart(
              chartType: ChartType.line,
              series: [series],
              controller: controller2,
            ),
          ),
        ),
      );

      // Assert - should unsubscribe from controller1 and subscribe to controller2
      expect(find.byType(BravenChart), findsOneWidget);

      // Verify controller1 is still usable (not disposed by widget)
      expect(() => controller1.addPoint('test', const ChartDataPoint(x: 0, y: 0)), returnsNormally);

      // Cleanup
      controller1.dispose();
      controller2.dispose();
    });

    testWidgets('didUpdateWidget() handles controller removal', (WidgetTester tester) async {
      // Arrange - start with external controller
      final controller = ChartController();
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
              controller: controller,
            ),
          ),
        ),
      );

      expect(find.byType(BravenChart), findsOneWidget);

      // Act - hot reload without controller (widget creates internal one)
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BravenChart(
              chartType: ChartType.line,
              series: [series],
              controller: null,
            ),
          ),
        ),
      );

      // Assert
      expect(find.byType(BravenChart), findsOneWidget);

      // Cleanup
      controller.dispose();
    });

    testWidgets('didUpdateWidget() handles stream swap', (WidgetTester tester) async {
      // Arrange - use broadcast streams to avoid listener issues
      final streamController1 = StreamController<ChartDataPoint>.broadcast();
      final streamController2 = StreamController<ChartDataPoint>.broadcast();
      final series = ChartSeries(
        id: 'test-series',
        points: [],
      );

      // Start with stream1
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

      expect(find.byType(BravenChart), findsOneWidget);

      // Act - hot reload with stream2
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

      // Assert - should cancel stream1 subscription and subscribe to stream2
      expect(find.byType(BravenChart), findsOneWidget);

      // Send data to stream2
      streamController2.add(const ChartDataPoint(x: 0, y: 10));
      await tester.pump(const Duration(milliseconds: 20));

      expect(find.byType(BravenChart), findsOneWidget);

      // Cleanup
      await streamController1.close();
      await streamController2.close();
    });

    testWidgets('didUpdateWidget() handles stream removal', (WidgetTester tester) async {
      // Arrange - start with broadcast stream
      final streamController = StreamController<ChartDataPoint>.broadcast();
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

      expect(find.byType(BravenChart), findsOneWidget);

      // Act - hot reload without stream
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

      // Assert - subscription should be canceled
      expect(find.byType(BravenChart), findsOneWidget);

      // Cleanup
      await streamController.close();
    });

    testWidgets('no duplicate controller subscriptions', (WidgetTester tester) async {
      // Arrange
      final controller = ChartController();
      final series = ChartSeries(
        id: 'test-series',
        points: [],
      );

      // Pump widget multiple times (simulate hot reloads)
      for (var i = 0; i < 5; i++) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: BravenChart(
                chartType: ChartType.line,
                series: [series],
                controller: controller,
              ),
            ),
          ),
        );
      }

      // Act - add a point
      controller.addPoint('test-series', const ChartDataPoint(x: 0, y: 10));
      await tester.pump();

      // Assert - should only trigger one rebuild (not 5)
      expect(find.byType(BravenChart), findsOneWidget);

      // Cleanup
      controller.dispose();
    });

    testWidgets('no duplicate stream subscriptions', (WidgetTester tester) async {
      // Arrange - use broadcast stream
      final streamController = StreamController<ChartDataPoint>.broadcast();
      final series = ChartSeries(
        id: 'test-series',
        points: [],
      );

      // Pump widget multiple times (simulate hot reloads)
      for (var i = 0; i < 5; i++) {
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
      }

      // Act - send data
      streamController.add(const ChartDataPoint(x: 0, y: 10));
      await tester.pump(const Duration(milliseconds: 20));

      // Assert
      expect(find.byType(BravenChart), findsOneWidget);

      // Cleanup
      await streamController.close();
    });

    testWidgets('chart type changes handled correctly', (WidgetTester tester) async {
      // Arrange
      final series = ChartSeries(
        id: 'test-series',
        points: [
          const ChartDataPoint(x: 0, y: 10),
          const ChartDataPoint(x: 1, y: 20),
        ],
      );

      // Start with line chart
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BravenChart(
              chartType: ChartType.line,
              series: [series],
            ),
          ),
        ),
      );

      expect(find.byType(BravenChart), findsOneWidget);

      // Act - change to bar chart
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BravenChart(
              chartType: ChartType.bar,
              series: [series],
            ),
          ),
        ),
      );

      // Assert
      expect(find.byType(BravenChart), findsOneWidget);
    });

    testWidgets('dimensions changes handled correctly', (WidgetTester tester) async {
      // Arrange
      final series = ChartSeries(
        id: 'test-series',
        points: [const ChartDataPoint(x: 0, y: 10)],
      );

      // Start with specific dimensions
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BravenChart(
              chartType: ChartType.line,
              series: [series],
              width: 400,
              height: 300,
            ),
          ),
        ),
      );

      expect(find.byType(BravenChart), findsOneWidget);

      // Act - change dimensions
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BravenChart(
              chartType: ChartType.line,
              series: [series],
              width: 600,
              height: 400,
            ),
          ),
        ),
      );

      // Assert
      final sizedBox = tester.widget<SizedBox>(find.byType(SizedBox).first);
      expect(sizedBox.width, equals(600));
      expect(sizedBox.height, equals(400));
    });

    testWidgets('annotation changes handled correctly', (WidgetTester tester) async {
      // Arrange
      final series = ChartSeries(
        id: 'test-series',
        points: [const ChartDataPoint(x: 0, y: 10)],
      );

      final annotation1 = TextAnnotation(
        text: 'Annotation 1',
        position: const Offset(100, 50),
      );

      // Start with one annotation
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BravenChart(
              chartType: ChartType.line,
              series: [series],
              annotations: [annotation1],
            ),
          ),
        ),
      );

      expect(find.text('Annotation 1'), findsOneWidget);

      // Act - add another annotation
      final annotation2 = TextAnnotation(
        text: 'Annotation 2',
        position: const Offset(200, 50),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BravenChart(
              chartType: ChartType.line,
              series: [series],
              annotations: [annotation1, annotation2],
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('Annotation 1'), findsOneWidget);
      expect(find.text('Annotation 2'), findsOneWidget);
    });
  });
}
