import 'dart:ui' show Color, Offset;

import 'package:flutter/foundation.dart';

import '../theming/styles/label_style.dart';

/// Formats one numeric component shown by a Pie or Donut surface.
///
/// Formatters own the complete returned text, including any unit or suffix.
/// Portable chart artifacts require a matching formatter descriptor at
/// extraction time so the callback can be safely rebound during hydration.
typedef RadialValueFormatter = String Function(double value);

/// Entrance animation used when a Pie or Donut first mounts or is replayed.
enum PieAnimationMode {
  /// Render the final geometry immediately.
  none,

  /// Grow every slice radially from the shared center.
  grow,

  /// Reveal slices progressively through the configured angular sweep.
  ///
  /// The reveal starts at [RadialChartStyle.startAngleDegrees] and follows
  /// [RadialChartStyle.clockwise].
  sweep,

  /// Fade the complete radial geometry into view.
  fade,
}

/// Policy for data-to-data transitions after a radial chart is mounted.
enum RadialDataTransitionMode {
  /// Apply new data immediately.
  none,

  /// Interpolate stable categories and use a structural fade for category
  /// insertion, removal, or reordering.
  automatic,
}

/// Policy used when a Pie slice does not provide an explicit border color.
enum PieBorderColorMode {
  /// Use the chart theme's axis-line color for every slice.
  chartTheme,

  /// Derive each border from its slice color using the configured HSL shifts.
  slice,
}

/// Shader geometry used to fill Pie slices.
enum PieGradientType {
  /// Blend along a shared directional axis across the complete Pie.
  linear,

  /// Blend from the shared Pie center towards its outer edge.
  radial,
}

/// Immutable gradient fill shared by every slice in a Pie series.
///
/// When [startColor] or [endColor] is null, that stop is derived from each
/// slice's resolved palette color using the matching lightness shift. This
/// preserves category identity while giving the complete Pie one consistent
/// light source.
@immutable
class PieGradientStyle {
  /// Creates a Pie gradient fill.
  const PieGradientStyle({
    this.enabled = true,
    this.type = PieGradientType.linear,
    this.startColor,
    this.endColor,
    this.startLightnessShift = 0.16,
    this.endLightnessShift = -0.12,
    this.angleDegrees = -45,
  });

  /// Whether this gradient is painted.
  ///
  /// Use a disabled style on a series to opt out of a theme gradient.
  final bool enabled;

  /// Directional or center-to-edge shader geometry.
  final PieGradientType type;

  /// Optional fixed first stop; null derives it from each slice color.
  final Color? startColor;

  /// Optional fixed final stop; null derives it from each slice color.
  final Color? endColor;

  /// Additive HSL lightness shift for a derived first stop.
  final double startLightnessShift;

  /// Additive HSL lightness shift for a derived final stop.
  final double endLightnessShift;

  /// Linear-gradient direction in screen-space degrees.
  ///
  /// Zero degrees points right and 90 degrees points down. Radial gradients
  /// ignore this value.
  final double angleDegrees;

