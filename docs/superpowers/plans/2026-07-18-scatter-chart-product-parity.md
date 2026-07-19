# Scatter Chart Product Parity — Implementation Plan

**Branch:** `feature/scatter-chart-product-parity`
**Design:** [Scatter Chart Product Parity — Design](../specs/2026-07-18-scatter-chart-product-parity-design.md)
**Status:** In progress — Phase 1 expressive marks

## Working rules

- Work in dependency order; do not build advanced styling on incorrect point
  geometry.
- Add a failing meaningful test before each correctness fix.
- Preserve original source indices through culling, aggregation, selection,
  table projection, and controller focus.
- Keep the Workbench family-neutral.
- Add each delivered configuration to artifacts and generated source in the
  same slice.
- Add every user-visible feature to the Scatter Lab selector as it lands.
- Refresh from `origin/master` before each new phase and after concurrent PRs
  merge.
- Keep the change local and reviewable before opening a PR.

## Phase 0 — Foundation and benchmark baseline

### 0.1 Correctness shield

- [x] Replace Scatter segment hit testing with marker-aware point hit testing.
- [x] Reject invalid coordinates in Scatter bounds, paint, label, hit, and data
      lookup paths.
- [x] Add unsorted-X and duplicate-coordinate regression coverage.
- [x] Add tests proving empty/invalid-only series have finite safe bounds.
- [ ] Remove placeholder Scatter integration assertions or replace them with
      tests that exercise real model/renderer behavior.

The fixed-size and per-point-sizing quickstarts now exercise real paint, hit,
bounds, and source-index behavior. Older cross-family placeholder files still
need separate replacement as their corresponding capabilities land.

### 0.2 Two-dimensional tracking

- [x] Define a plot-space pointer input for Scatter tracking without changing
      line/area X-tracking semantics.
- [x] Select the nearest Scatter point by Euclidean plot distance.
- [x] Add deterministic tie breaking and coincident-point behavior.
- [x] Respect per-series/multi-axis transforms.
- [x] Add standard, transposed, zoomed, and multi-axis tracking tests.

### 0.3 Viewport and spatial indexing

- [x] Introduce a Scatter point viewport/spatial index preserving source
      indices.
- [x] Cull non-visible points with marker-radius padding.
- [x] Route hits and nearest-point queries through indexed candidates.
- [x] Re-query safely after zoom, pan, resize, and per-series transform changes.
- [x] Add dense-series tests proving candidate work is bounded.

### 0.4 Paint performance

- [x] Establish current 1k/10k/100k paint and hit-test benchmarks.
- [x] Batch uniform circle markers where Flutter Canvas permits it.
- [x] Cache reusable paths for non-circle marker shapes in Phase 1.
- [x] Retain a correct per-point override fallback.
- [x] Avoid per-point `Paint` allocation on the uniform and grouped-style paths.

### 0.5 Scatter Lab foundation

- [x] Convert the existing Scatter detail page to the shared Workbench contract
      with Chart/Data/Split/Source.
- [x] Preserve Cohorts, Correlation, and Outliers.
- [x] Add Stress and Unsorted foundation presets.
- [x] Add point-count and series-count controls.
- [x] Add a clear raw-point count/effective-render summary.

### Phase 0 gate

- [x] Focused model, element, tracking, widget, and benchmark tests pass.
- [x] Package and example analysis pass.
- [x] Existing Line/Area/Bar interaction behavior is unchanged.
- [x] Direct Scatter route works in a release web build.
- [ ] Direct Scatter route works from a fresh debug bootstrap without a stale
      first frame.
- [x] Local dev server remains available for review.

## Phase 1 — Expressive marks and visual encodings

### 1.1 Marker API

- [x] Consolidate marker-shape definitions into an unambiguous public model.
- [x] Add public series-level circle, square, triangle, diamond, star, cross,
      plus, and none marker selection.
- [x] Add immutable `ScatterMarkerStyle` with validation and documentation.
- [x] Paint circle, square, diamond, triangle, inverted triangle, cross, plus,
      star, and none.
- [x] Add fill, stroke, stroke width, opacity, dimensions, and rotation.
- [x] Add per-point marker-shape and visual overrides.
- [x] Add interaction-state styling.
- [ ] Add golden tests at multiple sizes and device-pixel ratios.

`SeriesMarkerShape` is now the actual public series enum rather than an alias
over another hidden shape type. Marker shape and `ScatterMarkerStyle`
participate in series equality, paint geometry, precise hits, artifacts,
generated source, and the Shapes and Styling lab presets. Series and point
layers support fill, outline, opacity, independent dimensions, rotation, and
point-level shape exceptions. `ScatterInteractionStyle` now adds shape-aware
hover, press, selection, focus, and unselected feedback without invalidating
the cached base picture during pointer movement. Portable artifacts, hydration,
generated Dart, and the States showcase preset share the same configuration.
Multi-size and device-pixel-ratio goldens remain in this phase.

