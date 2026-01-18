# Feature Specification: X-Axis Renderer Unification

**Feature Branch**: `018-x-axis-renderer`  
**Created**: 2026-01-17  
**Status**: Draft  
**Input**: Unify X-axis rendering to match Y-axis theming and styling  
**Design Document**: [X_AXIS_RENDERING_UNIFICATION.md](../../docs/design/X_AXIS_RENDERING_UNIFICATION.md)

## User Scenarios & Testing _(mandatory)_

### User Story 1 - Themed X-Axis Rendering (Priority: P1)

As a chart user, I want the X-axis to have the same visual styling as the Y-axis so that my charts look cohesive and professional.

**Why this priority**: This is the core deliverable. Without themed X-axis rendering, the chart appears inconsistent and unprofessional. This addresses the fundamental visual parity problem.

**Independent Test**: Can be fully tested by rendering a chart and verifying the X-axis line, tick marks, and tick labels all share the same themed color derived from the series.

**Acceptance Scenarios**:

1. **Given** a chart with a single series, **When** rendered, **Then** the X-axis line, tick marks, and tick labels use the same color as the first series (matching Y-axis behavior)
2. **Given** a chart with XAxisConfig specifying a custom color, **When** rendered, **Then** the X-axis uses that custom color for all elements
3. **Given** a chart with visible=false in XAxisConfig, **When** rendered, **Then** the X-axis is completely hidden
4. **Given** a chart with showAxisLine=false in XAxisConfig, **When** rendered, **Then** only the axis line is hidden while ticks and labels remain visible

---

### User Story 2 - Themed Crosshair X-Value Label (Priority: P1)

As a chart user, I want the crosshair X-value label to match the Y-axis crosshair label styling so that the hover experience is visually consistent.

**Why this priority**: This is equally critical as it addresses the most visible inconsistency - the jarring white box with "X: 1.8" format that appears on hover.

**Independent Test**: Can be fully tested by hovering over the chart and verifying the X-value label has a semi-transparent themed background and displays only the value (no "X:" prefix).

**Acceptance Scenarios**:

1. **Given** a chart with crosshair enabled, **When** I hover over the chart, **Then** the X-value label displays only the value (e.g., "1.8" not "X: 1.8")
2. **Given** a chart with crosshair enabled, **When** I hover over the chart, **Then** the X-value label has a semi-transparent background tinted with the axis color
3. **Given** a chart with showCrosshairLabel=false in XAxisConfig, **When** I hover over the chart, **Then** no X-value label appears
4. **Given** a chart with a custom labelFormatter in XAxisConfig, **When** I hover over the chart, **Then** the X-value label uses the custom formatter

---

### User Story 3 - X-Axis Configuration API (Priority: P2)

As a developer, I want to configure the X-axis using an XAxisConfig object with the same properties as YAxisConfig so that I have a consistent API for axis customization.

**Why this priority**: While the visual rendering is most important, developers need a proper configuration API to customize the X-axis. This enables the customization use cases.

**Independent Test**: Can be fully tested by creating charts with various XAxisConfig settings and verifying each property affects the rendered output.

**Acceptance Scenarios**:

1. **Given** a BravenChartPlus widget, **When** I pass an xAxisConfig parameter, **Then** the chart accepts and uses the configuration
2. **Given** XAxisConfig with label="Time" and unit="s", **When** rendered, **Then** the axis title displays "Time (s)" centered below the tick labels
3. **Given** XAxisConfig with tickCount=5, **When** rendered, **Then** approximately 5 tick marks are generated using nice numbers
4. **Given** XAxisConfig with min=0 and max=100, **When** rendered, **Then** the X-axis displays that explicit range regardless of data bounds

---

### User Story 4 - Integration with Existing Charts (Priority: P2)

As a developer with existing charts, I want the new X-axis renderer to work without requiring code changes so that my charts automatically benefit from the improved styling.

**Why this priority**: Backward compatibility ensures existing applications improve without migration effort. This is important for adoption but secondary to core functionality.

**Independent Test**: Can be fully tested by running existing chart code without modifications and verifying the X-axis renders correctly with default theming.

**Acceptance Scenarios**:

1. **Given** an existing chart without explicit XAxisConfig, **When** rendered, **Then** the X-axis uses sensible defaults (first series color, visible, ticks shown)
2. **Given** an existing chart using the old AxisConfig for X-axis, **When** rendered, **Then** the chart still works (graceful fallback or automatic conversion)
3. **Given** the new XAxisPainter, **When** integrated, **Then** the old XAxisRenderer is no longer called for rendering

---

### Edge Cases

- What happens when no series are present? X-axis should use theme default color.
- What happens when labelFormatter throws an exception? Fall back to default number formatting.
- What happens when min > max in XAxisConfig? Validation should reject or swap values.
- What happens when tickCount is 0 or 1? Should enforce minimum of 2 ticks.
- What happens when visible=false but showCrosshairLabel=true? Crosshair label should still not appear.

## Requirements _(mandatory)_

### Functional Requirements

