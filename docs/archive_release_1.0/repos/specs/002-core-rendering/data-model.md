# Data Model: Core Rendering Engine

**Feature**: 002-core-rendering  
**Date**: 2025-10-05  
**Status**: Design Complete

---

## Entity Overview

The Core Rendering Engine introduces 5 primary entities and 1 supporting entity for high-performance chart visualization:

1. **RenderContext** - Immutable rendering state container
2. **RenderLayer** - Abstract visual element interface
3. **RenderPipeline** - Layer orchestration and frame execution
4. **PerformanceMonitor** - Frame timing and jank detection
5. **PerformanceMetrics** - Performance data snapshot
6. **TextLayoutCache** - Text painter layout caching

All entities follow Foundation Layer patterns: immutability, const constructors, value semantics.

---

## Entity 1: RenderContext

### Purpose
Dependency injection container providing layers with canvas, viewport, pools, and monitoring during rendering. Eliminates tight coupling between layers and rendering infrastructure.

### Fields

| Field | Type | Nullability | Purpose |
|-------|------|-------------|---------|
| `canvas` | Canvas | non-null | Flutter canvas for drawing operations |
| `size` | Size | non-null | Canvas size (width, height) |
| `viewport` | Rect | non-null | Visible bounds (pan/zoom transformed) |
| `culler` | ViewportCuller | non-null | Foundation culler for point visibility |
| `paintPool` | ObjectPool<Paint> | non-null | Pool for Paint objects |
| `pathPool` | ObjectPool<Path> | non-null | Pool for Path objects |
| `textPainterPool` | ObjectPool<TextPainter> | non-null | Pool for TextPainter objects |
| `textCache` | TextLayoutCache | non-null | Text layout cache |
| `performanceMonitor` | PerformanceMonitor | non-null | Frame timing monitor |

### Validation Rules
- `size.width` and `size.height` must be > 0 (canvas has dimensions)
- `viewport` must intersect `Rect.fromLTWH(0, 0, size.width, size.height)` (viewport within canvas)
- All pools must be initialized (non-null)

### Lifecycle
- **Creation**: Per frame by RenderPipeline before layer rendering
- **Usage**: Passed to each RenderLayer.render(context) call
- **Destruction**: End of frame (immutable, no cleanup needed)
- **Immutability**: Recreated per frame, never mutated

### Relationships
- **Used by**: RenderLayer implementations (composition)
- **Created by**: RenderPipeline
- **References**: ViewportCuller (Foundation), ObjectPool (Foundation), TextLayoutCache (local)

### Example
```dart
const context = RenderContext(
  canvas: canvas,
  size: Size(800, 600),
  viewport: Rect.fromLTWH(0, 0, 800, 600),
  culler: viewportCuller,
  paintPool: paintPool,
  pathPool: pathPool,
  textPainterPool: textPainterPool,
  textCache: textCache,
  performanceMonitor: monitor,
);

layer.render(context); // Layer receives all dependencies
```

---

## Entity 2: RenderLayer

### Purpose
Abstract interface for visual elements (data series, grid, annotations). Enables modular, testable, z-ordered rendering with visibility control.

### Fields

| Field | Type | Nullability | Purpose |
|-------|------|-------------|---------|
| `zIndex` | int | non-null | Rendering order (lower renders first/bottom) |
| `isVisible` | bool | non-null (default: true) | Visibility flag (false skips rendering) |

### Abstract Methods

| Method | Signature | Purpose |
|--------|-----------|---------|
| `render` | `void render(RenderContext context)` | Execute layer-specific rendering logic |
| `isEmpty` | `bool get isEmpty` (optional, default: false) | Check if layer has visible elements |

### Validation Rules
- `zIndex` can be any int (negative for backgrounds, positive for overlays)
- `isVisible` toggleable at runtime
- `render()` must be idempotent (safe to call multiple times per frame)

### Lifecycle
- **Creation**: When chart component added (e.g., addSeries, addGrid)
- **Usage**: RenderPipeline calls render() each frame if visible
- **Destruction**: When layer removed from pipeline
- **State**: Stateless (no frame-to-frame state), data passed per render

### Relationships
- **Implemented by**: Concrete layer types (DataSeriesLayer, GridLayer, etc.)
- **Managed by**: RenderPipeline (collection of layers)
- **Receives**: RenderContext during render()

