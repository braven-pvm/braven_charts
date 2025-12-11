// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

import 'dart:ui';

import 'package:braven_charts/src/models/grid_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GridConfig', () {
    group('construction', () {
      test('creates with default values', () {
        const config = GridConfig();
        expect(config.horizontal, isTrue);
        expect(config.vertical, isTrue);
        expect(config.horizontalColor, isNull);
        expect(config.verticalColor, isNull);
        expect(config.horizontalStrokeWidth, 0.5);
        expect(config.verticalStrokeWidth, 0.5);
      });

      test('creates with custom values', () {
        const config = GridConfig(
          horizontal: false,
          vertical: true,
          horizontalColor: Color(0xFFFF0000),
          verticalColor: Color(0xFF00FF00),
          horizontalStrokeWidth: 1.0,
          verticalStrokeWidth: 2.0,
        );
        expect(config.horizontal, isFalse);
        expect(config.vertical, isTrue);
        expect(config.horizontalColor, const Color(0xFFFF0000));
        expect(config.verticalColor, const Color(0xFF00FF00));
        expect(config.horizontalStrokeWidth, 1.0);
        expect(config.verticalStrokeWidth, 2.0);
      });

      test('creates with both grids disabled', () {
        const config = GridConfig(
          horizontal: false,
          vertical: false,
        );
        expect(config.horizontal, isFalse);
        expect(config.vertical, isFalse);
      });

      test('creates with colors but default widths', () {
        const config = GridConfig(
          horizontalColor: Color(0xFF888888),
          verticalColor: Color(0xFF888888),
        );
        expect(config.horizontalColor, const Color(0xFF888888));
        expect(config.verticalColor, const Color(0xFF888888));
        expect(config.horizontalStrokeWidth, 0.5);
        expect(config.verticalStrokeWidth, 0.5);
      });

      test('creates with custom widths but null colors', () {
        const config = GridConfig(
          horizontalStrokeWidth: 3.0,
          verticalStrokeWidth: 4.0,
        );
        expect(config.horizontalColor, isNull);
        expect(config.verticalColor, isNull);
        expect(config.horizontalStrokeWidth, 3.0);
        expect(config.verticalStrokeWidth, 4.0);
      });
    });

    group('validation', () {
      test('throws assertion error for zero horizontalStrokeWidth', () {
        expect(
          () => GridConfig(horizontalStrokeWidth: 0.0),
          throwsA(isA<AssertionError>()),
        );
      });

      test('throws assertion error for negative horizontalStrokeWidth', () {
        expect(
          () => GridConfig(horizontalStrokeWidth: -1.0),
          throwsA(isA<AssertionError>()),
        );
      });

      test('throws assertion error for zero verticalStrokeWidth', () {
        expect(
          () => GridConfig(verticalStrokeWidth: 0.0),
          throwsA(isA<AssertionError>()),
        );
      });

      test('throws assertion error for negative verticalStrokeWidth', () {
        expect(
          () => GridConfig(verticalStrokeWidth: -1.0),
          throwsA(isA<AssertionError>()),
        );
      });

      test('accepts very small positive stroke widths', () {
        const config = GridConfig(
          horizontalStrokeWidth: 0.001,
          verticalStrokeWidth: 0.001,
        );
        expect(config.horizontalStrokeWidth, 0.001);
        expect(config.verticalStrokeWidth, 0.001);
      });

      test('accepts large stroke widths', () {
        const config = GridConfig(
          horizontalStrokeWidth: 100.0,
          verticalStrokeWidth: 200.0,
        );
        expect(config.horizontalStrokeWidth, 100.0);
        expect(config.verticalStrokeWidth, 200.0);
      });
    });

    group('copyWith', () {
      test('returns identical config when no parameters provided', () {
        const original = GridConfig(
          horizontal: false,
          vertical: false,
          horizontalColor: Color(0xFFFF0000),
          verticalColor: Color(0xFF00FF00),
          horizontalStrokeWidth: 1.5,
          verticalStrokeWidth: 2.5,
        );
        final copy = original.copyWith();
        expect(copy.horizontal, original.horizontal);
        expect(copy.vertical, original.vertical);
        expect(copy.horizontalColor, original.horizontalColor);
        expect(copy.verticalColor, original.verticalColor);
        expect(copy.horizontalStrokeWidth, original.horizontalStrokeWidth);
        expect(copy.verticalStrokeWidth, original.verticalStrokeWidth);
      });

      test('overrides horizontal visibility', () {
        const original = GridConfig(horizontal: true);
        final copy = original.copyWith(horizontal: false);
        expect(copy.horizontal, isFalse);
        expect(copy.vertical, original.vertical);
      });

      test('overrides vertical visibility', () {
        const original = GridConfig(vertical: true);
        final copy = original.copyWith(vertical: false);
        expect(copy.vertical, isFalse);
        expect(copy.horizontal, original.horizontal);
      });

      test('overrides horizontalColor', () {
        const original = GridConfig(horizontalColor: Color(0xFFFF0000));
        final copy =
            original.copyWith(horizontalColor: const Color(0xFF0000FF));
        expect(copy.horizontalColor, const Color(0xFF0000FF));
        expect(copy.verticalColor, original.verticalColor);
      });

      test('overrides verticalColor', () {
        const original = GridConfig(verticalColor: Color(0xFFFF0000));
        final copy = original.copyWith(verticalColor: const Color(0xFF0000FF));
        expect(copy.verticalColor, const Color(0xFF0000FF));
        expect(copy.horizontalColor, original.horizontalColor);
      });

      test('overrides horizontalStrokeWidth', () {
        const original = GridConfig(horizontalStrokeWidth: 1.0);
        final copy = original.copyWith(horizontalStrokeWidth: 3.0);
        expect(copy.horizontalStrokeWidth, 3.0);
        expect(copy.verticalStrokeWidth, original.verticalStrokeWidth);
      });

      test('overrides verticalStrokeWidth', () {
        const original = GridConfig(verticalStrokeWidth: 1.0);
        final copy = original.copyWith(verticalStrokeWidth: 3.0);
        expect(copy.verticalStrokeWidth, 3.0);
        expect(copy.horizontalStrokeWidth, original.horizontalStrokeWidth);
      });

      test('overrides all parameters', () {
        const original = GridConfig(
          horizontal: true,
          vertical: true,
          horizontalColor: Color(0xFFFF0000),
          verticalColor: Color(0xFF00FF00),
          horizontalStrokeWidth: 1.0,
          verticalStrokeWidth: 2.0,
        );
        final copy = original.copyWith(
          horizontal: false,
          vertical: false,
          horizontalColor: const Color(0xFF0000FF),
          verticalColor: const Color(0xFFFFFF00),
          horizontalStrokeWidth: 3.0,
          verticalStrokeWidth: 4.0,
        );
        expect(copy.horizontal, isFalse);
        expect(copy.vertical, isFalse);
        expect(copy.horizontalColor, const Color(0xFF0000FF));
        expect(copy.verticalColor, const Color(0xFFFFFF00));
        expect(copy.horizontalStrokeWidth, 3.0);
        expect(copy.verticalStrokeWidth, 4.0);
      });

      test('overrides multiple properties selectively', () {
        const original = GridConfig(
          horizontal: true,
          vertical: false,
          horizontalStrokeWidth: 1.0,
          verticalStrokeWidth: 2.0,
        );
        final copy = original.copyWith(
          vertical: true,
          horizontalStrokeWidth: 5.0,
        );
        expect(copy.horizontal, original.horizontal); // unchanged
        expect(copy.vertical, isTrue); // changed
        expect(copy.horizontalStrokeWidth, 5.0); // changed
        expect(copy.verticalStrokeWidth,
            original.verticalStrokeWidth); // unchanged
      });
    });

    group('equality', () {
      test('equals itself', () {
        const config = GridConfig(
          horizontal: false,
          verticalColor: Color(0xFFFF0000),
        );
        expect(config, equals(config));
      });

      test('equals config with same values', () {
        const config1 = GridConfig(
          horizontal: false,
          vertical: true,
          horizontalColor: Color(0xFFFF0000),
          verticalColor: Color(0xFF00FF00),
          horizontalStrokeWidth: 1.5,
          verticalStrokeWidth: 2.5,
        );
        const config2 = GridConfig(
          horizontal: false,
          vertical: true,
          horizontalColor: Color(0xFFFF0000),
          verticalColor: Color(0xFF00FF00),
          horizontalStrokeWidth: 1.5,
          verticalStrokeWidth: 2.5,
        );
        expect(config1, equals(config2));
      });

      test('does not equal config with different horizontal', () {
        const config1 = GridConfig(horizontal: true);
        const config2 = GridConfig(horizontal: false);
        expect(config1, isNot(equals(config2)));
      });

      test('does not equal config with different vertical', () {
        const config1 = GridConfig(vertical: true);
        const config2 = GridConfig(vertical: false);
        expect(config1, isNot(equals(config2)));
      });

      test('does not equal config with different horizontalColor', () {
        const config1 = GridConfig(horizontalColor: Color(0xFFFF0000));
        const config2 = GridConfig(horizontalColor: Color(0xFF00FF00));
        expect(config1, isNot(equals(config2)));
      });

      test('does not equal config with different verticalColor', () {
        const config1 = GridConfig(verticalColor: Color(0xFFFF0000));
        const config2 = GridConfig(verticalColor: Color(0xFF00FF00));
        expect(config1, isNot(equals(config2)));
      });

      test('does not equal config with different horizontalStrokeWidth', () {
        const config1 = GridConfig(horizontalStrokeWidth: 1.0);
        const config2 = GridConfig(horizontalStrokeWidth: 2.0);
        expect(config1, isNot(equals(config2)));
      });

      test('does not equal config with different verticalStrokeWidth', () {
        const config1 = GridConfig(verticalStrokeWidth: 1.0);
        const config2 = GridConfig(verticalStrokeWidth: 2.0);
        expect(config1, isNot(equals(config2)));
      });

      test('does not equal non-GridConfig object', () {
        const config = GridConfig();
        expect(config, isNot(equals('GridConfig')));
        expect(config, isNot(equals(42)));
        expect(config, isNot(equals(null)));
      });
    });

    group('hashCode', () {
      test('is same for equal configs', () {
        const config1 = GridConfig(
          horizontal: false,
          vertical: true,
          horizontalColor: Color(0xFFFF0000),
          verticalColor: Color(0xFF00FF00),
          horizontalStrokeWidth: 1.5,
          verticalStrokeWidth: 2.5,
        );
        const config2 = GridConfig(
          horizontal: false,
          vertical: true,
          horizontalColor: Color(0xFFFF0000),
          verticalColor: Color(0xFF00FF00),
          horizontalStrokeWidth: 1.5,
          verticalStrokeWidth: 2.5,
        );
        expect(config1.hashCode, equals(config2.hashCode));
      });

      test('is different for configs with different values', () {
        const config1 = GridConfig(horizontal: true);
        const config2 = GridConfig(horizontal: false);
        expect(config1.hashCode, isNot(equals(config2.hashCode)));
      });

      test('is consistent across multiple calls', () {
        const config = GridConfig(horizontalColor: Color(0xFFFF0000));
        final hash1 = config.hashCode;
        final hash2 = config.hashCode;
        expect(hash1, equals(hash2));
      });
    });

    group('toString', () {
      test('returns descriptive string with default values', () {
        const config = GridConfig();
        final str = config.toString();
        expect(str, contains('GridConfig'));
        expect(str, contains('horizontal: true'));
        expect(str, contains('vertical: true'));
        expect(str, contains('horizontalColor: null'));
        expect(str, contains('verticalColor: null'));
        expect(str, contains('horizontalStrokeWidth: 0.5'));
        expect(str, contains('verticalStrokeWidth: 0.5'));
      });

      test('returns descriptive string with custom values', () {
        const config = GridConfig(
          horizontal: false,
          vertical: true,
          horizontalColor: Color(0xFFFF0000),
          verticalColor: Color(0xFF00FF00),
          horizontalStrokeWidth: 1.5,
          verticalStrokeWidth: 2.5,
        );
        final str = config.toString();
        expect(str, contains('GridConfig'));
        expect(str, contains('horizontal: false'));
        expect(str, contains('vertical: true'));
        expect(str, contains('horizontalColor: Color('));
        expect(str, contains('red: 1.0000'));
        expect(str, contains('verticalColor: Color('));
        expect(str, contains('green: 1.0000'));
        expect(str, contains('horizontalStrokeWidth: 1.5'));
        expect(str, contains('verticalStrokeWidth: 2.5'));
      });

      test('includes all properties in output', () {
        const config = GridConfig(
          horizontalStrokeWidth: 3.0,
          verticalStrokeWidth: 4.0,
        );
        final str = config.toString();
        expect(str, contains('horizontal:'));
        expect(str, contains('vertical:'));
        expect(str, contains('horizontalColor:'));
        expect(str, contains('verticalColor:'));
        expect(str, contains('horizontalStrokeWidth:'));
        expect(str, contains('verticalStrokeWidth:'));
      });
    });

    group('immutability', () {
      test('is const constructible', () {
        const config = GridConfig();
        expect(config, isNotNull);
      });

      test('is const constructible with all parameters', () {
        const config = GridConfig(
          horizontal: false,
          vertical: false,
          horizontalColor: Color(0xFFFF0000),
          verticalColor: Color(0xFF00FF00),
          horizontalStrokeWidth: 1.0,
          verticalStrokeWidth: 2.0,
        );
        expect(config, isNotNull);
      });
    });
  });
}
