# Architecting Complex Mouse Events in Flutter: A Guide for Overlapping Interactive Chart Widgets

**Your core problem: "fixing one event breaks another"** - This happens because Flutter's gesture system uses a competitive arena where recognizers battle for control, and changing one widget's behavior affects the entire competition. For your complex charting package with overlapping datapoints, annotations, crosshairs, and context menus, the solution requires understanding three architectural layers working together strategically.

## Table of Contents

1. [Understanding Flutter's Hit Testing and Gesture Arena](#understanding-flutters-hit-testing-and-gesture-arena)
2. [The Core Problem: Why Events Conflict](#the-core-problem-why-events-conflict)
3. [Solution 1: Custom Gesture Recognizers with Context-Aware Logic](#solution-1-custom-gesture-recognizers-with-context-aware-logic)
4. [Solution 2: Custom RenderObject Approach](#solution-2-custom-renderobject-approach)
5. [Handling All Mouse Event Types](#handling-all-mouse-event-types)
6. [Architecture Patterns from Production Chart Libraries](#architecture-patterns-from-production-chart-libraries)
7. [Performance Optimization for Large-Scale Interactive Elements](#performance-optimization-for-large-scale-interactive-elements)
8. [Complete Architecture Example](#complete-architecture-example)

## Understanding Flutter's Hit Testing and Gesture Arena

### Hit Testing Fundamentals

Flutter's hit testing operates through a **two-phase process** that's fundamentally different from traditional event bubbling:

1. **Downward traversal**: When a pointer touches the screen, Flutter traverses from the render tree root to leaves, testing each node to build a `HitTestResult` containing all widgets intersecting the touch point
2. **Reverse paint order**: Results are in reverse paint order—the deepest (topmost visually) widget is tested first

**Critical insight**: In a Stack, the last child (visually on top) is tested first, and if it returns true from `hitTest()`, lower widgets may not be tested at all depending on `HitTestBehavior`.

Source: [Flutter gesture documentation](https://docs.flutter.dev/ui/interactivity/gestures)

### HitTestBehavior: The Misunderstood Enum

The three behaviors are frequently misunderstood:

- **`HitTestBehavior.opaque`**: The widget participates in hit testing across its entire bounds AND prevents widgets behind it from being tested. **Common misconception**: It does NOT block children—children still receive events normally.
  
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
└── Datapoint overlay (wants tap)
    └── Annotation handle (wants drag)
```

All three widgets create gesture recognizers that enter the arena. The annotation handle's recognizer enters first and wins, preventing the datapoint tap and background pan from firing—even when you tap empty space near the annotation.

## The Core Problem: Why Events Conflict

### Scenario 1: Nested GestureDetectors

```dart
// ❌ PROBLEM: Child always wins, parent never fires
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

All four interaction types compete, and whichever recognizer enters the arena first wins—even if it's not the most appropriate for the user's intent.

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
// ❌ WRONG - cursor reverts to basic during drag
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
// ✅ CORRECT - cursor stays grabbing during drag
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
   Hover → grab
   Mouse down → grabbing
   Drag → keep grabbing
   Mouse up → back to grab (if still hovering) or basic
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
// ❌ WRONG - rebuilds widget tree every frame
AnimatedBuilder(
  animation: controller,
  builder: (context, _) => CustomPaint(
    painter: ChartPainter(),
  ),
)

// ✅ CORRECT - only repaints, no widget rebuild
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
├── Handles all pointer events
├── Uses QuadTree for spatial queries
├── Batched GPU rendering
└── Positioned overlay widgets
    ├── Draggable annotation handles
    ├── Context menu (AbsorbPointer)
    └── Crosshair (IgnorePointer)
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

## Additional Resources

- [Flutter gesture documentation](https://docs.flutter.dev/ui/interactivity/gestures)
- [Gesture arena deep dive](https://medium.com/flutter-community/flutter-deep-dive-gestures-c16203b3434f)
- [RenderObject documentation](https://api.flutter.dev/flutter/rendering/RenderObject-class.html)
- [fl_chart source code](https://github.com/imaNNeo/fl_chart)
- [High-performance canvas rendering](https://plugfox.dev/high-performance-canvas-rendering/)
- [RepaintBoundary optimization](https://api.flutter.dev/flutter/widgets/RepaintBoundary-class.html)

---

**For your complex charting package**: Start with a custom RenderObject for the base chart handling all pointer events with QuadTree spatial indexing. Add positioned overlay widgets with MouseRegion for high-priority interactions like annotation dragging. Use explicit state management with interaction modes to coordinate which gesture is active. This architecture scales to hundreds of interactive elements while preventing the "fixing one event breaks another" problem.
