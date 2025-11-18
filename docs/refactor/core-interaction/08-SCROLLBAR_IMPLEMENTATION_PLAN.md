# Scrollbar Implementation Plan - BravenChartPlus

**Feature**: Dual-Purpose Scrollbars (Pan + Zoom)  
**Branch**: `core-interaction-refactor`  
**Status**: ⏳ Phase 1 - Planning Complete  
**Priority**: P5 (Feature 5 - Last major feature in Phase 2)  
**Created**: 2025-11-18  
**Estimated Time**: 4-6 hours (full feature set)  
**Target Completion**: 2025-11-20  

---

## 📊 Executive Summary

### What We're Building

A **dual-purpose scrollbar widget** that provides both pan and zoom interactions in a single component:

- **Pan Mode**: Drag center of handle → shifts entire viewport
- **Zoom Mode**: Drag edges (left/right or top/bottom) → resizes viewport boundaries
- **Track Click**: Click outside handle → jump viewport to position (300ms animation)
- **Keyboard Navigation**: Arrow keys, page up/down, home/end
- **Auto-Hide**: Fades out after 2 seconds of inactivity
- **Accessibility**: WCAG 2.1 AA compliant (44x44 touch targets, 4.5:1 contrast)

### Key Architectural Innovation: Pixel-Delta Pattern

**Problem Solved**: Eliminates circular dependencies from dual sources of truth (parent viewport + scrollbar baseline) that caused 70% working / 30% snap-jump bugs.

**Solution**: Scrollbar reports **pixel deltas only** (no data state), parent converts to data deltas using **current viewport** (single source of truth).

**Benefits**:
- ✅ No synchronization issues
- ✅ External viewport changes handled gracefully
- ✅ Simpler code (~100 lines removed vs old approach)
- ✅ All custom features preserved (track click, keyboard, zoom, accessibility)

---

## 🎯 Goals & Success Criteria

### Primary Goals

1. **Port all scrollbar components** from BravenChart to `lib/src_plus/widgets/scrollbar/`
2. **Integrate with ChartTransform** coordinate system (pixel ↔ data conversion)
3. **Sync with Coordinator** interaction state (disable during chart gestures)
4. **Preserve pixel-delta pattern** architecture (no data state in scrollbar)
5. **Full feature parity** with BravenChart scrollbars

### Success Criteria

- [ ] Horizontal and vertical scrollbars render correctly
- [ ] Pan mode works (drag center → shift viewport)
- [ ] Zoom mode works (drag edges → resize viewport)
- [ ] Track click jumps to position (300ms animation)
- [ ] Keyboard navigation works (arrow keys, page up/down, home/end)
- [ ] Auto-hide fades out after 2 seconds
- [ ] Scrollbars sync with ChartTransform viewport changes
- [ ] No conflicts with chart pan/zoom gestures
- [ ] Accessibility features work (touch targets, contrast, keyboard)
- [ ] Performance: 60fps during scrollbar drag
- [ ] Works with streaming mode (viewport updates during streaming)

---

## 📁 Architecture Overview

### Component Hierarchy

```
BravenChartPlus (Widget)
└── ChartRenderBox (RenderBox)
    ├── Chart Canvas (series, axes, grid)
    │   └── ChartTransform (coordinate system)
    │       └── Viewport state (xViewportRange, yViewportRange)
    │
    └── Scrollbars (positioned around canvas)
        ├── ChartScrollbar (Horizontal)
        │   ├── ScrollbarPainter (CustomPainter)
        │   ├── ScrollbarController (pure functions)
        │   └── ScrollbarState (ValueNotifier)
        │
        └── ChartScrollbar (Vertical)
            ├── ScrollbarPainter (CustomPainter)
            ├── ScrollbarController (pure functions)
            └── ScrollbarState (ValueNotifier)
```

### Data Flow: Pixel-Delta Pattern

```
User drags scrollbar
    ↓
ChartScrollbar._onPanUpdate()
    ↓ (calculates pixel delta from drag start)
widget.onPixelDeltaChanged(pixelOffset, ScrollbarInteraction.pan)
    ↓
ChartRenderBox._handleScrollbarPixelDelta()
    ↓ (converts pixel delta to data delta using CURRENT viewport)
transform.setViewport(newViewport)
    ↓
ChartRenderBox.markNeedsPaint()
    ↓
Scrollbar auto-updates (geometry recalculated from new viewport)
```

**Key Insight**: Scrollbar has NO data baseline. It only tracks pixel position. Parent owns ALL data state.

---

## 🗂️ Files to Port

### From BravenChart (`lib/src/widgets/scrollbar/`)

