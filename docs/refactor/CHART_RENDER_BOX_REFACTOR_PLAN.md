# ChartRenderBox Refactoring Plan

## Overview

This document outlines the detailed plan for refactoring `ChartRenderBox` (6,652 lines) into smaller, more manageable modules while preserving the existing public API.

**Date Created**: 2025-12-05
**Last Updated**: 2025-12-06
**Status**: In Progress
**Branch**: render-refactor
**Backup Location**: `lib/src/rendering/chart_render_box.dart.backup`

## Progress Summary

| Module | Status | Lines | Commit | Complexity |
|--------|--------|-------|--------|------------|
| SeriesCacheManager | ✅ Complete | 170 | 876a479 | LOW |
| TooltipAnimator | ✅ Complete | 168 | c19e96c | LOW |
| ViewportConstraints | ✅ Complete | 190 | 7ef6396 | LOW |
| CrosshairRenderer | ⏳ Pending | ~400 | - | MEDIUM |
| ScrollbarManager | ⏳ Pending | ~700 | - | MEDIUM-HIGH |
| StreamingManager | ⏳ Pending | ~500 | - | HIGH |
| AnnotationInteractionHandler | ⏳ Pending | ~800 | - | HIGH |
| EventDispatcher | ⏳ Pending | ~1300 | - | HIGHEST |

**Current ChartRenderBox Size**: 6,302 lines (reduced from 6,652)
**Lines Extracted**: 350 lines (net reduction after integration code)
**New Module Lines**: 528 lines (SeriesCacheManager: 170, TooltipAnimator: 168, ViewportConstraints: 190)

---

## Detailed Complexity Analysis (Updated 2025-12-06)

### 1. CrosshairRenderer - MEDIUM Complexity

**Lines**: ~400 (lines 5200-5620)

**Methods to Extract**:
- `_drawCrosshairLabels()` (~120 lines) - X/Y label positioning and rendering
- `_drawPerAxisCrosshairLabels()` (~135 lines) - Multi-axis label rendering
- `_drawTrackingModeOverlay()` (~165 lines) - Crosshair lines, markers, tooltips

**Dependencies**:
- READ: `_plotArea`, `_transform`, `_theme`, `_cursorPosition`
- READ: `_getEffectiveYAxes()`, `_computeAxisWidths()`, `_computeAxisBounds()`
- READ: `_normalizationMode`, `_xAxis`, `_yAxis`
- WRITE: None (pure rendering)

**Impact Assessment**:
- ✅ No state mutation - safe extraction
- ⚠️ Depends on multi-axis helper methods (must pass as parameters or callback)
- ✅ Well-isolated in paint cycle
- ⚠️ Label positioning requires axis width calculations

**Extraction Strategy**:
1. Pass `ChartTransform`, `Rect plotArea`, `ChartTheme` as params
2. Pass multi-axis config via `MultiAxisInfo` data class
3. Return drawing commands or paint directly on canvas

**Risk Level**: LOW-MEDIUM

---

### 2. ScrollbarManager - MEDIUM-HIGH Complexity

**Lines**: ~700 (spread across multiple sections)

**State Fields** (~50 lines, 249-302):
- `_showXScrollbar`, `_showYScrollbar` - visibility flags
- `_scrollbarTheme` - configuration
- `_xScrollbarRect`, `_yScrollbarRect` - layout rects
- `_activeScrollbarAxis` - which axis is being dragged
- `_scrollbarDragStartPosition`, `_scrollbarDragStartZone` - drag state
- `_xScrollbarHoverZone`, `_yScrollbarHoverZone` - hover feedback
- `_scrollbarAutoHideTimer`, `_scrollbarsVisible` - auto-hide logic

**Methods to Extract**:
- `_hitTestScrollbars()` (~60 lines, 4458-4517) - hit testing
- `_handleScrollbarDrag()` (~200 lines, 4581-4779) - drag interaction
- `_paintScrollbars()` (~170 lines, 4779-4950) - rendering
- `_handleXScrollbarDelta()` (~90 lines) - X axis viewport changes
- `_handleYScrollbarDelta()` (~90 lines) - Y axis viewport changes
- Auto-hide timer management (~30 lines)

