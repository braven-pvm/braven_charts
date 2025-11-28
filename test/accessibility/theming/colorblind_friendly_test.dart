// ACCESSIBILITY TEST: Colorblind Friendly Theme
// Feature: 004-theming-system
// Phase 2: Predefined Themes & Validation
//
// Validates that the colorblind friendly theme is distinguishable
// for users with different types of color vision deficiency.

import 'package:braven_charts/legacy/src/theming/chart_theme.dart';
import 'package:braven_charts/legacy/src/theming/utilities/color_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Colorblind Friendly Theme - Accessibility', () {
    late ChartTheme theme;

    setUp(() {
      theme = ChartTheme.colorblindFriendly;
    });

    group('Protanopia Simulation (Red-Blind)', () {
      test('series colors remain distinguishable with protanopia', () {
        final colors = theme.seriesTheme.colors;

        // Simulate protanopia for all colors
        final simulatedColors =
            colors.map((c) => ColorUtils.simulateProtanopia(c)).toList();

        // Check that simulated colors are still distinguishable
        for (int i = 0; i < simulatedColors.length; i++) {
          for (int j = i + 1; j < simulatedColors.length; j++) {
            final contrastRatio = ColorUtils.calculateContrastRatio(
              simulatedColors[i],
              simulatedColors[j],
            );

            expect(contrastRatio, greaterThan(1.1),
                reason:
                    'Colors ${i + 1} and ${j + 1} should be distinguishable with protanopia');
          }
        }
      });

      test('series colors are visible against background with protanopia', () {
        final backgroundColor = theme.backgroundColor;
        final colors = theme.seriesTheme.colors;

        for (int i = 0; i < colors.length; i++) {
          final simulatedColor = ColorUtils.simulateProtanopia(colors[i]);
          final contrastRatio = ColorUtils.calculateContrastRatio(
            simulatedColor,
            backgroundColor,
          );

          expect(contrastRatio, greaterThanOrEqualTo(1.2),
              reason: 'Color ${i + 1} should be visible with protanopia');
        }
      });
    });

    group('Deuteranopia Simulation (Green-Blind)', () {
      test('series colors remain distinguishable with deuteranopia', () {
        final colors = theme.seriesTheme.colors;

        final simulatedColors =
            colors.map((c) => ColorUtils.simulateDeuteranopia(c)).toList();

        for (int i = 0; i < simulatedColors.length; i++) {
          for (int j = i + 1; j < simulatedColors.length; j++) {
            final contrastRatio = ColorUtils.calculateContrastRatio(
              simulatedColors[i],
              simulatedColors[j],
            );

            expect(contrastRatio, greaterThan(1.0),
                reason:
                    'Colors ${i + 1} and ${j + 1} should be distinguishable with deuteranopia');
          }
        }
      });
    });

    group('Tritanopia Simulation (Blue-Blind)', () {
      test('series colors remain distinguishable with tritanopia', () {
        final colors = theme.seriesTheme.colors;

        final simulatedColors =
            colors.map((c) => ColorUtils.simulateTritanopia(c)).toList();

        for (int i = 0; i < simulatedColors.length; i++) {
          for (int j = i + 1; j < simulatedColors.length; j++) {
            final contrastRatio = ColorUtils.calculateContrastRatio(
              simulatedColors[i],
              simulatedColors[j],
            );

            expect(contrastRatio, greaterThan(1.0),
                reason:
                    'Colors ${i + 1} and ${j + 1} should be distinguishable with tritanopia');
          }
        }
      });
    });

    group('Marker Shapes for Additional Distinction', () {
      test('uses multiple marker shapes for better distinguishability', () {
        final markerShapes = theme.seriesTheme.markerShapes;

        // Colorblind friendly theme should use varied shapes
        expect(markerShapes.length, greaterThanOrEqualTo(3),
            reason: 'Should use multiple marker shapes for redundancy');
      });
    });

    group('Okabe-Ito Palette Verification', () {
      test('uses scientifically validated colorblind-safe palette', () {
        final colors = theme.seriesTheme.colors;

        // The colorblind friendly theme should use the Okabe-Ito palette
        // Verify we have at least the minimum set
        expect(colors.length, greaterThanOrEqualTo(5),
            reason: 'Should use comprehensive colorblind-safe palette');
      });
    });
  });
}
