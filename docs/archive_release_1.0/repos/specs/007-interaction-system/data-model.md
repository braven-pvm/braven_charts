# Data Model: Interaction System

**Feature**: Layer 7 Interaction System  
**Branch**: 007-interaction-system  
**Date**: 2025-01-07  
**Source**: Extracted from spec.md Key Entities section

## Entity Overview

The Interaction System consists of 6 key entities:

1. **InteractionState** - Central state for all user interactions
2. **ZoomPanState** - Zoom/pan viewport state
3. **GestureDetails** - Information about gestures
4. **CrosshairConfig** - Crosshair configuration
5. **TooltipConfig** - Tooltip configuration
6. **InteractionConfig** - Main wrapper configuration for all interaction features

---

## Entity Definitions

### 1. InteractionState

**Purpose**: Represents the current state of all user interactions with the chart.

**Attributes**:
```dart
class InteractionState {
  // Hover state (desktop mouse)
  final ChartDataPoint? hoveredPoint;
  final String? hoveredSeriesId;
  
  // Focus state (keyboard navigation)
  final ChartDataPoint? focusedPoint;
  final int focusedPointIndex;
  
  // Selection state (multi-select support)
  final List<ChartDataPoint> selectedPoints;
  
  // Crosshair state
  final Offset? crosshairPosition;  // Screen coordinates
  final List<ChartDataPoint> snapPoints;  // Points at crosshair position
  final bool isCrosshairVisible;
  
  // Tooltip state
  final bool isTooltipVisible;
  final Offset? tooltipPosition;
  final ChartDataPoint? tooltipDataPoint;
  
  // Viewport state
  final ZoomPanState zoomPanState;
  
  // Active gesture
  final GestureDetails? activeGesture;
  
  // Timestamp for debugging
  final DateTime lastUpdated;
}
```

**Relationships**:
- **Contains one** `ZoomPanState` (viewport information)
- **References zero or more** `ChartDataPoint` (selected points, hovered point, etc.)
- **Contains zero or one** `GestureDetails` (active gesture)

**Validation Rules**:
- If `isCrosshairVisible == true`, then `crosshairPosition != null`
- If `isTooltipVisible == true`, then `tooltipPosition != null AND tooltipDataPoint != null`
- `focusedPointIndex >= 0` if `focusedPoint != null`
- `selectedPoints` list can be empty (no selection)

**State Transitions**:
```
Initial State:
  - All nullable fields are null
  - Lists are empty
  - Booleans are false
  - zoomPanState is at default (1.0 zoom, zero pan)

Mouse Enter Chart:
  - isCrosshairVisible = true
  
Mouse Move:
  - crosshairPosition updated
  - snapPoints calculated (nearest data point within radius)
  - hoveredPoint updated if snap occurred
  
Mouse Exit Chart:
  - isCrosshairVisible = false
  - hoveredPoint = null
  
Tap on Data Point:
  - tooltipDataPoint = tapped point
  - tooltipPosition = tap position
  - isTooltipVisible = true
  
Keyboard Focus:
  - focusedPoint = focused data point
  - focusedPointIndex = index in data series
```

**Methods**:
```dart
class InteractionState {
  // Factory constructors
  factory InteractionState.initial() { /* ... */ }
  factory InteractionState.fromJson(Map<String, dynamic> json) { /* ... */ }
  
  // Immutable update methods (copyWith pattern)
  InteractionState copyWith({
    ChartDataPoint? hoveredPoint,
    ChartDataPoint? focusedPoint,
    Offset? crosshairPosition,
    // ... other fields
  });
  
  // Helper methods
  bool get hasHoveredPoint => hoveredPoint != null;
  bool get hasFocusedPoint => focusedPoint != null;
  bool get hasActiveGesture => activeGesture != null;
  
  // Serialization
  Map<String, dynamic> toJson() { /* ... */ }
}
```

---

### 2. ZoomPanState

**Purpose**: Represents the current zoom level and pan offset of the chart viewport.

**Attributes**:
```dart
class ZoomPanState {
  // Zoom levels (1.0 = 100%, no zoom)
  final double zoomLevelX;
  final double zoomLevelY;
  
  // Pan offset in data space
  final Offset panOffset;
  
  // Visible data bounds after zoom/pan (calculated)
  final Rect visibleDataBounds;
  
  // Original bounds (before zoom/pan)
  final Rect originalDataBounds;
  
  // Constraints
  final double minZoomLevel;
  final double maxZoomLevel;
  final bool allowOverscroll;
  
  // Animation state
  final bool isAnimating;
  final Duration animationDuration;
}
```

