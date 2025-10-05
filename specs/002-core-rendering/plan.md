
# Implementation Plan: Core Rendering Engine

**Branch**: `002-core-rendering` | **Date**: 2025-10-05 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/002-core-rendering/spec.md`

## Execution Flow (/plan command scope)
```
1. Load feature spec from Input path
   → If not found: ERROR "No feature spec at {path}"
2. Fill Technical Context (scan for NEEDS CLARIFICATION)
   → Detect Project Type from file system structure or context (web=frontend+backend, mobile=app+api)
   → Set Structure Decision based on project type
3. Fill the Constitution Check section based on the content of the constitution document.
4. Evaluate Constitution Check section below
   → If violations exist: Document in Complexity Tracking
   → If no justification possible: ERROR "Simplify approach first"
   → Update Progress Tracking: Initial Constitution Check
5. Execute Phase 0 → research.md
   → If NEEDS CLARIFICATION remain: ERROR "Resolve unknowns"
6. Execute Phase 1 → contracts, data-model.md, quickstart.md, agent-specific template file (e.g., `CLAUDE.md` for Claude Code, `.github/copilot-instructions.md` for GitHub Copilot, `GEMINI.md` for Gemini CLI, `QWEN.md` for Qwen Code, or `AGENTS.md` for all other agents).
7. Re-evaluate Constitution Check section
   → If new violations: Refactor design, return to Phase 1
   → Update Progress Tracking: Post-Design Constitution Check
