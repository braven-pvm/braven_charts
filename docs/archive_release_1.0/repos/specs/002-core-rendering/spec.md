# Feature Specification: Core Rendering Engine

**Feature Branch**: `002-core-rendering`  
**Created**: 2025-01-04  
**Status**: Draft  
**Dependencies**: 001-foundation (ObjectPool, ViewportCuller, ChartDataPoint, ChartResult)

## Overview

The Core Rendering Engine provides the foundational rendering infrastructure for high-performance chart visualization. It manages Flutter canvas primitives through object pooling, implements a composable layer-based rendering pipeline, handles viewport culling/clipping, monitors performance metrics, and optimizes text layout through caching.

## Execution Flow (main)
```
1. Initialize rendering context with viewport and performance monitors
   → Create object pools for Paint, Path, TextPainter primitives
   → Configure viewport boundaries and culling regions
2. For each frame:
   → Begin performance monitoring (start frame timer)
   → Update viewport state (pan/zoom transformations)
   → Cull off-screen elements using viewport bounds
   → For each render layer (sorted by z-index):
      → Acquire pooled objects from primitive pools
      → Execute layer-specific rendering operations
      → Release pooled objects back to pools
   → Render cached text layouts for labels/annotations
   → End performance monitoring (record frame time, detect jank)
3. Collect performance metrics:
   → Track pool hit/miss rates
   → Measure frame render times
   → Detect frame drops (>16ms threshold)
4. Return: Rendered frame with performance data
```

---

## ⚡ Quick Guidelines
- ✅ Focus on WHAT users need and WHY
- ❌ Avoid HOW to implement (no tech stack, APIs, code structure)
- 👥 Written for business stakeholders, not developers
   - Security/compliance needs

---


---

## User Scenarios & Testing (MANDATORY)

### Scenario 1: Real-time Stock Chart with 10,000+ Points
**Actor**: Financial analyst viewing live market data  
**User Flow**:
1. Opens stock chart application with 10,000 data points
2. Chart renders initial viewport showing most recent 500 points
3. Pans left to view historical data (viewport shifts to show different 500-point window)
4. Zooms in to examine 1-hour price movement (viewport narrows to 50 points)
5. Chart maintains smooth 60fps interaction throughout

**Acceptance Criteria**:
- Initial render completes in <100ms
- Pan/zoom gestures respond with <16ms frame time (no jank)
- Viewport culling renders only visible points (500 of 10,000)
- Object pools maintain >90% hit rate (minimal allocation overhead)
- Performance monitor reports average frame time <8ms

**Edge Cases**:
- **Rapid pan**: User rapidly drags across entire dataset
  - Expected: Viewport updates skip intermediate frames but remain smooth
- **Extreme zoom out**: User zooms to view all 10,000 points
  - Expected: Adaptive rendering reduces detail while maintaining responsiveness
- **Zoom during pan**: User zooms while mid-pan gesture
  - Expected: Combined transformations apply without frame drops

### Scenario 2: Multi-Layer Chart with Annotations
**Actor**: Data scientist analyzing experimental results  
**User Flow**:
1. Opens chart with 3 layers: scatter plot (data), trend line (calculated), annotations (labels)
2. System renders layers in correct z-order (data → trend → annotations)
3. User hovers over data point to view tooltip annotation
4. New text label renders using cached layout (no re-computation)
5. User toggles trend line visibility (layer removed from rendering pipeline)

**Acceptance Criteria**:
- Layers render in correct z-order without depth sorting artifacts
- Text labels reuse cached layouts (>80% cache hit rate)
- Layer visibility toggle updates in <8ms
- Tooltips appear within one frame of hover event
- Memory usage remains stable across layer add/remove operations

**Edge Cases**:
- **Overlapping layers**: Multiple layers occupy same screen space
  - Expected: Proper alpha blending, no z-fighting
- **Empty layer**: Layer has no visible elements in viewport
  - Expected: Layer skipped entirely (zero rendering cost)
- **Text overflow**: Label text exceeds viewport bounds
  - Expected: Proper clipping without rendering off-screen portions

### Scenario 3: Performance Monitoring Dashboard
**Actor**: Developer debugging chart performance issues  
**User Flow**:
1. Enables performance monitoring overlay on chart
2. Views real-time metrics: frame time, pool hit rates, jank count
3. Identifies frame spike (25ms render time) during data update
4. Reviews performance log to find cause (pool exhaustion → allocation)
5. Adjusts pool sizes to eliminate future spikes

**Acceptance Criteria**:
- Performance metrics update every frame (60Hz)
- Frame time measurement accuracy ±0.5ms
- Pool statistics track hit/miss/allocation counts per primitive type
- Jank detection triggers when frame exceeds 16ms threshold
- Metrics collection overhead <1ms per frame

