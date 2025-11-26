// Copyright (c) 2025 Braven Charts
// Licensed under the MIT License

import 'package:flutter/material.dart';

import '../styles/label_style.dart';

/// Defines the visual styling for interactive elements in charts.
///
/// This theme controls the appearance of:
/// - Crosshair lines that follow the cursor
/// - Crosshair coordinate labels (X/Y values)
/// - Tooltips that display data point information
/// - Selection highlights for data points and regions
///
/// Example:
/// ```dart
/// final theme = InteractionTheme(
///   crosshairColor: Colors.grey,
///   crosshairWidth: 1.0,
///   crosshairDashPattern: [5.0, 3.0],
///   crosshairLabelStyle: LabelStyle(...),
///   tooltipStyle: LabelStyle(...),
///   selectionColor: Colors.blue.withOpacity(0.3),
/// );
/// ```
class InteractionTheme {
  const InteractionTheme({
    required this.crosshairColor,
    required this.crosshairWidth,
    required this.crosshairDashPattern,
    required this.crosshairLabelStyle,
    required this.tooltipStyle,
    required this.selectionColor,
  }) : assert(crosshairWidth >= 0, 'crosshairWidth must be >= 0');

  /// Color of the crosshair lines.
  final Color crosshairColor;

  /// Width of the crosshair lines. Must be >= 0.
  final double crosshairWidth;

  /// Dash pattern for crosshair lines.
  /// Empty list means solid line. Non-empty list defines dash/gap pattern.
  final List<double> crosshairDashPattern;

  /// Style for crosshair coordinate labels (X/Y values at chart edges).
  final LabelStyle crosshairLabelStyle;

  /// Style for data point tooltips (shown on marker hover).
  final LabelStyle tooltipStyle;

  /// Color used for selection highlights.
  final Color selectionColor;

  // ========== Predefined Themes ==========

  static final InteractionTheme defaultLight = InteractionTheme(
    crosshairColor: const Color(0xFF757575),
    crosshairWidth: 1.0,
    crosshairDashPattern: const [5.0, 3.0],
    crosshairLabelStyle: const LabelStyle(
      textStyle: TextStyle(color: Color(0xFF212121), fontSize: 10.0),
      backgroundColor: Color(0xF0FFFFFF),
      borderColor: Color(0xFFBDBDBD),
      borderWidth: 0.5,
      borderRadius: 3.0,
      padding: EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
    ),
    tooltipStyle: const LabelStyle(
      textStyle: TextStyle(color: Color(0xFF212121), fontSize: 12.0),
      backgroundColor: Color(0xE6FFFFFF),
      borderColor: Color(0xFFBDBDBD),
      borderWidth: 1.0,
      borderRadius: 4.0,
      padding: EdgeInsets.all(8.0),
      shadowColor: Color(0x33000000),
      shadowBlurRadius: 4.0,
    ),
    selectionColor: Color(0x4D2196F3),
  );

  static final InteractionTheme defaultDark = InteractionTheme(
    crosshairColor: const Color(0xFFBDBDBD),
    crosshairWidth: 1.0,
    crosshairDashPattern: const [5.0, 3.0],
    crosshairLabelStyle: const LabelStyle(
      textStyle: TextStyle(color: Color(0xFFFFFFFF), fontSize: 10.0),
      backgroundColor: Color(0xE6212121),
      borderColor: Color(0xFF616161),
      borderWidth: 0.5,
      borderRadius: 3.0,
      padding: EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
    ),
    tooltipStyle: const LabelStyle(
      textStyle: TextStyle(color: Color(0xFFFFFFFF), fontSize: 12.0),
      backgroundColor: Color(0xE6212121),
      borderColor: Color(0xFF616161),
      borderWidth: 1.0,
      borderRadius: 4.0,
      padding: EdgeInsets.all(8.0),
      shadowColor: Color(0x33000000),
      shadowBlurRadius: 4.0,
    ),
    selectionColor: Color(0x4D64B5F6),
  );

