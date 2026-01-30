# Agentic Chart Schema v2 Specification

**Status**: Draft  
**Created**: 2026-01-30  
**Purpose**: Unified, validated schema for LLM-driven chart creation and modification

## Problem Statement

The current schema has multiple issues:

1. **Dual y-axis patterns**: `yAxisId` + `yAxes[]` (reference) vs inline `yAxisPosition`/`yAxisLabel`/etc (flat) - confusing and mutually exclusive
2. **No validation**: Invalid references silently fail, causing unpredictable behavior
3. **Inconsistent**: Create and modify have different patterns
4. **Annotation complexity**: Same reference issues with `seriesId`
5. **LLM confusion**: Results in charts that sometimes work, sometimes fail

## Design Principles

1. **Self-contained objects**: All configuration for an entity lives within that entity
2. **No cross-references for required data**: Avoid patterns where object A must reference object B by ID
3. **Consistent structure**: Create and modify use the same schema shape
4. **Modify uses subsets**: Modify specifies only changed fields, identified by entity IDs
5. **Strict validation**: All inputs validated with clear error messages

## Core Concepts

### Normalization Modes

| Mode        | Behavior                             | Y-Axis Handling                                                     |
| ----------- | ------------------------------------ | ------------------------------------------------------------------- |
| `none`      | Raw data values, shared scale        | Chart-level `yAxis` applies; series `yAxis` renders additional axes |
| `auto`      | Auto-detect based on data ranges     | Library decides; chart-level `yAxis` as fallback                    |
| `perSeries` | Each series normalized independently | **Chart-level `yAxis` IGNORED**; each series MUST define `yAxis`    |

### Key Insight

When `normalizationMode: "perSeries"`:

- Each series is tied to its OWN y-axis
- Chart-level `yAxis` is meaningless (validated/warned)
- Series without `yAxis` config get a default axis

When `normalizationMode: "none"` or `"auto"`:

- Chart-level `yAxis` defines the shared axis
- Series `yAxis` creates ADDITIONAL axes (multi-axis chart)

---

## Schema Definition

### ChartConfiguration (Full Schema)

```json
{
  "id": "string (auto-generated on create, required on modify)",
  "title": "string | null",
  "subtitle": "string | null",

  "series": [SeriesConfig],

  "xAxis": XAxisConfig,
  "yAxis": YAxisConfig | null,

  "annotations": [AnnotationConfig],

  "normalizationMode": "none" | "auto" | "perSeries",

  "showGrid": "boolean (default: true)",
  "showLegend": "boolean (default: true)",
  "legendPosition": "top" | "bottom" | "left" | "right" | "topLeft" | "topRight" | "bottomLeft" | "bottomRight",

  "interactions": InteractionConfig,

  "useDarkTheme": "boolean (default: false)",
  "showScrollbar": "boolean (default: true)",

  "width": "number | null",
  "height": "number | null (default: 350)",
  "backgroundColor": "string (hex) | null"
}
```

### SeriesConfig

```json
{
  "id": "string (required, unique within chart)",
  "name": "string (display name)",
  "type": "line" | "area" | "bar" | "scatter",

  "data": [
    { "x": "number", "y": "number" }
  ],

  "color": "string (hex)",
  "visible": "boolean (default: true)",
  "legendVisible": "boolean (default: true)",

  "yAxis": YAxisConfig | null,

  "unit": "string | null",

  "strokeWidth": "number (default: 2.0)",
  "interpolation": "linear" | "bezier" | "stepped" | "monotone",
  "tension": "number 0-1 (default: 0.4, for bezier)",

  "showPoints": "boolean (default: false)",
  "markerStyle": "none" | "circle" | "square" | "triangle" | "diamond",
  "markerSize": "number (default: 4.0)",

  "fillOpacity": "number 0-1 (default: 0.3, for area)",

  "barWidthPercent": "number 0-1 (default: 0.7)",
  "barWidthPixels": "number | null (overrides percent)",
  "barMinWidth": "number (default: 4.0)",
  "barMaxWidth": "number (default: 100.0)"
}
```

### YAxisConfig (Nested in Series or Chart-level)

```json
{
  "label": "string | null",
  "unit": "string | null",
  "position": "left" | "right" | "leftOuter" | "rightOuter",
  "color": "string (hex) | null",

  "min": "number | null",
  "max": "number | null",
  "autoRange": "boolean (default: true)",
  "includeZero": "boolean (default: false)",

  "showTicks": "boolean (default: true)",
  "showAxisLine": "boolean (default: true)",
  "showGridLines": "boolean (default: true)"
}
```

