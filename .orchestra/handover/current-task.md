# Current Task: Integrate Normalizer with Chart Data Pipeline

## ⚠️ CRITICAL: THIS IS AN INTEGRATION TASK

**DO NOT** create new isolated files that aren't called. You MUST modify the **EXISTING** files below to wire in the normalization logic.

## Objective

Connect the completed normalizer (Task 6) and auto-detection logic (Task 7) into the actual chart rendering pipeline. When complete, charts should actually USE normalization for multi-scale data.

## Context

We now have:
- ✅ `MultiAxisNormalizer` - Core normalization engine (`lib/src/rendering/multi_axis_normalizer.dart`)
- ✅ `NormalizationDetector` - Auto-detection logic (`lib/src/axis/normalization_detector.dart`)
- ✅ `RangeRatioCalculator` - Range comparison (`lib/src/axis/range_ratio_calculator.dart`)
- ✅ `DataRange` - Min/max bounds container (`lib/src/models/data_range.dart`)

**NONE of these are actually CALLED yet!** This task wires them in.

## User Story Reference

**US1 (P1)**: Multi-scale data visualization
> "Each series uses the full vertical height of the chart while displaying its own properly-scaled Y-axis."

**US2 (P2)**: Automatic normalization detection
> "When the developer adds series with significantly different Y-ranges (e.g., 10x or more difference), the chart should automatically enable multi-axis mode."

## ⚠️ INTEGRATION REQUIREMENTS

### Files You MUST MODIFY (NOT create new!)

1. **`lib/src/rendering/chart_render_box.dart`** (4879 lines)
   - This is where chart rendering happens
   - Add import for `multi_axis_normalizer.dart`
   - Use `MultiAxisNormalizer.normalize()` when rendering series Y values
   - Use `MultiAxisNormalizer.denormalize()` when displaying tooltips
   
2. **`lib/src/braven_chart_plus.dart`** (2406 lines)
   - This is the main chart widget (at `lib/src/` NOT `lib/src/widgets/`)
   - Add import for `normalization_detector.dart`
   - Call `NormalizationDetector.shouldNormalize()` during initialization
   - Propagate normalization mode to render box

### File You MUST CREATE

3. **`test/integration/multi_axis_pipeline_integration_test.dart`**
   - Tests that prove the integration is working end-to-end

## ⚠️ TDD REQUIREMENT

1. **Write integration tests FIRST** (they should fail initially)
2. **Then modify existing files** to make tests pass
3. **Tests must exercise the full pipeline**, not just the isolated components

## What to Create

### 1. Integration Test File (Create FIRST!)

**Path**: `test/integration/multi_axis_pipeline_integration_test.dart`

```dart
// Integration tests proving normalizer is wired into chart pipeline

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:braven_charts/braven_charts.dart';

void main() {
  group('Multi-Axis Pipeline Integration', () {
    group('BravenChartPlus with multi-scale data', () {
      testWidgets('auto-detects need for normalization with 10x+ range difference', 
        (tester) async {
        // Create chart with series having 100x range difference
        // Series A: 0-10
        // Series B: 0-1000
        // Verify auto-detection triggered
      });
      
      testWidgets('does not normalize when ranges are similar', 
        (tester) async {
        // Create chart with series having 2x range difference
        // Series A: 0-50
        // Series B: 0-100  
        // Verify single-axis mode used
      });
      
      testWidgets('both series span full vertical height after normalization',
        (tester) async {
        // Create chart with vastly different ranges
        // Verify both series use full vertical space
        // (no "flat line at bottom" effect)
      });
    });
    
    group('Tooltip value display', () {
      testWidgets('shows original values not normalized values',
        (tester) async {
        // Create chart with normalized series
        // Trigger tooltip
        // Verify displayed value is original (e.g., "240 W" not "0.8")
      });
    });
    
    group('Crosshair integration', () {
      testWidgets('crosshair Y calculation uses per-axis denormalization',
        (tester) async {
        // FR-014: Crosshair Y-coordinate calculations MUST use 
        // per-axis bounds to convert screen position to original data values
      });
    });
    
    group('Backward compatibility', () {
      testWidgets('single series chart works unchanged',
        (tester) async {
        // Existing single-series charts must continue working
      });
      
      testWidgets('similar-range multi-series works unchanged',
        (tester) async {
        // Series with similar ranges should not be normalized
      });
    });
  });
}
```

