# Phase 0 Comprehensive Test Plan

**Status**: 🟡 IN PROGRESS - 60% Complete  
**Created**: 2025-01-XX  
**Last Updated**: 2025-01-XX

---

## Purpose

This document provides a complete test coverage plan for Phase 0 prototype validation, mapping all 15 conflict scenarios from `conflict_resolution_table.md` to specific test requirements and acceptance criteria.

**CRITICAL**: Phase 0 is NOT complete until ALL scenarios are validated with comprehensive test coverage.

---

## Current Test Coverage Summary

### ✅ Completed (6 of 15 scenarios - 40%)

| Scenario | Description             | Test Coverage                                             | Status      |
| -------- | ----------------------- | --------------------------------------------------------- | ----------- |
| **#6**   | Pan vs Series Click     | Middle-click pan tested in `conflict_scenarios_test.dart` | ✅ COMPLETE |
| **#7**   | Crosshair Active        | Passive behavior validated in coordinator tests           | ✅ COMPLETE |
| **#9**   | Ctrl+Click Multi-Select | Toggle selection tested in `coordinator_test.dart`        | ✅ COMPLETE |
| **#12**  | Pan + Hover             | Hover suspension during pan tested                        | ✅ COMPLETE |

### ⚠️ Partial Coverage (3 of 15 scenarios - 20%)

| Scenario | Description                  | Current Tests             | Missing Tests                                        | Status     |
| -------- | ---------------------------- | ------------------------- | ---------------------------------------------------- | ---------- |
| **#2**   | Datapoint vs Series Line     | Basic datapoint selection | Series line click, priority resolution               | ⚠️ PARTIAL |
| **#4**   | Overlapping Datapoints       | Nearest point selection   | 3px epsilon ambiguity, picker UI                     | ⚠️ PARTIAL |
| **#5**   | Box Select vs Datapoint Drag | Basic drag detection      | 5px threshold, box select mode, annotation exclusion | ⚠️ PARTIAL |

### ❌ Not Tested (6 of 15 scenarios - 40%)

| Scenario | Description                   | Priority    | User-Reported          | Status        |
| -------- | ----------------------------- | ----------- | ---------------------- | ------------- |
| **#1**   | Resize Handle vs Datapoint    | P9 vs P6    | YES - "drag to resize" | ❌ NOT TESTED |
| **#3**   | Annotation Body vs Datapoint  | P7 vs P6    | NO                     | ❌ NOT TESTED |
| **#8**   | Context Menu Open             | P10 (modal) | YES - "right click"    | ❌ NOT TESTED |
| **#10**  | Resize Drag Leaves Bounds     | P9          | YES - part of resize   | ❌ NOT TESTED |
| **#11**  | Edit Mode Active              | P9          | NO                     | ❌ NOT TESTED |
| **#13**  | Datapoint Drag vs Series Drag | P7 vs P5    | NO                     | ❌ NOT TESTED |
| **#14**  | Box Select Over Annotations   | P5          | NO                     | ❌ NOT TESTED |
| **#15**  | Long Press vs Drag            | Various     | NO                     | ❌ NOT TESTED |

---

## Test File Organization

### Existing Test Files (Phase 0.5 - 0.8)

```
refactor/interaction/test/
├── unit/
│   ├── quadtree_test.dart          ✅ 17 tests - COMPLETE
│   └── coordinator_test.dart       ⚠️ 41 tests - MISSING resize/context menu modes
├── widget/
│   └── conflict_scenarios_test.dart ⚠️ 10 tests - ONLY pan/select basics
└── integration/
    └── complete_workflows_test.dart ⚠️ 13 tests - NO resize/context menu workflows
└── performance/
    └── benchmark_test.dart         ✅ 10 tests - COMPLETE
```

**Current Total**: 91 tests (60% scenario coverage)

### Required New Test Files (Phase 0.9 - 0.11)

```
refactor/interaction/test/
├── widget/
│   ├── resize_scenarios_test.dart      🆕 8-10 tests (Scenarios #1, #10)
│   ├── context_menu_test.dart          🆕 5-7 tests (Scenario #8)
│   ├── hover_edge_cases_test.dart      🆕 6-8 tests (Scenarios #4, #7, #12 edge cases)
│   ├── annotation_conflicts_test.dart  🆕 4-6 tests (Scenarios #3, #11)
│   └── box_select_test.dart            🆕 3-5 tests (Scenarios #5, #14)
├── integration/
│   ├── resize_workflows_test.dart      🆕 6-8 tests (Complete resize flows)
│   ├── context_menu_workflows_test.dart 🆕 4-6 tests (Complete menu flows)
│   └── modifier_keys_test.dart         🆕 4-6 tests (Shift, Alt combinations)
└── visual/
    └── golden_tests.dart               🆕 5-10 tests (Screenshot validation)
```

