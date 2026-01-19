# Implementation Plan: Interaction System

**Branch**: `007-interaction-system` | **Date**: 2025-01-07 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `specs/007-interaction-system/spec.md`

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
6. Execute Phase 1 → contracts, data-model.md, quickstart.md, agent-specific template file (e.g., `claude.md` for Claude Code, `.github/copilot-instructions.md` for GitHub Copilot, `gemini.md` for Gemini CLI, `qwen.md` for Qwen Code, or `agents.md` for all other agents).
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

The Interaction System (Layer 7) provides professional-grade user interaction capabilities for chart exploration. It enables users to inspect data points through crosshairs and tooltips, navigate large datasets via zoom/pan controls, and interact using mouse, touch, and keyboard inputs. The system must maintain <100ms response times and 60 FPS performance while supporting all chart types and platforms (web, iOS, Android, desktop).

**Technical Approach**: Build a unified event processing system that translates platform-specific inputs (mouse/touch/keyboard) into chart coordinate space, then delegates to specialized interaction handlers (crosshair, tooltip, zoom/pan, gesture recognition). Use Flutter's GestureDetector for gesture recognition, CustomPainter for crosshair/tooltip rendering, and Flutter's accessibility APIs for keyboard navigation and screen reader support.

## Technical Context

**Language/Version**: Dart 3.10.0-227.0.dev, Flutter SDK 3.37.0-1.0.pre-216  
**Primary Dependencies**: Flutter framework (dart:ui for rendering, dart:async for streams)  
**Storage**: N/A (stateless interaction state, no persistence)  
**Testing**: Flutter test framework (flutter test), widget tests, integration tests  
**Target Platform**: Flutter Web (primary), iOS, Android, desktop (Windows/macOS/Linux)  
**Project Type**: Single Flutter library project  
**Performance Goals**: <100ms interaction response time (99th percentile), 60 FPS during zoom/pan, <2ms crosshair render  
**Constraints**: <5ms event processing overhead, <5MB memory overhead, zero memory leaks after 10,000 interactions  
**Scale/Scope**: 7 core interaction systems (events, crosshair, tooltip, zoom/pan, gestures, keyboard, callbacks), 147 total tests

## Constitution Check

_GATE: Must pass before Phase 0 research. Re-check after Phase 1 design._

### I. Test-First Development

- [x] **TDD Approach**: All interaction handlers will have unit tests written BEFORE implementation
- [x] **Test Coverage**: 147 tests planned (110 unit, 25 integration, 12 widget)
- [x] **Test Categories**: Event processing, crosshair rendering, tooltip positioning, zoom/pan, gestures, keyboard, callbacks
- [x] **Red-Green-Refactor**: Tests will fail initially, then implementation makes them pass
- [ ] **Status**: Tests to be written in Phase 1, implementation in Phase 3

### II. Performance First (60fps Target)

- [x] **Frame Budget**: All rendering operations <16ms (crosshair <2ms target)
- [x] **Response Time**: Event processing <5ms, total interaction <100ms
- [x] **Memory**: <5MB overhead, zero leaks after 10,000 interactions
- [x] **Optimization**: Spatial indexing for snap-to-point, viewport culling for large datasets
- [x] **Profiling Plan**: Performance benchmarks for event processing, rendering, gesture recognition
- [ ] **Status**: Performance targets documented, benchmarks to be created in Phase 1

### III. Architectural Integrity (Pure Flutter)

- [x] **Pure Flutter**: Using dart:ui, dart:async, Flutter GestureDetector, CustomPainter only
- [x] **No Web APIs**: No HTML elements, JavaScript interop, or web-specific code
- [x] **Layer Integration**: Integrates with Layer 5 (BravenChart widget), uses Layer 2 (CoordinateTransformer)
- [x] **SOLID Design**: Separate interfaces for event handling, rendering, gesture recognition
- [ ] **Status**: Architecture compliant, contracts to be defined in Phase 1

