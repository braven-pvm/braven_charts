# Current Task: Create Multi-Axis Painter

## Objective

Create the visual rendering infrastructure for multiple Y-axes. This includes a painter for drawing axes, a layout delegate for computing widths, and a layout manager for positioning axes at their configured positions.

## Context

We now have:
- ✅ `MultiAxisNormalizer` - Core normalization engine (Task 6)
- ✅ `NormalizationDetector` - Auto-detection logic (Task 7)
- ✅ Pipeline integration (Task 8) - Normalization wired into chart
- ✅ `YAxisConfig` - Axis configuration model (Task 2)
- ✅ `YAxisPosition` - Position enum (outerLeft, left, right, outerRight)
- ✅ `DataRange` - Min/max bounds container

**This task adds the VISUAL rendering** - painting the actual Y-axes on screen.

## User Story Reference

**US1 (P1)**: Multi-scale data visualization
> "Each series uses the full vertical height of the chart while displaying its own properly-scaled Y-axis."

**FR-001**: System MUST support up to 4 Y-axes positioned as: outerLeft, left, right, outerRight
**FR-005**: All Y-axis labels and ticks MUST display original data values (not normalized values)
**FR-007**: Each Y-axis MUST support color-coding to match its bound series

## ⚠️ TDD REQUIREMENT

1. **Write tests FIRST** (they should fail initially)
2. **Then implement** to make tests pass

## What to Create

### 1. Test File (Create FIRST!)

**Path**: `test/unit/multi_axis/multi_axis_painter_test.dart`

```dart
import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:braven_charts/braven_charts.dart';

void main() {
  group('MultiAxisLayoutDelegate', () {
    group('computeAxisWidths', () {
      test('returns empty map for empty axis list');
      test('computes width based on label text measurement');
      test('respects YAxisConfig.minWidth');
      test('respects YAxisConfig.maxWidth');
      test('includes space for unit suffix');
      test('accounts for tick marks width');
    });
    
    group('getTotalLeftWidth', () {
      test('returns 0 for no left axes');
      test('sums widths of left and outerLeft axes');
    });
    
    group('getTotalRightWidth', () {
      test('returns 0 for no right axes');
      test('sums widths of right and outerRight axes');
    });
  });
  
  group('AxisLayoutManager', () {
    group('getAxisRect', () {
      test('positions outerLeft axis at far left');
      test('positions left axis inside outerLeft');
      test('positions right axis at right edge of plot area');
      test('positions outerRight axis outside right');
      test('handles single axis at each position');
      test('handles all 4 axes simultaneously');
    });
    
    group('computePlotArea', () {
      test('reduces chart area by axis widths');
      test('preserves plot area when no axes');
    });
  });
  
  group('MultiAxisPainter', () {
    group('paint', () {
      test('paints axis line at correct position');
      test('paints tick marks at computed locations');
      test('paints tick labels with original values');
      test('uses axis color from YAxisConfig');
      test('includes unit suffix in labels');
      test('handles empty axis configuration gracefully');
    });
    
    group('tick value computation', () {
      test('generates appropriate tick count for axis height');
      test('uses nice numbers for tick values');
      test('respects explicit min/max from YAxisConfig');
      test('uses denormalized values from DataRange');
    });
  });
  
  group('acceptance scenarios', () {
    test('renders 2 axes - one left, one right');
    test('renders 4 axes at all positions');
    test('each axis shows original scale values');
  });
}
```

### 2. Layout Directory

**Create**: `lib/src/layout/` directory

### 3. MultiAxisLayoutDelegate

**Path**: `lib/src/layout/multi_axis_layout.dart`

```dart
import 'dart:ui';

import 'package:flutter/painting.dart';

import '../models/data_range.dart';
import '../models/y_axis_config.dart';
import '../models/y_axis_position.dart';

/// Computes axis widths based on content requirements.
///
/// This delegate measures the text width needed for tick labels
/// and determines appropriate axis widths within the configured bounds.
class MultiAxisLayoutDelegate {
  const MultiAxisLayoutDelegate();
  
  /// Computes the required width for each axis.
  ///
  /// Returns a map from axis ID to computed width.
  ///
  /// Width is determined by:
  /// - Maximum tick label width (based on [DataRange] values)
  /// - Unit suffix width if specified
  /// - Tick mark width
  /// - Constrained by [YAxisConfig.minWidth] and [YAxisConfig.maxWidth]
  Map<String, double> computeAxisWidths({
    required List<YAxisConfig> axes,
    required Map<String, DataRange> axisBounds,
    required TextStyle labelStyle,
  }) {
    // TODO: Implement
    // 1. For each axis, compute max label width from bounds
    // 2. Add unit suffix width if present
    // 3. Add padding for tick marks
    // 4. Clamp to minWidth/maxWidth
  }
  
  /// Gets total width of left-side axes (outerLeft + left).
  double getTotalLeftWidth(
    List<YAxisConfig> axes,
    Map<String, double> widths,
  ) {
    // TODO: Implement
  }
  
  /// Gets total width of right-side axes (right + outerRight).
  double getTotalRightWidth(
    List<YAxisConfig> axes,
    Map<String, double> widths,
  ) {
    // TODO: Implement
  }
}
```

### 4. AxisLayoutManager

**Path**: `lib/src/layout/axis_layout_manager.dart`