**Relationships**:
- **Owned by** `InteractionState` (composition)
- **Used by** rendering system to cull invisible points
- **Updated by** zoom/pan interactions

**Validation Rules**:
- `zoomLevelX >= minZoomLevel AND zoomLevelX <= maxZoomLevel`
- `zoomLevelY >= minZoomLevel AND zoomLevelY <= maxZoomLevel`
- If `allowOverscroll == false`, then pan offset constrained to data bounds
- `minZoomLevel > 0` (cannot zoom to zero or negative)
- `maxZoomLevel > minZoomLevel`

**State Transitions**:
```
Initial State:
  - zoomLevelX = 1.0, zoomLevelY = 1.0 (no zoom)
  - panOffset = Offset.zero (no pan)
  - visibleDataBounds = originalDataBounds
  
Zoom In (e.g., scroll wheel up):
  - zoomLevelX *= 1.1 (or scale from pinch gesture)
  - visibleDataBounds recalculated
  - Constrain to maxZoomLevel
  
Zoom Out (e.g., scroll wheel down):
  - zoomLevelX *= 0.9
  - visibleDataBounds recalculated
  - Constrain to minZoomLevel
  
Pan (e.g., drag or arrow keys):
  - panOffset += delta
  - Constrain to bounds if allowOverscroll == false
  - visibleDataBounds recalculated
  
Reset (e.g., double-click):
  - isAnimating = true
  - zoomLevelX → 1.0
  - zoomLevelY → 1.0
  - panOffset → Offset.zero
  - After animation: isAnimating = false
```

**Methods**:
```dart
class ZoomPanState {
  // Factory constructors
  factory ZoomPanState.initial(Rect dataBounds) { /* ... */ }
  
  // Immutable update methods
  ZoomPanState copyWith({
    double? zoomLevelX,
    double? zoomLevelY,
    Offset? panOffset,
    // ... other fields
  });
  
  // Calculated properties
  Rect get visibleDataBounds {
    double visibleWidth = originalDataBounds.width / zoomLevelX;
    double visibleHeight = originalDataBounds.height / zoomLevelY;
    return Rect.fromLTWH(
      panOffset.dx,
      panOffset.dy,
      visibleWidth,
      visibleHeight,
    );
  }
  
  // Constraint methods
  ZoomPanState constrainZoom() {
    return copyWith(
      zoomLevelX: zoomLevelX.clamp(minZoomLevel, maxZoomLevel),
      zoomLevelY: zoomLevelY.clamp(minZoomLevel, maxZoomLevel),
    );
  }
  
  ZoomPanState constrainPan() {
    if (allowOverscroll) return this;
    
    // Constrain pan offset to data bounds
    Offset constrainedPan = Offset(
      panOffset.dx.clamp(0, originalDataBounds.width - visibleDataBounds.width),
      panOffset.dy.clamp(0, originalDataBounds.height - visibleDataBounds.height),
    );
    return copyWith(panOffset: constrainedPan);
  }
  
  // Animation helpers
  ZoomPanState animateTo(ZoomPanState target, double progress) {
    // Linear interpolation for smooth animation
    return ZoomPanState(
      zoomLevelX: lerpDouble(zoomLevelX, target.zoomLevelX, progress)!,
      zoomLevelY: lerpDouble(zoomLevelY, target.zoomLevelY, progress)!,
      panOffset: Offset.lerp(panOffset, target.panOffset, progress)!,
      // ... other fields
    );
  }
}
```

---

### 3. GestureDetails

**Purpose**: Information about current or completed gesture.

**Attributes**:
```dart
class GestureDetails {
  // Gesture type
  final GestureType type; // enum: tap, doubleTap, longPress, pan, pinch
  
  // Position information
  final Offset startPosition;     // Screen coordinates where gesture started
  final Offset currentPosition;   // Current screen coordinates
  final Offset? endPosition;      // Screen coordinates where gesture ended (null if ongoing)
  
  // Pinch-specific
  final double? initialScale;     // Initial distance between fingers
  final double? currentScale;     // Current distance / initial distance
  
  // Pan-specific
  final Offset? panDelta;         // Delta from last pan update
  final Offset? totalPanDelta;    // Total delta from start
  
  // Timing
  final DateTime startTime;
  final DateTime? endTime;        // null if gesture ongoing
  
  // Metadata
  final int pointerCount;         // Number of fingers/pointers (1 for mouse, 1-5 for touch)
  final PointerDeviceKind deviceKind; // mouse, touch, stylus, trackpad
}
```