### Example
```dart
class DataSeriesLayer extends RenderLayer {
  final List<ChartDataPoint> dataPoints;
  
  const DataSeriesLayer({
    required this.dataPoints,
    required super.zIndex,
    super.isVisible,
  });
  
  @override
  void render(RenderContext context) {
    if (isEmpty) return; // Short-circuit
    
    final visiblePoints = context.culler.cullPoints(dataPoints, context.viewport);
    final paint = context.paintPool.acquire();
    
    try {
      for (final point in visiblePoints) {
        context.canvas.drawCircle(Offset(point.x, point.y), 3.0, paint);
      }
    } finally {
      context.paintPool.release(paint);
    }
  }
  
  @override
  bool get isEmpty => dataPoints.isEmpty;
}
```

---

## Entity 3: RenderPipeline

### Purpose
Orchestrates frame rendering by executing layers in z-order with performance monitoring, pool management, and viewport updates. Central coordinator for all rendering operations.

### Fields

| Field | Type | Nullability | Purpose |
|-------|------|-------------|---------|
| `layers` | List<RenderLayer> | non-null (mutable) | Collection of layers to render |
| `paintPool` | ObjectPool<Paint> | non-null | Shared Paint pool |
| `pathPool` | ObjectPool<Path> | non-null | Shared Path pool |
| `textPainterPool` | ObjectPool<TextPainter> | non-null | Shared TextPainter pool |
| `textCache` | TextLayoutCache | non-null | Shared text layout cache |
| `performanceMonitor` | PerformanceMonitor | non-null | Frame timing monitor |
| `culler` | ViewportCuller | non-null | Viewport culler from Foundation |
| `viewport` | Rect | non-null (mutable) | Current viewport bounds |

### Methods

| Method | Signature | Purpose |
|--------|-----------|---------|
| `renderFrame` | `void renderFrame(Canvas canvas, Size size)` | Execute full frame render |
| `addLayer` | `void addLayer(RenderLayer layer)` | Add layer to pipeline |
| `removeLayer` | `void removeLayer(RenderLayer layer)` | Remove layer from pipeline |
| `updateViewport` | `void updateViewport(Rect newViewport)` | Update viewport (pan/zoom) |

### Validation Rules
- Layers must have unique identity (prevent duplicate adds)
- `viewport` must be non-empty (width > 0, height > 0)
- `renderFrame` only callable with valid canvas and size

### Lifecycle
- **Creation**: Chart initialization (one per chart instance)
- **Usage**: renderFrame() called 60 times per second (60fps)
- **Destruction**: Chart disposal
- **State**: Mutable (layers, viewport change over time)

### Relationships
- **Contains**: List<RenderLayer> (1-to-many)
- **Creates**: RenderContext per frame
- **Uses**: ObjectPool (Foundation), ViewportCuller (Foundation), PerformanceMonitor (local)

### State Transitions
```
Created → Layers Added → Rendering (loop) → Layers Removed/Modified → Destroyed
                             ↓
                    (60fps renderFrame calls)
```

### Example
```dart
final pipeline = RenderPipeline(
  paintPool: paintPool,
  pathPool: pathPool,
  textPainterPool: textPainterPool,
  textCache: textCache,
  performanceMonitor: monitor,
  culler: culler,
  viewport: Rect.fromLTWH(0, 0, 800, 600),
);

pipeline.addLayer(DataSeriesLayer(dataPoints: points, zIndex: 0));
pipeline.addLayer(GridLayer(zIndex: -1)); // Render behind data
pipeline.addLayer(AnnotationLayer(zIndex: 1)); // Render on top

// Each frame:
pipeline.renderFrame(canvas, size);

// Pan/zoom:
pipeline.updateViewport(Rect.fromLTWH(100, 0, 800, 600));
```

---

## Entity 4: PerformanceMonitor

### Purpose
Track frame timing, jank detection, and pool statistics for performance debugging and validation. Provides microsecond-precision measurement with <1ms overhead.

### Fields

| Field | Type | Nullability | Purpose |
|-------|------|-------------|---------|
| `_stopwatch` | Stopwatch | non-null (private) | Microsecond-precision timer |
| `_frameTimes` | List<Duration> | non-null (private) | Historical frame times |
| `_jankCount` | int | non-null (private) | Number of jank frames (>16ms) |
| `maxHistorySize` | int | non-null | Max frame times to retain (default: 120 = 2 seconds @ 60fps) |

