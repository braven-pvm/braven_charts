# Phase 0: Research & Technical Decisions

**Feature**: Core Rendering Engine  
**Date**: 2025-10-05  
**Status**: Complete

---

## Technical Context Analysis

### Resolved Questions

All technical context is clear from specification - NO NEEDS CLARIFICATION markers present.

**Language**: Dart 3.0+ (Dart 3.10.0-227.0.dev)  
**Framework**: Flutter SDK 3.37.0-1.0.pre-216  
**Dependencies**: Foundation Layer (ObjectPool<T>, ViewportCuller, ChartDataPoint, ChartResult<T>)  
**Testing**: flutter test, benchmark_harness, visual validation  
**Target**: Flutter Web (primary), cross-platform (secondary)

**From User Input**: Foundation Layer is fully implemented and available:
- ObjectPool<T>: Generic object pooling with acquire/release
- ViewportCuller: Efficient point culling using binary search
- ChartDataPoint: Immutable data representation
- ChartResult<T>: Error handling wrapper
- All performance targets exceeded (see Foundation completion reports)

---

## Key Technical Decisions

### Decision 1: Object Pool Types and Strategy

**Decision**: Create specialized pools for Paint, Path, and TextPainter using Foundation's ObjectPool<T> with factory and reset functions.

**Rationale**:
- **Foundation Reuse**: ObjectPool<T> already proven (930+ tests, >90% hit rate achieved)
- **Type Safety**: Generic pool eliminates casting, compile-time verification
- **Performance**: Foundation pool achieves O(1) acquire/release, >90% hit rate
- **Zero Allocation**: Pool eliminates per-frame allocation (GC pressure <1 collection/second target)
- **Monitoring**: Pool exposes statistics for performance tracking (FR-004 requirement)

**Implementation Pattern**:
```dart
// Specialized pools using Foundation ObjectPool<T>
final paintPool = ObjectPool<Paint>(
  factory: () => Paint(),
  reset: (paint) {
    paint.color = Colors.black;
    paint.strokeWidth = 1.0;
    paint.style = PaintingStyle.fill;
    // Reset all properties to defaults
  },
  maxSize: 100, // Dynamic sizing based on usage
);

final pathPool = ObjectPool<Path>(
  factory: () => Path(),
  reset: (path) => path.reset(),
  maxSize: 50,
);

final textPainterPool = ObjectPool<TextPainter>(
  factory: () => TextPainter(
    textDirection: TextDirection.ltr,
  ),
  reset: (painter) {
    painter.text = null;
    // Clear cached layouts
  },
  maxSize: 20,
);
```

**Alternatives Considered**:
- **Single pool for all types**: Rejected - loses type safety, complicates reset logic
- **Manual pooling without foundation**: Rejected - reinvents tested wheel, violates KISS
- **No pooling (allocate per frame)**: Rejected - violates NFR-001 (<1 GC/second), causes jank

**Foundation Integration**:
- Import: `import 'package:braven_charts/src/foundation/object_pool.dart';`
- Contract: Follows ObjectPool<T> interface from Foundation
- Testing: Reuse ObjectPool contract tests with Paint/Path/TextPainter

---

### Decision 2: Layer-Based Rendering Pipeline Architecture

**Decision**: Implement composable RenderLayer abstract class with RenderPipeline orchestrator managing z-ordered execution.

**Rationale**:
- **Modularity**: Each layer encapsulates rendering logic (data, grid, annotations independent)
- **Performance**: Empty layer short-circuit (<0.1ms overhead per spec §FR-002)
- **Maintainability**: New layer types added without modifying pipeline (Open-Closed principle)
- **Testability**: Layers test in isolation, pipeline tests layer orchestration
- **Z-Ordering**: Simple sort by zIndex, render low-to-high guarantees correct depth

**Implementation Pattern**:
```dart
// Abstract base class (contract)
abstract class RenderLayer {
  final int zIndex;
  bool isVisible;
  
  const RenderLayer({required this.zIndex, this.isVisible = true});
  
  // Abstract method implemented by concrete layers
  void render(RenderContext context);
  
  // Optional: Check if layer has visible elements
  bool get isEmpty => false;
}

// Orchestrator
class RenderPipeline {
  final List<RenderLayer> _layers = [];
  final RenderContext _context;
  final PerformanceMonitor _monitor;
  
  void renderFrame(Canvas canvas, Size size) {
    _monitor.beginFrame();
    
    // Sort layers by zIndex (low to high)
    final sortedLayers = _layers.where((l) => l.isVisible).toList()
      ..sort((a, b) => a.zIndex.compareTo(b.zIndex));
    
    // Render each visible layer
    for (final layer in sortedLayers) {
      if (layer.isEmpty) continue; // Skip empty layers (<0.1ms)
      layer.render(_context);
    }
    
    _monitor.endFrame();
  }
  
  void addLayer(RenderLayer layer) { /* ... */ }
  void removeLayer(RenderLayer layer) { /* ... */ }
}
```

