# API Contracts: Axis Renderer Unification

**Feature**: 013-axis-renderer-unification  
**Date**: 2025-12-11

---

## Overview

This document defines the public API contracts for the axis renderer unification refactor.

---

## Public API Changes

### BravenChartPlus Widget

```dart
/// Main chart widget with unified axis configuration.
class BravenChartPlus extends StatefulWidget {
  const BravenChartPlus({
    Key? key,
    required this.series,
    // Y-AXIS: BREAKING CHANGE - type changed from AxisConfig? to YAxisConfig?
    this.yAxis,                    // YAxisConfig? (was AxisConfig?)
    this.xAxis,                    // AxisConfig? (unchanged, XAxisConfig in Phase 5)
    this.grid,                     // NEW: GridConfig?
    // ... other properties unchanged
  });

  /// Y-axis configuration. If null and no series has yAxisConfig,
  /// a default left-side Y-axis is auto-created.
  final YAxisConfig? yAxis;

  /// Chart-level grid configuration. Controls horizontal and vertical
  /// grid lines independently.
  final GridConfig? grid;
}
```

---

### YAxisConfig Model

```dart
/// Configuration for Y-axis appearance and behavior.
class YAxisConfig {
  const YAxisConfig({
    this.position = YAxisPosition.left,
    this.label,
    this.unit,
    this.color,
    this.visible = true,
    this.showAxisLine = true,
    this.showTicks = true,
    this.showCrosshairLabel = false,
    this.crosshairLabelPosition = CrosshairLabelPosition.overAxis, // NEW
    this.min,
    this.max,
    this.minWidth = 40,
    this.maxWidth = 80,
    this.tickCount = 5,
    this.labelFormatter,
    this.decimalPlaces,
    this.labelDisplay = AxisLabelDisplay.label,
    this.axisMargin = 4,
    this.tickLabelPadding = 4,
  });

  /// NEW: Where to position the crosshair label when showCrosshairLabel is true.
  final CrosshairLabelPosition crosshairLabelPosition;

  // ... existing properties unchanged

  /// Creates a copy with specified fields replaced.
  YAxisConfig copyWith({
    // ... existing parameters
    CrosshairLabelPosition? crosshairLabelPosition, // NEW
  });
}
```

---

### CrosshairLabelPosition Enum

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

### GridConfig Model

```dart
/// Chart-level configuration for grid line visibility and styling.
@immutable
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

  /// Creates a copy with specified fields replaced.
  GridConfig copyWith({
    bool? horizontal,
    bool? vertical,
    Color? horizontalColor,
    Color? verticalColor,
    double? horizontalStrokeWidth,
    double? verticalStrokeWidth,
  });

  @override
  bool operator ==(Object other);

  @override
  int get hashCode;
}
```

---

## Migration Contract

### Before (AxisConfig)

```dart
BravenChartPlus(
  yAxis: AxisConfig(
    label: 'Power',
    axisColor: Colors.blue,
    showGrid: true,
  ),
  series: [...],
)
```

### After (YAxisConfig + GridConfig)

```dart
BravenChartPlus(
  yAxis: YAxisConfig(
    label: 'Power',
    color: Colors.blue,  // Note: 'color' not 'axisColor'
    unit: 'W',           // NEW: unit support
    showCrosshairLabel: true,  // NEW: crosshair integration
  ),
  grid: GridConfig(horizontal: true, vertical: true),  // Grid moved to chart level
  series: [...],
)
```

---

## Behavioral Contracts

### Default Y-Axis Auto-Creation

**Contract**: When `yAxis` is null AND no series has `yAxisConfig`:
- System MUST auto-create `YAxisConfig(position: YAxisPosition.left)`
- Internal ID: `_primary`
- Range: Auto-scaled from series data

### Grid Rendering Order

**Contract**: Grid lines MUST be painted in this order (back to front):
1. Horizontal grid lines (Y-axis tick positions)
2. Vertical grid lines (X-axis tick positions)
3. Y-axes (via MultiAxisPainter)
4. X-axis (via XAxisRenderer)
5. Data series

### Crosshair Label Positioning

**Contract**: When `showCrosshairLabel: true`:
- `CrosshairLabelPosition.overAxis`: Label appears in axis strip area (outside plot)
- `CrosshairLabelPosition.insidePlot`: Label appears inside plot area near axis edge