### Methods

| Method | Signature | Purpose |
|--------|-----------|---------|
| `beginFrame` | `void beginFrame()` | Start frame timer |
| `endFrame` | `void endFrame()` | Stop timer, detect jank, record time |
| `currentMetrics` | `PerformanceMetrics get currentMetrics` | Get current performance snapshot |
| `reset` | `void reset()` | Clear history and jank count |

### Validation Rules
- `beginFrame()` and `endFrame()` must be called in pairs
- `endFrame()` without `beginFrame()` throws assertion error
- `_frameTimes` bounded by `maxHistorySize` (LRU eviction)

### Lifecycle
- **Creation**: RenderPipeline initialization
- **Usage**: beginFrame() → render operations → endFrame() (60fps)
- **Destruction**: RenderPipeline disposal
- **State**: Mutable (accumulates frame times, jank count)

### Relationships
- **Used by**: RenderPipeline (owns monitor)
- **Produces**: PerformanceMetrics (value object)
- **References**: None (self-contained, Stopwatch from dart:core)

### State Transitions
```
Idle → beginFrame() → Timing → endFrame() → Idle (loop)
                          ↓
                    (update jank count)
```

### Example
```dart
final monitor = PerformanceMonitor(maxHistorySize: 120);

// Each frame:
monitor.beginFrame();
// ... rendering operations ...
monitor.endFrame();

// Check performance:
final metrics = monitor.currentMetrics;
if (!metrics.meetsTargets) {
  print('Performance issue: avg=${metrics.averageFrameTime}');
}
```

---

## Entity 5: PerformanceMetrics

### Purpose
Immutable snapshot of performance data for validation and debugging. Value object with no behavior, only data.

### Fields

| Field | Type | Nullability | Purpose |
|-------|------|-------------|---------|
| `frameTime` | Duration | non-null | Last frame render time |
| `averageFrameTime` | Duration | non-null | Average over history |
| `p99FrameTime` | Duration | non-null | 99th percentile frame time |
| `jankCount` | int | non-null | Total frames >16ms |
| `poolHitRate` | double | non-null | Pool hit rate (0.0-1.0) |
| `culledElementCount` | int | nullable | Elements culled (optional) |
| `renderedElementCount` | int | nullable | Elements rendered (optional) |

### Computed Properties

| Property | Type | Purpose |
|----------|------|---------|
| `meetsTargets` | bool | True if avg<8ms, p99<16ms, hitRate>0.90 |
| `averageFrameTimeMs` | double | Frame time in milliseconds (convenience) |
| `p99FrameTimeMs` | double | P99 time in milliseconds (convenience) |

### Validation Rules
- All Duration fields must be non-negative
- `poolHitRate` must be in range [0.0, 1.0]
- `jankCount` must be >= 0

### Lifecycle
- **Creation**: PerformanceMonitor.currentMetrics getter
- **Usage**: Read performance data, validate against targets
- **Destruction**: GC (value object, no cleanup)
- **Immutability**: Const constructor, all fields final

### Relationships
- **Created by**: PerformanceMonitor
- **Used by**: Test assertions, performance validation, debugging UI
- **References**: None (pure data)

### Example
```dart
const metrics = PerformanceMetrics(
  frameTime: Duration(microseconds: 7500),
  averageFrameTime: Duration(microseconds: 7200),
  p99FrameTime: Duration(microseconds: 14800),
  jankCount: 2,
  poolHitRate: 0.94,
  culledElementCount: 9500,
  renderedElementCount: 500,
);

assert(metrics.meetsTargets); // avg<8ms, p99<16ms, hitRate>90%
print('Avg: ${metrics.averageFrameTimeMs}ms'); // 7.2ms
```

---

## Entity 6: TextLayoutCache

### Purpose
Cache pre-computed TextPainter layouts to avoid redundant text layout computation. Improves performance for label-heavy charts (>70% cache hit rate target).

### Fields

