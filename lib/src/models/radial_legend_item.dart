import 'package:flutter/material.dart';

import 'chart_data_point.dart';

/// Builds the visible content of one Pie or Donut legend item.
///
/// Braven Charts retains the package-owned tap target, selection action, and
/// assistive semantics around the returned widget. The builder controls the
/// complete visible contents inside that interaction shell.
typedef RadialLegendItemBuilder =
    Widget Function(BuildContext context, RadialLegendItemData item);

/// Resolved data and presentation state for one visible radial legend item.
///
/// A grouped `Other` item has multiple [sourcePointIndices] and [sourcePoints]
/// while [point] contains the single aggregate slice shown by the chart.
@immutable
class RadialLegendItemData {
  /// Creates immutable details for a visible radial legend item.
  RadialLegendItemData({
    required this.seriesId,
    required this.seriesName,
    required this.unit,
    required this.visibleIndex,
    required this.pointIndex,
    required List<int> sourcePointIndices,
    required List<ChartDataPoint> sourcePoints,
    required this.point,
    required this.category,
    required this.value,
    required this.share,
    required this.color,
    required this.selectionColor,
    required this.defaultTextStyle,
    required this.selected,
    required this.animationDuration,
    String? valueLabel,
    String? shareLabel,
  }) : sourcePointIndices = List<int>.unmodifiable(sourcePointIndices),
       sourcePoints = List<ChartDataPoint>.unmodifiable(sourcePoints),
       valueLabel =
           valueLabel ??
           '${value.toStringAsFixed(2)}${unit == null || unit.isEmpty ? '' : ' $unit'}',
       shareLabel = shareLabel ?? '${(share * 100).toStringAsFixed(1)}%';

  /// Stable series identity used by controller and artifact point references.
  final String seriesId;

  /// Optional user-facing series name.
  final String? seriesName;

  /// Optional value unit supplied by the radial series.
  final String? unit;

  /// Zero-based position among the currently visible slices.
  final int visibleIndex;

  /// Representative source point index used to activate this visible slice.
  final int pointIndex;

  /// Every stable source point index represented by this visible slice.
  final List<int> sourcePointIndices;

  /// Original source points represented by this visible slice.
  final List<ChartDataPoint> sourcePoints;

  /// Effective visible point, including an aggregate grouped slice when used.
  final ChartDataPoint point;

  /// Resolved non-empty category label.
  final String category;

  /// Effective visible contribution value.
  final double value;

  /// Contribution divided by the total of all visible values, in the range
  /// zero to one.
  final double share;

  /// Final slice color after point, series, and theme precedence is resolved.
  final Color color;

  /// Chart focus color available for custom selected and focused treatments.
  final Color selectionColor;

  /// Effective legend text style from the active chart theme.
  final TextStyle defaultTextStyle;

  /// Whether every source point represented by this item is selected.
  final bool selected;

  /// Effective interaction animation duration, or zero when disabled.
  final Duration animationDuration;

  /// Default package value formatting offered as a builder convenience.
  final String valueLabel;

  /// Default package percentage formatting offered as a builder convenience.
  final String shareLabel;

  /// Package-owned accessible description retained around custom content.
  String get semanticLabel {
    final semanticShare = shareLabel.endsWith('%')
        ? '${shareLabel.substring(0, shareLabel.length - 1)} percent'
        : shareLabel;
    return '$category, $valueLabel, $semanticShare, '
        '${selected ? 'selected' : 'not selected'}';
  }
}
