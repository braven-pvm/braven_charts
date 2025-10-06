# Tasks: Chart Types

**Feature**: Chart Types (Layer 4)  
**Branch**: 005-chart-types  
**Input**: Design documents from `/specs/005-chart-types/`  
**Prerequisites**: plan.md ✓, research.md ✓, data-model.md ✓, contracts/ ✓, quickstart.md ✓

---

## Execution Flow (main)
```
1. Load plan.md from feature directory
   ✓ Loaded: Dart 3.10.0, Flutter 3.37.0, 4 chart types
   ✓ Tech stack: Pure Flutter (dart:ui, dart:math), no external packages
   ✓ Structure: lib/src/charts/{base,line,area,bar,scatter}/, test/charts/{contract,unit,integration,performance,golden}/
2. Load optional design documents:
   ✓ data-model.md: 18 models (4 configs, 7 enums, 4 supporting, 3 internal)
   ✓ contracts/: 5 files (chart_layer, line_chart_config, area_chart_config, bar_chart_config, scatter_chart_config)
   ✓ research.md: 10 technical decisions (bezier, pooling, caching, etc.)
   ✓ quickstart.md: 10 executable examples
3. Generate tasks by category:
   ✓ Setup: Project structure, barrel file
   ✓ Tests: 5 contract tests, 10 quickstart integration tests
   ✓ Core: 18 model implementations, 4 chart layers, 7 utility classes
   ✓ Integration: Theme, coordinate, animation tests
   ✓ Polish: Performance benchmarks, golden tests, documentation
4. Apply task rules:
   ✓ Different files = marked [P] for parallel
   ✓ Same file = sequential (no [P])
   ✓ Tests before implementation (TDD)
5. Number tasks sequentially (T001-T060)
6. Generate dependency graph
7. Create parallel execution examples
8. Validate task completeness:
   ✓ All 5 contracts have tests
   ✓ All 18 models have implementation tasks
   ✓ All 4 chart types implemented
   ✓ All 10 quickstart examples validated
9. Return: SUCCESS (61 tasks ready for execution)
```

---

## Format: `[ID] [P?] Description`
- **[P]**: Can run in parallel (different files, no dependencies)
- Include exact file paths in descriptions
- TDD: Tests MUST be written and MUST FAIL before implementation

---

## Phase 3.1: Setup & Structure
**Goal**: Create project directory structure and barrel file

- [x] **T001** Create chart types directory structure (lib/src/charts/{base,line,area,bar,scatter}/) ✅ 2025-10-06
- [x] **T002** Create test directory structure (test/charts/{contract,unit,integration,performance,golden}/) ✅ 2025-10-06
- [x] **T003** Create barrel file lib/src/charts/charts.dart (empty initially, export added incrementally) ✅ 2025-10-06

---

## Phase 3.2: Contract Tests (TDD Phase 1) ⚠️ MUST COMPLETE BEFORE 3.3
**CRITICAL: These tests MUST be written and MUST FAIL before ANY implementation**

### Configuration Validation Tests (Parallel)
- [x] **T004** [P] Create LineChartConfig contract test (test/charts/contract/line_chart_config_test.dart) - MUST FAIL ✅ 2025-01-06
  - Test markerSize > 0 (must throw)
  - Test lineWidth > 0 (must throw)
  - Test dashPattern even length (must throw if odd)
  - Test copyWith() creates new instance
  - Test validate() with valid config (must pass)

- [ ] **T005** [P] Contract test for AreaChartConfig validation in test/charts/contract/area_chart_config_test.dart
  - Test fillOpacity in [0.0, 1.0] (must throw if outside)
  - Test showLine implies lineConfig != null (must throw if violated)
  - Test copyWith() creates new instance
  - Test validate() with valid config (must pass)

- [ ] **T006** [P] Contract test for BarChartConfig validation in test/charts/contract/bar_chart_config_test.dart
  - Test barWidthRatio in (0.0, 1.0] (must throw if outside)
  - Test spacing >= 0 (must throw if negative)
  - Test useGradient implies gradientStart or gradientEnd (must throw if violated)
  - Test copyWith() creates new instance
  - Test validate() with valid config (must pass)

