// Copyright 2026 Braven Charts contributors
// SPDX-License-Identifier: MIT

import 'package:flutter/foundation.dart';

import 'heatmap_cluster_data.dart';
import 'heatmap_hierarchy_projection.dart';

/// Matrix axis represented by a Heatmap dendrogram.
enum HeatmapDendrogramAxis {
  /// A hierarchy whose leaves correspond to matrix rows.
  rows,

  /// A hierarchy whose leaves correspond to matrix columns.
  columns,
}

/// Controls how hierarchy merge distance is mapped into branch extent.
enum HeatmapDendrogramDistanceScale {
  /// Preserves the clustering algorithm's proportional merge distances.
  ///
  /// This is the analytically faithful view, but close merge distances can
  /// compress several branches into a narrow band near the matrix.
  proportional,

  /// Spaces structural merge levels evenly from leaves to the root.
  ///
  /// This preserves hierarchy and leaf order while making dense trees easier
  /// to read. It does not change clustering, only branch presentation.
  structural,
}

/// One normalized line segment in a portable dendrogram layout.
///
/// `category` coordinates follow the accepted cluster leaf order. `distance`
/// coordinates run from zero at leaves to one at the root.
@immutable
final class HeatmapDendrogramSegment {
  const HeatmapDendrogramSegment({
    required this.id,
    required this.nodeId,
    required this.startCategory,
    required this.startDistance,
    required this.endCategory,
    required this.endDistance,
  });

  factory HeatmapDendrogramSegment.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final nodeId = json['nodeId'];
    final startCategory = json['startCategory'];
    final startDistance = json['startDistance'];
    final endCategory = json['endCategory'];
    final endDistance = json['endDistance'];
    if (id is! String ||
        id.isEmpty ||
        nodeId is! String ||
        nodeId.isEmpty ||
        startCategory is! num ||
        startDistance is! num ||
        endCategory is! num ||
        endDistance is! num) {
      throw const FormatException('Invalid Heatmap dendrogram segment');
    }
    final segment = HeatmapDendrogramSegment(
      id: id,
      nodeId: nodeId,
      startCategory: startCategory.toDouble(),
      startDistance: startDistance.toDouble(),
      endCategory: endCategory.toDouble(),
      endDistance: endDistance.toDouble(),
    );
    segment._validate();
    return segment;
  }

  final String id;
  final String nodeId;
  final double startCategory;
  final double startDistance;
  final double endCategory;
  final double endDistance;

  Map<String, dynamic> toJson() => {
    'id': id,
    'nodeId': nodeId,
    'startCategory': startCategory,
    'startDistance': startDistance,
    'endCategory': endCategory,
    'endDistance': endDistance,
  };

  void _validate() {
    final coordinates = [
      startCategory,
      startDistance,
      endCategory,
      endDistance,
    ];
    if (coordinates.any((value) => !value.isFinite || value < 0 || value > 1)) {
      throw const FormatException(
        'Heatmap dendrogram coordinates must be finite values from 0 to 1',
      );
    }
  }
}

/// One portable hierarchy-node anchor in a dendrogram layout.
///
/// [category] and [distance] use the same normalized coordinates as branch
/// segments. [mergeDistance] retains the clustering algorithm's original
/// distance even when the dendrogram uses structural spacing.
@immutable
final class HeatmapDendrogramNode {
  const HeatmapDendrogramNode({
    required this.id,
    required this.category,
    required this.distance,
    required this.mergeDistance,
    required this.memberCount,
    this.leafIndex,
    bool? isTerminal,
  }) : isTerminal = isTerminal ?? leafIndex != null;

