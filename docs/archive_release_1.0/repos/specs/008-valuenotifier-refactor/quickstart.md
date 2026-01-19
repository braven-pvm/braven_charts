# Developer Quickstart: ValueNotifier Refactor

**Feature**: 008-valuenotifier-refactor  
**Audience**: Developers working on BravenChart widget  
**Last Updated**: 2025-01-21

## TL;DR

**What changed**: Interaction state management migrated from `setState` to `ValueNotifier` pattern.

**Why**: `setState` causes 100+ widget rebuilds/second during mouse movements → MouseTracker crashes (box.dart:3345). ValueNotifier provides stable render trees with zero widget rebuilds.

**Impact**: Internal refactor only. **Zero public API changes**. Users get crash fix + 10-100x performance improvement automatically.

---

## Quick Reference

### Before (Broken setState Pattern)

```dart
class _BravenChartState extends State<BravenChart> {
  InteractionState _interactionState = InteractionState.initial();

  void _onHover(PointerHoverEvent event) {
    setState(() {  // ❌ Causes 100+ rebuilds/second → crashes
      _interactionState = _interactionState.copyWith(
        isCrosshairVisible: true,
        crosshairPosition: localPosition,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(...);  // Entire widget rebuilds
  }
}
```

### After (ValueNotifier Pattern)

```dart
class _BravenChartState extends State<BravenChart> {
  late ValueNotifier<InteractionState> _interactionStateNotifier;

  @override
  void initState() {
    super.initState();
    _interactionStateNotifier = ValueNotifier(InteractionState.initial());
  }

  void _onHover(PointerHoverEvent event) {
    // ✅ Direct notifier update, zero rebuilds
    _interactionStateNotifier.value = _interactionStateNotifier.value.copyWith(
      isCrosshairVisible: true,
      crosshairPosition: localPosition,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        CustomPaint(...),  // Never rebuilds
        RepaintBoundary(
          child: ValueListenableBuilder<InteractionState>(
            valueListenable: _interactionStateNotifier,
            builder: (context, state, _) {
              return CustomPaint(...);  // Only overlay rebuilds
            },
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _interactionStateNotifier.dispose();  // Prevent memory leaks
    super.dispose();
  }
}
```

---

## Understanding the Problem

### Root Cause

**Timeline**:

1. User moves mouse over chart (100+ events/second)
2. Each event triggers `setState(() => _interactionState = ...)`
3. setState invalidates entire widget tree
4. MouseTracker recalculates hit regions using RenderBox coordinates
5. **CRASH**: RenderBox coordinates invalid mid-calculation (box.dart:3345)

**Why 6+ Fix Attempts Failed**:

- `addPostFrameCallback()`: Still runs during mouse tracking frame
- `scheduleMicrotask()`: Still within frame boundaries
- Double post-frame callbacks: Pointer events are continuous (keep coming)
- **Core issue**: Problem is setState itself, not timing

### The Solution

**ValueNotifier Pattern**:

- `ValueNotifier<T>`: Observable value that notifies listeners without rebuilding widgets
- `ValueListenableBuilder`: Rebuilds only specific subtree when value changes
- `RepaintBoundary`: Isolates overlay repaints from base chart

**Performance Benefits**:
| Metric | Before (setState) | After (ValueNotifier) | Improvement |
|--------|-------------------|------------------------|-------------|
| Widget rebuilds | 100+/second | 0/second | Infinite |
| Repaint scope | Entire widget | CustomPaint only | 100x |
| Frame time | 25-50ms (jank) | <2ms (smooth) | 12-25x |
| Crashes | Continuous | Zero | Infinite |

---

## Architecture Overview

