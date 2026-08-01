// Copyright 2026 Braven Charts contributors
// SPDX-License-Identifier: MIT

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HeatmapDendrogramData', () {
    test('derives stable normalized geometry from an accepted hierarchy', () {
      final data = HeatmapDendrogramData(
        root: _root(distance: 4),
        sourceLabels: const ['Alpha', 'Beta', 'Gamma'],
        axis: HeatmapDendrogramAxis.columns,
      );

      expect(data.leafOrder, [0, 1, 2]);
      expect(data.labels, ['Alpha', 'Beta', 'Gamma']);
      expect(data.maximumDistance, 4);
      expect(data.distanceScale, HeatmapDendrogramDistanceScale.proportional);
      expect(data.segments, hasLength(6));
      expect(data.nodes, hasLength(5));
      expect(data.nodes.where((node) => node.isLeaf), hasLength(3));
      expect(data.nodes.where((node) => node.isTerminal), hasLength(3));
      expect(
        data.nodes.singleWhere((node) => node.id == 'column:0,1'),
        const HeatmapDendrogramNode(
          id: 'column:0,1',
          category: 1 / 3,
          distance: 0.5,
          mergeDistance: 2,
          memberCount: 2,
        ),
      );
      expect(
        data.segments.map((segment) => segment.id),
        containsAll([
          'column:0,1:left',
          'column:0,1:right',
          'column:0,1:join',
          'column:0,1,2:left',
          'column:0,1,2:right',
          'column:0,1,2:join',
        ]),
      );
      final rootJoin = data.segments.singleWhere(
        (segment) => segment.id == 'column:0,1,2:join',
      );
      expect(rootJoin.startDistance, 1);
      expect(rootJoin.endDistance, 1);
      expect(rootJoin.startCategory, closeTo(1 / 3, 0.000001));
      expect(rootJoin.endCategory, closeTo(5 / 6, 0.000001));
    });

    test('round-trips JSON-safe hierarchy geometry', () {
      final source = HeatmapDendrogramData(
        root: _root(distance: 4),
        sourceLabels: const ['Alpha', 'Beta', 'Gamma'],
        axis: HeatmapDendrogramAxis.rows,
      );

      final restored = HeatmapDendrogramData.fromJson(source.toJson());

      expect(restored.axis, source.axis);
      expect(restored.distanceScale, source.distanceScale);
      expect(restored.rootId, source.rootId);
      expect(restored.sourceLabels, source.sourceLabels);
      expect(restored.leafOrder, source.leafOrder);
      expect(restored.labels, source.labels);
      expect(restored.visibleGroups, source.visibleGroups);
      expect(restored.collapseState, source.collapseState);
      expect(restored.maximumDistance, source.maximumDistance);
      expect(
        restored.segments.map((segment) => segment.toJson()),
        source.segments.map((segment) => segment.toJson()),
      );
      expect(restored.nodes, source.nodes);
      expect(restored.metadata, contains('heatmapDendrogramRow'));
    });

    test('uses structural depth when every merge distance is zero', () {
      final data = HeatmapDendrogramData(
        root: _root(distance: 0, childDistance: 0),
        sourceLabels: const ['Alpha', 'Beta', 'Gamma'],
        axis: HeatmapDendrogramAxis.columns,
      );

      final childJoin = data.segments.singleWhere(
        (segment) => segment.id == 'column:0,1:join',
      );
      final rootJoin = data.segments.singleWhere(
        (segment) => segment.id == 'column:0,1,2:join',
      );
      expect(childJoin.startDistance, greaterThan(0));
      expect(childJoin.startDistance, lessThan(1));
      expect(rootJoin.startDistance, 1);
    });

    test('structural spacing expands compressed merge distances', () {
      final proportional = HeatmapDendrogramData(
        root: _root(distance: 4, childDistance: 0.2),
        sourceLabels: const ['Alpha', 'Beta', 'Gamma'],
        axis: HeatmapDendrogramAxis.columns,
      );
      final structural = HeatmapDendrogramData(
        root: _root(distance: 4, childDistance: 0.2),
        sourceLabels: const ['Alpha', 'Beta', 'Gamma'],
        axis: HeatmapDendrogramAxis.columns,
        distanceScale: HeatmapDendrogramDistanceScale.structural,
      );

      final proportionalChild = proportional.segments.singleWhere(
        (segment) => segment.id == 'column:0,1:join',
      );
      final structuralChild = structural.segments.singleWhere(
        (segment) => segment.id == 'column:0,1:join',
      );
      expect(proportionalChild.startDistance, closeTo(0.05, 0.000001));
      expect(structuralChild.startDistance, closeTo(0.5, 0.000001));
      expect(
        structural.nodes
            .singleWhere((node) => node.id == 'column:0,1')
            .mergeDistance,
        0.2,
      );
      expect(structural.toJson(), containsPair('distanceScale', 'structural'));
    });

    test('supports a focused subtree over the complete source-label set', () {
      final root = _root(distance: 4).left!;
      final data = HeatmapDendrogramData(
        root: root,
        sourceLabels: const ['Alpha', 'Beta', 'Gamma'],
        axis: HeatmapDendrogramAxis.columns,
      );

      expect(data.leafOrder, [0, 1]);
      expect(data.labels, ['Alpha', 'Beta']);
      expect(data.sourceLabels, ['Alpha', 'Beta', 'Gamma']);
      expect(data.segments, hasLength(3));
    });

    test('projects collapsed branches as source-preserving terminals', () {
      final data = HeatmapDendrogramData(
        root: _root(distance: 4),
        sourceLabels: const ['Alpha', 'Beta', 'Gamma'],
        axis: HeatmapDendrogramAxis.columns,
        collapseState: HeatmapHierarchyCollapseState(
          collapsedNodeIds: const ['column:0,1'],
        ),
        collapsedLabels: const {'column:0,1': 'Alpha and Beta'},
      );

      expect(data.leafOrder, [0, 1, 2]);
      expect(data.labels, ['Alpha and Beta', 'Gamma']);
      expect(data.visibleGroups.first.sourceIndices, [0, 1]);
      expect(data.nodes, hasLength(3));
      expect(data.segments, hasLength(3));
      expect(
        data.nodes.singleWhere((node) => node.id == 'column:0,1'),
        const HeatmapDendrogramNode(
          id: 'column:0,1',
          category: 0.25,
          distance: 0,
          mergeDistance: 2,
          memberCount: 2,
          isTerminal: true,
        ),
      );
      expect(
        data.nodes.map((node) => node.id),
        isNot(contains('column:leaf:0')),
      );
      expect(data.visibleGroupForNode('column:0,1')?.label, 'Alpha and Beta');
    });

    test('round-trips collapse state and projected visible groups', () {
      final source = HeatmapDendrogramData(
        root: _root(distance: 4),
        sourceLabels: const ['Alpha', 'Beta', 'Gamma'],
        axis: HeatmapDendrogramAxis.rows,
        collapseState: HeatmapHierarchyCollapseState(
          collapsedNodeIds: const ['column:0,1'],
        ),
      );

      final restored = HeatmapDendrogramData.fromJson(source.toJson());

      expect(restored.collapseState, source.collapseState);
      expect(restored.visibleGroups, source.visibleGroups);
      expect(restored.nodes, source.nodes);
      expect(restored.segments, hasLength(3));
    });

    test('hydrates legacy geometry without projected hierarchy fields', () {
      final source = HeatmapDendrogramData(
        root: _root(distance: 4),
        sourceLabels: const ['Alpha', 'Beta', 'Gamma'],
        axis: HeatmapDendrogramAxis.columns,
      );
      final legacyJson = Map<String, dynamic>.from(source.toJson())
        ..remove('visibleGroups')
        ..remove('collapseState');
      legacyJson['nodes'] = [
        for (final node in legacyJson['nodes'] as List)
          Map<String, dynamic>.from(node as Map)..remove('isTerminal'),
      ];

      final restored = HeatmapDendrogramData.fromJson(legacyJson);

      expect(
        restored.collapseState,
        const HeatmapHierarchyCollapseState.empty(),
      );
      expect(restored.labels, source.labels);
      expect(restored.visibleGroups, source.visibleGroups);
      expect(
        restored.nodes.every((node) => node.isTerminal == node.isLeaf),
        isTrue,
      );
      expect(
        restored.segments.map((segment) => segment.toJson()),
        source.segments.map((segment) => segment.toJson()),
      );
    });

    test('rejects a hierarchy outside the source-label set', () {
      expect(
        () => HeatmapDendrogramData(
          root: HeatmapClusterNode.fromJson({
            'id': 'column:leaf:2',
            'distance': 0,
            'memberIndices': [2],
            'leafIndex': 2,
          }),
          sourceLabels: const ['Alpha', 'Beta'],
          axis: HeatmapDendrogramAxis.columns,
        ),
        throwsArgumentError,
      );
    });
  });
}

HeatmapClusterNode _root({
  required double distance,
  double childDistance = 2,
}) => HeatmapClusterNode.fromJson({
  'id': 'column:0,1,2',
  'distance': distance,
  'memberIndices': [0, 1, 2],
  'left': {
    'id': 'column:0,1',
    'distance': childDistance,
    'memberIndices': [0, 1],
    'left': {
      'id': 'column:leaf:0',
      'distance': 0,
      'memberIndices': [0],
      'leafIndex': 0,
    },
    'right': {
      'id': 'column:leaf:1',
      'distance': 0,
      'memberIndices': [1],
      'leafIndex': 1,
    },
  },
  'right': {
    'id': 'column:leaf:2',
    'distance': 0,
    'memberIndices': [2],
    'leafIndex': 2,
  },
});
