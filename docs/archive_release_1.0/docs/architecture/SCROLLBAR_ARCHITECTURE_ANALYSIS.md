# Scrollbar Architecture Analysis & Redesign

**Date**: 2025-10-28  
**Branch**: `010-dual-purpose-scrollbars`  
**Problem**: Scrollbar snap/jump bug on subsequent drags (70% working, 30% failing)  
**Root Cause**: Circular dependency from dual sources of truth  
**Solution**: Pixel-delta pattern eliminating data state from scrollbar

---

## Executive Summary

After analyzing Flutter's core scrollbar architecture and our custom `ChartScrollbar` implementation, we identified that the snap/jump bug stems from a **circular dependency** created by maintaining separate baseline state in the scrollbar. This violates Flutter's design pattern where scrollbars are stateless displays that defer to a controller for position management.

**Recommended Solution**: Refactor to **pixel-delta pattern** where scrollbar reports pixel deltas (not data ranges), and parent converts to data deltas using its own viewport state. This eliminates circular dependencies while preserving all custom features.

---

## 1. Flutter's Standard Pattern Analysis

### 1.1 ScrollController + Scrollbar Architecture

**Source**: Flutter API Documentation  
- `https://api.flutter.dev/flutter/material/Scrollbar-class.html`
- `https://api.flutter.dev/flutter/widgets/ScrollController-class.html`

**Key Principles**:

1. **Single Source of Truth**: `ScrollController` owns scroll position
2. **Stateless Display**: `Scrollbar` is a `StatelessWidget` that reads from controller
3. **Unidirectional Flow**: Gestures → controller.jumpTo()/animateTo() → position update → rebuild
4. **No Circular Dependencies**: Controller notifies listeners, scrollbar rebuilds

**Data Flow**:
```
User drags scrollbar thumb
    ↓
Scrollbar calls controller.jumpTo(newOffset)
    ↓
Controller updates scroll position
    ↓
Controller notifies listeners
    ↓
Scrollbar rebuilds with new position (from controller)
```

**Why This Works**:
- No baseline tracking in scrollbar
- No synchronization issues
- Simple, predictable data flow
- Controller is the single authority on position

---

## 2. Our Current Architecture (Problematic)

### 2.1 ChartScrollbar State Fields

From `lib/src/widgets/chart_scrollbar.dart` (lines 164-176):

```dart
Offset? _dragStartPosition;           // Initial drag position (pixels)
DataRange? _dragStartViewportRange;   // ❌ PROBLEM: Baseline for delta calc
DataRange? _lastSentViewport;         // ❌ PROBLEM: Last sent to parent
DataRange? _lastUnclampedViewport;    // ❌ PROBLEM: Unclamped intent
```

### 2.2 Circular Dependency Flow

```
1. Parent owns viewport state (via zoom/pan)
2. Scrollbar receives viewport as prop (viewportRange)
3. User drags scrollbar (pan or zoom gesture)
4. Scrollbar calculates: newViewport = _dragStartViewportRange + delta
5. Scrollbar sends newViewport to parent via callback
6. Parent updates zoom/pan state
7. Parent calculates viewport from zoom/pan
8. Parent passes NEW viewport back to scrollbar
9. Scrollbar's didUpdateWidget receives new viewport
10. ❌ PROBLEM: Should we update _dragStartViewportRange?
```

**The Sync Problem**:
- If we update baseline → interferes with active drag
- If we DON'T update baseline → baseline becomes stale
- If we guard updates → complex edge case handling
- Result: Four band-aid fixes, 30% of drags still fail

### 2.3 Four Previous Band-Aid Fixes

1. **didUpdateWidget Guard**: Don't update baseline during drag
   - Problem: Baseline stale after drag ends
   
2. **onPanEnd Preservation**: Update baseline when drag completes
   - Problem: Conflicts with prop updates from parent
   
3. **onPanStart Preservation**: Keep old baseline at drag start
   - Problem: Doesn't handle intermediate prop changes
   
4. **Unclamped Tracking**: Track user's intent before clamping
   - Problem: Still has sync issues between intent and reality

**Analysis**: All fixes address **symptoms**, not **root cause**.

---

## 3. Custom Requirements Analysis

### 3.1 Why We Differ from Standard Scrollbars

Our `ChartScrollbar` has unique requirements:

| Feature | Standard Scrollbar | ChartScrollbar |
|---------|-------------------|----------------|
| **Pan** | Drag thumb along track | ✅ Drag center to shift viewport |
| **Zoom** | ❌ Not supported | ✅ Drag edges to resize viewport |
| **Track Click** | ✅ Jump to position | ✅ Jump to position |
| **Keyboard** | ✅ Arrow keys | ✅ Arrow keys + page up/down + home/end |
| **Purpose** | Single-axis scroll | Dual-purpose pan + zoom |
| **Data Type** | Pixel offset | Data range (min/max values) |