- [ ] **T007** [P] Contract test for ScatterChartConfig validation in test/charts/contract/scatter_chart_config_test.dart
  - Test fixed sizing requires fixedSize > 0 (must throw)
  - Test data-driven sizing requires minSize < maxSize (must throw if violated)
  - Test clusterThreshold >= 2 (must throw if less)
  - Test copyWith() creates new instance
  - Test validate() with valid config (must pass)

### Chart Layer Interface Test
- [ ] **T008** Contract test for ChartLayer interface in test/charts/contract/chart_layer_contract_test.dart
  - Test all chart types implement render() correctly
  - Test all chart types implement shouldRender() correctly
  - Test all chart types implement updateData() correctly
  - Test all chart types implement prepare() correctly
  - Test all chart types implement dispose() correctly
  - **Note**: Will initially fail until chart layers implemented

---

## Phase 3.3: Core Models (TDD Phase 2) - ONLY after contract tests are failing

### Enums (Parallel - Independent)
- [ ] **T009** [P] Implement LineStyle enum in lib/src/charts/line/line_chart_config.dart (straight, smooth, stepped)
- [ ] **T010** [P] Implement MarkerShape enum in lib/src/charts/base/chart_config.dart (circle, square, triangle, diamond, cross, plus, none)
- [ ] **T011** [P] Implement AreaFillStyle enum in lib/src/charts/area/area_chart_config.dart (solid, gradient, pattern)
- [ ] **T012** [P] Implement AreaBaselineType enum in lib/src/charts/area/area_chart_config.dart (zero, fixed, series)
- [ ] **T013** [P] Implement BarOrientation enum in lib/src/charts/bar/bar_chart_config.dart (vertical, horizontal)
- [ ] **T014** [P] Implement BarGroupingMode enum in lib/src/charts/bar/bar_chart_config.dart (grouped, stacked)
- [ ] **T015** [P] Implement MarkerSizingMode enum in lib/src/charts/scatter/scatter_chart_config.dart (fixed, dataDriven)
- [ ] **T016** [P] Implement MarkerStyle enum in lib/src/charts/scatter/scatter_chart_config.dart (filled, outlined, both)

### Supporting Models (Parallel - Independent)
- [ ] **T017** [P] Implement AreaBaseline class in lib/src/charts/area/area_chart_config.dart
  - Fields: AreaBaselineType type, double? fixedValue, String? seriesId
  - Validation in constructor
  - Immutable with copyWith()

- [ ] **T018** [P] Implement ChartAnimationConfig class in lib/src/charts/base/chart_config.dart
  - Fields: bool enabled, Duration duration, Curve curve, double changeThreshold
  - Immutable with copyWith()
  - Default values: enabled=true, duration=300ms, curve=Curves.easeInOut, changeThreshold=0.01

- [ ] **T019** [P] Implement ChartSeriesStyle class in lib/src/charts/base/chart_config.dart
  - Fields: Color? color, double? lineWidth, double? markerSize, double? fillOpacity, double? barWidthRatio
  - Immutable with copyWith()
  - Used for per-series overrides

### Configuration Classes (Sequential - Depend on enums)
- [ ] **T020** Implement LineChartConfig class in lib/src/charts/line/line_chart_config.dart
  - All fields from data-model.md
  - Validation in constructor (markerSize > 0, lineWidth > 0, dashPattern even)
  - Immutable with copyWith()
  - validate() method
  - **Must pass T004 tests**

- [ ] **T021** Implement AreaChartConfig class in lib/src/charts/area/area_chart_config.dart
  - All fields from data-model.md
  - Validation in constructor (fillOpacity [0,1], showLine implies lineConfig)
  - Immutable with copyWith()
  - validate() method
  - **Must pass T005 tests**

- [ ] **T022** Implement BarChartConfig class in lib/src/charts/bar/bar_chart_config.dart
  - All fields from data-model.md
  - Validation in constructor (barWidthRatio (0,1], spacing >= 0, useGradient implies colors)
  - Immutable with copyWith()
  - validate() method
  - **Must pass T006 tests**

- [ ] **T023** Implement ScatterChartConfig class in lib/src/charts/scatter/scatter_chart_config.dart
  - All fields from data-model.md
  - Validation in constructor (sizing constraints, clusterThreshold >= 2)
  - Immutable with copyWith()
  - validate() method
  - **Must pass T007 tests**