### IV. Requirements Compliance

- [x] **Spec Located**: specs/007-interaction-system/spec.md (512 lines, complete)
- [x] **Requirements Tracked**: 7 functional (FR-001 to FR-007), 17 non-functional (NFR-001 to NFR-017)
- [x] **Tasks.md Commitment**: Will update tasks.md after EVERY completed task
- [x] **Deviation Protocol**: Any architecture changes require tasks.md update with rationale
- [ ] **Status**: Tasks.md to be generated in Phase 2 (/tasks command)

### V. API Consistency & Stability

- [x] **Flutter Conventions**: InteractionConfig, CrosshairConfig, TooltipConfig follow Flutter patterns
- [x] **Backward Compatibility**: No breaking changes to existing chart widgets
- [x] **Naming**: lowerCamelCase for methods/properties, UpperCamelCase for classes
- [x] **Callbacks**: Optional nullable callbacks (onDataPointTap, onZoomChange, etc.)
- [ ] **Status**: API design to be documented in Phase 1 (contracts/)

### VI. Documentation Discipline

- [x] **Public APIs**: All config classes and callbacks require dartdoc comments
- [x] **Complex Algorithms**: Snap-to-point logic, gesture state machine, smart tooltip positioning
- [x] **Coordinate Transformations**: Event coordinate translation to chart data space
- [x] **Examples**: Minimum 8 examples in quickstart.md (per spec success metrics)
- [ ] **Status**: Quickstart.md to be created in Phase 1 with executable examples

### VII. Simplicity & Pragmatism (KISS)

- [x] **Use Flutter Primitives**: Leverage GestureDetector, not custom gesture engine
- [x] **Avoid Over-Engineering**: Simple event delegation, no complex state machines unless needed
- [x] **SOLID Adherence**: Single responsibility (separate crosshair, tooltip, zoom/pan classes)
- [x] **Research First**: Research gesture conflict resolution patterns before implementation
- [ ] **Status**: Simplicity validated, research to be completed in Phase 0

**Initial Constitution Check**: ✅ PASS (All principles followed, no violations detected)

## Project Structure

### Documentation (this feature)

```
specs/007-interaction-system/
├── spec.md              # User-facing specification (complete)
├── plan.md              # This file (/plan command output)
├── research.md          # Phase 0 output (/plan command)
├── data-model.md        # Phase 1 output (/plan command)
├── quickstart.md        # Phase 1 output (/plan command)
├── contracts/           # Phase 1 output (/plan command)
│   ├── i_event_handler.dart
│   ├── i_crosshair_renderer.dart
│   ├── i_tooltip_provider.dart
│   ├── i_gesture_recognizer.dart
│   └── i_keyboard_handler.dart
└── tasks.md             # Phase 2 output (/tasks command - NOT created by /plan)
```

### Source Code (repository root)

