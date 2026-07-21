// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

import 'dart:math' as math;
import 'dart:ui';

import '../theming/components/series_theme.dart' show SeriesMarkerShape;

import '../meta/chart_surface.dart';

/// One categorical Scatter mapping entry.
///
/// Color and shape are independent: a shape-only category mapping can coexist
/// with a quantitative color encoding, while a color-bearing entry takes
/// precedence over that quantitative color for matching points.
class ScatterCategoryStyle {
  const ScatterCategoryStyle({
    required this.key,
    this.label,
    this.color,
    this.shape,
  }) : assert(key != ''),
       assert(shape != SeriesMarkerShape.none);

  /// Stable value matched against [ChartDataPoint.categoryValue].
  final String key;

  /// Optional user-facing label. [key] is used when omitted.
  final String? label;

  /// Optional marker fill for this category.
  final Color? color;

  /// Optional marker silhouette for this category.
  final SeriesMarkerShape? shape;

  String get displayLabel => label == null || label!.isEmpty ? key : label!;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScatterCategoryStyle &&
          other.key == key &&
          other.label == label &&
          other.color == color &&
          other.shape == shape;

  @override
  int get hashCode => Object.hash(key, label, color, shape);
}

/// Maps a Scatter point's categorical value to color, shape, or both.
///
/// Explicit point styling always wins. Unmatched and null categories inherit
/// the quantitative, series, or theme styling beneath this encoding.
class ScatterCategoryEncoding {
  const ScatterCategoryEncoding({
    required this.categories,
    this.label = 'Category',
    this.showLegend = true,
  });

  /// Ordered category entries. Order is retained by native legends.
  final List<ScatterCategoryStyle> categories;

  /// Human-readable field name used by tracking, tables, and legends.
  final String label;

  /// Whether chart integrations should expose a categorical legend key.
  final bool showLegend;

  /// Whether every key is non-empty and unique and each entry changes at
  /// least one visible channel.
  bool get hasValidConfiguration {
    final keys = <String>{};
    for (final category in categories) {
      if (category.key.isEmpty ||
          !keys.add(category.key) ||
          (category.color == null && category.shape == null) ||
          category.shape == SeriesMarkerShape.none) {
        return false;
      }
    }
    return categories.isNotEmpty;
  }

  ScatterCategoryStyle? styleFor(String? key) {
    if (key == null || key.isEmpty) return null;
    for (final category in categories) {
      if (category.key == key) return category;
    }
    return null;
  }

  String? labelFor(String? key) => styleFor(key)?.displayLabel;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScatterCategoryEncoding &&
          _categoryListsEqual(other.categories, categories) &&
          other.label == label &&
          other.showLegend == showLegend;

  @override
  int get hashCode =>
      Object.hash(Object.hashAll(categories), label, showLegend);
}

bool _categoryListsEqual(
  List<ScatterCategoryStyle> left,
  List<ScatterCategoryStyle> right,
) {
  if (identical(left, right)) return true;
  if (left.length != right.length) return false;
  for (var index = 0; index < left.length; index++) {
    if (left[index] != right[index]) return false;
  }
  return true;
}

/// Deterministically separates overlapping Scatter markers in plot space.
///
/// [xAmplitude] and [yAmplitude] are maximum logical-pixel displacements from
/// the raw data position. Jitter never mutates source values or axis bounds,
/// so tables, exports, tooltips, and tracking continue to report exact data.
/// The same series id, point index, and [seed] always resolve to the same
/// offset across repaint, pan, zoom, artifact hydration, and generated source.
class ScatterJitterConfig {
  const ScatterJitterConfig({
    this.xAmplitude = 0,
    this.yAmplitude = 0,
    this.seed = 0,
  }) : assert(xAmplitude >= 0 && xAmplitude < double.infinity),
       assert(yAmplitude >= 0 && yAmplitude < double.infinity);

  /// Maximum horizontal displacement in logical pixels.
  final double xAmplitude;

