# Tasks: Agentic Schema V2

**Input**: Design documents from `/specs/005-agentic-schema-v2/`  
**Prerequisites**: plan.md ✅, spec.md ✅, research.md ✅, data-model.md ✅, contracts/ ✅

**Tests**: Included - TDD is mandatory per constitution (Test-First Development is NON-NEGOTIABLE).

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions

- **Core library**: `lib/src/` at repository root
- **Agent package**: `packages/braven_agent/lib/src/`
- **Core tests**: `test/` at repository root
- **Agent tests**: `packages/braven_agent/test/`

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Project initialization and verification of existing structure

- [ ] T001 Verify branch is `005-agentic-schema-v2` and create if needed
- [ ] T002 Run `flutter analyze` on both `lib/` and `packages/braven_agent/` to establish baseline
- [ ] T003 [P] Create validation module directory at `packages/braven_agent/lib/src/validation/`
- [ ] T004 [P] Create validation test directory at `packages/braven_agent/test/validation/`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core model updates that ALL user stories depend on

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

### Tests for Foundation

- [ ] T005 [P] Write failing test for annotation `id` field in `test/unit/models/annotation_config_test.dart`
- [ ] T006 [P] Write failing test for nested `yAxis` in SeriesConfig in `test/unit/models/series_config_test.dart`
- [ ] T007 [P] Write failing test for removed `yAxes[]` array in `test/unit/models/chart_configuration_test.dart`
- [ ] T008 [P] Write failing test for annotation `id` field in `packages/braven_agent/test/models/annotation_config_test.dart`
- [ ] T009 [P] Write failing test for nested `yAxis` in SeriesConfig in `packages/braven_agent/test/models/series_config_test.dart`

### Implementation for Foundation

- [ ] T010 [P] Add `id` field to `AnnotationConfig` in `lib/src/models/chart_annotation.dart`
- [ ] T011 [P] Add nested `yAxis` field to `ChartSeries` in `lib/src/models/chart_series.dart`
- [ ] T012 [P] Add `id` field to `AnnotationConfig` in `packages/braven_agent/lib/src/models/annotation_config.dart`
- [ ] T013 [P] Add nested `yAxis` field to `SeriesConfig` in `packages/braven_agent/lib/src/models/series_config.dart`
- [ ] T014 [P] Remove flat y-axis fields from `SeriesConfig` in `packages/braven_agent/lib/src/models/series_config.dart`
- [ ] T015 [P] Verify `position` field exists on `YAxisConfig` in `packages/braven_agent/lib/src/models/y_axis_config.dart`
- [ ] T016 Remove `yAxes[]` array from `ChartConfiguration` in `packages/braven_agent/lib/src/models/chart_configuration.dart`
- [ ] T017 Update `copyWith()`, `toJson()`, `fromJson()`, `==`, `hashCode` for all modified models
- [ ] T018 Run `flutter analyze` on all modified model files - must show zero warnings
- [ ] T019 Run all foundational tests - all must now PASS

**Checkpoint**: Foundation ready - user story implementation can now begin

---

## Phase 3: User Story 1 - LLM Creates Multi-Series Chart with Per-Series Y-Axes (Priority: P1) 🎯 MVP

**Goal**: LLM agent can create charts with nested y-axis configuration per series

**Independent Test**: Call `create_chart` with multi-series configuration, verify both series render with correct, independent y-axes

### Tests for User Story 1

- [ ] T020 [P] [US1] Write failing contract test for `create_chart` v2 schema in `packages/braven_agent/test/tools/create_chart_tool_test.dart`
- [ ] T021 [P] [US1] Write failing test for annotation ID generation in `packages/braven_agent/test/tools/create_chart_tool_test.dart`
- [ ] T022 [P] [US1] Write failing test for V001 warning (perSeries + chart yAxis) in `packages/braven_agent/test/validation/schema_validator_test.dart`
- [ ] T023 [P] [US1] Write failing test for V002 warning (perSeries + missing series yAxis) in `packages/braven_agent/test/validation/schema_validator_test.dart`
- [ ] T024 [P] [US1] Write failing test for V003 error (duplicate series id) in `packages/braven_agent/test/validation/schema_validator_test.dart`
- [ ] T025 [P] [US1] Write failing test for V004 error (duplicate annotation id) in `packages/braven_agent/test/validation/schema_validator_test.dart`

