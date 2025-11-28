# Current Task: Create YAxisConfig Model

## Objective

Create the `YAxisConfig` class - a configuration model for individual Y-axes in multi-axis charts.

## Context

Each Y-axis in a multi-axis chart needs configuration for:
- **Identity**: Unique ID for series binding
- **Position**: Where it appears (using `YAxisPosition` from Task 1)
- **Appearance**: Color, labels, visibility
- **Bounds**: Optional explicit min/max values
- **Formatting**: Unit suffix, custom label formatter

## What to Create

### 1. Config Class File

**Path**: `lib/src/models/y_axis_config.dart`

#### Required Properties (in constructor)

| Property | Type | Required | Default | Description |
|----------|------|----------|---------|-------------|
| `id` | `String` | Yes | - | Unique identifier for axis binding |
| `position` | `YAxisPosition` | Yes | - | Physical position (from Task 1) |
| `color` | `Color?` | No | `null` | Axis color; null = use first bound series color |
| `label` | `String?` | No | `null` | Axis label (e.g., "Power", "Heart Rate") |
| `unit` | `String?` | No | `null` | Unit suffix for labels (e.g., "W", "bpm") |
| `min` | `double?` | No | `null` | Explicit minimum; null = compute from data |
| `max` | `double?` | No | `null` | Explicit maximum; null = compute from data |
| `showTicks` | `bool` | No | `true` | Whether to show tick marks |
| `showAxisLine` | `bool` | No | `true` | Whether to show the axis line |
| `showLabels` | `bool` | No | `true` | Whether to show tick labels |
| `minWidth` | `double` | No | `40.0` | Minimum axis width in pixels |
| `maxWidth` | `double` | No | `80.0` | Maximum axis width in pixels |
| `tickCount` | `int?` | No | `null` | Preferred tick count; null = auto-compute |
| `labelFormatter` | `String Function(double)?` | No | `null` | Custom label formatting |

#### Validation Rules (as assertions)

```dart
assert(id.isNotEmpty, 'id must be non-empty');
assert(minWidth > 0, 'minWidth must be positive');
assert(maxWidth >= minWidth, 'maxWidth must be >= minWidth');
assert(min == null || max == null || min < max, 'min must be less than max');
assert(tickCount == null || tickCount >= 2, 'tickCount must be >= 2');
```

#### Required Methods

1. **copyWith**: Create modified copy with any properties changed
2. **== operator**: Value equality based on all properties
3. **hashCode**: Consistent with equality

#### Import Requirements

```dart
import 'dart:ui' show Color;
import 'y_axis_position.dart';  // From Task 1 - DO NOT REDEFINE
```

### 2. Test File (TDD - Create First!)

**Path**: `test/unit/multi_axis/y_axis_config_test.dart`

Write tests BEFORE implementing. Test groups should cover:

1. **Construction**
   - Creates with required parameters only
   - Creates with all parameters
   - Default values are correct

2. **Validation**
   - Empty id throws assertion error
   - minWidth <= 0 throws
   - maxWidth < minWidth throws
   - min >= max throws
   - tickCount == 1 throws

3. **copyWith**
   - Returns new instance (not same reference)
   - Changes specified values
   - Preserves unchanged values
   - Works with null values

4. **Equality**
   - Same values = equal
   - Different values = not equal
   - hashCode consistent with equality

### 3. Export

**File to modify**: `lib/src/models/enums.dart`

Add export after the existing y_axis_position export:
```dart
export 'y_axis_config.dart';
```

## Reference Pattern

Study `lib/src/models/axis_config.dart` for:
- Constructor style (`const`, `required`, defaults)
- Documentation comment format
- copyWith implementation pattern
- Equality implementation pattern

## Execution Order (TDD)

1. Create test file with failing tests
2. Run tests → should fail (class doesn't exist)
3. Create class implementation
4. Run tests → should pass
5. Add export to `enums.dart`
6. Run `flutter analyze lib/src/models/y_axis_config.dart`

## Example Usage (for context only)

```dart
final powerAxis = YAxisConfig(
  id: 'power',
  position: YAxisPosition.left,
  color: Colors.blue,
  label: 'Power',
  unit: 'W',
  min: 0,
  max: 400,
);

final hrAxis = YAxisConfig(
  id: 'heartrate',
  position: YAxisPosition.right,
  color: Colors.red,
  label: 'Heart Rate',
  unit: 'bpm',
);
```

## When Done

1. Stage your changes: `git add .`
2. Write to `.orchestra/handover/completion-signal.md`:
   - List files created/modified
   - Confirm all tests pass
   - Note any implementation decisions
3. Say "Task complete - ready for review"