  /// Maximum vertical displacement in logical pixels.
  final double yAmplitude;

  /// Stable layout seed. Changing it produces a different deterministic
  /// arrangement without changing point identities or raw values.
  final int seed;

  bool get isEnabled => xAmplitude > 0 || yAmplitude > 0;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScatterJitterConfig &&
          other.xAmplitude == xAmplitude &&
          other.yAmplitude == yAmplitude &&
          other.seed == seed;

  @override
  int get hashCode => Object.hash(xAmplitude, yAmplitude, seed);

  @override
  String toString() =>
      'ScatterJitterConfig(xAmplitude: $xAmplitude, yAmplitude: $yAmplitude, seed: $seed)';
}

/// Quantitative color mapping strategy for Scatter markers.
enum ScatterColorScaleType {
  /// Interpolate smoothly across the configured colors.
  continuous,

  /// Assign one discrete color band on either side of explicit thresholds.
  piecewise,
}

/// Maps a Scatter point's independent quantitative color value onto a color
/// scale.
///
/// The color domain can be fixed or derived from the finite values in the
/// series. Values outside the resolved domain clamp to the nearest endpoint.
/// A degenerate domain resolves to the midpoint of the ramp. Null and
/// non-finite values deliberately return null so the marker inherits its
/// normal point, series, or theme color rather than disappearing.
class ScatterColorEncoding {
  const ScatterColorEncoding({
    required this.colors,
    this.scaleType = ScatterColorScaleType.continuous,
    this.thresholds = const [],
    this.bandLabels = const [],
    this.minimumValue,
    this.maximumValue,
    this.label = 'Color value',
    this.unit,
    this.showLegend = true,
  }) : assert(
         minimumValue == null ||
             (minimumValue > double.negativeInfinity &&
                 minimumValue < double.infinity),
       ),
       assert(
         maximumValue == null ||
             (maximumValue > double.negativeInfinity &&
                 maximumValue < double.infinity),
       ),
       assert(
         minimumValue == null ||
             maximumValue == null ||
             maximumValue >= minimumValue,
       );

  /// Ordered ramp colors from the low-domain edge to the high-domain edge.
  final List<Color> colors;

  /// Whether the scale interpolates or resolves discrete threshold bands.
  final ScatterColorScaleType scaleType;

  /// Ordered thresholds separating piecewise color bands.
  ///
  /// A piecewise scale with N colors uses N-1 thresholds. Values equal to a
  /// threshold enter the higher band, matching common alert and risk rules.
  final List<double> thresholds;

  /// Optional human-readable label for each piecewise color band.
  final List<String> bandLabels;

  /// Optional fixed lower data-domain edge.
  final double? minimumValue;

  /// Optional fixed upper data-domain edge.
  final double? maximumValue;

  /// Human-readable metric name used by tooltips, tables, and legends.
  final String label;

  /// Optional unit appended to formatted color values.
  final String? unit;

  /// Whether chart integrations should expose a quantitative color legend.
  final bool showLegend;

  /// Whether the piecewise configuration is complete and strictly ordered.
  bool get hasValidPiecewiseConfiguration {
    if (scaleType != ScatterColorScaleType.piecewise) return true;
    if (colors.isEmpty || thresholds.length != colors.length - 1) return false;
    for (var index = 0; index < thresholds.length; index++) {
      final threshold = thresholds[index];
      if (!threshold.isFinite ||
          (index > 0 && threshold <= thresholds[index - 1])) {
        return false;
      }
    }
    return bandLabels.isEmpty || bandLabels.length == colors.length;
  }

