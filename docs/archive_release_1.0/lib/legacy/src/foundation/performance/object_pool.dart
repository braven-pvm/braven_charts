// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

/// Generic object pool for memory-efficient object reuse.
///
/// ObjectPool<T> manages a pool of reusable objects to minimize allocation
/// overhead. Objects are created on-demand and reset when returned to the pool.
///
/// Example:
/// ```dart
/// final pool = ObjectPool<StringBuilder>(
///   factory: () => StringBuilder(),
///   reset: (sb) => sb.clear(),
///   maxSize: 50,
/// );
///
/// final builder = pool.acquire();
/// builder.write('Hello');
/// pool.release(builder); // Returns to pool after reset
/// ```
///
/// Performance: Acquire/Release operations complete in <100ns (FR-005.3)
class ObjectPool<T> {
  /// Factory function to create new instances
  final T Function() _factory;

  /// Reset function called before returning objects to pool
  final void Function(T) _reset;

  /// Maximum number of objects to keep in pool
  final int maxSize;

  // Internal state
  final List<T> _available = [];
  final Set<T> _inUse = {};
  int _totalCreated = 0;
  int _acquireCount = 0;
  int _releaseCount = 0;

  /// Creates an object pool with specified factory and reset functions.
  ///
  /// [factory]: Function to create new instances when pool is empty
  /// [reset]: Function to reset objects before returning to pool
  /// [maxSize]: Maximum pool size (default: 100)
  ObjectPool({
    required T Function() factory,
    required void Function(T) reset,
    this.maxSize = 100,
  }) : _factory = factory,
       _reset = reset,
       assert(maxSize > 0, 'maxSize must be greater than 0');

  /// Returns pool usage statistics.
  PoolStatistics get statistics {
    final hitRate = _acquireCount > 0 ? _releaseCount / _acquireCount : 0.0;
    return PoolStatistics(
      totalCreated: _totalCreated,
      currentSize: _available.length,
      currentInUse: _inUse.length,
      acquireCount: _acquireCount,
      releaseCount: _releaseCount,
      hitRate: hitRate,
    );
  }

  /// Acquires an object from the pool.
  ///
  /// If the pool has available objects, reuses one. Otherwise, creates a new
  /// object using the factory function.
  ///
  /// Performance: <100ns per operation (FR-005.3)
  T acquire() {
    _acquireCount++;

    final T object;
    if (_available.isNotEmpty) {
      // Reuse from pool
      object = _available.removeLast();
    } else {
      // Create new object
      object = _factory();
      _totalCreated++;
    }

    _inUse.add(object);
    return object;
  }

  /// Returns an object to the pool.
  ///
  /// Calls the reset function on the object before adding it back to the pool.
  /// If the pool is at max capacity, the object is discarded.
  ///
  /// Performance: <100ns per operation (FR-005.3)
  void release(T object) {
    assert(
      _inUse.contains(object),
      'Cannot release object not acquired from this pool',
    );
    _inUse.remove(object);

    _releaseCount++;

    // Reset the object
    _reset(object);

    // Add back to pool if not at max capacity
    if (_available.length < maxSize) {
      _available.add(object);
    }
    // Otherwise, let it be garbage collected
  }

  /// Checks if an object is currently tracked by this pool.
  ///
  /// Returns true if the object was acquired and not yet released.
  bool isTracked(T object) {
    return _inUse.contains(object);
  }

  /// Clears all objects from the pool and resets statistics.
  ///
  /// All in-use objects remain valid but will not be tracked after this call.
  void clear() {
    _available.clear();
    _inUse.clear();
    _totalCreated = 0;
    _acquireCount = 0;
    _releaseCount = 0;
  }

  @override
  String toString() {
    return 'ObjectPool<$T>(available: ${_available.length}, '
        'inUse: ${_inUse.length}, total: $_totalCreated)';
  }
}

/// Pool usage statistics.
///
/// Provides insights into pool performance and object reuse efficiency.
class PoolStatistics {
  /// Total number of objects created since pool initialization
  final int totalCreated;

  /// Current number of objects available in the pool
  final int currentSize;

  /// Current number of objects in use (acquired but not released)
  final int currentInUse;

  /// Total number of acquire() calls
  final int acquireCount;

  /// Total number of release() calls
  final int releaseCount;

  /// Hit rate: ratio of releases to acquires (indicates reuse efficiency)
  final double hitRate;

  const PoolStatistics({
    required this.totalCreated,
    required this.currentSize,
    required this.currentInUse,
    required this.acquireCount,
    required this.releaseCount,
    required this.hitRate,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PoolStatistics &&
          runtimeType == other.runtimeType &&
          totalCreated == other.totalCreated &&
          currentSize == other.currentSize &&
          currentInUse == other.currentInUse &&
          acquireCount == other.acquireCount &&
          releaseCount == other.releaseCount &&
          (hitRate - other.hitRate).abs() < 0.001; // Float comparison

  @override
  int get hashCode => Object.hash(
    totalCreated,
    currentSize,
    currentInUse,
    acquireCount,
    releaseCount,
    hitRate,
  );

  @override
  String toString() =>
      'PoolStatistics('
      'created: $totalCreated, '
      'size: $currentSize, '
      'inUse: $currentInUse, '
      'hitRate: ${(hitRate * 100).toStringAsFixed(1)}%'
      ')';
}