### 3.2 Dual-Purpose Interaction Model

```dart
// Pan: Drag center of handle
onPanUpdate: Both min and max shift together
  DataRange(min: 10, max: 20) + delta(+5)
  → DataRange(min: 15, max: 25)

// Zoom: Drag edges of handle  
onEdgeResize: Adjust min OR max independently
  DataRange(min: 10, max: 20) + resizeMax(+5)
  → DataRange(min: 10, max: 25)
```

**Key Insight**: These custom features don't REQUIRE baseline tracking in scrollbar. They require gesture detection (pan vs edge drag) and delta calculation. Delta can be calculated from PIXEL movement, then converted to DATA movement by parent.

---

## 4. Recommended Solution: Pixel-Delta Pattern

### 4.1 Core Principle

**Scrollbar reports PIXEL deltas. Parent converts to DATA deltas.**

This mirrors Flutter's pattern while supporting our custom features.

### 4.2 New Architecture

```
User drags scrollbar
    ↓
Scrollbar calculates PIXEL delta (Offset)
Scrollbar identifies interaction type (pan, zoomLeft, zoomRight)
    ↓
Scrollbar calls: onPixelDeltaChanged(delta: Offset, type: ScrollbarInteraction)
    ↓
Parent receives pixel delta
Parent converts to DATA delta using CURRENT viewport:
  dataDelta = pixelDelta * (dataRange / pixelRange)
    ↓
Parent applies data delta to viewport
Parent updates zoomPanController
    ↓
Parent passes NEW viewport to scrollbar as prop
    ↓
Scrollbar rebuilds with new viewport (no baseline to sync!)
```

### 4.3 Key Changes

**ChartScrollbar**:
- ✅ KEEP: `_dragStartPosition` (pixel tracking for delta calc)
- ❌ REMOVE: `_dragStartViewportRange` (no data baseline)
- ❌ REMOVE: `_lastSentViewport` (no need to track)
- ❌ REMOVE: `_lastUnclampedViewport` (no need to track)
- 🔄 CHANGE: `onViewportChanged(DataRange)` → `onPixelDeltaChanged(Offset, ScrollbarInteraction)`

**BravenChart**:
- 🔄 CHANGE: `_onScrollbarViewportChanged(DataRange)` → `_onScrollbarPixelDelta(Offset, ScrollbarInteraction)`
- ➕ ADD: Pixel-to-data conversion logic using current zoomPanState

### 4.4 Interaction Type Enum

```dart
enum ScrollbarInteraction {
  pan,          // Dragging center of handle
  zoomLeft,     // Dragging left edge
  zoomRight,    // Dragging right edge (or top/bottom for vertical)
  trackClick,   // Clicked track to jump
  keyboard,     // Keyboard navigation
}
```

### 4.5 Pixel-to-Data Conversion Logic

```dart
void _onScrollbarPixelDelta(Offset pixelDelta, ScrollbarInteraction type) {
  // Get current viewport from zoomPanController
  final currentViewport = _zoomPanController?.viewportRange ?? widget.xAxis?.range;
  if (currentViewport == null) return;
  
  // Get scrollbar pixel dimensions
  final scrollbarPixelRange = _calculateScrollbarPixelRange();
  
  // Convert pixel delta to data delta
  final dataRange = currentViewport.max - currentViewport.min;
  final dataDelta = (pixelDelta.dx / scrollbarPixelRange) * dataRange;
  
  // Apply based on interaction type
  DataRange newViewport;
  switch (type) {
    case ScrollbarInteraction.pan:
      // Shift both min and max
      newViewport = DataRange(
        min: currentViewport.min + dataDelta,
        max: currentViewport.max + dataDelta,
      );
      break;
      
    case ScrollbarInteraction.zoomLeft:
      // Adjust min only
      newViewport = DataRange(
        min: currentViewport.min + dataDelta,
        max: currentViewport.max,
      );
      break;
      
    case ScrollbarInteraction.zoomRight:
      // Adjust max only
      newViewport = DataRange(
        min: currentViewport.min,
        max: currentViewport.max + dataDelta,
      );
      break;
      
    // ... track click and keyboard cases
  }
  
  // Clamp to data bounds
  newViewport = _clampViewport(newViewport);
  
  // Update zoomPanController
  _zoomPanController?.setViewportRange(newViewport);
}
```

---

## 5. Benefits of Pixel-Delta Pattern

### 5.1 Eliminates Root Cause

✅ **No Circular Dependency**: Parent is single source of truth for viewport  
✅ **No Baseline Sync**: Scrollbar doesn't store data state  
✅ **No Band-Aid Fixes**: Remove all four previous workarounds  
✅ **Simple Data Flow**: Unidirectional like Flutter's pattern  

