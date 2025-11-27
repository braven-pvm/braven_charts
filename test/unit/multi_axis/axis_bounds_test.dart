// Copyright (c) 2025 braven_charts. All rights reserved.
// Unit tests for axis bounds computation (US1: Multi-Scale Data Visualization)

import 'dart:ui' show Offset;

import 'package:flutter_test/flutter_test.dart';
import 'package:braven_charts/src_plus/axis/axis_bounds_calculator.dart';
import 'package:braven_charts/src_plus/axis/y_axis_config.dart';
import 'package:braven_charts/src_plus/models/y_axis_position.dart';
import 'package:braven_charts/src_plus/models/chart_series.dart';

/// Tests for axis bounds computation (FR-001, FR-002, FR-003).
///
/// This tests the computation of per-axis min/max bounds from series data,
/// which is essential for correct normalization.
void main() {
  group('AxisBoundsCalculator', () {
    group('computeBoundsForAxis', () {
      test('should compute min/max from single series data', () {
        final data = [
          const Offset(1, 10.0),
          const Offset(2, 25.0),
          const Offset(3, 50.0),
          const Offset(4, 75.0),
          const Offset(5, 100.0),
        ];

        final bounds = AxisBoundsCalculator.computeBoundsFromPoints(data);

        expect(bounds.min, equals(10.0));
        expect(bounds.max, equals(100.0));
      });

      test('should compute bounds with negative values', () {
        final data = [
          const Offset(1, -50.0),
          const Offset(2, -25.0),
          const Offset(3, 0.0),
          const Offset(4, 25.0),
          const Offset(5, 50.0),
        ];

        final bounds = AxisBoundsCalculator.computeBoundsFromPoints(data);

        expect(bounds.min, equals(-50.0));
        expect(bounds.max, equals(50.0));
      });

      test('should handle single data point', () {
        final data = [const Offset(1, 42.0)];

        final bounds = AxisBoundsCalculator.computeBoundsFromPoints(data);

        expect(bounds.min, equals(42.0));
        expect(bounds.max, equals(42.0));
      });

      test('should handle empty data', () {
        final data = <Offset>[];

        final bounds = AxisBoundsCalculator.computeBoundsFromPoints(data);

        // Empty data should return default bounds
        expect(bounds.min, equals(0.0));
        expect(bounds.max, equals(1.0));
      });

      test('should handle all same values', () {
        final data = [
          const Offset(1, 50.0),
          const Offset(2, 50.0),
          const Offset(3, 50.0),
        ];

        final bounds = AxisBoundsCalculator.computeBoundsFromPoints(data);

        expect(bounds.min, equals(50.0));
        expect(bounds.max, equals(50.0));
      });
    });

    group('computeAllBounds', () {
      test('should compute bounds for multiple axes from config', () {
        final configs = [
          const YAxisConfig(id: 'temp', position: YAxisPosition.left),
          const YAxisConfig(id: 'ph', position: YAxisPosition.right),
        ];

        final seriesData = {
          'temp': [
            const Offset(1, 20.0),
            const Offset(2, 50.0),
            const Offset(3, 80.0),
          ],
          'ph': [
            const Offset(1, 6.8),
            const Offset(2, 7.0),
            const Offset(3, 7.2),
          ],
        };

        final allBounds = AxisBoundsCalculator.computeAllBounds(
          configs,
          seriesData,
        );

        expect(allBounds['temp']!.min, equals(20.0));
        expect(allBounds['temp']!.max, equals(80.0));
        expect(allBounds['ph']!.min, equals(6.8));
        expect(allBounds['ph']!.max, equals(7.2));
      });

      test('should use explicit config bounds when provided', () {
        final configs = [
          const YAxisConfig(
            id: 'temp',
            position: YAxisPosition.left,
            min: 0.0,
            max: 100.0,
          ),
        ];

        final seriesData = {
          'temp': [
            const Offset(1, 20.0),
            const Offset(2, 50.0),
            const Offset(3, 80.0),
          ],
        };

        final allBounds = AxisBoundsCalculator.computeAllBounds(
          configs,
          seriesData,
        );

        // Should use explicit config bounds, not computed from data
        expect(allBounds['temp']!.min, equals(0.0));
        expect(allBounds['temp']!.max, equals(100.0));
      });

      test('should handle missing series data for config', () {
        final configs = [
          const YAxisConfig(id: 'temp', position: YAxisPosition.left),
          const YAxisConfig(id: 'missing', position: YAxisPosition.right),
        ];

        final seriesData = {
          'temp': [
            const Offset(1, 20.0),
            const Offset(2, 80.0),
          ],
          // 'missing' has no data
        };

        final allBounds = AxisBoundsCalculator.computeAllBounds(
          configs,
          seriesData,
        );

        expect(allBounds['temp']!.min, equals(20.0));
        expect(allBounds['temp']!.max, equals(80.0));
        // Missing should have default bounds
        expect(allBounds['missing']!.min, equals(0.0));
        expect(allBounds['missing']!.max, equals(1.0));
      });
    });

    group('resolveSeriesAxisBinding', () {
      test('should bind series to axis by explicit yAxisId', () {
        final series = const MockChartSeries(
          id: 'temp-series',
          yAxisId: 'temp',
          data: [Offset(1, 20.0)],
        );

        final binding = AxisBoundsCalculator.resolveSeriesAxisBinding(
          series,
          ['temp', 'ph'],
        );

        expect(binding, equals('temp'));
      });

      test('should return null for unbound series', () {
        final series = const MockChartSeries(
          id: 'orphan-series',
          yAxisId: null,
          data: [Offset(1, 20.0)],
        );

        final binding = AxisBoundsCalculator.resolveSeriesAxisBinding(
          series,
          ['temp', 'ph'],
        );

        expect(binding, isNull);
      });

      test('should validate axis exists in available list', () {
        final series = const MockChartSeries(
          id: 'series',
          yAxisId: 'nonexistent',
          data: [Offset(1, 20.0)],
        );

        final binding = AxisBoundsCalculator.resolveSeriesAxisBinding(
          series,
          ['temp', 'ph'],
        );

        // Should return null if axis doesn't exist
        expect(binding, isNull);
      });
    });

    group('computeAutoAxisAssignments', () {
      test('should auto-assign series to first axis when no yAxisId', () {
        final series = [
          const MockChartSeries(
            id: 'series1',
            yAxisId: null,
            data: [Offset(1, 20.0)],
          ),
        ];

        final configs = [
          const YAxisConfig(id: 'primary', position: YAxisPosition.left),
        ];

        final assignments = AxisBoundsCalculator.computeAutoAxisAssignments(
          series,
          configs,
        );

        expect(assignments['series1'], equals('primary'));
      });

      test('should respect explicit yAxisId over auto-assignment', () {
        final series = [
          const MockChartSeries(
            id: 'series1',
            yAxisId: 'secondary',
            data: [Offset(1, 20.0)],
          ),
        ];

        final configs = [
          const YAxisConfig(id: 'primary', position: YAxisPosition.left),
          const YAxisConfig(id: 'secondary', position: YAxisPosition.right),
        ];

        final assignments = AxisBoundsCalculator.computeAutoAxisAssignments(
          series,
          configs,
        );

        expect(assignments['series1'], equals('secondary'));
      });

      test('should distribute unbound series across axes by unit matching', () {
        final series = [
          const MockChartSeries(
            id: 'temp1',
            yAxisId: null,
            unit: '°C',
            data: [Offset(1, 20.0)],
          ),
          const MockChartSeries(
            id: 'temp2',
            yAxisId: null,
            unit: '°C',
            data: [Offset(1, 30.0)],
          ),
          const MockChartSeries(
            id: 'ph1',
            yAxisId: null,
            unit: 'pH',
            data: [Offset(1, 7.0)],
          ),
        ];

        final configs = [
          const YAxisConfig(id: 'temp-axis', position: YAxisPosition.left, unit: '°C'),
          const YAxisConfig(id: 'ph-axis', position: YAxisPosition.right, unit: 'pH'),
        ];

        final assignments = AxisBoundsCalculator.computeAutoAxisAssignments(
          series,
          configs,
        );

        // Series with matching units should be assigned to matching axes
        expect(assignments['temp1'], equals('temp-axis'));
        expect(assignments['temp2'], equals('temp-axis'));
        expect(assignments['ph1'], equals('ph-axis'));
      });
    });

    group('Bounds padding', () {
      test('should add padding to computed bounds', () {
        final data = [
          const Offset(1, 20.0),
          const Offset(2, 80.0),
        ];

        final bounds = AxisBoundsCalculator.computeBoundsFromPoints(
          data,
          paddingPercent: 10.0,
        );

        // Range is 60 (80-20), 10% padding = 6 on each side
        expect(bounds.min, closeTo(14.0, 0.1));
        expect(bounds.max, closeTo(86.0, 0.1));
      });

      test('should not add padding when paddingPercent is 0', () {
        final data = [
          const Offset(1, 20.0),
          const Offset(2, 80.0),
        ];

        final bounds = AxisBoundsCalculator.computeBoundsFromPoints(
          data,
          paddingPercent: 0.0,
        );

        expect(bounds.min, equals(20.0));
        expect(bounds.max, equals(80.0));
      });
    });

    group('Nice bounds', () {
      test('should round bounds to nice numbers', () {
        final data = [
          const Offset(1, 23.7),
          const Offset(2, 87.2),
        ];

        final bounds = AxisBoundsCalculator.computeBoundsFromPoints(
          data,
          useNiceBounds: true,
        );

        // Should round to nice numbers like 20 and 90
        expect(bounds.min, lessThanOrEqualTo(23.7));
        expect(bounds.max, greaterThanOrEqualTo(87.2));
      });
    });

    group('AxisBounds class', () {
      test('should compute range correctly', () {
        const bounds = AxisBounds(min: 20.0, max: 80.0);
        expect(bounds.range, equals(60.0));
      });

      test('should compute center correctly', () {
        const bounds = AxisBounds(min: 20.0, max: 80.0);
        expect(bounds.center, equals(50.0));
      });

      test('should check if value is within bounds', () {
        const bounds = AxisBounds(min: 20.0, max: 80.0);

        expect(bounds.contains(50.0), isTrue);
        expect(bounds.contains(20.0), isTrue);
        expect(bounds.contains(80.0), isTrue);
        expect(bounds.contains(10.0), isFalse);
        expect(bounds.contains(90.0), isFalse);
      });

      test('should handle equality', () {
        const bounds1 = AxisBounds(min: 20.0, max: 80.0);
        const bounds2 = AxisBounds(min: 20.0, max: 80.0);
        const bounds3 = AxisBounds(min: 0.0, max: 100.0);

        expect(bounds1, equals(bounds2));
        expect(bounds1, isNot(equals(bounds3)));
      });
    });
  });
}

/// Mock implementation of ChartSeries for testing.
class MockChartSeries {
  const MockChartSeries({
    required this.id,
    required this.yAxisId,
    required this.data,
    this.unit,
  });

  final String id;
  final String? yAxisId;
  final List<Offset> data;
  final String? unit;
}