**Dependencies**:
- READ: `_transform`, `_originalTransform`, `_streamingBounds`
- READ: `_plotArea`, `coordinator`
- WRITE: `_transform` (via delta handlers)
- WRITE: `_activeScrollbarAxis`, hover zones, timer

**Impact Assessment**:
- ⚠️ Modifies `_transform` - requires callback to apply viewport changes
- ⚠️ Complex state machine (idle → hover → drag → release)
- ⚠️ Timer management requires careful disposal
- ✅ Already uses separate `ScrollbarPainter` and `ScrollbarController`
- ✅ Scrollbar rendering is well-isolated

**Extraction Strategy**:
1. Create `ScrollbarManager` class with own state
2. Inject `ViewportDelegate` callback for transform updates
3. Manager handles all hit testing, drag state, auto-hide internally
4. ChartRenderBox calls `manager.paint()`, `manager.handleEvent()`

**Risk Level**: MEDIUM

---

### 3. StreamingManager - HIGH Complexity

**Lines**: ~500 (lines 1260-1500+)

**State Fields**:
- `_streamingBuffers` - Map<String, StreamingBuffer> (zero-copy refs)
- `_streamingElements` - Map<String, SeriesElement> (cached elements)
- `_streamingBounds` - DataBounds (full data range)
- `_viewportLockedForPause` - pause mode flag
- `_autoScrollTargetXMax`, `_autoScrollTargetWidth` - X animation targets
- `_expansionTargetYMin`, `_expansionTargetYMax` - Y animation targets
- `_autoScrollAnimationScheduled` - animation frame flag

**Methods to Extract**:
- `setStreamingData()` (~150 lines) - main entry point
- `clearStreamingData()` (~30 lines) - cleanup
- `lockViewportForPause()` / `unlockViewport()` (~40 lines)
- `_animateViewportExpansion()` (~100 lines) - smooth viewport animation
- `_paintStreamingBuffer()` (~100 lines) - direct buffer rendering

**Dependencies**:
- READ: `_transform`, `_originalTransform`, `_plotArea`
- WRITE: `_transform`, `_originalTransform` (viewport updates)
- WRITE: Triggers `markNeedsPaint()`, `_updateAxesFromTransform()`
- Uses `SchedulerBinding.instance.addPostFrameCallback` for animation

**Impact Assessment**:
- ⚠️ Complex animation state machine (auto-scroll vs expand modes)
- ⚠️ Directly modifies `_transform` and `_originalTransform`
- ⚠️ Interacts with `_seriesCacheManager.invalidate()`
- ⚠️ Must coordinate with pause/resume and user pan interactions
- ❌ Tightly coupled to viewport lifecycle

**Extraction Strategy**:
1. Pass `ViewportDelegate` for transform mutations
2. Manager handles animation scheduling internally
3. Requires bidirectional communication (manager ↔ renderbox)
4. Consider extracting animation loop separately

**Risk Level**: HIGH

---

### 4. AnnotationInteractionHandler - HIGH Complexity

**Lines**: ~800 (spread across event handlers)

**State Fields** (~30+ fields):
```dart
// Resize state
_resizingAnnotation: RangeAnnotationElement?
_activeResizeDirection: ResizeDirection?
_resizeStartBounds: Rect?

// Move state (per annotation type - 5 types!)
_movingAnnotation: RangeAnnotationElement?  // Range
_moveStartPosition, _moveStartBounds: Offset?, Rect?

_movingPointAnnotation: PointAnnotationElement?  // Point
_originalDataPointIndex, _candidateDataPointIndex: int?

_movingTextAnnotation: TextAnnotationElement?  // Text
_moveTextStartPosition: Offset?

_movingThresholdAnnotation: ThresholdAnnotationElement?  // Threshold
_moveThresholdStartPosition, _moveThresholdStartValue: Offset?, double?

_movingPinAnnotation: PinAnnotationElement?  // Pin
_movePinStartPosition, _movePinStartX, _movePinStartY: Offset?, double?, double?

// Potential drag state (before threshold exceeded - 5 types!)
_potentialDragRangeAnnotation, _potentialDragRangeStartPosition, _potentialDragRangeStartBounds
_potentialDragPointAnnotation, _potentialDragStartPosition
_potentialDragTextAnnotation, _potentialDragTextStartPosition
_potentialDragThresholdAnnotation, _potentialDragThresholdStartPosition
_potentialDragPinAnnotation, _potentialDragPinStartPosition
```

