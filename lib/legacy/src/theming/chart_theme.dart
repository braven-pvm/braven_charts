// Copyright (c) 2025 Braven Charts
// Licensed under the MIT License

import 'package:flutter/material.dart' hide ScrollbarTheme;

import 'components/animation_theme.dart';
import 'components/axis_style.dart';
import 'components/grid_style.dart';
import 'components/interaction_theme.dart';
import 'components/scrollbar_theme.dart';
import 'components/series_theme.dart';
import 'components/typography_theme.dart';

/// The root theme class that aggregates all chart styling components.
///
/// This is the main entry point for theming. It combines:
/// - Chart-level properties (background, border, padding)
/// - Component themes (grid, axes, series, interaction, typography, animation)
///
/// Example:
/// ```dart
/// final theme = ChartTheme(
///   backgroundColor: Colors.white,
///   borderColor: Colors.grey,
///   borderWidth: 1.0,
///   padding: EdgeInsets.all(16.0),
///   gridStyle: GridStyle.defaultLight,
///   axisStyle: AxisStyle.defaultLight,
///   seriesTheme: SeriesTheme.defaultLight,
///   interactionTheme: InteractionTheme.defaultLight,
///   typographyTheme: TypographyTheme.defaultLight,
///   animationTheme: AnimationTheme.defaultLight,
/// );
/// ```
class ChartTheme {
  // ========== Constructor ==========

  /// Creates a chart theme with the specified styling.
  ///
  /// Validates that:
  /// - [borderWidth] >= 0
  ChartTheme({
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
    required this.scrollbarTheme,
  }) : assert(borderWidth >= 0, 'borderWidth must be >= 0');

  /// Creates a theme from a JSON map.
  factory ChartTheme.fromJson(Map<String, dynamic> json) {
    return ChartTheme(
      backgroundColor: _parseColor(json['backgroundColor'] as String),
      borderColor: _parseColor(json['borderColor'] as String),
      borderWidth: (json['borderWidth'] as num).toDouble(),
      padding: _parsePadding(json['padding'] as Map<String, dynamic>),
      gridStyle: GridStyle.fromJson(json['gridStyle'] as Map<String, dynamic>),
      axisStyle: AxisStyle.fromJson(json['axisStyle'] as Map<String, dynamic>),
      seriesTheme: SeriesTheme.fromJson(json['seriesTheme'] as Map<String, dynamic>),
      interactionTheme: InteractionTheme.fromJson(json['interactionTheme'] as Map<String, dynamic>),
      typographyTheme: TypographyTheme.fromJson(json['typographyTheme'] as Map<String, dynamic>),
      animationTheme: AnimationTheme.fromJson(json['animationTheme'] as Map<String, dynamic>),
      scrollbarTheme: ScrollbarTheme.fromJson(json['scrollbarTheme'] as Map<String, dynamic>),
    );
  }
  // ========== Chart-Level Properties ==========

  /// Background color of the chart canvas.
  final Color backgroundColor;

  /// Color of the chart border.
  final Color borderColor;

  /// Width of the chart border.
  /// Must be >= 0. A value of 0 means no border.
  final double borderWidth;

  /// Padding around the chart content.
  final EdgeInsets padding;

  // ========== Component Themes ==========

  /// Styling for grid lines.
  final GridStyle gridStyle;

  /// Styling for axes.
  final AxisStyle axisStyle;

  /// Theming for series (colors, markers, etc.).
  final SeriesTheme seriesTheme;

  /// Styling for interactive elements (crosshair, tooltips, selection).
  final InteractionTheme interactionTheme;

  /// Typography settings (fonts, sizes, scaling).
  final TypographyTheme typographyTheme;

  /// Animation settings (durations, curves).
  final AnimationTheme animationTheme;

  /// Styling for scrollbars.
  final ScrollbarTheme scrollbarTheme;

  // ========== Predefined Themes ==========

  static final ChartTheme defaultLight = ChartTheme(
    backgroundColor: const Color(0xFFFFFFFF), // White
    borderColor: const Color(0xFFE0E0E0), // Light grey
    borderWidth: 1.0,
    padding: const EdgeInsets.all(16.0),
    gridStyle: GridStyle.defaultLight,
    axisStyle: AxisStyle.defaultLight,
    seriesTheme: SeriesTheme.defaultLight,
    interactionTheme: InteractionTheme.defaultLight,
    typographyTheme: TypographyTheme.defaultLight,
    animationTheme: AnimationTheme.defaultLight,
    scrollbarTheme: ScrollbarTheme.defaultLight,
  );

  static final ChartTheme defaultDark = ChartTheme(
    backgroundColor: const Color(0xFF121212), // Material dark
    borderColor: const Color(0xFF424242), // Dark grey
    borderWidth: 1.0,
    padding: const EdgeInsets.all(16.0),
    gridStyle: GridStyle.defaultDark,
    axisStyle: AxisStyle.defaultDark,
    seriesTheme: SeriesTheme.defaultDark,
    interactionTheme: InteractionTheme.defaultDark,
    typographyTheme: TypographyTheme.defaultDark,
    animationTheme: AnimationTheme.defaultDark,
    scrollbarTheme: ScrollbarTheme.defaultDark,
  );

