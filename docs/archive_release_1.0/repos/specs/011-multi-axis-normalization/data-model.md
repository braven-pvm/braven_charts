# Data Model: Multi-Axis Normalization

**Feature**: 011-multi-axis-normalization  
**Date**: 2025-11-27  
**Status**: Complete

---

## Entity Overview

| Entity | Purpose | New/Modified |
|--------|---------|--------------|
| YAxisConfig | Y-axis configuration with bounds, position, color | NEW |
| YAxisPosition | Enum for axis positions (leftOuter, left, right, rightOuter) | NEW |
| NormalizationMode | Enum for normalization behavior | NEW |
| ChartSeries | Base series class - add yAxisId and unit fields | MODIFIED |
| MultiAxisState | Runtime state for computed axis bounds | NEW |

---

## Entity 1: YAxisConfig

### Purpose
Defines configuration for a single Y-axis including position, color, bounds, and display options.

### Fields

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| id | String | Yes | - | Unique identifier for axis binding |
| position | YAxisPosition | Yes | - | Position relative to plot area |
| color | Color? | No | null | Axis color (defaults to first bound series color) |
| label | String? | No | null | Axis label text (e.g., "Power", "Heart Rate") |
| unit | String? | No | null | Unit suffix for tick labels (e.g., "W", "bpm") |
| min | double? | No | null | Explicit minimum (null = auto from data) |
| max | double? | No | null | Explicit maximum (null = auto from data) |
| showTicks | bool | No | true | Whether to show tick marks |
| showAxisLine | bool | No | true | Whether to show axis line |
| showLabels | bool | No | true | Whether to show tick labels |
| minWidth | double | No | 40.0 | Minimum axis width in pixels |
| maxWidth | double | No | 80.0 | Maximum axis width in pixels |
| tickCount | int? | No | null | Preferred tick count (null = auto) |
| labelFormatter | String Function(double)? | No | null | Custom label formatting |

### Validation Rules
- `id` must be non-empty and unique within chart's `yAxes` list
- `position` must be a valid `YAxisPosition` value
- If both `min` and `max` are specified, `min < max`
- `minWidth > 0` and `maxWidth >= minWidth`
- `tickCount` if specified must be >= 2

### Relationships
- One-to-many: One YAxisConfig can be referenced by multiple ChartSeries via `yAxisId`
- Contained by: BravenChartPlus widget's `yAxes` list

---

## Entity 2: YAxisPosition

### Purpose
Enum defining the 4 possible Y-axis positions relative to the plot area.

### Values

| Value | Description | Visual Position |
|-------|-------------|-----------------|
| leftOuter | Leftmost axis | Far left of plot area |
| left | Primary left axis | Adjacent to plot area left edge |
| right | Primary right axis | Adjacent to plot area right edge |
| rightOuter | Rightmost axis | Far right of plot area |

### Layout Order (left to right)
```
[leftOuter] [left] [PLOT AREA] [right] [rightOuter]
```

### Validation Rules
- Maximum 1 axis per position
- If only 2 axes needed, prefer `left` and `right` positions

---

## Entity 3: NormalizationMode

### Purpose
Enum controlling when and how Y-axis normalization is applied.

### Values

| Value | Description | Behavior |
|-------|-------------|----------|
| none | No normalization | Use global Y bounds (current behavior) |
| auto | Automatic detection | Enable when series ranges differ by >10x |
| perSeries | Always normalize | Each series uses full vertical space |

### Default Behavior
- `none`: All series share single Y-axis with global min/max
- `auto`: System analyzes series ranges, enables normalization if needed
- `perSeries`: Each series normalized to [0,1] regardless of range similarity

---

## Entity 4: ChartSeries (Modified)

### New Fields

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| yAxisId | String? | No | null | ID of Y-axis to use (null = primary axis) |
| unit | String? | No | null | Unit for this series (displayed in tooltips) |

### Affected Subclasses
- LineChartSeries
- ScatterChartSeries
- AreaChartSeries
- BarChartSeries

### Backward Compatibility
- `yAxisId: null` → Uses primary (left) axis → Identical to current behavior
- `unit: null` → No unit suffix in tooltips → Identical to current behavior

---

