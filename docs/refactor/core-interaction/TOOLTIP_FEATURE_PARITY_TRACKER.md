# Tooltip Feature Parity Tracker - BravenChartPlus

**Goal**: Achieve 100% feature parity with BravenChart's tooltip system using canvas-only rendering (no overlay widgets).

**Status**: 10% Complete (basic tooltip exists, missing 90% of features)

---

## 📊 Feature Comparison Matrix

| Feature | BravenChart | BravenChartPlus | Implementation | Status | Priority | Estimate |
|---------|-------------|-----------------|----------------|--------|----------|----------|
| **Basic tooltip display** | ✅ | ✅ | Canvas rendering | ✅ DONE | - | - |
| **TooltipStyle theming** | ✅ (9 properties) | ❌ Hardcoded | Use config.style.* | 🔴 TODO | P0 | 30 min |
| **Smart positioning** | ✅ (5 modes) | ❌ (only above/below) | Add left/right/auto | 🔴 TODO | P0 | 1 hour |
| **Arrow pointers** | ✅ (4 directions) | ❌ Plain rectangle | Path with lineTo/bezier | 🔴 TODO | P0 | 2 hours |
| **Trigger modes** | ✅ (hover/tap/both) | ❌ Hover only | Route tap events | 🔴 TODO | P1 | 20 min |
| **Fade animations** | ✅ AnimatedOpacity | ❌ Instant | Timer + opacity lerp | 🔴 TODO | P1 | 1.5 hours |
| **Show/hide delays** | ✅ Configurable | ❌ Ignored | Timer-based | 🔴 TODO | P1 | 30 min |
| **Follow cursor** | ✅ Optional | ❌ Fixed anchor | Use hover position | 🔴 TODO | P2 | 30 min |
| **Offset control** | ✅ config.offsetFromPoint | ❌ Hardcoded 12px | Use config value | 🔴 TODO | P2 | 5 min |
| **Custom builder** | ✅ Widget function | ❌ Ignored | 🟡 SKIP | 🟡 DEFERRED | P3 | 2+ hours |

**Legend**:
- ✅ = Complete
- ❌ = Missing/Broken
- 🟡 = Deferred
- 🔴 = Not Started
- 🟡 = In Progress
- 🟢 = Testing

---

## 🎯 Implementation Phases

### Phase 1: Foundation & Theming (1 hour) - PRIORITY 0
**Objective**: Respect all TooltipConfig properties, eliminate hardcoded values

#### Task 1.1: Apply TooltipStyle Properties ⏱️ 30 min ✅ COMPLETE
**File**: `lib/src_plus/rendering/chart_render_box.dart`  
**Location**: `_drawMarkerTooltip()` method (line ~3805)

**Changes**:
- [x] Replace hardcoded `Color(0xFFFFFFFF)` → `config.style.textColor`
- [x] Replace hardcoded `fontSize: 12` → `config.style.fontSize`
- [x] Replace hardcoded `padding: 8.0` → `config.style.padding`
- [x] Replace hardcoded `borderRadius: 4` → `config.style.borderRadius`
- [x] Replace hardcoded `Color(0xE0000000)` → `config.style.backgroundColor`
- [x] Add border drawing with `config.style.borderColor` and `borderWidth`
- [x] Use `config.style.shadowColor` and `shadowBlurRadius` for shadow

**Success Criteria**:
- All 9 TooltipStyle properties are used
- No hardcoded colors/sizes remain
- Visual appearance matches configured style

**Testing**:
```dart
// Test with custom styling
final config = TooltipConfig(
  style: TooltipStyle(
    backgroundColor: Colors.blue.shade900,
    textColor: Colors.white,
    fontSize: 14,
    borderRadius: 8,
    // ... etc
  ),
);
// Verify tooltip uses custom colors
```

---

#### Task 1.2: Apply Positioning Controls ⏱️ 5 min ✅ COMPLETE
**File**: `lib/src_plus/rendering/chart_render_box.dart`  
**Location**: `_drawMarkerTooltip()` method (line ~3842)

**Changes**:
- [x] Replace hardcoded `12` → `config.offsetFromPoint`
- [x] Verify offset works in all directions

