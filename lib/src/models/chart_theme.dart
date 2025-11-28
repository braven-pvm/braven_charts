// Copyright 2025 Braven Charts - Comprehensive Theming System
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';

import '../theming/components/animation_theme.dart';
import '../theming/components/annotation_theme.dart';
import '../theming/components/axis_style.dart';
import '../theming/components/grid_style.dart';
import '../theming/components/interaction_theme.dart';
import '../theming/components/scrollbar_config.dart';
import '../theming/components/series_theme.dart';
import '../theming/components/typography_theme.dart';

/// Comprehensive chart theme with component-based styling.
///
/// Integrates multiple theme components for complete visual control:
/// - [gridStyle]: Grid line styling (major/minor)
/// - [axisStyle]: Axis lines, labels, titles, ticks
/// - [seriesTheme]: Data series colors, line widths, markers
/// - [interactionTheme]: Crosshair, tooltips, selection
/// - [typographyTheme]: Font families, sizes, responsive scaling
/// - [animationTheme]: Animation durations and curves
/// - [annotationTheme]: Annotation styling (point, range, text, threshold, trend)
/// - [scrollbarConfig]: Scrollbar appearance and behavior
///
/// Example:
/// ```dart
/// final theme = ChartTheme(
///   gridStyle: GridStyle.defaultLight,
///   axisStyle: AxisStyle.defaultLight,
///   seriesTheme: SeriesTheme.defaultLight,
///   interactionTheme: InteractionTheme.defaultLight,
///   typographyTheme: TypographyTheme.defaultLight,
///   animationTheme: AnimationTheme.defaultLight,
///   annotationTheme: AnnotationTheme.defaultLight,
///   scrollbarConfig: ScrollbarConfig.defaultLight,
/// );
/// ```
class ChartTheme {
  const ChartTheme({
    required this.backgroundColor,
    required this.gridStyle,
    required this.axisStyle,
    required this.seriesTheme,
    required this.interactionTheme,
    required this.typographyTheme,
    required this.animationTheme,
    required this.annotationTheme,
    required this.scrollbarConfig,
    this.focusBorderColor = Colors.blue,
    this.focusBorderWidth = 2.0,
    this.focusBorderRadius = 0.0,
    // Deprecated fields for backward compatibility
    @Deprecated('Use gridStyle.majorColor instead') Color? gridColor,
    @Deprecated('Use axisStyle.lineColor instead') Color? axisColor,
    @Deprecated('Use typographyTheme or axisStyle.labelStyle.color instead') Color? textColor,
    @Deprecated('Use seriesTheme.colors instead') List<Color>? seriesColors,
  })  : _gridColor = gridColor,
        _axisColor = axisColor,
        _textColor = textColor,
        _seriesColors = seriesColors;

  /// Chart background color.
  final Color backgroundColor;

  /// Grid line styling (major and optional minor lines).
  final GridStyle gridStyle;

  /// Axis styling (lines, labels, titles, ticks).
  final AxisStyle axisStyle;

  /// Series data styling (colors, line widths, markers).
  final SeriesTheme seriesTheme;

  /// Interactive element styling (crosshair, tooltips, selection).
  final InteractionTheme interactionTheme;

  /// Typography settings (fonts, sizes, responsive scaling).
  final TypographyTheme typographyTheme;

  /// Animation settings (durations, curves).
  final AnimationTheme animationTheme;

  /// Annotation styling (point, range, text, threshold, trend).
  final AnnotationTheme annotationTheme;

  /// Scrollbar configuration.
  final ScrollbarConfig scrollbarConfig;

  /// Focus border color when chart has keyboard focus.
  final Color focusBorderColor;

  /// Focus border width in pixels.
  final double focusBorderWidth;

  /// Focus border corner radius in pixels (0 = sharp corners).
  final double focusBorderRadius;

  // Deprecated fields (private, for backward compatibility)
  final Color? _gridColor;
  final Color? _axisColor;
  final Color? _textColor;
  final List<Color>? _seriesColors;

  // Deprecated getters for backward compatibility
  @Deprecated('Use gridStyle.majorColor instead')
  Color get gridColor => _gridColor ?? gridStyle.majorColor;

  @Deprecated('Use axisStyle.lineColor instead')
  Color get axisColor => _axisColor ?? axisStyle.lineColor;

  @Deprecated('Use typographyTheme or axisStyle.labelStyle.color instead')
  Color get textColor => _textColor ?? axisStyle.labelStyle.color ?? Colors.black87;

  @Deprecated('Use seriesTheme.colors instead')
  List<Color> get seriesColors => _seriesColors ?? seriesTheme.colors;

  // ========== Predefined Themes ==========

  static final ChartTheme light = ChartTheme(
    backgroundColor: Colors.white,
    gridStyle: GridStyle.defaultLight,
    axisStyle: AxisStyle.defaultLight,
    seriesTheme: SeriesTheme.defaultLight,
    interactionTheme: InteractionTheme.defaultLight,
    typographyTheme: TypographyTheme.defaultLight,
    animationTheme: AnimationTheme.defaultLight,
    annotationTheme: AnnotationTheme.defaultLight,
    scrollbarConfig: ScrollbarConfig.defaultLight,
  );

  static final ChartTheme dark = ChartTheme(
    backgroundColor: const Color(0xFF1E1E1E),
    gridStyle: GridStyle.defaultDark,
    axisStyle: AxisStyle.defaultDark,
    seriesTheme: SeriesTheme.defaultDark,
    interactionTheme: InteractionTheme.defaultDark,
    typographyTheme: TypographyTheme.defaultDark,
    animationTheme: AnimationTheme.defaultDark,
    annotationTheme: AnnotationTheme.defaultDark,
    scrollbarConfig: ScrollbarConfig.defaultDark,
  );

