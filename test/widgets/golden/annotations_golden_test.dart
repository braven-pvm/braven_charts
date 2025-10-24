import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// T033: Golden test - Annotations
///
/// Visual regression tests for all 5 annotation types.
/// Ensures annotation rendering consistency across code changes.
///
/// Run: flutter test test/widgets/golden/annotations_golden_test.dart
/// Update: flutter test --update-goldens test/widgets/golden/annotations_golden_test.dart
void main() {
  group('Annotations Golden Tests', () {
    // Common test data
    final testSeries = [
      ChartSeries(
        id: 'data',
        name: 'Data',
        points: const [
          ChartDataPoint(x: 0, y: 10),
          ChartDataPoint(x: 1, y: 20),
          ChartDataPoint(x: 2, y: 15),
          ChartDataPoint(x: 3, y: 25),
          ChartDataPoint(x: 4, y: 18),
        ],
      ),
    ];

    testWidgets('TextAnnotation golden', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 300,
              child: BravenChart(
                chartType: ChartType.line,
                series: testSeries,
                title: 'Text Annotation',
                annotations: [
                  TextAnnotation(
                    id: 'note',
                    label: 'Important Note',
                    text: 'Important Note',
                    position: const Offset(200, 100),
                    style: AnnotationStyle(
                      fontSize: 14,
                      textColor: Colors.blue,
                      backgroundColor: Colors.blue.withOpacity(0.1),
                    ),
                  ),
                ],
                theme: ChartTheme.defaultLight,
              ),
            ),
          ),
        ),
      );

      await expectLater(
        find.byType(BravenChart),
        matchesGoldenFile('goldens/text_annotation.png'),
      );
    });

    testWidgets('PointAnnotation golden', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 300,
              child: BravenChart(
                chartType: ChartType.line,
                series: testSeries,
                title: 'Point Annotation',
                annotations: [
                  PointAnnotation(
                    id: 'peak',
                    label: 'Peak Value',
                    seriesId: 'data',
                    dataPointIndex: 3,
                    markerShape: MarkerShape.star,
                    markerSize: 12,
                    style: AnnotationStyle(
                      textColor: Colors.red,
                      backgroundColor: Colors.red.withOpacity(0.1),
                    ),
                  ),
                ],
                theme: ChartTheme.defaultLight,
              ),
            ),
          ),
        ),
      );

      await expectLater(
        find.byType(BravenChart),
        matchesGoldenFile('goldens/point_annotation.png'),
      );
    });

    testWidgets('RangeAnnotation golden', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 300,
              child: BravenChart(
                chartType: ChartType.line,
                series: testSeries,
                title: 'Range Annotation',
                annotations: [
                  RangeAnnotation(
                    id: 'target',
                    label: 'Target Range',
                    startX: 1,
                    endX: 3,
                    style: AnnotationStyle(
                      backgroundColor: Colors.green.withOpacity(0.2),
                      borderColor: Colors.green,
                    ),
                  ),
                ],
                theme: ChartTheme.defaultLight,
              ),
            ),
          ),
        ),
      );

      await expectLater(
        find.byType(BravenChart),
        matchesGoldenFile('goldens/range_annotation.png'),
      );
    });

    testWidgets('ThresholdAnnotation horizontal golden',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 300,
              child: BravenChart(
                chartType: ChartType.line,
                series: testSeries,
                title: 'Threshold Horizontal',
                annotations: [
                  ThresholdAnnotation(
                    id: 'limit',
                    label: 'Limit',
                    value: 20,
                    axis: AnnotationAxis.y,
                    style: const AnnotationStyle(
                      borderColor: Colors.red,
                      borderWidth: 2,
                    ),
                  ),
                ],
                theme: ChartTheme.defaultLight,
              ),
            ),
          ),
        ),
      );

      await expectLater(
        find.byType(BravenChart),
        matchesGoldenFile('goldens/threshold_horizontal.png'),
      );
    });

    testWidgets('ThresholdAnnotation vertical golden',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 300,
              child: BravenChart(
                chartType: ChartType.line,
                series: testSeries,
                title: 'Threshold Vertical',
                annotations: [
                  ThresholdAnnotation(
                    id: 'event',
                    label: 'Event',
                    value: 2,
                    axis: AnnotationAxis.x,
                    style: const AnnotationStyle(
                      borderColor: Colors.orange,
                      borderWidth: 2,
                    ),
                  ),
                ],
                theme: ChartTheme.defaultLight,
              ),
            ),
          ),
        ),
      );

      await expectLater(
        find.byType(BravenChart),
        matchesGoldenFile('goldens/threshold_vertical.png'),
      );
    });

    testWidgets('TrendAnnotation golden', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 300,
              child: BravenChart(
                chartType: ChartType.scatter,
                series: testSeries,
                title: 'Trend Annotation',
                annotations: [
                  TrendAnnotation(
                    id: 'trend',
                    label: 'Linear Trend',
                    seriesId: 'data',
                    trendType: TrendType.linear,
                    style: const AnnotationStyle(
                      borderColor: Colors.purple,
                      borderWidth: 2,
                    ),
                  ),
                ],
                theme: ChartTheme.defaultLight,
              ),
            ),
          ),
        ),
      );

      await expectLater(
        find.byType(BravenChart),
        matchesGoldenFile('goldens/trend_annotation.png'),
      );
    });

    testWidgets('Multiple annotations golden', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 300,
              child: BravenChart(
                chartType: ChartType.line,
                series: testSeries,
                title: 'Multiple Annotations',
                annotations: [
                  RangeAnnotation(
                    id: 'range',
                    label: 'Range',
                    startX: 1,
                    endX: 3,
                    zIndex: 1,
                    style: AnnotationStyle(
                      backgroundColor: Colors.blue.withOpacity(0.1),
                    ),
                  ),
                  ThresholdAnnotation(
                    id: 'threshold',
                    label: 'Threshold',
                    value: 20,
                    axis: AnnotationAxis.y,
                    zIndex: 5,
                    style: const AnnotationStyle(
                      borderColor: Colors.red,
                      borderWidth: 2,
                    ),
                  ),
                  PointAnnotation(
                    id: 'peak',
                    label: 'Peak',
                    seriesId: 'data',
                    dataPointIndex: 3,
                    markerShape: MarkerShape.star,
                    markerSize: 12,
                    zIndex: 10,
                    style: const AnnotationStyle(
                      textColor: Colors.green,
                    ),
                  ),
                ],
                theme: ChartTheme.defaultLight,
              ),
            ),
          ),
        ),
      );

      await expectLater(
        find.byType(BravenChart),
        matchesGoldenFile('goldens/multiple_annotations.png'),
      );
    });
  });
}
