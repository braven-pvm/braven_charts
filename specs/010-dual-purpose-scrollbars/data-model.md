# Data Model: Dual-Purpose Scrollbars

**Feature**: 010-dual-purpose-scrollbars  
**Version**: 1.0.0  
**Status**: Phase 1 Design  
**Last Updated**: 2025-01-20

## Entity Overview

```
┌─────────────────────────────────────────────────────────────┐
│                       BravenChart                           │
│  (contains ViewportState, manages chart lifecycle)         │
└─────────────────────────────────────────────────────────────┘
                              │
                              │ provides
                              ↓
┌─────────────────────────────────────────────────────────────┐
│                     ChartScrollbar                          │
│  (widget that renders scrollbar and handles user input)    │
│  • axis: Axis                                               │
│  • dataRange: DataRange                                     │
│  • viewportRange: DataRange                                 │
│  • theme: ScrollbarConfig                                   │
│  • onViewportChanged: Function(DataRange)                   │
└─────────────────────────────────────────────────────────────┘
                              │
                              │ manages
                              ↓
┌──────────────────────────────┐  ┌────────────────────────────┐
│   ScrollbarState             │  │   ScrollbarController      │
│   (immutable state)          │  │   (pure transformations)   │
│   • handlePosition: double   │  │   • handleToDataRange()    │
│   • handleSize: double       │  │   • dataRangeToHandle()    │
│   • isDragging: bool         │  │   • calculateHandleSize()  │
│   • hoverZone: HitTestZone?  │  │   • calculateHandlePos()   │
│   • isFocused: bool          │  │   • getHitTestZone()       │
└──────────────────────────────┘  └────────────────────────────┘
                              │
                              │ styled by
                              ↓
┌─────────────────────────────────────────────────────────────┐
│                     ScrollbarConfig                         │
│  (immutable configuration data class)                       │
│  • thickness, minHandleSize, colors, borderRadius, etc.     │
└─────────────────────────────────────────────────────────────┘
                              │
                              │ contained in
                              ↓
┌─────────────────────────────────────────────────────────────┐
│                     ScrollbarTheme                          │
│  (7th component of ChartTheme)                              │
│  • xAxisScrollbar: ScrollbarConfig                          │
│  • yAxisScrollbar: ScrollbarConfig                          │
└─────────────────────────────────────────────────────────────┘
                              │
                              │ part of
                              ↓
┌─────────────────────────────────────────────────────────────┐
│                       ChartTheme                            │
│  (root theme container)                                     │
│  • gridStyle, axisStyle, seriesTheme, ...                   │
│  • scrollbarTheme: ScrollbarTheme                           │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│                     ViewportState                           │
│  (existing entity, MODIFIED)                                │
│  • xRange: DataRange                                        │
│  • yRange: DataRange                                        │
│  • withRanges(DataRange x, DataRange y): ViewportState     │
└─────────────────────────────────────────────────────────────┘
                              │
                              │ integration point
                              ↑
                   onViewportChanged callback
                 (ChartScrollbar → BravenChart)

┌─────────────────────────────────────────────────────────────┐
│                   InteractionConfig                         │
│  (existing entity, MODIFIED)                                │
│  • enablePanning, enableZooming, ... (existing)             │
│  • showXScrollbar: bool (NEW)                               │
│  • showYScrollbar: bool (NEW)                               │
└─────────────────────────────────────────────────────────────┘
```

---

## Entity 1: ChartScrollbar (Widget)

**Purpose**: Stateful widget that renders scrollbar UI and handles user interactions (drag, click, hover, keyboard)

**File Location**: `lib/src/widgets/chart_scrollbar.dart` (NEW)

### Public API

```dart
/// Dual-purpose scrollbar for chart navigation (pan + zoom).
///
/// Provides two interaction modes:
/// - **Pan**: Drag center of handle to shift viewport
/// - **Zoom**: Drag edges of handle to resize viewport
///
/// Supports mouse, touch, and keyboard interactions with WCAG 2.1 AA accessibility.
class ChartScrollbar extends StatefulWidget {
  const ChartScrollbar({
    super.key,
    required this.axis,
    required this.dataRange,
    required this.viewportRange,
    required this.onViewportChanged,
    required this.theme,
  });

  /// Orientation of the scrollbar (horizontal or vertical).
  final Axis axis;

  /// Full range of data available for this axis.
  /// 
  /// Example: For time series from 2024-01-01 to 2024-12-31,
  /// dataRange = DataRange(min: 0, max: 365) (days since start).
  final DataRange dataRange;

  /// Currently visible range within the data.
  /// 
  /// Must be a subset of [dataRange].
  /// Example: Viewing Jan-Feb = DataRange(min: 0, max: 31).
  final DataRange viewportRange;

  /// Callback fired when user changes viewport via scrollbar interaction.
  /// 
  /// Called on:
  /// - Handle drag (pan or zoom)
  /// - Track click (jump)
  /// - Keyboard navigation (arrow keys, page up/down, home/end)
  /// 
  /// Throttled to max 60 FPS during drag to prevent chart jank.
  final ValueChanged<DataRange> onViewportChanged;

  /// Visual configuration (colors, sizes, interaction settings).
  final ScrollbarConfig theme;

  @override
  State<ChartScrollbar> createState() => _ChartScrollbarState();
}
```

### Internal State (_ChartScrollbarState)

```dart
class _ChartScrollbarState extends State<ChartScrollbar> {
  late ValueNotifier<ScrollbarState> _stateNotifier;
  late ScrollbarController _controller;
  late FocusNode _focusNode;
  DateTime? _lastViewportUpdate;
  Timer? _autoHideTimer;

  @override
  void initState() {
    super.initState();
    _stateNotifier = ValueNotifier(ScrollbarState.initial());
    _controller = ScrollbarController();
    _focusNode = FocusNode();
    
    if (widget.theme.autoHide) {
      _scheduleAutoHide();
    }
  }

  @override
  void didUpdateWidget(ChartScrollbar oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Update handle position/size when viewport or data range changes
    if (oldWidget.viewportRange != widget.viewportRange ||
        oldWidget.dataRange != widget.dataRange) {
      _updateHandleGeometry();
    }
  }

  @override
  void dispose() {
    _stateNotifier.dispose();
    _focusNode.dispose();
    _autoHideTimer?.cancel();
    super.dispose();
  }
  
  // Gesture handlers, keyboard handlers, etc. (see contracts)
}
```