**Target Total**: 130-150 tests (100% scenario coverage)

---

## Detailed Test Requirements by Scenario

### Scenario #1: Resize Handle vs Datapoint (CRITICAL - User Reported)

**Design Requirements**:

- **Priority**: Resize handle = 9, Datapoint = 6
- **Winner**: Resize handle (always)
- **Handle Size**: 8×8px visual, 10px hit radius
- **Handle Count**: 8 (4 corners + 4 midpoints: topLeft, topRight, bottomLeft, bottomRight, top, right, bottom, left)
- **Behavior**: Handle claims click/drag, datapoint ignored when pointer in handle region

**Existing Implementation** (✅ FOUND):

- `SimulatedAnnotation.getResizeHandles()` - returns 8 handle positions
- `ResizableElement` mixin - interface for resizable elements
- `InteractionMode.resizingAnnotation` - priority 9 mode
- `ResizeDirection` enum - 8 direction types
- Handle rendering when annotation selected (lines 182-193 of simulated_annotation.dart)

**Test Requirements** (❌ ZERO TESTS):

#### Unit Tests (`coordinator_test.dart` additions):

1. **Resize Mode Priority**:
   - [ ] `claimMode(resizingAnnotation)` succeeds when idle (priority 9 > 0)
   - [ ] `claimMode(resizingAnnotation)` blocks panning (priority 9 > 3)
   - [ ] `claimMode(resizingAnnotation)` blocks datapoint selection (priority 9 > 6)
   - [ ] `claimMode(panning)` fails when resizing active (priority 3 < 9)

#### Widget Tests (`resize_scenarios_test.dart` - NEW FILE):

2. **Handle Hit Testing**:
   - [ ] Click on corner handle (topLeft) triggers `onResizeStart` with correct direction
   - [ ] Click on midpoint handle (top) triggers `onResizeStart` with correct direction
   - [ ] Click on all 8 handles validates each direction (bottomRight, left, etc.)
   - [ ] Click outside 10px handle radius does NOT trigger resize

3. **Handle vs Datapoint Priority**:
   - [ ] Click on handle overlapping datapoint selects HANDLE (priority 9 > 6)
   - [ ] Drag from handle with datapoint underneath triggers resize, NOT datapoint drag
   - [ ] Click on datapoint outside handle region selects DATAPOINT normally

4. **Resize Drag Behavior**:
   - [ ] Drag topLeft handle shrinks/grows annotation from top-left corner
   - [ ] Drag bottomRight handle shrinks/grows annotation from bottom-right corner
   - [ ] Drag top midpoint handle changes height only (width unchanged)
   - [ ] Drag right midpoint handle changes width only (height unchanged)

5. **Resize Mode State**:
   - [ ] Resize mode persists during drag (mode = `resizingAnnotation`)
   - [ ] Hover events suspended during resize (hover priority 0 < 9)
   - [ ] Pan gestures blocked during resize (pan priority 3 < 9)
   - [ ] Pointer up releases resize mode, returns to idle

#### Integration Tests (`resize_workflows_test.dart` - NEW FILE):

6. **Complete Resize Workflows**:
   - [ ] Select annotation → hover over handle (cursor change) → drag handle → release → annotation resized
   - [ ] Resize annotation → release → deselect → handles disappear
   - [ ] Resize annotation → Ctrl+click elsewhere → both selected, resize ends
   - [ ] Resize multiple annotations sequentially (state cleanup between resizes)

**Acceptance Criteria**:

- ✅ All 8 resize handles functional and tested
- ✅ Priority 9 properly blocks lower priority interactions
- ✅ Resize mode transitions clean (no lingering state)
- ✅ Performance: Resize handle hit test <1ms (already validated in QuadTree)
- ✅ User can resize annotations by dragging any of the 8 handles
- ✅ Datapoints under handles do NOT interfere with resize

