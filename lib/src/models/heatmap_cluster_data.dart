// Copyright 2026 Braven Charts contributors
// SPDX-License-Identifier: MIT

import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import 'heatmap_data_point.dart';

/// Matrix dimensions transformed by [HeatmapMatrixClusterData].
enum HeatmapClusterAxisMode {
  /// Preserve the source order on both axes.
  none,

  /// Cluster rows while preserving source column order.
  rows,

  /// Cluster columns while preserving source row order.
  columns,

  /// Cluster rows and columns independently.
  both,
}

/// Distance measure used to compare Heatmap rows or columns.
enum HeatmapClusterDistance {
  /// Root-sum-square distance, corrected for ignored missing dimensions.
  euclidean,

  /// One minus Pearson correlation, in the inclusive `0..2` range.
  correlation,
}

/// Linkage used to compare two groups during agglomerative clustering.
enum HeatmapClusterLinkage {
  /// Mean distance across every member pair.
  average,

  /// Largest distance across every member pair.
  complete,

  /// Smallest distance across every member pair.
  single,
}

/// How explicitly missing Heatmap cells contribute to vector distances.
enum HeatmapClusterMissingValueMode {
  /// Compare only dimensions measured in both vectors.
  pairwiseIgnore,

  /// Substitute zero for every missing cell.
  zero,
}

/// Immutable configuration for deterministic matrix clustering.
@immutable
final class HeatmapClusterConfig {
  const HeatmapClusterConfig({
    this.axisMode = HeatmapClusterAxisMode.both,
    this.distance = HeatmapClusterDistance.correlation,
    this.linkage = HeatmapClusterLinkage.average,
    this.missingValueMode = HeatmapClusterMissingValueMode.pairwiseIgnore,
  });

  final HeatmapClusterAxisMode axisMode;
  final HeatmapClusterDistance distance;
  final HeatmapClusterLinkage linkage;
  final HeatmapClusterMissingValueMode missingValueMode;

  bool get clustersRows =>
      axisMode == HeatmapClusterAxisMode.rows ||
      axisMode == HeatmapClusterAxisMode.both;

  bool get clustersColumns =>
      axisMode == HeatmapClusterAxisMode.columns ||
      axisMode == HeatmapClusterAxisMode.both;

  Map<String, dynamic> toJson() => {
    'axisMode': axisMode.name,
    'distance': distance.name,
    'linkage': linkage.name,
    'missingValueMode': missingValueMode.name,
  };

  @override
  bool operator ==(Object other) =>
      other is HeatmapClusterConfig &&
      other.axisMode == axisMode &&
      other.distance == distance &&
      other.linkage == linkage &&
      other.missingValueMode == missingValueMode;

  @override
  int get hashCode =>
      Object.hash(axisMode, distance, linkage, missingValueMode);
}

/// One stable node in a row or column clustering hierarchy.
///
/// Leaf nodes expose [leafIndex]. Branch nodes expose [left] and [right].
/// [memberIndices] always refers to original source-category indices.
@immutable
final class HeatmapClusterNode {
  const HeatmapClusterNode._({
    required this.id,
    required this.distance,
    required this.memberIndices,
    required this.leafIndex,
    required this.left,
    required this.right,
  });

