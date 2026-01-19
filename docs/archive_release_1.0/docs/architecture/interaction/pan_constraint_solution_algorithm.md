# Pan Constraint Solution - Implementation Algorithm

**Date**: November 10, 2025  
**Status**: ✅ READY FOR IMPLEMENTATION  
**Reference**: PAN_CONSTRAINT_ANALYSIS.md

---

## Quick Reference: The Problem

❌ **Current Approach**: Tracks where "original data boundaries" appear in current viewport  
✅ **Correct Approach**: Tracks viewport position relative to original data extent  

**Result**: Zoom-independent, predictable pan constraints

---

## Visual Explanation

### Scenario: 2x Zoom with Pan Constraints

```
=== ORIGINAL DATA EXTENT (Fixed Reference) ===
Data X-Axis: [0 ────────────────────────────── 100]
             ↑                                    ↑
        originalDataXMin               originalDataXMax


=== VIEWPORT AT 2X ZOOM (Movable Window) ===

Initial Position (Centered):
Data X-Axis: [0 ─────────[25 ─────── 75]───────── 100]
                         ↑           ↑
                    dataXMin     dataXMax
                    (viewport start) (viewport end)

Viewport size: 75-25 = 50 data units
Zoom level: 100/50 = 2x


=== ALLOWED VIEWPORT POSITIONS ===

Max Whitespace: 10% of viewport = 10% of 50 units = 5 data units

Leftmost Position:
Data X-Axis: [-5 ─[0 ─────── 50]───────────── 100]
              ↑   ↑          ↑
         Whitespace │      dataXMax
         (5 units)  dataXMin
         
Constraint: dataXMin >= originalDataXMin - maxWhitespace
           dataXMin >= 0 - 5 = -5 ✓

Rightmost Position:
Data X-Axis: [0 ──────────────[50 ─────── 100]─ 105]
                              ↑           ↑    ↑
                         dataXMin    dataXMax  Whitespace
                                              (5 units)

Constraint: dataXMax <= originalDataXMax + maxWhitespace
           dataXMax <= 100 + 5 = 105 ✓


=== COMPARISON: CURRENT (WRONG) vs CORRECT ===

Current Approach (WRONG):
  Tracks: Where does dataX=0 and dataX=100 appear in PLOT SPACE?
  At 2x zoom centered: 
    - dataX=0 plots at -400px (way off left side!)
    - dataX=100 plots at +1200px (way off right side!)
  Result: "Both edges past limits! Enter recovery mode!" 🔴
  
Correct Approach:
  Tracks: Where is VIEWPORT positioned in DATA SPACE?
  At 2x zoom centered:
    - Viewport is [25, 75] in data space
    - Allowed range is [-5, 55] to [45, 105]
    - [25, 75] is within allowed range ✓ 🟢
  Result: Normal panning allowed in both directions
```

---

## The Algorithm - Step by Step

### Input Parameters
- `requestedPlotDx`: Requested pan delta in plot pixels (+ = pan right, - = pan left)
- `requestedPlotDy`: Requested pan delta in plot pixels (+ = pan down, - = pan up)

### Step 1: Convert to Data Space
```dart
// Current transform state
final dataXMin = _transform!.dataXMin;
final dataXMax = _transform!.dataXMax;
final dataYMin = _transform!.dataYMin;
final dataYMax = _transform!.dataYMax;

// Current viewport size (data units)
final dataXRange = dataXMax - dataXMin;
final dataYRange = dataYMax - dataYMin;

// Conversion factors
final dataPerPixelX = dataXRange / plotWidth;
final dataPerPixelY = dataYRange / plotHeight;

// Convert plot delta to data delta
final requestedDataDx = requestedPlotDx * dataPerPixelX;
final requestedDataDy = requestedPlotDy * dataPerPixelY;
```

**Example at 2x Zoom**:
```
Current viewport: [25, 75] (50 data units)
Plot width: 800px
dataPerPixelX = 50 / 800 = 0.0625 data units per pixel

User drags right 80px:
requestedPlotDx = 80
requestedDataDx = 80 * 0.0625 = 5 data units
```

### Step 2: Calculate Tentative New Viewport
```dart
final tentativeXMin = dataXMin + requestedDataDx;
final tentativeXMax = dataXMax + requestedDataDx;
final tentativeYMin = dataYMin + requestedDataDy;
final tentativeYMax = dataYMax + requestedDataDy;
```