## Entity 5: MultiAxisState

### Purpose
Runtime state computed from series data and axis configurations. Immutable per render frame.

### Fields

| Field | Type | Description |
|-------|------|-------------|
| axisConfigs | Map<String, YAxisConfig> | Axis ID → config mapping |
| axisBounds | Map<String, DataRange> | Axis ID → computed data bounds |
| seriesAxisMap | Map<String, String> | Series ID → axis ID mapping |
| axisWidths | Map<String, double> | Axis ID → computed width in pixels |
| isMultiAxisActive | bool | Whether multi-axis rendering is active |

### Computed Properties
- `leftAxes`: List of axes positioned on left (leftOuter, left)
- `rightAxes`: List of axes positioned on right (right, rightOuter)
- `totalLeftWidth`: Sum of left axis widths
- `totalRightWidth`: Sum of right axis widths
- `effectiveChartArea`: Plot area after axis width deduction

### Lifecycle
1. Created during layout phase from `yAxes` config and series data
2. Used during paint phase for normalization and axis rendering
3. Discarded after frame complete
4. Recreated on data or config change

---

## Entity Relationships

```
BravenChartPlus
├── yAxes: List<YAxisConfig>          [0..4]
├── normalizationMode: NormalizationMode
└── series: List<ChartSeries>         [0..n]
    └── yAxisId: String? ─────────────► YAxisConfig.id

MultiAxisState (computed at runtime)
├── axisConfigs ◄── yAxes
├── axisBounds ◄── computed from series data
├── seriesAxisMap ◄── series.yAxisId → axis.id
└── axisWidths ◄── computed from label widths
```

---

## State Transitions

### Normalization Mode Transitions

```
┌─────────────┐     multiple series      ┌─────────────┐
│    none     │ ────────────────────────►│  Evaluate   │
└─────────────┘     with yAxes config    └─────────────┘
                                               │
                         ┌─────────────────────┼─────────────────────┐
                         │                     │                     │
                         ▼                     ▼                     ▼
                  ┌─────────────┐       ┌─────────────┐       ┌─────────────┐
                  │ Single Axis │       │ Multi-Axis  │       │ Multi-Axis  │
                  │ (no change) │       │ (auto)      │       │ (explicit)  │
                  └─────────────┘       └─────────────┘       └─────────────┘
```

### Axis Bounds Computation

```
For each YAxisConfig:
  1. Find all series where series.yAxisId == axis.id
  2. If axis.min specified → use axis.min
     Else → min(series.points.y) for all bound series
  3. If axis.max specified → use axis.max
     Else → max(series.points.y) for all bound series
  4. Store in axisBounds[axis.id]
```

---

## Validation Matrix

| Entity | Validation | Error Type |
|--------|------------|------------|
| YAxisConfig | id non-empty | ArgumentError |
| YAxisConfig | min < max (if both set) | ArgumentError |
| YAxisConfig | unique id within yAxes | StateError |
| YAxisConfig | ≤4 axes total | StateError |
| YAxisConfig | ≤1 axis per position | StateError |
| ChartSeries | yAxisId exists in yAxes (if not null) | StateError |
| NormalizationMode | Valid enum value | N/A (type-safe) |

---

## Migration Path

### From Single-Axis (Current)
```dart
// Before (single axis)
BravenChartPlus(
  series: [series1, series2],
)

// After (backward compatible - no changes needed)
BravenChartPlus(
  series: [series1, series2], // yAxisId null = primary axis
)
```

### To Multi-Axis (Explicit)
```dart
BravenChartPlus(
  yAxes: [
    YAxisConfig(id: 'power', position: YAxisPosition.left, unit: 'W'),
    YAxisConfig(id: 'heartRate', position: YAxisPosition.right, unit: 'bpm'),
  ],
  series: [
    LineChartSeries(id: 'power', yAxisId: 'power', ...),
    LineChartSeries(id: 'hr', yAxisId: 'heartRate', ...),
  ],
)
```

### Auto-Detection Mode
```dart
BravenChartPlus(
  normalizationMode: NormalizationMode.auto, // System decides
  series: [series1, series2], // Ranges analyzed automatically
)
```

---

*Data Model Complete: 2025-11-27*