  factory HeatmapClusterNode.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final distance = json['distance'];
    final members = json['memberIndices'];
    final leafIndex = json['leafIndex'];
    final left = json['left'];
    final right = json['right'];
    if (id is! String ||
        id.isEmpty ||
        distance is! num ||
        members is! List ||
        members.any((value) => value is! int) ||
        leafIndex != null && leafIndex is! int ||
        left != null && left is! Map ||
        right != null && right is! Map) {
      throw const FormatException('Invalid Heatmap cluster node');
    }
    final node = HeatmapClusterNode._(
      id: id,
      distance: distance.toDouble(),
      memberIndices: List<int>.unmodifiable(members.cast<int>()),
      leafIndex: leafIndex as int?,
      left: left == null
          ? null
          : HeatmapClusterNode.fromJson(Map<String, dynamic>.from(left)),
      right: right == null
          ? null
          : HeatmapClusterNode.fromJson(Map<String, dynamic>.from(right)),
    );
    node._validate();
    return node;
  }

  final String id;
  final double distance;
  final List<int> memberIndices;
  final int? leafIndex;
  final HeatmapClusterNode? left;
  final HeatmapClusterNode? right;

  bool get isLeaf => leafIndex != null;

  /// Stable left-to-right source-category order represented by this subtree.
  List<int> get leafOrder => isLeaf
      ? List<int>.unmodifiable([leafIndex!])
      : List<int>.unmodifiable([...left!.leafOrder, ...right!.leafOrder]);

  Map<String, dynamic> toJson() => {
    'id': id,
    'distance': distance,
    'memberIndices': memberIndices,
    if (leafIndex != null) 'leafIndex': leafIndex,
    if (left != null) 'left': left!.toJson(),
    if (right != null) 'right': right!.toJson(),
  };

  void _validate() {
    if (id.isEmpty ||
        !distance.isFinite ||
        distance < 0 ||
        memberIndices.isEmpty) {
      throw const FormatException('Invalid Heatmap cluster node values');
    }
    for (var index = 1; index < memberIndices.length; index++) {
      if (memberIndices[index] <= memberIndices[index - 1]) {
        throw const FormatException(
          'Heatmap cluster member indices must be strictly increasing',
        );
      }
    }
    if (isLeaf) {
      if (left != null ||
          right != null ||
          memberIndices.length != 1 ||
          memberIndices.single != leafIndex) {
        throw const FormatException('Invalid Heatmap cluster leaf');
      }
    } else if (left == null || right == null) {
      throw const FormatException(
        'Heatmap cluster branch requires two children',
      );
    }
  }
}

/// Deterministic row/column clustering prepared for the native Heatmap.
///
/// The transform changes category positions only. Every output cell keeps its
/// original logical identity and records its source and reordered coordinates
/// in metadata.
@immutable
final class HeatmapMatrixClusterData {
  factory HeatmapMatrixClusterData({
    required Iterable<HeatmapDataPoint> cells,
    required List<String> rowLabels,
    required List<String> columnLabels,
    HeatmapClusterConfig config = const HeatmapClusterConfig(),
  }) {
    _validateLabels(rowLabels, 'rowLabels');
    _validateLabels(columnLabels, 'columnLabels');
    if (rowLabels.isEmpty || columnLabels.isEmpty) {
      throw ArgumentError(
        'Heatmap clustering requires at least one row and one column',
      );
    }

    final sourceCells = List<HeatmapDataPoint>.unmodifiable(cells);
    final expectedCellCount = rowLabels.length * columnLabels.length;
    if (sourceCells.length != expectedCellCount) {
      throw ArgumentError.value(
        sourceCells.length,
        'cells',
        'must contain exactly $expectedCellCount rectangular matrix cells',
      );
    }

    final matrix = List<List<HeatmapDataPoint?>>.generate(
      rowLabels.length,
      (_) => List<HeatmapDataPoint?>.filled(columnLabels.length, null),
    );
    final identities = <Object>{};
    for (var index = 0; index < sourceCells.length; index++) {
      final cell = sourceCells[index];
      final column = _categoryIndex(
        cell.x,
        count: columnLabels.length,
        parameterName: 'cells[$index].x',
      );
      final row = _categoryIndex(
        cell.y,
        count: rowLabels.length,
        parameterName: 'cells[$index].y',
      );
      if (matrix[row][column] != null) {
        throw ArgumentError.value(
          '($column, $row)',
          'cells[$index]',
          'duplicates an existing matrix coordinate',
        );
      }
      if (!identities.add(cell.identity)) {
        throw ArgumentError.value(
          cell.identity,
          'cells[$index]',
          'duplicates an existing Heatmap cell identity',
        );
      }
      matrix[row][column] = cell;
    }

    final completeMatrix = List<List<HeatmapDataPoint>>.unmodifiable([
      for (var row = 0; row < matrix.length; row++)
        List<HeatmapDataPoint>.unmodifiable([
          for (var column = 0; column < matrix[row].length; column++)
            matrix[row][column]!,
        ]),
    ]);
    final rowVectors = [
      for (final row in completeMatrix)
        [for (final cell in row) cell.isMissing ? null : cell.value],
    ];
    final columnVectors = [
      for (var column = 0; column < columnLabels.length; column++)
        [
          for (var row = 0; row < rowLabels.length; row++)
            completeMatrix[row][column].isMissing
                ? null
                : completeMatrix[row][column].value,
        ],
    ];

    final rowRoot = config.clustersRows
        ? _cluster(
            rowVectors,
            axisId: 'row',
            distance: config.distance,
            linkage: config.linkage,
            missingValueMode: config.missingValueMode,
          )
        : null;
    final columnRoot = config.clustersColumns
        ? _cluster(
            columnVectors,
            axisId: 'column',
            distance: config.distance,
            linkage: config.linkage,
            missingValueMode: config.missingValueMode,
          )
        : null;
    final rowOrder =
        rowRoot?.leafOrder ??
        List<int>.generate(rowLabels.length, (index) => index);
    final columnOrder =
        columnRoot?.leafOrder ??
        List<int>.generate(columnLabels.length, (index) => index);
    final rowPositions = {
      for (var index = 0; index < rowOrder.length; index++)
        rowOrder[index]: index,
    };
    final columnPositions = {
      for (var index = 0; index < columnOrder.length; index++)
        columnOrder[index]: index,
    };

    final reorderedCells = <HeatmapDataPoint>[];
    for (final sourceRow in rowOrder) {
      for (final sourceColumn in columnOrder) {
        final cell = completeMatrix[sourceRow][sourceColumn];
        reorderedCells.add(
          cell.copyWith(
            x: columnPositions[sourceColumn]!.toDouble(),
            y: rowPositions[sourceRow]!.toDouble(),
            metadata: {
              ...?cell.metadata,
              'heatmapClusterSourceRowIndex': sourceRow,
              'heatmapClusterSourceColumnIndex': sourceColumn,
              'heatmapClusterSourceRowLabel': rowLabels[sourceRow],
              'heatmapClusterSourceColumnLabel': columnLabels[sourceColumn],
              'heatmapClusterRowIndex': rowPositions[sourceRow],
              'heatmapClusterColumnIndex': columnPositions[sourceColumn],
            },
          ),
        );
      }
    }

    return HeatmapMatrixClusterData._(
      sourceCells: sourceCells,
      sourceRowLabels: List<String>.unmodifiable(rowLabels),
      sourceColumnLabels: List<String>.unmodifiable(columnLabels),
      config: config,
      rowOrder: List<int>.unmodifiable(rowOrder),
      columnOrder: List<int>.unmodifiable(columnOrder),
      rowRoot: rowRoot,
      columnRoot: columnRoot,
      cells: List<HeatmapDataPoint>.unmodifiable(reorderedCells),
    );
  }

