// Theme Constants
// Feature: 004-theming-system
// Phase 2: Predefined Themes & Validation (T025)

import 'package:flutter/material.dart';

/// Theme constants for chart styling, including color palettes, breakpoints,
/// and validation minimums.
///
/// This file provides reusable constants referenced across the theming system:
/// - **Color palettes**: Named color sets for predefined themes
/// - **Typography breakpoints**: Responsive scaling thresholds
/// - **Validation minimums**: Accessibility and usability constraints
///
/// Example usage:
/// ```dart
/// // Use a predefined color palette
/// final theme = SeriesTheme(
///   colors: ThemeConstants.corporateBluePalette,
///   lineWidths: [2.0],
///   markerSizes: [6.0],
///   markerShapes: [MarkerShape.circle],
/// );
///
/// // Get responsive scale factor
/// final scaleFactor = ThemeConstants.getTypographyScaleFactor(800.0);
///
/// // Enforce minimum constraints
/// final fontSize = max(userFontSize, ThemeConstants.minFontSize);
/// ```
class ThemeConstants {
  // Prevent instantiation
  ThemeConstants._();

  // ========== Color Palettes ==========

  /// Corporate Blue palette - Professional appearance with blue shades.
  ///
  /// Designed for business and corporate contexts. Uses a progression
  /// from primary blue through cyan, teal, and green for visual variety
  /// while maintaining professional consistency.
  ///
  /// Colors (in order):
  /// 1. Primary Blue (#1976D2) - Main brand color
  /// 2. Light Blue (#0288D1) - Secondary accent
  /// 3. Cyan (#0097A7) - Complementary cool tone
  /// 4. Teal (#00796B) - Transitional color
  /// 5. Green (#388E3C) - Distinct yet harmonious
  static const List<Color> corporateBluePalette = [
    Color(0xFF1976D2), // Primary Blue
    Color(0xFF0288D1), // Light Blue
    Color(0xFF0097A7), // Cyan
    Color(0xFF00796B), // Teal
    Color(0xFF388E3C), // Green
  ];

  /// Vibrant palette - High saturation colors for visual impact.
  ///
  /// Designed for dashboards and presentations where data needs to stand out.
  /// Uses bold, saturated colors across the spectrum for maximum distinction.
  ///
  /// Colors (in order):
  /// 1. Pink (#E91E63) - Eye-catching primary
  /// 2. Purple (#9C27B0) - Rich accent
  /// 3. Indigo (#3F51B5) - Deep blue contrast
  /// 4. Cyan (#00BCD4) - Bright cool tone
  /// 5. Lime (#CDDC39) - High contrast yellow-green
  /// 6. Deep Orange (#FF5722) - Warm accent
  static const List<Color> vibrantPalette = [
    Color(0xFFE91E63), // Pink
    Color(0xFF9C27B0), // Purple
    Color(0xFF3F51B5), // Indigo
    Color(0xFF00BCD4), // Cyan
    Color(0xFFCDDC39), // Lime
    Color(0xFFFF5722), // Deep Orange
  ];

  /// Colorblind-Safe palette - Okabe-Ito palette optimized for all colorblind types.
  ///
  /// Based on the scientifically-designed Okabe-Ito color palette, which is
  /// distinguishable by people with all common forms of colorblindness:
  /// protanopia (red-blind), deuteranopia (green-blind), and tritanopia (blue-blind).
  ///
  /// Reference: https://jfly.uni-koeln.de/color/
  ///
  /// Colors (in order):
  /// 1. Blue (#0173B2) - Primary reference
  /// 2. Orange (#DE8F05) - High contrast complement
  /// 3. Teal (#029E73) - Cool mid-tone
  /// 4. Pink (#CC78BC) - Warm mid-tone
  /// 5. Yellow (#ECE133) - High visibility
  /// 6. Light Blue (#56B4E9) - Secondary blue
  static const List<Color> colorblindSafePalette = [
    Color(0xFF0173B2), // Blue
    Color(0xFFDE8F05), // Orange
    Color(0xFF029E73), // Teal
    Color(0xFFCC78BC), // Pink
    Color(0xFFECE133), // Yellow
    Color(0xFF56B4E9), // Light Blue
  ];

  /// Minimal palette - Subtle gray shades for understated charts.
  ///
  /// Designed for minimalist designs where the data should speak for itself.
  /// Uses a neutral gray scale for non-distracting visualization.
  ///
  /// Colors (in order):
  /// 1. Gray (#757575) - Mid-tone base
  /// 2. Light Gray (#9E9E9E) - Lighter variation
  /// 3. Dark Gray (#616161) - Darker variation
  static const List<Color> minimalPalette = [
    Color(0xFF757575), // Gray
    Color(0xFF9E9E9E), // Light Gray
    Color(0xFF616161), // Dark Gray
  ];

  /// High Contrast palette - Maximum distinguishability for accessibility.
  ///
  /// Designed for users with low vision or high contrast display needs.
  /// Uses extreme contrast combinations: black, white, pure red, pure blue.
  /// Meets WCAG AAA standards when used on appropriate backgrounds.
  ///
  /// Colors (in order):
  /// 1. Black (#000000) - Maximum contrast on light backgrounds
  /// 2. White (#FFFFFF) - Maximum contrast on dark backgrounds
  /// 3. Red (#FF0000) - Pure red for alerts/emphasis
  /// 4. Blue (#0000FF) - Pure blue for data/neutrality
  static const List<Color> highContrastPalette = [
    Color(0xFF000000), // Black
    Color(0xFFFFFFFF), // White
    Color(0xFFFF0000), // Red
    Color(0xFF0000FF), // Blue
  ];

