// Copyright 2026 Braven Charts contributors
// SPDX-License-Identifier: MIT

import 'package:flutter/foundation.dart';

import 'heatmap_cluster_data.dart';
import 'heatmap_data_point.dart';

/// Reduction applied when a visible hierarchy terminal represents more than
/// one source row or column.
enum HeatmapHierarchyReducer {
  /// Arithmetic mean of every measured source cell in the visible group.
  mean,

  /// Sum of every measured source cell in the visible group.
  sum,

  /// Lowest measured source value in the visible group.
  minimum,

  /// Highest measured source value in the visible group.
  maximum,
}

/// Durable collapse state for one accepted Heatmap hierarchy.
///
/// The state stores stable clustering node IDs only. It is deliberately
/// independent from hover, keyboard focus, and hierarchy inspection selection.
/// A [HeatmapHierarchyProjection] resolves the IDs against the current source
/// tree and reports any stale or leaf IDs without mutating this state.
@immutable
final class HeatmapHierarchyCollapseState {
  const HeatmapHierarchyCollapseState.empty()
    : collapsedNodeIds = const <String>{};

  HeatmapHierarchyCollapseState({Iterable<String> collapsedNodeIds = const []})
    : collapsedNodeIds = Set<String>.unmodifiable(
        collapsedNodeIds.where((id) => id.isNotEmpty),
      );

  factory HeatmapHierarchyCollapseState.fromJson(Map<String, dynamic> json) {
    final ids = json['collapsedNodeIds'];
    if (ids is! List || ids.any((value) => value is! String)) {
      throw const FormatException('Invalid Heatmap hierarchy collapse state');
    }
    return HeatmapHierarchyCollapseState(collapsedNodeIds: ids.cast<String>());
  }

  final Set<String> collapsedNodeIds;

  bool isCollapsed(String nodeId) => collapsedNodeIds.contains(nodeId);

  HeatmapHierarchyCollapseState collapse(String nodeId) {
    if (nodeId.isEmpty || collapsedNodeIds.contains(nodeId)) return this;
    return HeatmapHierarchyCollapseState(
      collapsedNodeIds: {...collapsedNodeIds, nodeId},
    );
  }

  HeatmapHierarchyCollapseState expand(String nodeId) {
    if (!collapsedNodeIds.contains(nodeId)) return this;
    return HeatmapHierarchyCollapseState(
      collapsedNodeIds: collapsedNodeIds.where((id) => id != nodeId),
    );
  }

  HeatmapHierarchyCollapseState toggle(String nodeId) =>
      isCollapsed(nodeId) ? expand(nodeId) : collapse(nodeId);

  HeatmapHierarchyCollapseState clear() => collapsedNodeIds.isEmpty
      ? this
      : const HeatmapHierarchyCollapseState.empty();

  Map<String, dynamic> toJson() => {
    'collapsedNodeIds': collapsedNodeIds.toList()..sort(),
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HeatmapHierarchyCollapseState &&
          setEquals(other.collapsedNodeIds, collapsedNodeIds);

  @override
  int get hashCode => Object.hashAll(collapsedNodeIds.toList()..sort());
}

/// One visible terminal in a collapsed Heatmap hierarchy projection.
///
/// A terminal is either one original source leaf or one explicitly collapsed
/// merge node. [sourceIndices] always retain accepted left-to-right hierarchy
/// order so the host can reduce matrix rows or columns without reclustering.
@immutable
final class HeatmapHierarchyVisibleGroup {
  const HeatmapHierarchyVisibleGroup({
    required this.nodeId,
    required this.label,
    required this.sourceIndices,
    required this.mergeDistance,
    required this.isCollapsed,
  });

  factory HeatmapHierarchyVisibleGroup.fromJson(Map<String, dynamic> json) {
    final nodeId = json['nodeId'];
    final label = json['label'];
    final sourceIndices = json['sourceIndices'];
    final mergeDistance = json['mergeDistance'];
    final isCollapsed = json['isCollapsed'];
    if (nodeId is! String ||
        nodeId.isEmpty ||
        label is! String ||
        label.isEmpty ||
        sourceIndices is! List ||
        sourceIndices.isEmpty ||
        sourceIndices.any((value) => value is! int || value < 0) ||
        sourceIndices.toSet().length != sourceIndices.length ||
        mergeDistance is! num ||
        !mergeDistance.isFinite ||
        mergeDistance < 0 ||
        isCollapsed is! bool) {
      throw const FormatException('Invalid Heatmap hierarchy visible group');
    }
    return HeatmapHierarchyVisibleGroup(
      nodeId: nodeId,
      label: label,
      sourceIndices: List<int>.unmodifiable(sourceIndices.cast<int>()),
      mergeDistance: mergeDistance.toDouble(),
      isCollapsed: isCollapsed,
    );
  }