  const HeatmapMatrixClusterData._({
    required this.sourceCells,
    required this.sourceRowLabels,
    required this.sourceColumnLabels,
    required this.config,
    required this.rowOrder,
    required this.columnOrder,
    required this.rowRoot,
    required this.columnRoot,
    required this.cells,
  });

  final List<HeatmapDataPoint> sourceCells;
  final List<String> sourceRowLabels;
  final List<String> sourceColumnLabels;
  final HeatmapClusterConfig config;
  final List<int> rowOrder;
  final List<int> columnOrder;
  final HeatmapClusterNode? rowRoot;
  final HeatmapClusterNode? columnRoot;
  final List<HeatmapDataPoint> cells;

  List<String> get rowLabels => List<String>.unmodifiable([
    for (final index in rowOrder) sourceRowLabels[index],
  ]);

  List<String> get columnLabels => List<String>.unmodifiable([
    for (final index in columnOrder) sourceColumnLabels[index],
  ]);

  /// JSON-safe transform metadata suitable for series and artifact metadata.
  Map<String, dynamic> get metadata => {
    'heatmapClusterConfig': config.toJson(),
    'heatmapClusterRowOrder': rowOrder,
    'heatmapClusterColumnOrder': columnOrder,
    if (rowRoot != null) 'heatmapClusterRowHierarchy': rowRoot!.toJson(),
    if (columnRoot != null)
      'heatmapClusterColumnHierarchy': columnRoot!.toJson(),
  };

  static void _validateLabels(List<String> labels, String parameterName) {
    final identities = <String>{};
    for (var index = 0; index < labels.length; index++) {
      final label = labels[index];
      if (label.isEmpty) {
        throw ArgumentError.value(
          label,
          '$parameterName[$index]',
          'must not be empty',
        );
      }
      if (!identities.add(label)) {
        throw ArgumentError.value(
          label,
          '$parameterName[$index]',
          'duplicates an existing category label',
        );
      }
    }
  }

