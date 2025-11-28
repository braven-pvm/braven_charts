# Phase 2 Context - Normalization Phase

## What Phase 1 Built

Phase 1 (Foundation) created all the data models you'll need. All exports are in `lib/braven_charts.dart`.

### Available Models

**1. YAxisPosition enum** (`lib/src/axis/y_axis_position.dart`)
- Values: `outerLeft`, `left`, `right`, `outerRight`
- Used to specify where a Y-axis renders

**2. YAxisConfig class** (`lib/src/axis/y_axis_config.dart`)
- Properties: `id`, `position`, `color`, `label`, `unitSuffix`, `minValue`, `maxValue`
- Has `copyWith()`, equality operators, `toString()`

**3. SeriesAxisBinding class** (`lib/src/axis/series_axis_binding.dart`)  
- Properties: `seriesId`, `axisId`
- Links a data series to a specific Y-axis

**4. NormalizationMode enum** (`lib/src/axis/normalization_mode.dart`)
- Values: `none`, `auto`, `always`
- Controls when normalization should be applied

**5. MultiAxisConfig class** (`lib/src/axis/multi_axis_config.dart`)
- Container that holds: `axes` list, `bindings` list, `mode`, `autoDetectionThreshold`
- Has helper methods: `getAxisById(String id)`, `getAxisForSeries(String seriesId)`

### Import Pattern

```dart
import 'package:braven_charts/braven_charts.dart';
```

All models are exported from the barrel file.

---

## Feature Being Built

Multi-axis normalization for charts - allowing multiple data series with vastly different Y-ranges to be displayed together, each using the full chart height.

**Example use case**: A sports scientist displaying Power (0-300W), Heart Rate (60-200bpm), and Tidal Volume (0.5-4.0L) on the same chart. Without normalization, smaller ranges appear as flat lines.

---

## Phase 2 Requirements

Phase 2 implements the actual normalization logic. Your tasks will require:

1. **Test-Driven Development (TDD)** - Write tests first
2. Using the models from Phase 1
3. Creating new files in `lib/src/axis/` and `test/unit/axis/`

### Directory Structure

```
lib/src/axis/
├── y_axis_position.dart      ✅ exists
├── y_axis_config.dart        ✅ exists  
├── series_axis_binding.dart  ✅ exists
├── normalization_mode.dart   ✅ exists
├── multi_axis_config.dart    ✅ exists
└── data_normalizer.dart      ← Phase 2 creates

test/unit/axis/
└── data_normalizer_test.dart ← Phase 2 creates
```

---

## Workflow

1. Read your current task in `.orchestra/handover/current-task.md`
2. Implement the task (TDD: write tests first, then implementation)
3. Stage your changes with `git add`
4. Write to `completion-signal.md` that you're ready for review
5. Say "ready for review"

I'll verify and either approve (commit) or provide feedback.

---

## Quality Pattern Established in Phase 1

All Phase 1 models followed this pattern:
- Single responsibility
- Immutable where appropriate  
- Full documentation with `///` comments
- `copyWith()` method
- Equality operators (`==` and `hashCode`)
- Descriptive `toString()`
- Exported from barrel file

Please maintain this quality standard.

---

## Related Files (for reference)

- `lib/src/charts/` - chart data models
- `lib/src/painters/` - rendering logic  
- `lib/src/widgets/` - chart widgets
- `lib/braven_charts.dart` - main export barrel
