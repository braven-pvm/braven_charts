# Task 13: Update Crosshair to Use Per-Axis Bounds

## Objective

Update the crosshair/tracking mode to correctly convert screen Y positions to original data values using per-axis bounds instead of global Y bounds. Currently, crosshair uses global yMin/yMax for all series, which produces incorrect values when multi-axis normalization is active.

**Sprint**: 011-multi-axis-normalization  
**Phase**: Interaction (Phase 6: US4)  
**Category**: INTEGRATION - REQUIRES visual verification with screenshot

---

## SpecKit Traceability

**SpecKit Tasks Covered**:

- T043 [US4] **[FR-014]** Update crosshair to use per-axis Y bounds lookup - screen Y position → per-axis data value conversion
- T044 [US4] Update tracking mode to display all series values in tracking overlay
- T041 [P] [US4] Widget test for crosshair values in `test/widget/multi_axis/crosshair_values_test.dart`

**Contract References**: N/A - no explicit contracts for crosshair

---

## File Operations

### Files to CREATE:

| Op | File | Purpose |
|----|------|---------|
| CREATE | `test/widget/multi_axis/crosshair_values_test.dart` | Widget tests for per-axis crosshair values |
| CREATE | `example/lib/demos/task_013_crosshair_demo.dart` | Visual demo for crosshair verification |

### Files to UPDATE:

| Op | File | Changes |
|----|------|---------|
| UPDATE | `lib/src/rendering/chart_render_box.dart` | Update crosshair rendering to use per-axis bounds |
| UPDATE | `lib/src/interaction/core/crosshair_tracker.dart` | Add per-axis Y conversion method |

### Integration Changes (for UPDATE files):

```dart
// In CrosshairTracker, add a new method:
/// Converts a data Y coordinate to screen Y coordinate for a SPECIFIC axis.
static double dataToScreenYForAxis({
  required double dataY,
  required Rect chartBounds,
  required double axisMin,  // Per-axis min, not global
  required double axisMax,  // Per-axis max, not global
}) {
  // Same formula but uses axis-specific bounds
}

// In ChartRenderBox._paintCrosshairAndTracking, around line 4342:
// CURRENT (WRONG):
// final screenY = CrosshairTracker.dataToScreenY(
//   dataY: value.y,
//   chartBounds: _plotArea,
//   yMin: yMin,   // <-- Global bounds (WRONG for multi-axis)
//   yMax: yMax,
// );

// REQUIRED (CORRECT):
// 1. Look up the axis for this series
// 2. Get the per-axis bounds from _yAxes and normalization
// 3. Use axis-specific bounds for conversion:
// final axisBounds = _getAxisBoundsForSeries(value.seriesId);
// final screenY = CrosshairTracker.dataToScreenYForAxis(
//   dataY: value.y,
//   chartBounds: _plotArea,
//   axisMin: axisBounds.min,
//   axisMax: axisBounds.max,
// );
```

---

## Technical Context

### Dependencies (imports from completed tasks):

```dart
// From Task 12:
import 'package:braven_charts/src/formatting/multi_axis_value_formatter.dart';

// From Task 11:
import 'package:braven_charts/src/axis/series_axis_resolver.dart';

// From Task 6:
import 'package:braven_charts/src/rendering/multi_axis_normalizer.dart';

// Existing:
import 'package:braven_charts/src/interaction/core/crosshair_tracker.dart';
```

### ⚠️ MUST USE (DO NOT DUPLICATE):

| Utility | Use For | DO NOT |
|---------|---------|--------|
| `MultiAxisNormalizer.computeAxisBounds()` | Get per-axis min/max from series data | Recompute bounds inline |
| `SeriesAxisResolver.resolveAxisId()` | Get axis ID for a series | Manually match series to axis |
| `MultiAxisValueFormatter.formatWithDenormalization()` | Format values with unit | Build format strings manually |

### Relevant Existing Code:

- `lib/src/rendering/chart_render_box.dart` lines 4300-4380: Current crosshair rendering
- `lib/src/interaction/core/crosshair_tracker.dart`: `dataToScreenY()` method (line ~318)
- `test/widget/multi_axis/multi_axis_chart_test.dart`: Existing widget test patterns

---

## TDD Requirements

**Test File**: `test/widget/multi_axis/crosshair_values_test.dart`

**Test Cases to Implement FIRST** (write tests before implementation):

1. **Crosshair shows correct value for left axis series** - Power at 250W should show "250 W" not a scaled value
2. **Crosshair shows correct value for right axis series** - Heartrate at 150bpm should show "150 bpm" not a scaled value
3. **Tracking mode displays all series with correct per-axis values** - Both values shown correctly
4. **Screen Y conversion uses per-axis bounds** - Verify marker positions are correct

