# Current Task: Implement Data Normalizer

## Objective

Implement `MultiAxisNormalizer` - the core normalization engine that converts series data values to/from normalized [0,1] range for rendering while preserving original values for display.

## Context

This is the first task in the **Normalization Phase**. The foundation is complete:
- ✅ `YAxisPosition` - 4 axis positions
- ✅ `YAxisConfig` - Individual axis configuration
- ✅ `SeriesAxisBinding` - Links series to axes  
- ✅ `NormalizationMode` - Controls when normalization applies
- ✅ `MultiAxisConfig` - Container holding all configuration

Now we need the **core algorithm** that actually performs normalization.

## ⚠️ TDD REQUIREMENT

This is a **Test-Driven Development** task:
1. **Write tests FIRST** (they should fail initially)
2. **Then implement** to make tests pass
3. **Verify tests were actually testing something** (not false positives)

## What to Create

### 1. Test File: Normalization Tests (Create FIRST!)

**Path**: `test/unit/multi_axis/normalization_test.dart`

This tests the core normalize/denormalize operations (SpecKit T013).

#### Required Test Groups

```dart
group('MultiAxisNormalizer', () {
  group('normalize', () {
    // Convert data value to [0,1] range based on axis bounds
    test('normalizes minimum value to 0.0');
    test('normalizes maximum value to 1.0');
    test('normalizes midpoint value to 0.5');
    test('normalizes values outside bounds correctly');
    test('handles negative ranges (min=-100, max=100)');
    test('handles decimal precision');
  });

  group('denormalize', () {
    // Convert normalized [0,1] back to original data value
    test('denormalizes 0.0 to minimum value');
    test('denormalizes 1.0 to maximum value');
    test('denormalizes 0.5 to midpoint value');
    test('round-trip preserves original value');
  });

  group('edge cases', () {
    test('handles zero range (min == max) without division by zero');
    test('handles very small range (e.g., 0.001 difference)');
    test('handles very large values without overflow');
    test('handles single data point series');
  });
});
```

### 2. Test File: Axis Bounds Tests (Create FIRST!)

**Path**: `test/unit/multi_axis/axis_bounds_test.dart`

This tests computing bounds per Y-axis from series data (SpecKit T014).

#### Required Test Groups

```dart
group('Axis Bounds Computation', () {
  group('computeAxisBounds', () {
    // Compute min/max bounds for each Y-axis from series data
    test('computes bounds from single series');
    test('computes bounds from multiple series on same axis');
    test('computes separate bounds for different axes');
    test('respects explicit min/max from YAxisConfig');
    test('uses data-derived bounds when config min/max are null');
    test('handles mixed explicit and auto bounds');
  });

  group('series to axis mapping', () {
    test('maps series with yAxisId to correct axis');
    test('maps series without yAxisId to default axis');
    test('handles unmapped series (no matching axis)');
  });

  group('edge cases', () {
    test('handles empty series list');
    test('handles series with no data points');
    test('handles series with identical Y values');
  });
});
```

### 3. Implementation File

**Path**: `lib/src/rendering/multi_axis_normalizer.dart`

#### Class Structure

```dart
/// Normalizes series data values to [0,1] range for rendering while
/// preserving ability to recover original values for display.
///
/// See: specs/011-multi-axis-normalization/data-model.md
class MultiAxisNormalizer {
  const MultiAxisNormalizer._();

  /// Normalizes [value] to [0,1] range based on axis [min] and [max].
  ///
  /// Returns 0.0 for min, 1.0 for max, proportional values between.
  /// Values outside range return values outside [0,1].
  static double normalize(double value, double min, double max) {
    // TODO: Implement
    // Handle edge case: min == max
  }

  /// Converts normalized [value] back to original data value.
  ///
  /// Inverse of [normalize]. Used for tooltip/crosshair display.
  static double denormalize(double normalizedValue, double min, double max) {
    // TODO: Implement
  }

  /// Computes data bounds (min/max) for each Y-axis from series data.
  ///
  /// Returns Map from axis ID to DataRange.
  /// Uses explicit bounds from [axisConfigs] when specified,
  /// otherwise computes from [seriesData].
  static Map<String, DataRange> computeAxisBounds({
    required List<YAxisConfig> axisConfigs,
    required List<SeriesAxisBinding> bindings,
    required Map<String, List<double>> seriesYValues, // seriesId -> Y values
    String defaultAxisId = 'primary',
  }) {
    // TODO: Implement
    // Algorithm from data-model.md:
    // For each YAxisConfig:
    //   1. Find all series bound to this axis
    //   2. If axis.min specified → use it, else min of all bound series
    //   3. If axis.max specified → use it, else max of all bound series
  }
}

/// Simple data range container.
class DataRange {
  final double min;
  final double max;
  
  const DataRange(this.min, this.max);
  
  // TODO: Add equality, copyWith, etc.
}
```

### 4. Export

**File to modify**: `lib/src/rendering/rendering.dart` (or create if needed)

Add export:
```dart
export 'multi_axis_normalizer.dart';
```

Also ensure the main barrel file exports rendering.

## Algorithm Reference

From `specs/011-multi-axis-normalization/data-model.md`:

```
Axis Bounds Computation:

For each YAxisConfig:
  1. Find all series where series.yAxisId == axis.id
  2. If axis.min specified → use axis.min
     Else → min(series.points.y) for all bound series
  3. If axis.max specified → use axis.max
     Else → max(series.points.y) for all bound series
  4. Store in axisBounds[axis.id]
```

## Normalization Formula

Standard linear normalization:

```dart
// Normalize: data value -> [0,1]
normalized = (value - min) / (max - min)

// Denormalize: [0,1] -> data value  
original = normalizedValue * (max - min) + min

// Edge case: when min == max, return 0.5 (or configurable default)
```

## Dependencies

Import from completed foundation:
```dart
import 'package:braven_charts/src/models/y_axis_config.dart';
import 'package:braven_charts/src/models/series_axis_binding.dart';
```

## Test Execution

Run your new tests:
```bash
# Normalization tests (T013)
flutter test test/unit/multi_axis/normalization_test.dart

# Axis bounds tests (T014)
flutter test test/unit/multi_axis/axis_bounds_test.dart
```

Before completing, ensure ALL sprint tests still pass:
```bash
flutter test test/unit/multi_axis/
flutter test test/integration/multi_axis_*.dart
```

## Quality Gates (MANDATORY)

### 1. Linting - Zero Issues Required
```bash
flutter analyze lib/src/rendering/multi_axis_normalizer.dart
flutter analyze test/unit/multi_axis/normalization_test.dart
flutter analyze test/unit/multi_axis/axis_bounds_test.dart
```

### 2. All Sprint Tests Must Pass
```bash
flutter test test/unit/multi_axis/
flutter test test/integration/multi_axis_*.dart
```

Current baseline: **113 tests passing**. Your tests will ADD to this.

## When Done

1. **Verify linting is clean** (BLOCKING)
2. **Verify ALL tests pass** (BLOCKING - both old and new)
3. Stage your changes: `git add .`
4. Write to `.orchestra/handover/completion-signal.md`:
   - List files created
   - Number of tests added
   - Confirm linting clean (exact command output)
   - Confirm all sprint tests pass (exact test count)
5. Say "Task complete - ready for review"
