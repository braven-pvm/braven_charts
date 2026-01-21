# Interaction Architecture - Quick Reference

**Last Updated**: 2025-11-05  
**Status**: Design Phase - Prototype Implementation Starting

---

## 🎯 Quick Summary

**Problem**: Current widget-level GestureDetector approach causes gesture arena conflicts ("fixing one breaks another")

**Solution**: Custom RenderObject + Positioned Overlays + ChartInteractionCoordinator pattern

**Status**: Building standalone prototype with simulated components to validate architecture completely before integrating with braven_charts production code.

---

## 📋 Key Decisions Made

✅ **Architecture**: Hybrid RenderObject + Overlay + Coordinator  
✅ **Approach**: Standalone prototype first, then integration  
✅ **Testing**: Comprehensive unit/widget/integration/performance tests  
✅ **Preserve**: IEventHandler interface and ChartEvent model (excellent existing design)

⏳ **Pending**: Interaction priority hierarchy (conflict resolution table)

---

## 🏗️ Proposed Architecture (3 Layers)

### Layer 1: Custom RenderObject (Foundation)

- High-performance chart rendering
- GPU batching with `Canvas.drawRawAtlas`
- QuadTree spatial indexing (O(log n) hit testing)
- Direct `hitTest()` and `handleEvent()` overrides
- Background interactions: pan, zoom, wheel events

### Layer 2: Positioned Widget Overlays (High-Priority Elements)

- Annotation resize handles
- Draggable annotation bodies
- Datapoint selection handles
- Context menus (modal)
- Pattern: `MouseRegion` + `RawGestureDetector` + custom recognizers

### Layer 3: ChartInteractionCoordinator (State Manager)

- Track interaction mode (idle, panning, dragging, selecting, etc.)
- Claim/release interaction rights
- Keyboard modifier state
- Prevent conflicts via explicit state

---

## 🔄 Current Implementation (Widget-Level)

**Structure**:

```dart
MouseRegion (cursor)
  └─ GestureDetector (right-click, opaque)
       └─ Listener (middle-mouse pan, opaque)
            └─ MouseRegion (hover)
                 └─ chart widget
```

**Issues Found**:

- ❌ Multiple `HitTestBehavior.opaque` widgets compete in gesture arena
- ❌ Manual layering workarounds (code comments indicate previous failures)
- ❌ No spatial indexing (linear search)
- ❌ No coordinator (implicit state)
- ❌ 7306 line monolithic widget file
- ❌ Missing: box select, multi-select, annotation resize, datapoint drag

**Evidence**: Lines 2369-2375 in braven_chart.dart explicitly document arena conflicts requiring workarounds.

---

## ✅ Interactive Elements Confirmed

### Primary Elements

- **Series Lines**: Click select, hover highlight
- **Data Points**: Select, drag, hover tooltip
- **Annotations**: Drag, resize (8 handles), edit, select
- **Crosshair**: Follows mouse
- **Tooltips**: Hover display
- **Context Menus**: Right-click
- **Legend**: Click show/hide series

### Selection Mechanisms

- **Single Select**: Click
- **Multi-Select**: Ctrl+Click
- **Box Select**: Left-drag selection rectangle
- **Range Select**: Select datapoint sequence

### Interaction Types

- **Hover/Enter/Exit**: Highlight, tooltips, cursors
- **Left/Right/Middle Click**: Select, context menu, pan
- **Mouse Wheel**: Zoom (with Ctrl/Shift modifiers)
- **Drag**: Pan, drag elements, box select
- **Double-Click**: Zoom to fit, edit mode
- **Keyboard**: Modifiers (Ctrl/Shift/Space for interactions)

---

## 🚧 Implementation Plan

### ⭐ Phase 0: Standalone Prototype (CURRENT)

**Objective**: Build and validate complete architecture in isolation

**Deliverables**:

```
test/interaction_prototype/
├── lib/
│   ├── core/                    # Coordinator, ChartElement interface
│   ├── rendering/               # Custom RenderBox, QuadTree
│   ├── recognizers/             # Context-aware custom recognizers
│   ├── elements/                # Simulated components (points, annotations)
│   └── widgets/                 # Test chart widget, overlays
└── test/
    ├── unit/                    # Coordinator, spatial index, hit testing
    ├── widget/                  # Gesture conflicts, arena behavior
    └── integration/             # Complete workflows, all conflict scenarios
```

**Success Criteria**:

- [ ] All conflict scenarios tested and resolved
- [ ] 60fps with 100+ simulated elements
- [ ] Zero gesture arena conflicts
- [ ] All mouse event types working
- [ ] Box selection implemented
- [ ] Memory leak free (listener cleanup validated)

### Phase 1: Current Implementation Analysis ✅ COMPLETE

- Analyzed widget-level interaction approach
- Identified gesture arena conflicts
- Documented missing features
- Assessed migration requirements

### Phase 2-7: See full design document for complete roadmap

---

## ⚠️ Critical Conflict Scenarios (NEEDS DECISION)