### Sample Test Data

```dart
// Two-axis test data with different scales
final testAxes = [
  YAxisConfig(id: 'power', position: YAxisPosition.left),
  YAxisConfig(id: 'hr', position: YAxisPosition.right),
];

final testBindings = [
  SeriesAxisBinding(seriesId: 'power-series', yAxisId: 'power'),
  SeriesAxisBinding(seriesId: 'hr-series', yAxisId: 'hr'),
];

final powerSeries = LineChartSeries(
  id: 'power-series',
  points: [
    ChartDataPoint(x: 0, y: 0),
    ChartDataPoint(x: 50, y: 250),  // 250 Watts
    ChartDataPoint(x: 100, y: 500),
  ],
  color: const Color(0xFF2196F3),
);

final hrSeries = LineChartSeries(
  id: 'hr-series', 
  points: [
    ChartDataPoint(x: 0, y: 60),
    ChartDataPoint(x: 50, y: 150),  // 150 bpm
    ChartDataPoint(x: 100, y: 180),
  ],
  color: const Color(0xFFF44336),
);

// At x=50:
// - Power series Y value = 250 (should display as "250 W" or "250")
// - HR series Y value = 150 (should display as "150 bpm" or "150")
// 
// Bug scenario (current behavior):
// If using global bounds (0-500), HR value 150 gets converted incorrectly
// because the normalized position doesn't match HR's actual range (60-180)
```

---

## Code Scaffolds

```dart
// crosshair_values_test.dart scaffold
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:braven_charts/braven_charts.dart';

void main() {
  group('Crosshair Per-Axis Values', () {
    late List<YAxisConfig> testAxes;
    late List<SeriesAxisBinding> testBindings;
    late List<ChartSeries> testSeries;

    setUp(() {
      testAxes = [
        YAxisConfig(id: 'power', position: YAxisPosition.left),
        YAxisConfig(id: 'hr', position: YAxisPosition.right),
      ];
      
      testBindings = [
        SeriesAxisBinding(seriesId: 'power-series', yAxisId: 'power'),
        SeriesAxisBinding(seriesId: 'hr-series', yAxisId: 'hr'),
      ];
      
      testSeries = [
        LineChartSeries(
          id: 'power-series',
          points: [
            ChartDataPoint(x: 0, y: 0),
            ChartDataPoint(x: 50, y: 250),
            ChartDataPoint(x: 100, y: 500),
          ],
          color: const Color(0xFF2196F3),
        ),
        LineChartSeries(
          id: 'hr-series',
          points: [
            ChartDataPoint(x: 0, y: 60),
            ChartDataPoint(x: 50, y: 150),
            ChartDataPoint(x: 100, y: 180),
          ],
          color: const Color(0xFFF44336),
        ),
      ];
    });

    testWidgets('crosshair shows correct value for left axis series', (tester) async {
      // Implement: Create chart with multi-axis config, enable crosshair,
      // simulate pointer at x=50, verify power value shown is 250 (not scaled)
    });

    testWidgets('crosshair shows correct value for right axis series', (tester) async {
      // Implement: Create chart with multi-axis config, enable crosshair,
      // simulate pointer at x=50, verify HR value shown is 150 (not incorrectly scaled)
    });

    testWidgets('tracking mode displays all series with per-axis values', (tester) async {
      // Implement: Verify tracking overlay shows all series with per-axis values
    });
  });
}
```

---

## Visual Verification (Flutter Agent)

**Task Category**: INTEGRATION

### INTEGRATION Tasks (REQUIRE visual verification):

This task modifies crosshair rendering to use per-axis bounds. Visual verification
confirms the crosshair markers and values display correctly for multi-axis charts.

#### Step 1: Create Standalone Demo File

**Demo Path**: `example/lib/demos/task_013_crosshair_demo.dart`

