# ChartRenderBox Refactoring Plan

## Overview

This document outlines the detailed plan for refactoring \ChartRenderBox\ (6,652 lines) into smaller, more manageable modules while preserving the existing public API.

**Date Created**: 2025-12-05
**Status**: Planning
**Branch**: render-refactor
**Backup Location**: \lib/src/rendering/chart_render_box.dart.backup\

## Goals

1. **Maintainability**: Break down monolithic class into focused, single-responsibility modules
2. **Testability**: Each module can be tested in isolation
3. **Readability**: Code is easier to understand and navigate
4. **Preserve API**: The public interface of \ChartRenderBox\ MUST NOT change

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

### Phase 1: Low-Risk Extractions (No behavior change)
1. **SeriesCacheManager** - Self-contained caching logic
2. **CrosshairRenderer** - Isolated rendering, no state dependencies
3. **TooltipAnimator** - Isolated with clear timer management

### Phase 2: State-Heavy Extractions
4. **ViewportController** - Core transform management
5. **MultiAxisManager** - Multi-axis logic (depends on ViewportController)
6. **ScrollbarManager** - Complex but isolated interaction

### Phase 3: Event Flow Extractions
7. **AnnotationInteractionHandler** - Complex state machine
8. **EventDispatcher** - High-level routing (depends on all handlers)

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
