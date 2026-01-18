// Copyright (c) 2025 braven_charts. All rights reserved.
// Phase 0 Prototype - Axis System

// import 'package:flutter/foundation.dart' show debugPrint;

import 'dart:math' show log, ln10, pow;

import '../models/x_axis_config.dart';
import '../models/y_axis_config.dart';
import 'axis_config.dart';
import 'linear_scale.dart';
import 'tick.dart';
import 'tick_generator.dart';

/// Represents an axis with scale, ticks, and configuration.
///
/// **Purpose**: Combines data-to-pixel mapping, tick generation, and
/// visual configuration for rendering chart axes.
///
/// **Usage**:
/// ```dart
/// final xAxis = Axis.fromXAxisConfig(
///   config: XAxisConfig(label: 'Time'),
///   dataMin: 0,
///   dataMax: 100,
/// );
///
/// // Update for new viewport
/// xAxis.updateDataRange(25, 75);
///
/// // Update screen position
/// xAxis.updatePixelRange(60, 760);
/// ```
class Axis {
  /// Creates an axis from an internal configuration.
  ///
  /// **Prefer [Axis.fromXAxisConfig]** or [Axis.fromYAxisConfig] for creating
  /// axes from the public API. This constructor is for internal use when you
  /// already have an [InternalAxisConfig].
  Axis({
    required this.config,
    required double dataMin,
    required double dataMax,
    double pixelMin = 0,
    double pixelMax = 100,
    this.labelFormatter,
  }) {
    // Create initial scale
    scale = LinearScale(
      dataMin: dataMin,
      dataMax: dataMax,
      pixelMin: pixelMin,
      pixelMax: pixelMax,
      invertY: config.orientation == AxisOrientation.vertical,
    );

    // Generate initial ticks (skipped if axis is fully hidden)
    ticks = _generateTicks();
  }

  /// Creates an axis from the public XAxisConfig API.
  ///
  /// This is the recommended way to create X-axes from widget parameters.
  ///
  /// Example:
  /// ```dart
  /// final xAxis = Axis.fromXAxisConfig(
  ///   config: XAxisConfig(label: 'Time'),
  ///   dataMin: 0,
  ///   dataMax: 100,
  /// );
  /// ```
  factory Axis.fromXAxisConfig({
    required XAxisConfig config,
    required double dataMin,
    required double dataMax,
    double pixelMin = 0,
    double pixelMax = 100,
    String Function(double value)? labelFormatter,
  }) {
    return Axis(
      config: InternalAxisConfig.fromXAxisConfig(config),
      dataMin: dataMin,
      dataMax: dataMax,
      pixelMin: pixelMin,
      pixelMax: pixelMax,
      labelFormatter: labelFormatter,
    );
  }

  /// Creates an axis from the public YAxisConfig API.
  ///
  /// This is used for internal transform calculations when a single
  /// primary Y-axis is needed.
  factory Axis.fromYAxisConfig({
    required YAxisConfig config,
    required double dataMin,
    required double dataMax,
    double pixelMin = 0,
    double pixelMax = 100,
    String Function(double value)? labelFormatter,
  }) {
    return Axis(
      config: InternalAxisConfig.fromYAxisConfig(config),
      dataMin: dataMin,
      dataMax: dataMax,
      pixelMin: pixelMin,
      pixelMax: pixelMax,
      labelFormatter: labelFormatter,
    );
  }

  /// Visual configuration (internal).
  final InternalAxisConfig config;

  /// Scale for converting between data and pixel coordinates.
  late LinearScale scale;

  /// Generated tick positions and labels.
  late List<Tick> ticks;

  /// Optional custom label formatter.
  ///
  /// If provided, used instead of default formatting.
  final String Function(double value)? labelFormatter;

  /// Current data range (visible viewport).
  double get dataMin => scale.dataMin;
  double get dataMax => scale.dataMax;

  /// Current pixel range (screen position).
  double get pixelMin => scale.pixelMin;
  double get pixelMax => scale.pixelMax;

  /// Cached tick interval for throttling tick regeneration during streaming.
  /// Only regenerate ticks when the interval would change significantly.
  double? _lastTickInterval;

  /// Cached rightmost tick value for detecting when new ticks are needed.
  /// In expand mode, we only regenerate when data exceeds the last tick.
  /// In scroll mode, we regenerate when viewport slides significantly.
  double? _lastRightmostTick;
  double? _lastLeftmostTick;

