
# Implementation Plan: Chart Types

**Branch**: `005-chart-types` | **Date**: 2025-10-06 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/005-chart-types/spec.md`

## Execution Flow (/plan command scope)
```
1. Load feature spec from Input path
   ✓ Loaded spec.md with 45 FRs, 5 user scenarios, 4 chart types
2. Fill Technical Context (scan for NEEDS CLARIFICATION)
   ✓ Project Type: Single Flutter library (web-first)
   ✓ All technical aspects clear from constitution and architecture docs
   ✓ Foundation (Layer 0), Rendering (Layer 1), Coordinates (Layer 2), Theming (Layer 3) all implemented
3. Fill the Constitution Check section
   ✓ Constitutional requirements analyzed
4. Evaluate Constitution Check section below
   ✓ No violations detected - design aligns with principles
   ✓ Update Progress Tracking: Initial Constitution Check PASS
5. Execute Phase 0 → research.md
   ✓ Completed - rendering algorithms, interpolation methods, animation patterns documented
6. Execute Phase 1 → contracts, data-model.md, quickstart.md
   ✓ Completed - 4 chart configs, 8 contracts, quickstart examples defined
7. Re-evaluate Constitution Check section
   ✓ No new violations after design
   ✓ Update Progress Tracking: Post-Design Constitution Check PASS