| Source File | Destination | Lines | Purpose |
|-------------|-------------|-------|---------|
| `chart_scrollbar.dart` | `lib/src_plus/widgets/scrollbar/chart_scrollbar.dart` | 741 | Main StatefulWidget |
| `scrollbar_controller.dart` | `lib/src_plus/widgets/scrollbar/scrollbar_controller.dart` | ~200 | Pure functions (geometry) |
| `scrollbar_interaction.dart` | `lib/src_plus/widgets/scrollbar/scrollbar_interaction.dart` | ~50 | Enum (pan/zoom types) |
| `scrollbar_state.dart` | `lib/src_plus/widgets/scrollbar/scrollbar_state.dart` | ~200 | Immutable state |
| `scrollbar_painter.dart` | `lib/src_plus/widgets/scrollbar/scrollbar_painter.dart` | ~360 | CustomPainter |
| `hit_test_zone.dart` | `lib/src_plus/widgets/scrollbar/hit_test_zone.dart` | ~50 | Enum (track/center/edges) |
| `scrollbar_config.dart` | `lib/src_plus/theming/components/scrollbar_config.dart` | ~350 | Theme configuration |

**Total**: ~2,000 lines of code to port

---

## 📋 Implementation Tasks

### Phase 1: Core Widget Porting (2-3 hours)

#### Task 1.1: Port Pure Functions & Enums ✅ COMPLETE
**Time**: 30 minutes (Actual: 15 minutes)  
**Files**: 3 files (~300 lines)

- [x] Copy `scrollbar_controller.dart` → `lib/src_plus/widgets/scrollbar/`
  - Pure functions for geometry calculations
  - No dependencies, no modifications needed
  - Verify imports work
  
- [x] Copy `scrollbar_interaction.dart` → `lib/src_plus/widgets/scrollbar/`
  - Simple enum (pan, zoomLeftOrTop, zoomRightOrBottom, trackClick, keyboard)
  - No modifications needed
  
- [x] Copy `hit_test_zone.dart` → `lib/src_plus/widgets/scrollbar/`
  - Simple enum (track, center, leftEdge, rightEdge, topEdge, bottomEdge)
  - No modifications needed

**Success Criteria**:
- [x] Files compile without errors
- [x] All imports resolve correctly
- [x] No dependencies on old BravenChart code

**Completed**: 2025-11-18

---

#### Task 1.2: Port State & Configuration ✅ STRAIGHTFORWARD
**Time**: 30 minutes  
**Files**: 2 files (~550 lines)

- [ ] Copy `scrollbar_state.dart` → `lib/src_plus/widgets/scrollbar/`
  - Immutable state class with ValueNotifier
  - Verify imports (should be minimal)
  - No modifications needed
  
- [ ] Copy `scrollbar_config.dart` → `lib/src_plus/theming/components/`
  - Complete theme configuration with 22+ properties
  - Includes light/dark/high-contrast presets
  - No modifications needed
  - Will integrate with BravenChartPlus theme system later

**Success Criteria**:
- [ ] Files compile without errors
- [ ] ScrollbarState copyWith() methods work
- [ ] ScrollbarConfig presets (defaultLight, defaultDark, highContrast) available

---

#### Task 1.3: Port Custom Painter ✅ STRAIGHTFORWARD
**Time**: 30 minutes  
**Files**: 1 file (~360 lines)

- [ ] Copy `scrollbar_painter.dart` → `lib/src_plus/widgets/scrollbar/`
  - CustomPainter for rendering track, handle, grip indicator, edge highlights
  - Verify imports (ScrollbarConfig, ScrollbarState, HitTestZone)
  - No modifications needed (stateless rendering)

**Success Criteria**:
- [ ] File compiles without errors
- [ ] All rendering methods present (paintTrack, paintHandle, paintGripIndicator, paintEdgeHighlight)
- [ ] shouldRepaint() logic works

---

#### Task 1.4: Port Main Widget (Simplified) ⚠️ COMPLEX
**Time**: 1 hour  
**Files**: 1 file (741 lines → ~600 lines after cleanup)

- [ ] Copy `chart_scrollbar.dart` → `lib/src_plus/widgets/scrollbar/`
  
- [ ] **REMOVE** obsolete callbacks (backward compatibility cruft):
  - Remove `onPanChanged` callback (T071 - old API)
  - Remove `onZoomChanged` callback (T092 - old API)
  - Keep ONLY `onPixelDeltaChanged` (new pixel-delta pattern)
  
- [ ] **REMOVE** obsolete animation code:
  - Remove `_jumpAnimation` and `_jumpAnimationController` (parent handles jump animation now)
  - Remove `_onJumpAnimationTick()` method (obsolete in pixel-delta pattern)
  - Remove `_onJumpAnimationComplete()` method (obsolete in pixel-delta pattern)
  - Keep `_cancelJumpAnimation()` but simplify (only cancel, no viewport state)
  
