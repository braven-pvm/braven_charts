# Implementation Plan: Chart Widgets with Annotations

**Branch**: `006-chart-widgets` | **Date**: October 6, 2025 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/006-chart-widgets/spec.md`

## Execution Flow (/plan command scope)

```
1. Load feature spec from Input path
   ✓ Loaded spec.md with 40 FRs, 8 NFRs, 10 acceptance scenarios, 5 user stories
2. Fill Technical Context (scan for NEEDS CLARIFICATION)
   ✓ Project Type: Single Flutter library (web-first)
   ✓ All technical aspects clear from previous layers (Layers 0-4 implemented)
   ✓ Technical specification exists in docs/specs/005-chart-widgets/ with detailed architecture
3. Fill the Constitution Check section
   ✓ Constitutional requirements analyzed
4. Evaluate Constitution Check section below
   ✓ No violations detected - design aligns with all principles
   ✓ Update Progress Tracking: Initial Constitution Check PASS
5. Execute Phase 0 → research.md
   ✓ COMPLETE - All 7 technical decisions documented with rationale
6. Execute Phase 1 → contracts, data-model.md, quickstart.md
   ✓ COMPLETE - data-model.md (5 entities, relationships, validation)
   ✓ COMPLETE - contracts/ (4 contract files, TDD red phase)
   ✓ COMPLETE - quickstart.md (6-step guide, 5 minutes to first chart)
   ✓ COMPLETE - Updated .github/copilot-instructions.md
7. Re-evaluate Constitution Check section
   ✓ PASS - No new violations after design
   ✓ Update Progress Tracking: Post-Design Constitution Check PASS
8. Plan Phase 2 → Task generation approach
   ✓ COMPLETE - Described below
