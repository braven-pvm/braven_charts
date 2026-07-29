# Native Cartesian Heatmap Chart Family — Design Specification

**Date:** 2026-07-28  
**Register:** `BC-0037`  
**Status:** Approved direction; implementation in progress  
**Branch:** `feature/BC-0037-heatmaps`  
**Roadmap:** `docs/superpowers/plans/2026-07-28-heatmap-chart-family-roadmap.md`

## Product outcome

Add Heatmap as a complete built-in Cartesian chart family. A Heatmap cell owns
three independent data channels:

1. its X coordinate;
2. its Y coordinate;
3. the measured value encoded by colour.

The measured value is not metadata and is not a Scatter marker colour
shortcut. It must survive rendering, bounds, selection, tooltips,
accessibility, artifacts, Data mode, CSV, generated Dart, the Workbench, and
chart restoration without loss.

The first release supports regular and sparse matrices, useful colour scales,
categorical and quantitative axes, and production interaction. Advanced
statistical transforms and unrelated rectangle-based chart families remain
explicit later work.

## Why Heatmap is a new family

Existing Cartesian series map `x` and `y` to plot position. Scatter can also
map a secondary value to marker colour or size, but a marker remains a point.
A Heatmap cell instead occupies an X interval and a Y interval while a third
value controls its fill.

Treating Heatmap as Scatter would create four avoidable defects:

- hit testing would use marker distance instead of cell containment;
- neighbouring cells would not share exact interval boundaries;
- matrix tables and keyboard traversal would have no row/column contract;
- large matrices would create excessive point/semantic/spatial-index objects.

Heatmap therefore receives a dedicated typed point, series, geometry engine,
renderer element, table projection, source emitter, and Workbench adoption.
It still uses the normal Cartesian axes, annotations, viewport, navigator,
controller, and theme infrastructure.

## Family boundary

### Phase 1: native matrix Heatmap

- labelled categorical matrices;
- numeric-by-numeric matrices;
- date/time-by-category and date/time-by-time matrices;
- calendar and annual-weather presets;
- dense time-series or “lasagna” matrices;
- sequential, diverging, and threshold colour scales;
- sparse matrices and explicit missing cells.

### Phase 2: transformations and advanced matrix analysis

- raw-observation 2D histogram binning;
- count, sum, mean, min, max, and proportion aggregators;
- KDE or interpolated raster density and optional contours;
- clustered matrices, reordering, dendrograms, and clustering metadata;
- rectangular brush, row selection, and column selection;
- irregular cell boundaries;
- multiple Heatmap layers or colour axes and legend filtering;
- tiled, virtualized, streamed, and image-backed massive matrices;
- small multiples with shared colour domains.

### Separate families or compositions

| Visual | Correct home |
|---|---|
| Treemap | Hierarchical rectangle chart family |
| Mosaic / Marimekko | Variable-width categorical rectangle family |
| Bubble matrix / punch card | Scatter/Bubble preset |
| Wind vector field | Vector-field or geospatial family |
| Geographic heat layer / choropleth | Map and projection family |

Those visuals may share colour-scale concepts later, but do not belong in the
Heatmap series contract.

## Public data contract

### Cell

The canonical source form is a cell list, not a nested two-dimensional array:

```dart
HeatmapDataPoint(
  x: 3,
  y: 1,
  value: 92,
  pointKey: 'tuesday:marie',
  label: '92',
  metadata: {'employee': 'Marie', 'weekday': 'Tuesday'},
)
```

`HeatmapDataPoint` has:

- finite `x` and `y` coordinates;
- a finite measured `value`, unless the cell is explicitly missing;
- optional stable `pointKey`;
- optional label and metadata;
- an explicit missing state rather than a NaN or magic value.

Stable identity resolves in this order:

1. `pointKey`;
2. exact `(x, y)` coordinate pair.

Two populated cells may not share the same coordinate pair in one series.
Cell order is not visual identity and must not determine update matching.

### Series

```dart
HeatmapChartSeries(
  id: 'weekday-sales',
  name: 'Sales',
  points: cells,
  colorScale: HeatmapColorScale.sequential(...),
  cellStyle: HeatmapCellStyle(...),
  labels: HeatmapCellLabelConfig(...),
)
```

Convenience constructors may create the same canonical cell list from:

- a regular matrix with row/column coordinates;
- triplets `(x, y, value)`;
- calendar dates.

The constructors are adapters only. Artifact, table, selection, and renderer
code consume canonical cells.

### Missing cells

Missing is distinct from:

- a cell whose measured value is zero;
- an absent sparse coordinate;
- an invalid non-finite value.

An explicit missing cell retains row/column identity and may paint a configured
missing-value fill. An absent sparse coordinate paints nothing. Public
construction rejects NaN and infinity rather than silently converting them to
missing.