### 5.2 Preserves All Custom Features

✅ **Pan**: Pixel delta with type=pan → shift both min/max  
✅ **Zoom**: Pixel delta with type=zoomLeft/Right → adjust one edge  
✅ **Track Click**: Calculate pixel offset → convert to data position  
✅ **Keyboard**: Generate synthetic pixel deltas for each key  

### 5.3 Code Simplification

**Lines Removed** (~100 lines):
- Remove 3 state fields
- Remove didUpdateWidget baseline logic
- Remove onPanEnd/Start preservation
- Remove unclamped viewport tracking

**Lines Added** (~50 lines):
- Add pixel-to-data conversion in parent
- Add ScrollbarInteraction enum

**Net Change**: ~50 lines removed, simpler architecture

---

## 6. Edge Cases & Validation

### 6.1 Boundary Conditions

**Scenario**: Drag to data range limit (min or max)

**Current Behavior**: Scrollbar baseline gets out of sync, next drag jumps  
**New Behavior**: Parent clamps viewport, passes clamped value to scrollbar, no baseline to desync

### 6.2 Consecutive Drags

**Scenario**: Drag 1 → release → Drag 2 → release → Drag 3

**Current Behavior**: 70% work, 30% snap/jump on Drag 2 or 3  
**New Behavior**: Each drag starts fresh with current pixel position, no accumulated errors

### 6.3 Rapid Zoom/Pan Switching

**Scenario**: Zoom in (edge drag) → Pan (center drag) → Zoom out

**Current Behavior**: Baseline confusion between zoom and pan modes  
**New Behavior**: Each interaction reports pixel delta + type, parent handles independently

---

## 7. Implementation Roadmap

### Phase 1: Refactor ChartScrollbar (Task 6)
1. Remove `_dragStartViewportRange`, `_lastSentViewport`, `_lastUnclampedViewport`
2. Change callback signature: `onPixelDeltaChanged(Offset delta, ScrollbarInteraction type)`
3. Update `_onPanUpdate` to report pixel deltas instead of calculating data viewports
4. Update `_onPanStart` to only track pixel position (not data baseline)
5. Remove all four band-aid fixes (didUpdateWidget guards, preservation logic)

### Phase 2: Update BravenChart (Task 7)
1. Rename `_onScrollbarViewportChanged` → `_onScrollbarPixelDelta`
2. Implement pixel-to-data conversion logic
3. Add ScrollbarInteraction enum handling
4. Test with zoomPanController integration

### Phase 3: Testing (Task 8)
1. Unit tests: Pixel-to-data conversion math
2. Widget tests: Pan gestures (consecutive drags)
3. Widget tests: Zoom gestures (edge resize)
4. Integration tests: Track click, keyboard navigation
5. Edge case tests: Boundary clamping, rapid interaction switching

---

## 8. Success Criteria

### 8.1 Functional Requirements

✅ 100% of scrollbar drags work smoothly (currently 70%)  
✅ No snap/jump on consecutive drags  
✅ Boundary clamping works without position jumps  
✅ Pan (center drag) shifts viewport  
✅ Zoom (edge drag) resizes viewport  
✅ Track click jumps to position  
✅ Keyboard navigation works (arrows, page, home/end)  

### 8.2 Code Quality

✅ Remove ~100 lines of sync logic  
✅ Eliminate circular dependency  
✅ Follow Flutter's design pattern  
✅ Clear separation of concerns (pixel vs data)  
✅ No band-aid fixes  

### 8.3 Performance

✅ 60fps during scrollbar drag  
✅ No jank from pixel-to-data conversion  
✅ ValueNotifier pattern for smooth updates  

---

## 9. Conclusion

The scrollbar snap bug is NOT a problem with baseline tracking itself, but with **maintaining dual sources of truth** (parent viewport + scrollbar baseline). This creates a circular dependency that's impossible to synchronize perfectly.

**Solution**: Adopt Flutter's proven pattern with our custom twist:
- Scrollbar: Stateless for data, reports pixel deltas + interaction type
- Parent: Owns all data state, converts pixel deltas to data deltas
- Result: No circular dependencies, simple data flow, all features preserved

**Next Step**: Implement pixel-delta pattern (Tasks 6-8) and test thoroughly.

---

## References

- Flutter Scrollbar API: https://api.flutter.dev/flutter/material/Scrollbar-class.html
- Flutter ScrollController API: https://api.flutter.dev/flutter/widgets/ScrollController-class.html
- ChartScrollbar Source: `lib/src/widgets/chart_scrollbar.dart`
- BravenChart Integration: `lib/src/widgets/braven_chart.dart` (lines 3376-3446)
