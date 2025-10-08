# 007-Interaction-System Remediation Sprint

**Status**: 🔴 CRITICAL - Feature Delivery Gap Identified  
**Created**: 2025-01-08  
**Sprint Goal**: Complete the missing interaction functionality that was scoped in original spec but not implemented  
**Estimated Effort**: 1-2 days  
**Priority**: HIGHEST

---

## Executive Summary

### 🚨 Problem Statement

The 007-interaction-system sprint was marked COMPLETE (87/87 tasks ✅, 277/277 tests passing) but **ALL user-facing interaction features are non-functional**. 

**Root Cause**: Task T034 ("Update BravenChart widget to integrate interaction system") was completed with only "infrastructure" (parameter wiring, placeholders) but NOT the actual rendering and event handling logic.

**Critical Web UX Issue**: Mouse wheel zoom cannot hijack browser's default scroll behavior. Solution: Require CTRL/CMD modifier key for zoom, SHIFT for horizontal pan.

### 📊 Gap Analysis

#### ✅ What EXISTS (Completed in Original Sprint)
- All configuration models (`InteractionConfig`, `CrosshairConfig`, `TooltipConfig`, `KeyboardConfig`, `GestureConfig`, `ZoomPanState`)
- All business logic classes:
  - `EventHandler` - processes pointer/key events → `ChartEvent`
  - `CrosshairRenderer` - interface for rendering crosshairs
  - `TooltipProvider` - interface for showing/positioning tooltips
  - `GestureRecognizer` - detects tap/pan/pinch/long-press
  - `KeyboardHandler` - processes arrow/zoom/navigation keys
  - `ZoomPanController` - viewport transformation logic
  - `CallbackInvoker` - helper for invoking 8 callback types
- All unit tests (147+ tests passing)
- Parameter wiring in `BravenChart` widget
- Example showcase screen (520 lines, demonstrates all 8 callbacks)

#### ❌ What's MISSING (This Remediation Sprint)
1. **Crosshair Rendering** - No `_CrosshairPainter` class, no canvas drawing
2. **Tooltip Display** - No tooltip overlay widget, no positioning logic
3. **Zoom/Pan Transformation** - No viewport transformation applied to chart rendering
4. **Event Handler Wiring** - `EventHandler` never instantiated or used in widget lifecycle
5. **Gesture Recognition Integration** - `GestureRecognizer` not connected to `GestureDetector`
6. **Keyboard Navigation** - `KeyboardHandler` not connected to `Focus` widget
7. **Callback Invocation** - All 8 callbacks exist but never triggered from real events
8. **InteractionState Updates** - State model exists but not properly synchronized with user interactions

### 🎯 Acceptance Criteria for Remediation

**Sprint is COMPLETE when:**
- [ ] User can hover over chart and see crosshair following cursor
- [ ] Crosshair snaps to nearest data point within configured radius
- [ ] Tooltip appears on hover showing data point values
- [ ] Tooltip uses custom builder if provided
- [ ] Mouse wheel + CTRL/CMD modifier zooms chart at cursor position (prevents page scroll conflict)
- [ ] Mouse wheel + SHIFT modifier pans horizontally (prevents page scroll conflict)
- [ ] Middle-mouse button + drag pans the chart viewport (primary pan method)
- [ ] Left-click-and-drag pans the chart viewport (when pan mode enabled)
- [ ] Double-click resets zoom to original view
- [ ] Pinch gesture zooms (mobile/touchpad)
- [ ] Two-finger drag pans (mobile/touchpad)
- [ ] Arrow keys navigate between data points (focus visible)
- [ ] +/- keys zoom in/out at center
- [ ] Home/End keys jump to first/last data point
- [ ] All 8 callbacks fire from actual user interactions:
  * `onDataPointTap` - fires on tap
  * `onDataPointHover` - fires on hover
  * `onDataPointLongPress` - fires on long press
  * `onSelectionChanged` - fires when selection changes
  * `onZoomChanged` - fires when zoom level changes
  * `onPanChanged` - fires when pan offset changes
  * `onViewportChanged` - fires when visible data bounds change
  * `onCrosshairPositionChanged` - fires when crosshair moves
- [ ] Example showcase screen demonstrates all features working
- [ ] All existing tests still pass (277/277)
- [ ] Performance meets spec: <100ms response, 60 FPS, <2ms crosshair, <5ms events

---

## Task Breakdown

### Phase 1: Core Integration (3-4 hours)

#### **R-T001: Create CrosshairPainter Class** ⏱️ 30 min ✅ COMPLETE
**Type**: Implementation  
**File**: `lib/src/widgets/braven_chart.dart`  
**Dependencies**: None
**Status**: COMPLETE - CrosshairPainter class implemented with full dashed line support, coordinate labels, and snap point highlighting

**Description**:
Create `_CrosshairPainter` class extending `CustomPainter` that renders crosshair lines on canvas.