### Implementation for User Story 1

- [ ] T026 [US1] Create validation framework skeleton in `packages/braven_agent/lib/src/validation/schema_validator.dart`
- [ ] T027 [US1] Implement V001-V004 validation rules in `packages/braven_agent/lib/src/validation/schema_validator.dart`
- [ ] T028 [US1] Update `create_chart_tool.dart` to remove `{ "chart": ... }` wrapper - input IS ChartConfiguration
- [ ] T029 [US1] Update `create_chart_tool.dart` input schema to use nested `series[].yAxis` in `packages/braven_agent/lib/src/tools/create_chart_tool.dart`
- [ ] T030 [US1] Implement annotation ID generation using UUID in `packages/braven_agent/lib/src/tools/create_chart_tool.dart`
- [ ] T031 [US1] Update `create_chart_tool.dart` output to return full chart WITH generated IDs
- [ ] T032 [US1] Integrate validation into `create_chart_tool.dart`
- [ ] T033 [US1] Update chart renderer to read from `series[].yAxis` in `packages/braven_agent/lib/src/renderer/chart_renderer.dart`
- [ ] T034 [US1] Remove `yAxisId` lookup and `yAxes[]` array resolution from `packages/braven_agent/lib/src/renderer/chart_renderer.dart`
- [ ] T035 [US1] Run `flutter analyze` on all US1 files - must show zero warnings
- [ ] T036 [US1] Run all US1 tests - all must now PASS

**Checkpoint**: User Story 1 complete - LLM can create multi-axis charts with nested yAxis

---

## Phase 4: User Story 2 - LLM Modifies Chart Using Update/Add/Remove Operations (Priority: P1)

**Goal**: LLM agent can modify charts using explicit update/add/remove operations with correct execution order

**Independent Test**: Create a chart, call `modify_chart` with update/add/remove operations, verify changes applied correctly

### Tests for User Story 2

- [ ] T037 [P] [US2] Write failing test for `modify_chart` update operation in `packages/braven_agent/test/tools/modify_chart_tool_test.dart`
- [ ] T038 [P] [US2] Write failing test for `modify_chart` add operation with ID generation in `packages/braven_agent/test/tools/modify_chart_tool_test.dart`
- [ ] T039 [P] [US2] Write failing test for `modify_chart` remove operation in `packages/braven_agent/test/tools/modify_chart_tool_test.dart`
- [ ] T040 [P] [US2] Write failing test for execution order (remove → add → update) in `packages/braven_agent/test/tools/modify_chart_tool_test.dart`
- [ ] T041 [P] [US2] Write failing test for deep merge on yAxis update in `packages/braven_agent/test/tools/modify_chart_tool_test.dart`
- [ ] T042 [P] [US2] Write failing test for V010 error (update non-existent series) in `packages/braven_agent/test/validation/schema_validator_test.dart`
- [ ] T043 [P] [US2] Write failing test for V011 error (remove non-existent series) in `packages/braven_agent/test/validation/schema_validator_test.dart`
- [ ] T044 [P] [US2] Write failing test for V012 error (add duplicate series) in `packages/braven_agent/test/validation/schema_validator_test.dart`
- [ ] T045 [P] [US2] Write failing test for V020 error (update non-existent annotation) in `packages/braven_agent/test/validation/schema_validator_test.dart`
- [ ] T045a [P] [US2] Write failing test for V021 error (remove non-existent annotation) in `packages/braven_agent/test/validation/schema_validator_test.dart`
- [ ] T045b [P] [US2] Write failing test for V022 warning (agent-supplied annotation id ignored) in `packages/braven_agent/test/validation/schema_validator_test.dart`

### Implementation for User Story 2

