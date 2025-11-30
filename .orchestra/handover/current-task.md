# Task 15: Expose Multi-Axis API on BravenChartPlus

## Objective

Add `yAxisId` and `unit` fields to the `ChartSeries` model hierarchy to enable direct axis binding on series, and implement validation to prevent invalid multi-axis configurations (max 4 axes, unique positions).

**Phase**: Integration (API Exposure)

**Category**: INTEGRATION

- INFRASTRUCTURE: Creates classes/logic NOT yet wired into main widget (no screenshot)
- **INTEGRATION**: Wires components INTO BravenChartPlus (REQUIRES screenshot) ← THIS TASK
- VISUAL: Modifies rendering output (REQUIRES screenshot)

---

## SpecKit Traceability

**SpecKit Tasks Covered**:

- T006 - Add `yAxisId` and `unit` fields to ChartSeries base class
- T047 - Add validation for max 4 axes
- T048 - Add validation for unique axis positions
- T049 - Add API documentation to all public classes

**Contract References**:

- N/A - This is API enhancement, follows existing ChartSeries patterns

---

## Deliverables

### File Operations

| Operation | File | Purpose |
| --------- | ---- | ------- |
| CREATE | `test/unit/multi_axis/chart_series_axis_fields_test.dart` | Tests for yAxisId and unit fields |
| CREATE | `test/widget/multi_axis/api_validation_test.dart` | Widget tests for axis validation |
| CREATE | `example/lib/demos/task_015_api_demo.dart` | Demo showing series with yAxisId |
| UPDATE | `lib/src/models/chart_series.dart` | Add `yAxisId` and `unit` to base class and all subclasses |
| UPDATE | `lib/src/braven_chart_plus.dart` | Add validation for max 4 axes and unique positions |

### Integration Changes (for UPDATE files):

```dart
// In ChartSeries base class:
class ChartSeries {
  const ChartSeries({
    required this.id,
    this.name,
    required this.points,
    this.color,
    this.style,
    this.isXOrdered = false,
    this.metadata,
    this.annotations = const [],
    this.yAxisId,  // NEW: Explicit axis binding
    this.unit,     // NEW: Unit for value formatting
  });

  // ... existing fields ...
  
  /// Optional Y-axis binding. When set, this series will be rendered
  /// against the Y-axis with this ID. Takes precedence over axisBindings.
  final String? yAxisId;
  
  /// Optional unit suffix for value formatting (e.g., 'W', 'bpm', 'L').
  /// Used by tooltips and axis labels.
  final String? unit;
}

// In LineChartSeries (and all other subclasses):
class LineChartSeries extends ChartSeries {
  const LineChartSeries({
    // ... existing params ...
    super.yAxisId,  // Add to super call
    super.unit,     // Add to super call
  });
}

// In BravenChartPlus._rebuildElements() or initState():
// Add validation:
assert(
  widget.yAxes == null || widget.yAxes!.length <= 4,
  'Maximum 4 Y-axes allowed, got ${widget.yAxes!.length}',
);

// Check for duplicate positions:
if (widget.yAxes != null && widget.yAxes!.length > 1) {
  final positions = widget.yAxes!.map((a) => a.position).toList();
  final uniquePositions = positions.toSet();
  assert(
    positions.length == uniquePositions.length,
    'Duplicate Y-axis positions are not allowed',
  );
}
```

---

## Technical Context

### Dependencies (imports from completed tasks):

```dart
import 'package:braven_charts/src/models/chart_series.dart';
import 'package:braven_charts/src/models/y_axis_config.dart';
import 'package:braven_charts/src/models/y_axis_position.dart';
```

### ⚠️ MUST USE (DO NOT DUPLICATE):

| Utility | Use For | DO NOT |
| ------- | ------- | ------ |
| `SeriesAxisResolver` | Resolving which axis a series binds to | Create new resolution logic |
| Existing validation pattern | Follow assert() style in BravenChartPlus | Throw exceptions in widget constructor |

### Relevant Existing Code:

- `lib/src/models/chart_series.dart` - Base class and all subclasses
- `lib/src/braven_chart_plus.dart` - Widget with yAxes parameter
- `lib/src/axis/series_axis_resolver.dart` - Existing axis resolution logic

---

## Testing

**Test File 1**: `test/unit/multi_axis/chart_series_axis_fields_test.dart`

**Test Cases to Implement FIRST** (yAxisId and unit fields):

1. ChartSeries accepts yAxisId parameter
2. ChartSeries accepts unit parameter  
3. LineChartSeries supports yAxisId
4. LineChartSeries supports unit
5. AreaChartSeries supports yAxisId and unit
6. BarChartSeries supports yAxisId and unit
7. ScatterChartSeries supports yAxisId and unit
8. copyWith preserves yAxisId
9. copyWith preserves unit
10. equality includes yAxisId and unit

