import 'package:flutter/material.dart';

import 'scrollbar_config.dart';

/// Theme for both X and Y axis scrollbars (7th component of ChartTheme).
///
/// Allows independent styling of horizontal vs vertical scrollbars.
/// Integrated into ChartTheme as the 7th component theme (alongside GridStyle,
/// AxisStyle, SeriesTheme, InteractionTheme, TypographyTheme, AnimationTheme).
@immutable
class ScrollbarTheme {
  /// Deserialize from JSON.
  factory ScrollbarTheme.fromJson(Map<String, dynamic> json) => ScrollbarTheme(
    xAxisScrollbar: ScrollbarConfig.fromJson(
      json['xAxisScrollbar'] as Map<String, dynamic>,
    ),
    yAxisScrollbar: ScrollbarConfig.fromJson(
      json['yAxisScrollbar'] as Map<String, dynamic>,
    ),
  );
  const ScrollbarTheme({
    required this.xAxisScrollbar,
    required this.yAxisScrollbar,
  });

  /// Configuration for horizontal scrollbar (below chart).
  final ScrollbarConfig xAxisScrollbar;

  /// Configuration for vertical scrollbar (right of chart).
  final ScrollbarConfig yAxisScrollbar;

  /// Light theme preset (light background charts).
  ///
  /// Uses ScrollbarConfig.defaultLight for both axes.
  /// Track: #F5F5F5, Handle: #BDBDBD, Hover: #9E9E9E, Active: #757575
  static const ScrollbarTheme defaultLight = ScrollbarTheme(
    xAxisScrollbar: ScrollbarConfig.defaultLight,
    yAxisScrollbar: ScrollbarConfig.defaultLight,
  );

  /// Dark theme preset (dark background charts).
  ///
  /// Uses ScrollbarConfig.defaultDark for both axes.
  /// Track: #212121, Handle: #616161, Hover: #757575, Active: #9E9E9E
  static const ScrollbarTheme defaultDark = ScrollbarTheme(
    xAxisScrollbar: ScrollbarConfig.defaultDark,
    yAxisScrollbar: ScrollbarConfig.defaultDark,
  );

  /// High contrast preset (accessibility-focused).
  ///
  /// Uses ScrollbarConfig.highContrast for both axes.
  /// Track: #FFFFFF, Handle: #000000, Hover: #1976D2, Active: #D32F2F
  /// Meets WCAG 2.1 AAA contrast requirements (7:1 ratios).
  static const ScrollbarTheme highContrast = ScrollbarTheme(
    xAxisScrollbar: ScrollbarConfig.highContrast,
    yAxisScrollbar: ScrollbarConfig.highContrast,
  );

  /// Create copy with selective overrides.
  ScrollbarTheme copyWith({
    ScrollbarConfig? xAxisScrollbar,
    ScrollbarConfig? yAxisScrollbar,
  }) => ScrollbarTheme(
    xAxisScrollbar: xAxisScrollbar ?? this.xAxisScrollbar,
    yAxisScrollbar: yAxisScrollbar ?? this.yAxisScrollbar,
  );

  /// Serialize to JSON.
  Map<String, dynamic> toJson() => {
    'xAxisScrollbar': xAxisScrollbar.toJson(),
    'yAxisScrollbar': yAxisScrollbar.toJson(),
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScrollbarTheme &&
          xAxisScrollbar == other.xAxisScrollbar &&
          yAxisScrollbar == other.yAxisScrollbar;

  @override
  int get hashCode => Object.hash(xAxisScrollbar, yAxisScrollbar);
}
