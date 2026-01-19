// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

import 'package:braven_charts/legacy/src/foundation/data_models/chart_data_point.dart';
import 'package:braven_charts/legacy/src/foundation/data_models/chart_series.dart';
import 'package:braven_charts/legacy/src/foundation/type_system/chart_error.dart';
import 'package:braven_charts/legacy/src/foundation/type_system/chart_result.dart';

/// Time-based dataset with DateTime x-axis values.
///
/// TimeSeriesData is a specialized container for temporal data where
/// the x-axis represents timestamps. It provides aggregation and
/// conversion capabilities.
///
/// Example:
/// ```dart
/// final timeSeries = TimeSeriesData(
///   id: 'temperature-readings',
///   data: [
///     ChartDataPoint(
///       x: 1.0,
///       y: 21.5,
///       timestamp: DateTime(2024, 1, 1, 12, 0),
///       label: 'Noon reading',
///     ),
///   ],
/// );
/// ```
class TimeSeriesData {
  /// Unique identifier for this time series.
  final String id;

  /// Display name for this time series.
  final String? name;

  /// Time-ordered list of data points with timestamps.
  final List<ChartDataPoint> data;

  /// Optional custom metadata.
  final Map<String, dynamic>? metadata;

  /// Creates a time series with required id and data.
  ///
  /// [id] must not be empty.
  /// [data] can be empty but must not be null.
  /// All points in [data] should have timestamps.
  TimeSeriesData({
    required this.id,
    this.name,
    required this.data,
    this.metadata,
  }) : assert(id.isNotEmpty, 'id must not be empty');

  /// Returns true if this time series has no data points.
  bool get isEmpty => data.isEmpty;

  /// Returns the number of data points in this time series.
  int get length => data.length;

  /// Returns the earliest timestamp in this series, or null if empty.
  DateTime? get startTime {
    if (data.isEmpty) return null;

    DateTime? earliest;
    for (final point in data) {
      if (point.hasTimestamp) {
        if (earliest == null || point.timestamp!.isBefore(earliest)) {
          earliest = point.timestamp;
        }
      }
    }
    return earliest;
  }

  /// Returns the latest timestamp in this series, or null if empty.
  DateTime? get endTime {
    if (data.isEmpty) return null;

    DateTime? latest;
    for (final point in data) {
      if (point.hasTimestamp) {
        if (latest == null || point.timestamp!.isAfter(latest)) {
          latest = point.timestamp;
        }
      }
    }
    return latest;
  }

  /// Returns the time span covered by this series, or null if empty.
  ///
  /// Calculated as the duration between [startTime] and [endTime].
  Duration? get timeSpan {
    final start = startTime;
    final end = endTime;
    if (start == null || end == null) return null;
    return end.difference(start);
  }

  /// Validates this time series data.
  ///
  /// Returns Success if valid, Failure if:
  /// - id is empty
  /// - any data point is invalid (non-finite x or y)
  /// - any data point is missing a timestamp
  ChartResult<void> validate() {
    // Validate id
    if (id.isEmpty) {
      return Failure(
        ChartError.validation(
          'TimeSeriesData id must not be empty',
          code: 'TIMESERIES_EMPTY_ID',
        ),
      );
    }

    // Validate all points have timestamps and are valid
    for (var i = 0; i < data.length; i++) {
      final point = data[i];

      // Check for missing timestamp
      if (!point.hasTimestamp) {
        return Failure(
          ChartError.validation(
            'TimeSeriesData point at index $i is missing timestamp',
            code: 'TIMESERIES_MISSING_TIMESTAMP',
            context: {
              'id': id,
              'index': i,
            },
          ),
        );
      }

      // Check for invalid point values
      if (!point.isValid) {
        return Failure(
          ChartError.validation(
            'TimeSeriesData contains invalid point at index $i',
            code: 'TIMESERIES_INVALID_POINT',
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

  /// Converts this time series to a ChartSeries.
  ///
  /// The x-values will be converted to milliseconds since Unix epoch
  /// for numerical plotting.
  ///
  /// Example:
  /// ```dart
  /// final chartSeries = timeSeries.toChartSeries(
  ///   color: Colors.blue,
  ///   style: SeriesStyle.line,
  /// );
  /// ```
  ChartSeries toChartSeries({
    String? seriesId,
    String? seriesName,
    dynamic color,
    SeriesStyle? style,
  }) {
    // Convert timestamp to milliseconds for x-axis
    final convertedPoints = data.map((point) {
      final x = point.hasTimestamp
          ? point.timestamp!.millisecondsSinceEpoch.toDouble()
          : point.x;

      return ChartDataPoint(
        x: x,
        y: point.y,
        timestamp: point.timestamp,
        label: point.label,
        metadata: point.metadata,
      );
    }).toList();

    return ChartSeries(
      id: seriesId ?? id,
      name: seriesName ?? name,
      points: convertedPoints,
      color: color,
      style: style,
      isXOrdered: true, // Time series are typically ordered
      metadata: metadata,
    );
  }

  /// Creates a copy of this time series with optional property overrides.
  ///
  /// Example:
  /// ```dart
  /// final modified = timeSeries.copyWith(
  ///   name: 'Updated Name',
  ///   data: newDataPoints,
  /// );
  /// ```
  TimeSeriesData copyWith({
    String? id,
    String? name,
    List<ChartDataPoint>? data,
    Map<String, dynamic>? metadata,
  }) {
    return TimeSeriesData(
      id: id ?? this.id,
      name: name ?? this.name,
      data: data ?? this.data,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TimeSeriesData &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          _listEquals(data, other.data);
  // Note: metadata is intentionally excluded from equality

  @override
  int get hashCode => Object.hash(
        id,
        name,
        Object.hashAll(data),
      );

  @override
  String toString() {
    final start = startTime?.toIso8601String() ?? 'null';
    final end = endTime?.toIso8601String() ?? 'null';
    return 'TimeSeriesData(id: "$id", points: ${data.length}, '
        'startTime: $start, endTime: $end)';
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