9. STOP - Ready for /tasks command
```

**STATUS**: ✅ PLAN COMPLETE - Ready for `/tasks` command

**IMPORTANT**: The /plan command STOPS at step 9. Phases 2-4 are executed by other commands:

- Phase 2: /tasks command creates tasks.md
- Phase 3-4: Implementation execution (manual or via tools)

---

## Summary

The Chart Widgets layer provides a **single user-facing widget** (`BravenChart`) that wraps all chart layer implementations (Line, Area, Bar, Scatter), enabling Flutter developers to create professional charts with 5-10 lines of code instead of 50+. This widget includes comprehensive axis configuration, real-time data streaming support, annotation overlay system (5 types: Text, Point, Range, Threshold, Trend), and programmatic control via `ChartController`.

**Technical Approach**:

- Single `BravenChart` StatefulWidget as ONLY user-facing API (enforced architectural decision)
- Internal chart type selection via `chartType` enum parameter (line, area, bar, scatter)
- Stateful widget pattern with automatic resource lifecycle management
- `ChartController` for programmatic data/annotation updates without full rebuild
- Stream-based real-time data with throttling (60 FPS) and backpressure handling
- `AxisConfig` with 45+ properties and factory presets (defaults/hidden/minimal/gridOnly)
- Annotation system integrated as rendering layer (5 types with interaction support)
- Comprehensive axis configuration with visibility control for sparklines
- Automatic resource disposal on unmount (pipelines, pools, streams)
- TDD with contract tests, widget tests, golden tests, integration tests

---

**Language/Version**: Dart 3.10.0-227.0.dev  
**Primary Dependencies**: Flutter SDK 3.37.0-1.0.pre-216, Standard Dart libraries (dart:ui for widgets, dart:async for streams)  
**Storage**: N/A (stateless widget with external data sources)  
**Testing**: Flutter test framework, widget tests, golden tests, contract tests, integration tests  
**Target Platform**: Flutter Web (primary), iOS/Android (secondary)  
**Project Type**: Single Flutter library  
**Performance Goals**: 60 FPS with 10,000 data points, <16ms frame time, <100ms response to controller updates, Stream throttling at 60 FPS  
**Constraints**: Single user-facing widget (BravenChart ONLY), no direct access to chart layers, pure Flutter (no HTML/JS), zero memory leaks, proper hot reload support  
**Scale/Scope**: 1 primary widget (BravenChart), 4 chart types, 5 annotation types, 1 controller class, 1 comprehensive AxisConfig, 40 functional requirements, 8 non-functional requirements, 100% test coverage target

**User-Provided Implementation Context**:

- **Layer 0 (Foundation)**: ChartSeries, ChartDataPoint, ObjectPool, ViewportCuller implemented
- **Layer 1 (Core Rendering)**: RenderPipeline, RenderLayer, Paint/Path pooling implemented
- **Layer 2 (Coordinate System)**: UniversalCoordinateTransformer for all transformations implemented
- **Layer 3 (Theming)**: ChartTheme, SeriesTheme, dark mode support implemented
- **Layer 4 (Chart Types)**: LineChartLayer, AreaChartLayer, BarChartLayer, ScatterChartLayer implemented
- **Architecture Decision ARCH-005-001**: BravenChart as single entry point (see docs/specs/005-chart-widgets/architecture_decision.md)
- **Technical Specification**: Detailed implementation in docs/specs/005-chart-widgets/spec.md (2400+ lines, 13 FR sections)
- **Annotation Architecture**: Full specification in project-restart-docs/03-architecture-specs/annotation_system_architecture.md
- **Constitution**: TDD mandatory, 60fps/16ms targets, pure Flutter, SOLID principles, zero warnings requirement

## Constitution Check

_GATE: Must pass before Phase 0 research. Re-check after Phase 1 design._

### I. Test-First Development (NON-NEGOTIABLE)

✅ **PASS** - Comprehensive TDD strategy

- Contract tests FIRST: BravenChart widget interface, ChartController API, AxisConfig properties
- Widget tests: Rendering behavior, lifecycle management, hot reload support
- Golden tests: Visual regression for all chart types, axis configurations, annotation types
- Integration tests: Real-time streaming, annotation interactions, theme switching
- Unit tests: AxisConfig factory methods, data binding helpers, controller state management
- Performance tests: Frame time measurements, memory leak detection, stream backpressure
- Tests written BEFORE implementation per TDD cycle
- Target: 100% coverage for all new code

### II. Performance First (60fps Target)

✅ **PASS** - Performance-optimized design

- Reuses Layer 4 performance optimizations (viewport culling, object pooling)
- Stream throttling at 60 FPS max (16ms minimum interval between updates)
- Backpressure handling when data arrives faster than render rate
- Controller updates use setState() efficiently (minimal rebuild scope)
- Annotation rendering uses spatial indexing for hit-testing (500 annotation limit)
- Resource lifecycle tied to widget lifecycle (dispose on unmount)
- Performance benchmarks: <16ms frame time, <100ms controller response
- Memory leak tests: 24-hour stream test, hot reload cycles

### III. Architectural Integrity (Pure Flutter)

✅ **PASS** - Pure Flutter StatefulWidget implementation

- Uses only Flutter widgets (StatefulWidget, CustomPaint), dart:async (Stream, StreamController)
- No HTML elements, no web-specific APIs
- Clean separation:
  - `BravenChart`: StatefulWidget (user-facing, lifecycle management)
  - `_BravenChartState`: State management, controller binding, resource disposal
  - `ChartController`: Programmatic control (data/annotation updates)
  - `AxisConfig`: Axis configuration (immutable value object)
  - `ChartAnnotation`: Base annotation class with 5 subtypes
- Integrates cleanly with Layers 0-4 (no circular dependencies)
- SOLID principles: Single Responsibility (widget vs controller), Open-Closed (annotation extensibility), Dependency Inversion (controller interface)
- Architecture Decision: BravenChart as ONLY user-facing widget (ARCH-005-001)

### IV. Requirements Compliance (NON-NEGOTIABLE)

✅ **PASS** - Specification-driven implementation

- Business spec: specs/006-chart-widgets/spec.md (40 FRs, 8 NFRs, 10 scenarios)
- Technical spec: docs/specs/005-chart-widgets/spec.md (2400+ lines, 13 FR sections)
- Architecture decision: docs/specs/005-chart-widgets/architecture_decision.md
- Annotation integration: docs/specs/005-chart-widgets/annotations_integration.md
- All 40 functional requirements testable and documented
- tasks.md will be updated after EVERY task completion
- Deviations require explicit documentation in tasks.md with rationale

### V. API Consistency & Stability

✅ **PASS** - Flutter-idiomatic API design

- Follows Flutter widget conventions: named parameters, required vs optional
- Constructor pattern: `BravenChart({required ChartType chartType, required List<ChartSeries> series, ...})`
- Factory constructors for common patterns: `BravenChart.fromValues()`, `BravenChart.fromMap()`, `BravenChart.fromJson()`
- AxisConfig factory presets: `AxisConfig.defaults()`, `AxisConfig.hidden()`, `AxisConfig.minimal()`, `AxisConfig.gridOnly()`
- Callback naming: `onPointTap`, `onSeriesSelected`, `onAnnotationTap`, `onAnnotationDragged`
- ChartController follows Flutter controller pattern (TextEditingController, ScrollController precedent)
- Breaking changes require major version increment (currently pre-1.0, flexibility allowed)
- Comprehensive dartdoc for all public APIs with examples

### VI. Documentation Discipline

✅ **PASS** - Comprehensive documentation plan

- Inline dartdoc: All public APIs (BravenChart, ChartController, AxisConfig, annotations)
- Architecture Decision Record: ARCH-005-001 (single entry point justification)
- Integration guide: Annotation system integration (250+ lines)
- Code examples: Each annotation type, real-time patterns, axis configurations
- Quickstart guide: Will be generated in Phase 1 (3-5 minute first chart)
- Implementation comments: Explain "why" for non-obvious widget lifecycle decisions
- Migration guide: From direct Layer 4 usage to BravenChart (future users)

### VII. Simplicity & Pragmatism (KISS Principle)

✅ **PASS** - Simple, focused design

- Single widget entry point (not 4 separate widgets) - KISS applied
- Reuses all Layer 0-4 complexity (no reinvention)
- AxisConfig: Simple value object (no complex inheritance)
- ChartController: Simple notifier pattern (no complex state machine)
- Stream throttling: Built-in Flutter StreamTransformer (no custom implementation)
- Annotation rendering: Delegates to Layer 7 (when ready) or simple overlay (initial)
- No premature optimization: Performance measured, not assumed
- No over-engineering: Addresses 40 requirements, nothing more

## Project Structure

### Documentation (this feature)

```
specs/006-chart-widgets/
├── spec.md              # Business specification (350 lines, 40 FRs)
├── plan.md              # This file (/plan command output)
├── research.md          # Phase 0 output (widget patterns, controller design)
├── data-model.md        # Phase 1 output (entities, relationships)
├── quickstart.md        # Phase 1 output (5-minute first chart guide)
├── contracts/           # Phase 1 output (API contracts, test fixtures)
│   ├── braven_chart_contract.dart
│   ├── chart_controller_contract.dart
│   ├── axis_config_contract.dart
│   └── annotation_contracts.dart
└── tasks.md             # Phase 2 output (/tasks command - NOT created by /plan)
```

### Source Code (repository root)

```
lib/
├── src/
│   ├── widgets/             # NEW - Layer 5 (this feature)
│   │   ├── braven_chart.dart           # Main user-facing widget
│   │   ├── chart_controller.dart       # Programmatic control
│   │   ├── axis_config.dart            # Axis configuration
│   │   ├── annotations/                # Annotation types
│   │   │   ├── annotation_base.dart    # Base ChartAnnotation class
│   │   │   ├── text_annotation.dart    # Free-floating labels
│   │   │   ├── point_annotation.dart   # Data point markers
│   │   │   ├── range_annotation.dart   # Time/value ranges
│   │   │   ├── threshold_annotation.dart  # Reference lines
│   │   │   └── trend_annotation.dart   # Statistical overlays
│   │   └── internal/                   # Internal widgets (not exported)
│   │       ├── chart_painter.dart      # CustomPainter implementation
│   │       └── resource_manager.dart   # Pipeline/pool lifecycle
│   │
│   ├── charts/              # EXISTING - Layer 4 (chart types)
│   │   ├── line/
│   │   ├── area/
│   │   ├── bar/
│   │   └── scatter/
│   │
│   ├── theming/             # EXISTING - Layer 3
│   ├── coordinates/         # EXISTING - Layer 2
│   ├── rendering/           # EXISTING - Layer 1
│   └── foundation/          # EXISTING - Layer 0
│
├── braven_charts.dart       # Public API (exports widgets/)
└── widgets.dart             # NEW - Widget-specific exports