**Estimated Tests**: 8-10 tests (4 unit + 4-5 widget + 2-3 integration)

---

### Scenario #10: Resize Drag Leaves Bounds (CRITICAL - Related to #1)

**Design Requirements**:

- **Priority**: Resize operation in progress = 9
- **Winner**: Continue resize (track mouse outside bounds)
- **Behavior**: If mouse leaves chart during resize, continue tracking; apply resize on mouse up regardless of position
- **Cancel Condition**: ESC key cancels resize, restores original bounds

**Test Requirements** (❌ ZERO TESTS):

#### Widget Tests (`resize_scenarios_test.dart`):

1. **Mouse Outside Bounds**:
   - [ ] Drag resize handle outside chart area → resize continues
   - [ ] Drag handle far outside (1000px away) → resize still tracks correctly
   - [ ] Mouse leaves screen during resize → resize continues (system-dependent)

2. **Release Outside Bounds**:
   - [ ] Release mouse button outside chart → resize applied successfully
   - [ ] Release mouse button far outside → final bounds calculated correctly

3. **Cancel Operations**:
   - [ ] ESC key during resize → cancels resize, restores original bounds
   - [ ] ESC key after mouse leaves bounds → cancel still works

**Acceptance Criteria**:

- ✅ Resize tracks mouse position even when outside chart bounds
- ✅ Resize applies correctly when released outside bounds
- ✅ ESC key provides reliable cancel mechanism
- ✅ No crashes or undefined behavior when pointer leaves bounds

