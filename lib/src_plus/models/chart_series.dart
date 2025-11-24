// Copyright 2025 Braven Charts - Simplified for BravenChartPlus
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';

import 'chart_annotation.dart';
import 'chart_data_point.dart';

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
  });

  final String id;
  final String? name;
  final List<ChartDataPoint> points;
  final Color? color;
  final SeriesStyle? style;
  final bool isXOrdered;
  final Map<String, dynamic>? metadata;
  final List<ChartAnnotation> annotations;

  int get length => points.length;
  bool get isEmpty => points.isEmpty;
  bool get isNotEmpty => points.isNotEmpty;
  String get displayName => name ?? id;
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
    this.interpolation = LineInterpolation.linear,
    this.strokeWidth = 2.0,
    this.tension = 0.5,
    this.showDataPointMarkers = false,
    this.dataPointMarkerRadius = 3.0,
  });

  final LineInterpolation interpolation;
  final double strokeWidth;
  final double tension; // Used for bezier curves (0.0 = straight, 1.0 = very smooth)
  final bool showDataPointMarkers;
  final double dataPointMarkerRadius;

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
    this.markerRadius = 5.0,
  });

  final double markerRadius;

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
    this.interpolation = LineInterpolation.linear,
    this.strokeWidth = 2.0,
    this.tension = 0.5,
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
  String toString() => 'BarChartSeries(id: $id, points: ${points.length}, barWidth: ${barWidthPercent ?? barWidthPixels})';
}
