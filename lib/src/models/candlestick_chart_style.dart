// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

import 'dart:ui';

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
