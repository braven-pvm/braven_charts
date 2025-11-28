# Current Task: Create YAxisPosition Enum

## Objective

Create a `YAxisPosition` enum that defines the four positions where Y-axes can appear in a multi-axis chart.

## Context

Multi-axis charts can display up to 4 Y-axes simultaneously. Each axis needs a position:
- Two on the left side of the chart (outer and inner)
- Two on the right side of the chart (inner and outer)

Layout order from left to right:
```
[outerLeft] [left] | Chart Area | [right] [outerRight]
```

## What to Create

### 1. Enum File

**Path**: `lib/src/models/y_axis_position.dart`

Create an enum with these values (in this exact order):
- `outerLeft` - Leftmost position
- `left` - Inner left (primary/default position)
- `right` - Inner right
- `outerRight` - Rightmost position

**Requirements**:
- Add `///` documentation comment on the enum explaining its purpose
- Add `///` documentation comment on each value explaining when to use it
- Follow the pattern in `lib/src/models/enums.dart` for style reference

### 2. Test File (TDD - Create First!)

**Path**: `test/unit/multi_axis/y_axis_position_test.dart`

Write tests BEFORE implementing the enum. Tests should verify:
- Enum has exactly 4 values
- All expected values exist
- Values are in correct order (matches layout order)
- Enum names are correct strings

### 3. Export

**File to modify**: `lib/src/models/enums.dart`

Add an export at the end of the file:
```dart
export 'y_axis_position.dart';
```

## Execution Order (TDD)

1. Create test directory: `test/unit/multi_axis/`
2. Create test file with failing tests
3. Run tests → should fail (enum doesn't exist)
4. Create enum implementation
5. Run tests → should pass
6. Add export to `enums.dart`
7. Run `flutter analyze` on the new file

## When Done

1. Stage your changes: `git add .`
2. Write to `.orchestra/handover/completion-signal.md`:
   - List files created/modified
   - Confirm tests pass
   - Note any decisions made
3. Say "Task complete - ready for review"