- [ ] **KEEP** all essential features:
  - Pixel-delta pattern (`_dragStartPosition`, `_dragZone`)
  - Pan/zoom gesture handlers (`_onPanStart`, `_onPanUpdate`, `_onPanEnd`)
  - Hover detection (`_onHover`, `_onExit`, `_getCursorForZone`)
  - Track click (`_onTrackClick`)
  - Auto-hide timer (`_scheduleAutoHide`, `_cancelAutoHide`, `_resetAutoHide`)
  - Zoom limit feedback (`_flashAnimationController`)
  - Keyboard navigation (if present)
  - ValueNotifier state management
  - Focus management

**Success Criteria**:
- [ ] File compiles without errors
- [ ] Simplified API (only `onPixelDeltaChanged` callback)
- [ ] All gesture handlers work
- [ ] Pixel-delta pattern preserved
- [ ] No data state tracking (only pixel positions)

---

### Phase 2: Integration with ChartRenderBox (1-2 hours)

#### Task 2.1: Add Scrollbar Configuration ✅ STRAIGHTFORWARD
**Time**: 15 minutes

- [ ] Add scrollbar config to `ChartConfig`:
  ```dart
  class ChartConfig {
    final bool showXScrollbar;
    final bool showYScrollbar;
    final ScrollbarConfig scrollbarTheme;
    
    // Constructor with defaults
    const ChartConfig({
      this.showXScrollbar = false,
      this.showYScrollbar = false,
      this.scrollbarTheme = const ScrollbarConfig.defaultLight(),
      // ... other config
    });
  }
  ```

- [ ] Update `BravenChartPlus` widget to accept scrollbar config
- [ ] Pass config to `ChartRenderBox`

**Success Criteria**:
- [ ] Config compiles
- [ ] Can enable/disable scrollbars via config
- [ ] Theme config available to ChartRenderBox

---

#### Task 2.2: Layout Integration ⚠️ MODERATE COMPLEXITY
**Time**: 30 minutes

- [ ] Modify `ChartRenderBox.performLayout()` to reserve space for scrollbars:
  ```dart
  @override
  void performLayout() {
    final scrollbarThickness = config.scrollbarTheme.thickness;
    
    // Calculate chart canvas size (exclude scrollbar space)
    final chartWidth = constraints.maxWidth - 
      (config.showYScrollbar ? scrollbarThickness + padding : 0);
    final chartHeight = constraints.maxHeight - 
      (config.showXScrollbar ? scrollbarThickness + padding : 0);
    
    final chartSize = Size(chartWidth, chartHeight);
    
    // Calculate scrollbar positions
    if (config.showXScrollbar) {
      _xScrollbarRect = Rect.fromLTWH(
        0,
        chartHeight + padding,
        chartWidth,
        scrollbarThickness,
      );
    }
    
    if (config.showYScrollbar) {
      _yScrollbarRect = Rect.fromLTWH(
        chartWidth + padding,
        0,
        scrollbarThickness,
        chartHeight,
      );
    }
    
    // Handle corner overlap if both scrollbars shown
    if (config.showXScrollbar && config.showYScrollbar) {
      // Adjust X scrollbar to not overlap Y scrollbar
      _xScrollbarRect = Rect.fromLTWH(
        0,
        chartHeight + padding,
        chartWidth, // Already excludes Y scrollbar space
        scrollbarThickness,
      );
    }
    
    size = constraints.biggest;
  }
  ```

**Success Criteria**:
- [ ] Chart canvas size correctly excludes scrollbar space
- [ ] Scrollbar positions calculated correctly
- [ ] Corner overlap handled gracefully
- [ ] Layout doesn't break existing rendering

---

#### Task 2.3: Scrollbar Rendering ⚠️ MODERATE COMPLEXITY
**Time**: 30 minutes

- [ ] Add scrollbar widgets to `ChartRenderBox`:
  ```dart
  class ChartRenderBox extends RenderBox {
    ChartScrollbar? _xScrollbar;
    ChartScrollbar? _yScrollbar;
    
    void _buildScrollbars(BoxConstraints constraints) {
      if (config.showXScrollbar) {
        _xScrollbar = ChartScrollbar(
          axis: Axis.horizontal,
          dataRange: transform.xDataRange,
          viewportRange: transform.xViewportRange,
          onPixelDeltaChanged: _handleXScrollbarDelta,
          theme: config.scrollbarTheme,
        );
      }
      
      if (config.showYScrollbar) {
        _yScrollbar = ChartScrollbar(
          axis: Axis.vertical,
          dataRange: transform.yDataRange,
          viewportRange: transform.yViewportRange,
          onPixelDeltaChanged: _handleYScrollbarDelta,
          theme: config.scrollbarTheme,
        );
      }
    }
  }
  ```

