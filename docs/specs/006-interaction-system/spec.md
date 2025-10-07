# Feature Specification: Interaction System

**Feature**: Interaction System (Layer 6)  
**Status**: Draft Specification  
**Created**: 2025-01-07  
**Dependencies**: Layer 0 (Foundation), Layer 1 (Core Rendering), Layer 2 (Coordinate System), Layer 3 (Theming), Layer 4 (Chart Types), Layer 5 (Chart Widgets)

---

## 📋 Overview

### Purpose

Provide a professional-grade interaction system that enables users to explore chart data through mouse, touch, and keyboard inputs. The system delivers crosshairs, tooltips, zoom/pan controls, and gesture recognition while maintaining 60 FPS performance and conflict-free multi-input support.

### Problem Statement

**Current State (Layer 5):**
Layer 5 provides chart widgets with basic rendering and data display, but lacks user interaction capabilities:

- No data point inspection (hover tooltips)
- No precise targeting (crosshair system)
- No data exploration (zoom/pan)
- No touch gesture support
- No keyboard navigation
- No accessibility features for interactions

**Example of missing functionality:**
```dart
// Current: Static chart with no interaction
BravenChart(
  chartType: ChartType.line,
  series: [salesData],
  config: LineChartConfig(),
)
// User can only VIEW the chart - cannot interact with it
```

**Desired State (Layer 6):**
Rich, professional interactions with minimal configuration:

```dart
// With interactions enabled
BravenChart(
  chartType: ChartType.line,
  series: [salesData],
  config: LineChartConfig(),
  interactions: InteractionConfig(
    enableCrosshair: true,
    enableTooltip: true,
    enableZoom: true,
    enablePan: true,
  ),
  onDataPointHover: (point) => print('Hovering: $point'),
  onDataPointTap: (point) => showDetails(point),
)
```

### Key Features

1. **Crosshair System**: Precision targeting with vertical/horizontal guides
2. **Tooltip System**: Context-aware data display on hover/tap
3. **Zoom/Pan Controls**: Smooth navigation of large datasets
4. **Gesture Recognition**: Natural touch interactions (pinch, swipe, tap)
5. **Keyboard Navigation**: Accessibility-first keyboard controls
6. **Event System**: Unified event handling across input methods
7. **Performance**: <100ms response time, 60 FPS during interactions

### Success Criteria

1. **Response Time**: <100ms for all interaction feedback
2. **Frame Rate**: 60 FPS during pan/zoom operations
3. **Conflict-Free**: No conflicts between mouse/touch/keyboard inputs
4. **Natural UX**: Intuitive, predictable interaction patterns
5. **Accessibility**: WCAG 2.1 AA compliance for keyboard navigation
6. **Cross-Platform**: Consistent behavior on web, mobile, desktop
7. **Customizable**: Developers can configure or disable interactions
8. **Memory Safe**: Zero leaks, proper cleanup on widget disposal

---

## 🎯 Functional Requirements

### FR-001: Event Handling System
**Priority**: Critical  
**User Story**: As a chart library, I need a unified event system that processes mouse, touch, and keyboard events efficiently and routes them to appropriate interaction handlers.

**Requirements:**
- **Event Listener**: Attach listeners to chart widget for pointer events
- **Event Translation**: Convert raw events to chart coordinate space
- **Event Delegation**: Route events to active interaction handlers
- **Event Bubbling**: Support event propagation and cancellation
- **Priority System**: Handle overlapping interactive elements (tooltip > crosshair > zoom)
- **Performance**: <5ms event processing overhead
- **Memory**: Pool event objects to avoid allocations

**Event Types:**
1. **Pointer Events**: Down, Move, Up, Cancel, Hover, Enter, Exit
2. **Gesture Events**: Tap, DoubleTap, LongPress, Pan, Pinch, Scroll
3. **Keyboard Events**: KeyDown, KeyUp, KeyRepeat
4. **Focus Events**: FocusGain, FocusLoss

**Acceptance Criteria:**
```dart
class ChartEventSystem {
  // Register event handlers by priority
  void registerHandler(InteractionHandler handler, int priority);
  
  // Process incoming events
  void handlePointerEvent(PointerEvent event, ChartContext context);
  void handleKeyEvent(KeyEvent event, ChartContext context);
  
  // Event cancellation
  void cancelEvent(String eventId);
  
  // Cleanup
  void dispose();
}

// Usage within BravenChart
final eventSystem = ChartEventSystem();
eventSystem.registerHandler(crosshairHandler, priority: 10);
eventSystem.registerHandler(tooltipHandler, priority: 20);
eventSystem.registerHandler(zoomHandler, priority: 5);
```

**Performance Targets:**
- Event processing: <5ms per event
- Handler dispatch: <1ms
- Zero allocations in steady-state (use object pooling)

---

### FR-002: Crosshair System
**Priority**: Critical  
**User Story**: As a user, I want to see a crosshair that follows my cursor/finger so that I can precisely identify data points and their values.

