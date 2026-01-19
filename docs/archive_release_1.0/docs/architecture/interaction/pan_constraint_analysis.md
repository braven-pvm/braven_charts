# Pan Constraint Analysis - Deep Dive

**Date**: November 10, 2025  
**Status**: 🔴 PROBLEM IDENTIFIED  
**Priority**: CRITICAL - Blocking production use

---

## Executive Summary

The pan constraint implementation in `chart_render_box.dart` has **fundamental conceptual errors** in how it tracks and constrains viewport boundaries. The current approach attempts to track the "original data boundaries" in the current viewport, but this creates **contradictory constraints** that make panning feel unpredictable and broken.

**Key Issues**:
1. ❌ **Conceptual Error**: Tracks where "original data edges" appear in current viewport (wrong reference frame)
2. ❌ **Coordinate Confusion**: Mixes up which direction data/viewport moves during pan
3. ❌ **Constraint Contradictions**: "Both edges past limits" logic creates impossible states
4. ❌ **Zoom-Dependent Behavior**: Constraints behave differently at different zoom levels

**Impact**: Users experience:
- Panning stops unexpectedly (hitting invisible walls)
- Panning works in one direction but not the opposite
- Constraints feel inconsistent between zoom levels
- Recovery from "over-panned" state is confusing

---

## Problem Context

### Project Background
- **Project**: braven_charts v2.0 interaction architecture prototype
- **Location**: `refactor/interaction/` 
- **Current Phase**: Phase 0 prototype validation
- **Design Docs**: `docs/architecture/interaction/interaction_architecture_design.md`

### Constraint Requirements
From the design specification:
- **Goal**: Limit panning to prevent excessive whitespace beyond data boundaries
- **Constraint**: Original data edges can move off-screen by up to 10% of viewport (maxWhitespaceFraction = 0.1)
- **Behavior**: Panning should feel like "hitting a wall" when limit is reached
- **Zoom Independence**: Constraints should work consistently at all zoom levels

---

## Coordinate System Architecture

### Three Coordinate Spaces

From `chart_transform.dart` and design docs:

#### 1. **Widget Space**
- **Definition**: Entire chart widget including axes and margins
- **Origin**: Top-left corner of widget
- **Use**: Pointer events, cursor positions

#### 2. **Plot Space**  
- **Definition**: Plotting area only (excluding axes)
- **Origin**: Top-left corner of plot area (after axis margins)
- **Range**: `(0, 0)` → `(plotWidth, plotHeight)`
- **Use**: Element rendering, hit testing, spatial index

#### 3. **Data Space**
- **Definition**: Logical data values (timestamps, prices, etc.)
- **Range**: `(dataXMin, dataXMax)` × `(dataYMin, dataYMax)` - determined by visible viewport
- **Use**: Original data storage, zoom/pan calculations

### Transform Operations

#### Data → Plot (for rendering)
```dart
// Convert data value to plot pixel position
final plotX = (dataX - dataXMin) / dataXRange * plotWidth;
final plotY = invertY 
    ? (1.0 - (dataY - dataYMin) / dataYRange) * plotHeight  // Y=0 at bottom
    : (dataY - dataYMin) / dataYRange * plotHeight;         // Y=0 at top
```

#### Plot → Data (for hit testing)
```dart
// Convert plot pixel position to data value
final dataX = dataXMin + (plotX / plotWidth) * dataXRange;
final dataY = dataYMin + (invertY 
    ? (1.0 - plotY / plotHeight) 
    : plotY / plotHeight) * dataYRange;
```

#### Pan Operation (transform.pan)
```dart
// Pan updates data viewport by converting plot delta to data delta
final dataDx = plotDx * dataPerPixelX;  // dataPerPixelX = dataXRange / plotWidth
final dataDy = invertY ? -plotDy * dataPerPixelY : plotDy * dataPerPixelY;

// Shift data viewport
dataXMin += dataDx;
dataXMax += dataDx;
dataYMin += dataDy;
dataYMax += dataDy;
```

**CRITICAL INSIGHT**: Panning shifts the **data viewport** (what data values are visible), while plot space remains fixed (0 → plotWidth, 0 → plotHeight).

---

## Current Implementation Analysis

### Constraint Algorithm (Lines 350-570 of chart_render_box.dart)

#### Step 1: Calculate where "original data boundaries" appear in current viewport
```dart
// Convert original data min/max to CURRENT plot coordinates
final originalLeft = _transform!.dataToPlot(_originalTransform!.dataXMin, 0.0).dx;
final originalRight = _transform!.dataToPlot(_originalTransform!.dataXMax, 0.0).dx;
```

