// ACCESSIBILITY TEST: Default Dark Theme
// Feature: 004-theming-system
// Phase 2: Predefined Themes & Validation
//
// Validates WCAG AA compliance for the default dark theme.

import 'package:braven_charts/src/theming/chart_theme.dart';
import 'package:braven_charts/src/theming/utilities/color_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Default Dark Theme - WCAG AA Compliance', () {
    late ChartTheme theme;

    setUp(() {
      theme = ChartTheme.defaultDark;
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

    group('Series Colors', () {
      test('series colors are distinguishable', () {
        final colors = theme.seriesTheme.colors;

        for (int i = 0; i < colors.length; i++) {
          for (int j = i + 1; j < colors.length; j++) {
            final contrastRatio = ColorUtils.calculateContrastRatio(colors[i], colors[j]);
            expect(contrastRatio, greaterThan(1.0),
                reason: 'Series colors ${i + 1} and ${j + 1} should be distinguishable');
          }
        }
      });

      test('series colors are visible against dark background', () {
        final backgroundColor = theme.backgroundColor;
        final colors = theme.seriesTheme.colors;

        for (int i = 0; i < colors.length; i++) {
          final contrastRatio = ColorUtils.calculateContrastRatio(
            colors[i],
            backgroundColor,
          );

          expect(contrastRatio, greaterThanOrEqualTo(2.0),
              reason: 'Series color ${i + 1} should be visible on dark background');
        }
      });
    });

    group('Overall Theme Validation', () {
      test('theme is a dark theme (dark background)', () {
        final backgroundColor = theme.backgroundColor;
        final luminance = ColorUtils.calculateRelativeLuminance(backgroundColor);

        expect(luminance, lessThan(0.5),
            reason: 'Default dark theme should have a dark background');
      });
    });
  });
}
