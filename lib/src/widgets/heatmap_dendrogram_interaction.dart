// Copyright 2026 Braven Charts contributors
// SPDX-License-Identifier: MIT

import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/foundation.dart';

import '../models/heatmap_dendrogram_data.dart';

/// Screen-space projection shared by Heatmap dendrogram painting and input.
///
/// The projection is immutable. Pass the same [edgeInset], LOD mode, and
/// [minimumBranchLength] used by the painter so visible geometry and hit
/// regions remain aligned.
@immutable
final class HeatmapDendrogramLayout {
  HeatmapDendrogramLayout({
    required this.data,
    required this.size,
    this.edgeInset = 0.5,
    this.automaticLevelOfDetail = true,
    this.minimumBranchLength = 1.25,
  }) : assert(edgeInset >= 0),
       assert(minimumBranchLength >= 0),
       nodes = List<HeatmapDendrogramProjectedNode>.unmodifiable([
         for (final node in data.nodes)
           HeatmapDendrogramProjectedNode(
             node: node,
             position: _project(
               data.axis,
               size,
               edgeInset,
               category: node.category,
               distance: node.distance,
             ),
           ),
       ]),
       segments = List<HeatmapDendrogramProjectedSegment>.unmodifiable(
         _projectVisibleSegments(
           data,
           size,
           edgeInset,
           automaticLevelOfDetail,
           minimumBranchLength,
         ),
       );

  final HeatmapDendrogramData data;
  final Size size;
  final double edgeInset;
  final bool automaticLevelOfDetail;
  final double minimumBranchLength;

  /// Every hierarchy-node anchor in screen space.
  final List<HeatmapDendrogramProjectedNode> nodes;

  /// Branch segments that are painted after applying LOD as complete merges.
  final List<HeatmapDendrogramProjectedSegment> segments;

  /// Projects one normalized hierarchy coordinate into this layout.
  Offset project({required double category, required double distance}) =>
      _project(
        data.axis,
        size,
        edgeInset,
        category: category,
        distance: distance,
      );
}

/// One hierarchy node projected into screen space.
@immutable
final class HeatmapDendrogramProjectedNode {
  const HeatmapDendrogramProjectedNode({
    required this.node,
    required this.position,
  });

  final HeatmapDendrogramNode node;
  final Offset position;
}

/// One accepted hierarchy branch segment projected into screen space.
@immutable
final class HeatmapDendrogramProjectedSegment {
  const HeatmapDendrogramProjectedSegment({
    required this.segment,
    required this.start,
    required this.end,
  });

  final HeatmapDendrogramSegment segment;
  final Offset start;
  final Offset end;
}

/// Kind of immutable dendrogram target returned by a hit test.
enum HeatmapDendrogramHitKind { node, branch }

/// Stable hierarchy identity selected by screen-space hit testing.
@immutable
final class HeatmapDendrogramHitTarget {
  const HeatmapDendrogramHitTarget._({
    required this.kind,
    required this.axis,
    required this.nodeId,
    required this.distance,
    this.segmentId,
    this.leafIndex,
    this.memberCount,
  });

  final HeatmapDendrogramHitKind kind;
  final HeatmapDendrogramAxis axis;
  final String nodeId;
  final String? segmentId;
  final int? leafIndex;
  final int? memberCount;

  /// Screen-space distance from the pointer to the accepted target.
  final double distance;

  /// Stable, portable identity independent of the current canvas geometry.
  HeatmapDendrogramTargetIdentity get identity =>
      HeatmapDendrogramTargetIdentity(
        kind: kind,
        axis: axis,
        nodeId: nodeId,
        segmentId: segmentId,
      );
}

/// Stable node or branch identity used by hierarchy interaction state.
@immutable
final class HeatmapDendrogramTargetIdentity {
  const HeatmapDendrogramTargetIdentity({
    required this.kind,
    required this.axis,
    required this.nodeId,
    this.segmentId,
  }) : assert(
         kind == HeatmapDendrogramHitKind.branch || segmentId == null,
         'Only branch identities can carry a segment ID.',
       );

  factory HeatmapDendrogramTargetIdentity.fromJson(Map<String, dynamic> json) {
    final kindName = json['kind'];
    final axisName = json['axis'];
    final nodeId = json['nodeId'];
    final segmentId = json['segmentId'];
    final kind = kindName is String
        ? HeatmapDendrogramHitKind.values
              .where((value) => value.name == kindName)
              .firstOrNull
        : null;
    final axis = axisName is String
        ? HeatmapDendrogramAxis.values
              .where((value) => value.name == axisName)
              .firstOrNull
        : null;
    if (kind == null ||
        axis == null ||
        nodeId is! String ||
        nodeId.isEmpty ||
        (segmentId != null && segmentId is! String) ||
        (kind == HeatmapDendrogramHitKind.node && segmentId != null) ||
        (kind == HeatmapDendrogramHitKind.branch &&
            (segmentId is! String || segmentId.isEmpty))) {
      throw const FormatException('Invalid Heatmap dendrogram target');
    }
    return HeatmapDendrogramTargetIdentity(
      kind: kind,
      axis: axis,
      nodeId: nodeId,
      segmentId: segmentId as String?,
    );
  }