  /// Updates the visible data range (called when zooming/panning).
  ///
  /// Regenerates ticks when:
  /// 1. The tick interval would change significantly (>25% to prevent oscillation)
  /// 2. OR data extends beyond the rightmost/leftmost tick (need new gridlines)
  void updateDataRange(double newDataMin, double newDataMax) {
    scale = scale.copyWith(
      dataMin: newDataMin,
      dataMax: newDataMax,
    );

    // Skip tick generation entirely if nothing will be rendered
    // This is a major performance optimization for hidden axes
    if (!config.showAxisLine && !config.showGrid && !config.showTickMarks) {
      ticks = const [];
      return;
    }

    // Calculate what the new tick interval would be
    final dataRange = newDataMax - newDataMin;
    final roughInterval = dataRange / TickGenerator.defaultTargetCount;
    final niceInterval = _makeNiceInterval(roughInterval);

    // Check if interval changed significantly (>25% to prevent oscillation)
    // The nice number sequence is 1→2→5→10 (100%, 150%, 100% jumps)
    // Using 25% threshold prevents flickering between adjacent nice numbers
    final intervalChanged = _lastTickInterval == null || (niceInterval - _lastTickInterval!).abs() > _lastTickInterval! * 0.25;

    // Check if we need new ticks because data extends beyond current tick range
    // This works for both expand mode and scroll mode:
    // - Expand: triggers when data grows past rightmost tick
    // - Scroll: triggers when viewport slides past tick coverage
    // Use 1.0× interval threshold to regenerate only when we've scrolled a full tick
    bool needsNewTicks = false;
    if (!intervalChanged && _lastTickInterval != null && _lastRightmostTick != null) {
      // Need new tick on the right if data extends past last tick by a full interval
      if (newDataMax > _lastRightmostTick! + _lastTickInterval!) {
        needsNewTicks = true;
      }
      // Need new tick on the left if data extends past first tick by a full interval
      if (_lastLeftmostTick != null && newDataMin < _lastLeftmostTick! - _lastTickInterval!) {
        needsNewTicks = true;
      }
    }

    if (intervalChanged || needsNewTicks) {
      _lastTickInterval = niceInterval;
      ticks = _generateTicks();

      // Cache the tick range for next comparison
      if (ticks.isNotEmpty) {
        _lastLeftmostTick = ticks.first.value;
        _lastRightmostTick = ticks.last.value;
      }
    }
  }

  /// Rounds a value to a "nice" number for tick interval calculation.
  /// MUST match TickGenerator._makeNice() exactly to avoid caching mismatches.
  double _makeNiceInterval(double roughInterval) {
    if (roughInterval <= 0) return 1.0;

    // Use logarithm for correct exponent calculation (matches TickGenerator)
    final exponent = (log(roughInterval) / ln10).floor();
    final powerOf10 = pow(10.0, exponent).toDouble();

    // Normalize to [1, 10)
    final fraction = roughInterval / powerOf10;

    // Round to 1, 2, 5, or 10 - MUST use same thresholds as TickGenerator
    final niceFraction = fraction <= 1.0
        ? 1.0
        : fraction <= 2.0
            ? 2.0
            : fraction <= 5.0
                ? 5.0
                : 10.0;

    return niceFraction * powerOf10;
  }

  /// Updates the pixel range (called when layout changes).
  ///
  /// Regenerates ticks for the new pixel range.
  void updatePixelRange(double newPixelMin, double newPixelMax) {
    scale = scale.copyWith(
      pixelMin: newPixelMin,
      pixelMax: newPixelMax,
    );

    ticks = _generateTicks();
  }

  /// Updates both data and pixel ranges simultaneously.
  void updateRanges({
    double? dataMin,
    double? dataMax,
    double? pixelMin,
    double? pixelMax,
  }) {
    scale = scale.copyWith(
      dataMin: dataMin,
      dataMax: dataMax,
      pixelMin: pixelMin,
      pixelMax: pixelMax,
    );

    ticks = _generateTicks();
  }

  /// Generates ticks for the current data and pixel ranges.
  /// Returns empty list if axis is fully hidden (no axis line, grid, or tick marks).
  List<Tick> _generateTicks() {
    // Skip tick generation entirely if nothing will be rendered
    // This is a major performance optimization for hidden axes
    if (!config.showAxisLine && !config.showGrid && !config.showTickMarks) {
      return const [];
    }

    return TickGenerator().generateTicks(
      dataMin: scale.dataMin,
      dataMax: scale.dataMax,
      pixelRange: scale.pixelRange,
      formatLabel: labelFormatter,
    );
  }

  @override
  String toString() => 'Axis(${config.orientation}, ${config.position}, '
      'data: [${scale.dataMin}, ${scale.dataMax}], '
      'pixels: [${scale.pixelMin}, ${scale.pixelMax}], '
      'ticks: ${ticks.length})';
}
