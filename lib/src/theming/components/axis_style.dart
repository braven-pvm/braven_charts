// AxisStyle Implementation
// Feature: 004-theming-system
// Phase 1: Core Data Structures (T010)

import 'package:flutter/material.dart';

/// Styling for chart axes (X and Y).
///
/// Includes line styling, text styling for labels and titles, and tick mark configuration.
///
/// Example:
/// ```dart
/// final axisStyle = AxisStyle(
///   lineColor: Colors.black,
///   lineWidth: 2.0,
///   labelStyle: TextStyle(fontSize: 12, color: Colors.black87),
///   titleStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
///   showTicks: true,
///   tickLength: 6.0,
///   tickColor: Colors.black,
///   tickWidth: 1.0,
/// );
/// ```
class AxisStyle {
  const AxisStyle({
    required this.lineColor,
    required this.lineWidth,
    required this.labelStyle,
    required this.titleStyle,
    required this.showTicks,
    required this.tickLength,
    required this.tickColor,
    required this.tickWidth,
  })  : assert(lineWidth >= 0.0, 'lineWidth must be >= 0'),
        assert(tickLength >= 0.0, 'tickLength must be >= 0'),
        assert(tickWidth >= 0.0, 'tickWidth must be >= 0');

  /// Color of the axis line.
  final Color lineColor;

  /// Width of the axis line in pixels. Use 0.0 for no axis line.
  final double lineWidth;

  /// Text style for axis labels (tick values).
  final TextStyle labelStyle;

  /// Text style for axis title.
  final TextStyle titleStyle;

  /// Whether to show tick marks.
  final bool showTicks;

  /// Length of tick marks in pixels. Use 0.0 for no tick marks.
  final double tickLength;

  /// Color of tick marks.
  final Color tickColor;

  /// Width of tick marks in pixels.
  final double tickWidth;

  // ========== Predefined Styles ==========

  static const AxisStyle defaultLight = AxisStyle(
    lineColor: Color(0xFF000000),
    lineWidth: 1.0,
    labelStyle: TextStyle(
        fontSize: 12.0, fontFamily: 'Roboto', color: Color(0xFF000000)),
    titleStyle: TextStyle(
        fontSize: 14.0,
        fontFamily: 'Roboto',
        fontWeight: FontWeight.w500,
        color: Color(0xFF000000)),
    showTicks: true,
    tickLength: 6.0,
    tickColor: Color(0xFF000000),
    tickWidth: 1.0,
  );

  static const AxisStyle defaultDark = AxisStyle(
    lineColor: Color(0xFFFFFFFF),
    lineWidth: 1.0,
    labelStyle: TextStyle(
        fontSize: 12.0, fontFamily: 'Roboto', color: Color(0xFFFFFFFF)),
    titleStyle: TextStyle(
        fontSize: 14.0,
        fontFamily: 'Roboto',
        fontWeight: FontWeight.w500,
        color: Color(0xFFFFFFFF)),
    showTicks: true,
    tickLength: 6.0,
    tickColor: Color(0xFFFFFFFF),
    tickWidth: 1.0,
  );

  static const AxisStyle corporateBlue = AxisStyle(
    lineColor: Color(0xFF37474F),
    lineWidth: 1.0,
    labelStyle: TextStyle(
        fontSize: 12.0, fontFamily: 'Roboto', color: Color(0xFF37474F)),
    titleStyle: TextStyle(
        fontSize: 14.0,
        fontFamily: 'Roboto',
        fontWeight: FontWeight.w600,
        color: Color(0xFF1976D2)),
    showTicks: true,
    tickLength: 6.0,
    tickColor: Color(0xFF37474F),
    tickWidth: 1.0,
  );

  static const AxisStyle vibrant = AxisStyle(
    lineColor: Color(0xFF000000),
    lineWidth: 2.0,
    labelStyle: TextStyle(
        fontSize: 13.0,
        fontFamily: 'Roboto',
        fontWeight: FontWeight.w500,
        color: Color(0xFF000000)),
    titleStyle: TextStyle(
        fontSize: 16.0,
        fontFamily: 'Roboto',
        fontWeight: FontWeight.bold,
        color: Color(0xFF000000)),
    showTicks: true,
    tickLength: 8.0,
    tickColor: Color(0xFF000000),
    tickWidth: 1.5,
  );

  static const AxisStyle minimal = AxisStyle(
    lineColor: Color(0xFF9E9E9E),
    lineWidth: 0.5,
    labelStyle: TextStyle(
        fontSize: 11.0, fontFamily: 'Roboto', color: Color(0xFF616161)),
    titleStyle: TextStyle(
        fontSize: 12.0,
        fontFamily: 'Roboto',
        fontWeight: FontWeight.w400,
        color: Color(0xFF424242)),
    showTicks: true,
    tickLength: 4.0,
    tickColor: Color(0xFF9E9E9E),
    tickWidth: 0.5,
  );

  static const AxisStyle highContrast = AxisStyle(
    lineColor: Color(0xFF000000),
    lineWidth: 2.0,
    labelStyle: TextStyle(
        fontSize: 14.0,
        fontFamily: 'Roboto',
        fontWeight: FontWeight.w600,
        color: Color(0xFF000000)),
    titleStyle: TextStyle(
        fontSize: 16.0,
        fontFamily: 'Roboto',
        fontWeight: FontWeight.bold,
        color: Color(0xFF000000)),
    showTicks: true,
    tickLength: 8.0,
    tickColor: Color(0xFF000000),
    tickWidth: 2.0,
  );

