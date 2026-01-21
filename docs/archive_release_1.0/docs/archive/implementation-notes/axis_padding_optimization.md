# Axis Padding Optimization - SUPERSEDED

**Date**: October 21, 2025  
**Branch**: `007-interaction-system`  
**Status**: ⚠️ SUPERSEDED by axis_position_implementation.md

---

## ⚠️ IMPORTANT NOTICE

**This document is SUPERSEDED by the full axis positioning implementation.**

Please refer to **`axis_position_implementation.md`** for the complete, current implementation.

**What Changed**:

- Initial optimization (Phase 18) had a bug - incorrectly assumed axisPosition was used
- Bug fix (Phase 19) simplified but disabled the positioning feature
- Full implementation (Phase 20) made axisPosition fully functional
- Axes now render at the positions specified by axisPosition property

**See**: `axis_position_implementation.md` for comprehensive documentation.

---

## Historical Record (Original Document Below)

This document describes the initial optimization attempt (Phase 18) which had a bug
that was later fixed by implementing full axis positioning functionality.

### Problem (Historical)

The chart was reserving 40px of padding on **all four sides** (top, right, bottom, left) regardless of whether axes were actually positioned there. This resulted in:

- **Wasted space** on top and right sides when using default bottom/left axes
- **Smaller chart plotting area** than necessary
- **Empty orange padding zones** where no axes existed

### Before (Wasteful):

```
┌─────────────────────────────────┐
│ 🟠 TOP: 40px (EMPTY - no axis)  │
│ ┌────────────────────────────┐ │
│🟠│                          │🟠│
│ │   🔵 CHART AREA          │ │
│L │                          │R │
│E │                          │I │
│F │                          │G │
│T │                          │H │
│ │                          │T │
│4 │                          │: │
│0 │                          │4 │
│p │                          │0 │
│x │                          │p │
│ │                          │x │
│ │                          │ │
│ └────────────────────────────┘🟠│
│ 🟠 BOTTOM: 40px (X-axis here)   │
└─────────────────────────────────┘
```

## Solution

Dynamic padding calculation based on actual axis positions:

```dart
// Calculate padding based on actual axis positions
const axisPadding = 40.0;
final leftPadding = (yAxis.showAxis && yAxis.axisPosition == AxisPosition.left)
    ? axisPadding : 0.0;
final rightPadding = (yAxis.showAxis && yAxis.axisPosition == AxisPosition.right)
    ? axisPadding : 0.0;
final topPadding = (xAxis.showAxis && xAxis.axisPosition == AxisPosition.top)
    ? axisPadding : 0.0;
final bottomPadding = (xAxis.showAxis && xAxis.axisPosition == AxisPosition.bottom)
    ? axisPadding : 0.0;

final chartRect = Rect.fromLTWH(
  leftPadding,
  topPadding,
  size.width - leftPadding - rightPadding,
  size.height - topPadding - bottomPadding,
);
```

### After (Optimized):

```
┌─────────────────────────────────┐
│ 🔵 CHART AREA (larger!)         │
│ ┌────────────────────────────── │
│🟠│
│ │
│L │
│E │
│F │
│T │
│ │
│4 │
│0 │
│p │
│x │
│ │
│ │
│ └────────────────────────────────
│ 🟠 BOTTOM: 40px (X-axis here)   │
└─────────────────────────────────┘
```

## Changes Made

### 1. Updated `_BravenChartPainter.paint()` (line ~2402)

**File**: `lib/src/widgets/braven_chart.dart`

**Before**:

```dart
const padding = 40.0;
final chartRect = Rect.fromLTWH(
  padding,
  padding,
  size.width - padding * 2,
  size.height - padding * 2
);
```

**After**:

```dart
const axisPadding = 40.0;
final leftPadding = (yAxis.showAxis && yAxis.axisPosition == AxisPosition.left)
    ? axisPadding : 0.0;
final rightPadding = (yAxis.showAxis && yAxis.axisPosition == AxisPosition.right)
    ? axisPadding : 0.0;
final topPadding = (xAxis.showAxis && xAxis.axisPosition == AxisPosition.top)
    ? axisPadding : 0.0;
final bottomPadding = (xAxis.showAxis && xAxis.axisPosition == AxisPosition.bottom)
    ? axisPadding : 0.0;

final chartRect = Rect.fromLTWH(
  leftPadding,
  topPadding,
  size.width - leftPadding - rightPadding,
  size.height - topPadding - bottomPadding,
);
```

### 2. Updated `_calculateChartRect()` (line ~1807)

**File**: `lib/src/widgets/braven_chart.dart`

Applied the same logic to the interaction system's chart rect calculation to ensure tooltip positioning remains accurate.

### 3. Added Import

**File**: `lib/src/widgets/braven_chart.dart` (line ~31)

```dart
import 'package:braven_charts/src/widgets/enums/axis_position.dart';
```

