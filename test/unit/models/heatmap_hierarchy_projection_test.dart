// Copyright 2026 Braven Charts contributors
// SPDX-License-Identifier: MIT

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HeatmapHierarchyCollapseState', () {
    test('is immutable, deterministic, and JSON portable', () {
      final state = HeatmapHierarchyCollapseState(
        collapsedNodeIds: const ['branch:b', 'branch:a', 'branch:a'],
      );

      expect(state.toJson(), {
        'collapsedNodeIds': ['branch:a', 'branch:b'],
      });
      expect(HeatmapHierarchyCollapseState.fromJson(state.toJson()), state);
      expect(state.toggle('branch:a').collapsedNodeIds, {'branch:b'});
      expect(state.expand('missing'), same(state));
      expect(state.clear().collapsedNodeIds, isEmpty);
      expect(
        () => HeatmapHierarchyCollapseState.fromJson({
          'collapsedNodeIds': [1],
        }),
        throwsFormatException,
      );
    });
  });

  group('HeatmapHierarchyProjection', () {
    test('collapses a merge into one source-preserving visible group', () {
      final projection = HeatmapHierarchyProjection(
        root: _root,
        sourceLabels: const ['Alpha', 'Beta', 'Gamma', 'Delta'],
        collapseState: HeatmapHierarchyCollapseState(
          collapsedNodeIds: const ['row:0,1'],
        ),
      );

      expect(projection.visibleGroups, [
        const HeatmapHierarchyVisibleGroup(
          nodeId: 'row:0,1',
          label: 'Alpha + 1',
          sourceIndices: [0, 1],
          mergeDistance: 1,
          isCollapsed: true,
        ),
        const HeatmapHierarchyVisibleGroup(
          nodeId: 'row:leaf:2',
          label: 'Gamma',
          sourceIndices: [2],
          mergeDistance: 0,
          isCollapsed: false,
        ),
        const HeatmapHierarchyVisibleGroup(
          nodeId: 'row:leaf:3',
          label: 'Delta',
          sourceIndices: [3],
          mergeDistance: 0,
          isCollapsed: false,
        ),
      ]);
      expect(projection.sourceOrder, [0, 1, 2, 3]);
      expect(projection.activeCollapsedNodeIds, {'row:0,1'});
      expect(projection.ignoredCollapsedNodeIds, isEmpty);
    });

    test('retains nested collapse state while an ancestor hides it', () {
      final collapsed = HeatmapHierarchyCollapseState(
        collapsedNodeIds: const ['row:0,1', 'row:0,1,2,3', 'stale'],
      );
      final hidden = HeatmapHierarchyProjection(
        root: _root,
        sourceLabels: const ['Alpha', 'Beta', 'Gamma', 'Delta'],
        collapseState: collapsed,
        collapsedLabels: const {'row:0,1,2,3': 'All signals'},
      );

      expect(hidden.visibleGroups.single.label, 'All signals');
      expect(hidden.activeCollapsedNodeIds, {'row:0,1,2,3'});
      expect(hidden.ignoredCollapsedNodeIds, {'row:0,1', 'stale'});

      final expanded = HeatmapHierarchyProjection(
        root: _root,
        sourceLabels: const ['Alpha', 'Beta', 'Gamma', 'Delta'],
        collapseState: collapsed.expand('row:0,1,2,3'),
      );
      expect(expanded.activeCollapsedNodeIds, {'row:0,1'});
      expect(expanded.visibleGroups.map((group) => group.nodeId), [
        'row:0,1',
        'row:leaf:2',
        'row:leaf:3',
      ]);
    });

    test('reports leaf and stale IDs without corrupting the projection', () {
      final projection = HeatmapHierarchyProjection(
        root: _root,
        sourceLabels: const ['Alpha', 'Beta', 'Gamma', 'Delta'],
        collapseState: HeatmapHierarchyCollapseState(
          collapsedNodeIds: const ['row:leaf:0', 'removed-node'],
        ),
      );

      expect(projection.visibleGroups, hasLength(4));
      expect(projection.activeCollapsedNodeIds, isEmpty);
      expect(projection.ignoredCollapsedNodeIds, {
        'row:leaf:0',
        'removed-node',
      });
      expect(projection.containsNode('row:leaf:0'), isTrue);
      expect(projection.containsNode('removed-node'), isFalse);
    });
  });

  group('HeatmapHierarchyMatrixProjection', () {
    test('aggregates visible groups while retaining source provenance', () {
      final source = HeatmapMatrixClusterFocusData(source: _matrixSource());
      final projection = HeatmapHierarchyMatrixProjection(
        source: source,
        rowCollapseState: HeatmapHierarchyCollapseState(
          collapsedNodeIds: {source.rowRoot!.id},
        ),
      );

      expect(projection.rowLabels, ['Alpha + 1']);
      expect(projection.columnLabels, hasLength(2));
      expect(projection.cells, hasLength(2));
      final valuesBySourceColumn = {
        for (final cell in projection.cells)
          (cell.metadata!['heatmapHierarchySourceColumnIndices'] as List)
                  .single:
              cell.value,
      };
      expect(valuesBySourceColumn[0], 3);
      expect(valuesBySourceColumn[1], 3);
      expect(
        projection.cells.first.metadata!['heatmapHierarchySourceRowIndices'],
        [0, 1],
      );
      expect(projection.metadata['heatmapHierarchyRowCollapseState'], {
        'collapsedNodeIds': [source.rowRoot!.id],
      });
    });

    test('supports an explicit reducer and all-missing output', () {
      final source = HeatmapMatrixClusterFocusData(source: _matrixSource());
      final projection = HeatmapHierarchyMatrixProjection(
        source: source,
        rowCollapseState: HeatmapHierarchyCollapseState(
          collapsedNodeIds: {source.rowRoot!.id},
        ),
        columnCollapseState: HeatmapHierarchyCollapseState(
          collapsedNodeIds: {source.columnRoot!.id},
        ),
        reducer: HeatmapHierarchyReducer.sum,
      );

      expect(projection.cells.single.value, 9);
      expect(
        projection.cells.single.metadata!['heatmapHierarchySourceCellCount'],
        4,
      );
      expect(
        projection.cells.single.metadata!['heatmapHierarchyMeasuredCellCount'],
        3,
      );
    });
  });
}