- [ ] T046 [US2] Implement V010-V012 (series modify validation) in `packages/braven_agent/lib/src/validation/schema_validator.dart`
- [ ] T047 [US2] Implement V020 (update non-existent annotation) in `packages/braven_agent/lib/src/validation/schema_validator.dart`
- [ ] T047a [US2] Implement V021 (remove non-existent annotation) in `packages/braven_agent/lib/src/validation/schema_validator.dart`
- [ ] T047b [US2] Implement V022 (agent-supplied id warning) in `packages/braven_agent/lib/src/validation/schema_validator.dart`
- [ ] T048 [US2] Restructure `modify_chart_tool.dart` input schema to use `update`/`add`/`remove` structure
- [ ] T049 [US2] Implement remove operation handler in `packages/braven_agent/lib/src/tools/modify_chart_tool.dart`
- [ ] T050 [US2] Implement add operation handler with UUID generation in `packages/braven_agent/lib/src/tools/modify_chart_tool.dart`
- [ ] T051 [US2] Implement update operation handler with deep merge in `packages/braven_agent/lib/src/tools/modify_chart_tool.dart`
- [ ] T052 [US2] Implement execution order (remove → add → update) in `packages/braven_agent/lib/src/tools/modify_chart_tool.dart`
- [ ] T053 [US2] Implement deep merge utility for nested objects in `packages/braven_agent/lib/src/tools/modify_chart_tool.dart`
- [ ] T054 [US2] Update `modify_chart_tool.dart` output to include `added` section with generated IDs
- [ ] T055 [US2] Integrate validation into `modify_chart_tool.dart`
- [ ] T056 [US2] Run `flutter analyze` on all US2 files - must show zero warnings
- [ ] T057 [US2] Run all US2 tests - all must now PASS

**Checkpoint**: User Story 2 complete - LLM can modify charts with explicit operations

---

## Phase 5: User Story 3 - LLM Queries Chart State Before Modification (Priority: P2)

**Goal**: LLM agent can query current chart state to discover IDs for subsequent modifications

**Independent Test**: Create a chart with annotations, call `get_chart`, verify all annotation IDs are returned

### Tests for User Story 3

- [ ] T058 [P] [US3] Write failing test for `get_chart` basic retrieval in `packages/braven_agent/test/tools/get_chart_tool_test.dart`
- [ ] T059 [P] [US3] Write failing test for `get_chart` with `includeData: false` (data as count) in `packages/braven_agent/test/tools/get_chart_tool_test.dart`
- [ ] T060 [P] [US3] Write failing test for `get_chart` with `includeData: true` (full data) in `packages/braven_agent/test/tools/get_chart_tool_test.dart`
- [ ] T061 [P] [US3] Write failing test for `get_chart` error on non-existent chart in `packages/braven_agent/test/tools/get_chart_tool_test.dart`

### Implementation for User Story 3

- [ ] T062 [US3] Create `GetChartTool` class in `packages/braven_agent/lib/src/tools/get_chart_tool.dart`
- [ ] T063 [US3] Implement input schema with `chartId` and `includeData` parameters
- [ ] T064 [US3] Implement data summarization logic (`{ "count": N }`) for `includeData: false`
- [ ] T065 [US3] Implement full data return for `includeData: true`
- [ ] T066 [US3] Implement error handling for non-existent chart
- [ ] T067 [US3] Register `GetChartTool` in tool registry at `packages/braven_agent/lib/src/tools/tools.dart`
- [ ] T068 [US3] Export `get_chart_tool.dart` from `packages/braven_agent/lib/braven_agent.dart`
- [ ] T069 [US3] Run `flutter analyze` on all US3 files - must show zero warnings
- [ ] T070 [US3] Run all US3 tests - all must now PASS

**Checkpoint**: User Story 3 complete - LLM can query chart state

---

## Phase 6: User Story 4 - System Validates References and Provides Clear Errors (Priority: P2)

**Goal**: System validates all inputs and returns clear, actionable error messages

**Independent Test**: Submit invalid configurations and verify appropriate error messages

### Tests for User Story 4