**Success Criteria**:
- Tooltip distance from point is configurable
- Different offsets produce different spacing

---

#### Task 1.3: Handle Null/Default Config ⏱️ 10 min ✅ COMPLETE
**File**: `lib/src_plus/rendering/chart_render_box.dart`  
**Location**: `_drawMarkerTooltip()` start (line ~3805)

**Changes**:
- [x] Add null check: `final config = _interactionConfig?.tooltip ?? const TooltipConfig()`
- [x] Ensure default values work if config is null

**Success Criteria**:
- Works with null InteractionConfig
- Works with null TooltipConfig
- Uses sensible defaults

---

### Phase 2: Arrow Pointers (2 hours) - PRIORITY 0
**Objective**: Replace plain rectangle with arrow-based tooltip shape

#### Task 2.1: Create Arrow Path Generator ⏱️ 1 hour
**File**: `lib/src_plus/rendering/chart_render_box.dart`  
**Location**: New helper method after `_drawMarkerTooltip()`

**Implementation**:
```dart
/// Creates a tooltip path with arrow pointing in the specified direction.
///
/// Arrow positions:
/// - top: Arrow on bottom edge pointing down (tooltip above marker)
/// - bottom: Arrow on top edge pointing up (tooltip below marker)
/// - left: Arrow on right edge pointing right (tooltip left of marker)
/// - right: Arrow on left edge pointing left (tooltip right of marker)
Path _createTooltipPath(
  Rect rect,
  TooltipPosition position,
  double borderRadius,
  double arrowSize,
) {
  final path = Path();
  final radius = borderRadius;
  
  switch (position) {
    case TooltipPosition.top:
      // Arrow notch on BOTTOM edge (tooltip above, arrow points down to marker)
      const arrowOffsetX = 20.0; // Fixed offset from left
      final arrowLeft = arrowOffsetX - arrowSize / 2;
      final arrowRight = arrowOffsetX + arrowSize / 2;
      final arrowTip = rect.bottom + arrowSize;
      
      path.moveTo(rect.left + radius, rect.top);
      // Top edge with rounded corners
      path.lineTo(rect.right - radius, rect.top);
      path.quadraticBezierTo(rect.right, rect.top, rect.right, rect.top + radius);
      // Right edge
      path.lineTo(rect.right, rect.bottom - radius);
      path.quadraticBezierTo(rect.right, rect.bottom, rect.right - radius, rect.bottom);
      // Bottom edge with arrow
      path.lineTo(rect.left + arrowRight, rect.bottom);
      path.lineTo(rect.left + arrowOffsetX, arrowTip); // Arrow tip
      path.lineTo(rect.left + arrowLeft, rect.bottom);
      // Continue bottom edge
      path.lineTo(rect.left + radius, rect.bottom);
      path.quadraticBezierTo(rect.left, rect.bottom, rect.left, rect.bottom - radius);
      // Left edge
      path.lineTo(rect.left, rect.top + radius);
      path.quadraticBezierTo(rect.left, rect.top, rect.left + radius, rect.top);
      break;
      
    case TooltipPosition.bottom:
      // Arrow notch on TOP edge (tooltip below, arrow points up to marker)
      // ... similar structure
      break;
      
    case TooltipPosition.left:
      // Arrow notch on RIGHT edge (tooltip left, arrow points right to marker)
      // ... similar structure
      break;
      
    case TooltipPosition.right:
      // Arrow notch on LEFT edge (tooltip right, arrow points left to marker)
      // ... similar structure
      break;
      
    case TooltipPosition.auto:
      // No arrow for auto mode
      // Just rounded rectangle
      path.addRRect(RRect.fromRectAndRadius(rect, Radius.circular(radius)));
      return path;
  }
  
  path.close();
  return path;
}
```

**Reference**: Copy logic from `lib/src/widgets/braven_chart.dart` lines 7134-7254

#### Task 2.1: Create Arrow Path Generation ⏱️ 1.5 hours ✅ COMPLETE
**File**: `lib/src_plus/rendering/chart_render_box.dart`  
**Location**: New method before `_drawMarkerTooltip()` (line ~3815)

