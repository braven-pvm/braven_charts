# Radial chart-family architecture and roadmap

## Status

Approved on 2026-07-18. The six decisions in this document are the governing
boundaries for the radial chart-family programme. Phase 0 and Concentric Donut
Phase 1 are complete and merged. Phase 2 is complete on its review branch
through its V1 public series, renderer, controller selection, native table,
portable artifact/hydration, Workbench, generated source, and public showcase
surfaces, including Chart Types, three Gallery compositions, deterministic
pub.dev media, and public documentation. Package and showcase regressions, the
release-web build, native media capture, and the pub archive dry-run are green.
Compact, constrained, high-contrast, large-text, reduced-motion, and
deterministic label-density hardening is complete. Final visual acceptance was
recorded on 2026-07-19 after rebasing onto the published `0.9.0` mainline. The
branch is ready for PR review and is not yet merged or released.
Delivery remains phase-gated, and later families are not authorized by the
start of Phase 2.

## Executive decision

Braven Charts should not grow one universal `RadialSeries` with flags for Pie,
Donut, multi-ring Donut, Rose, Radial Bar, Gauge, and Sunburst.

Those charts share low-level annular-sector geometry, but they answer different
questions and require different data, scales, tables, selection behavior, and
portable-document contracts:

- **Partition charts** encode contribution to a total with angle.
- **Polar-axis charts** encode values against angular and radial scales.
- **Hierarchical radial charts** partition a tree across angle and depth.
- **Indicators** encode measurements against an explicit range and zones.

The architecture should reuse geometry and interaction primitives below those
semantic models. It should not reuse a public data model merely because the
rendered marks are arcs.

## The boundary in one table

| Chart | Primary question | Angle means | Radius means | Denominator / scale | Data model | Axis |
| --- | --- | --- | --- | --- | --- | --- |
| Pie | How does one total break down? | Share of one total | Constant, or optional second metric | Sum of slice values | One flat category series | None |
| Donut | How does one total break down, with center context? | Share of one total | Constant ring band, or optional second metric | Sum of slice values | One flat category series | None |
| Concentric Donut | How do several independent totals break down? | Share within that ring | Ring identity / allocated band | One independent total per ring | Several flat Donut series | None |
| Sunburst | How is a hierarchy partitioned? | Share within an ancestor partition | Tree depth | Parent/root rollups | One tree with stable node identity | None |
| Polar Column | How large is each category on a radial numeric scale? | Category position and bandwidth | Numeric value | Explicit radial numeric scale | Axis-based categorical series | Angular category + radial numeric |
| Rose / Nightingale | How do equal-angle categories compare by magnitude? | Equal category bandwidth | Numeric value, preferably area-correct | Explicit radial numeric scale | Polar Column specialization/preset | Angular category + radial numeric |
| Radial Bar | How far has each category progressed around a scale? | Numeric value / progress | Category ring | Explicit angular numeric scale | Axis-based categorical series | Radial category + angular numeric |
| Gauge / Solid Gauge | Where is a measurement within a known range? | Measurement or pointer position | Pane/track geometry | Explicit min, max, thresholds, and zones | Indicator measurements | Gauge axis |

The rule for ambiguous examples is:

- several rings that each add to their own total are **Concentric Donut**;
- nested parent/child rings are **Sunburst**;
- several rings where each arc is `value / maximum` are **Radial Bar** or
  **Solid Gauge**, not Donut;
- equal-angle wedges whose radii represent values are **Rose / Polar Column**,
  not variable-radius Pie;
- variable-radius Pie and Donut retain their existing two-metric contract:
  angle is still the primary part-to-whole share and radius is an independent
  secondary metric.

## Why the terminology needs to be explicit

The ecosystem uses “radial bar” for two different orientations. Highcharts
uses it for an inverted polar column: categories occupy radial rings and values
grow around the circle. Other libraries and examples use the phrase for bars
that sit at angular categories and grow outward.

Braven Charts should remove that ambiguity from the public API:

- `PolarColumnChartSeries` is the canonical outward-growing chart.
- `RadialBarChartSeries` is the concentric-track, sweep-growing chart.
- “Rose” or “Nightingale” is a documented Polar Column preset and a first-class
  showcase story. A convenience constructor may be added without creating a
  second rendering architecture.

Public documentation can mention “polar bar” as a search term, but the Dart
types and artifact capabilities should use the unambiguous names above.

## Current Braven Charts architecture

The current code already contains a good semantic seam:

- `RadialCategorySeries` is explicitly the shared validated contract for Pie
  and Donut, not a base for every circular chart.
- `PieChartSeries` and `DonutChartSeries` are distinct public models.
- `PieChartGeometry` computes the current wedge and annular-sector geometry.
- `PieSeriesElement` owns the current radial painting, hit testing, labels,
  semantics, tooltip anchors, and selection visuals.
- `BarChartSeries` belongs to the Cartesian axis/composition system and already
  has grouping, stacking, targets, and error-related behavior that should not
  be copied blindly into Pie.
- `ChartLayoutResolver` currently classifies only `cartesian` and `radial`, and
  deliberately requires exactly one Pie or Donut series.
- the native radial table projection similarly assumes one part-to-whole
  series and exposes category, value, and share;
- extraction, hydration, formatter descriptors, controller point references,
  previews, and the workbench all preserve the Pie/Donut meaning.

The important conclusion is that the existing `RadialCategorySeries` should
remain the **part-to-whole series base**. Renaming it to a universal radial base
or adding axes, hierarchy, gauges, and progress ranges to it would erase the
cleanest boundary currently in the package.

## Proposed architecture

### 1. Semantic families

Use internal coordinate/composition classification that is more expressive
than the current `cartesian | radial` split:

```text
cartesian
partitionRadial       Pie, Donut, Concentric Donut
polarAxis             Polar Column, Rose, Radial Bar, future Radar
hierarchicalRadial    Sunburst
gauge                 Needle and solid gauges
```

This can begin as an internal enum or sealed classifier. It should not become a
new public mega-configuration object. A family is responsible for validating
which series can compose in one plot.

Composition rules:

- Pie remains exactly one `PieChartSeries`.
- a single Donut remains exactly one `DonutChartSeries` and behaves exactly as
  it does today;
- Concentric Donut accepts two or more `DonutChartSeries` values only;
- polar-axis types may compose only where their pane and axes are compatible;
- Sunburst owns one hierarchy and does not mix with flat Donut series;
- gauges own a gauge pane and do not mix with part-to-whole series;
- no phase in this roadmap mixes Cartesian and radial families in one plot.

### 2. Shared low-level primitives

Extract and harden these implementation primitives without exposing a generic
“arc chart” public model:

- `RadialPaneGeometry`: center, available outer radius, start/end angle,
  direction, viewport insets, and reserved label space;
- `AnnularSectorGeometry`: start/end angle, inner/outer radius, gap, corner
  treatment, explosion offset, bounds, label anchors, and hit path;
- `PolarTransform`: angle/radius to Cartesian coordinates and inverse hit
  conversion;
- angular category, angular numeric, and radial numeric scales for axis-based
  families;
- reusable arc/sector painting, clipping, shadow, gradient, semantics, and hit
  regions;
- family-specific layout policies layered on top of those primitives.

`PieChartGeometry` can initially delegate to the extracted sector primitive.
Existing Pie/Donut output must remain pixel-stable before new types consume it.

### 3. Concentric Donut composition

Concentric Donut should be a composition of real `DonutChartSeries` instances,
not a new point format and not a fake hierarchy.

Each ring retains:

- its own series ID, name, unit, formatter, categories, ordering, and total;
- independent grouping and optional second-radius semantics;
- selection identity as `(seriesId, sourcePointIndex)`;
- independent artifact and table data.

A plot-level `ConcentricDonutConfig` should provisionally own:

