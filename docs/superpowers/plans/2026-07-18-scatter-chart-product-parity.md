# Scatter Chart Product Parity — Implementation Plan

**Branch:** `feature/scatter-chart-product-parity`
**Design:** [Scatter Chart Product Parity — Design](../specs/2026-07-18-scatter-chart-product-parity-design.md)
**Status:** In progress — Phase 4 density contours complete; cluster drill-down remains

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
- [x] Add categorical shape/color mapping.
- [x] Add quantitative color legends.
- [x] Add categorical color/shape legends.
- [x] Add deterministic X/Y jitter with a stable seed.
- [x] Add Scatter-specific label offsets and collision policies.
- [x] Add Shapes and Bubble lab presets.
- [x] Add a Color scale lab preset.
- [x] Add a Bands lab preset.
- [x] Add an Opacity lab preset.
- [x] Add a Categories lab preset.
- [x] Add a Jitter lab preset.

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

`ChartDataPoint.categoryValue` now carries an independent categorical field.
Optional `ScatterCategoryEncoding` maps configured category keys to color,
shape, or both, while explicit point styling retains precedence over the
encoding. Category values and labels survive artifacts, binary sidecars,
generated Dart, Data/Split tables, CSV export, tooltips, tracking, semantics,
and precise hits. A native `LegendCategoryScale` remains inside the existing
`LegendAnnotation` architecture and filters its entries to categories present
in the rendered series. The Fleet operating profile preset demonstrates three
powertrains through both color and silhouette within one Scatter series, so
the categorical field is not simulated by creating separate series.

Optional `ScatterJitterConfig` now applies deterministic logical-pixel X/Y
displacement after data-to-plot transformation. Raw coordinates, axis bounds,
tables, exports, tooltips, and tracking values remain exact, while paint,
precise hits, focus/selection geometry, and crosshair anchors share the same
jittered center. A stable series-id, source-index, and seed hash keeps offsets
unchanged across repaint, pan, zoom, artifact hydration, and generated source.
Viewport queries expand by the configured pixel amplitudes without disabling
the existing 2D index or uniform-marker batch path. The Support survey Jitter
preset exposes independent horizontal/vertical spread and a layout seed over
repeated integer responses.

Scatter now reuses the portable `DataPointLabelConfig` contract with an
explicit point-label content mode, four marker-relative anchors, marker gap,
independent X/Y offsets, plot-edge awareness, and `none`, `hide`, or
`reposition` collision policies. One chart-wide grid coordinator resolves
labels across every Scatter series, so collisions are not hidden inside
per-series paint passes and candidate placement remains bounded. The exact
configuration survives artifacts, generated Dart, and Workbench Data/Split
round trips. The Customer expansion candidates Labels preset exposes the
anchor, overlap policy, and offsets against representative named accounts.

### Phase 1 gate

- [ ] Public model, artifacts, source, AI schema, table, and showcase agree.
- [ ] Uniform and per-point styling paths meet benchmark expectations.
- [ ] Accessibility does not rely on color alone.

## Phase 2 — Exploration and linked selection

- [x] Define point/rectangle/lasso selection configuration.
- [x] Implement replace/add/subtract/toggle operations.
- [x] Add selected, focused, and unselected styling.
- [x] Return stable point references, extents, and summary statistics.
- [x] Link chart selection to Workbench table focus/selection.
- [x] Resolve selection-zoom gesture ownership explicitly.
- [x] Add keyboard focus and accessible selection announcements.
- [x] Add Brush and Lasso lab presets.
- [x] Add interaction tests for pointer, touch, keyboard, zoom, pan, and updates.

