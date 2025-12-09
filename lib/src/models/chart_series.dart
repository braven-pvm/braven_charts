// Copyright 2025 Braven Charts - Simplified for BravenChartPlus
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';

import 'chart_annotation.dart';
import 'chart_data_point.dart';
import 'y_axis_config.dart';

/// Interpolation methods for line and area charts.
enum LineInterpolation {
  linear,
  bezier,
  stepped,
  monotone,
}

/// Rendering style hints for series visualization.
enum SeriesStyle {
  line,
  bar,
  scatter,
  area,
}

/// Base class for chart series.
///
/// Now concrete to support generic usage like in BravenChart.
/// Supports optional Y-axis binding via [yAxisId] and value formatting
/// via [unit].
class ChartSeries {
  const ChartSeries({
    required this.id,
    this.name,
    required this.points,
    this.color,
    this.style,
    this.isXOrdered = false,
    this.metadata,
    this.annotations = const [],
    this.yAxisId,
    this.yAxisConfig,
    this.unit,
  });

  final String id;
  final String? name;
  final List<ChartDataPoint> points;
  final Color? color;
  final SeriesStyle? style;
  final bool isXOrdered;
  final Map<String, dynamic>? metadata;
  final List<ChartAnnotation> annotations;

  /// Optional Y-axis ID for referencing a shared axis in multi-axis mode.
  ///
  /// Use this when multiple series should share the same Y-axis defined
  /// in [BravenChartPlus.yAxes]. The ID should match a [YAxisConfig.id].
  ///
  /// For series with their own dedicated axis, prefer using [yAxisConfig]
  /// instead, which allows inline axis configuration.
  ///
  /// Example:
  /// ```dart
  /// // Reference a shared axis
  /// LineChartSeries(
  ///   id: 'power',
  ///   points: [...],
  ///   yAxisId: 'shared-axis',  // References YAxisConfig with id='shared-axis'
  /// )
  /// ```
  final String? yAxisId;

  /// Inline Y-axis configuration for this series.
  ///
  /// When set, creates a dedicated Y-axis for this series with the
  /// specified configuration. The axis ID is auto-generated from the
  /// series ID if not explicitly set in the config.
  ///
  /// This is the preferred way to configure axes when each series has
  /// its own axis. For shared axes (multiple series on one axis), use
  /// [yAxisId] to reference axes defined in [BravenChartPlus.yAxes].
  ///
  /// Example:
  /// ```dart
  /// LineChartSeries(
  ///   id: 'power',
  ///   points: [...],
  ///   yAxisConfig: YAxisConfig(
  ///     position: YAxisPosition.left,
  ///     label: 'Power',
  ///     unit: 'W',
  ///   ),
  /// )
  /// ```
  final YAxisConfig? yAxisConfig;

  /// Optional unit suffix for value formatting.
  ///
  /// Used by tooltips and axis labels to display values with units.
  /// Common examples: 'W' (watts), 'bpm' (beats per minute), 'L' (liters).
  ///
  /// Example:
  /// ```dart
  /// LineChartSeries(
  ///   id: 'power',
  ///   points: [...],
  ///   unit: 'W',  // Values displayed as "250 W"
  /// )
  /// ```
  final String? unit;

  int get length => points.length;
  bool get isEmpty => points.isEmpty;
  bool get isNotEmpty => points.isNotEmpty;
  String get displayName => name ?? id;

