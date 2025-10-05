# Tasks: Core Rendering Engine

**Input**: Design documents from `/specs/002-core-rendering/`
**Prerequisites**: plan.md, research.md, data-model.md, contracts/, quickstart.md

## Execution Flow (main)
```
1. Load plan.md from feature directory
   → Tech stack: Da- [x] **T026**: Write unit tests for `RenderPipeline` `ViewportCuller` integrationt 3.0+, Flutter SDK 3.37.0-1.0.pre-216
   → Dependencies: Foundation Layer (ObjectPool, ViewportCuller, ChartDataPoint)
   → Structure: Single Flutter project (lib/src/rendering/, test/)
2. Load design documents:
   → data-model.md: 6 entities (RenderContext, RenderLayer, RenderPipeline, PerformanceMonitor, PerformanceMetrics, TextLayoutCache)
   → contracts/: 3 files (render_layer.dart, performance_monitor.dart, text_layout_cache.dart)
   → quickstart.md: 4 scenarios (minimal example, custom layer, text rendering, viewport management)
3. Generate tasks by category:
   → Setup: Directory structure, linting
   → Tests: 3 contract tests, 4 integration tests (from user scenarios)
   → Core: 6 entity implementations
   → Integration: Pipeline orchestration, pool configuration
   → Polish: Unit tests, performance validation, documentation
4. Apply TDD rules:
   → Contract tests [P] before implementations
   → Integration tests [P] before polish
   → Different files = [P], same file = sequential
5. Number tasks: T001-T048 (48 total tasks)
6. Dependencies: Setup → Tests → Core → Integration → Polish
7. Validation: All entities tested, all scenarios covered
8. Return: SUCCESS (48 tasks ready for execution)
```

## Format: `[ID] [P?] Description`
- **[P]**: Can run in parallel (different files, no dependencies)
- Include exact file paths in descriptions