`ChartSelectionConfig` now provides one portable interaction policy for point,
rectangle, and lasso acquisition, set operations, background clearing, and
platform modifier overrides. Direct Scatter taps resolve the canonical
renderer-neutral `ChartDataHit`, so selection identity matches precise hits,
jittered marker geometry, tooltips, and durable `ChartPointRef` state. Point
mode implements replace, add, subtract, and toggle. Rectangle and lasso reuse
the indexed rendered-marker geometry for bounded live previews, then commit one
atomic set operation through the same durable point-reference and statistics
contract. Account portfolio Selection, Brush, and Lasso presets expose these
three acquisition modes with shared operation, styling, controller, Data/Split,
and Source behavior.
Manageable Scatter sets now use true plot-direction arrow traversal and
Enter/Space activation through the same durable selection policy. One
chart-level live semantic node announces the focused point's series, label, X,
Y, visual-encoding values, ordinal, and selected state. Datasets above 200
valid points deliberately expose an aggregate point/series summary instead of
allocating a semantic node per mark; their arrow keys retain viewport-pan
ownership.

The closing interaction matrix now drives the same point identity through
mouse, touch, and keyboard activation; exercises touch rectangle and lasso
acquisition; and proves that Shift-wheel zoom and middle-drag pan preserve
durable focus, selection, and statistics. Data replacement retains valid
references while republishing their current source values and aggregates, and
data removal prunes invalid focus/selection from both the controller and host
callbacks after the frame. Phase 2 is complete.

## Phase 3 — Analysis and uncertainty

- [x] Extend trend annotations with LOESS.
- [x] Add equation, R-squared, sample count, Pearson, and Spearman options.
- [x] Add confidence and prediction bands with documented assumptions.
- [x] Add X/Y symmetric and asymmetric error bars.
- [x] Add regression/uncertainty artifact and source round trips.
- [x] Add Regression and Uncertainty lab presets.
- [x] Verify statistics against fixed reference datasets.

`TrendAnnotation` now supports robust LOESS with a bounded neighborhood span,
zero to ten Tukey-bisquare robustness passes, and configurable curve sampling.
The deterministic fitter sorts unordered finite data, handles duplicate X
values, rejects vertical-only domains, and evenly caps dense fitting input at
2,048 points before local regression. The existing annotation renderer,
selection/hit path, native editor, portable artifact codec, and generated Dart
source all use the same model. The Campaign frequency response Regression
preset compares the nonlinear robust fit with a dashed linear reference and
exposes concise neighborhood, robustness, and curve-detail controls.

`TrendAnnotation` also exposes independent equation, R-squared, sample-count,
Pearson, and Spearman display options. One native trend diagnostics card keeps
the selected details attached to the fitted curve; parametric equations are
limited to linear and polynomial fits, while R-squared uses the rendered fit
and both correlations use finite source observations. Spearman ranks use
average ranks for ties. The native editor, artifact codec, generated Dart, and
Regression preset share the same opt-in fields.

Linear `TrendAnnotation` fits can now render a mean-response confidence band
and a wider future-observation prediction band at 90%, 95%, or 99% coverage.
The shared calculator uses ordinary least squares with Student-t critical
values and documents its assumptions: an independent linear mean response,
constant residual variance, approximately normal residuals, and fixed X
values. The native editor, artifact codec, generated Dart, renderer, and fixed
reference tests all use that one contract.

`ErrorBarAnnotation` adds independent negative and positive magnitudes on both
X and Y, so symmetric and asymmetric measurement uncertainty remains separate
from source observations. Statistical overlays participate in automatic axis
bounds while explicit caller-supplied bounds remain authoritative. The Assay
calibration Uncertainty preset composes both interval families with portable
X/Y error bars and concise live controls. Phase 3 is complete.

## Phase 4 — Dense-data modes

- [x] Define explicit points/clusters/hexbin/rect-bin/density render modes.
- [x] Implement deterministic screen-space clustering without O(n²) scans.
- [ ] Add cluster labels, zones, tooltip summaries, and drill-to-cluster.
- [x] Implement hexagonal and rectangular 2D aggregation.
- [x] Support count/sum/mean/min/max/proportion aggregates.
- [x] Implement density contours and legends.
- [x] Preserve raw source projection in Data/Split/Source.
- [x] Add Clusters, Hexbin, and Density lab presets.
- [x] Benchmark 100k raw and 500k aggregated source points.

