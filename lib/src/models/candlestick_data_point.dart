// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

import '../meta/chart_surface.dart';
import 'candlestick_chart_style.dart';
import 'chart_data_point.dart';
import 'segment_style.dart';

/// One immutable open-high-low-close sample in Cartesian data space.
///
/// The inherited [y] value is always equal to [close]. This keeps generic
/// point identity and callback behavior meaningful without losing OHLC data.
// The constructor validates OHLC in its BODY, so the reader cannot see the
// coupling in an assert initializer. `open`/`high`/`low`/`close` are one
// value — `high >= max(open, close)` and `low <= min(open, close)` — and an
// individual `withHigh(1)` on a candle whose `low` is 99 threw ArgumentError;
// they move together through `withOhlc` instead. `x` is only checked for
// finiteness, which no sibling value can influence.
@ChartSurface(
  combinedSetters: [
    CombinedSetter('withOhlc', ['open', 'high', 'low', 'close']),
  ],
  bodyValidated: [
    BodyValidated(
      'validateValues() rejects a non-finite x. That is a single-parameter '
      'check with no sibling coupling: withX(v) throws for exactly the v '
      'that CandlestickDataPoint(x: v, ...) would reject.',
      params: ['x'],
    ),
  ],
)
final class CandlestickDataPoint extends ChartDataPoint {
  CandlestickDataPoint({
    required super.x,
    super.pointKey,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
    super.magnitude,
    super.colorValue,
    super.opacityValue,
    super.categoryValue,
    super.timestamp,
    super.label,
    super.metadata,
    super.segmentStyle,
    super.pointStyle,
    this.candlestickStyle,
  }) : super(y: close) {
    validateValues(x: x, open: open, high: high, low: low, close: close);
  }

  /// Creates an elapsed-time candle whose X value is UTC epoch milliseconds.
  factory CandlestickDataPoint.atTime({
    required DateTime timestamp,
    String? pointKey,
    required double open,
    required double high,
    required double low,
    required double close,
    String? label,
    Map<String, dynamic>? metadata,
    CandlestickPointStyle? candlestickStyle,
  }) {
    final utcTimestamp = timestamp.toUtc();
    return CandlestickDataPoint(
      x: utcTimestamp.millisecondsSinceEpoch.toDouble(),
      pointKey: pointKey,
      open: open,
      high: high,
      low: low,
      close: close,
      timestamp: utcTimestamp,
      label: label,
      metadata: metadata,
      candlestickStyle: candlestickStyle,
    );
  }

  final double open;
  final double high;
  final double low;
  final double close;
  final CandlestickPointStyle? candlestickStyle;

  CandlestickDirection get direction => close > open
      ? CandlestickDirection.rising
      : close < open
      ? CandlestickDirection.falling
      : CandlestickDirection.doji;

  /// Applies the shared OHLC invariants used by all construction paths.
  static void validateValues({
    required double x,
    required double open,
    required double high,
    required double low,
    required double close,
    String parameterName = 'candlestick',
  }) {
    final values = <String, double>{
      'x': x,
      'open': open,
      'high': high,
      'low': low,
      'close': close,
    };
    for (final entry in values.entries) {
      if (!entry.value.isFinite) {
        throw ArgumentError.value(
          entry.value,
          '$parameterName.${entry.key}',
          'must be finite',
        );
      }
    }
    if (high < low) {
      throw ArgumentError.value(
        high,
        '$parameterName.high',
        'must be greater than or equal to low ($low)',
      );
    }
    if (high < open || high < close) {
      throw ArgumentError.value(
        high,
        '$parameterName.high',
        'must be greater than or equal to open and close',
      );
    }
    if (low > open || low > close) {
      throw ArgumentError.value(
        low,
        '$parameterName.low',
        'must be less than or equal to open and close',
      );
    }
  }

  @override
  CandlestickDataPoint copyWith({
    double? x,
    double? y,
    String? pointKey,
    bool clearPointKey = false,
    double? magnitude,
    bool clearMagnitude = false,
    double? colorValue,
    bool clearColorValue = false,
    double? opacityValue,
    bool clearOpacityValue = false,
    String? categoryValue,
    bool clearCategoryValue = false,
    DateTime? timestamp,
    bool clearTimestamp = false,
    String? label,
    bool clearLabel = false,
    Map<String, dynamic>? metadata,
    bool clearMetadata = false,
    SegmentStyle? segmentStyle,
    bool clearSegmentStyle = false,
    PointStyle? pointStyle,
    bool clearPointStyle = false,
    double? open,
    double? high,
    double? low,
    double? close,
    CandlestickPointStyle? candlestickStyle,
    bool clearCandlestickStyle = false,
  }) {
    if (y != null && close != null && y != close) {
      throw ArgumentError(
        'CandlestickDataPoint y and close overrides must be equal',
      );
    }
    final resolvedClose = close ?? y ?? this.close;
    return CandlestickDataPoint(
      x: x ?? this.x,
      pointKey: clearPointKey ? null : (pointKey ?? this.pointKey),
      open: open ?? this.open,
      high: high ?? this.high,
      low: low ?? this.low,
      close: resolvedClose,
      magnitude: clearMagnitude ? null : (magnitude ?? this.magnitude),
      colorValue: clearColorValue ? null : (colorValue ?? this.colorValue),
      opacityValue: clearOpacityValue
          ? null
          : (opacityValue ?? this.opacityValue),
      categoryValue: clearCategoryValue
          ? null
          : (categoryValue ?? this.categoryValue),
      timestamp: clearTimestamp ? null : (timestamp ?? this.timestamp),
      label: clearLabel ? null : (label ?? this.label),
      metadata: clearMetadata ? null : (metadata ?? this.metadata),
      segmentStyle: clearSegmentStyle
          ? null
          : (segmentStyle ?? this.segmentStyle),
      pointStyle: clearPointStyle ? null : (pointStyle ?? this.pointStyle),
      candlestickStyle: clearCandlestickStyle
          ? null
          : (candlestickStyle ?? this.candlestickStyle),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CandlestickDataPoint &&
          super == other &&
          other.open == open &&
          other.high == high &&
          other.low == low &&
          other.close == close &&
          other.candlestickStyle == candlestickStyle;

  @override
  int get hashCode =>
      Object.hash(super.hashCode, open, high, low, close, candlestickStyle);

  @override
  String toString() =>
      'CandlestickDataPoint(x: $x, open: $open, high: $high, low: $low, close: $close, direction: ${direction.name})';
}