## Path Conventions
- **Single Flutter project**: `lib/src/rendering/`, `test/unit/`, `test/contract/`, `test/integration/`
- All paths relative to repository root: `X:\Cloud Storage\Dropbox\Repositories\Flutter\braven_charts_v2.0\`

---

## Phase 3.1: Setup (2 tasks)
- [x] **T001** Create rendering directory structure in lib/src/rendering/ (render_context.dart, render_layer.dart, render_pipeline.dart, performance_monitor.dart, performance_metrics.dart, text_layout_cache.dart)
- [x] **T002** Create test directory structure in test/ (unit/rendering/, contract/rendering/, integration/rendering/, benchmarks/rendering/)

---

## Phase 3.2: Contract Tests (TDD - MUST COMPLETE BEFORE 3.3) (3 tasks)
**CRITICAL: These tests MUST be written and MUST FAIL before ANY implementation**

- [x] **T003** [P] Contract test for RenderLayer interface in test/contract/rendering/render_layer_contract_test.dart
  - Test render() method signature
  - Test zIndex ordering behavior
  - Test isVisible toggle effects
  - Test isEmpty optimization
  - Test RenderContext dependency injection
  - Use MockRenderContext from contracts/render_layer.dart

- [x] **T004** [P] Contract test for PerformanceMonitor interface in test/contract/rendering/performance_monitor_contract_test.dart
  - Test beginFrame()/endFrame() pairing
  - Test currentMetrics getter returns valid data
  - Test jank detection (>16ms threshold)
  - Test reset() clears history
  - Test maxHistorySize boundary
  - Use MockPerformanceMonitor from contracts/performance_monitor.dart

- [x] **T005** [P] Contract test for TextLayoutCache interface in test/contract/rendering/text_layout_cache_contract_test.dart
  - Test get() returns null on miss
  - Test put() stores layout
  - Test LRU eviction when maxSize exceeded
  - Test clear() empties cache
  - Test hitRate calculation (hits / (hits + misses))
  - Use MockTextLayoutCache from contracts/text_layout_cache.dart

---

## Phase 3.3: Integration Tests (User Scenarios - TDD) (4 tasks)

- [x] **T006** [P] Integration test for Scenario 1 (Real-time Stock Chart with 10K+ points) in test/integration/rendering/stock_chart_10k_test.dart
  - Create chart with 10,000 ChartDataPoint instances
  - Render initial viewport (500 visible points)
  - Assert frame time <16ms (no jank)
  - Simulate pan left (shift viewport)
  - Assert viewport culling reduces render to new 500 points
  - Simulate zoom in (50 visible points)
  - Assert pool hit rate >90%
  - Assert average frame time <8ms over 60 frames

- [x] **T007** [P] Integration test for Scenario 2 (Multi-layer chart with annotations) in test/integration/rendering/multi_layer_chart_test.dart
  - Create 3 layers: scatter plot (zIndex=0), trend line (zIndex=1), annotations (zIndex=2)
  - Assert layers render in correct z-order
  - Add tooltip annotation dynamically
  - Assert text cache hit rate >80% after second render
  - Toggle trend line visibility to false
  - Assert layer skipped in next frame (<8ms update)

- [x] **T008** [P] Integration test for Scenario 3 (Performance monitoring dashboard) in test/integration/rendering/performance_dashboard_test.dart
  - Enable PerformanceMonitor
  - Render 100 frames
  - Assert metrics update every frame (60Hz)
  - Simulate frame spike (force 25ms delay)
  - Assert jank counter increments
  - Assert frame time measurement accuracy ±0.5ms
  - Verify pool statistics track hit/miss/allocation

- [x] **T009** [P] Integration test for Scenario 4 (Text-heavy chart) in test/integration/rendering/text_heavy_chart_test.dart
  - Create bar chart with 50 value labels
  - Add legend with 10 category names
  - Assert initial text layout <50ms
  - Render second frame
  - Assert text cache hit rate >70%
  - Simulate pan (labels change)
  - Assert cached layouts reused for repeated text
  - Verify memory bounded (cache eviction works)

---

## Phase 3.4: Core Entity Implementation (6 tasks)

### T010: PerformanceMetrics (Immutable Value Object)
- [x] **T010** [P] Implement PerformanceMetrics in lib/src/rendering/performance_metrics.dart
  - Create immutable class with const constructor
  - Fields: frameTime, averageFrameTime, p99FrameTime, jankCount, poolHitRate, culledElementCount, renderedElementCount
  - Implement meetsTargets getter (avg<8ms, p99<16ms, hitRate>0.90)
  - Implement averageFrameTimeMs getter (Duration → milliseconds)
  - Implement p99FrameTimeMs getter (Duration → milliseconds)
  - Validate poolHitRate in range [0.0, 1.0]
  - Validate all Duration fields non-negative
  - Add dartdoc comments for all public APIs
  - Run contract tests to verify compilation (expected: still failing, implementation incomplete)

### T011: TextLayoutCache (LRU Cache Implementation)
- [x] **T011** [P] Implement TextLayoutCache in lib/src/rendering/text_layout_cache.dart
  - Create abstract base class matching contract
  - Implement LinkedHashMapTextLayoutCache using dart:collection
  - Private field: `_cache` (LinkedHashMap<String, TextPainter>)
  - Private counters: `_hitCount`, `_missCount`
  - Implement get(text, style) → check cache, increment hitCount/missCount
  - Implement put(text, style, painter) → store with LRU eviction
  - Implement clear() → reset cache and counters
  - Implement hitRate getter → hits / (hits + misses), handle division by zero
  - Private method: _makeCacheKey(text, style) → "$text:${style.hashCode}"
  - LRU eviction: remove oldest entry when size >= maxSize
  - Add dartdoc comments
  - Run contract tests (T005) → should pass

### T012: PerformanceMonitor (Frame Timing)
### T012: PerformanceMonitor (Stopwatch-based Implementation)
- [x] **T012** Implement PerformanceMonitor in lib/src/rendering/performance_monitor.dart
  - Create abstract base class matching contract
  - Implement StopwatchPerformanceMonitor using dart:core Stopwatch
  - Private field: `_stopwatch` (Stopwatch instance)
  - Private field: `_frameTimes` (List<Duration>, max length = maxHistorySize)
  - Private field: `_jankCount` (int counter for >16ms frames)
  - Implement beginFrame() → start stopwatch
  - Implement endFrame() → stop stopwatch, record elapsed, detect jank (>16ms), add to _frameTimes with LRU eviction
  - Implement currentMetrics getter → calculate avg, p99 from _frameTimes, return PerformanceMetrics
  - Implement reset() → clear _frameTimes, reset _jankCount
  - Assert beginFrame/endFrame pairing (debug mode assertion)
  - Add dartdoc comments
  - Run contract tests (T004) → should pass
  - **Dependency**: Requires T010 (PerformanceMetrics) complete

### T013: RenderContext (Dependency Injection Container)
- [x] **T013** [P] Implement RenderContext in lib/src/rendering/render_context.dart
  - Create immutable class with const constructor
  - Fields: canvas, size, viewport, culler, paintPool, pathPool, textPainterPool, textCache, performanceMonitor
  - Validate size.width > 0 and size.height > 0 (assert in constructor)
  - Validate viewport intersects canvas bounds (assert)
  - All pools must be non-null (null safety enforced by Dart)
  - Add dartdoc comments explaining dependency injection pattern
  - Import foundation: ObjectPool, ViewportCuller
  - Import rendering: TextLayoutCache, PerformanceMonitor
  - Run tests (expected: compilation success, contract tests use this)

### T014: RenderLayer (Abstract Interface)
- [x] **T014** [P] Implement RenderLayer in lib/src/rendering/render_layer.dart
  - Move contract from specs/002-core-rendering/contracts/render_layer.dart to lib/src/rendering/render_layer.dart
  - Keep abstract class with zIndex, isVisible fields
  - Keep abstract render(RenderContext context) method
  - Keep isEmpty getter with default implementation (return false)
  - Remove MockRenderLayer (move to test/mocks/ if needed)
  - Add const constructor
  - Add dartdoc comments from contract
  - Run contract tests (T003) → should pass

### T015: RenderPipeline (Orchestrator)
- [x] **T015** Implement RenderPipeline in lib/src/rendering/render_pipeline.dart
  - Create class with mutable layers list (List<RenderLayer>)
  - Constructor: Accept paintPool, pathPool, textPainterPool, textCache, performanceMonitor, culler, initial viewport
  - Implement addLayer(RenderLayer layer) → insert layer, maintain z-order sort
  - Implement removeLayer(RenderLayer layer) → remove from list
  - Implement updateViewport(Rect newViewport) → update internal viewport state
  - Implement renderFrame(Canvas canvas, Size size):
    1. Call performanceMonitor.beginFrame()
    2. Create RenderContext with current viewport, pools, canvas, size
    3. Filter visible layers (isVisible == true)
    4. Sort layers by zIndex (ascending)
    5. For each layer: if (!layer.isEmpty) call layer.render(context)
    6. Call performanceMonitor.endFrame()
  - Add getter for performanceMonitor (expose for metrics access)
  - Add getter for textCache (expose for monitoring)
  - Add dartdoc comments
  - **Dependencies**: Requires T010, T011, T012, T013, T014 complete
  - Run integration tests (T006-T009) → should pass (TDD complete)

---

## Phase 3.5: Unit Tests for Core Logic (12 tasks)

- [x] **T016** [P] Unit test for PerformanceMetrics validation in test/unit/rendering/performance_metrics_test.dart
  - Test meetsTargets returns true when avg<8ms, p99<16ms, hitRate>0.90
  - Test meetsTargets returns false when any target missed
  - Test poolHitRate validation throws on invalid range (<0 or >1)
  - Test Duration fields validation throws on negative values
  - Test millisecond getters convert correctly

- [x] **T017** [P] Unit test for TextLayoutCache LRU eviction in test/unit/rendering/text_layout_cache_test.dart
  - Test cache evicts oldest entry when maxSize exceeded
  - Test get() after eviction returns null for evicted key
  - Test put() updates existing key (no duplicate entries)
  - Test hitRate calculation with various hit/miss ratios
  - Test clear() resets counters to zero

- [x] **T018** [P] Unit test for PerformanceMonitor frame timing in test/unit/rendering/performance_monitor_test.dart
  - Test beginFrame/endFrame pair records frame time
  - Test jank detection increments counter when frame >16ms
  - Test maxHistorySize boundary (evicts oldest frame times)
  - Test currentMetrics calculates correct average
  - Test currentMetrics calculates correct p99
  - Test reset() clears all state

- [x] **T019** [P] Unit test for RenderContext validation in test/unit/rendering/render_context_test.dart
  - Test constructor asserts on invalid size (width<=0 or height<=0)
  - Test constructor asserts when viewport doesn't intersect canvas
  - Test immutability (all fields final)
  - Test provides access to all dependency objects

- [x] **T020** [P] Unit test for RenderLayer isEmpty optimization in test/unit/rendering/render_layer_test.dart
  - Create test layer with isEmpty=true
  - Verify render() not called when isEmpty (via mock verification)
  - Create test layer with isEmpty=false
  - Verify render() called
  - Test isVisible=false skips render regardless of isEmpty

- [x] **T021** [P] Unit test for RenderPipeline layer management in test/unit/rendering/render_pipeline_test.dart
  - Test addLayer maintains z-order sort
  - Test removeLayer removes correct layer
  - Test addLayer with duplicate zIndex (both render)
  - Test layer visibility toggle affects render
  - Test isEmpty layers skipped

- [x] **T022** [P] Unit test for RenderPipeline viewport update in test/unit/rendering/render_pipeline_test.dart
  - Test updateViewport updates internal state
  - Test viewport passed to RenderContext during renderFrame
  - Test culling uses updated viewport

- [x] **T023** [P] Unit test for RenderPipeline performance monitoring in test/unit/rendering/render_pipeline_test.dart
  - Test beginFrame called before rendering
  - Test endFrame called after all layers rendered
  - Test frame time recorded even if layer throws exception (finally block)

- [ ] **T024** [P] Unit test for object pool integration in test/unit/rendering/render_pipeline_test.dart
  - Test RenderContext provides access to all 3 pools
  - Test pools passed from pipeline to context correctly
  - Test pool statistics accessible via pipeline

- [x] **T025** [P] Unit test for text cache integration in test/unit/rendering/render_pipeline_test.dart
  - Test RenderContext provides access to text cache
  - Test cache passed from pipeline to context correctly
  - Test cache statistics accessible via pipeline

- [x] **T026** [P] Unit test for ViewportCuller integration in test/unit/rendering/render_pipeline_test.dart
  - Test RenderContext provides access to culler (Foundation)
  - Test culler passed from pipeline to context correctly
  - Test viewport bounds used for culling

- [x] **T027**: Write unit tests for `RenderPipeline` error handling
  - Test exception in one layer doesn't crash pipeline
  - Test endFrame() called even if render throws
  - Test subsequent frames continue after error

---

## Phase 3.6: Example Layer Implementations (3 tasks)

- [x] **T028** [P] Implement GridLayer example in lib/src/rendering/layers/grid_layer.dart
  - Extend RenderLayer
  - Constructor: gridLineCount, lineColor, zIndex
  - Implement render(context): Draw horizontal/vertical grid lines using pathPool and paintPool
  - Implement isEmpty: return false (grid always visible)
  - Add dartdoc comments with usage example
  - **Purpose**: Demonstrate layer pattern, used in quickstart.md

- [x] **T029** [P] Implement DataSeriesLayer example in lib/src/rendering/layers/data_series_layer.dart
  - Extend RenderLayer
  - Constructor: List<ChartDataPoint> dataPoints, zIndex
  - Implement render(context):
    1. Acquire Path from context.pathPool
    2. Use context.culler to filter visible points
    3. Build path through visible points
    4. Acquire Paint from context.paintPool
    5. Draw path on context.canvas
    6. Release Path and Paint back to pools
  - Implement isEmpty: return dataPoints.isEmpty || all points culled
  - Add dartdoc comments
  - **Purpose**: Demonstrate Foundation integration (ViewportCuller, ObjectPool)

- [x] **T030** [P] Implement AnnotationLayer example in lib/src/rendering/layers/annotation_layer.dart
  - Extend RenderLayer
  - Constructor: List<String> labels, List<Offset> positions, TextStyle, zIndex
  - Implement render(context):
    1. Check context.textCache.get(label, style)
    2. If miss: create TextPainter, layout, context.textCache.put()
    3. Paint using cached or fresh painter
  - Implement isEmpty: return labels.isEmpty
  - Add dartdoc comments
  - **Purpose**: Demonstrate text cache usage pattern

---

## Phase 3.7: Performance Benchmarks (6 tasks)

- [x] **T031** [P] Benchmark object pool performance in test/benchmarks/rendering/object_pool_benchmark.dart
  - Measure Paint pool acquire/release latency (target: O(1), <10μs)
  - Measure Path pool acquire/release latency
  - Measure TextPainter pool acquire/release latency
  - Measure pool hit rate over 1000 acquire/release cycles (target: >90%)
  - Use benchmark_harness package (Dart stdlib)

- [x] **T032** [P] Benchmark viewport culling performance in test/benchmarks/rendering/viewport_culling_benchmark.dart
  - Create 10,000 ChartDataPoint instances
  - Measure culling latency with 5% visible (target: <3ms)
  - Measure culling latency with 50% visible
  - Measure culling latency with 95% visible
  - Verify Foundation ViewportCuller reuse

- [x] **T033** [P] Benchmark text layout caching in test/benchmarks/rendering/text_cache_benchmark.dart
  - Create 500 unique text/style combinations
  - Measure cache hit latency (target: <1μs)
  - Measure cache miss + layout latency (baseline)
  - Measure hit rate after 1000 renders (target: >70%)
  - Measure LRU eviction performance

- [x] **T034** [P] Benchmark RenderPipeline frame time in test/benchmarks/rendering/render_pipeline_benchmark.dart
  - Create pipeline with 3 layers (grid + series + annotations)
  - Measure frame time with 500 visible points (target: <8ms)
  - Measure frame time with 5000 visible points
  - Measure p99 frame time over 100 frames (target: <16ms)
  - Verify jank count = 0

- [x] **T035** [P] Benchmark layer z-ordering overhead in test/benchmarks/rendering/layer_sorting_benchmark.dart
  - Create 10 layers with random zIndex values
  - Measure sort latency per frame (target: <0.1ms)
  - Create 100 layers with random zIndex values
  - Measure sort latency (verify O(n log n))

- [x] **T036** [P] Benchmark empty layer short-circuit in test/benchmarks/rendering/empty_layer_benchmark.dart
  - Create 50 layers with isEmpty=true
  - Measure frame time (target: <5ms overhead = <0.1ms per layer)
  - Create 50 layers with isEmpty=false
  - Measure frame time difference
  - Verify isEmpty optimization effective

---

## Phase 3.8: Edge Case Tests (6 tasks)

- [x] **T037** [P] Edge case test for rapid pan in test/unit/rendering/edge_cases/rapid_pan_test.dart
  - Simulate 100 viewport updates in 1 second
  - Assert no frame drops (all <16ms)
  - Assert viewport state updates correctly
  - Verify no memory leaks (pool sizes stable)

- [x] **T038** [P] Edge case test for extreme zoom out in test/unit/rendering/edge_cases/extreme_zoom_test.dart
  - Set viewport to show all 10,000 points
  - Assert frame time degrades gracefully (may exceed 16ms)
  - Verify no crashes or rendering artifacts

- [x] **T039** [P] Edge case test for overlapping layers in test/unit/rendering/edge_cases/overlapping_layers_test.dart
  - Create 3 layers with same screen space
  - Verify z-order preserved (visual validation via pixel comparison)
  - Test alpha blending correctness

- [x] **T040** [P] Edge case test for text overflow in test/unit/rendering/edge_cases/text_overflow_test.dart
  - Create label exceeding viewport bounds
  - Verify clipping applied (no off-screen rendering)
  - Verify no crashes

- [ ] **T041** [P] Edge case test for pool exhaustion in test/unit/rendering/edge_cases/pool_exhaustion_test.dart
  - Create layer that acquires 200 Paint objects (pool maxSize = 100)
  - Verify pool allocates beyond capacity (statistics show allocation count)
  - Verify performance degrades but no crash

- [ ] **T042** [P] Edge case test for cache overflow in test/unit/rendering/edge_cases/cache_overflow_test.dart
  - Create 1000 unique text/style combinations (cache maxSize = 500)
  - Verify LRU eviction works
  - Verify cache hit rate stabilizes
  - Verify no memory growth beyond maxSize

---

## Phase 3.9: Documentation & Polish (6 tasks)

- [ ] **T043** [P] Add dartdoc comments to all public APIs in lib/src/rendering/*.dart
  - Document RenderContext fields with usage examples
  - Document RenderLayer contract requirements
  - Document RenderPipeline lifecycle
  - Document PerformanceMonitor metrics interpretation
  - Document TextLayoutCache LRU behavior
  - Include @example annotations

- [ ] **T044** [P] Create rendering README in lib/src/rendering/README.md
  - Overview of rendering architecture
  - Quick start example (copy from quickstart.md)
  - Link to contracts, data model, spec
  - Performance targets and validation steps

- [ ] **T045** [P] Update main project README with rendering section
  - Add Core Rendering Engine to feature list
  - Link to spec, plan, tasks
  - Show usage example
  - List performance targets

- [ ] **T046** [P] Create manual testing guide in specs/002-core-rendering/manual-testing.md
  - Visual validation checklist (z-order, clipping, text rendering)
  - Performance validation steps (run benchmarks, check metrics)
  - Edge case testing scenarios (rapid pan, extreme zoom)
  - Screenshots of expected vs actual rendering

- [ ] **T047** [P] Update quickstart.md with final implementation paths
  - Verify all import paths correct (lib/src/rendering/*)
  - Verify all examples compile and run
  - Add troubleshooting section with common issues
  - Add performance validation checklist

- [ ] **T048** Validate all constitutional requirements and close feature
  - Run all tests: flutter test (expect 100% pass)
  - Run all benchmarks: verify targets met (<8ms avg, >90% pool hit, >70% cache hit)
  - Verify zero external dependencies (pubspec.yaml check)
  - Verify TDD compliance (all tests written before implementation)
  - Update plan.md Progress Tracking to 100% complete
  - Merge 002-core-rendering branch to main
  - Tag release: v0.2.0-rendering

---

## Dependencies

### Phase Order
1. **Setup (T001-T002)** → All other phases
2. **Contract Tests (T003-T005)** → Core Implementation (T010-T015)
3. **Integration Tests (T006-T009)** → Core Implementation (T010-T015)
4. **Core Implementation (T010-T015)** → Unit Tests (T016-T027)
5. **Unit Tests (T016-T027)** → Examples (T028-T030)
6. **Core Implementation (T010-T015)** → Benchmarks (T031-T036)
7. **Core Implementation (T010-T015)** → Edge Cases (T037-T042)
8. **All Implementation** → Documentation (T043-T048)

### Specific Task Dependencies
- **T012** (PerformanceMonitor) requires **T010** (PerformanceMetrics)
- **T013** (RenderContext) requires **T011** (TextLayoutCache), **T012** (PerformanceMonitor)
- **T015** (RenderPipeline) requires **T010, T011, T012, T013, T014** (all entities)
- **T016-T027** (Unit tests) require **T010-T015** (implementations)
- **T028-T030** (Example layers) require **T014, T015** (RenderLayer, RenderPipeline)
- **T031-T036** (Benchmarks) require **T010-T015** (implementations)
- **T037-T042** (Edge cases) require **T010-T015** (implementations)
- **T043-T047** (Documentation) require **T010-T030** (implementations + examples)
- **T048** (Validation) requires **ALL** previous tasks

### Blocking Chains
```
T001, T002 (Setup)
  ↓