| Field | Type | Nullability | Purpose |
|-------|------|-------------|---------|
| `_cache` | LinkedHashMap<String, TextPainter> | non-null (private) | LRU cache map |
| `maxSize` | int | non-null | Max cache entries (default: 500) |
| `_hitCount` | int | non-null (private) | Cache hit counter |
| `_missCount` | int | non-null (private) | Cache miss counter |

### Methods

| Method | Signature | Purpose |
|--------|-----------|---------|
| `get` | `TextPainter? get(String text, TextStyle style)` | Retrieve cached layout (null if miss) |
| `put` | `void put(String text, TextStyle style, TextPainter painter)` | Store layout (LRU evict if full) |
| `clear` | `void clear()` | Clear cache (invalidation) |
| `hitRate` | `double get hitRate` | Hit rate (0.0-1.0) |
| `_makeCacheKey` | `String _makeCacheKey(String text, TextStyle style)` (private) | Generate composite key |

### Validation Rules
- `maxSize` must be > 0
- `_cache.length` never exceeds `maxSize` (LRU eviction)
- Cache key must uniquely identify text+style combination

### Lifecycle
- **Creation**: RenderPipeline initialization
- **Usage**: get() before text layout, put() after layout computation
- **Destruction**: RenderPipeline disposal (cache cleared)
- **State**: Mutable (cache grows/shrinks, counters increment)

### Relationships
- **Used by**: RenderContext (passed to layers)
- **Contains**: TextPainter instances (Flutter framework object)
- **References**: None (self-contained)

### Cache Key Strategy
```dart
String _makeCacheKey(String text, TextStyle style) {
  return '$text:${style.hashCode}';
}
```
- **Text**: Full string content
- **Style**: hashCode of TextStyle (font, size, color, etc.)
- **Uniqueness**: Same text with different style = different keys

### LRU Eviction
```dart
void put(String text, TextStyle style, TextPainter painter) {
  final key = _makeCacheKey(text, style);
  
  // Evict oldest if at capacity
  if (_cache.length >= maxSize) {
    _cache.remove(_cache.keys.first); // LinkedHashMap preserves order
  }
  
  _cache[key] = painter;
}
```

### Example
```dart
final cache = TextLayoutCache(maxSize: 500);

// First render (cache miss):
var painter = cache.get('Label 1', textStyle);
if (painter == null) {
  painter = TextPainter(text: TextSpan(text: 'Label 1', style: textStyle));
  painter.layout();
  cache.put('Label 1', textStyle, painter);
}

// Second render (cache hit):
painter = cache.get('Label 1', textStyle); // Returns cached painter
assert(painter != null);
assert(cache.hitRate > 0.0);
```

---

## Data Model Relationships Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                        RenderPipeline                           │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │ - layers: List<RenderLayer>                               │  │
│  │ - viewport: Rect                                          │  │
│  │ - paintPool, pathPool, textPainterPool (ObjectPool)      │  │
│  │ - textCache: TextLayoutCache                              │  │
│  │ - performanceMonitor: PerformanceMonitor                  │  │
│  │ - culler: ViewportCuller (Foundation)                     │  │
│  └──────────────────────────────────────────────────────────┘  │
│                          │                                      │
│                          │ creates per frame                    │
│                          ▼                                      │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │                   RenderContext                           │  │
│  │  (Immutable dependency injection container)               │  │
│  │  - canvas, size, viewport                                 │  │
│  │  - culler, pools, textCache, performanceMonitor           │  │
│  └──────────────────────────────────────────────────────────┘  │
│                          │                                      │
│                          │ passed to                            │
│                          ▼                                      │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │              RenderLayer (abstract)                       │  │
│  │  - zIndex: int                                            │  │
│  │  - isVisible: bool                                        │  │
│  │  + render(RenderContext): void                            │  │
│  └──────────────────────────────────────────────────────────┘  │
│         ▲                                                       │
│         │ implemented by                                       │
│         │                                                       │
│  ┌──────┴──────┬─────────────┬───────────────┐                │
│  │             │             │               │                 │
│ DataSeriesLayer GridLayer  AnnotationLayer  ...                │
│  (Concrete layer implementations)                              │
└─────────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────┐
│                   PerformanceMonitor                         │
│  - _stopwatch: Stopwatch                                     │
│  - _frameTimes: List<Duration>                               │
│  - _jankCount: int                                           │
│  + beginFrame(), endFrame()                                  │
│  + currentMetrics: PerformanceMetrics                        │
└──────────────────────────────────────────────────────────────┘
                          │
                          │ produces
                          ▼
