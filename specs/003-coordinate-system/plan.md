
# Implementation Plan: Universal Coordinate System

**Branch**: `003-coordinate-system` | **Date**: 2025-10-05 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/003-coordinate-system/spec.md`

## Execution Flow (/plan command scope)
```
1. Load feature spec from Input path
   ✓ Loaded spec.md with 7 FRs, 4 user scenarios
2. Fill Technical Context (scan for NEEDS CLARIFICATION)
   ✓ Project Type: Single Flutter library (web-first)
   ✓ All technical aspects clear from constitution and architecture docs
3. Fill the Constitution Check section
   ✓ Constitutional requirements analyzed
4. Evaluate Constitution Check section below
   ✓ No violations detected - design aligns with principles
   ✓ Update Progress Tracking: Initial Constitution Check PASS
5. Execute Phase 0 → research.md
   ✓ Completed - transformation strategies and patterns documented
6. Execute Phase 1 → contracts, data-model.md, quickstart.md
   ✓ Completed - 4 entities, 4 contracts, quickstart tests defined
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

The Universal Coordinate System provides **type-safe, bidirectional transformations** between 8 coordinate spaces (mouse, screen, chartArea, data, dataPoint, marker, viewport, normalized). This eliminates v1.0's scattered coordinate logic that caused 40% of support tickets.

**Technical Approach** (from research):
- Stateless transformer with TransformContext dependency injection
- Affine transformation matrices for performance (cached per context hash)
- SIMD-optimized batch transformations for 10K+ points
- Comprehensive validation with actionable error messages
- Integration with Core Rendering Engine's RenderContext

## Technical Context
**Language/Version**: Dart 3.10.0-227.0.dev  
**Primary Dependencies**: Flutter SDK 3.37.0-1.0.pre-216, Standard Dart libraries (dart:ui, dart:math, dart:typed_data for SIMD)  
**Storage**: N/A (stateless transformation system)  
**Testing**: Flutter test framework, contract tests, integration tests with Core Rendering Engine  
**Target Platform**: Flutter Web (primary), iOS/Android (secondary)  
**Project Type**: Single Flutter library  
**Performance Goals**: <1ms batch transformation of 10K points, 60 FPS rendering, zero allocations in steady-state  
**Constraints**: No external packages, pure Flutter implementation, <16ms frame budget  
**Scale/Scope**: 8 coordinate systems, 56 bidirectional transformations, 100% test coverage requirement

**User Input Context**: Core Rendering Engine is fully implemented (v0.2.0-rendering) with RenderContext, RenderLayer, RenderPipeline, PerformanceMonitor, and TextLayoutCache. Coordinate system will integrate with RenderContext to provide transformation capabilities during rendering.

## Constitution Check
*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

### I. Architectural Integrity (Pure Flutter)
✅ **PASS** - Pure Dart/Flutter implementation
- Uses only dart:ui (Canvas), dart:math (Point, Rectangle), dart:typed_data (Float32x4 for SIMD)
- No HTML elements or web-specific APIs
- Integrates cleanly with Foundation Layer (DataRange, ObjectPool) and Core Rendering Engine (RenderContext)
- Clean separation: CoordinateTransformer (interface), UniversalCoordinateTransformer (implementation), TransformContext (data), ViewportState (data)
- No circular dependencies: Depends on Foundation + Core Rendering, consumed by future layers (Theming, Chart Types, Interaction, Annotation)

### II. Performance First (60fps Target)
✅ **PASS** - Performance-optimized design
- <1ms batch transformation target for 10K points (measured via benchmarks)
- Affine transformation matrix caching to avoid repeated calculations
- SIMD operations (Float32x4) for parallel arithmetic in batch transformations
- ObjectPool integration from Foundation Layer for zero-allocation transforms
- Viewport culling integration to skip off-screen transformations
- <16ms frame time maintained with coordinate transformations in rendering pipeline

