/// Multi-axis Y-axis renderer for charts.
///
/// Renders multiple Y-axes at different positions around the plot area:
/// - leftOuter: Left of the primary left axis
/// - left: Adjacent to plot area on the left
/// - right: Adjacent to plot area on the right
/// - rightOuter: Right of the primary right axis
///
/// Each axis is rendered with its own color (from config or series),
/// tick marks, labels, and optional axis label.
///
/// See also:
/// - [YAxisConfig] for axis configuration
/// - [SeriesAxisResolver] for series-to-axis binding
/// - [AxisLayoutManager] for computing axis positions
library;

import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart' show TextPainter, TextSpan, TextDirection, Colors;

import '../axis/y_axis_config.dart';
import '../models/chart_theme.dart';
import '../models/y_axis_position.dart';

/// Renders a single Y-axis for multi-axis charts.
///
/// Each Y-axis can be customized with:
/// - Position (leftOuter, left, right, rightOuter)
/// - Color for line, ticks, and labels
/// - Optional label and unit
/// - Computed or explicit min/max bounds
///
/// Example:
/// ```dart
/// final renderer = YAxisRenderer(
///   config: powerAxis,
///   bounds: (min: 0, max: 400),
///   axisRect: Rect.fromLTWH(0, 50, 60, 400),
/// );
/// renderer.paint(canvas, plotArea);
/// ```
class YAxisRenderer {
  /// Creates a Y-axis renderer.
  ///
  /// [config] defines the axis appearance and behavior.
  /// [bounds] specifies the min/max values for tick generation.
  /// [axisRect] defines where the axis is drawn (computed by layout manager).
  /// [theme] provides optional theme overrides.
  YAxisRenderer({
    required this.config,
    required this.bounds,
    required this.axisRect,
    this.theme,
    this.tickCount = 5,
  });

  /// The axis configuration.
  final YAxisConfig config;

  /// The computed bounds (min, max) for this axis.
  final ({double min, double max}) bounds;

  /// The rectangle where this axis is rendered.
  ///
  /// Width is the axis width (for labels and ticks).
  /// Height matches the plot area height.
  final Rect axisRect;

  /// Optional chart theme for styling.
  final ChartTheme? theme;

  /// Number of tick marks to display.
  final int tickCount;

  /// Paints the Y-axis on the canvas.
  ///
  /// [canvas] is the canvas to draw on.
  /// [plotArea] is the main chart plotting area.
  void paint(Canvas canvas, Rect plotArea) {
    if (!config.showAxisLine && !config.showLabels && !config.showTicks) {
      return; // Nothing to render
    }

    final axisColor = config.color ?? Colors.grey;
    final isLeftSide = config.position == YAxisPosition.left || config.position == YAxisPosition.leftOuter;

    // Calculate axis line X position
    final axisLineX = isLeftSide ? axisRect.right : axisRect.left;

    // Draw axis line
    if (config.showAxisLine) {
      _paintAxisLine(canvas, plotArea, axisLineX, axisColor);
    }

    // Generate and draw ticks
    final ticks = _generateTicks();
    for (final tick in ticks) {
      final y = _valueToPixel(tick.value, plotArea);

      // Skip if outside plot area
      if (y < plotArea.top || y > plotArea.bottom) continue;

      // Draw tick mark
      if (config.showTicks) {
        _paintTick(canvas, y, axisLineX, axisColor, isLeftSide);
      }

      // Draw tick label
      if (config.showLabels) {
        _paintTickLabel(canvas, tick.label, y, axisLineX, axisColor, isLeftSide);
      }
    }

    // Draw axis label (rotated)
    if (config.label != null && config.label!.isNotEmpty) {
      _paintAxisLabel(canvas, plotArea, axisColor, isLeftSide);
    }
  }

  /// Paints the main axis line.
  void _paintAxisLine(Canvas canvas, Rect plotArea, double axisX, Color color) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = theme?.axisStyle.lineWidth ?? 1.0;