### Internal Models (Parallel - Independent)
- [ ] **T024** [P] Implement InterpolatedPoint class in lib/src/charts/line/line_interpolator.dart
  - Fields: Offset position, Offset? controlPoint1, Offset? controlPoint2, bool isControlPoint
  - Used internally by line interpolator for bezier curves

- [ ] **T025** [P] Implement BarLayoutInfo class in lib/src/charts/bar/bar_positioner.dart
  - Fields: String seriesId, int categoryIndex, Rect bounds, double value, bool isNegative
  - Used internally by bar positioner

- [ ] **T026** [P] Implement ClusterInfo class in lib/src/charts/scatter/scatter_clusterer.dart
  - Fields: Offset center, int pointCount, List<int> pointIndices, double radius
  - Used internally by scatter clusterer

---

## Phase 3.4: Utility Algorithms (TDD Phase 3)

### Unit Tests for Algorithms (Parallel)
- [ ] **T027** [P] Unit test for LineInterpolator in test/charts/unit/line_interpolator_test.dart
  - Test straight line produces linear path
  - Test smooth line produces bezier curves (Catmull-Rom algorithm)
  - Test stepped line produces horizontal-vertical segments
  - Test path caching optimization

- [ ] **T028** [P] Unit test for AreaStacking in test/charts/unit/area_stacking_test.dart
  - Test cumulative stacking for positive values
  - Test handling negative values (separate stacks)
  - Test baseline calculation (zero, fixed, series)

- [ ] **T029** [P] Unit test for BarPositioner in test/charts/unit/bar_positioner_test.dart
  - Test grouped bar positioning (side-by-side with spacing)
  - Test stacked bar positioning (cumulative)
  - Test negative value handling in stacks

- [ ] **T030** [P] Unit test for ScatterClusterer in test/charts/unit/scatter_clusterer_test.dart
  - Test clustering algorithm for dense points
  - Test cluster threshold parameter
  - Test no clustering when disabled

- [ ] **T031** [P] Unit test for ChartRenderer (markers, gradients) in test/charts/unit/chart_renderer_test.dart
  - Test all 6 marker shapes render correctly
  - Test gradient shader caching
  - Test object pooling for marker paths

### Algorithm Implementations (Parallel)
- [ ] **T032** [P] Implement LineInterpolator in lib/src/charts/line/line_interpolator.dart
  - Straight: Linear path between points
  - Smooth: Catmull-Rom to cubic bezier conversion (algorithm from research.md)
  - Stepped: Horizontal then vertical segments
  - Path caching optimization
  - **Must pass T027 tests**

- [ ] **T033** [P] Implement AreaStacking in lib/src/charts/area/area_stacking.dart
  - Cumulative stacking algorithm
  - Negative value handling (separate stacks)
  - Baseline calculation (zero/fixed/series modes)
  - **Must pass T028 tests**

- [ ] **T034** [P] Implement BarPositioner in lib/src/charts/bar/bar_positioner.dart
  - Grouped bar algorithm (side-by-side with spacing)
  - Stacked bar algorithm (cumulative with negatives)
  - Algorithms from research.md
  - **Must pass T029 tests**

- [ ] **T035** [P] Implement ScatterClusterer in lib/src/charts/scatter/scatter_clusterer.dart
  - Optional clustering for dense data (>clusterThreshold points in radius)
  - K-means or grid-based clustering
  - Cluster info calculation
  - **Must pass T030 tests**

- [ ] **T036** [P] Implement ChartRenderer (shared utilities) in lib/src/charts/base/chart_renderer.dart
  - MarkerRenderer: 6 shapes with object pooling (from research.md)
  - GradientRenderer: Shader caching
  - Path pooling integration
  - **Must pass T031 tests**

---

## Phase 3.5: Chart Layer Implementations (TDD Phase 4)

### Chart Layer Tests (Sequential - Depend on utilities)
- [ ] **T037** Implement LineChartLayer in lib/src/charts/line/line_chart_layer.dart
  - Extends ChartLayer (from lib/src/charts/base/chart_layer.dart)
  - Uses LineInterpolator for path generation
  - Uses ChartRenderer for marker rendering
  - Viewport culling integration
  - Theme integration (automatic color cycling)
  - Animation support (diff-based lerp)
  - **Must pass T008 contract tests**

- [ ] **T038** Implement AreaChartLayer in lib/src/charts/area/area_chart_layer.dart
  - Extends ChartLayer
  - Uses AreaStacking for multi-series
  - Uses ChartRenderer for gradient fills
  - Viewport culling integration
  - Theme integration
  - Animation support
  - **Must pass T008 contract tests**