  /// Resolves one color using continuous interpolation or threshold bands.
  Color? colorFor(
    double? value, {
    required double resolvedMinimumValue,
    required double resolvedMaximumValue,
  }) {
    if (value == null || !value.isFinite) return null;
    if (colors.isEmpty) return null;
    if (scaleType == ScatterColorScaleType.piecewise) {
      if (!hasValidPiecewiseConfiguration) return null;
      return colors[_piecewiseBandIndex(value)];
    }
    if (colors.length == 1) return colors.first;
    final minimum = minimumValue ?? resolvedMinimumValue;
    final maximum = maximumValue ?? resolvedMaximumValue;
    final normalized = maximum <= minimum
        ? 0.5
        : ((value - minimum) / (maximum - minimum)).clamp(0.0, 1.0);
    final scaled = normalized * (colors.length - 1);
    final lowerIndex = scaled.floor().clamp(0, colors.length - 1);
    final upperIndex = scaled.ceil().clamp(0, colors.length - 1);
    if (lowerIndex == upperIndex) return colors[lowerIndex];
    return Color.lerp(
      colors[lowerIndex],
      colors[upperIndex],
      scaled - lowerIndex,
    );
  }

  String format(double value) {
    final fixed = value.toStringAsFixed(2);
    final text = fixed.endsWith('.00')
        ? fixed.substring(0, fixed.length - 3)
        : fixed.endsWith('0')
        ? fixed.substring(0, fixed.length - 1)
        : fixed;
    return unit == null || unit!.isEmpty ? text : '$text $unit';
  }

  /// Formats a value for tracking surfaces, including its discrete band.
  String formatForInteraction(double value) {
    final formatted = format(value);
    final band = bandLabelFor(value);
    return band == null ? formatted : '$formatted · $band';
  }

  /// Returns the configured or generated label for the resolved color band.
  String? bandLabelFor(double? value) {
    if (scaleType != ScatterColorScaleType.piecewise ||
        value == null ||
        !value.isFinite ||
        !hasValidPiecewiseConfiguration) {
      return null;
    }
    final labels = effectiveBandLabels;
    return labels[_piecewiseBandIndex(value)];
  }

  int _piecewiseBandIndex(double value) {
    var lower = 0;
    var upper = thresholds.length;
    while (lower < upper) {
      final midpoint = lower + ((upper - lower) >> 1);
      if (value < thresholds[midpoint]) {
        upper = midpoint;
      } else {
        lower = midpoint + 1;
      }
    }
    return lower;
  }

  /// Display labels used by native segmented legends.
  List<String> get effectiveBandLabels {
    if (bandLabels.length == colors.length) return bandLabels;
    if (!hasValidPiecewiseConfiguration) return const [];
    if (thresholds.isEmpty) return const ['All values'];
    return [
      'Below ${format(thresholds.first)}',
      for (var index = 1; index < thresholds.length; index++)
        '${format(thresholds[index - 1])}–${format(thresholds[index])}',
      '${format(thresholds.last)}+',
    ];
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScatterColorEncoding &&
          _colorListsEqual(other.colors, colors) &&
          other.scaleType == scaleType &&
          _doubleListsEqual(other.thresholds, thresholds) &&
          _stringListsEqual(other.bandLabels, bandLabels) &&
          other.minimumValue == minimumValue &&
          other.maximumValue == maximumValue &&
          other.label == label &&
          other.unit == unit &&
          other.showLegend == showLegend;

  @override
  int get hashCode => Object.hash(
    Object.hashAll(colors),
    scaleType,
    Object.hashAll(thresholds),
    Object.hashAll(bandLabels),
    minimumValue,
    maximumValue,
    label,
    unit,
    showLegend,
  );
}

/// Maps a Scatter point's independent quantitative opacity value onto a
/// bounded opacity range.
///
/// The data domain can be fixed or derived from finite point values. Values
/// outside the resolved domain clamp to the nearest endpoint. A degenerate
/// domain resolves to the midpoint of the opacity range. Null and non-finite
/// values deliberately return null so the marker inherits its explicit point,
/// series, or theme opacity rather than disappearing.
class ScatterOpacityEncoding {
  const ScatterOpacityEncoding({
    this.minimumOpacity = 0.2,
    this.maximumOpacity = 1,
    this.minimumValue,
    this.maximumValue,
    this.label = 'Opacity value',
    this.unit,
    this.showLegend = true,
  }) : assert(
         minimumOpacity >= 0 &&
             minimumOpacity <= 1 &&
             minimumOpacity <= maximumOpacity,
       ),
       assert(maximumOpacity >= 0 && maximumOpacity <= 1),
       assert(
         minimumValue == null ||
             (minimumValue > double.negativeInfinity &&
                 minimumValue < double.infinity),
       ),
       assert(
         maximumValue == null ||
             (maximumValue > double.negativeInfinity &&
                 maximumValue < double.infinity),
       ),
       assert(
         minimumValue == null ||
             maximumValue == null ||
             maximumValue >= minimumValue,
       );

