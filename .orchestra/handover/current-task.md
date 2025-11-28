# Current Task: Implement Auto-Detection Logic

## Objective

Implement automatic detection of when multi-axis normalization should be enabled based on series range differences. When series have vastly different Y-ranges (≥10x difference), the system should automatically recommend multi-axis mode.

## Context

Task 6 (Data Normalizer) is complete. We now have:
- ✅ `MultiAxisNormalizer` - Core normalization engine
- ✅ `DataRange` - Min/max bounds container

This task adds the **intelligence layer** that decides WHEN to normalize.

## User Story 2 Reference

> A developer integrating the chart library wants the system to automatically detect when multiple series need separate axes without manual configuration. When the developer adds series with significantly different Y-ranges (e.g., 10x or more difference), the chart should automatically enable multi-axis mode.

**Acceptance Scenarios**:
1. Series A (0-10) + Series B (0-1000) → Auto-detect: **YES** (100x difference)
2. Series with similar ranges (within 10x) → Auto-detect: **NO**
3. Explicit config provided → Explicit config takes precedence

## ⚠️ TDD REQUIREMENT

This is a **Test-Driven Development** task:
1. **Write tests FIRST** (they should fail initially)
2. **Then implement** to make tests pass

## What to Create

### 1. Test File (Create FIRST!)

**Path**: `test/unit/multi_axis/auto_detection_test.dart`

#### Required Test Groups

```dart
group('RangeRatioCalculator', () {
  group('calculateRatio', () {
    test('returns 1.0 for identical ranges');
    test('returns ratio for different ranges');
    test('calculates ratio as larger/smaller (always >= 1)');
    test('handles zero-width range without error');
    test('handles negative value ranges');
    test('handles ranges crossing zero');
  });
});

group('NormalizationDetector', () {
  group('shouldNormalize', () {
    test('returns false for single series');
    test('returns false for series within threshold');
    test('returns true when any pair exceeds threshold');
    test('uses default threshold of 10x');
    test('respects custom threshold');
    test('checks all pairwise combinations');
  });
  
  group('edge cases', () {
    test('handles empty series list');
    test('handles series with identical values');
    test('handles exactly 10x threshold (boundary)');
  });
  
  group('acceptance scenarios', () {
    // From spec
    test('US2-1: detects 0-10 vs 0-1000 (100x difference)');
    test('US2-2: does not detect 0-50 vs 0-100 (2x difference)');
  });
});
```

### 2. Range Ratio Calculator

**Path**: `lib/src/axis/range_ratio_calculator.dart`

```dart
import '../models/data_range.dart';

/// Calculates the ratio between data ranges to determine
/// if normalization is needed.
class RangeRatioCalculator {
  const RangeRatioCalculator._();
  
  /// Calculates the ratio between two data ranges.
  ///
  /// Returns a value >= 1.0 representing how many times larger
  /// the bigger range is compared to the smaller range.
  ///
  /// Examples:
  /// - Range(0,10) vs Range(0,100) → 10.0
  /// - Range(0,100) vs Range(0,10) → 10.0 (order doesn't matter)
  /// - Range(0,10) vs Range(0,10) → 1.0
  static double calculateRatio(DataRange range1, DataRange range2) {
    // TODO: Implement
    // Handle edge cases: zero span, etc.
  }
}
```

### 3. Normalization Detector

**Path**: `lib/src/axis/normalization_detector.dart`

```dart
import '../models/data_range.dart';
import 'range_ratio_calculator.dart';

/// Detects when automatic multi-axis normalization should be enabled.
///
/// According to spec FR-008:
/// "System MUST support automatic multi-axis detection when series 
/// Y-ranges differ by more than a configurable threshold (default: 10x)"
class NormalizationDetector {
  const NormalizationDetector._();
  
  /// Default threshold ratio for auto-detection (10x difference).
  static const double defaultThreshold = 10.0;
  
  /// Determines if normalization should be automatically enabled.
  ///
  /// Returns true if ANY pair of series has a range ratio >= [threshold].
  ///
  /// Parameters:
  /// - [seriesRanges]: Map of series ID to their data ranges
  /// - [threshold]: Minimum ratio to trigger detection (default: 10.0)
  static bool shouldNormalize(
    Map<String, DataRange> seriesRanges, {
    double threshold = defaultThreshold,
  }) {
    // TODO: Implement
    // Check all pairwise combinations
  }
  
  /// Gets the maximum range ratio among all series pairs.
  ///
  /// Useful for diagnostics and UI feedback.
  static double getMaxRatio(Map<String, DataRange> seriesRanges) {
    // TODO: Implement
  }
}
```

### 4. Export

**File to modify**: `lib/src/axis/axis.dart` (create if needed as barrel)

```dart
export 'range_ratio_calculator.dart';
export 'normalization_detector.dart';
```

Also add to main barrel file if needed.

## Algorithm

### Range Ratio Calculation

```dart
// Calculate span of each range
span1 = range1.max - range1.min
span2 = range2.max - range2.min

// Handle zero spans
if (span1 == 0 && span2 == 0) return 1.0
if (span1 == 0 || span2 == 0) return double.infinity // or handle specially

// Ratio is always >= 1.0 (larger / smaller)
ratio = max(span1, span2) / min(span1, span2)
```

### Auto-Detection Logic

```dart
// For N series, check all pairs
for i in 0..n-1:
  for j in i+1..n-1:
    ratio = calculateRatio(ranges[i], ranges[j])
    if (ratio >= threshold):
      return true  // Should normalize
return false  // All pairs within threshold
```

## Dependencies

Import from completed tasks:
```dart
import 'package:braven_charts/src/models/data_range.dart';
```

## Test Execution

```bash
# Run auto-detection tests
flutter test test/unit/multi_axis/auto_detection_test.dart

# Ensure all sprint tests pass
flutter test test/unit/multi_axis/
```

## Quality Gates (MANDATORY)

### 1. Linting - Zero Issues
```bash
flutter analyze lib/src/axis/range_ratio_calculator.dart
flutter analyze lib/src/axis/normalization_detector.dart
flutter analyze test/unit/multi_axis/auto_detection_test.dart
```

### 2. All Sprint Tests Must Pass
```bash
flutter test test/unit/multi_axis/
flutter test test/integration/multi_axis_*.dart
```

Current baseline: **134 tests passing**

## When Done

1. **Verify linting is clean** (BLOCKING)
2. **Verify ALL tests pass** (BLOCKING)
3. Stage your changes: `git add .`
4. Write to `.orchestra/handover/completion-signal.md`:
   - Files created
   - Number of tests added
   - Confirm linting clean
   - Confirm all sprint tests pass
5. Say "Task complete - ready for review"