- [ ] **T039** Implement BarChartLayer in lib/src/charts/bar/bar_chart_layer.dart
  - Extends ChartLayer
  - Uses BarPositioner for layout
  - Supports vertical/horizontal orientation
  - Supports grouped/stacked modes
  - Rounded corners, borders, gradients
  - Theme integration
  - Animation support
  - **Must pass T008 contract tests**

- [ ] **T040** Implement ScatterChartLayer in lib/src/charts/scatter/scatter_chart_layer.dart
  - Extends ChartLayer
  - Uses ScatterClusterer (optional)
  - Uses ChartRenderer for marker rendering
  - Fixed-size and data-driven sizing modes
  - Viewport culling integration
  - Theme integration
  - Animation support
  - **Must pass T008 contract tests**

- [ ] **T041** Implement ChartLayer base class in lib/src/charts/base/chart_layer.dart
  - Extends RenderLayer from Core Rendering Engine
  - Common properties: series, theme, animationConfig
  - Common methods: render(), shouldRender(), updateData(), prepare(), dispose()
  - Animation controller for data updates
  - **Blocks T037-T040**

---

## Phase 3.6: Integration Tests
**Goal**: Validate layer interactions and system integration

- [ ] **T042** [P] Integration test for multi-series rendering in test/charts/integration/multi_series_rendering_test.dart
  - Test all 4 chart types with 3+ series
  - Verify distinct colors from theme
  - Verify correct z-ordering
  - From quickstart.md Example 2

- [ ] **T043** [P] Integration test for theme integration in test/charts/integration/theme_integration_test.dart
  - Test automatic color cycling
  - Test line width from SeriesTheme
  - Test theme changes without recreation
  - Test per-series style overrides

- [ ] **T044** [P] Integration test for coordinate transformations in test/charts/integration/coordinate_transform_test.dart
  - Test data-to-screen transformations
  - Test pan/zoom updates
  - Test viewport culling with UniversalCoordinateTransformer

- [ ] **T045** [P] Integration test for animations in test/charts/integration/animation_test.dart
  - Test smooth data updates (diff-based lerp)
  - Test 60 FPS maintained during transitions
  - Test animation disabled mode (immediate updates)
  - From quickstart.md Example 9

---

## Phase 3.7: Quickstart Validation Tests
**Goal**: Validate all 10 quickstart examples execute correctly

- [ ] **T046** [P] Quickstart Example 1: Basic line chart in test/charts/integration/quickstart_01_basic_line_test.dart
  - Straight lines, circle markers, 5 points
  - Verify no errors during rendering

- [ ] **T047** [P] Quickstart Example 2: Smooth multi-series line in test/charts/integration/quickstart_02_smooth_multi_series_test.dart
  - Bezier curves, 2 series, 10 points each
  - Verify distinct colors from theme

- [ ] **T048** [P] Quickstart Example 3: Area chart with gradient in test/charts/integration/quickstart_03_area_gradient_test.dart
  - Vertical gradient fill, smooth line overlay, 5 points
  - Verify gradient shader applied

- [ ] **T049** [P] Quickstart Example 4: Stacked area chart in test/charts/integration/quickstart_04_stacked_area_test.dart
  - 3 series stacked, composition visualization
  - Verify cumulative stacking algorithm

- [ ] **T050** [P] Quickstart Example 5: Grouped bar chart in test/charts/integration/quickstart_05_grouped_bars_test.dart
  - Vertical, side-by-side, 2 series, 3 categories
  - Verify bar spacing and positioning

- [ ] **T051** [P] Quickstart Example 6: Stacked bars with negatives in test/charts/integration/quickstart_06_stacked_bars_negatives_test.dart
  - Income/expenses with negative values
  - Verify negative value handling in stacks

- [ ] **T052** [P] Quickstart Example 7: Scatter fixed-size in test/charts/integration/quickstart_07_scatter_fixed_test.dart
  - 50 random points, 6px circles, filled style
  - Verify fixed marker sizing

- [ ] **T053** [P] Quickstart Example 8: Scatter data-driven sizing in test/charts/integration/quickstart_08_scatter_data_driven_test.dart
  - 4 points with metadata['size']
  - Verify marker size represents third variable

