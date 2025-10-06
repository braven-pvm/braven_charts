// CONTRACT: ColorUtils
// Feature: 004-theming-system
//
// Color accessibility and manipulation utilities.
// Provides WCAG 2.1 compliance checks and colorblind simulation.

import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Utility functions for color accessibility and manipulation.
///
/// Provides:
/// - WCAG 2.1 contrast ratio calculations
/// - Automatic text color selection for accessibility
/// - Colorblind simulation (Brettel algorithm)
/// - Grayscale conversion
/// - Color distance calculations (ΔE in CIELAB)
///
/// Example:
/// ```dart
/// final bg = Color(0xFF1976D2);
/// final textColor = ColorUtils.autoContrastText(bg); // Returns white or black
/// final ratio = ColorUtils.contrastRatio(textColor, bg); // >= 4.5 for WCAG AA
///
/// final protanopiaView = ColorUtils.simulateProtanopia(Color(0xFFFF0000));
/// ```
class ColorUtils {
  ColorUtils._(); // Private constructor - static utility class

  // ========== WCAG 2.1 Compliance ==========

  /// Calculates relative luminance per WCAG 2.1 specification.
  ///
  /// Returns value between 0.0 (darkest) and 1.0 (lightest).
  ///
  /// Reference: https://www.w3.org/TR/WCAG21/#dfn-relative-luminance
  static double relativeLuminance(Color color) {
    final r = _sRGBtoLinear(color.red / 255.0);
    final g = _sRGBtoLinear(color.green / 255.0);
    final b = _sRGBtoLinear(color.blue / 255.0);
    return 0.2126 * r + 0.7152 * g + 0.0722 * b;
  }

  static double _sRGBtoLinear(double channel) {
    if (channel <= 0.03928) {
      return channel / 12.92;
    } else {
      return math.pow((channel + 0.055) / 1.055, 2.4).toDouble();
    }
  }

  /// Calculates contrast ratio per WCAG 2.1 specification.
  ///
  /// Returns value between 1.0 (no contrast) and 21.0 (maximum contrast).
  ///
  /// WCAG 2.1 Requirements:
  /// - AA (normal text): >= 4.5:1
  /// - AA (large text 18pt+): >= 3.0:1
  /// - AAA (normal text): >= 7.0:1
  /// - AAA (large text 18pt+): >= 4.5:1
  ///
  /// Reference: https://www.w3.org/TR/WCAG21/#dfn-contrast-ratio
  static double contrastRatio(Color c1, Color c2) {
    final l1 = relativeLuminance(c1);
    final l2 = relativeLuminance(c2);
    final lighter = math.max(l1, l2);
    final darker = math.min(l1, l2);
    return (lighter + 0.05) / (darker + 0.05);
  }

  /// Checks if color pair meets WCAG 2.1 AA (normal text).
  static bool isWCAG_AA(Color text, Color background) {
    return contrastRatio(text, background) >= 4.5;
  }

  /// Checks if color pair meets WCAG 2.1 AA (large text 18pt+).
  static bool isWCAG_AA_Large(Color text, Color background) {
    return contrastRatio(text, background) >= 3.0;
  }

  /// Checks if color pair meets WCAG 2.1 AAA (normal text).
  static bool isWCAG_AAA(Color text, Color background) {
    return contrastRatio(text, background) >= 7.0;
  }

  /// Checks if color pair meets WCAG 2.1 AAA (large text 18pt+).
  static bool isWCAG_AAA_Large(Color text, Color background) {
    return contrastRatio(text, background) >= 4.5;
  }

  /// Automatically selects black or white text color for best contrast.
  ///
  /// Returns Color(0xFF000000) or Color(0xFFFFFFFF) based on which
  /// provides better contrast with the background.
  static Color autoContrastText(Color background) {
    final whiteContrast = contrastRatio(const Color(0xFFFFFFFF), background);
    final blackContrast = contrastRatio(const Color(0xFF000000), background);
    return whiteContrast > blackContrast ? const Color(0xFFFFFFFF) : const Color(0xFF000000);
  }

  // ========== Colorblind Simulation ==========

  /// Simulates protanopia (L-cone deficiency, red-blind).
  ///
  /// Uses Brettel et al. algorithm for dichromatic simulation.
  /// Reference: Brettel, H., Viénot, F., & Mollon, J. D. (1997)
  /// "Computerized simulation of color appearance for dichromats"
  static Color simulateProtanopia(Color color) {
    return _simulateDichromacy(color, _protanopiaMatrix);
  }

  /// Simulates deuteranopia (M-cone deficiency, green-blind).
  static Color simulateDeuteranopia(Color color) {
    return _simulateDichromacy(color, _deuteranopiaMatrix);
  }

