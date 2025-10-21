# Internal Contracts: Event Handlers

**Feature**: 008-valuenotifier-refactor  
**Phase**: 1 - Design & Contracts  
**Contract Type**: Internal Widget Behavior  
**Scope**: Private methods in `_BravenChartState`  

## Overview

This contract defines the expected behavior for all pointer event handlers in the BravenChart widget. These are **internal private methods** not exposed in public API. The contract ensures consistent refactoring from setState to ValueNotifier pattern across all 11+ event handlers.

---

## Contract Definition

### Handler Signature Contract

**All event handlers MUST**:
1. Accept a single `PointerEvent` subclass parameter
2. Return `void`
3. Be private methods (prefix with `_`)
4. Update `_interactionStateNotifier.value` directly (never use setState)
5. Use `copyWith()` for immutable state updates
6. Handle null safety explicitly

**Standard Signature Template**:
```dart
void _handlerName(PointerEventSubclass event) {
  // 1. Coordinate conversion (if needed)
  final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
  if (renderBox == null) return;
  final localPosition = renderBox.globalToLocal(event.position);
  
  // 2. State update via notifier (NO setState)
  _interactionStateNotifier.value = _interactionStateNotifier.value.copyWith(
    relevantField: newValue,
  );
  
  // 3. Side effects (animations, callbacks) - optional
}
```

---

## Event Handler Inventory

### 1. Hover Events

#### _onHover(PointerHoverEvent event)
**Trigger**: Mouse moves over chart with no buttons pressed  
**Responsibility**: Update crosshair position, show crosshair

**Contract**:
```dart
void _onHover(PointerHoverEvent event) {
  // MUST convert to local coordinates
  final localPosition = _globalToLocal(event.position);
  if (localPosition == null) return;
  
  // MUST update notifier (not setState)
  _interactionStateNotifier.value = _interactionStateNotifier.value.copyWith(
    isCrosshairVisible: true,
    crosshairPosition: localPosition,
  );
  
  // MUST invoke tooltip timer if configured
  _scheduleTooltipDisplay();
}
```

**Postconditions**:
- `isCrosshairVisible == true`
- `crosshairPosition == localPosition`
- Tooltip timer scheduled (if tooltip enabled)
- Zero widget rebuilds triggered

---

#### _onExit(PointerExitEvent event)
**Trigger**: Mouse leaves chart boundary  
**Responsibility**: Hide crosshair, cancel tooltip timer

**Contract**:
```dart
void _onExit(PointerExitEvent event) {
  // MUST update notifier (not setState)
  _interactionStateNotifier.value = _interactionStateNotifier.value.copyWith(
    isCrosshairVisible: false,
    crosshairPosition: null,
    isTooltipVisible: false,
    tooltipPosition: null,
    tooltipText: null,
  );
  
  // MUST cancel tooltip timer
  _tooltipHideTimer?.cancel();
  _tooltipHideTimer = null;
}
```

**Postconditions**:
- `isCrosshairVisible == false`
- `crosshairPosition == null`
- All tooltip fields cleared
- Tooltip timer cancelled
- Zero widget rebuilds triggered

---

### 2. Pointer Down/Up Events

#### _onPointerDown(PointerDownEvent event)
**Trigger**: Mouse button pressed or touch starts  
**Responsibility**: Initiate pan gesture, record start position

**Contract**:
```dart
void _onPointerDown(PointerDownEvent event) {
  final localPosition = _globalToLocal(event.position);
  if (localPosition == null) return;
  
  // MUST update notifier (not setState)
  _interactionStateNotifier.value = _interactionStateNotifier.value.copyWith(
    isPanning: true,
    panStartPosition: localPosition,
    panCurrentPosition: localPosition,
  );
}
```

**Postconditions**:
- `isPanning == true`
- `panStartPosition == localPosition`
- `panCurrentPosition == localPosition`
- Zero widget rebuilds triggered

---

#### _onPointerUp(PointerUpEvent event)
**Trigger**: Mouse button released or touch ends  
**Responsibility**: End pan gesture, optionally trigger pan animation

