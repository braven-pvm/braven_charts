/// Runtime state for multi-axis chart rendering.
///
/// Computed from series data and axis configurations, this state is
/// immutable for each render frame and contains all derived values
/// needed for multi-axis normalization and rendering.
///
/// See also:
/// - [YAxisConfig] for axis configuration
/// - [YAxisPosition] for axis positioning
/// - [NormalizationMode] for normalization behavior
library;

import 'dart:ui' show Rect;

import '../models/data_range.dart';
import '../models/y_axis_position.dart';
import 'y_axis_config.dart';

/// Computed multi-axis state for a single render frame.
///
/// This class holds all derived values needed for multi-axis rendering:
/// - Axis bounds computed from series data
/// - Axis widths computed from label widths
/// - Series-to-axis mappings
/// - Effective chart area after axis width deduction
///
/// The state is immutable and recreated whenever the data or configuration
/// changes. It should be computed during the layout phase and passed to
/// the paint phase for rendering.
///
/// Example:
/// ```dart
/// final state = MultiAxisState(
///   axisConfigs: {'power': powerAxis, 'hr': hrAxis},
///   axisBounds: {'power': powerRange, 'hr': hrRange},
///   seriesAxisMap: {'powerSeries': 'power', 'hrSeries': 'hr'},
///   axisWidths: {'power': 60.0, 'hr': 55.0},
///   effectiveChartArea: Rect.fromLTWH(60, 0, 680, 400),
/// );
///
/// // Use for normalization
/// final normalizedY = state.normalizeY('powerSeries', 240.0);
///
/// // Use for value lookup
/// final originalY = state.denormalizeY('powerSeries', 0.5);
/// ```
class MultiAxisState {
  /// Creates a multi-axis state with all computed values.
  const MultiAxisState({
    required this.axisConfigs,
    required this.axisBounds,
    required this.seriesAxisMap,
    required this.axisWidths,
    required this.effectiveChartArea,
  });

  /// Creates an empty state for single-axis mode.
  ///
  /// Use this when multi-axis mode is not active.
  const MultiAxisState.empty()
      : axisConfigs = const {},
        axisBounds = const {},
        seriesAxisMap = const {},
        axisWidths = const {},
        effectiveChartArea = Rect.zero;

  /// Axis ID → configuration mapping.
  ///
  /// Contains all configured Y-axes indexed by their unique ID.
  final Map<String, YAxisConfig> axisConfigs;

  /// Axis ID → computed data bounds mapping.
  ///
  /// Bounds are computed from:
  /// 1. Explicit min/max in [YAxisConfig] if specified
  /// 2. Min/max of all series bound to this axis otherwise
  final Map<String, DataRange> axisBounds;

  /// Series ID → axis ID mapping.
  ///
  /// Maps each series to its Y-axis by ID. Series with null [yAxisId]
  /// are mapped to the primary axis (first left-positioned axis).
  final Map<String, String> seriesAxisMap;

  /// Axis ID → computed width in pixels.
  ///
  /// Width is determined by the maximum label width for this axis,
  /// clamped to [YAxisConfig.minWidth] and [YAxisConfig.maxWidth].
  final Map<String, double> axisWidths;

  /// Plot area after axis width deduction.
  ///
  /// This is the area available for rendering series data,
  /// computed as: widget bounds - left axis widths - right axis widths.
  final Rect effectiveChartArea;

  /// Whether multi-axis rendering is active.
  ///
  /// Returns true when more than one axis is configured.
  bool get isMultiAxisActive => axisConfigs.length > 1;

  /// Number of configured axes.
  int get axisCount => axisConfigs.length;

  /// Axes positioned on the left side (leftOuter, left).
  ///
  /// Sorted from outer to inner (leftOuter first, then left).
  List<YAxisConfig> get leftAxes {
    final axes = axisConfigs.values.where((a) => a.position.isLeft).toList();
    axes.sort((a, b) => a.position.index.compareTo(b.position.index));
    return axes;
  }

  /// Axes positioned on the right side (right, rightOuter).
  ///
  /// Sorted from inner to outer (right first, then rightOuter).
  List<YAxisConfig> get rightAxes {
    final axes = axisConfigs.values.where((a) => a.position.isRight).toList();
    axes.sort((a, b) => a.position.index.compareTo(b.position.index));
    return axes;
  }