**Requirements:**
- **Crosshair Modes**: Vertical only, Horizontal only, Both (cross)
- **Snapping**: Snap to nearest data point or free-form
- **Visual Styles**: Line color, width, dash pattern (from theme)
- **Labels**: Show X/Y values at crosshair intersection
- **Multi-Series**: Highlight nearest point on each series
- **Performance**: Render at 60 FPS during mouse movement
- **Throttling**: Throttle updates to 16ms (60 FPS budget)

**Crosshair Configuration:**
```dart
class CrosshairConfig {
  final bool enabled;
  final CrosshairMode mode; // vertical, horizontal, both
  final bool snapToDataPoint;
  final double snapRadius; // pixels
  final CrosshairStyle style;
  final bool showLabels;
  final Duration updateThrottle;
  
  const CrosshairConfig({
    this.enabled = true,
    this.mode = CrosshairMode.both,
    this.snapToDataPoint = true,
    this.snapRadius = 20.0,
    this.style = const CrosshairStyle(),
    this.showLabels = true,
    this.updateThrottle = const Duration(milliseconds: 16),
  });
}

class CrosshairStyle {
  final Color lineColor;
  final double lineWidth;
  final List<double>? dashPattern;
  final Color labelBackgroundColor;
  final TextStyle labelTextStyle;
  
  const CrosshairStyle({
    this.lineColor = Colors.grey,
    this.lineWidth = 1.0,
    this.dashPattern,
    this.labelBackgroundColor = Colors.white,
    this.labelTextStyle = const TextStyle(fontSize: 12),
  });
}

enum CrosshairMode { vertical, horizontal, both, none }
```

**Visual Behavior:**
- Vertical line: Extends from top to bottom of chart area
- Horizontal line: Extends from left to right of chart area
- Labels: Display at axis intersections or floating near crosshair
- Snap behavior: If within `snapRadius`, snap to nearest data point
- Multi-series: Show multiple snap points when hovering between series

**Acceptance Criteria:**
```dart
// Basic crosshair
BravenChart(
  chartType: ChartType.line,
  series: [salesData],
  interactions: InteractionConfig(
    crosshair: CrosshairConfig(
      mode: CrosshairMode.both,
      snapToDataPoint: true,
    ),
  ),
)

// Custom styled crosshair
BravenChart(
  interactions: InteractionConfig(
    crosshair: CrosshairConfig(
      mode: CrosshairMode.vertical,
      style: CrosshairStyle(
        lineColor: Colors.blue,
        lineWidth: 2.0,
        dashPattern: [5, 3],
      ),
    ),
  ),
)
```

**Performance Targets:**
- Crosshair render: <2ms per frame
- Snap calculation: <1ms for 10,000 points (use viewport culling)
- No jank: Maintain 60 FPS during continuous mouse movement

---

### FR-003: Tooltip System
**Priority**: Critical  
**User Story**: As a user, I want to see detailed information about data points when I hover or tap them so that I can understand exact values and context.

**Requirements:**
- **Trigger Modes**: Hover (desktop), Tap (mobile), Proximity (both)
- **Content**: Customizable tooltip content with data point info
- **Positioning**: Smart positioning to avoid clipping (above/below/left/right)
- **Multi-Series**: Show data for multiple series at same X coordinate
- **Styling**: Theme-aware with customization options
- **Animation**: Smooth fade-in/out transitions
- **Delay**: Configurable show/hide delays
- **Performance**: <5ms render time

**Tooltip Configuration:**
```dart
class TooltipConfig {
  final bool enabled;
  final TooltipTrigger trigger;
  final Duration showDelay;
  final Duration hideDelay;
  final TooltipPosition preferredPosition;
  final bool followCursor;
  final double offsetX;
  final double offsetY;
  final TooltipStyle style;
  final TooltipBuilder? customBuilder;
  
  const TooltipConfig({
    this.enabled = true,
    this.trigger = TooltipTrigger.hover,
    this.showDelay = const Duration(milliseconds: 300),
    this.hideDelay = const Duration(milliseconds: 100),
    this.preferredPosition = TooltipPosition.auto,
    this.followCursor = false,
    this.offsetX = 10.0,
    this.offsetY = 10.0,
    this.style = const TooltipStyle(),
    this.customBuilder,
  });
}

enum TooltipTrigger { hover, tap, both }
enum TooltipPosition { auto, top, bottom, left, right }

class TooltipStyle {
  final Color backgroundColor;
  final Color borderColor;
  final double borderWidth;
  final double borderRadius;
  final EdgeInsets padding;
  final TextStyle textStyle;
  final BoxShadow? shadow;
  
  const TooltipStyle({
    this.backgroundColor = Colors.white,
    this.borderColor = Colors.grey,
    this.borderWidth = 1.0,
    this.borderRadius = 4.0,
    this.padding = const EdgeInsets.all(8.0),
    this.textStyle = const TextStyle(fontSize: 12),
    this.shadow,
  });
}

// Custom tooltip builder
typedef TooltipBuilder = Widget Function(
  BuildContext context,
  ChartDataPoint point,
  ChartSeries series,
);
```

