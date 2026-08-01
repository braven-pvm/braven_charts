# Viewport-backed Heatmap matrix design

**Register:** BC-0043, slice V1

## Problem

The native Heatmap renderer already culls a large materialized matrix to the
visible viewport. That solves paint and hit-test cost, but it does not solve
source residency: a matrix with millions of cells should not require millions
of `HeatmapDataPoint` objects to remain in memory.

V1 adds a host-owned, asynchronous tile source. It resolves only the regular
matrix tiles needed for the current viewport plus bounded overscan, then
publishes an ordinary immutable `HeatmapChartSeries` snapshot. The rendering
pipeline, selection index, table projection, artifacts, and generated Dart
source continue to consume the same materialized series model they use today.

## Boundary

V1 includes:

- a finite regular matrix domain with deterministic row and column indices;
- stable tile coordinates and bounded tile requests;
- asynchronous tile loading outside the render loop;
- request coalescing and stale-result rejection;
- a deterministic least-recently-used tile cache with an explicit budget;
- immutable snapshots containing only the currently materialized cells;
- a showcase with a conceptual multi-million-cell matrix, cache diagnostics,
  and Workbench fidelity for the current resident snapshot.

V1 deliberately excludes:

- renderer-owned fetching or mutation;
- streamed cell mutation;
- image-backed or GPU texture tiles;
- provider serialization in chart documents or generated source;
- clustering, contours, or histogram aggregation pushed into the source;
- unbounded or irregular matrix domains.

## Public model

`HeatmapMatrixDomain` declares the full finite matrix shape, the centre of its
first cell, and its regular cell dimensions. It converts data-space viewports
into clamped row and column spans and exposes the full data-space bounds needed
for explicit chart axes.

`HeatmapTileKey` is the stable `(columnTile, rowTile)` identity. A
`HeatmapTileRequest` carries that key plus its clamped half-open source index
range. `HeatmapTile` returns zero or more cells for the requested range; sparse
tiles are valid.

`HeatmapTileSource` declares the domain and tile dimensions and implements one
asynchronous `loadTile` operation. Sources may read local files, databases,
network services, isolates, or deterministic procedural data. The package does
not prescribe transport.

## Controller lifecycle

`HeatmapViewportController` is a `ChangeNotifier` owned by the host widget.
The host forwards visible chart bounds as `HeatmapViewportRequest` values.
Requests may be scheduled with a small debounce for interaction-heavy views or
loaded immediately for initial state and deterministic tests.

For every accepted viewport the controller:

1. clamps the viewport to the finite domain and applies cell-count overscan;
2. rejects a request whose tile count exceeds the explicit per-viewport
   safety budget before materializing keys or starting source loads;
3. resolves a deterministic, row-major set of tile keys;
4. reuses cached tiles and deduplicates concurrent tile loads;
5. collects the complete requested tile set outside the render loop;
6. rejects publication when a newer request generation has superseded it;
7. publishes one immutable `HeatmapViewportSnapshot` in row-major cell order.

Completed stale tiles may enter the bounded cache because they can satisfy a
later request, but a stale generation can never replace the visible snapshot.
Errors from stale generations are ignored. A current error is surfaced in the
snapshot while the previously published cells remain visible.

## Cache semantics

The cache is a deterministic LRU keyed by `HeatmapTileKey`. Cache capacity is
expressed in tiles, not bytes, because the source owns tile density. Accessing
a cached tile promotes it. Inserting beyond the budget evicts the oldest tile.
The current snapshot owns its immutable cells independently from the cache, so
a viewport spanning more tiles than the cache budget remains correct.

Diagnostics expose request generation, requested/resident tile counts,
resident cell count, cache hits, cache misses, stale publications rejected,
and current loading/error state. They are host diagnostics and do not enter the
renderer.

## Full-domain axes and snapshot fidelity

The chart must use explicit X and Y bounds derived from
`HeatmapMatrixDomain`. Automatic bounds derived from resident points would
collapse the world to the current tile set and make pan/zoom unstable.

The controller materializes snapshots through `HeatmapChartSeries.copyWith`.
Workbench Data, Split, Source, table export, capture, and artifacts therefore
represent the current resident snapshot only. They do not serialize the source
or imply that every conceptual matrix cell is resident. The showcase labels
this boundary directly.

## Performance contract

- no source future is awaited by the render object;
- identical in-flight tile keys are loaded once;
- viewport motion coalesces to the latest scheduled request;
- publication work is proportional to resident cells, not conceptual cells;
- cache size is bounded and deterministic;
- accidental full-domain requests fail before allocating a massive tile list;
- the existing viewport index remains the only renderer-side culling path.

V1 tests cover domain math, edge clamping, deterministic tile identity, cache
promotion and eviction, in-flight deduplication, stale-result rejection,
failure retention, series materialization, and controller disposal. The
showcase verifies full-domain navigation, bounded resident data, cache reuse,
and accurate Workbench output.