### 1.2 Bubble encoding

- [x] Add a typed third quantitative value or typed size accessor contract.
- [x] Map magnitude to marker area with configurable domains/radii.
- [x] Define null, zero, negative, clamping, and degenerate-domain behavior.
- [x] Add a size legend and tooltip values.
- [x] Preserve the raw size value in Data/Split/Source and artifacts.

`ChartDataPoint.magnitude` now remains quantitative source data while
`PointStyle.size` remains an explicit logical-pixel override. Optional
`ScatterSizeEncoding` maps the magnitude linearly in marker area, supports
fixed or derived domains, and clamps values to configurable radii. Bubble mode
omits null, non-finite, and negative values, keeps zero inspectable at the
minimum radius, and maps a degenerate domain to the midpoint area. Resolved
geometry drives paint, indexed hits, tooltips, and semantics. The portable
point and columnar artifact formats, binary sidecar, generated Dart, and native
table projection retain magnitude. A second native `LegendAnnotation` exposes
the quantitative size scale alongside the categorical series legend, and the
Bubble showcase uses representative market-opportunity data.

### 1.3 Color, opacity, shape, jitter, and labels

- [x] Add continuous color scales.
- [x] Add piecewise color scales.
- [x] Add quantitative opacity mapping.
- [ ] Add categorical shape/color mapping.
- [x] Add quantitative color legends.
- [ ] Add categorical color/shape legends.
- [ ] Add deterministic X/Y jitter with a stable seed.
- [ ] Add Scatter-specific label offsets and collision policies.
- [x] Add Shapes and Bubble lab presets.
- [x] Add a Color scale lab preset.
- [x] Add a Bands lab preset.
- [x] Add an Opacity lab preset.
- [ ] Add a Jitter lab preset.

`ChartDataPoint.colorValue` is now independent of bubble `magnitude`, allowing
one point to encode separate measures through area and color. Optional
`ScatterColorEncoding` resolves fixed or finite data-derived domains, clamps
outliers, interpolates continuously across multi-stop ramps, and falls back to
the normal point/series color for null or non-finite values. Explicit point
colors retain precedence. The value survives point/columnar artifacts, binary
sidecars, generated Dart, Data/Split tables, tooltips, tracking, and semantics.
A separate native `LegendAnnotation` carries the quantitative gradient key,
while the representative Athlete readiness preset exposes interchangeable
ramps without introducing a parallel legend or viewport layer.

Piecewise scales now share the same `ScatterColorEncoding` contract with
explicit, finite, strictly ordered thresholds. Threshold equality enters the
higher band, invalid configurations fall back to normal marker color, and
tracking pairs each raw value with its band name. The same portable
`LegendAnnotation` renders adjacent labelled segments, while the Equipment risk
map demonstrates four operational bands and interchangeable palettes without a
second legend subsystem.

`ChartDataPoint.opacityValue` now supplies a third independent quantitative
channel. Optional `ScatterOpacityEncoding` maps fixed or finite data-derived
domains into a clamped visual range, resolves degenerate domains to the
midpoint, and lets null/non-finite values inherit normal marker opacity.
Explicit point opacity retains precedence over the encoding. The value and
encoding survive inline/columnar artifacts, binary sidecars, generated Dart,
Data/Split tables, tooltips, tracking, and semantics. A first-class
`LegendOpacityScale` remains inside the existing native `LegendAnnotation`
architecture, and the Demand forecast confidence preset exposes a live
low-confidence opacity control.

### Phase 1 gate

- [ ] Public model, artifacts, source, AI schema, table, and showcase agree.
- [ ] Uniform and per-point styling paths meet benchmark expectations.
- [ ] Accessibility does not rely on color alone.

## Phase 2 — Exploration and linked selection

- [ ] Define point/rectangle/lasso selection configuration.
- [ ] Implement replace/add/subtract/toggle operations.
- [ ] Add selected, focused, and unselected styling.
- [ ] Return stable point references, extents, and summary statistics.
- [ ] Link chart selection to Workbench table focus/selection.
- [ ] Resolve selection-zoom gesture ownership explicitly.
- [ ] Add keyboard focus and accessible selection announcements.
- [ ] Add Brush and Lasso lab presets.
- [ ] Add interaction tests for pointer, touch, keyboard, zoom, pan, and updates.

## Phase 3 — Analysis and uncertainty

