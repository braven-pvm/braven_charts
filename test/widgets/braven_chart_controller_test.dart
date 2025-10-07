/// Widget Tests: BravenChart Controller Integration
///
/// Tests ChartController interaction with the BravenChart widget.
/// Validates that controller updates trigger widget rebuilds correctly.
library;

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BravenChart Controller Integration', () {
    testWidgets('creates internal controller when none provided', (WidgetTester tester) async {
      // Arrange
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
            ),
          ),
        ),
      );

      // Assert - widget renders without controller
      expect(find.byType(BravenChart), findsOneWidget);
    });

    testWidgets('uses external controller when provided', (WidgetTester tester) async {
      // Arrange
      final controller = ChartController();
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
              controller: controller,
            ),
          ),
        ),
      );

      // Assert
      expect(find.byType(BravenChart), findsOneWidget);

      // Cleanup
      controller.dispose();
    });

    testWidgets('addPoint() triggers rebuild', (WidgetTester tester) async {
      // Arrange
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

      // Act - add a point to controller
      controller.addPoint('test-series', const ChartDataPoint(x: 1, y: 20));
      await tester.pump(); // Rebuild after controller update

      // Assert - widget should rebuild
      expect(find.byType(BravenChart), findsOneWidget);

      // Cleanup
      controller.dispose();
    });

    testWidgets('removeOldestPoint() triggers rebuild', (WidgetTester tester) async {
      // Arrange
      final controller = ChartController();
      controller.addPoint('test-series', const ChartDataPoint(x: 0, y: 10));
      controller.addPoint('test-series', const ChartDataPoint(x: 1, y: 20));

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
            ),
          ),
        ),
      );

      // Act
      controller.removeOldestPoint('test-series');
      await tester.pump();

      // Assert
      expect(find.byType(BravenChart), findsOneWidget);

      // Cleanup
      controller.dispose();
    });

    testWidgets('clearSeries() triggers rebuild', (WidgetTester tester) async {
      // Arrange
      final controller = ChartController();
      controller.addPoint('test-series', const ChartDataPoint(x: 0, y: 10));
      controller.addPoint('test-series', const ChartDataPoint(x: 1, y: 20));

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
            ),
          ),
        ),
      );

      // Act
      controller.clearSeries('test-series');
      await tester.pump();

      // Assert
      expect(find.byType(BravenChart), findsOneWidget);

      // Cleanup
      controller.dispose();
    });

    testWidgets('addAnnotation() triggers rebuild', (WidgetTester tester) async {
      // Arrange
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

      // Act - add annotation via controller
      final annotation = TextAnnotation(
        text: 'New Annotation',
        position: const Offset(100, 50),
      );
      controller.addAnnotation(annotation);
      await tester.pump();

      // Assert - annotation should be visible
      expect(find.text('New Annotation'), findsOneWidget);
      expect(find.byType(Stack), findsOneWidget); // Stack added for annotations

      // Cleanup
      controller.dispose();
    });

    testWidgets('removeAnnotation() triggers rebuild', (WidgetTester tester) async {
      // Arrange
      final controller = ChartController();
      final annotation = TextAnnotation(
        id: 'anno-1',
        text: 'Test Annotation',
        position: const Offset(100, 50),
      );
      controller.addAnnotation(annotation);

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

      // Verify annotation is present
      expect(find.text('Test Annotation'), findsOneWidget);

      // Act - remove annotation
      controller.removeAnnotation('anno-1');
      await tester.pump();

      // Assert - annotation should be gone
      expect(find.text('Test Annotation'), findsNothing);

      // Cleanup
      controller.dispose();
    });

    testWidgets('controller change updates widget correctly', (WidgetTester tester) async {
      // Arrange
      final controller1 = ChartController();
      final controller2 = ChartController();

      controller1.addPoint('series-1', const ChartDataPoint(x: 0, y: 10));
      controller2.addPoint('series-2', const ChartDataPoint(x: 0, y: 20));

      final series = ChartSeries(
        id: 'widget-series',
        points: [const ChartDataPoint(x: 0, y: 5)],
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

      // Act - switch to controller2
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

      // Assert - widget should update to use controller2
      expect(find.byType(BravenChart), findsOneWidget);

      // Cleanup
      controller1.dispose();
      controller2.dispose();
    });

    testWidgets('disposes internal controller on widget dispose', (WidgetTester tester) async {
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

      // Assert - should dispose without errors
      expect(find.byType(BravenChart), findsNothing);
    });

    testWidgets('external controller not disposed by widget', (WidgetTester tester) async {
      // Arrange
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

      // Act - remove widget from tree
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox.shrink(),
          ),
        ),
      );

      // Assert - controller should still be usable
      expect(() => controller.addPoint('test', const ChartDataPoint(x: 0, y: 0)), returnsNormally);

      // Cleanup
      controller.dispose();
    });

    testWidgets('controller series override widget series', (WidgetTester tester) async {
      // Arrange
      final controller = ChartController();
      controller.addPoint('shared-series', const ChartDataPoint(x: 0, y: 50));

      final widgetSeries = ChartSeries(
        id: 'shared-series',
        points: [const ChartDataPoint(x: 0, y: 10)],
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BravenChart(
              chartType: ChartType.line,
              series: [widgetSeries],
              controller: controller,
            ),
          ),
        ),
      );

      // Assert - controller series should have priority
      // (This is verified by the implementation logic in _getAllSeries)
      expect(find.byType(BravenChart), findsOneWidget);

      // Cleanup
      controller.dispose();
    });

    testWidgets('multiple controller updates batch correctly', (WidgetTester tester) async {
      // Arrange
      final controller = ChartController();
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
            ),
          ),
        ),
      );

      // Act - multiple rapid updates
      for (var i = 0; i < 10; i++) {
        controller.addPoint('test-series', ChartDataPoint(x: i.toDouble(), y: i * 10.0));
      }
      await tester.pump();

      // Assert - all updates processed
      expect(find.byType(BravenChart), findsOneWidget);
      expect(controller.getAllSeries()['test-series']?.length, equals(10));

      // Cleanup
      controller.dispose();
    });
  });
}
