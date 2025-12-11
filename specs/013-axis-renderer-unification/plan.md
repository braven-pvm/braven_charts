# Implementation Plan: Axis Renderer Unification

**Branch**: `013-axis-renderer-unification` | **Date**: 2025-12-11 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/013-axis-renderer-unification/spec.md`

**Note**: This template is filled in by the `/speckit.plan` command. See `.specify/templates/commands/plan.md` for the execution workflow.

## Summary

**Primary Requirement**: Consolidate two parallel Y-axis rendering paths (`AxisRenderer` and `MultiAxisPainter`) into a single consistent system using `MultiAxisPainter` as the unified Y-axis renderer.

**Technical Approach**: 
1. Add `CrosshairLabelPosition` enum to `YAxisConfig` for crosshair label positioning control
2. Change `BravenChartPlus.yAxis` type from `AxisConfig?` to `YAxisConfig?`
3. Create dedicated `GridRenderer` class, extract grid rendering from axis renderers
4. Rename `AxisRenderer` → `XAxisRenderer`, remove Y-axis code
5. Route all Y-axis rendering through `MultiAxisPainter`
6. Add TextPainter caching to maintain 60fps performance
7. Create `XAxisConfig` for API consistency (future phase)

## Technical Context

**Language/Version**: Dart 3.10.0-227.0.dev, Flutter SDK 3.37.0-1.0.pre-216  
**Primary Dependencies**: Standard Dart libraries only (dart:core, dart:math, dart:ui) - NO external packages  
**Storage**: N/A (stateless rendering library)  
**Testing**: `flutter test` (unit, widget, integration, golden tests)  
**Target Platform**: Flutter Web (primary), iOS/Android (secondary)
**Project Type**: Single Flutter package (lib/) with example app (example/)  
**Performance Goals**: 60fps (16ms frame time) during crosshair interaction and rendering  
**Constraints**: Zero external dependencies, pure Flutter implementation, TextPainter caching required for performance  
**Scale/Scope**: Charting library with ~50 source files, ~15k LOC in lib/

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Status | Notes |
|-----------|--------|-------|
| I. Test-First Development | ✅ PASS | Spec defines testable acceptance scenarios; unit/integration/golden tests required |
| II. Performance First (60fps) | ✅ PASS | FR-014 mandates TextPainter caching; SC-006 requires 60fps verification |
| II.a. High-Frequency State Updates | ✅ PASS | No setState in rendering path; uses CustomPainter + ValueNotifier patterns |
| III. Architectural Integrity | ✅ PASS | Pure Flutter, no HTML; clean separation: GridRenderer, XAxisRenderer, MultiAxisPainter |
| IV. Requirements Compliance | ✅ PASS | Technical spec reference provided; tasks.md will track deviations |
| V. API Consistency | ✅ PASS | Breaking change documented; XAxisConfig mirrors YAxisConfig naming |
| VI. Documentation | ✅ PASS | Migration guide in spec Section 7.1; public APIs will have docs |
| VII. Simplicity (KISS) | ✅ PASS | Facade pattern chosen over complex inheritance; minimal new classes |

**Gate Result**: ✅ ALL GATES PASS - Proceed to Phase 0

## Project Structure

### Documentation (this feature)

```
specs/013-axis-renderer-unification/
├── plan.md              # This file (/speckit.plan command output)
├── research.md          # Phase 0 output (/speckit.plan command)
├── data-model.md        # Phase 1 output (/speckit.plan command)
├── quickstart.md        # Phase 1 output (/speckit.plan command)
├── contracts/           # Phase 1 output (/speckit.plan command)
└── tasks.md             # Phase 2 output (/speckit.tasks command - NOT created by /speckit.plan)
```

### Source Code (repository root)

```
lib/
├── braven_charts.dart           # Package exports
└── src/
    ├── models/
    │   ├── y_axis_config.dart   # MODIFY: Add CrosshairLabelPosition enum
    │   ├── x_axis_config.dart   # NEW: XAxisConfig (Phase 5)
    │   └── grid_config.dart     # NEW: GridConfig
    ├── axis/
    │   ├── axis_renderer.dart   # RENAME → x_axis_renderer.dart, remove Y-axis code
    │   └── ...
    ├── rendering/
    │   ├── multi_axis_painter.dart    # MODIFY: Add TextPainter caching
    │   ├── grid_renderer.dart         # NEW: Dedicated grid rendering
    │   ├── chart_render_box.dart      # MODIFY: Unified Y-axis routing
    │   └── modules/
    │       ├── multi_axis_manager.dart    # MODIFY: Include primary Y-axis
    │       └── crosshair_renderer.dart    # MODIFY: Respect crosshairLabelPosition
    └── braven_chart_plus.dart   # MODIFY: yAxis type change AxisConfig? → YAxisConfig?

test/
├── unit/
│   ├── multi_axis/
│   │   └── y_axis_config_test.dart    # MODIFY: CrosshairLabelPosition tests
│   └── rendering/
│       └── grid_renderer_test.dart    # NEW: GridRenderer tests
├── widget/
│   └── braven_chart_plus_test.dart    # MODIFY: Type change tests
└── integration/
    └── axis_unification_test.dart     # NEW: End-to-end unification tests

example/lib/
└── demos/
    └── axis_unification_demo.dart     # NEW: Demo for unified axis API
```

**Structure Decision**: Single Flutter package with library source in `lib/src/`, tests in `test/`, and example app in `example/`. This matches the existing repository structure.

## Complexity Tracking

*No constitution violations requiring justification.*

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| None | - | - |

---

## Post-Design Constitution Re-Check

*Verified after Phase 1 design completion.*

| Principle | Status | Post-Design Verification |
|-----------|--------|--------------------------|
| I. Test-First Development | ✅ PASS | data-model.md defines testable entities; contracts define behavioral assertions |
| II. Performance First (60fps) | ✅ PASS | TextPainter caching strategy documented in research.md; no new setState usage |
| II.a. High-Frequency State Updates | ✅ PASS | Design uses CustomPainter rendering path; no widget rebuilds in interaction loop |
| III. Architectural Integrity | ✅ PASS | Clean separation: GridRenderer, XAxisRenderer, MultiAxisPainter as distinct classes |
| IV. Requirements Compliance | ✅ PASS | All FRs from spec mapped to data-model entities and API contracts |
| V. API Consistency | ✅ PASS | YAxisConfig/XAxisConfig use identical property naming per contracts |
| VI. Documentation | ✅ PASS | quickstart.md provides migration guide with before/after examples |
| VII. Simplicity (KISS) | ✅ PASS | 3 new classes (GridConfig, GridRenderer, CrosshairLabelPosition enum) - minimal surface |

**Post-Design Gate Result**: ✅ ALL GATES PASS - Ready for Phase 2 task generation

---

## Generated Artifacts

| Artifact | Path | Status |
|----------|------|--------|
| Implementation Plan | `specs/013-axis-renderer-unification/plan.md` | ✅ Complete |
| Research | `specs/013-axis-renderer-unification/research.md` | ✅ Complete |
| Data Model | `specs/013-axis-renderer-unification/data-model.md` | ✅ Complete |
| API Contracts | `specs/013-axis-renderer-unification/contracts/api-contracts.md` | ✅ Complete |
| Quickstart Guide | `specs/013-axis-renderer-unification/quickstart.md` | ✅ Complete |
| Agent Context | `.github/copilot-instructions.md` | ✅ Updated |
| Tasks | `specs/013-axis-renderer-unification/tasks.md` | ⏳ Pending (`/speckit.tasks`) |

---

## Next Steps

Run `/speckit.tasks` to generate the implementation task breakdown.