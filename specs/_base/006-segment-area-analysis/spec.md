# 006-segment-area-analysis: Segment & Area Data Analysis

## Overview

**Status**: Draft
**Priority**: Medium-High
**Estimated Effort**: 18-26 hours
**Created**: 2026-02-14

This feature makes the underlying series data within user-defined regions — segments and range annotations — programmatically accessible and optionally summarised with built-in metrics.

---

## Problem Statement

braven_charts already offers two ways to visually delineate regions of a chart:

1. **Segmented series** — coloured line/area segments defined per-point via `ChartDataPoint.segmentStyle`. These mark visually distinct phases within a single series (e.g. warm-up, intervals, cool-down).
2. **Vertical Range Annotations** — `RangeAnnotation` with `startX`/`endX` that highlight a specific X-axis range across all series (e.g. "VT1 zone", "Sprint 3").

Today neither mechanism exposes the underlying data it covers:

- When a user taps/selects a `RangeAnnotation`, the `onAnnotationTap` callback returns the annotation model — but **not** the series data points that fall within its `startX..endX` range.
- Segmented series have no concept of a "segment" as a first-class queryable region — the `SegmentStyle` is purely visual.
- Consumers who want to compute stats (min, max, avg) for a highlighted region must manually cross-reference annotation bounds with raw series data — error-prone and tedious.

---

## Goals

| #   | Goal                                                                                         | Priority     |
| --- | -------------------------------------------------------------------------------------------- | ------------ |
| G1  | Expose filtered data slices for selected segments/ranges as a readable property              | Must-have    |
| G2  | Provide a built-in summary (min, max, avg, count, sum, range, std-dev) per series per region | Must-have    |
| G3  | Allow summary display on-demand via callback, property toggle, or UI button                  | Must-have    |
| G4  | Work with both segment-style regions and vertical RangeAnnotations                           | Must-have    |
| G5  | Zero performance impact on rendering hot path (analysis is lazy/on-demand)                   | Must-have    |
| G6  | Support multi-axis charts (analysis uses original, non-normalized values)                    | Should-have  |
| G7  | Extensible: consumers can register custom analysis functions                                 | Nice-to-have |

---

## Current Architecture (Relevant Subsystems)

### Segment Styling (Per-Point)

```
ChartDataPoint
  └── segmentStyle: SegmentStyle?   // color, strokeWidth overrides
      └── Affects rendering of segment FROM this point TO the next

SeriesElement._analyzeStyleRegions()
  └── Groups consecutive same-style points into _StyleRegion batches
  └── Each _StyleRegion has: startIndex, endIndex, color, strokeWidth
```

Points with the same `SegmentStyle` are visually contiguous but not queryable as a logical group.

### Range Annotations

```
RangeAnnotation
  ├── startX, endX     // X-axis bounds (null = ±∞)
  ├── startY, endY     // Y-axis bounds (null = ±∞)
  ├── seriesId          // optional: for multi-axis Y alignment
  └── label, fillColor, borderColor, allowDragging, ...

RangeAnnotationElement
  └── Renders filled rectangle, handles hit-test + drag
```

### Selection & Callbacks

```
onAnnotationTap:   (ChartAnnotation annotation) → void
onSelectionChanged: (List<ChartDataPoint> points) → void     // box-select only
onPointTap:         (ChartDataPoint point, String seriesId) → void
```

**Gap**: No callback delivers "all series data within an annotation's range" or "all data in a visual segment group".

---

## Design

### Core Concepts

#### DataRegion — a logical X-range

```dart
/// Represents a contiguous X-range of interest within a chart.
/// Can originate from a RangeAnnotation or a segment group.
class DataRegion {
  final String id;                   // annotation ID or generated segment ID
  final String? label;               // human-readable name
  final double startX;               // inclusive
  final double endX;                 // inclusive
  final DataRegionSource source;     // enum: rangeAnnotation | segment

  /// Filtered data per series within this region's X-range.
  /// Key = seriesId, Value = list of ChartDataPoint with startX <= x <= endX.
  final Map<String, List<ChartDataPoint>> seriesData;
}

enum DataRegionSource { rangeAnnotation, segment, boxSelect }
```

