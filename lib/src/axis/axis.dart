// Copyright (c) 2025 braven_charts. All rights reserved.
// Phase 0 Prototype - Axis System

// import 'package:flutter/foundation.dart' show debugPrint;

import 'dart:math' show log, ln10, pow;

import '../models/axis_config.dart' as public_config;
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
/// final xAxis = Axis.fromPublicConfig(
///   config: AxisConfig(label: 'Time'),
///   isXAxis: true,
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
  /// **Prefer [Axis.fromPublicConfig]** for creating axes from the public API.
  /// This constructor is for internal use when you already have an [InternalAxisConfig].
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

    // Generate initial ticks
    ticks = _generateTicks();
  }

  /// Creates an axis from the public AxisConfig API.
  ///
  /// This is the recommended way to create axes from widget parameters.
  /// The [isXAxis] parameter determines orientation and default position.
  ///
  /// Example:
  /// ```dart
  /// final xAxis = Axis.fromPublicConfig(
  ///   config: AxisConfig(label: 'Time', showGrid: true),
  ///   isXAxis: true,
  ///   dataMin: 0,
  ///   dataMax: 100,
  /// );
  /// ```
  factory Axis.fromPublicConfig({
    required public_config.AxisConfig config,
    required bool isXAxis,
    required double dataMin,
    required double dataMax,
    double pixelMin = 0,
    double pixelMax = 100,
    String Function(double value)? labelFormatter,
  }) {
    return Axis(
      config: InternalAxisConfig.fromPublicConfig(config, isXAxis: isXAxis),
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

    // Calculate what the new tick interval would be
    final dataRange = newDataMax - newDataMin;
    final roughInterval = dataRange / TickGenerator.defaultTargetCount;
    final niceInterval = _makeNiceInterval(roughInterval);

    // Check if interval changed significantly (>25% to prevent oscillation)
    // The nice number sequence is 1→2→5→10 (100%, 150%, 100% jumps)
    // Using 25% threshold prevents flickering between adjacent nice numbers
    final intervalChanged = _lastTickInterval == null || 
        (niceInterval - _lastTickInterval!).abs() > _lastTickInterval! * 0.25;

    // Check if we need new ticks because data extends beyond current tick range
    // This works for both expand mode and scroll mode:
    // - Expand: triggers when data grows past rightmost tick
    // - Scroll: triggers when viewport slides past tick coverage
    bool needsNewTicks = false;
    if (!intervalChanged && _lastTickInterval != null && _lastRightmostTick != null) {
      // Need new tick on the right if data extends significantly past last tick
      // Use 0.8× interval threshold to regenerate just before hitting the edge
      if (newDataMax > _lastRightmostTick! + _lastTickInterval! * 0.8) {
        needsNewTicks = true;
      }
      // Need new tick on the left if data extends past first tick
      if (_lastLeftmostTick != null && newDataMin < _lastLeftmostTick! - _lastTickInterval! * 0.8) {
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
  List<Tick> _generateTicks() {
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
