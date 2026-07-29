# Native Cartesian Heatmap Chart Family — Delivery Roadmap

**Date:** 2026-07-28  
**Register:** `BC-0037`  
**Branch:** `feature/BC-0037-heatmaps`  
**Status:** Slices 0–4 complete locally; Slices 5–6 in progress  
**Design:** `docs/superpowers/specs/2026-07-28-heatmap-chart-family-design.md`

## Product outcome

Ship Heatmap as a complete built-in Cartesian family rather than a detached
painter or showcase approximation. The measured colour value must remain
first-class through the complete Braven Charts vertical contract.

## Delivery principles

1. One cell owns X, Y, and measured value.
2. Missing values are explicit and portable.
3. Category order is declared on both axes.
4. One series element owns and culls the matrix.
5. Colour mapping is deterministic, validated, and independently testable.
6. Data, Source, artifacts, accessibility, and Workbench are family work.
7. Phase 2 analysis transforms do not delay the native Phase 1 matrix.
8. No PR is opened between slices unless requested.

## Sequence

| Slice | Outcome | Status |
|---|---|---|
| 0 | Research, family boundary, architecture, and register | Complete |
| 1 | Cell/value, colour-scale, series, and axis foundations | Complete locally |
| 2 | Geometry, bounds, culling, hit index, and renderer | Complete locally |
| 3 | Interaction, accessibility, labels, legend, and motion | Complete locally |
| 4 | Artifacts, Data/CSV, Source, grammar, and Workbench | Complete locally |
| 5 | Complete showcase, Gallery, mobile, docs, and examples | In progress |
| 6 | Performance, regression hardening, and release readiness | In progress |

## Slice 0 — Architecture and scope

### Delivered

- Registered and claimed `BC-0037`.
- Audited the existing Cartesian, Scatter colour, category-axis, artifact,
  table, source, Workbench, showcase, and performance seams.
- Separated matrix Heatmap from treemap, mosaic, bubble, vector, and map
  families.
- Split native matrix delivery from advanced Phase 2 transforms.
- Wrote the complete design and delivery roadmap.

### Gate

- The family boundary and public model direction are explicit enough to begin
  contract tests without locking renderer internals prematurely.

## Slice 1 — Model and scale foundation

**Status:** First checkpoint implemented locally

### Public cell and identity

- Add `HeatmapDataPoint`.
- Support finite X/Y/value, stable point keys, labels, metadata, and explicit
  missing values.
- Add typed copy/equality/hash and strict validation.
- Reject duplicate coordinate pairs in one series.

### Colour scale

- Add sequential, diverging, and threshold scale models.
- Support explicit/automatic domain, midpoint, reverse, clamp, missing colour,
  formatter descriptors, and deterministic colour resolution.
- Keep the kernel independent from legend layout and Scatter refactoring.

### Series and axes

- Add `HeatmapChartSeries`, cell style, labels, and animation configuration.
- Add `SeriesStyle.heatmap` and public exports only when Cartesian registration
  is wired in the same slice.
- Generalize the categorical-axis contract for X and Y while preserving every
  existing X-axis behaviour.
- Define regular matrix, sparse, and triplet adapters that produce canonical
  cell lists.

### Tests first

- populated and missing cell construction;
- invalid finite values and invalid missing payloads;
- stable identity, copy, equality, and metadata;
- duplicate coordinate detection;
- valid and invalid sequential/diverging/threshold scales;
- exact endpoint, midpoint, threshold, reverse, clamp, and missing colours;
- category ordering and non-integral category coordinates;
- existing category-X regression tests.

### Review gate

- Public names, validation, missing state, colour semantics, and categorical Y
  are reviewed before renderer integration.

### Delivered local checkpoint

- `HeatmapDataPoint` keeps X position, Y position, and measured value as three
  independent channels, with explicit missing cells and durable identity.
- `HeatmapColorScale` resolves validated sequential, diverging, and threshold
  scales with fixed or caller-resolved domains, semantic midpoint, palette
  reversal, clamping, missing colour, and threshold labels.
