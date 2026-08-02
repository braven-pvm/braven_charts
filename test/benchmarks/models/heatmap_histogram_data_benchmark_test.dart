// Copyright 2026 Braven Charts contributors
// SPDX-License-Identifier: MIT

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('50K observations produce a 128 by 64 histogram promptly', () {
    final observations = [
      for (var index = 0; index < 50000; index++)
        HeatmapHistogramObservation(
          x: ((index * 37) % 10000) / 100,
          y: ((index * 53) % 6400) / 100,
          weight: 0.5 + (index % 7) * 0.25,
          pointKey: 'observation-$index',
        ),
    ];
    final xAxis = HeatmapHistogramAxis(
      boundaries: [for (var index = 0; index <= 128; index++) index * 0.78125],
    );
    final yAxis = HeatmapHistogramAxis(
      boundaries: [for (var index = 0; index <= 64; index++) index.toDouble()],
    );

    final stopwatch = Stopwatch()..start();
    final result = HeatmapHistogramData(
      observations: observations,
      xAxis: xAxis,
      yAxis: yAxis,
    );
    final cells = result.cellsFor(valueMode: HeatmapHistogramValueMode.weight);
    stopwatch.stop();

    final elapsedMs = stopwatch.elapsedMicroseconds / 1000;
    // ignore: avoid_print
    print(
      'Heatmap histogram transform '
      '(50,000 observations / 8,192 bins): '
      '${elapsedMs.toStringAsFixed(3)}ms',
    );
    expect(result.includedObservationCount, 50000);
    expect(cells, hasLength(8192));
    expect(elapsedMs, lessThan(2000));
  });
}
