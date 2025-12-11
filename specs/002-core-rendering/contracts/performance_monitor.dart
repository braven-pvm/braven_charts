// Contract: PerformanceMonitor Interface
// Feature: 002-core-rendering
// Purpose: Define performance monitoring contract for frame timing and jank detection
//
// Constitutional Compliance:
// - TDD: This contract must have failing tests BEFORE implementation
// - Performance: Monitoring overhead MUST be <1ms per frame (NFR-001)
// - Accuracy: Frame time measurement MUST be ±0.5ms accurate (FR-004)

import 'package:braven_charts/legacy/src/rendering/performance_metrics.dart';

/// Contract for frame-level performance monitoring and jank detection.
///
/// A [PerformanceMonitor] tracks rendering performance by measuring frame
/// render times, detecting jank (frames >16ms), and exposing metrics for
/// debugging and validation.
///
/// ## Contract Requirements
///
/// 1. **Paired Calls**: [beginFrame] and [endFrame] MUST be called in pairs.
///    Calling endFrame() without beginFrame() is a contract violation.
///
/// 2. **Timing Accuracy**: Frame time measurement MUST be accurate to ±0.5ms
///    using dart:core Stopwatch (microsecond precision).
///
/// 3. **Jank Detection**: Frames exceeding 16ms threshold MUST increment
///    jank counter. No false negatives allowed (100% detection rate).
///
/// 4. **Low Overhead**: Monitoring operations (begin/end/metrics) MUST
///    complete in <1ms total per frame (NFR-001 requirement).
///
/// 5. **Bounded History**: Frame time history MUST be bounded to prevent
///    unbounded memory growth. Default: 120 frames (2 seconds @ 60fps).
///
/// 6. **Thread Safety**: Not required. Monitoring expected on single render
///    thread (Flutter main isolate).
///
/// 7. **Reset Capability**: [reset] MUST clear all accumulated state
///    (history, jank count) for test reproducibility.
///
/// ## Example Usage
///
/// ```dart
/// final monitor = PerformanceMonitor(maxHistorySize: 120);
///
/// // Each frame:
/// monitor.beginFrame();
/// try {
///   // ... rendering operations ...
/// } finally {
///   monitor.endFrame();
/// }
///
/// // Check performance:
/// final metrics = monitor.currentMetrics;
/// if (!metrics.meetsTargets) {
///   print('Performance degradation: ${metrics.averageFrameTime}');
/// }
/// ```
///
/// ## Testing Contract
///
/// Implementations MUST pass these contract tests:
///
/// 1. **Timing Accuracy**: Measure known duration (sleep/delay), verify
///    reported frame time within ±0.5ms tolerance.
///
/// 2. **Jank Detection**: Simulate 17ms frame, verify jankCount increments.
///    Simulate 15ms frame, verify jankCount unchanged.
///
/// 3. **Paired Call Validation**: Call endFrame() without beginFrame(),
///    verify assertion error thrown.
///
/// 4. **History Bounding**: Record maxHistorySize + 10 frames, verify
///    history length == maxHistorySize (LRU eviction).
///
/// 5. **Low Overhead**: Measure begin/end/metrics overhead, verify <1ms
///    (benchmark test with 1000 iterations).
///
/// 6. **Reset Correctness**: Accumulate metrics, call reset(), verify
///    jankCount == 0 and history empty.
abstract class PerformanceMonitor {
  /// Maximum number of frame times to retain in history.
  ///
  /// Default: 120 frames (2 seconds @ 60fps).
  /// Larger values provide more statistical data but consume more memory.
  /// Smaller values reduce memory but may miss performance trends.
  ///
  /// **Memory Impact**: Each Duration is 8 bytes, so 120 frames = 960 bytes.
  int get maxHistorySize;

  /// Begin frame timing measurement.
  ///
  /// Starts internal stopwatch for current frame. MUST be paired with
  /// [endFrame] call. Multiple beginFrame() calls without endFrame()
  /// is a contract violation (assertion error in debug mode).
  ///
  /// **Performance**: This operation MUST complete in <0.1ms.
  ///
  /// **Usage Pattern**:
  /// ```dart
  /// monitor.beginFrame();
  /// try {
  ///   renderFrame();
  /// } finally {
  ///   monitor.endFrame(); // Ensure always called
  /// }
  /// ```
  void beginFrame();

