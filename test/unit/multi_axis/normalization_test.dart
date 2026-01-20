import 'package:braven_charts/src/rendering/multi_axis_normalizer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MultiAxisNormalizer', () {
    group('normalize', () {
      test('normalizes minimum value to 0.0', () {
        // Value at min should normalize to 0.0
        final result = MultiAxisNormalizer.normalize(0.0, 0.0, 100.0);
        expect(result, equals(0.0));
      });

      test('normalizes maximum value to 1.0', () {
        // Value at max should normalize to 1.0
        final result = MultiAxisNormalizer.normalize(100.0, 0.0, 100.0);
        expect(result, equals(1.0));
      });

      test('normalizes midpoint value to 0.5', () {
        // Value at midpoint should normalize to 0.5
        final result = MultiAxisNormalizer.normalize(50.0, 0.0, 100.0);
        expect(result, equals(0.5));
      });

      test('normalizes quarter point correctly', () {
        // 25% of the way should normalize to 0.25
        final result = MultiAxisNormalizer.normalize(25.0, 0.0, 100.0);
        expect(result, equals(0.25));
      });

      test('normalizes values below minimum to negative', () {
        // Value below min should result in negative normalized value
        final result = MultiAxisNormalizer.normalize(-20.0, 0.0, 100.0);
        expect(result, equals(-0.2));
      });

      test('normalizes values above maximum to greater than 1', () {
        // Value above max should result in normalized value > 1
        final result = MultiAxisNormalizer.normalize(150.0, 0.0, 100.0);
        expect(result, equals(1.5));
      });

      test('handles negative ranges (min=-100, max=100)', () {
        // Negative range: -100 to 100
        expect(
            MultiAxisNormalizer.normalize(-100.0, -100.0, 100.0), equals(0.0));
        expect(MultiAxisNormalizer.normalize(0.0, -100.0, 100.0), equals(0.5));
        expect(
            MultiAxisNormalizer.normalize(100.0, -100.0, 100.0), equals(1.0));
      });

      test('handles fully negative ranges', () {
        // Range from -200 to -100
        expect(
            MultiAxisNormalizer.normalize(-200.0, -200.0, -100.0), equals(0.0));
        expect(
            MultiAxisNormalizer.normalize(-150.0, -200.0, -100.0), equals(0.5));
        expect(
            MultiAxisNormalizer.normalize(-100.0, -200.0, -100.0), equals(1.0));
      });

      test('handles decimal precision', () {
        // Small decimal range: 0.1 to 0.9
        expect(
          MultiAxisNormalizer.normalize(0.1, 0.1, 0.9),
          equals(0.0),
        );
        expect(
          MultiAxisNormalizer.normalize(0.5, 0.1, 0.9),
          equals(0.5),
        );
        expect(
          MultiAxisNormalizer.normalize(0.9, 0.1, 0.9),
          equals(1.0),
        );
      });

      test('handles non-zero based ranges', () {
        // Range from 100 to 200
        expect(MultiAxisNormalizer.normalize(100.0, 100.0, 200.0), equals(0.0));
        expect(MultiAxisNormalizer.normalize(150.0, 100.0, 200.0), equals(0.5));
        expect(MultiAxisNormalizer.normalize(200.0, 100.0, 200.0), equals(1.0));
      });
    });

    group('denormalize', () {
      test('denormalizes 0.0 to minimum value', () {
        final result = MultiAxisNormalizer.denormalize(0.0, 0.0, 100.0);
        expect(result, equals(0.0));
      });

      test('denormalizes 1.0 to maximum value', () {
        final result = MultiAxisNormalizer.denormalize(1.0, 0.0, 100.0);
        expect(result, equals(100.0));
      });

      test('denormalizes 0.5 to midpoint value', () {
        final result = MultiAxisNormalizer.denormalize(0.5, 0.0, 100.0);
        expect(result, equals(50.0));
      });

      test('denormalizes 0.25 to quarter value', () {
        final result = MultiAxisNormalizer.denormalize(0.25, 0.0, 100.0);
        expect(result, equals(25.0));
      });

      test('denormalizes values outside 0-1 range', () {
        // Negative normalized value
        expect(
            MultiAxisNormalizer.denormalize(-0.2, 0.0, 100.0), equals(-20.0));
        // Normalized value > 1
        expect(MultiAxisNormalizer.denormalize(1.5, 0.0, 100.0), equals(150.0));
      });

      test('handles negative ranges', () {
        expect(
          MultiAxisNormalizer.denormalize(0.0, -100.0, 100.0),
          equals(-100.0),
        );
        expect(
          MultiAxisNormalizer.denormalize(0.5, -100.0, 100.0),
          equals(0.0),
        );
        expect(
          MultiAxisNormalizer.denormalize(1.0, -100.0, 100.0),
          equals(100.0),
        );
      });

      test('round-trip preserves original value', () {
        const originalValue = 73.5;
        const min = 10.0;
        const max = 200.0;

        final normalized =
            MultiAxisNormalizer.normalize(originalValue, min, max);
        final recovered = MultiAxisNormalizer.denormalize(normalized, min, max);

        expect(recovered, closeTo(originalValue, 1e-10));
      });

      test('round-trip preserves edge values', () {
        const min = -50.0;
        const max = 150.0;

        // Test min value
        final normalizedMin = MultiAxisNormalizer.normalize(min, min, max);
        final recoveredMin =
            MultiAxisNormalizer.denormalize(normalizedMin, min, max);
        expect(recoveredMin, closeTo(min, 1e-10));

        // Test max value
        final normalizedMax = MultiAxisNormalizer.normalize(max, min, max);
        final recoveredMax =
            MultiAxisNormalizer.denormalize(normalizedMax, min, max);
        expect(recoveredMax, closeTo(max, 1e-10));
      });

      test('multiple round-trips preserve value', () {
        const originalValue = 42.0;
        const min = 0.0;
        const max = 100.0;

        var value = originalValue;
        for (var i = 0; i < 10; i++) {
          final normalized = MultiAxisNormalizer.normalize(value, min, max);
          value = MultiAxisNormalizer.denormalize(normalized, min, max);
        }

        expect(value, closeTo(originalValue, 1e-10));
      });
    });

    group('edge cases', () {
      test('handles zero range (min == max) without division by zero', () {
        // When min equals max, should return 0.5 (middle of normalized range)
        final result = MultiAxisNormalizer.normalize(100.0, 100.0, 100.0);
        expect(result, equals(0.5));
      });

      test('denormalize handles zero range', () {
        // When min equals max, denormalize should return that value
        final result = MultiAxisNormalizer.denormalize(0.5, 100.0, 100.0);
        expect(result, equals(100.0));
      });

      test('handles very small range (e.g., 0.001 difference)', () {
        const min = 1.0;
        const max = 1.001;

        expect(
          MultiAxisNormalizer.normalize(min, min, max),
          equals(0.0),
        );
        expect(
          MultiAxisNormalizer.normalize(max, min, max),
          equals(1.0),
        );
        expect(
          MultiAxisNormalizer.normalize(1.0005, min, max),
          equals(0.5),
        );
      });

      test('handles very large values without overflow', () {
        const min = 1e15;
        const max = 2e15;
        const mid = 1.5e15;

        expect(
          MultiAxisNormalizer.normalize(min, min, max),
          equals(0.0),
        );
        expect(
          MultiAxisNormalizer.normalize(max, min, max),
          equals(1.0),
        );
        expect(
          MultiAxisNormalizer.normalize(mid, min, max),
          equals(0.5),
        );
      });

      test('handles very small values near zero', () {
        const min = 1e-15;
        const max = 2e-15;
        const mid = 1.5e-15;

        expect(
          MultiAxisNormalizer.normalize(min, min, max),
          equals(0.0),
        );
        expect(
          MultiAxisNormalizer.normalize(max, min, max),
          equals(1.0),
        );
        expect(
          MultiAxisNormalizer.normalize(mid, min, max),
          closeTo(0.5, 1e-10),
        );
      });

      test('handles single data point series scenario', () {
        // Single point at value 42 - creates zero range
        const singleValue = 42.0;
        final result = MultiAxisNormalizer.normalize(
          singleValue,
          singleValue,
          singleValue,
        );
        expect(result, equals(0.5));
      });

      test('handles infinity values gracefully', () {
        // Infinite range handling - these should not crash
        expect(
          MultiAxisNormalizer.normalize(50.0, 0.0, double.infinity),
          equals(0.0),
        );
      });
    });
  });
}
