// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

import 'dart:ui';

import '../meta/chart_surface.dart';

/// Price direction represented by a candlestick.
enum CandlestickDirection { rising, falling, doji }

/// Whether rising candle bodies are hollow or use their configured fill.
enum CandlestickBodyFillMode { hollowRising, filled }

/// Entrance behavior for a candlestick series.
enum CandlestickAnimationMode { none, reveal }

/// How compatible OHLC revisions move between old and new values.
enum CandlestickDataUpdateAnimationMode { none, interpolate }

/// Optional presentation overrides for one candlestick.
class CandlestickPointStyle {
  const CandlestickPointStyle({
    this.bodyFillColor,
    this.borderColor,
    this.wickColor,
  });

  final Color? bodyFillColor;
  final Color? borderColor;
  final Color? wickColor;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CandlestickPointStyle &&
          other.bodyFillColor == bodyFillColor &&
          other.borderColor == borderColor &&
          other.wickColor == wickColor;

  @override
  int get hashCode => Object.hash(bodyFillColor, borderColor, wickColor);
}

/// Geometry and presentation controls for a candlestick series.
///
/// Direction colors are nullable because final defaults are resolved by the
/// chart theme. Geometry values are validated again by
/// [CandlestickChartSeries] so invalid release-mode input fails closed.
@ChartSurface(
  combinedSetters: [
    CombinedSetter('withBodyWidthLimits', ['minBodyWidth', 'maxBodyWidth']),
  ],
)
class CandlestickChartStyle {
  const CandlestickChartStyle({
    this.risingBodyFillColor,
    this.fallingBodyFillColor,
    this.dojiBodyFillColor,
    this.risingBorderColor,
    this.fallingBorderColor,
    this.dojiBorderColor,
    this.risingWickColor,
    this.fallingWickColor,
    this.dojiWickColor,
    this.bodyFillMode = CandlestickBodyFillMode.hollowRising,
    this.bodyWidthFactor = 0.7,
    this.minBodyWidth = 1,
    this.maxBodyWidth = 18,
    this.bodyBorderWidth = 1,
    this.wickWidth = 1,
    this.showBodyBorder = true,
    this.showWicks = true,
    this.bodyCornerRadius = 0,
    this.minimumBodyHeight = 1,
  }) : assert(bodyWidthFactor > 0 && bodyWidthFactor <= 1),
       assert(minBodyWidth > 0),
       assert(maxBodyWidth >= minBodyWidth),
       assert(bodyBorderWidth >= 0),
       assert(wickWidth >= 0),
       assert(bodyCornerRadius >= 0),
       assert(minimumBodyHeight > 0);

  final Color? risingBodyFillColor;
  final Color? fallingBodyFillColor;
  final Color? dojiBodyFillColor;
  final Color? risingBorderColor;
  final Color? fallingBorderColor;
  final Color? dojiBorderColor;
  final Color? risingWickColor;
  final Color? fallingWickColor;
  final Color? dojiWickColor;
  final CandlestickBodyFillMode bodyFillMode;
  final double bodyWidthFactor;
  final double minBodyWidth;
  final double maxBodyWidth;
  final double bodyBorderWidth;
  final double wickWidth;
  final bool showBodyBorder;
  final bool showWicks;
  final double bodyCornerRadius;
  final double minimumBodyHeight;

  /// Throws an [ArgumentError] when geometry settings are not usable.
  void validate() {
    if (!bodyWidthFactor.isFinite ||
        bodyWidthFactor <= 0 ||
        bodyWidthFactor > 1) {
      throw ArgumentError.value(
        bodyWidthFactor,
        'bodyWidthFactor',
        'must be finite, greater than 0, and at most 1',
      );
    }
    if (!minBodyWidth.isFinite || minBodyWidth <= 0) {
      throw ArgumentError.value(
        minBodyWidth,
        'minBodyWidth',
        'must be finite and greater than 0',
      );
    }
    if (!maxBodyWidth.isFinite || maxBodyWidth < minBodyWidth) {
      throw ArgumentError.value(
        maxBodyWidth,
        'maxBodyWidth',
        'must be finite and at least minBodyWidth',
      );
    }
    _validateNonNegative(bodyBorderWidth, 'bodyBorderWidth');
    _validateNonNegative(wickWidth, 'wickWidth');
    _validateNonNegative(bodyCornerRadius, 'bodyCornerRadius');
    if (!minimumBodyHeight.isFinite || minimumBodyHeight <= 0) {
      throw ArgumentError.value(
        minimumBodyHeight,
        'minimumBodyHeight',
        'must be finite and greater than 0',
      );
    }
  }

  static void _validateNonNegative(double value, String name) {
    if (!value.isFinite || value < 0) {
      throw ArgumentError.value(value, name, 'must be finite and non-negative');
    }
  }

