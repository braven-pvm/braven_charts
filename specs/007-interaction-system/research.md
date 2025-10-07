# Research & Analysis: Interaction System

**Feature**: Layer 7 Interaction System  
**Branch**: 007-interaction-system  
**Date**: 2025-01-07

## Research Tasks

### 1. Flutter Gesture Detection System

#### Decision
Use Flutter's built-in **GestureDetector** widget for gesture recognition, with custom gesture prioritization logic.

#### Rationale
- **Mature & Tested**: Flutter's GestureDetector handles complex gesture arena resolution
- **Cross-Platform**: Works consistently across web, iOS, Android, desktop
- **Performance**: Native gesture recognition is highly optimized (<5ms processing)
- **Accessibility**: Integrates with Flutter's Semantics tree automatically

#### How GestureDetector Works
```dart
GestureDetector(
  onTapDown: (details) { /* Handle tap start */ },
  onTapUp: (details) { /* Handle tap end */ },
  onPanStart: (details) { /* Handle drag start */ },
  onPanUpdate: (details) { /* Handle drag move */ },
  onScaleStart: (details) { /* Handle pinch start */ },
  onScaleUpdate: (details) { /* Handle pinch/zoom */ },
  child: CustomPaint(painter: ChartPainter()),
)
```

#### Gesture Arena & Conflict Resolution
- **Arena System**: Multiple gesture recognizers compete; winner takes event stream
- **Priority Rules**:
  1. Tap loses to pan (if movement >10px within 300ms)
  2. Pan loses to pinch (if second finger detected)
  3. Long-press wins if no movement for 500ms
- **Custom Priority**: For chart-specific needs, use RawGestureDetector with custom recognizers

#### Pointer Event Flow
```
1. PointerDownEvent → Multiple recognizers enter arena
2. PointerMoveEvent → Recognizers evaluate (is this my gesture?)
3. Arena Resolution → One recognizer wins, others lose
4. Callback Invocation → onTapUp, onPanUpdate, etc.
```

#### Alternatives Considered
- **Custom Touch Handling**: Too complex, reinventing Flutter's optimized system
- **Third-Party Packages**: Unnecessary dependency, GestureDetector is sufficient

---

### 2. Coordinate Transformation Approaches

#### Decision
Leverage existing **CoordinateTransformer** (Layer 2) for all screen ↔ data conversions, extend with viewport state tracking.

#### Rationale
- **Already Implemented**: Layer 2 provides `screenToData()` and `dataToScreen()` methods
- **Consistent**: All rendering layers use same coordinate system
- **Viewport-Aware**: CoordinateTransformer already handles chart bounds and axis scales

#### Coordinate Spaces
```
1. Screen Space: Pixels from top-left of widget (0,0 to width,height)
2. Chart Space: Logical chart area (accounting for padding, axes, legends)
3. Data Space: Actual data values (X,Y coordinates of data points)
```

#### Transformation Pipeline for Interaction Events
```dart
// Mouse/touch event gives screen coordinates
Offset screenPosition = details.localPosition;

// Transform to chart space (account for padding)
Offset chartPosition = screenPosition - chartPadding;

// Transform to data space using existing transformer
ChartDataPoint dataPoint = coordinateTransformer.screenToData(chartPosition);
```

#### Viewport Transformation During Zoom/Pan
```dart
class ZoomPanState {
  double zoomLevelX = 1.0;  // 1.0 = 100% (no zoom)
  double zoomLevelY = 1.0;
  Offset panOffset = Offset.zero;  // In data space
  
  // Visible data bounds after zoom/pan
  Rect visibleDataBounds() {
    double visibleWidth = originalWidth / zoomLevelX;
    double visibleHeight = originalHeight / zoomLevelY;
    return Rect.fromLTWH(
      panOffset.dx,
      panOffset.dy,
      visibleWidth,
      visibleHeight,
    );
  }
}
```

#### Alternatives Considered
- **Custom Coordinate System**: Would break integration with existing rendering layers
- **Matrix Transformations**: More complex than needed for 2D charts

---

### 3. Accessibility APIs (WCAG 2.1 AA)

#### Decision
Use Flutter's **Semantics** widget and **Focus** system for keyboard navigation and screen reader support.

