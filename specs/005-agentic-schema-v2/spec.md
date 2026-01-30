# Feature Specification: Agentic Chart Schema V2

**Feature Branch**: `005-agentic-schema-v2`  
**Created**: 2026-01-30  
**Status**: Draft  
**Input**: Unified, validated schema for LLM-driven chart creation and modification with nested yAxis, annotation IDs, and comprehensive validation

## User Scenarios & Testing _(mandatory)_

### User Story 1 - LLM Creates Multi-Series Chart with Per-Series Y-Axes (Priority: P1)

An LLM agent receives a user request to visualize power output and heart rate data together. The agent calls `create_chart` with a configuration that includes two series, each with its own nested y-axis configuration specifying different scales, positions (left/right), labels, and units.

**Why this priority**: This is the core use case - creating charts with proper y-axis configuration is fundamental to the entire agentic charting system.

**Independent Test**: Can be fully tested by calling `create_chart` with a multi-series configuration and verifying both series render with correct, independent y-axes.

**Acceptance Scenarios**:

1. **Given** an LLM agent with chart creation capabilities, **When** it calls `create_chart` with two series each containing nested `yAxis` configuration, **Then** the chart renders with two independent y-axes at the specified positions
2. **Given** `normalizationMode: "perSeries"` is set, **When** chart-level `yAxis` is also provided, **Then** the system emits a warning and ignores the chart-level yAxis
3. **Given** a series without `yAxis` in perSeries mode, **When** the chart renders, **Then** the system uses default axis configuration for that series

---

### User Story 2 - LLM Modifies Chart Using Update/Add/Remove Operations (Priority: P1)

An LLM agent needs to update an existing chart by changing a series color, adding a new annotation, and removing an old series. The agent calls `modify_chart` with explicit `update`, `add`, and `remove` sections, each targeting entities by their IDs.

**Why this priority**: Modification is equally critical as creation - agents must reliably update charts based on user feedback.

**Independent Test**: Can be fully tested by creating a chart, then calling `modify_chart` with update/add/remove operations and verifying the changes are applied correctly.

**Acceptance Scenarios**:

1. **Given** an existing chart with series "power", **When** agent calls `modify_chart` with `update.series[{id: "power", color: "#FF0000"}]`, **Then** the power series color changes while other properties remain unchanged
2. **Given** an existing chart, **When** agent calls `modify_chart` with `add.annotations[{type: "referenceLine", value: 200}]`, **Then** a new annotation is created with a system-generated ID
3. **Given** an existing chart with annotation "ann-123", **When** agent calls `modify_chart` with `remove.annotations: ["ann-123"]`, **Then** that annotation is removed from the chart
4. **Given** a modify request with all three operations, **When** executed, **Then** operations run in order: remove → add → update

---

### User Story 3 - LLM Queries Chart State Before Modification (Priority: P2)

An LLM agent is asked to "remove the threshold line" but doesn't know the annotation ID. The agent calls `get_chart` to retrieve the current chart configuration, discovers the annotation IDs, and then calls `modify_chart` with the correct ID.

**Why this priority**: Essential for agents to make informed modifications without requiring users to specify technical IDs.

**Independent Test**: Can be fully tested by creating a chart with annotations, calling `get_chart`, and verifying all annotation IDs are returned.

**Acceptance Scenarios**:

1. **Given** a chart with annotations, **When** agent calls `get_chart`, **Then** the response includes all annotations with their system-generated IDs
2. **Given** `get_chart` called with `includeData: false` (default), **When** response is returned, **Then** series data is summarized as `{count: N}` instead of full array
3. **Given** `get_chart` called with `includeData: true`, **When** response is returned, **Then** full data arrays are included

---

### User Story 4 - System Validates References and Provides Clear Errors (Priority: P2)

An LLM agent attempts to create a horizontal reference line annotation in perSeries mode but forgets to specify `seriesId`. The system validates the input and returns a clear error message explaining that `seriesId` is required for horizontal reference lines in perSeries mode.

**Why this priority**: Validation prevents silent failures that cause unpredictable chart behavior and confuse both agents and users.

**Independent Test**: Can be fully tested by submitting invalid configurations and verifying appropriate error messages are returned.

**Acceptance Scenarios**:

1. **Given** `normalizationMode: "perSeries"` and a horizontal referenceLine without `seriesId`, **When** chart is created, **Then** system returns error: "horizontal referenceLine requires seriesId in perSeries mode"
2. **Given** a point annotation without `seriesId`, **When** chart is created, **Then** system returns error: "point annotation requires seriesId"
3. **Given** an annotation with `seriesId: "nonexistent"`, **When** chart is created, **Then** system returns error: "annotation references non-existent series 'nonexistent'"
4. **Given** `modify_chart` with `update.series[{id: "nonexistent"}]`, **When** executed, **Then** system returns error: "cannot update non-existent series 'nonexistent'"

---

### User Story 5 - Deep Merge for Nested Object Updates (Priority: P3)

An LLM agent wants to update just the y-axis label for a series without affecting other y-axis properties like min, max, or position. The agent sends a partial yAxis update, and the system deep-merges it with existing configuration.

**Why this priority**: Enables precise updates without requiring agents to resend entire configuration objects.