**Default Tooltip Content:**
```
Series: Sales
X: January 2025
Y: $45,230
```

**Multi-Series Tooltip:**
```
January 2025
─────────────
Sales:     $45,230
Revenue:   $67,450
Profit:    $22,220
```

**Acceptance Criteria:**
```dart
// Basic tooltip
BravenChart(
  chartType: ChartType.line,
  series: [salesData],
  interactions: InteractionConfig(
    tooltip: TooltipConfig(enabled: true),
  ),
)

// Custom tooltip
BravenChart(
  interactions: InteractionConfig(
    tooltip: TooltipConfig(
      enabled: true,
      trigger: TooltipTrigger.both,
      customBuilder: (context, point, series) {
        return Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.shade900,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('📊 ${series.name}', style: TextStyle(color: Colors.white)),
              Text('Value: ${point.y}', style: TextStyle(color: Colors.white)),
            ],
          ),
        );
      },
    ),
  ),
)
```

**Smart Positioning Logic:**
1. Default: Position tooltip above and to the right of data point
2. If clipped at top: Position below data point
3. If clipped at right: Position to the left of data point
4. If clipped at both: Choose position with most visible area
5. Respect `offsetX` and `offsetY` in all positions

**Performance Targets:**
- Tooltip render: <5ms
- Position calculation: <1ms
- No re-layout of chart during tooltip show/hide

---

### FR-004: Zoom/Pan Controls
**Priority**: Critical  
**User Story**: As a user, I want to zoom and pan the chart to explore large datasets and focus on specific time periods or value ranges.

**Requirements:**
- **Zoom Methods**: Mouse wheel, Pinch gesture, Double-tap, UI controls
- **Pan Methods**: Drag (mouse/touch), Arrow keys, UI scrollbars
- **Zoom Modes**: X-axis only, Y-axis only, Both axes, Uniform
- **Zoom Limits**: Min/max zoom levels to prevent over-zoom
- **Pan Limits**: Constrain panning to data bounds (with optional overflow)
- **Smooth Animations**: Interpolated zoom/pan transitions
- **Reset Control**: Double-click or button to reset view
- **Performance**: 60 FPS during zoom/pan operations

**Zoom/Pan Configuration:**
```dart
class ZoomPanConfig {
  final bool enableZoom;
  final bool enablePan;
  final ZoomMode zoomMode;
  final ZoomMethod allowedZoomMethods;
  final PanMethod allowedPanMethods;
  final double minZoomLevel;
  final double maxZoomLevel;
  final bool constrainPanToBounds;
  final bool allowOverscroll;
  final Duration animationDuration;
  final Curve animationCurve;
  
  const ZoomPanConfig({
    this.enableZoom = true,
    this.enablePan = true,
    this.zoomMode = ZoomMode.both,
    this.allowedZoomMethods = const ZoomMethod.all(),
    this.allowedPanMethods = const PanMethod.all(),
    this.minZoomLevel = 0.5,
    this.maxZoomLevel = 10.0,
    this.constrainPanToBounds = true,
    this.allowOverscroll = false,
    this.animationDuration = const Duration(milliseconds: 200),
    this.animationCurve = Curves.easeOut,
  });
}

enum ZoomMode { xOnly, yOnly, both, uniform }

class ZoomMethod {
  final bool mouseWheel;
  final bool pinchGesture;
  final bool doubleTap;
  final bool uiControls;
  
  const ZoomMethod({
    this.mouseWheel = true,
    this.pinchGesture = true,
    this.doubleTap = true,
    this.uiControls = false,
  });
  
  const ZoomMethod.all() : this();
  const ZoomMethod.touchOnly() : this(mouseWheel: false, uiControls: false);
}

class PanMethod {
  final bool drag;
  final bool arrowKeys;
  final bool scrollbars;
  
  const PanMethod({
    this.drag = true,
    this.arrowKeys = true,
    this.scrollbars = false,
  });
  
  const PanMethod.all() : this(scrollbars: true);
}
```

**Zoom/Pan State Management:**
```dart
class ZoomPanState {
  final double zoomLevelX;
  final double zoomLevelY;
  final Offset panOffset;
  final Rect visibleDataBounds;
  
  const ZoomPanState({
    this.zoomLevelX = 1.0,
    this.zoomLevelY = 1.0,
    this.panOffset = Offset.zero,
    required this.visibleDataBounds,
  });
  
  // Apply zoom at specific point (for mouse wheel, pinch)
  ZoomPanState zoomAt(Offset point, double delta);
  
  // Apply pan
  ZoomPanState pan(Offset delta);
  
  // Reset to default view
  ZoomPanState reset();
}
```

