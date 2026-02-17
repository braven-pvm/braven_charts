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

import 'dart:math' as math;

import '../models/chart_annotation.dart';
import '../models/chart_data_point.dart';
import '../models/data_region.dart';
import '../models/region_summary.dart';
import '../models/segment_style.dart';

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

  /// Computes statistical summary metrics for a single series.
  ///
  /// Calculates all 11 metrics (count, min, max, sum, average, range,
  /// stdDev, firstY, lastY, delta, duration) from the given [points].
  ///
  /// Returns null if [points] is empty (no data to summarise).
  ///
  /// **Null rules**:
  /// - [SeriesRegionSummary.stdDev] is null when count < 2.
  /// - [SeriesRegionSummary.delta] is null when count < 2.
  /// - [SeriesRegionSummary.firstY] and [SeriesRegionSummary.lastY] are
  ///   always non-null when count >= 1 (null only when count == 0, but
  ///   that case returns null from this method).
  ///
  /// **Standard deviation**: Uses population formula
  /// (`sqrt(Σ(yi − mean)² / N)`) — not sample formula (`N − 1`).
  ///
  /// **Duration**: Computed from [regionStartX] / [regionEndX] (the
  /// parent region's bounds), NOT from data point X values.
  ///
  /// [points] is the list of data points to analyse.
  /// [seriesId] uniquely identifies the series.
  /// [regionStartX] is the inclusive start of the parent region's X-range.
  /// [regionEndX] is the inclusive end of the parent region's X-range.
  /// [seriesName] is an optional human-readable name for the series.
  /// [unit] is an optional unit of measurement (e.g., 'W', '°C').
  ///
  /// Example:
  /// ```dart
  /// const analyzer = RegionAnalyzer();
  /// final summary = analyzer.computeSeriesSummary(
  ///   [
  ///     ChartDataPoint(x: 1, y: 10),
  ///     ChartDataPoint(x: 2, y: 20),
  ///     ChartDataPoint(x: 3, y: 30),
  ///   ],
  ///   seriesId: 'power',
  ///   regionStartX: 0.0,
  ///   regionEndX: 5.0,
  /// );
  /// // summary!.average == 20.0, summary!.duration == 5.0
  /// ```
  SeriesRegionSummary? computeSeriesSummary(
    List<ChartDataPoint> points, {
    required String seriesId,
    required double regionStartX,
    required double regionEndX,
    String? seriesName,
    String? unit,
  }) {
    if (points.isEmpty) {
      return null;
    }

    final count = points.length;

    double minY = points.first.y;
    double maxY = points.first.y;
    double sum = 0.0;

    for (final point in points) {
      final y = point.y;
      if (y < minY) minY = y;
      if (y > maxY) maxY = y;
      sum += y;
    }

    final average = sum / count;
    final range = maxY - minY;
    final duration = regionEndX - regionStartX;

    final firstY = points.first.y;
    final lastY = points.last.y;

    // stdDev and delta require count >= 2
    double? stdDev;
    double? delta;

    if (count >= 2) {
      // Population standard deviation: sqrt(Σ(yi − mean)² / N)
      double sumSquaredDiffs = 0.0;
      for (final point in points) {
        final diff = point.y - average;
        sumSquaredDiffs += diff * diff;
      }
      stdDev = math.sqrt(sumSquaredDiffs / count);
      delta = lastY - firstY;
    }

    return SeriesRegionSummary(
      seriesId: seriesId,
      seriesName: seriesName,
      unit: unit,
      count: count,
      min: minY,
      max: maxY,
      sum: sum,
      average: average,
      range: range,
      stdDev: stdDev,
      firstY: firstY,
      lastY: lastY,
      delta: delta,
      duration: duration,
    );
  }

  /// Computes an aggregated [RegionSummary] for all series in a [DataRegion].
  ///
  /// Iterates each series in [region.seriesData], calls
  /// [computeSeriesSummary] per series, and omits series with zero data
  /// points from the result.
  ///
  /// Optional [seriesNames] and [seriesUnits] maps are passed through to
  /// each [SeriesRegionSummary] for display purposes.
  ///
  /// [region] is the [DataRegion] to analyse.
  /// [seriesNames] maps series identifiers to human-readable names.
  /// [seriesUnits] maps series identifiers to measurement units.
  ///
  /// Example:
  /// ```dart
  /// const analyzer = RegionAnalyzer();
  /// final regionSummary = analyzer.computeRegionSummary(
  ///   myRegion,
  ///   seriesNames: {'power': 'Power Output'},
  ///   seriesUnits: {'power': 'W'},
  /// );
  /// ```
  RegionSummary computeRegionSummary(
    DataRegion region, {
    Map<String, String>? seriesNames,
    Map<String, String>? seriesUnits,
  }) {
    final seriesSummaries = <String, SeriesRegionSummary>{};

    for (final entry in region.seriesData.entries) {
      final summary = computeSeriesSummary(
        entry.value,
        seriesId: entry.key,
        regionStartX: region.startX,
        regionEndX: region.endX,
        seriesName: seriesNames?[entry.key],
        unit: seriesUnits?[entry.key],
      );

      // Omit series with zero data points (computeSeriesSummary returns null)
      if (summary != null) {
        seriesSummaries[entry.key] = summary;
      }
    }

    return RegionSummary(region: region, seriesSummaries: seriesSummaries);
  }

  /// Detects contiguous segment groups in a series.
  ///
  /// Iterates [points], grouping consecutive points with the same non-null
  /// [SegmentStyle] by value equality. Returns a [DataRegion] for each
  /// group with [DataRegionSource.segment] as source.
  ///
  /// **Grouping rules**:
  /// - Consecutive points sharing the same [SegmentStyle] form one group.
  /// - Non-adjacent groups with the same style are kept separate (FR-017).
  /// - Points with `segmentStyle == null` are excluded and break contiguity.
  /// - Single-point segments are valid (`startX == endX`).
  ///
  /// **ID format**: `'segment_<seriesId>_<startIndex>'` where startIndex is
  /// the index of the first point in the group within [points].
  ///
  /// [seriesId] uniquely identifies the series.
  /// [points] is the list of data points to scan.
  ///
  /// Example:
  /// ```dart
  /// const analyzer = RegionAnalyzer();
  /// final groups = analyzer.detectSegmentGroups('power', styledPoints);
  /// // Returns List<DataRegion> for each contiguous styled group
  /// ```
  List<DataRegion> detectSegmentGroups(
    String seriesId,
    List<ChartDataPoint> points,
  ) {
    if (points.isEmpty) {
      return [];
    }

    final groups = <DataRegion>[];

    int? groupStartIndex;
    SegmentStyle? currentStyle;

    for (int i = 0; i < points.length; i++) {
      final point = points[i];
      final style = point.segmentStyle;

      if (style != null && style == currentStyle) {
        // Continue the current group — same non-null style
        continue;
      }

      // Flush the previous group (if any) before starting a new one
      if (groupStartIndex != null) {
        final groupPoints = points.sublist(groupStartIndex, i);
        groups.add(
          DataRegion(
            id: 'segment_${seriesId}_$groupStartIndex',
            startX: groupPoints.first.x,
            endX: groupPoints.last.x,
            source: DataRegionSource.segment,
            seriesData: {seriesId: groupPoints},
          ),
        );
      }

      // Start a new group or reset
      if (style != null) {
        groupStartIndex = i;
        currentStyle = style;
      } else {
        groupStartIndex = null;
        currentStyle = null;
      }
    }

    // Flush the last group if it extends to the end of the list
    if (groupStartIndex != null) {
      final groupPoints = points.sublist(groupStartIndex);
      groups.add(
        DataRegion(
          id: 'segment_${seriesId}_$groupStartIndex',
          startX: groupPoints.first.x,
          endX: groupPoints.last.x,
          source: DataRegionSource.segment,
          seriesData: {seriesId: groupPoints},
        ),
      );
    }

    return groups;
  }

  /// Finds which segment group (if any) contains the given point index.
  ///
  /// Scans [points] for contiguous styled groups and returns the
  /// [DataRegion] whose index range includes [pointIndex], or `null`
  /// if the point has no segment style.
  ///
  /// [seriesId] uniquely identifies the series.
  /// [points] is the list of data points to scan.
  /// [pointIndex] is the index of the point to look up.
  ///
  /// Example:
  /// ```dart
  /// const analyzer = RegionAnalyzer();
  /// final region = analyzer.segmentGroupForPoint('power', points, 5);
  /// // Returns DataRegion if point 5 is in a styled group, else null
  /// ```
  DataRegion? segmentGroupForPoint(
    String seriesId,
    List<ChartDataPoint> points,
    int pointIndex,
  ) {
    if (pointIndex < 0 || pointIndex >= points.length) {
      return null;
    }

    // Quick check: if the target point has no segment style, return null
    if (points[pointIndex].segmentStyle == null) {
      return null;
    }

    // Delegate to detectSegmentGroups and find the group containing pointIndex
    final groups = detectSegmentGroups(seriesId, points);

    for (final group in groups) {
      // Check if pointIndex falls within this group's index range.
      // The group's seriesData contains the actual points; we need
      // to check by X-value range and point identity.
      final groupPoints = group.seriesData[seriesId]!;
      // The group contains consecutive points starting from the
      // start index embedded in the ID.
      final idParts = group.id.split('_');
      final startIdx = int.parse(idParts.last);
      final endIdx = startIdx + groupPoints.length - 1;

      if (pointIndex >= startIdx && pointIndex <= endIdx) {
        return group;
      }
    }

    return null;
  }
}