```dart
import 'package:flutter/material.dart';
import 'package:braven_charts/braven_charts.dart';

void main() => runApp(const Task013CrosshairDemo());

class Task013CrosshairDemo extends StatelessWidget {
  const Task013CrosshairDemo({super.key});

  @override
  Widget build(BuildContext context) {
    // Two-axis data: Power (0-500W) and Heart Rate (60-180bpm)
    final powerSeries = LineChartSeries(
      id: 'power',
      displayName: 'Power',
      points: [
        ChartDataPoint(x: 0, y: 100),
        ChartDataPoint(x: 25, y: 200),
        ChartDataPoint(x: 50, y: 350),
        ChartDataPoint(x: 75, y: 250),
        ChartDataPoint(x: 100, y: 400),
      ],
      color: const Color(0xFF2196F3),
    );

    final hrSeries = LineChartSeries(
      id: 'heartrate',
      displayName: 'Heart Rate',
      points: [
        ChartDataPoint(x: 0, y: 80),
        ChartDataPoint(x: 25, y: 110),
        ChartDataPoint(x: 50, y: 150),
        ChartDataPoint(x: 75, y: 140),
        ChartDataPoint(x: 100, y: 165),
      ],
      color: const Color(0xFFF44336),
    );

    return MaterialApp(
      title: 'Task 13: Crosshair Per-Axis Demo',
      home: Scaffold(
        appBar: AppBar(title: const Text('Crosshair Per-Axis Values')),
        body: Center(
          child: Container(
            width: 800,
            height: 600,
            padding: const EdgeInsets.all(20),
            child: BravenChartPlus(
              series: [powerSeries, hrSeries],
              yAxes: [
                YAxisConfig(id: 'power', position: YAxisPosition.left),
                YAxisConfig(id: 'heartrate', position: YAxisPosition.right),
              ],
              axisBindings: [
                SeriesAxisBinding(seriesId: 'power', yAxisId: 'power'),
                SeriesAxisBinding(seriesId: 'heartrate', yAxisId: 'heartrate'),
              ],
              normalizationMode: NormalizationMode.perSeries,
              interactionConfig: InteractionConfig(
                crosshairConfig: CrosshairConfig(
                  enabled: true,
                  mode: CrosshairMode.both,
                  showTrackingTooltip: true,
                  showIntersectionMarkers: true,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
```

#### Step 2: Flutter Agent Workflow

1. **Start Flutter with the standalone demo** (from repo root):

```powershell
Start-Process -FilePath "powershell" -ArgumentList "-NoExit", "-Command", `
  "cd 'e:\cloud services\Dropbox\Repositories\Flutter\braven_charts_v2.0\example'; python ..\tools\flutter_agent\flutter_agent.py run lib/demos/task_013_crosshair_demo.dart -d chrome"
```

2. **Wait for app to be ready**:

```powershell
cd "e:\cloud services\Dropbox\Repositories\Flutter\braven_charts_v2.0\example"
python ..\tools\flutter_agent\flutter_agent.py wait --timeout 30
```

3. **Take screenshot** (move mouse to ~center of chart first):

```powershell
python ..\tools\flutter_agent\flutter_agent.py screenshot --output ../screenshots/task-013-crosshair.png
```

4. **Stop when done**:

```powershell
python ..\tools\flutter_agent\flutter_agent.py stop
```

**Expected Visual Output**:

- Two data series visible (blue Power, red Heart Rate)
- Left Y-axis: Power scale (0-500 range, BLUE)
- Right Y-axis: Heart Rate scale (60-180 range, RED)
- Crosshair tooltip shows ORIGINAL values:
  - Power: ~350 W (not a normalized/scaled value)
  - Heart Rate: ~150 bpm (not a normalized/scaled value)
- Intersection markers on BOTH lines at their correct Y positions

---

## Acceptance Criteria

- [ ] Widget test `test/widget/multi_axis/crosshair_values_test.dart` created and passes
- [ ] Crosshair uses per-axis bounds via SeriesAxisResolver (not global yMin/yMax)
- [ ] Power values display correctly (e.g., "250 W" not scaled)
- [ ] Heart rate values display correctly (e.g., "150 bpm" not scaled)
- [ ] Intersection markers positioned at correct per-axis Y positions
- [ ] Demo `example/lib/demos/task_013_crosshair_demo.dart` works visually
- [ ] Screenshot captured via flutter_agent.py shows correct crosshair behavior
- [ ] Zero lint issues on modified files
- [ ] All sprint tests continue to pass (baseline: 237 unit + 13 widget)

---

## Quality Gates (MANDATORY)

### Linting - Zero Issues

```bash
flutter analyze lib/src/rendering/chart_render_box.dart
flutter analyze lib/src/interaction/core/crosshair_tracker.dart
flutter analyze test/widget/multi_axis/crosshair_values_test.dart
```

### All Sprint Tests Must Pass

```bash
flutter test test/unit/multi_axis/
flutter test test/widget/multi_axis/
```

**Current Test Baseline**: 237 unit tests + 13 widget tests (MUST NOT decrease!)

---

## Completion Protocol

When done:

1. **Verify linting is clean** (BLOCKING)
2. **Verify ALL tests pass** (BLOCKING)
3. **Visual verification completed via flutter_agent.py** (BLOCKING for integration task)
4. Stage your changes: `git add .`
5. Run pre-signal check: `.\.orchestra\handover\.implementor\scripts\pre-signal-check.ps1`
6. Write to `.orchestra/handover/completion-signal.md`:
   - Files created/modified
   - Number of tests added
   - Confirm linting clean
   - Confirm all sprint tests pass
   - Visual verification notes
7. Say "Task complete - ready for review"
