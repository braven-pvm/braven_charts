# Tasks: X-Axis Renderer Unification

**Feature Branch**: `018-x-axis-renderer`  
**Date**: 2026-01-18  
**Input**: Design documents from `/specs/018-x-axis-renderer/`  
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/

## Format: `[ID] [P?] [Story] Description`
- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3, US4)
- Include exact file paths in descriptions

## Path Conventions
- **Library code**: `lib/src/`
- **Models**: `lib/src/models/`
- **Rendering**: `lib/src/rendering/`
- **Widgets**: `lib/src/widgets/`
- **Example app**: `example/lib/`
- **Tests**: `test/`

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Project initialization and file stubs

- [ ] T001 Create `lib/src/models/x_axis_config.dart` file stub with imports and class declaration
- [ ] T002 [P] Create `lib/src/rendering/x_axis_painter.dart` file stub with imports and class declaration
- [ ] T003 [P] Add `XAxisConfig` export to `lib/braven_charts.dart`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core components that ALL user stories depend on

**⚠️ CRITICAL**: User story implementation cannot begin until these are complete

- [ ] T004 Implement `XAxisConfig` class with all 17 properties in `lib/src/models/x_axis_config.dart`
  - Properties: color, label, unit, min, max, visible, showAxisLine, showTicks, showCrosshairLabel, labelDisplay, minHeight, maxHeight, tickLabelPadding, axisLabelPadding, axisMargin, tickCount, labelFormatter
  - Validation: minHeight >= 0, maxHeight >= minHeight, min < max, tickCount >= 2
  - Computed properties: shouldShowAxisLabel, shouldShowTickLabels, shouldShowTickUnit, shouldAppendUnitToLabel
  - copyWith() method for immutability
  
- [ ] T005 Define `XAxisLabelFormatter` typedef in `lib/src/models/x_axis_config.dart`
  - Signature: `typedef XAxisLabelFormatter = String Function(double value);`

- [ ] T006 Implement `XAxisPainter` core structure in `lib/src/rendering/x_axis_painter.dart`
  - Constructor with required: config, axisBounds, labelStyle; optional: series
  - Stub methods: paint(), generateTicks(), formatTickLabel(), resolveAxisColor()
  - Cache fields: _tickLabelCache, _axisLabelCache, _previousAxisBounds, _previousLabelStyle

**Checkpoint**: Foundation ready - XAxisConfig and XAxisPainter shells exist, ready for rendering logic

---

## Phase 3: User Story 1 - Themed X-Axis Rendering (Priority: P1) 🎯 MVP

**Goal**: X-axis renders with same themed styling as Y-axis (colored axis line, ticks, labels)

**Independent Test**: Render a chart and verify X-axis elements share themed color from series

### Implementation for User Story 1

- [ ] T007 [US1] Implement `resolveAxisColor()` in `lib/src/rendering/x_axis_painter.dart`
  - Priority: config.color → first series color → theme default → Colors.grey
  - Match MultiAxisPainter pattern for consistency

- [ ] T008 [US1] Implement `generateTicks()` in `lib/src/rendering/x_axis_painter.dart`
  - Use nice-number algorithm from MultiAxisPainter
  - Accept bounds and optional maxTicks parameter
  - Return List<double> of human-readable tick values

- [ ] T009 [US1] Implement `formatTickLabel()` in `lib/src/rendering/x_axis_painter.dart`
  - Use config.labelFormatter if provided
  - Append unit if config.shouldShowTickUnit
  - Handle null/empty unit gracefully

- [ ] T010 [US1] Implement `paint()` method in `lib/src/rendering/x_axis_painter.dart`
  - Check config.visible first (early return if false)
  - Call resolveAxisColor() for consistent color
  - Paint axis line if config.showAxisLine
  - Paint tick marks if config.showTicks
  - Paint tick labels for each generated tick
  - Paint axis title if config.shouldShowAxisLabel

- [ ] T011 [US1] Implement TextPainter caching in `lib/src/rendering/x_axis_painter.dart`
  - Cache tick label TextPainters by value
  - Cache axis title TextPainter
  - Invalidate on axisBounds or labelStyle change

- [ ] T012 [US1] Add `xAxisConfig` parameter to `BravenChartPlus` widget in `lib/src/widgets/braven_chart_plus.dart`
  - Parameter type: XAxisConfig?
  - Default: null (uses defaults)
  - Pass to ChartRenderBox

- [ ] T013 [US1] Wire `XAxisPainter` into `ChartRenderBox` in `lib/src/rendering/chart_render_box.dart`
  - Create XAxisPainter instance with config, bounds, series, labelStyle
  - **CRITICAL**: Call _xAxisPainter.paint(canvas, chartArea, plotArea) in paint() method
  - **CRITICAL**: Verify this is NOT a stub - actual painting must occur