  /// Returns a copy with selected fields replaced.
  PieGradientStyle copyWith({
    bool? enabled,
    PieGradientType? type,
    Color? startColor,
    bool clearStartColor = false,
    Color? endColor,
    bool clearEndColor = false,
    double? startLightnessShift,
    double? endLightnessShift,
    double? angleDegrees,
  }) {
    return PieGradientStyle(
      enabled: enabled ?? this.enabled,
      type: type ?? this.type,
      startColor: clearStartColor ? null : (startColor ?? this.startColor),
      endColor: clearEndColor ? null : (endColor ?? this.endColor),
      startLightnessShift: startLightnessShift ?? this.startLightnessShift,
      endLightnessShift: endLightnessShift ?? this.endLightnessShift,
      angleDegrees: angleDegrees ?? this.angleDegrees,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PieGradientStyle &&
          enabled == other.enabled &&
          type == other.type &&
          startColor == other.startColor &&
          endColor == other.endColor &&
          startLightnessShift == other.startLightnessShift &&
          endLightnessShift == other.endLightnessShift &&
          angleDegrees == other.angleDegrees;

  @override
  int get hashCode => Object.hash(
    enabled,
    type,
    startColor,
    endColor,
    startLightnessShift,
    endLightnessShift,
    angleDegrees,
  );
}

/// A reusable blurred elevation layer for pie slices.
///
/// A downward [offset] and dark [color] reads as a shadow. A zero offset with
/// a slice-derived color reads as a glow. When [color] is null, the renderer
/// derives the layer from the slice color.
@immutable
class PieElevationStyle {
  /// Creates an elevation layer.
  const PieElevationStyle({
    this.color,
    this.blurRadius = 0,
    this.spreadRadius = 0,
    this.offset = Offset.zero,
    this.opacity = 1,
  }) : assert(blurRadius >= 0),
       assert(spreadRadius >= 0),
       assert(opacity >= 0 && opacity <= 1);

  /// Optional fixed layer color; null derives it from the slice.
  final Color? color;

  /// Soft-edge blur extent in logical pixels.
  final double blurRadius;

  /// Extra logical pixels drawn around the slice before blur.
  final double spreadRadius;

  /// Layer offset in logical pixels.
  final Offset offset;

  /// Layer opacity in the inclusive range 0–1.
  final double opacity;

  /// Whether this layer changes the rendered output.
  bool get isVisible =>
      opacity > 0 &&
      (blurRadius > 0 || spreadRadius > 0 || offset != Offset.zero);

  /// Returns a copy with selected fields replaced.
  PieElevationStyle copyWith({
    Color? color,
    bool clearColor = false,
    double? blurRadius,
    double? spreadRadius,
    Offset? offset,
    double? opacity,
  }) {
    return PieElevationStyle(
      color: clearColor ? null : (color ?? this.color),
      blurRadius: blurRadius ?? this.blurRadius,
      spreadRadius: spreadRadius ?? this.spreadRadius,
      offset: offset ?? this.offset,
      opacity: opacity ?? this.opacity,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PieElevationStyle &&
          color == other.color &&
          blurRadius == other.blurRadius &&
          spreadRadius == other.spreadRadius &&
          offset == other.offset &&
          opacity == other.opacity;

  @override
  int get hashCode =>
      Object.hash(color, blurRadius, spreadRadius, offset, opacity);
}

/// Controls how a Pie slice's inner and outer corners are resolved.
enum PieCornerTreatment {
  /// Round both outer corners and each slice's independent center tip.
  ///
  /// This preserves the original Braven Charts Pie rendering.
  roundAll,

  /// Round only the two corners on the outer circumference.
  ///
  /// Radial edges meet at a sharp slice apex.
  outerOnly,

  /// Round the outer corners and subtract one uniform circular center gap.
  ///
  /// The gap is shared by every non-exploded slice, so variable-radius slices
  /// retain a visually circular center instead of forming uneven rounded tips.
  circularCenter,
}

/// Theme defaults shared by radial Pie charts.
///
/// Per-series values in [PieChartStyle] and [PieDataLabelConfig] take
/// precedence. Existing [SeriesTheme], [LegendStyle], and [InteractionTheme]
/// continue to own palettes, legends, and tooltips respectively.
@immutable
class PieChartTheme {
  /// Creates radial theme defaults.
  const PieChartTheme({
    this.opacity = 1,
    this.cornerRadius = 0,
    this.cornerTreatment = PieCornerTreatment.roundAll,
    this.shadow = const PieElevationStyle(),
    this.selectedElevation = const PieElevationStyle(
      blurRadius: 10,
      spreadRadius: 1,
      opacity: 0.38,
    ),
    this.borderColorMode = PieBorderColorMode.chartTheme,
    this.borderHueShiftDegrees = 0,
    this.borderSaturationShift = 0,
    this.borderLightnessShift = -0.12,
    this.gradient,
    this.calloutStyle,
    this.centerLabelStyle,
    this.centerValueStyle,
    this.animationMode = PieAnimationMode.grow,
  }) : assert(opacity >= 0 && opacity <= 1),
       assert(cornerRadius >= 0),
       assert(
         borderHueShiftDegrees > double.negativeInfinity &&
             borderHueShiftDegrees < double.infinity,
       ),
       assert(borderSaturationShift >= -1 && borderSaturationShift <= 1),
       assert(borderLightnessShift >= -1 && borderLightnessShift <= 1);

  /// Default slice opacity in the inclusive range 0–1.
  final double opacity;

  /// Default corner radius in logical pixels.
  final double cornerRadius;

  /// Default policy for applying [cornerRadius] to Pie slice paths.
  final PieCornerTreatment cornerTreatment;

  /// Default elevation applied to every slice.
  final PieElevationStyle shadow;

  /// Additional elevation applied to selected slices.
  final PieElevationStyle selectedElevation;

  /// Default border-color policy when a series has no fixed
  /// [PieChartStyle.borderColor].
  final PieBorderColorMode borderColorMode;

  /// Hue rotation applied by [PieBorderColorMode.slice].
  final double borderHueShiftDegrees;

  /// Additive HSL saturation shift applied by [PieBorderColorMode.slice].
  final double borderSaturationShift;

  /// Additive HSL lightness shift applied by [PieBorderColorMode.slice].
  final double borderLightnessShift;

  /// Optional default slice gradient; null keeps solid palette fills.
  final PieGradientStyle? gradient;

  /// Optional outside/inside data-label callout styling.
  final LabelStyle? calloutStyle;

  /// Optional theme-level appearance for a Donut center label.
  final LabelStyle? centerLabelStyle;

  /// Optional theme-level appearance for a Donut center value.
  final LabelStyle? centerValueStyle;

  /// Default Pie and Donut entrance animation.
  final PieAnimationMode animationMode;

  /// Returns a copy with selected fields replaced.
  PieChartTheme copyWith({
    double? opacity,
    double? cornerRadius,
    PieCornerTreatment? cornerTreatment,
    PieElevationStyle? shadow,
    PieElevationStyle? selectedElevation,
    PieBorderColorMode? borderColorMode,
    double? borderHueShiftDegrees,
    double? borderSaturationShift,
    double? borderLightnessShift,
    PieGradientStyle? gradient,
    bool clearGradient = false,
    LabelStyle? calloutStyle,
    bool clearCalloutStyle = false,
    LabelStyle? centerLabelStyle,
    bool clearCenterLabelStyle = false,
    LabelStyle? centerValueStyle,
    bool clearCenterValueStyle = false,
    PieAnimationMode? animationMode,
  }) {
    return PieChartTheme(
      opacity: opacity ?? this.opacity,
      cornerRadius: cornerRadius ?? this.cornerRadius,
      cornerTreatment: cornerTreatment ?? this.cornerTreatment,
      shadow: shadow ?? this.shadow,
      selectedElevation: selectedElevation ?? this.selectedElevation,
      borderColorMode: borderColorMode ?? this.borderColorMode,
      borderHueShiftDegrees:
          borderHueShiftDegrees ?? this.borderHueShiftDegrees,
      borderSaturationShift:
          borderSaturationShift ?? this.borderSaturationShift,
      borderLightnessShift: borderLightnessShift ?? this.borderLightnessShift,
      gradient: clearGradient ? null : (gradient ?? this.gradient),
      calloutStyle: clearCalloutStyle
          ? null
          : (calloutStyle ?? this.calloutStyle),
      centerLabelStyle: clearCenterLabelStyle
          ? null
          : (centerLabelStyle ?? this.centerLabelStyle),
      centerValueStyle: clearCenterValueStyle
          ? null
          : (centerValueStyle ?? this.centerValueStyle),
      animationMode: animationMode ?? this.animationMode,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PieChartTheme &&
          opacity == other.opacity &&
          cornerRadius == other.cornerRadius &&
          cornerTreatment == other.cornerTreatment &&
          shadow == other.shadow &&
          selectedElevation == other.selectedElevation &&
          borderColorMode == other.borderColorMode &&
          borderHueShiftDegrees == other.borderHueShiftDegrees &&
          borderSaturationShift == other.borderSaturationShift &&
          borderLightnessShift == other.borderLightnessShift &&
          gradient == other.gradient &&
          calloutStyle == other.calloutStyle &&
          centerLabelStyle == other.centerLabelStyle &&
          centerValueStyle == other.centerValueStyle &&
          animationMode == other.animationMode;

  @override
  int get hashCode => Object.hash(
    opacity,
    cornerRadius,
    cornerTreatment,
    shadow,
    selectedElevation,
    borderColorMode,
    borderHueShiftDegrees,
    borderSaturationShift,
    borderLightnessShift,
    gradient,
    calloutStyle,
    centerLabelStyle,
    centerValueStyle,
    animationMode,
  );
}

/// Content rendered for an eligible pie-slice data label.
enum PieDataLabelContent {
  /// Category only.
  category,

  /// Formatted numeric value only.
  value,

  /// Percentage share only.
  percentage,

  /// Category followed by the formatted value.
  categoryAndValue,

  /// Category followed by its percentage share.
  categoryAndPercentage,

  /// Formatted value followed by its percentage share.
  valueAndPercentage,

  /// Category, formatted value, and percentage share.
  categoryValueAndPercentage,
}

/// Placement of pie-slice data labels.
enum PieDataLabelPosition {
  /// Place labels inside eligible slices.
  inside,

  /// Place labels in collision-managed lanes outside the pie.
  outside,
}

/// Policy used when outside pie labels would overlap.
enum PieDataLabelCollisionStrategy {
  /// Keep the requested anchors even if labels overlap.
  none,

  /// Shift labels within their side lane while space remains.
  shift,

  /// Shift labels, then hide the lowest-priority labels if space is exhausted.
  shiftAndHide,
}

/// Mapping used to turn raw per-slice radius values into visible radii.
enum PieSliceRadiusScale {
  /// Interpolate the visible radius directly from the normalized value.
  linear,

  /// Interpolate squared radius so equal value changes produce equal area
  /// changes. This is the default because area is the perceived quantity.
  area,
}

/// Immutable encoding policy for an optional second Pie value dimension.
///
/// Angular share continues to come from `ChartDataPoint.y`. When this config
/// is attached to a `PieChartSeries`, every point supplies its raw radius
/// value through `PointStyle.size`. The values are normalized across visible
/// slices and mapped between [minimumFactor] and the series' outer radius.
@immutable
class PieSliceRadiusConfig {
  /// Creates a variable slice-radius encoding.
  const PieSliceRadiusConfig({
    this.minimumFactor = 0.35,
    this.scale = PieSliceRadiusScale.area,
    this.label = 'Radius',
    this.unit,
    this.formatter,
  });

  /// Smallest radius as a fraction of the maximum Pie radius.
  final double minimumFactor;

  /// Perceptual mapping applied after values are normalized.
  final PieSliceRadiusScale scale;

  /// Human-readable name for the radius metric in tables and tooltips.
  final String label;

  /// Optional unit for the radius metric.
  final String? unit;

  /// Optional formatter shared by radius tooltips and custom consumers.
  final RadialValueFormatter? formatter;

  /// Returns a copy with selected fields replaced.
  PieSliceRadiusConfig copyWith({
    double? minimumFactor,
    PieSliceRadiusScale? scale,
    String? label,
    String? unit,
    bool clearUnit = false,
    RadialValueFormatter? formatter,
    bool clearFormatter = false,
  }) => PieSliceRadiusConfig(
    minimumFactor: minimumFactor ?? this.minimumFactor,
    scale: scale ?? this.scale,
    label: label ?? this.label,
    unit: clearUnit ? null : (unit ?? this.unit),
    formatter: clearFormatter ? null : (formatter ?? this.formatter),
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PieSliceRadiusConfig &&
          minimumFactor == other.minimumFactor &&
          scale == other.scale &&
          label == other.label &&
          unit == other.unit &&
          formatter == other.formatter;

  @override
  int get hashCode => Object.hash(minimumFactor, scale, label, unit, formatter);
}

/// Shared name for the optional second-metric radius encoding used by radial
/// category charts.
///
/// [PieSliceRadiusConfig] remains the source-compatible Pie API name.
typedef RadialSliceRadiusConfig = PieSliceRadiusConfig;

/// Common geometry and appearance contract implemented by radial chart styles.
///
/// Pie and Donut keep distinct public style models while the renderer consumes
/// this stable shared surface.
abstract interface class RadialChartStyle {
  double get startAngleDegrees;
  bool get clockwise;
  double get radiusFactor;
  double get sliceGap;
  double get borderWidth;
  Color? get borderColor;
  PieBorderColorMode? get borderColorMode;
  double? get borderHueShiftDegrees;
  double? get borderSaturationShift;
  double? get borderLightnessShift;
  PieGradientStyle? get gradient;
  double get selectionExplodeOffset;
  double? get opacity;
  double? get cornerRadius;
  PieCornerTreatment? get cornerTreatment;
  PieElevationStyle? get shadow;
  PieElevationStyle? get selectedElevation;
  PieAnimationMode? get animationMode;
  RadialDataTransitionMode get dataTransitionMode;
}

/// Immutable per-series Pie geometry and appearance overrides.
@immutable
class PieChartStyle implements RadialChartStyle {
  /// Creates Pie geometry and optional theme overrides.
  const PieChartStyle({
    this.startAngleDegrees = -90,
    this.clockwise = true,
    this.radiusFactor = 0.9,
    this.sliceGap = 2,
    this.borderWidth = 1,
    this.borderColor,
    this.borderColorMode,
    this.borderHueShiftDegrees,
    this.borderSaturationShift,
    this.borderLightnessShift,
    this.gradient,
    this.selectionExplodeOffset = 8,
    this.opacity,
    this.cornerRadius,
    this.cornerTreatment,
    this.shadow,
    this.selectedElevation,
    this.animationMode,
    this.dataTransitionMode = RadialDataTransitionMode.automatic,
  });

  /// Angle in degrees at which the first slice begins.
  @override
  final double startAngleDegrees;

  /// Whether slices advance clockwise in screen coordinates.
  @override
  final bool clockwise;

  /// Fraction of the available half-size used as the outer radius.
  @override
  final double radiusFactor;

  /// Logical-pixel gap measured along the outer circumference.
  @override
  final double sliceGap;

  /// Logical-pixel slice-border width.
  @override
  final double borderWidth;

  /// Optional shared slice-border color.
  @override
  final Color? borderColor;

  /// Optional border policy overriding [PieChartTheme.borderColorMode].
  ///
  /// A non-null [borderColor] always wins and produces a fixed shared color.
  @override
  final PieBorderColorMode? borderColorMode;

  /// Optional hue rotation overriding [PieChartTheme.borderHueShiftDegrees].
  @override
  final double? borderHueShiftDegrees;

  /// Optional saturation shift overriding
  /// [PieChartTheme.borderSaturationShift].
  @override
  final double? borderSaturationShift;

  /// Optional lightness shift overriding [PieChartTheme.borderLightnessShift].
  @override
  final double? borderLightnessShift;

  /// Optional gradient overriding [PieChartTheme.gradient].
  ///
  /// A disabled gradient explicitly restores solid fills for this series.
  @override
  final PieGradientStyle? gradient;

  /// Logical-pixel offset applied to a selected, exploded slice.
  @override
  final double selectionExplodeOffset;

  /// Optional slice opacity overriding [PieChartTheme.opacity].
  @override
  final double? opacity;

  /// Optional corner radius overriding [PieChartTheme.cornerRadius].
  @override
  final double? cornerRadius;

  /// Optional corner policy overriding [PieChartTheme.cornerTreatment].
  @override
  final PieCornerTreatment? cornerTreatment;

  /// Optional base elevation overriding [PieChartTheme.shadow].
  @override
  final PieElevationStyle? shadow;

  /// Optional selected elevation overriding [PieChartTheme.selectedElevation].
  @override
  final PieElevationStyle? selectedElevation;

  /// Optional entrance animation overriding [PieChartTheme.animationMode].
  @override
  final PieAnimationMode? animationMode;

  /// Data-to-data motion policy, independent from entrance animation.
  @override
  final RadialDataTransitionMode dataTransitionMode;

  /// Returns a copy with selected fields replaced.
  PieChartStyle copyWith({
    double? startAngleDegrees,
    bool? clockwise,
    double? radiusFactor,
    double? sliceGap,
    double? borderWidth,
    Color? borderColor,
    bool clearBorderColor = false,
    PieBorderColorMode? borderColorMode,
    bool clearBorderColorMode = false,
    double? borderHueShiftDegrees,
    bool clearBorderHueShiftDegrees = false,
    double? borderSaturationShift,
    bool clearBorderSaturationShift = false,
    double? borderLightnessShift,
    bool clearBorderLightnessShift = false,
    PieGradientStyle? gradient,
    bool clearGradient = false,
    double? selectionExplodeOffset,
    double? opacity,
    bool clearOpacity = false,
    double? cornerRadius,
    bool clearCornerRadius = false,
    PieCornerTreatment? cornerTreatment,
    bool clearCornerTreatment = false,
    PieElevationStyle? shadow,
    bool clearShadow = false,
    PieElevationStyle? selectedElevation,
    bool clearSelectedElevation = false,
    PieAnimationMode? animationMode,
    bool clearAnimationMode = false,
    RadialDataTransitionMode? dataTransitionMode,
  }) {
    return PieChartStyle(
      startAngleDegrees: startAngleDegrees ?? this.startAngleDegrees,
      clockwise: clockwise ?? this.clockwise,
      radiusFactor: radiusFactor ?? this.radiusFactor,
      sliceGap: sliceGap ?? this.sliceGap,
      borderWidth: borderWidth ?? this.borderWidth,
      borderColor: clearBorderColor ? null : (borderColor ?? this.borderColor),
      borderColorMode: clearBorderColorMode
          ? null
          : (borderColorMode ?? this.borderColorMode),
      borderHueShiftDegrees: clearBorderHueShiftDegrees
          ? null
          : (borderHueShiftDegrees ?? this.borderHueShiftDegrees),
      borderSaturationShift: clearBorderSaturationShift
          ? null
          : (borderSaturationShift ?? this.borderSaturationShift),
      borderLightnessShift: clearBorderLightnessShift
          ? null
          : (borderLightnessShift ?? this.borderLightnessShift),
      gradient: clearGradient ? null : (gradient ?? this.gradient),
      selectionExplodeOffset:
          selectionExplodeOffset ?? this.selectionExplodeOffset,
      opacity: clearOpacity ? null : (opacity ?? this.opacity),
      cornerRadius: clearCornerRadius
          ? null
          : (cornerRadius ?? this.cornerRadius),
      cornerTreatment: clearCornerTreatment
          ? null
          : (cornerTreatment ?? this.cornerTreatment),
      shadow: clearShadow ? null : (shadow ?? this.shadow),
      selectedElevation: clearSelectedElevation
          ? null
          : (selectedElevation ?? this.selectedElevation),
      animationMode: clearAnimationMode
          ? null
          : (animationMode ?? this.animationMode),
      dataTransitionMode: dataTransitionMode ?? this.dataTransitionMode,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PieChartStyle &&
          startAngleDegrees == other.startAngleDegrees &&
          clockwise == other.clockwise &&
          radiusFactor == other.radiusFactor &&
          sliceGap == other.sliceGap &&
          borderWidth == other.borderWidth &&
          borderColor == other.borderColor &&
          borderColorMode == other.borderColorMode &&
          borderHueShiftDegrees == other.borderHueShiftDegrees &&
          borderSaturationShift == other.borderSaturationShift &&
          borderLightnessShift == other.borderLightnessShift &&
          gradient == other.gradient &&
          selectionExplodeOffset == other.selectionExplodeOffset &&
          opacity == other.opacity &&
          cornerRadius == other.cornerRadius &&
          cornerTreatment == other.cornerTreatment &&
          shadow == other.shadow &&
          selectedElevation == other.selectedElevation &&
          animationMode == other.animationMode &&
          dataTransitionMode == other.dataTransitionMode;

  @override
  int get hashCode => Object.hashAll([
    startAngleDegrees,
    clockwise,
    radiusFactor,
    sliceGap,
    borderWidth,
    borderColor,
    borderColorMode,
    borderHueShiftDegrees,
    borderSaturationShift,
    borderLightnessShift,
    gradient,
    selectionExplodeOffset,
    opacity,
    cornerRadius,
    cornerTreatment,
    shadow,
    selectedElevation,
    animationMode,
    dataTransitionMode,
  ]);
}

/// Immutable eligibility, placement, connector, and callout policy for labels.
@immutable
class PieDataLabelConfig {
  /// Creates pie data-label configuration.
  const PieDataLabelConfig({
    this.isVisible = true,
    this.position = PieDataLabelPosition.outside,
    this.content = PieDataLabelContent.categoryAndPercentage,
    this.secondaryContent,
    this.secondaryPosition = PieDataLabelPosition.inside,
    this.secondaryCalloutStyle,
    this.minimumShare = 0.03,
    this.minimumSweepDegrees = 8,
    this.padding = 6,
    this.insideOffset = 0,
    this.outsideOffset = 0,
    this.connectorLength = 14,
    this.connectorWidth = 1,
    this.connectorColor,
    this.collisionStrategy = PieDataLabelCollisionStrategy.shiftAndHide,
    this.calloutStyle,
    this.valueFormatter,
    this.percentageFormatter,
  });

  /// Whether data labels are rendered.
  final bool isVisible;

  /// Requested inside or outside placement.
  final PieDataLabelPosition position;

  /// Category/value/share content shown by each label.
  final PieDataLabelContent content;

  /// Optional content for a second label layer on the opposite placement.
  ///
  /// This supports radial compositions such as an outside category callout
  /// paired with a compact percentage badge inside the same slice. Leave null
  /// to render only the primary [content] layer.
  final PieDataLabelContent? secondaryContent;

  /// Placement of [secondaryContent].
  ///
  /// When [secondaryContent] is not null this must differ from [position], so
  /// each placement owns at most one deterministic label layer.
  final PieDataLabelPosition secondaryPosition;

  /// Optional callout style for [secondaryContent].
  ///
  /// Null resolves from [PieChartTheme], independently of [calloutStyle].
  final LabelStyle? secondaryCalloutStyle;

  /// Whether this configuration paints a label at [placement].
  bool hasLabelAt(PieDataLabelPosition placement) =>
      position == placement ||
      (secondaryContent != null && secondaryPosition == placement);

  /// Minimum share in the inclusive range 0–1 required for a label.
  final double minimumShare;

  /// Minimum absolute slice sweep in degrees required for a label.
  final double minimumSweepDegrees;

  /// Logical-pixel padding between a label and its anchor or lane.
  final double padding;

  /// Signed radial offset applied to labels painted inside a slice.
  ///
  /// Zero uses the renderer's balanced position within the radial band.
  /// Positive values move the label toward the outer edge; negative values
  /// move it toward the chart center. The resolved anchor remains inside the
  /// slice's radial band.
  final double insideOffset;

  /// Horizontal gap between the painted pie and an outside-label lane.
  ///
  /// A value of zero keeps the aligned label lane tight to the pie. Positive
  /// values move it outwards while the renderer keeps labels inside the plot.
  final double outsideOffset;

  /// Logical-pixel radial connector length for outside labels.
  final double connectorLength;

  /// Logical-pixel connector stroke width.
  final double connectorWidth;

  /// Optional connector color; the renderer otherwise derives one from theme.
  final Color? connectorColor;

  /// Collision policy for outside labels.
  final PieDataLabelCollisionStrategy collisionStrategy;

  /// Optional label callout override; null resolves from [PieChartTheme].
  final LabelStyle? calloutStyle;

  /// Optional value formatter shared by labels, legends, tooltips, and
  /// assistive descriptions.
  final RadialValueFormatter? valueFormatter;

  /// Optional fractional-share formatter shared by labels, legends,
  /// tooltips, and assistive descriptions. The input is in the range 0–1.
  final RadialValueFormatter? percentageFormatter;

  /// Returns a copy with selected fields replaced.
  PieDataLabelConfig copyWith({
    bool? isVisible,
    PieDataLabelPosition? position,
    PieDataLabelContent? content,
    PieDataLabelContent? secondaryContent,
    bool clearSecondaryContent = false,
    PieDataLabelPosition? secondaryPosition,
    LabelStyle? secondaryCalloutStyle,
    bool clearSecondaryCalloutStyle = false,
    double? minimumShare,
    double? minimumSweepDegrees,
    double? padding,
    double? insideOffset,
    double? outsideOffset,
    double? connectorLength,
    double? connectorWidth,
    Color? connectorColor,
    bool clearConnectorColor = false,
    PieDataLabelCollisionStrategy? collisionStrategy,
    LabelStyle? calloutStyle,
    bool clearCalloutStyle = false,
    RadialValueFormatter? valueFormatter,
    bool clearValueFormatter = false,
    RadialValueFormatter? percentageFormatter,
    bool clearPercentageFormatter = false,
  }) {
    return PieDataLabelConfig(
      isVisible: isVisible ?? this.isVisible,
      position: position ?? this.position,
      content: content ?? this.content,
      secondaryContent: clearSecondaryContent
          ? null
          : (secondaryContent ?? this.secondaryContent),
      secondaryPosition: secondaryPosition ?? this.secondaryPosition,
      secondaryCalloutStyle: clearSecondaryCalloutStyle
          ? null
          : (secondaryCalloutStyle ?? this.secondaryCalloutStyle),
      minimumShare: minimumShare ?? this.minimumShare,
      minimumSweepDegrees: minimumSweepDegrees ?? this.minimumSweepDegrees,
      padding: padding ?? this.padding,
      insideOffset: insideOffset ?? this.insideOffset,
      outsideOffset: outsideOffset ?? this.outsideOffset,
      connectorLength: connectorLength ?? this.connectorLength,
      connectorWidth: connectorWidth ?? this.connectorWidth,
      connectorColor: clearConnectorColor
          ? null
          : (connectorColor ?? this.connectorColor),
      collisionStrategy: collisionStrategy ?? this.collisionStrategy,
      calloutStyle: clearCalloutStyle
          ? null
          : (calloutStyle ?? this.calloutStyle),
      valueFormatter: clearValueFormatter
          ? null
          : (valueFormatter ?? this.valueFormatter),
      percentageFormatter: clearPercentageFormatter
          ? null
          : (percentageFormatter ?? this.percentageFormatter),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PieDataLabelConfig &&
          isVisible == other.isVisible &&
          position == other.position &&
          content == other.content &&
          secondaryContent == other.secondaryContent &&
          secondaryPosition == other.secondaryPosition &&
          secondaryCalloutStyle == other.secondaryCalloutStyle &&
          minimumShare == other.minimumShare &&
          minimumSweepDegrees == other.minimumSweepDegrees &&
          padding == other.padding &&
          insideOffset == other.insideOffset &&
          outsideOffset == other.outsideOffset &&
          connectorLength == other.connectorLength &&
          connectorWidth == other.connectorWidth &&
          connectorColor == other.connectorColor &&
          collisionStrategy == other.collisionStrategy &&
          calloutStyle == other.calloutStyle &&
          valueFormatter == other.valueFormatter &&
          percentageFormatter == other.percentageFormatter;

  @override
  int get hashCode => Object.hash(
    isVisible,
    position,
    content,
    secondaryContent,
    secondaryPosition,
    secondaryCalloutStyle,
    minimumShare,
    minimumSweepDegrees,
    padding,
    insideOffset,
    outsideOffset,
    connectorLength,
    connectorWidth,
    connectorColor,
    collisionStrategy,
    calloutStyle,
    valueFormatter,
    percentageFormatter,
  );
}