#### Rationale
- **WCAG Compliance**: Flutter's Semantics maps to platform accessibility APIs
- **Screen Reader Support**: Automatic announcements via SemanticsLabel
- **Keyboard Navigation**: FocusNode system with visual focus indicators
- **Cross-Platform**: Works on web (ARIA), iOS (VoiceOver), Android (TalkBack)

#### Keyboard Navigation Implementation
```dart
class AccessibleDataPoint extends StatefulWidget {
  final ChartDataPoint point;
  final FocusNode focusNode;
  
  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: focusNode,
      onKey: (node, event) {
        if (event is RawKeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
            // Move to next data point
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: Semantics(
        label: 'Data point: ${point.seriesName}, ${point.x}, ${point.y}',
        button: true,
        onTap: () => _showTooltip(point),
        child: CustomPaint(painter: FocusIndicatorPainter()),
      ),
    );
  }
}
```

#### Focus Indicator Requirements
- **Contrast**: 3:1 minimum contrast ratio against background (WCAG 2.1 AA)
- **Visual Style**: 2px solid border around focused data point
- **Color**: Use theme's focus color (typically blue or accent color)

#### Screen Reader Announcements
```dart
// When crosshair snaps to data point
SemanticsService.announce(
  'Data point selected: Sales, January 15, \$45,230',
  TextDirection.ltr,
);

// When zoom level changes
SemanticsService.announce(
  'Zoom level: ${(zoomLevel * 100).toInt()}%',
  TextDirection.ltr,
);
```

#### Keyboard Shortcuts
| Key | Action | Implementation |
|-----|--------|----------------|
| Arrow Keys | Navigate data points / pan chart | FocusNode traversal |
| +/- | Zoom in/out | RawKeyboard listener |
| Home/End | Jump to first/last point | Focus list boundaries |
| Enter/Space | Show tooltip | Semantics onTap |
| Escape | Close tooltip / clear selection | RawKeyboard listener |

#### Alternatives Considered
- **Custom Accessibility Layer**: Too complex, Flutter's Semantics is standard
- **Web-Only ARIA**: Would not work on native platforms

---

### 4. Performance Optimization Strategies

#### Decision
Implement **spatial indexing** (quadtree) for snap-to-point and **viewport culling** for rendering optimization.

#### Rationale
- **Snap-to-Point Performance**: Linear search is O(n), quadtree is O(log n)
- **Large Datasets**: With 100,000+ data points, need sub-millisecond search
- **Viewport Culling**: Only render visible points during zoom
- **Memory Efficiency**: Quadtree overhead <1MB for 100k points

#### Spatial Indexing: Quadtree for Snap-to-Point
```dart
class SpatialIndex {
  QuadTree<ChartDataPoint> tree;
  
  void buildIndex(List<ChartDataPoint> points) {
    tree = QuadTree(bounds: dataBounds);
    for (var point in points) {
      tree.insert(point, point.position);
    }
  }
  
  ChartDataPoint? findNearest(Offset position, double maxRadius) {
    // Search only within radius (much faster than linear scan)
    List<ChartDataPoint> candidates = tree.query(
      Rect.fromCircle(center: position, radius: maxRadius)
    );
    
    // Find closest among candidates
    return candidates.isEmpty ? null : 
      candidates.reduce((a, b) => 
        (a.position - position).distance < (b.position - position).distance ? a : b
      );
  }
}
```

**Performance**: O(log n) vs O(n), for 100k points: ~17 comparisons vs 100k

#### Viewport Culling During Zoom/Pan
```dart
List<ChartDataPoint> getVisiblePoints(Rect viewport) {
  // Only return points within visible viewport
  return allPoints.where((point) => 
    viewport.contains(point.position)
  ).toList();
}

// In renderer:
void paint(Canvas canvas, Size size) {
  Rect viewport = zoomPanState.visibleDataBounds();
  List<ChartDataPoint> visiblePoints = getVisiblePoints(viewport);
  
  // Render only visible points (massive performance gain)
  for (var point in visiblePoints) {
    drawDataPoint(canvas, point);
  }
}
```

**Performance**: 1000 visible points vs 100k total = 100x fewer draw calls

