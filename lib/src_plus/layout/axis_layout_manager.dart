/// Axis layout manager for multi-axis charts.
///
/// Computes the exact rendering rectangles for each Y-axis based on
/// their position (leftOuter, left, right, rightOuter) and configuration.
///
/// This manager works with [MultiAxisLayoutDelegate] to compute widths
/// and then generates the actual [Rect] values needed by [YAxisRenderer].
///
/// See also:
/// - [MultiAxisLayoutDelegate] for width computation
/// - [YAxisRenderer] for axis rendering
/// - [YAxisPosition] for position options
library;

import 'dart:ui' show Rect, Size;

import '../axis/y_axis_config.dart';
import '../models/y_axis_position.dart';
import 'multi_axis_layout.dart';

/// Result of axis layout computation with rendering rectangles.
class AxisLayoutRects {
  /// Creates axis layout rects.
  const AxisLayoutRects({
    required this.axisRects,
    required this.plotArea,
    required this.leftWidth,
    required this.rightWidth,
  });

  /// Rendering rectangles for each axis, keyed by axis ID.
  final Map<String, Rect> axisRects;

  /// The computed plot area after axis deduction.
  final Rect plotArea;

  /// Total width consumed by left-side axes.
  final double leftWidth;

  /// Total width consumed by right-side axes.
  final double rightWidth;

  /// Gets the rect for a specific axis.
  Rect? getRect(String axisId) => axisRects[axisId];

  @override
  String toString() => 'AxisLayoutRects(plotArea: $plotArea, axes: ${axisRects.keys.join(", ")})';
}

/// Manages axis layout and positioning for multi-axis charts.
///
/// Computes the rendering rectangles for each Y-axis based on:
/// - Axis position (leftOuter, left, right, rightOuter)
/// - Axis width (from configuration or computed from labels)
/// - Chart dimensions and padding
///
/// Example:
/// ```dart
/// final manager = AxisLayoutManager(
///   axisConfigs: [powerAxis, heartRateAxis],
///   chartSize: Size(800, 400),
/// );
///
/// final rects = manager.computeAxisRects(
///   axisBounds: {
///     'power': (min: 0, max: 400),
///     'heartRate': (min: 60, max: 180),
///   },
/// );
///
/// print('Power axis rect: ${rects.getRect('power')}');
/// print('Plot area: ${rects.plotArea}');
/// ```
class AxisLayoutManager {
  /// Creates an axis layout manager.
  ///
  /// [axisConfigs] defines the axes to layout (max 4).
  /// [chartSize] is the total available size.
  /// [topPadding] is space reserved at the top (e.g., for title).
  /// [bottomPadding] is space reserved at the bottom (e.g., for X-axis).
  /// [axisPadding] is space between adjacent axes.
  AxisLayoutManager({
    required this.axisConfigs,
    required this.chartSize,
    this.topPadding = 20.0,
    this.bottomPadding = 40.0,
    this.axisPadding = 4.0,
    this.minPlotWidth = 100.0,
  });

  /// The axis configurations.
  final List<YAxisConfig> axisConfigs;

  /// Total chart size.
  final Size chartSize;

  /// Padding at the top of the chart.
  final double topPadding;

  /// Padding at the bottom (for X-axis).
  final double bottomPadding;

  /// Padding between adjacent axes.
  final double axisPadding;

  /// Minimum plot area width (to prevent axes from squeezing plot too much).
  final double minPlotWidth;