8. Plan Phase 2 → Describe task generation approach (DO NOT create tasks.md)
9. STOP - Ready for /tasks command
```

**IMPORTANT**: The /plan command STOPS at step 7. Phases 2-4 are executed by other commands:
- Phase 2: /tasks command creates tasks.md
- Phase 3-4: Implementation execution (manual or via tools)

## Summary

The Core Rendering Engine provides high-performance chart visualization through object pooling for Flutter canvas primitives (Paint, Path, TextPainter), a composable layer-based rendering pipeline, viewport culling/clipping for large datasets, real-time performance monitoring, and text layout caching. This layer builds upon the Foundation Layer (001-foundation) to deliver 60fps rendering for charts with 10,000+ data points, achieving <8ms average frame time through aggressive optimization and zero-allocation rendering strategies.

## Technical Context
**Language/Version**: Dart 3.0+ (Dart 3.10.0-227.0.dev)  
**Primary Dependencies**: Flutter SDK 3.37.0-1.0.pre-216, Foundation Layer (ObjectPool<T>, ViewportCuller, ChartDataPoint, ChartResult<T>)  
**Storage**: N/A (in-memory rendering state)  
**Testing**: flutter test (unit/contract/integration), flutter drive (visual validation), benchmark_harness (performance)  
**Target Platform**: Flutter Web (primary), iOS/Android/Desktop (secondary via Flutter cross-platform)
**Project Type**: Single Flutter project (lib/ for implementation, test/ for all test types)  
**Performance Goals**: 60fps (16ms budget), <8ms avg frame time, <16ms p99, >90% pool hit rate, >70% text cache hit rate  
**Constraints**: Zero external packages (Dart stdlib only per constitution), zero GC pressure during steady-state, pixel-perfect rendering accuracy  
**Scale/Scope**: Support 10,000+ visible data points, unlimited layers (performance scales with visible elements), 500-entry text cache, dynamic pool sizing

## Constitution Check
*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

**I. Test-First Development (TDD)**: ✅ PASS
- All contracts will have failing tests before implementation
- Performance benchmarks define acceptance before code
- Integration tests from user scenarios (spec §User Scenarios 1-4)
- Contract tests for RenderLayer interface, ObjectPool usage
- Red-Green-Refactor mandatory per Foundation pattern

**II. Performance First (60fps)**: ✅ PASS  
- Target: <8ms avg, <16ms p99 frame time (spec §NFR-001)
- Object pooling eliminates per-frame allocation (spec §FR-001)
- Viewport culling reduces rendering to visible elements only (spec §FR-003)
- Performance monitoring built-in for profiling (spec §FR-004)
- Benchmarks required for all rendering paths

**III. Architectural Integrity (Pure Flutter)**: ✅ PASS
- Pure Flutter Canvas API (no HTML elements)
- Layered architecture: RenderContext → RenderPipeline → RenderLayer (spec §Key Entities)
- Dependency injection via RenderContext
- Foundation Layer provides ObjectPool, ViewportCuller (established patterns)
- SOLID principles: Single Responsibility per layer, Open-Closed via layer composition

**IV. Requirements Compliance**: ✅ PASS
- Spec has clear FR-001 to FR-005, NFR-001 to NFR-003
- No clarifications needed (verified by /clarify)
- tasks.md will track all deviations per constitution
- Implementation follows established Foundation patterns

**V. API Consistency & Stability**: ✅ PASS
- RenderLayer interface follows Flutter CustomPainter patterns
- ObjectPool<T> usage consistent with Foundation
- No breaking changes (new layer, builds on Foundation)
- All public APIs will have dartdoc comments

**VI. Documentation Discipline**: ✅ PASS
- ADRs for: pooling strategy, layer pipeline, culling algorithm, text caching
- Inline docs for complex rendering transformations
- Quickstart.md for layer creation examples
- Contracts define testable interfaces

**VII. Simplicity & Pragmatism (KISS)**: ✅ PASS
- Reuse Foundation ObjectPool (no reimplementation)
- Reuse Foundation ViewportCuller (proven algorithm)
- Simple layer pipeline: sort by zIndex, render visible layers
- Text cache: straightforward Map<String, TextPainter> with LRU
- No over-engineering (deferred GridLayer/SeriesLayer to higher layers per spec)

## Project Structure

### Documentation (this feature)
```
specs/002-core-rendering/
├── plan.md              # This file (/plan command output)
├── research.md          # Phase 0 output (/plan command)
├── data-model.md        # Phase 1 output (/plan command)
├── quickstart.md        # Phase 1 output (/plan command)
├── contracts/           # Phase 1 output (/plan command)
│   ├── render_layer.dart
│   ├── performance_monitor.dart
│   └── text_cache.dart
└── tasks.md             # Phase 2 output (/tasks command - NOT created by /plan)
```

### Source Code (repository root)
```
lib/
├── src/
│   ├── foundation/          # From 001-foundation (dependency)
│   │   ├── object_pool.dart
│   │   ├── viewport_culler.dart
│   │   ├── data_models.dart
│   │   └── ...
│   └── rendering/           # NEW in 002-core-rendering
│       ├── render_context.dart
│       ├── render_layer.dart
│       ├── render_pipeline.dart
│       ├── performance_monitor.dart
│       ├── performance_metrics.dart
│       └── text_layout_cache.dart
│
test/
├── unit/
│   └── rendering/           # Unit tests for rendering primitives
│       ├── render_context_test.dart
│       ├── render_pipeline_test.dart
│       ├── performance_monitor_test.dart
│       └── text_layout_cache_test.dart
├── contract/
│   └── rendering/           # Contract tests from contracts/
│       ├── render_layer_contract_test.dart
│       ├── performance_monitor_contract_test.dart
│       └── text_cache_contract_test.dart
└── integration/
    └── rendering/           # Integration tests from user scenarios
        ├── large_dataset_rendering_test.dart
        ├── multi_layer_rendering_test.dart
        ├── performance_monitoring_test.dart
        └── text_heavy_chart_test.dart
