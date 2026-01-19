# Zoom & Pan Architecture Design

**Date**: November 6, 2025  
**Status**: Design Phase  
**Purpose**: Add zoom and pan capabilities to the interaction prototype while preserving all existing priority-based hit testing and element interactions.

---

## 1. Core Problem

### Current State
- All coordinates are in **screen space** (pixel coordinates on canvas)
- Elements store their positions directly as rendered
- QuadTree uses screen coordinates
- Hit testing uses screen coordinates
- No concept of data space vs. screen space

### Target State
- Introduce **two coordinate spaces**:
  - **Data Space**: Unchanging, where elements live (e.g., time=100, price=50)
  - **Screen Space**: After pan/zoom transforms (e.g., pixel x=250, y=150)
- Store element positions in data space
- Transform only during rendering and hit testing
- QuadTree continues to use data space coordinates
- Support smooth pan and zoom gestures

---

## 2. Architecture Components

### 2.1 ChartTransform Class

**Purpose**: Bidirectional coordinate transformation between data space and screen space.

**Responsibilities**:
- Maintain data viewport (visible portion of data space)
- Maintain screen viewport (rendering area size)
- Compute scale and translation factors
- Convert data ↔ screen coordinates
- Handle pan operations (shift data viewport)
- Handle zoom operations (resize data viewport around a point)
- Constrain viewport to data bounds

**Key Operations**:
```dart
class ChartTransform {
  Rect _dataViewport;       // Visible portion of data space
  Rect _screenViewport;     // Rendering area
  
  // Cached transformation factors
  double _scaleX, _scaleY;
  double _translateX, _translateY;
  
  Offset dataToScreen(Offset dataPoint);
  Offset screenToData(Offset screenPoint);
  
  void panByScreenDelta(Offset screenDelta);
  void zoomAroundScreenPoint(Offset screenPoint, double factor);
  void setDataViewport(Rect viewport);
}
```

### 2.2 Updated ChartRenderBox

**New Responsibilities**:
- Own a `ChartTransform` instance
- Handle pan gestures (left-click drag on empty space)
- Handle zoom gestures (mouse wheel)
- Transform screen coordinates to data coordinates for hit testing
- Transform data coordinates to screen coordinates for painting
- Scale hit tolerance by zoom level

**Interaction Flow**:
```
1. User clicks at screen(250, 150)
2. Convert to data(100, 50) via transform.screenToData()
3. Query QuadTree with data coordinates + scaled tolerance
4. Check element.hitTest() with data coordinates
5. If hit → select element
6. If miss → start pan operation
```

**Paint Flow**:
```
1. Query QuadTree with visible data viewport
2. For each visible element:
   - Get element's data position
   - Convert to screen position via transform.dataToScreen()
   - Paint at screen position
```

### 2.3 Updated ChartElement Interface

**Changes**:
- `Rect get bounds` → now returns bounds in **data space**
- `bool hitTest(Offset position)` → receives position in **data space**
- `void paint(Canvas canvas, Size size)` → paints at **screen coordinates** (converted by RenderBox)

**Migration Strategy**:
- Elements already store positions (currently screen space)
- These become data space positions (no code change needed for now since we start with identity transform)
- Elements don't need to know about transforms - RenderBox handles conversion

### 2.4 Pan Gesture Handling

**Requirements** (from conflict resolution rules):
- Left-click drag on empty space = pan
- Cursor: `grab` when hovering, `grabbing` when panning
- Should NOT interfere with:
  - Datapoint drag
  - Annotation drag/resize
  - Box selection

**State Machine**:
```
IDLE:
  - Left-click on empty space → PANNING (record start position)
  - Left-click on element → SELECTING/DRAGGING (existing behavior)

PANNING:
  - Mouse move → Update data viewport via transform.panByScreenDelta()
  - Mouse up → IDLE
  - Right-click → Cancel pan, return to IDLE
```

