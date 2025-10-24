# Phase 0: Research & Technical Decisions

**Feature**: Dual-Purpose Scrollbars for Chart Navigation  
**Date**: 2025-01-20  
**Status**: COMPLETE

## Research Questions Resolved

### 1. State Management Pattern for High-Frequency Pointer Events

**Decision**: Use ValueNotifier<ScrollbarState> + ValueListenableBuilder pattern for scrollbar drag state

**Rationale**:
- **Constitutional Requirement**: Constitution v1.1.0 Performance First principle MANDATES ValueNotifier for >10Hz updates
- **Crash Prevention**: setState during pointer events causes box.dart:3345 and mouse_tracker.dart:199 assertion failures
- **Performance**: Scrollbar drag generates 100+ pointer events per second (well above 10Hz threshold)
- **Granular Reactivity**: ValueNotifier provides selective rebuilds (only handle visual updates, not entire chart)
- **Proven Pattern**: Layer 008 (ValueNotifier Architecture Refactor) eliminated identical crashes using this pattern
- **MouseTracker Compatibility**: setState invalidates render trees during hit testing, causing coordinate calculation failures

**Alternatives Considered**:

| Alternative | Why Rejected |
|-------------|--------------|
| **setState** | Violates Constitution II, causes catastrophic crashes during pointer events, rebuilds entire widget tree (expensive), invalidates MouseTracker coordinates mid-calculation |
| **StatefulWidget without ValueNotifier** | Same setState issues - any state update during pointer events triggers crashes |
| **InheritedWidget** | Over-engineered for single widget scope, no performance benefit over ValueNotifier, more boilerplate |
| **Stream + StreamBuilder** | Heavier than needed, async overhead unnecessary for synchronous pointer events, more complex disposal |
| **Provider/Riverpod** | External dependency violates Constitution III (Pure Flutter), overkill for internal widget state |

**Implementation Pattern**:
```dart
// ChartScrollbar widget state
class _ChartScrollbarState extends State<ChartScrollbar> {
  late ValueNotifier<ScrollbarState> _scrollbarStateNotifier;

  @override
  void initState() {
    super.initState();
    _scrollbarStateNotifier = ValueNotifier(ScrollbarState.initial());
  }

  void _onDragUpdate(DragUpdateDetails details) {
    // ✅ Direct value update, no setState, no crashes
    _scrollbarStateNotifier.value = _scrollbarStateNotifier.value.copyWith(
      handlePosition: _calculateNewPosition(details.localPosition),
      isDragging: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ScrollbarState>(
      valueListenable: _scrollbarStateNotifier,
      builder: (context, state, child) {
        return CustomPaint(
          painter: ScrollbarPainter(state),
        );
      },
    );
  }

  @override
  void dispose() {
    _scrollbarStateNotifier.dispose();
    super.dispose();
  }
}
```

**References**:
- Constitution v1.1.0 Performance First expansion (lines 24-78)
- Layer 008 ValueNotifier Architecture Refactor (successful crash elimination)
- Flutter docs: https://api.flutter.dev/flutter/foundation/ValueNotifier-class.html
- RESEARCH.md comprehensive analysis (lines 1-1490)

---

### 2. Handle Geometry Calculations (Position & Size)

**Decision**: O(1) ratio-based formulas for handle position and size calculations

**Rationale**:
- **Performance**: Simple ratio math completes in <0.1ms (meets SC-009 requirement)
- **Simplicity**: No complex algorithms, easy to understand and maintain
- **Proven**: Similar calculations in Layer 003 (coordinate transformations) validated in production
- **Scalability**: O(1) complexity handles datasets from 100 to 1M+ points without performance degradation

**Formulas**:

