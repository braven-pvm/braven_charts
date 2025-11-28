# Current Task: Create Multi-Axis Configuration Container

## Objective

Create `MultiAxisConfig` - the container class that holds all multi-axis configuration together.

## Context

This is the final foundation task. It combines all the pieces we've built:
- `YAxisConfig` (Task 2) - Individual axis configurations
- `SeriesAxisBinding` (Task 3) - Links series to axes
- `NormalizationMode` (Task 4) - Controls when normalization applies

This container will be passed to chart widgets to enable multi-axis support.

## What to Create

### 1. Container Class File

**Path**: `lib/src/models/multi_axis_config.dart`

#### Properties

| Property | Type | Required | Default | Description |
|----------|------|----------|---------|-------------|
| `axes` | `List<YAxisConfig>` | No | `const []` | List of Y-axis configurations |
| `bindings` | `List<SeriesAxisBinding>` | No | `const []` | Series-to-axis bindings |
| `mode` | `NormalizationMode` | No | `NormalizationMode.auto` | When to normalize |

#### Requirements

1. **const constructor** - Immutable configuration
2. **Import previous tasks** - Use types from Tasks 2, 3, 4
3. **Helper methods**:
   - `getAxisById(String id)` → `YAxisConfig?`
   - `getAxisForSeries(String seriesId)` → `YAxisConfig?`
   - `getBindingsForAxis(String axisId)` → `List<SeriesAxisBinding>`
4. **copyWith** method
5. **Equality** and **hashCode**

#### Import Requirements

```dart
import 'normalization_mode.dart';
import 'series_axis_binding.dart';
import 'y_axis_config.dart';
```

### 2. Test File (TDD - Create First!)

**Path**: `test/unit/multi_axis/multi_axis_config_test.dart`

#### Required Test Groups

1. **Construction**
   - Creates with defaults (empty axes, empty bindings, auto mode)
   - Creates with all parameters
   
2. **getAxisById**
   - Returns axis when found
   - Returns null when not found
   - Works with multiple axes
   
3. **getAxisForSeries**
   - Returns axis when binding exists
   - Returns null when no binding
   - Returns null when axis not found (binding exists but axis missing)
   
4. **getBindingsForAxis**
   - Returns empty list when no bindings
   - Returns matching bindings
   - Returns multiple bindings for shared axis
   
5. **copyWith**
   - Changes specified values
   - Preserves unchanged values
   
6. **Equality**
   - Same config = equal
   - Different config = not equal

### 3. Export

**File to modify**: `lib/src/models/enums.dart`

Add export:
```dart
export 'multi_axis_config.dart';
```

## Example Usage (for context only)

```dart
final config = MultiAxisConfig(
  axes: [
    YAxisConfig(id: 'power', position: YAxisPosition.left, unit: 'W'),
    YAxisConfig(id: 'hr', position: YAxisPosition.right, unit: 'bpm'),
  ],
  bindings: [
    SeriesAxisBinding(seriesId: 'power-series', yAxisId: 'power'),
    SeriesAxisBinding(seriesId: 'hr-series', yAxisId: 'hr'),
  ],
  mode: NormalizationMode.auto,
);

// Helper methods
final powerAxis = config.getAxisById('power');
final axisForSeries = config.getAxisForSeries('hr-series');
final hrBindings = config.getBindingsForAxis('hr');
```

## When Done

1. Stage your changes: `git add .`
2. Write to `.orchestra/handover/completion-signal.md`:
   - List files created/modified
   - Confirm all tests pass
   - Note: "Foundation phase complete!"
3. Say "Task complete - ready for review"
