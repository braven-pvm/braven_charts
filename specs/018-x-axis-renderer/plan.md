# Implementation Plan: X-Axis Renderer Unification

**Branch**: `018-x-axis-renderer` | **Date**: 2026-01-18 | **Spec**: [spec.md](spec.md)  
**Design Document**: [X_AXIS_RENDERING_UNIFICATION.md](../../docs/design/X_AXIS_RENDERING_UNIFICATION.md)

## Summary

Replace the legacy X-axis rendering pipeline with a new unified renderer that matches Y-axis theming and styling. Create `XAxisConfig` (modeled on `YAxisConfig`) and `XAxisPainter` (modeled on `MultiAxisPainter`), integrate them into `ChartRenderBox` and `BravenChartPlus`, and update `CrosshairRenderer` to use themed X-value labels. Critical lesson from previous sprint failure: the new renderer MUST be wired in and actually called, not just created.

## Technical Context

**Language/Version**: Dart 3.10.0-227.0.dev, Flutter SDK 3.38.6  
**Primary Dependencies**: Standard Flutter libraries (dart:ui, flutter/painting.dart), NO external packages  
**Storage**: N/A (stateless rendering library)  
**Testing**: flutter test (unit, widget, integration tests)  
**Target Platform**: Flutter Web (primary), iOS/Android (secondary)  
**Project Type**: Single Flutter package with example app  
**Performance Goals**: 60 FPS rendering, frame times under 16ms  
**Constraints**: Must maintain backward compatibility, must not break existing charts  
**Scale/Scope**: Single X-axis per chart (no multi-axis), approximately 17 configurable properties

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Status | Notes |
|-----------|--------|-------|
| **I. Test-First Development** | ✅ PASS | Tests will be written before implementation for each component |
| **II. Performance First (60fps)** | ✅ PASS | Uses TextPainter caching, matches existing MultiAxisPainter patterns; no setState in rendering |
| **III. Architectural Integrity** | ✅ PASS | Pure Flutter implementation, follows existing patterns (MultiAxisPainter) |
| **IV. Requirements Compliance** | ✅ PASS | Spec and design document define all requirements |
| **V. API Consistency** | ✅ PASS | XAxisConfig mirrors YAxisConfig API for consistency |
| **VI. Documentation Discipline** | ✅ PASS | All public APIs will be documented with examples |
| **VII. Simplicity (KISS)** | ✅ PASS | Single-axis implementation is simpler than multi-axis Y approach |

**Gate Status**: ✅ ALL PASSED - Proceed to Phase 0

## Project Structure

### Documentation (this feature)

`
specs/018-x-axis-renderer/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/           # Phase 1 output
├── checklists/          # Quality checklists
│   └── requirements.md  # Specification quality checklist
└── tasks.md             # Phase 2 output (created by /speckit.tasks)
`

### Source Code (repository root)

`
lib/
├── braven_charts.dart           # Main library export (add XAxisConfig export)
└── src/
    ├── models/
    │   ├── x_axis_config.dart   # NEW: X-axis configuration class
    │   └── y_axis_config.dart   # Reference: Y-axis config (existing)
    ├── rendering/
    │   ├── x_axis_painter.dart  # NEW: X-axis painter (replaces old renderer)
    │   ├── multi_axis_painter.dart  # Reference: Y-axis painter (existing)
    │   └── modules/
    │       └── crosshair_renderer.dart  # MODIFY: Add XAxisConfig support
    ├── axis/
    │   └── x_axis_renderer.dart # DEPRECATED: Legacy renderer (to be bypassed)
    └── widgets/
        └── braven_chart_plus.dart  # MODIFY: Add xAxisConfig parameter

example/
└── lib/
    └── demos/
        └── x_axis_theming_demo.dart  # NEW: Visual verification demo

test/
├── unit/
│   ├── models/
│   │   └── x_axis_config_test.dart  # NEW: Config unit tests
│   └── rendering/
│       └── x_axis_painter_test.dart # NEW: Painter unit tests
├── widget/
│   └── x_axis_integration_test.dart # NEW: Integration tests
└── golden/
    └── x_axis_theming_test.dart     # NEW: Visual regression tests
`

**Structure Decision**: Single Flutter package structure. New files for XAxisConfig and XAxisPainter, modifications to existing ChartRenderBox and CrosshairRenderer.

## Complexity Tracking

*No constitution violations - section not applicable*

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| (none)    | N/A        | N/A                                 |
