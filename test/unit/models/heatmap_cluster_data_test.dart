// Copyright 2026 Braven Charts contributors
// SPDX-License-Identifier: MIT

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HeatmapMatrixClusterData', () {
    test('clusters related rows and columns deterministically', () {
      final data = HeatmapMatrixClusterData(
        rowLabels: const ['R0', 'R1', 'R2', 'R3'],
        columnLabels: const ['C0', 'C1', 'C2', 'C3'],
        cells: _cells(const [
          [9, 1, 8, 2],
          [1, 9, 2, 8],
          [8, 2, 9, 1],
          [2, 8, 1, 9],
        ]),
        config: const HeatmapClusterConfig(
          distance: HeatmapClusterDistance.euclidean,
        ),
      );

      expect(data.rowOrder, const [0, 2, 1, 3]);
      expect(data.columnOrder, const [0, 2, 1, 3]);
      expect(data.rowLabels, const ['R0', 'R2', 'R1', 'R3']);
      expect(data.columnLabels, const ['C0', 'C2', 'C1', 'C3']);
      expect(data.rowRoot!.leafOrder, data.rowOrder);
      expect(data.columnRoot!.leafOrder, data.columnOrder);

      final repeated = HeatmapMatrixClusterData(
        rowLabels: const ['R0', 'R1', 'R2', 'R3'],
        columnLabels: const ['C0', 'C1', 'C2', 'C3'],
        cells: _cells(const [
          [9, 1, 8, 2],
          [1, 9, 2, 8],
          [8, 2, 9, 1],
          [2, 8, 1, 9],
        ]),
        config: const HeatmapClusterConfig(
          distance: HeatmapClusterDistance.euclidean,
        ),
      );
      expect(repeated.rowRoot!.toJson(), data.rowRoot!.toJson());
      expect(repeated.columnRoot!.toJson(), data.columnRoot!.toJson());
    });

    test('supports independent axes and disabled source order', () {
      final rowsOnly = HeatmapMatrixClusterData(
        rowLabels: const ['R0', 'R1', 'R2'],
        columnLabels: const ['C0', 'C1'],
        cells: _cells(const [
          [9, 1],
          [1, 9],
          [8, 2],
        ]),
        config: const HeatmapClusterConfig(
          axisMode: HeatmapClusterAxisMode.rows,
          distance: HeatmapClusterDistance.euclidean,
        ),
      );
      expect(rowsOnly.rowOrder, const [0, 2, 1]);
      expect(rowsOnly.columnOrder, const [0, 1]);
      expect(rowsOnly.rowRoot, isNotNull);
      expect(rowsOnly.columnRoot, isNull);

      final sourceOrder = HeatmapMatrixClusterData(
        rowLabels: const ['R0', 'R1', 'R2'],
        columnLabels: const ['C0', 'C1'],
        cells: _cells(const [
          [9, 1],
          [1, 9],
          [8, 2],
        ]),
        config: const HeatmapClusterConfig(
          axisMode: HeatmapClusterAxisMode.none,
        ),
      );
      expect(sourceOrder.rowOrder, const [0, 1, 2]);
      expect(sourceOrder.columnOrder, const [0, 1]);
      expect(sourceOrder.rowRoot, isNull);
      expect(sourceOrder.columnRoot, isNull);
    });

    test('keeps logical cell identity and records source coordinates', () {
      final source = _cells(const [
        [9, 1, 8],
        [1, 9, 2],
        [8, 2, 9],
      ]);
      final data = HeatmapMatrixClusterData(
        rowLabels: const ['R0', 'R1', 'R2'],
        columnLabels: const ['C0', 'C1', 'C2'],
        cells: source,
        config: const HeatmapClusterConfig(
          distance: HeatmapClusterDistance.euclidean,
        ),
      );

      final reordered = data.cells.singleWhere(
        (cell) => cell.pointKey == 'cell-2-0',
      );
      expect(reordered.identity, source[6].identity);
      expect(reordered.x, 0);
      expect(reordered.y, 1);
      expect(
        reordered.metadata,
        containsPair('heatmapClusterSourceRowIndex', 2),
      );
      expect(
        reordered.metadata,
        containsPair('heatmapClusterSourceColumnLabel', 'C0'),
      );
      expect(data.metadata['heatmapClusterRowOrder'], const [0, 2, 1]);
    });

    test('round-trips hierarchy JSON', () {
      final data = HeatmapMatrixClusterData(
        rowLabels: const ['A', 'B', 'C'],
        columnLabels: const ['X', 'Y'],
        cells: _cells(const [
          [1, 2],
          [8, 9],
          [2, 3],
        ]),
      );
      final json = data.rowRoot!.toJson();
      final restored = HeatmapClusterNode.fromJson(json);

      expect(restored.toJson(), json);
      expect(restored.leafOrder, data.rowOrder);
      expect(
        () => HeatmapClusterNode.fromJson({'id': 'broken'}),
        throwsFormatException,
      );
    });

    test('focuses accepted subtrees without reclustering source cells', () {
      final source = HeatmapMatrixClusterData(
        rowLabels: const ['R0', 'R1', 'R2', 'R3'],
        columnLabels: const ['C0', 'C1', 'C2', 'C3'],
        cells: _cells(const [
          [9, 1, 8, 2],
          [1, 9, 2, 8],
          [8, 2, 9, 1],
          [2, 8, 1, 9],
        ]),
        config: const HeatmapClusterConfig(
          distance: HeatmapClusterDistance.euclidean,
        ),
      );
      final focused = HeatmapMatrixClusterFocusData(
        source: source,
        rowRootId: source.rowRoot!.left!.id,
        columnRootId: source.columnRoot!.right!.id,
      );

      expect(focused.rowOrder, source.rowRoot!.left!.leafOrder);
      expect(focused.columnOrder, source.columnRoot!.right!.leafOrder);
      expect(focused.rowLabels, ['R0', 'R2']);
      expect(focused.columnLabels, ['C1', 'C3']);
      expect(focused.cells, hasLength(4));
      expect(focused.cells.map((cell) => (cell.x, cell.y)), [
        (0.0, 0.0),
        (1.0, 0.0),
        (0.0, 1.0),
        (1.0, 1.0),
      ]);
      expect(
        focused.cells.first.metadata,
        containsPair('heatmapClusterSourceRowIndex', 0),
      );
      expect(
        focused.cells.first.metadata,
        containsPair('heatmapClusterFocusColumnIndex', 0),
      );
      expect(
        focused.metadata,
        containsPair('heatmapClusterFocusRowRootId', source.rowRoot!.left!.id),
      );
      expect(focused.rowRoot!.toJson(), source.rowRoot!.left!.toJson());
      expect(focused.columnRoot!.toJson(), source.columnRoot!.right!.toJson());
    });

    test('rejects focus roots outside the accepted hierarchy', () {
      final source = HeatmapMatrixClusterData(
        rowLabels: const ['R0', 'R1'],
        columnLabels: const ['C0', 'C1'],
        cells: _cells(const [
          [1, 2],
          [3, 4],
        ]),
      );

      expect(
        () => HeatmapMatrixClusterFocusData(
          source: source,
          rowRootId: 'row:not-present',
        ),
        throwsArgumentError,
      );
    });

    test('applies explicit pairwise and zero missing-value semantics', () {
      final cells = <HeatmapDataPoint>[
        HeatmapDataPoint(x: 0, y: 0, value: 4, pointKey: 'a0'),
        HeatmapDataPoint.missing(x: 1, y: 0, pointKey: 'a1'),
        HeatmapDataPoint(x: 0, y: 1, value: 4, pointKey: 'b0'),
        HeatmapDataPoint(x: 1, y: 1, value: 8, pointKey: 'b1'),
        HeatmapDataPoint.missing(x: 0, y: 2, pointKey: 'c0'),
        HeatmapDataPoint(x: 1, y: 2, value: 8, pointKey: 'c1'),
      ];
      final pairwise = HeatmapMatrixClusterData(
        rowLabels: const ['A', 'B', 'C'],
        columnLabels: const ['X', 'Y'],
        cells: cells,
        config: const HeatmapClusterConfig(
          axisMode: HeatmapClusterAxisMode.rows,
          distance: HeatmapClusterDistance.euclidean,
        ),
      );
      final zero = HeatmapMatrixClusterData(
        rowLabels: const ['A', 'B', 'C'],
        columnLabels: const ['X', 'Y'],
        cells: cells,
        config: const HeatmapClusterConfig(
          axisMode: HeatmapClusterAxisMode.rows,
          distance: HeatmapClusterDistance.euclidean,
          missingValueMode: HeatmapClusterMissingValueMode.zero,
        ),
      );

      expect(pairwise.rowOrder, const [0, 1, 2]);
      expect(zero.rowOrder, const [0, 1, 2]);
      expect(pairwise.rowRoot!.left!.memberIndices, const [0, 1]);
      expect(pairwise.rowRoot!.right!.memberIndices, const [2]);
      expect(zero.rowRoot!.left!.memberIndices, const [0]);
      expect(zero.rowRoot!.right!.memberIndices, const [1, 2]);
    });

    test('supports all linkage modes and correlation distance', () {
      for (final linkage in HeatmapClusterLinkage.values) {
        final data = HeatmapMatrixClusterData(
          rowLabels: const ['A', 'B', 'C', 'D'],
          columnLabels: const ['X', 'Y', 'Z'],
          cells: _cells(const [
            [1, 2, 3],
            [8, 7, 6],
            [2, 4, 6],
            [7, 5, 3],
          ]),
          config: HeatmapClusterConfig(
            axisMode: HeatmapClusterAxisMode.rows,
            distance: HeatmapClusterDistance.correlation,
            linkage: linkage,
          ),
        );
        expect(data.rowOrder, hasLength(4));
        expect(data.rowOrder.toSet(), {0, 1, 2, 3});
        expect(data.rowRoot!.distance, isNonNegative);
      }
    });

    test('rejects incomplete, duplicate, and invalid matrix input', () {
      expect(
        () => HeatmapMatrixClusterData(
          rowLabels: const ['A'],
          columnLabels: const ['X', 'Y'],
          cells: [HeatmapDataPoint(x: 0, y: 0, value: 1)],
        ),
        throwsArgumentError,
      );
      expect(
        () => HeatmapMatrixClusterData(
          rowLabels: const ['A'],
          columnLabels: const ['X', 'Y'],
          cells: [
            HeatmapDataPoint(x: 0, y: 0, value: 1),
            HeatmapDataPoint(x: 0, y: 0, value: 2),
          ],
        ),
        throwsArgumentError,
      );
      expect(
        () => HeatmapMatrixClusterData(
          rowLabels: const ['A', 'A'],
          columnLabels: const ['X'],
          cells: _cells(const [
            [1],
            [2],
          ]),
        ),
        throwsArgumentError,
      );
      expect(
        () => HeatmapMatrixClusterData(
          rowLabels: const ['A'],
          columnLabels: const ['X'],
          cells: [HeatmapDataPoint(x: 0.5, y: 0, value: 1)],
        ),
        throwsArgumentError,
      );
    });
  });
}

List<HeatmapDataPoint> _cells(List<List<num>> values) => [
  for (var row = 0; row < values.length; row++)
    for (var column = 0; column < values[row].length; column++)
      HeatmapDataPoint(
        x: column.toDouble(),
        y: row.toDouble(),
        value: values[row][column].toDouble(),
        pointKey: 'cell-$row-$column',
        label: 'Cell $row, $column',
        metadata: {'source': 'test'},
      ),
];