  factory HeatmapDendrogramNode.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final category = json['category'];
    final distance = json['distance'];
    final mergeDistance = json['mergeDistance'];
    final memberCount = json['memberCount'];
    final leafIndex = json['leafIndex'];
    final isTerminal = json['isTerminal'];
    if (id is! String ||
        id.isEmpty ||
        category is! num ||
        distance is! num ||
        mergeDistance is! num ||
        memberCount is! int ||
        (leafIndex != null && leafIndex is! int) ||
        (isTerminal != null && isTerminal is! bool)) {
      throw const FormatException('Invalid Heatmap dendrogram node');
    }
    final node = HeatmapDendrogramNode(
      id: id,
      category: category.toDouble(),
      distance: distance.toDouble(),
      mergeDistance: mergeDistance.toDouble(),
      memberCount: memberCount,
      leafIndex: leafIndex as int?,
      isTerminal: isTerminal as bool?,
    );
    node._validate();
    return node;
  }

  /// Stable hierarchy-node identity.
  final String id;

  /// Normalized category-axis position.
  final double category;

  /// Normalized branch-distance position used by the current layout.
  final double distance;

  /// Original, unnormalized clustering distance.
  final double mergeDistance;

  /// Number of source leaves represented by this node.
  final int memberCount;

  /// Source-leaf index, or `null` when this is a merge node.
  final int? leafIndex;

  /// Whether this node is a visible terminal in the projected hierarchy.
  ///
  /// Original source leaves and explicitly collapsed merge nodes are both
  /// terminals. [isLeaf] distinguishes the former from the latter.
  final bool isTerminal;

  /// Whether this anchor represents one source leaf.
  bool get isLeaf => leafIndex != null;

  Map<String, dynamic> toJson() => {
    'id': id,
    'category': category,
    'distance': distance,
    'mergeDistance': mergeDistance,
    'memberCount': memberCount,
    if (leafIndex != null) 'leafIndex': leafIndex,
    if (isTerminal != isLeaf) 'isTerminal': isTerminal,
  };

  void _validate() {
    if (id.isEmpty ||
        !category.isFinite ||
        category < 0 ||
        category > 1 ||
        !distance.isFinite ||
        distance < 0 ||
        distance > 1 ||
        !mergeDistance.isFinite ||
        mergeDistance < 0 ||
        memberCount <= 0 ||
        (isLeaf && !isTerminal) ||
        (leafIndex != null && leafIndex! < 0)) {
      throw const FormatException('Invalid Heatmap dendrogram node values');
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HeatmapDendrogramNode &&
          other.id == id &&
          other.category == category &&
          other.distance == distance &&
          other.mergeDistance == mergeDistance &&
          other.memberCount == memberCount &&
          other.leafIndex == leafIndex &&
          other.isTerminal == isTerminal;

  @override
  int get hashCode => Object.hash(
    id,
    category,
    distance,
    mergeDistance,
    memberCount,
    leafIndex,
    isTerminal,
  );
}

/// Portable, renderer-independent dendrogram geometry.
@immutable
final class HeatmapDendrogramData {
  factory HeatmapDendrogramData({
    required HeatmapClusterNode root,
    required List<String> sourceLabels,
    required HeatmapDendrogramAxis axis,
    HeatmapDendrogramDistanceScale distanceScale =
        HeatmapDendrogramDistanceScale.proportional,
    HeatmapHierarchyCollapseState collapseState =
        const HeatmapHierarchyCollapseState.empty(),
    Map<String, String> collapsedLabels = const {},
  }) {
    if (sourceLabels.isEmpty ||
        sourceLabels.any((label) => label.isEmpty) ||
        sourceLabels.toSet().length != sourceLabels.length) {
      throw ArgumentError.value(
        sourceLabels,
        'sourceLabels',
        'must contain unique, non-empty labels',
      );
    }
    final projection = HeatmapHierarchyProjection(
      root: root,
      sourceLabels: sourceLabels,
      collapseState: collapseState,
      collapsedLabels: collapsedLabels,
    );
    final leafOrder = projection.sourceOrder;
    if (leafOrder.isEmpty ||
        leafOrder.toSet().length != leafOrder.length ||
        leafOrder.any((index) => index < 0 || index >= sourceLabels.length)) {
      throw ArgumentError(
        'Heatmap dendrogram hierarchy must contain unique source-label indices',
      );
    }

    final terminalNodeIds = {
      for (final group in projection.visibleGroups) group.nodeId,
    };
    final heightByNodeId = <String, int>{};
    final maximumHeight = _collectProjectedHeights(
      root,
      terminalNodeIds,
      heightByNodeId,
    );
    final maximumDistance = _maximumDistance(root);
    final terminalPositions = <String, double>{
      for (
        var position = 0;
        position < projection.visibleGroups.length;
        position++
      )
        projection.visibleGroups[position].nodeId:
            (position + 0.5) / projection.visibleGroups.length,
    };
    final segments = <HeatmapDendrogramSegment>[];
    final nodes = <HeatmapDendrogramNode>[];

    _layoutNode(
      root,
      terminalNodeIds: terminalNodeIds,
      terminalPositions: terminalPositions,
      heightByNodeId: heightByNodeId,
      maximumHeight: maximumHeight,
      maximumDistance: maximumDistance,
      distanceScale: distanceScale,
      segments: segments,
      nodes: nodes,
    );

    return HeatmapDendrogramData._(
      axis: axis,
      distanceScale: distanceScale,
      rootId: root.id,
      sourceLabels: List<String>.unmodifiable(sourceLabels),
      leafOrder: List<int>.unmodifiable(leafOrder),
      labels: List<String>.unmodifiable([
        for (final group in projection.visibleGroups) group.label,
      ]),
      visibleGroups: projection.visibleGroups,
      collapseState: collapseState,
      maximumDistance: maximumDistance,
      segments: List<HeatmapDendrogramSegment>.unmodifiable(segments),
      nodes: List<HeatmapDendrogramNode>.unmodifiable(nodes),
    );
  }

  factory HeatmapDendrogramData.fromJson(Map<String, dynamic> json) {
    final axisName = json['axis'];
    final distanceScaleName = json['distanceScale'];
    final rootId = json['rootId'];
    final sourceLabels = json['sourceLabels'];
    final leafOrder = json['leafOrder'];
    final labels = json['labels'];
    final maximumDistance = json['maximumDistance'];
    final segments = json['segments'];
    final nodes = json['nodes'];
    final visibleGroups = json['visibleGroups'];
    final collapseState = json['collapseState'];
    if (axisName is! String ||
        (distanceScaleName != null && distanceScaleName is! String) ||
        rootId is! String ||
        rootId.isEmpty ||
        sourceLabels is! List ||
        sourceLabels.any((value) => value is! String) ||
        leafOrder is! List ||
        leafOrder.any((value) => value is! int) ||
        labels is! List ||
        labels.any((value) => value is! String) ||
        maximumDistance is! num ||
        segments is! List ||
        segments.any((value) => value is! Map) ||
        nodes is! List ||
        nodes.any((value) => value is! Map) ||
        (visibleGroups != null &&
            (visibleGroups is! List ||
                visibleGroups.any((value) => value is! Map))) ||
        (collapseState != null && collapseState is! Map)) {
      throw const FormatException('Invalid Heatmap dendrogram data');
    }
    final axis = HeatmapDendrogramAxis.values
        .where((value) => value.name == axisName)
        .firstOrNull;
    if (axis == null) {
      throw const FormatException('Invalid Heatmap dendrogram axis');
    }
    final distanceScale = distanceScaleName == null
        ? HeatmapDendrogramDistanceScale.proportional
        : HeatmapDendrogramDistanceScale.values
              .where((value) => value.name == distanceScaleName)
              .firstOrNull;
    if (distanceScale == null) {
      throw const FormatException('Invalid Heatmap dendrogram distance scale');
    }
    final parsedNodes = List<HeatmapDendrogramNode>.unmodifiable([
      for (final value in nodes)
        HeatmapDendrogramNode.fromJson(Map<String, dynamic>.from(value as Map)),
    ]);
    final parsedVisibleGroups = visibleGroups == null
        ? List<HeatmapHierarchyVisibleGroup>.unmodifiable([
            for (var position = 0; position < leafOrder.length; position++)
              HeatmapHierarchyVisibleGroup(
                nodeId: parsedNodes
                    .singleWhere(
                      (node) => node.leafIndex == leafOrder[position],
                    )
                    .id,
                label: labels[position] as String,
                sourceIndices: [leafOrder[position] as int],
                mergeDistance: parsedNodes
                    .singleWhere(
                      (node) => node.leafIndex == leafOrder[position],
                    )
                    .mergeDistance,
                isCollapsed: false,
              ),
          ])
        : List<HeatmapHierarchyVisibleGroup>.unmodifiable([
            for (final value in visibleGroups)
              HeatmapHierarchyVisibleGroup.fromJson(
                Map<String, dynamic>.from(value as Map),
              ),
          ]);
    final data = HeatmapDendrogramData._(
      axis: axis,
      distanceScale: distanceScale,
      rootId: rootId,
      sourceLabels: List<String>.unmodifiable(sourceLabels.cast<String>()),
      leafOrder: List<int>.unmodifiable(leafOrder.cast<int>()),
      labels: List<String>.unmodifiable(labels.cast<String>()),
      visibleGroups: parsedVisibleGroups,
      collapseState: collapseState == null
          ? const HeatmapHierarchyCollapseState.empty()
          : HeatmapHierarchyCollapseState.fromJson(
              Map<String, dynamic>.from(collapseState as Map),
            ),
      maximumDistance: maximumDistance.toDouble(),
      segments: List<HeatmapDendrogramSegment>.unmodifiable([
        for (final value in segments)
          HeatmapDendrogramSegment.fromJson(
            Map<String, dynamic>.from(value as Map),
          ),
      ]),
      nodes: parsedNodes,
    );
    data._validate();
    return data;
  }

  const HeatmapDendrogramData._({
    required this.axis,
    required this.distanceScale,
    required this.rootId,
    required this.sourceLabels,
    required this.leafOrder,
    required this.labels,
    required this.visibleGroups,
    required this.collapseState,
    required this.maximumDistance,
    required this.segments,
    required this.nodes,
  });

  final HeatmapDendrogramAxis axis;
  final HeatmapDendrogramDistanceScale distanceScale;
  final String rootId;
  final List<String> sourceLabels;
  final List<int> leafOrder;
  final List<String> labels;
  final List<HeatmapHierarchyVisibleGroup> visibleGroups;
  final HeatmapHierarchyCollapseState collapseState;
  final double maximumDistance;
  final List<HeatmapDendrogramSegment> segments;
  final List<HeatmapDendrogramNode> nodes;

  /// Returns the visible terminal group represented by [nodeId].
  HeatmapHierarchyVisibleGroup? visibleGroupForNode(String nodeId) =>
      visibleGroups.where((group) => group.nodeId == nodeId).firstOrNull;

  Map<String, dynamic> toJson() => {
    'axis': axis.name,
    'distanceScale': distanceScale.name,
    'rootId': rootId,
    'sourceLabels': sourceLabels,
    'leafOrder': leafOrder,
    'labels': labels,
    'visibleGroups': [for (final group in visibleGroups) group.toJson()],
    'collapseState': collapseState.toJson(),
    'maximumDistance': maximumDistance,
    'segments': [for (final segment in segments) segment.toJson()],
    'nodes': [for (final node in nodes) node.toJson()],
  };

  /// JSON-safe metadata suitable for series and portable chart documents.
  Map<String, dynamic> get metadata => {
    'heatmapDendrogram${axis == HeatmapDendrogramAxis.rows ? 'Row' : 'Column'}':
        toJson(),
  };

  void _validate() {
    if (rootId.isEmpty ||
        sourceLabels.isEmpty ||
        labels.length != visibleGroups.length ||
        leafOrder.isEmpty ||
        !maximumDistance.isFinite ||
        maximumDistance < 0 ||
        sourceLabels.any((label) => label.isEmpty) ||
        labels.any((label) => label.isEmpty) ||
        sourceLabels.toSet().length != sourceLabels.length ||
        visibleGroups.isEmpty ||
        visibleGroups.map((group) => group.nodeId).toSet().length !=
            visibleGroups.length ||
        leafOrder.toSet().length != leafOrder.length ||
        leafOrder.any((index) => index < 0 || index >= sourceLabels.length)) {
      throw const FormatException('Invalid Heatmap dendrogram values');
    }
    for (final segment in segments) {
      segment._validate();
    }
    if (nodes.isEmpty ||
        nodes.map((node) => node.id).toSet().length != nodes.length ||
        nodes.where((node) => node.isTerminal).length != visibleGroups.length) {
      throw const FormatException('Invalid Heatmap dendrogram node set');
    }
    for (final node in nodes) {
      node._validate();
      if (node.leafIndex != null &&
          (node.leafIndex! >= sourceLabels.length ||
              !leafOrder.contains(node.leafIndex))) {
        throw const FormatException('Invalid Heatmap dendrogram leaf node');
      }
    }
    for (var index = 0; index < visibleGroups.length; index++) {
      final group = visibleGroups[index];
      if (group.label != labels[index] ||
          group.sourceIndices.any(
            (sourceIndex) =>
                sourceIndex < 0 || !leafOrder.contains(sourceIndex),
          ) ||
          !nodes.any((node) => node.id == group.nodeId && node.isTerminal)) {
        throw const FormatException('Invalid Heatmap dendrogram visible group');
      }
    }
  }
}

int _collectProjectedHeights(
  HeatmapClusterNode node,
  Set<String> terminalNodeIds,
  Map<String, int> heightByNodeId,
) {
  if (terminalNodeIds.contains(node.id)) {
    heightByNodeId[node.id] = 0;
    return 0;
  }
  final leftHeight = _collectProjectedHeights(
    node.left!,
    terminalNodeIds,
    heightByNodeId,
  );
  final rightHeight = _collectProjectedHeights(
    node.right!,
    terminalNodeIds,
    heightByNodeId,
  );
  final height = 1 + (leftHeight > rightHeight ? leftHeight : rightHeight);
  heightByNodeId[node.id] = height;
  return height;
}

double _maximumDistance(HeatmapClusterNode node) {
  if (node.isLeaf) return node.distance;
  final left = _maximumDistance(node.left!);
  final right = _maximumDistance(node.right!);
  return [node.distance, left, right].reduce((a, b) => a > b ? a : b);
}

_DendrogramAnchor _layoutNode(
  HeatmapClusterNode node, {
  required Set<String> terminalNodeIds,
  required Map<String, double> terminalPositions,
  required Map<String, int> heightByNodeId,
  required int maximumHeight,
  required double maximumDistance,
  required HeatmapDendrogramDistanceScale distanceScale,
  required List<HeatmapDendrogramSegment> segments,
  required List<HeatmapDendrogramNode> nodes,
}) {
  if (terminalNodeIds.contains(node.id)) {
    final category = terminalPositions[node.id]!;
    nodes.add(
      HeatmapDendrogramNode(
        id: node.id,
        category: category,
        distance: 0,
        mergeDistance: node.distance,
        memberCount: node.memberIndices.length,
        leafIndex: node.leafIndex,
        isTerminal: true,
      ),
    );
    return _DendrogramAnchor(category: category, distance: 0);
  }

  final left = _layoutNode(
    node.left!,
    terminalNodeIds: terminalNodeIds,
    terminalPositions: terminalPositions,
    heightByNodeId: heightByNodeId,
    maximumHeight: maximumHeight,
    maximumDistance: maximumDistance,
    distanceScale: distanceScale,
    segments: segments,
    nodes: nodes,
  );
  final right = _layoutNode(
    node.right!,
    terminalNodeIds: terminalNodeIds,
    terminalPositions: terminalPositions,
    heightByNodeId: heightByNodeId,
    maximumHeight: maximumHeight,
    maximumDistance: maximumDistance,
    distanceScale: distanceScale,
    segments: segments,
    nodes: nodes,
  );
  final usesStructuralScale =
      distanceScale == HeatmapDendrogramDistanceScale.structural ||
      maximumDistance == 0;
  final distance = usesStructuralScale
      ? maximumHeight == 0
            ? 1.0
            : heightByNodeId[node.id]! / maximumHeight
      : (node.distance / maximumDistance).clamp(0.0, 1.0);
  final category = (left.category + right.category) / 2;
  nodes.add(
    HeatmapDendrogramNode(
      id: node.id,
      category: category,
      distance: distance,
      mergeDistance: node.distance,
      memberCount: node.memberIndices.length,
      isTerminal: false,
    ),
  );

  segments.addAll([
    HeatmapDendrogramSegment(
      id: '${node.id}:left',
      nodeId: node.id,
      startCategory: left.category,
      startDistance: left.distance,
      endCategory: left.category,
      endDistance: distance,
    ),
    HeatmapDendrogramSegment(
      id: '${node.id}:right',
      nodeId: node.id,
      startCategory: right.category,
      startDistance: right.distance,
      endCategory: right.category,
      endDistance: distance,
    ),
    HeatmapDendrogramSegment(
      id: '${node.id}:join',
      nodeId: node.id,
      startCategory: left.category,
      startDistance: distance,
      endCategory: right.category,
      endDistance: distance,
    ),
  ]);
  return _DendrogramAnchor(category: category, distance: distance);
}

final class _DendrogramAnchor {
  const _DendrogramAnchor({required this.category, required this.distance});

  final double category;
  final double distance;
}