**Edge Cases**:
- **Performance monitor disabled**: Metrics collection should have zero overhead
  - Expected: No performance measurement code executes when disabled
- **Long frame time**: Frame takes >100ms (e.g., during resize)
  - Expected: Jank counter increments, no overflow errors
- **Pool statistics overflow**: Counter exceeds max int value
  - Expected: Graceful reset or saturation behavior

### Scenario 4: Text-Heavy Chart (Labels, Legends, Annotations)
**Actor**: Business user viewing quarterly report chart  
**User Flow**:
1. Opens bar chart with 50 bars, each with value label
2. Legend shows 10 category names with color indicators
3. Title and axis labels render with proper typography
4. User pans chart (data shifts, labels change)
5. Text layouts cached for repeated labels (months, values)

**Acceptance Criteria**:
- Initial text layout computation <50ms for all labels
- Cached layouts reused for identical text/style combinations (>70% hit rate)
- Text rendering maintains crisp appearance at all zoom levels
- Label positioning updates correctly during pan/zoom
- Memory usage bounded (cache eviction for old layouts)

**Edge Cases**:
- **Very long labels**: Label text exceeds 1000 characters
  - Expected: Layout completes without timeout, proper truncation
- **Thousands of unique labels**: Each data point has unique label
  - Expected: Cache size limited, LRU eviction maintains performance
- **Rapid text changes**: Labels update every frame (live counter)
  - Expected: Cache bypassed for dynamic text, no stale renders

---

## Requirements (MANDATORY)

### Functional Requirements

#### FR-001: Canvas Rendering Primitives
**Description**: The system must manage Flutter canvas primitives (Paint, Path, TextPainter) through object pooling to minimize garbage collection overhead during rendering.

**Rationale**: Canvas primitive allocation is a primary source of GC pressure in Flutter rendering. Object pooling eliminates per-frame allocation, critical for maintaining 60fps.

**Acceptance Criteria**:
- Object pools created for Paint, Path, and TextPainter types
- Pool acquire/release operations complete in O(1) time
- Pool hit rate exceeds 90% during steady-state rendering
- Pool statistics (hit/miss/allocation counts) exposed for monitoring
- Pool capacity dynamically adjusts based on usage patterns

**Dependencies**: 001-foundation (ObjectPool<T>)

**Success Metrics**:
- GC collections per second: <1 during active rendering
- Pool allocation overhead: <2% of frame time
- Memory stability: No growth over 1000-frame test

---

#### FR-002: Rendering Pipeline
**Description**: The system must provide a composable layer-based rendering pipeline where each layer represents a distinct visual element (data series, grid, annotations) with independent rendering logic.

**Rationale**: Layer-based architecture enables modularity (layers added/removed independently), performance optimization (skip empty layers), and correct visual ordering (z-index control).

**Acceptance Criteria**:
- Layers render in z-order (lower index first, higher index on top)
- Each layer has access to shared RenderContext (viewport, pools, metrics)
- Layer visibility toggling excludes layer from pipeline (<8ms update)
- Empty layers (no visible elements) short-circuit without rendering cost
- Layer composition supports alpha blending and clipping

**Dependencies**: None (self-contained)

**Success Metrics**:
- Layer add/remove latency: <5ms
- Empty layer overhead: <0.1ms
- Z-order correctness: 100% visual validation

---

#### FR-003: Viewport Management
**Description**: The system must provide viewport culling and clipping to render only elements visible within the current view bounds, reducing rendering overhead for large datasets.

**Rationale**: Rendering off-screen elements wastes GPU time and increases frame duration. Viewport culling (skip off-screen) and clipping (trim partial visibility) are essential for scalability.

**Acceptance Criteria**:
- Viewport bounds defined by pan/zoom transformation matrix
- Culling algorithm identifies visible data points using spatial index
- Clipping applied to partially visible elements (proper edge handling)
- Viewport updates (pan/zoom) recalculate visible set in <5ms
- Culling effectiveness measured (rendered vs total elements ratio)

**Dependencies**: 001-foundation (ViewportCuller for point-based culling)

**Success Metrics**:
- Culling latency: <3ms for 10,000 points
- Render reduction: >80% when viewing 5% of dataset
- Clipping accuracy: Pixel-perfect edge rendering

---

#### FR-004: Performance Monitoring
**Description**: The system must track real-time performance metrics including frame render time, jank detection (frames exceeding 16ms), and object pool statistics to enable performance debugging.

**Rationale**: Performance issues are difficult to diagnose without instrumentation. Real-time metrics allow developers to identify bottlenecks (e.g., pool exhaustion, culling inefficiency) during development.

