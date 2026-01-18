# X-Axis Rendering Unification - Technical Design Document

**Date**: 2026-01-17  
**Status**: APPROVED  
**Author**: Technical Analysis  
**Target Sprint**: 017-x-axis-unification (Restart)

---

## 1. Problem Statement

### 1.1 Visual Evidence

The current chart rendering exhibits a jarring visual inconsistency between Y-axis and X-axis rendering:

| Element                  | Y-Axis (NEW)                                   | X-Axis (OLD)                                           |
| ------------------------ | ---------------------------------------------- | ------------------------------------------------------ |
| **Axis Line**            | Themed color (matches series)                  | Default gray/black                                     |
| **Tick Marks**           | Themed color                                   | Default gray/black                                     |
| **Tick Labels**          | Themed color, consistent styling               | Plain black text                                       |
| **Crosshair Value Box**  | Semi-transparent themed background with border | Plain white box with black border                      |
| **Crosshair Value Text** | Clean value only (e.g., `48421.32`)            | Wrong format `X: 1.8`                                  |
| **Renderer Used**        | `MultiAxisPainter` (new unified system)        | `XAxisRenderer` (legacy) + `CrosshairRenderer` X-label |

### 1.2 Root Cause

The Y-axis was refactored to use a new unified rendering system (`MultiAxisPainter`) that:

- Applies consistent theming from series/axis configuration
- Renders axis line, ticks, labels with coordinated colors
- Uses the same color for crosshair value labels
- Supports multi-axis layouts (up to 4 Y-axes)

The X-axis was **never updated** to match this approach. It still uses:

- `XAxisRenderer`: Legacy renderer with hardcoded default styling
- `CrosshairRenderer._paintCrosshairLabels()`: Generic white box with `X:` prefix

---

## 2. Goals

### 2.1 Primary Goal

Replace the X-axis rendering pipeline to achieve visual parity with the Y-axis rendering, creating a cohesive and professional chart appearance.

### 2.2 Non-Goals

- **Multi-axis X-axis**: There will only ever be ONE X-axis (unlike Y which supports up to 4)
- **Position configurability**: X-axis is always at the bottom (no top/outer positions needed)
- **Changing Y-axis implementation**: The Y-axis system is working correctly

---

## 3. Current State Analysis

### 3.1 Y-Axis System (Target Pattern)

#### Configuration: `YAxisConfig`

Located: `lib/src/models/y_axis_config.dart`

Key properties:

- `id`: Internal identifier
- `position`: YAxisPosition (left, right, leftOuter, rightOuter)
- `color`: Themed color for all axis elements
- `label`: Axis title text
- `unit`: Unit suffix for values
- `visible`: Whether to render
- `showAxisLine`: Show axis line
- `showTicks`: Show tick marks
- `showCrosshairLabel`: Show crosshair value label
- `crosshairLabelPosition`: overAxis | insidePlot
- `labelDisplay`: AxisLabelDisplay enum for label/unit combinations
- `minWidth`, `maxWidth`: Size constraints
- `tickLabelPadding`, `axisLabelPadding`, `axisMargin`: Spacing
- `tickCount`: Preferred tick count
- `labelFormatter`: Custom value formatter

#### Renderer: `MultiAxisPainter`

Located: `lib/src/rendering/multi_axis_painter.dart`

Responsibilities:

- Paint axis line with themed color
- Paint tick marks with themed color
- Paint tick labels with themed color
- Paint rotated axis title label
- Generate nice-number tick values
- Cache TextPainters for performance

#### Crosshair Label: `CrosshairRenderer._paintPerAxisCrosshairLabels()`

Located: `lib/src/rendering/modules/crosshair_renderer.dart` (lines 575-670)

Renders:

- Semi-transparent background with axis color tint (`axisColor.withValues(alpha: 0.15)`)
- Border with axis color (`axisColor.withValues(alpha: 0.6)`)
- Value-only text (no `Y:` prefix)

### 3.2 X-Axis System (Current/Legacy)

#### Configuration: `AxisConfig` (public) + `InternalAxisConfig`

Located: `lib/src/models/axis_config.dart` + `lib/src/axis/axis_config.dart`

This is a DIFFERENT configuration class from YAxisConfig, with different properties:

- `showAxis`, `showGrid`, `showTicks`, `showLabels`: Visibility
- `axisColor`, `axisWidth`: Axis line styling
- `gridColor`, `gridWidth`: Grid lines
- `tickLength`, `tickWidth`, `tickColor`: Tick marks
- `label`, `labelFormatter`: Labels
- `range`: AxisRange for bounds