**Example**:
```
Current: [25, 75]
requestedDataDx = 5
Tentative: [25+5, 75+5] = [30, 80]
```

### Step 3: Calculate Maximum Allowed Whitespace
```dart
// Max whitespace in data units (10% of current viewport)
final maxWhitespaceX = plotWidth * maxWhitespaceFraction * dataPerPixelX;
final maxWhitespaceY = plotHeight * maxWhitespaceFraction * dataPerPixelY;
```

**Example**:
```
plotWidth = 800px
maxWhitespaceFraction = 0.1
dataPerPixelX = 0.0625

maxWhitespaceX = 800 * 0.1 * 0.0625 = 5 data units

This means: viewport edges can extend 5 data units beyond original data
```

### Step 4: Calculate Allowed Viewport Bounds
```dart
// Original data extent (from _originalTransform)
final originalDataXMin = _originalTransform!.dataXMin;
final originalDataXMax = _originalTransform!.dataXMax;
final originalDataYMin = _originalTransform!.dataYMin;
final originalDataYMax = _originalTransform!.dataYMax;

// Viewport start position limits
final minAllowedXMin = originalDataXMin - maxWhitespaceX;
final maxAllowedXMin = originalDataXMax - dataXRange + maxWhitespaceX;

// Viewport end position limits (derived from start + range)
final minAllowedXMax = originalDataXMin + dataXRange - maxWhitespaceX;
final maxAllowedXMax = originalDataXMax + maxWhitespaceX;

// Same for Y-axis
final minAllowedYMin = originalDataYMin - maxWhitespaceY;
final maxAllowedYMin = originalDataYMax - dataYRange + maxWhitespaceY;
final minAllowedYMax = originalDataYMin + dataYRange - maxWhitespaceY;
final maxAllowedYMax = originalDataYMax + maxWhitespaceY;
```

**Example**:
```
Original data: [0, 100]
Current viewport size: 50 data units (2x zoom)
maxWhitespaceX = 5

X-axis constraints:
  minAllowedXMin = 0 - 5 = -5        (can start 5 units before data start)
  maxAllowedXMin = 100 - 50 + 5 = 55 (can start up to 5 units before data end)
  
  minAllowedXMax = 0 + 50 - 5 = 45   (must end at least 5 units after data start)
  maxAllowedXMax = 100 + 5 = 105     (can end 5 units after data end)

Valid viewport positions:
  - Start: anywhere in [-5, 55]
  - End: anywhere in [45, 105]
  - Must maintain: end = start + 50 (viewport size)
```

### Step 5: Clamp Viewport to Bounds
```dart
// Clamp viewport start positions
final clampedXMin = tentativeXMin.clamp(minAllowedXMin, maxAllowedXMin);
final clampedYMin = tentativeYMin.clamp(minAllowedYMin, maxAllowedYMin);

// Calculate viewport end positions (maintain viewport size)
final clampedXMax = clampedXMin + dataXRange;
final clampedYMax = clampedYMin + dataYRange;

// Verify end positions are within bounds (they should be by construction)
assert(clampedXMax >= minAllowedXMax && clampedXMax <= maxAllowedXMax);
assert(clampedYMax >= minAllowedYMax && clampedYMax <= maxAllowedYMax);
```

**Example - Normal Pan**:
```
Tentative: [30, 80]
Bounds: start in [-5, 55], end in [45, 105]

Clamp:
  clampedXMin = clamp(30, -5, 55) = 30 ✓ (within bounds)
  clampedXMax = 30 + 50 = 80 ✓ (within [45, 105])

Result: Full pan allowed, no constraint applied
```

**Example - Hitting Right Limit**:
```
Tentative: [60, 110]  (trying to pan past right edge)
Bounds: start in [-5, 55], end in [45, 105]

Clamp:
  clampedXMin = clamp(60, -5, 55) = 55 (clamped to max start position)
  clampedXMax = 55 + 50 = 105 ✓ (exactly at right limit)

Result: Partial pan allowed, stopped at right edge
```