  /// Opacity at the low-domain edge.
  final double minimumOpacity;

  /// Opacity at the high-domain edge.
  final double maximumOpacity;

  /// Optional fixed lower data-domain edge.
  final double? minimumValue;

  /// Optional fixed upper data-domain edge.
  final double? maximumValue;

  /// Human-readable metric name used by tooltips, tables, and legends.
  final String label;

  /// Optional unit appended to formatted opacity values.
  final String? unit;

  /// Whether chart integrations should expose a quantitative opacity key.
  final bool showLegend;

  /// Resolves one marker opacity in the configured visual range.
  double? opacityFor(
    double? value, {
    required double resolvedMinimumValue,
    required double resolvedMaximumValue,
  }) {
    if (value == null || !value.isFinite) return null;
    final minimum = minimumValue ?? resolvedMinimumValue;
    final maximum = maximumValue ?? resolvedMaximumValue;
    final normalized = maximum <= minimum
        ? 0.5
        : ((value - minimum) / (maximum - minimum)).clamp(0.0, 1.0);
    return minimumOpacity + normalized * (maximumOpacity - minimumOpacity);
  }

  String format(double value) {
    final fixed = value.toStringAsFixed(2);
    final text = fixed.endsWith('.00')
        ? fixed.substring(0, fixed.length - 3)
        : fixed.endsWith('0')
        ? fixed.substring(0, fixed.length - 1)
        : fixed;
    return unit == null || unit!.isEmpty ? text : '$text $unit';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScatterOpacityEncoding &&
          other.minimumOpacity == minimumOpacity &&
          other.maximumOpacity == maximumOpacity &&
          other.minimumValue == minimumValue &&
          other.maximumValue == maximumValue &&
          other.label == label &&
          other.unit == unit &&
          other.showLegend == showLegend;

  @override
  int get hashCode => Object.hash(
    minimumOpacity,
    maximumOpacity,
    minimumValue,
    maximumValue,
    label,
    unit,
    showLegend,
  );
}

bool _doubleListsEqual(List<double> left, List<double> right) {
  if (identical(left, right)) return true;
  if (left.length != right.length) return false;
  for (var index = 0; index < left.length; index++) {
    if (left[index] != right[index]) return false;
  }
  return true;
}

bool _stringListsEqual(List<String> left, List<String> right) {
  if (identical(left, right)) return true;
  if (left.length != right.length) return false;
  for (var index = 0; index < left.length; index++) {
    if (left[index] != right[index]) return false;
  }
  return true;
}

bool _colorListsEqual(List<Color> left, List<Color> right) {
  if (identical(left, right)) return true;
  if (left.length != right.length) return false;
  for (var index = 0; index < left.length; index++) {
    if (left[index] != right[index]) return false;
  }
  return true;
}

/// Area-correct mapping from a Scatter point's quantitative magnitude to its
/// marker radius.
///
/// Null, non-finite, and negative magnitudes are omitted while this encoding
/// is active. Zero remains inspectable at [minimumRadius]. Values outside the
/// domain clamp to its nearest edge. When every value resolves to one domain
/// value, all markers use the midpoint of the available marker area.
class ScatterSizeEncoding {
  const ScatterSizeEncoding({
    this.minimumRadius = 4,
    this.maximumRadius = 24,
    this.minimumValue = 0,
    this.maximumValue,
    this.label = 'Magnitude',
    this.unit,
    this.showLegend = true,
  }) : assert(minimumRadius >= 0 && minimumRadius < double.infinity),
       assert(
         maximumRadius >= minimumRadius && maximumRadius < double.infinity,
       ),
       assert(minimumValue >= 0 && minimumValue < double.infinity),
       assert(
         maximumValue == null ||
             (maximumValue >= minimumValue && maximumValue < double.infinity),
       );

