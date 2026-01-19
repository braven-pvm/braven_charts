# Feature Specification: Axis Renderer Unification

**Feature Branch**: `013-axis-renderer-unification`  
**Created**: 2025-12-10  
**Status**: Draft  
**Input**: User description: "Refactor: Unify axis renderer - consolidate two parallel Y-axis rendering paths (AxisRenderer and MultiAxisPainter) into a single consistent system using MultiAxisPainter as the unified Y-axis renderer"

**Technical Specification Reference**: `docs/architecture/specs/axis_renderer_unification_spec.md`

---

## Problem Statement

The current codebase has **two parallel Y-axis rendering paths** with inconsistent behavior:

1. **`AxisRenderer`** (legacy) - Used for single-axis mode via `BravenChartPlus.yAxis` with `AxisConfig`
2. **`MultiAxisPainter`** (modern) - Used for multi-axis mode via `ChartSeries.yAxisConfig` with `YAxisConfig`

This causes:
- Inconsistent feature availability (unit support, crosshair labels, flexible positioning only in multi-axis mode)
- Hardcoded margins (left margin = 60) ignoring axis position
- Dual conversion chains (`AxisConfig` → `InternalAxisConfig` → `Axis` → render)
- Code duplication in tick generation and label rendering

---

## Assumptions

- This is a **breaking change** - users using `AxisConfig` for Y-axis will need to migrate to `YAxisConfig`
- The existing `MultiAxisPainter` is battle-tested and can handle single-axis cases seamlessly
- Grid rendering should be a separate concern from axis rendering (separation of concerns)
- TextPainter caching can be added to `MultiAxisPainter` to maintain performance parity
- X-axis will follow the same pattern with `XAxisConfig` for API consistency

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Simple Chart with Default Y-Axis (Priority: P1)

As a developer, I want to create a simple chart without specifying any Y-axis configuration, and have the chart automatically create a sensible default Y-axis on the left side.

**Why this priority**: This is the most common use case - developers just want a chart to "just work" without configuring axes. This ensures backward compatibility and ease of use.

**Independent Test**: Can be tested by creating a `BravenChartPlus` with only series data and verifying a Y-axis appears on the left with auto-scaled range.

**Acceptance Scenarios**:

1. **Given** a chart with series data but no Y-axis configuration, **When** the chart renders, **Then** a Y-axis appears on the left side with auto-scaled range based on series data.
2. **Given** a chart with series data but no Y-axis configuration, **When** series data changes, **Then** the Y-axis range auto-scales to fit the new data.

---

### User Story 2 - Customized Single Y-Axis with Modern Features (Priority: P1)

As a developer, I want to configure a single Y-axis using `YAxisConfig` with modern features like units, crosshair labels, and flexible positioning that were previously only available in multi-axis mode.

**Why this priority**: This addresses the core problem - feature parity between single-axis and multi-axis modes. Developers should get the same capabilities regardless of how many axes they use.

**Independent Test**: Can be tested by creating a `BravenChartPlus` with `yAxis: YAxisConfig(position: YAxisPosition.right, unit: 'W', showCrosshairLabel: true)` and verifying all features work.

**Acceptance Scenarios**:

1. **Given** a chart with `yAxis: YAxisConfig(position: YAxisPosition.right)`, **When** the chart renders, **Then** the Y-axis appears on the right side (not hardcoded left).
2. **Given** a chart with `yAxis: YAxisConfig(unit: 'kW')`, **When** viewing tick labels, **Then** the unit is displayed according to `labelDisplay` setting.
3. **Given** a chart with `yAxis: YAxisConfig(showCrosshairLabel: true)`, **When** crosshair is active, **Then** a Y-value label appears for this axis.

---

### User Story 3 - Multi-Axis Chart Unchanged Behavior (Priority: P1)

As a developer using multi-axis mode via `ChartSeries.yAxisConfig`, I want my existing charts to continue working identically after this refactor.

**Why this priority**: Existing functionality must not regress. Multi-axis mode is already using the target system (`MultiAxisPainter`), so it should be unaffected.

**Independent Test**: Can be tested by running existing multi-axis demos/tests and verifying identical visual output and behavior.

**Acceptance Scenarios**:

1. **Given** an existing multi-axis chart with series-defined `yAxisConfig`, **When** the refactored code runs, **Then** the visual output is identical to before.
2. **Given** a chart with multiple Y-axes on left and right positions, **When** rendered, **Then** axis layout, tick positions, and labels are unchanged.

