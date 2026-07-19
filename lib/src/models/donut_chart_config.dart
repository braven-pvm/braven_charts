import 'dart:ui' show Color;

import 'package:flutter/foundation.dart';

import 'pie_chart_config.dart';
import '../theming/styles/label_style.dart';

/// Numeric content displayed inside a Donut's shared center opening.
enum DonutCenterValueMode {
  /// Display the sum of every visible slice.
  total,

  /// Display the selected slice value, or no value when nothing is selected.
  selectedValue,

  /// Display the selected slice value and fall back to the total.
  selectedOrTotal,

  /// Display [DonutCenterContent.customValue].
  custom,
}

/// Portable, text-first content rendered inside a Donut's center opening.
///
/// This model deliberately excludes arbitrary widgets and builders so chart
/// artifacts, previews, and restored charts retain the same center meaning.
@immutable
class DonutCenterContent {
  /// Creates a center summary.
  const DonutCenterContent({
    this.isVisible = true,
    this.label,
    this.valueMode = DonutCenterValueMode.total,
    this.customValue,
    this.labelStyle,
    this.valueStyle,
    this.valueFormatter,
  });

  /// A hidden center summary used as the default on [DonutChartSeries].
  static const hidden = DonutCenterContent(isVisible: false);

  /// Whether the center summary is painted and exposed to semantics.
  final bool isVisible;

  /// Optional short label displayed above the resolved value.
  ///
  /// When omitted, selected modes use the selected category. An unselected
  /// total or custom value renders without a secondary label.
  final String? label;

  /// Source used for the primary center value.
  final DonutCenterValueMode valueMode;

  /// Explicit value used by [DonutCenterValueMode.custom].
  final String? customValue;

  /// Optional per-series label appearance override.
  final LabelStyle? labelStyle;

  /// Optional per-series value appearance override.
  final LabelStyle? valueStyle;

  /// Optional formatter for numeric total and selected-value center modes.
  ///
  /// Custom string values bypass this callback. The formatter owns the
  /// complete returned text, including units.
  final RadialValueFormatter? valueFormatter;

  /// Returns a copy with selected fields replaced.
  DonutCenterContent copyWith({
    bool? isVisible,
    String? label,
    bool clearLabel = false,
    DonutCenterValueMode? valueMode,
    String? customValue,
    bool clearCustomValue = false,
    LabelStyle? labelStyle,
    bool clearLabelStyle = false,
    LabelStyle? valueStyle,
    bool clearValueStyle = false,
    RadialValueFormatter? valueFormatter,
    bool clearValueFormatter = false,
  }) => DonutCenterContent(
    isVisible: isVisible ?? this.isVisible,
    label: clearLabel ? null : (label ?? this.label),
    valueMode: valueMode ?? this.valueMode,
    customValue: clearCustomValue ? null : (customValue ?? this.customValue),
    labelStyle: clearLabelStyle ? null : (labelStyle ?? this.labelStyle),
    valueStyle: clearValueStyle ? null : (valueStyle ?? this.valueStyle),
    valueFormatter: clearValueFormatter
        ? null
        : (valueFormatter ?? this.valueFormatter),
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DonutCenterContent &&
          isVisible == other.isVisible &&
          label == other.label &&
          valueMode == other.valueMode &&
          customValue == other.customValue &&
          labelStyle == other.labelStyle &&
          valueStyle == other.valueStyle &&
          valueFormatter == other.valueFormatter;

  @override
  int get hashCode => Object.hash(
    isVisible,
    label,
    valueMode,
    customValue,
    labelStyle,
    valueStyle,
    valueFormatter,
  );
}

/// Immutable per-series Donut geometry and appearance overrides.
///
/// Donut reuses the established radial slice appearance contract while adding
/// a required circular opening and an optional partial sweep.
@immutable
class DonutChartStyle extends PieChartStyle {
  /// Creates Donut geometry and optional theme overrides.
  const DonutChartStyle({
    this.innerRadiusFactor = 0.58,
    this.sweepAngleDegrees = 360,
    super.startAngleDegrees,
    super.clockwise,
    super.radiusFactor,
    super.sliceGap,
    super.borderWidth,
    super.borderColor,
    super.borderColorMode,
    super.borderHueShiftDegrees,
    super.borderSaturationShift,
    super.borderLightnessShift,
    super.gradient,
    super.selectionExplodeOffset,
    super.opacity,
    super.cornerRadius,
    super.cornerTreatment,
    super.shadow,
    super.selectedElevation,
    super.animationMode,
    super.dataTransitionMode,
  });

  /// Creates a Donut style from an existing shared radial appearance.
  factory DonutChartStyle.fromRadialStyle(
    RadialChartStyle style, {
    double innerRadiusFactor = 0.58,
    double sweepAngleDegrees = 360,
  }) => DonutChartStyle(
    innerRadiusFactor: innerRadiusFactor,
    sweepAngleDegrees: sweepAngleDegrees,
    startAngleDegrees: style.startAngleDegrees,
    clockwise: style.clockwise,
    radiusFactor: style.radiusFactor,
    sliceGap: style.sliceGap,
    borderWidth: style.borderWidth,
    borderColor: style.borderColor,
    borderColorMode: style.borderColorMode,
    borderHueShiftDegrees: style.borderHueShiftDegrees,
    borderSaturationShift: style.borderSaturationShift,
    borderLightnessShift: style.borderLightnessShift,
    gradient: style.gradient,
    selectionExplodeOffset: style.selectionExplodeOffset,
    opacity: style.opacity,
    cornerRadius: style.cornerRadius,
    cornerTreatment: style.cornerTreatment,
    shadow: style.shadow,
    selectedElevation: style.selectedElevation,
    animationMode: style.animationMode,
    dataTransitionMode: style.dataTransitionMode,
  );

  /// Radius of the shared center opening as a fraction of the maximum outer
  /// radius. Values must be finite and in the open interval `(0, 1)`.
  final double innerRadiusFactor;

  /// Total angular span distributed across all visible slices.
  ///
  /// Values must be finite and in `(0, 360]`. The start angle and direction
  /// come from [startAngleDegrees] and [clockwise].
  final double sweepAngleDegrees;

  /// Returns a copy with selected fields replaced.
  @override
  DonutChartStyle copyWith({
    double? innerRadiusFactor,
    double? sweepAngleDegrees,
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
  }) => DonutChartStyle(
    innerRadiusFactor: innerRadiusFactor ?? this.innerRadiusFactor,
    sweepAngleDegrees: sweepAngleDegrees ?? this.sweepAngleDegrees,
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

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DonutChartStyle &&
          super == other &&
          innerRadiusFactor == other.innerRadiusFactor &&
          sweepAngleDegrees == other.sweepAngleDegrees;

  @override
  int get hashCode =>
      Object.hash(super.hashCode, innerRadiusFactor, sweepAngleDegrees);
}
