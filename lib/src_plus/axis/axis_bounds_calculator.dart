/// Axis bounds calculation utility for multi-axis charts.
///
/// Computes per-axis min/max bounds from series data based on
/// axis-series binding via [ChartSeries.yAxisId].
///
/// See also:
/// - [YAxisConfig] for axis configuration
/// - [MultiAxisState] for runtime axis state
library;

import 'dart:ui' show Offset;

import '../axis/y_axis_config.dart';
import '../models/chart_series.dart';
import '../models/y_axis_position.dart';

/// Represents computed bounds for a single axis.
///
/// Used for both static computation from points and instance-based
/// multi-axis bound computation.
class AxisBounds {
  /// Creates axis bounds with just min/max values.
  const AxisBounds({
    required this.min,
    required this.max,
  })  : axisId = null,
        seriesIds = const [];

  /// Creates axis bounds with axis ID and series tracking.
  const AxisBounds.forAxis({
    required String this.axisId,
    required this.min,
    required this.max,
    this.seriesIds = const [],
  });

  /// Creates default bounds (0-1) when no data is available.
  const AxisBounds.empty()
      : axisId = null,
        min = 0.0,
        max = 1.0,
        seriesIds = const [];

  /// Creates default bounds (0-1) for a specific axis.
  const AxisBounds.emptyForAxis(String this.axisId)
      : min = 0.0,
        max = 1.0,
        seriesIds = const [];

  /// The axis identifier (optional, for multi-axis use).
  final String? axisId;

  /// The minimum Y value across all bound series.
  final double min;

  /// The maximum Y value across all bound series.
  final double max;

  /// IDs of series bound to this axis.
  final List<String> seriesIds;

  /// The range span (max - min).
  double get range => max - min;

  /// The center value of the bounds.
  double get center => (min + max) / 2;

  /// Whether bounds are valid (max > min).
  bool get isValid => max > min;

  /// Whether this represents default empty bounds.
  bool get isEmpty => seriesIds.isEmpty && axisId == null;

  /// Whether a value is within the bounds (inclusive).
  bool contains(double value) => value >= min && value <= max;

  /// Creates a copy with optional modifications.
  AxisBounds copyWith({
    String? axisId,
    double? min,
    double? max,
    List<String>? seriesIds,
  }) {
    return AxisBounds.forAxis(
      axisId: axisId ?? this.axisId ?? '',
      min: min ?? this.min,
      max: max ?? this.max,
      seriesIds: seriesIds ?? this.seriesIds,
    );
  }

  @override
  String toString() {
    if (axisId != null) {
      return 'AxisBounds(id: $axisId, min: $min, max: $max, series: $seriesIds)';
    }
    return 'AxisBounds(min: $min, max: $max)';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is AxisBounds && runtimeType == other.runtimeType && min == other.min && max == other.max;

  @override
  int get hashCode => Object.hash(min, max);
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
  String toString() => 'MultiAxisBounds(axes: ${axisBounds.keys.join(', ')}, series: ${seriesAxisMapping.length})';
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
      return AxisBounds.forAxis(
        axisId: config.id,
        min: config.min!,
        max: config.max!,
        seriesIds: boundSeries.map((s) => s.id).toList(),
      );
    }

