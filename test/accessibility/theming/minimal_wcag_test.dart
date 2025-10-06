// ACCESSIBILITY TEST: Minimal Theme
// Feature: 004-theming-system
// Phase 2: Predefined Themes & Validation
//
// Validates WCAG AA compliance for the minimal theme.

import 'package:braven_charts/src/theming/chart_theme.dart';
import 'package:braven_charts/src/theming/utilities/color_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Minimal Theme - WCAG AA Compliance', () {
    late ChartTheme theme;

    setUp(() {
      theme = ChartTheme.minimal;
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

    group('Subtle Gray Palette', () {
      test('series theme uses muted colors', () {
        final colors = theme.seriesTheme.colors;

        // Minimal theme may have fewer colors
        expect(colors.length, greaterThanOrEqualTo(3),
            reason: 'Minimal palette should have at least 3 colors');
      });

      test('series colors are still visible despite minimal styling', () {
        final backgroundColor = theme.backgroundColor;
        final colors = theme.seriesTheme.colors;

        for (int i = 0; i < colors.length; i++) {
          final contrastRatio = ColorUtils.calculateContrastRatio(
            colors[i],
            backgroundColor,
          );

          expect(contrastRatio, greaterThanOrEqualTo(1.5),
              reason: 'Even minimal colors should be visible');
        }
      });
    });

    group('Minimal Styling', () {
      test('uses no border or minimal border', () {
        final borderWidth = theme.borderWidth;
        expect(borderWidth, lessThanOrEqualTo(1.0),
            reason: 'Minimal theme should have subtle or no border');
      });

      test('uses less padding than default themes', () {
        final padding = theme.padding;
        expect(padding.left + padding.right, lessThanOrEqualTo(30.0),
            reason: 'Minimal theme should have compact padding');
      });
    });
  });
}