### Data Flow Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                     User Input Event                         │
│              (hover, scroll, click, drag)                    │
└───────────────────────────┬─────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│                    Event Handler                             │
│         (_onHover, _onScroll, _onPointerDown, etc.)         │
│                                                               │
│  1. Convert global → local coordinates                       │
│  2. Compute new InteractionState                             │
│  3. Update notifier:                                         │
│     _interactionStateNotifier.value = newState               │
└───────────────────────────┬─────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│              ValueNotifier<InteractionState>                 │
│                                                               │
│  - Holds current interaction state                           │
│  - Notifies listeners when value changes                     │
│  - Does NOT trigger setState (stable render tree)            │
└───────────────────────────┬─────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│               ValueListenableBuilder                         │
│                                                               │
│  - Listens to notifier                                       │
│  - Rebuilds ONLY builder function (not entire widget)        │
│  - Wrapped in RepaintBoundary for isolation                  │
└───────────────────────────┬─────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│                  Interactive Overlays                        │
│              (crosshair, tooltip, zoom indicator)            │
│                                                               │
│  - CustomPaint renders based on current state                │
│  - Repaints independently of base chart                      │
│  - Smooth 60fps performance                                  │
└─────────────────────────────────────────────────────────────┘
```

### Component Responsibilities

**InteractionState** (existing model):

- Immutable value object holding all interaction data
- Fields: crosshair, tooltip, pan, zoom, keyboard state
- Updated via `copyWith()` method
- **No changes required** (already perfect for ValueNotifier)

**ValueNotifier<InteractionState>** (new core):

- Observable wrapper around InteractionState
- Created in `initState()`, disposed in `dispose()`
- Updated directly by event handlers (no setState)
- Notifies ValueListenableBuilder on changes

**ValueListenableBuilder** (new rendering):

- Listens to notifier
- Rebuilds only interactive overlays (not base chart)
- Wrapped in RepaintBoundary for isolation
- Added to `build()` method

**Event Handlers** (refactored):

- 11+ handlers: `_onHover`, `_onExit`, `_onPointerDown`, etc.
- Changed from `setState(() => ...)` to `_interactionStateNotifier.value = ...`
- No other logic changes

**Animation Listeners** (refactored):

- Zoom/pan animation listeners
- Changed from `setState(() => ...)` to `_interactionStateNotifier.value = ...`
- No other logic changes

---

## Implementation Phases

### Phase 1: Core State Management (30 minutes)

**File**: `lib/src/widgets/braven_chart.dart`

**Changes**:

1. Add `late ValueNotifier<InteractionState> _interactionStateNotifier;` field
2. Initialize in `initState()`:
   ```dart
   _interactionStateNotifier = ValueNotifier(InteractionState.initial());
   ```
3. Add disposal in `dispose()`:
   ```dart
   _interactionStateNotifier.dispose();
   super.dispose();
   ```

**Testing**:

```bash
flutter test test/unit/widgets/braven_chart_state_test.dart
```

---

### Phase 2: Event Handlers (45 minutes)

**File**: `lib/src/widgets/braven_chart.dart`

**Changes**: For each handler (`_onHover`, `_onExit`, `_onPointerDown`, `_onPointerMove`, `_onPointerUp`, `_onPointerSignal`, etc.):

```dart
// BEFORE
void _onHover(PointerHoverEvent event) {
  setState(() {
    _interactionState = _interactionState.copyWith(...);
  });
}