## Axis contract

Heatmap supports these coordinate combinations on both axes:

- continuous numeric;
- date/time represented by the existing timestamp coordinate convention;
- categorical positions with explicit labels and ordering.

The current `CategoryAxisConfig` is X-oriented in implementation even though
the concept is not X-specific. Heatmap requires first-class categorical Y.
The implementation must extract or generalize a reusable Cartesian categorical
axis contract without changing existing X-axis behaviour.

Category coordinates remain numeric internally and must be integer-aligned
indexes into an ordered category list. Unknown, duplicate, and non-integral
category coordinates fail validation. Category order is declared, never
inferred from insertion order during paint.

For regular cells, geometry derives boundaries from neighbouring coordinates
or explicit cell dimensions. For categories, one category occupies one band.
For irregular numeric coordinates, Phase 1 uses midpoint-derived boundaries
plus optional uniform width/height. Arbitrary per-cell rectangles are Phase 2.

## Colour-scale contract

Heatmap owns a typed `HeatmapColorScale`, independent from annotation legend
presentation.

### Supported scales

- **Sequential:** low-to-high magnitude.
- **Diverging:** values on either side of a meaningful midpoint.
- **Threshold:** ordered numeric thresholds with discrete colour buckets.

### Required behaviour

- automatic or explicit minimum and maximum;
- explicit diverging midpoint, defaulting to zero only when requested;
- reversal;
- clamping outside the domain;
- missing-value colour;
- optional formatter and semantic label;
- deterministic interpolation in an explicit colour space;
- a native continuous or discrete colour legend.

The existing Scatter colour encoding is useful precedent, but Phase 1 does not
force a cross-family refactor. Heatmap models its complete contract first. A
later compatibility-safe extraction may let Scatter and Heatmap share a lower
level numeric colour-scale kernel.

### Validation

- domains and thresholds must be finite;
- minimum must be less than maximum;
- a diverging midpoint must lie within the domain;
- thresholds must be strictly increasing;
- a threshold scale requires exactly one more colour than thresholds;
- sequential and diverging gradients require at least two stops;
- automatic domains ignore explicit missing cells and fail when no measured
  values remain.

## Cell presentation

`HeatmapCellStyle` controls:

- row and column gap;
- border colour and width;
- corner radius;
- opacity;
- missing-cell colour;
- hover, focus, and selection overlays.

`HeatmapCellLabelConfig` controls:

- visibility;
- formatter;
- text style;
- minimum readable cell width and height;
- automatic contrast against the resolved cell colour;
- collision and overflow behaviour.

Labels are density-aware. The renderer must not construct a `TextPainter` for
every source cell when labels cannot fit or the cell is off screen.

## Geometry and renderer

Heatmap uses one dedicated `HeatmapSeriesElement` under
`ChartLayoutKind.cartesian`.

It must not create one top-level `ChartElement` or QuadTree entry per cell.
That would multiply element lifecycle, sorting, semantics, and hit-test costs.
Instead, the element owns:

- the canonical cell list;
- row/column coordinate indexes;
- visible-range lookup;
- batched base-cell painting;
- a direct containment hit index;
- separate hover, focus, and selection overlays.

### Regular matrix fast path

For ordered regular rows and columns:

- binary-search visible row and column ranges;
- derive the visible rectangular cell window;
- paint only visible cells plus a one-cell overscan;
- map a pointer to row/column indexes directly.

### Sparse or irregular path

For sparse matrices:

- maintain ordered row and column indexes;
- query only cells intersecting visible coordinate ranges;
- use a compact cell-bound index for containment;
- preserve canonical source identity.

### Paint order

1. optional matrix background;
2. missing cells configured for painting;
3. visible measured cells;
4. borders;
5. readable labels;
6. hover/focus/selection overlays.

Base geometry and cell colours are cached separately from transient
interaction overlays. Hovering one cell must not rebuild every label or matrix
index.

## Bounds and layout

Cartesian data bounds include cell edges, not only cell centres. Bounds use
category bands, midpoint-derived numeric boundaries, or configured dimensions.
Measured values do not affect X/Y bounds; they affect only the colour domain.

Phase 1 permits exactly one Heatmap series per Cartesian chart plus normal
annotations. Ordinary Line/Scatter overlays and multiple Heatmap colour axes
remain Phase 2 until z-order, hit, legend, and scale ownership are explicit.

## Interaction

Phase 1 supports:

- pointer hover and touch tap by cell containment;
- durable cell selection with stable identity;
- tooltip and tracking rows containing X, Y, measured value, formatted
  category labels, and missing state;
