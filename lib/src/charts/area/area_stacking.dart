/// Area chart stacking algorithm for cumulative stacking
library;

import 'dart:ui' show Offset;

import 'area_chart_config.dart' show AreaBaseline, AreaBaselineType;

/// Stacks area chart series data for cumulative area charts
///
/// Implements the stacking algorithm for area charts where multiple series
/// are stacked on top of each other. Positive and negative values are
/// handled separately, creating separate stacks above and below the baseline.
///
/// Constitutional requirement: Performance optimization (object pooling, caching)
class AreaStacking {
  /// Creates an area stacking calculator
  const AreaStacking();

  /// Stacks multiple series data cumulatively
  ///
  /// Takes a list of series (each series is a list of points) and returns
  /// the stacked data. The result includes:
  /// - Each series with stacked y-values
  /// - A final baseline series
  ///
  /// Algorithm:
  /// 1. First series remains unchanged
  /// 2. Subsequent series stack on top of previous values
  /// 3. Positive values stack upward, negative values stack downward
  /// 4. Final entry is the baseline points
  ///
  /// Parameters:
  /// - [seriesData]: List of series, each containing data points
  /// - [baseline]: Baseline configuration (defaults to zero)
  /// - [seriesIds]: Optional series IDs (required for series-based baseline)
  ///
  /// Returns: List of stacked series + baseline (length = seriesData.length + 1)
  ///
  /// Edge cases:
  /// - Empty list: Returns empty list
  /// - Single series: Returns [series, baseline]
  /// - Different lengths: Uses shortest series length
  List<List<Offset>> stack(
    List<List<Offset>> seriesData, {
    AreaBaseline baseline = const AreaBaseline.zero(),
    List<String>? seriesIds,
  }) {
    if (seriesData.isEmpty) {
      return [];
    }

    // Find the minimum length across all series
    final minLength = seriesData.fold<int>(
      seriesData[0].length,
      (min, series) => series.length < min ? series.length : min,
    );

    // If no data points, return empty
    if (minLength == 0) {
      return [];
    }

    // Initialize result list with capacity for all series + baseline
    final result = <List<Offset>>[];

    // Track cumulative values at each x position
    // Separate accumulators for positive and negative stacks
    final positiveStack = List<double>.filled(minLength, 0.0);
    final negativeStack = List<double>.filled(minLength, 0.0);

    // Stack each series
    for (int seriesIndex = 0; seriesIndex < seriesData.length; seriesIndex++) {
      final series = seriesData[seriesIndex];
      final stackedSeries = <Offset>[];

      for (int i = 0; i < minLength; i++) {
        final point = series[i];
        final value = point.dy;

        // Stack positive and negative values separately
        final double stackedY;
        if (value >= 0) {
          positiveStack[i] += value;
          stackedY = positiveStack[i];
        } else {
          negativeStack[i] += value;
          stackedY = negativeStack[i];
        }

        stackedSeries.add(Offset(point.dx, stackedY));
      }

      result.add(stackedSeries);
    }

    // Add baseline as the last entry
    final baselinePoints = _calculateBaseline(
      seriesData,
      minLength,
      baseline,
      seriesIds,
    );
    result.add(baselinePoints);

    return result;
  }

  /// Calculates baseline points based on baseline configuration
  ///
  /// Returns a list of points representing the baseline for the area chart.
  ///
  /// Baseline types:
  /// - [AreaBaselineType.zero]: All y-values are 0
  /// - [AreaBaselineType.fixed]: All y-values are the fixed value
  /// - [AreaBaselineType.series]: Use the specified series' y-values
  List<Offset> _calculateBaseline(
    List<List<Offset>> seriesData,
    int length,
    AreaBaseline baseline,
    List<String>? seriesIds,
  ) {
    switch (baseline.type) {
      case AreaBaselineType.zero:
        return _createZeroBaseline(seriesData[0], length);

      case AreaBaselineType.fixed:
        return _createFixedBaseline(
          seriesData[0],
          length,
          baseline.fixedValue!,
        );

      case AreaBaselineType.series:
        return _createSeriesBaseline(
          seriesData,
          length,
          baseline.seriesId!,
          seriesIds,
        );
    }
  }

  /// Creates a baseline at y=0
  List<Offset> _createZeroBaseline(List<Offset> referencePoints, int length) {
    return List.generate(
      length,
      (i) => Offset(referencePoints[i].dx, 0),
    );
  }

  /// Creates a baseline at a fixed y-value
  List<Offset> _createFixedBaseline(
    List<Offset> referencePoints,
    int length,
    double fixedValue,
  ) {
    return List.generate(
      length,
      (i) => Offset(referencePoints[i].dx, fixedValue),
    );
  }

  /// Creates a baseline from another series
  ///
  /// If the specified series is not found, defaults to zero baseline.
  List<Offset> _createSeriesBaseline(
    List<List<Offset>> seriesData,
    int length,
    String targetSeriesId,
    List<String>? seriesIds,
  ) {
    // Find the series index matching targetSeriesId
    if (seriesIds != null) {
      final seriesIndex = seriesIds.indexOf(targetSeriesId);
      if (seriesIndex >= 0 && seriesIndex < seriesData.length) {
        final targetSeries = seriesData[seriesIndex];
        return List.generate(
          length,
          (i) => Offset(targetSeries[i].dx, targetSeries[i].dy),
        );
      }
    }

    // Fallback to zero baseline if series not found
    return _createZeroBaseline(seriesData[0], length);
  }
}