**Acceptance Criteria:**
```dart
// Basic zoom/pan
BravenChart(
  chartType: ChartType.line,
  series: [timeSeriesData],
  interactions: InteractionConfig(
    zoomPan: ZoomPanConfig(
      enableZoom: true,
      enablePan: true,
    ),
  ),
)

// Horizontal zoom only (common for time series)
BravenChart(
  interactions: InteractionConfig(
    zoomPan: ZoomPanConfig(
      zoomMode: ZoomMode.xOnly,
      minZoomLevel: 1.0,
      maxZoomLevel: 50.0,
    ),
  ),
)

// With scrollbars
BravenChart(
  interactions: InteractionConfig(
    zoomPan: ZoomPanConfig(
      allowedPanMethods: PanMethod.all(), // Includes scrollbars
    ),
  ),
)

// Programmatic zoom/pan
final controller = ChartController();
BravenChart(
  controller: controller,
  interactions: InteractionConfig(zoomPan: ZoomPanConfig()),
)
// Later...
controller.zoomTo(minX: jan1, maxX: jan31, animated: true);
controller.panBy(Offset(100, 0), animated: true);
controller.resetView(animated: true);
```

**Zoom Behaviors:**
- **Mouse Wheel**: Zoom in/out at cursor position (zoom center = cursor)
- **Pinch**: Zoom in/out at pinch center point
- **Double-Tap**: Zoom in 2x at tap location (or reset if at max zoom)
- **UI Controls**: Zoom in/out at chart center

**Pan Behaviors:**
- **Drag**: Pan in direction of drag, stop at bounds (if constrained)
- **Arrow Keys**: Pan in 10% increments (or configurable)
- **Scrollbars**: Direct manipulation of visible range

**Performance Targets:**
- Zoom/pan render: <16ms per frame (60 FPS)
- Smooth interpolation: No jank during animated transitions
- Data culling: Only render visible data points (use viewport)

---

### FR-005: Gesture Recognition
**Priority**: High  
**User Story**: As a mobile user, I want natural touch gestures (tap, double-tap, long-press, pinch, swipe) to work intuitively so that I can interact with charts on touchscreens.

**Requirements:**
- **Tap**: Select/activate data point, show tooltip
- **Double-Tap**: Zoom in at tap location
- **Long-Press**: Show persistent tooltip, enable drag mode
- **Pinch**: Zoom in/out with two fingers
- **Pan/Swipe**: Pan chart view
- **Conflict Resolution**: Distinguish between pan and pinch
- **Threshold Detection**: Minimum distance/time to trigger gesture
- **Cancel Handling**: Handle gesture cancellation (e.g., phone call)

**Gesture Configuration:**
```dart
class GestureConfig {
  final bool enableTap;
  final bool enableDoubleTap;
  final bool enableLongPress;
  final bool enablePinch;
  final bool enablePan;
  final Duration doubleTapTimeout;
  final Duration longPressDelay;
  final double tapRadius;
  final double panThreshold;
  final double pinchThreshold;
  
  const GestureConfig({
    this.enableTap = true,
    this.enableDoubleTap = true,
    this.enableLongPress = true,
    this.enablePinch = true,
    this.enablePan = true,
    this.doubleTapTimeout = const Duration(milliseconds: 300),
    this.longPressDelay = const Duration(milliseconds: 500),
    this.tapRadius = 20.0,
    this.panThreshold = 10.0,
    this.pinchThreshold = 5.0,
  });
}
```

**Gesture State Machine:**
```
Idle → PointerDown → [Tap | DoubleTap | LongPress | Pan | Pinch]
  ↓
Tap: Quick down/up within radius
  ↓
DoubleTap: Two taps within timeout
  ↓
LongPress: Down > longPressDelay without movement
  ↓
Pan: Move > panThreshold with 1 pointer
  ↓
Pinch: 2 pointers with distance change > pinchThreshold
```

**Acceptance Criteria:**
```dart
BravenChart(
  chartType: ChartType.scatter,
  series: [pointData],
  interactions: InteractionConfig(
    gestures: GestureConfig(
      enableTap: true,
      enablePinch: true,
      enablePan: true,
    ),
    tooltip: TooltipConfig(trigger: TooltipTrigger.tap),
    zoomPan: ZoomPanConfig(),
  ),
  onDataPointTap: (point) => showDetails(point),
)
```

**Conflict Resolution Rules:**
1. If 2 pointers detected → Pinch takes precedence over Pan
2. If movement < `panThreshold` after `longPressDelay` → LongPress wins
3. If movement > `panThreshold` quickly → Pan wins (cancel LongPress timer)
4. Second tap within `doubleTapTimeout` → DoubleTap (cancel first Tap callback)

**Performance Targets:**
- Gesture recognition: <10ms
- No false positives: >95% accuracy
- Smooth tracking: 60 FPS during pan/pinch

---

### FR-006: Keyboard Navigation
**Priority**: High  
**User Story**: As a keyboard user or user with accessibility needs, I want to navigate charts using keyboard shortcuts so that I can access chart features without a mouse.

**Requirements:**
- **Arrow Keys**: Pan chart view (Left/Right/Up/Down)
- **+/- Keys**: Zoom in/out at chart center
- **Home/End**: Jump to start/end of data
- **Tab**: Cycle through data points
- **Enter/Space**: Activate focused data point (show tooltip)
- **Escape**: Close tooltip, reset selection
- **Focus Indicators**: Visual highlight of focused element
- **Customizable Keys**: Allow key binding customization