```dart
// Handle size represents visible percentage of data
double calculateHandleSize(DataRange viewport, DataRange data, double trackSize) {
  final visibleRatio = (viewport.max - viewport.min) / (data.max - data.min);
  return (visibleRatio * trackSize).clamp(minHandleSize, trackSize);
}

// Handle position represents viewport offset within data range
double calculateHandlePosition(DataRange viewport, DataRange data, double trackSize, double handleSize) {
  final offsetRatio = (viewport.min - data.min) / (data.max - data.min);
  return offsetRatio * (trackSize - handleSize);
}

// Reverse: Convert handle position/size back to data range
DataRange calculateDataRange(double handlePos, double handleSize, double trackSize, DataRange data) {
  final offsetRatio = handlePos / (trackSize - handleSize);
  final visibleRatio = handleSize / trackSize;
  
  final dataSpan = data.max - data.min;
  final viewportSpan = dataSpan * visibleRatio;
  final viewportMin = data.min + (dataSpan * offsetRatio);
  final viewportMax = viewportMin + viewportSpan;
  
  return DataRange(min: viewportMin, max: viewportMax);
}
```

**Edge Cases Handled**:
- **Minimum Handle Size**: Clamp to minHandleSize (20px) prevents tiny handles when zoomed far out
- **Division by Zero**: Validate trackSize > 0 and dataSpan > 0 before calculations
- **Boundary Constraints**: Constrain handle position within [0, trackSize - handleSize]
- **Zoom Limits**: Respect minZoomRatio (1%) and maxZoomRatio (100%) from ScrollbarConfig

**Performance Validation**:
- Arithmetic operations: 8 multiplications, 4 divisions, 3 additions → <0.1ms on modern hardware
- No loops, no data structure traversal → O(1) complexity guaranteed
- Benchmarks from Layer 003 similar transforms: 0.05ms average

**Alternatives Considered**:

| Alternative | Why Rejected |
|-------------|--------------|
| **Logarithmic scaling** | Adds complexity, requires math.log() calls (slower), unnecessary for linear data ranges |
| **Bezier curve interpolation** | Overkill for simple position mapping, 10x slower, no UX benefit |
| **Lookup tables** | Memory overhead, cache invalidation complexity, not worth it for simple ratio math |

---

### 3. Coordinate System Independence (Critical Constraint)

**Decision**: Scrollbar layout MUST NOT affect TransformContext.chartAreaBounds

**Rationale**:
- **FR-015 Requirement**: Scrollbar must not modify coordinate system internals
- **Architectural Integrity**: Chart rendering calculations depend on stable chartAreaBounds
- **Layer Separation**: Scrollbar is widget layer (007), should not reach into coordinate layer (003)
- **Maintainability**: Clean separation prevents coupling between layout and coordinate calculations

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
            child: ChartCanvas(...),  // ← TransformContext created here from canvas size
          ),
          if (showYScrollbar)
            ChartScrollbar(
              axis: Axis.vertical,
              dataRange: fullYRange,
              viewportRange: currentViewport.yRange,
              onViewportChanged: (newRange) {
                _updateViewport(viewport.withRanges(viewport.xRange, newRange));
              },
            ),
        ],
      ),
    ),
    if (showXScrollbar)
      ChartScrollbar(
        axis: Axis.horizontal,
        dataRange: fullXRange,
        viewportRange: currentViewport.xRange,
        onViewportChanged: (newRange) {
          _updateViewport(viewport.withRanges(newRange, viewport.yRange));
        },
      ),
  ],
)
```

2. **Independent Coordinate Systems**:
- **Chart Canvas**: Uses TransformContext with chartAreaBounds calculated from available space (Expanded widget determines size)
- **Scrollbar**: Uses Flutter RenderBox layout coordinates, no access to TransformContext
- **Isolation**: Scrollbar never imports or references coordinate system classes (except DataRange value objects)

3. **Viewport State Flow**:
```
User drags scrollbar handle
    ↓
ScrollbarController.handleDrag() calculates new DataRange (pure function, widget coordinates only)
    ↓
onViewportChanged callback fires with new DataRange
    ↓
BravenChart state updates ViewportState via viewportState.withRanges(newXRange, newYRange)
    ↓
TransformContext recreated with new viewport (chartAreaBounds still from canvas size)
    ↓
Chart re-renders with updated visible range
    ↓
