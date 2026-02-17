import 'package:braven_charts/src/models/normalization_mode.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NormalizationMode', () {
    test('has exactly 3 values', () {
      expect(NormalizationMode.values.length, equals(3));
    });

    test('contains none value', () {
      expect(NormalizationMode.values.contains(NormalizationMode.none), isTrue);
    });

    test('contains auto value', () {
      expect(NormalizationMode.values.contains(NormalizationMode.auto), isTrue);
    });

    test('contains perSeries value', () {
      expect(
        NormalizationMode.values.contains(NormalizationMode.perSeries),
        isTrue,
      );
    });

    group('order', () {
      test('none is first (index 0)', () {
        expect(NormalizationMode.none.index, equals(0));
      });

      test('auto is second (index 1)', () {
        expect(NormalizationMode.auto.index, equals(1));
      });

      test('perSeries is third (index 2)', () {
        expect(NormalizationMode.perSeries.index, equals(2));
      });

      test('values are in correct order', () {
        expect(
          NormalizationMode.values,
          equals([
            NormalizationMode.none,
            NormalizationMode.auto,
            NormalizationMode.perSeries,
          ]),
        );
      });
    });

    group('names', () {
      test('none has correct name', () {
        expect(NormalizationMode.none.name, equals('none'));
      });

      test('auto has correct name', () {
        expect(NormalizationMode.auto.name, equals('auto'));
      });

      test('perSeries has correct name', () {
        expect(NormalizationMode.perSeries.name, equals('perSeries'));
      });
    });
  });
}
