# Quickstart: Multi-Axis Normalization

**Feature**: 011-multi-axis-normalization  
**Date**: 2025-11-27

---

## Overview

Multi-axis normalization allows you to display multiple data series with vastly different Y-axis ranges on the same chart. Each series uses the full vertical height while showing its original values on color-coded Y-axes.

---

## Quick Examples

### Basic Multi-Axis Chart

```dart
BravenChartPlus(
  chartType: ChartType.line,
  yAxes: [
    YAxisConfig(
      id: 'power',
      position: YAxisPosition.left,
      color: Colors.blue,
      label: 'Power',
      unit: 'W',
    ),
    YAxisConfig(
      id: 'heartRate',
      position: YAxisPosition.right,
      color: Colors.red,
      label: 'Heart Rate',
      unit: 'bpm',
    ),
  ],
  series: [
    LineChartSeries(
      id: 'power',
      yAxisId: 'power',  // Bind to power axis
      points: powerData,
      color: Colors.blue,
    ),
    LineChartSeries(
      id: 'hr',
      yAxisId: 'heartRate',  // Bind to heart rate axis
      points: heartRateData,
      color: Colors.red,
    ),
  ],
)
```

### Auto-Detection Mode

Let the system decide when multi-axis is needed:

```dart
BravenChartPlus(
  chartType: ChartType.line,
  normalizationMode: NormalizationMode.auto,  // Detects when ranges differ >10x
  series: [
    LineChartSeries(id: 'power', points: powerData),      // 0-300W
    LineChartSeries(id: 'volume', points: volumeData),    // 0.5-4L
  ],
)
```

### Four-Axis Chart

Maximum configuration with 4 Y-axes:

```dart
BravenChartPlus(
  chartType: ChartType.line,
  yAxes: [
    YAxisConfig(id: 'ventilation', position: YAxisPosition.leftOuter, unit: 'L/min'),
    YAxisConfig(id: 'tidalVolume', position: YAxisPosition.left, unit: 'L'),
    YAxisConfig(id: 'power', position: YAxisPosition.right, unit: 'W'),
    YAxisConfig(id: 'respRate', position: YAxisPosition.rightOuter, unit: 'bpm'),
  ],
  series: [
    LineChartSeries(id: 've', yAxisId: 'ventilation', points: veData),
    LineChartSeries(id: 'tv', yAxisId: 'tidalVolume', points: tvData),
    LineChartSeries(id: 'power', yAxisId: 'power', points: powerData),
    LineChartSeries(id: 'rf', yAxisId: 'respRate', points: rfData),
  ],
)
```

---

## API Reference

### YAxisConfig

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| id | String | required | Unique identifier for series binding |
| position | YAxisPosition | required | leftOuter, left, right, or rightOuter |
| color | Color? | null | Axis color (defaults to first bound series) |
| label | String? | null | Axis label text |
| unit | String? | null | Unit suffix for tick labels |
| min | double? | null | Explicit minimum (null = auto) |
| max | double? | null | Explicit maximum (null = auto) |
| minWidth | double | 40.0 | Minimum axis width in pixels |
| maxWidth | double | 80.0 | Maximum axis width in pixels |

### YAxisPosition

| Value | Description |
|-------|-------------|
| leftOuter | Leftmost axis |
| left | Primary left axis (default) |
| right | Primary right axis |
| rightOuter | Rightmost axis |

### NormalizationMode

| Value | Description |
|-------|-------------|
| none | No normalization (current behavior) |
| auto | Enable when ranges differ by >10x |
| perSeries | Always normalize each series |

### ChartSeries Extensions

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| yAxisId | String? | null | ID of Y-axis to use (null = primary) |
| unit | String? | null | Unit for tooltip display |

---

## Common Patterns

### Sharing an Axis

Multiple series can share the same Y-axis:

```dart
BravenChartPlus(
  chartType: ChartType.line,
  yAxes: [
    YAxisConfig(id: 'percentage', position: YAxisPosition.left, unit: '%'),
  ],
  series: [
    LineChartSeries(id: 'cpu', yAxisId: 'percentage', ...),
    LineChartSeries(id: 'memory', yAxisId: 'percentage', ...),  // Same axis
    LineChartSeries(id: 'disk', yAxisId: 'percentage', ...),    // Same axis
  ],
)
```

### Explicit Bounds

Override auto-computed bounds:

```dart
YAxisConfig(
  id: 'heartRate',
  position: YAxisPosition.right,
  min: 50,   // Always start at 50 bpm
  max: 200,  // Always end at 200 bpm
)
```

### Custom Formatting

Format tick labels:

```dart
YAxisConfig(
  id: 'temperature',
  position: YAxisPosition.left,
  labelFormatter: (value) => '${value.toStringAsFixed(1)}°C',
)
```

---

## Migration Guide

### From Single-Axis Charts

**No changes required!** Existing charts continue to work:

```dart
// This still works exactly as before
BravenChartPlus(
  chartType: ChartType.line,
  series: [series1, series2],  // All use primary axis
)
```

### Adding a Second Axis

```dart
// Add yAxes config and yAxisId to series
BravenChartPlus(
  chartType: ChartType.line,
  yAxes: [
    YAxisConfig(id: 'primary', position: YAxisPosition.left),
    YAxisConfig(id: 'secondary', position: YAxisPosition.right),
  ],
  series: [
    LineChartSeries(id: 's1', yAxisId: 'primary', ...),
    LineChartSeries(id: 's2', yAxisId: 'secondary', ...),
  ],
)
```

---

## Best Practices

1. **Use color-coding**: Match axis color to series color for instant recognition
2. **Limit to 4 axes**: More than 4 Y-axes becomes visually overwhelming
3. **Group similar metrics**: Series with same units should share an axis
4. **Use auto-detection**: Let the system decide for typical use cases
5. **Set explicit bounds**: For known ranges (e.g., heart rate 50-200 bpm)

---

## Troubleshooting

### Series appears as flat line
- Check if `yAxisId` matches an axis in `yAxes`
- Verify axis bounds aren't too wide for the data range

### Axis labels overlap
- Increase `maxWidth` on YAxisConfig
- Reduce `tickCount` to show fewer labels

### Crosshair shows wrong values
- Ensure `unit` is set on series for proper formatting
- Check that series `yAxisId` is correctly bound

---

*Quickstart Complete: 2025-11-27*
