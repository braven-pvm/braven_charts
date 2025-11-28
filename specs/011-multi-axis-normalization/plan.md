# Implementation Plan: Multi-Axis Normalization

**Branch**: `011-multi-axis-normalization` | **Date**: 2025-11-27 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/011-multi-axis-normalization/spec.md`

**Note**: This template is filled in by the `/speckit.plan` command. See `.specify/templates/commands/plan.md` for the execution workflow.

## Summary

Enable displaying multiple data series with vastly different Y-axis ranges (e.g., Power 0-300W, Tidal Volume 0.5-4L) on the same chart. Each series is internally normalized to use full vertical space while up to 4 color-coded Y-axes display original values. Auto-detection triggers multi-axis mode when series ranges differ by >10x.

## Technical Context

**Language/Version**: Dart 3.10.0-227.0.dev, Flutter SDK 3.37.0-1.0.pre-216  
**Primary Dependencies**: Standard Dart libraries only (dart:core, dart:math, dart:ui) - NO external packages  
**Storage**: N/A (stateless rendering, data provided by caller)  
**Testing**: flutter test (unit, widget, golden, integration with ChromeDriver)  
**Target Platform**: Flutter Web (primary), iOS/Android (secondary)  
**Project Type**: Single library package with example app  
**Performance Goals**: 60 FPS with 4 series × 1000+ points, <5ms normalization overhead per frame  
**Constraints**: O(A) + O(S) memory (no per-point overhead), <16ms frame time  
**Scale/Scope**: Up to 4 Y-axes, unlimited series per axis, 10k+ data points

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Status | Notes |
|-----------|--------|-------|
| I. Test-First Development | ✅ PASS | TDD mandatory - tests before implementation |
| II. Performance First (60fps) | ✅ PASS | 60 FPS target with 4 series × 1000 points; ValueNotifier pattern for any high-frequency updates |
| III. Architectural Integrity | ✅ PASS | Pure Flutter, integrates with existing ChartTransform and AxisConfig |
| IV. Requirements Compliance | ✅ PASS | Spec documented, tasks.md will track deviations |
| V. API Consistency | ✅ PASS | Backward compatible - single-axis mode unchanged |
| VI. Documentation Discipline | ✅ PASS | All public APIs will have documentation |
| VII. Simplicity (KISS) | ✅ PASS | Extends existing axis system, no new patterns required |

**Gate Result**: ✅ ALL GATES PASS - Proceed to Phase 0

## Project Structure

### Documentation (this feature)

```
specs/011-multi-axis-normalization/
├── plan.md              # This file
├── spec.md              # Feature specification
├── base-spec.md         # Detailed technical spec with data models
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/           # Phase 1 output (internal APIs)
├── checklists/
│   └── requirements.md  # Requirements tracking
└── tasks.md             # Phase 2 output
```

### Source Code (repository root)

```
lib/
└── src/
    ├── models/
    │   ├── y_axis_position.dart      # NEW: YAxisPosition enum
    │   ├── normalization_mode.dart   # NEW: NormalizationMode enum
    │   └── chart_series.dart         # MODIFY: Add yAxisId, unit fields
    ├── axis/
    │   ├── axis.dart                 # NEW: Barrel export
    │   ├── y_axis_config.dart        # NEW: YAxisConfig class
    │   ├── multi_axis_state.dart     # NEW: Runtime state
    │   ├── axis_bounds_calculator.dart # NEW: Bounds computation
    │   ├── series_axis_resolver.dart # NEW: Series-to-axis binding
    │   ├── axis_color_resolver.dart  # NEW: Color resolution
    │   ├── range_ratio_calculator.dart # NEW: Auto-detection
    │   └── normalization_detector.dart # NEW: Auto-detection logic
    ├── rendering/
    │   ├── multi_axis_normalizer.dart # NEW: Per-axis normalization
    │   ├── y_axis_renderer.dart      # NEW: Multi-axis rendering
    │   ├── chart_painter.dart        # MODIFY: Multi-axis integration
    │   └── grid_renderer.dart        # MODIFY: Disable in multi-axis
    ├── layout/
    │   ├── multi_axis_layout.dart    # NEW: Layout delegate
    │   └── axis_layout_manager.dart  # NEW: Position management
    ├── interaction/
    │   ├── zoom_controller.dart      # MODIFY: Y-zoom constraint
    │   ├── tooltip_builder.dart      # MODIFY: Original values
    │   ├── crosshair_handler.dart    # MODIFY: Per-axis lookup
    │   └── tracking_overlay.dart     # MODIFY: Multi-series values
    ├── formatting/
    │   └── multi_axis_value_formatter.dart # NEW: Value formatting
    └── widgets/
        └── braven_chart_plus.dart    # MODIFY: yAxes configuration
```
test/
├── unit/
│   └── multi_axis/                   # NEW: Unit tests for normalization
├── widget/
│   └── multi_axis/                   # NEW: Widget tests for axis rendering
└── golden/
    └── multi_axis/                   # NEW: Visual regression tests
```

**Structure Decision**: Extends existing single-project structure. New functionality integrated into existing modules with new test directories for isolation.

## Complexity Tracking

*No constitution violations - section not required.*

All gates pass without exceptions. Feature extends existing patterns without introducing new complexity.

