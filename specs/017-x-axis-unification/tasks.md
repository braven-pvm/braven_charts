# Task Breakdown: X-Axis Architecture Unification

**Feature**: 017-x-axis-unification  
**Generated**: 2025-01-14  
**Spec**: [spec.md](spec.md) | **Plan**: [plan.md](plan.md)

---

## Overview

| Metric | Value |
|--------|-------|
| Total Tasks | 39 |
| Phases | 10 |
| Parallel Opportunities | 12 tasks |
| MVP Scope | Phase 1-5 (US1 + US6 + US7 = consistent API, visual defaults, backward compat) |

### User Story Summary

| Story | Priority | Tasks | Description |
|-------|----------|-------|-------------|
| US1 | P1 | 5 | Consistent Axis Configuration API |
| US2 | P1 | 4 | Unit Suffix Support |
| US6 | P1 | 3 | Visual Consistency with Y-Axis |
| US7 | P1 | 4 | Backward Compatibility |
| US3 | P2 | 4 | Series-Derived X-Axis Color |
| US4 | P2 | 4 | Crosshair X-Value Label |
| US5 | P3 | 4 | Per-Series X-Axis Configuration |
| Setup/Polish | - | 11 | Infrastructure and finalization |

---

## Phase 1: Setup

**Goal**: Establish project structure and foundational files.

### Tasks

- [ ] T001 Create `XAxisPosition` enum in `lib/src/models/x_axis_position.dart`
- [ ] T002 [P] Create test file structure in `test/unit/models/x_axis_config_test.dart`
- [ ] T003 [P] Create test file structure in `test/unit/rendering/x_axis_painter_test.dart`

---

## Phase 2: Foundational (Blocking)

**Goal**: Create core infrastructure that all user stories depend on.

### Tasks

- [ ] T004 Create `XAxisConfig` class skeleton with id and position in `lib/src/models/x_axis_config.dart`
- [ ] T005 Export `XAxisConfig` and `XAxisPosition` from barrel file `lib/braven_charts.dart`
- [ ] T006 Create `XAxisPainter` class skeleton in `lib/src/rendering/x_axis_painter.dart`

---

## Phase 3: US1 - Consistent Axis Configuration API (P1)

**Goal**: Developers can configure X-axis using same API patterns as Y-axis.

**Independent Test**: Create chart with `XAxisConfig` using same property names as `YAxisConfig` and verify axis renders correctly.

### Tasks

- [ ] T007 [US1] Write failing unit tests for `XAxisConfig` property defaults, copyWith, labelFormatter, and tickCount in `test/unit/models/x_axis_config_test.dart`
- [ ] T008 [US1] Add all configuration properties to `XAxisConfig` (label, visible, tickCount, tickLabelPadding, axisLabelPadding, axisMargin, labelFormatter) in `lib/src/models/x_axis_config.dart`
- [ ] T009 [US1] Implement `copyWith` method on `XAxisConfig` in `lib/src/models/x_axis_config.dart`
- [ ] T010 [US1] Write failing unit tests for `XAxisPainter` basic rendering (axis line, ticks, labels, nice numbers) in `test/unit/rendering/x_axis_painter_test.dart`
- [ ] T011 [US1] Implement basic paint method in `XAxisPainter` with nice numbers algorithm (FR-015) in `lib/src/rendering/x_axis_painter.dart`
  - **MANDATORY VERIFICATION** *(Added post-mortem 2026-01-16)*:
    - `paint()` MUST call `canvas.drawLine()` for axis line (pattern: `canvas\.drawLine`)
    - `paint()` MUST call `canvas.drawLine()` for tick marks (min 2 matches for axis + ticks)
    - `paint()` MUST call `textPainter.paint()` or `.paint(canvas` for labels
    - NO-OP REJECTION: If `paint()` contains only comments or no canvas draw calls, task FAILS
- [ ] T011a [US1] Wire `XAxisPainter` into `chart_render_box.dart` to replace `XAxisRenderer` *(Added post-mortem 2026-01-16)*
  - **MANDATORY VERIFICATION**:
    - `chart_render_box.dart` MUST contain `XAxisPainter` (pattern: `XAxisPainter`)
    - `chart_render_box.dart` MUST NOT use `XAxisRenderer` for painting (excluding deprecation comments)

---

## Phase 4: US6 - Visual Consistency with Y-Axis (P1)

**Goal**: X and Y axes have identical default styling (font size, colors, spacing).

**Independent Test**: Render chart with defaults and visually compare X and Y axis styling.

### Tasks

- [ ] T012 [US6] Write failing unit tests for default TextStyle (11px, 0xFF666666) and spacing (4px tick padding, 8px margin) in `test/unit/models/x_axis_config_test.dart`
- [ ] T013 [US6] Add default TextStyle constant and verify spacing defaults in `XAxisConfig` in `lib/src/models/x_axis_config.dart`
- [ ] T014 [US6] Implement TextPainter caching with invalidation on config/data/theme change in `XAxisPainter` in `lib/src/rendering/x_axis_painter.dart`

