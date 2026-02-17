# Tasks: Segment & Area Data Analysis

**Input**: Design documents from `/specs/006-segment-area-analysis/`
**Prerequisites**: plan.md ✓, spec.md ✓, research.md ✓, data-model.md ✓, contracts/ ✓, quickstart.md ✓

**Tests**: Included — spec explicitly defines unit, widget, golden, and performance test requirements (Constitution check: "TDD workflow will be followed").

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions

- **Source**: `lib/src/` at repository root
- **Tests**: `test/` at repository root
- **Barrel exports**: `lib/braven_charts.dart`

---

## Phase 1: Setup

**Purpose**: Create directory structure and placeholder files for the new analysis feature

- [ ] T001 Create `lib/src/analysis/` directory and add empty `region_analyzer.dart` file with library doc comment
- [ ] T002 [P] Create `test/unit/analysis/` directory and add empty `region_analyzer_test.dart` placeholder
- [ ] T003 [P] Create `test/unit/models/data_region_test.dart` placeholder
- [ ] T004 [P] Create `test/unit/models/region_summary_test.dart` placeholder

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Data models that ALL user stories depend on. Must be complete before any story implementation.

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [ ] T005 Implement `DataRegionSource` enum and `DataRegion` model class with `id`, `label`, `startX`, `endX`, `source`, `seriesData` fields, `Equatable` equality (by id/startX/endX/source), `copyWith`, and validation (`startX <= endX`, non-empty `id`) in `lib/src/models/data_region.dart`; include dartdoc noting that `startX == endX` (zero-width region) is valid for single-point queries
- [ ] T006 [P] Implement `RegionMetric` enum (min, max, average, sum, count, range, stdDev, delta, firstY, lastY, duration) with display labels in `lib/src/models/region_summary.dart`
- [ ] T007 [P] Implement `SeriesRegionSummary` model class with all statistical fields (count, min, max, sum, average, range, stdDev, firstY, lastY, delta, duration), `Equatable` equality, and null rules (stdDev/delta null when count < 2) in `lib/src/models/region_summary.dart`
- [ ] T008 Implement `RegionSummary` model class (region + seriesSummaries map) with `Equatable` equality in `lib/src/models/region_summary.dart` (depends on T005, T007)
- [ ] T009 [P] Implement `RegionSummaryPosition` enum (aboveRegion, insideTop, insideBottom) and `RegionSummaryConfig` model class (metrics set, valueFormatter, position) with defaults (`{min, max, average}`, `aboveRegion`) in `lib/src/models/region_summary_config.dart`
- [ ] T010 Add `RegionSelectedCallback` and `CustomRegionAnalysisCallback` typedefs to `lib/src/models/interaction_callbacks.dart`
- [ ] T011 Add barrel exports for all new public types (`data_region.dart`, `region_summary.dart`, `region_summary_config.dart`, `region_analyzer.dart`) to `lib/braven_charts.dart`
- [ ] T012 Write unit tests for `DataRegion` model: equality, copyWith, validation (startX <= endX, non-empty id), different sources in `test/unit/models/data_region_test.dart`
- [ ] T013 [P] Write unit tests for `SeriesRegionSummary`: field values, null rules (count < 2 → null stdDev/delta), edge cases (count=0, count=1) in `test/unit/models/region_summary_test.dart`
- [ ] T014 [P] Write unit tests for `RegionSummary`: per-series map, empty map, and `RegionSummaryConfig` defaults in `test/unit/models/region_summary_test.dart`

**Checkpoint**: Foundation ready — all models exist, pass tests, are exported. User story implementation can begin.

---

## Phase 3: User Story 1 — Query Data Within a Range Annotation (Priority: P1) 🎯 MVP

**Goal**: When a user taps a vertical range annotation, fire `onRegionSelected` callback with a `DataRegion` containing all series data within the annotation's X-range.

**Independent Test**: Create a chart with series data and a range annotation, tap the annotation, verify the callback delivers correct filtered data points per series within the annotation's X-range.

### Tests for US1

- [ ] T015 [P] [US1] Write unit tests for `RegionAnalyzer.filterPointsInRange()`: sorted binary-search path, unsorted linear-scan fallback, inclusive boundaries, empty input, boundary duplicates, single-point match, range outside data in `test/unit/analysis/region_analyzer_test.dart`
- [ ] T016 [P] [US1] Write unit tests for `RegionAnalyzer.regionFromAnnotation()`: builds DataRegion from RangeAnnotation + multi-series data, maps filtered points per series, excludes series with no matches, handles empty series in `test/unit/analysis/region_analyzer_test.dart`

