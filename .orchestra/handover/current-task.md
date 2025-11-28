# Current Task

## Objective

Create a model to bind a data series to a specific Y-axis.

When a chart has multiple Y-axes, each data series needs to know which axis it belongs to. Create a simple binding model that associates a series with an axis by ID.

## Context

- We have `YAxisPosition` enum (outerLeft, left, right, outerRight)
- We have `YAxisConfig` model (id, position, color, label, unitSuffix, minValue, maxValue)
- Now we need to connect data series to these axis configurations
- The chart's data series already have identifiers - we just need to map series ID → axis ID

## Required Properties

| Property | Type | Required | Description |
|----------|------|----------|-------------|
| seriesId | String | Yes | ID of the data series |
| axisId | String | Yes | ID of the YAxisConfig this series binds to |

## Design Notes

- Keep it simple - just a mapping between two IDs
- The chart will use this to look up which axis config applies to each series
- Multiple series can bind to the same axis (if they have compatible ranges)

## Success Demonstration

When complete, provide:

1. The file path where the class was created
2. Code snippet showing usage:
   ```dart
   final binding = SeriesAxisBinding(
     seriesId: 'power-series',
     axisId: 'power-axis',
   );
   ```
3. Confirmation that `dart analyze` passes

## Location

Create in: `lib/src/axis/series_axis_binding.dart`
Export from: `lib/braven_charts.dart`

## When Done

1. Stage your changes: `git add .`
2. Update `completion-signal.md` with your demonstration
3. Say "Task complete - ready for review"
