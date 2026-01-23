# Implementation Plan: Multi-Series Rendering Improvements

**Branch**: `002-multi-series-rendering-fix` | **Date**: 2026-01-23 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/002-multi-series-rendering-fix/spec.md`

**Note**: This template is filled in by the `/speckit.plan` command. See `.specify/templates/commands/plan.md` for the execution workflow.

## Summary

Fix two critical rendering issues in multi-series charts: (1) Multiple bar series at the same X-position must render adjacent (grouped) rather than overlapping, and (2) Vertical (Y-axis) zoom must work correctly when using `NormalizationMode.perSeries` with multiple Y-axes. Changes must preserve existing 60fps performance with 1000+ data points.

## Technical Context

**Language/Version**: Dart 3.0+, Flutter SDK 3.10.0+  
**Primary Dependencies**: Flutter standard libraries (dart:ui, dart:math), no external packages for core rendering  
**Storage**: N/A (stateless rendering library)  
**Testing**: flutter test (unit, widget, golden, integration via flutter_driver)  
**Target Platform**: Flutter Web (primary), iOS/Android (secondary)  
**Project Type**: Single library project  
**Performance Goals**: 60fps with 1000+ data points during zoom/pan interactions  
**Constraints**: <16ms frame times, no additional per-frame allocations during pan/zoom  
**Scale/Scope**: Charts with 2-10 bar series, 2+ Y-axes

## Constitution Check

_GATE: Must pass before Phase 0 research. Re-check after Phase 1 design._

| Principle                    | Status  | Notes                                                                        |
| ---------------------------- | ------- | ---------------------------------------------------------------------------- |
| I. Test-First Development    | ✅ PASS | Widget tests for grouped bars and Y-zoom required before implementation      |
| II. Performance First        | ✅ PASS | 60fps target explicit in spec; no setState in render path; O(n) bar grouping |
| III. Architectural Integrity | ✅ PASS | Pure Flutter, modifies existing rendering modules only                       |
| IV. Requirements Compliance  | ✅ PASS | Will update tasks.md after each completed task                               |
| V. API Consistency           | ✅ PASS | No new public APIs; internal changes only                                    |
| VI. Documentation Discipline | ✅ PASS | Will document BarGroupInfo and forPainting parameter                         |
| VII. Simplicity (KISS)       | ✅ PASS | Minimal changes to existing architecture; BarGroupInfo is simple data class  |

**Gate Result**: ✅ PASS - All gates satisfied

### Post-Phase 1 Design Review

| Check                               | Status | Evidence                                                   |
| ----------------------------------- | ------ | ---------------------------------------------------------- |
| No setState in high-frequency paths | ✅     | BarGroupInfo computed during element generation, not paint |
| No per-frame allocations            | ✅     | All objects created during element generation phase        |
| Immutable data structures           | ✅     | BarGroupInfo is immutable with final fields                |
| O(n) or better complexity           | ✅     | Bar grouping O(n) where n = series count                   |
| Existing architecture preserved     | ✅     | Uses existing SeriesElement, MultiAxisManager patterns     |

## Project Structure

### Documentation (this feature)

```
specs/002-multi-series-rendering-fix/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/           # Phase 1 output (N/A - no API contracts)
└── tasks.md             # Phase 2 output (/speckit.tasks command)
```

### Source Code (repository root)

```
lib/src/
├── elements/
│   └── series_element.dart      # UPDATE: _paintBarSeries() grouped bar logic
├── models/
│   └── bar_group_info.dart      # CREATE: BarGroupInfo class
├── rendering/
│   ├── chart_render_box.dart    # UPDATE: Pass BarGroupInfo, use forPainting bounds
│   └── modules/
│       └── multi_axis_manager.dart  # UPDATE: forPainting parameter
├── coordinates/
│   └── chart_transform.dart     # REVIEW: Zoom transform for perSeries
└── braven_chart_plus.dart       # UPDATE: Compute bar series index/count

test/
├── unit/
│   └── rendering/
│       ├── bar_group_info_test.dart     # CREATE: Unit tests for positioning
│       └── multi_axis_zoom_test.dart    # CREATE: Y-zoom normalization tests
├── widget/
│   └── charts/
│       ├── grouped_bar_chart_test.dart  # CREATE: Grouped bar rendering tests
│       └── multi_axis_zoom_test.dart    # CREATE: Y-zoom widget tests
└── integration/
    └── multi_series_rendering_test.dart # CREATE: Full integration tests
```

**Structure Decision**: Single library project with changes isolated to `lib/src/elements/`, `lib/src/rendering/`, and `lib/src/models/`. Tests organized by type (unit, widget, integration).

## Complexity Tracking

_No constitution violations requiring justification._