  final String nodeId;
  final String label;
  final List<int> sourceIndices;
  final double mergeDistance;
  final bool isCollapsed;

  bool get isSourceLeaf => sourceIndices.length == 1 && !isCollapsed;

  Map<String, dynamic> toJson() => {
    'nodeId': nodeId,
    'label': label,
    'sourceIndices': sourceIndices,
    'mergeDistance': mergeDistance,
    'isCollapsed': isCollapsed,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HeatmapHierarchyVisibleGroup &&
          other.nodeId == nodeId &&
          other.label == label &&
          listEquals(other.sourceIndices, sourceIndices) &&
          other.mergeDistance == mergeDistance &&
          other.isCollapsed == isCollapsed;

  @override
  int get hashCode => Object.hash(
    nodeId,
    label,
    Object.hashAll(sourceIndices),
    mergeDistance,
    isCollapsed,
  );
}

/// Immutable visible-leaf projection over an accepted clustering hierarchy.
///
/// This model does not aggregate matrix values. It tells the host exactly which
/// source rows or columns belong to each visible group; the host chooses an
/// explicit reducer appropriate to its domain. The source hierarchy and its
/// accepted order are never modified or recomputed.
@immutable
final class HeatmapHierarchyProjection {
  factory HeatmapHierarchyProjection({
    required HeatmapClusterNode root,
    required List<String> sourceLabels,
    HeatmapHierarchyCollapseState collapseState =
        const HeatmapHierarchyCollapseState.empty(),
    Map<String, String> collapsedLabels = const {},
  }) {
    if (sourceLabels.isEmpty || sourceLabels.any((label) => label.isEmpty)) {
      throw ArgumentError.value(
        sourceLabels,
        'sourceLabels',
        'must contain non-empty labels',
      );
    }
    if (root.memberIndices.any(
      (index) => index < 0 || index >= sourceLabels.length,
    )) {
      throw ArgumentError(
        'Heatmap hierarchy members must belong to the source-label set',
      );
    }

    final knownNodeIds = <String>{};
    final visibleGroups = <HeatmapHierarchyVisibleGroup>[];
    final activeCollapsedNodeIds = <String>{};

    void visit(HeatmapClusterNode node) {
      knownNodeIds.add(node.id);
      final isCollapsed = !node.isLeaf && collapseState.isCollapsed(node.id);
      if (node.isLeaf || isCollapsed) {
        final indices = List<int>.unmodifiable(node.leafOrder);
        visibleGroups.add(
          HeatmapHierarchyVisibleGroup(
            nodeId: node.id,
            label: node.isLeaf
                ? sourceLabels[node.leafIndex!]
                : collapsedLabels[node.id] ??
                      _defaultCollapsedLabel(indices, sourceLabels),
            sourceIndices: indices,
            mergeDistance: node.distance,
            isCollapsed: isCollapsed,
          ),
        );
        if (isCollapsed) activeCollapsedNodeIds.add(node.id);
        _collectNodeIds(node.left, knownNodeIds);
        _collectNodeIds(node.right, knownNodeIds);
        return;
      }
      visit(node.left!);
      visit(node.right!);
    }

    visit(root);
    final ignoredCollapsedNodeIds = collapseState.collapsedNodeIds
        .where((id) => !activeCollapsedNodeIds.contains(id))
        .toSet();

    return HeatmapHierarchyProjection._(
      root: root,
      sourceLabels: List<String>.unmodifiable(sourceLabels),
      collapseState: collapseState,
      visibleGroups: List<HeatmapHierarchyVisibleGroup>.unmodifiable(
        visibleGroups,
      ),
      activeCollapsedNodeIds: Set<String>.unmodifiable(activeCollapsedNodeIds),
      ignoredCollapsedNodeIds: Set<String>.unmodifiable(
        ignoredCollapsedNodeIds,
      ),
      knownNodeIds: Set<String>.unmodifiable(knownNodeIds),
    );
  }

  const HeatmapHierarchyProjection._({
    required this.root,
    required this.sourceLabels,
    required this.collapseState,
    required this.visibleGroups,
    required this.activeCollapsedNodeIds,
    required this.ignoredCollapsedNodeIds,
    required this.knownNodeIds,
  });

  final HeatmapClusterNode root;
  final List<String> sourceLabels;
  final HeatmapHierarchyCollapseState collapseState;
  final List<HeatmapHierarchyVisibleGroup> visibleGroups;
  final Set<String> activeCollapsedNodeIds;