**Contract**:
```dart
void _onPointerUp(PointerUpEvent event) {
  // MUST update notifier (not setState)
  _interactionStateNotifier.value = _interactionStateNotifier.value.copyWith(
    isPanning: false,
    panStartPosition: null,
    panCurrentPosition: null,
  );
  
  // MAY trigger pan animation if velocity sufficient
  if (_hasSufficientVelocity()) {
    _startPanAnimation();
  }
}
```

**Postconditions**:
- `isPanning == false`
- Pan positions cleared
- Pan animation started if velocity sufficient
- Zero widget rebuilds triggered

---

### 3. Pointer Move Events

#### _onPointerMove(PointerMoveEvent event)
**Trigger**: Mouse dragged or touch moved (button/touch active)  
**Responsibility**: Update pan position during drag

**Contract**:
```dart
void _onPointerMove(PointerMoveEvent event) {
  // MUST check if panning active
  if (!_interactionStateNotifier.value.isPanning) return;
  
  final localPosition = _globalToLocal(event.position);
  if (localPosition == null) return;
  
  // MUST update notifier (not setState)
  _interactionStateNotifier.value = _interactionStateNotifier.value.copyWith(
    panCurrentPosition: localPosition,
  );
}
```

**Postconditions**:
- `panCurrentPosition == localPosition` (if panning active)
- Zero widget rebuilds triggered

---

### 4. Scroll/Zoom Events

#### _onPointerSignal(PointerSignalEvent event)
**Trigger**: Mouse wheel or trackpad scroll  
**Responsibility**: Update zoom level, trigger zoom animation

**Contract**:
```dart
void _onPointerSignal(PointerSignalEvent event) {
  if (event is! PointerScrollEvent) return;
  
  // MUST calculate zoom delta
  final scrollDelta = event.scrollDelta.dy;
  final zoomFactor = scrollDelta > 0 ? 0.9 : 1.1;
  final newZoomLevel = (_interactionStateNotifier.value.zoomLevel * zoomFactor)
      .clamp(widget.interactionConfig?.minZoom ?? 0.1, widget.interactionConfig?.maxZoom ?? 10.0);
  
  final localPosition = _globalToLocal(event.position);
  
  // MUST update notifier (not setState)
  _interactionStateNotifier.value = _interactionStateNotifier.value.copyWith(
    isZooming: true,
    zoomLevel: newZoomLevel,
    zoomFocalPoint: localPosition,
  );
  
  // MUST trigger zoom animation
  _startZoomAnimation(newZoomLevel);
}
```

**Postconditions**:
- `zoomLevel` updated within configured bounds
- `isZooming == true`
- `zoomFocalPoint == localPosition`
- Zoom animation started
- Zero widget rebuilds triggered

---

### 5. Keyboard Events (if supported)

#### _onKeyEvent(KeyEvent event)
**Trigger**: Keyboard key pressed/released  
**Responsibility**: Update modifier key state (Ctrl, Shift, etc.)

**Contract**:
```dart
void _onKeyEvent(KeyEvent event) {
  final pressedKeys = Set<LogicalKeyboardKey>.from(
    _interactionStateNotifier.value.pressedKeys,
  );
  
  if (event is KeyDownEvent) {
    pressedKeys.add(event.logicalKey);
  } else if (event is KeyUpEvent) {
    pressedKeys.remove(event.logicalKey);
  }
  
  // MUST update notifier (not setState)
  _interactionStateNotifier.value = _interactionStateNotifier.value.copyWith(
    pressedKeys: pressedKeys,
  );
}
```

**Postconditions**:
- `pressedKeys` updated with current key state
- Zero widget rebuilds triggered

---

## Common Patterns & Requirements

### Pattern 1: Coordinate Conversion

**All handlers receiving pointer events MUST**:
```dart
// Extract RenderBox safely
final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
if (renderBox == null) return; // Early return if not mounted

// Convert to local coordinates
final Offset localPosition = renderBox.globalToLocal(event.position);
```

**Why**: Global coordinates meaningless for chart rendering, local coordinates required for data mapping.

---

### Pattern 2: Notifier Update (Never setState)