Scrollbar receives new viewportRange prop, updates handle position reactively
```

**Validation Requirements**:
- chartAreaBounds MUST always equal canvas widget size (from LayoutBuilder/Expanded)
- Scrollbar drag MUST NOT trigger chartAreaBounds recalculation
- TransformContext factory methods MUST only read viewport from ViewportState, never from scrollbar

**Alternatives Considered**:

| Alternative | Why Rejected |
|-------------|--------------|
| **Scrollbar modifies chartAreaBounds** | Violates FR-015, creates circular dependency (canvas size depends on scrollbar, scrollbar depends on canvas) |
| **Shared coordinate system for scrollbar and chart** | Tight coupling, violates layer separation, makes testing harder |
| **Scrollbar calculates chartAreaBounds** | Duplicates layout logic, risks inconsistency with actual canvas size |

---

### 4. Interaction Zone Hit Testing

**Decision**: Three-zone hit testing with cursor changes (edges, center, track)

**Rationale**:
- **Discoverability**: Cursor changes signal affordances (resize vs drag vs jump)
- **Industry Standard**: Excel, Google Sheets, Highcharts all use edge-based resize patterns
- **Touch-Friendly**: 8px edge grip zones large enough for touch screens (WCAG minimum 44px achieved with handle height)
- **Unambiguous**: Clear separation between pan (center) and zoom (edges) interactions

**Hit Zones**:

| Zone | Width/Height | Cursor | Action | Data Update |
|------|--------------|--------|--------|-------------|
| Left/Top Edge | 8px | ↔ / ↕ (resize horizontal/vertical) | Drag to adjust viewportMin | viewportRange.copyWith(min: newMin) |
| Right/Bottom Edge | 8px | ↔ / ↕ (resize horizontal/vertical) | Drag to adjust viewportMax | viewportRange.copyWith(max: newMax) |
| Center Area | handleSize - 16px | ✋ (grab/drag) | Drag to pan viewport | Shift both min/max by delta |
| Track (outside handle) | trackSize - handleSize | 👆 (pointer) | Click to jump viewport | Center viewport around click point |

**Implementation**:
```dart
enum HitTestZone { leftEdge, rightEdge, center, track }

HitTestZone _getHitZone(Offset localPosition, Rect handleBounds, double edgeGripWidth) {
  if (!handleBounds.contains(localPosition)) {
    return HitTestZone.track;  // Outside handle
  }
  
  final distanceFromLeft = localPosition.dx - handleBounds.left;
  final distanceFromRight = handleBounds.right - localPosition.dx;
  
  if (distanceFromLeft <= edgeGripWidth) {
    return HitTestZone.leftEdge;
  } else if (distanceFromRight <= edgeGripWidth) {
    return HitTestZone.rightEdge;
  } else {
    return HitTestZone.center;
  }
}

MouseCursor _getCursorForZone(HitTestZone zone, Axis axis) {
  switch (zone) {
    case HitTestZone.leftEdge:
    case HitTestZone.rightEdge:
      return axis == Axis.horizontal 
          ? SystemMouseCursors.resizeColumn 
          : SystemMouseCursors.resizeRow;
    case HitTestZone.center:
      return SystemMouseCursors.grab;
    case HitTestZone.track:
      return SystemMouseCursors.click;
  }
}
```

**Accessibility**: Keyboard navigation provides alternative to mouse-based hit testing (arrow keys for pan, Ctrl+arrow for zoom)

**Alternatives Considered**:

| Alternative | Why Rejected |
|-------------|--------------|
| **Separate resize handles (like window edges)** | More visual clutter, less intuitive than edge-drag pattern |
| **Context menu for zoom** | Requires extra click, slower than direct manipulation |
| **Modifier key + drag** | Discoverability issue (users won't know to hold Ctrl), conflicts with browser shortcuts |
| **Pinch-to-zoom on scrollbar** | Not applicable to desktop/web, touch gestures separate feature |

---

### 5. Theming System Integration

**Decision**: Extend ChartTheme with ScrollbarTheme as 7th component theme

**Rationale**:
- **Consistency**: Follows existing Layer 004 theming patterns (GridStyle, AxisStyle, SeriesTheme, etc.)
- **Customization**: Allows independent X/Y scrollbar styling (horizontal vs vertical may have different visual requirements)
- **Predefined Themes**: Leverages existing 7 predefined themes (defaultLight, defaultDark, corporateBlue, vibrant, minimal, highContrast, colorblindFriendly)
- **Immutability**: Maintains constitutional requirement for immutable themes with copyWith()

**Theme Structure**:

```dart
// Add to ChartTheme (root theme class)
class ChartTheme {
  final Color backgroundColor;
  final Color borderColor;
  final double borderWidth;
  final EdgeInsets padding;
  final GridStyle gridStyle;
  final AxisStyle axisStyle;
  final SeriesTheme seriesTheme;
  final InteractionTheme interactionTheme;
  final TypographyTheme typographyTheme;
  final AnimationTheme animationTheme;
  final ScrollbarTheme scrollbarTheme;  // ← NEW (7th component theme)
  