### Relationships

- **USES** ScrollbarController (for coordinate transformations)
- **MANAGES** ScrollbarState (via ValueNotifier)
- **CONSUMES** ScrollbarConfig (from ChartTheme)
- **INTEGRATES WITH** ViewportState (via onViewportChanged callback)
- **RENDERS VIA** CustomPainter (ScrollbarPainter)

---

## Entity 2: ScrollbarState (Immutable State)

**Purpose**: Represents current UI state of scrollbar (handle position, drag state, hover, focus)

**File Location**: `lib/src/widgets/chart_scrollbar.dart` (NEW, private class)

### Data Structure

```dart
/// Immutable state for scrollbar UI.
/// 
/// Managed via ValueNotifier to prevent setState crashes during pointer events.
@immutable
class ScrollbarState {
  const ScrollbarState({
    required this.handlePosition,
    required this.handleSize,
    required this.isDragging,
    required this.hoverZone,
    required this.isFocused,
    required this.isVisible,
  });

  /// Position of scrollbar handle's leading edge (pixels from track start).
  /// 
  /// For horizontal scrollbar: distance from left edge.
  /// For vertical scrollbar: distance from top edge.
  /// 
  /// Constrained to [0, trackSize - handleSize].
  final double handlePosition;

  /// Size of scrollbar handle (pixels along track axis).
  /// 
  /// Calculated as: (viewportRange / dataRange) * trackSize.
  /// Clamped to minimum of ScrollbarConfig.minHandleSize (default 20px).
  final double handleSize;

  /// Whether user is currently dragging the handle.
  /// 
  /// True during GestureDetector.onPanUpdate, false on onPanEnd.
  final bool isDragging;

  /// Which zone the mouse is currently hovering over (if any).
  /// 
  /// Used to:
  /// - Show appropriate cursor (resize vs grab vs click)
  /// - Highlight hover state in theme colors
  /// 
  /// null when mouse not over scrollbar.
  final HitTestZone? hoverZone;

  /// Whether scrollbar has keyboard focus.
  /// 
  /// True when user tabs to scrollbar or clicks it.
  /// Enables keyboard navigation (arrow keys, etc.).
  final bool isFocused;

  /// Whether scrollbar is visible (for auto-hide feature).
  /// 
  /// False after ScrollbarConfig.autoHideDelay expires with no interaction.
  final bool isVisible;

  /// Create initial state (no interaction, default geometry).
  factory ScrollbarState.initial() => const ScrollbarState(
    handlePosition: 0.0,
    handleSize: 20.0,  // Will be recalculated on first build
    isDragging: false,
    hoverZone: null,
    isFocused: false,
    isVisible: true,
  );

  /// Create copy with updated fields (for ValueNotifier updates).
  ScrollbarState copyWith({
    double? handlePosition,
    double? handleSize,
    bool? isDragging,
    HitTestZone? hoverZone,
    bool? isFocused,
    bool? isVisible,
  }) => ScrollbarState(
    handlePosition: handlePosition ?? this.handlePosition,
    handleSize: handleSize ?? this.handleSize,
    isDragging: isDragging ?? this.isDragging,
    hoverZone: hoverZone ?? this.hoverZone,
    isFocused: isFocused ?? this.isFocused,
    isVisible: isVisible ?? this.isVisible,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScrollbarState &&
      handlePosition == other.handlePosition &&
      handleSize == other.handleSize &&
      isDragging == other.isDragging &&
      hoverZone == other.hoverZone &&
      isFocused == other.isFocused &&
      isVisible == other.isVisible;

  @override
  int get hashCode => Object.hash(
    handlePosition,
    handleSize,
    isDragging,
    hoverZone,
    isFocused,
    isVisible,
  );
}
```

### State Transitions

```
┌─────────────┐
│   Initial   │ (handlePosition=0, isDragging=false, hoverZone=null)
└──────┬──────┘
       │
       │ onPointerEnter
       ↓
┌─────────────┐
│   Hovering  │ (hoverZone=leftEdge/rightEdge/center/track)
└──────┬──────┘
       │
       │ onPanStart
       ↓
┌─────────────┐
│   Dragging  │ (isDragging=true, handlePosition updates continuously)
└──────┬──────┘
       │
       │ onPanEnd
       ↓
┌─────────────┐
│   Hovering  │ (isDragging=false, hoverZone restored)
└──────┬──────┘
       │
       │ onPointerExit
       ↓
┌─────────────┐
│   Initial   │
└─────────────┘

┌──────────────┐
│  Unfocused   │ (isFocused=false)
└──────┬───────┘
       │
       │ onFocusGained (Tab key or click)
       ↓
┌──────────────┐
│   Focused    │ (isFocused=true, keyboard navigation enabled)
└──────┬───────┘
       │
       │ onFocusLost (Tab away or Escape)
       ↓
┌──────────────┐
│  Unfocused   │
└──────────────┘

┌──────────────┐
│   Visible    │ (isVisible=true)
└──────┬───────┘
       │
       │ autoHideDelay expires (2 seconds of no interaction)
       ↓
┌──────────────┐
│   Hidden     │ (isVisible=false, opacity=0.0)
└──────┬───────┘
       │
       │ onPointerEnter or keyboard interaction
       ↓
┌──────────────┐
│   Visible    │
└──────────────┘
```

### Validation Rules

- **handlePosition**: Must be ≥ 0 and ≤ (trackSize - handleSize)
- **handleSize**: Must be ≥ ScrollbarConfig.minHandleSize and ≤ trackSize
- **isDragging**: Can only be true if hoverZone is leftEdge, rightEdge, or center (not track)
- **hoverZone**: Can be null or one of HitTestZone enum values
- **isFocused**: Boolean, no constraints
- **isVisible**: Boolean, no constraints

---

## Entity 3: ScrollbarController (Pure Functions)

**Purpose**: Stateless coordinate transformation utilities for scrollbar calculations

