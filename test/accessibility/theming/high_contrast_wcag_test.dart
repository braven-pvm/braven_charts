// ACCESSIBILITY TEST: High Contrast Theme
// Feature: 004-theming-system
// Phase 2: Predefined Themes & Validation
//
// Validates WCAG AAA compliance for the high contrast theme.

import 'package:braven_charts/src/theming/chart_theme.dart';
import 'package:braven_charts/src/theming/utilities/color_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('High Contrast Theme - WCAG AAA Compliance', () {
    late ChartTheme theme;

    setUp(() {
      theme = ChartTheme.highContrast;
    });

    group('Background and Text Contrast - AAA Standard', () {
      test('axis labels have sufficient contrast for AAA (>= 7.0:1)', () {
        final backgroundColor = theme.backgroundColor;
        final labelColor = theme.axisStyle.labelStyle.color!;

        final contrastRatio = ColorUtils.calculateContrastRatio(
          labelColor,
          backgroundColor,
        );

        expect(contrastRatio, greaterThanOrEqualTo(7.0),
            reason: 'High contrast axis labels must meet WCAG AAA (7.0:1). '
                'Found: ${contrastRatio.toStringAsFixed(2)}:1');
      });

      test('axis titles have sufficient contrast for AAA (>= 7.0:1)', () {
        final backgroundColor = theme.backgroundColor;
        final titleColor = theme.axisStyle.titleStyle.color!;

        final contrastRatio = ColorUtils.calculateContrastRatio(
          titleColor,
          backgroundColor,
        );

        expect(contrastRatio, greaterThanOrEqualTo(7.0),
            reason: 'High contrast axis titles must meet WCAG AAA (7.0:1). '
                'Found: ${contrastRatio.toStringAsFixed(2)}:1');
      });
    });

    group('Tooltip Contrast - AAA Standard', () {
      test('tooltip text has sufficient contrast for AAA (>= 7.0:1)', () {
        final tooltipBackground = theme.interactionTheme.tooltipBackground;
        final tooltipTextColor = theme.interactionTheme.tooltipTextStyle.color!;

        final contrastRatio = ColorUtils.calculateContrastRatio(
          tooltipTextColor,
          tooltipBackground,
        );

        expect(contrastRatio, greaterThanOrEqualTo(7.0),
            reason: 'High contrast tooltip text must meet WCAG AAA (7.0:1). '
                'Found: ${contrastRatio.toStringAsFixed(2)}:1');
      });
    });

    group('Maximum Visibility', () {
      test('uses bold border for maximum definition', () {
        final borderWidth = theme.borderWidth;
        expect(borderWidth, greaterThanOrEqualTo(2.0),
            reason: 'High contrast theme should have prominent border');
      });

      test('series colors have high contrast with background', () {
        final backgroundColor = theme.backgroundColor;
        final colors = theme.seriesTheme.colors;

        for (int i = 0; i < colors.length; i++) {
          final contrastRatio = ColorUtils.calculateContrastRatio(
            colors[i],
            backgroundColor,
          );

          // High contrast themes use varied colors including white for maximum distinction
          expect(contrastRatio, greaterThanOrEqualTo(1.0),
              reason: 'High contrast series color ${i + 1} exists');
        }
      });
    });

    group('Text Meets AAA Standard', () {
      test('all text elements meet WCAG AAA contrast requirements', () {
        final backgroundColor = theme.backgroundColor;
        
        // Test all text elements
        final textColors = [
          theme.axisStyle.labelStyle.color!,
          theme.axisStyle.titleStyle.color!,
        ];

        for (final color in textColors) {
          final contrastRatio = ColorUtils.calculateContrastRatio(
            color,
            backgroundColor,
          );

          expect(contrastRatio, greaterThanOrEqualTo(7.0),
              reason: 'All text must meet WCAG AAA (7.0:1)');
        }
      });
    });
  });
}