  /// Smallest rendered marker radius in logical pixels.
  final double minimumRadius;

  /// Largest rendered marker radius in logical pixels.
  final double maximumRadius;

  /// Lower data-domain edge. Values below it clamp to this edge.
  final double minimumValue;

  /// Optional fixed upper data-domain edge.
  ///
  /// When null, the largest finite non-negative magnitude in the series is
  /// used.
  final double? maximumValue;

  /// Human-readable metric name used by tooltips, tables, and legends.
  final String label;

  /// Optional unit appended to formatted magnitudes.
  final String? unit;

  /// Whether chart integrations should expose a size legend.
  final bool showLegend;

  /// Resolves one radius using linear marker-area interpolation.
  double radiusFor(double value, {required double resolvedMaximumValue}) {
    final maximum = maximumValue ?? resolvedMaximumValue;
    final normalized = maximum <= minimumValue
        ? 0.5
        : ((value - minimumValue) / (maximum - minimumValue)).clamp(0.0, 1.0);
    final minimumArea = minimumRadius * minimumRadius;
    final maximumArea = maximumRadius * maximumRadius;
    return math.sqrt(minimumArea + normalized * (maximumArea - minimumArea));
  }

  String format(double value) {
    final fixed = value.toStringAsFixed(2);
    final text = fixed.endsWith('.00')
        ? fixed.substring(0, fixed.length - 3)
        : fixed.endsWith('0')
        ? fixed.substring(0, fixed.length - 1)
        : fixed;
    return unit == null || unit!.isEmpty ? text : '$text $unit';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScatterSizeEncoding &&
          other.minimumRadius == minimumRadius &&
          other.maximumRadius == maximumRadius &&
          other.minimumValue == minimumValue &&
          other.maximumValue == maximumValue &&
          other.label == label &&
          other.unit == unit &&
          other.showLegend == showLegend;

  @override
  int get hashCode => Object.hash(
    minimumRadius,
    maximumRadius,
    minimumValue,
    maximumValue,
    label,
    unit,
    showLegend,
  );
}

/// Optional visual overrides for Scatter markers.
///
/// Null properties inherit from the point, series, or theme layer beneath
/// them. Width and height are expressed in logical pixels. Rotation is
/// clockwise in degrees.
// `copyWith` spells the rotation unset flag `clearRotation`, not
// `clearRotationDegrees`, so the derived convention needs an override.
@ChartSurface(clearFlags: {'rotationDegrees': 'clearRotation'})
class ScatterMarkerStyle {
  const ScatterMarkerStyle({
    this.fillColor,
    this.strokeColor,
    this.strokeWidth,
    this.opacity,
    this.width,
    this.height,
    this.rotationDegrees,
  }) : assert(
         strokeWidth == null ||
             (strokeWidth >= 0 && strokeWidth < double.infinity),
       ),
       assert(opacity == null || (opacity >= 0 && opacity <= 1)),
       assert(width == null || (width >= 0 && width < double.infinity)),
       assert(height == null || (height >= 0 && height < double.infinity)),
       assert(
         rotationDegrees == null ||
             (rotationDegrees > double.negativeInfinity &&
                 rotationDegrees < double.infinity),
       );

