// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

import 'dart:math' as math;

import 'package:flutter/painting.dart';

import '../layout/axis_layout_manager.dart';
import '../layout/multi_axis_layout.dart';
import '../models/chart_series.dart';
import '../models/series_axis_binding.dart';
import '../models/y_axis_config.dart';
import '../models/y_axis_position.dart';
import 'axis_color_resolver.dart';
import 'multi_axis_normalizer.dart';

/// Paints multiple Y-axes with their tick marks and labels.
///
/// This painter handles the visual rendering of Y-axes in multi-axis charts.
/// Each axis displays tick marks and labels showing original data values
/// (not normalized values), using FR-005 requirements.
///
/// The painter uses:
/// - [MultiAxisLayoutDelegate] to compute axis widths
/// - [AxisLayoutManager] to position axes
/// - Nice number algorithm for readable tick values
///
/// Example:
/// ```dart
/// final painter = MultiAxisPainter(
///   axes: [powerAxis, hrAxis],
///   axisBounds: {'power': powerRange, 'heartrate': hrRange},
///   labelStyle: TextStyle(fontSize: 12),
/// );
/// painter.paint(canvas, chartArea, plotArea);
/// ```
class MultiAxisPainter {
  /// Creates a multi-axis painter.
  ///
  /// [axes] is the list of Y-axis configurations to render.
  /// [axisBounds] maps axis IDs to their data ranges.
  /// [bindings] is the list of series-to-axis bindings for color resolution.
  /// [series] is the list of data series for color resolution.
  /// [labelStyle] is optional; uses default style if not provided.
  MultiAxisPainter({
    required this.axes,
    required this.axisBounds,
    this.bindings = const [],
    this.series = const [],
    TextStyle? labelStyle,
  }) : labelStyle = labelStyle ?? _defaultLabelStyle;

  /// List of Y-axis configurations to render.
  final List<YAxisConfig> axes;

  /// Map from axis ID to data range for tick value computation.
  final Map<String, DataRange> axisBounds;

  /// List of series-to-axis bindings for color resolution.
  ///
  /// Used to determine axis colors when [YAxisConfig.color] is null.
  final List<SeriesAxisBinding> bindings;

  /// List of data series for color resolution.
  ///
  /// Used to determine axis colors when [YAxisConfig.color] is null.
  final List<ChartSeries> series;

  /// Text style for tick labels.
  final TextStyle labelStyle;

  /// Default text style for labels.
  static const TextStyle _defaultLabelStyle = TextStyle(
    fontSize: 11,
    color: Color(0xFF666666),
  );

  /// Default tick mark length.
  static const double _tickLength = 6.0;

  /// Default axis line width.
  static const double _axisLineWidth = 1.0;

  /// Layout delegate for computing widths.
  final _layoutDelegate = const MultiAxisLayoutDelegate();

  /// Layout manager for positioning.
  final _layoutManager = const AxisLayoutManager();

  /// Cached axis widths.
  Map<String, double>? _cachedWidths;

  /// Paints all configured axes on the canvas.
  ///
  /// [canvas] is the canvas to draw on.
  /// [chartArea] is the total chart area (axes will be painted in reserved space).
  /// [plotArea] is the data rendering area (axes align to this).
  void paint(Canvas canvas, Rect chartArea, Rect plotArea) {
    if (axes.isEmpty) return;

    // Compute widths if not cached
    _cachedWidths ??= _layoutDelegate.computeAxisWidths(
      axes: axes,
      axisBounds: axisBounds,
      labelStyle: labelStyle,
    );

    // Paint each axis
    for (final axis in axes) {
      final bounds = axisBounds[axis.id];
      if (bounds == null) continue;

      final axisRect = _layoutManager.getAxisRect(
        chartArea: chartArea,
        axis: axis,
        axisWidths: _cachedWidths!,
        allAxes: axes,
      );

      _paintAxis(canvas, axis, axisRect, plotArea, bounds);
    }
  }

