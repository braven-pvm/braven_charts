# Task 14: Disable Y-Zoom and Grid Lines in Multi-Axis Mode

## Objective

Disable Y-axis zoom/pan and horizontal grid lines when multi-axis mode is active, while preserving X-axis zoom functionality.

## Context

Multi-axis mode uses per-axis normalization where all series are displayed in 0-1 normalized space - zooming the Y-axis would break this normalization and grid lines become meaningless since each axis has different scales. This task builds on Task 13 (crosshair per-axis bounds) by adding zoom/pan constraints.

**Phase**: Interaction

**Category**: VISUAL (requires screenshot)

---

## SpecKit Traceability

**SpecKit Tasks Covered**:

- T012a [P] **[FR-009]** Disable grid lines when multi-axis active in `lib/src/rendering/chart_render_box.dart`
- T012b [P] Unit test for Y-axis zoom constraint in `test/unit/multi_axis/zoom_constraint_test.dart`
- T012c **[FR-013]** Disable Y-axis zoom/pan when multi-axis mode active - X-axis zoom remains functional

**Contract References**:

- [N/A - Feature requirements from spec, not contract-based]

---

## Deliverables

| Operation | File | Purpose |
|-----------|------|---------|
| CREATE | `test/unit/multi_axis/zoom_constraint_test.dart` | Unit tests for zoom constraint behavior |
| CREATE | `example/lib/demos/task_014_zoom_grid_demo.dart` | Standalone demo showing disabled Y-zoom and no grid |
| UPDATE | `lib/src/rendering/chart_render_box.dart` | Disable Y-zoom and skip horizontal grid lines in multi-axis mode |

### Integration Changes (for UPDATE files):

```dart
// In ChartRenderBox, where horizontal grid lines are painted:
// Add check: if (_hasMultipleYAxes()) skip horizontal grid lines

// In wheel/scroll event handling for Y-axis:
// Add check: if (_hasMultipleYAxes()) ignore Y-axis zoom/pan events
// X-axis zoom/pan should REMAIN functional

// Example pattern:
void _handleWheelEvent(...) {
  // ... existing X-axis handling ...
  
  // Y-axis handling - skip if multi-axis mode
  if (!_hasMultipleYAxes()) {
    // existing Y-axis zoom/pan logic
  }
}
```

---

## Technical Context

### Dependencies (imports from completed tasks):

```dart
// Already available in chart_render_box.dart:
import 'multi_axis_normalizer.dart';
import 'multi_axis_painter.dart';
// Already has: _hasMultipleYAxes() method
```

### ⚠️ MUST USE (DO NOT DUPLICATE):

| Utility | Use For | DO NOT |
|---------|---------|--------|
| `_hasMultipleYAxes()` | Check if multi-axis mode is active | Create another flag or check |

### Relevant Existing Code:

- `lib/src/rendering/chart_render_box.dart` - Main rendering logic, already has `_hasMultipleYAxes()` at line 640
- Wheel/scroll handling is in this file
- Grid line painting location needs to be identified (search for horizontal line drawing)

---

## Testing

**Test File**: `test/unit/multi_axis/zoom_constraint_test.dart`

**Test Cases to Implement FIRST**:

1. `Y-axis zoom is disabled when multiple Y-axes configured`
2. `X-axis zoom remains functional when multiple Y-axes configured`
3. `Y-axis pan is disabled when multiple Y-axes configured`
4. `X-axis pan remains functional when multiple Y-axes configured`
5. `Single Y-axis mode allows Y-zoom and Y-pan normally`
6. `Switching from single to multi-axis disables Y-zoom`
7. `Grid lines are disabled in multi-axis mode`
8. `Grid lines are enabled in single-axis mode`

### Sample Test Data

