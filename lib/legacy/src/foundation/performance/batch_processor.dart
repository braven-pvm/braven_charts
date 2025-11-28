// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

/// Groups similar operations for rendering efficiency.
///
/// BatchProcessor<T, K> groups items by a common key to minimize state changes
/// during rendering. This is useful for batching paint operations by color,
/// grouping shapes by style, or organizing text by font.
///
/// Example:
/// ```dart
/// final processor = BatchProcessor<Shape, Color>(
///   keyExtractor: (shape) => shape.color,
///   batchSize: 100,
/// );
///
/// final batches = processor.batch(allShapes);
/// batches.forEach((color, shapes) {
///   setColor(color); // Single state change
///   drawShapes(shapes); // Batch rendering
/// });
/// ```
class BatchProcessor<T, K> {
  /// Function to extract the grouping key from an item
  final K Function(T) _keyExtractor;

  /// Maximum batch size for processing
  final int batchSize;

  /// Creates a batch processor with specified key extractor.
  ///
  /// [keyExtractor]: Function to extract the grouping key from each item
  /// [batchSize]: Maximum items per batch (default: 100)
  BatchProcessor({
    required K Function(T) keyExtractor,
    this.batchSize = 100,
  })  : _keyExtractor = keyExtractor,
        assert(batchSize > 0, 'batchSize must be greater than 0');

  /// Groups items by extracted key.
  ///
  /// Returns a map where:
  /// - Key: The extracted key value (e.g., color, style, font)
  /// - Value: List of all items with that key
  ///
  /// Use cases:
  /// - Group points by color for Paint reuse
  /// - Group shapes by fill style
  /// - Group text by font
  ///
  /// Example:
  /// ```dart
  /// final batches = processor.batch([
  ///   Point(1, 2, color: red),
  ///   Point(3, 4, color: blue),
  ///   Point(5, 6, color: red),
  /// ]);
  /// // Result: {red: [Point(1,2), Point(5,6)], blue: [Point(3,4)]}
  /// ```
  Map<K, List<T>> batch(List<T> items) {
    final batches = <K, List<T>>{};

    for (final item in items) {
      final key = _keyExtractor(item);
      batches.putIfAbsent(key, () => <T>[]).add(item);
    }

    return batches;
  }

  /// Processes items in batches with a callback function.
  ///
  /// Groups items by key and calls the processor function for each batch.
  /// This is useful for immediate processing without storing all batches.
  ///
  /// [items]: Items to process
  /// [processor]: Function called for each (key, batch) pair
  ///
  /// Example:
  /// ```dart
  /// processor.processBatches(shapes, (color, batch) {
  ///   canvas.setFillColor(color);
  ///   for (final shape in batch) {
  ///     canvas.drawShape(shape);
  ///   }
  /// });
  /// ```
  void processBatches(
    List<T> items,
    void Function(K key, List<T> batch) processor,
  ) {
    final batches = batch(items);
    batches.forEach(processor);
  }

  @override
  String toString() => 'BatchProcessor<$T, $K>(batchSize: $batchSize)';
}
