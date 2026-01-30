# Tasks: Agentic Charts

**Input**: Design documents from `/specs/003-agentic-charts/`
**Prerequisites**: plan.md ✅, spec.md ✅, research.md ✅, data-model.md ✅, contracts/ ✅, quickstart.md ✅

**Tests**: Constitution mandates Test-First Development. Tests included per principle I.

**Organization**: Tasks grouped by user story (9 stories total: 3×P1, 4×P2, 2×P3)

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions

- **Models**: `lib/src/agentic/models/`
- **Providers**: `lib/src/agentic/providers/`
- **Tools**: `lib/src/agentic/tools/`
- **Services**: `lib/src/agentic/services/`
- **Widgets**: `lib/src/agentic/widgets/`
- **Tests**: `test/unit/agentic/`, `test/widget/agentic/`, `test/integration/agentic/`
- **Example**: `example/lib/demos/`

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Project initialization, module structure, and dependencies

- [ ] T001 Create agentic module directory structure per plan.md at `lib/src/agentic/`
- [ ] T002 Add dependencies to `pubspec.yaml`: `anthropic_sdk_dart`, `braven_data`, `braven_charts`, `http`, `uuid`, `json_annotation`
- [ ] T003 [P] Create barrel export file at `lib/src/agentic/agentic.dart`
- [ ] T004 [P] Create test directory structure at `test/unit/agentic/`, `test/widget/agentic/`, `test/integration/agentic/`
- [ ] T005 [P] Add `build.yaml` configuration for json_serializable code generation

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core infrastructure that MUST be complete before ANY user story can be implemented

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

### Core Models (All Stories Depend On)

- [ ] T006 [P] Create `Conversation` model in `lib/src/agentic/models/conversation.dart`
- [ ] T007 [P] Create `Message` model (user/assistant/system roles) in `lib/src/agentic/models/message.dart`
- [ ] T008 [P] Create `ToolCall` and `ToolResult` models in `lib/src/agentic/models/tool_result.dart`
- [ ] T009 [P] Create `ChartConfiguration` model with JSON serialization in `lib/src/agentic/models/chart_config.dart`
- [ ] T010 [P] Create `SeriesConfig`, `XAxisConfig`, `YAxisConfig` models in `lib/src/agentic/models/chart_config.dart`
- [ ] T011 [P] Create `LoadedData` and `ColumnDescriptor` models in `lib/src/agentic/models/data_source.dart`
- [ ] T012 [P] Create `FileAttachment` model with status enum in `lib/src/agentic/models/file_attachment.dart`

### LLM Provider Abstraction

- [ ] T013 Create abstract `LLMProvider` interface in `lib/src/agentic/providers/llm_provider.dart`
- [ ] T014 [P] Implement `AnthropicProvider` in `lib/src/agentic/providers/anthropic_provider.dart`
- [ ] T015 [P] Unit tests for `AnthropicProvider` in `test/unit/agentic/providers/anthropic_provider_test.dart`

### Tool Registry Framework

- [ ] T016 Create `LLMTool` abstract class and `ToolRegistry` in `lib/src/agentic/tools/tool_registry.dart`
- [ ] T017 Unit tests for `ToolRegistry` in `test/unit/agentic/tools/tool_registry_test.dart`

### Core Services

- [ ] T018 Create `DataStore` (UUID-based data reference) in `lib/src/agentic/services/data_store.dart`
- [ ] T019 [P] Unit tests for `DataStore` in `test/unit/agentic/services/data_store_test.dart`
- [ ] T020 Create `AgentService` orchestrator skeleton in `lib/src/agentic/services/agent_service.dart`

**Checkpoint**: Foundation ready - user story implementation can now begin

---

## Phase 3: User Story 1 - Natural Language Chart Creation (Priority: P1) 🎯 MVP

**Goal**: Users describe charts in plain language and receive rendered visualizations

**Independent Test**: User types "Show me a line chart of power over time" → chart renders with labeled axes

### Tests for User Story 1

