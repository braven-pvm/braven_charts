import 'package:flutter/material.dart';

import 'chart_data_point.dart';

/// Builds the visible contents of a Donut chart's shared center opening.
///
/// Braven Charts retains the circular clip, size constraints, tap target, and
/// assistive semantics around the returned widget. The builder controls only
/// the visible content inside that interaction shell.
typedef DonutCenterBuilder =
    Widget Function(BuildContext context, DonutCenterData center);

/// Handles activation of the package-owned Donut center interaction shell.
typedef DonutCenterTapCallback = void Function(DonutCenterData center);

/// One independent Donut ring represented by a shared Concentric Donut center.
@immutable
class DonutCenterRingSummary {
  /// Creates immutable ring summary data for a runtime center builder.
  const DonutCenterRingSummary({
    required this.seriesId,
    required this.seriesName,
    required this.unit,
    required this.total,
    required this.ringIndex,
    required this.ringCount,
    required this.positionLabel,
  });

  /// Stable source-series identity.
  final String seriesId;

  /// Optional user-facing series name.
  final String? seriesName;

  /// Optional unit supplied by the ring series.
  final String? unit;

  /// Sum of every positive source contribution in this ring.
  final double total;

  /// Source-series index used by legend, table, and controller identity.
  final int ringIndex;

  /// Number of rings sharing the center.
  final int ringCount;

  /// Human-readable radial position such as `Outer ring` or `Inner ring`.
  final String positionLabel;
}

/// Resolved data and presentation state for one Donut center.
///
/// A selected grouped slice exposes the aggregate [selectedPoint] together
/// with every original [selectedSourcePointIndices] and [selectedSourcePoints].
@immutable
class DonutCenterData {
  /// Creates immutable details for a visible Donut center.
  DonutCenterData({
    required this.seriesId,
    required this.seriesName,
    required this.unit,
    required this.total,
    required this.label,
    required this.valueLabel,
    required this.semanticLabel,
    required this.availableDiameter,
    required this.defaultLabelStyle,
    required this.defaultValueStyle,
    required this.selectionColor,
    this.selectedPoint,
    this.selectedCategory,
    this.selectedValue,
    this.selectedShare,
    this.selectedSeriesId,
    this.selectedRingIndex,
    this.selectedPointIndex,
    List<DonutCenterRingSummary> rings = const <DonutCenterRingSummary>[],
    List<int> selectedSourcePointIndices = const <int>[],
    List<ChartDataPoint> selectedSourcePoints = const <ChartDataPoint>[],
  }) : rings = List<DonutCenterRingSummary>.unmodifiable(rings),
       selectedSourcePointIndices = List<int>.unmodifiable(
         selectedSourcePointIndices,
       ),
       selectedSourcePoints = List<ChartDataPoint>.unmodifiable(
         selectedSourcePoints,
       );

  /// Stable series identity used by controller and artifact point references.
  final String seriesId;

  /// Optional user-facing series name.
  final String? seriesName;

  /// Optional unit supplied by the Donut series.
  final String? unit;

  /// Sum of every positive source contribution.
  final double total;

  /// Resolved portable label used by the default center presentation.
  final String? label;

  /// Resolved portable value used by the default center presentation.
  final String valueLabel;

  /// Package-owned accessible description retained around custom content.
  final String semanticLabel;

  /// Diameter of the circular opening available to the interaction shell.
  final double availableDiameter;

  /// Effective default style for the center's secondary label.
  final TextStyle defaultLabelStyle;

  /// Effective default style for the center's primary value.
  final TextStyle defaultValueStyle;

  /// Chart focus color available for custom selected treatments.
  final Color selectionColor;

  /// Effective visible selected point, including a grouped aggregate.
  final ChartDataPoint? selectedPoint;

  /// Resolved category of [selectedPoint].
  final String? selectedCategory;

  /// Primary contribution of [selectedPoint].
  final double? selectedValue;

  /// Selected contribution divided by [total].
  final double? selectedShare;

  /// Stable series identity that owns [selectedPoint], when selected.
  ///
  /// This is especially useful for Concentric Donut centers, where [seriesId]
  /// continues to identify the primary ring when no selection exists.
  final String? selectedSeriesId;

  /// Source-series index that owns [selectedPoint], when selected.
  final int? selectedRingIndex;

  /// Source point index represented by [selectedPoint], when selected.
  final int? selectedPointIndex;

  /// Every independent ring sharing this center, in source-series order.
  ///
  /// A single Donut supplies one summary. Concentric Donut supplies one entry
  /// per ring without merging their independent totals.
  final List<DonutCenterRingSummary> rings;

  /// Stable source point indices represented by [selectedPoint].
  final List<int> selectedSourcePointIndices;

  /// Original source points represented by [selectedPoint].
  final List<ChartDataPoint> selectedSourcePoints;

  /// Whether the center currently represents a selected visible slice.
  bool get hasSelection => selectedPoint != null;
}