  static final ChartTheme corporateBlue = ChartTheme(
    backgroundColor: Colors.white,
    gridStyle: GridStyle.corporateBlue,
    axisStyle: AxisStyle.corporateBlue,
    seriesTheme: SeriesTheme.corporateBlue,
    interactionTheme: InteractionTheme.corporateBlue,
    typographyTheme: TypographyTheme.corporateBlue,
    animationTheme: AnimationTheme.corporateBlue,
    annotationTheme: AnnotationTheme.corporateBlue,
    scrollbarConfig: ScrollbarConfig.defaultLight,
  );

  static final ChartTheme vibrant = ChartTheme(
    backgroundColor: Colors.white,
    gridStyle: GridStyle.vibrant,
    axisStyle: AxisStyle.vibrant,
    seriesTheme: SeriesTheme.vibrant,
    interactionTheme: InteractionTheme.vibrant,
    typographyTheme: TypographyTheme.vibrant,
    animationTheme: AnimationTheme.vibrant,
    annotationTheme: AnnotationTheme.vibrant,
    scrollbarConfig: ScrollbarConfig.defaultLight,
  );

  static final ChartTheme minimal = ChartTheme(
    backgroundColor: const Color(0xFFFAFAFA),
    gridStyle: GridStyle.minimal,
    axisStyle: AxisStyle.minimal,
    seriesTheme: SeriesTheme.minimal,
    interactionTheme: InteractionTheme.minimal,
    typographyTheme: TypographyTheme.minimal,
    animationTheme: AnimationTheme.minimal,
    annotationTheme: AnnotationTheme.minimal,
    scrollbarConfig: ScrollbarConfig.defaultLight,
  );

  static final ChartTheme highContrast = ChartTheme(
    backgroundColor: Colors.white,
    gridStyle: GridStyle.highContrast,
    axisStyle: AxisStyle.highContrast,
    seriesTheme: SeriesTheme.highContrast,
    interactionTheme: InteractionTheme.highContrast,
    typographyTheme: TypographyTheme.highContrast,
    animationTheme: AnimationTheme.highContrast,
    annotationTheme: AnnotationTheme.highContrast,
    scrollbarConfig: ScrollbarConfig.highContrast,
  );

  static final ChartTheme colorblindFriendly = ChartTheme(
    backgroundColor: Colors.white,
    gridStyle: GridStyle.colorblindFriendly,
    axisStyle: AxisStyle.colorblindFriendly,
    seriesTheme: SeriesTheme.colorblindFriendly,
    interactionTheme: InteractionTheme.colorblindFriendly,
    typographyTheme: TypographyTheme.colorblindFriendly,
    animationTheme: AnimationTheme.colorblindFriendly,
    annotationTheme: AnnotationTheme.colorblindFriendly,
    scrollbarConfig: ScrollbarConfig.defaultLight,
  );

  // ========== Customization ==========

  ChartTheme copyWith({
    Color? backgroundColor,
    GridStyle? gridStyle,
    AxisStyle? axisStyle,
    SeriesTheme? seriesTheme,
    InteractionTheme? interactionTheme,
    TypographyTheme? typographyTheme,
    AnimationTheme? animationTheme,
    AnnotationTheme? annotationTheme,
    ScrollbarConfig? scrollbarConfig,
    Color? focusBorderColor,
    double? focusBorderWidth,
    double? focusBorderRadius,
  }) {
    return ChartTheme(
      backgroundColor: backgroundColor ?? this.backgroundColor,
      gridStyle: gridStyle ?? this.gridStyle,
      axisStyle: axisStyle ?? this.axisStyle,
      seriesTheme: seriesTheme ?? this.seriesTheme,
      interactionTheme: interactionTheme ?? this.interactionTheme,
      typographyTheme: typographyTheme ?? this.typographyTheme,
      animationTheme: animationTheme ?? this.animationTheme,
      annotationTheme: annotationTheme ?? this.annotationTheme,
      scrollbarConfig: scrollbarConfig ?? this.scrollbarConfig,
      focusBorderColor: focusBorderColor ?? this.focusBorderColor,
      focusBorderWidth: focusBorderWidth ?? this.focusBorderWidth,
      focusBorderRadius: focusBorderRadius ?? this.focusBorderRadius,
    );
  }

  // ========== Equality ==========

  // ========== Equality ==========

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! ChartTheme) return false;

    return backgroundColor == other.backgroundColor &&
        gridStyle == other.gridStyle &&
        axisStyle == other.axisStyle &&
        seriesTheme == other.seriesTheme &&
        interactionTheme == other.interactionTheme &&
        typographyTheme == other.typographyTheme &&
        animationTheme == other.animationTheme &&
        annotationTheme == other.annotationTheme &&
        scrollbarConfig == other.scrollbarConfig &&
        focusBorderColor == other.focusBorderColor &&
        focusBorderWidth == other.focusBorderWidth &&
        focusBorderRadius == other.focusBorderRadius;
  }

  @override
  int get hashCode => Object.hash(
        backgroundColor,
        gridStyle,
        axisStyle,
        seriesTheme,
        interactionTheme,
        typographyTheme,
        animationTheme,
        annotationTheme,
        scrollbarConfig,
        focusBorderColor,
        focusBorderWidth,
        focusBorderRadius,
      );
}