```
lib/
├── src/
│   ├── interaction/                    # NEW: Interaction system (Layer 7)
│   │   ├── models/
│   │   │   ├── interaction_state.dart  # InteractionState entity
│   │   │   ├── zoom_pan_state.dart     # ZoomPanState entity
│   │   │   ├── gesture_details.dart    # GestureDetails entity
│   │   │   ├── crosshair_config.dart   # CrosshairConfig entity
│   │   │   └── tooltip_config.dart     # TooltipConfig entity
│   │   ├── event_handler.dart          # FR-001: Event processing
│   │   ├── crosshair_renderer.dart     # FR-002: Crosshair system
│   │   ├── tooltip_provider.dart       # FR-003: Tooltip system
│   │   ├── zoom_pan_controller.dart    # FR-004: Zoom/pan controls
│   │   ├── gesture_recognizer.dart     # FR-005: Gesture recognition
│   │   ├── keyboard_handler.dart       # FR-006: Keyboard navigation
│   │   └── interaction_callbacks.dart  # FR-007: Developer callbacks
│   ├── core/                           # EXISTING: Layers 0-2
│   ├── theming/                        # EXISTING: Layer 3
│   ├── chart_types/                    # EXISTING: Layer 4
│   └── widgets/                        # EXISTING: Layer 5
│       └── braven_chart.dart           # Integration point for interactions
├── braven_charts.dart                  # Main library export

test/
├── interaction/                        # NEW: Interaction tests
│   ├── unit/
│   │   ├── event_handler_test.dart     # 15 tests
│   │   ├── crosshair_renderer_test.dart # 18 tests
│   │   ├── tooltip_provider_test.dart   # 20 tests
│   │   ├── zoom_pan_controller_test.dart # 22 tests
│   │   ├── gesture_recognizer_test.dart  # 20 tests
│   │   └── keyboard_handler_test.dart    # 15 tests
│   ├── integration/
│   │   ├── crosshair_tooltip_test.dart   # 8 tests
│   │   ├── zoom_pan_gestures_test.dart   # 10 tests
│   │   └── keyboard_navigation_test.dart # 7 tests
│   └── widgets/
│       ├── interaction_widget_test.dart  # 12 tests
│       └── accessibility_test.dart       # Performance/a11y validation
```

**Structure Decision**: Single Flutter library project. The interaction system is a new layer (Layer 7) added to the existing lib/src/ structure. All interaction components live under `lib/src/interaction/` with clear separation between models, event processing, rendering, and input handling. Tests mirror the source structure under `test/interaction/` with unit, integration, and widget test categories.

## Phase 0: Outline & Research

### Research Tasks

All technical context is clear from the feature spec and existing project structure. Research focused on Flutter patterns and best practices for interaction implementation:

1. **Flutter Gesture Detection System**
   - Research Flutter's GestureDetector capabilities and limitations
   - Investigate gesture conflict resolution patterns
   - Understand gesture arena and pointer event handling

2. **Coordinate Transformation Approaches**
   - Review existing CoordinateTransformer implementation (Layer 2)
   - Understand screen-to-chart and chart-to-data coordinate conversions
   - Research viewport transformations during zoom/pan

3. **Accessibility APIs (WCAG 2.1 AA)**
   - Research Flutter's Semantics widget for screen reader support
   - Investigate keyboard navigation patterns in Flutter
   - Study focus indicator implementation (3:1 contrast requirement)

4. **Performance Optimization Strategies**
   - Research spatial indexing for snap-to-point performance
   - Investigate viewport culling for large datasets
   - Study Flutter's CustomPainter performance best practices

5. **Cross-Platform Touch/Mouse Handling**
   - Research platform-specific gesture differences (web vs mobile)
   - Understand mouse wheel events in Flutter web
   - Investigate touch event handling on iOS/Android

**Output**: research.md with consolidated findings and architectural decisions

**Status**: ✅ Research scope defined, execution delegated to research.md generation

## Phase 1: Design & Contracts

_Prerequisites: research.md complete_

### Entity Extraction

From feature spec Key Entities section, extract to `data-model.md`:

- **InteractionState**: Current state of all user interactions (hovered point, focused point, selections, crosshair, tooltip, zoom/pan, active gesture)
- **ZoomPanState**: Zoom levels (X/Y), pan offset, visible data bounds
- **GestureDetails**: Gesture type, positions, scale/delta, timestamp
- **CrosshairConfig**: Enabled flag, mode, snap settings, line style, coordinate labels
- **TooltipConfig**: Enabled flag, trigger mode, delays, positioning, style, custom builder

### API Contract Generation

From functional requirements (FR-001 to FR-007), generate interface contracts:

- **IEventHandler**: `processEvent(PointerEvent) → ChartEvent`
- **ICrosshairRenderer**: `renderCrosshair(Canvas, InteractionState) → void`
- **ITooltipProvider**: `showTooltip(ChartDataPoint) → Widget`
- **IGestureRecognizer**: `recognizeGesture(PointerEvent) → GestureDetails`
- **IKeyboardHandler**: `handleKeyEvent(RawKeyEvent) → KeyEventResult`