### III. Testing Excellence (NON-NEGOTIABLE)
✅ **PASS** - Comprehensive test strategy
- TDD approach: Contract tests → Unit tests → Integration tests → Implementation
- 100% coverage target: All 56 transformation paths tested (8 systems × 7 destinations)
- Round-trip tests verify bidirectional accuracy within 0.01 pixel tolerance
- Contract tests verify all transformation paths exist and signatures match
- Integration tests verify RenderContext integration
- Performance benchmarks enforce <1ms batch transformation requirement
- Golden tests for visual validation of transformed coordinates (via rendering)

### IV. Requirements Compliance (NON-NEGOTIABLE)
✅ **PASS** - Specification-driven implementation
- All 7 functional requirements (FR-001 to FR-007) mapped to implementation tasks
- tasks.md will document every requirement with corresponding tasks
- Deviations will be explicitly acknowledged in tasks.md changelog with rationale
- Progress tracking in tasks.md updated after each completed task

### V. API Consistency
✅ **PASS** - Flutter-idiomatic API design
- Follows Foundation Layer patterns: immutability (const constructors), value semantics
- Matches Core Rendering Engine patterns: context-based dependency injection
- Named parameters for clarity: `transformer.transform(point, from: CoordinateSystem.data, to: CoordinateSystem.screen, context: ctx)`
- Proper Dart naming conventions: camelCase methods, PascalCase classes, lowercase_with_underscores enums
- Breaking changes tracked for v1.0.0 release (currently in pre-release development)

### VI. Documentation Discipline
✅ **PASS** - Comprehensive documentation plan
- quickstart.md provides examples for all 8 coordinate systems
- Contract files include dartdoc comments explaining each transformation path
- data-model.md documents all entities with field descriptions and validation rules
- Inline comments explain "why" for non-obvious transformations (e.g., affine matrix composition)
- Architecture decision record: Why affine matrices over direct calculations (composability, performance)

**GATE STATUS**: ✅ All constitutional requirements satisfied

## Project Structure

### Documentation (this feature)
```
specs/003-coordinate-system/
├── spec.md              # Feature specification (constitutional spec)
├── plan.md              # This file (/plan command output)
├── research.md          # Phase 0 output - transformation strategies
├── data-model.md        # Phase 1 output - 4 entities defined
├── quickstart.md        # Phase 1 output - usage examples for 8 coordinate systems
├── contracts/           # Phase 1 output - 4 contract files
│   ├── coordinate_transformer.dart      # Main transformation interface
│   ├── transform_context.dart           # Immutable context data
│   ├── viewport_state.dart              # Zoom/pan state
│   └── transform_matrix.dart            # Affine matrix utilities
└── tasks.md             # Phase 2 output (/tasks command - NOT created by /plan)
```

### Source Code (repository root)
```
lib/
├── src/
│   ├── foundation/                      # Layer 0 (existing)
│   │   ├── data_structures.dart         # DataRange, ChartSeries, ChartDataPoint
│   │   ├── performance.dart             # ObjectPool, PerformanceTimer
│   │   └── ...
│   │
│   ├── rendering/                       # Layer 1 (existing - Core Rendering)
│   │   ├── render_context.dart          # RenderContext with viewport culler
│   │   ├── render_layer.dart            # RenderLayer interface
│   │   ├── render_pipeline.dart         # Frame orchestration
│   │   └── ...
│   │
│   └── coordinates/                     # Layer 2 (NEW - this feature)
│       ├── coordinate_system.dart       # CoordinateSystem enum
│       ├── coordinate_transformer.dart  # CoordinateTransformer interface
│       ├── universal_transformer.dart   # UniversalCoordinateTransformer impl
│       ├── transform_context.dart       # TransformContext immutable data
│       ├── viewport_state.dart          # ViewportState immutable data
│       ├── transform_matrix.dart        # Affine matrix internals
│       └── validation_result.dart       # Validation error types
│
└── braven_charts.dart                   # Public API exports

test/
├── contract/
│   └── coordinates/                     # Contract tests for all 56 paths
│       ├── coordinate_transformer_test.dart
│       ├── transform_context_test.dart
│       ├── viewport_state_test.dart
│       └── transform_matrix_test.dart
│
├── unit/
│   └── coordinates/                     # Unit tests for each transformation
│       ├── mouse_screen_test.dart       # Mouse ↔ Screen
│       ├── screen_chartarea_test.dart   # Screen ↔ ChartArea
│       ├── chartarea_data_test.dart     # ChartArea ↔ Data
│       ├── data_viewport_test.dart      # Data ↔ Viewport (zoom/pan)
│       ├── data_datapoint_test.dart     # Data ↔ DataPoint (index lookup)
│       ├── data_marker_test.dart        # Data ↔ Marker (annotation offsets)
│       ├── data_normalized_test.dart    # Data ↔ Normalized (0.0-1.0)
│       ├── round_trip_test.dart         # All round-trip accuracy tests
│       ├── edge_cases_test.dart         # NaN, infinity, zero dimensions
│       └── validation_test.dart         # Coordinate validation tests
│
├── integration/
│   └── coordinates/                     # Integration with Core Rendering
│       ├── render_context_integration_test.dart  # RenderContext + transformer
│       └── transformation_pipeline_test.dart     # Full data→screen pipeline
│
└── benchmarks/
    └── coordinates/                     # Performance benchmarks
        ├── batch_transformation_benchmark.dart   # 10K points <1ms target
        ├── cache_hit_rate_benchmark.dart         # >90% cache hit rate
        └── zero_allocation_benchmark.dart        # Memory profiling
```