#### RegionSummary — built-in statistics

```dart
/// Pre-computed statistics for one series within one DataRegion.
class SeriesRegionSummary {
  final String seriesId;
  final String? seriesName;
  final String? unit;
  final int count;
  final double min;
  final double max;
  final double sum;
  final double average;
  final double range;          // max - min
  final double? stdDev;        // population std dev (null if count < 2)
  final double? firstY;        // first point's Y value
  final double? lastY;         // last point's Y value
  final double? delta;         // lastY - firstY (null if < 2 points)
  final double duration;       // endX - startX in data units
}

/// Summary for an entire region across all series.
class RegionSummary {
  final DataRegion region;
  final Map<String, SeriesRegionSummary> seriesSummaries;
}
```

### API Surface

#### 1. Readable property on BravenChartPlus state

```dart
/// Access via GlobalKey<BravenChartPlusState> or through callback.
class BravenChartPlusState {
  /// Returns DataRegion(s) for the currently selected annotation(s)
  /// or segment(s). Empty list when nothing is selected.
  List<DataRegion> get selectedDataRegions;
}
```

This is populated **lazily** when queried — no work is done until the getter is called.

#### 2. Callback when region data becomes available

```dart
BravenChartPlus(
  /// Fired when a region (annotation or segment) is selected/deselected.
  /// Provides the data slices and optional pre-computed summaries.
  onRegionSelected: (DataRegion? region) { ... },
)
```

#### 3. Built-in summary computation

```dart
class BravenChartPlusState {
  /// Compute summaries for the given regions (or current selection).
  /// Lazy — no cost until called.
  List<RegionSummary> computeRegionSummaries([List<DataRegion>? regions]);
}
```

#### 4. On-demand summary display

```dart
BravenChartPlus(
  /// When true, selecting a range annotation or segment shows a
  /// summary overlay (small card) with min/max/avg per series.
  showRegionSummary: false,       // default off

  /// Customise which metrics appear and their formatting.
  regionSummaryConfig: RegionSummaryConfig(
    metrics: {RegionMetric.min, RegionMetric.max, RegionMetric.average},
    valueFormatter: (value, unit) => '${value.toStringAsFixed(1)} $unit',
    position: RegionSummaryPosition.aboveRegion,
  ),
)
```

Alternatively, a programmatic toggle:

```dart
// Via GlobalKey
chartKey.currentState?.showRegionSummaryOverlay(region);
chartKey.currentState?.hideRegionSummaryOverlay();
```

#### 5. Custom analysis hook (G7 — extensible)

```dart
BravenChartPlus(
  /// Called after built-in summary computation.  Receives the region
  /// data and built-in summary; returns optional additional display map.
  customRegionAnalysis: (DataRegion region, RegionSummary summary) {
    return {'Normalized Power': computeNP(region.seriesData['power']!)};
  },
)
```

### Segment Group Detection

Consecutive points sharing the same non-null `SegmentStyle` (by value equality — same color and strokeWidth) form a **segment group**. Each group is treated as a `DataRegion` with:

- `startX` = first point's X in the group
- `endX` = last point's X in the group
- `source` = `DataRegionSource.segment`
- `id` = `'segment_<seriesId>_<startIndex>'`
- `label` = null (segments are unnamed — consumers identify by index/X-range)

This reuses the existing `_StyleRegion` analysis in `SeriesElement` but at the model level to avoid coupling to rendering internals.

### Box-Select Analysis

The chart already supports box-selection (drag to select points). This feature extends it so that when a user completes a box-select drag, the X-range of the bounding box is automatically treated as an ad-hoc `DataRegion`:

1. User drags a bounding box on the chart (existing interaction)
2. On drag-complete, compute `startX`/`endX` from the box bounds (plot → data space)
3. Create a transient `DataRegion` with `source: DataRegionSource.boxSelect`
4. Fire `onRegionSelected` with the region (same callback as annotation/segment selection)
5. If `showRegionSummary` is enabled, display the summary overlay card
6. Region is cleared when the user clicks elsewhere or starts a new interaction

This gives users an interactive "select-and-analyse" experience without needing to pre-create annotations.

### Data Filtering

```
filterSeriesForRegion(series: ChartSeries, startX: double, endX: double):
  1. Binary search for first point where x >= startX   (O(log n) — data is X-sorted)
  2. Linear scan forward while x <= endX                (O(k) where k = points in range)
  3. Return List<ChartDataPoint> slice
```

For unsorted data (rare but possible), falls back to O(n) filter. X-only filtering — Y values are not filtered (vertical range annotations have unbounded Y).

**CRITICAL**: Analysis uses **original data values** — never normalized values. Multi-axis normalization is a rendering concern only.

---

## Rendering: Summary Overlay

When `showRegionSummary` is `true` and a region is selected, a summary card is rendered in the **overlay layer** (Layer 2) — same as tooltips and crosshairs.

```
┌───────────────────────────────────┐
│  VT1 Zone  (3.2 → 7.8)          │
│─────────────────────────────────  │
│  Target[W]   min: 85  max: 210   │
│              avg: 142  Δ: +125    │
│  FeO2[%]    min: 14.9 max: 16.1  │
│              avg: 15.4 Δ: +1.2    │
│  EqO2       min: 22.3 max: 28.1  │
│              avg: 25.0 Δ: +5.8    │
└───────────────────────────────────┘
```

Position: centred above the highlighted region, with fallback to inside-top if there's no space above.

This card must **not** invalidate the series cache — it paints in the overlay layer only.

---

## Integration Points

### With Existing Callbacks

| Existing Callback    | New Behaviour                                                                                                      |
| -------------------- | ------------------------------------------------------------------------------------------------------------------ |
| `onAnnotationTap`    | Still fires as-is. Additionally triggers `onRegionSelected` if the tapped annotation is a vertical RangeAnnotation |
| `onSelectionChanged` | Unchanged for point-level selection. Box-select now ALSO triggers `onRegionSelected` with the dragged X-range      |
| `onPointTap`         | Unchanged                                                                                                          |

### With ChartInteractionCoordinator

Region selection piggybacks on the existing annotation selection flow:

1. User taps a `RangeAnnotationElement` → coordinator marks it as selected
2. `onAnnotationTap` fires (existing)
3. New: if element is a `RangeAnnotationElement`, also compute `DataRegion` and fire `onRegionSelected`

For segments: selecting a data point on a styled segment computes the segment group and fires `onRegionSelected`.

### With Streaming

- Region analysis uses the **current buffer snapshot** — it reads whatever data is available at query time.
- No subscriptions or continuous updates — it's a point-in-time query.

---

## Models

### New Files

| File                                                     | Contents                                                    |
| -------------------------------------------------------- | ----------------------------------------------------------- |
| `lib/src/models/data_region.dart`                        | `DataRegion`, `DataRegionSource`                            |
| `lib/src/models/region_summary.dart`                     | `SeriesRegionSummary`, `RegionSummary`, `RegionMetric` enum |
| `lib/src/models/region_summary_config.dart`              | `RegionSummaryConfig`, `RegionSummaryPosition`              |
| `lib/src/analysis/region_analyzer.dart`                  | `RegionAnalyzer` — stateless utility: filter + summarise    |
| `lib/src/rendering/modules/region_summary_renderer.dart` | Overlay card painter                                        |

### Modified Files

