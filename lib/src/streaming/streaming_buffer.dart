// Copyright (c) 2025 braven_charts. All rights reserved.
// High-Performance Circular Buffer for Live Streaming

import '../models/chart_data_point.dart';
import '../utils/data_converter.dart';

/// High-performance circular buffer optimized for streaming chart data.
///
/// **Key Features**:
/// - O(1) add operation with automatic oldest-element eviction
/// - O(1) bounds access (incremental tracking, lazy recalculation on eviction)
/// - Fixed-size memory footprint (no allocations during streaming)
/// - FIFO ordering preserved for chart rendering
///
/// **Usage**:
/// ```dart
/// final buffer = StreamingBuffer(maxSize: 1000);
///
/// // Add points (O(1), auto-evicts oldest when full)
/// buffer.add(ChartDataPoint(x: 1, y: 10));
/// buffer.add(ChartDataPoint(x: 2, y: 20));
///
/// // Get bounds for viewport (O(1) typically, O(n) after eviction edge case)
/// final bounds = buffer.bounds;  // DataBounds(xMin: 1, xMax: 2, ...)
///
/// // Get ordered points for rendering
/// final points = buffer.toList();  // [point1, point2, ...]
/// ```
///
/// **Performance Characteristics**:
/// - `add()`: O(1) always
/// - `bounds`: O(1) typical, O(n) when evicted point was a boundary
/// - `toList()`: O(n) - creates new list in correct order
/// - `clear()`: O(1)
/// - Memory: Fixed at `maxSize * sizeof(ChartDataPoint)` after first fill
class StreamingBuffer {
  /// Creates a streaming buffer with the specified maximum capacity.
  ///
  /// **Parameters**:
  /// - [maxSize]: Maximum number of points to retain. Must be positive.
  ///   When the buffer is full, adding new points evicts the oldest.
  ///
  /// **Throws**: [AssertionError] if maxSize is not positive.
  StreamingBuffer({required int maxSize})
    : assert(maxSize > 0, 'maxSize must be positive'),
      _maxSize = maxSize,
      // Pre-allocate with dummy values (will be overwritten)
      _data = List<ChartDataPoint>.filled(
        maxSize,
        const ChartDataPoint(x: 0, y: 0),
      );

  final int _maxSize;
  final List<ChartDataPoint> _data;

  /// Next write position in circular buffer.
  int _head = 0;

  /// Current number of valid elements (0 to maxSize).
  int _count = 0;

  /// Version counter - incremented on every modification.
  /// Used for efficient change detection without comparing all data.
  int _version = 0;

  // ============================================================================
  // Incremental Bounds Tracking
  // ============================================================================

  /// Current minimum X value in buffer.
  double _xMin = double.infinity;

  /// Current maximum X value in buffer.
  double _xMax = double.negativeInfinity;

  /// Current minimum Y value in buffer.
  double _yMin = double.infinity;

  /// Current maximum Y value in buffer.
  double _yMax = double.negativeInfinity;

  /// Flag indicating bounds need full recalculation.
  ///
  /// Set true when an evicted point was at a boundary (min/max).
  /// Cleared after recalculation in [bounds] getter.
  bool _boundsNeedRecalc = false;

  /// Frame counter for throttling expensive bounds recalculation.
  /// Only recalculate every N frames to avoid stuttering during streaming.
  int _framesSinceLastRecalc = 0;

  /// Throttle interval: recalculate bounds every N frames when needed.
  /// At 60fps, value of 10 = recalc every ~166ms (acceptable latency).
  static const int _boundsRecalcThrottleFrames = 10;

  // Debug: Track add call rate
  int _addCallCount = 0;
  DateTime? _addTrackingStart;

  // ============================================================================
  // Public Properties
  // ============================================================================

  /// Maximum capacity of this buffer.
  int get maxSize => _maxSize;

  /// Current number of elements in the buffer.
  int get length => _count;

  /// Version counter - incremented on every add/clear operation.
  /// Use this for efficient change detection without comparing data.
  int get version => _version;

  /// Whether the buffer is empty.
  bool get isEmpty => _count == 0;

  /// Whether the buffer is not empty.
  bool get isNotEmpty => _count > 0;

  /// Whether the buffer has reached maximum capacity.
  bool get isFull => _count >= _maxSize;