T003, T004, T005 [P] (Contract tests)
T006, T007, T008, T009 [P] (Integration tests)
  ↓
T010 [P] (PerformanceMetrics)
T011 [P] (TextLayoutCache)
  ↓
T012 (PerformanceMonitor) - requires T010
T013 [P] (RenderContext) - requires T011, T012
T014 [P] (RenderLayer)
  ↓
T015 (RenderPipeline) - requires T010, T011, T012, T013, T014
  ↓
T016-T027 [P] (Unit tests)
T028-T030 [P] (Example layers)
T031-T036 [P] (Benchmarks)
T037-T042 [P] (Edge cases)
  ↓
T043-T047 [P] (Documentation)
  ↓
T048 (Final validation)
```

---

## Parallel Execution Examples

### Example 1: Contract Tests (Phase 3.2)
```
Task: "Contract test for RenderLayer interface in test/contract/rendering/render_layer_contract_test.dart"
Task: "Contract test for PerformanceMonitor interface in test/contract/rendering/performance_monitor_contract_test.dart"
Task: "Contract test for TextLayoutCache interface in test/contract/rendering/text_layout_cache_contract_test.dart"
```
**Rationale**: Different files, no shared dependencies, all test contracts independently.

### Example 2: Integration Tests (Phase 3.3)
```
Task: "Integration test for Scenario 1 (Stock Chart 10K) in test/integration/rendering/stock_chart_10k_test.dart"
Task: "Integration test for Scenario 2 (Multi-layer) in test/integration/rendering/multi_layer_chart_test.dart"
Task: "Integration test for Scenario 3 (Performance Dashboard) in test/integration/rendering/performance_dashboard_test.dart"
Task: "Integration test for Scenario 4 (Text-heavy) in test/integration/rendering/text_heavy_chart_test.dart"
```
**Rationale**: Different test files, each validates independent user scenario.

### Example 3: Entity Implementations (Phase 3.4 - Partial)
```
Task: "Implement PerformanceMetrics in lib/src/rendering/performance_metrics.dart"
Task: "Implement TextLayoutCache in lib/src/rendering/text_layout_cache.dart"
```
**Rationale**: No dependencies between PerformanceMetrics and TextLayoutCache.

**NOTE**: T012 (PerformanceMonitor) CANNOT run parallel with T010 (PerformanceMetrics) - requires T010 complete.

### Example 4: Unit Tests (Phase 3.5)
```
Task: "Unit test for PerformanceMetrics validation in test/unit/rendering/performance_metrics_test.dart"
Task: "Unit test for TextLayoutCache LRU eviction in test/unit/rendering/text_layout_cache_test.dart"
Task: "Unit test for PerformanceMonitor frame timing in test/unit/rendering/performance_monitor_test.dart"
Task: "Unit test for RenderContext validation in test/unit/rendering/render_context_test.dart"
Task: "Unit test for RenderLayer isEmpty optimization in test/unit/rendering/render_layer_test.dart"
```
**Rationale**: Different test files, test different entities independently.

### Example 5: Benchmarks (Phase 3.7)
```
Task: "Benchmark object pool performance in test/benchmarks/rendering/object_pool_benchmark.dart"
Task: "Benchmark viewport culling performance in test/benchmarks/rendering/viewport_culling_benchmark.dart"
Task: "Benchmark text layout caching in test/benchmarks/rendering/text_cache_benchmark.dart"
Task: "Benchmark RenderPipeline frame time in test/benchmarks/rendering/render_pipeline_benchmark.dart"
Task: "Benchmark layer z-ordering overhead in test/benchmarks/rendering/layer_sorting_benchmark.dart"
Task: "Benchmark empty layer short-circuit in test/benchmarks/rendering/empty_layer_benchmark.dart"
```
**Rationale**: Different benchmark files, measure independent performance aspects.

---

## Notes

### TDD Workflow
1. ✅ Write contract test (T003-T005) - **MUST FAIL** initially
2. ✅ Write integration test (T006-T009) - **MUST FAIL** initially
3. ✅ Implement entity (T010-T015) - Make tests **PASS**
4. ✅ Write unit tests (T016-T027) - Cover edge cases
5. ✅ Refactor - Improve code without breaking tests

### Performance Validation
- Run benchmarks after T015 (RenderPipeline) complete
- Targets: <8ms avg frame, <16ms p99, >90% pool hit, >70% cache hit
- If targets missed: Optimize, re-benchmark, repeat

### Commit Strategy
- Commit after each task or logical group
- Tag milestones: `v0.2.0-alpha` after T015, `v0.2.0-beta` after T042, `v0.2.0` after T048

### Code Review Checklist (Apply before T048)
- [ ] All tests pass (flutter test)
- [ ] All benchmarks meet targets
- [ ] Zero external dependencies (pubspec.yaml)
- [ ] Dartdoc comments on all public APIs
- [ ] No code duplication (DRY principle)
- [ ] SOLID principles followed
- [ ] Constitution compliance verified

---

## Task Generation Rules
*Applied during main() execution*

1. **From Contracts (3 files)**:
   - render_layer.dart → T003 (contract test), T014 (implementation)
   - performance_monitor.dart → T004 (contract test), T012 (implementation)
   - text_layout_cache.dart → T005 (contract test), T011 (implementation)

2. **From Data Model (6 entities)**:
   - RenderContext → T013 (implementation), T019 (unit test)
   - RenderLayer → T014 (implementation), T020 (unit test)
   - RenderPipeline → T015 (implementation), T021-T027 (unit tests)
   - PerformanceMonitor → T012 (implementation), T018 (unit test)
   - PerformanceMetrics → T010 (implementation), T016 (unit test)
   - TextLayoutCache → T011 (implementation), T017 (unit test)

3. **From User Scenarios (4 scenarios in spec.md)**:
   - Scenario 1 (Stock Chart 10K) → T006 (integration test)
   - Scenario 2 (Multi-layer) → T007 (integration test)
   - Scenario 3 (Performance Dashboard) → T008 (integration test)
   - Scenario 4 (Text-heavy) → T009 (integration test)

4. **From Quickstart (3 example layers)**:
   - GridLayer → T028 (implementation)
   - DataSeriesLayer → T029 (implementation)
   - AnnotationLayer → T030 (implementation)

5. **Ordering Applied**:
   - Setup (T001-T002) first
   - Tests before implementation (T003-T009 before T010-T015)
   - Dependencies resolved (T010 before T012, T010-T014 before T015)
   - Polish last (T043-T048)

---

## Validation Checklist
*GATE: Checked before execution*

- [x] All 3 contracts have corresponding tests (T003-T005)
- [x] All 6 entities have implementation tasks (T010-T015)
- [x] All 4 user scenarios have integration tests (T006-T009)
- [x] All tests come before implementation (T003-T009 before T010-T015)
- [x] Parallel tasks truly independent (verified file paths, no shared state)
- [x] Each task specifies exact file path (lib/src/rendering/*, test/*)
- [x] No task modifies same file as another [P] task
- [x] Dependencies explicitly documented (T012 requires T010, etc.)
- [x] TDD workflow enforced (contract tests fail initially, pass after implementation)
- [x] Performance targets defined in benchmarks (T031-T036)
- [x] Edge cases covered (T037-T042)
- [x] Documentation complete (T043-T048)

---

## Execution Status

**Total Tasks**: 48  
**Phases**: 9 (Setup, Contract Tests, Integration Tests, Core Implementation, Unit Tests, Examples, Benchmarks, Edge Cases, Documentation)  
**Estimated Time**: 2-4 weeks (per plan.md)  
**Dependencies**: Foundation Layer (001-foundation) COMPLETE ✅

**Next Step**: Execute T001 (Create rendering directory structure)

**Constitutional Compliance**:
- ✅ TDD: Tests (T003-T009) before implementation (T010-T015)
- ✅ Performance: Benchmarks (T031-T036) validate <8ms, >90% pool hit, >70% cache hit
- ✅ KISS: Reuses Foundation (ObjectPool, ViewportCuller), simple LRU cache
- ✅ Zero dependencies: No external packages, Dart stdlib only

**Ready for Execution**: ✅ SUCCESS
