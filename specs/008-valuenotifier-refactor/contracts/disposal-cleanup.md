# Internal Contracts: Disposal & Cleanup

**Feature**: 008-valuenotifier-refactor  
**Phase**: 1 - Design & Contracts  
**Contract Type**: Internal Widget Behavior  
**Scope**: Resource management in `_BravenChartState`  

## Overview

This contract defines the comprehensive disposal strategy for all resources managed by BravenChart widget. Proper disposal prevents memory leaks by ensuring all listeners, controllers, timers, and notifiers are cleaned up when widget is destroyed. This is **critical for production stability** given the high-frequency nature of interaction events.

---

## Disposal Contract

### Master Disposal Method

**Signature**:
```dart
@override
void dispose() {
  // Phase 1: Cancel timers (prevent callbacks during disposal)
  _cancelTooltipTimer();
  
  // Phase 2: Dispose animation controllers (stop tickers, remove listeners)
  _disposeAnimationControllers();
  
  // Phase 3: Dispose ValueNotifier (release all listeners)
  _disposeNotifier();
  
  // Phase 4: Framework cleanup
  super.dispose();
}
```

**Disposal Order Contract**:
1. **Timers first**: Prevent callbacks from firing during disposal
2. **Animation controllers second**: Stop animations and tickers before state disposal
3. **ValueNotifier third**: Dispose after all writers stopped
4. **super.dispose() last**: Framework cleanup after all resources released

**Why Order Matters**:
- Timers/callbacks may access notifier → cancel before notifier disposal
- Animation listeners may access notifier → dispose controllers before notifier
- Framework expects widget state valid until super.dispose() → dispose custom resources first

---

## Phase 1: Timer Disposal

### Contract: _cancelTooltipTimer()

**Purpose**: Cancel tooltip hide timer to prevent callback from executing after disposal.

**Implementation**:
```dart
void _cancelTooltipTimer() {
  _tooltipHideTimer?.cancel();
  _tooltipHideTimer = null;
}
```

**Requirements**:
- **MUST** use null-aware call operator (`?.`) for safe cancellation
- **MUST** set to null after cancellation (prevents double-cancel)
- **MUST** call before notifier disposal (callback may access notifier)

**Consequences of Skipping**:
- Timer callback fires after disposal → attempts to update disposed notifier
- Crash: "A ValueNotifier was used after being disposed"
- Memory leak: Timer holds reference to widget state

---

### Timer Inventory

| Timer | Purpose | Callback Risk | Disposal Required |
|-------|---------|---------------|-------------------|
| `_tooltipHideTimer` | Hides tooltip after delay | Updates notifier with `isTooltipVisible: false` | ✅ YES |

**Future Timers**: If additional timers added, MUST follow same disposal pattern.

---

## Phase 2: Animation Controller Disposal

### Contract: _disposeAnimationControllers()

**Purpose**: Stop animations, remove listeners, and release ticker resources.

**Implementation**:
```dart
void _disposeAnimationControllers() {
  // Explicitly remove listeners (defensive, controller.dispose() also does this)
  _zoomAnimation.removeListener(_onZoomAnimationUpdate);
  _panAnimation.removeListener(_onPanAnimationUpdate);
  
  // Dispose controllers (stops tickers, removes listeners, releases resources)
  _zoomAnimationController.dispose();
  _panAnimationController.dispose();
}
```

**Requirements**:
- **MUST** dispose all AnimationController instances
- **SHOULD** explicitly remove listeners (defensive programming)
- **MUST** call before notifier disposal (listeners may access notifier)
- **MUST NOT** access controllers after disposal

**Consequences of Skipping**:
- Ticker keeps running → wasted CPU cycles
- Listeners not removed → memory leak (controllers hold widget reference)
- Animation listener fires after disposal → attempts to update disposed notifier

---

### Controller Inventory

| Controller | Purpose | Listener | Disposal Required |
|------------|---------|----------|-------------------|
| `_zoomAnimationController` | Zoom interpolation | `_onZoomAnimationUpdate` | ✅ YES |
| `_panAnimationController` | Pan momentum | `_onPanAnimationUpdate` | ✅ YES |

**Future Controllers**: If additional controllers added, MUST follow same disposal pattern.

---

## Phase 3: ValueNotifier Disposal

### Contract: _disposeNotifier()

**Purpose**: Release all listeners registered to ValueNotifier and mark as disposed.

**Implementation**:
```dart
void _disposeNotifier() {
  _interactionStateNotifier.dispose();
}
```

