import 'package:flutter/material.dart';

/// Immutable annotation style configuration
/// 
/// Defines the visual styling for chart annotations.
@immutable
class AnnotationStyle {
  /// Creates an annotation style
  const AnnotationStyle({
    this.fontSize = 12.0,
    this.fontWeight = FontWeight.normal,
    this.textColor = Colors.black,
    this.backgroundColor,
    this.borderColor,
    this.borderWidth = 1.0,
  });

  /// Font size for annotation text
  final double fontSize;

  /// Font weight for annotation text
  final FontWeight fontWeight;

  /// Text color
  final Color textColor;

  /// Background color (optional)
  final Color? backgroundColor;

  /// Border color (optional)
  final Color? borderColor;

  /// Border width
  final double borderWidth;

  /// Creates a copy with modified properties
  AnnotationStyle copyWith({
    double? fontSize,
    FontWeight? fontWeight,
    Color? textColor,
    Color? backgroundColor,
    Color? borderColor,
    double? borderWidth,
  }) {
    return AnnotationStyle(
      fontSize: fontSize ?? this.fontSize,
      fontWeight: fontWeight ?? this.fontWeight,
      textColor: textColor ?? this.textColor,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      borderColor: borderColor ?? this.borderColor,
      borderWidth: borderWidth ?? this.borderWidth,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AnnotationStyle &&
        other.fontSize == fontSize &&
        other.fontWeight == fontWeight &&
        other.textColor == textColor &&
        other.backgroundColor == backgroundColor &&
        other.borderColor == borderColor &&
        other.borderWidth == borderWidth;
  }

  @override
  int get hashCode {
    return Object.hash(
      fontSize,
      fontWeight,
      textColor,
      backgroundColor,
      borderColor,
      borderWidth,
    );
  }
}
