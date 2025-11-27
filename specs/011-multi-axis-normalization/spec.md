# Feature Specification: Multi-Axis Normalization

**Feature Branch**: `011-multi-axis-normalization`  
**Created**: 2025-11-27  
**Status**: Draft  
**Input**: User description: "Multi-axis normalization for displaying multiple data series with vastly different Y-axis ranges on the same chart, with color-coded axes showing original values"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Multi-Scale Data Visualization (Priority: P1)

A sports scientist needs to display power output, heart rate, and respiratory metrics on a single chart during an athletic performance review. Currently, when metrics like Power (0-300W), Tidal Volume (0.5-4.0L), and Respiratory Rate (10-40 bpm) are plotted together, the smaller-range series appear as flat lines near the bottom, making the data unreadable.

With multi-axis normalization, each series uses the full vertical height of the chart while displaying its own properly-scaled Y-axis. The scientist can now correlate all physiological responses in a single view.

**Why this priority**: This is the core value proposition. Without proper visualization of multi-scale data, the chart is unusable for its primary purpose. This delivers immediate, high-impact user value.

**Independent Test**: Can be fully tested by creating a chart with 2+ series having >10x range difference and verifying all series are visible and distinguishable using full vertical space.

**Acceptance Scenarios**:

1. **Given** a chart with two series (Power: 0-300W, Tidal Volume: 0.5-4.0L), **When** the chart renders, **Then** both series span the full vertical height of the plot area
2. **Given** a chart with four series with vastly different ranges, **When** the chart renders, **Then** each series has its own color-coded Y-axis displaying original values
3. **Given** a multi-axis chart, **When** the user hovers over any data point, **Then** the tooltip displays the original Y-value (not a normalized percentage)

---

### User Story 2 - Automatic Normalization Detection (Priority: P2)

A developer integrating the chart library wants the system to automatically detect when multiple series need separate axes without manual configuration. When the developer adds series with significantly different Y-ranges (e.g., 10x or more difference), the chart should automatically enable multi-axis mode.

**Why this priority**: Reduces developer friction and makes the feature work "out of the box" for common cases. Depends on P1 being functional first.

**Independent Test**: Can be tested by creating a chart with series whose ranges differ by >10x and verifying multi-axis mode activates automatically without explicit configuration.

**Acceptance Scenarios**:

1. **Given** a chart with series A (range 0-10) and series B (range 0-1000), **When** no explicit axis configuration is provided, **Then** the chart automatically enables multi-axis mode
2. **Given** a chart with series having similar ranges (within 10x), **When** no explicit configuration is provided, **Then** the chart uses single-axis mode (current behavior)
3. **Given** auto-detection is enabled, **When** the developer provides explicit axis configuration, **Then** the explicit configuration takes precedence

---

### User Story 3 - Color-Coded Axis Identification (Priority: P2)

A user viewing a multi-axis chart with 4 different series needs to quickly identify which Y-axis corresponds to which data line. Each Y-axis should match the color of its associated series, providing an immediate visual connection.

**Why this priority**: Essential for usability of multi-axis charts. Without clear visual association, users cannot interpret the data correctly. Equal priority with P2 as both enhance core functionality.

**Independent Test**: Can be tested by verifying that each Y-axis (labels, ticks, axis line) uses the same color as its bound series.

**Acceptance Scenarios**:

1. **Given** a chart with a blue Power series bound to the left axis, **When** the chart renders, **Then** the left Y-axis labels and ticks are displayed in blue
2. **Given** a chart with multiple color-coded axes, **When** viewed in dark mode, **Then** axis colors remain distinguishable and match their series
3. **Given** multiple series share the same axis, **When** the chart renders, **Then** the axis uses a neutral color or the first series' color

---

### User Story 4 - Original Value Display in Crosshair (Priority: P3)

A user analyzing data with the crosshair/tracking feature wants to see the actual data values for each series at the current position, not normalized percentages. The crosshair tooltip should display formatted original values with appropriate units.

**Why this priority**: Important for detailed data analysis but depends on core rendering (P1) and axis display (P2) working first.

