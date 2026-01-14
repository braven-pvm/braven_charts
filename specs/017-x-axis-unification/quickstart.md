# Quickstart: X-Axis Architecture Unification

**Feature**: 017-x-axis-unification  
**Date**: 2025-01-14

---

## Overview

This feature unifies X-axis architecture with the Y-axis system from Sprint 013. After implementation, developers can configure X and Y axes using identical patterns.

## Before (Legacy)

```dart
// Limited X-axis configuration
BravenChartPlus(
  xAxis: AxisConfig(
    label: 'Time',
    position: AxisPosition.bottom,
    // No unit support
    // No color derivation
    // No crosshair labels
  ),
  series: [powerSeries],
)
```

## After (New API)

```dart
// Full-featured X-axis configuration
BravenChartPlus(
  xAxisConfig: XAxisConfig(
    id: 'time',
    position: XAxisPosition.bottom,
    label: 'Time',
    unit: 's',  // Unit suffix support
    labelDisplay: AxisLabelDisplay.labelWithUnit,  // "Time (s)"
    color: null,  // Derive from series
    showCrosshairLabel: true,  // Show X-value on hover
  ),
  series: [powerSeries],
)
```

## Common Use Cases

### 1. Basic X-Axis with Units

```dart
XAxisConfig(
  id: 'time',
  label: 'Time',
  unit: 's',
  labelDisplay: AxisLabelDisplay.labelWithUnit,
)
// Result: Axis label shows "Time (s)", ticks show "10", "20", "30"
```

### 2. Unit on Every Tick

```dart
XAxisConfig(
  id: 'time',
  unit: 'ms',
  labelDisplay: AxisLabelDisplay.labelAndTickUnit,
)
// Result: Ticks show "100 ms", "200 ms", "300 ms"
```

### 3. Series-Derived Color

```dart
// X-axis automatically matches series color
XAxisConfig(
  id: 'time',
  color: null,  // Derive from first bound series
)
```

### 4. Crosshair X-Value Display

```dart
XAxisConfig(
  id: 'time',
  showCrosshairLabel: true,
  crosshairLabelPosition: CrosshairLabelPosition.overAxis,
  unit: 's',
)
// Result: Hovering shows "15 s" on X-axis at crosshair position
```

### 5. Top-Positioned X-Axis

```dart
XAxisConfig(
  id: 'time',
  position: XAxisPosition.top,
  label: 'Elapsed Time',
)
```

### 6. Per-Series X-Axis Configuration

```dart
// Advanced: Different series with different X-axis settings
final series1 = LineSeries(
  id: 'fast',
  points: fastData,
  xAxisConfig: XAxisConfig(
    id: 'fast-time',
    unit: 'ms',  // Milliseconds for fast data
  ),
);

final series2 = LineSeries(
  id: 'slow',
  points: slowData,
  xAxisConfig: XAxisConfig(
    id: 'slow-time',
    unit: 's',  // Seconds for slow data
  ),
);
```

### 7. Hidden X-Axis (Data Scaling Only)

```dart
XAxisConfig(
  id: 'time',
  visible: false,  // Hidden but still affects data scaling
)
```

## Backward Compatibility

Existing code continues to work:

```dart
// This still works (legacy API)
BravenChartPlus(
  xAxis: AxisConfig(
    label: 'Time',
    position: AxisPosition.bottom,
  ),
)

// Migration: Replace xAxis with xAxisConfig for new features
BravenChartPlus(
  xAxisConfig: XAxisConfig(
    id: 'time',
    label: 'Time',
    position: XAxisPosition.bottom,
    unit: 's',  // Now available!
  ),
)
```

## Key Differences from YAxisConfig

| Aspect | XAxisConfig | YAxisConfig |
|--------|-------------|-------------|
| Position enum | `XAxisPosition.top/bottom` | `YAxisPosition.left/right/leftOuter/rightOuter` |
| Default position | `bottom` | `left` |
| Multi-axis | Single axis (MVP) | Multiple axes supported |
| Rendering | `XAxisPainter` | `MultiAxisPainter` |

## API Mapping: X vs Y

| Feature | XAxisConfig | YAxisConfig |
|---------|-------------|-------------|
| Position | `position: XAxisPosition` | `position: YAxisPosition` |
| Label | `label: String` | `label: String` |
| Unit | `unit: String` | `unit: String` |
| Display mode | `labelDisplay: AxisLabelDisplay` | `labelDisplay: AxisLabelDisplay` |
| Color | `color: Color?` | `color: Color?` |
| Visibility | `visible: bool` | `visible: bool` |
| Tick count | `tickCount: int` | `tickCount: int` |
| Crosshair | `showCrosshairLabel: bool` | `showCrosshairLabel: bool` |
| Formatter | `labelFormatter: Function?` | `labelFormatter: Function?` |

## Testing

```dart
// Unit test example
test('XAxisConfig unit suffix formatting', () {
  final config = XAxisConfig(
    id: 'time',
    unit: 's',
    labelDisplay: AxisLabelDisplay.labelAndTickUnit,
  );
  
  final painter = XAxisPainter(config: config);
  final label = painter.formatTickLabel(15.0);
  
  expect(label, '15 s');
});
```

## Performance Notes

- XAxisPainter uses TextPainter caching (same as MultiAxisPainter)
- No setState during crosshair interaction
- RepaintBoundary isolates axis repaints from chart rebuilds