| File                                                   | Change                                                                                                                                                                                   |
| ------------------------------------------------------ | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `lib/src/braven_chart_plus.dart`                       | Add `onRegionSelected`, `showRegionSummary`, `regionSummaryConfig`, `customRegionAnalysis` properties; add `selectedDataRegions` getter; wire annotation selection to region computation |
| `lib/src/models/interaction_config.dart`               | Add `onRegionSelected` callback typedef                                                                                                                                                  |
| `lib/src/rendering/modules/event_handler_manager.dart` | Extend box-select completion to create transient DataRegion and fire `onRegionSelected`                                                                                                  |
| `lib/src/rendering/chart_render_box.dart`              | Paint summary overlay in overlay layer when active                                                                                                                                       |
| `lib/braven_charts.dart`                               | Export new public types                                                                                                                                                                  |

---

## Implementation Plan

### Phase 1: Data Model & Analysis Engine

| Task         | Description                                                                           | Hours    |
| ------------ | ------------------------------------------------------------------------------------- | -------- |
| 1.1          | Create `DataRegion` and `DataRegionSource` models with equality, copyWith, toJson     | 1.5      |
| 1.2          | Create `SeriesRegionSummary`, `RegionSummary`, `RegionMetric` models                  | 1.5      |
| 1.3          | Implement `RegionAnalyzer.filterPointsInRange()` with binary search                   | 2.0      |
| 1.4          | Implement `RegionAnalyzer.computeSummary()` — all built-in metrics                    | 2.0      |
| 1.5          | Implement segment group detection from point-level `SegmentStyle` data                | 1.5      |
| 1.6          | Unit tests for analyzer (filter, summary, edge cases — empty, single-point, unsorted) | 2.5      |
| **Subtotal** |                                                                                       | **11.0** |

### Phase 2: Widget Integration & Callbacks

| Task         | Description                                                                         | Hours    |
| ------------ | ----------------------------------------------------------------------------------- | -------- |
| 2.1          | Add `onRegionSelected` callback and `selectedDataRegions` getter to BravenChartPlus | 1.5      |
| 2.2          | Wire RangeAnnotation selection → DataRegion computation → callback                  | 2.0      |
| 2.3          | Wire segment point selection → segment group detection → callback                   | 2.0      |
| 2.4          | Wire box-select completion → transient DataRegion → callback + overlay              | 2.5      |
| 2.5          | Add `showRegionSummary` / `regionSummaryConfig` properties                          | 1.0      |
| 2.6          | Widget tests for callback integration (annotations, segments, box-select)           | 2.5      |
| **Subtotal** |                                                                                     | **11.5** |

### Phase 3: Summary Overlay Rendering

| Task         | Description                                                          | Hours   |
| ------------ | -------------------------------------------------------------------- | ------- |
| 3.1          | Implement `RegionSummaryRenderer` — overlay card layout & painting   | 3.0     |
| 3.2          | Position logic (above region, inside fallback, respect chart bounds) | 1.5     |
| 3.3          | Wire into `ChartRenderBox.paint()` overlay layer                     | 1.0     |
| 3.4          | Visual polish (theme integration, animation)                         | 1.0     |
| 3.5          | Widget/golden tests for overlay rendering                            | 1.5     |
| **Subtotal** |                                                                      | **8.0** |

### Phase 4: Polish & Documentation

| Task         | Description                                      | Hours   |
| ------------ | ------------------------------------------------ | ------- |
| 4.1          | Custom analysis hook (`customRegionAnalysis`)    | 1.0     |
| 4.2          | Example demo page                                | 1.5     |
| 4.3          | Barrel export updates, API docs                  | 0.5     |
| 4.4          | Full regression test run + performance benchmark | 1.0     |
| **Subtotal** |                                                  | **4.0** |

**Total Estimated Hours**: 34.5 (conservative upper bound ~28h allowing for overlap)

---

## Performance Considerations

