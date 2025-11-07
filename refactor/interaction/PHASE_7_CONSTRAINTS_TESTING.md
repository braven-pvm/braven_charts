# Phase 7: Zoom/Pan Constraints - Testing Guide

## Overview
Phase 7 implements zoom and pan constraints to prevent users from getting "lost" during chart navigation. All zoom and pan operations now respect defined limits and provide a reset mechanism.

## Features Implemented

### 1. Zoom Constraints
- **Min Zoom Level**: 0.1x (can zoom out to show 10x original data range)
- **Max Zoom Level**: 10.0x (can zoom in to show 1/10th original data range)
- **Applied to**:
  - Shift + MouseWheel zoom (cursor-centered)
  - Keyboard +/- zoom (plot-centered)

### 2. Pan Constraints
- **Minimum Visible Data**: 10% of original data range must remain visible
- **Applied to**:
  - Middle-button drag pan
  - Arrow key pan

### 3. Reset View Functionality
- **Keyboard Shortcuts**: 
  - `Home` key: Reset to original zoom/pan state
  - `R` key: Reset to original zoom/pan state
- **Behavior**: Restores original data ranges while preserving current plot dimensions

## Implementation Details

### Constraint Constants
```dart
// In chart_render_box.dart
static const double minZoomLevel = 0.1;
static const double maxZoomLevel = 10.0;
static const double minVisibleDataFraction = 0.1;
```

### Original Transform Capture
- Captured during first `performLayout()` when transform is created
- Stored in `_originalTransform` field
- Used for:
  - Calculating current zoom level relative to original
  - Enforcing pan bounds
  - Reset functionality

### Zoom Clamping Algorithm
1. Calculate current zoom level: `originalRange / currentRange`
2. If zoom exceeds limits, clamp to min/max
3. Scale data ranges to clamped zoom level
4. Preserve center point of current viewport

### Pan Clamping Algorithm
1. Check if panned viewport overlaps original data by at least 10%
2. If not, shift viewport to maintain minimum overlap
3. Clamp in all four directions (left, right, up, down)

## Test Scenarios

### A. Zoom Constraint Testing

#### Test A1: Max Zoom In (Shift+Wheel)
**Steps**:
1. Press and hold Shift
2. Scroll wheel UP repeatedly (zoom in)
3. Continue until constraints activate

**Expected**:
- Zooming should stop at 10x zoom level
- Debug console shows: `🔒 Zoom clamped: X=...→10.0, Y=...→10.0`
- Further scroll attempts have no effect
- View remains stable at max zoom

#### Test A2: Max Zoom Out (Shift+Wheel)
**Steps**:
1. Press and hold Shift
2. Scroll wheel DOWN repeatedly (zoom out)
3. Continue until constraints activate

**Expected**:
- Zooming should stop at 0.1x zoom level
- Debug console shows: `🔒 Zoom clamped: X=...→0.1, Y=...→0.1`
- Further scroll attempts have no effect
- View remains stable at min zoom

#### Test A3: Keyboard Zoom Limits (+/-)
**Steps**:
1. Press `+` or `=` key repeatedly (zoom in)
2. Note when zoom stops
3. Press `-` key repeatedly (zoom out)
4. Note when zoom stops

**Expected**:
- Same zoom limits as wheel zoom (0.1x to 10x)
- Clamp messages in debug console
- Smooth stop at limits

#### Test A4: Zoom Constraint at Different Centers
**Steps**:
1. Move cursor to top-left corner
2. Shift+Wheel zoom in to max
3. Move cursor to bottom-right corner
4. Shift+Wheel zoom in to max

**Expected**:
- Constraints apply regardless of zoom center
- Max zoom level consistent across all center points
- Center point preserved correctly even when clamped

### B. Pan Constraint Testing

#### Test B1: Pan Too Far Left (Middle-Button)
**Steps**:
1. Middle-button drag chart far to the RIGHT
2. Continue dragging until constraints activate
3. Try to drag further

**Expected**:
- Panning stops when only 10% of original data visible on left edge
- Debug console shows: `🔒 Pan clamped: X too far right`
- Chart "resists" further panning in that direction
- At least 10% of original X range remains visible

#### Test B2: Pan Too Far Right (Arrow Keys)
**Steps**:
1. Press Right Arrow key repeatedly
2. Continue until constraints activate

**Expected**:
- Panning stops when only 10% of original data visible on right edge
- Debug console shows: `🔒 Pan clamped: X too far left`
- Further arrow presses have no effect
- At least 10% of original X range remains visible

#### Test B3: Pan Bounds in All Directions
**Steps**:
1. Pan left until constraint (Right Arrow repeatedly)
2. Pan right until constraint (Left Arrow repeatedly)
3. Pan up until constraint (Down Arrow repeatedly)
4. Pan down until constraint (Up Arrow repeatedly)

**Expected**:
- Constraints activate in all four directions
- Minimum 10% visibility maintained in all cases
- Smooth resistance at boundaries
- No jarring stops or visual glitches