**All handlers MUST**:
```dart
// ❌ FORBIDDEN - Never use setState
_safeSetState(() {
  _interactionState = _interactionState.copyWith(...);
});

// ✅ REQUIRED - Always update notifier directly
_interactionStateNotifier.value = _interactionStateNotifier.value.copyWith(
  field: newValue,
);
```

**Why**: setState causes widget rebuilds → MouseTracker crashes. ValueNotifier only notifies listeners.

---

### Pattern 3: Immutable Updates (copyWith)

**All state updates MUST**:
```dart
// ❌ FORBIDDEN - Never mutate state directly
_interactionState.crosshairPosition = newPosition; // Won't compile (final fields)

// ✅ REQUIRED - Always use copyWith for immutable updates
_interactionStateNotifier.value = _interactionStateNotifier.value.copyWith(
  crosshairPosition: newPosition,
  // Only specify changed fields, others preserved
);
```

**Why**: InteractionState is immutable, ValueNotifier requires new reference for notifications.

---

### Pattern 4: Null Safety

**All handlers MUST**:
```dart
// Check nullable fields before use
if (localPosition == null) return;
if (renderBox == null) return;

// Use null-aware operators
_tooltipHideTimer?.cancel();

// Explicitly set null to clear state
crosshairPosition: null,  // Clear position
```

**Why**: Dart null safety requires explicit handling, prevents runtime errors.

---

## Testing Contract

### Unit Test Requirements

**Each handler MUST have**:
1. Test verifying notifier update (not setState)
2. Test verifying correct fields updated
3. Test verifying other fields preserved (copyWith selectivity)
4. Test verifying null safety handling
5. Test verifying zero widget rebuilds

**Example Test Template**:
```dart
testWidgets('_onHover updates notifier without setState', (tester) async {
  await tester.pumpWidget(BravenChart(...));
  final state = tester.state<_BravenChartState>(find.byType(BravenChart));
  
  // Track rebuild count
  int buildCount = 0;
  state.addListener(() => buildCount++);
  
  // Simulate hover event
  await tester.sendEventToBinding(PointerHoverEvent(
    position: const Offset(100, 200),
  ));
  await tester.pump();
  
  // Assert notifier updated
  expect(state._interactionStateNotifier.value.isCrosshairVisible, isTrue);
  expect(state._interactionStateNotifier.value.crosshairPosition, isNotNull);
  
  // Assert zero rebuilds
  expect(buildCount, equals(0));
});
```

---

## Performance Contract

**All handlers MUST**:
1. Complete in <1ms (non-blocking)
2. Trigger zero widget rebuilds
3. Update only changed fields (copyWith selectivity)
4. Handle high-frequency events (>100 events/second) without degradation

**Performance Validation**:
```dart
testWidgets('Handlers maintain performance under high frequency', (tester) async {
  await tester.pumpWidget(BravenChart(...));
  
  final stopwatch = Stopwatch()..start();
  
  // Send 1000 events
  for (int i = 0; i < 1000; i++) {
    await tester.sendEventToBinding(PointerHoverEvent(
      position: Offset(i.toDouble(), 100),
    ));
  }
  
  stopwatch.stop();
  
  // Assert average <1ms per event
  expect(stopwatch.elapsedMilliseconds / 1000, lessThan(1.0));
});
```

---

## Migration Checklist

For each handler being refactored:

- [ ] Remove all `setState()` calls
- [ ] Remove all `_safeSetState()` calls
- [ ] Update to use `_interactionStateNotifier.value = ...`
- [ ] Use `copyWith()` for immutable updates
- [ ] Add null safety checks
- [ ] Verify coordinate conversion
- [ ] Write unit tests (5 minimum per handler)
- [ ] Run performance validation
- [ ] Verify zero widget rebuilds
- [ ] Update inline documentation

---

## Summary

**Total Handlers**: 11+  
**Pattern**: Direct notifier update, zero setState  
**Performance**: <1ms per handler, zero rebuilds  
**Testing**: 90% coverage, performance validation  
**Migration**: Systematic refactor following checklist  

**Key Principle**: Event handlers are state update mechanisms, not widget rebuild triggers. ValueNotifier decouples state changes from widget lifecycle.