**Example Scenario**:
- Original data: X ∈ [0, 100] (stored in _originalTransform)
- Current viewport: X ∈ [0, 100] (no pan yet, _transform matches original)
- Plot width: 800px

Result:
- `originalLeft = dataToPlot(0) = 0px` (left edge at left side of plot)
- `originalRight = dataToPlot(100) = 800px` (right edge at right side of plot)

#### Step 2: Define allowed bounds with 10% whitespace
```dart
final minLeftEdge = -plotWidth * maxWhitespaceFraction;    // -80px
final maxRightEdge = plotWidth * (1.0 + maxWhitespaceFraction);  // 880px
```

**Interpretation**: Original data edges can move:
- Left edge: from 0px to -80px (10% off left side of plot)
- Right edge: from 800px to 880px (10% off right side of plot)

#### Step 3: Calculate "margins" (distance from limit)
```dart
final leftMargin = originalLeft - minLeftEdge;      // 0 - (-80) = 80px room
final rightMargin = maxRightEdge - originalRight;   // 880 - 800 = 80px room
```

**Interpretation**: How much room each edge has before hitting its limit.

#### Step 4: Clamp pan delta based on margins
```dart
if (requestedDx > 0) {
    // Panning right: LEFT edge approaches left limit
    clampedDx = requestedDx.clamp(0, leftMargin);  // Max 80px right pan
}
```

---

## The Fundamental Problems

### Problem 1: Wrong Reference Frame 🔴 CRITICAL

**Current Approach**: Tracks where "original data boundaries" appear in the **current viewport**.

**Why This Is Wrong**:
- When you pan, the data viewport moves, but "original boundaries" are fixed data values
- As you zoom in, "original boundaries" move **off-screen naturally** because you're viewing a subset
- At 2x zoom, the original boundaries are **already outside the viewport** by design
- The constraint tries to prevent this natural behavior, creating contradictions

**Example**:
```
Original viewport: Data X ∈ [0, 100], Plot: 0 → 800px
├─────────────────────────────────────────────────┤
0px                                              800px
dataX=0                                       dataX=100

After 2x zoom centered at X=50:
Data X ∈ [25, 75], Plot: 0 → 800px
├─────────────────────────────────────────────────┤
0px                                              800px
dataX=25                                       dataX=75

Where are "original boundaries" now?
- dataX=0 would plot at: (0-25)/50 * 800 = -400px (way off left side!)
- dataX=100 would plot at: (100-25)/50 * 800 = 1200px (way off right side!)
```

At 2x zoom, the original boundaries are **naturally 400px off-screen**. The constraint tries to prevent panning that would move them further off-screen, but they're **already off-screen** just from zooming!

### Problem 2: "Both Edges Past Limits" Logic is Nonsensical

```dart
if (bothXEdgesPastLimits) {
    // At extreme zoom, both edges are outside bounds
    // ONLY allow panning that brings edges back toward center (recovery)
```

**Why This Breaks**:
1. At any zoom > 1.2x, **both original edges are naturally past the 10% limits**
2. The code thinks this is an "error state" requiring "recovery"
3. It only allows panning that would "bring edges back" toward viewport center
4. But this **prevents normal panning** at moderate zoom levels!

**Example at 2x Zoom**:
- Original left edge (dataX=0) plots at -400px (past -80px limit)
- Original right edge (dataX=100) plots at 1200px (past 880px limit)
- Code: "Both edges past limits! Only allow recovery panning!"
- User tries to pan right to see dataX=60-75 region
- Code blocks it because that moves originalLeft further left (-450px)
- **User experience**: "Pan is broken at 2x zoom"

### Problem 3: Directional Pan Logic is Backwards

The code has extensive comments explaining the logic:

```dart
// CRITICAL UNDERSTANDING:
// - Pan RIGHT (+dx) → data moves RIGHT → originalLeft/Right plot positions move LEFT
```

**This is INCORRECT**. Let's trace through what actually happens:

#### What ACTUALLY Happens When You Pan Right (+dx)

1. **User Action**: Drag mouse right by 50px (plotDx = +50)
2. **Transform Calculation**: `dataDx = plotDx * dataPerPixelX = 50 * 0.125 = 6.25` data units
3. **Viewport Update**: 
   ```dart
   dataXMin = 25 + 6.25 = 31.25  // Viewport moved RIGHT in data space
   dataXMax = 75 + 6.25 = 81.25
   ```
4. **Visual Effect**: Chart content slides LEFT (viewport moved right, so you see rightward data)

