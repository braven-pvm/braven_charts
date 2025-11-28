/// Tests for theme diffing and change detection.
library;

import 'package:braven_charts/legacy/src/theming/chart_theme.dart';
import 'package:braven_charts/legacy/src/theming/utilities/theme_change_set.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ThemeChangeSet.compute', () {
    test('returns all false when themes are identical', () {
      final theme = ChartTheme.defaultLight;
      final changeSet = ThemeChangeSet.compute(theme, theme);

      expect(changeSet.backgroundChanged, isFalse);
      expect(changeSet.borderColorChanged, isFalse);
      expect(changeSet.borderWidthChanged, isFalse);
      expect(changeSet.paddingChanged, isFalse);
      expect(changeSet.gridStyleChanged, isFalse);
      expect(changeSet.axisStyleChanged, isFalse);
      expect(changeSet.seriesThemeChanged, isFalse);
      expect(changeSet.interactionThemeChanged, isFalse);
      expect(changeSet.typographyThemeChanged, isFalse);
      expect(changeSet.animationThemeChanged, isFalse);
      expect(changeSet.anyChanged, isFalse);
    });

    test('detects backgroundColor change only', () {
      final oldTheme = ChartTheme.defaultLight;
      final newTheme =
          oldTheme.copyWith(backgroundColor: const Color(0xFF000000));

      final changeSet = ThemeChangeSet.compute(oldTheme, newTheme);

      expect(changeSet.backgroundChanged, isTrue);
      expect(changeSet.borderColorChanged, isFalse);
      expect(changeSet.borderWidthChanged, isFalse);
      expect(changeSet.paddingChanged, isFalse);
      expect(changeSet.gridStyleChanged, isFalse);
      expect(changeSet.axisStyleChanged, isFalse);
      expect(changeSet.seriesThemeChanged, isFalse);
      expect(changeSet.interactionThemeChanged, isFalse);
      expect(changeSet.typographyThemeChanged, isFalse);
      expect(changeSet.animationThemeChanged, isFalse);
      expect(changeSet.anyChanged, isTrue);
    });

    test('detects borderColor change only', () {
      final oldTheme = ChartTheme.defaultLight;
      final newTheme = oldTheme.copyWith(borderColor: const Color(0xFFFF0000));

      final changeSet = ThemeChangeSet.compute(oldTheme, newTheme);

      expect(changeSet.backgroundChanged, isFalse);
      expect(changeSet.borderColorChanged, isTrue);
      expect(changeSet.borderWidthChanged, isFalse);
      expect(changeSet.paddingChanged, isFalse);
      expect(changeSet.gridStyleChanged, isFalse);
      expect(changeSet.axisStyleChanged, isFalse);
      expect(changeSet.seriesThemeChanged, isFalse);
      expect(changeSet.interactionThemeChanged, isFalse);
      expect(changeSet.typographyThemeChanged, isFalse);
      expect(changeSet.animationThemeChanged, isFalse);
      expect(changeSet.anyChanged, isTrue);
    });

    test('detects borderWidth change only', () {
      final oldTheme = ChartTheme.defaultLight;
      final newTheme = oldTheme.copyWith(borderWidth: 5.0);

      final changeSet = ThemeChangeSet.compute(oldTheme, newTheme);

      expect(changeSet.backgroundChanged, isFalse);
      expect(changeSet.borderColorChanged, isFalse);
      expect(changeSet.borderWidthChanged, isTrue);
      expect(changeSet.paddingChanged, isFalse);
      expect(changeSet.gridStyleChanged, isFalse);
      expect(changeSet.axisStyleChanged, isFalse);
      expect(changeSet.seriesThemeChanged, isFalse);
      expect(changeSet.interactionThemeChanged, isFalse);
      expect(changeSet.typographyThemeChanged, isFalse);
      expect(changeSet.animationThemeChanged, isFalse);
      expect(changeSet.anyChanged, isTrue);
    });

    test('detects padding change only', () {
      final oldTheme = ChartTheme.defaultLight;
      final newTheme = oldTheme.copyWith(padding: const EdgeInsets.all(32));

      final changeSet = ThemeChangeSet.compute(oldTheme, newTheme);

      expect(changeSet.backgroundChanged, isFalse);
      expect(changeSet.borderColorChanged, isFalse);
      expect(changeSet.borderWidthChanged, isFalse);
      expect(changeSet.paddingChanged, isTrue);
      expect(changeSet.gridStyleChanged, isFalse);
      expect(changeSet.axisStyleChanged, isFalse);
      expect(changeSet.seriesThemeChanged, isFalse);
      expect(changeSet.interactionThemeChanged, isFalse);
      expect(changeSet.typographyThemeChanged, isFalse);
      expect(changeSet.animationThemeChanged, isFalse);
      expect(changeSet.anyChanged, isTrue);
    });

    test('detects gridStyle change only', () {
      final oldTheme = ChartTheme.defaultLight;
      final newTheme = oldTheme.copyWith(
        gridStyle:
            oldTheme.gridStyle.copyWith(majorColor: const Color(0xFFFF0000)),
      );

      final changeSet = ThemeChangeSet.compute(oldTheme, newTheme);

      expect(changeSet.backgroundChanged, isFalse);
      expect(changeSet.borderColorChanged, isFalse);
      expect(changeSet.borderWidthChanged, isFalse);
      expect(changeSet.paddingChanged, isFalse);
      expect(changeSet.gridStyleChanged, isTrue);
      expect(changeSet.axisStyleChanged, isFalse);
      expect(changeSet.seriesThemeChanged, isFalse);
      expect(changeSet.interactionThemeChanged, isFalse);
      expect(changeSet.typographyThemeChanged, isFalse);
      expect(changeSet.animationThemeChanged, isFalse);
      expect(changeSet.anyChanged, isTrue);
    });

    test('detects axisStyle change only', () {
      final oldTheme = ChartTheme.defaultLight;
      final newTheme = oldTheme.copyWith(
        axisStyle:
            oldTheme.axisStyle.copyWith(lineColor: const Color(0xFFFF0000)),
      );

      final changeSet = ThemeChangeSet.compute(oldTheme, newTheme);

      expect(changeSet.backgroundChanged, isFalse);
      expect(changeSet.borderColorChanged, isFalse);
      expect(changeSet.borderWidthChanged, isFalse);
      expect(changeSet.paddingChanged, isFalse);
      expect(changeSet.gridStyleChanged, isFalse);
      expect(changeSet.axisStyleChanged, isTrue);
      expect(changeSet.seriesThemeChanged, isFalse);
      expect(changeSet.interactionThemeChanged, isFalse);
      expect(changeSet.typographyThemeChanged, isFalse);
      expect(changeSet.animationThemeChanged, isFalse);
      expect(changeSet.anyChanged, isTrue);
    });

    test('detects seriesTheme change only', () {
      final oldTheme = ChartTheme.defaultLight;
      final newTheme = oldTheme.copyWith(
        seriesTheme: oldTheme.seriesTheme.copyWith(
          colors: const [Color(0xFFFF0000)],
        ),
      );

      final changeSet = ThemeChangeSet.compute(oldTheme, newTheme);

      expect(changeSet.backgroundChanged, isFalse);
      expect(changeSet.borderColorChanged, isFalse);
      expect(changeSet.borderWidthChanged, isFalse);
      expect(changeSet.paddingChanged, isFalse);
      expect(changeSet.gridStyleChanged, isFalse);
      expect(changeSet.axisStyleChanged, isFalse);
      expect(changeSet.seriesThemeChanged, isTrue);
      expect(changeSet.interactionThemeChanged, isFalse);
      expect(changeSet.typographyThemeChanged, isFalse);
      expect(changeSet.animationThemeChanged, isFalse);
      expect(changeSet.anyChanged, isTrue);
    });

    test('detects interactionTheme change only', () {
      final oldTheme = ChartTheme.defaultLight;
      final newTheme = oldTheme.copyWith(
        interactionTheme: oldTheme.interactionTheme.copyWith(
          crosshairColor: const Color(0xFFFF0000),
        ),
      );

      final changeSet = ThemeChangeSet.compute(oldTheme, newTheme);

      expect(changeSet.backgroundChanged, isFalse);
      expect(changeSet.borderColorChanged, isFalse);
      expect(changeSet.borderWidthChanged, isFalse);
      expect(changeSet.paddingChanged, isFalse);
      expect(changeSet.gridStyleChanged, isFalse);
      expect(changeSet.axisStyleChanged, isFalse);
      expect(changeSet.seriesThemeChanged, isFalse);
      expect(changeSet.interactionThemeChanged, isTrue);
      expect(changeSet.typographyThemeChanged, isFalse);
      expect(changeSet.animationThemeChanged, isFalse);
      expect(changeSet.anyChanged, isTrue);
    });

    test('detects typographyTheme change only', () {
      final oldTheme = ChartTheme.defaultLight;
      final newTheme = oldTheme.copyWith(
        typographyTheme: oldTheme.typographyTheme.copyWith(
          baseFontSize: 24.0,
        ),
      );

      final changeSet = ThemeChangeSet.compute(oldTheme, newTheme);

      expect(changeSet.backgroundChanged, isFalse);
      expect(changeSet.borderColorChanged, isFalse);
      expect(changeSet.borderWidthChanged, isFalse);
      expect(changeSet.paddingChanged, isFalse);
      expect(changeSet.gridStyleChanged, isFalse);
      expect(changeSet.axisStyleChanged, isFalse);
      expect(changeSet.seriesThemeChanged, isFalse);
      expect(changeSet.interactionThemeChanged, isFalse);
      expect(changeSet.typographyThemeChanged, isTrue);
      expect(changeSet.animationThemeChanged, isFalse);
      expect(changeSet.anyChanged, isTrue);
    });

    test('detects animationTheme change only', () {
      final oldTheme = ChartTheme.defaultLight;
      final newTheme = oldTheme.copyWith(
        animationTheme: oldTheme.animationTheme.copyWith(
          dataUpdateDuration: const Duration(milliseconds: 500),
        ),
      );

      final changeSet = ThemeChangeSet.compute(oldTheme, newTheme);

      expect(changeSet.backgroundChanged, isFalse);
      expect(changeSet.borderColorChanged, isFalse);
      expect(changeSet.borderWidthChanged, isFalse);
      expect(changeSet.paddingChanged, isFalse);
      expect(changeSet.gridStyleChanged, isFalse);
      expect(changeSet.axisStyleChanged, isFalse);
      expect(changeSet.seriesThemeChanged, isFalse);
      expect(changeSet.interactionThemeChanged, isFalse);
      expect(changeSet.typographyThemeChanged, isFalse);
      expect(changeSet.animationThemeChanged, isTrue);
      expect(changeSet.anyChanged, isTrue);
    });

    test('detects multiple component changes', () {
      final oldTheme = ChartTheme.defaultLight;
      final newTheme = oldTheme.copyWith(
        backgroundColor: const Color(0xFF000000),
        borderColor: const Color(0xFFFF0000),
        borderWidth: 5.0,
      );

      final changeSet = ThemeChangeSet.compute(oldTheme, newTheme);

      expect(changeSet.backgroundChanged, isTrue);
      expect(changeSet.borderColorChanged, isTrue);
      expect(changeSet.borderWidthChanged, isTrue);
      expect(changeSet.paddingChanged, isFalse);
      expect(changeSet.gridStyleChanged, isFalse);
      expect(changeSet.axisStyleChanged, isFalse);
      expect(changeSet.seriesThemeChanged, isFalse);
      expect(changeSet.interactionThemeChanged, isFalse);
      expect(changeSet.typographyThemeChanged, isFalse);
      expect(changeSet.animationThemeChanged, isFalse);
      expect(changeSet.anyChanged, isTrue);
    });

    test('detects all component changes', () {
      final changeSet = ThemeChangeSet.compute(
        ChartTheme.defaultLight,
        ChartTheme.defaultDark,
      );

      // At least some components should be different between light and dark themes
      expect(changeSet.anyChanged, isTrue);
    });
  });

  group('ThemeChangeSet.anyChanged', () {
    test('returns false when no changes', () {
      final theme = ChartTheme.defaultLight;
      final changeSet = ThemeChangeSet.compute(theme, theme);

      expect(changeSet.anyChanged, isFalse);
    });

    test('returns true when background changes', () {
      final oldTheme = ChartTheme.defaultLight;
      final newTheme =
          oldTheme.copyWith(backgroundColor: const Color(0xFF000000));
      final changeSet = ThemeChangeSet.compute(oldTheme, newTheme);

      expect(changeSet.anyChanged, isTrue);
    });

    test('returns true when multiple components change', () {
      final oldTheme = ChartTheme.defaultLight;
      final newTheme = oldTheme.copyWith(
        backgroundColor: const Color(0xFF000000),
        borderColor: const Color(0xFFFF0000),
      );
      final changeSet = ThemeChangeSet.compute(oldTheme, newTheme);

      expect(changeSet.anyChanged, isTrue);
    });
  });
}
