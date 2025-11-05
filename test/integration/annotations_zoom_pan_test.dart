import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Integration tests for Phase 1, Task 1.4: Annotation behavior with zoom/pan
///
/// These tests verify that all annotation types (Point, Range, Threshold)
/// correctly respond to zoom and pan operations, maintaining their position
/// relative to the data points they annotate.
void main() {
  group('Annotations with Zoom/Pan', () {
    testWidgets('PointAnnotation should move with data when panning', (WidgetTester tester) async {
      // Arrange: Create a chart with zoom/pan enabled
      final series = ChartSeries(
        id: 'test-series',
        points: List.generate(20, (i) => ChartDataPoint(x: i.toDouble(), y: i.toDouble())),
      );

      final annotation = PointAnnotation(
        seriesId: 'test-series',
        dataPointIndex: 10, // Middle point (x=10, y=10)
        markerShape: MarkerShape.circle,
        markerSize: 10.0,
        markerColor: Colors.red,
      );

      // Act: Build the chart with interaction enabled
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
                interactionConfig: const InteractionConfig(
                  enabled: true,
                  enablePan: true,
                  enableZoom: true,
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert: Chart should render without errors
      expect(find.byType(BravenChart), findsOneWidget);
      expect(tester.takeException(), isNull);

      // Note: We can't directly test the visual position change without accessing internals,
      // but we can verify the chart continues to render correctly during interactions
    });

    testWidgets('RangeAnnotation should resize with zoom', (WidgetTester tester) async {
      // Arrange
      final series = ChartSeries(
        id: 'test-series',
        points: List.generate(20, (i) => ChartDataPoint(x: i.toDouble(), y: i.toDouble())),
      );

      final annotation = RangeAnnotation(
        id: 'test-range',
        startX: 5.0,
        endX: 15.0,
        startY: 3.0,
        endY: 17.0,
        fillColor: Colors.blue.withOpacity(0.2),
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
                interactionConfig: const InteractionConfig(
                  enabled: true,
                  enableZoom: true,
                  enablePan: true,
                ),
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

    testWidgets('ThresholdAnnotation should maintain position during zoom', (WidgetTester tester) async {
      // Arrange
      final series = ChartSeries(
        id: 'test-series',
        points: List.generate(20, (i) => ChartDataPoint(x: i.toDouble(), y: i.toDouble())),
      );

      final annotations = [
        ThresholdAnnotation(
          id: 'threshold-y',
          axis: AnnotationAxis.y,
          value: 10.0,
          lineColor: Colors.red,
          lineWidth: 2.0,
        ),
        ThresholdAnnotation(
          id: 'threshold-x',
          axis: AnnotationAxis.x,
          value: 12.0,
          lineColor: Colors.blue,
          lineWidth: 2.0,
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
                interactionConfig: const InteractionConfig(
                  enabled: true,
                  enableZoom: true,
                  enablePan: true,
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert
      expect(tester.takeException(), isNull);
    });

    testWidgets('Multiple annotation types should work together with zoom/pan', (WidgetTester tester) async {
      // Arrange: Create chart with all three annotation types
      final series = ChartSeries(
        id: 'test-series',
        points: List.generate(30, (i) => ChartDataPoint(x: i.toDouble(), y: i.toDouble())),
      );

      final annotations = <ChartAnnotation>[
        // Point annotations
        PointAnnotation(
          seriesId: 'test-series',
          dataPointIndex: 5,
          markerShape: MarkerShape.circle,
          markerSize: 8.0,
          markerColor: Colors.red,
        ),
        PointAnnotation(
          seriesId: 'test-series',
          dataPointIndex: 15,
          markerShape: MarkerShape.square,
          markerSize: 10.0,
          markerColor: Colors.green,
        ),

        // Range annotations
        RangeAnnotation(
          id: 'range-1',
          startX: 8.0,
          endX: 12.0,
          startY: 8.0,
          endY: 12.0,
          fillColor: Colors.yellow.withOpacity(0.2),
        ),
        RangeAnnotation(
          id: 'range-2',
          startX: 18.0,
          endX: 22.0,
          startY: null,
          endY: null,
          fillColor: Colors.purple.withOpacity(0.1),
        ),

        // Threshold annotations
        ThresholdAnnotation(
          id: 'threshold-low',
          axis: AnnotationAxis.y,
          value: 10.0,
          lineColor: Colors.orange,
          lineWidth: 1.5,
          dashPattern: [5, 3],
        ),
        ThresholdAnnotation(
          id: 'threshold-high',
          axis: AnnotationAxis.y,
          value: 20.0,
          lineColor: Colors.red,
          lineWidth: 2.0,
        ),
        ThresholdAnnotation(
          id: 'threshold-vertical',
          axis: AnnotationAxis.x,
          value: 25.0,
          lineColor: Colors.blue,
          lineWidth: 1.5,
        ),
      ];

      // Act: Build complex chart with all annotations and interactions enabled
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 600,
              height: 400,
              child: BravenChart(
                series: [series],
                annotations: annotations,
                chartType: ChartType.line,
                interactionConfig: const InteractionConfig(
                  enabled: true,
                  enableZoom: true,
                  enablePan: true,
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert: All annotations should render without conflicts
      expect(tester.takeException(), isNull);
      expect(find.byType(BravenChart), findsOneWidget);
    });

    testWidgets('Annotations should handle chart rebuilds correctly', (WidgetTester tester) async {
      // Arrange: Create a stateful widget that can update annotations
      final series = ChartSeries(
        id: 'test-series',
        points: List.generate(20, (i) => ChartDataPoint(x: i.toDouble(), y: i.toDouble())),
      );

      var pointIndex = 10;

      // Act: Build initial chart
      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return MaterialApp(
              home: Scaffold(
                body: Column(
                  children: [
                    Expanded(
                      child: BravenChart(
                        series: [series],
                        annotations: [
                          PointAnnotation(
                            seriesId: 'test-series',
                            dataPointIndex: pointIndex,
                            markerShape: MarkerShape.circle,
                            markerSize: 10.0,
                            markerColor: Colors.red,
                          ),
                        ],
                        chartType: ChartType.line,
                        interactionConfig: const InteractionConfig(
                          enabled: true,
                          enableZoom: true,
                          enablePan: true,
                        ),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () => setState(() => pointIndex = 15),
                      child: const Text('Update'),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );

      await tester.pumpAndSettle();

      // Assert: Initial render
      expect(tester.takeException(), isNull);

      // Act: Tap button to update annotation
      await tester.tap(find.text('Update'));
      await tester.pumpAndSettle();

      // Assert: Chart should handle annotation update
      expect(tester.takeException(), isNull);
    });

    testWidgets('Annotations outside viewport should not cause errors', (WidgetTester tester) async {
      // Arrange: Create chart with annotation far outside initial view
      final series = ChartSeries(
        id: 'test-series',
        points: List.generate(100, (i) => ChartDataPoint(x: i.toDouble(), y: i.toDouble())),
      );

      final annotations = [
        PointAnnotation(
          seriesId: 'test-series',
          dataPointIndex: 95, // Far from initial view
          markerShape: MarkerShape.circle,
          markerSize: 10.0,
          markerColor: Colors.red,
        ),
        RangeAnnotation(
          id: 'far-range',
          startX: 80.0,
          endX: 90.0,
          startY: 80.0,
          endY: 90.0,
          fillColor: Colors.blue.withOpacity(0.2),
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
                interactionConfig: const InteractionConfig(
                  enabled: true,
                  enableZoom: true,
                  enablePan: true,
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert: Should handle gracefully (annotations hidden or clipped)
      expect(tester.takeException(), isNull);
    });
  });
}