**Relationships**:
- **Created by** `IGestureRecognizer` implementations
- **Passed to** interaction callbacks (onDataPointTap, etc.)
- **Referenced by** `InteractionState.activeGesture`

**Validation Rules**:
- If `type == GestureType.pinch`, then `pointerCount >= 2`
- If `type == GestureType.pinch`, then `initialScale != null AND currentScale != null`
- If `type == GestureType.pan`, then `panDelta != null AND totalPanDelta != null`
- `endPosition != null` implies `endTime != null` (completed gesture)
- `startTime <= endTime` (if endTime not null)

**State Transitions**:
```
Gesture Start:
  - type determined by gesture recognizer
  - startPosition = initial pointer position
  - currentPosition = startPosition
  - startTime = now
  - endPosition = null (ongoing)
  
Gesture Update (e.g., pan or pinch):
  - currentPosition updated
  - panDelta or currentScale updated
  - endPosition still null
  
Gesture End:
  - endPosition = final pointer position
  - endTime = now
```

**Methods**:
```dart
class GestureDetails {
  // Factory constructors for each gesture type
  factory GestureDetails.tap(Offset position) { /* ... */ }
  factory GestureDetails.pan(Offset start, Offset current, Offset delta) { /* ... */ }
  factory GestureDetails.pinch(Offset start, double scale) { /* ... */ }
  
  // Calculated properties
  Duration get duration => (endTime ?? DateTime.now()).difference(startTime);
  bool get isComplete => endTime != null;
  bool get isOngoing => endTime == null;
  
  // Helper methods
  double get distance => (currentPosition - startPosition).distance;
  double get velocity {
    if (!isComplete) return 0;
    return distance / duration.inMilliseconds; // pixels per millisecond
  }
}
```

---

### 4. CrosshairConfig

**Purpose**: Configuration for crosshair visual appearance and behavior.

**Attributes**:
```dart
class CrosshairConfig {
  // Enable/disable
  final bool enabled;
  
  // Mode
  final CrosshairMode mode; // enum: none, vertical, horizontal, both
  
  // Snap behavior
  final bool snapToDataPoint;
  final double snapRadius;  // Pixels (default 20)
  
  // Visual style
  final CrosshairStyle style;
  
  // Labels
  final bool showCoordinateLabels;
  final TextStyle? coordinateLabelStyle;
}

class CrosshairStyle {
  final Color lineColor;
  final double lineWidth;
  final List<double>? dashPattern; // [5, 3] for dashed line
  final StrokeCap strokeCap;
}

enum CrosshairMode {
  none,       // No crosshair
  vertical,   // Vertical line only
  horizontal, // Horizontal line only
  both,       // Both lines (full crosshair)
}
```

**Relationships**:
- **Provided by** developer in `InteractionConfig`
- **Used by** `ICrosshairRenderer` implementations

**Validation Rules**:
- `snapRadius >= 0` (cannot be negative)
- If `enabled == false`, crosshair is not rendered
- If `mode == CrosshairMode.none`, crosshair is not rendered even if enabled
- `lineWidth > 0`

**Default Values**:
```dart
factory CrosshairConfig.defaultConfig() {
  return CrosshairConfig(
    enabled: true,
    mode: CrosshairMode.both,
    snapToDataPoint: true,
    snapRadius: 20.0,
    style: CrosshairStyle(
      lineColor: Colors.grey.withOpacity(0.7),
      lineWidth: 1.0,
      dashPattern: [5, 3],
      strokeCap: StrokeCap.round,
    ),
    showCoordinateLabels: true,
    coordinateLabelStyle: TextStyle(fontSize: 12, color: Colors.black87),
  );
}
```

---

### 5. TooltipConfig

**Purpose**: Configuration for tooltip behavior and appearance.