```dart
import 'dart:ui';

import '../models/y_axis_config.dart';
import '../models/y_axis_position.dart';

/// Manages positioning of multiple Y-axes around the chart area.
///
/// Positions axes according to FR-001:
/// - outerLeft: Leftmost position
/// - left: Inside outerLeft, adjacent to plot area
/// - right: Right edge of plot area
/// - outerRight: Rightmost position
class AxisLayoutManager {
  const AxisLayoutManager();
  
  /// Gets the rectangle for rendering a specific axis.
  ///
  /// [chartArea] is the total available chart area.
  /// [axis] is the axis configuration.
  /// [axisWidths] contains computed widths for all axes.
  /// [allAxes] is the complete list of axis configurations.
  Rect getAxisRect({
    required Rect chartArea,
    required YAxisConfig axis,
    required Map<String, double> axisWidths,
    required List<YAxisConfig> allAxes,
  }) {
    // TODO: Implement
    // Calculate X offset based on position and other axes
    // Width comes from axisWidths[axis.id]
    // Height matches plot area height
  }
  
  /// Computes the plot area after reserving space for axes.
  ///
  /// Returns the rectangle available for chart data rendering
  /// after accounting for all axis widths.
  Rect computePlotArea({
    required Rect chartArea,
    required List<YAxisConfig> axes,
    required Map<String, double> axisWidths,
  }) {
    // TODO: Implement
    // Subtract left widths from left edge
    // Subtract right widths from right edge
  }
}
```

### 5. MultiAxisPainter

**Path**: `lib/src/rendering/multi_axis_painter.dart`

```dart
import 'dart:ui';

import 'package:flutter/painting.dart';

import '../layout/axis_layout_manager.dart';
import '../layout/multi_axis_layout.dart';
import '../models/data_range.dart';
import '../models/y_axis_config.dart';
import 'multi_axis_normalizer.dart';

/// Paints multiple Y-axes with their tick marks and labels.
///
/// Uses [MultiAxisNormalizer.denormalize] to convert normalized
/// tick positions back to original data values for display.
class MultiAxisPainter {
  MultiAxisPainter({
    required this.axes,
    required this.axisBounds,
    this.labelStyle,
  });
  
  final List<YAxisConfig> axes;
  final Map<String, DataRange> axisBounds;
  final TextStyle? labelStyle;
  
  final _layoutDelegate = const MultiAxisLayoutDelegate();
  final _layoutManager = const AxisLayoutManager();
  
  /// Paints all configured axes on the canvas.
  ///
  /// [canvas] is the canvas to draw on.
  /// [chartArea] is the total chart area (axes will be painted outside plot area).
  /// [plotArea] is the data rendering area (axes align to this).
  void paint(Canvas canvas, Rect chartArea, Rect plotArea) {
    // TODO: Implement
    // 1. Compute axis widths
    // 2. For each axis:
    //    a. Get axis rect from layout manager
    //    b. Paint axis line
    //    c. Generate tick values from bounds
    //    d. Paint tick marks
    //    e. Paint tick labels (denormalized values)
  }
  
  /// Paints a single axis.
  void _paintAxis(
    Canvas canvas,
    YAxisConfig axis,
    Rect axisRect,
    Rect plotArea,
    DataRange bounds,
  ) {
    // TODO: Implement
    // Draw axis line
    // Draw ticks and labels
  }
  
  /// Generates nice tick values for an axis.
  List<double> _generateTicks(DataRange bounds, int maxTicks) {
    // TODO: Implement
    // Use nice number algorithm
  }
  
  /// Formats a tick value with optional unit suffix.
  String _formatTickLabel(double value, YAxisConfig axis) {
    // TODO: Implement
    // Format number + add unit suffix
  }
}
```

### 6. Barrel Export

**Path**: `lib/src/layout/layout.dart`

```dart
export 'axis_layout_manager.dart';
export 'multi_axis_layout.dart';
```

Update main barrel file if needed.

## Dependencies

```dart
// Use from completed tasks:
import 'package:braven_charts/src/rendering/multi_axis_normalizer.dart';
import 'package:braven_charts/src/models/data_range.dart';
import 'package:braven_charts/src/models/y_axis_config.dart';
import 'package:braven_charts/src/models/y_axis_position.dart';
```

## Algorithm Notes

### Nice Number Algorithm for Ticks

```dart
// Generate "nice" tick values that are easy to read
double niceNum(double range, bool round) {
  final exponent = (log(range) / ln10).floor();
  final fraction = range / pow(10, exponent);
  
  double niceFraction;
  if (round) {
    if (fraction < 1.5) niceFraction = 1;
    else if (fraction < 3) niceFraction = 2;
    else if (fraction < 7) niceFraction = 5;
    else niceFraction = 10;
  } else {
    if (fraction <= 1) niceFraction = 1;
    else if (fraction <= 2) niceFraction = 2;
    else if (fraction <= 5) niceFraction = 5;
    else niceFraction = 10;
  }
  
  return niceFraction * pow(10, exponent);
}
```

### Axis Position Layout

```
+------------------+---+---+--------+---+---+
| outerLeft | left |   PLOT AREA   | right | outerRight |
+------------------+---+---+--------+---+---+
```

## Test Execution

```bash
# Run multi-axis painter tests (should FAIL initially)
flutter test test/unit/multi_axis/multi_axis_painter_test.dart

# Ensure all sprint tests still pass
flutter test test/unit/multi_axis/
```

## Quality Gates (MANDATORY)

### 1. Linting - Zero Issues
```bash
flutter analyze lib/src/rendering/multi_axis_painter.dart
flutter analyze lib/src/layout/
flutter analyze test/unit/multi_axis/multi_axis_painter_test.dart
```

### 2. All Sprint Tests Must Pass
```bash
flutter test test/unit/multi_axis/
flutter test test/integration/multi_axis_normalization_integration_test.dart
flutter test test/integration/multi_axis_pipeline_integration_test.dart
```

Current baseline: **192 tests passing** (MUST NOT decrease!)

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
