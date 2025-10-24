# Implementation Plan: Dual-Mode Streaming Chart

**Branch**: `009-dual-mode-streaming` | **Date**: 2025-10-22 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/009-dual-mode-streaming/spec.md`

**Note**: This template is filled in by the `/speckit.plan` command. See `.specify/templates/commands/plan.md` for the execution workflow.

## Summary

**Primary Requirement**: Enable BravenChart to operate in mutually exclusive streaming or interactive modes, preventing rendering pipeline errors (box.dart:3345, mouse_tracker.dart:199) caused by ValueListenableBuilder rebuilds during MouseTracker hit testing.

**Technical Approach**: Implement dual-mode architecture where chart operates in exactly one mode at any time:
- **Streaming Mode**: Data updates freely, interaction handlers disabled at widget tree level, auto-scroll enabled, no ValueListenableBuilder rebuilds during interaction
- **Interactive Mode**: Streaming paused, data buffered (FIFO queue, max 10K points), full interaction enabled, ValueListenableBuilder rebuilds safe (no mouse tracking conflicts)
- **Mode Transitions**: Automatic on first interaction (streaming→interactive) and timeout-based auto-resume (interactive→streaming, 10s default)
- **Critical Pattern**: Use ValueNotifier + conditional widget wrapping (not setState) to avoid MouseTracker conflicts per Constitution II Performance First

## Technical Context

**Language/Version**: Dart 3.10.0-227.0.dev, Flutter SDK 3.37.0-1.0.pre-216  
**Primary Dependencies**: Standard Dart libraries only (dart:core, dart:async for Timer, dart:ui for rendering)  
**Storage**: N/A (stateless widget with external data sources)  
**Testing**: Flutter test framework (flutter test), ChromeDriver integration tests (flutter drive), golden tests for visual regression  
**Target Platform**: Flutter Web (primary), iOS/Android (secondary) - web-first deployment
**Project Type**: Single library project (braven_charts package)  
**Performance Goals**: 60 FPS rendering for streaming mode (100+ points/sec), <16ms interaction response in interactive mode, <50ms mode transitions  
**Constraints**: Zero rendering errors (box.dart:3345, mouse_tracker.dart:199), stable memory (no unbounded growth during 1-hour sessions), no data loss (forced auto-resume when buffer fills)  
**Scale/Scope**: Single chart widget with dual-mode state management, ~5 new classes (ChartMode enum, StreamingConfig, buffer management), integration into existing BravenChart widget (~2000 LOC)

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

### I. Test-First Development ✅ PASS
- **Requirement**: TDD mandatory, tests before implementation
- **Plan**: Will create unit tests for mode transitions, integration tests for streaming+interaction cycles, performance benchmarks for 60fps target
- **Status**: Compliant - tests will be written first per TDD

### II. Performance First (60fps Target) ✅ PASS
- **Requirement**: 60fps/16ms targets, ValueNotifier for >10Hz updates, no setState during interactions
- **Plan**: 
  - Using ValueNotifier + ValueListenableBuilder pattern (not setState) ✅
  - Conditional widget wrapping to disable interactions in streaming mode ✅
  - RepaintBoundary isolation for mode-specific rendering ✅
  - Performance benchmarks required before merge ✅
- **Critical Pattern Compliance**: 
  - ✅ NO setState for high-frequency updates (>10Hz streaming data)
  - ✅ ValueNotifier + ValueListenableBuilder for all state changes
  - ✅ RepaintBoundary to isolate repainting layers
  - ✅ Interaction handlers disabled during streaming mode (prevents MouseTracker conflicts)
- **Status**: Compliant - architecture prevents box.dart/mouse_tracker.dart errors by design

### III. Architectural Integrity ✅ PASS
- **Requirement**: Pure Flutter, SOLID principles, no circular dependencies
- **Plan**: Pure Dart/Flutter implementation, clear separation (ChartMode enum, StreamingConfig class, buffer manager), integrates with existing BravenChart widget
- **Status**: Compliant - clean architecture, no web-specific APIs

### IV. Requirements Compliance ✅ PASS
- **Requirement**: Stop and ask if deviating, update tasks.md for all changes
- **Plan**: Following spec requirements exactly, tasks.md will track all implementation progress and deviations
- **Status**: Compliant - spec-driven development

### V. API Consistency & Stability ⚠️ BREAKING CHANGE
- **Requirement**: Maintain backward compatibility, breaking changes require major version + migration guide
- **Breaking Change**: BravenChart constructor will require new StreamingConfig parameter for charts with streaming data
- **Migration Plan Required**: 
  - Provide migration guide showing old vs new API usage
  - Document deprecation path for existing non-streaming charts (StreamingConfig optional/null for backward compatibility)
  - Version increment: MINOR (1.x.0 → 1.y.0) with breaking change notice
- **Status**: ⚠️ Requires migration documentation (will create in Phase 1)

### VI. Documentation Discipline ✅ PASS
- **Requirement**: Public APIs documented with examples, ADRs for major decisions
- **Plan**: Will document StreamingConfig API, mode transition behavior, buffer management, provide examples in quickstart.md
- **Status**: Compliant - comprehensive docs planned

### VII. Simplicity & Pragmatism ✅ PASS
- **Requirement**: KISS principle, SOLID design, justify complexity
- **Plan**: Simplest solution (mode enum + conditional rendering), no over-engineering, complexity justified by preventing rendering errors
- **Status**: Compliant - minimal complexity for maximum impact

**OVERALL GATE STATUS**: ✅ PASS with breaking change notice
- **Action Required**: Create migration guide in Phase 1 documenting API changes and backward compatibility strategy

## Project Structure

### Documentation (this feature)

```
specs/009-dual-mode-streaming/
├── plan.md              # This file (/speckit.plan command output)
├── spec.md              # Business requirements (already created)
├── research.md          # Phase 0 output (/speckit.plan command)
├── data-model.md        # Phase 1 output (/speckit.plan command)
├── quickstart.md        # Phase 1 output (/speckit.plan command)
├── contracts/           # Phase 1 output (/speckit.plan command)
│   └── streaming_config_api.dart  # API contract for StreamingConfig class
├── checklists/
│   └── requirements.md  # Requirements validation (already created)
└── tasks.md             # Phase 2 output (/speckit.tasks command - NOT created by /speckit.plan)
```

### Source Code (repository root)

```
lib/src/
├── models/
│   ├── chart_mode.dart              # NEW: Enum for streaming/interactive modes
│   └── streaming_config.dart        # NEW: Configuration class for dual-mode behavior
├── widgets/
│   └── braven_chart.dart            # MODIFIED: Add dual-mode state management
├── renderers/
│   └── [existing renderers]         # MODIFIED: Respect mode-based rendering
└── utils/
    └── buffer_manager.dart          # NEW: FIFO buffer for interactive mode data

