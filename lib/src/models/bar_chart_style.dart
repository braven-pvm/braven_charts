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

  /// Center a normalized composition around the baseline.
  ///
  /// Series opt into the negative, neutral, or positive side with
  /// [BarChartSeries.divergingRole]. Negative responses stack left/below the
  /// baseline, positive responses stack right/above it, and one neutral
  /// response straddles the baseline. Source values remain positive
  /// magnitudes and are normalized across the complete category total.
  divergingStacked,

  /// Accumulate each point as a sequential increase or decrease.
  ///
  /// Points listed in [BarChartSeries.waterfallTotalIndices] render the
  /// running total from the series baseline instead of applying their `y`
  /// value as another delta.
  waterfall,
}

/// Semantic placement of a series in a diverging stacked composition.
enum BarDivergingRole {
  /// Stack away from the baseline on the negative side.
  negative,

  /// Center the segment across the baseline.
  neutral,

  /// Stack away from the baseline on the positive side.
  positive,
}

/// Center-line treatment for a diverging stacked bar composition.
class BarDivergingStyle {
  const BarDivergingStyle({
    this.showCenterLine = true,
    this.centerLineColor = const Color(0xFF64748B),
    this.centerLineWidth = 1.25,
    this.centerLineOpacity = 0.7,
  }) : assert(centerLineWidth >= 0, 'Center-line width must be non-negative'),
       assert(
         centerLineOpacity >= 0 && centerLineOpacity <= 1,
         'Center-line opacity must be between 0 and 1',
       );

  final bool showCenterLine;
  final Color centerLineColor;
  final double centerLineWidth;
  final double centerLineOpacity;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BarDivergingStyle &&
          other.showCenterLine == showCenterLine &&
          other.centerLineColor == centerLineColor &&
          other.centerLineWidth == centerLineWidth &&
          other.centerLineOpacity == centerLineOpacity;

  @override
  int get hashCode => Object.hash(
    showCenterLine,
    centerLineColor,
    centerLineWidth,
    centerLineOpacity,
  );
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

/// Controls how a bar series enters and responds to data updates.
enum BarAnimationMode {
  /// Render the latest geometry immediately.
  none,

  /// Grow new bars from their baseline and interpolate existing values.
  grow,
}

/// Controls the order in which bars enter or update within one series.
enum BarAnimationOrder {
  /// Animate every bar on the same timeline.
  together,

  /// Animate from the first category to the last.
  forward,

  /// Animate from the last category to the first.
  reverse,

  /// Animate the center category or pair first, then move toward the edges.
  centerOut,

  /// Animate the outer categories first, then move toward the center.
  edgesIn,
}

/// Serializable choreography for bar entrance and data-update motion.
class BarMotionStyle {
  const BarMotionStyle({
    this.order = BarAnimationOrder.together,
    this.staggerFraction = 0.0,
  }) : assert(
         staggerFraction >= 0 && staggerFraction < 1,
         'Stagger fraction must be at least 0 and less than 1',
       );

  /// Category sequencing order.
  final BarAnimationOrder order;

  /// Fraction of the shared animation timeline reserved for start delays.
  ///
  /// A value of `0` animates bars together. A value of `0.4` distributes bar
  /// starts across the first 40% of the timeline while preserving one shared
  /// completion point.
  final double staggerFraction;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BarMotionStyle &&
          other.order == order &&
          other.staggerFraction == staggerFraction;

  @override
  int get hashCode => Object.hash(order, staggerFraction);
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

/// Non-color fill encodings that can distinguish bar series in monochrome.
enum BarFillPattern {
  /// Lines rise from left to right (`/`).
  diagonalUp,

  /// Lines fall from left to right (`\\`).
  diagonalDown,

  /// Both diagonal directions are drawn.
  crosshatch,

  /// Horizontal lines repeat along the value axis.
  horizontal,

  /// Vertical lines repeat along the category axis.
  vertical,
}

/// A clipped line pattern drawn over a bar's fill.
///
/// Patterns provide a second visual channel alongside color. When [color] is
/// null, the renderer chooses black or white from the resolved bar luminance.
class BarPatternStyle {
  const BarPatternStyle({
    required this.pattern,
    this.color,
    this.spacing = 8.0,
    this.strokeWidth = 1.5,
    this.opacity = 0.55,
  }) : assert(spacing > 0, 'Pattern spacing must be greater than zero'),
       assert(
         strokeWidth > 0,
         'Pattern stroke width must be greater than zero',
       ),
       assert(opacity >= 0 && opacity <= 1, 'Opacity must be between 0 and 1');

  final BarFillPattern pattern;
  final Color? color;
  final double spacing;
  final double strokeWidth;
  final double opacity;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BarPatternStyle &&
          other.pattern == pattern &&
          other.color == color &&
          other.spacing == spacing &&
          other.strokeWidth == strokeWidth &&
          other.opacity == opacity;

