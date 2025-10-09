# Line Continuity Bug Analysis

**Date**: 2025-01-09  
**Status**: 🐛 **BUG CONFIRMED** - Root cause identified, fix in progress

---

## Executive Summary

**Critical Bug Discovered**: Point culling in `_drawLineSeries()` breaks line continuity during zoom/pan operations.

**Impact**: Line charts display incorrect curve shapes when zoomed or panned, not just a cropped viewport.

**Root Cause**: The rendering code uses `continue` to skip data points outside the visible viewport, which creates line segments that connect non-consecutive points, fundamentally altering the line's shape.

**Solution**: Replace point culling with Canvas clipping to maintain all line segments while only displaying the visible viewport.

---

## Test Evidence

### Test File
`integration_test/line_continuity_test.dart`

### Test Data
- **Dataset**: 20-point sine wave curve (smooth continuous function)
- **Expected**: Line shape remains identical at all zoom levels (only viewport changes)
- **Actual**: Line shape changes as points get culled

### Screenshot Analysis

| Screenshot | File Size | Status | Notes |
|-----------|-----------|---------|-------|
| `line_continuity_baseline.png` | 48,923 bytes | ✅ Correct shape | Full curve visible |
| `line_continuity_zoom1.png` | 39,501 bytes | ✅ Shape maintained | Smaller file = less visible area (expected) |
| `line_continuity_zoom2.png` | 35,332 bytes | ✅ Shape maintained | Even less visible area (expected) |
| `line_continuity_zoom3.png` | 32,619 bytes | ✅ Shape maintained | Maximum zoom (expected) |

**IMPORTANT CLARIFICATION**: File size reduction during zoom is EXPECTED and NORMAL behavior. When zooming in, less of the curve is visible, so PNG compression results in smaller files (fewer pixels contain line data). This is NOT evidence of a bug.

**The REAL bug**: Line shape changing (curve flattening, missing segments between visible points). This is caused by point culling creating line segments that skip over culled points.

**File Size Pattern Analysis** (REVISED):
- Before fix: Progressive reduction 49KB → 39KB → 33KB → 33KB was due to BOTH fewer visible points AND Canvas clipping
- After fix: Similar pattern 49KB → 40KB → 35KB → 33KB is due ONLY to Canvas clipping (less visible area)
- The key difference is in the LINE SHAPE, not file size

### Debug Output Evidence

```
Total Visible Points: 19 / 20
```

Console output shows that the culling logic is actively removing points:
```
Point (12, 81.2): CULLED
```

Even a single culled point can break line continuity if it's between two visible points.

---

## Technical Root Cause

### Current Implementation (BROKEN)

**Location**: `lib/src/braven_chart.dart`, `_drawLineSeries()` method (~line 1870)

```dart
for (final point in s.points) {
  // ❌ THIS IS THE BUG:
  if (point.x < bounds.minX || point.x > bounds.maxX ||
      point.y < bounds.minY || point.y > bounds.maxY) {
    continue; // Skips this point entirely
  }
  
  final offset = Offset(
    chartRect.left + (point.x - bounds.minX) / (bounds.maxX - bounds.minX) * chartRect.width,
    chartRect.bottom - (point.y - bounds.minY) / (bounds.maxY - bounds.minY) * chartRect.height,
  );
  
  if (path.isEmpty) {
    path.moveTo(offset.dx, offset.dy);
  } else {
    path.lineTo(offset.dx, offset.dy);
  }
}
```

### Why This Breaks

**Example Scenario**:
```
Data Points: [A, B, C, D, E, F]
Viewport: Shows only [B, C, D, E]

Current Code (BROKEN):
  Point A: Outside viewport → SKIP (continue)
  Point B: Inside viewport → moveTo(B)
  Point C: Inside viewport → lineTo(C)
  Point D: Inside viewport → lineTo(D)
  Point E: Inside viewport → lineTo(E)
  Point F: Outside viewport → SKIP (continue)

Result: Line only connects B→C→D→E
Missing: A→B and E→F segments are NOT rendered
Impact: The line curve is WRONG - it doesn't show the entry/exit tangents
```

**Visual Impact**:
- Lines appear to "start from nowhere" at viewport edges
- Curve slope is wrong at boundaries
- Smooth curves become jagged or flattened
- Bezier curves lose their shape entirely

---

## Correct Solution: Canvas Clipping

### Proposed Implementation

```dart
// Add before drawing the line:
canvas.save();
canvas.clipRect(chartRect); // Only this rectangle will be visible

// Draw ALL points (no culling):
for (final point in s.points) {
  final offset = Offset(
    chartRect.left + (point.x - bounds.minX) / (bounds.maxX - bounds.minX) * chartRect.width,
    chartRect.bottom - (point.y - bounds.minY) / (bounds.maxY - bounds.minY) * chartRect.height,
  );
  
  if (path.isEmpty) {
    path.moveTo(offset.dx, offset.dy);
  } else {
    path.lineTo(offset.dx, offset.dy);
  }
}

canvas.drawPath(path, paint);
canvas.restore(); // Remove clipping
```

