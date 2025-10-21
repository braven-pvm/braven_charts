# Data Model: ValueNotifier Architecture

**Feature**: 008-valuenotifier-refactor  
**Phase**: 1 - Design & Contracts  
**Date**: 2025-01-21

## Overview

This document defines the data structures and state management patterns used in the ValueNotifier-based interaction system. All entities are internal to `BravenChart` widget and not exposed in public API.

---

## Core Entities

### Entity 1: InteractionState (Existing - No Changes)

**Location**: `lib/src/models/interaction_state.dart`

**Purpose**: Immutable value object containing all user interaction state (crosshair, tooltips, pan/zoom, keyboard).

**Structure**:
```dart
class InteractionState {
  // Crosshair state
  final bool isCrosshairVisible;
  final Offset? crosshairPosition;
  
  // Tooltip state
  final bool isTooltipVisible;
  final Offset? tooltipPosition;
  final String? tooltipText;
  
  // Pan state
  final bool isPanning;
  final Offset? panStartPosition;
  final Offset? panCurrentPosition;
  
  // Zoom state
  final bool isZooming;
  final double zoomLevel;
  final Offset? zoomFocalPoint;
  
  // Keyboard state
  final Set<LogicalKeyboardKey> pressedKeys;
  
  // Factory constructor
  factory InteractionState.initial() => InteractionState(...);
  
  // Immutable copy with selective updates
  InteractionState copyWith({
    bool? isCrosshairVisible,
    Offset? crosshairPosition,
    // ... all fields optional
  }) => InteractionState(...);
}
```

**Characteristics**:
- **Immutability**: All fields final, updates via `copyWith()`
- **Nullability**: Position fields nullable (null = not active)
- **Composition**: Single object holds all interaction state (not fragmented)
- **Serializability**: Can be serialized for debugging (though not currently implemented)

**Usage Pattern**:
```dart
// Read current state
final currentState = _interactionStateNotifier.value;

// Create updated state
final updatedState = currentState.copyWith(
  isCrosshairVisible: true,
  crosshairPosition: Offset(100, 200),
);

// Publish to listeners
_interactionStateNotifier.value = updatedState;
```

**Why No Changes Needed**:
- Already immutable value object (perfect for ValueNotifier)
- Already has copyWith() for selective updates
- Already covers all interaction types
- Field structure matches requirements exactly

---

### Entity 2: ValueNotifier<InteractionState> (New - Core Refactor)

**Location**: `lib/src/widgets/braven_chart.dart` (private field in `_BravenChartState`)

**Purpose**: Observable state container that notifies listeners when InteractionState changes without triggering widget rebuilds.

**Structure**:
```dart
class _BravenChartState extends State<BravenChart> {
  late final ValueNotifier<InteractionState> _interactionStateNotifier;
  
  @override
  void initState() {
    super.initState();
    _interactionStateNotifier = ValueNotifier(InteractionState.initial());
  }
  
  @override
  void dispose() {
    _interactionStateNotifier.dispose();
    super.dispose();
  }
}
```

**Characteristics**:
- **Lifecycle**: Created in `initState()`, disposed in `dispose()`
- **Initialization**: Starts with `InteractionState.initial()`
- **Scope**: Private to `_BravenChartState`, not exposed publicly
- **Thread Safety**: Updates happen on UI thread (no synchronization needed)

**Update Pattern**:
```dart
// BEFORE (broken setState approach)
void _onHover(PointerHoverEvent event) {
  _safeSetState(() {
    _interactionState = _interactionState.copyWith(
      isCrosshairVisible: true,
      crosshairPosition: localPosition,
    );
  });
}

// AFTER (ValueNotifier approach)
void _onHover(PointerHoverEvent event) {
  _interactionStateNotifier.value = _interactionStateNotifier.value.copyWith(
    isCrosshairVisible: true,
    crosshairPosition: localPosition,
  );
}
```

**Notification Behavior**:
- **When**: Notifies all listeners whenever `.value` setter called
- **Coalescing**: Framework automatically coalesces multiple updates within single frame
- **Granular**: Only registered ValueListenableBuilder widgets rebuild
- **Performance**: Zero impact on widgets not listening to notifier

---

### Entity 3: ValueListenableBuilder<InteractionState> (New - Rendering Integration)

**Location**: `lib/src/widgets/braven_chart.dart` (in `build()` method)

**Purpose**: Rebuilds interactive overlays (crosshair, tooltip) when InteractionState changes, isolated from base chart rendering.