**Keyboard Configuration:**
```dart
class KeyboardConfig {
  final bool enabled;
  final Map<LogicalKeyboardKey, KeyAction> keyBindings;
  final double panStepSize; // Percentage of viewport
  final double zoomStepSize; // Multiplier (1.2 = 20% zoom)
  final bool showFocusIndicator;
  final FocusIndicatorStyle focusStyle;
  
  const KeyboardConfig({
    this.enabled = true,
    this.keyBindings = defaultKeyBindings,
    this.panStepSize = 0.1, // 10% of viewport
    this.zoomStepSize = 1.2,
    this.showFocusIndicator = true,
    this.focusStyle = const FocusIndicatorStyle(),
  });
  
  static const defaultKeyBindings = {
    LogicalKeyboardKey.arrowLeft: KeyAction.panLeft,
    LogicalKeyboardKey.arrowRight: KeyAction.panRight,
    LogicalKeyboardKey.arrowUp: KeyAction.panUp,
    LogicalKeyboardKey.arrowDown: KeyAction.panDown,
    LogicalKeyboardKey.equal: KeyAction.zoomIn, // + key
    LogicalKeyboardKey.minus: KeyAction.zoomOut,
    LogicalKeyboardKey.home: KeyAction.jumpToStart,
    LogicalKeyboardKey.end: KeyAction.jumpToEnd,
    LogicalKeyboardKey.tab: KeyAction.focusNext,
    LogicalKeyboardKey.enter: KeyAction.activate,
    LogicalKeyboardKey.space: KeyAction.activate,
    LogicalKeyboardKey.escape: KeyAction.cancel,
  };
}

enum KeyAction {
  panLeft, panRight, panUp, panDown,
  zoomIn, zoomOut,
  jumpToStart, jumpToEnd,
  focusNext, focusPrevious,
  activate, cancel,
}

class FocusIndicatorStyle {
  final Color color;
  final double width;
  final double radius;
  
  const FocusIndicatorStyle({
    this.color = Colors.blue,
    this.width = 2.0,
    this.radius = 4.0,
  });
}
```

**Focus Management:**
- Chart receives focus when clicked or tabbed to
- Arrow keys move focus between data points (in X order)
- Tab cycles through interactive elements (data points, controls)
- Visual indicator (ring) around focused data point
- Screen reader announces focused point: "Data point: Series Sales, X: January, Y: $45,230"

**Acceptance Criteria:**
```dart
// Enable keyboard navigation
BravenChart(
  chartType: ChartType.line,
  series: [salesData],
  interactions: InteractionConfig(
    keyboard: KeyboardConfig(enabled: true),
  ),
)

// Custom key bindings
BravenChart(
  interactions: InteractionConfig(
    keyboard: KeyboardConfig(
      keyBindings: {
        LogicalKeyboardKey.keyW: KeyAction.panUp,
        LogicalKeyboardKey.keyS: KeyAction.panDown,
        LogicalKeyboardKey.keyA: KeyAction.panLeft,
        LogicalKeyboardKey.keyD: KeyAction.panRight,
      },
    ),
  ),
)
```

**Accessibility Requirements:**
- WCAG 2.1 AA compliance
- All interactive features accessible via keyboard
- Focus indicators meet 3:1 contrast ratio
- Screen reader support (semantic labels)

**Performance Targets:**
- Key press response: <50ms
- Smooth animated pan/zoom on key hold

---

### FR-007: Interaction Callbacks
**Priority**: Critical  
**User Story**: As a developer, I want callback functions for user interactions so that I can respond to user actions with custom logic.

**Requirements:**
- **Point Events**: onDataPointTap, onDataPointHover, onDataPointLongPress
- **Selection Events**: onSelectionChange (multi-point selection)
- **Zoom/Pan Events**: onZoomChange, onPanChange, onViewportChange
- **Gesture Events**: onGestureStart, onGestureUpdate, onGestureEnd
- **Focus Events**: onDataPointFocus, onChartFocus, onChartBlur
- **Async Support**: Callbacks can be async functions
- **Event Details**: Rich event objects with context data

**Callback Signatures:**
```dart
// Point interaction callbacks
typedef DataPointCallback = void Function(ChartDataPoint point, ChartSeries series);
typedef DataPointAsyncCallback = Future<void> Function(ChartDataPoint point, ChartSeries series);

// Selection callbacks
typedef SelectionCallback = void Function(List<ChartDataPoint> selectedPoints);

// Viewport callbacks
typedef ViewportCallback = void Function(ZoomPanState state);

// Gesture callbacks
typedef GestureCallback = void Function(GestureDetails details);

// Focus callbacks
typedef FocusCallback = void Function(ChartDataPoint? focusedPoint);

// Event detail objects
class GestureDetails {
  final GestureType type;
  final Offset position;
  final double? scale; // For pinch
  final Offset? delta; // For pan
  final DateTime timestamp;
}

enum GestureType { tap, doubleTap, longPress, panStart, panUpdate, panEnd, pinchStart, pinchUpdate, pinchEnd }
```

