/// Contract: MultiAxisState
///
/// Runtime state computed from series data and axis configurations.
/// Immutable per render frame.
library;

import 'dart:ui' show Rect;

import 'package:braven_charts/legacy/braven_charts.dart' show DataRange;

import 'y_axis_config.dart';

/// Computed multi-axis state for a single render frame.
///
/// This class holds all derived values needed for multi-axis rendering:
/// - Axis bounds computed from series data
/// - Axis widths computed from label widths
/// - Series-to-axis mappings
/// - Effective chart area after axis width deduction
///
/// Example:
/// ```dart
/// final state = MultiAxisState.compute(
///   axisConfigs: [powerAxis, heartRateAxis],
///   series: [powerSeries, hrSeries],
///   availableWidth: 800,
/// );
///
/// // Use for rendering
/// final powerBounds = state.axisBounds['power'];
/// final normalizedY = (point.y - powerBounds.min) /
///     (powerBounds.max - powerBounds.min);
/// ```
class MultiAxisState {
  const MultiAxisState({
    required this.axisConfigs,
    required this.axisBounds,
    required this.seriesAxisMap,
    required this.axisWidths,
    required this.effectiveChartArea,
  });

  /// Axis ID → configuration mapping.
  final Map<String, YAxisConfig> axisConfigs;

  /// Axis ID → computed data bounds mapping.
  ///
  /// Bounds are computed from:
  /// 1. Explicit min/max in YAxisConfig (if specified)
  /// 2. Min/max of all series bound to this axis (if not specified)
  final Map<String, DataRange> axisBounds;

  /// Series ID → axis ID mapping.
  ///
  /// Maps each series to its Y-axis. Series with null yAxisId
  /// are mapped to the primary (left) axis.
  final Map<String, String> seriesAxisMap;

  /// Axis ID → computed width in pixels.
  ///
  /// Width is determined by:
  /// 1. Maximum label width for this axis
  /// 2. Clamped to [minWidth, maxWidth] from config
  final Map<String, double> axisWidths;

  /// Plot area after axis width deduction.
  ///
  /// This is the area available for rendering series data,
  /// computed as: widget bounds - left axis widths - right axis widths.
  final Rect effectiveChartArea;

  /// Whether multi-axis rendering is active.
  bool get isMultiAxisActive => axisConfigs.length > 1;

  /// Axes positioned on the left side (leftOuter, left).
  List<YAxisConfig> get leftAxes => axisConfigs.values
      .where((a) =>
          a.position == YAxisPosition.leftOuter ||
          a.position == YAxisPosition.left)
      .toList()
    ..sort((a, b) => a.position.index.compareTo(b.position.index));

  /// Axes positioned on the right side (right, rightOuter).
  List<YAxisConfig> get rightAxes => axisConfigs.values
      .where((a) =>
          a.position == YAxisPosition.right ||
          a.position == YAxisPosition.rightOuter)
      .toList()
    ..sort((a, b) => a.position.index.compareTo(b.position.index));

  /// Total width of left-side axes in pixels.
  double get totalLeftWidth =>
      leftAxes.fold(0.0, (sum, axis) => sum + (axisWidths[axis.id] ?? 0));

  /// Total width of right-side axes in pixels.
  double get totalRightWidth =>
      rightAxes.fold(0.0, (sum, axis) => sum + (axisWidths[axis.id] ?? 0));

  /// Get the axis configuration for a series.
  ///
  /// Returns the axis config bound to the given series ID,
  /// or the primary axis if not found.
  YAxisConfig? getAxisForSeries(String seriesId) {
    final axisId = seriesAxisMap[seriesId];
    return axisId != null ? axisConfigs[axisId] : null;
  }

  /// Get the data bounds for a series.
  ///
  /// Returns the Y-axis bounds for the axis bound to the given series.
  DataRange? getBoundsForSeries(String seriesId) {
    final axisId = seriesAxisMap[seriesId];
    return axisId != null ? axisBounds[axisId] : null;
  }

  /// Normalize a Y value for a specific series.
  ///
  /// Maps the value from its axis bounds to [0.0, 1.0].
  /// Returns null if series or bounds not found.
  double? normalizeY(String seriesId, double y) {
    final bounds = getBoundsForSeries(seriesId);
    if (bounds == null) return null;

    final range = bounds.max - bounds.min;
    if (range == 0) return 0.5; // Avoid division by zero

    return (y - bounds.min) / range;
  }

  /// Denormalize a Y value for a specific series.
  ///
  /// Maps the value from [0.0, 1.0] back to axis bounds.
  /// Returns null if series or bounds not found.
  double? denormalizeY(String seriesId, double normalizedY) {
    final bounds = getBoundsForSeries(seriesId);
    if (bounds == null) return null;

    return bounds.min + normalizedY * (bounds.max - bounds.min);
  }

  @override
  String toString() => 'MultiAxisState('
      'axes: ${axisConfigs.length}, '
      'series: ${seriesAxisMap.length}, '
      'active: $isMultiAxisActive)';
}
