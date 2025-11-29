# Current Task: Task 10 - Implement Color-Coded Axis Rendering

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

### Files to CREATE

| File | Purpose | Export To |
|------|---------|-----------|
| `lib/src/rendering/axis_color_resolver.dart` | Color resolution logic | `lib/braven_charts.dart` |
| `test/unit/multi_axis/axis_color_resolver_test.dart` | Unit tests | N/A |
| `example/lib/demos/task_010_color_demo.dart` | Visual verification demo | N/A |

### Files to MODIFY

| File | Changes |
|------|---------|
| `lib/src/rendering/multi_axis_painter.dart` | Add bindings/series params, use AxisColorResolver |

### Integration Changes (for MultiAxisPainter)

The `MultiAxisPainter` needs these specific modifications:

```dart
// 1. Add import at top of file:
import 'axis_color_resolver.dart';

// 2. Add new constructor parameters:
MultiAxisPainter({
  required this.axes,
  required this.axisBounds,
  required this.bindings,    // NEW
  required this.series,      // NEW
  TextStyle? labelStyle,
})

// 3. Add fields:
final List<SeriesAxisBinding> bindings;
final List<ChartSeries> series;

// 4. In _paintAxis(), replace hardcoded color resolution:
// BEFORE (around line 117):
final axisColor = axis.color ?? const Color(0xFF333333);

// AFTER:
final axisColor = AxisColorResolver.resolveAxisColor(
  axis,
  bindings,
  series,
);

// 5. In _paintTickLabel(), use resolved color:
// BEFORE (around line 193):
final labelColor = axis.color ?? labelStyle.color ?? const Color(0xFF666666);

// AFTER:
final labelColor = AxisColorResolver.resolveAxisColor(axis, bindings, series);
```

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

### Test File: `test/unit/multi_axis/axis_color_resolver_test.dart`

**Note**: Tests go in `test/unit/multi_axis/` (sprint folder), NOT `test/unit/rendering/`.

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

### Sample Test Data

Copy-paste these into your test file:

```dart
import 'dart:ui';

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter_test/flutter_test.dart';

// Test colors
const blueColor = Color(0xFF0000FF);
const redColor = Color(0xFFFF0000);
const greenColor = Color(0xFF00FF00);
const defaultGray = Color(0xFF333333);

// Axis with explicit color
final axisWithColor = YAxisConfig(
  id: 'power',
  position: YAxisPosition.left,
  color: blueColor,
);

// Axis without color (should resolve from series)
final axisWithoutColor = YAxisConfig(
  id: 'heartrate',
  position: YAxisPosition.right,
  color: null,
);

// Bindings
final powerBinding = SeriesAxisBinding(
  seriesId: 'power-series',
  yAxisId: 'power',
);

final hrBinding = SeriesAxisBinding(
  seriesId: 'hr-series',
  yAxisId: 'heartrate',
);

// Shared axis bindings (two series → one axis)
final sharedBinding1 = SeriesAxisBinding(
  seriesId: 'cpu-series',
  yAxisId: 'percentage',
);

final sharedBinding2 = SeriesAxisBinding(
  seriesId: 'memory-series',
  yAxisId: 'percentage',
);

// Series with colors
final powerSeries = ChartSeries(
  id: 'power-series',
  points: [],
  color: blueColor,
);

final hrSeries = ChartSeries(
  id: 'hr-series',
  points: [],
  color: redColor,
);

final cpuSeries = ChartSeries(
  id: 'cpu-series',
  points: [],
  color: greenColor,  // First series → this color should win
);

final memorySeries = ChartSeries(
  id: 'memory-series',
  points: [],
  color: redColor,  // Second series → should be ignored
);

// Series without color
final noColorSeries = ChartSeries(
  id: 'no-color-series',
  points: [],
  color: null,
);
```

### TDD Workflow
1. Create test file with failing tests FIRST
2. Run tests to confirm they fail: `flutter test test/unit/multi_axis/axis_color_resolver_test.dart`
3. Implement `AxisColorResolver` to make tests pass
4. Update `MultiAxisPainter` to use resolver
5. Run all sprint tests: `flutter test test/unit/multi_axis/`

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

### Demo File: `example/lib/demos/task_010_color_demo.dart`

Create this standalone demo:

