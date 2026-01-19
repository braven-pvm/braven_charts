# Feature Specification: ValueNotifier Architecture Refactor

**Feature Branch**: `008-valuenotifier-refactor`  
**Created**: 2025-01-21  
**Status**: Draft  
**Input**: User description: "We are in dire need of an architectural refactor. Detail is in this document: architecture_refactor_plan.md"

## Clarifications

### Session 2025-01-21

- Q: What minimum unit test coverage is required for the ValueNotifier refactor to ensure reliability? → A: 90% coverage
- Q: When updates occur faster than 60Hz (>60 updates/second), how should the system handle them? → A: Throttle updates to 60Hz maximum using frame-based coalescing
- Q: How should existing chart instances handle the migration from setState to ValueNotifier pattern? → A: Automatic migration - no user action required (internal refactor only)
- Q: How should the system handle simultaneous multiple interaction types (zoom + pan + hover)? → A: Allow non-conflicting interactions simultaneously with proper state isolation
- Q: How should memory leaks be prevented when disposing ValueNotifier instances? → A: Dispose ValueNotifier, remove all listeners, cancel timers, dispose animation controllers

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Smooth Mouse Interactions Without Crashes (Priority: P1)

Users interact with charts using mouse movements (hover, zoom, pan) and the system responds smoothly without crashes or errors. Mouse movements over chart elements show crosshairs, tooltips, and data point highlights in real-time without any lag or application freezes.

**Why this priority**: This is the critical bug fix - the current system crashes catastrophically with `box.dart:3345` and `mouse_tracker.dart:199` errors when interactionConfig is enabled. Without this fix, the interaction system is completely unusable.

**Independent Test**: Can be fully tested by enabling interactionConfig, hovering mouse over a chart with data points, and verifying zero crashes occur and crosshair/tooltip appear smoothly. Delivers immediate value by making the interaction system functional.

**Acceptance Scenarios**:

1. **Given** a chart with interactionConfig enabled and 50+ data points, **When** user moves mouse across the chart continuously, **Then** crosshair follows mouse position smoothly without any crashes or console errors
2. **Given** a chart with streaming data updating every 100ms, **When** user hovers mouse over chart during data updates, **Then** chart continues updating smoothly, mouse tracking works correctly, and no rendering errors occur
3. **Given** a chart displaying 1000 data points, **When** user performs rapid mouse movements (100+ pixels/second), **Then** system maintains 60fps frame rate and coordinates remain accurate

---

### User Story 2 - Zero Performance Degradation During Interactions (Priority: P2)

Users experience consistent 60fps performance during all mouse interactions regardless of dataset size or interaction frequency. The chart feels responsive and professional even with thousands of data points and continuous mouse movements.

**Why this priority**: Performance is a constitutional requirement (60fps target). After stability is achieved (P1), performance optimization ensures the solution scales and meets professional standards.

**Independent Test**: Can be tested independently by profiling frame times during mouse hover interactions with large datasets (1000+ points). Delivers measurable performance improvements verifiable through DevTools.

**Acceptance Scenarios**:

1. **Given** a chart with 5000 data points, **When** user moves mouse continuously over the chart, **Then** frame times remain under 16ms (60fps) with zero widget rebuilds detected in DevTools
2. **Given** multiple charts on screen with interactionConfig enabled, **When** user interacts with one chart, **Then** other charts are not affected and overall frame rate stays above 55fps
3. **Given** a chart with active zoom/pan animations, **When** user hovers mouse during animation, **Then** animation continues smoothly and mouse tracking works without interference

---

### User Story 3 - Simultaneous Controller Updates and Interactions (Priority: P3)

Users can programmatically update chart data via ChartController while simultaneously hovering/interacting with the mouse, and both operations work correctly without conflicts or errors.

**Why this priority**: This addresses the edge case discovered during testing where controller updates conflicted with interaction state. Important for streaming/real-time data scenarios but less critical than basic functionality.

**Independent Test**: Can be tested by adding data points via controller.addPoint() while continuously moving mouse over chart. Delivers confidence that controller and interaction system are properly isolated.

**Acceptance Scenarios**:

1. **Given** a chart with controller attached and mouse hovering over data points, **When** new data points are added via controller.addPoint(), **Then** both mouse tracking and data updates work correctly without crashes
2. **Given** a chart with auto-scroll enabled and active mouse hover, **When** chart auto-scrolls due to new data, **Then** mouse position updates correctly and crosshair remains accurate
3. **Given** a chart with annotations being added programmatically, **When** user interacts with mouse simultaneously, **Then** both operations complete successfully without state conflicts

---

### Edge Cases

