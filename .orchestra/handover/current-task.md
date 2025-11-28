# Current Task

## Objective

Create an enum to represent Y-axis positions for multi-axis charts.

The chart will support up to 4 Y-axes positioned on the left and right sides. Create an enum that defines these positions clearly.

## Context

- Multi-axis charts need axes on both sides of the chart
- Positions needed: outer-left, left, right, outer-right
- This will be used by axis configuration to specify where each axis renders

## Success Demonstration

When complete, provide:

1. The file path where the enum was created
2. A code snippet showing how to use the enum:
   ```dart
   final position = YAxisPosition.left;
   ```
3. Confirmation that `dart analyze` passes on the file

## Location

Create in: `lib/src/axis/` (create folder if needed)

## When Done

1. Stage your changes: `git add .`
2. Update `completion-signal.md` with your demonstration
3. Say "Task complete - ready for review"