  /// Total width of left-side axes in pixels.
  double get totalLeftWidth => leftAxes.fold(0.0, (sum, axis) => sum + (axisWidths[axis.id] ?? 0.0));

  /// Total width of right-side axes in pixels.
  double get totalRightWidth => rightAxes.fold(0.0, (sum, axis) => sum + (axisWidths[axis.id] ?? 0.0));

  /// Gets the axis ID for a series.
  ///
  /// Returns null if the series is not mapped to any axis.
  String? getAxisIdForSeries(String seriesId) => seriesAxisMap[seriesId];

  /// Gets the axis configuration for a series.
  ///
  /// Returns the axis config bound to the given series ID,
  /// or null if the series is not mapped.
  YAxisConfig? getAxisForSeries(String seriesId) {
    final axisId = seriesAxisMap[seriesId];
    return axisId != null ? axisConfigs[axisId] : null;
  }

  /// Gets the data bounds for a series.
  ///
  /// Returns the Y-axis bounds for the axis bound to the given series.
  DataRange? getBoundsForSeries(String seriesId) {
    final axisId = seriesAxisMap[seriesId];
    return axisId != null ? axisBounds[axisId] : null;
  }

  /// Gets the width of the axis for a series.
  ///
  /// Returns 0.0 if the series is not mapped or axis width not computed.
  double getAxisWidthForSeries(String seriesId) {
    final axisId = seriesAxisMap[seriesId];
    return axisId != null ? (axisWidths[axisId] ?? 0.0) : 0.0;
  }

  /// Normalizes a Y value for a specific series to [0.0, 1.0].
  ///
  /// Maps the value from its axis bounds to a normalized value where:
  /// - 0.0 represents the axis minimum
  /// - 1.0 represents the axis maximum
  ///
  /// Returns null if the series is not mapped or bounds not found.
  /// Returns 0.5 if the axis range is zero (prevents division by zero).
  double? normalizeY(String seriesId, double y) {
    final bounds = getBoundsForSeries(seriesId);
    if (bounds == null) return null;

    final range = bounds.span;
    if (range == 0) return 0.5; // Avoid division by zero

    return (y - bounds.min) / range;
  }

  /// Denormalizes a Y value from [0.0, 1.0] back to original data value.
  ///
  /// Maps the normalized value back to its axis bounds where:
  /// - 0.0 maps to the axis minimum
  /// - 1.0 maps to the axis maximum
  ///
  /// Returns null if the series is not mapped or bounds not found.
  double? denormalizeY(String seriesId, double normalizedY) {
    final bounds = getBoundsForSeries(seriesId);
    if (bounds == null) return null;

    return bounds.min + normalizedY * bounds.span;
  }

  /// Converts a screen Y position to an original data value for a series.
  ///
  /// Useful for crosshair and tooltip value display.
  /// [screenY] should be relative to [effectiveChartArea].
  ///
  /// Returns null if the series is not mapped.
  double? screenYToValue(String seriesId, double screenY) {
    if (effectiveChartArea.isEmpty) return null;

    // Convert screen Y to normalized Y (0 = top, 1 = bottom)
    final normalizedY = 1.0 - (screenY - effectiveChartArea.top) / effectiveChartArea.height;

    return denormalizeY(seriesId, normalizedY);
  }

  /// Converts an original data value to a screen Y position for a series.
  ///
  /// Useful for rendering normalized series data.
  /// Returns Y position relative to widget bounds.
  ///
  /// Returns null if the series is not mapped.
  double? valueToScreenY(String seriesId, double value) {
    final normalizedY = normalizeY(seriesId, value);
    if (normalizedY == null) return null;

    // Convert normalized Y to screen Y (0 = top, 1 = bottom, so invert)
    return effectiveChartArea.top + effectiveChartArea.height * (1.0 - normalizedY);
  }

  @override
  String toString() => 'MultiAxisState(axes: $axisCount, series: ${seriesAxisMap.length}, active: $isMultiAxisActive)';
}