**Attributes**:
```dart
class TooltipConfig {
  // Enable/disable
  final bool enabled;
  
  // Trigger mode
  final TooltipTriggerMode triggerMode; // enum: hover, tap, both
  
  // Timing
  final Duration showDelay;    // Delay before showing (default 300ms)
  final Duration hideDelay;    // Delay before hiding (default 0ms)
  
  // Positioning
  final TooltipPosition preferredPosition; // enum: auto, top, bottom, left, right
  final double offsetFromPoint; // Distance from data point (default 10px)
  
  // Visual style
  final TooltipStyle style;
  
  // Custom content
  final Widget Function(BuildContext, ChartDataPoint, String seriesId)? customBuilder;
}

class TooltipStyle {
  final Color backgroundColor;
  final Color borderColor;
  final double borderWidth;
  final double borderRadius;
  final EdgeInsets padding;
  final TextStyle textStyle;
  final BoxShadow? shadow;
}

enum TooltipTriggerMode {
  hover,  // Desktop: mouse hover
  tap,    // Mobile: tap to show
  both,   // Both hover and tap
}

enum TooltipPosition {
  auto,   // Smart positioning (avoid clipping)
  top,
  bottom,
  left,
  right,
}
```

**Relationships**:
- **Provided by** developer in `InteractionConfig`
- **Used by** `ITooltipProvider` implementations

**Validation Rules**:
- `showDelay >= Duration.zero` (cannot be negative)
- `hideDelay >= Duration.zero`
- `offsetFromPoint >= 0`
- If `customBuilder != null`, use custom content; otherwise use default content
- If `preferredPosition == TooltipPosition.auto`, calculate position to avoid clipping

**Default Values**:
```dart
factory TooltipConfig.defaultConfig() {
  return TooltipConfig(
    enabled: true,
    triggerMode: TooltipTriggerMode.both,
    showDelay: Duration(milliseconds: 300),
    hideDelay: Duration.zero,
    preferredPosition: TooltipPosition.auto,
    offsetFromPoint: 10.0,
    style: TooltipStyle(
      backgroundColor: Colors.white,
      borderColor: Colors.grey.shade300,
      borderWidth: 1.0,
      borderRadius: 4.0,
      padding: EdgeInsets.all(8),
      textStyle: TextStyle(fontSize: 14, color: Colors.black87),
      shadow: BoxShadow(
        color: Colors.black.withOpacity(0.1),
        blurRadius: 4,
        offset: Offset(0, 2),
      ),
    ),
    customBuilder: null,
  );
}
```

---

### 6. InteractionConfig

**Purpose**: Main wrapper configuration class that aggregates all interaction feature configurations and callbacks. Supports both simple (boolean flags) and advanced (detailed sub-configs) configuration modes.

**Attributes**:
```dart
class InteractionConfig {
  // Advanced sub-configurations (nullable - if null, simple flags used)
  final CrosshairConfig? crosshair;
  final TooltipConfig? tooltip;
  final ZoomPanConfig? zoomPan;
  final KeyboardConfig? keyboard;
  
  // Simple boolean flags (fallback if sub-configs are null)
  final bool enableCrosshair;
  final bool enableTooltip;
  final bool enableZoom;
  final bool enablePan;
  
  // Callback functions for user interaction events
  final DataPointCallback? onDataPointTap;
  final DataPointCallback? onDataPointDoubleTap;
  final SelectionCallback? onSelectionChanged;
  final ZoomCallback? onZoomChanged;
  final PanCallback? onPanChanged;
  final CrosshairChangeCallback? onCrosshairChanged;
  final TooltipChangeCallback? onTooltipChanged;
  final KeyboardActionCallback? onKeyboardAction;
  
  // Interaction mode (determines which features are active)
  final InteractionMode mode;  // explore, analyze, present
  final InteractionModeChangeCallback? onModeChanged;
}

// Callback type definitions
typedef DataPointCallback = void Function(ChartDataPoint point, Offset position);
typedef SelectionCallback = void Function(List<ChartDataPoint> selectedPoints);
typedef ZoomCallback = void Function(double zoomLevelX, double zoomLevelY);
typedef PanCallback = void Function(Offset panOffset);
typedef CrosshairChangeCallback = void Function(Offset? position, List<ChartDataPoint> snapPoints);
typedef TooltipChangeCallback = void Function(bool visible, ChartDataPoint? dataPoint);
typedef KeyboardActionCallback = void Function(String action, ChartDataPoint? targetPoint);
typedef InteractionModeChangeCallback = void Function(InteractionMode newMode);

// Interaction mode enumeration
enum InteractionMode {
  /// Full exploration mode - all interactions enabled (crosshair, tooltip, zoom, pan, keyboard)
  explore,
  
  /// Analysis mode - focus on data inspection (crosshair, tooltip, selection, keyboard)
  /// Zoom/pan may be limited to prevent accidental viewport changes
  analyze,
  
  /// Presentation mode - minimal interactions (tooltip on tap only)
  /// Designed for presentations where viewport should remain fixed
  present,
}
```