#### Test B4: Pan Constraints After Zoom In
**Steps**:
1. Zoom in to 5x (Shift+Wheel or +++)
2. Middle-button drag in all directions
3. Try to pan beyond bounds

**Expected**:
- Pan constraints still apply even when zoomed in
- Constraint calculation uses original data range, not current zoom
- 10% visibility rule enforced correctly
- Zoomed view stays within bounds

### C. Reset View Testing

#### Test C1: Reset After Zoom (Home Key)
**Steps**:
1. Zoom in several times (Shift+Wheel up)
2. Press `Home` key

**Expected**:
- View instantly resets to original zoom level
- Data ranges match original transform
- Debug console shows: `🔄 View reset to original`
- Elements regenerate with original transform

#### Test C2: Reset After Pan (R Key)
**Steps**:
1. Pan chart in various directions (Middle-button drag)
2. Press `R` key

**Expected**:
- View instantly resets to original pan position
- Center of chart returns to original location
- Debug console shows: `🔄 View reset to original`
- Elements regenerate with original transform

#### Test C3: Reset After Complex Navigation
**Steps**:
1. Zoom in to 5x
2. Pan left, then up
3. Zoom out to 2x
4. Pan right
5. Press `Home` key

**Expected**:
- View resets completely to initial state
- All zoom and pan changes undone
- Original data ranges restored
- Plot dimensions preserved (if resized)

#### Test C4: Reset Preserves Plot Dimensions
**Steps**:
1. Resize browser window (if on web)
2. Zoom and pan chart
3. Press `Home` key

**Expected**:
- Data ranges reset to original
- Plot dimensions match CURRENT window size (not original)
- Transform uses `copyWith(plotWidth, plotHeight)` correctly
- Chart fills available space

### D. Edge Cases and Combinations

#### Test D1: Zoom at Constraint + Pan
**Steps**:
1. Zoom to max (10x)
2. Try to zoom more (should clamp)
3. Pan around the zoomed view

**Expected**:
- Zoom stays at max
- Pan still works within bounds
- Constraints independent and both enforced

#### Test D2: Pan at Constraint + Zoom
**Steps**:
1. Pan to right edge (left constraint)
2. Try to pan more (should clamp)
3. Zoom in and out

**Expected**:
- Pan stays at constraint
- Zoom works normally
- After zoom, pan constraints recalculated correctly

#### Test D3: Rapid Constraint Transitions
**Steps**:
1. Zoom in rapidly to max
2. Immediately zoom out rapidly to min
3. Immediately reset view

**Expected**:
- No visual glitches or stuttering
- Constraints apply smoothly
- Reset works even after rapid changes
- Debug output shows clamping events

#### Test D4: Multiple Resets
**Steps**:
1. Zoom/pan
2. Reset (Home)
3. Zoom/pan differently
4. Reset (R)
5. Repeat several times

**Expected**:
- Every reset returns to same original state
- Original transform never changes
- Reset reliable across multiple uses
- No state corruption

## Debug Console Output

### Expected Messages

**Transform Capture** (on first layout):
```
📸 Original transform captured: dataX=1000..2000, dataY=50..150
```

**Zoom Constraints**:
```
🔒 Zoom clamped: X=12.5→10.0, Y=12.5→10.0
🔒 Zoom clamped: X=0.05→0.1, Y=0.05→0.1
```

**Pan Constraints**:
```
🔒 Pan clamped: X too far right
🔒 Pan clamped: X too far left
🔒 Pan clamped: Y too far down
🔒 Pan clamped: Y too far up
```

**Reset View**:
```
🔄 View reset to original
⌨️ View reset to original
```

## Performance Considerations

### Constraint Calculation Cost
- Zoom clamping: ~10 calculations per zoom operation
- Pan clamping: ~8 calculations per pan operation
- Reset: Minimal cost (copyWith operation)

### Expected Performance
- No perceptible lag during constrained operations
- Smooth 60 FPS maintained
- Deferred regeneration still applies (only regenerate on pointer up for drag)

## Known Behaviors

### Smooth Constraint Feel
- Constraints should feel like "soft limits" not "hard stops"
- Zoom clamping preserves center point, so view doesn't jump
- Pan clamping shifts viewport minimally to enforce bounds

### Constraint Independence
- Zoom constraints independent of pan state
- Pan constraints independent of zoom level
- Both can be active simultaneously

### Reset Safety Net
- Reset always available as "escape hatch"
- Works from any zoom/pan state
- Instant (no animation)

## Success Criteria

Phase 7 is considered complete when:
- ✅ Zoom constrained to 0.1x - 10.0x range
- ✅ Pan constrained to keep 10% data visible
- ✅ Reset (Home/R) works from any state
- ✅ Constraints apply smoothly without glitches
- ✅ Debug output shows constraint activations
- ✅ All combinations work (zoom+pan, reset+zoom, etc.)
- ✅ Performance maintains 60 FPS
- ✅ No visual artifacts or state corruption

## Next Steps

After testing Phase 7:
1. Fix any issues found during testing
2. Adjust constraint values if UX feels wrong
3. Consider adding visual feedback when limits reached
4. Move to Phase 8: Testing and refinement
