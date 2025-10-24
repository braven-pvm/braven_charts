// Copyright 2025 Braven Charts. All rights reserved.
// Use of this source code is governed by a BSD-style license.

import 'package:flutter/foundation.dart';
import 'package:braven_charts/src/theming/scrollbar_config.dart';

/// Theme for both X and Y axis scrollbars (7th component of ChartTheme).
///
/// Allows independent styling of horizontal vs vertical scrollbars. This is
/// the theme container that integrates scrollbar styling into the broader
/// ChartTheme system.
///
/// ## Basic Usage
///
/// ```dart
/// // Use predefined theme
/// final theme = ScrollbarTheme.defaultLight;
///
/// // Customize X scrollbar only
/// final customTheme = ScrollbarTheme.defaultLight.copyWith(
///   xAxisScrollbar: ScrollbarConfig(
///     thickness: 16.0,
///     handleColor: Colors.blue,
///   ),
/// );
/// ```
///
/// ## Integration with ChartTheme
///
/// ```dart
/// // Add to ChartTheme
/// final chartTheme = ChartTheme.defaultLight.copyWith(
///   scrollbarTheme: ScrollbarTheme(
///     xAxisScrollbar: ScrollbarConfig(thickness: 16.0),
///     yAxisScrollbar: ScrollbarConfig.defaultLight,
///   ),
/// );
///
/// // Use in chart
/// final chart = BravenChart(
///   theme: chartTheme,
///   interactionConfig: InteractionConfig(
///     showXScrollbar: true,
///     showYScrollbar: true,
///   ),
/// );
/// ```
///
/// ## Why Separate X and Y Configs?
///
/// - **Different Visual Requirements**: Horizontal vs vertical scrollbars may need different thickness/colors
/// - **Independent Control**: Enable X without Y, or vice versa
/// - **Future Flexibility**: Allows per-axis customization (e.g., X scrollbar always visible, Y auto-hides)
///
/// **Note**: Most use cases will use same config for both axes (via predefined themes).
///
/// ## See Also
///
/// - [ScrollbarConfig] - Configuration for a single scrollbar
/// - [ChartTheme] - Root theme container (includes this as 7th component)
@immutable
class ScrollbarTheme {
  /// Creates a scrollbar theme for X and Y axes.
  ///
  /// Both [xAxisScrollbar] and [yAxisScrollbar] are required.
  ///
  /// Example:
  /// ```dart
  /// const theme = ScrollbarTheme(
  ///   xAxisScrollbar: ScrollbarConfig(thickness: 16.0),
  ///   yAxisScrollbar: ScrollbarConfig.defaultLight,
  /// );
  /// ```
  const ScrollbarTheme({
    required this.xAxisScrollbar,
    required this.yAxisScrollbar,
  });

  /// Configuration for horizontal scrollbar (below chart).
  ///
  /// Controls appearance and behavior of the scrollbar that pans/zooms
  /// along the X axis (horizontal data range).
  ///
  /// **Position**: Rendered below the chart canvas, spans full width.
  ///
  /// **Usage**:
  /// ```dart
  /// ChartScrollbar(
  ///   axis: Axis.horizontal,
  ///   theme: chartTheme.scrollbarTheme.xAxisScrollbar,  // ← Uses this config
  /// )
  /// ```
  final ScrollbarConfig xAxisScrollbar;

  /// Configuration for vertical scrollbar (right of chart).
  ///
  /// Controls appearance and behavior of the scrollbar that pans/zooms
  /// along the Y axis (vertical data range).
  ///
  /// **Position**: Rendered to the right of chart canvas, spans full height.
  ///
  /// **Usage**:
  /// ```dart
  /// ChartScrollbar(
  ///   axis: Axis.vertical,
  ///   theme: chartTheme.scrollbarTheme.yAxisScrollbar,  // ← Uses this config
  /// )
  /// ```
  final ScrollbarConfig yAxisScrollbar;

  // === Predefined Themes ===

