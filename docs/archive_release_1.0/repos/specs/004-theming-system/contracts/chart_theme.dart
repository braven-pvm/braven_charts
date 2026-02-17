// CONTRACT: ChartTheme
// Feature: 004-theming-system
// Layer: 3 (depends on Foundation, Core Rendering)
//
// This contract defines the root ChartTheme entity that aggregates all
// theme components. It provides 7 predefined themes and supports
// serialization, customization via copyWith(), and validation.

import 'package:flutter/material.dart';

import 'animation_theme.dart';
import 'axis_style.dart';
import 'grid_style.dart';
import 'interaction_theme.dart';
import 'series_theme.dart';
import 'typography_theme.dart';

/// Root theme container for all chart visual styling.
///
/// ChartTheme is immutable and can only be modified via [copyWith()].
/// All fields are required and non-null.
///
/// Example:
/// ```dart
/// final theme = ChartTheme.defaultLight.copyWith(
///   backgroundColor: Colors.grey[50],
///   seriesTheme: SeriesTheme(colors: [Colors.red, Colors.blue]),
/// );
/// ```
class ChartTheme {
  const ChartTheme({
    required this.backgroundColor,
    required this.borderColor,
    required this.borderWidth,
    required this.padding,
    required this.gridStyle,
    required this.axisStyle,
    required this.seriesTheme,
    required this.interactionTheme,
    required this.typographyTheme,
    required this.animationTheme,
  }) : assert(borderWidth >= 0.0, 'borderWidth must be >= 0');

  /// Background color of the entire chart area.
  final Color backgroundColor;

  /// Border color around the chart area.
  final Color borderColor;

  /// Border width in pixels. Use 0.0 for no border.
  final double borderWidth;

  /// Padding inside the chart area (between border and plot area).
  final EdgeInsets padding;

  /// Grid line styling.
  final GridStyle gridStyle;

  /// Axis line and label styling.
  final AxisStyle axisStyle;

  /// Series colors, line widths, and marker styling.
  final SeriesTheme seriesTheme;

  /// Interactive element styling (crosshair, tooltips, selection).
  final InteractionTheme interactionTheme;

  /// Font family, sizes, and responsive scaling.
  final TypographyTheme typographyTheme;

  /// Animation durations and curves.
  final AnimationTheme animationTheme;

  // ========== Predefined Themes ==========

  /// Default light theme: white background, professional styling.
  /// Meets WCAG 2.1 AA contrast requirements.
  static const ChartTheme defaultLight = ChartTheme(
    backgroundColor: Color(0xFFFFFFFF),
    borderColor: Color(0xFFE0E0E0),
    borderWidth: 1.0,
    padding: EdgeInsets.all(16.0),
    gridStyle: GridStyle.defaultLight,
    axisStyle: AxisStyle.defaultLight,
    seriesTheme: SeriesTheme.defaultLight,
    interactionTheme: InteractionTheme.defaultLight,
    typographyTheme: TypographyTheme.defaultLight,
    animationTheme: AnimationTheme.defaultLight,
  );

  /// Default dark theme: dark background, Material Design 3 inspired.
  /// Meets WCAG 2.1 AA contrast requirements.
  static const ChartTheme defaultDark = ChartTheme(
    backgroundColor: Color(0xFF121212),
    borderColor: Color(0xFF424242),
    borderWidth: 1.0,
    padding: EdgeInsets.all(16.0),
    gridStyle: GridStyle.defaultDark,
    axisStyle: AxisStyle.defaultDark,
    seriesTheme: SeriesTheme.defaultDark,
    interactionTheme: InteractionTheme.defaultDark,
    typographyTheme: TypographyTheme.defaultDark,
    animationTheme: AnimationTheme.defaultDark,
  );

  /// Corporate Blue theme: professional financial/business applications.
  /// Uses blue color palette with 5+ shades.
  static const ChartTheme corporateBlue = ChartTheme(
    backgroundColor: Color(0xFFF5F7FA),
    borderColor: Color(0xFFB0BEC5),
    borderWidth: 1.0,
    padding: EdgeInsets.all(16.0),
    gridStyle: GridStyle.corporateBlue,
    axisStyle: AxisStyle.corporateBlue,
    seriesTheme: SeriesTheme.corporateBlue,
    interactionTheme: InteractionTheme.corporateBlue,
    typographyTheme: TypographyTheme.corporateBlue,
    animationTheme: AnimationTheme.corporateBlue,
  );

