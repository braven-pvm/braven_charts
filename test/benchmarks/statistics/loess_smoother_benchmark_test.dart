import 'dart:math' as math;

import 'package:braven_charts/src/models/chart_data_point.dart';
import 'package:braven_charts/src/statistics/loess_smoother.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('fits a bounded LOESS curve over 100,000 source points promptly', () {
    final points = [
      for (var index = 0; index < 100000; index++)
        ChartDataPoint(
          x: index / 1000,
          y: 20 + math.sin(index / 3000) * 8 + (index % 17) / 20,
        ),
    ];
    const smoother = LoessSmoother(
      span: 0.4,
      robustnessIterations: 2,
      sampleCount: 120,
      maximumInputPoints: 1024,
    );

    final stopwatch = Stopwatch()..start();
    final result = smoother.smooth(points);
    stopwatch.stop();

    final elapsedMs = stopwatch.elapsedMicroseconds / 1000;
    // ignore: avoid_print
    print(
      'Robust LOESS (100,000 source / 1,024 fit points): '
      '${elapsedMs.toStringAsFixed(3)}ms',
    );
    expect(result, hasLength(120));
    expect(
      result.every((point) => point.x.isFinite && point.y.isFinite),
      isTrue,
    );
    expect(elapsedMs, lessThan(1500));
  });
}