- [ ] T021 [P] [US1] Unit test for `CreateChartTool` in `test/unit/agentic/tools/create_chart_tool_test.dart`
- [ ] T022 [P] [US1] Widget test for `ChatInterface` basic input/output in `test/widget/agentic/chat_interface_test.dart`
- [ ] T023 [P] [US1] Integration test for chat → chart flow in `test/integration/agentic/chat_to_chart_test.dart`

### Implementation for User Story 1

- [ ] T024 [US1] Implement `CreateChartTool` per contract schema in `lib/src/agentic/tools/create_chart_tool.dart`
- [ ] T025 [US1] Implement chart rendering bridge to BravenChartPlus in `lib/src/agentic/services/chart_renderer.dart`
- [ ] T026 [P] [US1] Create `MessageBubble` widget in `lib/src/agentic/widgets/message_bubble.dart`
- [ ] T027 [P] [US1] Create `ChartCard` widget (chart + action bar) in `lib/src/agentic/widgets/chart_card.dart`
- [ ] T028 [US1] Create `ChatInterface` main widget with input field in `lib/src/agentic/widgets/chat_interface.dart`
- [ ] T029 [US1] Wire `AgentService` to handle user messages and execute tools in `lib/src/agentic/services/agent_service.dart` (use ValueNotifier per Constitution II)
- [ ] T030 [US1] Add loading indicators and streaming text display per FR-015, FR-016 in `lib/src/agentic/widgets/chat_interface.dart` (use ValueNotifier per Constitution II)
- [ ] T031 [US1] Add error handling with retry UI per FR-017 in `lib/src/agentic/widgets/error_message.dart`
- [ ] T032 [US1] Create demo app showcasing basic chart creation at `example/lib/demos/agentic_chart_demo.dart`

**Checkpoint**: User Story 1 complete - basic natural language → chart flow works

---

## Phase 4: User Story 2 - Sport Science File Analysis (Priority: P1)

**Goal**: Users upload FIT/CSV files and analyze with rolling averages, distributions

**Independent Test**: Upload FIT file → "Show 30-second rolling average of power" → smoothed chart

### Tests for User Story 2

- [ ] T033 [P] [US2] Unit test for `LoadDataTool` in `test/unit/agentic/tools/load_data_tool_test.dart`
- [ ] T034 [P] [US2] Unit test for `DescribeDataTool` in `test/unit/agentic/tools/describe_data_tool_test.dart`
- [ ] T035 [P] [US2] Unit test for `ProcessDataTool` rolling window in `test/unit/agentic/tools/process_data_tool_test.dart`
- [ ] T036 [P] [US2] Integration test for file upload → chart flow in `test/integration/agentic/file_to_chart_test.dart`

### Implementation for User Story 2

- [ ] T037 [US2] Implement `LoadDataTool` with FIT/CSV parsing via braven_data in `lib/src/agentic/tools/load_data_tool.dart`
- [ ] T038 [US2] Implement `DescribeDataTool` for column discovery per FR-014 in `lib/src/agentic/tools/describe_data_tool.dart`
- [ ] T039 [US2] Implement `ProcessDataTool` with rolling_window and fixed_window operations in `lib/src/agentic/tools/process_data_tool.dart`
- [ ] T040 [P] [US2] Create `FileAttachmentChip` widget for file display in `lib/src/agentic/widgets/file_attachment_chip.dart`
- [ ] T041 [P] [US2] Create `DataPreview` widget showing columns/stats per FR-022 in `lib/src/agentic/widgets/data_preview.dart`
- [ ] T042 [US2] Add file upload handling to `ChatInterface` in `lib/src/agentic/widgets/chat_interface.dart`
- [ ] T043 [US2] Add file validation (size limits, allowed formats) per FR-018, FR-019 in `lib/src/agentic/services/file_validator.dart`
- [ ] T043a [US2] Add timezone detection and handling per FR-026 in `lib/src/agentic/tools/load_data_tool.dart`
- [ ] T044 [US2] Update demo to show file upload workflow at `example/lib/demos/agentic_chart_demo.dart`

**Checkpoint**: User Story 2 complete - FIT file analysis with rolling averages works

---

## Phase 5: User Story 3 - Complete Chart Property Control (Priority: P1)

**Goal**: Full control over all chart properties via natural language (colors, axes, annotations)

**Independent Test**: "Make the line red, dashed, add reference line at 250W" → all applied