  // ... copyWith(), toJson(), fromJson()
}

// New ScrollbarTheme component
@immutable
class ScrollbarTheme {
  const ScrollbarTheme({
    required this.xAxisScrollbar,
    required this.yAxisScrollbar,
  });

  final ScrollbarConfig xAxisScrollbar;  // Horizontal scrollbar config
  final ScrollbarConfig yAxisScrollbar;  // Vertical scrollbar config

  /// Predefined light theme
  static const ScrollbarTheme defaultLight = ScrollbarTheme(
    xAxisScrollbar: ScrollbarConfig(
      trackColor: Color(0xFFF5F5F5),      // Light grey
      handleColor: Color(0xFFBDBDBD),     // Medium grey
      handleHoverColor: Color(0xFF9E9E9E), // Darker grey
      handleActiveColor: Color(0xFF757575), // Dark grey
    ),
    yAxisScrollbar: ScrollbarConfig(/* same as X */),
  );

  /// Predefined dark theme
  static const ScrollbarTheme defaultDark = ScrollbarTheme(
    xAxisScrollbar: ScrollbarConfig(
      trackColor: Color(0xFF212121),      // Dark background
      handleColor: Color(0xFF616161),     // Medium grey
      handleHoverColor: Color(0xFF757575), // Lighter grey
      handleActiveColor: Color(0xFF9E9E9E), // Light grey
    ),
    yAxisScrollbar: ScrollbarConfig(/* same as X */),
  );

  // ... copyWith(), toJson(), fromJson(), equality
}

// ScrollbarConfig data class
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

  final double thickness;
  final double minHandleSize;
  final Color trackColor;
  final Color handleColor;
  final Color handleHoverColor;
  final Color handleActiveColor;
  final double borderRadius;
  final double edgeGripWidth;
  final bool showGripIndicator;
  final bool autoHide;
  final Duration autoHideDelay;
  final bool enableResizeHandles;
  final double minZoomRatio;
  final double maxZoomRatio;

  // ... copyWith(), toJson(), fromJson(), equality
}
```

**Usage**:
```dart
// Use predefined theme
final chart = BravenChart(
  theme: ChartTheme.defaultDark,  // Scrollbar theme included
  // ...
);

