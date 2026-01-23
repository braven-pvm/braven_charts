# Tasks: Scientific Data Input & Aggregation API

**Input**: Design documents from `/specs/001-data-input-api/`
**Prerequisites**: plan.md (required), spec.md (required for user stories), research.md, data-model.md, contracts/

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Initialize the standalone `braven_data` package and configuration.

- [ ] T001 Create `braven_data/` directory and basic project structure
- [ ] T002 Initialize Dart project with `pubspec.yaml` including `test` and `benchmarks` dependencies
- [ ] T003 [P] Configure `analysis_options.yaml` for strict typing
- [ ] T004 Create benchmarks directory structure at `braven_data/test/benchmarks/`

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Implement the core `TypedData` storage engine required by all user stories.

- [ ] T005 Define abstract `SeriesStorage<TX, TY>` interface in `braven_data/lib/src/storage.dart`
- [ ] T006 Implement `TypedDataStorage` with `Float64List` support in `braven_data/lib/src/storage.dart`
- [ ] T007 Implement `Int64List` support for Time axes (using sentinels) in `braven_data/lib/src/storage.dart`
- [ ] T008 [P] Implement `ListStorage` fallback in `braven_data/lib/src/storage.dart`
- [ ] T009 Create unit tests for storage backend integrity in `braven_data/test/unit/storage_test.dart`
- [ ] T009a Implement `IntervalStorage` (Structure-of-Arrays) for aggregated data support in `braven_data/lib/src/storage.dart`

## Phase 3: User Story 1 - High-Performance Data Ingestion (P1)

**Story**: Load large scientific datasets without blocking UI.
**Independent Test**: Ingest 10M points in benchmark script, verify memory/speed.

- [ ] T010 [US1] Define `SeriesMeta` and `SeriesStats` classes in `braven_data/lib/src/series.dart`
- [ ] T011 [US1] Implement `Series<TX, TY>` container with strict runtime type checking in `braven_data/lib/src/series.dart`
- [ ] T012 [US1] Add `Series.fromTypedData` factory constructor in `braven_data/lib/src/series.dart`
- [ ] T013 [US1] Implement `Series.slice()` method for subset access in `braven_data/lib/src/series.dart`
- [ ] T014 [US1] Create benchmark script `braven_data/test/benchmarks/perf.dart` (include generic vs typed int64 web/native checks)
- [ ] T015 [US1] Implement 10M point ingestion test case in `perf.dart`

## Phase 4: User Story 2 - Deterministic Aggregation (P1)

**Story**: Aggregate dense data for rendering (e.g., 1 point per pixel).
**Independent Test**: Verify reduction of 1000 points → 10 points via windowed aggregation.

- [ ] T016 [US2] Define `WindowSpec` class (Fixed, Rolling, PixelAligned) in `braven_data/lib/src/aggregation.dart`
- [ ] T017 [US2] Define `SeriesReducer` abstract base and built-ins (Mean, Max, Min) in `braven_data/lib/src/aggregation.dart`
- [ ] T018 [US2] Implement `AggregationSpec` configuration class in `braven_data/lib/src/aggregation.dart`
- [ ] T019 [US2] Add `aggregate(AggregationSpec)` method to `Series` class in `braven_data/lib/src/series.dart`
- [ ] T020 [US2] Implement synchronous aggregation engine logic in `braven_data/lib/src/engine.dart`
- [ ] T021 [US2] Create unit tests for aggregation correctness (Mean/Max) in `braven_data/test/unit/aggregation_test.dart`

## Phase 5: User Story 3 - Scientific Pipeline & Metrics (P2)

**Story**: Domain-specific transformations (Normalized Power).
**Independent Test**: Calculate Normalized Power from raw watts and verify against known formula.

- [ ] T022 [US3] Define `Pipeline<TX, TY>` fluent interface in `braven_data/lib/src/pipeline.dart`
- [ ] T023 [US3] Implement pipeline operators (`map`, `rolling`) in `braven_data/lib/src/pipeline.dart`
- [ ] T024 [US3] Implement domain algorithms (Normalized Power, xPower) as custom Reducers in `braven_data/lib/src/algorithms.dart`
- [ ] T025 [US3] Connect Pipeline execution to Series via `transform()` method in `braven_data/lib/src/series.dart`
- [ ] T026 [US3] Create integration test for NP calculation in `braven_data/test/integration/scientific_test.dart`

## Phase 6: Polish & Cross-Cutting

- [ ] T027 [P] Export public API surface in `braven_data/lib/braven_data.dart`
- [ ] T028 Add API documentation comments for all public classes
- [ ] T029 Create `README.md` with usage examples from quickstart.md

## Dependencies

- **Phase 1 (Setup)**: Blocks everything.
- **Phase 2 (Foundation)**: Blocks US1, US2, US3.
- **Phase 3 (US1)**: Blocks US2 (needs Series object).
- **Phase 4 (US2)**: Can run parallel with US3 (mostly), but US3 depends on basic reduction logic.
- **Phase 5 (US3)**: Depends on US2's Reducer infrastructure.

## Parallel Execution Examples

- T003 (Linting) can run parallel to T001/T002.
- T024 (Algorithms) can be implemented while T020 (Engine) is being built.
- T027 (Exports) can happen anytime after Phase 2.

## Implementation Strategy

- **Step 1 (MVP)**: Complete Phases 1, 2, and 3. This gives raw ingestion capability.
- **Step 2 (Rendering Support)**: Complete Phase 4. This enables the "Rendering Contract".
- **Step 3 (Science)**: Complete Phase 5. Adds the specific algorithmic requirements.