### Tests for User Story 3

- [ ] T045 [P] [US3] Unit test for `ModifyChartTool` in `test/unit/agentic/tools/modify_chart_tool_test.dart`
- [ ] T046 [P] [US3] Unit test for `AddAnnotationTool` in `test/unit/agentic/tools/add_annotation_tool_test.dart`
- [ ] T047 [P] [US3] Integration test for in-place chart modification in `test/integration/agentic/modify_chart_test.dart`

### Implementation for User Story 3

- [ ] T048 [US3] Create `AnnotationConfig` model in `lib/src/agentic/models/annotation_config.dart`
- [ ] T048a [US3] Add multi-axis support (up to 4 Y-axes) per FR-009 in `lib/src/agentic/models/chart_config.dart`
- [ ] T049 [US3] Implement `ModifyChartTool` for in-place updates per FR-005 in `lib/src/agentic/tools/modify_chart_tool.dart`
- [ ] T050 [US3] Implement `AddAnnotationTool` for reference lines, zones, labels in `lib/src/agentic/tools/add_annotation_tool.dart`
- [ ] T051 [US3] Add chart state tracking to `AgentService` (current config context) in `lib/src/agentic/services/agent_service.dart`
- [ ] T052 [US3] Create `ChartHistory` service for undo/redo (20 steps) per FR-020 in `lib/src/agentic/services/chart_history.dart`
- [ ] T053 [P] [US3] Unit tests for `ChartHistory` in `test/unit/agentic/services/chart_history_test.dart`
- [ ] T054 [US3] Update `ChartCard` with Edit button linking to inline context in `lib/src/agentic/widgets/chart_card.dart`

**Checkpoint**: User Story 3 complete - full property control and in-place editing works

---

## Phase 6: User Story 4 - Quick Configuration Adjustments (Priority: P2)

**Goal**: Visual config panel for quick tweaks without re-prompting AI

**Independent Test**: Click Settings on chart → toggle dark mode → chart updates instantly

### Tests for User Story 4

- [ ] T055 [P] [US4] Widget test for `ConfigPanel` in `test/widget/agentic/config_panel_test.dart`

### Implementation for User Story 4

- [ ] T056 [US4] Create `ConfigPanel` widget with theme/grid/legend toggles per FR-006 in `lib/src/agentic/widgets/config_panel.dart` (use ValueNotifier per Constitution II)
- [ ] T057 [US4] Add panel toggle to `ChartCard` action bar in `lib/src/agentic/widgets/chart_card.dart`
- [ ] T058 [US4] Sync panel state with chart configuration for agent awareness in `lib/src/agentic/services/agent_service.dart`
- [ ] T059 [US4] Ensure <100ms panel update latency per SC-012 via ValueNotifier in `lib/src/agentic/widgets/config_panel.dart`

**Checkpoint**: User Story 4 complete - config panel provides instant visual tweaks

---

## Phase 7: User Story 5 - Multiple Data Sources (Priority: P2)

**Goal**: Support file uploads, inline data, URLs, and context files

**Independent Test**: Paste "[1,2,3,4,5]" in chat → "Chart this data" → chart renders

### Tests for User Story 5

- [ ] T060 [P] [US5] Unit test for inline data parsing in `test/unit/agentic/tools/load_data_tool_test.dart`
- [ ] T061 [P] [US5] Unit test for URL fetching in `test/unit/agentic/services/url_fetcher_test.dart`

### Implementation for User Story 5

- [ ] T062 [US5] Add inline data parsing to `LoadDataTool` per FR-007 in `lib/src/agentic/tools/load_data_tool.dart` (depends on T037)
- [ ] T063 [US5] Add URL fetching capability to `LoadDataTool` in `lib/src/agentic/tools/load_data_tool.dart` (depends on T037)
- [ ] T064 [US5] Create context file loader for athlete defaults in `lib/src/agentic/services/context_loader.dart`
- [ ] T065 [US5] Add automatic downsampling for >100k data points in `lib/src/agentic/services/data_optimizer.dart`

**Checkpoint**: User Story 5 complete - multiple data sources work

---

## Phase 8: User Story 6 - Sport Science Calculations (Priority: P2)

