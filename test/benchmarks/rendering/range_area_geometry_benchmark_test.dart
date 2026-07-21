import 'dart:math' as math;

import 'package:braven_charts/braven_charts.dart';
import 'package:braven_charts/src/rendering/range_area_geometry.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final points = <RangeAreaDataPoint>[
    for (var index = 0; index < 50000; index++)
      RangeAreaDataPoint(
        x: index.toDouble(),
        low: 40 + math.sin(index / 80) * 12,
        high: 60 + math.sin(index / 80) * 12 + math.cos(index / 37) * 4,
      ),
  ];
  final index = RangeAreaViewportIndex(points);

  test('cold-indexes 5,000 ordered intervals promptly', () {
    final stopwatch = Stopwatch()..start();
    final coldIndex = RangeAreaViewportIndex(points.take(5000).toList());
    stopwatch.stop();

    final elapsedMs = stopwatch.elapsedMicroseconds / 1000;
    // ignore: avoid_print
    print('Cold Range Area index (5,000): ${elapsedMs.toStringAsFixed(3)}ms');
    expect(coldIndex.points, hasLength(5000));
    expect(elapsedMs, lessThan(16.67));
  });

  test('cold-indexes 50,000 ordered intervals promptly', () {
    final stopwatch = Stopwatch()..start();
    final coldIndex = RangeAreaViewportIndex(points);
    stopwatch.stop();

    final elapsedMs = stopwatch.elapsedMicroseconds / 1000;
    // ignore: avoid_print
    print('Cold Range Area index (50,000): ${elapsedMs.toStringAsFixed(3)}ms');
    expect(coldIndex.points, hasLength(50000));
    expect(elapsedMs, lessThan(100));
  });

  test('resolves 1,000 visible monotone intervals within one frame', () {
    for (var warmup = 0; warmup < 5; warmup++) {
      _resolve(index, warmup * 1000.0);
    }

    const iterations = 50;
    final stopwatch = Stopwatch()..start();
    for (var iteration = 0; iteration < iterations; iteration++) {
      final geometry = _resolve(index, iteration * 500.0);
      expect(geometry, hasLength(1));
      expect(geometry.single.points.length, inInclusiveRange(1000, 1002));
    }
    stopwatch.stop();

    final averageMs = stopwatch.elapsedMicroseconds / 1000 / iterations;
    // ignore: avoid_print
    print(
      'Virtualized Range Area geometry '
      '(50,000 source / 1,000 visible): '
      '${averageMs.toStringAsFixed(3)}ms average',
    );
    expect(averageMs, lessThan(16.67));
  });
}

List<RangeAreaGeometryRun> _resolve(
  RangeAreaViewportIndex index,
  double start,
) => RangeAreaGeometryEngine.resolve(
  index: index,
  transform: ChartTransform(
    dataXMin: start,
    dataXMax: start + 999,
    dataYMin: 20,
    dataYMax: 80,
    plotWidth: 1600,
    plotHeight: 900,
  ),
  interpolation: LineInterpolation.monotone,
);
