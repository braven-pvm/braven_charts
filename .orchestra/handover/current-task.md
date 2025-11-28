# Current Task: #6 - Implement Data Normalizer

## Objective

Create a utility class that normalizes data values to a 0.0-1.0 range based on axis configuration.

## ⚠️ TDD REQUIRED

**You must write tests FIRST, then implementation.**

1. Create test file: `test/unit/axis/data_normalizer_test.dart`
2. Write at least 5 test cases covering different scenarios
3. Run tests (they should fail initially)
4. Create implementation: `lib/src/axis/data_normalizer.dart`
5. Run tests again (they should pass)
6. Export from `lib/braven_charts.dart`

## Requirements

Create `DataNormalizer` class with methods:

### 1. `normalize(double value, double min, double max) → double`
- Normalizes a raw value to 0.0-1.0 range
- When value equals min, returns 0.0
- When value equals max, returns 1.0
- Values in between scale proportionally

### 2. `denormalize(double normalized, double min, double max) → double`
- Converts a normalized value (0.0-1.0) back to original range
- Inverse of normalize()

### Edge Cases to Handle
- **Zero range**: When min equals max, all values should normalize to 0.5
- **Values outside range**: Values below min should normalize to < 0.0, above max to > 1.0

## Test Cases Required

Your tests must cover:
1. Value at min → 0.0
2. Value at max → 1.0
3. Mid-range value → 0.5 (or proportional)
4. Zero range (min == max) → 0.5
5. Denormalize returns original value (roundtrip)

## File Locations

```
lib/src/axis/data_normalizer.dart       ← implementation
test/unit/axis/data_normalizer_test.dart ← tests (WRITE FIRST)
lib/braven_charts.dart                   ← add export
```

## Context

See `task-context.md` for Phase 1 models you can use (YAxisConfig has minValue/maxValue).

## When Done

1. Stage changes: `git add .`
2. Write to `completion-signal.md`: "Task 6 complete - DataNormalizer with TDD"
3. Say "ready for review"
