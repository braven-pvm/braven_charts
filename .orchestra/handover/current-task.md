# Current Task

## Objective

Create the container class that holds all multi-axis configuration together.

This is the "master config" that users will pass to the chart. It combines all the pieces we've built: axis configs, series bindings, and normalization mode.

## Context

We have built:
- `YAxisPosition` - where axes render (outerLeft, left, right, outerRight)
- `YAxisConfig` - individual axis configuration (id, position, color, label, etc.)
- `SeriesAxisBinding` - maps series to axes
- `NormalizationMode` - when to normalize (none, auto, always)

Now we need a container that holds:
- List of axis configurations
- List of series-to-axis bindings  
- The normalization mode
- Auto-detection threshold (for `auto` mode)

## Required Properties

| Property | Type | Required | Description |
|----------|------|----------|-------------|
| axes | List<YAxisConfig> | Yes | All Y-axis configurations |
| bindings | List<SeriesAxisBinding> | Yes | Series-to-axis mappings |
| mode | NormalizationMode | No | Defaults to `auto` |
| autoDetectionThreshold | double | No | Range ratio to trigger auto (default: 10.0) |

## Success Demonstration

When complete, provide:

1. The file path where the class was created
2. Code snippet showing full usage:
   ```dart
   final config = MultiAxisConfig(
     axes: [
       YAxisConfig(id: 'power', position: YAxisPosition.left, color: Colors.blue),
       YAxisConfig(id: 'hr', position: YAxisPosition.right, color: Colors.red),
     ],
     bindings: [
       SeriesAxisBinding(seriesId: 'power-data', axisId: 'power'),
       SeriesAxisBinding(seriesId: 'hr-data', axisId: 'hr'),
     ],
     mode: NormalizationMode.auto,
   );
   ```
3. Confirmation that it imports and uses all previous models
4. Confirmation that `dart analyze` passes

## Location

Create in: `lib/src/axis/multi_axis_config.dart`
Export from: `lib/braven_charts.dart`

## When Done

1. Stage your changes: `git add .`
2. Update `completion-signal.md` with your demonstration
3. Say "Task complete - ready for review"