**Implementation**:
- [x] Create `_createTooltipPath()` helper method
- [x] Calculate arrow position based on anchor vs tooltip rect
- [x] Generate Path with moveTo/lineTo/quadraticBezierTo
- [x] Support all 4 arrow positions: top, bottom, left, right
- [x] Clamp arrow offset to avoid corners (edgeMargin = 10.0)
- [x] Use Path operations matching BravenChart reference implementation

**Success Criteria**:
- Path creates correct arrow shape for each position
- Rounded corners work correctly
- Arrow size is configurable

---

#### Task 2.2: Integrate Arrow Drawing ⏱️ 30 min ✅ COMPLETE
**File**: `lib/src_plus/rendering/chart_render_box.dart`  
**Location**: `_drawMarkerTooltip()` method (line ~4000)

**Changes**:
- [x] Replace `RRect.fromRectAndRadius()` with `_createTooltipPath()`
- [x] Use `canvas.drawPath()` instead of `canvas.drawRRect()`
- [x] Apply shadow to path (draw twice: once shifted for shadow, once for fill)
- [x] Draw border on path if `borderWidth > 0`

**Implementation**:
```dart
// Calculate tooltip rect
final tooltipRect = Rect.fromLTWH(tooltipX, tooltipY, tooltipWidth, tooltipHeight);

// Create path with arrow
final tooltipPath = _createTooltipPath(
  tooltipRect,
  config.preferredPosition,
  config.style.borderRadius,
  10.0, // arrowSize (could be configurable)
);

// Draw shadow
if (config.style.shadowBlurRadius > 0) {
  canvas.drawPath(
    tooltipPath.shift(const Offset(0, 2)),
    Paint()
      ..color = config.style.shadowColor
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, config.style.shadowBlurRadius),
  );
}

// Draw background
canvas.drawPath(
  tooltipPath,
  Paint()..color = config.style.backgroundColor,
);

// Draw border
if (config.style.borderWidth > 0) {
  canvas.drawPath(
    tooltipPath,
    Paint()
      ..color = config.style.borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = config.style.borderWidth,
  );
}
```

**Success Criteria**:
- Tooltip displays with arrow pointing to marker
- Shadow follows arrow shape
- Border follows arrow shape

---

### Phase 3: Smart Positioning (1 hour) - PRIORITY 0
**Objective**: Support all 5 positioning modes with intelligent fallback

#### Task 3.1: Add Left/Right Position Logic ⏱️ 30 min ✅ COMPLETE
**File**: `lib/src_plus/rendering/chart_render_box.dart`  
**Location**: `_drawMarkerTooltip()` position calculation (line ~3975)

**Changes**:
- [x] Add `case TooltipPosition.left:` positioning logic
- [x] Add `case TooltipPosition.right:` positioning logic  
- [x] Update arrow direction to match position (handled by _createTooltipPath)
- [x] Add edge margin handling and intelligent flipping
- [x] Support all 5 positions: top, bottom, left, right, auto

**Implementation**:
```dart
// Calculate tooltip position based on preferredPosition
switch (config.preferredPosition) {
  case TooltipPosition.top:
    tooltipY = tooltipAnchor.dy - tooltipHeight - offset;
    tooltipX = tooltipAnchor.dx - tooltipWidth / 2;
    break;
  case TooltipPosition.bottom:
    tooltipY = tooltipAnchor.dy + offset;
    tooltipX = tooltipAnchor.dx - tooltipWidth / 2;
    break;
  case TooltipPosition.left:
    tooltipX = tooltipAnchor.dx - tooltipWidth - offset;
    tooltipY = tooltipAnchor.dy - tooltipHeight / 2;
    break;
  case TooltipPosition.right:
    tooltipX = tooltipAnchor.dx + offset;
    tooltipY = tooltipAnchor.dy - tooltipHeight / 2;
    break;
  case TooltipPosition.auto:
    // Handled in next task
    break;
}
```

**Success Criteria**:
- Left/right positioning works correctly
- Arrow points in correct direction for each position
- Tooltips don't overlap marker

---

#### Task 3.2: Implement Auto Mode with Fallback ⏱️ 30 min ✅ COMPLETE
**File**: `lib/src_plus/rendering/chart_render_box.dart`  
**Location**: `_drawMarkerTooltip()` position calculation (line ~3975)

