// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

import 'package:flutter/foundation.dart' show mapEquals, setEquals;

import 'bar_chart_style.dart';

/// Metadata for positioning and composing a bar series within category slots.
///
/// When multiple bar slots share the same X-values, they need to be positioned
/// side-by-side. Stacked series intentionally share a slot index while grouped
/// series receive distinct indices.
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
/// - `SeriesElement`, which stores bar group metadata during rendering
class BarGroupInfo {
  /// Creates bar group positioning metadata.
  ///
  /// [index] is the 0-based position of this series' category slot.
  /// [count] is the total number of category slots in the chart.
  /// [gap] is the pixel spacing between adjacent slots (default 2.0).
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
    this.layoutMode = BarLayoutMode.grouped,
    this.groupId,
    this.stackBaseline = 0.0,
    this.startValues = const {},
    this.endValues = const {},
    this.percentages = const {},
    this.outerPointIndices = const {},
    this.drawTrack = true,
  }) : assert(index >= 0, 'index must be non-negative'),
       assert(count >= 1, 'count must be at least 1'),
       assert(index < count, 'index must be less than count'),
       assert(gap >= 0, 'gap must be non-negative');

  /// 0-based index of this series' category slot.
  ///
  /// For example, if there are 3 slots, valid indices are 0, 1, 2.
  final int index;

  /// Total number of side-by-side category slots in the chart.
  ///
  /// Must be >= 1. For a single bar series, count is 1 and index is 0.
  final int count;

  /// Pixel spacing between adjacent bars within a group.
  ///
  /// Defaults to 2.0 pixels per FR-003 specification.
  final double gap;

  /// Composition mode resolved for this series.
  final BarLayoutMode layoutMode;

  /// Named stack ID, when supplied by the series.
  final String? groupId;

  /// Common baseline used by a stack.
  final double stackBaseline;

  /// Rendered segment start values keyed by point index.
  final Map<int, double> startValues;

  /// Rendered segment end values keyed by point index.
  final Map<int, double> endValues;

  /// Signed normalized percentages keyed by point index.
  final Map<int, double> percentages;

  /// Point indices exposed at the positive or negative end of a stack.
  final Set<int> outerPointIndices;

  /// Whether this series owns the shared track behind its composition slot.
  final bool drawTrack;

  bool get isStacked =>
      layoutMode == BarLayoutMode.stacked ||
      layoutMode == BarLayoutMode.normalizedStacked;

  bool get isOverlaid => layoutMode == BarLayoutMode.overlaid;

  bool get isWaterfall => layoutMode == BarLayoutMode.waterfall;

  double startValueFor(int pointIndex, double fallback) =>
      startValues[pointIndex] ?? fallback;

  double endValueFor(int pointIndex, double fallback) =>
      endValues[pointIndex] ?? fallback;

  double? percentageFor(int pointIndex) => percentages[pointIndex];

  bool isOuterPoint(int pointIndex) =>
      !isStacked || outerPointIndices.contains(pointIndex);

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
      other is BarGroupInfo &&
          runtimeType == other.runtimeType &&
          index == other.index &&
          count == other.count &&
          gap == other.gap &&
          layoutMode == other.layoutMode &&
          groupId == other.groupId &&
          stackBaseline == other.stackBaseline &&
          mapEquals(startValues, other.startValues) &&
          mapEquals(endValues, other.endValues) &&
          mapEquals(percentages, other.percentages) &&
          setEquals(outerPointIndices, other.outerPointIndices) &&
          drawTrack == other.drawTrack;

  /// Returns a hash code based on index, count, and gap.
  @override
  int get hashCode => Object.hashAll([
    index,
    count,
    gap,
    layoutMode,
    groupId,
    stackBaseline,
    _mapHash(startValues),
    _mapHash(endValues),
    _mapHash(percentages),
    Object.hashAll(outerPointIndices.toList()..sort()),
    drawTrack,
  ]);

  /// Returns a string representation of this BarGroupInfo.
  ///
  /// Example: `BarGroupInfo(index: 1, count: 3, gap: 2.0)`
  @override
  String toString() =>
      'BarGroupInfo(index: $index, count: $count, gap: $gap, layoutMode: $layoutMode, groupId: $groupId)';

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
    BarLayoutMode? layoutMode,
    String? groupId,
    bool clearGroupId = false,
    double? stackBaseline,
    Map<int, double>? startValues,
    Map<int, double>? endValues,
    Map<int, double>? percentages,
    Set<int>? outerPointIndices,
    bool? drawTrack,
  }) {
    return BarGroupInfo(
      index: index ?? this.index,
      count: count ?? this.count,
      gap: gap ?? this.gap,
      layoutMode: layoutMode ?? this.layoutMode,
      groupId: clearGroupId ? null : (groupId ?? this.groupId),
      stackBaseline: stackBaseline ?? this.stackBaseline,
      startValues: startValues ?? this.startValues,
      endValues: endValues ?? this.endValues,
      percentages: percentages ?? this.percentages,
      outerPointIndices: outerPointIndices ?? this.outerPointIndices,
      drawTrack: drawTrack ?? this.drawTrack,
    );
  }
}

int _mapHash(Map<int, double> values) {
  final keys = values.keys.toList()..sort();
  return Object.hashAll([
    for (final key in keys) Object.hash(key, values[key]),
  ]);
}
