# Tasks: X-Axis Renderer Unification

**Feature Branch**: `018-x-axis-renderer`  
**Date**: 2026-01-18  
**Input**: Design documents from `/specs/018-x-axis-renderer/`  
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/

**TDD Compliance**: This task list follows Test-First Development per Constitution Principle I.
Tests are written FIRST, verified to FAIL, then implementation makes them pass.

**Task Count**: 52 tasks (13 [TEST] tasks, 39 implementation tasks)

---

## 🔧 Gap Remediation Log (2026-01-18)

This task list was updated based on deep-dive analysis against Y-axis implementation.
The following gaps were identified and remediated:

| Gap ID | Severity | Issue | Remediation |
|--------|----------|-------|-------------|
| GAP-001 | 🔴 CRITICAL | CrosshairRenderer.paint() signature missing xAxisConfig | T027 updated to modify paint() params, not constructor |
| GAP-002 | 🔴 CRITICAL | AxisColorResolver not reused | T012, T017 updated to require AxisColorResolver reuse |
| GAP-003 | 🔴 CRITICAL | CrosshairRenderer is const (no state storage) | T027 clarified: add to paint() method, NOT constructor |
| GAP-004 | 🟡 HIGH | Missing _invalidateCachesIfNeeded() pattern | T021 updated with exact cache invalidation pattern |
| GAP-005 | 🟡 HIGH | Computed property logic not documented | T006, T009 updated with exact logic from YAxisConfig |
| GAP-006 | 🟠 MEDIUM | crosshairLabelPosition not in XAxisConfig | DESIGN DECISION: Not needed - X-axis always below plot |
| GAP-007 | 🟠 MEDIUM | _niceNum() algorithm not documented | T018 updated with full algorithm from MultiAxisPainter |
| GAP-008 | 🟠 MEDIUM | Missing crosshair integration test | T026a added for crosshair theming flow verification |
| GAP-010 | 🟢 LOW | Missing operator==/hashCode | T006, T009 updated with equality requirements |
| GAP-011 | 🟢 LOW | Missing toString() | T006, T009 updated with toString() requirement |

### Design Decisions from Gap Analysis

**DD-GAP-006**: XAxisConfig does NOT need `crosshairLabelPosition` property.
- Rationale: X-axis is always at bottom, crosshair label always appears below plot area
- Y-axis needs this because axes can be left/right with labels inside/outside plot
- Simplifies API without losing functionality

---

## 🎯 Critical Patterns to Follow (MANDATORY)

These patterns were extracted from Y-axis implementation and MUST be followed exactly:

### Pattern 1: Color Resolution (from AxisColorResolver)
```dart
// Reference: lib/src/rendering/axis_color_resolver.dart lines 46-80
// Priority: config.color → first series color → defaultAxisColor (0xFF333333)
static const Color defaultAxisColor = Color(0xFF333333);
```

### Pattern 2: Cache Invalidation (from MultiAxisPainter)
```dart
// Reference: lib/src/rendering/multi_axis_painter.dart
void _invalidateCachesIfNeeded() {
  if (_previousAxisBounds != axisBounds || _previousLabelStyle != labelStyle) {
    _tickLabelCache.clear();
    _axisLabelCache = null;
    _previousAxisBounds = axisBounds;
    _previousLabelStyle = labelStyle;
  }
}
```

### Pattern 3: Crosshair Label Theming (from CrosshairRenderer)
```dart
// Reference: lib/src/rendering/modules/crosshair_renderer.dart lines 647-655
final bgColor = axisColor.withValues(alpha: 0.15);  // Semi-transparent background
final borderPaint = Paint()
  ..color = axisColor.withValues(alpha: 0.6)        // Themed border
  ..style = PaintingStyle.stroke
  ..strokeWidth = 1.0;
```