  static int _categoryIndex(
    double value, {
    required int count,
    required String parameterName,
  }) {
    final index = value.round();
    if (!value.isFinite || (value - index).abs() > 0.000001) {
      throw ArgumentError.value(
        value,
        parameterName,
        'must be a finite integer category centre',
      );
    }
    if (index < 0 || index >= count) {
      throw ArgumentError.value(
        value,
        parameterName,
        'falls outside the declared category domain',
      );
    }
    return index;
  }
}

/// A fixed, pre-layout view over an accepted clustered Heatmap matrix.
///
/// Focus is expressed by stable hierarchy node IDs. The selected row and
/// column subtrees keep their accepted leaf order; no distances are recomputed
/// and no source cells are reclustered. Output cells are reindexed to a local
/// zero-based matrix while retaining their original source and clustered
/// coordinates in metadata.
///
/// This transform is suitable for host-composed dendrogram layouts whose
/// matrix, labels, and trees must share one locked category window.
@immutable
final class HeatmapMatrixClusterFocusData {
  factory HeatmapMatrixClusterFocusData({
    required HeatmapMatrixClusterData source,
    String? rowRootId,
    String? columnRootId,
  }) {
    final rowRoot = _resolveFocusRoot(
      source.rowRoot,
      rowRootId,
      parameterName: 'rowRootId',
    );
    final columnRoot = _resolveFocusRoot(
      source.columnRoot,
      columnRootId,
      parameterName: 'columnRootId',
    );
    final rowOrder = rowRoot?.leafOrder ?? source.rowOrder;
    final columnOrder = columnRoot?.leafOrder ?? source.columnOrder;
    final cellsBySourceCoordinate = <(int, int), HeatmapDataPoint>{};
    for (final cell in source.cells) {
      final metadata = cell.metadata;
      final sourceRow = metadata?['heatmapClusterSourceRowIndex'];
      final sourceColumn = metadata?['heatmapClusterSourceColumnIndex'];
      if (sourceRow is! int || sourceColumn is! int) {
        throw StateError(
          'Clustered Heatmap cells must retain source row and column indices',
        );
      }
      cellsBySourceCoordinate[(sourceRow, sourceColumn)] = cell;
    }

    final focusedCells = <HeatmapDataPoint>[];
    for (var row = 0; row < rowOrder.length; row++) {
      for (var column = 0; column < columnOrder.length; column++) {
        final sourceRow = rowOrder[row];
        final sourceColumn = columnOrder[column];
        final sourceCell = cellsBySourceCoordinate[(sourceRow, sourceColumn)]!;
        focusedCells.add(
          sourceCell.copyWith(
            x: column.toDouble(),
            y: row.toDouble(),
            metadata: {
              ...?sourceCell.metadata,
              'heatmapClusterFocusRowIndex': row,
              'heatmapClusterFocusColumnIndex': column,
            },
          ),
        );
      }
    }

    return HeatmapMatrixClusterFocusData._(
      source: source,
      rowRootId: rowRootId,
      columnRootId: columnRootId,
      rowRoot: rowRoot,
      columnRoot: columnRoot,
      rowOrder: List<int>.unmodifiable(rowOrder),
      columnOrder: List<int>.unmodifiable(columnOrder),
      cells: List<HeatmapDataPoint>.unmodifiable(focusedCells),
    );
  }

  const HeatmapMatrixClusterFocusData._({
    required this.source,
    required this.rowRootId,
    required this.columnRootId,
    required this.rowRoot,
    required this.columnRoot,
    required this.rowOrder,
    required this.columnOrder,
    required this.cells,
  });

  /// Complete accepted clustering from which this view was derived.
  final HeatmapMatrixClusterData source;

  /// Selected row subtree identity, or null for the complete accepted row set.
  final String? rowRootId;

  /// Selected column subtree identity, or null for the complete column set.
  final String? columnRootId;

  /// Selected row hierarchy root, when row clustering exists.
  final HeatmapClusterNode? rowRoot;

  /// Selected column hierarchy root, when column clustering exists.
  final HeatmapClusterNode? columnRoot;

  /// Original source-row indices in focused display order.
  final List<int> rowOrder;

  /// Original source-column indices in focused display order.
  final List<int> columnOrder;