**Estimated Tests**: 2-3 tests (integrated with Scenario #1 tests)

---

### Scenario #8: Context Menu Open (CRITICAL - User Reported)

**Design Requirements**:

- **Priority**: Context menu = 10 (MODAL - highest priority)
- **Behavior**: Right-click opens context menu (modal state blocks ALL other interactions)
- **Menu Types**:
  - Right-click empty chart → "Add Annotation / Chart Actions" menu
  - Right-click annotation → "Edit / Delete / Properties" menu
- **Close Triggers**: Click outside, select item, ESC key

**Existing Implementation** (✅ FOUND):

- `InteractionMode.contextMenuOpen` - priority 10 modal mode
- `kSecondaryMouseButton` handling in RenderBox (lines 194-196)
- `ContextMenuElement` mixin - interface for menu-enabled elements

**Test Requirements** (❌ ZERO TESTS):

#### Unit Tests (`coordinator_test.dart` - ALREADY HAS SOME):

1. **Modal Priority** (✅ ALREADY TESTED - lines 116-131):
   - [x] `claimMode(contextMenuOpen)` sets `isModal = true`
   - [x] All other `claimMode()` calls fail when context menu open
   - [x] Panning blocked (priority 3 < 10)
   - [x] Dragging blocked (priority 7 < 10)
   - [x] Resizing blocked (priority 9 < 10)

#### Widget Tests (`context_menu_test.dart` - NEW FILE):

2. **Right-Click Detection**:
   - [ ] Right-click on empty chart area triggers `onContextMenu(null)`
   - [ ] Right-click on annotation triggers `onContextMenu(annotation)`
   - [ ] Right-click on datapoint triggers `onContextMenu(datapoint)`
   - [ ] Left-click does NOT trigger context menu
   - [ ] Middle-click does NOT trigger context menu

3. **Menu Blocking Behavior**:
   - [ ] While menu open, left-click on datapoint does NOT select
   - [ ] While menu open, middle-click does NOT pan
   - [ ] While menu open, hover does NOT show tooltips
   - [ ] While menu open, Ctrl+click does NOT multi-select

4. **Menu Close Triggers**:
   - [ ] Click outside menu → menu closes, returns to idle mode
   - [ ] Select menu item → callback invoked, menu closes
   - [ ] ESC key → menu closes without action
   - [ ] Right-click elsewhere → closes first menu, opens new menu

#### Integration Tests (`context_menu_workflows_test.dart` - NEW FILE):

5. **Complete Menu Workflows**:
   - [ ] Right-click empty → "Add Annotation" menu → select item → add flow begins
   - [ ] Right-click annotation → "Edit/Delete" menu → select Edit → edit mode starts
   - [ ] Right-click annotation → Delete → confirmation → annotation removed
   - [ ] Open menu → click outside → menu closes, chart still interactive

**Acceptance Criteria**:

- ✅ Right-click reliably opens context menu (not left or middle)
- ✅ Context menu is truly modal (blocks ALL chart interactions)
- ✅ Menu closes on all expected triggers (click outside, ESC, item select)
- ✅ Different menu types for empty area vs elements
- ✅ Performance: Menu open/close <10ms

**Estimated Tests**: 5-7 tests (2 unit already exist + 3-4 widget + 1-2 integration)

---

### Scenario #4: Overlapping Datapoints (PARTIAL - User Reported Hover Bugs)

**Design Requirements**:

- **Priority**: Datapoint = 6
- **Winner**: Nearest datapoint by Euclidean distance
- **Ambiguity Threshold**: If multiple points within 3px of same distance, show picker UI
- **Multi-Select**: Ctrl+click toggles nearest point

**Existing Implementation** (✅ TESTED PARTIALLY):

- Nearest point selection tested in `conflict_scenarios_test.dart` (lines 220-239)
- Ctrl+click toggle tested in `coordinator_test.dart`

**Test Requirements** (⚠️ PARTIAL - Missing Edge Cases):

#### Widget Tests (`hover_edge_cases_test.dart` - NEW FILE):

1. **Hover with Overlapping Elements** (❌ NOT TESTED):
   - [ ] Hover over 2 datapoints within 3px → hover nearest (deterministic)
   - [ ] Hover over 3+ datapoints within 3px → hover nearest (or show picker)
   - [ ] Hover moves from point A to point B (2px apart) → hover switches correctly
   - [ ] Hover on annotation over datapoint → correct element hovered based on priority

2. **Hover Suspended During Interactions** (⚠️ BASIC TEST EXISTS):
   - [x] Hover suspended during pan (scenario #12 tested)
   - [ ] Hover suspended during datapoint drag
   - [ ] Hover suspended during resize
   - [ ] Hover suspended during box select
   - [ ] Hover resumes after interaction ends

3. **Hover Detection Inconsistency Bug** (❌ NOT TESTED - USER REPORTED):
   - [ ] Hover over elements <5px apart → consistent hover without flickering
   - [ ] Rapid mouse movement over dense datapoints → hover updates correctly
   - [ ] Hover near chart edges → no false positives from out-of-bounds elements
   - [ ] Hover during scroll/zoom → hover coordinates update correctly

**Acceptance Criteria**:

- ✅ Hover detection deterministic (same position always hovers same element)
- ✅ No hover flickering when elements are close (<5px)
- ✅ Hover correctly suspended during all priority 3+ interactions
- ✅ 3px ambiguity threshold enforced (picker UI or nearest selection)
- ✅ USER BUG FIXED: "inconsistent hover detection where elements are close to each other"

**Estimated Tests**: 6-8 tests (expanding existing hover tests + bug fixes)

---

### Scenario #2: Datapoint vs Series Line

**Design Requirements**:

- **Priority**: Datapoint = 6, Series = 4
- **Winner**: Datapoint (if pointer within marker radius), otherwise Series
- **Behavior**: Datapoint hit radius wins; clicks outside radius hit series line

**Test Requirements** (⚠️ BASIC TESTS - Missing Priority Resolution):

#### Widget Tests (`annotation_conflicts_test.dart` or expand `conflict_scenarios_test.dart`):

1. **Hit Detection**:
   - [ ] Click on datapoint marker (within 10px radius) → datapoint selected (priority 6)
   - [ ] Click on series line between datapoints → series selected (priority 4)
   - [ ] Click 11px away from datapoint on series line → series wins
   - [ ] Click 9px away from datapoint on series line → datapoint wins

2. **Multi-Element Priority**:
   - [ ] Click on datapoint with series line underneath → datapoint wins
   - [ ] Hover over datapoint marker → datapoint hover, NOT series hover
   - [ ] Hover over series line (not on marker) → series hover only

**Acceptance Criteria**:

- ✅ Datapoint radius (10px) correctly determines hit priority
- ✅ Series line accessible when not overlapping datapoint
- ✅ Priority 6 > 4 enforced in QuadTree nearest queries

**Estimated Tests**: 3-4 tests

---

### Scenario #3: Annotation Body vs Datapoint

**Design Requirements**:

- **Priority**: Annotation (trend/selectable) = 7, Datapoint = 6
- **Winner**: Annotation for Trend annotations; otherwise Datapoint
- **Behavior**: Trend annotations claim clicks in body region; passive annotations allow datapoint selection underneath

**Test Requirements** (❌ NOT TESTED):

#### Widget Tests (`annotation_conflicts_test.dart` - NEW FILE):

1. **Trend Annotation Priority**:
   - [ ] Click on Trend annotation body over datapoint → annotation selected (priority 7 > 6)
   - [ ] Click on Trend annotation with no datapoint underneath → annotation selected
   - [ ] Drag Trend annotation over datapoints → annotation moves, datapoints ignored

2. **Passive Annotation Behavior**:
   - [ ] Click on Text annotation over datapoint → datapoint selected (annotation passive)
   - [ ] Click on Range annotation body over datapoint → datapoint selected (body passive)
   - [ ] Click on Range annotation resize handle over datapoint → handle wins (priority 9 > 6)

**Acceptance Criteria**:

- ✅ Trend annotations selectable and block datapoint clicks
- ✅ Passive annotations (Text, Range body) do NOT block datapoint selection
- ✅ Priority hierarchy: Resize handle (9) > Trend annotation (7) > Datapoint (6) > Series (4)

**Estimated Tests**: 4-6 tests

---

### Scenario #5: Box Selection vs Datapoint Drag

**Design Requirements**:

- **Priority**: Datapoint drag = 6, Box select = 5
- **Winner**: Datapoint drag (if started within 10px radius); otherwise Box select
- **Threshold**: Drag >5px from initial pointer down triggers box select
- **Behavior**: Box select only selects datapoints, NOT annotations

**Test Requirements** (⚠️ BASIC DRAG TESTS - Missing Box Select):

#### Widget Tests (`box_select_test.dart` - NEW FILE):

1. **Drag Threshold Detection**:
   - [ ] Click empty area, drag 6px → box select starts (threshold = 5px)
   - [ ] Click empty area, drag 4px → no box select (below threshold)
   - [ ] Click on datapoint, drag 10px → datapoint drag (within radius, priority 6 > 5)
   - [ ] Click 11px from datapoint, drag → box select (outside radius)

2. **Box Select Behavior**:
   - [ ] Drag box over 5 datapoints → all 5 selected
   - [ ] Drag box over datapoints + annotations → only datapoints selected (annotations ignored)
   - [ ] Drag box over empty area → no selections
   - [ ] Release box select → selected datapoints remain selected

3. **Multi-Select Integration**:
   - [ ] Box select with Ctrl → adds to existing selection
   - [ ] Box select without Ctrl → replaces selection
   - [ ] Box select + Ctrl+click → both mechanisms work together

**Acceptance Criteria**:

- ✅ 5px drag threshold enforced (no accidental box select on small movements)
- ✅ Datapoint drag wins when started within 10px radius
- ✅ Box select only captures datapoints (annotations excluded)
- ✅ Box select respects Ctrl modifier for additive selection

**Estimated Tests**: 3-5 tests

---

### Scenario #11: Edit Mode Active

**Design Requirements**:

- **Priority**: Edit mode = 9
- **Winner**: Edit mode blocks most interactions
- **Behavior**: Double-click annotation enters edit mode; click outside commits changes and exits

**Test Requirements** (❌ NOT TESTED):

#### Unit Tests (`coordinator_test.dart` additions):

1. **Edit Mode Priority**:
   - [ ] `claimMode(editingAnnotation)` sets `isModal = true` (priority 9)
   - [ ] Pan blocked during edit (priority 3 < 9)
   - [ ] Hover blocked during edit (priority 0 < 9)
   - [ ] Other element selection blocked during edit (priority 6 < 9)

#### Widget Tests (`annotation_conflicts_test.dart`):

2. **Edit Mode Entry/Exit**:
   - [ ] Double-click annotation → edit mode activated
   - [ ] Click outside annotation during edit → changes committed, edit mode exited
   - [ ] Click on another element during edit → first annotation committed, second element selected
   - [ ] ESC key during edit → changes discarded, edit mode exited

**Acceptance Criteria**:

- ✅ Double-click reliably enters edit mode (not single-click)
- ✅ Edit mode blocks lower priority interactions
- ✅ Click outside commits and allows new interaction
- ✅ ESC provides discard option

**Estimated Tests**: 2-3 tests

---

### Scenario #13: Datapoint Drag vs Series Drag

**Design Requirements**:

- **Priority**: Datapoint drag = 7, Series drag = 5
- **Winner**: Datapoint drag (click on point); Series drag requires Alt modifier
- **Behavior**: Click datapoint = drag point; Alt+drag series = move series

**Test Requirements** (❌ NOT TESTED):

#### Widget Tests (expand `conflict_scenarios_test.dart` or create `series_drag_test.dart`):

1. **Drag Type Detection**:
   - [ ] Click datapoint, drag → datapoint moves (priority 7)
   - [ ] Click series line (not on point), drag → nothing happens (no series drag without modifier)
   - [ ] Alt+click series line, drag → series moves (priority 5 with modifier)
   - [ ] Alt+click datapoint, drag → datapoint moves (point takes priority over series)

**Acceptance Criteria**:

- ✅ Datapoint drag works without modifier (priority 7)
- ✅ Series drag requires Alt modifier (priority 5)
- ✅ Datapoint always wins over series when both present

**Estimated Tests**: 2-3 tests

---

### Scenario #14: Box Select Over Annotations

**Design Requirements**:

- **Priority**: Box select = 5
- **Behavior**: Box select only selects datapoints, ignores annotations entirely
- **Selection Criteria**: Element center inside box OR boundary intersects box (configurable)

**Test Requirements** (❌ NOT TESTED):

#### Widget Tests (`box_select_test.dart`):

1. **Annotation Exclusion**:
   - [ ] Drag box over 3 datapoints + 2 annotations → only 3 datapoints selected
   - [ ] Drag box over only annotations → no selections
   - [ ] Drag box over mixed elements → only datapoints selected (annotations untouched)

**Acceptance Criteria**:

- ✅ Box select never selects annotations (only datapoints)
- ✅ Annotations remain unaffected by box selection

**Estimated Tests**: 1-2 tests (combine with Scenario #5 tests)

---

### Scenario #15: Long Press vs Drag

**Design Requirements**:

- **Threshold**: Move >5px within 200ms = Drag; Hold still >500ms = Long press
- **Behavior**: Long press shows context menu (touch devices); Mouse uses right-click

**Test Requirements** (❌ NOT TESTED - Lower Priority):

#### Widget Tests (optional - low priority for mouse-focused prototype):

1. **Gesture Disambiguation**:
   - [ ] Hold still 600ms → long press detected (context menu)
   - [ ] Move 6px within 100ms → drag wins (long press canceled)
   - [ ] Hold 300ms then move → drag wins (long press canceled)

**Acceptance Criteria**:

- ✅ Long press and drag do not conflict
- ✅ Touch: long press = context menu; Mouse: right-click = context menu

**Estimated Tests**: 1-2 tests (OPTIONAL - defer to Phase 1 touch support)

---

## Test Execution Plan

### Phase 0.9: Resize Tests (HIGH PRIORITY - User Request)

**Target**: Scenarios #1 + #10 complete  
**Files**: `resize_scenarios_test.dart`, `resize_workflows_test.dart`, coordinator updates  
**Tests**: 8-10 new tests  
**Timeline**: 1-2 sessions

**Milestones**:

1. Add 4 unit tests to `coordinator_test.dart` for resize mode priority
2. Create `resize_scenarios_test.dart` with 4-5 widget tests
3. Create `resize_workflows_test.dart` with 2-3 integration tests
4. Run full test suite → target 99-101 passing tests
5. Validate: All 8 resize handles functional, priority 9 enforced

---

### Phase 0.10: Context Menu + Hover Tests (HIGH PRIORITY - User Requests)

**Target**: Scenarios #8 + #4 edge cases complete  
**Files**: `context_menu_test.dart`, `context_menu_workflows_test.dart`, `hover_edge_cases_test.dart`  
**Tests**: 11-15 new tests  
**Timeline**: 2-3 sessions

**Milestones**:

1. Create `context_menu_test.dart` with 3-4 widget tests (right-click detection, modal blocking)
2. Create `context_menu_workflows_test.dart` with 1-2 integration tests
3. Create `hover_edge_cases_test.dart` with 6-8 tests (overlapping elements, suspension, **BUG FIX**)
4. Fix user-reported hover inconsistency bug
5. Run full test suite → target 112-119 passing tests
6. Validate: Context menu modal, hover deterministic

---

### Phase 0.11: Remaining Scenarios (MEDIUM PRIORITY)

**Target**: Scenarios #2, #3, #5, #11, #13, #14 complete  
**Files**: `annotation_conflicts_test.dart`, `box_select_test.dart`, updates to existing files  
**Tests**: 12-18 new tests  
**Timeline**: 2-3 sessions

**Milestones**:

1. Create `annotation_conflicts_test.dart` with 6-9 tests (scenarios #2, #3, #11)
2. Create `box_select_test.dart` with 4-7 tests (scenarios #5, #14)
3. Add tests for scenario #13 (datapoint vs series drag)
4. Run full test suite → target 130-140 passing tests
5. Validate: All 15 conflict scenarios tested

---

### Phase 0.12: Visual Regression + Modifier Keys (OPTIONAL)

**Target**: Visual validation + Shift/Alt modifiers  
**Files**: `golden_tests.dart`, `modifier_keys_test.dart`  
**Tests**: 9-16 new tests  
**Timeline**: 1-2 sessions (OPTIONAL)

**Milestones**:

1. Create `golden_tests.dart` with 5-10 screenshot tests
2. Create `modifier_keys_test.dart` with 4-6 tests (Shift, Alt combinations)
3. Run full test suite → target 145-160 passing tests
4. Validate: Visual consistency, modifier behavior

---

### Phase 0.13: Final Validation (MANDATORY)

**Target**: 100% scenario coverage, all user bugs fixed, production readiness  
**Files**: All test files  
**Tests**: 130-160 total (depends on optional tests)  
**Timeline**: 1 session

**Checklist**:

- [ ] All 15 conflict scenarios validated with tests
- [ ] User-reported bugs fixed:
  - [ ] "drag to resize" - ✅ Tested in Phase 0.9
  - [ ] "right click" - ✅ Tested in Phase 0.10
  - [ ] "inconsistent hover detection" - ✅ Fixed and tested in Phase 0.10
- [ ] Performance targets met (already validated in Phase 0.8)
- [ ] All tests passing (130-160 tests)
- [ ] Documentation updated (phase_0_summary.md corrected)
- [ ] Code coverage >90% for interaction system

**THEN**: Phase 0 is **TRULY COMPLETE** ✅

---

## Performance Targets (Already Validated in Phase 0.8)

All performance benchmarks from Phase 0.8 remain valid:

- ✅ QuadTree insert: 6ms (16x faster than 100ms target)
- ✅ QuadTree query: 0.006ms (8x faster than 0.05ms target)
- ✅ QuadTree remove: 2ms (50x faster than 100ms target)
- ✅ Widget rebuild: 4.70ms (3.5x under 16.67ms budget)
- ✅ Interaction handling: 2.25ms (7x under 16.67ms budget)
- ✅ Memory: Stable with 1000 elements, no leaks over 50 cycles

**Additional Performance Tests** (Phase 0.9-0.11):

- Resize handle hit test: <1ms (QuadTree performance applies)
- Context menu open/close: <10ms
- Hover detection with 1000+ elements: <5ms

---

## Success Criteria for Phase 0 Completion

### Functional Requirements

- [x] Core architecture (QuadTree, Coordinator, RenderBox, Gestures, Widget) - **DONE Phase 0.1-0.4**
- [x] Basic interactions (select, pan, multi-select) - **DONE Phase 0.5-0.7**
- [ ] **Resize functionality** - IMPLEMENTED but NOT TESTED → **Phase 0.9**
- [ ] **Context menu** - IMPLEMENTED but NOT TESTED → **Phase 0.10**
- [ ] **Hover edge cases** - PARTIAL, bugs reported → **Phase 0.10**
- [ ] **All 15 conflict scenarios** - 6 tested, 9 missing → **Phase 0.9-0.11**

### Test Coverage Requirements

- [x] Unit tests: QuadTree (17 tests) - **DONE**
- [ ] Unit tests: Coordinator (41 tests) → **Add 8-10 for resize/context menu/edit modes** → Phase 0.9-0.11
- [ ] Widget tests: 10 → **Add 25-35 for all scenarios** → Phase 0.9-0.11
- [ ] Integration tests: 13 → **Add 12-18 for complete workflows** → Phase 0.9-0.11
- [x] Performance tests: 10 benchmarks - **DONE**
- [ ] Visual tests: 0 → **Add 5-10 golden tests (OPTIONAL)** → Phase 0.12

**Target**: 130-160 total tests (current: 91)

### Bug Fixes Required

- [ ] **Inconsistent hover detection** - User reported "where elements are close to each other" → **MUST FIX Phase 0.10**
- [ ] Any bugs discovered during comprehensive testing → **Fix immediately**

### Documentation Requirements

- [ ] Update phase_0_summary.md: Change status from "PRODUCTION-READY" to honest "IN PROGRESS - 60% → 100%"
- [ ] Update readme.md: Remove premature "COMPLETE ✅" claims
- [ ] Create phase_0_test_plan.md: **THIS DOCUMENT**
- [ ] Document all 15 conflict scenarios with test evidence

---

## Appendix: Conflict Scenario Reference Table

Quick reference for all 15 scenarios from `conflict_resolution_table.md`:

| #   | Scenario                      | Priority A | Priority B | Winner                     | Status        | User Reported              |
| --- | ----------------------------- | ---------- | ---------- | -------------------------- | ------------- | -------------------------- |
| 1   | Resize handle vs Datapoint    | 9          | 6          | Handle                     | ❌ NOT TESTED | YES - "drag to resize"     |
| 2   | Datapoint vs Series line      | 6          | 4          | Datapoint                  | ⚠️ PARTIAL    | NO                         |
| 3   | Annotation body vs Datapoint  | 7          | 6          | Annotation (trend)         | ❌ NOT TESTED | NO                         |
| 4   | Overlapping datapoints        | 6          | 6          | Nearest (3px picker)       | ⚠️ PARTIAL    | YES - "inconsistent hover" |
| 5   | Box select vs Datapoint drag  | 6          | 5          | Datapoint (if on point)    | ⚠️ PARTIAL    | NO                         |
| 6   | Pan vs Series click           | 3          | 4          | Pan (middle-button)        | ✅ COMPLETE   | NO                         |
| 7   | Crosshair vs Click            | 0          | Any        | Passive (never wins)       | ✅ COMPLETE   | NO                         |
| 8   | Context menu open             | 10         | All        | Context menu (modal)       | ❌ NOT TESTED | YES - "right click"        |
| 9   | Ctrl+Click multi-select       | N/A        | N/A        | Toggle selection           | ✅ COMPLETE   | NO                         |
| 10  | Resize drag leaves bounds     | 9          | N/A        | Continue resize            | ❌ NOT TESTED | YES - part of resize       |
| 11  | Edit mode active              | 9          | <9         | Edit mode blocks           | ❌ NOT TESTED | NO                         |
| 12  | Pan + Hover tooltips          | 3          | 0          | Pan suspends hover         | ✅ COMPLETE   | NO                         |
| 13  | Datapoint drag vs Series drag | 7          | 5          | Datapoint (Alt for series) | ❌ NOT TESTED | NO                         |
| 14  | Box select over annotations   | 5          | N/A        | Ignore annotations         | ❌ NOT TESTED | NO                         |
| 15  | Long press vs Drag            | N/A        | N/A        | Thresholds: 5px/500ms      | ❌ NOT TESTED | NO                         |

**Summary**: 4 complete ✅ | 3 partial ⚠️ | 8 not tested ❌  
**User-Reported Issues**: 4 scenarios (all marked YES)  
**Phase 0 Completion**: Requires ALL 15 scenarios fully tested

---

## Notes

1. **User Feedback is Critical**: The user correctly identified 3 major gaps (resize, right-click, hover bugs) that would have been missed without their intervention.

2. **Test Count ≠ Coverage**: 91 passing tests is meaningless if only 40% of scenarios are validated. Phase 0.13 requires **scenario coverage**, not just test volume.

3. **Implementation ≠ Validation**: Just because `ResizableElement`, `contextMenuOpen`, and hover exist in the code doesn't mean they work correctly. Tests are mandatory.

4. **Premature Declarations are Dangerous**: Claiming "PRODUCTION-READY" without comprehensive validation undermines trust and quality. Phase 0 is NOT complete until ALL scenarios pass.

5. **This Document is the Source of Truth**: Use this plan to track REAL progress. Update status as tests are added and scenarios validated.

---

**Document Status**: 🟡 LIVING DOCUMENT - Update as tests are completed  
**Next Update**: After Phase 0.9 (resize tests complete)  
**Owner**: Development Team  
**Last Reviewed**: 2025-01-XX