---

### User Story 4 - Grid Rendering Independence (Priority: P2)

As a developer, I want grid lines to be controlled independently from axis configuration via a chart-level `GridConfig`, so I can show/hide grids regardless of axis setup.

**Why this priority**: Grid rendering is being extracted to a separate `GridRenderer` class. This enables cleaner architecture and fixes the issue where multi-axis mode disables Y-grid lines.

**Independent Test**: Can be tested by creating a chart with `grid: GridConfig(horizontal: true, vertical: false)` and verifying only horizontal grid lines appear.

**Acceptance Scenarios**:

1. **Given** a chart with `grid: GridConfig(horizontal: true)`, **When** rendered, **Then** horizontal grid lines appear at Y-axis tick positions.
2. **Given** a chart with `grid: GridConfig(vertical: true)`, **When** rendered, **Then** vertical grid lines appear at X-axis tick positions.
3. **Given** a multi-axis chart with multiple Y-axes at different scales, **When** `grid: GridConfig(horizontal: true)`, **Then** horizontal grid lines use the primary Y-axis tick positions.

---

### User Story 5 - Crosshair Label Position Control (Priority: P2)

As a developer, I want to control where crosshair Y-value labels appear (over the axis strip or inside the plot area) for each axis independently.

**Why this priority**: Adds fine-grained control over crosshair appearance. Important for charts where axis strips are narrow or when the default position obscures data.

**Independent Test**: Can be tested by creating a chart with `yAxis: YAxisConfig(showCrosshairLabel: true, crosshairLabelPosition: CrosshairLabelPosition.insidePlot)` and verifying label position.

**Acceptance Scenarios**:

1. **Given** a Y-axis with `crosshairLabelPosition: CrosshairLabelPosition.overAxis`, **When** crosshair is active, **Then** the Y-value label appears in the axis strip area (outside plot).
2. **Given** a Y-axis with `crosshairLabelPosition: CrosshairLabelPosition.insidePlot`, **When** crosshair is active, **Then** the Y-value label appears inside the plot area near the axis edge.

---

### User Story 6 - X-Axis API Consistency (Priority: P3)

As a developer, I want the X-axis configuration API (`XAxisConfig`) to be consistent with Y-axis configuration (`YAxisConfig`) in property naming and capabilities.

**Why this priority**: API consistency improves developer experience. Both axis types should use the same property names (`color` not `axisColor`) and support the same features (units).

**Independent Test**: Can be tested by creating a chart with `xAxis: XAxisConfig(position: XAxisPosition.bottom, unit: 'sec', color: Colors.blue)` and verifying all properties work.

**Acceptance Scenarios**:

1. **Given** a chart with `xAxis: XAxisConfig(position: XAxisPosition.top)`, **When** rendered, **Then** the X-axis appears at the top.
2. **Given** a chart with `xAxis: XAxisConfig(unit: 'ms')`, **When** viewing tick labels, **Then** the unit is displayed appropriately.
3. **Given** `XAxisConfig` properties, **When** compared to `YAxisConfig`, **Then** equivalent properties use the same names (`color`, `unit`, `label`, etc.).

---

### Edge Cases

- **Empty series data**: When no data points exist, axes should still render with reasonable defaults (0-100 range) or be hidden gracefully.
- **Single data point**: Axis range should expand to show meaningful context around the single point.
- **Extreme values**: Very large/small numbers should render with appropriate tick formatting (scientific notation, abbreviated units).
- **Axis with zero range**: When min == max, the system should expand the range to avoid division by zero.
- **Null YAxisConfig**: When `yAxis` is explicitly set to `null`, the auto-created default should still appear (per design decision Q6).
- **Conflicting positions**: If both `yAxis` and series `yAxisConfig` specify the same position, they should stack correctly using `leftOuter`/`rightOuter` positions.

## Requirements *(mandatory)*

### Functional Requirements

#### Phase 1: CrosshairLabelPosition Enum
- **FR-001**: System MUST provide a `CrosshairLabelPosition` enum with values `overAxis` and `insidePlot`
- **FR-002**: `YAxisConfig` MUST include a `crosshairLabelPosition` property defaulting to `overAxis`
- **FR-003**: Crosshair renderer MUST position Y-value labels according to the axis's `crosshairLabelPosition` setting

