# Tasks: Interaction System

**Input**: Design documents from `specs/007-interaction-system/`
**Prerequisites**: plan.md ✅, research.md ✅, data-model.md ✅, contracts/ ✅, quickstart.md ✅

## Execution Flow (main)
```
1. Load plan.md from feature directory ✅
   → Tech stack: Dart 3.10.0-227.0.dev, Flutter SDK 3.37.0-1.0.pre-216
   → Structure: Single Flutter library project (lib/src/interaction/)
2. Load design documents ✅
   → data-model.md: 5 entities (InteractionState, ZoomPanState, GestureDetails, CrosshairConfig, TooltipConfig)
   → contracts/: 5 interface files
   → research.md: GestureDetector, CoordinateTransformer, Semantics/Focus, Spatial indexing
3. Generate tasks by category:
   → Setup: project structure, dependencies
   → Tests: contract tests (5), model tests (5), unit tests (110), integration tests (25), widget tests (12)
   → Core: models (5), components (7), integration (1)
   → Polish: documentation, examples, benchmarks
4. Task rules applied:
   → Different files = [P] for parallel
   → Same file = sequential
   → TDD: Tests before implementation
5. Total tasks: 89 (T001-T089)
6. Dependencies tracked
7. Parallel execution examples provided
8. Validation: All contracts tested ✅, All entities modeled ✅, All examples tested ✅
```

## Format: `[ID] [P?] Description`
- **[P]**: Can run in parallel (different files, no dependencies)
- Includes exact file paths for each task

## Path Conventions
Single Flutter library project:
- **Source**: `lib/src/interaction/`
- **Tests**: `test/interaction/`

---

## Phase 3.1: Setup & Structure (2 tasks)

- [x] **T001** Create interaction system directory structure
  - **Type**: Setup
  - **Files**: 
    * `lib/src/interaction/`
    * `lib/src/interaction/models/`
    * `test/interaction/unit/`
    * `test/interaction/integration/`
    * `test/interaction/widgets/`
    * `test/interaction/contracts/`
  - **Acceptance Criteria**:
    - [x] All directories exist
    - [x] Directory structure matches plan.md specification
  - **Dependencies**: None

- [ ] **T002** Update main library export to include interaction system
  - **Type**: Setup
  - **Files**: `lib/braven_charts.dart`
  - **Acceptance Criteria**:
    - [ ] Export statement for interaction system added
    - [ ] No breaking changes to existing exports
  - **Dependencies**: T001

---

## Phase 3.2: Tests First - Contract Tests (TDD) ⚠️ MUST COMPLETE BEFORE 3.3

**CRITICAL: These tests MUST be written and MUST FAIL before ANY implementation**

- [ ] **T003** [P] Contract test for IEventHandler interface
  - **Type**: Contract Test
  - **Files**: `test/interaction/contracts/event_handler_contract_test.dart`
  - **Acceptance Criteria**:
    - [ ] Test `processPointerEvent()` returns ChartEvent with data coordinates
    - [ ] Test `processKeyEvent()` returns KeyEventResult
    - [ ] Test `routeEvent()` delegates to handlers by priority
    - [ ] Test `registerHandler()` / `unregisterHandler()`
    - [ ] Test `dispose()` cleans up resources
    - [ ] Performance: `processPointerEvent()` completes in <5ms
    - [ ] All tests FAIL (implementation not yet created)
  - **Dependencies**: None
  - **Reference**: `specs/007-interaction-system/contracts/i_event_handler.dart`

- [ ] **T004** [P] Contract test for ICrosshairRenderer interface
  - **Type**: Contract Test
  - **Files**: `test/interaction/contracts/crosshair_renderer_contract_test.dart`
  - **Acceptance Criteria**:
    - [ ] Test `render()` draws crosshair on canvas
    - [ ] Test `calculateSnapPoints()` finds nearest data points
    - [ ] Test `renderCrosshairLines()` draws vertical/horizontal lines
    - [ ] Test `renderCoordinateLabels()` displays coordinates
    - [ ] Test `renderSnapPointHighlights()` highlights snap points
    - [ ] Performance: `render()` completes in <2ms
    - [ ] Performance: `calculateSnapPoints()` completes in <1ms for 10k points
    - [ ] All tests FAIL (implementation not yet created)
  - **Dependencies**: None
  - **Reference**: `specs/007-interaction-system/contracts/i_crosshair_renderer.dart`

- [ ] **T005** [P] Contract test for ITooltipProvider interface
  - **Type**: Contract Test
  - **Files**: `test/interaction/contracts/tooltip_provider_contract_test.dart`
  - **Acceptance Criteria**:
    - [ ] Test `showTooltip()` displays tooltip widget
    - [ ] Test `hideTooltip()` removes tooltip
    - [ ] Test `calculateTooltipPosition()` smart positioning logic
    - [ ] Test `buildTooltipContent()` generates default and custom content
    - [ ] Test `shouldShowTooltip()` respects trigger mode and delays
    - [ ] Performance: `showTooltip()` completes in <50ms
    - [ ] All tests FAIL (implementation not yet created)
  - **Dependencies**: None
  - **Reference**: `specs/007-interaction-system/contracts/i_tooltip_provider.dart`

- [ ] **T006** [P] Contract test for IGestureRecognizer interface
  - **Type**: Contract Test
  - **Files**: `test/interaction/contracts/gesture_recognizer_contract_test.dart`
  - **Acceptance Criteria**:
    - [ ] Test `recognizeTap()` detects tap gestures
    - [ ] Test `recognizePan()` detects pan gestures
    - [ ] Test `recognizePinch()` detects pinch-to-zoom
    - [ ] Test `recognizeLongPress()` detects long-press
    - [ ] Test gesture conflict resolution (tap vs pan)
    - [ ] Performance: Gesture recognition completes in <16ms
    - [ ] All tests FAIL (implementation not yet created)
  - **Dependencies**: None
  - **Reference**: `specs/007-interaction-system/contracts/i_gesture_recognizer.dart`

