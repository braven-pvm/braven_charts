# Feature Specification: Multi-Series Rendering Improvements

**Feature Branch**: `002-multi-series-rendering-fix`  
**Created**: 2026-01-23  
**Status**: Draft  
**Input**: User description: "Multi-series rendering improvements: fix grouped bar charts overlapping and perSeries Y-zoom not working"

## User Scenarios & Testing _(mandatory)_

### User Story 1 - View Multiple Bar Series Side-by-Side (Priority: P1)

A data analyst wants to compare multiple metrics across categories using a bar chart. When displaying bar series for metrics like "Duration" and "Work Done" for each training session, they expect to see bars grouped side-by-side at each X-position so both values are clearly visible and comparable.

**Why this priority**: This is a fundamental charting capability. Without it, multi-series bar charts are unusable—users only see the last-painted series, making data comparison impossible. This blocks core chart functionality.

**Independent Test**: Can be fully tested by creating a chart with 2+ bar series sharing the same X-values and verifying all bars are visible and adjacent.

**Acceptance Scenarios**:

1. **Given** a chart with two BarChartSeries sharing the same X-values, **When** the chart renders, **Then** bars at each X-position appear side-by-side with visible separation between them
2. **Given** a chart with three or more BarChartSeries, **When** the chart renders, **Then** all series bars are visible and grouped together at each X-position
3. **Given** a single BarChartSeries, **When** the chart renders, **Then** bars render centered at each X-position (unchanged from current behavior)
4. **Given** a chart with many bar series (5+), **When** the chart renders, **Then** bars remain visually distinguishable with a minimum readable width

---

### User Story 2 - Zoom Y-Axis with Multi-Axis Charts (Priority: P1)

A data analyst views a chart with multiple Y-axes (e.g., duration on left axis, calories on right axis) using per-series normalization. They want to zoom in vertically to examine a specific data range more closely.

**Why this priority**: Vertical zoom is a core interaction for data exploration. Users expect to zoom into any axis to see detail. When this doesn't work, users cannot properly analyze their data, making the chart less useful than static images.

**Independent Test**: Can be tested by creating a multi-axis chart with perSeries normalization and verifying vertical zoom interaction scales the data display correctly.

**Acceptance Scenarios**:

1. **Given** a chart with multiple Y-axes using perSeries normalization, **When** the user uses mouse wheel to zoom, **Then** both X and Y axes zoom proportionally
2. **Given** a chart with multiple Y-axes, **When** the user drags the Y-scrollbar edge to zoom, **Then** the Y-axis zooms and the visible data range updates accordingly
3. **Given** a zoomed-in view of a multi-axis chart, **When** viewing the Y-axis labels, **Then** the labels reflect the zoomed range (not the full data range)
4. **Given** a multi-axis chart with perSeries normalization, **When** zooming toward a cursor position, **Then** the zoom centers on the cursor location

---

### User Story 3 - Pan Through Zoomed Multi-Axis Charts (Priority: P2)

After zooming into a multi-axis chart, a user wants to pan horizontally and vertically to explore different portions of the data while maintaining the zoom level.

**Why this priority**: Panning completes the zoom+navigate workflow. Without it, users cannot explore the full dataset after zooming. Lower priority than zoom because it's a follow-on action.

**Independent Test**: Can be tested by zooming a multi-axis chart, then panning and verifying the viewport scrolls correctly.

**Acceptance Scenarios**:

1. **Given** a zoomed multi-axis chart, **When** the user drags to pan, **Then** the viewport moves smoothly while data remains correctly scaled
2. **Given** a panned position in a zoomed chart, **When** examining crosshair tooltips, **Then** tooltips show correct data values for the cursor position

---

### Edge Cases

- When bar series have different X-value sets (non-overlapping data), bars render independently at their unique X-positions (centered); grouping only applies where X-values match across series
- Extreme zoom levels are constrained by existing viewport zoom limits in the current implementation
- When the number of bar series would require bars narrower than the 4px minimum, bars will overlap slightly rather than become invisible
- When data changes dynamically after zoom, the viewport should maintain its relative position within the new data bounds

## Requirements _(mandatory)_

### Functional Requirements

- **FR-001**: System MUST render multiple bar series at the same X-position as adjacent (grouped) bars rather than overlapping
- **FR-002**: System MUST calculate appropriate bar widths based on the number of bar series to fit within the available group width
- **FR-003**: System MUST maintain constructor-configurable visual separation (gap) between bars within a group (default: 2 pixels)
- **FR-004**: System MUST support 2-10 bar series without visual degradation or bars becoming unreadable
- **FR-005**: System MUST preserve existing single-bar-series rendering behavior (bars centered at X-position)
- **FR-006**: System MUST apply vertical (Y-axis) zoom correctly when using per-series normalization mode
- **FR-007**: System MUST ensure mouse wheel zoom affects both X and Y axes simultaneously
- **FR-008**: System MUST ensure scrollbar edge drag zoom works independently for each axis (X scrollbar → X zoom, Y scrollbar → Y zoom)
- **FR-009**: System MUST update Y-axis labels to reflect the zoomed data range
- **FR-010**: System MUST maintain zoom center point (zoom toward cursor position)
- **FR-011**: System MUST support vertical zoom with 2 or more Y-axes configured
- **FR-012**: System MUST enforce a minimum bar width (4 pixels) to ensure readability regardless of series count

### Key Entities

- **Bar Group**: A collection of bars at the same X-position from different series, rendered adjacently
- **Axis Bounds**: The visible data range for an axis, which may differ from the full data range when zoomed
- **Viewport**: The current visible portion of the chart, affected by zoom and pan operations

## Success Criteria _(mandatory)_

### Measurable Outcomes

- **SC-001**: Charts with 2-10 bar series display all bars visibly grouped at each X-position with no overlapping
- **SC-002**: Vertical zoom in perSeries mode scales visible data correctly, matching the behavior of non-normalized charts
- **SC-003**: Rendering performance maintains 60fps with 1000+ data points during zoom/pan interactions
- **SC-004**: No regression in existing single-axis or single-series chart functionality
- **SC-005**: Crosshair tooltips display correct data values after zoom operations on multi-axis charts
- **SC-006**: Y-axis labels accurately reflect the current zoomed viewport range

## Assumptions

- Users have existing multi-axis charting infrastructure available (from prior feature work)
- Default bar grouping behavior is automatic when multiple bar series exist
- The minimum bar width of 4 pixels matches existing chart conventions
- All Y-axes zoom proportionally together when vertical zoom is applied
- Existing zoom limits (ViewportConstraints) apply and are not modified by this feature

## Clarifications

### Session 2026-01-23

- Q: When bar series have different (non-overlapping) X-values, should bars still be grouped, or render independently? → A: Group only when X-values match; independent bars render centered at their own X
- Q: Should the system enforce a maximum zoom level to prevent performance degradation? → A: Use existing zoom limits from current implementation
