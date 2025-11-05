# Interaction Architecture Design Document

**Project**: braven_charts v2.0  
**Date**: November 5, 2025  
**Status**: Design Phase - Architecture Planning

---

## Executive Summary

This document captures the architecture design for a complete interaction system for braven_charts. The current implementation has suffered from the "fixing one event breaks another" problem due to Flutter's gesture arena conflicts. This redesign will implement a production-ready interaction architecture based on research from professional charting libraries (fl_chart, Syncfusion, charts_flutter).

---

## Problem Statement

### Current Issues
- **Gesture Arena Conflicts**: Multiple overlapping interactive elements compete for gestures, causing unpredictable behavior
- **Event Interference**: Fixing one interaction breaks another (e.g., enabling datapoint drag breaks pan/zoom)
- **Scalability**: Current approach doesn't scale to hundreds of interactive elements
- **Complexity**: Widget-level GestureDetector patterns create maintenance nightmare with stacked elements

### Root Cause
Flutter's gesture arena is a **competitive disambiguation system** where recognizers battle for control. Default widget-level approaches fail with overlapping interactive elements because we don't control which recognizer wins the arena.

---

## Research Findings Summary

Based on comprehensive analysis of Flutter's interaction systems and production charting libraries:

### Key Architectural Insights

1. **Hit Testing Foundation**
   - Hit testing proceeds **front-to-back** in Stack (last child tested first)
   - `HitTestBehavior.opaque` prevents testing lower Z-order widgets BUT NOT children
   - Custom `hitTest()` overrides provide pixel-perfect control

2. **Gesture Arena Strategy**
   - Custom recognizers with **context-aware logic** solve conflicts
   - Position-based acceptance/rejection decisions (e.g., accept if within 10px of datapoint)
   - `RawGestureDetector` + `GestureRecognizerFactory` for custom recognizers

3. **Performance at Scale**
   - **Custom RenderObject** is production choice for 100+ interactive elements
   - **QuadTree spatial indexing**: O(log n) hit testing vs O(n) linear
   - **Canvas.drawRawAtlas**: GPU batching for hundreds of elements
   - **Viewport culling**: Only paint/test visible elements

4. **Production Library Patterns**
   - **Single event handler** with position-based routing > multiple GestureDetectors
   - **Coordinator pattern** for interaction state management
   - **Behavior composition** (Syncfusion) separates concerns cleanly

---

## Requirements Gathering

### 1. Interactive Chart Elements

#### Primary Elements
- ✅ **Series Lines**: Clickable, hoverable, selectable
- ✅ **Data Points**: Selectable, draggable, hoverable with tooltip
- ✅ **Annotations**: 
  - Draggable (move)
  - Resizable (drag handles)
  - Editable (double-click to edit text/properties)
  - Selectable
- ✅ **Crosshair**: Follows mouse, doesn't interfere with other interactions
- ✅ **Tooltips**: Show on hover (non-interfering)
- ✅ **Context Menus**: Right-click on elements
- ✅ **Axis Labels**: Potentially interactive for range selection
- ✅ **Legend**: Click to show/hide series

#### Selection Mechanisms
- ✅ **Single Select**: Click datapoint/annotation/series
- ✅ **Multi-Select**: Ctrl+Click for multiple items
- ✅ **Box Select**: Left-click drag to create selection rectangle
  - Select multiple datapoints within box
  - Create range annotation from selection
- ✅ **Range Select**: Select sequence of datapoints for range operations

### 2. Interaction Types

#### Mouse Events
- ✅ **Hover/Enter/Exit**: Highlight, tooltips, cursor changes
- ✅ **Left Click**: Select, activate
- ✅ **Right Click**: Context menus
- ✅ **Middle Click**: TBD (pan mode toggle?)
- ✅ **Mouse Wheel**: Zoom (with modifiers for different zoom modes)
- ✅ **Drag**: Pan chart, drag elements, box select

#### Gesture Events
- ✅ **Pan**: Chart navigation
- ✅ **Pinch/Zoom**: Scale operations
- ✅ **Double-Click**: Zoom to fit, enter edit mode
- ✅ **Long Press**: Alternative context menu trigger

#### Keyboard Modifiers
- ✅ **Ctrl + Wheel**: Horizontal zoom
- ✅ **Shift + Wheel**: Vertical zoom  
- ✅ **Ctrl + Click**: Multi-select
- ✅ **Ctrl + Shift + Wheel**: Custom zoom mode
- ✅ **Space + Drag**: Pan mode (like Photoshop)