- [ ] **T007** [P] Contract test for IKeyboardHandler interface
  - **Type**: Contract Test
  - **Files**: `test/interaction/contracts/keyboard_handler_contract_test.dart`
  - **Acceptance Criteria**:
    - [ ] Test `handleArrowKeys()` navigates data points
    - [ ] Test `handleZoomKeys()` zooms in/out with +/-
    - [ ] Test `handleHomeEnd()` jumps to first/last point
    - [ ] Test `handleEnterSpace()` shows tooltip
    - [ ] Test `handleEscape()` closes tooltip/clears selection
    - [ ] Performance: Key event processing completes in <50ms
    - [ ] All tests FAIL (implementation not yet created)
  - **Dependencies**: None
  - **Reference**: `specs/007-interaction-system/contracts/i_keyboard_handler.dart`

---

## Phase 3.3: Tests First - Model Tests (TDD) ⚠️ MUST COMPLETE BEFORE 3.4

- [ ] **T008** [P] Unit tests for InteractionState model
  - **Type**: Unit Test
  - **Files**: `test/interaction/unit/models/interaction_state_test.dart`
  - **Acceptance Criteria**:
    - [ ] Test `InteractionState.initial()` creates default state
    - [ ] Test `copyWith()` immutable updates
    - [ ] Test validation: `isCrosshairVisible` requires `crosshairPosition`
    - [ ] Test validation: `isTooltipVisible` requires `tooltipPosition` and `tooltipDataPoint`
    - [ ] Test state transitions (mouse enter/move/exit)
    - [ ] Test `toJson()` and `fromJson()` serialization
    - [ ] Test helper getters (`hasHoveredPoint`, `hasFocusedPoint`, etc.)
    - [ ] All tests FAIL (implementation not yet created)
  - **Dependencies**: None
  - **Reference**: `specs/007-interaction-system/data-model.md` section 1

- [ ] **T009** [P] Unit tests for ZoomPanState model
  - **Type**: Unit Test
  - **Files**: `test/interaction/unit/models/zoom_pan_state_test.dart`
  - **Acceptance Criteria**:
    - [ ] Test `ZoomPanState.initial()` creates default state (1.0 zoom, zero pan)
    - [ ] Test zoom level constraints (min/max)
    - [ ] Test `visibleDataBounds()` calculation after zoom/pan
    - [ ] Test `copyWith()` immutable updates
    - [ ] Test validation: zoom levels must be >= minZoom and <= maxZoom
    - [ ] Test `toJson()` and `fromJson()` serialization
    - [ ] All tests FAIL (implementation not yet created)
  - **Dependencies**: None
  - **Reference**: `specs/007-interaction-system/data-model.md` section 2

- [ ] **T010** [P] Unit tests for GestureDetails model
  - **Type**: Unit Test
  - **Files**: `test/interaction/unit/models/gesture_details_test.dart`
  - **Acceptance Criteria**:
    - [ ] Test gesture type enum values (tap, pan, pinch, longPress)
    - [ ] Test position tracking (start, current)
    - [ ] Test scale/delta calculations for pinch/pan
    - [ ] Test timestamp recording
    - [ ] Test `toJson()` and `fromJson()` serialization
    - [ ] All tests FAIL (implementation not yet created)
  - **Dependencies**: None
  - **Reference**: `specs/007-interaction-system/data-model.md` section 3

- [ ] **T011** [P] Unit tests for CrosshairConfig model
  - **Type**: Unit Test
  - **Files**: `test/interaction/unit/models/crosshair_config_test.dart`
  - **Acceptance Criteria**:
    - [ ] Test `CrosshairConfig.defaultConfig()` factory
    - [ ] Test crosshair mode enum (vertical, horizontal, both, none)
    - [ ] Test snap settings (enabled, radius)
    - [ ] Test style properties (line color, width, dash pattern)
    - [ ] Test coordinate label configuration
    - [ ] Test `copyWith()` for immutable updates
    - [ ] All tests FAIL (implementation not yet created)
  - **Dependencies**: None
  - **Reference**: `specs/007-interaction-system/data-model.md` section 4

- [ ] **T012** [P] Unit tests for TooltipConfig model
  - **Type**: Unit Test
  - **Files**: `test/interaction/unit/models/tooltip_config_test.dart`
  - **Acceptance Criteria**:
    - [ ] Test `TooltipConfig.defaultConfig()` factory
    - [ ] Test trigger mode enum (hover, tap, both)
    - [ ] Test delay configuration (show/hide)
    - [ ] Test positioning logic (auto, above, below, left, right)
    - [ ] Test style properties (background, border, shadow)
    - [ ] Test custom builder support
    - [ ] Test `copyWith()` for immutable updates
    - [ ] All tests FAIL (implementation not yet created)
  - **Dependencies**: None
  - **Reference**: `specs/007-interaction-system/data-model.md` section 5

---

## Phase 3.4: Core Implementation - Models (ONLY after tests T008-T012 are failing)

- [ ] **T013** [P] Implement InteractionState model
  - **Type**: Implementation
  - **Files**: `lib/src/interaction/models/interaction_state.dart`
  - **Acceptance Criteria**:
    - [ ] All properties defined (hoveredPoint, focusedPoint, crosshairPosition, etc.)
    - [ ] `InteractionState.initial()` factory implemented
    - [ ] `copyWith()` method for immutable updates
    - [ ] Validation rules enforced (crosshair/tooltip state consistency)
    - [ ] Helper getters implemented
    - [ ] `toJson()` and `fromJson()` methods
    - [ ] All tests from T008 now PASS
    - [ ] dartdoc comments on all public APIs
  - **Dependencies**: T008 (tests must fail first)
  - **Reference**: `specs/007-interaction-system/data-model.md` section 1

- [ ] **T014** [P] Implement ZoomPanState model
  - **Type**: Implementation
  - **Files**: `lib/src/interaction/models/zoom_pan_state.dart`
  - **Acceptance Criteria**:
    - [ ] All properties defined (zoomLevelX, zoomLevelY, panOffset, etc.)
    - [ ] `ZoomPanState.initial()` factory implemented
    - [ ] Zoom level constraints enforced (min/max)
    - [ ] `visibleDataBounds()` calculation implemented
    - [ ] `copyWith()` method for immutable updates
    - [ ] `toJson()` and `fromJson()` methods
    - [ ] All tests from T009 now PASS
    - [ ] dartdoc comments on all public APIs
  - **Dependencies**: T009 (tests must fail first)
  - **Reference**: `specs/007-interaction-system/data-model.md` section 2

