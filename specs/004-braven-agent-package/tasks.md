# Tasks: Braven Agent Package

**Input**: Design documents from `/specs/004-braven-agent-package/`  
**Prerequisites**: plan.md ✅, spec.md ✅, research.md ✅, data-model.md ✅, contracts/ ✅

**Tests**: Unit tests are included per Constitution Test-First Development principle. Property wiring test is translated from /agentic per 004.1 spec.

**Organization**: Tasks grouped by user story priority (P1 → P2 → P3) to enable MVP-first delivery.

## Format: `[ID] [P?] [Story?] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Maps to user story (US1-US8) from spec.md
- Include exact file paths in descriptions

## Path Conventions

- **Package root**: `packages/braven_agent/`
- **Source**: `packages/braven_agent/lib/src/`
- **Tests**: `packages/braven_agent/test/`
- **Demo**: `example/lib/demos/`

---

## Phase 1: Setup (Project Initialization)

**Purpose**: Create package structure and establish dependencies

- [ ] T001 Create package directory structure at `packages/braven_agent/`
- [ ] T002 Create `packages/braven_agent/pubspec.yaml` with dependencies per plan.md
- [ ] T003 [P] Create `packages/braven_agent/analysis_options.yaml` with linting rules
- [ ] T004 Create barrel file `packages/braven_agent/lib/braven_agent.dart` with comprehensive doc comments

**Checkpoint**: `flutter pub get` succeeds in packages/braven_agent/

---

## Phase 2: Foundational (Core Models - All Stories Depend On)

**Purpose**: Core models and enums that ALL user stories require. MUST complete before any user story.

**⚠️ CRITICAL**: No user story work can begin until this phase is complete.

### Model Classes

- [ ] T005 [P] Create DataPoint model in `packages/braven_agent/lib/src/models/data_point.dart`
- [ ] T006 [P] Create enums (ChartType, MarkerStyle, Interpolation, AxisType, AxisPosition, etc.) in `packages/braven_agent/lib/src/models/enums.dart`
- [ ] T007 [P] Create SeriesConfig model in `packages/braven_agent/lib/src/models/series_config.dart`
- [ ] T008 [P] Create XAxisConfig model in `packages/braven_agent/lib/src/models/x_axis_config.dart`
- [ ] T009 [P] Create YAxisConfig model in `packages/braven_agent/lib/src/models/y_axis_config.dart`
- [ ] T010 [P] Create AnnotationConfig model in `packages/braven_agent/lib/src/models/annotation_config.dart`
- [ ] T011 [P] Create ChartStyleConfig model in `packages/braven_agent/lib/src/models/chart_style_config.dart`
- [ ] T012 Create ChartConfiguration model in `packages/braven_agent/lib/src/models/chart_configuration.dart` (depends on T005-T011)
- [ ] T013 [P] Create models barrel file `packages/braven_agent/lib/src/models/models.dart`

### Model Tests

- [ ] T014 [P] Create serialization tests for models in `packages/braven_agent/test/models/serialization_test.dart`

### LLM Foundation Classes

- [ ] T015 [P] Create MessageContent sealed hierarchy in `packages/braven_agent/lib/src/llm/models/message_content.dart`
- [ ] T016 [P] Create AgentMessage model in `packages/braven_agent/lib/src/llm/models/agent_message.dart`
- [ ] T017 [P] Create LLMConfig model in `packages/braven_agent/lib/src/llm/llm_config.dart`
- [ ] T018 [P] Create LLMResponse and LLMChunk models in `packages/braven_agent/lib/src/llm/llm_response.dart`

### Session Foundation Classes

- [ ] T019 [P] Create SessionState model in `packages/braven_agent/lib/src/session/session_state.dart`
- [ ] T020 [P] Create AgentEvent sealed hierarchy (ChartCreatedEvent, ChartUpdatedEvent, ToolStartEvent, ToolEndEvent, ErrorEvent, CancelledEvent, ProcessingStartedEvent, ProcessingCompletedEvent) in `packages/braven_agent/lib/src/session/agent_events.dart`

### Tool Foundation Classes

