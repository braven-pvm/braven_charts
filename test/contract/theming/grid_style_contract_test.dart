// CONTRACT TEST: GridStyle
// Feature: 004-theming-system
// Phase 0: TDD Foundation
//
// This test MUST FAIL initially because GridStyle is not yet implemented.
// After Phase 1 (T009), this test should PASS.

// Import will fail initially - this is expected for TDD
// ignore: unused_import
import 'package:braven_charts/src/theming/components/grid_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GridStyle Contract Tests', () {
    group('Predefined Styles', () {
      test('defaultLight style exists and has valid properties', () {
        final style = GridStyle.defaultLight;

        expect(style.majorColor, isA<Color>());
        expect(style.majorWidth, greaterThanOrEqualTo(0.0));
        expect(style.majorDashPattern, isA<List<double>>());
        expect(style.showMinor, isA<bool>());

        if (style.showMinor) {
          expect(style.minorColor, isA<Color?>());
          expect(style.minorWidth, greaterThanOrEqualTo(0.0));
          expect(style.minorDashPattern, isA<List<double>>());
        }
      });

      test('defaultDark style exists', () {
        final style = GridStyle.defaultDark;
        expect(style, isA<GridStyle>());
      });

      test('corporateBlue style exists', () {
        final style = GridStyle.corporateBlue;
        expect(style, isA<GridStyle>());
      });

      test('vibrant style exists', () {
        final style = GridStyle.vibrant;
        expect(style, isA<GridStyle>());
      });

      test('minimal style exists', () {
        final style = GridStyle.minimal;
        expect(style, isA<GridStyle>());
      });

      test('highContrast style exists', () {
        final style = GridStyle.highContrast;
        expect(style, isA<GridStyle>());
      });

      test('colorblindFriendly style exists', () {
        final style = GridStyle.colorblindFriendly;
        expect(style, isA<GridStyle>());
      });
    });

    group('Major Grid Configuration', () {
      test('major grid has color, width, and dash pattern', () {
        final style = GridStyle.defaultLight;

        expect(style.majorColor, isA<Color>());
        expect(style.majorWidth, greaterThanOrEqualTo(0.0));
        expect(style.majorDashPattern, isA<List<double>>());
      });

      test('major dash pattern can be empty (solid line)', () {
        final style = GridStyle.defaultLight.copyWith(majorDashPattern: []);
        expect(style.majorDashPattern, isEmpty);
      });

      test('major dash pattern can be dashed', () {
        final style = GridStyle.defaultLight.copyWith(
          majorDashPattern: [5.0, 3.0],
        );
        expect(style.majorDashPattern, equals([5.0, 3.0]));
      });
    });

    group('Minor Grid Configuration', () {
      test('minor grid can be disabled', () {
        final style = GridStyle.defaultLight.copyWith(showMinor: false);
        expect(style.showMinor, isFalse);
      });

      test('minor grid can be enabled', () {
        final style = GridStyle.defaultLight.copyWith(
          showMinor: true,
          minorColor: const Color(0xFFF0F0F0),
          minorWidth: 0.5,
        );
        expect(style.showMinor, isTrue);
      });

      test('when minor is enabled, properties are accessible', () {
        final style = GridStyle.defaultLight.copyWith(
          showMinor: true,
          minorColor: const Color(0xFFAAAAAA),
          minorWidth: 0.5,
          minorDashPattern: [2.0, 2.0],
        );

        expect(style.showMinor, isTrue);
        expect(style.minorColor, equals(const Color(0xFFAAAAAA)));
        expect(style.minorWidth, equals(0.5));
        expect(style.minorDashPattern, equals([2.0, 2.0]));
      });
    });

    group('Immutability', () {
      test('copyWith() creates new instance with changed fields', () {
        final original = GridStyle.defaultLight;
        final modified = original.copyWith(
          majorColor: const Color(0xFF123456),
        );

        expect(modified.majorColor, equals(const Color(0xFF123456)));
        expect(modified.majorWidth, equals(original.majorWidth));
        expect(identical(original, modified), isFalse);
      });

      test('copyWith() preserves unchanged fields', () {
        final original = GridStyle.defaultLight;
        final modified = original.copyWith(
          majorWidth: 2.0,
        );

        expect(modified.majorColor, equals(original.majorColor));
        expect(modified.majorWidth, equals(2.0));
        expect(modified.majorDashPattern, equals(original.majorDashPattern));
        expect(modified.showMinor, equals(original.showMinor));
      });
    });

    group('Serialization', () {
      test('toJson() produces valid JSON map', () {
        final style = GridStyle.defaultLight;
        final json = style.toJson();

        expect(json, isA<Map<String, dynamic>>());
        expect(json['majorColor'], isA<String>());
        expect(json['majorWidth'], isA<num>());
        expect(json['majorDashPattern'], isA<List>());
        expect(json['showMinor'], isA<bool>());
      });

      test('fromJson() reconstructs style from JSON', () {
        final original = GridStyle.defaultLight;
        final json = original.toJson();
        final reconstructed = GridStyle.fromJson(json);

        expect(reconstructed.majorColor, equals(original.majorColor));
        expect(reconstructed.majorWidth, equals(original.majorWidth));
        expect(reconstructed.showMinor, equals(original.showMinor));
      });

      test('round-trip serialization preserves all properties', () {
        final original = GridStyle.defaultDark;
        final json = original.toJson();
        final reconstructed = GridStyle.fromJson(json);

        expect(reconstructed, equals(original));
      });
    });

    group('Equality', () {
      test('identical styles are equal', () {
        final style1 = GridStyle.defaultLight;
        final style2 = GridStyle.defaultLight;

        expect(style1, equals(style2));
        expect(style1.hashCode, equals(style2.hashCode));
      });

      test('different styles are not equal', () {
        final style1 = GridStyle.defaultLight;
        final style2 = GridStyle.defaultDark;

        expect(style1, isNot(equals(style2)));
      });
    });

    group('Validation', () {
      test('negative major width throws assertion error', () {
        expect(
          () => GridStyle(
            majorColor: Colors.grey,
            majorWidth: -1.0, // Invalid
            majorDashPattern: const [],
            showMinor: false,
            minorColor: null,
            minorWidth: 0.0,
            minorDashPattern: const [],
          ),
          throwsA(isA<AssertionError>()),
        );
      });

      test('negative minor width throws assertion error', () {
        expect(
          () => GridStyle(
            majorColor: Colors.grey,
            majorWidth: 1.0,
            majorDashPattern: const [],
            showMinor: true,
            minorColor: Colors.grey.shade300,
            minorWidth: -0.5, // Invalid
            minorDashPattern: const [],
          ),
          throwsA(isA<AssertionError>()),
        );
      });

      test('zero width is valid (no grid line)', () {
        final style = GridStyle.defaultLight.copyWith(majorWidth: 0.0);
        expect(style.majorWidth, equals(0.0));
      });
    });
  });
}
