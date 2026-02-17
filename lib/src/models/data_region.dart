// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

import 'package:equatable/equatable.dart';

import 'chart_data_point.dart';

/// Identifies how a [DataRegion] was created.
///
/// Each source type represents a different mechanism for defining
/// a region of interest within a chart:
///
/// - [rangeAnnotation]: A pre-defined annotated range on the chart.
/// - [segment]: A segment of a chart series (e.g., between two data points).
/// - [boxSelect]: A user-drawn selection box on the chart.
enum DataRegionSource {
  /// Region defined by a range annotation on the chart.
  rangeAnnotation,

  /// Region defined by a chart series segment.
  segment,

  /// Region defined by a user box-selection gesture.
  boxSelect,
}

/// Represents a region of interest within a chart, defined by an X-axis range.
///
/// A [DataRegion] encapsulates a horizontal span of the chart between
/// [startX] and [endX], identified by a unique [id], along with the
/// [source] that created it and optional [seriesData] containing the
/// data points that fall within this region.
///
/// **Equality** is based on [id], [startX], [endX], and [source] only.
/// The [label] and [seriesData] fields are excluded from equality
/// because they are considered derived or presentational data.
///
/// **Validation**: [startX] must be less than or equal to [endX], and
/// [id] must be non-empty. A zero-width region (`startX == endX`) is
/// valid and represents a single-point query.
///
/// Example:
/// ```dart
/// final region = DataRegion(
///   id: 'peak-zone',
///   label: 'Peak Power Zone',
///   startX: 100.0,
///   endX: 200.0,
///   source: DataRegionSource.rangeAnnotation,
///   seriesData: {
///     'power': [
///       ChartDataPoint(x: 120.0, y: 350.0),
///       ChartDataPoint(x: 150.0, y: 400.0),
///     ],
///   },
/// );
/// ```
class DataRegion extends Equatable {
  /// Creates a [DataRegion] with the given parameters.
  ///
  /// [id] must be a non-empty string uniquely identifying this region.
  /// [startX] must be less than or equal to [endX].
  /// [source] indicates how this region was created.
  /// [seriesData] maps series identifiers to their data points within
  /// this region. Defaults to an empty map if not provided.
  /// [label] is an optional human-readable label for display.
  DataRegion({
    required this.id,
    this.label,
    required this.startX,
    required this.endX,
    required this.source,
    required this.seriesData,
  }) : assert(id.isNotEmpty, 'id must be non-empty'),
       assert(startX <= endX, 'startX must be <= endX');

  /// Unique identifier for this region.
  final String id;

  /// Optional human-readable label for display purposes.
  final String? label;

  /// The start of the X-axis range (inclusive).
  final double startX;

  /// The end of the X-axis range (inclusive).
  final double endX;

  /// How this region was created.
  final DataRegionSource source;

  /// Data points within this region, keyed by series identifier.
  ///
  /// Each entry maps a series ID to the list of [ChartDataPoint]s
  /// that fall within the [startX]–[endX] range for that series.
  final Map<String, List<ChartDataPoint>> seriesData;

  /// Creates a copy of this [DataRegion] with optional field overrides.
  ///
  /// Any parameter not provided retains its current value.
  ///
  /// Example:
  /// ```dart
  /// final updated = region.copyWith(
  ///   label: 'Updated Label',
  ///   endX: 250.0,
  /// );
  /// ```
  DataRegion copyWith({
    String? id,
    String? label,
    double? startX,
    double? endX,
    DataRegionSource? source,
    Map<String, List<ChartDataPoint>>? seriesData,
  }) {
    return DataRegion(
      id: id ?? this.id,
      label: label ?? this.label,
      startX: startX ?? this.startX,
      endX: endX ?? this.endX,
      source: source ?? this.source,
      seriesData: seriesData ?? this.seriesData,
    );
  }

  @override
  List<Object?> get props => [id, startX, endX, source];
}
