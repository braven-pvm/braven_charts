// Copyright (c) 2025 braven_charts. All rights reserved.
// Annotation Style Configuration for BravenChartPlus

import 'package:flutter/material.dart';

/// Immutable annotation style configuration.
///
/// Defines the visual styling for chart annotations including text style,
/// colors, borders, and padding.
@immutable
class AnnotationStyle {
  /// Creates an annotation style.
  const AnnotationStyle({
    this.textStyle = const TextStyle(
      fontSize: 12.0,
      fontWeight: FontWeight.normal,
      color: Colors.black,
    ),
    this.backgroundColor,
    this.borderColor,
    this.borderWidth = 1.0,
    this.borderRadius,
    this.padding,
  });

  /// Text style for annotation labels.
  ///
  /// Supports full typography control including font size, weight, style,
  /// family, color, letter spacing, and decoration.
  ///
  /// Default: `TextStyle(fontSize: 12, fontWeight: FontWeight.normal, color: Colors.black)`
  final TextStyle textStyle;

  /// Background color for annotation containers (optional).
  final Color? backgroundColor;

  /// Border color for annotation outlines (optional).
  final Color? borderColor;

  /// Border width in logical pixels.
  final double borderWidth;

  /// Border radius for rounded corners.
  ///
  /// If null, defaults to `BorderRadius.circular(4)`.
  /// Set to `BorderRadius.zero` for sharp corners.
  final BorderRadius? borderRadius;

  /// Padding inside annotation containers.
  ///
  /// If null, defaults to `EdgeInsets.symmetric(horizontal: 6, vertical: 3)`.
  final EdgeInsets? padding;

  /// Font size extracted from textStyle for convenience.
  double get fontSize => textStyle.fontSize ?? 12.0;

  /// Font weight extracted from textStyle for convenience.
  FontWeight get fontWeight => textStyle.fontWeight ?? FontWeight.normal;

  /// Text color extracted from textStyle for convenience.
  Color get textColor => textStyle.color ?? Colors.black;

  /// Creates a copy with modified properties.
  AnnotationStyle copyWith({
    TextStyle? textStyle,
    Color? backgroundColor,
    Color? borderColor,
    double? borderWidth,
    BorderRadius? borderRadius,
    EdgeInsets? padding,
  }) {
    return AnnotationStyle(
      textStyle: textStyle ?? this.textStyle,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      borderColor: borderColor ?? this.borderColor,
      borderWidth: borderWidth ?? this.borderWidth,
      borderRadius: borderRadius ?? this.borderRadius,
      padding: padding ?? this.padding,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AnnotationStyle &&
        other.textStyle == textStyle &&
        other.backgroundColor == backgroundColor &&
        other.borderColor == borderColor &&
        other.borderWidth == borderWidth &&
        other.borderRadius == borderRadius &&
        other.padding == padding;
  }

  @override
  int get hashCode {
    return Object.hash(
      textStyle,
      backgroundColor,
      borderColor,
      borderWidth,
      borderRadius,
      padding,
    );
  }
}