#### CustomPainter Performance Best Practices
```dart
class CrosshairPainter extends CustomPainter {
  final Paint _linePaint = Paint()..isAntiAlias = false; // Avoid AA if possible
  
  @override
  void paint(Canvas canvas, Size size) {
    // Use path for multiple lines (batch rendering)
    final path = Path()
      ..moveTo(0, crosshairY)
      ..lineTo(size.width, crosshairY)
      ..moveTo(crosshairX, 0)
      ..lineTo(crosshairX, size.height);
    canvas.drawPath(path, _linePaint);
  }
  
  @override
  bool shouldRepaint(CrosshairPainter oldDelegate) {
    // Only repaint if position changed
    return oldDelegate.crosshairX != crosshairX || 
           oldDelegate.crosshairY != crosshairY;
  }
}
```

#### Memory Management
```dart
// Object pooling for frequently created objects
class EventPool {
  final Queue<PointerEvent> _pool = Queue();
  
  PointerEvent acquire(Offset position) {
    return _pool.isEmpty ? PointerEvent(position) : _pool.removeFirst()..reset(position);
  }
  
  void release(PointerEvent event) {
    _pool.add(event);
  }
}
```

#### Alternatives Considered
- **No Spatial Index**: Too slow for large datasets (>10k points)
- **KD-Tree**: Quadtree better for 2D spatial queries
- **R-Tree**: Overkill for point data (better for rectangles)

---

### 5. Cross-Platform Touch/Mouse Handling

#### Decision
Use **PointerEvent** API as lowest common denominator, translate to logical gestures via GestureDetector.

#### Rationale
- **Unified API**: PointerEvent works identically on web, iOS, Android, desktop
- **Device Agnostic**: Handles mouse, touch, pen, trackpad
- **Performance**: Native pointer events have <1ms latency

#### Platform Differences

##### Mouse (Desktop: Windows/macOS/Linux/Web)
```dart
MouseRegion(
  onEnter: (event) { /* Show crosshair */ },
  onExit: (event) { /* Hide crosshair */ },
  onHover: (event) { /* Update crosshair position */ },
  child: Listener(
    onPointerSignal: (signal) {
      if (signal is PointerScrollEvent) {
        // Mouse wheel zoom
        double zoomDelta = signal.scrollDelta.dy > 0 ? 0.9 : 1.1;
        zoomAtPoint(event.localPosition, zoomDelta);
      }
    },
    child: chart,
  ),
)
```

##### Touch (Mobile: iOS/Android, Web Touch)
```dart
GestureDetector(
  onTapDown: (details) {
    // Show crosshair at tap position
    showCrosshairAt(details.localPosition);
  },
  onLongPressStart: (details) {
    // Show persistent tooltip
    showTooltipAt(details.localPosition, persistent: true);
  },
  onScaleStart: (details) {
    // Begin pinch-to-zoom
    initialZoomLevel = currentZoomLevel;
  },
  onScaleUpdate: (details) {
    // Apply zoom
    currentZoomLevel = initialZoomLevel * details.scale;
  },
  child: chart,
)
```

##### Web-Specific Considerations
```dart
// Prevent browser's default zoom (Ctrl+Wheel)
if (kIsWeb) {
  html.document.addEventListener('wheel', (event) {
    if (event.ctrlKey) {
      event.preventDefault(); // Prevent browser zoom
      // Apply chart zoom instead
    }
  }, { 'passive': false });
}
```

#### Gesture Detection Across Platforms

| Gesture | Desktop (Mouse) | Mobile (Touch) | Web |
|---------|----------------|----------------|-----|
| Tap | Click | Tap | Click or Tap |
| Double-tap | Double-click | Double-tap | Double-click or Double-tap |
| Zoom | Ctrl+Wheel | Pinch | Ctrl+Wheel or Pinch |
| Pan | Click+Drag | Swipe | Click+Drag or Swipe |
| Crosshair | Hover | Tap | Hover or Tap |

#### Alternatives Considered
- **Platform-Specific Code**: Would violate Pure Flutter principle
- **Conditional Compilation**: Unnecessary, PointerEvent is universal

---

## Architectural Decisions Summary

### 1. Event Processing Architecture
**Decision**: Unified event pipeline with priority-based delegation