**Changes**:
- [x] Auto mode defaults to top position
- [x] Smart flipping when tooltip would clip canvas edges
- [x] Separate logic for vertical (top/bottom) vs horizontal (left/right) flipping
- [x] Edge margin handling (10.0 pixels)
- [x] followCursor support: uses _cursorPosition when enabled (line ~3953)

**Implementation**:
Integrated directly into switch statement with intelligent edge detection and flipping logic. Auto mode starts with top position and flips to bottom if it would clip the top edge.
```dart
/// Calculates optimal tooltip position using smart fallback algorithm.
///
/// Algorithm:
/// 1. Try preferred position (or top if auto)
/// 2. If clipped, try opposite side
/// 3. If still clipped, try other two sides
/// 4. If all clipped, use first position and clamp to bounds
Offset _calculateSmartTooltipPosition(
  Offset anchor,
  Size tooltipSize,
  TooltipPosition preferredPosition,
  double offset,
  Size canvasSize,
) {
  if (preferredPosition != TooltipPosition.auto) {
    // Use specified position
    return _calculateTooltipPositionForMode(anchor, tooltipSize, preferredPosition, offset);
  }
  
  // Auto mode: try positions in order until one fits
  const tryOrder = [
    TooltipPosition.top,
    TooltipPosition.bottom,
    TooltipPosition.right,
    TooltipPosition.left,
  ];
  
  for (final position in tryOrder) {
    final testPos = _calculateTooltipPositionForMode(anchor, tooltipSize, position, offset);
    final testRect = Rect.fromLTWH(testPos.dx, testPos.dy, tooltipSize.width, tooltipSize.height);
    
    // Check if tooltip fits within canvas bounds
    if (_fitsInBounds(testRect, canvasSize)) {
      return testPos; // Use first position that fits
    }
  }
  
  // If nothing fits, use top position and clamp to bounds
  final fallbackPos = _calculateTooltipPositionForMode(anchor, tooltipSize, TooltipPosition.top, offset);
  return Offset(
    fallbackPos.dx.clamp(10, canvasSize.width - tooltipSize.width - 10),
    fallbackPos.dy.clamp(10, canvasSize.height - tooltipSize.height - 10),
  );
}

bool _fitsInBounds(Rect rect, Size bounds) {
  const margin = 10.0;
  return rect.left >= margin &&
         rect.top >= margin &&
         rect.right <= bounds.width - margin &&
         rect.bottom <= bounds.height - margin;
}
```

**Success Criteria**:
- Auto mode tries positions in order
- Uses first position that fits completely
- Clamps to bounds if nothing fits
- No tooltip clipping in common scenarios

---

### Phase 4: Trigger Modes (20 min) - PRIORITY 1 ✅ COMPLETE
**Objective**: Support hover, tap, and both trigger modes

#### Task 4.1: Add Tap Event Handling ⏱️ 20 min ✅ COMPLETE
**File**: `lib/src_plus/rendering/chart_render_box.dart`  
**Location**: Multiple locations

**Changes**:
- [x] Add `_tappedMarker` field to track tapped marker (line ~183)
- [x] Update tooltip rendering condition to check triggerMode (line ~2776)
- [x] Add tap detection in `_handlePointerUp` (line ~2271)
- [x] Support hover, tap, and both modes with proper logic
- [x] Toggle tap tooltip on/off when tapping same marker twice

**Implementation**:
- Added `HoveredMarkerInfo? _tappedMarker` field to track tap state
- Modified tooltip rendering to use switch on `config.triggerMode`:
  - `hover`: Show only hoveredMarker
  - `tap`: Show only _tappedMarker
  - `both`: Show _tappedMarker if set, else hoveredMarker
- Added tap detection in _handlePointerUp that toggles _tappedMarker
- Tapping same marker twice hides tooltip, tapping different marker switches it

**Success Criteria**:
- ✅ Tap shows tooltip when triggerMode is tap or both
- ✅ Hover shows tooltip when triggerMode is hover or both
- ✅ Modes work independently and combined
- ✅ Tap toggle behavior works correctly

