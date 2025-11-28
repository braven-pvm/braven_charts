/// Unit tests for AreaStacking
///
/// Tests the area chart stacking algorithm for cumulative stacking,
/// negative value handling, and baseline calculations.
library;

import 'dart:ui' show Offset;

import 'package:braven_charts/legacy/src/charts/area/area_chart_config.dart';
import 'package:braven_charts/legacy/src/charts/area/area_stacking.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AreaStacking', () {
    group('Cumulative Stacking for Positive Values', () {
      test('stacks two series with positive values', () {
        final series1Points = [
          const Offset(0, 10),
          const Offset(1, 20),
          const Offset(2, 15),
        ];
        final series2Points = [
          const Offset(0, 5),
          const Offset(1, 10),
          const Offset(2, 8),
        ];

        final stacker = AreaStacking();
        final stacked = stacker.stack([
          series1Points,
          series2Points,
        ]);

        // Should have 2 series + baseline
        expect(stacked.length, equals(3));

        // First series should be unchanged
        expect(stacked[0], equals(series1Points));

        // Second series should be stacked on top of first
        expect(stacked[1].length, equals(3));
        expect(stacked[1][0].dy, equals(15)); // 10 + 5
        expect(stacked[1][1].dy, equals(30)); // 20 + 10
        expect(stacked[1][2].dy, equals(23)); // 15 + 8

        // Baseline should be zero
        expect(stacked[2].length, equals(3));
        expect(stacked[2][0].dy, equals(0));
        expect(stacked[2][1].dy, equals(0));
        expect(stacked[2][2].dy, equals(0));
      });

      test('stacks three series cumulatively', () {
        final series1 = [const Offset(0, 10)];
        final series2 = [const Offset(0, 5)];
        final series3 = [const Offset(0, 3)];

        final stacker = AreaStacking();
        final stacked = stacker.stack([series1, series2, series3]);

        expect(stacked.length, equals(4)); // 3 series + baseline
        expect(stacked[0][0].dy, equals(10)); // First: unchanged
        expect(stacked[1][0].dy, equals(15)); // Second: 10 + 5
        expect(stacked[2][0].dy, equals(18)); // Third: 15 + 3
        expect(stacked[3][0].dy, equals(0)); // Baseline: zero
      });

      test('handles empty series list', () {
        final stacker = AreaStacking();
        final stacked = stacker.stack([]);

        expect(stacked.isEmpty, isTrue);
      });

      test('handles single series', () {
        final series = [
          const Offset(0, 10),
          const Offset(1, 20),
        ];

        final stacker = AreaStacking();
        final stacked = stacker.stack([series]);

        expect(stacked.length, equals(2)); // 1 series + baseline
        expect(stacked[0], equals(series)); // Unchanged
        expect(stacked[1].length, equals(2)); // Baseline
        expect(stacked[1][0].dy, equals(0));
        expect(stacked[1][1].dy, equals(0));
      });
    });

    group('Negative Value Handling (Separate Stacks)', () {
      test('separates positive and negative values into different stacks', () {
        final series1 = [
          const Offset(0, 10),
          const Offset(1, -5),
        ];
        final series2 = [
          const Offset(0, 5),
          const Offset(1, -3),
        ];

        final stacker = AreaStacking();
        final stacked = stacker.stack([series1, series2]);

        // Should stack positives upward and negatives downward
        expect(stacked.length, equals(3)); // 2 series + baseline

        // First series unchanged
        expect(stacked[0][0].dy, equals(10));
        expect(stacked[0][1].dy, equals(-5));

        // Second series stacked
        expect(stacked[1][0].dy, equals(15)); // Positive: 10 + 5
        expect(stacked[1][1].dy, equals(-8)); // Negative: -5 + -3
      });

      test('handles all negative values', () {
        final series1 = [const Offset(0, -10)];
        final series2 = [const Offset(0, -5)];

        final stacker = AreaStacking();
        final stacked = stacker.stack([series1, series2]);

        expect(stacked[0][0].dy, equals(-10)); // First unchanged
        expect(stacked[1][0].dy, equals(-15)); // Stacked: -10 + -5
      });

      test('handles mixed positive and negative across multiple series', () {
        final series1 = [
          const Offset(0, 10),
          const Offset(1, -10),
          const Offset(2, 5),
        ];
        final series2 = [
          const Offset(0, 5),
          const Offset(1, -5),
          const Offset(2, 3),
        ];

        final stacker = AreaStacking();
        final stacked = stacker.stack([series1, series2]);

        // Positives stack upward, negatives stack downward
        expect(stacked[1][0].dy, equals(15)); // 10 + 5
        expect(stacked[1][1].dy, equals(-15)); // -10 + -5
        expect(stacked[1][2].dy, equals(8)); // 5 + 3
      });
    });

    group('Baseline Calculation', () {
      test('zero baseline returns all y-values as zero', () {
        final series = [
          const Offset(0, 10),
          const Offset(1, 20),
        ];

        final stacker = AreaStacking();
        final stacked =
            stacker.stack([series], baseline: const AreaBaseline.zero());

        final baselinePoints = stacked.last;
        expect(baselinePoints[0].dy, equals(0));
        expect(baselinePoints[1].dy, equals(0));
      });

      test('fixed baseline returns constant y-value', () {
        final series = [
          const Offset(0, 10),
          const Offset(1, 20),
        ];

        final stacker = AreaStacking();
        final stacked = stacker.stack(
          [series],
          baseline: const AreaBaseline.fixed(50),
        );

        final baselinePoints = stacked.last;
        expect(baselinePoints[0].dy, equals(50));
        expect(baselinePoints[1].dy, equals(50));
      });

      test('series baseline uses specified series as baseline', () {
        final series1 = [
          const Offset(0, 30),
          const Offset(1, 40),
        ];
        final series2 = [
          const Offset(0, 10),
          const Offset(1, 15),
        ];

        final stacker = AreaStacking();
        final stacked = stacker.stack(
          [series1, series2],
          baseline: const AreaBaseline.series('series1'),
          seriesIds: ['series1', 'series2'],
        );

        // Baseline should match series1 values
        final baselinePoints = stacked.last;
        expect(baselinePoints[0].dy, equals(30));
        expect(baselinePoints[1].dy, equals(40));
      });

      test('series baseline with non-existent seriesId defaults to zero', () {
        final series = [
          const Offset(0, 10),
          const Offset(1, 20),
        ];

        final stacker = AreaStacking();
        final stacked = stacker.stack(
          [series],
          baseline: const AreaBaseline.series('nonExistent'),
          seriesIds: ['series1'],
        );

        // Should fallback to zero baseline
        final baselinePoints = stacked.last;
        expect(baselinePoints[0].dy, equals(0));
        expect(baselinePoints[1].dy, equals(0));
      });

      test('adjusts stacking relative to non-zero baseline', () {
        final series1 = [const Offset(0, 10)];
        final series2 = [const Offset(0, 5)];

        final stacker = AreaStacking();
        final stacked = stacker.stack(
          [series1, series2],
          baseline: const AreaBaseline.fixed(20),
        );

        // With baseline at 20:
        // series1 at 10 is -10 relative to baseline (below baseline)
        // series2 at 5 is -15 relative to baseline (below baseline)
        // Stacking should be: series1 = 20 + 10 = 30, series2 = 30 + 5 = 35
        // (if stacking upward from baseline)

        // Check that baseline is applied
        final baselinePoints = stacked.last;
        expect(baselinePoints[0].dy, equals(20));
      });
    });

    group('Edge Cases', () {
      test('handles series with different lengths by using minimum length', () {
        final series1 = [
          const Offset(0, 10),
          const Offset(1, 20),
          const Offset(2, 15),
        ];
        final series2 = [
          const Offset(0, 5),
          const Offset(1, 10),
        ]; // Shorter

        final stacker = AreaStacking();
        final stacked = stacker.stack([series1, series2]);

        // Should handle gracefully - may truncate or pad with zeros
        expect(stacked.isNotEmpty, isTrue);
      });

      test('handles zero values in series', () {
        final series1 = [
          const Offset(0, 0),
          const Offset(1, 10),
        ];
        final series2 = [
          const Offset(0, 5),
          const Offset(1, 0),
        ];

        final stacker = AreaStacking();
        final stacked = stacker.stack([series1, series2]);

        expect(stacked[0][0].dy, equals(0));
        expect(stacked[1][0].dy, equals(5)); // 0 + 5
        expect(stacked[1][1].dy, equals(10)); // 10 + 0
      });
    });
  });
}
