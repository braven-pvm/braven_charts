// Contract: Performance Primitives (FR-002)
// This file defines API contracts for performance optimization utilities.
//
// NOTE: This is a CONTRACT file, not an implementation.
// Compile errors are expected - this defines the API surface.
// Implementation classes will be created during Phase 3-4.

/// ObjectPool<T> Contract (FR-002.1)
///
/// Generic object pool for memory-efficient object reuse.
///
/// MUST:
/// - Support generic type-safe pooling
/// - Implement acquire/release pattern
/// - Automatically reset objects on release
/// - Be configurable for max pool size
/// - Provide pool statistics
///
/// Performance Targets:
/// - Acquire operation: <100ns (FR-005.3)
/// - Release operation: <100ns (FR-005.3)
/// - Memory overhead: <1KB per pool (FR-005.8)
abstract class ObjectPool<T> {
  // Configuration
  int get maxSize;

  // Statistics
  PoolStatistics get statistics;

  // Factory constructor
  factory ObjectPool({
    required T Function() factory,
    required void Function(T) reset,
    int maxSize = 100,
  }) = _ObjectPoolImpl<T>;

  // Lifecycle operations
  /// Acquire an object from the pool.
  /// Creates a new object if pool is empty.
  /// MUST complete in <100ns (FR-005.3)
  T acquire();

  /// Return an object to the pool.
  /// Calls reset function before storing.
  /// MUST complete in <100ns (FR-005.3)
  void release(T object);

  /// Empty the pool and reset statistics
  void clear();

  /// Validate that the object was acquired from this pool
  bool isTracked(T object);
}

/// Pool usage statistics
class PoolStatistics {
  final int totalCreated;
  final int currentSize;
  final int currentInUse;
  final int acquireCount;
  final int releaseCount;
  final double hitRate; // releases / acquires

  const PoolStatistics({
    required this.totalCreated,
    required this.currentSize,
    required this.currentInUse,
    required this.acquireCount,
    required this.releaseCount,
    required this.hitRate,
  });

  @override
  String toString() => 'PoolStatistics('
      'created: $totalCreated, '
      'size: $currentSize, '
      'inUse: $currentInUse, '
      'hitRate: ${(hitRate * 100).toStringAsFixed(1)}%'
      ')';
}

/// ViewportCuller Contract (FR-002.2)
///
/// Efficiently filter data points to visible viewport region.
///
/// MUST:
/// - Support spatial filtering
/// - Optimize for both ordered and unordered data
/// - Support configurable cull margin
/// - Use binary search for ordered data
///
/// Performance Targets:
/// - 10,000 points: <1ms (FR-005.4)
/// - Ordered data: O(log n + m) where m = visible points
/// - Unordered data: O(n)
abstract class ViewportCuller {
  // Configuration
  double get margin;

  // Factory constructor
  factory ViewportCuller({double margin = 0.1}) = _ViewportCullerImpl;

  /// Filter points to visible viewport plus margin.
  ///
  /// Parameters:
  /// - points: All data points to filter
  /// - viewportX: Visible x-axis range
  /// - viewportY: Visible y-axis range
  /// - isXOrdered: True if points are sorted by x-value
  ///
  /// Returns: Filtered list of visible points
  ///
  /// Performance: MUST complete in <1ms for 10,000 points (FR-005.4)
  List<ChartDataPoint> cull({
    required List<ChartDataPoint> points,
    required DataRange viewportX,
    required DataRange viewportY,
    required bool isXOrdered,
  });

  /// Calculate effective viewport with margin applied
  ViewportBounds calculateBounds({
    required DataRange viewportX,
    required DataRange viewportY,
  });
}

/// Viewport bounds with margin
class ViewportBounds {
  final DataRange xRange;
  final DataRange yRange;

  const ViewportBounds({
    required this.xRange,
    required this.yRange,
  });

  bool contains(ChartDataPoint point) => xRange.contains(point.x) && yRange.contains(point.y);
}

/// BatchProcessor Contract (FR-002.3)
///
/// Group similar operations for rendering efficiency.
///
/// MUST:
/// - Support generic batching by key
/// - Minimize state changes in rendering
/// - Be configurable for batch size
abstract class BatchProcessor<T, K> {
  // Configuration
  int get batchSize;

  // Factory constructor
  factory BatchProcessor({
    required K Function(T) keyExtractor,
    int batchSize = 100,
  }) = _BatchProcessorImpl<T, K>;

  /// Group items by extracted key.
  ///
  /// Returns: Map of key → list of items with that key
  ///
  /// Use cases:
  /// - Group points by color for Paint reuse
  /// - Group shapes by fill style
  /// - Group text by font
  Map<K, List<T>> batch(List<T> items);

  /// Process items in batches with callback
  void processBatches(
    List<T> items,
    void Function(K key, List<T> batch) processor,
  );
}

// Supporting types (referenced from other contracts)
class ChartDataPoint {
  final double x;
  final double y;
  const ChartDataPoint({required this.x, required this.y});
}

class DataRange {
  final double min;
  final double max;
  const DataRange({required this.min, required this.max});
  bool contains(double value) => value >= min && value <= max;
}

// Placeholder implementations (will throw errors to ensure contract testing)
class _ObjectPoolImpl<T> implements ObjectPool<T> {
  @override
  int get maxSize => throw UnimplementedError('Contract only');

  @override
  PoolStatistics get statistics => throw UnimplementedError('Contract only');

  @override
  T acquire() => throw UnimplementedError('Contract only');

  @override
  void release(T object) => throw UnimplementedError('Contract only');

  @override
  void clear() => throw UnimplementedError('Contract only');

  @override
  bool isTracked(T object) => throw UnimplementedError('Contract only');
}

class _ViewportCullerImpl implements ViewportCuller {
  @override
  double get margin => throw UnimplementedError('Contract only');

  @override
  List<ChartDataPoint> cull({
    required List<ChartDataPoint> points,
    required DataRange viewportX,
    required DataRange viewportY,
    required bool isXOrdered,
  }) =>
      throw UnimplementedError('Contract only');

  @override
  ViewportBounds calculateBounds({
    required DataRange viewportX,
    required DataRange viewportY,
  }) =>
      throw UnimplementedError('Contract only');
}

class _BatchProcessorImpl<T, K> implements BatchProcessor<T, K> {
  @override
  int get batchSize => throw UnimplementedError('Contract only');

  @override
  Map<K, List<T>> batch(List<T> items) => throw UnimplementedError('Contract only');

  @override
  void processBatches(
    List<T> items,
    void Function(K key, List<T> batch) processor,
  ) =>
      throw UnimplementedError('Contract only');
}
