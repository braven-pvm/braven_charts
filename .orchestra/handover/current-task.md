# Current Task: Task 11 - Integrate Multi-Axis Painter with Chart Widget

## Task Overview

**Objective**: Wire the complete multi-axis rendering pipeline into `BravenChartPlus`, adding the `yAxes` and `normalizationMode` parameters to the widget API and creating widget tests.

**Category**: ⚠️ **INTEGRATION TASK** - Modifies existing `BravenChartPlus` widget

**Current State**:
- `MultiAxisPainter` exists and renders colored axes (Task 9, 10)
- `MultiAxisNormalizer` exists with normalization logic (Task 6)
- `NormalizationDetector` exists for auto-detection (Task 7)
- `BravenChartPlus` has `_normalizationNeeded` flag but NO `yAxes` parameter
- `ChartRenderBox` has `normalizeValue()`/`denormalizeValue()` methods (Task 8)
- Widget test directory `test/widget/multi_axis/` does NOT exist

**Required State**:
- `BravenChartPlus` accepts `yAxes: List<YAxisConfig>` parameter
- `BravenChartPlus` accepts `normalizationMode: NormalizationMode` parameter  
- `MultiAxisPainter` is called from render box when multi-axis is active
- Series-to-axis binding resolution implemented
- Widget test directory created with tests for multi-axis, auto-detection, and color-coded axes

---

## SpecKit Traceability

| SpecKit ID | Description | Status |
|------------|-------------|--------|
| T010 | Add `yAxes` and `normalizationMode` parameters to BravenChartPlus | ⏳ Pending |
| T015 | Widget test for multi-axis rendering | ⏳ Pending |
| T008 | Create test directory structure at `test/widget/multi_axis/` | ⏳ Pending |
| T018 | Implement series-to-axis binding resolution | ⏳ Pending |
| T026 | Widget test for auto-mode triggering (US2) | ⏳ Pending |
| T032 | Widget test for color-coded axes (US3) | ⏳ Pending |

**Total SpecKit Tasks**: 6

---

## Deliverables

### Files to CREATE

| File | Purpose | Export To |
|------|---------|-----------|
| `test/widget/multi_axis/multi_axis_chart_test.dart` | T015 - Widget test for multi-axis | N/A |
| `test/widget/multi_axis/auto_detection_widget_test.dart` | T026 - Widget test for auto-detection | N/A |
| `test/widget/multi_axis/axis_color_widget_test.dart` | T032 - Widget test for color-coded axes | N/A |
| `lib/src/axis/series_axis_resolver.dart` | T018 - Series-to-axis binding resolution | `lib/braven_charts.dart` |
| `example/lib/demos/task_011_integration_demo.dart` | Visual verification demo | N/A |

### Files to MODIFY

| File | Changes |
|------|---------|
| `lib/src/braven_chart_plus.dart` | Add `yAxes`, `normalizationMode`, `bindings` parameters |
| `lib/src/rendering/chart_render_box.dart` | Call `MultiAxisPainter` when multi-axis active |
| `lib/braven_charts.dart` | Export new classes if any |

### Integration Changes (CRITICAL - read carefully)

#### 1. BravenChartPlus Widget Changes

```dart
// lib/src/braven_chart_plus.dart

// Add new parameters to constructor (around line 65):
const BravenChartPlus({
  // ... existing parameters ...
  this.yAxes,                    // NEW: List of Y-axis configurations
  this.normalizationMode,        // NEW: Auto, manual, or disabled
  this.axisBindings,             // NEW: Series-to-axis bindings
  // ... rest of parameters ...
});

// Add new fields (around line 445):
/// Y-axis configurations for multi-axis mode.
///
/// When provided with more than one axis, the chart enters multi-axis mode
/// where each series can be bound to a specific Y-axis via [axisBindings].
///
/// If null or empty, the chart uses the default single Y-axis mode.
final List<YAxisConfig>? yAxes;

/// Controls how normalization is applied to multi-axis data.
///
/// - [NormalizationMode.auto]: Automatically detect when normalization is needed
/// - [NormalizationMode.perAxis]: Always normalize each axis independently
/// - [NormalizationMode.none]: Never normalize (use global Y scale)
///
/// Defaults to [NormalizationMode.auto] when [yAxes] is provided.
final NormalizationMode? normalizationMode;

/// Bindings that connect series to specific Y-axes.
///
/// Each binding maps a series ID to a Y-axis ID. Series without explicit
/// bindings use the first (default) axis.
final List<SeriesAxisBinding>? axisBindings;
```