  final HeatmapDendrogramHitKind kind;
  final HeatmapDendrogramAxis axis;
  final String nodeId;
  final String? segmentId;

  Map<String, dynamic> toJson() => {
    'kind': kind.name,
    'axis': axis.name,
    'nodeId': nodeId,
    if (segmentId != null) 'segmentId': segmentId,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HeatmapDendrogramTargetIdentity &&
          other.kind == kind &&
          other.axis == axis &&
          other.nodeId == nodeId &&
          other.segmentId == segmentId;

  @override
  int get hashCode => Object.hash(kind, axis, nodeId, segmentId);
}

/// Controlled hover, focus, and durable selection for one dendrogram.
///
/// Hover and focus are transient host state. [selectedTarget] is stable and
/// JSON-safe so applications can retain it in a portable chart document.
@immutable
final class HeatmapDendrogramInteractionState {
  const HeatmapDendrogramInteractionState({
    this.hoveredTarget,
    this.focusedTarget,
    this.selectedTarget,
  });

  final HeatmapDendrogramTargetIdentity? hoveredTarget;
  final HeatmapDendrogramTargetIdentity? focusedTarget;
  final HeatmapDendrogramTargetIdentity? selectedTarget;

  HeatmapDendrogramInteractionState withHoveredTarget(
    HeatmapDendrogramTargetIdentity? target,
  ) => HeatmapDendrogramInteractionState(
    hoveredTarget: target,
    focusedTarget: focusedTarget,
    selectedTarget: selectedTarget,
  );

  HeatmapDendrogramInteractionState withFocusedTarget(
    HeatmapDendrogramTargetIdentity? target,
  ) => HeatmapDendrogramInteractionState(
    hoveredTarget: hoveredTarget,
    focusedTarget: target,
    selectedTarget: selectedTarget,
  );

  HeatmapDendrogramInteractionState withSelectedTarget(
    HeatmapDendrogramTargetIdentity? target,
  ) => HeatmapDendrogramInteractionState(
    hoveredTarget: hoveredTarget,
    focusedTarget: focusedTarget,
    selectedTarget: target,
  );

  /// Portable durable state. Transient hover and focus are intentionally
  /// excluded.
  Map<String, dynamic> toJson() => {
    if (selectedTarget != null) 'selectedTarget': selectedTarget!.toJson(),
  };

