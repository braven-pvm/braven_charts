# Scatter Chart Product Parity — Design

**Status:** Accepted for implementation
**Branch:** `feature/scatter-chart-product-parity`
**Scope:** Strengthen the existing Cartesian Scatter family from renderer
foundation through expressive marks, exploration, analysis, dense-data modes,
Workbench parity, and public showcase coverage.

## Product objective

Make Scatter charts a first-class analytical family rather than a collection
of uniformly painted circles. The finished family must support:

- precise two-dimensional inspection and selection;
- categorical and quantitative visual encodings;
- bubble, uncertainty, regression, and density workflows;
- large datasets without silently changing source semantics; and
- the same Chart/Data/Split/Source, artifact, source-generation, accessibility,
  motion, documentation, and release guarantees as other built-in families.

## Current baseline

`ScatterChartSeries` currently adds only `markerRadius` to the shared Cartesian
series model. `PointStyle` can override color and size, but the renderer paints
filled circles only. The implementation also inherits assumptions that are
appropriate for ordered line data but not arbitrary two-dimensional samples:

- series hit testing measures distance to invisible segments between points;
- tracking snaps by X through an ordered-data binary search;
- bounds and painting do not consistently reject non-finite points;
- every point is transformed and painted even when outside the viewport; and
- several nominal Scatter integration tests contain placeholder assertions.

These are release blockers for advanced Scatter features. Marker styling,
lasso selection, clustering, and regression must build on point-accurate
geometry and meaningful tests.

## Design principles

### Preserve the source model

Raw source points remain available in Data, Split, Source, copy, CSV, and
artifacts even when the renderer displays clusters, bins, or density. Derived
marks never replace or mutate the mounted document.

### Make aggregation explicit

The chart exposes whether it is rendering points, clusters, bins, or density.
Automatic recommendations may be offered, but the UI, legend, tooltip, and
generated source must disclose the effective mode and aggregation.

### Treat Scatter as genuinely two-dimensional

Pointer proximity, crosshair inspection, brush selection, lasso selection,
and keyboard focus use plot-space X and Y distance. X-only tracking remains a
line/area behavior and is not reused for unordered Scatter samples.

### Prefer deterministic rendering

Jitter, cluster layout, point identity, animation matching, label collision,
and derived statistics must produce stable output for the same inputs. Random
layout changes between paints are not acceptable.

### Protect the dense-data path

Uniform marks use batched or cached geometry. Per-point styling remains
available through an explicit slower path. Arbitrary widgets per point are not
part of the core renderer because they prevent batching and predictable frame
cost.

### Keep Workbench family-neutral

Scatter-specific semantics are represented in the mounted document, series,
table projection, and generated source. `BravenChartWorkbench` continues to
consume the effective document through `BravenChartController` without
hard-coded Scatter rules.

## Product capabilities

### 1. Foundation and precision

- Reject non-finite points consistently in bounds, rendering, labels, hits,
  crosshair values, selection, trends, and density transforms.
- Add point-accurate Scatter hit testing; never hit invisible connecting
  segments.
- Add true two-dimensional nearest-point tracking with stable tie breaking for
  coincident points.
- Cull off-viewport points before transformation, painting, labels, and hits.
- Introduce a reusable point viewport/spatial index that preserves original
  source indices for controller focus and table linkage.
- Establish stable point identity for selection and data-update motion.
- Add uniform-marker batching with a per-point-style fallback.

### 2. Expressive marker system

- Consolidate the existing marker-shape concepts behind one public Scatter
  marker style instead of creating another unrelated enum.
- Support circle, square, diamond, triangle, inverted triangle, cross, plus,
  star, and no-marker shapes where meaningful.
- Support fill, stroke, stroke width, opacity, width, height, radius, and
  rotation with series defaults and per-point overrides.
- Support selected, hovered, focused, and unselected appearance states.
- Add deterministic render-only X/Y jitter with a stable seed.
- Add point labels with explicit offsets and collision policies.

### 3. Bubble and visual encoding

- Add a typed quantitative size value and area-based size mapping.
- Support explicit size domain, minimum/maximum radius, clamping, and policies
  for null, zero, and negative values.
- Add size legends.
- Map numeric dimensions to continuous or piecewise color and opacity scales.
- Map categorical dimensions to color and shape.
- Preserve raw values in table/source output and disclose derived scales.

### 4. Exploration and selection

- Add point, rectangle-brush, and freeform-lasso selection.
- Support replace, add, subtract, and toggle selection operations.
- Dim or restyle unselected points without mutating series colors.
- Return stable point references, selected data extents, and summary statistics.
- Link chart selection to Workbench table focus/selection.
- Keep selection zoom and brush selection as explicit, non-conflicting modes.
- Provide keyboard focus traversal and semantics for manageable point counts;
  provide aggregate semantics for dense modes.

### 5. Analysis and uncertainty

- Extend the trend infrastructure with linear, polynomial, and LOESS fits.
- Optionally display equation, sample count, R-squared, Pearson correlation,
  and Spearman rank correlation.