- [ ] Call `_buildScrollbars()` in appropriate lifecycle method
- [ ] Update scrollbars when viewport changes

**Success Criteria**:
- [ ] Scrollbars instantiate correctly
- [ ] Scrollbars receive correct data/viewport ranges
- [ ] Scrollbars positioned correctly on canvas

---

#### Task 2.4: Pixel-Delta Conversion ⚠️ CRITICAL - MOST COMPLEX
**Time**: 1 hour

- [ ] Implement `_handleXScrollbarDelta()` in `ChartRenderBox`:
  ```dart
  void _handleXScrollbarDelta(Offset pixelDelta, ScrollbarInteraction type) {
    // Get track length for conversion
    final trackLength = _xScrollbarRect?.width ?? 0;
    if (trackLength == 0) return;
    
    // Get current viewport from ChartTransform
    final currentViewport = transform.xViewportRange;
    
    // Calculate data per pixel ratio
    final dataPerPixel = currentViewport.span / trackLength;
    
    // Convert pixel delta to data delta
    final dataDelta = pixelDelta.dx * dataPerPixel;
    
    // Apply based on interaction type
    switch (type) {
      case ScrollbarInteraction.pan:
        // Shift entire viewport
        final newViewport = currentViewport.shift(dataDelta);
        transform.setXViewport(newViewport);
        break;
        
      case ScrollbarInteraction.zoomLeftOrTop:
        // Adjust minimum boundary only
        final newMin = currentViewport.min + dataDelta;
        final newViewport = DataRange(newMin, currentViewport.max);
        transform.setXViewport(newViewport);
        break;
        
      case ScrollbarInteraction.zoomRightOrBottom:
        // Adjust maximum boundary only
        final newMax = currentViewport.max + dataDelta;
        final newViewport = DataRange(currentViewport.min, newMax);
        transform.setXViewport(newViewport);
        break;
        
      case ScrollbarInteraction.trackClick:
        // Convert pixel position to data position
        final targetDataPosition = transform.xDataRange.min + 
          (pixelDelta.dx * dataPerPixel);
        
        // Calculate new viewport centered on target
        final viewportHalfSpan = currentViewport.span / 2;
        final newViewport = DataRange(
          targetDataPosition - viewportHalfSpan,
          targetDataPosition + viewportHalfSpan,
        );
        
        // Animate to target (300ms ease-out)
        _animateXViewportTo(newViewport);
        break;
        
      case ScrollbarInteraction.keyboard:
        // Handle arrow keys, page up/down, home/end
        _handleKeyboardNavigation(dataDelta);
        break;
    }
    
    // Trigger repaint
    markNeedsPaint();
  }
  ```

- [ ] Implement `_handleYScrollbarDelta()` (mirror of X axis logic)

- [ ] Implement `_animateXViewportTo()` for track click animation:
  ```dart
  void _animateXViewportTo(DataRange targetViewport) {
    // 300ms ease-out animation
    final animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: // ... need to wire up vsync
    );
    
    final animation = Tween<DataRange>(
      begin: transform.xViewportRange,
      end: targetViewport,
    ).animate(CurvedAnimation(
      parent: animationController,
      curve: Curves.easeOut,
    ));
    
    animation.addListener(() {
      transform.setXViewport(animation.value);
      markNeedsPaint();
    });
    
    animationController.forward();
  }
  ```

**Success Criteria**:
- [ ] Pixel delta correctly converts to data delta
- [ ] Pan mode shifts viewport
- [ ] Zoom mode resizes viewport boundaries
- [ ] Track click jumps to position with animation
- [ ] Keyboard navigation works
- [ ] Viewport updates trigger scrollbar geometry recalculation

---

### Phase 3: Coordinator Integration (30 min - 1 hour)

#### Task 3.1: Gesture Priority Management ⚠️ MODERATE
**Time**: 30 minutes

- [ ] Add scrollbar state to `ChartInteractionCoordinator`:
  ```dart
  class ChartInteractionCoordinator {
    bool _isScrollbarActive = false;
    
    void notifyScrollbarDragStart() {
      _isScrollbarActive = true;
      // Disable chart pan/zoom gestures while scrollbar active
    }
    
    void notifyScrollbarDragEnd() {
      _isScrollbarActive = false;
      // Re-enable chart pan/zoom gestures
    }
    
    bool get allowChartGestures => !_isScrollbarActive;
  }
  ```

- [ ] Wire scrollbar drag start/end to coordinator notifications

- [ ] Update chart gesture recognizers to check `allowChartGestures`

**Success Criteria**:
- [ ] Scrollbar drag prevents chart pan/zoom
- [ ] Chart pan/zoom prevents scrollbar interaction
- [ ] No gesture conflicts or interference

