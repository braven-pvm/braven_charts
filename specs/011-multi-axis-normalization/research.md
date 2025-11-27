# Research: Multi-Axis Normalization

**Feature**: 011-multi-axis-normalization  
**Date**: 2025-11-27  
**Status**: Complete

---

## Research Tasks

### RT-001: Series-to-Axis Binding Syntax

**Question**: How should series be bound to specific Y-axes?

**Options Evaluated**:

| Option | Approach | Pros | Cons |
|--------|----------|------|------|
| A | `yAxisId` on series, separate `yAxes` list on chart | Clean separation, reusable axes | Two places to configure |
| B | Inline `YAxisConfig` on each series | Self-contained series | Duplicate config if shared |
| C | Grouped series configuration | Logical grouping | Breaking API change |

**Decision**: **Option A** - `yAxisId` on series with separate `yAxes` configuration list

**Rationale**:
1. Follows existing Flutter patterns (e.g., `heroTag` references)
2. Enables axis reuse across multiple series
3. Backward compatible - `yAxisId: null` uses default axis
4. Clear separation of concerns (series data vs. axis presentation)

**Integration Point**: Add optional `yAxisId` field to `ChartSeries` base class in `lib/src_plus/models/chart_series.dart`

---

### RT-002: Default Axis Assignment

**Question**: What happens when a series doesn't specify `yAxisId`?

**Options Evaluated**:

| Option | Behavior | Pros | Cons |
|--------|----------|------|------|
| A | Use primary axis (left) | Backward compatible | May crowd primary axis |
| B | Auto-assign to next available | Spreads series out | Unpredictable behavior |
| C | Error if multi-axis mode forced | Explicit | Poor DX |

**Decision**: **Option A** - Default to primary (left) axis

**Rationale**:
1. 100% backward compatible with existing charts
2. Matches user mental model (main data on main axis)
3. Explicit binding only needed for secondary axes
4. Follows principle of least surprise

**Implementation**: `ChartSeries.yAxisId` defaults to `null`, which resolves to primary axis ID during rendering

---

### RT-003: Axis Spacing Algorithm

**Question**: How much horizontal space should each Y-axis consume?

**Options Evaluated**:

| Option | Approach | Pros | Cons |
|--------|----------|------|------|
| A | Fixed width (e.g., 60px) | Simple, predictable | May clip long labels |
| B | Dynamic based on label width | Optimal fit | Layout instability |
| C | Configurable with min/max | Flexible | More API surface |

**Decision**: **Option B with C fallback** - Dynamic width with configurable min/max

**Rationale**:
1. Dynamic sizing ensures labels never clip
2. Min/max bounds prevent extreme layouts
3. Defaults work for 95% of cases (min: 40px, max: 80px)
4. Power users can override for special cases

**Implementation**:
```dart
class YAxisConfig {
  final double minWidth;  // Default: 40.0
  final double maxWidth;  // Default: 80.0
  // Actual width computed from max label width within bounds
}
```

---

### RT-004: Legend Enhancement

**Question**: Should the legend show per-series Y-range information?

**Options Evaluated**:

| Option | Display | Pros | Cons |
|--------|---------|------|------|
| A | Color + name only (current) | Clean, simple | No range info |
| B | Color + name + range | Informative | Visual clutter |
| C | Color + name + current value | Interactive feel | Complex implementation |

**Decision**: **Option A** - Keep legend simple (color + name only)

**Rationale**:
1. Color-coded axes already convey which axis belongs to which series
2. Range info is visible on the axis itself
3. Current value shown in crosshair/tooltip
4. KISS principle - avoid UI clutter
5. Can be added as future enhancement if users request

---

### RT-005: Coordinate Transformation Integration

**Question**: How does multi-axis normalization integrate with `UniversalCoordinateTransformer`?

**Research Findings**:

The current `TransformContext` has a **single** `yDataRange` field:
```dart
// From lib/src/coordinates/transform_context.dart
final DataRange yDataRange;
```

**Challenge**: Multi-axis requires per-series Y data ranges for normalization.

**Solution Options**:

| Option | Approach | Impact |
|--------|----------|--------|
| A | Add `Map<String, DataRange> yDataRanges` to TransformContext | Moderate - new field |
| B | Create per-series transform context | High - major refactor |
| C | Normalize at rendering layer, not transform layer | Low - isolated change |

**Decision**: **Option C** - Normalize at rendering layer

**Rationale**:
1. Keeps `TransformContext` unchanged (no regression risk)
2. Rendering already knows series → axis binding
3. Normalization is purely visual, not coordinate-system level
4. Crosshair/tooltip already access original data values

**Implementation**:
- Renderer receives `Map<String, YAxisConfig>` with per-axis bounds
- Renderer normalizes each series Y values to [0,1] using its axis bounds
- Renderer then maps [0,1] to chart area pixels using existing transform
- Original values preserved in series data for tooltip/crosshair display

---

### RT-006: Auto-Detection Algorithm

**Question**: How should the system detect when multi-axis mode is needed?

**Algorithm Design**:

