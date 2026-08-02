// Copyright 2026 Braven Charts contributors
// SPDX-License-Identifier: MIT

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('2K observations produce a 32 by 24 density raster promptly', () {
    final observations = [
      for (var index = 0; index < 2000; index++)
        HeatmapDensityObservation(
          x: ((index * 37) % 1000) / 100,
          y: ((index * 53) % 1000) / 10,
          weight: 0.75 + (index % 5) * 0.1,
          pointKey: 'observation-$index',
        ),
    ];
    final xAxis = HeatmapDensityAxis(minimum: 0, maximum: 10, cellCount: 32);
    final yAxis = HeatmapDensityAxis(minimum: 0, maximum: 100, cellCount: 24);

    final stopwatch = Stopwatch()..start();
    final result = HeatmapDensityData(
      observations: observations,
      xAxis: xAxis,
      yAxis: yAxis,
      bandwidthX: 0.6,
      bandwidthY: 6,
    );
    stopwatch.stop();

    final elapsedMs = stopwatch.elapsedMicroseconds / 1000;
    // ignore: avoid_print
    print(
      'Heatmap density transform '
      '(2,000 observations / 768 cells): '
      '${elapsedMs.toStringAsFixed(3)}ms',
    );
    expect(result.cells, hasLength(768));
    expect(result.maximumDensity, greaterThan(0));
    expect(elapsedMs, lessThan(1500));
  });
}
