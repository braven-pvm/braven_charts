import 'dart:ui' show Color;

import 'package:braven_charts/braven_charts.dart';
import 'package:braven_charts/src/coordinates/chart_transform.dart';
import 'package:braven_charts/src/rendering/bar_geometry.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('lays out 1,000 styled bars within one 60fps frame on average', () {
    final series = BarChartSeries(
      id: 'benchmark',
      points: [
        for (var index = 0; index < 1000; index++)
          ChartDataPoint(x: index.toDouble(), y: (index % 100).toDouble()),
      ],
      barWidthPercent: 0.72,
      minBarLength: 2,
      barStyle: const BarChartStyle(
        cornerRadius: 4,
        gradient: BarGradient(colors: [Color(0xFF34D399), Color(0xFF168AAD)]),
      ),
      trackStyle: const BarTrackStyle(color: Color(0xFFE0F2F1), value: 100),
    );
    const transform = ChartTransform(
      dataXMin: -1,
      dataXMax: 1000,
      dataYMin: 0,
      dataYMax: 110,
      plotWidth: 1600,
      plotHeight: 900,
    );

    for (var warmup = 0; warmup < 5; warmup++) {
      BarGeometryEngine.layout(series: series, transform: transform);
    }

    const iterations = 20;
    final stopwatch = Stopwatch()..start();
    for (var iteration = 0; iteration < iterations; iteration++) {
      final geometry = BarGeometryEngine.layout(
        series: series,
        transform: transform,
      );
      expect(geometry, hasLength(1000));
    }
    stopwatch.stop();

    final averageMilliseconds =
        stopwatch.elapsedMicroseconds / iterations / 1000;
    // ignore: avoid_print
    print(
      'Bar geometry (1,000 styled bars): '
      '${averageMilliseconds.toStringAsFixed(3)}ms average',
    );
    expect(averageMilliseconds, lessThan(16.67));
  });
}