  /// IDs not currently represented as visible collapsed merge nodes.
  ///
  /// This includes stale IDs, leaf IDs, and nested collapsed nodes hidden by a
  /// collapsed ancestor. The durable state retains them so expanding an
  /// ancestor restores the prior nested structure.
  final Set<String> ignoredCollapsedNodeIds;
  final Set<String> knownNodeIds;

  List<int> get sourceOrder => List<int>.unmodifiable([
    for (final group in visibleGroups) ...group.sourceIndices,
  ]);

  bool containsNode(String nodeId) => knownNodeIds.contains(nodeId);

  Map<String, dynamic> toJson() => {
    'collapseState': collapseState.toJson(),
    'visibleGroups': [for (final group in visibleGroups) group.toJson()],
    'activeCollapsedNodeIds': activeCollapsedNodeIds.toList()..sort(),
    'ignoredCollapsedNodeIds': ignoredCollapsedNodeIds.toList()..sort(),
  };
}

/// Immutable matrix projection derived from row and column hierarchy state.
///
/// This is a host-side preparation model: it never mutates the source
/// hierarchy, reclusters data, or changes retained renderer ownership. Every
/// visible cell records its complete source row and column membership so
/// tooltips, tables, artifacts, and generated source retain provenance after
/// aggregation.
@immutable
final class HeatmapHierarchyMatrixProjection {
  factory HeatmapHierarchyMatrixProjection({
    required HeatmapMatrixClusterFocusData source,
    HeatmapHierarchyCollapseState rowCollapseState =
        const HeatmapHierarchyCollapseState.empty(),
    HeatmapHierarchyCollapseState columnCollapseState =
        const HeatmapHierarchyCollapseState.empty(),
    HeatmapHierarchyReducer reducer = HeatmapHierarchyReducer.mean,
    Map<String, String> collapsedRowLabels = const {},
    Map<String, String> collapsedColumnLabels = const {},
  }) {
    final rowRoot = source.rowRoot;
    final columnRoot = source.columnRoot;
    final rowProjection = rowRoot == null
        ? null
        : HeatmapHierarchyProjection(
            root: rowRoot,
            sourceLabels: source.source.sourceRowLabels,
            collapseState: rowCollapseState,
            collapsedLabels: collapsedRowLabels,
          );
    final columnProjection = columnRoot == null
        ? null
        : HeatmapHierarchyProjection(
            root: columnRoot,
            sourceLabels: source.source.sourceColumnLabels,
            collapseState: columnCollapseState,
            collapsedLabels: collapsedColumnLabels,
          );
    final rowGroups =
        rowProjection?.visibleGroups ??
        [
          for (final sourceIndex in source.rowOrder)
            HeatmapHierarchyVisibleGroup(
              nodeId: 'row:leaf:$sourceIndex',
              label: source.source.sourceRowLabels[sourceIndex],
              sourceIndices: [sourceIndex],
              mergeDistance: 0,
              isCollapsed: false,
            ),
        ];
    final columnGroups =
        columnProjection?.visibleGroups ??
        [
          for (final sourceIndex in source.columnOrder)
            HeatmapHierarchyVisibleGroup(
              nodeId: 'column:leaf:$sourceIndex',
              label: source.source.sourceColumnLabels[sourceIndex],
              sourceIndices: [sourceIndex],
              mergeDistance: 0,
              isCollapsed: false,
            ),
        ];
    final sourceCells = <(int, int), HeatmapDataPoint>{};
    for (final cell in source.cells) {
      final sourceRow = cell.metadata?['heatmapClusterSourceRowIndex'];
      final sourceColumn = cell.metadata?['heatmapClusterSourceColumnIndex'];
      if (sourceRow is! int || sourceColumn is! int) {
        throw StateError(
          'Projected Heatmap cells must retain source row and column indices',
        );
      }
      sourceCells[(sourceRow, sourceColumn)] = cell;
    }

    final cells = <HeatmapDataPoint>[];
    for (var row = 0; row < rowGroups.length; row++) {
      final rowGroup = rowGroups[row];
      for (var column = 0; column < columnGroups.length; column++) {
        final columnGroup = columnGroups[column];
        final members = <HeatmapDataPoint>[];
        for (final sourceRow in rowGroup.sourceIndices) {
          for (final sourceColumn in columnGroup.sourceIndices) {
            final cell = sourceCells[(sourceRow, sourceColumn)];
            if (cell != null) members.add(cell);
          }
        }
        final measured = [
          for (final cell in members)
            if (!cell.isMissing) cell.value!,
        ];
        final metadata = <String, dynamic>{
          if (members.length == 1) ...?members.single.metadata,
          'heatmapHierarchyRowNodeId': rowGroup.nodeId,
          'heatmapHierarchyColumnNodeId': columnGroup.nodeId,
          'heatmapHierarchySourceRowIndices': rowGroup.sourceIndices,
          'heatmapHierarchySourceColumnIndices': columnGroup.sourceIndices,
          'heatmapHierarchySourceRowLabels': [
            for (final index in rowGroup.sourceIndices)
              source.source.sourceRowLabels[index],
          ],
          'heatmapHierarchySourceColumnLabels': [
            for (final index in columnGroup.sourceIndices)
              source.source.sourceColumnLabels[index],
          ],
          'heatmapHierarchySourcePointKeys': [
            for (final cell in members)
              if (cell.pointKey != null) cell.pointKey,
          ],
          'heatmapHierarchyReducer': reducer.name,
          'heatmapHierarchyMeasuredCellCount': measured.length,
          'heatmapHierarchySourceCellCount': members.length,
        };
        final pointKey = 'hierarchy:${rowGroup.nodeId}:${columnGroup.nodeId}';
        final label = '${rowGroup.label} · ${columnGroup.label}';
        cells.add(
          measured.isEmpty
              ? HeatmapDataPoint.missing(
                  x: column.toDouble(),
                  y: row.toDouble(),
                  pointKey: pointKey,
                  label: '$label · not measured',
                  metadata: metadata,
                )
              : HeatmapDataPoint(
                  x: column.toDouble(),
                  y: row.toDouble(),
                  value: _reduceHierarchyValues(measured, reducer),
                  pointKey: pointKey,
                  label: label,
                  metadata: metadata,
                ),
        );
      }
    }

    return HeatmapHierarchyMatrixProjection._(
      source: source,
      rowProjection: rowProjection,
      columnProjection: columnProjection,
      reducer: reducer,
      rowGroups: List<HeatmapHierarchyVisibleGroup>.unmodifiable(rowGroups),
      columnGroups: List<HeatmapHierarchyVisibleGroup>.unmodifiable(
        columnGroups,
      ),
      cells: List<HeatmapDataPoint>.unmodifiable(cells),
    );
  }