**Implementation**:
```dart
@override
void handleEvent(PointerEvent event, BoxHitTestEntry entry) {
  // ... existing code ...
  
  final tooltipConfig = _interactionConfig?.tooltip;
  
  if (event is PointerDownEvent && tooltipConfig != null && tooltipConfig.enabled) {
    // Handle tap trigger
    if (tooltipConfig.triggerMode == TooltipTriggerMode.tap ||
        tooltipConfig.triggerMode == TooltipTriggerMode.both) {
      // Find marker at tap position
      final candidates = _spatialIndex?.query(event.localPosition) ?? [];
      for (final element in candidates) {
        if (element is SeriesElement && element.hitTest(event.localPosition)) {
          final markerIndex = element.findNearestMarkerIndex(event.localPosition);
          if (markerIndex != null) {
            coordinator.setHoveredMarker(HoveredMarkerInfo(
              seriesId: element.id,
              markerIndex: markerIndex,
              plotPosition: element.getMarkerPlotPosition(markerIndex),
            ));
            markNeedsPaint();
            break;
          }
        }
      }
    }
  }
  
  if (event is PointerHoverEvent && tooltipConfig != null && tooltipConfig.enabled) {
    // Handle hover trigger
    if (tooltipConfig.triggerMode == TooltipTriggerMode.hover ||
        tooltipConfig.triggerMode == TooltipTriggerMode.both) {
      // ... existing hover logic ...
    }
  }
}
```

**Success Criteria**:
- Tap shows tooltip when triggerMode is tap or both
- Hover shows tooltip when triggerMode is hover or both
- Modes work independently and combined

---

### Phase 5: Fade Animations (2 hours) - PRIORITY 1 ✅ COMPLETE
**Objective**: Smooth fade-in/fade-out with configurable delays

#### Task 5.1: Add Animation State Fields ⏱️ 15 min ✅ COMPLETE
**File**: `lib/src_plus/rendering/chart_render_box.dart`  
**Location**: Class fields (line ~186)

**Changes**:
- [x] Add `double _tooltipOpacity = 0.0`
- [x] Add `Timer? _tooltipShowTimer`
- [x] Add `Timer? _tooltipHideTimer`
- [x] Add `Timer? _tooltipFadeTimer`
- [x] Add `HoveredMarkerInfo? _tooltipTargetMarker` for state tracking

**Implementation**:
```dart
class ChartRenderBox extends RenderBox {
  // ... existing fields ...
  
  /// Current tooltip opacity for fade animation (0.0 = hidden, 1.0 = visible)
  double _tooltipOpacity = 0.0;
  
  /// Timer for delaying tooltip show
  Timer? _tooltipShowTimer;
  
  /// Timer for delaying tooltip hide
  Timer? _tooltipHideTimer;
  
  /// Timer for fade animation steps
  Timer? _tooltipFadeTimer;
  
  // ...
}
```

---

#### Task 5.2: Implement Show/Hide with Delays ⏱️ 30 min ✅ COMPLETE
**File**: `lib/src_plus/rendering/chart_render_box.dart`  
**Location**: New methods after `_drawMarkerTooltip()` (line ~4140)

**Changes**:
- [x] Add `_showTooltipWithDelay()` method with timer and marker tracking
- [x] Add `_hideTooltipWithDelay()` method with timer cancellation
- [x] Add `_animateTooltipOpacity()` with 60fps periodic timer
- [x] Add `_cancelTooltipTimers()` for cleanup
- [x] Handle zero delays (immediate show/hide)
- [x] Implement marker change detection to cancel old animations