### Implementation for US1

- [ ] T017 [US1] Implement `RegionAnalyzer.filterPointsInRange()` with binary search on sorted data (O(log n + k)) and linear-scan fallback, sorted heuristic (`first.x <= last.x`), inclusive bounds in `lib/src/analysis/region_analyzer.dart`
- [ ] T018 [US1] Implement `RegionAnalyzer.regionFromAnnotation()` that builds a `DataRegion` from a `RangeAnnotation` and `Map<String, List<ChartDataPoint>>` series data, filtering each series via `filterPointsInRange()` in `lib/src/analysis/region_analyzer.dart`
- [ ] T019 [US1] Add `onRegionSelected` callback property (`RegionSelectedCallback?`) to `BravenChartPlus` widget in `lib/src/braven_chart_plus.dart`
- [ ] T020 [US1] Wire annotation-tap flow: in `EventHandlerManager._handleElementTap()` (or equivalent), detect `RangeAnnotationElement`, extract startX/endX, call `RegionAnalyzer.regionFromAnnotation()`, fire `onRegionSelected` with the resulting `DataRegion` — detection logic in `lib/src/rendering/modules/event_handler_manager.dart`, callback dispatch through `BravenChartPlusState` in `lib/src/braven_chart_plus.dart`; only annotations with non-null `startX` and `endX` qualify (reject horizontal-only annotations)
- [ ] T021 [US1] Add `selectedDataRegions` getter to `BravenChartPlusState` that lazily builds `List<DataRegion>` from current coordinator selection state in `lib/src/braven_chart_plus.dart`
- [ ] T022 [US1] Write widget test: create chart with 3 series + range annotation spanning X=3.2..7.8, simulate tap on annotation, verify `onRegionSelected` fires with correct DataRegion (source=rangeAnnotation, correct seriesData per series); also assert `onAnnotationTap` still fires alongside `onRegionSelected` (both callbacks co-fire per base spec integration contract); verify `selectedDataRegions` getter returns matching DataRegion after tap in `test/unit/analysis/annotation_region_widget_test.dart`
- [ ] T023 [US1] Write widget test: range annotation covers zero data points → callback fires with empty seriesData map; multiple series where only some have data in range → only matching series included; horizontal-only annotation (null startX/endX) is ignored — no callback fires; single-region selection (FR-005): tap annotation A then tap annotation B → only B's region is active and A is deselected in `test/unit/analysis/annotation_region_widget_test.dart`

**Checkpoint**: User Story 1 complete — tapping a range annotation yields filtered data via callback.

---

## Phase 4: User Story 2 — Built-in Summary Statistics (Priority: P1)

**Goal**: Compute min/max/average/sum/count/range/stdDev/delta/firstY/lastY/duration per series within a selected region, without consumers writing aggregation code.

**Independent Test**: Select a region, call `computeRegionSummaries()`, verify each metric against manually calculated expected values.

### Tests for US2

- [ ] T024 [P] [US2] Write unit tests for `RegionAnalyzer.computeSeriesSummary()`: correct computation of all metrics for 50-point series, 1-point series (stdDev=null, delta=null), 0-point series (returns null), floating-point precision (within 1e-10) in `test/unit/analysis/region_analyzer_test.dart`
- [ ] T025 [P] [US2] Write unit tests for `RegionAnalyzer.computeRegionSummary()`: multi-series region, omits series with zero data, custom seriesNames/seriesUnits pass-through in `test/unit/analysis/region_analyzer_test.dart`

### Implementation for US2

- [ ] T026 [US2] Implement `RegionAnalyzer.computeSeriesSummary()` that computes count, min, max, sum, average, range, stdDev (population), firstY, lastY, delta, duration from a list of `ChartDataPoint` in `lib/src/analysis/region_analyzer.dart`
- [ ] T027 [US2] Implement `RegionAnalyzer.computeRegionSummary()` that iterates all series in a `DataRegion`, calls `computeSeriesSummary()` per series, returns `RegionSummary` (omitting empty series); cache the result per region and invalidate on selection change in `lib/src/analysis/region_analyzer.dart`
- [ ] T028 [US2] Add `computeRegionSummaries([List<DataRegion>? regions])` method to `BravenChartPlusState` that delegates to `RegionAnalyzer.computeRegionSummary()` for each region (defaults to `selectedDataRegions` if null) in `lib/src/braven_chart_plus.dart`
- [ ] T029 [US2] Write widget test: programmatic analysis via `GlobalKey<BravenChartPlusState>` — select region, call `computeRegionSummaries()`, verify all metrics match expected values in `test/unit/analysis/region_summary_widget_test.dart`

