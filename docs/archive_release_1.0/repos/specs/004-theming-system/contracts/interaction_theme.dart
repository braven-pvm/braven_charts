// CONTRACT: InteractionTheme
// Feature: 004-theming-system
//
// Defines styling for interactive chart elements (crosshair, tooltips, selection).

import 'package:flutter/material.dart';

/// Styling for interactive chart elements.
///
/// Includes crosshair (mouse tracking), tooltips (data display),
/// and selection highlights.
///
/// Example:
/// ```dart
/// final interactionTheme = InteractionTheme(
///   crosshairColor: Colors.grey,
///   crosshairWidth: 1.0,
///   crosshairDashPattern: [5.0, 5.0],
///   tooltipBackground: Colors.white,
///   tooltipTextStyle: TextStyle(fontSize: 12, color: Colors.black),
///   tooltipBorderColor: Colors.grey,
///   tooltipBorderWidth: 1.0,
///   selectionColor: Colors.blue,
///   selectionOpacity: 0.2,
/// );
/// ```
class InteractionTheme {
  const InteractionTheme({
    required this.crosshairColor,
    required this.crosshairWidth,
    this.crosshairDashPattern,
    required this.tooltipBackground,
    required this.tooltipTextStyle,
    required this.tooltipBorderColor,
    required this.tooltipBorderWidth,
    required this.selectionColor,
    required this.selectionOpacity,
  })  : assert(crosshairWidth >= 0.0, 'crosshairWidth must be >= 0'),
        assert(tooltipBorderWidth >= 0.0, 'tooltipBorderWidth must be >= 0'),
        assert(selectionOpacity >= 0.0 && selectionOpacity <= 1.0,
            'selectionOpacity must be 0.0-1.0');

  /// Color of crosshair lines.
  final Color crosshairColor;

  /// Width of crosshair lines in pixels. Use 0.0 for no crosshair.
  final double crosshairWidth;

  /// Dash pattern for crosshair. Null = solid line.
  final List<double>? crosshairDashPattern;

  /// Background color of tooltip.
  final Color tooltipBackground;

  /// Text style for tooltip content.
  final TextStyle tooltipTextStyle;

  /// Border color of tooltip.
  final Color tooltipBorderColor;

  /// Border width of tooltip in pixels. Use 0.0 for no border.
  final double tooltipBorderWidth;

  /// Color of selection highlight (data range or point selection).
  final Color selectionColor;

  /// Opacity of selection highlight (0.0 = transparent, 1.0 = opaque).
  final double selectionOpacity;

  // ========== Predefined Themes ==========

  static const InteractionTheme defaultLight = InteractionTheme(
    crosshairColor: Color(0xFF757575),
    crosshairWidth: 1.0,
    crosshairDashPattern: [5.0, 5.0],
    tooltipBackground: Color(0xFFFFFFFF),
    tooltipTextStyle: TextStyle(
        fontSize: 12.0, fontFamily: 'Roboto', color: Color(0xFF000000)),
    tooltipBorderColor: Color(0xFF757575),
    tooltipBorderWidth: 1.0,
    selectionColor: Color(0xFF1976D2),
    selectionOpacity: 0.2,
  );

  static const InteractionTheme defaultDark = InteractionTheme(
    crosshairColor: Color(0xFFBDBDBD),
    crosshairWidth: 1.0,
    crosshairDashPattern: [5.0, 5.0],
    tooltipBackground: Color(0xFF424242),
    tooltipTextStyle: TextStyle(
        fontSize: 12.0, fontFamily: 'Roboto', color: Color(0xFFFFFFFF)),
    tooltipBorderColor: Color(0xFF757575),
    tooltipBorderWidth: 1.0,
    selectionColor: Color(0xFF42A5F5),
    selectionOpacity: 0.3,
  );

