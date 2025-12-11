# Quickstart: Axis Renderer Unification

**Feature**: 013-axis-renderer-unification  
**Date**: 2025-12-11

---

## Overview

This guide explains how to use the unified axis rendering API after the refactor.

---

## Simple Chart (Default Y-Axis)

The simplest chart requires no axis configuration - a default Y-axis on the left is auto-created:

```dart
import 'package:braven_charts/braven_charts.dart';

BravenChartPlus(
  series: [
    ChartSeries(
      data: [
        ChartDataPoint(x: 0, y: 10),
        ChartDataPoint(x: 1, y: 25),
        ChartDataPoint(x: 2, y: 15),
      ],
    ),
  ],
)
```

**Result**: Chart with auto-scaled left Y-axis, auto-scaled X-axis, and default grid.

---

## Single Y-Axis with Modern Features

Configure a single Y-axis with units, crosshair labels, and custom positioning:

```dart
BravenChartPlus(
  yAxis: YAxisConfig(
    position: YAxisPosition.right,  // Or: left, leftOuter, rightOuter
    label: 'Power',
    unit: 'kW',
    color: Colors.blue,
    showCrosshairLabel: true,
    crosshairLabelPosition: CrosshairLabelPosition.overAxis,
    labelDisplay: AxisLabelDisplay.labelWithUnit,  // Shows "Power (kW)"
    min: 0,
    max: 100,
  ),
  grid: GridConfig(
    horizontal: true,
    vertical: true,
  ),
  series: [...],
)
```

---

## Multi-Axis Chart (Unchanged)

Multi-axis charts work exactly as before via `ChartSeries.yAxisConfig`:

```dart
BravenChartPlus(
  series: [
    ChartSeries(
      id: 'power',
      yAxisConfig: YAxisConfig(
        position: YAxisPosition.left,
        label: 'Power',
        unit: 'W',
        color: Colors.blue,
      ),
      data: powerData,
    ),
    ChartSeries(
      id: 'temperature',
      yAxisConfig: YAxisConfig(
        position: YAxisPosition.right,
        label: 'Temperature',
        unit: '°C',
        color: Colors.red,
      ),
      data: tempData,
    ),
  ],
)
```

---

## Grid Control

Grid lines are now controlled at the chart level, independent of axis configuration:

```dart
BravenChartPlus(
  grid: GridConfig(
    horizontal: true,          // Y-axis tick positions
    vertical: false,           // X-axis tick positions
    horizontalColor: Colors.grey.withOpacity(0.3),
    horizontalStrokeWidth: 1.0,
  ),
  series: [...],
)
```

---

## Crosshair Label Positioning

Control where crosshair Y-value labels appear per axis:

```dart
YAxisConfig(
  showCrosshairLabel: true,
  // Option 1: Label in axis strip (outside plot area)
  crosshairLabelPosition: CrosshairLabelPosition.overAxis,
  
  // Option 2: Label inside plot area
  // crosshairLabelPosition: CrosshairLabelPosition.insidePlot,
)
```

---

## Migration from AxisConfig

### Property Mapping

| Old (AxisConfig)   | New (YAxisConfig)                          |
|--------------------|--------------------------------------------|
| `axisColor`      | `color`                                  |
| `tickColor`      | `color` (unified)                        |
| `showGrid`       | Use `GridConfig` on `BravenChartPlus`  |
| `gridColor`      | Use `GridConfig.horizontalColor`         |
| `showAxis`       | `visible` + `showAxisLine`             |
| `range`          | `min` + `max` (separate properties)    |

### Before

```dart
BravenChartPlus(
  yAxis: AxisConfig(
    label: 'Power',
    axisColor: Colors.blue,
    showGrid: true,
    gridColor: Colors.grey,
  ),
  series: [...],
)
```

### After

```dart
BravenChartPlus(
  yAxis: YAxisConfig(
    label: 'Power',
    color: Colors.blue,
    unit: 'W',  // NEW: optional unit
    showCrosshairLabel: true,  // NEW: optional crosshair
  ),
  grid: GridConfig(
    horizontal: true,
    horizontalColor: Colors.grey,
  ),
  series: [...],
)
```

---

## Testing Your Migration

1. Replace `AxisConfig` with `YAxisConfig` for Y-axis configuration
2. Move grid settings to `BravenChartPlus.grid: GridConfig(...)`
3. Update property names (`axisColor` → `color`)
4. Run `flutter analyze` - should have zero warnings
5. Run `flutter test` - all tests should pass
6. Visual verification - chart should render identically