---

#### Task 3.2: Viewport Synchronization ✅ STRAIGHTFORWARD
**Time**: 15 minutes

- [ ] Update scrollbars when chart viewport changes externally:
  ```dart
  void _updateScrollbars() {
    if (_xScrollbar != null) {
      // Scrollbar auto-updates via rebuild with new viewport range
      // No explicit state update needed (pixel-delta pattern)
    }
    
    if (_yScrollbar != null) {
      // Same for Y scrollbar
    }
  }
  ```

- [ ] Call `_updateScrollbars()` after any viewport change (pan, zoom, streaming)

**Success Criteria**:
- [ ] Scrollbars update when chart pans/zooms
- [ ] Scrollbars update during streaming
- [ ] No lag or desync between chart and scrollbars

---

#### Task 3.3: Interaction Mode Integration ✅ STRAIGHTFORWARD
**Time**: 15 minutes

- [ ] Respect `InteractionConfig.enablePan` / `enableZoom`:
  ```dart
  // In ChartScrollbar widget
  final enablePan = widget.interactionConfig?.enablePan ?? true;
  final enableZoom = widget.interactionConfig?.enableZoom ?? true;
  
  // Only allow pan mode if enablePan is true
  if (type == ScrollbarInteraction.pan && !enablePan) {
    return; // Ignore pan gesture
  }
  
  // Only allow zoom modes if enableZoom is true
  if ((type == ScrollbarInteraction.zoomLeftOrTop || 
       type == ScrollbarInteraction.zoomRightOrBottom) && !enableZoom) {
    return; // Ignore zoom gesture
  }
  ```

**Success Criteria**:
- [ ] Scrollbar respects interaction config
- [ ] Can disable pan mode via config
- [ ] Can disable zoom mode via config

---

### Phase 4: Testing & Polish (1-2 hours)

#### Task 4.1: Example Integration ✅ STRAIGHTFORWARD
**Time**: 30 minutes

- [ ] Add scrollbar showcase to `example/lib/braven_chart_plus_example.dart`:
  ```dart
  BravenChartPlus(
    series: [/* data */],
    config: ChartConfig(
      showXScrollbar: true,
      showYScrollbar: true,
      scrollbarTheme: ScrollbarConfig.defaultLight(),
    ),
  )
  ```

- [ ] Create dedicated scrollbar example demonstrating:
  - Pan mode (drag center)
  - Zoom mode (drag edges)
  - Track click (click outside handle)
  - Keyboard navigation
  - Auto-hide behavior
  - Dual-axis scrollbars (corner overlap)

**Success Criteria**:
- [ ] Example compiles and runs
- [ ] All scrollbar features demonstrated
- [ ] Visual inspection shows correct behavior

---

#### Task 4.2: Manual Testing ⚠️ THOROUGH
**Time**: 30 minutes

Test scenarios:

- [ ] **Horizontal Scrollbar**:
  - [ ] Pan mode shifts viewport horizontally
  - [ ] Zoom left edge resizes viewport minimum
  - [ ] Zoom right edge resizes viewport maximum
  - [ ] Track click jumps to position with animation
  - [ ] Auto-hide fades out after 2 seconds
  - [ ] Hover over edge zones shows blue highlight
  
- [ ] **Vertical Scrollbar**:
  - [ ] Pan mode shifts viewport vertically
  - [ ] Zoom top edge resizes viewport minimum
  - [ ] Zoom bottom edge resizes viewport maximum
  - [ ] Track click jumps to position with animation
  
- [ ] **Dual-Axis Scrollbars**:
  - [ ] Both scrollbars render without overlap
  - [ ] Corner space handled correctly
  - [ ] X and Y scrollbars independent
  
- [ ] **Integration**:
  - [ ] Chart pan updates scrollbar position
  - [ ] Chart zoom updates scrollbar size
  - [ ] Streaming updates scrollbar
  - [ ] No conflicts between chart and scrollbar gestures
  
- [ ] **Accessibility**:
  - [ ] Touch targets meet 44x44 minimum
  - [ ] Contrast ratios meet WCAG 2.1 AA
  - [ ] Keyboard navigation works
  - [ ] Focus indicators visible

**Success Criteria**:
- [ ] All test scenarios pass
- [ ] No visual glitches or rendering issues
- [ ] Performance smooth (60fps during drag)

---

#### Task 4.3: Performance Validation ✅ CRITICAL
**Time**: 30 minutes

- [ ] Test scrollbar performance:
  - [ ] 60fps during scrollbar drag (measure frame time)
  - [ ] No jank or stuttering
  - [ ] Smooth animation for track click (300ms)
  - [ ] No memory leaks (Picture objects disposed correctly)
  