HeatmapMatrixClusterData _matrixSource() => HeatmapMatrixClusterData(
  rowLabels: const ['Alpha', 'Beta'],
  columnLabels: const ['First', 'Second'],
  cells: [
    HeatmapDataPoint(x: 0, y: 0, value: 1, pointKey: 'a-first'),
    HeatmapDataPoint(x: 1, y: 0, value: 3, pointKey: 'a-second'),
    HeatmapDataPoint(x: 0, y: 1, value: 5, pointKey: 'b-first'),
    HeatmapDataPoint.missing(x: 1, y: 1, pointKey: 'b-second'),
  ],
);

final _root = HeatmapClusterNode.fromJson(const {
  'id': 'row:0,1,2,3',
  'distance': 3,
  'memberIndices': [0, 1, 2, 3],
  'left': {
    'id': 'row:0,1',
    'distance': 1,
    'memberIndices': [0, 1],
    'left': {
      'id': 'row:leaf:0',
      'distance': 0,
      'memberIndices': [0],
      'leafIndex': 0,
    },
    'right': {
      'id': 'row:leaf:1',
      'distance': 0,
      'memberIndices': [1],
      'leafIndex': 1,
    },
  },
  'right': {
    'id': 'row:2,3',
    'distance': 2,
    'memberIndices': [2, 3],
    'left': {
      'id': 'row:leaf:2',
      'distance': 0,
      'memberIndices': [2],
      'leafIndex': 2,
    },
    'right': {
      'id': 'row:leaf:3',
      'distance': 0,
      'memberIndices': [3],
      'leafIndex': 3,
    },
  },
});
