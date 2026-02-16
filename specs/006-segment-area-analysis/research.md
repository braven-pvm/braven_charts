# Research: Segment & Area Data Analysis

**Feature**: `006-segment-area-analysis` | **Date**: 2026-02-14

## Research Summary

No NEEDS CLARIFICATION markers in Technical Context — all technology choices are well-established within the codebase. This document records integration pattern research and best-practice decisions.

---

## R1: Overlay Rendering Pattern

**Task**: Determine the correct pattern for painting the summary overlay card in the existing two-layer architecture.

**Finding**: `ChartRenderBox` uses a two-layer paint system:

- **Layer 1 (Series Layer)**: GPU-cached via `SeriesCacheManager`. Paints series data, annotations. Cached between frames.
- **Layer 2 (Overlay Layer)**: Painted fresh every frame in `_paintOverlayLayer()`. Currently renders: box-selection rectangle, range annotation rubber-band, crosshair lines, tooltips (via `TooltipRenderer`).

The overlay layer checks `_hasActiveOverlayContent()` before calling `saveLayer` — this avoids the ~1-3ms `saveLayer` cost on idle charts (critical with 21+ charts).

**Decision**: The `RegionSummaryRenderer` will be a stateless module (matching `TooltipRenderer` pattern: `const RegionSummaryRenderer()`) invoked from `_paintOverlayLayer()`. The `_hasActiveOverlayContent()` check must be extended to include "active region summary".

**Rationale**: Follows established architecture exactly. No new patterns introduced.

**Alternatives considered**:

- Painting in the series layer (rejected — would invalidate cache on selection change)
- Using a Flutter `Overlay` widget (rejected — would break the pure custom-painting approach, mix widget and RenderBox layers)

---

## R2: Selection Flow Integration

**Task**: Determine how to wire annotation/segment/box-select events into the region analysis pipeline.

**Finding**: Three distinct entry points exist:

1. **Annotation tap**: `EventHandlerManager._handleElementTap()` → `coordinator.selectElement(element)` → delegates to `_BravenChartPlusState._invokeAnnotationTapCallback()` which calls `widget.onAnnotationTap`. The callback receives the `ChartAnnotation` model.

2. **Point tap on segment**: `EventHandlerManager._handleElementTap()` → same selection flow → `_invokePointTapCallback()` which calls `widget.onPointTap(dataPoint, seriesId)`. The data point has `segmentStyle` but no segment group context.

3. **Box-select**: `EventHandlerManager._completeBoxSelection()` → `coordinator.addToSelection(hits)` → `onSelectionChanged` fires with selected points list. The box rect is available from `coordinator.boxSelectionRect`.

**Decision**:

- For annotation tap: intercept after `selectElement()` — check if the element is a `RangeAnnotationElement`, extract `startX`/`endX`, build `DataRegion`, fire `onRegionSelected`.
- For segment tap: intercept after point tap — check if `dataPoint.segmentStyle != null`, detect segment group via `RegionAnalyzer`, build `DataRegion`, fire `onRegionSelected`.
- For box-select: intercept in `_completeBoxSelection()` — convert box rect to data-space X-range, build transient `DataRegion`, fire `onRegionSelected`.

All three converge on the same `onRegionSelected` callback with a `DataRegion` payload.

**Rationale**: Minimal invasiveness — piggybacks on existing flows rather than creating parallel selection systems.

**Alternatives considered**:

- New `InteractionMode.regionAnalysis` (rejected — region analysis is a reaction to existing events, not a new interaction mode)
- Separate callbacks per source type (rejected — unified callback simpler for consumers)

---

## R3: Segment Group Detection at Model Level

**Task**: Determine how to detect segment groups without coupling to rendering internals (`_StyleRegion` is private to `SeriesElement`).

**Finding**: `SeriesElement._analyzeStyleRegions()` performs an O(n) single-pass grouping of consecutive same-styled points into `_StyleRegion` objects (with `startIndex`, `endIndex`, `color`, `strokeWidth`). This is called during `paint()` and is tightly coupled to rendering (uses `Color` from the series theme as defaults).

The grouping logic itself is simple: iterate points, start a new group when `segmentStyle` changes. The rendering-specific parts are only the default color/strokeWidth resolution.

**Decision**: Implement `RegionAnalyzer.detectSegmentGroups(points)` as a model-level equivalent that:

1. Iterates `List<ChartDataPoint>`, groups consecutive non-null `SegmentStyle` by value equality
2. Returns `List<DataRegion>` with `startX`/`endX` from the group's first/last point
3. Does NOT depend on rendering defaults — uses `SegmentStyle` equality only (color + strokeWidth)

**Rationale**: Clean separation. The analyzer works on data models only, never touches rendering internals. The existing `_analyzeStyleRegions` continues to serve its rendering purpose unchanged.

**Alternatives considered**:

- Making `_StyleRegion` public and reusing it (rejected — would couple analysis to rendering, violates SOLID)
- Adding a `segmentGroupId` field to `ChartDataPoint` (rejected — adds state tracking to an immutable data model; over-engineering)

---

## R4: Binary Search on X-Sorted Data

**Task**: Validate the binary search approach for filtering data points within an X-range.

**Finding**: `ChartDataPoint.x` is a `double`. Data is typically X-sorted (time-series), but the library does not enforce or validate sort order anywhere. The `SeriesElement` paint code iterates points in order — if unsorted, it draws zigzag lines (valid but uncommon).

**Decision**:

1. `RegionAnalyzer.filterPointsInRange()` first checks if data is sorted (O(1) check: compare first and last X values as heuristic, or use a `bool isSorted` parameter with default `true`)
2. If sorted: binary search for `startX` → linear scan to `endX` → O(log n + k)
3. If not sorted: linear filter O(n)
4. Sort detection: Use a simple heuristic — if `points.first.x <= points.last.x`, assume sorted. This is O(1) and correct for all practical time-series data. A full O(n) sort check would negate the binary search benefit.

**Rationale**: Binary search is the right approach for the primary use case (sorted time-series). The fallback ensures correctness for edge cases.

**Alternatives considered**:

- Always linear scan (rejected — O(n) for every query is wasteful on 100k+ point datasets)
- Require sorted data (rejected — library currently accepts unsorted without error)
- Build an index/tree (rejected — over-engineering for on-demand queries)

---

## R5: Data Region Lifecycle and Caching

**Task**: Determine when `DataRegion` objects are created, cached, and disposed.

**Finding**: The spec requires lazy/on-demand computation (FR-007). The existing tooltip system computes tooltip content on every hover without caching — it's fast enough for per-frame rendering.

**Decision**:

- `DataRegion` is created fresh on each selection event (tap annotation, tap segment, box-select complete)
- The `selectedDataRegions` getter on state lazily computes the region from current selection state (coordinator's `_selectedElements`)
- `RegionSummary` is computed fresh each time `computeRegionSummaries()` is called — no caching
- Cache invalidation is avoided entirely by not caching. The computational cost (binary search + summary math on a few hundred to few thousand points) is well under 1ms and doesn't warrant caching complexity

**Rationale**: KISS principle (Constitution VII). Caching adds complexity (invalidation on data change, selection change, streaming update) for negligible benefit on the expected data sizes within a single region.

**Alternatives considered**:

- Cache `RegionSummary` keyed by region ID + data version (rejected — adds mutable state and invalidation logic for <1ms computation)
- Pre-compute all regions on data load (rejected — violates FR-007 lazy requirement)
