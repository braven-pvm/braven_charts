# Research Document: Dual-Purpose Chart Scrollbars
## Feature: Scrollbars with Pan & Zoom Capabilities

**Author**: AI Assistant (GitHub Copilot)  
**Date**: 2025-10-24  
**Status**: Research Phase  
**Target Sprint**: 010-scrollbars  

---

## Executive Summary

This document presents comprehensive research for implementing dual-purpose scrollbars in the Braven Charts library. Unlike traditional scrollbars that only allow panning, these scrollbars will enable **both panning (scrolling) and zooming (resizable handle)** within a single, intuitive UI component. The scrollbar must integrate seamlessly with the existing coordinate system without affecting chart rendering or data transformations.

### Key Innovation

The core innovation is a **resizable scrollbar handle** where:
- **Handle position** = current viewport position (pan)
- **Handle size** = visible data range (zoom)
- **Dragging handle** = pan operation
- **Resizing handle edges** = zoom operation

This provides users with an intuitive, spatial representation of their current view within the full dataset, similar to patterns found in Highcharts Navigator and D3.js brush components.

---

## 1. Problem Statement & Requirements

### 1.1 Current Limitations

The Braven Charts library currently supports:
- ✅ Zoom via mouse wheel, pinch gestures, keyboard
- ✅ Pan via drag gestures, keyboard arrows
- ✅ ViewportState for tracking zoom/pan transformations
- ❌ No visual feedback showing viewport position within full dataset
- ❌ No direct manipulation UI for adjusting visible range
- ❌ No scrollbar component for mouse-heavy workflows

### 1.2 User Requirements

**Primary Use Case**: Large dataset exploration (thousands of data points)

Users need to:
1. **See their position** - Visual indicator of where current viewport is within full dataset
2. **Pan efficiently** - Click or drag to move viewport without interfering with data interactions
3. **Zoom intuitively** - Adjust visible range by resizing the viewport indicator
4. **Avoid coordinate conflicts** - Scrollbars should not affect chart rendering coordinate system

### 1.3 Functional Requirements (Initial)

**FR-001: Scrollbar Visibility**
- Scrollbar MUST appear when viewport is smaller than data range
- X-axis scrollbar: Show when `viewport.xRange < fullDataRange.xRange`
- Y-axis scrollbar: Show when `viewport.yRange < fullDataRange.yRange`
- Scrollbar MUST hide when entire dataset is visible (zoom level 1.0, no pan)

**FR-002: Dual-Purpose Handle**
- Scrollbar handle size MUST represent visible percentage of data
  - Formula: `handleSize = (viewportRange / dataRange) * trackLength`
  - Example: If viewport shows 25% of data, handle is 25% of scrollbar track
- Scrollbar handle position MUST represent viewport offset within data
  - Formula: `handlePosition = (viewportMin - dataMin) / (dataMax - dataMin) * (trackLength - handleSize)`
- Handle MUST be resizable via grab/drag on handle edges
- Handle MUST be draggable by grabbing center (pan without resize)

**FR-003: Pan Operations (Scrolling)**
- Dragging handle center MUST pan viewport (scroll data)
- Clicking scrollbar track MUST jump viewport to that position
- Pan MUST respect data boundaries (no overscroll beyond data range)
- Pan MUST update `ViewportState.panOffset` and `ViewportState.xRange/yRange`

**FR-004: Zoom Operations (Handle Resize)**
- Dragging left edge of handle MUST zoom by adjusting viewport minimum
  - Shrinking handle = zoom in (less data visible)
  - Expanding handle = zoom out (more data visible)
- Dragging right edge of handle MUST zoom by adjusting viewport maximum
- Resizing MUST maintain opposite edge position (anchor point)
- Zoom MUST respect min/max zoom limits (e.g., 0.1x to 100x)
- Zoom MUST update `ViewportState.zoomFactor` and visible range

**FR-005: Coordinate System Independence**
- Scrollbars MUST NOT affect `TransformContext.chartAreaBounds`
- Scrollbars MUST render OUTSIDE the chart plot area
- Chart rendering coordinate transformations MUST remain unchanged
- Scrollbar positioning MUST use widget layout, not chart coordinates

**FR-006: Bidirectional Axis Support**
- System MUST support horizontal scrollbar (X-axis) at bottom
- System MUST support vertical scrollbar (Y-axis) on right side
- Both scrollbars MUST work independently
- Both scrollbars MUST work simultaneously for 2D navigation

**FR-007: Interaction Behavior**
- Scrollbar interactions MUST NOT trigger chart data point interactions
- Scrollbar hover MUST show resize/drag cursors
- Scrollbar MUST support keyboard navigation (Tab to focus, arrows to pan)
- Scrollbar MUST support accessibility (screen readers, semantic labels)

**FR-008: Performance**
- Scrollbar updates MUST maintain 60 FPS during drag operations
- Handle position calculations MUST be O(1) complexity
- Scrollbar rendering MUST NOT trigger chart re-renders (unless viewport changes)
- Coordinate system transformations MUST remain unaffected (<1% performance delta)

---

## 2. Industry Research & Reference Implementations

### 2.1 Highcharts Navigator Pattern