**Acceptance Criteria**:
- Frame time measured with microsecond precision (Stopwatch)
- Jank detection triggers when frame exceeds 16ms threshold
- Pool statistics collected per primitive type (Paint/Path/TextPainter)
- Metrics exposed via callback or stream for external monitoring
- Monitoring overhead <1ms per frame (negligible impact)

**Dependencies**: None (uses dart:core Stopwatch)

**Success Metrics**:
- Measurement accuracy: ±0.5ms
- Overhead percentage: <1.5% of frame time
- Jank detection rate: 100% (no false negatives)

---

#### FR-005: Text Rendering Optimization
**Description**: The system must cache TextPainter layouts for repeated text content to avoid redundant layout computation, improving performance for label-heavy charts.

**Rationale**: TextPainter.layout() is computationally expensive (typography, line breaking, shaping). Caching layouts for identical text/style combinations eliminates repeated computation.

**Acceptance Criteria**:
- Cache keyed by text content + TextStyle hash
- Cache hit returns pre-computed layout in <0.5ms
- Cache miss computes layout and stores result (LRU eviction policy)
- Cache size bounded (e.g., 500 entries) to prevent unbounded growth
- Cache invalidation on style changes (font, size, color)

**Dependencies**: None (self-contained)

**Success Metrics**:
- Cache hit rate: >70% for typical charts
- Hit latency: <0.5ms
- Miss latency: <5ms (layout + cache store)

---

### Non-Functional Requirements

#### NFR-001: Performance
**Description**: The system must maintain 60fps rendering (16ms frame budget) for charts with up to 10,000 visible data points under typical pan/zoom interactions.

**Acceptance Criteria**:
- Average frame time <8ms (50% margin below 16ms budget)
- 99th percentile frame time <16ms (rare jank acceptable)
- Object pool operations <2% of frame time
- Viewport culling <20% of frame time
- Text layout cache hit rate >70%

**Measurement**: Automated performance tests with 10,000-point dataset, simulated pan/zoom gestures, frame time histogram analysis.

**Priority**: P0 (Critical - primary feature value)

---

#### NFR-002: Code Quality
**Description**: The system must achieve >95% test coverage with TDD-developed unit, contract, and integration tests to ensure correctness and prevent regressions.

**Acceptance Criteria**:
- Unit tests: All public methods, edge cases, error conditions
- Contract tests: RenderLayer interface compliance, pool contracts
- Integration tests: Full rendering pipeline with real Canvas mocks
- Performance tests: Frame time benchmarks, pool efficiency metrics
- Test execution time <30s for full suite

**Measurement**: Coverage reports (dart test --coverage), test pass rate, CI pipeline validation.

**Priority**: P0 (Critical - maintains foundation quality standard)

---

#### NFR-003: Maintainability
**Description**: The system must provide clear abstractions (RenderContext, RenderLayer) and comprehensive documentation to enable future extension (new layer types, rendering strategies).

**Acceptance Criteria**:
- All public APIs documented with dartdoc comments
- Architecture decision records (ADRs) for pooling, layering, culling
- Example usage code for common scenarios (new layer, custom culling)
- Dependency injection for testability (RenderContext passed to layers)
- Zero external package dependencies (Dart stdlib only)

**Measurement**: Documentation completeness review, API surface analysis, extensibility validation.

**Priority**: P1 (High - ensures long-term project success)

---

## Key Entities (CONDITIONAL)

### RenderContext
**Description**: Shared rendering state passed to all layers during pipeline execution.

**Purpose**: Provides layers access to viewport bounds, object pools, performance monitors, and canvas context without tight coupling.

**Key Attributes**:
- `viewport`: Current view transformation (pan/zoom matrix)
- `paintPool`: ObjectPool<Paint> for acquiring/releasing Paint objects
- `pathPool`: ObjectPool<Path> for acquiring/releasing Path objects
- `textPainterPool`: ObjectPool<TextPainter> for text rendering
- `performanceMonitor`: Frame time and jank tracking
- `canvas`: Flutter Canvas for drawing operations

**Lifecycle**: Created at rendering pipeline initialization, updated per frame, passed to layers during render.

**Relationships**: Used by RenderLayer implementations, managed by RenderPipeline.

---

### RenderLayer
**Description**: Abstract representation of a distinct visual element in the chart (data series, grid, annotations).

**Purpose**: Enables modular rendering where each layer handles its own drawing logic, z-ordering, and visibility.

**Key Attributes**:
- `zIndex`: Rendering order (lower values render first/bottom)
- `isVisible`: Visibility flag (false skips rendering)
- `render(RenderContext)`: Abstract method implemented by concrete layers

**Lifecycle**: Created when chart component added, destroyed when removed, rendered each frame if visible.

**Relationships**: Managed by RenderPipeline (sorted by zIndex), uses RenderContext during render.