### XAxisConfig

```json
{
  "label": "string | null",
  "unit": "string | null",
  "type": "numeric" | "category" | "datetime",

  "min": "number | null",
  "max": "number | null",
  "autoRange": "boolean (default: true)",
  "paddingPercent": "number (default: 0)",

  "tickRotation": "number (default: 0)",
  "showTicks": "boolean (default: true)",
  "showAxisLine": "boolean (default: true)",
  "showGridLines": "boolean (default: true)"
}
```

### AnnotationConfig

```json
{
  "id": "string (system-generated, read-only - returned in tool output and get_chart)",
  "type": "referenceLine" | "zone" | "textLabel" | "marker" | "point",

  "orientation": "horizontal" | "vertical (for referenceLine/zone)",
  "value": "number (for referenceLine)",
  "minValue": "number (for zone)",
  "maxValue": "number (for zone)",

  "seriesId": "string | null (see Annotation seriesId Requirements below)",

  "dataPointIndex": "number | null (for point annotations - index into series data)",

  "label": "string | null",
  "color": "string (hex)",
  "strokeWidth": "number",
  "strokeDash": "[number, number] | null",

  "text": "string (for textLabel)",
  "position": "topLeft" | "topCenter" | "topRight" | "centerLeft" | "center" | "centerRight" | "bottomLeft" | "bottomCenter" | "bottomRight",
  "fontSize": "number (default: 14)"
}
```

#### Annotation `id` Lifecycle

| Operation                 | `id` Behavior                                        |
| ------------------------- | ---------------------------------------------------- |
| `create_chart`            | Agent does NOT supply `id`; system generates it      |
| `add.annotations`         | Agent does NOT supply `id`; system generates it      |
| Tool result / `get_chart` | System returns annotations WITH their generated `id` |
| `update.annotations`      | Agent MUST supply `id` to identify target            |
| `remove.annotations`      | Agent supplies `id` to identify which to remove      |

**Implementation Note:**

The `id` field is added to `AnnotationConfig` in BravenChartPlus (same pattern as `SeriesConfig.id`):

- Field is settable (not final), allowing the tool handler to assign generated IDs
- ID lives on the config object itself - no separate registry needed
- Widget rebuilds don't affect IDs since the config objects persist in app state
- IDs are stable for the lifetime of the annotation object

#### Annotation `seriesId` Requirements

The `seriesId` field links an annotation to a specific series for coordinate resolution.
Validation depends on annotation type AND chart normalization mode:

| Annotation Type | Condition                                                             | `seriesId` Requirement                            |
| --------------- | --------------------------------------------------------------------- | ------------------------------------------------- |
| `point`         | Always                                                                | **REQUIRED** - must reference valid series        |
| `marker`        | Always                                                                | **REQUIRED** - positioned relative to series data |
| `referenceLine` | `orientation: "horizontal"` + `normalizationMode: "perSeries"`        | **REQUIRED** - which series scale?                |
| `referenceLine` | `orientation: "horizontal"` + `normalizationMode: "none"` or `"auto"` | Optional (uses chart yAxis)                       |
| `referenceLine` | `orientation: "vertical"`                                             | Not needed (x-axis is shared)                     |
| `zone`          | `orientation: "horizontal"` + `normalizationMode: "perSeries"`        | **REQUIRED** - which series scale?                |
| `zone`          | `orientation: "horizontal"` + `normalizationMode: "none"` or `"auto"` | Optional (uses chart yAxis)                       |
| `zone`          | `orientation: "vertical"`                                             | Not needed (x-axis is shared)                     |
| `textLabel`     | Always                                                                | Optional (can be chart-level or series-relative)  |

**Validation Rules:**

- When `seriesId` is provided, it MUST reference an existing series in the chart (V021)
- When `seriesId` is REQUIRED but missing, emit error with specific guidance (V020)

### InteractionConfig

```json
{
  "enableZoom": "boolean (default: true)",
  "enablePan": "boolean (default: true)",
  "crosshairMode": "none" | "vertical" | "horizontal" | "both",
  "tooltipEnabled": "boolean (default: true)"
}
```

---

## Tool Schemas

### create_chart

Creates a new chart. Uses full ChartConfiguration schema directly (no wrapper).

**Input:**

The input IS the ChartConfiguration object:

```json
{
  "id": "string (optional, auto-generated if omitted)",
  "title": "...",
  "series": [...],
  "annotations": [
    {
      "type": "referenceLine",
      "value": 200,
      ...
    }
  ],
  ...
}
```

**Output:**

Returns the created chart configuration WITH all system-generated IDs:

```json
{
  "success": true,
  "chart": {
    "id": "chart-abc123",
    "title": "...",
    "series": [...],
    "annotations": [
      {
        "id": "ann-xyz789",
        "type": "referenceLine",
        "value": 200,
        ...
      }
    ]
  }
}
```

This is how the agent discovers annotation IDs for future update/remove operations.

**Notes:**

- Chart `id` is auto-generated if not provided
- All series must have unique `id` values (agent-supplied)
- Annotation `id` values are ALWAYS system-generated (agent does not supply)
- If `normalizationMode: "perSeries"` and chart-level `yAxis` is provided, emit warning and ignore it

---

### get_chart

Retrieves the current configuration of an existing chart. Enables the agent to inspect chart state before modifications.

**Input:**

```json
{
  "chartId": "string (optional, uses active chart if omitted)",
  "includeData": "boolean (default: false)"
}
```

**Output:**

When `includeData: false` (default), series data is summarized:

```json
{
  "success": true,
  "chart": {
    "id": "chart-uuid",
    "title": "Power Analysis",
    "series": [
      {
        "id": "power",
        "name": "Power",
        "type": "line",
        "color": "#2196F3",
        "data": { "count": 1000 },
        "yAxis": { ... }
      }
    ],
    "annotations": [
      {
        "id": "ann-uuid-1",
        "type": "referenceLine",
        ...
      }
    ],
    ...
  }
}
```

When `includeData: true`, full data arrays are included:

```json
{
  "success": true,
  "chart": {
    "series": [
      {
        "id": "power",
        "data": [{ "x": 0, "y": 150 }, { "x": 1, "y": 200 }, ...]
      }
    ]
  }
}
```

On error:

```json
{
  "success": false,
  "error": "Chart not found: {chartId}"
}
```

**Use Cases:**

1. **Inspect before modify**: Agent can see current series IDs, axis configs, etc. before calling `modify_chart`
2. **Validate references**: Agent can verify a series ID exists before trying to update/remove it
3. **Avoid blind modifications**: Agent doesn't have to guess or remember what was created earlier
4. **Context recovery**: After conversation restart, agent can re-discover existing chart state

**Notes:**

- Returns the CURRENT configuration, including any previous modifications
- Data arrays may be truncated in the response to reduce token usage (e.g., `"data": [{"x": 0, "y": 150}, "...(248 more points)..."]`)
- Agent should call this when uncertain about current chart state

---

### modify_chart

Modifies an existing chart using explicit update/add/remove operations.

**Input:**

```json
{
  "chartId": "string (optional, uses active chart if omitted)",

  "update": {
    "title": "string | null",
    "subtitle": "string | null",
    "normalizationMode": "none" | "auto" | "perSeries",
    "showGrid": "boolean",
    "showLegend": "boolean",
    "legendPosition": "...",
    "useDarkTheme": "boolean",
    "showScrollbar": "boolean",

    "xAxis": PartialXAxisConfig,
    "yAxis": PartialYAxisConfig | null,

    "series": [
      {
        "id": "string (REQUIRED - identifies target series)",
        "name": "string",
        "color": "string",
        "visible": "boolean",
        "yAxis": YAxisConfig,
        "data": [DataPoint],
        ...other SeriesConfig fields...
      }
    ],

    "annotations": [
      {
        "id": "string (REQUIRED - identifies target annotation)",
        "value": "number",
        "color": "string",
        ...other AnnotationConfig fields...
      }
    ]
  },

  "add": {
    "series": [SeriesConfig],
    "annotations": [AnnotationConfig]
  },

  "remove": {
    "series": ["seriesId1", "seriesId2"],
    "annotations": ["annotationId1", "annotationId2"]
  }
}
```

**Execution Order:**

1. `remove` - First, remove specified entities
2. `add` - Then, add new entities
3. `update` - Finally, update existing entities