```dart
import 'package:flutter/material.dart';
import 'package:braven_charts/braven_charts.dart';

/// Task 10 Demo: Color-Coded Axis Rendering
///
/// Demonstrates:
/// - Power axis (left) derives BLUE from power series
/// - HR axis (right) derives RED from heartrate series
/// - Both axes have NO explicit color - color comes from bound series
void main() => runApp(const Task010ColorDemo());

class Task010ColorDemo extends StatelessWidget {
  const Task010ColorDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Task 10: Color-Coded Axes',
      theme: ThemeData.dark(),
      home: Scaffold(
        appBar: AppBar(title: const Text('Task 10: Color-Coded Axes')),
        body: Center(
          child: Container(
            width: 800,
            height: 500,
            padding: const EdgeInsets.all(16),
            child: _buildChart(),
          ),
        ),
      ),
    );
  }

  Widget _buildChart() {
    // Sample data
    final powerData = List.generate(
      20,
      (i) => ChartDataPoint(x: i.toDouble(), y: 100 + (i * 15) % 300),
    );
    final hrData = List.generate(
      20,
      (i) => ChartDataPoint(x: i.toDouble(), y: 60 + (i * 5) % 120),
    );

    // Series with explicit colors
    final powerSeries = LineChartSeries(
      id: 'power',
      name: 'Power',
      points: powerData,
      color: Colors.blue,  // BLUE - should appear on left axis
    );

    final hrSeries = LineChartSeries(
      id: 'heartrate',
      name: 'Heart Rate',
      points: hrData,
      color: Colors.red,  // RED - should appear on right axis
    );

    // Axes WITHOUT explicit colors - should derive from series
    final powerAxis = YAxisConfig(
      id: 'power-axis',
      position: YAxisPosition.left,
      color: null,  // Should resolve to BLUE from powerSeries
      label: 'Power',
      unit: 'W',
    );

    final hrAxis = YAxisConfig(
      id: 'hr-axis',
      position: YAxisPosition.right,
      color: null,  // Should resolve to RED from hrSeries
      label: 'Heart Rate',
      unit: 'bpm',
    );

    // Bindings connect series to axes
    final bindings = [
      SeriesAxisBinding(seriesId: 'power', yAxisId: 'power-axis'),
      SeriesAxisBinding(seriesId: 'heartrate', yAxisId: 'hr-axis'),
    ];

    // Multi-axis configuration
    final multiAxisConfig = MultiAxisConfig(
      axes: [powerAxis, hrAxis],
      bindings: bindings,
    );

    return BravenChartPlus(
      series: [powerSeries, hrSeries],
      multiAxisConfig: multiAxisConfig,
    );
  }
}
```

### Flutter Agent Workflow

1. **Start Flutter with the standalone demo** (from repo root):

```powershell
Start-Process -FilePath "powershell" -ArgumentList "-NoExit", "-Command", `
  "cd 'e:\cloud services\Dropbox\Repositories\Flutter\braven_charts_v2.0\example'; python ..\tools\flutter_agent\flutter_agent.py run lib/demos/task_010_color_demo.dart -d chrome"
```

2. **Wait for app to be ready**:

```powershell
cd "e:\cloud services\Dropbox\Repositories\Flutter\braven_charts_v2.0\example"
python ..\tools\flutter_agent\flutter_agent.py wait --timeout 60
```

3. **Take screenshot**:

```powershell
python ..\tools\flutter_agent\flutter_agent.py screenshot --output ../.orchestra/screenshots/task-010-color-coded-axes.png
```

4. **Stop when done**:

```powershell
python ..\tools\flutter_agent\flutter_agent.py stop
```

### Expected Visual Output

In the screenshot, verify:
- **Left axis (Power)**: Labels, ticks, and axis line are **BLUE**
- **Right axis (Heart Rate)**: Labels, ticks, and axis line are **RED**
- **Both data series** visible: blue line for power, red line for heart rate
- **No gray axes**: All axes should have color derived from their bound series

---

## Quality Gates (MANDATORY)

### Linting - Zero Issues

```powershell
flutter analyze lib/src/rendering/axis_color_resolver.dart
flutter analyze lib/src/rendering/multi_axis_painter.dart
flutter analyze test/unit/multi_axis/axis_color_resolver_test.dart
```

### All Sprint Tests Must Pass

```powershell
# Task tests
flutter test test/unit/multi_axis/axis_color_resolver_test.dart

# All sprint unit tests (catches regressions)
flutter test test/unit/multi_axis/

# Integration tests
flutter test test/integration/multi_axis_*.dart
```

**Current Test Baseline**: 217 tests (197 unit + 20 integration) - MUST NOT decrease!

### Expected New Tests: 8+

The `axis_color_resolver_test.dart` should add at least 8 new tests.

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
