# Implementation Plan: X-Axis Architecture Unification

**Branch**: `017-x-axis-unification` | **Date**: 2025-01-14 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/017-x-axis-unification/spec.md`

## Summary

Unify X-axis architecture to achieve feature parity with the Y-axis rendering system established in Sprint 013. This involves creating `XAxisConfig` configuration model (parallel to `YAxisConfig`), `XAxisPainter` rendering class (parallel to `MultiAxisPainter`), extending `AxisColorResolver` for X-axis support, and adding per-series binding while maintaining backward compatibility with existing `AxisConfig`.

## Technical Context

**Language/Version**: Dart 3.10.0-227.0.dev, Flutter SDK 3.38.6  
**Primary Dependencies**: Standard Flutter libraries (dart:ui, flutter/painting.dart), NO external packages  
**Storage**: N/A (stateless rendering library)  
**Testing**: `flutter test` - unit tests in `test/unit/`, widget tests in `test/widgets/`  
**Target Platform**: Flutter Web (primary), iOS/Android (secondary)  
**Project Type**: Single Flutter package library  
**Performance Goals**: 60 FPS, frame times under 16ms, TextPainter caching for efficiency  
**Constraints**: No setState in high-frequency updates (ValueNotifier required), RepaintBoundary isolation  
**Scale/Scope**: ~15 files modified/created, ~1500 lines of new code, 7 user stories

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Status | Evidence |
|-----------|--------|----------|
| I. Test-First Development | ✅ PASS | TDD mandated - tests before implementation for all new classes |
| II. Performance First (60fps) | ✅ PASS | TextPainter caching, no setState in pointer handlers, RepaintBoundary isolation planned |
| III. Architectural Integrity | ✅ PASS | Pure Flutter, follows existing MultiAxisPainter patterns, extends AxisColorResolver |
| IV. Requirements Compliance | ✅ PASS | 30 FRs mapped to user stories, tasks.md will track deviations |
| V. API Consistency & Stability | ✅ PASS | Backward compatibility (FR-029, FR-030), deprecation-safe design |
| VI. Documentation Discipline | ✅ PASS | Comprehensive dartdocs required for all public APIs |
| VII. Simplicity & Pragmatism | ✅ PASS | Follows existing YAxisConfig/MultiAxisPainter patterns - no novel architecture |

**Gate Status**: ✅ PASSED - No violations. Design follows established patterns.

## Project Structure

### Documentation (this feature)

```
specs/017-x-axis-unification/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── checklists/          # Validation checklists
│   └── requirements.md  # Already created during /speckit.specify
└── tasks.md             # Phase 2 output (/speckit.tasks command)
```

### Source Code (repository root)

```
lib/
└── src/
    ├── models/
    │   ├── x_axis_config.dart        # NEW: XAxisConfig class
    │   ├── x_axis_position.dart      # NEW: XAxisPosition enum
    │   ├── y_axis_config.dart        # REFERENCE: AxisLabelDisplay, CrosshairLabelPosition (reused)
    │   └── chart_series.dart         # UPDATE: Add optional xAxisConfig property
    ├── rendering/
    │   ├── x_axis_painter.dart       # NEW: XAxisPainter class
    │   ├── axis_color_resolver.dart  # UPDATE: Extend for XAxisConfig
    │   └── multi_axis_painter.dart   # REFERENCE: Architecture pattern
    ├── axis/
    │   └── x_axis_renderer.dart      # DEPRECATE: Legacy renderer
    └── widgets/
        └── braven_chart_plus.dart    # UPDATE: Add xAxisConfig parameter

test/
├── unit/
│   ├── models/
│   │   └── x_axis_config_test.dart   # NEW: XAxisConfig unit tests
│   └── rendering/
│       ├── x_axis_painter_test.dart  # NEW: XAxisPainter unit tests
│       └── axis_color_resolver_test.dart  # UPDATE: X-axis color tests
└── widget/
    └── x_axis_widget_test.dart       # NEW: Integration tests
```

**Structure Decision**: Flutter package library structure with `lib/src/` for source and `test/` for tests. Follows existing codebase organization with models, rendering, and widgets separated.

## Complexity Tracking

*No violations - design follows established patterns.*

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| None | N/A | N/A |