  /// Vibrant theme: high-energy dashboards and marketing.
  /// Bold, saturated colors for maximum visual impact.
  static const ChartTheme vibrant = ChartTheme(
    backgroundColor: Color(0xFFFFFFFF),
    borderColor: Color(0xFFBDBDBD),
    borderWidth: 1.0,
    padding: EdgeInsets.all(16.0),
    gridStyle: GridStyle.vibrant,
    axisStyle: AxisStyle.vibrant,
    seriesTheme: SeriesTheme.vibrant,
    interactionTheme: InteractionTheme.vibrant,
    typographyTheme: TypographyTheme.vibrant,
    animationTheme: AnimationTheme.vibrant,
  );

  /// Minimal theme: technical/scientific applications.
  /// Subtle grays, minimal visual noise.
  static const ChartTheme minimal = ChartTheme(
    backgroundColor: Color(0xFFFFFFFF),
    borderColor: Color(0xFFEEEEEE),
    borderWidth: 0.5,
    padding: EdgeInsets.all(12.0),
    gridStyle: GridStyle.minimal,
    axisStyle: AxisStyle.minimal,
    seriesTheme: SeriesTheme.minimal,
    interactionTheme: InteractionTheme.minimal,
    typographyTheme: TypographyTheme.minimal,
    animationTheme: AnimationTheme.minimal,
  );

  /// High Contrast theme: accessibility and printing.
  /// Meets WCAG 2.1 AAA (7:1 contrast ratio) for all text.
  static const ChartTheme highContrast = ChartTheme(
    backgroundColor: Color(0xFFFFFFFF),
    borderColor: Color(0xFF000000),
    borderWidth: 2.0,
    padding: EdgeInsets.all(16.0),
    gridStyle: GridStyle.highContrast,
    axisStyle: AxisStyle.highContrast,
    seriesTheme: SeriesTheme.highContrast,
    interactionTheme: InteractionTheme.highContrast,
    typographyTheme: TypographyTheme.highContrast,
    animationTheme: AnimationTheme.highContrast,
  );

  /// Colorblind Friendly theme: safe for protanopia, deuteranopia, tritanopia.
  /// Uses Brettel-tested colors with redundant encoding (shapes + colors).
  static const ChartTheme colorblindFriendly = ChartTheme(
    backgroundColor: Color(0xFFFFFFFF),
    borderColor: Color(0xFFBDBDBD),
    borderWidth: 1.0,
    padding: EdgeInsets.all(16.0),
    gridStyle: GridStyle.colorblindFriendly,
    axisStyle: AxisStyle.colorblindFriendly,
    seriesTheme: SeriesTheme.colorblindFriendly,
    interactionTheme: InteractionTheme.colorblindFriendly,
    typographyTheme: TypographyTheme.colorblindFriendly,
    animationTheme: AnimationTheme.colorblindFriendly,
  );

  // ========== Customization ==========

  /// Creates a copy with specified fields replaced.
  ///
  /// All parameters are optional. Unspecified fields retain their current values.
  ///
  /// Example:
  /// ```dart
  /// final customTheme = ChartTheme.defaultLight.copyWith(
  ///   backgroundColor: Colors.grey[100],
  ///   seriesTheme: SeriesTheme(colors: [Colors.red, Colors.green]),
  /// );
  /// ```
  ChartTheme copyWith({
    Color? backgroundColor,
    Color? borderColor,
    double? borderWidth,
    EdgeInsets? padding,
    GridStyle? gridStyle,
    AxisStyle? axisStyle,
    SeriesTheme? seriesTheme,
    InteractionTheme? interactionTheme,
    TypographyTheme? typographyTheme,
    AnimationTheme? animationTheme,
  }) {
    return ChartTheme(
      backgroundColor: backgroundColor ?? this.backgroundColor,
      borderColor: borderColor ?? this.borderColor,
      borderWidth: borderWidth ?? this.borderWidth,
      padding: padding ?? this.padding,
      gridStyle: gridStyle ?? this.gridStyle,
      axisStyle: axisStyle ?? this.axisStyle,
      seriesTheme: seriesTheme ?? this.seriesTheme,
      interactionTheme: interactionTheme ?? this.interactionTheme,
      typographyTheme: typographyTheme ?? this.typographyTheme,
      animationTheme: animationTheme ?? this.animationTheme,
    );
  }

  // ========== Serialization ==========