**Structure**:
```dart
@override
Widget build(BuildContext context) {
  return Stack(
    children: [
      // Base chart (never rebuilds from interaction state)
      CustomPaint(
        painter: _ChartPainter(...),
      ),
      
      // Interactive overlays (rebuilds on state changes)
      RepaintBoundary(
        child: ValueListenableBuilder<InteractionState>(
          valueListenable: _interactionStateNotifier,
          builder: (context, state, child) {
            return Stack(
              children: [
                if (state.isCrosshairVisible && state.crosshairPosition != null)
                  CustomPaint(
                    painter: _CrosshairPainter(state.crosshairPosition!),
                  ),
                if (state.isTooltipVisible && state.tooltipPosition != null)
                  Positioned(
                    left: state.tooltipPosition!.dx,
                    top: state.tooltipPosition!.dy,
                    child: _TooltipWidget(text: state.tooltipText),
                  ),
              ],
            );
          },
        ),
      ),
    ],
  );
}
```

**Characteristics**:
- **Selective Rebuilding**: Only builder function executes, not entire widget
- **Null Safety**: Checks field nullability before rendering
- **Composability**: Can nest multiple builders if needed (not required for this refactor)
- **Isolation**: Wrapped in RepaintBoundary for further optimization

**Rebuild Scope**:
- **DOES rebuild**: Widgets inside builder function (crosshair, tooltip)
- **DOES NOT rebuild**: Base chart, parent Stack, sibling widgets
- **Performance**: Only rebuilds what changed (minimal work)

---

## State Transitions

### Transition Diagram

```
[Initial State]
    ↓
[User Action] → [Event Handler] → [Update Notifier] → [Notify Listeners] → [Rebuild Overlay]
    ↑                                                                              ↓
    └──────────────────────────────── [Render Complete] ←────────────────────────┘
```

### State Transition Examples

#### Example 1: Mouse Hover (Crosshair Display)
```dart
// 1. Initial state
InteractionState(
  isCrosshairVisible: false,
  crosshairPosition: null,
  // ... other fields default
)

// 2. User moves mouse over chart
_onHover(PointerHoverEvent(localPosition: Offset(150, 300)))

// 3. Event handler updates notifier
_interactionStateNotifier.value = _interactionStateNotifier.value.copyWith(
  isCrosshairVisible: true,
  crosshairPosition: Offset(150, 300),
)

// 4. New state
InteractionState(
  isCrosshairVisible: true,          // Changed
  crosshairPosition: Offset(150, 300), // Changed
  // ... other fields preserved
)

// 5. ValueListenableBuilder notified → Crosshair renders at (150, 300)
```

#### Example 2: Simultaneous Interactions (Zoom + Hover)
```dart
// 1. Current state (hovering)
InteractionState(
  isCrosshairVisible: true,
  crosshairPosition: Offset(150, 300),
  isZooming: false,
  zoomLevel: 1.0,
)

// 2. User starts zoom gesture while hovering
_onPointerSignal(PointerSignalEvent(...))

// 3. Event handler updates zoom fields only
_interactionStateNotifier.value = _interactionStateNotifier.value.copyWith(
  isZooming: true,
  zoomLevel: 1.2,
  zoomFocalPoint: Offset(150, 300),
  // crosshair fields NOT specified → preserved
)

// 4. New state (both hover AND zoom active)
InteractionState(
  isCrosshairVisible: true,           // Preserved
  crosshairPosition: Offset(150, 300), // Preserved
  isZooming: true,                     // Changed
  zoomLevel: 1.2,                      // Changed
  zoomFocalPoint: Offset(150, 300),    // Changed
)

// 5. ValueListenableBuilder notified → Both crosshair AND zoom indicator render
```

#### Example 3: Throttled High-Frequency Updates
```dart
// Scenario: Mouse moves 200 times/second, throttled to 60Hz

// Frame 1 (0ms): Update allowed
_throttledUpdate(state1) → _interactionStateNotifier.value = state1

// 1ms-15ms: 20 updates queued, coalesced to final position
_throttledUpdate(state2) → Deferred
_throttledUpdate(state3) → Deferred
// ... 17 more updates
_throttledUpdate(state20) → Deferred (but position cached)

// Frame 2 (16ms): Coalesced update applied
SchedulerBinding.instance.scheduleFrameCallback((_) {
  _interactionStateNotifier.value = state20; // Only latest position
});

// Result: 200 input events → 60 state updates → smooth 60fps
```

---

## Data Flow Architecture

