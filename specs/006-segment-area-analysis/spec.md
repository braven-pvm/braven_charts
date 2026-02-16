# Feature Specification: Segment & Area Data Analysis

**Feature Branch**: `006-segment-area-analysis`  
**Created**: 2026-02-14  
**Status**: Draft  
**Input**: User description: "Create new spec based on specs/\_base/006-segment-area-analysis/spec.md — make underlying data in chart segments and range annotations queryable and summarizable"

## User Scenarios & Testing _(mandatory)_

### User Story 1 - Query Data Within a Range Annotation (Priority: P1)

A sports analytics developer has a chart showing heart rate, power, and oxygen data over time. They have placed vertical range annotations marking physiological zones (e.g., "VT1 Zone", "Sprint 3"). When their user taps one of these annotations, the developer needs access to **all data points from every series** that fall within that annotation's X-range, so they can compute zone-specific metrics and display them in a sidebar panel.

**Why this priority**: This is the core value proposition — bridging the gap between visual annotations and the data they cover. Without this, developers must manually cross-reference annotation bounds with raw data, which is error-prone and tedious.

**Independent Test**: Can be fully tested by creating a chart with series data and a range annotation, tapping the annotation, and verifying the callback delivers the correct filtered data points for each series within the annotation's X-range.

**Acceptance Scenarios**:

1. **Given** a chart with 3 series and a vertical range annotation spanning X=3.2 to X=7.8, **When** the user taps the annotation, **Then** a callback fires containing all data points from each series where X is between 3.2 and 7.8 (inclusive).
2. **Given** a chart with a range annotation that covers zero data points, **When** the user taps the annotation, **Then** the callback fires with an empty data set (no error).
3. **Given** a chart with multiple series where some have data within the range and others do not, **When** the annotation is tapped, **Then** only series with matching data are included in the result.

---

### User Story 2 - Built-in Summary Statistics for a Region (Priority: P1)

A developer building a fitness dashboard wants to show min/max/average power and heart rate within a selected training zone — without writing their own aggregation code. They enable a built-in summary computation and receive pre-calculated statistics (count, min, max, sum, average, range, standard deviation, delta) for each series within the selected region.

**Why this priority**: Summary statistics are the most common consumer need after accessing raw data. Providing them built-in eliminates boilerplate code and ensures consistent, correct calculations across all consumers.

**Independent Test**: Can be tested by selecting a region (annotation or segment), calling the summary computation, and verifying each metric against manually calculated expected values.

**Acceptance Scenarios**:

1. **Given** a selected region containing 50 data points for a "Power" series, **When** summary computation is invoked, **Then** the result includes count=50, correct min, max, sum, average, range, standard deviation, first/last Y values, and delta (last − first).
2. **Given** a region containing only 1 data point, **When** summary is computed, **Then** min=max=average=sum=the single value, standard deviation is null, delta is null.
3. **Given** a region with no data points for a particular series, **When** summary is computed, **Then** that series is omitted from results (not included with zero values).

---

### User Story 3 - Analyse Data in Segmented Series (Priority: P2)

A developer colours line segments to indicate exercise phases (warm-up in blue, intervals in red, cool-down in green). When their user taps a data point within a coloured segment, the developer wants to receive the data for the **entire contiguous segment group** — all consecutive points sharing the same visual style — so they can display phase-specific analytics.

**Why this priority**: Segments are a visual concept today with no data-query capability. Elevating segment groups to queryable regions unlocks phase-based analysis, which is a core use case for time-series fitness/health data.

**Independent Test**: Can be tested by creating a series with styled segments, tapping a point within a segment, and verifying the callback delivers all points in that contiguous segment group.

**Acceptance Scenarios**:

1. **Given** a series with points 0-9 styled blue and points 10-19 styled red, **When** the user taps point 5, **Then** the callback delivers a region containing points 0-9 with X-range from point 0's X to point 9's X.
2. **Given** a series with unstyled points (no segment), **When** the user taps any point, **Then** no segment-based region callback fires (only the existing point-tap callback).
3. **Given** two non-adjacent groups of points with the same style (blue points 0-4, then red 5-9, then blue 10-14), **When** point 12 is tapped, **Then** only points 10-14 are included in the region (groups are based on contiguity, not just colour).