**Relationships**:
- **Contains zero or one** `CrosshairConfig` (advanced crosshair settings)
- **Contains zero or one** `TooltipConfig` (advanced tooltip settings)
- **Contains zero or one** `ZoomPanConfig` (advanced zoom/pan settings)
- **Contains zero or one** `KeyboardConfig` (keyboard navigation settings)
- **Used by** `InteractiveChart` widget (configuration source)
- **Provides callbacks to** Developer (event notifications)

**Validation Rules**:
- If `crosshair != null`, then `enableCrosshair` is ignored (advanced mode)
- If `tooltip != null`, then `enableTooltip` is ignored (advanced mode)
- If `zoomPan != null`, then `enableZoom` and `enablePan` are ignored (advanced mode)
- Cannot have conflicting zoom/pan settings (e.g., `enableZoom=false` but `zoomPan.allowZoom=true`)
- `mode` determines which features are active regardless of individual flags

**Configuration Modes**:

**Simple Mode** (boolean flags):
```dart
InteractionConfig(
  enableCrosshair: true,
  enableTooltip: true,
  enableZoom: false,
  enablePan: false,
  onDataPointTap: (point, position) => print('Tapped: $point'),
);
```

**Advanced Mode** (detailed sub-configs):
```dart
InteractionConfig(
  crosshair: CrosshairConfig(
    mode: CrosshairMode.both,
    snapToPoint: true,
    snapRadius: 20.0,
  ),
  tooltip: TooltipConfig(
    triggerMode: TooltipTriggerMode.hover,
    customBuilder: (context, point) => CustomTooltip(point),
  ),
  zoomPan: ZoomPanConfig(
    allowZoom: true,
    allowPan: true,
    minZoom: 0.5,
    maxZoom: 10.0,
  ),
  keyboard: KeyboardConfig(
    enableNavigation: true,
    enableZoomShortcuts: true,
  ),
  onZoomChanged: (x, y) => print('Zoom: $x, $y'),
);
```

**Factory Constructors**:
```dart
// Enable all interaction features
InteractionConfig.all()

// Disable all interaction features
InteractionConfig.none()
```

**Default Values**:
```dart
InteractionConfig._({
  this.crosshair,
  this.tooltip,
  this.zoomPan,
  this.keyboard,
  this.enableCrosshair = false,
  this.enableTooltip = false,
  this.enableZoom = false,
  this.enablePan = false,
  this.onDataPointTap,
  this.onDataPointDoubleTap,
  this.onSelectionChanged,
  this.onZoomChanged,
  this.onPanChanged,
  this.onCrosshairChanged,
  this.onTooltipChanged,
  this.onKeyboardAction,
  this.mode = InteractionMode.explore,
  this.onModeChanged,
});
```

**Effective Configuration Getters**:
```dart
// Returns actual crosshair config, merging simple/advanced modes
CrosshairConfig get effectiveCrosshairConfig {
  if (crosshair != null) return crosshair!;
  return enableCrosshair 
    ? CrosshairConfig.defaultConfig() 
    : CrosshairConfig(mode: CrosshairMode.none);
}

// Similar getters for tooltip, zoomPan, keyboard
```

---

## Entity Relationships Diagram

```
InteractionConfig (main wrapper)
├── Contains: CrosshairConfig? (optional)
├── Contains: TooltipConfig? (optional)
├── Contains: ZoomPanConfig? (optional)
├── Contains: KeyboardConfig? (optional)
├── Provides: 8 callback functions
└── Used by: InteractiveChart widget

InteractionState (central state)
├── Contains: ZoomPanState (viewport)
├── References: ChartDataPoint* (hovered, focused, selected, tooltip)
└── Contains: GestureDetails? (active gesture)

CrosshairConfig ───used by──→ CrosshairRenderer
TooltipConfig ───used by──→ TooltipProvider
InteractionConfig ───configures──→ All interaction components

Developer
├── Provides: InteractionConfig (main entry point)
├── Provides: CrosshairConfig (optional advanced)
├── Provides: TooltipConfig (optional advanced)
└── Observes: InteractionState (via callbacks)
```