- [ ] **T054** [P] Quickstart Example 9: Animated updates in test/charts/integration/quickstart_09_animated_updates_test.dart
  - 300ms transition between datasets
  - Verify smooth lerp animation
  - Already covered by T045 (can combine)

- [ ] **T055** [P] Quickstart Example 10: Performance test in test/charts/performance/quickstart_10_performance_test.dart
  - 10,000 points rendered in <16ms
  - Verify 60 FPS requirement
  - Already covered by T056-T059 (can combine)

---

## Phase 3.8: Performance Benchmarks (Constitutional Requirement)
**Goal**: Validate <16ms frame time for all chart types

- [ ] **T056** [P] Performance benchmark for LineChartLayer in test/charts/performance/line_chart_benchmark.dart
  - 10,000 points, all 3 line styles (straight, smooth, stepped)
  - Stopwatch measurement: <16ms required
  - All 6 marker shapes
  - Constitutional requirement from FR-009

- [ ] **T057** [P] Performance benchmark for AreaChartLayer in test/charts/performance/area_chart_benchmark.dart
  - 10,000 points, all 3 fill styles (solid, gradient, pattern)
  - Stopwatch measurement: <16ms required
  - Stacked mode with 3 series
  - Constitutional requirement from FR-015

- [ ] **T058** [P] Performance benchmark for BarChartLayer in test/charts/performance/bar_chart_benchmark.dart
  - 1,000 bars, both orientations (vertical, horizontal)
  - Both grouping modes (grouped, stacked)
  - Stopwatch measurement: <16ms required
  - Constitutional requirement from FR-023

- [ ] **T059** [P] Performance benchmark for ScatterChartLayer in test/charts/performance/scatter_chart_benchmark.dart
  - 10,000 points, all 6 marker shapes
  - Both sizing modes (fixed, data-driven)
  - With and without clustering
  - Stopwatch measurement: <16ms required
  - Constitutional requirement from FR-029

- [ ] **T060** [P] Performance benchmark for viewport culling in test/charts/performance/viewport_culling_benchmark.dart
  - Measure culling overhead: <1ms required
  - Test with 10,000 points across all chart types
  - Constitutional requirement from FR-034

- [ ] **T061** [P] Performance benchmark for object pooling in test/charts/performance/object_pooling_benchmark.dart
  - Measure pool hit rate: >90% required
  - Test Paint/Path pooling during rendering
  - Constitutional requirement (Performance First principle)

---

## Phase 3.9: Visual Regression Tests (Golden Tests)
**Goal**: Ensure UI consistency across changes

- [ ] **T062** [P] Golden test for line charts in test/charts/golden/line_chart_golden_test.dart
  - All 3 line styles (straight, smooth, stepped)
  - All 6 marker shapes
  - Multi-series with distinct colors
  - Edge cases: empty data, single point, null values

- [ ] **T063** [P] Golden test for area charts in test/charts/golden/area_chart_golden_test.dart
  - All 3 fill styles (solid, gradient, pattern)
  - Stacked mode (3 series)
  - All baseline types (zero, fixed, series)
  - Edge cases: negative values, single point

- [ ] **T064** [P] Golden test for bar charts in test/charts/golden/bar_chart_golden_test.dart
  - Both orientations (vertical, horizontal)
  - Both grouping modes (grouped, stacked)
  - With rounded corners, borders, gradients
  - Edge cases: negative values, zero values

- [ ] **T065** [P] Golden test for scatter plots in test/charts/golden/scatter_chart_golden_test.dart
  - All 6 marker shapes
  - All 3 marker styles (filled, outlined, both)
  - Both sizing modes (fixed, data-driven)
  - With clustering enabled

---

## Phase 3.10: Documentation & Polish
**Goal**: Complete documentation and cleanup

- [ ] **T066** Update barrel file lib/src/charts/charts.dart
  - Export all public APIs
  - Export: LineChartLayer, AreaChartLayer, BarChartLayer, ScatterChartLayer
  - Export: LineChartConfig, AreaChartConfig, BarChartConfig, ScatterChartConfig
  - Export: LineStyle, MarkerShape, AreaFillStyle, AreaBaselineType, BarOrientation, BarGroupingMode, MarkerSizingMode, MarkerStyle
  - Export: ChartAnimationConfig, ChartSeriesStyle

