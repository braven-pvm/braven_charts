// Copyright (c) 2025 braven_charts. All rights reserved.
// BravenChartPlus - Data Conversion Utilities

import '../coordinates/chart_transform.dart';
import '../elements/series_element.dart';
import '../interaction/core/coordinator.dart';
import '../models/bar_group_info.dart';
import '../models/chart_series.dart';
import '../models/chart_theme.dart';

/// Converts ChartSeries data to SeriesElements for rendering.
///
/// **Purpose**: Bridge between data model (ChartSeries) and rendering
/// system (SeriesElement + QuadTree).
///
/// **Usage**:
/// ```dart
/// final seriesElements = DataConverter.seriesToElements(
///   series: chartData,
///   transform: transform,
/// );
/// // Insert into QuadTree for hit testing
/// for (final element in seriesElements) {
///   spatialIndex.insert(element);
/// }
/// ```
class DataConverter {
  const DataConverter._();

  /// Converts a list of ChartSeries to SeriesElements.
  ///
  /// Each ChartSeries becomes one SeriesElement that wraps the entire
  /// series for rendering and interaction.
  ///
  /// **Parameters**:
  /// - `series`: List of ChartSeries to convert
  /// - `transform`: Current ChartTransform for coordinate conversion
  /// - `theme`: Optional ChartTheme for styling (uses theme.seriesTheme for colors/widths/markers)
  /// - `coordinator`: Optional interaction coordinator for per-marker hover state
  ///
  /// **Returns**: List of SeriesElements ready for spatial index insertion
  static List<SeriesElement> seriesToElements({
    required List<ChartSeries> series,
    required ChartTransform transform,
    ChartTheme? theme,
    @Deprecated('Use theme.seriesTheme instead') double? strokeWidth,
    ChartInteractionCoordinator? coordinator,
  }) {
    // First pass: Count total bar series for grouping
    final barSeriesCount = series.whereType<BarChartSeries>().length;

    // Track bar series index for grouping
    int barSeriesIndex = 0;

    // Use theme.seriesTheme if available, otherwise backward compatibility mode
    return series.asMap().entries.map((entry) {
      final index = entry.key;
      final s = entry.value;

      // Compute BarGroupInfo for bar series (needed for grouped rendering)
      BarGroupInfo? barGroupInfo;
      if (s is BarChartSeries && barSeriesCount > 0) {
        barGroupInfo = BarGroupInfo(
          index: barSeriesIndex,
          count: barSeriesCount,
          gap: 2.0, // Default 2px gap per FR-003 specification
        );
        barSeriesIndex++;
      }

      return SeriesElement(
        series: s,
        transform: transform,
        seriesTheme: theme?.seriesTheme,
        seriesIndex: index,
        coordinator: coordinator,
        barGroupInfo: barGroupInfo,
      );
    }).toList();
  }

  /// Computes data bounds from all series.
  ///
  /// Finds min/max X and Y values across all series for setting up
  /// the initial ChartTransform viewport.
  ///
  /// **Returns**: DataBounds with xMin, xMax, yMin, yMax
  static DataBounds computeDataBounds(List<ChartSeries> series) {
    if (series.isEmpty || series.every((s) => s.isEmpty)) {
      return const DataBounds(xMin: 0, xMax: 1, yMin: 0, yMax: 1);
    }

    double xMin = double.infinity;
    double xMax = double.negativeInfinity;
    double yMin = double.infinity;
    double yMax = double.negativeInfinity;

    for (final s in series) {
      for (final point in s.points) {
        if (point.x < xMin) xMin = point.x;
        if (point.x > xMax) xMax = point.x;
        if (point.y < yMin) yMin = point.y;
        if (point.y > yMax) yMax = point.y;
      }
    }

    // Add 5% padding to data bounds for visual breathing room
    final xPadding = (xMax - xMin) * 0.05;
    final yPadding = (yMax - yMin) * 0.05;

    return DataBounds(
        xMin: xMin - xPadding,
        xMax: xMax + xPadding,
        yMin: yMin - yPadding,
        yMax: yMax + yPadding);
  }
}

/// Data bounds for chart viewport setup.
class DataBounds {
  const DataBounds(
      {required this.xMin,
      required this.xMax,
      required this.yMin,
      required this.yMax});

  final double xMin;
  final double xMax;
  final double yMin;
  final double yMax;
}