```

**Structure Decision**: Single Flutter project structure (lib/ and test/). This is a library feature, not an application. Rendering logic goes in lib/src/rendering/ following established Foundation pattern (lib/src/foundation/). Tests mirror source structure under test/unit/, test/contract/, test/integration/ per TDD constitution requirement. All files use Dart stdlib only (no external packages).

## Phase 0: Outline & Research
1. **Extract unknowns from Technical Context** above:
   - ✅ NO NEEDS CLARIFICATION present - all context clear from spec
   - ✅ Foundation Layer dependencies verified available
   - ✅ Performance targets defined in spec (NFR-001)

2. **Generate and dispatch research agents**:
   - ✅ Object pooling strategy (reuse Foundation ObjectPool<T>)
   - ✅ Layer pipeline architecture (RenderLayer + RenderPipeline)
   - ✅ Viewport culling integration (reuse Foundation ViewportCuller)
   - ✅ Performance monitoring approach (dart:core Stopwatch)
   - ✅ Text cache design (LinkedHashMap with LRU)
   - ✅ RenderContext pattern (immutable dependency injection)

3. **Consolidate findings** in `research.md` using format:
   - ✅ Decision 1: Object Pool Types and Strategy
   - ✅ Decision 2: Layer-Based Rendering Pipeline Architecture
   - ✅ Decision 3: Viewport Culling Integration with Foundation
   - ✅ Decision 4: Performance Monitoring Strategy  
   - ✅ Decision 5: Text Layout Cache Design
   - ✅ Decision 6: RenderContext Design Pattern
   - ✅ ADR-001 to ADR-004: Architecture Decision Records
   - ✅ Foundation integration points documented
   - ✅ Performance validation strategy defined

**Output**: ✅ research.md complete (all unknowns resolved)

## Phase 1: Design & Contracts
*Prerequisites: research.md complete*

1. **Extract entities from feature spec** → `data-model.md`:
   - ✅ Entity 1: RenderContext (dependency injection container)
   - ✅ Entity 2: RenderLayer (abstract visual element interface)
   - ✅ Entity 3: RenderPipeline (layer orchestration)
   - ✅ Entity 4: PerformanceMonitor (frame timing)
   - ✅ Entity 5: PerformanceMetrics (performance data snapshot)
   - ✅ Entity 6: TextLayoutCache (text layout caching)

2. **Generate API contracts** from functional requirements:
   - ✅ contracts/render_layer.dart (FR-002: Rendering Pipeline)
   - ✅ contracts/performance_monitor.dart (FR-004: Performance Monitoring)
   - ✅ contracts/text_layout_cache.dart (FR-005: Text Rendering)
   - Note: RenderContext, RenderPipeline, PerformanceMetrics are concrete classes (data holders, not interfaces)

3. **Generate contract tests** from contracts:
   - ⏭️ DEFERRED to tasks.md (Phase 2)
   - Contract tests written as first tasks (TDD workflow)
   - Tests must fail before implementation

4. **Extract test scenarios** from user stories:
   - ✅ quickstart.md created with 4 scenarios from spec:
     - Minimal working example (pipeline + layers)
     - Custom render layer implementation
     - Text rendering with caching
     - Viewport management (pan/zoom)
     - Performance monitoring and debugging
   - Integration tests derived from quickstart scenarios (Phase 2)

5. **Update agent file incrementally** (O(1) operation):
   - Execute: `.specify/scripts/powershell/update-agent-context.ps1 -AgentType copilot`
   - Will add Core Rendering Engine to active technologies
   - Preserve Foundation Layer references
   - Update recent changes (keep last 3 features)

**Output**: ✅ data-model.md (6 entities), contracts/ (3 contract files with TDD placeholders), quickstart.md (usage examples), agent file update pending

## Phase 2: Task Planning Approach
*This section describes what the /tasks command will do - DO NOT execute during /plan*

**Task Generation Strategy**:
- Load `.specify/templates/tasks-template.md` as base
- Generate tasks from Phase 1 design docs (contracts, data model, quickstart)
- TDD Order: Contract tests → Entity tests → Integration tests → Implementation
- Each contract → contract test task before implementation [P]
- Each entity → unit test task before implementation [P]
- Each user scenario → integration test task
- Implementation tasks to make tests pass (Green phase of Red-Green-Refactor)

**Ordering Strategy**:
- **Phase 1**: Contract tests (all fail initially, parallel [P])
  - render_layer_contract_test.dart [P]
  - performance_monitor_contract_test.dart [P]
  - text_layout_cache_contract_test.dart [P]
  
- **Phase 2**: Entity unit tests (all fail, dependencies guide order)
  - performance_metrics_test.dart [P] (no dependencies)
  - text_layout_cache_test.dart [P] (no dependencies)
  - performance_monitor_test.dart (depends on PerformanceMetrics)
  - render_context_test.dart (depends on Foundation: ObjectPool, ViewportCuller)
  - render_layer_test.dart (depends on RenderContext)
  - render_pipeline_test.dart (depends on RenderLayer, RenderContext, PerformanceMonitor)

- **Phase 3**: Implementation (make tests pass)
  - performance_metrics.dart (simple data class) [P]
  - text_layout_cache.dart (no dependencies) [P]
  - performance_monitor.dart (depends on PerformanceMetrics)
  - render_context.dart (depends on Foundation)
  - render_layer.dart (abstract class, depends on RenderContext)
  - render_pipeline.dart (depends on all above)

- **Phase 4**: Integration tests (validate user scenarios from quickstart.md)
  - large_dataset_rendering_test.dart (Scenario 1: 10K points)
  - multi_layer_rendering_test.dart (Scenario 2: z-ordering)
  - performance_monitoring_test.dart (Scenario 3: metrics validation)
  - text_heavy_chart_test.dart (Scenario 4: cache hit rate)

**Parallel Execution Markers**:
- [P] indicates tasks can execute in parallel (independent files/tests)
- Phase 1 contract tests: All parallel
- Phase 2 entity tests: Parallel within dependency groups
- Phase 3 implementation: Parallel where no dependencies exist
- Phase 4 integration: Sequential (validate in order)

**Estimated Output**: 
- ~40-45 numbered, ordered tasks in tasks.md
- Breakdown: 3 contract tests + 12 unit tests + 6 implementations + 12 integration tests + setup/validation
- Duration: 2-4 weeks following TDD (test first, then code)

**IMPORTANT**: This phase is executed by the /tasks command, NOT by /plan

## Phase 3+: Future Implementation
*These phases are beyond the scope of the /plan command*

**Phase 3**: Task execution (/tasks command creates tasks.md)  
**Phase 4**: Implementation (execute tasks.md following constitutional principles)  
**Phase 5**: Validation (run tests, execute quickstart.md, performance validation)

## Complexity Tracking
*Fill ONLY if Constitution Check has violations that must be justified*

**No violations**. All constitutional requirements satisfied:
- ✅ TDD: Contracts written before implementation, tests-first workflow
- ✅ Performance: Targets defined (<8ms, >90% pool hit rate)
- ✅ Pure Flutter: No HTML, uses Flutter Canvas API
- ✅ Requirements Compliance: Spec complete, no clarifications needed
- ✅ API Consistency: Follows Foundation patterns (ObjectPool, immutability)
- ✅ Documentation: ADRs, contracts, quickstart, data model complete
- ✅ KISS: Reuses Foundation primitives, simple LinkedHashMap cache, no over-engineering

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| *None* | *N/A* | *N/A* |


## Progress Tracking
*This checklist is updated during execution flow*

**Phase Status**:
- [x] Phase 0: Research complete (/plan command) ✅
- [x] Phase 1: Design complete (/plan command) ✅
- [x] Phase 2: Task planning complete (/plan command - describe approach only) ✅
- [ ] Phase 3: Tasks generated (/tasks command) ⏭️ NEXT
- [ ] Phase 4: Implementation complete
- [ ] Phase 5: Validation passed

**Gate Status**:
- [x] Initial Constitution Check: PASS ✅
- [x] Post-Design Constitution Check: PASS ✅
- [x] All NEEDS CLARIFICATION resolved ✅ (none present)
- [x] Complexity deviations documented ✅ (none)

**Artifacts Generated**:
- [x] research.md (6 decisions, 4 ADRs, Foundation integration)
- [x] data-model.md (6 entities with relationships)
- [x] contracts/render_layer.dart (RenderLayer interface)
- [x] contracts/performance_monitor.dart (PerformanceMonitor interface)
- [x] contracts/text_layout_cache.dart (TextLayoutCache interface)
- [x] quickstart.md (4 usage scenarios, troubleshooting)
- [ ] .github/copilot-instructions.md update (pending script execution)
- [ ] tasks.md (pending /tasks command)

---
*Plan execution complete. Ready for /tasks command to generate implementation tasks.*
*Based on Constitution v1.0.0 - See `.specify/memory/constitution.md`*