| Concern                                         | Mitigation                                                                                       |
| ----------------------------------------------- | ------------------------------------------------------------------------------------------------ |
| Filtering cost on large datasets (100k+ points) | Binary search O(log n) + linear scan O(k); only runs on-demand, never in paint loop              |
| Summary computation                             | Pure math on filtered slice; runs once per selection, cached until selection changes             |
| Overlay rendering                               | Paints in overlay layer only; does NOT invalidate series cache                                   |
| Memory                                          | `DataRegion.seriesData` holds references to existing `ChartDataPoint` objects — no copies        |
| Segment group detection                         | Runs once per element regeneration; reuses existing `_StyleRegion` grouping logic at model level |

---

## Resolved Questions

1. **Segment label assignment**: ✅ RESOLVED
   - **Decision**: No — keep `SegmentStyle` as-is (color + strokeWidth only). Consumers identify segment groups by index/X-range position. Labels may be added in a future version.

2. **Multi-region selection**: ✅ RESOLVED
   - **Decision**: V1 supports single-region selection only. Tapping a new annotation deselects the previous one. The `List<DataRegion>` API naturally extends to multi-region in a future version.

3. **Y-range filtering**: ✅ RESOLVED
   - **Decision**: X-only filtering. This feature targets vertical range annotations where Y values are completely unbound. Y-range filtering is out of scope.

4. **Programmatic region query**: ✅ RESOLVED
   - **Decision**: Yes — both programmatic and interactive. Expose `RegionAnalyzer` as a public utility for code-level queries, AND extend box-select so that dragging a bounding box on the chart analyses the X-range covered. See "Box-Select Analysis" section in Design.

---

## Dependencies

- No external package dependencies
- Builds on existing annotation selection system
- Builds on existing `SegmentStyle` / `_StyleRegion` infrastructure
- Uses existing overlay rendering layer

---

## Testing Strategy

### Unit Tests

- `RegionAnalyzer.filterPointsInRange()` — sorted data, unsorted data, empty, single point, boundary inclusive
- `RegionAnalyzer.computeSummary()` — all metrics validated against manual calculation
- Segment group detection — single segment, multiple segments, no segments, mixed series
- `DataRegion` serialization and equality

### Widget Tests

- Tap RangeAnnotation → `onRegionSelected` fires with correct data
- Tap segmented point → `onRegionSelected` fires with segment group data
- `selectedDataRegions` getter returns correct data
- `showRegionSummary` toggle shows/hides overlay

### Golden Tests

- Summary overlay card rendering at different positions
- Summary card with 1, 2, 3 series

### Performance Tests

- Analysis on 100k point dataset completes in <10ms
- No frame budget impact during hover/crosshair with summary visible

---

## Risk Assessment

| Risk                                                                       | Likelihood | Impact | Mitigation                                                           |
| -------------------------------------------------------------------------- | ---------- | ------ | -------------------------------------------------------------------- |
| Binary search assumption on X-sorted data fails for some use cases         | Low        | Medium | Fallback to O(n) filter; document sort requirement                   |
| Segment group detection produces too many/too few groups                   | Medium     | Low    | Configurable equality (exact match vs colour-only)                   |
| Summary overlay obscures important chart content                           | Medium     | Low    | Configurable position + dismiss on tap + auto-hide after timeout     |
| Performance regression from region computation on large streaming datasets | Low        | High   | Computation is lazy (on-demand only); never in paint/layout hot path |

---

## References

- `lib/src/models/chart_data_point.dart` — `ChartDataPoint`, `SegmentStyle`
- `lib/src/models/chart_annotation.dart` — `RangeAnnotation`
- `lib/src/elements/series_element.dart` — `_StyleRegion`, `_analyzeStyleRegions()`
- `lib/src/interaction/core/coordinator.dart` — `ChartInteractionCoordinator`
- `lib/src/rendering/modules/tooltip_renderer.dart` — overlay rendering pattern to follow
