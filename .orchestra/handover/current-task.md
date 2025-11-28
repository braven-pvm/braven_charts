# Current Task: Create Normalization Mode Enum

## Objective

Create a `NormalizationMode` enum that controls when Y-axis normalization is applied.

## Context

Multi-axis charts can normalize data to display series with vastly different ranges on the same chart. This enum controls WHEN normalization happens:

- **disabled** - Never normalize (chart behaves as before)
- **auto** - Automatically detect when normalization is needed (e.g., when ranges differ by >10x)
- **always** - Always normalize, regardless of data ranges

## What to Create

### 1. Enum File

**Path**: `lib/src/models/normalization_mode.dart`

#### Enum Values (exactly these 3, in this order)

```dart
enum NormalizationMode {
  disabled,  // Never normalize
  auto,      // Auto-detect based on range differences
  always,    // Always normalize
}
```

#### Requirements

1. Add `///` doc comment on the enum explaining its purpose
2. Add `///` doc comment on each value explaining when to use it
3. Follow pattern from `lib/src/models/enums.dart`
4. **Keep it simple** - no methods, no extensions

### 2. Test File (TDD - Create First!)

**Path**: `test/unit/multi_axis/normalization_mode_test.dart`

#### Required Tests

1. Enum has exactly 3 values
2. All expected values exist (disabled, auto, always)
3. Values are in correct order
4. Value names match strings exactly

### 3. Export

**File to modify**: `lib/src/models/enums.dart`

Add export:
```dart
export 'normalization_mode.dart';
```

## Example Usage (for context only)

```dart
// Default: let the system decide
final config = MultiAxisConfig(
  mode: NormalizationMode.auto,
  // ...
);

// Force normalization off
final traditionalChart = MultiAxisConfig(
  mode: NormalizationMode.disabled,
);

// Always normalize even if ranges are similar
final alwaysNormalized = MultiAxisConfig(
  mode: NormalizationMode.always,
);
```

## When Done

1. Stage your changes: `git add .`
2. Write to `.orchestra/handover/completion-signal.md`:
   - List files created/modified
   - Confirm all tests pass
3. Say "Task complete - ready for review"
