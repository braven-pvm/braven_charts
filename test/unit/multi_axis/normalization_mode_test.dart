import 'package:braven_charts/src/models/normalization_mode.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NormalizationMode', () {
    test('has exactly 3 values', () {
      expect(NormalizationMode.values.length, equals(3));
    });

    test('contains disabled value', () {
      expect(
        NormalizationMode.values.contains(NormalizationMode.disabled),
        isTrue,
      );
    });

    test('contains auto value', () {
      expect(
        NormalizationMode.values.contains(NormalizationMode.auto),
        isTrue,
      );
    });

    test('contains always value', () {
      expect(
        NormalizationMode.values.contains(NormalizationMode.always),
        isTrue,
      );
    });

    group('order', () {
      test('disabled is first (index 0)', () {
        expect(NormalizationMode.disabled.index, equals(0));
      });

      test('auto is second (index 1)', () {
        expect(NormalizationMode.auto.index, equals(1));
      });

      test('always is third (index 2)', () {
        expect(NormalizationMode.always.index, equals(2));
      });

      test('values are in correct order', () {
        expect(
            NormalizationMode.values,
            equals([
              NormalizationMode.disabled,
              NormalizationMode.auto,
              NormalizationMode.always,
            ]));
      });
    });

    group('names', () {
      test('disabled has correct name', () {
        expect(NormalizationMode.disabled.name, equals('disabled'));
      });

      test('auto has correct name', () {
        expect(NormalizationMode.auto.name, equals('auto'));
      });

      test('always has correct name', () {
        expect(NormalizationMode.always.name, equals('always'));
      });
    });
  });
}