**Callback Integration:**
```dart
BravenChart(
  chartType: ChartType.scatter,
  series: [pointData],
  
  // Point interaction callbacks
  onDataPointTap: (point, series) {
    print('Tapped: ${series.name} - ${point.y}');
    showDialog(context: context, builder: (ctx) => DataPointDialog(point));
  },
  
  onDataPointHover: (point, series) {
    setState(() => hoveredPoint = point);
  },
  
  onDataPointLongPress: (point, series) async {
    final result = await showMenu(context: context, items: [...]);
    if (result == 'delete') deletePoint(point);
  },
  
  // Selection callbacks
  onSelectionChange: (selectedPoints) {
    print('Selected ${selectedPoints.length} points');
    updateStatistics(selectedPoints);
  },
  
  // Viewport callbacks
  onZoomChange: (state) {
    print('Zoom: ${state.zoomLevelX}x');
    if (state.zoomLevelX > 5.0) loadHighResData();
  },
  
  onViewportChange: (state) {
    print('Visible: ${state.visibleDataBounds}');
    loadDataForVisibleRange(state.visibleDataBounds);
  },
  
  // Gesture callbacks
  onGestureStart: (details) {
    print('Gesture started: ${details.type}');
  },
  
  onGestureEnd: (details) {
    print('Gesture ended: ${details.type}');
    saveViewportState();
  },
  
  // Focus callbacks
  onDataPointFocus: (point) {
    announceToScreenReader('Focused: ${point?.y ?? "none"}');
  },
)
```

**Acceptance Criteria:**
- All callbacks are optional (nullable)
- Callbacks receive rich event context
- Async callbacks are awaited before next interaction
- No performance impact when callbacks not registered
- Callbacks fire in logical order (hover before tap, etc.)

**Performance Targets:**
- Callback invocation overhead: <1ms
- Support up to 100ms execution time in callbacks without blocking UI

---

## 🏗️ Technical Architecture

### System Components

```
┌─────────────────────────────────────────────────────────┐
│                    BravenChart Widget                    │
│  (receives InteractionConfig, forwards to system)        │
└────────────────────────┬────────────────────────────────┘
                         │
         ┌───────────────┴───────────────┐
         │                               │
┌────────▼─────────┐          ┌─────────▼──────────┐
│  Event System    │          │ Interaction Layer  │
│  - Listeners     │◄─────────┤  - Crosshair       │
│  - Translation   │          │  - Tooltip         │
│  - Delegation    │          │  - Zoom/Pan        │
│  - Priority      │          │  - Selection       │
└────────┬─────────┘          └─────────┬──────────┘
         │                               │
         │   ┌───────────────────────────┘
         │   │
┌────────▼───▼─────────┐
│  Gesture Recognizer  │
│  - Tap               │
│  - DoubleTap         │
│  - LongPress         │
│  - Pan               │
│  - Pinch             │
└──────────────────────┘
```

### Data Flow

**Interaction Lifecycle:**
```
1. User Input (Mouse/Touch/Keyboard)
   ↓
2. Flutter Event System (PointerEvent/KeyEvent)
   ↓
3. ChartEventSystem (capture & translate)
   ↓
4. Event Translation (screen → data coordinates)
   ↓
5. Handler Dispatch (by priority)
   ↓
6. Interaction Handlers (Crosshair/Tooltip/Zoom)
   ↓
7. State Update (hover state, viewport, etc.)
   ↓
8. Render Trigger (setState or controller notify)
   ↓
9. Visual Feedback (crosshair, tooltip, zoom)
   ↓
10. Callback Invocation (developer callbacks)
```

### State Management

**Interaction State:**
```dart
class InteractionState {
  // Hover/Focus state
  final ChartDataPoint? hoveredPoint;
  final ChartSeries? hoveredSeries;
  final ChartDataPoint? focusedPoint;
  
  // Selection state
  final Set<ChartDataPoint> selectedPoints;
  
  // Crosshair state
  final Offset? crosshairPosition;
  final List<ChartDataPoint> crosshairSnapPoints;
  
  // Tooltip state
  final bool tooltipVisible;
  final Offset? tooltipPosition;
  final ChartDataPoint? tooltipDataPoint;
  
  // Zoom/Pan state
  final ZoomPanState zoomPan;
  
  // Gesture state
  final GestureType? activeGesture;
  final Offset? gestureStartPosition;
}
```

**State Persistence:**
```dart
class InteractionController extends ChangeNotifier {
  InteractionState _state = InteractionState.initial();
  
  // Update methods
  void updateHover(ChartDataPoint? point, ChartSeries? series) {
    _state = _state.copyWith(hoveredPoint: point, hoveredSeries: series);
    notifyListeners();
  }
  
  void updateZoomPan(ZoomPanState zoomPan) {
    _state = _state.copyWith(zoomPan: zoomPan);
    notifyListeners();
  }
  
  // Reset
  void reset() {
    _state = InteractionState.initial();
    notifyListeners();
  }
  
  // Dispose
  @override
  void dispose() {
    // Cleanup listeners
    super.dispose();
  }
}
```