### Contract Test Generation

For each contract interface, create failing test:

- `test/interaction/contracts/event_handler_contract_test.dart`
- `test/interaction/contracts/crosshair_renderer_contract_test.dart`
- `test/interaction/contracts/tooltip_provider_contract_test.dart`
- `test/interaction/contracts/gesture_recognizer_contract_test.dart`
- `test/interaction/contracts/keyboard_handler_contract_test.dart`

### Test Scenario Extraction

From user scenarios (Scenarios 1-4), create integration tests:

- **Scenario 1**: Crosshair + Tooltip interaction (crosshair_tooltip_test.dart)
- **Scenario 2**: Zoom and Pan (zoom_pan_gestures_test.dart)
- **Scenario 3**: Touch Gestures (zoom_pan_gestures_test.dart - mobile section)
- **Scenario 4**: Keyboard Navigation (keyboard_navigation_test.dart)

### Quickstart Example Extraction

From spec Success Metrics (Developer Experience), create 8+ executable examples:

1. Basic crosshair enablement
2. Custom crosshair styling
3. Tooltip with default content
4. Tooltip with custom builder
5. Zoom/pan configuration
6. Gesture handling with callbacks
7. Keyboard navigation setup
8. Complete interaction configuration

### Agent Context Update

Run update script to add Interaction System to agent context:

```powershell
.\.specify\scripts\powershell\update-agent-context.ps1 -AgentType copilot
```

**Output**: data-model.md, contracts/, failing contract tests, quickstart.md, updated .github/copilot-instructions.md

**Status**: ⏳ Ready to execute (next step in workflow)

## Phase 2: Task Planning Approach

_This section describes what the /tasks command will do - DO NOT execute during /plan_

**Task Generation Strategy**:
The /tasks command will load `.specify/templates/tasks-template.md` and generate granular implementation tasks based on Phase 1 design documents.

**Task Sources**:

1. **From contracts/** → Contract test tasks (failing tests first)
   - Each interface → one contract test file
   - Test that interface requirements are met

2. **From data-model.md** → Model creation tasks
   - Each entity → one model implementation task
   - Validation rules → unit tests per entity

3. **From quickstart.md** → Integration test tasks
   - Each example → one integration test scenario
   - Verify example code executes correctly

4. **From functional requirements (FR-001 to FR-007)** → Implementation tasks
   - Event Handler implementation (FR-001)
   - Crosshair Renderer implementation (FR-002)
   - Tooltip Provider implementation (FR-003)
   - Zoom/Pan Controller implementation (FR-004)
   - Gesture Recognizer implementation (FR-005)
   - Keyboard Handler implementation (FR-006)
   - Interaction Callbacks implementation (FR-007)

**Task Ordering Strategy**:

- **TDD Order**: Contract tests → Model creation → Unit tests → Implementation → Integration tests
- **Dependency Order**:
  1. Models (InteractionState, ZoomPanState, etc.) - no dependencies
  2. Event Handler - depends on models
  3. Crosshair/Tooltip - depends on models + event handler
  4. Zoom/Pan - depends on models + event handler
  5. Gestures - depends on models + event handler
  6. Keyboard - depends on models + event handler
  7. Callbacks - depends on all above
  8. Widget integration - depends on all above

**Parallel Execution Markers [P]**:

- Model creation tasks can run in parallel (independent)
- Unit test tasks can run in parallel (isolated)
- Contract test tasks can run in parallel (independent)

**Estimated Task Count**:

- Phase 1 artifacts: 15-20 tasks
  - 5 contract test files
  - 5 model implementation tasks
  - 5-10 model validation unit tests
- Phase 2 implementation: 40-50 tasks
  - 7 component implementations (one per FR)
  - 30-40 unit tests (110 total tests)
  - 3-5 integration tests (25 total tests)
- Phase 3 testing: 10-15 tasks
  - Widget test implementation (12 tests)
  - Performance benchmarks
  - Accessibility validation
- **Total: ~75-90 numbered, ordered tasks**

**Task Template Format** (from tasks-template.md):

```markdown
## Task ###: [Task Name]

**Type**: [Contract Test | Unit Test | Implementation | Integration Test | Documentation]
**SDLC Phase**: [Planning | Implementation | Testing | Deployment]
**Status**: [Not Started | In Progress | Complete | Blocked]
**Parallel**: [Yes/No]
**Dependencies**: [Task numbers or "None"]

### Description

[What needs to be done]

### Acceptance Criteria

- [ ] Criterion 1
- [ ] Criterion 2

### Technical Notes

[Implementation details, edge cases, performance requirements]
```

**IMPORTANT**: The /tasks command will execute this strategy and create tasks.md. This phase is NOT executed by /plan.

**Status**: ⏳ Ready for /tasks command execution

## Phase 3+: Future Implementation

_These phases are beyond the scope of the /plan command_

**Phase 3**: Task execution (/tasks command creates tasks.md)  
**Phase 4**: Implementation (execute tasks.md following constitutional principles)  
**Phase 5**: Validation (run tests, execute quickstart.md, performance validation)

## Complexity Tracking

_Fill ONLY if Constitution Check has violations that must be justified_

**Status**: ✅ No Violations

All constitutional principles satisfied:

- ✅ Test-First Development: 147 tests planned, TDD approach documented
- ✅ Performance First: <100ms response, 60 FPS targets, spatial indexing for optimization
- ✅ Architectural Integrity: Pure Flutter, no web APIs, SOLID design with interface contracts
- ✅ Requirements Compliance: spec.md tracked, tasks.md commitment documented
- ✅ API Consistency: Flutter conventions followed, no breaking changes
- ✅ Documentation Discipline: dartdoc comments required, 9 executable examples created
- ✅ Simplicity & Pragmatism: Using Flutter's GestureDetector, no custom gesture engine

No complexity deviations to document.

## Progress Tracking

_This checklist is updated during execution flow_

**Phase Status**:

- [x] Phase 0: Research complete (/plan command) - ✅ research.md created (2025-01-07)
- [x] Phase 1: Design complete (/plan command) - ✅ All artifacts created (2025-01-07)
  - data-model.md (5 entities, complete)
  - contracts/ (5 interface files, complete)
  - quickstart.md (9 executable examples, complete)
- [ ] Phase 2: Task planning complete (/plan command - described approach only) - ⏳ Ready for /tasks
- [ ] Phase 3: Tasks generated (/tasks command)
- [ ] Phase 4: Implementation complete
- [ ] Phase 5: Validation passed

**Gate Status**:

- [x] Initial Constitution Check: ✅ PASS (All principles followed)
- [x] Post-Design Constitution Check: ✅ PASS (No violations, pure Flutter, SOLID design)
- [x] All NEEDS CLARIFICATION resolved: ✅ None (all technical context clear)
- [x] Complexity deviations documented: ✅ None (no violations)

**Artifacts Created**:

1. ✅ specs/007-interaction-system/plan.md (this file)
2. ✅ specs/007-interaction-system/research.md (150+ lines, architectural decisions)
3. ✅ specs/007-interaction-system/data-model.md (400+ lines, 5 entities with validation)
4. ✅ specs/007-interaction-system/contracts/ (5 interface files)
   - i_event_handler.dart
   - i_crosshair_renderer.dart
   - i_tooltip_provider.dart
   - i_gesture_recognizer.dart
   - i_keyboard_handler.dart
5. ✅ specs/007-interaction-system/quickstart.md (500+ lines, 9 examples)

**Next Command**: `/tasks` to generate tasks.md with ~75-90 implementation tasks

---

_Based on Constitution v1.0.0 - See `.specify/memory/constitution.md`_