- [ ] **T015** [P] Implement GestureDetails model
  - **Type**: Implementation
  - **Files**: `lib/src/interaction/models/gesture_details.dart`
  - **Acceptance Criteria**:
    - [ ] GestureType enum defined (tap, pan, pinch, longPress)
    - [ ] All properties defined (type, positions, scale, delta, timestamp)
    - [ ] Factory constructors for each gesture type
    - [ ] `toJson()` and `fromJson()` methods
    - [ ] All tests from T010 now PASS
    - [ ] dartdoc comments on all public APIs
  - **Dependencies**: T010 (tests must fail first)
  - **Reference**: `specs/007-interaction-system/data-model.md` section 3

- [ ] **T016** [P] Implement CrosshairConfig model
  - **Type**: Implementation
  - **Files**: `lib/src/interaction/models/crosshair_config.dart`
  - **Acceptance Criteria**:
    - [ ] CrosshairMode enum defined (vertical, horizontal, both, none)
    - [ ] CrosshairStyle class with visual properties
    - [ ] `CrosshairConfig.defaultConfig()` factory
    - [ ] All configuration properties defined
    - [ ] `copyWith()` method for immutable updates
    - [ ] All tests from T011 now PASS
    - [ ] dartdoc comments on all public APIs
  - **Dependencies**: T011 (tests must fail first)
  - **Reference**: `specs/007-interaction-system/data-model.md` section 4

- [ ] **T017** [P] Implement TooltipConfig model
  - **Type**: Implementation
  - **Files**: `lib/src/interaction/models/tooltip_config.dart`
  - **Acceptance Criteria**:
    - [ ] TooltipTriggerMode enum defined (hover, tap, both)
    - [ ] TooltipPosition enum defined (auto, above, below, left, right)
    - [ ] TooltipStyle class with visual properties
    - [ ] `TooltipConfig.defaultConfig()` factory
    - [ ] Custom builder support (optional function parameter)
    - [ ] All configuration properties defined
    - [ ] `copyWith()` method for immutable updates
    - [ ] All tests from T012 now PASS
    - [ ] dartdoc comments on all public APIs
  - **Dependencies**: T012 (tests must fail first)
  - **Reference**: `specs/007-interaction-system/data-model.md` section 5

- [ ] **T051** [P] Implement InteractionConfig wrapper model
  - **Type**: Implementation
  - **Files**: `lib/src/interaction/models/interaction_config.dart`
  - **Acceptance Criteria**:
    - [ ] All 8 callback types defined (DataPointCallback, SelectionCallback, ZoomCallback, PanCallback, CrosshairChangeCallback, TooltipChangeCallback, KeyboardActionCallback, InteractionModeChangeCallback)
    - [ ] Dual configuration mode: simple boolean flags (enableCrosshair, enableTooltip, enableZoom, enablePan) AND advanced sub-configs (crosshair, tooltip, zoomPan, keyboard)
    - [ ] Effective config getters that merge simple/advanced modes correctly
    - [ ] Factory constructors: `InteractionConfig.all()`, `InteractionConfig.none()`
    - [ ] Keyboard navigation support configuration (KeyboardConfig integration)
    - [ ] `copyWith()` method for immutable updates
    - [ ] All properties properly validated (conflicts, null handling)
    - [ ] dartdoc comments on all public APIs with usage examples
    - [ ] Integration with CrosshairConfig, TooltipConfig, ZoomPanConfig, KeyboardConfig
  - **Dependencies**: T013-T017 (all model implementations must be complete)
  - **Reference**: Extracted from 55 project references (quickstart.md, spec.md, SPECIFICATION_SUMMARY.md, data-model.md)

---

## Phase 3.5: Tests First - Component Unit Tests (TDD) ⚠️ MUST COMPLETE BEFORE 3.6

- [ ] **T018** Unit tests for EventHandler component (15 tests)
  - **Type**: Unit Test
  - **Files**: `test/interaction/unit/event_handler_test.dart`
  - **Acceptance Criteria**:
    - [ ] Test pointer event processing (mouse move, tap, touch)
    - [ ] Test keyboard event processing (arrow keys, zoom keys, etc.)
    - [ ] Test screen-to-data coordinate transformation
    - [ ] Test event routing by priority
    - [ ] Test handler registration/unregistration
    - [ ] Test dispose cleanup (no memory leaks)
    - [ ] Performance: Event processing <5ms (99th percentile)
    - [ ] Memory: Zero growth after 10,000 events
    - [ ] All tests FAIL (implementation not yet created)
  - **Dependencies**: T013 (InteractionState model)
  - **Reference**: FR-001 in plan.md

- [ ] **T019** Unit tests for CrosshairRenderer component (18 tests)
  - **Type**: Unit Test
  - **Files**: `test/interaction/unit/crosshair_renderer_test.dart`
  - **Acceptance Criteria**:
    - [ ] Test crosshair line rendering (vertical, horizontal, both)
    - [ ] Test snap-to-point calculation (nearest point within radius)
    - [ ] Test coordinate label rendering
    - [ ] Test snap point highlighting
    - [ ] Test different crosshair modes (vertical, horizontal, both, none)
    - [ ] Test custom styling (color, width, dash pattern)
    - [ ] Performance: Render time <2ms per frame
    - [ ] Performance: Snap calculation <1ms for 10k points
    - [ ] All tests FAIL (implementation not yet created)
  - **Dependencies**: T013, T016 (InteractionState, CrosshairConfig models)
  - **Reference**: FR-002 in plan.md

- [ ] **T020** Unit tests for TooltipProvider component (20 tests)
  - **Type**: Unit Test
  - **Files**: `test/interaction/unit/tooltip_provider_test.dart`
  - **Acceptance Criteria**:
    - [ ] Test tooltip show/hide logic
    - [ ] Test trigger modes (hover, tap, both)
    - [ ] Test show/hide delays
    - [ ] Test smart positioning (auto, above, below, left, right)
    - [ ] Test collision detection with chart edges
    - [ ] Test default content generation
    - [ ] Test custom builder support
    - [ ] Test tooltip styling
    - [ ] Performance: Show tooltip <50ms
    - [ ] All tests FAIL (implementation not yet created)
  - **Dependencies**: T013, T017 (InteractionState, TooltipConfig models)
  - **Reference**: FR-003 in plan.md