  /// Light theme preset (light background charts).
  ///
  /// **Colors**: Light grey track, medium grey handle (both axes same).
  ///
  /// **Use Case**: Charts with white or light backgrounds.
  ///
  /// Example:
  /// ```dart
  /// final chart = BravenChart(
  ///   theme: ChartTheme.defaultLight,  // Includes ScrollbarTheme.defaultLight
  /// );
  /// ```
  static const ScrollbarTheme defaultLight = ScrollbarTheme(
    xAxisScrollbar: ScrollbarConfig.defaultLight,
    yAxisScrollbar: ScrollbarConfig.defaultLight,
  );

  /// Dark theme preset (dark background charts).
  ///
  /// **Colors**: Dark track, medium grey handle (both axes same).
  ///
  /// **Use Case**: Charts with dark backgrounds.
  static const ScrollbarTheme defaultDark = ScrollbarTheme(
    xAxisScrollbar: ScrollbarConfig.defaultDark,
    yAxisScrollbar: ScrollbarConfig.defaultDark,
  );

  /// High contrast preset (accessibility-focused).
  ///
  /// **Colors**: Pure white track, pure black handle with color-coded states.
  ///
  /// **Use Case**: Accessibility-focused applications, WCAG 2.1 AAA compliance.
  static const ScrollbarTheme highContrast = ScrollbarTheme(
    xAxisScrollbar: ScrollbarConfig.highContrast,
    yAxisScrollbar: ScrollbarConfig.highContrast,
  );

  // === Methods ===

  /// Create copy with selective overrides.
  ///
  /// **Example**:
  /// ```dart
  /// // Customize only X scrollbar
  /// final customTheme = ScrollbarTheme.defaultLight.copyWith(
  ///   xAxisScrollbar: ScrollbarConfig(thickness: 16.0),
  /// );
  ///
  /// // Customize both
  /// final customTheme2 = ScrollbarTheme.defaultLight.copyWith(
  ///   xAxisScrollbar: ScrollbarConfig(thickness: 16.0, autoHide: false),
  ///   yAxisScrollbar: ScrollbarConfig.defaultDark,
  /// );
  /// ```
  ScrollbarTheme copyWith({
    ScrollbarConfig? xAxisScrollbar,
    ScrollbarConfig? yAxisScrollbar,
  }) =>
      ScrollbarTheme(
        xAxisScrollbar: xAxisScrollbar ?? this.xAxisScrollbar,
        yAxisScrollbar: yAxisScrollbar ?? this.yAxisScrollbar,
      );

  /// Serialize to JSON.
  ///
  /// **Example**:
  /// ```dart
  /// final json = ScrollbarTheme.defaultLight.toJson();
  /// // {
  /// //   'xAxisScrollbar': { 'thickness': 12.0, ... },
  /// //   'yAxisScrollbar': { 'thickness': 12.0, ... }
  /// // }
  /// ```
  Map<String, dynamic> toJson() => {
        'xAxisScrollbar': xAxisScrollbar.toJson(),
        'yAxisScrollbar': yAxisScrollbar.toJson(),
      };

  /// Deserialize from JSON.
  ///
  /// **Example**:
  /// ```dart
  /// final json = {
  ///   'xAxisScrollbar': {'thickness': 16.0, ...},
  ///   'yAxisScrollbar': {'thickness': 12.0, ...}
  /// };
  /// final theme = ScrollbarTheme.fromJson(json);
  /// ```
  factory ScrollbarTheme.fromJson(Map<String, dynamic> json) => ScrollbarTheme(
        xAxisScrollbar: ScrollbarConfig.fromJson(json['xAxisScrollbar'] as Map<String, dynamic>),
        yAxisScrollbar: ScrollbarConfig.fromJson(json['yAxisScrollbar'] as Map<String, dynamic>),
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is ScrollbarTheme && xAxisScrollbar == other.xAxisScrollbar && yAxisScrollbar == other.yAxisScrollbar;

  @override
  int get hashCode => Object.hash(xAxisScrollbar, yAxisScrollbar);

  @override
  String toString() => 'ScrollbarTheme('
      'xAxisScrollbar: $xAxisScrollbar, '
      'yAxisScrollbar: $yAxisScrollbar'
      ')';
}
