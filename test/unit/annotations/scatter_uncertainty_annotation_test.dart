import 'dart:ui';

import 'package:braven_charts/src/coordinates/chart_transform.dart';
import 'package:braven_charts/src/elements/annotation_elements.dart';
import 'package:braven_charts/src/models/chart_annotation.dart';
import 'package:braven_charts/src/models/chart_data_point.dart';
import 'package:braven_charts/src/models/chart_series.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const transform = ChartTransform(
    dataXMin: 0,
    dataXMax: 6,
    dataYMin: 0,
    dataYMax: 10,
    plotWidth: 600,
    plotHeight: 400,
  );
  const series = ScatterChartSeries(
    id: 'observed',
    points: [
      ChartDataPoint(x: 1, y: 2),
      ChartDataPoint(x: 2, y: 4),
      ChartDataPoint(x: 3, y: 5),
      ChartDataPoint(x: 4, y: 4),
      ChartDataPoint(x: 5, y: 5),
    ],
  );

  test('linear trend paints confidence and prediction bands', () {
    final element = TrendAnnotationElement(
      annotation: TrendAnnotation(
        id: 'fit',
        seriesId: 'observed',
        trendType: TrendType.linear,
        showConfidenceBand: true,
        showPredictionBand: true,
        confidenceLevel: 0.95,
      ),
      series: series,
      transform: transform,
    );

    expect(element.intervals, isNotNull);
    expect(element.intervals!.points, hasLength(96));
    expect(element.bounds.isFinite, isTrue);
    final recorder = PictureRecorder();
    element.paint(Canvas(recorder), const Size(600, 400));
    expect(recorder.endRecording(), isNotNull);
  });

  test('error bars support asymmetric X and Y magnitudes', () {
    final element = ErrorBarAnnotationElement(
      annotation: ErrorBarAnnotation(
        id: 'errors',
        seriesId: 'observed',
        values: const [
          ErrorBarDatum(
            pointIndex: 1,
            xNegative: 0.25,
            xPositive: 0.5,
            yNegative: 0.75,
            yPositive: 1.25,
          ),
          ErrorBarDatum.symmetric(pointIndex: 3, x: 0.4, y: 0.8),
        ],
      ),
      series: series,
      transform: transform,
    );

    expect(element.bounds, isNot(Rect.zero));
    expect(element.bounds.isFinite, isTrue);
    final recorder = PictureRecorder();
    element.paint(Canvas(recorder), const Size(600, 400));
    expect(recorder.endRecording(), isNotNull);
  });
}