**Independent Test**: Can be tested by enabling crosshair mode, moving over data points, and verifying displayed values match the original data values with correct formatting.

**Acceptance Scenarios**:

1. **Given** a multi-axis chart with crosshair enabled, **When** the user hovers at X position where Power=240W and HeartRate=165bpm, **Then** the tooltip shows "Power: 240 W" and "Heart Rate: 165 bpm"
2. **Given** tracking mode is enabled, **When** the user moves along the chart, **Then** all intersected series display their original Y-values
3. **Given** a series with decimal values (Tidal Volume: 2.3L), **When** displayed in crosshair, **Then** the value is formatted appropriately (not truncated or over-precise)

---

### Edge Cases

- What happens when all series have identical or very similar ranges?
  - Single-axis mode should be used (no normalization needed)
- What happens when a series has zero range (all Y values identical)?
  - Series should render as a horizontal line at the configured position
- What happens when a series has only one data point?
  - Single point should render using reasonable default bounds
- How does the system handle mixed configured and unconfigured axes?
  - Unconfigured series use the primary (left) axis by default
- What happens when more than 4 axes are requested?
  - System should use a maximum of 4 axes; additional series share existing axes
- How are threshold annotations displayed across multiple axes?
  - Thresholds specify which axis they apply to, or display values for all axes at that Y-position
  - **Future Scope**: Threshold annotation axis binding is deferred to a separate enhancement
- **How does zoom/pan interact with multi-axis normalization?**
  - **X-axis zoom/pan**: Works normally, scrolls through time/horizontal data
  - **Y-axis zoom**: DISABLED in multi-axis mode - each axis always shows full range
  - **Rationale**: Independent Y-zoom per axis is confusing UX; normalized series should always use full vertical space

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST support up to 4 Y-axes positioned as: leftOuter, left, right, rightOuter
- **FR-002**: Each data series MUST be bindable to a specific Y-axis by identifier
- **FR-003**: Each Y-axis MUST maintain its own data bounds (min/max), either auto-computed from bound series or explicitly configured
- **FR-004**: System MUST internally normalize each series to the full plot height while preserving original values for all display purposes
- **FR-005**: All Y-axis labels and ticks MUST display original data values (not normalized values)
- **FR-006**: Tooltips and crosshair displays MUST show original data values for each series
- **FR-007**: Each Y-axis MUST support color-coding to match its bound series
- **FR-008**: System MUST support automatic multi-axis detection when series Y-ranges differ by more than a configurable threshold (default: 10x)
- **FR-009**: Grid lines MUST be disabled when multi-axis normalization is active (to avoid confusion with multiple scales)
- **FR-010**: Multiple series MUST be able to share the same Y-axis when they have compatible ranges or units
- **FR-011**: Series without explicit axis binding MUST default to the primary (left) Y-axis for backward compatibility
- **FR-012**: Y-axis labels MUST support optional unit suffixes (e.g., "W", "bpm", "L/min")
- **FR-013**: When multi-axis mode is active, Y-axis zoom MUST be disabled (X-axis zoom/pan remains functional)
- **FR-014**: Crosshair Y-coordinate calculations MUST use per-axis bounds to convert screen position to original data values

### Key Entities

- **Y-Axis Configuration**: Defines a single Y-axis with unique identifier, position (left/right variants), color, label text, unit suffix, and optional explicit min/max bounds
- **Series-Axis Binding**: Associates a data series with a specific Y-axis configuration by identifier
- **Normalization Mode**: Controls whether normalization is disabled, automatic based on range detection, or always active

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Charts with 4 series (1000+ points each) across 4 Y-axes render at 60 frames per second without visible lag or stutter
- **SC-002**: 100% of series in a multi-axis chart visually span at least 80% of the available vertical plot height (no "flat line" effect)
- **SC-003**: Users can correctly identify which Y-axis corresponds to which series within 2 seconds of viewing the chart (via color-coding)
- **SC-004**: All displayed Y-values (axes, tooltips, crosshair, legend) exactly match the original data values with no visible rounding errors
- **SC-005**: Existing single-axis charts (one series, or similar-range series) continue to work identically with zero configuration changes required