// Customize scrollbar within theme
final customTheme = ChartTheme.defaultLight.copyWith(
  scrollbarTheme: ScrollbarTheme.defaultLight.copyWith(
    xAxisScrollbar: ScrollbarConfig(
      trackColor: Colors.blue[50]!,
      handleColor: Colors.blue[300]!,
      thickness: 16.0,  // Thicker scrollbar
    ),
  ),
);
```

**Alternatives Considered**:

| Alternative | Why Rejected |
|-------------|--------------|
| **Separate ScrollbarTheme top-level class** | Inconsistent with existing component theme pattern, requires extra prop on BravenChart |
| **Inline scrollbar props on BravenChart** | 12+ new props pollute API, breaks theme encapsulation |
| **ScrollbarConfig only (no ScrollbarTheme wrapper)** | Cannot differentiate X vs Y scrollbar styling |
| **Use Flutter's ScrollbarTheme** | Designed for Scrollable widgets, not custom scrollbars, missing dual-purpose handle features |

---

### 6. Accessibility Compliance (WCAG 2.1 AA)

**Decision**: Implement keyboard navigation, screen reader support, and WCAG 2.1 AA contrast ratios

**Rationale**:
- **FR-024 Requirement**: Explicit accessibility requirement in specification
- **Legal Compliance**: Many jurisdictions require WCAG 2.1 AA for public-facing applications
- **User Base**: Supports users with motor disabilities (keyboard), visual disabilities (screen readers, high contrast)
- **Best Practice**: Accessibility improves UX for all users (keyboard power users benefit from shortcuts)

**Keyboard Navigation Specification**:

| Key | Action | Increment | Use Case |
|-----|--------|-----------|----------|
| Tab | Focus scrollbar | N/A | Navigate to scrollbar for interaction |
| Arrow keys | Pan (small) | 5% of visible range | Fine-grained navigation |
| Shift + Arrow keys | Pan (fast) | 25% of visible range | Quick navigation |
| Ctrl/Cmd + Arrow keys | Zoom in/out | ±10% zoom level | Zoom without mouse |
| Home | Jump to start | viewportMin = dataMin | Navigate to beginning of data |
| End | Jump to end | viewportMax = dataMax | Navigate to end of data |
| Page Up/Down | Jump (large) | 1 viewport width | Paginated navigation |

**Screen Reader Support**:
```dart
Semantics(
  label: axis == Axis.horizontal 
      ? 'Chart X-axis scrollbar' 
      : 'Chart Y-axis scrollbar',
  hint: 'Drag to pan, drag edges to zoom, use arrow keys to navigate',
  value: 'Showing data from ${viewport.min.toStringAsFixed(1)} '
         'to ${viewport.max.toStringAsFixed(1)}, '
         '${(visibleRatio * 100).toStringAsFixed(0)}% of total data',
  onIncrease: () => _panRight(),    // Triggered by assistive tech
  onDecrease: () => _panLeft(),
  focusNode: _scrollbarFocusNode,
  child: scrollbarWidget,
)
```

**Contrast Ratio Requirements**:

| Element Pair | Required Ratio | Example (Light Theme) | Validation |
|--------------|----------------|----------------------|------------|
| Track vs Background | 3:1 (non-text) | #F5F5F5 vs #FFFFFF | WCAG SC 1.4.11 |
| Handle vs Track | 3:1 (non-text) | #BDBDBD vs #F5F5F5 | WCAG SC 1.4.11 |
| Handle vs Background | 4.5:1 (critical UI) | #BDBDBD vs #FFFFFF | WCAG SC 1.4.3 |
| Active Handle vs Normal | 3:1 (state change) | #757575 vs #BDBDBD | WCAG SC 1.4.11 |

**Focus Indicator**:
- Visible focus ring (2px solid, high-contrast color)
- Follows Flutter's default focus behavior
- Keyboard and pointer focus handled separately (focus on first keyboard interaction)

**Alternatives Considered**:

| Alternative | Why Rejected |
|-------------|--------------|
| **Mouse-only interaction** | Excludes keyboard users, fails WCAG 2.1.1 (Keyboard Accessible) |
| **WCAG A compliance only** | Insufficient for modern applications, misses important guidelines |
| **Generic semantic labels** | Screen readers need specific context ("Chart X-axis scrollbar" vs "scrollbar") |
| **Auto-hide without keyboard override** | Keyboard users can't see scrollbar focus state if hidden |

---

### 7. Performance Optimization Strategy

**Decision**: Triple-layer optimization (independent rendering + throttling + RepaintBoundary isolation)

**Rationale**:
- **SC-008 Requirement**: 60 FPS during drag operations (≤16.67ms frame time)
- **SC-009 Requirement**: <0.1ms handle calculations
- **SC-010 Requirement**: <16ms viewport updates
- **User Experience**: Smooth scrollbar drag feels responsive, laggy drag feels broken

**Optimization Layers**:

#### Layer 1: Independent Rendering (Isolation Strategy)

```dart
RepaintBoundary(
  child: ChartScrollbar(
    // Scrollbar renders in isolated layer
    // Chart canvas does NOT repaint when scrollbar handle moves during drag
  ),
)
```

- **Benefit**: Scrollbar drag repaints <1KB (handle only), not full chart (100KB+)
- **Implementation**: RepaintBoundary wraps scrollbar, prevents cascade to parent
- **Validation**: DevTools repaint rainbow - only scrollbar flashes during drag

#### Layer 2: Gesture Throttling (Update Frequency Control)

```dart
void _onDragUpdate(DragUpdateDetails details) {
  // Update visual handle position immediately (feels responsive)
  _scrollbarStateNotifier.value = state.copyWith(
    handlePosition: newPosition,
    isDragging: true,
  );
  
  // Throttle viewport updates to 60 FPS max
  if (_shouldThrottleViewportUpdate()) {
    return;  // Skip this update, wait for next frame
  }
  
  _lastViewportUpdate = DateTime.now();
  final newViewportRange = _controller.handlePositionToDataRange(...);
  widget.onViewportChanged(newViewportRange);  // Triggers chart re-render
}

