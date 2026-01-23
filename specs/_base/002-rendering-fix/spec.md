# 002-rendering-fix: Multi-Series Rendering Improvements

## Overview

**Status**: Draft  
**Priority**: High  
**Estimated Effort**: 14-21 hours  
**Created**: 2026-01-23

This sprint addresses two critical rendering issues discovered when using multiple series with different Y-axes:

1. **Grouped Bar Charts**: Multiple bar series overlay instead of rendering adjacent
2. **perSeries Y-Zoom**: Vertical zoom doesn't work with `NormalizationMode.perSeries` + multi-axis

---

## Current Architecture (MUST PRESERVE)

This section documents the existing rendering architecture. **All changes MUST work within this architecture to maintain performance and stability.**

### Core Design Principles (Constitution)

1. **PERFORMANCE FIRST**: 60fps with 1000+ points is non-negotiable
2. **GPU-Accelerated Caching**: Static series rendered to `ui.Picture`, reused during hover/pan
3. **Layer Separation**: Series layer (cached) vs Overlay layer (dynamic)
4. **Immutable Transforms**: All viewport changes create new `ChartTransform` instances
5. **Spatial Indexing**: O(log n) hit testing via QuadTree

### Rendering Pipeline

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           RENDERING PIPELINE                                │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  1. ELEMENT GENERATION (on data/transform change only)                     │
│     ┌──────────────────┐    ┌─────────────────┐    ┌──────────────────┐    │
│     │ ElementGenerator │ -> │ SeriesElement[] │ -> │ QuadTree Index   │    │
│     │ (from widget)    │    │ (plot space)    │    │ (spatial query)  │    │
│     └──────────────────┘    └─────────────────┘    └──────────────────┘    │
│                                                                             │
│  2. SERIES LAYER (Layer 1 - CACHED in ui.Picture)                          │
│     ┌──────────────────┐    ┌─────────────────┐    ┌──────────────────┐    │
│     │ SeriesCacheManager│ -> │ generatePicture │ -> │ GPU-Cached       │    │
│     │ (dirty tracking) │    │ (paint series)  │    │ Picture          │    │
│     └──────────────────┘    └─────────────────┘    └──────────────────┘    │
│                                      │                                      │
│     INVALIDATION TRIGGERS:           │ CACHE SURVIVES:                      │
│     - Data change                    │ - Hover events                       │
│     - Transform change (zoom/pan)    │ - Box selection drag                 │
│     - Theme change                   │ - Annotation drag                    │
│                                                                             │
│  3. OVERLAY LAYER (Layer 2 - FRESH every frame)                            │
│     ┌──────────────────┐    ┌─────────────────┐                            │
│     │ Crosshair        │    │ Selection boxes │                            │
│     │ Tooltip          │    │ Preview markers │                            │
│     │ Scrollbars       │    │ Annotations     │                            │
│     └──────────────────┘    └─────────────────┘                            │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Key Classes and Responsibilities

| Class | File | Responsibility |
|-------|------|----------------|
| `ChartRenderBox` | `lib/src/rendering/chart_render_box.dart` | Main RenderBox, orchestrates all rendering |
| `SeriesElement` | `lib/src/elements/series_element.dart` | Wraps ChartSeries for rendering/hit testing |
| `ChartTransform` | `lib/src/coordinates/chart_transform.dart` | Immutable Data↔Plot coordinate transform |
| `MultiAxisManager` | `lib/src/rendering/modules/multi_axis_manager.dart` | Multi-axis config, bounds, normalization |
| `SeriesCacheManager` | `lib/src/rendering/modules/series_cache_manager.dart` | GPU Picture caching for series layer |
| `ScrollbarManager` | `lib/src/rendering/modules/scrollbar_manager.dart` | Scrollbar state, zoom/pan via scrollbars |
| `EventHandlerManager` | `lib/src/rendering/modules/event_handler_manager.dart` | Pointer events, zoom/pan gestures |

### Coordinate Spaces