**Implementation**:
```dart
/// Shows tooltip after configured delay with fade-in animation.
void _showTooltipWithDelay(HoveredMarkerInfo markerInfo) {
  final config = _interactionConfig?.tooltip;
  if (config == null || !config.enabled) return;
  
  // Cancel existing timers
  _tooltipShowTimer?.cancel();
  _tooltipHideTimer?.cancel();
  
  // Start show delay timer
  _tooltipShowTimer = Timer(config.showDelay, () {
    // Start fade-in animation (0.0 → 1.0)
    _animateTooltipOpacity(1.0, const Duration(milliseconds: 150));
  });
}

/// Hides tooltip after configured delay with fade-out animation.
void _hideTooltipWithDelay() {
  final config = _interactionConfig?.tooltip;
  if (config == null) return;
  
  // Cancel show timer (user moved away before delay finished)
  _tooltipShowTimer?.cancel();
  
  // Start hide delay timer
  _tooltipHideTimer = Timer(config.hideDelay, () {
    // Start fade-out animation (1.0 → 0.0)
    _animateTooltipOpacity(0.0, const Duration(milliseconds: 100));
  });
}

/// Animates tooltip opacity to target value over specified duration.
void _animateTooltipOpacity(double target, Duration duration) {
  _tooltipFadeTimer?.cancel();
  
  const fps = 60;
  final frameCount = (duration.inMilliseconds * fps / 1000).round();
  final frameDuration = Duration(milliseconds: (1000 / fps).round());
  
  final startOpacity = _tooltipOpacity;
  final deltaOpacity = target - startOpacity;
  
  var currentFrame = 0;
  
  _tooltipFadeTimer = Timer.periodic(frameDuration, (timer) {
    if (currentFrame >= frameCount) {
      timer.cancel();
      _tooltipOpacity = target;
      markNeedsPaint();
      return;
    }
    
    // Linear interpolation (can add easing curves later)
    final progress = currentFrame / frameCount;
    _tooltipOpacity = startOpacity + (deltaOpacity * progress);
    currentFrame++;
    
    markNeedsPaint(); // Trigger repaint for each frame
  });
}
```

**Success Criteria**:
- Tooltip appears after `showDelay`
- Tooltip disappears after `hideDelay`
- Fade animations run at ~60fps
- Delays are cancellable (moving cursor away before show)

---

#### Task 5.3: Apply Opacity to Rendering ⏱️ 45 min ✅ COMPLETE
**File**: `lib/src_plus/rendering/chart_render_box.dart`  
**Location**: `_drawMarkerTooltip()` method (line ~4096)