- [ ] **T067** [P] Add DartDoc comments to all public APIs in lib/src/charts/
  - Document all classes, methods, properties
  - Include usage examples in doc comments
  - Document performance requirements
  - Document validation rules

- [ ] **T068** [P] Add algorithm explanations in code comments
  - Bezier interpolation algorithm (line_interpolator.dart)
  - Bar positioning algorithm (bar_positioner.dart)
  - Stacking algorithm (area_stacking.dart)
  - Gradient shader caching (chart_renderer.dart)

- [ ] **T069** [P] Update main README.md with chart types examples
  - Add "Chart Types" section
  - Include code snippets for all 4 chart types
  - Link to quickstart.md
  - Show visual examples (screenshots or ASCII art)

- [ ] **T070** [P] Create usage guide in docs/guides/chart-types.md
  - "Getting Started" section
  - "Line Charts" section with all styles
  - "Area Charts" section with stacking
  - "Bar Charts" section with grouping modes
  - "Scatter Plots" section with sizing modes
  - "Animations" section with data updates
  - "Performance" section with optimization tips

- [ ] **T071** Code cleanup and refactoring
  - Remove any code duplication
  - Ensure SOLID principles followed
  - Verify no unused imports
  - Run dart format on all files
  - Run dart analyze --fatal-infos

- [ ] **T072** Final validation
  - All tests passing (contract, unit, integration, performance, golden)
  - All performance benchmarks meeting constitutional requirements
  - 100% test coverage verified
  - Documentation complete
  - No linter warnings or errors
  - Ready for merge to main

---

## Dependencies

### Critical Path (Sequential)
1. **T001-T003** (Setup) → ALL OTHER TASKS
2. **T004-T008** (Contract tests) → **T009-T026** (Models)
3. **T009-T026** (Models) → **T027-T036** (Algorithms)
4. **T027-T036** (Algorithms) → **T041** (Base ChartLayer)
5. **T041** (Base ChartLayer) → **T037-T040** (Chart implementations)
6. **T037-T040** (Chart implementations) → **T042-T072** (Integration, validation, polish)

### Parallel Execution Groups
- **Group 1** (T004-T007): All config contract tests
- **Group 2** (T009-T016): All enum implementations
- **Group 3** (T017-T019): All supporting models
- **Group 4** (T024-T026): All internal models
- **Group 5** (T027-T031): All algorithm unit tests
- **Group 6** (T032-T036): All algorithm implementations
- **Group 7** (T042-T045): All integration tests
- **Group 8** (T046-T055): All quickstart validation tests
- **Group 9** (T056-T061): All performance benchmarks
- **Group 10** (T062-T065): All golden tests
- **Group 11** (T067-T070): All documentation tasks

---

## Parallel Execution Examples

### Example 1: Contract Tests (Group 1)
```bash
# Launch T004-T007 together (different files, no dependencies):
Task: "Contract test for LineChartConfig validation in test/charts/contract/line_chart_config_test.dart"
Task: "Contract test for AreaChartConfig validation in test/charts/contract/area_chart_config_test.dart"
Task: "Contract test for BarChartConfig validation in test/charts/contract/bar_chart_config_test.dart"
Task: "Contract test for ScatterChartConfig validation in test/charts/contract/scatter_chart_config_test.dart"
```

### Example 2: Enum Implementations (Group 2)
```bash
# Launch T009-T016 together (different enums, independent):
Task: "Implement LineStyle enum in lib/src/charts/line/line_chart_config.dart"
Task: "Implement MarkerShape enum in lib/src/charts/base/chart_config.dart"
Task: "Implement AreaFillStyle enum in lib/src/charts/area/area_chart_config.dart"
Task: "Implement AreaBaselineType enum in lib/src/charts/area/area_chart_config.dart"
Task: "Implement BarOrientation enum in lib/src/charts/bar/bar_chart_config.dart"
Task: "Implement BarGroupingMode enum in lib/src/charts/bar/bar_chart_config.dart"
Task: "Implement MarkerSizingMode enum in lib/src/charts/scatter/scatter_chart_config.dart"
Task: "Implement MarkerStyle enum in lib/src/charts/scatter/scatter_chart_config.dart"
```

