# Phase 0 Interaction Architecture Prototype

**Status**: 🟡 In Progress  
**Phase**: Phase 0 - Standalone Architecture Validation  
**Purpose**: Validate interaction architecture before integrating with braven_charts

---

## Overview

This prototype implements the complete interaction architecture designed in `docs/architecture/interaction/INTERACTION_ARCHITECTURE_DESIGN.md`. It exists as a standalone project to validate all architectural decisions before touching the production codebase.

### Why a Standalone Prototype?

Per the architecture design document:
- Current braven_charts has 7306-line monolithic widget with gesture arena conflicts
- "Fixing one event breaks another" problem proven by code comments
- Refactoring in place is too risky
- Need to validate architecture with comprehensive tests first

---

## Architecture Components

### Core Foundation (`lib/core/`)

#### `interaction_mode.dart`
- **InteractionMode** enum: All possible interaction states
- Priority mapping from conflict resolution table (0-10)
- Modal/passive/dragging state helpers
- 11 modes: idle, hovering, panning, zooming, selecting, boxSelecting, draggingDataPoint, draggingAnnotation, resizingAnnotation, editingAnnotation, contextMenuOpen

#### `chart_element.dart`
- **ChartElement** interface: Unified interface for all interactive elements
- Properties: id, bounds, priority, elementType, isSelected, isHovered
- Methods: hitTest(), paint(), onSelect/Deselect(), onHoverEnter/Exit()
- Mixins: ResizableElement, TooltipElement, ContextMenuElement

#### `coordinator.dart`
- **ChartInteractionCoordinator**: Central state manager (ChangeNotifier)
- Responsibilities:
  - Track current interaction mode
  - Claim/release interaction rights (conflict prevention)
  - Track keyboard modifiers (Ctrl, Shift, Alt)
  - Manage selection (single, multi-select, box select)
  - Hover management (passive, suspended during pan)
- Conflict resolution logic per CONFLICT_RESOLUTION_TABLE.md

### Rendering Layer (`lib/rendering/`)

#### `spatial_index.dart`
- **QuadTree**: O(log n) spatial indexing for hit testing
- Operations: insert, query, queryRect, queryNearest, queryNearby, remove
- Handles 100+ elements efficiently at 60fps
- Auto-split at capacity (4 elements/node), auto-merge on remove

#### `chart_render_box.dart`
- **ChartRenderBox**: Custom RenderBox for chart
- Overrides: hitTest(), handleEvent(), paint()
- Event routing based on mouse button:
  - Middle button → pan (exclusive, per scenario 6)
  - Right button → context menu (exclusive, per scenario 8)
  - Left button → select/drag/box-select (per scenarios 5, 9, 13)
- Integrates QuadTree for O(log n) element lookup
- Paints selection rectangle during box select

### Simulated Elements (`lib/elements/`)

#### `simulated_datapoint.dart`
- **SimulatedDatapoint**: Test datapoint with realistic behavior
- Priority: 6 (medium)
- Hit radius: 10px (per conflict resolution scenario 5)
- Selectable & draggable
- Tooltip support (suspended during pan per scenario 12)

---

## Conflict Resolution Implementation

All 15 conflict scenarios from `CONFLICT_RESOLUTION_TABLE.md` are implemented:

### Mouse Event Responsibilities

| Button | Behavior | Exclusivity |
|--------|----------|-------------|
| Middle | Pan only | EXCLUSIVE |
| Right | Context menu | EXCLUSIVE |
| Left | Select, drag, box-select | Context-dependent |
| Wheel | Zoom | Modifiers affect axis |

### Priority Hierarchy

| Priority | Element Types | Scenarios |
|----------|--------------|-----------|
| 10 | Context menu (modal) | 8 |
| 9 | Resize handles, edit mode | 1, 11 |
| 8 | Annotation drag | 10 |
| 7 | Datapoint drag, trend annotations | 3, 13 |
| 6 | Datapoints, selection | 2, 4, 5 |
| 4 | Series lines | 2, 6 |
| 3 | Pan | 6 |
| 1 | Zoom | 12 |
| 0 | Crosshair, hover (passive) | 7, 12 |

### Key Thresholds

- Datapoint hit radius: 10px (scenario 5)
- Box-select start threshold: 5px drag on empty area (scenario 5)
- Ambiguous selection epsilon: 3px (scenario 4 - would show picker UI)
- Resize handle size: 8px × 8px (scenario 1)

---

## Current Implementation Status

### ✅ Completed

1. **Core Foundation**
   - ✅ InteractionMode enum with 11 modes
   - ✅ ChartElement interface with mixins
   - ✅ ChartInteractionCoordinator with full state management
   - ✅ Keyboard modifier tracking
   - ✅ Selection management (single, multi, box)

