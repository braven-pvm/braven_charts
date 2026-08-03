// Copyright 2026 Braven Charts contributors
// SPDX-License-Identifier: MIT

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter_test/flutter_test.dart';

import '../heatmap_benchmark_support.dart';

void main() {
  test('five contour levels traverse a 32 by 24 density raster promptly', () {
    final density = HeatmapDensityData(
      observations: [
        for (var index = 0; index < 2000; index++)
          HeatmapDensityObservation(
            x: ((index * 37) % 1000) / 100,
            y: ((index * 53) % 1000) / 10,
            weight: 0.75 + (index % 5) * 0.1,
            pointKey: 'observation-$index',
          ),
      ],
      xAxis: HeatmapDensityAxis(minimum: 0, maximum: 10, cellCount: 32),
      yAxis: HeatmapDensityAxis(minimum: 0, maximum: 100, cellCount: 24),
      bandwidthX: 0.6,
      bandwidthY: 6,
    );

    late HeatmapContourData contours;
    final distribution = measureHeatmapSync(() {
      contours = HeatmapContourData.fromDensity(
        density,
        levels: const [0.15, 0.3, 0.45, 0.6, 0.75],
      );
    });

    printHeatmapDistribution(
      'Heatmap contour transform (768 cells / 5 levels)',
      distribution,
    );
    expect(contours.paths, isNotEmpty);
    expect(contours.paths.expand((path) => path.points), isNotEmpty);
    expect(distribution.p95Millis, lessThan(500));
  });
}
