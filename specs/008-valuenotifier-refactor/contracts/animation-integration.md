# Internal Contracts: Animation Integration

**Feature**: 008-valuenotifier-refactor  
**Phase**: 1 - Design & Contracts  
**Contract Type**: Internal Widget Behavior  
**Scope**: Animation controllers and listeners in `_BravenChartState`  

## Overview

This contract defines the expected behavior for animation controllers (zoom, pan) and their integration with ValueNotifier pattern. These are **internal private members** not exposed in public API. The contract ensures animations update state through notifier without triggering widget rebuilds.

---

## Animation Controller Inventory

### 1. Zoom Animation Controller
 
#### Purpose
Smoothly interpolate zoom level changes when user scrolls or uses zoom gestures.

#### Declaration Contract
```dart
class _BravenChartState extends State<BravenChart> with TickerProviderStateMixin {
  late AnimationController _zoomAnimationController;
  late Animation<double> _zoomAnimation;
  
  @override
  void initState() {
    super.initState();
    
    // MUST initialize in initState
    _zoomAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    // MUST create animation with initial value
    _zoomAnimation = Tween<double>(
      begin: 1.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _zoomAnimationController,
      curve: Curves.easeOut,
    ));
    
    // MUST add listener that updates notifier (NOT setState)
    _zoomAnimation.addListener(_onZoomAnimationUpdate);
  }
  
  @override
  void dispose() {
    // MUST dispose controller before notifier
    _zoomAnimationController.dispose();
    // ... other disposal
    super.dispose();
  }
}
```

---

#### Listener Contract: _onZoomAnimationUpdate()

**Signature**:
```dart
void _onZoomAnimationUpdate() {
  // MUST update notifier (NOT setState)
  _interactionStateNotifier.value = _interactionStateNotifier.value.copyWith(
    zoomLevel: _zoomAnimation.value,
    isZooming: _zoomAnimationController.isAnimating,
  );
}
```

**Requirements**:
- **MUST** update notifier directly (never use setState)
- **MUST** use copyWith for immutable updates
- **MUST** derive `isZooming` from controller state
- **MUST** complete in <1ms (called 60 times/second during animation)

**Postconditions**:
- `zoomLevel` updated to current animation value
- `isZooming == true` while animating, `false` when complete
- Zero widget rebuilds triggered
- Only ValueListenableBuilder overlay rebuilds

---

#### Animation Trigger Contract: _startZoomAnimation(double targetZoom)

**Signature**:
```dart
void _startZoomAnimation(double targetZoom) {
  // MUST clamp target zoom to configured bounds
  final clampedZoom = targetZoom.clamp(
    widget.interactionConfig?.minZoom ?? 0.1,
    widget.interactionConfig?.maxZoom ?? 10.0,
  );
  
  // MUST update Tween begin/end values
  _zoomAnimation = Tween<double>(
    begin: _interactionStateNotifier.value.zoomLevel,  // Current zoom
    end: clampedZoom,                                   // Target zoom
  ).animate(CurvedAnimation(
    parent: _zoomAnimationController,
    curve: Curves.easeOut,
  ));
  
  // MUST reset controller and start animation
  _zoomAnimationController
    ..reset()
    ..forward();
}
```

**Requirements**:
- **MUST** clamp target to configured bounds (prevent invalid zoom levels)
- **MUST** use current state value as animation start (smooth transitions)
- **MUST** reset controller before starting (ensures clean state)
- **MAY** interrupt existing animation (last animation wins)

**Postconditions**:
- Animation started from current zoom to target zoom
- Listener will fire 60 times/second during 200ms duration
- `isZooming == true` in InteractionState

---

### 2. Pan Animation Controller

#### Purpose
Apply momentum/inertia to pan gestures after user releases pointer (fling gesture).

#### Declaration Contract
```dart
class _BravenChartState extends State<BravenChart> with TickerProviderStateMixin {
  late AnimationController _panAnimationController;
  late Animation<Offset> _panAnimation;
  
  @override
  void initState() {
    super.initState();
    
    // MUST initialize in initState
    _panAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    // MUST create animation with initial value
    _panAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _panAnimationController,
      curve: Curves.decelerate,
    ));
    
    // MUST add listener that updates notifier (NOT setState)
    _panAnimation.addListener(_onPanAnimationUpdate);
  }
  
  @override
  void dispose() {
    // MUST dispose controller before notifier
    _panAnimationController.dispose();
    // ... other disposal
    super.dispose();
  }
}
```

---

#### Listener Contract: _onPanAnimationUpdate()

**Signature**:
```dart
void _onPanAnimationUpdate() {
  // MUST update notifier (NOT setState)
  _interactionStateNotifier.value = _interactionStateNotifier.value.copyWith(
    panCurrentPosition: _panAnimation.value,
    isPanning: _panAnimationController.isAnimating,
  );
}
```