**Requirements**:
- **MUST** call after timers cancelled (callbacks may update notifier)
- **MUST** call after controllers disposed (listeners may update notifier)
- **MUST NOT** access notifier after disposal (throws exception)
- **MUST** dispose even if no listeners (releases internal resources)

**Consequences of Skipping**:
- Listeners not removed → memory leak (notifier holds widget reference via ValueListenableBuilder)
- ValueNotifier marked as active → prevents garbage collection
- Memory usage grows with each BravenChart creation/disposal cycle

---

### Notifier Inventory

| Notifier | Purpose | Listeners | Disposal Required |
|----------|---------|-----------|-------------------|
| `_interactionStateNotifier` | Interaction state management | ValueListenableBuilder in build() | ✅ YES |

**Future Notifiers**: If additional notifiers added, MUST follow same disposal pattern.

---

## Phase 4: Framework Disposal

### Contract: super.dispose()

**Purpose**: Invoke framework's disposal logic for StatefulWidget.

**Implementation**:
```dart
@override
void dispose() {
  // Custom resource cleanup (phases 1-3)
  _cancelTooltipTimer();
  _disposeAnimationControllers();
  _disposeNotifier();
  
  // Framework cleanup (MUST be last)
  super.dispose();
}
```

**Requirements**:
- **MUST** call super.dispose() last (after all custom cleanup)
- **MUST NOT** skip super.dispose() (framework cleanup not executed)
- **MUST** call even if error during custom cleanup (use try-finally if needed)

**Consequences of Skipping**:
- Framework disposal logic not executed
- Widget remains in widget tree tracking structures
- Element not removed from BuildContext
- Memory leak in Flutter framework internals

---

## Memory Leak Detection

### Detection Strategy

**Flutter DevTools Memory Tab**:
1. Open Flutter DevTools
2. Navigate to Memory tab
3. Perform stress test:
   ```dart
   // Create and dispose BravenChart 1000 times
   for (int i = 0; i < 1000; i++) {
     await tester.pumpWidget(BravenChart(...));
     await tester.pumpWidget(Container()); // Dispose
     if (i % 100 == 0) {
       // Force GC every 100 iterations
       await tester.runAsync(() => Future.delayed(Duration(milliseconds: 100)));
     }
   }
   ```
4. Click "GC" button (garbage collect)
5. Check snapshot: `_BravenChartState` instances should be ~0 (not 1000)

**Expected Results**:
- ✅ PASS: 0-2 `_BravenChartState` instances (GC may lag slightly)
- ❌ FAIL: Hundreds of `_BravenChartState` instances (memory leak confirmed)

---

### Common Leak Sources

| Leak Source | Symptom | Detection | Fix |
|-------------|---------|-----------|-----|
| **Undisposed ValueNotifier** | Growing memory, listeners retained | DevTools shows many notifier instances | Call `dispose()` in dispose() |
| **Undisposed AnimationController** | CPU usage, ticker keeps running | DevTools shows active tickers | Call `dispose()` on all controllers |
| **Uncancelled Timer** | Callback fires after disposal | Crash: "used after being disposed" | Call `cancel()` on all timers |
| **External listeners** | Widget retained by external objects | DevTools shows widget held by listener | Document that external code must deregister |

---

## Testing Contract

### Unit Test Requirements

**Disposal MUST have**:
1. Test verifying all resources disposed
2. Test verifying disposal order
3. Test verifying no crashes on double-dispose
4. Test verifying notifier unusable after disposal
5. Memory leak stress test (1000 create/dispose cycles)

**Example Test Template**:
```dart
testWidgets('dispose() cleans up all resources', (tester) async {
  await tester.pumpWidget(BravenChart(...));
  final state = tester.state<_BravenChartState>(find.byType(BravenChart));
  
  // Capture references before disposal
  final notifier = state._interactionStateNotifier;
  final zoomController = state._zoomAnimationController;
  final panController = state._panAnimationController;
  
  // Dispose widget
  await tester.pumpWidget(Container());
  
  // Verify resources disposed
  expect(() => notifier.value, throwsFlutterError); // Notifier disposed
  expect(() => zoomController.forward(), throwsFlutterError); // Controller disposed
  expect(() => panController.forward(), throwsFlutterError); // Controller disposed
});

testWidgets('No memory leak after 1000 cycles', (tester) async {
  // Get baseline memory usage
  final initialInstances = _BravenChartStateInstanceCount(); // Hypothetical counter
  
  // Stress test: create/dispose 1000 times
  for (int i = 0; i < 1000; i++) {
    await tester.pumpWidget(BravenChart(...));
    await tester.pumpWidget(Container());
  }
  
  // Force GC
  await tester.runAsync(() => Future.delayed(Duration(milliseconds: 500)));
  
  // Verify no leaks (allow some GC lag)
  final finalInstances = _BravenChartStateInstanceCount();
  expect(finalInstances - initialInstances, lessThan(10)); // <10 instances leaked
});

testWidgets('Double dispose does not crash', (tester) async {
  await tester.pumpWidget(BravenChart(...));
  final state = tester.state<_BravenChartState>(find.byType(BravenChart));
  
  // First disposal (via pumpWidget)
  await tester.pumpWidget(Container());
  
  // Second disposal (manual, should not crash)
  expect(() => state.dispose(), returnsNormally);
});
```