**Implementation Approach**:
```dart
// In _handlePointerDown():
if (hitElement == null && event.buttons == kPrimaryMouseButton) {
  // Empty space click
  if (coordinator.allowsPanning) {
    coordinator.startPanning();
    _panStartPosition = position;
  }
}

// In _handlePointerMove():
if (coordinator.currentMode == InteractionMode.panning) {
  final delta = event.delta;
  _transform.panByScreenDelta(delta);
  markNeedsPaint();
}

// In _handlePointerUp():
if (coordinator.currentMode == InteractionMode.panning) {
  coordinator.endPanning();
  _panStartPosition = null;
}
```

### 2.5 Zoom Gesture Handling

**Requirements**:
- Mouse wheel = zoom in/out
- Zoom around mouse cursor position (keep point under mouse stationary)
- Zoom constraints: min 0.1x, max 10.0x
- Cursor: `SystemMouseCursors.grab` (or custom zoom cursors if needed)

**Zoom Behavior**:
```
User scrolls wheel at screen position S:
1. Convert S to data position D = transform.screenToData(S)
2. Calculate zoom factor from scroll delta (e.g., 1.1 for zoom in, 0.9 for zoom out)
3. Resize data viewport by factor
4. Reposition viewport so D remains at screen position S
5. Constrain viewport to data bounds
6. Rebuild spatial index (deferred, not every frame)
7. Repaint
```

**Implementation Approach**:
```dart
// In handleEvent():
if (event is PointerSignalEvent && event is PointerScrollEvent) {
  _handleScroll(event.localPosition, event.scrollDelta);
}

void _handleScroll(Offset screenPosition, Offset scrollDelta) {
  final zoomFactor = 1.0 + (scrollDelta.dy * -0.001); // Invert: scroll up = zoom in
  _transform.zoomAroundScreenPoint(screenPosition, zoomFactor);
  
  // Deferred rebuild for performance
  _scheduleRebuildSpatialIndex();
  markNeedsPaint();
}
```

### 2.6 Spatial Index Updates

**Current State**:
- QuadTree stores elements in screen coordinates
- Rebuilt on element changes, layout changes, resize end

