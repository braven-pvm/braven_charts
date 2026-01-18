# Data Model: X-Axis Renderer Unification

**Feature**: 018-x-axis-renderer  
**Date**: 2026-01-18

## Entities

### XAxisConfig

Configuration object for X-axis appearance and behavior.

**Purpose**: Provides all configuration options for the X-axis, mirroring YAxisConfig API but simplified for single-axis use.

**Properties**:

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `color` | `Color?` | null (→ first series) | Themed color for all axis elements |
| `label` | `String?` | null | Axis title text (e.g., ""Time"") |
| `unit` | `String?` | null | Unit suffix (e.g., ""s"", ""km"") |
| `min` | `double?` | null (→ data min) | Explicit minimum X value |
| `max` | `double?` | null (→ data max) | Explicit maximum X value |
| `visible` | `bool` | true | Whether to render the axis |
| `showAxisLine` | `bool` | true | Show horizontal axis line |
| `showTicks` | `bool` | true | Show tick marks |
| `showCrosshairLabel` | `bool` | true | Show crosshair X-value label |
| `labelDisplay` | `AxisLabelDisplay` | labelWithUnit | How to display label/unit |
| `minHeight` | `double` | 0.0 | Minimum height of X-axis area |
| `maxHeight` | `double` | 60.0 | Maximum height of X-axis area |
| `tickLabelPadding` | `double` | 4.0 | Gap between tick and label |
| `axisLabelPadding` | `double` | 5.0 | Gap between labels and title |
| `axisMargin` | `double` | 8.0 | Margin from plot area |
| `tickCount` | `int?` | null (→ auto) | Preferred tick count |
| `labelFormatter` | `XAxisLabelFormatter?` | null | Custom value formatter |

**Validation Rules**:
- `minHeight` must be >= 0
- `maxHeight` must be >= `minHeight`
- If both `min` and `max` are set, `min` must be < `max`
- `tickCount` if set must be >= 2

**Computed Properties**:
- `shouldShowAxisLabel` → true if label is non-empty and labelDisplay includes label
- `shouldShowTickLabels` → true based on labelDisplay mode
- `shouldShowTickUnit` → true if labelDisplay includes tick unit
- `shouldAppendUnitToLabel` → true if labelDisplay appends unit to label

### XAxisPainter

Rendering component for X-axis painting.

**Purpose**: Paints the X-axis with themed styling matching MultiAxisPainter behavior.

**Properties**:

| Property | Type | Description |
|----------|------|-------------|
| `config` | `XAxisConfig` | Configuration for rendering |
| `axisBounds` | `DataRange` | Min/max X values for tick generation |
| `series` | `List<ChartSeries>?` | For color resolution |
| `labelStyle` | `TextStyle` | Text style for tick labels |

**Methods**:

| Method | Returns | Description |
|--------|---------|-------------|
| `paint(canvas, chartArea, plotArea)` | void | Main paint method |
| `generateTicks(bounds, {maxTicks})` | `List<double>` | Nice-number tick generation |
| `formatTickLabel(value)` | `String` | Format tick value with optional unit |
| `resolveAxisColor()` | `Color` | Resolve color from config/series/theme |

**Internal Methods**:
- `_paintAxisLine(canvas, plotArea, color)`
- `_paintTickMark(canvas, plotArea, x, color)`
- `_paintTickLabel(canvas, plotArea, x, value, color)`
- `_paintAxisLabel(canvas, plotArea, color)`
- `_niceNum(range, {round})`

**Caching**:
- `_tickLabelCache`: Map<double, TextPainter> for tick labels
- `_axisLabelCache`: TextPainter for axis title
- `_previousAxisBounds`: For cache invalidation
- `_previousLabelStyle`: For cache invalidation

### DataRange (Existing)

Represents a min/max range for axis values.

| Property | Type | Description |
|----------|------|-------------|
| `min` | `double` | Minimum value |
| `max` | `double` | Maximum value |
| `span` | `double` | Computed: max - min |

### AxisLabelDisplay (Existing - Reused)

Enum controlling how axis labels and units are displayed.

| Value | Axis Label | Tick Labels |
|-------|------------|-------------|
| `labelOnly` | ""Power"" | ""250"", ""500"" |
| `labelWithUnit` | ""Power (W)"" | ""250"", ""500"" |
| `labelAndTickUnit` | ""Power"" | ""250 W"", ""500 W"" |
| `labelWithUnitAndTickUnit` | ""Power (W)"" | ""250 W"", ""500 W"" |
| `tickUnitOnly` | (none) | ""250 W"", ""500 W"" |
| `tickOnly` | (none) | ""250"", ""500"" |
| `none` | (none) | ""250"", ""500"" |

## Relationships

`
BravenChartPlus
    │
    ├── xAxisConfig: XAxisConfig?
    │
    └─▶ ChartRenderBox
            │
            ├── _xAxisConfig: XAxisConfig
            ├── _xAxisPainter: XAxisPainter
            │
            └─▶ CrosshairRenderer
                    │
                    └── xAxisConfig: XAxisConfig?
`

## State Transitions

XAxisConfig is immutable. State changes are handled by:
1. Widget rebuild with new XAxisConfig
2. ChartRenderBox detects change and updates painter
3. Painter invalidates caches if bounds/style changed
4. Next paint cycle uses new configuration
