// ChartThemeBuilder Implementation
// Feature: 004-theming-system
// Phase 3: Theme Builder (T028)

import 'package:flutter/material.dart';

import '../chart_theme.dart';
import '../components/animation_theme.dart';
import '../components/axis_style.dart';
import '../components/grid_style.dart';
import '../components/interaction_theme.dart';
import '../components/series_theme.dart';
import '../components/typography_theme.dart';

/// Fluent builder for creating custom chart themes.
///
/// Provides a convenient, type-safe way to construct themes with custom
/// properties. Supports two creation patterns:
///
/// 1. **Start from defaults**: `ChartThemeBuilder()` begins with sensible defaults
/// 2. **Start from existing theme**: `ChartThemeBuilder.from(theme)` customizes a predefined theme
///
/// All setter methods return `this` for fluent chaining.
///
/// Example:
/// ```dart
/// // Minimal customization from defaults
/// final theme = ChartThemeBuilder()
///   .backgroundColor(Colors.grey[50]!)
///   .borderWidth(2.0)
///   .build();
///
/// // Start from predefined theme
/// final customVibrant = ChartThemeBuilder.from(ChartTheme.vibrant)
///   .padding(EdgeInsets.all(32.0))
///   .build();
///
/// // Complex customization with chaining
/// final enterprise = ChartThemeBuilder()
///   .backgroundColor(Color(0xFFFAFAFA))
///   .borderColor(Color(0xFF1976D2))
///   .borderWidth(3.0)
///   .padding(EdgeInsets.all(24.0))
///   .gridStyle(GridStyle.corporateBlue)
///   .axisStyle(AxisStyle.corporateBlue)
///   .seriesTheme(SeriesTheme.corporateBlue)
///   .interactionTheme(InteractionTheme.corporateBlue)
///   .typographyTheme(TypographyTheme.corporateBlue)
///   .animationTheme(AnimationTheme.corporateBlue)
///   .build();
/// ```
class ChartThemeBuilder {
  // ========== Constructors ==========

  /// Creates a builder starting from default values.
  ///
  /// The default values match [ChartTheme.defaultLight]:
  /// - backgroundColor: white (#FFFFFF)
  /// - borderColor: light grey (#E0E0E0)
  /// - borderWidth: 1.0
  /// - padding: 16px all sides
  /// - Component themes: all default light variants
  ChartThemeBuilder() {
    _backgroundColor = const Color(0xFFFFFFFF);
    _borderColor = const Color(0xFFE0E0E0);
    _borderWidth = 1.0;
    _padding = const EdgeInsets.all(16.0);
    _gridStyle = GridStyle.defaultLight;
    _axisStyle = AxisStyle.defaultLight;
    _seriesTheme = SeriesTheme.defaultLight;
    _interactionTheme = InteractionTheme.defaultLight;
    _typographyTheme = TypographyTheme.defaultLight;
    _animationTheme = AnimationTheme.defaultLight;
  }

  /// Creates a builder starting from an existing theme.
  ///
  /// All properties are initialized from the provided theme, allowing
  /// selective customization of specific properties.
  ///
  /// Example:
  /// ```dart
  /// final darkWithBorder = ChartThemeBuilder.from(ChartTheme.defaultDark)
  ///   .borderWidth(2.0)
  ///   .build();
  /// ```
  ChartThemeBuilder.from(ChartTheme theme) {
    _backgroundColor = theme.backgroundColor;
    _borderColor = theme.borderColor;
    _borderWidth = theme.borderWidth;
    _padding = theme.padding;
    _gridStyle = theme.gridStyle;
    _axisStyle = theme.axisStyle;
    _seriesTheme = theme.seriesTheme;
    _interactionTheme = theme.interactionTheme;
    _typographyTheme = theme.typographyTheme;
    _animationTheme = theme.animationTheme;
  }

  // ========== Private State ==========

  late Color _backgroundColor;
  late Color _borderColor;
  late double _borderWidth;
  late EdgeInsets _padding;
  late GridStyle _gridStyle;
  late AxisStyle _axisStyle;
  late SeriesTheme _seriesTheme;
  late InteractionTheme _interactionTheme;
  late TypographyTheme _typographyTheme;
  late AnimationTheme _animationTheme;