```
┌─────────────────────────────────────────────────────────────────┐
│                     COORDINATE SPACES                           │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  DATA SPACE            →  PLOT SPACE           →  WIDGET SPACE  │
│  (logical values)         (pixels in chart)       (full widget) │
│                                                                 │
│  Example:                 Example:                Example:      │
│  x: 1609459200 (time)     x: 0 - 730 px          x: 60 - 790 px │
│  y: 100-200 (price)       y: 0 - 540 px          y: 10 - 550 px │
│                                                                 │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │ ChartTransform handles DATA ↔ PLOT conversions:         │   │
│  │   dataToPlot(x, y) → Offset (for rendering)             │   │
│  │   plotToData(px, py) → Offset (for hit testing)         │   │
│  └──────────────────────────────────────────────────────────┘   │
│                                                                 │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │ Plot area offset handles PLOT ↔ WIDGET conversions:     │   │
│  │   plotToWidget(offset) = offset + _plotArea.topLeft     │   │
│  │   widgetToPlot(offset) = offset - _plotArea.topLeft     │   │
│  └──────────────────────────────────────────────────────────┘   │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### Multi-Axis Normalization Flow (NormalizationMode.perSeries)

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                    MULTI-AXIS NORMALIZATION FLOW                            │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  1. SERIES DATA (different Y ranges)                                       │
│     Series A: y=[0-600]s (time)                                            │
│     Series B: y=[0-15]kJ (work)                                            │
│                                                                             │
│  2. AXIS BOUNDS COMPUTATION (MultiAxisManager.computeAxisBounds)            │
│     ┌───────────────────────────────────────────────────────────┐          │
│     │ For each axis: find min/max Y from bound series          │          │
│     │ Add 5% padding buffer                                     │          │
│     │ Returns: { "axis_A": [0-630], "axis_B": [0-15.75] }      │          │
│     └───────────────────────────────────────────────────────────┘          │
│                                                                             │
│  3. PER-SERIES TRANSFORM (ChartRenderBox._paintSeriesLayerContent)         │
│     ┌───────────────────────────────────────────────────────────┐          │
│     │ For Series A: transform.copyWith(dataYMin: 0, dataYMax: 630)         │
│     │ For Series B: transform.copyWith(dataYMin: 0, dataYMax: 15.75)       │
│     │                                                                       │
│     │ RESULT: Each series normalized to fill 0-plotHeight                  │
│     │         Different data ranges → same visual space                    │
│     └───────────────────────────────────────────────────────────┘          │
│                                                                             │
│  4. RENDERING: All series paint in same visual space (0 to plotHeight)     │
│                                                                             │
│  ⚠️  CURRENT ISSUE: Zoom modifies global transform, but per-series         │
│      transforms use forceFullBounds=true, ignoring zoom.                   │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Zoom/Pan Transform Flow

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                        ZOOM/PAN TRANSFORM FLOW                              │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  USER ACTION                                                                │
│      ↓                                                                      │
│  EventHandlerManager._handlePointerScroll() [mouse wheel]                  │
│  ScrollbarManager.handleScrollbarDrag() [scrollbar edge]                   │
│      ↓                                                                      │
│  ChartRenderBox.zoomChart(factor, plotCenter)                              │
│      ↓                                                                      │
│  ┌──────────────────────────────────────────────────────────────┐          │
│  │ ChartTransform.zoom(factor, plotCenter)                      │          │
│  │   - Converts plotCenter to data space                        │          │
│  │   - Calculates new data ranges (shrink/grow by factor)       │          │
│  │   - Returns NEW ChartTransform with zoomed viewport          │          │
│  └──────────────────────────────────────────────────────────────┘          │
│      ↓                                                                      │
│  ViewportConstraints.clampZoomLevel(transform)                             │
│      ↓                                                                      │
│  _transform = zoomedTransform                                              │
│  _updateAxesFromTransform()  → Y-axis labels update                        │
│  _seriesCacheManager.invalidate()                                          │
│  markNeedsPaint()                                                          │
│      ↓                                                                      │
│  paint() → _paintSeriesLayerContent() → series.updateTransform()           │
│                                                                             │
│  ⚠️  CURRENT ISSUE (perSeries mode):                                       │
│      _transform.dataYMin/Max are modified by zoom                          │
│      BUT computeAxisBounds(forceFullBounds: true) ignores them             │
│      → Per-series transforms receive FULL bounds, not zoomed bounds        │
│      → Visual zoom doesn't happen                                          │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Series Element Painting

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                     SERIES ELEMENT PAINTING                                 │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  SeriesElement.paint(canvas, size)                                         │
│      ↓                                                                      │
│  switch (series.runtimeType) {                                             │
│    LineChartSeries  → _paintLineSeries()                                   │
│    BarChartSeries   → _paintBarSeries()    ← ISSUE 1 HERE                  │
│    ScatterChartSeries → _paintScatterSeries()                              │
│    AreaChartSeries  → _paintAreaSeries()                                   │
│  }                                                                          │
│                                                                             │
│  _paintBarSeries() CURRENT LOGIC:                                          │
│  ┌──────────────────────────────────────────────────────────────┐          │
│  │ for (point in series.points):                                │          │
│  │   plotPos = transform.dataToPlot(point.x, point.y)          │          │
│  │   rect = Rect centered at plotPos.dx, width = barWidth      │          │
│  │   canvas.drawRect(rect)                                      │          │
│  │                                                              │          │
│  │ ⚠️ PROBLEM: No awareness of OTHER bar series at same X      │          │
│  │    All bars centered at exact same X position = OVERLAP     │          │
│  └──────────────────────────────────────────────────────────────┘          │
│                                                                             │
│  REQUIRED FIX:                                                              │
│  ┌──────────────────────────────────────────────────────────────┐          │
│  │ Know: barGroupInfo.index (0, 1, 2...) and barGroupInfo.count │          │
│  │ Calculate: xOffset = offset for this bar within group       │          │
│  │ Apply: rect centered at (plotPos.dx + xOffset)              │          │
│  └──────────────────────────────────────────────────────────────┘          │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Performance-Critical Paths (DO NOT REGRESS)

| Path | Target | Current | Notes |
|------|--------|---------|-------|
| Hover response | <16ms (60fps) | ~2ms | Cached Picture reuse |
| Series paint (5×1000 pts) | <17ms | ~15ms | Path caching |
| Zoom animation | 60fps | 60fps | Incremental cache invalidate |
| Hit testing | O(log n) | O(log n) | QuadTree spatial index |

### Files We Will Modify

| File | Changes | Risk |
|------|---------|------|
| `lib/src/elements/series_element.dart` | Add BarGroupInfo, modify `_paintBarSeries()` | LOW - isolated change |
| `lib/src/models/bar_group_info.dart` | NEW FILE - BarGroupInfo class | NONE - new file |
| `lib/src/rendering/modules/multi_axis_manager.dart` | Add `forPainting` param to computeAxisBounds | MEDIUM - core logic |
| `lib/src/rendering/chart_render_box.dart` | Pass BarGroupInfo, use forPainting bounds | MEDIUM - orchestration |
| `lib/src/braven_chart_plus.dart` | Compute bar series index/count during element gen | LOW - minor addition |

---

## Problem Statement

### Issue 1: Bar Series Overlapping

**Observed Behavior**:  
When multiple `BarChartSeries` share the same X-values, all bars render directly on top of each other at the exact same X position. Only the last-painted series is visible.

**Expected Behavior**:  
Bars should render side-by-side (grouped) for each X-value, similar to Excel/Sheets grouped bar charts.

**Root Cause**:  
`SeriesElement._paintBarSeries()` paints each series independently without knowledge of:

- Total count of bar series at each X-value
- Current series index among bar series
- Group width allocation

**Affected Code**:

- `lib/src/elements/series_element.dart` (lines 967-1008)

### Issue 2: Y-Axis Zoom Locked in perSeries Mode

**Observed Behavior**:  
With `NormalizationMode.perSeries` and multiple Y-axes configured:

- Horizontal (X-axis) zoom works correctly
- Vertical (Y-axis) zoom appears locked - scrollbar updates but chart data doesn't scale
- Y-axis labels update correctly during scroll/pan but not zoom

**Expected Behavior**:  
Vertical zoom should scale the visible data range proportionally for all series.

**Root Cause**:  
In perSeries mode, Y-values are normalized to 0-1 range. The zoom transform modifies this normalized range, but:

1. Axis bounds are computed with `forceFullBounds: true` for painting
2. Per-series transforms receive full axis bounds, not zoomed bounds
3. Disconnect between what transform represents and what's rendered

**Affected Code**:

- `lib/src/rendering/modules/multi_axis_manager.dart` (computeAxisBounds)
- `lib/src/rendering/chart_render_box.dart` (\_paintSeries, perSeriesTransform)
- `lib/src/coordinates/chart_transform.dart` (zoom method)

---

## Requirements

### FR-001: Grouped Bar Chart Rendering

**Description**: When multiple BarChartSeries exist with overlapping X-values, bars must render adjacent to each other within a group.

**Acceptance Criteria**:

- [ ] Bars at same X-value render side-by-side, not overlapping
- [ ] Group width is calculated based on bar count at each X
- [ ] Individual bar width scales proportionally to fit group
- [ ] Configurable gap between bars within a group
- [ ] Works with 2-10 bar series without visual degradation
- [ ] Maintains existing single-bar-series behavior

### FR-002: perSeries Y-Axis Zoom

**Description**: Vertical zoom must work correctly when using `NormalizationMode.perSeries` with multiple Y-axes.

**Acceptance Criteria**:

- [ ] Mouse wheel zoom affects both X and Y axes
- [ ] Scrollbar edge drag zoom works for Y-axis
- [ ] Zoomed viewport clips/scales data correctly
- [ ] Y-axis labels reflect zoomed range
- [ ] Zoom center point is preserved (zoom toward cursor)
- [ ] Works with 2+ Y-axes configured

### NFR-001: Performance

**Description**: Changes must not degrade rendering performance.

**Acceptance Criteria**:

- [ ] No additional allocations per frame during pan/zoom
- [ ] Bar grouping calculation is O(n) where n = series count
- [ ] No regression in 60fps target for 1000+ points

---

## Technical Design

### Design Option A: Grouped Bars via SeriesElement Context

**Approach**: Pass bar series metadata (index, count) to SeriesElement during construction.

```dart
// In ChartRenderBox or element generator
final barSeriesCount = series.whereType<BarChartSeries>().length;
var barSeriesIndex = 0;