**New State**:
- QuadTree stores elements in **data coordinates** (no change to content)
- Rebuilt on:
  - Element additions/removals
  - Element position changes (drag, resize)
  - Layout changes (screen viewport size)
  - ~~Zoom/pan changes~~ (NOT needed - data coords don't change!)

**Key Insight**: Zoom/pan changes the transform but NOT the data coordinates, so QuadTree doesn't need rebuilding!

**Exception**: If elements need bounds in screen space for some reason (currently they don't), defer rebuild to avoid rebuilding 60x/sec during pan.

### 2.7 Hit Testing with Transforms

**Current Hit Testing**:
```dart
final hitElement = hitTestElements(screenPosition);
```

**Updated Hit Testing**:
```dart
// Convert screen position to data position
final dataPosition = _transform.screenToData(screenPosition);

// Scale hit tolerance by zoom level
final baseToleranceData = 10.0 / _transform.scaleX; // or scaleY

// Query QuadTree in data space
final queryRect = Rect.fromCenter(
  center: dataPosition,
  width: baseToleranceData * 2,
  height: baseToleranceData * 2,
);

final candidates = _spatialIndex.query(queryRect);

// Test each candidate with data coordinates
for (final element in candidates) {
  if (element.hitTest(dataPosition)) {
    return element;
  }
}
```

**Why Scale Tolerance?**:
- At 1.0x zoom: 10px screen tolerance = 10 data units
- At 2.0x zoom: 10px screen tolerance = 5 data units (same visual size)
- Without scaling, zooming in would make elements harder to click

### 2.8 Painting with Transforms

**Current Painting**:
```dart
for (final element in sortedElements) {
  element.paint(canvas, size); // Element paints at its position
}
```

**Updated Painting**:
```dart
// Query visible elements in data space
final visibleDataRect = _transform.dataViewport.inflate(
  _transform.dataViewport.width * 0.1, // 10% padding
);
final visibleElements = /* query QuadTree with visibleDataRect */;

// Paint each visible element
for (final element in visibleElements.sorted(by priority)) {
  // Element's bounds are in data space
  final dataBounds = element.bounds;
  
  // Convert to screen space for painting
  final screenBounds = _transform.dataRectToScreen(dataBounds);
  
  // Option 1: Transform the canvas before element paints
  canvas.save();
  canvas.transform(_transform.matrix4); // 4x4 matrix
  element.paint(canvas, size); // Element paints at data coords, canvas transforms it
  canvas.restore();
  
  // Option 2: Pass screen bounds to element (requires element API change)
  element.paintAtScreen(canvas, screenBounds);
}
```

**Recommendation**: Use Option 1 (transform canvas) to avoid changing element paint APIs.

---

## 3. Integration with Existing Systems

### 3.1 Priority-Based Hit Testing ✅

**No changes needed!**

- ChartElement types and priorities remain unchanged
- Hit testing still uses QuadTree spatial index
- Only difference: coordinates are in data space instead of screen space
- Transform is transparent to the priority system

### 3.2 Resize Handles ✅

**Requires coordinate awareness:**

```dart
class ResizeHandleElement extends ChartElement {
  final SimulatedAnnotation parentAnnotation;
  final ResizeDirection direction;
  Rect _bounds; // Now in DATA space
  
  // Update bounds when annotation resizes (data coords)
  void updateFromParent() {
    _bounds = _computeHandleBounds(parentAnnotation.bounds); // data coords
  }
  
  @override
  bool hitTest(Offset position) {
    // position is in data space
    return _bounds.contains(position);
  }
  
  @override
  void paint(Canvas canvas, Size size) {
    // Canvas is already transformed to data space by RenderBox
    // Just paint at data coordinates
    final paint = Paint()..color = Colors.blue;
    canvas.drawRect(_bounds, paint);
  }
}
```

**Key**: Resize handles update their data-space bounds when parent annotation changes. No special zoom/pan logic needed.

### 3.3 Annotation Drag/Resize 🔧

**Current Behavior**:
```dart
void _performResize(Offset currentPosition, Offset startPosition) {
  final delta = currentPosition - startPosition;
  final newBounds = _computeNewBounds(_resizeStartBounds, delta, _activeResizeDirection);
  _resizingAnnotation.updateBounds(newBounds);
}
```

**Updated Behavior**:
```dart
void _performResize(Offset currentScreenPosition, Offset startScreenPosition) {
  // Convert screen positions to data positions
  final currentData = _transform.screenToData(currentScreenPosition);
  final startData = _transform.screenToData(startScreenPosition);
  
  final dataDelta = currentData - startData;
  
  // Compute new bounds in data space
  final newDataBounds = _computeNewBounds(_resizeStartBounds, dataDelta, _activeResizeDirection);
  
  // Update annotation (still in data space)
  _resizingAnnotation.updateBounds(newDataBounds);
}
```

**Key**: Convert screen deltas to data deltas before applying to element bounds.

### 3.4 Box Selection 🔧

**Current Behavior**:
```dart
final boxRect = coordinator.boxSelectionRect; // In screen space
final intersecting = _elements.where((e) => e.bounds.overlaps(boxRect));
```

**Updated Behavior**:
```dart
final boxScreenRect = coordinator.boxSelectionRect; // In screen space
final boxDataRect = _transform.screenRectToData(boxScreenRect); // Convert to data space

// Query QuadTree with data rect
final candidates = _spatialIndex.query(boxDataRect);
final intersecting = candidates.where((e) => e.bounds.overlaps(boxDataRect));
```

**Key**: Box selection rectangle drawn in screen space, but tested in data space.

### 3.5 Crosshair 🔧

**Current Behavior**:
```dart
void paint(PaintingContext context, Offset offset) {
  final cursorPos = _cursorPosition; // Screen coords
  canvas.drawLine(Offset(0, cursorPos.dy), Offset(size.width, cursorPos.dy), paint);
  canvas.drawLine(Offset(cursorPos.dx, 0), Offset(cursorPos.dx, size.height), paint);
}
```

**Updated Behavior** (no change needed!):
```dart
// Crosshair is always drawn in screen space (overlay above transformed content)
// It follows the mouse cursor, which is in screen space
// No transformation needed!
```

**Key**: Crosshair is a screen-space overlay, not part of the transformed chart content.

### 3.6 Cursor Management 🆕

**New Cursor States**:
```dart
SystemMouseCursor _computeCursor() {
  // Active interaction takes precedence
  if (coordinator.currentMode == InteractionMode.panning) {
    return SystemMouseCursors.grabbing;
  }
  if (coordinator.currentMode == InteractionMode.resizingAnnotation) {
    return _getResizeCursor(_activeResizeDirection);
  }
  if (coordinator.currentMode == InteractionMode.draggingAnnotation) {
    return SystemMouseCursors.grabbing;
  }
  
  // Hover state
  if (_hoveredElement != null) {
    return _getCursorForElement(_hoveredElement);
  }
  
  // Default: grab cursor for pan-enabled chart
  return SystemMouseCursors.grab;
}
```

**Cursor Lifecycle**:
```
Idle → grab (hovering over chart)
Click empty space → grabbing (panning)
Release → grab
Hover over element → click/move/resize cursors
```

---

## 4. Implementation Plan

### Phase 1: ChartTransform Class ✅
**Files**: `lib/core/chart_transform.dart` (new)

- [ ] Create ChartTransform class
  - [ ] Constructor with data bounds and screen viewport
  - [ ] Cached scale/translate factors
  - [ ] `dataToScreen()` and `screenToData()` methods
  - [ ] `dataRectToScreen()` and `screenRectToData()` methods
  - [ ] `panByScreenDelta()` method
  - [ ] `zoomAroundScreenPoint()` method
  - [ ] Zoom constraints (min/max zoom levels)
  - [ ] Viewport constraints (prevent panning beyond bounds)
  - [ ] `zoomToFit()` utility method

### Phase 2: Update ChartRenderBox ✅
**Files**: `lib/rendering/chart_render_box.dart`

- [ ] Add ChartTransform field
- [ ] Initialize transform in constructor
- [ ] Update `performLayout()` to set screen viewport
- [ ] Add pan gesture handling:
  - [ ] Detect empty space click
  - [ ] Track pan state
  - [ ] Update transform on pointer move
  - [ ] End pan on pointer up
- [ ] Add zoom gesture handling:
  - [ ] Handle PointerScrollEvent
  - [ ] Call transform.zoomAroundScreenPoint()
  - [ ] Repaint
- [ ] Update hit testing:
  - [ ] Convert screen → data coordinates
  - [ ] Scale hit tolerance by zoom
  - [ ] Query QuadTree with data coordinates
- [ ] Update painting:
  - [ ] Query visible elements with data viewport
  - [ ] Transform canvas before painting
  - [ ] Or pass screen coordinates to elements

### Phase 3: Update Interaction Coordinator ✅
**Files**: `lib/core/coordinator.dart`

- [ ] Add InteractionMode.panning
- [ ] Add pan state management:
  - [ ] `startPanning()`
  - [ ] `endPanning()`
  - [ ] `bool get isPanning`
- [ ] Add pan permission checks:
  - [ ] Don't allow pan during resize
  - [ ] Don't allow pan during box select
  - [ ] Don't allow pan during element drag

### Phase 4: Update Element Drag/Resize ✅
**Files**: `lib/rendering/chart_render_box.dart`

- [ ] Convert screen deltas to data deltas in `_performResize()`
- [ ] Convert screen deltas to data deltas in annotation drag
- [ ] Update box selection to use data coordinates

### Phase 5: Cursor Management ✅
**Files**: `lib/rendering/chart_render_box.dart`

- [ ] Update `_computeCursor()` to include pan states
- [ ] Set grab cursor on hover
- [ ] Set grabbing cursor during pan
- [ ] Add cursor callback invocation

### Phase 6: Testing & Refinement ✅
**Files**: Example app, test files

- [ ] Test pan gesture (left-drag empty space)
- [ ] Test zoom gesture (mouse wheel)
- [ ] Test zoom around cursor position
- [ ] Test pan constraints (don't go beyond bounds)
- [ ] Test zoom constraints (min/max levels)
- [ ] Test element selection during zoom/pan
- [ ] Test element drag during zoom/pan
- [ ] Test annotation resize during zoom/pan
- [ ] Test box selection during zoom/pan
- [ ] Test cursor changes
- [ ] Performance test (smooth 60 FPS during pan/zoom)

---

## 5. Data Migration Strategy

### Current Element Coordinates
**Problem**: Elements currently store screen coordinates. When we introduce transforms, these need to become data coordinates.

**Solution**: Start with **identity transform** (1:1 mapping).

```dart
// Initial state
final dataBounds = Rect.fromLTWH(0, 0, 800, 600); // Same as screen size
final screenViewport = Rect.fromLTWH(0, 0, 800, 600);

_transform = ChartTransform(
  dataViewport: dataBounds,
  screenViewport: screenViewport,
);

// Now screen coords == data coords
// No element code changes needed!
```

**Migration Path**:
1. Add transform with identity mapping
2. Update hit testing to use transform (no-op at first)
3. Update painting to use transform (no-op at first)
4. Enable pan/zoom gestures
5. Now pan/zoom work without changing element storage!

### Future: True Data Space
Later, when integrating with real chart data:

```dart
// Data space: time series data
final dataBounds = Rect.fromLTWH(
  0,              // time: 0
  0,              // price: 0
  1000,           // time range: 1000 units
  100,            // price range: 100 units
);

// Screen space: canvas size
final screenViewport = Rect.fromLTWH(0, 0, 800, 600);

// Transform maps data → screen
_transform = ChartTransform(
  dataViewport: dataBounds,
  screenViewport: screenViewport,
);
```

---

## 6. Performance Considerations

### 6.1 Avoid Rebuilding QuadTree on Every Pan/Zoom

**Problem**: Rebuilding QuadTree 60x per second during pan kills performance.

**Solution**: QuadTree stores data coordinates, which don't change during pan/zoom!

```dart
void _handlePointerMove(PointerMoveEvent event) {
  if (coordinator.currentMode == InteractionMode.panning) {
    _transform.panByScreenDelta(event.delta);
    // QuadTree still valid - just repaint!
    markNeedsPaint();
  }
}
```

**When to rebuild**:
- Element added/removed
- Element position changed (drag ended)
- Element resized (resize ended)
- NOT during pan/zoom

### 6.2 Viewport Culling

**Optimization**: Only paint elements visible in the current data viewport.

```dart
void paint(PaintingContext context, Offset offset) {
  final visibleDataRect = _transform.dataViewport.inflate(
    _transform.dataViewport.width * 0.1, // 10% padding for smooth pan
  );
  
  final visibleIds = _spatialIndex.query(visibleDataRect);
  
  // Only paint visible elements
  for (final id in visibleIds) {
    final element = getElement(id);
    element.paint(canvas, size);
  }
}
```

**Benefit**: At 10x zoom, only ~1% of elements are visible → 100x speedup!

### 6.3 Hit Tolerance Scaling

**Problem**: At high zoom, elements appear larger but hit tolerance stays same, making them feel "sticky".

**Solution**: Scale hit tolerance inversely with zoom.

```dart
final screenTolerance = 10.0; // pixels
final dataTolerance = screenTolerance / _transform.scaleX;

final queryRect = Rect.fromCenter(
  center: dataPosition,
  width: dataTolerance * 2,
  height: dataTolerance * 2,
);
```

**Result**: Consistent click feel at all zoom levels.

### 6.4 Deferred Spatial Index Rebuild

If we DO need to rebuild QuadTree (e.g., screen-space bounds for some elements):

```dart
Timer? _rebuildTimer;

void _scheduleRebuildSpatialIndex() {
  _rebuildTimer?.cancel();
  _rebuildTimer = Timer(Duration(milliseconds: 100), () {
    _rebuildSpatialIndex();
    markNeedsPaint();
  });
}

void _handleScroll(...) {
  _transform.zoomAroundScreenPoint(...);
  _scheduleRebuildSpatialIndex(); // Deferred
  markNeedsPaint(); // Immediate
}
```

**Benefit**: Rebuilds only after zoom settles, not 60x/sec.

---

## 7. Edge Cases & Constraints

### 7.1 Zoom Limits
```dart
class ChartTransform {
  double _minZoom = 0.1;  // Don't zoom out more than 10x
  double _maxZoom = 10.0; // Don't zoom in more than 10x
  
  void zoomAroundScreenPoint(Offset screenPoint, double factor) {
    final currentZoom = _dataBounds.width / _dataViewport.width;
    final targetZoom = currentZoom * factor;
    
    if (targetZoom < _minZoom || targetZoom > _maxZoom) {
      return; // Reject zoom
    }
    
    // Apply zoom...
  }
}
```

### 7.2 Pan Constraints
```dart
void panByScreenDelta(Offset screenDelta) {
  final dataDelta = Offset(
    screenDelta.dx / _scaleX,
    screenDelta.dy / _scaleY,
  );
  
  _dataViewport = _dataViewport.shift(-dataDelta);
  
  // Constrain to data bounds
  _constrainViewportToBounds();
  _updateTransform();
}

void _constrainViewportToBounds() {
  // Don't allow viewport left/top to go below bounds left/top
  // Don't allow viewport right/bottom to go above bounds right/bottom
  // If viewport is larger than bounds (zoomed out), center it
  
  // (Implementation per Section 7 of architecture doc)
}
```

### 7.3 Coordinate Precision

**Issue**: At extreme zoom (100x), floating-point precision errors can cause jitter.

**Mitigation**:
- Use double precision (64-bit) for all coordinates
- Limit max zoom to 10x (reasonable for chart UX)
- Use Matrix4 for transforms (hardware-accelerated, high precision)

### 7.4 Interaction During Pan/Zoom

**Rule**: Panning/zooming should not interfere with element interactions.

**Approach**:
```dart
void _handlePointerDown(PointerDownEvent event, Offset position) {
  final hitElement = hitTestElements(position);
  
  if (hitElement != null) {
    // Element clicked - handle element interaction
    _handleElementClick(hitElement, event);
  } else {
    // Empty space clicked
    if (event.buttons == kPrimaryMouseButton && coordinator.allowsPanning) {
      coordinator.startPanning();
    }
  }
}
```

**Priority**:
1. Element interactions (select, drag, resize) > panning
2. Panning only starts on empty space click
3. Zoom works regardless (mouse wheel is passive)

---

## 8. Testing Strategy

### 8.1 Unit Tests

```dart
test('ChartTransform converts data to screen correctly', () {
  final transform = ChartTransform(
    dataViewport: Rect.fromLTWH(0, 0, 100, 100),
    screenViewport: Rect.fromLTWH(0, 0, 800, 600),
  );
  
  expect(transform.dataToScreen(Offset(50, 50)), Offset(400, 300));
  expect(transform.screenToData(Offset(400, 300)), Offset(50, 50));
});

test('ChartTransform pans correctly', () {
  final transform = ChartTransform(
    dataViewport: Rect.fromLTWH(0, 0, 100, 100),
    screenViewport: Rect.fromLTWH(0, 0, 800, 600),
  );
  
  transform.panByScreenDelta(Offset(80, 0)); // Pan right 80 screen pixels
  
  // Data viewport should shift left by 10 data units (80 / scaleX)
  expect(transform.dataViewport.left, -10);
  expect(transform.dataViewport.width, 100);
});

test('ChartTransform zooms around point correctly', () {
  final transform = ChartTransform(
    dataViewport: Rect.fromLTWH(0, 0, 100, 100),
    screenViewport: Rect.fromLTWH(0, 0, 800, 600),
  );
  
  final screenPoint = Offset(400, 300); // Center
  transform.zoomAroundScreenPoint(screenPoint, 2.0); // 2x zoom in
  
  // Viewport width should halve
  expect(transform.dataViewport.width, 50);
  
  // Center point should remain at same screen position
  final centerData = Offset(50, 50); // Original center
  expect(transform.dataToScreen(centerData), screenPoint);
});
```

### 8.2 Integration Tests

```dart
testWidgets('Pan gesture shifts viewport', (tester) async {
  await tester.pumpWidget(ChartPrototypeWidget(...));
  
  // Click and drag on empty space
  await tester.dragFrom(Offset(400, 300), Offset(100, 0));
  await tester.pumpAndSettle();
  
  // Verify viewport shifted
  final renderBox = tester.renderObject<ChartRenderBox>(find.byType(ChartPrototypeWidget));
  expect(renderBox.transform.dataViewport.left, lessThan(0));
});

testWidgets('Zoom gesture changes scale', (tester) async {
  await tester.pumpWidget(ChartPrototypeWidget(...));
  
  // Simulate mouse wheel scroll
  final pointer = TestPointer(1, PointerDeviceKind.mouse);
  await tester.sendEventToBinding(pointer.scroll(Offset(0, -10))); // Scroll up = zoom in
  await tester.pumpAndSettle();
  
  // Verify zoom level increased
  final renderBox = tester.renderObject<ChartRenderBox>(find.byType(ChartPrototypeWidget));
  expect(renderBox.transform.scaleX, greaterThan(1.0));
});

testWidgets('Element selection works during zoom', (tester) async {
  await tester.pumpWidget(ChartPrototypeWidget(...));
  
  // Zoom in 2x
  final pointer = TestPointer(1, PointerDeviceKind.mouse);
  await tester.sendEventToBinding(pointer.scroll(Offset(0, -100)));
  await tester.pumpAndSettle();
  
  // Click on datapoint
  await tester.tapAt(/* screen position of datapoint after zoom */);
  await tester.pumpAndSettle();
  
  // Verify datapoint selected
  final coordinator = /* get coordinator */;
  expect(coordinator.selectedElement?.elementType, ChartElementType.datapoint);
});
```

### 8.3 Performance Tests

```dart
test('Pan performance: 60 FPS with 1000 elements', () async {
  final stopwatch = Stopwatch()..start();
  
  for (int i = 0; i < 60; i++) {
    _transform.panByScreenDelta(Offset(1, 0));
    _renderBox.paint(/* ... */);
  }
  
  stopwatch.stop();
  final avgFrameTime = stopwatch.elapsedMilliseconds / 60;
  
  expect(avgFrameTime, lessThan(16.67)); // 60 FPS = 16.67ms per frame
});
```

---

## 9. Future Enhancements

### 9.1 Pinch-to-Zoom (Touch)
- Detect two-finger pinch gesture
- Calculate zoom factor from finger distance change
- Zoom around midpoint between fingers

### 9.2 Momentum Panning (Fling)
- Track pan velocity
- Continue panning with deceleration after pointer up
- Use AnimationController with Curves.decelerate

### 9.3 Zoom Animations
- Smooth zoom transitions instead of instant
- AnimationController with Curves.easeOut
- Interpolate data viewport over duration

### 9.4 Mini-Map / Navigator
- Small overview showing full data range
- Highlight current viewport
- Click/drag to pan main view

### 9.5 Zoom To Selection
- Select elements → zoom to fit selection bounds
- Useful for "focus on interesting data" UX

### 9.6 Constrained Zoom (Axis-Specific)
- Zoom X-axis only (time zoom)
- Zoom Y-axis only (value zoom)
- Modifier keys: Shift = X-only, Ctrl = Y-only

---

## 10. Migration Checklist

### Before Starting
- [x] Review architecture document
- [x] Understand current coordinate system
- [ ] Back up working state (git branch)
- [ ] Write baseline performance tests

### Implementation
- [ ] Create ChartTransform class
- [ ] Add to ChartRenderBox
- [ ] Update hit testing
- [ ] Update painting
- [ ] Add pan gesture
- [ ] Add zoom gesture
- [ ] Update cursor management
- [ ] Update element interactions
- [ ] Test thoroughly

### Validation
- [ ] All existing tests pass
- [ ] New zoom/pan tests pass
- [ ] Performance meets 60 FPS target
- [ ] No regressions in element interactions
- [ ] Cursor changes correctly
- [ ] Viewport constraints work

### Documentation
- [ ] Update README with pan/zoom controls
- [ ] Document transform coordinate system
- [ ] Add examples to example app
- [ ] Update architecture diagrams

---

## 11. Success Criteria

✅ **Functional**:
- Pan chart with left-click drag on empty space
- Zoom in/out with mouse wheel
- Zoom centers around cursor position
- Element selection works at all zoom levels
- Element drag works at all zoom levels
- Annotation resize works at all zoom levels
- Box selection works at all zoom levels
- Cursor shows grab/grabbing appropriately

✅ **Performance**:
- Smooth 60 FPS during pan
- Smooth 60 FPS during zoom
- No jank or frame drops with 1000+ elements
- Viewport culling reduces paint time proportionally

✅ **UX**:
- Pan feels natural and responsive
- Zoom feels smooth and controlled
- Element hit targets feel consistent at all zoom levels
- Cursor feedback is clear and helpful
- No interaction conflicts (pan doesn't break element clicks)

---

## 12. Implementation Status

### Phase 1-6: Core Zoom/Pan ✅ COMPLETE
- [x] Element data storage (ElementData)
- [x] Element regeneration with ChartTransform
- [x] Shift+MouseWheel zoom (cursor-centered)
- [x] Keyboard +/- zoom (plot-centered)
- [x] Middle-button pan (with performance optimization)
- [x] Arrow key panning
- [x] Transform persistence fix (critical bug)
- [x] Performance optimization (deferred regeneration)

### Phase 7: Zoom/Pan Constraints ✅ COMPLETE
**Date**: November 6, 2025

#### Features Implemented

**Zoom Constraints**:
- Min zoom level: 0.1x (show 10x original data range)
- Max zoom level: 10.0x (show 1/10th original data range)
- Applied to all zoom methods:
  - Shift + MouseWheel zoom
  - Keyboard +/- zoom
- Smooth clamping preserves viewport center

**Pan Constraints**:
- Minimum 10% of original data must remain visible
- Prevents panning completely off data
- Applied to all pan methods:
  - Middle-button drag
  - Arrow key panning
- Smooth resistance at boundaries

**Reset View**:
- Keyboard shortcuts: `Home` or `R` key
- Restores original zoom and pan state
- Preserves current plot dimensions (if resized)
- Instant reset (no animation)

#### Implementation Details

**Original Transform Storage** (`chart_render_box.dart`):
```dart
ChartTransform? _originalTransform;  // Captured on first layout
```

**Constraint Constants**:
```dart
static const double minZoomLevel = 0.1;
static const double maxZoomLevel = 10.0;
static const double minVisibleDataFraction = 0.1;
```

**Clamping Methods**:
- `_clampZoomLevel(transform)`: Enforces min/max zoom
- `_clampPanBounds(transform)`: Keeps data visible
- Both applied transparently during zoom/pan operations

**Algorithm Highlights**:
- **Zoom clamping**: Calculate current zoom as `originalRange / currentRange`, clamp to limits, preserve center
- **Pan clamping**: Check viewport overlap with original data, shift to maintain 10% visibility
- **Stateless**: Works by comparing current transform to original, no state tracking

#### Testing
See `phase_7_constraints_testing.md` for comprehensive test scenarios.

### Phase 8: Testing and Refinement 🔄 IN PROGRESS
- [ ] Comprehensive zoom/pan testing
- [ ] Performance profiling
- [ ] Reduce debug output
- [ ] Add unit tests for constraints
- [ ] Verify all edge cases
- [ ] Polish UX feedback

---

**Status**: Phase 7 complete. Ready for testing and Phase 8 refinement.