---

### User Story 4 - Box-Select to Analyse Ad-Hoc Regions (Priority: P2)

A user wants to drag a bounding box on the chart to select an arbitrary X-range and immediately see summary statistics for that region — without needing to create a persistent annotation first. This enables exploratory "select-and-analyse" workflows.

**Why this priority**: Box-select already exists for point selection. Extending it to trigger region analysis gives users interactive data exploration without requiring pre-defined annotations. It's the most natural gesture for ad-hoc analysis.

**Independent Test**: Can be tested by performing a box-select drag on a chart, verifying a transient region is created from the drag's X-range, and checking that the region callback fires with the correct filtered data.

**Acceptance Scenarios**:

1. **Given** a chart with data, **When** the user drags a bounding box from X=2.0 to X=8.0, **Then** a region callback fires with all series data in that X-range, sourced as "box-select".
2. **Given** an active box-select region, **When** the user clicks elsewhere on the chart, **Then** the region is cleared and the callback fires with null/empty.
3. **Given** a box-select region is active and summary display is enabled, **When** the user starts a new box-select drag, **Then** the previous region is dismissed and replaced by the new one upon drag completion.

---

### User Story 5 - Visual Summary Overlay (Priority: P3)

A developer wants an opt-in visual card that appears above a selected region showing key metrics (min, max, average, delta) per series — similar to a tooltip but for region-level data. This card should be configurable (which metrics, formatting, position) and should not disrupt chart rendering performance.

**Why this priority**: A built-in overlay reduces the need for developers to build custom UI for common summary display. However, many developers will build their own UI using the data callbacks, making this a convenience feature rather than a necessity.

**Independent Test**: Can be tested by enabling the summary overlay, selecting a region, and verifying the overlay card appears with the correct metrics, positioned relative to the selected region.

**Acceptance Scenarios**:

1. **Given** summary display is enabled and configured to show min/max/average, **When** a region is selected, **Then** an overlay card appears showing those metrics for each series in the region.
2. **Given** the overlay would overlap the top of the chart area, **When** it is positioned, **Then** it falls back to rendering inside the top of the region instead of above it.
3. **Given** summary display is enabled, **When** the region is deselected, **Then** the overlay card is dismissed.
4. **Given** summary display is disabled (the default), **When** a region is selected, **Then** no overlay card appears (only the data callback fires).

---

### User Story 6 - Custom Analysis Extensions (Priority: P3)

A developer computing domain-specific metrics (e.g., "Normalized Power" for cycling) wants to plug a custom analysis function into the region analysis pipeline. When a region is selected, the built-in summary is computed first, then the custom function runs and its results are merged into the summary output or overlay display.

**Why this priority**: Extensibility is important for advanced consumers but the core feature (data access + built-in stats) must be solid first. Custom hooks add flexibility without blocking the base implementation.

**Independent Test**: Can be tested by registering a custom analysis function that returns a map of metric names to values, selecting a region, and verifying the custom metrics appear alongside built-in ones.

**Acceptance Scenarios**:

1. **Given** a custom analysis function is registered that computes "Normalized Power", **When** a region is selected, **Then** the custom metric is available in the summary result alongside built-in metrics.
2. **Given** no custom analysis function is registered, **When** a region is selected, **Then** only built-in metrics are returned (no error from null hook).

---

### Edge Cases

- What happens when the selected region's X-range extends beyond the data boundaries (start before first point, end after last point)? → Only points within the actual data range are returned; no synthetic points are created.
- What happens when data is not sorted by X value? → The system falls back to a linear scan instead of binary search; results are still correct, just slower.
- What happens when a series has duplicate X values at the region boundary? → All points at the boundary X value are included (inclusive filtering).
- What happens when the chart is in streaming mode and data changes after a region is selected? → The analysis reflects the data snapshot at query time. There is no continuous subscription — consumers re-query if they want updated results.
- What happens with multi-axis charts where series have different X scales? → Analysis uses original (non-normalized) data values. Each series is filtered independently against the region's X-range.

