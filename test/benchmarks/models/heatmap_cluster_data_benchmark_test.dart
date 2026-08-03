// Copyright 2026 Braven Charts contributors
// SPDX-License-Identifier: MIT

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter_test/flutter_test.dart';

import '../heatmap_benchmark_support.dart';

void main() {
  test('48 by 32 matrix clusters both axes promptly', () {
    const rowCount = 48;
    const columnCount = 32;
    final cells = [
      for (var row = 0; row < rowCount; row++)
        for (var column = 0; column < columnCount; column++)
          HeatmapDataPoint(
            x: column.toDouble(),
            y: row.toDouble(),
            value:
                ((row % 6) * 0.7) +
                ((column % 4) * 0.35) +
                ((row * 17 + column * 31) % 13) / 20,
            pointKey: 'benchmark-$row-$column',
          ),
    ];

    final rowLabels = [for (var row = 0; row < rowCount; row++) 'Row $row'];
    final columnLabels = [
      for (var column = 0; column < columnCount; column++) 'Column $column',
    ];
    late HeatmapMatrixClusterData result;
    final distribution = measureHeatmapSync(() {
      result = HeatmapMatrixClusterData(
        rowLabels: rowLabels,
        columnLabels: columnLabels,
        cells: cells,
      );
    });

    printHeatmapDistribution(
      'Heatmap clustering (48 rows / 32 columns / 1,536 cells): '
      'transform',
      distribution,
    );
    expect(result.cells, hasLength(rowCount * columnCount));
    expect(result.rowRoot, isNotNull);
    expect(result.columnRoot, isNotNull);
    expect(distribution.p95Millis, lessThan(1500));
  });

  test('96 by 64 matrix and 512-leaf hierarchy remain bounded', () {
    const rowCount = 96;
    const columnCount = 64;
    final cells = [
      for (var row = 0; row < rowCount; row++)
        for (var column = 0; column < columnCount; column++)
          HeatmapDataPoint(
            x: column.toDouble(),
            y: row.toDouble(),
            value:
                ((row % 8) * 0.55) +
                ((column % 7) * 0.3) +
                ((row * 19 + column * 29) % 17) / 25,
            pointKey: 'scale-$row-$column',
          ),
    ];

    final rowLabels = [for (var row = 0; row < rowCount; row++) 'Row $row'];
    final columnLabels = [
      for (var column = 0; column < columnCount; column++) 'Column $column',
    ];
    late HeatmapMatrixClusterData result;
    final clusterDistribution = measureHeatmapSync(() {
      result = HeatmapMatrixClusterData(
        rowLabels: rowLabels,
        columnLabels: columnLabels,
        cells: cells,
      );
    });

    final hierarchyRoot = HeatmapClusterNode.fromJson(
      _balancedRootJson(0, 512),
    );
    final sourceLabels = [
      for (var index = 0; index < 512; index++) 'Leaf $index',
    ];
    late HeatmapDendrogramData hierarchy;
    final layoutDistribution = measureHeatmapSync(() {
      hierarchy = HeatmapDendrogramData(
        root: hierarchyRoot,
        sourceLabels: sourceLabels,
        axis: HeatmapDendrogramAxis.columns,
        distanceScale: HeatmapDendrogramDistanceScale.structural,
      );
    });

    printHeatmapDistribution(
      'Heatmap scale benchmark (96 x 64 / 6,144 cells)',
      clusterDistribution,
    );
    printHeatmapDistribution(
      'Heatmap 512-leaf dendrogram layout',
      layoutDistribution,
    );
    expect(result.cells, hasLength(rowCount * columnCount));
    expect(hierarchy.nodes, hasLength(1023));
    expect(hierarchy.segments, hasLength(1533));
    expect(clusterDistribution.p95Millis, lessThan(4000));
    expect(layoutDistribution.p95Millis, lessThan(250));
  });
}

Map<String, dynamic> _balancedRootJson(int start, int end) {
  if (end - start == 1) {
    return {
      'id': 'axis:leaf:$start',
      'distance': 0,
      'memberIndices': [start],
      'leafIndex': start,
    };
  }
  final middle = (start + end) ~/ 2;
  return {
    'id': 'axis:$start-${end - 1}',
    'distance': (end - start).toDouble(),
    'memberIndices': [for (var index = start; index < end; index++) index],
    'left': _balancedRootJson(start, middle),
    'right': _balancedRootJson(middle, end),
  };
}