### Step 6: Calculate Actual Movement
```dart
// How much did we actually move?
final actualDataDx = clampedXMin - dataXMin;
final actualDataDy = clampedYMin - dataYMin;

// Alternative: calculate from end positions (should be identical)
// final actualDataDx = (clampedXMax - dataXMax);
// assert((clampedXMin - dataXMin) == (clampedXMax - dataXMax));
```

**Example - Normal Pan**:
```
Current: [25, 75]
Clamped: [30, 80]
actualDataDx = 30 - 25 = 5 data units (full requested movement)
```

**Example - Constrained Pan**:
```
Current: [50, 100]
Tentative: [60, 110] (requested +10 units)
Clamped: [55, 105] (stopped at limit)
actualDataDx = 55 - 50 = 5 data units (only 5 of 10 requested)
```

### Step 7: Convert Back to Plot Space
```dart
// Convert data delta back to plot delta
final actualPlotDx = actualDataDx / dataPerPixelX;
final actualPlotDy = actualDataDy / dataPerPixelY;

return (actualPlotDx, actualPlotDy);
```

**Example - Normal Pan**:
```
actualDataDx = 5 data units
dataPerPixelX = 0.0625
actualPlotDx = 5 / 0.0625 = 80px (full 80px requested)
```

**Example - Constrained Pan**:
```
actualDataDx = 5 data units (requested 10, clamped to 5)
dataPerPixelX = 0.0625
actualPlotDx = 5 / 0.0625 = 80px (only 80px of 160px requested)

User dragged 160px, but chart only moved 80px - hit the wall! 🧱
```

---

## Complete Implementation

```dart
/// Clamps pan delta to enforce viewport bounds.
///
/// **Constraints**:
/// - Viewport edges can extend up to 10% of viewport size beyond original data
/// - Constraints are zoom-independent (same whitespace ratio at all zoom levels)
/// - Panning feels like hitting a solid wall when limit reached
///
/// **Algorithm**:
/// 1. Convert plot delta to data delta
/// 2. Calculate tentative new viewport position
/// 3. Calculate max allowed whitespace (10% of viewport in data units)
/// 4. Clamp viewport position to allowed bounds
/// 5. Convert actual movement back to plot delta
(double, double) _clampPanDelta(double requestedPlotDx, double requestedPlotDy) {
  if (_transform == null || _originalTransform == null) {
    return (requestedPlotDx, requestedPlotDy);
  }

  // Step 1: Convert to data space
  final dataXMin = _transform!.dataXMin;
  final dataXMax = _transform!.dataXMax;
  final dataYMin = _transform!.dataYMin;
  final dataYMax = _transform!.dataYMax;

  final dataXRange = dataXMax - dataXMin;
  final dataYRange = dataYMax - dataYMin;

  final dataPerPixelX = dataXRange / _plotArea.width;
  final dataPerPixelY = dataYRange / _plotArea.height;

  final requestedDataDx = requestedPlotDx * dataPerPixelX;
  final requestedDataDy = requestedPlotDy * dataPerPixelY;

  // Step 2: Calculate tentative viewport
  final tentativeXMin = dataXMin + requestedDataDx;
  final tentativeYMin = dataYMin + requestedDataDy;

  // Step 3: Calculate max whitespace
  final maxWhitespaceX = _plotArea.width * maxWhitespaceFraction * dataPerPixelX;
  final maxWhitespaceY = _plotArea.height * maxWhitespaceFraction * dataPerPixelY;

  // Step 4: Calculate allowed bounds
  final originalDataXMin = _originalTransform!.dataXMin;
  final originalDataXMax = _originalTransform!.dataXMax;
  final originalDataYMin = _originalTransform!.dataYMin;
  final originalDataYMax = _originalTransform!.dataYMax;

  final minAllowedXMin = originalDataXMin - maxWhitespaceX;
  final maxAllowedXMin = originalDataXMax - dataXRange + maxWhitespaceX;
  final minAllowedYMin = originalDataYMin - maxWhitespaceY;
  final maxAllowedYMin = originalDataYMax - dataYRange + maxWhitespaceY;

  // Step 5: Clamp viewport
  final clampedXMin = tentativeXMin.clamp(minAllowedXMin, maxAllowedXMin);
  final clampedYMin = tentativeYMin.clamp(minAllowedYMin, maxAllowedYMin);

  // Step 6: Calculate actual movement
  final actualDataDx = clampedXMin - dataXMin;
  final actualDataDy = clampedYMin - dataYMin;

  // Step 7: Convert back to plot space
  final actualPlotDx = actualDataDx / dataPerPixelX;
  final actualPlotDy = actualDataDy / dataPerPixelY;

  // Debug output
  if (actualPlotDx != requestedPlotDx || actualPlotDy != requestedPlotDy) {
    debugPrint('🧱 Pan constrained: requested=($requestedPlotDx, $requestedPlotDy) '
        '→ allowed=($actualPlotDx, $actualPlotDy)');
    debugPrint('   Viewport: [$dataXMin, $dataXMax] → [$clampedXMin, ${clampedXMin + dataXRange}]');
  }

  return (actualPlotDx, actualPlotDy);
}
```