**Alternatives Considered**:
- **Flat rendering (no layers)**: Rejected - violates modularity, can't toggle visibility
- **Scene graph with tree structure**: Rejected - over-engineered for chart rendering, KISS violation
- **Priority queue for z-order**: Rejected - simple sort sufficient for <100 layers, premature optimization

**Flutter Integration**:
- Follows CustomPainter pattern (render method with Canvas)
- Compatible with RepaintBoundary for layer-level optimization
- Integrates with Foundation ViewportCuller for per-layer culling

---

### Decision 3: Viewport Culling Integration with Foundation

**Decision**: Reuse Foundation ViewportCuller for point-based culling, extend with RenderContext for layer access.

**Rationale**:
- **Foundation Reuse**: ViewportCuller proven (<3ms for 10K points per Foundation tests)
- **Binary Search**: O(log n) x-axis culling already implemented and optimized
- **Consistency**: Same culling algorithm across all chart components
- **Testability**: Foundation has comprehensive culling tests (edge cases, performance)
- **Integration**: RenderContext holds viewport bounds, layers call culler

**Implementation Pattern**:
```dart
class RenderContext {
  final Canvas canvas;
  final Size size;
  final Rect viewport; // Current visible bounds
  final ViewportCuller culler; // From Foundation
  final ObjectPool<Paint> paintPool;
  final ObjectPool<Path> pathPool;
  final ObjectPool<TextPainter> textPainterPool;
  final PerformanceMonitor performanceMonitor;
  
  // Layers use context for culling
  List<ChartDataPoint> cullPoints(List<ChartDataPoint> points) {
    return culler.cullPoints(points, viewport);
  }
}

// Example layer using culling
class DataSeriesLayer extends RenderLayer {
  final List<ChartDataPoint> allPoints;
  
  @override
  void render(RenderContext context) {
    // Cull to visible points only
    final visiblePoints = context.cullPoints(allPoints);
    
    // Render only visible points (80%+ reduction per spec)
    for (final point in visiblePoints) {
      // Draw point using context.paintPool.acquire()
    }
  }
}
```

