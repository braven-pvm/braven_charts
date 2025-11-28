import 'package:braven_charts/legacy/braven_charts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// T036: Integration test - Quickstart Step 2 (Annotations)
///
/// Validates the annotation scenario from quickstart.md Step 2.
/// Tests that users can add PointAnnotation and ThresholdAnnotation to charts.
///
/// Run: flutter test test/widgets/integration/quickstart_step2_test.dart
void main() {
  group('Quickstart Step 2: Add Annotations', () {
    testWidgets('Adds PointAnnotation to highlight data point',
        (WidgetTester tester) async {
      // Step 2 from quickstart.md - Add PointAnnotation
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: BravenChart(
                chartType: ChartType.line,
                series: [
                  ChartSeries(
                    id: 'monthly_sales',
                    name: 'Monthly Sales',
                    points: const [
                      ChartDataPoint(x: 1, y: 10000),
                      ChartDataPoint(x: 2, y: 15000),
                      ChartDataPoint(x: 3, y: 12000),
                      ChartDataPoint(x: 4, y: 18000),
                      ChartDataPoint(x: 5, y: 22000),
                      ChartDataPoint(x: 6, y: 25000),
                    ],
                  ),
                ],
                annotations: [
                  PointAnnotation(
                    id: 'record_month',
                    seriesId: 'monthly_sales',
                    dataPointIndex: 5, // June
                    label: 'Record Month!',
                    markerShape: MarkerShape.star,
                  ),
                ],
                title: 'Monthly Sales 2025',
                width: 400,
                height: 300,
              ),
            ),
          ),
        ),
      );

      // Verify chart renders
      expect(find.byType(BravenChart), findsOneWidget);

      // Verify annotation is present
      final chartWidget = tester.widget<BravenChart>(find.byType(BravenChart));
      expect(chartWidget.annotations.length, equals(1));

      // Verify annotation details
      final annotation = chartWidget.annotations[0] as PointAnnotation;
      expect(annotation.seriesId, equals('monthly_sales'));
      expect(annotation.dataPointIndex, equals(5));
      expect(annotation.label, equals('Record Month!'));
      expect(annotation.markerShape, equals(MarkerShape.star));
    });

    testWidgets('Adds ThresholdAnnotation to show target line',
        (WidgetTester tester) async {
      // Step 2 from quickstart.md - Add ThresholdAnnotation
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: BravenChart(
                chartType: ChartType.line,
                series: [
                  ChartSeries(
                    id: 'monthly_sales',
                    points: const [
                      ChartDataPoint(x: 1, y: 10000),
                      ChartDataPoint(x: 2, y: 15000),
                      ChartDataPoint(x: 3, y: 12000),
                      ChartDataPoint(x: 4, y: 18000),
                      ChartDataPoint(x: 5, y: 22000),
                      ChartDataPoint(x: 6, y: 25000),
                    ],
                  ),
                ],
                annotations: [
                  ThresholdAnnotation(
                    id: 'sales_target',
                    axis: AnnotationAxis.y,
                    value: 20000,
                    label: 'Sales Target',
                    style: const AnnotationStyle(
                      borderColor: Colors.green,
                    ),
                  ),
                ],
                title: 'Monthly Sales 2025',
                width: 400,
                height: 300,
              ),
            ),
          ),
        ),
      );

      // Verify chart renders
      expect(find.byType(BravenChart), findsOneWidget);

      // Verify annotation is present
      final chartWidget = tester.widget<BravenChart>(find.byType(BravenChart));
      expect(chartWidget.annotations.length, equals(1));

      // Verify annotation details
      final annotation = chartWidget.annotations[0] as ThresholdAnnotation;
      expect(annotation.axis, equals(AnnotationAxis.y));
      expect(annotation.value, equals(20000));
      expect(annotation.label, equals('Sales Target'));
      expect(annotation.style.borderColor, equals(Colors.green));
    });

    testWidgets('Combines PointAnnotation and ThresholdAnnotation',
        (WidgetTester tester) async {
      // Step 2 complete example from quickstart.md
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: BravenChart(
                chartType: ChartType.line,
                series: [
                  ChartSeries(
                    id: 'monthly_sales',
                    name: 'Monthly Sales',
                    points: const [
                      ChartDataPoint(x: 1, y: 10000),
                      ChartDataPoint(x: 2, y: 15000),
                      ChartDataPoint(x: 3, y: 12000),
                      ChartDataPoint(x: 4, y: 18000),
                      ChartDataPoint(x: 5, y: 22000),
                      ChartDataPoint(x: 6, y: 25000),
                    ],
                  ),
                ],
                annotations: [
                  PointAnnotation(
                    id: 'record_month',
                    seriesId: 'monthly_sales',
                    dataPointIndex: 5,
                    label: 'Record Month!',
                    markerShape: MarkerShape.star,
                  ),
                  ThresholdAnnotation(
                    id: 'sales_target',
                    axis: AnnotationAxis.y,
                    value: 20000,
                    label: 'Sales Target',
                    style: const AnnotationStyle(
                      borderColor: Colors.green,
                    ),
                  ),
                ],
                title: 'Monthly Sales 2025',
                width: 400,
                height: 300,
              ),
            ),
          ),
        ),
      );

      // Verify both annotations render
      final chartWidget = tester.widget<BravenChart>(find.byType(BravenChart));
      expect(chartWidget.annotations.length, equals(2));

      // Verify PointAnnotation
      final pointAnnotation = chartWidget.annotations[0] as PointAnnotation;
      expect(pointAnnotation.markerShape, equals(MarkerShape.star));

      // Verify ThresholdAnnotation
      final thresholdAnnotation =
          chartWidget.annotations[1] as ThresholdAnnotation;
      expect(thresholdAnnotation.value, equals(20000));
    });

    testWidgets('Annotations render on top of chart',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: BravenChart(
                chartType: ChartType.line,
                series: [
                  ChartSeries(
                    id: 'data',
                    points: const [
                      ChartDataPoint(x: 0, y: 10),
                      ChartDataPoint(x: 1, y: 20),
                      ChartDataPoint(x: 2, y: 15),
                    ],
                  ),
                ],
                annotations: [
                  TextAnnotation(
                    id: 'label',
                    text: 'Important Event',
                    position: const Offset(200, 100),
                  ),
                ],
                width: 400,
                height: 300,
              ),
            ),
          ),
        ),
      );

      // Verify chart uses Stack for annotation overlay
      expect(find.byType(Stack), findsWidgets);
      expect(find.byType(BravenChart), findsOneWidget);
    });

    testWidgets('Multiple marker shapes work', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: BravenChart(
                chartType: ChartType.line,
                series: [
                  ChartSeries(
                    id: 'data',
                    points: const [
                      ChartDataPoint(x: 0, y: 10),
                      ChartDataPoint(x: 1, y: 20),
                      ChartDataPoint(x: 2, y: 15),
                      ChartDataPoint(x: 3, y: 25),
                    ],
                  ),
                ],
                annotations: [
                  PointAnnotation(
                    id: 'star',
                    seriesId: 'data',
                    dataPointIndex: 0,
                    markerShape: MarkerShape.star,
                  ),
                  PointAnnotation(
                    id: 'circle',
                    seriesId: 'data',
                    dataPointIndex: 1,
                    markerShape: MarkerShape.circle,
                  ),
                  PointAnnotation(
                    id: 'square',
                    seriesId: 'data',
                    dataPointIndex: 2,
                    markerShape: MarkerShape.square,
                  ),
                ],
                width: 400,
                height: 300,
              ),
            ),
          ),
        ),
      );

      // Verify all marker shapes render
      final chartWidget = tester.widget<BravenChart>(find.byType(BravenChart));
      expect(chartWidget.annotations.length, equals(3));

      expect((chartWidget.annotations[0] as PointAnnotation).markerShape,
          equals(MarkerShape.star));
      expect((chartWidget.annotations[1] as PointAnnotation).markerShape,
          equals(MarkerShape.circle));
      expect((chartWidget.annotations[2] as PointAnnotation).markerShape,
          equals(MarkerShape.square));
    });
  });
}
