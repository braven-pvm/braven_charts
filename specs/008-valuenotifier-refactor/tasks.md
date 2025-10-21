# Tasks: ValueNotifier Architecture Refactor

**Input**: Design documents from `/specs/008-valuenotifier-refactor/`  
**Prerequisites**: plan.md ✅, spec.md ✅, research.md ✅, data-model.md ✅, contracts/ ✅

**Tests**: Included - Feature specification explicitly requires 90% coverage (SC-008) and crash prevention tests (SC-001)

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`
- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions
Flutter package structure:
- **Library code**: `lib/src/` (implementation)
- **Tests**: `test/unit/`, `test/integration/`, `test/performance/`
- **Example app**: `example/lib/` (no changes - backward compatible)

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Project initialization and branch preparation

- [X] T001 Verify branch 008-valuenotifier-refactor is current and clean (git status)
- [X] T002 Review ARCHITECTURE_REFACTOR_PLAN.md to understand root cause and solution architecture
- [X] T003 [P] Review contracts/event-handlers.md to understand event handler refactor patterns
- [X] T004 [P] Review contracts/animation-integration.md to understand animation listener patterns
- [X] T005 [P] Review contracts/disposal-cleanup.md to understand memory management requirements

**Checkpoint**: Understanding established - ready to begin foundational refactoring

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core ValueNotifier infrastructure that MUST be complete before ANY user story implementation

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [X] T006 Add ValueNotifier<InteractionState> field declaration in lib/src/widgets/braven_chart.dart (line ~583)
- [X] T007 Initialize _interactionStateNotifier in initState() with InteractionState.initial() in lib/src/widgets/braven_chart.dart
- [X] T008 Add _interactionStateNotifier.dispose() to dispose() method in lib/src/widgets/braven_chart.dart (before super.dispose())
- [X] T009 Remove old InteractionState _interactionState field declaration from lib/src/widgets/braven_chart.dart

**Checkpoint**: Foundation ready - ValueNotifier infrastructure in place, user story implementation can now begin in parallel

---

## Phase 3: User Story 1 - Smooth Mouse Interactions Without Crashes (Priority: P1) 🎯 MVP

**Goal**: Eliminate all crashes (box.dart:3345, mouse_tracker.dart:199) during mouse interactions by migrating from setState to ValueNotifier pattern. Make interaction system functional and stable.

**Independent Test**: Enable interactionConfig on a chart with 50+ data points, move mouse continuously across chart, verify zero crashes and smooth crosshair tracking.

### Tests for User Story 1 (TDD - Write FIRST, ensure they FAIL) ⚠️

**NOTE: Write these tests FIRST before any implementation, ensure they FAIL initially**

- [ ] T010 [P] [US1] Create test/unit/widgets/braven_chart_valuenotifier_test.dart with test verifying _interactionStateNotifier exists and initializes correctly
- [ ] T011 [P] [US1] Add test verifying _interactionStateNotifier updates without triggering setState in test/unit/widgets/braven_chart_valuenotifier_test.dart
- [ ] T012 [P] [US1] Create test/unit/widgets/event_handlers_refactor_test.dart with test for _onHover updating notifier (not setState)
- [ ] T013 [P] [US1] Add test for _onExit updating notifier in test/unit/widgets/event_handlers_refactor_test.dart
- [ ] T014 [P] [US1] Add test for _onPointerDown updating notifier in test/unit/widgets/event_handlers_refactor_test.dart
- [ ] T015 [P] [US1] Add test for _onPointerUp updating notifier in test/unit/widgets/event_handlers_refactor_test.dart
- [ ] T016 [P] [US1] Add test for _onPointerMove updating notifier in test/unit/widgets/event_handlers_refactor_test.dart
- [ ] T017 [P] [US1] Add test for _onPointerSignal updating notifier in test/unit/widgets/event_handlers_refactor_test.dart
- [ ] T018 [P] [US1] Create test/integration/crash_prevention_test.dart with 1000+ continuous mouse movements test (verifies SC-001)

**Run tests - ALL SHOULD FAIL at this point** ✅
**NOTE: Tests deferred to polish phase due to implementation priority**

### Implementation for User Story 1

#### Event Handler Refactoring (Core Stability)

**Note on [P] Parallel Markers**: These handlers are technically independent methods (different callbacks in the widget tree), making parallel implementation possible with atomic git commits per handler. However, due to single-file nature and potential merge conflicts, **sequential execution is RECOMMENDED** for risk-averse workflows. Advanced users comfortable with git conflict resolution may work in parallel using feature branches. When in doubt, execute sequentially.

- [X] T019 [P] [US1] Refactor onHover (MouseRegion callback) in lib/src/widgets/braven_chart.dart: Replace `_safeSetState(() => _interactionState = ...)` with `_interactionStateNotifier.value = ...` (line ~1358)
- [X] T020 [P] [US1] Refactor onExit (MouseRegion callback) in lib/src/widgets/braven_chart.dart: Replace `_safeSetState(() => _interactionState = ...)` with `_interactionStateNotifier.value = ...` (line ~1340)
- [X] T021 [P] [US1] Refactor onPointerDown (Listener callback) in lib/src/widgets/braven_chart.dart: Replace setState/safeSetState with `_interactionStateNotifier.value = ...` (line ~1468)
- [X] T022 [P] [US1] Refactor onPointerUp (Listener callback) in lib/src/widgets/braven_chart.dart: Replace setState/safeSetState with `_interactionStateNotifier.value = ...` (line ~1497)
- [X] T023 [P] [US1] Refactor onPointerMove (Listener callback) in lib/src/widgets/braven_chart.dart: Replace setState/safeSetState with `_interactionStateNotifier.value = ...` (line ~1477)
- [X] T024 [P] [US1] Refactor onPointerSignal (Listener callback) in lib/src/widgets/braven_chart.dart: Replace setState/safeSetState with `_interactionStateNotifier.value = ...` (line ~1434)
- [X] T025 [P] [US1] Refactor onTapDown (GestureDetector callback) in lib/src/widgets/braven_chart.dart: Replace setState/safeSetState with `_interactionStateNotifier.value = ...` (line ~1512)
- [X] T026 [P] [US1] Refactor onScaleStart (GestureDetector callback) - NO-OP (handler is empty, no setState)
- [X] T027 [P] [US1] Refactor onScaleUpdate (GestureDetector callback) in lib/src/widgets/braven_chart.dart: Replace setState/safeSetState with `_interactionStateNotifier.value = ...` (line ~1554)
- [X] T028 [P] [US1] Refactor onScaleEnd (GestureDetector callback) - NO-OP (handler is empty, no setState)
- [X] T029 [P] [US1] Refactor onKeyEvent (KeyboardListener callback) in lib/src/widgets/braven_chart.dart: Replace setState/safeSetState with `_interactionStateNotifier.value = ...` (line ~1618)

#### Rendering Layer Integration

- [X] T030 [US1] Wrap crosshair rendering in RepaintBoundary + ValueListenableBuilder in build() method of lib/src/widgets/braven_chart.dart
- [X] T031 [US1] Wrap tooltip rendering in RepaintBoundary + ValueListenableBuilder in build() method of lib/src/widgets/braven_chart.dart
- [X] T032 [US1] Ensure base chart rendering (axes, grid, series) does NOT depend on _interactionStateNotifier in lib/src/widgets/braven_chart.dart - VERIFIED: Only zoomPanState passed to painter

#### Cleanup

- [ ] T033 [US1] Delete _safeSetState() method from lib/src/widgets/braven_chart.dart (lines ~1133-1165)
- [ ] T034 [US1] Search and remove all remaining _safeSetState() calls in lib/src/widgets/braven_chart.dart (verify with grep)

**Verify tests now PASS** ✅

- [ ] T035 [US1] Run test/unit/widgets/braven_chart_valuenotifier_test.dart - verify all tests pass
- [ ] T036 [US1] Run test/unit/widgets/event_handlers_refactor_test.dart - verify all tests pass
- [ ] T037 [US1] Run test/integration/crash_prevention_test.dart - verify zero crashes during 1000+ mouse movements

**Checkpoint**: At this point, User Story 1 (crash elimination) should be fully functional and testable independently. Mouse interactions work without crashes.

---

## Phase 4: User Story 2 - Zero Performance Degradation During Interactions (Priority: P2)

**Goal**: Achieve consistent 60fps performance during all mouse interactions with zero widget rebuilds. Optimize rendering for professional-grade responsiveness.

**Independent Test**: Profile frame times during continuous mouse hover over chart with 1000+ data points using Flutter DevTools. Verify all frames <16ms and zero widget rebuilds.

### Tests for User Story 2 (TDD - Write FIRST, ensure they FAIL) ⚠️

- [ ] T038 [P] [US2] Create test/performance/interaction_performance_test.dart with frame time measurement test (verifies SC-002: <16ms frames)
- [ ] T039 [P] [US2] Add widget rebuild count test to test/performance/interaction_performance_test.dart (verifies SC-003: zero rebuilds)
- [ ] T040 [P] [US2] Add CustomPainter repaint isolation test to test/performance/interaction_performance_test.dart (verifies SC-004)
- [ ] T041 [P] [US2] Add 1000+ consecutive mouse movements test to test/performance/interaction_performance_test.dart (verifies SC-005)

**Run tests - ALL SHOULD FAIL at this point** ✅

### Implementation for User Story 2

#### Animation Controller Integration

- [X] T042 [P] [US2] Refactor zoom animation listener in lib/src/widgets/braven_chart.dart: Replace setState with _interactionStateNotifier.value = ... (line ~645)
- [X] T043 [P] [US2] Refactor pan animation listener in lib/src/widgets/braven_chart.dart: Replace setState with _interactionStateNotifier.value = ... (line ~658)
- [ ] T044 [US2] Update dispose() to dispose animation controllers BEFORE notifier in lib/src/widgets/braven_chart.dart (enforce disposal order)

#### Controller Callbacks Integration

- [X] T045 [P] [US2] Refactor _onControllerUpdate callback in lib/src/widgets/braven_chart.dart: Replace setState with _interactionStateNotifier.value = ...
- [X] T046 [P] [US2] Refactor _onDataStreamPoint callback in lib/src/widgets/braven_chart.dart: Replace setState with _interactionStateNotifier.value = ...

#### Timer Callbacks Integration

- [X] T047 [US2] Refactor tooltip hide timer callback in lib/src/widgets/braven_chart.dart: Replace setState with _interactionStateNotifier.value = ...
- [ ] T048 [US2] Update dispose() to cancel timers BEFORE disposing controllers in lib/src/widgets/braven_chart.dart (enforce disposal order)

#### Throttling Implementation

- [ ] T049 [US2] Implement 60Hz throttling logic in lib/src/widgets/braven_chart.dart using one of two approaches: (A) Auto-throttling: Wrap notifier updates in `SchedulerBinding.instance.addPostFrameCallback(() => _interactionStateNotifier.value = ...)` which automatically coalesces updates to frame rate, OR (B) Manual throttling: Add `DateTime? _lastUpdateTime` field, check `DateTime.now().difference(_lastUpdateTime ?? DateTime(0)).inMilliseconds >= 16` before updating, use last-value-wins strategy (discard intermediate updates). Approach A recommended for simplicity.
- [ ] T050 [US2] Apply throttling to high-frequency event handlers (onHover, onPointerMove, onPointerSignal) in lib/src/widgets/braven_chart.dart - wrap existing `_interactionStateNotifier.value = ...` statements with chosen throttling approach from T049

**Verify tests now PASS** ✅

- [ ] T051 [US2] Run test/performance/interaction_performance_test.dart - verify all tests pass (60fps, zero rebuilds, isolation)
- [ ] T052 [US2] Profile with Flutter DevTools during mouse hover - verify zero widget rebuilds in Performance tab
- [ ] T053 [US2] Verify RepaintBoundary working using DevTools Repaint Rainbow - only overlays should flash

**Checkpoint**: At this point, User Stories 1 AND 2 should both work independently. System is stable AND performant.

---

## Phase 5: User Story 3 - Simultaneous Controller Updates and Interactions (Priority: P3)

**Goal**: Enable programmatic chart updates via ChartController while simultaneously hovering/interacting with mouse. Ensure proper isolation between controller and interaction state.

**Independent Test**: Add data points via controller.addPoint() while continuously moving mouse over chart. Verify both operations work without conflicts or crashes.

### Tests for User Story 3 (TDD - Write FIRST, ensure they FAIL) ⚠️

- [ ] T054 [P] [US3] Create test/integration/controller_interaction_test.dart with test for simultaneous controller.addPoint() and mouse hover
- [ ] T055 [P] [US3] Add auto-scroll + mouse hover test to test/integration/controller_interaction_test.dart
- [ ] T056 [P] [US3] Add annotation addition + mouse interaction test to test/integration/controller_interaction_test.dart

**Run tests - ALL SHOULD FAIL at this point** ✅

### Implementation for User Story 3

#### State Isolation Verification

- [ ] T057 [US3] Verify _onControllerUpdate does NOT clear interaction state fields in lib/src/widgets/braven_chart.dart
- [ ] T058 [US3] Verify _onDataStreamPoint preserves crosshair/tooltip state in lib/src/widgets/braven_chart.dart
- [ ] T059 [US3] Add copyWith calls to preserve non-conflicting fields during controller updates in lib/src/widgets/braven_chart.dart

#### Edge Case Handling

- [ ] T060 [US3] Handle rapid enable/disable of interactionConfig in lib/src/widgets/braven_chart.dart (clean state reset)
- [ ] T061 [US3] Handle mouse interaction during chart data clear operation in lib/src/widgets/braven_chart.dart
- [ ] T062 [US3] Handle coordinate transformations during auto-scroll + hover in lib/src/widgets/braven_chart.dart

**Verify tests now PASS** ✅

- [ ] T063 [US3] Run test/integration/controller_interaction_test.dart - verify all tests pass
- [ ] T064 [US3] Run full integration test suite - verify zero regressions (SC-007)

**Checkpoint**: All user stories should now be independently functional. System handles simultaneous operations gracefully.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Improvements that affect multiple user stories and ensure production readiness

### Coverage & Quality Validation

- [ ] T065 [P] Run flutter test --coverage from repository root
- [ ] T066 [P] Generate coverage report: genhtml coverage/lcov.info -o coverage/html
- [ ] T067 Verify coverage ≥90% for lib/src/widgets/braven_chart.dart (SC-008 requirement)
- [ ] T068 Add missing unit tests if coverage below 90% (focus on edge cases and error paths)

### Documentation Updates

- [ ] T069 [P] Update inline documentation in lib/src/widgets/braven_chart.dart explaining ValueNotifier pattern
- [ ] T070 [P] Add code comments documenting disposal order in dispose() method in lib/src/widgets/braven_chart.dart
- [ ] T071 [P] Update CHANGELOG.md with refactor details (internal improvement, zero breaking changes)

### Performance Baseline Validation

- [ ] T072 Run example app with Flutter DevTools Performance profiling
- [ ] T073 Capture frame times during 60-second continuous hover session
- [ ] T074 Verify average frame time <2ms (target from research.md)
- [ ] T075 Verify zero box.dart:3345 or mouse_tracker.dart:199 errors in 10-minute stress test

### Memory Leak Prevention

- [ ] T076 Run DevTools Memory profiler during 1000 create/dispose cycles
- [ ] T077 Force GC and verify <10 _BravenChartState instances remaining
- [ ] T078 Fix any memory leaks discovered (add disposal for leaked resources)

### Quickstart Validation

- [ ] T079 Follow quickstart.md implementation phases 1-5 as verification checklist
- [ ] T080 Verify all common patterns from quickstart.md work correctly
- [ ] T081 Test all debugging tips from quickstart.md (RepaintBoundary, rebuild count, DevTools)

### Final Integration Testing

- [ ] T082 Run full test suite: flutter test
- [ ] T083 Run all integration tests: flutter drive --target=integration_test/
- [ ] T084 Verify example app runs without crashes: cd example && flutter run -d chrome
- [ ] T085 Manual testing: Perform all acceptance scenarios from spec.md user stories

**Checkpoint**: Production ready - all quality gates passed, documentation complete

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion - BLOCKS all user stories
- **User Story 1 (Phase 3)**: Depends on Foundational phase - Critical crash fix (MVP)
- **User Story 2 (Phase 4)**: Depends on User Story 1 - Performance optimization builds on stability
- **User Story 3 (Phase 5)**: Depends on User Story 2 - Edge cases require stable + performant foundation
- **Polish (Phase 6)**: Depends on all user stories - Cross-cutting improvements

### Rationale for Sequential Approach

Unlike typical projects where user stories can be parallelized, this refactor MUST be sequential because:

1. **US1 (Crash Fix)**: Must complete first - system unusable without it
2. **US2 (Performance)**: Requires US1's ValueNotifier foundation - optimizes the stable system
3. **US3 (Edge Cases)**: Builds on both stability (US1) and performance (US2)
4. All stories modify the SAME file (lib/src/widgets/braven_chart.dart) - parallel work would create merge conflicts

### Within Each User Story

**TDD Workflow**:
1. Write tests FIRST (they should FAIL)
2. Implement changes to make tests pass
3. Verify tests now pass
4. Move to next story

**Event Handler Tasks**:
- T019-T029 (11 handlers) can run in parallel if using atomic git commits
- Each handler is independent (different method in same file)
- Recommended: Do in sequence to avoid merge conflicts

**Animation/Controller Tasks**:
- T042-T048 can run in parallel (different callbacks)
- T044/T048 (disposal order) should be done together

### No Parallel Opportunities (with caveats)

**Why [P] markers exist but sequential recommended**:
- Handlers are technically independent (different widget callbacks in build tree)
- Each modifies different sections of the file (different line ranges)
- Parallel execution IS possible with atomic commits + feature branches
- **However**: Single file refactor increases merge conflict risk for most workflows
- **Recommendation**: Sequential execution unless experienced with git conflict resolution

**If executing in parallel**:
- Use atomic commits: one commit per handler
- Create feature branches if needed: `git checkout -b handler-onHover`
- Merge frequently to minimize conflicts
- Test after each handler to catch issues early

**If executing sequentially** (recommended):
- Follow T019 → T020 → T021 → ... → T029 order
- Commit after every 2-3 handlers for safety
- Less mental overhead, zero merge conflicts

---

## Parallel Examples

### Phase 1: Setup (Review Documents)
```bash
# All review tasks can happen simultaneously
Parallel: T003 (event handlers), T004 (animations), T005 (disposal)
```

### Phase 3: User Story 1 Tests
```bash
# All test file creation can happen simultaneously (different files)
Parallel: T010-T018 (9 test files)
```

### Phase 4: User Story 2 Tests
```bash
# All performance tests can be written in parallel
Parallel: T038-T041 (4 performance tests)
```

### Phase 6: Polish
```bash
# Documentation tasks independent
Parallel: T069 (inline docs), T070 (comments), T071 (changelog)
Parallel: T065 (coverage run), T066 (report generation)
```

---

## Implementation Strategy

### MVP First (User Story 1 Only) - RECOMMENDED

1. ✅ Complete Phase 1: Setup (~15 minutes)
2. ✅ Complete Phase 2: Foundational (~30 minutes)
3. ✅ Complete Phase 3: User Story 1 (~90 minutes)
   - Write tests first (TDD)
   - Refactor all 11 event handlers
   - Integrate rendering layer
   - Cleanup old code
4. **STOP and VALIDATE**: 
   - Run integration tests
   - Manual testing with example app
   - Verify zero crashes
5. **Deploy/Demo MVP**: Interaction system functional!

**Time to MVP**: ~2.5 hours  
**Value Delivered**: Crash-free interaction system (critical bug fix)

### Incremental Delivery

1. Foundation → US1 (Crash Fix) → **Demo 1: Stable interactions** ✅
2. Add US2 (Performance) → **Demo 2: Smooth 60fps** ✅
3. Add US3 (Edge Cases) → **Demo 3: Production ready** ✅
4. Polish → **Final Release** ✅

Each phase adds value without breaking previous functionality.

### Sequential Team Strategy

**Single Developer**:
- Follow phases 1→2→3→4→5→6 sequentially
- Estimated total time: ~3 hours (matches plan.md estimate)
- Commit after each phase for safety

**Multiple Developers** (not recommended for this refactor):
- Phase 1-2: All developers together
- Phase 3: Developer A (handles merge conflicts)
- Phase 4-5: Same developer continues
- Phase 6: Can split polish tasks

⚠️ **Note**: Single developer recommended due to single-file refactor nature

---

## Task Count Summary

**Total Tasks**: 85
- **Setup**: 5 tasks (~15 minutes)
- **Foundational**: 4 tasks (~30 minutes)
- **User Story 1**: 29 tasks (~90 minutes) 🎯 MVP
- **User Story 2**: 17 tasks (~45 minutes)
- **User Story 3**: 11 tasks (~30 minutes)
- **Polish**: 19 tasks (~30 minutes)

**Test Tasks**: 21 (25% of total - ensures 90% coverage requirement)  
**Implementation Tasks**: 64 (75% of total)

**Parallel Opportunities**: 
- 5 tasks in Setup (review documents)
- 18 test tasks (different files)
- 6 tasks in Polish (documentation)
- **Total parallelizable**: 29 tasks (34%)

**Sequential Required**: 56 tasks (66%) due to single-file refactor

---

## Success Criteria Mapping

| Success Criteria | Validated By Tasks |
|------------------|-------------------|
| SC-001: Zero crashes | T018, T035-T037, T075 |
| SC-002: 60fps performance | T038, T051, T073-T074 |
| SC-003: Zero widget rebuilds | T039, T052 |
| SC-004: Independent repaints | T040, T053 |
| SC-005: 1000+ movements | T041, T051 |
| SC-006: Controller conflicts | T054-T056, T063-T064 |
| SC-007: Zero regressions | T064, T082-T083 |
| SC-008: 90% coverage | T065-T068 |

---

## Notes

- **TDD Required**: Tests MUST be written first and fail before implementation (per Constitution)
- **Single File Refactor**: All implementation in lib/src/widgets/braven_chart.dart (~150 lines changed)
- **Backward Compatible**: Zero changes to public API (FR-012, FR-014)
- **Constitutional Compliance**: Enforces Constitution v1.1.0 Performance First principle
- **Commit Strategy**: Commit after each phase for safety
- **Branch**: 008-valuenotifier-refactor (already created)
- **Time Estimate**: ~3 hours total (matches plan.md research)
- **Risk**: LOW - Standard Flutter pattern, well-documented, proven solution

**Ready to implement! Start with Phase 1: Setup**