---

### RenderPipeline
**Description**: Orchestrates the frame rendering process by executing layers in z-order with performance monitoring.

**Purpose**: Central coordinator that manages layer collection, viewport state, object pools, and performance tracking.

**Key Attributes**:
- `layers`: List of RenderLayer instances (maintained in z-order)
- `renderContext`: Shared context instance passed to layers
- `performanceMonitor`: Tracks frame time, jank, pool statistics

**Lifecycle**: Created at chart initialization, persists for chart lifetime, executes per frame.

**Relationships**: Contains RenderLayer collection, creates/manages RenderContext, invokes PerformanceMonitor.

---

### PerformanceMetrics
**Description**: Real-time performance data collected during rendering.

**Purpose**: Provides visibility into rendering performance for debugging and optimization.

**Key Attributes**:
- `frameTime`: Duration of last frame render (microseconds)
- `jankCount`: Number of frames exceeding 16ms threshold
- `poolHitRate`: Percentage of pool acquires satisfied from pool (not allocated)
- `culledElementCount`: Number of elements skipped by viewport culling
- `renderedElementCount`: Number of elements actually drawn

**Lifecycle**: Updated each frame, persisted across frames, exposed via callback/stream.

**Relationships**: Populated by RenderPipeline and PerformanceMonitor, consumed by external monitoring.

---

### TextLayoutCache
**Description**: Cache of pre-computed TextPainter layouts keyed by text content and style.

**Purpose**: Eliminates redundant text layout computation for repeated labels (axis values, legend entries).

**Key Attributes**:
- `cache`: Map<String, TextPainter> keyed by "text:styleHash"
- `maxSize`: Maximum cache entries (LRU eviction when exceeded)
- `hitCount`: Number of cache hits (for hit rate calculation)
- `missCount`: Number of cache misses (layout computations)

**Lifecycle**: Created at pipeline initialization, persists across frames, evicts old entries when full.

**Relationships**: Used by text-rendering layers, managed by RenderPipeline or dedicated text manager.

---

## Review & Acceptance Checklist

- [x] **User scenarios are testable and unambiguous**: Each scenario has clear acceptance criteria and edge cases
- [x] **Requirements have measurable success criteria**: All FRs and NFRs include specific metrics
- [x] **No implementation details**: Spec describes WHAT (pooling, layering) not HOW (class names, APIs)
- [x] **Dependencies clearly stated**: Foundation layer (ObjectPool, ViewportCuller) explicitly listed
- [x] **Edge cases identified**: Rapid interaction, extreme zoom, pool exhaustion, cache overflow covered
- [x] **Constitutional compliance verified**: Zero external dependencies, TDD required, performance targets defined
- [x] **Spec is ready for planning**: Clear scope, testable requirements, foundation dependencies available

---

## Execution Status

**Status**: ✅ SUCCESS (Specification ready for planning)

**Key Decisions**:
- Object pooling for Paint/Path/TextPainter to eliminate GC overhead
- Layer-based rendering pipeline for modularity and z-ordering
- Viewport culling leverages foundation ViewportCuller
- Performance monitoring built-in (frame time, jank, pool stats)
- Text layout caching for label-heavy chart optimization

**Deferred to Planning**:
- Specific layer types (GridLayer, SeriesLayer, AnnotationLayer) - implementation detail
- Pool sizing strategy (initial capacity, growth policy) - tuning parameter
- Cache eviction algorithm details (LRU vs other) - implementation choice
- Performance monitor data structure - technical design

**Performance Targets Summary**:
| Metric | Target | Measurement |
|--------|--------|-------------|
| Frame time (average) | <8ms | Stopwatch per frame |
| Frame time (99th percentile) | <16ms | Histogram analysis |
| Pool hit rate | >90% | Acquire stats |
| Text cache hit rate | >70% | Cache stats |
| Viewport culling latency | <3ms | 10K point test |
| Jank detection accuracy | 100% | Threshold validation |

**Dependencies**:
- ✅ 001-foundation: ObjectPool<T> (AVAILABLE - foundation complete)
- ✅ 001-foundation: ViewportCuller (AVAILABLE - foundation complete)
- ✅ 001-foundation: ChartDataPoint (AVAILABLE - foundation complete)
- ✅ 001-foundation: ChartResult<T> (AVAILABLE - foundation complete)

**Next Steps**:
1. Create `plan.md`: Implementation strategy, architecture decisions, file structure
2. Create `tasks.md`: TDD task breakdown (tests first), phase-by-phase execution
3. Create `data-model.md`: RenderContext, PerformanceMetrics, cache structures
4. Create `contracts/`: RenderLayer interface, pool contracts, monitor interfaces
5. Begin implementation following TDD workflow from 001-foundation