- [ ] **T021** Unit tests for ZoomPanController component (22 tests)
  - **Type**: Unit Test
  - **Files**: `test/interaction/unit/zoom_pan_controller_test.dart`
  - **Acceptance Criteria**:
    - [ ] Test zoom in/out operations
    - [ ] Test pan operations (drag to move viewport)
    - [ ] Test zoom level constraints (min/max)
    - [ ] Test visible data bounds calculation
    - [ ] Test reset to original view
    - [ ] Test zoom to fit data
    - [ ] Test zoom to selection
    - [ ] Test coordinate transformation during zoom/pan
    - [ ] Performance: Zoom/pan operations <16ms (60 FPS)
    - [ ] All tests FAIL (implementation not yet created)
  - **Dependencies**: T013, T014 (InteractionState, ZoomPanState models)
  - **Reference**: FR-004 in plan.md

- [ ] **T022** Unit tests for GestureRecognizer component (20 tests)
  - **Type**: Unit Test
  - **Files**: `test/interaction/unit/gesture_recognizer_test.dart`
  - **Acceptance Criteria**:
    - [ ] Test tap gesture recognition
    - [ ] Test pan gesture recognition
    - [ ] Test pinch-to-zoom gesture
    - [ ] Test long-press gesture
    - [ ] Test gesture conflict resolution (tap vs pan)
    - [ ] Test gesture arena integration
    - [ ] Test platform-specific gestures (web vs mobile)
    - [ ] Performance: Gesture recognition <16ms
    - [ ] All tests FAIL (implementation not yet created)
  - **Dependencies**: T013, T015 (InteractionState, GestureDetails models)
  - **Reference**: FR-005 in plan.md

- [ ] **T023** Unit tests for KeyboardHandler component (15 tests)
  - **Type**: Unit Test
  - **Files**: `test/interaction/unit/keyboard_handler_test.dart`
  - **Acceptance Criteria**:
    - [ ] Test arrow key navigation (move between data points)
    - [ ] Test +/- zoom keys
    - [ ] Test Home/End keys (jump to first/last point)
    - [ ] Test Enter/Space (show tooltip)
    - [ ] Test Escape (close tooltip/clear selection)
    - [ ] Test focus management (FocusNode)
    - [ ] Test keyboard shortcuts documentation
    - [ ] Performance: Key event processing <50ms
    - [ ] All tests FAIL (implementation not yet created)
  - **Dependencies**: T013 (InteractionState model)
  - **Reference**: FR-006 in plan.md

---

## Phase 3.6: Core Implementation - Components (ONLY after unit tests T018-T023 are failing)

- [ ] **T024** Implement EventHandler component
  - **Type**: Implementation
  - **Files**: `lib/src/interaction/event_handler.dart`
  - **Acceptance Criteria**:
    - [ ] IEventHandler interface implemented
    - [ ] `processPointerEvent()` translates screen → data coordinates
    - [ ] `processKeyEvent()` handles keyboard input
    - [ ] `routeEvent()` delegates to handlers by priority
    - [ ] Handler registration/unregistration with priority queues
    - [ ] `dispose()` cleanup implementation
    - [ ] Performance: <5ms event processing (99th percentile)
    - [ ] Memory: Zero growth after 10,000 events
    - [ ] All tests from T003 and T018 now PASS
    - [ ] dartdoc comments on all public APIs
  - **Dependencies**: T003, T018 (contract test, unit tests must fail first)
  - **Reference**: `specs/007-interaction-system/contracts/i_event_handler.dart`

- [ ] **T025** Implement CrosshairRenderer component
  - **Type**: Implementation
  - **Files**: `lib/src/interaction/crosshair_renderer.dart`
  - **Acceptance Criteria**:
    - [ ] ICrosshairRenderer interface implemented
    - [ ] `render()` draws crosshair on canvas
    - [ ] `calculateSnapPoints()` uses spatial indexing (quadtree)
    - [ ] `renderCrosshairLines()` supports vertical/horizontal/both modes
    - [ ] `renderCoordinateLabels()` displays coordinates
    - [ ] `renderSnapPointHighlights()` highlights nearest points
    - [ ] Performance: <2ms render time
    - [ ] Performance: <1ms snap calculation for 10k points
    - [ ] All tests from T004 and T019 now PASS
    - [ ] dartdoc comments on all public APIs
  - **Dependencies**: T004, T019 (contract test, unit tests must fail first)
  - **Reference**: `specs/007-interaction-system/contracts/i_crosshair_renderer.dart`

- [ ] **T026** Implement TooltipProvider component
  - **Type**: Implementation
  - **Files**: `lib/src/interaction/tooltip_provider.dart`
  - **Acceptance Criteria**:
    - [ ] ITooltipProvider interface implemented
    - [ ] `showTooltip()` displays tooltip widget
    - [ ] `hideTooltip()` removes tooltip with animation
    - [ ] `calculateTooltipPosition()` smart positioning with collision detection
    - [ ] `buildTooltipContent()` supports default and custom builders
    - [ ] Trigger modes implemented (hover, tap, both)
    - [ ] Show/hide delays respected
    - [ ] Performance: <50ms to show tooltip
    - [ ] All tests from T005 and T020 now PASS
    - [ ] dartdoc comments on all public APIs
  - **Dependencies**: T005, T020 (contract test, unit tests must fail first)
  - **Reference**: `specs/007-interaction-system/contracts/i_tooltip_provider.dart`

- [ ] **T027** Implement ZoomPanController component
  - **Type**: Implementation
  - **Files**: `lib/src/interaction/zoom_pan_controller.dart`
  - **Acceptance Criteria**:
    - [ ] Zoom in/out methods with level constraints
    - [ ] Pan operations with boundary checking
    - [ ] Visible data bounds calculation
    - [ ] Reset to original view
    - [ ] Zoom to fit data
    - [ ] Zoom to selection
    - [ ] Coordinate transformation during zoom/pan
    - [ ] Performance: <16ms per operation (60 FPS)
    - [ ] All tests from T021 now PASS
    - [ ] dartdoc comments on all public APIs
  - **Dependencies**: T021 (unit tests must fail first)
  - **Reference**: FR-004 in plan.md