**Methods to Extract**:
- `_performResize()` (~107 lines, 2138-2245)
- `_performMove()` (~25 lines, 2245-2270) - Range annotation
- `_performPointAnnotationMove()` (~66 lines, 2270-2336)
- `_performTextAnnotationMove()` (~15 lines, 2336-2351)
- `_performThresholdAnnotationMove()` (~36 lines, 2351-2387)
- `_performPinAnnotationMove()` (~40 lines, 2387-2427)
- Drag threshold detection logic (~200 lines in `_handlePointerMove`)
- Pointer up finalization logic (~300 lines in `_handlePointerUp`)

**Dependencies**:
- READ: `_transform`, `_plotArea`, series elements
- WRITE: Element temp bounds via `updateTempValues()`, `updateBounds()`
- WRITE: Emits `onAnnotationChanged` callback with new data coordinates
- Uses `coordinator` for mode claiming

**Impact Assessment**:
- ❌ 5 different annotation types with different move semantics
- ❌ Complex state machine: potential drag → threshold → actual drag → release
- ❌ Tightly coupled to event handlers (`_handlePointerDown`, `_handlePointerMove`, `_handlePointerUp`)
- ❌ Snapping logic requires access to data points
- ⚠️ Coordinate conversion (pixels ↔ data) at multiple points

**Extraction Strategy**:
1. Create unified `AnnotationInteractionHandler` with type-specific strategies
2. Use command pattern: handler returns `AnnotationUpdate` command objects
3. ChartRenderBox applies commands (separation of decision vs execution)
4. Consider splitting into per-type handlers if complexity warrants

**Risk Level**: HIGH

---

### 5. EventDispatcher - HIGHEST Complexity

**Lines**: ~1300 (lines 2420-3615+)

**Methods**:
- `handleEvent()` routing (~20 lines)
- `_handlePointerDown()` (~124 lines, 2439-2563)
- `_handlePointerMove()` (~305 lines, 2563-2868)
- `_handlePointerUp()` (~589 lines, 2868-3457)
- `_handlePointerHover()` (~158 lines, 3457-3615)
- `_handlePointerScroll()` (~100 lines, 3615-3715)

**Dependencies**:
- ALL state fields - event handling touches everything
- ALL modules - scrollbar, annotation, tooltip, crosshair, streaming
- `coordinator` for interaction mode management
- All callbacks: `onElementClick`, `onEmptyAreaClick`, `onAnnotationChanged`, etc.

**Impact Assessment**:
- ❌ Central orchestration point - everything flows through here
- ❌ Cannot extract without extracting all subsystems first
- ❌ Complex priority-based event routing
- ❌ Many interleaved concerns in single methods

**Extraction Strategy**:
1. **MUST BE LAST** - extract all subsystems first
2. EventDispatcher becomes thin router that delegates to modules
3. Each module exposes `handlePointerDown()`, `handlePointerMove()`, etc.
4. Dispatcher just routes based on current mode and hit test results

**Risk Level**: HIGHEST - DO NOT ATTEMPT UNTIL ALL OTHER MODULES EXTRACTED

---

## Revised Priority Order (Low-Hanging Fruit First)

### Phase 1: LOW Complexity (Complete)
1. ✅ SeriesCacheManager - Pure caching, no external deps
2. ✅ TooltipAnimator - Timer-based, clear boundaries  
3. ✅ ViewportConstraints - Pure calculations

### Phase 2: MEDIUM Complexity (Next)
4. **CrosshairRenderer** - Pure rendering, multi-axis read-only
5. **ScrollbarManager** - Self-contained with delegate pattern

### Phase 3: HIGH Complexity (Later)
6. **StreamingManager** - Complex animation, transform mutations
7. **AnnotationInteractionHandler** - Complex state machine

### Phase 4: HIGHEST Complexity (Last)
8. **EventDispatcher** - Must wait for all other modules

---

## Recommended Next Steps

1. **Extract CrosshairRenderer** (~400 lines, MEDIUM)
   - Create `MultiAxisInfo` record to pass axis config
   - Pure rendering, no state mutation
   - Estimated: 2 hours

