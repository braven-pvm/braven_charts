# Feature Specification: X-Axis Architecture Unification

**Feature Branch**: `017-x-axis-unification`  
**Created**: 2025-01-14  
**Status**: Draft  
**Prerequisite**: `013-axis-renderer-unification` (COMPLETED)  
**Input**: Unify X-axis architecture to achieve feature parity with the Y-axis rendering system established in Sprint 013

---

## Executive Summary

Sprint 013 successfully unified Y-axis rendering through `MultiAxisPainter` with a rich configuration model (`YAxisConfig`). However, the X-axis remains on a legacy architecture with significant capability gaps. This specification covers the complete architectural unification of X-axis rendering to achieve feature parity with Y-axis, including a new configuration model, dedicated painter, color resolution, and per-series binding support.

---

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Consistent Axis Configuration API (Priority: P1)

**As a** developer creating charts with both X and Y axes,  
**I want** the X-axis to use the same configuration patterns as Y-axis,  
**So that** I can configure both axes using a consistent, intuitive API without learning two different systems.

**Why this priority**: API consistency is the foundation for all other features. Developers expect X and Y axes to be configured identically.

**Independent Test**: Can be fully tested by creating a chart with `XAxisConfig` using the same property names and patterns as `YAxisConfig`, and verifying the axis renders correctly.

**Acceptance Scenarios**:

1. **Given** a chart with `XAxisConfig(position: XAxisPosition.bottom, label: 'Time', unit: 's')`, **When** rendered, **Then** the X-axis displays with the label "Time (s)" in the default position.
2. **Given** a chart with `XAxisConfig(tickLabelPadding: 4.0, axisLabelPadding: 5.0)`, **When** rendered, **Then** the spacing matches the configured values exactly.
3. **Given** a chart with `XAxisConfig(visible: false)`, **When** rendered, **Then** the X-axis is hidden but data scaling still works correctly.
4. **Given** a developer familiar with `YAxisConfig`, **When** they configure `XAxisConfig`, **Then** they can use the same property names and patterns without consulting documentation.

---

### User Story 2 - Unit Suffix Support on X-Axis (Priority: P1)

**As a** developer displaying time-series or measurement data,  
**I want** X-axis tick labels to support unit suffixes like Y-axis does,  
**So that** I can display labels like "10 s", "20 s" or axis titles like "Time (seconds)" without manual formatting.

**Why this priority**: Unit display is essential for scientific and engineering applications. X-axis frequently represents time with units.

**Independent Test**: Can be tested by setting `XAxisConfig(unit: 's', labelDisplay: AxisLabelDisplay.labelAndTickUnit)` and verifying tick labels show "10 s", "20 s" etc.

**Acceptance Scenarios**:

1. **Given** `XAxisConfig(unit: 's', labelDisplay: AxisLabelDisplay.labelWithUnit)`, **When** rendered, **Then** the axis label shows "Time (s)" and tick labels show "10", "20" without units.
2. **Given** `XAxisConfig(unit: 'min', labelDisplay: AxisLabelDisplay.labelAndTickUnit)`, **When** rendered, **Then** tick labels show "1 min", "2 min", "3 min".
3. **Given** `XAxisConfig(unit: 'ms', labelDisplay: AxisLabelDisplay.tickUnitOnly)`, **When** rendered, **Then** no axis title is shown but ticks display "100 ms", "200 ms".
4. **Given** all 7 `AxisLabelDisplay` modes, **When** applied to X-axis, **Then** each mode produces the same label/unit behavior as on Y-axis.

---

### User Story 3 - Series-Derived X-Axis Color (Priority: P2)

**As a** developer creating multi-series charts,  
**I want** X-axis color to optionally derive from series color (like Y-axis does),  
**So that** my charts maintain visual coherence without manually synchronizing colors.

**Why this priority**: Color derivation enhances visual consistency and reduces configuration burden.

**Independent Test**: Can be tested by creating a chart with `XAxisConfig(color: null)` bound to a blue series, and verifying the axis renders in blue.

**Acceptance Scenarios**:

1. **Given** `XAxisConfig(color: null)` with a single bound series of color blue, **When** rendered, **Then** the X-axis line, ticks, and labels are blue.
2. **Given** `XAxisConfig(color: Colors.red)` (explicit color), **When** rendered, **Then** the X-axis uses red regardless of series colors.
3. **Given** `XAxisConfig(color: null)` with no bound series, **When** rendered, **Then** the X-axis uses the default gray color (`Color(0xFF666666)`).
4. **Given** multiple series with different colors, **When** X-axis has no explicit color, **Then** the X-axis uses the color of the first series.

