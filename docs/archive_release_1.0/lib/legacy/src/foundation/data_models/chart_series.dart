// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

import 'package:braven_charts/legacy/src/foundation/data_models/chart_data_point.dart';
import 'package:braven_charts/legacy/src/foundation/data_models/data_range.dart'
    as dr;
import 'package:braven_charts/legacy/src/foundation/type_system/chart_error.dart';
import 'package:braven_charts/legacy/src/foundation/type_system/chart_result.dart';
import 'package:braven_charts/legacy/src/widgets/annotations/chart_annotation.dart';
import 'package:flutter/material.dart';

/// Rendering style hints for series visualization.
enum SeriesStyle {
  line,
  bar,
  scatter,
  area,
}

/// Collection of related ChartDataPoint objects representing a data series.
///
/// ChartSeries is an immutable container for chart data with computed
/// properties for efficient rendering and analysis.
///
/// Example:
/// ```dart
/// final series = ChartSeries(
///   id: 'revenue-2024',
///   name: 'Revenue',
///   points: [
///     ChartDataPoint(x: 1.0, y: 100.0),
///     ChartDataPoint(x: 2.0, y: 150.0),
///   ],
///   color: Colors.blue,
///   isXOrdered: true,
/// );
/// ```
class ChartSeries {
  /// Creates a chart series with required id and points.
  ///
  /// [id] must not be empty.
  /// [points] can be empty but must not be null.
  /// If [isXOrdered] is true, points should be sorted by x-value.
  ChartSeries({
    required this.id,
    this.name,
    required this.points,
    this.color,
    this.style,
    this.isXOrdered = false,
    this.metadata,
    this.annotations = const [],
  }) : assert(id.isNotEmpty, 'id must not be empty');

  /// Unique identifier for the series.
  final String id;

  /// Display name (e.g., "Revenue 2024").
  final String? name;

  /// Ordered list of data points.
  final List<ChartDataPoint> points;

  /// Suggested rendering color.
  final Color? color;

  /// Rendering style hints (line, bar, scatter, area).
  final SeriesStyle? style;

  /// True if points are sorted by x-value (enables optimizations).
  final bool isXOrdered;

  /// Optional custom metadata.
  final Map<String, dynamic>? metadata;

  /// Annotations specific to this series.
  ///
  /// **Preferred Pattern**: Attach annotations directly to the series they reference.
  /// This provides better encapsulation and eliminates the need for `seriesId` lookups.
  ///
  /// Example:
  /// ```dart
  /// ChartSeries(
  ///   id: 'temperature',
  ///   points: [...],
  ///   annotations: [
  ///     TrendAnnotation(
  ///       id: 'temp_trend',
  ///       trendType: TrendType.linear,
  ///     ),
  ///     ThresholdAnnotation(
  ///       id: 'target',
  ///       value: 28.0,
  ///     ),
  ///   ],
  /// )
  /// ```
  ///
  /// **Migration Note**: Chart-level annotations (BravenChart.annotations) are still
  /// supported for backwards compatibility and global annotations that don't belong
  /// to a specific series.
  final List<ChartAnnotation> annotations;

  // Cached computed properties
  dr.DataRange? _xRange;
  dr.DataRange? _yRange;

  /// Returns true if the series has no data points.
  bool get isEmpty => points.isEmpty;

  /// Returns the number of data points in the series.
  int get length => points.length;

  /// Returns the range of x-values in this series.
  ///
  /// Computed on first access and cached for performance.
  dr.DataRange get xRange {
    _xRange ??= dr.DataRange.fromPoints(points, dr.Axis.x);
    return _xRange!;
  }

  /// Returns the range of y-values in this series.
  ///
  /// Computed on first access and cached for performance.
  dr.DataRange get yRange {
    _yRange ??= dr.DataRange.fromPoints(points, dr.Axis.y);
    return _yRange!;
  }

  /// Validates that points are sorted by x-value if [isXOrdered] is true.
  ///
  /// Returns true if:
  /// - [isXOrdered] is false (no ordering requirement), OR
  /// - [isXOrdered] is true AND points are sorted by x ascending
  bool validateOrdering() {
    if (!isXOrdered || points.length <= 1) {
      return true;
    }

    for (var i = 1; i < points.length; i++) {
      if (points[i].x < points[i - 1].x) {
        return false;
      }
    }

    return true;
  }

  /// Validates this series.
  ///
  /// Returns Success if valid, Failure if:
  /// - id is empty
  /// - points list is null
  /// - isXOrdered is true but points are not sorted
  ChartResult<void> validate() {
    // Validate id
    if (id.isEmpty) {
      return Failure(
        ChartError.validation(
          'ChartSeries id must not be empty',
          code: 'SERIES_EMPTY_ID',
        ),
      );
    }

    // Validate ordering if required
    if (isXOrdered && !validateOrdering()) {
      return Failure(
        ChartError.validation(
          'ChartSeries points are not sorted by x-value',
          code: 'SERIES_NOT_ORDERED',
          context: {'id': id, 'isXOrdered': isXOrdered},
        ),
      );
    }

    // Validate that all points are valid (finite numbers)
    for (var i = 0; i < points.length; i++) {
      final point = points[i];
      if (!point.isValid) {
        return Failure(
          ChartError.validation(
            'ChartSeries contains invalid point at index $i',
            code: 'SERIES_INVALID_POINT',
            context: {
              'id': id,
              'index': i,
              'x': point.x,
              'y': point.y,
            },
          ),
        );
      }
    }

    return const Success(null);
  }

  /// Creates a copy of this series with optional property overrides.
  ///
  /// Example:
  /// ```dart
  /// final modified = series.copyWith(
  ///   color: Colors.red,
  ///   points: newPoints,
  /// );
  /// ```
  ChartSeries copyWith({
    String? id,
    String? name,
    List<ChartDataPoint>? points,
    Color? color,
    SeriesStyle? style,
    bool? isXOrdered,
    Map<String, dynamic>? metadata,
    List<ChartAnnotation>? annotations,
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
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChartSeries &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          _listEquals(points, other.points) &&
          color == other.color &&
          style == other.style &&
          isXOrdered == other.isXOrdered;
  // Note: metadata is intentionally excluded from equality

  @override
  int get hashCode => Object.hash(
        id,
        name,
        Object.hashAll(points),
        color,
        style,
        isXOrdered,
      );

  @override
  String toString() {
    return 'ChartSeries(id: "$id", points: ${points.length}, '
        'isXOrdered: $isXOrdered)';
  }

  // Helper for list equality
  bool _listEquals(List<ChartDataPoint> a, List<ChartDataPoint> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
