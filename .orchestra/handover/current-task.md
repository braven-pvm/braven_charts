# Task 16: Create Working Demo Example

## Objective

Create a comprehensive showcase demonstrating all multi-axis features, add golden tests for visual regression, validate backward compatibility, and update documentation to complete Sprint 011.

## 1. Task Overview

This is the **FINAL TASK** of the multi-axis normalization sprint. It brings together all 15 previous tasks into a comprehensive working demonstration, adds golden tests for visual regression, validates backward compatibility, and updates documentation.

**Phase**: Integration (Final Validation)

**Category**: VISUAL

This task validates the complete sprint by creating:
1. Golden tests for visual regression testing
2. A comprehensive showcase demo demonstrating all 4 user stories
3. Backward compatibility validation (single-axis mode unchanged)
4. Performance benchmark
5. CHANGELOG documentation

---

## 2. SpecKit Traceability

**SpecKit Tasks Covered**:

- T009 - Create test directory structure at `test/golden/multi_axis/`
- T016 - Golden test for 2-axis chart
- T017 - Golden test for 4-axis chart
- T024 - Add example multi-axis chart to showcase (US1)
- T030 - Add auto-detection example to showcase (US2)
- T033 - Golden test for colored axes (US3)
- T039 - Add themed axis color example to showcase (US3)
- T046 - Add crosshair example to showcase (US4)
- T050 - Run performance benchmark
- T051 - Validate backward compatibility
- T052 - Run quickstart.md validation
- T053 - Update CHANGELOG.md

**Contract References**: N/A

---

## 3. Deliverables

### File Operations:

- CREATE: `test/golden/multi_axis/.gitkeep` - Create golden test directory
- CREATE: `test/golden/multi_axis/two_axis_chart_test.dart` - Golden test for 2-axis config
- CREATE: `test/golden/multi_axis/four_axis_chart_test.dart` - Golden test for 4-axis config
- CREATE: `test/golden/multi_axis/colored_axes_test.dart` - Golden test for color-coded axes
- CREATE: `test/widget/multi_axis/backward_compat_test.dart` - Verify single-axis unchanged
- CREATE: `test/benchmarks/multi_axis_benchmark.dart` - Performance validation
- CREATE: `example/lib/demos/task_016_showcase_demo.dart` - Comprehensive showcase
- UPDATE: `CHANGELOG.md` - Add multi-axis normalization feature entry

### Integration Changes:

```markdown
# CHANGELOG.md addition (at top of Unreleased section):

## [Unreleased]

### Added
- Multi-axis Y normalization for displaying series with vastly different scales
  - Each series uses full vertical height with its own Y-axis
  - Up to 4 Y-axes supported (left, leftOuter, right, rightOuter)
  - Color-coded axes match their bound series
  - Tooltips and crosshair display original (non-normalized) values
- Automatic normalization detection when series ranges differ >10x
- New `yAxisId` and `unit` fields on `ChartSeries` for direct axis binding
- `YAxisConfig` class for configuring additional Y-axes
- `NormalizationMode` enum: `none`, `auto`, `perSeries`
```

---

## 4. Technical Context

### Dependencies (imports from completed tasks):

```dart
import 'package:braven_charts/braven_charts.dart';
// This exports all the multi-axis components:
// - YAxisConfig, YAxisPosition
// - NormalizationMode
// - ChartSeries with yAxisId, unit fields
// - BravenChartPlus with yAxes, normalizationMode params
```

### ⚠️ MUST USE (DO NOT DUPLICATE):

| Utility | Use For | DO NOT |
| ------- | ------- | ------ |
| `BravenChartPlus` widget | Chart rendering | Create custom chart widget |
| `YAxisConfig` | Axis configuration | Custom axis config class |
| `LineChartSeries.yAxisId` | Axis binding | Manual binding logic |

### Relevant Existing Code:

- `example/lib/demos/task_015_api_demo.dart` - Reference for demo structure
- `test/widget/multi_axis/` - Existing widget tests for patterns
- `lib/src/models/y_axis_config.dart` - YAxisConfig class
- `lib/src/models/chart_series.dart` - ChartSeries with yAxisId/unit

---

## Testing

### Golden Tests

**Directory**: `test/golden/multi_axis/`

Golden tests capture visual snapshots and compare them on future runs to detect visual regressions.

**Test File 1**: `test/golden/multi_axis/two_axis_chart_test.dart`
- 2-axis chart (left + right)
- Different data scales (e.g., 0-300 vs 60-180)
- Verify both series span full height

**Test File 2**: `test/golden/multi_axis/four_axis_chart_test.dart`
- 4-axis chart (leftOuter, left, right, rightOuter)
- Four different data ranges
- Verify all axes render without overlap