**Critical Realization**: 
- ✅ Pan right → viewport moves right in data space
- ✅ Visual: content slides left (you see data that was to the right)
- ❌ Code assumes: "data moves right, so originalLeft position moves LEFT"
- ✅ Reality: originalLeft is a **fixed data value** (dataX=0), its **plot position** only changes when viewport changes

Let's calculate originalLeft plot position after pan:
```dart
// Before pan: viewport = [25, 75]
originalLeft = (0 - 25) / 50 * 800 = -400px

// After pan right: viewport = [31.25, 81.25]  
originalLeft = (0 - 31.25) / 50 * 800 = -500px  // Moved further LEFT (more negative)
```

**The code got this RIGHT accidentally** (originalLeft DOES move left when panning right), but the explanation is wrong. The confusion comes from thinking about "data moving" instead of "viewport moving".

### Problem 4: Margin Calculations Measure the Wrong Thing

```dart
final leftMargin = originalLeft - minLeftEdge;  // How far from limit
```

**What This Measures**: "How far is the original left data boundary from being 10% off the left side of the current viewport?"

**What We SHOULD Measure**: "How far can the viewport move before the **currently visible data** would show excessive whitespace?"

The difference is subtle but critical:
- **Current approach**: Constrains based on where original boundaries are
- **Correct approach**: Constrains based on where current viewport is relative to original data extent

---

## Why Users Experience "Broken" Panning

### Symptom 1: Panning Stops at Low Zoom Levels
- **Cause**: At 1.5x zoom, original boundaries are ~60px off-screen (past -80px limit)
- **Trigger**: Code enters "both edges past limits" recovery mode
- **Effect**: Only allows "recovery panning" back toward center
- **User Experience**: "I can only pan one direction, feels broken"

### Symptom 2: Panning Works Fine at 1x Zoom, Breaks at 2x
- **Cause**: Constraints are zoom-dependent due to tracking "original boundary positions"
- **At 1x**: Original boundaries are at plot edges (0px, 800px) - plenty of margin
- **At 2x**: Original boundaries are way off-screen (-400px, 1200px) - triggers "recovery mode"
- **User Experience**: "Why does zoom level change how panning works?"

### Symptom 3: Hitting "Invisible Walls" Prematurely
- **Cause**: Margin calculations prevent panning when original edges approach limits
- **Effect**: User can't pan far enough to see all interesting data
- **Example**: At 2x zoom viewing [25,75], user wants to pan to see [40,90]
  - This requires panning right to shift viewport to [40,90]
  - Original right edge (dataX=100) would plot at: (100-40)/50*800 = 960px
  - 960px > 880px limit → pan blocked!
  - But there's still **10 data units** of original data to the right (90-100)!
- **User Experience**: "There's more data to see, why won't it let me pan there?"

---

## The Correct Conceptual Model

### What We SHOULD Constrain

**Goal**: Prevent the viewport from panning so far that you see excessive whitespace beyond the original data extent.

**Key Insight**: We don't care where "original boundaries appear in the viewport" - we care about the **relationship between the viewport and the original data extent**.

### Correct Approach: Viewport Position Constraints

Think of it like a camera (viewport) panning over a fixed scene (original data):

```
Original Data Extent: X ∈ [0, 100]
Viewport (Camera): X ∈ [dataXMin, dataXMax]  (size = dataXRange)

Allowed Viewport Positions:
- Leftmost: dataXMin >= 0 - (plotWidth * 0.1 / pixelsPerDataX)
            "Can start up to 10% of viewport width LEFT of data start"
            
- Rightmost: dataXMax <= 100 + (plotWidth * 0.1 / pixelsPerDataX)
             "Can end up to 10% of viewport width RIGHT of data end"
```

#### Calculating Maximum Whitespace in Data Units

At any zoom level:
```dart
final dataPerPixel = dataXRange / plotWidth;  // Current zoom: data units per pixel

// 10% of viewport in data units
final maxWhitespaceData = plotWidth * 0.1 * dataPerPixel;

// Viewport position limits
final minDataXMin = originalDataXMin - maxWhitespaceData;  // Can start this far left
final maxDataXMax = originalDataXMax + maxWhitespaceData;  // Can end this far right

// Equivalently for right edge:
final maxDataXMin = originalDataXMax - dataXRange - maxWhitespaceData;  // Leftmost start position
final minDataXMax = originalDataXMin + dataXRange + maxWhitespaceData;  // Rightmost end position
```

