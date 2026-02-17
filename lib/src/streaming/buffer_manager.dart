// Copyright (c) 2025 braven_charts. All rights reserved.
// FIFO Buffer Manager for Streaming Data

import 'dart:collection' show Queue;

/// Generic FIFO buffer manager for managing collections with maximum size limits.
///
/// Provides a simple, type-safe wrapper around Dart's Queue with automatic
/// oldest-element discard when capacity is reached. Designed for buffering
/// streaming data with size constraints.
///
/// **Characteristics**:
/// - FIFO (First-In-First-Out) ordering
/// - O(1) add and remove operations
/// - Automatic overflow handling (discards oldest when full)
/// - Type-safe generic implementation
/// - No external dependencies (uses dart:collection only)
///
/// **Example Usage**:
/// ```dart
/// // Create buffer with 1000-element capacity
/// final buffer = BufferManager<ChartDataPoint>(maxSize: 1000);
///
/// // Add elements
/// buffer.add(ChartDataPoint(x: 1, y: 10));
/// buffer.add(ChartDataPoint(x: 2, y: 20));
///
/// // Check status
/// print(buffer.length);    // 2
/// print(buffer.isFull);    // false
///
/// // Retrieve and remove all
/// final allElements = buffer.removeAll();  // [point1, point2]
/// print(buffer.isEmpty);   // true
/// ```
class BufferManager<T> {
  /// Creates a buffer manager with the specified maximum size.
  ///
  /// Parameters:
  /// - [maxSize]: Maximum number of elements the buffer can hold. Must be positive.
  ///
  /// Throws [AssertionError] if [maxSize] is not positive.
  BufferManager({required int maxSize})
    : assert(maxSize > 0, 'maxSize must be positive'),
      _maxSize = maxSize,
      _queue = Queue<T>();

  final int _maxSize;
  final Queue<T> _queue;

  /// Maximum capacity of this buffer.
  ///
  /// Once the buffer reaches this size, adding new elements will automatically
  /// discard the oldest element (FIFO overflow behavior).
  int get maxSize => _maxSize;

  /// Current number of elements in the buffer.
  ///
  /// Ranges from 0 (empty) to [maxSize] (full).
  int get length => _queue.length;

  /// Whether the buffer has reached its maximum capacity.
  ///
  /// When true, the next [add] operation will discard the oldest element.
  bool get isFull => _queue.length >= _maxSize;

  /// Whether the buffer is currently empty.
  bool get isEmpty => _queue.isEmpty;

  /// Whether the buffer contains at least one element.
  bool get isNotEmpty => _queue.isNotEmpty;

  /// Adds an element to the buffer.
  ///
  /// If the buffer is full, the oldest element is automatically removed
  /// before adding the new element (FIFO overflow behavior).
  ///
  /// **Performance**: O(1) operation.
  ///
  /// Example:
  /// ```dart
  /// final buffer = BufferManager<int>(maxSize: 3);
  /// buffer.add(1);  // [1]
  /// buffer.add(2);  // [1, 2]
  /// buffer.add(3);  // [1, 2, 3] - now full
  /// buffer.add(4);  // [2, 3, 4] - oldest (1) discarded
  /// ```
  void add(T element) {
    if (isFull) {
      // Buffer full - discard oldest element (FIFO overflow)
      _queue.removeFirst();
    }
    _queue.addLast(element);
  }

  /// Removes and returns all elements from the buffer in FIFO order.
  ///
  /// Returns a list containing all buffered elements in the order they were added.
  /// The buffer is empty after this operation.
  ///
  /// **Performance**: O(n) where n = number of buffered elements.
  ///
  /// Example:
  /// ```dart
  /// buffer.add(1);
  /// buffer.add(2);
  /// buffer.add(3);
  /// final all = buffer.removeAll();  // [1, 2, 3]
  /// print(buffer.isEmpty);           // true
  /// ```
  List<T> removeAll() {
    final result = _queue.toList();
    _queue.clear();
    return result;
  }

  /// Removes all elements from the buffer without returning them.
  ///
  /// More efficient than [removeAll] when you don't need the buffered elements.
  ///
  /// **Performance**: O(1) operation.
  ///
  /// Example:
  /// ```dart
  /// buffer.add(1);
  /// buffer.add(2);
  /// buffer.clear();
  /// print(buffer.isEmpty);  // true
  /// ```
  void clear() {
    _queue.clear();
  }

  /// Returns a read-only view of the buffer contents without removing them.
  ///
  /// Useful for inspecting the buffer state without modifying it.
  /// Returns elements in FIFO order (oldest first).
  ///
  /// **Performance**: O(n) where n = number of buffered elements.
  ///
  /// Example:
  /// ```dart
  /// buffer.add(1);
  /// buffer.add(2);
  /// final peek = buffer.toList();  // [1, 2]
  /// print(buffer.length);          // 2 (unchanged)
  /// ```
  List<T> toList() {
    return _queue.toList();
  }
}
