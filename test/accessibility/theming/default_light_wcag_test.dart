// ACCESSIBILITY TEST: Default Light Theme
// Feature: 004-theming-system
// Phase 2: Predefined Themes & Validation
//
// Validates WCAG AA compliance for the default light theme.

import 'package:braven_charts/src/theming/chart_theme.dart';
import 'package:braven_charts/src/theming/utilities/color_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Default Light Theme - WCAG AA Compliance', () {
    late ChartTheme theme;

    setUp(() {
      theme = ChartTheme.defaultLight;
    });

    group('Background and Text Contrast', () {
      test('axis labels have sufficient contrast with background (>= 4.5:1)', () {
        final backgroundColor = theme.backgroundColor;
        final labelColor = theme.axisStyle.labelStyle.color!;

        final contrastRatio = ColorUtils.calculateContrastRatio(
          labelColor,
          backgroundColor,
        );

        expect(contrastRatio, greaterThanOrEqualTo(4.5),
            reason: 'Axis labels must meet WCAG AA for normal text (4.5:1). '
                'Found: ${contrastRatio.toStringAsFixed(2)}:1');
      });

      test('axis titles have sufficient contrast with background (>= 4.5:1)', () {
        final backgroundColor = theme.backgroundColor;
        final titleColor = theme.axisStyle.titleStyle.color!;

        final contrastRatio = ColorUtils.calculateContrastRatio(
          titleColor,
          backgroundColor,
        );

        expect(contrastRatio, greaterThanOrEqualTo(4.5),
            reason: 'Axis titles must meet WCAG AA for normal text (4.5:1). '
                'Found: ${contrastRatio.toStringAsFixed(2)}:1');
      });

      test('grid lines are visible (even if subtle)', () {
        final backgroundColor = theme.backgroundColor;
        final gridColor = theme.gridStyle.majorColor;

        final contrastRatio = ColorUtils.calculateContrastRatio(
          gridColor,
          backgroundColor,
        );

        // Grid lines can be subtle for minimal themes
        expect(contrastRatio, greaterThanOrEqualTo(1.1),
            reason: 'Grid lines should be visible. '
                'Found: ${contrastRatio.toStringAsFixed(2)}:1');
      });
    });

    group('Tooltip Contrast', () {
      test('tooltip text has sufficient contrast with tooltip background (>= 4.5:1)', () {
        final tooltipBackground = theme.interactionTheme.tooltipBackground;
        final tooltipTextColor = theme.interactionTheme.tooltipTextStyle.color!;

        final contrastRatio = ColorUtils.calculateContrastRatio(
          tooltipTextColor,
          tooltipBackground,
        );

        expect(contrastRatio, greaterThanOrEqualTo(4.5),
            reason: 'Tooltip text must meet WCAG AA for normal text (4.5:1). '
                'Found: ${contrastRatio.toStringAsFixed(2)}:1');
      });
    });

    group('Series Colors Distinguishability', () {
      test('series colors are distinguishable from each other', () {
        final colors = theme.seriesTheme.colors;

        // Check each pair of colors
        for (int i = 0; i < colors.length; i++) {
          for (int j = i + 1; j < colors.length; j++) {
            final color1 = colors[i];
            final color2 = colors[j];

            // Calculate contrast ratio (basic distinguishability check)
            final contrastRatio = ColorUtils.calculateContrastRatio(color1, color2);

            // Colors should be at least somewhat different
            expect(contrastRatio, greaterThan(1.1),
                reason: 'Series colors ${i + 1} and ${j + 1} should be distinguishable. '
                    'Found contrast: ${contrastRatio.toStringAsFixed(2)}:1');
          }
        }
      });

      test('series colors are visible against white background', () {
        final backgroundColor = theme.backgroundColor;
        final colors = theme.seriesTheme.colors;

        for (int i = 0; i < colors.length; i++) {
          final contrastRatio = ColorUtils.calculateContrastRatio(
            colors[i],
            backgroundColor,
          );

          // Series colors should be visible on the background (relaxed threshold for color variety)
          expect(contrastRatio, greaterThanOrEqualTo(2.0),
              reason: 'Series color ${i + 1} should be visible on white background. '
                  'Found: ${contrastRatio.toStringAsFixed(2)}:1');
        }
      });
    });

    group('Interactive Elements', () {
      test('crosshair has sufficient contrast with background', () {
        final backgroundColor = theme.backgroundColor;
        final crosshairColor = theme.interactionTheme.crosshairColor;

        final contrastRatio = ColorUtils.calculateContrastRatio(
          crosshairColor,
          backgroundColor,
        );

        expect(contrastRatio, greaterThanOrEqualTo(3.0),
            reason: 'Crosshair should be visible. '
                'Found: ${contrastRatio.toStringAsFixed(2)}:1');
      });

      test('selection highlight is visible', () {
        final selectionColor = theme.interactionTheme.selectionColor;

        // Selection uses semi-transparent color, so we need to composite it
        // For now, just check that it has some opacity
        expect(selectionColor.alpha, greaterThan(0), reason: 'Selection color should be visible (not fully transparent)');
        expect(selectionColor.alpha, lessThan(255), reason: 'Selection color should be semi-transparent for better UX');
      });
    });

    group('Overall Theme Validation', () {
      test('theme is a light theme (light background)', () {
        final backgroundColor = theme.backgroundColor;
        final luminance = ColorUtils.calculateRelativeLuminance(backgroundColor);

        expect(luminance, greaterThan(0.5),
            reason: 'Default light theme should have a light background. '
                'Found luminance: ${luminance.toStringAsFixed(2)}');
      });

      test('border color is visible against background', () {
        final backgroundColor = theme.backgroundColor;
        final borderColor = theme.borderColor;

        final contrastRatio = ColorUtils.calculateContrastRatio(
          borderColor,
          backgroundColor,
        );

        expect(contrastRatio, greaterThanOrEqualTo(1.1),
            reason: 'Border should be visible. '
                'Found: ${contrastRatio.toStringAsFixed(2)}:1');
      });
    });
  });
}