---

### User Story 4 - Crosshair X-Value Label (Priority: P2)

**As a** user interacting with time-series charts,  
**I want** to see the exact X-value (e.g., timestamp) displayed on the X-axis when using the crosshair,  
**So that** I can precisely identify the X-coordinate of any point I'm examining.

**Why this priority**: Crosshair labels significantly improve data exploration UX. Y-axis already has this feature.

**Independent Test**: Can be tested by enabling `XAxisConfig(showCrosshairLabel: true)`, hovering over the chart, and verifying the X-value appears on the axis.

**Acceptance Scenarios**:

1. **Given** `XAxisConfig(showCrosshairLabel: true, crosshairLabelPosition: CrosshairLabelPosition.overAxis)`, **When** user hovers over the chart, **Then** the X-value label appears on the X-axis at the crosshair position.
2. **Given** `XAxisConfig(showCrosshairLabel: true, crosshairLabelPosition: CrosshairLabelPosition.insidePlot)`, **When** user hovers, **Then** the X-value label appears inside the plot area near the X-axis.
3. **Given** `XAxisConfig(showCrosshairLabel: true, unit: 's')`, **When** crosshair is at x=15, **Then** the label shows "15 s" (formatted with unit).
4. **Given** `XAxisConfig(showCrosshairLabel: false)` (default), **When** user hovers, **Then** no X-value label appears on the axis.

---

### User Story 5 - Per-Series X-Axis Configuration (Priority: P3)

**As a** developer creating complex charts with multiple X-axis requirements,  
**I want** to configure X-axis properties per-series (like Y-axis allows),  
**So that** I have flexibility for advanced use cases while maintaining backward compatibility.

**Why this priority**: Enables advanced scenarios while the global configuration remains the default.

**Independent Test**: Can be tested by adding `xAxisConfig` to a series and verifying those settings override the chart-level defaults.

**Acceptance Scenarios**:

1. **Given** a series with inline `xAxisConfig: XAxisConfig(unit: 'ms')`, **When** rendered, **Then** the X-axis reflects that series' configuration.
2. **Given** a chart with global `xAxisConfig` and a series with its own `xAxisConfig`, **When** rendered, **Then** the series-level config takes precedence for that series.
3. **Given** the existing `xAxis: AxisConfig(...)` parameter, **When** developer upgrades, **Then** the old parameter still works (backward compatible).

---

### User Story 6 - Visual Consistency with Y-Axis (Priority: P1)

**As a** developer creating professional charts,  
**I want** X and Y axes to have identical default styling (font size, colors, spacing),  
**So that** my charts look polished and consistent without manual style adjustments.

**Why this priority**: Visual consistency is essential for professional appearance. Current X-axis uses different defaults.

**Independent Test**: Can be tested by rendering a chart with default settings and visually comparing X and Y axis styling.

**Acceptance Scenarios**:

1. **Given** default X and Y axis configurations, **When** rendered, **Then** tick label font size is 11px on both axes.
2. **Given** default configurations, **When** rendered, **Then** both axes use the same default color (`Color(0xFF666666)`).
3. **Given** default configurations, **When** rendered, **Then** tick label padding is 4px on both axes (not 8px on X-axis).
4. **Given** a dark theme with `theme.axisStyle.labelStyle.color` set, **When** rendered, **Then** both X and Y axis labels use `theme.axisStyle.labelStyle.color`; if null, fallback to axis line color; if null, fallback to `Color(0xFFCCCCCC)`.

---

### User Story 7 - Backward Compatibility (Priority: P1)

**As a** developer with existing charts using `AxisConfig`,  
**I want** my existing code to continue working after the upgrade,  
**So that** I can adopt the new features incrementally without breaking changes.

**Why this priority**: Breaking existing code would create adoption barriers and maintenance burden.

**Independent Test**: Can be tested by running existing test suites and example apps without modification.

**Acceptance Scenarios**:

1. **Given** existing code using `BravenChartPlus(xAxis: AxisConfig(...))`, **When** upgraded, **Then** charts render identically (no visual regression).
2. **Given** existing code with no X-axis configuration, **When** upgraded, **Then** default behavior remains unchanged.
3. **Given** all existing unit and widget tests, **When** run after upgrade, **Then** 100% of tests pass without modification.
4. **Given** the example app with existing charts, **When** run after upgrade, **Then** all charts display correctly.

---

### Edge Cases