  /// Focused, locally reindexed cells in row-major order.
  final List<HeatmapDataPoint> cells;

  List<String> get rowLabels => List<String>.unmodifiable([
    for (final index in rowOrder) source.sourceRowLabels[index],
  ]);

  List<String> get columnLabels => List<String>.unmodifiable([
    for (final index in columnOrder) source.sourceColumnLabels[index],
  ]);

  /// JSON-safe focus metadata suitable for series and chart artifacts.
  Map<String, dynamic> get metadata => {
    'heatmapClusterFocusRowOrder': rowOrder,
    'heatmapClusterFocusColumnOrder': columnOrder,
    if (rowRootId != null) 'heatmapClusterFocusRowRootId': rowRootId,
    if (columnRootId != null) 'heatmapClusterFocusColumnRootId': columnRootId,
  };
}

HeatmapClusterNode? _resolveFocusRoot(
  HeatmapClusterNode? sourceRoot,
  String? focusRootId, {
  required String parameterName,
}) {
  if (focusRootId == null) return sourceRoot;
  final resolved = _findClusterNode(sourceRoot, focusRootId);
  if (resolved == null) {
    throw ArgumentError.value(
      focusRootId,
      parameterName,
      'must identify a node in the accepted hierarchy',
    );
  }
  return resolved;
}

HeatmapClusterNode? _findClusterNode(
  HeatmapClusterNode? node,
  String targetId,
) {
  if (node == null || node.id == targetId) return node;
  return _findClusterNode(node.left, targetId) ??
      _findClusterNode(node.right, targetId);
}

HeatmapClusterNode _cluster(
  List<List<double?>> vectors, {
  required String axisId,
  required HeatmapClusterDistance distance,
  required HeatmapClusterLinkage linkage,
  required HeatmapClusterMissingValueMode missingValueMode,
}) {
  final leafDistances = List<List<double>>.generate(
    vectors.length,
    (left) => List<double>.generate(
      vectors.length,
      (right) => left == right
          ? 0
          : _vectorDistance(
              vectors[left],
              vectors[right],
              distance: distance,
              missingValueMode: missingValueMode,
            ),
    ),
  );
  final clusters = <_WorkingHeatmapCluster>[
    for (var index = 0; index < vectors.length; index++)
      _WorkingHeatmapCluster(
        node: HeatmapClusterNode._(
          id: '$axisId:leaf:$index',
          distance: 0,
          memberIndices: List<int>.unmodifiable([index]),
          leafIndex: index,
          left: null,
          right: null,
        ),
        members: [index],
      ),
  ];

  while (clusters.length > 1) {
    var bestLeft = 0;
    var bestRight = 1;
    var bestDistance = _linkageDistance(
      clusters[0].members,
      clusters[1].members,
      leafDistances,
      linkage,
    );
    for (var left = 0; left < clusters.length - 1; left++) {
      for (var right = left + 1; right < clusters.length; right++) {
        final candidateDistance = _linkageDistance(
          clusters[left].members,
          clusters[right].members,
          leafDistances,
          linkage,
        );
        final comparison = _compareClusterPair(
          candidateDistance,
          clusters[left],
          clusters[right],
          bestDistance,
          clusters[bestLeft],
          clusters[bestRight],
        );
        if (comparison < 0) {
          bestLeft = left;
          bestRight = right;
          bestDistance = candidateDistance;
        }
      }
    }

    var leftCluster = clusters[bestLeft];
    var rightCluster = clusters[bestRight];
    if (leftCluster.minimumMember > rightCluster.minimumMember) {
      final temporary = leftCluster;
      leftCluster = rightCluster;
      rightCluster = temporary;
    }
    final members = <int>[...leftCluster.members, ...rightCluster.members]
      ..sort();
    final merged = _WorkingHeatmapCluster(
      node: HeatmapClusterNode._(
        id: '$axisId:${members.join(",")}',
        distance: bestDistance,
        memberIndices: List<int>.unmodifiable(members),
        leafIndex: null,
        left: leftCluster.node,
        right: rightCluster.node,
      ),
      members: members,
    );
    clusters.removeAt(bestRight);
    clusters.removeAt(bestLeft);
    clusters.add(merged);
    clusters.sort(
      (left, right) => left.minimumMember.compareTo(right.minimumMember),
    );
  }
  return clusters.single.node;
}