- keyboard row/column traversal;
- activation and selection callbacks with typed Heatmap details;
- normal Cartesian zoom, pan, X/Y scrollbars, navigator, and annotations.

Tracking resolves a cell, not an interpolated value between cells. The
crosshair may align with the selected cell centre while the hover/selection
overlay covers the full cell.

## Accessibility

The chart must not publish one semantics node per cell for very large source
matrices. The accessibility contract is:

- the focused/selected/hovered cell is fully announced;
- arrow keys traverse logical rows and columns;
- the announcement includes series, row, column, value or missing, position,
  and selection state;
- colour is never the only meaning: table data, labels, tooltips, and
  semantics expose the numeric value;
- Data mode remains the complete accessible representation.

A configurable small-matrix threshold may expose all visible cells, but source
size alone must never create tens of thousands of semantics nodes.

## Animation

Entrance animation reveals cell opacity and optional scale in a deterministic
row, column, radial, or simultaneous order. Reduced motion and zero duration
render the target frame immediately.

Data updates match cells by stable identity and interpolate measured values
through the active colour scale. Coordinate changes are treated as remove/add
unless a future explicit move transition is added. Missing-to-value and
value-to-missing transitions use the configured missing colour and never
manufacture numeric values.

Artifacts and tables always expose canonical target data rather than in-flight
colours.

## Portable artifacts and Workbench

The Heatmap family is not complete until it supports:

- artifact extraction and hydration;
- capability negotiation for Heatmap cells and scale types;
- stable selected-cell identity;
- Chart, Data, Split, and Source modes;
- generated Dart that reconstructs the same chart;
- Workbench chart-family registration;
- fluent/grammar input and public exports.

### Data mode

Two projections are required:

- **Long:** one row per cell with X, Y, measured value, labels, identity, and
  missing state.
- **Matrix:** ordered row labels, ordered column labels, and cell values.

Long form is the canonical portable representation. Matrix mode is a view.
CSV export must preserve explicit missing cells and distinguish them from
absent sparse coordinates.

## Showcase requirements

The Heatmap guide must include materially different examples:

1. employee by weekday with readable values;
2. date by hour temperature matrix;
3. calendar/month layout;
4. dense time-series/lasagna matrix;
5. diverging correlation or confusion matrix;
6. sparse matrix with explicit missing cells.

The page is a real Workbench adoption with live controls for scale type,
palette, domain, midpoint, reversal, clamping, missing colour, gaps, borders,
labels, legend, theme, axes, zoom, and pan. It needs direct desktop and compact
routes plus representative Gallery and mobile examples.

## Performance contract

Reference workloads:

| Workload | Purpose |
|---|---|
| 1,000 cells | labelled interactive matrix |
| 10,000 cells | common dense matrix |
| 250,000 source cells with a small viewport | culling and index proof |

Required properties:

- visible work scales with visible cells, not total source cells;
- pointer hit lookup does not scan all source cells;
- hover invalidates transient overlays only;
- labels are skipped before text layout when unreadable;
- the normal warm path performs no per-cell widget allocation;
- performance evidence records build mode, device, source count, visible
  count, labels, borders, scale type, and p50/p95.

Concrete frame and hit-test budgets are set after the foundational benchmark
harness establishes a reproducible baseline. No release claim is made without
warm full-frame and cached-hit gates.

## Verification matrix

- model validation and identity;
- sequential/diverging/threshold colour mapping;
- automatic domains and missing values;
- categorical X and Y ordering;
- regular, sparse, and irregular geometry;
- cell-edge bounds and clipping;
- visible-cell culling;
- paint, label contrast, themes, and legends;
- containment hits, selection, keyboard, semantics, zoom, and pan;
- entrance and stable-identity update motion;
- artifact/hydration and malformed documents;
- long/matrix Data, CSV, Source, and generated-source compilation;
- Workbench mode persistence;
- compact/desktop route and release web build;
- 1k, 10k, and 250k-source performance workloads.

## Decisions fixed for implementation

- Public family name is Heatmap.
- One cell owns X, Y, and measured value.
- Canonical artifacts use a cell list.
- Missing is explicit; NaN is invalid.
- Category order is declared.
- Heatmap is a dedicated Cartesian series element.
- One top-level element does not become one element per cell.
- Phase 1 supports one Heatmap series per chart.
- Raw-observation binning is a Phase 2 transform, not implicit renderer work.
- Treemap, mosaic, bubble matrix, vector field, and map heat layer are separate
  families or compositions.

## Open implementation questions

These are reviewable implementation choices, not blockers to Slice 1:

- final public name of the reusable categorical-axis base contract;
- colour interpolation space used by the first gradient kernel;
- exact small-matrix threshold for expanded semantics;
- whether the first calendar adapter lives on the series or in showcase/data
  preparation.

