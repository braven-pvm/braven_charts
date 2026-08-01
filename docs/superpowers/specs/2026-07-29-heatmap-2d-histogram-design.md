# Heatmap 2D Histogram — Phase 2 Slice Contract

**Date:** 2026-07-29
**Register:** `BC-0043`
**Branch:** `feature/BC-0043-heatmap-histogram`
**Depends on:** `BC-0037`

## Outcome

Developers can transform raw numeric X/Y observations into canonical Heatmap
cells without moving aggregation into the renderer or losing the source
identity required for inspection.

## Product boundary

This slice is a deterministic data transform. It does not add another painter,
an implicit Scatter mode, KDE smoothing, contours, or image-backed storage.
Its output is ordinary `HeatmapDataPoint` data, so the existing Heatmap
renderer, colour scales, table, artifacts, generated Source, Workbench,
interaction, and accessibility remain authoritative.

## Public contract

- `HeatmapHistogramObservation` owns finite X/Y, a non-negative weight, an
  optional durable key, and optional host metadata.
- `HeatmapHistogramAxis` owns explicit, strictly increasing numeric
  boundaries and one category label per interval.
- Every interval is lower-inclusive and upper-exclusive, except the final
  interval which includes the final domain boundary.
- `HeatmapHistogramData` preserves raw input order, aggregates a complete
  row-major bin matrix, and reports observations outside the declared domains.
- Bins expose count, total weight, input indices, and durable source keys.
- Output cells encode either count or total weight.
- Empty bins are explicitly configurable as zero, missing, or omitted.
- Output cell identity is stable for a given X/Y bin index.
- Bin boundaries and source references are copied into JSON-safe cell metadata
  so Data, artifacts, and generated Dart retain the exact canonical result.

## Deferred from this slice

- automatic bin-count algorithms and adaptive boundaries;
- probability-density normalization;
- raw-observation artifact codecs that rerun the transform after hydration;
- KDE/raster density and contours;
- rectangular bin brushing;
- tiled or streamed aggregation.

These remain in `BC-0043` and must not be inferred from the first transform.

## Verification

- boundary inclusion and invalid-boundary tests;
- weighted and unweighted aggregation;
- outside-domain accounting;
- zero, missing, and omitted empty-bin behavior;
- stable cell and raw observation identity;
- immutability and invalid-input tests;
- Heatmap table/artifact/generated-source integration;
- one production-shaped showcase preset;
- focused transform benchmark before promotion.