  /// End frame timing measurement and record metrics.
  ///
  /// Stops internal stopwatch, calculates frame time, detects jank (>16ms),
  /// and appends to frame history (LRU eviction if at capacity).
  ///
  /// MUST be called after [beginFrame]. Calling endFrame() without
  /// beginFrame() is a contract violation (assertion error).
  ///
  /// **Jank Detection**: If frame time > 16000 microseconds, jank counter
  /// increments. Threshold is 16ms for 60fps (1000ms / 60 ≈ 16.67ms).
  ///
  /// **Performance**: This operation MUST complete in <0.5ms (includes
  /// history append, jank check, statistical calculations).
  void endFrame();

  /// Get current performance metrics snapshot.
  ///
  /// Returns immutable [PerformanceMetrics] value object with:
  /// - Last frame time
  /// - Average frame time (over history)
  /// - 99th percentile frame time
  /// - Jank count (total frames >16ms)
  /// - Pool hit rate (from pools passed to monitor)
  ///
  /// **Performance**: This operation MUST complete in <0.5ms (statistical
  /// calculations on bounded history).
  ///
  /// **Immutability**: Returned metrics are snapshot at call time. Subsequent
  /// frames do not mutate returned object.
  ///
  /// **Thread Safety**: Getter expected to be called on same thread as
  /// begin/end. No synchronization required.
  PerformanceMetrics get currentMetrics;

  /// Reset all accumulated metrics and history.
  ///
  /// Clears frame time history, resets jank counter to zero. Used for:
  /// - Test setup (ensure clean state)
  /// - Runtime reset (user action or profiling session)
  ///
  /// **Post-Condition**: After reset(), currentMetrics should reflect
  /// empty state (no frames recorded). First subsequent frame becomes
  /// new baseline.
  ///
  /// **Performance**: This operation completes immediately (<0.1ms).
  void reset();
}

/// Default implementation of [PerformanceMonitor] using dart:core Stopwatch.
///
/// This is the production implementation. Uses Stopwatch for microsecond-
/// precision timing, maintains bounded frame history with LRU eviction,
/// detects jank at 16ms threshold.
///
/// **Constitutional Compliance**:
/// - Zero external dependencies (dart:core only)
/// - TDD: Tests written before this implementation
/// - Performance: <1ms overhead validated by benchmarks
///
/// NOT part of contract (implementation detail). Placed here for reference.
/// Actual implementation goes in lib/src/rendering/performance_monitor.dart.
class StopwatchPerformanceMonitor implements PerformanceMonitor {
  // Private fields (implementation detail):
  // - Stopwatch _stopwatch
  // - List<Duration> _frameTimes
  // - int _jankCount
  // - int _maxHistorySize
  // - bool _frameInProgress

  @override
  int get maxHistorySize => throw UnimplementedError('TDD: Test first');

  @override
  void beginFrame() => throw UnimplementedError('TDD: Test first');

  @override
  void endFrame() => throw UnimplementedError('TDD: Test first');

  @override
  PerformanceMetrics get currentMetrics =>
      throw UnimplementedError('TDD: Test first');

  @override
  void reset() => throw UnimplementedError('TDD: Test first');
}

/// Contract test helper: Mock monitor for testing layer/pipeline behavior.
///
/// Allows tests to verify that layers/pipeline correctly call begin/end and
/// access metrics. NOT for production use.
class MockPerformanceMonitor implements PerformanceMonitor {
  int beginFrameCallCount = 0;
  int endFrameCallCount = 0;
  int metricsAccessCount = 0;

  final PerformanceMetrics _mockMetrics;

  MockPerformanceMonitor({
    PerformanceMetrics? mockMetrics,
  }) : _mockMetrics = mockMetrics ??
            const PerformanceMetrics(
              frameTime: Duration(microseconds: 7000),
              averageFrameTime: Duration(microseconds: 7500),
              p99FrameTime: Duration(microseconds: 15000),
              jankCount: 0,
              poolHitRate: 0.95,
            );

  @override
  int get maxHistorySize => 120;

  @override
  void beginFrame() {
    beginFrameCallCount++;
  }

  @override
  void endFrame() {
    endFrameCallCount++;
  }

  @override
  PerformanceMetrics get currentMetrics {
    metricsAccessCount++;
    return _mockMetrics;
  }

  @override
  void reset() {
    beginFrameCallCount = 0;
    endFrameCallCount = 0;
    metricsAccessCount = 0;
  }
}
