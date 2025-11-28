# Current Task

## Objective

Create an enum to represent normalization modes for multi-axis charts.

The chart needs to know when and how to apply normalization. Create an enum that defines the different modes available.

## Context

- Multi-axis charts normalize data so different scales use the full chart height
- Users may want: no normalization, automatic detection, or always-on normalization
- This enum will be used in the overall multi-axis configuration

## Required Values

| Value | Description |
|-------|-------------|
| `none` | No normalization - traditional single-axis behavior |
| `auto` | Automatically enable when series ranges differ significantly (e.g., >10x) |
| `always` | Always normalize all series to full height |

## Success Demonstration

When complete, provide:

1. The file path where the enum was created
2. Code snippet showing usage:
   ```dart
   final mode = NormalizationMode.auto;
   ```
3. Confirmation that `dart analyze` passes

## Location

Create in: `lib/src/axis/normalization_mode.dart`
Export from: `lib/braven_charts.dart`

## When Done

1. Stage your changes: `git add .`
2. Update `completion-signal.md` with your demonstration
3. Say "Task complete - ready for review"
