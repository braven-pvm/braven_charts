// Copyright (c) 2025 braven_charts. All rights reserved.
// Phase 0 Prototype - Axis System

// import 'package:flutter/foundation.dart' show debugPrint;

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

  /// Cached tick interval for throttling tick regeneration during streaming.
  /// Only regenerate ticks when the interval would change significantly.
  double? _lastTickInterval;

  /// Current data range (visible viewport).
  double get dataMin => scale.dataMin;
  double get dataMax => scale.dataMax;

  /// Current pixel range (screen position).
  double get pixelMin => scale.pixelMin;
  double get pixelMax => scale.pixelMax;

  /// Updates the visible data range (called when zooming/panning).
  ///
  /// Regenerates ticks only when the tick interval would change significantly.
  /// This throttles tick regeneration during high-frequency streaming updates.
  void updateDataRange(double newDataMin, double newDataMax) {
    scale = scale.copyWith(
      dataMin: newDataMin,
      dataMax: newDataMax,
    );

    // Calculate what the new tick interval would be
    final dataRange = newDataMax - newDataMin;
    final roughInterval = dataRange / TickGenerator.defaultTargetCount;
    final niceInterval = _makeNiceInterval(roughInterval);

    // Only regenerate ticks if interval changed significantly (>10%)
    // This throttles tick regeneration during streaming where the range
    // changes every frame but the tick spacing remains similar
    if (_lastTickInterval == null || (niceInterval - _lastTickInterval!).abs() > _lastTickInterval! * 0.1) {
      _lastTickInterval = niceInterval;
      ticks = _generateTicks();
    }
  }

  /// Rounds a value to a "nice" number for tick interval calculation.
  /// Duplicated from TickGenerator to avoid creating instance just for checking.
  double _makeNiceInterval(double roughInterval) {
    if (roughInterval <= 0) return 1.0;
    final exponent = (roughInterval.abs()).toString().split('.')[0].length - 1;
    final magnitude = _pow10(exponent.toDouble());
    final fraction = roughInterval / magnitude;

    double niceFraction;
    if (fraction <= 1.5) {
      niceFraction = 1.0;
    } else if (fraction <= 3.0) {
      niceFraction = 2.0;
    } else if (fraction <= 7.0) {
      niceFraction = 5.0;
    } else {
      niceFraction = 10.0;
    }
    return niceFraction * magnitude;
  }

  /// Fast power of 10 calculation.
  double _pow10(double exp) {
    if (exp == 0) return 1.0;
    if (exp == 1) return 10.0;
    if (exp == 2) return 100.0;
    if (exp == 3) return 1000.0;
    if (exp == -1) return 0.1;
    if (exp == -2) return 0.01;
    return 1.0; // Fallback
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