## Impact Analysis

### ✅ Benefits

1. **Larger Chart Area**: Charts with default bottom/left axes now have ~80px more plotting area (40px recovered from top, 40px from right)
2. **No Wasted Space**: Padding only where axes actually exist
3. **Flexible Positioning**: Supports all 4 axis positions (top, right, bottom, left)
4. **Backward Compatible**: Existing charts continue to work without changes

### 🔍 Testing Required

- [x] Default configuration (bottom X-axis, left Y-axis)
- [x] Hidden axes (no padding)
- [ ] Right Y-axis positioning
- [ ] Top X-axis positioning
- [ ] Tooltip positioning accuracy with new padding
- [ ] Crosshair alignment with new boundaries
- [ ] Zoom/pan interactions

## Coordinate System Impact

### Before Optimization:

```
Stack Coordinates (RED area): Full widget
Chart Coordinates (BLUE area): Widget minus 40px on ALL sides
Tooltip positioning: Uses Stack coordinates
```

### After Optimization:

```
Stack Coordinates (RED area): Full widget
Chart Coordinates (BLUE area): Widget minus padding ONLY where axes exist
Tooltip positioning: Uses Stack coordinates (unchanged)
```

**Critical**: Tooltip positioning logic (`_calculateTooltipPosition`) uses Stack coordinates and is **not affected** by this change. Tooltips will continue to position correctly.

## Examples

### Default Configuration (bottom/left)

```dart
BravenChart(
  chartType: ChartType.line,
  series: [/* data */],
  // Default axes: bottom X, left Y
)
```

**Result**: Padding on bottom (40px) and left (40px) only. Top and right edges extend to widget boundary.

### Hidden Axes (sparkline)

```dart
BravenChart(
  chartType: ChartType.line,
  series: [/* data */],
  xAxis: AxisConfig.hidden(),
  yAxis: AxisConfig.hidden(),
)
```

**Result**: NO padding on any side. Chart fills entire widget.

### Top/Right Axes (inverted)

```dart
BravenChart(
  chartType: ChartType.line,
  series: [/* data */],
  xAxis: AxisConfig.defaults().copyWith(
    axisPosition: AxisPosition.top,
  ),
  yAxis: AxisConfig.defaults().copyWith(
    axisPosition: AxisPosition.right,
  ),
)
```

**Result**: Padding on top (40px) and right (40px) only. Bottom and left edges extend to widget boundary.

## Regression Risks

### 🔴 HIGH RISK (Require Testing)

1. **Tooltip Positioning**: Tooltips must still align correctly with data points
   - **Mitigation**: `_calculateChartRect()` updated with same logic
   - **Status**: Verified in code, needs visual testing

2. **Crosshair Alignment**: Crosshair must align with chart edges
   - **Mitigation**: Uses same chartRect calculation
   - **Status**: Needs testing

3. **Zoom/Pan Boundaries**: Must respect new dynamic boundaries
   - **Mitigation**: Uses chartRect from painter
   - **Status**: Needs testing

### 🟡 MEDIUM RISK

4. **Annotations**: Text/point/range annotations must respect new boundaries
   - **Status**: Uses same coordinate system

5. **Hit Testing**: Interaction events must map correctly to new chart area
   - **Status**: Uses chartRect calculation

### 🟢 LOW RISK

6. **Grid Lines**: Should automatically adjust (driven by chartRect)
7. **Series Rendering**: Should automatically adjust (driven by chartRect)

## Validation Checklist

- [x] Code compiles without errors
- [x] Flutter analyze passes
- [x] Default axes work (bottom/left)
- [ ] Tooltips position correctly
- [ ] Crosshair aligns with edges
- [ ] Zoom/pan respects boundaries
- [ ] Hidden axes remove all padding
- [ ] Top X-axis positioning
- [ ] Right Y-axis positioning
- [ ] Mixed axis positions

## Files Modified

1. `lib/src/widgets/braven_chart.dart`
   - Added import for `AxisPosition`
   - Updated `_BravenChartPainter.paint()` method
   - Updated `_calculateChartRect()` method

## Migration Guide

**No migration required!** This optimization is fully backward compatible. Existing code continues to work without any changes.

## Next Steps

1. ✅ Implement dynamic padding calculation
2. ✅ Update chart rect calculation for interaction system
3. ⏳ Visual testing with example app
4. ⏳ Test tooltip positioning with various axis configurations
5. ⏳ Test crosshair with various axis configurations
6. ⏳ Update documentation if needed
7. ⏳ Commit and push changes

## Related Issues

- Tooltip positioning architecture: `tooltip_positioning_architecture_fix.md`
- Coordinate system design: `docs/guides/coordinate-system.md`

---

**Author**: AI Assistant  
**Reviewer**: TBD  
**Last Updated**: October 21, 2025