- [ ] T021 [P] Create ToolResult model in `packages/braven_agent/lib/src/tools/tool_result.dart`
- [ ] T022 Create AgentTool interface in `packages/braven_agent/lib/src/tools/agent_tool.dart`

### Update Barrel File

- [ ] T023 Update barrel file exports in `packages/braven_agent/lib/braven_agent.dart` with all foundational exports

**Checkpoint**: All models compile, serialization tests pass. Foundation ready for user stories.

---

## Phase 3: User Story 1 - Create Charts via Natural Language (Priority: P1) 🎯 MVP

**Goal**: Enable developers to create charts through natural language conversations with LLM.

**Independent Test**: Start session → send "Create a line chart" → verify ChartConfiguration returned with series data.

### LLM Provider Implementation (US1 Dependency)

- [ ] T024 [US1] Create LLMProvider interface in `packages/braven_agent/lib/src/llm/llm_provider.dart`
- [ ] T025 [US1] Create LLMRegistry factory in `packages/braven_agent/lib/src/llm/llm_registry.dart`
- [ ] T026 [US1] Create AnthropicAdapter in `packages/braven_agent/lib/src/llm/providers/anthropic_adapter.dart`
- [ ] T027 [P] [US1] Create LLM layer barrel file `packages/braven_agent/lib/src/llm/llm.dart`

### CreateChartTool Implementation

- [ ] T028 [US1] Create CreateChartTool in `packages/braven_agent/lib/src/tools/create_chart_tool.dart` with JSON Schema from contracts/
- [ ] T029 [P] [US1] Create CreateChartTool tests in `packages/braven_agent/test/tools/create_chart_tool_test.dart`

### Session Implementation

- [ ] T030 [US1] Create default system prompt in `packages/braven_agent/lib/src/session/default_system_prompt.dart`
- [ ] T031 [US1] Create AgentSession interface in `packages/braven_agent/lib/src/session/agent_session.dart`
- [ ] T032 [US1] Create AgentSessionImpl with ValueNotifier state in `packages/braven_agent/lib/src/session/agent_session_impl.dart`
- [ ] T033 [P] [US1] Create session layer barrel file `packages/braven_agent/lib/src/session/session.dart`
- [ ] T034 [US1] Create AgentSession tests in `packages/braven_agent/test/session/agent_session_test.dart`

### Integration

- [ ] T035 [US1] Update barrel file with all US1 exports in `packages/braven_agent/lib/braven_agent.dart`

**Checkpoint**: AgentSession can create charts via LLM. US1 is independently testable.

---

## Phase 4: User Story 2 - Modify Charts via Conversation (Priority: P1)

**Goal**: Enable users to modify existing charts through follow-up conversation.

**Independent Test**: Create chart → send "Make the line red" → verify color property changed, chart ID preserved.

### ModifyChartTool Implementation

- [ ] T036 [US2] Create ModifyChartTool in `packages/braven_agent/lib/src/tools/modify_chart_tool.dart` with merge logic
- [ ] T037 [P] [US2] Create ModifyChartTool tests in `packages/braven_agent/test/tools/modify_chart_tool_test.dart`
- [ ] T038 [P] [US2] Create tools layer barrel file `packages/braven_agent/lib/src/tools/tools.dart`

### Session Update for Modify

- [ ] T039 [US2] Add modify_chart tool to default tool set in AgentSessionImpl
- [ ] T040 [US2] Create chart modification integration test in `packages/braven_agent/test/integration/chart_modification_test.dart`

**Checkpoint**: Modify chart flow works end-to-end. US2 is independently testable.

---

## Phase 5: User Story 3 - Demo App Chat Flow (Priority: P1)

**Goal**: Demo app validates package works and demonstrates integration patterns.

**Independent Test**: Run demo → type "Create a line chart with 3 series" → see chart rendered with 3 series.

### ChartRenderer (Translated from /agentic)

- [ ] T041 [US3] Translate ChartRenderer from `lib/src/agentic/services/chart_renderer.dart` (or implement from data-model.md Section 8 if source unavailable) to `packages/braven_agent/lib/src/renderer/chart_renderer.dart`
- [ ] T042 [US3] Translate property wiring test to `packages/braven_agent/test/renderer/property_wiring_test.dart`
- [ ] T043 [P] [US3] Create renderer layer barrel file `packages/braven_agent/lib/src/renderer/renderer.dart`