  static const InteractionTheme corporateBlue = InteractionTheme(
    crosshairColor: Color(0xFF546E7A),
    crosshairWidth: 1.0,
    crosshairDashPattern: [5.0, 5.0],
    tooltipBackground: Color(0xFFFAFAFA),
    tooltipTextStyle: TextStyle(
        fontSize: 12.0, fontFamily: 'Roboto', color: Color(0xFF37474F)),
    tooltipBorderColor: Color(0xFF1976D2),
    tooltipBorderWidth: 2.0,
    selectionColor: Color(0xFF1976D2),
    selectionOpacity: 0.15,
  );

  static const InteractionTheme vibrant = InteractionTheme(
    crosshairColor: Color(0xFF000000),
    crosshairWidth: 1.5,
    crosshairDashPattern: [8.0, 4.0],
    tooltipBackground: Color(0xFFFFFFFF),
    tooltipTextStyle: TextStyle(
        fontSize: 13.0,
        fontFamily: 'Roboto',
        fontWeight: FontWeight.w500,
        color: Color(0xFF000000)),
    tooltipBorderColor: Color(0xFFE91E63),
    tooltipBorderWidth: 2.0,
    selectionColor: Color(0xFFE91E63),
    selectionOpacity: 0.25,
  );

  static const InteractionTheme minimal = InteractionTheme(
    crosshairColor: Color(0xFFBDBDBD),
    crosshairWidth: 0.5,
    crosshairDashPattern: [5.0, 5.0],
    tooltipBackground: Color(0xFFFAFAFA),
    tooltipTextStyle: TextStyle(
        fontSize: 11.0, fontFamily: 'Roboto', color: Color(0xFF616161)),
    tooltipBorderColor: Color(0xFFE0E0E0),
    tooltipBorderWidth: 0.5,
    selectionColor: Color(0xFF9E9E9E),
    selectionOpacity: 0.15,
  );

  static const InteractionTheme highContrast = InteractionTheme(
    crosshairColor: Color(0xFF000000),
    crosshairWidth: 2.0,
    crosshairDashPattern: null, // Solid for max visibility
    tooltipBackground: Color(0xFFFFFFFF),
    tooltipTextStyle: TextStyle(
        fontSize: 14.0,
        fontFamily: 'Roboto',
        fontWeight: FontWeight.w600,
        color: Color(0xFF000000)),
    tooltipBorderColor: Color(0xFF000000),
    tooltipBorderWidth: 2.0,
    selectionColor: Color(0xFF000000),
    selectionOpacity: 0.3,
  );

  static const InteractionTheme colorblindFriendly = InteractionTheme(
    crosshairColor: Color(0xFF000000),
    crosshairWidth: 1.5,
    crosshairDashPattern: [6.0, 4.0],
    tooltipBackground: Color(0xFFFFFFFF),
    tooltipTextStyle: TextStyle(
        fontSize: 12.0,
        fontFamily: 'Roboto',
        fontWeight: FontWeight.w500,
        color: Color(0xFF000000)),
    tooltipBorderColor: Color(0xFF0173B2), // Blue from colorblind-safe palette
    tooltipBorderWidth: 1.5,
    selectionColor: Color(0xFF0173B2),
    selectionOpacity: 0.2,
  );

  // ========== Customization ==========

  InteractionTheme copyWith({
    Color? crosshairColor,
    double? crosshairWidth,
    List<double>? crosshairDashPattern,
    Color? tooltipBackground,
    TextStyle? tooltipTextStyle,
    Color? tooltipBorderColor,
    double? tooltipBorderWidth,
    Color? selectionColor,
    double? selectionOpacity,
  }) {
    return InteractionTheme(
      crosshairColor: crosshairColor ?? this.crosshairColor,
      crosshairWidth: crosshairWidth ?? this.crosshairWidth,
      crosshairDashPattern: crosshairDashPattern ?? this.crosshairDashPattern,
      tooltipBackground: tooltipBackground ?? this.tooltipBackground,
      tooltipTextStyle: tooltipTextStyle ?? this.tooltipTextStyle,
      tooltipBorderColor: tooltipBorderColor ?? this.tooltipBorderColor,
      tooltipBorderWidth: tooltipBorderWidth ?? this.tooltipBorderWidth,
      selectionColor: selectionColor ?? this.selectionColor,
      selectionOpacity: selectionOpacity ?? this.selectionOpacity,
    );
  }