┌──────────────────────────────────────────────────────────────┐
│                  PerformanceMetrics (immutable)              │
│  - frameTime, averageFrameTime, p99FrameTime                 │
│  - jankCount, poolHitRate                                    │
│  + meetsTargets: bool                                        │
└──────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────┐
│                   TextLayoutCache                            │
│  - _cache: LinkedHashMap<String, TextPainter>                │
│  - maxSize: int                                              │
│  - _hitCount, _missCount: int                                │
│  + get(text, style): TextPainter?                            │
│  + put(text, style, painter): void                           │
│  + hitRate: double                                           │
└──────────────────────────────────────────────────────────────┘
```

---

## Validation Rules Summary

| Entity | Key Validation Rules |
|--------|---------------------|
| RenderContext | Size > 0, viewport within canvas bounds, non-null dependencies |
| RenderLayer | zIndex any int, isVisible boolean, render() idempotent |
| RenderPipeline | Unique layers, non-empty viewport, valid canvas/size |
| PerformanceMonitor | Paired begin/end calls, bounded history, non-negative times |
| PerformanceMetrics | Non-negative durations, poolHitRate in [0,1], jankCount >= 0 |
| TextLayoutCache | maxSize > 0, cache.length <= maxSize, unique keys |

---

## Immutability Strategy

Following Foundation Layer pattern:

**Immutable Entities**:
- ✅ RenderContext (const constructor, recreated per frame)
- ✅ PerformanceMetrics (const constructor, value object)

**Mutable Entities** (justified):
- ⚠️ RenderPipeline (layers added/removed, viewport updates)
- ⚠️ PerformanceMonitor (accumulates metrics over time)
- ⚠️ TextLayoutCache (cache grows/shrinks, LRU eviction)
- ⚠️ RenderLayer (isVisible toggleable)

**Rationale for Mutability**:
- RenderPipeline: Chart structure changes at runtime (add/remove series)
- PerformanceMonitor: Stateful by nature (historical data)
- TextLayoutCache: Cache inherently stateful (memoization)
- RenderLayer: Visibility control requires mutability

All mutable entities encapsulate state, expose immutable snapshots (PerformanceMetrics).

---

## Foundation Layer Integration

### Dependencies

| Core Rendering Entity | Foundation Dependency | Integration Point |
|----------------------|----------------------|-------------------|
| RenderContext | ObjectPool<T> | paintPool, pathPool, textPainterPool fields |
| RenderContext | ViewportCuller | culler field, cullPoints() method |
| RenderPipeline | ObjectPool<T> | Pool creation and lifecycle |
| RenderPipeline | ViewportCuller | Passed to RenderContext |
| (All layers) | ChartDataPoint | Data representation for rendering |

### Import Strategy
```dart
import 'package:braven_charts/src/foundation/object_pool.dart';
import 'package:braven_charts/src/foundation/viewport_culler.dart';
import 'package:braven_charts/src/foundation/data_models.dart';
```

No circular dependencies: Core Rendering imports Foundation, Foundation never imports Core Rendering.

---

## Testing Strategy

### Contract Tests (from contracts/)
- RenderLayer.render() contract compliance
- PerformanceMonitor timing accuracy
- TextLayoutCache hit/miss behavior

### Unit Tests
- RenderContext immutability, validation
- RenderPipeline layer management (add/remove/sort)
- PerformanceMonitor jank detection (>16ms threshold)
- TextLayoutCache LRU eviction

### Integration Tests
- Full pipeline: layers → pipeline → context → render
- Performance: measure actual frame times, validate <8ms avg
- Pool integration: verify >90% hit rate with Paint/Path/TextPainter

### Data Model Validation
- All entities serializable (for testing, not production use)
- Equality and hashCode for value objects (PerformanceMetrics)
- copyWith() for mutable entities (RenderLayer.isVisible toggle)

---

## Summary

6 entities defined following Foundation patterns: immutability where possible, clear validation rules, dependency injection via RenderContext, integration with Foundation ObjectPool and ViewportCuller. Data model supports all functional requirements (FR-001 to FR-005) and non-functional requirements (NFR-001 to NFR-003). Ready for contract generation (Phase 1 continuation).
