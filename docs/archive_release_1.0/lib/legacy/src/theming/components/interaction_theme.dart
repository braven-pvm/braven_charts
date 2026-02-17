// Copyright (c) 2025 Braven Charts
// Licensed under the MIT License

import 'package:flutter/material.dart';

/// Defines the visual styling for interactive elements in charts.
///
/// This theme controls the appearance of:
/// - Crosshair lines that follow the cursor
/// - Tooltips that display data point information
/// - Selection highlights for data points and regions
///
/// Example:
/// ```dart
/// final theme = InteractionTheme(
///   crosshairColor: Colors.grey,
///   crosshairWidth: 1.0,
///   crosshairDashPattern: [5.0, 3.0],
///   tooltipBackground: Colors.black87,
///   tooltipTextStyle: TextStyle(color: Colors.white, fontSize: 12.0),
///   selectionColor: Colors.blue.withOpacity(0.3),
/// );
/// ```
class InteractionTheme {
  // ========== Constructor ==========

  /// Creates an interaction theme with the specified styling.
  ///
  /// Validates that:
  /// - [crosshairWidth] >= 0
  InteractionTheme({
    required this.crosshairColor,
    required this.crosshairWidth,
    required this.crosshairDashPattern,
    required this.tooltipBackground,
    required this.tooltipTextStyle,
    required this.selectionColor,
  }) : assert(crosshairWidth >= 0, 'crosshairWidth must be >= 0');

  /// Creates a theme from a JSON map.
  factory InteractionTheme.fromJson(Map<String, dynamic> json) {
    return InteractionTheme(
      crosshairColor: _parseColor(json['crosshairColor'] as String),
      crosshairWidth: (json['crosshairWidth'] as num).toDouble(),
      crosshairDashPattern: (json['crosshairDashPattern'] as List)
          .map((e) => (e as num).toDouble())
          .toList(),
      tooltipBackground: _parseColor(json['tooltipBackground'] as String),
      tooltipTextStyle: _parseTextStyle(
        json['tooltipTextStyle'] as Map<String, dynamic>,
      ),
      selectionColor: _parseColor(json['selectionColor'] as String),
    );
  }
  // ========== Properties ==========

  /// Color of the crosshair lines.
  final Color crosshairColor;

  /// Width of the crosshair lines.
  /// Must be >= 0. A value of 0 hides the crosshair.
  final double crosshairWidth;

  /// Dash pattern for crosshair lines.
  /// Empty list means solid line. Non-empty list defines dash/gap pattern.
  final List<double> crosshairDashPattern;

  /// Background color for tooltips.
  final Color tooltipBackground;

  /// Text style for tooltip content.
  final TextStyle tooltipTextStyle;

  /// Color used for selection highlights.
  final Color selectionColor;

  // ========== Predefined Themes ==========

  static final InteractionTheme defaultLight = InteractionTheme(
    crosshairColor: const Color(0xFF757575), // Medium grey
    crosshairWidth: 1.0,
    crosshairDashPattern: const [5.0, 3.0],
    tooltipBackground: const Color(0xE6FFFFFF), // 90% white
    tooltipTextStyle: const TextStyle(
      color: Color(0xFF212121),
      fontSize: 12.0,
      fontWeight: FontWeight.normal,
    ),
    selectionColor: const Color(0x4D2196F3), // 30% blue
  );

  static final InteractionTheme defaultDark = InteractionTheme(
    crosshairColor: const Color(0xFFBDBDBD), // Light grey
    crosshairWidth: 1.0,
    crosshairDashPattern: const [5.0, 3.0],
    tooltipBackground: const Color(0xE6212121), // 90% dark grey
    tooltipTextStyle: const TextStyle(
      color: Color(0xFFFFFFFF),
      fontSize: 12.0,
      fontWeight: FontWeight.normal,
    ),
    selectionColor: const Color(0x4D64B5F6), // 30% light blue
  );

  static final InteractionTheme corporateBlue = InteractionTheme(
    crosshairColor: const Color(0xFF1976D2), // Corporate blue
    crosshairWidth: 1.0,
    crosshairDashPattern: const [4.0, 2.0],
    tooltipBackground: const Color(0xF0FFFFFF), // 94% white
    tooltipTextStyle: const TextStyle(
      color: Color(0xFF1565C0),
      fontSize: 12.0,
      fontWeight: FontWeight.w500,
    ),
    selectionColor: const Color(0x4D1976D2), // 30% blue
  );

  static final InteractionTheme vibrant = InteractionTheme(
    crosshairColor: const Color(0xFFE91E63), // Pink
    crosshairWidth: 1.5,
    crosshairDashPattern: const [6.0, 3.0],
    tooltipBackground: const Color(0xF0FFFFFF), // 94% white
    tooltipTextStyle: const TextStyle(
      color: Color(0xFF880E4F),
      fontSize: 12.0,
      fontWeight: FontWeight.w600,
    ),
    selectionColor: const Color(0x4DE91E63), // 30% pink
  );