  CandlestickChartStyle copyWith({
    Color? risingBodyFillColor,
    Color? fallingBodyFillColor,
    Color? dojiBodyFillColor,
    Color? risingBorderColor,
    Color? fallingBorderColor,
    Color? dojiBorderColor,
    Color? risingWickColor,
    Color? fallingWickColor,
    Color? dojiWickColor,
    CandlestickBodyFillMode? bodyFillMode,
    double? bodyWidthFactor,
    double? minBodyWidth,
    double? maxBodyWidth,
    double? bodyBorderWidth,
    double? wickWidth,
    bool? showBodyBorder,
    bool? showWicks,
    double? bodyCornerRadius,
    double? minimumBodyHeight,
    bool clearRisingBodyFillColor = false,
    bool clearFallingBodyFillColor = false,
    bool clearDojiBodyFillColor = false,
    bool clearRisingBorderColor = false,
    bool clearFallingBorderColor = false,
    bool clearDojiBorderColor = false,
    bool clearRisingWickColor = false,
    bool clearFallingWickColor = false,
    bool clearDojiWickColor = false,
  }) => CandlestickChartStyle(
    risingBodyFillColor: clearRisingBodyFillColor
        ? null
        : (risingBodyFillColor ?? this.risingBodyFillColor),
    fallingBodyFillColor: clearFallingBodyFillColor
        ? null
        : (fallingBodyFillColor ?? this.fallingBodyFillColor),
    dojiBodyFillColor: clearDojiBodyFillColor
        ? null
        : (dojiBodyFillColor ?? this.dojiBodyFillColor),
    risingBorderColor: clearRisingBorderColor
        ? null
        : (risingBorderColor ?? this.risingBorderColor),
    fallingBorderColor: clearFallingBorderColor
        ? null
        : (fallingBorderColor ?? this.fallingBorderColor),
    dojiBorderColor: clearDojiBorderColor
        ? null
        : (dojiBorderColor ?? this.dojiBorderColor),
    risingWickColor: clearRisingWickColor
        ? null
        : (risingWickColor ?? this.risingWickColor),
    fallingWickColor: clearFallingWickColor
        ? null
        : (fallingWickColor ?? this.fallingWickColor),
    dojiWickColor: clearDojiWickColor
        ? null
        : (dojiWickColor ?? this.dojiWickColor),
    bodyFillMode: bodyFillMode ?? this.bodyFillMode,
    bodyWidthFactor: bodyWidthFactor ?? this.bodyWidthFactor,
    minBodyWidth: minBodyWidth ?? this.minBodyWidth,
    maxBodyWidth: maxBodyWidth ?? this.maxBodyWidth,
    bodyBorderWidth: bodyBorderWidth ?? this.bodyBorderWidth,
    wickWidth: wickWidth ?? this.wickWidth,
    showBodyBorder: showBodyBorder ?? this.showBodyBorder,
    showWicks: showWicks ?? this.showWicks,
    bodyCornerRadius: bodyCornerRadius ?? this.bodyCornerRadius,
    minimumBodyHeight: minimumBodyHeight ?? this.minimumBodyHeight,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CandlestickChartStyle &&
          other.risingBodyFillColor == risingBodyFillColor &&
          other.fallingBodyFillColor == fallingBodyFillColor &&
          other.dojiBodyFillColor == dojiBodyFillColor &&
          other.risingBorderColor == risingBorderColor &&
          other.fallingBorderColor == fallingBorderColor &&
          other.dojiBorderColor == dojiBorderColor &&
          other.risingWickColor == risingWickColor &&
          other.fallingWickColor == fallingWickColor &&
          other.dojiWickColor == dojiWickColor &&
          other.bodyFillMode == bodyFillMode &&
          other.bodyWidthFactor == bodyWidthFactor &&
          other.minBodyWidth == minBodyWidth &&
          other.maxBodyWidth == maxBodyWidth &&
          other.bodyBorderWidth == bodyBorderWidth &&
          other.wickWidth == wickWidth &&
          other.showBodyBorder == showBodyBorder &&
          other.showWicks == showWicks &&
          other.bodyCornerRadius == bodyCornerRadius &&
          other.minimumBodyHeight == minimumBodyHeight;

  @override
  int get hashCode => Object.hashAll([
    risingBodyFillColor,
    fallingBodyFillColor,
    dojiBodyFillColor,
    risingBorderColor,
    fallingBorderColor,
    dojiBorderColor,
    risingWickColor,
    fallingWickColor,
    dojiWickColor,
    bodyFillMode,
    bodyWidthFactor,
    minBodyWidth,
    maxBodyWidth,
    bodyBorderWidth,
    wickWidth,
    showBodyBorder,
    showWicks,
    bodyCornerRadius,
    minimumBodyHeight,
  ]);
}

/// Entrance animation settings for a candlestick series.
@chartSurface
class CandlestickAnimationStyle {
  const CandlestickAnimationStyle({
    this.mode = CandlestickAnimationMode.reveal,
    this.staggerFraction = 0,
    this.dataUpdateMode = CandlestickDataUpdateAnimationMode.interpolate,
  }) : assert(staggerFraction >= 0 && staggerFraction <= 1);

  final CandlestickAnimationMode mode;

  /// Fraction of the entrance timeline used to advance the candle sequence.
  ///
  /// Zero uses the complete theme duration. Values above zero finish the
  /// ordered reveal at this fraction and leave the remaining time to settle.
  final double staggerFraction;
  final CandlestickDataUpdateAnimationMode dataUpdateMode;

  void validate() {
    if (!staggerFraction.isFinite ||
        staggerFraction < 0 ||
        staggerFraction > 1) {
      throw ArgumentError.value(
        staggerFraction,
        'staggerFraction',
        'must be finite and between 0 and 1',
      );
    }
  }

  CandlestickAnimationStyle copyWith({
    CandlestickAnimationMode? mode,
    double? staggerFraction,
    CandlestickDataUpdateAnimationMode? dataUpdateMode,
  }) => CandlestickAnimationStyle(
    mode: mode ?? this.mode,
    staggerFraction: staggerFraction ?? this.staggerFraction,
    dataUpdateMode: dataUpdateMode ?? this.dataUpdateMode,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CandlestickAnimationStyle &&
          other.mode == mode &&
          other.staggerFraction == staggerFraction &&
          other.dataUpdateMode == dataUpdateMode;

  @override
  int get hashCode => Object.hash(mode, staggerFraction, dataUpdateMode);
}