- **FR-001**: System MUST render X-axis line with themed color from XAxisConfig or first series color
- **FR-002**: System MUST render X-axis tick marks with the same themed color as the axis line
- **FR-003**: System MUST render X-axis tick labels with the same themed color as the axis line
- **FR-004**: System MUST render X-axis title label horizontally centered below tick labels when label is configured
- **FR-005**: System MUST render crosshair X-value label with semi-transparent themed background (alpha 0.15 of axis color)
- **FR-006**: System MUST render crosshair X-value label with themed border (alpha 0.6 of axis color)
- **FR-007**: System MUST display crosshair X-value as value only (no "X:" prefix)
- **FR-008**: System MUST accept XAxisConfig parameter on the BravenChartPlus widget
- **FR-009**: System MUST pass XAxisConfig from widget through to the rendering components
- **FR-010**: System MUST use XAxisPainter.paint() from ChartRenderBox (not a stub/no-op)
- **FR-011**: System MUST NOT use the legacy XAxisRenderer for X-axis rendering
- **FR-012**: System MUST respect all XAxisConfig properties and reflect them in the rendered output
- **FR-013**: System MUST fall back to ChartTheme defaults when XAxisConfig properties are null
- **FR-014**: System MUST generate nice-number tick values using the same algorithm as Y-axis
- **FR-015**: System MUST cache TextPainters for performance

### Non-Functional Requirements

- **NFR-001**: X-axis rendering performance MUST NOT degrade compared to legacy renderer (paint() completes within 2ms for typical axis)
- **NFR-002**: XAxisConfig API MUST be consistent with YAxisConfig API (similar property names and behavior)
- **NFR-003**: Implementation MUST NOT break existing charts that don't use XAxisConfig
- **NFR-004**: Implementation MUST follow TDD methodology per Constitution Principle I (tests written before implementation)
- **NFR-005**: labelFormatter exception handling MUST fall back to default number formatting gracefully

### Key Entities

- **XAxisConfig**: Configuration object for X-axis appearance and behavior. Contains properties for color, label, unit, visibility, tick formatting, and sizing constraints. Single instance per chart (unlike YAxisConfig which supports multiple).

- **XAxisPainter**: Rendering component responsible for painting the X-axis. Receives XAxisConfig and DataRange, draws axis line, tick marks, tick labels, and axis title using themed colors.

## Success Criteria _(mandatory)_

### Measurable Outcomes

- **SC-001**: X-axis visually matches Y-axis styling when viewed side-by-side (same color, same label box style)
- **SC-002**: Crosshair X-value label shows value-only format (no "X:" prefix)
- **SC-003**: Crosshair X-value label has semi-transparent themed background matching Y-axis label style
- **SC-004**: All 17 XAxisConfig properties affect rendering when set (verified by individual property tests)
- **SC-005**: Existing charts render correctly without code changes (backward compatibility)
- **SC-006**: XAxisPainter.paint() is called from ChartRenderBox (verified by integration test)
- **SC-007**: Legacy XAxisRenderer is not used for rendering (verified by code search showing no active calls)

## Assumptions

- The Y-axis implementation (MultiAxisPainter) is the correct target pattern to follow
- First series color is an acceptable default for X-axis color when not specified
- X-axis will always be positioned at the bottom of the chart (no top position needed)
- Only one X-axis is ever needed (no multi-axis X support required)
- The AxisLabelDisplay enum from YAxisConfig can be reused for XAxisConfig
- The nice-number tick generation algorithm from MultiAxisPainter can be reused
- AxisColorResolver pattern can be reused for X-axis color resolution

## Constraints

- Must not change the Y-axis implementation
- Must maintain backward compatibility with existing chart configurations
- X-axis is single-axis only (no multi-axis support needed)
- Position is fixed at bottom (no configurability needed)
- CrosshairRenderer is `static const` - cannot store XAxisConfig as field (must pass via paint() params)

## Design Decisions (from Gap Analysis 2026-01-18)

### DD-001: No crosshairLabelPosition for XAxisConfig
**Decision**: XAxisConfig does NOT include `crosshairLabelPosition` property.
**Rationale**: 
- X-axis is always at bottom of chart
- Crosshair X-value label always appears below plot area (no inside/outside choice needed)
- YAxisConfig needs this because Y-axes can be left/right with labels inside or outside plot
- Simplifies API without losing functionality

### DD-002: Default color is 0xFF333333 (not theme lookup)
**Decision**: When no color is specified and no series is present, default to `Color(0xFF333333)`.
**Rationale**:
- Matches `AxisColorResolver.defaultAxisColor` constant
- Consistent with existing Y-axis behavior
- No theme lookup needed - simpler implementation

### DD-003: Validation throws AssertionError (not silent swap)
**Decision**: Invalid configurations (min > max, tickCount < 2) throw AssertionError.
**Rationale**:
- Matches YAxisConfig behavior exactly
- Fails fast during development
- Consistent with Flutter's validation patterns

## Dependencies

- Depends on existing MultiAxisPainter implementation as reference
- Depends on existing AxisColorResolver for color resolution pattern
- Depends on existing CrosshairRenderer for crosshair label integration
- Depends on ChartRenderBox for integration point
- Depends on BravenChartPlus widget for API surface