**Structure Decision**: Single Flutter library project following established Layer 0 (Foundation) and Layer 1 (Core Rendering) patterns. The coordinate system is Layer 2 in the architectural dependency graph, building on DataRange/ChartSeries from Foundation and integrating with RenderContext from Core Rendering. Future layers (Theming, Chart Types, Interaction, Annotation) will consume the coordinate transformation system.

## Phase 0: Outline & Research
1. **Extract unknowns from Technical Context** above:
   - ✅ All technical aspects clear from architecture documents and Core Rendering implementation
   - ✅ No NEEDS CLARIFICATION markers remain
   - ✅ Transformation strategy research complete (affine matrices selected)

2. **Generate and dispatch research agents**:
   - R1: Coordinate transformation strategies (affine matrices vs direct calculation vs functional composition)
   - R2: Context management pattern (immutable vs mutable vs global state)
   - R3: Performance optimization techniques (caching, SIMD, viewport culling)
   - R4: Validation strategy (compile-time vs runtime vs debug-mode)
   - R5: Core Rendering Engine integration (RenderContext extension approach)

3. **Consolidate findings** in `research.md`:
   - ✅ All 5 research tasks completed
   - ✅ Decisions documented with rationale and alternatives considered
   - ✅ Implementation notes provided for each decision

**Output**: ✅ research.md complete (5 research decisions, all aligned with constitution)

## Phase 1: Design & Contracts
*Prerequisites: research.md complete*

1. **Extract entities from feature spec** → `data-model.md`:
   - ✅ Entity 1: CoordinateSystem (enum) - 8 coordinate spaces defined
   - ✅ Entity 2: TransformContext (immutable data) - 9 fields, all validated
   - ✅ Entity 3: ViewportState (immutable data) - 4 fields, zoom/pan state
   - ✅ Entity 4: TransformMatrix (internal utility) - 3x3 affine matrix
   - ✅ Relationships: TransformContext uses ViewportState, depends on Foundation (DataRange, ChartSeries)
   - ✅ Integration: RenderContext extended with transformContext and transformer fields

2. **Generate API contracts** from functional requirements:
   - ✅ coordinate_transformer.dart - Main transformation interface (FR-001 to FR-007)
     - `transform(point, from, to, context)` - Single point transformation
     - `transformBatch(points, from, to, context)` - Optimized batch transformation
     - `validate(point, system, context)` - Coordinate validation
     - `getValidRange(system, context)` - Valid range for coordinate system
   - ✅ transform_context.dart - Immutable context data (FR-003)
     - 9 fields: widgetSize, chartAreaBounds, xDataRange, yDataRange, viewport, series, markerOffset, animationProgress, devicePixelRatio
     - withX() methods for immutable updates
     - Hash code and equality for cache keys
   - ✅ viewport_state.dart - Zoom/pan state (FR-006, FR-007)
     - 4 fields: xRange, yRange, zoomFactor, panOffset
     - withZoom(), withPan(), withRanges() methods
     - containsPoint() and isIdentity() helpers
   - ✅ transform_matrix.dart - Internal affine matrix (FR-004 performance)
     - Factory constructors: identity(), translation(), scale(), combined()
     - transform(point) - Apply matrix transformation
     - inverse() - Reverse transformation
     - operator* - Matrix multiplication for composition
     - transformBatch4() - SIMD-optimized batch processing