**Checkpoint**: User Story 2 complete — built-in stats available via `computeRegionSummaries()`.

---

## Phase 5: User Story 3 — Analyse Data in Segmented Series (Priority: P2)

**Goal**: When a user taps a data point within a styled segment, detect the contiguous segment group and fire `onRegionSelected` with a `DataRegion` covering all points in that group.

**Independent Test**: Create a series with styled segments, tap a point within a segment, verify callback delivers all points in the contiguous segment group.

### Tests for US3

- [ ] T030 [P] [US3] Write unit tests for `RegionAnalyzer.detectSegmentGroups()`: contiguous same-style groups, non-adjacent same-style treated as separate, unstyled points excluded, single-point segments, all-same-style series in `test/unit/analysis/region_analyzer_test.dart`
- [ ] T031 [P] [US3] Write unit tests for `RegionAnalyzer.segmentGroupForPoint()`: point inside a group returns correct DataRegion, point outside any group returns null, boundary points included in `test/unit/analysis/region_analyzer_test.dart`

### Implementation for US3

- [ ] T032 [US3] Implement `RegionAnalyzer.detectSegmentGroups()` that iterates `List<ChartDataPoint>`, groups consecutive non-null `SegmentStyle` by value equality, returns `List<DataRegion>` (source=segment) with X-range from group's first/last point; use ID format `'segment_<seriesId>_<startIndex>'` per base spec convention in `lib/src/analysis/region_analyzer.dart`
- [ ] T033 [US3] Implement `RegionAnalyzer.segmentGroupForPoint()` that finds which segment group contains a given point index, returns `DataRegion` or null in `lib/src/analysis/region_analyzer.dart`
- [ ] T034 [US3] Wire segment-tap flow: in point-tap handler, check if tapped `ChartDataPoint.segmentStyle != null`, call `RegionAnalyzer.segmentGroupForPoint()`, fire `onRegionSelected` with the segment group `DataRegion` (source=segment) — detection logic in `lib/src/rendering/modules/event_handler_manager.dart`, callback dispatch through `BravenChartPlusState` in `lib/src/braven_chart_plus.dart`
- [ ] T035 [US3] Write widget test: series with points 0-9 styled blue and 10-19 styled red, tap point 5, verify callback delivers region with points 0-9; tap unstyled point → no segment region callback in `test/unit/analysis/segment_region_widget_test.dart`
- [ ] T036 [US3] Write widget test: non-adjacent same-style groups (blue 0-4, red 5-9, blue 10-14), tap point 12, verify only points 10-14 returned (contiguity check) in `test/unit/analysis/segment_region_widget_test.dart`

**Checkpoint**: User Story 3 complete — tapping a styled segment yields segment-group data.

---

## Phase 6: User Story 4 — Box-Select to Analyse Ad-Hoc Regions (Priority: P2)

**Goal**: When a user drags a bounding box, create a transient `DataRegion` from the drag's X-range and fire `onRegionSelected`.

**Independent Test**: Perform box-select drag, verify a transient region is created with the drag's X-range and the callback fires with correct filtered data.

### Tests for US4

- [ ] T037 [P] [US4] Write widget test: box-select drag from X=2.0 to X=8.0, verify `onRegionSelected` fires with DataRegion (source=boxSelect) containing correct series data in the X-range; assert callback fires synchronously upon drag completion; also assert `onSelectionChanged` still fires alongside `onRegionSelected` (both callbacks co-fire per base spec integration contract) in `test/unit/analysis/box_select_region_widget_test.dart`
- [ ] T038 [P] [US4] Write widget test: active box-select region is cleared on click elsewhere (callback fires with null); starting a new box-select replaces the previous region; assert only one box-select DataRegion exists at a time (replacement, not accumulation) in `test/unit/analysis/box_select_region_widget_test.dart`

### Implementation for US4

