# 018 X-Axis Renderer Fix — Refactor Plan

## Goal

Replace legacy X-axis configuration and rendering with `XAxisConfig` end-to-end. Remove the legacy `AxisConfig` API to eliminate ambiguity and ensure all X-axis properties are applied consistently.

## Current Problems

1. `BravenChartPlus` allows both `xAxis` (legacy) and `xAxisConfig` (new), which is confusing.
2. Rendering pipeline still derives config from legacy `AxisConfig`, so new `XAxisConfig` properties are ignored.
3. `AxisConfig` is still present and referenced across widget, axis system, and demos.

## Target State

- `BravenChartPlus` exposes **only** `xAxisConfig: XAxisConfig?` (no legacy `xAxis`).
- `AxisConfig` is removed from the codebase (public model + internal wrappers).
- All X-axis rendering uses `XAxisConfig` directly.
- Backward compatibility is intentionally broken to force correct usage.

## Refactor Scope

### 1) Public API Cleanup

- Remove `AxisConfig` from `lib/src/models/axis_config.dart`.
- Remove `xAxis` parameter from `BravenChartPlus` (constructor + factories).
- Update any public examples/demos to use `XAxisConfig` only.

### 2) Internal Axis System

- Remove `lib/src/axis/axis_config.dart` (internal wrapper of legacy config).
- Update `lib/src/axis/axis.dart` to accept `XAxisConfig` (or a new internal config derived from it).
- Ensure tick generation and scale logic are fed by `XAxisConfig` or computed defaults.

### 3) Rendering Pipeline

- In `ChartRenderBox`, remove all conversion from legacy `_xAxis.config` to `XAxisConfig`.
- Use `_xAxisConfig` as the **single source of truth** for X-axis rendering and crosshair styling.
- Ensure axis bounds are still computed from data (not config) when config min/max are null.

### 4) Tests

- Update widget tests to use `xAxisConfig` only.
- Remove any tests referencing `AxisConfig`.
- Add integration coverage verifying `XAxisConfig` properties affect rendering.

## Decision Points (Need Review)

1. **Axis creation**: Should `XAxisConfig` produce a new internal axis config, or should we bypass legacy `Axis` entirely for X-axis?
2. **Data bounds**: Keep `Axis` for scale/ticks? Or move to a dedicated `XAxisLayout` utility?
3. **Migration strategy**: Hard break (remove legacy) vs. staged deprecation (not requested).

## Proposed Implementation Phases

### Phase A — API Removal (Breaking Change)

- Remove `xAxis` from `BravenChartPlus` and all factories.
- Delete `AxisConfig` public model.
- Update demos and tests.

### Phase B — Internal Axis Cleanup

- Remove legacy axis config wrapper.
- Rework `Axis.fromPublicConfig` to use `XAxisConfig` (or replace it).

### Phase C — Rendering Alignment

- Wire `XAxisConfig` through `ChartRenderBox` and `XAxisPainter` without conversions.
- Verify crosshair label styling uses `XAxisConfig` directly.

### Phase D — Validation

- Run full test suite.
- Update CHANGELOG and docs.

## Files Impacted (Expected)

- lib/src/braven_chart_plus.dart
- lib/src/models/axis_config.dart (remove)
- lib/src/axis/axis_config.dart (remove)
- lib/src/axis/axis.dart
- lib/src/rendering/chart_render_box.dart
- example/lib/demos/x_axis_rendering_demo.dart
- test/widgets/braven_chart_plus_x_axis_config_test.dart
- Any legacy references under lib/legacy/

## Risks

- Large surface area: axis system is intertwined with transforms and ticks.
- Removing `AxisConfig` will cause compile breaks across demos/tests.
- Need to confirm all axis-related defaults remain sensible.

## Acceptance Criteria

- No `AxisConfig` references remain in `lib/src` or `example`.
- `BravenChartPlus` only supports `XAxisConfig` for X-axis configuration.
- All `XAxisConfig` properties are applied in rendering.
- All tests pass.

## Immediate Next Step

Review this plan, then implement Phase A first.