- inner and outer plot radius factors;
- gap between rings;
- inner-to-outer or outer-to-inner series order;
- automatic ring weights, plus optional weights keyed by series ID;
- the one center-content policy for the complete composition;
- legend grouping policy.

The exact placement of that portable config in `ChartDocument` requires a
focused Phase 1 design, because the current center content and inner radius are
series-owned. Backwards compatibility is non-negotiable: a one-series Donut
must serialize and render exactly as it does now.

Center ownership rules:

- one concentric plot has one center surface;
- runtime builders remain plot-level rebinding hooks;
- a single Donut maps its existing center content through unchanged;
- a multi-ring document must not silently choose between conflicting per-ring
  center declarations;
- the portable fallback must still render in previews without Dart callbacks.

No initial Concentric Donut feature may infer relationships between same-named
categories across rings. Category alignment, if later useful, must be explicit.

### 4. Polar-axis charts

Polar charts need real scales and axes. They must not obtain those semantics by
adding a maximum or a baseline to `RadialCategorySeries`.

The polar pane owns:

- angular and radial scale domains;
- category ordering and numeric tick generation;
- partial/full sweep and clockwise direction;
- grid shape and lines;
- thresholds, zero/baseline, and clipping;
- label placement and collision policies for axes and marks.

`PolarColumnChartSeries` provisionally owns category/value points and column
composition. Its initial mark uses a fixed angular bandwidth and maps values to
radius. Later phases may add multiple series, grouping, stacking, targets, and
errors after each is defined in polar terms rather than mechanically ported
from Cartesian bars.

The Rose preset uses equal angular bandwidth. To make magnitude proportional
to sector area rather than radius, its default radial mapping should be
area-correct (square-root transformed) and explicitly documented. A linear
radius option may be offered, but should not be the silent statistical default.

`RadialBarChartSeries` reverses the orientation: categories occupy concentric
tracks and values map to sweep on an angular numeric scale. It owns min/max,
baseline, track, threshold, and stacking semantics. Shares are not generated
unless the host explicitly supplies or requests a derived percentage.

### 5. Sunburst hierarchy

Sunburst is not “several Donuts.” It needs a durable tree contract:

- stable node ID and optional parent ID;
- deterministic root and child ordering;
- explicit value/rollup rules and validation of inconsistent totals;
- depth-to-ring allocation;
- angle partition within each parent;
- selection of node, ancestors, descendants, and path;
- drill root, breadcrumbs, and restoration of drill state;
- hierarchy-aware labels, tooltips, table projection, and accessibility;
- portable node identity that survives reorder and hydration.

Current point-index references are sufficient for flat Pie/Donut and polar
series, but Sunburst must not rely on an array index as its durable identity.
The hierarchy identity contract is a Phase Sunburst prerequisite.

### 6. Gauges and indicators

A Gauge answers “where is this measurement within an expected range?” It owns:

- explicit minimum and maximum;
- thresholds/zones and optional target;
- needle, marker, or solid-arc presentation;
- center value and status semantics;
- direction and partial/full pane;
- optional multiple measurements with an explicit composition policy.

A solid gauge may visually resemble one progress ring, and several solid gauges
may resemble Radial Bars. The semantic boundary is intent:

- use Radial Bar to compare a categorical collection on one scale;
- use Gauge for operational state, thresholds, zones, and indicator semantics.

They may share pane, scale, and annular-sector primitives, but not a public
series model.

## Cross-cutting contracts

### Selection and controller

- Concentric Donut and polar-axis points use existing series + point identity.
- selecting a legend item, table row, chart mark, or controller reference must
  converge on the same selected reference.
- grouped Donut rows retain the current source-to-visible projection behavior,
  scoped by series ID.
- Sunburst adds stable node identity and explicit drill state rather than
  overloading flat point selection.
- Gauge selection is optional and separate from its current measurement value.

### Native data tables

