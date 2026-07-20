// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

/// Theme defaults for the Cartesian value summary panel.
///
/// `CartesianValueSummaryStyle` overrides resolve against these defaults:
/// an inherited field takes the value defined here, while an explicitly
/// cleared field stays cleared with no fallback to this theme. The fixed
/// overlay and the draggable annotation presentation resolve against the
/// same component, so both stay visually consistent.
///
/// The presets keep the panel legible in high contrast, at 200% text
/// scaling, and on dark plot backgrounds; text colors never rely on the
/// panel surface remaining opaque.
@immutable
class CartesianValueSummaryTheme {
  const CartesianValueSummaryTheme({
    required this.background,
    required this.backgroundOpacity,
    required this.border,
    required this.borderWidth,
    required this.borderRadius,
    required this.padding,
    required this.titleStyle,
    required this.labelStyle,
    required this.valueStyle,
    required this.accentSize,
    this.shadow,
    required this.minWidth,
    required this.maxWidth,
    required this.rowGap,
  });

  /// Panel surface color before [backgroundOpacity] is applied.
  final Color background;

  /// Opacity applied to [background], from 0 to 1.
  final double backgroundOpacity;

  /// Panel outline color.
  final Color border;

  /// Panel outline width in logical pixels.
  final double borderWidth;

  /// Corner radius of the panel surface and outline.
  final BorderRadius borderRadius;

  /// Inner padding between the panel edge and its content.
  final EdgeInsets padding;

  /// Text style for the panel title (series or section heading).
  final TextStyle titleStyle;

  /// Text style for row labels and secondary content.
  final TextStyle labelStyle;

  /// Text style for row values and primary content.
  final TextStyle valueStyle;

  /// Diameter of the series accent mark in logical pixels.
  final double accentSize;

  /// Drop shadow behind the panel, or null for no shadow.
  final BoxShadow? shadow;

  /// Minimum panel width in logical pixels.
  final double minWidth;

  /// Maximum panel width in logical pixels.
  final double maxWidth;

  /// Vertical gap between rows in logical pixels.
  final double rowGap;

  static const light = CartesianValueSummaryTheme(
    background: Color(0xFFFFFFFF),
    backgroundOpacity: 0.9,
    border: Color(0xFFBDBDBD),
    borderWidth: 1.0,
    borderRadius: BorderRadius.all(Radius.circular(4)),
    padding: EdgeInsets.all(8),
    titleStyle: TextStyle(
      color: Color(0xFF212121),
      fontSize: 12.0,
      fontWeight: FontWeight.w600,
    ),
    labelStyle: TextStyle(color: Color(0xFF616161), fontSize: 11.0),
    valueStyle: TextStyle(
      color: Color(0xFF212121),
      fontSize: 11.0,
      fontWeight: FontWeight.w500,
    ),
    accentSize: 8.0,
    shadow: BoxShadow(color: Color(0x33000000), blurRadius: 4.0),
    minWidth: 168.0,
    maxWidth: 280.0,
    rowGap: 4.0,
  );

  static const dark = CartesianValueSummaryTheme(
    background: Color(0xFF212121),
    backgroundOpacity: 0.9,
    border: Color(0xFF616161),
    borderWidth: 1.0,
    borderRadius: BorderRadius.all(Radius.circular(4)),
    padding: EdgeInsets.all(8),
    titleStyle: TextStyle(
      color: Color(0xFFFFFFFF),
      fontSize: 12.0,
      fontWeight: FontWeight.w600,
    ),
    labelStyle: TextStyle(color: Color(0xFFBDBDBD), fontSize: 11.0),
    valueStyle: TextStyle(
      color: Color(0xFFFFFFFF),
      fontSize: 11.0,
      fontWeight: FontWeight.w500,
    ),
    accentSize: 8.0,
    shadow: BoxShadow(color: Color(0x33000000), blurRadius: 4.0),
    minWidth: 168.0,
    maxWidth: 280.0,
    rowGap: 4.0,
  );

  /// Opaque black-on-white treatment with a heavy crisp outline and no
  /// soft shadow, sized up for legibility under text scaling.
  static const highContrast = CartesianValueSummaryTheme(
    background: Color(0xFF000000),
    backgroundOpacity: 1.0,
    border: Color(0xFFFFFFFF),
    borderWidth: 2.0,
    borderRadius: BorderRadius.zero,
    padding: EdgeInsets.all(10),
    titleStyle: TextStyle(
      color: Color(0xFFFFFFFF),
      fontSize: 14.0,
      fontWeight: FontWeight.bold,
    ),
    labelStyle: TextStyle(
      color: Color(0xFFFFFFFF),
      fontSize: 12.0,
      fontWeight: FontWeight.bold,
    ),
    valueStyle: TextStyle(
      color: Color(0xFFFFFFFF),
      fontSize: 12.0,
      fontWeight: FontWeight.bold,
    ),
    accentSize: 10.0,
    minWidth: 168.0,
    maxWidth: 280.0,
    rowGap: 6.0,
  );