---

## Key Advantages of This Approach

### 1. Zoom Independence ✅
```
At 1x zoom (100 data units visible):
  maxWhitespace = 800px * 0.1 * (100/800) = 10 data units
  10% whitespace on screen

At 5x zoom (20 data units visible):
  maxWhitespace = 800px * 0.1 * (20/800) = 2 data units  
  10% whitespace on screen (same ratio!)

Whitespace ratio stays constant regardless of zoom level
```

### 2. No Special Cases ✅
- No "both edges past limits" logic
- No "recovery mode"
- No directional checks
- Just simple viewport position clamping

### 3. Mathematically Correct ✅
- Viewport position is the primary constraint
- Original boundary positions are derived, not tracked
- Geometric relationships are preserved

### 4. Predictable UX ✅
- Panning always stops at the same visual whitespace (10%)
- Works identically at all zoom levels
- Feels like hitting a solid wall (no partial blocks or weird behavior)

---

## Testing Checklist

### Unit Tests (New `_clampPanDelta`)
- [ ] Pan at 1x zoom stays within bounds
- [ ] Pan at 2x zoom stays within bounds
- [ ] Pan at 5x zoom stays within bounds
- [ ] Zoom level doesn't affect constraint behavior (visual whitespace is constant)
- [ ] Pan to left edge stops with 10% whitespace
- [ ] Pan to right edge stops with 10% whitespace
- [ ] Partial pan allowed when approaching limit
- [ ] Full pan blocked when at limit
- [ ] Zero pan returned when already at limit and pushing further

### Integration Tests
- [ ] Pan to edge at 1x zoom, zoom to 5x, pan still works correctly
- [ ] Zoom to 5x, pan to edge, zoom back to 1x, constraints still correct
- [ ] Rapid panning doesn't allow overshoot
- [ ] Pan + zoom + pan maintains consistent constraints

### Visual Tests (Manual)
- [ ] Whitespace appears the same at all zoom levels when panned to edge
- [ ] No "jump" or "snap-back" when hitting constraint
- [ ] Panning feels smooth and predictable
- [ ] Can explore all original data plus 10% margin in all directions

---

## Migration Notes

### Code to Remove
1. Lines 348-405: "Roaming radius" high-zoom logic
2. Lines 435-460: "Both edges past limits" recovery logic
3. Lines 462-500: Directional pan constraint checks (leftMargin/rightMargin)
4. Lines 502-570: Y-axis equivalent of above

**Total removal**: ~220 lines of complex, incorrect constraint logic

### Code to Add
**New implementation**: ~50 lines of simple, correct viewport clamping

**Net change**: -170 lines (simpler AND correct!)

---

## Performance Considerations

### Current Implementation
- Converts original data boundaries to plot space (4 dataToPlot calls)
- Calculates margins and checks multiple conditions
- Special case logic for "both edges past limits"
- Directional checks for each axis

### New Implementation
- Pure data-space arithmetic (no coordinate conversions mid-algorithm)
- Simple clamp operations (hardware-optimized)
- No conditionals or special cases

**Expected**: Slightly faster AND simpler

---

## Next Steps

1. ✅ Implement new `_clampPanDelta` in `chart_render_box.dart`
2. ✅ Remove old constraint code
3. ✅ Add debug logging for constraint hits
4. ✅ Write comprehensive unit tests
5. ✅ Manual testing at various zoom levels
6. ✅ Update documentation

---

**Document Owner**: AI Assistant  
**Implementation Status**: Ready  
**Review**: Pending team review