  /// Paints a single axis.
  void _paintAxis(
    Canvas canvas,
    YAxisConfig axis,
    Rect axisRect,
    Rect plotArea,
    DataRange bounds,
  ) {
    final axisColor = AxisColorResolver.resolveAxisColor(
      axis,
      bindings,
      series,
    );
    final paint = Paint()
      ..color = axisColor
      ..strokeWidth = _axisLineWidth
      ..style = PaintingStyle.stroke;

    // Determine if this is a left-side or right-side axis
    final isLeftSide = axis.position == YAxisPosition.left || axis.position == YAxisPosition.leftOuter;

    // Paint axis line
    if (axis.showAxisLine) {
      final lineX = isLeftSide ? axisRect.right : axisRect.left;
      canvas.drawLine(
        Offset(lineX, plotArea.top),
        Offset(lineX, plotArea.bottom),
        paint,
      );
    }

    // Paint axis label (rotated 90°, centered on axis)
    // Uses shouldShowAxisLabel helper to check labelDisplay mode
    if (axis.label != null && axis.label!.isNotEmpty && axis.shouldShowAxisLabel) {
      _paintAxisLabel(canvas, axis, axisRect, plotArea, isLeftSide, axisColor);
    }

    // Generate and paint ticks
    // Uses shouldShowTickLabels helper to check labelDisplay mode
    if (axis.showTicks || axis.shouldShowTickLabels) {
      final maxTicks = axis.tickCount ?? _computeMaxTicks(plotArea.height);
      final ticks = generateTicks(bounds, maxTicks: maxTicks);

      for (final tickValue in ticks) {
        // Convert tick value to Y position using shared normalizer
        final normalizedY = MultiAxisNormalizer.normalize(tickValue, bounds.min, bounds.max);
        // Invert Y because screen coordinates go down
        final screenY = plotArea.bottom - (normalizedY * plotArea.height);

        // Only paint if within plot area
        if (screenY >= plotArea.top && screenY <= plotArea.bottom) {
          if (axis.showTicks) {
            _paintTickMark(canvas, axis, axisRect, screenY, isLeftSide, paint);
          }

          if (axis.shouldShowTickLabels) {
            _paintTickLabel(canvas, axis, axisRect, screenY, tickValue, isLeftSide);
          }
        }
      }
    }
  }