- What happens when user performs extremely rapid mouse movements (1000+ pixels/second) over complex charts? System throttles updates to 60Hz using frame-based coalescing to prevent excessive repaints while maintaining responsiveness.
- How does system handle mouse interactions during intensive operations (large dataset rendering, multiple animations)?
- What happens when multiple interaction types occur simultaneously (zoom + pan + hover)? Non-conflicting interactions are allowed simultaneously with proper state isolation - each interaction type updates its own portion of InteractionState, and ValueNotifier coalesces them into a single update.
- How does system behave when interaction state updates occur faster than frame rate (>60 updates/second)? Updates are throttled to 60Hz maximum, with ValueNotifier coalescing multiple updates within a single frame.
- What happens during rapid enable/disable cycles of interactionConfig?

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST eliminate all setState calls for interaction state updates (crosshair, tooltip, hover state)
- **FR-002**: System MUST use ValueNotifier pattern for managing interaction state (InteractionState)
- **FR-003**: System MUST wrap interactive overlays (crosshair, tooltip) in ValueListenableBuilder
- **FR-004**: System MUST isolate interactive overlays using RepaintBoundary to prevent cascade repaints
- **FR-005**: System MUST properly dispose of ValueNotifier instances in widget dispose() method, including removing all listeners, canceling timers, and disposing animation controllers to prevent memory leaks
- **FR-006**: System MUST update all event handlers to update notifier value directly without setState. Specific handlers to refactor:
  - **Mouse/Pointer Handlers**: onHover (MouseRegion), onExit (MouseRegion), onPointerSignal (Listener - zoom/scroll), onPointerDown (Listener - pan start), onPointerMove (Listener - pan drag), onPointerUp (Listener - pan end)
  - **Gesture Handlers**: onTapDown (GestureDetector), onScaleStart (GestureDetector - pinch zoom/pan), onScaleUpdate (GestureDetector), onScaleEnd (GestureDetector)
  - **Keyboard Handler**: onKeyEvent (KeyboardListener - modifier keys)
  - **Total**: 11 interaction handlers
- **FR-007**: System MUST update animation controller listeners (zoom, pan) to use notifier instead of setState
- **FR-008**: System MUST update controller callbacks (_onControllerUpdate, _onDataStreamPoint) to use notifier
- **FR-009**: System MUST update timer callbacks (tooltip hide timer) to use notifier
- **FR-010**: System MUST delete deprecated _safeSetState() method and all its usages
- **FR-011**: System MUST ensure base chart rendering never depends on interaction state (separation of concerns)
- **FR-012**: System MUST maintain backward compatibility with existing public APIs (no breaking changes to BravenChart widget interface)
- **FR-013**: System MUST throttle interaction state updates to 60Hz maximum using frame-based coalescing when updates occur faster than the frame rate
- **FR-014**: Migration MUST be automatic and transparent to users - existing chart instances work without code changes (internal refactor only)
- **FR-015**: System MUST support simultaneous non-conflicting interactions (zoom + pan + hover) with proper state isolation, where each interaction type updates its own portion of InteractionState

### Key Entities

- **InteractionState**: Represents current interaction state including crosshair visibility/position, tooltip data, hover information, zoom/pan state, and keyboard modifier states. Currently stored as plain field, will be wrapped in ValueNotifier.
- **ValueNotifier<InteractionState>**: Reactive state container that notifies listeners when interaction state changes, enabling granular UI updates without widget rebuilds.
- **Interactive Overlays**: Visual elements (crosshair, tooltip) that render on top of base chart and update frequently based on mouse position. Will be isolated in RepaintBoundary with ValueListenableBuilder.
- **Event Handlers**: 11 handler methods that respond to user interactions and currently trigger setState, will be refactored to update notifier value:
  - Mouse/Pointer: onHover, onExit, onPointerSignal, onPointerDown, onPointerMove, onPointerUp (6 handlers)
  - Gesture: onTapDown, onScaleStart, onScaleUpdate, onScaleEnd (4 handlers)
  - Keyboard: onKeyEvent (1 handler)
- **Base Chart**: The chart rendering layer (axes, grid, data series) that should remain stable and never rebuild during mouse interactions.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Charts with interactionConfig enabled operate without crashes - zero `box.dart:3345` or `mouse_tracker.dart:199` errors during continuous mouse interaction sessions
- **SC-002**: Mouse interactions maintain 60fps performance - frame times under 16ms during continuous hover over charts with 1000+ data points, verified through performance profiling
- **SC-003**: Widget rebuild count during mouse hover drops to zero - DevTools shows no widget tree rebuilds when only mouse position changes
- **SC-004**: Interactive overlays repaint independently - only CustomPainter repaints detected during mouse movements, base chart remains stable
- **SC-005**: Users can perform 1000+ consecutive mouse movements over chart without any performance degradation or memory leaks
- **SC-006**: Concurrent operations work correctly - users can add data via controller while hovering mouse with zero conflicts or errors (100% success rate in stress tests)
- **SC-007**: All existing integration tests pass - zero regressions in functionality, all acceptance scenarios from user stories verified
- **SC-008**: Unit test coverage reaches minimum 90% for all refactored code including event handlers, animation listeners, controller callbacks, timer callbacks, and disposal logic

### Assumptions

- Interaction system code is primarily in `lib/src/widgets/braven_chart.dart` file
- InteractionState class exists with copyWith() method for immutable updates
- CustomPainter implementations (_CrosshairPainter, tooltip painters) are already implemented and just need new integration approach
- RepaintBoundary and ValueListenableBuilder are available in Flutter version being used (standard Flutter widgets)
- Existing event handler structure (_onHover, _onExit, etc.) can be modified without breaking other dependencies
- ChartController interface remains stable and doesn't require changes
- Performance profiling will be done using Flutter DevTools
- Testing will cover all 11+ interaction handlers, animation controllers, controller callbacks, and timer callbacks mentioned in implementation checklist