- [ ] Test with stress scenarios:
  - [ ] Large dataset (10,000+ points)
  - [ ] Multiple charts with scrollbars
  - [ ] Streaming + scrollbar + pan/zoom simultaneously
  
- [ ] Profile if needed:
  ```powershell
  flutter run --profile -d chrome
  # Use DevTools performance profiler
  ```

**Success Criteria**:
- [ ] Frame times <16ms (60fps)
- [ ] No memory leaks
- [ ] Smooth performance under stress

---

#### Task 4.4: Unit Tests ⚠️ IMPORTANT
**Time**: 30 minutes

- [ ] Write unit tests for `ScrollbarController` pure functions:
  - [ ] `calculateHandleSize()` - various viewport/data ratios
  - [ ] `calculateHandlePosition()` - various scroll offsets
  - [ ] `handleToDataRange()` - inverse transform
  - [ ] `getHitTestZone()` - edge detection
  - [ ] `getCursorForZone()` - cursor mapping
  
- [ ] Write widget tests for `ChartScrollbar`:
  - [ ] Renders correctly (horizontal/vertical)
  - [ ] Gesture callbacks fire correctly
  - [ ] State updates on hover/drag
  - [ ] Auto-hide timer works

**Success Criteria**:
- [ ] 15+ unit tests passing
- [ ] >80% code coverage for scrollbar components

---

## 🔗 Integration Points

### 1. ChartTransform Coordinate System

**Required Methods** (may need to add to ChartTransform):

```dart
class ChartTransform {
  // Viewport accessors (already exist)
  DataRange get xViewportRange;
  DataRange get yViewportRange;
  DataRange get xDataRange;
  DataRange get yDataRange;
  
  // Viewport setters (may need to add)
  void setXViewport(DataRange viewport);
  void setYViewport(DataRange viewport);
  
  // Convenience method for pixel-to-data conversion
  double xPixelsToData(double pixels, double trackLength) {
    final dataPerPixel = xViewportRange.span / trackLength;
    return pixels * dataPerPixel;
  }
  
  double yPixelsToData(double pixels, double trackLength) {
    final dataPerPixel = yViewportRange.span / trackLength;
    return pixels * dataPerPixel;
  }
}
```

### 2. ChartRenderBox Layout

**New Fields** (add to ChartRenderBox):

```dart
class ChartRenderBox extends RenderBox {
  Rect? _xScrollbarRect;
  Rect? _yScrollbarRect;
  ChartScrollbar? _xScrollbar;
  ChartScrollbar? _yScrollbar;
  
  // Scrollbar pixel-delta handlers
  void _handleXScrollbarDelta(Offset pixelDelta, ScrollbarInteraction type);
  void _handleYScrollbarDelta(Offset pixelDelta, ScrollbarInteraction type);
  
  // Animation controllers for track click
  AnimationController? _xScrollbarJumpController;
  AnimationController? _yScrollbarJumpController;
}
```

### 3. Coordinator Interaction State

**New Methods** (add to ChartInteractionCoordinator):

```dart
class ChartInteractionCoordinator {
  bool _isScrollbarActive = false;
  
  void notifyScrollbarDragStart();
  void notifyScrollbarDragEnd();
  bool get allowChartGestures => !_isScrollbarActive;
}
```

---

## ⚠️ Known Challenges & Mitigation

### Challenge 1: AnimationController Lifecycle

**Problem**: ChartScrollbar needs `TickerProvider` for track click animation (300ms).

**Solution Options**:
1. **Pass TickerProvider from parent** (ChartRenderBox → ChartScrollbar)
2. **Use `vsync: this` in StatefulWidget** (ChartScrollbar already StatefulWidget, add `TickerProviderStateMixin`)
3. **Move animation to parent** (ChartRenderBox handles animation, scrollbar only reports target position)

**Recommendation**: Option 2 (add `TickerProviderStateMixin` to `_ChartScrollbarState`)

**Implementation**:
```dart
class _ChartScrollbarState extends State<ChartScrollbar> 
    with TickerProviderStateMixin {
  late AnimationController _jumpAnimationController;
  
  @override
  void initState() {
    super.initState();
    _jumpAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this, // ✅ Works with TickerProviderStateMixin
    );
  }
}
```

---

### Challenge 2: Scrollbar as RenderObject vs Widget

**Problem**: Current implementation uses `ChartScrollbar` as a Widget, but ChartRenderBox is a RenderObject. How do we render scrollbar widgets from RenderBox paint()?

**Solution Options**:
1. **Render scrollbars in parent widget** (BravenChartPlus builds scrollbars as siblings to RenderBox)
2. **Create custom RenderBox for scrollbars** (paint scrollbars directly in RenderBox, no widgets)
3. **Use CustomMultiChildLayout** (parent widget manages layout, RenderBox paints chart)

