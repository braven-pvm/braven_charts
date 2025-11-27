/// Axis bounds calculation utility for multi-axis charts.
///
/// Computes per-axis min/max bounds from series data based on
/// axis-series binding via [ChartSeries.yAxisId].
///
/// See also:
/// - [YAxisConfig] for axis configuration
/// - [MultiAxisState] for runtime axis state
library;

import '../axis/y_axis_config.dart';
import '../models/chart_series.dart';
import '../models/y_axis_position.dart';

/// Represents computed bounds for a single axis.
class AxisBounds {
  /// Creates axis bounds.
  const AxisBounds({
    required this.axisId,
    required this.min,
    required this.max,
    required this.seriesIds,
  });

  /// Creates default bounds (0-1) when no data is available.
  const AxisBounds.empty(this.axisId)
      : min = 0.0,
        max = 1.0,
        seriesIds = const [];

  /// The axis identifier.
  final String axisId;

  /// The minimum Y value across all bound series.
  final double min;

  /// The maximum Y value across all bound series.
  final double max;

  /// IDs of series bound to this axis.
  final List<String> seriesIds;

  /// The range span (max - min).
  double get range => max - min;

  /// Whether bounds are valid (max > min and at least one series).
  bool get isValid => max > min && seriesIds.isNotEmpty;

  /// Whether this represents default empty bounds.
  bool get isEmpty => seriesIds.isEmpty;

  /// Creates a copy with optional modifications.
  AxisBounds copyWith({
    String? axisId,
    double? min,
    double? max,
    List<String>? seriesIds,
  }) {
    return AxisBounds(
      axisId: axisId ?? this.axisId,
      min: min ?? this.min,
      max: max ?? this.max,
      seriesIds: seriesIds ?? this.seriesIds,
    );
  }

  @override
  String toString() =>
      'AxisBounds(id: $axisId, min: $min, max: $max, series: $seriesIds)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AxisBounds &&
          runtimeType == other.runtimeType &&
          axisId == other.axisId &&
          min == other.min &&
          max == other.max &&
          _listEquals(seriesIds, other.seriesIds);

  @override
  int get hashCode => Object.hash(axisId, min, max, Object.hashAll(seriesIds));

  /// Simple list equality check.
  static bool _listEquals<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

/// Complete bounds result for all axes.
class MultiAxisBounds {
  /// Creates multi-axis bounds.
  const MultiAxisBounds({
    required this.axisBounds,
    required this.seriesAxisMapping,
  });

  /// Creates empty multi-axis bounds.
  const MultiAxisBounds.empty()
      : axisBounds = const {},
        seriesAxisMapping = const {};

  /// Bounds for each axis, keyed by axis ID.
  final Map<String, AxisBounds> axisBounds;

  /// Maps series ID to axis ID.
  final Map<String, String> seriesAxisMapping;

  /// Gets bounds for a specific axis.
  AxisBounds? getBounds(String axisId) => axisBounds[axisId];

  /// Gets the axis ID for a series.
  String? getAxisForSeries(String seriesId) => seriesAxisMapping[seriesId];

  /// Whether any bounds are defined.
  bool get isEmpty => axisBounds.isEmpty;

  /// Whether all axes have valid bounds.
  bool get allValid => axisBounds.values.every((b) => b.isValid);

  @override
  String toString() =>
      'MultiAxisBounds(axes: ${axisBounds.keys.join(', ')}, series: ${seriesAxisMapping.length})';
}

/// Calculator for computing per-axis bounds from series data.
///
/// Handles:
/// - Series-to-axis binding via [ChartSeries.yAxisId]
/// - Default axis assignment for series without yAxisId
/// - Explicit bounds from [YAxisConfig.min]/[YAxisConfig.max]
/// - Computed bounds from series Y-values
///
/// Example:
/// ```dart
/// final calculator = AxisBoundsCalculator(
///   axisConfigs: [powerAxis, heartRateAxis],
///   series: [powerSeries, hrSeries],
/// );
///
/// final bounds = calculator.compute();
/// print('Power bounds: ${bounds.getBounds('power')}');
/// ```
class AxisBoundsCalculator {
  /// Creates an axis bounds calculator.
  ///
  /// [axisConfigs] defines the available axes.
  /// [series] is the list of data series to compute bounds from.
  AxisBoundsCalculator({
    required this.axisConfigs,
    required this.series,
  });

  /// The axis configurations.
  final List<YAxisConfig> axisConfigs;

  /// The data series.
  final List<ChartSeries> series;

  /// Default axis ID to use when series has no yAxisId.
  ///
  /// Returns the ID of the first axis, or 'default' if no axes defined.
  String get defaultAxisId {
    if (axisConfigs.isEmpty) return 'default';
    // Prefer left or leftOuter position as default
    for (final config in axisConfigs) {
      if (config.position == YAxisPosition.left) return config.id;
    }
    for (final config in axisConfigs) {
      if (config.position == YAxisPosition.leftOuter) return config.id;
    }
    return axisConfigs.first.id;
  }

