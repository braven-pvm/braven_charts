# Implementation Plan: Braven Agent Package

**Branch**: `004-braven-agent-package` | **Date**: 2026-01-28 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/004-braven-agent-package/spec.md`

**Base Specifications**:

- [004.1-braven-agent-extraction.md](../_base/004-braven-lab-studio-integration/004.1-braven-agent-extraction.md) - Complete implementation specification (v5.1)
- [technical-design.md](../_base/004-braven-lab-studio-integration/technical-design.md) - End-to-end implementation guide
- [decisions/](../_base/004-braven-lab-studio-integration/decisions/) - Architecture decision records

## Summary

Create a new `braven_agent` package that decouples AI orchestration from chart rendering. The package provides:

1. **AgentSession** - UI-bindable conversation state management with ValueNotifier
2. **LLM Layer** - Provider abstraction with Anthropic adapter for AI communication
3. **Tool System** - `create_chart` and `modify_chart` tools producing ChartConfiguration objects
4. **ChartRenderer** - Translates ChartConfiguration → BravenChartPlus widgets
5. **Demo App** - Validates package functionality with basic chat UI

Technical approach: Clean implementation from specification (NOT migration from `/agentic`). Only `ChartRenderer` and property wiring test are translated directly.

## Technical Context

**Language/Version**: Dart 3.0+, Flutter SDK 3.10.0+
**Primary Dependencies**: `braven_chart_plus` (path: ../../), `anthropic_sdk_dart: ^0.2.0`, `uuid: ^4.0.0`, `equatable: ^2.0.5`, `meta: ^1.11.0`, `async: ^2.11.0`, `collection: ^1.18.0`
**Storage**: N/A (session-local only, no persistence in V1)
**Testing**: `flutter test` with unit tests, widget tests, and integration tests
**Target Platform**: Flutter Web (primary), iOS/Android (secondary)
**Project Type**: Flutter package with embedded demo app
**Performance Goals**: 60 FPS for UI interactions, responsive state updates via ValueNotifier
**Constraints**: No domain-specific logic (athletes, FIT files, projects), domain-agnostic package
**Scale/Scope**: Single package with ~15 source files, 1 demo app

## Constitution Check

_GATE: Must pass before Phase 0 research. Re-check after Phase 1 design._

| Principle                     | Status       | Notes                                                                                        |
| ----------------------------- | ------------ | -------------------------------------------------------------------------------------------- |
| I. Test-First Development     | ✅ COMPLIANT | Property wiring test translated, new unit tests for tools/session                            |
| II. Performance First (60fps) | ✅ COMPLIANT | Using ValueNotifier + ValueListenableBuilder (NOT setState) for high-frequency state updates |
| III. Architectural Integrity  | ✅ COMPLIANT | Pure Flutter, clean separation: models/llm/tools/session/renderer layers                     |
| IV. Requirements Compliance   | ✅ COMPLIANT | Implementation follows 004.1 spec strictly, tasks.md will track deviations                   |
| V. API Consistency            | ✅ COMPLIANT | Following Flutter conventions, barrel file exports public API                                |
| VI. Documentation Discipline  | ✅ COMPLIANT | ADRs in decisions/, comprehensive doc comments in barrel file                                |
| VII. Simplicity (KISS)        | ✅ COMPLIANT | V1 excludes data tools, file attachments, history - MVP only                                 |

**Result**: ✅ All gates PASS - proceed to Phase 0

## Project Structure

### Documentation (this feature)

```
specs/004-braven-agent-package/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/           # Phase 1 output (API schemas)
└── tasks.md             # Phase 2 output (/speckit.tasks command)
```

### Source Code (repository root)

```
packages/braven_agent/
├── lib/
│   ├── braven_agent.dart              # Public API barrel file
│   └── src/
│       ├── models/                    # Domain models
│       │   ├── chart_configuration.dart
│       │   ├── series_config.dart
│       │   ├── axis_config.dart
│       │   ├── annotation_config.dart
│       │   └── chart_style_config.dart
│       ├── renderer/
│       │   └── chart_renderer.dart    # ChartConfiguration → Widget
│       ├── session/
│       │   ├── agent_session.dart     # Core session interface & impl
│       │   ├── session_state.dart     # Immutable state model
│       │   ├── agent_events.dart      # Event definitions
│       │   └── default_system_prompt.dart
│       ├── llm/
│       │   ├── llm_provider.dart      # Abstract interface
│       │   ├── llm_config.dart        # Configuration model
│       │   ├── llm_registry.dart      # Provider factory
│       │   ├── models/
│       │   │   └── agent_message.dart # Message & content types
│       │   └── providers/
│       │       └── anthropic_adapter.dart
│       └── tools/
│           ├── agent_tool.dart        # Abstract tool interface
│           ├── create_chart_tool.dart
│           └── modify_chart_tool.dart
├── test/
│   ├── tools/
│   │   ├── create_chart_tool_test.dart
│   │   └── modify_chart_tool_test.dart
│   ├── session/
│   │   └── agent_session_test.dart
│   ├── renderer/
│   │   └── property_wiring_test.dart  # Translated from /agentic
│   └── integration/
│       └── chart_creation_flow_test.dart
└── pubspec.yaml

