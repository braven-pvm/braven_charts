import 'package:flutter/material.dart';

/// Immutable annotation style configuration
///
/// Defines the visual styling for chart annotations.
@immutable
class AnnotationStyle {
  /// Creates an annotation style
  const AnnotationStyle({
    this.textStyle = const TextStyle(fontSize: 12.0, fontWeight: FontWeight.normal, color: Colors.black),
    this.backgroundColor,
    this.borderColor,
    this.borderWidth = 1.0,
    this.borderRadius,
    this.padding,
  });

  /// Text style for annotation labels.
  ///
  /// Supports full typography control including:
  /// - fontSize, fontWeight, fontStyle
  /// - fontFamily, fontFamilyFallback
  /// - color, backgroundColor
  /// - letterSpacing, wordSpacing, height
  /// - decoration, decorationColor, decorationStyle
  ///
  /// Default: `TextStyle(fontSize: 12, fontWeight: FontWeight.normal, color: Colors.black)`
  ///
  /// Example:
  /// ```dart
  /// AnnotationStyle(
  ///   textStyle: TextStyle(
  ///     fontFamily: 'Roboto Mono',
  ///     fontSize: 14,
  ///     fontWeight: FontWeight.bold,
  ///     color: Colors.blue,
  ///     letterSpacing: 1.2,
  ///   ),
  /// )
  /// ```
  final TextStyle textStyle;

  /// Background color (optional)
  final Color? backgroundColor;

  /// Border color (optional)
  final Color? borderColor;

  /// Border width
  final double borderWidth;

  /// Border radius for annotation containers.
  ///
  /// If null, defaults to `BorderRadius.circular(4)`.
  /// Set to `BorderRadius.zero` for sharp corners.
  ///
  /// Example:
  /// ```dart
  /// AnnotationStyle(
  ///   borderRadius: BorderRadius.circular(8), // Rounded corners
  /// )
  /// ```
  final BorderRadius? borderRadius;

  /// Padding for text inside annotation containers.
  ///
  /// If null, defaults to `EdgeInsets.symmetric(horizontal: 6, vertical: 3)`.
  ///
  /// Example:
  /// ```dart
  /// AnnotationStyle(
  ///   padding: EdgeInsets.all(8), // Equal padding on all sides
  /// )
  /// ```
  final EdgeInsets? padding;

  // Convenience getters for backward compatibility during migration
  /// Font size extracted from textStyle
  double get fontSize => textStyle.fontSize ?? 12.0;

  /// Font weight extracted from textStyle
  FontWeight get fontWeight => textStyle.fontWeight ?? FontWeight.normal;

  /// Text color extracted from textStyle
  Color get textColor => textStyle.color ?? Colors.black;

  /// Creates a copy with modified properties
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
