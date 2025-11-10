// Copyright (c) 2025 braven_charts. All rights reserved.
// Phase 0 Prototype - Axis System

import 'package:flutter/foundation.dart' show debugPrint;

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
/// final xAxis = Axis(
///   config: AxisConfig(
///     orientation: AxisOrientation.horizontal,
///     position: AxisPosition.bottom,
///     label: 'Time',
///   ),
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
  /// Visual configuration.
  final AxisConfig config;

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

  /// Updates the visible data range (called when zooming/panning).
  ///
  /// Regenerates ticks for the new range.
  void updateDataRange(double newDataMin, double newDataMax) {
    scale = scale.copyWith(
      dataMin: newDataMin,
      dataMax: newDataMax,
    );

    ticks = _generateTicks();
    debugPrint('   Axis ticks regenerated: ${ticks.length} ticks for range [$newDataMin, $newDataMax]');
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
