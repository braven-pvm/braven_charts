// Implementation: PerformanceMetrics
// Feature: 002-core-rendering
// Purpose: Immutable performance data snapshot
//
// TDD Phase: GREEN - Making contract tests pass
//
// Constitutional Compliance:
// - Immutability: All fields final, const constructor
// - Value semantics: Pure data, no behavior
// - Zero dependencies: dart:core only

/// Immutable snapshot of rendering performance metrics.
///
/// Contains frame timing statistics, jank detection results, and pool
/// performance data collected during rendering. Used for performance
/// validation, debugging, and monitoring.
///
/// ## Usage
///
/// ```dart
/// final metrics = PerformanceMetrics(
///   frameTime: Duration(microseconds: 7500),
///   averageFrameTime: Duration(microseconds: 7200),
///   p99FrameTime: Duration(microseconds: 14800),
///   jankCount: 2,
///   poolHitRate: 0.94,
///   culledElementCount: 9500,
///   renderedElementCount: 500,
/// );
///
/// if (metrics.meetsTargets) {
///   print('Performance OK: ${metrics.averageFrameTimeMs}ms avg');
/// } else {
///   print('Performance issue detected');
/// }
/// ```
///
/// ## Constitutional Compliance
///
/// - **Immutability**: All fields `final`, const constructor
/// - **Value Object**: No identity, equality based on field values
/// - **Zero Dependencies**: Uses only dart:core Duration
/// - **Performance**: All getters O(1), no computation
class PerformanceMetrics {
  /// Duration of the most recent frame render operation.
  ///
  /// Measured from beginFrame() to endFrame() using dart:core Stopwatch.
  /// Microsecond precision (e.g., Duration(microseconds: 7500) = 7.5ms).
  ///
  /// Used for:
  /// - Real-time performance monitoring
  /// - Jank detection (>16ms threshold)
  /// - Frame time charts/graphs
  final Duration frameTime;

  /// Average frame time over history window.
  ///
  /// Calculated as mean of frame times in bounded history (default 120 frames).
  /// Used for overall performance assessment.
  ///
  /// **Target**: <8ms for 60fps rendering (spec §NFR-001)
  final Duration averageFrameTime;

  /// 99th percentile frame time (worst 1% of frames).
  ///
  /// Indicates worst-case performance. Useful for detecting occasional spikes
  /// that don't affect average but cause user-visible jank.
  ///
  /// **Target**: <16ms (60fps budget) per spec §NFR-001
  final Duration p99FrameTime;

  /// Total number of jank frames detected (>16ms threshold).
  ///
  /// Increments when endFrame() detects frame time exceeding 16000 microseconds.
  /// Accumulated across entire monitoring session until reset().
  ///
  /// **Target**: 0 jank frames in typical interaction (spec §User Scenarios)
  final int jankCount;

  /// Object pool hit rate (0.0-1.0).
  ///
  /// Percentage of pool acquire() calls satisfied from pool (not allocated).
  /// Calculated as: hits / (hits + allocations).
  ///
  /// **Target**: >0.90 (90% hit rate) per spec §FR-001
  ///
  /// Low hit rate indicates:
  /// - Pool too small (increase maxSize)
  /// - Pool exhaustion (too many simultaneous acquires)
  /// - Release/acquire imbalance (leak)
  final double poolHitRate;

  /// Number of elements culled by viewport (not rendered).
  ///
  /// Defaults to 0 if not provided. Indicates effectiveness of culling optimization.
  ///
  /// Example: 10,000 total points, 500 rendered → 9,500 culled
  final int culledElementCount;

  /// Number of elements actually rendered (drawn to canvas).
  ///
  /// Defaults to 0 if not provided.
  /// Used with [culledElementCount] to calculate culling ratio.
  ///
  /// Example: 10,000 total points, 500 rendered → renderedElementCount = 500
  final int renderedElementCount;

