# Tasks: Axis Renderer Unification

**Input**: Design documents from `/specs/013-axis-renderer-unification/`
**Prerequisites**: plan.md (required), spec.md (required), research.md, data-model.md, contracts/

**Tests**: Unit tests included as part of TDD constitution requirement. This is a Flutter library refactor.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`
- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions
- **Library source**: `lib/src/` at repository root
- **Tests**: `test/` at repository root
- **Example app**: `example/lib/`

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Create new files and enum that all user stories depend on

- [ ] T001 [P] Add `CrosshairLabelPosition` enum to `lib/src/models/y_axis_config.dart`
- [ ] T002 [P] Add `crosshairLabelPosition` property to `YAxisConfig` class in `lib/src/models/y_axis_config.dart`
- [ ] T003 [P] Update `YAxisConfig.copyWith()` method to include `crosshairLabelPosition` parameter in `lib/src/models/y_axis_config.dart`
- [ ] T004 [P] Update `YAxisConfig` equality (`==`, `hashCode`, `toString`) to include `crosshairLabelPosition` in `lib/src/models/y_axis_config.dart`
- [ ] T005 [P] Create `GridConfig` model class in `lib/src/models/grid_config.dart`
- [ ] T006 [P] Create `GridRenderer` class skeleton in `lib/src/rendering/grid_renderer.dart`
- [ ] T007 Export new models in `lib/braven_charts.dart` (add `GridConfig`, `CrosshairLabelPosition` exports)

**Checkpoint**: New entities created and exported

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core infrastructure changes that MUST be complete before ANY user story can be implemented

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [ ] T008 Change `BravenChartPlus.yAxis` type from `AxisConfig?` to `YAxisConfig?` in `lib/src/braven_chart_plus.dart`
- [ ] T009 Add `grid` property (`GridConfig?`) to `BravenChartPlus` widget in `lib/src/braven_chart_plus.dart`
- [ ] T010 Update `BravenChartPlusState._rebuildElements()` to handle `YAxisConfig` directly (remove AxisConfig conversion) in `lib/src/braven_chart_plus.dart`
- [ ] T011 Update `MultiAxisManager.getEffectiveYAxes()` to include primary Y-axis from `BravenChartPlus.yAxis` in `lib/src/rendering/modules/multi_axis_manager.dart`
- [ ] T012 Add default Y-axis auto-creation when `yAxis` is null AND no series has `yAxisConfig` in `lib/src/rendering/modules/multi_axis_manager.dart`
- [ ] T013 Implement `GridRenderer.paintHorizontalGrid()` method in `lib/src/rendering/grid_renderer.dart`
- [ ] T014 Implement `GridRenderer.paintVerticalGrid()` method in `lib/src/rendering/grid_renderer.dart`
- [ ] T015 Rename `lib/src/axis/axis_renderer.dart` to `lib/src/axis/x_axis_renderer.dart` and update class name to `XAxisRenderer`
- [ ] T016 Remove Y-axis rendering code from `XAxisRenderer` (formerly AxisRenderer) in `lib/src/axis/x_axis_renderer.dart`
- [ ] T017 Remove grid rendering code from `XAxisRenderer` in `lib/src/axis/x_axis_renderer.dart`
- [ ] T018 Update all imports that reference `axis_renderer.dart` to use `x_axis_renderer.dart`
- [ ] T019 Update `chart_render_box.dart` to use `GridRenderer` for grid lines (before axes) in `lib/src/rendering/chart_render_box.dart`
- [ ] T020 Update `chart_render_box.dart` to route ALL Y-axis rendering through `MultiAxisPainter` in `lib/src/rendering/chart_render_box.dart`
- [ ] T021 Update `chart_render_box.dart` to use `XAxisRenderer` for X-axis only in `lib/src/rendering/chart_render_box.dart`
- [ ] T022 Run `flutter analyze lib/` and fix all analyzer issues

**Checkpoint**: Foundation ready - unified rendering path established, user story implementation can now begin

---

## Phase 3: User Story 1 - Simple Chart with Default Y-Axis (Priority: P1) 🎯 MVP

**Goal**: Charts render a default left Y-axis automatically when no Y-axis configuration is provided

**Independent Test**: Create `BravenChartPlus` with only series data, verify Y-axis appears on left with auto-scaled range

### Tests for User Story 1

- [ ] T023 [P] [US1] Add unit test for default Y-axis auto-creation in `test/unit/multi_axis/default_y_axis_test.dart`
- [ ] T024 [P] [US1] Add widget test for chart with no Y-axis config renders left axis in `test/widget/braven_chart_plus_test.dart`
- [ ] T024a [P] [US1] Add unit test verifying YAxisConfig works without explicit `id` parameter (FR-007) in `test/unit/multi_axis/y_axis_config_test.dart`
- [ ] T024b [P] [US1] Add edge case tests: empty data, single point, zero range in `test/unit/multi_axis/default_y_axis_test.dart`

### Implementation for User Story 1

- [ ] T025 [US1] Verify `MultiAxisManager.getEffectiveYAxes()` returns default when no Y-axis configured in `lib/src/rendering/modules/multi_axis_manager.dart`
- [ ] T026 [US1] Verify auto-scaling works for default Y-axis (data range calculation) in `lib/src/rendering/modules/multi_axis_manager.dart`
- [ ] T027 [US1] Run tests for User Story 1: `flutter test test/unit/multi_axis/default_y_axis_test.dart test/widget/braven_chart_plus_test.dart`

**Checkpoint**: Charts with no Y-axis config automatically show a left Y-axis

---

## Phase 4: User Story 2 - Customized Single Y-Axis with Modern Features (Priority: P1)

**Goal**: Single Y-axis via `BravenChartPlus.yAxis` supports all modern features (position, unit, crosshair)

**Independent Test**: Create chart with `yAxis: YAxisConfig(position: YAxisPosition.right, unit: 'W', showCrosshairLabel: true)` and verify all features work

### Tests for User Story 2

- [ ] T028 [P] [US2] Add unit test for `YAxisConfig.crosshairLabelPosition` property in `test/unit/multi_axis/y_axis_config_test.dart`
- [ ] T029 [P] [US2] Add widget test for right-side Y-axis rendering in `test/widget/y_axis_position_test.dart`
- [ ] T030 [P] [US2] Add widget test for unit display on single Y-axis in `test/widget/y_axis_unit_test.dart`

### Implementation for User Story 2

- [ ] T031 [US2] Verify Y-axis position (left/right/leftOuter/rightOuter) works for single-axis mode in `lib/src/rendering/chart_render_box.dart`
- [ ] T032 [US2] Verify unit display works for single-axis via `MultiAxisPainter` in `lib/src/rendering/multi_axis_painter.dart`
- [ ] T033 [US2] Run tests for User Story 2: `flutter test test/unit/multi_axis/y_axis_config_test.dart test/widget/y_axis_position_test.dart test/widget/y_axis_unit_test.dart`

**Checkpoint**: Single Y-axis supports all modern features

---

## Phase 5: User Story 3 - Multi-Axis Chart Unchanged Behavior (Priority: P1)

**Goal**: Existing multi-axis charts continue working identically (zero regression)

**Independent Test**: Run existing multi-axis demos/tests, verify identical visual output

### Tests for User Story 3

- [ ] T034 [US3] Run all existing multi-axis tests: `flutter test test/unit/multi_axis/`
- [ ] T035 [US3] Verify all existing multi-axis tests pass without modification (zero regression)

### Implementation for User Story 3

- [ ] T036 [US3] Review and fix any failing multi-axis tests (should be none if foundation done correctly)
- [ ] T037 [US3] Verify visual output matches before/after for multi-axis demo in `example/lib/demos/`

**Checkpoint**: Multi-axis mode unchanged, zero regression

---

## Phase 6: User Story 4 - Grid Rendering Independence (Priority: P2)

**Goal**: Grid lines controlled via chart-level `GridConfig`, independent of axis setup

**Independent Test**: Create chart with `grid: GridConfig(horizontal: true, vertical: false)` and verify only horizontal grid lines appear

### Tests for User Story 4

- [ ] T038 [P] [US4] Add unit test for `GridConfig` model in `test/unit/models/grid_config_test.dart`
- [ ] T039 [P] [US4] Add unit test for `GridRenderer` in `test/unit/rendering/grid_renderer_test.dart`
- [ ] T040 [P] [US4] Add widget test for horizontal-only grid in `test/widget/grid_rendering_test.dart`
- [ ] T041 [P] [US4] Add widget test for vertical-only grid in `test/widget/grid_rendering_test.dart`

### Implementation for User Story 4

- [ ] T042 [US4] Verify `GridConfig` properties control grid visibility correctly in `lib/src/rendering/chart_render_box.dart`
- [ ] T043 [US4] Verify grid colors and stroke widths from `GridConfig` are applied in `lib/src/rendering/grid_renderer.dart`
- [ ] T044 [US4] Verify grid falls back to theme when colors are null in `lib/src/rendering/grid_renderer.dart`
- [ ] T045 [US4] Run tests for User Story 4: `flutter test test/unit/models/grid_config_test.dart test/unit/rendering/grid_renderer_test.dart test/widget/grid_rendering_test.dart`

**Checkpoint**: Grid rendering works independently of axis configuration

---

## Phase 7: User Story 5 - Crosshair Label Position Control (Priority: P2)

**Goal**: Control where crosshair Y-value labels appear per axis (overAxis vs insidePlot)

**Independent Test**: Create chart with `crosshairLabelPosition: CrosshairLabelPosition.insidePlot` and verify label appears inside plot area

### Tests for User Story 5

- [ ] T046 [P] [US5] Add unit test for `CrosshairLabelPosition` enum in `test/unit/multi_axis/y_axis_config_test.dart`
- [ ] T047 [P] [US5] Add widget test for crosshair label at overAxis position in `test/widget/crosshair_label_position_test.dart`
- [ ] T048 [P] [US5] Add widget test for crosshair label at insidePlot position in `test/widget/crosshair_label_position_test.dart`

### Implementation for User Story 5

- [ ] T049 [US5] Update `CrosshairRenderer._paintPerAxisCrosshairLabels()` to respect `crosshairLabelPosition` in `lib/src/rendering/modules/crosshair_renderer.dart`
- [ ] T050 [US5] Implement `overAxis` label positioning (outside plot area) in `lib/src/rendering/modules/crosshair_renderer.dart`
- [ ] T051 [US5] Implement `insidePlot` label positioning (inside plot area) in `lib/src/rendering/modules/crosshair_renderer.dart`
- [ ] T052 [US5] Run tests for User Story 5: `flutter test test/unit/multi_axis/y_axis_config_test.dart test/widget/crosshair_label_position_test.dart`

**Checkpoint**: Crosshair label position is controllable per axis

---

## Phase 8: User Story 6 - X-Axis API Consistency (Priority: P3) - DEFERRED

**Goal**: Create `XAxisConfig` for API consistency with `YAxisConfig`

**Note**: This corresponds to "Phase 5: X-Axis Consistency (Future)" in spec.md FR-016/FR-017. Implementation deferred to future feature branch.

### Placeholder Tasks (for future implementation)

- [ ] T053 [US6] Create `XAxisConfig` model in `lib/src/models/x_axis_config.dart` (DEFERRED)
- [ ] T054 [US6] Create `XAxisPosition` enum with `top`, `bottom` values (DEFERRED)
- [ ] T055 [US6] Change `BravenChartPlus.xAxis` type from `AxisConfig?` to `XAxisConfig?` (DEFERRED)
- [ ] T056 [US6] Update `XAxisRenderer` to use `XAxisConfig` (DEFERRED)

**Checkpoint**: DEFERRED - Not implemented in this feature branch

---

## Phase 9: Performance & Cleanup

**Purpose**: Performance optimization and code cleanup

- [ ] T057 [P] Add TextPainter caching to `MultiAxisPainter` with `Map<String, Map<double, TextPainter>>` in `lib/src/rendering/multi_axis_painter.dart`
- [ ] T058 [P] Implement cache invalidation on axis config change in `lib/src/rendering/multi_axis_painter.dart`
- [ ] T058a Run performance benchmark: verify 60fps (16ms frame time) during crosshair interaction (SC-006)
- [ ] T059 [P] Remove unused Y-axis code from `InternalAxisConfig` in `lib/src/axis/internal_axis_config.dart`
- [ ] T060 [P] Remove deprecated `toAxisConfig()` Y-axis conversion methods
- [ ] T061 [P] Update package exports in `lib/braven_charts.dart` to remove deprecated exports
- [ ] T061a Verify AxisConfig Y-axis usage is fully removed from public API (SC-007)
- [ ] T062 Run `flutter analyze lib/` - must return zero warnings

**Checkpoint**: Performance optimized, legacy code removed

---

## Phase 10: Polish & Documentation

**Purpose**: Documentation, demos, and final validation

- [ ] T063 [P] Create unified axis demo in `example/lib/demos/axis_unification_demo.dart`
- [ ] T064 [P] Update `readme.md` with new `YAxisConfig` and `GridConfig` examples
- [ ] T065 [P] Add migration section to `changelog.md` with before/after code examples
- [ ] T066 [P] Update `docs/architecture/specs/axis_renderer_unification_spec.md` checklist items as complete
- [ ] T067 Run full test suite: `flutter test`
- [ ] T068 Run `flutter analyze lib/ example/` - must return zero errors
- [ ] T069 Manual verification: Run demo app and verify all axis features work

**Checkpoint**: Feature complete, documented, tested

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1 (Setup)**: No dependencies - can start immediately
- **Phase 2 (Foundational)**: Depends on Phase 1 - BLOCKS all user stories
- **Phase 3-7 (User Stories)**: All depend on Phase 2 completion
  - US1, US2, US3 are all P1 priority - can proceed sequentially
  - US4, US5 are P2 priority - depend on US1-3 conceptually
  - US6 is DEFERRED
- **Phase 9 (Performance)**: Depends on Phase 7 completion
- **Phase 10 (Polish)**: Depends on Phase 9 completion

### User Story Dependencies

- **US1 (Default Y-Axis)**: Foundation only - truly independent
- **US2 (Modern Features)**: Foundation only - can parallel with US1
- **US3 (Multi-Axis Unchanged)**: Foundation only - regression testing
- **US4 (Grid Independence)**: Requires GridRenderer from Phase 2
- **US5 (Crosshair Position)**: Requires CrosshairLabelPosition enum from Phase 1

### Parallel Opportunities

**Phase 1 (all parallel)**:
- T001, T002, T003, T004 (YAxisConfig changes)
- T005 (GridConfig)
- T006 (GridRenderer skeleton)

**Phase 2 (sequential due to dependencies)**:
- T008-T012 must be sequential (BravenChartPlus → MultiAxisManager)
- T013, T014 can parallel (GridRenderer methods)
- T015-T018 must be sequential (rename AxisRenderer)
- T019-T021 must be sequential (chart_render_box.dart)

**User Story Phases (tests parallel within each story)**:
- Tests within each story can run in parallel
- Implementation follows test completion

---

## Parallel Example: Phase 1 Setup

```bash
# All Phase 1 tasks can run in parallel (different files):
Task T001: CrosshairLabelPosition enum in y_axis_config.dart
Task T005: GridConfig model in grid_config.dart
Task T006: GridRenderer skeleton in grid_renderer.dart
```

---

## Implementation Strategy

### MVP First (User Stories 1-3 Only)

1. Complete Phase 1: Setup (enum, GridConfig, GridRenderer skeleton)
2. Complete Phase 2: Foundational (type change, unified rendering)
3. Complete Phase 3: User Story 1 (default Y-axis)
4. **VALIDATE**: Charts with no config work → Deploy/Demo
5. Complete Phase 4: User Story 2 (modern features)
6. Complete Phase 5: User Story 3 (regression check)
7. **STOP and VALIDATE**: Core unification complete

### Incremental Delivery

1. Phase 1-2: Foundation ready
2. Phase 3 (US1): Default Y-axis works → **MVP!**
3. Phase 4 (US2): Modern features available
4. Phase 5 (US3): Regression verified
5. Phase 6 (US4): Grid independence
6. Phase 7 (US5): Crosshair position control
7. Phase 9-10: Polish and document

---

## Notes

- [P] tasks = different files, no dependencies
- [Story] label maps task to specific user story
- User Story 6 (XAxisConfig) is DEFERRED to future branch
- Constitution requires TDD - tests written before implementation
- Constitution requires 60fps - Phase 9 TextPainter caching is critical
- Run `flutter analyze` after each phase to catch issues early
