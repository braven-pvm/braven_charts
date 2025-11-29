# Current Task: Task 10 - Implement Color-Coded Axis Rendering

## Pre-Flight Checklist (Orchestrator Audit Trail)

**Date**: [TO BE FILLED BY ORCHESTRATOR]
**Orchestrator**: GitHub Copilot (Claude Opus 4.5)
**Task Source**: `.orchestra/manifest.yaml` lines 75-81

### Verification
- [x] Read `.orchestra/readme.md` (Step 0)
- [x] Read `.orchestra/manifest.yaml` to identify this task
- [x] Read SpecKit tasks (T034, T035, T036, T037, T038, T031)
- [x] Identified dependencies: Task 9 (MultiAxisPainter) - COMPLETED
- [x] Created verification criteria in `.orchestra/verification/task-010.yaml`
- [x] Deleted previous `current-task.md` before creating this one

### Files Consulted
- `specs/011-multi-axis-normalization/tasks.md` - SpecKit task definitions
- `specs/011-multi-axis-normalization/spec.md` - FR-007 color-coding requirement
- `lib/src/models/y_axis_config.dart` - Existing color field
- `lib/src/models/series_axis_binding.dart` - Binding model
- `lib/src/models/chart_series.dart` - Series color source
- `lib/src/rendering/multi_axis_painter.dart` - Where color is applied

---

## Task Overview

**Objective**: Implement color resolution for Y-axes that derives color from bound series when not explicitly set on the axis config.

**Category**: INTEGRATION (connects axis config to series data via bindings)

**FR-007**: "Each Y-axis MUST support color-coding to match its bound series"

**Current State**:
- `YAxisConfig.color` is nullable with doc "If null, uses the color of the first bound series"
- `MultiAxisPainter` currently falls back to hardcoded gray (`Color(0xFF333333)`) when axis.color is null
- `SeriesAxisBinding` exists to connect series → axis by ID
- `ChartSeries.color` contains the series color

**Required State**:
- `AxisColorResolver` class that resolves effective axis color from config or bound series
- `MultiAxisPainter` uses resolved color for axis line, ticks, and labels
- Shared axes (multiple series) use first bound series color

---

## SpecKit Traceability

| SpecKit ID | Description | Status |
|------------|-------------|--------|
| T034 | Implement axis color resolver (from config or series) | ⏳ Pending |
| T035 | Apply color to axis labels | ⏳ Pending |
| T036 | Apply color to axis ticks | ⏳ Pending |
| T037 | Apply color to axis line | ⏳ Pending |
| T038 | Handle shared axis color (multiple series bound) | ⏳ Pending |
| T031 | Unit test for axis colors | ⏳ Pending |

**Total SpecKit Tasks**: 6

---

## Deliverables

### Required Files

| # | File Path | Purpose | SpecKit |
|---|-----------|---------|---------|
| 1 | `lib/src/rendering/axis_color_resolver.dart` | NEW: Color resolution logic | T034, T038 |
| 2 | `lib/src/rendering/multi_axis_painter.dart` | UPDATE: Use resolved colors | T035, T036, T037 |
| 3 | `test/unit/rendering/axis_color_resolver_test.dart` | NEW: Unit tests | T031 |

### Expected Outputs
- `AxisColorResolver` class with `resolveAxisColor()` method
- `MultiAxisPainter` integration with color resolver
- 8+ unit tests covering resolution scenarios

---

## Technical Context

### Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                      AxisColorResolver                          │
├─────────────────────────────────────────────────────────────────┤
│ static Color resolveAxisColor(                                  │
│   YAxisConfig axis,                                             │
│   List<SeriesAxisBinding> bindings,                             │
│   List<ChartSeries> series,                                     │
│   {Color defaultColor = const Color(0xFF333333)}                │
│ )                                                               │
│                                                                 │
│ Resolution Priority:                                            │
│ 1. axis.color if non-null → return it                          │
│ 2. Find bindings where binding.yAxisId == axis.id              │
│ 3. Find first matching series by seriesId                      │
│ 4. Return series.color if non-null                             │
│ 5. Return defaultColor                                          │
└─────────────────────────────────────────────────────────────────┘
```

### MUST USE (DO NOT DUPLICATE)

| Component | Location | Why Use It |
|-----------|----------|------------|
| `SeriesAxisBinding` | `lib/src/models/series_axis_binding.dart` | Binding lookup by yAxisId |
| `YAxisConfig.color` | `lib/src/models/y_axis_config.dart` | Primary color source |
| `ChartSeries.color` | `lib/src/models/chart_series.dart` | Fallback color source |
| `MultiAxisPainter` | `lib/src/rendering/multi_axis_painter.dart` | Integrate color resolution |

**ANTI-PATTERNS TO AVOID**:
- ❌ Hardcoding fallback colors in multiple places
- ❌ Creating new binding lookup logic (use existing model)
- ❌ Duplicating color resolution in labels/ticks/line separately

### Key Dependencies
- Task 9 `MultiAxisPainter` (COMPLETED) - will be updated to use color resolver

---

## TDD Requirements

### Test File: `test/unit/rendering/axis_color_resolver_test.dart`

```dart
// Required test cases (minimum):
group('AxisColorResolver', () {
  // T034: Axis color resolver
  test('returns axis.color when explicitly set');
  test('returns first bound series color when axis.color is null');
  test('returns default color when no series bound');
  test('returns default color when bound series has null color');
  
  // T038: Shared axis
  test('uses first bound series color for shared axis');
  test('ignores subsequent series colors for shared axis');
  
  // Edge cases
  test('handles empty bindings list');
  test('handles empty series list');
});
```

### TDD Workflow
1. Create test file with failing tests FIRST
2. Run tests to confirm they fail
3. Implement `AxisColorResolver` to make tests pass
4. Update `MultiAxisPainter` to use resolver
5. Run all tests to confirm integration

---

## Code Scaffolds

### `lib/src/rendering/axis_color_resolver.dart`

```dart
/// Resolves axis colors from configuration or bound series.
///
/// This library provides the [AxisColorResolver] class for determining
/// the effective color of a Y-axis in multi-axis charts.
library;