**Alternatives Considered**:
- **Custom culling per layer**: Rejected - duplicates Foundation work, inconsistent performance
- **No culling (render all)**: Rejected - violates NFR-001 (can't achieve <8ms with 10K points)
- **GPU-based culling**: Rejected - Flutter web limitations, not needed for 10K scale

**Foundation Dependency**:
- Import: `import 'package:braven_charts/src/foundation/viewport_culler.dart';`
- Contract: Follows ViewportCuller.cullPoints interface
- Testing: Leverage Foundation culling tests for integration validation

---

### Decision 4: Performance Monitoring Strategy

**Decision**: Implement PerformanceMonitor using dart:core Stopwatch for microsecond-precision frame timing with per-frame metrics collection.

**Rationale**:
- **Accuracy**: Stopwatch provides microsecond precision (±0.5ms per spec §FR-004)
- **Low Overhead**: Simple start/stop operations (<1ms per frame per spec)
- **Stdlib Only**: No external packages (constitution compliance)
- **Real-time**: Metrics available immediately after frame for debugging
- **Jank Detection**: Compare frame time to 16ms threshold (60fps)

**Implementation Pattern**:
```dart
class PerformanceMonitor {
  final Stopwatch _stopwatch = Stopwatch();
  final List<Duration> _frameTimes = [];
  int _jankCount = 0;
  
  void beginFrame() {
    _stopwatch.reset();
    _stopwatch.start();
  }
  
  void endFrame() {
    _stopwatch.stop();
    final frameTime = _stopwatch.elapsed;
    _frameTimes.add(frameTime);
    
    // Jank detection (>16ms threshold)
    if (frameTime.inMicroseconds > 16000) {
      _jankCount++;
    }
  }
  
  PerformanceMetrics get currentMetrics => PerformanceMetrics(
    frameTime: _frameTimes.last,
    averageFrameTime: _calculateAverage(),
    p99FrameTime: _calculateP99(),
    jankCount: _jankCount,
    poolHitRate: _calculatePoolHitRate(),
  );
}

class PerformanceMetrics {
  final Duration frameTime;
  final Duration averageFrameTime;
  final Duration p99FrameTime;
  final int jankCount;
  final double poolHitRate;
  
  const PerformanceMetrics({...});
  
  bool get meetsTargets =>
    averageFrameTime.inMicroseconds < 8000 && // <8ms avg
    p99FrameTime.inMicroseconds < 16000 &&    // <16ms p99
    poolHitRate > 0.90;                        // >90% hit rate
}
```

**Alternatives Considered**:
- **Timeline package**: Rejected - external dependency, constitution violation
- **Flutter DevTools only**: Rejected - need programmatic access for tests
- **Manual DateTime**: Rejected - millisecond precision insufficient (need microseconds)

**Testing Strategy**:
- Unit tests: Verify jank detection accuracy (16ms threshold)
- Integration tests: Validate <1ms monitoring overhead
- Performance tests: Ensure metrics collection doesn't affect frame time

---

### Decision 5: Text Layout Cache Design

**Decision**: Implement simple Map<String, TextPainter> cache with LRU eviction and composite key "text:styleHash".

**Rationale**:
- **Simplicity**: Plain Map sufficient for 500-entry cache (KISS principle)
- **Performance**: Map lookups O(1), cache hit <0.5ms (spec §FR-005)
- **LRU Eviction**: LinkedHashMap preserves insertion order for simple LRU
- **Style Sensitivity**: Hash TextStyle to detect style changes (font, size, color)
- **Bounded Size**: 500 entries prevent unbounded growth (memory safety)

**Implementation Pattern**:
```dart
class TextLayoutCache {
  final LinkedHashMap<String, TextPainter> _cache = LinkedHashMap();
  final int maxSize;
  int _hitCount = 0;
  int _missCount = 0;
  
  TextLayoutCache({this.maxSize = 500});
  
  TextPainter? get(String text, TextStyle style) {
    final key = _makeCacheKey(text, style);
    final cached = _cache[key];
    
    if (cached != null) {
      _hitCount++;
      // Move to end (most recently used)
      _cache.remove(key);
      _cache[key] = cached;
      return cached;
    }
    
    _missCount++;
    return null;
  }
  
  void put(String text, TextStyle style, TextPainter painter) {
    final key = _makeCacheKey(text, style);
    
    // Evict oldest entry if at capacity
    if (_cache.length >= maxSize) {
      _cache.remove(_cache.keys.first); // LRU eviction
    }
    
    _cache[key] = painter;
  }
  
  String _makeCacheKey(String text, TextStyle style) {
    // Composite key: text content + style hash
    return '$text:${style.hashCode}';
  }
  
  double get hitRate => _hitCount / (_hitCount + _missCount);
}
```

**Alternatives Considered**:
- **LRU package (lru_cache)**: Rejected - external dependency, constitution violation
- **Full text layout re-computation**: Rejected - >5ms per label, fails NFR-001
- **Unbounded cache**: Rejected - memory leak risk, not production-ready
- **Custom LRU linked list**: Rejected - LinkedHashMap simpler, KISS

**Cache Invalidation**:
- Style changes detected via hashCode comparison
- Pan/zoom don't invalidate (text content/style unchanged)
- Manual invalidation API for dynamic text updates

---

### Decision 6: RenderContext Design Pattern

**Decision**: Immutable value object passed to layers containing canvas, viewport, pools, and monitors.

**Rationale**:
- **Dependency Injection**: Layers receive dependencies via parameter (testability)
- **Immutability**: Context recreated per frame, prevents stale state
- **Single Responsibility**: Context groups rendering resources, doesn't render
- **Foundation Pattern**: Follows ChartDataPoint immutability from Foundation
- **Testability**: Mock RenderContext for layer unit tests

**Implementation Pattern**:
```dart
class RenderContext {
  final Canvas canvas;
  final Size size;
  final Rect viewport;
  final ViewportCuller culler;
  final ObjectPool<Paint> paintPool;
  final ObjectPool<Path> pathPool;
  final ObjectPool<TextPainter> textPainterPool;
  final TextLayoutCache textCache;
  final PerformanceMonitor performanceMonitor;
  
  const RenderContext({
    required this.canvas,
    required this.size,
    required this.viewport,
    required this.culler,
    required this.paintPool,
    required this.pathPool,
    required this.textPainterPool,
    required this.textCache,
    required this.performanceMonitor,
  });
  
  // Convenience methods for common operations
  Paint acquirePaint() => paintPool.acquire();
  void releasePaint(Paint paint) => paintPool.release(paint);
  
  Path acquirePath() => pathPool.acquire();
  void releasePath(Path path) => pathPool.release(path);
}
```

**Alternatives Considered**:
- **Mutable context (singleton)**: Rejected - thread safety issues, violates Foundation immutability pattern
- **Global pools**: Rejected - tight coupling, untestable, anti-pattern
- **Builder pattern**: Rejected - over-engineered, KISS violation

**Testing Benefits**:
- Mock context for layer tests (no real Canvas needed)
- Verify pool acquire/release calls
- Validate viewport culling integration

---

## Architecture Decision Records (ADRs)

### ADR-001: Why Object Pooling Over Allocate-Per-Frame

**Context**: Flutter rendering can allocate hundreds of Paint/Path objects per frame, causing GC pressure and jank.

**Decision**: Use ObjectPool<T> from Foundation for all canvas primitives.

**Consequences**:
- ✅ Eliminates per-frame allocation (zero GC during steady-state)
- ✅ Achieves >90% pool hit rate (Foundation proven)
- ✅ Meets <8ms frame time target (NFR-001)
- ⚠️ Requires careful reset logic (must clear all properties)
- ⚠️ Pool sizing tuning needed (monitor hit rate, adjust maxSize)

**Status**: Accepted (required for NFR-001 compliance)

---

### ADR-002: Why Layer-Based Pipeline Over Flat Rendering

**Context**: Charts have multiple visual elements (data, grid, annotations) with different z-ordering and visibility requirements.

**Decision**: Implement RenderLayer abstraction with RenderPipeline orchestrator.

**Consequences**:
- ✅ Modularity: Add/remove layers independently
- ✅ Performance: Skip empty/invisible layers (<0.1ms overhead)
- ✅ Maintainability: New layer types extend base class (Open-Closed)
- ✅ Testability: Layers test in isolation
- ⚠️ Complexity: Two abstractions (Layer + Pipeline) vs one
- ⚠️ Sorting overhead: O(n log n) for n layers (negligible for <100 layers)

**Status**: Accepted (enables modularity without performance cost)

---

### ADR-003: Why Reuse Foundation ViewportCuller

**Context**: Viewport culling is critical for large dataset performance (10K+ points).

**Decision**: Reuse Foundation's ViewportCuller via RenderContext.

**Consequences**:
- ✅ Proven performance: <3ms for 10K points (Foundation tests)
- ✅ Consistency: Same culling across all chart components
- ✅ KISS: No reimplementation, reuse tested code
- ✅ Maintainability: Single culling algorithm to optimize
- ⚠️ Foundation dependency (acceptable - same feature tree)

**Status**: Accepted (DRY principle, Foundation dependency intended)

---

### ADR-004: Why Simple Map Cache Over LRU Library

**Context**: Text layout computation is expensive (>5ms per label), caching required for label-heavy charts.

**Decision**: Use LinkedHashMap with manual LRU eviction over external LRU package.

**Consequences**:
- ✅ Zero external dependencies (constitution compliance)
- ✅ Simple implementation (KISS)
- ✅ Sufficient performance: O(1) lookups, <0.5ms hit latency
- ⚠️ Manual LRU logic (10 lines, low complexity)
- ⚠️ No advanced features (e.g., TTL, weighted eviction) - not needed

**Status**: Accepted (KISS trumps feature richness for this use case)

---

## Implementation Risks & Mitigations

### Risk 1: Pool Exhaustion Under Load

**Risk**: Object pools run out of available objects, forcing allocation and violating zero-GC goal.

**Probability**: Medium (depends on dataset size and layer count)

**Impact**: High (causes jank, fails NFR-001)

**Mitigation**:
1. **Dynamic Pool Sizing**: Monitor hit rate, grow maxSize if hit rate <90%
2. **Performance Tests**: Benchmark worst-case scenarios (10K points, 10 layers)
3. **Pool Statistics**: Expose metrics for debugging (FR-004 monitoring)
4. **Conservative Defaults**: Start with larger pools (Paint=100, Path=50)

**Test Coverage**:
- Integration test: Render 10K points with minimal pools, verify no allocation
- Performance test: Measure pool hit rate under stress
- Contract test: Verify pool grow() method (if implemented)

---

### Risk 2: Text Cache Miss Rate Too High

**Risk**: Text cache hit rate <70%, causing excessive layout computation and violating frame time budget.

**Probability**: Low (chart labels typically repeat: axis values, legend)

**Impact**: Medium (increases frame time but layers render independently)

**Mitigation**:
1. **Cache Size Tuning**: 500 entries should cover most charts (50 bars × 10 labels)
2. **Style Hash Stability**: Ensure TextStyle.hashCode consistent (Dart guarantee)
3. **Precomputation**: Pre-populate cache for known labels (axis ticks)
4. **Monitoring**: Track hit/miss counts (FR-004), alert if <70%

**Test Coverage**:
- Unit test: Verify cache hit/miss tracking accuracy
- Integration test: Text-heavy scenario (Scenario 4), assert >70% hit rate
- Performance test: Measure cache overhead (<0.5ms hit, <5ms miss)

---

### Risk 3: Layer Sorting Overhead

**Risk**: Sorting layers by zIndex every frame causes performance degradation.

**Probability**: Very Low (<100 layers typical, O(n log n) negligible)

**Impact**: Low (sorting 100 items <0.1ms)

**Mitigation**:
1. **Lazy Sorting**: Only sort when layers added/removed, cache sorted list
2. **Insertion Sort**: If layers rarely change, insertion sort on add is O(n)
3. **Pre-sorted Maintenance**: Keep list sorted, binary search insert position

**Test Coverage**:
- Performance test: Benchmark sorting overhead for 100 layers (<1ms)
- Unit test: Verify sort stability (layers with same zIndex preserve order)

---

## Foundation Layer Integration Points

### Available from Foundation (001-foundation)

**Verified Complete** (user provided "foundation is implemented and detail is attached"):

1. **ObjectPool<T>** (`lib/src/foundation/object_pool.dart`)
   - Generic type-safe pooling
   - acquire() / release() methods
   - PoolStatistics exposure
   - Dynamic sizing support
   - 930+ tests, >90% hit rate achieved

2. **ViewportCuller** (`lib/src/foundation/viewport_culler.dart`)
   - Binary search x-axis culling
   - cullPoints(points, viewport) method
   - <3ms for 10K points performance
   - Comprehensive edge case tests

3. **ChartDataPoint** (`lib/src/foundation/data_models.dart`)
   - Immutable data representation
   - x, y, timestamp, label fields
   - Equality and hashCode implemented

4. **ChartResult<T>** (`lib/src/foundation/type_system.dart`)
   - Error handling wrapper
   - Success/Failure cases
   - Validation utilities

### Integration Strategy

**Import Pattern**:
```dart
// Core Rendering imports Foundation
import 'package:braven_charts/src/foundation/object_pool.dart';
import 'package:braven_charts/src/foundation/viewport_culler.dart';
import 'package:braven_charts/src/foundation/data_models.dart';
import 'package:braven_charts/src/foundation/type_system.dart';
```

**Dependency Flow**:
```
Core Rendering (002-core-rendering)
└── Foundation (001-foundation)
    └── Dart stdlib only
```

**Testing Strategy**:
- Core Rendering tests import Foundation contracts
- Reuse Foundation ObjectPool tests for Paint/Path/TextPainter pools
- Integrate Foundation ViewportCuller in rendering pipeline tests
- No circular dependencies (Core Rendering never imported by Foundation)

---

## Performance Validation Strategy

### Benchmarks Required

1. **Frame Time Benchmark** (NFR-001)
   - Dataset: 10,000 ChartDataPoint instances
   - Layers: 3 layers (data, grid, annotations)
   - Actions: Pan 100px, zoom 2x, pan back
   - Target: <8ms avg, <16ms p99
   - Tool: benchmark_harness

2. **Pool Hit Rate Benchmark** (FR-001)
   - Render 1000 frames with 10K points
   - Measure: Paint/Path/TextPainter pool statistics
   - Target: >90% hit rate for all pools
   - Tool: PoolStatistics from Foundation

3. **Viewport Culling Benchmark** (FR-003)
   - Dataset: 10,000 points, viewport shows 500
   - Measure: Culling latency, rendered element count
   - Target: <3ms culling, 500/10000 rendered (95% reduction)
   - Tool: Stopwatch + element counters

4. **Text Cache Benchmark** (FR-005)
   - Chart: 50 bars with labels, 10-item legend
   - Frames: 100 frames (simulate pan)
   - Measure: Cache hit/miss counts
   - Target: >70% hit rate
   - Tool: TextLayoutCache.hitRate

### Performance Gates

All benchmarks must pass before merge:
- ✅ Frame time: <8ms avg, <16ms p99
- ✅ Pool hit rate: >90%
- ✅ Culling: <3ms for 10K points
- ✅ Text cache: >70% hit rate
- ✅ Zero GC collections during steady-state

---

## Summary

All technical context resolved. Foundation Layer provides proven ObjectPool and ViewportCuller primitives. Core Rendering implements layer-based pipeline with performance monitoring and text caching using pure Dart stdlib. Architecture decisions documented in ADRs. Performance validation strategy defined with concrete benchmarks. Ready for Phase 1 (contracts and data model).