---

## Null Safety Contract

### Nullable Field Handling

**All fields that may be null MUST**:
1. Use null-aware operators for disposal
2. Set to null after disposal (defensive)
3. Check for null before accessing after potential disposal

**Pattern**:
```dart
class _BravenChartState extends State<BravenChart> {
  Timer? _tooltipHideTimer;  // Nullable (may not be active)
  late AnimationController _zoomAnimationController;  // Non-nullable (always initialized)
  late ValueNotifier<InteractionState> _interactionStateNotifier;  // Non-nullable (always initialized)
  
  @override
  void dispose() {
    // Nullable field: use null-aware operator
    _tooltipHideTimer?.cancel();
    _tooltipHideTimer = null;
    
    // Non-nullable fields: direct call (initialized in initState)
    _zoomAnimationController.dispose();
    _panAnimationController.dispose();
    _interactionStateNotifier.dispose();
    
    super.dispose();
  }
}
```

**Why**:
- `late` fields guaranteed initialized before access (enforced by Dart)
- Nullable fields may or may not be set → require null-aware operators
- Setting to null after disposal prevents accidental re-use

---

## Error Handling Contract

### Graceful Degradation

**Disposal MUST NOT throw exceptions**:
```dart
@override
void dispose() {
  try {
    // Phase 1: Timers
    _tooltipHideTimer?.cancel();
    _tooltipHideTimer = null;
  } catch (e) {
    // Log error but continue disposal
    debugPrint('Error cancelling timer: $e');
  }
  
  try {
    // Phase 2: Controllers
    _zoomAnimationController.dispose();
    _panAnimationController.dispose();
  } catch (e) {
    debugPrint('Error disposing controllers: $e');
  }
  
  try {
    // Phase 3: Notifier
    _interactionStateNotifier.dispose();
  } catch (e) {
    debugPrint('Error disposing notifier: $e');
  }
  
  // Phase 4: Framework (MUST always call)
  super.dispose();
}
```

**Why**:
- Exception in disposal prevents subsequent cleanup steps
- Framework disposal (super.dispose) may be skipped → memory leak
- Defensive error handling ensures all cleanup attempted

**Note**: Current implementation (Phase F) does NOT require try-catch unless complex cleanup added in future.

---

## Migration Checklist

For disposal refactor:

- [ ] Identify all timers (search for `Timer`)
- [ ] Identify all animation controllers (search for `AnimationController`)
- [ ] Identify all ValueNotifiers (search for `ValueNotifier`)
- [ ] Implement `_cancelTooltipTimer()` helper
- [ ] Implement `_disposeAnimationControllers()` helper
- [ ] Implement `_disposeNotifier()` helper
- [ ] Update `dispose()` method with 4-phase pattern
- [ ] Verify disposal order (timers → controllers → notifier → super)
- [ ] Write unit tests (disposal verification, no double-dispose crash)
- [ ] Run memory leak stress test (1000 cycles)
- [ ] Verify with Flutter DevTools Memory tab
- [ ] Update inline documentation

---

## Summary

**Disposal Phases**: 4 (timers, controllers, notifier, framework)  
**Resources Managed**: 1 timer, 2 controllers, 1 notifier  
**Order Critical**: YES (callbacks/listeners may access disposed resources)  
**Testing**: Disposal verification, no-crash on double-dispose, memory leak stress test  
**Memory Leak Prevention**: Complete disposal eliminates all leak sources  

**Key Principle**: Disposal order matters. Resources that may trigger callbacks/listeners MUST be disposed before resources they access. Framework disposal MUST be last. Zero exceptions tolerated in disposal path.
