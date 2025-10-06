// Copyright (c) 2025 Braven Charts
// Licensed under the MIT License

import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Utility functions for color manipulation, accessibility, and conversions.
///
/// Provides:
/// - WCAG contrast ratio calculations
/// - Colorblind simulation (Protanopia, Deuteranopia, Tritanopia)
/// - Colorblind-friendly palette generation
/// - Color serialization (hex conversion)
class ColorUtils {
  // Prevent instantiation
  ColorUtils._();

  // ========== WCAG Contrast Calculations ==========

  /// Calculates the relative luminance of a color according to WCAG 2.0.
  ///
  /// Returns a value between 0.0 (darkest black) and 1.0 (lightest white).
  ///
  /// Reference: https://www.w3.org/TR/WCAG20/#relativeluminancedef
  static double calculateRelativeLuminance(Color color) {
    // Convert RGB to 0-1 range
    final r = color.red / 255.0;
    final g = color.green / 255.0;
    final b = color.blue / 255.0;

    // Apply sRGB to linear RGB conversion
    final rLinear = _sRGBtoLinear(r);
    final gLinear = _sRGBtoLinear(g);
    final bLinear = _sRGBtoLinear(b);

    // Calculate relative luminance
    return 0.2126 * rLinear + 0.7152 * gLinear + 0.0722 * bLinear;
  }

  /// Calculates the contrast ratio between two colors according to WCAG 2.0.
  ///
  /// Returns a value >= 1.0, where 21.0 is the maximum contrast (black vs white).
  ///
  /// Reference: https://www.w3.org/TR/WCAG20/#contrast-ratiodef
  static double calculateContrastRatio(Color color1, Color color2) {
    final lum1 = calculateRelativeLuminance(color1);
    final lum2 = calculateRelativeLuminance(color2);

    final lighter = math.max(lum1, lum2);
    final darker = math.min(lum1, lum2);

    return (lighter + 0.05) / (darker + 0.05);
  }

  /// Checks if two colors meet WCAG AA contrast requirements.
  ///
  /// - Normal text requires 4.5:1 contrast ratio
  /// - Large text requires 3:1 contrast ratio
  static bool meetsWCAG_AA(Color foreground, Color background, {required bool isLargeText}) {
    final ratio = calculateContrastRatio(foreground, background);
    return isLargeText ? ratio >= 3.0 : ratio >= 4.5;
  }

  /// Checks if two colors meet WCAG AAA contrast requirements.
  ///
  /// - Normal text requires 7:1 contrast ratio
  /// - Large text requires 4.5:1 contrast ratio
  static bool meetsWCAG_AAA(Color foreground, Color background, {required bool isLargeText}) {
    final ratio = calculateContrastRatio(foreground, background);
    return isLargeText ? ratio >= 4.5 : ratio >= 7.0;
  }

  // ========== Colorblind Simulation ==========

  /// Simulates how a color appears to someone with Protanopia (red-blind).
  ///
  /// Uses the Brettel, Viénot and Mollon (1997) algorithm.
  static Color simulateProtanopia(Color color) {
    return _simulateColorblindness(color, _protanopiaMatrix);
  }

  /// Simulates how a color appears to someone with Deuteranopia (green-blind).
  ///
  /// Uses the Brettel, Viénot and Mollon (1997) algorithm.
  static Color simulateDeuteranopia(Color color) {
    return _simulateColorblindness(color, _deuteranopiaMatrix);
  }

  /// Simulates how a color appears to someone with Tritanopia (blue-blind).
  ///
  /// Uses the Brettel, Viénot and Mollon (1997) algorithm.
  static Color simulateTritanopia(Color color) {
    return _simulateColorblindness(color, _tritanopiaMatrix);
  }

  // ========== Color Palette Generation ==========

