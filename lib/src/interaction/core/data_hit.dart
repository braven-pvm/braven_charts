import 'dart:ui';

import '../../models/chart_data_point.dart';

/// Immutable identity and display payload for one interactable chart datum.
///
/// Cartesian markers and radial slices share this boundary so hover, tooltip,
/// activation, and assistive semantics do not depend on a renderer shape.
class ChartDataHit {
  /// Creates a resolved data hit in plot-local coordinates.
  const ChartDataHit({
    required this.seriesId,
    required this.pointIndex,
    this.sourcePointIndices = const <int>[],
    required this.plotPosition,
    required this.semanticBounds,
    required this.point,
    required this.formattedValue,
    required this.ordinal,
    required this.count,
    this.category,
    this.total,
    this.share,
    this.formattedShare,
    this.radiusValue,
    this.formattedRadiusValue,
    this.radiusLabel,
    this.groupLabel,
    this.groupName,
    this.groupOrdinal,
    this.groupCount,
    this.isSelected = false,
    this.isFocused = false,
  });

  /// Stable source-series ID.
  final String seriesId;

  /// Stable source point index within the series.
  final int pointIndex;

  /// Original point indices represented by this hit.
  ///
  /// Cartesian data and ungrouped radial slices leave this empty and use
  /// [pointIndex]. Grouped radial slices carry every source point here.
  final List<int> sourcePointIndices;

  /// Complete source identity represented by this hit.
  List<int> get effectiveSourcePointIndices => sourcePointIndices.isEmpty
      ? <int>[pointIndex]
      : List<int>.unmodifiable(sourcePointIndices);

  /// Preferred tooltip anchor in plot-local coordinates.
  final Offset plotPosition;

  /// Assistive hit region in plot-local coordinates.
  final Rect semanticBounds;

  /// Original transported point passed to public callbacks.
  final ChartDataPoint point;

  /// Optional category label for categorical renderers.
  final String? category;

  /// Raw total used to calculate a categorical share.
  final double? total;

  /// Fractional contribution in the inclusive range 0–1.
  final double? share;

  /// Optional visual formatting for [share], including its percent suffix.
  final String? formattedShare;

  /// Optional raw second metric controlling radial extent.
  final double? radiusValue;

  /// Optional formatted radius metric including its unit.
  final String? formattedRadiusValue;

  /// Optional human-readable name of the radius metric.
  final String? radiusLabel;

  /// Optional position label for a datum inside a composed data group.
  ///
  /// Concentric Donut uses this for values such as `Outer ring` and keeps it
  /// null for standalone Pie and Donut charts so their existing presentation
  /// remains unchanged.
  final String? groupLabel;

  /// Optional user-facing name of the composed data group.
  final String? groupName;

  /// One-based traversal position of the composed data group.
  final int? groupOrdinal;

  /// Number of groups participating in the composition.
  final int? groupCount;

  /// Preformatted value including an applicable unit.
  final String formattedValue;

  /// One-based visible position of this datum.
  final int ordinal;

  /// Number of visible data items in this element.
  final int count;

  /// Whether this datum has durable selection state.
  final bool isSelected;

  /// Whether this datum has transient keyboard or linked focus.
  final bool isFocused;

  /// Complete non-color-only announcement for assistive technologies.
  String get semanticLabel {
    final name = category ?? point.label ?? 'Data point';
    final parts = <String>[?groupLabel, ?groupName, name, formattedValue];
    if (share != null) {
      final display = formattedShare ?? '${(share! * 100).toStringAsFixed(1)}%';
      parts.add(
        display.endsWith('%')
            ? '${display.substring(0, display.length - 1)} percent'
            : display,
      );
    }
    if (formattedRadiusValue != null) {
      parts.add('${radiusLabel ?? 'Radius'} $formattedRadiusValue');
    }
    if (effectiveSourcePointIndices.length > 1) {
      parts.add('${effectiveSourcePointIndices.length} grouped categories');
    }
    parts.add('${share == null ? 'point' : 'slice'} $ordinal of $count');
    parts.add(isSelected ? 'selected' : 'not selected');
    return parts.join(', ');
  }

  /// Stable sort position for assistive traversal across composed groups.
  double get semanticSortOrdinal =>
      ((groupOrdinal ?? 1) - 1) * 1000000 + ordinal.toDouble();
}