**File Location**: `lib/src/widgets/chart_scrollbar.dart` (NEW, private class)

### Data Structure

```dart
/// Pure functions for scrollbar coordinate transformations.
/// 
/// All methods are static (no instance state) to enforce immutability.
/// Performance: All calculations O(1), <0.1ms per call.
class ScrollbarController {
  ScrollbarController._(); // Private constructor (utility class, no instances)

  /// Calculate handle size based on viewport-to-data ratio.
  /// 
  /// Formula: handleSize = (viewportRange / dataRange) * trackSize
  /// Clamped to [minHandleSize, trackSize].
  /// 
  /// Example:
  /// - dataRange: 0-100 (100 data points)
  /// - viewportRange: 0-25 (viewing 25% of data)
  /// - trackSize: 200px
  /// - Result: (25/100) * 200 = 50px handle
  static double calculateHandleSize({
    required DataRange dataRange,
    required DataRange viewportRange,
    required double trackSize,
    required double minHandleSize,
  }) {
    assert(trackSize > 0, 'Track size must be positive');
    assert(minHandleSize > 0, 'Min handle size must be positive');
    assert(dataRange.span > 0, 'Data range span must be positive');
    assert(viewportRange.span > 0, 'Viewport range span must be positive');
    
    final visibleRatio = viewportRange.span / dataRange.span;
    final handleSize = visibleRatio * trackSize;
    return handleSize.clamp(minHandleSize, trackSize);
  }

  /// Calculate handle position based on viewport offset within data range.
  /// 
  /// Formula: handlePosition = ((viewportMin - dataMin) / dataSpan) * (trackSize - handleSize)
  /// Constrained to [0, trackSize - handleSize].
  /// 
  /// Example:
  /// - dataRange: 0-100
  /// - viewportRange: 50-75 (viewport starts at 50% through data)
  /// - trackSize: 200px, handleSize: 50px
  /// - Result: (50/100) * (200-50) = 0.5 * 150 = 75px from track start
  static double calculateHandlePosition({
    required DataRange dataRange,
    required DataRange viewportRange,
    required double trackSize,
    required double handleSize,
  }) {
    assert(trackSize > handleSize, 'Track must be larger than handle');
    assert(dataRange.span > 0, 'Data range span must be positive');
    
    final offsetRatio = (viewportRange.min - dataRange.min) / dataRange.span;
    final position = offsetRatio * (trackSize - handleSize);
    return position.clamp(0.0, trackSize - handleSize);
  }

  /// Convert handle position/size back to data range (inverse of above methods).
  /// 
  /// Used when user drags handle: pixel delta → data range delta.
  /// 
  /// Example:
  /// - Handle at 75px, size 50px, track 200px
  /// - dataRange: 0-100
  /// - offsetRatio: 75 / (200-50) = 0.5
  /// - visibleRatio: 50 / 200 = 0.25
  /// - Result: viewportMin = 0 + (100 * 0.5) = 50
  ///           viewportMax = 50 + (100 * 0.25) = 75
  ///           → DataRange(50, 75)
  static DataRange handleToDataRange({
    required double handlePosition,
    required double handleSize,
    required double trackSize,
    required DataRange dataRange,
  }) {
    assert(trackSize > handleSize, 'Track must be larger than handle');
    assert(handlePosition >= 0 && handlePosition <= trackSize - handleSize,
        'Handle position out of bounds');
    
    final offsetRatio = handlePosition / (trackSize - handleSize);
    final visibleRatio = handleSize / trackSize;
    
    final dataSpan = dataRange.span;
    final viewportSpan = dataSpan * visibleRatio;
    final viewportMin = dataRange.min + (dataSpan * offsetRatio);
    final viewportMax = viewportMin + viewportSpan;
    
    return DataRange(min: viewportMin, max: viewportMax);
  }

  /// Convert data range to handle position/size (forward transformation).
  /// 
  /// Convenience method combining calculateHandleSize + calculateHandlePosition.
  static ({double position, double size}) dataRangeToHandle({
    required DataRange dataRange,
    required DataRange viewportRange,
    required double trackSize,
    required double minHandleSize,
  }) {
    final size = calculateHandleSize(
      dataRange: dataRange,
      viewportRange: viewportRange,
      trackSize: trackSize,
      minHandleSize: minHandleSize,
    );
    final position = calculateHandlePosition(
      dataRange: dataRange,
      viewportRange: viewportRange,
      trackSize: trackSize,
      handleSize: size,
    );
    return (position: position, size: size);
  }

  /// Determine which interaction zone the pointer is over.
  /// 
  /// Zones:
  /// - **leftEdge/topEdge**: First edgeGripWidth pixels of handle (resize min)
  /// - **rightEdge/bottomEdge**: Last edgeGripWidth pixels of handle (resize max)
  /// - **center**: Middle of handle (pan)
  /// - **track**: Outside handle (jump to position)
  /// 
  /// Example (horizontal, edgeGripWidth=8px, handleSize=50px):
  /// - pointerX in [handlePos, handlePos+8): leftEdge
  /// - pointerX in [handlePos+8, handlePos+42): center (50-8-8=34px)
  /// - pointerX in [handlePos+42, handlePos+50): rightEdge
  /// - pointerX outside [handlePos, handlePos+50): track
  static HitTestZone getHitTestZone({
    required Offset pointerPosition,
    required Rect handleBounds,
    required double edgeGripWidth,
    required Axis axis,
  }) {
    final isHorizontal = axis == Axis.horizontal;
    final pointerCoord = isHorizontal ? pointerPosition.dx : pointerPosition.dy;
    final handleStart = isHorizontal ? handleBounds.left : handleBounds.top;
    final handleEnd = isHorizontal ? handleBounds.right : handleBounds.bottom;
    
    // Outside handle → track
    if (pointerCoord < handleStart || pointerCoord > handleEnd) {
      return HitTestZone.track;
    }
    
    // Inside handle → determine edge vs center
    final distanceFromStart = pointerCoord - handleStart;
    final distanceFromEnd = handleEnd - pointerCoord;
    
    if (distanceFromStart <= edgeGripWidth) {
      return isHorizontal ? HitTestZone.leftEdge : HitTestZone.topEdge;
    } else if (distanceFromEnd <= edgeGripWidth) {
      return isHorizontal ? HitTestZone.rightEdge : HitTestZone.bottomEdge;
    } else {
      return HitTestZone.center;
    }
  }

  /// Get appropriate mouse cursor for interaction zone.
  static MouseCursor getCursorForZone(HitTestZone zone, Axis axis) {
    switch (zone) {
      case HitTestZone.leftEdge:
      case HitTestZone.rightEdge:
        return axis == Axis.horizontal 
            ? SystemMouseCursors.resizeColumn 
            : SystemMouseCursors.resizeRow;
      case HitTestZone.topEdge:
      case HitTestZone.bottomEdge:
        return SystemMouseCursors.resizeRow;
      case HitTestZone.center:
        return SystemMouseCursors.grab;
      case HitTestZone.track:
        return SystemMouseCursors.click;
    }
  }
}
```