**Test File 2**: `test/widget/multi_axis/api_validation_test.dart`

**Test Cases** (validation):

1. Widget accepts up to 4 Y-axes
2. Widget assertion fails with 5+ Y-axes
3. Widget accepts axes at different positions
4. Widget assertion fails with duplicate positions (e.g., two left)

### Sample Test Data

```dart
// For unit tests - series with axis binding
final powerSeries = LineChartSeries(
  id: 'power',
  name: 'Power',
  points: [ChartDataPoint(x: 0, y: 100), ChartDataPoint(x: 1, y: 200)],
  color: Colors.blue,
  yAxisId: 'power-axis',  // Explicit binding
  unit: 'W',              // Unit for formatting
);

final hrSeries = LineChartSeries(
  id: 'heartrate',
  name: 'Heart Rate',
  points: [ChartDataPoint(x: 0, y: 80), ChartDataPoint(x: 1, y: 120)],
  color: Colors.red,
  yAxisId: 'hr-axis',
  unit: 'bpm',
);

// For widget tests - valid 4-axis config
final validAxes = [
  YAxisConfig(id: 'axis1', position: YAxisPosition.leftOuter),
  YAxisConfig(id: 'axis2', position: YAxisPosition.left),
  YAxisConfig(id: 'axis3', position: YAxisPosition.right),
  YAxisConfig(id: 'axis4', position: YAxisPosition.rightOuter),
];

// For widget tests - invalid 5-axis config (should fail)
final invalidAxes = [...validAxes, YAxisConfig(id: 'axis5', position: YAxisPosition.left)];

// For widget tests - duplicate positions (should fail)
final duplicateAxes = [
  YAxisConfig(id: 'axis1', position: YAxisPosition.left),
  YAxisConfig(id: 'axis2', position: YAxisPosition.left),  // Duplicate!
];
```

---

## Code Scaffolds

### ChartSeries Base Class Updates

```dart
/// Base class for chart series.
///
/// Now supports optional Y-axis binding via [yAxisId] and value formatting
/// via [unit].
class ChartSeries {
  const ChartSeries({
    required this.id,
    this.name,
    required this.points,
    this.color,
    this.style,
    this.isXOrdered = false,
    this.metadata,
    this.annotations = const [],
    this.yAxisId,
    this.unit,
  });

  final String id;
  final String? name;
  final List<ChartDataPoint> points;
  final Color? color;
  final SeriesStyle? style;
  final bool isXOrdered;
  final Map<String, dynamic>? metadata;
  final List<ChartAnnotation> annotations;
  
  /// Optional Y-axis ID for explicit axis binding in multi-axis mode.
  ///
  /// When set, this series will be rendered against the Y-axis with
  /// this ID, rather than using the [axisBindings] parameter or
  /// auto-detection.
  ///
  /// Example:
  /// ```dart
  /// LineChartSeries(
  ///   id: 'power',
  ///   points: [...],
  ///   yAxisId: 'power-axis',  // Binds to axis with id='power-axis'
  /// )
  /// ```
  final String? yAxisId;
  
  /// Optional unit suffix for value formatting.
  ///
  /// Used by tooltips and axis labels to display values with units.
  /// Common examples: 'W' (watts), 'bpm' (beats per minute), 'L' (liters).
  ///
  /// Example:
  /// ```dart
  /// LineChartSeries(
  ///   id: 'power',
  ///   points: [...],
  ///   unit: 'W',  // Values displayed as "250 W"
  /// )
  /// ```
  final String? unit;

  int get length => points.length;
  bool get isEmpty => points.isEmpty;
  bool get isNotEmpty => points.isNotEmpty;
  String get displayName => name ?? id;
}
```

### Validation in BravenChartPlus

```dart
// In didUpdateWidget or _rebuildElements (wherever yAxes is accessed)
void _validateAxisConfiguration() {
  final axes = widget.yAxes;
  if (axes == null || axes.isEmpty) return;
  
  // Max 4 axes validation
  assert(
    axes.length <= 4,
    'Maximum 4 Y-axes allowed. Got ${axes.length}.',
  );
  
  // Unique positions validation
  final positions = axes.map((a) => a.position).toList();
  final uniquePositions = positions.toSet();
  assert(
    positions.length == uniquePositions.length,
    'Duplicate Y-axis positions are not allowed. '
    'Each axis must have a unique position.',
  );
}
```

---

## Visual Verification

**Task Category**: INTEGRATION

### INTEGRATION Tasks (REQUIRE visual verification):

This task wires the yAxisId field into the chart, enabling series to directly specify their axis binding.

#### Step 1: Create Standalone Demo File

**Demo Path**: `example/lib/demos/task_015_api_demo.dart`

```dart
import 'package:flutter/material.dart';
import 'package:braven_charts/braven_charts.dart';

void main() => runApp(const Task015ApiDemo());