**Independent Test**: Can be fully tested by updating a nested property and verifying other nested properties are preserved.

**Acceptance Scenarios**:

1. **Given** a series with `yAxis: {label: "Power", unit: "W", position: "left"}`, **When** agent updates with `yAxis: {label: "Power Output"}`, **Then** yAxis becomes `{label: "Power Output", unit: "W", position: "left"}`
2. **Given** a series update with `data: [...]`, **When** executed, **Then** data array is replaced entirely (not merged)

---

### Edge Cases

- What happens when agent supplies `id` on annotation create? → System ignores and generates new ID, emits warning
- What happens when duplicate series IDs are provided? → System returns validation error before chart creation
- How does system handle empty `update`/`add`/`remove` sections? → Treated as no-op for that section
- What if `remove` targets an ID that was just added in same request? → Remove runs first, so add succeeds (order: remove → add → update)

## Requirements _(mandatory)_

### Functional Requirements

**Schema Structure:**

- **FR-001**: Series configuration MUST support nested `yAxis` object containing all y-axis properties (label, unit, position, color, min, max, etc.)
- **FR-002**: System MUST NOT support flat y-axis fields on series (`yAxisPosition`, `yAxisLabel`, `yAxisUnit`, `yAxisColor`, `yAxisMin`, `yAxisMax`)
- **FR-003**: System MUST NOT support `yAxisId` references or `yAxes[]` array
- **FR-004**: Annotation configuration MUST include `id` field that is system-generated and read-only
- **FR-005**: Annotation configuration MUST support `seriesId` field for linking to series coordinate systems

**Tool Operations:**

- **FR-010**: `create_chart` tool MUST accept ChartConfiguration directly (no wrapper object)
- **FR-011**: `create_chart` tool MUST return created chart WITH all system-generated IDs (chart id, annotation ids)
- **FR-012**: `get_chart` tool MUST return current chart configuration with all IDs
- **FR-013**: `get_chart` tool MUST support `includeData` parameter (default: false) to control data array inclusion
- **FR-014**: `modify_chart` tool MUST use explicit `update`/`add`/`remove` structure
- **FR-015**: `modify_chart` tool MUST execute operations in order: remove → add → update
- **FR-016**: `modify_chart` tool MUST return modified chart including IDs of newly added entities

**Validation:**

- **FR-020**: System MUST validate all series `id` values are unique within a chart
- **FR-021**: System MUST validate all annotation `id` values are unique within a chart
- **FR-022**: System MUST validate `seriesId` references exist when provided
- **FR-023**: System MUST require `seriesId` for point and marker annotations (always)
- **FR-024**: System MUST require `seriesId` for horizontal referenceLine/zone annotations when `normalizationMode: "perSeries"`
- **FR-025**: System MUST warn when chart-level `yAxis` is provided with `normalizationMode: "perSeries"`
- **FR-026**: System MUST validate required fields per annotation type (value for referenceLine, minValue/maxValue for zone, text for textLabel, dataPointIndex for point)
- **FR-027**: System MUST return clear, actionable error messages for all validation failures

**Merge Semantics:**

- **FR-030**: Scalar field updates MUST replace existing values
- **FR-031**: Nested object updates MUST deep-merge with existing values
- **FR-032**: Array field updates (`data`) MUST replace entire array

### Key Entities

- **ChartConfiguration**: Root configuration containing series, axes, annotations, and display settings. Has system-generated `id`.
- **SeriesConfig**: Data series with nested `yAxis` configuration. Has agent-supplied `id` (required, unique).
- **AnnotationConfig**: Chart decoration (referenceLine, zone, textLabel, marker, point). Has system-generated `id` and optional `seriesId` link.
- **YAxisConfig**: Y-axis configuration that can appear at chart level or nested in series. Contains label, unit, position, range settings.
- **XAxisConfig**: X-axis configuration at chart level. Contains label, unit, type (numeric/category/datetime), range settings.

## Success Criteria _(mandatory)_

### Measurable Outcomes

- **SC-001**: 100% of charts created with nested `yAxis` configuration render correctly on first attempt
- **SC-002**: 100% of validation errors include actionable guidance for resolution
- **SC-003**: LLM agents can complete create → query → modify → remove cycle for annotations using returned IDs
- **SC-004**: Zero silent failures - all invalid configurations produce explicit error messages
- **SC-005**: Modification operations preserve unspecified properties (deep merge works correctly)
- **SC-006**: Agent can discover all entity IDs via `get_chart` without prior knowledge

## Assumptions

- The existing `SeriesConfig.id` pattern (agent-supplied, settable field) works correctly and will be replicated for annotations
- Widget rebuilds do not affect configuration objects - IDs persist because config objects persist in app state
- LLM agents will use tool results to track IDs for subsequent operations
- No backward compatibility is required - this is a breaking schema change

## Dependencies

- BravenChartPlus core library must be updated to support nested `yAxis` and annotation `id` fields
- Existing tests must be updated to reflect new schema structure

## Technical Reference

The detailed technical schema specification is maintained at:
`specs/_base/005-agentic-schema-v2/schema_spec.md`

This includes:

- Complete JSON schema definitions
- Validation rule codes (V001-V044)
- Tool input/output formats
- Implementation task breakdown
- File change summary
