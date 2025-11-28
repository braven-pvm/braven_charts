# Task Context: Multi-Axis Normalization Sprint

## What We're Building

A multi-axis normalization feature for BravenChartPlus that allows displaying multiple data series with vastly different Y-ranges on the same chart. Each series gets its own Y-axis showing original values.

**Example use case**: Display Power (0-300W) and Tidal Volume (0.5-4L) on the same chart, each using full vertical space.

## Current Codebase Structure

```
lib/src/
├── models/
│   ├── enums.dart          ← Barrel exports, add new exports here
│   ├── chart_series.dart   ← Will be modified later
│   └── ...
├── axis/
│   ├── axis.dart           ← Axis barrel file
│   └── ...
├── widgets/
│   └── braven_chart_plus.dart  ← Main chart widget
└── ...

test/unit/
├── models/
├── axis/
└── multi_axis/             ← Create this for new tests
```

## Existing Patterns to Follow

### Enum Style (from `lib/src/models/enums.dart`)

```dart
/// Description of what the enum represents.
///
/// More details about usage.
enum ExampleEnum {
  /// Description of this value.
  valueOne,

  /// Description of this value.
  valueTwo,
}
```

### Test Style

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:braven_charts/src/models/example.dart';

void main() {
  group('ExampleEnum', () {
    test('has expected values', () {
      expect(ExampleEnum.values.length, equals(2));
    });
  });
}
```

## Sprint Goal

Enable charts to:
1. Display multiple Y-axes (up to 4)
2. Normalize each series independently
3. Show original values on each axis
4. Auto-detect when normalization is needed

## Your Role

You're implementing one task at a time. Focus only on the current task in `current-task.md`. Don't look ahead or try to anticipate future tasks.