- [ ] T071 [P] [US4] Write failing test for V030 (seriesId references non-existent series) in `packages/braven_agent/test/validation/schema_validator_test.dart`
- [ ] T072 [P] [US4] Write failing test for V031 (point without seriesId) in `packages/braven_agent/test/validation/schema_validator_test.dart`
- [ ] T073 [P] [US4] Write failing test for V032 (marker without seriesId) in `packages/braven_agent/test/validation/schema_validator_test.dart`
- [ ] T074 [P] [US4] Write failing test for V033 (horizontal referenceLine in perSeries without seriesId) in `packages/braven_agent/test/validation/schema_validator_test.dart`
- [ ] T075 [P] [US4] Write failing test for V034 (horizontal zone in perSeries without seriesId) in `packages/braven_agent/test/validation/schema_validator_test.dart`
- [ ] T076 [P] [US4] Write failing test for V040 (referenceLine without value) in `packages/braven_agent/test/validation/schema_validator_test.dart`
- [ ] T077 [P] [US4] Write failing test for V041 (zone without minValue/maxValue) in `packages/braven_agent/test/validation/schema_validator_test.dart`
- [ ] T078 [P] [US4] Write failing test for V042 (point without dataPointIndex) in `packages/braven_agent/test/validation/schema_validator_test.dart`
- [ ] T079 [P] [US4] Write failing test for V043 (dataPointIndex out of range) in `packages/braven_agent/test/validation/schema_validator_test.dart`
- [ ] T080 [P] [US4] Write failing test for V044 (textLabel without text) in `packages/braven_agent/test/validation/schema_validator_test.dart`

### Implementation for User Story 4

- [ ] T081 [US4] Implement V030 (seriesId reference validation) in `packages/braven_agent/lib/src/validation/schema_validator.dart`
- [ ] T082 [US4] Implement V031-V034 (seriesId required validation) in `packages/braven_agent/lib/src/validation/schema_validator.dart`
- [ ] T083 [US4] Implement V040-V044 (type-specific validation) in `packages/braven_agent/lib/src/validation/schema_validator.dart`
- [ ] T084 [US4] Ensure all error messages include actionable guidance (e.g., "use get_chart to discover valid IDs")
- [ ] T085 [US4] Export validation module from `packages/braven_agent/lib/braven_agent.dart`
- [ ] T086 [US4] Run `flutter analyze` on all US4 files - must show zero warnings
- [ ] T087 [US4] Run all US4 tests - all must now PASS

**Checkpoint**: User Story 4 complete - System provides clear validation errors

---

## Phase 7: User Story 5 - Deep Merge for Nested Object Updates (Priority: P3)

**Goal**: Partial updates to nested objects (like yAxis) preserve unspecified properties

**Independent Test**: Update a nested property and verify other nested properties are preserved

### Tests for User Story 5

- [ ] T088 [P] [US5] Write failing test for deep merge preserving unspecified yAxis properties in `packages/braven_agent/test/tools/modify_chart_tool_test.dart`
- [ ] T089 [P] [US5] Write failing test for array replacement (data field) in `packages/braven_agent/test/tools/modify_chart_tool_test.dart`
- [ ] T090 [P] [US5] Write failing test for scalar replacement in `packages/braven_agent/test/tools/modify_chart_tool_test.dart`

### Implementation for User Story 5

- [ ] T091 [US5] Verify deep merge utility handles all edge cases in `packages/braven_agent/lib/src/tools/modify_chart_tool.dart`
- [ ] T092 [US5] Add explicit array replacement behavior for `data` field
- [ ] T093 [US5] Add unit tests for merge utility function
- [ ] T094 [US5] Run `flutter analyze` on all US5 files - must show zero warnings
- [ ] T095 [US5] Run all US5 tests - all must now PASS

**Checkpoint**: User Story 5 complete - Deep merge works correctly

---

## Phase 8: Integration Testing

**Purpose**: Full lifecycle testing across all user stories

- [ ] T096 [P] Write integration test for create → get → modify → remove cycle in `test/integration/agentic_flow_test.dart`
- [ ] T097 [P] Write integration test for annotation lifecycle in `test/integration/agentic_flow_test.dart`
- [ ] T098 Run full integration test suite
- [ ] T099 Manual testing of agentic flow in demo app at `example/lib/demos/braven_agent_demo.dart`

---

## Phase 9: Polish & Cross-Cutting Concerns

**Purpose**: Improvements that affect multiple user stories

- [ ] T100 [P] Update inline dartdoc comments for all changed classes
- [ ] T101 [P] Update `example/lib/demos/braven_agent_demo.dart` to use v2 schema
- [ ] T102 Remove any backward compatibility shims and dead code
- [ ] T103 Run `flutter analyze` on entire `lib/` directory - must show zero warnings
- [ ] T104 Run `flutter analyze` on entire `packages/braven_agent/` directory - must show zero warnings
- [ ] T105 Run full test suite: `flutter test test/ packages/braven_agent/test/`
- [ ] T106 Verify all 20 validation rules (V001-V044, with reserved ranges) are implemented and tested
- [ ] T107 Run quickstart.md validation - execute all examples