for (final s in series) {
  if (s is BarChartSeries) {
    elements.add(SeriesElement(
      series: s,
      barGroupInfo: BarGroupInfo(
        index: barSeriesIndex++,
        count: barSeriesCount,
        groupGap: 2.0,  // pixels between bars
      ),
    ));
  }
}
```

**Pros**: Clean separation, no global state  
**Cons**: Requires element regeneration if bar count changes

### Design Option B: Grouped Bars via Shared BarPositioner

**Approach**: Create a `BarPositioner` (like legacy) that calculates all bar positions upfront.

```dart
class BarPositioner {
  final List<BarChartSeries> barSeries;
  final double groupGapPixels;

  Map<String, List<BarLayout>> computeLayouts(ChartTransform transform);
}
```

**Pros**: Matches legacy architecture, supports stacked bars later  
**Cons**: Additional class, coordination overhead

### Design Option C: Y-Zoom Fix via Viewport-Aware Axis Bounds

**Approach**: Modify `computeAxisBounds()` to respect viewport zoom for painting transforms.

```dart
// In MultiAxisManager.computeAxisBounds()
Map<String, DataRange> computeAxisBounds({
  ChartTransform? transform,
  ChartTransform? originalTransform,
  bool forceFullBounds = false,
  bool forPainting = false,  // NEW: use zoomed bounds for series rendering
}) {
  // When forPainting=true AND viewport is zoomed:
  // Return bounds that match the visible portion of data
}
```

**Pros**: Minimal API change, centralized fix  
**Cons**: Adds complexity to already complex method

### Design Option D: Y-Zoom Fix via Transform Denormalization

**Approach**: Apply zoom to denormalized data bounds before creating per-series transform.

```dart
// In ChartRenderBox._paintSeries()
if (axisBounds != null && seriesToAxisMap != null) {
  final axisId = seriesToAxisMap[series.id];
  if (axisId != null && axisBounds.containsKey(axisId)) {
    final fullRange = axisBounds[axisId]!;

    // Apply viewport zoom to axis bounds
    final zoomedRange = _applyViewportZoom(fullRange, _transform!, _originalTransform!);

    final perSeriesTransform = _transform!.copyWith(
      dataYMin: zoomedRange.min,
      dataYMax: zoomedRange.max,
    );
    series.updateTransform(perSeriesTransform);
  }
}
```

**Pros**: Fix at source, clear intent  
**Cons**: Duplicates zoom logic

---

## Proposed Solution

### For Issue 1 (Grouped Bars): Design Option A

Rationale:

- Minimal architectural change
- No new classes required
- Natural fit with existing element-based rendering

### For Issue 2 (Y-Zoom): Design Option C + D Hybrid

Rationale:

- Option C provides the foundation (viewport-aware bounds)
- Option D applies it correctly during painting
- Combined approach ensures consistency

---

## Tasks

### Phase 1: Grouped Bar Charts

| Task         | Description                                                    | Hours   |
| ------------ | -------------------------------------------------------------- | ------- |
| 1.1          | Add `BarGroupInfo` class with index, count, gap properties     | 0.5     |
| 1.2          | Update `SeriesElement` to accept and store `BarGroupInfo`      | 0.5     |
| 1.3          | Modify `_paintBarSeries()` to calculate offset from group info | 2.0     |
| 1.4          | Update element generator to compute bar series metadata        | 1.0     |
| 1.5          | Add unit tests for grouped bar positioning                     | 1.0     |
| 1.6          | Update FitDistributionPage demo to verify fix                  | 0.5     |
| **Subtotal** |                                                                | **5.5** |

### Phase 2: perSeries Y-Zoom Fix

| Task         | Description                                              | Hours   |
| ------------ | -------------------------------------------------------- | ------- |
| 2.1          | Add `forPainting` parameter to `computeAxisBounds()`     | 1.0     |
| 2.2          | Implement viewport-aware bounds calculation for painting | 3.0     |
| 2.3          | Update `_paintSeries()` to use painting-aware bounds     | 1.5     |
| 2.4          | Ensure crosshair/tooltip use correct (display) bounds    | 1.5     |
| 2.5          | Add integration tests for Y-zoom with perSeries mode     | 2.0     |
| 2.6          | Test with FitDistributionPage demo                       | 0.5     |
| **Subtotal** |                                                          | **9.5** |

### Phase 3: Integration & Polish

| Task         | Description                                  | Hours   |
| ------------ | -------------------------------------------- | ------- |
| 3.1          | Run full test suite, fix regressions         | 1.5     |
| 3.2          | Performance benchmark (ensure no regression) | 1.0     |
| 3.3          | Update documentation/examples                | 1.0     |
| **Subtotal** |                                              | **3.5** |

**Total Estimated Hours**: 18.5

---

## Open Questions

1. **Bar Grouping Mode**: ✅ RESOLVED
   - **Decision**: Hybrid approach
   - Auto-detect as default (multiple bar series = `grouped`)
   - Add `BarGroupingMode` enum for explicit control: `grouped`, `stacked`, `overlapping`
   - Chart-level config allows override of default behavior
   - Enables stacked bars in future without breaking change

2. **Y-Zoom Axis Selection**: ✅ RESOLVED
   - **Decision**: All axes proportionally (Option A), preserving existing zoom mechanics
   - **Mouse wheel / Keyboard (+/-)**: Zooms BOTH X and Y axes simultaneously (existing behavior)
   - **X-Scrollbar edge drag**: Zooms X-axis ONLY (existing behavior)
   - **Y-Scrollbar edge drag**: Zooms Y-axis ONLY (existing behavior)
   - This dual mechanism already works for non-normalized charts
   - Must now also work for `NormalizationMode.perSeries` + multi-axis charts
   - When Y-zoom occurs via any method, ALL Y-axes zoom proportionally together

3. **Minimum Bar Width**: ✅ RESOLVED
   - **Decision**: 4px minimum (Option A)
   - Bars never render narrower than 4 pixels regardless of series count
   - Aligns with existing `BarChartSeries.minWidth` default (4.0)
   - Ensures readability on all displays
   - If group would require < 4px bars, bars will overlap slightly rather than become invisible

---

## Dependencies

- No external package dependencies
- Builds on existing multi-axis infrastructure (FR-008)
- Uses existing transform/viewport system

---

## Testing Strategy

### Unit Tests

- `BarGroupInfo` positioning calculations
- `computeAxisBounds()` with `forPainting=true`
- Zoom transform application to axis bounds

### Widget Tests

- Multi-bar-series chart rendering
- Y-zoom with perSeries normalization

### Integration Tests

- FitDistributionPage with real/synthetic data
- Performance benchmarks with 1000+ points

### Manual Verification

- Visual inspection of grouped bars
- Zoom/pan interaction testing
- Scrollbar behavior verification

---

## Risk Assessment

| Risk                                  | Likelihood | Impact | Mitigation                            |
| ------------------------------------- | ---------- | ------ | ------------------------------------- |
| Breaking existing single-axis charts  | Low        | High   | Comprehensive regression tests        |
| Performance degradation               | Low        | Medium | Benchmark before/after                |
| Crosshair/tooltip coordinate mismatch | Medium     | Medium | Test interaction after zoom           |
| Complex edge cases in normalization   | Medium     | Medium | Incremental implementation with tests |

---

## References

- Legacy bar positioner: `docs/archive_release_1.0/lib/legacy/src/charts/bar/bar_positioner.dart`
- Multi-axis manager: `lib/src/rendering/modules/multi_axis_manager.dart`
- Series element painting: `lib/src/elements/series_element.dart`
- Chart transform: `lib/src/coordinates/chart_transform.dart`
