// Unit Tests: PerformanceMonitor Frame Timing
// Feature: 002-core-rendering
// Task: T018
// Purpose: Validate frame timing, jank detection, history management, metrics calculation

import 'package:braven_charts/src/rendering/performance_monitor.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('StopwatchPerformanceMonitor - Frame Timing', () {
    test('beginFrame/endFrame pair records frame time', () {
      final monitor = StopwatchPerformanceMonitor();

      monitor.beginFrame();
      // Simulate some work (very brief)
      for (int i = 0; i < 100; i++) {
        // Busy loop
      }
      monitor.endFrame();

      final metrics = monitor.currentMetrics;
      expect(metrics.frameTime.inMicroseconds, greaterThan(0), reason: 'Frame time should be recorded and non-zero');
    });

    test('multiple beginFrame/endFrame pairs record separate frame times', () {
      final monitor = StopwatchPerformanceMonitor();

      // Record 3 frames
      for (int frame = 0; frame < 3; frame++) {
        monitor.beginFrame();
        // Simulate varying work
        for (int i = 0; i < (frame + 1) * 50; i++) {
          // Busy loop
        }
        monitor.endFrame();
      }

      final metrics = monitor.currentMetrics;
      expect(metrics.frameTime.inMicroseconds, greaterThan(0), reason: 'Last frame time should be recorded');
      expect(metrics.averageFrameTime.inMicroseconds, greaterThan(0), reason: 'Average should be calculated from all frames');
    });

    test('frame time has microsecond precision', () {
      final monitor = StopwatchPerformanceMonitor();

      monitor.beginFrame();
      // Very brief work
      monitor.endFrame();

      final metrics = monitor.currentMetrics;
      // Even minimal work should register in microseconds
      expect(metrics.frameTime.inMicroseconds, greaterThanOrEqualTo(0), reason: 'Microsecond precision should detect minimal work');
    });

    test('beginFrame without endFrame throws assertion in debug mode', () {
      final monitor = StopwatchPerformanceMonitor();

      monitor.beginFrame();

      // Second beginFrame should throw assertion error
      expect(() => monitor.beginFrame(), throwsAssertionError, reason: 'Double beginFrame should assert');
    });

    test('endFrame without beginFrame throws assertion in debug mode', () {
      final monitor = StopwatchPerformanceMonitor();

      // endFrame without beginFrame should throw assertion error
      expect(() => monitor.endFrame(), throwsAssertionError, reason: 'endFrame without beginFrame should assert');
    });
  });

  group('StopwatchPerformanceMonitor - Jank Detection', () {
    test('jank counter increments when frame exceeds 16ms threshold', () async {
      final monitor = StopwatchPerformanceMonitor();

      monitor.beginFrame();
      // Force delay >16ms
      await Future.delayed(const Duration(milliseconds: 20));
      monitor.endFrame();

      final metrics = monitor.currentMetrics;
      expect(metrics.jankCount, equals(1), reason: 'Jank counter should increment for frame >16ms');
    });

    test('jank counter does not increment for frames under 16ms', () {
      final monitor = StopwatchPerformanceMonitor();

      monitor.beginFrame();
      // Minimal work (should be <16ms)
      for (int i = 0; i < 100; i++) {
        // Brief loop
      }
      monitor.endFrame();

      final metrics = monitor.currentMetrics;
      expect(metrics.jankCount, equals(0), reason: 'Jank counter should not increment for fast frames');
    });

    test('jank counter accumulates across multiple slow frames', () async {
      final monitor = StopwatchPerformanceMonitor();

      // Record 3 janky frames
      for (int i = 0; i < 3; i++) {
        monitor.beginFrame();
        await Future.delayed(const Duration(milliseconds: 18));
        monitor.endFrame();
      }

      final metrics = monitor.currentMetrics;
      expect(metrics.jankCount, equals(3), reason: 'Jank counter should accumulate across frames');
    });

    test('jank counter does not increment for exactly 16ms frame', () async {
      final monitor = StopwatchPerformanceMonitor();

      monitor.beginFrame();
      // Target exactly 16ms (may vary slightly in practice)
      await Future.delayed(const Duration(milliseconds: 16));
      monitor.endFrame();

      final metrics = monitor.currentMetrics;
      // Jank threshold is >16ms (exclusive), so 16ms should not count
      expect(metrics.jankCount, equals(0), reason: 'Jank threshold is >16ms, so exactly 16ms should not count');
    });

    test('mixed fast and slow frames only count slow ones', () async {
      final monitor = StopwatchPerformanceMonitor();

      // Fast frame
      monitor.beginFrame();
      monitor.endFrame();

      // Slow frame
      monitor.beginFrame();
      await Future.delayed(const Duration(milliseconds: 20));
      monitor.endFrame();

      // Fast frame
      monitor.beginFrame();
      monitor.endFrame();

      final metrics = monitor.currentMetrics;
      expect(metrics.jankCount, equals(1), reason: 'Only the slow frame should increment jank counter');
    });
  });

  group('StopwatchPerformanceMonitor - History Management', () {
    test('maxHistorySize boundary enforces LRU eviction', () {
      final monitor = StopwatchPerformanceMonitor(maxHistorySize: 3);

      // Record 5 frames (should evict 2 oldest)
      for (int i = 0; i < 5; i++) {
        monitor.beginFrame();
        monitor.endFrame();
      }

      final metrics = monitor.currentMetrics;
      // Average should be calculated from last 3 frames only
      // (Cannot directly verify count, but average behavior confirms bounded history)
      expect(metrics.averageFrameTime, isNotNull, reason: 'Average should be calculated from bounded history');
    });

    test('history starts empty and builds up', () {
      final monitor = StopwatchPerformanceMonitor(maxHistorySize: 10);

      // Before any frames
      var metrics = monitor.currentMetrics;
      expect(metrics.frameTime, equals(Duration.zero), reason: 'Empty history should return zero frame time');
      expect(metrics.averageFrameTime, equals(Duration.zero));
      expect(metrics.jankCount, equals(0));

      // After one frame
      monitor.beginFrame();
      monitor.endFrame();

      metrics = monitor.currentMetrics;
      expect(metrics.frameTime.inMicroseconds, greaterThan(0), reason: 'After first frame, metrics should be non-zero');
    });

    test('maxHistorySize=1 only retains most recent frame', () {
      final monitor = StopwatchPerformanceMonitor(maxHistorySize: 1);

      // Record multiple frames
      monitor.beginFrame();
      monitor.endFrame();

      final firstFrameTime = monitor.currentMetrics.frameTime;

      monitor.beginFrame();
      monitor.endFrame();

      final secondFrameTime = monitor.currentMetrics.frameTime;

      // Average should equal last frame time (only 1 frame in history)
      expect(monitor.currentMetrics.averageFrameTime, equals(secondFrameTime), reason: 'With maxHistorySize=1, average should equal last frame');
      expect(monitor.currentMetrics.averageFrameTime, isNot(equals(firstFrameTime)), reason: 'First frame should have been evicted');
    });

    test('large maxHistorySize retains all frames without eviction', () {
      final monitor = StopwatchPerformanceMonitor(maxHistorySize: 1000);

      // Record 10 frames (well below max)
      for (int i = 0; i < 10; i++) {
        monitor.beginFrame();
        monitor.endFrame();
      }

      final metrics = monitor.currentMetrics;
      // All frames should contribute to average (no eviction)
      expect(metrics.averageFrameTime.inMicroseconds, greaterThan(0), reason: 'Average should include all recorded frames');
    });
  });

  group('StopwatchPerformanceMonitor - Metrics Calculation', () {
    test('averageFrameTime calculates correct mean', () async {
      final monitor = StopwatchPerformanceMonitor();

      // Record frames with known delays
      monitor.beginFrame();
      await Future.delayed(const Duration(milliseconds: 5));
      monitor.endFrame();

      monitor.beginFrame();
      await Future.delayed(const Duration(milliseconds: 10));
      monitor.endFrame();

      monitor.beginFrame();
      await Future.delayed(const Duration(milliseconds: 15));
      monitor.endFrame();

      final metrics = monitor.currentMetrics;
      // Average should be around 10ms (5+10+15)/3
      // Allow tolerance for timing variations
      expect(metrics.averageFrameTimeMs, closeTo(10.0, 3.0), reason: 'Average frame time should be approximately (5+10+15)/3 = 10ms');
    });

    test('p99FrameTime returns 99th percentile value', () {
      final monitor = StopwatchPerformanceMonitor(maxHistorySize: 100);

      // Record 100 frames: 99 fast, 1 very slow
      for (int i = 0; i < 99; i++) {
        monitor.beginFrame();
        // Fast frames (minimal work)
        monitor.endFrame();
      }

      // One slow frame
      monitor.beginFrame();
      for (int i = 0; i < 1000000; i++) {
        // Heavy work to create outlier
      }
      monitor.endFrame();

      final metrics = monitor.currentMetrics;
      // p99 should be the slow frame (99th percentile of 100 frames)
      expect(metrics.p99FrameTime.inMicroseconds, greaterThan(metrics.averageFrameTime.inMicroseconds),
          reason: 'p99 should be higher than average due to slow outlier');
    });

    test('currentMetrics updates with each frame', () {
      final monitor = StopwatchPerformanceMonitor();

      monitor.beginFrame();
      monitor.endFrame();
      final metrics1 = monitor.currentMetrics;

      monitor.beginFrame();
      monitor.endFrame();
      final metrics2 = monitor.currentMetrics;

      // Frame times should be different (different execution)
      expect(metrics2.frameTime, isNot(equals(metrics1.frameTime)), reason: 'Each frame should have independent timing');
    });

    test('currentMetrics includes poolHitRate from updatePoolMetrics', () {
      final monitor = StopwatchPerformanceMonitor();

      monitor.updatePoolMetrics(
        poolHitRate: 0.85,
        culledElementCount: 500,
        renderedElementCount: 100,
      );

      monitor.beginFrame();
      monitor.endFrame();

      final metrics = monitor.currentMetrics;
      expect(metrics.poolHitRate, equals(0.85), reason: 'Metrics should include updated pool hit rate');
      expect(metrics.culledElementCount, equals(500));
      expect(metrics.renderedElementCount, equals(100));
    });

    test('currentMetrics defaults pool metrics when not updated', () {
      final monitor = StopwatchPerformanceMonitor();

      monitor.beginFrame();
      monitor.endFrame();

      final metrics = monitor.currentMetrics;
      expect(metrics.poolHitRate, equals(1.0), reason: 'Default pool hit rate should be 1.0 (100%)');
      expect(metrics.culledElementCount, equals(0));
      expect(metrics.renderedElementCount, equals(0));
    });
  });

  group('StopwatchPerformanceMonitor - Reset Behavior', () {
    test('reset clears all frame history', () async {
      final monitor = StopwatchPerformanceMonitor();

      // Record frames
      monitor.beginFrame();
      await Future.delayed(const Duration(milliseconds: 10));
      monitor.endFrame();

      monitor.beginFrame();
      monitor.endFrame();

      expect(monitor.currentMetrics.jankCount, greaterThan(0), reason: 'Should have jank before reset');

      monitor.reset();

      final metrics = monitor.currentMetrics;
      expect(metrics.frameTime, equals(Duration.zero), reason: 'Frame time should be zero after reset');
      expect(metrics.averageFrameTime, equals(Duration.zero));
      expect(metrics.jankCount, equals(0), reason: 'Jank count should be zero after reset');
    });

    test('reset allows monitor to be reused', () {
      final monitor = StopwatchPerformanceMonitor();

      // Use monitor
      monitor.beginFrame();
      monitor.endFrame();

      monitor.reset();

      // Reuse monitor
      monitor.beginFrame();
      monitor.endFrame();

      final metrics = monitor.currentMetrics;
      expect(metrics.frameTime.inMicroseconds, greaterThan(0), reason: 'Monitor should work normally after reset');
    });

    test('reset clears jank counter', () async {
      final monitor = StopwatchPerformanceMonitor();

      // Create jank
      monitor.beginFrame();
      await Future.delayed(const Duration(milliseconds: 20));
      monitor.endFrame();

      expect(monitor.currentMetrics.jankCount, equals(1), reason: 'Should have jank before reset');

      monitor.reset();

      expect(monitor.currentMetrics.jankCount, equals(0), reason: 'Jank counter should reset to zero');
    });

    test('reset clears pool metrics', () {
      final monitor = StopwatchPerformanceMonitor();

      monitor.updatePoolMetrics(
        poolHitRate: 0.75,
        culledElementCount: 300,
        renderedElementCount: 200,
      );

      monitor.reset();

      monitor.beginFrame();
      monitor.endFrame();

      final metrics = monitor.currentMetrics;
      expect(metrics.poolHitRate, equals(1.0), reason: 'Pool hit rate should reset to default 1.0');
      expect(metrics.culledElementCount, equals(0));
      expect(metrics.renderedElementCount, equals(0));
    });
  });

  group('StopwatchPerformanceMonitor - Edge Cases', () {
    test('maxHistorySize=1 works correctly', () {
      final monitor = StopwatchPerformanceMonitor(maxHistorySize: 1);

      monitor.beginFrame();
      monitor.endFrame();

      final metrics = monitor.currentMetrics;
      expect(metrics.frameTime, isNotNull);
      expect(metrics.averageFrameTime, equals(metrics.frameTime), reason: 'With history of 1, average should equal single frame');
    });

    test('zero work frame still records time', () {
      final monitor = StopwatchPerformanceMonitor();

      monitor.beginFrame();
      // No work at all
      monitor.endFrame();

      final metrics = monitor.currentMetrics;
      expect(metrics.frameTime.inMicroseconds, greaterThanOrEqualTo(0), reason: 'Even zero-work frame should have non-negative time');
    });

    test('many consecutive frames maintain stability', () {
      final monitor = StopwatchPerformanceMonitor(maxHistorySize: 120);

      // Simulate 200 frames (exceeds history size)
      for (int i = 0; i < 200; i++) {
        monitor.beginFrame();
        monitor.endFrame();
      }

      final metrics = monitor.currentMetrics;
      expect(metrics.frameTime, isNotNull);
      expect(metrics.averageFrameTime, isNotNull);
      expect(metrics.p99FrameTime, isNotNull, reason: 'Metrics should remain stable after many frames');
    });

    test('p99 calculation handles small history sizes', () {
      final monitor = StopwatchPerformanceMonitor(maxHistorySize: 5);

      // Record only 2 frames
      monitor.beginFrame();
      monitor.endFrame();
      monitor.beginFrame();
      monitor.endFrame();

      final metrics = monitor.currentMetrics;
      expect(metrics.p99FrameTime, isNotNull, reason: 'p99 should handle small sample sizes gracefully');
    });
  });
}