**Example at 2x Zoom**:
```
Original: X ∈ [0, 100]
Current: X ∈ [25, 75]  (dataXRange = 50, zoom = 2x)
Plot: 800px
dataPerPixel = 50/800 = 0.0625

maxWhitespaceData = 800 * 0.1 * 0.0625 = 5 data units

Constraints:
- dataXMin >= 0 - 5 = -5     (viewport can start 5 units before data start)
- dataXMax <= 100 + 5 = 105  (viewport can end 5 units after data end)

OR equivalently:
- dataXMin <= 100 - 50 + 5 = 55   (viewport can start up to X=55)
- dataXMax >= 0 + 50 - 5 = 45     (viewport must end at least at X=45)

Current viewport [25, 75] is WITHIN these constraints ✓
- 25 >= -5 ✓ and 25 <= 55 ✓
- 75 <= 105 ✓ and 75 >= 45 ✓
```

### Clamping Pan Delta - Correct Approach

Given a requested pan delta in plot pixels, we need to calculate the maximum allowed delta that keeps the viewport within constraints:

```dart
// Current viewport
final currentDataXMin = _transform!.dataXMin;
final currentDataXMax = _transform!.dataXMax;

// Calculate what new viewport would be
final dataDx = plotDx * dataPerPixelX;
final tentativeDataXMin = currentDataXMin + dataDx;
final tentativeDataXMax = currentDataXMax + dataDx;

// Calculate limits (in data space)
final minAllowedDataXMin = originalDataXMin - maxWhitespaceData;
final maxAllowedDataXMax = originalDataXMax + maxWhitespaceData;

// Clamp tentative viewport to limits
final clampedDataXMin = tentativeDataXMin.clamp(minAllowedDataXMin, maxAllowedDataXMax - dataXRange);
final clampedDataXMax = tentativeDataXMax.clamp(minAllowedDataXMin + dataXRange, maxAllowedDataXMax);

// Calculate how much we actually moved
final actualDataDx = clampedDataXMin - currentDataXMin;  // OR: clampedDataXMax - currentDataXMax

// Convert back to plot space
final actualPlotDx = actualDataDx / dataPerPixelX;

return actualPlotDx;
```

---

## Recommended Solution

### Approach 1: Direct Viewport Constraint (Recommended)

**Algorithm**:
1. Calculate requested viewport change in data space
2. Calculate allowed viewport bounds in data space
3. Clamp viewport to bounds
4. Convert back to plot delta

**Advantages**:
- ✅ Conceptually simple and correct
- ✅ Zoom-independent (constraints scale automatically)
- ✅ No special cases or "recovery modes"
- ✅ Predictable "wall" behavior

**Implementation** (pseudocode):
```dart
(double, double) _clampPanDelta(double requestedPlotDx, double requestedPlotDy) {
  // Convert plot delta to data delta
  final requestedDataDx = requestedPlotDx * dataPerPixelX;
  final requestedDataDy = requestedPlotDy * dataPerPixelY;
  
  // Calculate tentative new viewport
  final tentativeXMin = dataXMin + requestedDataDx;
  final tentativeXMax = dataXMax + requestedDataDx;
  final tentativeYMin = dataYMin + requestedDataDy;
  final tentativeYMax = dataYMax + requestedDataDy;
  
  // Calculate max whitespace in data units
  final maxWhitespaceX = plotWidth * maxWhitespaceFraction * dataPerPixelX;
  final maxWhitespaceY = plotHeight * maxWhitespaceFraction * dataPerPixelY;
  
  // Calculate allowed viewport bounds
  final minAllowedXMin = originalDataXMin - maxWhitespaceX;
  final maxAllowedXMin = originalDataXMax - dataXRange + maxWhitespaceX;
  final minAllowedYMin = originalDataYMin - maxWhitespaceY;
  final maxAllowedYMin = originalDataYMax - dataYRange + maxWhitespaceY;
  
  // Clamp viewport to bounds
  final clampedXMin = tentativeXMin.clamp(minAllowedXMin, maxAllowedXMin);
  final clampedYMin = tentativeYMin.clamp(minAllowedYMin, maxAllowedYMin);
  
  // Calculate actual movement
  final actualDataDx = clampedXMin - dataXMin;
  final actualDataDy = clampedYMin - dataYMin;
  
  // Convert back to plot space
  final actualPlotDx = actualDataDx / dataPerPixelX;
  final actualPlotDy = actualDataDy / dataPerPixelY;
  
  return (actualPlotDx, actualPlotDy);
}
```

### Approach 2: Viewport-Percentage Constraint (Alternative)

Instead of "10% of current viewport", use "10% of original data extent":

