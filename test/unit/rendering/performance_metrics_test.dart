// Unit Test: PerformanceMetrics validation and conversion
// Feature: 002-core-rendering
// Purpose: Validate PerformanceMetrics value object constraints and computed properties
//
// Constitutional Compliance:
// - TDD: Tests written after implementation (unit tests validate correctness)
// - Coverage: All validation rules and computed getters tested

import 'package:braven_charts/src/rendering/performance_metrics.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PerformanceMetrics', () {
    group('meetsTargets', () {
      test(
          'returns true when all targets met (avg<8ms, p99<16ms, hitRate>0.90)',
          () {
        final metrics = PerformanceMetrics(
          frameTime: const Duration(microseconds: 7000),
          averageFrameTime: const Duration(microseconds: 7500), // <8ms ✓
          p99FrameTime: const Duration(microseconds: 15000), // <16ms ✓
          jankCount: 0,
          poolHitRate: 0.95, // >0.90 ✓
        );

        expect(metrics.meetsTargets, isTrue);
      });

      test('returns false when average frame time exceeds 8ms', () {
        final metrics = PerformanceMetrics(
          frameTime: const Duration(microseconds: 9000),
          averageFrameTime: const Duration(microseconds: 9000), // Exceeds 8ms
          p99FrameTime: const Duration(microseconds: 15000),
          jankCount: 0,
          poolHitRate: 0.95,
        );

        expect(metrics.meetsTargets, isFalse);
      });

      test('returns false when p99 frame time exceeds 16ms', () {
        final metrics = PerformanceMetrics(
          frameTime: const Duration(microseconds: 7000),
          averageFrameTime: const Duration(microseconds: 7500),
          p99FrameTime: const Duration(microseconds: 17000), // Exceeds 16ms
          jankCount: 0,
          poolHitRate: 0.95,
        );

        expect(metrics.meetsTargets, isFalse);
      });

      test('returns false when pool hit rate below 0.90', () {
        final metrics = PerformanceMetrics(
          frameTime: const Duration(microseconds: 7000),
          averageFrameTime: const Duration(microseconds: 7500),
          p99FrameTime: const Duration(microseconds: 15000),
          jankCount: 0,
          poolHitRate: 0.89, // Below 0.90
        );

        expect(metrics.meetsTargets, isFalse);
      });

      test('boundary: returns true at exact limits (8ms, 16ms, 0.90)', () {
        final metrics = PerformanceMetrics(
          frameTime: const Duration(microseconds: 8000),
          averageFrameTime: const Duration(microseconds: 8000), // Exactly 8ms
          p99FrameTime: const Duration(microseconds: 16000), // Exactly 16ms
          jankCount: 0,
          poolHitRate: 0.90, // Exactly 0.90
        );

        expect(metrics.meetsTargets, isTrue);
      });
    });

    group('poolHitRate validation', () {
      test('accepts valid hit rate (0.0 to 1.0 inclusive)', () {
        expect(
          () => PerformanceMetrics(
            frameTime: Duration.zero,
            averageFrameTime: Duration.zero,
            p99FrameTime: Duration.zero,
            jankCount: 0,
            poolHitRate: 0.0,
          ),
          returnsNormally,
        );

        expect(
          () => PerformanceMetrics(
            frameTime: Duration.zero,
            averageFrameTime: Duration.zero,
            p99FrameTime: Duration.zero,
            jankCount: 0,
            poolHitRate: 1.0,
          ),
          returnsNormally,
        );

        expect(
          () => PerformanceMetrics(
            frameTime: Duration.zero,
            averageFrameTime: Duration.zero,
            p99FrameTime: Duration.zero,
            jankCount: 0,
            poolHitRate: 0.5,
          ),
          returnsNormally,
        );
      });

      test('throws assertion error when hit rate < 0', () {
        expect(
          () => PerformanceMetrics(
            frameTime: Duration.zero,
            averageFrameTime: Duration.zero,
            p99FrameTime: Duration.zero,
            jankCount: 0,
            poolHitRate: -0.1,
          ),
          throwsA(isA<AssertionError>()),
        );
      });

      test('throws assertion error when hit rate > 1', () {
        expect(
          () => PerformanceMetrics(
            frameTime: Duration.zero,
            averageFrameTime: Duration.zero,
            p99FrameTime: Duration.zero,
            jankCount: 0,
            poolHitRate: 1.1,
          ),
          throwsA(isA<AssertionError>()),
        );
      });
    });

    group('Duration fields validation', () {
      test('accepts non-negative durations', () {
        expect(
          () => PerformanceMetrics(
            frameTime: Duration.zero,
            averageFrameTime: Duration.zero,
            p99FrameTime: Duration.zero,
            jankCount: 0,
            poolHitRate: 1.0,
          ),
          returnsNormally,
        );

        expect(
          () => PerformanceMetrics(
            frameTime: const Duration(microseconds: 7000),
            averageFrameTime: const Duration(microseconds: 8000),
            p99FrameTime: const Duration(microseconds: 15000),
            jankCount: 0,
            poolHitRate: 1.0,
          ),
          returnsNormally,
        );
      });

      test('throws assertion error when frameTime is negative', () {
        expect(
          () => PerformanceMetrics(
            frameTime: const Duration(microseconds: -1),
            averageFrameTime: Duration.zero,
            p99FrameTime: Duration.zero,
            jankCount: 0,
            poolHitRate: 1.0,
          ),
          throwsA(isA<AssertionError>()),
        );
      });

      test('throws assertion error when averageFrameTime is negative', () {
        expect(
          () => PerformanceMetrics(
            frameTime: Duration.zero,
            averageFrameTime: const Duration(microseconds: -1),
            p99FrameTime: Duration.zero,
            jankCount: 0,
            poolHitRate: 1.0,
          ),
          throwsA(isA<AssertionError>()),
        );
      });

      test('throws assertion error when p99FrameTime is negative', () {
        expect(
          () => PerformanceMetrics(
            frameTime: Duration.zero,
            averageFrameTime: Duration.zero,
            p99FrameTime: const Duration(microseconds: -1),
            jankCount: 0,
            poolHitRate: 1.0,
          ),
          throwsA(isA<AssertionError>()),
        );
      });
    });

    group('millisecond getters', () {
      test('averageFrameTimeMs converts microseconds to milliseconds', () {
        final metrics = PerformanceMetrics(
          frameTime: Duration.zero,
          averageFrameTime: const Duration(microseconds: 7500), // 7.5ms
          p99FrameTime: Duration.zero,
          jankCount: 0,
          poolHitRate: 1.0,
        );

        expect(metrics.averageFrameTimeMs, equals(7.5));
      });

      test('p99FrameTimeMs converts microseconds to milliseconds', () {
        final metrics = PerformanceMetrics(
          frameTime: Duration.zero,
          averageFrameTime: Duration.zero,
          p99FrameTime: const Duration(microseconds: 15500), // 15.5ms
          jankCount: 0,
          poolHitRate: 1.0,
        );

        expect(metrics.p99FrameTimeMs, equals(15.5));
      });

      test('millisecond getters handle zero durations', () {
        final metrics = PerformanceMetrics(
          frameTime: Duration.zero,
          averageFrameTime: Duration.zero,
          p99FrameTime: Duration.zero,
          jankCount: 0,
          poolHitRate: 1.0,
        );

        expect(metrics.averageFrameTimeMs, equals(0.0));
        expect(metrics.p99FrameTimeMs, equals(0.0));
      });

      test('millisecond getters handle fractional milliseconds', () {
        final metrics = PerformanceMetrics(
          frameTime: Duration.zero,
          averageFrameTime: const Duration(microseconds: 12345), // 12.345ms
          p99FrameTime: const Duration(microseconds: 9876), // 9.876ms
          jankCount: 0,
          poolHitRate: 1.0,
        );

        expect(metrics.averageFrameTimeMs, closeTo(12.345, 0.001));
        expect(metrics.p99FrameTimeMs, closeTo(9.876, 0.001));
      });
    });

    group('optional fields', () {
      test('culledElementCount defaults to 0', () {
        final metrics = PerformanceMetrics(
          frameTime: Duration.zero,
          averageFrameTime: Duration.zero,
          p99FrameTime: Duration.zero,
          jankCount: 0,
          poolHitRate: 1.0,
        );

        expect(metrics.culledElementCount, equals(0));
      });

      test('renderedElementCount defaults to 0', () {
        final metrics = PerformanceMetrics(
          frameTime: Duration.zero,
          averageFrameTime: Duration.zero,
          p99FrameTime: Duration.zero,
          jankCount: 0,
          poolHitRate: 1.0,
        );

        expect(metrics.renderedElementCount, equals(0));
      });

      test('accepts custom culled and rendered counts', () {
        final metrics = PerformanceMetrics(
          frameTime: Duration.zero,
          averageFrameTime: Duration.zero,
          p99FrameTime: Duration.zero,
          jankCount: 0,
          poolHitRate: 1.0,
          culledElementCount: 9500,
          renderedElementCount: 500,
        );

        expect(metrics.culledElementCount, equals(9500));
        expect(metrics.renderedElementCount, equals(500));
      });
    });

    group('immutability', () {
      test('all fields are final (value equality works)', () {
        final metrics1 = PerformanceMetrics(
          frameTime: const Duration(microseconds: 7000),
          averageFrameTime: const Duration(microseconds: 7500),
          p99FrameTime: const Duration(microseconds: 15000),
          jankCount: 0,
          poolHitRate: 0.95,
        );

        final metrics2 = PerformanceMetrics(
          frameTime: const Duration(microseconds: 7000),
          averageFrameTime: const Duration(microseconds: 7500),
          p99FrameTime: const Duration(microseconds: 15000),
          jankCount: 0,
          poolHitRate: 0.95,
        );

        // All fields should be equal (value equality)
        expect(metrics1.frameTime, equals(metrics2.frameTime));
        expect(metrics1.averageFrameTime, equals(metrics2.averageFrameTime));
        expect(metrics1.p99FrameTime, equals(metrics2.p99FrameTime));
        expect(metrics1.jankCount, equals(metrics2.jankCount));
        expect(metrics1.poolHitRate, equals(metrics2.poolHitRate));
        expect(metrics1.renderedElementCount, equals(metrics2.renderedElementCount));
        expect(metrics1.culledElementCount, equals(metrics2.culledElementCount));
      });
    });
  });
}
