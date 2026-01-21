# Pan Constraint Y-Axis Inversion Bug Fix

**Date**: November 10, 2025  
**Status**: ✅ FIXED  
**Bug**: Y-axis panning constraint caused chart to disappear when hitting boundary  
**Root Cause**: Constraint calculation didn't account for Y-axis inversion

---

## Problem Description

### User Report

"Panning left and right seems to work 100% at each zoom level. Panning up and down - when I hit the 'wall' the entire chart/render area is cleared (nothing is rendered, everything disappears)."

### Root Cause Analysis

The bug was caused by a **mismatch between coordinate transformations** in the constraint calculation vs the actual pan operation.

**Flutter's Y-Axis Coordinate System**:

- Screen/Plot space: Y=0 at top, increases downward (standard canvas coordinates)
- Data space: Y=0 at bottom, increases upward (standard chart convention)
- `ChartTransform` has `invertY = true` by default to handle this

**The ChartTransform.pan() Method**:

```dart
ChartTransform pan(double plotDx, double plotDy) {
  final dataDx = plotDx * dataPerPixelX;
  final dataDy = invertY
      ? -plotDy * dataPerPixelY  // ← NEGATES plotDy for inverted Y
      : plotDy * dataPerPixelY;

  final newDataYMin = dataYMin + dataDy;
  final newDataYMax = dataYMax + dataDy;
  // ...
}
```

**The Bug in \_clampPanDelta (Original)**:

```dart
// WRONG: Doesn't account for Y inversion!
final requestedDataDy = requestedPlotDy * dataPerPixelY;  // ← Missing negation
final tentativeDataYMin = _transform!.dataYMin + requestedDataDy;

// ... constraint calculation ...

final actualPlotDy = actualDataDy / dataPerPixelY;  // ← Missing reverse negation
```

**What Happened**:

1. User drags down (positive plotDy)
2. Constraint calculates: `dataYMin += positive` (viewport moves UP in data space)
3. But `pan()` applies: `dataYMin += negative` (viewport moves DOWN in data space)
4. Constraint and pan() work in **opposite directions**!
5. When constraint clamps to boundary, `pan()` inverts it and goes past the boundary
6. Results in invalid transform with degenerate range or out-of-bounds values
7. Element generator produces empty list or invalid coordinates
8. Chart disappears! 💥

---

## The Fix

### Code Changes

**Step 1: Match Y-Axis Inversion in Constraint Calculation**

```dart
// BEFORE (WRONG):
final requestedDataDy = requestedPlotDy * dataPerPixelY;

// AFTER (CORRECT):
final requestedDataDy = _transform!.invertY
    ? -requestedPlotDy * dataPerPixelY  // Invert Y movement (match pan() logic)
    : requestedPlotDy * dataPerPixelY;
```

**Step 2: Reverse Inversion When Converting Back**

```dart
// BEFORE (WRONG):
final actualPlotDy = actualDataDy / dataPerPixelY;

// AFTER (CORRECT):
final actualPlotDy = _transform!.invertY
    ? -actualDataDy / dataPerPixelY  // Reverse Y inversion
    : actualDataDy / dataPerPixelY;
```

### Why This Works

Now the constraint calculation uses the **same coordinate transformation logic** as `pan()`:

1. **Convert plot → data**: Apply inversion if `invertY = true`
2. **Calculate constraints**: Work in consistent data space
3. **Convert data → plot**: Reverse inversion if `invertY = true`

**Result**: Constraints and pan() now agree on coordinate directions! ✅

---

## Mathematical Validation

### Example: Pan Down at Boundary

**Setup**:

- Original data range: Y = 50..150
- Current viewport: Y = 50..150 (at 1x zoom, no pan yet)
- Max whitespace: 10% of viewport = 10 data units
- User drags DOWN (positive plotDy = +10 pixels)

**Step-by-Step** (with fix):

1. **Convert to data space** (with inversion):

   ```
   dataPerPixelY = 100 / 540 = 0.185
   requestedDataDy = -(+10) * 0.185 = -1.85
   ```

2. **Calculate tentative position**:

   ```
   tentativeDataYMin = 50 + (-1.85) = 48.15
   ```

3. **Calculate allowed bounds**:

   ```
   minAllowedDataYMin = 50 - 10 = 40
   maxAllowedDataYMin = 150 - 100 + 10 = 60
   ```

4. **Clamp**:

   ```
   clampedDataYMin = clamp(48.15, 40, 60) = 48.15 ✓
   ```

5. **Convert back to plot** (reverse inversion):

   ```
   actualDataDy = 48.15 - 50 = -1.85
   actualPlotDy = -(-1.85) / 0.185 = +10 ✓
   ```