  // ========== Fluent Setters ==========

  /// Sets the background color of the chart canvas.
  ///
  /// Example:
  /// ```dart
  /// builder.backgroundColor(Colors.grey[50]!)
  /// ```
  ChartThemeBuilder backgroundColor(Color value) {
    _backgroundColor = value;
    return this;
  }

  /// Sets the color of the chart border.
  ///
  /// Example:
  /// ```dart
  /// builder.borderColor(Color(0xFF1976D2))
  /// ```
  ChartThemeBuilder borderColor(Color value) {
    _borderColor = value;
    return this;
  }

  /// Sets the width of the chart border.
  ///
  /// Must be >= 0. A value of 0 means no border.
  ///
  /// Example:
  /// ```dart
  /// builder.borderWidth(2.0)
  /// ```
  ChartThemeBuilder borderWidth(double value) {
    _borderWidth = value;
    return this;
  }

  /// Sets the padding around the chart content.
  ///
  /// Example:
  /// ```dart
  /// builder.padding(EdgeInsets.all(24.0))
  /// ```
  ChartThemeBuilder padding(EdgeInsets value) {
    _padding = value;
    return this;
  }

  /// Sets the grid style for grid lines.
  ///
  /// Example:
  /// ```dart
  /// builder.gridStyle(GridStyle.minimal)
  /// ```
  ChartThemeBuilder gridStyle(GridStyle value) {
    _gridStyle = value;
    return this;
  }

  /// Sets the axis style for axes.
  ///
  /// Example:
  /// ```dart
  /// builder.axisStyle(AxisStyle.corporateBlue)
  /// ```
  ChartThemeBuilder axisStyle(AxisStyle value) {
    _axisStyle = value;
    return this;
  }

  /// Sets the series theme for data visualization.
  ///
  /// Example:
  /// ```dart
  /// builder.seriesTheme(SeriesTheme.vibrant)
  /// ```
  ChartThemeBuilder seriesTheme(SeriesTheme value) {
    _seriesTheme = value;
    return this;
  }

  /// Sets the interaction theme for tooltips and crosshairs.
  ///
  /// Example:
  /// ```dart
  /// builder.interactionTheme(InteractionTheme.highContrast)
  /// ```
  ChartThemeBuilder interactionTheme(InteractionTheme value) {
    _interactionTheme = value;
    return this;
  }

  /// Sets the typography theme for text rendering.
  ///
  /// Example:
  /// ```dart
  /// builder.typographyTheme(TypographyTheme.defaultDark)
  /// ```
  ChartThemeBuilder typographyTheme(TypographyTheme value) {
    _typographyTheme = value;
    return this;
  }

  /// Sets the animation theme for transitions.
  ///
  /// Example:
  /// ```dart
  /// builder.animationTheme(AnimationTheme.minimal)
  /// ```
  ChartThemeBuilder animationTheme(AnimationTheme value) {
    _animationTheme = value;
    return this;
  }

  // ========== Build ==========

  /// Builds the final ChartTheme after validation.
  ///
  /// Throws [ArgumentError] if any validation rules are violated:
  /// - borderWidth must be >= 0
  ///
  /// Example:
  /// ```dart
  /// final theme = builder.build();
  /// ```
  ChartTheme build() {
    _validate();
    return ChartTheme(
      backgroundColor: _backgroundColor,
      borderColor: _borderColor,
      borderWidth: _borderWidth,
      padding: _padding,
      gridStyle: _gridStyle,
      axisStyle: _axisStyle,
      seriesTheme: _seriesTheme,
      interactionTheme: _interactionTheme,
      typographyTheme: _typographyTheme,
      animationTheme: _animationTheme,
    );
  }

  // ========== Private Validation ==========

  /// Validates all builder state before constructing the theme.
  ///
  /// Throws [ArgumentError] with descriptive messages for any violations.
  void _validate() {
    // Validate borderWidth >= 0
    if (_borderWidth < 0) {
      throw ArgumentError.value(
        _borderWidth,
        'borderWidth',
        'must be >= 0 (got $_borderWidth)',
      );
    }

    // Additional validations are delegated to component themes
    // (they validate on construction, so we don't need to re-validate here)
  }
}