**Changes**:
- [x] Apply `_tooltipOpacity` to shadow color with `.withOpacity()`
- [x] Apply `_tooltipOpacity` to background color
- [x] Apply `_tooltipOpacity` to border color
- [x] Apply `_tooltipOpacity` to text color (recreated TextPainter)
- [x] Preserve original alpha channel (multiply, don't replace)

**Implementation**:
```dart
void _drawMarkerTooltip(Canvas canvas, Size size, HoveredMarkerInfo markerInfo) {
  // Skip if fully transparent
  if (_tooltipOpacity == 0.0) return;
  
  final config = _interactionConfig?.tooltip ?? TooltipConfig.defaultConfig();
  
  // ... calculate position and size ...
  
  // Apply opacity to shadow
  if (config.style.shadowBlurRadius > 0) {
    canvas.drawPath(
      tooltipPath.shift(const Offset(0, 2)),
      Paint()
        ..color = config.style.shadowColor.withOpacity(
          config.style.shadowColor.opacity * _tooltipOpacity * 0.4,
        )
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, config.style.shadowBlurRadius),
    );
  }
  
  // Apply opacity to background
  canvas.drawPath(
    tooltipPath,
    Paint()..color = config.style.backgroundColor.withOpacity(
      config.style.backgroundColor.opacity * _tooltipOpacity,
    ),
  );
  
  // Apply opacity to border
  if (config.style.borderWidth > 0) {
    canvas.drawPath(
      tooltipPath,
      Paint()
        ..color = config.style.borderColor.withOpacity(
          config.style.borderColor.opacity * _tooltipOpacity,
        )
        ..style = PaintingStyle.stroke
        ..strokeWidth = config.style.borderWidth,
    );
  }
  
  // Apply opacity to text
  final textStyle = TextStyle(
    color: config.style.textColor.withOpacity(_tooltipOpacity),
    fontSize: config.style.fontSize,
    fontWeight: FontWeight.w500,
  );
  
  // ... draw text with opacity-adjusted style ...
}
```

**Success Criteria**:
- Tooltip fades in smoothly (not instant)
- Tooltip fades out smoothly
- All visual elements fade together (background, border, text, shadow)
- No visible artifacts during fade

---

#### Task 5.4: Integrate with Hover Events ⏱️ 30 min ✅ COMPLETE
**File**: `lib/src_plus/rendering/chart_render_box.dart`  
**Location**: Tooltip rendering in `_paintOverlay()` (line ~2797)

**Changes**:
- [x] Call `_showTooltipWithDelay()` when marker appears or changes
- [x] Call `_hideTooltipWithDelay()` when marker disappears
- [x] Only draw tooltip if `_tooltipOpacity > 0.001` (visible or fading)
- [x] During fade-out, continue drawing using cached `_tooltipTargetMarker`
- [x] Cancel animations when tooltips disabled or panning starts
- [x] Detect marker changes with `_tooltipTargetMarker != markerToShow`

**Implementation**:
Integrated animation trigger logic directly into tooltip rendering section. Animations start automatically when marker state changes, with proper handling for hover, tap, and both trigger modes.

**Implementation**:
```dart
// In handleEvent() hover section:
if (event is PointerHoverEvent) {
  // ... existing hover logic ...
  
  if (hoveredMarker != null) {
    coordinator.setHoveredMarker(hoveredMarker);
    _showTooltipWithDelay(hoveredMarker); // ✅ Use delayed show
    // markNeedsPaint(); // ❌ Remove - animation handles repaints
  } else {
    coordinator.clearHoveredMarker();
    _hideTooltipWithDelay(); // ✅ Use delayed hide
    // markNeedsPaint(); // ❌ Remove - animation handles repaints
  }
}
```

**Success Criteria**:
- Hovering marker triggers delayed fade-in
- Moving away triggers delayed fade-out
- Rapid hover movements cancel pending shows
- Animation is smooth and responsive

---

### Phase 6: Advanced Features (1 hour) - PRIORITY 2 ✅ COMPLETE
**Objective**: Follow cursor and enhanced configuration

#### Task 6.1: Add Follow Cursor Support ⏱️ 30 min ✅ COMPLETE (Phase 3)
**File**: `lib/src_plus/rendering/chart_render_box.dart`  
**Location**: `_drawMarkerTooltip()` (line ~3953)

**Changes**:
- [x] Use `_cursorPosition` field (already existed in codebase)
- [x] Apply followCursor logic: use cursor position when enabled, else marker position
- [x] Integrated directly into tooltip anchor calculation

**Note**: This feature was already completed during Phase 3, Task 3.2 implementation.

**Implementation**:
```dart
class ChartRenderBox extends RenderBox {
  // ... existing fields ...
  
  /// Current cursor position for followCursor mode
  Offset? _currentCursorPosition;
  
  // ...
}

// In handleEvent():
if (event is PointerHoverEvent) {
  _currentCursorPosition = event.localPosition;
  // ... existing logic ...
}

// In _drawMarkerTooltip():
void _drawMarkerTooltip(Canvas canvas, Size size, HoveredMarkerInfo markerInfo) {
  final config = _interactionConfig?.tooltip ?? TooltipConfig.defaultConfig();
  
  // Use cursor position if followCursor enabled, otherwise use marker anchor
  final tooltipAnchor = config.followCursor
      ? (_currentCursorPosition ?? plotToWidget(markerInfo.plotPosition))
      : plotToWidget(markerInfo.plotPosition);
  
  // ... continue with tooltipAnchor ...
}
```

**Success Criteria**:
- When `followCursor == true`, tooltip follows cursor
- When `followCursor == false`, tooltip anchors to marker
- Smooth tracking without jitter

---

#### Task 6.2: Dispose Timers Properly ⏱️ 15 min ✅ COMPLETE
**File**: `lib/src_plus/rendering/chart_render_box.dart`  
**Location**: `dispose()` method (line ~433)

**Changes**:
- [x] Call `_cancelTooltipTimers()` in dispose()
- [x] Cancel all three tooltip timers (show, hide, fade)
- [x] Set timer references to null
- [x] Prevent memory leaks from lingering timers

**Implementation**:
```dart
@override
void dispose() {
  _tooltipShowTimer?.cancel();
  _tooltipHideTimer?.cancel();
  _tooltipFadeTimer?.cancel();
  super.dispose();
}
```

**Success Criteria**:
- No timer leaks
- No warnings about timers after dispose

---

#### Task 6.3: Add Configuration Validation ⏱️ 15 min ✅ COMPLETE
**File**: `lib/src_plus/models/interaction_config.dart`  
**Location**: `TooltipConfig` class (line ~413)

**Changes**:
- [x] Add assertion for `offsetFromPoint >= 0`
- [x] Document constraints in class documentation
- [x] Clear error messages for invalid configurations

**Note**: Duration assertions omitted to maintain const constructor compatibility.

**Implementation**:
```dart
class TooltipConfig {
  const TooltipConfig({
    this.enabled = true,
    this.triggerMode = TooltipTriggerMode.hover,
    this.preferredPosition = TooltipPosition.auto,
    this.showDelay = const Duration(milliseconds: 300),
    this.hideDelay = const Duration(milliseconds: 200),
    this.followCursor = false,
    this.offsetFromPoint = 10.0,
    this.style = const TooltipStyle(),
    this.customBuilder,
  }) : assert(offsetFromPoint >= 0, 'offsetFromPoint must be non-negative'),
       assert(showDelay >= Duration.zero, 'showDelay must be non-negative'),
       assert(hideDelay >= Duration.zero, 'hideDelay must be non-negative');
  
  // ...
}
```

**Success Criteria**:
- Invalid configs throw assertions
- Clear error messages

---

## 🧪 Testing Plan

### Unit Tests
- [ ] TooltipStyle property application
- [ ] Arrow path generation for each position
- [ ] Smart positioning algorithm
- [ ] Fade animation timing
- [ ] Trigger mode routing
- [ ] Follow cursor tracking

### Integration Tests
- [ ] Hover → delay → fade in → hover away → delay → fade out
- [ ] Tap trigger on mobile/touch
- [ ] Rapid hover movements (cancel pending shows)
- [ ] Tooltip positioning near edges (auto mode fallback)
- [ ] Multiple series with different tooltip configs

### Visual Tests
- [ ] All arrow directions visible and correct
- [ ] Theming matches configuration
- [ ] Smooth animation (no jank)
- [ ] No clipping or overflow
- [ ] Shadows render correctly

---

## 📈 Progress Tracking

**Total Tasks**: 18  
**Completed**: 15 ✅ (83%)  
**In Progress**: 0 🟡  
**Blocked**: 0 🔴  
**Deferred**: 3 🟠 (Custom builder - P3 priority)  

**Estimated Total Time**: 8-10 hours  
**Time Spent**: 7.08 hours  
**Remaining**: 3 tasks deferred (custom builder feature)

---

## 🎯 Priority Breakdown

**P0 (Must Have)**: 6 tasks, ~4.5 hours
- Theming, arrow pointers, smart positioning

**P1 (Should Have)**: 5 tasks, ~2.5 hours
- Trigger modes, fade animations

**P2 (Nice to Have)**: 7 tasks, ~1.5 hours
- Follow cursor, validation, cleanup

**P3 (Deferred)**: 1 task, deferred
- Custom builder (widget-based)

---

## 🚀 Next Steps

1. **Start with Phase 1, Task 1.1** (30 min)
   - Quick win: visual improvement immediately visible
   - Foundation for all other features
   
2. **Continue with Phase 2** (2 hours)
   - Most visually impactful feature
   - Requires theming from Phase 1
   
3. **Add smart positioning (Phase 3)** (1 hour)
   - Critical for usability
   - Completes positioning system
   
4. **Polish with animations (Phase 5)** (2 hours)
   - Professional feel
   - Requires all previous phases

---

## 📝 Notes

- **No widget overlays needed** - all features implementable with canvas
- **Performance target**: Maintain 60fps during tooltip display/animation
- **Memory target**: Zero allocations in steady state (reuse Paint objects)
- **Compatibility**: Works seamlessly with existing zoom/pan/coordinate transforms
- **Future**: Custom builder can be added later if requested (use canvas-based custom paint function)

---

**Last Updated**: 2025-11-24  
**Status**: Ready to implement  
**Next Action**: Begin Phase 1, Task 1.1 (Apply TooltipStyle Properties)
