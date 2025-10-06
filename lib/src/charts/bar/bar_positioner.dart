/// Bar chart layout and positioning utilities
library;

import 'dart:ui' show Rect;

import 'bar_chart_config.dart' show BarOrientation, BarGroupingMode;

/// Represents calculated bar positions and dimensions.
///
/// Used internally by BarPositioner for rendering. Contains all information
/// needed to draw a single bar, including its bounds, associated data value,
/// and metadata about its position in the chart.
class BarLayoutInfo {
  /// Creates a bar layout info.
  const BarLayoutInfo({
    required this.seriesId,
    required this.categoryIndex,
    required this.bounds,
    required this.value,
    required this.isNegative,
  });

  /// The ID of the series this bar belongs to.
  final String seriesId;

  /// The index of the category this bar represents.
  final int categoryIndex;

  /// The bar rectangle in screen coordinates.
  final Rect bounds;

  /// The original data value this bar represents.
  final double value;

  /// Whether the value is negative (value < 0).
  final bool isNegative;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BarLayoutInfo &&
        other.seriesId == seriesId &&
        other.categoryIndex == categoryIndex &&
        other.bounds == bounds &&
        other.value == value &&
        other.isNegative == isNegative;
  }

  @override
  int get hashCode => Object.hash(
        seriesId,
        categoryIndex,
        bounds,
        value,
        isNegative,
      );

  @override
  String toString() {
    return 'BarLayoutInfo('
        'seriesId: $seriesId, '
        'categoryIndex: $categoryIndex, '
        'bounds: $bounds, '
        'value: $value, '
        'isNegative: $isNegative'
        ')';
  }
}

/// Bar chart positioning calculator for grouped and stacked modes
///
/// Calculates bar positions and dimensions for bar charts with support for:
/// - Grouped (side-by-side) bars
/// - Stacked (cumulative) bars
/// - Horizontal and vertical orientations
/// - Positive and negative value handling
///
/// Constitutional requirement: Performance optimization
class BarPositioner {
  /// Creates a bar positioner with configuration
  const BarPositioner({
    required this.orientation,
    required this.groupingMode,
    required this.barWidthRatio,
    required this.barSpacing,
    required this.groupSpacing,
  });

  /// Chart orientation (vertical or horizontal)
  final BarOrientation orientation;

  /// Grouping mode (grouped or stacked)
  final BarGroupingMode groupingMode;

  /// Bar width as percentage of category width (0.0, 1.0]
  final double barWidthRatio;

  /// Spacing between bars in a group (pixels)
  final double barSpacing;

  /// Spacing between category groups (pixels)
  final double groupSpacing;

  /// Calculates layout for all bars in the chart
  ///
  /// Parameters:
  /// - [seriesData]: List of series, each containing values for each category
  /// - [categoryWidth]: Width allocated for each category
  /// - [chartHeight]: Total chart height (for vertical bars)
  /// - [baseline]: Y-coordinate of the baseline (typically 0 value line)
  ///
  /// Returns: List of BarLayoutInfo with positions for all bars
  ///
  /// Algorithm:
  /// - Grouped mode: Bars placed side-by-side within category
  /// - Stacked mode: Bars stacked cumulatively (positive up, negative down)
  List<BarLayoutInfo> calculateLayout({
    required List<List<double>> seriesData,
    required double categoryWidth,
    required double chartHeight,
    required double baseline,
  }) {
    if (seriesData.isEmpty) {
      return [];
    }

    // Find the minimum length across all series
    final minLength = seriesData.fold<int>(
      seriesData[0].length,
      (min, series) => series.length < min ? series.length : min,
    );

    if (minLength == 0) {
      return [];
    }

    return groupingMode == BarGroupingMode.grouped
        ? _calculateGroupedLayout(
            seriesData,
            minLength,
            categoryWidth,
            baseline,
          )
        : _calculateStackedLayout(
            seriesData,
            minLength,
            categoryWidth,
            baseline,
          );
  }