  /// Converts this theme to a JSON map (version 1.0 schema).
  ///
  /// Colors are serialized as #AARRGGBB hex strings.
  /// All component themes are serialized recursively.
  ///
  /// Example output:
  /// ```json
  /// {
  ///   "version": "1.0",
  ///   "theme": {
  ///     "backgroundColor": "#FFFFFFFF",
  ///     "borderColor": "#FFE0E0E0",
  ///     "borderWidth": 1.0,
  ///     ...
  ///   }
  /// }
  /// ```
  Map<String, dynamic> toJson() {
    return {
      'version': '1.0',
      'theme': {
        'backgroundColor':
            '#${backgroundColor.value.toRadixString(16).padLeft(8, '0')}',
        'borderColor':
            '#${borderColor.value.toRadixString(16).padLeft(8, '0')}',
        'borderWidth': borderWidth,
        'padding': {
          'top': padding.top,
          'right': padding.right,
          'bottom': padding.bottom,
          'left': padding.left,
        },
        'gridStyle': gridStyle.toJson(),
        'axisStyle': axisStyle.toJson(),
        'seriesTheme': seriesTheme.toJson(),
        'interactionTheme': interactionTheme.toJson(),
        'typographyTheme': typographyTheme.toJson(),
        'animationTheme': animationTheme.toJson(),
      },
    };
  }

  /// Creates a ChartTheme from a JSON map (version 1.0 schema).
  ///
  /// Missing properties use default values from [defaultLight].
  /// Unknown properties are ignored.
  /// Unknown versions trigger a warning but parse best-effort.
  ///
  /// Throws [FormatException] if JSON is malformed.
  ///
  /// Example:
  /// ```dart
  /// final json = {'version': '1.0', 'theme': {...}};
  /// final theme = ChartTheme.fromJson(json);
  /// ```
  static ChartTheme fromJson(Map<String, dynamic> json) {
    final version = json['version'] as String? ?? '1.0';
    if (version != '1.0') {
      print(
        'Warning: Theme schema version $version, expected 1.0. Parsing best-effort.',
      );
    }

    final themeData = json['theme'] as Map<String, dynamic>? ?? {};
    return ChartTheme(
      backgroundColor:
          _parseColor(themeData['backgroundColor']) ??
          defaultLight.backgroundColor,
      borderColor:
          _parseColor(themeData['borderColor']) ?? defaultLight.borderColor,
      borderWidth:
          (themeData['borderWidth'] as num?)?.toDouble() ??
          defaultLight.borderWidth,
      padding: _parsePadding(themeData['padding']) ?? defaultLight.padding,
      gridStyle: GridStyle.fromJson(
        themeData['gridStyle'] as Map<String, dynamic>? ?? {},
      ),
      axisStyle: AxisStyle.fromJson(
        themeData['axisStyle'] as Map<String, dynamic>? ?? {},
      ),
      seriesTheme: SeriesTheme.fromJson(
        themeData['seriesTheme'] as Map<String, dynamic>? ?? {},
      ),
      interactionTheme: InteractionTheme.fromJson(
        themeData['interactionTheme'] as Map<String, dynamic>? ?? {},
      ),
      typographyTheme: TypographyTheme.fromJson(
        themeData['typographyTheme'] as Map<String, dynamic>? ?? {},
      ),
      animationTheme: AnimationTheme.fromJson(
        themeData['animationTheme'] as Map<String, dynamic>? ?? {},
      ),
    );
  }

  static Color? _parseColor(dynamic value) {
    if (value is! String) return null;
    if (!value.startsWith('#')) return null;
    final hex = value.substring(1);
    if (hex.length != 8) return null;
    return Color(int.parse(hex, radix: 16));
  }

  static EdgeInsets? _parsePadding(dynamic value) {
    if (value is! Map<String, dynamic>) return null;
    return EdgeInsets.only(
      top: (value['top'] as num?)?.toDouble() ?? 0.0,
      right: (value['right'] as num?)?.toDouble() ?? 0.0,
      bottom: (value['bottom'] as num?)?.toDouble() ?? 0.0,
      left: (value['left'] as num?)?.toDouble() ?? 0.0,
    );
  }

  // ========== Equality ==========

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ChartTheme &&
        other.backgroundColor == backgroundColor &&
        other.borderColor == borderColor &&
        other.borderWidth == borderWidth &&
        other.padding == padding &&
        other.gridStyle == gridStyle &&
        other.axisStyle == axisStyle &&
        other.seriesTheme == seriesTheme &&
        other.interactionTheme == interactionTheme &&
        other.typographyTheme == typographyTheme &&
        other.animationTheme == animationTheme;
  }

  @override
  int get hashCode => Object.hash(
    backgroundColor,
    borderColor,
    borderWidth,
    padding,
    gridStyle,
    axisStyle,
    seriesTheme,
    interactionTheme,
    typographyTheme,
    animationTheme,
  );
}
