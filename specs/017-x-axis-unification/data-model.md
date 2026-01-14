# Data Model: X-Axis Architecture Unification

**Feature**: 017-x-axis-unification  
**Date**: 2025-01-14

---

## Entity Definitions

### XAxisConfig

Configuration model for X-axis properties. Parallel structure to `YAxisConfig`.

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| id | String | Yes | - | Unique identifier for axis reference |
| position | XAxisPosition | No | bottom | Top or bottom of chart |
| label | String | No | '' | Axis title text |
| unit | String | No | '' | Unit suffix for labels (e.g., 's', 'ms') |
| labelDisplay | AxisLabelDisplay | No | labelWithUnit | How to display label and units |
| color | Color? | No | null | Explicit color (null = derive from series) |
| visible | bool | No | true | Whether axis is rendered |
| tickCount | int | No | 5 | Target number of tick marks |
| tickLabelPadding | double | No | 4.0 | Spacing between tick and label |
| axisLabelPadding | double | No | 5.0 | Spacing between tick labels and axis label |
| axisMargin | double | No | 8.0 | Margin around entire axis |
| labelFormatter | Function? | No | null | Custom tick value formatter |
| showCrosshairLabel | bool | No | false | Show X-value on crosshair hover |
| crosshairLabelPosition | CrosshairLabelPosition | No | overAxis | Where crosshair label appears |

**Validation Rules**:
- `id` must be non-empty and unique within chart
- `tickCount` must be >= 1
- Padding/margin values must be >= 0

---

### XAxisPosition

Enum defining valid X-axis positions.

| Value | Description |
|-------|-------------|
| top | X-axis rendered above plot area |
| bottom | X-axis rendered below plot area (default) |

**Note**: `topOuter` and `bottomOuter` deferred to future sprint (multi-axis support).

---

### SeriesAxisBinding (Extended)

Extended binding model for series-to-axis relationships.

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| seriesId | String | Yes | - | Reference to ChartSeries.id |
| yAxisId | String | Yes | - | Reference to YAxisConfig.id |
| xAxisId | String | No | null | Reference to XAxisConfig.id (null = chart default) |

**Backward Compatibility**: Existing bindings with only `seriesId` and `yAxisId` continue working.

---

### ChartSeries (Extended)

Extended series model with optional per-series X-axis configuration.

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| (existing fields) | ... | ... | ... | All existing properties unchanged |
| xAxisConfig | XAxisConfig? | No | null | Per-series X-axis configuration |
| xAxisId | String? | No | null | Reference to shared XAxisConfig |

**Precedence**: `xAxisConfig` > `xAxisId` reference > chart-level `xAxisConfig`

---

## Enum Reuse

The following enums from `y_axis_config.dart` are reused without modification:

### AxisLabelDisplay

| Value | Label Shown | Tick Unit Shown |
|-------|-------------|-----------------|
| labelOnly | Yes | No |
| labelWithUnit | Yes (with unit) | No |
| labelAndTickUnit | Yes | Yes |
| labelWithUnitAndTickUnit | Yes (with unit) | Yes |
| tickUnitOnly | No | Yes |
| unitInLabel | Yes (unit only) | No |
| noLabels | No | No |

### CrosshairLabelPosition

| Value | Description |
|-------|-------------|
| overAxis | Label in axis strip area outside plot |
| insidePlot | Label inside plot area near axis edge |

---

## Relationships

```
┌─────────────────┐
│  BravenChartPlus │
│─────────────────│
│ xAxisConfig?    │───────────────┐
│ xAxis? (legacy) │               │
│ yAxisConfigs[]  │               │
│ series[]        │               │
└─────────────────┘               │
        │                         ▼
        │                 ┌───────────────┐
        │                 │  XAxisConfig  │
        │                 │───────────────│
        │                 │ id            │
        │                 │ position      │
        │                 │ label, unit   │
        │                 │ color?        │
        │                 └───────────────┘
        │                         ▲
        ▼                         │
┌─────────────────┐               │
│   ChartSeries   │               │
│─────────────────│               │
│ id              │               │
│ xAxisConfig?    │───────────────┘
│ xAxisId?        │───────────────┘ (reference)
│ yAxisConfig?    │
└─────────────────┘
        │
        ▼
┌───────────────────┐
│ SeriesAxisBinding │
│───────────────────│
│ seriesId          │
│ yAxisId           │
│ xAxisId?          │
└───────────────────┘
```

---

## State Transitions

XAxisConfig is immutable (following Flutter conventions). State changes require creating new config instances.

**Visibility State**:
- `visible: true` → Axis renders normally
- `visible: false` → Axis hidden, but data scaling uses its range

**Color Resolution State**:
- `color: explicit` → Use explicit color
- `color: null, series bound` → Derive from first series
- `color: null, no series` → Use default gray

---

## Validation Rules Summary

| Entity | Rule | Error |
|--------|------|-------|
| XAxisConfig | id non-empty | ArgumentError |
| XAxisConfig | tickCount >= 1 | ArgumentError |
| XAxisConfig | padding/margin >= 0 | ArgumentError |
| SeriesAxisBinding | seriesId non-empty | ArgumentError |
| SeriesAxisBinding | yAxisId non-empty | ArgumentError |
