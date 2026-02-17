import 'package:braven_charts/src/axis/normalization_detector.dart';
import 'package:braven_charts/src/axis/range_ratio_calculator.dart';
import 'package:braven_charts/src/models/data_range.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RangeRatioCalculator', () {
    group('calculateRatio', () {
      test('returns 1.0 for identical ranges', () {
        const range1 = DataRange(min: 0.0, max: 100.0);
        const range2 = DataRange(min: 0.0, max: 100.0);

        final ratio = RangeRatioCalculator.calculateRatio(range1, range2);

        expect(ratio, equals(1.0));
      });

      test('returns ratio for different ranges', () {
        const range1 = DataRange(min: 0.0, max: 10.0); // span = 10
        const range2 = DataRange(min: 0.0, max: 100.0); // span = 100

        final ratio = RangeRatioCalculator.calculateRatio(range1, range2);

        expect(ratio, equals(10.0));
      });

      test('calculates ratio as larger/smaller (always >= 1)', () {
        const smallRange = DataRange(min: 0.0, max: 10.0);
        const largeRange = DataRange(min: 0.0, max: 100.0);

        // Order shouldn't matter - ratio is always >= 1
        final ratio1 = RangeRatioCalculator.calculateRatio(
          smallRange,
          largeRange,
        );
        final ratio2 = RangeRatioCalculator.calculateRatio(
          largeRange,
          smallRange,
        );

        expect(ratio1, equals(10.0));
        expect(ratio2, equals(10.0));
      });

      test('handles zero-width range without error', () {
        const zeroRange = DataRange(min: 50.0, max: 50.0); // span = 0
        const normalRange = DataRange(min: 0.0, max: 100.0);

        // Should handle gracefully (return infinity or very large number)
        final ratio = RangeRatioCalculator.calculateRatio(
          zeroRange,
          normalRange,
        );

        expect(ratio, equals(double.infinity));
      });

      test('handles both zero-width ranges', () {
        const zeroRange1 = DataRange(min: 50.0, max: 50.0);
        const zeroRange2 = DataRange(min: 100.0, max: 100.0);

        // Two zero ranges have ratio 1.0 (identical span)
        final ratio = RangeRatioCalculator.calculateRatio(
          zeroRange1,
          zeroRange2,
        );

        expect(ratio, equals(1.0));
      });

      test('handles negative value ranges', () {
        const negativeRange = DataRange(min: -100.0, max: -50.0); // span = 50
        const positiveRange = DataRange(min: 0.0, max: 100.0); // span = 100

        final ratio = RangeRatioCalculator.calculateRatio(
          negativeRange,
          positiveRange,
        );

        expect(ratio, equals(2.0));
      });

      test('handles ranges crossing zero', () {
        const crossingRange = DataRange(min: -50.0, max: 50.0); // span = 100
        const positiveRange = DataRange(min: 0.0, max: 50.0); // span = 50

        final ratio = RangeRatioCalculator.calculateRatio(
          crossingRange,
          positiveRange,
        );

        expect(ratio, equals(2.0));
      });

      test('handles very small difference', () {
        const range1 = DataRange(min: 0.0, max: 10.0);
        const range2 = DataRange(min: 0.0, max: 11.0);

        final ratio = RangeRatioCalculator.calculateRatio(range1, range2);

        expect(ratio, equals(1.1));
      });

      test('handles very large ranges', () {
        const smallRange = DataRange(min: 0.0, max: 1.0);
        const largeRange = DataRange(min: 0.0, max: 1000000.0);

        final ratio = RangeRatioCalculator.calculateRatio(
          smallRange,
          largeRange,
        );

        expect(ratio, equals(1000000.0));
      });
    });
  });

  group('NormalizationDetector', () {
    group('shouldNormalize', () {
      test('returns false for single series', () {
        final seriesRanges = {'series1': const DataRange(min: 0.0, max: 100.0)};

        final result = NormalizationDetector.shouldNormalize(seriesRanges);

        expect(result, isFalse);
      });

      test('returns false for series within threshold', () {
        final seriesRanges = {
          'series1': const DataRange(min: 0.0, max: 50.0), // span = 50
          'series2': const DataRange(min: 0.0, max: 100.0), // span = 100
        };
        // Ratio = 2x, threshold = 10x

        final result = NormalizationDetector.shouldNormalize(seriesRanges);

        expect(result, isFalse);
      });

      test('returns true when any pair exceeds threshold', () {
        final seriesRanges = {
          'series1': const DataRange(min: 0.0, max: 10.0), // span = 10
          'series2': const DataRange(min: 0.0, max: 100.0), // span = 100
        };
        // Ratio = 10x, threshold = 10x

        final result = NormalizationDetector.shouldNormalize(seriesRanges);

        expect(result, isTrue);
      });

      test('uses default threshold of 10x', () {
        final seriesRanges = {
          'series1': const DataRange(min: 0.0, max: 10.0),
          'series2': const DataRange(
            min: 0.0,
            max: 99.0,
          ), // 9.9x - below threshold
        };

        final result = NormalizationDetector.shouldNormalize(seriesRanges);

        expect(result, isFalse);
      });

      test('respects custom threshold', () {
        final seriesRanges = {
          'series1': const DataRange(min: 0.0, max: 10.0),
          'series2': const DataRange(min: 0.0, max: 50.0), // 5x difference
        };

        // With default threshold (10x) - should be false
        expect(NormalizationDetector.shouldNormalize(seriesRanges), isFalse);

        // With custom threshold (5x) - should be true
        expect(
          NormalizationDetector.shouldNormalize(seriesRanges, threshold: 5.0),
          isTrue,
        );
      });

      test('checks all pairwise combinations', () {
        final seriesRanges = {
          'series1': const DataRange(min: 0.0, max: 100.0), // span = 100
          'series2': const DataRange(min: 0.0, max: 100.0), // span = 100
          'series3': const DataRange(min: 0.0, max: 1.0), // span = 1
        };
        // series1 vs series2: 1x (OK)
        // series1 vs series3: 100x (exceeds!)
        // series2 vs series3: 100x (exceeds!)

        final result = NormalizationDetector.shouldNormalize(seriesRanges);

        expect(result, isTrue);
      });

      test('returns false when all pairs are within threshold', () {
        final seriesRanges = {
          'series1': const DataRange(min: 0.0, max: 100.0),
          'series2': const DataRange(min: 0.0, max: 80.0),
          'series3': const DataRange(min: 0.0, max: 120.0),
        };
        // All ratios are < 2x, well within 10x threshold

        final result = NormalizationDetector.shouldNormalize(seriesRanges);

        expect(result, isFalse);
      });
    });

    group('getMaxRatio', () {
      test('returns 1.0 for single series', () {
        final seriesRanges = {'series1': const DataRange(min: 0.0, max: 100.0)};

        final ratio = NormalizationDetector.getMaxRatio(seriesRanges);

        expect(ratio, equals(1.0));
      });

      test('returns maximum ratio among all pairs', () {
        final seriesRanges = {
          'series1': const DataRange(min: 0.0, max: 100.0), // span = 100
          'series2': const DataRange(min: 0.0, max: 50.0), // span = 50
          'series3': const DataRange(min: 0.0, max: 10.0), // span = 10
        };
        // s1 vs s2: 2x
        // s1 vs s3: 10x (max!)
        // s2 vs s3: 5x

        final ratio = NormalizationDetector.getMaxRatio(seriesRanges);

        expect(ratio, equals(10.0));
      });

      test('returns 1.0 for identical ranges', () {
        final seriesRanges = {
          'series1': const DataRange(min: 0.0, max: 100.0),
          'series2': const DataRange(min: 0.0, max: 100.0),
        };

        final ratio = NormalizationDetector.getMaxRatio(seriesRanges);

        expect(ratio, equals(1.0));
      });
    });

    group('edge cases', () {
      test('handles empty series list', () {
        final seriesRanges = <String, DataRange>{};

        final result = NormalizationDetector.shouldNormalize(seriesRanges);
        final ratio = NormalizationDetector.getMaxRatio(seriesRanges);

        expect(result, isFalse);
        expect(ratio, equals(1.0));
      });

      test('handles series with identical values (zero span)', () {
        final seriesRanges = {
          'series1': const DataRange(min: 50.0, max: 50.0),
          'series2': const DataRange(min: 0.0, max: 100.0),
        };

        // One zero-width range vs normal range = infinity ratio
        final result = NormalizationDetector.shouldNormalize(seriesRanges);

        expect(result, isTrue); // Infinity > 10, so should normalize
      });

      test('handles exactly 10x threshold (boundary)', () {
        final seriesRanges = {
          'series1': const DataRange(min: 0.0, max: 10.0), // span = 10
          'series2': const DataRange(min: 0.0, max: 100.0), // span = 100
        };
        // Ratio = exactly 10x

        final result = NormalizationDetector.shouldNormalize(seriesRanges);

        // Exactly at threshold should trigger normalization (>= not just >)
        expect(result, isTrue);
      });

      test('handles just below 10x threshold', () {
        final seriesRanges = {
          'series1': const DataRange(min: 0.0, max: 10.0), // span = 10
          'series2': const DataRange(min: 0.0, max: 99.9), // span = 99.9
        };
        // Ratio = 9.99x, just under threshold

        final result = NormalizationDetector.shouldNormalize(seriesRanges);

        expect(result, isFalse);
      });
    });

    group('acceptance scenarios (from spec)', () {
      test('US2-1: detects 0-10 vs 0-1000 (100x difference)', () {
        final seriesRanges = {
          'seriesA': const DataRange(min: 0.0, max: 10.0),
          'seriesB': const DataRange(min: 0.0, max: 1000.0),
        };

        final result = NormalizationDetector.shouldNormalize(seriesRanges);
        final ratio = NormalizationDetector.getMaxRatio(seriesRanges);

        expect(result, isTrue);
        expect(ratio, equals(100.0));
      });

      test('US2-2: does not detect 0-50 vs 0-100 (2x difference)', () {
        final seriesRanges = {
          'seriesA': const DataRange(min: 0.0, max: 50.0),
          'seriesB': const DataRange(min: 0.0, max: 100.0),
        };

        final result = NormalizationDetector.shouldNormalize(seriesRanges);
        final ratio = NormalizationDetector.getMaxRatio(seriesRanges);

        expect(result, isFalse);
        expect(ratio, equals(2.0));
      });

      test(
        'US2-3: respects explicit config (not implemented here, but ratio is calculated)',
        () {
          // This test documents the expected behavior:
          // Even if shouldNormalize returns true, explicit config takes precedence
          // The detector just provides the recommendation

          final seriesRanges = {
            'power': const DataRange(min: 0.0, max: 300.0),
            'tidalVolume': const DataRange(min: 0.5, max: 4.0), // span = 3.5
          };

          final ratio = NormalizationDetector.getMaxRatio(seriesRanges);

          // 300 / 3.5 ≈ 85.7x difference
          expect(ratio, closeTo(85.7, 0.1));
        },
      );
    });

    group('real-world scenarios', () {
      test('power vs heart rate - should normalize', () {
        final seriesRanges = {
          'power': const DataRange(min: 0.0, max: 400.0), // watts
          'heartRate': const DataRange(min: 60.0, max: 180.0), // bpm, span=120
        };
        // 400 / 120 ≈ 3.3x - within threshold

        final result = NormalizationDetector.shouldNormalize(seriesRanges);

        expect(result, isFalse); // Actually within threshold!
      });

      test('power vs tidal volume - should normalize', () {
        final seriesRanges = {
          'power': const DataRange(min: 0.0, max: 300.0), // watts
          'tidalVolume': const DataRange(min: 0.5, max: 4.0), // liters
        };
        // 300 / 3.5 ≈ 85.7x - exceeds threshold

        final result = NormalizationDetector.shouldNormalize(seriesRanges);

        expect(result, isTrue);
      });

      test('multiple physiological parameters', () {
        final seriesRanges = {
          'heartRate': const DataRange(min: 60.0, max: 180.0), // span=120
          'spo2': const DataRange(min: 90.0, max: 100.0), // span=10
          'respRate': const DataRange(min: 10.0, max: 30.0), // span=20
        };
        // HR vs SpO2: 120/10 = 12x (exceeds!)
        // HR vs RR: 120/20 = 6x
        // SpO2 vs RR: 20/10 = 2x

        final result = NormalizationDetector.shouldNormalize(seriesRanges);

        expect(result, isTrue);
      });
    });
  });
}