**Goal**: Calculate NP, TSS, IF, time-in-zones from workout data

**Independent Test**: "Calculate Normalized Power for this ride" → displays NP value

### Tests for User Story 6

- [ ] T066 [P] [US6] Unit test for NP calculation (within 1% per SC-006) in `test/unit/agentic/tools/calculate_metric_tool_test.dart`
- [ ] T067 [P] [US6] Unit test for TSS, IF calculations in `test/unit/agentic/tools/calculate_metric_tool_test.dart`
- [ ] T068 [P] [US6] Widget test for `MetricCard` display in `test/widget/agentic/metric_card_test.dart`

### Implementation for User Story 6

- [ ] T069 [US6] Create `Metric` model in `lib/src/agentic/models/metric.dart`
- [ ] T070 [US6] Implement `CalculateMetricTool` with NP, TSS, IF, mean, max, min per FR-008 in `lib/src/agentic/tools/calculate_metric_tool.dart`
- [ ] T071 [P] [US6] Create `MetricCard` widget for displaying computed values per FR-023 in `lib/src/agentic/widgets/metric_card.dart`
- [ ] T072 [US6] Add zone overlay support to annotation tool in `lib/src/agentic/tools/add_annotation_tool.dart` (extends T050)

**Checkpoint**: User Story 6 complete - sport science metrics calculated and displayed

---

## Phase 9: User Story 9 - Inline Chart Editing (Priority: P2)

**Goal**: Per-chart inline chat for targeted modifications when multiple charts exist

**Independent Test**: Click chat icon on chart → "Make this line red" → only that chart updates

### Tests for User Story 9

- [ ] T073 [P] [US9] Widget test for `InlineChat` in `test/widget/agentic/inline_chat_test.dart`
- [ ] T074 [P] [US9] Integration test for scoped chart editing in `test/integration/agentic/inline_edit_test.dart`

### Implementation for User Story 9

- [ ] T075 [US9] Create `InlineChat` widget linked to specific chartId per FR-013 in `lib/src/agentic/widgets/inline_chat.dart`
- [ ] T076 [US9] Add inline chat toggle button to `ChartCard` in `lib/src/agentic/widgets/chart_card.dart`
- [ ] T077 [US9] Preserve inline chat history when chart collapsed/expanded per spec in `lib/src/agentic/services/agent_service.dart`
- [ ] T078 [US9] Add "Add to Context" button for cross-chart operations in `lib/src/agentic/widgets/chart_card.dart`

**Checkpoint**: User Story 9 complete - inline per-chart editing works

---

## Phase 10: User Story 7 - Workout Comparison (Priority: P3)

**Goal**: Compare up to 5 workouts with overlay and metrics table

**Independent Test**: Upload 2 FIT files → "Compare these rides" → overlaid chart + metrics table

### Tests for User Story 7

- [ ] T079 [P] [US7] Integration test for multi-workout comparison in `test/integration/agentic/workout_comparison_test.dart`

### Implementation for User Story 7

- [ ] T080 [US7] Add multi-file handling to data store (up to 5 per FR-010) in `lib/src/agentic/services/data_store.dart`
- [ ] T081 [US7] Implement comparison overlay logic in `CreateChartTool` in `lib/src/agentic/tools/create_chart_tool.dart`
- [ ] T082 [P] [US7] Create comparison metrics table widget in `lib/src/agentic/widgets/comparison_table.dart`
- [ ] T083 [US7] Add distinct colors/styles for overlaid workouts in `lib/src/agentic/services/chart_renderer.dart`

**Checkpoint**: User Story 7 complete - workout comparison with metrics table works

---

## Phase 11: User Story 8 - Chart Export & Favorites (Priority: P3)

**Goal**: Export charts as images, save to favorites, export favorites as config

**Independent Test**: Click Export on chart → PNG downloads; Click Favorite → chart saved to gallery

### Tests for User Story 8

- [ ] T084 [P] [US8] Unit test for PNG export (verify 300 DPI per SC-009) in `test/unit/agentic/tools/export_chart_tool_test.dart`
- [ ] T085 [P] [US8] Unit test for favorites service in `test/unit/agentic/services/favorites_service_test.dart`