- Support confidence and prediction bands with documented assumptions.
- Support forward/backward fit extent.
- Add symmetric and asymmetric X and Y error bars.
- Compose quadrants, reference regions, and outlier emphasis through the
  annotation system rather than duplicating annotation geometry.

### 6. Dense-data rendering

- Raw points with viewport culling and marker batching.
- Screen-space clusters with count labels, zones, tooltip summaries, and
  drill-to-cluster.
- Hexagonal and rectangular 2D bins.
- Count, sum, mean, min, max, and proportion aggregates.
- Density contours for severe overplotting.
- Explicit effective-render-mode metadata for tooltips, legends, artifacts,
  source generation, and accessibility.

### 7. Analytical compositions

- Marginal X/Y histograms, densities, and rugs.
- Jittered strip and beeswarm presentations for discrete dimensions.
- Scatter matrix and coordinated small multiples as composition widgets rather
  than additional `ScatterChartSeries` paint modes.
- Connected Scatter remains a Line + Scatter composition.

## Public model direction

Exact names can be refined during implementation, but responsibilities should
remain separated:

- `ScatterMarkerStyle`: marker geometry and paint.
- `ScatterVisualEncoding`: quantitative/categorical channels and legends.
- `ScatterJitterConfig`: deterministic displacement.
- `ScatterSelectionConfig`: point/brush/lasso interaction and state styling.
- `ScatterRenderMode`: points, clusters, hexbin, rectangular bins, density.
- `ScatterDensityConfig` / `ScatterClusterConfig`: derived-mark behavior.
- existing `TrendAnnotation`: regression/LOESS and statistical presentation.
- existing point identity/controller contracts: portable selection references.

All portable properties must participate in equality, `copyWith`, validation,
artifact encode/decode, hydration, source generation, table projection when
applicable, AI configuration, runtime descriptors, and public exports.

## Scatter Lab contract

The public Scatter detail page becomes a progressive lab with these presets:

`Cohorts · Shapes · Bubble · Color scale · Jitter · Brush · Lasso ·
Regression · Uncertainty · Clusters · Hexbin · Density · Marginals · Stress`

Controls should include point count, series count, marker shape and size,
opacity, size/color encoding, jitter, interaction mode, trend type, error bars,
bin width, cluster threshold, and render mode. Every new capability must appear
in the selector when it lands.

## Performance and quality budgets

Performance gates are measured rather than inferred:

- 10k raw points: interactive hover, zoom, and pan on the standard Canvas path.
- 100k raw points: benchmark viewport culling, batching, hit queries, and
  allocation pressure; document any interaction trade-offs.
- 500k source points: demonstrate an explicit aggregated mode without losing
  source-table fidelity.
- Point lookup should scale with visible/candidate points rather than total
  series length after the spatial index is established.
- Repaints must not allocate a paint object per point on the uniform path.

Required coverage includes pure geometry tests, renderer tests, widget
interaction tests, multi-axis tests, zoom/pan tests, artifact/source round-trip
tests, deterministic showcase tests, benchmarks, and release-web verification.

## Delivery phases

1. **Foundation:** correctness, indexing, culling, batching, tests, benchmark
   harness, and the initial Scatter Lab stress preset.
2. **Marks and encodings:** marker system, bubble sizing, color/opacity/shape
   channels, legends, jitter, and labels.
3. **Exploration:** brush, lasso, linked selection, keyboard and semantics.
4. **Analysis:** regression, LOESS, statistics, confidence bands, error bars.
5. **Density:** clusters, hexbin, rectangular bins, contours, adaptive advice.
6. **Composition and release:** marginals, strip/beeswarm, documentation,
   accessibility, media, full release gate.

### Implementation status — 2026-07-20

| Phase | Status | Remaining gate |
|---|---|---|
| 1. Foundation | Ready | Keep benchmark thresholds under release review. |
| 2. Marks and encodings | Ready | Maintain codec and artifact round-trip coverage as APIs evolve. |
| 3. Exploration | Ready | Complete the final accessibility audit with the release gate. |
| 4. Analysis | Ready | Complete the final documentation and source-generation audit. |
| 5. Density | Review needed | Audit adaptive-mode advice and disclosure; complete the density performance gate. |
| 6. Composition and release | In progress | Viewport-linked histogram, KDE density, rug, and combined marginals are implemented locally. Strip/beeswarm, docs, media, accessibility, and the full release gate remain. |

The next delivery order is: finish the marginal family, add strip/beeswarm as
composition widgets, close the Phase 5 adaptive-disclosure audit, then run the
cross-surface release matrix and performance gate.

## Deferred and excluded

- 3D Scatter is a separate chart family and is not part of this roadmap.
- Arbitrary Flutter widgets per point are excluded from the core Canvas path.
- Non-deterministic jitter is excluded.
- Naive pairwise O(n²) clustering is excluded.
- Decorative pulsing/effect markers are deferred until reduced-motion and
  accessibility behavior can be justified.
- Automatic aggregation that is not disclosed to the user is excluded.

## Completion definition

Scatter parity is complete only when the public API, renderer, interactions,
portable document, source generation, table views, Workbench modes, AI schema,
showcase route, guides, feature matrix, benchmarks, and release checks agree on
the supported behavior. A visually working showcase alone is not completion.
