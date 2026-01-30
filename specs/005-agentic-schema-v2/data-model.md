# Data Model: Agentic Schema V2

**Feature**: 005-agentic-schema-v2  
**Date**: 2025-01-20  
**Source**: `specs/_base/005-agentic-schema-v2/schema_spec.md`

## Entity Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                     ChartConfiguration                          │
│  ┌─────────────┐  ┌──────────────┐  ┌─────────────────────────┐ │
│  │  XAxisConfig │  │  YAxisConfig  │  │  normalizationMode     │ │
│  │  (optional)  │  │  (optional)   │  │  none|auto|perSeries   │ │
│  └─────────────┘  └──────────────┘  └─────────────────────────┘ │
│                                                                  │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │  series: SeriesConfig[]                                    │  │
│  │  ┌─────────────────────────────────────────────────────┐  │  │
│  │  │  SeriesConfig                                        │  │  │
│  │  │  • id: string (required, unique)                     │  │  │
│  │  │  • name: string                                      │  │  │
│  │  │  • type: line|area|bar|scatter|step                  │  │  │
│  │  │  • data: DataPoint[]                                 │  │  │
│  │  │  • color, style, ...                                 │  │  │
│  │  │  ┌────────────────────────────────────┐              │  │  │
│  │  │  │  yAxis: YAxisConfig (optional)     │              │  │  │
│  │  │  │  • label, unit, position, color    │              │  │  │
│  │  │  │  • min, max, autoRange, includeZero│              │  │  │
│  │  │  │  • showTicks, showAxisLine, ...    │              │  │  │
│  │  │  └────────────────────────────────────┘              │  │  │
│  │  └─────────────────────────────────────────────────────┘  │  │
│  └───────────────────────────────────────────────────────────┘  │
│                                                                  │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │  annotations: AnnotationConfig[] (optional)                │  │
│  │  ┌─────────────────────────────────────────────────────┐  │  │
│  │  │  AnnotationConfig                                    │  │  │
│  │  │  • id: string (system-generated, unique)             │  │  │
│  │  │  • type: referenceLine|zone|textLabel|marker|point   │  │  │
│  │  │  • seriesId: string (optional, required for some)    │  │  │
│  │  │  • [type-specific fields]                            │  │  │
│  │  └─────────────────────────────────────────────────────┘  │  │
│  └───────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
```

## Core Entities

### ChartConfiguration

The root configuration object for a chart.

| Field               | Type                 | Required | Description                                 |
| ------------------- | -------------------- | -------- | ------------------------------------------- |
| `title`             | `string`             | No       | Chart title                                 |
| `xAxis`             | `XAxisConfig`        | No       | X-axis configuration                        |
| `yAxis`             | `YAxisConfig`        | No       | Chart-level Y-axis (default for all series) |
| `normalizationMode` | `enum`               | No       | `none` (default), `auto`, `perSeries`       |
| `series`            | `SeriesConfig[]`     | Yes      | Array of data series (min 1)                |
| `annotations`       | `AnnotationConfig[]` | No       | Array of chart annotations                  |
| `style`             | `ChartStyleConfig`   | No       | Visual styling options                      |

**Constraints:**

- At least one series required
- If `normalizationMode: "perSeries"`, chart-level `yAxis` is ignored (warning V001)
- All series `id` values must be unique (error V003)
- All annotation `id` values must be unique (error V004)

---

### SeriesConfig

Configuration for a single data series.

| Field   | Type                | Required | Description                                          |
| ------- | ------------------- | -------- | ---------------------------------------------------- |
| `id`    | `string`            | Yes      | Unique identifier (agent-provided or auto-generated) |
| `name`  | `string`            | No       | Display name for legend                              |
| `type`  | `enum`              | No       | `line` (default), `area`, `bar`, `scatter`, `step`   |
| `data`  | `DataPoint[]`       | Yes      | Array of data points                                 |
| `color` | `string`            | No       | Series color (hex or named)                          |
| `yAxis` | `YAxisConfig`       | No       | Per-series Y-axis configuration                      |
| `style` | `SeriesStyleConfig` | No       | Line width, markers, etc.                            |

**Constraints:**

- `id` must be unique across all series in the chart
- If `normalizationMode: "perSeries"` and series lacks `yAxis`, warning V002

**Removed Fields (v1 → v2):**

- ~~`yAxisId`~~ - Use nested `yAxis` instead
- ~~`yAxisPosition`~~ - Use `yAxis.position`
- ~~`yAxisLabel`~~ - Use `yAxis.label`
- ~~`yAxisUnit`~~ - Use `yAxis.unit`
- ~~`yAxisColor`~~ - Use `yAxis.color`
- ~~`yAxisMin`~~ - Use `yAxis.min`
- ~~`yAxisMax`~~ - Use `yAxis.max`

---

### YAxisConfig

Configuration for a Y-axis (chart-level or per-series).

| Field           | Type      | Required | Description                                          |
| --------------- | --------- | -------- | ---------------------------------------------------- |
| `label`         | `string`  | No       | Axis label text                                      |
| `unit`          | `string`  | No       | Unit suffix (e.g., "km/h", "°C")                     |
| `position`      | `enum`    | No       | `left` (default), `right`, `leftOuter`, `rightOuter` |
| `color`         | `string`  | No       | Axis color (hex or named)                            |
| `min`           | `number`  | No       | Fixed minimum value                                  |
| `max`           | `number`  | No       | Fixed maximum value                                  |
| `autoRange`     | `boolean` | No       | Auto-calculate range from data (default: true)       |
| `includeZero`   | `boolean` | No       | Ensure zero is in range (default: false)             |
| `showTicks`     | `boolean` | No       | Show tick marks (default: true)                      |
| `showAxisLine`  | `boolean` | No       | Show axis line (default: true)                       |
| `showGridLines` | `boolean` | No       | Show horizontal grid lines (default: false)          |

---

### XAxisConfig

Configuration for the X-axis.

| Field           | Type      | Required | Description                                 |
| --------------- | --------- | -------- | ------------------------------------------- |
| `label`         | `string`  | No       | Axis label text                             |
| `type`          | `enum`    | No       | `numeric` (default), `datetime`, `category` |
| `format`        | `string`  | No       | Value format pattern                        |
| `showTicks`     | `boolean` | No       | Show tick marks (default: true)             |
| `showAxisLine`  | `boolean` | No       | Show axis line (default: true)              |
| `showGridLines` | `boolean` | No       | Show vertical grid lines (default: false)   |

---

### AnnotationConfig

Configuration for chart annotations.

| Field            | Type                    | Required    | Description                                             |
| ---------------- | ----------------------- | ----------- | ------------------------------------------------------- |
| `id`             | `string`                | Auto        | System-generated UUID (returned in output)              |
| `type`           | `enum`                  | Yes         | `referenceLine`, `zone`, `textLabel`, `marker`, `point` |
| `seriesId`       | `string`                | Conditional | Required for some types (see constraints)               |
| `orientation`    | `enum`                  | Conditional | `horizontal`, `vertical` (for referenceLine, zone)      |
| `value`          | `number`                | Conditional | For referenceLine                                       |
| `minValue`       | `number`                | Conditional | For zone                                                |
| `maxValue`       | `number`                | Conditional | For zone                                                |
| `text`           | `string`                | Conditional | For textLabel                                           |
| `dataPointIndex` | `integer`               | Conditional | For point                                               |
| `x`              | `number`                | Conditional | X position for marker, textLabel                        |
| `y`              | `number`                | Conditional | Y position for marker, textLabel                        |
| `color`          | `string`                | No          | Annotation color                                        |
| `style`          | `AnnotationStyleConfig` | No          | Additional styling                                      |

**seriesId Requirements:**

| Type                         | seriesId Required?       |
| ---------------------------- | ------------------------ |
| `point`                      | Always                   |
| `marker`                     | Always                   |
| `referenceLine` (horizontal) | Only in `perSeries` mode |
| `zone` (horizontal)          | Only in `perSeries` mode |
| `referenceLine` (vertical)   | Never                    |
| `zone` (vertical)            | Never                    |
| `textLabel`                  | Never                    |

---

### DataPoint

A single data point in a series.

| Field | Type     | Required | Description  |
| ----- | -------- | -------- | ------------ |
| `x`   | `number` | Yes      | X-axis value |
| `y`   | `number` | Yes      | Y-axis value |

---

## Normalization Modes

| Mode        | Behavior                         | Y-Axis Source       |
| ----------- | -------------------------------- | ------------------- |
| `none`      | No normalization, raw values     | Chart-level `yAxis` |
| `auto`      | Auto-scale all series together   | Chart-level `yAxis` |
| `perSeries` | Each series scaled independently | `series[].yAxis`    |

---

## ID Generation

### Series ID

- Agent SHOULD provide `id` when creating series
- If not provided, system generates UUID
- Used for update/remove operations

### Annotation ID

- Agent SHOULD NOT provide `id` (will be ignored with warning V022)
- System always generates UUID
- Returned in tool output `added.annotations[].id`
- Used for update/remove operations

---

## Related Documents

- [schema_spec.md](../../../specs/_base/005-agentic-schema-v2/schema_spec.md) - Full JSON schema definitions
- [spec.md](spec.md) - Functional requirements
- [contracts/](contracts/) - Tool interface contracts