  static final InteractionTheme corporateBlue = InteractionTheme(
    crosshairColor: const Color(0xFF1976D2),
    crosshairWidth: 1.0,
    crosshairDashPattern: const [4.0, 2.0],
    crosshairLabelStyle: const LabelStyle(
      textStyle: TextStyle(color: Color(0xFF1976D2), fontSize: 10.0, fontWeight: FontWeight.w500),
      backgroundColor: Color(0xF0FFFFFF),
      borderColor: Color(0xFF1976D2),
      borderWidth: 0.5,
      borderRadius: 2.0,
      padding: EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
    ),
    tooltipStyle: const LabelStyle(
      textStyle: TextStyle(color: Color(0xFF1565C0), fontSize: 12.0, fontWeight: FontWeight.w500),
      backgroundColor: Color(0xF0FFFFFF),
      borderColor: Color(0xFF1976D2),
      borderWidth: 1.5,
      borderRadius: 2.0,
      padding: EdgeInsets.all(8.0),
    ),
    selectionColor: Color(0x4D1976D2),
  );

  static final InteractionTheme vibrant = InteractionTheme(
    crosshairColor: const Color(0xFFE91E63),
    crosshairWidth: 1.5,
    crosshairDashPattern: const [6.0, 3.0],
    crosshairLabelStyle: const LabelStyle(
      textStyle: TextStyle(color: Color(0xFFE91E63), fontSize: 10.0, fontWeight: FontWeight.w600),
      backgroundColor: Color(0xF0FFFFFF),
      borderColor: Color(0xFFE91E63),
      borderWidth: 0.5,
      borderRadius: 6.0,
      padding: EdgeInsets.symmetric(horizontal: 5.0, vertical: 3.0),
    ),
    tooltipStyle: const LabelStyle(
      textStyle: TextStyle(color: Color(0xFF880E4F), fontSize: 12.0, fontWeight: FontWeight.w600),
      backgroundColor: Color(0xF0FFFFFF),
      borderColor: Color(0xFFE91E63),
      borderWidth: 2.0,
      borderRadius: 6.0,
      padding: EdgeInsets.all(10.0),
      shadowColor: Color(0x44E91E63),
      shadowBlurRadius: 6.0,
    ),
    selectionColor: Color(0x4DE91E63),
  );

  static final InteractionTheme minimal = InteractionTheme(
    crosshairColor: const Color(0xFF9E9E9E),
    crosshairWidth: 0.5,
    crosshairDashPattern: const [],
    crosshairLabelStyle: const LabelStyle(
      textStyle: TextStyle(color: Color(0xFF616161), fontSize: 9.0),
      backgroundColor: Color(0xF5F5F5F5),
      borderColor: Color(0xFFE0E0E0),
      borderWidth: 0.5,
      borderRadius: 3.0,
      padding: EdgeInsets.symmetric(horizontal: 3.0, vertical: 1.5),
    ),
    tooltipStyle: const LabelStyle(
      textStyle: TextStyle(color: Color(0xFF424242), fontSize: 11.0),
      backgroundColor: Color(0xF5F5F5F5),
      borderColor: Color(0xFFE0E0E0),
      borderWidth: 0.5,
      borderRadius: 3.0,
      padding: EdgeInsets.all(6.0),
    ),
    selectionColor: Color(0x33757575),
  );

  static final InteractionTheme highContrast = InteractionTheme(
    crosshairColor: const Color(0xFFFF0000),
    crosshairWidth: 2.0,
    crosshairDashPattern: const [],
    crosshairLabelStyle: const LabelStyle(
      textStyle: TextStyle(color: Color(0xFFFFFF00), fontSize: 12.0, fontWeight: FontWeight.bold),
      backgroundColor: Color(0xFF000000),
      borderColor: Color(0xFFFFFFFF),
      borderWidth: 2.0,
      borderRadius: 0.0,
      padding: EdgeInsets.symmetric(horizontal: 6.0, vertical: 3.0),
    ),
    tooltipStyle: const LabelStyle(
      textStyle: TextStyle(color: Color(0xFFFFFFFF), fontSize: 14.0, fontWeight: FontWeight.bold),
      backgroundColor: Color(0xFF000000),
      borderColor: Color(0xFFFFFFFF),
      borderWidth: 2.0,
      borderRadius: 0.0,
      padding: EdgeInsets.all(10.0),
    ),
    selectionColor: Color(0x80FFFF00),
  );