`ScatterRenderMode.density` now builds a deterministic plot-space histogram,
applies separable Gaussian smoothing, normalizes the visible field, and traces
two to twelve clipped isolines with marching squares. Bandwidth, sample-grid
precision, contour count, outer threshold, opacity range, line width, and raw
point overlay are all explicit `ScatterDensityConfig` values. A density-region
hit reports the local relative density, source-point identities, and raw-data
centroid through the existing `ChartDataHit`, tooltip, crosshair, semantics,
and selection contracts. The existing native `LegendAnnotation` supplies the
relative-density opacity key. Artifact hydration, generated Dart, AI schema,
Data/Split/Source, a Density Workbench preset, and a 500k-point benchmark share
the same configuration without adding a parallel viewport or legend system.

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
- 2026-07-19: Completed categorical color and shape mapping. Added independent
  `categoryValue`, typed `ScatterCategoryEncoding`, explicit point-first
  precedence, category-aware hits/tracking/tooltips/semantics, and full
  point/columnar/binary/artifact/source/table portability. The existing native
  `LegendAnnotation` now supports a portable `LegendCategoryScale`; no parallel
  legend or viewport layer was introduced. The Fleet operating profile uses
  one series and maps 3 powertrains through both color and silhouette. The
  release gate passed all 2,112 package tests and all 197 example tests,
  package/example analysis, generated-source compilation, and the release web
  build. The visually checked Categories route is served on port 8101.
- 2026-07-19: Completed deterministic plot-space jitter. Added immutable
  `ScatterJitterConfig`, independent logical-pixel X/Y amplitudes, a stable
  series/source-index seed hash with byte mixing to avoid adjacent-index
  correlation, jitter-aware viewport padding, canonical
  paint/hit/focus/crosshair geometry, artifact hydration, and generated Dart.
  The Support survey preset exposes horizontal spread, vertical spread, and
  layout seed over 36 repeated integer responses while Data and tracking retain
  the raw scores. The release gate passed all 2,116 package tests and all 199
  example tests, package/example analysis, generated-source compilation, and
  the release web build. The 100,000-point jittered viewport benchmark averaged
  0.043 ms versus 0.057 ms without jitter in the focused run, and 100,000
  uniform markers retained the batched 1.344 ms average paint path.
- 2026-07-19: Completed Scatter point-label layout. Extended the shared
  `DataPointLabelConfig` with portable point text, marker-relative anchors,
  marker gap, X/Y offsets, edge awareness, and explicit collision policies.
  A chart-wide spatial-grid coordinator now repositions or hides collisions
  across multiple Scatter series while paint still uses the canonical jittered
  marker geometry. Artifacts, source generation, and Workbench round trips
  retain the exact configuration. The Customer expansion candidates Labels
  preset exposes the full workflow. The release gate passed all 2,122 package
  tests and all 200 example tests plus package/example analysis. The 5,000-label
  full-suite benchmark averaged 10.480 ms with only 3,749 exact comparisons.
- 2026-07-19: Began Phase 2 with a portable chart-selection policy and working
  Scatter point operations. `ChartSelectionConfig` defines point, rectangle,
  and lasso acquisition plus replace, add, subtract, toggle, background-clear,
  and standard modifier behavior. Direct Scatter activation now resolves
  canonical `ChartDataHit` identity and updates the existing durable controller,
  rendering, artifact, generated-source, AI, and Workbench state. The Account
  portfolio selection preset exposes only implemented point behavior. The
  independently run release gate passed all 2,130 package tests and all 201
  example tests with clean package/example analysis; separating the suites
  avoids resource contention in the package performance benchmarks.
- 2026-07-19: Completed the durable Scatter state-styling slice. The existing
  shape-aware selection backing/ring, independent focus outline, and
  unselected opacity now have independent pixel-level renderer regressions.
  `ScatterInteractionStyle.copyWith` supports immutable customization and
  explicit restoration of inherited hover, selection, and focus colors. The
  Selection preset drives selection scale, ring width, unselected opacity, and
  focus-ring gap through the actual series style, so direct point selection
  exposes the same portable configuration demonstrated by the earlier States
  preset. The sequential release gate passed all 2,133 package tests and all
  201 example tests, package/example library analysis, and the release web
  build. The reviewed Selection route remains available on port 8101.
