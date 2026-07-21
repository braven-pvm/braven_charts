// Copyright 2025 Braven Charts - Comprehensive Theming System
// SPDX-License-Identifier: MIT

import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import '../theming/components/animation_theme.dart';
import '../theming/components/annotation_theme.dart';
import '../theming/components/axis_style.dart';
import '../theming/components/candlestick_theme.dart';
import '../theming/components/cartesian_value_summary_theme.dart';
import '../theming/components/grid_style.dart';
import '../theming/components/interaction_theme.dart';
import '../theming/components/range_area_theme.dart';
import '../theming/components/scrollbar_config.dart';
import '../theming/components/series_theme.dart';
import '../theming/components/typography_theme.dart';
import 'legend_style.dart';
import 'pie_chart_config.dart';

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
/// - [legendStyle]: Legend appearance (position, fonts, colors, markers)
/// - [pieChartTheme]: Radial fill, elevation, callout, and animation defaults
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
///   legendStyle: LegendStyle.light,
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
    required this.legendStyle,
    this.pieChartTheme = const PieChartTheme(),
    this.candlestickTheme = CandlestickTheme.light,
    this.rangeAreaTheme = RangeAreaTheme.light,
    this.cartesianValueSummaryTheme = CartesianValueSummaryTheme.light,
    this.focusBorderColor = Colors.blue,
    this.focusBorderWidth = 2.0,
    this.focusBorderRadius = 0.0,
    // Deprecated fields for backward compatibility
    @Deprecated('Use gridStyle.majorColor instead') Color? gridColor,
    @Deprecated('Use axisStyle.lineColor instead') Color? axisColor,
    @Deprecated('Use typographyTheme or axisStyle.labelStyle.color instead')
    Color? textColor,
    @Deprecated('Use seriesTheme.colors instead') List<Color>? seriesColors,
  }) : _gridColor = gridColor,
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

  /// Legend styling (position, fonts, colors, markers).
  final LegendStyle legendStyle;

  /// Pie-specific defaults resolved beneath per-series overrides.
  final PieChartTheme pieChartTheme;

  /// Candlestick-specific direction and interaction defaults.
  final CandlestickTheme candlestickTheme;

  /// Range Area fill, boundary, marker, and linked-state defaults.
  final RangeAreaTheme rangeAreaTheme;

  /// Cartesian value summary panel defaults resolved beneath
  /// `CartesianValueSummaryStyle` overrides.
  final CartesianValueSummaryTheme cartesianValueSummaryTheme;

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
  Color get textColor =>
      _textColor ?? axisStyle.labelStyle.color ?? Colors.black87;

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
    legendStyle: LegendStyle.light,
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
    legendStyle: LegendStyle.dark,
    candlestickTheme: CandlestickTheme.dark,
    rangeAreaTheme: RangeAreaTheme.dark,
    cartesianValueSummaryTheme: CartesianValueSummaryTheme.dark,
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
    legendStyle: LegendStyle.light,
    candlestickTheme: CandlestickTheme.light,
    cartesianValueSummaryTheme: CartesianValueSummaryTheme.light,
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
    legendStyle: LegendStyle.light,
    candlestickTheme: CandlestickTheme.light,
    cartesianValueSummaryTheme: CartesianValueSummaryTheme.light,
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
    legendStyle: LegendStyle.light,
    candlestickTheme: CandlestickTheme.light,
    cartesianValueSummaryTheme: CartesianValueSummaryTheme.light,
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
    legendStyle: LegendStyle.light,
    candlestickTheme: CandlestickTheme.highContrast,
    rangeAreaTheme: RangeAreaTheme.highContrast,
    cartesianValueSummaryTheme: CartesianValueSummaryTheme.highContrast,
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
    legendStyle: LegendStyle.light,
    candlestickTheme: CandlestickTheme.colorblindFriendly,
    cartesianValueSummaryTheme: CartesianValueSummaryTheme.colorblindFriendly,
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
    LegendStyle? legendStyle,
    PieChartTheme? pieChartTheme,
    CandlestickTheme? candlestickTheme,
    RangeAreaTheme? rangeAreaTheme,
    CartesianValueSummaryTheme? cartesianValueSummaryTheme,
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
      legendStyle: legendStyle ?? this.legendStyle,
      pieChartTheme: pieChartTheme ?? this.pieChartTheme,
      candlestickTheme: candlestickTheme ?? this.candlestickTheme,
      rangeAreaTheme: rangeAreaTheme ?? this.rangeAreaTheme,
      cartesianValueSummaryTheme:
          cartesianValueSummaryTheme ?? this.cartesianValueSummaryTheme,
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
        legendStyle == other.legendStyle &&
        pieChartTheme == other.pieChartTheme &&
        candlestickTheme == other.candlestickTheme &&
        rangeAreaTheme == other.rangeAreaTheme &&
        cartesianValueSummaryTheme == other.cartesianValueSummaryTheme &&
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
    legendStyle,
    pieChartTheme,
    candlestickTheme,
    rangeAreaTheme,
    cartesianValueSummaryTheme,
    focusBorderColor,
    focusBorderWidth,
    focusBorderRadius,
  );

  // ========== Interpolation ==========

  /// Linearly interpolates between two themes for animated transitions.
  ///
  /// Continuous values — [backgroundColor], the focus border fields, and
  /// [cartesianValueSummaryTheme] — interpolate smoothly. Component themes
  /// without interpolation support switch from [a] to [b] at the midpoint,
  /// following the [ThemeData.lerp] convention for non-lerpable values.
  static ChartTheme lerp(ChartTheme a, ChartTheme b, double t) {
    if (identical(a, b)) {
      return a;
    }
    return ChartTheme(
      backgroundColor: Color.lerp(a.backgroundColor, b.backgroundColor, t)!,
      gridStyle: t < 0.5 ? a.gridStyle : b.gridStyle,
      axisStyle: t < 0.5 ? a.axisStyle : b.axisStyle,
      seriesTheme: t < 0.5 ? a.seriesTheme : b.seriesTheme,
      interactionTheme: t < 0.5 ? a.interactionTheme : b.interactionTheme,
      typographyTheme: t < 0.5 ? a.typographyTheme : b.typographyTheme,
      animationTheme: t < 0.5 ? a.animationTheme : b.animationTheme,
      annotationTheme: t < 0.5 ? a.annotationTheme : b.annotationTheme,
      scrollbarConfig: t < 0.5 ? a.scrollbarConfig : b.scrollbarConfig,
      legendStyle: t < 0.5 ? a.legendStyle : b.legendStyle,
      pieChartTheme: t < 0.5 ? a.pieChartTheme : b.pieChartTheme,
      candlestickTheme: t < 0.5 ? a.candlestickTheme : b.candlestickTheme,
      rangeAreaTheme: t < 0.5 ? a.rangeAreaTheme : b.rangeAreaTheme,
      cartesianValueSummaryTheme: CartesianValueSummaryTheme.lerp(
        a.cartesianValueSummaryTheme,
        b.cartesianValueSummaryTheme,
        t,
      ),
      focusBorderColor: Color.lerp(a.focusBorderColor, b.focusBorderColor, t)!,
      focusBorderWidth: lerpDouble(a.focusBorderWidth, b.focusBorderWidth, t)!,
      focusBorderRadius: lerpDouble(
        a.focusBorderRadius,
        b.focusBorderRadius,
        t,
      )!,
    );
  }
}