- [ ] Extend trend annotations with LOESS.
- [ ] Add equation, R-squared, sample count, Pearson, and Spearman options.
- [ ] Add confidence and prediction bands with documented assumptions.
- [ ] Add X/Y symmetric and asymmetric error bars.
- [ ] Add regression/uncertainty artifact and source round trips.
- [ ] Add Regression and Uncertainty lab presets.
- [ ] Verify statistics against fixed reference datasets.

## Phase 4 — Dense-data modes

- [ ] Define explicit points/clusters/hexbin/rect-bin/density render modes.
- [ ] Implement deterministic screen-space clustering without O(n²) scans.
- [ ] Add cluster labels, zones, tooltip summaries, and drill-to-cluster.
- [ ] Implement hexagonal and rectangular 2D aggregation.
- [ ] Support count/sum/mean/min/max/proportion aggregates.
- [ ] Implement density contours and legends.
- [ ] Preserve raw source projection in Data/Split/Source.
- [ ] Add Clusters, Hexbin, and Density lab presets.
- [ ] Benchmark 100k raw and 500k aggregated source points.

## Phase 5 — Composition, documentation, and release

- [ ] Add marginal histogram, density, and rug compositions.
- [ ] Add jittered strip and beeswarm compositions.
- [ ] Design Scatter matrix/small-multiple composition separately.
- [ ] Add Marginals showcase preset.
- [ ] Update API reference, chart-type guide, feature matrix, README, and
      changelog.
- [ ] Capture focused Scatter media for the public documentation surface.
- [ ] Run formatting, package tests, example tests, analysis, dartdoc, release
      web build, archive hygiene, and `git diff --check`.
- [ ] Record remaining performance/accessibility risks before release approval.

## Verification log

Record each completed slice here with commands, results, local route, and any
accepted deferrals. Do not mark a phase complete from showcase appearance
alone.

- 2026-07-18: Research completed. Current implementation, official-library
  capabilities, architectural dependencies, and release contract documented.
- 2026-07-18: Phase 0.1 started on current `origin/master` in the dedicated
  Scatter worktree.
- 2026-07-18: Correctness shield and the first spatial-index slice landed
  locally. Focused tests cover point-only hits, effective marker radii,
  invalid-only safety, unordered and coincident points, two-dimensional
  tracking, transposed transforms, viewport edge overlap, pan re-query, and a
  100k-point bounded-candidate scenario.
- 2026-07-18: Added the Stress and Unsorted Scatter Lab presets with 100 to
  100k points per series and one to six series. Cold 100k indexing measured
  17-19ms locally; repeated 100k viewport re-query measured 0.04-0.05ms
  average. The full package suite passed 1,960 tests, `flutter analyze lib` and
  `flutter analyze example/lib` passed, and the full-workspace analyzer's
  pre-existing vendored Fleather example dependency failures remain outside
  this slice.
- 2026-07-18: Live review route launched at
  `http://127.0.0.1:8101/?page=scatter-charts&preset=stress`. The showcase UI
  follows the existing Workbench hierarchy and density: the preset selector
  remains primary, stress-only controls use progressive disclosure, and
  Chart/Data/Split/Source keep raw inspection secondary to the visualization.
  Automated headless Chrome/Edge capture reached the debug bootstrap but
  returned Flutter's blank first frame; route health is confirmed with HTTP
  200 and the focused widget tests, while final visual review remains a manual
  browser checkpoint.
- 2026-07-19: Refreshed to `origin/master` at `8915aeef` and resolved the
  concurrent line-forecast showcase change. Fixed Scatter marker-radius
  updates by making the explicit series radius beat theme defaults and by
  including marker geometry in `ScatterChartSeries` equality. Uniform markers
  now use one `Canvas.drawPoints` batch; isolated paint averages were 0.274ms
  for 1k, 0.162ms for 10k, and 1.343ms for 100k points. Added series-level
  circle, square, triangle, diamond, star, cross, plus, and none shapes with
  shape-aware hits, artifact/source round trips, and a Shapes lab preset. The
  full package suite passed 2,001 tests and library/example analysis passed.
  A release-mode browser capture verified the live Shapes route on port 8101.
- 2026-07-19: Added the immutable `ScatterMarkerStyle` override layer with
  fill, outline, outline width, opacity, width, height, and clockwise rotation.
  The same style can override an individual datum through
  `PointStyle.scatterMarkerStyle`; legacy radius, shape, point color, and point
  size remain compatible fallbacks. Paint, culling, spatial hits, portable
  artifacts (`series.scatter.marker-style.v1`), hydration, and generated Dart
  now share the style. A progressive Styling preset exposes only the relevant
  advanced controls. Focused renderer, artifact, source, and showcase tests
  passed before the broader release check. The completed gate passed 2,007
  package tests, 165 example tests, package/example analysis, and the release
  web build. Isolated 100k measurements remained bounded at 19.121ms cold
  indexing, 0.048ms average viewport queries, and 1.283ms average uniform
  marker paint. The final Styling route was browser-captured from the release
  build and remains available on port 8101.