#### 2. ChartRenderBox Integration

```dart
// lib/src/rendering/chart_render_box.dart

// In paint() method, after painting grid and before painting series:
// Check if multi-axis mode is active
if (_hasMultipleYAxes()) {
  _paintMultipleYAxes(context, offset);
}

// New method to check multi-axis mode:
bool _hasMultipleYAxes() {
  return widget.yAxes != null && widget.yAxes!.length > 1;
}

// New method to paint multiple Y-axes:
void _paintMultipleYAxes(PaintingContext context, Offset offset) {
  final canvas = context.canvas;
  
  // Compute axis bounds for each axis
  final axisBounds = MultiAxisNormalizer.computeAxisBounds(
    series: widget.series,
    bindings: widget.axisBindings ?? [],
  );
  
  // Create and invoke painter
  final painter = MultiAxisPainter(
    axes: widget.yAxes!,
    axisBounds: axisBounds,
    bindings: widget.axisBindings ?? [],
    series: widget.series,
  );
  
  painter.paint(canvas, _plotArea);
}
```

#### 3. Series-Axis Resolver (T018)

```dart
// lib/src/axis/series_axis_resolver.dart

/// Resolves which Y-axis a series should use.
///
/// Resolution priority:
/// 1. Explicit binding via [SeriesAxisBinding]
/// 2. First (default) axis if no binding exists
class SeriesAxisResolver {
  const SeriesAxisResolver._();

  /// Resolves the Y-axis ID for a given series.
  static String resolveAxisId(
    String seriesId,
    List<SeriesAxisBinding> bindings,
    List<YAxisConfig> axes,
  ) {
    // Find explicit binding
    final binding = bindings.firstWhere(
      (b) => b.seriesId == seriesId,
      orElse: () => SeriesAxisBinding(
        seriesId: seriesId, 
        yAxisId: axes.first.id,
      ),
    );
    return binding.yAxisId;
  }
  
  /// Resolves the [YAxisConfig] for a given series.
  static YAxisConfig? resolveAxis(
    String seriesId,
    List<SeriesAxisBinding> bindings,
    List<YAxisConfig> axes,
  ) {
    final axisId = resolveAxisId(seriesId, bindings, axes);
    return axes.firstWhere(
      (a) => a.id == axisId,
      orElse: () => axes.first,
    );
  }
}
```

---

## Technical Context

### Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────┐
│                        BravenChartPlus                               │
│  ┌─────────────────────────────────────────────────────────────────┐ │
│  │ yAxes: [YAxisConfig, YAxisConfig]                               │ │
│  │ normalizationMode: NormalizationMode.auto                       │ │
│  │ axisBindings: [SeriesAxisBinding, SeriesAxisBinding]            │ │
│  └─────────────────────────────────────────────────────────────────┘ │
│                              │                                       │
│                              ▼                                       │
│  ┌─────────────────────────────────────────────────────────────────┐ │
│  │                     ChartRenderBox                               │ │
│  │                              │                                   │ │
│  │  ┌───────────────────────────┼───────────────────────────────┐  │ │
│  │  │                           ▼                               │  │ │
│  │  │  if (hasMultipleYAxes) → MultiAxisPainter.paint()         │  │ │
│  │  │                                                           │  │ │
│  │  │  Series rendering uses:                                   │  │ │
│  │  │    SeriesAxisResolver.resolveAxis()                       │  │ │
│  │  │    MultiAxisNormalizer.normalize()                        │  │ │
│  │  └───────────────────────────────────────────────────────────┘  │ │
│  └─────────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────────┘
```

### MUST USE (DO NOT DUPLICATE)

| Component | Location | Purpose |
|-----------|----------|---------|
| `MultiAxisPainter` | `lib/src/rendering/multi_axis_painter.dart` | Renders Y-axes with colors |
| `MultiAxisNormalizer` | `lib/src/rendering/multi_axis_normalizer.dart` | Normalizes data values |
| `AxisColorResolver` | `lib/src/rendering/axis_color_resolver.dart` | Resolves axis colors |
| `NormalizationDetector` | `lib/src/axis/normalization_detector.dart` | Auto-detection logic |
| `YAxisConfig` | `lib/src/models/y_axis_config.dart` | Axis configuration model |
| `SeriesAxisBinding` | `lib/src/models/series_axis_binding.dart` | Series-axis binding model |

### Existing Infrastructure (from prior tasks)

```dart
// Already in BravenChartPlus state (Task 8):
bool _normalizationNeeded = false;
Map<String, DataRange> _seriesYRanges = {};