  const HeatmapHierarchyMatrixProjection._({
    required this.source,
    required this.rowProjection,
    required this.columnProjection,
    required this.reducer,
    required this.rowGroups,
    required this.columnGroups,
    required this.cells,
  });

  final HeatmapMatrixClusterFocusData source;
  final HeatmapHierarchyProjection? rowProjection;
  final HeatmapHierarchyProjection? columnProjection;
  final HeatmapHierarchyReducer reducer;
  final List<HeatmapHierarchyVisibleGroup> rowGroups;
  final List<HeatmapHierarchyVisibleGroup> columnGroups;
  final List<HeatmapDataPoint> cells;

  List<String> get rowLabels =>
      List<String>.unmodifiable(rowGroups.map((group) => group.label));

  List<String> get columnLabels =>
      List<String>.unmodifiable(columnGroups.map((group) => group.label));

  Map<String, dynamic> get metadata => {
    'heatmapHierarchyReducer': reducer.name,
    'heatmapHierarchyRowCollapseState':
        rowProjection?.collapseState.toJson() ??
        const HeatmapHierarchyCollapseState.empty().toJson(),
    'heatmapHierarchyColumnCollapseState':
        columnProjection?.collapseState.toJson() ??
        const HeatmapHierarchyCollapseState.empty().toJson(),
    'heatmapHierarchyRowGroups': [
      for (final group in rowGroups) group.toJson(),
    ],
    'heatmapHierarchyColumnGroups': [
      for (final group in columnGroups) group.toJson(),
    ],
  };
}

void _collectNodeIds(HeatmapClusterNode? node, Set<String> target) {
  if (node == null) return;
  target.add(node.id);
  _collectNodeIds(node.left, target);
  _collectNodeIds(node.right, target);
}

String _defaultCollapsedLabel(
  List<int> sourceIndices,
  List<String> sourceLabels,
) {
  final first = sourceLabels[sourceIndices.first];
  final remaining = sourceIndices.length - 1;
  return remaining == 0 ? first : '$first + $remaining';
}

double _reduceHierarchyValues(
  List<double> values,
  HeatmapHierarchyReducer reducer,
) => switch (reducer) {
  HeatmapHierarchyReducer.mean =>
    values.reduce((left, right) => left + right) / values.length,
  HeatmapHierarchyReducer.sum => values.reduce((left, right) => left + right),
  HeatmapHierarchyReducer.minimum => values.reduce(
    (left, right) => left < right ? left : right,
  ),
  HeatmapHierarchyReducer.maximum => values.reduce(
    (left, right) => left > right ? left : right,
  ),
};