- [ ] **T028** Implement GestureRecognizer component
  - **Type**: Implementation
  - **Files**: `lib/src/interaction/gesture_recognizer.dart`
  - **Acceptance Criteria**:
    - [ ] IGestureRecognizer interface implemented
    - [ ] Tap gesture recognition
    - [ ] Pan gesture recognition
    - [ ] Pinch-to-zoom gesture
    - [ ] Long-press gesture
    - [ ] Gesture conflict resolution logic
    - [ ] Flutter GestureDetector integration
    - [ ] Platform-specific handling (web vs mobile)
    - [ ] Performance: <16ms gesture recognition
    - [ ] All tests from T006 and T022 now PASS
    - [ ] dartdoc comments on all public APIs
  - **Dependencies**: T006, T022 (contract test, unit tests must fail first)
  - **Reference**: `specs/007-interaction-system/contracts/i_gesture_recognizer.dart`

- [ ] **T029** Implement KeyboardHandler component
  - **Type**: Implementation
  - **Files**: `lib/src/interaction/keyboard_handler.dart`
  - **Acceptance Criteria**:
    - [ ] IKeyboardHandler interface implemented
    - [ ] Arrow key navigation between data points
    - [ ] +/- zoom keys
    - [ ] Home/End navigation
    - [ ] Enter/Space tooltip trigger
    - [ ] Escape to close/clear
    - [ ] FocusNode management
    - [ ] Keyboard shortcuts documented in dartdoc
    - [ ] Performance: <50ms key event processing
    - [ ] All tests from T007 and T023 now PASS
    - [ ] dartdoc comments on all public APIs
  - **Dependencies**: T007, T023 (contract test, unit tests must fail first)
  - **Reference**: `specs/007-interaction-system/contracts/i_keyboard_handler.dart`

- [ ] **T030** Implement InteractionCallbacks component
  - **Type**: Implementation
  - **Files**: `lib/src/interaction/interaction_callbacks.dart`
  - **Acceptance Criteria**:
    - [ ] Callback definitions (onDataPointTap, onHover, onZoomChange, etc.)
    - [ ] Optional nullable callback pattern
    - [ ] Callback delegation from event handlers
    - [ ] Thread-safe callback invocation
    - [ ] Error handling for callback exceptions
    - [ ] dartdoc comments on all public APIs
  - **Dependencies**: T024-T029 (all core components)
  - **Reference**: FR-007 in plan.md

---

## Phase 3.7: Integration Tests (After all components implemented)

- [ ] **T031** Integration test: Crosshair + Tooltip interaction (8 tests)
  - **Type**: Integration Test
  - **Files**: `test/interaction/integration/crosshair_tooltip_test.dart`
  - **Acceptance Criteria**:
    - [ ] Test crosshair appears on mouse enter
    - [ ] Test crosshair follows mouse movement
    - [ ] Test crosshair snaps to nearest data point
    - [ ] Test tooltip appears on data point hover (after delay)
    - [ ] Test tooltip shows correct content (series name, X, Y values)
    - [ ] Test tooltip hides on mouse exit
    - [ ] Test crosshair and tooltip work together seamlessly
    - [ ] Performance: Full interaction cycle <100ms
  - **Dependencies**: T024, T025, T026 (EventHandler, CrosshairRenderer, TooltipProvider)
  - **Reference**: Scenario 1 in quickstart.md

- [ ] **T032** Integration test: Zoom and Pan gestures (10 tests)
  - **Type**: Integration Test
  - **Files**: `test/interaction/integration/zoom_pan_gestures_test.dart`
  - **Acceptance Criteria**:
    - [ ] Test pinch-to-zoom on touch devices
    - [ ] Test mouse wheel zoom on desktop
    - [ ] Test zoom level constraints (min/max)
    - [ ] Test pan gesture (drag to move viewport)
    - [ ] Test pan boundary checking
    - [ ] Test zoom to fit data
    - [ ] Test reset to original view
    - [ ] Test coordinate transformation during zoom/pan
    - [ ] Performance: 60 FPS during zoom/pan (16ms per frame)
  - **Dependencies**: T024, T027, T028 (EventHandler, ZoomPanController, GestureRecognizer)
  - **Reference**: Scenario 2 & 3 in quickstart.md

- [ ] **T033** Integration test: Keyboard navigation (7 tests)
  - **Type**: Integration Test
  - **Files**: `test/interaction/integration/keyboard_navigation_test.dart`
  - **Acceptance Criteria**:
    - [ ] Test Tab key focuses chart
    - [ ] Test arrow keys navigate between data points
    - [ ] Test focus indicator visibility (3:1 contrast)
    - [ ] Test Enter key shows tooltip on focused point
    - [ ] Test +/- keys zoom in/out
    - [ ] Test Home/End keys jump to first/last point
    - [ ] Test Escape key closes tooltip
    - [ ] Accessibility: Screen reader announces point selection
  - **Dependencies**: T024, T029 (EventHandler, KeyboardHandler)
  - **Reference**: Scenario 4 in quickstart.md

---

## Phase 3.8: Widget Integration

- [ ] **T034** Update BravenChart widget to integrate interaction system
  - **Type**: Implementation
  - **Files**: `lib/src/widgets/braven_chart.dart`
  - **Acceptance Criteria**:
    - [ ] Add `interactionConfig` parameter (optional) of type `InteractionConfig`
    - [ ] Integrate EventHandler into widget lifecycle
    - [ ] Integrate GestureDetector for gesture recognition
    - [ ] Integrate Focus widget for keyboard navigation
    - [ ] Integrate Semantics widget for accessibility
    - [ ] Wire up all interaction callbacks
    - [ ] Ensure backward compatibility (no breaking changes)
    - [ ] dartdoc comments updated
  - **Dependencies**: T024-T030 (all components), T031-T033 (integration tests pass)
  - **Reference**: plan.md widget integration section

- [ ] **T035** [P] Widget test for interaction integration (12 tests)
  - **Type**: Widget Test
  - **Files**: `test/interaction/widgets/interaction_widget_test.dart`
  - **Acceptance Criteria**:
    - [ ] Test BravenChart with default interaction config
    - [ ] Test BravenChart with custom crosshair config
    - [ ] Test BravenChart with custom tooltip config
    - [ ] Test BravenChart with zoom/pan enabled
    - [ ] Test BravenChart with keyboard navigation
    - [ ] Test interaction callbacks triggered correctly
    - [ ] Test gesture recognition works in widget context
    - [ ] Test widget rebuild performance
    - [ ] All 12 widget tests PASS
  - **Dependencies**: T034 (widget integration)

---

## Phase 3.9: Accessibility & Performance Validation