---

## Phase 5: US7 - Backward Compatibility (P1)

**Goal**: Existing code using `AxisConfig` continues working without modification.

**Independent Test**: Run existing test suites and example apps without modification.

### Tasks

- [ ] T015 [US7] Add `xAxisConfig: XAxisConfig?` parameter to `BravenChartPlus` widget in `lib/src/widgets/braven_chart_plus.dart`
- [ ] T016 [US7] Implement precedence logic (xAxisConfig > xAxis) in `BravenChartPlus` in `lib/src/widgets/braven_chart_plus.dart`
- [ ] T017 [US7] Verify all existing tests pass without modification - run `flutter test`
- [ ] T018 [US7] Update example app to demonstrate both old and new API in `example/lib/main.dart`

---

## Phase 6: US2 - Unit Suffix Support (P1)

**Goal**: X-axis tick labels support unit suffixes like Y-axis does.

**Independent Test**: Set `XAxisConfig(unit: 's', labelDisplay: AxisLabelDisplay.labelAndTickUnit)` and verify tick labels show "10 s", "20 s".

### Tasks

- [ ] T019 [US2] Write failing unit tests for all 7 `AxisLabelDisplay` modes in `test/unit/rendering/x_axis_painter_test.dart`
- [ ] T020 [US2] Add `unit` and `labelDisplay` properties to `XAxisConfig` in `lib/src/models/x_axis_config.dart`
- [ ] T021 [US2] Implement unit suffix formatting in `XAxisPainter._formatTickLabel()` in `lib/src/rendering/x_axis_painter.dart`
- [ ] T022 [US2] Implement all 7 `AxisLabelDisplay` modes in `XAxisPainter` in `lib/src/rendering/x_axis_painter.dart`

---

## Phase 7: US3 - Series-Derived X-Axis Color (P2)

**Goal**: X-axis color optionally derives from series color.

**Independent Test**: Create chart with `XAxisConfig(color: null)` bound to blue series and verify axis renders in blue.

### Tasks

- [ ] T023 [US3] Write failing unit tests for X-axis color resolution (explicit, series-derived, default) in `test/unit/rendering/axis_color_resolver_test.dart`
- [ ] T024 [US3] Add `color` property to `XAxisConfig` in `lib/src/models/x_axis_config.dart`
- [ ] T025 [US3] Extend `SeriesAxisBinding` with optional `xAxisId` field in `lib/src/models/series_axis_binding.dart`
- [ ] T026 [US3] Add `resolveXAxisColor` method to `AxisColorResolver` in `lib/src/rendering/axis_color_resolver.dart`

---

## Phase 8: US4 - Crosshair X-Value Label (P2)

**Goal**: Crosshair shows exact X-value on the X-axis during hover.

**Independent Test**: Enable `XAxisConfig(showCrosshairLabel: true)`, hover over chart, verify X-value appears on axis.

### Tasks

- [ ] T027 [US4] Write failing widget tests for crosshair X-value display in `test/widgets/x_axis_crosshair_test.dart`
- [ ] T028 [US4] Add `showCrosshairLabel` and `crosshairLabelPosition` properties to `XAxisConfig` in `lib/src/models/x_axis_config.dart`
- [ ] T029 [US4] Implement crosshair label rendering in `XAxisPainter.paintCrosshairLabel()` using ValueNotifier (no setState) in `lib/src/rendering/x_axis_painter.dart`
- [ ] T030 [US4] Integrate crosshair label with chart interaction system in `lib/src/widgets/braven_chart_plus.dart`

---

## Phase 9: US5 - Per-Series X-Axis Configuration (P3)

**Goal**: Configure X-axis properties per-series for advanced use cases.

**Independent Test**: Add `xAxisConfig` to a series and verify those settings override chart-level defaults.

### Tasks

- [ ] T031 [US5] Write failing unit tests for per-series config precedence in `test/unit/rendering/x_axis_painter_test.dart`
- [ ] T032 [US5] Add optional `xAxisConfig` and `xAxisId` properties to `ChartSeries` in `lib/src/models/chart_series.dart`
- [ ] T033 [US5] Implement config precedence logic (series > chart-level) in `XAxisPainter` in `lib/src/rendering/x_axis_painter.dart`
- [ ] T034 [US5] Update example app with per-series X-axis demo in `example/lib/main.dart`

---

## Phase 10: Polish & Cross-Cutting

**Goal**: Final cleanup, documentation, and validation.

### Tasks

- [ ] T035 Add comprehensive dartdoc comments to `XAxisConfig` public API in `lib/src/models/x_axis_config.dart`
- [ ] T036 Add comprehensive dartdoc comments to `XAxisPainter` public API in `lib/src/rendering/x_axis_painter.dart`
- [ ] T037 Mark `XAxisRenderer` as deprecated in `lib/src/axis/x_axis_renderer.dart`
- [ ] T038 Run `flutter analyze` and fix all warnings
- [ ] T039 Run full test suite and verify 100% pass rate

