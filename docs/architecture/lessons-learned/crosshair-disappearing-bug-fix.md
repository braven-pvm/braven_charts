# Crosshair Disappearing Bug - Root Cause Analysis & Fix

**Date**: 2025-01-09  
**Issue**: Crosshair completely disappears when hovering near data points  
**Status**: ✅ RESOLVED

## Problem Description

### User Report
"The crosshair completely disappears when you get close to a data point, like when the snapping wants to engage."

### Symptoms
1. **Original Bug**: Crosshair (vertical/horizontal lines) would vanish when hovering near data points in snap mode
2. **Secondary Issue**: In the "Interaction System Showcase" screen, the crosshair would flicker/disappear at certain coordinates (e.g., X=27, Y=408) when multiple series were present

## Root Cause Analysis

### Primary Cause: Coordinate System Mismatch
The `_CrosshairPainter` was receiving **data coordinates** instead of **screen coordinates** for the `nearestPoint` parameter used to render the snap-to-point highlight circle.

**Why this caused disappearance:**
- When snap-to-point engaged, the painter received data coordinates (e.g., x=27, y=408)
- These were interpreted as **pixel offsets** on the canvas
- For data with large values (y=408), the highlight circle rendered far outside the visible canvas bounds
- Flutter's rendering system may have optimized away the entire CustomPaint when all drawing operations were out of bounds

### Secondary Cause: Widget State Reset During Parent Rebuilds
In the "Interaction System Showcase" screen, the crosshair would disappear intermittently due to:

**Issue**: Parent widget rebuilds (triggered by callback logging) causing the chart widget to lose state

**Mechanism**:
1. User hovers → `onCrosshairChanged` callback fires
2. Callback calls `_logEvent()` which triggers `setState()` in parent widget
3. Parent rebuilds, recreating `BravenChart` widget without a key
4. Without a key, Flutter creates a **new** widget instance instead of updating existing one
5. New widget instance has fresh internal state (`_BravenChartState`)
6. Crosshair state (`_interactionState`) is lost during the transition
7. Crosshair disappears until next hover event

## Solution Implementation

### Fix 1: Store Screen Coordinates in Metadata
**File**: `lib/src/widgets/braven_chart.dart` (lines 1389-1407)

```dart
Map<String, dynamic>? _findNearestDataPoint(Offset screenPosition) {
  // ... existing code ...
  
  nearestPoint = {
    'seriesId': series.id,
    'x': point.x,
    'y': point.y,
    'screenX': screenPoint.dx,  // ← ADD: Store screen coordinates
    'screenY': screenPoint.dy,  // ← ADD: Store screen coordinates
    if (point.metadata != null) ...point.metadata!,
  };
}
```

**Rationale**: Store both data coordinates (for tooltips/callbacks) and screen coordinates (for rendering) in the metadata.

### Fix 2: Use Screen Coordinates in Crosshair Painter
**File**: `lib/src/widgets/braven_chart.dart` (lines 947-970)

```dart
nearestPoint: _interactionState.hoveredPoint != null &&
        _interactionState.hoveredPoint!.containsKey('screenX') &&
        _interactionState.hoveredPoint!.containsKey('screenY')
    ? () {
        final screenX = (_interactionState.hoveredPoint!['screenX'] as num?)?.toDouble() ?? 0;
        final screenY = (_interactionState.hoveredPoint!['screenY'] as num?)?.toDouble() ?? 0;
        // Validate coordinates are finite (not NaN/infinity)
        if (screenX.isFinite && screenY.isFinite) {
          return Offset(screenX, screenY);
        }
        return null;
      }()
    : null,
```

**Rationale**: Extract screen coordinates from metadata and validate they're finite before creating the Offset.

### Fix 3: Add Coordinate Validation Guards
**Multiple locations in `braven_chart.dart`**:

1. **In `_findNearestDataPoint`** (lines 1395-1396):
   ```dart
   if (!screenPoint.dx.isFinite || !screenPoint.dy.isFinite) {
     continue;  // Skip invalid coordinates
   }
   ```

2. **In crosshair build** (lines 947-951):
   ```dart
   if (config.crosshair.enabled && 
       _interactionState.isCrosshairVisible &&
       _interactionState.crosshairPosition != null &&
       _interactionState.crosshairPosition!.dx.isFinite &&
       _interactionState.crosshairPosition!.dy.isFinite)
   ```

3. **In `_CrosshairPainter.paint`** (line 2462):
   ```dart
   if (nearestPoint!.dx.isFinite && nearestPoint!.dy.isFinite) {
     // Draw snap highlight circle
   }
   ```

**Rationale**: Prevent rendering glitches from NaN or infinity values that could occur during coordinate transformations.

### Fix 4: Add Widget Key to Preserve State
**File**: `example/lib/screens/interaction_showcase_screen.dart` (line 297)