## Integration Points

### In `chart_render_box.dart`:

Find where Y values are converted to screen coordinates and:

```dart
// BEFORE (pseudo-code):
// screenY = plotArea.bottom - ((value - minY) / (maxY - minY)) * plotArea.height

// AFTER (pseudo-code):
import '../rendering/multi_axis_normalizer.dart';

// When normalization is active:
final normalizedValue = MultiAxisNormalizer.normalize(value, axisMin, axisMax);
final screenY = plotArea.bottom - normalizedValue * plotArea.height;
```

For tooltips:
```dart
// Convert screen Y back to original value
final originalValue = MultiAxisNormalizer.denormalize(normalizedValue, axisMin, axisMax);
// Display originalValue in tooltip
```

### In `braven_chart_plus.dart`:

Find widget initialization and:

```dart
import 'axis/normalization_detector.dart';
import 'models/data_range.dart';

// During build or init:
if (normalizationMode == NormalizationMode.auto) {
  final seriesRanges = _computeSeriesRanges(series);
  if (NormalizationDetector.shouldNormalize(seriesRanges)) {
    // Enable multi-axis normalization
  }
}
```

## Key Classes/Methods to Understand

Before modifying, read these existing code sections:

1. **`chart_render_box.dart`**:
   - `paint()` method - where rendering happens
   - Series iteration and Y coordinate calculation
   - Tooltip display logic
   
2. **`braven_chart_plus.dart`**:
   - `build()` method
   - How it creates/configures `ChartRenderBox`
   - How series data is passed through

## Dependencies

```dart
// Import from completed tasks:
import 'package:braven_charts/src/rendering/multi_axis_normalizer.dart';
import 'package:braven_charts/src/axis/normalization_detector.dart';
import 'package:braven_charts/src/models/data_range.dart';
```

## Test Execution

```bash
# Run integration tests (these should FAIL initially, then pass)
flutter test test/integration/multi_axis_pipeline_integration_test.dart

# Ensure ALL sprint tests still pass
flutter test test/unit/multi_axis/
flutter test test/integration/multi_axis_*.dart
```

## Quality Gates (MANDATORY)

### 1. Linting - Zero Issues
```bash
flutter analyze lib/src/rendering/chart_render_box.dart
flutter analyze lib/src/braven_chart_plus.dart
flutter analyze test/integration/multi_axis_pipeline_integration_test.dart
```

### 2. All Sprint Tests Must Pass
```bash
flutter test test/unit/multi_axis/
flutter test test/integration/multi_axis_*.dart
```

Current baseline: **163 tests passing** (MUST NOT decrease!)

### 3. Integration Verification

After completing, verify these are TRUE:
- [ ] `chart_render_box.dart` has been modified (git diff shows changes)
- [ ] `braven_chart_plus.dart` has been modified (git diff shows changes)
- [ ] `MultiAxisNormalizer` methods are imported AND called
- [ ] `NormalizationDetector` methods are imported AND called
- [ ] Integration tests pass through actual BravenChartPlus widget

## When Done

1. **Verify git diff shows MODIFICATIONS to existing files** (not just new files)
2. **Verify linting is clean** (BLOCKING)
3. **Verify ALL tests pass** (BLOCKING)
4. Stage your changes: `git add .`
5. Write to `.orchestra/handover/completion-signal.md`:
   - Files modified (confirm chart_render_box.dart and braven_chart_plus.dart)
   - Files created (integration test)
   - Number of tests added
   - Confirm linting clean
   - Confirm all sprint tests pass
6. Say "Task complete - ready for review"