  // ========== Typography Breakpoints ==========

  /// Mobile viewport threshold (< 600px logical width).
  ///
  /// Aligned with Material Design 3 breakpoints. Devices narrower than
  /// this value are considered mobile and receive scaled-down typography.
  static const double mobileBreakpoint = 600.0;

  /// Tablet viewport threshold (600-1023px logical width).
  ///
  /// Aligned with Material Design 3 breakpoints. Devices in this range
  /// receive baseline typography scaling (1.0x).
  static const double tabletBreakpoint = 1024.0;

  /// Desktop viewport threshold (>= 1024px logical width).
  ///
  /// Aligned with Material Design 3 breakpoints. Devices wider than
  /// this value receive scaled-up typography for readability on large displays.
  static const double desktopBreakpoint = 1024.0;

  /// Mobile typography scale factor (0.9x).
  ///
  /// Applied to all text sizes when viewport width < [mobileBreakpoint].
  /// Ensures text remains readable on small screens while maximizing
  /// available space for chart content.
  static const double mobileScaleFactor = 0.9;

  /// Tablet typography scale factor (1.0x - baseline).
  ///
  /// Applied to all text sizes when viewport width is between
  /// [mobileBreakpoint] and [desktopBreakpoint]. This is the baseline
  /// scale, so all theme font sizes are designed for this scale.
  static const double tabletScaleFactor = 1.0;

  /// Desktop typography scale factor (1.1x).
  ///
  /// Applied to all text sizes when viewport width >= [desktopBreakpoint].
  /// Improves readability on large displays where users may be viewing
  /// from a greater distance.
  static const double desktopScaleFactor = 1.1;

  /// Get the appropriate typography scale factor for a given viewport width.
  ///
  /// Uses discrete breakpoints (not smooth interpolation) for predictable
  /// behavior and easier testing. Returns one of three values:
  /// - [mobileScaleFactor] (0.9) for widths < 600px
  /// - [tabletScaleFactor] (1.0) for widths 600-1023px
  /// - [desktopScaleFactor] (1.1) for widths >= 1024px
  ///
  /// Example:
  /// ```dart
  /// final viewportWidth = MediaQuery.of(context).size.width;
  /// final scaleFactor = ThemeConstants.getTypographyScaleFactor(viewportWidth);
  /// final scaledFontSize = baseFontSize * scaleFactor;
  /// ```
  static double getTypographyScaleFactor(double viewportWidth) {
    if (viewportWidth < mobileBreakpoint) {
      return mobileScaleFactor;
    } else if (viewportWidth < desktopBreakpoint) {
      return tabletScaleFactor;
    } else {
      return desktopScaleFactor;
    }
  }

  // ========== Validation Minimums ==========

  /// Minimum font size for any text in charts (10.0 logical pixels).
  ///
  /// Enforced minimum for accessibility and readability. Even with responsive
  /// scaling applied, no text should be rendered smaller than this value.
  ///
  /// Rationale:
  /// - WCAG 2.1 recommends minimum 10-12px for readability
  /// - 10px is the practical minimum for crisp rendering on modern displays
  /// - Enforced via `max(scaledSize, minFontSize)` in typography scaling
  ///
  /// Example:
  /// ```dart
  /// final scaledSize = baseFontSize * scaleFactor;
  /// final finalSize = max(scaledSize, ThemeConstants.minFontSize);
  /// ```
  static const double minFontSize = 10.0;

  /// Minimum line width for chart elements (0.5 logical pixels).
  ///
  /// Enforced minimum for visibility and rendering quality. Lines thinner
  /// than this may not render consistently across different displays and
  /// zoom levels.
  ///
  /// Rationale:
  /// - 0.5px is the practical minimum for visible, anti-aliased lines
  /// - Thinner lines may disappear on low-DPI displays
  /// - Ensures grid lines, axis lines, and series lines are always visible
  ///
  /// Example:
  /// ```dart
  /// final lineWidth = max(userWidth, ThemeConstants.minLineWidth);
  /// ```
  static const double minLineWidth = 0.5;

  /// Minimum marker size for data points (3.0 logical pixels).
  ///
  /// Enforced minimum for touch targets and visibility. Markers smaller
  /// than this are difficult to see and impossible to interact with on
  /// touch devices.
  ///
  /// Rationale:
  /// - 3px is the minimum for visible points at typical zoom levels
  /// - While WCAG recommends 44px touch targets, data points can be smaller
  ///   since they're typically viewed, not tapped individually
  /// - Interactive overlays (tooltips) provide larger hit areas if needed
  ///
  /// Example:
  /// ```dart
  /// final markerSize = max(userSize, ThemeConstants.minMarkerSize);
  /// ```
  static const double minMarkerSize = 3.0;

  /// Minimum padding around chart content (8.0 logical pixels).
  ///
  /// Enforced minimum for visual breathing room and preventing content
  /// from touching chart edges. Ensures axes, labels, and content don't
  /// feel cramped.
  ///
  /// Rationale:
  /// - 8px is Material Design's minimum spacing unit
  /// - Prevents text clipping at chart boundaries
  /// - Provides consistent visual rhythm across all themes
  ///
  /// Example:
  /// ```dart
  /// final padding = EdgeInsets.all(max(userPadding, ThemeConstants.minPadding));
  /// ```
  static const double minPadding = 8.0;
}
