# Architecture Refactor Plan: ValueNotifier Pattern

**Date:** 2025-10-21  
**Issue:** Catastrophic rendering crashes with interaction system  
**Root Cause:** setState-based architecture incompatible with high-frequency pointer events  
**Solution:** Complete refactor to ValueNotifier pattern

---

## 🔍 ROOT CAUSE ANALYSIS

### Current Architecture (BROKEN)
```dart
// State stored as plain field
InteractionState _interactionState = InteractionState.initial();

// Updated via setState on EVERY mouse movement
void onHover(PointerHoverEvent event) {
  setState(() {  // ❌ FULL WIDGET REBUILD
    _interactionState = _interactionState.copyWith(
      crosshairPosition: localPosition,
    );
  });
}

// Rendered inline in build method
@override
Widget build(BuildContext context) {
  return Stack(
    children: [
      // Chart...
      if (_interactionState.isCrosshairVisible)  // ❌ Depends on state
        CustomPaint(painter: _CrosshairPainter(...)),
    ],
  );
}
```

### Why This Fails
1. **Mouse events = 100+ per second** (every pixel of movement)
2. **setState = full widget tree rebuild** (expensive)
3. **MouseTracker requires stable render tree** during hit testing
4. **Conflict:** We're rebuilding WHILE Flutter calculates mouse positions
5. **Result:** `box.dart:3345` and `mouse_tracker.dart:199` assertions fail

### Why Timing Fixes Failed
- ❌ `addPostFrameCallback()` - Still runs during mouse tracking phase
- ❌ `scheduleMicrotask()` - Still within rendering frame boundaries  
- ❌ Double post-frame - Pointer events are continuous across frames
- ❌ Any setState deferral - The problem is setState itself, not timing

---

## ✅ PROPER SOLUTION: ValueNotifier Pattern

### New Architecture (CORRECT)

```dart
// State stored in ValueNotifier (reactive)
final ValueNotifier<InteractionState> _interactionStateNotifier = 
    ValueNotifier(InteractionState.initial());

// Updated directly (NO setState)
void onHover(PointerHoverEvent event) {
  // Just update the value - notifies listeners automatically
  _interactionStateNotifier.value = _interactionStateNotifier.value.copyWith(
    crosshairPosition: localPosition,
  );
  // ✅ No widget rebuild!
  // ✅ Only overlay repaints!
}

// Rendered with ValueListenableBuilder (isolated)
@override
Widget build(BuildContext context) {
  return Stack(
    children: [
      // Base chart (NEVER rebuilds for interactions)
      _buildBaseChart(),
      
      // Interactive overlay (ONLY THIS repaints)
      RepaintBoundary(  // Isolate repaints
        child: ValueListenableBuilder<InteractionState>(
          valueListenable: _interactionStateNotifier,
          builder: (context, state, child) {
            if (!state.isCrosshairVisible) {
              return const SizedBox.shrink();
            }
            return CustomPaint(
              painter: _CrosshairPainter(state.crosshairPosition, ...),
            );
          },
        ),
      ),
    ],
  );
}
```

### Why This Works
1. ✅ **No setState** = no widget rebuilds
2. ✅ **Stable render tree** = MouseTracker happy
3. ✅ **Only CustomPainter repaints** = efficient (60fps)
4. ✅ **RepaintBoundary** = isolated layer
5. ✅ **Scales to 1000s of points** with continuous interactions

---

## 📋 IMPLEMENTATION CHECKLIST

### Phase 1: Core State Management (30 min)
- [ ] Add `ValueNotifier<InteractionState> _interactionStateNotifier`
- [ ] Remove `InteractionState _interactionState` field
- [ ] Add proper disposal in `dispose()`
- [ ] Update all reads from `_interactionState` to `_interactionStateNotifier.value`

### Phase 2: Event Handlers Refactor (45 min)
Update all 11+ handlers to update notifier instead of setState:
- [ ] `_onHover` - Crosshair tracking
- [ ] `_onExit` - Hide crosshair
- [ ] `_onPointerSignal` - SHIFT+scroll zoom
- [ ] `_onPointerDown` - Middle-mouse pan start
- [ ] `_onPointerMove` - Pan drag
- [ ] `_onPointerUp` - Pan end
- [ ] `_onTapDown` - Data point selection
- [ ] `_onScaleUpdate` - Pinch zoom and touch pan
- [ ] `_onDoubleTap` - Reset zoom
- [ ] `_onKeyEvent` (3 variations) - Keyboard navigation

### Phase 3: Animation Controllers (20 min)
- [ ] Update `_zoomAnimationController.addListener` to use notifier
- [ ] Update `_panAnimationController.addListener` to use notifier
- [ ] Update zoom fallback (instant zoom) to use notifier
- [ ] Update pan fallback (instant pan) to use notifier

