// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

import 'dart:ui' show Color;

import 'package:flutter/painting.dart'
    show BorderRadius, BoxShadow, EdgeInsets, TextStyle;

import 'chart_style_value.dart';

/// Visual overrides for the Cartesian value summary panel.
///
/// Every field is a tri-state [ChartStyleValue] so authors can distinguish
/// inheriting the theme default from explicitly clearing the property:
///
/// - [ChartStyleValue.inherit] (the default for every field) resolves to the
///   `CartesianValueSummaryTheme` default for the active chart theme;
/// - [ChartStyleValue.value] overrides the theme default;
/// - [ChartStyleValue.none] clears the property outright — a cleared
///   background is truly transparent and a cleared border draws no stroke,
///   with no silent fallback to the theme.
///
/// The fixed overlay and the draggable annotation presentation resolve the
/// exact same effective style from this model. A transparent surface does not
/// waive text-contrast requirements; authors clearing the background remain
/// responsible for an explicit, legible text color.
///
/// Example:
/// ```dart
/// const style = CartesianValueSummaryStyle(
///   backgroundColor: ChartStyleValue.value(Color(0xEE1E2430)),
///   borderColor: ChartStyleValue.none(),
/// );
/// ```
class CartesianValueSummaryStyle {
  /// Creates a summary style. Every field defaults to
  /// [ChartStyleValue.inherit].
  const CartesianValueSummaryStyle({
    this.backgroundColor = const ChartStyleValue<Color>.inherit(),
    this.backgroundOpacity = const ChartStyleValue<double>.inherit(),
    this.borderColor = const ChartStyleValue<Color>.inherit(),
    this.borderWidth = const ChartStyleValue<double>.inherit(),
    this.borderRadius = const ChartStyleValue<BorderRadius>.inherit(),
    this.padding = const ChartStyleValue<EdgeInsets>.inherit(),
    this.textStyle = const ChartStyleValue<TextStyle>.inherit(),
    this.labelStyle = const ChartStyleValue<TextStyle>.inherit(),
    this.accentColor = const ChartStyleValue<Color>.inherit(),
    this.shadow = const ChartStyleValue<BoxShadow>.inherit(),
    this.minWidth = const ChartStyleValue<double>.inherit(),
    this.maxWidth = const ChartStyleValue<double>.inherit(),
    this.rowGap = const ChartStyleValue<double>.inherit(),
    this.labelValueGap = const ChartStyleValue<double>.inherit(),
  });

  /// Panel surface color. Cleared means a truly transparent surface.
  final ChartStyleValue<Color> backgroundColor;

  /// Opacity applied to the resolved background color, from 0 to 1.
  final ChartStyleValue<double> backgroundOpacity;

  /// Panel outline color. Cleared means no visible stroke.
  final ChartStyleValue<Color> borderColor;

  /// Panel outline width in logical pixels.
  final ChartStyleValue<double> borderWidth;

  /// Corner radius of the panel surface and outline.
  final ChartStyleValue<BorderRadius> borderRadius;

  /// Inner padding between the panel edge and its content.
  final ChartStyleValue<EdgeInsets> padding;

  /// Text style for row values and primary content.
  final ChartStyleValue<TextStyle> textStyle;

  /// Text style for row labels and secondary content.
  final ChartStyleValue<TextStyle> labelStyle;

  /// Color of the series accent mark. Cleared hides the accent color.
  final ChartStyleValue<Color> accentColor;

  /// Drop shadow behind the panel. Cleared means no shadow.
  final ChartStyleValue<BoxShadow> shadow;

  /// Minimum panel width in logical pixels.
  final ChartStyleValue<double> minWidth;

  /// Maximum panel width in logical pixels.
  final ChartStyleValue<double> maxWidth;

  /// Vertical gap between rows in logical pixels.
  final ChartStyleValue<double> rowGap;

  /// Horizontal gap between the row-label column and the value column, in
  /// logical pixels.
  ///
  /// Resolved to a value, rows pack: values left-align in a shared column
  /// that starts at the widest row label plus this gap, and the panel's
  /// intrinsic width tightens to labels + gap + widest value (still clamped
  /// by [minWidth] and [maxWidth], with long values still ellipsizing).
  /// Inherited (no theme preset sets a default) or cleared, rows spread:
  /// values right-align to the panel's content edge. Title, subtitle, and
  /// section-header rows are unaffected either way.
  final ChartStyleValue<double> labelValueGap;

  /// Creates a copy with the given fields replaced.
  ///
  /// Pass an explicit [ChartStyleValue.inherit] to restore theme inheritance
  /// for a field that was previously overridden or cleared.
  CartesianValueSummaryStyle copyWith({
    ChartStyleValue<Color>? backgroundColor,
    ChartStyleValue<double>? backgroundOpacity,
    ChartStyleValue<Color>? borderColor,
    ChartStyleValue<double>? borderWidth,
    ChartStyleValue<BorderRadius>? borderRadius,
    ChartStyleValue<EdgeInsets>? padding,
    ChartStyleValue<TextStyle>? textStyle,
    ChartStyleValue<TextStyle>? labelStyle,
    ChartStyleValue<Color>? accentColor,
    ChartStyleValue<BoxShadow>? shadow,
    ChartStyleValue<double>? minWidth,
    ChartStyleValue<double>? maxWidth,
    ChartStyleValue<double>? rowGap,
    ChartStyleValue<double>? labelValueGap,
  }) => CartesianValueSummaryStyle(
    backgroundColor: backgroundColor ?? this.backgroundColor,
    backgroundOpacity: backgroundOpacity ?? this.backgroundOpacity,
    borderColor: borderColor ?? this.borderColor,
    borderWidth: borderWidth ?? this.borderWidth,
    borderRadius: borderRadius ?? this.borderRadius,
    padding: padding ?? this.padding,
    textStyle: textStyle ?? this.textStyle,
    labelStyle: labelStyle ?? this.labelStyle,
    accentColor: accentColor ?? this.accentColor,
    shadow: shadow ?? this.shadow,
    minWidth: minWidth ?? this.minWidth,
    maxWidth: maxWidth ?? this.maxWidth,
    rowGap: rowGap ?? this.rowGap,
    labelValueGap: labelValueGap ?? this.labelValueGap,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CartesianValueSummaryStyle &&
          other.backgroundColor == backgroundColor &&
          other.backgroundOpacity == backgroundOpacity &&
          other.borderColor == borderColor &&
          other.borderWidth == borderWidth &&
          other.borderRadius == borderRadius &&
          other.padding == padding &&
          other.textStyle == textStyle &&
          other.labelStyle == labelStyle &&
          other.accentColor == accentColor &&
          other.shadow == shadow &&
          other.minWidth == minWidth &&
          other.maxWidth == maxWidth &&
          other.rowGap == rowGap &&
          other.labelValueGap == labelValueGap;

  @override
  int get hashCode => Object.hash(
    backgroundColor,
    backgroundOpacity,
    borderColor,
    borderWidth,
    borderRadius,
    padding,
    textStyle,
    labelStyle,
    accentColor,
    shadow,
    minWidth,
    maxWidth,
    rowGap,
    labelValueGap,
  );
}