**Requirements**:
- **MUST** update notifier directly (never use setState)
- **MUST** use copyWith for immutable updates
- **MUST** derive `isPanning` from controller state (true during animation)
- **MUST** complete in <1ms (called 60 times/second during animation)

**Postconditions**:
- `panCurrentPosition` updated to current animation value
- `isPanning == true` while animating, `false` when complete
- Zero widget rebuilds triggered
- Only ValueListenableBuilder overlay rebuilds

---

#### Animation Trigger Contract: _startPanAnimation(Offset velocity)

**Signature**:
```dart
void _startPanAnimation(Offset velocity) {
  // MUST check minimum velocity threshold (prevent tiny animations)
  const double minVelocity = 50.0; // pixels/second
  if (velocity.distance < minVelocity) return;
  
  // MUST calculate target position based on velocity and duration
  final currentPosition = _interactionStateNotifier.value.panCurrentPosition ?? Offset.zero;
  final animationDuration = _panAnimationController.duration!.inMilliseconds / 1000.0;
  final targetPosition = currentPosition + (velocity * animationDuration);
  
  // MUST update Tween begin/end values
  _panAnimation = Tween<Offset>(
    begin: currentPosition,  // Current position
    end: targetPosition,      // Calculated target
  ).animate(CurvedAnimation(
    parent: _panAnimationController,
    curve: Curves.decelerate,
  ));
  
  // MUST reset controller and start animation
  _panAnimationController
    ..reset()
    ..forward();
}
```

**Requirements**:
- **MUST** check minimum velocity threshold (prevent imperceptible animations)
- **MUST** calculate target based on velocity and duration (physics-based)
- **MUST** use current state value as animation start (smooth transitions)
- **MUST** reset controller before starting (ensures clean state)
- **MAY** interrupt existing animation (last animation wins)

**Postconditions**:
- Animation started from current position to calculated target
- Listener will fire 60 times/second during 300ms duration
- `isPanning == true` in InteractionState

---

## Common Animation Patterns

### Pattern 1: Listener Registration

**MUST add listener in initState**:
```dart
@override
void initState() {
  super.initState();
  
  // Create controller
  _zoomAnimationController = AnimationController(...);
  
  // Create animation
  _zoomAnimation = Tween<double>(...).animate(_zoomAnimationController);
  
  // ✅ REQUIRED: Add listener
  _zoomAnimation.addListener(_onZoomAnimationUpdate);
  
  // ❌ FORBIDDEN: Never use addListener(() => setState(...))
}
```

**Why**: Listeners registered in initState ensure they're active for entire widget lifecycle.

---

### Pattern 2: Notifier Update (Not setState)

**Listener implementation MUST**:
```dart
void _onZoomAnimationUpdate() {
  // ❌ FORBIDDEN - Never use setState in animation listener
  setState(() {
    _interactionState = _interactionState.copyWith(
      zoomLevel: _zoomAnimation.value,
    );
  });
  
  // ✅ REQUIRED - Always update notifier directly
  _interactionStateNotifier.value = _interactionStateNotifier.value.copyWith(
    zoomLevel: _zoomAnimation.value,
  );
}
```

**Why**: setState in animation listener causes 60 widget rebuilds/second → severe jank and crashes.

---

### Pattern 3: Disposal Order

**Disposal MUST follow specific order**:
```dart
@override
void dispose() {
  // 1. Cancel timers first
  _tooltipHideTimer?.cancel();
  _tooltipHideTimer = null;
  
  // 2. ✅ Dispose animation controllers BEFORE notifier
  _zoomAnimationController.dispose();
  _panAnimationController.dispose();
  
  // 3. Dispose notifier last
  _interactionStateNotifier.dispose();
  
  // 4. Super dispose final
  super.dispose();
}
```

**Why**:
1. Timers: Prevent callbacks during disposal
2. Controllers: Stop animations before state disposal (listeners may access notifier)
3. Notifier: Dispose after all potential writers stopped
4. Super: Framework cleanup last

---

### Pattern 4: Animation Interruption

**Starting new animation MUST handle interruption**:
```dart
void _startZoomAnimation(double targetZoom) {
  // ✅ REQUIRED: Reset controller (stops current animation if running)
  _zoomAnimationController.reset();
  
  // Update tween
  _zoomAnimation = Tween<double>(
    begin: _interactionStateNotifier.value.zoomLevel,  // Use current value (may be mid-animation)
    end: targetZoom,
  ).animate(_zoomAnimationController);
  
  // Start new animation
  _zoomAnimationController.forward();
}
```

**Why**: User may trigger new animation before previous completes. Using current state value ensures smooth transition.

---

## Controller Lifecycle

### State Machine

```
[Initialized] 
    ↓ (controller.forward())
[Animating] ← listener fires 60 times/second → [Notifier Updated] → [Overlay Rebuilds]
    ↓ (animation completes)
[Complete] 
    ↓ (controller.reset())
[Initialized]
    ↓ (dispose() called)
[Disposed] ← MUST NOT access after this point
```