- 2026-07-19: Added the canonical `ChartSelectionResult` runtime contract.
  Results retain deterministic series/source-index `ChartPointRef` ordering,
  pair every reference with its source datum and series name, and expose X/Y
  extents. `ChartSelectionStatistics` includes point and series counts,
  finite count/min/max/sum/mean summaries for X, Y, magnitude, color value,
  and opacity value, plus category frequencies. The new
  `onSelectionResultChanged` callback and `BravenChartController.selectionResult`
  publish the same value while the legacy raw-point callback remains intact.
  The Selection preset adds one quiet, wrapping X/Y summary below its count.
  After fast-forwarding the 2 concurrent Concentric showcase commits, the
  sequential release gate passed all 2,138 package tests and all 205 example
  tests, package/example library analysis, and the release web build.
- 2026-07-19: Completed exact Scatter-to-Workbench row linking. The Scatter
  showcase now requests the lossless long table projection, so one directly
  selected marker maps to one selected Data/Split row instead of becoming a
  partial selection inside a shared wide row. A real pointer-selection widget
  regression follows the selected `ChartPointRef` through the mounted chart
  controller into the Workbench table and verifies the row's selected
  semantics. The growing Scatter preset catalogue now also uses the shared
  compact wrapping-choice pattern instead of clipping horizontally.
- 2026-07-19: Made selection-versus-viewport gesture ownership explicit.
  `ChartSelectionDragActivation` now reserves either primary drag or
  Shift+primary drag for drag-capable selection modes, while point mode remains
  tap-only. Empty point-mode drags no longer enter the legacy box-selection
  path or clear durable point state; rectangle mode claims only its configured
  chord. Middle-drag pan and Shift+wheel zoom retain their existing viewport
  ownership. The policy round-trips through interaction artifacts, generated
  Dart, and AI configuration, with renderer regressions for neutral point
  drags and modifier-gated rectangle drags. Lasso rendering remains correctly
  deferred to the dedicated Brush/Lasso slice. The sequential release gate
  passed all 2,142 package tests and all 207 example tests, clean package and
  example analysis, and a release web build for the port-8101 review route.
- 2026-07-19: Added bounded Scatter keyboard navigation and accessible
  selection announcements. For charts with at most 200 valid points, arrow
  keys traverse the nearest mark in the requested plot-space direction, so
  transformed and jittered geometry remains authoritative; Enter/Space applies
  the existing replace/add/subtract/toggle policy. The focused point uses a
  live chart-level semantic value containing series, label, X, Y, encoded
  metrics, ordinal, and selected state, with assistive activation and
  increment/decrement actions. Larger datasets expose one aggregate
  point/series summary and retain arrow-key viewport panning instead of
  allocating semantic nodes per mark. The Selection preset documents the
  keyboard path and feature coverage. The sequential release gate passed all
  2,144 package tests and all 207 example tests, clean package/example
  analysis, and the release web build for port 8101.
- 2026-07-19: Completed rectangle Brush and free-form Lasso acquisition.
  Both modes reuse the rendered Scatter marker-cell index for bounded live
  previews, respect jittered/transformed marker centers, and commit one atomic
  replace/add/subtract/toggle operation through the existing durable
  `ChartPointRef`, controller, statistics, table, artifact, and generated-source
  contract. The renderer draws native box or polygon overlays without adding a
  parallel viewport layer. Dedicated wrapped Workbench presets share the
  representative account portfolio data and expose concise mode-specific
  gesture guidance. The sequential release gate passed all 2,146 package tests
  and all 208 example tests, clean package/example analysis, and the release
  web build for the Brush and Lasso routes on port 8101.