- `HeatmapChartSeries` is publicly exported and registered as
  `SeriesStyle.heatmap`; layout validation prevents unsupported mixed-family
  compositions.
- The retained Cartesian series element paints cells, derives cell-edge
  bounds, hit-tests, selects, focuses, and exposes cell semantics.
- `CategoryAxisConfig` now applies to both X and Y axes. Categorical Y labels,
  density, layout width, exact half-slot bounds, crosshair labels, and
  per-series axes use the same category identity contract as X.
- Heatmap category coordinates are validated as integral and in-domain;
  blank/duplicate category identity is rejected.
- `HeatmapColorLegend` is a reusable public widget for continuous sequential
  and diverging ramps plus discrete threshold bands. The showcase no longer
  maintains a private approximation.
- Generated schema and fluent Y-axis surfaces include the category axis.
- 67 focused model, scale, axis, painter, legend, and renderer tests pass;
  generated fluent smoke coverage passes; package/showcase analysis is clean;
  the direct route smoke test and release web build pass.
- Canonical cell lists drive the renderer, viewport index, portable document,
  table, Source, fluent, grammar, and agentic JSON surfaces without hiding the
  measured value in metadata.

## Slice 2 — Geometry and renderer

**Status:** Complete locally

### Scope

- Add pure regular/sparse matrix geometry with cell-edge bounds.
- Add binary-search visible row/column culling and sparse visible queries.
- Add direct regular containment lookup and compact sparse hit index.
- Add one `HeatmapSeriesElement` with batched paint.
- Cache base cells separately from transient overlays.
- Add chart layout validation and normal Cartesian clipping.

### Tests

- category, numeric, date/time, regular, sparse, and missing geometry;
- midpoint-derived numeric boundaries and configured dimensions;
- visible source identity through culling;
- containment at borders and gaps;
- 250k source / small visible-window complexity;
- light, dark, high-contrast, missing, border, gap, and clipping goldens.

### Review surface

A first direct Heatmap route with labelled employee/weekday and dense
temperature matrices. It is not called portable-complete yet.

## Slice 3 — Product interaction and presentation

**Status:** Complete locally; broad accessibility and animation regression
evidence remains in Slice 6

### Scope

- typed cell hits, callbacks, tooltips, and tracking values;
- full-cell hover/focus/selection overlays;
- keyboard row/column traversal and cell activation;
- scalable semantics;
- density-aware labels with automatic contrast;
- continuous/discrete colour legend;
- entrance ordering and stable-identity value updates;
- normal zoom, pan, scrollbars, navigator, and annotations.

### Acceptance gates

- no interpolation between cells;
- paint, hit, tooltip, and table expose the same measured value;
- a 100k-cell source does not create 100k semantic nodes;
- reduced motion renders final state immediately;
- hover does not rebuild matrix geometry or all labels.

## Slice 4 — Portable family and Workbench

**Status:** Complete locally

### Scope

- artifact series/cell/scale codecs and capability negotiation;
- hydration and selected-cell restoration;
- long and matrix Data projections;
- CSV with explicit missing-state fidelity;
- deterministic generated Dart and compile fixtures;
- grammar/fluent and agentic input;
- Chart/Data/Split/Source Workbench adoption;
- source capture and family integration documentation.

### Acceptance gates

- canonical cell identity and colour scale round-trip losslessly;
- malformed domains, duplicate coordinates, and implicit NaN missing fail;
- generated Dart compiles and reconstructs equivalent configuration;
- every built-in Heatmap preset has a clean Source view.

### Delivered local checkpoint

- Inline and columnar chart documents preserve cell identity, values, explicit
  missing state, colour scales, cell styling, and category metadata.
- Hydration fails closed for malformed Heatmap extensions.
- Data supports matrix and explicit long-form projections; CSV retains the
  source distinction between zero, missing, and absent positions.
- Direct Dart and grammar Source reconstruct typed cells, axes, scales, and
  style configuration and pass formatting, parsing, analysis, and round-trip
  fixtures.