8. Plan Phase 2 → Task generation approach defined
9. STOP - Ready for /tasks command
```

**IMPORTANT**: The /plan command STOPS at step 9. Phases 2-4 are executed by other commands:
- Phase 2: /tasks command creates tasks.md
- Phase 3-4: Implementation execution (manual or via tools)

## Summary

The Chart Types layer provides **four core chart implementations** (Line, Area, Bar, Scatter) that transform data into visual representations using all foundation layers. Each chart type is implemented as a specialized RenderLayer with unique rendering algorithms, supporting multi-series data, real-time updates with animations, and maintaining 60 FPS performance with 10,000+ data points.

**Technical Approach** (from research):
- Chart types as RenderLayers for composability and z-ordering
- Bezier curve interpolation for smooth line charts (Catmull-Rom algorithm)
- Gradient shader optimization for area charts (cached shader creation)
- Bar positioning algorithms with configurable spacing (grouped/stacked modes)
- Marker shape rendering with object pooling (6 shapes: circle, square, triangle, diamond, cross, plus)
- Diff-based animation system for data updates (lerp between old/new values)
- Viewport culling integration for performance (<1ms overhead)
- Automatic theme integration (colors, line widths from SeriesTheme)

## Technical Context
**Language/Version**: Dart 3.10.0-227.0.dev  
**Primary Dependencies**: Flutter SDK 3.37.0-1.0.pre-216, Standard Dart libraries (dart:ui, dart:math for bezier/interpolation)  
**Storage**: N/A (stateless rendering, data provided by caller)  
**Testing**: Flutter test framework, contract tests, performance benchmarks, visual regression tests  
**Target Platform**: Flutter Web (primary), iOS/Android (secondary)  
**Project Type**: Single Flutter library  
**Performance Goals**: Line/Area <16ms for 10K points, Bar <16ms for 1K bars, Scatter <16ms for 10K points, 60 FPS during animations  
**Constraints**: No external packages, pure Flutter implementation, viewport culling <1ms overhead, >90% object pool hit rate  
**Scale/Scope**: 4 chart types, 3 line styles, 6 marker shapes, 3 fill styles, 2 orientations, 2 grouping modes, 100% test coverage requirement

**User Input Context**: 
- **Foundation Layer** (001-foundation): Provides ChartSeries, ChartDataPoint, ObjectPool, ViewportCuller, interpolation utilities
- **Core Rendering Engine** (002-core-rendering): Provides RenderLayer interface, RenderPipeline, Paint/Path pooling, RenderContext
- **Coordinate System** (003-coordinate-system): Provides UniversalCoordinateTransformer for data-to-screen transformations
- **Theming System** (004-theming-system): Provides ChartTheme, SeriesTheme (colors, line widths), AnimationTheme

## Constitution Check
*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

### I. Architectural Integrity (Pure Flutter)
✅ **PASS** - Pure Dart/Flutter implementation
- Uses only dart:ui (Canvas, Paint, Path), dart:math (bezier calculations, trigonometry for markers)
- No HTML elements or web-specific APIs
- Integrates cleanly with Foundation Layer (ChartSeries, ObjectPool, ViewportCuller), Core Rendering (RenderLayer, RenderPipeline), Coordinate System (UniversalCoordinateTransformer), Theming (ChartTheme, SeriesTheme)
- Clean separation: ChartLayer (base), LineChartLayer/AreaChartLayer/BarChartLayer/ScatterChartLayer (implementations), ChartRenderer (shared utilities), LineChartConfig/AreaChartConfig/BarChartConfig/ScatterChartConfig (configuration)
- No circular dependencies: Depends on Layers 0-3, consumed by future layers (Interaction, Annotation)

### II. Performance First (60fps Target)
✅ **PASS** - Performance-optimized design
- <16ms frame time for all chart types (Line/Area: 10K points, Bar: 1K bars, Scatter: 10K points)
- Viewport culling integration with <1ms overhead (reuse Foundation's ViewportCuller)
- Object pooling for Paint/Path objects with >90% hit rate target
- Zero allocations during rendering (pre-allocated buffers, pooled objects)
- Bezier curve caching for smooth lines (compute once, reuse until data changes)
- Gradient shader caching for area fills (create once per gradient config)
- Diff-based animation updates (only animate changed data points)
- Performance benchmarks for each chart type (automated tests)

### III. Testing Excellence (NON-NEGOTIABLE)
✅ **PASS** - Comprehensive test strategy
- TDD approach: Contract tests → Unit tests → Integration tests → Performance benchmarks → Implementation
- 100% coverage target: All 4 chart types, all styles (3 line, 3 fill), all markers (6 shapes), all modes (2 orientations, 2 grouping)
- Contract tests: All RenderLayer interface methods, configuration validation
- Unit tests: Bezier interpolation, marker rendering, bar positioning, stacking algorithms
- Integration tests: Multi-series rendering, theme application, coordinate transformations
- Performance benchmarks: Frame time measurements for each chart type at scale
- Visual regression tests: Golden tests for all chart types, styles, and edge cases
- Animation tests: Smooth transitions, 60 FPS maintained during updates

### IV. Requirements Compliance (NON-NEGOTIABLE)
✅ **PASS** - Specification-driven implementation
- All 45 functional requirements (FR-001 to FR-045) mapped to implementation tasks
- tasks.md will document every requirement with corresponding tasks
- Deviations will be explicitly acknowledged in tasks.md changelog with rationale
- Update tasks.md after EVERY completed task

### V. API Consistency & Stability
✅ **PASS** - Consistent API design
- All chart types implement RenderLayer interface (consistent render() method)
- Configuration objects follow consistent naming: LineChartConfig, AreaChartConfig, BarChartConfig, ScatterChartConfig
- All configs use copyWith() pattern for immutability
- Marker shapes enum shared across line and scatter charts
- Consistent multi-series API (List<ChartSeries> for all chart types)
- Theme application automatic and consistent (no manual color management)

### VI. Documentation Discipline
✅ **PASS** - Comprehensive documentation planned
- All public APIs documented with DartDoc comments
- Code comments explain "why" for complex algorithms (bezier interpolation, bar positioning, stacking)
- Rendering pipeline documented with coordinate transformation flow
- Architecture Decision Records for chart type selection and rendering approach
- Usage examples in quickstart.md for all 4 chart types
- Visual examples showing all styles, markers, and modes

### VII. Simplicity & Pragmatism (KISS)
✅ **PASS** - Simple, focused design
- Lowest level implementation: Canvas.drawPath for lines, Canvas.drawRect for bars, Canvas.drawCircle/drawPath for markers
- SOLID principles: Single Responsibility (one class per chart type), Open-Closed (RenderLayer extension), Interface Segregation (focused configs)
- No premature optimization: Start with straightforward algorithms, optimize if benchmarks show need
- Complexity justified: Bezier curves for smooth lines (user requirement), viewport culling (performance requirement)
- No over-engineering: 4 chart types cover 80% of use cases, avoid feature creep

## Project Structure

### Documentation (this feature)
```
specs/005-chart-types/
├── plan.md              # This file (/plan command output)
├── research.md          # Phase 0 output (/plan command)
├── data-model.md        # Phase 1 output (/plan command)
├── quickstart.md        # Phase 1 output (/plan command)
├── contracts/           # Phase 1 output (/plan command)
└── tasks.md             # Phase 2 output (/tasks command - NOT created by /plan)
```

### Source Code (repository root)
```
lib/src/charts/
├── base/
│   ├── chart_layer.dart           # Base class for all chart layers (extends RenderLayer)
│   ├── chart_config.dart          # Base configuration class
│   └── chart_renderer.dart        # Shared rendering utilities (markers, gradients)
├── line/
│   ├── line_chart_layer.dart      # Line chart RenderLayer implementation
│   ├── line_chart_config.dart     # Line chart configuration
│   ├── line_interpolator.dart     # Bezier/stepped interpolation algorithms
│   └── line_marker_renderer.dart  # Point marker rendering
├── area/
│   ├── area_chart_layer.dart      # Area chart RenderLayer implementation
│   ├── area_chart_config.dart     # Area chart configuration
│   ├── area_fill_renderer.dart    # Fill/gradient rendering
│   └── area_stacking.dart         # Stacking algorithm for multiple series
├── bar/
│   ├── bar_chart_layer.dart       # Bar chart RenderLayer implementation
│   ├── bar_chart_config.dart      # Bar chart configuration
│   ├── bar_positioner.dart        # Bar positioning (grouped/stacked)
│   └── bar_renderer.dart          # Bar drawing (rounded corners, gradients)
├── scatter/
│   ├── scatter_chart_layer.dart   # Scatter chart RenderLayer implementation
│   ├── scatter_chart_config.dart  # Scatter chart configuration
│   ├── scatter_marker_renderer.dart  # Marker shape rendering
│   └── scatter_clusterer.dart     # Optional clustering for dense data
└── charts.dart                    # Barrel file exporting all chart types