2. **Extract ScrollbarManager** (~700 lines, MEDIUM-HIGH)
   - Use delegate pattern for transform updates
   - Self-contained timer and state management
   - Estimated: 3 hours

## Goals

1. **Maintainability**: Break down monolithic class into focused, single-responsibility modules
2. **Testability**: Each module can be tested in isolation
3. **Readability**: Code is easier to understand and navigate
4. **Preserve API**: The public interface of `ChartRenderBox` MUST NOT change

## Current Structure Analysis

### Lines by Logical Section (Approximate)

| Section | Lines | Description |
|---------|-------|-------------|
| State & Properties | ~500 | Private fields, getters, setters |
| Multi-Axis Support | ~300 | Y-axis configurations, bindings, normalization |
| Zoom/Pan Constraints | ~300 | \_clampZoomLevel\, \_clampPanDelta\, calculations |
| Live Streaming | ~500 | Buffer management, auto-scroll, viewport animation |
| Layout | ~200 | \performLayout\, plot area calculations |
| Hit Testing | ~100 | \hitTest\, \hitTestElements\, \hitTestRect\ |
| Annotation Manipulation | ~300 | Drag state, resize state, move logic |
| Event Handling | ~1300 | \handleEvent\, pointer processing, gesture routing |
| Scrollbar Interaction | ~700 | Scrollbar state, drag, hover, painting |
| Crosshair/Tooltip | ~800 | Crosshair rendering, tooltip display, animations |
| Painting | ~600 | \paint\, layer rendering, caching |
| Utilities | ~100 | Helper methods, formatting |

**Total**: ~6,652 lines

## Proposed Module Architecture

### Module 1: ViewportController
**Purpose**: Manage viewport state, zoom/pan constraints, transform calculations
**Estimated Lines**: ~400

**Extract**:
- \_transform\ state
- \_originalTransform\
- \_panConstraintTransform\
- \_clampZoomLevel()\
- \_clampPanDelta()\
- Zoom/pan delta application
- \pplyZoom()\, \pplyPan()\

**Interface**:
\\\dart
class ViewportController {
  ChartTransform? transform;
  ChartTransform? originalTransform;
  
  ChartTransform clampZoomLevel(ChartTransform tentative);
  (double, double) clampPanDelta(double dx, double dy);
  void applyZoom(double scale, Offset focalPoint);
  void applyPan(double dx, double dy);
  void reset();
}
\\\

### Module 2: StreamingManager
**Purpose**: Handle live streaming mode, buffer management, auto-scroll
**Estimated Lines**: ~500

**Extract**:
- Streaming buffer integration
- Auto-scroll animation state
- Viewport expansion logic
- \_animateViewportExpansion()\
- Pan constraint bounds for paused mode

**Interface**:
\\\dart
class StreamingManager {
  bool isStreaming;
  bool isPaused;
  
  void setPanConstraintBounds(Rect bounds);
  void clearPanConstraintBounds();
  void animateViewportExpansion();
  void handleNewData(List<ChartDataPoint> points);
}
\\\

### Module 3: ScrollbarManager
**Purpose**: Scrollbar state, interaction, rendering
**Estimated Lines**: ~700

**Extract**:
- \_xScrollbarRect\, \_yScrollbarRect\
- \_activeScrollbarAxis\
- Scrollbar hit testing (\_hitTestScrollbars\)
- Scrollbar drag handling
- Scrollbar painting (\_paintScrollbars\)
- Auto-hide timer logic

**Interface**:
\\\dart
class ScrollbarManager {
  bool showXScrollbar;
  bool showYScrollbar;
  ScrollbarConfig? theme;
  
  HitTestZone? hitTest(Offset position);
  void handleDragStart(Offset position, HitTestZone zone, Axis axis);
  void handleDragUpdate(Offset position);
  void handleDragEnd();
  void paint(Canvas canvas, Rect xRect, Rect yRect, ScrollbarState state);
}
\\\

### Module 4: AnnotationInteractionHandler
**Purpose**: Annotation drag, resize, move logic
**Estimated Lines**: ~500

**Extract**:
- \_resizingAnnotation\, \_movingAnnotation\ state
- \_potentialDrag*\ states for click/drag distinction
- Resize handle element generation
- Annotation move calculations
- \_handleAnnotationResize()\, \_handleAnnotationMove()\