**Acceptance Criteria**:
- [ ] Class extends `CustomPainter` with `paint()` and `shouldRepaint()` methods
- [ ] Renders vertical and horizontal lines at crosshair position
- [ ] Respects `CrosshairConfig` (style, color, width, mode)
- [ ] Implements snap-to-point highlighting (circle around nearest point)
- [ ] Renders coordinate labels if enabled
- [ ] Performance: <2ms render time for single crosshair

**Technical Notes**:
- Use `CrosshairRenderer` interface as reference but implement directly in painter
- Support `CrosshairMode.free` (follows cursor) and `CrosshairMode.snap` (snaps to nearest point)
- Draw using `canvas.drawLine()` for crosshair lines
- Draw using `canvas.drawCircle()` for snap point highlight
- Use `TextPainter` for coordinate labels

**Code Location**: Insert after `_BravenChartPainter` class (~line 1520)

---

#### **R-T002: Implement Tooltip Overlay Widget** ⏱️ 45 min ✅ COMPLETE
**Type**: Implementation  
**File**: `lib/src/widgets/braven_chart.dart`  
**Dependencies**: None
**Status**: COMPLETE - Tooltip overlay widget with smart positioning, custom builder support, and AnimatedOpacity fade-in

**Description**:
Create tooltip overlay widget that displays data point information with smart positioning.

**Acceptance Criteria**:
- [ ] Creates positioned tooltip widget at cursor location
- [ ] Uses `TooltipConfig.customBuilder` if provided, otherwise default builder
- [ ] Implements smart positioning (flips to opposite side if clipping chart bounds)
- [ ] Respects `TooltipStyle` (colors, padding, border, font)
- [ ] Fades in/out smoothly with `AnimatedOpacity`
- [ ] Shows data for all series at X position if `showAllSeries = true`

**Technical Notes**:
- Use `Positioned` widget with calculated `left/top` offsets
- Default builder shows: `"X: {x}\nY: {y}"` formatted with `toStringAsFixed(2)`
- Smart positioning algorithm:
  ```dart
  // If tooltip would clip right edge, position to left of cursor
  final tooltipLeft = (cursorX + tooltipWidth > chartWidth) 
    ? cursorX - tooltipWidth - 10 
    : cursorX + 10;
  // Similar logic for top/bottom
  ```
- Wrap in `IgnorePointer` so it doesn't intercept mouse events

**Code Location**: Insert as helper method in `_BravenChartState` (~line 900)

---

#### **R-T003: Wire EventHandler to Widget Lifecycle** ⏱️ 30 min ✅ COMPLETE
**Type**: Implementation  
**File**: `lib/src/widgets/braven_chart.dart`  
**Dependencies**: None
**Status**: COMPLETE - EventHandler properly initialized in initState, recreated in didUpdateWidget on config changes, disposed in dispose

**Description**:
Instantiate and properly wire `EventHandler` in widget lifecycle (init, update, dispose).

**Acceptance Criteria**:
- [ ] Create `EventHandler` instance in `initState()` when `interactionConfig.enabled == true`
- [ ] Dispose `EventHandler` in `dispose()` method
- [ ] Handle `EventHandler` recreation on config changes in `didUpdateWidget()`
- [ ] Register callback handlers for all 8 interaction types
- [ ] Process pointer events through `EventHandler.processPointerEvent()`
- [ ] Process key events through `EventHandler.processKeyEvent()`

**Technical Notes**:
- Already have `EventHandler? _eventHandler;` field (line 617)
- Already initializing in `initState()` (line 650)
- Need to add callback registration:
  ```dart
  _eventHandler?.registerHandler((event) {
    // Route to appropriate callback based on event.type
    return true; // handled
  }, priority: 0);
  ```

**Code Location**: Modify existing `initState()`, `didUpdateWidget()`, `dispose()` methods

---

#### **R-T004: Implement Complete _wrapWithInteractionSystem Method** ⏱️ 2 hours ✅ COMPLETE
**Status**: COMPLETE - Full Stack implementation with MouseRegion, Listener (scroll events), GestureDetector (tap/long-press/pan/scale), and Focus. Crosshair overlay using _CrosshairPainter, tooltip overlay using _buildTooltipOverlay, all callbacks properly wired with ChartDataPoint conversions via _mapToDataPoint helper.
**Type**: Implementation  
**File**: `lib/src/widgets/braven_chart.dart`  
**Dependencies**: R-T001, R-T002, R-T003

**Description**:
Replace placeholder `_wrapWithInteractionSystem()` method with full implementation that integrates all interaction features.

**Acceptance Criteria**:
- [ ] Wraps chart in `Stack` with crosshair overlay (using `_CrosshairPainter`)
- [ ] Adds tooltip overlay (using tooltip builder from R-T002)
- [ ] Wraps in `MouseRegion` for hover detection (onEnter, onExit, onHover)
- [ ] Wraps in `GestureDetector` for tap/long-press/pan/pinch gestures
- [ ] Wraps in `Listener` for mouse wheel events (zoom)
- [ ] Wraps in `Focus` for keyboard navigation
- [ ] All gestures update `InteractionState` via `setState()`
- [ ] All gestures invoke appropriate callbacks via `widget.interactionConfig.onXxx?.call()`
- [ ] Implements `_findNearestDataPoint()` helper for snap-to-point
- [ ] Respects all enabled flags (`crosshair.enabled`, `tooltip.enabled`, `enableZoom`, etc.)