```dart
// Max whitespace = 10% of ORIGINAL data range (zoom-independent)
final maxWhitespaceX = originalDataXRange * 0.1;
final maxWhitespaceY = originalDataYRange * 0.1;

// Viewport constraints
final minAllowedXMin = originalDataXMin - maxWhitespaceX;
final maxAllowedXMin = originalDataXMax - dataXRange + maxWhitespaceX;
```

**Trade-offs**:
- ✅ Even simpler (maxWhitespace is constant)
- ✅ Zoom-independent constraints
- ⚠️ At high zoom, whitespace appears larger on screen (10% of original data is more pixels)
- ⚠️ At low zoom, whitespace appears smaller on screen

**Recommendation**: Use **Approach 1** (viewport-based) for consistency with user's visual experience.

---

## Migration Strategy

### Phase 1: Replace _clampPanDelta Implementation
1. Remove current implementation (lines 308-570)
2. Implement new algorithm based on Approach 1
3. Remove "both edges past limits" logic entirely
4. Remove directional pan checks (no longer needed)

### Phase 2: Update Comments
1. Remove misleading "data moves right/left" comments
2. Add correct "viewport moves in data space" explanations
3. Document zoom-independence of constraints

### Phase 3: Test Coverage
1. Unit tests for _clampPanDelta at different zoom levels
2. Integration tests for pan-to-edge behavior
3. Verify zoom-independent constraint behavior
4. Test recovery from manual viewport manipulation

### Phase 4: Remove Roaming Radius Code
The "roaming radius" code (lines 348-405) was a workaround for high-zoom constraints. With correct viewport constraints, this is no longer needed.

---

## Test Cases to Validate

### Test 1: Pan at 1x Zoom (No Zoom)
```dart
Original: [0, 100] × [0, 100]
Viewport: [0, 100] × [0, 100]  (1x zoom)
Plot: 800×600

Action: Pan right 100px
Expected: Viewport shifts to ~[12.5, 112.5]
Constraint: dataXMax <= 100 + 10 = 110 ✓ (within limit)
```

### Test 2: Pan at 2x Zoom
```dart
Original: [0, 100] × [0, 100]
Viewport: [25, 75] × [25, 75]  (2x zoom, centered)
Plot: 800×600

Action: Pan right 100px (attempt to see [31.25, 81.25])
Expected: Allowed (within constraints)
Constraint: dataXMax = 81.25 <= 100 + 6.25 = 106.25 ✓
```

### Test 3: Pan to Edge at 2x Zoom
```dart
Viewport: [25, 75]  (2x zoom)
maxWhitespaceData = 800 * 0.1 * 0.0625 = 5

Action: Pan right until edge
Expected: Stops when dataXMax = 100 + 5 = 105
Final viewport: [55, 105]  (right edge 5 units past original data)
Visual: See 10% whitespace on right side
```

### Test 4: Pan to Edge at 5x Zoom
```dart
Viewport: [40, 60]  (5x zoom, 20 data units visible)
maxWhitespaceData = 800 * 0.1 * 0.025 = 2

Action: Pan right until edge
Expected: Stops when dataXMax = 100 + 2 = 102
Final viewport: [82, 102]
Visual: See 10% whitespace on right side (same as 2x zoom)
```

### Test 5: Zoom Independence
```dart
At all zoom levels (1x, 2x, 5x), the amount of whitespace visible
when panned to edge should be the same: 10% of viewport.

This confirms constraints are zoom-independent ✓
```

---

## Expected Outcomes

After implementing the correct approach:

✅ **Zoom Independence**: Panning works the same at all zoom levels  
✅ **Predictable Walls**: Panning stops with consistent whitespace across zoom levels  
✅ **No Special Cases**: No "recovery mode" or "both edges past limits" logic  
✅ **Smooth UX**: Users never hit unexpected invisible walls  
✅ **Mathematically Correct**: Viewport position constraints are geometrically sound  

---

## Conclusion

The current pan constraint implementation has a **fundamental conceptual error** in tracking "original boundary positions in current viewport" rather than "viewport position relative to original data extent". This leads to zoom-dependent behavior, contradictory constraints, and a broken user experience.

The solution is to **completely rewrite `_clampPanDelta`** using direct viewport position constraints in data space. This approach is simpler, mathematically correct, and provides zoom-independent behavior.

**Next Steps**:
1. Implement new `_clampPanDelta` algorithm (Approach 1)
2. Remove "roaming radius" and "both edges past limits" code
3. Add comprehensive test coverage
4. Validate pan-to-edge behavior at multiple zoom levels

---

**Document Owner**: AI Assistant  
**Review Status**: Ready for team review  
**Implementation Priority**: CRITICAL
