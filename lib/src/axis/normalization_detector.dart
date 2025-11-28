/// Represents the value range of a data series.
///
/// Used by [NormalizationDetector] to analyze whether multiple series
/// need normalization to be displayed together effectively.
///
/// Example:
/// ```dart
/// const powerRange = SeriesRange(
///   seriesId: 'power',
///   min: 0.0,
///   max: 300.0,
/// );
/// print(powerRange.span); // 300.0
/// ```
class SeriesRange {
  /// Creates a series range with the given bounds.
  ///
  /// - [seriesId]: Unique identifier for the data series
  /// - [min]: Minimum value in the series data
  /// - [max]: Maximum value in the series data
  const SeriesRange({
    required this.seriesId,
    required this.min,
    required this.max,
  });

  /// Unique identifier for the data series.
  ///
  /// Corresponds to the series ID used in chart data and axis bindings.
  final String seriesId;

  /// Minimum value in the series data.
  final double min;

  /// Maximum value in the series data.
  final double max;

  /// The span (range) of values in this series.
  ///
  /// Calculated as `max - min`. A span of zero indicates a constant
  /// value series where all data points have the same value.
  double get span => max - min;

  /// Creates a copy of this range with the given fields replaced.
  SeriesRange copyWith({
    String? seriesId,
    double? min,
    double? max,
  }) {
    return SeriesRange(
      seriesId: seriesId ?? this.seriesId,
      min: min ?? this.min,
      max: max ?? this.max,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SeriesRange && other.seriesId == seriesId && other.min == min && other.max == max;
  }

  @override
  int get hashCode => Object.hash(seriesId, min, max);

  @override
  String toString() {
    return 'SeriesRange(seriesId: $seriesId, min: $min, max: $max, span: $span)';
  }
}

/// Detector for determining whether data series need normalization.
///
/// Analyzes the value ranges of multiple data series and determines
/// if their scales are different enough to require normalization for
/// effective visualization on the same chart.
///
/// This is used in conjunction with [NormalizationMode.auto] to
/// automatically enable normalization when needed.
///
/// Example:
/// ```dart
/// final ranges = [
///   SeriesRange(seriesId: 'power', min: 0.0, max: 300.0),      // span: 300
///   SeriesRange(seriesId: 'tidalVolume', min: 0.5, max: 4.0),  // span: 3.5
/// ];
///
/// // Ratio: 300 / 3.5 = 85.7 > 10 (default threshold)
/// final needsNormalization = NormalizationDetector.shouldNormalize(ranges);
/// print(needsNormalization); // true
/// ```
class NormalizationDetector {
  /// Private constructor to prevent instantiation.
  ///
  /// This is a utility class with only static methods.
  NormalizationDetector._();

  /// Determines whether the given series ranges need normalization.
  ///
  /// Compares the largest range span to the smallest range span.
  /// If the ratio exceeds or equals [threshold], returns `true`.
  ///
  /// **Detection Logic:**
  /// - Finds the maximum and minimum non-zero spans
  /// - Calculates ratio: `maxSpan / minSpan`
  /// - Returns `true` if ratio >= [threshold]
  ///
  /// **Edge Cases:**
  /// - Empty list: Returns `false` (nothing to normalize)
  /// - Single series: Returns `false` (nothing to compare)
  /// - All zero spans: Returns `false` (all identical)
  /// - One zero span with non-zero: Returns `true` (infinite ratio)
  ///
  /// Parameters:
  /// - [ranges]: List of series ranges to analyze
  /// - [threshold]: The ratio threshold above which normalization is needed.
  ///   Defaults to 10.0, meaning if the largest span is 10x or more than
  ///   the smallest, normalization is recommended.
  ///
  /// Returns `true` if normalization is recommended, `false` otherwise.
  static bool shouldNormalize(
    List<SeriesRange> ranges, {
    double threshold = 10.0,
  }) {
    // Edge case: empty list or single series
    if (ranges.length < 2) {
      return false;
    }

    // Extract all spans
    final spans = ranges.map((r) => r.span).toList();

    // Find min and max spans
    double minSpan = double.infinity;
    double maxSpan = 0.0;

    for (final span in spans) {
      if (span < minSpan) minSpan = span;
      if (span > maxSpan) maxSpan = span;
    }

    // Edge case: all spans are zero (all constant value series)
    if (maxSpan == 0.0) {
      return false;
    }

    // Edge case: minimum span is zero (at least one constant value series)
    // This creates an infinite ratio, so normalization is definitely needed
    if (minSpan == 0.0) {
      return true;
    }

    // Calculate ratio and compare to threshold
    final ratio = maxSpan / minSpan;
    return ratio >= threshold;
  }
}
