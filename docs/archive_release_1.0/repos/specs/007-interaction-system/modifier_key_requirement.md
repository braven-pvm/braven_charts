# Modifier Key Requirement for Scroll-Based Interactions

**Issue**: Critical Web UX Conflict  
**Date**: 2025-01-08  
**Status**: 🔴 Addressed in Remediation Sprint

---

## Problem

On web platforms, the mouse wheel is used for **page scrolling** - the most fundamental navigation pattern. If our chart hijacks scroll events without requiring a modifier key, we create a terrible UX where:

1. User scrolls down the page
2. Cursor happens to be over a chart
3. Chart zooms instead of page scrolling
4. User is frustrated and confused

This is a **critical anti-pattern** that violates web platform conventions.

---

## Solution

**Require modifier keys for scroll-based interactions:**

| Interaction | Input | Behavior |
|-------------|-------|----------|
| **Zoom** | CTRL/CMD + Scroll | Zoom chart at cursor position |
| **Horizontal Pan** | SHIFT + Scroll | Pan chart horizontally |
| **Pan (Primary)** | Middle-mouse + Drag | Pan chart in any direction |
| **Pan (Alt)** | Left-click + Drag | Pan chart (when pan mode enabled) |
| **Page Scroll** | Scroll (no modifier) | Allow default browser scroll (don't consume event) |

### Platform-Specific Modifier Keys

- **Windows/Linux**: CTRL key
- **macOS**: CMD key (Meta key)
- **Web**: Always require modifier (critical)
- **Desktop Apps**: Optional (can be disabled for standalone apps)

---

## Implementation Details

### Detection Code

```dart
// Scroll events with modifiers
onPointerSignal: (signal) {
  if (signal is PointerScrollEvent) {
    // Detect platform-specific modifier keys
    final isCtrlPressed = HardwareKeyboard.instance.isControlPressed || 
                          HardwareKeyboard.instance.isMetaPressed; // CMD on macOS
    
    final isShiftPressed = HardwareKeyboard.instance.isShiftPressed;
    
    if (isCtrlPressed) {
      // CTRL/CMD + Scroll → Zoom at cursor position
      _handleZoom(signal.scrollDelta.dy, signal.localPosition);
      // Event consumed - prevents page scroll
      return;
    }
    
    if (isShiftPressed) {
      // SHIFT + Scroll → Pan horizontally
      _handleHorizontalPan(signal.scrollDelta.dy);
      // Event consumed - prevents page scroll
      return;
    }
    
    // No modifier → Allow default page scroll
    // DON'T call event.stopPropagation() or consume the event
  }
},

// Middle-mouse button pan (PRIMARY method)
Listener(
  onPointerDown: (event) {
    if (event.buttons == kMiddleMouseButton) { // Button value = 4
      _isPanningWithMiddleMouse = true;
      _panStartPosition = event.localPosition;
      // Change cursor to grab/grabbing
    }
  },
  onPointerMove: (event) {
    if (_isPanningWithMiddleMouse) {
      final delta = event.localPosition - _panStartPosition;
      _handlePan(delta);
      _panStartPosition = event.localPosition;
    }
  },
  onPointerUp: (event) {
    if (_isPanningWithMiddleMouse) {
      _isPanningWithMiddleMouse = false;
      // Restore cursor
    }
  },
  child: chart,
)
```

### Configuration

Add to `InteractionConfig`:

```dart
class InteractionConfig {
  /// Whether scroll events require a modifier key (CTRL/CMD or SHIFT).
  /// 
  /// When true (default for web), plain scroll doesn't zoom/pan - only
  /// CTRL+Scroll or SHIFT+Scroll work. This prevents hijacking browser scroll.
  /// 
  /// When false (option for desktop apps), plain scroll zooms the chart.
  final bool requireModifierForScroll;
  
  /// Whether to show a visual hint about modifier keys and pan controls.
  /// 
  /// When true, shows overlay hint like "Hold Ctrl to zoom, Middle-mouse to pan" when hovering.
  final bool showModifierHint;
  
  /// Whether middle-mouse button enables panning.
  /// 
  /// When true (default), middle-mouse + drag pans the chart in any direction.
  /// This is the PRIMARY pan method (doesn't conflict with selection/tooltips).
  final bool enableMiddleMousePan;
  
  // Default to true on web, false on desktop
  InteractionConfig({
    this.requireModifierForScroll = kIsWeb ? true : false,
    this.showModifierHint = true,
    this.enableMiddleMousePan = true,
    // ... other config
  });
}
```

---

## User Education

### Visual Hint (Recommended)

Show a subtle overlay when user hovers over chart:

```
┌─────────────────────────────────┐
│         Revenue Chart           │
│                                 │
│  [Chart content here]           │
│                                 │
│  ⓘ Ctrl+Scroll: Zoom           │ ← Appears on hover
│  ⓘ Middle-mouse: Pan            │
└─────────────────────────────────┘
```

### Why Middle-Mouse for Pan?

**Advantages:**
1. ✅ **No Conflicts** - Doesn't interfere with tooltips/selection (left-click) or context menus (right-click)
2. ✅ **Industry Standard** - CAD software, 3D modeling tools, Google Earth all use middle-mouse for pan
3. ✅ **Discoverable** - Users familiar with design tools expect this
4. ✅ **Efficient** - Single button, no modifier key needed
5. ✅ **Natural Feel** - Continuous drag feels like "grabbing" the chart

**Fallback Options:**
- SHIFT + Scroll → Horizontal pan (for users without middle-mouse button)
- Left-click + Drag → Pan (when pan mode explicitly enabled, but conflicts with selection)

### Documentation

Update all documentation to mention:

- **readme.md**: "Use CTRL+Scroll to zoom, Middle-mouse drag to pan"
- **Example app**: Tooltip explaining "Middle-mouse to pan, Ctrl+Scroll to zoom"
- **API docs**: Document `requireModifierForScroll` and `enableMiddleMousePan` parameters
- **Migration guide**: If users upgrade, explain new behavior

---

## Testing

### Test Cases

1. **Plain scroll** → Page scrolls, chart does NOT zoom
2. **CTRL + Scroll** → Chart zooms, page does NOT scroll
3. **SHIFT + Scroll** → Chart pans horizontally, page does NOT scroll
4. **Middle-mouse + Drag** → Chart pans in any direction (PRIMARY method)
5. **Left-click + Drag** → Chart pans only if pan mode enabled
6. **Desktop app mode** → Can optionally disable modifier requirement
7. **Visual hint** → Shows "Ctrl+Scroll: Zoom, Middle-mouse: Pan" on hover (if enabled)

### Browser Testing

- ✅ Chrome (Windows, macOS, Linux)
- ✅ Firefox (Windows, macOS, Linux)
- ✅ Safari (macOS)
- ✅ Edge (Windows)

---

## Alternatives Considered

### ❌ Alternative 1: Always Hijack Scroll
**Problem**: Terrible UX, frustrates users, violates web conventions

### ❌ Alternative 2: Detect Intent (scroll speed/direction)
**Problem**: Unreliable, still breaks expectations, too clever

### ❌ Alternative 3: Focus Required (click chart first)
**Problem**: Extra step, not discoverable, still can accidentally trigger

### ✅ Alternative 4: Modifier Keys (CHOSEN)
**Why**: Standard pattern (Google Maps, Figma, etc.), clear intent, doesn't break scroll

---

## References

### Similar Implementations

- **Google Maps**: CTRL+Scroll to zoom, middle-mouse drag to pan
- **Google Earth**: Middle-mouse drag to pan, CTRL+Scroll to zoom
- **Figma**: CTRL+Scroll to zoom canvas, middle-mouse/space+drag to pan
- **Miro**: CTRL+Scroll to zoom board, middle-mouse to pan
- **Tableau**: CTRL+Scroll to zoom chart
- **AutoCAD**: Middle-mouse pan (industry standard)
- **Blender**: Middle-mouse to rotate/pan viewport
- **D3.js Charts**: Typically require modifier keys for zoom

### Web Platform Standards

- [WCAG 2.1 SC 2.1.1](https://www.w3.org/WAI/WCAG21/Understanding/keyboard.html): "All functionality available from a keyboard"
- [MDN: Pointer Events](https://developer.mozilla.org/en-US/docs/Web/API/Pointer_events)
- [Scroll behavior best practices](https://web.dev/scrolling-performance/)

---

## Impact on Remediation Sprint

**New Task Added**: R-T006 "Implement Modifier Key Detection for Scroll Events"  
**Effort**: +30 minutes  
**Dependencies**: Must complete before R-T007 (ZoomPanController integration)  
**Testing**: +3 test cases in R-T013

**Updated Timeline**:
- Best case: 8 hours → 8.5 hours
- Expected: 12 hours → 12.5 hours  
- Worst case: 16 hours → 16.5 hours

---

**Status**: 📝 Documented and incorporated into remediation sprint plan