  factory HeatmapDendrogramInteractionState.fromJson(
    Map<String, dynamic> json,
  ) {
    final selected = json['selectedTarget'];
    if (selected != null && selected is! Map) {
      throw const FormatException(
        'Invalid Heatmap dendrogram interaction state',
      );
    }
    return HeatmapDendrogramInteractionState(
      selectedTarget: selected == null
          ? null
          : HeatmapDendrogramTargetIdentity.fromJson(
              Map<String, dynamic>.from(selected as Map),
            ),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HeatmapDendrogramInteractionState &&
          other.hoveredTarget == hoveredTarget &&
          other.focusedTarget == focusedTarget &&
          other.selectedTarget == selectedTarget;

  @override
  int get hashCode => Object.hash(hoveredTarget, focusedTarget, selectedTarget);
}

/// Immutable hit-test snapshot for one accepted dendrogram layout.
@immutable
final class HeatmapDendrogramHitTestMap {
  const HeatmapDendrogramHitTestMap({
    required this.layout,
    this.includeLeafNodes = true,
    this.includeMergeNodes = true,
  });

  final HeatmapDendrogramLayout layout;
  final bool includeLeafNodes;
  final bool includeMergeNodes;

  /// Returns the deterministic target at [position], or `null` on a miss.
  ///
  /// Nodes take precedence over branches. Candidates are ordered by screen
  /// distance and then stable hierarchy identity.
  HeatmapDendrogramHitTarget? hitTest(
    Offset position, {
    double nodeRadius = 12,
    double branchRadius = 6,
  }) {
    assert(nodeRadius >= 0);
    assert(branchRadius >= 0);
    final nodes = <HeatmapDendrogramHitTarget>[];
    for (final projected in layout.nodes) {
      if ((projected.node.isTerminal && !includeLeafNodes) ||
          (!projected.node.isTerminal && !includeMergeNodes)) {
        continue;
      }
      final distance = (position - projected.position).distance;
      if (distance <= nodeRadius) {
        nodes.add(
          HeatmapDendrogramHitTarget._(
            kind: HeatmapDendrogramHitKind.node,
            axis: layout.data.axis,
            nodeId: projected.node.id,
            leafIndex: projected.node.leafIndex,
            memberCount: projected.node.memberCount,
            distance: distance,
          ),
        );
      }
    }
    if (nodes.isNotEmpty) {
      nodes.sort(_compareTargets);
      return nodes.first;
    }

    final branches = <HeatmapDendrogramHitTarget>[];
    for (final projected in layout.segments) {
      final distance = _distanceToSegment(
        position,
        projected.start,
        projected.end,
      );
      if (distance <= branchRadius) {
        branches.add(
          HeatmapDendrogramHitTarget._(
            kind: HeatmapDendrogramHitKind.branch,
            axis: layout.data.axis,
            nodeId: projected.segment.nodeId,
            segmentId: projected.segment.id,
            distance: distance,
          ),
        );
      }
    }
    if (branches.isEmpty) return null;
    branches.sort(_compareTargets);
    return branches.first;
  }
}

int _compareTargets(
  HeatmapDendrogramHitTarget left,
  HeatmapDendrogramHitTarget right,
) {
  final distance = left.distance.compareTo(right.distance);
  if (distance != 0) return distance;
  final node = left.nodeId.compareTo(right.nodeId);
  if (node != 0) return node;
  return (left.segmentId ?? '').compareTo(right.segmentId ?? '');
}

List<HeatmapDendrogramProjectedSegment> _projectVisibleSegments(
  HeatmapDendrogramData data,
  Size size,
  double edgeInset,
  bool automaticLevelOfDetail,
  double minimumBranchLength,
) {
  final projectedById = <String, HeatmapDendrogramProjectedSegment>{
    for (final segment in data.segments)
      segment.id: HeatmapDendrogramProjectedSegment(
        segment: segment,
        start: _project(
          data.axis,
          size,
          edgeInset,
          category: segment.startCategory,
          distance: segment.startDistance,
        ),
        end: _project(
          data.axis,
          size,
          edgeInset,
          category: segment.endCategory,
          distance: segment.endDistance,
        ),
      ),
  };
  if (!automaticLevelOfDetail || minimumBranchLength == 0) {
    return [for (final segment in data.segments) projectedById[segment.id]!];
  }

  final segmentsByNode = <String, List<HeatmapDendrogramSegment>>{};
  for (final segment in data.segments) {
    (segmentsByNode[segment.nodeId] ??= []).add(segment);
  }
  final visibleIds = <String>{};
  for (final segments in segmentsByNode.values) {
    final isCompleteMerge =
        segments.any((segment) => segment.id.endsWith(':left')) &&
        segments.any((segment) => segment.id.endsWith(':right')) &&
        segments.any((segment) => segment.id.endsWith(':join'));
    if (isCompleteMerge) {
      if (segments.any(
        (segment) =>
            _segmentLength(projectedById[segment.id]!) >= minimumBranchLength,
      )) {
        visibleIds.addAll(segments.map((segment) => segment.id));
      }
      continue;
    }
    for (final segment in segments) {
      if (_segmentLength(projectedById[segment.id]!) >= minimumBranchLength) {
        visibleIds.add(segment.id);
      }
    }
  }
  return [
    for (final segment in data.segments)
      if (visibleIds.contains(segment.id)) projectedById[segment.id]!,
  ];
}

double _segmentLength(HeatmapDendrogramProjectedSegment segment) =>
    (segment.end - segment.start).distance;

Offset _project(
  HeatmapDendrogramAxis axis,
  Size size,
  double edgeInset, {
  required double category,
  required double distance,
}) {
  final width = math.max(0, size.width - 2 * edgeInset);
  final height = math.max(0, size.height - 2 * edgeInset);
  return switch (axis) {
    HeatmapDendrogramAxis.columns => Offset(
      edgeInset + category * width,
      edgeInset + (1 - distance) * height,
    ),
    HeatmapDendrogramAxis.rows => Offset(
      edgeInset + (1 - distance) * width,
      edgeInset + (1 - category) * height,
    ),
  };
}

double _distanceToSegment(Offset point, Offset start, Offset end) {
  final delta = end - start;
  final lengthSquared = delta.dx * delta.dx + delta.dy * delta.dy;
  if (lengthSquared == 0) return (point - start).distance;
  final fromStart = point - start;
  final fraction =
      ((fromStart.dx * delta.dx + fromStart.dy * delta.dy) / lengthSquared)
          .clamp(0.0, 1.0);
  final nearest = start + delta * fraction;
  return (point - nearest).distance;
}
