// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

import '../meta/chart_surface.dart';
import 'chart_data_point.dart';
import 'segment_style.dart';

/// One immutable low/high interval in Cartesian data space.
///
/// For a valid interval, inherited [y] is always the interval midpoint. A gap
/// uses an internal zero placeholder because [ChartDataPoint] requires a
/// double, but Range Area-aware surfaces use [isGap] and never treat it as data.
///
/// A gap is not reachable through the fluent surface. `copyWith`'s `makeGap`
/// flag has no constructor parameter behind it, so no verb is generated for
/// it; build gaps with [RangeAreaDataPoint.gap].
// The constructor validates the interval in its BODY, so the reader cannot
// see the coupling in an assert initializer. `low`/`high` are one value —
// `high >= low` — and an individual `withHigh(1)` on an interval whose `low`
// is 99 throws ArgumentError; they move together through `withInterval`
// instead. Replacing them as a pair also keeps the inherited `y` midpoint
// consistent, which `copyWith` independently refuses to let drift. `x` is
// only checked for finiteness, which no sibling value can influence.
@ChartSurface(
  combinedSetters: [
    CombinedSetter('withInterval', ['low', 'high']),
  ],
  bodyValidated: [
    BodyValidated(
      'validateInterval() rejects a non-finite x. That is a single-parameter '
      'check with no sibling coupling: withX(v) throws for exactly the v '
      'that RangeAreaDataPoint(x: v, ...) would reject.',
      params: ['x'],
    ),
  ],
)
final class RangeAreaDataPoint extends ChartDataPoint {
  RangeAreaDataPoint({
    required super.x,
    super.pointKey,
    required double low,
    required double high,
    super.magnitude,
    super.colorValue,
    super.opacityValue,
    super.categoryValue,
    super.timestamp,
    super.label,
    super.metadata,
    super.segmentStyle,
    super.pointStyle,
  }) : low = low,
       high = high,
       isGap = false,
       super(y: (low + high) / 2) {
    validateInterval(x: x, low: low, high: high);
  }

  RangeAreaDataPoint.gap({
    required super.x,
    super.pointKey,
    super.timestamp,
    super.label,
    super.metadata,
  }) : low = null,
       high = null,
       isGap = true,
       super(y: 0) {
    validateGap(x: x);
  }

  /// Creates an elapsed-time interval whose X is UTC epoch milliseconds.
  factory RangeAreaDataPoint.atTime({
    required DateTime timestamp,
    String? pointKey,
    required double low,
    required double high,
    String? label,
    Map<String, dynamic>? metadata,
  }) {
    final utcTimestamp = timestamp.toUtc();
    return RangeAreaDataPoint(
      x: utcTimestamp.millisecondsSinceEpoch.toDouble(),
      pointKey: pointKey,
      low: low,
      high: high,
      timestamp: utcTimestamp,
      label: label,
      metadata: metadata,
    );
  }

  final double? low;
  final double? high;
  final bool isGap;

  double? get midpoint => isGap ? null : y;
  double? get span => isGap ? null : high! - low!;

  @override
  bool get isValid =>
      x.isFinite &&
      (isGap ||
          (low != null &&
              high != null &&
              low!.isFinite &&
              high!.isFinite &&
              low! <= high!));

  static void validateInterval({
    required double x,
    required double low,
    required double high,
    String parameterName = 'rangeArea',
  }) {
    if (!x.isFinite) {
      throw ArgumentError.value(x, '$parameterName.x', 'must be finite');
    }
    if (!low.isFinite) {
      throw ArgumentError.value(low, '$parameterName.low', 'must be finite');
    }
    if (!high.isFinite) {
      throw ArgumentError.value(high, '$parameterName.high', 'must be finite');
    }
    if (high < low) {
      throw ArgumentError.value(
        high,
        '$parameterName.high',
        'must be greater than or equal to low ($low)',
      );
    }
  }

  static void validateGap({
    required double x,
    String parameterName = 'rangeArea',
  }) {
    if (!x.isFinite) {
      throw ArgumentError.value(x, '$parameterName.x', 'must be finite');
    }
  }

  @override
  RangeAreaDataPoint copyWith({
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
    String? label,
    Map<String, dynamic>? metadata,
    SegmentStyle? segmentStyle,
    bool clearSegmentStyle = false,
    PointStyle? pointStyle,
    bool clearPointStyle = false,
    double? low,
    double? high,
    bool makeGap = false,
  }) {
    if (makeGap) {
      if (low != null || high != null || y != null) {
        throw ArgumentError('A gap cannot include low, high, or y overrides');
      }
      return RangeAreaDataPoint.gap(
        x: x ?? this.x,
        pointKey: clearPointKey ? null : (pointKey ?? this.pointKey),
        timestamp: timestamp ?? this.timestamp,
        label: label ?? this.label,
        metadata: metadata ?? this.metadata,
      );
    }

    final resolvedLow = low ?? this.low;
    final resolvedHigh = high ?? this.high;
    if (resolvedLow == null || resolvedHigh == null) {
      if (resolvedLow != null || resolvedHigh != null) {
        throw ArgumentError(
          'Filling a Range Area gap requires both low and high',
        );
      }
      if (y != null) {
        throw ArgumentError('A Range Area gap cannot override y');
      }
      return RangeAreaDataPoint.gap(
        x: x ?? this.x,
        pointKey: clearPointKey ? null : (pointKey ?? this.pointKey),
        timestamp: timestamp ?? this.timestamp,
        label: label ?? this.label,
        metadata: metadata ?? this.metadata,
      );
    }

    final resolvedMidpoint = (resolvedLow + resolvedHigh) / 2;
    if (y != null && y != resolvedMidpoint) {
      throw ArgumentError(
        'RangeAreaDataPoint y must equal the low/high midpoint',
      );
    }
    return RangeAreaDataPoint(
      x: x ?? this.x,
      pointKey: clearPointKey ? null : (pointKey ?? this.pointKey),
      low: resolvedLow,
      high: resolvedHigh,
      magnitude: clearMagnitude ? null : (magnitude ?? this.magnitude),
      colorValue: clearColorValue ? null : (colorValue ?? this.colorValue),
      opacityValue: clearOpacityValue
          ? null
          : (opacityValue ?? this.opacityValue),
      categoryValue: clearCategoryValue
          ? null
          : (categoryValue ?? this.categoryValue),
      timestamp: timestamp ?? this.timestamp,
      label: label ?? this.label,
      metadata: metadata ?? this.metadata,
      segmentStyle: clearSegmentStyle
          ? null
          : (segmentStyle ?? this.segmentStyle),
      pointStyle: clearPointStyle ? null : (pointStyle ?? this.pointStyle),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RangeAreaDataPoint &&
          super == other &&
          low == other.low &&
          high == other.high &&
          isGap == other.isGap;

  @override
  int get hashCode => Object.hash(super.hashCode, low, high, isGap);

  @override
  String toString() => isGap
      ? 'RangeAreaDataPoint.gap(x: $x)'
      : 'RangeAreaDataPoint(x: $x, low: $low, high: $high, midpoint: $y)';
}
