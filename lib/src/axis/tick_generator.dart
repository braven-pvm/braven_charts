// Copyright (c) 2025 braven_charts. All rights reserved.
// Phase 0 Prototype - Axis System

import 'dart:math';

import 'tick.dart';

/// Generates "nice" tick positions for axis rendering.
///
/// **Purpose**: Calculate tick positions at human-friendly intervals
/// (1, 2, 5, 10, 20, 50, 100, etc.) instead of arbitrary values.
///
/// **Algorithm**:
/// 1. Calculate rough interval from data range and target tick count
/// 2. Round to nearest "nice" number (1, 2, or 5 times a power of 10)
/// 3. Generate ticks at multiples of the nice interval
///
/// **Example**:
/// ```dart
/// Data range: [0, 87.3]
/// Target ticks: 10
/// Rough interval: 8.73
/// Nice interval: 10
/// Generated ticks: 0, 10, 20, 30, 40, 50, 60, 70, 80
/// ```
class TickGenerator {
  /// Default number of ticks to target.
  static const int defaultTargetCount = 10;

  /// Minimum number of ticks to generate.
  static const int minTickCount = 2;

  /// Maximum number of ticks to generate.
  static const int maxTickCount = 20;

  /// Generates tick positions for the given data range.
  ///
  /// [dataMin] and [dataMax] define the visible data range.
  /// [pixelRange] is the available screen space (used to avoid overcrowding).
  /// [targetTickCount] is the desired number of ticks (will be adjusted for "nice" intervals).
  List<Tick> generateTicks({
    required double dataMin,
    required double dataMax,
    required double pixelRange,
    int targetTickCount = defaultTargetCount,
    String Function(double)? formatLabel,
  }) {
    assert(dataMax > dataMin, 'dataMax must be greater than dataMin');
    assert(pixelRange > 0, 'pixelRange must be positive');
    assert(targetTickCount >= minTickCount,
        'targetTickCount must be at least $minTickCount');

    // Clamp target count to reasonable range
    final clampedTargetCount =
        targetTickCount.clamp(minTickCount, maxTickCount);

    // Calculate ideal tick interval
    final dataRange = dataMax - dataMin;
    final roughInterval = dataRange / clampedTargetCount;

    // Round to "nice" number
    final niceInterval = _makeNice(roughInterval);

    // Generate ticks at nice intervals
    final ticks = <Tick>[];

    // Start at first nice multiple >= dataMin
    final startTick = (dataMin / niceInterval).ceil() * niceInterval;

    // Generate ticks up to dataMax
    for (double value = startTick;
        value <= dataMax + niceInterval * 0.01;
        value += niceInterval) {
      // Skip if outside bounds (with small tolerance for floating point)
      if (value < dataMin - niceInterval * 0.01) continue;
      if (value > dataMax + niceInterval * 0.01) break;

      final label = formatLabel?.call(value) ?? _defaultFormatLabel(value);
      ticks.add(Tick(value: value, label: label));
    }

    // Ensure we have at least 2 ticks
    if (ticks.isEmpty || ticks.length < 2) {
      return [
        Tick(
            value: dataMin,
            label: formatLabel?.call(dataMin) ?? _defaultFormatLabel(dataMin)),
        Tick(
            value: dataMax,
            label: formatLabel?.call(dataMax) ?? _defaultFormatLabel(dataMax)),
      ];
    }

    return ticks;
  }

  /// Rounds a value to a "nice" number: 1, 2, or 5 times a power of 10.
  ///
  /// Examples:
  /// - 8.73 → 10
  /// - 0.37 → 0.5
  /// - 123 → 100 or 200
  /// - 0.0047 → 0.005
  double _makeNice(double roughInterval) {
    // Handle edge case
    if (roughInterval <= 0) return 1.0;

    // Find the order of magnitude (power of 10)
    final exponent = (log(roughInterval) / ln10).floor();
    final powerOf10 = pow(10.0, exponent);

    // Normalize to [1, 10)
    final fraction = roughInterval / powerOf10;

    // Round to 1, 2, or 5
    final niceFraction = fraction <= 1.0
        ? 1.0
        : fraction <= 2.0
            ? 2.0
            : fraction <= 5.0
                ? 5.0
                : 10.0;

    return niceFraction * powerOf10;
  }

  /// Default label formatter.
  ///
  /// Smart formatting:
  /// - Integers: "1", "10", "100"
  /// - Large numbers: "1K", "1.5K", "1M"
  /// - Small decimals: "0.1", "0.01"
  /// - Very small: scientific notation "1.23e-5"
  String _defaultFormatLabel(double value) {
    // Handle zero
    if (value == 0) return '0';

    final absValue = value.abs();

    // Large numbers: format as K, M, B
    if (absValue >= 1000000000) {
      return _formatWithSuffix(value / 1000000000, 'B');
    }
    if (absValue >= 1000000) {
      return _formatWithSuffix(value / 1000000, 'M');
    }
    if (absValue >= 1000) {
      return _formatWithSuffix(value / 1000, 'K');
    }

    // Very small numbers: scientific notation
    if (absValue < 0.001 && absValue > 0) {
      return value.toStringAsExponential(1);
    }

    // Regular numbers: remove unnecessary decimals
    if (value == value.truncate()) {
      return value.truncate().toString();
    }

    // Decimals: limit to 2 decimal places
    return value.toStringAsFixed(2).replaceAll(RegExp(r'\.?0+$'), '');
  }

  /// Formats a value with a suffix (K, M, B).
  String _formatWithSuffix(double value, String suffix) {
    if (value == value.truncate()) {
      return '${value.truncate()}$suffix';
    }
    return '${value.toStringAsFixed(1)}$suffix';
  }
}