- 2026-07-19: Replaced the public `SeriesMarkerShape` alias with an explicit
  series-shape enum, added the missing inverted-triangle silhouette, and added
  portable point-level shape overrides through `PointStyle`. Paint, precise
  hits, artifacts, generated source, the Shapes catalogue, and the Styling
  preset now agree on the effective shape. Focused renderer, artifact, source,
  and showcase tests passed, followed by package/example analysis and a
  release web build for visual review on port 8101.
- 2026-07-19: Added immutable `ScatterInteractionStyle` feedback for hover,
  press, durable selection, linked focus, and dimmed unselected points. Hover
  and press paint in the uncached overlay; selection and focus reuse stable
  point identities and effective marker geometry. The portable artifact
  capability is `series.scatter.interaction.v1`, with fail-closed range
  validation and direct generated-Dart support. The States preset provides
  controller-backed Select, Focus, and Clear actions plus scoped controls for
  selection scale, unselected opacity, and focus gap. Renderer, codec, source,
  and showcase tests passed; the complete package suite passed 2,014 tests and
  the complete example suite passed 167 tests. Package/example analysis and a
  release web build passed. The idle 100k-point fast path remained bounded at
  29.142ms cold indexing, 0.059ms average viewport query, and 2.185ms average
  uniform-marker paint in this run. The release States route was captured and
  remains available on port 8101.
- 2026-07-19: Completed Phase 1.2 Bubble encoding. Added typed point
  `magnitude`, immutable `ScatterSizeEncoding`, area-correct radius mapping,
  explicit invalid/zero/clamp/degenerate rules, geometry-aware indexed hits,
  tooltip and semantic values, a quantitative size key, and the Market
  opportunity Bubble preset with live minimum/maximum radius controls. Inline
  point, inline columnar, binary sidecar, hydration, generated source, and
  Data/Split table projections preserve the third metric. Focused renderer,
  artifact, source, table, legend, and showcase tests passed. The sequential
  full package suite passed 2,022 tests, the full example suite passed 168
  tests, package/example analysis passed, and the release web build is served
  on port 8101. One 120k Bar mount benchmark failed only while both full suites
  competed concurrently; it passed in isolation at 724ms and passed again in
  the sequential package suite.
- 2026-07-19: Corrected the Bubble review surface after visual inspection. The
  scale uses the representative 95-600 account domain and explicitly names
  bubble area. The chart summary explains all four visual channels, point
  labels identify markets without duplicating values, and discrete Scatter
  tracking exposes point identity, X, Y, and formatted magnitude. The initial
  standalone widget prototype was then removed: `LegendAnnotation` now
  supports a portable quantitative size key and `BravenChartPlus`
  auto-generates it as a second native legend element. Categorical and
  quantitative legends are independently positioned in the canvas, share
  `LegendStyle`, participate in artifact/source output, and obey the existing
  `showLegend` switch. The refactor passed all 2,027 package tests, all 168
  example tests, package/example analysis, generated-source compilation, and a
  release web build; the visually checked route remains on port 8101.
- 2026-07-19: Completed piecewise quantitative color. `ScatterColorEncoding`
  now resolves explicit ordered thresholds with higher-band equality semantics,
  portable labels, fail-closed validation, and logarithmic band lookup. Native
  `LegendAnnotation` color scales render labelled adjacent segments and retain
  artifact/source portability. The representative Equipment risk Bands preset
  exposes three working palettes. All 2,051 package tests and 175 example tests,
  scoped analysis, generated-source compilation, and the release web build
  passed. The visually checked Bands route is served on port 8101.
- 2026-07-19: Completed quantitative opacity mapping. Added independent
  `opacityValue`, typed `ScatterOpacityEncoding`, explicit point-over-encoding
  precedence, clamped and degenerate domain behavior, native tracking/tooltip/
  semantic values, full artifact/source/table portability, and a first-class
  `LegendOpacityScale` within `LegendAnnotation`. The Demand forecast
  confidence preset demonstrates two forecast models and exposes a working
  low-confidence opacity control. The release gate passed all 2,108 package
  tests and all 194 example tests, package/example analysis, generated-source
  compilation, and the release web build. The visually checked Opacity route
  is served on port 8101.