### Performance Characteristics

| Method | Complexity | Operations | Target Time |
|--------|------------|------------|-------------|
| calculateHandleSize | O(1) | 3 divisions, 1 multiplication, 1 clamp | <0.05ms |
| calculateHandlePosition | O(1) | 2 divisions, 1 multiplication, 1 subtraction, 1 clamp | <0.05ms |
| handleToDataRange | O(1) | 4 divisions, 3 multiplications, 2 additions | <0.1ms |
| dataRangeToHandle | O(1) | Calls above 2 methods | <0.1ms |
| getHitTestZone | O(1) | 6 comparisons, 2 subtractions | <0.01ms |
| getCursorForZone | O(1) | 1 switch statement | <0.01ms |

---

## Entity 4: ScrollbarConfig (Configuration Data Class)

**Purpose**: Immutable configuration for scrollbar visual appearance and interaction behavior

**File Location**: `lib/src/theming/scrollbar_theme.dart` (NEW)

### Data Structure

```dart
/// Configuration for a single scrollbar (X or Y axis).
/// 
/// Immutable data class with copyWith() for customization.
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
    this.gripIndicatorColor = const Color(0xFF757575),
    this.autoHide = true,
    this.autoHideDelay = const Duration(seconds: 2),
    this.fadeDuration = const Duration(milliseconds: 200),
    this.enableResizeHandles = true,
    this.minZoomRatio = 0.01,
    this.maxZoomRatio = 1.0,
  });

  // === Visual Properties ===

  /// Width (for vertical) or height (for horizontal) of the scrollbar track.
  /// 
  /// Default: 12.0 (matches Material Design scrollbar thickness)
  final double thickness;

  /// Minimum size of the handle (prevents tiny handles when zoomed way out).
  /// 
  /// Default: 20.0 (ensures handle remains grabbable)
  final double minHandleSize;

  /// Background color of the scrollbar track.
  /// 
  /// Should have 3:1 contrast ratio with chart background (WCAG 2.1 SC 1.4.11).
  final Color trackColor;

  /// Default color of the scrollbar handle (no interaction).
  /// 
  /// Should have 4.5:1 contrast ratio with trackColor (WCAG 2.1 SC 1.4.3).
  final Color handleColor;

  /// Handle color when mouse is hovering over it.
  /// 
  /// Should have 3:1 contrast ratio with handleColor (WCAG 2.1 SC 1.4.11).
  final Color handleHoverColor;

  /// Handle color when user is dragging it.
  /// 
  /// Should have 3:1 contrast ratio with handleColor (WCAG 2.1 SC 1.4.11).
  final Color handleActiveColor;

  /// Corner radius for handle (rounded rectangle).
  /// 
  /// Default: 4.0 (matches Material Design)
  final double borderRadius;

  /// Visual indicator lines on handle (3 parallel lines in center).
  /// 
  /// Provides visual affordance for draggability.
  final bool showGripIndicator;

  /// Color of grip indicator lines.
  final Color gripIndicatorColor;

  // === Interaction Properties ===

  /// Width of edge interaction zones (for resize handles).
  /// 
  /// First/last edgeGripWidth pixels of handle trigger resize mode.
  /// Default: 8.0 (large enough for mouse, <20% of minHandleSize).
  final double edgeGripWidth;

  /// Whether to enable edge resize handles (if false, only center pan works).
  /// 
  /// Disable for simplified scrollbar (pan-only, no zoom).
  final bool enableResizeHandles;

  /// Minimum zoom ratio (viewportRange / dataRange).
  /// 
  /// Default: 0.01 (1% minimum - prevents zooming in so far you see <1% of data).
  final double minZoomRatio;

  /// Maximum zoom ratio (viewportRange / dataRange).
  /// 
  /// Default: 1.0 (100% maximum - prevents zooming out past full data range).
  final double maxZoomRatio;

  // === Auto-Hide Properties ===

  /// Whether scrollbar auto-hides after period of inactivity.
  /// 
  /// Default: true (common pattern in modern UIs).
  final bool autoHide;

  /// Delay before auto-hiding scrollbar (if autoHide is true).
  /// 
  /// Timer resets on any pointer or keyboard interaction.
  final Duration autoHideDelay;

  /// Duration of fade-in/fade-out animation when auto-hiding.
  final Duration fadeDuration;

  // === Factory Constructors ===

  /// Light theme preset (light background, dark handle).
  static const ScrollbarConfig defaultLight = ScrollbarConfig(
    trackColor: Color(0xFFF5F5F5),      // Light grey
    handleColor: Color(0xFFBDBDBD),     // Medium grey
    handleHoverColor: Color(0xFF9E9E9E), // Darker grey
    handleActiveColor: Color(0xFF757575), // Dark grey
  );

  /// Dark theme preset (dark background, light handle).
  static const ScrollbarConfig defaultDark = ScrollbarConfig(
    trackColor: Color(0xFF212121),      // Dark background
    handleColor: Color(0xFF616161),     // Medium grey
    handleHoverColor: Color(0xFF757575), // Lighter grey
    handleActiveColor: Color(0xFF9E9E9E), // Light grey
  );

  /// High contrast preset (WCAG 2.1 AAA - 7:1 contrast ratios).
  static const ScrollbarConfig highContrast = ScrollbarConfig(
    trackColor: Color(0xFFFFFFFF),      // Pure white
    handleColor: Color(0xFF000000),     // Pure black
    handleHoverColor: Color(0xFF1976D2), // Blue
    handleActiveColor: Color(0xFFD32F2F), // Red
  );

  /// Create copy with selective overrides.
  ScrollbarConfig copyWith({
    double? thickness,
    double? minHandleSize,
    Color? trackColor,
    Color? handleColor,
    Color? handleHoverColor,
    Color? handleActiveColor,
    double? borderRadius,
    double? edgeGripWidth,
    bool? showGripIndicator,
    Color? gripIndicatorColor,
    bool? autoHide,
    Duration? autoHideDelay,
    Duration? fadeDuration,
    bool? enableResizeHandles,
    double? minZoomRatio,
    double? maxZoomRatio,
  }) => ScrollbarConfig(
    thickness: thickness ?? this.thickness,
    minHandleSize: minHandleSize ?? this.minHandleSize,
    trackColor: trackColor ?? this.trackColor,
    handleColor: handleColor ?? this.handleColor,
    handleHoverColor: handleHoverColor ?? this.handleHoverColor,
    handleActiveColor: handleActiveColor ?? this.handleActiveColor,
    borderRadius: borderRadius ?? this.borderRadius,
    edgeGripWidth: edgeGripWidth ?? this.edgeGripWidth,
    showGripIndicator: showGripIndicator ?? this.showGripIndicator,
    gripIndicatorColor: gripIndicatorColor ?? this.gripIndicatorColor,
    autoHide: autoHide ?? this.autoHide,
    autoHideDelay: autoHideDelay ?? this.autoHideDelay,
    fadeDuration: fadeDuration ?? this.fadeDuration,
    enableResizeHandles: enableResizeHandles ?? this.enableResizeHandles,
    minZoomRatio: minZoomRatio ?? this.minZoomRatio,
    maxZoomRatio: maxZoomRatio ?? this.maxZoomRatio,
  );

  /// Serialize to JSON (for theme persistence).
  Map<String, dynamic> toJson() => {
    'thickness': thickness,
    'minHandleSize': minHandleSize,
    'trackColor': trackColor.value,
    'handleColor': handleColor.value,
    'handleHoverColor': handleHoverColor.value,
    'handleActiveColor': handleActiveColor.value,
    'borderRadius': borderRadius,
    'edgeGripWidth': edgeGripWidth,
    'showGripIndicator': showGripIndicator,
    'gripIndicatorColor': gripIndicatorColor.value,
    'autoHide': autoHide,
    'autoHideDelayMs': autoHideDelay.inMilliseconds,
    'fadeDurationMs': fadeDuration.inMilliseconds,
    'enableResizeHandles': enableResizeHandles,
    'minZoomRatio': minZoomRatio,
    'maxZoomRatio': maxZoomRatio,
  };

  /// Deserialize from JSON.
  factory ScrollbarConfig.fromJson(Map<String, dynamic> json) => ScrollbarConfig(
    thickness: json['thickness'] as double,
    minHandleSize: json['minHandleSize'] as double,
    trackColor: Color(json['trackColor'] as int),
    handleColor: Color(json['handleColor'] as int),
    handleHoverColor: Color(json['handleHoverColor'] as int),
    handleActiveColor: Color(json['handleActiveColor'] as int),
    borderRadius: json['borderRadius'] as double,
    edgeGripWidth: json['edgeGripWidth'] as double,
    showGripIndicator: json['showGripIndicator'] as bool,
    gripIndicatorColor: Color(json['gripIndicatorColor'] as int),
    autoHide: json['autoHide'] as bool,
    autoHideDelay: Duration(milliseconds: json['autoHideDelayMs'] as int),
    fadeDuration: Duration(milliseconds: json['fadeDurationMs'] as int),
    enableResizeHandles: json['enableResizeHandles'] as bool,
    minZoomRatio: json['minZoomRatio'] as double,
    maxZoomRatio: json['maxZoomRatio'] as double,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScrollbarConfig &&
      thickness == other.thickness &&
      minHandleSize == other.minHandleSize &&
      trackColor == other.trackColor &&
      handleColor == other.handleColor &&
      handleHoverColor == other.handleHoverColor &&
      handleActiveColor == other.handleActiveColor &&
      borderRadius == other.borderRadius &&
      edgeGripWidth == other.edgeGripWidth &&
      showGripIndicator == other.showGripIndicator &&
      gripIndicatorColor == other.gripIndicatorColor &&
      autoHide == other.autoHide &&
      autoHideDelay == other.autoHideDelay &&
      fadeDuration == other.fadeDuration &&
      enableResizeHandles == other.enableResizeHandles &&
      minZoomRatio == other.minZoomRatio &&
      maxZoomRatio == other.maxZoomRatio;

  @override
  int get hashCode => Object.hash(
    thickness,
    minHandleSize,
    trackColor,
    handleColor,
    handleHoverColor,
    handleActiveColor,
    borderRadius,
    edgeGripWidth,
    showGripIndicator,
    gripIndicatorColor,
    autoHide,
    autoHideDelay,
    fadeDuration,
    enableResizeHandles,
    minZoomRatio,
    maxZoomRatio,
  );
}
```

