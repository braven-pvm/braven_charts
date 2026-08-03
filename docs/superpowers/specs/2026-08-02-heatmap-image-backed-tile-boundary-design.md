# Heatmap image-backed tile boundary

**Register:** BC-0050 I1  
**Status:** gates 1-5 implemented for review; BC-0052 release audit pending

## Purpose

Some very large regular matrices are already available as pre-coloured image
tiles, or are cheaper to rasterize outside Flutter than to materialize one
`HeatmapDataPoint` per source cell. Braven Charts needs a bounded way to show
those tiles without moving acquisition, decoding, caching, or resource disposal
into `ChartRenderBox` and without pretending that pixels are canonical cells.

This is a presentation optimization, not a replacement for the ordinary
Heatmap data model.

## Decision

Image-backed tiles remain a separate host-owned runtime from
`HeatmapTileSource`. They must not be added to `HeatmapChartSeries` or encoded
as `HeatmapDataPoint` values.

The implemented raster Heatmap layer uses these boundaries:

- the host resolves and decodes image tiles;
- a controller owns the byte-budgeted cache and publishes an immutable mounted
  raster snapshot;
- the renderer receives only ready-to-paint image handles and finite data-space
  bounds;
- the renderer clips and transforms those handles like any other Cartesian
  layer, but never fetches, decodes, caches, subscribes, or disposes them; and
- exact cell semantics exist only when the host also supplies a bounded
  canonical cell or semantic index for the resident region.

The ordinary cell renderer remains the default and the truthful fallback.

## Proposed contracts

The implementation keeps acquisition and mounted presentation distinct. Gate 1
adopts the contract names below as internal runtime types; they remain
unexported until renderer and product evidence establish the public API.

### Host source

`HeatmapRasterTileSource` accepts bounded tile requests derived from one
viewport and returns host-decoded resources carrying:

- a stable tile key;
- a monotonic content revision;
- finite source-space bounds;
- a decoded resource whose ownership transfers to the controller;
- colour-domain and palette identity used to produce the pixels; and
- optional semantic resident cells or a cell lookup index.

Credentials, transports, callbacks, and mutable caches never enter a chart
document.

### Controller snapshot

`HeatmapRasterViewportController` owns loading coordination, eviction,
generation ordering, byte accounting, and disposal. Decode remains behind the
host source boundary. The controller publishes an immutable snapshot containing mounted
tiles with:

- stable key and revision;
- exact source-space bounds;
- a decoded, ready-to-paint image handle;
- decoded byte cost;
- optional bounded semantic data; and
- load/error diagnostics.

Cache budgets are expressed in decoded bytes as well as tile count. Tile-count
alone is not a meaningful memory bound for images.

### Renderer layer

A dedicated raster layer paints mounted tiles under the existing Cartesian
transform and plot clip. It is not a branch inside ordinary Heatmap cell
painting and does not change `HeatmapChartSeries` interpretation.

The renderer may retain an immutable snapshot reference for a paint, but it
does not own the image lifecycle. The controller must not dispose an image
while any published snapshot can still reference it.

## Lifecycle and disposal

Decoded images are external resources and require an explicit lifetime:

1. a newly decoded generation is staged by the controller;
2. a complete immutable mounted snapshot is published atomically;
3. superseded images remain alive until no published or painting snapshot can
   reference them; and
4. only then may byte-budgeted LRU eviction dispose them.

Failed or stale loads never replace a complete mounted tile. Errors retain the
last complete raster snapshot where one exists. Generation checks follow the
same deterministic stale-result rules as the cell viewport controller.

## Colour and value semantics

Raster tiles are already coloured. Braven Charts cannot reliably recover the
original values from their pixels.

- The source owns the palette, domain, missing-value colour, and rasterization
  revision.
- Chart palette controls are disabled for a raster-only snapshot unless the
  source explicitly supports re-rasterization and reload.
- A displayed colour legend uses source-supplied domain metadata and must be
  labelled as provider metadata, not derived from pixels.
- A host that needs runtime palette editing must provide canonical cells or a
  source capable of regenerating tiles for the requested scale.

## Interaction and hit testing

Raster pixels do not create fabricated `HeatmapDataPoint` identities.

- Cell tooltips, selection, keyboard navigation, and exact value lookup are
  enabled only for the bounded canonical cells or semantic index supplied by
  the host.
- A raster-only layer supports chart-level pan and zoom but is explicitly
  non-interactive at cell level.
- Approximate pixel-colour inversion is not an accepted hit-test strategy.
- Selection identity must remain stable across tile eviction and reload; the
  host-provided semantic key is authoritative.

## Accessibility

Raster-only content must expose a chart-level summary describing its source,
visible domain, colour domain, and the absence of per-cell semantics. It must
not announce synthetic values inferred from pixels.

When per-cell accessibility or table navigation is required, the host supplies
the corresponding bounded canonical cells or a separate accessible data view.
The ordinary cell renderer remains the required fallback for complete
cell-level semantics.

