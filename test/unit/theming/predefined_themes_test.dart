// Predefined Themes Test
// Feature: 004-theming-system
// Phase 2: Predefined Themes & Validation (T026)

import 'package:braven_charts/src/theming/chart_theme.dart';
import 'package:braven_charts/src/theming/themes/predefined_themes.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Predefined Themes Showcase', () {
    test('all theme re-exports are defined', () {
      expect(defaultLight, isNotNull);
      expect(defaultDark, isNotNull);
      expect(corporateBlue, isNotNull);
      expect(vibrant, isNotNull);
      expect(minimal, isNotNull);
      expect(highContrast, isNotNull);
      expect(colorblindFriendly, isNotNull);
    });

    test('all theme re-exports match ChartTheme static instances', () {
      expect(defaultLight, same(ChartTheme.defaultLight));
      expect(defaultDark, same(ChartTheme.defaultDark));
      expect(corporateBlue, same(ChartTheme.corporateBlue));
      expect(vibrant, same(ChartTheme.vibrant));
      expect(minimal, same(ChartTheme.minimal));
      expect(highContrast, same(ChartTheme.highContrast));
      expect(colorblindFriendly, same(ChartTheme.colorblindFriendly));
    });

    test('allPredefinedThemes map contains all 7 themes', () {
      expect(allPredefinedThemes.length, equals(7));
      expect(
          allPredefinedThemes.keys,
          containsAll([
            'defaultLight',
            'defaultDark',
            'corporateBlue',
            'vibrant',
            'minimal',
            'highContrast',
            'colorblindFriendly',
          ]));
    });

    test('allPredefinedThemes values match individual exports', () {
      expect(allPredefinedThemes['defaultLight'], same(defaultLight));
      expect(allPredefinedThemes['defaultDark'], same(defaultDark));
      expect(allPredefinedThemes['corporateBlue'], same(corporateBlue));
      expect(allPredefinedThemes['vibrant'], same(vibrant));
      expect(allPredefinedThemes['minimal'], same(minimal));
      expect(allPredefinedThemes['highContrast'], same(highContrast));
      expect(allPredefinedThemes['colorblindFriendly'], same(colorblindFriendly));
    });

    test('all themes have unique configurations', () {
      final themes = allPredefinedThemes.values.toList();

      // Check that each theme is distinct (not equal to others)
      for (var i = 0; i < themes.length; i++) {
        for (var j = i + 1; j < themes.length; j++) {
          expect(
            themes[i] == themes[j],
            isFalse,
            reason: 'Theme $i should be different from theme $j',
          );
        }
      }
    });

    test('theme map is iteration-friendly', () {
      // Verify the map can be iterated for UI components
      final themeNames = <String>[];
      final themeValues = <ChartTheme>[];

      for (final entry in allPredefinedThemes.entries) {
        themeNames.add(entry.key);
        themeValues.add(entry.value);
      }

      expect(themeNames.length, equals(7));
      expect(themeValues.length, equals(7));
      expect(themeValues, everyElement(isA<ChartTheme>()));
    });
  });
}
