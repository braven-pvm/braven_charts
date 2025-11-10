# Dynamic Axes & Crosshair Labels Implementation

**Date**: 2025-11-10  
**Feature**: Make axes dynamic (update with zoom/pan) + Add crosshair coordinate labels

## Problem Statement

1. **Static Axes**: Axes showed original data range (1000-2000, 50-150) even when zoomed/panned
2. **No Coordinate Feedback**: Crosshair had no labels showing current position in data coordinates
3. **Axes Not Updating During Pan**: Axes updated AFTER pan completed (on mouse release), not smoothly during pan movement

## Solution Architecture

### Part 1: Just-In-Time Axis Updates (CRITICAL FIX)

**Initial Approach** (Didn't Work):
- Called `axis.updateDataRange()` in `_handlePointerMove()` before `markNeedsPaint()`
- Axes were updated, but visual rendering didn't reflect changes until pointer up
- Terminal showed "📏 Axes updated" every frame, but user didn't see axis labels changing

**Root Cause**:
- Flutter rendering pipeline timing: updating axes before `markNeedsPaint()` didn't guarantee the updated ticks would be used in the same paint frame
- Our architecture pre-generates ticks and stores them, unlike the reference implementation which calculates everything during paint

**Final Solution** (Matches Reference Implementation Pattern):
- Update axes **just-in-time during `paint()` method** before rendering them
- This ensures axes always use the absolute latest transform state
- Pattern matches `lib/src/widgets/braven_chart.dart` which recalculates axes dynamically during every paint

**Implementation**:
```dart
@override
void paint(PaintingContext context, Offset offset) {
  // ... setup ...
  
  // Update axes to match current viewport JUST-IN-TIME before painting
  // This ensures axes always reflect the latest transform state during every paint
  if (_transform != null) {
    _xAxis?.updateDataRange(_transform!.dataXMin, _transform!.dataXMax);
    _yAxis?.updateDataRange(_transform!.dataYMin, _transform!.dataYMax);
  }

  // Paint axes immediately after updating
  if (_xAxis != null) {
    AxisRenderer(_xAxis!).paint(canvas, size, _plotArea);
  }
  if (_yAxis != null) {
    AxisRenderer(_yAxis!).paint(canvas, size, _plotArea);
  }
}
```

**Why This Works**:
1. Every `markNeedsPaint()` call triggers `paint()`
2. During pan, `_handlePointerMove()` updates `_transform` and calls `markNeedsPaint()`
3. `paint()` is called and IMMEDIATELY updates axes with latest transform
4. Axes are rendered with fresh ticks reflecting current viewport
5. **Zero timing issues** - update and render happen atomically in same paint frame

### Part 2: Crosshair Coordinate Labels

Reference implementation (`lib/src/widgets/braven_chart.dart`) uses `_CrosshairLabelsPainter` to render coordinate labels. We integrated similar logic directly into our paint method.

**Implementation**:
- Added `_drawCrosshairLabels()` method (lines ~1193-1262)
- Added `_formatDataValue()` method (lines ~1264-1280)
- Called from `paint()` after drawing crosshair lines

**Label Format**:
- **X label**: Bottom of plot area, shows "X: {dataValue}"
- **Y label**: Left side of plot area, shows "Y: {dataValue}"
- Smart formatting: integers shown without decimals, scientific notation for tiny values
- Background with padding for readability

**Coordinate Conversion Flow**:
```
Widget Space → Plot Space → Data Space
cursorPos → widgetToPlot() → transform.plotToData()
```

## Code Changes

**File**: `refactor/interaction/lib/rendering/chart_render_box.dart`

### Modified Methods

1. **`paint()`** - Just-in-time axis updates (CRITICAL FIX):
   ```dart
   // BEFORE: Axes painted with potentially stale ticks
   if (_xAxis != null) {
     AxisRenderer(_xAxis!).paint(canvas, size, _plotArea);
   }
   
   // AFTER: Axes updated just-in-time before painting
   if (_transform != null) {
     _xAxis?.updateDataRange(_transform!.dataXMin, _transform!.dataXMax);
     _yAxis?.updateDataRange(_transform!.dataYMin, _transform!.dataYMax);
   }
   if (_xAxis != null) {
     AxisRenderer(_xAxis!).paint(canvas, size, _plotArea);
   }
   ```

2. **`paint()`** - Added crosshair label rendering:
   ```dart
   if (cursorPos != null) {
     // Draw crosshair lines...
     _drawCrosshairLabels(canvas, size, cursorPos); // NEW
   }
   ```

3. **`_handlePointerMove()`** - Simplified (removed redundant axis update):
   ```dart
   _transform = _transform!.pan(clampedDx, clampedDy);
   // Axes will be updated just-in-time during paint()
   markNeedsPaint();
   ```

### Added Methods

```dart
/// Draws coordinate labels for the crosshair.
void _drawCrosshairLabels(Canvas canvas, Size size, Offset cursorPos) {
  // Convert widget → plot → data coordinates
  // Paint X label at bottom, Y label at left
  // Background + text with smart formatting
}

/// Formats data values for display (same logic as axis labels).
String _formatDataValue(double value) {
  // Integer check, scientific notation, decimal places
}
```

### Removed Helper (No Longer Needed)

```dart
// REMOVED: _updateAxesFromTransform() 
// Was called from multiple locations (zoom/pan/scroll)
// NOW: Axes updated just-in-time in paint() instead
```

## Testing Results

✅ **Axes update SMOOTHLY during pan** - Real-time visual updates as mouse moves  
✅ **Axes update on zoom** (Shift+scroll)  
✅ **Axes update on keyboard pan**  
✅ **Axes update on programmatic pan**  
✅ **Crosshair labels render** with data coordinates  
✅ **Terminal logging** shows tick regeneration count per axis update  

## Key Insight: Rendering Pipeline Timing

**Problem**: When axes were updated before `markNeedsPaint()`, there was no guarantee the updated ticks would be used in the same paint frame due to Flutter's rendering pipeline batching/scheduling.

**Solution**: Update axes **inside `paint()`** just before rendering them. This creates an atomic operation:
- Transform updated → `markNeedsPaint()` called
- Paint triggered → Axes updated with latest transform → Axes rendered immediately
- No timing gaps, no stale data

This matches the reference implementation's pattern where they calculate `bounds` and axis intervals dynamically during every paint cycle.

## Performance Considerations

**During Pan (Pointer Move)**:
- Update transform ✓
- Trigger repaint ✓
- **Just-in-time** update axes during paint ✓
- Render axes with fresh ticks ✓
- **Defer** element regeneration until pointer up ✓

**After Pan (Pointer Up)**:
- Regenerate elements ✓
- Rebuild spatial index ✓

This ensures smooth 60fps panning with live axis updates while maintaining optimal performance.

## Reference Implementation Comparison

### lib/src (Reference)
```dart
void _drawAxes(Canvas canvas, Size size, Rect chartRect, _DataBounds bounds) {
  // Calculate intervals dynamically during paint
  final xInterval = _calculateNiceInterval(bounds.maxX - bounds.minX);
  
  // Generate and render labels on-the-fly
  var currentX = firstX;
  while (currentX <= bounds.maxX) {
    // Paint label at currentX
    currentX += xInterval;
  }
}
```

### refactor/interaction (Our Implementation)
```dart
@override
void paint(PaintingContext context, Offset offset) {
  // Update axes just-in-time with current transform
  if (_transform != null) {
    _xAxis?.updateDataRange(_transform!.dataXMin, _transform!.dataXMax);
    _yAxis?.updateDataRange(_transform!.dataYMin, _transform!.dataYMax);
  }
  
  // Paint axes with fresh ticks
  AxisRenderer(_xAxis!).paint(canvas, size, _plotArea);
}
```

**Both approaches** recalculate axes during paint based on current viewport state. The reference does it inline, we delegate to Axis/AxisRenderer classes, but the timing is identical.

## Future Enhancements

1. **Gridlines**: Could add dynamic gridlines matching axis ticks
2. **Label Style**: Could make crosshair label style configurable
3. **Label Position**: Could make label positioning configurable (outside vs inside plot)
4. **Snap to Data**: Could add snap-to-nearest-point for crosshair
5. **Performance**: Consider caching ticks if viewport hasn't changed (optimization)