**Interface**:
\\\dart
class AnnotationInteractionHandler {
  bool isDragging;
  ChartElement? activeAnnotation;
  
  void handlePointerDown(ChartElement element, Offset position);
  void handlePointerMove(Offset position, ChartTransform transform);
  void handlePointerUp();
  void handlePointerCancel();
  ChartAnnotation? getUpdatedAnnotation();
}
\\\

### Module 5: EventDispatcher
**Purpose**: Route pointer events to appropriate handlers
**Estimated Lines**: ~400

**Extract**:
- \handleEvent()\ routing logic
- Modifier key handling
- Wheel event processing
- Pointer event classification

**Interface**:
\\\dart
class EventDispatcher {
  void handleEvent(PointerEvent event);
  void handlePointerDown(PointerDownEvent event);
  void handlePointerMove(PointerMoveEvent event);
  void handlePointerUp(PointerUpEvent event);
  void handlePointerScroll(PointerScrollEvent event);
  void handlePointerHover(PointerHoverEvent event);
}
\\\

### Module 6: CrosshairRenderer
**Purpose**: Crosshair line rendering and coordinate display
**Estimated Lines**: ~400

**Extract**:
- \_cursorPosition\ state
- Crosshair line painting
- Coordinate label rendering
- Label caching (future optimization)

**Interface**:
\\\dart
class CrosshairRenderer {
  Offset? cursorPosition;
  
  void setCursorPosition(Offset? position);
  void paint(Canvas canvas, Rect plotArea, ChartTransform transform, ChartTheme theme);
}
\\\

### Module 7: TooltipAnimator
**Purpose**: Tooltip display, positioning, fade animations
**Estimated Lines**: ~400

**Extract**:
- \_tooltipOpacity\ animation state
- \_tooltipShowTimer\, \_tooltipHideTimer\
- Tooltip path creation
- Tooltip content rendering
- Smart positioning logic

**Interface**:
\\\dart
class TooltipAnimator {
  double opacity;
  bool isShowing;
  
  void showTooltip(HoveredMarkerInfo marker);
  void hideTooltip();
  void paint(Canvas canvas, Rect plotArea, ChartTheme theme);
  void dispose();
}
\\\

### Module 8: MultiAxisManager
**Purpose**: Multi-axis configuration, normalization, bounds computation
**Estimated Lines**: ~400

**Extract**:
- \_getEffectiveYAxes()\
- \_getEffectiveBindings()\
- \_computeAxisBounds()\
- \_paintMultipleYAxes()\
- Normalization helpers

**Interface**:
\\\dart
class MultiAxisManager {
  NormalizationMode? mode;
  List<ChartSeries> series;
  
  List<YAxisConfig> getEffectiveYAxes();
  List<SeriesAxisBinding> getEffectiveBindings();
  Map<String, DataRange> computeAxisBounds();
  bool hasMultipleYAxes();
}
\\\

### Module 9: SeriesCacheManager
**Purpose**: Picture caching for series layer
**Estimated Lines**: ~200

**Extract**:
- \_cachedSeriesPicture\
- \_seriesCacheDirty\ flag
- \_cachedSeriesHash\
- Cache invalidation logic
- \_getSeriesPicture()\

**Interface**:
\\\dart
class SeriesCacheManager {
  bool isDirty;
  
  ui.Picture? getCachedPicture();
  void invalidate();
  void updateCache(List<ChartElement> elements, ChartTransform transform);
  void dispose();
}
\\\

### ChartRenderBox (Refactored)
**Purpose**: Facade/coordinator that delegates to modules
**Estimated Lines**: ~800

**Remaining**:
- Constructor with delegation to modules
- \performLayout()\ (reduced, delegates)
- \paint()\ (coordinates layer painting)
- Public API methods (delegating to modules)
- Spatial index management

## Implementation Order

### Phase 1: Low-Risk Extractions (Pure calculations, no complex state)
1. **SeriesCacheManager** ✅ - Self-contained caching logic (commit 876a479)
2. **TooltipAnimator** ✅ - Timer-based animation, clear boundaries (commit c19e96c)
3. **ViewportConstraints** ✅ - Pure zoom/pan calculations (commit 7ef6396)
4. **CrosshairRenderer** - Isolated rendering (depends on multi-axis for labels)