- [ ] T039 [US4] Wire box-select flow: in `EventHandlerManager._completeBoxSelection()` (or equivalent), convert box rect to data-space X-range, build transient `DataRegion` (source=boxSelect) via `RegionAnalyzer.filterPointsInRange()`, fire `onRegionSelected` — detection logic in `lib/src/rendering/modules/event_handler_manager.dart`, callback dispatch through `BravenChartPlusState` in `lib/src/braven_chart_plus.dart`
- [ ] T040 [US4] Implement region clearing: on click-elsewhere or new interaction, fire `onRegionSelected(null)` and clear the transient box-select state in `lib/src/braven_chart_plus.dart`
- [ ] T041 [US4] Ensure `selectedDataRegions` getter includes the transient box-select region when active in `lib/src/braven_chart_plus.dart`

**Checkpoint**: User Story 4 complete — box-select creates transient analysable regions.

---

## Phase 7: User Story 5 — Visual Summary Overlay (Priority: P3)

**Goal**: Opt-in overlay card showing configured metrics (min, max, average, delta) per series above/inside the selected region, painted in the overlay layer without invalidating the series cache.

**Independent Test**: Enable summary overlay, select a region, verify an overlay card appears with correct metrics, positioned correctly, and the series layer cache is not invalidated.

### Tests for US5

- [ ] T042 [P] [US5] Write unit tests for `RegionSummaryRenderer.paint()`: renders card with configured metrics, formats values, positions above region with inside-top fallback, handles multi-series display in `test/unit/rendering/modules/region_summary_renderer_test.dart`
- [ ] T043 [P] [US5] Write golden tests: overlay card appearance with min/max/avg metrics for 1 series, 2 series, and 3 series; include variants for both positions — above region (default) and inside-top fallback (when card would exceed chart top boundary) in `test/golden/region_summary_overlay_test.dart`

### Implementation for US5

