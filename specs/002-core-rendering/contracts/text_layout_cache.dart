// Contract: TextLayoutCache Interface
// Feature: 002-core-rendering
// Purpose: Define text layout caching contract for performance optimization
//
// Constitutional Compliance:
// - TDD: This contract must have failing tests BEFORE implementation
// - Performance: Cache hit MUST be <0.5ms, miss <5ms (FR-005)
// - Hit Rate: Target >70% for typical label-heavy charts (NFR-001)

import 'package:flutter/painting.dart';

/// Contract for caching pre-computed TextPainter layouts.
///
/// A [TextLayoutCache] memoizes text layout computation to avoid redundant
/// calls to TextPainter.layout(), which is expensive (>5ms for complex text).
/// Critical for label-heavy charts (axis labels, legends, annotations).
///
/// ## Contract Requirements
///
/// 1. **Cache Key**: Keys MUST uniquely identify text content + TextStyle
///    combination. Same text with different style = different cache entries.
///
/// 2. **Hit Performance**: Cache hits (key exists) MUST complete in <0.5ms
///    (FR-005 requirement). O(1) lookup expected.
///
/// 3. **Miss Performance**: Cache misses (key not found) MUST return null
///    in <0.5ms. Caller responsible for layout computation and [put].
///
/// 4. **Bounded Size**: Cache MUST enforce maximum entry count to prevent
///    unbounded memory growth. Default: 500 entries.
///
/// 5. **LRU Eviction**: When cache at capacity, oldest (least recently used)
///    entry MUST be evicted before inserting new entry.
///
/// 6. **Hit Rate Tracking**: Cache MUST track hit/miss counts for monitoring.
///    [hitRate] getter returns hits / (hits + misses).
///
/// 7. **Invalidation**: [clear] MUST remove all cached entries (e.g., on
///    theme change, global font scaling).
///
/// ## Example Usage
///
/// ```dart
/// final cache = TextLayoutCache(maxSize: 500);
/// final textStyle = TextStyle(fontSize: 14, color: Colors.black);
///
/// // First render (cache miss):
/// var painter = cache.get('Label 1', textStyle);
/// if (painter == null) {
///   painter = TextPainter(
///     text: TextSpan(text: 'Label 1', style: textStyle),
///     textDirection: TextDirection.ltr,
///   );
///   painter.layout();
///   cache.put('Label 1', textStyle, painter);
/// }
/// painter.paint(canvas, offset);
///
/// // Second render (cache hit):
/// painter = cache.get('Label 1', textStyle); // Fast lookup
/// assert(painter != null);
/// painter!.paint(canvas, offset);
/// ```
///
/// ## Testing Contract
///
/// Implementations MUST pass these contract tests:
///
/// 1. **Cache Miss**: get() for non-existent key returns null in <0.5ms.
///
/// 2. **Cache Hit**: put() then get() same key returns cached painter in <0.5ms.
///
/// 3. **Style Sensitivity**: put('text', style1, painter1), get('text', style2)
///    returns null if style1 != style2 (different styles = different keys).
///
/// 4. **LRU Eviction**: Fill cache to maxSize, add one more entry, verify
///    oldest entry evicted (first put() key now returns null).
///
/// 5. **Hit Rate Accuracy**: Execute 7 hits, 3 misses, verify hitRate == 0.7.
///
/// 6. **Clear Invalidation**: put() entries, clear(), verify all get()
///    return null.
///
/// 7. **Bounded Size**: Add maxSize + 100 entries, verify cache.length <= maxSize.
abstract class TextLayoutCache {
  /// Maximum number of cached layouts.
  ///
  /// Default: 500 entries. Typical chart with 50 bars + 10 legend items +
  /// 20 axis labels = ~80 unique labels. 500 provides 6x headroom.
  ///
  /// **Memory Impact**: Each TextPainter ~1KB, so 500 entries ≈ 500KB.
  /// Acceptable for in-memory cache.
  int get maxSize;

  /// Retrieve cached text layout for given text and style.
  ///
  /// Returns pre-computed [TextPainter] if cache hit, null if cache miss.
  ///
  /// **Cache Key**: Composite of text content and style hash. Same text with
  /// different style is different key:
  /// - get('Label', style1) vs get('Label', style2) are distinct lookups.
  ///
  /// **Performance**: MUST complete in <0.5ms for both hit and miss (FR-005).
  /// Expected O(1) map lookup.
  ///
  /// **LRU Update**: Cache hits SHOULD move entry to end (most recently used)
  /// for accurate LRU eviction. Implementation detail.
  ///
  /// **Null Return**: Null indicates cache miss. Caller computes layout and
  /// calls [put] to cache result.
  ///
  /// [text] - Text content to render (e.g., "Label 1", "100.5", "Q1 2023").
  /// [style] - TextStyle for rendering (font, size, color, etc.).
  ///
  /// Returns cached TextPainter if hit, null if miss.
  TextPainter? get(String text, TextStyle style);