---

## ⚡ Performance Requirements

### Response Time Targets

| Interaction | Target | Maximum | Notes |
|-------------|--------|---------|-------|
| Event processing | <5ms | <10ms | Per event |
| Crosshair update | <2ms | <5ms | 60 FPS = 16ms budget |
| Tooltip render | <5ms | <10ms | Including layout |
| Zoom/pan frame | <16ms | <20ms | 60 FPS target |
| Gesture recognition | <10ms | <20ms | Includes state machine |
| Keyboard action | <50ms | <100ms | User perception threshold |
| Callback dispatch | <1ms | <5ms | Overhead only |

### Memory Constraints

- **Event Object Pooling**: Reuse event objects, zero allocations in steady-state
- **Crosshair Cache**: Pool Paint/Path objects for crosshair rendering
- **Tooltip Cache**: Cache tooltip layout to avoid re-computation
- **Gesture State**: Fixed-size state machine, no dynamic allocations
- **Total Overhead**: <5MB for complete interaction system

### Rendering Performance

- **Crosshair**: Render at 60 FPS during mouse movement (16ms budget)
- **Tooltip**: Smooth fade-in/out animations (no jank)
- **Zoom/Pan**: Maintain 60 FPS during continuous zoom/pan
- **Multi-Layer**: Interactions should not trigger full chart re-render (use overlay layers)

---

## 🧪 Testing Requirements

### Unit Tests

1. **Event System Tests** (20 tests)
   - Event listener registration/deregistration
   - Event translation (screen → data coordinates)
   - Event delegation by priority
   - Event cancellation
   - Memory leak detection (listener cleanup)

2. **Crosshair Tests** (15 tests)
   - Crosshair rendering (vertical/horizontal/both)
   - Snap to data point logic
   - Multi-series snap behavior
   - Crosshair style application
   - Performance (render time)

3. **Tooltip Tests** (18 tests)
   - Tooltip trigger (hover/tap)
   - Smart positioning logic
   - Multi-series tooltip content
   - Custom tooltip builder
   - Show/hide delay timing
   - Performance (render time)

4. **Zoom/Pan Tests** (25 tests)
   - Mouse wheel zoom
   - Pinch gesture zoom
   - Drag pan
   - Keyboard pan
   - Zoom limits (min/max)
   - Pan constraints
   - Animated transitions
   - State persistence

5. **Gesture Tests** (20 tests)
   - Tap recognition
   - Double-tap recognition
   - Long-press recognition
   - Pan gesture
   - Pinch gesture
   - Conflict resolution (pan vs pinch)
   - Gesture cancellation

6. **Keyboard Tests** (12 tests)
   - Arrow key navigation
   - Zoom keys (+/-)
   - Focus management
   - Custom key bindings
   - Focus indicator rendering
   - Accessibility announcements

### Integration Tests

1. **Cross-Feature Tests** (15 tests)
   - Crosshair + Tooltip interaction
   - Zoom + Crosshair coordinate accuracy
   - Keyboard + Tooltip activation
   - Multi-touch gestures
   - Event priority conflicts

2. **Performance Tests** (10 tests)
   - 60 FPS during pan/zoom
   - <100ms interaction response
   - No memory leaks over 1000 interactions
   - Smooth animations (no dropped frames)

### Widget Tests

1. **Interaction Widget Tests** (12 tests)
   - BravenChart with interactions enabled
   - Interaction config propagation
   - Callback invocation
   - Hot reload support
   - Dispose cleanup

### Manual Testing

1. **Cross-Platform Testing**
   - Test on web (Chrome, Firefox, Safari)
   - Test on mobile (iOS, Android)
   - Test on desktop (Windows, macOS, Linux)

2. **Accessibility Testing**
   - Keyboard-only navigation
   - Screen reader compatibility
   - Focus indicator visibility

---

## 📚 Documentation Requirements

### API Documentation

1. **DartDoc Comments**: All public classes, methods, parameters
2. **Usage Examples**: Code snippets for each interaction feature
3. **Configuration Guide**: Complete InteractionConfig reference
4. **Callback Reference**: All callbacks with signatures and use cases

### User Guides

1. **Interaction Guide** (`docs/guides/interactions.md`)
   - Overview of interaction system
   - Enabling/disabling interactions
   - Customizing crosshair
   - Customizing tooltips
   - Zoom/pan configuration
   - Gesture configuration
   - Keyboard shortcuts
   - Accessibility features

2. **Quickstart Examples** (`quickstart.md`)
   - Basic interactions
   - Custom tooltip
   - Zoom/pan only chart
   - Keyboard-navigable chart
   - Mobile-optimized interactions

### Performance Guide

1. **Optimization Tips**
   - When to disable interactions
   - Throttling hover updates
   - Optimizing custom tooltip builders
   - Memory profiling

---

## 🎯 Success Metrics

### Performance Metrics

- ✅ All interactions respond in <100ms
- ✅ 60 FPS maintained during zoom/pan
- ✅ Zero memory leaks after 10,000 interactions
- ✅ <5MB memory overhead for interaction system