  /// Data bounds of all points in the buffer.
  ///
  /// **Performance**:
  /// - O(1) when bounds are incrementally tracked
  /// - O(n) when recalculation is needed (after evicting a boundary point)
  ///
  /// Returns default bounds (0-1 range) if buffer is empty.
  DataBounds get bounds {
    if (_count == 0) {
      return const DataBounds(xMin: 0, xMax: 1, yMin: 0, yMax: 1);
    }

    // Throttle expensive O(n) recalculation to avoid stuttering during streaming.
    // Only recalculate every N frames when bounds are stale.
    if (_boundsNeedRecalc) {
      _framesSinceLastRecalc++;
      if (_framesSinceLastRecalc >= _boundsRecalcThrottleFrames) {
        _recalculateBounds();
        _framesSinceLastRecalc = 0;
      }
      // Else: use stale bounds for a few frames (acceptable for streaming UX)
    }

    return DataBounds(xMin: _xMin, xMax: _xMax, yMin: _yMin, yMax: _yMax);
  }

  // ============================================================================
  // Data Operations
  // ============================================================================

  /// Adds a data point to the buffer.
  ///
  /// If the buffer is full, the oldest point is automatically evicted.
  /// If the evicted point was at a min/max boundary, bounds will be
  /// recalculated on next access.
  ///
  /// **Performance**: O(1) always.
  void add(ChartDataPoint point) {
    // Debug: Track add call rate
    _addCallCount++;
    _addTrackingStart ??= DateTime.now();
    if (_addCallCount % 100 == 0) {
      // final elapsed = DateTime.now().difference(_addTrackingStart!).inMilliseconds;
      // final rate = _addCallCount / (elapsed / 1000);
      // Performance monitoring (disabled in production):
      // print('[StreamingBuffer.add] Called $rate Hz ($_addCallCount calls in ${elapsed}ms, buffer size: $_count/$_maxSize)');
      _addCallCount = 0;
      _addTrackingStart = DateTime.now();
    }

    // Handle eviction if buffer is full
    if (_count == _maxSize) {
      final evicted = _data[_head];

      // Check if evicted point was a boundary (requires recalculation)
      // Use tolerance for floating point comparison
      const tolerance = 1e-10;
      if ((evicted.x - _xMin).abs() < tolerance ||
          (evicted.x - _xMax).abs() < tolerance ||
          (evicted.y - _yMin).abs() < tolerance ||
          (evicted.y - _yMax).abs() < tolerance) {
        _boundsNeedRecalc = true;
      }
    }

    // Write point at head position
    _data[_head] = point;

    // Advance head (circular wrap)
    _head = (_head + 1) % _maxSize;

    // Increment count (up to maxSize)
    if (_count < _maxSize) {
      _count++;
    }

    // Increment version for change detection
    _version++;

    // Update bounds incrementally (always correct for new point)
    _updateBoundsIncremental(point);
  }

  /// Adds multiple data points to the buffer.
  ///
  /// More efficient than calling [add] repeatedly when you have
  /// a batch of points to add.
  ///
  /// **Performance**: O(k) where k = number of points to add.
  void addAll(List<ChartDataPoint> points) {
    for (final point in points) {
      add(point);
    }
  }

  /// Returns all points in the buffer in chronological order.
  ///
  /// The returned list is ordered from oldest to newest (FIFO order),
  /// suitable for chart rendering.
  ///
  /// **Performance**: O(n) where n = number of elements.
  ///
  /// **Note**: Creates a new list. For large buffers in tight loops,
  /// consider using [forEachInOrder] instead.
  List<ChartDataPoint> toList() {
    if (_count == 0) return const [];

    final result = <ChartDataPoint>[];

    // Calculate start position (oldest element)
    final start = _count < _maxSize ? 0 : _head;

    // Copy in order: start → end, then 0 → head-1 (if wrapped)
    for (var i = 0; i < _count; i++) {
      final index = (start + i) % _maxSize;
      result.add(_data[index]);
    }

    return result;
  }

  /// Iterates over all points in chronological order without allocation.
  ///
  /// Use this for performance-critical scenarios where you need to
  /// process all points but don't need a list.
  ///
  /// **Performance**: O(n) traversal, no allocation.
  void forEachInOrder(void Function(ChartDataPoint point) callback) {
    if (_count == 0) return;

    final start = _count < _maxSize ? 0 : _head;
    for (var i = 0; i < _count; i++) {
      final index = (start + i) % _maxSize;
      callback(_data[index]);
    }
  }