---

## Dependencies

```
Phase 1 (Setup)
    │
    ▼
Phase 2 (Foundational) ──────────────────────────────────┐
    │                                                     │
    ├──► Phase 3 (US1: Config API) ──┐                   │
    │                                 │                   │
    ├──► Phase 4 (US6: Visual) ──────┼──► Phase 6 (US2: Units)
    │                                 │         │
    └──► Phase 5 (US7: Backward) ────┘         │
                                               │
                                               ├──► Phase 7 (US3: Color)
                                               │
                                               ├──► Phase 8 (US4: Crosshair)
                                               │
                                               └──► Phase 9 (US5: Per-Series)
                                                          │
                                                          ▼
                                                   Phase 10 (Polish)
```

### Critical Path

1. **MVP (P1 Stories)**: T001-T022 (Phases 1-6)
2. **Enhanced (P2 Stories)**: T023-T030 (Phases 7-8) - can run in parallel
3. **Advanced (P3 Stories)**: T031-T034 (Phase 9)
4. **Finalization**: T035-T039 (Phase 10)

---

## Parallel Execution Examples

### Within Phase 1
```
T001 ──┐
       ├──► All complete → Phase 2
T002 ──┤
T003 ──┘
```

### After Phase 5 (US7)
```
T019 (US2: Units) ──┐
                    ├──► Continue to Phase 7-9
T023 (US3: Color) ──┤
T027 (US4: Cross) ──┘
```

### P2 Stories (Phases 7-8)
```
Phase 7 (US3: Color) ───┬──► Phase 10
Phase 8 (US4: Cross) ───┘
```

---

## Implementation Strategy

### MVP First (Recommended)

**Goal**: Deliver core value with P1 stories before expanding.

1. **Sprint A**: Complete Phases 1-5 (Setup + US1 + US6 + US7)
   - Establishes new architecture
   - Maintains backward compatibility
   - Achieves visual parity

2. **Sprint B**: Complete Phase 6 (US2: Units)
   - Adds key differentiating feature

3. **Sprint C**: Complete Phases 7-9 (US3 + US4 + US5)
   - Advanced features
   - P3 can be deferred if needed

4. **Sprint D**: Complete Phase 10 (Polish)
   - Documentation
   - Final validation

### Incremental Delivery Checkpoints

| Checkpoint | Tasks | Deliverable |
|------------|-------|-------------|
| Alpha | T001-T011a | XAxisConfig + XAxisPainter **fully functional and wired** *(Updated post-mortem)* |
| Beta | T012-T018 | Visual parity + backward compatibility |
| RC1 | T019-T026 | Unit suffixes + color resolution |
| RC2 | T027-T034 | Crosshair + per-series config |
| Release | T035-T039 | Documentation + full validation |

---

## Verification Guidelines *(Added post-mortem 2026-01-16)*

### Renderer Task Verification Requirements

Any task that implements a `paint()` method MUST include these verification checks:

#### Structural Checks (BLOCKING)

```yaml
- description: "Painter calls canvas.drawLine for axis/ticks"
  path: "lib/src/rendering/<painter>.dart"
  pattern: "canvas\\.drawLine"
  min_matches: 2  # axis line + at least one tick

- description: "Painter calls TextPainter.paint for labels"
  path: "lib/src/rendering/<painter>.dart"  
  pattern: "\\.paint\\(canvas|textPainter\\.paint"
  min_matches: 1
```

#### Anti-Pattern Checks (BLOCKING)

```yaml
- description: "paint() is NOT a no-op stub"
  path: "lib/src/rendering/<painter>.dart"
  pattern: "void paint.*\\{[^}]*canvas\\.(draw|paint)"  
  min_matches: 1
  rationale: "Rejects paint() methods that only contain comments"
```

#### Pipeline Wiring Checks (BLOCKING)

```yaml
- description: "New painter is used in render pipeline"
  path: "lib/src/rendering/chart_render_box.dart"
  pattern: "<NewPainter>"
  min_matches: 1

- description: "Old renderer is NOT used (excluding deprecation comments)"
  command: "grep -v '//' chart_render_box.dart | grep '<OldRenderer>(' | wc -l"
  expect_output: "0"
```

### Visual Verification (MANDATORY for UI tasks)

1. Run demo app with new API
2. Capture screenshot
3. Verify visual output matches expected behavior
4. Compare before/after if replacing existing renderer

### Amendment Restrictions

When amending verification criteria:

- **REMOVING a BLOCKING check** requires explicit spec reference showing the check was incorrect
- **"Handover said X"** is NOT valid justification for removing a check
- **Only "Spec says X"** is valid justification
- All amendments removing safety checks must be escalated to human review

---

## Change Log

| Date | Change | Reason |
|------|--------|--------|
| 2025-01-14 | Initial task breakdown | Generated from spec.md and plan.md |