**Test File 3**: `test/golden/multi_axis/colored_axes_test.dart`
- 2+ axes with explicit colors
- Verify axis color matches series color
- Test both explicit color and color-from-series

### Backward Compatibility Test

**Test File**: `test/widget/multi_axis/backward_compat_test.dart`

Test Cases:
1. Single-axis chart renders identically to before sprint
2. No yAxes parameter = classic single-axis behavior
3. Grid lines visible in single-axis mode
4. Y-zoom works in single-axis mode

### Performance Benchmark

**Test File**: `test/benchmarks/multi_axis_benchmark.dart`

Benchmark:
- 4 series × 1000 points each
- Target: 60 FPS (16.67ms per frame)
- Measure normalization overhead

### Sample Test Structure

```dart
// Golden test example
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:braven_charts/braven_charts.dart';

void main() {
  group('Two-Axis Golden Tests', () {
    testWidgets('two axis chart renders correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 800,
              height: 600,
              child: BravenChartPlus(
                chartType: ChartType.line,
                series: [
                  LineChartSeries(
                    id: 'power',
                    points: _generatePowerData(),
                    color: Colors.blue,
                    yAxisId: 'power-axis',
                  ),
                  LineChartSeries(
                    id: 'hr',
                    points: _generateHRData(),
                    color: Colors.red,
                    yAxisId: 'hr-axis',
                  ),
                ],
                yAxes: [
                  YAxisConfig(
                    id: 'power-axis',
                    position: YAxisPosition.left,
                    color: Colors.blue,
                  ),
                  YAxisConfig(
                    id: 'hr-axis',
                    position: YAxisPosition.right,
                    color: Colors.red,
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      await expectLater(
        find.byType(BravenChartPlus),
        matchesGoldenFile('goldens/two_axis_chart.png'),
      );
    });
  });
}

List<ChartDataPoint> _generatePowerData() => 
    List.generate(50, (i) => ChartDataPoint(x: i.toDouble(), y: 150 + 50 * (i % 10) / 10));

List<ChartDataPoint> _generateHRData() => 
    List.generate(50, (i) => ChartDataPoint(x: i.toDouble(), y: 80 + 20 * (i % 10) / 10));
```

---

## 6. Code Scaffolds

### Showcase Demo Structure

```dart
// example/lib/demos/task_016_showcase_demo.dart

import 'package:flutter/material.dart';
import 'package:braven_charts/braven_charts.dart';

void main() => runApp(const Task016ShowcaseDemo());

class Task016ShowcaseDemo extends StatefulWidget {
  const Task016ShowcaseDemo({super.key});

  @override
  State<Task016ShowcaseDemo> createState() => _Task016ShowcaseDemoState();
}

class _Task016ShowcaseDemoState extends State<Task016ShowcaseDemo> {
  int _selectedDemo = 0;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Multi-Axis Showcase',
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Sprint 011: Multi-Axis Normalization'),
        ),
        body: Column(
          children: [
            // Demo selector tabs
            _buildDemoSelector(),
            // Active demo
            Expanded(child: _buildActiveDemo()),
          ],
        ),
      ),
    );
  }

  Widget _buildDemoSelector() {
    final demos = [
      'US1: Multi-Scale',
      'US2: Auto-Detect',
      'US3: Color-Coded',
      'US4: Crosshair',
    ];
    // Build tab bar for demo selection
    // ...
  }

  Widget _buildActiveDemo() {
    switch (_selectedDemo) {
      case 0: return _buildMultiScaleDemo();   // US1
      case 1: return _buildAutoDetectDemo();   // US2
      case 2: return _buildColorCodedDemo();   // US3
      case 3: return _buildCrosshairDemo();    // US4
      default: return _buildMultiScaleDemo();
    }
  }

  // US1: Multi-Scale Visualization
  Widget _buildMultiScaleDemo() {
    // Power (0-300W) + Heart Rate (60-200bpm)
    // Both should use full vertical space
  }

  // US2: Auto-Detection
  Widget _buildAutoDetectDemo() {
    // No explicit yAxes - just normalizationMode: auto
    // System detects range difference > 10x and enables multi-axis
  }

  // US3: Color-Coded Axes
  Widget _buildColorCodedDemo() {
    // Explicit colors on YAxisConfig
    // Shows axis lines/labels/ticks in series color
  }

  // US4: Crosshair with Original Values
  Widget _buildCrosshairDemo() {
    // Enable crosshair interaction
    // Hover shows original values (not normalized 0-1)
  }
}
```

---

## 7. Visual Verification

**Task Category**: VISUAL

This is a VISUAL task - screenshot verification is REQUIRED.

