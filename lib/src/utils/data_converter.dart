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
  /// For bar charts, adds extra X padding to ensure edge bars aren't clipped.
  /// The padding is based on the average spacing between data points (bar width).
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
    double xPadding = (xMax - xMin) * 0.05;
    final yPadding = (yMax - yMin) * 0.05;

    // For bar charts, ensure minimum X padding based on bar width (spacing)
    // so edge bars aren't clipped. Bars are centered on data points, so we
    // need at least half a bar width of padding on each side.
    final hasBarSeries = series.any((s) => s is BarChartSeries);
    if (hasBarSeries) {
      // Calculate average X spacing from all bar series
      double totalSpacing = 0;
      int spacingCount = 0;

      for (final s in series) {
        if (s is BarChartSeries && s.points.length >= 2) {
          // Sort points by X to calculate spacing correctly
          final sortedPoints = [...s.points]
            ..sort((a, b) => a.x.compareTo(b.x));
          for (int i = 1; i < sortedPoints.length; i++) {
            totalSpacing += sortedPoints[i].x - sortedPoints[i - 1].x;
            spacingCount++;
          }
        }
      }

      if (spacingCount > 0) {
        final avgSpacing = totalSpacing / spacingCount;
        // Bar width is typically 80% of spacing, we need half that for edge padding
        // Plus a small buffer (10%) for visual comfort
        final barPadding = avgSpacing * 0.5;
        // Use whichever is larger: percentage padding or bar-based padding
        xPadding = xPadding > barPadding ? xPadding : barPadding;
      }
    }

    return DataBounds(
      xMin: xMin - xPadding,
      xMax: xMax + xPadding,
      yMin: yMin - yPadding,
      yMax: yMax + yPadding,
    );
  }
}

/// Data bounds for chart viewport setup.
class DataBounds {
  const DataBounds({
    required this.xMin,
    required this.xMax,
    required this.yMin,
    required this.yMax,
  });

  final double xMin;
  final double xMax;
  final double yMin;
  final double yMax;
}