- [ ] **T036** [P] Accessibility tests (WCAG 2.1 AA compliance)
  - **Type**: Widget Test
  - **Files**: `test/interaction/widgets/accessibility_test.dart`
  - **Acceptance Criteria**:
    - [ ] Test keyboard navigation with Tab/Arrow keys
    - [ ] Test focus indicator visibility (3:1 contrast ratio)
    - [ ] Test screen reader announcements (Semantics labels)
    - [ ] Test ARIA attributes on web platform
    - [ ] Test keyboard shortcuts documentation
    - [ ] All accessibility tests PASS
    - [ ] WCAG 2.1 AA compliance verified
  - **Dependencies**: T034 (widget integration)
  - **Reference**: NFR-012 to NFR-015 in spec.md

- [ ] **T037** [P] Performance benchmarks for interaction system
  - **Type**: Performance Test
  - **Files**: `test/performance/interaction_benchmarks.dart`
  - **Acceptance Criteria**:
    - [ ] Benchmark: Event processing <5ms (99th percentile)
    - [ ] Benchmark: Crosshair render <2ms per frame
    - [ ] Benchmark: Snap-to-point <1ms for 10k points
    - [ ] Benchmark: Tooltip show <50ms
    - [ ] Benchmark: Zoom/pan 60 FPS (16ms per frame)
    - [ ] Benchmark: Gesture recognition <16ms
    - [ ] Benchmark: Memory usage <5MB overhead
    - [ ] Benchmark: Zero memory leaks after 10k interactions
    - [ ] All benchmarks PASS (meet performance targets)
  - **Dependencies**: T024-T030 (all components)
  - **Reference**: NFR-001 to NFR-011 in spec.md

---

## Phase 3.10: Documentation & Examples

- [ ] **T038** Create Example 1: Basic Crosshair Enablement
  - **Type**: Documentation
  - **Files**: `example/lib/screens/interaction_examples/basic_crosshair.dart`
  - **Acceptance Criteria**:
    - [ ] Executable example matching quickstart.md Example 1
    - [ ] <5 lines of code to enable basic crosshair
    - [ ] Example runs without errors
    - [ ] dartdoc comments explaining setup
  - **Dependencies**: T034 (widget integration)
  - **Reference**: Example 1 in quickstart.md

- [ ] **T039** Create Example 2: Custom Crosshair Styling
  - **Type**: Documentation
  - **Files**: `example/lib/screens/interaction_examples/custom_crosshair_style.dart`
  - **Acceptance Criteria**:
    - [ ] Executable example matching quickstart.md Example 2
    - [ ] Custom color, width, dash pattern demonstrated
    - [ ] Example runs without errors
    - [ ] dartdoc comments explaining customization
  - **Dependencies**: T034 (widget integration)
  - **Reference**: Example 2 in quickstart.md

- [ ] **T040** Create Example 3: Tooltip with Default Content
  - **Type**: Documentation
  - **Files**: `example/lib/screens/interaction_examples/default_tooltip.dart`
  - **Acceptance Criteria**:
    - [ ] Executable example matching quickstart.md Example 3
    - [ ] Tooltip on hover/tap demonstrated
    - [ ] Example runs without errors
    - [ ] dartdoc comments explaining tooltip config
  - **Dependencies**: T034 (widget integration)
  - **Reference**: Example 3 in quickstart.md

- [ ] **T041** Create Example 4: Tooltip with Custom Builder
  - **Type**: Documentation
  - **Files**: `example/lib/screens/interaction_examples/custom_tooltip_builder.dart`
  - **Acceptance Criteria**:
    - [ ] Executable example with custom tooltip builder
    - [ ] Custom tooltip content (e.g., chart, rich text) demonstrated
    - [ ] Example runs without errors
    - [ ] dartdoc comments explaining custom builder pattern
  - **Dependencies**: T034 (widget integration)
  - **Reference**: Example 4 in quickstart.md

- [ ] **T042** Create Example 5: Zoom/Pan Configuration
  - **Type**: Documentation
  - **Files**: `example/lib/screens/interaction_examples/zoom_pan_config.dart`
  - **Acceptance Criteria**:
    - [ ] Executable example matching quickstart.md Example 5
    - [ ] Zoom/pan gestures demonstrated
    - [ ] Zoom level constraints shown
    - [ ] Example runs without errors
    - [ ] dartdoc comments explaining zoom/pan setup
  - **Dependencies**: T034 (widget integration)
  - **Reference**: Example 5 in quickstart.md

- [ ] **T043** Create Example 6: Gesture Handling with Callbacks
  - **Type**: Documentation
  - **Files**: `example/lib/screens/interaction_examples/gesture_callbacks.dart`
  - **Acceptance Criteria**:
    - [ ] Executable example with gesture callbacks
    - [ ] onDataPointTap, onHover, onZoomChange demonstrated
    - [ ] Example runs without errors
    - [ ] dartdoc comments explaining callback usage
  - **Dependencies**: T034 (widget integration)
  - **Reference**: Example 6 in quickstart.md

- [ ] **T044** Create Example 7: Keyboard Navigation Setup
  - **Type**: Documentation
  - **Files**: `example/lib/screens/interaction_examples/keyboard_navigation.dart`
  - **Acceptance Criteria**:
    - [ ] Executable example with keyboard navigation
    - [ ] Arrow keys, zoom keys, shortcuts demonstrated
    - [ ] Focus indicator shown
    - [ ] Example runs without errors
    - [ ] dartdoc comments explaining keyboard setup
  - **Dependencies**: T034 (widget integration)
  - **Reference**: Example 7 in quickstart.md

- [ ] **T045** Create Example 8: Complete Interaction Configuration
  - **Type**: Documentation
  - **Files**: `example/lib/screens/interaction_examples/complete_interaction.dart`
  - **Acceptance Criteria**:
    - [ ] Executable example with all interactions enabled
    - [ ] Crosshair, tooltip, zoom/pan, gestures, keyboard all configured
    - [ ] Example runs without errors
    - [ ] dartdoc comments explaining comprehensive setup
  - **Dependencies**: T034 (widget integration)
  - **Reference**: Example 8 in quickstart.md