bool _shouldThrottleViewportUpdate() {
  final timeSinceLastUpdate = DateTime.now().difference(_lastViewportUpdate);
  return timeSinceLastUpdate < const Duration(milliseconds: 16);  // 60 FPS = 16.67ms
}
```

- **Benefit**: Visual feedback instant, data updates capped at 60 FPS
- **Trade-off**: Chart data may lag 1-2 frames behind handle position during rapid drag (acceptable)
- **Fallback**: onDragEnd() always fires final update (ensures data syncs on release)

#### Layer 3: Layout Optimization (Calculation Efficiency)

- **Fixed Sizes**: Scrollbar dimensions fixed during chart lifetime (no layout recalculation during drag)
- **O(1) Calculations**: Handle position = simple ratio math (8 operations, <0.1ms)
- **Cached Ranges**: Data ranges cached, not re-queried from data source during drag
- **No Data Traversal**: No iteration over data points (only range min/max used)

**Performance Targets & Validation**:

| Metric | Target | Validation Method |
|--------|--------|-------------------|
| Handle calculation | <0.1ms | Benchmark test with 1M iterations |
| Scrollbar render | <1ms | CustomPainter profiling |
| Viewport update | <16ms | Full chart re-render with 10K points |
| Memory overhead | <100KB | DevTools memory profiler (both scrollbars) |
| Frame time during drag | <16.67ms | Flutter DevTools performance overlay |
| Frame drops (jank) | 0% | 1000-frame drag session monitoring |

**Alternatives Considered**:

| Alternative | Why Rejected |
|-------------|--------------|
| **Debouncing instead of throttling** | Lag feels worse (updates pause, then jump), throttling smoother |
| **Update on every pointer event** | Causes jank (100+ updates/sec), wastes CPU cycles |
| **Render scrollbar and chart together** | Repaint entire stack on drag (expensive), fails performance targets |
| **Complex optimization (worker isolates, caching matrices)** | Over-engineered, O(1) calculations already fast enough |

---

## Summary

**All 7 research questions resolved** - No blocking technical uncertainties remain.

**Key Decisions**:
1. **ValueNotifier Pattern** - Constitutional requirement for >10Hz pointer events
2. **O(1) Ratio Formulas** - Simple, fast, maintainable handle calculations
3. **Coordinate Independence** - Scrollbar layout separated from TransformContext
4. **Three-Zone Hit Testing** - Edge/center/track zones with cursor feedback
5. **ScrollbarTheme Integration** - 7th component theme following Layer 004 patterns
6. **WCAG 2.1 AA Accessibility** - Keyboard navigation, screen readers, 4.5:1 contrast
7. **Triple-Layer Performance** - Isolation + throttling + O(1) calculations

**Ready for Phase 1**: Design documented, contracts defined, unknowns eliminated.

**Next Steps**: Generate data-model.md, contracts/, quickstart.md artifacts.