### Pattern 4: Computed Properties (from YAxisConfig)
```dart
// Reference: lib/src/models/y_axis_config.dart lines 571-600
bool get shouldShowAxisLabel => labelDisplay != AxisLabelDisplay.tickUnitOnly &&
    labelDisplay != AxisLabelDisplay.tickOnly && labelDisplay != AxisLabelDisplay.none;
bool get shouldAppendUnitToLabel => labelDisplay == AxisLabelDisplay.labelWithUnit ||
    labelDisplay == AxisLabelDisplay.labelWithUnitAndTickUnit;
bool get shouldShowTickUnit => labelDisplay == AxisLabelDisplay.labelAndTickUnit ||
    labelDisplay == AxisLabelDisplay.labelWithUnitAndTickUnit ||
    labelDisplay == AxisLabelDisplay.tickUnitOnly;
bool get shouldShowTickLabels => labelDisplay != AxisLabelDisplay.none;
```

## Format: `[ID] [P?] [Story] Description`
- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3, US4)
- **[TEST]**: Test task - must be written and fail BEFORE implementation
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

**Purpose**: Project initialization, file stubs, and test infrastructure

- [ ] T001 Create `lib/src/models/x_axis_config.dart` file stub with imports and class declaration
- [ ] T002 [P] Create `lib/src/rendering/x_axis_painter.dart` file stub with imports and class declaration
- [ ] T003 [P] Add `XAxisConfig` export to `lib/braven_charts.dart`
- [ ] T004 [P] Create test file `test/unit/models/x_axis_config_test.dart` with test group structure
- [ ] T005 [P] Create test file `test/unit/rendering/x_axis_painter_test.dart` with test group structure

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core components that ALL user stories depend on

**⚠️ CRITICAL**: User story implementation cannot begin until these are complete
**TDD**: Write tests FIRST (T006-T008), verify they FAIL, then implement (T009-T011)

### Tests for Foundational (Write FIRST - Must FAIL)

- [ ] T006 [TEST] Write unit tests for `XAxisConfig` in `test/unit/models/x_axis_config_test.dart`
  - Test default values for all 17 properties
  - Test validation: minHeight >= 0, maxHeight >= minHeight
  - Test validation: if min and max set, min < max
  - Test validation: if tickCount set, tickCount >= 2
  - Test computed properties with EXACT logic from YAxisConfig:
    - `shouldShowAxisLabel`: true unless labelDisplay is tickUnitOnly, tickOnly, or none
    - `shouldShowTickLabels`: true unless labelDisplay is none
    - `shouldShowTickUnit`: true if labelDisplay is labelAndTickUnit, labelWithUnitAndTickUnit, or tickUnitOnly
    - `shouldAppendUnitToLabel`: true if labelDisplay is labelWithUnit or labelWithUnitAndTickUnit
  - Test copyWith() preserves unchanged values
  - Test operator== and hashCode (compare all 17 properties)
  - Test toString() returns readable debug string
  - Test edge case: min > max should throw AssertionError
  - Test edge case: tickCount = 0 or 1 should throw AssertionError
  - **Reference**: Copy computed property logic from `lib/src/models/y_axis_config.dart` lines 571-600
  - **Run tests - they MUST FAIL (class not implemented)**

- [ ] T007 [TEST] Write unit tests for `XAxisLabelFormatter` typedef in `test/unit/models/x_axis_config_test.dart`
  - Test that formatter function signature matches `String Function(double value)`
  - Test edge case: formatter throws exception → verify behavior documented
  - **Run tests - they MUST FAIL**

- [ ] T008 [TEST] Write unit tests for `XAxisPainter` structure in `test/unit/rendering/x_axis_painter_test.dart`
  - Test constructor accepts required: config, axisBounds, labelStyle; optional: series
  - Test stub methods exist: paint(), generateTicks(), formatTickLabel(), resolveAxisColor()
  - **Run tests - they MUST FAIL (class not implemented)**

### Implementation for Foundational (Make Tests PASS)

