/// Layout delegate for multi-axis chart configuration.
///
/// Computes axis widths based on label measurements and manages
/// the spatial arrangement of multiple Y-axes around the plot area.
///
/// See also:
/// - [YAxisConfig] for axis configuration options
/// - [MultiAxisState] for runtime axis state
library;

import 'package:flutter/widgets.dart' show Size, TextPainter, TextDirection, TextSpan;

import '../axis/y_axis_config.dart';
import '../models/y_axis_position.dart';

/// Computed layout result for a single axis.
class AxisLayoutResult {
  /// Creates an axis layout result.
  const AxisLayoutResult({
    required this.axisId,
    required this.position,
    required this.width,
    required this.offset,
  });

  /// The axis identifier.
  final String axisId;

  /// The axis position (leftOuter, left, right, rightOuter).
  final YAxisPosition position;

  /// The computed width in pixels.
  final double width;

  /// The offset from the chart edge in pixels.
  ///
  /// For left axes, this is the distance from the left edge.
  /// For right axes, this is the distance from the right edge.
  final double offset;

  @override
  String toString() => 'AxisLayoutResult(id: $axisId, position: $position, width: $width, offset: $offset)';
}

/// Complete layout result for all axes.
class MultiAxisLayoutResult {
  /// Creates a multi-axis layout result.
  const MultiAxisLayoutResult({
    required this.axisLayouts,
    required this.leftWidth,
    required this.rightWidth,
    required this.plotAreaWidth,
    required this.plotAreaHeight,
  });

  /// Layout results for each axis, keyed by axis ID.
  final Map<String, AxisLayoutResult> axisLayouts;

  /// Total width consumed by left-side axes.
  final double leftWidth;

  /// Total width consumed by right-side axes.
  final double rightWidth;

  /// Remaining width for the plot area after axis deduction.
  final double plotAreaWidth;

  /// Height of the plot area (unchanged from chart height minus padding).
  final double plotAreaHeight;

  /// Gets layout result for a specific axis by ID.
  AxisLayoutResult? getAxisLayout(String axisId) => axisLayouts[axisId];

  /// Gets all left-side axis layouts in order (leftOuter first, then left).
  List<AxisLayoutResult> get leftAxisLayouts {
    return axisLayouts.values.where((layout) => layout.position.isLeft).toList()
      ..sort((a, b) {
        // leftOuter comes before left
        if (a.position == YAxisPosition.leftOuter) return -1;
        if (b.position == YAxisPosition.leftOuter) return 1;
        return 0;
      });
  }

  /// Gets all right-side axis layouts in order (right first, then rightOuter).
  List<AxisLayoutResult> get rightAxisLayouts {
    return axisLayouts.values.where((layout) => layout.position.isRight).toList()
      ..sort((a, b) {
        // right comes before rightOuter
        if (a.position == YAxisPosition.right) return -1;
        if (b.position == YAxisPosition.right) return 1;
        return 0;
      });
  }

  @override
  String toString() => 'MultiAxisLayoutResult(leftWidth: $leftWidth, rightWidth: $rightWidth, plotArea: ${plotAreaWidth}x$plotAreaHeight)';
}

/// Delegate for computing multi-axis layout dimensions.
///
/// Measures axis label widths and computes the spatial arrangement
/// of multiple Y-axes around the plot area.
///
/// Example:
/// ```dart
/// final delegate = MultiAxisLayoutDelegate(
///   axisConfigs: [powerAxis, heartRateAxis],
///   chartSize: Size(800, 400),
/// );
///
/// final layout = delegate.computeLayout();
/// print('Plot area width: ${layout.plotAreaWidth}');
/// ```
class MultiAxisLayoutDelegate {
  /// Creates a multi-axis layout delegate.
  ///
  /// [axisConfigs] must contain at most 4 axes, one per position.
  /// [chartSize] is the total available size for the chart.
  MultiAxisLayoutDelegate({
    required this.axisConfigs,
    required this.chartSize,
    this.padding = 0.0,
    this.axisPadding = 4.0,
    this.labelStyle,
  }) : assert(axisConfigs.length <= 4, 'Maximum 4 axes supported') {
    _validateUniquePositions();
  }

  /// The axis configurations to layout.
  final List<YAxisConfig> axisConfigs;

  /// Total available chart size.
  final Size chartSize;

  /// Outer padding around the entire chart.
  final double padding;

  /// Padding between adjacent axes.
  final double axisPadding;

  /// Text style for measuring label widths.
  ///
  /// If null, uses a default text style for measurement.
  final String? labelStyle;

  /// Validates that no two axes share the same position.
  void _validateUniquePositions() {
    final positions = <YAxisPosition>{};
    for (final config in axisConfigs) {
      if (positions.contains(config.position)) {
        throw StateError(
          'Duplicate axis position: ${config.position}. '
          'Each position can only have one axis.',
        );
      }
      positions.add(config.position);
    }
  }