#### Renderer: `XAxisRenderer`

Located: `lib/src/axis/x_axis_renderer.dart`

Problems:

- Uses hardcoded Paint() colors or falls back to theme defaults
- No theming coordination with series
- No modern styling approach

#### Crosshair Label: `CrosshairRenderer._paintCrosshairLabels()`

Located: `lib/src/rendering/modules/crosshair_renderer.dart` (lines 441-565)

Problems:

- Uses generic white background (`Color(0xF0FFFFFF)`)
- Uses generic border (`Color(0xFFBDBDBD)`)
- Formats as `X: \` instead of value-only
- No theming from axis/series configuration

---

## 4. Proposed Solution

### 4.1 Architectural Approach

Create a new `XAxisConfig` and `XAxisPainter` that mirror the Y-axis approach but simplified for single-axis use:

`YAxisConfig (multi-axis)         XAxisConfig (single-axis)
    |                                    |
    v                                    v
MultiAxisPainter (1-4 axes)      XAxisPainter (1 axis only)
    |                                    |
    v                                    v
CrosshairRenderer Y-labels       CrosshairRenderer X-label
(per-axis themed)                (themed to match)`

### 4.2 New X-Axis Configuration: `XAxisConfig`

Create `lib/src/models/x_axis_config.dart`

Properties (subset of YAxisConfig, removing multi-axis concerns):

| Property             | Type                   | Description                           |
| -------------------- | ---------------------- | ------------------------------------- |
| `color`              | `Color?`               | Themed color for all X-axis elements  |
| `label`              | `String?`              | Axis title (e.g., "Time", "Distance") |
| `unit`               | `String?`              | Unit suffix (e.g., "s", "km")         |
| `visible`            | `bool`                 | Whether to render the axis            |
| `showAxisLine`       | `bool`                 | Show horizontal axis line             |
| `showTicks`          | `bool`                 | Show tick marks                       |
| `showCrosshairLabel` | `bool`                 | Show crosshair X-value label          |
| `labelDisplay`       | `AxisLabelDisplay`     | How to display label/unit             |
| `minHeight`          | `double`               | Minimum height of X-axis area         |
| `maxHeight`          | `double`               | Maximum height of X-axis area         |
| `tickLabelPadding`   | `double`               | Gap between tick and label            |
| `axisLabelPadding`   | `double`               | Gap between labels and title          |
| `axisMargin`         | `double`               | Margin from plot area                 |
| `tickCount`          | `int?`                 | Preferred tick count                  |
| `labelFormatter`     | `XAxisLabelFormatter?` | Custom value formatter                |

**Removed from YAxisConfig** (not applicable):

- `id`: Single axis, no ID needed
- `position`: Always bottom
- `crosshairLabelPosition`: Always below plot area

### 4.3 New X-Axis Painter: `XAxisPainter`

Create/Replace `lib/src/rendering/x_axis_painter.dart`

Based on `MultiAxisPainter` but simplified:

`dart
class XAxisPainter {
XAxisPainter({
required this.config,
required this.axisBounds, // DataRange for X values
this.series, // For color resolution
TextStyle? labelStyle,
});

final XAxisConfig config;
final DataRange axisBounds;
final List<ChartSeries>? series;
final TextStyle labelStyle;

void paint(Canvas canvas, Rect chartArea, Rect plotArea) {
if (!config.visible) return;

    final axisColor = _resolveAxisColor();

    if (config.showAxisLine) {
      _paintAxisLine(canvas, plotArea, axisColor);
    }

    if (config.showTicks || config.shouldShowTickLabels) {
      final ticks = generateTicks(axisBounds);
      _paintTicksAndLabels(canvas, plotArea, ticks, axisColor);
    }

    if (config.shouldShowAxisLabel) {
      _paintAxisLabel(canvas, plotArea, axisColor);
    }

}

// Methods mirror MultiAxisPainter:
// - \_paintAxisLine()
// - \_paintTickMark()
// - \_paintTickLabel()
// - \_paintAxisLabel()
// - generateTicks()
// - formatTickLabel()
// - \_niceNum()
}
`

### 4.4 Updated Crosshair X-Label

Modify `CrosshairRenderer._paintCrosshairLabels()` to:

1. Accept `XAxisConfig` parameter
2. Use themed styling matching Y-axis approach:
   - Semi-transparent background: `axisColor.withValues(alpha: 0.15)`
   - Border: `axisColor.withValues(alpha: 0.6)`
   - Value-only text (remove `X:` prefix)
3. Position correctly below plot area

### 4.5 Integration Points

1. **ChartRenderBox**: Replace `XAxisRenderer` usage with `XAxisPainter`
2. **BravenChartPlus widget**: Accept `XAxisConfig` parameter
3. **ChartTheme**: Ensure X-axis picks up theme defaults
4. **CrosshairRenderer**: Update to use `XAxisConfig` for X-label styling

---

## 5. CRITICAL INTEGRATION REQUIREMENTS

> ⚠️ **LESSON LEARNED**: Previous implementation failed because the renderer was created but never wired into the component. The paint method was a NO-OP stub. This section defines MANDATORY integration requirements that MUST be verified.

### 5.1 The New Renderer MUST Actually Be Used

**REQUIREMENT INT-001**: The `XAxisPainter.paint()` method MUST be called from `ChartRenderBox.paint()` or its delegate methods.

**Verification**:

- Grep for `XAxisPainter` instantiation in `ChartRenderBox`
- Grep for `.paint(` call on the `XAxisPainter` instance
- Visual verification: X-axis renders with themed colors

**Anti-pattern to avoid**:

```dart
// ❌ WRONG: Creating painter but never calling paint()
final xAxisPainter = XAxisPainter(config: config, ...);
// Missing: xAxisPainter.paint(canvas, chartArea, plotArea);
```

**Correct pattern**:

```dart
// ✅ CORRECT: Create AND call paint()
final xAxisPainter = XAxisPainter(config: _xAxisConfig, ...);
xAxisPainter.paint(canvas, chartArea, plotArea);
```

### 5.2 Old Renderer MUST Be Removed/Bypassed

**REQUIREMENT INT-002**: The old `XAxisRenderer` MUST NOT be called for X-axis rendering once the new painter is integrated.

**Verification**:

- Search for `XAxisRenderer` usage in `ChartRenderBox` - should be removed or commented out
- The new `XAxisPainter` is the ONLY code path for X-axis rendering

### 5.3 XAxisConfig MUST Flow Through Widget Tree

**REQUIREMENT INT-003**: `XAxisConfig` must be accepted by `BravenChartPlus` widget and passed down to `ChartRenderBox`.

**Widget tree flow**:

```
BravenChartPlus(xAxisConfig: config)
    └─> _BravenChartPlusState
        └─> ChartRenderBox(xAxisConfig: config)
            └─> XAxisPainter(config: config)
                └─> paint() uses config properties
```

### 5.4 ChartTheme MUST Be Default, XAxisConfig Overrides

**REQUIREMENT INT-004**: When `XAxisConfig` properties are null, values MUST fall back to `ChartTheme`. When `XAxisConfig` properties are set, they MUST override theme defaults.

**Resolution order** (highest priority first):

1. `XAxisConfig.color` (if explicitly set)
2. First series color (if XAxisConfig.color is null)
3. `ChartTheme.axisStyle.lineColor` (fallback)
4. Hardcoded default `Color(0xFF666666)` (last resort)

**Verification**:

- Test with no XAxisConfig → uses theme/series color
- Test with XAxisConfig(color: Colors.red) → uses red

### 5.5 ALL XAxisConfig Properties MUST Affect Rendering

**REQUIREMENT INT-005**: Every property on `XAxisConfig` MUST be wired into the renderer and MUST affect the visual output when changed.

| Property             | Must Affect                                                      |
| -------------------- | ---------------------------------------------------------------- |
| `color`              | Axis line color, tick color, label color, crosshair label border |
| `label`              | Axis title text rendered below ticks                             |
| `unit`               | Appended to label and/or ticks per `labelDisplay`                |
| `visible`            | When false, entire X-axis is not rendered                        |
| `showAxisLine`       | When false, horizontal axis line is not drawn                    |
| `showTicks`          | When false, tick marks are not drawn                             |
| `showCrosshairLabel` | When false, crosshair X-value label is not shown                 |
| `labelDisplay`       | Controls label/unit display mode                                 |
| `minHeight`          | Minimum height reserved for X-axis area                          |
| `maxHeight`          | Maximum height for X-axis area                                   |
| `tickLabelPadding`   | Gap between tick marks and tick labels                           |
| `axisLabelPadding`   | Gap between tick labels and axis title                           |
| `axisMargin`         | Margin between plot area and axis                                |
| `tickCount`          | Number of ticks generated                                        |
| `labelFormatter`     | Custom formatting of tick values                                 |
| `min`                | Explicit minimum X value (overrides data)                        |
| `max`                | Explicit maximum X value (overrides data)                        |

**Verification**: Unit tests for EACH property showing before/after behavior.

### 5.6 Crosshair X-Label MUST Use XAxisConfig

**REQUIREMENT INT-006**: The crosshair X-value label MUST use `XAxisConfig` for:

- Color (semi-transparent background tinted with axis color)
- Visibility (`showCrosshairLabel` controls whether it appears)
- Formatting (`labelFormatter` if provided)

**Verification**:

- Set `XAxisConfig(color: Colors.blue)` → crosshair label has blue-tinted background
- Set `XAxisConfig(showCrosshairLabel: false)` → no X-value label on crosshair

### 5.7 No Dead Code / Stub Methods

**REQUIREMENT INT-007**: The `XAxisPainter.paint()` method MUST NOT be a stub/no-op. It MUST contain actual drawing code that calls `canvas.drawLine()`, `canvas.drawRRect()`, `TextPainter.paint()`, etc.

**Verification**:

- `paint()` method contains `canvas.drawLine()` for axis line
- `paint()` method contains `canvas.drawLine()` for tick marks
- `paint()` method contains `TextPainter.paint()` for tick labels
- `paint()` method contains `TextPainter.paint()` for axis title

---

## 6. Implementation Tasks

### Phase 1: Configuration

1. Create `XAxisConfig` class (modeled on YAxisConfig)
2. Add `xAxisConfig` parameter to chart widget
3. Create `XAxisLabelFormatter` typedef

### Phase 2: Painter

4. Create new `XAxisPainter` class (modeled on MultiAxisPainter)
5. Implement axis line painting with theming
6. Implement tick mark painting with theming
7. Implement tick label painting with theming
8. Implement axis title label painting
9. Implement nice-number tick generation
10. Implement TextPainter caching

### Phase 3: Crosshair Integration

11. Update `CrosshairRenderer` to accept `XAxisConfig`
12. Implement themed X-value label rendering
13. Remove `X:` prefix from value display

### Phase 4: Integration (CRITICAL - Previous Failure Point)

14. **Wire XAxisConfig into BravenChartPlus widget parameter**
15. **Pass XAxisConfig from widget to ChartRenderBox**
16. **Instantiate XAxisPainter in ChartRenderBox with config**
17. **CALL XAxisPainter.paint() from ChartRenderBox.paint()**
18. **Remove/disable old XAxisRenderer calls**
19. **Pass XAxisConfig to CrosshairRenderer for X-label theming**

### Phase 5: Testing & Polish

20. Unit tests for `XAxisConfig`
21. Unit tests for `XAxisPainter`
22. Integration tests verifying wiring (INT-001 through INT-007)
23. Widget tests for full integration
24. Visual verification demo

---

## 7. API Changes

### 6.1 New Classes

`dart
// lib/src/models/x_axis_config.dart
class XAxisConfig { ... }

// lib/src/rendering/x_axis_painter.dart
class XAxisPainter { ... }
`

### 6.2 Modified Signatures

`dart
// BravenChartPlus widget
BravenChartPlus({
// ... existing params
XAxisConfig? xAxisConfig, // NEW
})

// CrosshairRenderer (internal)
void \_paintCrosshairLabels({
// ... existing params
XAxisConfig? xAxisConfig, // NEW
})
`

### 6.3 Deprecated/Removed

`dart
// Will be deprecated/removed:
// - lib/src/axis/x_axis_renderer.dart (XAxisRenderer class)
// - Related old AxisConfig X-axis properties
`

---

## 8. Property Mapping Reference

### YAxisConfig → XAxisConfig Mapping

| YAxisConfig Property     | XAxisConfig Property | Notes                     |
| ------------------------ | -------------------- | ------------------------- |
| `id`                     | (none)               | Single axis, no ID needed |
| `position`               | (none)               | Always bottom             |
| `color`                  | `color`              | Same                      |
| `label`                  | `label`              | Same                      |
| `unit`                   | `unit`               | Same                      |
| `min`                    | `min`                | Same                      |
| `max`                    | `max`                | Same                      |
| `visible`                | `visible`            | Same                      |
| `showAxisLine`           | `showAxisLine`       | Same                      |
| `showTicks`              | `showTicks`          | Same                      |
| `showCrosshairLabel`     | `showCrosshairLabel` | Same                      |
| `crosshairLabelPosition` | (none)               | Always below plot         |
| `labelDisplay`           | `labelDisplay`       | Same                      |
| `minWidth`               | `minHeight`          | Renamed (horizontal axis) |
| `maxWidth`               | `maxHeight`          | Renamed (horizontal axis) |
| `tickLabelPadding`       | `tickLabelPadding`   | Same                      |
| `axisLabelPadding`       | `axisLabelPadding`   | Same                      |
| `axisMargin`             | `axisMargin`         | Same                      |
| `tickCount`              | `tickCount`          | Same                      |
| `labelFormatter`         | `labelFormatter`     | Same                      |

---

## 9. Visual Specification

### Before (Current State)

`+---------------------------+
|     Y-AXIS    | PLOT AREA |
| [Green ticks] |  [Chart]  |
| [Green label] |           |
|   48421.32    |     •     |  ← Green themed crosshair label
+---------------------------+
|  1   2   3   [X: 1.8]     |  ← Plain black ticks, white box
+---------------------------+`

### After (Target State)

`+---------------------------+
|     Y-AXIS    | PLOT AREA |
| [Green ticks] |  [Chart]  |
| [Green label] |           |
|   48421.32    |     •     |  ← Green themed crosshair label
+---------------------------+
| [Grn] 1   2   3           |  ← Green themed ticks
|      [1.8]                |  ← Green themed crosshair label
+---------------------------+`

Both axes will have:

- Coordinated theme colors
- Same label box styling (semi-transparent bg, colored border)
- Clean value-only display (no axis prefix)

---

## 10. Success Criteria

### Functional Criteria

1. **Visual Parity**: X-axis visually matches Y-axis styling
2. **Theming Works**: X-axis color derived from configuration or series
3. **Clean Labels**: Crosshair X-label shows value only (no `X:` prefix)
4. **Styled Box**: X-label uses semi-transparent themed background
5. **All Tests Pass**: No regressions in existing functionality
6. **No Multi-Axis Complexity**: Single X-axis only, simple API

### CRITICAL Integration Criteria (Must Verify)

7. **INT-001 VERIFIED**: `XAxisPainter.paint()` is CALLED from `ChartRenderBox`
8. **INT-002 VERIFIED**: Old `XAxisRenderer` is NOT used for rendering
9. **INT-003 VERIFIED**: `XAxisConfig` flows from widget → render box → painter
10. **INT-004 VERIFIED**: Theme defaults work when `XAxisConfig` properties are null
11. **INT-005 VERIFIED**: ALL `XAxisConfig` properties affect rendering when set
12. **INT-006 VERIFIED**: Crosshair X-label uses `XAxisConfig` for theming
13. **INT-007 VERIFIED**: `XAxisPainter.paint()` contains actual draw calls (not a stub)

---

## 11. Design Decisions (Resolved)

### Decision 1: Default X-Axis Color

**Question**: If no explicit `color` is specified in `XAxisConfig`, what should the X-axis default to?

**Decision**: **Use first series color** (consistent with Y-axis behavior)

**Rationale**: Maintains API consistency with Y-axis. The first series color provides a reasonable default that integrates with the chart's visual theme.

---

### Decision 2: X-Axis Title Label Orientation

**Question**: The Y-axis title is rotated 90°. What orientation should the X-axis title use?

**Decision**: **Horizontal, centered below tick labels**

**Rationale**: Standard chart convention. X-axis has horizontal space available, so rotation is unnecessary. Layout:

```
───1───2───3───
     Time (s)
```

---

### Decision 3: Grid Line Ownership

**Question**: Should `XAxisPainter` also handle vertical grid lines?

**Decision**: **Keep grid lines separate** (out of scope for this sprint)

**Rationale**: Maintains separation of concerns and avoids breaking changes. Grid theming can be addressed in a future sprint if needed.

---

## 12. References

- `lib/src/models/y_axis_config.dart` - Reference configuration class
- `lib/src/rendering/multi_axis_painter.dart` - Reference painter implementation
- `lib/src/rendering/modules/crosshair_renderer.dart` - Crosshair label rendering
- `lib/src/axis/x_axis_renderer.dart` - Current (legacy) X-axis renderer

---

**Document Status**: Approved - Ready for Spec Generation