- [ ] T009 Implement `XAxisConfig` class with all 17 properties in `lib/src/models/x_axis_config.dart`
  - Properties: color, label, unit, min, max, visible, showAxisLine, showTicks, showCrosshairLabel, labelDisplay, minHeight, maxHeight, tickLabelPadding, axisLabelPadding, axisMargin, tickCount, labelFormatter
  - Validation via asserts (matching YAxisConfig pattern):
    - `assert(minHeight >= 0, 'minHeight must be non-negative')`
    - `assert(maxHeight >= minHeight, 'maxHeight must be >= minHeight')`
    - `assert(min == null || max == null || min < max, 'min must be less than max')`
    - `assert(tickCount == null || tickCount >= 2, 'tickCount must be >= 2')`
  - Computed properties - COPY EXACT LOGIC from `lib/src/models/y_axis_config.dart` lines 571-600:
    ```dart
    bool get shouldShowAxisLabel => labelDisplay != AxisLabelDisplay.tickUnitOnly &&
        labelDisplay != AxisLabelDisplay.tickOnly && labelDisplay != AxisLabelDisplay.none;
    bool get shouldAppendUnitToLabel => labelDisplay == AxisLabelDisplay.labelWithUnit ||
        labelDisplay == AxisLabelDisplay.labelWithUnitAndTickUnit;
    bool get shouldShowTickUnit => labelDisplay == AxisLabelDisplay.labelAndTickUnit ||
        labelDisplay == AxisLabelDisplay.labelWithUnitAndTickUnit ||
        labelDisplay == AxisLabelDisplay.tickUnitOnly;
    bool get shouldShowTickLabels => labelDisplay != AxisLabelDisplay.none;
    ```
  - copyWith() method for immutability (copy pattern from YAxisConfig)
  - operator== comparing all 17 properties (copy pattern from YAxisConfig line 509-532)
  - hashCode using Object.hash() for all 17 properties
  - toString() for debug output
  - **REUSE** `AxisLabelDisplay` enum from y_axis_config.dart (import, don't duplicate)
  - **Run T006 tests - they MUST PASS**
  
- [ ] T010 Define `XAxisLabelFormatter` typedef in `lib/src/models/x_axis_config.dart`
  - Signature: `typedef XAxisLabelFormatter = String Function(double value);`
  - **Run T007 tests - they MUST PASS**

- [ ] T011 Implement `XAxisPainter` core structure in `lib/src/rendering/x_axis_painter.dart`
  - Constructor with required: config, axisBounds, labelStyle; optional: series
  - Stub methods: paint(), generateTicks(), formatTickLabel(), resolveAxisColor()
  - Cache fields: _tickLabelCache, _axisLabelCache, _previousAxisBounds, _previousLabelStyle
  - **Run T008 tests - they MUST PASS**

**Checkpoint**: Foundation ready - XAxisConfig and XAxisPainter shells exist with passing tests

---

## Phase 3: User Story 1 - Themed X-Axis Rendering (Priority: P1) 🎯 MVP

**Goal**: X-axis renders with same themed styling as Y-axis (colored axis line, ticks, labels)

**Independent Test**: Render a chart and verify X-axis elements share themed color from series

### Tests for User Story 1 (Write FIRST - Must FAIL)

- [ ] T012 [TEST] [P] [US1] Write unit tests for `resolveAxisColor()` in `test/unit/rendering/x_axis_painter_test.dart`
  - Test priority: config.color → first series color → defaultAxisColor (0xFF333333)
  - Test matches `AxisColorResolver.resolveAxisColor()` behavior from `lib/src/rendering/axis_color_resolver.dart`
  - Test edge case: no series present → use defaultAxisColor (0xFF333333), not crash
  - Test edge case: series present but series.color is null → use defaultAxisColor
  - **CRITICAL**: Tests should verify XAxisPainter REUSES AxisColorResolver or matches its exact logic
  - **Run tests - they MUST FAIL**

- [ ] T013 [TEST] [P] [US1] Write unit tests for `generateTicks()` in `test/unit/rendering/x_axis_painter_test.dart`
  - Test nice-number algorithm produces human-readable values
  - Test accepts bounds and optional maxTicks parameter
  - Test returns List<double> within bounds
  - **Run tests - they MUST FAIL**

- [ ] T014 [TEST] [P] [US1] Write unit tests for `formatTickLabel()` in `test/unit/rendering/x_axis_painter_test.dart`
  - Test uses config.labelFormatter if provided
  - Test appends unit if config.shouldShowTickUnit
  - Test handles null/empty unit gracefully
  - Test edge case: labelFormatter throws exception → fallback to default formatting
  - **Run tests - they MUST FAIL**

- [ ] T015 [TEST] [US1] Write unit tests for `paint()` method in `test/unit/rendering/x_axis_painter_test.dart`
  - Test early return when config.visible == false
  - Test calls resolveAxisColor() for consistent color
  - Test paints axis line when config.showAxisLine == true
  - Test paints tick marks when config.showTicks == true
  - Test paints tick labels for generated ticks
  - **Run tests - they MUST FAIL**

- [ ] T016 [TEST] [US1] Write integration test for XAxisPainter wiring in `test/widget/x_axis_integration_test.dart`
  - Test XAxisPainter.paint() is called from ChartRenderBox
  - Test legacy XAxisRenderer is NOT called
  - Test visual output matches expected themed colors
  - Reference: see `lib/src/rendering/chart_render_box.dart` paint() method for integration point
  - **Run tests - they MUST FAIL**

### Implementation for User Story 1 (Make Tests PASS)

- [ ] T017 [US1] Implement `resolveAxisColor()` in `lib/src/rendering/x_axis_painter.dart`
  - **REUSE** `AxisColorResolver` from `lib/src/rendering/axis_color_resolver.dart`
  - Option A (preferred): Create static method `AxisColorResolver.resolveXAxisColor()` mirroring Y-axis pattern
  - Option B: Inline same logic but match exactly:
    - Priority: config.color → first series color → defaultAxisColor (0xFF333333)
    - Reference: `AxisColorResolver.resolveAxisColor()` lines 46-80
  - **DO NOT** reinvent color resolution - reuse existing AxisColorResolver pattern
  - Edge case: handle null/empty series list → return defaultAxisColor
  - **Run T012 tests - they MUST PASS**

- [ ] T018 [US1] Implement `generateTicks()` in `lib/src/rendering/x_axis_painter.dart`
  - **COPY** nice-number algorithm from `lib/src/rendering/multi_axis_painter.dart`
  - Key methods to copy:
    - `_niceNum(double range, {bool round = false})` - lines ~280-300
    - `generateTicks(DataRange bounds, {int? maxTicks})` - lines ~250-280
  - Algorithm summary (for reference):
    ```dart
    double _niceNum(double range, {bool round = false}) {
      final exponent = (range > 0 ? log(range) / ln10 : 0).floor();
      final fraction = range / pow(10, exponent);
      double niceFraction;
      if (round) {
        if (fraction < 1.5) niceFraction = 1;
        else if (fraction < 3) niceFraction = 2;
        else if (fraction < 7) niceFraction = 5;
        else niceFraction = 10;
      } else {
        if (fraction <= 1) niceFraction = 1;
        else if (fraction <= 2) niceFraction = 2;
        else if (fraction <= 5) niceFraction = 5;
        else niceFraction = 10;
      }
      return niceFraction * pow(10, exponent);
    }
    ```
  - Accept bounds and optional maxTicks parameter
  - Return List<double> of human-readable tick values within bounds
  - **Run T013 tests - they MUST PASS**

- [ ] T019 [US1] Implement `formatTickLabel()` in `lib/src/rendering/x_axis_painter.dart`
  - Use config.labelFormatter if provided
  - Append unit if config.shouldShowTickUnit
  - Handle null/empty unit gracefully
  - Edge case: wrap labelFormatter call in try-catch, fallback to default on exception
  - **Run T014 tests - they MUST PASS**

- [ ] T020 [US1] Implement `paint()` method in `lib/src/rendering/x_axis_painter.dart`
  - Check config.visible first (early return if false)
  - Call resolveAxisColor() for consistent color
  - Paint axis line if config.showAxisLine
  - Paint tick marks if config.showTicks
  - Paint tick labels for each generated tick
  - Paint axis title if config.shouldShowAxisLabel (basic - advanced in US3)
  - **Run T015 tests - they MUST PASS**

- [ ] T021 [US1] Implement TextPainter caching in `lib/src/rendering/x_axis_painter.dart`
  - Cache tick label TextPainters by value: `Map<double, TextPainter> _tickLabelCache`
  - Cache axis title TextPainter: `TextPainter? _axisLabelCache`
  - Store previous state for change detection:
    - `DataRange? _previousAxisBounds`
    - `TextStyle? _previousLabelStyle`
  - **COPY** `_invalidateCachesIfNeeded()` pattern from `lib/src/rendering/multi_axis_painter.dart`:
    ```dart
    void _invalidateCachesIfNeeded() {
      if (_previousAxisBounds != axisBounds || _previousLabelStyle != labelStyle) {
        _tickLabelCache.clear();
        _axisLabelCache = null;
        _previousAxisBounds = axisBounds;
        _previousLabelStyle = labelStyle;
      }
    }
    ```
  - Call `_invalidateCachesIfNeeded()` at start of paint() method

- [ ] T022 [US1] Add `xAxisConfig` parameter to `BravenChartPlus` widget in `lib/src/widgets/braven_chart_plus.dart`
  - Parameter type: XAxisConfig?
  - Default: null (uses defaults)
  - Pass to ChartRenderBox

- [ ] T023 [US1] Wire `XAxisPainter` into `ChartRenderBox` in `lib/src/rendering/chart_render_box.dart`
  - Reference: see existing paint() method structure around line 200+ for Y-axis painter calls
  - Create XAxisPainter instance with config, bounds, series, labelStyle
  - **CRITICAL**: Call _xAxisPainter.paint(canvas, chartArea, plotArea) in paint() method
  - **CRITICAL**: Verify this is NOT a stub - actual painting must occur
  - **Run T016 tests - they MUST PASS**

- [ ] T024 [US1] Bypass legacy `XAxisRenderer` calls in `ChartRenderBox`
  - Reference: search for `XAxisRenderer` in `lib/src/rendering/chart_render_box.dart`
  - Ensure old XAxisRenderer is NOT used for X-axis painting
  - Remove or guard any existing calls to legacy renderer
  - **Run T016 tests - integration verified**

- [ ] T025 [US1] Create visual verification demo in `example/lib/demos/x_axis_theming_demo.dart`
  - Chart with colored Y-axis and matching X-axis
  - Side-by-side visual comparison
  - Run and screenshot to verify styled rendering

**Checkpoint**: User Story 1 complete - X-axis renders with themed colors matching Y-axis, all tests pass

---

## Phase 4: User Story 2 - Themed Crosshair X-Value Label (Priority: P1)

**Goal**: Crosshair X-value label matches Y-axis label styling (themed background, value-only format)

**Independent Test**: Hover over chart and verify X-label has semi-transparent themed background, displays ""1.8"" not ""X: 1.8""

### Tests for User Story 2 (Write FIRST - Must FAIL)

- [ ] T026 [TEST] [P] [US2] Write unit tests for CrosshairRenderer XAxisConfig support in `test/unit/rendering/crosshair_renderer_test.dart`
  - Test `paint()` method accepts xAxisConfig parameter (NOT constructor - see T027)
  - Test X-value label uses semi-transparent background: `axisColor.withValues(alpha: 0.15)`
  - Test X-value label has themed border: `axisColor.withValues(alpha: 0.6)`
  - Test X-value displays value only (no ""X: "" prefix)
  - Test showCrosshairLabel=false skips X-value label entirely
  - Test labelFormatter is applied to crosshair X-value
  - Test visible=false in XAxisConfig → crosshair label should NOT appear (even if showCrosshairLabel=true)
  - **Reference**: Y-axis crosshair label pattern in `_paintPerAxisCrosshairLabels()` lines 575-670
  - **Run tests - they MUST FAIL**

- [ ] T026a [TEST] [US2] Write integration test for CrosshairRenderer XAxisConfig flow in `test/widget/x_axis_integration_test.dart`
  - Test XAxisConfig is passed from ChartRenderBox to CrosshairRenderer.paint()
  - Test hover over chart shows themed X-value label (not white box)
  - Test XAxisConfig(color: Colors.blue) produces blue-tinted crosshair label
  - **Run tests - they MUST FAIL**

### Implementation for User Story 2 (Make Tests PASS)

- [ ] T027 [US2] Modify `CrosshairRenderer.paint()` signature to accept `XAxisConfig` in `lib/src/rendering/modules/crosshair_renderer.dart`
  - **CRITICAL**: CrosshairRenderer is `static const` in ChartRenderBox (line 346) - CANNOT store state
  - Add `XAxisConfig? xAxisConfig` parameter to `paint()` method signature (line 126-142)
  - **DO NOT** add to constructor - the class is const and stateless
  - Pass xAxisConfig through to `_paintCrosshairLabels()` and `_paintStandardMode()`
  - Current signature to modify:
    ```dart
    void paint({
      required Canvas canvas,
      required Size size,
      required Offset cursorPosition,
      ...
      required bool isRangeCreationMode,
      XAxisConfig? xAxisConfig,  // ← ADD THIS
    })
    ```
  - **Run T026 tests - partial pass**

- [ ] T028 [US2] Update X-value label background in `CrosshairRenderer`
  - Use semi-transparent background: axis color with alpha 0.15
  - Add themed border: axis color with alpha 0.6
  - Match Y-axis crosshair label box styling

- [ ] T029 [US2] Update X-value label text format in `CrosshairRenderer`
  - Remove ""X: "" prefix - display value only
  - Use XAxisConfig.labelFormatter if provided
  - Apply axis color to text
  - **Run T026 tests - they MUST PASS**

- [ ] T030 [US2] Respect `showCrosshairLabel` property in `CrosshairRenderer`
  - If XAxisConfig.showCrosshairLabel == false, skip X-value label entirely
  - Default to true when not configured
  - Edge case: visible=false but showCrosshairLabel=true → crosshair label should NOT appear

- [ ] T031 [US2] Pass `XAxisConfig` from `ChartRenderBox` to `CrosshairRenderer.paint()`
  - **Location**: `lib/src/rendering/chart_render_box.dart` lines 1739-1748
  - Update the existing `_crosshairRenderer.paint()` call to include `xAxisConfig` parameter:
    ```dart
    _crosshairRenderer.paint(
      canvas: canvas,
      size: size,
      cursorPosition: cursorPos,
      ...
      isRangeCreationMode: coordinator.currentMode == InteractionMode.rangeAnnotationCreation,
      xAxisConfig: _xAxisConfig,  // ← ADD THIS
    );
    ```
  - Ensure `_xAxisConfig` field exists on ChartRenderBox (added in T023)
  - **Run T026a tests - they MUST PASS**

- [ ] T032 [US2] Update demo to verify crosshair styling in `example/lib/demos/x_axis_theming_demo.dart`
  - Add instructions to hover over chart
  - Verify styled crosshair label appears

**Checkpoint**: User Story 2 complete - Crosshair X-label has themed styling matching Y-label, all tests pass

---

## Phase 5: User Story 3 - X-Axis Configuration API (Priority: P2)

**Goal**: Developers can configure X-axis using XAxisConfig with same properties as YAxisConfig

**Independent Test**: Create charts with various XAxisConfig settings and verify each property affects output

### Tests for User Story 3 (Write FIRST - Must FAIL)

- [ ] T033 [TEST] [US3] Write property verification tests in `test/unit/rendering/x_axis_painter_test.dart`
  - Test all 17 XAxisConfig properties affect rendering output
  - Test axis title positioning (horizontally centered below ticks)
  - Test labelDisplay modes (labelOnly, labelWithUnit, etc.)
  - Test explicit min/max bounds override data bounds
  - Test tickCount hint produces approximate tick count
  - Test height constraints (minHeight, maxHeight)
  - Verify API parity: compare XAxisConfig properties with YAxisConfig
  - **Run tests - they MUST FAIL**

### Implementation for User Story 3 (Make Tests PASS)

- [ ] T034 [US3] Verify all 17 XAxisConfig properties are implemented and documented in `lib/src/models/x_axis_config.dart`
  - Add dartdoc comments to each property
  - Add usage examples in class-level documentation
  - Ensure copyWith handles all properties
  - Verify API parity with YAxisConfig (reference: `lib/src/models/y_axis_config.dart`)

- [ ] T035 [US3] Implement axis title rendering in `XAxisPainter.paint()`
  - Title positioned horizontally centered below tick labels
  - Respect labelDisplay modes (labelOnly, labelWithUnit, etc.)
  - Use config.axisLabelPadding for spacing
  - Note: Basic title support added in T020, this adds advanced labelDisplay handling

- [ ] T036 [US3] Implement explicit min/max bounds in `XAxisPainter`
  - When config.min/max are set, use them instead of data bounds
  - Pass through generateTicks() correctly

- [ ] T037 [US3] Implement tickCount hint in `XAxisPainter.generateTicks()`
  - When config.tickCount is set, generate approximately that many ticks
  - Still use nice-number algorithm for values

- [ ] T038 [US3] Implement height constraints in axis layout
  - Respect config.minHeight and config.maxHeight
  - Integrate with chart layout calculations
  - **Run T033 tests - they MUST PASS**

- [ ] T039 [US3] Create configuration demo in `example/lib/demos/x_axis_config_demo.dart`
  - Demonstrate each configurable property
  - Include sliders/toggles for interactive testing

**Checkpoint**: User Story 3 complete - Full XAxisConfig API functional and documented, all tests pass

---

## Phase 6: User Story 4 - Integration with Existing Charts (Priority: P2)

**Goal**: Existing charts work without code changes, automatically get themed styling

**Independent Test**: Run existing chart code without modifications, verify X-axis renders correctly

### Tests for User Story 4 (Write FIRST - Must FAIL)

- [ ] T040 [TEST] [US4] Write backward compatibility tests in `test/widget/x_axis_integration_test.dart`
  - Test chart without XAxisConfig uses sensible defaults
  - Test first series color is used when no explicit color
  - Test legacy XAxisRenderer is not called (grep verification)
  - Test existing demos render without errors
  - **Run tests - they MUST FAIL**

### Implementation for User Story 4 (Make Tests PASS)

- [ ] T041 [US4] Ensure sensible defaults in `XAxisConfig` and `XAxisPainter`
  - Default color: first series color (not null requiring config)
  - Default visible: true
  - Default showAxisLine, showTicks: true
  - Default labelDisplay: labelWithUnit

- [ ] T042 [US4] Handle missing XAxisConfig gracefully in `ChartRenderBox`
  - When xAxisConfig is null, create default XAxisConfig()
  - Ensure all rendering paths have valid config
  - **Run T040 tests - partial pass**

- [ ] T043 [US4] Remove or deprecate legacy XAxisRenderer usage paths
  - Search for XAxisRenderer usages in codebase: `grep -r ""XAxisRenderer"" lib/`
  - Redirect or remove calls to legacy renderer
  - Add @Deprecated annotation if kept for reference
  - **Run T040 tests - they MUST PASS**

- [ ] T044 [US4] Run existing demo apps without modifications
  - Run all existing demos in example/lib/
  - Verify no regressions in X-axis rendering
  - Document any breaking changes (should be none)

- [ ] T045 [US4] Update library documentation in `lib/braven_charts.dart` and `README.md`
  - Document XAxisConfig availability
  - Add migration notes (if any)
  - Include basic usage example

**Checkpoint**: User Story 4 complete - Backward compatibility verified, existing charts work, all tests pass

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: Final quality improvements and verification

- [ ] T046 [P] Run `flutter analyze` on all modified files - fix ALL issues
  - lib/src/models/x_axis_config.dart
  - lib/src/rendering/x_axis_painter.dart
  - lib/src/rendering/chart_render_box.dart
  - lib/src/rendering/modules/crosshair_renderer.dart
  - lib/src/widgets/braven_chart_plus.dart

- [ ] T047 [P] Verify integration requirements (CRITICAL - prevents 017 failure mode)
  - Verify XAxisPainter.paint() is called from ChartRenderBox.paint() (grep for call)
  - Verify XAxisPainter.paint() actually draws to canvas (not empty stub)
  - Verify legacy XAxisRenderer is not used for rendering (grep for usages)
  - Verify all XAxisConfig properties affect rendering

- [ ] T048 Run ALL tests and verify 100% pass rate
  - `flutter test test/unit/models/x_axis_config_test.dart`
  - `flutter test test/unit/rendering/x_axis_painter_test.dart`
  - `flutter test test/unit/rendering/crosshair_renderer_test.dart`
  - `flutter test test/widget/x_axis_integration_test.dart`

- [ ] T049 Run visual verification with screenshot capture
  - Run x_axis_theming_demo.dart
  - Capture screenshot
  - Verify X-axis visually matches Y-axis styling

- [ ] T050 Validate quickstart.md examples work
  - Copy code examples from specs/018-x-axis-renderer/quickstart.md
  - Run in example app
  - Verify all examples compile and render correctly

- [ ] T051 Update CHANGELOG.md with feature summary
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

### TDD Cycle Within Each Phase

1. Write [TEST] tasks FIRST
2. Run tests - verify they FAIL (Red)
3. Implement code tasks
4. Run tests - verify they PASS (Green)
5. Refactor if needed (Refactor)
6. Proceed to next phase

### User Story Dependencies

- **US1 (Themed Rendering)**: Foundational only - can start first
- **US2 (Crosshair Label)**: Can start after Phase 2, integrates with US1 config flow
- **US3 (Config API)**: Extends US1 implementation, adds more properties
- **US4 (Integration)**: Verification phase, runs after US1-3

### Parallel Opportunities

Setup phase (T001-T005): All can run in parallel
Within Foundational tests: T006, T007, T008 can run in parallel
Within US1 tests: T012, T013, T014 can run in parallel
Within US1 impl: T017, T018, T019 can run in parallel
Polish phase: T046, T047 can run in parallel

---

## Parallel Example: User Story 1 TDD Cycle

`bash
# Step 1: Write tests in parallel (different test groups):
Task: T012 - Test resolveAxisColor()
Task: T013 - Test generateTicks()
Task: T014 - Test formatTickLabel()

# Step 2: Verify all tests FAIL
flutter test test/unit/rendering/x_axis_painter_test.dart
# Expected: All tests fail (methods not implemented)

# Step 3: Implement in parallel (different methods):
Task: T017 - Implement resolveAxisColor()
Task: T018 - Implement generateTicks()
Task: T019 - Implement formatTickLabel()

# Step 4: Verify tests PASS
flutter test test/unit/rendering/x_axis_painter_test.dart
# Expected: All tests pass
`

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup (T001-T005)
2. Complete Phase 2: Foundational with TDD (T006-T011)
3. Complete Phase 3: User Story 1 with TDD (T012-T025)
4. **STOP and VALIDATE**: All tests pass + visual verification
5. If X-axis renders with themed colors matching Y-axis → MVP complete

### Incremental Delivery

1. Setup + Foundational → XAxisConfig and XAxisPainter exist, tests pass
2. User Story 1 → Themed X-axis rendering works (MVP!), tests pass
3. User Story 2 → Themed crosshair labels work, tests pass
4. User Story 3 → Full configuration API documented, tests pass
5. User Story 4 → Backward compatibility verified, tests pass
6. Polish → All quality gates passed, 100% test coverage

### Critical Success Verification (MANDATORY)

After Phase 3 (US1) completion, verify:

1. ✅ All T012-T016 tests PASS
2. ✅ `grep -r ""_xAxisPainter.paint"" lib/` returns ChartRenderBox call
3. ✅ XAxisPainter.paint() contains actual Canvas drawing code
4. ✅ `grep -r ""XAxisRenderer"" lib/` shows no active rendering calls
5. ✅ Visual screenshot shows colored X-axis matching Y-axis

---

## Edge Cases Covered

| Edge Case | Covered In | Implementation |
|-----------|------------|----------------|
| No series present | T012, T017 | Use defaultAxisColor (0xFF333333) |
| Series with null color | T012, T017 | Use defaultAxisColor (0xFF333333) |
| labelFormatter throws | T014, T019 | Try-catch, fallback to default formatting |
| min > max | T006, T009 | AssertionError thrown (matching YAxisConfig) |
| tickCount < 2 | T006, T009 | AssertionError thrown (matching YAxisConfig) |
| visible=false + showCrosshairLabel=true | T026, T030 | Crosshair label hidden |
| Empty axisBounds (min == max) | T013, T018 | Generate single tick at value |
| Cache invalidation on style change | T021 | _invalidateCachesIfNeeded() pattern |

---

## Notes

- [P] tasks = different files, no dependencies on incomplete tasks
- [TEST] tasks = TDD tests, MUST be written and FAIL before implementation
- [Story] label maps task to specific user story for traceability
- CRITICAL: T023 and T024 are the integration tasks that failed in sprint 017
- Verify T023 calls paint() - not just creates the painter
- Verify T024 removes/bypasses legacy renderer
- TDD RED-GREEN-REFACTOR cycle is mandatory per Constitution Principle I
- Commit after each task or logical group
- Stop at any checkpoint to validate independently