#### Step 1: Create Standalone Demo File

**Demo Path**: `example/lib/demos/task_016_showcase_demo.dart`

The demo should display a tabbed view showing all 4 user stories:
1. **US1 Tab**: Multi-scale chart (Power W vs Heart Rate bpm)
2. **US2 Tab**: Auto-detection mode (no explicit config, just data with >10x range diff)
3. **US3 Tab**: Color-coded axes (blue left axis, red right axis)
4. **US4 Tab**: Crosshair interaction with original value display

#### Step 2: Flutter Agent Workflow

1. **Start Flutter with the standalone demo** (from repo root):

```powershell
Start-Process -FilePath "powershell" -ArgumentList "-NoExit", "-Command", `
  "cd 'e:\cloud services\Dropbox\Repositories\Flutter\braven_charts_v2.0\example'; python ..\tools\flutter_agent\flutter_agent.py run lib/demos/task_016_showcase_demo.dart -d chrome"
```

2. **Wait for app to be ready**:

```powershell
cd "e:\cloud services\Dropbox\Repositories\Flutter\braven_charts_v2.0\example"
python ..\tools\flutter_agent\flutter_agent.py wait --timeout 30
```

3. **Take screenshot**:

```powershell
python ..\tools\flutter_agent\flutter_agent.py screenshot --output ..\screenshots\task-016-showcase.png
```

4. **Stop when done**:

```powershell
python ..\tools\flutter_agent\flutter_agent.py stop
```

**Expected Visual Output**:

- Chart with multiple Y-axes visible (left and right sides)
- Each axis colored to match its series
- All series using full vertical space despite different data ranges
- Axis labels showing original values (e.g., "150 W", "85 bpm")
- Tab selector for switching between user story demos

---

## 8. Quality Gates (MANDATORY)

### 🚫 YOU TOUCH IT, YOU OWN IT - ZERO TOLERANCE

**If you CREATE or MODIFY a file, ALL analyzer issues in that file are YOUR responsibility.**

- ❌ "Pre-existing issues" - **NOT AN EXCUSE**
- ❌ "The warning was already there" - **NOT AN EXCUSE**
- ❌ "I only changed a few lines" - **NOT AN EXCUSE**

You MUST fix ALL issues (errors, warnings, AND infos) before signaling completion.
Your completion signal WILL BE REJECTED if any issues remain.

### Linting - Zero Issues

```bash
flutter analyze example/lib/demos/task_016_showcase_demo.dart
flutter analyze test/golden/multi_axis/
flutter analyze test/widget/multi_axis/backward_compat_test.dart
flutter analyze test/benchmarks/multi_axis_benchmark.dart
```

### All Sprint Tests Must Pass

```bash
flutter test test/unit/multi_axis/
flutter test test/widget/multi_axis/
flutter test test/golden/multi_axis/
```

**Current Test Baseline**: 262 tests (MUST NOT decrease!)

---

## 9. Completion Protocol

When done:

1. **Verify linting is clean** (BLOCKING)
2. **Verify ALL tests pass** (BLOCKING)
3. **Generate golden baselines**: `flutter test test/golden/multi_axis/ --update-goldens`
4. **Visual verification completed** (screenshot captured)
5. Stage your changes: `git add .`
6. Write to `.orchestra/handover/completion-signal.md`:
   - Files created/modified
   - Number of tests added
   - Confirm linting clean
   - Confirm all sprint tests pass
   - Visual verification notes
7. Say "Task complete - ready for review"

---

## Acceptance Criteria

- [ ] Golden test directory `test/golden/multi_axis/` exists
- [ ] `two_axis_chart_test.dart` has 3+ test cases
- [ ] `four_axis_chart_test.dart` has 3+ test cases  
- [ ] `colored_axes_test.dart` has 3+ test cases
- [ ] `backward_compat_test.dart` validates single-axis unchanged
- [ ] `multi_axis_benchmark.dart` measures performance
- [ ] `task_016_showcase_demo.dart` demonstrates all 4 user stories
- [ ] CHANGELOG.md has multi-axis feature entry
- [ ] Screenshot captured showing working demo
- [ ] All 262+ sprint tests pass
- [ ] Zero analyzer issues in all created files

---

## 10. Success Criteria Summary

This task succeeds when:

✅ Golden test directory exists with 3 test files
✅ Each golden test has at least 3 test cases
✅ Showcase demo runs and displays all 4 user stories
✅ Backward compatibility tests pass (single-axis mode unchanged)
✅ Performance benchmark exists (60 FPS target documented)
✅ CHANGELOG.md updated with feature entry
✅ Screenshot captured showing multi-axis chart
✅ All 262+ tests pass
✅ Zero analyzer issues
