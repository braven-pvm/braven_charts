// Copyright (c) 2025 braven_charts. All rights reserved.
// Unit tests for per-axis normalization (US1: Multi-Scale Data Visualization)

import 'dart:ui' show Offset;

import 'package:flutter_test/flutter_test.dart';
import 'package:braven_charts/src_plus/axis/y_axis_config.dart';
import 'package:braven_charts/src_plus/models/y_axis_position.dart';
import 'package:braven_charts/src_plus/models/normalization_mode.dart';
import 'package:braven_charts/src_plus/rendering/multi_axis_normalizer.dart';

/// Tests for per-axis normalization functionality (FR-001, FR-002, FR-003, FR-008).
///
/// This tests the core requirement: each series is normalized to its own Y-axis
/// scale (0-1), ensuring every series spans the full vertical height of the
/// chart regardless of its absolute data range.
void main() {
  group('MultiAxisNormalizer', () {
    group('Basic normalization', () {
      test('should normalize Y value to 0-1 range based on axis bounds', () {
        final normalizer = MultiAxisNormalizer();

        // Axis with range 0-100
        const axisMin = 0.0;
        const axisMax = 100.0;

        // Value at minimum should be 0
        expect(normalizer.normalizeY(0, axisMin, axisMax), equals(0.0));

        // Value at maximum should be 1
        expect(normalizer.normalizeY(100, axisMin, axisMax), equals(1.0));

        // Value at midpoint should be 0.5
        expect(normalizer.normalizeY(50, axisMin, axisMax), equals(0.5));

        // Value at 25% should be 0.25
        expect(normalizer.normalizeY(25, axisMin, axisMax), equals(0.25));
      });

      test('should handle negative value ranges', () {
        final normalizer = MultiAxisNormalizer();

        const axisMin = -50.0;
        const axisMax = 50.0;

        expect(normalizer.normalizeY(-50, axisMin, axisMax), equals(0.0));
        expect(normalizer.normalizeY(50, axisMin, axisMax), equals(1.0));
        expect(normalizer.normalizeY(0, axisMin, axisMax), equals(0.5));
      });

      test('should handle all-negative ranges', () {
        final normalizer = MultiAxisNormalizer();

        const axisMin = -100.0;
        const axisMax = -10.0;

        expect(normalizer.normalizeY(-100, axisMin, axisMax), equals(0.0));
        expect(normalizer.normalizeY(-10, axisMin, axisMax), equals(1.0));
        expect(normalizer.normalizeY(-55, axisMin, axisMax), equals(0.5));
      });

      test('should handle large value ranges (temperature sensor example)', () {
        final normalizer = MultiAxisNormalizer();

        // Temperature: 20°C to 80°C
        const tempMin = 20.0;
        const tempMax = 80.0;

        expect(normalizer.normalizeY(20, tempMin, tempMax), equals(0.0));
        expect(normalizer.normalizeY(80, tempMin, tempMax), equals(1.0));
        expect(normalizer.normalizeY(50, tempMin, tempMax), equals(0.5));
      });

      test('should handle very small value ranges (pH sensor example)', () {
        final normalizer = MultiAxisNormalizer();

        // pH: 6.8 to 7.2
        const phMin = 6.8;
        const phMax = 7.2;

        expect(normalizer.normalizeY(6.8, phMin, phMax), equals(0.0));
        expect(normalizer.normalizeY(7.2, phMin, phMax), equals(1.0));
        expect(normalizer.normalizeY(7.0, phMin, phMax), closeTo(0.5, 0.001));
      });
    });

    group('Denormalization (inverse)', () {
      test('should convert normalized value back to original scale', () {
        final normalizer = MultiAxisNormalizer();

        const axisMin = 0.0;
        const axisMax = 100.0;

        expect(normalizer.denormalizeY(0.0, axisMin, axisMax), equals(0.0));
        expect(normalizer.denormalizeY(1.0, axisMin, axisMax), equals(100.0));
        expect(normalizer.denormalizeY(0.5, axisMin, axisMax), equals(50.0));
        expect(normalizer.denormalizeY(0.25, axisMin, axisMax), equals(25.0));
      });

      test('should be inverse of normalization', () {
        final normalizer = MultiAxisNormalizer();

        const axisMin = -50.0;
        const axisMax = 150.0;
        const originalValue = 37.5;

        final normalized = normalizer.normalizeY(originalValue, axisMin, axisMax);
        final denormalized = normalizer.denormalizeY(normalized, axisMin, axisMax);

        expect(denormalized, closeTo(originalValue, 0.0001));
      });
    });

    group('Point normalization', () {
      test('should normalize a data point preserving X coordinate', () {
        final normalizer = MultiAxisNormalizer();

        const axisMin = 0.0;
        const axisMax = 100.0;
        const dataPoint = Offset(1625097600, 50.0); // timestamp, value

        final normalized = normalizer.normalizePoint(dataPoint, axisMin, axisMax);

        expect(normalized.dx, equals(1625097600)); // X unchanged
        expect(normalized.dy, equals(0.5)); // Y normalized
      });

      test('should normalize series of points', () {
        final normalizer = MultiAxisNormalizer();

        const axisMin = 0.0;
        const axisMax = 100.0;
        final dataPoints = [
          const Offset(1, 0),
          const Offset(2, 25),
          const Offset(3, 50),
          const Offset(4, 75),
          const Offset(5, 100),
        ];

        final normalized = normalizer.normalizePoints(dataPoints, axisMin, axisMax);

        expect(normalized.length, equals(5));
        expect(normalized[0].dy, equals(0.0));
        expect(normalized[1].dy, equals(0.25));
        expect(normalized[2].dy, equals(0.5));
        expect(normalized[3].dy, equals(0.75));
        expect(normalized[4].dy, equals(1.0));

        // X coordinates preserved
        for (var i = 0; i < 5; i++) {
          expect(normalized[i].dx, equals(dataPoints[i].dx));
        }
      });
    });

    group('Multi-axis configuration', () {
      test('should normalize series to correct axis based on axisId', () {
        final normalizer = MultiAxisNormalizer();

        // Define axis bounds for two axes
        final axisBounds = {
          'temperature': (min: 20.0, max: 80.0),
          'ph': (min: 6.8, max: 7.2),
        };

        // Temperature point at 50°C (midpoint)
        final tempNormalized = normalizer.normalizeY(
          50,
          axisBounds['temperature']!.min,
          axisBounds['temperature']!.max,
        );
        expect(tempNormalized, equals(0.5));

        // pH point at 7.0 (midpoint)
        final phNormalized = normalizer.normalizeY(
          7.0,
          axisBounds['ph']!.min,
          axisBounds['ph']!.max,
        );
        expect(phNormalized, closeTo(0.5, 0.001));
      });

      test('should handle series with vastly different ranges', () {
        final normalizer = MultiAxisNormalizer();

        // Stock price: $100-$200 (100x range)
        const priceMin = 100.0;
        const priceMax = 200.0;

        // Trading volume: 1M-10M (10000x range)
        const volumeMin = 1000000.0;
        const volumeMax = 10000000.0;

        // Both at their midpoints should normalize to 0.5
        expect(normalizer.normalizeY(150, priceMin, priceMax), equals(0.5));
        expect(normalizer.normalizeY(5500000, volumeMin, volumeMax), equals(0.5));

        // Both at their maximums should normalize to 1.0
        expect(normalizer.normalizeY(200, priceMin, priceMax), equals(1.0));
        expect(normalizer.normalizeY(10000000, volumeMin, volumeMax), equals(1.0));
      });
    });

    group('Edge cases', () {
      test('should handle zero range (min == max)', () {
        final normalizer = MultiAxisNormalizer();

        // All values are the same - should return 0.5 (middle)
        expect(normalizer.normalizeY(50, 50, 50), equals(0.5));
      });

      test('should clamp values outside axis range', () {
        final normalizer = MultiAxisNormalizer();

        const axisMin = 0.0;
        const axisMax = 100.0;

        // Values below min should clamp to 0
        expect(normalizer.normalizeY(-10, axisMin, axisMax, clamp: true), equals(0.0));

        // Values above max should clamp to 1
        expect(normalizer.normalizeY(110, axisMin, axisMax, clamp: true), equals(1.0));
      });

      test('should allow values outside range without clamping', () {
        final normalizer = MultiAxisNormalizer();

        const axisMin = 0.0;
        const axisMax = 100.0;

        // Below min: -10 is 10% below min
        expect(normalizer.normalizeY(-10, axisMin, axisMax, clamp: false), equals(-0.1));

        // Above max: 110 is 10% above max
        expect(normalizer.normalizeY(110, axisMin, axisMax, clamp: false), equals(1.1));
      });

      test('should handle very small numbers (precision)', () {
        final normalizer = MultiAxisNormalizer();

        const axisMin = 0.0000001;
        const axisMax = 0.0000002;

        final normalized = normalizer.normalizeY(0.00000015, axisMin, axisMax);
        expect(normalized, closeTo(0.5, 0.0001));
      });

      test('should handle very large numbers', () {
        final normalizer = MultiAxisNormalizer();

        const axisMin = 1e10;
        const axisMax = 1e11;

        final normalized = normalizer.normalizeY(5.5e10, axisMin, axisMax);
        expect(normalized, closeTo(0.5, 0.0001));
      });
    });

    group('Normalization mode', () {
      test('NormalizationMode.none should leave values unchanged', () {
        final normalizer = MultiAxisNormalizer();

        // When mode is none, Y values pass through unchanged
        const mode = NormalizationMode.none;
        const value = 50.0;

        final result = normalizer.applyNormalizationMode(value, mode, 0, 100);
        expect(result, equals(50.0)); // Unchanged
      });

      test('NormalizationMode.auto should normalize when enabled', () {
        final normalizer = MultiAxisNormalizer();

        const mode = NormalizationMode.auto;
        const value = 50.0;

        final result = normalizer.applyNormalizationMode(value, mode, 0, 100);
        expect(result, equals(0.5)); // Normalized
      });

      test('NormalizationMode.perSeries should normalize per-axis', () {
        final normalizer = MultiAxisNormalizer();

        const mode = NormalizationMode.perSeries;
        const value = 50.0;

        final result = normalizer.applyNormalizationMode(value, mode, 0, 100);
        expect(result, equals(0.5)); // Normalized per-axis
      });
    });

    group('Integration with YAxisConfig', () {
      test('should use explicit min/max from config when provided', () {
        final normalizer = MultiAxisNormalizer();

        final config = YAxisConfig(
          id: 'temp',
          position: YAxisPosition.left,
          min: 0,
          max: 100,
        );

        final normalized = normalizer.normalizeY(50, config.min!, config.max!);
        expect(normalized, equals(0.5));
      });

      test('should handle config without explicit bounds (auto-computed)', () {
        final normalizer = MultiAxisNormalizer();

        // When config has no explicit bounds, bounds come from data
        final config = YAxisConfig(
          id: 'auto',
          position: YAxisPosition.right,
          // No min/max - will be computed from data
        );

        // Simulate auto-computed bounds from data
        const computedMin = 10.0;
        const computedMax = 90.0;

        expect(config.min, isNull);
        expect(config.max, isNull);

        // Use computed bounds for normalization
        final normalized = normalizer.normalizeY(50, computedMin, computedMax);
        expect(normalized, equals(0.5));
      });
    });
  });
}
