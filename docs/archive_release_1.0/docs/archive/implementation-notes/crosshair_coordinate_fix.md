# Crosshair Coordinate Alignment Fix

## Issue

The crosshair and tooltip markers were appearing at incorrect positions - offset from the actual data points on the chart. This was particularly noticeable when zooming or panning the chart.

## Root Cause

The bug was caused by a mismatch between two coordinate transformation systems:

1. **Chart Painter's `_calculateDataBounds()`**: This method correctly applied zoom/pan transformations to calculate the visible data bounds.

2. **Widget's `_calculateDataBounds()`**: This method was used by `_findNearestDataPoint()` to transform data coordinates to screen coordinates for the crosshair/tooltip positioning. **It did NOT apply zoom/pan transformations**.

### The Problem

When a user zoomed or panned:
- The chart would render using the **zoomed/panned bounds** (correct)
- The crosshair/tooltip would calculate screen positions using the **original unzoomed bounds** (incorrect)

This created a coordinate mismatch where the crosshair appeared offset from the actual data point positions.

## Technical Details

### Before (Broken)

```dart
// Widget's _calculateDataBounds - NO zoom/pan handling
_DataBounds _calculateDataBounds(List<ChartSeries> series) {
  // ... calculate minX, maxX, minY, maxY ...
  
  // Simple padding
  final xPadding = (maxX - minX) * 0.1;
  final yPadding = (maxY - minY) * 0.1;
  
  return _DataBounds(
    minX: minX - xPadding,
    maxX: maxX + xPadding,
    minY: minY - yPadding,
    maxY: maxY + yPadding,
  );
}
```

### After (Fixed)

```dart
// Widget's _calculateDataBounds - WITH zoom/pan handling (matches painter)
_DataBounds _calculateDataBounds(List<ChartSeries> series) {
  // ... calculate minX, maxX, minY, maxY ...
  
  // Store original data range BEFORE padding
  final dataMinX = minX;
  final dataMaxX = maxX;
  final dataMinY = minY;
  final dataMaxY = maxY;
  
  // Add padding
  final yRange = maxY - minY;
  minY -= yRange * 0.1;
  maxY += yRange * 0.1;
  
  // Apply zoom/pan transformation if active
  final zoomPanState = _interactionState.zoomPanState;
  if (zoomX != 1.0 || zoomY != 1.0 || panX != 0.0 || panY != 0.0) {
    // Calculate center from ORIGINAL data range
    final centerX = (dataMinX + dataMaxX) / 2;
    final centerY = (dataMinY + dataMaxY) / 2;
    
    // Calculate zoomed range
    final dataRangeX = dataMaxX - dataMinX;
    final dataRangeY = dataMaxY - dataMinY;
    final rangeX = dataRangeX / zoomX;
    final rangeY = dataRangeY / zoomY;
    
    // Convert pan offset from pixels to data units
    final chartRect = _calculateChartRect(context.size!);
    final panDataX = -panX * (dataRangeX / chartRect.width);
    final panDataY = panY * (dataRangeY / chartRect.height);
    
    // Calculate visible bounds
    minX = centerX - rangeX / 2 + panDataX;
    maxX = centerX + rangeX / 2 + panDataX;
    minY = centerY - rangeY / 2 + panDataY;
    maxY = centerY + rangeY / 2 + panDataY;
  }
  
  return _DataBounds(minX: minX, maxX: maxX, minY: minY, maxY: maxY);
}
```

## Code Flow

### Crosshair Position Calculation

1. **User hovers over chart** → `onPointerMove` or `onPointerHover` event
2. **Find nearest point**: `_findNearestDataPoint(screenPosition)` is called
3. **Get chart bounds**: Calls widget's `_calculateDataBounds()` ← **THIS NEEDED THE FIX**
4. **Transform coordinates**: `_dataToScreenPoint(point, chartRect, bounds)` converts data → screen
5. **Store position**: Sets `screenX` and `screenY` in `hoveredPoint` map
6. **Render crosshair**: `_CrosshairPainter` uses `screenX`/`screenY` to draw marker

### Chart Rendering

1. **Paint chart**: `_BravenChartPainter.paint()` is called
2. **Get chart bounds**: Calls painter's `_calculateDataBounds()` ← Already had zoom/pan
3. **Draw series**: `_drawLineSeries()`, `_drawAreaSeries()` use these bounds
4. **Transform points**: `_dataToPixel(point, chartRect, bounds)` converts data → screen

## The Fix

Made the widget's `_calculateDataBounds()` method **identical** to the painter's version by:

1. Storing original data range before padding
2. Calculating zoom center from original data (not padded)
3. Calculating zoomed range from original data
4. Converting pan offset from pixels to data units
5. Applying zoom/pan transformations to visible bounds

This ensures both the chart rendering AND the crosshair/tooltip positioning use the **same coordinate system**.

## Testing

### Visual Verification

1. **No Zoom/Pan**: Crosshair should align perfectly with data points ✅
2. **After Zoom In**: Crosshair should stay aligned with data points ✅
3. **After Pan**: Crosshair should stay aligned with data points ✅
4. **After Zoom + Pan**: Crosshair should stay aligned with data points ✅

### Test Cases

The fix affects these interaction scenarios:
- Hover over data points (desktop/web)
- Tap on data points (mobile)
- Crosshair snapping to nearest point
- Tooltip positioning at data points
- All chart types (line, area, scatter, bar)

## Files Modified

- `lib/src/widgets/braven_chart.dart` (~50 lines changed)
  - Updated `_calculateDataBounds()` method in widget state class
  - Added zoom/pan transformation logic matching the painter's implementation

## Impact

- **Fixes**: Crosshair/tooltip misalignment at all zoom/pan levels
- **No Breaking Changes**: API remains unchanged
- **Performance**: No impact (same calculations, just in correct place)
- **Related Bugs**: None - this is an isolated coordinate transformation issue

## Related Issues

This fix is separate from the previous zoom/pan bug fixes:
- Previous fixes addressed line continuity and data disappearance during zoom
- This fix addresses coordinate alignment for interactive overlays (crosshair/tooltip)
- Both sets of fixes work together to provide correct zoom/pan behavior

---

**Date Fixed**: 2025-10-09  
**Severity**: Medium (visual/UX issue, doesn't affect data or functionality)  
**Resolution**: Coordinate system consistency between painter and widget state