This order prevents conflicts (e.g., can't update something that was removed).

**Merge Semantics:**

| Field Type       | Behavior                  | Example                                                     |
| ---------------- | ------------------------- | ----------------------------------------------------------- |
| Scalar           | Replace                   | `"color": "#FF0000"` replaces existing color                |
| Nested Object    | Deep merge                | `"yAxis": {"label": "New"}` merges, keeps other yAxis props |
| Array (`data`)   | Replace entirely          | `"data": [...]` replaces all data points                    |
| Array (explicit) | Use add/remove operations | Use `add.series` / `remove.series`                          |

**Output:**

Returns the modified chart configuration, including any newly generated IDs:

```json
{
  "success": true,
  "chart": ChartConfiguration,
  "added": {
    "annotations": [
      { "id": "ann-newid123", "type": "referenceLine", ... }
    ]
  }
}
```

The `added` section shows newly created entities with their system-generated IDs, so the agent can reference them in future operations.

**Examples:**

Update series color (keeps all other properties):

```json
{
  "update": {
    "series": [{ "id": "power", "color": "#4472C4" }]
  }
}
```

Update series y-axis label (keeps other yAxis properties):

```json
{
  "update": {
    "series": [
      {
        "id": "power",
        "yAxis": { "label": "Power Output" }
      }
    ]
  }
}
```

Add a series and remove another:

```json
{
  "add": {
    "series": [{ "id": "cadence", "name": "Cadence", ... }]
  },
  "remove": {
    "series": ["oldSeries"]
  }
}
```

**Notes:**

- All `update.series[]` and `update.annotations[]` entries MUST have `id`
- All `add.series[]` and `add.annotations[]` entries MUST have unique `id` values
- `remove` arrays contain only the IDs to remove

---

## Validation Rules

### Chart-Level Validation

| Rule | Condition                                                     | Action                                               |
| ---- | ------------------------------------------------------------- | ---------------------------------------------------- |
| V001 | `normalizationMode: "perSeries"` AND `yAxis` provided         | Warning: chart-level yAxis ignored in perSeries mode |
| V002 | `normalizationMode: "perSeries"` AND any series lacks `yAxis` | Warning: series will use default axis config         |
| V003 | Duplicate series `id`                                         | Error: series IDs must be unique                     |
| V004 | Duplicate annotation `id`                                     | Error: annotation IDs must be unique                 |

### Series Validation (on modify)

| Rule | Condition                                        | Action                                                           |
| ---- | ------------------------------------------------ | ---------------------------------------------------------------- |
| V010 | `update.series[].id` not found in existing chart | Error: cannot update non-existent series "{id}"                  |
| V011 | `remove.series` contains non-existent ID         | Error: cannot remove non-existent series "{id}"                  |
| V012 | `add.series[].id` already exists                 | Error: series "{id}" already exists, use update.series to modify |

### Annotation Validation

**ID Validation (on modify):**

| Rule | Condition                                     | Action                                                       |
| ---- | --------------------------------------------- | ------------------------------------------------------------ |
| V020 | `update.annotations[].id` not found in chart  | Error: cannot update non-existent annotation "{id}"          |
| V021 | `remove.annotations` contains non-existent ID | Error: cannot remove non-existent annotation "{id}"          |
| V022 | Agent supplies `id` on create/add             | Warning: id is system-generated, supplied id will be ignored |

**seriesId Validation (ALWAYS - when seriesId is provided):**

| Rule | Condition                                 | Action                                                        |
| ---- | ----------------------------------------- | ------------------------------------------------------------- |
| V030 | `seriesId` references non-existent series | Error: annotation references non-existent series "{seriesId}" |

**seriesId Required Validation (conditional on annotation type and mode):**

| Rule | Condition                                                                                                | Action                                                              |
| ---- | -------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------- |
| V031 | `type: "point"` without `seriesId`                                                                       | Error: point annotation requires seriesId                           |
| V032 | `type: "marker"` without `seriesId`                                                                      | Error: marker annotation requires seriesId                          |
| V033 | `type: "referenceLine"` + `orientation: "horizontal"` + `normalizationMode: "perSeries"` + no `seriesId` | Error: horizontal referenceLine requires seriesId in perSeries mode |
| V034 | `type: "zone"` + `orientation: "horizontal"` + `normalizationMode: "perSeries"` + no `seriesId`          | Error: horizontal zone requires seriesId in perSeries mode          |

**Type-specific Validation:**

| Rule | Condition                                       | Action                                                         |
| ---- | ----------------------------------------------- | -------------------------------------------------------------- |
| V040 | `type: "referenceLine"` without `value`         | Error: referenceLine requires value property                   |
| V041 | `type: "zone"` without `minValue` or `maxValue` | Error: zone requires minValue and maxValue                     |
| V042 | `type: "point"` without `dataPointIndex`        | Error: point annotation requires dataPointIndex                |
| V043 | `type: "point"` with invalid `dataPointIndex`   | Error: dataPointIndex {n} out of range for series "{seriesId}" |
| V044 | `type: "textLabel"` without `text`              | Error: textLabel requires text property                        |

---

## Migration Path

### From v1 to v2

**Series y-axis fields migration:**

| v1 (deprecated)               | v2 (nested)                                   |
| ----------------------------- | --------------------------------------------- |
| `series[].yAxisPosition`      | `series[].yAxis.position`                     |
| `series[].yAxisLabel`         | `series[].yAxis.label`                        |
| `series[].yAxisUnit`          | `series[].yAxis.unit`                         |
| `series[].yAxisColor`         | `series[].yAxis.color`                        |
| `series[].yAxisMin`           | `series[].yAxis.min`                          |
| `series[].yAxisMax`           | `series[].yAxis.max`                          |
| `series[].yAxisId`            | **REMOVED** (no longer needed)                |
| `yAxes[]` (chart-level array) | **REMOVED** (use `series[].yAxis` or `yAxis`) |

**Backward compatibility:**

- v1 flat fields will be supported during transition with deprecation warnings
- After transition period, v1 fields will be removed

---

## Examples

### Example 1: Simple Single-Axis Chart

```json
{
  "title": "Temperature Over Time",
  "series": [
    {
      "id": "temp",
      "name": "Temperature",
      "type": "line",
      "data": [
        { "x": 0, "y": 20 },
        { "x": 1, "y": 22 },
        { "x": 2, "y": 21 }
      ],
      "color": "#FF5722"
    }
  ],
  "xAxis": {
    "label": "Time",
    "unit": "hours"
  },
  "yAxis": {
    "label": "Temperature",
    "unit": "°C"
  }
}
```

### Example 2: Multi-Series with Per-Series Normalization

```json
{
  "title": "Power vs Heart Rate",
  "normalizationMode": "perSeries",
  "series": [
    {
      "id": "power",
      "name": "Power",
      "type": "line",
      "data": [
        { "x": 0, "y": 150 },
        { "x": 1, "y": 200 },
        { "x": 2, "y": 180 }
      ],
      "color": "#2196F3",
      "yAxis": {
        "label": "Power",
        "unit": "W",
        "position": "left"
      }
    },
    {
      "id": "hr",
      "name": "Heart Rate",
      "type": "line",
      "data": [
        { "x": 0, "y": 120 },
        { "x": 1, "y": 145 },
        { "x": 2, "y": 135 }
      ],
      "color": "#E91E63",
      "yAxis": {
        "label": "Heart Rate",
        "unit": "bpm",
        "position": "right"
      }
    }
  ],
  "xAxis": {
    "label": "Time",
    "unit": "min"
  }
}
```

### Example 3: Modifying a Series Y-Axis

```json
{
  "modifications": {
    "series": [
      {
        "id": "power",
        "yAxis": {
          "label": "Power Output",
          "color": "#4472C4",
          "showGridLines": false
        }
      }
    ]
  }
}
```

### Example 4: Adding a New Series

```json
{
  "modifications": {
    "addSeries": [
      {
        "id": "cadence",
        "name": "Cadence",
        "type": "line",
        "data": [
          { "x": 0, "y": 80 },
          { "x": 1, "y": 85 },
          { "x": 2, "y": 82 }
        ],
        "color": "#4CAF50",
        "yAxis": {
          "label": "Cadence",
          "unit": "rpm",
          "position": "rightOuter"
        }
      }
    ]
  }
}
```

---

## Implementation Tasks

### Phase 1: BravenChartPlus Core Library Changes

**Location:** `lib/src/`

#### 1.1 Annotation Model Updates

**File:** `lib/src/models/annotation_config.dart` (or equivalent)

- [ ] Add `String? id` field to base annotation class/config
- [ ] Field must be settable (not final) to allow tool handler to assign generated IDs
- [ ] Update `copyWith()` to include `id` parameter
- [ ] Update `toJson()` / `fromJson()` to serialize `id`
- [ ] Update `==` operator and `hashCode` to include `id`
- [ ] Add `point` annotation type if not exists
- [ ] Add `dataPointIndex` field for point annotations

**Affected Classes (audit and update all):**

- [ ] `AnnotationConfig` / `ChartAnnotation` base class
- [ ] `ReferenceLineAnnotation`
- [ ] `ZoneAnnotation`
- [ ] `TextLabelAnnotation`
- [ ] `MarkerAnnotation`
- [ ] `PointAnnotation` (new or existing)

#### 1.2 Series Model Updates

**File:** `lib/src/models/series_config.dart` (or equivalent)

- [ ] Add nested `YAxisConfig? yAxis` field to `SeriesConfig`
- [ ] Remove flat y-axis fields:
  - [ ] `yAxisId`
  - [ ] `yAxisPosition`
  - [ ] `yAxisLabel`
  - [ ] `yAxisUnit`
  - [ ] `yAxisColor`
  - [ ] `yAxisMin`
  - [ ] `yAxisMax`
- [ ] Update `copyWith()` method
- [ ] Update `toJson()` / `fromJson()` serialization
- [ ] Update `==` operator and `hashCode`

#### 1.3 Chart Configuration Updates

**File:** `lib/src/models/chart_configuration.dart` (or equivalent)

- [ ] Remove `List<YAxisConfig>? yAxes` array field
- [ ] Ensure single `YAxisConfig? yAxis` exists for chart-level axis
- [ ] Update `copyWith()` method
- [ ] Update `toJson()` / `fromJson()` serialization
- [ ] Update `==` operator and `hashCode`

#### 1.4 YAxisConfig Updates

**File:** `lib/src/models/y_axis_config.dart` (or equivalent)

- [ ] Ensure `position` field exists with enum: `left`, `right`, `leftOuter`, `rightOuter`
- [ ] Verify all properties match schema spec:
  - `label`, `unit`, `position`, `color`
  - `min`, `max`, `autoRange`, `includeZero`
  - `showTicks`, `showAxisLine`, `showGridLines`

---

### Phase 2: BravenChartPlus Rendering Updates

**Location:** `lib/src/rendering/` or `lib/src/painters/`

#### 2.1 Y-Axis Resolution Logic

- [ ] Update axis resolution to read from `series[].yAxis` instead of `yAxisId` lookup
- [ ] Remove any `yAxes[]` array lookup/resolution code
- [ ] For `normalizationMode: "none"` or `"auto"`: use chart-level `yAxis` as default
- [ ] For `normalizationMode: "perSeries"`: use `series[].yAxis` (each series has own axis)
- [ ] Handle missing `series[].yAxis` gracefully (use defaults)

#### 2.2 Annotation Rendering

- [ ] Ensure annotation renderer can handle `id` field (ignore for rendering, just data)
- [ ] Add rendering support for `point` annotation type
- [ ] Ensure `seriesId` lookup works for annotations

---

### Phase 3: Braven Agent Package - Tool Updates

**Location:** `packages/braven_agent/lib/src/tools/`

#### 3.1 New Tool: get_chart_tool.dart

**File:** `packages/braven_agent/lib/src/tools/get_chart_tool.dart` (NEW)

- [ ] Create new tool file
- [ ] Implement `GetChartTool` class
- [ ] Input schema: `{ chartId?: string, includeData?: boolean }`
- [ ] Output: Full chart configuration with all IDs
- [ ] When `includeData: false` (default): replace `data` array with `{ "count": N }`
- [ ] When `includeData: true`: include full data arrays
- [ ] Register tool in tool registry

#### 3.2 Update: create_chart_tool.dart

**File:** `packages/braven_agent/lib/src/tools/create_chart_tool.dart`

- [ ] Remove `{ "chart": ... }` wrapper from input schema - input IS the ChartConfiguration
- [ ] Update input schema to match v2 spec:
  - Nested `series[].yAxis` instead of flat fields
  - No `yAxes[]` array
  - No `yAxisId` references
- [ ] Generate UUIDs for annotations that don't have `id`
- [ ] Update output to return full chart WITH generated IDs
- [ ] Add validation rules (V001-V004, V030-V044)
- [ ] Update JSON schema description for LLM

#### 3.3 Update: modify_chart_tool.dart

**File:** `packages/braven_agent/lib/src/tools/modify_chart_tool.dart`

- [ ] Restructure input schema to use `update` / `add` / `remove` structure:
  ```json
  {
    "chartId": "optional",
    "update": { ... },
    "add": { "series": [...], "annotations": [...] },
    "remove": { "series": ["id1"], "annotations": ["id2"] }
  }
  ```
- [ ] Remove old `modifications` / `addSeries` / `removeSeries` structure
- [ ] Implement execution order: remove → add → update
- [ ] Implement deep merge for nested objects (yAxis updates)
- [ ] Implement replace for array fields (data)
- [ ] Generate UUIDs for `add.annotations` entries
- [ ] Update output to include `added` section with generated IDs
- [ ] Add validation rules (V010-V012, V020-V022, V030-V044)
- [ ] Update JSON schema description for LLM

---

### Phase 4: Braven Agent Package - Renderer Updates

**Location:** `packages/braven_agent/lib/src/renderer/`

#### 4.1 Chart Renderer Updates

**File:** `packages/braven_agent/lib/src/renderer/chart_renderer.dart`

- [ ] Remove `yAxesLookup` map and `yAxisId` resolution logic
- [ ] Update to read `series[].yAxis` directly
- [ ] Remove `_convertYAxisConfig` helper that resolved references
- [ ] Simplify y-axis config extraction

#### 4.2 Config Parsing Updates

**File:** `packages/braven_agent/lib/src/renderer/config_parser.dart` (or equivalent)

- [ ] Update JSON parsing to handle nested `series[].yAxis`
- [ ] Remove parsing for flat y-axis fields
- [ ] Remove parsing for `yAxes[]` array
- [ ] Add ID generation for annotations during parsing
- [ ] Implement deep merge logic for modify operations

---

### Phase 5: Validation Implementation

**Location:** `packages/braven_agent/lib/src/validation/`

#### 5.1 Create Validation Module

**File:** `packages/braven_agent/lib/src/validation/schema_validator.dart` (NEW)

- [ ] Create validation framework
- [ ] Implement all validation rules:

**Chart-Level (V001-V004):**

- [ ] V001: Warn if `normalizationMode: "perSeries"` AND chart `yAxis` provided
- [ ] V002: Warn if `normalizationMode: "perSeries"` AND series lacks `yAxis`
- [ ] V003: Error if duplicate series `id`
- [ ] V004: Error if duplicate annotation `id`

**Series Modify (V010-V012):**

- [ ] V010: Error if `update.series[].id` not found
- [ ] V011: Error if `remove.series` contains non-existent ID
- [ ] V012: Error if `add.series[].id` already exists

**Annotation ID (V020-V022):**

- [ ] V020: Error if `update.annotations[].id` not found
- [ ] V021: Error if `remove.annotations` contains non-existent ID
- [ ] V022: Warn if agent supplies `id` on create (will be ignored)

**Annotation seriesId (V030-V034):**

- [ ] V030: Error if `seriesId` references non-existent series
- [ ] V031: Error if `type: "point"` without `seriesId`
- [ ] V032: Error if `type: "marker"` without `seriesId`
- [ ] V033: Error if horizontal `referenceLine` in perSeries mode without `seriesId`
- [ ] V034: Error if horizontal `zone` in perSeries mode without `seriesId`

**Type-Specific (V040-V044):**

- [ ] V040: Error if `referenceLine` without `value`
- [ ] V041: Error if `zone` without `minValue` or `maxValue`
- [ ] V042: Error if `point` without `dataPointIndex`
- [ ] V043: Error if `dataPointIndex` out of range
- [ ] V044: Error if `textLabel` without `text`

---

### Phase 6: Test Updates

**Location:** `test/` and `packages/braven_agent/test/`

#### 6.1 BravenChartPlus Core Tests

**Files to audit and update:**

- [ ] `test/unit/models/annotation_config_test.dart` - Add id field tests
- [ ] `test/unit/models/series_config_test.dart` - Nested yAxis tests, remove flat field tests
- [ ] `test/unit/models/chart_configuration_test.dart` - Remove yAxes[] tests
- [ ] `test/unit/rendering/y_axis_resolution_test.dart` - Update for new resolution logic
- [ ] `test/widget/` - Update any widget tests using old schema

**New tests to add:**

- [ ] Test annotation id serialization/deserialization
- [ ] Test nested yAxis serialization/deserialization
- [ ] Test copyWith includes new fields

#### 6.2 Braven Agent Tests

**Files to audit and update:**

- [ ] `packages/braven_agent/test/tools/create_chart_tool_test.dart`
  - [ ] Update to use v2 input schema (no wrapper)
  - [ ] Test annotation ID generation
  - [ ] Test output includes generated IDs
- [ ] `packages/braven_agent/test/tools/modify_chart_tool_test.dart`
  - [ ] Update to use update/add/remove structure
  - [ ] Test deep merge for yAxis updates
  - [ ] Test annotation ID generation on add
  - [ ] Test remove operations
  - [ ] Test execution order (remove → add → update)

- [ ] `packages/braven_agent/test/renderer/chart_renderer_test.dart`
  - [ ] Remove yAxisId resolution tests
  - [ ] Add nested yAxis resolution tests

**New test files:**

- [ ] `packages/braven_agent/test/tools/get_chart_tool_test.dart` (NEW)
  - [ ] Test basic retrieval
  - [ ] Test `includeData: false` (default) - data replaced with count
  - [ ] Test `includeData: true` - full data returned
  - [ ] Test error on non-existent chart

- [ ] `packages/braven_agent/test/validation/schema_validator_test.dart` (NEW)
  - [ ] Test each validation rule (V001-V044)
  - [ ] Test error messages are helpful
  - [ ] Test warnings vs errors

#### 6.3 Integration Tests

- [ ] `test/integration/agentic_flow_test.dart` - Full create → get → modify flow
- [ ] Test annotation lifecycle: create → get ID → update → remove

---

### Phase 7: Documentation Updates

#### 7.1 API Documentation

- [ ] Update inline dartdoc comments for all changed classes
- [ ] Document annotation `id` lifecycle
- [ ] Document nested `yAxis` pattern

#### 7.2 Example Updates

**File:** `example/lib/demos/braven_agent_demo.dart`

- [ ] Update any hardcoded tool calls to use v2 schema
- [ ] Verify demo still works with schema changes

---

### Phase 8: Migration / Cleanup

#### 8.1 Remove Deprecated Code

- [ ] Delete any backward compatibility shims (none - breaking change)
- [ ] Remove unused imports
- [ ] Remove dead code paths for old schema

#### 8.2 Final Audit

- [ ] Run `flutter analyze` on all changed files
- [ ] Run full test suite
- [ ] Manual testing of agentic flow in demo app
- [ ] Verify annotation create → update → remove cycle works

---

## File Change Summary

| Package           | File                                         | Change Type                               |
| ----------------- | -------------------------------------------- | ----------------------------------------- |
| braven_chart_plus | `lib/src/models/annotation_config.dart`      | MODIFY - add `id` field                   |
| braven_chart_plus | `lib/src/models/series_config.dart`          | MODIFY - nested yAxis, remove flat fields |
| braven_chart_plus | `lib/src/models/chart_configuration.dart`    | MODIFY - remove yAxes[]                   |
| braven_chart_plus | `lib/src/models/y_axis_config.dart`          | VERIFY - position field                   |
| braven_chart_plus | `lib/src/rendering/*`                        | MODIFY - yAxis resolution                 |
| braven_agent      | `lib/src/tools/get_chart_tool.dart`          | NEW                                       |
| braven_agent      | `lib/src/tools/create_chart_tool.dart`       | MODIFY - schema, output                   |
| braven_agent      | `lib/src/tools/modify_chart_tool.dart`       | MAJOR REWRITE                             |
| braven_agent      | `lib/src/renderer/chart_renderer.dart`       | MODIFY - remove yAxisId lookup            |
| braven_agent      | `lib/src/validation/schema_validator.dart`   | NEW                                       |
| braven_agent      | `test/tools/get_chart_tool_test.dart`        | NEW                                       |
| braven_agent      | `test/validation/schema_validator_test.dart` | NEW                                       |
| All               | Various test files                           | MODIFY                                    |

---

## Open Questions

_None - all questions resolved._

---

## Resolved Decisions

1. **Annotation `id`**: System-generated, not agent-supplied. Agent sees id in tool output / get_chart, uses it for update/remove operations. ID is a settable field on the annotation object (same pattern as series).

2. **Annotation `seriesId`**: Required for some annotation types (point, marker) always; required for horizontal referenceLine/zone only in perSeries mode. Validation is strict and contextual.

3. **Backward compatibility**: None. V2 schema is a breaking change. V1 flat fields (`yAxisPosition`, `yAxisLabel`, etc.) and `yAxes[]` array will be removed immediately. No deprecation period.

4. **Chart-level yAxis position**: Fully configurable via `yAxis.position`. Agent can set left, right, leftOuter, or rightOuter. Same schema as series-level yAxis.

5. **Data in get_chart**: By default, `get_chart` excludes series data (returns `"data": { "count": N }` instead). Optional `includeData: true` parameter returns full data array. Data optimization (truncation, summarization) deferred to Braven Lab Suite phase.