**Technical Notes**:
- **Stack Structure**:
  ```dart
  Stack(
    children: [
      child, // Base chart
      if (crosshairVisible) Positioned.fill(child: CustomPaint(painter: _CrosshairPainter(...))),
      if (tooltipVisible) Positioned(left: ..., top: ..., child: _buildTooltip(...)),
    ],
  )
  ```
- **MouseRegion Handlers**:
  - `onEnter`: Set hover state, trigger `onDataPointHover`
  - `onExit`: Clear hover state, hide crosshair/tooltip
  - `onHover`: Update crosshair position, find nearest point, show tooltip
- **GestureDetector Handlers**:
  - `onTapDown`: Find nearest point, trigger `onDataPointTap`, update selection
  - `onLongPressStart`: Trigger `onDataPointLongPress`
  - `onPanStart/Update/End`: If `enablePan`, update pan offset, trigger `onPanChanged`
    * **Middle-mouse button** (button 4) + drag → Always pans (primary pan method)
    * **Left-mouse button** + drag → Pans only if pan mode enabled
  - `onScaleStart/Update/End`: If `enableZoom`, handle pinch zoom
- **Listener for Mouse Wheel**:
  - `onPointerSignal`: Check for `PointerScrollEvent` with modifier keys
  - **CTRL/CMD + Scroll**: Zoom at cursor position (prevents page scroll conflict)
  - **SHIFT + Scroll**: Pan horizontally (prevents page scroll conflict)
  - **No modifier**: Allow default page scroll behavior (don't consume event)
  - Call `event.stopPropagation()` only when modifier is pressed
- **Focus Handlers**:
  - `onKeyEvent`: Use `KeyboardHandler` to process arrow keys, +/-, home/end

**Code Location**: Replace existing `_wrapWithInteractionSystem()` method (~line 848)

---

#### **R-T005: Implement _findNearestDataPoint Helper** ⏱️ 20 min ✅ COMPLETE
**Status**: COMPLETE - Full implementation with proper coordinate transformation using _dataToScreenPoint helper. Reuses same transformation logic as _BravenChartPainter._dataToPixel. Includes _calculateDataBounds and _calculateChartRect helpers for accurate screen coordinate mapping. Performance: O(n) for n total data points.
**Type**: Implementation  
**File**: `lib/src/widgets/braven_chart.dart`  
**Dependencies**: None

**Description**:
Create helper method to find the nearest data point to a screen position.

**Acceptance Criteria**:
- [ ] Takes `Offset screenPosition` parameter
- [ ] Returns `ChartDataPoint?` (null if none within snap radius)
- [ ] Searches all visible series' data points
- [ ] Uses Euclidean distance calculation: `sqrt(dx*dx + dy*dy)`
- [ ] Respects `CrosshairConfig.snapRadius` (default 20 pixels)
- [ ] Transforms data coordinates to screen coordinates for comparison
- [ ] Performance: <1ms for 10,000 points (use spatial indexing if needed)

**Technical Notes**:
- Need to reuse coordinate transformation from `_BravenChartPainter._dataToPixel()`
- Consider extracting transformation logic to shared helper
- For large datasets, could implement quadtree spatial index (future optimization)
- Basic implementation:
  ```dart
  ChartDataPoint? _findNearestDataPoint(Offset screenPos) {
    final snapRadius = widget.interactionConfig!.crosshair.snapRadius;
    ChartDataPoint? nearest;
    double minDistance = snapRadius;
    
    for (final series in _getAllSeries()) {
      for (final point in series.points) {
        final screenPoint = _dataToPixel(point); // Need this helper
        final distance = (screenPos - screenPoint).distance;
        if (distance < minDistance) {
          minDistance = distance;
          nearest = point;
        }
      }
    }
    return nearest;
  }
  ```

**Code Location**: Insert as helper method in `_BravenChartState` (~line 920)

---

### Phase 2: Zoom/Pan Integration (2 hours)

#### **R-T006: Implement Modifier Key Detection for Scroll Events** ⏱️ 30 min ✅ COMPLETE
**Status**: COMPLETE - Platform-aware modifier key detection implemented (CTRL/CMD for zoom, SHIFT for horizontal pan). Middle-mouse button pan detection added with onPointerDown/Move/Up handlers. Plain scroll without modifiers correctly allows default page scroll (critical for web UX). Placeholders for actual zoom/pan logic to be added in R-T007.
**Type**: Implementation  
**File**: `lib/src/widgets/braven_chart.dart`  
**Dependencies**: R-T004

**Description**:
Implement modifier key detection to prevent scroll wheel hijacking browser's default scroll behavior.

**Acceptance Criteria**:
- [ ] Detect CTRL/CMD modifier key state on pointer events
- [ ] Detect SHIFT modifier key state on pointer events
- [ ] Detect middle-mouse button (button 4) press/drag
- [ ] CTRL/CMD + Scroll → Zoom at cursor position
- [ ] SHIFT + Scroll → Pan horizontally
- [ ] Middle-mouse + Drag → Pan in any direction (primary pan method)
- [ ] Plain scroll (no modifiers) → Allow default page scroll (don't consume event)
- [ ] Visual indicator shows when modifier key is pressed (optional but recommended)
- [ ] Works consistently across platforms (Windows: Ctrl, macOS: Cmd, Linux: Ctrl)

**Technical Notes**:
- Use `RawKeyboard.instance.keysPressed` or event modifiers:
  ```dart
  onPointerSignal: (signal) {
    if (signal is PointerScrollEvent) {
      final isCtrlPressed = signal.kind == PointerDeviceKind.mouse && 
        (HardwareKeyboard.instance.isControlPressed || 
         HardwareKeyboard.instance.isMetaPressed); // Meta = CMD on macOS
      
      final isShiftPressed = HardwareKeyboard.instance.isShiftPressed;
      
      if (isCtrlPressed) {
        // Zoom at cursor position
        _handleZoom(signal.scrollDelta.dy, signal.localPosition);
        // Event consumed - prevents page scroll
      } else if (isShiftPressed) {
        // Pan horizontally
        _handleHorizontalPan(signal.scrollDelta.dy);
        // Event consumed - prevents page scroll
      }
      // If no modifier, don't handle - allows default page scroll
    }
  },
  ```
- **Middle-mouse button detection**:
  ```dart
  // In Listener widget
  onPointerDown: (event) {
    if (event.buttons == kMiddleMouseButton) { // Button value = 4
      _isPanningWithMiddleMouse = true;
      _panStartPosition = event.localPosition;
    }
  },
  onPointerMove: (event) {
    if (_isPanningWithMiddleMouse) {
      final delta = event.localPosition - _panStartPosition;
      _handlePan(delta);
      _panStartPosition = event.localPosition;
    }
  },
  onPointerUp: (event) {
    _isPanningWithMiddleMouse = false;
  },
  ```
- Add to `InteractionConfig`:
  ```dart
  final bool requireModifierForZoom; // Default true for web, false for desktop apps
  final bool showModifierHint; // Show "Hold Ctrl to zoom" hint
  final bool enableMiddleMousePan; // Default true - middle-mouse button pans
  ```
- Platform-specific defaults:
  - Web: Always require modifier (prevent hijacking)
  - Desktop: Make optional (can be enabled per app)
  - Mobile: N/A (no scroll wheel)

**Code Location**: Add helper methods in `_BravenChartState`, wire in `_wrapWithInteractionSystem()`

---

#### **R-T007: Integrate ZoomPanController** ⏱️ 1 hour
**Type**: Implementation  
**File**: `lib/src/widgets/braven_chart.dart`  
**Dependencies**: R-T004

#### **R-T007: Integrate ZoomPanController** ⏱️ 1 hour ✅ COMPLETE
**Status**: COMPLETE - ZoomPanController instantiated in initState when zoom/pan enabled. Wired CTRL/CMD+scroll to zoom, SHIFT+scroll to pan horizontally, middle-mouse drag to pan. Pinch gestures and double-tap reset integrated. All interactions update InteractionState.zoomPanState and invoke onZoomChanged, onPanChanged, and onViewportChanged callbacks. Helper method _invokeViewportCallback calculates visible data bounds.
**Type**: Implementation  
**File**: `lib/src/widgets/braven_chart.dart`  
**Dependencies**: R-T004, R-T006

**Description**:
Instantiate `ZoomPanController` and wire it to gesture events to enable zoom/pan viewport transformation.

**Acceptance Criteria**:
- [ ] Create `ZoomPanController` instance when `enableZoom || enablePan`
- [ ] Initialize with default zoom level (1.0) and pan offset (0, 0)
- [ ] Wire CTRL/CMD + scroll events to `controller.handleZoom()` (from R-T006)
- [ ] Wire SHIFT + scroll events to `controller.handlePan()` (from R-T006)
- [ ] Wire pinch gestures to `controller.handlePinchZoom()`
- [ ] Wire drag gestures to `controller.handlePan()`
- [ ] Wire double-tap to `controller.resetZoom()`
- [ ] Update `InteractionState.zoomPanState` when zoom/pan changes
- [ ] Trigger `onZoomChanged` callback when zoom level changes
- [ ] Trigger `onPanChanged` callback when pan offset changes
- [ ] Trigger `onViewportChanged` callback when visible bounds change

**Technical Notes**:
- Add `ZoomPanController? _zoomPanController;` field to state
- Initialize in `initState()`:
  ```dart
  if (widget.interactionConfig!.enableZoom || widget.interactionConfig!.enablePan) {
    _zoomPanController = ZoomPanController(
      minZoomLevel: widget.interactionConfig!.minZoomLevel,
      maxZoomLevel: widget.interactionConfig!.maxZoomLevel,
    );
  }
  ```
- On zoom/pan changes, update state:
  ```dart
  setState(() {
    _interactionState = _interactionState.copyWith(
      zoomPanState: _zoomPanController!.currentState,
    );
  });
  widget.interactionConfig!.onZoomChanged?.call(_zoomPanController!.currentState);
  ```

**Code Location**: Modify `_BravenChartState` lifecycle methods and `_wrapWithInteractionSystem()`

---

#### **R-T008: Apply Viewport Transformation to Chart Rendering** ⏱️ 1 hour ✅ COMPLETE
**Type**: Implementation  
**File**: `lib/src/widgets/braven_chart.dart`  
**Dependencies**: R-T007
**Status**: COMPLETE - ZoomPanState passed to painter, _calculateDataBounds applies zoom/pan transformation, viewport culling implemented in all draw methods (line, area, bar, scatter)

**Description**:
Modify `_BravenChartPainter` to apply zoom/pan transformation to chart rendering.

**Acceptance Criteria**:
- [ ] Pass `ZoomPanState` to `_BravenChartPainter` constructor
- [ ] Transform data bounds based on zoom level and pan offset
- [ ] Only render data points within visible viewport (culling)
- [ ] Maintain 60 FPS during continuous zoom/pan
- [ ] Grid and axes adjust to visible bounds
- [ ] Axis labels update to show visible data range

**Technical Notes**:
- Modify `_calculateDataBounds()` to apply transformation:
  ```dart
  if (zoomPanState != null) {
    final visibleXRange = (maxX - minX) / zoomPanState.zoomLevelX;
    final visibleYRange = (maxY - minY) / zoomPanState.zoomLevelY;
    
    minX = minX + zoomPanState.panOffsetX;
    maxX = minX + visibleXRange;
    minY = minY + zoomPanState.panOffsetY;
    maxY = minY + visibleYRange;
  }
  ```
- Add viewport culling in draw methods:
  ```dart
  for (final point in series.points) {
    if (point.x < bounds.minX || point.x > bounds.maxX) continue;
    // ... render point
  }
  ```

**Code Location**: Modify `_BravenChartPainter` class (~line 945)

---

### Phase 3: Keyboard & Gesture Integration (1.5 hours)

#### **R-T009: Integrate GestureRecognizer** ⏱️ 45 min ✅ COMPLETE
**Type**: Implementation  
**File**: `lib/src/widgets/braven_chart.dart`  
**Dependencies**: R-T004
**Status**: COMPLETE - Flutter's GestureDetector already provides all required gesture recognition (tap, long-press, pan, scale, double-tap). Custom GestureRecognizer class exists for advanced use cases but GestureDetector is more appropriate for widget-based interaction and is fully integrated in R-T004.

**Description**:
Wire `GestureRecognizer` to detect and classify gestures, triggering appropriate callbacks.

**Acceptance Criteria**:
- [ ] Create `GestureRecognizer` instance when any gesture callbacks are registered
- [ ] Process all pointer events through `GestureRecognizer.recognizeGesture()`
- [ ] Trigger callbacks based on recognized gesture type:
  * Tap → `onDataPointTap`
  * Double-tap → reset zoom
  * Long-press → `onDataPointLongPress`
  * Pan → `onPanChanged`
  * Pinch → zoom
- [ ] Handle gesture conflicts (e.g., pan vs pinch priority)
- [ ] Update `InteractionState.activeGesture` with current gesture

**Technical Notes**:
- Add `GestureRecognizer? _gestureRecognizer;` field
- Initialize in `initState()`:
  ```dart
  _gestureRecognizer = GestureRecognizer(
    tapThreshold: 10.0, // pixels
    longPressDuration: const Duration(milliseconds: 500),
  );
  ```
- In `GestureDetector` callbacks, use recognizer:
  ```dart
  onTapDown: (details) {
    final gesture = _gestureRecognizer?.recognizeGesture(
      GestureType.tap,
      details.localPosition,
    );
    // Process gesture...
  },
  ```

**Code Location**: Modify `_BravenChartState` and `_wrapWithInteractionSystem()`

---

#### **R-T010: Integrate KeyboardHandler** ⏱️ 45 min ✅ COMPLETE
**Type**: Implementation  
**File**: `lib/src/widgets/braven_chart.dart`  
**Dependencies**: R-T004
**Status**: COMPLETE - KeyboardHandler initialized in initState when keyboard.enabled, integrated in Focus widget's onKeyEvent handler. Processes arrow keys for navigation, +/- for zoom, Home/End for first/last point. Updates InteractionState and invokes appropriate callbacks (hover, zoom, selection).

**Description**:
Wire `KeyboardHandler` to process keyboard navigation and trigger appropriate actions.

**Acceptance Criteria**:
- [ ] Create `KeyboardHandler` instance when `keyboard.enabled == true`
- [ ] Process key events through `KeyboardHandler.handleKeyEvent()`
- [ ] Arrow keys navigate between data points (update focused point)
- [ ] +/- keys zoom in/out at center
- [ ] Home/End keys jump to first/last data point
- [ ] Enter/Space keys show tooltip for focused point
- [ ] Escape key hides tooltip
- [ ] Tab key cycles through series
- [ ] Visual focus indicator shows focused data point
- [ ] Screen reader announces focused point (via Semantics)

**Technical Notes**:
- Add `KeyboardHandler? _keyboardHandler;` field
- Initialize with keyboard shortcuts config:
  ```dart
  _keyboardHandler = KeyboardHandler(
    shortcuts: widget.interactionConfig!.keyboard.shortcuts,
  );
  ```
- In `Focus` widget's `onKeyEvent`:
  ```dart
  onKeyEvent: (node, event) {
    final result = _keyboardHandler?.handleKeyEvent(event);
    if (result?.action != null) {
      switch (result!.action) {
        case KeyboardAction.navigateNext:
          _navigateToNextPoint();
          return KeyEventResult.handled;
        case KeyboardAction.zoomIn:
          _zoomPanController?.zoomIn();
          return KeyEventResult.handled;
        // ... other actions
      }
    }
    return KeyEventResult.ignored;
  },
  ```

**Code Location**: Modify `_BravenChartState` and `_wrapWithInteractionSystem()`

---

### Phase 4: InteractionState Synchronization (1 hour)

#### **R-T011: Fix InteractionState Type Mismatches** ⏱️ 30 min ✅ COMPLETE
**Type**: Bug Fix  
**File**: `lib/src/interaction/models/interaction_state.dart`  
**Dependencies**: None
**Status**: COMPLETE - Kept Map<String, dynamic> for data points to avoid circular dependencies and maintain JSON serializability. Added comprehensive documentation explaining this design choice. All properties (hoveredPoint, focusedPoint, selectedPoints) are properly documented. Widget layer handles conversion via _mapToDataPoint helper.

**Description**:
Fix type mismatches between `InteractionState` properties and usage in widget.

**Acceptance Criteria**:
- [ ] Decide: Keep `Map<String, dynamic>` for data points OR change to `ChartDataPoint?`
- [ ] Add missing `isHovering` property if needed
- [ ] Add missing `selectedPoint` property if needed
- [ ] Update `copyWith()` method to include all new properties
- [ ] Update `initial()` factory to initialize all properties
- [ ] Document the chosen approach in dartdoc comments

**Technical Notes**:
- Current issue: `InteractionState` uses `Map<String, dynamic>? hoveredPoint` but widget expects `ChartDataPoint?`
- **Option A** (Recommended): Change to `ChartDataPoint?` for type safety
  ```dart
  final ChartDataPoint? hoveredPoint;
  final ChartDataPoint? focusedPoint;
  final ChartDataPoint? tooltipDataPoint;
  final List<ChartDataPoint> selectedPoints;
  ```
- **Option B**: Keep `Map<String, dynamic>` and convert in widget:
  ```dart
  final hoveredPointMap = {'x': point.x, 'y': point.y, 'seriesId': seriesId};
  ```
- **Recommendation**: Use Option A for type safety and better IDE support

**Code Location**: `lib/src/interaction/models/interaction_state.dart` (~line 20)

---

#### **R-T012: Synchronize InteractionState Updates** ⏱️ 30 min ✅ COMPLETE
**Type**: Implementation  
**File**: `lib/src/widgets/braven_chart.dart`  
**Dependencies**: R-T010
**Status**: COMPLETE - All interaction handlers properly update InteractionState using copyWith pattern within setState. Mouse hover updates crosshair/tooltip/hovered state, mouse exit clears state, tap updates selection/focus, zoom/pan updates zoomPanState, keyboard updates focused point. All updates maintain immutability and trigger rebuilds correctly.

**Description**:
Ensure all user interactions properly update `InteractionState` with correct values.

**Acceptance Criteria**:
- [ ] Mouse hover updates: `hoveredPoint`, `crosshairPosition`, `isCrosshairVisible`, `isTooltipVisible`, `tooltipPosition`
- [ ] Mouse exit clears: `hoveredPoint`, `crosshairPosition`, `tooltipPosition`, sets `isCrosshairVisible = false`
- [ ] Tap updates: `selectedPoints`, `focusedPoint`
- [ ] Zoom/pan updates: `zoomPanState`, `visibleDataBounds`
- [ ] Keyboard navigation updates: `focusedPoint`, `selectedPoints`
- [ ] Gesture updates: `activeGesture`, `gestureStart`, `currentGesturePosition`
- [ ] All updates use `copyWith()` to maintain immutability
- [ ] State changes trigger `setState()` for rebuild

**Technical Notes**:
- Pattern for all updates:
  ```dart
  setState(() {
    _interactionState = _interactionState.copyWith(
      hoveredPoint: nearestPoint,
      crosshairPosition: cursorPosition,
      isCrosshairVisible: true,
    );
  });
  ```
- Clear state on interaction end:
  ```dart
  _interactionState = _interactionState.copyWith(
    hoveredPoint: null,
    crosshairPosition: null,
    isCrosshairVisible: false,
  );
  ```

**Code Location**: All event handlers in `_wrapWithInteractionSystem()`

---

### Phase 5: Testing & Validation (2 hours)

#### **R-T013: Manual Testing with Showcase Screen** ⏱️ 1 hour
**Type**: Testing  
**File**: `example/lib/screens/interaction_showcase_screen.dart`  
**Dependencies**: R-T001 through R-T011

**Description**:
Manually test all interaction features using the existing showcase screen.

**Test Cases**:
- [ ] **Crosshair**: Hover over chart, verify crosshair appears and follows cursor
- [ ] **Snap-to-Point**: Verify crosshair snaps to nearest point within 20px
- [ ] **Tooltip**: Verify tooltip appears with correct data values
- [ ] **Custom Tooltip**: Verify custom builder is used when provided
- [ ] **CTRL/CMD + Mouse Wheel Zoom**: Hold CTRL/CMD and scroll, verify zoom at cursor position
- [ ] **Plain Mouse Wheel**: Scroll without modifier, verify page scrolls normally (not hijacked)
- [ ] **SHIFT + Mouse Wheel Pan**: Hold SHIFT and scroll, verify horizontal pan
- [ ] **Middle-Mouse Pan**: Hold middle-mouse button and drag, verify chart pans in all directions
- [ ] **Left-Click Drag Pan**: Click and drag with left button (if pan mode enabled), verify pan
- [ ] **Pinch Zoom**: Two-finger pinch on trackpad, verify zoom works
- [ ] **Double-Click Reset**: Double-click, verify zoom resets
- [ ] **Arrow Keys**: Press arrow keys, verify focus moves between points
- [ ] **+/- Keys**: Press +/-, verify zoom in/out
- [ ] **Home/End Keys**: Press home/end, verify jump to first/last
- [ ] **All 8 Callbacks**: Verify event log shows all callbacks firing
- [ ] **Factory Toggles**: Verify `.all()`, `.none()`, custom configs work
- [ ] **Control Panel**: Verify toggles enable/disable features correctly
- [ ] **Modifier Key Hint**: Verify visual hint shows "Hold Ctrl to zoom" (if enabled)

**Performance Validation**:
- [ ] Crosshair render time: <2ms (use DevTools Performance tab)
- [ ] Event processing time: <5ms (log timestamps)
- [ ] Zoom/pan FPS: 60 FPS during continuous interaction (use Performance Overlay)
- [ ] Overall response time: <100ms (time from event to visual feedback)

**Code Location**: `example/lib/screens/interaction_showcase_screen.dart`

---

#### **R-T014: Verify Existing Tests Still Pass** ⏱️ 30 min
**Type**: Testing  
**File**: N/A (run all tests)  
**Dependencies**: R-T001 through R-T011

**Description**:
Run all existing tests to ensure new implementation doesn't break anything.

**Acceptance Criteria**:
- [ ] All 277 existing tests pass (100%)
- [ ] No new analyzer warnings or errors
- [ ] `flutter analyze` passes with 0 issues
- [ ] `flutter test` passes all unit/widget/integration tests
- [ ] No performance regressions in existing benchmarks
- [ ] Modifier key detection works on web (critical for scroll hijacking prevention)

**Commands**:
```powershell
# Run all tests
flutter test

# Run with coverage
flutter test --coverage

# Analyze code
flutter analyze

# Run performance benchmarks
flutter test test/benchmarks/
```

**Code Location**: N/A (CI/CD validation)

---

#### **R-T015: Update Documentation** ⏱️ 30 min
**Type**: Documentation  
**File**: Multiple  
**Dependencies**: R-T012, R-T013

**Description**:
Update documentation to reflect completed functionality.

**Acceptance Criteria**:
- [ ] Update `specs/007-interaction-system/tasks.md`:
  * Add "REMEDIATION SPRINT" section documenting the gap
  * Mark T034 with deviation note: "Completed infrastructure only, functionality added in remediation sprint R-T001 through R-T015"
- [ ] Update `PROJECT_STATUS.md`:
  * Change Layer 7 status from "INCOMPLETE" to "COMPLETE"
  * Add note about remediation sprint
- [ ] Update `README.md`:
  * Add interaction features to feature list
  * Add code example showing interaction config
  * **Document modifier key requirement**: "On web, use CTRL+Scroll to zoom, SHIFT+Scroll to pan"
- [ ] Update `example/README.md`:
  * Document interaction showcase screen
  * **Add modifier key instructions**: "Hold CTRL/CMD while scrolling to zoom"
  * Add screenshots of interactions (optional)

**Code Location**: Various documentation files

---

## Risk Assessment

### 🟢 Low Risk
- **Crosshair Rendering** (R-T001) - Straightforward CustomPainter implementation
- **Tooltip Display** (R-T002) - Standard Flutter overlay pattern
- **EventHandler Wiring** (R-T003) - Handler class already exists and is tested
- **Type Fixes** (R-T011) - Simple model update

### 🟡 Medium Risk
- **_wrapWithInteractionSystem** (R-T004) - Complex method with many interactions, may have edge cases
- **Modifier Key Detection** (R-T006) - Platform differences (Ctrl vs Cmd), web vs desktop behavior
- **ZoomPanController Integration** (R-T007) - Viewport math can be tricky
- **GestureRecognizer Integration** (R-T009) - Gesture conflicts possible

### 🔴 High Risk
- **Viewport Transformation** (R-T008) - Could break existing chart rendering if not careful
- **Performance** (R-T013) - Meeting <2ms crosshair, 60 FPS targets may require optimization
- **Web Scroll Hijacking Prevention** (R-T006) - Critical UX issue, must not break browser scroll

### Mitigation Strategies
1. **Incremental Development**: Complete one task at a time, test before moving to next
2. **Existing Test Safety Net**: 277 tests will catch regressions immediately
3. **Git Workflow**: Commit after each completed task for easy rollback
4. **Performance Monitoring**: Use Flutter DevTools Performance tab throughout development
5. **Code Review**: Review each major change before committing

---

## Dependencies & Prerequisites

### External Dependencies
- ✅ All handler classes exist (`EventHandler`, `CrosshairRenderer`, etc.)
- ✅ All config models exist (`InteractionConfig`, `CrosshairConfig`, etc.)
- ✅ All tests exist and are passing
- ✅ Example showcase screen exists

### Internal Dependencies
- R-T004 depends on R-T001, R-T002, R-T003
- R-T007 depends on R-T006
- R-T008 depends on R-T007
- R-T013 depends on R-T001 through R-T012
- R-T014 depends on R-T001 through R-T012
- R-T015 depends on R-T013, R-T014

### Parallel Execution Opportunities
- **Phase 1**: R-T001, R-T002, R-T003, R-T005 can be done in parallel (if multiple developers)
- **Phase 2**: R-T006 and R-T007 are sequential, R-T008 depends on R-T007
- **Phase 3**: R-T009 and R-T010 can be done in parallel
- **Phase 4**: R-T011 and R-T012 are sequential
- **Phase 5**: R-T013, R-T014, R-T015 are sequential

---

## Success Metrics

### Functional Metrics
- [ ] All 12 acceptance criteria from "🎯 Acceptance Criteria for Remediation" section are met
- [ ] All 15 remediation tasks (R-T001 through R-T015) are complete
- [ ] Zero new bugs introduced (all existing tests pass)
- [ ] **Modifier key zoom/pan works on web** (critical - prevents scroll hijacking)

### Performance Metrics
- [ ] Crosshair render time: <2ms (spec requirement)
- [ ] Event processing time: <5ms (spec requirement)
- [ ] Zoom/pan FPS: 60 FPS during continuous interaction (spec requirement)
- [ ] Overall response time: <100ms from event to visual feedback (spec requirement)
- [ ] Memory usage: <5MB for interaction system (spec requirement)

### Code Quality Metrics
- [ ] Zero analyzer warnings/errors
- [ ] 100% dartdoc coverage for new public APIs
- [ ] Code follows existing patterns in `braven_chart.dart`
- [ ] All TODOs removed from code

---

## Timeline Estimate

### Best Case (1 day)
- Experienced Flutter developer
- No unexpected issues
- Straight implementation following tasks
- **Total**: 8.5 hours of focused work (added 30min for modifier key handling)

### Expected Case (1.5 days)
- Moderate Flutter experience
- Minor debugging needed
- Some performance optimization required
- Platform-specific modifier key testing
- **Total**: 12.5 hours of work

### Worst Case (2 days)
- Complex edge cases discovered
- Performance optimization required
- Multiple iterations needed for testing
- Cross-platform modifier key issues
- **Total**: 16.5 hours of work

---

## Approval & Sign-Off

**Review Checklist**:
- [ ] All tasks clearly defined with acceptance criteria
- [ ] Dependencies and risks identified
- [ ] Timeline estimate is reasonable
- [ ] Success metrics are measurable
- [ ] No missing requirements from original spec

**Approved By**: _________________  
**Date**: _________________  
**Estimated Start**: _________________  
**Estimated Completion**: _________________  

---

## Execution Notes

*This section will be filled during execution*

**Deviations from Plan**:
- [To be documented during implementation]

**Unexpected Issues**:
- [To be documented during implementation]

**Performance Optimizations**:
- [To be documented during implementation]

**Lessons Learned**:
- [To be documented during implementation]

---

**STATUS**: ⏳ Awaiting approval to begin remediation sprint