### Why This Works

**Same Scenario with Canvas Clipping**:
```
Data Points: [A, B, C, D, E, F]
Viewport: Shows only [B, C, D, E]

New Code (FIXED):
  Process ALL points:
    Point A: Outside → Still rendered (lineTo outside chartRect)
    Point B: Inside → lineTo(B)
    Point C: Inside → lineTo(C)
    Point D: Inside → lineTo(D)
    Point E: Inside → lineTo(E)
    Point F: Outside → Still rendered (lineTo outside chartRect)

  Canvas.clipRect() automatically clips the path:
    - A→B segment is partially visible (shows B endpoint correctly)
    - B→C→D→E fully visible
    - E→F segment is partially visible (shows E endpoint correctly)

Result: Perfect line shape with correct entry/exit angles!
```

---

## Performance Considerations

### Concern
Processing all points instead of culling might be slower for large datasets.

### Analysis
1. **Canvas clipping is hardware-accelerated** - GPU handles the clipping efficiently
2. **Path building is already O(n)** - we're just removing one conditional check
3. **Typical datasets**: Line charts rarely have >10,000 points visible at once
4. **Optimization opportunity**: Can still cull points that are MANY screen widths away (e.g., >2x viewport width)

### Benchmarking Plan
After implementing the fix:
1. Test with 100, 1,000, 10,000, and 100,000 point datasets
2. Measure frame render times
3. Compare with/without aggressive culling (e.g., 2x viewport margin)
4. Document performance characteristics

---

## Implementation Checklist

### Phase 1: Fix the Bug ✅ COMPLETE
- [x] Create test to prove bug exists (`line_continuity_test.dart`)
- [x] Capture before-fix screenshots
- [x] Analyze file sizes and debug output
- [x] Modify `_drawLineSeries()` to use Canvas clipping
- [x] Remove point culling `continue` statement
- [x] Add `canvas.save()` / `clipRect()` / `restore()`
- [x] Modify `_drawAreaSeries()` to use Canvas clipping (same issue)
- [x] Run test again to capture after-fix screenshots
- [x] Verify line continuity maintained (visual inspection)
- [x] Remove all debug print statements

### Phase 2: Verify Across Chart Types ✅ COMPLETE
- [x] Line charts - FIXED (Canvas clipping implemented)
- [x] Area charts - FIXED (Canvas clipping implemented)
- [x] Scatter plots - OK (markers only, no continuity issue)
- [x] Bar charts - OK (discrete bars, culling is fine)

### Phase 3: Performance Validation ⏳ DEFERRED
- [ ] Benchmark with 10,000 points
- [ ] Benchmark with 100,000 points
- [ ] Profile GPU usage
- [ ] Implement smart culling if needed (>2x viewport margin)

**Note**: Performance testing deferred until more critical features are complete. Canvas clipping is hardware-accelerated and should handle typical datasets (< 10,000 points) efficiently.

### Phase 4: Cleanup ✅ COMPLETE
- [x] Remove all debug print statements from `_calculateDataBounds()`
- [x] Remove unused variables (`origMinX`, `origMaxX`, `origMinY`, `origMaxY`)
- [x] Update documentation (this file)
- [x] Test passes without debug output

---

## Lessons Learned

### Design Principle Violated
**"Optimize rendering, not data"** - We should have clipped the viewport, not the data.

### Why This Bug Persisted
1. Initial testing probably used bar charts or scatter plots where culling works fine
2. Line charts need special handling for continuity
3. Debug output focused on coordinate math, not rendering pipeline
4. Screenshots without side-by-side comparison can hide subtle shape changes

### Prevention Strategy
1. **Test with continuous functions** (sine, exponential, etc.) that have obvious shapes
2. **Visual regression testing** - compare screenshots pixel-by-pixel
3. **File size monitoring** - sudden drops indicate data loss
4. **Render ALL points in debug mode** - make culling opt-in, not default

---

## References

### Related Files
- `lib/src/braven_chart.dart` - Main chart painter (bug location ~line 1870)
- `integration_test/line_continuity_test.dart` - Test proving the bug
- `integration_test/keyboard_zoom_incremental_test.dart` - Original evidence (file size drops)

### Canvas API Documentation
- [Flutter Canvas.clipRect()](https://api.flutter.dev/flutter/dart-ui/Canvas/clipRect.html)
- [Flutter Canvas.save()](https://api.flutter.dev/flutter/dart-ui/Canvas/save.html)
- [Flutter Canvas.restore()](https://api.flutter.dev/flutter/dart-ui/Canvas/restore.html)

---

## Next Steps

1. ✅ **DONE**: Create test and prove bug exists
2. 🔄 **IN PROGRESS**: Implement Canvas clipping fix
3. ⏳ **PENDING**: Verify fix with screenshots
4. ⏳ **PENDING**: Performance testing
5. ⏳ **PENDING**: Cleanup and documentation

---

**Status**: Ready to implement the fix. All evidence collected, root cause confirmed, solution designed.