    canvas.drawLine(
      Offset(axisX, plotArea.top),
      Offset(axisX, plotArea.bottom),
      paint,
    );
  }

  /// Paints a single tick mark.
  void _paintTick(Canvas canvas, double y, double axisX, Color color, bool isLeftSide) {
    final tickLength = theme?.axisStyle.tickLength ?? 6.0;
    final paint = Paint()
      ..color = color
      ..strokeWidth = theme?.axisStyle.tickWidth ?? 1.0;

    final x1 = isLeftSide ? axisX - tickLength : axisX;
    final x2 = isLeftSide ? axisX : axisX + tickLength;

    canvas.drawLine(Offset(x1, y), Offset(x2, y), paint);
  }

  /// Paints a tick label.
  void _paintTickLabel(
    Canvas canvas,
    String label,
    double y,
    double axisX,
    Color color,
    bool isLeftSide,
  ) {
    final tickLength = theme?.axisStyle.tickLength ?? 6.0;
    final labelPadding = theme?.axisStyle.labelPadding ?? 4.0;

    final textPainter = TextPainter(
      text: TextSpan(
        text: label,
        style: theme?.axisStyle.labelStyle.copyWith(color: color) ?? TextStyle(fontSize: 10, color: color),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final labelX = isLeftSide ? axisX - tickLength - labelPadding - textPainter.width : axisX + tickLength + labelPadding;

    textPainter.paint(
      canvas,
      Offset(labelX, y - textPainter.height / 2),
    );
  }

  /// Paints the axis label (rotated 90°).
  void _paintAxisLabel(Canvas canvas, Rect plotArea, Color color, bool isLeftSide) {
    canvas.save();

    final labelX = isLeftSide ? axisRect.left + 12 : axisRect.right - 12;
    final labelY = plotArea.top + plotArea.height / 2;

    canvas.translate(labelX, labelY);
    canvas.rotate(-math.pi / 2);

    String labelText = config.label ?? '';
    if (config.unit != null && config.unit!.isNotEmpty) {
      labelText += ' (${config.unit})';
    }

    final labelPainter = TextPainter(
      text: TextSpan(
        text: labelText,
        style: theme?.axisStyle.axisLabelStyle?.copyWith(color: color) ?? TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.bold),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    labelPainter.paint(canvas, Offset(-labelPainter.width / 2, 0));

    canvas.restore();
  }

  /// Converts a data value to pixel Y coordinate.
  double _valueToPixel(double value, Rect plotArea) {
    final range = bounds.max - bounds.min;
    if (range == 0) return plotArea.top + plotArea.height / 2;

    // Invert Y: larger values at top
    final normalized = (value - bounds.min) / range;
    return plotArea.bottom - (normalized * plotArea.height);
  }

  /// Generates tick marks for the axis.
  List<_Tick> _generateTicks() {
    final ticks = <_Tick>[];
    final range = bounds.max - bounds.min;

    if (range == 0) {
      // Single tick at the center
      ticks.add(_Tick(bounds.min, _formatValue(bounds.min)));
      return ticks;
    }

    // Calculate nice step
    final rawStep = range / (tickCount - 1);
    final step = _niceStep(rawStep);

    // Find nice min
    final niceMin = (bounds.min / step).floor() * step;

    // Generate ticks
    var value = niceMin;
    while (value <= bounds.max + step * 0.001) {
      if (value >= bounds.min - step * 0.001) {
        ticks.add(_Tick(value, _formatValue(value)));
      }
      value += step;
    }

    // Ensure we have at least min and max
    if (ticks.isEmpty) {
      ticks.add(_Tick(bounds.min, _formatValue(bounds.min)));
      ticks.add(_Tick(bounds.max, _formatValue(bounds.max)));
    }

    return ticks;
  }

  /// Calculates a "nice" step size for tick marks.
  double _niceStep(double rawStep) {
    if (rawStep <= 0) return 1;

    // Calculate order of magnitude
    final magnitude = _pow10(_log10(rawStep).floor());
    final normalizedStep = rawStep / magnitude;

    // Round to nice number
    double niceNorm;
    if (normalizedStep < 1.5) {
      niceNorm = 1;
    } else if (normalizedStep < 3) {
      niceNorm = 2;
    } else if (normalizedStep < 7) {
      niceNorm = 5;
    } else {
      niceNorm = 10;
    }

    return niceNorm * magnitude;
  }

  /// Formats a value for display as a tick label.
  String _formatValue(double value) {
    // Use custom formatter if provided
    if (config.labelFormatter != null) {
      return config.labelFormatter!(value);
    }

    // Auto-format based on range
    final range = bounds.max - bounds.min;

    if (range == 0) {
      return value.toString();
    }

    // Determine appropriate precision
    int decimals;
    if (range >= 100) {
      decimals = 0;
    } else if (range >= 10) {
      decimals = 1;
    } else if (range >= 1) {
      decimals = 2;
    } else {
      // For small ranges, use more precision
      decimals = (-_log10(range).floor() + 2).clamp(0, 6);
    }

    return value.toStringAsFixed(decimals);
  }

  /// Power of 10.
  static double _pow10(int exponent) {
    double result = 1.0;
    if (exponent >= 0) {
      for (int i = 0; i < exponent; i++) {
        result *= 10.0;
      }
    } else {
      for (int i = 0; i > exponent; i--) {
        result /= 10.0;
      }
    }
    return result;
  }

  /// Log base 10.
  static double _log10(double x) {
    if (x <= 0) return 0;
    return _ln(x) / 2.302585092994046; // ln(10)
  }

  /// Natural log approximation.
  static double _ln(double x) {
    if (x <= 0) return double.negativeInfinity;
    int exp = 0;
    while (x > 2) {
      x /= 2;
      exp++;
    }
    while (x < 1) {
      x *= 2;
      exp--;
    }
    final y = x - 1;
    double sum = 0;
    double term = y;
    for (int i = 1; i <= 20; i++) {
      sum += term / i;
      term *= -y;
    }
    return sum + exp * 0.6931471805599453; // ln(2)
  }
}

/// Internal tick representation.
class _Tick {
  const _Tick(this.value, this.label);
  final double value;
  final String label;
}

/// Renders multiple Y-axes for a chart.
///
/// Orchestrates the rendering of all configured Y-axes,
/// positioning them according to their [YAxisPosition].
///
/// Example:
/// ```dart
/// final renderer = MultiYAxisRenderer(
///   configs: [powerAxis, heartRateAxis],
///   bounds: {
///     'power': (min: 0, max: 400),
///     'heartRate': (min: 60, max: 180),
///   },
///   axisRects: {
///     'power': Rect.fromLTWH(0, 50, 60, 400),
///     'heartRate': Rect.fromLTWH(740, 50, 60, 400),
///   },
/// );
/// renderer.paint(canvas, plotArea);
/// ```
class MultiYAxisRenderer {
  /// Creates a multi Y-axis renderer.
  MultiYAxisRenderer({
    required this.configs,
    required this.bounds,
    required this.axisRects,
    this.theme,
    this.tickCount = 5,
  });

  /// All Y-axis configurations.
  final List<YAxisConfig> configs;

  /// Bounds for each axis, keyed by axis ID.
  final Map<String, ({double min, double max})> bounds;

  /// Rendering rectangles for each axis, keyed by axis ID.
  final Map<String, Rect> axisRects;

  /// Optional chart theme.
  final ChartTheme? theme;

  /// Number of ticks per axis.
  final int tickCount;

  /// Paints all Y-axes.
  void paint(Canvas canvas, Rect plotArea) {
    for (final config in configs) {
      final axisBounds = bounds[config.id];
      final axisRect = axisRects[config.id];

      if (axisBounds == null || axisRect == null) continue;

      final renderer = YAxisRenderer(
        config: config,
        bounds: axisBounds,
        axisRect: axisRect,
        theme: theme,
        tickCount: tickCount,
      );

      renderer.paint(canvas, plotArea);
    }
  }

  /// Gets the total width consumed by left-side axes.
  double get leftAxesWidth {
    double width = 0;
    for (final config in configs) {
      if (config.position == YAxisPosition.left || config.position == YAxisPosition.leftOuter) {
        final rect = axisRects[config.id];
        if (rect != null) width += rect.width;
      }
    }
    return width;
  }

  /// Gets the total width consumed by right-side axes.
  double get rightAxesWidth {
    double width = 0;
    for (final config in configs) {
      if (config.position == YAxisPosition.right || config.position == YAxisPosition.rightOuter) {
        final rect = axisRects[config.id];
        if (rect != null) width += rect.width;
      }
    }
    return width;
  }
}