  /// Generates a colorblind-friendly palette using the Okabe-Ito color scheme.
  ///
  /// Returns [count] distinct colors that are distinguishable to people with
  /// various forms of colorblindness.
  ///
  /// The palette is based on:
  /// - Okabe, M., and K. Ito. 2008. "Color Universal Design (CUD)"
  static List<Color> generateColorblindFriendlyPalette(int count) {
    assert(count > 0, 'count must be > 0');

    // Okabe-Ito color palette (colorblind-friendly)
    // Ordered to maximize contrast between adjacent colors
    const okabeItoPalette = [
      Color(0xFF0173B2), // Blue
      Color(0xFFECE133), // Yellow (high contrast with blue)
      Color(0xFFD55E00), // Vermillion (high contrast with yellow)
      Color(0xFF56B4E9), // Light Blue (high contrast with vermillion)
      Color(0xFF029E73), // Teal
      Color(0xFFF0E442), // Light Yellow
      Color(0xFFCC78BC), // Pink
      Color(0xFFCA9161), // Brown
      Color(0xFFDE8F05), // Orange
    ];

    // Repeat the palette if more colors are needed
    final result = <Color>[];
    for (int i = 0; i < count; i++) {
      result.add(okabeItoPalette[i % okabeItoPalette.length]);
    }

    return result;
  }

  // ========== Color Serialization ==========

  /// Converts a Color to a hex string in the format #AARRGGBB.
  static String colorToHex(Color color) {
    return '#${color.value.toRadixString(16).padLeft(8, '0').toUpperCase()}';
  }

  /// Parses a hex string to a Color.
  ///
  /// Accepts formats: #RGB, #RRGGBB, #AARRGGBB
  /// Also accepts without the # prefix.
  static Color hexToColor(String hex) {
    String hexValue = hex.replaceFirst('#', '');

    // Handle short forms
    if (hexValue.length == 3) {
      // #RGB -> #FFRRGGBB
      hexValue = 'FF${hexValue[0]}${hexValue[0]}${hexValue[1]}${hexValue[1]}${hexValue[2]}${hexValue[2]}';
    } else if (hexValue.length == 6) {
      // #RRGGBB -> #FFRRGGBB
      hexValue = 'FF$hexValue';
    } else if (hexValue.length != 8) {
      throw Exception('Invalid hex color format: $hex');
    }

    final intValue = int.tryParse(hexValue, radix: 16);
    if (intValue == null) {
      throw Exception('Invalid hex color format: $hex');
    }

    return Color(intValue);
  }

  // ========== Helper Methods ==========

  /// Converts sRGB component to linear RGB.
  static double _sRGBtoLinear(double component) {
    if (component <= 0.03928) {
      return component / 12.92;
    } else {
      return math.pow((component + 0.055) / 1.055, 2.4).toDouble();
    }
  }

  /// Applies a colorblind simulation matrix to a color.
  static Color _simulateColorblindness(Color color, List<List<double>> matrix) {
    final r = color.red / 255.0;
    final g = color.green / 255.0;
    final b = color.blue / 255.0;

    final newR = (r * matrix[0][0] + g * matrix[0][1] + b * matrix[0][2]).clamp(0.0, 1.0);
    final newG = (r * matrix[1][0] + g * matrix[1][1] + b * matrix[1][2]).clamp(0.0, 1.0);
    final newB = (r * matrix[2][0] + g * matrix[2][1] + b * matrix[2][2]).clamp(0.0, 1.0);

    return Color.fromARGB(
      color.alpha,
      (newR * 255).round(),
      (newG * 255).round(),
      (newB * 255).round(),
    );
  }

  // ========== Colorblind Simulation Matrices ==========
  // Based on Brettel, Viénot and Mollon (1997)

  static const _protanopiaMatrix = [
    [0.567, 0.433, 0.000],
    [0.558, 0.442, 0.000],
    [0.000, 0.242, 0.758],
  ];

  static const _deuteranopiaMatrix = [
    [0.625, 0.375, 0.000],
    [0.700, 0.300, 0.000],
    [0.000, 0.300, 0.700],
  ];

  static const _tritanopiaMatrix = [
    [0.950, 0.050, 0.000],
    [0.000, 0.433, 0.567],
    [0.000, 0.475, 0.525],
  ];
}
