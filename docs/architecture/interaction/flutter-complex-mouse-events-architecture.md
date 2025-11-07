# Architecting Complex Mouse Events in Flutter: A Guide for Overlapping Interactive Chart Widgets

**Your core problem: "fixing one event breaks another"** - This happens because Flutter's gesture system uses a competitive arena where recognizers battle for control, and changing one widget's behavior affects the entire competition. For your complex charting package with overlapping datapoints, annotations, crosshairs, and context menus, the solution requires understanding three architectural layers working together strategically.

## Table of Contents

1. [Understanding Flutter's Hit Testing and Gesture Arena](#understanding-flutters-hit-testing-and-gesture-arena)
2. [The Core Problem: Why Events Conflict](#the-core-problem-why-events-conflict)
3. [Solution 1: Custom Gesture Recognizers with Context-Aware Logic](#solution-1-custom-gesture-recognizers-with-context-aware-logic)
4. [Solution 2: Custom RenderObject Approach](#solution-2-custom-renderobject-approach)
5. [Handling All Mouse Event Types](#handling-all-mouse-event-types)
6. [Mouse Cursor Management for Interactive Charts](#mouse-cursor-management-for-interactive-charts)
7. [Coordinate Transformation: The Foundation for Zoom and Pan](#coordinate-transformation-the-foundation-for-zoom-and-pan)
8. [Architecture Patterns from Production Chart Libraries](#architecture-patterns-from-production-chart-libraries)
9. [Performance Optimization for Large-Scale Interactive Elements](#performance-optimization-for-large-scale-interactive-elements)
10. [Complete Architecture Example](#complete-architecture-example)

## Understanding Flutter's Hit Testing and Gesture Arena

### Hit Testing Fundamentals

Flutter's hit testing operates through a **two-phase process** that's fundamentally different from traditional event bubbling:

1. **Downward traversal**: When a pointer touches the screen, Flutter traverses from the render tree root to leaves, testing each node to build a `HitTestResult` containing all widgets intersecting the touch point
2. **Reverse paint order**: Results are in reverse paint orderâ€”the deepest (topmost visually) widget is tested first

**Critical insight**: In a Stack, the last child (visually on top) is tested first, and if it returns true from `hitTest()`, lower widgets may not be tested at all depending on `HitTestBehavior`.

Source: [Flutter gesture documentation](https://docs.flutter.dev/ui/interactivity/gestures)

### HitTestBehavior: The Misunderstood Enum

The three behaviors are frequently misunderstood:

- **`HitTestBehavior.opaque`**: The widget participates in hit testing across its entire bounds AND prevents widgets behind it from being tested. **Common misconception**: It does NOT block childrenâ€”children still receive events normally.
  
- **`HitTestBehavior.translucent`**: The widget participates AND allows widgets behind it to also be tested. Both enter the gesture arena.

- **`HitTestBehavior.deferToChild`**: Only participates if a child is hit first. Unsuitable for capturing taps on whitespace.

Source: [HitTestBehavior documentation](https://api.flutter.dev/flutter/rendering/HitTestBehavior.html)

**For your chart scenario**: Understanding that all widgets in the hit test path receive pointer events is crucial. A Stack with three overlapping GestureDetectors will have all three receive pointer events, but only one tap gesture will ultimately fire due to the gesture arena.

### The Gesture Arena: Competitive Disambiguation

Flutter's gesture arena is where recognizers compete when a pointer sequence begins. Every `GestureDetector` creates recognizers that:

- **Accept**: Declare victory immediately, winning the arena
- **Reject**: Leave voluntarily, allowing others to win
- **Hold**: Continue observing to gather more information

**The problem**: Child widgets always win by default (FIFO ordering), which is why parent and child GestureDetectors conflict.

Source: [Flutter gesture arena deep dive](https://medium.com/flutter-community/flutter-deep-dive-gestures-c16203b3434f)

### Why Fixing One Event Breaks Another

When you have:
```
Chart background (wants pan/zoom)
â””â”€â”€ Datapoint overlay (wants tap)
    â””â”€â”€ Annotation handle (wants drag)
```

All three widgets create gesture recognizers that enter the arena. The annotation handle's recognizer enters first and wins, preventing the datapoint tap and background pan from firingâ€”even when you tap empty space near the annotation.

## The Core Problem: Why Events Conflict

### Scenario 1: Nested GestureDetectors

```dart
// âŒ PROBLEM: Child always wins, parent never fires
Stack(
  children: [
    GestureDetector(
      onTap: () => print('Background'),
      child: Container(color: Colors.blue),
    ),
    Positioned(
      child: GestureDetector(
        onTap: () => print('Foreground'),
        child: Container(color: Colors.red),
      ),
    ),
  ],
)
```

**What happens**: When you tap the red container, both recognizers enter the arena, but the red container's recognizer entered first (FIFO) and wins. The background tap never fires.

### Scenario 2: Multiple Interactive Elements in Charts

For a chart with:
- Background pan/zoom gesture
- Datapoint tap to select
- Crosshair drag to move
- Right-click context menu

All four interaction types compete, and whichever recognizer enters the arena first winsâ€”even if it's not the most appropriate for the user's intent.

**This is exactly your "fixing one breaks another" problem.**

Source: [Stack Overflow: event bubbling in Flutter](https://stackoverflow.com/questions/71620474/stop-event-bubbling-from-flutter-listener-widget)

## Solution 1: Custom Gesture Recognizers with Context-Aware Logic

### The Key Pattern

Create custom recognizers that examine the pointer position and **decide whether to participate based on hit location**:

```dart
class ContextAwareGestureRecognizer extends OneSequenceGestureRecognizer {
  final bool Function(Offset) shouldAcceptGesture;
  
  ContextAwareGestureRecognizer(this.shouldAcceptGesture);
  
  @override
  void addPointer(PointerDownEvent event) {
    if (shouldAcceptGesture(event.position)) {
      // This gesture is relevant - accept immediately
      resolve(GestureDisposition.accepted);
      startTrackingPointer(event.pointer);
    } else {
      // Not relevant - reject to let others win
      resolve(GestureDisposition.rejected);
    }
  }
  
  @override
  void handleEvent(PointerEvent event) {
    if (event is PointerMoveEvent) {
      // Process movement only if we won arena
    }
    if (event is PointerUpEvent) {
      stopTrackingPointer(event.pointer);
    }
  }
  
  @override
  String get debugDescription => 'context_aware_gesture';
}
```

Source: [Custom gesture recognizers](https://www.linkedin.com/pulse/uigesturerecognizer-tutorial-flutter-taps-drags-more-karim-soliman)

### Using RawGestureDetector

Connect your custom recognizer to the widget tree:

```dart
class ChartDataPoint extends StatelessWidget {
  final DataPoint point;
  final Offset screenPosition;
  
  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: screenPosition.dx - 10,
      top: screenPosition.dy - 10,
      child: RawGestureDetector(
        gestures: {
          ContextAwareGestureRecognizer: 
            GestureRecognizerFactoryWithHandlers<ContextAwareGestureRecognizer>(
              () => ContextAwareGestureRecognizer(
                (position) {
                  // Accept only if within 10px of datapoint center
                  return (position - screenPosition).distance < 10;
                }
              ),
              (instance) {
                instance.onPointerDown = (event) {
                  // Handle datapoint selection
                };
              },
            ),
        },
        child: Container(width: 20, height: 20, color: Colors.transparent),
      ),
    );
  }
}
```

### For Your Chart: Priority-Based Recognition

```dart
// Datapoint: Accept within 10px radius
bool shouldAcceptDatapoint(Offset position) {
  return datapoints.any((p) => (p.position - position).distance < 10);
}

// Series line: Accept within 5px of path
bool shouldAcceptSeries(Offset position) {
  return seriesPath.contains(position) || 
         _distanceToPath(seriesPath, position) < 5;
}

// Crosshair: Accept on initial touch, always
bool shouldAcceptCrosshair(Offset position) {
  return true; // But reject after initial positioning
}

// Background pan: Accept only if nothing else accepts
bool shouldAcceptBackground(Offset position) {
  return !shouldAcceptDatapoint(position) && 
         !shouldAcceptSeries(position);
}
```

## Solution 2: Custom RenderObject Approach

### When to Use Custom RenderObject

For charting packages with hundreds of datapoints and complex overlapping interactions, **custom RenderObject is the production-ready choice** because:

1. **Bypasses gesture arena entirely** - You override `hitTest()` and `handleEvent()` directly
2. **Performance** - No widget rebuilds trigger render object recreation
3. **Pixel-perfect control** - You determine exactly what constitutes a "hit"
4. **Raw event access** - Receive `PointerDownEvent`, `PointerMoveEvent`, etc. directly

Source: [RenderObject documentation](https://api.flutter.dev/flutter/rendering/RenderObject-class.html)

### Basic Structure

```dart
class ChartRenderBox extends RenderBox {
  List<DataPoint> dataPoints = [];
  List<ChartSeries> series = [];
  Path seriesPath = Path();
  List<Rect> dataPointHitAreas = [];
  
  // Geometry computed during paint for hit testing
  void _computeHitGeometry() {
    dataPointHitAreas.clear();
    seriesPath.reset();
    
    for (final point in dataPoints) {
      final screenPos = _dataToScreen(point);
      dataPointHitAreas.add(
        Rect.fromCenter(center: screenPos, width: 20, height: 20)
      );
    }
    
    // Build series path
    for (final series in series) {
      for (int i = 0; i < series.points.length; i++) {
        final pos = _dataToScreen(series.points[i]);
        if (i == 0) {
          seriesPath.moveTo(pos.dx, pos.dy);
        } else {
          seriesPath.lineTo(pos.dx, pos.dy);
        }
      }
    }
  }
  
  @override
  void paint(PaintingContext context, Offset offset) {
    _computeHitGeometry();
    
    final canvas = context.canvas;
    canvas.save();
    canvas.translate(offset.dx, offset.dy);
    
    // Draw series
    canvas.drawPath(seriesPath, Paint()..color = Colors.blue);
    
    // Draw datapoints
    for (final rect in dataPointHitAreas) {
      canvas.drawCircle(rect.center, 4, Paint()..color = Colors.red);
    }
    
    canvas.restore();
  }
  
  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    if (!size.contains(position)) return false;
    
    // Priority 1: Check datapoints
    if (dataPointHitAreas.any((rect) => rect.contains(position))) {
      result.add(BoxHitTestEntry(this, position));
      return true;
    }
    
    // Priority 2: Check series path
    if (seriesPath.contains(position)) {
      result.add(BoxHitTestEntry(this, position));
      return true;
    }
    
    // Priority 3: Background (always accept for pan/zoom)
    result.add(BoxHitTestEntry(this, position));
    return true;
  }
  
  @override
  void handleEvent(PointerEvent event, BoxHitTestEntry entry) {
    final position = entry.localPosition;
    
    if (event is PointerDownEvent) {
      if (dataPointHitAreas.any((rect) => rect.contains(position))) {
        _handleDataPointDown(position);
      } else if (seriesPath.contains(position)) {
        _handleSeriesDown(position);
      } else {
        _handleBackgroundDown(position);
      }
      
      // Handle right-click
      if (event.kind == PointerDeviceKind.mouse && 
          event.buttons == kSecondaryMouseButton) {
        _showContextMenu(position);
      }
    }
    
    if (event is PointerMoveEvent) {
      _handleMove(position);
    }
    
    if (event is PointerUpEvent) {
      _handleUp(position);
    }
  }
  
  void _handleDataPointDown(Offset position) {
    // Find which datapoint
    for (int i = 0; i < dataPointHitAreas.length; i++) {
      if (dataPointHitAreas[i].contains(position)) {
        // Select this datapoint
        break;
      }
    }
  }
  
  void _handleSeriesDown(Offset position) {
    // Highlight series
  }
  
  void _handleBackgroundDown(Offset position) {
    // Start pan operation
  }
  
  void _handleMove(Offset position) {
    // Update crosshair or continue pan
  }
  
  void _handleUp(Offset position) {
    // End gesture
  }
  
  void _showContextMenu(Offset position) {
    // Show context menu
  }
  
  @override
  void performLayout() {
    size = constraints.biggest;
  }
}
```

Source: [RenderBox hitTest documentation](https://api.flutter.dev/flutter/rendering/RenderBox/hitTest.html)

### Wrapping in a Widget

```dart
class ChartWidget extends LeafRenderObjectWidget {
  final List<DataPoint> dataPoints;
  final List<ChartSeries> series;
  
  const ChartWidget({
    required this.dataPoints,
    required this.series,
  });
  
  @override
  RenderObject createRenderObject(BuildContext context) {
    return ChartRenderBox()
      ..dataPoints = dataPoints
      ..series = series;
  }
  
  @override
  void updateRenderObject(BuildContext context, ChartRenderBox renderObject) {
    renderObject
      ..dataPoints = dataPoints
      ..series = series
      ..markNeedsPaint();
  }
}
```

### Hybrid Approach: CustomPaint + Listener

If full RenderObject is too heavy, use `Listener` (which doesn't participate in gesture arena) with `CustomPaint`:

```dart
class ChartWidget extends StatefulWidget {
  @override
  State<ChartWidget> createState() => _ChartWidgetState();
}

class _ChartWidgetState extends State<ChartWidget> {
  Offset? _crosshairPosition;
  
  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (event) {
        if (event.buttons == kSecondaryMouseButton) {
          _showContextMenu(event.position);
        } else {
          _handlePointerDown(event.position);
        }
      },
      onPointerMove: (event) {
        setState(() {
          _crosshairPosition = event.position;
        });
      },
      onPointerSignal: (signal) {
        if (signal is PointerScrollEvent) {
          _handleScroll(signal.scrollDelta);
        }
      },
      child: CustomPaint(
        painter: ChartPainter(
          dataPoints: widget.dataPoints,
          crosshair: _crosshairPosition,
        ),
        child: Container(), // For hit testing
      ),
    );
  }
}
```

Source: [Listener class documentation](https://api.flutter.dev/flutter/widgets/Listener-class.html)

## Handling All Mouse Event Types

### Hover/Enter/Exit: MouseRegion

`MouseRegion` handles hover events **independently of gesture detection**:

```dart
MouseRegion(
  onEnter: (event) {
    setState(() {
      _hovered = true;
    });
  },
  onExit: (event) {
    setState(() {
      _hovered = false;
    });
  },
  onHover: (event) {
    // Update hover position for tooltip
    _updateTooltipPosition(event.position);
  },
  cursor: SystemMouseCursors.click,
  child: yourWidget,
)
```

Source: [MouseRegion documentation](https://api.flutter.dev/flutter/widgets/MouseRegion-class.html)

### Right-Click: Listener with Button Detection

`GestureDetector.onTap` doesn't distinguish mouse buttons. Use `Listener`:

```dart
Listener(
  onPointerDown: (PointerDownEvent event) {
    if (event.kind == PointerDeviceKind.mouse) {
      if (event.buttons == kSecondaryMouseButton) {
        _showContextMenu(event.localPosition);
      } else if (event.buttons == kPrimaryMouseButton) {
        _handleLeftClick(event.localPosition);
      } else if (event.buttons == kMiddleMouseButton) {
        _handleMiddleClick(event.localPosition);
      }
    }
  },
  child: chartWidget,
)
```

Source: [Stack Overflow: right-click detection](https://stackoverflow.com/questions/62244113/can-i-change-right-click-action-in-flutter-web-application)

### Mouse Wheel with Modifier Keys

```dart
Listener(
  onPointerSignal: (PointerSignalEvent event) {
    if (event is PointerScrollEvent) {
      // Detect modifier keys
      final hasCtrl = HardwareKeyboard.instance.isControlPressed;
      final hasShift = HardwareKeyboard.instance.isShiftPressed;
      
      if (hasCtrl && hasShift) {
        _handleFineZoom(event.scrollDelta, event.localPosition);
      } else if (hasCtrl) {
        _handleZoom(event.scrollDelta, event.localPosition);
      } else {
        _handleScroll(event.scrollDelta);
      }
    }
  },
  child: chartWidget,
)
```

**Note**: For keyboard state, use `HardwareKeyboard.instance` (Flutter 3.x+) or maintain your own state with `RawKeyboard` listeners.

Source: [Stack Overflow: mouse wheel events](https://stackoverflow.com/questions/64985580/flutter-web-gesturedetector-detect-mouse-wheel-events)

### Complete Mouse Event Stack

Layer your mouse event handlers appropriately:

```dart
// Bottom: Listener for raw events + right-click + wheel
Listener(
  onPointerDown: _handlePointerDown,
  onPointerMove: _handlePointerMove,
  onPointerSignal: _handlePointerSignal,
  child: MouseRegion(
    // Middle: MouseRegion for hover
    onEnter: _handleHoverEnter,
    onExit: _handleHoverExit,
    onHover: _handleHover,
    cursor: SystemMouseCursors.click,
    child: GestureDetector(
      // Top: GestureDetector for semantic gestures (optional)
      onTap: _handleTap,
      onPanStart: _handlePanStart,
      behavior: HitTestBehavior.opaque,
      child: yourChartWidget,
    ),
  ),
)
```

## Mouse Cursor Management for Interactive Charts

### Available System Cursors

Flutter provides comprehensive cursor types through `SystemMouseCursors`:

```dart
// Basic cursors
SystemMouseCursors.basic       // Default arrow
SystemMouseCursors.click       // Pointing hand
SystemMouseCursors.forbidden   // Circle with slash

// Text cursors
SystemMouseCursors.text        // I-beam
SystemMouseCursors.verticalText

// Grab cursors (critical for drag operations)
SystemMouseCursors.grab        // Open hand - hovering over draggable
SystemMouseCursors.grabbing    // Closed hand - actively dragging

// Move cursor
SystemMouseCursors.move        // Four-way arrows

// Resize cursors (for chart annotations/handles)
SystemMouseCursors.resizeUp
SystemMouseCursors.resizeDown
SystemMouseCursors.resizeLeft
SystemMouseCursors.resizeRight
SystemMouseCursors.resizeUpLeft
SystemMouseCursors.resizeUpRight
SystemMouseCursors.resizeDownLeft
SystemMouseCursors.resizeDownRight
SystemMouseCursors.resizeUpDown
SystemMouseCursors.resizeLeftRight

// Precision cursors (for detailed chart work)
SystemMouseCursors.precise     // Crosshair
SystemMouseCursors.cell        // Table cell selector

// Waiting cursors
SystemMouseCursors.wait
SystemMouseCursors.progress

// Zoom cursors
SystemMouseCursors.zoomIn
SystemMouseCursors.zoomOut

// Special cursors
SystemMouseCursors.none        // Hide cursor
SystemMouseCursors.alias       // Shortcut indicator
SystemMouseCursors.copy        // Copy indicator
SystemMouseCursors.disappearing // Poof animation
```

Source: [SystemMouseCursors documentation](https://github.com/flutter/flutter/blob/master/packages/flutter/lib/src/services/mouse_cursor.dart)

### Basic Cursor Changes with MouseRegion

The simplest approach uses `MouseRegion.cursor`:

```dart
MouseRegion(
  cursor: SystemMouseCursors.click,
  onEnter: (event) => print('Hovering'),
  child: Container(
    width: 100,
    height: 100,
    color: Colors.blue,
  ),
)
```

Source: [Stack Overflow: cursor hover](https://stackoverflow.com/questions/56211844/flutter-web-mouse-hover-change-cursor-to-pointer)

### Stateful Cursor Changes Based on Interaction

For charts, cursor should change based on what's happening. Use stateful approach:

```dart
class InteractiveChartWidget extends StatefulWidget {
  @override
  State<InteractiveChartWidget> createState() => _InteractiveChartWidgetState();
}

class _InteractiveChartWidgetState extends State<InteractiveChartWidget> {
  SystemMouseCursor _currentCursor = SystemMouseCursors.basic;
  InteractionMode _mode = InteractionMode.idle;
  ChartElement? _hoveredElement;
  
  SystemMouseCursor _computeCursor() {
    // Priority 1: Active interaction
    switch (_mode) {
      case InteractionMode.panning:
        return SystemMouseCursors.grabbing;
      case InteractionMode.draggingDatapoint:
        return SystemMouseCursors.grabbing;
      case InteractionMode.draggingAnnotation:
        return SystemMouseCursors.grabbing;
      case InteractionMode.resizingAnnotation:
        return _getResizeCursor(_resizeDirection);
      default:
        break;
    }
    
    // Priority 2: Hover state
    if (_hoveredElement != null) {
      switch (_hoveredElement!.type) {
        case ElementType.datapoint:
          return SystemMouseCursors.click;
        case ElementType.annotation:
          return SystemMouseCursors.move;
        case ElementType.resizeHandle:
          return _getResizeCursor(_hoveredElement!.direction);
        case ElementType.seriesLine:
          return SystemMouseCursors.click;
      }
    }
    
    // Priority 3: Default mode cursor
    if (widget.panEnabled) {
      return SystemMouseCursors.grab;
    }
    
    return SystemMouseCursors.basic;
  }
  
  SystemMouseCursor _getResizeCursor(ResizeDirection direction) {
    switch (direction) {
      case ResizeDirection.horizontal:
        return SystemMouseCursors.resizeLeftRight;
      case ResizeDirection.vertical:
        return SystemMouseCursors.resizeUpDown;
      case ResizeDirection.topLeft:
        return SystemMouseCursors.resizeUpLeft;
      case ResizeDirection.topRight:
        return SystemMouseCursors.resizeUpRight;
      case ResizeDirection.bottomLeft:
        return SystemMouseCursors.resizeDownLeft;
      case ResizeDirection.bottomRight:
        return SystemMouseCursors.resizeDownRight;
    }
  }
  
  void _updateHover(Offset position) {
    final element = _hitTest(position);
    if (element != _hoveredElement) {
      setState(() {
        _hoveredElement = element;
        _currentCursor = _computeCursor();
      });
    }
  }
  
  void _startDrag() {
    setState(() {
      _mode = InteractionMode.draggingDatapoint;
      _currentCursor = _computeCursor();
    });
  }
  
  void _endDrag() {
    setState(() {
      _mode = InteractionMode.idle;
      _currentCursor = _computeCursor();
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: _currentCursor,
      onHover: (event) => _updateHover(event.localPosition),
      onExit: (_) {
        setState(() {
          _hoveredElement = null;
          _currentCursor = _computeCursor();
        });
      },
      child: Listener(
        onPointerDown: (event) {
          if (_hoveredElement != null) {
            _startDrag();
          }
        },
        onPointerUp: (_) => _endDrag(),
        child: CustomPaint(
          painter: ChartPainter(
            hoveredElement: _hoveredElement,
          ),
        ),
      ),
    );
  }
}
```

Source: [Stack Overflow: explicit cursor changes](https://stackoverflow.com/questions/70768718/change-the-cursor-explictly-without-mouseregion-in-flutter)

### Cursor During Drag Operations

**Critical issue**: When dragging, the cursor can revert to basic if not handled correctly.

#### The Problem

```dart
// âŒ WRONG - cursor reverts to basic during drag
Draggable(
  feedback: MouseRegion(
    cursor: SystemMouseCursors.grabbing,
    child: dragWidget,
  ),
  child: MouseRegion(
    cursor: SystemMouseCursors.grab,
    child: dragWidget,
  ),
)
```

The cursor reverts because by default, Draggable's feedback ignores pointer events.

#### The Solution

Set `ignoringFeedbackPointer: false`:

```dart
// âœ… CORRECT - cursor stays grabbing during drag
Draggable(
  ignoringFeedbackPointer: false, // Critical!
  feedback: MouseRegion(
    cursor: SystemMouseCursors.grabbing,
    child: dragWidget,
  ),
  child: MouseRegion(
    cursor: SystemMouseCursors.grab,
    child: dragWidget,
  ),
  childWhenDragging: MouseRegion(
    cursor: SystemMouseCursors.grabbing,
    child: dragWidget,
  ),
)
```

Source: [GitHub issue: Draggable cursor](https://stackoverflow.com/questions/66195257/draggable-mouse-cursor)

### Chart-Specific Cursor Pattern: Layered MouseRegions

For complex charts with overlapping interactive elements, use **layered MouseRegions with priority**:

```dart
class ChartWithCursorManagement extends StatefulWidget {
  @override
  State<ChartWithCursorManagement> createState() => 
    _ChartWithCursorManagementState();
}

class _ChartWithCursorManagementState extends State<ChartWithCursorManagement> {
  SystemMouseCursor _activeCursor = SystemMouseCursors.basic;
  
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Base layer: Default cursor for pan
        MouseRegion(
          cursor: _activeCursor,
          child: Listener(
            onPointerDown: _handlePointerDown,
            onPointerMove: _handlePointerMove,
            child: CustomPaint(
              painter: ChartPainter(),
            ),
          ),
        ),
        
        // Overlay layer: High-priority interactive elements
        ..._buildDataPointOverlays(),
        ..._buildAnnotationOverlays(),
      ],
    );
  }
  
  List<Widget> _buildDataPointOverlays() {
    return dataPoints.map((point) {
      return Positioned(
        left: point.x - 10,
        top: point.y - 10,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => _setHoverCursor(SystemMouseCursors.click),
          onExit: (_) => _clearHoverCursor(),
          child: GestureDetector(
            onTap: () => _selectDatapoint(point),
            child: Container(
              width: 20,
              height: 20,
              color: Colors.transparent,
            ),
          ),
        ),
      );
    }).toList();
  }
  
  List<Widget> _buildAnnotationOverlays() {
    return annotations.map((annotation) {
      return Positioned(
        left: annotation.x - 8,
        top: annotation.y - 8,
        child: MouseRegion(
          cursor: SystemMouseCursors.move,
          onEnter: (_) => _setHoverCursor(SystemMouseCursors.move),
          onExit: (_) => _clearHoverCursor(),
          child: GestureDetector(
            onPanStart: (_) {
              setState(() => _activeCursor = SystemMouseCursors.grabbing);
            },
            onPanUpdate: (details) => _moveAnnotation(annotation, details.delta),
            onPanEnd: (_) {
              setState(() => _activeCursor = SystemMouseCursors.move);
            },
            child: Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.blue),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
      );
    }).toList();
  }
  
  void _setHoverCursor(SystemMouseCursor cursor) {
    setState(() => _activeCursor = cursor);
  }
  
  void _clearHoverCursor() {
    setState(() => _activeCursor = SystemMouseCursors.grab);
  }
}
```

### Dynamic Cursor Based on Hit Detection in CustomPaint

For custom painted charts where you can't use positioned overlays everywhere:

```dart
class ChartWithDynamicCursor extends StatefulWidget {
  @override
  State<ChartWithDynamicCursor> createState() => _ChartWithDynamicCursorState();
}

class _ChartWithDynamicCursorState extends State<ChartWithDynamicCursor> {
  SystemMouseCursor _cursor = SystemMouseCursors.basic;
  Offset? _lastHoverPosition;
  
  SystemMouseCursor _determineCursorForPosition(Offset position) {
    // Check datapoints
    for (final point in dataPoints) {
      if ((point.position - position).distance < 10) {
        return SystemMouseCursors.click;
      }
    }
    
    // Check series lines
    if (_isNearSeriesLine(position)) {
      return SystemMouseCursors.click;
    }
    
    // Check resize handles on selected annotation
    if (_selectedAnnotation != null) {
      final handle = _getResizeHandle(_selectedAnnotation!, position);
      if (handle != null) {
        return _getResizeCursor(handle);
      }
      
      // Check if over annotation body
      if (_selectedAnnotation!.bounds.contains(position)) {
        return SystemMouseCursors.move;
      }
    }
    
    // Check crosshair activation zone
    if (_crosshairZone.contains(position)) {
      return SystemMouseCursors.precise;
    }
    
    // Default: pan cursor
    return _isPanning 
      ? SystemMouseCursors.grabbing 
      : SystemMouseCursors.grab;
  }
  
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: _cursor,
      onHover: (event) {
        setState(() {
          _lastHoverPosition = event.localPosition;
          _cursor = _determineCursorForPosition(event.localPosition);
        });
      },
      child: Listener(
        onPointerDown: (event) {
          final element = _hitTest(event.localPosition);
          if (element != null) {
            setState(() {
              _cursor = _getCursorForInteraction(element);
            });
          }
        },
        onPointerMove: (event) {
          // Update cursor during drag if needed
          if (_isDragging) {
            setState(() {
              _cursor = SystemMouseCursors.grabbing;
            });
          }
        },
        onPointerUp: (_) {
          setState(() {
            _cursor = _determineCursorForPosition(
              _lastHoverPosition ?? Offset.zero
            );
          });
        },
        child: CustomPaint(
          painter: ChartPainter(
            dataPoints: dataPoints,
            selectedAnnotation: _selectedAnnotation,
          ),
        ),
      ),
    );
  }
  
  SystemMouseCursor _getCursorForInteraction(ChartElement element) {
    switch (element.type) {
      case ElementType.datapoint:
        return SystemMouseCursors.grabbing;
      case ElementType.annotation:
        return SystemMouseCursors.grabbing;
      case ElementType.resizeHandle:
        return _getResizeCursor(element.direction);
      default:
        return SystemMouseCursors.basic;
    }
  }
}
```

### Custom Cursors (Advanced)

For truly custom cursors beyond system cursors, hide the system cursor and render your own:

```dart
class CustomCursorChart extends StatefulWidget {
  @override
  State<CustomCursorChart> createState() => _CustomCursorChartState();
}

class _CustomCursorChartState extends State<CustomCursorChart> {
  Offset _cursorPosition = Offset.zero;
  
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Hide system cursor
        MouseRegion(
          cursor: SystemMouseCursors.none,
          onHover: (event) {
            setState(() {
              _cursorPosition = event.position;
            });
          },
          child: yourChartWidget,
        ),
        
        // Custom cursor widget
        Positioned(
          left: _cursorPosition.dx - 12,
          top: _cursorPosition.dy - 12,
          child: IgnorePointer(
            child: CustomPaint(
              size: Size(24, 24),
              painter: CustomCursorPainter(
                type: _getCurrentCursorType(),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class CustomCursorPainter extends CustomPainter {
  final CursorType type;
  
  CustomCursorPainter({required this.type});
  
  @override
  void paint(Canvas canvas, Size size) {
    switch (type) {
      case CursorType.crosshair:
        _drawCrosshair(canvas, size);
        break;
      case CursorType.datapoint:
        _drawDatapointCursor(canvas, size);
        break;
      // ... other custom cursors
    }
  }
  
  void _drawCrosshair(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.red
      ..strokeWidth = 1.5;
    
    final center = Offset(size.width / 2, size.height / 2);
    
    // Horizontal line
    canvas.drawLine(
      Offset(0, center.dy),
      Offset(size.width, center.dy),
      paint,
    );
    
    // Vertical line
    canvas.drawLine(
      Offset(center.dx, 0),
      Offset(center.dx, size.height),
      paint,
    );
    
    // Center circle
    canvas.drawCircle(center, 3, paint..style = PaintingStyle.stroke);
  }
  
  @override
  bool shouldRepaint(CustomCursorPainter oldDelegate) =>
    type != oldDelegate.type;
}
```

Source: [Medium: custom cursors](https://medium.com/bobble-engineering/custom-cursors-in-flutter-web-6b79de764443)

### Performance Considerations for Cursor Updates

**Problem**: Updating cursor on every hover event can cause performance issues.

**Solution**: Debounce cursor changes:

```dart
class _ChartState extends State<Chart> {
  SystemMouseCursor _cursor = SystemMouseCursors.basic;
  Timer? _cursorUpdateTimer;
  
  void _updateCursorDebounced(Offset position) {
    _cursorUpdateTimer?.cancel();
    _cursorUpdateTimer = Timer(Duration(milliseconds: 16), () {
      final newCursor = _determineCursor(position);
      if (newCursor != _cursor) {
        setState(() {
          _cursor = newCursor;
        });
      }
    });
  }
  
  @override
  void dispose() {
    _cursorUpdateTimer?.cancel();
    super.dispose();
  }
}
```

### Chart Cursor Best Practices Summary

1. **Hierarchy**: Active interaction > Hover > Default
2. **Consistency**: 
   - `grab` when hovering over pannable area
   - `grabbing` when actively panning
   - `move` when hovering over draggable annotation
   - `grabbing` when dragging annotation
   - Resize cursors (`resizeUpLeft`, etc.) for resize handles
   - `click` for selectable elements (datapoints, series)
   - `precise` (crosshair) for precision tools

3. **Feedback Loop**:
   ```
   Hover â†’ grab
   Mouse down â†’ grabbing
   Drag â†’ keep grabbing
   Mouse up â†’ back to grab (if still hovering) or basic
   ```

4. **Overlapping Elements**: Higher-priority elements (smaller, more specific) should set cursor first

5. **State Management**: Use explicit cursor state variable, don't rely only on MouseRegion cascade

### Complete Cursor Management Example for Charts

```dart
class InteractiveChart extends StatefulWidget {
  @override
  State<InteractiveChart> createState() => _InteractiveChartState();
}

class _InteractiveChartState extends State<InteractiveChart> {
  SystemMouseCursor _cursor = SystemMouseCursors.basic;
  ChartInteractionMode _mode = ChartInteractionMode.idle;
  ChartElement? _hoveredElement;
  
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: _cursor,
      onHover: _handleHover,
      onExit: (_) => _handleExit(),
      child: Listener(
        onPointerDown: _handleDown,
        onPointerMove: _handleMove,
        onPointerUp: _handleUp,
        child: Stack(
          children: [
            CustomPaint(
              painter: ChartPainter(/* ... */),
            ),
            ..._buildOverlayElements(),
          ],
        ),
      ),
    );
  }
  
  void _handleHover(PointerHoverEvent event) {
    final element = _hitTest(event.localPosition);
    if (element != _hoveredElement) {
      setState(() {
        _hoveredElement = element;
        _cursor = _computeCursor();
      });
    }
  }
  
  void _handleDown(PointerDownEvent event) {
    if (_hoveredElement != null) {
      setState(() {
        _mode = _getInteractionMode(_hoveredElement!);
        _cursor = _computeCursor();
      });
    }
  }
  
  void _handleMove(PointerMoveEvent event) {
    if (_mode != ChartInteractionMode.idle) {
      // Keep cursor consistent during interaction
      // Don't recalculate based on hover
    }
  }
  
  void _handleUp(PointerUpEvent event) {
    setState(() {
      _mode = ChartInteractionMode.idle;
      _cursor = _computeCursor();
    });
  }
  
  void _handleExit() {
    setState(() {
      _hoveredElement = null;
      _cursor = SystemMouseCursors.basic;
    });
  }
  
  SystemMouseCursor _computeCursor() {
    // Active interaction takes precedence
    if (_mode == ChartInteractionMode.panning) {
      return SystemMouseCursors.grabbing;
    }
    if (_mode == ChartInteractionMode.draggingElement) {
      return SystemMouseCursors.grabbing;
    }
    if (_mode == ChartInteractionMode.resizing) {
      return _getResizeCursor(_resizeDirection);
    }
    
    // Hover state
    if (_hoveredElement != null) {
      return _getCursorForElement(_hoveredElement!);
    }
    
    // Default
    return widget.enablePan 
      ? SystemMouseCursors.grab 
      : SystemMouseCursors.basic;
  }
  
  SystemMouseCursor _getCursorForElement(ChartElement element) {
    switch (element.type) {
      case ElementType.datapoint:
        return SystemMouseCursors.click;
      case ElementType.annotation:
        return SystemMouseCursors.move;
      case ElementType.resizeHandle:
        return _getResizeCursor(element.direction);
      case ElementType.series:
        return SystemMouseCursors.click;
      case ElementType.crosshair:
        return SystemMouseCursors.precise;
      default:
        return SystemMouseCursors.basic;
    }
  }
}
```

## Coordinate Transformation: The Foundation for Zoom and Pan

### The Core Challenge

When you introduce zoom and pan, you create **two coordinate spaces** that must be synchronized:

1. **Screen Space**: Where the mouse pointer is (pixels on the device screen)
2. **Data Space**: Where your chart data lives (actual data values like time, price, etc.)

**The problem**: After zooming/panning, a datapoint at data coordinates `(100, 50)` might render at screen coordinates `(250, 150)`. But hit testing receives screen coordinates, and you need to determine which data element was hit.

**The solution**: Maintain a bidirectional transformation matrix that converts between these spaces.

### Transformation Architecture

```dart
class ChartTransform {
  // The viewport in data space coordinates
  Rect _dataViewport;
  
  // The rendering area in screen space coordinates  
  Rect _screenViewport;
  
  // Cached transformation values for performance
  double _scaleX = 1.0;
  double _scaleY = 1.0;
  double _translateX = 0.0;
  double _translateY = 0.0;
  
  ChartTransform({
    required Rect dataViewport,
    required Rect screenViewport,
  }) : _dataViewport = dataViewport,
       _screenViewport = screenViewport {
    _updateTransform();
  }
  
  void _updateTransform() {
    // Calculate scale factors
    _scaleX = _screenViewport.width / _dataViewport.width;
    _scaleY = _screenViewport.height / _dataViewport.height;
    
    // Calculate translation offsets
    _translateX = _screenViewport.left - (_dataViewport.left * _scaleX);
    _translateY = _screenViewport.top - (_dataViewport.top * _scaleY);
  }
  
  /// Convert data coordinates to screen coordinates
  Offset dataToScreen(Offset dataPoint) {
    return Offset(
      dataPoint.dx * _scaleX + _translateX,
      dataPoint.dy * _scaleY + _translateY,
    );
  }
  
  /// Convert screen coordinates to data coordinates
  Offset screenToData(Offset screenPoint) {
    return Offset(
      (screenPoint.dx - _translateX) / _scaleX,
      (screenPoint.dy - _translateY) / _scaleY,
    );
  }
  
  /// Convert data rect to screen rect
  Rect dataRectToScreen(Rect dataRect) {
    final topLeft = dataToScreen(dataRect.topLeft);
    final bottomRight = dataToScreen(dataRect.bottomRight);
    return Rect.fromPoints(topLeft, bottomRight);
  }
  
  /// Convert screen rect to data rect
  Rect screenRectToData(Rect screenRect) {
    final topLeft = screenToData(screenRect.topLeft);
    final bottomRight = screenToData(screenRect.bottomRight);
    return Rect.fromPoints(topLeft, bottomRight);
  }
  
  /// Get current zoom level (1.0 = no zoom)
  double get zoomX => _scaleX;
  double get zoomY => _scaleY;
  
  /// Get the visible data viewport
  Rect get dataViewport => _dataViewport;
  
  /// Update the data viewport (for pan/zoom)
  void setDataViewport(Rect newViewport) {
    _dataViewport = newViewport;
    _updateTransform();
  }
  
  /// Pan by delta in screen pixels
  void panByScreenDelta(Offset screenDelta) {
    // Convert screen delta to data delta
    final dataDelta = Offset(
      screenDelta.dx / _scaleX,
      screenDelta.dy / _scaleY,
    );
    
    // Shift the data viewport
    _dataViewport = _dataViewport.shift(-dataDelta);
    _updateTransform();
  }
  
  /// Zoom around a specific screen point (like mouse position)
  void zoomAroundScreenPoint(Offset screenPoint, double zoomFactor) {
    // Convert screen point to data space
    final dataPoint = screenToData(screenPoint);
    
    // Calculate new viewport dimensions
    final newWidth = _dataViewport.width / zoomFactor;
    final newHeight = _dataViewport.height / zoomFactor;
    
    // Keep the data point under the mouse in the same screen location
    final newLeft = dataPoint.dx - (dataPoint.dx - _dataViewport.left) / zoomFactor;
    final newTop = dataPoint.dy - (dataPoint.dy - _dataViewport.top) / zoomFactor;
    
    _dataViewport = Rect.fromLTWH(newLeft, newTop, newWidth, newHeight);
    _updateTransform();
  }
  
  /// Zoom to fit all data
  void zoomToFit(Rect dataBounds, {double padding = 0.1}) {
    final paddedBounds = dataBounds.inflate(
      dataBounds.width * padding
    );
    _dataViewport = paddedBounds;
    _updateTransform();
  }
  
  ChartTransform copyWith({Rect? dataViewport, Rect? screenViewport}) {
    return ChartTransform(
      dataViewport: dataViewport ?? _dataViewport,
      screenViewport: screenViewport ?? _screenViewport,
    );
  }
}
```

Source: [Coordinate transformations in graphics](https://en.wikipedia.org/wiki/Transformation_matrix)

### Integration with RenderObject Hit Testing

**Critical insight**: Hit testing receives screen coordinates, but your spatial index (QuadTree) stores data coordinates. You must transform between them:

```dart
class ChartRenderBox extends RenderBox {
  final QuadTree _spatialIndex; // Stores data coordinates
  final ChartTransform _transform;
  
  ChartRenderBox(this._state, Rect dataBounds)
    : _spatialIndex = QuadTree(boundary: dataBounds, capacity: 24),
      _transform = ChartTransform(
        dataViewport: dataBounds,
        screenViewport: Rect.fromLTWH(0, 0, 800, 600), // Updated in performLayout
      );
  
  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    if (!size.contains(position)) return false;
    
    // Convert screen position to data space for spatial query
    final dataPosition = _transform.screenToData(position);
    
    // Query in data space with tolerance
    final tolerance = 10.0 / _transform.zoomX; // Scale tolerance by zoom
    final queryRect = Rect.fromCenter(
      center: dataPosition,
      width: tolerance * 2,
      height: tolerance * 2,
    );
    
    final candidates = _spatialIndex.query(queryRect);
    
    if (candidates.isNotEmpty) {
      result.add(BoxHitTestEntry(this, position));
      return true;
    }
    
    // Accept for background pan even if no elements hit
    result.add(BoxHitTestEntry(this, position));
    return true;
  }
  
  @override
  void handleEvent(PointerEvent event, BoxHitTestEntry entry) {
    final screenPosition = entry.localPosition;
    
    if (event is PointerDownEvent) {
      if (event.buttons == kSecondaryMouseButton) {
        _handleContextMenu(screenPosition);
      } else {
        _handleDown(screenPosition);
      }
    } else if (event is PointerMoveEvent) {
      _handleMove(screenPosition, event);
    } else if (event is PointerUpEvent) {
      _handleUp(screenPosition);
    } else if (event is PointerSignalEvent && event is PointerScrollEvent) {
      _handleScroll(screenPosition, event.scrollDelta);
    }
  }
  
  void _handleDown(Offset screenPosition) {
    final element = _findElementAt(screenPosition);
    if (element != null) {
      _state.selectElement(element);
    } else {
      // Start pan - store the initial screen position
      _state.startPan(screenPosition);
    }
  }
  
  void _handleMove(Offset screenPosition, PointerMoveEvent event) {
    if (_state.isPanning) {
      // Pan by the screen delta
      final delta = event.delta;
      _transform.panByScreenDelta(delta);
      _state.notifyPanned();
      markNeedsPaint();
    } else if (_state.isDraggingElement) {
      // When dragging an element, convert screen delta to data delta
      final dataDelta = Offset(
        event.delta.dx / _transform.zoomX,
        event.delta.dy / _transform.zoomY,
      );
      _state.updateDraggedElement(dataDelta);
      markNeedsPaint();
    }
  }
  
  void _handleScroll(Offset screenPosition, Offset scrollDelta) {
    // Determine zoom factor from scroll
    final zoomFactor = 1.0 + (scrollDelta.dy * 0.001);
    
    // Zoom around the mouse position
    _transform.zoomAroundScreenPoint(screenPosition, zoomFactor);
    markNeedsPaint();
  }
  
  ChartElement? _findElementAt(Offset screenPosition) {
    // Convert to data space
    final dataPosition = _transform.screenToData(screenPosition);
    
    // Query spatial index in data space
    final tolerance = 10.0 / _transform.zoomX; // Hit tolerance in data space
    final queryRect = Rect.fromCenter(
      center: dataPosition,
      width: tolerance * 2,
      height: tolerance * 2,
    );
    
    final candidates = _spatialIndex.query(queryRect);
    
    // Check each candidate - elements store data coordinates
    for (final id in candidates) {
      final element = _state.getElement(id);
      
      // Element has data coordinates, check distance in data space
      final distance = (element.dataPosition - dataPosition).distance;
      if (distance <= tolerance) {
        return element;
      }
    }
    return null;
  }
  
  @override
  void paint(PaintingContext context, Offset offset) {
    final canvas = context.canvas;
    canvas.save();
    canvas.translate(offset.dx, offset.dy);
    
    // Calculate visible data viewport
    final visibleDataRect = _transform.dataViewport;
    
    // Query only visible elements from spatial index (in data space)
    final visibleIds = _spatialIndex.query(visibleDataRect);
    
    // Draw elements, converting their data coords to screen coords
    for (final id in visibleIds) {
      final element = _state.getElement(id);
      final screenPos = _transform.dataToScreen(element.dataPosition);
      
      // Draw at screen position
      _drawElement(canvas, element, screenPos);
    }
    
    canvas.restore();
  }
  
  @override
  void performLayout() {
    size = constraints.biggest;
    
    // Update screen viewport when size changes
    _transform.setScreenViewport(Rect.fromLTWH(0, 0, size.width, size.height));
  }
}
```

### Zoom and Pan State Management

```dart
enum ChartInteractionMode {
  idle,
  panning,
  selecting,
  draggingElement,
  zooming,
}

class ChartState extends ChangeNotifier {
  ChartInteractionMode _mode = ChartInteractionMode.idle;
  
  // Pan state
  Offset? _panStartPosition;
  
  // Zoom constraints
  double _minZoom = 0.1;
  double _maxZoom = 10.0;
  
  // Data bounds (never changes)
  final Rect _fullDataBounds;
  
  // Current viewport in data space
  Rect _currentDataViewport;
  
  ChartState({required Rect dataBounds})
    : _fullDataBounds = dataBounds,
      _currentDataViewport = dataBounds;
  
  bool get isPanning => _mode == ChartInteractionMode.panning;
  bool get isDraggingElement => _mode == ChartInteractionMode.draggingElement;
  
  void startPan(Offset screenPosition) {
    _panStartPosition = screenPosition;
    _mode = ChartInteractionMode.panning;
    notifyListeners();
  }
  
  void notifyPanned() {
    notifyListeners();
  }
  
  void endPan() {
    _panStartPosition = null;
    _mode = ChartInteractionMode.idle;
    notifyListeners();
  }
  
  void zoom(double factor, {Rect? limits}) {
    // Apply zoom constraints
    final currentZoom = _fullDataBounds.width / _currentDataViewport.width;
    final newZoom = (currentZoom * factor).clamp(_minZoom, _maxZoom);
    final actualFactor = newZoom / currentZoom;
    
    // Update viewport
    final center = _currentDataViewport.center;
    final newWidth = _currentDataViewport.width / actualFactor;
    final newHeight = _currentDataViewport.height / actualFactor;
    
    _currentDataViewport = Rect.fromCenter(
      center: center,
      width: newWidth,
      height: newHeight,
    );
    
    // Constrain to data bounds
    _constrainViewport(limits);
    notifyListeners();
  }
  
  void _constrainViewport(Rect? limits) {
    final bounds = limits ?? _fullDataBounds;
    
    // Don't allow panning beyond data bounds
    double left = _currentDataViewport.left;
    double top = _currentDataViewport.top;
    double right = _currentDataViewport.right;
    double bottom = _currentDataViewport.bottom;
    
    if (left < bounds.left) {
      final shift = bounds.left - left;
      left += shift;
      right += shift;
    }
    if (right > bounds.right) {
      final shift = right - bounds.right;
      left -= shift;
      right -= shift;
    }
    if (top < bounds.top) {
      final shift = bounds.top - top;
      top += shift;
      bottom += shift;
    }
    if (bottom > bounds.bottom) {
      final shift = bottom - bounds.bottom;
      top -= shift;
      bottom -= shift;
    }
    
    _currentDataViewport = Rect.fromLTRB(left, top, right, bottom);
  }
  
  void resetZoom() {
    _currentDataViewport = _fullDataBounds;
    notifyListeners();
  }
}
```

### Overlay Widget Positioning with Transforms

**Critical issue**: Positioned overlay widgets (like annotation handles) need to update their screen positions when zoom/pan changes:

```dart
class ChartWithOverlays extends StatefulWidget {
  @override
  State<ChartWithOverlays> createState() => _ChartWithOverlaysState();
}

class _ChartWithOverlaysState extends State<ChartWithOverlays> {
  final ChartState _state = ChartState(dataBounds: Rect.fromLTWH(0, 0, 100, 100));
  late ChartTransform _transform;
  
  @override
  void initState() {
    super.initState();
    _transform = ChartTransform(
      dataViewport: _state._currentDataViewport,
      screenViewport: Rect.fromLTWH(0, 0, 800, 600),
    );
    
    // Listen to state changes to update transform
    _state.addListener(_updateTransform);
  }
  
  void _updateTransform() {
    setState(() {
      _transform.setDataViewport(_state._currentDataViewport);
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Update screen viewport on layout
        _transform.setScreenViewport(
          Rect.fromLTWH(0, 0, constraints.maxWidth, constraints.maxHeight)
        );
        
        return ListenableBuilder(
          listenable: _state,
          builder: (context, _) {
            return Stack(
              children: [
                // Base chart with transform
                ChartWidget(
                  state: _state,
                  transform: _transform,
                ),
                
                // Positioned overlays - convert data coords to screen coords
                ..._buildAnnotationHandles(),
                
                // Non-transformed overlays (like crosshair)
                if (_state.showCrosshair)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: CustomPaint(
                        painter: CrosshairPainter(_state.crosshairPosition),
                      ),
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }
  
  List<Widget> _buildAnnotationHandles() {
    return _state.annotations.map((annotation) {
      // Convert annotation's DATA coordinates to SCREEN coordinates
      final screenPos = _transform.dataToScreen(annotation.dataPosition);
      
      return Positioned(
        left: screenPos.dx - 8,
        top: screenPos.dy - 8,
        child: MouseRegion(
          cursor: SystemMouseCursors.move,
          child: GestureDetector(
            onPanStart: (_) => _state.startDragAnnotation(annotation),
            onPanUpdate: (details) {
              // Convert screen delta to data delta
              final dataDelta = Offset(
                details.delta.dx / _transform.zoomX,
                details.delta.dy / _transform.zoomY,
              );
              _state.updateAnnotationPosition(dataDelta);
            },
            onPanEnd: (_) => _state.endDragAnnotation(),
            child: Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.blue),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
      );
    }).toList();
  }
  
  @override
  void dispose() {
    _state.removeListener(_updateTransform);
    super.dispose();
  }
}
```

### Advanced: Momentum Panning

For better UX, implement momentum-based panning (fling gesture):

```dart
class ChartRenderBox extends RenderBox {
  AnimationController? _panMomentumController;
  Offset _panVelocity = Offset.zero;
  Offset _lastPanPosition = Offset.zero;
  DateTime _lastPanTime = DateTime.now();
  
  void _handlePanStart(Offset position) {
    _panMomentumController?.stop();
    _lastPanPosition = position;
    _lastPanTime = DateTime.now();
    _panVelocity = Offset.zero;
  }
  
  void _handlePanUpdate(Offset position, Offset delta) {
    final now = DateTime.now();
    final elapsed = now.difference(_lastPanTime).inMilliseconds;
    
    if (elapsed > 0) {
      // Calculate velocity
      _panVelocity = Offset(
        delta.dx / elapsed * 1000,
        delta.dy / elapsed * 1000,
      );
    }
    
    _lastPanPosition = position;
    _lastPanTime = now;
    
    // Apply pan
    _transform.panByScreenDelta(delta);
    markNeedsPaint();
  }
  
  void _handlePanEnd() {
    final velocityMagnitude = _panVelocity.distance;
    
    // Only apply momentum if velocity is significant
    if (velocityMagnitude > 100) {
      _startMomentumPan(_panVelocity);
    }
  }
  
  void _startMomentumPan(Offset velocity) {
    _panMomentumController?.dispose();
    _panMomentumController = AnimationController(
      vsync: this, // Assumes RenderBox has TickerProviderStateMixin
      duration: Duration(milliseconds: 500),
    );
    
    final curve = Curves.decelerate;
    
    _panMomentumController!.addListener(() {
      final t = curve.transform(_panMomentumController!.value);
      final damping = 1.0 - t;
      
      final delta = Offset(
        velocity.dx * damping * 0.016, // Assume 60fps
        velocity.dy * damping * 0.016,
      );
      
      _transform.panByScreenDelta(delta);
      markNeedsPaint();
    });
    
    _panMomentumController!.forward();
  }
}
```

### Zoom Constraints and Boundaries

Prevent zooming too far in/out or panning beyond data bounds:

```dart
class ChartTransform {
  final Rect _dataBounds; // The full extent of all data
  double _minZoomLevel = 0.1;
  double _maxZoomLevel = 10.0;
  
  void setZoomConstraints({double? minZoom, double? maxZoom}) {
    _minZoomLevel = minZoom ?? _minZoomLevel;
    _maxZoomLevel = maxZoom ?? _maxZoomLevel;
  }
  
  void zoomAroundScreenPoint(Offset screenPoint, double zoomFactor) {
    // Calculate desired zoom level
    final currentZoom = _dataBounds.width / _dataViewport.width;
    final targetZoom = (currentZoom * zoomFactor).clamp(_minZoomLevel, _maxZoomLevel);
    final actualFactor = targetZoom / currentZoom;
    
    if ((actualFactor - 1.0).abs() < 0.001) return; // No change
    
    // Convert screen point to data space
    final dataPoint = screenToData(screenPoint);
    
    // Calculate new viewport dimensions
    final newWidth = _dataViewport.width / actualFactor;
    final newHeight = _dataViewport.height / actualFactor;
    
    // Keep the data point under the mouse in the same screen location
    final newLeft = dataPoint.dx - (dataPoint.dx - _dataViewport.left) / actualFactor;
    final newTop = dataPoint.dy - (dataPoint.dy - _dataViewport.top) / actualFactor;
    
    _dataViewport = Rect.fromLTWH(newLeft, newTop, newWidth, newHeight);
    
    // Constrain to data bounds
    _constrainViewportToBounds();
    _updateTransform();
  }
  
  void panByScreenDelta(Offset screenDelta) {
    // Convert screen delta to data delta
    final dataDelta = Offset(
      screenDelta.dx / _scaleX,
      screenDelta.dy / _scaleY,
    );
    
    // Shift the data viewport
    _dataViewport = _dataViewport.shift(-dataDelta);
    
    // Constrain to bounds
    _constrainViewportToBounds();
    _updateTransform();
  }
  
  void _constrainViewportToBounds() {
    double left = _dataViewport.left;
    double top = _dataViewport.top;
    double width = _dataViewport.width;
    double height = _dataViewport.height;
    
    // Don't allow viewport to go outside data bounds
    if (left < _dataBounds.left) {
      left = _dataBounds.left;
    }
    if (top < _dataBounds.top) {
      top = _dataBounds.top;
    }
    if (left + width > _dataBounds.right) {
      left = _dataBounds.right - width;
    }
    if (top + height > _dataBounds.bottom) {
      top = _dataBounds.bottom - height;
    }
    
    // If viewport is larger than bounds (zoomed out too far), center it
    if (width > _dataBounds.width) {
      left = _dataBounds.left - (width - _dataBounds.width) / 2;
    }
    if (height > _dataBounds.height) {
      top = _dataBounds.top - (height - _dataBounds.height) / 2;
    }
    
    _dataViewport = Rect.fromLTWH(left, top, width, height);
  }
}
```

### Performance: Culling Off-Screen Elements

With zoom, most elements may be off-screen. Use the transform to efficiently cull:

```dart
@override
void paint(PaintingContext context, Offset offset) {
  final canvas = context.canvas;
  canvas.save();
  canvas.translate(offset.dx, offset.dy);
  
  // Get visible data viewport with slight padding for smooth panning
  final visibleDataRect = _transform.dataViewport.inflate(
    _transform.dataViewport.width * 0.1 // 10% padding
  );
  
  // Query only elements in visible data space
  final visibleIds = _spatialIndex.query(visibleDataRect);
  
  // Only draw visible elements
  for (final id in visibleIds) {
    final element = _state.getElement(id);
    final screenPos = _transform.dataToScreen(element.dataPosition);
    
    // Additional screen-space culling for precision
    if (_screenViewport.inflate(20).contains(screenPos)) {
      _drawElement(canvas, element, screenPos);
    }
  }
  
  canvas.restore();
}
```

### Zoom/Pan Best Practices Summary

1. **Two coordinate spaces**: Always maintain data space (unchanged) and screen space (transforms applied)
2. **Store in data space**: Keep all element positions in data coordinates in the spatial index
3. **Transform for rendering**: Convert data coords to screen coords only during paint
4. **Transform for hit testing**: Convert screen coords to data coords for spatial queries
5. **Scale hit tolerance**: Divide screen-space hit tolerance by zoom level to maintain consistent data-space tolerance
6. **Constrain viewport**: Prevent panning/zooming beyond reasonable bounds
7. **Update overlays**: Positioned widgets must recalculate screen positions on every transform change
8. **Momentum for UX**: Implement fling gestures for natural panning feel
9. **Cull aggressively**: Use the transform's visible data rect to query only what's on screen

### Complete Zoom/Pan Integration Example

```dart
class ChartWidget extends LeafRenderObjectWidget {
  final ChartState state;
  final ChartTransform transform;
  
  const ChartWidget({
    required this.state,
    required this.transform,
  });
  
  @override
  RenderObject createRenderObject(BuildContext context) {
    return ChartRenderBox(state, transform);
  }
  
  @override
  void updateRenderObject(BuildContext context, ChartRenderBox renderObject) {
    renderObject
      ..state = state
      ..transform = transform
      ..markNeedsPaint();
  }
}

class ChartRenderBox extends RenderBox {
  ChartState _state;
  ChartTransform _transform;
  final QuadTree _spatialIndex;
  
  bool _isPanning = false;
  Offset _lastPanPosition = Offset.zero;
  
  ChartRenderBox(this._state, this._transform)
    : _spatialIndex = QuadTree(
        boundary: _transform._dataBounds,
        capacity: 24,
      );
  
  set state(ChartState value) {
    if (_state == value) return;
    _state = value;
  }
  
  set transform(ChartTransform value) {
    if (_transform == value) return;
    _transform = value;
  }
  
  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    if (!size.contains(position)) return false;
    result.add(BoxHitTestEntry(this, position));
    return true;
  }
  
  @override
  void handleEvent(PointerEvent event, BoxHitTestEntry entry) {
    final screenPosition = entry.localPosition;
    
    if (event is PointerDownEvent) {
      final element = _findElementAt(screenPosition);
      if (element != null) {
        _state.selectElement(element);
      } else if (event.buttons == kPrimaryMouseButton) {
        _isPanning = true;
        _lastPanPosition = screenPosition;
      }
    } else if (event is PointerMoveEvent) {
      if (_isPanning) {
        final delta = screenPosition - _lastPanPosition;
        _transform.panByScreenDelta(delta);
        _lastPanPosition = screenPosition;
        markNeedsPaint();
      }
    } else if (event is PointerUpEvent) {
      _isPanning = false;
    } else if (event is PointerSignalEvent && event is PointerScrollEvent) {
      final zoomFactor = 1.0 - (event.scrollDelta.dy * 0.001);
      _transform.zoomAroundScreenPoint(screenPosition, zoomFactor);
      markNeedsPaint();
    }
  }
  
  ChartElement? _findElementAt(Offset screenPosition) {
    final dataPosition = _transform.screenToData(screenPosition);
    final tolerance = 10.0 / _transform.zoomX;
    
    final queryRect = Rect.fromCenter(
      center: dataPosition,
      width: tolerance * 2,
      height: tolerance * 2,
    );
    
    final candidates = _spatialIndex.query(queryRect);
    
    for (final id in candidates) {
      final element = _state.getElement(id);
      final distance = (element.dataPosition - dataPosition).distance;
      if (distance <= tolerance) {
        return element;
      }
    }
    return null;
  }
  
  @override
  void paint(PaintingContext context, Offset offset) {
    final canvas = context.canvas;
    canvas.save();
    canvas.translate(offset.dx, offset.dy);
    
    // Cull to visible viewport
    final visibleDataRect = _transform.dataViewport.inflate(
      _transform.dataViewport.width * 0.1
    );
    final visibleIds = _spatialIndex.query(visibleDataRect);
    
    // Draw visible elements
    for (final id in visibleIds) {
      final element = _state.getElement(id);
      final screenPos = _transform.dataToScreen(element.dataPosition);
      
      canvas.drawCircle(
        screenPos,
        4.0,
        Paint()..color = Colors.blue,
      );
    }
    
    canvas.restore();
  }
  
  @override
  void performLayout() {
    size = constraints.biggest;
    _transform.setScreenViewport(Rect.fromLTWH(0, 0, size.width, size.height));
  }
}
```

## Architecture Patterns from Production Chart Libraries

### fl_chart: Event-Based Architecture

fl_chart uses a callback-based system where touch events are captured, processed to determine which elements were touched, and wrapped into typed response objects.

**Key pattern**: The `distanceCalculator` function determines which element is "closest" when multiple overlap:

```dart
LineTouchData(
  enabled: true,
  touchCallback: (FlTouchEvent event, LineTouchResponse? response) {
    if (event is FlTapUpEvent && response != null) {
      for (final spot in response.lineBarSpots ?? []) {
        print('Series ${spot.barIndex}, Point ${spot.spotIndex}');
      }
    }
  },
  handleBuiltInTouches: false, // Disable default, implement custom
  touchSpotThreshold: 10, // Max distance in pixels
  distanceCalculator: (spot, touchPoint) {
    // Custom 2D distance instead of X-only
    final dx = spot.x - touchPoint.dx;
    final dy = spot.y - touchPoint.dy;
    return sqrt(dx * dx + dy * dy);
  },
)
```

**Key insight**: For overlapping elements, **a single touch event handler with position-based routing is more reliable than multiple competing GestureDetectors**.

Source: [fl_chart LineTouchData](https://pub.dev/documentation/fl_chart/latest/fl_chart/LineTouchData-class.html)

### Syncfusion: Behavior-Based Architecture

Syncfusion uses a compositional behavior pattern where `TooltipBehavior`, `ZoomPanBehavior`, `SelectionBehavior`, etc. are separate objects:

```dart
SfCartesianChart(
  zoomPanBehavior: ZoomPanBehavior(
    enablePanning: true,
    enablePinching: true,
  ),
  tooltipBehavior: TooltipBehavior(
    enable: true,
    activationMode: ActivationMode.singleTap,
  ),
  selectionGesture: ActivationMode.singleTap,
  onChartTouchInteractionDown: (ChartTouchInteractionArgs args) {
    // Custom handling
  },
)
```

**Key insight**: Each behavior handles a specific concern, preventing conflicts through **compositional separation**.

Source: [Syncfusion callbacks documentation](https://help.syncfusion.com/flutter/cartesian-charts/callbacks)

### Google Charts (charts_flutter): Dual SelectionModel

Separates read vs write interactions:

- `SelectionModelType.info`: For exploration (hover)
- `SelectionModelType.action`: For input (click)

```dart
SelectionModelConfig(
  type: SelectionModelType.info,
  changedListener: (SelectionModel model) {
    // Show tooltip on hover
  },
),
SelectionModelConfig(
  type: SelectionModelType.action,
  changedListener: (SelectionModel model) {
    // Perform selection on click
  },
),
```

Source: [charts_flutter SelectionModel](https://pub.dev/documentation/charts_flutter_new/latest/flutter/SelectionModel-class.html)

### Universal Pattern: Single Handler + Position Routing

All three libraries converge on this pattern:

1. **One touch handler** receives all events
2. **Query spatial index** to find which elements intersect the position
3. **Dispatch to handlers** based on priority and context

This is superior to multiple competing GestureDetectors.

## Performance Optimization for Large-Scale Interactive Elements

### Critical Optimization 1: GPU Batching with drawRawAtlas

Drawing hundreds of datapoint circles individually generates separate GPU commands. Batch them:

```dart
class OptimizedChartPainter extends CustomPainter {
  final ui.Image atlasImage; // Pre-loaded sprite atlas
  final List<DataPoint> dataPoints;
  
  @override
  void paint(Canvas canvas, Size size) {
    final visible = dataPoints.where((p) => viewport.contains(p.position));
    final count = visible.length;
    
    // Prepare batched draw data
    final transforms = Float32List(count * 4);
    final rects = Float32List(count * 4);
    
    int i = 0;
    for (final point in visible) {
      // RSTransform: scos, ssin, tx, ty
      transforms[i * 4 + 0] = 1.0; // scale (scos)
      transforms[i * 4 + 1] = 0.0; // rotation (ssin)
      transforms[i * 4 + 2] = point.x; // translate x
      transforms[i * 4 + 3] = point.y; // translate y
      
      // Source rect in atlas
      rects[i * 4 + 0] = 0;
      rects[i * 4 + 1] = 0;
      rects[i * 4 + 2] = 16;
      rects[i * 4 + 3] = 16;
      
      i++;
    }
    
    // Single GPU command for all datapoints
    canvas.drawRawAtlas(
      atlasImage,
      transforms,
      rects,
      null, // colors
      BlendMode.srcOver,
      null, // cullRect
      Paint(),
    );
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
```

Source: [High-performance canvas rendering](https://plugfox.dev/high-performance-canvas-rendering/)

### Critical Optimization 2: Spatial Indexing with QuadTree

Without spatial indexing, hit testing is O(n). With QuadTree, it's O(log n):

```dart
class ChartScene {
  final QuadTree quadTree;
  final Map<String, ChartElement> _elements = {};
  
  ChartScene(Rect bounds) 
    : quadTree = QuadTree(boundary: bounds, capacity: 24);
  
  void addElement(ChartElement element) {
    final id = element.id;
    quadTree.insert(element.bounds, data: id);
    _elements[id] = element;
  }
  
  ChartElement? hitTest(Offset position) {
    final region = Rect.fromCenter(
      center: position, 
      width: 20, 
      height: 20,
    );
    
    final candidateIds = quadTree.query(region);
    
    // Test only nearby candidates
    for (final id in candidateIds) {
      final element = _elements[id];
      if (element?.contains(position) ?? false) {
        return element;
      }
    }
    return null;
  }
  
  List<ChartElement> getVisible(Rect viewport) {
    final ids = quadTree.query(viewport.inflate(32));
    return ids.map((id) => _elements[id]!).toList();
  }
}
```

### Critical Optimization 3: RepaintBoundary Isolation

Wrap your chart in `RepaintBoundary` to isolate it from parent rebuilds:

```dart
RepaintBoundary(
  child: CustomPaint(
    painter: ChartPainter(repaint: animationController),
  ),
)
```

For custom RenderObject, override:

```dart
@override
bool get isRepaintBoundary => true;
```

**Warning**: Overusing RepaintBoundary increases GPU memory. Measure with DevTools.

Source: [RepaintBoundary documentation](https://api.flutter.dev/flutter/widgets/RepaintBoundary-class.html)

### Anti-Pattern: Wrapping CustomPaint in Builders

```dart
// âŒ WRONG - rebuilds widget tree every frame
AnimatedBuilder(
  animation: controller,
  builder: (context, _) => CustomPaint(
    painter: ChartPainter(),
  ),
)

// âœ… CORRECT - only repaints, no widget rebuild
CustomPaint(
  painter: ChartPainter(repaint: controller),
)

class ChartPainter extends CustomPainter {
  ChartPainter({Listenable? repaint}) : super(repaint: repaint);
}
```

Source: [CustomPaint performance](https://github.com/flutter/flutter/issues/72066)

## Complete Architecture Example

### Structure

```
Chart (Custom RenderBox)
â”œâ”€â”€ Handles all pointer events
â”œâ”€â”€ Uses QuadTree for spatial queries
â”œâ”€â”€ Batched GPU rendering
â””â”€â”€ Positioned overlay widgets
    â”œâ”€â”€ Draggable annotation handles
    â”œâ”€â”€ Context menu (AbsorbPointer)
    â””â”€â”€ Crosshair (IgnorePointer)
```

### Base Layer: Custom RenderBox

```dart
class ChartRenderBox extends RenderBox {
  final QuadTree _spatialIndex;
  final ChartState _state;
  Ticker? _ticker;
  
  ChartRenderBox(this._state, Rect bounds)
    : _spatialIndex = QuadTree(boundary: bounds, capacity: 24);
  
  @override
  bool get isRepaintBoundary => true;
  
  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _state.addListener(markNeedsPaint);
    _ticker = Ticker(_onTick)..start();
  }
  
  @override
  void detach() {
    _ticker?.dispose();
    _state.removeListener(markNeedsPaint);
    super.detach();
  }
  
  void _onTick(Duration elapsed) {
    // Update animations
  }
  
  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    if (!size.contains(position)) return false;
    
    final candidates = _spatialIndex.query(
      Rect.fromCenter(center: position, width: 20, height: 20)
    );
    
    if (candidates.isNotEmpty) {
      result.add(BoxHitTestEntry(this, position));
      return true;
    }
    
    // Accept for background pan even if no elements hit
    result.add(BoxHitTestEntry(this, position));
    return true;
  }
  
  @override
  void handleEvent(PointerEvent event, BoxHitTestEntry entry) {
    final position = entry.localPosition;
    
    if (event is PointerDownEvent) {
      if (event.buttons == kSecondaryMouseButton) {
        _handleContextMenu(position);
      } else {
        _handleDown(position);
      }
    } else if (event is PointerMoveEvent) {
      _handleMove(position);
    } else if (event is PointerUpEvent) {
      _handleUp(position);
    } else if (event is PointerSignalEvent && event is PointerScrollEvent) {
      _handleScroll(event.scrollDelta);
    }
  }
  
  void _handleDown(Offset position) {
    final element = _findElementAt(position);
    if (element != null) {
      _state.selectElement(element);
    } else {
      _state.startPan(position);
    }
  }
  
  ChartElement? _findElementAt(Offset position) {
    final region = Rect.fromCenter(center: position, width: 20, height: 20);
    final candidates = _spatialIndex.query(region);
    
    // Check in priority order
    for (final id in candidates) {
      final element = _state.getElement(id);
      if (element.contains(position)) {
        return element;
      }
    }
    return null;
  }
  
  @override
  void paint(PaintingContext context, Offset offset) {
    final canvas = context.canvas;
    canvas.save();
    canvas.translate(offset.dx, offset.dy);
    
    final visible = _spatialIndex.query(_state.viewport);
    
    // Batch render all datapoints
    _drawDataPointsBatched(canvas, visible);
    
    // Draw series lines
    _drawSeriesLines(canvas, visible);
    
    canvas.restore();
  }
  
  void _drawDataPointsBatched(Canvas canvas, List<String> visibleIds) {
    // Implementation with drawRawAtlas
  }
  
  @override
  void performLayout() {
    size = constraints.biggest;
  }
}
```

### Overlay Layer: Positioned Widgets

```dart
class ChartWithOverlays extends StatefulWidget {
  @override
  State<ChartWithOverlays> createState() => _ChartWithOverlaysState();
}

class _ChartWithOverlaysState extends State<ChartWithOverlays> {
  final ChartState _state = ChartState();
  
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _state,
      builder: (context, _) {
        return Stack(
          children: [
            // Base chart
            ChartWidget(state: _state),
            
            // Interactive overlays
            ..._buildAnnotationHandles(),
            
            // Crosshair
            if (_state.showCrosshair)
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: CrosshairPainter(_state.crosshairPosition),
                  ),
                ),
              ),
            
            // Context menu
            if (_state.showContextMenu)
              Positioned(
                left: _state.menuPosition.dx,
                top: _state.menuPosition.dy,
                child: AbsorbPointer(
                  child: ContextMenu(
                    options: _state.contextMenuOptions,
                    onSelect: _state.handleMenuSelection,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
  
  List<Widget> _buildAnnotationHandles() {
    return _state.annotations.map((annotation) {
      return Positioned(
        left: annotation.position.dx - 8,
        top: annotation.position.dy - 8,
        child: MouseRegion(
          cursor: SystemMouseCursors.move,
          child: GestureDetector(
            onPanStart: (_) => _state.startDragAnnotation(annotation),
            onPanUpdate: (details) => 
              _state.updateAnnotationPosition(details.delta),
            onPanEnd: (_) => _state.endDragAnnotation(),
            child: Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.blue),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
      );
    }).toList();
  }
}
```

### State Management

```dart
enum InteractionMode {
  idle,
  panning,
  selecting,
  draggingAnnotation,
}

class ChartState extends ChangeNotifier {
  InteractionMode _mode = InteractionMode.idle;
  ChartElement? _selectedElement;
  Offset? crosshairPosition;
  bool showCrosshair = false;
  bool showContextMenu = false;
  Offset menuPosition = Offset.zero;
  
  void selectElement(ChartElement element) {
    _selectedElement = element;
    _mode = InteractionMode.selecting;
    notifyListeners();
  }
  
  void startPan(Offset position) {
    _mode = InteractionMode.panning;
    notifyListeners();
  }
  
  void startDragAnnotation(Annotation annotation) {
    _mode = InteractionMode.draggingAnnotation;
    notifyListeners();
  }
  
  bool canInteract(InteractionMode mode) {
    return _mode == InteractionMode.idle || _mode == mode;
  }
}
```

## Key Takeaways

1. **The gesture arena is competitive** - Child widgets win by default, causing conflicts

2. **Custom recognizers solve conflicts** - Use context-aware recognizers that accept/reject based on position

3. **Custom RenderObject for scale** - Bypasses gesture arena, provides pixel-perfect control, better performance

4. **Layer your event handlers**:
   - `Listener` for raw events + right-click + wheel
   - `MouseRegion` for hover (doesn't participate in arena)
   - `GestureDetector` for semantic gestures (optional)

5. **Single handler + position routing** - Production libraries use one touch handler with spatial queries, not multiple competing GestureDetectors

6. **Performance trinity**:
   - GPU batching with `drawRawAtlas`
   - Spatial indexing with QuadTree
   - `RepaintBoundary` isolation

7. **State coordination** - Use explicit interaction modes to prevent "fixing one breaks another"

8. **Two coordinate spaces are essential** - Maintain data space (unchanging) and screen space (after transforms). Store elements in data space, transform only for rendering.

9. **Hit testing with zoom** - Convert screen coordinates to data coordinates, scale hit tolerance by zoom level to maintain consistent interaction distance

10. **Positioned overlays must update** - When zoom/pan changes, recalculate all overlay widget positions from data coords to screen coords

11. **Cursor feedback with transforms** - Maintain cursor state based on interaction mode (grab → grabbing → grab transition) independent of coordinate transforms

## Additional Resources

- [Flutter gesture documentation](https://docs.flutter.dev/ui/interactivity/gestures)
- [Gesture arena deep dive](https://medium.com/flutter-community/flutter-deep-dive-gestures-c16203b3434f)
- [RenderObject documentation](https://api.flutter.dev/flutter/rendering/RenderObject-class.html)
- [fl_chart source code](https://github.com/imaNNeo/fl_chart)
- [High-performance canvas rendering](https://plugfox.dev/high-performance-canvas-rendering/)
- [RepaintBoundary optimization](https://api.flutter.dev/flutter/widgets/RepaintBoundary-class.html)

---

**For your complex charting package**: Start with a custom RenderObject for the base chart handling all pointer events with QuadTree spatial indexing. Add positioned overlay widgets with MouseRegion for high-priority interactions like annotation dragging. Use explicit state management with interaction modes to coordinate which gesture is active. Implement a `ChartTransform` class to manage the bidirectional conversion between data space and screen space, storing all elements in data coordinates and transforming only during rendering and hit testing. Scale hit tolerance by zoom level to maintain consistent interaction feel. This architecture scales to hundreds of interactive elements with zoom/pan while preventing the "fixing one event breaks another" problem.
