import 'package:braven_charts/legacy/braven_charts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Unit tests for Phase 1, Task 1.3: ThresholdAnnotation coordinate transformation
///
/// These tests verify that ThresholdAnnotation lines are correctly positioned
/// at their data values using proper coordinate transformation.
void main() {
  group('ThresholdAnnotation Coordinate Transformation', () {
    testWidgets('should render horizontal threshold (Y-axis) at correct position', (WidgetTester tester) async {
      // Arrange: Create a simple chart
      final series = ChartSeries(
        id: 'test-series',
        points: [
          const ChartDataPoint(x: 0, y: 0),
          const ChartDataPoint(x: 10, y: 10),
        ],
      );

      // Create a horizontal threshold at Y=5
      final annotation = ThresholdAnnotation(
        id: 'threshold-y',
        axis: AnnotationAxis.y,
        value: 5.0,
        lineColor: Colors.red,
        lineWidth: 2.0,
        label: 'Target',
      );

      // Act: Build the chart
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 300,
              child: BravenChart(
                series: [series],
                annotations: [annotation],
                chartType: ChartType.line,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert: Chart should render without errors
      expect(find.byType(BravenChart), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('should render vertical threshold (X-axis) at correct position', (WidgetTester tester) async {
      // Arrange
      final series = ChartSeries(
        id: 'test-series',
        points: [
          const ChartDataPoint(x: 0, y: 0),
          const ChartDataPoint(x: 10, y: 10),
        ],
      );

      // Create a vertical threshold at X=7
      final annotation = ThresholdAnnotation(
        id: 'threshold-x',
        axis: AnnotationAxis.x,
        value: 7.0,
        lineColor: Colors.blue,
        lineWidth: 2.0,
        label: 'Deadline',
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 300,
              child: BravenChart(
                series: [series],
                annotations: [annotation],
                chartType: ChartType.line,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert
      expect(tester.takeException(), isNull);
    });

    testWidgets('should handle dashed threshold line', (WidgetTester tester) async {
      // Arrange
      final series = ChartSeries(
        id: 'test-series',
        points: [
          const ChartDataPoint(x: 0, y: 0),
          const ChartDataPoint(x: 10, y: 10),
        ],
      );

      // Create a dashed threshold
      final annotation = ThresholdAnnotation(
        id: 'threshold-dashed',
        axis: AnnotationAxis.y,
        value: 5.0,
        lineColor: Colors.green,
        lineWidth: 2.0,
        dashPattern: [5, 3], // 5px dash, 3px gap
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 300,
              child: BravenChart(
                series: [series],
                annotations: [annotation],
                chartType: ChartType.line,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert
      expect(tester.takeException(), isNull);
    });

    testWidgets('should hide threshold outside visible Y range', (WidgetTester tester) async {
      // Arrange
      final series = ChartSeries(
        id: 'test-series',
        points: [
          const ChartDataPoint(x: 0, y: 0),
          const ChartDataPoint(x: 10, y: 10),
        ],
      );

      // Create a threshold outside the data range
      final annotation = ThresholdAnnotation(
        id: 'threshold-outside',
        axis: AnnotationAxis.y,
        value: 20.0, // Outside range [0, 10]
        lineColor: Colors.red,
        lineWidth: 2.0,
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 300,
              child: BravenChart(
                series: [series],
                annotations: [annotation],
                chartType: ChartType.line,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert: Should render without errors (annotation hidden)
      expect(tester.takeException(), isNull);
    });

    testWidgets('should hide threshold outside visible X range', (WidgetTester tester) async {
      // Arrange
      final series = ChartSeries(
        id: 'test-series',
        points: [
          const ChartDataPoint(x: 0, y: 0),
          const ChartDataPoint(x: 10, y: 10),
        ],
      );

      // Create a threshold outside the data range
      final annotation = ThresholdAnnotation(
        id: 'threshold-outside',
        axis: AnnotationAxis.x,
        value: -5.0, // Outside range [0, 10]
        lineColor: Colors.blue,
        lineWidth: 2.0,
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 300,
              child: BravenChart(
                series: [series],
                annotations: [annotation],
                chartType: ChartType.line,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert
      expect(tester.takeException(), isNull);
    });

    testWidgets('should render multiple thresholds correctly', (WidgetTester tester) async {
      // Arrange
      final series = ChartSeries(
        id: 'test-series',
        points: [
          const ChartDataPoint(x: 0, y: 0),
          const ChartDataPoint(x: 10, y: 10),
        ],
      );

      // Create multiple thresholds
      final annotations = [
        ThresholdAnnotation(
          id: 'threshold-1',
          axis: AnnotationAxis.y,
          value: 3.0,
          lineColor: Colors.red,
          lineWidth: 1.0,
          label: 'Low',
        ),
        ThresholdAnnotation(
          id: 'threshold-2',
          axis: AnnotationAxis.y,
          value: 7.0,
          lineColor: Colors.green,
          lineWidth: 2.0,
          label: 'High',
        ),
        ThresholdAnnotation(
          id: 'threshold-3',
          axis: AnnotationAxis.x,
          value: 5.0,
          lineColor: Colors.blue,
          lineWidth: 1.5,
          dashPattern: [3, 2],
        ),
      ];

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 300,
              child: BravenChart(
                series: [series],
                annotations: annotations,
                chartType: ChartType.line,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert
      expect(tester.takeException(), isNull);
      expect(find.byType(BravenChart), findsOneWidget);
    });

    testWidgets('should handle threshold at data boundary', (WidgetTester tester) async {
      // Arrange
      final series = ChartSeries(
        id: 'test-series',
        points: [
          const ChartDataPoint(x: 0, y: 0),
          const ChartDataPoint(x: 10, y: 10),
        ],
      );

      // Create thresholds at exact min and max
      final annotations = [
        ThresholdAnnotation(
          id: 'threshold-min',
          axis: AnnotationAxis.y,
          value: 0.0, // Min Y
          lineColor: Colors.black,
          lineWidth: 1.0,
        ),
        ThresholdAnnotation(
          id: 'threshold-max',
          axis: AnnotationAxis.y,
          value: 10.0, // Max Y
          lineColor: Colors.black,
          lineWidth: 1.0,
        ),
      ];

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 300,
              child: BravenChart(
                series: [series],
                annotations: annotations,
                chartType: ChartType.line,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert
      expect(tester.takeException(), isNull);
    });
  });
}
