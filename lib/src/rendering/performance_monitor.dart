// Implementation: PerformanceMonitor
// Feature: 002-core-rendering
// Purpose: Frame-level performance monitoring with jank detection
//
// Constitutional Compliance:
// - TDD: Contract tests written first (test/contract/rendering/performance_monitor_contract_test.dart)
// - Performance: <1ms overhead per frame (NFR-001)
// - Dependencies: dart:core only (Stopwatch, Duration)

import 'dart:core';
import 'package:braven_charts/src/rendering/performance_metrics.dart';

/// Production implementation of PerformanceMonitor using dart:core Stopwatch.
///
/// Tracks frame render times with microsecond precision, detects jank
/// (frames >16ms), maintains bounded history with LRU eviction.
///
/// ## Performance Characteristics
/// - beginFrame(): <0.1ms (start stopwatch)
/// - endFrame(): <0.5ms (stop, append to history, jank check)
/// - currentMetrics: <0.5ms (calculate average, p99 from bounded history)
/// - Memory: ~960 bytes for 120-frame history (8 bytes/Duration)
///
/// ## Contract Compliance
/// See: specs/002-core-rendering/contracts/performance_monitor.dart
class StopwatchPerformanceMonitor implements PerformanceMonitor {
  final Stopwatch _stopwatch = Stopwatch();
  final List<Duration> _frameTimes = [];
  final int _maxHistorySize;
  int _jankCount = 0;
  bool _frameInProgress = false;
  
  // Pool metrics (optional, for PerformanceMetrics construction)
  double _lastPoolHitRate = 1.0;
  int _lastCulledCount = 0;
  int _lastRenderedCount = 0;

  StopwatchPerformanceMonitor({int maxHistorySize = 120})
      : _maxHistorySize = maxHistorySize {
    assert(maxHistorySize > 0, 'maxHistorySize must be greater than 0');
  }

  @override
  int get maxHistorySize => _maxHistorySize;

  @override
  void beginFrame() {
    assert(!_frameInProgress, 
        'beginFrame() called twice without endFrame(). Frames must be paired.');
    _frameInProgress = true;
    _stopwatch.reset();
    _stopwatch.start();
  }

  @override
  void endFrame() {
    assert(_frameInProgress, 
        'endFrame() called without beginFrame(). Frames must be paired.');
    
    _stopwatch.stop();
    _frameInProgress = false;
    
    final frameTime = _stopwatch.elapsed;
    
    // Append to history with LRU eviction
    if (_frameTimes.length >= _maxHistorySize) {
      _frameTimes.removeAt(0); // Remove oldest (LRU)
    }
    _frameTimes.add(frameTime);
    
    // Jank detection: 16ms threshold for 60fps
    if (frameTime.inMicroseconds > 16000) {
      _jankCount++;
    }
  }

  @override
  PerformanceMetrics get currentMetrics {
    if (_frameTimes.isEmpty) {
      return PerformanceMetrics(
        frameTime: Duration.zero,
        averageFrameTime: Duration.zero,
        p99FrameTime: Duration.zero,
        jankCount: 0,
        poolHitRate: 1.0,
      );
    }

    final lastFrameTime = _frameTimes.last;
    
    // Calculate average frame time
    final totalMicros = _frameTimes.fold<int>(
      0,
      (sum, duration) => sum + duration.inMicroseconds,
    );
    final avgMicros = totalMicros ~/ _frameTimes.length;
    final averageFrameTime = Duration(microseconds: avgMicros);
    
    // Calculate p99 (99th percentile)
    final sortedTimes = List<Duration>.from(_frameTimes)
      ..sort((a, b) => a.inMicroseconds.compareTo(b.inMicroseconds));
    final p99Index = (sortedTimes.length * 0.99).floor();
    final p99FrameTime = sortedTimes[p99Index.clamp(0, sortedTimes.length - 1)];

    return PerformanceMetrics(
      frameTime: lastFrameTime,
      averageFrameTime: averageFrameTime,
      p99FrameTime: p99FrameTime,
      jankCount: _jankCount,
      poolHitRate: _lastPoolHitRate,
      culledElementCount: _lastCulledCount,
      renderedElementCount: _lastRenderedCount,
    );
  }

  @override
  void reset() {
    _stopwatch.reset();
    _frameTimes.clear();
    _jankCount = 0;
    _frameInProgress = false;
    _lastPoolHitRate = 1.0;
    _lastCulledCount = 0;
    _lastRenderedCount = 0;
  }

  /// Update pool metrics for next PerformanceMetrics snapshot.
  ///
  /// Called by RenderContext to inject pool/culling metrics.
  /// Not part of contract (implementation coordination detail).
  void updatePoolMetrics({
    required double poolHitRate,
    required int culledElementCount,
    required int renderedElementCount,
  }) {
    _lastPoolHitRate = poolHitRate;
    _lastCulledCount = culledElementCount;
    _lastRenderedCount = renderedElementCount;
  }
}

/// Abstract contract interface (re-exported for convenience).
///
/// See: specs/002-core-rendering/contracts/performance_monitor.dart
abstract class PerformanceMonitor {
  int get maxHistorySize;
  void beginFrame();
  void endFrame();
  PerformanceMetrics get currentMetrics;
  void reset();
}