class Task015ApiDemo extends StatelessWidget {
  const Task015ApiDemo({super.key});

  @override
  Widget build(BuildContext context) {
    // Series with direct yAxisId binding (new feature!)
    final powerSeries = LineChartSeries(
      id: 'power',
      name: 'Power Output',
      points: _generatePowerData(),
      color: Colors.blue,
      yAxisId: 'power-axis',  // Direct binding via yAxisId
      unit: 'W',
    );

    final hrSeries = LineChartSeries(
      id: 'heartrate',
      name: 'Heart Rate',
      points: _generateHRData(),
      color: Colors.red,
      yAxisId: 'hr-axis',  // Direct binding via yAxisId
      unit: 'bpm',
    );

    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Task 15: API Demo - yAxisId on Series')),
        body: Center(
          child: SizedBox(
            width: 800,
            height: 500,
            child: BravenChartPlus(
              chartType: ChartType.line,
              series: [powerSeries, hrSeries],
              yAxes: [
                YAxisConfig(
                  id: 'power-axis',
                  position: YAxisPosition.left,
                  label: 'Power',
                  unit: 'W',
                ),
                YAxisConfig(
                  id: 'hr-axis',
                  position: YAxisPosition.right,
                  label: 'Heart Rate',
                  unit: 'bpm',
                ),
              ],
              // Note: No axisBindings needed - yAxisId on series handles binding!
            ),
          ),
        ),
      ),
    );
  }

  List<ChartDataPoint> _generatePowerData() {
    return List.generate(50, (i) => ChartDataPoint(
      x: i.toDouble(),
      y: 150 + 100 * (i % 10 < 5 ? i % 10 / 5 : (10 - i % 10) / 5),
    ));
  }

  List<ChartDataPoint> _generateHRData() {
    return List.generate(50, (i) => ChartDataPoint(
      x: i.toDouble(),
      y: 80 + 40 * (i % 10 < 5 ? i % 10 / 5 : (10 - i % 10) / 5),
    ));
  }
}
```

#### Step 2: Flutter Agent Workflow

1. **Start Flutter with the standalone demo** (from repo root):

```powershell
Start-Process -FilePath "powershell" -ArgumentList "-NoExit", "-Command", `
  "cd 'e:\cloud services\Dropbox\Repositories\Flutter\braven_charts_v2.0\example'; python ..\tools\flutter_agent\flutter_agent.py run lib/demos/task_015_api_demo.dart -d chrome"
```

2. **Wait for app to be ready**:

```powershell
cd "e:\cloud services\Dropbox\Repositories\Flutter\braven_charts_v2.0\example"
python ..\tools\flutter_agent\flutter_agent.py wait --timeout 30
```

3. **Take screenshot**:

```powershell
python ..\tools\flutter_agent\flutter_agent.py screenshot --output ../screenshots/task-015-api-demo.png
```

4. **Stop when done**:

```powershell
python ..\tools\flutter_agent\flutter_agent.py stop
```

**Expected Visual Output**:

- Chart displays two series (Power and Heart Rate)
- Left Y-axis shows Power values (0-300 range) in blue
- Right Y-axis shows Heart Rate values (80-120 range) in red
- Each series uses full vertical height (normalized)
- Axis labels show unit suffix (W, bpm)

---

## Quality Gates (MANDATORY)

### 🚫 YOU TOUCH IT, YOU OWN IT - ZERO TOLERANCE

**If you CREATE or MODIFY a file, ALL analyzer issues in that file are YOUR responsibility.**

- ❌ "Pre-existing issues" - **NOT AN EXCUSE**
- ❌ "The warning was already there" - **NOT AN EXCUSE**
- ❌ "I only changed a few lines" - **NOT AN EXCUSE**

You MUST fix ALL issues (errors, warnings, AND infos) before signaling completion.
Your completion signal WILL BE REJECTED if any issues remain.

### Linting - Zero Issues

```bash
flutter analyze lib/src/models/chart_series.dart
flutter analyze lib/src/braven_chart_plus.dart
flutter analyze test/unit/multi_axis/chart_series_axis_fields_test.dart
flutter analyze test/widget/multi_axis/api_validation_test.dart
```

### All Sprint Tests Must Pass

```bash
flutter test test/unit/multi_axis/
flutter test test/widget/multi_axis/
```

**Current Test Baseline**: 270 tests (MUST NOT decrease!)

---

## Completion Protocol

When done:

1. **Verify linting is clean** (BLOCKING)
2. **Verify ALL tests pass** (BLOCKING)
3. **Visual verification completed** (screenshot taken)
4. Stage your changes: `git add .`
5. Write to `.orchestra/handover/completion-signal.md`:
   - Files created/modified
   - Number of tests added
   - Confirm linting clean
   - Confirm all sprint tests pass
   - Visual verification notes (if applicable)
6. Say "Task complete - ready for review"
