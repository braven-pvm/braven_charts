# Current Task: #7 - Implement Auto-Detection Logic

## Objective

Create a detector class that analyzes data series ranges and determines if normalization is needed based on configurable thresholds.

## ⚠️ TDD REQUIRED

**You must write tests FIRST, then implementation.**

1. Create test file: `test/unit/axis/normalization_detector_test.dart`
2. Write at least 5 test cases
3. Run tests (they should fail initially)
4. Create implementation: `lib/src/axis/normalization_detector.dart`
5. Run tests again (they should pass)
6. Export from `lib/braven_charts.dart`

## Requirements

Create `NormalizationDetector` class with method:

### `shouldNormalize(List<SeriesRange> ranges, {double threshold = 10.0}) → bool`

**SeriesRange** is a simple helper class you'll also create:
```dart
class SeriesRange {
  final String seriesId;
  final double min;
  final double max;
  
  double get span => max - min;
}
```

**Detection Logic:**
- Compare the largest range span to the smallest range span
- If `largestSpan / smallestSpan >= threshold`, return `true` (needs normalization)
- Otherwise return `false`

### Edge Cases to Handle
- **Single series**: Return `false` (nothing to compare)
- **Empty list**: Return `false`
- **Zero span series**: Handle gracefully (don't divide by zero)
- **Identical ranges**: Return `false`

## Test Cases Required

Your tests must cover:
1. Similar ranges (within threshold) → `false`
2. Different ranges (exceed threshold) → `true`
3. Custom threshold is respected
4. Single series → `false`
5. Empty list → `false`

## File Locations

```
lib/src/axis/normalization_detector.dart  ← implementation (includes SeriesRange)
test/unit/axis/normalization_detector_test.dart ← tests (WRITE FIRST)
lib/braven_charts.dart                     ← add export
```

## Context

This detector will be used by the chart to automatically decide whether to apply normalization based on the `NormalizationMode.auto` setting from `MultiAxisConfig`.

## When Done

1. Stage changes: `git add .`
2. Write to `completion-signal.md`: "Task 7 complete - NormalizationDetector with TDD"
3. Say "ready for review"
