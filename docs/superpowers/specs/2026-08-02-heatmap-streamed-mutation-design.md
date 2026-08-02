# Streamed Heatmap Mutation Design

Status: Accepted for BC-0050 S1 implementation

## Purpose

Viewport-backed Heatmaps already keep fetching, cache ownership, and residency
outside the renderer. This slice adds live cell changes without turning the
chart package into a second unbounded database or allowing asynchronous work
inside painting.

## Contract

The host remains authoritative. It updates its `HeatmapTileSource` first, then
submits an ordered `HeatmapMutationBatch` to `HeatmapViewportController`.
Batch revisions are monotonic. Repeated or older batches are ignored.

A batch contains typed operations:

- `HeatmapCellUpsert` replaces or inserts one regular-matrix cell;
- `HeatmapCellRemoval` removes one regular-matrix cell;
- `HeatmapTileInvalidation` declares that a complete source tile must reload.

Cell operations use row and column indices, not display coordinates, so their
tile identity is deterministic. An upsert's point must represent the exact
regular-matrix coordinate named by the operation.

## Residency and race behaviour

Accepted cell operations patch cached tiles immediately. If the same tile is
already loading, the controller retains only the latest operation for each
address and overlays those idempotent changes before the load may enter cache.
That short-lived overlay is limited to in-flight tiles and is discarded after
the load completes.

Tile invalidation removes the resident cache entry and advances a per-tile
epoch. A load that began under an older epoch is discarded and restarted, so
an old response cannot overwrite current source truth.

The visible snapshot is never mutated. Pending cell operations are coalesced
by address and published as a new immutable snapshot at a bounded cadence.
Visible invalidations schedule one viewport reload at the same boundary. The
renderer therefore continues to consume a normal immutable
`HeatmapChartSeries` with no source callbacks, futures, or mutable collections.

## Boundedness

- Cache size remains governed by `maxCachedTiles`.
- Viewport breadth remains governed by `maxTilesPerViewport`.
- One mutation batch is limited by `maxMutationsPerBatch`.
- Pending visible operations are flushed when their unique-address budget is
  reached, preventing an unbounded coalescing queue.
- The controller does not retain a historical mutation journal.

## Failure and diagnostics

Malformed operations fail before changing controller state. Stale batch
revisions return `false`. Diagnostics expose the last accepted revision,
accepted and ignored batch counts, applied cell-operation count, and
coalesced publication count.

## Deferred decisions

Portable provider runtime binding, image-backed tiles, and aggregation or
clustering pushdown remain separate BC-0050 decision slices. None are implied
by this mutation API.