  static final InteractionTheme minimal = InteractionTheme(
    crosshairColor: const Color(0xFF9E9E9E), // Grey
    crosshairWidth: 0.5,
    crosshairDashPattern: const [],
    tooltipBackground: const Color(0xF5F5F5F5), // 96% grey
    tooltipTextStyle: const TextStyle(
      color: Color(0xFF424242),
      fontSize: 11.0,
      fontWeight: FontWeight.normal,
    ),
    selectionColor: const Color(0x33757575), // 20% grey
  );

  static final InteractionTheme highContrast = InteractionTheme(
    crosshairColor: const Color(0xFFFF0000), // Red
    crosshairWidth: 2.0,
    crosshairDashPattern: const [],
    tooltipBackground: const Color(0xFF000000), // Black
    tooltipTextStyle: const TextStyle(
      color: Color(0xFFFFFFFF),
      fontSize: 14.0,
      fontWeight: FontWeight.bold,
    ),
    selectionColor: const Color(0x80FFFF00), // 50% yellow
  );

  static final InteractionTheme colorblindFriendly = InteractionTheme(
    crosshairColor: const Color(0xFF0173B2), // Blue (Okabe-Ito)
    crosshairWidth: 1.0,
    crosshairDashPattern: const [5.0, 3.0],
    tooltipBackground: const Color(0xF0FFFFFF), // 94% white
    tooltipTextStyle: const TextStyle(
      color: Color(0xFF000000),
      fontSize: 12.0,
      fontWeight: FontWeight.normal,
    ),
    selectionColor: const Color(0x4DDE8F05), // 30% orange (Okabe-Ito)
  );

  // ========== Methods ==========

  /// Creates a copy of this theme with the given fields replaced.
  InteractionTheme copyWith({
    Color? crosshairColor,
    double? crosshairWidth,
    List<double>? crosshairDashPattern,
    Color? tooltipBackground,
    TextStyle? tooltipTextStyle,
    Color? selectionColor,
  }) {
    return InteractionTheme(
      crosshairColor: crosshairColor ?? this.crosshairColor,
      crosshairWidth: crosshairWidth ?? this.crosshairWidth,
      crosshairDashPattern: crosshairDashPattern ?? this.crosshairDashPattern,
      tooltipBackground: tooltipBackground ?? this.tooltipBackground,
      tooltipTextStyle: tooltipTextStyle ?? this.tooltipTextStyle,
      selectionColor: selectionColor ?? this.selectionColor,
    );
  }

  /// Converts this theme to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'crosshairColor':
          '#${crosshairColor.value.toRadixString(16).padLeft(8, '0')}',
      'crosshairWidth': crosshairWidth,
      'crosshairDashPattern': crosshairDashPattern,
      'tooltipBackground':
          '#${tooltipBackground.value.toRadixString(16).padLeft(8, '0')}',
      'tooltipTextStyle': _textStyleToJson(tooltipTextStyle),
      'selectionColor':
          '#${selectionColor.value.toRadixString(16).padLeft(8, '0')}',
    };
  }

  // ========== Equality ==========

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! InteractionTheme) return false;

    return crosshairColor == other.crosshairColor &&
        crosshairWidth == other.crosshairWidth &&
        _listEquals(crosshairDashPattern, other.crosshairDashPattern) &&
        tooltipBackground == other.tooltipBackground &&
        tooltipTextStyle == other.tooltipTextStyle &&
        selectionColor == other.selectionColor;
  }

  @override
  int get hashCode {
    return Object.hash(
      crosshairColor,
      crosshairWidth,
      Object.hashAll(crosshairDashPattern),
      tooltipBackground,
      tooltipTextStyle,
      selectionColor,
    );
  }

  // ========== Helper Methods ==========

  /// Parses a color from hex string format.
  static Color _parseColor(String hex) {
    final hexValue = hex.replaceFirst('#', '');
    return Color(int.parse(hexValue, radix: 16));
  }

  /// Converts a TextStyle to JSON.
  static Map<String, dynamic> _textStyleToJson(TextStyle style) {
    return {
      if (style.color != null)
        'color': '#${style.color!.value.toRadixString(16).padLeft(8, '0')}',
      if (style.fontSize != null) 'fontSize': style.fontSize,
      if (style.fontWeight != null) 'fontWeight': style.fontWeight!.index,
      if (style.fontFamily != null) 'fontFamily': style.fontFamily,
    };
  }

  /// Parses a TextStyle from JSON.
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

  /// Compares two lists for equality.
  static bool _listEquals<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