3. **Generate contract tests** from contracts:
   - Test file structure defined in Project Structure section
   - Contract tests verify: All 56 transformation paths exist, signatures match, round-trip accuracy
   - Tests must fail initially (no implementation yet)

4. **Extract test scenarios** from user stories:
   - ✅ Scenario 1: Mouse click detection (mouse → data → screen)
   - ✅ Scenario 2: Annotation anchoring (data → marker → screen with offset)
   - ✅ Scenario 3: Range highlighting (data ranges → screen rectangles)
   - ✅ Scenario 4: Real-time auto-pan (streaming data + viewport updates)
   - ✅ quickstart.md contains 8 executable test examples (one per coordinate system)

5. **Update agent file incrementally**:
   - Skip this step - Using GitHub Copilot with .github/copilot-instructions.md (already updated)
   - Manual additions preserved between markers
   - Recent changes tracked in instructions file

**Output**: ✅ All Phase 1 artifacts complete
- data-model.md (4 entities, relationships, integration)
- contracts/ (4 contract files with full API signatures)
- quickstart.md (8 test examples, performance validation)
- .github/copilot-instructions.md (already configured)

## Phase 2: Task Planning Approach
*This section describes what the /tasks command will do - DO NOT execute during /plan*

**Task Generation Strategy**:
- Load `.specify/templates/tasks-template.md` as base
- Generate tasks from Phase 1 design docs (contracts, data model, quickstart)
- Follow TDD order: Contract tests → Unit tests → Implementation → Integration tests

**Task Categories**:

1. **Contract Test Tasks** (All [P] - parallel execution):
   - T001 [P]: Contract test - CoordinateSystem enum (8 values, exhaustive switch)
   - T002 [P]: Contract test - CoordinateTransformer interface (4 methods, 56 paths)
   - T003 [P]: Contract test - TransformContext (9 fields, immutability, withX() methods)
   - T004 [P]: Contract test - ViewportState (4 fields, immutability, helpers)
   - T005 [P]: Contract test - TransformMatrix (factory constructors, transform(), inverse())

2. **Entity Implementation Tasks** (Sequential dependencies):
   - T006: Implement CoordinateSystem enum (depends on T001)
   - T007: Implement ViewportState (depends on T004)
   - T008: Implement TransformContext (depends on T003, T007)
   - T009: Implement TransformMatrix internals (depends on T005)

3. **Transformation Logic Tasks** (56 paths, organized by priority):
   - T010 [P]: Implement mouse ↔ screen (identity transformation)
   - T011 [P]: Implement screen ↔ chartArea (translation)
   - T012: Implement chartArea ↔ data (scale + translate + Y-flip)
   - T013: Implement data ↔ viewport (zoom/pan)
   - T014: Implement data ↔ dataPoint (index lookup)
   - T015: Implement data ↔ marker (annotation offset)
   - T016 [P]: Implement chartArea ↔ normalized (scale to 0.0-1.0)
   - T017-T025: Implement transitive transformations (via intermediate systems)

4. **Validation Tasks**:
   - T026: Implement coordinate validation (NaN, infinity, range checks)
   - T027: Implement ValidationResult error messages (actionable, with suggestions)
   - T028: Implement getValidRange() for all 8 coordinate systems

5. **Performance Optimization Tasks**:
   - T029: Implement matrix caching with context hash
   - T030: Implement SIMD batch transformations (Float32x4)
   - T031: Implement zero-allocation transformations (ObjectPool integration)
   - T032: Add viewport culling integration

