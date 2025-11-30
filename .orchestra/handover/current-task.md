# Task 12: Update Tooltip to Show Original Values

## Objective

Create a multi-axis value formatter that converts normalized Y-values back to original values with proper unit formatting. Update the tooltip system to display original Y-values with their units (e.g., "250 W", "145 bpm") instead of normalized 0-1 values.

---

## Context

**Sprint**: 011-multi-axis-normalization  
**Phase**: Interaction (Phase 6: US4)  
**Depends On**: Task 11 (Widget Integration)

**Category**: ⚠️ **INTEGRATION TASK** - Modifies existing tooltip system

**Current State**:
- Tooltips exist in `lib/legacy/src/interaction/tooltip_provider.dart`
- `MultiAxisNormalizer.denormalize()` exists for reversing normalization
- Chart has `_seriesYRanges` storing min/max for each series
- No unit formatting exists yet
- Tooltips currently show raw data point values

**Required State**:
- New `MultiAxisValueFormatter` class for formatting values with units
- Tooltip displays original values with unit suffix (e.g., "Power: 250 W")
- Decimal precision is appropriate (no over-precision like 250.00000001)
- Works for both single-axis and multi-axis modes

---

## SpecKit Traceability

**SpecKit Tasks Covered**:

| SpecKit ID | Description | File Path |
|------------|-------------|-----------|
| T023 | Update tooltip to display original Y-values with units | `lib/src/interaction/tooltip_builder.dart` |
| T042 | Create multi-axis value formatter | `lib/src/formatting/multi_axis_value_formatter.dart` |
| T045 | Format decimal values appropriately (no over-precision) | `lib/src/formatting/multi_axis_value_formatter.dart` |
| T040 | Unit test for value formatting with units | `test/unit/multi_axis/value_formatter_test.dart` |

**Contract References**:
- N/A - No formal contract for value formatter

---

## File Operations

| Operation | File Path | Purpose |
|-----------|-----------|---------||
| CREATE | `lib/src/formatting/multi_axis_value_formatter.dart` | T042, T045 - Value formatter with unit support |
| CREATE | `test/unit/multi_axis/value_formatter_test.dart` | T040 - Unit tests for value formatter |
| CREATE | `example/lib/demos/task_012_tooltip_demo.dart` | Visual verification demo |
| UPDATE | `lib/legacy/src/interaction/tooltip_provider.dart` | T023 - Use value formatter for displaying Y-values |
| UPDATE | `lib/braven_charts.dart` | Export new formatter |

### Deliverable Details

| File | Changes |
| `lib/legacy/src/interaction/tooltip_provider.dart` | Integrate MultiAxisValueFormatter for Y-value display |
| `lib/braven_charts.dart` | Add export for MultiAxisValueFormatter |

---

## Technical Context

### Dependencies (imports from completed tasks):

`dart
import 'package:braven_charts/src/rendering/multi_axis_normalizer.dart';
import 'package:braven_charts/src/models/y_axis_config.dart';
`

### ⚠️ MUST USE (DO NOT DUPLICATE):

| Utility | Use For | DO NOT |
|---------|---------|--------|
| `MultiAxisNormalizer.denormalize()` | Converting normalized (0-1) values back to original range | Inline `(normalized * (max - min)) + min` |
| `YAxisConfig.unit` | Getting unit string for an axis | Hardcoded unit strings |

---

## TDD

**Test File**: `test/unit/multi_axis/value_formatter_test.dart`

**Test Cases to Implement FIRST**:

1. `formats integer value with unit` - `format(250, unit: 'W')` → `"250 W"`
2. `formats decimal value with appropriate precision` - `format(123.456789)` → `"123.46"`
3. `handles null unit gracefully` - `format(100, unit: null)` → `"100"`
4. `optimal precision for large values` - `optimalPrecision(1234.5)` → 0 or 1
5. `optimal precision for small values` - `optimalPrecision(0.00123)` → 4 or 5
6. `handles negative values` - `format(-50.5, unit: 'W')` → `"-50.5 W"`
7. `formats denormalized value correctly` - Denormalize 0.5 from range (100, 300) → 200

