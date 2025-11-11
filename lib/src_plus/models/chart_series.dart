// Copyright 2025 Braven Charts - Simplified for BravenChartPlus
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';

import 'chart_data_point.dart';

/// Line interpolation modes for smooth curve rendering.
enum LineInterpolation {
  /// Straight lines between points.
  linear,

  /// Smooth bezier curves with Catmull-Rom splines.
  bezier,

  /// Horizontal then vertical stepped lines.
  stepped,

  /// Monotone cubic interpolation (preserves monotonicity).
  monotone,
}

/// Sealed base class for all chart series types.
///
/// This provides type-safe series configuration with exhaustive pattern matching.
/// Each concrete subtype has only the properties applicable to that series type.
sealed class ChartSeries {
  const ChartSeries({
    required this.id,
    this.name,
    required this.points,
    this.color,
    this.isXOrdered = false,
    this.metadata,
  });

  final String id;
  final String? name;
  final List<ChartDataPoint> points;
  final Color? color;
  final bool isXOrdered;
  final Map<String, dynamic>? metadata;

  int get length => points.length;
  bool get isEmpty => points.isEmpty;
  bool get isNotEmpty => points.isNotEmpty;
  String get displayName => name ?? id;

  @override
  String toString() => 'ChartSeries(id: $id, points: ${points.length})';
}

/// Line chart series with interpolation and marker configuration.
final class LineChartSeries extends ChartSeries {
  const LineChartSeries({
    required super.id,
    super.name,
    required super.points,
    super.color,
    super.isXOrdered,
    super.metadata,
    this.interpolation = LineInterpolation.linear,
    this.tension = 0.5,
    this.strokeWidth = 2.0,
    this.showDataPointMarkers = false,
    this.dataPointMarkerRadius = 4.0,
  })  : assert(tension >= 0.0 && tension <= 1.0, 'Tension must be between 0.0 and 1.0'),
        assert(strokeWidth > 0, 'Stroke width must be positive'),
        assert(dataPointMarkerRadius > 0, 'Marker radius must be positive');

  /// How to interpolate between data points.
  final LineInterpolation interpolation;

  /// Tension for bezier curves (0.0 = angular, 1.0 = very smooth).
  final double tension;

  /// Line stroke width in pixels.
  final double strokeWidth;

  /// Whether to render markers at each data point.
  final bool showDataPointMarkers;

  /// Radius of data point markers in pixels.
  final double dataPointMarkerRadius;

  @override
  String toString() => 'LineChartSeries(id: $id, points: ${points.length}, interpolation: $interpolation)';
}

/// Bar chart series with width configuration.
final class BarChartSeries extends ChartSeries {
  const BarChartSeries({
    required super.id,
    super.name,
    required super.points,
    super.color,
    super.isXOrdered,
    super.metadata,
    this.barWidthPixels,
    this.barWidthPercent,
    this.minWidth = 2.0,
    this.maxWidth = double.infinity,
  })  : assert(
          barWidthPixels != null || barWidthPercent != null,
          'Must specify either barWidthPixels or barWidthPercent',
        ),
        assert(
          barWidthPixels == null || barWidthPercent == null,
          'Cannot specify both barWidthPixels and barWidthPercent',
        ),
        assert(
          barWidthPixels == null || barWidthPixels > 0,
          'Bar width in pixels must be positive',
        ),
        assert(
          barWidthPercent == null || (barWidthPercent > 0.0 && barWidthPercent <= 1.0),
          'Bar width percent must be between 0.0 and 1.0',
        ),
        assert(minWidth > 0, 'Minimum width must be positive'),
        assert(maxWidth > 0, 'Maximum width must be positive'),
        assert(minWidth <= maxWidth, 'Minimum width must be <= maximum width');

  /// Explicit bar width in pixels (scales with zoom).
  final double? barWidthPixels;

  /// Bar width as percentage of X-axis spacing (0.0-1.0).
  final double? barWidthPercent;

  /// Minimum bar width in pixels (prevents invisible bars).
  final double minWidth;

  /// Maximum bar width in pixels (prevents overlapping bars).
  final double maxWidth;

  @override
  String toString() => 'BarChartSeries(id: $id, points: ${points.length}, '
      'width: ${barWidthPixels != null ? "${barWidthPixels}px" : "${barWidthPercent! * 100}%"})';
}

/// Scatter chart series with marker configuration.
final class ScatterChartSeries extends ChartSeries {
  const ScatterChartSeries({
    required super.id,
    super.name,
    required super.points,
    super.color,
    super.isXOrdered,
    super.metadata,
    this.markerRadius = 6.0,
    this.strokeWidth = 2.0,
  })  : assert(markerRadius > 0, 'Marker radius must be positive'),
        assert(strokeWidth > 0, 'Stroke width must be positive');

  /// Radius of scatter point markers in pixels.
  final double markerRadius;

  /// Stroke width for marker outline in pixels.
  final double strokeWidth;

  @override
  String toString() => 'ScatterChartSeries(id: $id, points: ${points.length}, radius: $markerRadius)';
}

/// Area chart series with fill and line configuration.
final class AreaChartSeries extends ChartSeries {
  const AreaChartSeries({
    required super.id,
    super.name,
    required super.points,
    super.color,
    super.isXOrdered,
    super.metadata,
    this.interpolation = LineInterpolation.linear,
    this.tension = 0.5,
    this.fillOpacity = 0.3,
    this.strokeWidth = 2.0,
    this.showDataPointMarkers = false,
    this.dataPointMarkerRadius = 4.0,
  })  : assert(tension >= 0.0 && tension <= 1.0, 'Tension must be between 0.0 and 1.0'),
        assert(fillOpacity >= 0.0 && fillOpacity <= 1.0, 'Fill opacity must be between 0.0 and 1.0'),
        assert(strokeWidth > 0, 'Stroke width must be positive'),
        assert(dataPointMarkerRadius > 0, 'Marker radius must be positive');

  /// How to interpolate between data points.
  final LineInterpolation interpolation;

  /// Tension for bezier curves (0.0 = angular, 1.0 = very smooth).
  final double tension;

  /// Opacity of the filled area (0.0 = transparent, 1.0 = opaque).
  final double fillOpacity;

  /// Line stroke width in pixels.
  final double strokeWidth;

  /// Whether to render markers at each data point.
  final bool showDataPointMarkers;

  /// Radius of data point markers in pixels.
  final double dataPointMarkerRadius;

  @override
  String toString() => 'AreaChartSeries(id: $id, points: ${points.length}, interpolation: $interpolation)';
}
