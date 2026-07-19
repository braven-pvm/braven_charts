import 'dart:ui';

import 'package:braven_charts/braven_charts.dart';
import 'package:braven_charts/src/coordinates/chart_transform.dart';
import 'package:braven_charts/src/elements/series_element.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Quickstart Example 7: fixed-size Scatter', () {
    final points = [
      for (var index = 0; index < 50; index++)
        ChartDataPoint(x: (index % 10).toDouble(), y: (index ~/ 10).toDouble()),
    ];

    test('preserves and paints all 50 source points', () {
      final series = ScatterChartSeries(
        id: 'fixed-scatter',
        points: points,
        markerRadius: 6,
      );
      final element = SeriesElement(series: series, transform: _transform());

      expect(element.pointCount, 50);
      expect(element.dataHitForPointIndex(49)?.point, points[49]);

      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);
      expect(
        () => element.paint(canvas, const Size(900, 400)),
        returnsNormally,
      );
      recorder.endRecording();
    });

    test('uses the configured fixed marker radius for precise hits', () {
      final element = SeriesElement(
        series: ScatterChartSeries(
          id: 'fixed-scatter',
          points: points,
          markerRadius: 6,
        ),
        transform: _transform(),
      );
      final center = element.dataHitForPointIndex(0)!.plotPosition;

      expect(element.hitTest(center + const Offset(5, 0)), isTrue);
      expect(element.hitTest(center + const Offset(11, 0)), isFalse);
    });
  });
}

ChartTransform _transform() => const ChartTransform(
  dataXMin: 0,
  dataXMax: 9,
  dataYMin: 0,
  dataYMax: 4,
  plotWidth: 900,
  plotHeight: 400,
);
