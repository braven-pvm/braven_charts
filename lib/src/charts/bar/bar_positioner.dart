/// Bar chart layout and positioning utilities
library;

import 'dart:ui' show Rect;

/// Represents calculated bar positions and dimensions.
///
/// Used internally by BarPositioner for rendering. Contains all information
/// needed to draw a single bar, including its bounds, associated data value,
/// and metadata about its position in the chart.
class BarLayoutInfo {
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

  /// Creates a bar layout info.
  const BarLayoutInfo({
    required this.seriesId,
    required this.categoryIndex,
    required this.bounds,
    required this.value,
    required this.isNegative,
  });

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
