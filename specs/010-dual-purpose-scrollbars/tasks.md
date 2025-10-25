# Tasks: Dual-Purpose Scrollbars for Chart Navigation

**Input**: Design documents from `/specs/010-dual-purpose-scrollbars/`  
**Prerequisites**: plan.md ✅, spec.md ✅, research.md ✅, data-model.md ✅, contracts/ ✅

**Tech Stack**: Dart 3.10.0-227.0.dev, Flutter SDK 3.37.0-1.0.pre-216  
**Project Type**: Flutter library (adding scrollbar components to lib/src/)

**Tests**: Contract tests and golden tests are MANDATORY per Constitution I (Test-First Development). Integration tests validate user stories.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `- [ ] [ID] [P?] [Story] Description`
- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions
- **lib/src/**: Source code for chart library
- **test/**: All test files (contract/, unit/, integration/, golden/)
- All paths relative to repository root: `E:\cloud services\Dropbox\Repositories\Flutter\braven_charts_v2.0\`

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Project initialization and basic structure for scrollbar feature

- [X] T001 Verify Flutter SDK 3.37.0-1.0.pre-216 and Dart 3.10.0-227.0.dev installation
- [X] T002 [P] Create scrollbar directory structure in lib/src/widgets/
- [X] T003 [P] Create scrollbar theming directory structure in lib/src/theming/components/
- [X] T004 [P] Create test directory structure for scrollbar tests in test/

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core scrollbar infrastructure that MUST be complete before ANY user story can be implemented

**⚠️ CRITICAL**: No user story work can begin until this phase is complete. These are shared components used by all stories.

### Foundational Entities (Data Model)

- [X] T005 [P] Create HitTestZone enum in lib/src/widgets/scrollbar/hit_test_zone.dart
- [X] T006 [P] Create ScrollbarState immutable data class in lib/src/widgets/scrollbar/scrollbar_state.dart
- [X] T007 [P] Create ScrollbarConfig data class with 16 properties in lib/src/theming/components/scrollbar_config.dart
- [X] T008 Create ScrollbarTheme component theme in lib/src/theming/components/scrollbar_theme.dart (depends on T007)

### Foundational Contract Tests (TDD - Write Tests FIRST) ⚠️

**CRITICAL: Write these tests FIRST, ensure they FAIL before implementation per Constitution I**

- [X] T009 [P] Contract test for ScrollbarController.calculateHandleSize() in test/contract/widgets/scrollbar_controller_handle_size_test.dart
- [X] T010 [P] Contract test for ScrollbarController.calculateHandlePosition() in test/contract/widgets/scrollbar_controller_position_test.dart
- [X] T011 [P] Contract test for ScrollbarController.handleToDataRange() inverse transform in test/contract/widgets/scrollbar_controller_inverse_test.dart
- [X] T012 [P] Contract test for ScrollbarController.dataRangeToHandle() in test/contract/widgets/scrollbar_controller_forward_test.dart
- [ ] T013 [P] Contract test for ScrollbarConfig immutability and copyWith() in test/contract/theming/scrollbar_config_test.dart
- [X] T014 [P] Contract test for ScrollbarTheme integration with ChartTheme in test/contract/theming/scrollbar_theme_test.dart

### Foundational Controllers (Pure Functions)

**NOTE: Implement AFTER contract tests T009-T014 pass (TDD Red-Green-Refactor)**

- [X] T015 [P] Implement ScrollbarController.calculateHandleSize() in lib/src/widgets/scrollbar/scrollbar_controller.dart
- [X] T016 [P] Implement ScrollbarController.calculateHandlePosition() in lib/src/widgets/scrollbar/scrollbar_controller.dart
- [X] T017 Implement ScrollbarController.handleToDataRange() in lib/src/widgets/scrollbar/scrollbar_controller.dart (depends on T015, T016)
- [X] T018 [P] Implement ScrollbarController.dataRangeToHandle() in lib/src/widgets/scrollbar/scrollbar_controller.dart
- [X] T019 [P] Implement ScrollbarController.getHitTestZone() with 8.0px edge zones (FR-008/009 enhanced) in lib/src/widgets/scrollbar/scrollbar_controller.dart
- [X] T020 [P] Implement ScrollbarController.getCursorForZone() in lib/src/widgets/scrollbar/scrollbar_controller.dart
- [X] T020A Implement ScrollbarController.getInteractionState() to determine current state (default/hover/active/disabled per FR-021A) in lib/src/widgets/scrollbar/scrollbar_controller.dart
- [X] T020B Implement ScrollbarController.calculateTouchHitTestPadding() for 44x44 minimum touch targets (FR-024A) in lib/src/widgets/scrollbar/scrollbar_controller.dart

### Foundational Rendering

- [X] T021 Create ScrollbarPainter CustomPainter in lib/src/widgets/scrollbar/scrollbar_painter.dart
- [X] T022 Implement ScrollbarPainter.paint() method for track rendering in lib/src/widgets/scrollbar/scrollbar_painter.dart
- [X] T023 Implement ScrollbarPainter handle rendering with border radius in lib/src/widgets/scrollbar/scrollbar_painter.dart
- [X] T024 Implement ScrollbarPainter grip indicator rendering in lib/src/widgets/scrollbar/scrollbar_painter.dart
- [X] T024A Implement ScrollbarPainter interaction state rendering (default, hover, active, disabled per FR-021A) in lib/src/widgets/scrollbar/scrollbar_painter.dart
- [X] T024B Implement ScrollbarPainter track hover state rendering (opacity 0.2 → 0.3 per FR-021B) in lib/src/widgets/scrollbar/scrollbar_painter.dart
- [X] T024C Implement ScrollbarPainter corner overlap rendering for multi-axis (0.5 opacity blend per FR-015A) in lib/src/widgets/scrollbar/scrollbar_painter.dart

### Foundational Widget Structure

- [X] T025 Create ChartScrollbar StatefulWidget skeleton in lib/src/widgets/chart_scrollbar.dart
- [X] T026 Create _ChartScrollbarState class with ValueNotifier<ScrollbarState> in lib/src/widgets/chart_scrollbar.dart
- [X] T027 Implement _ChartScrollbarState.initState() with ScrollbarState initialization in lib/src/widgets/chart_scrollbar.dart
- [X] T028 Implement _ChartScrollbarState.dispose() with ValueNotifier cleanup in lib/src/widgets/chart_scrollbar.dart

### Foundational Theme Integration

- [X] T029 Modify ChartTheme to add scrollbarTheme field in lib/src/theming/chart_theme.dart
- [X] T030 Update ChartTheme.copyWith() to include scrollbarTheme in lib/src/theming/chart_theme.dart
- [X] T031 Update ChartTheme.toJson() and fromJson() to serialize scrollbarTheme in lib/src/theming/chart_theme.dart
- [X] T032 [P] Add ScrollbarTheme.defaultLight predefined theme with FR-025 colors (track 0x33000000, handle 0x99000000) in lib/src/theming/components/scrollbar_theme.dart
- [X] T033 [P] Add ScrollbarTheme.defaultDark predefined theme with FR-025 colors (track 0x33FFFFFF, handle 0x99FFFFFF) in lib/src/theming/components/scrollbar_theme.dart
- [X] T034 [P] Add ScrollbarTheme.highContrast predefined theme with FR-025 colors (track solid black/white, handle yellow/cyan, 7:1 contrast) in lib/src/theming/components/scrollbar_theme.dart
- [X] T034A Add ScrollbarConfig.forcedColorsMode support for Windows High Contrast (FR-024B) in lib/src/theming/components/scrollbar_config.dart
- [X] T034B Add ScrollbarConfig.prefersReducedMotion support (FR-024C - disables animations when true) in lib/src/theming/components/scrollbar_config.dart

### Foundational InteractionConfig Modifications

- [X] T035 Add showXScrollbar boolean field to InteractionConfig in lib/src/interaction/interaction_config.dart
- [X] T036 Add showYScrollbar boolean field to InteractionConfig in lib/src/interaction/interaction_config.dart
- [X] T037 Update InteractionConfig.copyWith() to include scrollbar flags in lib/src/interaction/interaction_config.dart
- [X] T038 Update InteractionConfig.toJson() and fromJson() to serialize scrollbar flags in lib/src/interaction/interaction_config.dart

**Checkpoint**: Foundation ready - user story implementation can now begin in parallel

---

## Phase 3: User Story 1 - Navigate Large Dataset with Visual Feedback (Priority: P1) 🎯 MVP

**Goal**: Display scrollbar with handle size representing visible percentage of data. Users can see where they are in the dataset while zoomed in.

**Independent Test**: Zoom into any chart until viewport shows <100% of data. Verify scrollbar appears with handle size = (viewport / data) ratio. Test passes if handle occupies 10% of track when viewing 10% of data.

**Constitutional Requirements**:
- ✅ Test-First Development: Contract tests written before implementation
- ✅ Performance First: ValueNotifier pattern for >10Hz pointer events (no setState)
- ✅ Architectural Integrity: Scrollbar layout independent of TransformContext

### Contract Tests for User Story 1 (TDD - Write FIRST) ⚠️

**NOTE: Write these tests FIRST, ensure they FAIL before implementation**

- [X] T039 [P] [US1] Contract test for ChartScrollbar widget rendering in test/contract/widgets/chart_scrollbar_render_test.dart
- [X] T040 [P] [US1] Contract test for handle size calculation accuracy in test/contract/widgets/scrollbar_handle_size_accuracy_test.dart
- [X] T041 [P] [US1] Contract test for handle position calculation accuracy in test/contract/widgets/scrollbar_handle_position_accuracy_test.dart
- [X] T042 [P] [US1] Golden test for scrollbar visual appearance (horizontal) in test/golden/scrollbar_horizontal_visual_test.dart
- [X] T043 [P] [US1] Golden test for scrollbar visual appearance (vertical) in test/golden/scrollbar_vertical_visual_test.dart

### Implementation for User Story 1

- [X] T044 [US1] Implement ChartScrollbar.build() with ValueListenableBuilder in lib/src/widgets/chart_scrollbar.dart
- [X] T045 [US1] Wire ScrollbarPainter into CustomPaint widget in lib/src/widgets/chart_scrollbar.dart
- [X] T046 [US1] Calculate handle size using ScrollbarController in ChartScrollbar.build() in lib/src/widgets/chart_scrollbar.dart
- [X] T047 [US1] Calculate handle position using ScrollbarController in ChartScrollbar.build() in lib/src/widgets/chart_scrollbar.dart
- [X] T048 [US1] Implement didUpdateWidget() to sync handle with external viewport changes in lib/src/widgets/chart_scrollbar.dart
- [X] T049 [US1] Add RepaintBoundary wrapper around ChartScrollbar in lib/src/widgets/chart_scrollbar.dart
- [X] T050 [US1] Modify BravenChart to conditionally render X scrollbar based on InteractionConfig.showXScrollbar in lib/src/widgets/braven_chart.dart
- [X] T051 [US1] Modify BravenChart to conditionally render Y scrollbar based on InteractionConfig.showYScrollbar in lib/src/widgets/braven_chart.dart
- [X] T052 [US1] Implement BravenChart layout structure (Column/Row) to position scrollbars outside chart canvas in lib/src/widgets/braven_chart.dart
- [X] T053 [US1] Wire ChartScrollbar.dataRange from BravenChart's full data range in lib/src/widgets/braven_chart.dart
- [X] T054 [US1] Wire ChartScrollbar.viewportRange from BravenChart's ViewportState in lib/src/widgets/braven_chart.dart
- [X] T055 [US1] Wire ChartScrollbar.theme from ChartTheme.scrollbarTheme in lib/src/widgets/braven_chart.dart

### Integration Tests for User Story 1

- [X] T056 [US1] Integration test: Zoom in to 10% → verify scrollbar appears with 10% handle size in test/integration/scrollbar_zoom_visual_feedback_test.dart
- [X] T057 [US1] Integration test: Viewport at 100% → verify scrollbar hidden in test/integration/scrollbar_auto_hide_full_viewport_test.dart
- [X] T058 [US1] Integration test: Viewport at 30% position → verify handle at 30% track position in test/integration/scrollbar_position_accuracy_test.dart

**Checkpoint**: At this point, User Story 1 should be fully functional - scrollbar displays with correct handle size/position reflecting viewport state

---

## Phase 4: User Story 2 - Pan Through Data via Scrollbar (Priority: P1) 🎯 MVP

**Goal**: Users can drag scrollbar handle to pan through data without touching chart. Handle drag updates viewport, chart re-renders with new visible range.

**Independent Test**: Drag scrollbar handle from left edge to center. Verify chart viewport pans to show middle section of data. Zoom level remains constant (handle size unchanged).

**Constitutional Requirements**:
- ✅ Performance First: 60 FPS during drag (viewport updates throttled to 16ms, <16.67ms frame time)
- ✅ Test-First Development: Widget tests for gesture handling before implementation

### Contract Tests for User Story 2 (TDD - Write FIRST) ⚠️

- [X] T059 [P] [US2] Contract test for GestureDetector onPanStart handling in test/contract/widgets/scrollbar_gesture_pan_start_test.dart
- [X] T060 [P] [US2] Contract test for GestureDetector onPanUpdate handling in test/contract/widgets/scrollbar_gesture_pan_update_test.dart
- [ ] T061 [P] [US2] Contract test for GestureDetector onPanEnd handling in test/contract/widgets/scrollbar_gesture_pan_end_test.dart
- [ ] T062 [US2] Contract test for viewport update throttling (60 FPS) in test/contract/widgets/scrollbar_throttle_test.dart

### Implementation for User Story 2

- [ ] T063 [US2] Add GestureDetector wrapper in ChartScrollbar.build() in lib/src/widgets/chart_scrollbar.dart
- [ ] T064 [US2] Implement _onPanStart() to detect drag zone (center vs edges) in lib/src/widgets/chart_scrollbar.dart
- [ ] T065 [US2] Implement _onPanUpdate() for handle drag (center zone) in lib/src/widgets/chart_scrollbar.dart
- [ ] T066 [US2] Update ScrollbarState.handlePosition via ValueNotifier in _onPanUpdate() in lib/src/widgets/chart_scrollbar.dart
- [ ] T067 [US2] Implement viewport update throttling (16ms timer) in _onPanUpdate() in lib/src/widgets/chart_scrollbar.dart
- [ ] T068 [US2] Convert handle position delta to DataRange delta using ScrollbarController.handleToDataRange() in lib/src/widgets/chart_scrollbar.dart
- [ ] T069 [US2] Fire onViewportChanged callback with new DataRange in lib/src/widgets/chart_scrollbar.dart
- [ ] T070 [US2] Implement _onPanEnd() to ensure final viewport sync in lib/src/widgets/chart_scrollbar.dart
- [ ] T071 [US2] Fire InteractionConfig.onPanChanged callback in _onPanEnd() with delta offset in lib/src/widgets/chart_scrollbar.dart
- [ ] T072 [US2] Add boundary clamping (no overscroll beyond dataRange) in lib/src/widgets/chart_scrollbar.dart
- [ ] T073 [US2] Implement track click (onTapUp) to jump viewport to click position with 300ms ease-out animation (Curves.easeOut per FR-007 enhanced) in lib/src/widgets/chart_scrollbar.dart
- [ ] T073A [US2] Implement state transition animations using 150ms ease-in-out curve (Curves.easeInOut per FR-007 enhanced) for hover/active/focus states in lib/src/widgets/chart_scrollbar.dart
- [ ] T073B [US2] Implement animation cancellation for concurrent interactions (FR-048 enhanced) - new interaction cancels active animation immediately in lib/src/widgets/chart_scrollbar.dart

### Integration Tests for User Story 2

- [ ] T074 [US2] Integration test: Drag handle from 0% to 50% → verify viewport pans to middle in test/integration/scrollbar_drag_pan_test.dart
- [ ] T075 [US2] Integration test: Drag beyond data boundaries → verify clamping (no overscroll) in test/integration/scrollbar_boundary_clamp_test.dart
- [ ] T076 [US2] Integration test: Click track at 70% → verify handle animates to 70% over 300ms in test/integration/scrollbar_track_click_jump_test.dart
- [ ] T077 [US2] Integration test: Rapid drag → verify 60 FPS throttling (max 1 update per 16ms) in test/integration/scrollbar_throttle_performance_test.dart
- [ ] T078 [US2] Integration test: Pan drag completes → verify onPanChanged callback fired with delta in test/integration/scrollbar_pan_callback_test.dart

### Performance Tests for User Story 2

- [ ] T079 [US2] Benchmark ScrollbarController calculations (<0.1ms) in test/performance/scrollbar_calculation_benchmark.dart
- [ ] T080 [US2] Benchmark frame time during drag (target <16.67ms) in test/performance/scrollbar_drag_frame_time_test.dart

**Checkpoint**: User Stories 1 AND 2 should both work independently - scrollbar displays AND pans viewport on drag

---

## Phase 5: User Story 3 - Zoom via Scrollbar Handle Resize (Priority: P2)

**Goal**: Users can drag scrollbar handle edges to zoom in/out. Left edge drag adjusts viewport min (right edge fixed), right edge drag adjusts viewport max (left edge fixed).

**Independent Test**: Drag right edge of handle leftward. Verify chart zooms in (shows less data) with left boundary fixed at original position. Handle size shrinks to match new viewport ratio.

**Constitutional Requirements**:
- ✅ Performance First: Edge drag same performance as center drag (60 FPS, throttled updates)
- ✅ Architectural Integrity: Zoom updates ViewportState via withRanges(), no direct coordinate system modification

### Contract Tests for User Story 3 (TDD - Write FIRST) ⚠️

- [ ] T079 [P] [US3] Contract test for HitTestZone detection (leftEdge/rightEdge) in test/contract/widgets/scrollbar_hit_test_edge_detection_test.dart
- [ ] T080 [P] [US3] Contract test for left edge drag (adjusts viewportMin) in test/contract/widgets/scrollbar_left_edge_resize_test.dart
- [ ] T081 [P] [US3] Contract test for right edge drag (adjusts viewportMax) in test/contract/widgets/scrollbar_right_edge_resize_test.dart
- [ ] T082 [P] [US3] Contract test for minimum handle size clamping in test/contract/widgets/scrollbar_min_handle_size_test.dart
- [ ] T083 [P] [US3] Golden test for edge resize cursors (↔) in test/golden/scrollbar_edge_cursor_test.dart

### Implementation for User Story 3

- [ ] T084 [US3] Implement _onHover() to detect edge zones and update cursor in lib/src/widgets/chart_scrollbar.dart
- [ ] T085 [US3] Store hover zone in ScrollbarState.hoverZone via ValueNotifier in lib/src/widgets/chart_scrollbar.dart
- [ ] T086 [US3] Modify _onPanStart() to detect leftEdge/rightEdge zones in lib/src/widgets/chart_scrollbar.dart
- [ ] T087 [US3] Implement _onPanUpdate() for left edge drag (resize viewport min) in lib/src/widgets/chart_scrollbar.dart
- [ ] T088 [US3] Implement _onPanUpdate() for right edge drag (resize viewport max) in lib/src/widgets/chart_scrollbar.dart
- [ ] T089 [US3] Calculate new viewport min/max using ScrollbarController edge formulas in lib/src/widgets/chart_scrollbar.dart
- [ ] T090 [US3] Enforce minZoomRatio (1% minimum visible) from ScrollbarConfig in lib/src/widgets/chart_scrollbar.dart
- [ ] T091 [US3] Enforce maxZoomRatio (100% maximum visible) from ScrollbarConfig in lib/src/widgets/chart_scrollbar.dart
- [ ] T091A [US3] Implement zoom limit feedback: flash animation (opacity 0.8 → 0.4 → 0.8 over 200ms per FR-011 enhanced) when zoom limit reached in lib/src/widgets/chart_scrollbar.dart
- [ ] T091B [US3] Implement zoom limit feedback: cursor changes to 'not-allowed' when dragging beyond zoom limits (FR-011 enhanced) in lib/src/widgets/chart_scrollbar.dart
- [ ] T092 [US3] Fire InteractionConfig.onZoomChanged callback in edge resize _onPanEnd() with zoom ratio change in lib/src/widgets/chart_scrollbar.dart
- [ ] T093 [US3] Update cursor via MouseRegion based on hoverZone in lib/src/widgets/chart_scrollbar.dart
- [ ] T094 [US3] Implement SystemMouseCursors.resizeColumn for horizontal scrollbar edges in lib/src/widgets/chart_scrollbar.dart
- [ ] T095 [US3] Implement SystemMouseCursors.resizeRow for vertical scrollbar edges in lib/src/widgets/chart_scrollbar.dart

### Integration Tests for User Story 3

- [ ] T096 [US3] Integration test: Drag right edge left → verify zoom in with left edge anchored in test/integration/scrollbar_right_edge_zoom_test.dart
- [ ] T097 [US3] Integration test: Drag left edge right → verify zoom in with right edge anchored in test/integration/scrollbar_left_edge_zoom_test.dart
- [ ] T098 [US3] Integration test: Zoom to min handle size → verify clamping at 1% visible in test/integration/scrollbar_zoom_limit_test.dart
- [ ] T099 [US3] Integration test: Hover over edge → verify cursor changes to ↔ in test/integration/scrollbar_edge_cursor_change_test.dart
- [ ] T100 [US3] Integration test: enableZoom=false → verify edges not draggable in test/integration/scrollbar_zoom_disabled_test.dart
- [ ] T101 [US3] Integration test: Edge resize completes → verify onZoomChanged callback fired with zoom ratio in test/integration/scrollbar_zoom_callback_test.dart

**Checkpoint**: User Stories 1, 2, AND 3 should all work independently - scrollbar displays, pans, AND zooms

---

## Phase 6: User Story 4 - Keyboard Navigation for Accessibility (Priority: P3)

**Goal**: Users can navigate chart using only keyboard. Tab focuses scrollbar, arrow keys pan, Ctrl+arrow zooms, Home/End jump to boundaries.

**Independent Test**: Using only keyboard: Tab to focus scrollbar → press Right Arrow 5 times → verify viewport pans right by 25% (5 × 5% increments). No mouse required.

**Constitutional Requirements**:
- ✅ Architectural Integrity: Accessibility mandatory (WCAG 2.1 AA compliance, keyboard navigation)
- ✅ API Consistency: Follow Flutter FocusNode and KeyboardListener patterns

### Contract Tests for User Story 4 (TDD - Write FIRST) ⚠️

- [ ] T100 [P] [US4] Contract test for FocusNode focus/unfocus handling in test/contract/widgets/scrollbar_focus_test.dart
- [ ] T101 [P] [US4] Contract test for arrow key pan (5% increments) in test/contract/widgets/scrollbar_keyboard_pan_test.dart
- [ ] T102 [P] [US4] Contract test for Shift+arrow fast pan (25% increments) in test/contract/widgets/scrollbar_keyboard_fast_pan_test.dart
- [ ] T103 [P] [US4] Contract test for Ctrl+arrow zoom (±10%) in test/contract/widgets/scrollbar_keyboard_zoom_test.dart
- [ ] T104 [P] [US4] Contract test for Home/End key (jump to boundaries) in test/contract/widgets/scrollbar_keyboard_jump_test.dart
- [ ] T105 [P] [US4] Contract test for Page Up/Down (jump 1 viewport width) in test/contract/widgets/scrollbar_keyboard_page_test.dart

### Implementation for User Story 4

- [ ] T106 [US4] Add FocusNode to _ChartScrollbarState in lib/src/widgets/chart_scrollbar.dart
- [ ] T107 [US4] Initialize FocusNode in initState() in lib/src/widgets/chart_scrollbar.dart
- [ ] T108 [US4] Dispose FocusNode in dispose() in lib/src/widgets/chart_scrollbar.dart
- [ ] T109 [US4] Add Focus widget wrapper in ChartScrollbar.build() in lib/src/widgets/chart_scrollbar.dart
- [ ] T110 [US4] Implement onFocusChange callback to update ScrollbarState.isFocused in lib/src/widgets/chart_scrollbar.dart
- [ ] T111 [US4] Add KeyboardListener for key events in lib/src/widgets/chart_scrollbar.dart
- [ ] T112 [US4] Implement _onKeyEvent() to route key presses to handlers in lib/src/widgets/chart_scrollbar.dart
- [ ] T113 [US4] Implement arrow key handler (pan 5% of viewport) in lib/src/widgets/chart_scrollbar.dart
- [ ] T114 [US4] Implement Shift+arrow key handler (pan 25% of viewport) in lib/src/widgets/chart_scrollbar.dart
- [ ] T115 [US4] Implement Ctrl+arrow key handler (zoom ±10%) in lib/src/widgets/chart_scrollbar.dart
- [ ] T116 [US4] Implement Home key handler (jump to dataRange.min) in lib/src/widgets/chart_scrollbar.dart
- [ ] T117 [US4] Implement End key handler (jump to dataRange.max) in lib/src/widgets/chart_scrollbar.dart
- [ ] T118 [US4] Implement Page Up/Down handler (jump 1 viewport width) in lib/src/widgets/chart_scrollbar.dart
- [ ] T119 [US4] Add focus indicator rendering (2px outline) to ScrollbarPainter in lib/src/widgets/scrollbar/scrollbar_painter.dart

### Accessibility Tests for User Story 4

- [ ] T120 [US4] Accessibility test: Tab navigation → verify scrollbar receives focus in test/integration/scrollbar_keyboard_focus_test.dart
- [ ] T121 [US4] Accessibility test: Arrow keys → verify pan without mouse in test/integration/scrollbar_keyboard_only_navigation_test.dart
- [ ] T122 [US4] Accessibility test: Screen reader → verify semantic labels announced in test/integration/scrollbar_screen_reader_test.dart
- [ ] T123 [US4] Golden test: Focus indicator visible when focused in test/golden/scrollbar_focus_indicator_test.dart

**Checkpoint**: User Stories 1-4 all work independently - scrollbar displays, pans, zooms, AND keyboard-accessible

---

## Phase 7: User Story 5 - Themed Scrollbar Appearance (Priority: P3)

**Goal**: Scrollbars automatically adapt to chart theme (light/dark/high contrast). Developers can customize colors, sizes, and behavior via ScrollbarConfig.

**Independent Test**: Apply ChartTheme.defaultDark to chart. Verify scrollbar uses dark theme colors (light handle on dark track). Change to ChartTheme.highContrast → verify high contrast colors (21:1 ratio).

**Constitutional Requirements**:
- ✅ API Consistency: Theme integration follows existing ChartTheme patterns
- ✅ Documentation Discipline: dartdoc comments for all ScrollbarConfig properties

### Contract Tests for User Story 5 (TDD - Write FIRST) ⚠️

- [ ] T124 [P] [US5] Contract test for ScrollbarConfig.defaultLight contrast ratios (≥4.5:1) in test/contract/theming/scrollbar_config_light_contrast_test.dart
- [ ] T125 [P] [US5] Contract test for ScrollbarConfig.defaultDark contrast ratios (≥4.5:1) in test/contract/theming/scrollbar_config_dark_contrast_test.dart
- [ ] T126 [P] [US5] Contract test for ScrollbarConfig.highContrast ratios (≥21:1) in test/contract/theming/scrollbar_config_high_contrast_test.dart
- [ ] T127 [P] [US5] Contract test for ScrollbarConfig.copyWith() immutability in test/contract/theming/scrollbar_config_copyWith_test.dart
- [ ] T128 [P] [US5] Golden test for defaultLight theme appearance in test/golden/scrollbar_theme_light_test.dart
- [ ] T129 [P] [US5] Golden test for defaultDark theme appearance in test/golden/scrollbar_theme_dark_test.dart
- [ ] T130 [P] [US5] Golden test for highContrast theme appearance in test/golden/scrollbar_theme_high_contrast_test.dart

### Implementation for User Story 5

- [ ] T131 [US5] Implement ScrollbarConfig.defaultLight with WCAG AA colors in lib/src/theming/components/scrollbar_config.dart
- [ ] T132 [US5] Implement ScrollbarConfig.defaultDark with WCAG AA colors in lib/src/theming/components/scrollbar_config.dart
- [ ] T133 [US5] Implement ScrollbarConfig.highContrast with WCAG AAA colors in lib/src/theming/components/scrollbar_config.dart
- [ ] T134 [US5] Implement hover state color transitions in ScrollbarPainter in lib/src/widgets/scrollbar/scrollbar_painter.dart
- [ ] T135 [US5] Implement active state color transitions in ScrollbarPainter in lib/src/widgets/scrollbar/scrollbar_painter.dart
- [ ] T136 [US5] Apply ScrollbarConfig.borderRadius to handle rendering in lib/src/widgets/scrollbar/scrollbar_painter.dart
- [ ] T137 [US5] Apply ScrollbarConfig.thickness to scrollbar layout in lib/src/widgets/chart_scrollbar.dart
- [ ] T138 [US5] Implement auto-hide animation (fade to 0 opacity) in lib/src/widgets/chart_scrollbar.dart
- [ ] T139 [US5] Implement auto-hide timer (2 second delay) in lib/src/widgets/chart_scrollbar.dart
- [ ] T140 [US5] Reset auto-hide timer on pointer enter in lib/src/widgets/chart_scrollbar.dart

### Integration Tests for User Story 5

- [ ] T141 [US5] Integration test: Apply defaultDark theme → verify dark colors in test/integration/scrollbar_theme_dark_integration_test.dart
- [ ] T142 [US5] Integration test: Hover over handle → verify hover color transition in test/integration/scrollbar_hover_state_test.dart
- [ ] T143 [US5] Integration test: Auto-hide enabled → verify fade after 2s inactivity in test/integration/scrollbar_auto_hide_test.dart
- [ ] T144 [US5] Integration test: Custom thickness → verify scrollbar width matches in test/integration/scrollbar_custom_thickness_test.dart

### Accessibility Tests for User Story 5

- [ ] T145 [US5] Accessibility test: Verify WCAG 2.1 AA contrast ratios for all predefined themes in test/integration/scrollbar_wcag_contrast_test.dart
- [ ] T146 [US5] Accessibility test: High contrast theme → verify screen reader compatibility in test/integration/scrollbar_high_contrast_screen_reader_test.dart

**Checkpoint**: All user stories should now be independently functional - scrollbar displays, pans, zooms, keyboard-accessible, AND themed

---

## Phase 8: Accessibility & Semantics (Cross-Cutting)

**Purpose**: WCAG 2.1 AA compliance across all user stories

- [ ] T147 [P] Add Semantics widget wrapper to ChartScrollbar in lib/src/widgets/chart_scrollbar.dart
- [ ] T148 [P] Implement dynamic Semantics.label (e.g., "Chart X-axis scrollbar") in lib/src/widgets/chart_scrollbar.dart
- [ ] T149 [P] Implement dynamic Semantics.value (e.g., "Showing 25-75%, 50% of data") in lib/src/widgets/chart_scrollbar.dart
- [ ] T150 [P] Implement Semantics.hint (e.g., "Drag to pan, use arrow keys") in lib/src/widgets/chart_scrollbar.dart
- [ ] T151 [P] Implement Semantics.onIncrease (pan right/up) in lib/src/widgets/chart_scrollbar.dart
- [ ] T152 [P] Implement Semantics.onDecrease (pan left/down) in lib/src/widgets/chart_scrollbar.dart
- [ ] T153 Accessibility test: Screen reader announces state changes in test/integration/scrollbar_screen_reader_announcements_test.dart
- [ ] T153A Accessibility test: Touch target minimum 44x44 pixels (FR-024A WCAG 2.5.5) in test/integration/scrollbar_touch_target_test.dart
- [ ] T153B Accessibility test: High-contrast mode renders with system colors and borders (FR-024B) in test/integration/scrollbar_forced_colors_test.dart
- [ ] T153C Accessibility test: Reduced motion disables all animations (FR-024C WCAG 2.3.3) in test/integration/scrollbar_reduced_motion_test.dart
- [ ] T153D Accessibility test: Interaction state consistency between X/Y scrollbars (FR-021C) in test/integration/scrollbar_state_consistency_test.dart

---

## Phase 9: Polish & Documentation

**Purpose**: Improvements that affect multiple user stories

### Documentation

- [ ] T154 [P] Add dartdoc comments to all ChartScrollbar public methods in lib/src/widgets/chart_scrollbar.dart
- [ ] T155 [P] Add dartdoc comments to all ScrollbarController methods in lib/src/widgets/scrollbar/scrollbar_controller.dart
- [ ] T156 [P] Add dartdoc comments to all ScrollbarConfig properties in lib/src/theming/components/scrollbar_config.dart
- [ ] T157 [P] Add dartdoc comments to ScrollbarTheme in lib/src/theming/components/scrollbar_theme.dart
- [ ] T158 Copy quickstart.md to docs/guides/scrollbar-usage.md
- [ ] T159 Update example/lib/main.dart with scrollbar demo
- [ ] T160 Create example/lib/charts/scrollbar_examples.dart with 4 common patterns

### Code Quality

- [ ] T161 Run `dart analyze` and fix all warnings in lib/src/widgets/chart_scrollbar.dart
- [ ] T162 Run `dart analyze` and fix all warnings in lib/src/theming/components/
- [ ] T163 Run `dart format` on all scrollbar source files
- [ ] T164 Verify zero Dart analyzer warnings (constitutional requirement)

### Performance Validation

- [ ] T165 Run performance benchmarks and verify <0.1ms calculations in test/performance/scrollbar_calculation_benchmark.dart
- [ ] T166 Run frame time tests and verify <16.67ms during drag in test/performance/scrollbar_drag_frame_time_test.dart
- [ ] T167 Run memory profiler and verify <100KB overhead in test/performance/scrollbar_memory_overhead_test.dart
- [ ] T168 Run jank detection test and verify 0% dropped frames in test/performance/scrollbar_jank_detection_test.dart

### Integration & Validation

- [ ] T169 Verify TransformContext.chartAreaBounds unaffected by scrollbar layout in test/integration/scrollbar_coordinate_independence_test.dart
- [ ] T170 Run all contract tests and verify 100% pass rate
- [ ] T171 Run all golden tests and verify 100% visual match
- [ ] T172 Run quickstart.md validation scenarios
- [ ] T173 Update CHANGELOG.md with scrollbar feature details

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion - **BLOCKS all user stories**
- **User Stories (Phase 3-7)**: All depend on Foundational phase completion
  - US1 (Visual Feedback): Can start after Foundational ✅
  - US2 (Pan): Depends on US1 (needs rendering) ❌
  - US3 (Zoom): Depends on US2 (shares gesture handling) ❌
  - US4 (Keyboard): Independent of US2/US3 (separate input method) ✅
  - US5 (Theming): Independent of US2/US3/US4 (visual only) ✅
- **Accessibility (Phase 8)**: Depends on US4 (keyboard navigation)
- **Polish (Phase 9)**: Depends on all desired user stories being complete

### User Story Dependencies

**Parallel Opportunities** (can start together after Foundational):
- **US1 (Visual Feedback)**: No dependencies after Foundational ✅
- **US4 (Keyboard)**: No dependencies after Foundational ✅
- **US5 (Theming)**: No dependencies after Foundational ✅

**Sequential Requirements**:
- **US2 (Pan)**: MUST complete US1 first (needs widget rendering)
- **US3 (Zoom)**: MUST complete US2 first (shares gesture detection logic)

**Dependency Graph**:
```
Phase 2 (Foundational)
    ├─→ US1 (Visual) ─→ US2 (Pan) ─→ US3 (Zoom)
    ├─→ US4 (Keyboard) ──────────────┘
    └─→ US5 (Theming) ───────────────┘
            ↓
     Phase 8 (Accessibility)
            ↓
      Phase 9 (Polish)
```

### Within Each User Story

- Contract tests MUST be written and FAIL before implementation
- Foundational entities/controllers before widget usage
- Widget structure before gesture handling
- Gesture handling before integration with BravenChart
- Integration tests after implementation complete

### Parallel Opportunities

**Phase 2 Foundational** (all marked [P] can run in parallel):
```bash
# Core data structures (independent files):
T005: HitTestZone enum
T006: ScrollbarState class
T007: ScrollbarConfig class

# Controller methods (independent methods in same file, but parallelizable):
T009: calculateHandleSize()
T010: calculateHandlePosition()
T012: dataRangeToHandle()
T013: getHitTestZone()
T014: getCursorForZone()

# Predefined themes (independent):
T026: defaultLight theme
T027: defaultDark theme
T028: highContrast theme

# Contract tests (independent test files):
T033-T038: All foundational contract tests
```

**User Story 1** (tests in parallel):
```bash
T039: ChartScrollbar render test
T040: Handle size accuracy test
T041: Handle position accuracy test
T042: Horizontal golden test
T043: Vertical golden test
```

**User Story 2** (tests in parallel):
```bash
T059: Pan start test
T060: Pan update test
T061: Pan end test
T062: Throttle test
```

**User Story 3** (tests in parallel):
```bash
T079: Edge detection test
T080: Left edge resize test
T081: Right edge resize test
T082: Min handle size test
T083: Edge cursor golden test
```

**User Story 4** (all keyboard tests in parallel):
```bash
T100-T105: All keyboard navigation contract tests
```

**User Story 5** (all theme tests in parallel):
```bash
T124-T130: All theme contract and golden tests
```

**Phase 9 Polish** (documentation in parallel):
```bash
T154: ChartScrollbar dartdoc
T155: ScrollbarController dartdoc
T156: ScrollbarConfig dartdoc
T157: ScrollbarTheme dartdoc
```

---

## Parallel Example: Foundational Phase

```bash
# Launch all foundational data structures together:
Task: "Create HitTestZone enum in lib/src/widgets/scrollbar/hit_test_zone.dart"
Task: "Create ScrollbarState immutable data class in lib/src/widgets/scrollbar/scrollbar_state.dart"
Task: "Create ScrollbarConfig data class in lib/src/theming/components/scrollbar_config.dart"

# Launch all controller methods together (separate files for parallelism):
Task: "Implement ScrollbarController.calculateHandleSize()"
Task: "Implement ScrollbarController.calculateHandlePosition()"
Task: "Implement ScrollbarController.getHitTestZone()"
Task: "Implement ScrollbarController.getCursorForZone()"
```

---

## Implementation Strategy

### MVP First (User Story 1 + 2 Only)

**Minimum Viable Product** for production deployment:

1. Complete Phase 1: Setup ✅
2. Complete Phase 2: Foundational (CRITICAL - blocks all stories) ✅
3. Complete Phase 3: User Story 1 (Visual Feedback) ✅
4. Complete Phase 4: User Story 2 (Pan) ✅
5. **STOP and VALIDATE**: Test US1+US2 independently
6. Deploy/demo scrollbar with visual feedback + pan (covers 80% of use cases)

**Why This MVP**:
- Visual feedback (US1) answers "where am I in my data?" (core value)
- Pan capability (US2) enables navigation (core interaction)
- Combined: Delivers production-ready scrollbar for most use cases
- Defer: Zoom (US3), keyboard (US4), theming (US5) to later iterations

### Incremental Delivery

**Each phase adds standalone value**:

1. **Foundation** (Phase 2) → Scrollbar infrastructure ready
2. **+ US1** (Phase 3) → Scrollbar displays with accurate position ✅ **DEMO**
3. **+ US2** (Phase 4) → Scrollbar enables pan navigation ✅ **MVP RELEASE**
4. **+ US3** (Phase 5) → Scrollbar enables zoom control ✅ **RELEASE**
5. **+ US4** (Phase 6) → Scrollbar keyboard-accessible ✅ **ACCESSIBILITY COMPLIANT**
6. **+ US5** (Phase 7) → Scrollbar fully themed ✅ **POLISH COMPLETE**

**Each increment independently testable and deployable**

### Parallel Team Strategy

With 3 developers after Foundational phase completes:

- **Developer A**: US1 (Visual) → US2 (Pan) → US3 (Zoom) [Core interactions, sequential]
- **Developer B**: US4 (Keyboard) → Phase 8 (Accessibility) [Accessibility track, parallel]
- **Developer C**: US5 (Theming) → Phase 9 (Polish/Docs) [Visual polish track, parallel]

**Timeline**: All tracks merge after ~2 weeks for integration testing

---

## Testing Strategy

### Test-First Development (TDD)

**CRITICAL**: Write contract tests BEFORE implementation per Constitution I

**TDD Workflow**:
1. Write contract test for feature (e.g., T033: calculateHandleSize test)
2. Run test → verify it FAILS (red)
3. Implement feature (e.g., T009: calculateHandleSize method)
4. Run test → verify it PASSES (green)
5. Refactor if needed, keep test passing

**Test Categories**:

| Type | Purpose | Example | Phase |
|------|---------|---------|-------|
| **Contract Tests** | Verify API contracts (inputs → outputs) | ScrollbarController.calculateHandleSize() with edge cases | Foundational, All User Stories |
| **Unit Tests** | Verify isolated component behavior | ScrollbarState.copyWith() immutability | Foundational |
| **Widget Tests** | Verify widget rendering and gestures | ChartScrollbar renders handle correctly | US1, US2, US3 |
| **Golden Tests** | Verify visual appearance (regression prevention) | Scrollbar appearance in defaultLight theme | US1, US5 |
| **Integration Tests** | Verify user story end-to-end flows | Drag scrollbar → chart viewport updates | All User Stories |
| **Performance Tests** | Verify <0.1ms calculations, 60 FPS, <100KB memory | Benchmark calculations, frame time, memory profiler | US2 (drag), Phase 9 |
| **Accessibility Tests** | Verify WCAG 2.1 AA compliance | Screen reader announcements, contrast ratios | US4, US5, Phase 8 |

**Test Coverage Target**: 100% for core scrollbar logic (ScrollbarController, ChartScrollbar gestures)

---

## Performance Targets

**From Constitution II (Performance First) and SC-003 through SC-013**:

| Metric | Target | Validation | Task |
|--------|--------|------------|------|
| Handle calculation | <0.1ms | Benchmark with 1M iterations | T165 |
| Scrollbar render | <1ms | CustomPainter profiling | T166 |
| Viewport update | <16ms | Full chart re-render with 10K points | T166 |
| Frame time during drag | <16.67ms (60 FPS) | Flutter DevTools performance overlay | T166 |
| Memory overhead | <100KB | Both X+Y scrollbars, DevTools memory profiler | T167 |
| Jank rate | 0% | 1000-frame drag session, no dropped frames | T168 |

**Performance Validation**: All targets verified in Phase 9 before declaring feature complete

---

## Accessibility Requirements

**WCAG 2.1 AA Compliance** (Constitutional requirement per Architectural Integrity):

| Guideline | Requirement | Implementation | Tasks |
|-----------|-------------|----------------|-------|
| **2.1.1 Keyboard** | All functionality via keyboard | Arrow keys (pan), Ctrl+arrow (zoom), Tab (focus) | T106-T118 (US4) |
| **1.4.3 Contrast (Minimum)** | 4.5:1 for text/critical UI | Handle vs track: 4.5:1+ in all themes | T131-T133 (US5) |
| **1.4.11 Non-text Contrast** | 3:1 for UI components | Track vs background: 3:1+, hover/active: 3:1+ | T131-T133 (US5) |
| **4.1.3 Status Messages** | Screen reader announcements | Semantics widget with value updates | T147-T152 (Phase 8) |
| **2.4.7 Focus Visible** | Visible focus indicator | 2px solid focus ring, high contrast | T119 (US4) |

**Validation**: Phase 8 accessibility tests verify all guidelines (T145, T146, T153)

---

## Notes

- **[P] tasks** = Different files, no dependencies, can run in parallel
- **[Story] label** = Maps task to specific user story for traceability
- **Constitutional Compliance**:
  - ✅ Test-First Development: Contract tests before implementation (all phases)
  - ✅ Performance First: ValueNotifier pattern for >10Hz updates (T020, T064-T066)
  - ✅ Architectural Integrity: Coordinate system independence (T052, T169)
  - ✅ API Consistency: Follow Flutter patterns (T106-T110 FocusNode, T111-T118 KeyboardListener)
  - ✅ Documentation Discipline: dartdoc comments for all public APIs (T154-T157)
- **Total Tasks**: 173 tasks across 9 phases
- **Parallel Opportunities**: 
  - Phase 2 Foundational: 15+ parallel tasks
  - Each user story tests: 5-7 parallel tasks
  - Phase 9 Documentation: 4 parallel tasks
- **MVP Scope**: Phase 1 + Phase 2 + US1 + US2 = 76 tasks (~40% of total)
- **Full Feature**: All 173 tasks for complete dual-purpose scrollbars with accessibility

---

## Task Summary

**Total Task Count**: 173 tasks

**Tasks by User Story**:
- Phase 1 (Setup): 4 tasks
- Phase 2 (Foundational): 28 tasks ⚠️ **BLOCKS ALL STORIES**
- US1 (Visual Feedback): 18 tasks (MVP increment 1)
- US2 (Pan): 16 tasks (MVP increment 2)
- US3 (Zoom): 21 tasks
- US4 (Keyboard): 24 tasks
- US5 (Theming): 23 tasks
- Phase 8 (Accessibility): 7 tasks
- Phase 9 (Polish): 32 tasks

**Parallel Opportunities Identified**: 60+ tasks can run in parallel (marked with [P])

**Independent Test Criteria**:
- ✅ US1: Zoom in → scrollbar appears with handle size = viewport ratio
- ✅ US2: Drag handle → chart viewport pans, zoom level constant
- ✅ US3: Drag edge → chart zooms with opposite edge anchored
- ✅ US4: Tab + arrows → navigate without mouse
- ✅ US5: Apply theme → scrollbar colors match

**Suggested MVP Scope**: Phase 1 + Phase 2 + US1 + US2 = 76 tasks (delivers scrollbar with visual feedback + pan navigation)

---

## Format Validation

✅ All 173 tasks follow the checklist format:
- Checkbox: `- [ ]`
- Task ID: Sequential T001-T173
- [P] marker: 60+ parallelizable tasks marked
- [Story] label: US1, US2, US3, US4, US5 labels applied correctly
- Description: Clear action + exact file path
- Setup/Foundational/Polish phases: No story labels ✅
- User Story phases: All have story labels ✅