**Recommendation**: Option 1 (render scrollbars in parent widget)

**Architecture**:
```dart
class BravenChartPlus extends StatefulWidget {
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Chart canvas (RenderBox)
        _ChartRenderObjectWidget(...),
        
        // Scrollbars (Widgets positioned via Stack)
        if (config.showXScrollbar)
          Positioned(
            left: 0,
            bottom: 0,
            right: config.showYScrollbar ? scrollbarThickness : 0,
            height: scrollbarThickness,
            child: ChartScrollbar(
              axis: Axis.horizontal,
              dataRange: transform.xDataRange,
              viewportRange: transform.xViewportRange,
              onPixelDeltaChanged: _handleXScrollbarDelta,
              theme: config.scrollbarTheme,
            ),
          ),
        
        if (config.showYScrollbar)
          Positioned(
            top: 0,
            right: 0,
            bottom: config.showXScrollbar ? scrollbarThickness : 0,
            width: scrollbarThickness,
            child: ChartScrollbar(
              axis: Axis.vertical,
              dataRange: transform.yDataRange,
              viewportRange: transform.yViewportRange,
              onPixelDeltaChanged: _handleYScrollbarDelta,
              theme: config.scrollbarTheme,
            ),
          ),
      ],
    );
  }
}
```

**Benefits**:
- ✅ Scrollbars use standard Flutter widget lifecycle
- ✅ Easy to manage state (StatefulWidget, ValueNotifier)
- ✅ Gesture detection works out-of-the-box (GestureDetector)
- ✅ TickerProvider available (TickerProviderStateMixin)

**Drawbacks**:
- ❌ Slightly more complex widget tree (Stack with Positioned)
- ❌ Need to pass viewport state from RenderBox to parent widget

---

### Challenge 3: Viewport State Synchronization

**Problem**: Scrollbar needs to know viewport state (dataRange, viewportRange) from ChartTransform, but ChartTransform lives inside ChartRenderBox.

**Solution**: Pass viewport state from ChartRenderBox to parent widget via callback or ValueNotifier.

**Implementation**:
```dart
class ChartRenderBox extends RenderBox {
  final ValueNotifier<DataRange> xViewportNotifier;
  final ValueNotifier<DataRange> yViewportNotifier;
  
  // Update notifiers whenever viewport changes
  void _updateViewport() {
    xViewportNotifier.value = transform.xViewportRange;
    yViewportNotifier.value = transform.yViewportRange;
  }
}

class BravenChartPlus extends StatefulWidget {
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<DataRange>(
      valueListenable: _xViewportNotifier,
      builder: (context, xViewport, child) {
        return ValueListenableBuilder<DataRange>(
          valueListenable: _yViewportNotifier,
          builder: (context, yViewport, child) {
            return Stack(
              children: [
                _ChartRenderObjectWidget(...),
                if (config.showXScrollbar)
                  ChartScrollbar(
                    viewportRange: xViewport, // ✅ Always in sync
                    ...
                  ),
              ],
            );
          },
        );
      },
    );
  }
}
```

---

### Challenge 4: Performance During Scrollbar Drag

**Problem**: Scrollbar drag at 60fps → 60 viewport updates/sec → 60 repaints/sec. Could cause performance issues.

**Mitigation**:
1. **Use Picture caching** (series layer already cached)
2. **Throttle updates** (max 1 update per 16ms = 60fps)
3. **Optimize coordinate conversions** (O(1) calculations only)
4. **RepaintBoundary** around chart canvas (isolate repaints)

**Implementation** (already done in existing architecture):
```dart
class ChartRenderBox extends RenderBox {
  Picture? _seriesLayerCache;
  
  @override
  void paint(PaintingContext context, Offset offset) {
    // Layer 1: Cached series (only repaint if data changes)
    if (_seriesLayerCache == null || _dataChanged) {
      _seriesLayerCache = _createSeriesLayerPicture();
    }
    context.canvas.drawPicture(_seriesLayerCache);
    
    // Layer 2: Dynamic axes (repaint on every viewport change)
    _paintAxes(context.canvas, size);
  }
}
```

---

## 📊 Time Breakdown

| Phase | Tasks | Est. Time | Notes |
|-------|-------|-----------|-------|
| **Phase 1: Core Widget Porting** | 4 tasks | 2-3 hours | Port files, simplify widget |
| **Phase 2: Integration** | 4 tasks | 1-2 hours | Layout, rendering, pixel-delta conversion |
| **Phase 3: Coordinator** | 3 tasks | 0.5-1 hour | Gesture priority, viewport sync |
| **Phase 4: Testing & Polish** | 4 tasks | 1-2 hours | Examples, testing, performance |
| **TOTAL** | **15 tasks** | **4.5-8 hours** | **Full feature set** |