### Implementation for User Story 8

- [ ] T086 [US8] Implement `ExportChartTool` for PNG/SVG/JSON export per FR-011 in `lib/src/agentic/tools/export_chart_tool.dart`
- [ ] T087 [US8] Create `FavoritesService` for session-local favorites per FR-012 in `lib/src/agentic/services/favorites_service.dart`
- [ ] T088 [P] [US8] Create favorites gallery widget in `lib/src/agentic/widgets/favorites_gallery.dart`
- [ ] T089 [US8] Add Export/Favorite buttons to `ChartCard` action bar in `lib/src/agentic/widgets/chart_card.dart`
- [ ] T090 [US8] Add "Export All" for favorites as JSON config in `lib/src/agentic/services/favorites_service.dart`

**Checkpoint**: User Story 8 complete - export and favorites fully functional

---

## Phase 12: Polish & Cross-Cutting Concerns

**Purpose**: Welcome screen, keyboard shortcuts, additional providers, final polish

- [ ] T091 [P] Create welcome screen with example prompts + sample chart per FR-027 in `lib/src/agentic/widgets/welcome_screen.dart`
- [ ] T092 [P] Create read-only prompt templates per FR-021 in `lib/src/agentic/models/prompt_template.dart`
- [ ] T093 [P] Add prompt template dropdown to `ChatInterface` in `lib/src/agentic/widgets/chat_interface.dart`
- [ ] T094 [P] Implement keyboard shortcuts per FR-025 (Ctrl+Enter, Ctrl+U, Ctrl+Z) in `lib/src/agentic/widgets/chat_interface.dart`
- [ ] T095 [P] Add token usage tracking and 80% warning per FR-024 in `lib/src/agentic/services/agent_service.dart`
- [ ] T096 [P] Implement `OpenAIProvider` in `lib/src/agentic/providers/openai_provider.dart`
- [ ] T097 [P] Implement `GeminiProvider` in `lib/src/agentic/providers/gemini_provider.dart`
- [ ] T098 [P] Add golden tests for chat interface UI in `test/golden/agentic/chat_interface_golden_test.dart`
- [ ] T099 Run quickstart.md validation - verify all examples work
- [ ] T100 Update `lib/braven_charts.dart` to export agentic module

### Performance Validation (Success Criteria)

- [ ] T101 [P] Integration test for end-to-end <30s first chart per SC-001 in `test/integration/agentic/performance_e2e_test.dart`
- [ ] T102 [P] Stress test for 50MB file handling per SC-007 in `test/integration/agentic/large_file_stress_test.dart`

---

## Dependencies & Execution Order

### Phase Dependencies

```
Phase 1 (Setup) ──────────────────────────────────────────────────────┐
                                                                       ▼
Phase 2 (Foundational) ◄── BLOCKS ALL USER STORIES ──────────────────┤
                                                                       │
    ┌──────────────────────────────────────────────────────────────────┤
    │                                                                   │
    ▼                           ▼                           ▼          │
Phase 3 (US1-P1)          Phase 4 (US2-P1)          Phase 5 (US3-P1)  │
    │                           │                           │          │
    └───────────────────────────┴───────────────────────────┘          │
                                │                                       │
    ┌───────────────────────────┴───────────────────────────┐          │
    ▼                   ▼                   ▼               ▼          │
Phase 6 (US4-P2)  Phase 7 (US5-P2)  Phase 8 (US6-P2)  Phase 9 (US9-P2)│
    │                   │                   │               │          │
    └───────────────────┴───────────────────┴───────────────┘          │
                                │                                       │
    ┌───────────────────────────┴───────────────────────────┐          │
    ▼                                                       ▼          │
Phase 10 (US7-P3)                                   Phase 11 (US8-P3) │
    │                                                       │          │
    └───────────────────────────┬───────────────────────────┘          │
                                ▼                                       │
                       Phase 12 (Polish) ◄─────────────────────────────┘
```

### User Story Dependencies