- [ ] T014 [US1] Bypass legacy `XAxisRenderer` calls in `ChartRenderBox`
  - Ensure old XAxisRenderer is NOT used for X-axis painting
  - Remove or guard any existing calls to legacy renderer

- [ ] T015 [US1] Create visual verification demo in `example/lib/demos/x_axis_theming_demo.dart`
  - Chart with colored Y-axis and matching X-axis
  - Side-by-side visual comparison
  - Run and screenshot to verify styled rendering

**Checkpoint**: User Story 1 complete - X-axis renders with themed colors matching Y-axis

---

## Phase 4: User Story 2 - Themed Crosshair X-Value Label (Priority: P1)

**Goal**: Crosshair X-value label matches Y-axis label styling (themed background, value-only format)

**Independent Test**: Hover over chart and verify X-label has semi-transparent themed background, displays ""1.8"" not ""X: 1.8""

### Implementation for User Story 2

- [ ] T016 [US2] Modify `CrosshairRenderer` to accept `XAxisConfig` in `lib/src/rendering/modules/crosshair_renderer.dart`
  - Add xAxisConfig parameter to constructor
  - Store for use in X-value label painting

- [ ] T017 [US2] Update X-value label background in `CrosshairRenderer`
  - Use semi-transparent background: axis color with alpha 0.15
  - Add themed border: axis color with alpha 0.6
  - Match Y-axis crosshair label box styling

- [ ] T018 [US2] Update X-value label text format in `CrosshairRenderer`
  - Remove ""X: "" prefix - display value only
  - Use XAxisConfig.labelFormatter if provided
  - Apply axis color to text

- [ ] T019 [US2] Respect `showCrosshairLabel` property in `CrosshairRenderer`
  - If XAxisConfig.showCrosshairLabel == false, skip X-value label entirely
  - Default to true when not configured

- [ ] T020 [US2] Pass `XAxisConfig` from `ChartRenderBox` to `CrosshairRenderer`
  - Update CrosshairRenderer instantiation in ChartRenderBox
  - Ensure config flows through paint pipeline

- [ ] T021 [US2] Update demo to verify crosshair styling in `example/lib/demos/x_axis_theming_demo.dart`
  - Add instructions to hover over chart
  - Verify styled crosshair label appears

**Checkpoint**: User Story 2 complete - Crosshair X-label has themed styling matching Y-label

---

## Phase 5: User Story 3 - X-Axis Configuration API (Priority: P2)

**Goal**: Developers can configure X-axis using XAxisConfig with same properties as YAxisConfig

**Independent Test**: Create charts with various XAxisConfig settings and verify each property affects output

### Implementation for User Story 3

- [ ] T022 [US3] Verify all 17 XAxisConfig properties are implemented and documented in `lib/src/models/x_axis_config.dart`
  - Add dartdoc comments to each property
  - Add usage examples in class-level documentation
  - Ensure copyWith handles all properties

- [ ] T023 [US3] Implement axis title rendering in `XAxisPainter.paint()`
  - Title positioned horizontally centered below tick labels
  - Respect labelDisplay modes (labelOnly, labelWithUnit, etc.)
  - Use config.axisLabelPadding for spacing

- [ ] T024 [US3] Implement explicit min/max bounds in `XAxisPainter`
  - When config.min/max are set, use them instead of data bounds
  - Pass through generateTicks() correctly

- [ ] T025 [US3] Implement tickCount hint in `XAxisPainter.generateTicks()`
  - When config.tickCount is set, generate approximately that many ticks
  - Still use nice-number algorithm for values

- [ ] T026 [US3] Implement height constraints in axis layout
  - Respect config.minHeight and config.maxHeight
  - Integrate with chart layout calculations

- [ ] T027 [US3] Create configuration demo in `example/lib/demos/x_axis_config_demo.dart`
  - Demonstrate each configurable property
  - Include sliders/toggles for interactive testing

**Checkpoint**: User Story 3 complete - Full XAxisConfig API functional and documented

---

## Phase 6: User Story 4 - Integration with Existing Charts (Priority: P2)

**Goal**: Existing charts work without code changes, automatically get themed styling

**Independent Test**: Run existing chart code without modifications, verify X-axis renders correctly

### Implementation for User Story 4

- [ ] T028 [US4] Ensure sensible defaults in `XAxisConfig` and `XAxisPainter`
  - Default color: first series color (not null requiring config)
  - Default visible: true
  - Default showAxisLine, showTicks: true
  - Default labelDisplay: labelWithUnit

- [ ] T029 [US4] Handle missing XAxisConfig gracefully in `ChartRenderBox`
  - When xAxisConfig is null, create default XAxisConfig()
  - Ensure all rendering paths have valid config

- [ ] T030 [US4] Remove or deprecate legacy XAxisRenderer usage paths
  - Search for XAxisRenderer usages in codebase
  - Redirect or remove calls to legacy renderer
  - Add @Deprecated annotation if kept for reference