### 3. Interaction Priority Hierarchy

**DECISION REQUIRED**: Define complete priority hierarchy for all conflict scenarios.

#### Initial Proposed Hierarchy (Highest to Lowest Priority)

1. **Context Menu Active** (blocks all other interactions)
2. **Modal Dialog/Editor** (blocks all chart interactions)
3. **Active Drag Operation** (annotation resize > annotation move > datapoint drag)
4. **Box Selection Active** (left-click drag in empty space)
5. **Annotation Resize Handles** (small hit targets, need highest interactive priority)
6. **Annotation Bodies** (drag to move)
7. **Data Points** (click select, drag to move)
8. **Series Lines** (click select, hover highlight)
9. **Chart Background Pan/Zoom**
10. **Crosshair** (passive, doesn't claim interactions)

#### Conflict Scenarios to Define

**TASK**: Document behavior for each conflict scenario:

| Scenario | Element 1 | Element 2 | Winner | Behavior |
|----------|-----------|-----------|--------|----------|
| 1 | Annotation resize handle | Datapoint underneath | ? | ? |
| 2 | Datapoint | Series line | ? | ? |
| 3 | Annotation body | Datapoint | ? | ? |
| 4 | Multiple datapoints overlapping | Multiple points | ? | Closest to click? |
| 5 | Box select drag | Datapoint clicked initially | ? | Distance threshold? |
| 6 | Pan gesture | Series click | ? | ? |
| 7 | Crosshair active | Any click | ? | ? |
| 8 | Right-click menu open | Any interaction | Menu | Block all |
| 9 | Ctrl+Click (multi-select) | Normal click | ? | Check modifier |
| 10 | Resize in progress | Mouse leaves element | ? | Continue? Cancel? |

**ACTION ITEM**: Complete this table with team decisions.

---

## Proposed Architecture

### Architecture Pattern: Hybrid RenderObject + Overlay + Coordinator

Based on research, we'll implement a **three-layer architecture**:

#### Layer 1: Custom RenderObject Base (Chart Foundation)
- **Purpose**: High-performance rendering and base-level interaction
- **Responsibilities**:
  - Chart rendering with GPU batching (`drawRawAtlas`)
  - Viewport culling via QuadTree spatial index
  - Background interactions (pan, zoom, wheel events)
  - Raw pointer event handling (`handleEvent()`)
  - Pixel-perfect hit testing (`hitTest()`)
- **Performance**: Handles 100+ elements at 60fps

#### Layer 2: Positioned Widget Overlays (High-Priority Elements)
- **Purpose**: Complex interactive elements needing gesture priority
- **Responsibilities**:
  - Annotation resize handles (small hit targets)
  - Draggable annotation bodies
  - Datapoint selection/drag handles
  - Context menus (modal overlays)
- **Pattern**: `MouseRegion` + `RawGestureDetector` + custom recognizers

#### Layer 3: Interaction Coordinator (State Manager)
- **Purpose**: Prevent conflicts via explicit state management
- **Responsibilities**:
  - Track current interaction mode (idle, panning, dragging, selecting, etc.)
  - Claim/release interaction rights
  - Keyboard modifier state tracking
  - Notify listeners of interaction state changes
- **Integration**: Provider/Riverpod for widget tree access

### Technology Stack

#### Core Components
- ✅ **Custom RenderObject**: `ChartRenderBox` extending `RenderBox`
- ✅ **QuadTree**: Spatial indexing for O(log n) operations
- ✅ **Custom Recognizers**: Context-aware gesture arena participants
- ✅ **Listener**: Raw pointer events (right-click, wheel, modifier detection)
- ✅ **MouseRegion**: Hover states independent of gesture arena
- ✅ **State Management**: Provider or Riverpod for coordinator

#### Interaction Components
```dart
// Core coordinator
class ChartInteractionCoordinator extends ChangeNotifier {
  InteractionMode currentMode;
  Set<LogicalKeyboardKey> modifierKeys;
  ChartElement? activeElement;
  Set<ChartElement> selectedElements;
  // ... methods
}

// Interaction modes
enum InteractionMode {
  idle,
  hovering,
  panning,
  zooming,
  selecting,              // Single element selection
  boxSelecting,           // Drag-to-select box
  draggingDataPoint,
  draggingAnnotation,
  resizingAnnotation,
  editingAnnotation,
  contextMenuOpen,
}

// Chart elements (unified interface)
abstract class ChartElement {
  Rect get bounds;
  bool hitTest(Offset position);
  void paint(Canvas canvas);
  int get priority;  // For conflict resolution
}
```

---

## Implementation Plan

### Phase 0: Standalone Architecture Prototype ⭐ **CURRENT PHASE**

**Objective**: Build and test complete architecture in isolation before integrating with braven_charts.

#### 0.1: Create Prototype Project Structure
```
test/interaction_prototype/
├── lib/
│   ├── core/
│   │   ├── coordinator.dart              # ChartInteractionCoordinator
│   │   ├── chart_element.dart            # Base ChartElement interface
│   │   └── interaction_mode.dart         # InteractionMode enum
│   ├── rendering/
│   │   ├── chart_render_box.dart         # Custom RenderBox
│   │   └── spatial_index.dart            # QuadTree implementation
│   ├── recognizers/
│   │   ├── context_aware_recognizer.dart # Base custom recognizer
│   │   ├── priority_pan_recognizer.dart  # Pan with priority
│   │   └── priority_tap_recognizer.dart  # Tap with priority
│   ├── elements/
│   │   ├── simulated_datapoint.dart      # Test datapoint element
│   │   ├── simulated_annotation.dart     # Test annotation element
│   │   └── simulated_series.dart         # Test series element
│   └── widgets/
│       ├── prototype_chart.dart          # Test chart widget
│       └── overlay_widgets.dart          # Test overlay components
└── test/
    ├── unit/
    │   ├── coordinator_test.dart
    │   ├── spatial_index_test.dart
    │   └── hit_testing_test.dart
    ├── widget/
    │   ├── gesture_conflict_test.dart
    │   └── interaction_test.dart
    └── integration/
        └── complete_interaction_test.dart
```

#### 0.2: Prototype Features to Implement
- [ ] Basic custom RenderBox with hit testing
- [ ] QuadTree spatial index with query operations
- [ ] ChartInteractionCoordinator with all modes
- [ ] 3-5 simulated chart elements (points, annotations, series)
- [ ] Custom recognizers with coordinator integration
- [ ] Layered widget structure (base + overlays)
- [ ] All mouse event types (hover, click, right-click, wheel)
- [ ] Keyboard modifier detection
- [ ] Box selection mechanism
- [ ] Context menu system

#### 0.3: Test Scenarios to Validate

**Unit Tests**:
- [ ] Coordinator state transitions
- [ ] QuadTree insert/query/remove operations
- [ ] Hit testing with various element types
- [ ] Priority calculation and conflict resolution
- [ ] Modifier key tracking

**Widget Tests**:
- [ ] Gesture arena conflicts (overlapping elements)
- [ ] Custom recognizer accept/reject logic
- [ ] MouseRegion hover behavior
- [ ] HitTestBehavior configurations
- [ ] IgnorePointer/AbsorbPointer blocking

**Integration Tests**:
- [ ] Complete interaction workflows
- [ ] All conflict scenarios from table
- [ ] Performance with 100+ elements
- [ ] Memory leak detection (listener cleanup)
- [ ] Frame rate during interactions (60fps validation)

### Phase 1: Current Implementation Analysis

**ACTION**: Analyze existing braven_charts interaction code.

#### 1.1: Code Audit
- [ ] Inventory all current interactive elements
- [ ] Document current gesture handling approach
- [ ] Identify all known interaction bugs
- [ ] Map current performance bottlenecks

#### 1.2: API Surface Analysis
- [ ] Document public interaction APIs
- [ ] Identify breaking changes needed
- [ ] Plan migration path for existing users

### Phase 2: Core Architecture Implementation

**Depends on**: Phase 0 prototype validation

#### 2.1: Foundation Layer
- [ ] Implement production ChartRenderBox
- [ ] Integrate QuadTree spatial index
- [ ] Implement efficient batch rendering
- [ ] Add viewport culling

#### 2.2: Coordinator System
- [ ] Implement ChartInteractionCoordinator
- [ ] Integrate with state management (Provider/Riverpod)
- [ ] Add keyboard tracking
- [ ] Implement claim/release mechanism

#### 2.3: Custom Recognizers
- [ ] Context-aware pan recognizer
- [ ] Context-aware tap recognizer
- [ ] Priority-based recognizer factory
- [ ] Coordinator-integrated recognizers

### Phase 3: Element-Specific Interactions

#### 3.1: Data Points
- [ ] Click selection
- [ ] Drag to move
- [ ] Hover tooltips
- [ ] Multi-select with Ctrl

#### 3.2: Annotations
- [ ] Click selection
- [ ] Drag to move
- [ ] Resize handles (8-point)
- [ ] Double-click to edit
- [ ] Right-click context menu

#### 3.3: Series Lines
- [ ] Click selection
- [ ] Hover highlight
- [ ] Show/hide from legend

#### 3.4: Box Selection
- [ ] Drag-to-select rectangle
- [ ] Visual feedback during drag
- [ ] Select all contained elements
- [ ] Create range annotation from selection

### Phase 4: Advanced Features

#### 4.1: Pan/Zoom System
- [ ] Mouse wheel zoom (with Ctrl/Shift modifiers)
- [ ] Pinch-to-zoom (touch)
- [ ] Pan with drag
- [ ] Double-click zoom to fit
- [ ] Zoom to selection

#### 4.2: Context Menus
- [ ] Right-click detection
- [ ] Context-aware menu items
- [ ] AbsorbPointer blocking
- [ ] Keyboard shortcuts

#### 4.3: Keyboard Integration
- [ ] Focus management
- [ ] Modifier key tracking
- [ ] Keyboard shortcuts
- [ ] Arrow key navigation

### Phase 5: Performance Optimization

#### 5.1: Rendering Optimization
- [ ] GPU batching with drawRawAtlas
- [ ] RepaintBoundary strategic placement
- [ ] Minimize widget rebuilds
- [ ] Listenable-based repaint triggers

#### 5.2: Interaction Optimization
- [ ] Spatial index tuning
- [ ] Hit test optimization
- [ ] Debouncing hover events
- [ ] Throttling paint updates

### Phase 6: Testing & Validation

#### 6.1: Comprehensive Test Suite
- [ ] Unit tests (80%+ coverage)
- [ ] Widget tests (all gesture scenarios)
- [ ] Integration tests (complete workflows)
- [ ] Performance benchmarks

#### 6.2: Real-World Validation
- [ ] Test with production data sets
- [ ] Stress test with 1000+ datapoints
- [ ] Validate 60fps during interactions
- [ ] Memory leak detection

### Phase 7: Migration & Documentation

#### 7.1: Migration Strategy
- [ ] Deprecation plan for old APIs
- [ ] Migration guide documentation
- [ ] Example migration code
- [ ] Breaking change announcements

#### 7.2: Documentation
- [ ] Architecture documentation
- [ ] API reference updates
- [ ] Interaction examples
- [ ] Best practices guide

---

## Current Implementation Analysis

**STATUS**: ✅ COMPLETED - Analysis of `lib/src` interaction system

### Architecture Overview

#### Current Structure
```
lib/src/
├── interaction/
│   ├── event_handler.dart           # EventHandler with priority-based routing
│   ├── crosshair_renderer.dart      # Crosshair rendering logic
│   ├── tooltip_provider.dart        # Tooltip display system
│   ├── zoom_pan_controller.dart     # Pan/zoom state management
│   ├── gesture_recognizer.dart      # Custom gesture recognizers
│   ├── keyboard_handler.dart        # Keyboard event processing
│   ├── interaction_callbacks.dart   # Callback interfaces
│   └── models/
│       └── gesture_details.dart     # GestureDetails model (tap, pan, pinch, longPress)
└── widgets/
    └── braven_chart.dart            # Main chart widget (7306 lines)
```

### Current Interaction Approach: Widget-Level GestureDetector + Listener

#### Layer 1: Base Chart (braven_chart.dart)

**Key Finding**: The main chart uses **nested widget-level interaction** with layered GestureDetector and Listener:

```dart
// Lines 2183-2584: Widget tree structure
MouseRegion(cursor: resizeCursor)           // Outermost - cursor management
  └─ GestureDetector(                       // Outer - right-click handler
       behavior: HitTestBehavior.opaque,
       onSecondaryTapDown: _handleRightClick,
       child: Listener(                     // Inner - middle-mouse pan
         behavior: HitTestBehavior.opaque,
         onPointerDown: _handleMiddleMousePan,
         child: MouseRegion(               // Hover detection
           onHover: _updateCrosshair,
           child: chartWidget
         )
       )
     )
```

**CRITICAL ISSUES IDENTIFIED**:

1. **Comment Evidence of Arena Conflicts** (Line 2369-2375):
   ```dart
   // CRITICAL FIX: Wrap with GestureDetector BEFORE Listener
   // GestureDetector must be OUTER layer to receive events first for right-click handling
   // Widget tree order: GestureDetector → Listener → MouseRegion → chart
   // This ensures right-clicks reach GestureDetector before Listener can interfere
   ```
   - Comments indicate previous failures with event ordering
   - Manual layering workaround to prevent Listener from blocking GestureDetector

2. **HitTestBehavior Misconfiguration** (Lines 2376, 2494):
   ```dart
   behavior: HitTestBehavior.opaque,  // Multiple widgets with opaque behavior
   ```
   - Both GestureDetector AND Listener use opaque behavior
   - This creates gesture arena competition issues

3. **No Spatial Indexing**: Linear search through all elements on each event

4. **No Coordinator Pattern**: No centralized interaction state management

5. **Annotation Handling** (Lines 5090+): Each annotation wrapped in separate GestureDetector
   - Multiple competing recognizers for overlapping annotations
   - No explicit priority resolution

#### Layer 2: Event Handler (event_handler.dart)

**Positive Findings**:
- ✅ Clean abstraction with IEventHandler interface
- ✅ Priority-based handler registration (handlers sorted by priority)
- ✅ ChartEvent model with data coordinate translation
- ✅ Support for multiple event types (mouse, touch, keyboard)

**Limitations**:
- ⚠️ No integration with gesture arena (processes PointerEvents directly)
- ⚠️ No custom recognizers (can't participate in arena competition)
- ⚠️ No spatial indexing for hit testing
- ⚠️ KeyEvent processing stubbed out (returns ignored)

#### Layer 3: Gesture Details Model

**Strengths**:
- ✅ Comprehensive gesture tracking (tap, pan, pinch, longPress)
- ✅ Immutable design with factories
- ✅ Calculated properties (distance, velocity, duration)
- ✅ JSON serialization support

### Current Interaction Features

#### ✅ Implemented
- **Crosshair**: MouseRegion-based hover tracking (ValueListenableBuilder for updates)
- **Tooltips**: Hover-based display (tooltip_provider.dart)
- **Pan/Zoom**: Middle-mouse drag for pan, wheel for zoom (zoom_pan_controller.dart)
- **Right-Click**: GestureDetector.onSecondaryTap for context menus
- **Annotations**: Basic drag support per annotation (separate GestureDetectors)

#### ❌ Not Implemented / Problematic
- **Box Selection**: Not found in codebase
- **Multi-Select**: No Ctrl+Click detection for multi-select
- **Datapoint Drag**: Not found (datapoints are painted, not individual widgets)
- **Annotation Resize**: Resize handles not found in analyzed sections
- **Priority Resolution**: No explicit conflict resolution for overlapping elements
- **Spatial Indexing**: No QuadTree or similar optimization
- **Custom Recognizers**: gesture_recognizer.dart exists but content not analyzed
- **Keyboard Modifiers**: keyboard_handler.dart exists but KeyEvent processing returns ignored

### Performance Concerns

1. **7306 Line Widget File**: Main chart widget is monolithic
   - Difficult to maintain and test
   - Tight coupling of rendering + interaction

2. **No Viewport Culling**: All annotations rendered regardless of visibility

3. **Widget Rebuilds**: Comments indicate concerns about rebuild performance (line 2159)

4. **Linear Hit Testing**: No spatial data structure for O(log n) lookups

### Known Bugs/Issues From Code Comments

1. **Right-Click Interference** (Lines 2369-2372):
   - Previous attempts failed with event ordering
   - Required manual layering workaround

2. **Size Mismatch** (Lines 2207-2211):
   ```dart
   // CRITICAL FIX: Do NOT calculate chartRect here with LayoutBuilder size.
   // LayoutBuilder sees the full widget size including title/subtitle (537px height),
   // but CustomPaint renders with a smaller size (493px, excluding title).
   // This size mismatch causes proportional coordinate transformation errors.
   ```

3. **Annotation Event Pass-Through** (Line 2336):
   ```dart
   opaque: false, // Allow child MouseRegions (annotation handles) to receive events
   ```
   - Indicates previous blocking issues with nested MouseRegions

### Architectural Assessment

#### Strengths
- Clean event abstraction (IEventHandler, ChartEvent model)
- Priority-based handler system
- Separation of concerns (crosshair, tooltip, zoom/pan in separate files)

#### Critical Weaknesses
- ❌ **Widget-level gesture approach doesn't scale**: Each element needs separate GestureDetector
- ❌ **Gesture arena conflicts**: Manual workarounds (layering order, HitTestBehavior hacks)
- ❌ **No spatial optimization**: O(n) hit testing
- ❌ **No state coordinator**: Implicit state in nested widgets
- ❌ **Monolithic chart widget**: 7306 lines, tight coupling
- ❌ **Missing features**: Box select, multi-select, annotation resize, datapoint drag

### Migration Requirements

#### Breaking Changes Needed
1. **Custom RenderObject**: Replace widget-level CustomPaint
2. **Unified Event System**: Replace nested GestureDetector/Listener with custom recognizers
3. **Coordinator Integration**: Add ChartInteractionCoordinator to replace implicit state
4. **API Changes**: Event callbacks may need different signatures

#### Preservation Opportunities
1. **Keep**: IEventHandler abstraction (excellent design)
2. **Keep**: ChartEvent and GestureDetails models
3. **Keep**: Crosshair/Tooltip/ZoomPan separation (refactor integration)
4. **Migrate**: Event handler registration to work with coordinator

### Recommended Refactoring Strategy

1. **Phase 0** (Prototype): Build new architecture standalone with simulated elements
2. **Phase 1** (Foundation): 
   - Extract rendering logic to custom RenderObject
   - Implement spatial indexing (QuadTree)
3. **Phase 2** (Coordinator):
   - Implement ChartInteractionCoordinator
   - Integrate with existing event_handler.dart
4. **Phase 3** (Custom Recognizers):
   - Build context-aware recognizers
   - Replace nested GestureDetector/Listener
5. **Phase 4** (Feature Parity):
   - Migrate crosshair, tooltip, zoom/pan to new system
   - Add missing features (box select, multi-select, etc.)
6. **Phase 5** (Cleanup):
   - Remove deprecated widget-level code
   - Refactor monolithic braven_chart.dart

### Conclusion

The current implementation shows **clear evidence of the "fixing one event breaks another" problem** through comments indicating multiple refactoring attempts and workarounds. The widget-level gesture approach has reached its scalability limits. The proposed custom RenderObject + Coordinator architecture is the correct path forward and is validated by the existing pain points in the codebase.

---

## Decisions Log

### Decision 1: Architecture Pattern
- **Date**: 2025-11-05
- **Decision**: Hybrid RenderObject + Overlay + Coordinator pattern
- **Rationale**: 
  - Matches production library patterns (fl_chart, Syncfusion)
  - Provides performance (RenderObject) + flexibility (overlays)
  - Coordinator prevents gesture arena conflicts explicitly
  - **Current codebase analysis confirms this is necessary** (widget-level approach has failed)
- **Alternatives Considered**:
  - Pure widget-level approach (rejected: doesn't scale, arena conflicts - proven by current implementation)
  - Pure RenderObject (rejected: too complex for all interactions)

### Decision 2: Standalone Prototype First
- **Date**: 2025-11-05
- **Decision**: Build complete architecture prototype before integration
- **Rationale**:
  - Validate architecture completely before touching production code
  - Test all conflict scenarios in isolation
  - Iterate quickly without breaking existing functionality
  - Comprehensive testing before integration
  - **Current codebase is 7306 lines with tight coupling** - refactoring in place is too risky
- **Approval**: User confirmed

### Decision 3: Testing Strategy
- **Date**: 2025-11-05
- **Decision**: Unit + Widget + Integration + Performance tests
- **Rationale**:
  - Unit tests: Coordinator logic, spatial index, hit testing
  - Widget tests: Gesture conflicts, recognizer behavior
  - Integration tests: Complete workflows
  - Performance tests: 100+ elements at 60fps
  - **Current implementation has no architectural tests** - must validate new approach thoroughly

### Decision 4: Interaction Priority Hierarchy
- **Date**: 2025-11-05
- **Status**: ⚠️ **PENDING** - Requires team decision
- **Blocker**: Need to define complete conflict resolution table
- **Action**: Schedule decision meeting
- **Note**: Current implementation has no explicit priority system - causes conflicts

### Decision 5: Preserve Event Handler Abstraction
- **Date**: 2025-11-05  
- **Decision**: Keep IEventHandler interface and ChartEvent model
- **Rationale**:
  - Excellent design with priority-based routing
  - Clean abstraction between platform events and chart events
  - Already handles coordinate transformation
  - Integrate with coordinator rather than replace
- **Migration**: Extend to work with custom recognizers and coordinator

---

## Open Questions

### High Priority
1. ❓ **Conflict Resolution Table**: Complete the 10+ conflict scenarios - WHO WINS?
2. ❓ **Modifier Key Combinations**: Define all Ctrl/Shift/Alt + Mouse combinations
3. ❓ **State Management Choice**: Provider vs Riverpod for coordinator?
4. ❓ **Touch vs Mouse**: Different behavior for touch gestures vs mouse?

### Medium Priority
5. ❓ **Annotation Edit Mode**: Inline editing vs modal dialog?
6. ❓ **Selection Visual Feedback**: How to indicate selected elements?
7. ❓ **Multi-select Limit**: Maximum number of selected elements?
8. ❓ **Undo/Redo**: Should interaction coordinator track history?

### Low Priority
9. ❓ **Accessibility**: Keyboard-only navigation support?
10. ❓ **Mobile Optimization**: Touch-specific gesture optimizations?

---

## Risk Assessment

### High Risk
- ⚠️ **Migration Complexity**: Breaking changes may impact existing users
  - *Mitigation*: Deprecation period, migration guide, parallel API support
- ⚠️ **Performance Regression**: Custom RenderObject bugs could hurt performance
  - *Mitigation*: Comprehensive benchmarks, gradual rollout, feature flags

### Medium Risk
- ⚠️ **Scope Creep**: Feature requests during implementation
  - *Mitigation*: Strict scope control, backlog for v2.1
- ⚠️ **Test Coverage**: Complex interactions hard to test
  - *Mitigation*: Prototype testing, integration tests, manual QA

### Low Risk
- ⚠️ **Flutter API Changes**: Future Flutter updates breaking our code
  - *Mitigation*: Abstract Flutter APIs, monitor Flutter changelog

---

## Success Criteria

### Must Have (v2.0 Release)
- ✅ Zero gesture arena conflicts in common scenarios
- ✅ 60fps with 100+ interactive datapoints
- ✅ All mouse event types working (hover, click, right-click, wheel)
- ✅ Box selection with visual feedback
- ✅ Annotation drag, resize, edit
- ✅ Comprehensive test suite (80%+ coverage)

### Should Have (v2.0 or v2.1)
- ✅ 60fps with 500+ datapoints
- ✅ Touch gesture optimization
- ✅ Undo/redo for interactions
- ✅ Keyboard shortcuts
- ✅ Accessibility support

### Nice to Have (v2.1+)
- ✅ Advanced selection modes (lasso, polygon)
- ✅ Animation during interactions
- ✅ Collaborative editing support
- ✅ Interaction recording/playback

---

## Next Steps

### Immediate Actions (This Week)
1. **Complete conflict resolution table** with team decisions
2. **Start Phase 0 prototype** - create project structure
3. **Implement basic QuadTree** spatial index
4. **Create ChartInteractionCoordinator** skeleton
5. **Set up test infrastructure** for prototype

### This Sprint
1. Complete Phase 0 prototype implementation
2. Validate all conflict scenarios with tests
3. Performance benchmark with 100+ elements
4. Document findings and iterate on architecture

### Next Sprint
1. Analyze current braven_charts implementation (Phase 1)
2. Design migration strategy
3. Begin Phase 2 core implementation

---

## References

- [Flutter Gesture System Documentation](https://docs.flutter.dev/development/ui/advanced/gestures)
- [fl_chart Source Code](https://github.com/imaNNeoFighT/fl_chart)
- [Syncfusion Charts](https://pub.dev/packages/syncfusion_flutter_charts)
- Research Document: `docs/architecture/interaction/interaction-systems.md`

---

**Document Owner**: Development Team  
**Last Updated**: 2025-11-05  
**Status**: Living Document - Updated as decisions are made
