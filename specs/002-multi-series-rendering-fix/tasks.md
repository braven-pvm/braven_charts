# Tasks: Multi-Series Rendering Improvements

**Input**: Design documents from `/specs/002-multi-series-rendering-fix/`
**Prerequisites**: plan.md ✓, spec.md ✓, research.md ✓, data-model.md ✓

**Tests**: Tests are included per Constitution requirement (TDD methodology).

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions

- **Library source**: `lib/src/` at repository root
- **Tests**: `test/unit/`, `test/widget/`, `test/integration/`

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Create foundational data structures needed by all user stories

- [ ] T001 Create BarGroupInfo class with constructor-configurable gap parameter (default 2.0px, satisfies FR-003) in lib/src/models/bar_group_info.dart
- [ ] T002 [P] Create unit tests for BarGroupInfo in test/unit/rendering/bar_group_info_test.dart
- [ ] T003 Export BarGroupInfo from lib/braven_charts.dart

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core infrastructure changes that enable both grouped bars and Y-zoom fixes

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [ ] T004 Add barGroupInfo field to SeriesElement in lib/src/elements/series_element.dart
- [ ] T005 Add forPainting parameter to computeAxisBounds() in lib/src/rendering/modules/multi_axis_manager.dart
- [ ] T006 [P] Add unit tests for computeAxisBounds with forPainting=true in test/unit/rendering/multi_axis_zoom_test.dart

**Checkpoint**: Foundation ready - user story implementation can now begin

---

## Phase 3: User Story 1 - View Multiple Bar Series Side-by-Side (Priority: P1) 🎯 MVP

**Goal**: Multiple bar series at the same X-position render adjacent (grouped) rather than overlapping

**Independent Test**: Create chart with 2+ BarChartSeries sharing X-values → all bars visible and adjacent

### Tests for User Story 1 ⚠️

**NOTE: Write these tests FIRST, ensure they FAIL before implementation**

- [ ] T007 [P] [US1] Widget test for 2 bar series grouping in test/widget/charts/grouped_bar_chart_test.dart
- [ ] T008 [P] [US1] Widget test for 3+ bar series grouping in test/widget/charts/grouped_bar_chart_test.dart
- [ ] T009 [P] [US1] Widget test for single bar series (unchanged behavior) in test/widget/charts/grouped_bar_chart_test.dart
- [ ] T010 [P] [US1] Widget test for minimum bar width (4px) enforcement in test/widget/charts/grouped_bar_chart_test.dart

### Implementation for User Story 1

- [ ] T011 [US1] Compute bar series index/count during element generation in lib/src/braven_chart_plus.dart
- [ ] T012 [US1] Modify \_paintBarSeries() to use BarGroupInfo for X-offset in lib/src/elements/series_element.dart
- [ ] T013 [US1] Enforce minimum bar width (4px) in \_paintBarSeries() in lib/src/elements/series_element.dart
- [ ] T014 [US1] Handle non-overlapping X-values (centered bars) in lib/src/elements/series_element.dart

**Checkpoint**: User Story 1 complete - grouped bar charts work independently

---

## Phase 4: User Story 2 - Zoom Y-Axis with Multi-Axis Charts (Priority: P1)

**Goal**: Vertical zoom works correctly with perSeries normalization and multiple Y-axes

**Independent Test**: Create multi-axis chart with perSeries normalization → Y-zoom scales data correctly

### Tests for User Story 2 ⚠️

**NOTE: Write these tests FIRST, ensure they FAIL before implementation**

- [ ] T015 [P] [US2] Widget test for mouse wheel Y-zoom with perSeries in test/widget/charts/multi_axis_zoom_test.dart
- [ ] T016 [P] [US2] Widget test for Y-scrollbar edge drag zoom in test/widget/charts/multi_axis_zoom_test.dart
- [ ] T017 [P] [US2] Widget test for Y-axis labels reflect zoomed range in test/widget/charts/multi_axis_zoom_test.dart
- [ ] T018 [P] [US2] Widget test for zoom center point preservation in test/widget/charts/multi_axis_zoom_test.dart

### Implementation for User Story 2

- [ ] T019 [US2] Implement viewport-aware bounds in computeAxisBounds(forPainting: true) in lib/src/rendering/modules/multi_axis_manager.dart
- [ ] T020 [US2] Update \_paintSeries() to use forPainting bounds for per-series transforms in lib/src/rendering/chart_render_box.dart
- [ ] T021 [US2] Ensure Y-axis labels use correct zoomed bounds in lib/src/rendering/chart_render_box.dart
- [ ] T022 [US2] Verify zoom center point is preserved for Y-axis in lib/src/rendering/chart_render_box.dart