## Requirements _(mandatory)_

### Functional Requirements

- **FR-001**: System MUST provide a callback that delivers filtered data points per series when a vertical range annotation is selected (tapped).
- **FR-002**: System MUST expose a readable property on the chart state that returns the data region(s) for the current selection.
- **FR-003**: System MUST compute built-in summary statistics (count, min, max, sum, average, range, standard deviation, first/last values, delta) per series within a selected region.
- **FR-004**: System MUST detect contiguous segment groups (consecutive points sharing the same visual style) and treat each group as a queryable data region.
- **FR-005**: System MUST support single-region selection in V1 — selecting a new region deselects the previous one.
- **FR-006**: System MUST fire the region callback when a box-select drag completes, creating a transient region from the drag's X-range.
- **FR-007**: System MUST perform region analysis lazily (on-demand only) — no computation in the rendering hot path.
- **FR-008**: System MUST use original (non-normalized) data values for all analysis, regardless of multi-axis normalization.
- **FR-009**: System MUST support X-only filtering — vertical range annotations filter by X-range; Y values are not bounded.
- **FR-010**: System MUST provide an opt-in visual summary overlay card that displays configured metrics above/inside the selected region.
- **FR-011**: System MUST support a configurable set of metrics displayed in the summary overlay (which metrics, value formatting, position).
- **FR-012**: System MUST allow consumers to register a custom analysis function that runs after built-in summary computation and merges additional metrics into the result.
- **FR-013**: The summary overlay MUST render in the overlay layer and MUST NOT invalidate the series rendering cache.
- **FR-014**: System MUST clear the transient box-select region when the user clicks elsewhere or starts a new interaction.
- **FR-015**: Summary statistics MUST return null for standard deviation and delta when fewer than 2 data points exist in the region.
- **FR-016**: System MUST use efficient search (binary search on sorted data) for filtering points within a region's X-range, with a linear-scan fallback for unsorted data.
- **FR-017**: Segment groups MUST be identified by contiguity — not by style value alone. Non-adjacent groups with the same style are treated as separate regions.

### Key Entities

- **Data Region**: A contiguous X-range of interest within a chart. Has an identifier, optional label, start/end X values, a source type (range annotation, segment, or box-select), and the filtered series data within its bounds.
- **Region Summary**: Pre-computed statistics for an entire region. Contains per-series summaries including count, min, max, sum, average, range, standard deviation, first/last values, delta, and duration.
- **Series Region Summary**: Statistics for a single series within a single region. Includes the series identifier, optional name and unit, and all computed metrics.
- **Region Source**: Indicates how a data region was created — from a range annotation, a segment group, or an interactive box-select.
- **Region Summary Configuration**: Controls which metrics appear in the visual overlay, how values are formatted, and where the overlay is positioned relative to the region.

## Success Criteria _(mandatory)_

### Measurable Outcomes

- **SC-001**: Selecting a range annotation with 3 series and 10,000 data points completes data filtering and returns results in under 10ms.
- **SC-002**: Summary computation for a filtered region of 1,000 points per series completes in under 5ms.
- **SC-003**: The rendering frame budget is not impacted when a region is selected — no measurable increase in paint time for the series layer.
- **SC-004**: All built-in summary metrics (count, min, max, sum, average, range, std dev, delta) match manually-calculated expected values within floating-point tolerance (1e-10).
- **SC-005**: The region callback correctly returns data for all 3 source types: range annotations, segment groups, and box-select.
- **SC-006**: Segment group detection correctly identifies separate groups for non-adjacent segments sharing the same style.
- **SC-007**: The summary overlay renders without invalidating the cached series layer.
- **SC-008**: The box-select region callback fires within 1 frame of drag completion.
- **SC-009**: The API surface supports the full workflow (select region → get data → compute summary → display overlay) without requiring consumers to write data filtering or aggregation code.
