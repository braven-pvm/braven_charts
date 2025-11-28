import 'package:braven_charts/legacy/src/axis/data_normalizer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DataNormalizer', () {
    group('normalize()', () {
      test('returns 0.0 when value equals min', () {
        // Arrange
        const value = 100.0;
        const min = 100.0;
        const max = 200.0;

        // Act
        final result = DataNormalizer.normalize(value, min, max);

        // Assert
        expect(result, equals(0.0));
      });

      test('returns 1.0 when value equals max', () {
        // Arrange
        const value = 200.0;
        const min = 100.0;
        const max = 200.0;

        // Act
        final result = DataNormalizer.normalize(value, min, max);

        // Assert
        expect(result, equals(1.0));
      });

      test('returns 0.5 for mid-range value', () {
        // Arrange
        const value = 150.0;
        const min = 100.0;
        const max = 200.0;

        // Act
        final result = DataNormalizer.normalize(value, min, max);

        // Assert
        expect(result, equals(0.5));
      });

      test('returns 0.5 when min equals max (zero range)', () {
        // Arrange
        const value = 100.0;
        const min = 100.0;
        const max = 100.0;

        // Act
        final result = DataNormalizer.normalize(value, min, max);

        // Assert
        expect(result, equals(0.5));
      });

      test('returns value < 0.0 when value is below min', () {
        // Arrange
        const value = 50.0;
        const min = 100.0;
        const max = 200.0;

        // Act
        final result = DataNormalizer.normalize(value, min, max);

        // Assert
        expect(result, equals(-0.5));
        expect(result, lessThan(0.0));
      });

      test('returns value > 1.0 when value is above max', () {
        // Arrange
        const value = 250.0;
        const min = 100.0;
        const max = 200.0;

        // Act
        final result = DataNormalizer.normalize(value, min, max);

        // Assert
        expect(result, equals(1.5));
        expect(result, greaterThan(1.0));
      });

      test('handles negative ranges correctly', () {
        // Arrange
        const value = -50.0;
        const min = -100.0;
        const max = 0.0;

        // Act
        final result = DataNormalizer.normalize(value, min, max);

        // Assert
        expect(result, equals(0.5));
      });

      test('handles ranges crossing zero correctly', () {
        // Arrange
        const value = 0.0;
        const min = -50.0;
        const max = 50.0;

        // Act
        final result = DataNormalizer.normalize(value, min, max);

        // Assert
        expect(result, equals(0.5));
      });
    });

    group('denormalize()', () {
      test('returns min when normalized value is 0.0', () {
        // Arrange
        const normalized = 0.0;
        const min = 100.0;
        const max = 200.0;

        // Act
        final result = DataNormalizer.denormalize(normalized, min, max);

        // Assert
        expect(result, equals(100.0));
      });

      test('returns max when normalized value is 1.0', () {
        // Arrange
        const normalized = 1.0;
        const min = 100.0;
        const max = 200.0;

        // Act
        final result = DataNormalizer.denormalize(normalized, min, max);

        // Assert
        expect(result, equals(200.0));
      });

      test('returns mid-range value when normalized is 0.5', () {
        // Arrange
        const normalized = 0.5;
        const min = 100.0;
        const max = 200.0;

        // Act
        final result = DataNormalizer.denormalize(normalized, min, max);

        // Assert
        expect(result, equals(150.0));
      });

      test('returns min when min equals max (zero range)', () {
        // Arrange
        const normalized = 0.5;
        const min = 100.0;
        const max = 100.0;

        // Act
        final result = DataNormalizer.denormalize(normalized, min, max);

        // Assert
        expect(result, equals(100.0));
      });

      test('returns value below min when normalized < 0.0', () {
        // Arrange
        const normalized = -0.5;
        const min = 100.0;
        const max = 200.0;

        // Act
        final result = DataNormalizer.denormalize(normalized, min, max);

        // Assert
        expect(result, equals(50.0));
        expect(result, lessThan(min));
      });

      test('returns value above max when normalized > 1.0', () {
        // Arrange
        const normalized = 1.5;
        const min = 100.0;
        const max = 200.0;

        // Act
        final result = DataNormalizer.denormalize(normalized, min, max);

        // Assert
        expect(result, equals(250.0));
        expect(result, greaterThan(max));
      });
    });

    group('roundtrip tests', () {
      test('normalize then denormalize returns original value', () {
        // Arrange
        const originalValue = 150.0;
        const min = 100.0;
        const max = 200.0;

        // Act
        final normalized = DataNormalizer.normalize(originalValue, min, max);
        final denormalized = DataNormalizer.denormalize(normalized, min, max);

        // Assert
        expect(denormalized, equals(originalValue));
      });

      test('denormalize then normalize returns original normalized value', () {
        // Arrange
        const originalNormalized = 0.75;
        const min = 0.0;
        const max = 100.0;

        // Act
        final denormalized = DataNormalizer.denormalize(
          originalNormalized,
          min,
          max,
        );
        final normalized = DataNormalizer.normalize(denormalized, min, max);

        // Assert
        expect(normalized, equals(originalNormalized));
      });

      test('roundtrip with values outside range preserves value', () {
        // Arrange
        const outsideValue = 250.0; // Above max
        const min = 100.0;
        const max = 200.0;

        // Act
        final normalized = DataNormalizer.normalize(outsideValue, min, max);
        final denormalized = DataNormalizer.denormalize(normalized, min, max);

        // Assert
        expect(denormalized, equals(outsideValue));
      });

      test('roundtrip with negative range preserves value', () {
        // Arrange
        const originalValue = -25.0;
        const min = -100.0;
        const max = 0.0;

        // Act
        final normalized = DataNormalizer.normalize(originalValue, min, max);
        final denormalized = DataNormalizer.denormalize(normalized, min, max);

        // Assert
        expect(denormalized, equals(originalValue));
      });
    });
  });
}