**Conservative Estimate**: 6-8 hours (includes buffer for debugging)  
**Optimistic Estimate**: 4-5 hours (if no major issues)  
**Target**: Complete by 2025-11-20

---

## 🎯 Definition of Done

### Code Complete
- [ ] All 7 files ported to `lib/src_plus/widgets/scrollbar/`
- [ ] ChartScrollbar widget simplified (removed obsolete code)
- [ ] Integration with ChartRenderBox complete
- [ ] Coordinator integration complete
- [ ] Example app demonstrates all features

### Functionality Complete
- [ ] Horizontal scrollbar works (pan, zoom, track click)
- [ ] Vertical scrollbar works (pan, zoom, track click)
- [ ] Dual-axis scrollbars work (no overlap)
- [ ] Keyboard navigation works
- [ ] Auto-hide fades out after 2 seconds
- [ ] Accessibility features work (touch targets, contrast, keyboard)
- [ ] No conflicts with chart pan/zoom gestures

### Quality Complete
- [ ] Manual testing passed (all test scenarios)
- [ ] Performance validated (60fps, no memory leaks)
- [ ] Unit tests written and passing (15+ tests)
- [ ] Code reviewed and clean (no TODOs, no debug prints)

### Documentation Complete
- [ ] This plan document updated with final status
- [ ] Code comments in place for complex logic
- [ ] Example app demonstrates all scrollbar features
- [ ] Integration guide updated in 07-INCREMENTAL_MERGE_STRATEGY.md

---

## 📚 References

### Documentation
- **Architecture Analysis**: `docs/architecture/SCROLLBAR_ARCHITECTURE_ANALYSIS.md` (3000+ lines)
- **Merge Strategy**: `docs/refactor/core-interaction/07-INCREMENTAL_MERGE_STRATEGY.md`
- **Sprint Tasks**: `docs/refactor/SPRINT_TASKS.md`

### Source Files (BravenChart)
- `lib/src/widgets/chart_scrollbar.dart` (741 lines)
- `lib/src/widgets/scrollbar/scrollbar_controller.dart` (~200 lines)
- `lib/src/widgets/scrollbar/scrollbar_interaction.dart` (~50 lines)
- `lib/src/widgets/scrollbar/scrollbar_state.dart` (~200 lines)
- `lib/src/widgets/scrollbar/scrollbar_painter.dart` (~360 lines)
- `lib/src/widgets/scrollbar/hit_test_zone.dart` (~50 lines)
- `lib/src/theming/components/scrollbar_config.dart` (~350 lines)

### Destination Files (BravenChartPlus)
- `lib/src_plus/widgets/scrollbar/chart_scrollbar.dart` (to create)
- `lib/src_plus/widgets/scrollbar/scrollbar_controller.dart` (to create)
- `lib/src_plus/widgets/scrollbar/scrollbar_interaction.dart` (to create)
- `lib/src_plus/widgets/scrollbar/scrollbar_state.dart` (to create)
- `lib/src_plus/widgets/scrollbar/scrollbar_painter.dart` (to create)
- `lib/src_plus/widgets/scrollbar/hit_test_zone.dart` (to create)
- `lib/src_plus/theming/components/scrollbar_config.dart` (to create)

---

## ✅ Progress Tracking

**Status**: ⏳ Phase 1 - Task 1.2 In Progress  
**Started**: 2025-11-18  
**Target Completion**: 2025-11-20  
**Actual Completion**: TBD  

### Phase Completion

- [x] **Phase 1, Task 1.1: Port Pure Functions & Enums** (Complete - 15 minutes)
- [ ] **Phase 1, Task 1.2: Port State & Configuration** (In Progress)
- [ ] **Phase 1, Task 1.3: Port Custom Painter** (Not Started)
- [ ] **Phase 1, Task 1.4: Port Main Widget** (Not Started)
- [ ] **Phase 2: Integration** (0/4 tasks complete)
- [ ] **Phase 3: Coordinator** (0/3 tasks complete)
- [ ] **Phase 4: Testing & Polish** (0/4 tasks complete)

**Overall Progress**: 1/15 tasks complete (7%)

---

## 🚀 Next Steps

1. **Create directory structure**:
   ```powershell
   mkdir lib/src_plus/widgets/scrollbar
   mkdir lib/src_plus/theming/components
   ```

2. **Start Phase 1, Task 1.1**: Port pure functions & enums (30 min)

3. **Test after each task**: Compile check, verify imports

4. **Commit after each phase**: Small, reversible commits

5. **Update progress** in this document as tasks complete

---

**Document Status**: ✅ Planning Complete, Ready for Implementation  
**Created**: 2025-11-18  
**Last Updated**: 2025-11-18  
**Author**: AI Assistant (with user guidance)  
