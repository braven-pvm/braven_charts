# Tasks: Multi-Axis Normalization

**Input**: Design documents from `/specs/011-multi-axis-normalization/`
**Prerequisites**: plan.md ✓, spec.md ✓, research.md ✓, data-model.md ✓, contracts/ ✓, quickstart.md ✓

**Tests**: TDD approach required per Constitution (Test-First Development). Tests BEFORE implementation.

**Organization**: Tasks grouped by user story to enable independent implementation and testing.

## Format: `[ID] [P?] [Story] Description`
- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (US1, US2, US3, US4)
- Include exact file paths in descriptions

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Create core types and foundational structure for multi-axis support

- [X] T001 [P] Create YAxisPosition enum in `lib/src_plus/models/y_axis_position.dart`
- [X] T002 [P] Create NormalizationMode enum in `lib/src_plus/models/normalization_mode.dart`
- [X] T003 [P] Create YAxisConfig class in `lib/src_plus/axis/y_axis_config.dart`
- [X] T004 [P] Create MultiAxisState class in `lib/src_plus/axis/multi_axis_state.dart`
- [X] T005 Create barrel export for new types in `lib/src_plus/axis/axis.dart`
- [X] T006 Add `yAxisId` and `unit` fields to ChartSeries base class in `lib/src_plus/models/chart_series.dart`

**Checkpoint**: Core types available for user story implementation ✅

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Infrastructure that MUST complete before user stories

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [X] T007 Create test directory structure at `test/unit/multi_axis/`
- [X] T008 Create test directory structure at `test/widget/multi_axis/`
- [X] T009 Create test directory structure at `test/golden/multi_axis/`
- [X] T010 Add `yAxes` and `normalizationMode` parameters to BravenChartPlus widget in `lib/src_plus/widgets/braven_chart_plus.dart`
- [X] T011 Create MultiAxisLayoutDelegate for axis width computation in `lib/src_plus/layout/multi_axis_layout.dart`
- [X] T012 Create axis bounds computation utility in `lib/src_plus/axis/axis_bounds_calculator.dart`
- [X] T012a [P] **[FR-009]** Disable grid lines when multi-axis active in `lib/src_plus/rendering/grid_renderer.dart`
- [X] T012b [P] Unit test for Y-axis zoom constraint in `test/unit/multi_axis/zoom_constraint_test.dart`
- [X] T012c **[FR-013]** Disable Y-axis zoom/pan when multi-axis mode active in `lib/src_plus/interaction/zoom_controller.dart` - X-axis zoom remains functional

**Checkpoint**: Foundation ready - user story implementation can begin

---

## Phase 3: User Story 1 - Multi-Scale Data Visualization (Priority: P1) 🎯 MVP

**Goal**: Display multiple series with vastly different Y-ranges, each using full vertical space with its own Y-axis showing original values

**Independent Test**: Create chart with 2+ series having >10x range difference and verify all series span full vertical height with original values on axes

### Tests for User Story 1

- [ ] T013 [P] [US1] Unit test for per-axis normalization in `test/unit/multi_axis/normalization_test.dart`
- [ ] T014 [P] [US1] Unit test for axis bounds computation in `test/unit/multi_axis/axis_bounds_test.dart`
- [ ] T015 [P] [US1] Widget test for multi-axis rendering in `test/widget/multi_axis/multi_axis_chart_test.dart`
- [ ] T016 [P] [US1] Golden test for 2-axis chart in `test/golden/multi_axis/two_axis_chart_test.dart`
- [ ] T017 [P] [US1] Golden test for 4-axis chart in `test/golden/multi_axis/four_axis_chart_test.dart`

### Implementation for User Story 1

- [ ] T018 [US1] Implement series-to-axis binding resolution in `lib/src_plus/axis/series_axis_resolver.dart`
- [ ] T019 [US1] Implement per-axis Y normalization in `lib/src_plus/rendering/multi_axis_normalizer.dart`
- [ ] T020 [US1] Modify axis renderer for multiple Y-axes in `lib/src_plus/rendering/y_axis_renderer.dart`
- [ ] T021 [US1] Implement axis layout positioning (left/right) in `lib/src_plus/layout/axis_layout_manager.dart`
- [ ] T022 [US1] Integrate multi-axis rendering into chart paint in `lib/src_plus/rendering/chart_painter.dart`
- [ ] T023 [US1] Update tooltip to display original Y-values with units in `lib/src_plus/interaction/tooltip_builder.dart`
- [ ] T024 [US1] Add example multi-axis chart to showcase in `example/lib/showcase_plus/pages/scientific_data_page.dart`

