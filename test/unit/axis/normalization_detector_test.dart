import 'package:braven_charts/src/axis/normalization_detector.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SeriesRange', () {
    test('calculates span correctly', () {
      // Arrange
      const range = SeriesRange(seriesId: 'test', min: 100.0, max: 200.0);

      // Assert
      expect(range.span, equals(100.0));
    });

    test('span is zero when min equals max', () {
      // Arrange
      const range = SeriesRange(seriesId: 'test', min: 50.0, max: 50.0);

      // Assert
      expect(range.span, equals(0.0));
    });

    test('equality works correctly', () {
      // Arrange
      const range1 = SeriesRange(seriesId: 'a', min: 0.0, max: 100.0);
      const range2 = SeriesRange(seriesId: 'a', min: 0.0, max: 100.0);
      const range3 = SeriesRange(seriesId: 'b', min: 0.0, max: 100.0);

      // Assert
      expect(range1, equals(range2));
      expect(range1, isNot(equals(range3)));
    });

    test('copyWith creates modified copy', () {
      // Arrange
      const original = SeriesRange(seriesId: 'test', min: 0.0, max: 100.0);

      // Act
      final modified = original.copyWith(max: 200.0);

      // Assert
      expect(modified.seriesId, equals('test'));
      expect(modified.min, equals(0.0));
      expect(modified.max, equals(200.0));
      expect(modified.span, equals(200.0));
    });

    test('toString returns descriptive string', () {
      // Arrange
      const range = SeriesRange(seriesId: 'power', min: 0.0, max: 300.0);

      // Act
      final result = range.toString();

      // Assert
      expect(result, contains('power'));
      expect(result, contains('0.0'));
      expect(result, contains('300.0'));
    });
  });

  group('NormalizationDetector', () {
    group('shouldNormalize()', () {
      test('returns false for similar ranges within threshold', () {
        // Arrange - Two series with similar ranges (ratio = 2.0, below default 10.0)
        final ranges = [
          const SeriesRange(seriesId: 'a', min: 0.0, max: 100.0), // span: 100
          const SeriesRange(seriesId: 'b', min: 0.0, max: 200.0), // span: 200
        ];

        // Act
        final result = NormalizationDetector.shouldNormalize(ranges);

        // Assert
        expect(result, isFalse);
      });

      test('returns true for different ranges exceeding threshold', () {
        // Arrange - Power (0-300W) vs Tidal Volume (0.5-4.0L)
        // Spans: 300 vs 3.5, ratio = 85.7 > 10
        final ranges = [
          const SeriesRange(seriesId: 'power', min: 0.0, max: 300.0), // span: 300
          const SeriesRange(
            seriesId: 'tidalVolume',
            min: 0.5,
            max: 4.0,
          ), // span: 3.5
        ];

        // Act
        final result = NormalizationDetector.shouldNormalize(ranges);

        // Assert
        expect(result, isTrue);
      });

      test('respects custom threshold parameter', () {
        // Arrange - Ratio of 5.0 (500/100)
        final ranges = [
          const SeriesRange(seriesId: 'a', min: 0.0, max: 100.0), // span: 100
          const SeriesRange(seriesId: 'b', min: 0.0, max: 500.0), // span: 500
        ];

        // Act & Assert - With threshold 10, should be false (5 < 10)
        expect(
          NormalizationDetector.shouldNormalize(ranges, threshold: 10.0),
          isFalse,
        );

        // Act & Assert - With threshold 3, should be true (5 >= 3)
        expect(
          NormalizationDetector.shouldNormalize(ranges, threshold: 3.0),
          isTrue,
        );
      });

      test('returns false for single series', () {
        // Arrange
        final ranges = [
          const SeriesRange(seriesId: 'only', min: 0.0, max: 1000.0),
        ];

        // Act
        final result = NormalizationDetector.shouldNormalize(ranges);

        // Assert
        expect(result, isFalse);
      });

      test('returns false for empty list', () {
        // Arrange
        final ranges = <SeriesRange>[];

        // Act
        final result = NormalizationDetector.shouldNormalize(ranges);

        // Assert
        expect(result, isFalse);
      });

      test('returns false for identical ranges', () {
        // Arrange - Three series with identical ranges
        final ranges = [
          const SeriesRange(seriesId: 'a', min: 0.0, max: 100.0),
          const SeriesRange(seriesId: 'b', min: 0.0, max: 100.0),
          const SeriesRange(seriesId: 'c', min: 0.0, max: 100.0),
        ];

        // Act
        final result = NormalizationDetector.shouldNormalize(ranges);

        // Assert
        expect(result, isFalse);
      });

      test('handles zero span series gracefully', () {
        // Arrange - One series with zero span (constant value)
        final ranges = [
          const SeriesRange(seriesId: 'constant', min: 50.0, max: 50.0), // span: 0
          const SeriesRange(seriesId: 'normal', min: 0.0, max: 100.0), // span: 100
        ];

        // Act - Should not throw, should handle gracefully
        final result = NormalizationDetector.shouldNormalize(ranges);

        // Assert - With zero span, normalization is needed (infinite ratio)
        expect(result, isTrue);
      });

      test('handles all zero span series gracefully', () {
        // Arrange - All series with zero span
        final ranges = [
          const SeriesRange(seriesId: 'a', min: 50.0, max: 50.0), // span: 0
          const SeriesRange(seriesId: 'b', min: 100.0, max: 100.0), // span: 0
        ];

        // Act - Should not throw
        final result = NormalizationDetector.shouldNormalize(ranges);

        // Assert - All zero spans means identical (zero) spans, no normalization needed
        expect(result, isFalse);
      });

      test('works with three series where one outlier exists', () {
        // Arrange - Heart rate and power similar, tidal volume very different
        final ranges = [
          const SeriesRange(
            seriesId: 'heartRate',
            min: 60.0,
            max: 200.0,
          ), // span: 140
          const SeriesRange(seriesId: 'power', min: 0.0, max: 300.0), // span: 300
          const SeriesRange(
            seriesId: 'tidalVolume',
            min: 0.5,
            max: 4.0,
          ), // span: 3.5
        ];

        // Act - Largest (300) / Smallest (3.5) = 85.7 > 10
        final result = NormalizationDetector.shouldNormalize(ranges);

        // Assert
        expect(result, isTrue);
      });

      test('handles negative value ranges', () {
        // Arrange - Temperature range crossing zero
        final ranges = [
          const SeriesRange(
            seriesId: 'temp',
            min: -20.0,
            max: 40.0,
          ), // span: 60
          const SeriesRange(
            seriesId: 'humidity',
            min: 0.0,
            max: 100.0,
          ), // span: 100
        ];

        // Act - Ratio 100/60 = 1.67 < 10
        final result = NormalizationDetector.shouldNormalize(ranges);

        // Assert
        expect(result, isFalse);
      });

      test('exact threshold boundary returns true', () {
        // Arrange - Exactly at threshold (ratio = 10.0)
        final ranges = [
          const SeriesRange(seriesId: 'a', min: 0.0, max: 10.0), // span: 10
          const SeriesRange(seriesId: 'b', min: 0.0, max: 100.0), // span: 100
        ];

        // Act - Ratio = 10.0, threshold = 10.0, should be true (>=)
        final result = NormalizationDetector.shouldNormalize(
          ranges,
          threshold: 10.0,
        );

        // Assert
        expect(result, isTrue);
      });

      test('just below threshold boundary returns false', () {
        // Arrange - Just below threshold
        final ranges = [
          const SeriesRange(seriesId: 'a', min: 0.0, max: 10.1), // span: 10.1
          const SeriesRange(seriesId: 'b', min: 0.0, max: 100.0), // span: 100
        ];

        // Act - Ratio = 100/10.1 ≈ 9.9 < 10
        final result = NormalizationDetector.shouldNormalize(
          ranges,
          threshold: 10.0,
        );

        // Assert
        expect(result, isFalse);
      });
    });
  });
}
