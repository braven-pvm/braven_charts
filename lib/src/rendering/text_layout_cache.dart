// Implementation: TextLayoutCache
// Feature: 002-core-rendering
// Purpose: LRU cache for TextPainter layouts
//
// TDD Phase: GREEN - Making contract tests pass
//
// Constitutional Compliance:
// - Zero dependencies: dart:collection LinkedHashMap only
// - Performance: <0.5ms hit, <1ms put per contract
// - Memory bounded: LRU eviction at maxSize

import 'dart:collection';

import 'package:flutter/painting.dart';

/// Contract for caching pre-computed TextPainter layouts.
///
/// See contract documentation in specs/002-core-rendering/contracts/text_layout_cache.dart
abstract class TextLayoutCache {
  /// Maximum number of cached layouts.
  int get maxSize;

  /// Retrieve cached text layout for given text and style.
  TextPainter? get(String text, TextStyle style);

  /// Store computed text layout in cache.
  void put(String text, TextStyle style, TextPainter painter);

  /// Remove all cached entries.
  void clear();

  /// Cache hit rate (hits / total lookups).
  double get hitRate;

  /// Current number of cached entries.
  int get length;
}

/// LRU cache implementation using LinkedHashMap.
///
/// Provides O(1) cache hits/misses, automatic LRU eviction when at capacity,
/// and hit/miss rate tracking for performance monitoring.
///
/// ## Usage
///
/// ```dart
/// final cache = LinkedHashMapTextLayoutCache(maxSize: 500);
/// final style = TextStyle(fontSize: 14, color: Colors.black);
///
/// // First render (miss)
/// var painter = cache.get('Label', style);
/// if (painter == null) {
///   painter = TextPainter(
///     text: TextSpan(text: 'Label', style: style),
///     textDirection: TextDirection.ltr,
///   );
///   painter.layout();
///   cache.put('Label', style, painter);
/// }
/// painter.paint(canvas, offset);
///
/// // Second render (hit)
/// painter = cache.get('Label', style); // Fast O(1) lookup
/// painter!.paint(canvas, offset);
/// ```
///
/// ## Performance
///
/// - **get()**: <0.5ms (O(1) map lookup)
/// - **put()**: <1ms (O(1) map insertion + potential eviction)
/// - **Target hit rate**: >70% for label-heavy charts
///
/// ## Memory
///
/// - Each TextPainter ~1KB
/// - Default maxSize=500 → ~500KB max memory
/// - LRU eviction prevents unbounded growth
class LinkedHashMapTextLayoutCache implements TextLayoutCache {
  final LinkedHashMap<String, TextPainter> _cache;
  final int _maxSize;
  int _hitCount = 0;
  int _missCount = 0;

  /// Create text layout cache with specified maximum size.
  ///
  /// [maxSize] defaults to 500 entries (~500KB memory).
  /// Larger values provide better hit rates but consume more memory.
  /// Smaller values reduce memory but may cause cache thrashing.
  ///
  /// **Typical sizing**:
  /// - Simple chart (20 labels): maxSize=50
  /// - Complex chart (100 labels): maxSize=200
  /// - Dashboard (multiple charts): maxSize=500+
  LinkedHashMapTextLayoutCache({int maxSize = 500})
      : _maxSize = maxSize,
        _cache = LinkedHashMap<String, TextPainter>() {
    assert(maxSize > 0, 'maxSize must be greater than 0');
  }

  @override
  int get maxSize => _maxSize;

  @override
  TextPainter? get(String text, TextStyle style) {
    final key = _makeCacheKey(text, style);
    final painter = _cache[key];

    if (painter != null) {
      _hitCount++;

      // Move to end (most recently used) for accurate LRU
      _cache.remove(key);
      _cache[key] = painter;

      return painter;
    } else {
      _missCount++;
      return null;
    }
  }

  @override
  void put(String text, TextStyle style, TextPainter painter) {
    final key = _makeCacheKey(text, style);

    // If key exists, remove it first (will re-add at end)
    if (_cache.containsKey(key)) {
      _cache.remove(key);
    }

    // Evict oldest entry if at capacity
    if (_cache.length >= _maxSize) {
      // LinkedHashMap maintains insertion order
      // First key is oldest (least recently used)
      final oldestKey = _cache.keys.first;
      _cache.remove(oldestKey);
    }

    // Add new entry (goes to end - most recently used)
    _cache[key] = painter;
  }

  @override
  void clear() {
    _cache.clear();
    _hitCount = 0;
    _missCount = 0;
  }

  @override
  double get hitRate {
    final totalLookups = _hitCount + _missCount;
    if (totalLookups == 0) {
      return 0.0;
    }
    return _hitCount / totalLookups;
  }

  @override
  int get length => _cache.length;

  /// Generate unique cache key from text content and style.
  ///
  /// Key format: "text:styleHashCode"
  ///
  /// Same text with different styles produces different keys:
  /// - "Label" with fontSize=14 → "Label:12345"
  /// - "Label" with fontSize=16 → "Label:67890"
  ///
  /// TextStyle.hashCode includes all style properties (font, size, color, etc.),
  /// so any style difference produces different hash.
  String _makeCacheKey(String text, TextStyle style) {
    return '$text:${style.hashCode}';
  }

  @override
  String toString() {
    return 'LinkedHashMapTextLayoutCache('
        'size: $length/$maxSize, '
        'hitRate: ${(hitRate * 100).toStringAsFixed(1)}%, '
        'hits: $_hitCount, '
        'misses: $_missCount)';
  }
}