  static const AxisStyle colorblindFriendly = AxisStyle(
    lineColor: Color(0xFF000000),
    lineWidth: 1.5,
    labelStyle: TextStyle(
        fontSize: 12.0,
        fontFamily: 'Roboto',
        fontWeight: FontWeight.w500,
        color: Color(0xFF000000)),
    titleStyle: TextStyle(
        fontSize: 14.0,
        fontFamily: 'Roboto',
        fontWeight: FontWeight.w600,
        color: Color(0xFF000000)),
    showTicks: true,
    tickLength: 6.0,
    tickColor: Color(0xFF000000),
    tickWidth: 1.0,
  );

  // ========== Customization ==========

  AxisStyle copyWith({
    Color? lineColor,
    double? lineWidth,
    TextStyle? labelStyle,
    TextStyle? titleStyle,
    bool? showTicks,
    double? tickLength,
    Color? tickColor,
    double? tickWidth,
  }) {
    return AxisStyle(
      lineColor: lineColor ?? this.lineColor,
      lineWidth: lineWidth ?? this.lineWidth,
      labelStyle: labelStyle ?? this.labelStyle,
      titleStyle: titleStyle ?? this.titleStyle,
      showTicks: showTicks ?? this.showTicks,
      tickLength: tickLength ?? this.tickLength,
      tickColor: tickColor ?? this.tickColor,
      tickWidth: tickWidth ?? this.tickWidth,
    );
  }

  // ========== Serialization ==========

  Map<String, dynamic> toJson() {
    return {
      'lineColor': '#${lineColor.value.toRadixString(16).padLeft(8, '0')}',
      'lineWidth': lineWidth,
      'labelStyle': {
        'fontSize': labelStyle.fontSize,
        'fontFamily': labelStyle.fontFamily,
        'color': labelStyle.color != null
            ? '#${labelStyle.color!.value.toRadixString(16).padLeft(8, '0')}'
            : null,
        'fontWeight': labelStyle.fontWeight?.toString(),
      },
      'titleStyle': {
        'fontSize': titleStyle.fontSize,
        'fontFamily': titleStyle.fontFamily,
        'color': titleStyle.color != null
            ? '#${titleStyle.color!.value.toRadixString(16).padLeft(8, '0')}'
            : null,
        'fontWeight': titleStyle.fontWeight?.toString(),
      },
      'showTicks': showTicks,
      'tickLength': tickLength,
      'tickColor': '#${tickColor.value.toRadixString(16).padLeft(8, '0')}',
      'tickWidth': tickWidth,
    };
  }

  static AxisStyle fromJson(Map<String, dynamic> json) {
    return AxisStyle(
      lineColor: _parseColor(json['lineColor']) ?? defaultLight.lineColor,
      lineWidth:
          (json['lineWidth'] as num?)?.toDouble() ?? defaultLight.lineWidth,
      labelStyle:
          _parseTextStyle(json['labelStyle']) ?? defaultLight.labelStyle,
      titleStyle:
          _parseTextStyle(json['titleStyle']) ?? defaultLight.titleStyle,
      showTicks: json['showTicks'] as bool? ?? defaultLight.showTicks,
      tickLength:
          (json['tickLength'] as num?)?.toDouble() ?? defaultLight.tickLength,
      tickColor: _parseColor(json['tickColor']) ?? defaultLight.tickColor,
      tickWidth:
          (json['tickWidth'] as num?)?.toDouble() ?? defaultLight.tickWidth,
    );
  }

  static Color? _parseColor(dynamic value) {
    if (value is! String) return null;
    if (!value.startsWith('#')) return null;
    final hex = value.substring(1);
    if (hex.length != 8) return null;
    return Color(int.parse(hex, radix: 16));
  }

  static TextStyle? _parseTextStyle(dynamic value) {
    if (value is! Map<String, dynamic>) return null;
    return TextStyle(
      fontSize: (value['fontSize'] as num?)?.toDouble(),
      fontFamily: value['fontFamily'] as String?,
      color: _parseColor(value['color']),
      fontWeight: _parseFontWeight(value['fontWeight']),
    );
  }

  static FontWeight? _parseFontWeight(dynamic value) {
    if (value is! String) return null;
    if (value == 'FontWeight.w100') return FontWeight.w100;
    if (value == 'FontWeight.w200') return FontWeight.w200;
    if (value == 'FontWeight.w300') return FontWeight.w300;
    if (value == 'FontWeight.w400') return FontWeight.w400;
    if (value == 'FontWeight.w500') return FontWeight.w500;
    if (value == 'FontWeight.w600') return FontWeight.w600;
    if (value == 'FontWeight.w700') return FontWeight.w700;
    if (value == 'FontWeight.w800') return FontWeight.w800;
    if (value == 'FontWeight.w900') return FontWeight.w900;
    return null;
  }

  // ========== Equality ==========

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AxisStyle &&
        other.lineColor == lineColor &&
        other.lineWidth == lineWidth &&
        other.labelStyle == labelStyle &&
        other.titleStyle == titleStyle &&
        other.showTicks == showTicks &&
        other.tickLength == tickLength &&
        other.tickColor == tickColor &&
        other.tickWidth == tickWidth;
  }

  @override
  int get hashCode => Object.hash(
        lineColor,
        lineWidth,
        labelStyle,
        titleStyle,
        showTicks,
        tickLength,
        tickColor,
        tickWidth,
      );
}