```dart
// Sample multi-axis configuration (2 axes = multi-axis mode)
final multiAxisConfig = [
  YAxisConfig(id: 'power', position: YAxisPosition.left),
  YAxisConfig(id: 'heart-rate', position: YAxisPosition.right),
];

// Sample single-axis configuration (1 axis = normal mode)
final singleAxisConfig = [
  YAxisConfig(id: 'default', position: YAxisPosition.left),
];

// Or null for legacy mode
final noAxesConfig = null;

// Test that hasMultipleYAxes() returns true/false appropriately:
expect(renderBox.hasMultipleYAxes, isTrue); // with multiAxisConfig
expect(renderBox.hasMultipleYAxes, isFalse); // with singleAxisConfig or null
```

---

## Code Scaffolds

```dart
// test/unit/multi_axis/zoom_constraint_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:braven_charts/src/models/y_axis_config.dart';
import 'package:braven_charts/src/models/y_axis_position.dart';

void main() {
  group('Multi-Axis Zoom Constraints', () {
    group('Y-axis zoom behavior', () {
      test('Y-axis zoom is disabled when multiple Y-axes configured', () {
        // IMPLEMENT:
        // Setup chart with 2+ Y-axes
        // Attempt Y-axis zoom (wheel event)
        // Verify Y viewport unchanged
      });

      test('X-axis zoom remains functional in multi-axis mode', () {
        // IMPLEMENT:
        // Setup chart with 2+ Y-axes
        // Perform X-axis zoom
        // Verify X viewport changed
      });

      test('Single Y-axis mode allows Y-zoom normally', () {
        // IMPLEMENT:
        // Setup chart with 1 Y-axis
        // Perform Y-axis zoom
        // Verify Y viewport changed
      });
    });

    group('Grid line behavior', () {
      test('Grid lines disabled in multi-axis mode', () {
        // IMPLEMENT:
        // Setup chart with 2+ Y-axes
        // Verify horizontal grid lines not painted
      });

      test('Grid lines enabled in single-axis mode', () {
        // IMPLEMENT:
        // Setup chart with 1 Y-axis
        // Verify horizontal grid lines painted
      });
    });
  });
}
```

---

## Visual Verification

**Task Category**: VISUAL

### INTEGRATION / VISUAL Tasks (REQUIRE visual verification):

These tasks wire components into BravenChartPlus or modify rendering. A
STANDALONE demo is required to isolate the visual behavior being tested.

#### Step 1: Create Standalone Demo File

**Demo Path**: `example/lib/demos/task_014_zoom_grid_demo.dart`

```dart
import 'package:flutter/material.dart';
import 'package:braven_charts/braven_charts.dart';

void main() => runApp(const Task014Demo());

class Task014Demo extends StatefulWidget {
  const Task014Demo({super.key});

  @override
  State<Task014Demo> createState() => _Task014DemoState();
}

class _Task014DemoState extends State<Task014Demo> {
  bool _multiAxisMode = true;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Task 014: Y-Zoom & Grid Constraints'),
          actions: [
            Switch(
              value: _multiAxisMode,
              onChanged: (v) => setState(() => _multiAxisMode = v),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Text(_multiAxisMode ? 'Multi-Axis' : 'Single-Axis'),
              ),
            ),
          ],
        ),
        body: Center(
          child: SizedBox(
            width: 800,
            height: 600,
            child: BravenChartPlus(
              series: [
                ChartSeries(
                  id: 'power',
                  points: List.generate(50, (i) => 
                    ChartDataPoint(x: i.toDouble(), y: 200 + 50 * (i % 10).toDouble())),
                  color: Colors.blue,
                ),
                ChartSeries(
                  id: 'heart-rate',
                  points: List.generate(50, (i) => 
                    ChartDataPoint(x: i.toDouble(), y: 120 + 30 * ((i + 5) % 10).toDouble())),
                  color: Colors.red,
                ),
              ],
              yAxes: _multiAxisMode
                  ? [
                      YAxisConfig(id: 'power', position: YAxisPosition.left, label: 'Power (W)'),
                      YAxisConfig(id: 'heart-rate', position: YAxisPosition.right, label: 'HR (bpm)'),
                    ]
                  : [
                      YAxisConfig(id: 'default', position: YAxisPosition.left),
                    ],
              axisBindings: _multiAxisMode
                  ? [
                      SeriesAxisBinding(seriesId: 'power', yAxisId: 'power'),
                      SeriesAxisBinding(seriesId: 'heart-rate', yAxisId: 'heart-rate'),
                    ]
                  : [],
              // Add interaction config if needed to test zoom behavior
            ),
          ),
        ),
        bottomSheet: Container(
          color: Colors.grey[200],
          padding: const EdgeInsets.all(16),
          child: Text(
            _multiAxisMode
                ? '✓ Multi-axis mode: No horizontal grid lines, Y-zoom disabled, X-zoom works'
                : '✓ Single-axis mode: Grid lines visible, both X and Y zoom work',
            style: const TextStyle(fontSize: 14),
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
  "cd 'e:\cloud services\Dropbox\Repositories\Flutter\braven_charts_v2.0\example'; python ..\tools\flutter_agent\flutter_agent.py run lib/demos/task_014_zoom_grid_demo.dart -d chrome"
```