| User Story                   | Priority | Dependencies              | Can Run After       |
| ---------------------------- | -------- | ------------------------- | ------------------- |
| US1 - Natural Language Chart | P1       | Phase 2 only              | Phase 2 complete    |
| US2 - File Analysis          | P1       | Phase 2 only              | Phase 2 complete    |
| US3 - Property Control       | P1       | Phase 2 only              | Phase 2 complete    |
| US4 - Config Panel           | P2       | US1 (ChartCard)           | Phase 3 complete    |
| US5 - Multiple Sources       | P2       | US2 (LoadDataTool)        | Phase 4 complete    |
| US6 - Calculations           | P2       | US2 (data loading)        | Phase 4 complete    |
| US9 - Inline Editing         | P2       | US1, US3 (charts, modify) | Phase 3, 5 complete |
| US7 - Comparison             | P3       | US2, US6 (file + metrics) | Phase 4, 8 complete |
| US8 - Export & Favorites     | P3       | US1 (charts exist)        | Phase 3 complete    |

### Parallel Opportunities Per Phase

**Phase 2 (Foundational)**:

- T006-T012 (all models) can run in parallel
- T014-T015 (provider + tests) can run in parallel
- T018-T019 (data store + tests) can run in parallel

**Phase 3 (US1)**:

- T021-T023 (all tests) can run in parallel
- T026-T027 (widgets) can run in parallel

**Phase 4 (US2)**:

- T033-T036 (all tests) can run in parallel
- T040-T041 (widgets) can run in parallel

**Phase 12 (Polish)**:

- T091-T098 (all tasks) can run in parallel

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup (~5 tasks)
2. Complete Phase 2: Foundational (~15 tasks)
3. Complete Phase 3: User Story 1 (~12 tasks)
4. **STOP and VALIDATE**: Test basic chat → chart flow
5. Deploy/demo if ready - MVP achieved!

**MVP Task Count**: 32 tasks

### Incremental Delivery

| Increment      | User Stories | Cumulative Tasks | Value Delivered                          |
| -------------- | ------------ | ---------------- | ---------------------------------------- |
| MVP            | US1          | 32               | Basic natural language charts            |
| +File Analysis | US1+US2      | 45               | FIT file support, rolling averages       |
| +Full Control  | US1+US2+US3  | 56               | Complete property control, annotations   |
| +Quick Tweak   | +US4         | 61               | Config panel for instant changes         |
| +Data Sources  | +US5         | 67               | Inline data, URLs, context files         |
| +Metrics       | +US6         | 74               | NP, TSS, IF calculations                 |
| +Inline Edit   | +US9         | 80               | Per-chart editing                        |
| +Comparison    | +US7         | 85               | Multi-workout overlay                    |
| +Export        | +US8         | 92               | PNG export, favorites                    |
| Complete       | +Polish      | 104              | Welcome screen, templates, all providers |

### Parallel Team Strategy

With 3 developers after Phase 2:

- **Dev A**: US1 → US4 → US9 (chart creation path)
- **Dev B**: US2 → US5 → US7 (data loading path)
- **Dev C**: US3 → US6 → US8 (modification/metrics path)

---

## Summary

| Metric                     | Value                |
| -------------------------- | -------------------- |
| **Total Tasks**            | 104                  |
| **Phase 1 (Setup)**        | 5                    |
| **Phase 2 (Foundational)** | 15                   |
| **US1 Tasks**              | 12                   |
| **US2 Tasks**              | 13 (+T043a)          |
| **US3 Tasks**              | 11 (+T048a)          |
| **US4 Tasks**              | 5                    |
| **US5 Tasks**              | 6                    |
| **US6 Tasks**              | 7                    |
| **US9 Tasks**              | 6                    |
| **US7 Tasks**              | 5                    |
| **US8 Tasks**              | 7                    |
| **Phase 12 (Polish)**      | 12 (+T101, T102)     |
| **MVP Scope**              | 32 tasks (US1 only)  |
| **Parallel Opportunities** | 47+ tasks marked [P] |

---

## Notes

- [P] tasks = different files, no dependencies
- [Story] label maps task to specific user story for traceability
- Each user story is independently completable and testable
- Constitution mandates tests written first (Red-Green-Refactor)
- Commit after each task or logical group
- Stop at any checkpoint to validate story independently
- ValueNotifier pattern required for all high-frequency state updates (per constitution)