#### Phase 2: YAxisConfig as Primary Y-Axis Type
- **FR-004**: `BravenChartPlus.yAxis` property MUST accept `YAxisConfig?` instead of `AxisConfig?`
- **FR-005**: When `yAxis` is not provided and no series has `yAxisConfig`, system MUST auto-create a default Y-axis with `position: YAxisPosition.left`
- **FR-006**: `YAxisConfig.position` MUST default to `YAxisPosition.left` when not specified
- **FR-007**: System MUST NOT require users to specify `id` on `YAxisConfig` - IDs are auto-generated internally

#### Phase 3: Grid Extraction & Rendering Unification
- **FR-008**: System MUST provide a dedicated `GridRenderer` class for rendering grid lines
- **FR-009**: Grid rendering MUST be controlled via chart-level `GridConfig`, not per-axis settings
- **FR-010**: `GridConfig` MUST support independent control of horizontal and vertical grid lines
- **FR-011**: System MUST use `MultiAxisPainter` as the single rendering path for ALL Y-axes (single or multi)
- **FR-012**: `AxisRenderer` MUST be renamed to `XAxisRenderer` and handle only X-axis rendering
- **FR-013**: `XAxisRenderer` MUST NOT render grid lines (grid is separate concern)

#### Phase 4: Performance & Cleanup
- **FR-014**: `MultiAxisPainter` MUST cache `TextPainter` objects to maintain performance parity with legacy system
- **FR-015**: System MUST remove unused Y-axis code from `InternalAxisConfig` and related legacy paths

#### Phase 5: X-Axis Consistency (Future)
- **FR-016**: System MUST provide `XAxisConfig` with consistent property names matching `YAxisConfig`
- **FR-017**: `XAxisConfig.position` MUST use `XAxisPosition` enum (`top`, `bottom`) for type safety

### Key Entities

- **YAxisConfig**: Configuration for Y-axis appearance and behavior (position, range, unit, label display, crosshair settings). IDs are auto-generated internally.
- **XAxisConfig**: Configuration for X-axis appearance and behavior (position, range, unit, label display). Mirrors `YAxisConfig` property names.
- **GridConfig**: Chart-level configuration for grid line visibility and styling. Controls horizontal (Y-tick positions) and vertical (X-tick positions) grid lines independently.
- **CrosshairLabelPosition**: Enum controlling where crosshair Y-value labels appear (`overAxis` or `insidePlot`).
- **GridRenderer**: Dedicated renderer for chart grid lines. Receives tick positions from axis systems, paints before data series.
- **XAxisRenderer**: Renamed from `AxisRenderer`. Handles only X-axis line, ticks, and labels. No grid rendering.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: All existing multi-axis tests pass without modification (zero regression)
- **SC-002**: Single-axis charts using `YAxisConfig` render identically to equivalent multi-axis single-axis charts
- **SC-003**: Developers can configure Y-axis position (left/right/leftOuter/rightOuter) in single-axis mode and see correct rendering
- **SC-004**: Developers can use unit display and crosshair labels in single-axis mode without workarounds
- **SC-005**: Grid lines render correctly at tick positions regardless of single/multi axis mode
- **SC-006**: Chart frame rate remains at 60fps during crosshair interaction (no performance regression from TextPainter caching removal)
- **SC-007**: API surface is reduced by consolidating `AxisConfig` Y-axis usage into `YAxisConfig`
- **SC-008**: All acceptance scenarios from user stories pass automated testing

---

## Resolved Design Decisions

*These decisions were made during spec analysis and are documented in the technical spec.*

| Question | Decision | Rationale |
|----------|----------|-----------|
| Breaking Change Strategy | Clean break (no deprecation) | Simplifies implementation, matches major version bump expectations |
| Default ID | Remove from public API | IDs auto-generated as `${series.id}_axis` internally |
| Default Position | `YAxisPosition.left` | Most common use case, matches industry conventions |
| Grid Ownership | Separate `GridConfig` at chart level | Multi-axis mode already disables Y-grid; grid is independent concern |
| X-Axis Unification | Create `XAxisConfig` for consistency | Same property names, type-safe positions |
| Default Y-Axis Behavior | Auto-create when none provided | Maintains backward compatibility |

---

## Out of Scope

- Theming system changes (grid styling uses existing theme)
- Data series rendering changes
- Annotation system changes
- Tooltip system changes (other than crosshair label positioning)