example/lib/demos/
└── braven_agent_demo.dart             # Demo app for package validation
```

**Structure Decision**: Monorepo sub-package pattern. The `braven_agent` package lives in `packages/braven_agent/` and depends on `braven_chart_plus` via path reference. Demo app resides in existing `example/` directory.

## Complexity Tracking

_No violations - all constitution gates pass._

| Violation | Why Needed | Simpler Alternative Rejected Because |
| --------- | ---------- | ------------------------------------ |
| N/A       | N/A        | N/A                                  |

## Dependencies

### Package Dependencies (pubspec.yaml)

| Package              | Version      | Purpose                               |
| -------------------- | ------------ | ------------------------------------- |
| `braven_chart_plus`  | path: ../../ | Chart rendering library               |
| `anthropic_sdk_dart` | ^0.2.0       | Anthropic LLM API client              |
| `uuid`               | ^4.0.0       | UUID generation for IDs               |
| `equatable`          | ^2.0.5       | Value equality for models             |
| `meta`               | ^1.11.0      | Annotations (@immutable, @protected)  |
| `async`              | ^2.11.0      | CancelableOperation for request abort |
| `collection`         | ^1.18.0      | Collection utilities (if needed)      |

### Dev Dependencies

| Package        | Version | Purpose           |
| -------------- | ------- | ----------------- |
| `flutter_test` | sdk     | Widget testing    |
| `test`         | any     | Unit testing      |
| `mocktail`     | ^1.0.0  | Mocking for tests |

### External System Dependencies

| System              | Dependency Type | Notes                          |
| ------------------- | --------------- | ------------------------------ |
| Anthropic API       | Runtime         | Requires valid API key         |
| Internet Connection | Runtime         | Required for LLM communication |
| braven_chart_plus   | Build           | Must be available at path      |

## Risk Assessment

### Technical Risks

| Risk                            | Likelihood | Impact | Mitigation                                          |
| ------------------------------- | ---------- | ------ | --------------------------------------------------- |
| Anthropic SDK breaking changes  | Low        | Medium | Pin version, adapter pattern isolates changes       |
| ChartRenderer property mismatch | Medium     | High   | Property wiring test validates all mappings         |
| LLM rate limiting               | Medium     | Low    | Demo app includes error handling and retry guidance |
| Context window overflow         | Low        | Medium | V1 defers to LLM error; future: context management  |

### Schedule Risks

| Risk                     | Likelihood | Impact | Mitigation                                          |
| ------------------------ | ---------- | ------ | --------------------------------------------------- |
| ChartRenderer complexity | Medium     | Medium | Direct translation, not rewrite                     |
| Tool schema validation   | Low        | Low    | JSON Schema is well-defined in spec                 |
| Demo app scope creep     | Medium     | Low    | Strict MVP scope: API key input + chat + chart view |

### Dependency Risks

| Risk                          | Likelihood | Impact | Mitigation                               |
| ----------------------------- | ---------- | ------ | ---------------------------------------- |
| braven_chart_plus API changes | Low        | High   | Package is under same repo control       |
| anthropic_sdk_dart issues     | Low        | Medium | Well-maintained package, adapter pattern |

## Implementation Phases

### Phase 1: Foundation (Tasks 1-3)

**Goal**: Establish package structure and core models

- Create package structure at `packages/braven_agent/`
- Implement all model classes with fromJson/toJson/copyWith
- Barrel file with comprehensive documentation

**Exit Criteria**:

- Package compiles with `flutter pub get`
- All models have unit tests for serialization

### Phase 2: LLM Layer (Tasks 4-6)

**Goal**: LLM provider abstraction and Anthropic integration

- LLMProvider interface
- LLMRegistry factory pattern
- AnthropicAdapter implementation
- Message model conversions

**Exit Criteria**:

- AnthropicAdapter can send messages and receive responses
- Provider registration and creation works

### Phase 3: Tool System (Tasks 7-8)

**Goal**: Create chart tools with validated schemas

- AgentTool interface
- CreateChartTool with full JSON Schema
- ModifyChartTool with merge logic

**Exit Criteria**:

- Tools produce valid ChartConfiguration objects
- Tool error handling returns proper ToolResult

### Phase 4: Session Layer (Tasks 9-10)

**Goal**: UI-bindable session state management

- AgentSession interface
- AgentSessionImpl with ValueNotifier state
- Event stream for side effects
- Cancellation support

**Exit Criteria**:

- Session correctly orchestrates LLM → Tool → State flow
- ValueListenableBuilder can render state changes

### Phase 5: Renderer (Task 11)

**Goal**: ChartConfiguration → Widget translation

- Translate ChartRenderer from /agentic
- Property wiring test validation

**Exit Criteria**:

- All chart types render correctly
- Property wiring test passes

### Phase 6: Integration (Tasks 12-13)

**Goal**: End-to-end validation

- Integration tests for create/modify flow
- Demo app implementation
- Final documentation

**Exit Criteria**:

- Demo app shows functional chat → chart creation
- All tests pass

---

## Related Documents

| Document                                                   | Purpose                                                  |
| ---------------------------------------------------------- | -------------------------------------------------------- |
| [spec.md](spec.md)                                         | Feature specification with user stories and requirements |
| [research.md](research.md)                                 | Resolved design decisions and rationale                  |
| [data-model.md](data-model.md)                             | Complete entity definitions                              |
| [contracts/tool-contracts.md](contracts/tool-contracts.md) | Tool JSON schemas and API contracts                      |
| [quickstart.md](quickstart.md)                             | Usage examples and patterns                              |
| [checklists/requirements.md](checklists/requirements.md)   | Spec validation checklist                                |

---

_Plan created by /speckit.plan command. Proceed to /speckit.tasks to generate tasks.md._
