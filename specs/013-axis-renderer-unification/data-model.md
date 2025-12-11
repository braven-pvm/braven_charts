# Data Model: Axis Renderer Unification

**Feature**: 013-axis-renderer-unification  
**Date**: 2025-12-11

---

## Entity Overview

This refactor modifies existing entities and adds new ones to unify axis rendering.

---

## Modified Entities

### YAxisConfig (Modified)

**File**: `lib/src/models/y_axis_config.dart`

**New Properties**:

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `crosshairLabelPosition` | `CrosshairLabelPosition` | `overAxis` | Controls where crosshair Y-value label appears |

**Validation Rules**:
- `crosshairLabelPosition` must be a valid enum value
- Existing validation rules unchanged (minWidth, maxWidth, min/max, tickCount)

---

### BravenChartPlus (Modified)

**File**: `lib/src/braven_chart_plus.dart`

**Property Changes**:

| Property | Old Type | New Type | Notes |
|----------|----------|----------|-------|
| `yAxis` | `AxisConfig?` | `YAxisConfig?` | Breaking change |
| `grid` | N/A (new) | `GridConfig?` | Chart-level grid control |

---

## New Entities

### CrosshairLabelPosition (Enum)

**File**: `lib/src/models/y_axis_config.dart`

```dart
/// Controls where the crosshair Y-value label is positioned.
enum CrosshairLabelPosition {
  /// Label is positioned over the axis area (outside the plot area).
  /// This is the default behavior for multi-axis mode.
  overAxis,

  /// Label is positioned inside the plot area, near the axis edge.
  /// Similar to the default "Y: value" crosshair label behavior.
  insidePlot,
}
```

---

### GridConfig (New)

**File**: `lib/src/models/grid_config.dart`

```dart
/// Chart-level configuration for grid line visibility and styling.
class GridConfig {
  const GridConfig({
    this.horizontal = true,
    this.vertical = true,
    this.horizontalColor,
    this.verticalColor,
    this.horizontalStrokeWidth = 0.5,
    this.verticalStrokeWidth = 0.5,
  });

  /// Whether to show horizontal grid lines (at Y-axis tick positions).
  final bool horizontal;

  /// Whether to show vertical grid lines (at X-axis tick positions).
  final bool vertical;

  /// Color for horizontal grid lines. Falls back to theme if null.
  final Color? horizontalColor;

  /// Color for vertical grid lines. Falls back to theme if null.
  final Color? verticalColor;

  /// Stroke width for horizontal grid lines.
  final double horizontalStrokeWidth;

  /// Stroke width for vertical grid lines.
  final double verticalStrokeWidth;
}
```

**Validation Rules**:
- `horizontalStrokeWidth` must be > 0
- `verticalStrokeWidth` must be > 0

---

### XAxisConfig (New - Phase 5)

**File**: `lib/src/models/x_axis_config.dart`

```dart
/// Configuration for X-axis appearance and behavior.
/// Mirrors YAxisConfig property naming for API consistency.
class XAxisConfig {
  const XAxisConfig({
    this.position = XAxisPosition.bottom,
    this.label,
    this.unit,
    this.color,
    this.visible = true,
    this.showAxisLine = true,
    this.showTicks = true,
    this.min,
    this.max,
    this.labelFormatter,
    this.decimalPlaces,
    this.labelDisplay = AxisLabelDisplay.label,
  });

  final XAxisPosition position;
  final String? label;
  final String? unit;
  final Color? color;
  final bool visible;
  final bool showAxisLine;
  final bool showTicks;
  final double? min;
  final double? max;
  final String Function(double)? labelFormatter;
  final int? decimalPlaces;
  final AxisLabelDisplay labelDisplay;
}

/// Type-safe X-axis positions.
enum XAxisPosition { top, bottom }
```

---

### GridRenderer (New)

**File**: `lib/src/rendering/grid_renderer.dart`

```dart
/// Renders chart grid lines independent of axis rendering.
/// Grid lines are painted BEFORE data series (behind them).
class GridRenderer {
  const GridRenderer({this.theme, this.config});
  
  final ChartTheme? theme;
  final GridConfig? config;

  /// Paints horizontal grid lines at the specified Y positions.
  void paintHorizontalGrid(
    Canvas canvas,
    Rect plotArea,
    List<double> yPositions,
  );

  /// Paints vertical grid lines at the specified X positions.
  void paintVerticalGrid(
    Canvas canvas,
    Rect plotArea,
    List<double> xPositions,
  );
}
```

---

## Entity Relationships

```
BravenChartPlus
├── yAxis: YAxisConfig? (CHANGED from AxisConfig?)
│   └── crosshairLabelPosition: CrosshairLabelPosition (NEW)
├── xAxis: XAxisConfig? (NEW - Phase 5, replaces AxisConfig for X)
├── grid: GridConfig? (NEW)
└── series: List<ChartSeries>
    └── yAxisConfig: YAxisConfig (unchanged)

Rendering Pipeline
├── GridRenderer (NEW)
│   └── config: GridConfig?
├── MultiAxisPainter (MODIFIED - unified Y-axis path)
│   └── _tickLabelCache: Map<String, Map<double, TextPainter>> (NEW)
├── XAxisRenderer (RENAMED from AxisRenderer)
│   └── (Y-axis code removed, grid code removed)
└── CrosshairRenderer (MODIFIED)
    └── Respects YAxisConfig.crosshairLabelPosition
```

---

## State Transitions

### Default Y-Axis Auto-Creation

**Trigger**: `BravenChartPlus.yAxis` is null AND no series has `yAxisConfig`

**Transition**:
1. `MultiAxisManager.getEffectiveYAxes()` detects no Y-axes configured
2. System auto-creates: `YAxisConfig(position: YAxisPosition.left)`
3. Internal ID assigned: `_primary`
4. Axis included in `effectiveYAxes` list

---

## Migration Impact

### Breaking Changes

| Entity | Change | Migration |
|--------|--------|-----------|
| `BravenChartPlus.yAxis` | `AxisConfig?` → `YAxisConfig?` | Replace `AxisConfig(...)` with `YAxisConfig(...)` |
| Grid control | Per-axis `showGrid` | Move to `BravenChartPlus.grid: GridConfig(...)` |
| Property names | `axisColor` | Use `color` instead |

---

## Data Volume Assumptions

- Typical chart: 1-4 Y-axes
- TextPainter cache: ~50-100 entries per axis (tick labels)
- Cache invalidation: On axis config change or data range change
- Memory impact: Minimal (~10KB per axis)