  // ========== Serialization ==========

  Map<String, dynamic> toJson() {
    return {
      'crosshairColor':
          '#${crosshairColor.value.toRadixString(16).padLeft(8, '0')}',
      'crosshairWidth': crosshairWidth,
      'crosshairDashPattern': crosshairDashPattern,
      'tooltipBackground':
          '#${tooltipBackground.value.toRadixString(16).padLeft(8, '0')}',
      'tooltipTextStyle': {
        'fontSize': tooltipTextStyle.fontSize,
        'fontFamily': tooltipTextStyle.fontFamily,
        'color': tooltipTextStyle.color != null
            ? '#${tooltipTextStyle.color!.value.toRadixString(16).padLeft(8, '0')}'
            : null,
        'fontWeight': tooltipTextStyle.fontWeight?.toString(),
      },
      'tooltipBorderColor':
          '#${tooltipBorderColor.value.toRadixString(16).padLeft(8, '0')}',
      'tooltipBorderWidth': tooltipBorderWidth,
      'selectionColor':
          '#${selectionColor.value.toRadixString(16).padLeft(8, '0')}',
      'selectionOpacity': selectionOpacity,
    };
  }

  static InteractionTheme fromJson(Map<String, dynamic> json) {
    return InteractionTheme(
      crosshairColor:
          _parseColor(json['crosshairColor']) ?? defaultLight.crosshairColor,
      crosshairWidth: (json['crosshairWidth'] as num?)?.toDouble() ??
          defaultLight.crosshairWidth,
      crosshairDashPattern: (json['crosshairDashPattern'] as List<dynamic>?)
          ?.map((e) => (e as num).toDouble())
          .toList(),
      tooltipBackground: _parseColor(json['tooltipBackground']) ??
          defaultLight.tooltipBackground,
      tooltipTextStyle: _parseTextStyle(json['tooltipTextStyle']) ??
          defaultLight.tooltipTextStyle,
      tooltipBorderColor: _parseColor(json['tooltipBorderColor']) ??
          defaultLight.tooltipBorderColor,
      tooltipBorderWidth: (json['tooltipBorderWidth'] as num?)?.toDouble() ??
          defaultLight.tooltipBorderWidth,
      selectionColor:
          _parseColor(json['selectionColor']) ?? defaultLight.selectionColor,
      selectionOpacity: (json['selectionOpacity'] as num?)?.toDouble() ??
          defaultLight.selectionOpacity,
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
    return other is InteractionTheme &&
        other.crosshairColor == crosshairColor &&
        other.crosshairWidth == crosshairWidth &&
        _listEquals(other.crosshairDashPattern, crosshairDashPattern) &&
        other.tooltipBackground == tooltipBackground &&
        other.tooltipTextStyle == tooltipTextStyle &&
        other.tooltipBorderColor == tooltipBorderColor &&
        other.tooltipBorderWidth == tooltipBorderWidth &&
        other.selectionColor == selectionColor &&
        other.selectionOpacity == selectionOpacity;
  }

  @override
  int get hashCode => Object.hash(
        crosshairColor,
        crosshairWidth,
        Object.hashAll(crosshairDashPattern ?? []),
        tooltipBackground,
        tooltipTextStyle,
        tooltipBorderColor,
        tooltipBorderWidth,
        selectionColor,
        selectionOpacity,
      );

  bool _listEquals(List<double>? a, List<double>? b) {
    if (a == null && b == null) return true;
    if (a == null || b == null) return false;
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
