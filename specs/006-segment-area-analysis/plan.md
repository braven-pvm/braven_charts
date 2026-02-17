# Implementation Plan: Segment & Area Data Analysis

**Branch**: `006-segment-area-analysis` | **Date**: 2026-02-14 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/006-segment-area-analysis/spec.md`

## Summary

Make underlying series data within chart regions (range annotations, visual segments, and box-select areas) programmatically accessible and optionally summarizable with built-in statistics.

**Technical approach**: Add a `DataRegion` model representing an X-range of interest, a stateless `RegionAnalyzer` utility for filtering and summarization (binary search on sorted data), wire region callbacks into the existing annotation selection and box-select flows via `ChartInteractionCoordinator`, and paint an optional summary overlay card in the existing Layer 2 overlay system alongside tooltips and crosshairs.

## Technical Context

**Language/Version**: Dart >=3.9.0 <4.0.0, Flutter SDK >=3.35.0  
**Primary Dependencies**: Flutter standard libraries (dart:ui, dart:math), `equatable: ^2.0.8` for model equality; no new external packages required  
**Storage**: N/A (stateless — data provided by caller, analysis is point-in-time)  
**Testing**: `flutter_test`, `mockito: ^5.4.1`, `test: ^1.26.3`; golden tests for overlay rendering  
**Target Platform**: Flutter Web (primary), iOS/Android (secondary)  
**Project Type**: Single Flutter package (library)  
**Performance Goals**: 60fps/16ms frame budget; region analysis <10ms for 10k points; overlay painting <2ms  
**Constraints**: Analysis MUST be lazy (on-demand only, never in paint/layout); overlay MUST NOT invalidate GPU-cached series layer; MUST use original (non-normalized) data values  
**Scale/Scope**: 5 new files, 5 modified files; ~34.5h estimated effort

## Constitution Check

_GATE: Must pass before Phase 0 research. Re-check after Phase 1 design._

| Principle                                       | Status  | Notes                                                                                                                                                                                                                                                   |
| ----------------------------------------------- | ------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **I. Test-First Development**                   | ✅ PASS | Spec defines unit, widget, golden, and performance test requirements. TDD workflow will be followed.                                                                                                                                                    |
| **II. Performance First (60fps)**               | ✅ PASS | Analysis is lazy/on-demand only (FR-007). Overlay paints in Layer 2 — no series cache invalidation (FR-013). No setState in high-frequency paths — region selection is a discrete tap/drag event, not continuous. Binary search O(log n) for filtering. |
| **III. Architectural Integrity (Pure Flutter)** | ✅ PASS | No HTML/web-specific APIs. New modules follow existing patterns (stateless module like `TooltipRenderer`, models like `ChartDataPoint`). No circular dependencies — models → analyzer → renderer, each layer uni-directional.                           |
| **IV. Requirements Compliance**                 | ✅ PASS | Full spec with 17 functional requirements and 9 success criteria. tasks.md will track deviations.                                                                                                                                                       |
| **V. API Consistency & Stability**              | ✅ PASS | New public APIs follow existing Flutter conventions (callbacks, getters, config objects). No breaking changes — all additions are optional with defaults off.                                                                                           |
| **VI. Documentation Discipline**                | ✅ PASS | All public APIs will have dartdoc with examples. Architecture decisions documented in base spec.                                                                                                                                                        |
| **VII. Simplicity & Pragmatism (KISS)**         | ✅ PASS | Reuses existing patterns: overlay rendering (TooltipRenderer pattern), selection flow (coordinator), segment detection (\_StyleRegion pattern). No new abstractions beyond what's needed.                                                               |

**Gate result**: ALL PASS — proceed to Phase 0.

**Post-Phase 1 re-check**: ALL PASS confirmed. Data model uses `equatable` (already a dependency). `RegionAnalyzer` is a stateless utility with no setState calls. Overlay renderer follows `TooltipRenderer` pattern exactly. No new violations introduced by design decisions in research.md or contracts.

## Project Structure

### Documentation (this feature)

```
specs/006-segment-area-analysis/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/           # Phase 1 output (Dart API contracts)
└── tasks.md             # Phase 2 output (/speckit.tasks command)
```

### Source Code (repository root)

```
lib/src/
├── models/
│   ├── data_region.dart              # NEW: DataRegion, DataRegionSource
│   ├── region_summary.dart           # NEW: SeriesRegionSummary, RegionSummary, RegionMetric
│   └── region_summary_config.dart    # NEW: RegionSummaryConfig, RegionSummaryPosition
├── analysis/                         # NEW DIRECTORY
│   └── region_analyzer.dart          # NEW: RegionAnalyzer (filter + summarize)
├── rendering/
│   └── modules/
│       └── region_summary_renderer.dart  # NEW: Overlay card painter
├── braven_chart_plus.dart            # MODIFIED: Add region properties, callbacks, getter
├── interaction/
│   └── core/
│       └── coordinator.dart          # MODIFIED: Region selection state (if needed)
└── ...

lib/braven_charts.dart                # MODIFIED: Export new public types

test/
├── unit/
│   ├── analysis/
│   │   ├── region_analyzer_test.dart          # NEW: Filter, summary, edge cases
│   │   ├── annotation_region_widget_test.dart # NEW: Tap annotation → callback
│   │   ├── segment_region_widget_test.dart    # NEW: Tap segment → callback
│   │   ├── box_select_region_widget_test.dart # NEW: Box-select → callback
│   │   ├── region_summary_widget_test.dart    # NEW: Summary via state method
│   │   └── custom_analysis_widget_test.dart   # NEW: Custom analysis callback
│   ├── models/
│   │   ├── data_region_test.dart              # NEW: Equality, copyWith
│   │   └── region_summary_test.dart           # NEW: Metric validation
│   └── rendering/
│       └── modules/
│           └── region_summary_renderer_test.dart # NEW: Overlay renderer
├── golden/
│   └── region_summary_overlay_test.dart   # NEW: Overlay rendering
└── benchmark/
    └── region_analysis_benchmark.dart     # NEW: 100k point analysis
```

**Structure Decision**: Single Flutter package. New `analysis/` directory under `lib/src/` for the `RegionAnalyzer` utility — separate from `models/` (data) and `rendering/` (paint) following existing SOLID separation. All other new files slot into existing directories.

## Complexity Tracking

_No constitution violations — no entries required._