  @override
  int get hashCode =>
      Object.hash(pattern, color, spacing, strokeWidth, opacity);
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

/// Visual feedback applied to individual bars during interaction.
///
/// State feedback deliberately combines opacity, fill, and outlines so hover,
/// press, focus, and selection remain distinguishable without relying on color
/// alone. Null colors inherit from the bar or chart interaction theme.
class BarInteractionStyle {
  const BarInteractionStyle({
    this.hoverColor,
    this.hoverOpacity = 0.12,
    this.hoverBorderWidth = 2.0,
    this.pressedColor = const Color(0xFF000000),
    this.pressedOpacity = 0.16,
    this.selectionColor,
    this.selectionOpacity = 0.14,
    this.selectionBorderWidth = 2.5,
    this.focusColor,
    this.focusBorderWidth = 2.5,
    this.focusGap = 3.0,
    this.dimmedOpacity = 0.42,
  }) : assert(hoverOpacity >= 0 && hoverOpacity <= 1),
       assert(hoverBorderWidth >= 0),
       assert(pressedOpacity >= 0 && pressedOpacity <= 1),
       assert(selectionOpacity >= 0 && selectionOpacity <= 1),
       assert(selectionBorderWidth >= 0),
       assert(focusBorderWidth >= 0),
       assert(focusGap >= 0),
       assert(dimmedOpacity >= 0 && dimmedOpacity <= 1);

  /// Hover overlay color. Null derives a contrasting tint from the bar color.
  final Color? hoverColor;
  final double hoverOpacity;
  final double hoverBorderWidth;

  /// Press overlay color and opacity.
  final Color pressedColor;
  final double pressedOpacity;

  /// Durable selection overlay. Null uses the chart interaction theme.
  final Color? selectionColor;
  final double selectionOpacity;
  final double selectionBorderWidth;

  /// Keyboard or linked-focus outline. Null uses the chart focus color.
  final Color? focusColor;
  final double focusBorderWidth;
  final double focusGap;

  /// Opacity multiplier for unselected bars while any bar point is selected.
  final double dimmedOpacity;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BarInteractionStyle &&
          other.hoverColor == hoverColor &&
          other.hoverOpacity == hoverOpacity &&
          other.hoverBorderWidth == hoverBorderWidth &&
          other.pressedColor == pressedColor &&
          other.pressedOpacity == pressedOpacity &&
          other.selectionColor == selectionColor &&
          other.selectionOpacity == selectionOpacity &&
          other.selectionBorderWidth == selectionBorderWidth &&
          other.focusColor == focusColor &&
          other.focusBorderWidth == focusBorderWidth &&
          other.focusGap == focusGap &&
          other.dimmedOpacity == dimmedOpacity;

  @override
  int get hashCode => Object.hash(
    hoverColor,
    hoverOpacity,
    hoverBorderWidth,
    pressedColor,
    pressedOpacity,
    selectionColor,
    selectionOpacity,
    selectionBorderWidth,
    focusColor,
    focusBorderWidth,
    focusGap,
    dimmedOpacity,
  );
}

/// Visual styling shared by all bars in a series.
class BarChartStyle {
  const BarChartStyle({
    this.cornerRadius = 0.0,
    this.cornerRadiusPolicy = BarCornerRadiusPolicy.valueEnd,
    this.gradient,
    this.pattern,
    this.border,
    this.opacity = 1.0,
    this.interaction = const BarInteractionStyle(),
    this.animationMode = BarAnimationMode.grow,
    this.motion = const BarMotionStyle(),
  }) : assert(cornerRadius >= 0, 'Corner radius must be non-negative'),
       assert(opacity >= 0 && opacity <= 1, 'Opacity must be between 0 and 1');

  final double cornerRadius;
  final BarCornerRadiusPolicy cornerRadiusPolicy;
  final BarGradient? gradient;
  final BarPatternStyle? pattern;
  final BarBorderStyle? border;
  final double opacity;
  final BarInteractionStyle interaction;

  /// Entrance and data-update behavior for this series.
  ///
  /// Duration and easing resolve from the chart theme's animation settings.
  /// Reduced motion preferences always render the final geometry immediately.
  final BarAnimationMode animationMode;

  /// Optional sequencing applied within this series.
  final BarMotionStyle motion;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BarChartStyle &&
          other.cornerRadius == cornerRadius &&
          other.cornerRadiusPolicy == cornerRadiusPolicy &&
          other.gradient == gradient &&
          other.pattern == pattern &&
          other.border == border &&
          other.opacity == opacity &&
          other.interaction == interaction &&
          other.animationMode == animationMode &&
          other.motion == motion;