  static final InteractionTheme colorblindFriendly = InteractionTheme(
    crosshairColor: const Color(0xFF0173B2),
    crosshairWidth: 1.0,
    crosshairDashPattern: const [5.0, 3.0],
    crosshairLabelStyle: const LabelStyle(
      textStyle: TextStyle(color: Color(0xFF0173B2), fontSize: 10.0),
      backgroundColor: Color(0xF0FFFFFF),
      borderColor: Color(0xFF0173B2),
      borderWidth: 0.5,
      borderRadius: 4.0,
      padding: EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
    ),
    tooltipStyle: const LabelStyle(
      textStyle: TextStyle(color: Color(0xFF000000), fontSize: 12.0),
      backgroundColor: Color(0xF0FFFFFF),
      borderColor: Color(0xFF0173B2),
      borderWidth: 1.0,
      borderRadius: 4.0,
      padding: EdgeInsets.all(8.0),
    ),
    selectionColor: Color(0x4DDE8F05),
  );

  // ========== Methods ==========

  InteractionTheme copyWith({
    Color? crosshairColor,
    double? crosshairWidth,
    List<double>? crosshairDashPattern,
    LabelStyle? crosshairLabelStyle,
    LabelStyle? tooltipStyle,
    Color? selectionColor,
  }) {
    return InteractionTheme(
      crosshairColor: crosshairColor ?? this.crosshairColor,
      crosshairWidth: crosshairWidth ?? this.crosshairWidth,
      crosshairDashPattern: crosshairDashPattern ?? this.crosshairDashPattern,
      crosshairLabelStyle: crosshairLabelStyle ?? this.crosshairLabelStyle,
      tooltipStyle: tooltipStyle ?? this.tooltipStyle,
      selectionColor: selectionColor ?? this.selectionColor,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'crosshairColor': '#${crosshairColor.value.toRadixString(16).padLeft(8, '0')}',
      'crosshairWidth': crosshairWidth,
      'crosshairDashPattern': crosshairDashPattern,
      'crosshairLabelStyle': crosshairLabelStyle.toJson(),
      'tooltipStyle': tooltipStyle.toJson(),
      'selectionColor': '#${selectionColor.value.toRadixString(16).padLeft(8, '0')}',
    };
  }

  factory InteractionTheme.fromJson(Map<String, dynamic> json) {
    return InteractionTheme(
      crosshairColor: _parseColor(json['crosshairColor'] as String),
      crosshairWidth: (json['crosshairWidth'] as num).toDouble(),
      crosshairDashPattern: (json['crosshairDashPattern'] as List).map((e) => (e as num).toDouble()).toList(),
      crosshairLabelStyle: LabelStyle.fromJson(json['crosshairLabelStyle'] as Map<String, dynamic>),
      tooltipStyle: LabelStyle.fromJson(json['tooltipStyle'] as Map<String, dynamic>),
      selectionColor: _parseColor(json['selectionColor'] as String),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is InteractionTheme &&
        crosshairColor == other.crosshairColor &&
        crosshairWidth == other.crosshairWidth &&
        _listEquals(crosshairDashPattern, other.crosshairDashPattern) &&
        crosshairLabelStyle == other.crosshairLabelStyle &&
        tooltipStyle == other.tooltipStyle &&
        selectionColor == other.selectionColor;
  }

  @override
  int get hashCode => Object.hash(
        crosshairColor,
        crosshairWidth,
        Object.hashAll(crosshairDashPattern),
        crosshairLabelStyle,
        tooltipStyle,
        selectionColor,
      );

  static Color _parseColor(String hex) {
    final hexValue = hex.replaceFirst('#', '');
    return Color(int.parse(hexValue, radix: 16));
  }

  static bool _listEquals<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