**Checkpoint**: User Story 1 complete - multi-scale visualization working independently

---

## Phase 4: User Story 2 - Automatic Normalization Detection (Priority: P2)

**Goal**: System auto-detects when series need separate axes (ranges differ >10x)

**Independent Test**: Create chart with series whose ranges differ by >10x without explicit config and verify multi-axis mode activates

### Tests for User Story 2

- [ ] T025 [P] [US2] Unit test for auto-detection algorithm in `test/unit/multi_axis/auto_detection_test.dart`
- [ ] T026 [P] [US2] Widget test for auto-mode triggering in `test/widget/multi_axis/auto_detection_widget_test.dart`

### Implementation for User Story 2

- [ ] T027 [US2] Implement range ratio calculator in `lib/src_plus/axis/range_ratio_calculator.dart`
- [ ] T028 [US2] Implement auto-detection logic in `lib/src_plus/axis/normalization_detector.dart`
- [ ] T029 [US2] Integrate auto-detection with chart initialization in `lib/src_plus/widgets/braven_chart_plus.dart`
- [ ] T030 [US2] Add auto-detection example to showcase in `example/lib/showcase_plus/pages/scientific_data_page.dart`

**Checkpoint**: User Story 2 complete - auto-detection working independently

---

## Phase 5: User Story 3 - Color-Coded Axis Identification (Priority: P2)

**Goal**: Each Y-axis color matches its bound series for instant visual association

**Independent Test**: Create chart with colored series and verify each Y-axis uses same color

### Tests for User Story 3

- [ ] T031 [P] [US3] Unit test for axis color resolution in `test/unit/multi_axis/axis_color_test.dart`
- [ ] T032 [P] [US3] Widget test for color-coded axes in `test/widget/multi_axis/axis_color_widget_test.dart`
- [ ] T033 [P] [US3] Golden test for colored axes in `test/golden/multi_axis/colored_axes_test.dart`

### Implementation for User Story 3

- [ ] T034 [US3] Implement axis color resolver (from config or series) in `lib/src_plus/axis/axis_color_resolver.dart`
- [ ] T035 [US3] Apply color to axis labels in Y-axis renderer in `lib/src_plus/rendering/y_axis_renderer.dart`
- [ ] T036 [US3] Apply color to axis ticks in Y-axis renderer in `lib/src_plus/rendering/y_axis_renderer.dart`
- [ ] T037 [US3] Apply color to axis line in Y-axis renderer in `lib/src_plus/rendering/y_axis_renderer.dart`
- [ ] T038 [US3] Handle shared axis color (neutral or first series) in `lib/src_plus/axis/axis_color_resolver.dart`
- [ ] T039 [US3] Add themed axis color example to showcase in `example/lib/showcase_plus/pages/scientific_data_page.dart`

**Checkpoint**: User Story 3 complete - color-coded axes working independently

---

## Phase 6: User Story 4 - Original Value Display in Crosshair (Priority: P3)

**Goal**: Crosshair and tracking mode display original Y-values with proper formatting

**Independent Test**: Enable crosshair, hover over data points, verify displayed values match original data

### Tests for User Story 4

- [ ] T040 [P] [US4] Unit test for value formatting with units in `test/unit/multi_axis/value_formatter_test.dart`
- [ ] T041 [P] [US4] Widget test for crosshair values in `test/widget/multi_axis/crosshair_values_test.dart`

### Implementation for User Story 4

- [ ] T042 [US4] Create multi-axis value formatter in `lib/src_plus/formatting/multi_axis_value_formatter.dart`
- [ ] T043 [US4] **[FR-014]** Update crosshair to use per-axis Y bounds lookup in `lib/src_plus/interaction/crosshair_handler.dart` - screen Y position → per-axis data value conversion
- [ ] T044 [US4] Update tracking mode to display all series values in `lib/src_plus/interaction/tracking_overlay.dart`
- [ ] T045 [US4] Format decimal values appropriately (no over-precision) in `lib/src_plus/formatting/multi_axis_value_formatter.dart`
- [ ] T046 [US4] Add crosshair example to showcase in `example/lib/showcase_plus/pages/scientific_data_page.dart`

**Checkpoint**: User Story 4 complete - crosshair with original values working

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: Final validation, documentation, and cleanup

