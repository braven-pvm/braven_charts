# Current Task: Create Series-Axis Binding Model

## Objective

Create a simple `SeriesAxisBinding` class that associates a data series with a Y-axis by their IDs.

## Context

In a multi-axis chart, each data series needs to be bound to a specific Y-axis. This binding is by **ID strings**, not object references - keeping the model lightweight and flexible.

Example: A "power" series binds to the "power-axis", a "heartrate" series binds to the "hr-axis".

## What to Create

### 1. Binding Model File

**Path**: `lib/src/models/series_axis_binding.dart`

#### Properties

| Property | Type | Required | Description |
|----------|------|----------|-------------|
| `seriesId` | `String` | Yes | ID of the data series (matches `ChartSeries.id`) |
| `yAxisId` | `String` | Yes | ID of the Y-axis (matches `YAxisConfig.id`) |

#### Requirements

1. **const constructor** - This is an immutable value object
2. **Validation assertions**:
   - `seriesId.isNotEmpty`
   - `yAxisId.isNotEmpty`
3. **Equality** - Two bindings are equal if both IDs match
4. **hashCode** - Consistent with equality
5. **toString** - For debugging

#### Example Implementation Pattern

```dart
class SeriesAxisBinding {
  const SeriesAxisBinding({
    required this.seriesId,
    required this.yAxisId,
  }) : assert(seriesId.isNotEmpty, 'seriesId must be non-empty'),
       assert(yAxisId.isNotEmpty, 'yAxisId must be non-empty');

  final String seriesId;
  final String yAxisId;

  // ... equality, hashCode, toString
}
```

### 2. Test File (TDD - Create First!)

**Path**: `test/unit/multi_axis/series_axis_binding_test.dart`

#### Required Test Groups

1. **Construction**
   - Creates with valid IDs
   - Is const-constructible

2. **Validation**
   - Empty seriesId throws
   - Empty yAxisId throws

3. **Equality**
   - Same IDs = equal
   - Different seriesId = not equal
   - Different yAxisId = not equal
   - hashCode consistent

4. **toString**
   - Contains both IDs

### 3. Export

**File to modify**: `lib/src/models/enums.dart`

Add export:
```dart
export 'series_axis_binding.dart';
```

## Key Constraints

- **DO NOT** import `ChartSeries` or `YAxisConfig`
- **DO NOT** add complex logic - this is just a data association
- **KEEP IT SIMPLE** - two string IDs, that's it

## Example Usage (for context only)

```dart
// Bind power series to left axis
final powerBinding = SeriesAxisBinding(
  seriesId: 'power',
  yAxisId: 'power-axis',
);

// Bind heart rate to right axis
final hrBinding = SeriesAxisBinding(
  seriesId: 'heartrate',
  yAxisId: 'hr-axis',
);

// Multiple series can share an axis
final cadenceBinding = SeriesAxisBinding(
  seriesId: 'cadence',
  yAxisId: 'hr-axis',  // Same axis as heartrate
);
```

## When Done

1. Stage your changes: `git add .`
2. Write to `.orchestra/handover/completion-signal.md`:
   - List files created/modified
   - Confirm all tests pass
   - Note: "Kept model simple - no heavy imports"
3. Say "Task complete - ready for review"