### Demo Application

- [ ] T044 [US3] Create demo app entry point in `example/lib/demos/braven_agent_demo.dart`
- [ ] T045 [US3] Create API key input screen in demo app
- [ ] T046 [US3] Create chat screen with message history display
- [ ] T047 [US3] Create chart display area using ChartRenderer
- [ ] T048 [US3] Add processing state indicators (thinking, tool execution)

### Final US3 Integration

- [ ] T049 [US3] Update barrel file with renderer exports in `packages/braven_agent/lib/braven_agent.dart`
- [ ] T050 [US3] Add demo app to example/README.md documentation

**Checkpoint**: Demo app runs, shows chat UI, creates and renders charts. All P1 stories complete.

---

## Phase 6: User Story 4 - Real-Time Session State (Priority: P2)

**Goal**: Developers can observe session state transitions for responsive UI.

**Independent Test**: Listen to state changes → verify transitions idle → processing → idle during chart creation.

### State Observation Enhancements

- [ ] T051 [US4] Add detailed status enum (idle, thinking, callingTool) to SessionState
- [ ] T052 [US4] Add activeTool property to SessionState for tool-in-progress info
- [ ] T053 [US4] Create state transition tests in `packages/braven_agent/test/session/state_transitions_test.dart`

**Checkpoint**: State transitions are accurate and observable. US4 is independently testable.

---

## Phase 7: User Story 5 - Agent Events (Priority: P2)

**Goal**: Developers can subscribe to typed events for side effects (persistence, navigation, toasts).

**Independent Test**: Subscribe to events stream → verify ChartCreatedEvent, ToolStartEvent emitted during flow.

### Event Stream Implementation

- [ ] T054 [US5] Ensure AgentSessionImpl emits all event types per events hierarchy
- [ ] T055 [US5] Add ToolStartEvent and ToolEndEvent emissions in tool execution loop
- [ ] T056 [P] [US5] Create event stream tests in `packages/braven_agent/test/session/event_stream_test.dart`

**Checkpoint**: All events emit correctly with proper data. US5 is independently testable.

---

## Phase 8: User Story 6 - LLM Provider Configuration (Priority: P2)

**Goal**: Developers can configure LLM provider with API key, model selection, and parameters.

**Independent Test**: Create Anthropic provider with config → verify session generates responses with configured model.

### Provider Configuration

- [ ] T057 [US6] Add model selection and temperature to LLMConfig validation
- [ ] T058 [US6] Add provider options passthrough in AnthropicAdapter
- [ ] T059 [P] [US6] Create provider configuration tests in `packages/braven_agent/test/llm/provider_config_test.dart`
- [ ] T060 [US6] Handle invalid API key error surfacing through events/state

**Checkpoint**: Provider configuration works correctly. US6 is independently testable.

---

## Phase 9: User Story 7 - Sync User Edits (Priority: P3)

**Goal**: Developers can sync external chart edits back to session so agent is aware of changes.

**Independent Test**: Create chart → call updateChart() with modified config → verify next prompt includes updated chart.

### UpdateChart Implementation

- [ ] T061 [US7] Implement updateChart() method in AgentSessionImpl
- [ ] T062 [US7] Emit ChartUpdatedEvent when updateChart() called
- [ ] T063 [P] [US7] Create updateChart tests in `packages/braven_agent/test/session/update_chart_test.dart`

**Checkpoint**: User edits sync to session. US7 is independently testable.

---

## Phase 10: User Story 8 - Conversation History Display (Priority: P3)

**Goal**: Demo app displays full conversation history in chronological order.

**Independent Test**: Send multiple messages → verify all appear in correct order with appropriate styling.

### History Display Enhancement

- [ ] T064 [US8] Enhance demo chat screen with styled message bubbles
- [ ] T065 [US8] Add assistant response styling and chart creation indicators
- [ ] T066 [US8] Add scroll-to-bottom on new messages

**Checkpoint**: Conversation history displays correctly. US8 is independently testable.

---

## Phase 11: Polish & Cross-Cutting Concerns