// Already in ChartRenderBox (Task 8):
double normalizeValue(double value, double min, double max);
double denormalizeValue(double normalizedValue, double min, double max);
```

---

## TDD Requirements

### Test Directory: `test/widget/multi_axis/`

Create this directory structure:
```
test/widget/multi_axis/
├── multi_axis_chart_test.dart      (T015)
├── auto_detection_widget_test.dart (T026)  
└── axis_color_widget_test.dart     (T032)
```

### T015: multi_axis_chart_test.dart

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:braven_charts/braven_charts.dart';

void main() {
  group('Multi-Axis Chart Widget', () {
    testWidgets('renders chart with multiple Y-axes', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BravenChartPlus(
              chartType: ChartType.line,
              series: [
                LineChartSeries(id: 'power', points: [
                  ChartDataPoint(x: 0, y: 100),
                  ChartDataPoint(x: 1, y: 200),
                ]),
                LineChartSeries(id: 'hr', points: [
                  ChartDataPoint(x: 0, y: 60),
                  ChartDataPoint(x: 1, y: 80),
                ]),
              ],
              yAxes: [
                YAxisConfig(id: 'power-axis', position: YAxisPosition.left),
                YAxisConfig(id: 'hr-axis', position: YAxisPosition.right),
              ],
              axisBindings: [
                SeriesAxisBinding(seriesId: 'power', yAxisId: 'power-axis'),
                SeriesAxisBinding(seriesId: 'hr', yAxisId: 'hr-axis'),
              ],
            ),
          ),
        ),
      );
      
      await tester.pumpAndSettle();
      
      // Verify chart renders without error
      expect(find.byType(BravenChartPlus), findsOneWidget);
    });

    testWidgets('applies normalization mode when specified', (tester) async {
      // Test normalizationMode parameter
    });

    testWidgets('uses default axis when no binding specified', (tester) async {
      // Test SeriesAxisResolver default behavior
    });

    testWidgets('handles empty yAxes gracefully', (tester) async {
      // Test null/empty yAxes falls back to single axis mode
    });
  });
}
```

### T026: auto_detection_widget_test.dart

```dart
void main() {
  group('Auto-Detection Widget Tests', () {
    testWidgets('detects normalization need for >10x range difference', (tester) async {
      // Create chart with power (0-400W) and HR (60-180bpm)
      // Verify _normalizationNeeded becomes true
    });

    testWidgets('does not trigger for <10x range difference', (tester) async {
      // Create chart with similar ranges
      // Verify _normalizationNeeded stays false
    });

    testWidgets('respects NormalizationMode.none override', (tester) async {
      // Even with >10x range, normalization should be disabled
    });
  });
}
```

### T032: axis_color_widget_test.dart

```dart
void main() {
  group('Axis Color Widget Tests', () {
    testWidgets('axis derives color from bound series', (tester) async {
      // Create chart with colored series, axes with null color
      // Verify axes render with series colors
    });

    testWidgets('explicit axis color overrides series color', (tester) async {
      // Create chart with axis.color set
      // Verify axis uses explicit color, not series color
    });

    testWidgets('shared axis uses first bound series color', (tester) async {
      // Two series bound to same axis
      // Verify axis uses first series color
    });
  });
}
```