test/charts/
├── contract/
│   ├── chart_layer_contract_test.dart      # RenderLayer interface compliance
│   ├── line_chart_config_test.dart         # Config validation tests
│   ├── area_chart_config_test.dart
│   ├── bar_chart_config_test.dart
│   └── scatter_chart_config_test.dart
├── unit/
│   ├── line_interpolator_test.dart         # Bezier/stepped algorithm tests
│   ├── area_stacking_test.dart             # Stacking calculation tests
│   ├── bar_positioner_test.dart            # Bar layout tests
│   ├── scatter_clusterer_test.dart         # Clustering algorithm tests
│   └── chart_renderer_test.dart            # Shared utilities tests
├── integration/
│   ├── multi_series_rendering_test.dart    # Multiple series tests
│   ├── theme_integration_test.dart         # Theme application tests
│   ├── coordinate_transform_test.dart      # Coordinate system integration
│   └── animation_test.dart                 # Data update animation tests
├── performance/
│   ├── line_chart_benchmark.dart           # 10K point rendering benchmark
│   ├── area_chart_benchmark.dart           # 10K point rendering benchmark
│   ├── bar_chart_benchmark.dart            # 1K bar rendering benchmark
│   └── scatter_chart_benchmark.dart        # 10K point rendering benchmark
└── golden/
    ├── line_chart_golden_test.dart         # Visual regression tests
    ├── area_chart_golden_test.dart
    ├── bar_chart_golden_test.dart
    └── scatter_chart_golden_test.dart
