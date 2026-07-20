import 'package:braven_charts/braven_charts.dart';
import 'package:braven_charts/src/elements/annotation_elements.dart';
import 'package:braven_charts/src/rendering/chart_render_box.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('native legend identifies every uncertainty layer', (
    tester,
  ) async {
    final trend = TrendAnnotation(
      id: 'fit',
      label: 'OLS fit',
      seriesId: 'assay',
      trendType: TrendType.linear,
      showConfidenceBand: true,
      showPredictionBand: true,
      confidenceLevel: 0.95,
      confidenceBandColor: const Color(0xFF0F8CA8),
      predictionBandColor: const Color(0xFF6366F1),
    );
    final error = ErrorBarAnnotation(
      id: 'error',
      label: 'X/Y measurement error',
      seriesId: 'assay',
      values: const [ErrorBarDatum.symmetric(pointIndex: 0, x: 0.2, y: 1.5)],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 760,
          height: 440,
          child: BravenChartPlus(
            series: const [
              ScatterChartSeries(
                id: 'assay',
                name: 'Observed assay',
                points: [
                  ChartDataPoint(x: 1, y: 14),
                  ChartDataPoint(x: 2, y: 23),
                  ChartDataPoint(x: 3, y: 31),
                ],
                markerStyle: ScatterMarkerStyle(
                  fillColor: Color(0xFFF8FAFC),
                  strokeColor: Color(0xFF0F8CA8),
                  strokeWidth: 2,
                ),
              ),
            ],
            annotations: [trend, error],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final renderBox = tester.allRenderObjects
        .whereType<ChartRenderBox>()
        .single;
    final legend = renderBox.debugElements
        .whereType<LegendAnnotationElement>()
        .single;

    expect(legend.annotation.series.single.displayName, 'Observed assay');
    expect(legend.annotation.trendAnnotations.single.label, 'OLS fit');
    expect(legend.annotation.errorBarAnnotations.single.id, 'error');
    expect(legend.debugUncertaintyLabels, [
      'X/Y measurement error',
      '95% mean confidence',
      '95% future prediction',
    ]);
    expect(legend.bounds.height, greaterThan(70));
    expect(tester.takeException(), isNull);
  });

  testWidgets('uncertainty key stacks within a narrow chart', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 360,
          height: 520,
          child: BravenChartPlus(
            series: const [
              ScatterChartSeries(
                id: 'assay',
                name: 'Observed assay',
                points: [
                  ChartDataPoint(x: 1, y: 14),
                  ChartDataPoint(x: 2, y: 23),
                  ChartDataPoint(x: 3, y: 31),
                ],
              ),
            ],
            annotations: [
              TrendAnnotation(
                label: 'OLS fit',
                seriesId: 'assay',
                trendType: TrendType.linear,
                showConfidenceBand: true,
                showPredictionBand: true,
              ),
              ErrorBarAnnotation(
                label: 'X/Y measurement error',
                seriesId: 'assay',
                values: const [
                  ErrorBarDatum.symmetric(pointIndex: 0, x: 0.2, y: 1.5),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final renderBox = tester.allRenderObjects
        .whereType<ChartRenderBox>()
        .single;
    final legend = renderBox.debugElements
        .whereType<LegendAnnotationElement>()
        .single;
    expect(legend.bounds.left, greaterThanOrEqualTo(0));
    expect(legend.bounds.right, lessThanOrEqualTo(renderBox.plotWidth));
    expect(tester.takeException(), isNull);
  });
}