test/
├── unit/
│   ├── models/
│   │   ├── chart_mode_test.dart     # NEW: Unit tests for ChartMode enum
│   │   └── streaming_config_test.dart  # NEW: Unit tests for StreamingConfig
│   └── utils/
│       └── buffer_manager_test.dart # NEW: Unit tests for buffer FIFO logic
├── integration/
│   └── dual_mode_streaming_test.dart  # NEW: Integration tests for mode transitions
└── performance/
    └── streaming_benchmark.dart     # NEW: 60fps streaming + interaction benchmarks
```

**Structure Decision**: Single library project structure. All new code integrates into existing `lib/src/` organization. New classes follow established patterns (models/, widgets/, utils/). Tests mirror source structure per convention.

## Complexity Tracking

*Fill ONLY if Constitution Check has violations that must be justified*

**No violations requiring justification.** Breaking change (API addition) is expected for new features and follows proper migration path (Constitution V).

---

## Phase 0: Research & Technical Decisions ✅ COMPLETE

**Status**: All technical decisions resolved. See [research.md](./research.md) for details.

**Key Decisions**:
1. **ValueNotifier + ValueListenableBuilder** for mode management (Constitution II compliance)
2. **Conditional widget wrapping** to disable interaction handlers (cleaner than IgnorePointer)
3. **Timer-based auto-resume** with cancellation/recreation on interactions
4. **dart:collection Queue** for FIFO buffer (O(1) operations)
5. **RepaintBoundary isolation** for performance-critical rendering
6. **Callback-based developer hooks** (no built-in logging per clarification)
7. **Synchronous mode transitions** with state guards (prevents race conditions)
8. **Auto-scroll integration** with existing viewport logic

**Performance Validation Strategy**:
- Streaming: 100 points/sec for 10 minutes, sustained 60fps
- Transitions: <50ms latency, rapid pause/resume cycles
- Interaction: <16ms response time during interactive mode
- Buffer: Fill to 10K points without frame drops

**Migration Path**: StreamingConfig optional/nullable for backward compatibility with non-streaming charts.

---

## Phase 1: Design & Contracts ✅ COMPLETE

**Status**: Data model, API contracts, and quickstart guide complete.

**Deliverables**:
- ✅ [data-model.md](./data-model.md) - Core entities (ChartMode, StreamingConfig, Buffer, Timer, Mode Transitions)
- ✅ [contracts/streaming_api_contract.dart](./contracts/streaming_api_contract.dart) - Public API surface with FR/SC coverage checklist
- ✅ [quickstart.md](./quickstart.md) - Developer integration guide with examples

**Core Entities**:
1. **ChartMode enum**: `streaming` | `interactive` (mutual exclusivity)
2. **StreamingConfig class**: Configuration with callbacks (onModeChanged, onBufferUpdated, onReturnToLive, onStreamError)
3. **Buffer (Queue<DataPoint>)**: FIFO queue, max 10K points, force resume when full
4. **Auto-Resume Timer**: Countdown with reset on interactions, triggers resume on timeout
5. **Mode Transition**: Atomic state changes with cleanup/initialization

**API Surface**:
- Public: `StreamingConfig`, `ChartMode`, `BravenChart.resumeStreaming()`
- Internal: `_chartMode`, `_bufferedPoints`, `_autoResumeTimer`, transition methods

**Backward Compatibility**: StreamingConfig optional for non-streaming charts, required for Stream data sources.

---

## Phase 2: Task Breakdown (NEXT STEP)

**Status**: Not started. Run `/speckit.tasks` to generate implementation task breakdown.

**Expected Output**: `tasks.md` with atomic implementation tasks based on:
- Phase 0 research decisions
- Phase 1 data model design
- API contracts and requirements
- Constitution compliance checklist

---

## Artifacts Generated

| File | Status | Purpose |
|------|--------|---------|
| spec.md | ✅ Complete | Business requirements and user scenarios |
| checklists/requirements.md | ✅ Complete | Requirements validation and coverage analysis |
| plan.md | ✅ Complete | This file - implementation plan with technical context |
| research.md | ✅ Complete | Technical decisions and best practices |
| data-model.md | ✅ Complete | Core entities, relationships, validation rules |
| contracts/streaming_api_contract.dart | ✅ Complete | Public API surface with FR/SC coverage |
| quickstart.md | ✅ Complete | Developer integration guide with examples |
| tasks.md | ⏳ Pending | Task breakdown (run `/speckit.tasks`) |

---

## Constitution Check Re-Validation (Post-Design)

### I. Test-First Development ✅ PASS
- Benchmark strategy defined (streaming, transitions, interaction, buffer)
- Test file structure planned in project structure section
- Golden tests for visual regression included

### II. Performance First ✅ PASS
- ValueNotifier + ValueListenableBuilder pattern confirmed in research.md
- RepaintBoundary isolation documented
- No setState during interactions (architectural constraint)
- Performance benchmarks defined with specific targets

### III. Architectural Integrity ✅ PASS
- Pure Dart/Flutter (dart:core, dart:async, dart:ui only)
- SOLID principles: ChartMode (SRP), StreamingConfig (OCP), clean interfaces
- No circular dependencies in entity relationships
- Integrates with existing coordinate system

### IV. Requirements Compliance ✅ PASS
- All 20+ FRs mapped to API contracts (checklist in streaming_api_contract.dart)
- All 10 SCs mapped to benchmarks
- Clarifications integrated (no validation, fail-fast errors, independent instances, no logging, forced resume)

### V. API Consistency & Stability ✅ PASS
- Migration guide in quickstart.md (before/after examples)
- Backward compatibility strategy defined (StreamingConfig optional)
- Breaking change documented with examples

### VI. Documentation Discipline ✅ PASS
- API contracts with comprehensive examples
- quickstart.md with basic/advanced patterns
- Inline documentation in contract file
- Architecture explained in data-model.md

### VII. Simplicity & Pragmatism ✅ PASS
- KISS: Mode enum + conditional rendering (simplest solution)
- Complexity justified: Prevents rendering errors, no simpler alternative
- No over-engineering: Queue, Timer, ValueNotifier (all standard library)

**OVERALL STATUS**: ✅ ALL GATES PASS - Ready for implementation

---

## Next Command

Run `/speckit.tasks` to generate atomic implementation task breakdown in `tasks.md`.