    // Compute bounds from series data
    if (boundSeries.isEmpty) {
      // No series bound - use explicit bounds or default
      return AxisBounds.forAxis(
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
      return AxisBounds.forAxis(
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

    return AxisBounds.forAxis(
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

  // ============================================
  // STATIC API (for testing and convenience)
  // ============================================

  /// Computes bounds from a list of points (Y values).
  ///
  /// Static method for simple bounds computation without axis configuration.
  ///
  /// [paddingPercent] adds margin as a percentage of the range (0-100).
  /// [useNiceBounds] rounds bounds to "nice" numbers for cleaner axis labels.
  static AxisBounds computeBoundsFromPoints(
    List<Offset> data, {
    double paddingPercent = 0.0,
    bool useNiceBounds = false,
  }) {
    if (data.isEmpty) {
      return const AxisBounds(min: 0.0, max: 1.0);
    }

    double minY = double.infinity;
    double maxY = double.negativeInfinity;

    for (final point in data) {
      if (point.dy < minY) minY = point.dy;
      if (point.dy > maxY) maxY = point.dy;
    }

    if (minY == double.infinity || maxY == double.negativeInfinity) {
      return const AxisBounds(min: 0.0, max: 1.0);
    }

    // Apply padding
    if (paddingPercent > 0 && minY != maxY) {
      final range = maxY - minY;
      final padding = range * (paddingPercent / 100.0);
      minY -= padding;
      maxY += padding;
    }

    // Apply nice bounds
    if (useNiceBounds && minY != maxY) {
      minY = _niceFloor(minY);
      maxY = _niceCeil(maxY);
    }

    return AxisBounds(min: minY, max: maxY);
  }

  /// Rounds down to a "nice" number for axis labels.
  static double _niceFloor(double value) {
    if (value == 0) return 0;
    final magnitude = _pow10((_log10(value.abs()).floor()));
    final normalized = value / magnitude;
    final niceNormalized = (normalized * 10).floor() / 10;
    return niceNormalized * magnitude;
  }

  /// Rounds up to a "nice" number for axis labels.
  static double _niceCeil(double value) {
    if (value == 0) return 0;
    final magnitude = _pow10((_log10(value.abs()).floor()));
    final normalized = value / magnitude;
    final niceNormalized = (normalized * 10).ceil() / 10;
    return niceNormalized * magnitude;
  }

  /// Power of 10.
  static double _pow10(int exponent) {
    double result = 1.0;
    if (exponent >= 0) {
      for (int i = 0; i < exponent; i++) {
        result *= 10.0;
      }
    } else {
      for (int i = 0; i > exponent; i--) {
        result /= 10.0;
      }
    }
    return result;
  }

  /// Log base 10.
  static double _log10(double x) {
    // log10(x) = ln(x) / ln(10)
    return _ln(x) / 2.302585092994046; // ln(10)
  }

  /// Natural log approximation.
  static double _ln(double x) {
    if (x <= 0) return double.negativeInfinity;
    // Use series expansion for ln(x)
    int exp = 0;
    while (x > 2) {
      x /= 2;
      exp++;
    }
    while (x < 1) {
      x *= 2;
      exp--;
    }
    // ln(x) for 1 <= x <= 2 using Taylor series
    final y = x - 1;
    double sum = 0;
    double term = y;
    for (int i = 1; i <= 20; i++) {
      sum += term / i;
      term *= -y;
    }
    return sum + exp * 0.6931471805599453; // ln(2)
  }

  /// Computes bounds for multiple axes from config and series data.
  ///
  /// Static method for computing bounds when data is provided as a map.
  ///
  /// [configs] defines the axes.
  /// [seriesData] maps axis ID to list of points (Y values in dy).
  static Map<String, AxisBounds> computeAllBounds(
    List<YAxisConfig> configs,
    Map<String, List<Offset>> seriesData,
  ) {
    final result = <String, AxisBounds>{};

    for (final config in configs) {
      final data = seriesData[config.id] ?? [];

      // Use explicit config bounds if provided
      if (config.min != null && config.max != null) {
        result[config.id] = AxisBounds(min: config.min!, max: config.max!);
        continue;
      }

      // Compute from data
      if (data.isEmpty) {
        result[config.id] = const AxisBounds(min: 0.0, max: 1.0);
        continue;
      }

      result[config.id] = computeBoundsFromPoints(data);
    }

    return result;
  }

  /// Resolves which axis a series should bind to.
  ///
  /// Returns the axis ID if the series' yAxisId exists in available axes,
  /// null otherwise.
  static String? resolveSeriesAxisBinding<T>(
    T series,
    List<String> availableAxisIds,
  ) {
    // Handle both ChartSeries and mock objects
    String? yAxisId;
    if (series is ChartSeries) {
      yAxisId = series.yAxisId;
    } else {
      // Use reflection-like approach for mock objects
      try {
        yAxisId = (series as dynamic).yAxisId as String?;
      } catch (_) {
        return null;
      }
    }

    if (yAxisId != null && availableAxisIds.contains(yAxisId)) {
      return yAxisId;
    }
    return null;
  }

  /// Computes automatic axis assignments for all series.
  ///
  /// Assigns series to axes based on:
  /// 1. Explicit yAxisId
  /// 2. Unit matching (series.unit == config.unit)
  /// 3. Default to first left-positioned axis
  static Map<String, String> computeAutoAxisAssignments<T>(
    List<T> series,
    List<YAxisConfig> configs,
  ) {
    if (configs.isEmpty) return {};

    // Build lookup maps
    final axisIds = configs.map((c) => c.id).toSet();
    final unitToAxis = <String, String>{};
    for (final c in configs) {
      if (c.unit != null) unitToAxis[c.unit!] = c.id;
    }

    // Find default axis (prefer left position)
    String? defaultAxis;
    for (final c in configs) {
      if (c.position == YAxisPosition.left) {
        defaultAxis = c.id;
        break;
      }
    }
    defaultAxis ??= configs.first.id;

    final assignments = <String, String>{};

    for (final s in series) {
      String id;
      String? yAxisId;
      String? unit;

      // Extract properties (handle both ChartSeries and mocks)
      if (s is ChartSeries) {
        id = s.id;
        yAxisId = s.yAxisId;
        unit = s.unit;
      } else {
        try {
          final dynamic d = s;
          id = d.id as String;
          yAxisId = d.yAxisId as String?;
          unit = d.unit as String?;
        } catch (_) {
          continue;
        }
      }

      // 1. Explicit binding
      if (yAxisId != null && axisIds.contains(yAxisId)) {
        assignments[id] = yAxisId;
        continue;
      }

      // 2. Unit matching
      if (unit != null && unitToAxis.containsKey(unit)) {
        assignments[id] = unitToAxis[unit]!;
        continue;
      }

      // 3. Default
      assignments[id] = defaultAxis;
    }

    return assignments;
  }
}