  /// Create immutable performance metrics snapshot.
  ///
  /// All Duration fields must be non-negative. [poolHitRate] must be in
  /// range [0.0, 1.0]. [jankCount] and element counts must be >= 0.
  ///
  /// Assertions validate constraints in debug mode.
  const PerformanceMetrics({
    required this.frameTime,
    required this.averageFrameTime,
    required this.p99FrameTime,
    required this.jankCount,
    required this.poolHitRate,
    this.culledElementCount = 0,
    this.renderedElementCount = 0,
  }) : assert(frameTime >= Duration.zero, 'frameTime must be non-negative'),
       assert(
         averageFrameTime >= Duration.zero,
         'averageFrameTime must be non-negative',
       ),
       assert(
         p99FrameTime >= Duration.zero,
         'p99FrameTime must be non-negative',
       ),
       assert(jankCount >= 0, 'jankCount must be non-negative'),
       assert(
         culledElementCount >= 0,
         'culledElementCount must be non-negative',
       ),
       assert(
         renderedElementCount >= 0,
         'renderedElementCount must be non-negative',
       ),
       assert(
         poolHitRate >= 0.0 && poolHitRate <= 1.0,
         'poolHitRate must be in range [0.0, 1.0]',
       );

  /// Check if performance meets constitutional targets.
  ///
  /// Returns true if ALL targets satisfied:
  /// - Average frame time <8ms (8000 microseconds)
  /// - 99th percentile frame time <16ms (16000 microseconds)
  /// - Pool hit rate >90% (0.90)
  ///
  /// **Usage**: Quick validation in tests and monitoring dashboards.
  ///
  /// ```dart
  /// if (!metrics.meetsTargets) {
  ///   print('Performance degradation: avg=${metrics.averageFrameTimeMs}ms');
  /// }
  /// ```
  bool get meetsTargets {
    return averageFrameTime.inMicroseconds <= 8000 &&
        p99FrameTime.inMicroseconds <= 16000 &&
        poolHitRate >= 0.90;
  }

  /// Average frame time in milliseconds (convenience getter).
  ///
  /// Converts [averageFrameTime] from Duration to double milliseconds.
  /// Useful for logging and display (humans think in milliseconds).
  ///
  /// Example: Duration(microseconds: 7500) → 7.5ms
  double get averageFrameTimeMs {
    return averageFrameTime.inMicroseconds / 1000.0;
  }

  /// 99th percentile frame time in milliseconds (convenience getter).
  ///
  /// Converts [p99FrameTime] from Duration to double milliseconds.
  ///
  /// Example: Duration(microseconds: 14800) → 14.8ms
  double get p99FrameTimeMs {
    return p99FrameTime.inMicroseconds / 1000.0;
  }

  /// Culling ratio (culled / total elements).
  ///
  /// Returns 0.0 if no elements (culled + rendered = 0).
  ///
  /// Example: 9500 culled, 500 rendered → 9500/10000 = 0.95 (95% culled)
  double get cullingRatio {
    final total = culledElementCount + renderedElementCount;
    if (total == 0) return 0.0;

    return culledElementCount / total;
  }

  @override
  String toString() {
    return 'PerformanceMetrics('
        'frameTime: ${frameTime.inMicroseconds}µs, '
        'avg: ${averageFrameTimeMs.toStringAsFixed(2)}ms, '
        'p99: ${p99FrameTimeMs.toStringAsFixed(2)}ms, '
        'jank: $jankCount, '
        'poolHitRate: ${(poolHitRate * 100).toStringAsFixed(1)}%, '
        'culled: $culledElementCount, '
        'rendered: $renderedElementCount)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is PerformanceMetrics &&
        other.frameTime == frameTime &&
        other.averageFrameTime == averageFrameTime &&
        other.p99FrameTime == p99FrameTime &&
        other.jankCount == jankCount &&
        other.poolHitRate == poolHitRate &&
        other.culledElementCount == culledElementCount &&
        other.renderedElementCount == renderedElementCount;
  }

  @override
  int get hashCode {
    return Object.hash(
      frameTime,
      averageFrameTime,
      p99FrameTime,
      jankCount,
      poolHitRate,
      culledElementCount,
      renderedElementCount,
    );
  }
}