| #   | Scenario                                 | Element 1     | Element 2   | Winner? | Behavior?           |
| --- | ---------------------------------------- | ------------- | ----------- | ------- | ------------------- |
| 1   | Annotation resize handle under datapoint | Resize handle | Datapoint   | ?       | ?                   |
| 2   | Datapoint on series line                 | Datapoint     | Series      | ?       | ?                   |
| 3   | Annotation body over datapoint           | Annotation    | Datapoint   | ?       | ?                   |
| 4   | Multiple overlapping datapoints          | Point A       | Point B     | ?       | Closest?            |
| 5   | Box select vs datapoint                  | Box drag      | Point click | ?       | Distance threshold? |
| 6   | Pan vs series click                      | Pan           | Series      | ?       | ?                   |
| 7   | Crosshair vs any click                   | Crosshair     | Other       | ?       | ?                   |
| 8   | Context menu open                        | Menu          | Any         | Menu    | Block all ✅        |
| 9   | Ctrl+Click vs normal click               | Multi-select  | Select      | ?       | Check modifier ✅   |
| 10  | Resize drag leaves element               | Resize        | Exit        | ?       | Continue? Cancel?   |

**ACTION REQUIRED**: Complete this table with team decisions before prototype implementation.

---

## 📊 Performance Targets

### Must Achieve

- ✅ 60fps with 100+ interactive datapoints
- ✅ <5ms event processing overhead (99th percentile)
- ✅ O(log n) hit testing with spatial index
- ✅ Zero memory growth after 10,000 event cycles

### Stretch Goals

- 60fps with 500+ datapoints
- 120fps on high-refresh displays
- <1ms hit testing with optimized QuadTree

---

## 📚 Key Reference Documents

- **Full Design**: `interaction_architecture_design.md`
- **Research**: `interaction-systems.md` (Flutter gesture system deep dive)
- **Current Code**: `lib/src/widgets/braven_chart.dart` (main widget)
- **Event Handler**: `lib/src/interaction/event_handler.dart` (keep this!)

---

## 🔗 Architecture Patterns from Research

### Custom RenderObject Pattern

```dart
class ChartRenderBox extends RenderBox {
  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    // QuadTree query for O(log n) performance
    final candidates = _spatialIndex.query(position);
    if (candidates.isNotEmpty) {
      result.add(BoxHitTestEntry(this, position));
      return true;
    }
    return false;
  }

  @override
  void handleEvent(PointerEvent event, BoxHitTestEntry entry) {
    // Direct event handling - bypasses gesture arena
    if (event is PointerDownEvent) { /* ... */ }
  }
}
```

### Context-Aware Recognizer Pattern

```dart
class ContextAwareRecognizer extends OneSequenceGestureRecognizer {
  final bool Function(Offset) shouldAcceptGesture;

  @override
  void addPointer(PointerDownEvent event) {
    if (shouldAcceptGesture(event.position)) {
      resolve(GestureDisposition.accepted);  // Win immediately
    } else {
      resolve(GestureDisposition.rejected);  // Leave arena
    }
  }
}
```

### Coordinator Pattern

```dart
class ChartInteractionCoordinator extends ChangeNotifier {
  InteractionMode _mode = InteractionMode.idle;

  bool canClaim(InteractionMode mode, Widget element) {
    return _mode == InteractionMode.idle ||
           (_mode == mode && _activeElement == element);
  }

  void claim(InteractionMode mode, Widget element) { /* ... */ }
  void release(Widget element) { /* ... */ }
}
```

---

## 🚀 Getting Started with Prototype

### Next Immediate Actions

1. Create prototype project structure
2. Implement basic QuadTree spatial index
3. Create ChartInteractionCoordinator skeleton
4. Build 3-5 simulated chart elements
5. Set up comprehensive test suite
6. Validate ALL conflict scenarios

### First Week Goals

- Complete Phase 0 prototype implementation
- Validate architecture with 100+ elements
- Performance benchmark at 60fps
- Document findings and iterate

---

## 📝 Notes for Implementation Team

### What to Keep from Current Code

- ✅ `IEventHandler` interface (excellent abstraction)
- ✅ `ChartEvent` model (clean coordinate translation)
- ✅ `GestureDetails` model (comprehensive tracking)
- ✅ Separation of crosshair/tooltip/zoom-pan logic
- ✅ Priority-based handler registration system

### What to Replace

- ❌ Nested GestureDetector + Listener pattern
- ❌ Widget-level CustomPaint approach
- ❌ Linear hit testing (no spatial index)
- ❌ Implicit interaction state (need explicit coordinator)
- ❌ Per-annotation GestureDetectors (use overlays + custom recognizers)

### Critical Risks

- **Migration complexity**: Breaking changes to public API
- **Performance regression**: Custom RenderObject bugs could hurt performance
- **Scope creep**: Must control feature requests during implementation

### Mitigations

- Standalone prototype validates architecture before production integration
- Comprehensive benchmarks catch performance regressions early
- Strict scope control - backlog for v2.1 features
- Deprecation period + migration guide for API changes

---

## 📞 Contact & Updates

**Document Owner**: Development Team  
**Status Updates**: This document updated weekly during implementation  
**Questions**: File issue in project tracker or discuss in team meeting

**Last Major Update**: 2025-11-05 - Initial design and current implementation analysis complete