- 2026-07-19: Closed Phase 2 with a mounted interaction matrix covering mouse,
  touch, keyboard, Shift-wheel zoom, middle-drag pan, and live data updates.
  The matrix exposed and fixed a durable-state defect: selected references
  remained valid after a data replacement, but their controller statistics and
  host result callback retained the previous source values. Rebuilds now
  republish changed results after the frame, retain current valid identities,
  and prune removed focus/selection consistently. The sequential release gate
  passed all 2,151 package tests and all 208 example tests, clean package and
  example analysis, `git diff --check`, and the release web build. Selection,
  Brush, and Lasso routes return HTTP 200 from the port-8101 review server.
  Roadmap progress is 64/94 overall and 9/9 for Phase 2; Phase 3 analysis and
  uncertainty is next.
- 2026-07-19: Opened Phase 3 with robust LOESS trend annotations. The public
  model exposes bounded neighborhood span, robustness passes, and curve detail;
  the renderer uses deterministic local-linear tricube fits with Tukey
  bisquare reweighting and a 2,048-point input cap. Native editing, artifacts,
  generated Dart, and the Campaign frequency response Regression preset all
  share that contract. Fixed reference, renderer, codec, source, editor,
  showcase, and 100k-source benchmark coverage passed; the dense fit completed
  in 59.211 ms. The sequential release gate passed all 2,160 package tests and
  all 209 example tests, clean package/example analysis, `git diff --check`,
  and the release web build. The Regression route returns HTTP 200 from the
  port-8101 review server. Roadmap progress is 65/94 overall and 1/7 for Phase
  3; equation and correlation statistics are next.
- 2026-07-19: Added a deterministic Scatter point-generator lab for repeatable
  visual and interaction testing. Its dedicated Generator preset controls the
  distribution, points per cohort, cohort count, horizontal and vertical
  spread, positive or negative correlation, outlier rate, and seed. Generated
  cohorts remain bounded and X ordered, and every control rebuilds the same
  real chart, Data, Split, and Source surfaces. Generator reference tests and
  mounted-control coverage passed with all 213 example tests, clean example
  analysis, `git diff --check`, and the release web build. The Generator route
  returns HTTP 200 from port 8101. Checklist progress remains 65/94 overall and
  1/7 for Phase 3.
- 2026-07-19: Added portable trend diagnostics for equation, R-squared, sample
  count, Pearson correlation, and Spearman rank correlation. One bounded native
  annotation card groups the requested values beside the fitted line, with
  compact editor chips and independent Regression-preset toggles. Fixed linear,
  inverse, tied-rank, degenerate, and non-finite reference datasets verify the
  calculations. Artifact and generated-source round trips preserve every
  option. The sequential release gate passed all 2,168 package tests and all
  213 example tests with clean package/example analysis. Checklist progress is
  66/94 overall and 2/7 for Phase 3; confidence and prediction bands are next.
- 2026-07-19: Completed Phase 3 with native OLS mean-confidence and
  future-prediction bands plus symmetric or asymmetric X/Y error bars. The
  Student-t interval calculator documents its linearity, independence,
  constant-variance, normal-residual, and fixed-X assumptions and matches a
  fixed reference dataset. Both uncertainty families survive annotation
  artifacts and generated Dart, and the native trend editor exposes 90%, 95%,
  and 99% coverage. Statistical geometry expands automatic axes without
  overriding explicit limits. The representative Assay calibration preset
  keeps its native legend clear of the highest interval and exposes live band,
  coverage, axis, symmetry, and magnitude controls. The release gate passed
  all 2,176 package tests and all 214 example tests, clean package/example
  analysis, `git diff --check`, a Wasm-compatible release web build, HTTP 200,
  and a browser screenshot from the port-8101 route. Roadmap progress is 71/94
  overall and 7/7 for Phase 3; Phase 4 dense-data modes is next.
