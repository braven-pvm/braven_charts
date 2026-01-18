# Quickstart: X-Axis Renderer Unification

**Feature**: 018-x-axis-renderer

## Basic Usage

### Default X-Axis (No Configuration)

The X-axis works out-of-the-box with sensible defaults:

`dart
BravenChartPlus(
  series: [
    ChartSeries(
      yAxisId: 'main',
      data: myDataPoints,
      color: Colors.blue,
    ),
  ],
  yAxisConfigs: [
    YAxisConfig(id: 'main', label: 'Value', unit: 'W'),
  ],
  // X-axis uses defaults: visible, first series color, no label
)
`

### Themed X-Axis

Configure the X-axis with a specific color and label:

`dart
BravenChartPlus(
  series: [
    ChartSeries(
      yAxisId: 'main',
      data: myDataPoints,
      color: Colors.blue,
    ),
  ],
  yAxisConfigs: [
    YAxisConfig(id: 'main', label: 'Power', unit: 'W', color: Colors.green),
  ],
  xAxisConfig: XAxisConfig(
    color: Colors.amber,           // Explicit X-axis color
    label: 'Time',                 // Axis title
    unit: 's',                     // Unit for tick labels
    labelDisplay: AxisLabelDisplay.labelWithUnit,
  ),
)
`

### Custom Tick Formatting

Use a custom formatter for tick labels:

`dart
BravenChartPlus(
  series: [mySeries],
  yAxisConfigs: [myYAxisConfig],
  xAxisConfig: XAxisConfig(
    label: 'Date',
    labelFormatter: (value) {
      final date = DateTime.fromMillisecondsSinceEpoch(value.toInt());
      return DateFormat('HH:mm').format(date);
    },
  ),
)
`

### Controlling Visibility

Hide specific axis elements:

`dart
XAxisConfig(
  visible: true,           // Show/hide entire axis
  showAxisLine: false,     // Hide the axis line
  showTicks: true,         // Show tick marks
  showCrosshairLabel: true, // Show X-value in crosshair
)
`

### Explicit Range

Set fixed min/max values:

`dart
XAxisConfig(
  min: 0.0,
  max: 1000.0,
  label: 'Distance',
  unit: 'km',
)
`

## Property Reference

| Property | Type | Default | Purpose |
|----------|------|---------|---------|
| color | Color? | first series | Themed color for axis |
| label | String? | null | Axis title text |
| unit | String? | null | Unit suffix |
| min/max | double? | data bounds | Explicit range |
| visible | bool | true | Show/hide axis |
| showAxisLine | bool | true | Show axis line |
| showTicks | bool | true | Show tick marks |
| showCrosshairLabel | bool | true | Show X in crosshair |
| labelDisplay | AxisLabelDisplay | labelWithUnit | Label/unit display |
| labelFormatter | Function? | null | Custom formatting |

## Migration from Legacy

No migration required. If you were using the default X-axis behavior, it continues to work. To opt into themed styling, simply add an `xAxisConfig`:

`dart
// Before (still works)
BravenChartPlus(series: [...], yAxisConfigs: [...])

// After (opt-in to theming)
BravenChartPlus(
  series: [...],
  yAxisConfigs: [...],
  xAxisConfig: XAxisConfig(color: Colors.green, label: 'Time'),
)
`

## Visual Comparison

**Before** (legacy plain rendering):
- Gray axis line
- Black tick labels
- No colored styling

**After** (themed rendering):
- Colored axis line matching theme
- Colored tick labels
- Rounded corners on crosshair labels
- Consistent with Y-axis styling