  /// Computes bounds for all axes.
  ///
  /// For each axis:
  /// 1. Finds all series bound to it (via yAxisId or default)
  /// 2. Uses explicit min/max from config if provided
  /// 3. Otherwise computes min/max from series Y-values
  /// 4. Applies padding (5%) to computed bounds for visual margin
  ///
  /// Returns [MultiAxisBounds] with per-axis bounds and series mapping.
  MultiAxisBounds compute({double paddingPercent = 0.05}) {
    final axisBoundsMap = <String, AxisBounds>{};
    final seriesAxisMap = <String, String>{};

    // Group series by axis ID
    final seriesByAxis = <String, List<ChartSeries>>{};
    for (final s in series) {
      final axisId = s.yAxisId ?? defaultAxisId;
      seriesAxisMap[s.id] = axisId;
      seriesByAxis.putIfAbsent(axisId, () => []).add(s);
    }

    // Compute bounds for each axis
    for (final config in axisConfigs) {
      final boundSeries = seriesByAxis[config.id] ?? [];
      final bounds = _computeAxisBounds(config, boundSeries, paddingPercent);
      axisBoundsMap[config.id] = bounds;
    }

    // Handle any axis with no bound series (use explicit bounds or default)
    for (final config in axisConfigs) {
      if (!axisBoundsMap.containsKey(config.id)) {
        axisBoundsMap[config.id] = _computeAxisBounds(config, [], paddingPercent);
      }
    }

    return MultiAxisBounds(
      axisBounds: axisBoundsMap,
      seriesAxisMapping: seriesAxisMap,
    );
  }

  /// Computes bounds for a single axis.
  AxisBounds _computeAxisBounds(
    YAxisConfig config,
    List<ChartSeries> boundSeries,
    double paddingPercent,
  ) {
    // If explicit bounds are configured, use them
    if (config.min != null && config.max != null) {
      return AxisBounds(
        axisId: config.id,
        min: config.min!,
        max: config.max!,
        seriesIds: boundSeries.map((s) => s.id).toList(),
      );
    }

    // Compute bounds from series data
    if (boundSeries.isEmpty) {
      // No series bound - use explicit bounds or default
      return AxisBounds(
        axisId: config.id,
        min: config.min ?? 0.0,
        max: config.max ?? 1.0,
        seriesIds: const [],
      );
    }

    // Find min/max Y across all bound series
    double minY = double.infinity;
    double maxY = double.negativeInfinity;

    for (final s in boundSeries) {
      for (final point in s.points) {
        if (point.y < minY) minY = point.y;
        if (point.y > maxY) maxY = point.y;
      }
    }

    // Handle degenerate cases
    if (minY == double.infinity || maxY == double.negativeInfinity) {
      return AxisBounds(
        axisId: config.id,
        min: config.min ?? 0.0,
        max: config.max ?? 1.0,
        seriesIds: boundSeries.map((s) => s.id).toList(),
      );
    }

    // Handle flat data (all same Y value)
    if (minY == maxY) {
      final value = minY;
      if (value == 0) {
        minY = -1.0;
        maxY = 1.0;
      } else {
        minY = value - value.abs() * 0.1;
        maxY = value + value.abs() * 0.1;
      }
    }

    // Override with explicit bounds if provided
    if (config.min != null) minY = config.min!;
    if (config.max != null) maxY = config.max!;

    // Apply padding for visual margin
    final range = maxY - minY;
    final padding = range * paddingPercent;

    // Only apply padding to computed bounds (not explicit)
    final paddedMin = config.min ?? (minY - padding);
    final paddedMax = config.max ?? (maxY + padding);

    return AxisBounds(
      axisId: config.id,
      min: paddedMin,
      max: paddedMax,
      seriesIds: boundSeries.map((s) => s.id).toList(),
    );
  }

  /// Computes the range ratio between two axes.
  ///
  /// Returns how many times larger the range of [axisIdA] is compared to [axisIdB].
  /// Useful for auto-detection of when normalization is needed.
  ///
  /// Example:
  /// ```dart
  /// final ratio = calculator.computeRangeRatio(bounds, 'power', 'heartRate');
  /// if (ratio > 10.0) {
  ///   // Normalization recommended
  /// }
  /// ```
  double computeRangeRatio(
    MultiAxisBounds bounds,
    String axisIdA,
    String axisIdB,
  ) {
    final boundsA = bounds.getBounds(axisIdA);
    final boundsB = bounds.getBounds(axisIdB);

    if (boundsA == null || boundsB == null) return 1.0;
    if (boundsB.range == 0) return double.infinity;

    return boundsA.range / boundsB.range;
  }

  /// Computes the maximum range ratio across all axis pairs.
  ///
  /// Returns the largest ratio between any two axes' ranges.
  /// Useful for auto-detection threshold (e.g., >10x triggers normalization).
  double computeMaxRangeRatio(MultiAxisBounds bounds) {
    if (bounds.axisBounds.length < 2) return 1.0;

    double maxRatio = 1.0;
    final axisIds = bounds.axisBounds.keys.toList();

    for (int i = 0; i < axisIds.length; i++) {
      for (int j = i + 1; j < axisIds.length; j++) {
        final ratio = computeRangeRatio(bounds, axisIds[i], axisIds[j]);
        if (ratio > maxRatio) maxRatio = ratio;
        if (ratio > 0 && (1 / ratio) > maxRatio) maxRatio = 1 / ratio;
      }
    }

    return maxRatio;
  }
}