### Quality Metrics

- ✅ 100 unit tests with >95% coverage
- ✅ 25 integration tests passing
- ✅ 12 widget tests passing
- ✅ Zero linter warnings
- ✅ Zero type errors

### User Experience Metrics

- ✅ WCAG 2.1 AA compliance (keyboard nav)
- ✅ Works on web, mobile, desktop
- ✅ Natural, predictable interactions
- ✅ No input conflicts (mouse/touch/keyboard)

### Developer Experience Metrics

- ✅ Simple 5-line interaction setup
- ✅ Comprehensive DartDoc coverage
- ✅ 8+ quickstart examples
- ✅ Detailed usage guide (1000+ lines)

---

## 🚀 Implementation Phases

### Phase 1: Core Event System (Week 1)
- ChartEventSystem implementation
- Event listener registration
- Event translation (coordinate systems)
- Event delegation by priority
- Unit tests (20 tests)

### Phase 2: Crosshair System (Week 1-2)
- CrosshairConfig and CrosshairStyle
- Crosshair rendering layer
- Snap-to-point logic
- Multi-series support
- Unit tests (15 tests)

### Phase 3: Tooltip System (Week 2)
- TooltipConfig and TooltipStyle
- Tooltip positioning logic
- Custom tooltip builder support
- Animation support
- Unit tests (18 tests)

### Phase 4: Zoom/Pan Controls (Week 2-3)
- ZoomPanConfig and ZoomPanState
- Mouse wheel zoom
- Drag pan
- Zoom/pan animations
- Constraint handling
- Unit tests (25 tests)

### Phase 5: Gesture Recognition (Week 3)
- GestureConfig implementation
- Gesture recognizer state machine
- Tap/DoubleTap/LongPress
- Pan/Pinch gestures
- Conflict resolution
- Unit tests (20 tests)

### Phase 6: Keyboard Navigation (Week 3-4)
- KeyboardConfig implementation
- Focus management
- Key bindings
- Accessibility features
- Unit tests (12 tests)

### Phase 7: Integration & Testing (Week 4)
- Integration tests (25 tests)
- Widget tests (12 tests)
- Performance testing
- Cross-platform validation
- Bug fixes

### Phase 8: Documentation (Week 4)
- DartDoc completion
- Interaction guide
- Quickstart examples
- Performance guide

---

## 📝 Open Questions

1. **Scrollbar Implementation**: Use Flutter's Scrollbar widget or custom implementation?
   - **Decision Needed**: Evaluate performance and customization needs

2. **Multi-Chart Interactions**: How to handle interactions across multiple charts on same screen?
   - **Proposal**: Each chart has independent InteractionState
   - **Alternative**: Optional shared InteractionController for synchronized interactions

3. **Mobile Performance**: Should we reduce interaction fidelity on low-end devices?
   - **Proposal**: Auto-detect device performance and adjust throttling
   - **Alternative**: Expose performance mode in InteractionConfig

4. **Touch Precision**: How to handle fat finger problem on small charts?
   - **Proposal**: Larger tap radius (30-40px) on mobile
   - **Alternative**: Zoom into tap location for precision selection

5. **Accessibility Voice Control**: Should we support voice commands (e.g., "zoom in")?
   - **Decision Needed**: Research Flutter voice control capabilities
   - **Recommendation**: Defer to future layer if complex

---

## 🔗 Dependencies

### Required Layers (Must be Complete)

- ✅ Layer 0: Foundation (data models, utilities)
- ✅ Layer 1: Core Rendering (RenderPipeline, layers)
- ✅ Layer 2: Coordinate System (coordinate transformation)
- ✅ Layer 3: Theming (style system)
- ✅ Layer 4: Chart Types (chart layers)
- ✅ Layer 5: Chart Widgets (BravenChart widget)

### Flutter Dependencies

- `dart:ui` - Canvas, Paint, Path for crosshair rendering
- `dart:async` - Stream for event handling
- `package:flutter/gestures.dart` - Gesture recognition
- `package:flutter/services.dart` - Keyboard events
- `package:flutter/widgets.dart` - Focus management

### Internal Dependencies

- `CoordinateTransformer` - Translate screen → data coordinates
- `RenderPipeline` - Add interaction overlay layers
- `ChartTheme` - Style crosshair, tooltip, focus indicator
- `ObjectPool` - Pool event objects, Paint/Path for crosshair

---

## 📌 Notes

- Interaction system should work seamlessly with real-time streaming (Layer 5)
- Design with annotation system (Layer 7) in mind - annotations will need similar event handling
- Consider future export feature (Layer 8) - interactions may need to be disabled during export
- Mobile-first design: Touch gestures are primary, mouse is enhancement
- Accessibility is not optional - keyboard navigation is a requirement, not nice-to-have

---

**Status**: Ready for Review  
**Next Steps**: 
1. Review and approve specification
2. Create implementation plan (plan.md)
3. Break down into tasks (tasks.md)
4. Define contracts (contracts/)
5. Create quickstart examples (quickstart.md)