- **Theme with null colors**: When `theme.axisStyle.labelStyle.color` is null, X-axis falls back to axis line color, then to default gray (`Color(0xFF666666)`)
- **Very long tick labels**: X-axis MUST truncate labels exceeding available width with ellipsis; label rotation is deferred to future sprint
- **Top-positioned X-axis**: Verify spacing and label positioning works correctly for `XAxisPosition.top`
- **No series bound to chart**: X-axis should use default color when no series exists for color derivation
- **Both old and new API used**: When both `xAxis` (old) and `xAxisConfig` (new) are provided, new takes precedence
- **Custom label formatter**: Custom formatters should override unit suffix behavior
- **Zero-width data range**: When min == max on X-axis, sensible tick generation should still work
- **Cache invalidation**: TextPainter cache MUST invalidate when XAxisConfig changes, data range changes, or theme changes
- **No-op paint detection** *(Added post-mortem 2026-01-16)*: Any `paint()` method that does not call `canvas.drawLine()`, `canvas.drawRect()`, or `TextPainter.paint()` is INVALID and MUST fail verification - stub/placeholder implementations are NOT acceptable for renderer tasks

---

## Requirements *(mandatory)*

### Functional Requirements

#### Configuration Model

- **FR-001**: System MUST provide `XAxisConfig` class with properties parallel to `YAxisConfig`
- **FR-002**: System MUST provide `XAxisPosition` enum with `top` and `bottom` values
- **FR-003**: `XAxisConfig` MUST support `unit` property for tick label suffixes
- **FR-004**: `XAxisConfig` MUST support all 7 `AxisLabelDisplay` modes from Y-axis
- **FR-005**: `XAxisConfig` MUST support `color` property that can be null (derive from series) or explicit
- **FR-006**: `XAxisConfig` MUST support structured spacing properties: `tickLabelPadding`, `axisLabelPadding`, `axisMargin`
- **FR-007**: `XAxisConfig` MUST support `visible` property to hide axis while maintaining data scaling
- **FR-008**: `XAxisConfig` MUST support `showCrosshairLabel` and `crosshairLabelPosition` for crosshair value display
- **FR-009**: `XAxisConfig` MUST support `labelFormatter` for custom tick label formatting
- **FR-010**: `XAxisConfig` MUST support `tickCount` for controlling number of tick marks

#### Renderer

- **FR-011**: System MUST provide `XAxisPainter` class following `MultiAxisPainter` architecture
- **FR-011a**: `XAxisPainter.paint()` MUST draw axis line via `canvas.drawLine()` when `showAxisLine` is true *(Added post-mortem 2026-01-16: Explicit canvas draw requirement)*
- **FR-011b**: `XAxisPainter.paint()` MUST draw tick marks via `canvas.drawLine()` when `showTicks` is true *(Added post-mortem 2026-01-16)*
- **FR-011c**: `XAxisPainter.paint()` MUST draw tick labels via `TextPainter.paint()` *(Added post-mortem 2026-01-16)*
- **FR-012**: `XAxisPainter` MUST implement TextPainter caching with automatic invalidation
- **FR-013**: `XAxisPainter` MUST use `AxisColorResolver` for color resolution
- **FR-014**: `XAxisPainter` MUST support unit suffix formatting in tick labels
- **FR-015**: `XAxisPainter` MUST use "nice numbers" algorithm for readable tick values
- **FR-016**: `XAxisPainter` MUST use configuration properties for spacing (no hardcoded offsets)
- **FR-017**: `XAxisPainter` MUST support crosshair value label rendering

#### Pipeline Integration *(Added post-mortem 2026-01-16)*

- **FR-031**: `chart_render_box.dart` MUST use `XAxisPainter` (not legacy `XAxisRenderer`) when `xAxisConfig` is provided
- **FR-032**: Legacy `XAxisRenderer` MUST be marked `@Deprecated` with migration guidance to `XAxisPainter`
- **FR-033**: When `xAxisConfig` is provided, the X-axis MUST be visually rendered using the new painter (not silently ignored)

#### Color Resolution

- **FR-018**: `AxisColorResolver` MUST be extended to support `XAxisConfig` in addition to `YAxisConfig`
- **FR-019**: X-axis color resolution MUST follow same priority: explicit color → first bound series color → default color

#### Per-Series Binding

- **FR-020**: `ChartSeries` MUST support optional `xAxisConfig` property for per-series X-axis configuration
- **FR-021**: `ChartSeries` MUST support optional `xAxisId` property for shared X-axis references

#### Widget Integration

