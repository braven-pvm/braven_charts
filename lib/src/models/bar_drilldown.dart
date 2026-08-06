import 'package:flutter/foundation.dart';

import '../meta/chart_surface.dart';
import 'chart_series.dart';

/// Gesture that activates a hierarchy navigation step.
enum BarDrillActivation { primaryAction, selection }

/// Host-side transition used when the effective hierarchy level changes.
enum BarDrillTransition { none, fadeThrough }

/// How chart selection should be treated when navigating between levels.
enum BarDrillSelectionPolicy { clear, preserveStableIdentities }

/// One immutable level in a hierarchical bar chart.
///
/// A node owns the complete series shown at that level. Child IDs are mapped
/// from a point's `metadata['barDrillNodeId']` value, keeping the renderer and
/// the source series ordinary and independently reusable.
@immutable
@chartSurface
final class BarDrillNode {
  const BarDrillNode({
    required this.id,
    required this.label,
    required this.series,
    this.children = const <BarDrillNode>[],
    this.metadata = const <String, Object?>{},
    this.mayHaveLazyChildren = false,
  }) : assert(id != ''),
       assert(label != '');

  final String id;
  final String label;
  final List<ChartSeries> series;
  final List<BarDrillNode> children;
  final Map<String, Object?> metadata;
  final bool mayHaveLazyChildren;

  BarDrillNode copyWith({
    String? id,
    String? label,
    List<ChartSeries>? series,
    List<BarDrillNode>? children,
    Map<String, Object?>? metadata,
    bool? mayHaveLazyChildren,
  }) => BarDrillNode(
    id: id ?? this.id,
    label: label ?? this.label,
    series: series ?? this.series,
    children: children ?? this.children,
    metadata: metadata ?? this.metadata,
    mayHaveLazyChildren: mayHaveLazyChildren ?? this.mayHaveLazyChildren,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BarDrillNode &&
          other.id == id &&
          other.label == label &&
          listEquals(other.series, series) &&
          listEquals(other.children, children) &&
          mapEquals(other.metadata, metadata) &&
          other.mayHaveLazyChildren == mayHaveLazyChildren;

  @override
  int get hashCode => Object.hash(
    id,
    label,
    Object.hashAll(series),
    Object.hashAll(children),
    Object.hashAllUnordered(metadata.entries),
    mayHaveLazyChildren,
  );
}

/// Portable hierarchy policy; runtime lazy resolvers are supplied separately.
@immutable
@chartSurface
final class BarDrilldownConfig {
  const BarDrilldownConfig({
    required this.root,
    this.activation = BarDrillActivation.primaryAction,
    this.transition = BarDrillTransition.fadeThrough,
    this.showBreadcrumbs = true,
    this.selectionPolicy = BarDrillSelectionPolicy.clear,
    this.lazyResolverBinding,
  });

  final BarDrillNode root;
  final BarDrillActivation activation;
  final BarDrillTransition transition;
  final bool showBreadcrumbs;
  final BarDrillSelectionPolicy selectionPolicy;

  /// Optional host binding name for resolving children that are not embedded.
  ///
  /// The binding name is portable; the executable resolver is supplied by the
  /// host when constructing the drill-down controller.
  final String? lazyResolverBinding;

  BarDrilldownConfig copyWith({
    BarDrillNode? root,
    BarDrillActivation? activation,
    BarDrillTransition? transition,
    bool? showBreadcrumbs,
    BarDrillSelectionPolicy? selectionPolicy,
    String? lazyResolverBinding,
    bool clearLazyResolverBinding = false,
  }) => BarDrilldownConfig(
    root: root ?? this.root,
    activation: activation ?? this.activation,
    transition: transition ?? this.transition,
    showBreadcrumbs: showBreadcrumbs ?? this.showBreadcrumbs,
    selectionPolicy: selectionPolicy ?? this.selectionPolicy,
    lazyResolverBinding: clearLazyResolverBinding
        ? null
        : lazyResolverBinding ?? this.lazyResolverBinding,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BarDrilldownConfig &&
          other.root == root &&
          other.activation == activation &&
          other.transition == transition &&
          other.showBreadcrumbs == showBreadcrumbs &&
          other.selectionPolicy == selectionPolicy &&
          other.lazyResolverBinding == lazyResolverBinding;

  @override
  int get hashCode => Object.hash(
    root,
    activation,
    transition,
    showBreadcrumbs,
    selectionPolicy,
    lazyResolverBinding,
  );
}

/// Metadata key used to associate a rendered point with a child node.
const barDrillNodeIdMetadataKey = 'barDrillNodeId';

String? barDrillNodeIdForPointMetadata(Map<String, dynamic>? metadata) {
  final value = metadata?[barDrillNodeIdMetadataKey];
  return value is String && value.isNotEmpty ? value : null;
}