  /// Calculates layout for grouped (side-by-side) bars
  List<BarLayoutInfo> _calculateGroupedLayout(
    List<List<double>> seriesData,
    int numCategories,
    double categoryWidth,
    double baseline,
  ) {
    final result = <BarLayoutInfo>[];
    final numSeries = seriesData.length;

    // Calculate individual bar width
    final totalSpacing = barSpacing * (numSeries - 1);
    final availableWidth = categoryWidth * barWidthRatio - totalSpacing;
    final barWidth = availableWidth / numSeries;

    for (int catIndex = 0; catIndex < numCategories; catIndex++) {
      // Calculate starting X position for this category
      final categoryStart = catIndex * categoryWidth;
      final groupStart = categoryStart + (categoryWidth - categoryWidth * barWidthRatio) / 2;

      for (int seriesIndex = 0; seriesIndex < numSeries; seriesIndex++) {
        final value = seriesData[seriesIndex][catIndex];
        final isNegative = value < 0;

        // Calculate bar X position
        final x = groupStart + seriesIndex * (barWidth + barSpacing);

        // Calculate bar Y position and height based on orientation
        final Rect bounds;
        if (orientation == BarOrientation.vertical) {
          if (isNegative) {
            // Negative bar extends downward from baseline
            bounds = Rect.fromLTWH(x, baseline, barWidth, value.abs());
          } else {
            // Positive bar extends upward from baseline
            bounds = Rect.fromLTWH(x, baseline - value, barWidth, value);
          }
        } else {
          // Horizontal orientation
          if (isNegative) {
            // Negative bar extends leftward from baseline
            bounds = Rect.fromLTWH(
              baseline - value.abs(),
              x,
              value.abs(),
              barWidth,
            );
          } else {
            // Positive bar extends rightward from baseline
            bounds = Rect.fromLTWH(baseline, x, value, barWidth);
          }
        }

        result.add(
          BarLayoutInfo(
            seriesId: 'series$seriesIndex',
            categoryIndex: catIndex,
            bounds: bounds,
            value: value,
            isNegative: isNegative,
          ),
        );
      }
    }

    return result;
  }

  /// Calculates layout for stacked (cumulative) bars
  List<BarLayoutInfo> _calculateStackedLayout(
    List<List<double>> seriesData,
    int numCategories,
    double categoryWidth,
    double baseline,
  ) {
    final result = <BarLayoutInfo>[];
    final numSeries = seriesData.length;

    // Calculate bar width
    final barWidth = categoryWidth * barWidthRatio;

    for (int catIndex = 0; catIndex < numCategories; catIndex++) {
      // Calculate X position for this category's stacked bar
      final categoryStart = catIndex * categoryWidth;
      final x = categoryStart + (categoryWidth - barWidth) / 2;

      // Track cumulative positions for positive and negative stacks
      double positiveTop = baseline;
      double negativeBottom = baseline;

      for (int seriesIndex = 0; seriesIndex < numSeries; seriesIndex++) {
        final value = seriesData[seriesIndex][catIndex];
        final isNegative = value < 0;

        final Rect bounds;
        if (orientation == BarOrientation.vertical) {
          if (isNegative) {
            // Stack negative values downward
            bounds = Rect.fromLTWH(
              x,
              negativeBottom,
              barWidth,
              value.abs(),
            );
            negativeBottom += value.abs();
          } else {
            // Stack positive values upward
            bounds = Rect.fromLTWH(
              x,
              positiveTop - value,
              barWidth,
              value,
            );
            positiveTop -= value;
          }
        } else {
          // Horizontal orientation
          if (isNegative) {
            // Stack negative values leftward
            final left = negativeBottom - value.abs();
            bounds = Rect.fromLTWH(
              left,
              x,
              value.abs(),
              barWidth,
            );
            negativeBottom = left;
          } else {
            // Stack positive values rightward
            bounds = Rect.fromLTWH(
              positiveTop,
              x,
              value,
              barWidth,
            );
            positiveTop += value;
          }
        }

        result.add(
          BarLayoutInfo(
            seriesId: 'series$seriesIndex',
            categoryIndex: catIndex,
            bounds: bounds,
            value: value,
            isNegative: isNegative,
          ),
        );
      }
    }

    return result;
  }
}