- [ ] T031 [US4] Run existing demo apps without modifications
  - Run all existing demos in example/lib/
  - Verify no regressions in X-axis rendering
  - Document any breaking changes (should be none)

- [ ] T032 [US4] Update library documentation in `lib/braven_charts.dart` and `README.md`
  - Document XAxisConfig availability
  - Add migration notes (if any)
  - Include basic usage example

**Checkpoint**: User Story 4 complete - Backward compatibility verified, existing charts work

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: Final quality improvements and verification

- [ ] T033 [P] Run `flutter analyze` on all modified files - fix ALL issues
  - lib/src/models/x_axis_config.dart
  - lib/src/rendering/x_axis_painter.dart
  - lib/src/rendering/chart_render_box.dart
  - lib/src/rendering/modules/crosshair_renderer.dart
  - lib/src/widgets/braven_chart_plus.dart

- [ ] T034 [P] Verify integration requirements (CRITICAL - prevents 017 failure mode)
  - Verify XAxisPainter.paint() is called from ChartRenderBox.paint() (grep for call)
  - Verify XAxisPainter.paint() actually draws to canvas (not empty stub)
  - Verify legacy XAxisRenderer is not used for rendering (grep for usages)
  - Verify all XAxisConfig properties affect rendering

- [ ] T035 Run visual verification with screenshot capture
  - Run x_axis_theming_demo.dart
  - Capture screenshot
  - Verify X-axis visually matches Y-axis styling

- [ ] T036 Validate quickstart.md examples work
  - Copy code examples from specs/018-x-axis-renderer/quickstart.md
  - Run in example app
  - Verify all examples compile and render correctly

- [ ] T037 Update CHANGELOG.md with feature summary
  - Add 018-x-axis-renderer entry
  - Document new XAxisConfig class and properties
  - Note backward compatibility maintained

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1 (Setup)**: No dependencies - start immediately
- **Phase 2 (Foundational)**: Depends on Phase 1 - BLOCKS all user stories
- **Phase 3 (US1)**: Depends on Phase 2 - Core themed rendering
- **Phase 4 (US2)**: Depends on Phase 2, optionally US1 for config flow
- **Phase 5 (US3)**: Depends on Phase 2, builds on US1 implementation
- **Phase 6 (US4)**: Depends on Phases 2-5 completion
- **Phase 7 (Polish)**: Depends on all user stories

### User Story Dependencies

- **US1 (Themed Rendering)**: Foundational only - can start first
- **US2 (Crosshair Label)**: Can start after Phase 2, integrates with US1 config flow
- **US3 (Config API)**: Extends US1 implementation, adds more properties
- **US4 (Integration)**: Verification phase, runs after US1-3

### Parallel Opportunities

Setup phase (T001-T003): All can run in parallel
Within US1: T007, T008, T009 can run in parallel (different methods)
Within US2: T016, T017, T018 can run in parallel initially
Polish phase: T033, T034 can run in parallel

---

## Parallel Example: User Story 1 Core Implementation

`bash
# Launch in parallel (different methods, no dependencies):
Task: T007 - Implement resolveAxisColor()
Task: T008 - Implement generateTicks()
Task: T009 - Implement formatTickLabel()

# Then sequentially (depends on above):
Task: T010 - Implement paint() method (uses all above)
`

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup (T001-T003)
2. Complete Phase 2: Foundational (T004-T006)
3. Complete Phase 3: User Story 1 (T007-T015)
4. **STOP and VALIDATE**: Visual verification with screenshot
5. If X-axis renders with themed colors matching Y-axis → MVP complete

### Incremental Delivery

1. Setup + Foundational → XAxisConfig and XAxisPainter exist
2. User Story 1 → Themed X-axis rendering works (MVP!)
3. User Story 2 → Themed crosshair labels work
4. User Story 3 → Full configuration API documented
5. User Story 4 → Backward compatibility verified
6. Polish → All quality gates passed

### Critical Success Verification (MANDATORY)

After Phase 3 (US1) completion, verify:

1. ✅ `grep -r ""_xAxisPainter.paint"" lib/` returns ChartRenderBox call
2. ✅ XAxisPainter.paint() contains actual Canvas drawing code
3. ✅ `grep -r ""XAxisRenderer"" lib/` shows no active rendering calls
4. ✅ Visual screenshot shows colored X-axis matching Y-axis

---

## Notes

- [P] tasks = different files, no dependencies on incomplete tasks
- [Story] label maps task to specific user story for traceability
- CRITICAL: T013 and T014 are the integration tasks that failed in sprint 017
- Verify T013 calls paint() - not just creates the painter
- Verify T014 removes/bypasses legacy renderer
- Commit after each task or logical group
- Stop at any checkpoint to validate independently
