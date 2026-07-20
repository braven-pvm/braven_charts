import 'dart:ui';

import 'package:braven_charts/src/coordinates/chart_transform.dart';
import 'package:braven_charts/src/elements/annotation_elements.dart';
import 'package:braven_charts/src/models/chart_annotation.dart';
import 'package:braven_charts/src/models/chart_data_point.dart';
import 'package:braven_charts/src/models/chart_series.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TrendAnnotationElement LOESS', () {
    const transform = ChartTransform(
      dataXMin: 0,
      dataXMax: 10,
      dataYMin: 0,
      dataYMax: 120,
      plotWidth: 500,
      plotHeight: 320,
    );

    test('renders and evaluates the robust fitted curve', () {
      final element = TrendAnnotationElement(
        annotation: TrendAnnotation(
          id: 'robust-fit',
          seriesId: 'observed',
          trendType: TrendType.loess,
          loessSpan: 0.8,
          loessRobustnessIterations: 2,
          loessSampleCount: 101,
        ),
        series: ScatterChartSeries(
          id: 'observed',
          points: [
            for (var x = 0; x <= 10; x++)
              ChartDataPoint(x: x.toDouble(), y: x == 5 ? 100 : x.toDouble()),
          ],
        ),
        transform: transform,
      );

      expect(element.evaluateAt(5), closeTo(5, 0.2));
      expect(element.evaluateAt(-1), isNull);
      expect(element.bounds.isFinite, isTrue);
      expect(element.bounds, isNot(Rect.zero));
    });

    test('does not render a vertical-only or invalid dataset', () {
      final element = TrendAnnotationElement(
        annotation: TrendAnnotation(
          id: 'empty-fit',
          seriesId: 'observed',
          trendType: TrendType.loess,
        ),
        series: const ScatterChartSeries(
          id: 'observed',
          points: [
            ChartDataPoint(x: 2, y: 1),
            ChartDataPoint(x: 2, y: 4),
            ChartDataPoint(x: double.nan, y: 8),
          ],
        ),
        transform: transform,
      );

      expect(element.evaluateAt(2), isNull);
      expect(element.bounds, Rect.zero);
    });
  });

  test('linear trend calculates and paints requested diagnostics', () {
    const transform = ChartTransform(
      dataXMin: 0,
      dataXMax: 4,
      dataYMin: 0,
      dataYMax: 10,
      plotWidth: 500,
      plotHeight: 320,
    );
    final element = TrendAnnotationElement(
      annotation: TrendAnnotation(
        id: 'linear-fit',
        label: 'Linear diagnostics',
        seriesId: 'observed',
        trendType: TrendType.linear,
        showEquation: true,
        showRSquared: true,
        showSampleCount: true,
        showPearsonCorrelation: true,
        showSpearmanCorrelation: true,
      ),
      series: const ScatterChartSeries(
        id: 'observed',
        points: [
          ChartDataPoint(x: 0, y: 1),
          ChartDataPoint(x: 1, y: 3),
          ChartDataPoint(x: 2, y: 5),
          ChartDataPoint(x: 3, y: 7),
          ChartDataPoint(x: 4, y: 9),
        ],
      ),
      transform: transform,
    );

    expect(element.statistics.sampleCount, 5);
    expect(element.statistics.equation, 'y = 2x + 1');
    expect(element.statistics.rSquared, closeTo(1, 1e-12));
    expect(element.statistics.pearsonCorrelation, closeTo(1, 1e-12));
    expect(element.statistics.spearmanCorrelation, closeTo(1, 1e-12));
    expect(element.bounds.isFinite, isTrue);

    final recorder = PictureRecorder();
    final canvas = Canvas(recorder);
    element.paint(canvas, const Size(500, 320));
    expect(recorder.endRecording(), isNotNull);
  });
}