2. **Wait for app to be ready**:

```powershell
cd "e:\cloud services\Dropbox\Repositories\Flutter\braven_charts_v2.0\example"
python ..\tools\flutter_agent\flutter_agent.py wait --timeout 30
```

3. **Take screenshot**:

```powershell
python ..\tools\flutter_agent\flutter_agent.py screenshot --output ../screenshots/task-014-multi-axis-constraints.png
```

4. **Stop when done**:

```powershell
python ..\tools\flutter_agent\flutter_agent.py stop
```

**Expected Visual Output**:

- **Multi-axis mode ON**:
  - Two Y-axes visible (left: Power, right: HR)
  - NO horizontal grid lines
  - Mouse wheel Y-scroll has no effect
  - Mouse wheel X-scroll (with Shift or horizontal scroll) still works
  
- **Multi-axis mode OFF** (toggle switch):
  - Single Y-axis visible
  - Horizontal grid lines VISIBLE
  - Both X and Y zoom work normally

---

## Quality Gates

### 🚫 YOU TOUCH IT, YOU OWN IT - ZERO TOLERANCE

**If you CREATE or MODIFY a file, ALL analyzer issues in that file are YOUR responsibility.**

- ❌ "Pre-existing issues" - **NOT AN EXCUSE**
- ❌ "The warning was already there" - **NOT AN EXCUSE**
- ❌ "I only changed a few lines" - **NOT AN EXCUSE**

You MUST fix ALL issues (errors, warnings, AND infos) before signaling completion.
Your completion signal WILL BE REJECTED if any issues remain.

### Linting - Zero Issues

```bash
flutter analyze lib/src/rendering/chart_render_box.dart
flutter analyze test/unit/multi_axis/zoom_constraint_test.dart
flutter analyze example/lib/demos/task_014_zoom_grid_demo.dart
```

### All Sprint Tests Must Pass

```bash
flutter test test/unit/multi_axis/
```

**Current Test Baseline**: 237 tests (MUST NOT decrease!)

---

## Acceptance Criteria

- [ ] Y-axis zoom/pan is disabled when multi-axis mode active (2+ Y-axes)
- [ ] X-axis zoom/pan remains functional in multi-axis mode
- [ ] Horizontal grid lines are not drawn when multi-axis mode active
- [ ] Single-axis mode (1 Y-axis) works exactly as before (grid + Y-zoom)
- [ ] All tests pass (baseline: 237 + new tests)
- [ ] All touched files pass `flutter analyze` with zero issues
- [ ] Screenshot captured showing both modes

---

## Completion Protocol

When done:

1. **Verify linting is clean** (BLOCKING)
2. **Verify ALL tests pass** (BLOCKING)
3. **Visual verification completed** (screenshot captured)
4. Stage your changes: `git add .`
5. Run: `.orchestra/handover/.implementor/scripts/pre-signal-check.ps1`
6. Write to `.orchestra/handover/completion-signal.md`:
   - Files created/modified
   - Number of tests added
   - Confirm linting clean
   - Confirm all sprint tests pass
   - Visual verification notes
7. Say "Task complete - ready for review"
