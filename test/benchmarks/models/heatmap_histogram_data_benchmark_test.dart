// Copyright 2026 Braven Charts contributors
// SPDX-License-Identifier: MIT

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter_test/flutter_test.dart';

import '../heatmap_benchmark_support.dart';

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

    late HeatmapHistogramData result;
    late List<HeatmapDataPoint> cells;
    final distribution = measureHeatmapSync(() {
      result = HeatmapHistogramData(
        observations: observations,
        xAxis: xAxis,
        yAxis: yAxis,
      );
      cells = result.cellsFor(valueMode: HeatmapHistogramValueMode.weight);
    });

    printHeatmapDistribution(
      'Heatmap histogram transform '
      '(50,000 observations / 8,192 bins)',
      distribution,
    );
    expect(result.includedObservationCount, 50000);
    expect(cells, hasLength(8192));
    expect(distribution.p95Millis, lessThan(2000));
  });
}