  /// Paints the axis title label rotated 90 degrees.
  ///
  /// The label is centered vertically along the axis and positioned
  /// within the axis strip area. Left-side axes rotate counter-clockwise
  /// (text reads bottom-to-top), right-side axes rotate clockwise
  /// (text reads top-to-bottom).
  ///
  /// If [axis.shouldAppendUnitToLabel] is true, the unit is appended
  /// to the label in parentheses (e.g., "Power (W)").
  void _paintAxisLabel(
    Canvas canvas,
    YAxisConfig axis,
    Rect axisRect,
    Rect plotArea,
    bool isLeftSide,
    Color axisColor,
  ) {
    // Build label text with optional unit suffix
    String labelText = axis.label!;
    if (axis.shouldAppendUnitToLabel && axis.unit != null && axis.unit!.isNotEmpty) {
      labelText = '$labelText (${axis.unit})';
    }

    final textPainter = TextPainter(
      text: TextSpan(
        text: labelText,
        style: TextStyle(
          color: axisColor,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    canvas.save();

    // Position at the vertical center of the plot area
    final centerY = plotArea.top + plotArea.height / 2;

    // Position horizontally within the axis strip
    // The text is rotated 90°, so textPainter.height is the effective width
    // axisMargin provides space from the outer edge
    final labelX =
        isLeftSide ? axisRect.left + axis.axisMargin + (textPainter.height / 2) : axisRect.right - axis.axisMargin - (textPainter.height / 2);

    canvas.translate(labelX, centerY);

    // Rotate: left axes rotate -90° (CCW), right axes rotate +90° (CW)
    canvas.rotate(isLeftSide ? -math.pi / 2 : math.pi / 2);

    // Center the text on the rotation point
    canvas.translate(-textPainter.width / 2, -textPainter.height / 2);

    textPainter.paint(canvas, Offset.zero);

    canvas.restore();
  }

  /// Paints a tick mark at the specified Y position.
  void _paintTickMark(
    Canvas canvas,
    YAxisConfig axis,
    Rect axisRect,
    double screenY,
    bool isLeftSide,
    Paint paint,
  ) {
    double tickStart;
    double tickEnd;

    if (isLeftSide) {
      tickStart = axisRect.right;
      tickEnd = axisRect.right - _tickLength;
    } else {
      tickStart = axisRect.left;
      tickEnd = axisRect.left + _tickLength;
    }

    canvas.drawLine(
      Offset(tickStart, screenY),
      Offset(tickEnd, screenY),
      paint,
    );
  }

  /// Paints a tick label at the specified Y position.
  void _paintTickLabel(
    Canvas canvas,
    YAxisConfig axis,
    Rect axisRect,
    double screenY,
    double value,
    bool isLeftSide,
  ) {
    final label = formatTickLabel(value, axis);
    final labelColor = AxisColorResolver.resolveAxisColor(
      axis,
      bindings,
      series,
    );

    final textPainter = TextPainter(
      text: TextSpan(
        text: label,
        style: labelStyle.copyWith(color: labelColor),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    double labelX;
    if (isLeftSide) {
      // Right-align labels on left-side axes, positioned from axis line inward
      // Layout: [margin][axisLabel][axisLabelPadding][tickLabels][tickLabelPadding][tickMark][axisLine]
      labelX = axisRect.right - _tickLength - axis.tickLabelPadding - textPainter.width;
    } else {
      // Left-align labels on right-side axes, positioned from axis line inward
      labelX = axisRect.left + _tickLength + axis.tickLabelPadding;
    }

    // Center label vertically on tick
    final labelY = screenY - textPainter.height / 2;

    textPainter.paint(canvas, Offset(labelX, labelY));
  }

  /// Generates nice tick values for an axis.
  ///
  /// Uses the "nice numbers" algorithm to generate human-readable tick values
  /// like 0, 50, 100 instead of arbitrary values like 17, 83, 149.
  ///
  /// [bounds] is the data range for the axis.
  /// [maxTicks] is the maximum number of tick marks to generate.
  ///
  /// Returns a list of tick values within the bounds.
  List<double> generateTicks(DataRange bounds, {int maxTicks = 10}) {
    if (bounds.span == 0) {
      return [bounds.min];
    }

    // Calculate nice tick spacing
    final range = bounds.span;
    final roughStep = range / (maxTicks - 1);
    final nicedStep = _niceNum(roughStep, round: true);

    // Calculate tick bounds
    final niceMin = (bounds.min / nicedStep).floor() * nicedStep;
    final niceMax = (bounds.max / nicedStep).ceil() * nicedStep;

    // Generate ticks
    final ticks = <double>[];
    for (var tick = niceMin; tick <= niceMax; tick += nicedStep) {
      // Only include ticks within the actual bounds
      if (tick >= bounds.min && tick <= bounds.max) {
        ticks.add(_roundToDecimals(tick, 10));
      }
    }

    // Ensure we have at least min and max as ticks if list is empty
    if (ticks.isEmpty) {
      ticks.add(bounds.min);
      if (bounds.min != bounds.max) {
        ticks.add(bounds.max);
      }
    }

    return ticks;
  }

  /// Formats a tick value with optional unit suffix.
  ///
  /// Uses the custom [YAxisConfig.labelFormatter] if provided,
  /// otherwise formats the number and optionally appends the unit suffix
  /// based on [YAxisConfig.shouldShowTickUnit].
  ///
  /// [value] is the tick value to format.
  /// [axis] is the axis configuration containing formatting options.
  String formatTickLabel(double value, YAxisConfig axis) {
    if (axis.labelFormatter != null) {
      return axis.labelFormatter!(value);
    }

    String formatted;
    if (value == value.roundToDouble()) {
      formatted = value.toInt().toString();
    } else if (value.abs() < 1) {
      // Small decimals - show more precision
      formatted = value.toStringAsFixed(2);
    } else if (value.abs() < 100) {
      // Medium values - show one decimal if needed
      final rounded = _roundToDecimals(value, 1);
      if (rounded == rounded.roundToDouble()) {
        formatted = rounded.toInt().toString();
      } else {
        formatted = rounded.toStringAsFixed(1);
      }
    } else {
      // Large values - show as integer
      formatted = value.round().toString();
    }

    // Only append unit if shouldShowTickUnit is true
    if (axis.shouldShowTickUnit && axis.unit != null) {
      formatted = '$formatted ${axis.unit}';
    }

    return formatted;
  }

  /// Computes maximum ticks based on available height.
  int _computeMaxTicks(double height) {
    // Roughly one tick per 40-50 pixels
    return math.max(2, (height / 45).floor());
  }

  /// Returns a "nice" number that is approximately equal to range.
  ///
  /// A "nice" number is either 1, 2, or 5 times a power of 10.
  /// If [round] is true, rounds to nearest nice number; otherwise rounds up.
  double _niceNum(double range, {bool round = true}) {
    if (range == 0) return 0;

    final exponent = (math.log(range.abs()) / math.ln10).floor();
    final fraction = range / math.pow(10, exponent);

    double niceFraction;
    if (round) {
      if (fraction < 1.5) {
        niceFraction = 1;
      } else if (fraction < 3) {
        niceFraction = 2;
      } else if (fraction < 7) {
        niceFraction = 5;
      } else {
        niceFraction = 10;
      }
    } else {
      if (fraction <= 1) {
        niceFraction = 1;
      } else if (fraction <= 2) {
        niceFraction = 2;
      } else if (fraction <= 5) {
        niceFraction = 5;
      } else {
        niceFraction = 10;
      }
    }

    return niceFraction * math.pow(10, exponent);
  }

  /// Rounds a value to the specified number of decimal places.
  double _roundToDecimals(double value, int decimals) {
    final factor = math.pow(10, decimals);
    return (value * factor).round() / factor;
  }
}