  /// Creates a copy of this series with specified properties overridden.
  ///
  /// All parameters are optional. Properties not specified retain their
  /// current values.
  ChartSeries copyWith({
    String? id,
    String? name,
    List<ChartDataPoint>? points,
    Color? color,
    SeriesStyle? style,
    bool? isXOrdered,
    Map<String, dynamic>? metadata,
    List<ChartAnnotation>? annotations,
    String? yAxisId,
    YAxisConfig? yAxisConfig,
    String? unit,
  }) {
    return ChartSeries(
      id: id ?? this.id,
      name: name ?? this.name,
      points: points ?? this.points,
      color: color ?? this.color,
      style: style ?? this.style,
      isXOrdered: isXOrdered ?? this.isXOrdered,
      metadata: metadata ?? this.metadata,
      annotations: annotations ?? this.annotations,
      yAxisId: yAxisId ?? this.yAxisId,
      yAxisConfig: yAxisConfig ?? this.yAxisConfig,
      unit: unit ?? this.unit,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ChartSeries &&
        other.id == id &&
        other.name == name &&
        _listEquals(other.points, points) &&
        other.color == color &&
        other.style == style &&
        other.isXOrdered == isXOrdered &&
        _mapEquals(other.metadata, metadata) &&
        _listEquals(other.annotations, annotations) &&
        other.yAxisId == yAxisId &&
        other.yAxisConfig == yAxisConfig &&
        other.unit == unit;
  }

  @override
  int get hashCode => Object.hash(
        id,
        name,
        Object.hashAll(points),
        color,
        style,
        isXOrdered,
        metadata != null ? Object.hashAll(metadata!.entries) : null,
        Object.hashAll(annotations),
        yAxisId,
        yAxisConfig,
        unit,
      );

  /// Helper for list equality comparison.
  static bool _listEquals<T>(List<T>? a, List<T>? b) {
    if (identical(a, b)) return true;
    if (a == null || b == null) return a == b;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  /// Helper for map equality comparison.
  static bool _mapEquals<K, V>(Map<K, V>? a, Map<K, V>? b) {
    if (identical(a, b)) return true;
    if (a == null || b == null) return a == b;
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (!b.containsKey(key) || a[key] != b[key]) return false;
    }
    return true;
  }

  @override
  String toString() => 'ChartSeries(id: $id, points: ${points.length}, yAxisId: $yAxisId, unit: $unit)';
}

/// Line chart series with configurable interpolation.
class LineChartSeries extends ChartSeries {
  const LineChartSeries({
    required super.id,
    super.name,
    required super.points,
    super.color,
    super.isXOrdered = false,
    super.metadata,
    super.yAxisId,
    super.yAxisConfig,
    super.unit,
    this.interpolation = LineInterpolation.linear,
    this.strokeWidth = 2.0,
    this.tension = 0.25,
    this.showDataPointMarkers = false,
    this.dataPointMarkerRadius = 3.0,
  });

  final LineInterpolation interpolation;
  final double strokeWidth;
  final double tension; // Used for bezier curves (0.0 = straight, 1.0 = very smooth)
  final bool showDataPointMarkers;
  final double dataPointMarkerRadius;

  @override
  LineChartSeries copyWith({
    String? id,
    String? name,
    List<ChartDataPoint>? points,
    Color? color,
    SeriesStyle? style,
    bool? isXOrdered,
    Map<String, dynamic>? metadata,
    List<ChartAnnotation>? annotations,
    String? yAxisId,
    YAxisConfig? yAxisConfig,
    String? unit,
    LineInterpolation? interpolation,
    double? strokeWidth,
    double? tension,
    bool? showDataPointMarkers,
    double? dataPointMarkerRadius,
  }) {
    return LineChartSeries(
      id: id ?? this.id,
      name: name ?? this.name,
      points: points ?? this.points,
      color: color ?? this.color,
      isXOrdered: isXOrdered ?? this.isXOrdered,
      metadata: metadata ?? this.metadata,
      yAxisId: yAxisId ?? this.yAxisId,
      yAxisConfig: yAxisConfig ?? this.yAxisConfig,
      unit: unit ?? this.unit,
      interpolation: interpolation ?? this.interpolation,
      strokeWidth: strokeWidth ?? this.strokeWidth,
      tension: tension ?? this.tension,
      showDataPointMarkers: showDataPointMarkers ?? this.showDataPointMarkers,
      dataPointMarkerRadius: dataPointMarkerRadius ?? this.dataPointMarkerRadius,
    );
  }

  @override
  String toString() => 'LineChartSeries(id: $id, points: ${points.length}, interpolation: $interpolation)';
}

/// Scatter plot series with configurable marker size.
class ScatterChartSeries extends ChartSeries {
  const ScatterChartSeries({
    required super.id,
    super.name,
    required super.points,
    super.color,
    super.isXOrdered = false,
    super.metadata,
    super.yAxisId,
    super.yAxisConfig,
    super.unit,
    this.markerRadius = 5.0,
  });

  final double markerRadius;

  @override
  ScatterChartSeries copyWith({
    String? id,
    String? name,
    List<ChartDataPoint>? points,
    Color? color,
    SeriesStyle? style,
    bool? isXOrdered,
    Map<String, dynamic>? metadata,
    List<ChartAnnotation>? annotations,
    String? yAxisId,
    YAxisConfig? yAxisConfig,
    String? unit,
    double? markerRadius,
  }) {
    return ScatterChartSeries(
      id: id ?? this.id,
      name: name ?? this.name,
      points: points ?? this.points,
      color: color ?? this.color,
      isXOrdered: isXOrdered ?? this.isXOrdered,
      metadata: metadata ?? this.metadata,
      yAxisId: yAxisId ?? this.yAxisId,
      yAxisConfig: yAxisConfig ?? this.yAxisConfig,
      unit: unit ?? this.unit,
      markerRadius: markerRadius ?? this.markerRadius,
    );
  }

