# Research: X-Axis Renderer Unification

**Feature**: 018-x-axis-renderer  
**Date**: 2026-01-18  
**Status**: Complete

## Overview

This research documents the technical decisions made during the design phase. All clarifications were resolved during the technical design document creation (see [X_AXIS_RENDERING_UNIFICATION.md](../../docs/design/X_AXIS_RENDERING_UNIFICATION.md)).

## Research Topics

### 1. Default X-Axis Color Strategy

**Decision**: Use first series color (consistent with Y-axis behavior)

**Rationale**: Maintains API consistency with Y-axis. The first series color provides a reasonable default that integrates with the chart's visual theme. Users can override with explicit `XAxisConfig.color`.

**Alternatives Considered**:
- Neutral theme color - Rejected because it differs from Y-axis approach
- Hardcoded default - Rejected because it's less flexible

### 2. X-Axis Title Label Orientation

**Decision**: Horizontal, centered below tick labels

**Rationale**: Standard chart convention. X-axis has horizontal space available, so rotation is unnecessary. Y-axis rotates because vertical space is limited horizontally.

**Layout**:
`
───1───2───3───
     Time (s)
`

**Alternatives Considered**:
- Rotated like Y-axis - Rejected because X-axis has horizontal space
- No title support - Rejected because parity with Y-axis is needed

### 3. Grid Line Ownership

**Decision**: Keep grid lines in separate renderer (out of scope)

**Rationale**: Maintains separation of concerns and avoids breaking changes. Grid theming can be addressed in a future sprint if needed.

**Alternatives Considered**:
- Move vertical grid lines into XAxisPainter - Rejected to limit scope
- Pass axis color to GridRenderer - Could be future enhancement

### 4. XAxisConfig vs YAxisConfig Property Mapping

**Decision**: XAxisConfig is a simplified subset of YAxisConfig

**Properties Included** (17 total):
- `color`, `label`, `unit` - Appearance
- `min`, `max` - Bounds
- `visible`, `showAxisLine`, `showTicks`, `showCrosshairLabel` - Visibility
- `labelDisplay` - Label/unit display mode
- `minHeight`, `maxHeight` - Sizing (renamed from minWidth/maxWidth)
- `tickLabelPadding`, `axisLabelPadding`, `axisMargin` - Spacing
- `tickCount`, `labelFormatter` - Formatting

**Properties Excluded**:
- `id` - Single axis, no ID needed
- `position` - Always bottom
- `crosshairLabelPosition` - Always below plot area

**Rationale**: X-axis is single-instance, so multi-axis properties are unnecessary. This simplifies the API while maintaining feature parity.

### 5. Reference Implementation Analysis

**Decision**: Model XAxisPainter after MultiAxisPainter

**Key Patterns from MultiAxisPainter**:
1. TextPainter caching for performance
2. Nice-number tick generation algorithm
3. Axis color resolution from config → series → theme → default
4. Separate methods for axis line, tick marks, tick labels, axis title
5. Cache invalidation when bounds or style change

**Files to Reference**:
- `lib/src/rendering/multi_axis_painter.dart` - Main rendering logic
- `lib/src/models/y_axis_config.dart` - Configuration structure
- `lib/src/rendering/modules/crosshair_renderer.dart` - Crosshair label styling

### 6. Integration Points Identified

**Decision**: Four integration points required

| Component | Change Required |
|-----------|-----------------|
| `BravenChartPlus` | Add `xAxisConfig` parameter |
| `ChartRenderBox` | Instantiate and call `XAxisPainter.paint()` |
| `CrosshairRenderer` | Accept `XAxisConfig` for X-label theming |
| `XAxisRenderer` | Bypass/remove calls (legacy) |

**Critical Lesson**: Previous sprint failed because painter was created but `paint()` was never called. Integration verification is mandatory.

### 7. Crosshair Label Styling

**Decision**: Match Y-axis crosshair label styling exactly

**Styling Spec**:
- Background: `axisColor.withValues(alpha: 0.15)` (semi-transparent)
- Border: `axisColor.withValues(alpha: 0.6)`
- Border width: 1.0
- Border radius: Use `labelStyle?.borderRadius ?? 3.0`
- Text: Value only (no ""X:"" prefix)

**Reference**: `CrosshairRenderer._paintPerAxisCrosshairLabels()` lines 575-670

## Conclusion

All technical decisions have been made and documented. No outstanding clarifications remain. Ready for Phase 1: Design & Contracts.
