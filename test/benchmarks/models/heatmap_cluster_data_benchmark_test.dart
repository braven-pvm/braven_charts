// Copyright 2026 Braven Charts contributors
// SPDX-License-Identifier: MIT

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter_test/flutter_test.dart';

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

    final stopwatch = Stopwatch()..start();
    final result = HeatmapMatrixClusterData(
      rowLabels: [for (var row = 0; row < rowCount; row++) 'Row $row'],
      columnLabels: [
        for (var column = 0; column < columnCount; column++) 'Column $column',
      ],
      cells: cells,
    );
    stopwatch.stop();

    final elapsedMs = stopwatch.elapsedMicroseconds / 1000;
    // ignore: avoid_print
    print(
      'Heatmap clustering (48 rows / 32 columns / 1,536 cells): '
      '${elapsedMs.toStringAsFixed(3)}ms',
    );
    expect(result.cells, hasLength(rowCount * columnCount));
    expect(result.rowRoot, isNotNull);
    expect(result.columnRoot, isNotNull);
    expect(elapsedMs, lessThan(1500));
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

    final clusterStopwatch = Stopwatch()..start();
    final result = HeatmapMatrixClusterData(
      rowLabels: [for (var row = 0; row < rowCount; row++) 'Row $row'],
      columnLabels: [
        for (var column = 0; column < columnCount; column++) 'Column $column',
      ],
      cells: cells,
    );
    clusterStopwatch.stop();

    final hierarchyRoot = HeatmapClusterNode.fromJson(
      _balancedRootJson(0, 512),
    );
    final layoutStopwatch = Stopwatch()..start();
    final hierarchy = HeatmapDendrogramData(
      root: hierarchyRoot,
      sourceLabels: [for (var index = 0; index < 512; index++) 'Leaf $index'],
      axis: HeatmapDendrogramAxis.columns,
      distanceScale: HeatmapDendrogramDistanceScale.structural,
    );
    layoutStopwatch.stop();

    final clusterMs = clusterStopwatch.elapsedMicroseconds / 1000;
    final layoutMs = layoutStopwatch.elapsedMicroseconds / 1000;
    // ignore: avoid_print
    print(
      'Heatmap scale benchmark (96 x 64 / 6,144 cells): '
      '${clusterMs.toStringAsFixed(3)}ms; '
      '512-leaf dendrogram layout: ${layoutMs.toStringAsFixed(3)}ms',
    );
    expect(result.cells, hasLength(rowCount * columnCount));
    expect(hierarchy.nodes, hasLength(1023));
    expect(hierarchy.segments, hasLength(1533));
    expect(clusterMs, lessThan(4000));
    expect(layoutMs, lessThan(250));
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