  /// Simulates tritanopia (S-cone deficiency, blue-blind).
  static Color simulateTritanopia(Color color) {
    return _simulateDichromacy(color, _tritanopiaMatrix);
  }

  static Color _simulateDichromacy(Color color, List<double> matrix) {
    // Convert RGB → LMS (cone response)
    final r = color.red / 255.0;
    final g = color.green / 255.0;
    final b = color.blue / 255.0;

    final l = 0.31399 * r + 0.63951 * g + 0.04649 * b;
    final m = 0.15537 * r + 0.75789 * g + 0.08673 * b;
    final s = 0.01775 * r + 0.10944 * g + 0.87281 * b;

    // Apply dichromatic transformation
    final lSim = matrix[0] * l + matrix[1] * m + matrix[2] * s;
    final mSim = matrix[3] * l + matrix[4] * m + matrix[5] * s;
    final sSim = matrix[6] * l + matrix[7] * m + matrix[8] * s;

    // Convert LMS → RGB
    final rSim = 5.47221 * lSim - 4.6419 * mSim + 0.16969 * sSim;
    final gSim = -1.1252 * lSim + 2.29317 * mSim - 0.16798 * sSim;
    final bSim = 0.02980 * lSim - 0.19318 * mSim + 1.16338 * sSim;

    return Color.fromARGB(
      color.alpha,
      (rSim * 255).clamp(0, 255).round(),
      (gSim * 255).clamp(0, 255).round(),
      (bSim * 255).clamp(0, 255).round(),
    );
  }

  // Brettel transformation matrices (simplified for protanopia/deuteranopia/tritanopia)
  static const List<double> _protanopiaMatrix = [
    0.0,
    1.05118,
    -0.05116,
    0.0,
    1.0,
    0.0,
    0.0,
    0.0,
    1.0,
  ];

  static const List<double> _deuteranopiaMatrix = [
    1.0,
    0.0,
    0.0,
    0.9513,
    0.0,
    0.04866,
    0.0,
    0.0,
    1.0,
  ];

  static const List<double> _tritanopiaMatrix = [
    1.0,
    0.0,
    0.0,
    0.0,
    1.0,
    0.0,
    -0.86744,
    1.86727,
    0.0,
  ];

  // ========== Color Manipulation ==========

  /// Converts color to grayscale using luminance-preserving algorithm.
  static Color toGrayscale(Color color) {
    final luminance = relativeLuminance(color);
    final gray = (luminance * 255).round();
    return Color.fromARGB(color.alpha, gray, gray, gray);
  }

  /// Calculates color distance using ΔE (Delta-E) in CIELAB color space.
  ///
  /// Returns value >= 0. Typical interpretation:
  /// - ΔE < 1: Not perceptible by human eyes
  /// - ΔE 1-2: Perceptible through close observation
  /// - ΔE 2-10: Perceptible at a glance
  /// - ΔE > 10: Colors perceived as different
  /// - ΔE > 40: Good separation for data visualization
  static double colorDistance(Color c1, Color c2) {
    final lab1 = _rgbToLab(c1);
    final lab2 = _rgbToLab(c2);

    final deltaL = lab1[0] - lab2[0];
    final deltaA = lab1[1] - lab2[1];
    final deltaB = lab1[2] - lab2[2];

    return math.sqrt(deltaL * deltaL + deltaA * deltaA + deltaB * deltaB);
  }

  static List<double> _rgbToLab(Color color) {
    // RGB → XYZ
    var r = color.red / 255.0;
    var g = color.green / 255.0;
    var b = color.blue / 255.0;

    r = r > 0.04045 ? math.pow((r + 0.055) / 1.055, 2.4).toDouble() : r / 12.92;
    g = g > 0.04045 ? math.pow((g + 0.055) / 1.055, 2.4).toDouble() : g / 12.92;
    b = b > 0.04045 ? math.pow((b + 0.055) / 1.055, 2.4).toDouble() : b / 12.92;

    var x = r * 0.4124 + g * 0.3576 + b * 0.1805;
    var y = r * 0.2126 + g * 0.7152 + b * 0.0722;
    var z = r * 0.0193 + g * 0.1192 + b * 0.9505;

    // XYZ → LAB (D65 illuminant)
    x = x / 0.95047;
    y = y / 1.00000;
    z = z / 1.08883;

    x = x > 0.008856 ? math.pow(x, 1 / 3).toDouble() : (7.787 * x) + (16 / 116);
    y = y > 0.008856 ? math.pow(y, 1 / 3).toDouble() : (7.787 * y) + (16 / 116);
    z = z > 0.008856 ? math.pow(z, 1 / 3).toDouble() : (7.787 * z) + (16 / 116);

    final L = (116 * y) - 16;
    final a = 500 * (x - y);
    final bVal = 200 * (y - z);

    return [L, a, bVal];
  }
}