- Generated fluent builders, grammar `HeatmapMark<T>` / `geomHeatmap`, and the
  agentic JSON builder all construct native Heatmap series.
- The dedicated page mounts through `BravenChartWorkbench`; Chart, Data, Split,
  and Source stay synchronized with the effective preset and controls.

## Slice 5 — Showcase breadth

**Status:** In progress

### Required examples

- employee by weekday with values;
- day/hour temperature;
- calendar/month;
- annual weather or dense time-series/lasagna;
- diverging correlation/confusion;
- sparse matrix with explicit missing cells.

### Controls

- scale type, palette, domain, midpoint, reverse, clamp, and missing colour;
- cell gaps, border, radius, labels, contrast, and legend;
- matrix density and data regeneration;
- axes, categories, theme, zoom, pan, scrollbars, and navigator;
- animation replay and update;
- Workbench display modes.

### Surfaces

- desktop guide and direct route;
- compact/mobile examples;
- Chart Types catalogue;
- Gallery cards;
- README/pub.dev native captures when release-ready.

### Current local checkpoint

- The desktop Heatmap guide offers activity, day/hour temperature,
  service-health threshold, calendar/month, diverging correlation, and dense
  sparse viewport presets.
- The inspector exposes palette, reverse, clamp, domain padding, diverging
  midpoint, missing-cell colour, labels, gap, radius, and legend controls.
- Calendar Source emits explicit missing cells and preset changes refresh
  Source without stale-state warnings.
- Compact/mobile examples, Chart Types catalogue, Gallery cards, public docs,
  and release captures remain open.

## Slice 6 — Hardening and release

**Status:** Performance checkpoint complete locally; broad hardening and
release work remain

### Performance

- permanent 1k labelled, 10k dense, and 250k-source/culling benchmarks;
- cached hit, hover overlay, uniform cells, borders, labels, and motion;
- p50/p95 with build mode, device, source, visible count, and style.

### Current local performance checkpoint

- Heatmap cells, borders, and labels now remain in the retained series
  `Picture`, while focus, selection, hover, and press paint in a live overlay.
- Structurally equal widget series and interaction-only element regeneration
  preserve the same cached base picture. Data, palette, label, gap, radius,
  transform, and other presentation changes still invalidate it.
- Permanent host-side `flutter test` benchmarks cover 1,000 labelled cells,
  10,000 styled cells, a 250,000-cell source culled to 1,134 visible cells,
  cached indexed hits, and the hover overlay.
- Current Windows host results:
  - 1,000 labelled cells: 1.433 ms median, 1.718 ms p95;
  - 10,000 styled cells: 11.121 ms median, 12.907 ms p95;
  - 250,000 source / 1,134 visible: 1.131 ms median, 1.441 ms p95;
  - cached hit: 0.005 ms median and p95;
  - hover overlay: 0.004 ms median, 0.005 ms p95.
- Widget regressions prove selection and hover retain picture identity while
  presentation-only changes replace it.

### Regression

- full package and standalone showcase tests;
- scoped package/showcase analysis;
- existing Cartesian category, axis, annotation, navigator, and selection tests;
- artifacts, table, source compile, Workbench, compact, and desktop routes;
- release web build and direct-route browser review.

### Release

- public API and chart-type docs;
- feature matrix and chart-family integration evidence;
- README and changelog;
- dartdoc;
- pub.dev dry run;
- explicit visual and interaction approval before PR/release promotion.

## Phase 2 backlog

Phase 2 remains attached to BC-0037 until implementation planning determines
whether any item needs its own register entry:

- 2D histogram aggregation transforms;
- KDE/raster density and contours;
- clustering/reordering/dendrograms;
- rectangular brush and row/column selection;
- irregular cell boundaries;
- multiple Heatmap colour axes and legend filtering;
- tiled/virtualized/streamed/image-backed matrices;
- shared-domain small multiples.

Separate-family candidates are treemap, mosaic/Marimekko, vector field, and
geographic Heatmap.

## Immediate next action

Complete accessibility and motion hardening, public documentation and native
captures, then run the broad package/showcase/release-readiness matrix before
PR promotion.
