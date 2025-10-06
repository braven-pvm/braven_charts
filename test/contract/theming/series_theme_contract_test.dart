// CONTRACT TEST: SeriesTheme
// Feature: 004-theming-system
// Phase 0: TDD Foundation
//
// This test MUST FAIL initially because SeriesTheme is not yet implemented.
// After Phase 1 (T011), this test should PASS.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// Import will fail initially - this is expected for TDD
// ignore: unused_import
import 'package:braven_charts/src/theming/components/series_theme.dart';

void main() {
  group('SeriesTheme Contract Tests', () {
    group('Predefined Themes', () {
      test('defaultLight theme exists and has valid properties', () {
        final theme = SeriesTheme.defaultLight;

        expect(theme.colors, isA<List<Color>>());
        expect(theme.colors.isNotEmpty, isTrue);
        expect(theme.lineWidths, isA<List<double>>());
        expect(theme.lineWidths.isNotEmpty, isTrue);
        expect(theme.markerSizes, isA<List<double>>());
        expect(theme.markerSizes.isNotEmpty, isTrue);
        expect(theme.markerShapes, isA<List<MarkerShape>>());
        expect(theme.markerShapes.isNotEmpty, isTrue);
      });

      test('defaultDark theme exists', () {
        final theme = SeriesTheme.defaultDark;
        expect(theme, isA<SeriesTheme>());
      });

      test('corporateBlue theme exists', () {
        final theme = SeriesTheme.corporateBlue;
        expect(theme, isA<SeriesTheme>());
      });

      test('vibrant theme exists', () {
        final theme = SeriesTheme.vibrant;
        expect(theme, isA<SeriesTheme>());
      });

      test('minimal theme exists', () {
        final theme = SeriesTheme.minimal;
        expect(theme, isA<SeriesTheme>());
      });

      test('highContrast theme exists', () {
        final theme = SeriesTheme.highContrast;
        expect(theme, isA<SeriesTheme>());
      });

      test('colorblindFriendly theme exists', () {
        final theme = SeriesTheme.colorblindFriendly;
        expect(theme, isA<SeriesTheme>());
      });
    });

    group('Color Cycling', () {
      test('colorAt() cycles through colors list', () {
        final theme = SeriesTheme.defaultLight;
        final colorsLength = theme.colors.length;

        expect(theme.colorAt(0), equals(theme.colors[0]));
        expect(theme.colorAt(colorsLength - 1),
            equals(theme.colors[colorsLength - 1]));
        expect(theme.colorAt(colorsLength), equals(theme.colors[0])); // Cycles
        expect(theme.colorAt(colorsLength + 1), equals(theme.colors[1]));
      });

      test('colorAt() handles large indices', () {
        final theme = SeriesTheme.defaultLight;
        final largeIndex = theme.colors.length * 10 + 3;
        expect(theme.colorAt(largeIndex), equals(theme.colors[3]));
      });
    });

    group('Line Width Cycling', () {
      test('lineWidthAt() cycles through lineWidths list', () {
        final theme = SeriesTheme.defaultLight;
        final widthsLength = theme.lineWidths.length;

        expect(theme.lineWidthAt(0), equals(theme.lineWidths[0]));
        expect(theme.lineWidthAt(widthsLength - 1),
            equals(theme.lineWidths[widthsLength - 1]));
        expect(theme.lineWidthAt(widthsLength),
            equals(theme.lineWidths[0])); // Cycles
      });
    });

    group('Marker Size Cycling', () {
      test('markerSizeAt() cycles through markerSizes list', () {
        final theme = SeriesTheme.defaultLight;
        final sizesLength = theme.markerSizes.length;

        expect(theme.markerSizeAt(0), equals(theme.markerSizes[0]));
        expect(theme.markerSizeAt(sizesLength - 1),
            equals(theme.markerSizes[sizesLength - 1]));
        expect(theme.markerSizeAt(sizesLength),
            equals(theme.markerSizes[0])); // Cycles
      });
    });

    group('Marker Shape Cycling', () {
      test('markerShapeAt() cycles through markerShapes list', () {
        final theme = SeriesTheme.defaultLight;
        final shapesLength = theme.markerShapes.length;

        expect(theme.markerShapeAt(0), equals(theme.markerShapes[0]));
        expect(theme.markerShapeAt(shapesLength - 1),
            equals(theme.markerShapes[shapesLength - 1]));
        expect(theme.markerShapeAt(shapesLength),
            equals(theme.markerShapes[0])); // Cycles
      });

      test('MarkerShape enum has all expected values', () {
        expect(MarkerShape.values,
            containsAll([MarkerShape.circle, MarkerShape.square]));
      });
    });

    group('Immutability', () {
      test('copyWith() creates new instance with changed fields', () {
        final original = SeriesTheme.defaultLight;
        final newColors = [Colors.red, Colors.blue];
        final modified = original.copyWith(
          colors: newColors,
        );

        expect(modified.colors, equals(newColors));
        expect(modified.lineWidths, equals(original.lineWidths));
        expect(identical(original, modified), isFalse);
      });

      test('copyWith() preserves unchanged fields', () {
        final original = SeriesTheme.defaultLight;
        final newWidths = [3.0, 4.0];
        final modified = original.copyWith(
          lineWidths: newWidths,
        );

        expect(modified.colors, equals(original.colors));
        expect(modified.lineWidths, equals(newWidths));
        expect(modified.markerSizes, equals(original.markerSizes));
        expect(modified.markerShapes, equals(original.markerShapes));
      });
    });

    group('Serialization', () {
      test('toJson() produces valid JSON map', () {
        final theme = SeriesTheme.defaultLight;
        final json = theme.toJson();

        expect(json, isA<Map<String, dynamic>>());
        expect(json['colors'], isA<List>());
        expect(json['lineWidths'], isA<List>());
        expect(json['markerSizes'], isA<List>());
        expect(json['markerShapes'], isA<List>());
      });

      test('fromJson() reconstructs theme from JSON', () {
        final original = SeriesTheme.defaultLight;
        final json = original.toJson();
        final reconstructed = SeriesTheme.fromJson(json);

        expect(reconstructed.colors.length, equals(original.colors.length));
        expect(reconstructed.lineWidths, equals(original.lineWidths));
      });

      test('round-trip serialization preserves all properties', () {
        final original = SeriesTheme.defaultDark;
        final json = original.toJson();
        final reconstructed = SeriesTheme.fromJson(json);

        expect(reconstructed, equals(original));
      });
    });

    group('Equality', () {
      test('identical themes are equal', () {
        final theme1 = SeriesTheme.defaultLight;
        final theme2 = SeriesTheme.defaultLight;

        expect(theme1, equals(theme2));
        expect(theme1.hashCode, equals(theme2.hashCode));
      });

      test('different themes are not equal', () {
        final theme1 = SeriesTheme.defaultLight;
        final theme2 = SeriesTheme.defaultDark;

        expect(theme1, isNot(equals(theme2)));
      });
    });

    group('Validation', () {
      test('empty colors list throws assertion error', () {
        expect(
          () => SeriesTheme(
            colors: const [], // Invalid
            lineWidths: const [2.0],
            markerSizes: const [6.0],
            markerShapes: const [MarkerShape.circle],
          ),
          throwsA(isA<AssertionError>()),
        );
      });

      test('empty lineWidths list throws assertion error', () {
        expect(
          () => SeriesTheme(
            colors: const [Colors.blue],
            lineWidths: const [], // Invalid
            markerSizes: const [6.0],
            markerShapes: const [MarkerShape.circle],
          ),
          throwsA(isA<AssertionError>()),
        );
      });

      test('all lists must have at least one element', () {
        final theme = SeriesTheme.defaultLight;

        expect(theme.colors.length, greaterThanOrEqualTo(1));
        expect(theme.lineWidths.length, greaterThanOrEqualTo(1));
        expect(theme.markerSizes.length, greaterThanOrEqualTo(1));
        expect(theme.markerShapes.length, greaterThanOrEqualTo(1));
      });
    });
  });
}