**Checkpoint**: User Story 2 complete - Y-zoom works with multi-axis charts

---

## Phase 5: User Story 3 - Pan Through Zoomed Multi-Axis Charts (Priority: P2)

**Goal**: Panning works correctly after zooming on multi-axis charts with perSeries normalization

**Independent Test**: Zoom multi-axis chart, then pan → viewport scrolls correctly, tooltips accurate

### Tests for User Story 3 ⚠️

**NOTE: Write these tests FIRST, ensure they FAIL before implementation**

- [ ] T023 [P] [US3] Widget test for pan after Y-zoom in test/widget/charts/multi_axis_zoom_test.dart
- [ ] T024 [P] [US3] Widget test for crosshair tooltips after zoom+pan in test/widget/charts/multi_axis_zoom_test.dart

### Implementation for User Story 3

- [ ] T025 [US3] Verify pan updates per-series transforms correctly in lib/src/rendering/chart_render_box.dart
- [ ] T026 [US3] Ensure crosshair/tooltip uses correct (display) bounds after pan in lib/src/rendering/chart_render_box.dart

**Checkpoint**: User Story 3 complete - full zoom+pan workflow works

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Regression testing, performance validation, documentation

- [ ] T027 [P] Run full test suite and fix any regressions (flutter test)
- [ ] T028 [P] Performance benchmark: verify 60fps with 1000+ points during zoom/pan
- [ ] T029 [P] Update FitDistributionPage demo to showcase grouped bars in example/lib/demos/
- [ ] T030 [P] Add inline documentation for BarGroupInfo in lib/src/models/bar_group_info.dart
- [ ] T031 [P] Add inline documentation for forPainting parameter in lib/src/rendering/modules/multi_axis_manager.dart
- [ ] T032 Run flutter analyze and fix all warnings
- [ ] T033 Integration test for multi-series rendering in test/integration/multi_series_rendering_test.dart

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on T001 (BarGroupInfo class)
- **User Story 1 (Phase 3)**: Depends on Phase 2 completion (T004-T006)
- **User Story 2 (Phase 4)**: Depends on Phase 2 completion (T004-T006)
- **User Story 3 (Phase 5)**: Depends on User Story 2 completion (T019-T022)
- **Polish (Phase 6)**: Depends on all user stories being complete

### User Story Dependencies

- **User Story 1 (P1)**: Can start after Foundational - No dependencies on other stories
- **User Story 2 (P1)**: Can start after Foundational - No dependencies on US1
- **User Story 3 (P2)**: Depends on User Story 2 (zoom must work before pan can be tested)

### Within Each User Story

- Tests (T007-T010, T015-T018, T023-T024) MUST be written and FAIL before implementation
- Implementation tasks within a story are sequential (depend on each other)
- Story complete before moving to next priority

### Parallel Opportunities

**Phase 1**: T002 can run in parallel with T001 (test file creation)
**Phase 2**: T006 can run in parallel after T005 completes
**Phase 3**: T007-T010 can ALL run in parallel (different test cases)
**Phase 4**: T015-T018 can ALL run in parallel (different test cases)
**Phase 5**: T023-T024 can run in parallel
**Phase 6**: T027-T031 can ALL run in parallel

**Cross-Story Parallelism**: User Story 1 and User Story 2 can be worked on simultaneously after Phase 2 completes (different files, independent functionality)

---

## Parallel Example: User Story 1 Tests

```bash
# Launch all US1 tests together (they test different scenarios):
flutter test test/widget/charts/grouped_bar_chart_test.dart
```

## Parallel Example: User Story 2 Tests

```bash
# Launch all US2 tests together:
flutter test test/widget/charts/multi_axis_zoom_test.dart
```

---

## Implementation Strategy

### MVP Scope (Minimum Viable Product)

**User Story 1 alone delivers value**: Grouped bar charts are immediately useful and can be shipped independently. This is the recommended MVP.

### Incremental Delivery

1. **MVP Release**: Phase 1 + Phase 2 + Phase 3 (User Story 1) → Grouped bar charts work
2. **Full Release**: + Phase 4 (User Story 2) → Y-zoom works
3. **Complete Release**: + Phase 5 (User Story 3) + Phase 6 → Full functionality with polish

### Risk Mitigation

- User Story 1 and User Story 2 can be developed in parallel
- User Story 3 is lower priority and can be deferred if needed
- Each phase has a checkpoint to validate before proceeding