- 2026-07-20: Completed the Phase 3 uncertainty presentation pass without
  introducing a parallel legend system. `LegendAnnotation` now derives and
  renders the observed Scatter marker, fitted trend, capped X/Y measurement
  error glyph, mean-confidence band, and future-prediction band from the native
  series and annotation models. The uncertainty key lays out horizontally when
  space permits and stacks inside narrow plots. The Assay preset also names the
  visual encodings in its summary and uses a vertical-only interactive tracker,
  keeping chart-wide inspection visibly distinct from point-local error bars.
  Nested error-bar legend semantics round-trip through artifacts and generated
  Dart. The release gate passed all 2,178 package tests and all 214 example
  tests, clean package/example analysis, `git diff --check`, a Wasm-compatible
  release web build, HTTP 200, and a final browser screenshot from the
  port-8101 review route. Checklist progress remains 71/94 overall and 7/7 for
  Phase 3; Phase 4 dense-data modes is next.
- 2026-07-20: Added the first Phase 4 dense-data mode as an explicit,
  portable `ScatterRenderMode.clusters` contract. A deterministic O(n)
  screen-cell layout reduces 100,000 visible source observations to 608
  markers in 88.164ms on the final local benchmark while preserving every raw point
  and source index for Data, Split, Source, selection, focus, and callbacks.
  Cluster radius scales by count, optional labels abbreviate large counts, and
  tooltips report observation count plus X/Y means instead of presenting an
  aggregate as one raw point. Viewport changes invalidate the screen-space
  layout so zoom reveals the original observations. The new Clusters preset
  exposes raw count, cell size, threshold, radius range, and labels, and its
  25,000-point customer-activity example passed the visual hierarchy and
  density review at the port-8101 route. Artifact JSON, generated Dart, AI
  schema input, release-safe validation, and native renderer behavior are
  covered. The release gate passed all 2,192 package tests and all 215 example
  tests with clean `lib`/example analysis, a Wasm-compatible release web
  build, HTTP 200, and a browser screenshot. Checklist progress is 73/94
  overall and 2/9 for Phase 4; hexagonal and rectangular aggregation are next.
- 2026-07-20: Added native count-based rectangular and flat-top hexagonal
  screen-space aggregation. Both deterministic O(n) layouts preserve every
  raw source index, expose exact path-aware hits, selection/focus overlays,
  aggregate semantics, count plus X/Y-mean tooltips, optional count labels,
  and opacity-scaled density. The portable `ScatterBinConfig` contract now
  round-trips through artifact JSON, generated Dart, hydration, and AI schema
  input. Grid bins and Hexbin Workbench presets expose raw count, cell size,
  gap, minimum count, opacity range, and label controls, with a native
  `LegendAnnotation` opacity key instead of a parallel legend layer. Focused
  renderer, artifact, source, AI, tooltip, and showcase tests passed. The full
  release gate passed all 2,204 package tests and all 216 example tests, clean
  package-library and example analysis, `git diff --check`, a Wasm-compatible
  release web build, and HTTP 200 on both review routes. The 500,000-point
  hexbin benchmark reduced the source to 1,682 bins in 411.882ms. Checklist
  progress is 75/94 overall and 4/9 for Phase 4; aggregate functions are next.
- 2026-07-20: Extended both 2D bin modes with count, proportion, sum, mean,
  minimum, and maximum aggregates over X, Y, magnitude, color value, or
  opacity value. Count and proportion retain perceptual square-root opacity;
  metric aggregates use their visible minimum/maximum domain. Optional metric
  values are ignored without losing raw rows, and tooltips plus assistive
  semantics disclose the contributing sample when it is smaller than the bin.
  Aggregate labels, exact hits, artifact JSON, generated Dart, hydration, AI
  schema input, and release-safe invalid-enum handling share the same contract.
  Grid bins and Hexbin expose concise mode-specific Aggregate and Value
  controls, while Data/Split/Source continue to project the raw observations.
  The full release gate passed all 2,210 package tests and all 216 example
  tests, clean package-library and example analysis, `git diff --check`, a
  Wasm-compatible release web build, and HTTP 200 on both port-8101 review
  routes. The 500,000-point mean-hexbin benchmark reduced the source to 1,682
  bins in 420.219ms. Checklist progress is 76/94 overall and 5/9 for Phase 4;
  density contours are next.