---

## Data Flow

### 1. User Interaction → State Update
```
User Action (mouse move, tap, key press)
  ↓
PointerEvent / RawKeyEvent
  ↓
Event Handler (processEvent)
  ↓
InteractionState update
  ↓
UI Rebuild (via ValueNotifier listener)
```

### 2. State → Rendering
```
InteractionState updated
  ↓
ValueListenableBuilder rebuilds
  ↓
CustomPainter.shouldRepaint returns true
  ↓
CrosshairPainter.paint (if crosshair visible)
  ↓
TooltipWidget.build (if tooltip visible)
```

### 3. Zoom/Pan State Update
```
Zoom/Pan Gesture
  ↓
ZoomPanState update
  ↓
visibleDataBounds recalculated
  ↓
Rendering system culls invisible points
  ↓
Chart redraws with visible data only
```

---

## Serialization / Persistence

### Not Persisted (Session-Only State)
- `InteractionState` - Resets on widget rebuild
- `GestureDetails` - Short-lived (duration of gesture)

### Potentially Persisted (Optional)
- `ZoomPanState` - Could save/restore zoom level and pan position

```dart
// Example: Save zoom/pan state to SharedPreferences
void saveZoomPanState(ZoomPanState state) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setDouble('zoomLevelX', state.zoomLevelX);
  await prefs.setDouble('zoomLevelY', state.zoomLevelY);
  await prefs.setDouble('panOffsetDx', state.panOffset.dx);
  await prefs.setDouble('panOffsetDy', state.panOffset.dy);
}

// Restore zoom/pan state
ZoomPanState loadZoomPanState(Rect dataBounds) async {
  final prefs = await SharedPreferences.getInstance();
  return ZoomPanState(
    zoomLevelX: prefs.getDouble('zoomLevelX') ?? 1.0,
    zoomLevelY: prefs.getDouble('zoomLevelY') ?? 1.0,
    panOffset: Offset(
      prefs.getDouble('panOffsetDx') ?? 0,
      prefs.getDouble('panOffsetDy') ?? 0,
    ),
    originalDataBounds: dataBounds,
    // ... other fields
  );
}
```

---

## Performance Considerations

### Memory Footprint
| Entity | Size (bytes) | Notes |
|--------|--------------|-------|
| InteractionState | ~200 | Contains references, not copies |
| ZoomPanState | ~96 | Doubles and Rect (8 doubles) |
| GestureDetails | ~120 | Includes timestamps and positions |
| CrosshairConfig | ~80 | Small config object |
| TooltipConfig | ~120 | Includes style and builder function reference |
| **Total** | **~616 bytes** | Per chart instance |

With 10 chart instances: ~6KB (well within <5MB budget)

### Allocation Rate
- **InteractionState updates**: 60/sec during active interaction
- **GestureDetails creation**: 1-5/sec during gesture
- **Total allocations**: ~60-120 objects/sec (acceptable)

### Object Pooling (Future Optimization)
If allocation becomes a bottleneck:
```dart
class InteractionStatePool {
  final Queue<InteractionState> _pool = Queue();
  
  InteractionState acquire() {
    return _pool.isEmpty ? InteractionState.initial() : _pool.removeFirst();
  }
  
  void release(InteractionState state) {
    _pool.add(state);
  }
}
```

---

## Conclusion

Six entities model all interaction state and configuration:

1. ✅ **InteractionState** - Central reactive state
2. ✅ **ZoomPanState** - Viewport zoom/pan tracking
3. ✅ **GestureDetails** - Gesture information
4. ✅ **CrosshairConfig** - Crosshair customization
5. ✅ **TooltipConfig** - Tooltip customization
6. ✅ **InteractionConfig** - Main wrapper configuration (added 2025-01-07)

All entities follow immutable data patterns (copyWith), validated constraints, and minimal memory footprint. Ready for contract generation (Phase 1).

**Status**: ✅ Data Model Complete (Updated 2025-01-07 - Added InteractionConfig)
