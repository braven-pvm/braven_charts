// CONTRACT TEST: ChartTheme
// Feature: 004-theming-system
// Phase 0: TDD Foundation
//
// This test MUST FAIL initially because ChartTheme is not yet implemented.
// After Phase 1 (T016), this test should PASS.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// Import will fail initially - this is expected for TDD
// ignore: unused_import
import 'package:braven_charts/src/theming/chart_theme.dart';
import 'package:braven_charts/src/theming/components/animation_theme.dart';
import 'package:braven_charts/src/theming/components/axis_style.dart';
import 'package:braven_charts/src/theming/components/grid_style.dart';
import 'package:braven_charts/src/theming/components/interaction_theme.dart';
import 'package:braven_charts/src/theming/components/series_theme.dart';
import 'package:braven_charts/src/theming/components/typography_theme.dart';

void main() {
  group('ChartTheme Contract Tests', () {
    group('Predefined Themes', () {
      test('defaultLight theme exists and has valid properties', () {
        final theme = ChartTheme.defaultLight;

        expect(theme.backgroundColor, equals(const Color(0xFFFFFFFF)));
        expect(theme.borderColor, isA<Color>());
        expect(theme.borderWidth, greaterThanOrEqualTo(0.0));
        expect(theme.padding, isA<EdgeInsets>());
        expect(theme.gridStyle, isA<GridStyle>());
        expect(theme.axisStyle, isA<AxisStyle>());
        expect(theme.seriesTheme, isA<SeriesTheme>());
        expect(theme.interactionTheme, isA<InteractionTheme>());
        expect(theme.typographyTheme, isA<TypographyTheme>());
        expect(theme.animationTheme, isA<AnimationTheme>());
      });

      test('defaultDark theme exists and has valid properties', () {
        final theme = ChartTheme.defaultDark;

        expect(theme.backgroundColor, equals(const Color(0xFF121212)));
        expect(theme.borderColor, isA<Color>());
        expect(theme.borderWidth, greaterThanOrEqualTo(0.0));
        expect(theme.gridStyle, isA<GridStyle>());
        expect(theme.axisStyle, isA<AxisStyle>());
      });

      test('corporateBlue theme exists', () {
        final theme = ChartTheme.corporateBlue;
        expect(theme, isA<ChartTheme>());
      });

      test('vibrant theme exists', () {
        final theme = ChartTheme.vibrant;
        expect(theme, isA<ChartTheme>());
      });

      test('minimal theme exists', () {
        final theme = ChartTheme.minimal;
        expect(theme, isA<ChartTheme>());
      });

      test('highContrast theme exists', () {
        final theme = ChartTheme.highContrast;
        expect(theme, isA<ChartTheme>());
      });

      test('colorblindFriendly theme exists', () {
        final theme = ChartTheme.colorblindFriendly;
        expect(theme, isA<ChartTheme>());
      });
    });

    group('Immutability', () {
      test('copyWith() creates new instance with changed fields', () {
        final original = ChartTheme.defaultLight;
        final modified = original.copyWith(
          backgroundColor: const Color(0xFF123456),
        );

        expect(modified.backgroundColor, equals(const Color(0xFF123456)));
        expect(modified.borderColor, equals(original.borderColor));
        expect(modified.gridStyle, equals(original.gridStyle));
        expect(identical(original, modified), isFalse);
      });

      test('copyWith() preserves unchanged fields', () {
        final original = ChartTheme.defaultLight;
        final modified = original.copyWith(
          borderWidth: 2.0,
        );

        expect(modified.backgroundColor, equals(original.backgroundColor));
        expect(modified.borderColor, equals(original.borderColor));
        expect(modified.borderWidth, equals(2.0));
        expect(modified.padding, equals(original.padding));
        expect(modified.gridStyle, equals(original.gridStyle));
        expect(modified.axisStyle, equals(original.axisStyle));
      });
    });

    group('Serialization', () {
      test('toJson() produces valid JSON map', () {
        final theme = ChartTheme.defaultLight;
        final json = theme.toJson();

        expect(json, isA<Map<String, dynamic>>());
        expect(json['backgroundColor'], isA<String>());
        expect(json['borderColor'], isA<String>());
        expect(json['borderWidth'], isA<num>());
        expect(json['gridStyle'], isA<Map>());
        expect(json['axisStyle'], isA<Map>());
        expect(json['seriesTheme'], isA<Map>());
      });

      test('fromJson() reconstructs theme from JSON', () {
        final original = ChartTheme.defaultLight;
        final json = original.toJson();
        final reconstructed = ChartTheme.fromJson(json);

        expect(reconstructed.backgroundColor, equals(original.backgroundColor));
        expect(reconstructed.borderColor, equals(original.borderColor));
        expect(reconstructed.borderWidth, equals(original.borderWidth));
      });

      test('round-trip serialization preserves all properties', () {
        final original = ChartTheme.defaultDark;
        final json = original.toJson();
        final reconstructed = ChartTheme.fromJson(json);

        expect(reconstructed, equals(original));
      });
    });

    group('Equality', () {
      test('identical themes are equal', () {
        final theme1 = ChartTheme.defaultLight;
        final theme2 = ChartTheme.defaultLight;

        expect(theme1, equals(theme2));
        expect(theme1.hashCode, equals(theme2.hashCode));
      });

      test('different themes are not equal', () {
        final theme1 = ChartTheme.defaultLight;
        final theme2 = ChartTheme.defaultDark;

        expect(theme1, isNot(equals(theme2)));
      });

      test('themes with same values are equal', () {
        final theme1 = ChartTheme.defaultLight;
        final theme2 = ChartTheme.defaultLight.copyWith();

        expect(theme1, equals(theme2));
        expect(theme1.hashCode, equals(theme2.hashCode));
      });
    });

    group('Validation', () {
      test('negative borderWidth throws assertion error', () {
        expect(
          () => ChartTheme(
            backgroundColor: Colors.white,
            borderColor: Colors.black,
            borderWidth: -1.0, // Invalid
            padding: EdgeInsets.zero,
            gridStyle: GridStyle.defaultLight,
            axisStyle: AxisStyle.defaultLight,
            seriesTheme: SeriesTheme.defaultLight,
            interactionTheme: InteractionTheme.defaultLight,
            typographyTheme: TypographyTheme.defaultLight,
            animationTheme: AnimationTheme.defaultLight,
          ),
          throwsA(isA<AssertionError>()),
        );
      });

      test('zero borderWidth is valid (no border)', () {
        final theme = ChartTheme.defaultLight.copyWith(borderWidth: 0.0);
        expect(theme.borderWidth, equals(0.0));
      });
    });
  });
}
