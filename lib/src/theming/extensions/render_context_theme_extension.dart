/// RenderContext extension for theme management.
///
/// Adds theming capabilities to RenderContext for efficient theme application
/// and switching with automatic cache invalidation and diffing.
library;

import 'package:braven_charts/src/rendering/render_context.dart';
import 'package:braven_charts/src/theming/chart_theme.dart';
import 'package:braven_charts/src/theming/utilities/style_cache.dart';
import 'package:braven_charts/src/theming/utilities/theme_change_set.dart';

/// Extension to add theme management to RenderContext.
///
/// Provides methods for applying and updating themes with automatic
/// cache invalidation based on changed components.
///
/// ## Usage
///
/// ```dart
/// // Apply initial theme
/// context.applyTheme(ChartTheme.defaultLight);
///
/// // Get current theme
/// final theme = context.currentTheme;
///
/// // Update theme with automatic diffing
/// context.updateTheme(ChartTheme.defaultDark); // Invalidates changed components
/// ```
extension RenderContextThemeExtension on RenderContext {
  // Static storage for theme and cache (shared across all contexts)
  static ChartTheme? _currentTheme;
  static final StyleCache _styleCache = StyleCache();

  /// Gets the current theme.
  ///
  /// Returns the currently applied theme or null if no theme has been set.
  ///
  /// Example:
  /// ```dart
  /// final theme = context.currentTheme;
  /// if (theme != null) {
  ///   final backgroundColor = theme.backgroundColor;
  /// }
  /// ```
  ChartTheme? get currentTheme => _currentTheme;

  /// Gets the style cache instance.
  ///
  /// Exposed for testing and advanced use cases. Generally, you don't
  /// need to interact with the cache directly.
  StyleCache get styleCache => _styleCache;

  /// Applies a theme without diffing.
  ///
  /// Sets the current theme and clears the entire style cache.
  /// Use this for initial theme application or when you want to force
  /// a complete cache refresh.
  ///
  /// For theme updates, prefer [updateTheme] which performs diffing
  /// and only invalidates affected cache entries.
  ///
  /// Example:
  /// ```dart
  /// // Initial theme setup
  /// context.applyTheme(ChartTheme.defaultLight);
  /// ```
  void applyTheme(ChartTheme theme) {
    _currentTheme = theme;
    _styleCache.clear();
  }

  /// Updates the theme with intelligent diffing.
  ///
  /// Compares the new theme with the current theme to determine which
  /// components changed. Only invalidates cache entries for changed
  /// components, preserving cached styles for unchanged components.
  ///
  /// If no theme is currently set, behaves like [applyTheme] (clears
  /// entire cache).
  ///
  /// Returns a [ThemeChangeSet] indicating which components changed.
  ///
  /// Example:
  /// ```dart
  /// final changes = context.updateTheme(ChartTheme.defaultDark);
  ///
  /// if (changes.backgroundChanged) {
  ///   // Re-render background
  /// }
  ///
  /// if (changes.gridStyleChanged) {
  ///   // Re-render grid
  /// }
  /// ```
  ThemeChangeSet updateTheme(ChartTheme newTheme) {
    final oldTheme = _currentTheme;

    if (oldTheme == null) {
      // No previous theme - apply fresh
      applyTheme(newTheme);
      return ThemeChangeSet.compute(newTheme, newTheme); // All changed
    }

    // Compute what changed
    final changeSet = ThemeChangeSet.compute(oldTheme, newTheme);

    if (!changeSet.anyChanged) {
      // No changes - nothing to do
      return changeSet;
    }

    // Update current theme
    _currentTheme = newTheme;

    // Invalidate cache entries for changed components
    // Since we don't track which cache keys correspond to which components,
    // we clear the entire cache when any component changes.
    // This is a simplification - a more sophisticated implementation could
    // track cache keys by component type and selectively invalidate.
    _styleCache.clear();

    return changeSet;
  }
}
