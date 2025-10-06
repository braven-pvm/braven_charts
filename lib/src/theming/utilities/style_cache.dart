// StyleCache Implementation
// Feature: 004-theming-system
// Phase 4: Utilities (T031)

import 'dart:collection';

/// Key for caching resolved styles.
///
/// Combines theme hash, element type, and optional overrides hash to create
/// a unique cache key for style lookup.
///
/// Example:
/// ```dart
/// final key = StyleCacheKey(
///   themeHash: theme.hashCode,
///   elementType: 'axis',
///   overridesHash: overrides?.hashCode,
/// );
/// ```
class StyleCacheKey {
  /// Creates a cache key.
  ///
  /// - [themeHash]: Hash code of the theme
  /// - [elementType]: Type of chart element ('axis', 'grid', 'series', etc.)
  /// - [overridesHash]: Optional hash of style overrides
  const StyleCacheKey({
    required this.themeHash,
    required this.elementType,
    this.overridesHash,
  });

  /// Hash code of the theme being used.
  final int themeHash;

  /// Type of chart element being styled.
  ///
  /// Examples: 'axis', 'grid', 'series', 'legend', 'tooltip'
  final String elementType;

  /// Optional hash code of style overrides.
  ///
  /// Null if no overrides are applied.
  final int? overridesHash;

  @override
  int get hashCode => Object.hash(themeHash, elementType, overridesHash);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StyleCacheKey &&
          runtimeType == other.runtimeType &&
          themeHash == other.themeHash &&
          elementType == other.elementType &&
          overridesHash == other.overridesHash;

  @override
  String toString() => 'StyleCacheKey(themeHash: $themeHash, elementType: $elementType, overridesHash: $overridesHash)';
}

/// LRU cache for resolved chart styles.
///
/// Caches computed styles to avoid redundant calculations during rendering.
/// Uses Least Recently Used (LRU) eviction policy with a maximum size limit.
///
/// ## Performance Characteristics
///
/// - **Lookup**: O(1) average case
/// - **Insertion**: O(1) average case
/// - **Eviction**: O(1) when cache is full
/// - **Memory**: Bounded to [maxSize] entries
///
/// ## Usage
///
/// ```dart
/// final cache = StyleCache();
///
/// // Try to get cached style
/// final style = cache.get<TextStyle>(key);
///
/// if (style == null) {
///   // Cache miss - compute style
///   final computed = computeStyle();
///   cache.put(key, computed);
/// }
///
/// // Check cache performance
/// print('Hit rate: ${cache.hitRate.toStringAsFixed(2)}');
/// print('Cache size: ${cache.size}');
/// ```
class StyleCache {
  /// Maximum number of entries in the cache.
  ///
  /// When this limit is exceeded, the least recently used entry is evicted.
  ///
  /// **Sizing rationale**:
  /// - Typical chart has 10 chart elements (grid, axes, title, etc.)
  /// - 5-10 series with individual styles
  /// - 10 style variations per element
  /// - Total: ~100-200 active entries
  /// - 1000 provides 5-10x headroom for safety
  static const int maxSize = 1000;

  /// Internal cache storage using LinkedHashMap for LRU ordering.
  ///
  /// LinkedHashMap maintains insertion order, which we use for LRU:
  /// - First entry = least recently used (oldest)
  /// - Last entry = most recently used (newest)
  final LinkedHashMap<StyleCacheKey, dynamic> _cache = LinkedHashMap();

  /// Number of cache hits (successful lookups).
  int _hits = 0;

  /// Number of cache misses (unsuccessful lookups).
  int _misses = 0;

  /// Retrieves a cached style.
  ///
  /// Returns the cached value if found, or null if not found.
  /// On cache hit, moves the entry to the end (marks as most recently used).
  ///
  /// Example:
  /// ```dart
  /// final style = cache.get<TextStyle>(key);
  /// if (style != null) {
  ///   // Use cached style
  /// }
  /// ```
  T? get<T>(StyleCacheKey key) {
    final value = _cache.remove(key);
    if (value != null) {
      _cache[key] = value; // Move to end (most recently used)
      _hits++;
      return value as T;
    }
    _misses++;
    return null;
  }

  /// Stores a style in the cache.
  ///
  /// If the key already exists, updates the value and moves to end.
  /// If cache is full, evicts the least recently used entry.
  ///
  /// Example:
  /// ```dart
  /// cache.put(key, computedStyle);
  /// ```
  void put<T>(StyleCacheKey key, T value) {
    _cache.remove(key); // Remove if exists (to update position)
    _cache[key] = value; // Insert at end

    // LRU eviction
    if (_cache.length > maxSize) {
      _cache.remove(_cache.keys.first); // Evict oldest (first entry)
    }
  }

  /// Clears all cached entries.
  ///
  /// Typically called when the theme changes to invalidate all cached styles.
  ///
  /// Example:
  /// ```dart
  /// // Theme changed, invalidate cache
  /// cache.clear();
  /// ```
  void clear() {
    _cache.clear();
    _hits = 0;
    _misses = 0;
  }

  /// Returns the cache hit rate as a ratio between 0.0 and 1.0.
  ///
  /// Hit rate = hits / (hits + misses)
  ///
  /// - 1.0 = perfect hit rate (all lookups succeeded)
  /// - 0.0 = zero hit rate (all lookups missed)
  ///
  /// Returns 0.0 if no lookups have been performed yet.
  ///
  /// Example:
  /// ```dart
  /// if (cache.hitRate < 0.8) {
  ///   print('Warning: Low cache hit rate');
  /// }
  /// ```
  double get hitRate {
    final total = _hits + _misses;
    if (total == 0) return 0.0;
    return _hits / total;
  }

  /// Returns the current number of entries in the cache.
  ///
  /// Example:
  /// ```dart
  /// print('Cache is ${cache.size}/${StyleCache.maxSize} full');
  /// ```
  int get size => _cache.length;

  /// Returns the number of cache hits since last clear.
  int get hits => _hits;

  /// Returns the number of cache misses since last clear.
  int get misses => _misses;

  /// Returns whether the cache is full (at maximum size).
  bool get isFull => _cache.length >= maxSize;

  /// Returns whether the cache is empty.
  bool get isEmpty => _cache.isEmpty;

  /// Returns whether the cache contains an entry for the given key.
  ///
  /// Note: This does NOT count as a hit or miss for hit rate calculation.
  ///
  /// Example:
  /// ```dart
  /// if (cache.containsKey(key)) {
  ///   // Entry exists
  /// }
  /// ```
  bool containsKey(StyleCacheKey key) => _cache.containsKey(key);
}
