// Copyright 2025 Braven Charts - Auto-Detection Algorithm Tests
// SPDX-License-Identifier: MIT

import 'package:braven_charts/src_plus/axis/normalization_detector.dart';
import 'package:braven_charts/src_plus/axis/range_ratio_calculator.dart';
import 'package:braven_charts/src_plus/models/chart_data_point.dart';
import 'package:braven_charts/src_plus/models/chart_series.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RangeRatioCalculator', () {
    group('computeRange', () {
      test('computes correct min/max for positive values', () {
        final points = [
          const ChartDataPoint(x: 0, y: 10),
          const ChartDataPoint(x: 1, y: 50),
          const ChartDataPoint(x: 2, y: 30),
        ];

        final range = RangeRatioCalculator.computeRange(points);

        expect(range, isNotNull);
        expect(range!.min, 10);
        expect(range.max, 50);
        expect(range.span, 40);
      });

      test('computes correct range for mixed positive/negative values', () {
        final points = [
          const ChartDataPoint(x: 0, y: -20),
          const ChartDataPoint(x: 1, y: 30),
          const ChartDataPoint(x: 2, y: 0),
        ];

        final range = RangeRatioCalculator.computeRange(points);

        expect(range, isNotNull);
        expect(range!.min, -20);
        expect(range.max, 30);
        expect(range.span, 50);
      });

      test('handles single point (span is 0)', () {
        final points = [const ChartDataPoint(x: 0, y: 100)];

        final range = RangeRatioCalculator.computeRange(points);

        expect(range, isNotNull);
        expect(range!.min, 100);
        expect(range.max, 100);
        expect(range.span, 0);
      });

      test('returns null for empty points', () {
        final range = RangeRatioCalculator.computeRange([]);

        expect(range, isNull);
      });

      test('handles very small ranges (sub-unit)', () {
        final points = [
          const ChartDataPoint(x: 0, y: 0.001),
          const ChartDataPoint(x: 1, y: 0.005),
        ];

        final range = RangeRatioCalculator.computeRange(points);

        expect(range!.min, 0.001);
        expect(range.max, 0.005);
        expect(range.span, closeTo(0.004, 0.0001));
      });

      test('handles very large ranges', () {
        final points = [
          const ChartDataPoint(x: 0, y: 1000000),
          const ChartDataPoint(x: 1, y: 5000000),
        ];

        final range = RangeRatioCalculator.computeRange(points);

        expect(range!.span, 4000000);
      });
    });

    group('computeRangeRatio', () {
      test('computes correct ratio for Power vs Heart Rate (typical ~2x)', () {
        // Power: 100-250W (span: 150)
        final powerRange = SeriesRange(min: 100, max: 250);
        // Heart Rate: 60-180bpm (span: 120)
        final hrRange = SeriesRange(min: 60, max: 180);

        final ratio = RangeRatioCalculator.computeRangeRatio(powerRange, hrRange);

        expect(ratio, closeTo(1.25, 0.01)); // 150/120 = 1.25
      });

      test('computes correct ratio for vastly different ranges (>10x)', () {
        // Power: 100-250W (span: 150)
        final powerRange = SeriesRange(min: 100, max: 250);
        // Micro-volts: 0.001-0.005 (span: 0.004)
        final microVoltRange = SeriesRange(min: 0.001, max: 0.005);

        final ratio = RangeRatioCalculator.computeRangeRatio(powerRange, microVoltRange);

        expect(ratio, greaterThan(10)); // 150/0.004 = 37500
      });

      test('returns 1.0 for identical ranges', () {
        final range1 = SeriesRange(min: 0, max: 100);
        final range2 = SeriesRange(min: 0, max: 100);

        final ratio = RangeRatioCalculator.computeRangeRatio(range1, range2);

        expect(ratio, 1.0);
      });

      test('handles zero span in one series (avoids division by zero)', () {
        final zeroSpan = SeriesRange(min: 100, max: 100);
        final normalRange = SeriesRange(min: 0, max: 100);

        final ratio = RangeRatioCalculator.computeRangeRatio(zeroSpan, normalRange);

        expect(ratio, double.infinity);
      });

      test('ratio is always >= 1 (larger/smaller)', () {
        final small = SeriesRange(min: 0, max: 10);
        final large = SeriesRange(min: 0, max: 1000);

        // Regardless of argument order, ratio should be >= 1
        final ratio1 = RangeRatioCalculator.computeRangeRatio(small, large);
        final ratio2 = RangeRatioCalculator.computeRangeRatio(large, small);

        expect(ratio1, greaterThanOrEqualTo(1.0));
        expect(ratio2, greaterThanOrEqualTo(1.0));
        expect(ratio1, ratio2); // Should be the same
      });
    });

    group('computeMaxRatioAcrossSeries', () {
      test('finds maximum ratio among multiple series', () {
        final series = [
          const LineChartSeries(
            id: 'power',
            name: 'Power',
            points: [
              ChartDataPoint(x: 0, y: 100),
              ChartDataPoint(x: 1, y: 250),
            ],
            color: Colors.blue,
          ),
          const LineChartSeries(
            id: 'hr',
            name: 'Heart Rate',
            points: [
              ChartDataPoint(x: 0, y: 60),
              ChartDataPoint(x: 1, y: 180),
            ],
            color: Colors.red,
          ),
          const LineChartSeries(
            id: 'micro',
            name: 'Micro-Volts',
            points: [
              ChartDataPoint(x: 0, y: 0.001),
              ChartDataPoint(x: 1, y: 0.005),
            ],
            color: Colors.green,
          ),
        ];

        final result = RangeRatioCalculator.computeMaxRatioAcrossSeries(series);

        // Power vs Micro-Volts should have the largest ratio
        expect(result.maxRatio, greaterThan(1000));
        expect(result.series1Id, isNotNull);
        expect(result.series2Id, isNotNull);
      });

      test('returns 1.0 for single series', () {
        final series = [
          const LineChartSeries(
            id: 'only',
            name: 'Only Series',
            points: [
              ChartDataPoint(x: 0, y: 0),
              ChartDataPoint(x: 1, y: 100),
            ],
            color: Colors.blue,
          ),
        ];

        final result = RangeRatioCalculator.computeMaxRatioAcrossSeries(series);

        expect(result.maxRatio, 1.0);
      });

      test('returns 1.0 for empty series list', () {
        final result = RangeRatioCalculator.computeMaxRatioAcrossSeries([]);

        expect(result.maxRatio, 1.0);
      });
    });
  });

  group('NormalizationDetector', () {
    group('shouldNormalize', () {
      test('returns true when ratio exceeds threshold', () {
        final series = [
          const LineChartSeries(
            id: 'power',
            name: 'Power',
            points: [
              ChartDataPoint(x: 0, y: 100),
              ChartDataPoint(x: 1, y: 250),
            ],
            color: Colors.blue,
          ),
          const LineChartSeries(
            id: 'micro',
            name: 'Micro-Volts',
            points: [
              ChartDataPoint(x: 0, y: 0.001),
              ChartDataPoint(x: 1, y: 0.005),
            ],
            color: Colors.green,
          ),
        ];

        // Default threshold is 10x
        final shouldNormalize = NormalizationDetector.shouldNormalize(series);

        expect(shouldNormalize, isTrue);
      });

      test('returns false when ratio is below threshold', () {
        final series = [
          const LineChartSeries(
            id: 'power',
            name: 'Power',
            points: [
              ChartDataPoint(x: 0, y: 100),
              ChartDataPoint(x: 1, y: 250),
            ],
            color: Colors.blue,
          ),
          const LineChartSeries(
            id: 'hr',
            name: 'Heart Rate',
            points: [
              ChartDataPoint(x: 0, y: 60),
              ChartDataPoint(x: 1, y: 180),
            ],
            color: Colors.red,
          ),
        ];

        // Power (150 span) vs HR (120 span) = 1.25x ratio
        final shouldNormalize = NormalizationDetector.shouldNormalize(series);

        expect(shouldNormalize, isFalse);
      });

      test('respects custom threshold', () {
        final series = [
          const LineChartSeries(
            id: 's1',
            name: 'Series 1',
            points: [
              ChartDataPoint(x: 0, y: 0),
              ChartDataPoint(x: 1, y: 100),
            ],
            color: Colors.blue,
          ),
          const LineChartSeries(
            id: 's2',
            name: 'Series 2',
            points: [
              ChartDataPoint(x: 0, y: 0),
              ChartDataPoint(x: 1, y: 500),
            ],
            color: Colors.red,
          ),
        ];

        // 100 vs 500 = 5x ratio
        expect(NormalizationDetector.shouldNormalize(series, threshold: 3), isTrue);
        expect(NormalizationDetector.shouldNormalize(series, threshold: 10), isFalse);
      });

      test('returns false for single series', () {
        final series = [
          const LineChartSeries(
            id: 'only',
            name: 'Only',
            points: [
              ChartDataPoint(x: 0, y: 0),
              ChartDataPoint(x: 1, y: 1000000),
            ],
            color: Colors.blue,
          ),
        ];

        expect(NormalizationDetector.shouldNormalize(series), isFalse);
      });
    });

    group('detect', () {
      test('returns detection result with details', () {
        final series = [
          const LineChartSeries(
            id: 'power',
            name: 'Power',
            points: [
              ChartDataPoint(x: 0, y: 100),
              ChartDataPoint(x: 1, y: 250),
            ],
            color: Colors.blue,
          ),
          const LineChartSeries(
            id: 'micro',
            name: 'Micro',
            points: [
              ChartDataPoint(x: 0, y: 0.001),
              ChartDataPoint(x: 1, y: 0.005),
            ],
            color: Colors.green,
          ),
        ];

        final result = NormalizationDetector.detect(series);

        expect(result.shouldNormalize, isTrue);
        expect(result.maxRatio, greaterThan(10));
        expect(result.dominantPairIds, hasLength(2));
        expect(result.seriesRanges, hasLength(2));
      });

      test('provides series ranges for each series', () {
        final series = [
          const LineChartSeries(
            id: 'a',
            name: 'A',
            points: [
              ChartDataPoint(x: 0, y: 10),
              ChartDataPoint(x: 1, y: 20),
            ],
            color: Colors.blue,
          ),
          const LineChartSeries(
            id: 'b',
            name: 'B',
            points: [
              ChartDataPoint(x: 0, y: 100),
              ChartDataPoint(x: 1, y: 200),
            ],
            color: Colors.red,
          ),
        ];

        final result = NormalizationDetector.detect(series);

        expect(result.seriesRanges['a']!.min, 10);
        expect(result.seriesRanges['a']!.max, 20);
        expect(result.seriesRanges['b']!.min, 100);
        expect(result.seriesRanges['b']!.max, 200);
      });
    });

    group('edge cases', () {
      test('handles series with all same Y values', () {
        final series = [
          const LineChartSeries(
            id: 'flat',
            name: 'Flat',
            points: [
              ChartDataPoint(x: 0, y: 50),
              ChartDataPoint(x: 1, y: 50),
              ChartDataPoint(x: 2, y: 50),
            ],
            color: Colors.blue,
          ),
          const LineChartSeries(
            id: 'normal',
            name: 'Normal',
            points: [
              ChartDataPoint(x: 0, y: 0),
              ChartDataPoint(x: 1, y: 100),
            ],
            color: Colors.red,
          ),
        ];

        // Flat series has 0 span - should handle gracefully
        final result = NormalizationDetector.detect(series);

        // Should not throw and should handle zero-span gracefully
        expect(result, isNotNull);
      });

      test('handles empty series points', () {
        final series = [
          const LineChartSeries(
            id: 'empty',
            name: 'Empty',
            points: [],
            color: Colors.blue,
          ),
          const LineChartSeries(
            id: 'normal',
            name: 'Normal',
            points: [
              ChartDataPoint(x: 0, y: 0),
              ChartDataPoint(x: 1, y: 100),
            ],
            color: Colors.red,
          ),
        ];

        final result = NormalizationDetector.detect(series);

        expect(result.shouldNormalize, isFalse);
      });

      test('handles negative values correctly', () {
        final series = [
          const LineChartSeries(
            id: 'positive',
            name: 'Positive',
            points: [
              ChartDataPoint(x: 0, y: 100),
              ChartDataPoint(x: 1, y: 200),
            ],
            color: Colors.blue,
          ),
          const LineChartSeries(
            id: 'negative',
            name: 'Negative',
            points: [
              ChartDataPoint(x: 0, y: -1000),
              ChartDataPoint(x: 1, y: -2000),
            ],
            color: Colors.red,
          ),
        ];

        // Positive: span 100, Negative: span 1000 = 10x
        final result = NormalizationDetector.detect(series);

        expect(result.maxRatio, closeTo(10, 0.1));
      });
    });
  });
}