  static final ChartTheme corporateBlue = ChartTheme(
    backgroundColor: const Color(0xFFFAFAFA), // Off-white
    borderColor: const Color(0xFF1976D2), // Corporate blue
    borderWidth: 2.0,
    padding: const EdgeInsets.all(20.0),
    gridStyle: GridStyle.corporateBlue,
    axisStyle: AxisStyle.corporateBlue,
    seriesTheme: SeriesTheme.corporateBlue,
    interactionTheme: InteractionTheme.corporateBlue,
    typographyTheme: TypographyTheme.corporateBlue,
    animationTheme: AnimationTheme.corporateBlue,
    scrollbarTheme: ScrollbarTheme.defaultLight,
  );

  static final ChartTheme vibrant = ChartTheme(
    backgroundColor: const Color(0xFFFFFFFF), // White
    borderColor: const Color(0xFFE91E63), // Pink
    borderWidth: 2.0,
    padding: const EdgeInsets.all(24.0),
    gridStyle: GridStyle.vibrant,
    axisStyle: AxisStyle.vibrant,
    seriesTheme: SeriesTheme.vibrant,
    interactionTheme: InteractionTheme.vibrant,
    typographyTheme: TypographyTheme.vibrant,
    animationTheme: AnimationTheme.vibrant,
    scrollbarTheme: ScrollbarTheme.defaultLight,
  );

  static final ChartTheme minimal = ChartTheme(
    backgroundColor: const Color(0xFFFFFFFF), // White
    borderColor: const Color(0xFFE0E0E0), // Light grey
    borderWidth: 0.0, // No border
    padding: const EdgeInsets.all(12.0),
    gridStyle: GridStyle.minimal,
    axisStyle: AxisStyle.minimal,
    seriesTheme: SeriesTheme.minimal,
    interactionTheme: InteractionTheme.minimal,
    typographyTheme: TypographyTheme.minimal,
    animationTheme: AnimationTheme.minimal,
    scrollbarTheme: ScrollbarTheme.defaultLight,
  );

  static final ChartTheme highContrast = ChartTheme(
    backgroundColor: const Color(0xFFFFFFFF), // White
    borderColor: const Color(0xFF000000), // Black
    borderWidth: 3.0,
    padding: const EdgeInsets.all(20.0),
    gridStyle: GridStyle.highContrast,
    axisStyle: AxisStyle.highContrast,
    seriesTheme: SeriesTheme.highContrast,
    interactionTheme: InteractionTheme.highContrast,
    typographyTheme: TypographyTheme.highContrast,
    animationTheme: AnimationTheme.highContrast,
    scrollbarTheme: ScrollbarTheme.highContrast,
  );

  static final ChartTheme colorblindFriendly = ChartTheme(
    backgroundColor: const Color(0xFFFFFFFF), // White
    borderColor: const Color(0xFFBDBDBD), // Medium grey
    borderWidth: 1.0,
    padding: const EdgeInsets.all(16.0),
    gridStyle: GridStyle.colorblindFriendly,
    axisStyle: AxisStyle.colorblindFriendly,
    seriesTheme: SeriesTheme.colorblindFriendly,
    interactionTheme: InteractionTheme.colorblindFriendly,
    typographyTheme: TypographyTheme.colorblindFriendly,
    animationTheme: AnimationTheme.colorblindFriendly,
    scrollbarTheme: ScrollbarTheme.defaultLight,
  );

  // ========== Methods ==========

  /// Creates a copy of this theme with the given fields replaced.
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
    ScrollbarTheme? scrollbarTheme,
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
      scrollbarTheme: scrollbarTheme ?? this.scrollbarTheme,
    );
  }

  /// Converts this theme to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'backgroundColor': '#${backgroundColor.value.toRadixString(16).padLeft(8, '0')}',
      'borderColor': '#${borderColor.value.toRadixString(16).padLeft(8, '0')}',
      'borderWidth': borderWidth,
      'padding': {
        'left': padding.left,
        'top': padding.top,
        'right': padding.right,
        'bottom': padding.bottom,
      },
      'gridStyle': gridStyle.toJson(),
      'axisStyle': axisStyle.toJson(),
      'seriesTheme': seriesTheme.toJson(),
      'interactionTheme': interactionTheme.toJson(),
      'typographyTheme': typographyTheme.toJson(),
      'animationTheme': animationTheme.toJson(),
      'scrollbarTheme': scrollbarTheme.toJson(),
    };
  }

  // ========== Equality ==========

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! ChartTheme) return false;

    return backgroundColor == other.backgroundColor &&
        borderColor == other.borderColor &&
        borderWidth == other.borderWidth &&
        padding == other.padding &&
        gridStyle == other.gridStyle &&
        axisStyle == other.axisStyle &&
        seriesTheme == other.seriesTheme &&
        interactionTheme == other.interactionTheme &&
        typographyTheme == other.typographyTheme &&
        animationTheme == other.animationTheme &&
        scrollbarTheme == other.scrollbarTheme;
  }

  @override
  int get hashCode {
    return Object.hash(
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
      scrollbarTheme,
    );
  }

  // ========== Helper Methods ==========

  /// Parses a color from hex string format.
  static Color _parseColor(String hex) {
    final hexValue = hex.replaceFirst('#', '');
    return Color(int.parse(hexValue, radix: 16));
  }

  /// Parses EdgeInsets from JSON.
  static EdgeInsets _parsePadding(Map<String, dynamic> json) {
    return EdgeInsets.only(
      left: (json['left'] as num).toDouble(),
      top: (json['top'] as num).toDouble(),
      right: (json['right'] as num).toDouble(),
      bottom: (json['bottom'] as num).toDouble(),
    );
  }
}