6. **Integration Tasks**:
   - T033: Extend RenderContext with transformContext and transformer fields
   - T034: Add convenience methods to RenderContext (dataToScreen, screenToData, batch)
   - T035: Update RenderPipeline to construct TransformContext

7. **Testing Tasks**:
   - T036-T042: Unit tests for each transformation path (7 direct paths)
   - T043: Round-trip accuracy tests (all 56 paths)
   - T044: Edge case tests (NaN, infinity, zero dimensions)
   - T045: Validation tests (all error types)
   - T046-T047: Integration tests with RenderContext
   - T048: Performance benchmarks (<1ms for 10K points)

8. **Documentation Tasks**:
   - T049: API documentation (dartdoc comments)
   - T050: Update quickstart.md with actual implementation
   - T051: Add transformation examples to documentation

**Ordering Strategy**:
- TDD order: Tests before implementation (T001-T005 before T006-T009)
- Dependency order: Entities before transformations (T006-T009 before T010-T025)
- Critical path: Core transformations before optimizations (T010-T016 before T029-T032)
- Mark [P] for parallel execution (independent tasks)

**Estimated Output**: 51 numbered, ordered tasks in tasks.md

**Performance Gates**:
- T048 MUST pass (<1ms batch transformation) before marking complete
- T043 MUST pass (round-trip accuracy <0.01 pixels) before marking complete
- All contract tests (T001-T005) MUST pass before implementation tasks

**IMPORTANT**: This phase is executed by the /tasks command, NOT by /plan

## Phase 3+: Future Implementation
*These phases are beyond the scope of the /plan command*

**Phase 3**: Task execution (/tasks command creates tasks.md)  
**Phase 4**: Implementation (execute tasks.md following constitutional principles)  
**Phase 5**: Validation (run tests, execute quickstart.md, performance validation)

## Complexity Tracking
*Fill ONLY if Constitution Check has violations that must be justified*

**No constitutional violations detected.** All design decisions align with constitutional principles:

- ✅ Pure Flutter architecture (dart:ui, dart:math, dart:typed_data only)
- ✅ Performance first (<1ms batch transformations, zero allocations, matrix caching)
- ✅ Testing excellence (TDD approach, 100% coverage target, contract tests)
- ✅ Requirements compliance (all 7 FRs mapped to tasks, progress tracking in tasks.md)
- ✅ API consistency (immutable patterns match Foundation, RenderContext integration matches Core Rendering)
- ✅ Documentation discipline (research rationale, contract comments, quickstart examples)

**Architectural Decisions**:
- Affine transformation matrices: Industry-standard approach, well-established math, composable
- Immutable context passing: Functional programming best practice, matches Foundation patterns
- SIMD optimization: Dart standard library feature (Float32x4), no external dependencies

**No complexity tracking needed** - design is intentionally simple following KISS principle.


## Progress Tracking
*This checklist is updated during execution flow*

**Phase Status**:
- [x] Phase 0: Research complete (/plan command)
- [x] Phase 1: Design complete (/plan command)
- [x] Phase 2: Task planning complete (/plan command - approach described)
- [ ] Phase 3: Tasks generated (/tasks command)
- [ ] Phase 4: Implementation complete
- [ ] Phase 5: Validation passed

**Gate Status**:
- [x] Initial Constitution Check: PASS (no violations)
- [x] Post-Design Constitution Check: PASS (no new violations)
- [x] All NEEDS CLARIFICATION resolved (none existed)
- [x] Complexity deviations documented (none - no violations)

**Artifacts Generated**:
- [x] research.md (5 research decisions with rationale)
- [x] data-model.md (4 entities, relationships, integration)
- [x] contracts/ (4 contract files with full API)
- [x] quickstart.md (8 test examples, performance validation)
- [ ] tasks.md (awaiting /tasks command)

**Ready for Next Phase**: ✅ YES - Execute `/tasks` command to generate tasks.md

---
*Based on Constitution v1.1.0 - See `docs/memory/constitution.md`*
*Plan completed: 2025-10-05*
