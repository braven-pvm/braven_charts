// CONTRACT TEST: InteractionTheme
// Feature: 004-theming-system
// Phase 0: TDD Foundation
//
// This test MUST FAIL initially because InteractionTheme is not yet implemented.
// After Phase 1 (T012), this test should PASS.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// Import will fail initially - this is expected for TDD
// ignore: unused_import
import 'package:braven_charts/src/theming/components/interaction_theme.dart';

void main() {
  group('InteractionTheme Contract Tests', () {
    group('Predefined Themes', () {
      test('defaultLight theme exists and has valid properties', () {
        final theme = InteractionTheme.defaultLight;

        expect(theme.crosshairColor, isA<Color>());
        expect(theme.crosshairWidth, greaterThanOrEqualTo(0.0));
        expect(theme.crosshairDashPattern, isA<List<double>>());
        expect(theme.tooltipBackground, isA<Color>());
        expect(theme.tooltipTextStyle, isA<TextStyle>());
        expect(theme.selectionColor, isA<Color>());
      });

      test('defaultDark theme exists', () {
        final theme = InteractionTheme.defaultDark;
        expect(theme, isA<InteractionTheme>());
      });

      test('corporateBlue theme exists', () {
        final theme = InteractionTheme.corporateBlue;
        expect(theme, isA<InteractionTheme>());
      });

      test('vibrant theme exists', () {
        final theme = InteractionTheme.vibrant;
        expect(theme, isA<InteractionTheme>());
      });

      test('minimal theme exists', () {
        final theme = InteractionTheme.minimal;
        expect(theme, isA<InteractionTheme>());
      });

      test('highContrast theme exists', () {
        final theme = InteractionTheme.highContrast;
        expect(theme, isA<InteractionTheme>());
      });

      test('colorblindFriendly theme exists', () {
        final theme = InteractionTheme.colorblindFriendly;
        expect(theme, isA<InteractionTheme>());
      });
    });

    group('Crosshair Styling', () {
      test('crosshair has color, width, and dash pattern', () {
        final theme = InteractionTheme.defaultLight;

        expect(theme.crosshairColor, isA<Color>());
        expect(theme.crosshairWidth, greaterThanOrEqualTo(0.0));
        expect(theme.crosshairDashPattern, isA<List<double>>());
      });

      test('crosshair can be solid (empty dash pattern)', () {
        final theme = InteractionTheme.defaultLight.copyWith(
          crosshairDashPattern: [],
        );
        expect(theme.crosshairDashPattern, isEmpty);
      });

      test('crosshair can be dashed', () {
        final theme = InteractionTheme.defaultLight.copyWith(
          crosshairDashPattern: [5.0, 3.0],
        );
        expect(theme.crosshairDashPattern, equals([5.0, 3.0]));
      });
    });

    group('Tooltip Styling', () {
      test('tooltip has background color', () {
        final theme = InteractionTheme.defaultLight;
        expect(theme.tooltipBackground, isA<Color>());
      });

      test('tooltip has text style', () {
        final theme = InteractionTheme.defaultLight;
        expect(theme.tooltipTextStyle, isA<TextStyle>());
        expect(theme.tooltipTextStyle.color, isA<Color>());
      });

      test('tooltip styles can be customized', () {
        final customTextStyle = const TextStyle(
          fontSize: 12.0,
          color: Colors.white,
        );

        final theme = InteractionTheme.defaultLight.copyWith(
          tooltipBackground: const Color(0xFF000000),
          tooltipTextStyle: customTextStyle,
        );

        expect(theme.tooltipBackground, equals(const Color(0xFF000000)));
        expect(theme.tooltipTextStyle.fontSize, equals(12.0));
        expect(theme.tooltipTextStyle.color, equals(Colors.white));
      });
    });

    group('Selection Styling', () {
      test('selection has color', () {
        final theme = InteractionTheme.defaultLight;
        expect(theme.selectionColor, isA<Color>());
      });

      test('selection color can be customized', () {
        final theme = InteractionTheme.defaultLight.copyWith(
          selectionColor: const Color(0xFFFF0000),
        );
        expect(theme.selectionColor, equals(const Color(0xFFFF0000)));
      });
    });

    group('Immutability', () {
      test('copyWith() creates new instance with changed fields', () {
        final original = InteractionTheme.defaultLight;
        final modified = original.copyWith(
          crosshairColor: const Color(0xFF123456),
        );

        expect(modified.crosshairColor, equals(const Color(0xFF123456)));
        expect(modified.crosshairWidth, equals(original.crosshairWidth));
        expect(identical(original, modified), isFalse);
      });

      test('copyWith() preserves unchanged fields', () {
        final original = InteractionTheme.defaultLight;
        final modified = original.copyWith(
          crosshairWidth: 2.0,
        );

        expect(modified.crosshairColor, equals(original.crosshairColor));
        expect(modified.crosshairWidth, equals(2.0));
        expect(modified.tooltipBackground, equals(original.tooltipBackground));
        expect(modified.selectionColor, equals(original.selectionColor));
      });
    });

    group('Serialization', () {
      test('toJson() produces valid JSON map', () {
        final theme = InteractionTheme.defaultLight;
        final json = theme.toJson();

        expect(json, isA<Map<String, dynamic>>());
        expect(json['crosshairColor'], isA<String>());
        expect(json['crosshairWidth'], isA<num>());
        expect(json['crosshairDashPattern'], isA<List>());
        expect(json['tooltipBackground'], isA<String>());
        expect(json['tooltipTextStyle'], isA<Map>());
        expect(json['selectionColor'], isA<String>());
      });

      test('fromJson() reconstructs theme from JSON', () {
        final original = InteractionTheme.defaultLight;
        final json = original.toJson();
        final reconstructed = InteractionTheme.fromJson(json);

        expect(reconstructed.crosshairColor, equals(original.crosshairColor));
        expect(reconstructed.crosshairWidth, equals(original.crosshairWidth));
        expect(reconstructed.selectionColor, equals(original.selectionColor));
      });

      test('round-trip serialization preserves all properties', () {
        final original = InteractionTheme.defaultDark;
        final json = original.toJson();
        final reconstructed = InteractionTheme.fromJson(json);

        expect(reconstructed, equals(original));
      });
    });

    group('Equality', () {
      test('identical themes are equal', () {
        final theme1 = InteractionTheme.defaultLight;
        final theme2 = InteractionTheme.defaultLight;

        expect(theme1, equals(theme2));
        expect(theme1.hashCode, equals(theme2.hashCode));
      });

      test('different themes are not equal', () {
        final theme1 = InteractionTheme.defaultLight;
        final theme2 = InteractionTheme.defaultDark;

        expect(theme1, isNot(equals(theme2)));
      });
    });

    group('Validation', () {
      test('negative crosshair width throws assertion error', () {
        expect(
          () => InteractionTheme(
            crosshairColor: Colors.grey,
            crosshairWidth: -1.0, // Invalid
            crosshairDashPattern: const [],
            tooltipBackground: Colors.black,
            tooltipTextStyle: const TextStyle(),
            selectionColor: Colors.blue,
          ),
          throwsA(isA<AssertionError>()),
        );
      });

      test('zero crosshair width is valid (hidden)', () {
        final theme = InteractionTheme.defaultLight.copyWith(
          crosshairWidth: 0.0,
        );
        expect(theme.crosshairWidth, equals(0.0));
      });
    });
  });
}