### Overview Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                        BravenChart Widget                        │
│                                                                   │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │              _BravenChartState                           │   │
│  │                                                           │   │
│  │  ┌─────────────────────────────────────────────┐        │   │
│  │  │  ValueNotifier<InteractionState>            │        │   │
│  │  │  ↑                                           ↓        │   │
│  │  │  │ Updates from:                    Notifies:        │   │
│  │  │  │ - Event handlers (11+)           - ValueListenableBuilder │
│  │  │  │ - Animation listeners (2)        - Overlay rendering     │
│  │  │  │ - Controller callbacks (2)                        │   │
│  │  │  │ - Timer callbacks (1)                             │   │
│  │  └─────────────────────────────────────────────┘        │   │
│  │                                                           │   │
│  │  ┌─────────────────────────────────────────────┐        │   │
│  │  │  build() Method                              │        │   │
│  │  │                                               │        │   │
│  │  │  Stack(                                       │        │   │
│  │  │    CustomPaint(ChartPainter) ← No rebuilds  │        │   │
│  │  │    RepaintBoundary(                          │        │   │
│  │  │      ValueListenableBuilder(                 │        │   │
│  │  │        _interactionStateNotifier,            │        │   │
│  │  │        builder: (context, state, _) {        │        │   │
│  │  │          return InteractiveOverlays(state); │        │   │
│  │  │        }                                      │        │   │
│  │  │      )                                        │        │   │
│  │  │    )                                          │        │   │
│  │  │  )                                            │        │   │
│  │  └─────────────────────────────────────────────┘        │   │
│  └─────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
```

### Data Flow Steps

**Step 1: User Input**
- Pointer events (hover, exit, down, move, up)
- Scroll events (wheel, trackpad)
- Keyboard events (Ctrl, Shift for modifiers)

**Step 2: Event Handler**
- Event converted to local coordinates
- Current state retrieved: `_interactionStateNotifier.value`
- New state computed: `currentState.copyWith(...)`
- Throttling applied if needed (>60Hz)

**Step 3: Notifier Update**
- New state published: `_interactionStateNotifier.value = newState`
- Framework invokes `notifyListeners()` internally
- All registered listeners notified synchronously

**Step 4: Builder Invocation**
- ValueListenableBuilder receives new state
- Builder function executes with updated state
- Conditional rendering based on state flags

**Step 5: Overlay Rendering**
- CustomPainter renders crosshair/tooltip
- RepaintBoundary isolates from base chart
- Only overlay layer repaints (not entire widget)

**Performance Characteristics**:
- **Latency**: <1ms from event to notifier update
- **Rebuild Time**: ~0.1ms for overlay (crosshair line)
- **Base Chart Impact**: Zero (never rebuilds)
- **Frame Budget**: <2ms total for interaction update (leaves 14ms for other work)

---

## Memory Management

### Lifecycle Management

**Creation (initState)**:
```dart
@override
void initState() {
  super.initState();
  
  // Create notifier with initial state
  _interactionStateNotifier = ValueNotifier(InteractionState.initial());
  
  // Animation controllers (if needed)
  _zoomAnimationController = AnimationController(...)
    ..addListener(() {
      // Update notifier directly (no setState)
      _interactionStateNotifier.value = _interactionStateNotifier.value.copyWith(
        zoomLevel: _zoomAnimation.value,
      );
    });
}
```

**Disposal (dispose)**:
```dart
@override
void dispose() {
  // 1. Cancel timers first (prevent callbacks after disposal)
  _tooltipHideTimer?.cancel();
  _tooltipHideTimer = null;
  
  // 2. Dispose animation controllers (stops tickers, removes listeners)
  _zoomAnimationController.dispose();
  _panAnimationController.dispose();
  
  // 3. Dispose ValueNotifier (releases all listeners)
  _interactionStateNotifier.dispose();
  
  // 4. Super dispose (framework cleanup)
  super.dispose();
}
```

**Disposal Order Critical**:
1. **Timers**: Prevent callbacks during disposal
2. **Animation Controllers**: Stop tickers before state disposal
3. **ValueNotifier**: Release listeners after no more updates
4. **super.dispose()**: Framework cleanup last

### Memory Leak Prevention

**Potential Leak Sources**:
| Source | Risk | Prevention |
|--------|------|------------|
| **ValueNotifier listeners** | Listeners hold widget references | Call `dispose()` to remove all listeners |
| **Animation controllers** | Tickers and listeners survive disposal | Call `dispose()` on each controller |
| **Active timers** | Timer callbacks hold state references | Call `cancel()` before disposal |
| **External listeners** | If external widgets register listeners | Document that external listeners must deregister |

**Verification Strategy**:
```dart
// Test disposal in unit test
testWidgets('Disposal cleans up all resources', (tester) async {
  await tester.pumpWidget(BravenChart(...));
  final state = tester.state<_BravenChartState>(find.byType(BravenChart));
  
  // Capture references
  final notifier = state._interactionStateNotifier;
  final zoomController = state._zoomAnimationController;
  
  // Dispose widget
  await tester.pumpWidget(Container());
  
  // Verify disposal
  expect(() => notifier.value, throwsFlutterError); // Disposed notifiers throw
  expect(() => zoomController.forward(), throwsFlutterError); // Disposed controllers throw
});
```

---

## Thread Safety & Concurrency

### Current Architecture (Single-Threaded)

**All operations on UI thread**:
- Event handlers execute on UI thread
- ValueNotifier updates happen on UI thread
- Listeners notified synchronously on UI thread
- No explicit synchronization needed

**Why No Concurrency Concerns**:
1. **Flutter Event Loop**: All UI events processed sequentially on main isolate
2. **Synchronous Notifications**: ValueNotifier.value setter synchronously notifies listeners
3. **No Isolates**: Chart rendering stays on main isolate (no compute offloading)
4. **No Async Updates**: State updates happen immediately in event handlers

### Future Considerations (If Needed)

**IF heavy computation needed** (e.g., 100k+ data points):
```dart
// Hypothetical: Offload data processing to isolate
Future<void> _processHeavyData() async {
  final processedData = await compute(_heavyComputation, rawData);
  
  // Update notifier on UI thread after compute
  if (mounted) {
    _interactionStateNotifier.value = _interactionStateNotifier.value.copyWith(
      processedData: processedData,
    );
  }
}
```

**Current Scope**: No isolate usage needed for interaction state (all operations <1ms).

---

## Performance Characteristics

### Benchmarks (Expected)

| Operation | Before (setState) | After (ValueNotifier) | Improvement |
|-----------|-------------------|------------------------|-------------|
| **Widget rebuilds on hover** | 100+ per second | 0 per second | Infinite |
| **Overlay repaints** | Entire stack | CustomPainter only | 100x |
| **Frame time (mouse hover)** | 25-50ms (jank) | <2ms (smooth) | 12-25x |
| **Crash frequency** | Continuous (box.dart:3345) | Zero | Infinite |
| **Memory usage** | Same | Same | No change |

### Performance Testing Strategy

**Automated Performance Test**:
```dart
// test/performance/interaction_performance_test.dart
testWidgets('Maintains 60fps during continuous hover', (tester) async {
  final stopwatch = Stopwatch()..start();
  final frameTimes = <Duration>[];
  
  WidgetsBinding.instance.addTimingsCallback((timings) {
    for (final timing in timings) {
      frameTimes.add(timing.totalSpan);
    }
  });
  
  await tester.pumpWidget(BravenChart(...));
  
  // Simulate 1000 hover events over 5 seconds
  for (int i = 0; i < 1000; i++) {
    await tester.sendEventToBinding(PointerHoverEvent(
      position: Offset(i.toDouble(), 100),
    ));
    await tester.pump(const Duration(milliseconds: 5));
  }
  
  stopwatch.stop();
  
  // Assert all frames under 16ms (60fps)
  expect(frameTimes.every((t) => t.inMilliseconds <= 16), isTrue);
  
  // Assert zero crashes
  expect(tester.takeException(), isNull);
});
```

---

## Summary

**Core Data Structures**:
1. **InteractionState**: Existing immutable value object (no changes)
2. **ValueNotifier<InteractionState>**: New observable state container (core refactor)
3. **ValueListenableBuilder<InteractionState>**: New selective rebuild widget (rendering integration)

**Key Patterns**:
- **Immutability**: All state updates via copyWith()
- **Observability**: ValueNotifier notifies listeners without setState
- **Isolation**: RepaintBoundary prevents cascade repaints
- **Lifecycle**: Proper initialization and comprehensive disposal
- **Performance**: Zero widget rebuilds, minimal repaint cost

**Performance Gains**:
- 100+ widget rebuilds/second → 0 widget rebuilds
- Full stack repaints → Isolated CustomPainter repaints
- 25-50ms frame times → <2ms frame times
- Continuous crashes → Zero crashes

**Ready for Phase 2: Task Breakdown**