```dart
BravenChart(
  key: const ValueKey('interaction_showcase_chart'),  // ← ADD: Preserve state across rebuilds
  chartType: ChartType.line,
  // ...
)
```

**Rationale**: When the parent widget rebuilds (due to callback-triggered setState), Flutter uses the key to **update** the existing widget instance rather than creating a new one, preserving the internal `_interactionState`.

### Fix 5: Avoid Build-Time Size Access
**File**: `lib/src/widgets/braven_chart.dart` (line 968)

```dart
chartSize: Size.infinite,  // ← CORRECT: Use Size.infinite, not context.size
```

**Rationale**: Accessing `context.size` during the build phase violates Flutter's build/layout separation and causes "Cannot get size during build" errors. `Size.infinite` works fine because the CustomPaint is wrapped in `Positioned.fill` which provides the actual canvas size in the paint callback.

## Testing

### Integration Test Suite
Created comprehensive test suite: `test/integration/interaction/crosshair_integration_test.dart`

**Test Coverage**:
1. ✅ Crosshair appears on hover and remains visible during snap
2. ✅ Crosshair uses correct screen coordinates for snap point highlight
3. ✅ Crosshair renders in all three modes correctly (vertical, horizontal, both)
4. ✅ Crosshair snaps to nearest point within snap radius
5. ✅ Crosshair disappears when mouse leaves chart area

**Results**: 5/5 tests passing

### Manual Testing
- ✅ Single series charts: Crosshair remains visible at all coordinates
- ✅ Multiple series charts: Crosshair remains visible when switching between series
- ✅ Edge coordinates: Crosshair renders correctly near chart boundaries
- ✅ Interaction Showcase screen: No flickering or disappearing with callback-triggered rebuilds

## Lessons Learned

### 1. Coordinate System Clarity is Critical
**Lesson**: Always explicitly distinguish between data coordinates and screen coordinates in variable names, documentation, and metadata.

**Best Practice**:
- Use `dataX`, `dataY` for data space coordinates
- Use `screenX`, `screenY` or `pixelX`, `pixelY` for screen space coordinates
- Document which coordinate system each parameter expects

### 2. Widget Keys for Stateful Widgets in Rebuilding Parents
**Lesson**: Stateful widgets that maintain important UI state (like interaction state) should have explicit keys when their parent widgets rebuild frequently.

**Best Practice**:
- Add `const ValueKey()` or `GlobalKey()` to stateful widgets with important internal state
- Especially important when parent has callbacks that trigger setState

### 3. Validate Coordinates Before Rendering
**Lesson**: Coordinate transformations can produce NaN or infinity values. Always validate with `isFinite` before using in rendering operations.

**Best Practice**:
```dart
if (coordinate.dx.isFinite && coordinate.dy.isFinite) {
  // Safe to use for rendering
}
```

### 4. Flutter Build/Layout/Paint Separation
**Lesson**: `context.size` is only available after layout completes (in paint callbacks or gesture handlers), never during the build phase.

**Best Practice**:
- For CustomPaint size info, use the `size` parameter in the `paint` callback
- If you need size during build, wrap in `LayoutBuilder`
- For overlay widgets like Positioned.fill, use `Size.infinite` in the constructor

### 5. Debugging Widget Disappearance
**When widgets mysteriously disappear, check:**
1. ✅ Are coordinates valid (not NaN/infinity)?
2. ✅ Are coordinates in the visible range?
3. ✅ Is the widget actually being built? (check conditional rendering)
4. ✅ Is widget state being preserved across parent rebuilds?
5. ✅ Are there layout errors being swallowed?

## Performance Impact

**Positive**: The fixes add minimal overhead
- Coordinate validation: O(1) per point, very fast
- Widget key: No performance cost, improves efficiency by avoiding unnecessary widget recreation
- Screen coordinate storage: ~16 bytes per data point (2 doubles)

**No Negative Impact**: All changes are defensive checks and metadata additions with negligible performance cost.

## Related Files Modified

1. `lib/src/widgets/braven_chart.dart` - Core fixes (coordinate handling, validation)
2. `example/lib/screens/interaction_showcase_screen.dart` - Added widget key
3. `test/integration/interaction/crosshair_integration_test.dart` - New test suite

## Future Improvements

1. **Type Safety**: Consider creating a `ScreenCoordinate` and `DataCoordinate` class to prevent coordinate system confusion at compile time
2. **Performance**: For very large datasets (>10k points), consider spatial indexing for nearest-point lookup
3. **Documentation**: Add coordinate system diagrams to developer documentation
4. **Linting**: Create custom lint rule to detect coordinate system mismatches

## Conclusion

This bug demonstrated the importance of:
- Clear separation between coordinate systems
- Defensive validation of numerical values
- Proper widget lifecycle management in Flutter
- Comprehensive integration testing for interaction features

The fix ensures crosshair functionality remains robust across all chart types, data ranges, and usage scenarios.