  /// Gets a point by logical index (0 = oldest, length-1 = newest).
  ///
  /// **Performance**: O(1).
  ///
  /// **Throws**: [RangeError] if index is out of bounds.
  ChartDataPoint operator [](int logicalIndex) {
    if (logicalIndex < 0 || logicalIndex >= _count) {
      throw RangeError.index(logicalIndex, this, 'index', null, _count);
    }
    final start = _count < _maxSize ? 0 : _head;
    final physicalIndex = (start + logicalIndex) % _maxSize;
    return _data[physicalIndex];
  }

  /// Iterates over a range of points by logical index without allocation.
  ///
  /// [startIndex] is inclusive, [endIndex] is exclusive.
  /// Useful for rendering only visible points.
  ///
  /// **Performance**: O(endIndex - startIndex), no allocation.
  void forEachInRange(
    int startIndex,
    int endIndex,
    void Function(ChartDataPoint point, int index) callback,
  ) {
    if (_count == 0) return;
    final clampedStart = startIndex.clamp(0, _count);
    final clampedEnd = endIndex.clamp(0, _count);

    final bufferStart = _count < _maxSize ? 0 : _head;
    for (var i = clampedStart; i < clampedEnd; i++) {
      final physicalIndex = (bufferStart + i) % _maxSize;
      callback(_data[physicalIndex], i);
    }
  }

  /// Clears all data from the buffer.
  ///
  /// Resets the buffer to empty state. Does not deallocate memory
  /// (the underlying array remains allocated for reuse).
  ///
  /// **Performance**: O(1).
  void clear() {
    _head = 0;
    _count = 0;
    _version++;
    _xMin = double.infinity;
    _xMax = double.negativeInfinity;
    _yMin = double.infinity;
    _yMax = double.negativeInfinity;
    _boundsNeedRecalc = false;
  }

  /// Returns the most recently added point, or null if empty.
  ///
  /// **Performance**: O(1).
  ChartDataPoint? get latest {
    if (_count == 0) return null;
    // Head points to NEXT write position, so latest is at head-1
    final latestIndex = (_head - 1 + _maxSize) % _maxSize;
    return _data[latestIndex];
  }

  /// Returns the oldest point in the buffer, or null if empty.
  ///
  /// **Performance**: O(1).
  ChartDataPoint? get oldest {
    if (_count == 0) return null;
    if (_count < _maxSize) {
      return _data[0]; // Not yet wrapped, oldest is first
    }
    return _data[_head]; // Wrapped, oldest is at head (next to be overwritten)
  }

  // ============================================================================
  // Internal Bounds Management
  // ============================================================================

  /// Updates bounds incrementally with a new point.
  ///
  /// Called on every add. This ensures bounds are always correct for
  /// the newest point, even if _boundsNeedRecalc is true.
  void _updateBoundsIncremental(ChartDataPoint point) {
    if (point.x < _xMin) _xMin = point.x;
    if (point.x > _xMax) _xMax = point.x;
    if (point.y < _yMin) _yMin = point.y;
    if (point.y > _yMax) _yMax = point.y;
  }

  /// Recalculates bounds by scanning all elements.
  ///
  /// Called lazily when [bounds] is accessed and [_boundsNeedRecalc] is true.
  ///
  /// **Performance**: O(n).
  void _recalculateBounds() {
    if (_count == 0) {
      _xMin = double.infinity;
      _xMax = double.negativeInfinity;
      _yMin = double.infinity;
      _yMax = double.negativeInfinity;
      _boundsNeedRecalc = false;
      return;
    }

    // Reset to extremes
    double xMin = double.infinity;
    double xMax = double.negativeInfinity;
    double yMin = double.infinity;
    double yMax = double.negativeInfinity;

    // Scan all valid elements
    final start = _count < _maxSize ? 0 : _head;
    for (var i = 0; i < _count; i++) {
      final index = (start + i) % _maxSize;
      final point = _data[index];
      if (point.x < xMin) xMin = point.x;
      if (point.x > xMax) xMax = point.x;
      if (point.y < yMin) yMin = point.y;
      if (point.y > yMax) yMax = point.y;
    }

    _xMin = xMin;
    _xMax = xMax;
    _yMin = yMin;
    _yMax = yMax;
    _boundsNeedRecalc = false;
  }

  @override
  String toString() {
    return 'StreamingBuffer(count: $_count/$_maxSize, '
        'bounds: x[$_xMin..$_xMax] y[$_yMin..$_yMax])';
  }
}
