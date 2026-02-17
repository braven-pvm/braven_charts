// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

/// Stateless utility for analyzing data within chart regions.
///
/// Provides methods for filtering data points by X-range, computing
/// per-series statistical summaries, and aggregating results into
/// [RegionSummary] objects.
///
/// All methods are stateless — data is provided by the caller and
/// analysis is performed on-demand. No internal caching or persistence.
library;

import '../models/chart_annotation.dart';
import '../models/chart_data_point.dart';
import '../models/data_region.dart';

/// Stateless utility class for region data analysis.
///
/// Computes statistical summaries for data points within a
/// specified X-axis range. Supports binary search for sorted
/// data and linear scan for unsorted data.
///
/// Example:
/// ```dart
/// const analyzer = RegionAnalyzer();
/// final filtered = analyzer.filterPointsInRange(
///   points,
///   startX: 2.0,
///   endX: 8.0,
/// );
/// ```
class RegionAnalyzer {
  /// Creates a [RegionAnalyzer] instance.
  const RegionAnalyzer();

  /// Filter data points within an X-range.
  ///
  /// Uses binary search when [isSorted] is true (default), linear scan
  /// otherwise. Returns points where `startX <= point.x <= endX`.
  ///
  /// [points] is the list of data points to filter.
  /// [startX] is the inclusive start of the X-range.
  /// [endX] is the inclusive end of the X-range.
  /// [isSorted] controls whether to use binary search (true) or linear
  /// scan (false). Defaults to true.
  ///
  /// **Performance**: For sorted data, uses O(log n + k) binary search
  /// where k is the number of matching points. For unsorted data, uses
  /// O(n) linear scan.
  ///
  /// Example:
  /// ```dart
  /// const analyzer = RegionAnalyzer();
  /// final points = [
  ///   ChartDataPoint(x: 1, y: 10),
  ///   ChartDataPoint(x: 2, y: 20),
  ///   ChartDataPoint(x: 3, y: 30),
  /// ];
  /// final filtered = analyzer.filterPointsInRange(
  ///   points,
  ///   startX: 1.5,
  ///   endX: 2.5,
  /// );
  /// // Returns: [ChartDataPoint(x: 2, y: 20)]
  /// ```
  List<ChartDataPoint> filterPointsInRange(
    List<ChartDataPoint> points, {
    required double startX,
    required double endX,
    bool isSorted = true,
  }) {
    if (points.isEmpty) {
      return [];
    }

    if (isSorted) {
      return _binarySearchFilter(points, startX, endX);
    }

    return _linearScanFilter(points, startX, endX);
  }

  /// Binary search filter for sorted data — O(log n + k).
  ///
  /// Finds the first point with x >= startX using binary search,
  /// then scans forward collecting all points until x > endX.
  List<ChartDataPoint> _binarySearchFilter(
    List<ChartDataPoint> points,
    double startX,
    double endX,
  ) {
    // Binary search for the first index where point.x >= startX
    int low = 0;
    int high = points.length;

    while (low < high) {
      final mid = low + (high - low) ~/ 2;
      if (points[mid].x < startX) {
        low = mid + 1;
      } else {
        high = mid;
      }
    }

    // low is now the first index where point.x >= startX
    // Scan forward collecting points until x > endX
    final result = <ChartDataPoint>[];
    for (int i = low; i < points.length; i++) {
      if (points[i].x > endX) {
        break;
      }
      result.add(points[i]);
    }

    return result;
  }

  /// Linear scan filter for unsorted data — O(n).
  ///
  /// Iterates all points and includes those where startX <= x <= endX.
  List<ChartDataPoint> _linearScanFilter(
    List<ChartDataPoint> points,
    double startX,
    double endX,
  ) {
    return points.where((p) => p.x >= startX && p.x <= endX).toList();
  }

  /// Build a [DataRegion] from a [RangeAnnotation] and the chart's series data.
  ///
  /// Filters each series via [filterPointsInRange], excluding series with
  /// zero matching points from the result's [DataRegion.seriesData] map.
  ///
  /// [annotation] is the range annotation defining the X-range.
  /// [allSeriesData] maps series identifiers to their data points.
  ///
  /// The resulting [DataRegion] has:
  /// - [DataRegion.id] derived from the annotation ID
  /// - [DataRegion.source] set to [DataRegionSource.rangeAnnotation]
  /// - [DataRegion.startX] and [DataRegion.endX] from the annotation
  /// - [DataRegion.seriesData] containing only series with matching points
  ///
  /// Example:
  /// ```dart
  /// const analyzer = RegionAnalyzer();
  /// final annotation = RangeAnnotation(
  ///   id: 'peak-zone',
  ///   startX: 100.0,
  ///   endX: 200.0,
  /// );
  /// final region = analyzer.regionFromAnnotation(
  ///   annotation,
  ///   {'power': powerPoints, 'heartrate': hrPoints},
  /// );
  /// ```
  DataRegion regionFromAnnotation(
    RangeAnnotation annotation,
    Map<String, List<ChartDataPoint>> allSeriesData,
  ) {
    final startX = annotation.startX!;
    final endX = annotation.endX!;

    final seriesData = <String, List<ChartDataPoint>>{};

    for (final entry in allSeriesData.entries) {
      final filtered = filterPointsInRange(
        entry.value,
        startX: startX,
        endX: endX,
      );

      // Exclude series with zero matching points
      if (filtered.isNotEmpty) {
        seriesData[entry.key] = filtered;
      }
    }

    return DataRegion(
      id: 'region-${annotation.id}',
      label: annotation.label,
      startX: startX,
      endX: endX,
      source: DataRegionSource.rangeAnnotation,
      seriesData: seriesData,
    );
  }
}