  @override
  int get hashCode => Object.hash(
    cornerRadius,
    cornerRadiusPolicy,
    gradient,
    pattern,
    border,
    opacity,
    interaction,
    animationMode,
    motion,
  );
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
  ///
  /// In a diverging composition this is the capacity endpoint on one side of
  /// the shared baseline; the track mirrors that distance on the other side.
  /// A null diverging value spans both visible value-axis boundaries.
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

/// A light-weight stem-and-head treatment for categorical bar values.
///
/// Supplying this style replaces the filled bar body while preserving the
/// same canonical value geometry, labels, animation, tooltips, and
/// interactions. The stem follows the value axis and the circular head marks
/// the exact value end.
class BarLollipopStyle {
  const BarLollipopStyle({
    this.stemWidth = 3.0,
    this.headRadius = 7.0,
    this.stemColor,
    this.headColor,
    this.headBorder,
  }) : assert(stemWidth > 0, 'Lollipop stem width must be positive'),
       assert(headRadius > 0, 'Lollipop head radius must be positive');

  /// Logical-pixel width of the line from the baseline to the value.
  final double stemWidth;

  /// Logical-pixel radius of the circular value marker.
  final double headRadius;

  /// Optional stem color. Null inherits the resolved point or series color.
  final Color? stemColor;

  /// Optional head color. Null inherits the resolved point or series color.
  final Color? headColor;

  /// Optional outline around the value marker.
  final BarBorderStyle? headBorder;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BarLollipopStyle &&
          other.stemWidth == stemWidth &&
          other.headRadius == headRadius &&
          other.stemColor == stemColor &&
          other.headColor == headColor &&
          other.headBorder == headBorder;

  @override
  int get hashCode =>
      Object.hash(stemWidth, headRadius, stemColor, headColor, headBorder);
}

/// One qualitative performance range behind a bullet-chart measure.
class BarBulletRange {
  const BarBulletRange({
    required this.endValue,
    required this.color,
    this.label,
  });

  /// Value-axis end of this range, measured from the series baseline.
  final double endValue;

  /// Passive background color for this range.
  final Color color;

  /// Optional portable description such as `On track` or `Stretch`.
  final String? label;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BarBulletRange &&
          other.endValue == endValue &&
          other.color == color &&
          other.label == label;

  @override
  int get hashCode => Object.hash(endValue, color, label);
}

/// Qualitative ranges that turn a standard bar into a bullet chart.
///
/// Ranges are shared by every point in the series and paint behind the actual
/// measure. The series target values remain the comparative
/// marker, so the bullet chart does not create synthetic data series.
class BarBulletStyle {
  const BarBulletStyle({
    required this.ranges,
    this.measureThicknessFactor = 0.45,
    this.cornerRadius = 3.0,
  }) : assert(
         measureThicknessFactor > 0 && measureThicknessFactor <= 1,
         'Measure thickness factor must be greater than 0 and at most 1',
       ),
       assert(cornerRadius >= 0, 'Bullet range radius must be non-negative');

  /// Ordered range endpoints. Values must increase away from the baseline.
  final List<BarBulletRange> ranges;

  /// Actual-measure thickness relative to the qualitative range thickness.
  final double measureThicknessFactor;

  /// Corner radius applied to the complete qualitative range background.
  final double cornerRadius;

  /// Returns the first qualitative range containing [value].
  ///
  /// Values beyond the outermost configured endpoint intentionally return
  /// null: callers can then describe the measure as exceeding the scale.
  BarBulletRange? rangeForValue(double value) {
    for (final range in ranges) {
      if (value <= range.endValue) return range;
    }
    return null;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BarBulletStyle &&
          _listEquals(other.ranges, ranges) &&
          other.measureThicknessFactor == measureThicknessFactor &&
          other.cornerRadius == cornerRadius;

  @override
  int get hashCode =>
      Object.hash(Object.hashAll(ranges), measureThicknessFactor, cornerRadius);
}

/// A benchmark marker drawn across a bar at a target value.
///
/// The marker is intentionally a passive reference: the bar remains the
/// interactive data mark, while tooltips and semantics expose the target.
class BarTargetMarkerStyle {
  const BarTargetMarkerStyle({
    this.color,
    this.width = 2.0,
    this.lengthFactor = 1.3,
    this.opacity = 1.0,
  }) : assert(width >= 0, 'Marker width must be non-negative'),
       assert(lengthFactor > 0, 'Marker length factor must be positive'),
       assert(opacity >= 0 && opacity <= 1, 'Opacity must be between 0 and 1');

  /// Marker color. Null selects a contrasting color from the rendered bar.
  final Color? color;

  /// Logical-pixel stroke width.
  final double width;