---

## Dependencies & Execution Order

### Phase Dependencies

```
Phase 1 (Setup) ──────────────────────────────────────────────────────────────►
                │
                ▼
Phase 2 (Foundational) ───────────────────────────────────────────────────────►
                │
                ├──────────────────────┬──────────────────────┐
                ▼                      ▼                      ▼
Phase 3 (US1: P1)        Phase 4 (US2: P1)       [Can run in parallel
MVP - Create Chart       Modify Chart            if team capacity allows]
                │                      │
                ▼                      ▼
Phase 5 (US3: P2)        Phase 6 (US4: P2)       [Depend on US1/US2
Query Chart              Validation Errors        for chart to exist]
                │                      │
                └──────────────────────┘
                           │
                           ▼
                  Phase 7 (US5: P3)
                  Deep Merge
                           │
                           ▼
                  Phase 8 (Integration)
                           │
                           ▼
                  Phase 9 (Polish)
```

### User Story Dependencies

| User Story         | Depends On                       | Independent Test                           |
| ------------------ | -------------------------------- | ------------------------------------------ |
| US1 (Create Chart) | Foundation only                  | Yes - can be fully tested alone            |
| US2 (Modify Chart) | Foundation only                  | Yes - create then modify in same test      |
| US3 (Query Chart)  | US1 or US2 (need chart to query) | Yes - create then query in same test       |
| US4 (Validation)   | Foundation only                  | Yes - submit invalid input, verify error   |
| US5 (Deep Merge)   | US2 (uses modify)                | Yes - create, modify partial, verify merge |

### Within Each User Story

1. Tests MUST be written and FAIL before implementation
2. Models before services
3. Services before tools
4. Core implementation before integration
5. Run `flutter analyze` before marking story complete

### Parallel Opportunities

**Phase 1-2**: All tasks marked [P] can run in parallel

**Phase 3-7**: Once Foundational phase completes:

- US1 and US2 can start in parallel (both P1 priority)
- US3 and US4 can start in parallel after US1/US2
- US5 can start after US2

**Within each phase**: All tests marked [P] can run in parallel

---

## Parallel Example: User Story 1

```bash
# Launch all US1 tests in parallel:
flutter test packages/braven_agent/test/tools/create_chart_tool_test.dart &
flutter test packages/braven_agent/test/validation/schema_validator_test.dart &
wait

# All should FAIL initially (TDD red phase)

# After implementation, run again - all should PASS (TDD green phase)
```

---

## Summary

| Metric                         | Value                    |
| ------------------------------ | ------------------------ |
| **Total Tasks**                | 111                      |
| **Phase 1 (Setup)**            | 4 tasks                  |
| **Phase 2 (Foundational)**     | 15 tasks                 |
| **Phase 3 (US1 - Create)**     | 17 tasks                 |
| **Phase 4 (US2 - Modify)**     | 25 tasks                 |
| **Phase 5 (US3 - Query)**      | 13 tasks                 |
| **Phase 6 (US4 - Validation)** | 17 tasks                 |
| **Phase 7 (US5 - Deep Merge)** | 8 tasks                  |
| **Phase 8 (Integration)**      | 4 tasks                  |
| **Phase 9 (Polish)**           | 8 tasks                  |
| **Parallel Opportunities**     | 54 tasks marked [P]      |
| **MVP Scope**                  | US1 (Phase 3) - 17 tasks |

### Validation Rule Coverage

All 20 validation rules are covered:

- V001-V004: Chart-level validation (US1)
- V005-V009: Reserved for future chart-level validation
- V010-V012: Series modify validation (US2)
- V013-V019: Reserved for future series validation
- V020-V022: Annotation modify validation (US2)
- V023-V029: Reserved for future annotation validation
- V030-V034: seriesId reference validation (US4)
- V035-V039: Reserved for future reference validation
- V040-V044: Type-specific annotation validation (US4)