### Phase 4: Controller Callbacks (15 min)
- [ ] Update `_onControllerUpdate` to use notifier
- [ ] Update `_onDataStreamPoint` to use notifier

### Phase 5: Timer Callbacks (10 min)
- [ ] Update tooltip hide timer to use notifier

### Phase 6: Rendering Layer Refactor (60 min)
- [ ] Wrap crosshair rendering in `ValueListenableBuilder`
- [ ] Wrap tooltip rendering in `ValueListenableBuilder`
- [ ] Add `RepaintBoundary` around interaction overlays
- [ ] Ensure base chart never depends on interaction state

### Phase 7: Delete Old Code (5 min)
- [ ] Delete `_safeSetState()` method (no longer needed)
- [ ] Remove any remaining setState calls related to interactions

### Phase 8: Testing (30 min)
- [ ] Test continuous mouse hover (no crashes)
- [ ] Test zoom/pan with mouse movements (smooth)
- [ ] Test controller updates with hover (no conflicts)
- [ ] Test streaming data with interactions (60fps)
- [ ] Profile performance (should see zero widget rebuilds on hover)

---

## 🎯 PERFORMANCE BENEFITS

### Before (setState pattern)
- ❌ **Widget rebuilds:** 100+ per second (every mouse movement)
- ❌ **Layout recalculation:** Full tree on every movement
- ❌ **Coordinate invalidation:** Constant render tree changes
- ❌ **Frame rate:** Crashes or stutters
- ❌ **CPU usage:** High (continuous rebuilds)

### After (ValueNotifier pattern)
- ✅ **Widget rebuilds:** 0 per second (only on data changes)
- ✅ **Layout recalculation:** None for interactions
- ✅ **Coordinate stability:** Render tree stays stable
- ✅ **Frame rate:** Smooth 60fps
- ✅ **CPU usage:** Low (only CustomPainter repaints)

---

## 📊 ESTIMATED IMPACT

**Code Changes:** ~150 lines modified  
**Development Time:** ~3 hours  
**Performance Gain:** 10-100x improvement  
**Stability:** Complete elimination of crashes  

**This aligns with our constitution: PERFORMANCE FIRST** ✅

---

## 🔧 CODE SNIPPETS

### Converting Event Handlers

**Before:**
```dart
void _onHover(PointerHoverEvent event) {
  _safeSetState(() {
    _interactionState = _interactionState.copyWith(
      isCrosshairVisible: true,
      crosshairPosition: localPosition,
    );
  });
}
```

**After:**
```dart
void _onHover(PointerHoverEvent event) {
  _interactionStateNotifier.value = _interactionStateNotifier.value.copyWith(
    isCrosshairVisible: true,
    crosshairPosition: localPosition,
  );
}
```

### Converting Rendering

**Before:**
```dart
if (_interactionState.isCrosshairVisible &&
    _interactionState.crosshairPosition != null) {
  CustomPaint(
    painter: _CrosshairPainter(_interactionState.crosshairPosition!, ...),
  )
}
```

**After:**
```dart
RepaintBoundary(
  child: ValueListenableBuilder<InteractionState>(
    valueListenable: _interactionStateNotifier,
    builder: (context, state, child) {
      if (!state.isCrosshairVisible || state.crosshairPosition == null) {
        return const SizedBox.shrink();
      }
      return CustomPaint(
        painter: _CrosshairPainter(state.crosshairPosition!, ...),
      );
    },
  ),
)
```

### Proper Disposal

**Add to dispose():**
```dart
@override
void dispose() {
  _interactionStateNotifier.dispose();  // Clean up notifier
  // ... existing disposal code
  super.dispose();
}
```

---

## 🚀 NEXT STEPS

**Option 1: Full Refactor (Recommended)**
- Implement all phases in one go
- Clean, complete solution
- ~3 hours of focused work
- Guaranteed stability

**Option 2: Incremental Refactor**
- Phase 1-2 first (core + handlers)
- Test and verify
- Then Phase 3-6 (animations + rendering)
- Safer but slower

**Recommendation:** Full refactor. The current architecture is broken at a fundamental level. Band-aids won't work. We need surgical reconstruction.

---

## 💡 KEY INSIGHTS

1. **setState is NOT for high-frequency updates** - Flutter docs explicitly recommend ValueNotifier for this
2. **CustomPainter + ValueListenableBuilder is the pattern** - Used by Flutter's own gesture overlays
3. **RepaintBoundary prevents cascade repaints** - Critical for layered architecture
4. **Performance requires architectural correctness** - No amount of optimization fixes bad design

This refactor transforms the interaction system from **broken** to **best-practice Flutter architecture**.
