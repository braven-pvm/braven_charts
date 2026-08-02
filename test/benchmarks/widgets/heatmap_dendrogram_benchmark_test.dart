// Copyright 2026 Braven Charts contributors
// SPDX-License-Identifier: MIT

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('cached 512-leaf dendrogram repaints remain bounded', (
    tester,
  ) async {
    final data = HeatmapDendrogramData(
      root: HeatmapClusterNode.fromJson(_balancedRootJson(0, 512)),
      sourceLabels: [for (var index = 0; index < 512; index++) 'Leaf $index'],
      axis: HeatmapDendrogramAxis.columns,
      distanceScale: HeatmapDendrogramDistanceScale.structural,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 1024,
          height: 120,
          child: HeatmapDendrogram(
            data: data,
            style: const HeatmapDendrogramStyle(
              showLeafTicks: true,
              showLeafMarkers: true,
              showMergeMarkers: true,
              showMergeDistanceLabels: true,
            ),
          ),
        ),
      ),
    );

    final renderObject = tester.renderObject<RenderCustomPaint>(
      find.byKey(const ValueKey('heatmap-columns-dendrogram-canvas')),
    );
    final stopwatch = Stopwatch()..start();
    for (var frame = 0; frame < 120; frame++) {
      renderObject.markNeedsPaint();
      await tester.pump();
    }
    stopwatch.stop();

    final elapsedMs = stopwatch.elapsedMicroseconds / 1000;
    // ignore: avoid_print
    print(
      'Cached 512-leaf dendrogram (120 repaints): '
      '${elapsedMs.toStringAsFixed(3)}ms',
    );
    expect(elapsedMs, lessThan(3000));
    expect(tester.takeException(), isNull);
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