| Family | Required native columns |
| --- | --- |
| Concentric Donut | Ring/series, category, value, share within ring, optional radius metric |
| Polar Column / Rose | Category, series, value, optional baseline/target/error fields |
| Radial Bar | Category/track, series, value, min/max or derived progress when configured |
| Sunburst | Node, path, parent, depth, value, share of parent, share of root |
| Gauge | Metric, value, min, max, normalized progress, zone/status |

Copy row, copy dataset, CSV export, formatting, table/chart selection, and
split-view resizing are release requirements for each family—not showcase-only
features.

### Legends and labels

- Concentric Donut defaults to grouped-by-ring legend sections. A flat legend
  is allowed only when identity remains unambiguous.
- custom legend builders receive the family-specific immutable item plus stable
  series/point or node identity.
- Sunburst does not default to a flat legend of every node; labels,
  breadcrumbs, and path context are primary.
- polar-axis charts use category axis labels and a series legend rather than a
  Pie-style legend item for every value.
- gauges normally use direct labels and center/status content; legends are
  optional.

### Artifacts and hydration

Every family must declare a narrow capability rather than a generic radial
capability. Provisional capability names are:

```text
series.donut.concentric.v1
series.polar.column.v1
series.radial.bar.v1
series.sunburst.v1
series.gauge.v1
```

Each capability needs deterministic JSON, schema validation, safe hydration,
formatter descriptors, preview behavior, and a defined failure when an older
runtime cannot support it. Runtime widget builders remain bindings and never
enter the portable document.

### Animation and reduced motion

- Pie/Donut identity-keyed transitions remain the baseline for flat category
  data.
- Concentric Donut animates each ring without changing ring allocation because
  another ring selected a point.
- polar-axis charts animate from their numeric baseline, not from a Pie sweep.
- Radial Bar grows along its angular numeric scale.
- Sunburst transitions preserve stable node identity and use an explicit drill
  transition.
- Gauge transitions interpolate measurements and zones without replaying mount
  motion.
- every family renders the final state immediately for reduced motion and
  zero-duration themes.

### Accessibility

Every implementation must expose:

- a chart-level summary describing the correct semantic family;
- stable focus order and keyboard navigation;
- category/series or hierarchy path plus formatted value;
- share only where a real partition denominator exists;
- min/max/zone context for scale-based bars and gauges;
- no duplicate Canvas and widget semantics;
- no focus reflow when selection changes a legend item's visuals.

## Delivery roadmap

This is a dependency graph with a recommended merge order. It is not one large
branch or one PR.

```text
Current Pie/Donut
        |
        +--> Annular-sector seam --> Concentric Donut --> Sunburst
        |
        +--> Polar pane/scales ----> Polar Column/Rose --> Radial Bar
                     |                                      |
                     +-------------------------------> Gauge/Solid Gauge
                     |
                     +-------------------------------> future Radar/Polar Line
```

Sunburst shares partition concepts with Donut but not its flat data model.
Gauge shares pane and arc primitives with polar charts but not their categorical
comparison model. The arrows indicate reusable foundations, not inheritance.

### Phase 0 — Architecture ratification and geometry seam

Deliver:

- ratify the terminology and boundary matrix in this document;
- write the focused Concentric Donut and polar-pane API designs;
- expand the internal composition classifier;
- extract an annular-sector primitive behind existing Pie/Donut geometry;
- add regression tests proving current Pie and Donut models, artifacts,
  interaction, animation, and pixels are unchanged.

Exit gate: the foundation changes no public behavior and creates no universal
radial series base.

### Phase 1 — Concentric Donut V1

Status: complete and merged. The V1 family contract, portable document,
Workbench integration, public showcase, and release-facing documentation have
passed their Phase 1 gates.

Deliver:

- multiple independent `DonutChartSeries` rings;
- automatic ring allocation, gap, ordering, and optional weights;
- one center-content surface;
- ring-aware legend, table, controller selection, tooltip, semantics, and
  formatter context;
- full artifact extraction/hydration, image preview, workbench, gallery, Chart
  Types, dedicated showcase story, and documentation.

V1 limits:

- Donut only; Pie cannot be overlaid as another ring;
- independent totals; no parent-child inference;
- no drilldown;
- no cross-ring stacking;
- one shared explode/lift selection model across Pie, Donut, and Concentric
  Donut behavior.

Exit gate: a saved multi-ring artifact restores with identical rings, totals,
selection identity, table rows, and portable center fallback.

### Phase 2 — Polar coordinate foundation + Polar Column V1

Status: complete on the review branch and ready for PR. The radial-pane geometry,
bidirectional polar transform, category and numeric scales, public V1 series
and configuration, renderer, selection, native table, deterministic artifact
and hydration, Workbench, generated source, dedicated showcase, Chart Types,
three-composition Gallery, deterministic media capture, and public guide are in
place. Package and showcase regressions and the release-web build are green;
the native media capture and pub archive dry-run pass, and final visual
acceptance is recorded.
Focused goldens now cover normal, compact dense, constrained partial-sweep, and
high-contrast large-text layouts. Reduced motion resolves immediately to final
geometry, and dense angular/direct labels thin without removing semantic or
table data. The branch is rebased onto the published `0.9.0` mainline; PR review
and merge remain before release.

Deliver:

- radial pane and polar transform;
- angular category and radial numeric scales;
- ticks, grid, baseline, partial sweep, direction, labels, clipping, hit
  testing, zoom policy, and semantics;
- one non-negative `PolarColumnChartSeries` with explicit category/value data;
- a Rose/Nightingale preset with area-correct default scaling;
- native table, artifacts, controller, workbench, showcase, Gallery, media,
  and documentation integration.

V1 limits:

- one series;
- no stacking/grouping/errors/targets;
- no negative radial values until baseline behavior is separately designed;
- no Cartesian/polar mixed plot.

Exit gate: the same data can be understood from its axis labels, table, and
artifact without relying on a Pie share.

### Phase 3 — Polar Column composition hardening

Deliver in small slices:

1. multiple compatible series;
2. grouping;
3. stacking with explicit positive/negative rules;
4. thresholds/targets;
5. errors/ranges if the polar presentation remains legible and accessible;
6. performance and label-density limits.

Each feature is specified in polar coordinate terms. Existing Cartesian Bar
algorithms may share scale/domain utilities, but Cartesian geometry is not
treated as the source of truth for polar layout.

### Phase 4 — Radial Bar V1

Deliver:

- `RadialBarChartSeries` with category tracks and value-to-sweep mapping;
- explicit min/max/baseline;
- full and partial sweep panes;
- background tracks, gaps, rounded ends, thresholds, and selection;
- table/controller/artifact/workbench/showcase support;
- then grouping/stacking as separately reviewed slices.

Exit gate: documentation and runtime messages never describe the bars as
shares of a Donut total unless a percentage is explicitly derived from its
configured scale.

### Phase 5 — Gauge and Solid Gauge

Deliver:

- a dedicated indicator model;
- needle and solid-arc modes;
- min/max, ticks, zones, target, center value, status semantics;
- deterministic artifacts and runtime center builders;
- single-measurement V1, followed by an explicit multi-measurement design.

Exit gate: threshold/zone state and the current value are fully represented in
the table, semantics, document, preview, and hydrated runtime.

### Phase 6 — Sunburst V1

Deliver:

- immutable hierarchy model with stable node IDs;
- validation and rollup policy;
- partition layout by angle and depth;
- node/path selection, focus, labels, tooltip, and breadcrumbs;
- drill root and portable drill state;
- hierarchy table and CSV representation;
- artifacts, hydration, preview, workbench, showcase, and documentation.

V1 limits:

- one hierarchy;
- no arbitrary multiple-root overlay;
- no mixing with flat Donut rings;
- no runtime-only node builder in portable previews without a text fallback.

Exit gate: reorder and hydration preserve node identity, current drill root,
selection path, values, and ancestor relationships.

### Future lane — Radar and polar line/area

Radar, polar line, and polar area should consume the Phase 2 pane and scale
foundation. They are not required to complete Donut, Radial Bar, Gauge, or
Sunburst and should get their own product/design investigation.