---

## Code Scaffolds

### `lib/src/axis/series_axis_resolver.dart`

```dart
/// Resolves series-to-axis bindings for multi-axis charts.
///
/// This library provides [SeriesAxisResolver] for determining which Y-axis
/// a series should use based on explicit bindings or defaults.
library;

import '../models/series_axis_binding.dart';
import '../models/y_axis_config.dart';

/// Resolves which Y-axis a series should use.
///
/// When a series has an explicit [SeriesAxisBinding], that axis is used.
/// Otherwise, the first (default) axis is used.
///
/// Example:
/// ```dart
/// final axisId = SeriesAxisResolver.resolveAxisId(
///   'power-series',
///   bindings,
///   axes,
/// );
/// ```
class SeriesAxisResolver {
  const SeriesAxisResolver._();

  /// Resolves the Y-axis ID for a series.
  ///
  /// Returns the explicitly bound axis ID, or the first axis ID if unbound.
  static String resolveAxisId(
    String seriesId,
    List<SeriesAxisBinding> bindings,
    List<YAxisConfig> axes,
  ) {
    // TODO: Implement
    throw UnimplementedError();
  }

  /// Resolves the [YAxisConfig] for a series.
  ///
  /// Returns the explicitly bound axis, or the first axis if unbound.
  /// Returns null if axes list is empty.
  static YAxisConfig? resolveAxis(
    String seriesId,
    List<SeriesAxisBinding> bindings,
    List<YAxisConfig> axes,
  ) {
    // TODO: Implement
    throw UnimplementedError();
  }
}
```

---

## Visual Verification

**Category**: INTEGRATION (modifies BravenChartPlus)

### Demo File: `example/lib/demos/task_011_integration_demo.dart`

```dart
import 'package:flutter/material.dart';
import 'package:braven_charts/braven_charts.dart';

/// Task 11 Demo: Multi-Axis Widget Integration
///
/// Demonstrates:
/// - yAxes parameter on BravenChartPlus
/// - axisBindings connecting series to axes
/// - Both axes rendering with derived colors
/// - Data properly normalized per-axis
void main() => runApp(const Task011IntegrationDemo());

class Task011IntegrationDemo extends StatelessWidget {
  const Task011IntegrationDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Task 11: Multi-Axis Integration',
      theme: ThemeData.dark(),
      home: Scaffold(
        appBar: AppBar(title: const Text('Task 11: Multi-Axis Widget')),
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
    // Power data: 100-400W range
    final powerData = List.generate(
      20,
      (i) => ChartDataPoint(x: i.toDouble(), y: 100 + (i * 15)),
    );
    
    // Heart rate data: 60-180 bpm range (10x smaller scale)
    final hrData = List.generate(
      20,
      (i) => ChartDataPoint(x: i.toDouble(), y: 60 + (i * 6)),
    );

    return BravenChartPlus(
      chartType: ChartType.line,
      series: [
        LineChartSeries(
          id: 'power',
          name: 'Power (W)',
          points: powerData,
          color: Colors.blue,
        ),
        LineChartSeries(
          id: 'heartrate',
          name: 'Heart Rate (bpm)',
          points: hrData,
          color: Colors.red,
        ),
      ],
      // NEW: Multi-axis configuration via widget parameters
      yAxes: [
        YAxisConfig(
          id: 'power-axis',
          position: YAxisPosition.left,
          label: 'Power',
          unit: 'W',
          // color: null - will derive from series
        ),
        YAxisConfig(
          id: 'hr-axis',
          position: YAxisPosition.right,
          label: 'Heart Rate',
          unit: 'bpm',
          // color: null - will derive from series
        ),
      ],
      axisBindings: [
        SeriesAxisBinding(seriesId: 'power', yAxisId: 'power-axis'),
        SeriesAxisBinding(seriesId: 'heartrate', yAxisId: 'hr-axis'),
      ],
      normalizationMode: NormalizationMode.perAxis,
    );
  }
}
```

### Flutter Agent Workflow

```powershell
# 1. Start Flutter with demo
Start-Process -FilePath "powershell" -ArgumentList "-NoExit", "-Command", `
  "cd 'e:\cloud services\Dropbox\Repositories\Flutter\braven_charts_v2.0\example'; python ..\tools\flutter_agent\flutter_agent.py run lib/demos/task_011_integration_demo.dart -d chrome"

# 2. Wait for app ready
cd "e:\cloud services\Dropbox\Repositories\Flutter\braven_charts_v2.0\example"
python ..\tools\flutter_agent\flutter_agent.py wait --timeout 60

# 3. Screenshot
python ..\tools\flutter_agent\flutter_agent.py screenshot --output ../.orchestra/verification/screenshots/task-011-multi-axis-integration.png

# 4. Stop
python ..\tools\flutter_agent\flutter_agent.py stop
```