  /// Computes the rendering rectangles for all axes.
  ///
  /// [axisBounds] provides the min/max values for each axis,
  /// used to compute appropriate label widths.
  ///
  /// Returns [AxisLayoutRects] with:
  /// - Rect for each axis (positioned correctly)
  /// - Computed plot area
  /// - Total left/right widths
  AxisLayoutRects computeAxisRects({
    Map<String, ({double min, double max})>? axisBounds,
  }) {
    final axisRects = <String, Rect>{};

    // Sort axes by position
    final leftOuter = axisConfigs.where((c) => c.position == YAxisPosition.leftOuter).toList();
    final left = axisConfigs.where((c) => c.position == YAxisPosition.left).toList();
    final right = axisConfigs.where((c) => c.position == YAxisPosition.right).toList();
    final rightOuter = axisConfigs.where((c) => c.position == YAxisPosition.rightOuter).toList();

    // Compute widths for each axis
    final widths = <String, double>{};
    for (final config in axisConfigs) {
      widths[config.id] = _computeAxisWidth(config, axisBounds?[config.id]);
    }

    // Calculate total left/right widths
    double totalLeftWidth = 0;
    for (final config in [...leftOuter, ...left]) {
      totalLeftWidth += widths[config.id]!;
    }
    if (leftOuter.isNotEmpty || left.isNotEmpty) {
      totalLeftWidth += axisPadding * (leftOuter.length + left.length);
    }

    double totalRightWidth = 0;
    for (final config in [...right, ...rightOuter]) {
      totalRightWidth += widths[config.id]!;
    }
    if (right.isNotEmpty || rightOuter.isNotEmpty) {
      totalRightWidth += axisPadding * (right.length + rightOuter.length);
    }

    // Compute plot area
    final plotHeight = chartSize.height - topPadding - bottomPadding;
    var plotWidth = chartSize.width - totalLeftWidth - totalRightWidth;

    // Ensure minimum plot width
    if (plotWidth < minPlotWidth) {
      // Scale down axis widths proportionally
      final scale = (chartSize.width - minPlotWidth) / (totalLeftWidth + totalRightWidth);
      for (final id in widths.keys) {
        widths[id] = widths[id]! * scale.clamp(0.5, 1.0);
      }
      plotWidth = minPlotWidth;
    }

    final plotLeft = totalLeftWidth;
    final plotTop = topPadding;
    final plotArea = Rect.fromLTWH(plotLeft, plotTop, plotWidth, plotHeight);

    // Position left-side axes (from outer edge towards plot area)
    double currentX = 0;

    // Left outer first (at the very left)
    for (final config in leftOuter) {
      final width = widths[config.id]!;
      axisRects[config.id] = Rect.fromLTWH(
        currentX,
        plotTop,
        width,
        plotHeight,
      );
      currentX += width + axisPadding;
    }

    // Then left (adjacent to plot area)
    for (final config in left) {
      final width = widths[config.id]!;
      axisRects[config.id] = Rect.fromLTWH(
        currentX,
        plotTop,
        width,
        plotHeight,
      );
      currentX += width + axisPadding;
    }

    // Position right-side axes (from plot area towards outer edge)
    currentX = plotArea.right + axisPadding;

    // Right first (adjacent to plot area)
    for (final config in right) {
      final width = widths[config.id]!;
      axisRects[config.id] = Rect.fromLTWH(
        currentX,
        plotTop,
        width,
        plotHeight,
      );
      currentX += width + axisPadding;
    }

    // Then right outer (at the very right)
    for (final config in rightOuter) {
      final width = widths[config.id]!;
      axisRects[config.id] = Rect.fromLTWH(
        currentX,
        plotTop,
        width,
        plotHeight,
      );
      currentX += width + axisPadding;
    }

    return AxisLayoutRects(
      axisRects: axisRects,
      plotArea: plotArea,
      leftWidth: totalLeftWidth,
      rightWidth: totalRightWidth,
    );
  }

  /// Computes the width for a single axis.
  double _computeAxisWidth(
    YAxisConfig config,
    ({double min, double max})? bounds,
  ) {
    // Use explicit bounds from config if available
    final minValue = config.min ?? bounds?.min ?? 0.0;
    final maxValue = config.max ?? bounds?.max ?? 100.0;

    // Estimate label width based on value range
    final maxAbsValue = [minValue.abs(), maxValue.abs()].reduce((a, b) => a > b ? a : b);

    // Estimate digits needed
    int digits;
    if (maxAbsValue < 0.01) {
      digits = 10; // Scientific notation
    } else if (maxAbsValue < 1) {
      digits = 6; // 0.xxx
    } else if (maxAbsValue < 10) {
      digits = 5; // x.xx
    } else if (maxAbsValue < 100) {
      digits = 4; // xx.x
    } else if (maxAbsValue < 1000) {
      digits = 4; // xxx
    } else if (maxAbsValue < 10000) {
      digits = 5; // x,xxx
    } else {
      digits = 7; // Larger numbers
    }

    // Include minus sign if negative values
    if (minValue < 0) digits += 1;

    // Include unit suffix if present
    if (config.unit != null) {
      digits += config.unit!.length + 1; // +1 for space
    }

    // Approximate width: ~7px per character + tick mark + padding
    const charWidth = 7.0;
    const tickAndPadding = 12.0;

    final estimatedWidth = digits * charWidth + tickAndPadding;

    // Clamp to configured limits
    return estimatedWidth.clamp(config.minWidth, config.maxWidth);
  }

  /// Gets axes grouped by their side (left vs right).
  ({List<YAxisConfig> left, List<YAxisConfig> right}) get axesBySide {
    final leftAxes = axisConfigs.where((c) => c.position == YAxisPosition.left || c.position == YAxisPosition.leftOuter).toList();
    final rightAxes = axisConfigs.where((c) => c.position == YAxisPosition.right || c.position == YAxisPosition.rightOuter).toList();
    return (left: leftAxes, right: rightAxes);
  }

  /// Gets the axis config for a specific position.
  YAxisConfig? getAxisAt(YAxisPosition position) {
    for (final config in axisConfigs) {
      if (config.position == position) return config;
    }
    return null;
  }

  /// Checks if a position is occupied by an axis.
  bool hasAxisAt(YAxisPosition position) => getAxisAt(position) != null;
}

/// Extension for quick layout computation with defaults.
extension AxisLayoutManagerExtension on List<YAxisConfig> {
  /// Computes axis layout for these configs with default settings.
  AxisLayoutRects computeLayout({
    required Size chartSize,
    Map<String, ({double min, double max})>? axisBounds,
    double topPadding = 20.0,
    double bottomPadding = 40.0,
  }) {
    final manager = AxisLayoutManager(
      axisConfigs: this,
      chartSize: chartSize,
      topPadding: topPadding,
      bottomPadding: bottomPadding,
    );
    return manager.computeAxisRects(axisBounds: axisBounds);
  }
}