- [ ] T044 [US5] Implement `RegionSummaryRenderer` as a stateless const module (matching `TooltipRenderer` pattern) with `paint(Canvas, Size, RegionSummary, RegionSummaryConfig, Rect regionBounds)` method that renders a card with metric labels and values, including position calculation (center above region bounds, fall back to inside-top if card would exceed chart area top boundary) in `lib/src/rendering/modules/region_summary_renderer.dart`
- [ ] ~~T045~~ _(merged into T044)_
- [ ] T046 [US5] Add `showRegionSummary` (bool, default false) and `regionSummaryConfig` (`RegionSummaryConfig?`) properties to `BravenChartPlus` widget in `lib/src/braven_chart_plus.dart`
- [ ] T047 [US5] Wire overlay painting: extend `_paintOverlayLayer()` and `_hasActiveOverlayContent()` in `ChartRenderBox` to invoke `RegionSummaryRenderer.paint()` when `showRegionSummary` is true and a region is selected in `lib/src/rendering/chart_render_box.dart`; verify series layer cache (`_seriesLayerPicture`) is NOT invalidated by overlay repaint
- [ ] T048 [US5] Add `showRegionSummaryOverlay(DataRegion)` and `hideRegionSummaryOverlay()` methods to `BravenChartPlusState` for programmatic overlay control; write widget tests verifying: overlay is dismissed when region is deselected (US5 acceptance #3); toggling `showRegionSummary` from true to false hides the overlay in `lib/src/braven_chart_plus.dart` and `test/unit/analysis/region_summary_widget_test.dart`

**Checkpoint**: User Story 5 complete — overlay card renders with configured metrics.

---

## Phase 8: User Story 6 — Custom Analysis Extensions (Priority: P3)

**Goal**: Allow consumers to register a custom analysis function that runs after built-in summary and merges additional metrics into the result/overlay.

**Independent Test**: Register a custom function that returns `{'Normalized Power': '250 W'}`, select a region, verify the custom metric appears alongside built-in ones.

### Tests for US6

- [ ] T049 [P] [US6] Write widget test: register `customRegionAnalysis` callback returning `{'NP': '250 W'}`, select region, verify custom metrics appear in summary overlay card in `test/unit/analysis/custom_analysis_widget_test.dart`
- [ ] T050 [P] [US6] Write widget test: no custom callback registered → only built-in metrics shown, no error in `test/unit/analysis/custom_analysis_widget_test.dart`

### Implementation for US6

- [ ] T051 [US6] Add `customRegionAnalysis` (`CustomRegionAnalysisCallback?`) property to `BravenChartPlus` widget in `lib/src/braven_chart_plus.dart`
- [ ] T052 [US6] Wire custom analysis: after computing `RegionSummary`, invoke `customRegionAnalysis(region, summary)` if non-null, merge returned `Map<String, String>` into overlay display data in `lib/src/braven_chart_plus.dart`
- [ ] T053 [US6] Update `RegionSummaryRenderer.paint()` to accept and display custom metric entries alongside built-in metrics in `lib/src/rendering/modules/region_summary_renderer.dart`

**Checkpoint**: User Story 6 complete — custom domain-specific metrics integrated into analysis pipeline.

---

## Phase 9: Polish & Cross-Cutting Concerns

**Purpose**: Performance validation, edge cases, documentation, and demo

- [ ] T054 Write performance benchmark: `RegionAnalyzer.filterPointsInRange()` with 100k sorted points completes under 10ms, `computeSeriesSummary()` with 1k points completes under 5ms; verify no measurable increase in series-layer paint time when hovering/crosshair is active with summary overlay visible (frame budget test) in `test/benchmark/region_analysis_benchmark.dart`
- [ ] T055 [P] Write edge-case unit tests: region X-range extends beyond data boundaries (returns only actual data), unsorted data fallback produces correct results, duplicate X values at boundary are included, multi-axis series where X values use different scales (filtering uses raw data coordinates), analysis of region mid-stream produces correct results from currently-available data snapshot in `test/unit/analysis/region_analyzer_test.dart`
- [ ] T056 [P] Verify `dart analyze` reports zero issues for all new and modified files (run `dart analyze lib/src/models/data_region.dart lib/src/models/region_summary.dart lib/src/models/region_summary_config.dart lib/src/analysis/region_analyzer.dart lib/src/rendering/modules/region_summary_renderer.dart`)
- [ ] T057 [P] Add dartdoc comments with `///` examples to all public APIs: `DataRegion`, `RegionAnalyzer`, `RegionSummary`, `RegionSummaryConfig`, new `BravenChartPlus` properties
- [ ] T058 Create demo page showing all 3 region sources (annotation tap, segment tap, box-select) with summary overlay enabled in `example/lib/screens/region_analysis_demo.dart`
- [ ] T059 Update `example/lib/main.dart` to include navigation to the region analysis demo page

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — can start immediately
- **Foundational (Phase 2)**: Depends on Phase 1 — BLOCKS all user stories
- **US1 (Phase 3)**: Depends on Phase 2 — core data access
- **US2 (Phase 4)**: Depends on Phase 2; benefits from US1 for widget integration context but logically independent (RegionAnalyzer methods standalone)
- **US3 (Phase 5)**: Depends on Phase 2; parallizable with US1/US2 (segment detection is independent logic)
- **US4 (Phase 6)**: Depends on Phase 2 + US1 (requires `onRegionSelected` wiring from US1 to be in place)
- **US5 (Phase 7)**: Depends on Phase 2 + US2 (needs RegionSummary computation from US2)
- **US6 (Phase 8)**: Depends on US2 + US5 (extends the summary + overlay pipeline)
- **Polish (Phase 9)**: Depends on all user stories being complete

### User Story Dependencies

```
Phase 1 (Setup)
    │
    ▼
Phase 2 (Foundational Models) ←── BLOCKS everything
    │
    ├─────────────┬───────────────┐
    ▼             ▼               ▼
 US1 (P1)     US2 (P1)       US3 (P2)
 Annotation   Summary Stats  Segments
    │             │
    ▼             │
 US4 (P2)        │
 Box-Select      │
                  ▼
              US5 (P3)
              Overlay
                  │
                  ▼
              US6 (P3)
              Custom Analysis
                  │
                  ▼
            Phase 9 (Polish)
```

### Within Each User Story

- Tests MUST be written and FAIL before implementation (TDD red-green)
- Models before services/logic
- Core logic before widget integration
- Unit tests before widget tests
- Story complete before moving to next priority

### Parallel Opportunities

- **Phase 1**: T002, T003, T004 are all [P] (different files)
- **Phase 2**: T006, T007, T009 are [P] (independently defined); T012, T013, T014 are [P] tests
- **US1**: T015, T016 are [P] tests
- **US2**: T024, T025 are [P] tests
- **US3**: T030, T031 are [P] tests
- **US4**: T037, T038 are [P] tests
- **US5**: T042, T043 are [P] tests
- **US6**: T049, T050 are [P] tests
- **Phase 9**: T055, T056, T057 are [P]
- **Cross-phase**: US1, US2, and US3 can run in parallel after Phase 2
