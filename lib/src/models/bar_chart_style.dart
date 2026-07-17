// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

import 'dart:ui' show Color;

import 'package:flutter/painting.dart' show FontWeight;

import 'chart_data_point.dart';

/// Selects which screen axis carries categories and values for a bar series.
enum BarOrientation {
  /// Categories run left-to-right and values grow vertically.
  vertical,

  /// Categories run top-to-bottom and values grow horizontally.
  ///
  /// Horizontal bars transpose the complete Cartesian chart so the semantic
  /// X values remain categories and semantic Y values remain measurements.
  horizontal,
}

/// Determines how bar series share category slots.
enum BarLayoutMode {
  /// Give every series its own side-by-side slot.
  grouped,

  /// Draw series in the same named group on a shared category center.
  ///
  /// Each series retains its own width and value. Series later in the chart's
  /// series list paint in front of earlier series, which supports wide
  /// reference bars behind narrower comparison bars.
  overlaid,

  /// Stack raw contributions for series sharing the same group ID.
  stacked,

  /// Stack contributions as a percentage of the positive or negative total.
  normalizedStacked,

  /// Accumulate each point as a sequential increase or decrease.
  ///
  /// Points listed in [BarChartSeries.waterfallTotalIndices] render the
  /// running total from the series baseline instead of applying their `y`
  /// value as another delta.
  waterfall,
}

/// Determines which corners of a bar receive [BarChartStyle.cornerRadius].
enum BarCornerRadiusPolicy {
  /// Round every corner.
  all,

  /// Round only the corners at the value end of the bar.
  ///
  /// Positive bars round away from their baseline (top for vertical, right for
  /// horizontal); negative bars round the opposite end.
  valueEnd,
}

/// A serializable linear gradient used to fill bars.
///
/// The gradient follows the value axis: baseline to value end for each bar.
class BarGradient {
  const BarGradient({required this.colors, this.stops});

  final List<Color> colors;
  final List<double>? stops;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BarGradient &&
          _listEquals(other.colors, colors) &&
          _listEquals(other.stops, stops);

  @override
  int get hashCode =>
      Object.hash(Object.hashAll(colors), Object.hashAll(stops ?? const []));
}

/// Optional border drawn around each bar.
class BarBorderStyle {
  const BarBorderStyle({required this.color, this.width = 1.0})
    : assert(width >= 0, 'Border width must be non-negative');

  final Color color;
  final double width;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BarBorderStyle && other.color == color && other.width == width;

  @override
  int get hashCode => Object.hash(color, width);
}

/// Visual styling shared by all bars in a series.
class BarChartStyle {
  const BarChartStyle({
    this.cornerRadius = 0.0,
    this.cornerRadiusPolicy = BarCornerRadiusPolicy.valueEnd,
    this.gradient,
    this.border,
    this.opacity = 1.0,
  }) : assert(cornerRadius >= 0, 'Corner radius must be non-negative'),
       assert(opacity >= 0 && opacity <= 1, 'Opacity must be between 0 and 1');

  final double cornerRadius;
  final BarCornerRadiusPolicy cornerRadiusPolicy;
  final BarGradient? gradient;
  final BarBorderStyle? border;
  final double opacity;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BarChartStyle &&
          other.cornerRadius == cornerRadius &&
          other.cornerRadiusPolicy == cornerRadiusPolicy &&
          other.gradient == gradient &&
          other.border == border &&
          other.opacity == opacity;

  @override
  int get hashCode =>
      Object.hash(cornerRadius, cornerRadiusPolicy, gradient, border, opacity);
}

/// A passive capacity or target track rendered behind each bar.
class BarTrackStyle {
  const BarTrackStyle({
    required this.color,
    this.value,
    this.opacity = 1.0,
    this.cornerRadius,
    this.border,
  }) : assert(opacity >= 0 && opacity <= 1, 'Opacity must be between 0 and 1'),
       assert(
         cornerRadius == null || cornerRadius >= 0,
         'Corner radius must be non-negative',
       );

  /// Track fill color.
  final Color color;

  /// Explicit track value. When null, the visible value-axis boundary is used.
  final double? value;

  final double opacity;

  /// Track radius. When null, the bar radius is used.
  final double? cornerRadius;

  final BarBorderStyle? border;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BarTrackStyle &&
          other.color == color &&
          other.value == value &&
          other.opacity == opacity &&
          other.cornerRadius == cornerRadius &&
          other.border == border;