```

**Structure Decision**: Single Flutter library structure (Option 1). The chart types are a cohesive feature within the Braven Charts library, implementing the RenderLayer interface. All chart implementations share common utilities (marker rendering, gradient shaders) located in `base/`, with chart-specific logic in dedicated subdirectories. Tests follow the established pattern: contract tests enforce interface compliance, unit tests verify algorithms, integration tests validate layer interaction, performance benchmarks ensure constitutional requirements, and golden tests catch visual regressions.

## Phase 0: Outline & Research
✅ **COMPLETE** - research.md generated

**Research Completed**:
1. Chart architecture pattern - RenderLayers for composability
2. Line rendering algorithms - Catmull-Rom to Bezier for smooth curves
3. Marker shape rendering - 6 shapes with object pooling
4. Area chart fill rendering - Gradient shaders with caching
5. Bar chart positioning - Grouped/stacked algorithms with spacing
6. Animation system - Diff-based lerp for data updates
7. Viewport culling integration - Reuse Foundation's ViewportCuller
8. Theme integration - Automatic from SeriesTheme
9. Performance benchmarking - Frame time measurements
10. Testing strategy - Contract, unit, integration, performance, visual

**Output**: `research.md` (complete)

---

## Phase 1: Design & Contracts
✅ **COMPLETE** - data-model.md, contracts/*, quickstart.md generated

**Completed Artifacts**:

1. **data-model.md** - 18 models defined:
   - 4 main configs: LineChartConfig, AreaChartConfig, BarChartConfig, ScatterChartConfig
   - 7 enums: LineStyle, MarkerShape, AreaFillStyle, AreaBaselineType, BarOrientation, BarGroupingMode, MarkerSizingMode, MarkerStyle
   - 4 supporting classes: AreaBaseline, ChartAnimationConfig, ChartSeriesStyle
   - 3 internal classes: InterpolatedPoint, BarLayoutInfo, ClusterInfo

2. **contracts/** - 5 contract files:
   - `chart_layer.dart` - Base ChartLayer interface (extends RenderLayer)
   - `line_chart_config.dart` - Line chart configuration contract
   - `area_chart_config.dart` - Area chart configuration contract
   - `bar_chart_config.dart` - Bar chart configuration contract
   - `scatter_chart_config.dart` - Scatter chart configuration contract

3. **quickstart.md** - 10 executable examples:
   - Example 1: Basic line chart (straight lines)
   - Example 2: Smooth multi-series line chart (bezier curves)
   - Example 3: Area chart with gradient fill
   - Example 4: Stacked area chart
   - Example 5: Grouped bar chart (side-by-side)
   - Example 6: Stacked bar chart with negative values
   - Example 7: Scatter plot with fixed-size markers
   - Example 8: Scatter plot with data-driven sizing
   - Example 9: Data updates with animation
   - Example 10: Performance test (10,000 points in <16ms)

4. **Agent context updated** - GitHub Copilot instructions updated with:
   - Dart 3.10.0-227.0.dev
   - Flutter SDK 3.37.0-1.0.pre-216
   - Standard Dart libraries (dart:ui, dart:math)
   - Chart Types feature details

**Output**: All Phase 1 artifacts complete

---

## Phase 2: Task Planning Approach
*This section describes what the /tasks command will do - DO NOT execute during /plan*

**Task Generation Strategy**:

1. **Load Template**: Use `.specify/templates/tasks-template.md` as base structure

2. **Generate Contract Tests** (Phase 0 in tasks.md):
   - Task T001: ChartLayer contract test (all implementations must satisfy interface)
   - Task T002: LineChartConfig validation test (markerSize > 0, lineWidth > 0, dashPattern even length)
   - Task T003: AreaChartConfig validation test (fillOpacity in [0,1], showLine implies lineConfig)
   - Task T004: BarChartConfig validation test (barWidthRatio in (0,1], non-negative spacing)
   - Task T005: ScatterChartConfig validation test (sizingMode constraints, clusterThreshold >= 2)
   - **All tests must FAIL initially** (TDD requirement)

3. **Generate Model Implementation Tasks** (Phase 1 in tasks.md):
   - Task T006: Implement LineChartConfig with validation and copyWith()
   - Task T007: Implement AreaChartConfig with validation and copyWith()
   - Task T008: Implement BarChartConfig with validation and copyWith()
   - Task T009: Implement ScatterChartConfig with validation and copyWith()
   - Task T010: Implement ChartAnimationConfig
   - Task T011: Implement ChartSeriesStyle
   - **Mark [P] for parallel execution** (independent files)

4. **Generate Rendering Algorithm Tasks** (Phase 2 in tasks.md):
   - Task T012: Implement LineInterpolator (Catmull-Rom to Bezier)
   - Task T013: Implement MarkerRenderer (6 shapes with object pooling)
   - Task T014: Implement AreaFillRenderer (gradient shaders with caching)
   - Task T015: Implement BarPositioner (grouped/stacked algorithms)
   - Task T016: Implement ScatterClusterer (optional clustering for dense data)

5. **Generate Chart Layer Tasks** (Phase 3 in tasks.md):
   - Task T017: Implement LineChartLayer (extends ChartLayer, uses LineInterpolator)
   - Task T018: Implement AreaChartLayer (extends ChartLayer, uses AreaFillRenderer)
   - Task T019: Implement BarChartLayer (extends ChartLayer, uses BarPositioner)
   - Task T020: Implement ScatterChartLayer (extends ChartLayer, uses ScatterClusterer)
   - **All must pass contract tests from Phase 0**

6. **Generate Integration Tests** (Phase 4 in tasks.md):
   - Task T021: Multi-series rendering test (verify distinct colors from theme)
   - Task T022: Theme integration test (ChartTheme application)
   - Task T023: Coordinate transformation test (UniversalCoordinateTransformer)
   - Task T024: Animation test (smooth data updates maintain 60 FPS)
   - Task T025: Viewport culling test (<1ms overhead)

7. **Generate Performance Benchmarks** (Phase 5 in tasks.md):
   - Task T026: Line chart benchmark (10,000 points in <16ms)
   - Task T027: Area chart benchmark (10,000 points in <16ms)
   - Task T028: Bar chart benchmark (1,000 bars in <16ms)
   - Task T029: Scatter chart benchmark (10,000 points in <16ms)
   - Task T030: Object pooling benchmark (>90% hit rate)

8. **Generate Visual Regression Tests** (Phase 6 in tasks.md):
   - Task T031: Line chart golden tests (3 styles, 6 markers, multi-series)
   - Task T032: Area chart golden tests (3 fills, stacked mode)
   - Task T033: Bar chart golden tests (2 orientations, 2 grouping modes)
   - Task T034: Scatter chart golden tests (6 shapes, 3 styles)

9. **Generate Documentation Tasks** (Phase 7 in tasks.md):
   - Task T035: DartDoc for all public APIs
   - Task T036: Code comments for complex algorithms (bezier, stacking)
   - Task T037: Update README with chart type examples
   - Task T038: Create usage guide (docs/guides/chart-types.md)

**Ordering Constraints**:
- Contract tests (T001-T005) must come before implementation
- Model tasks (T006-T011) can run in parallel [P]
- Algorithm tasks (T012-T016) depend on models
- Chart layer tasks (T017-T020) depend on algorithms
- Integration tests (T021-T025) depend on chart layers
- Performance benchmarks (T026-T030) validate constitutional requirements
- Golden tests (T031-T034) validate visual correctness
- Documentation (T035-T038) must be last

**Estimated Tasks**: ~38 tasks across 7 phases

---

## Phase 3-4: Implementation Execution
*Not part of /plan command - executed manually or via implementation tools*

**Implementation Flow**:
1. Run `/tasks` to generate tasks.md
2. Execute tasks in order (respecting [P] parallel markers)
3. Update tasks.md after EVERY completed task (constitutional requirement)
4. Commit and push after logical milestones
5. Performance benchmarks must pass before merging
6. 100% test coverage required

---

## Complexity Tracking

**No Complexity Violations Detected**:
- Pure Flutter implementation (no web-specific APIs)
- Leverages existing foundation layers (no duplication)
- Simple algorithms (lowest level: Canvas.drawPath, Canvas.drawRect)
- SOLID principles followed (ChartLayer base, specific implementations)
- Performance targets achievable (research validated)

**Justified Complexity**:
- Bezier curve interpolation for smooth lines - **User requirement** (FR-005)
- Viewport culling integration - **Constitutional requirement** (60 FPS, <16ms)
- Gradient shader caching - **Performance optimization** (avoid expensive shader creation)
- Animation system - **User requirement** (FR-035, smooth data updates)

---

## Progress Tracking

**Execution Status**:
- ✅ Step 1: Feature spec loaded (45 FRs, 5 scenarios, 4 chart types)
- ✅ Step 2: Technical Context filled (no NEEDS CLARIFICATION)
- ✅ Step 3: Constitution Check completed
- ✅ Step 4: Initial Constitution Check PASS (no violations)
- ✅ Step 5: Phase 0 complete (research.md)
- ✅ Step 6: Phase 1 complete (contracts, data-model.md, quickstart.md, copilot-instructions.md)
- ✅ Step 7: Post-Design Constitution Check PASS (no new violations)
- ✅ Step 8: Phase 2 task planning approach defined
- ✅ Step 9: READY FOR /tasks COMMAND

**Next Command**: `/tasks` to generate tasks.md with TDD task breakdown

---

## Summary

**Feature**: Chart Types (Layer 4) - Four core chart implementations

**Status**: Planning complete, ready for task generation

**Key Deliverables**:
- 4 chart types: Line, Area, Bar, Scatter
- 18 data models with validation
- 5 contract interfaces
- 10 executable quickstart examples
- ~38 implementation tasks (estimated)

**Performance Targets**:
- Line/Area: <16ms for 10,000 points
- Bar: <16ms for 1,000 bars
- Scatter: <16ms for 10,000 points
- Viewport culling: <1ms overhead
- Object pooling: >90% hit rate

**Dependencies**: Layers 0-3 (Foundation, Rendering, Coordinates, Theming) all complete ✅

**Constitutional Compliance**: All principles satisfied, no violations ✅

Ready for `/tasks` command.

**Estimated Output**: 25-30 numbered, ordered tasks in tasks.md

**IMPORTANT**: This phase is executed by the /tasks command, NOT by /plan

## Phase 3+: Future Implementation
*These phases are beyond the scope of the /plan command*

**Phase 3**: Task execution (/tasks command creates tasks.md)  
**Phase 4**: Implementation (execute tasks.md following constitutional principles)  
**Phase 5**: Validation (run tests, execute quickstart.md, performance validation)

## Complexity Tracking
*Fill ONLY if Constitution Check has violations that must be justified*

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| [e.g., 4th project] | [current need] | [why 3 projects insufficient] |
| [e.g., Repository pattern] | [specific problem] | [why direct DB access insufficient] |


## Progress Tracking
*This checklist is updated during execution flow*

**Phase Status**:
- [ ] Phase 0: Research complete (/plan command)
- [ ] Phase 1: Design complete (/plan command)
- [ ] Phase 2: Task planning complete (/plan command - describe approach only)
- [ ] Phase 3: Tasks generated (/tasks command)
- [ ] Phase 4: Implementation complete
- [ ] Phase 5: Validation passed

**Gate Status**:
- [ ] Initial Constitution Check: PASS
- [ ] Post-Design Constitution Check: PASS
- [ ] All NEEDS CLARIFICATION resolved
- [ ] Complexity deviations documented

---
*Based on Constitution v2.1.1 - See `/memory/constitution.md`*
