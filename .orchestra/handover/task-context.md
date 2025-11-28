# Task Context

## Feature Being Built

Multi-axis normalization for charts - allowing multiple data series with vastly different Y-ranges to be displayed together, each using the full chart height.

**Example use case**: A sports scientist displaying Power (0-300W), Heart Rate (60-200bpm), and Tidal Volume (0.5-4.0L) on the same chart. Without normalization, smaller ranges appear as flat lines.

## Current Sprint Focus

Building the foundation layer - data models and configuration classes that will be used by rendering and interaction layers.

## What Exists

- `BravenChartPlus` widget - main chart widget
- `ChartData` - holds data series
- `ChartPainter` - renders the chart
- Single Y-axis support (current)

## What We're Building

- Multi-axis configuration models
- Normalization logic
- Multi-axis rendering
- Updated tooltips/crosshair

## Related Files (for reference)

- `lib/src/charts/` - chart data models
- `lib/src/painters/` - rendering logic  
- `lib/src/widgets/` - chart widgets
- `lib/braven_charts.dart` - main export barrel
