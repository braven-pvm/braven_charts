// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

import '../meta/chart_surface.dart';

/// Opt-in pixel-density grouping for a native Candlestick series.
///
/// Grouping is a render and interaction projection only. The source points on
/// the series remain unchanged, so artifacts, Data mode, copy, and CSV keep
/// exposing the raw OHLC observations.
@chartSurface
class CandlestickDensityGrouping {
  const CandlestickDensityGrouping({
    this.enabled = false,
    this.targetGroupWidth = 5,
    this.minimumPointsPerGroup = 2,
  }) : assert(targetGroupWidth > 0),
       assert(minimumPointsPerGroup >= 2);

  /// Whether dense visible candles may be combined into OHLC groups.
  final bool enabled;

  /// Desired horizontal plot-space width, in logical pixels, per group.
  ///
  /// Grouping activates only when the visible source density would allocate
  /// fewer than this many pixels to each candle.
  final double targetGroupWidth;

  /// Smallest number of source candles represented by a grouped candle.
  final int minimumPointsPerGroup;

  /// Throws an [ArgumentError] when the grouping threshold is unusable.
  void validate() {
    if (!targetGroupWidth.isFinite || targetGroupWidth <= 0) {
      throw ArgumentError.value(
        targetGroupWidth,
        'targetGroupWidth',
        'must be finite and greater than 0',
      );
    }
    if (minimumPointsPerGroup < 2) {
      throw ArgumentError.value(
        minimumPointsPerGroup,
        'minimumPointsPerGroup',
        'must be at least 2',
      );
    }
  }

  CandlestickDensityGrouping copyWith({
    bool? enabled,
    double? targetGroupWidth,
    int? minimumPointsPerGroup,
  }) => CandlestickDensityGrouping(
    enabled: enabled ?? this.enabled,
    targetGroupWidth: targetGroupWidth ?? this.targetGroupWidth,
    minimumPointsPerGroup: minimumPointsPerGroup ?? this.minimumPointsPerGroup,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CandlestickDensityGrouping &&
          other.enabled == enabled &&
          other.targetGroupWidth == targetGroupWidth &&
          other.minimumPointsPerGroup == minimumPointsPerGroup;

  @override
  int get hashCode =>
      Object.hash(enabled, targetGroupWidth, minimumPointsPerGroup);
}