  @override
  String toString() => 'ScatterChartSeries(id: $id, points: ${points.length}, markerRadius: $markerRadius)';
}

/// Area chart series with fill and interpolation.
class AreaChartSeries extends ChartSeries {
  const AreaChartSeries({
    required super.id,
    super.name,
    required super.points,
    super.color,
    super.isXOrdered = false,
    super.metadata,
    super.yAxisId,
    super.yAxisConfig,
    super.unit,
    this.interpolation = LineInterpolation.linear,
    this.strokeWidth = 2.0,
    this.tension = 0.25,
    this.fillOpacity = 0.3,
    this.showDataPointMarkers = false,
    this.dataPointMarkerRadius = 3.0,
  });

  final LineInterpolation interpolation;
  final double strokeWidth;
  final double tension;
  final double fillOpacity;
  final bool showDataPointMarkers;
  final double dataPointMarkerRadius;

  @override
  AreaChartSeries copyWith({
    String? id,
    String? name,
    List<ChartDataPoint>? points,
    Color? color,
    SeriesStyle? style,
    bool? isXOrdered,
    Map<String, dynamic>? metadata,
    List<ChartAnnotation>? annotations,
    String? yAxisId,
    YAxisConfig? yAxisConfig,
    String? unit,
    LineInterpolation? interpolation,
    double? strokeWidth,
    double? tension,
    double? fillOpacity,
    bool? showDataPointMarkers,
    double? dataPointMarkerRadius,
  }) {
    return AreaChartSeries(
      id: id ?? this.id,
      name: name ?? this.name,
      points: points ?? this.points,
      color: color ?? this.color,
      isXOrdered: isXOrdered ?? this.isXOrdered,
      metadata: metadata ?? this.metadata,
      yAxisId: yAxisId ?? this.yAxisId,
      yAxisConfig: yAxisConfig ?? this.yAxisConfig,
      unit: unit ?? this.unit,
      interpolation: interpolation ?? this.interpolation,
      strokeWidth: strokeWidth ?? this.strokeWidth,
      tension: tension ?? this.tension,
      fillOpacity: fillOpacity ?? this.fillOpacity,
      showDataPointMarkers: showDataPointMarkers ?? this.showDataPointMarkers,
      dataPointMarkerRadius: dataPointMarkerRadius ?? this.dataPointMarkerRadius,
    );
  }

  @override
  String toString() => 'AreaChartSeries(id: $id, points: ${points.length}, interpolation: $interpolation)';
}

/// Bar chart series with configurable width.
class BarChartSeries extends ChartSeries {
  const BarChartSeries({
    required super.id,
    super.name,
    required super.points,
    super.color,
    super.isXOrdered = false,
    super.metadata,
    super.yAxisId,
    super.yAxisConfig,
    super.unit,
    this.barWidthPercent,
    this.barWidthPixels,
    this.minWidth = 4.0,
    this.maxWidth = 100.0,
  })  : assert(barWidthPercent != null || barWidthPixels != null, 'Must specify either barWidthPercent or barWidthPixels'),
        assert(barWidthPercent == null || (barWidthPercent >= 0.0 && barWidthPercent <= 1.0), 'barWidthPercent must be between 0.0 and 1.0');

  final double? barWidthPercent; // Percentage of spacing between points (0.0 - 1.0)
  final double? barWidthPixels; // Fixed width in data units
  final double minWidth; // Minimum bar width in data units
  final double maxWidth; // Maximum bar width in data units

  @override
  BarChartSeries copyWith({
    String? id,
    String? name,
    List<ChartDataPoint>? points,
    Color? color,
    SeriesStyle? style,
    bool? isXOrdered,
    Map<String, dynamic>? metadata,
    List<ChartAnnotation>? annotations,
    String? yAxisId,
    YAxisConfig? yAxisConfig,
    String? unit,
    double? barWidthPercent,
    double? barWidthPixels,
    double? minWidth,
    double? maxWidth,
  }) {
    return BarChartSeries(
      id: id ?? this.id,
      name: name ?? this.name,
      points: points ?? this.points,
      color: color ?? this.color,
      isXOrdered: isXOrdered ?? this.isXOrdered,
      metadata: metadata ?? this.metadata,
      yAxisId: yAxisId ?? this.yAxisId,
      yAxisConfig: yAxisConfig ?? this.yAxisConfig,
      unit: unit ?? this.unit,
      barWidthPercent: barWidthPercent ?? this.barWidthPercent,
      barWidthPixels: barWidthPixels ?? this.barWidthPixels,
      minWidth: minWidth ?? this.minWidth,
      maxWidth: maxWidth ?? this.maxWidth,
    );
  }

  @override
  String toString() => 'BarChartSeries(id: $id, points: ${points.length}, barWidth: ${barWidthPercent ?? barWidthPixels})';
}