  /// Computes the axis widths based on the longest label.
  ///
  /// Uses [TextPainter] to measure label widths with the configured
  /// label formatter or default number formatting.
  ///
  /// [axisDataBounds] provides the min/max values for each axis
  /// to determine which labels need to be measured.
  MultiAxisLayoutResult computeLayout({
    Map<String, ({double min, double max})>? axisDataBounds,
  }) {
    final axisLayouts = <String, AxisLayoutResult>{};

    // Separate axes by side
    final leftConfigs = axisConfigs.where((c) => c.position.isLeft).toList()
      ..sort((a, b) {
        // leftOuter comes before left
        if (a.position == YAxisPosition.leftOuter) return -1;
        if (b.position == YAxisPosition.leftOuter) return 1;
        return 0;
      });

    final rightConfigs = axisConfigs.where((c) => c.position.isRight).toList()
      ..sort((a, b) {
        // right comes before rightOuter
        if (a.position == YAxisPosition.right) return -1;
        if (b.position == YAxisPosition.right) return 1;
        return 0;
      });

    // Compute left axis widths and offsets
    double leftOffset = padding;
    double totalLeftWidth = 0.0;

    for (final config in leftConfigs) {
      final bounds = axisDataBounds?[config.id];
      final width = _computeAxisWidth(config, bounds);

      axisLayouts[config.id] = AxisLayoutResult(
        axisId: config.id,
        position: config.position,
        width: width,
        offset: leftOffset,
      );

      leftOffset += width + axisPadding;
      totalLeftWidth += width;
    }

    // Add padding between axes if there are multiple left axes
    if (leftConfigs.length > 1) {
      totalLeftWidth += axisPadding * (leftConfigs.length - 1);
    }

    // Compute right axis widths and offsets
    double rightOffset = padding;
    double totalRightWidth = 0.0;

    for (final config in rightConfigs) {
      final bounds = axisDataBounds?[config.id];
      final width = _computeAxisWidth(config, bounds);

      axisLayouts[config.id] = AxisLayoutResult(
        axisId: config.id,
        position: config.position,
        width: width,
        offset: rightOffset,
      );

      rightOffset += width + axisPadding;
      totalRightWidth += width;
    }

    // Add padding between axes if there are multiple right axes
    if (rightConfigs.length > 1) {
      totalRightWidth += axisPadding * (rightConfigs.length - 1);
    }

    // Compute plot area dimensions
    final plotAreaWidth = chartSize.width - totalLeftWidth - totalRightWidth - (padding * 2);
    final plotAreaHeight = chartSize.height - (padding * 2);

    return MultiAxisLayoutResult(
      axisLayouts: axisLayouts,
      leftWidth: totalLeftWidth,
      rightWidth: totalRightWidth,
      plotAreaWidth: plotAreaWidth.clamp(0, double.infinity),
      plotAreaHeight: plotAreaHeight.clamp(0, double.infinity),
    );
  }

  /// Computes the width for a single axis based on its configuration
  /// and the labels that need to be displayed.
  double _computeAxisWidth(
    YAxisConfig config,
    ({double min, double max})? bounds,
  ) {
    // If no bounds provided, use the axis min/max or fallback to default range
    final minValue = bounds?.min ?? config.min ?? 0.0;
    final maxValue = bounds?.max ?? config.max ?? 100.0;

    // Generate sample labels for measurement
    final labels = _generateLabels(config, minValue, maxValue);

    // Measure each label and find the maximum width
    double maxLabelWidth = 0.0;
    for (final label in labels) {
      final width = _measureTextWidth(label);
      if (width > maxLabelWidth) {
        maxLabelWidth = width;
      }
    }

    // Add some padding for tick marks and spacing
    final computedWidth = maxLabelWidth + 8.0; // 8px for tick mark and padding

    // Clamp to the configured min/max width
    return computedWidth.clamp(config.minWidth, config.maxWidth);
  }

  /// Generates sample labels for width measurement.
  List<String> _generateLabels(YAxisConfig config, double min, double max) {
    final labels = <String>[];
    final tickCount = config.tickCount ?? 5;

    // Generate labels at regular intervals
    final step = (max - min) / (tickCount - 1);
    for (int i = 0; i < tickCount; i++) {
      final value = min + (step * i);
      final label = _formatValue(config, value);
      labels.add(label);
    }

    return labels;
  }

  /// Formats a value using the axis formatter or default formatting.
  String _formatValue(YAxisConfig config, double value) {
    if (config.labelFormatter != null) {
      return config.labelFormatter!(value);
    }

    // Default formatting: auto-determine decimal places based on range
    if (value.abs() < 0.01) {
      return value.toStringAsExponential(1);
    } else if (value.abs() < 1) {
      return value.toStringAsFixed(3);
    } else if (value.abs() < 10) {
      return value.toStringAsFixed(2);
    } else if (value.abs() < 100) {
      return value.toStringAsFixed(1);
    } else {
      return value.toStringAsFixed(0);
    }
  }

  /// Measures the width of text in pixels.
  ///
  /// Uses a simple approximation based on character count and average
  /// character width. For exact measurements, a [TextPainter] with
  /// the actual font metrics should be used.
  double _measureTextWidth(String text) {
    // Simple approximation: ~7 pixels per character for typical fonts
    // This provides a reasonable estimate without requiring a BuildContext
    // A more accurate implementation would use TextPainter with actual style
    const averageCharWidth = 7.0;
    return text.length * averageCharWidth;
  }

  /// Measures text width using [TextPainter] for more accurate results.
  ///
  /// This method provides precise measurements but requires a [TextPainter]
  /// to be created and laid out.
  double measureTextWidthAccurate(String text, TextPainter painter) {
    painter.text = TextSpan(text: text);
    painter.textDirection = TextDirection.ltr;
    painter.layout();
    return painter.width;
  }
}
