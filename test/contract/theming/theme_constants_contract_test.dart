// Theme Constants Contract Test
// Feature: 004-theming-system
// Phase 2: Predefined Themes & Validation (T025)

import 'package:braven_charts/src/theming/constants/theme_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ThemeConstants - Color Palettes', () {
    test('corporateBluePalette has 5 professional blue-toned colors', () {
      expect(ThemeConstants.corporateBluePalette.length, equals(5));
      expect(ThemeConstants.corporateBluePalette, isNotEmpty);
      expect(ThemeConstants.corporateBluePalette, everyElement(isA<Color>()));
    });

    test('vibrantPalette has 6 high-saturation colors', () {
      expect(ThemeConstants.vibrantPalette.length, equals(6));
      expect(ThemeConstants.vibrantPalette, isNotEmpty);
      expect(ThemeConstants.vibrantPalette, everyElement(isA<Color>()));
    });

    test('colorblindSafePalette has 6 Okabe-Ito colors', () {
      expect(ThemeConstants.colorblindSafePalette.length, equals(6));
      expect(ThemeConstants.colorblindSafePalette, isNotEmpty);
      expect(ThemeConstants.colorblindSafePalette, everyElement(isA<Color>()));

      // Verify it matches the Okabe-Ito standard colors
      expect(ThemeConstants.colorblindSafePalette[0].value, equals(0xFF0173B2)); // Blue
      expect(ThemeConstants.colorblindSafePalette[1].value, equals(0xFFDE8F05)); // Orange
      expect(ThemeConstants.colorblindSafePalette[2].value, equals(0xFF029E73)); // Teal
      expect(ThemeConstants.colorblindSafePalette[3].value, equals(0xFFCC78BC)); // Pink
      expect(ThemeConstants.colorblindSafePalette[4].value, equals(0xFFECE133)); // Yellow
      expect(ThemeConstants.colorblindSafePalette[5].value, equals(0xFF56B4E9)); // Light Blue
    });

    test('minimalPalette has 3 gray shades', () {
      expect(ThemeConstants.minimalPalette.length, equals(3));
      expect(ThemeConstants.minimalPalette, isNotEmpty);
      expect(ThemeConstants.minimalPalette, everyElement(isA<Color>()));
    });

    test('highContrastPalette has 4 extreme contrast colors', () {
      expect(ThemeConstants.highContrastPalette.length, equals(4));
      expect(ThemeConstants.highContrastPalette, isNotEmpty);
      expect(ThemeConstants.highContrastPalette, everyElement(isA<Color>()));

      // Verify extreme contrast colors
      expect(ThemeConstants.highContrastPalette[0].value, equals(0xFF000000)); // Black
      expect(ThemeConstants.highContrastPalette[1].value, equals(0xFFFFFFFF)); // White
      expect(ThemeConstants.highContrastPalette[2].value, equals(0xFFFF0000)); // Red
      expect(ThemeConstants.highContrastPalette[3].value, equals(0xFF0000FF)); // Blue
    });
  });

  group('ThemeConstants - Typography Breakpoints', () {
    test('breakpoint constants are correctly defined', () {
      expect(ThemeConstants.mobileBreakpoint, equals(600.0));
      expect(ThemeConstants.tabletBreakpoint, equals(1024.0));
      expect(ThemeConstants.desktopBreakpoint, equals(1024.0));
    });

    test('scale factors are correctly defined', () {
      expect(ThemeConstants.mobileScaleFactor, equals(0.9));
      expect(ThemeConstants.tabletScaleFactor, equals(1.0));
      expect(ThemeConstants.desktopScaleFactor, equals(1.1));
    });

    test('getTypographyScaleFactor returns mobile scale for widths < 600', () {
      expect(ThemeConstants.getTypographyScaleFactor(0.0), equals(0.9));
      expect(ThemeConstants.getTypographyScaleFactor(300.0), equals(0.9));
      expect(ThemeConstants.getTypographyScaleFactor(599.0), equals(0.9));
    });

    test('getTypographyScaleFactor returns tablet scale for widths 600-1023', () {
      expect(ThemeConstants.getTypographyScaleFactor(600.0), equals(1.0));
      expect(ThemeConstants.getTypographyScaleFactor(800.0), equals(1.0));
      expect(ThemeConstants.getTypographyScaleFactor(1023.0), equals(1.0));
    });

    test('getTypographyScaleFactor returns desktop scale for widths >= 1024', () {
      expect(ThemeConstants.getTypographyScaleFactor(1024.0), equals(1.1));
      expect(ThemeConstants.getTypographyScaleFactor(1920.0), equals(1.1));
      expect(ThemeConstants.getTypographyScaleFactor(3840.0), equals(1.1));
    });
  });

  group('ThemeConstants - Validation Minimums', () {
    test('minimum font size is 10.0 logical pixels', () {
      expect(ThemeConstants.minFontSize, equals(10.0));
    });

    test('minimum line width is 0.5 logical pixels', () {
      expect(ThemeConstants.minLineWidth, equals(0.5));
    });

    test('minimum marker size is 3.0 logical pixels', () {
      expect(ThemeConstants.minMarkerSize, equals(3.0));
    });

    test('minimum padding is 8.0 logical pixels', () {
      expect(ThemeConstants.minPadding, equals(8.0));
    });

    test('all minimums are positive', () {
      expect(ThemeConstants.minFontSize, greaterThan(0.0));
      expect(ThemeConstants.minLineWidth, greaterThan(0.0));
      expect(ThemeConstants.minMarkerSize, greaterThan(0.0));
      expect(ThemeConstants.minPadding, greaterThan(0.0));
    });

    test('minimums are reasonable for accessibility', () {
      // WCAG 2.1 recommends 10-12px minimum font size
      expect(ThemeConstants.minFontSize, greaterThanOrEqualTo(10.0));

      // Line widths should be visible but not intrusive
      expect(ThemeConstants.minLineWidth, greaterThanOrEqualTo(0.5));
      expect(ThemeConstants.minLineWidth, lessThan(5.0));

      // Marker sizes should be visible
      expect(ThemeConstants.minMarkerSize, greaterThanOrEqualTo(3.0));

      // Padding should provide breathing room
      expect(ThemeConstants.minPadding, greaterThanOrEqualTo(8.0));
    });
  });

  group('ThemeConstants - Integration', () {
    test('palettes contain no duplicate colors within themselves', () {
      // Check each palette individually
      expect(
        ThemeConstants.corporateBluePalette.toSet().length,
        equals(ThemeConstants.corporateBluePalette.length),
        reason: 'corporateBluePalette should have no duplicate colors',
      );

      expect(
        ThemeConstants.vibrantPalette.toSet().length,
        equals(ThemeConstants.vibrantPalette.length),
        reason: 'vibrantPalette should have no duplicate colors',
      );

      expect(
        ThemeConstants.colorblindSafePalette.toSet().length,
        equals(ThemeConstants.colorblindSafePalette.length),
        reason: 'colorblindSafePalette should have no duplicate colors',
      );

      expect(
        ThemeConstants.minimalPalette.toSet().length,
        equals(ThemeConstants.minimalPalette.length),
        reason: 'minimalPalette should have no duplicate colors',
      );

      expect(
        ThemeConstants.highContrastPalette.toSet().length,
        equals(ThemeConstants.highContrastPalette.length),
        reason: 'highContrastPalette should have no duplicate colors',
      );
    });

    test('breakpoints are in ascending order', () {
      expect(ThemeConstants.mobileBreakpoint, lessThanOrEqualTo(ThemeConstants.tabletBreakpoint));
      expect(ThemeConstants.tabletBreakpoint, lessThanOrEqualTo(ThemeConstants.desktopBreakpoint));
    });

    test('scale factors progress logically (mobile < tablet < desktop)', () {
      expect(ThemeConstants.mobileScaleFactor, lessThan(ThemeConstants.tabletScaleFactor));
      expect(ThemeConstants.tabletScaleFactor, lessThan(ThemeConstants.desktopScaleFactor));
    });

    test('scale factors are reasonable (0.8-1.2 range)', () {
      expect(ThemeConstants.mobileScaleFactor, greaterThanOrEqualTo(0.8));
      expect(ThemeConstants.mobileScaleFactor, lessThanOrEqualTo(1.0));

      expect(ThemeConstants.tabletScaleFactor, equals(1.0));

      expect(ThemeConstants.desktopScaleFactor, greaterThanOrEqualTo(1.0));
      expect(ThemeConstants.desktopScaleFactor, lessThanOrEqualTo(1.2));
    });
  });
}