import 'dart:ui' show Color;

import '../models/chart_series.dart';
import '../models/series_axis_binding.dart';
import '../models/y_axis_config.dart';

/// Resolves the effective color for a Y-axis.
///
/// Color resolution priority:
/// 1. Explicit [YAxisConfig.color] if set
/// 2. Color of first bound [ChartSeries]
/// 3. Default color (configurable)
///
/// Example:
/// ```dart
/// final color = AxisColorResolver.resolveAxisColor(
///   powerAxis,
///   bindings,
///   series,
/// );
/// ```
class AxisColorResolver {
  const AxisColorResolver._();

  /// Default color when no other color source is available.
  static const Color defaultAxisColor = Color(0xFF333333);

  /// Resolves the effective color for a Y-axis.
  ///
  /// [axis] is the Y-axis configuration.
  /// [bindings] is the list of series-to-axis bindings.
  /// [series] is the list of data series.
  /// [defaultColor] is the fallback color (defaults to [defaultAxisColor]).
  ///
  /// Returns the resolved color for the axis.
  static Color resolveAxisColor(
    YAxisConfig axis,
    List<SeriesAxisBinding> bindings,
    List<ChartSeries> series, {
    Color defaultColor = defaultAxisColor,
  }) {
    // TODO: Implement color resolution
    // 1. Return axis.color if non-null
    // 2. Find bindings matching axis.id
    // 3. Find first series by seriesId
    // 4. Return series.color if non-null
    // 5. Return defaultColor
    throw UnimplementedError();
  }
}
```

---

## Visual Verification

**Category**: INTEGRATION

**Requirement**: Standalone demo with screenshot verification

### Demo Location
`example/lib/demos/task_010_demo.dart`

### Demo Requirements
1. Create multi-axis chart with:
   - Power axis (left) - NO explicit color (should derive from blue series)
   - HR axis (right) - NO explicit color (should derive from red series)
   - Shared axis with two series (verify uses first series color)
   
2. Verify visually:
   - Power axis labels, ticks, line are all BLUE
   - HR axis labels, ticks, line are all RED
   - Shared axis uses first bound series color consistently

### Screenshot Command
```powershell
python tools/flutter_agent/flutter_agent.py --project-root "example" --screenshot ".orchestra/screenshots/task-010-color-coded-axes.png" --run-timeout 30
```

---

## Quality Gates

### Automated Checks
- [ ] All new tests pass
- [ ] No regressions in existing tests (`flutter test`)
- [ ] No analyzer warnings (`flutter analyze`)
- [ ] Test coverage for new code ≥80%

### Manual Verification
- [ ] Axis colors match bound series when axis.color is null
- [ ] Explicit axis.color overrides series color
- [ ] Shared axis uses first bound series color
- [ ] Labels, ticks, and line all use same resolved color

---

## Completion Protocol

When all deliverables are complete:

1. Run full test suite: `flutter test`
2. Run analyzer: `flutter analyze`
3. Capture demo screenshot
4. Update `.orchestra/handover/completion-signal.md`:
   ```yaml
   task: 10
   status: ready-for-verification
   tests_added: [count]
   tests_passing: [count]
   screenshot: .orchestra/screenshots/task-010-color-coded-axes.png
   ```
5. Signal completion: "Task 10 ready for orchestrator verification"

---

## Notes

- The color resolver should be a pure function (static method) for easy testing
- `MultiAxisPainter` will need to accept bindings and series as new parameters
- Consider whether the painter should receive already-resolved colors vs. doing resolution internally
- FR-007 explicitly requires color-coding capability; this task implements the core mechanism
