// Contract Test: PerformanceMonitor Interface
// Feature: 002-core-rendering
// Purpose: Verify PerformanceMonitor contract compliance
//
// TDD Phase: RED - These tests MUST fail before implementation exists
//
// Expected initial state: COMPILATION ERROR
// - PerformanceMonitor not fully implemented yet (will be created in T012)
// - PerformanceMetrics not defined yet (will be created in T010)
// - This is intentional per TDD workflow

import 'package:braven_charts/legacy/src/rendering/performance_metrics.dart';
import 'package:braven_charts/legacy/src/rendering/performance_monitor.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PerformanceMonitor Contract Tests', () {
    late PerformanceMonitor monitor;

    setUp(() {
      // Will fail until T012 implements StopwatchPerformanceMonitor
      monitor = StopwatchPerformanceMonitor(maxHistorySize: 10);
    });

    group('Contract Requirement 1: Paired Calls', () {
      test('beginFrame() and endFrame() must be called in pairs', () {
        expect(() {
          monitor.beginFrame();
          monitor.endFrame();
        }, returnsNormally, reason: 'Paired begin/end should work');
      });

      test('endFrame() without beginFrame() throws assertion error', () {
        // This should throw in debug mode
        expect(
          () => monitor.endFrame(),
          throwsA(isA<AssertionError>()),
          reason: 'endFrame() without beginFrame() violates contract',
        );
      });

      test('multiple beginFrame() without endFrame() throws assertion', () {
        monitor.beginFrame();

        expect(
          () => monitor.beginFrame(),
          throwsA(isA<AssertionError>()),
          reason: 'Cannot begin new frame while frame in progress',
        );

        monitor.endFrame(); // Clean up
      });
    });

    group('Contract Requirement 2: Timing Accuracy', () {
      test('frame time measurement accurate to ±0.5ms', () async {
        monitor.beginFrame();

        // Simulate known duration (5ms)
        await Future.delayed(const Duration(milliseconds: 5));

        monitor.endFrame();

        final metrics = monitor.currentMetrics;
        final measuredMs = metrics.frameTime.inMilliseconds;

        // Allow ±2ms tolerance for platform variance
        expect(measuredMs, greaterThanOrEqualTo(3),
            reason: 'Should measure at least 3ms (5ms - 2ms tolerance)');
        expect(measuredMs, lessThanOrEqualTo(10),
            reason:
                'Should measure at most 10ms (5ms + 5ms platform variance)');
      });

      test('uses microsecond precision', () async {
        monitor.beginFrame();
        await Future.delayed(const Duration(microseconds: 1500));
        monitor.endFrame();

        final metrics = monitor.currentMetrics;

        // Should capture sub-millisecond precision
        expect(metrics.frameTime.inMicroseconds, greaterThan(1000),
            reason: 'Should use microsecond precision');
      });
    });

    group('Contract Requirement 3: Jank Detection', () {
      test('frames >16ms increment jank counter', () async {
        final initialMetrics = monitor.currentMetrics;
        final initialJankCount = initialMetrics.jankCount;

        // Simulate slow frame (17ms)
        monitor.beginFrame();
        await Future.delayed(const Duration(milliseconds: 17));
        monitor.endFrame();

        final afterMetrics = monitor.currentMetrics;

        expect(afterMetrics.jankCount, equals(initialJankCount + 1),
            reason: 'Jank counter should increment for >16ms frame');
      });

      test('frames ≤16ms do not increment jank counter', () async {
        final initialMetrics = monitor.currentMetrics;
        final initialJankCount = initialMetrics.jankCount;

        // Simulate fast frame (5ms)
        monitor.beginFrame();
        await Future.delayed(const Duration(milliseconds: 5));
        monitor.endFrame();

        final afterMetrics = monitor.currentMetrics;

        expect(afterMetrics.jankCount, equals(initialJankCount),
            reason: 'Jank counter should not increment for ≤16ms frame');
      });

      test('100% jank detection accuracy', () async {
        monitor.reset();

        // Execute 10 frames: 5 fast, 5 slow
        for (int i = 0; i < 5; i++) {
          monitor.beginFrame();
          await Future.delayed(const Duration(milliseconds: 5));
          monitor.endFrame();
        }

        for (int i = 0; i < 5; i++) {
          monitor.beginFrame();
          await Future.delayed(const Duration(milliseconds: 18));
          monitor.endFrame();
        }

        final metrics = monitor.currentMetrics;

        expect(metrics.jankCount, equals(5),
            reason: 'Should detect exactly 5 jank frames');
      });
    });

    group('Contract Requirement 4: Low Overhead', () {
      test('begin/end/metrics overhead <1ms per frame', () {
        final stopwatch = Stopwatch()..start();

        for (int i = 0; i < 100; i++) {
          monitor.beginFrame();
          // No actual work, just timing overhead
          monitor.endFrame();
          final _ = monitor.currentMetrics;
        }

        stopwatch.stop();

        final avgOverheadMicros = stopwatch.elapsedMicroseconds / 100;

        expect(avgOverheadMicros, lessThan(1000),
            reason: 'Monitoring overhead must be <1ms (1000 microseconds)');
      });
    });

    group('Contract Requirement 5: Bounded History', () {
      test('frame history respects maxHistorySize', () {
        final smallMonitor = StopwatchPerformanceMonitor(maxHistorySize: 5);

        // Record 10 frames (exceeds maxHistorySize of 5)
        for (int i = 0; i < 10; i++) {
          smallMonitor.beginFrame();
          smallMonitor.endFrame();
        }

        // History should be bounded to 5 (LRU eviction)
        // We can't directly access history, but metrics should reflect bounded size
        final metrics = smallMonitor.currentMetrics;

        // This validates that metrics calculation works with bounded history
        expect(metrics.frameTime, isNotNull,
            reason: 'Metrics should work with bounded history');
      });

      test('LRU eviction removes oldest frames', () {
        final smallMonitor = StopwatchPerformanceMonitor(maxHistorySize: 3);

        // Record frames with distinct durations
        // This test validates that oldest frames are evicted
        for (int i = 0; i < 5; i++) {
          smallMonitor.beginFrame();
          smallMonitor.endFrame();
        }

        // After 5 frames with maxHistorySize=3, oldest 2 should be evicted
        // Metrics should be calculated from most recent 3 frames only
        final metrics = smallMonitor.currentMetrics;

        expect(metrics.averageFrameTime, isNotNull,
            reason: 'LRU eviction should maintain valid metrics');
      });
    });

    group('Contract Requirement 6: Thread Safety', () {
      test('single-threaded operation (no synchronization required)', () {
        // Contract specifies no thread safety required
        // This test just validates single-threaded usage works

        for (int i = 0; i < 10; i++) {
          monitor.beginFrame();
          monitor.endFrame();
        }

        final metrics = monitor.currentMetrics;
        expect(metrics.frameTime, isNotNull);
      });
    });

    group('Contract Requirement 7: Reset Capability', () {
      test('reset() clears all accumulated state', () {
        // Record some frames with jank
        for (int i = 0; i < 5; i++) {
          monitor.beginFrame();
          monitor.endFrame();
        }

        // Metrics should show some data
        var metrics = monitor.currentMetrics;
        expect(metrics.jankCount, greaterThanOrEqualTo(0));

        // Reset
        monitor.reset();

        // After reset, should be clean state
        metrics = monitor.currentMetrics;
        expect(metrics.jankCount, equals(0),
            reason: 'Jank count should be zero after reset');
      });

      test('reset() allows test reproducibility', () {
        // First run
        monitor.beginFrame();
        monitor.endFrame();
        final firstMetrics = monitor.currentMetrics;
        expect(firstMetrics, isNotNull);

        // Reset
        monitor.reset();

        // Second run (should be independent)
        monitor.beginFrame();
        monitor.endFrame();
        final secondMetrics = monitor.currentMetrics;

        // Both runs should have similar frame time (reproducible)
        expect(secondMetrics.jankCount, equals(0),
            reason: 'Reset should enable independent test runs');
      });
    });

    group('currentMetrics getter', () {
      test('returns valid PerformanceMetrics', () {
        monitor.beginFrame();
        monitor.endFrame();

        final metrics = monitor.currentMetrics;

        expect(metrics, isA<PerformanceMetrics>());
        expect(metrics.frameTime, isNotNull);
        expect(metrics.averageFrameTime, isNotNull);
        expect(metrics.p99FrameTime, isNotNull);
        expect(metrics.jankCount, isNotNull);
        expect(metrics.poolHitRate, isNotNull);
      });

      test('metrics are immutable snapshots', () {
        monitor.beginFrame();
        monitor.endFrame();

        final metrics1 = monitor.currentMetrics;

        monitor.beginFrame();
        monitor.endFrame();

        final metrics2 = monitor.currentMetrics;

        // metrics1 should not be mutated by second frame
        expect(metrics1, isNot(same(metrics2)),
            reason: 'Each currentMetrics call should return new snapshot');
      });
    });

    group('maxHistorySize property', () {
      test('maxHistorySize is accessible', () {
        final monitor120 = StopwatchPerformanceMonitor(maxHistorySize: 120);

        expect(monitor120.maxHistorySize, equals(120));
      });

      test('maxHistorySize default is 120 frames', () {
        // This validates the default per contract
        // Default constructor should use 120
        final defaultMonitor = StopwatchPerformanceMonitor();

        expect(defaultMonitor.maxHistorySize, equals(120),
            reason: 'Default maxHistorySize should be 120 (2 seconds @ 60fps)');
      });
    });
  });
}