  /// Marker length relative to the rendered bar thickness.
  final double lengthFactor;

  final double opacity;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BarTargetMarkerStyle &&
          other.color == color &&
          other.width == width &&
          other.lengthFactor == lengthFactor &&
          other.opacity == opacity;

  @override
  int get hashCode => Object.hash(color, width, lengthFactor, opacity);
}

/// Presentation for a per-point uncertainty or error interval.
///
/// The interval is a passive analytical reference. Its stem follows the value
/// axis and its caps cross the rendered bar at the lower and upper endpoints.
class BarErrorBarStyle {
  const BarErrorBarStyle({
    this.color,
    this.width = 1.5,
    this.capLengthFactor = 0.6,
    this.opacity = 1.0,
  }) : assert(width >= 0, 'Error-bar width must be non-negative'),
       assert(capLengthFactor > 0, 'Cap length factor must be positive'),
       assert(opacity >= 0 && opacity <= 1, 'Opacity must be between 0 and 1');

  /// Line color. Null uses a dark core with a light contrast halo.
  final Color? color;

  /// Logical-pixel width of the stem and endpoint caps.
  final double width;

  /// Total cap length relative to the rendered bar thickness.
  final double capLengthFactor;

  final double opacity;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BarErrorBarStyle &&
          other.color == color &&
          other.width == width &&
          other.capLengthFactor == capLengthFactor &&
          other.opacity == opacity;

  @override
  int get hashCode => Object.hash(color, width, capLengthFactor, opacity);
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

/// Controls how bar labels behave when their painted bounds overlap.
enum BarLabelCollisionPolicy {
  /// Preserve the requested position even when labels overlap.
  none,

  /// Try inside/outside alternatives and progressively displaced callouts.
  reposition,

  /// Hide a label when its requested position is already occupied.
  hide,
}

/// Optional connector drawn between a displaced label and its bar value end.
class BarLabelCalloutStyle {
  const BarLabelCalloutStyle({
    this.show = false,
    this.color,
    this.width = 1.0,
    this.minimumLength = 4.0,
  }) : assert(width >= 0, 'Callout width must be non-negative'),
       assert(
         minimumLength >= 0,
         'Minimum callout length must be non-negative',
       );

  final bool show;
  final Color? color;
  final double width;
  final double minimumLength;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BarLabelCalloutStyle &&
          other.show == show &&
          other.color == color &&
          other.width == width &&
          other.minimumLength == minimumLength;

  @override
  int get hashCode => Object.hash(show, color, width, minimumLength);
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
    this.collisionPolicy = BarLabelCollisionPolicy.none,
    this.plotEdgeAware = true,
    this.collisionPadding = 2.0,
    this.backgroundColor,
    this.borderColor,
    this.borderWidth = 0.0,
    this.borderRadius = 4.0,
    this.backgroundPadding = 3.0,
    this.callout = const BarLabelCalloutStyle(),
    this.showStackTotal = false,
    this.formatter,
  }) : assert(fontSize > 0, 'Font size must be positive'),
       assert(padding >= 0, 'Padding must be non-negative'),
       assert(collisionPadding >= 0, 'Collision padding must be non-negative'),
       assert(borderWidth >= 0, 'Border width must be non-negative'),
       assert(borderRadius >= 0, 'Border radius must be non-negative'),
       assert(
         backgroundPadding >= 0,
         'Background padding must be non-negative',
       );

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

  /// Global label collision behavior shared across every bar series.
  final BarLabelCollisionPolicy collisionPolicy;

  /// Whether labels should remain fully inside the plot viewport.
  final bool plotEdgeAware;

  /// Minimum gap reserved around every accepted label box.
  final double collisionPadding;

  /// Optional compact backing surface for labels over dense chart content.
  final Color? backgroundColor;
  final Color? borderColor;
  final double borderWidth;
  final double borderRadius;
  final double backgroundPadding;

  /// Connector used when a label is moved away from its value end.
  final BarLabelCalloutStyle callout;

  /// Paint the resolved positive or negative total outside an exposed stack.
  final bool showStackTotal;

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
          other.collisionPolicy == collisionPolicy &&
          other.plotEdgeAware == plotEdgeAware &&
          other.collisionPadding == collisionPadding &&
          other.backgroundColor == backgroundColor &&
          other.borderColor == borderColor &&
          other.borderWidth == borderWidth &&
          other.borderRadius == borderRadius &&
          other.backgroundPadding == backgroundPadding &&
          other.callout == callout &&
          other.showStackTotal == showStackTotal &&
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
    collisionPolicy,
    plotEdgeAware,
    collisionPadding,
    backgroundColor,
    borderColor,
    borderWidth,
    borderRadius,
    backgroundPadding,
    callout,
    showStackTotal,
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