  @override
  int get hashCode => Object.hash(color, value, opacity, cornerRadius, border);
}

/// Connector line drawn between sequential waterfall columns.
class BarWaterfallConnectorStyle {
  const BarWaterfallConnectorStyle({
    this.show = true,
    this.color = const Color(0xFF9CA3AF),
    this.width = 1.0,
  }) : assert(width >= 0, 'Connector width must be non-negative');

  final bool show;
  final Color color;
  final double width;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BarWaterfallConnectorStyle &&
          other.show == show &&
          other.color == color &&
          other.width == width;

  @override
  int get hashCode => Object.hash(show, color, width);
}

/// Semantic colors and connector presentation for waterfall bars.
class BarWaterfallStyle {
  const BarWaterfallStyle({
    this.increaseColor,
    this.decreaseColor,
    this.totalColor,
    this.connector = const BarWaterfallConnectorStyle(),
  });

  /// Color for positive deltas. Null uses the series color.
  final Color? increaseColor;

  /// Color for negative deltas. Null uses the series color.
  final Color? decreaseColor;

  /// Color for running-total columns. Null uses the series color.
  final Color? totalColor;

  final BarWaterfallConnectorStyle connector;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BarWaterfallStyle &&
          other.increaseColor == increaseColor &&
          other.decreaseColor == decreaseColor &&
          other.totalColor == totalColor &&
          other.connector == connector;

  @override
  int get hashCode =>
      Object.hash(increaseColor, decreaseColor, totalColor, connector);
}

/// Position of a value label relative to its bar.
enum BarLabelPosition {
  /// Choose inside-end when it fits, otherwise outside-end.
  auto,

  /// Place the label near the value end, inside the bar.
  insideEnd,

  /// Center the label inside the bar.
  insideCenter,

  /// Place the label just beyond the value end.
  outsideEnd,

  /// Place the lower and upper values at opposite ends of the bar.
  ///
  /// This is especially useful for floating/range bars. Endpoint labels wrap
  /// or rotate when grouped bars do not provide enough horizontal space.
  rangeEnds,
}

/// Selects the value represented by a bar label.
enum BarLabelValueMode {
  /// Display the original point value.
  value,

  /// Display the resolved range start and end values.
  range,

  /// Display the segment percentage calculated by normalized stacking.
  percentage,

  /// Display deltas for waterfall steps and cumulative values for totals.
  waterfall,
}

/// Optional value labels rendered using bar geometry rather than marker geometry.
class BarLabelStyle {
  const BarLabelStyle({
    this.show = false,
    this.position = BarLabelPosition.auto,
    this.valueMode = BarLabelValueMode.value,
    this.color,
    this.fontSize = 10.0,
    this.fontWeight = FontWeight.w600,
    this.showUnit = false,
    this.padding = 4.0,
    this.formatter,
  }) : assert(fontSize > 0, 'Font size must be positive'),
       assert(padding >= 0, 'Padding must be non-negative');

  final bool show;
  final BarLabelPosition position;
  final BarLabelValueMode valueMode;
  final Color? color;
  final double fontSize;
  final FontWeight fontWeight;
  final bool showUnit;

  /// Minimum logical-pixel gap between an end label and the bar edge.
  ///
  /// Inside-end labels may use a larger inset when required to clear a
  /// rounded value end. Outside-end and range-end labels use this value as
  /// their exact gap.
  final double padding;

  /// Runtime-only formatter. Portable artifacts intentionally omit callbacks.
  final String Function(ChartDataPoint)? formatter;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BarLabelStyle &&
          other.show == show &&
          other.position == position &&
          other.valueMode == valueMode &&
          other.color == color &&
          other.fontSize == fontSize &&
          other.fontWeight == fontWeight &&
          other.showUnit == showUnit &&
          other.padding == padding &&
          other.formatter == formatter;

  @override
  int get hashCode => Object.hash(
    show,
    position,
    valueMode,
    color,
    fontSize,
    fontWeight,
    showUnit,
    padding,
    formatter,
  );
}

bool _listEquals<T>(List<T>? left, List<T>? right) {
  if (identical(left, right)) return true;
  if (left == null || right == null || left.length != right.length) {
    return false;
  }
  for (var index = 0; index < left.length; index++) {
    if (left[index] != right[index]) return false;
  }
  return true;
}