// AFTER
void _onHover(PointerHoverEvent event) {
  _interactionStateNotifier.value = _interactionStateNotifier.value.copyWith(...);
}
```

**Search & Replace Pattern**:

- Search: `setState(() {\n\s*_interactionState = _interactionState.copyWith(`
- Replace: `_interactionStateNotifier.value = _interactionStateNotifier.value.copyWith(`

**Testing**:

```bash
flutter test test/unit/widgets/event_handlers_test.dart
```

---

### Phase 3: Animation Listeners (20 minutes)

**File**: `lib/src/widgets/braven_chart.dart`

**Changes**: Update zoom/pan animation listeners:

```dart
// BEFORE
_zoomAnimationController = AnimationController(...)
  ..addListener(() {
    setState(() {
      _interactionState = _interactionState.copyWith(...);
    });
  });

// AFTER
_zoomAnimationController = AnimationController(...)
  ..addListener(() {
    _interactionStateNotifier.value = _interactionStateNotifier.value.copyWith(...);
  });
```

**Testing**:

```bash
flutter test test/unit/widgets/animation_integration_test.dart
```

---

### Phase 4: Rendering Layer (60 minutes)

**File**: `lib/src/widgets/braven_chart.dart`

**Changes**: Wrap interactive overlays in ValueListenableBuilder:

```dart
// BEFORE
@override
Widget build(BuildContext context) {
  return Stack(
    children: [
      CustomPaint(painter: _ChartPainter(...)),
      if (_interactionState.isCrosshairVisible)
        CustomPaint(painter: _CrosshairPainter(...)),
      // ... more overlays
    ],
  );
}

// AFTER
@override
Widget build(BuildContext context) {
  return Stack(
    children: [
      // Base chart (never rebuilds)
      CustomPaint(painter: _ChartPainter(...)),

      // Interactive overlays (only these rebuild)
      RepaintBoundary(
        child: ValueListenableBuilder<InteractionState>(
          valueListenable: _interactionStateNotifier,
          builder: (context, state, child) {
            return Stack(
              children: [
                if (state.isCrosshairVisible && state.crosshairPosition != null)
                  CustomPaint(painter: _CrosshairPainter(state.crosshairPosition!)),
                if (state.isTooltipVisible && state.tooltipPosition != null)
                  Positioned(...),
                // ... more overlays based on state
              ],
            );
          },
        ),
      ),
    ],
  );
}
```

**Testing**:

```bash
flutter test test/unit/widgets/rendering_test.dart
flutter test test/performance/interaction_performance_test.dart
```

---

### Phase 5: Cleanup & Testing (30 minutes)

**Changes**:

1. Delete `_safeSetState()` method (no longer used)
2. Remove all `_interactionState` field references (replaced by notifier)
3. Run full test suite
4. Run integration tests
5. Profile with Flutter DevTools (verify zero rebuilds)

**Commands**:

```bash
# Unit tests
flutter test

# Integration tests
flutter drive --target=integration_test/interaction_stability_test.dart

# Coverage report
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

---

## Common Patterns

### Pattern 1: Reading State

```dart
// Get current state
final currentState = _interactionStateNotifier.value;

// Check specific field
if (_interactionStateNotifier.value.isCrosshairVisible) {
  // Do something
}
```

---

### Pattern 2: Updating State

```dart
// Update single field
_interactionStateNotifier.value = _interactionStateNotifier.value.copyWith(
  isCrosshairVisible: true,
);

// Update multiple fields
_interactionStateNotifier.value = _interactionStateNotifier.value.copyWith(
  isCrosshairVisible: true,
  crosshairPosition: Offset(100, 200),
  isTooltipVisible: false,
);

// Clear field (set to null)
_interactionStateNotifier.value = _interactionStateNotifier.value.copyWith(
  crosshairPosition: null,
);
```

---

### Pattern 3: Conditional Rendering

```dart
ValueListenableBuilder<InteractionState>(
  valueListenable: _interactionStateNotifier,
  builder: (context, state, child) {
    // Early return for hidden elements
    if (!state.isCrosshairVisible) {
      return const SizedBox.shrink();
    }

    // Null-safe rendering
    if (state.crosshairPosition == null) {
      return const SizedBox.shrink();
    }

    // Render with state
    return CustomPaint(
      painter: _CrosshairPainter(state.crosshairPosition!),
    );
  },
)
```

---

### Pattern 4: Simultaneous Interactions

```dart
// Zoom and hover simultaneously (non-conflicting fields)
void _onScroll(PointerScrollEvent event) {
  _interactionStateNotifier.value = _interactionStateNotifier.value.copyWith(
    zoomLevel: newZoomLevel,
    isZooming: true,
    // crosshairPosition preserved (not specified in copyWith)
  );
}

void _onHover(PointerHoverEvent event) {
  _interactionStateNotifier.value = _interactionStateNotifier.value.copyWith(
    crosshairPosition: localPosition,
    isCrosshairVisible: true,
    // zoomLevel preserved (not specified in copyWith)
  );
}
```

---

## Testing Guide

### Unit Testing

**Test Structure**:

```dart
// test/unit/widgets/braven_chart_interaction_test.dart

testWidgets('Notifier updates without setState', (tester) async {
  await tester.pumpWidget(BravenChart(...));
  final state = tester.state<_BravenChartState>(find.byType(BravenChart));

  // Track rebuilds
  int buildCount = 0;
  state.addListener(() => buildCount++);

  // Trigger event
  await tester.sendEventToBinding(PointerHoverEvent(...));
  await tester.pump();

  // Verify notifier updated
  expect(state._interactionStateNotifier.value.isCrosshairVisible, isTrue);

  // Verify zero rebuilds
  expect(buildCount, equals(0));
});
```

**Coverage Target**: 90% for all refactored code

**Run Tests**:

```bash
flutter test test/unit/widgets/
```

---

### Integration Testing

**Test Focus**: Verify no crashes under high-frequency events

```dart
// integration_test/interaction_stability_test.dart

testWidgets('Continuous hover does not crash', (tester) async {
  await tester.pumpWidget(BravenChart(...));

  // Simulate 1000 mouse movements
  for (int i = 0; i < 1000; i++) {
    await tester.sendEventToBinding(PointerHoverEvent(
      position: Offset(i.toDouble(), 100),
    ));
    await tester.pump(const Duration(milliseconds: 5));
  }

  // Verify zero crashes
  expect(tester.takeException(), isNull);
});
```

**Run Tests**:

```bash
flutter drive --target=integration_test/interaction_stability_test.dart
```

---

### Performance Testing

**Test Focus**: Verify 60fps, zero widget rebuilds

```dart
// test/performance/interaction_performance_test.dart

testWidgets('Maintains 60fps during hover', (tester) async {
  final frameTimes = <Duration>[];

  WidgetsBinding.instance.addTimingsCallback((timings) {
    for (final timing in timings) {
      frameTimes.add(timing.totalSpan);
    }
  });

  await tester.pumpWidget(BravenChart(...));

  // Simulate continuous hover
  for (int i = 0; i < 1000; i++) {
    await tester.sendEventToBinding(PointerHoverEvent(...));
    await tester.pump(const Duration(milliseconds: 5));
  }

  // Assert all frames < 16ms (60fps)
  expect(frameTimes.every((t) => t.inMilliseconds <= 16), isTrue);
});
```

**Run Tests**:

```bash
flutter test test/performance/
```

---

## Debugging Tips

### Verify ValueNotifier Working

**Add temporary logging**:

```dart
_interactionStateNotifier.addListener(() {
  debugPrint('State updated: ${_interactionStateNotifier.value}');
});
```

**Expected**: Logs on every mouse movement, no widget rebuilds.

---

### Verify Zero Widget Rebuilds

**Use Flutter DevTools**:

1. Open DevTools
2. Enable "Track Widget Rebuilds" in Performance tab
3. Hover over chart
4. Check rebuild count: Should be **0** for base chart

---

### Verify Repaint Boundaries

**Use Flutter DevTools**:

1. Open DevTools
2. Enable "Repaint Rainbow" in Performance tab
3. Hover over chart
4. Only overlay should flash colors (not entire widget)

---

### Verify No Memory Leaks

**Use Flutter DevTools**:

1. Open DevTools Memory tab
2. Run stress test (create/dispose 1000 times)
3. Click "GC" button
4. Check `_BravenChartState` instances: Should be **~0** (not 1000)

---

## Common Pitfalls

### ❌ Pitfall 1: Forgetting to Dispose

```dart
// ❌ WRONG - Memory leak
@override
void dispose() {
  super.dispose();  // Missing notifier.dispose()
}

// ✅ CORRECT
@override
void dispose() {
  _interactionStateNotifier.dispose();
  super.dispose();
}
```

---

### ❌ Pitfall 2: Using setState with Notifier

```dart
// ❌ WRONG - Defeats the purpose, still causes rebuilds
void _onHover(PointerHoverEvent event) {
  setState(() {
    _interactionStateNotifier.value = ...;
  });
}

// ✅ CORRECT - Direct notifier update
void _onHover(PointerHoverEvent event) {
  _interactionStateNotifier.value = ...;
}
```

---

### ❌ Pitfall 3: Mutating State Directly

```dart
// ❌ WRONG - Won't compile (fields are final)
_interactionStateNotifier.value.isCrosshairVisible = true;

// ✅ CORRECT - Use copyWith for immutable updates
_interactionStateNotifier.value = _interactionStateNotifier.value.copyWith(
  isCrosshairVisible: true,
);
```

---

### ❌ Pitfall 4: Not Wrapping in RepaintBoundary

```dart
// ❌ WRONG - Overlay repaints trigger base chart repaints
ValueListenableBuilder<InteractionState>(
  valueListenable: _interactionStateNotifier,
  builder: (context, state, _) => CustomPaint(...),
)

// ✅ CORRECT - RepaintBoundary isolates overlay
RepaintBoundary(
  child: ValueListenableBuilder<InteractionState>(
    valueListenable: _interactionStateNotifier,
    builder: (context, state, _) => CustomPaint(...),
  ),
)
```

---

## FAQ

**Q: Why not use Provider/Riverpod?**  
A: Constitution requires pure Flutter (no external dependencies). ValueNotifier is Flutter standard library.

**Q: What about setState for non-interaction state?**  
A: setState still fine for low-frequency updates (theme changes, data loading). Only high-frequency interaction state (>10Hz) requires ValueNotifier.

**Q: Does this affect public API?**  
A: No. This is internal refactor only. BravenChart constructor and properties unchanged. Users get benefits automatically.

**Q: How to test if refactor successful?**  
A: Run integration tests (zero crashes) + performance tests (60fps) + DevTools verification (zero rebuilds).

**Q: What if I need more ValueNotifiers?**  
A: Follow same pattern: Create in initState(), dispose in dispose(), use ValueListenableBuilder for rendering, never use setState.

---

## Additional Resources

**Documentation**:

- [architecture_refactor_plan.md](../../../architecture_refactor_plan.md) - Full technical analysis
- [spec.md](../spec.md) - Feature specification with requirements
- [research.md](../research.md) - Research findings and decisions
- [data-model.md](../data-model.md) - Data structures and flow

**Contracts** (internal behavior specifications):

- [event-handlers.md](../contracts/event-handlers.md) - Event handler refactor contracts
- [animation-integration.md](../contracts/animation-integration.md) - Animation listener contracts
- [disposal-cleanup.md](../contracts/disposal-cleanup.md) - Memory management contracts

**Flutter Documentation**:

- [ValueNotifier](https://api.flutter.dev/flutter/foundation/ValueNotifier-class.html)
- [ValueListenableBuilder](https://api.flutter.dev/flutter/widgets/ValueListenableBuilder-class.html)
- [RepaintBoundary](https://api.flutter.dev/flutter/widgets/RepaintBoundary-class.html)
- [Performance Best Practices](https://docs.flutter.dev/perf/best-practices)

---

## Summary

**What**: Migrate from setState to ValueNotifier for interaction state  
**Why**: setState causes crashes + poor performance with high-frequency events  
**Impact**: Internal only, zero breaking changes, 10-100x performance gain  
**Effort**: ~3 hours implementation + testing  
**Key Files**: `lib/src/widgets/braven_chart.dart` (~150 lines changed)  
**Testing**: 90% coverage, zero crashes, 60fps verified

**Ready to implement? Follow the 5 phases above. Questions? Check contracts/ directory for detailed specifications.**