double _vectorDistance(
  List<double?> left,
  List<double?> right, {
  required HeatmapClusterDistance distance,
  required HeatmapClusterMissingValueMode missingValueMode,
}) {
  assert(left.length == right.length);
  final leftValues = <double>[];
  final rightValues = <double>[];
  for (var index = 0; index < left.length; index++) {
    final leftValue = left[index];
    final rightValue = right[index];
    if (missingValueMode == HeatmapClusterMissingValueMode.pairwiseIgnore &&
        (leftValue == null || rightValue == null)) {
      continue;
    }
    leftValues.add(leftValue ?? 0);
    rightValues.add(rightValue ?? 0);
  }
  if (leftValues.isEmpty) return 1e308;

  return switch (distance) {
    HeatmapClusterDistance.euclidean => _euclideanDistance(
      leftValues,
      rightValues,
      sourceDimensionCount: left.length,
      scalesIgnoredDimensions:
          missingValueMode == HeatmapClusterMissingValueMode.pairwiseIgnore,
    ),
    HeatmapClusterDistance.correlation => _correlationDistance(
      leftValues,
      rightValues,
    ),
  };
}

double _euclideanDistance(
  List<double> left,
  List<double> right, {
  required int sourceDimensionCount,
  required bool scalesIgnoredDimensions,
}) {
  var squaredDistance = 0.0;
  for (var index = 0; index < left.length; index++) {
    final difference = left[index] - right[index];
    squaredDistance += difference * difference;
  }
  if (scalesIgnoredDimensions) {
    squaredDistance *= sourceDimensionCount / left.length;
  }
  return math.sqrt(squaredDistance);
}

double _correlationDistance(List<double> left, List<double> right) {
  final leftMean = left.reduce((a, b) => a + b) / left.length;
  final rightMean = right.reduce((a, b) => a + b) / right.length;
  var covariance = 0.0;
  var leftVariance = 0.0;
  var rightVariance = 0.0;
  for (var index = 0; index < left.length; index++) {
    final leftDelta = left[index] - leftMean;
    final rightDelta = right[index] - rightMean;
    covariance += leftDelta * rightDelta;
    leftVariance += leftDelta * leftDelta;
    rightVariance += rightDelta * rightDelta;
  }
  if (leftVariance == 0 || rightVariance == 0) {
    return listEquals(left, right) ? 0 : 1;
  }
  final correlation = covariance / math.sqrt(leftVariance * rightVariance);
  return (1 - correlation).clamp(0.0, 2.0);
}

double _linkageDistance(
  List<int> left,
  List<int> right,
  List<List<double>> leafDistances,
  HeatmapClusterLinkage linkage,
) {
  var result = switch (linkage) {
    HeatmapClusterLinkage.average => 0.0,
    HeatmapClusterLinkage.complete => 0.0,
    HeatmapClusterLinkage.single => double.infinity,
  };
  var count = 0;
  for (final leftIndex in left) {
    for (final rightIndex in right) {
      final value = leafDistances[leftIndex][rightIndex];
      switch (linkage) {
        case HeatmapClusterLinkage.average:
          count++;
          result += (value - result) / count;
        case HeatmapClusterLinkage.complete:
          if (value > result) result = value;
        case HeatmapClusterLinkage.single:
          if (value < result) result = value;
      }
    }
  }
  return result;
}

int _compareClusterPair(
  double candidateDistance,
  _WorkingHeatmapCluster candidateLeft,
  _WorkingHeatmapCluster candidateRight,
  double bestDistance,
  _WorkingHeatmapCluster bestLeft,
  _WorkingHeatmapCluster bestRight,
) {
  final distanceComparison = candidateDistance.compareTo(bestDistance);
  if (distanceComparison != 0) return distanceComparison;
  final candidateMinimum = candidateLeft.minimumMember;
  final bestMinimum = bestLeft.minimumMember;
  if (candidateMinimum != bestMinimum) {
    return candidateMinimum.compareTo(bestMinimum);
  }
  return candidateRight.minimumMember.compareTo(bestRight.minimumMember);
}

final class _WorkingHeatmapCluster {
  const _WorkingHeatmapCluster({required this.node, required this.members});

  final HeatmapClusterNode node;
  final List<int> members;

  int get minimumMember => members.first;
}