- **FR-022**: `BravenChartPlus` MUST support new `xAxisConfig: XAxisConfig` parameter
- **FR-023**: `BravenChartPlus` MUST maintain backward compatibility with existing `xAxis: AxisConfig` parameter
- **FR-024**: When both `xAxis` and `xAxisConfig` are provided, `xAxisConfig` MUST take precedence

#### Visual Defaults

- **FR-025**: Default tick label font size MUST be 11px (matching Y-axis)
- **FR-026**: Default tick label color MUST be `Color(0xFF666666)` (matching Y-axis)
- **FR-027**: Default tick label padding MUST be 4px (matching Y-axis)
- **FR-028**: Default axis margin MUST be 8px (matching Y-axis)

#### Backward Compatibility

- **FR-029**: Existing `AxisConfig` parameter MUST continue to work without modification
- **FR-030**: All existing tests MUST pass without modification after upgrade

### Key Entities

- **XAxisConfig**: Configuration model for X-axis properties including position, appearance, units, spacing, and behavior. Parallel to `YAxisConfig`.
- **XAxisPosition**: Enum defining valid X-axis positions (`top`, `bottom`).
- **XAxisPainter**: Rendering class responsible for painting X-axis elements (line, ticks, labels, crosshair). Parallel to `MultiAxisPainter`.
- **AxisColorResolver**: Utility for determining effective axis color from configuration or bound series. Extended to support both X and Y axes.

---

## Success Criteria *(mandatory)*

### Measurable Outcomes

| ID | Criterion | Measurement |
|----|-----------|-------------|
| SC-001 | Developers can configure X-axis using same API patterns as Y-axis | API property comparison shows 1:1 mapping for core features |
| SC-002 | X-axis supports all 7 AxisLabelDisplay modes | Unit tests verify correct label/unit behavior for each mode |
| SC-003 | X-axis tick labels can display unit suffixes | Unit test with `unit: 's'` shows "10 s", "20 s" format |
| SC-004 | X-axis derives color from series when not explicitly set | Unit test with null color shows series color on axis |
| SC-005 | Crosshair X-value label displays when enabled | Widget test with hover shows X-value on axis |
| SC-006 | Visual defaults match Y-axis exactly | Comparison shows 11px font, gray color, 4px padding |
| SC-007 | All existing tests pass after upgrade | CI shows 0 test failures, 100% pass rate |
| SC-008 | Example app renders correctly after upgrade | Visual inspection shows no regressions |
| SC-009 | Per-series xAxisConfig overrides chart-level config | Widget test verifies series-level config precedence |
| SC-010 | Backward compatibility with AxisConfig maintained | Existing code using old API renders identically |
| **SC-011** | **X-axis is visually rendered by XAxisPainter** | **Demo app with xAxisConfig shows visible X-axis with line, ticks, labels** *(Added post-mortem 2026-01-16)* |
| **SC-012** | **XAxisPainter replaces XAxisRenderer in pipeline** | **grep for XAxisRenderer in chart_render_box.dart returns 0 matches (excluding comments)** *(Added post-mortem 2026-01-16)* |

### Visual Verification Requirements *(Added post-mortem 2026-01-16)*

The following visual verification is MANDATORY for any renderer implementation:

1. **Demo App Test**: A demo app using the new API MUST be run and produce visible output
2. **Screenshot Comparison**: Before/after screenshots MUST show the new renderer is active
3. **No-Op Detection**: Any `paint()` method containing only comments or no canvas operations MUST fail verification
4. **Pipeline Check**: The render pipeline file MUST be verified to call the new renderer

---

## Assumptions

1. The existing `AxisLabelDisplay` enum and `CrosshairLabelPosition` enum from Y-axis can be reused for X-axis without modification
2. The `AxisColorResolver` pattern is extensible to support both axis types without breaking existing Y-axis behavior
3. The `ChartSeries` abstract class can be extended with optional `xAxisConfig` property without breaking existing implementations
4. Performance requirements remain the same as Y-axis (rendering under 1ms, 60fps with crosshair interaction)
5. Grid rendering remains separate from axis rendering (handled by `GridRenderer`)
6. Multi-X-axis support (topOuter, bottomOuter) is explicitly deferred to a future sprint

---

## Out of Scope

1. **Multi-X-axis support** - Multiple X-axes at different positions (topOuter, bottomOuter) - deferred to future sprint
2. **X-axis normalization** - Normalizing multiple series to a common X-range - not needed for current use cases
3. **X-axis scrollbar unification** - Scrollbar styling is a separate concern
4. **Logarithmic/inverted X-axis** - These features exist in current AxisConfig and will be preserved, not enhanced

