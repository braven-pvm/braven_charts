import 'dart:ui' show Color, Offset;

import 'package:flutter/foundation.dart';

import '../theming/styles/label_style.dart';

/// Entrance animation used when a pie first mounts or receives new data.
enum PieAnimationMode {
  /// Render the final geometry immediately.
  none,

  /// Grow every slice radially from the shared center.
  grow,
}

/// Policy used when a Pie slice does not provide an explicit border color.
enum PieBorderColorMode {
  /// Use the chart theme's axis-line color for every slice.
  chartTheme,

  /// Derive each border from its slice color using the configured HSL shifts.
  slice,
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
    this.calloutStyle,
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

  /// Optional outside/inside data-label callout styling.
  final LabelStyle? calloutStyle;

  /// Default Pie entrance animation.
  final PieAnimationMode animationMode;

  /// Returns a copy with selected fields replaced.
  PieChartTheme copyWith({
    double? opacity,
    double? cornerRadius,
    PieElevationStyle? shadow,
    PieElevationStyle? selectedElevation,
    PieBorderColorMode? borderColorMode,
    double? borderHueShiftDegrees,
    double? borderSaturationShift,
    double? borderLightnessShift,
    LabelStyle? calloutStyle,
    bool clearCalloutStyle = false,
    PieAnimationMode? animationMode,
  }) {
    return PieChartTheme(
      opacity: opacity ?? this.opacity,
      cornerRadius: cornerRadius ?? this.cornerRadius,
      shadow: shadow ?? this.shadow,
      selectedElevation: selectedElevation ?? this.selectedElevation,
      borderColorMode: borderColorMode ?? this.borderColorMode,
      borderHueShiftDegrees:
          borderHueShiftDegrees ?? this.borderHueShiftDegrees,
      borderSaturationShift:
          borderSaturationShift ?? this.borderSaturationShift,
      borderLightnessShift: borderLightnessShift ?? this.borderLightnessShift,
      calloutStyle: clearCalloutStyle
          ? null
          : (calloutStyle ?? this.calloutStyle),
      animationMode: animationMode ?? this.animationMode,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PieChartTheme &&
          opacity == other.opacity &&
          cornerRadius == other.cornerRadius &&
          shadow == other.shadow &&
          selectedElevation == other.selectedElevation &&
          borderColorMode == other.borderColorMode &&
          borderHueShiftDegrees == other.borderHueShiftDegrees &&
          borderSaturationShift == other.borderSaturationShift &&
          borderLightnessShift == other.borderLightnessShift &&
          calloutStyle == other.calloutStyle &&
          animationMode == other.animationMode;

  @override
  int get hashCode => Object.hash(
    opacity,
    cornerRadius,
    shadow,
    selectedElevation,
    borderColorMode,
    borderHueShiftDegrees,
    borderSaturationShift,
    borderLightnessShift,
    calloutStyle,
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

/// Immutable per-series Pie geometry and appearance overrides.
@immutable
class PieChartStyle {
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
    this.selectionExplodeOffset = 8,
    this.opacity,
    this.cornerRadius,
    this.shadow,
    this.selectedElevation,
    this.animationMode,
  });

  /// Angle in degrees at which the first slice begins.
  final double startAngleDegrees;

  /// Whether slices advance clockwise in screen coordinates.
  final bool clockwise;

  /// Fraction of the available half-size used as the outer radius.
  final double radiusFactor;

  /// Logical-pixel gap measured along the outer circumference.
  final double sliceGap;

  /// Logical-pixel slice-border width.
  final double borderWidth;

  /// Optional shared slice-border color.
  final Color? borderColor;

  /// Optional border policy overriding [PieChartTheme.borderColorMode].
  ///
  /// A non-null [borderColor] always wins and produces a fixed shared color.
  final PieBorderColorMode? borderColorMode;

  /// Optional hue rotation overriding [PieChartTheme.borderHueShiftDegrees].
  final double? borderHueShiftDegrees;

  /// Optional saturation shift overriding
  /// [PieChartTheme.borderSaturationShift].
  final double? borderSaturationShift;

  /// Optional lightness shift overriding [PieChartTheme.borderLightnessShift].
  final double? borderLightnessShift;

  /// Logical-pixel offset applied to a selected, exploded slice.
  final double selectionExplodeOffset;

  /// Optional slice opacity overriding [PieChartTheme.opacity].
  final double? opacity;

  /// Optional corner radius overriding [PieChartTheme.cornerRadius].
  final double? cornerRadius;

  /// Optional base elevation overriding [PieChartTheme.shadow].
  final PieElevationStyle? shadow;

  /// Optional selected elevation overriding [PieChartTheme.selectedElevation].
  final PieElevationStyle? selectedElevation;

  /// Optional entrance animation overriding [PieChartTheme.animationMode].
  final PieAnimationMode? animationMode;

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
    double? selectionExplodeOffset,
    double? opacity,
    bool clearOpacity = false,
    double? cornerRadius,
    bool clearCornerRadius = false,
    PieElevationStyle? shadow,
    bool clearShadow = false,
    PieElevationStyle? selectedElevation,
    bool clearSelectedElevation = false,
    PieAnimationMode? animationMode,
    bool clearAnimationMode = false,
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
      selectionExplodeOffset:
          selectionExplodeOffset ?? this.selectionExplodeOffset,
      opacity: clearOpacity ? null : (opacity ?? this.opacity),
      cornerRadius: clearCornerRadius
          ? null
          : (cornerRadius ?? this.cornerRadius),
      shadow: clearShadow ? null : (shadow ?? this.shadow),
      selectedElevation: clearSelectedElevation
          ? null
          : (selectedElevation ?? this.selectedElevation),
      animationMode: clearAnimationMode
          ? null
          : (animationMode ?? this.animationMode),
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
          selectionExplodeOffset == other.selectionExplodeOffset &&
          opacity == other.opacity &&
          cornerRadius == other.cornerRadius &&
          shadow == other.shadow &&
          selectedElevation == other.selectedElevation &&
          animationMode == other.animationMode;

  @override
  int get hashCode => Object.hash(
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
    selectionExplodeOffset,
    opacity,
    cornerRadius,
    shadow,
    selectedElevation,
    animationMode,
  );
}

/// Immutable eligibility, placement, connector, and callout policy for labels.
@immutable
class PieDataLabelConfig {
  /// Creates pie data-label configuration.
  const PieDataLabelConfig({
    this.isVisible = true,
    this.position = PieDataLabelPosition.outside,
    this.content = PieDataLabelContent.categoryAndPercentage,
    this.minimumShare = 0.03,
    this.minimumSweepDegrees = 8,
    this.padding = 6,
    this.connectorLength = 14,
    this.connectorWidth = 1,
    this.connectorColor,
    this.collisionStrategy = PieDataLabelCollisionStrategy.shiftAndHide,
    this.calloutStyle,
  });

  /// Whether data labels are rendered.
  final bool isVisible;

  /// Requested inside or outside placement.
  final PieDataLabelPosition position;

  /// Category/value/share content shown by each label.
  final PieDataLabelContent content;

  /// Minimum share in the inclusive range 0–1 required for a label.
  final double minimumShare;

  /// Minimum absolute slice sweep in degrees required for a label.
  final double minimumSweepDegrees;

  /// Logical-pixel padding between a label and its anchor or lane.
  final double padding;

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

  /// Returns a copy with selected fields replaced.
  PieDataLabelConfig copyWith({
    bool? isVisible,
    PieDataLabelPosition? position,
    PieDataLabelContent? content,
    double? minimumShare,
    double? minimumSweepDegrees,
    double? padding,
    double? connectorLength,
    double? connectorWidth,
    Color? connectorColor,
    bool clearConnectorColor = false,
    PieDataLabelCollisionStrategy? collisionStrategy,
    LabelStyle? calloutStyle,
    bool clearCalloutStyle = false,
  }) {
    return PieDataLabelConfig(
      isVisible: isVisible ?? this.isVisible,
      position: position ?? this.position,
      content: content ?? this.content,
      minimumShare: minimumShare ?? this.minimumShare,
      minimumSweepDegrees: minimumSweepDegrees ?? this.minimumSweepDegrees,
      padding: padding ?? this.padding,
      connectorLength: connectorLength ?? this.connectorLength,
      connectorWidth: connectorWidth ?? this.connectorWidth,
      connectorColor: clearConnectorColor
          ? null
          : (connectorColor ?? this.connectorColor),
      collisionStrategy: collisionStrategy ?? this.collisionStrategy,
      calloutStyle: clearCalloutStyle
          ? null
          : (calloutStyle ?? this.calloutStyle),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PieDataLabelConfig &&
          isVisible == other.isVisible &&
          position == other.position &&
          content == other.content &&
          minimumShare == other.minimumShare &&
          minimumSweepDegrees == other.minimumSweepDegrees &&
          padding == other.padding &&
          connectorLength == other.connectorLength &&
          connectorWidth == other.connectorWidth &&
          connectorColor == other.connectorColor &&
          collisionStrategy == other.collisionStrategy &&
          calloutStyle == other.calloutStyle;

  @override
  int get hashCode => Object.hash(
    isVisible,
    position,
    content,
    minimumShare,
    minimumSweepDegrees,
    padding,
    connectorLength,
    connectorWidth,
    connectorColor,
    collisionStrategy,
    calloutStyle,
  );
}