  /// Neutral surface with an Okabe-Ito blue border so the panel never
  /// relies on red/green discrimination.
  static const colorblindFriendly = CartesianValueSummaryTheme(
    background: Color(0xFFFFFFFF),
    backgroundOpacity: 0.94,
    border: Color(0xFF0173B2),
    borderWidth: 1.0,
    borderRadius: BorderRadius.all(Radius.circular(4)),
    padding: EdgeInsets.all(8),
    titleStyle: TextStyle(
      color: Color(0xFF000000),
      fontSize: 12.0,
      fontWeight: FontWeight.w600,
    ),
    labelStyle: TextStyle(color: Color(0xFF374151), fontSize: 11.0),
    valueStyle: TextStyle(
      color: Color(0xFF000000),
      fontSize: 11.0,
      fontWeight: FontWeight.w500,
    ),
    accentSize: 8.0,
    shadow: BoxShadow(color: Color(0x33000000), blurRadius: 4.0),
    minWidth: 168.0,
    maxWidth: 280.0,
    rowGap: 4.0,
  );

  /// Linearly interpolates between two summary themes.
  ///
  /// All fields interpolate continuously; a null [shadow] endpoint fades
  /// the shadow in or out rather than popping. Values of [t] at or below 0
  /// return [a] exactly and values at or above 1 return [b] exactly, so
  /// endpoint themes keep their identity (including a null [shadow]).
  static CartesianValueSummaryTheme lerp(
    CartesianValueSummaryTheme a,
    CartesianValueSummaryTheme b,
    double t,
  ) {
    if (identical(a, b) || t <= 0.0) {
      return a;
    }
    if (t >= 1.0) {
      return b;
    }
    return CartesianValueSummaryTheme(
      background: Color.lerp(a.background, b.background, t)!,
      backgroundOpacity: lerpDouble(a.backgroundOpacity, b.backgroundOpacity, t)!,
      border: Color.lerp(a.border, b.border, t)!,
      borderWidth: lerpDouble(a.borderWidth, b.borderWidth, t)!,
      borderRadius: BorderRadius.lerp(a.borderRadius, b.borderRadius, t)!,
      padding: EdgeInsets.lerp(a.padding, b.padding, t)!,
      titleStyle: TextStyle.lerp(a.titleStyle, b.titleStyle, t)!,
      labelStyle: TextStyle.lerp(a.labelStyle, b.labelStyle, t)!,
      valueStyle: TextStyle.lerp(a.valueStyle, b.valueStyle, t)!,
      accentSize: lerpDouble(a.accentSize, b.accentSize, t)!,
      shadow: BoxShadow.lerp(a.shadow, b.shadow, t),
      minWidth: lerpDouble(a.minWidth, b.minWidth, t)!,
      maxWidth: lerpDouble(a.maxWidth, b.maxWidth, t)!,
      rowGap: lerpDouble(a.rowGap, b.rowGap, t)!,
    );
  }

  CartesianValueSummaryTheme copyWith({
    Color? background,
    double? backgroundOpacity,
    Color? border,
    double? borderWidth,
    BorderRadius? borderRadius,
    EdgeInsets? padding,
    TextStyle? titleStyle,
    TextStyle? labelStyle,
    TextStyle? valueStyle,
    double? accentSize,
    BoxShadow? shadow,
    double? minWidth,
    double? maxWidth,
    double? rowGap,
  }) => CartesianValueSummaryTheme(
    background: background ?? this.background,
    backgroundOpacity: backgroundOpacity ?? this.backgroundOpacity,
    border: border ?? this.border,
    borderWidth: borderWidth ?? this.borderWidth,
    borderRadius: borderRadius ?? this.borderRadius,
    padding: padding ?? this.padding,
    titleStyle: titleStyle ?? this.titleStyle,
    labelStyle: labelStyle ?? this.labelStyle,
    valueStyle: valueStyle ?? this.valueStyle,
    accentSize: accentSize ?? this.accentSize,
    shadow: shadow ?? this.shadow,
    minWidth: minWidth ?? this.minWidth,
    maxWidth: maxWidth ?? this.maxWidth,
    rowGap: rowGap ?? this.rowGap,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CartesianValueSummaryTheme &&
          other.background == background &&
          other.backgroundOpacity == backgroundOpacity &&
          other.border == border &&
          other.borderWidth == borderWidth &&
          other.borderRadius == borderRadius &&
          other.padding == padding &&
          other.titleStyle == titleStyle &&
          other.labelStyle == labelStyle &&
          other.valueStyle == valueStyle &&
          other.accentSize == accentSize &&
          other.shadow == shadow &&
          other.minWidth == minWidth &&
          other.maxWidth == maxWidth &&
          other.rowGap == rowGap;

  @override
  int get hashCode => Object.hashAll([
    background,
    backgroundOpacity,
    border,
    borderWidth,
    borderRadius,
    padding,
    titleStyle,
    labelStyle,
    valueStyle,
    accentSize,
    shadow,
    minWidth,
    maxWidth,
    rowGap,
  ]);
}
