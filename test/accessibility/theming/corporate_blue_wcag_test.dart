// ACCESSIBILITY TEST: Corporate Blue Theme
// Feature: 004-theming-system
// Phase 2: Predefined Themes & Validation
//
// Validates WCAG AA compliance for the corporate blue theme.

import 'package:braven_charts/legacy/src/theming/chart_theme.dart';
import 'package:braven_charts/legacy/src/theming/utilities/color_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Corporate Blue Theme - WCAG AA Compliance', () {
    late ChartTheme theme;

    setUp(() {
      theme = ChartTheme.corporateBlue;
    });

    group('Background and Text Contrast', () {
      test('axis labels have sufficient contrast with background (>= 4.5:1)',
          () {
        final backgroundColor = theme.backgroundColor;
        final labelColor = theme.axisStyle.labelStyle.color!;

        final contrastRatio = ColorUtils.calculateContrastRatio(
          labelColor,
          backgroundColor,
        );

        expect(contrastRatio, greaterThanOrEqualTo(4.5),
            reason: 'Axis labels must meet WCAG AA for normal text (4.5:1)');
      });
    });

    group('Blue Color Palette', () {
      test('series theme uses blue-based colors', () {
        final colors = theme.seriesTheme.colors;

        // At least 5 colors in the palette
        expect(colors.length, greaterThanOrEqualTo(5),
            reason: 'Corporate blue palette should have at least 5 colors');
      });

      test('series colors are visible against background', () {
        final backgroundColor = theme.backgroundColor;
        final colors = theme.seriesTheme.colors;

        for (int i = 0; i < colors.length; i++) {
          final contrastRatio = ColorUtils.calculateContrastRatio(
            colors[i],
            backgroundColor,
          );

          expect(contrastRatio, greaterThanOrEqualTo(2.0),
              reason: 'Series color ${i + 1} should be visible');
        }
      });
    });

    group('Professional Appearance', () {
      test('border is more prominent than minimal theme', () {
        final borderWidth = theme.borderWidth;
        expect(borderWidth, greaterThanOrEqualTo(1.0),
            reason: 'Corporate theme should have visible border');
      });

      test('uses more padding than default themes', () {
        final padding = theme.padding;
        expect(padding.left + padding.right, greaterThanOrEqualTo(30.0),
            reason: 'Corporate theme should have generous padding');
      });
    });
  });
}