## Workbench, artifacts, and export

The portable artifact remains a truthful resident snapshot:

- PNG capture includes the painted raster layer.
- Workbench Data, CSV, Split, and generated Dart expose only canonical resident
  cells supplied by the host. Raster-only pixels are described as a provider
  layer and are not serialized as invented cell data.
- Portable configuration stores a stable raster-provider descriptor, source
  arguments safe for JSON, initial viewport, and presentation metadata.
- Hydration requires an allowlisted host runtime binding. A missing binding
  fails with `runtime_binding_required`.
- Encoded image bytes, decoded image handles, credentials, caches, and
  transport state are not embedded in `ChartDocument`.
- A static preview may accompany an artifact, but it is not presented as a
  hydratable or queryable Heatmap data source.

## Fallback behavior

Every raster-backed chart declares one of these explicit fallbacks:

1. **Cell fallback** — render supplied canonical resident cells when raster
   mounting is unsupported or fails.
2. **Static preview fallback** — show a labelled, non-interactive preview when
   only presentation is required.
3. **Hard failure** — report a named runtime/provider error when neither
   fallback exists.

Silent empty charts and silent substitution of stale or semantically different
data are not allowed.

## Performance boundary

Raster tiles are justified only if they reduce end-to-end cost for a measured
workload. The implementation must measure decode latency, upload/raster cost,
decoded memory, cache churn, viewport latency, and presented frame cadence.
BC-0052 owns the full release audit; image-backed measurements become part of
that gate if this layer ships.

The implementation must not add work to ordinary Heatmap or other Cartesian
paint paths when no raster layer is mounted.

## Implementation gates

1. **Runtime model and lifecycle** — prove generation ordering, byte budgets,
   atomic snapshot publication, retained fallback, and exact-once disposal in
   isolated controller tests. **Implemented for review on 2026-08-02:** eight
   focused tests cover complete-only publication, stale generations, tile and
   aggregate byte budgets, LRU eviction, retained errors, invalid bounds, and
   exact-once disposal including late completion.
2. **Cartesian raster layer** — paint finite source-space tile bounds under the
   existing transform and clip without renderer-owned acquisition or disposal.
   **Implemented for review on 2026-08-02:**
   `HeatmapRasterImageResource`, `HeatmapRasterElement`, and
   `BravenChartPlus.heatmapRasterViewportController` borrow complete mounted
   snapshots from the controller. Focused paint tests cover transform updates,
   clipping, and non-ownership; the `Raster tiles` preset paints six decoded
   images with no fallback Heatmap series.
3. **Semantic companion** — prove optional exact hit testing, selection,
   accessibility, and Data/Source truthfulness from bounded host-supplied data.
   **Implemented for review on 2026-08-02:** every complete tile may carry
   bounded canonical aggregates. The raster controller validates and flattens
   those cells into one ordinary immutable `HeatmapChartSeries`; raster paint
   remains single-pass while the canonical companion powers Workbench,
   interaction, export, and accessibility.
4. **Portable provider** — add descriptor/runtime binding and named failure
   behavior without serializing bytes or handles. **Implemented for review on
   2026-08-02:** `HeatmapRasterViewportProviderDescriptor` stores one stable
   provider ID, layer identity, bounded initial viewport, JSON-safe arguments,
   presentation settings, and an explicit cell or hard-failure fallback.
   `ChartRuntimeBindings.heatmapRasterViewportProviders` creates a fresh
   host-owned runtime per mounted hydrated chart. Documents never contain
   raster bytes, decoded handles, caches, transports, credentials, or
   callbacks.
5. **Product and performance evidence** — add a production-shaped massive
   matrix example, fallback states, benchmarks, memory evidence, and BC-0052
   release-audit coverage. **Implemented for review on 2026-08-02:** the Deep
   signal spectrogram represents 512 channels by one million acquisition
   samples while mounting only 12-16 decoded image tiles and 1,536-2,048
   canonical semantic aggregates for a moving viewport. Deliberate review
   controls expose atomic retained loading, retained failure, retry, and
   return-to-latest behavior. A focused 100-window controller benchmark
   completed in 101.824 ms with 212 loads, 1,188 cache hits, 164 evictions,
   and a 6 MiB decoded cache; 100 same-residency pans completed in 42.715 ms
   with 1,200 cache hits and no new decode or disposal. These are bounded
   controller-contract results, not the complete release performance audit.

Each gate began only after the preceding boundary and focused evidence were
accepted. Gates 1-5 establish the product and architecture contract, but a
fast controller benchmark does not make the chart releasable: BC-0052 must
still measure decode, upload, raster, interaction, memory, cache churn, and
presented-frame behavior end to end.

## Non-goals

- renderer-owned network or filesystem access;
- reconstructing canonical values from colours;
- general geographic map tiling;
- GPU texture APIs embedded in portable chart documents;
- unbounded decoded-image caches;
- changing ordinary Heatmap cell semantics; or
- declaring Heatmap release readiness without BC-0052.