### Example 3: Algorithm Unit Tests (Group 5)
```bash
# Launch T027-T031 together (different test files):
Task: "Unit test for LineInterpolator in test/charts/unit/line_interpolator_test.dart"
Task: "Unit test for AreaStacking in test/charts/unit/area_stacking_test.dart"
Task: "Unit test for BarPositioner in test/charts/unit/bar_positioner_test.dart"
Task: "Unit test for ScatterClusterer in test/charts/unit/scatter_clusterer_test.dart"
Task: "Unit test for ChartRenderer in test/charts/unit/chart_renderer_test.dart"
```

### Example 4: Performance Benchmarks (Group 9)
```bash
# Launch T056-T061 together (different benchmark files):
Task: "Performance benchmark for LineChartLayer in test/charts/performance/line_chart_benchmark.dart"
Task: "Performance benchmark for AreaChartLayer in test/charts/performance/area_chart_benchmark.dart"
Task: "Performance benchmark for BarChartLayer in test/charts/performance/bar_chart_benchmark.dart"
Task: "Performance benchmark for ScatterChartLayer in test/charts/performance/scatter_chart_benchmark.dart"
Task: "Performance benchmark for viewport culling in test/charts/performance/viewport_culling_benchmark.dart"
Task: "Performance benchmark for object pooling in test/charts/performance/object_pooling_benchmark.dart"
```

---

## Validation Checklist
*GATE: Checked before marking feature complete*

- [x] All 5 contracts have corresponding tests (T004-T008)
- [x] All 18 models have implementation tasks (T009-T026)
- [x] All 4 chart types have implementation tasks (T037-T040)
- [x] All contract tests come before implementation (T004-T008 before T009-T041)
- [x] All unit tests come before algorithms (T027-T031 before T032-T036)
- [x] Parallel tasks truly independent (different files, verified)
- [x] Each task specifies exact file path
- [x] No task modifies same file as another [P] task
- [x] All 45 functional requirements mapped to tasks
- [x] All 10 quickstart examples have validation tests (T046-T055)
- [x] All performance benchmarks included (T056-T061)
- [x] Visual regression tests included (T062-T065)
- [x] Documentation tasks included (T066-T070)

---

## Functional Requirements Coverage

**All 45 FRs mapped to tasks**:

- **FR-001 to FR-004** (Chart type support): T037-T040 (chart layer implementations)
- **FR-005 to FR-009** (Line chart): T009, T020, T027, T032, T037, T056 (enum, config, test, interpolator, layer, benchmark)
- **FR-010 to FR-015** (Area chart): T011, T012, T017, T021, T028, T033, T038, T057 (enums, baseline, config, test, stacking, layer, benchmark)
- **FR-016 to FR-023** (Bar chart): T013, T014, T022, T029, T034, T039, T058 (enums, config, test, positioner, layer, benchmark)
- **FR-024 to FR-029** (Scatter chart): T015, T016, T023, T030, T035, T040, T059 (enums, config, test, clusterer, layer, benchmark)
- **FR-030 to FR-034** (Common features): T042 (multi-series), T043 (theming), T044 (transforms), T060 (culling)
- **FR-035 to FR-039** (Animation): T018, T041, T045 (config, base layer, integration test)
- **FR-040 to FR-045** (Performance): T056-T061 (all performance benchmarks)

---

## Notes

- **TDD Enforcement**: Contract tests (T004-T008) MUST be written and MUST FAIL before ANY model implementation
- **Commit Strategy**: Commit after each logical milestone (all enums, all configs, each chart layer, etc.)
- **[P] Tasks**: Can run in parallel - different files, no shared dependencies
- **Sequential Tasks**: Must run in order - same file or dependency relationship
- **Constitutional Compliance**: Performance benchmarks (T056-T061) are NON-NEGOTIABLE - must pass before merge
- **Test Coverage**: Target 100% coverage, minimum 90% required
- **Update this file**: After EVERY completed task, mark checkbox and add completion date/notes

---

## Progress Tracking

**Status**: Ready for execution  
**Total Tasks**: 72  
**Completed**: 0  
**In Progress**: 0  
**Blocked**: 0

**Last Updated**: 2025-10-06  
**Next Action**: Begin T001 (Create directory structure)

---

## Changelog

### 2025-10-06
- Initial tasks.md generated from design documents
- 72 tasks defined across 10 phases
- All 45 functional requirements mapped
- All 10 quickstart examples validated
- Constitutional requirements enforced (performance benchmarks)
