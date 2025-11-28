# Current Task

## Objective

Create a configuration model for Y-axis settings in multi-axis charts.

Each Y-axis needs configuration for its position, appearance, and data bounds. Create an immutable configuration class that holds these settings.

## Context

- We just created `YAxisPosition` enum (outerLeft, left, right, outerRight)
- Now we need a config class that USES this enum
- This config will be used when setting up multi-axis charts

## Required Properties

| Property | Type | Required | Description |
|----------|------|----------|-------------|
| id | String | Yes | Unique identifier for this axis |
| position | YAxisPosition | Yes | Where to render (uses enum from Task 1) |
| color | Color? | No | Color for axis line, ticks, labels |
| label | String? | No | Axis title text |
| unitSuffix | String? | No | Unit to append to values (e.g., "W", "bpm") |
| minValue | double? | No | Explicit minimum bound |
| maxValue | double? | No | Explicit maximum bound |

## Success Demonstration

When complete, provide:

1. The file path where the class was created
2. Code snippet showing instantiation:
   ```dart
   final config = YAxisConfig(
     id: 'power',
     position: YAxisPosition.left,
     color: Colors.blue,
     unitSuffix: 'W',
   );
   ```
3. Confirmation that it imports and uses `YAxisPosition` from Task 1
4. Confirmation that `dart analyze` passes

## Location

Create in: `lib/src/axis/y_axis_config.dart`
Export from: `lib/braven_charts.dart`

## When Done

1. Stage your changes: `git add .`
2. Update `completion-signal.md` with your demonstration
3. Say "Task complete - ready for review"