## Release gate for every public phase

Every phase is a separate dedicated worktree, branch, local review, and PR.
Before handback it requires:

1. public API docs and a focused feature guide;
2. model, validation, layout, paint, interaction, keyboard, semantics, table,
   formatter, artifact, hydration, preview, and workbench tests;
3. focused golden coverage at compact, normal, and constrained sizes;
4. reduced-motion and high-contrast verification;
5. full package and example analysis/tests;
6. `flutter build web --release` from `example`;
7. direct-route browser validation for the new public showcase page;
8. Gallery and Chart Types integration where appropriate;
9. pub.dev screenshots/media and package documentation;
10. `dart pub publish --dry-run` and `git diff --check`;
11. a running local web route for user acceptance before commit/PR.

## Explicit non-goals

- no mega `RadialSeries` with a chart-type enum;
- no generic `radius` and `angle` point model exposed as the normal API;
- no Sunburst implemented by stacking independent Donuts;
- no Radial Bar implemented by normalizing values into fake Pie shares;
- no Gauge implemented as a selected Donut slice;
- no silent category alignment or hierarchy inference by display label;
- no runtime widget callback serialized into artifacts;
- no new public chart without native data/table, controller, artifact,
  hydration, preview, accessibility, and showcase support.

## Decisions to ratify

1. **Names:** adopt `PolarColumnChartSeries` for outward-growing bars and
   `RadialBarChartSeries` for sweep-growing concentric tracks.
2. **Rose:** ship it as a named Polar Column preset/convenience constructor,
   not a separate renderer or data model.
3. **Concentric totals:** every Donut ring has an independent denominator;
   parent-child rings are reserved for Sunburst.
4. **Center ownership:** one plot-level center surface for Concentric Donut,
   with current single-series Donut behavior preserved through an adapter.
5. **Recommended order:** Concentric Donut, Polar Column/Rose, Radial Bar,
   Gauge, then Sunburst. Sunburst is later because hierarchy identity,
   drilldown, tables, and artifacts make it the highest-risk family.
6. **Variable-radius Pie/Donut:** retain it as a deliberate two-metric
   part-to-whole chart and document that it is not a Rose chart.

## Research references

- [D3 pie generator](https://d3js.org/d3-shape/pie) separates part-to-whole
  angle calculation from the generic arc primitive.
- [D3 arc generator](https://d3js.org/d3-shape/arc) demonstrates that the same
  annular-sector geometry can support different semantics.
- [Chart.js Doughnut and Pie](https://www.chartjs.org/docs/latest/charts/doughnut)
  documents multiple datasets as concentric rings with independent dataset
  weight, while Pie differs primarily by cutout.
- [Highcharts polar charts](https://www.highcharts.com/docs/chart-and-series-types/polar-chart)
  describe an angular X axis and center-to-edge Y axis.
- [Highcharts radial bar](https://www.highcharts.com/docs/chart-and-series-types/radial-bar-chart)
  defines radial bar as an inverted polar column with category rings and value
  sweeps.
- [Chart.js Polar Area](https://www.chartjs.org/docs/latest/charts/polar.html)
  uses equal angular sectors and radius to encode magnitude.
- [Apache ECharts Nightingale/Rose](https://echarts.apache.org/handbook/en/how-to/chart-types/pie/rose/)
  illustrates the common Rose terminology.
- [Vega radial plot](https://vega.github.io/vega/examples/radial-plot/) warns that
  simultaneously encoding angle and radius is perceptually difficult because
  viewers tend to interpret total sector area.
- [Highcharts Sunburst](https://www.highcharts.com/docs/chart-and-series-types/sunburst-series)
  and [Vega Sunburst](https://vega.github.io/vega/examples/sunburst/) both model
  hierarchy rather than independent concentric datasets.
- [Highcharts angular gauges](https://www.highcharts.com/docs/chart-and-series-types/angular-gauges)
  use an explicit value range, axis, and indicator semantics.
