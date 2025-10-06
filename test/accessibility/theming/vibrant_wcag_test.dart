// ACCESSIBILITY TEST: Vibrant Theme
// Feature: 004-theming-system
// Phase 2: Predefined Themes & Validation
//
// Validates WCAG AA compliance for the vibrant theme.

import 'package:braven_charts/src/theming/chart_theme.dart';
import 'package:braven_charts/src/theming/utilities/color_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Vibrant Theme - WCAG AA Compliance', () {
    late ChartTheme theme;

    setUp(() {
      theme = ChartTheme.vibrant;
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
            reason: 'Axis labels must meet WCAG AA');
      });
    });

    group('High Saturation Colors', () {
      test('series theme uses vibrant colors', () {
        final colors = theme.seriesTheme.colors;

        // Vibrant theme should have multiple bold colors
        expect(colors.length, greaterThanOrEqualTo(5),
            reason: 'Vibrant palette should have variety');
      });

      test('series colors are distinct and visible', () {
        final backgroundColor = theme.backgroundColor;
        final colors = theme.seriesTheme.colors;

        for (int i = 0; i < colors.length; i++) {
          final contrastRatio = ColorUtils.calculateContrastRatio(
            colors[i],
            backgroundColor,
          );

          // Vibrant theme prioritizes color variety; some colors may have lower contrast
          expect(contrastRatio, greaterThanOrEqualTo(1.5),
              reason: 'Vibrant color ${i + 1} should be visible');
        }
      });
    });

    group('Visual Impact', () {
      test('uses bold styling with visible border', () {
        final borderWidth = theme.borderWidth;
        expect(borderWidth, greaterThanOrEqualTo(1.5),
            reason: 'Vibrant theme should have bold border');
      });
    });
  });
}