test/
├── widgets/                 # NEW - Layer 5 tests
│   ├── contract/
│   │   ├── braven_chart_contract_test.dart
│   │   ├── chart_controller_contract_test.dart
│   │   └── axis_config_contract_test.dart
│   ├── widget/
│   │   ├── braven_chart_widget_test.dart
│   │   ├── real_time_streaming_test.dart
│   │   ├── annotation_rendering_test.dart
│   │   └── hot_reload_test.dart
│   ├── golden/
│   │   ├── chart_types_golden_test.dart
│   │   ├── axis_configurations_golden_test.dart
│   │   └── annotations_golden_test.dart
│   ├── integration/
│   │   ├── end_to_end_test.dart
│   │   └── performance_test.dart
│   └── unit/
│       ├── axis_config_test.dart
│       ├── controller_test.dart
│       └── annotation_test.dart
│
├── charts/                  # EXISTING - Layer 4 tests
├── theming/                 # EXISTING - Layer 3 tests
├── coordinates/             # EXISTING - Layer 2 tests
├── rendering/               # EXISTING - Layer 1 tests
└── foundation/              # EXISTING - Layer 0 tests
```

**Structure Decision**: Single Flutter library project (existing structure). New Layer 5 (widgets/) sits above existing Layers 0-4. All user-facing APIs exported through `lib/braven_charts.dart` and new `lib/widgets.dart`. Internal implementation details (chart_painter, resource_manager) kept in `internal/` subdirectory and NOT exported. Tests organized by type (contract, widget, golden, integration, unit) following established pattern from previous layers.

## Phase 0: Outline & Research ✅ COMPLETE

**Execution Summary**:

- All technical unknowns resolved through research.md
- 7 major architectural decisions documented with full rationale
- No NEEDS CLARIFICATION items remaining from Technical Context
- Best practices identified for Flutter StatefulWidget, ChangeNotifier, Stream integration

**Major Decisions**:

1. **StatefulWidget** chosen over StatelessWidget (resource lifecycle needs)
2. **Controller pattern** using TextEditingController-style ChangeNotifier
3. **Stream throttling** at 16ms for 60 FPS compliance (NFR-001)
4. **Simple annotation overlay** with future Layer 7 migration path
5. **AxisConfig presets** for discoverability (defaults/hidden/minimal/gridOnly)
6. **Widget lifecycle integration** for resource management
7. **RepaintBoundary + shouldRepaint** for performance optimization

**Output**: `specs/006-chart-widgets/research.md` (7 decisions, 500+ lines)

**All unknowns resolved** ✅

## Phase 1: Design & Contracts ✅ COMPLETE

_Prerequisites: research.md complete ✅_

**Execution Summary**:

- Complete data model documented with 5 entities + 8 supporting types
- 4 contract test files created following TDD red phase (all intentionally failing)
- Quickstart guide created with 6 progressive steps (5-minute first chart)
- Agent context updated with Layer 5 technical information

**Entities Defined** (data-model.md):

1. **BravenChart** (StatefulWidget) - 25+ properties, 3 factory constructors
2. **ChartController** (ChangeNotifier) - Data + annotation management, 12 methods
3. **AxisConfig** (Value object) - 45+ properties, 4 factory presets
4. **ChartAnnotation** (Abstract) + 5 subtypes (Text/Point/Range/Threshold/Trend)
5. **Supporting Types** - 8 enums, 3 value objects

**Contract Tests Created** (TDD Red Phase):

- `braven_chart_contract.dart` - 80+ tests (166 lint errors EXPECTED)
- `chart_controller_contract.dart` - 40+ tests (147 lint errors EXPECTED)
- `axis_config_contract.dart` - Factory + validation tests (8 lint errors EXPECTED)
- `annotation_contracts.dart` - All 5 annotation types (14 lint errors EXPECTED)

**Outputs**:

- `specs/006-chart-widgets/data-model.md` (500+ lines, complete entity documentation)
- `specs/006-chart-widgets/contracts/` (4 test files, TDD red phase)
- `specs/006-chart-widgets/quickstart.md` (350+ lines, 6-step guide)
- `.github/copilot-instructions.md` (updated with Layer 5 context)

**Design Validated** ✅ No constitutional violations

## Phase 2: Task Planning Approach ✅ COMPLETE

_This section describes what the /tasks command will do - DO NOT execute during /plan_

**Task Generation Strategy**:

1. Load `.specify/templates/tasks-template.md` as base structure
2. Generate tasks from Phase 1 artifacts:
   - data-model.md → Entity implementation tasks
   - contracts/\*.dart → Contract test tasks
   - quickstart.md → Integration test scenarios
   - research.md → Implementation patterns

**Task Categorization**:

- **Setup Tasks** (1-3): Move contracts, create directory structure, setup test helpers
- **Entity Tasks** (4-15): Implement 5 entities + 8 supporting types to make contracts pass
- **Widget Tasks** (16-25): Implement BravenChart StatefulWidget + State class
- **Integration Tasks** (26-30): Widget tests, golden tests, quickstart validation
- **Documentation Tasks** (31-35): API docs, examples, migration guide

**Ordering Strategy**:

- **TDD Order**: Contract tests → Implementation → Widget tests → Golden tests → Integration tests
- **Dependency Order**:
  1. Supporting types (enums, value objects) [P]
  2. ChartAnnotation hierarchy [P]
  3. AxisConfig (depends on enums)
  4. ChartController (depends on annotations, enums)
  5. BravenChart widget (depends on all above)
- **Parallel Markers**: [P] for independent files (enums, annotation subtypes, test categories)

**Estimated Task Count**: 35-40 numbered, ordered tasks

**Task Template Pattern**:

```
### Task N: [Action] [Component]
- [ ] Implementation (or test creation)
- [ ] Unit tests pass (if implementation)
- [ ] Documentation updated
- [ ] Performance validated (if applicable)
```

**Constitutional Compliance Checkpoints**:

- Task 3: Contract tests ready (Test-First principle)
- Task 15: Entities complete (Architectural Integrity)
- Task 25: Widget complete (API Consistency)
- Task 30: Integration tests pass (Requirements Compliance)
- Task 35: Performance validated (Performance First)

**IMPORTANT**: This phase is executed by the /tasks command, NOT by /plan

## Phase 3+: Future Implementation

_These phases are beyond the scope of the /plan command_

**Phase 3**: Task execution (/tasks command creates tasks.md)  
**Phase 4**: Implementation (execute tasks.md following constitutional principles)  
**Phase 5**: Validation (run tests, execute quickstart.md, performance validation)

## Complexity Tracking

_Fill ONLY if Constitution Check has violations that must be justified_

| Violation                  | Why Needed         | Simpler Alternative Rejected Because |
| -------------------------- | ------------------ | ------------------------------------ |
| [e.g., 4th project]        | [current need]     | [why 3 projects insufficient]        |
| [e.g., Repository pattern] | [specific problem] | [why direct DB access insufficient]  |

## Progress Tracking

_This checklist is updated during execution flow_

**Phase Status**:

- [x] Phase 0: Research complete (/plan command) ✅ 7 decisions documented
- [x] Phase 1: Design complete (/plan command) ✅ Data model + contracts + quickstart
- [x] Phase 2: Task planning complete (/plan command - describe approach only) ✅ Strategy defined
- [ ] Phase 3: Tasks generated (/tasks command) - READY TO EXECUTE
- [ ] Phase 4: Implementation complete
- [ ] Phase 5: Validation passed

**Constitutional Checkpoints**:

- [x] Initial Constitution Check: PASS (all 7 principles compliant)
- [x] Post-Design Constitution Check: PASS (no new violations)

**Artifact Status**:

- [x] research.md created (500+ lines, 7 decisions)
- [x] data-model.md created (500+ lines, 5 entities)
- [x] contracts/ created (4 files, TDD red phase)
- [x] quickstart.md created (350+ lines, 6 steps)
- [x] copilot-instructions.md updated (Layer 5 context)

**Ready for /tasks command** ✅

**Gate Status**:

- [ ] Initial Constitution Check: PASS
- [ ] Post-Design Constitution Check: PASS
- [ ] All NEEDS CLARIFICATION resolved
- [ ] Complexity deviations documented

---

_Based on Constitution v2.1.1 - See `/memory/constitution.md`_