- [ ] T047 [P] Add validation for max 4 axes in `lib/src_plus/axis/y_axis_config.dart`
- [ ] T048 [P] Add validation for unique axis positions in `lib/src_plus/widgets/braven_chart_plus.dart`
- [ ] T049 [P] Add API documentation to all public classes in `lib/src_plus/axis/`
- [ ] T050 Run performance benchmark (60 FPS with 4 series × 1000 points) in `test/benchmarks/multi_axis_benchmark.dart`
- [ ] T051 Validate backward compatibility (single-axis mode unchanged) in `test/widget/multi_axis/backward_compat_test.dart`
- [ ] T052 Run quickstart.md validation - test all code examples compile
- [ ] T053 Update CHANGELOG.md with multi-axis normalization feature

---

## Dependencies & Execution Order

### Phase Dependencies

```
Phase 1: Setup ──────────────────────────────────────┐
                                                     │
Phase 2: Foundational ◄──────────────────────────────┘
         │
         ▼
         ┌──────────────────────────────────────────────────────────────┐
         │                    USER STORIES (can parallel)                │
         │                                                               │
         │  Phase 3: US1 (P1) ──┬── Phase 4: US2 (P2) ──┬── Phase 5: US3│
         │  Multi-Scale Viz     │   Auto-Detection      │   Color-Coded │
         │                      │                       │               │
         │                      └───────────────────────┴───────────────┤
         │                                                               │
         │                              Phase 6: US4 (P3)                │
         │                              Crosshair Values                 │
         └──────────────────────────────────────────────────────────────┘
                                        │
                                        ▼
                              Phase 7: Polish
```

### User Story Dependencies

| Story | Depends On | Can Run With |
|-------|------------|--------------|
| US1 (P1) | Phase 2 only | US2, US3 (after Phase 2) |
| US2 (P2) | Phase 2 only | US1, US3 (after Phase 2) |
| US3 (P2) | Phase 2 only | US1, US2 (after Phase 2) |
| US4 (P3) | US1 (needs rendering) | - |

### Within Each User Story

1. Tests MUST be written FIRST and FAIL before implementation
2. Core logic before rendering integration
3. Rendering before interaction features
4. Story complete before Phase 7 polish

### Parallel Opportunities

**Phase 1** (all can run in parallel):
- T001, T002, T003, T004 - Independent type definitions

**Phase 3 Tests** (all can run in parallel):
- T013, T014, T015, T016, T017 - Independent test files

**Phase 4-6** (stories can run in parallel after US1 core):
- US2 and US3 can start once Phase 2 complete
- US4 requires US1 rendering to be functional

---

## Parallel Example: User Story 1

```bash
# Launch all tests for User Story 1 together:
flutter test test/unit/multi_axis/normalization_test.dart &
flutter test test/unit/multi_axis/axis_bounds_test.dart &
flutter test test/widget/multi_axis/multi_axis_chart_test.dart &

# After tests written and failing, implement models in parallel:
# T018, T019 can run in parallel (different files)
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. ✅ Complete Phase 1: Setup (core types)
2. ✅ Complete Phase 2: Foundational (infrastructure)
3. ✅ Complete Phase 3: User Story 1 (multi-scale viz)
4. **STOP and VALIDATE**: Test US1 independently
5. Demo multi-axis chart with 2+ series

### Incremental Delivery

| Increment | Stories | Value Delivered |
|-----------|---------|-----------------|
| MVP | US1 | Multi-scale visualization works |
| +1 | US1 + US2 | Auto-detection reduces config |
| +2 | US1 + US2 + US3 | Color-coded axes improve UX |
| +3 | All | Full crosshair with original values |

### Suggested Team Assignment

**Solo Developer** (recommended):
1. Setup → Foundational → US1 → US2 → US3 → US4 → Polish

**Two Developers**:
- Dev A: Setup + US1 + US4
- Dev B: Foundational + US2 + US3 + Polish

---

## Task Summary

| Phase | Tasks | Parallel | Description |
|-------|-------|----------|-------------|
| Phase 1 | 6 | 4 | Setup - core types |
| Phase 2 | 9 | 5 | Foundational - infrastructure + grid/zoom constraints |
| Phase 3 | 12 | 5 | US1 - Multi-scale visualization |
| Phase 4 | 6 | 2 | US2 - Auto-detection |
| Phase 5 | 9 | 3 | US3 - Color-coded axes |
| Phase 6 | 7 | 2 | US4 - Crosshair values |
| Phase 7 | 7 | 4 | Polish & validation |
| **Total** | **56** | **25** | |

---

## Notes

- Constitution requires TDD: Write tests FIRST, verify they FAIL, then implement
- Each user story is independently testable after completion
- Commit after each task or logical group
- Performance target: 60 FPS with 4 series × 1000 points
- Backward compatibility is mandatory: existing single-axis charts unchanged

---

*Tasks Generated: 2025-11-27*