```
1. Compute Y range (min, max) for each series
2. Find global max range span: maxSpan = max(seriesMax - seriesMin)
3. Find global min range span: minSpan = min(seriesMax - seriesMin)
4. If maxSpan / minSpan > threshold (default: 10):
   → Recommend multi-axis mode
5. If series units differ (e.g., "W" vs "bpm"):
   → Recommend multi-axis mode
```

**Decision**: Implement range-ratio detection with configurable threshold

**Rationale**:
1. 10x ratio catches most cases (e.g., 0-300W vs 0.5-4L is 75x)
2. Unit detection is optional enhancement (future phase)
3. Auto-detection is a *suggestion*, explicit config always wins

---

### RT-007: Grid Lines Behavior

**Question**: How should grid lines behave in multi-axis mode?

**Research**: Multiple grid line sets would create visual confusion - which axis do they belong to?

**Decision**: Disable grid lines when >1 Y-axis is active

**Rationale**:
1. Avoids ambiguity about which axis grid lines reference
2. Matches reference implementation (VO2master has no grid in multi-axis)
3. Plot area remains clean for data focus
4. Can add "primary axis grid only" as future enhancement

**Implementation**: `AxisConfig.showGrid` is overridden to `false` when `yAxes.length > 1`

---

### RT-008: Zoom/Pan Behavior in Multi-Axis Mode

**Question**: How should zoom and pan behave when multiple Y-axes are active?

**Research Findings**:

The current `TransformContext` uses a **single** `yDataRange` for zoom calculations:
```dart
// From lib/src/coordinates/transform_context.dart
final DataRange yDataRange;
```

When zooming occurs, `ViewportState.yRange` is updated as a single global range. Multi-axis would require per-axis Y ranges for proper independent Y-zoom.

**Challenge**: The coordinate transformation system was designed for single Y-axis. Supporting independent Y-zoom per axis would require:
1. `Map<String, DataRange>` for per-axis Y ranges
2. New gesture handling to determine which axis to zoom
3. Major refactor of `UniversalCoordinateTransformer`

**Options Evaluated**:

| Option | Approach | Complexity | UX |
|--------|----------|------------|-----|
| A | Independent Y-axis zoom | Very High | Complex - user must target specific axis |
| B | X-axis zoom only in multi-axis mode | Low | Intuitive - all series zoom together horizontally |
| C | Proportional Y-zoom (all axes zoom equally) | Medium | May not make sense for different scales |

**Decision**: **Option B** - X-axis zoom only when multi-axis mode is active

**Rationale**:
1. Avoids major refactor of coordinate transformation system
2. X-zoom is the most common use case (scrubbing time series)
3. Y-zoom on multi-axis is ambiguous (which axis to zoom?)
4. All series show full Y range - consistent behavior
5. Matches reference implementations (VO2master uses X-only zoom)

**Implementation**:
- When `yAxes.length > 1` or `normalizationMode == perSeries`:
  - Y-axis zoom gestures are ignored
  - Y-axis pan gestures are ignored
  - X-axis zoom/pan works normally
- Constraint enforced in `ZoomController` or `PanHandler`

**FR Reference**: FR-013 in spec.md

---

## Integration Points Summary

| Component | File | Change Type |
|-----------|------|-------------|
| ChartSeries | `lib/src_plus/models/chart_series.dart` | Add `yAxisId`, `unit` fields |
| YAxisConfig | `lib/src_plus/axis/y_axis_config.dart` | NEW - Y-axis configuration class |
| YAxisPosition | `lib/src_plus/models/enums.dart` | NEW - leftOuter/left/right/rightOuter enum |
| NormalizationMode | `lib/src_plus/models/enums.dart` | NEW - none/auto/perSeries enum |
| AxisRenderer | `lib/src_plus/rendering/axis_renderer.dart` | Modify for multi-axis layout |
| SeriesRenderer | `lib/src_plus/rendering/series_renderer.dart` | Add per-axis normalization |
| BravenChartPlus | `lib/src_plus/widgets/braven_chart_plus.dart` | Add `yAxes` configuration |

---

## Open Questions Resolved

| ID | Question | Resolution |
|----|----------|------------|
| OQ-001 | Series-to-Axis Binding Syntax | Option A: `yAxisId` + separate `yAxes` list |
| OQ-002 | Default Axis Assignment | Option A: Default to primary (left) axis |
| OQ-003 | Axis Spacing Algorithm | Dynamic with min/max bounds |
| OQ-004 | Legend Enhancement | Keep simple (color + name only) |
| OQ-005 | Zoom/Pan in Multi-Axis Mode | Option B: X-axis zoom only, Y-zoom disabled |

---

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Performance regression with 4 axes | Low | Medium | Benchmark early, profile normalization |
| Breaking existing single-axis charts | Low | High | Extensive backward compatibility tests |
| Tooltip/crosshair value confusion | Medium | Medium | Clear unit display, consistent formatting |
| Axis label overlap | Medium | Low | Dynamic spacing, configurable min/max width |

---

*Research Complete: 2025-11-27*