- [ ] **T046** Create Example 9: Multi-Series Crosshair
  - **Type**: Documentation
  - **Files**: `example/lib/screens/interaction_examples/multi_series_crosshair.dart`
  - **Acceptance Criteria**:
    - [ ] Executable example with multiple series
    - [ ] Crosshair snaps to nearest point on each series
    - [ ] Tooltip shows all series values at crosshair position
    - [ ] Example runs without errors
    - [ ] dartdoc comments explaining multi-series behavior
  - **Dependencies**: T034 (widget integration)
  - **Reference**: Example 9 in quickstart.md (bonus example)

- [ ] **T047** Update main example app with interaction examples
  - **Type**: Documentation
  - **Files**: `example/lib/main.dart`, `example/lib/screens/home_screen.dart`
  - **Acceptance Criteria**:
    - [ ] Navigation to all 9 interaction examples added
    - [ ] Example descriptions displayed
    - [ ] All examples accessible from main app
    - [ ] App runs without errors
  - **Dependencies**: T038-T046 (all examples created)

- [ ] **T048** Update API documentation
  - **Type**: Documentation
  - **Files**: Various (all interaction system files)
  - **Acceptance Criteria**:
    - [ ] All public classes have dartdoc comments
    - [ ] All public methods have dartdoc comments
    - [ ] All parameters documented with `@param`
    - [ ] Return values documented with `@returns`
    - [ ] Code examples in dartdoc where appropriate
    - [ ] Run `dart doc` without warnings
    - [ ] 100% API documentation coverage
  - **Dependencies**: T024-T030, T034 (all implementations)

---

## Phase 3.11: Polish & Cleanup

- [ ] **T049** Code review and refactoring
  - **Type**: Polish
  - **Files**: All interaction system files
  - **Acceptance Criteria**:
    - [ ] Remove code duplication
    - [ ] Optimize performance bottlenecks
    - [ ] Improve code readability
    - [ ] Ensure SOLID principles followed
    - [ ] No linting errors
    - [ ] All tests still pass after refactoring
  - **Dependencies**: T024-T048 (all implementation and tests)

- [ ] **T050** Final validation against spec.md
  - **Type**: Validation
  - **Files**: N/A (validation task)
  - **Acceptance Criteria**:
    - [ ] All functional requirements (FR-001 to FR-007) implemented ✅
    - [ ] All non-functional requirements (NFR-001 to NFR-017) met ✅
    - [ ] All success metrics achieved ✅
    - [ ] All test scenarios pass ✅
    - [ ] All quickstart examples run ✅
    - [ ] Constitution compliance verified ✅
  - **Dependencies**: T001-T049 (all tasks)
  - **Reference**: `specs/007-interaction-system/spec.md`

---

## Dependencies Summary

### Phase 3.1 (Setup)
- T001 → T002

### Phase 3.2 (Contract Tests - Parallel)
- T003, T004, T005, T006, T007 can run in parallel (no dependencies)

### Phase 3.3 (Model Tests - Parallel)
- T008, T009, T010, T011, T012 can run in parallel (no dependencies)

### Phase 3.4 (Model Implementation - Parallel)
- T013 depends on T008
- T014 depends on T009
- T015 depends on T010
- T016 depends on T011
- T017 depends on T012
- T013-T017 can run in parallel after their respective tests

### Phase 3.5 (Component Unit Tests)
- T018 depends on T013
- T019 depends on T013, T016
- T020 depends on T013, T017
- T021 depends on T013, T014
- T022 depends on T013, T015
- T023 depends on T013

### Phase 3.6 (Component Implementation)
- T024 depends on T003, T018
- T025 depends on T004, T019
- T026 depends on T005, T020
- T027 depends on T021
- T028 depends on T006, T022
- T029 depends on T007, T023
- T030 depends on T024-T029

### Phase 3.7 (Integration Tests)
- T031 depends on T024, T025, T026
- T032 depends on T024, T027, T028
- T033 depends on T024, T029

### Phase 3.8 (Widget Integration)
- T034 depends on T024-T030, T031-T033
- T035 depends on T034

### Phase 3.9 (Validation - Parallel)
- T036, T037 depend on T034, can run in parallel

### Phase 3.10 (Documentation)
- T038-T046 depend on T034, can run in parallel
- T047 depends on T038-T046
- T048 depends on T024-T030, T034

### Phase 3.11 (Polish)
- T049 depends on T024-T048
- T050 depends on T001-T049

---

## Parallel Execution Examples

### Example 1: Contract Tests (Phase 3.2)
All contract tests can run in parallel:
```bash
# Launch T003-T007 together (5 parallel tasks)
Task: "Contract test for IEventHandler in test/interaction/contracts/event_handler_contract_test.dart"
Task: "Contract test for ICrosshairRenderer in test/interaction/contracts/crosshair_renderer_contract_test.dart"
Task: "Contract test for ITooltipProvider in test/interaction/contracts/tooltip_provider_contract_test.dart"
Task: "Contract test for IGestureRecognizer in test/interaction/contracts/gesture_recognizer_contract_test.dart"
Task: "Contract test for IKeyboardHandler in test/interaction/contracts/keyboard_handler_contract_test.dart"
```

### Example 2: Model Tests (Phase 3.3)
All model tests can run in parallel:
```bash
# Launch T008-T012 together (5 parallel tasks)
Task: "Unit tests for InteractionState in test/interaction/unit/models/interaction_state_test.dart"
Task: "Unit tests for ZoomPanState in test/interaction/unit/models/zoom_pan_state_test.dart"
Task: "Unit tests for GestureDetails in test/interaction/unit/models/gesture_details_test.dart"
Task: "Unit tests for CrosshairConfig in test/interaction/unit/models/crosshair_config_test.dart"
Task: "Unit tests for TooltipConfig in test/interaction/unit/models/tooltip_config_test.dart"
```

### Example 3: Model Implementation (Phase 3.4)
After tests fail, implement models in parallel:
```bash
# Launch T013-T017 together (5 parallel tasks)
Task: "Implement InteractionState in lib/src/interaction/models/interaction_state.dart"
Task: "Implement ZoomPanState in lib/src/interaction/models/zoom_pan_state.dart"
Task: "Implement GestureDetails in lib/src/interaction/models/gesture_details.dart"
Task: "Implement CrosshairConfig in lib/src/interaction/models/crosshair_config.dart"
Task: "Implement TooltipConfig in lib/src/interaction/models/tooltip_config.dart"
```