  /// Marker fill. Null inherits the point or series color.
  final Color? fillColor;

  /// Optional marker outline color.
  final Color? strokeColor;

  /// Outline width in logical pixels. Zero disables the outline.
  final double? strokeWidth;

  /// Marker opacity from 0 (transparent) to 1 (opaque).
  final double? opacity;

  /// Marker width in logical pixels.
  final double? width;

  /// Marker height in logical pixels.
  final double? height;

  /// Clockwise rotation in degrees.
  final double? rotationDegrees;

  bool get hasOverrides =>
      fillColor != null ||
      strokeColor != null ||
      strokeWidth != null ||
      opacity != null ||
      width != null ||
      height != null ||
      rotationDegrees != null;

  ScatterMarkerStyle copyWith({
    Color? fillColor,
    Color? strokeColor,
    double? strokeWidth,
    double? opacity,
    double? width,
    double? height,
    double? rotationDegrees,
    bool clearFillColor = false,
    bool clearStrokeColor = false,
    bool clearStrokeWidth = false,
    bool clearOpacity = false,
    bool clearWidth = false,
    bool clearHeight = false,
    bool clearRotation = false,
  }) => ScatterMarkerStyle(
    fillColor: clearFillColor ? null : (fillColor ?? this.fillColor),
    strokeColor: clearStrokeColor ? null : (strokeColor ?? this.strokeColor),
    strokeWidth: clearStrokeWidth ? null : (strokeWidth ?? this.strokeWidth),
    opacity: clearOpacity ? null : (opacity ?? this.opacity),
    width: clearWidth ? null : (width ?? this.width),
    height: clearHeight ? null : (height ?? this.height),
    rotationDegrees: clearRotation
        ? null
        : (rotationDegrees ?? this.rotationDegrees),
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScatterMarkerStyle &&
          fillColor == other.fillColor &&
          strokeColor == other.strokeColor &&
          strokeWidth == other.strokeWidth &&
          opacity == other.opacity &&
          width == other.width &&
          height == other.height &&
          rotationDegrees == other.rotationDegrees;

  @override
  int get hashCode => Object.hash(
    fillColor,
    strokeColor,
    strokeWidth,
    opacity,
    width,
    height,
    rotationDegrees,
  );

  @override
  String toString() =>
      'ScatterMarkerStyle(fillColor: $fillColor, strokeColor: $strokeColor, '
      'strokeWidth: $strokeWidth, opacity: $opacity, width: $width, '
      'height: $height, rotationDegrees: $rotationDegrees)';
}

/// Visual feedback applied to individual Scatter points during interaction.
///
/// Every state combines a geometry change with an outline so meaning never
/// depends on color alone. Null colors inherit from the chart interaction
/// theme or the point's effective series color.
@chartSurface
class ScatterInteractionStyle {
  const ScatterInteractionStyle({
    this.hoverColor,
    this.hoverScale = 1.35,
    this.hoverStrokeWidth = 2.0,
    this.pressedColor = const Color(0xFF000000),
    this.pressedScale = 1.15,
    this.pressedOpacity = 0.12,
    this.selectionColor,
    this.selectionScale = 1.25,
    this.selectionOpacity = 0.14,
    this.selectionStrokeWidth = 2.5,
    this.focusColor,
    this.focusGap = 4.0,
    this.focusStrokeWidth = 2.5,
    this.dimmedOpacity = 0.32,
  }) : assert(hoverScale >= 1 && hoverScale < double.infinity),
       assert(hoverStrokeWidth >= 0 && hoverStrokeWidth < double.infinity),
       assert(pressedScale > 0 && pressedScale < double.infinity),
       assert(pressedOpacity >= 0 && pressedOpacity <= 1),
       assert(selectionScale >= 1 && selectionScale < double.infinity),
       assert(selectionOpacity >= 0 && selectionOpacity <= 1),
       assert(
         selectionStrokeWidth >= 0 && selectionStrokeWidth < double.infinity,
       ),
       assert(focusGap >= 0 && focusGap < double.infinity),
       assert(focusStrokeWidth >= 0 && focusStrokeWidth < double.infinity),
       assert(dimmedOpacity >= 0 && dimmedOpacity <= 1);