**Purpose**: Final cleanup and documentation

- [ ] T067 [P] Add comprehensive dartdoc to all public APIs
- [ ] T068 [P] Create package README at `packages/braven_agent/README.md`
- [ ] T069 Run `flutter analyze packages/braven_agent` and fix all issues
- [ ] T070 Run all tests and ensure 100% pass rate
- [ ] T071 Validate quickstart.md examples work as documented
- [ ] T072 Update barrel file with final organized exports

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1 (Setup)**: No dependencies - start immediately
- **Phase 2 (Foundational)**: Depends on Phase 1 - BLOCKS all user stories
- **Phases 3-10 (User Stories)**: All depend on Phase 2 completion
- **Phase 11 (Polish)**: Depends on all desired user stories being complete

### User Story Dependencies

| Story | Priority | Can Start After | Dependencies on Other Stories |
| ----- | -------- | --------------- | ----------------------------- |
| US1   | P1       | Phase 2         | None                          |
| US2   | P1       | Phase 2         | Shares session with US1       |
| US3   | P1       | US1, US2        | Uses ChartRenderer to display |
| US4   | P2       | Phase 2         | Enhances session state        |
| US5   | P2       | Phase 2         | Enhances session events       |
| US6   | P2       | Phase 2         | Enhances provider config      |
| US7   | P3       | US1             | Requires chart to update      |
| US8   | P3       | US3             | Enhances demo app UI          |

### Within Each User Story

1. Interface/abstract classes first
2. Implementation classes second
3. Tests can run parallel with implementation (TDD)
4. Integration last

### Parallel Opportunities

**Phase 1 (Setup):**

- T003 can run parallel with T001, T002

**Phase 2 (Foundational) - Maximum Parallelism:**

- T005-T011 (all model files) can run in parallel
- T014-T022 (tests and LLM/session foundation) can run in parallel

**Phase 3-10 (User Stories):**

- Tests marked [P] can run parallel with implementation
- Different user stories (P2, P3) can run parallel after P1 MVP

---

## Parallel Example: Foundational Models

```bash
# Launch all model files together (Phase 2):
T005: "Create DataPoint model in packages/braven_agent/lib/src/models/data_point.dart"
T006: "Create enums in packages/braven_agent/lib/src/models/enums.dart"
T007: "Create SeriesConfig model in packages/braven_agent/lib/src/models/series_config.dart"
T008: "Create XAxisConfig model in packages/braven_agent/lib/src/models/x_axis_config.dart"
T009: "Create YAxisConfig model in packages/braven_agent/lib/src/models/y_axis_config.dart"
T010: "Create AnnotationConfig model in packages/braven_agent/lib/src/models/annotation_config.dart"
T011: "Create ChartStyleConfig model in packages/braven_agent/lib/src/models/chart_style_config.dart"
```

---

## Implementation Strategy

### MVP First (P1 Stories Only) - Recommended

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational (CRITICAL - blocks all stories)
3. Complete Phase 3: User Story 1 (Create Charts)
4. Complete Phase 4: User Story 2 (Modify Charts)
5. Complete Phase 5: User Story 3 (Demo App)
6. **STOP and VALIDATE**: Test all P1 stories
7. Deploy/demo if ready - **MVP ACHIEVED**

### Incremental Delivery

1. MVP (Phases 1-5) → P1 stories complete → Functional demo
2. Add US4-US6 (P2) → Enhanced observability → Better DX
3. Add US7-US8 (P3) → Polish features → Complete package

### Suggested MVP Scope

**MVP = Phases 1-5 (Tasks T001-T050)**

- Setup + Foundation + All P1 Stories
- Delivers: Create charts, modify charts, working demo app
- Test: Run demo, create chart, modify it

---

## Notes

- [P] tasks = different files, no dependencies on incomplete tasks in same phase
- [US#] label maps task to user story for traceability
- ChartRenderer is TRANSLATED from /agentic (exception to clean implementation)
- Property wiring test is TRANSLATED from /agentic (validates renderer)
- All models need fromJson/toJson/copyWith per v5.1 spec
- Use ValueNotifier for state (NOT streams) per constitution
- Demo app is minimal - validates package, not production UX