### Validation Rules

- **thickness**: > 0 (typically 8-20px)
- **minHandleSize**: ≥ edgeGripWidth * 2 (must fit both edge zones), typically 20-40px
- **trackColor, handleColor, etc.**: Any Color (no constraints, but should meet WCAG ratios)
- **borderRadius**: ≥ 0 (0 = sharp corners, >0 = rounded)
- **edgeGripWidth**: > 0 and < minHandleSize / 2 (must fit within handle)
- **minZoomRatio**: > 0 and < maxZoomRatio (must be valid range)
- **maxZoomRatio**: ≤ 1.0 (can't show more than 100% of data)
- **autoHideDelay**: > Duration.zero (if autoHide is true)

---

## Entity 5: ScrollbarTheme (Component Theme)

**Purpose**: Container for X and Y axis scrollbar configurations (7th component of ChartTheme)

**File Location**: `lib/src/theming/scrollbar_theme.dart` (NEW)

### Data Structure

```dart
/// Theme for both X and Y axis scrollbars (7th component of ChartTheme).
/// 
/// Allows independent styling of horizontal vs vertical scrollbars.
@immutable
class ScrollbarTheme {
  const ScrollbarTheme({
    required this.xAxisScrollbar,
    required this.yAxisScrollbar,
  });

  /// Configuration for horizontal scrollbar (below chart).
  final ScrollbarConfig xAxisScrollbar;

  /// Configuration for vertical scrollbar (right of chart).
  final ScrollbarConfig yAxisScrollbar;

  /// Light theme preset (light background charts).
  static const ScrollbarTheme defaultLight = ScrollbarTheme(
    xAxisScrollbar: ScrollbarConfig.defaultLight,
    yAxisScrollbar: ScrollbarConfig.defaultLight,
  );

  /// Dark theme preset (dark background charts).
  static const ScrollbarTheme defaultDark = ScrollbarTheme(
    xAxisScrollbar: ScrollbarConfig.defaultDark,
    yAxisScrollbar: ScrollbarConfig.defaultDark,
  );

  /// High contrast preset (accessibility-focused).
  static const ScrollbarTheme highContrast = ScrollbarTheme(
    xAxisScrollbar: ScrollbarConfig.highContrast,
    yAxisScrollbar: ScrollbarConfig.highContrast,
  );

  /// Create copy with selective overrides.
  ScrollbarTheme copyWith({
    ScrollbarConfig? xAxisScrollbar,
    ScrollbarConfig? yAxisScrollbar,
  }) => ScrollbarTheme(
    xAxisScrollbar: xAxisScrollbar ?? this.xAxisScrollbar,
    yAxisScrollbar: yAxisScrollbar ?? this.yAxisScrollbar,
  );

  /// Serialize to JSON.
  Map<String, dynamic> toJson() => {
    'xAxisScrollbar': xAxisScrollbar.toJson(),
    'yAxisScrollbar': yAxisScrollbar.toJson(),
  };

  /// Deserialize from JSON.
  factory ScrollbarTheme.fromJson(Map<String, dynamic> json) => ScrollbarTheme(
    xAxisScrollbar: ScrollbarConfig.fromJson(json['xAxisScrollbar'] as Map<String, dynamic>),
    yAxisScrollbar: ScrollbarConfig.fromJson(json['yAxisScrollbar'] as Map<String, dynamic>),
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScrollbarTheme &&
      xAxisScrollbar == other.xAxisScrollbar &&
      yAxisScrollbar == other.yAxisScrollbar;

  @override
  int get hashCode => Object.hash(xAxisScrollbar, yAxisScrollbar);
}
```

### Integration with ChartTheme

```dart
// MODIFIED: Add scrollbarTheme to ChartTheme (lib/src/theming/chart_theme.dart)
class ChartTheme {
  const ChartTheme({
    required this.backgroundColor,
    required this.borderColor,
    required this.borderWidth,
    required this.padding,
    required this.gridStyle,
    required this.axisStyle,
    required this.seriesTheme,
    required this.interactionTheme,
    required this.typographyTheme,
    required this.animationTheme,
    required this.scrollbarTheme,  // ← NEW (7th component theme)
  });

  // ... existing fields ...
  
  /// Scrollbar appearance and behavior configuration.
  final ScrollbarTheme scrollbarTheme;

  // Update predefined themes to include scrollbarTheme
  static final ChartTheme defaultLight = ChartTheme(
    // ... existing theme properties ...
    scrollbarTheme: ScrollbarTheme.defaultLight,
  );

  static final ChartTheme defaultDark = ChartTheme(
    // ... existing theme properties ...
    scrollbarTheme: ScrollbarTheme.defaultDark,
  );

  // ... other predefined themes ...

  // Update copyWith() to include scrollbarTheme
  ChartTheme copyWith({
    // ... existing parameters ...
    ScrollbarTheme? scrollbarTheme,
  }) => ChartTheme(
    // ... existing fields ...
    scrollbarTheme: scrollbarTheme ?? this.scrollbarTheme,
  );

  // Update toJson() and fromJson() to include scrollbarTheme
  Map<String, dynamic> toJson() => {
    // ... existing fields ...
    'scrollbarTheme': scrollbarTheme.toJson(),
  };

  factory ChartTheme.fromJson(Map<String, dynamic> json) => ChartTheme(
    // ... existing fields ...
    scrollbarTheme: ScrollbarTheme.fromJson(json['scrollbarTheme'] as Map<String, dynamic>),
  );
}
```

---

## Entity 6: ViewportState (MODIFIED - Integration Point)

**Purpose**: Existing entity that represents visible data range, extended to support scrollbar updates

**File Location**: `lib/src/coordinate_system/viewport_state.dart` (EXISTING, no modifications needed)

### Current API (Already Sufficient)

```dart
/// Immutable viewport state representing visible data range.
@immutable
class ViewportState {
  const ViewportState({
    required this.xRange,
    required this.yRange,
  });

  /// Visible range on X axis.
  final DataRange xRange;

  /// Visible range on Y axis.
  final DataRange yRange;

  /// Create copy with new ranges (used by scrollbar to update viewport).
  /// 
  /// Scrollbar integration:
  /// - X scrollbar calls: viewportState.withRanges(newXRange, viewportState.yRange)
  /// - Y scrollbar calls: viewportState.withRanges(viewportState.xRange, newYRange)
  ViewportState withRanges(DataRange x, DataRange y) => ViewportState(
    xRange: x,
    yRange: y,
  );

  // ... equality, hashCode, etc.
}
```

### Integration Pattern

**No modifications needed** - existing `withRanges()` method perfect for scrollbar integration.

**Usage from ChartScrollbar**:
```dart
// BravenChart manages ViewportState
late ValueNotifier<ViewportState> _viewportNotifier;

// Pass callback to scrollbar
ChartScrollbar(
  axis: Axis.horizontal,
  dataRange: fullXRange,
  viewportRange: currentViewport.xRange,
  onViewportChanged: (newXRange) {
    // Update viewport immutably
    _viewportNotifier.value = _viewportNotifier.value.withRanges(
      newXRange,
      _viewportNotifier.value.yRange,  // Y unchanged
    );
  },
)
```

---

## Entity 7: InteractionConfig (MODIFIED - Enable Flags)

**Purpose**: Existing configuration for chart interactions, extended with scrollbar enable flags

**File Location**: `lib/src/interaction/interaction_config.dart` (EXISTING, requires modification)

### Modifications Required

```dart
/// Configuration for chart interaction behaviors.
@immutable
class InteractionConfig {
  const InteractionConfig({
    // === Existing Properties (unchanged) ===
    this.enablePanning = true,
    this.enableZooming = true,
    this.enableTooltips = true,
    this.enableCrosshair = false,
    this.enableSelection = false,
    // ... other existing properties ...
    
    // === NEW Properties (for scrollbar feature) ===
    this.showXScrollbar = false,  // ← NEW: Show horizontal scrollbar
    this.showYScrollbar = false,  // ← NEW: Show vertical scrollbar
  });

  // ... existing properties ...

  /// Whether to show horizontal scrollbar below chart.
  /// 
  /// When true, BravenChart renders ChartScrollbar(axis: Axis.horizontal).
  /// Independent of enablePanning/enableZooming (scrollbar can work even if direct chart pan/zoom disabled).
  final bool showXScrollbar;

  /// Whether to show vertical scrollbar to the right of chart.
  /// 
  /// When true, BravenChart renders ChartScrollbar(axis: Axis.vertical).
  final bool showYScrollbar;

  // Update copyWith() to include new properties
  InteractionConfig copyWith({
    // ... existing parameters ...
    bool? showXScrollbar,
    bool? showYScrollbar,
  }) => InteractionConfig(
    // ... existing fields ...
    showXScrollbar: showXScrollbar ?? this.showXScrollbar,
    showYScrollbar: showYScrollbar ?? this.showYScrollbar,
  );

  // Update toJson() and fromJson() to include new properties
  Map<String, dynamic> toJson() => {
    // ... existing fields ...
    'showXScrollbar': showXScrollbar,
    'showYScrollbar': showYScrollbar,
  };

  factory InteractionConfig.fromJson(Map<String, dynamic> json) => InteractionConfig(
    // ... existing fields ...
    showXScrollbar: json['showXScrollbar'] as bool? ?? false,
    showYScrollbar: json['showYScrollbar'] as bool? ?? false,
  );

  // Update equality and hashCode to include new properties
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InteractionConfig &&
      // ... existing comparisons ...
      showXScrollbar == other.showXScrollbar &&
      showYScrollbar == other.showYScrollbar;

  @override
  int get hashCode => Object.hash(
    // ... existing hash values ...
    showXScrollbar,
    showYScrollbar,
  );
}
```

### Usage in BravenChart

```dart
// User enables scrollbars via InteractionConfig
final chart = BravenChart(
  series: [...],
  interactionConfig: InteractionConfig(
    enablePanning: true,
    enableZooming: true,
    showXScrollbar: true,  // ← Enable horizontal scrollbar
    showYScrollbar: true,  // ← Enable vertical scrollbar
  ),
);

// BravenChart build() method conditionally renders scrollbars
@override
Widget build(BuildContext context) {
  return Column(
    children: [
      Expanded(
        child: Row(
          children: [
            Expanded(child: _buildChartCanvas()),
            if (widget.interactionConfig.showYScrollbar)
              ChartScrollbar(
                axis: Axis.vertical,
                dataRange: _fullYRange,
                viewportRange: _currentViewport.yRange,
                onViewportChanged: (newYRange) => _updateViewport(
                  _currentViewport.withRanges(_currentViewport.xRange, newYRange),
                ),
                theme: widget.theme.scrollbarTheme.yAxisScrollbar,
              ),
          ],
        ),
      ),
      if (widget.interactionConfig.showXScrollbar)
        ChartScrollbar(
          axis: Axis.horizontal,
          dataRange: _fullXRange,
          viewportRange: _currentViewport.xRange,
          onViewportChanged: (newXRange) => _updateViewport(
            _currentViewport.withRanges(newXRange, _currentViewport.yRange),
          ),
          theme: widget.theme.scrollbarTheme.xAxisScrollbar,
        ),
    ],
  );
}
```

---

## Supporting Enums & Types

### HitTestZone Enum

```dart
/// Interaction zones within scrollbar for hit testing.
enum HitTestZone {
  /// Left edge of horizontal scrollbar (first edgeGripWidth pixels).
  /// Dragging adjusts viewportMin, keeping viewportMax fixed (zoom in/out left side).
  leftEdge,

  /// Right edge of horizontal scrollbar (last edgeGripWidth pixels).
  /// Dragging adjusts viewportMax, keeping viewportMin fixed (zoom in/out right side).
  rightEdge,

  /// Top edge of vertical scrollbar (first edgeGripWidth pixels).
  /// Dragging adjusts viewportMin, keeping viewportMax fixed.
  topEdge,

  /// Bottom edge of vertical scrollbar (last edgeGripWidth pixels).
  /// Dragging adjusts viewportMax, keeping viewportMin fixed.
  bottomEdge,

  /// Center of scrollbar handle (between edge zones).
  /// Dragging pans viewport (shifts both min and max by same delta).
  center,

  /// Track area outside handle.
  /// Clicking jumps viewport to center around click position.
  track,
}
```

### DataRange (Existing - No Changes)

```dart
/// Immutable range of data values (min-max pair).
@immutable
class DataRange {
  const DataRange({required this.min, required this.max})
      : assert(min <= max, 'Min must be <= max');

  final double min;
  final double max;

  double get span => max - min;

  // ... equality, hashCode, etc.
}
```

---

## Entity Relationships Summary

```
BravenChart (root widget)
  ├─ manages → ViewportState (current visible range)
  ├─ contains → InteractionConfig (showXScrollbar, showYScrollbar flags)
  └─ renders → ChartScrollbar (if showXScrollbar/showYScrollbar enabled)
                  ├─ manages → ScrollbarState (via ValueNotifier)
                  ├─ uses → ScrollbarController (coordinate transformations)
                  ├─ styled by → ScrollbarConfig (from ChartTheme.scrollbarTheme)
                  └─ updates → ViewportState (via onViewportChanged callback)

ChartTheme (root theme)
  ├─ contains → GridStyle, AxisStyle, SeriesTheme, ... (existing)
  └─ contains → ScrollbarTheme (NEW, 7th component)
                  ├─ xAxisScrollbar: ScrollbarConfig
                  └─ yAxisScrollbar: ScrollbarConfig
```

---

## Data Flow

### User Drags Scrollbar Handle (Pan Mode)

```
1. User drags center of handle (pointer events @ 100+ Hz)
   ↓
2. GestureDetector.onPanUpdate() in ChartScrollbar
   ↓
3. Update ScrollbarState.handlePosition via ValueNotifier (immediate visual feedback)
   ↓
4. Throttle check: Has 16ms elapsed since last viewport update? (60 FPS cap)
   ↓ (if yes)
5. ScrollbarController.handleToDataRange() calculates new DataRange (<0.1ms)
   ↓
6. onViewportChanged callback fires with new DataRange
   ↓
7. BravenChart updates ViewportState via viewportState.withRanges()
   ↓
8. Chart re-renders with new visible range (<16ms)
   ↓
9. Scrollbar receives updated viewportRange prop, recalculates handle position
   ↓
10. Next drag event (repeat from step 1)
```

### User Clicks Scrollbar Track (Jump Mode)

```
1. User clicks track (outside handle)
   ↓
2. GestureDetector.onTapUp() in ChartScrollbar
   ↓
3. Calculate click position as percentage of track
   ↓
4. ScrollbarController.handleToDataRange() with handle centered at click position
   ↓
5. onViewportChanged callback fires
   ↓
6. ViewportState updated, chart re-renders
```

### Keyboard Navigation

```
1. User presses arrow key (scrollbar has focus)
   ↓
2. KeyboardListener.onKey() in ChartScrollbar
   ↓
3. Calculate delta based on key:
   - Arrow: 5% of visible range
   - Shift+Arrow: 25% of visible range
   - Ctrl+Arrow: ±10% zoom level
   - Home/End: Jump to data start/end
   - Page Up/Down: 1 viewport width
   ↓
4. Apply delta to current viewportRange
   ↓
5. onViewportChanged callback fires
   ↓
6. ViewportState updated, chart re-renders
```

---

## Performance Guarantees

| Operation | Target | Validation Method |
|-----------|--------|-------------------|
| Handle calculation | <0.1ms | Benchmark with 1M iterations |
| Scrollbar render | <1ms | CustomPainter profiling |
| Viewport update | <16ms | Full chart re-render (10K points) |
| Drag frame time | <16.67ms | Flutter DevTools performance overlay |
| Memory overhead | <100KB | Both scrollbars, DevTools memory profiler |
| Jank rate | 0% | 1000-frame drag session |

---

## Accessibility Compliance

| WCAG Guideline | Requirement | Implementation |
|----------------|-------------|----------------|
| **2.1.1 Keyboard** | All functionality via keyboard | Arrow keys (pan), Ctrl+arrow (zoom), Page Up/Down (jump), Home/End (boundaries) |
| **1.4.3 Contrast (Minimum)** | 4.5:1 for critical UI | Handle vs track: 4.5:1+ in all predefined themes |
| **1.4.11 Non-text Contrast** | 3:1 for UI components | Track vs background: 3:1+, hover/active states: 3:1+ |
| **4.1.3 Status Messages** | Screen reader announcements | Semantics widget with value updates ("Showing 50-75, 25% of data") |
| **2.4.7 Focus Visible** | Visible focus indicator | 2px solid focus ring, high contrast |

---

## Validation & Testing

### Contract Tests (Required for Each Entity)

1. **ChartScrollbar Widget Contract**:
   - Renders correctly for both Axis.horizontal and Axis.vertical
   - Respects ScrollbarConfig visual properties
   - Fires onViewportChanged with correct DataRange values
   - Handles edge cases (viewport == data range, min handle size, etc.)

2. **ScrollbarState Contract**:
   - Immutable (all fields final)
   - copyWith() produces new instance with updated fields
   - Equality works correctly
   - Validation rules enforced (position ≥ 0, size ≥ minHandleSize, etc.)

3. **ScrollbarController Contract**:
   - All methods pure (no side effects, deterministic output)
   - O(1) complexity validated (benchmarks)
   - Inverse transformations correct (data→handle→data returns original)
   - Edge cases handled (zero data span, track smaller than handle, etc.)

4. **ScrollbarConfig Contract**:
   - Immutable (all fields final)
   - copyWith() works correctly
   - toJson()/fromJson() round-trips without data loss
   - Equality and hashCode consistent

5. **ScrollbarTheme Contract**:
   - Immutable, copyWith(), toJson()/fromJson() all work
   - Integrates cleanly with ChartTheme

6. **ViewportState Integration Contract**:
   - withRanges() produces correct new state
   - No unintended side effects on coordinate system

7. **InteractionConfig Integration Contract**:
   - showXScrollbar/showYScrollbar flags work independently
   - Serialization includes new fields

### Golden Tests (Visual Regression)

- Scrollbar rendering in all hover/drag/focus states
- Both horizontal and vertical orientations
- All predefined themes (defaultLight, defaultDark, highContrast)
- Edge cases (min handle size, auto-hide, grip indicator)

### Integration Tests

- Full drag interaction (handle position updates → viewport changes → chart re-renders)
- Track click (jump to position)
- Keyboard navigation (all key combinations)
- Theme changes (runtime theme switching)
- Auto-hide behavior (timer triggers fade-out)

### Performance Tests

- Benchmark ScrollbarController methods (target <0.1ms)
- Frame time during drag (target <16.67ms, 60 FPS)
- Memory usage (target <100KB for both scrollbars)
- Jank detection (0% dropped frames in 1000-frame drag session)

### Accessibility Tests

- Keyboard-only navigation (complete all tasks without mouse)
- Screen reader announcements (validate Semantics labels)
- Contrast ratios (automated WCAG checker)
- Focus visibility (manual testing with Tab key)