```
PointerEvent (screen coordinates)
  ↓ (CoordinateTransformer)
ChartEvent (data coordinates)
  ↓ (Event Router)
Priority 1: Gesture Recognizer (pan/pinch takes precedence)
Priority 2: Crosshair Renderer (always active)
Priority 3: Tooltip Provider (triggered by tap/hover)
Priority 4: Keyboard Handler (when focused)
```

### 2. State Management
**Decision**: ValueNotifier for reactive interaction state

```dart
class InteractionController {
  final ValueNotifier<InteractionState> state = ValueNotifier(InteractionState.initial());
  final ValueNotifier<ZoomPanState> zoomPan = ValueNotifier(ZoomPanState.initial());
  
  void updateCrosshair(Offset position) {
    state.value = state.value.copyWith(crosshairPosition: position);
  }
}
```

**Rationale**: ValueNotifier is lightweight, integrates with ValueListenableBuilder, avoids heavy state management packages

### 3. Rendering Strategy
**Decision**: Separate CustomPainter layers for crosshair, tooltip, focus indicator

```dart
Stack(
  children: [
    CustomPaint(painter: ChartPainter()),     // Layer 5: Chart rendering
    CustomPaint(painter: CrosshairPainter()), // Layer 7a: Crosshair overlay
    TooltipWidget(),                           // Layer 7b: Tooltip (uses Overlay)
    CustomPaint(painter: FocusIndicatorPainter()), // Layer 7c: Focus ring
  ],
)
```

**Rationale**: Separate painters minimize repaints (crosshair updates don't repaint entire chart)

### 4. Testing Strategy
**Decision**: Contract tests → Unit tests → Integration tests → Widget tests

```
1. Contract Tests (test/interaction/contracts/):
   - Define expected interfaces
   - Ensure API consistency
   
2. Unit Tests (test/interaction/unit/):
   - Test each component in isolation
   - Mock dependencies
   
3. Integration Tests (test/interaction/integration/):
   - Test component interactions
   - Crosshair + Tooltip together
   
4. Widget Tests (test/interaction/widgets/):
   - Test visual rendering
   - Test gesture recognition
   - Test accessibility
```

---

## Performance Benchmarks

### Target Metrics (from spec)
- Event processing: <5ms overhead
- Crosshair rendering: <2ms per frame
- Tooltip rendering: <5ms including layout
- Total interaction response: <100ms (99th percentile)
- Frame rate during zoom/pan: 60 FPS (16ms per frame)
- Memory overhead: <5MB
- Zero memory leaks after 10,000 interactions

### Measurement Approach
```dart
// Performance test example
test('Crosshair renders in <2ms', () async {
  final stopwatch = Stopwatch()..start();
  
  for (int i = 0; i < 1000; i++) {
    crosshairPainter.paint(canvas, size);
  }
  
  stopwatch.stop();
  double avgTime = stopwatch.elapsedMicroseconds / 1000 / 1000; // Convert to ms
  
  expect(avgTime, lessThan(2.0), reason: 'Crosshair render time exceeded 2ms');
});
```

---

## Risk Assessment

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| Gesture conflicts (tap vs pan) | High | Medium | Implement gesture priority system |
| Performance on large datasets | High | Medium | Spatial indexing + viewport culling |
| Cross-platform inconsistencies | Medium | Low | Use PointerEvent API universally |
| Accessibility compliance | Medium | Low | Use Flutter's Semantics widget |
| Memory leaks from event listeners | High | Medium | Object pooling + proper disposal |

---

## Conclusion

Research confirms that Flutter's built-in APIs (GestureDetector, Semantics, CustomPainter) are sufficient for implementing a professional-grade interaction system. No external packages required. Key architectural decisions:

1. ✅ Use GestureDetector for gesture recognition
2. ✅ Leverage existing CoordinateTransformer for coordinate conversions
3. ✅ Use Semantics widget for WCAG 2.1 AA compliance
4. ✅ Implement spatial indexing (quadtree) for performance
5. ✅ Use PointerEvent API for cross-platform consistency

All constitutional principles satisfied. Ready to proceed to Phase 1 (Design & Contracts).

**Status**: ✅ Research Complete (2025-01-07)