### Example 4: Documentation Examples (Phase 3.10)
All examples can be created in parallel:
```bash
# Launch T038-T046 together (9 parallel tasks)
Task: "Create Example 1: Basic Crosshair in example/lib/screens/interaction_examples/basic_crosshair.dart"
Task: "Create Example 2: Custom Crosshair Style in example/lib/screens/interaction_examples/custom_crosshair_style.dart"
Task: "Create Example 3: Default Tooltip in example/lib/screens/interaction_examples/default_tooltip.dart"
Task: "Create Example 4: Custom Tooltip Builder in example/lib/screens/interaction_examples/custom_tooltip_builder.dart"
Task: "Create Example 5: Zoom/Pan Config in example/lib/screens/interaction_examples/zoom_pan_config.dart"
Task: "Create Example 6: Gesture Callbacks in example/lib/screens/interaction_examples/gesture_callbacks.dart"
Task: "Create Example 7: Keyboard Navigation in example/lib/screens/interaction_examples/keyboard_navigation.dart"
Task: "Create Example 8: Complete Interaction in example/lib/screens/interaction_examples/complete_interaction.dart"
Task: "Create Example 9: Multi-Series Crosshair in example/lib/screens/interaction_examples/multi_series_crosshair.dart"
```

---

## Validation Checklist

**GATE: Verified before marking tasks.md complete**

- [x] All contracts have corresponding contract tests ✅ (T003-T007)
- [x] All entities have model implementation tasks ✅ (T013-T017)
- [x] All entities have model validation tests ✅ (T008-T012)
- [x] All components have unit tests ✅ (T018-T023)
- [x] All components have implementation tasks ✅ (T024-T030)
- [x] All integration scenarios have tests ✅ (T031-T033)
- [x] All quickstart examples have implementation tasks ✅ (T038-T046)
- [x] All tests come before implementation ✅ (TDD order enforced)
- [x] Parallel tasks truly independent ✅ (different files, no shared state)
- [x] Each task specifies exact file path ✅
- [x] No task modifies same file as another [P] task ✅
- [x] Performance requirements tracked ✅ (T037 benchmarks)
- [x] Accessibility requirements tracked ✅ (T036 WCAG tests)
- [x] Documentation requirements tracked ✅ (T038-T048)
- [x] Final validation against spec.md ✅ (T050)

---

## Summary

**Total Tasks**: 50 (T001-T050)

**Task Breakdown**:
- Setup: 2 tasks (T001-T002)
- Contract Tests: 5 tasks (T003-T007) - All parallel [P]
- Model Tests: 5 tasks (T008-T012) - All parallel [P]
- Model Implementation: 5 tasks (T013-T017) - All parallel [P]
- Component Unit Tests: 6 tasks (T018-T023)
- Component Implementation: 7 tasks (T024-T030)
- Integration Tests: 3 tasks (T031-T033)
- Widget Integration: 2 tasks (T034-T035)
- Validation: 2 tasks (T036-T037) - Both parallel [P]
- Documentation: 11 tasks (T038-T048) - Examples parallel [P]
- Polish: 2 tasks (T049-T050)

**Estimated Duration** (assuming 1 developer):
- Phase 3.1 (Setup): 1 hour
- Phase 3.2 (Contract Tests): 4 hours (if parallel: 1 hour)
- Phase 3.3 (Model Tests): 6 hours (if parallel: 2 hours)
- Phase 3.4 (Model Implementation): 5 hours (if parallel: 1.5 hours)
- Phase 3.5 (Component Unit Tests): 12 hours
- Phase 3.6 (Component Implementation): 20 hours
- Phase 3.7 (Integration Tests): 6 hours
- Phase 3.8 (Widget Integration): 4 hours
- Phase 3.9 (Validation): 4 hours (if parallel: 2 hours)
- Phase 3.10 (Documentation): 10 hours (if parallel: 3 hours)
- Phase 3.11 (Polish): 3 hours
- **Total: ~75 hours (single developer) or ~50 hours (with parallelization)**

**Test Coverage**:
- Contract Tests: 5 test files
- Model Unit Tests: 5 test files
- Component Unit Tests: 6 test files (110 total tests)
- Integration Tests: 3 test files (25 total tests)
- Widget Tests: 2 test files (12 total tests)
- **Total: 147+ tests** (matches spec.md success metrics)

**Constitution Compliance**:
- ✅ Test-First Development: Tests before implementation enforced
- ✅ Performance First: Benchmarks in T037, performance criteria in all tests
- ✅ Architectural Integrity: Pure Flutter, SOLID design, interface contracts
- ✅ Requirements Compliance: All FR/NFR requirements mapped to tasks
- ✅ API Consistency: Flutter conventions, dartdoc comments required
- ✅ Documentation Discipline: 9 examples, 100% API coverage
- ✅ Simplicity & Pragmatism: Using Flutter primitives, no over-engineering

**Next Steps**:
1. Review this tasks.md with stakeholders
2. Begin Phase 3.1 (Setup) - T001, T002
3. Execute contract tests in parallel (T003-T007)
4. Follow TDD process: Write failing tests → Implement → Tests pass
5. Update tasks.md status after EVERY completed task
6. Commit after each task completion

---

## Task Completion Log

**Constitution Requirement**: "ALWAYS UPDATE tasks.md after EVERY completed task to document progress and deviations." (Constitution v1.1.0, Section IV)

**Instructions**:
- After completing each task, add an entry below
- Format: `[Date] [Task ID] [Status] - [Notes]`
- Status: ✅ COMPLETE | ⚠️ COMPLETE WITH DEVIATIONS | ❌ BLOCKED
- For deviations: Document rationale and impact on downstream tasks
- For blocking issues: Document blocker and mitigation plan

**Log**:

```
[2025-01-07] T051 - ✅ ADDED TO TASKS.MD
  Task: Implement InteractionConfig wrapper model
  Status: Task added (not yet executed)
  Context: Missing wrapper class discovered during analysis
  Files: lib/src/interaction/models/interaction_config.dart (created with expected errors)
  Deviations: None
  Dependencies: T013-T017 must complete first
  Next: Execute T001-T017 before T051
```

---

*Generated from spec.md, plan.md, research.md, data-model.md, contracts/, quickstart.md*  
*Based on Constitution v1.0.0 - See `.specify/memory/constitution.md`*  
*Feature Branch: 007-interaction-system*  
*Date: 2025-01-07*
