/// Theme change detection utilities for incremental re-rendering.
///
/// Provides efficient diffing between theme versions to determine which
/// components changed, enabling partial re-renders and cache invalidation.
library;

import 'package:braven_charts/src/theming/chart_theme.dart';

/// Represents which components changed between two themes.
///
/// This class is used to optimize rendering when themes change:
/// - Only re-render components that actually changed
/// - Invalidate cached styles for affected components
/// - Preserve rendering state for unchanged components
///
/// ## Example Usage
///
/// ```dart
/// final oldTheme = ChartTheme.defaultLight;
/// final newTheme = ChartTheme.defaultDark;
///
/// final changeSet = ThemeChangeSet.compute(oldTheme, newTheme);
///
/// if (changeSet.backgroundChanged) {
///   // Re-render background
/// }
///
/// if (changeSet.gridStyleChanged) {
///   // Re-render grid
/// }
///
/// if (changeSet.anyChanged) {
///   // At least one component changed
/// }
/// ```
class ThemeChangeSet {
  /// Computes which components changed between two themes.
  ///
  /// Compares each component using equality (==) to detect changes.
  /// Returns a [ThemeChangeSet] with boolean flags for each component.
  ///
  /// Examples:
  /// ```dart
  /// // No changes
  /// final cs1 = ThemeChangeSet.compute(theme, theme);
  /// assert(!cs1.anyChanged);
  ///
  /// // Background changed
  /// final newTheme = theme.copyWith(backgroundColor: Colors.black);
  /// final cs2 = ThemeChangeSet.compute(theme, newTheme);
  /// assert(cs2.backgroundChanged);
  /// assert(!cs2.gridStyleChanged);
  ///
  /// // Multiple changes
  /// final cs3 = ThemeChangeSet.compute(
  ///   ChartTheme.defaultLight,
  ///   ChartTheme.defaultDark,
  /// );
  /// assert(cs3.anyChanged);
  /// ```
  factory ThemeChangeSet.compute(ChartTheme oldTheme, ChartTheme newTheme) {
    return ThemeChangeSet._(
      backgroundChanged: oldTheme.backgroundColor != newTheme.backgroundColor,
      borderColorChanged: oldTheme.borderColor != newTheme.borderColor,
      borderWidthChanged: oldTheme.borderWidth != newTheme.borderWidth,
      paddingChanged: oldTheme.padding != newTheme.padding,
      gridStyleChanged: oldTheme.gridStyle != newTheme.gridStyle,
      axisStyleChanged: oldTheme.axisStyle != newTheme.axisStyle,
      seriesThemeChanged: oldTheme.seriesTheme != newTheme.seriesTheme,
      interactionThemeChanged: oldTheme.interactionTheme != newTheme.interactionTheme,
      typographyThemeChanged: oldTheme.typographyTheme != newTheme.typographyTheme,
      animationThemeChanged: oldTheme.animationTheme != newTheme.animationTheme,
    );
  }

  /// Private constructor (use [compute] factory).
  const ThemeChangeSet._({
    required this.backgroundChanged,
    required this.borderColorChanged,
    required this.borderWidthChanged,
    required this.paddingChanged,
    required this.gridStyleChanged,
    required this.axisStyleChanged,
    required this.seriesThemeChanged,
    required this.interactionThemeChanged,
    required this.typographyThemeChanged,
    required this.animationThemeChanged,
  });

  /// Whether the background color changed.
  final bool backgroundChanged;

  /// Whether the border color changed.
  final bool borderColorChanged;

  /// Whether the border width changed.
  final bool borderWidthChanged;

  /// Whether the padding changed.
  final bool paddingChanged;

  /// Whether the grid style changed.
  final bool gridStyleChanged;

  /// Whether the axis style changed.
  final bool axisStyleChanged;

  /// Whether the series theme changed.
  final bool seriesThemeChanged;

  /// Whether the interaction theme changed.
  final bool interactionThemeChanged;

  /// Whether the typography theme changed.
  final bool typographyThemeChanged;

  /// Whether the animation theme changed.
  final bool animationThemeChanged;

  /// Whether any component changed.
  ///
  /// Returns true if at least one component changed between themes.
  /// Useful for quick checks before entering diffing logic.
  ///
  /// Examples:
  /// ```dart
  /// if (changeSet.anyChanged) {
  ///   // Re-render or invalidate cache
  /// } else {
  ///   // Skip update - themes are identical
  /// }
  /// ```
  bool get anyChanged =>
      backgroundChanged ||
      borderColorChanged ||
      borderWidthChanged ||
      paddingChanged ||
      gridStyleChanged ||
      axisStyleChanged ||
      seriesThemeChanged ||
      interactionThemeChanged ||
      typographyThemeChanged ||
      animationThemeChanged;
}