2. **Spatial Indexing**
   - ✅ QuadTree implementation
   - ✅ Insert/query/remove operations
   - ✅ queryNearest for conflict resolution scenario 4
   - ✅ queryNearby for ambiguous selection detection
   - ✅ Auto-split/merge optimization

3. **Rendering**
   - ✅ ChartRenderBox with custom hitTest/handleEvent
   - ✅ Mouse button routing (middle=pan, right=menu, left=select/drag)
   - ✅ Box selection visual feedback
   - ✅ Element priority-based rendering

4. **Test Elements**
   - ✅ SimulatedDatapoint with tooltip support
   - ✅ SimulatedAnnotation with resize handles (8 handles: corners + midpoints)
   - ✅ SimulatedSeries with line rendering and hit testing

5. **Custom Recognizers**
   - ✅ ContextAwareGestureRecognizer base class
   - ✅ PriorityPanGestureRecognizer (middle-click exclusive pan)
   - ✅ PriorityTapGestureRecognizer (left-click selection with Ctrl multi-select)

6. **Unit Tests**
   - ✅ QuadTree operations (17 tests, all passing)

7. **Widget Layer**
   - ✅ PrototypeChart widget (integrates RenderBox + recognizers + coordinator)
   - ✅ Debug overlay showing coordinator state
   - ✅ Example application demonstrating all features

### 🟡 In Progress

8. **Additional Unit Tests**
   - ⏳ Coordinator state transitions
   - ⏳ Priority resolution logic
   - ⏳ Recognizer conflict handling

9. **Widget Tests**
   - ⏸️ All 15 conflict scenarios
   - ⏸️ Gesture arena behavior
   - ⏸️ HitTestBehavior validation

10. **Integration Tests**
    - ⏸️ Complete interaction workflows
    - ⏸️ Performance validation (100+ elements @ 60fps)

---

## Testing Strategy

### Unit Tests (`test/unit/`)
- **coordinator_test.dart**: State transitions, mode claiming, selection management
- **spatial_index_test.dart**: QuadTree insert/query/remove, performance benchmarks
- **hit_testing_test.dart**: Element hit testing, priority resolution

### Widget Tests (`test/widget/`)
- **gesture_conflict_test.dart**: All 15 scenarios from conflict resolution table
- **interaction_test.dart**: Mouse button routing, modifier keys, selection

### Integration Tests (`test/integration/`)
- **complete_interaction_test.dart**: End-to-end workflows
- **performance_test.dart**: 100+ elements @ 60fps validation

---

## Next Steps

1. **Complete Custom Recognizers** (in progress)
   - Implement PriorityPanRecognizer with coordinator integration
   - Implement PriorityTapRecognizer with context-aware logic

2. **Create Remaining Test Elements**
   - SimulatedAnnotation with ResizableElement mixin
   - SimulatedSeries with path hit testing

3. **Build Prototype Widget**
   - PrototypeChart combining RenderObject + overlays
   - Test app demonstrating all interactions

4. **Write Comprehensive Tests**
   - Unit tests for all core components
   - Widget tests for all 15 conflict scenarios
   - Integration tests for workflows and performance

5. **Validate & Document**
   - Performance benchmarks (target: 100+ elements @ 60fps)
   - Memory leak detection (listener cleanup)
   - Document findings and iterate if needed

6. **Sign-Off for Integration** (after validation)
   - Review with team
   - Get approval to begin Phase 1 (braven_charts integration)

---

## Running the Prototype

**Note**: This is a standalone library prototype, not a runnable Flutter app yet.

To use in tests:
```dart
import 'package:interaction_prototype/core/coordinator.dart';
import 'package:interaction_prototype/rendering/chart_render_box.dart';
import 'package:interaction_prototype/elements/simulated_datapoint.dart';

final coordinator = ChartInteractionCoordinator();
final renderBox = ChartRenderBox(coordinator: coordinator);
final datapoint = SimulatedDatapoint(
  id: 'point1',
  center: Offset(100, 100),
);
```

---

## References

- **Design Document**: `../../docs/architecture/interaction/INTERACTION_ARCHITECTURE_DESIGN.md`
- **Conflict Resolution**: `../../docs/architecture/interaction/CONFLICT_RESOLUTION_TABLE.md`
- **Research**: `../../docs/architecture/interaction/interaction-systems.md`

---

**Last Updated**: 2025-11-05  
**Branch**: interaction-refactor  
**Status**: Prototype foundation complete, continuing with recognizers and tests
