// Copyright (c) 2025 Braven Charts
// Licensed under the MIT License

import 'package:flutter/material.dart';

/// Reusable styling for labels across all chart components.
///
/// This style is used for:
/// - Crosshair coordinate labels (X/Y values at chart edges)
/// - Tooltip labels (data point details)
/// - Annotation labels (range, threshold, trend labels)
/// - Axis tick labels
/// - Any other labeled UI elements
///
/// Example:
/// ```dart
/// final labelStyle = LabelStyle(
///   textStyle: TextStyle(color: Colors.black, fontSize: 12),
///   backgroundColor: Colors.white,
///   borderColor: Colors.grey,
///   borderWidth: 1.0,
///   borderRadius: 4.0,
///   padding: EdgeInsets.all(8.0),
/// );
/// ```
class LabelStyle {
  /// Creates a LabelStyle from JSON.
  factory LabelStyle.fromJson(Map<String, dynamic> json) {
    return LabelStyle(
      textStyle: _parseTextStyle(json['textStyle'] as Map<String, dynamic>),
      backgroundColor: _parseColor(json['backgroundColor'] as String),
      borderColor: _parseColor(json['borderColor'] as String),
      borderWidth: (json['borderWidth'] as num).toDouble(),
      borderRadius: (json['borderRadius'] as num).toDouble(),
      padding: _parsePadding(json['padding'] as Map<String, dynamic>),
      shadowColor: json['shadowColor'] != null
          ? _parseColor(json['shadowColor'] as String)
          : null,
      shadowBlurRadius: json['shadowBlurRadius'] != null
          ? (json['shadowBlurRadius'] as num).toDouble()
          : null,
    );
  }
  const LabelStyle({
    required this.textStyle,
    required this.backgroundColor,
    required this.borderColor,
    required this.borderWidth,
    required this.borderRadius,
    required this.padding,
    this.shadowColor,
    this.shadowBlurRadius,
  }) : assert(borderWidth >= 0, 'borderWidth must be >= 0'),
       assert(borderRadius >= 0, 'borderRadius must be >= 0');

  /// Text style for the label content.
  final TextStyle textStyle;

  /// Background color of the label box.
  final Color backgroundColor;

  /// Border color of the label box.
  final Color borderColor;

  /// Width of the border in pixels. Must be >= 0.
  final double borderWidth;

  /// Radius of the border corners in pixels. Must be >= 0.
  final double borderRadius;

  /// Padding inside the label box.
  final EdgeInsets padding;

  /// Optional shadow color. Null means no shadow.
  final Color? shadowColor;

  /// Optional shadow blur radius. Null means no shadow.
  final double? shadowBlurRadius;

  /// Creates a copy with the specified fields replaced.
  LabelStyle copyWith({
    TextStyle? textStyle,
    Color? backgroundColor,
    Color? borderColor,
    double? borderWidth,
    double? borderRadius,
    EdgeInsets? padding,
    Color? shadowColor,
    double? shadowBlurRadius,
  }) {
    return LabelStyle(
      textStyle: textStyle ?? this.textStyle,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      borderColor: borderColor ?? this.borderColor,
      borderWidth: borderWidth ?? this.borderWidth,
      borderRadius: borderRadius ?? this.borderRadius,
      padding: padding ?? this.padding,
      shadowColor: shadowColor ?? this.shadowColor,
      shadowBlurRadius: shadowBlurRadius ?? this.shadowBlurRadius,
    );
  }

  /// Converts this style to JSON.
  Map<String, dynamic> toJson() {
    return {
      'textStyle': _textStyleToJson(textStyle),
      'backgroundColor':
          '#${backgroundColor.value.toRadixString(16).padLeft(8, '0')}',
      'borderColor': '#${borderColor.value.toRadixString(16).padLeft(8, '0')}',
      'borderWidth': borderWidth,
      'borderRadius': borderRadius,
      'padding': _paddingToJson(padding),
      if (shadowColor != null)
        'shadowColor':
            '#${shadowColor!.value.toRadixString(16).padLeft(8, '0')}',
      if (shadowBlurRadius != null) 'shadowBlurRadius': shadowBlurRadius,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LabelStyle &&
        textStyle == other.textStyle &&
        backgroundColor == other.backgroundColor &&
        borderColor == other.borderColor &&
        borderWidth == other.borderWidth &&
        borderRadius == other.borderRadius &&
        padding == other.padding &&
        shadowColor == other.shadowColor &&
        shadowBlurRadius == other.shadowBlurRadius;
  }

  @override
  int get hashCode => Object.hash(
    textStyle,
    backgroundColor,
    borderColor,
    borderWidth,
    borderRadius,
    padding,
    shadowColor,
    shadowBlurRadius,
  );

  // ========== Helper Methods ==========

  static Color _parseColor(String hex) {
    final hexValue = hex.replaceFirst('#', '');
    return Color(int.parse(hexValue, radix: 16));
  }

  static TextStyle _parseTextStyle(Map<String, dynamic> json) {
    return TextStyle(
      color: json['color'] != null
          ? _parseColor(json['color'] as String)
          : null,
      fontSize: json['fontSize'] != null
          ? (json['fontSize'] as num).toDouble()
          : null,
      fontWeight: json['fontWeight'] != null
          ? FontWeight.values[json['fontWeight'] as int]
          : null,
      fontFamily: json['fontFamily'] as String?,
    );
  }

  static Map<String, dynamic> _textStyleToJson(TextStyle style) {
    return {
      if (style.color != null)
        'color': '#${style.color!.value.toRadixString(16).padLeft(8, '0')}',
      if (style.fontSize != null) 'fontSize': style.fontSize,
      if (style.fontWeight != null) 'fontWeight': style.fontWeight!.index,
      if (style.fontFamily != null) 'fontFamily': style.fontFamily,
    };
  }

  static EdgeInsets _parsePadding(Map<String, dynamic> json) {
    if (json.containsKey('all')) {
      return EdgeInsets.all((json['all'] as num).toDouble());
    }
    return EdgeInsets.only(
      left: (json['left'] as num?)?.toDouble() ?? 0,
      top: (json['top'] as num?)?.toDouble() ?? 0,
      right: (json['right'] as num?)?.toDouble() ?? 0,
      bottom: (json['bottom'] as num?)?.toDouble() ?? 0,
    );
  }

  static Map<String, dynamic> _paddingToJson(EdgeInsets padding) {
    if (padding.left == padding.top &&
        padding.top == padding.right &&
        padding.right == padding.bottom) {
      return {'all': padding.left};
    }
    return {
      'left': padding.left,
      'top': padding.top,
      'right': padding.right,
      'bottom': padding.bottom,
    };
  }
}
