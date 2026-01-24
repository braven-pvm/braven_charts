// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

/// Metadata for positioning a bar series within a group of bar series.
///
/// When multiple bar series share the same X-values, they need to be positioned
/// side-by-side rather than overlapping. BarGroupInfo provides the positioning
/// metadata needed to calculate horizontal offsets for each bar within a group.
///
/// **Usage**:
/// ```dart
/// // For the second bar series out of three total bar series:
/// final groupInfo = BarGroupInfo(
///   index: 1,
///   count: 3,
///   gap: 2.0,
/// );
///
/// // Calculate X-offset for a 20px wide bar
/// final offset = groupInfo.calculateOffset(20.0);
/// ```
///
/// **Immutability**: All fields are final and the class has a const constructor.
///
/// See also:
/// - [SeriesElement] which stores BarGroupInfo for bar series rendering
class BarGroupInfo {
  /// Creates bar group positioning metadata.
  ///
  /// [index] is the 0-based position of this bar series among all bar series.
  /// [count] is the total number of bar series in the chart.
  /// [gap] is the pixel spacing between adjacent bars within a group (default 2.0).
  ///
  /// Example:
  /// ```dart
  /// // First bar series out of three
  /// const info = BarGroupInfo(index: 0, count: 3);
  ///
  /// // With custom gap
  /// const infoWithGap = BarGroupInfo(index: 1, count: 3, gap: 4.0);
  /// ```
  const BarGroupInfo({
    required this.index,
    required this.count,
    this.gap = 2.0,
  })  : assert(index >= 0, 'index must be non-negative'),
        assert(count >= 1, 'count must be at least 1'),
        assert(index < count, 'index must be less than count'),
        assert(gap >= 0, 'gap must be non-negative');

  /// 0-based index of this bar series among all bar series.
  ///
  /// For example, if there are 3 bar series, valid indices are 0, 1, 2.
  final int index;

  /// Total number of bar series in the chart.
  ///
  /// Must be >= 1. For a single bar series, count is 1 and index is 0.
  final int count;

  /// Pixel spacing between adjacent bars within a group.
  ///
  /// Defaults to 2.0 pixels per FR-003 specification.
  final double gap;

  /// Calculate the X-offset for this bar within its group.
  ///
  /// The formula centers the bar group around the X-position and spaces
  /// bars evenly with the configured gap:
  ///
  /// 1. effectiveWidth = barWidth + gap
  /// 2. totalWidth = effectiveWidth * count - gap (total group width)
  /// 3. startOffset = -totalWidth / 2 + barWidth / 2 (center the group)
  /// 4. offset = startOffset + index * effectiveWidth
  ///
  /// Example:
  /// ```dart
  /// // Three 20px bars with 2px gap:
  /// // Total width: (20+2)*3 - 2 = 64px
  /// // Offsets: -22px, 0px, +22px (centered around 0)
  /// final info0 = BarGroupInfo(index: 0, count: 3);
  /// final info1 = BarGroupInfo(index: 1, count: 3);
  /// final info2 = BarGroupInfo(index: 2, count: 3);
  /// print(info0.calculateOffset(20.0)); // -22.0
  /// print(info1.calculateOffset(20.0)); // 0.0
  /// print(info2.calculateOffset(20.0)); // 22.0
  /// ```
  double calculateOffset(double barWidth) {
    final effectiveWidth = barWidth + gap;
    final totalWidth = effectiveWidth * count - gap;
    final startOffset = -totalWidth / 2 + barWidth / 2;
    return startOffset + index * effectiveWidth;
  }

  /// Compares two BarGroupInfo instances for value equality.
  ///
  /// Two instances are equal if they have the same index, count, and gap values.
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BarGroupInfo && runtimeType == other.runtimeType && index == other.index && count == other.count && gap == other.gap;

  /// Returns a hash code based on index, count, and gap.
  @override
  int get hashCode => Object.hash(index, count, gap);

  /// Returns a string representation of this BarGroupInfo.
  ///
  /// Example: `BarGroupInfo(index: 1, count: 3, gap: 2.0)`
  @override
  String toString() => 'BarGroupInfo(index: $index, count: $count, gap: $gap)';

  /// Creates a copy with optional field overrides.
  ///
  /// Any parameter that is null will use the current value.
  ///
  /// Example:
  /// ```dart
  /// final original = BarGroupInfo(index: 0, count: 3, gap: 2.0);
  /// final modified = original.copyWith(gap: 4.0);
  /// // modified has index=0, count=3, gap=4.0
  /// ```
  BarGroupInfo copyWith({
    int? index,
    int? count,
    double? gap,
  }) {
    return BarGroupInfo(
      index: index ?? this.index,
      count: count ?? this.count,
      gap: gap ?? this.gap,
    );
  }
}