**Source**: [Highcharts Stock Navigator](https://www.highcharts.com/docs/stock/navigator)

**Key Features**:
- Small chart below main chart showing full dataset
- Draggable handles on left/right edges for zoom
- Draggable center area for pan
- Visual feedback via semi-transparent mask

**Advantages**:
- **Context preservation**: Mini-chart shows data shape during navigation
- **Intuitive interaction**: Handles clearly communicate resize capability
- **Spatial awareness**: Always visible reference to full dataset

**Disadvantages**:
- Requires rendering a second chart (complexity + performance)
- Takes significant vertical space
- Not suitable for Y-axis scrolling

**Applicability to Braven Charts**:
- ✅ Adopt handle-based resize pattern
- ✅ Adopt dual-purpose drag behavior (center vs edges)
- ❌ Skip mini-chart rendering (use simple range indicator instead)
- ✅ Adapt pattern for both X and Y axes

### 2.2 D3.js Brush Component

**Source**: [D3 Brush](https://observablehq.com/@d3/focus-context) (Focus + Context pattern)

**Key Features**:
- `d3.brushX()` for horizontal selection
- `d3.brushY()` for vertical selection
- Resizable selection box with handles
- Event-driven updates: `brush`, `end` events
- Cursor changes for edges vs center

**Advantages**:
- **Lightweight**: No data rendering, pure interaction component
- **Flexible**: Works as overlay on any chart
- **Proven**: Industry-standard interaction pattern

**Disadvantages**:
- Requires D3.js (not applicable to pure Flutter)
- Less discoverable than visible scrollbar

**Applicability to Braven Charts**:
- ✅ Adopt brush-style interaction model
- ✅ Adopt event-driven architecture (`onPan`, `onZoom` callbacks)
- ✅ Adopt cursor change patterns (resize arrows, grab hand)
- ✅ Adapt for Flutter Custom Painter implementation

### 2.3 Flutter Scrollbar Widget

**Source**: Flutter SDK `Scrollbar` widget

**Key Features**:
- Automatically tracks `ScrollController` position
- Shows/hides based on overflow
- Draggable thumb for quick scrolling
- Platform-adaptive styling (iOS vs Android vs desktop)

**Advantages**:
- **Native Flutter integration**: Uses existing layout primitives
- **Accessibility**: Built-in semantic labels and screen reader support
- **Themeable**: Respects `ScrollbarTheme`

**Disadvantages**:
- Single-purpose: Pan only, no zoom/resize
- Tied to `ScrollController`: Not directly applicable to chart viewport
- Limited customization for dual-purpose behavior

**Applicability to Braven Charts**:
- ✅ Adopt Flutter layout patterns (positioned outside chart area)
- ✅ Adopt show/hide logic (only when content overflows)
- ✅ Adopt theming patterns (`ScrollbarTheme` as reference)
- ✅ Adopt accessibility patterns (semantic labels, focus indicators)
- ❌ Must create custom implementation (not widget-based scrolling)

### 2.4 Excel/Google Sheets Scrollbars

**Key Features**:
- Always visible scrollbars (horizontal + vertical)
- Handle size represents visible percentage
- Clicking track jumps to that section
- No zoom functionality (separate controls)

**Advantages**:
- **Familiar**: Users already understand this pattern
- **Discoverable**: Always-visible affordance
- **Predictable**: Standard scrollbar behavior

**Disadvantages**:
- No zoom capability (requires separate zoom UI)
- Always visible (takes up space even when not needed)

**Applicability to Braven Charts**:
- ✅ Adopt familiar scrollbar visual appearance
- ✅ Adopt track-click jump behavior
- ✅ Adopt proportional handle sizing
- ➕ **Enhance** with resize capability for zoom

---

## 3. Technical Design

### 3.1 Architecture Overview

```
┌─────────────────────────────────────────────────┐
│              BravenChart Widget                 │
│                                                 │
│  ┌────────────────────────────────────────┐   │
│  │       Chart Canvas Area                │   │
│  │  (Renders using TransformContext)      │   │
│  │                                        │   │
│  │  ViewportState controls visible range  │   │
│  └────────────────────────────────────────┘   │
│  ┌────────────────────────────────────────┐   │ ← X-Scrollbar
│  │  [──────█████──────────────────────]   │   │   (Horizontal)
│  └────────────────────────────────────────┘   │
└─────────────────────────────────────────────────┘
                                              ▲
                                              │
                                         Y-Scrollbar
                                         (Vertical)

Key Components:
- ChartScrollbar: Custom StatefulWidget for scrollbar rendering
- ScrollbarHandle: Resizable/draggable handle component
- ScrollbarController: Manages handle state, translates gestures to viewport changes
- ViewportState: Existing class, updated by scrollbar interactions
```

### 3.2 Core Components

#### 3.2.1 ChartScrollbar Widget

**Purpose**: Render a scrollbar with dual-purpose handle (pan + zoom)

**Responsibilities**:
- Render scrollbar track (background)
- Render scrollbar handle (foreground)
- Detect gestures (drag, resize, click)
- Translate gestures to viewport changes
- Update `ViewportState` via callback

**Key Properties**:
```dart
class ChartScrollbar extends StatefulWidget {
  const ChartScrollbar({
    required this.axis,              // Axis.horizontal or Axis.vertical
    required this.dataRange,         // Full data range (min, max)
    required this.viewportRange,     // Current visible range
    required this.onViewportChanged, // Callback when viewport changes
    this.scrollbarConfig,            // Optional: theme, size, behavior
  });

  final Axis axis;
  final DataRange dataRange;
  final DataRange viewportRange;
  final ValueChanged<DataRange> onViewportChanged;
  final ScrollbarConfig? scrollbarConfig;
}
```

**State Management**:
- `_isDragging`: Is handle currently being dragged (pan)?
- `_isResizing`: Is handle currently being resized (zoom)?
- `_resizeEdge`: Which edge is being resized (left/right, top/bottom)?
- `_dragStartOffset`: Initial cursor position for drag calculations

#### 3.2.2 ScrollbarHandle Component

**Purpose**: Represent visible viewport as a resizable, draggable rectangle

**Visual Design**:
```
Track (Full data range):
[═════════════════════════════════════════]
         ↑                        ↑
    Handle edge              Handle edge
    (resize grip)            (resize grip)
    
Handle (Visible viewport):
[═══╔═════════╗═══════════════════════════]
    ║█████████║ ← Center (drag for pan)
    ╚═════════╝
    ↑         ↑
   Resize    Resize
   left      right
```

**Interaction Zones**:
1. **Left/Top Edge** (8px wide): Resize by adjusting minimum
2. **Right/Bottom Edge** (8px wide): Resize by adjusting maximum
3. **Center Area**: Drag to pan (no resize)
4. **Track (outside handle)**: Click to jump viewport

**Cursor Changes**:
- Left/Right edges: ↔ (horizontal resize)
- Top/Bottom edges: ↕ (vertical resize)
- Center: ✋ (grab/drag)
- Track: 👆 (pointer)

#### 3.2.3 ScrollbarController

**Purpose**: Translate raw gesture events into viewport transformations

**Key Methods**:
```dart
class ScrollbarController {
  /// Convert handle position (pixels) to data range
  DataRange handlePositionToDataRange(
    double handleStart,  // Handle left/top edge position (pixels)
    double handleSize,   // Handle width/height (pixels)
    double trackSize,    // Total track size (pixels)
    DataRange dataRange, // Full data range
  );

  /// Convert data range to handle position (pixels)
  (double start, double size) dataRangeToHandlePosition(
    DataRange viewportRange,
    DataRange dataRange,
    double trackSize,
  );

  /// Handle drag gesture (pan operation)
  DataRange handleDrag(
    double dragDelta,    // Pixels moved
    DataRange currentViewport,
    DataRange dataRange,
    double trackSize,
  );

  /// Handle resize gesture (zoom operation)
  DataRange handleResize(
    ScrollbarEdge edge,  // Which edge is being dragged
    double resizeDelta,  // Pixels moved
    DataRange currentViewport,
    DataRange dataRange,
    double trackSize,
  );
}
```

**Coordinate Calculations**:

```dart
// Handle size represents visible percentage
double getHandleSize(DataRange viewport, DataRange data, double trackSize) {
  final visibleRatio = (viewport.max - viewport.min) / (data.max - data.min);
  return visibleRatio * trackSize;
}

// Handle position represents viewport offset
double getHandlePosition(DataRange viewport, DataRange data, double trackSize, double handleSize) {
  final offsetRatio = (viewport.min - data.min) / (data.max - data.min);
  return offsetRatio * (trackSize - handleSize);
}

// Reverse: Convert handle position to data range
DataRange getDataRangeFromHandle(double handlePos, double handleSize, double trackSize, DataRange data) {
  final offsetRatio = handlePos / (trackSize - handleSize);
  final visibleRatio = handleSize / trackSize;
  
  final dataSpan = data.max - data.min;
  final viewportSpan = dataSpan * visibleRatio;
  final viewportMin = data.min + (dataSpan * offsetRatio);
  final viewportMax = viewportMin + viewportSpan;
  
  return DataRange(min: viewportMin, max: viewportMax);
}
```

### 3.3 Integration with Existing Systems

#### 3.3.1 Coordinate System Independence

**Critical Requirement**: Scrollbars MUST NOT affect chart rendering coordinate system

**Implementation Strategy**:

1. **Separate Layout Regions**:
```dart
// BravenChart widget layout structure
Column(
  children: [
    Expanded(
      child: Row(
        children: [
          Expanded(
            child: ChartCanvas(...), // Uses TransformContext for rendering
          ),
          if (showYScrollbar)
            ChartScrollbar(
              axis: Axis.vertical,
              // ... Y-axis scrollbar
            ),
        ],
      ),
    ),
    if (showXScrollbar)
      ChartScrollbar(
        axis: Axis.horizontal,
        // ... X-axis scrollbar
      ),
  ],
)
```

2. **Independent Coordinate Systems**:
- **Chart Canvas**: Uses `TransformContext` with `chartAreaBounds` calculated from available space
- **Scrollbar**: Uses widget layout coordinates (Flutter RenderBox), no access to `TransformContext`
- **Viewport Updates**: Scrollbar updates `ViewportState`, which is consumed by `TransformContext` factory

3. **Viewport State Flow**:
```
User drags scrollbar handle
    ↓
ScrollbarController calculates new DataRange
    ↓
onViewportChanged callback fires
    ↓
BravenChart updates ViewportState
    ↓
TransformContext rebuilt with new viewport
    ↓
Chart re-renders with updated visible range
    ↓
Scrollbar updates handle position (reactive)
```

**Validation**: Scrollbar must not modify:
- `TransformContext.chartAreaBounds` (always calculated from canvas size)
- `TransformContext.widgetSize` (always from layout)
- `TransformContext.xDataRange/yDataRange` (always full data range)

Only `TransformContext.viewport` changes (this is the intended behavior).

#### 3.3.2 ViewportState Integration

**Existing System** (`viewport_state.dart`):
```dart
class ViewportState {
  final DataRange xRange;      // Visible X range
  final DataRange yRange;      // Visible Y range
  final double zoomFactor;     // Zoom multiplier
  final Point<double> panOffset; // Pan offset in data units
  
  ViewportState withZoom(double factor);
  ViewportState withPan(Point<double> offset);
  ViewportState withRanges(DataRange x, DataRange y); // ← Use this!
}
```

**Scrollbar Integration**:
- Scrollbar interactions update viewport via `withRanges()`
- **Pan**: Calculate new visible range by shifting min/max by delta
- **Zoom**: Calculate new visible range by adjusting min or max (keeping opposite edge fixed)
- `zoomFactor` and `panOffset` are derived from ranges (backward compatibility)

**Example Flow**:
```dart
// User drags X-scrollbar handle 50 pixels right
final dragDelta = 50.0;
final trackSize = 400.0;
final dataSpan = dataRange.max - dataRange.min;

// Calculate data delta
final dataDelta = (dragDelta / trackSize) * dataSpan;

// Create new viewport range
final newViewport = DataRange(
  min: currentViewport.min + dataDelta,
  max: currentViewport.max + dataDelta,
);

// Update ViewportState
final newState = viewportState.withRanges(newViewport, viewportState.yRange);

// Trigger chart update
onViewportChanged(newState);
```

#### 3.3.3 Interaction Config Integration

**Requirement**: Scrollbar behavior must respect existing interaction configuration

**InteractionConfig Properties** (from `interaction_config.dart`):
```dart
class InteractionConfig {
  final bool enableZoom;  // Affects scrollbar resize capability
  final bool enablePan;   // Affects scrollbar drag capability
  final ZoomCallback? onZoomChanged;  // Fire when scrollbar resizes
  final PanCallback? onPanChanged;    // Fire when scrollbar drags
}
```

**Scrollbar Behavior Matrix**:

| InteractionConfig | Scrollbar Behavior |
|-------------------|-------------------|
| `enableZoom: true, enablePan: true` | Full dual-purpose scrollbar (pan + zoom) |
| `enableZoom: false, enablePan: true` | Pan-only scrollbar (no resize handles) |
| `enableZoom: true, enablePan: false` | Zoom-only scrollbar (resize handles, no drag) |
| `enableZoom: false, enablePan: false` | No scrollbar (hidden) |

**Callback Integration**:
```dart
// When scrollbar drag ends (pan)
if (interactionConfig.onPanChanged != null) {
  final panDelta = Offset(newViewport.min - oldViewport.min, 0);
  interactionConfig.onPanChanged!(panDelta);
}

// When scrollbar resize ends (zoom)
if (interactionConfig.onZoomChanged != null) {
  final zoomRatio = (newViewport.max - newViewport.min) / (oldViewport.max - oldViewport.min);
  interactionConfig.onZoomChanged!(zoomRatio, zoomRatio);
}
```

---

## 4. Configuration & Theming

### 4.1 ScrollbarConfig Class

**Purpose**: Configure scrollbar appearance, behavior, and interaction

```dart
@immutable
class ScrollbarConfig {
  const ScrollbarConfig({
    this.thickness = 12.0,
    this.minHandleSize = 20.0,
    this.trackColor = const Color(0xFFF5F5F5),
    this.handleColor = const Color(0xFFBDBDBD),
    this.handleHoverColor = const Color(0xFF9E9E9E),
    this.handleActiveColor = const Color(0xFF757575),
    this.borderRadius = 4.0,
    this.edgeGripWidth = 8.0,
    this.showGripIndicator = true,
    this.autoHide = true,
    this.autoHideDelay = const Duration(seconds: 2),
    this.enableResizeHandles = true,
    this.minZoomRatio = 0.01,  // 1% minimum visible
    this.maxZoomRatio = 1.0,   // 100% maximum visible
  });

  /// Scrollbar thickness (width for vertical, height for horizontal)
  final double thickness;

  /// Minimum handle size in pixels (prevents handle from becoming too small)
  final double minHandleSize;

  /// Track background color (behind handle)
  final Color trackColor;

  /// Handle color (normal state)
  final Color handleColor;

  /// Handle color when hovered
  final Color handleHoverColor;

  /// Handle color when dragging/resizing
  final Color handleActiveColor;

  /// Border radius for track and handle (rounded corners)
  final double borderRadius;

  /// Width of resize grip zone on handle edges
  final double edgeGripWidth;

  /// Show visual indicator on handle edges (dots or lines)
  final bool showGripIndicator;

  /// Auto-hide scrollbar when not in use
  final bool autoHide;

  /// Delay before hiding scrollbar
  final Duration autoHideDelay;

  /// Enable resize handles (if false, pan-only scrollbar)
  final bool enableResizeHandles;

  /// Minimum visible data ratio (prevents zooming in too far)
  final double minZoomRatio;

  /// Maximum visible data ratio (prevents zooming out beyond full data)
  final double maxZoomRatio;
}
```

### 4.2 Theming Integration

**Approach**: Extend existing theming system (004-theming-system)

**Add to `ChartTheme`**:
```dart
class ChartTheme {
  // ... existing fields
  final ScrollbarTheme scrollbarTheme;  // NEW
}

@immutable
class ScrollbarTheme {
  const ScrollbarTheme({
    required this.xAxisScrollbar,  // Horizontal scrollbar config
    required this.yAxisScrollbar,  // Vertical scrollbar config
  });

  final ScrollbarConfig xAxisScrollbar;
  final ScrollbarConfig yAxisScrollbar;

  /// Predefined themes
  static const ScrollbarTheme defaultLight = ScrollbarTheme(
    xAxisScrollbar: ScrollbarConfig(
      trackColor: Color(0xFFF5F5F5),
      handleColor: Color(0xFFBDBDBD),
    ),
    yAxisScrollbar: ScrollbarConfig(
      trackColor: Color(0xFFF5F5F5),
      handleColor: Color(0xFFBDBDBD),
    ),
  );

  static const ScrollbarTheme defaultDark = ScrollbarTheme(
    xAxisScrollbar: ScrollbarConfig(
      trackColor: Color(0xFF212121),
      handleColor: Color(0xFF616161),
    ),
    yAxisScrollbar: ScrollbarConfig(
      trackColor: Color(0xFF212121),
      handleColor: Color(0xFF616161),
    ),
  );
}
```

**Theme Application**:
```dart
// BravenChart widget
final theme = chartTheme ?? ChartTheme.defaultLight;
final scrollbarConfig = axis == Axis.horizontal
    ? theme.scrollbarTheme.xAxisScrollbar
    : theme.scrollbarTheme.yAxisScrollbar;

ChartScrollbar(
  axis: axis,
  config: scrollbarConfig,
  // ...
);
```

### 4.3 Accessibility Considerations

**Requirements**:
- WCAG 2.1 AA compliance (4.5:1 contrast ratio)
- Keyboard navigation support
- Screen reader compatibility

**Implementation**:

1. **Contrast Ratios**:
   - Track vs Handle: Minimum 3:1 contrast
   - Handle vs Background: Minimum 4.5:1 contrast
   - Active state: Minimum 3:1 contrast vs normal state

2. **Keyboard Navigation**:
   - Tab: Focus scrollbar
   - Arrow keys: Pan (small increments, e.g., 5% of visible range)
   - Shift + Arrow keys: Pan faster (e.g., 25% of visible range)
   - Ctrl/Cmd + Arrow keys: Zoom (e.g., ±10% zoom level)
   - Home/End: Jump to start/end of data
   - Page Up/Down: Jump by full viewport width

3. **Semantic Labels**:
   - Scrollbar: "Chart X-axis scrollbar" or "Chart Y-axis scrollbar"
   - Handle: "Visible range: {min} to {max}, {percent}% of total data"
   - Instructions: "Drag to pan, drag edges to zoom, use arrow keys to navigate"

4. **Focus Indicators**:
   - Visible focus ring (2px, high-contrast color)
   - Follows Flutter's default focus behavior
   - Keyboard and pointer focus handled separately

**Example Semantics**:
```dart
Semantics(
  label: 'Chart X-axis scrollbar',
  hint: 'Drag to pan, drag edges to zoom, use arrow keys to navigate',
  value: 'Showing data from ${viewport.min.toStringAsFixed(1)} '
         'to ${viewport.max.toStringAsFixed(1)}, '
         '${(visibleRatio * 100).toStringAsFixed(0)}% of total',
  onIncrease: () => _panRight(),
  onDecrease: () => _panLeft(),
  child: scrollbarWidget,
)
```

---

## 5. Performance Considerations

### 5.1 Rendering Performance

**Target**: 60 FPS (16.67ms per frame) during scrollbar interactions

**Optimization Strategies**:

1. **Independent Rendering**:
   - Scrollbar renders in its own `CustomPainter`
   - Chart canvas only re-renders when viewport changes (not during drag)
   - Use `RepaintBoundary` to isolate scrollbar from chart

2. **Gesture Throttling**:
   - Throttle viewport updates during rapid drag (max 60 updates/sec)
   - Batch multiple small drags into single viewport update
   - Use `onEnd` callback to finalize viewport (not `onUpdate`)

3. **Layout Optimization**:
   - Scrollbar size fixed during chart lifetime (no layout recalculation)
   - Handle position calculated in O(1) time (simple ratio math)
   - No expensive data queries during drag (use cached data ranges)

**Performance Benchmarks** (Targets):
- Handle position calculation: <0.1ms
- Scrollbar render (custom painter): <1ms
- Viewport update + chart re-render: <16ms (full budget)
- Memory overhead: <100KB (for both X and Y scrollbars)

### 5.2 Memory Considerations

**Scrollbar State**:
- Fixed-size state (<1KB per scrollbar)
- No data buffering (uses references to existing data ranges)
- No texture caching (simple vector rendering)

**Chart Re-render Optimization**:
- Viewport culling already implemented (Layer 0 - Foundation)
- Scrollbar updates only trigger culling recalculation (cheap)
- No additional memory overhead from scrollbar feature

### 5.3 Large Dataset Handling

**Challenge**: Scrollbar handle becomes very small with large datasets

**Solutions**:

1. **Minimum Handle Size**:
   - Enforce `minHandleSize` (e.g., 20px)
   - When calculated size < minHandleSize, clamp to minimum
   - Adjust position calculation to compensate for clamped size

2. **Precision Handling**:
   - Use double precision for all position calculations
   - Round to pixels only during rendering (not during calculations)
   - Avoid cumulative rounding errors during drag

3. **Zoom Level Limits**:
   - Enforce `minZoomRatio` (e.g., 1% = show minimum 1% of data)
   - Prevent users from zooming in so far that handle becomes unusable
   - Show warning or change cursor when limit reached

**Example Calculation** (with min size constraint):
```dart
double calculateHandleSize(DataRange viewport, DataRange data, double trackSize, double minSize) {
  final visibleRatio = (viewport.max - viewport.min) / (data.max - data.min);
  final calculatedSize = visibleRatio * trackSize;
  return math.max(calculatedSize, minSize);
}

double calculateHandlePosition(
  DataRange viewport,
  DataRange data,
  double trackSize,
  double handleSize,
) {
  final offsetRatio = (viewport.min - data.min) / (data.max - data.min);
  final maxPosition = trackSize - handleSize;
  return offsetRatio * maxPosition;
}
```

---

## 6. Implementation Patterns & Best Practices

### 6.1 State Management

**Approach**: Lift scrollbar state to parent (`BravenChart` widget)

**Rationale**:
- Viewport is chart-wide state (not scrollbar-specific)
- Multiple widgets need viewport state (chart canvas, X-scrollbar, Y-scrollbar)
- Simplifies synchronization (single source of truth)

**State Flow**:
```dart
class _BravenChartState extends State<BravenChart> {
  ViewportState _viewport = ViewportState.identity();

  void _onXScrollbarChanged(DataRange newXRange) {
    setState(() {
      _viewport = _viewport.withRanges(newXRange, _viewport.yRange);
    });
  }

  void _onYScrollbarChanged(DataRange newYRange) {
    setState(() {
      _viewport = _viewport.withRanges(_viewport.xRange, newYRange);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: ChartCanvas(viewport: _viewport),
              ),
              ChartScrollbar(
                axis: Axis.vertical,
                viewportRange: _viewport.yRange,
                onViewportChanged: _onYScrollbarChanged,
              ),
            ],
          ),
        ),
        ChartScrollbar(
          axis: Axis.horizontal,
          viewportRange: _viewport.xRange,
          onViewportChanged: _onXScrollbarChanged,
        ),
      ],
    );
  }
}
```

### 6.2 Gesture Handling

**Challenge**: Disambiguate between drag (pan) and resize (zoom) gestures

**Solution**: Hit-test-based gesture recognition

```dart
enum ScrollbarInteractionZone {
  track,      // Outside handle (click to jump)
  handleCenter, // Center of handle (drag to pan)
  handleLeft,   // Left edge of handle (resize left)
  handleRight,  // Right edge of handle (resize right)
}

ScrollbarInteractionZone hitTest(Offset localPosition, Rect handleRect, double edgeWidth) {
  if (!handleRect.contains(localPosition)) {
    return ScrollbarInteractionZone.track;
  }
  
  if (localPosition.dx < handleRect.left + edgeWidth) {
    return ScrollbarInteractionZone.handleLeft;
  }
  
  if (localPosition.dx > handleRect.right - edgeWidth) {
    return ScrollbarInteractionZone.handleRight;
  }
  
  return ScrollbarInteractionZone.handleCenter;
}
```

**Gesture State Machine**:
```
IDLE
  ↓ (onTapDown in track)
TRACK_CLICK → Update viewport instantly
  ↓ (onTapUp)
IDLE

IDLE
  ↓ (onPanStart in handleCenter)
DRAGGING_PAN
  ↓ (onPanUpdate)
DRAGGING_PAN → Update viewport continuously
  ↓ (onPanEnd)
IDLE

IDLE
  ↓ (onPanStart in handleEdge)
RESIZING
  ↓ (onPanUpdate)
RESIZING → Update viewport continuously
  ↓ (onPanEnd)
IDLE
```

### 6.3 Error Handling & Edge Cases

**Edge Case 1**: Handle smaller than minimum size
- **Cause**: Zoomed in very far (viewport << data range)
- **Solution**: Clamp handle size to `minHandleSize`, adjust position calculations

**Edge Case 2**: Pan beyond data boundaries
- **Cause**: User drags handle past track edges
- **Solution**: Clamp viewport range to `[dataMin, dataMax]`

**Edge Case 3**: Zoom beyond limits
- **Cause**: User resizes handle to very small or very large
- **Solution**: Clamp visible ratio to `[minZoomRatio, maxZoomRatio]`

**Edge Case 4**: Simultaneous X and Y scrollbar interactions
- **Cause**: User drags both scrollbars at once (rare but possible)
- **Solution**: Independent state machines per scrollbar, no interference

**Edge Case 5**: Scrollbar appears/disappears during interaction
- **Cause**: Viewport changes cause scrollbar to become unnecessary
- **Solution**: Complete current gesture before hiding, smooth fade-out animation

**Error Recovery**:
```dart
DataRange clampViewportToData(DataRange viewport, DataRange data) {
  final min = math.max(viewport.min, data.min);
  final max = math.min(viewport.max, data.max);
  
  // Ensure valid range (min < max)
  if (min >= max) {
    // Fallback: Reset to full data range
    return data;
  }
  
  return DataRange(min: min, max: max);
}
```

---

## 7. Testing Strategy

### 7.1 Unit Tests

**Component**: `ScrollbarController`

1. **Position Calculations**:
   - Test `dataRangeToHandlePosition()` with various zoom levels
   - Test `handlePositionToDataRange()` round-trip accuracy
   - Test clamping to data boundaries
   - Test minimum handle size enforcement

2. **Gesture Translation**:
   - Test `handleDrag()` with various drag deltas
   - Test `handleResize()` on left and right edges
   - Test simultaneous pan and zoom (should be mutually exclusive)
   - Test edge cases (zero drag, very large drag)

3. **Zoom Limit Enforcement**:
   - Test `minZoomRatio` enforcement during resize
   - Test `maxZoomRatio` enforcement during resize
   - Test behavior at zoom limits (cursor change, haptic feedback)

**Example Tests**:
```dart
test('Handle size represents visible percentage', () {
  final viewport = DataRange(min: 25, max: 75);  // 50% visible
  final data = DataRange(min: 0, max: 100);
  final trackSize = 400.0;
  
  final (_, handleSize) = controller.dataRangeToHandlePosition(
    viewport,
    data,
    trackSize,
  );
  
  expect(handleSize, closeTo(200.0, 0.1));  // 50% of 400px
});

test('Pan respects data boundaries', () {
  final viewport = DataRange(min: 80, max: 100);  // Near right edge
  final data = DataRange(min: 0, max: 100);
  final dragDelta = 100.0;  // Try to drag past boundary
  
  final newViewport = controller.handleDrag(
    dragDelta,
    viewport,
    data,
    400.0,
  );
  
  expect(newViewport.max, lessThanOrEqualTo(100.0));  // Clamped
});
```

### 7.2 Widget Tests

**Component**: `ChartScrollbar` widget

1. **Rendering**:
   - Test scrollbar visibility (show/hide based on viewport)
   - Test handle position reflects viewport
   - Test handle size reflects zoom level
   - Test theming (colors, sizes from `ScrollbarConfig`)

2. **Interaction**:
   - Test tap on track jumps viewport
   - Test drag on handle pans viewport
   - Test resize on edges zooms viewport
   - Test keyboard navigation (arrow keys)

3. **State Updates**:
   - Test `onViewportChanged` callback fires
   - Test viewport updates trigger handle position update
   - Test multiple rapid updates (throttling)

**Example Tests**:
```dart
testWidgets('Scrollbar hides when entire data is visible', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: ChartScrollbar(
        axis: Axis.horizontal,
        dataRange: DataRange(min: 0, max: 100),
        viewportRange: DataRange(min: 0, max: 100),  // Full data visible
        onViewportChanged: (_) {},
      ),
    ),
  );
  
  expect(find.byType(ChartScrollbar), findsNothing);  // Hidden
});

testWidgets('Dragging handle updates viewport', (tester) async {
  var capturedViewport = DataRange(min: 0, max: 50);
  
  await tester.pumpWidget(
    MaterialApp(
      home: ChartScrollbar(
        axis: Axis.horizontal,
        dataRange: DataRange(min: 0, max: 100),
        viewportRange: capturedViewport,
        onViewportChanged: (newRange) {
          capturedViewport = newRange;
        },
      ),
    ),
  );
  
  // Find handle and drag right
  final handle = find.byKey(Key('scrollbar_handle'));
  await tester.drag(handle, Offset(50, 0));
  await tester.pumpAndSettle();
  
  expect(capturedViewport.min, greaterThan(0));  // Moved right
});
```

### 7.3 Integration Tests

**Scenario**: Full chart with scrollbars + zoom/pan interactions

1. **Scrollbar + Mouse Wheel**:
   - Use scrollbar to navigate to position
   - Use mouse wheel to zoom
   - Verify scrollbar handle updates correctly
   - Verify chart re-renders correctly

2. **Scrollbar + Drag Gestures**:
   - Use scrollbar to pan
   - Use chart drag to pan
   - Verify both methods produce same result
   - Verify no double-pan (interference)

3. **Scrollbar + Auto-Scroll** (Streaming Mode):
   - Start chart in streaming mode (auto-scroll enabled)
   - Data accumulates, scrollbar appears
   - User interacts with scrollbar (pauses streaming)
   - Verify streaming resumes after timeout
   - Verify scrollbar correctly represents buffered data

### 7.4 Performance Tests

**Benchmark**: Scrollbar interaction overhead

1. **Render Performance**:
   - Measure scrollbar render time (target: <1ms)
   - Measure chart re-render time with scrollbar (target: <16ms)
   - Measure layout time with scrollbar (target: <5ms)

2. **Gesture Performance**:
   - Simulate 1000 rapid drag updates
   - Measure average update time (target: <1ms)
   - Measure frame drop rate (target: 0 drops at 60 FPS)

3. **Memory Performance**:
   - Measure scrollbar state size (target: <1KB)
   - Measure memory delta with scrollbar vs without (target: <100KB)
   - Measure GC pressure during drag (target: no allocations)

---

## 8. Future Enhancements (Post-MVP)

### 8.1 Mini-Chart Navigator (Highcharts-style)

**Enhancement**: Render a simplified chart within scrollbar track

**Benefits**:
- Visual context of data shape during navigation
- Easier to identify regions of interest
- More intuitive for users familiar with Highcharts

**Challenges**:
- Requires rendering second chart instance (complexity)
- Performance impact (extra render pass)
- Increased memory usage (cached mini-chart)

**Implementation Complexity**: High (2-3 weeks)

### 8.2 Scrollbar Annotations

**Enhancement**: Show markers on scrollbar for important data points

**Use Cases**:
- Mark anomalies (e.g., sensor errors, data gaps)
- Mark events (e.g., deployments, incidents)
- Show selection ranges (e.g., highlighted time periods)

**Implementation**:
```dart
class ScrollbarConfig {
  final List<ScrollbarAnnotation> annotations;
}

class ScrollbarAnnotation {
  final double dataPosition;  // Where in data range
  final Color color;          // Marker color
  final String? tooltip;      // Hover text
}
```

**Implementation Complexity**: Medium (1 week)

### 8.3 Dual-Thumb Range Selection

**Enhancement**: Support two-thumb range selection (like slider)

**Use Cases**:
- Select date range for analysis
- Filter data by value range
- Export specific data subset

**Visual Design**:
```
[═══╔═════════╗═════════╔═════════╗═══]
    ║ Thumb 1 ║         ║ Thumb 2 ║
    ╚═════════╝         ╚═════════╝
    ↑                   ↑
   Start               End
   selection           selection
```

**Implementation Complexity**: Medium (1 week)

### 8.4 Touch Optimization

**Enhancement**: Improve scrollbar for touch devices

**Changes**:
- Larger hit targets (minimum 44x44 pixels per iOS guidelines)
- Haptic feedback on resize/pan
- Auto-expand on touch (temporarily increase thickness)
- Momentum scrolling (fling gesture)

**Implementation Complexity**: Low (3 days)

---

## 9. Open Questions & Decisions

### 9.1 Scrollbar Placement

**Question**: Should scrollbars be inside or outside chart padding?

**Options**:
1. **Inside Padding**: Scrollbar overlaps chart canvas (like overlays)
   - ✅ Pro: Doesn't reduce chart size
   - ❌ Con: Covers chart data near edges
   - ❌ Con: Conflicts with chart interactions

2. **Outside Padding**: Scrollbar in dedicated layout region (recommended)
   - ✅ Pro: Never covers chart data
   - ✅ Pro: Clear separation of concerns
   - ❌ Con: Reduces available chart space

**Decision**: Option 2 (outside padding) - Align with standard scrollbar patterns

### 9.2 Auto-Hide Behavior

**Question**: Should scrollbars auto-hide when not in use?

**Options**:
1. **Always Visible**: Scrollbars always rendered (like Excel)
   - ✅ Pro: Constant affordance, easier to discover
   - ❌ Con: Takes up space even when not needed
   - ❌ Con: Visual clutter

2. **Auto-Hide**: Fade out after inactivity, fade in on hover (like macOS)
   - ✅ Pro: Cleaner appearance, more space for data
   - ✅ Pro: Modern UX pattern
   - ❌ Con: Less discoverable for new users
   - ❌ Con: Requires animation system

**Decision**: Option 2 (auto-hide) with configurable default - Supports `ScrollbarConfig.autoHide` flag

### 9.3 Minimum Handle Size

**Question**: What should minimum handle size be?

**Considerations**:
- **Usability**: Must be grabbable (minimum ~20px for mouse, ~44px for touch)
- **Precision**: Smaller handle = more precise navigation
- **Aesthetics**: Very small handle looks odd

**Options**:
1. **20px** (desktop-optimized) - Recommended for mouse workflows
2. **44px** (touch-optimized) - Recommended for mobile/tablet
3. **Adaptive** - Change based on input device

**Decision**: 20px default with `ScrollbarConfig.minHandleSize` override - Document touch recommendations

### 9.4 Coordinate System Edge Cases

**Question**: How to handle scrollbar when chart has inverted axes?

**Context**: Some charts invert Y-axis (e.g., depth charts, ranking charts)

**Options**:
1. **Scrollbar Always Normal**: Top = min, bottom = max (regardless of axis)
   - ✅ Pro: Consistent scrollbar behavior
   - ❌ Con: Confusing when axis is inverted

2. **Scrollbar Follows Axis**: Invert scrollbar direction if axis inverted
   - ✅ Pro: Intuitive (scrollbar matches chart)
   - ❌ Con: Unexpected scrollbar behavior for users

**Decision**: Option 2 (follow axis) - Scrollbar should reflect visual layout

---

## 10. Success Criteria

### 10.1 Functional Success

- ✅ Scrollbars appear when viewport < data range
- ✅ Handle size accurately represents visible percentage
- ✅ Handle position accurately represents viewport offset
- ✅ Dragging handle updates viewport (pan)
- ✅ Resizing handle updates viewport (zoom)
- ✅ Scrollbar works on both X and Y axes independently
- ✅ Scrollbar respects `InteractionConfig` (zoom/pan enable flags)
- ✅ Scrollbar does NOT affect chart coordinate system

### 10.2 Performance Success

- ✅ Scrollbar interactions maintain 60 FPS
- ✅ Scrollbar rendering adds <1ms per frame
- ✅ Chart re-renders with scrollbar complete in <16ms
- ✅ No frame drops during rapid scrollbar interactions
- ✅ Memory overhead <100KB total (both scrollbars)

### 10.3 Usability Success

- ✅ Users can navigate large datasets efficiently
- ✅ Users understand handle size = visible range
- ✅ Users discover resize capability within 30 seconds
- ✅ Keyboard navigation works intuitively
- ✅ Scrollbar does NOT interfere with chart interactions

### 10.4 Accessibility Success

- ✅ Scrollbar meets WCAG 2.1 AA contrast requirements
- ✅ Keyboard navigation supports all scrollbar operations
- ✅ Screen readers announce scrollbar state correctly
- ✅ Focus indicators clearly visible
- ✅ Touch targets meet iOS/Android minimum sizes (with touch config)

---

## 11. References & Resources

### 11.1 Industry References

1. **Highcharts Navigator**
   - [Documentation](https://www.highcharts.com/docs/stock/navigator)
   - Key learnings: Handle-based resize, mini-chart context

2. **D3.js Brush**
   - [Observable Example](https://observablehq.com/@d3/focus-context)
   - Key learnings: Event-driven updates, cursor changes

3. **Flutter Scrollbar**
   - [API Reference](https://api.flutter.dev/flutter/material/Scrollbar-class.html)
   - Key learnings: Auto-hide, theming, accessibility

4. **Material Design Scrollbars**
   - [Guidelines](https://material.io/components/scrollbars)
   - Key learnings: Visual design, interaction patterns

### 11.2 Internal References

1. **Coordinate System** (003-coordinate-system)
   - `ViewportState`: Tracks zoom/pan state
   - `TransformContext`: Converts between coordinate systems
   - `UniversalCoordinateTransformer`: Performs transformations

2. **Theming System** (004-theming-system)
   - `ChartTheme`: Root theme class
   - Theme builder pattern for customization
   - Accessibility utilities (contrast checking)

3. **Interaction System** (007-interaction-system)
   - `InteractionConfig`: Zoom/pan enable flags
   - Gesture callbacks: `onZoomChanged`, `onPanChanged`
   - Keyboard navigation patterns

4. **Streaming Mode** (009-dual-mode-streaming)
   - `AutoScrollConfig`: Auto-scroll behavior
   - `StreamingConfig`: Buffer management
   - Relevant for scrollbar + streaming integration

### 11.3 Technical Specifications

- **Flutter Custom Painter**: [Documentation](https://api.flutter.dev/flutter/rendering/CustomPainter-class.html)
- **Flutter GestureDetector**: [Documentation](https://api.flutter.dev/flutter/widgets/GestureDetector-class.html)
- **WCAG 2.1 Contrast**: [Guidelines](https://www.w3.org/WAI/WCAG21/Understanding/contrast-minimum.html)

---

## 12. Next Steps

### 12.1 Immediate Actions (This Sprint)

1. ✅ Complete this research document
2. ⬜ Review and validate with team/stakeholders
3. ⬜ Create detailed feature specification (spec.md)
4. ⬜ Define data model (contracts)
5. ⬜ Create implementation plan with task breakdown

### 12.2 Implementation Phases (Next Sprint)

**Phase 1: Core Scrollbar** (Week 1)
- Implement `ChartScrollbar` widget
- Implement `ScrollbarController` (position calculations)
- Basic pan-only scrollbar (no resize yet)
- Unit tests for calculations

**Phase 2: Dual-Purpose Handle** (Week 2)
- Add resize handles (edge grips)
- Implement zoom via handle resize
- Gesture disambiguation (drag vs resize)
- Widget tests for interactions

**Phase 3: Integration & Theming** (Week 3)
- Integrate with `BravenChart` widget
- Add `ScrollbarTheme` to theming system
- Implement auto-hide behavior
- Accessibility features (keyboard, semantics)

**Phase 4: Testing & Polish** (Week 4)
- Integration tests (scrollbar + chart interactions)
- Performance benchmarks
- Documentation (usage guide, examples)
- Example app screens

### 12.3 Documentation Needs

- **User Guide**: How to use scrollbars (examples, configuration)
- **API Reference**: All classes and methods documented
- **Migration Guide**: For users upgrading from no-scrollbar version
- **Best Practices**: When to use scrollbars, performance tips

---

## Appendix A: Glossary

| Term | Definition |
|------|------------|
| **Scrollbar** | UI component for navigating large datasets via pan and zoom |
| **Handle** | Draggable/resizable element within scrollbar representing visible viewport |
| **Track** | Background area of scrollbar representing full data range |
| **Pan** | Moving viewport left/right or up/down without changing zoom level |
| **Zoom** | Changing visible data range (handle size) |
| **Viewport** | Currently visible subset of full data range |
| **Data Range** | Full extent of data (min to max) |
| **Handle Size** | Visual representation of `viewportRange / dataRange` ratio |
| **Handle Position** | Visual representation of viewport offset within data range |
| **Resize Handle** | Draggable edge of handle for zoom operations |
| **Dual-Purpose** | Single component supporting both pan (drag) and zoom (resize) |

---

## Appendix B: Example Usage

### B.1 Basic Scrollbar

```dart
BravenChart(
  chartType: ChartType.line,
  series: [
    ChartSeries(
      id: 'sensor',
      points: generateLargeDataset(10000), // 10K points
    ),
  ],
  // Scrollbar automatically appears (default behavior)
)
```

### B.2 Custom Scrollbar Configuration

```dart
BravenChart(
  chartType: ChartType.line,
  series: [sensorData],
  scrollbarConfig: ScrollbarConfig(
    thickness: 16.0,              // Thicker scrollbar
    minHandleSize: 30.0,          // Larger minimum handle
    handleColor: Colors.blue,     // Custom color
    autoHide: false,              // Always visible
    enableResizeHandles: true,    // Allow zoom via resize
  ),
)
```

### B.3 Pan-Only Scrollbar (No Zoom)

```dart
BravenChart(
  chartType: ChartType.line,
  series: [sensorData],
  scrollbarConfig: ScrollbarConfig(
    enableResizeHandles: false,   // Disable zoom
  ),
  interactionConfig: InteractionConfig(
    enablePan: true,
    enableZoom: false,              // No zoom via other methods either
  ),
)
```

### B.4 Themed Scrollbar

```dart
BravenChart(
  chartType: ChartType.line,
  series: [sensorData],
  chartTheme: ChartTheme.defaultDark.copyWith(
    scrollbarTheme: ScrollbarTheme(
      xAxisScrollbar: ScrollbarConfig(
        trackColor: Color(0xFF212121),
        handleColor: Color(0xFF616161),
        handleHoverColor: Color(0xFF9E9E9E),
      ),
      yAxisScrollbar: ScrollbarConfig(
        trackColor: Color(0xFF212121),
        handleColor: Color(0xFF616161),
      ),
    ),
  ),
)
```

---

**Document Status**: ✅ COMPLETE - Ready for Spec Generation  
**Last Updated**: 2025-10-24  
**Review Required**: Yes (Technical Lead, UX Designer)  
**Next Action**: Create feature specification (`spec.md`)
