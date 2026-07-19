import 'dart:ui';

import 'package:braven_charts/braven_charts.dart';
import 'package:braven_charts/src/coordinates/chart_transform.dart';
import 'package:braven_charts/src/elements/series_element.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Quickstart Example 8: per-point Scatter sizing', () {
    const series = ScatterChartSeries(
      id: 'sized-scatter',
      points: [
        ChartDataPoint(x: 1, y: 1, pointStyle: PointStyle(size: 3)),
        ChartDataPoint(x: 3, y: 3, pointStyle: PointStyle(size: 6)),
        ChartDataPoint(x: 6, y: 6, pointStyle: PointStyle(size: 12)),
        ChartDataPoint(x: 9, y: 9, pointStyle: PointStyle(size: 18)),
      ],
      markerRadius: 5,
    );

    test('preserves four independently sized source points', () {
      final element = SeriesElement(series: series, transform: _transform());

      expect(element.pointCount, 4);
      expect(
        [for (final point in series.points) point.pointStyle!.size],
        [3, 6, 12, 18],
      );
      expect(element.bounds.right, greaterThan(900));
    });

    test('larger point sizes produce larger marker-aware hit regions', () {
      final element = SeriesElement(series: series, transform: _transform());
      final small = element.dataHitForPointIndex(0)!.plotPosition;
      final large = element.dataHitForPointIndex(3)!.plotPosition;

      expect(element.hitTest(small + const Offset(9, 0)), isFalse);
      expect(element.hitTest(large + const Offset(17, 0)), isTrue);
    });

    test('renders the styled path without per-point geometry errors', () {
      final element = SeriesElement(series: series, transform: _transform());
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);

      expect(
        () => element.paint(canvas, const Size(1000, 600)),
        returnsNormally,
      );
      recorder.endRecording();
    });
  });
}

ChartTransform _transform() => const ChartTransform(
  dataXMin: 0,
  dataXMax: 10,
  dataYMin: 0,
  dataYMax: 10,
  plotWidth: 1000,
  plotHeight: 600,
);
