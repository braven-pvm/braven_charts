// Theme Equality Tests
// Feature: 004-theming-system
// Phase 2: Predefined Themes & Validation (T027)

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:braven_charts/src/theming/chart_theme.dart';

void main() {
  group('ChartTheme - Equality', () {
    test('theme equals itself', () {
      final theme = ChartTheme.defaultLight;
      expect(theme == theme, isTrue);
      expect(identical(theme, theme), isTrue);
    });

    test('all 7 predefined themes are distinct', () {
      final themes = [
        ChartTheme.defaultLight,
        ChartTheme.defaultDark,
        ChartTheme.corporateBlue,
        ChartTheme.vibrant,
        ChartTheme.minimal,
        ChartTheme.highContrast,
        ChartTheme.colorblindFriendly,
      ];

      // Compare each theme with every other theme
      for (var i = 0; i < themes.length; i++) {
        for (var j = 0; j < themes.length; j++) {
          if (i == j) {
            expect(themes[i] == themes[j], isTrue,
                reason: 'Theme should equal itself');
          } else {
            expect(themes[i] == themes[j], isFalse,
                reason: 'Theme $i should not equal theme $j');
          }
        }
      }
    });

    test('themes with identical properties are equal', () {
      final theme1 = ChartTheme.defaultLight;
      final theme2 = ChartTheme.defaultLight.copyWith();

      expect(theme1 == theme2, isTrue);
      expect(theme1.hashCode, equals(theme2.hashCode));
    });

    test('themes with different backgroundColor are not equal', () {
      final theme1 = ChartTheme.defaultLight;
      final theme2 = theme1.copyWith(backgroundColor: Colors.grey);

      expect(theme1 == theme2, isFalse);
    });

    test('themes with different borderColor are not equal', () {
      final theme1 = ChartTheme.defaultLight;
      final theme2 = theme1.copyWith(borderColor: Colors.blue);

      expect(theme1 == theme2, isFalse);
    });

    test('themes with different borderWidth are not equal', () {
      final theme1 = ChartTheme.defaultLight;
      final theme2 = theme1.copyWith(borderWidth: 5.0);

      expect(theme1 == theme2, isFalse);
    });

    test('themes with different padding are not equal', () {
      final theme1 = ChartTheme.defaultLight;
      final theme2 = theme1.copyWith(padding: const EdgeInsets.all(32.0));

      expect(theme1 == theme2, isFalse);
    });
  });

  group('ChartTheme - HashCode', () {
    test('identical themes have identical hashCodes', () {
      final theme1 = ChartTheme.defaultLight;
      final theme2 = ChartTheme.defaultLight;

      expect(theme1.hashCode, equals(theme2.hashCode));
    });

    test('equal themes have equal hashCodes', () {
      final theme1 = ChartTheme.defaultLight;
      final theme2 = theme1.copyWith();

      expect(theme1 == theme2, isTrue);
      expect(theme1.hashCode, equals(theme2.hashCode));
    });

    test('different themes have different hashCodes (usually)', () {
      final themes = [
        ChartTheme.defaultLight,
        ChartTheme.defaultDark,
        ChartTheme.corporateBlue,
        ChartTheme.vibrant,
        ChartTheme.minimal,
        ChartTheme.highContrast,
        ChartTheme.colorblindFriendly,
      ];

      final hashCodes = themes.map((t) => t.hashCode).toSet();
      
      // All 7 themes should have unique hash codes
      expect(hashCodes.length, equals(7),
          reason: 'All predefined themes should have unique hash codes');
    });

    test('hashCode is consistent across multiple calls', () {
      final theme = ChartTheme.defaultLight;
      final hash1 = theme.hashCode;
      final hash2 = theme.hashCode;
      final hash3 = theme.hashCode;

      expect(hash1, equals(hash2));
      expect(hash2, equals(hash3));
    });
  });

  group('ChartTheme - copyWith()', () {
    test('copyWith() with no arguments creates equal theme', () {
      final theme = ChartTheme.defaultLight;
      final copy = theme.copyWith();

      expect(copy, equals(theme));
      expect(copy.hashCode, equals(theme.hashCode));
    });

    test('copyWith() creates new instance (not identical)', () {
      final theme = ChartTheme.defaultLight;
      final copy = theme.copyWith();

      expect(identical(copy, theme), isFalse,
          reason: 'copyWith() should create a new instance');
    });

    test('copyWith(backgroundColor) only changes backgroundColor', () {
      final theme = ChartTheme.defaultLight;
      final newColor = const Color(0xFFF0F0F0);
      final copy = theme.copyWith(backgroundColor: newColor);

      expect(copy.backgroundColor, equals(newColor));
      expect(copy.borderColor, equals(theme.borderColor));
      expect(copy.borderWidth, equals(theme.borderWidth));
      expect(copy.padding, equals(theme.padding));
      expect(copy.gridStyle, equals(theme.gridStyle));
      expect(copy.axisStyle, equals(theme.axisStyle));
      expect(copy.seriesTheme, equals(theme.seriesTheme));
      expect(copy.interactionTheme, equals(theme.interactionTheme));
      expect(copy.typographyTheme, equals(theme.typographyTheme));
      expect(copy.animationTheme, equals(theme.animationTheme));
    });

    test('copyWith(borderColor) only changes borderColor', () {
      final theme = ChartTheme.defaultLight;
      final newColor = const Color(0xFF0000FF);
      final copy = theme.copyWith(borderColor: newColor);

      expect(copy.borderColor, equals(newColor));
      expect(copy.backgroundColor, equals(theme.backgroundColor));
      expect(copy.borderWidth, equals(theme.borderWidth));
    });

    test('copyWith(borderWidth) only changes borderWidth', () {
      final theme = ChartTheme.defaultLight;
      final copy = theme.copyWith(borderWidth: 5.0);

      expect(copy.borderWidth, equals(5.0));
      expect(copy.backgroundColor, equals(theme.backgroundColor));
      expect(copy.borderColor, equals(theme.borderColor));
    });

    test('copyWith(padding) only changes padding', () {
      final theme = ChartTheme.defaultLight;
      final newPadding = const EdgeInsets.all(32.0);
      final copy = theme.copyWith(padding: newPadding);

      expect(copy.padding, equals(newPadding));
      expect(copy.backgroundColor, equals(theme.backgroundColor));
      expect(copy.borderWidth, equals(theme.borderWidth));
    });

    test('copyWith() can change multiple properties at once', () {
      final theme = ChartTheme.defaultLight;
      final copy = theme.copyWith(
        backgroundColor: Colors.grey,
        borderWidth: 3.0,
        padding: const EdgeInsets.all(24.0),
      );

      expect(copy.backgroundColor, equals(Colors.grey));
      expect(copy.borderWidth, equals(3.0));
      expect(copy.padding, equals(const EdgeInsets.all(24.0)));
      expect(copy.borderColor, equals(theme.borderColor));
    });

    test('copyWith() works for all predefined themes', () {
      final themes = [
        ChartTheme.defaultLight,
        ChartTheme.defaultDark,
        ChartTheme.corporateBlue,
        ChartTheme.vibrant,
        ChartTheme.minimal,
        ChartTheme.highContrast,
        ChartTheme.colorblindFriendly,
      ];

      for (final theme in themes) {
        final copy = theme.copyWith(backgroundColor: Colors.pink);
        expect(copy.backgroundColor, equals(Colors.pink));
        expect(copy, isNot(equals(theme)));
      }
    });
  });

  group('ChartTheme - toJson()', () {
    test('toJson() produces expected structure for defaultLight', () {
      final json = ChartTheme.defaultLight.toJson();

      expect(json, isA<Map<String, dynamic>>());
      expect(json.keys, containsAll([
        'backgroundColor',
        'borderColor',
        'borderWidth',
        'padding',
        'gridStyle',
        'axisStyle',
        'seriesTheme',
        'interactionTheme',
        'typographyTheme',
        'animationTheme',
      ]));
    });

    test('toJson() backgroundColor is hex string', () {
      final json = ChartTheme.defaultLight.toJson();
      expect(json['backgroundColor'], isA<String>());
      expect(json['backgroundColor'], startsWith('#'));
      expect(json['backgroundColor'], hasLength(9)); // #AARRGGBB
    });

    test('toJson() borderColor is hex string', () {
      final json = ChartTheme.defaultLight.toJson();
      expect(json['borderColor'], isA<String>());
      expect(json['borderColor'], startsWith('#'));
      expect(json['borderColor'], hasLength(9)); // #AARRGGBB
    });

    test('toJson() borderWidth is number', () {
      final json = ChartTheme.defaultLight.toJson();
      expect(json['borderWidth'], isA<num>());
      expect(json['borderWidth'], equals(1.0));
    });

    test('toJson() padding has left/top/right/bottom', () {
      final json = ChartTheme.defaultLight.toJson();
      final padding = json['padding'] as Map<String, dynamic>;

      expect(padding.keys, containsAll(['left', 'top', 'right', 'bottom']));
      expect(padding['left'], isA<num>());
      expect(padding['top'], isA<num>());
      expect(padding['right'], isA<num>());
      expect(padding['bottom'], isA<num>());
    });

    test('toJson() component themes are maps', () {
      final json = ChartTheme.defaultLight.toJson();

      expect(json['gridStyle'], isA<Map<String, dynamic>>());
      expect(json['axisStyle'], isA<Map<String, dynamic>>());
      expect(json['seriesTheme'], isA<Map<String, dynamic>>());
      expect(json['interactionTheme'], isA<Map<String, dynamic>>());
      expect(json['typographyTheme'], isA<Map<String, dynamic>>());
      expect(json['animationTheme'], isA<Map<String, dynamic>>());
    });

    test('toJson() round-trips correctly for defaultLight', () {
      final original = ChartTheme.defaultLight;
      final json = original.toJson();
      final restored = ChartTheme.fromJson(json);

      expect(restored.backgroundColor, equals(original.backgroundColor));
      expect(restored.borderColor, equals(original.borderColor));
      expect(restored.borderWidth, equals(original.borderWidth));
      expect(restored.padding, equals(original.padding));
    });

    test('toJson() works for all 7 predefined themes', () {
      final themes = [
        ChartTheme.defaultLight,
        ChartTheme.defaultDark,
        ChartTheme.corporateBlue,
        ChartTheme.vibrant,
        ChartTheme.minimal,
        ChartTheme.highContrast,
        ChartTheme.colorblindFriendly,
      ];

      for (final theme in themes) {
        final json = theme.toJson();
        expect(json, isA<Map<String, dynamic>>());
        expect(json['backgroundColor'], isA<String>());
        expect(json['borderColor'], isA<String>());
        expect(json['borderWidth'], isA<num>());
      }
    });

    test('toJson() produces unique JSON for each theme', () {
      final themes = [
        ChartTheme.defaultLight,
        ChartTheme.defaultDark,
        ChartTheme.corporateBlue,
        ChartTheme.vibrant,
        ChartTheme.minimal,
        ChartTheme.highContrast,
        ChartTheme.colorblindFriendly,
      ];

      final jsonStrings = themes.map((t) => t.toJson().toString()).toSet();
      
      // All themes should produce unique JSON
      expect(jsonStrings.length, equals(7),
          reason: 'Each theme should produce unique JSON');
    });
  });

  group('ChartTheme - fromJson()', () {
    test('fromJson() restores theme from toJson() output', () {
      final original = ChartTheme.defaultLight;
      final json = original.toJson();
      final restored = ChartTheme.fromJson(json);

      expect(restored, equals(original));
    });

    test('fromJson() works for all predefined themes', () {
      final themes = [
        ChartTheme.defaultLight,
        ChartTheme.defaultDark,
        ChartTheme.corporateBlue,
        ChartTheme.vibrant,
        ChartTheme.minimal,
        ChartTheme.highContrast,
        ChartTheme.colorblindFriendly,
      ];

      for (final theme in themes) {
        final json = theme.toJson();
        final restored = ChartTheme.fromJson(json);
        expect(restored, equals(theme));
      }
    });

    test('fromJson() handles custom padding values', () {
      final original = ChartTheme.defaultLight.copyWith(
        padding: const EdgeInsets.fromLTRB(10, 20, 30, 40),
      );
      final json = original.toJson();
      final restored = ChartTheme.fromJson(json);

      expect(restored.padding.left, equals(10.0));
      expect(restored.padding.top, equals(20.0));
      expect(restored.padding.right, equals(30.0));
      expect(restored.padding.bottom, equals(40.0));
    });
  });
}