6. **Apply pan()**:
   ```
   pan(0, +10) converts: dataDy = -(+10) * 0.185 = -1.85
   newDataYMin = 50 + (-1.85) = 48.15 ✓
   ```

**Result**: Constraint and pan() agree! Chart moves down smoothly. ✅

### Example: Pan Down Past Boundary

**Setup**: Same as above, but drag DOWN by 100 pixels (beyond boundary)

1. **Convert to data space**:

   ```
   requestedDataDy = -100 * 0.185 = -18.5
   ```

2. **Calculate tentative position**:

   ```
   tentativeDataYMin = 50 - 18.5 = 31.5
   ```

3. **Clamp to boundary**:

   ```
   clampedDataYMin = clamp(31.5, 40, 60) = 40  ← CLAMPED!
   ```

4. **Convert back**:

   ```
   actualDataDy = 40 - 50 = -10
   actualPlotDy = -(-10) / 0.185 = +54 pixels (reduced from 100)
   ```

5. **Apply pan()**:
   ```
   pan(0, +54) converts: dataDy = -54 * 0.185 = -10
   newDataYMin = 50 - 10 = 40 ✓ (exactly at boundary!)
   ```

**Result**: Pan stops at boundary (10% whitespace), no overshoot! ✅

---

## Testing Results

### Before Fix

- ❌ X-axis: Works correctly (no inversion needed)
- ❌ Y-axis: Chart disappears when hitting boundary
- ❌ Constraint and pan() work in opposite directions
- ❌ Invalid transform produced

### After Fix

- ✅ X-axis: Still works correctly
- ✅ Y-axis: Works correctly, matches X-axis behavior
- ✅ Constraint and pan() work in same direction
- ✅ Valid transform always produced
- ✅ Smooth "wall" feeling at boundaries on both axes

---

## Key Lessons Learned

### 1. Coordinate Transform Consistency

When implementing constraints on coordinate transformations:

- ✅ **MUST use the same transformation logic** as the operation being constrained
- ✅ **MUST account for axis inversions** (Y-axis in charts, coordinate system differences)
- ✅ **MUST apply inverse transformation** when converting back

### 2. Importance of Testing Both Axes

- X-axis worked because no inversion needed
- Y-axis failed because inversion was missed
- **Always test all axes independently!**

### 3. Debug Output is Critical

The validation code I added revealed the issue:

```dart
if (newDataYMax <= newDataYMin) {
  debugPrint('❌ ERROR: Degenerate Y range!');
  return (actualPlotDx, 0.0);  // Prevent invalid transform
}
```

This prevented the crash and made the bug obvious.

---

## Code Quality Improvement

### Before

```dart
// Simple but wrong - assumes no inversion
final requestedDataDy = requestedPlotDy * dataPerPixelY;
final actualPlotDy = actualDataDy / dataPerPixelY;
```

### After

```dart
// Correct - handles inversion explicitly
final requestedDataDy = _transform!.invertY
    ? -requestedPlotDy * dataPerPixelY  // Invert for charts
    : requestedPlotDy * dataPerPixelY;   // Standard for canvas

final actualPlotDy = _transform!.invertY
    ? -actualDataDy / dataPerPixelY     // Reverse inversion
    : actualDataDy / dataPerPixelY;
```

**Benefits**:

- ✅ Explicit about coordinate system handling
- ✅ Self-documenting (comments explain why)
- ✅ Matches ChartTransform.pan() logic exactly
- ✅ Works for both inverted and non-inverted Y-axes

---

## Related Files

**Modified**:

- `lib/rendering/chart_render_box.dart` - Fixed `_clampPanDelta()` method

**Reference**:

- `lib/transforms/chart_transform.dart` - Contains `pan()` method with inversion logic
- `docs/architecture/interaction/pan_constraint_analysis.md` - Original problem analysis
- `docs/architecture/interaction/pan_constraint_solution_algorithm.md` - Solution design

---

## Summary

**Bug**: Y-axis constraint calculation didn't account for Flutter's inverted Y-axis coordinate system.

**Fix**: Apply the same Y-inversion logic in constraint calculation that `ChartTransform.pan()` uses:

1. Negate plotDy when converting to data space (if invertY=true)
2. Negate dataDy when converting back to plot space (if invertY=true)

**Result**: Y-axis panning now works identically to X-axis - smooth panning with solid "wall" boundaries at all zoom levels!

**Status**: ✅ **FIXED AND VERIFIED**

---

**Document Owner**: AI Assistant  
**Fix Date**: November 10, 2025  
**Verification**: User tested and confirmed Y-axis now works correctly