### Lifecycle Methods

**initState()**:
```dart
@override
void initState() {
  super.initState();
  
  // 1. Create controllers
  _zoomAnimationController = AnimationController(...);
  _panAnimationController = AnimationController(...);
  
  // 2. Create animations
  _zoomAnimation = Tween<double>(...).animate(_zoomAnimationController);
  _panAnimation = Tween<Offset>(...).animate(_panAnimationController);
  
  // 3. Register listeners
  _zoomAnimation.addListener(_onZoomAnimationUpdate);
  _panAnimation.addListener(_onPanAnimationUpdate);
}
```

**dispose()**:
```dart
@override
void dispose() {
  // Controllers auto-remove listeners on dispose, but explicit is safer
  _zoomAnimation.removeListener(_onZoomAnimationUpdate);
  _panAnimation.removeListener(_onPanAnimationUpdate);
  
  // Dispose controllers (stops animations, releases tickers)
  _zoomAnimationController.dispose();
  _panAnimationController.dispose();
  
  super.dispose();
}
```

---

## Testing Contract

### Unit Test Requirements

**Each controller MUST have**:
1. Test verifying listener updates notifier (not setState)
2. Test verifying animation interpolates correctly
3. Test verifying controller disposal
4. Test verifying animation interruption
5. Test verifying zero widget rebuilds during animation

**Example Test Template**:
```dart
testWidgets('Zoom animation updates notifier without setState', (tester) async {
  await tester.pumpWidget(BravenChart(...));
  final state = tester.state<_BravenChartState>(find.byType(BravenChart));
  
  // Track rebuild count
  int buildCount = 0;
  state.addListener(() => buildCount++);
  
  // Start zoom animation
  state._startZoomAnimation(2.0);
  
  // Pump animation frames
  await tester.pump(); // Start
  await tester.pump(const Duration(milliseconds: 100)); // Mid-animation
  await tester.pump(const Duration(milliseconds: 200)); // Complete
  
  // Assert notifier updated
  expect(state._interactionStateNotifier.value.zoomLevel, closeTo(2.0, 0.01));
  
  // Assert zero widget rebuilds
  expect(buildCount, equals(0));
});

testWidgets('Animation interruption works correctly', (tester) async {
  await tester.pumpWidget(BravenChart(...));
  final state = tester.state<_BravenChartState>(find.byType(BravenChart));
  
  // Start first animation
  state._startZoomAnimation(2.0);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50)); // 25% through
  
  final midAnimationZoom = state._interactionStateNotifier.value.zoomLevel;
  expect(midAnimationZoom, greaterThan(1.0));
  expect(midAnimationZoom, lessThan(2.0));
  
  // Interrupt with second animation
  state._startZoomAnimation(3.0);
  await tester.pump(const Duration(milliseconds: 200));
  
  // Assert ended at new target (not original target)
  expect(state._interactionStateNotifier.value.zoomLevel, closeTo(3.0, 0.01));
});
```

---

## Performance Contract

**Animation listeners MUST**:
1. Complete in <1ms (called 60 times/second)
2. Trigger zero widget rebuilds
3. Update only relevant fields (copyWith selectivity)
4. Handle interruption gracefully (no crashes)

**Performance Validation**:
```dart
testWidgets('Animation maintains 60fps', (tester) async {
  await tester.pumpWidget(BravenChart(...));
  final state = tester.state<_BravenChartState>(find.byType(BravenChart));
  
  final frameTimes = <Duration>[];
  WidgetsBinding.instance.addTimingsCallback((timings) {
    for (final timing in timings) {
      frameTimes.add(timing.totalSpan);
    }
  });
  
  // Run animation
  state._startZoomAnimation(2.0);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 200));
  
  // Assert all frames < 16ms (60fps)
  expect(frameTimes.every((t) => t.inMilliseconds <= 16), isTrue);
});
```

---

## Migration Checklist

For each animation controller being refactored:

- [ ] Remove all `setState()` calls from listeners
- [ ] Remove all `_safeSetState()` calls from listeners
- [ ] Update listeners to use `_interactionStateNotifier.value = ...`
- [ ] Use `copyWith()` for immutable updates
- [ ] Verify disposal order (controllers before notifier)
- [ ] Add listener removal in dispose (explicit cleanup)
- [ ] Write unit tests (5 minimum per controller)
- [ ] Run performance validation (60fps verification)
- [ ] Verify animation interruption works
- [ ] Update inline documentation

---

## Summary

**Total Controllers**: 2 (zoom, pan)  
**Listeners**: 2 (one per controller)  
**Pattern**: Direct notifier update in listener, zero setState  
**Performance**: <1ms per listener call, 60fps maintained  
**Lifecycle**: Initialize in initState, dispose before notifier  
**Testing**: 90% coverage, performance validation, interruption testing  

**Key Principle**: Animation controllers drive state changes through notifier, not through setState. Listeners are pure state update mechanisms decoupled from widget lifecycle.