---

## Code Scaffold

`dart
/// lib/src/formatting/multi_axis_value_formatter.dart

library;

import '../rendering/multi_axis_normalizer.dart';

/// Formats numeric values with optional units for chart display.
class MultiAxisValueFormatter {
  const MultiAxisValueFormatter._();

  /// Formats a value with optional unit suffix.
  static String format({
    required double value,
    String? unit,
    int? precision,
  }) {
    final p = precision ?? optimalPrecision(value);
    final formatted = value.toStringAsFixed(p);
    final clean = _cleanTrailingZeros(formatted);
    return unit != null ? '$clean $unit' : clean;
  }

  /// Determines optimal decimal precision based on value magnitude.
  static int optimalPrecision(double value) {
    final abs = value.abs();
    if (abs >= 100) return 0;
    if (abs >= 10) return 1;
    if (abs >= 1) return 2;
    if (abs >= 0.1) return 3;
    return 4;
  }

  /// Denormalizes a 0-1 value and formats it with unit.
  static String formatWithDenormalization({
    required double normalizedValue,
    required double min,
    required double max,
    String? unit,
    int? precision,
  }) {
    final original = MultiAxisNormalizer.denormalize(normalizedValue, min, max);
    return format(value: original, unit: unit, precision: precision);
  }

  static String _cleanTrailingZeros(String s) {
    if (!s.contains('.')) return s;
    var result = s;
    while (result.endsWith('0')) {
      result = result.substring(0, result.length - 1);
    }
    if (result.endsWith('.')) {
      result = result.substring(0, result.length - 1);
    }
    return result;
  }
}
`

---

## Visual Verification

**Task Category**: INTEGRATION

### Demo File: `example/lib/demos/task_012_tooltip_demo.dart`

Create a chart with multi-axis that shows tooltip values with units when hovering.

### Flutter Agent Workflow

⛔ **CRITICAL: Use ONLY flutter_agent.py for visual verification!**

`powershell
# 1. Start Flutter (from repo root):
Start-Process -FilePath "powershell" -ArgumentList "-NoExit", "-Command", `
  "cd 'e:\cloud services\Dropbox\Repositories\Flutter\braven_charts_v2.0\example'; python ..\tools\flutter_agent\flutter_agent.py run lib/demos/task_012_tooltip_demo.dart -d chrome"

# 2. Wait for app:
python ..\tools\flutter_agent\flutter_agent.py wait --timeout 30

# 3. Screenshot:
python ..\tools\flutter_agent\flutter_agent.py screenshot --output ../.orchestra/verification/screenshots/task-012-tooltip-values.png

# 4. Stop:
python ..\tools\flutter_agent\flutter_agent.py stop
`

### Expected Output
- Tooltip shows: "Power: 250 W" (not "0.5" or "250.00000001")
- Tooltip shows: "Heart Rate: 120 bpm"

---

## Acceptance Criteria

- [ ] `MultiAxisValueFormatter.format()` exists and formats values with units
- [ ] `MultiAxisValueFormatter.optimalPrecision()` handles all magnitude ranges
- [ ] `MultiAxisValueFormatter.formatWithDenormalization()` uses `MultiAxisNormalizer.denormalize()`
- [ ] All 7 unit tests pass in `value_formatter_test.dart`
- [ ] Tooltip shows formatted values with units (visual verification)
- [ ] No over-precision (e.g., "250.00000001" should be "250")
- [ ] Works for both positive and negative values
- [ ] Export added to `lib/braven_charts.dart`

---

## Quality Gates

`bash
flutter analyze lib/src/formatting/
flutter test test/unit/multi_axis/value_formatter_test.dart
flutter test test/unit/multi_axis/
`

**Test Baseline**: 210 unit + 13 widget tests (MUST NOT decrease!)

---

## Completion Protocol

1. Run `pre-signal-check.ps1` (MANDATORY)
2. Verify linting clean
3. Verify ALL tests pass
4. Visual verification via flutter_agent.py
5. Write to `completion-signal.md`
6. Say "Task complete - ready for review"