### Expected Visual Output

- **Left axis (Power)**: Blue color, labels showing W units, range ~100-400
- **Right axis (Heart Rate)**: Red color, labels showing bpm units, range ~60-180
- **Power series**: Blue line spanning full vertical height of left axis
- **Heart rate series**: Red line spanning full vertical height of right axis
- **Both series visible**: Each normalized to its own axis scale

---

## Quality Gates (MANDATORY)

### Linting - Zero Issues

```powershell
flutter analyze lib/src/braven_chart_plus.dart
flutter analyze lib/src/axis/series_axis_resolver.dart
flutter analyze test/widget/multi_axis/
```

### All Tests Must Pass

```powershell
# New widget tests
flutter test test/widget/multi_axis/

# All sprint unit tests (catches regressions)
flutter test test/unit/multi_axis/

# Integration tests
flutter test test/integration/multi_axis_*.dart
```

**Current Test Baseline**: 210 unit tests + 29 integration tests - MUST NOT decrease!

### Expected New Tests: 9+

- multi_axis_chart_test.dart: ~3-4 tests
- auto_detection_widget_test.dart: ~3 tests
- axis_color_widget_test.dart: ~3 tests

---

## Completion Protocol

When all deliverables are complete:

1. Run full test suite: `flutter test`
2. Run analyzer: `flutter analyze`
3. Capture demo screenshot
4. Update `.orchestra/handover/completion-signal.md`:
   ```markdown
   # Task Completion Signal
   
   ## Status: COMPLETED
   
   ## Task: 11 - Integrate Multi-Axis Painter with Chart Widget
   
   ## Summary
   [Brief summary of what was done]
   
   ## SpecKit Traceability
   | SpecKit ID | Description | Status |
   |------------|-------------|--------|
   | T010 | yAxes/normalizationMode parameters | ✅ Complete |
   | T015 | Widget test for multi-axis | ✅ Complete |
   | T008 | Widget test directory | ✅ Complete |
   | T018 | Series-axis resolver | ✅ Complete |
   | T026 | Auto-detection widget test | ✅ Complete |
   | T032 | Color axes widget test | ✅ Complete |
   
   ## Files
   ### Created
   - lib/src/axis/series_axis_resolver.dart
   - test/widget/multi_axis/multi_axis_chart_test.dart
   - test/widget/multi_axis/auto_detection_widget_test.dart
   - test/widget/multi_axis/axis_color_widget_test.dart
   - example/lib/demos/task_011_integration_demo.dart
   
   ### Modified
   - lib/src/braven_chart_plus.dart
   - lib/src/rendering/chart_render_box.dart
   
   ## Test Results
   [Test output]
   
   ## Visual Verification
   - Screenshot: .orchestra/verification/screenshots/task-011-multi-axis-integration.png
   ```
5. Signal completion: "Task 11 ready for orchestrator verification"

---

## Notes

- This is an **INTEGRATION TASK** - take extra care when modifying `BravenChartPlus`
- Existing `_normalizationNeeded` infrastructure in widget state should be leveraged
- The demo should work with the existing `ChartRenderBox` rendering pipeline
- SeriesAxisResolver complements AxisColorResolver (color) with axis lookup (binding)
- Widget tests should use `tester.pumpAndSettle()` to wait for rendering