  /// Hover outline. Null uses the effective point color.
  final Color? hoverColor;
  final double hoverScale;
  final double hoverStrokeWidth;

  /// Press feedback layered over the hovered marker.
  final Color pressedColor;
  final double pressedScale;
  final double pressedOpacity;

  /// Durable selection ring and translucent backing.
  final Color? selectionColor;
  final double selectionScale;
  final double selectionOpacity;
  final double selectionStrokeWidth;

  /// Keyboard or linked-focus outline.
  final Color? focusColor;
  final double focusGap;
  final double focusStrokeWidth;

  /// Opacity multiplier for unselected points while any point is selected.
  final double dimmedOpacity;

  /// Creates a copy with selected interaction-state values replaced.
  ///
  /// The color clear flags restore inheritance from the chart interaction
  /// theme or the point's effective series color.
  ScatterInteractionStyle copyWith({
    Color? hoverColor,
    double? hoverScale,
    double? hoverStrokeWidth,
    Color? pressedColor,
    double? pressedScale,
    double? pressedOpacity,
    Color? selectionColor,
    double? selectionScale,
    double? selectionOpacity,
    double? selectionStrokeWidth,
    Color? focusColor,
    double? focusGap,
    double? focusStrokeWidth,
    double? dimmedOpacity,
    bool clearHoverColor = false,
    bool clearSelectionColor = false,
    bool clearFocusColor = false,
  }) => ScatterInteractionStyle(
    hoverColor: clearHoverColor ? null : (hoverColor ?? this.hoverColor),
    hoverScale: hoverScale ?? this.hoverScale,
    hoverStrokeWidth: hoverStrokeWidth ?? this.hoverStrokeWidth,
    pressedColor: pressedColor ?? this.pressedColor,
    pressedScale: pressedScale ?? this.pressedScale,
    pressedOpacity: pressedOpacity ?? this.pressedOpacity,
    selectionColor: clearSelectionColor
        ? null
        : (selectionColor ?? this.selectionColor),
    selectionScale: selectionScale ?? this.selectionScale,
    selectionOpacity: selectionOpacity ?? this.selectionOpacity,
    selectionStrokeWidth: selectionStrokeWidth ?? this.selectionStrokeWidth,
    focusColor: clearFocusColor ? null : (focusColor ?? this.focusColor),
    focusGap: focusGap ?? this.focusGap,
    focusStrokeWidth: focusStrokeWidth ?? this.focusStrokeWidth,
    dimmedOpacity: dimmedOpacity ?? this.dimmedOpacity,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScatterInteractionStyle &&
          other.hoverColor == hoverColor &&
          other.hoverScale == hoverScale &&
          other.hoverStrokeWidth == hoverStrokeWidth &&
          other.pressedColor == pressedColor &&
          other.pressedScale == pressedScale &&
          other.pressedOpacity == pressedOpacity &&
          other.selectionColor == selectionColor &&
          other.selectionScale == selectionScale &&
          other.selectionOpacity == selectionOpacity &&
          other.selectionStrokeWidth == selectionStrokeWidth &&
          other.focusColor == focusColor &&
          other.focusGap == focusGap &&
          other.focusStrokeWidth == focusStrokeWidth &&
          other.dimmedOpacity == dimmedOpacity;

  @override
  int get hashCode => Object.hash(
    hoverColor,
    hoverScale,
    hoverStrokeWidth,
    pressedColor,
    pressedScale,
    pressedOpacity,
    selectionColor,
    selectionScale,
    selectionOpacity,
    selectionStrokeWidth,
    focusColor,
    focusGap,
    focusStrokeWidth,
    dimmedOpacity,
  );
}