### Phase 2: State-Heavy Extractions (Complex state dependencies)
5. **StreamingManager** - Live streaming mode, viewport animation
6. **ScrollbarManager** - Complex interaction with hover/drag/hide states
7. **MultiAxisManager** - Multi-axis configuration and normalization

### Phase 3: Event Flow Extractions (High coupling)
8. **AnnotationInteractionHandler** - Complex state machine for annotation editing
9. **EventDispatcher** - High-level routing (depends on all handlers)

### Complexity Assessment (Low → High)
| Module | Complexity | Dependencies | Recommended Order |
|--------|------------|--------------|-------------------|
| SeriesCacheManager | ⬛ Low | None | ✅ Done |
| TooltipAnimator | ⬛ Low | Timer only | ✅ Done |
| ViewportConstraints | ⬛ Low | ChartTransform | ✅ Done |
| CrosshairRenderer | ⬛⬛ Medium | Multi-axis, Theme | Next candidate |
| ScrollbarManager | ⬛⬛ Medium | Timer, Hover state | Later |
| StreamingManager | ⬛⬛⬛ Medium-High | Viewport, Animation | Later |
| MultiAxisManager | ⬛⬛⬛ Medium-High | Many paint methods | Later |
| AnnotationInteractionHandler | ⬛⬛⬛⬛ High | State machine | Last |
| EventDispatcher | ⬛⬛⬛⬛ High | All handlers | Last |

### Phase 4: Integration
9. **StreamingManager** - Last due to cross-cutting concerns
10. **Final cleanup** - Remove dead code, optimize imports

## Testing Strategy

### Baseline Tests (COMPLETED)
- \	est/unit/rendering/chart_render_box_baseline_test.dart\ - 35 tests
- Covers: construction, coordinate conversion, normalization, state updates, disposal

### Module Tests (TODO)
Each extracted module needs:
- Unit tests for isolated functionality
- Integration tests with ChartRenderBox

### Regression Tests (TODO)
- Run full existing test suite after each phase
- Manual visual verification with example app

## Risk Mitigation

1. **Backup**: Original file backed up at \chart_render_box.dart.backup\
2. **Baseline Tests**: Comprehensive tests before any changes
3. **Incremental**: One module at a time, test after each
4. **Public API Lock**: No changes to ChartRenderBox public interface
5. **Git Commits**: Atomic commits per module extraction

## Success Criteria

- [ ] All 35 baseline tests pass
- [ ] All existing widget/interaction tests pass
- [ ] No changes to ChartRenderBox public API
- [ ] Each module has dedicated unit tests
- [ ] ChartRenderBox reduced to ~800 lines
- [ ] Code compiles with no analyzer warnings
- [ ] Manual visual verification passes

## Dependencies

| Module | Depends On |
|--------|------------|
| SeriesCacheManager | None |
| CrosshairRenderer | ChartTransform |
| TooltipAnimator | ChartTheme |
| ViewportController | ChartTransform |
| MultiAxisManager | ViewportController (transform) |
| ScrollbarManager | ViewportController (transform) |
| AnnotationInteractionHandler | ViewportController, Coordinator |
| EventDispatcher | All handlers |
| StreamingManager | ViewportController |

## File Structure After Refactoring

\\\
lib/src/rendering/
├── chart_render_box.dart           # Facade (~800 lines)
├── chart_render_box.dart.backup    # Original backup
├── modules/
│   ├── viewport_controller.dart
│   ├── streaming_manager.dart
│   ├── scrollbar_manager.dart
│   ├── annotation_interaction_handler.dart
│   ├── event_dispatcher.dart
│   ├── crosshair_renderer.dart
│   ├── tooltip_animator.dart
│   ├── multi_axis_manager.dart
│   └── series_cache_manager.dart
├── multi_axis_normalizer.dart      # Existing
├── multi_axis_painter.dart         # Existing
└── spatial_index.dart              # Existing
\\\

## Next Steps

1. Create \lib/src/rendering/modules/\ directory
2. Begin Phase 1 with SeriesCacheManager extraction
3. Write tests for SeriesCacheManager
4. Continue through phases