  /// Store computed text layout in cache.
  ///
  /// Associates [painter] with composite key (text + style). If cache at
  /// capacity ([maxSize] entries), evicts least recently used entry before
  /// insertion.
  ///
  /// **Eviction**: When cache.length == maxSize, oldest entry MUST be removed
  /// before adding new entry. Implementation SHOULD use LinkedHashMap or
  /// similar structure that preserves insertion order for LRU.
  ///
  /// **Overwrite**: If key already exists (rare), overwrite old painter.
  /// No duplicate keys allowed.
  ///
  /// **Performance**: MUST complete in <1ms (map insertion + potential eviction).
  ///
  /// **Side Effects**: Increments internal miss counter (since put() only
  /// called after get() miss). Hit/miss tracking implementation detail.
  ///
  /// [text] - Text content (same as used in [get]).
  /// [style] - TextStyle (same as used in [get]).
  /// [painter] - Pre-computed TextPainter (already layout() called).
  void put(String text, TextStyle style, TextPainter painter);

  /// Remove all cached entries.
  ///
  /// Invalidates entire cache. Used when:
  /// - Theme change (all TextStyle instances potentially invalid)
  /// - Global font scaling change
  /// - Test cleanup (reset to known state)
  ///
  /// **Post-Condition**: After clear(), all [get] calls return null until
  /// new [put] calls populate cache.
  ///
  /// **Performance**: MUST complete in <5ms even for full cache (500 entries).
  /// Simple map.clear() expected.
  void clear();

  /// Cache hit rate (hits / total lookups).
  ///
  /// Returns value in range [0.0, 1.0]:
  /// - 1.0 = 100% hits (perfect cache, all lookups found)
  /// - 0.7 = 70% hits (target for label-heavy charts per FR-005)
  /// - 0.0 = 0% hits (cold cache, all misses)
  ///
  /// **Calculation**: hits / (hits + misses). If no lookups yet, returns 0.0.
  ///
  /// **Monitoring**: Exposed for performance validation and debugging.
  /// Persistent low hit rate (<70%) indicates cache ineffective (too small,
  /// or labels too diverse).
  ///
  /// **Performance**: MUST be O(1) (simple division of counters).
  double get hitRate;

  /// Current number of cached entries.
  ///
  /// Returns count of unique (text, style) pairs currently cached.
  /// Always satisfies: 0 <= length <= maxSize.
  ///
  /// **Monitoring**: Useful for debugging cache utilization. If length
  /// consistently < maxSize, cache is under-utilized (could reduce maxSize).
  /// If length == maxSize frequently, cache may be too small (increase maxSize).
  ///
  /// **Performance**: MUST be O(1) (map.length property).
  int get length;
}

/// Default implementation of [TextLayoutCache] using LinkedHashMap.
///
/// This is the production implementation. Uses LinkedHashMap to preserve
/// insertion order for LRU eviction, tracks hit/miss counts, enforces
/// bounded size.
///
/// **Constitutional Compliance**:
/// - Zero external dependencies (dart:collection LinkedHashMap)
/// - TDD: Tests written before this implementation
/// - Performance: <0.5ms hit, <5ms miss validated by benchmarks
///
/// NOT part of contract (implementation detail). Placed here for reference.
/// Actual implementation goes in lib/src/rendering/text_layout_cache.dart.
class LinkedHashMapTextLayoutCache implements TextLayoutCache {
  // Private fields (implementation detail):
  // - LinkedHashMap<String, TextPainter> _cache
  // - int _maxSize
  // - int _hitCount
  // - int _missCount

  @override
  int get maxSize => throw UnimplementedError('TDD: Test first');

  @override
  TextPainter? get(String text, TextStyle style) => throw UnimplementedError('TDD: Test first');

  @override
  void put(String text, TextStyle style, TextPainter painter) => throw UnimplementedError('TDD: Test first');

  @override
  void clear() => throw UnimplementedError('TDD: Test first');

  @override
  double get hitRate => throw UnimplementedError('TDD: Test first');

  @override
  int get length => throw UnimplementedError('TDD: Test first');
}

/// Contract test helper: Mock cache for testing layer behavior.
///
/// Allows tests to verify that layers correctly use cache (get before layout,
/// put after miss). NOT for production use.
class MockTextLayoutCache implements TextLayoutCache {
  final Map<String, TextPainter> _cache = {};
  int getCallCount = 0;
  int putCallCount = 0;
  int clearCallCount = 0;

  @override
  final int maxSize;

  MockTextLayoutCache({this.maxSize = 500});

  @override
  TextPainter? get(String text, TextStyle style) {
    getCallCount++;
    final key = '$text:${style.hashCode}';
    return _cache[key];
  }

  @override
  void put(String text, TextStyle style, TextPainter painter) {
    putCallCount++;
    final key = '$text:${style.hashCode}';
    _cache[key] = painter;
  }

  @override
  void clear() {
    clearCallCount++;
    _cache.clear();
  }

  @override
  double get hitRate {
    if (getCallCount == 0) return 0.0;
    final hits = getCallCount - putCallCount; // Approx (put follows miss)
    return hits / getCallCount;
  }

  @override
  int get length => _cache.length;
}
