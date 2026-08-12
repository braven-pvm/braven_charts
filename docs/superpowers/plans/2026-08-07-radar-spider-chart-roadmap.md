# Native Radar / Spider Chart Family — Research and Delivery Roadmap

**Date:** 2026-08-07  
**Register:** `BC-0061`  
**Branch:** `feature/BC-0061-radar-chart`  
**Worktree:** `F:\Repositories\braven_charts-spiderweb-research`  
**Status:** Review complete; release gates passed and PR delivery authorized
**Parent architecture:**
`docs/superpowers/specs/2026-07-18-radial-chart-family-roadmap.md`

## Product outcome

Ship Radar as a complete native `polarAxis` chart family for comparing aligned
quantitative profiles over one ordered set of categories. “Spider” and
“Spiderweb” are documented aliases for the polygon-grid presentation, not
separate data models or duplicated public series types.

The family must participate in the complete Braven Charts product contract:
rendering, interaction, controller selection, accessibility, Data/Split/Source,
artifacts, hydration, previews, Workbench, grammar, AI/fluent construction,
showcase, public docs, and release media.

## Executive decisions

1. The canonical public family is **Radar**: `ChartType.radar` and
   `RadarChartSeries`. “Spider” and “Spiderweb” remain discoverable aliases.
2. Radar uses `ChartLayoutKind.polarAxis`, but it is not a Polar Column preset.
3. `RadarChartSeries` extends `ChartSeries`; it does not extend
   `RadialCategorySeries`, whose angle-as-share contract belongs to Pie/Donut.
4. One chart owns one ordered category domain and one shared **linear** radial
   scale. Every visible series must align to that exact category identity and
   order.
5. V1 supports full-circle closed profiles only. Start angle and direction are
   configurable; partial sweeps are not.
6. V1 values are finite and non-negative. Negative/centered Radar is a separate
   design problem and is not inferred from the current Polar Column baseline.
7. Missing vertices are rejected in V1. A closed polygon never silently treats
   an absent value as zero or joins unrelated neighbours.
8. Category order is authored data and is preserved in documents and source.
   The renderer never sorts by value because order changes the visual shape.
9. Polygon and circular grids are presentations of the same data. Polygon is
   the Spider/Spiderweb default; circle is the Radar alternative.
10. Straight closed segments ship first. Bézier smoothing is excluded because
    control-point overshoot can exceed the represented radial bounds and make
    the profile misleading.

## Research findings

### Common ecosystem model

- Plotly implements Radar as a closed `scatterpolar` trace. Its examples repeat
  the first category/value to close the path, support `fill: 'toself'`, and
  overlay several named traces. Braven should close canonical geometry itself;
  users must not duplicate the first point in source data.
- Highcharts allows polar grid lines to interpolate as either `polygon` or
  `circle`. That is a plot-level grid choice, not a second series type.
- Apache ECharts similarly exposes Radar as its own coordinate/series family,
  reinforcing the semantic boundary from ordinary polar bars.
- The supplied “Budget vs spending” reference is the conservative core case:
  six like-unit categories, two aligned profiles, one visible scale, markers,
  polygon web, and an ordinary series legend.

### Perceptual limits

Radar charts are attractive summaries but weak precision tools. IBM Research’s
controlled comparison of radial composite-indicator views found Radar least
effective and least liked among the tested alternatives. The product should
therefore help users avoid the common failure modes rather than simply expose
every possible option:

- default to a small number of profiles;
- preserve and disclose category order;
- use one visible radial scale and include zero by default;
- avoid filled opacity that hides later profiles;
- never use color as the only differentiator;
- keep the exact Data table one click away;
- explain that a bar or line chart is usually better for precise ranking and
  trend comparison.

### Accessibility implications

W3C guidance requires text alternatives for chart data, keyboard access to
pointer functionality, sufficient contrast, and presentation that can adapt
without losing information. Radar therefore cannot be considered complete with
only a painter. It needs structured semantics, linked keyboard selection, and
the native category-by-series table as an equivalent data view.

### Primary sources

- Plotly Radar examples:
  <https://plotly.com/javascript/radar-chart/>
- Highcharts polygon/circle polar grids:
  <https://api.highcharts.com/highcharts/yAxis.gridLineInterpolation>
- Apache ECharts Radar option surface:
  <https://echarts.apache.org/en/option.html#radar>
- IBM Research comparative study:
  <https://research.ibm.com/publications/off-the-radar-comparative-evaluation-of-radial-visualization-solutions-for-composite-indicators>
- W3C accessibility principles:
  <https://www.w3.org/WAI/fundamentals/accessibility-principles/>
- W3C accessible table guidance:
  <https://www.w3.org/WAI/tutorials/tables/>

## Family boundary

| Family | Angle means | Radius means | Closure | Data semantics |
| --- | --- | --- | --- | --- |
| Pie / Donut | share of a total | fixed or second metric | partition | one denominator |
| Polar Column | category band | numeric value | independent columns | axis comparison |
| Radial Bar | numeric progress | category track | independent arcs | value / explicit range |
| **Radar / Spider** | category axis | numeric value | closed profile | aligned multidimensional profile |

Radar may reuse the polar pane and axis primitives below these models. It must
not reuse their public series, table, selection, or artifact meaning.

### Mixed compositions

V1 accepts one or more `RadarChartSeries` and rejects mixtures with Cartesian,
Pie/Donut, Polar Column, Radial Bar, or Gauge series. Radar + Polar Column is
not enabled merely because both resolve to `polarAxis`: their mark geometry,
hit targets, label rules, animation, and table semantics do not yet share a
reviewed composition contract.

## V1 data contract

### Canonical series

```dart
RadarChartSeries.fromMap(
  id: 'allocated',
  name: 'Allocated budget',
  values: const {
    'Sales': 43000,
    'Marketing': 19000,
    'Development': 60000,
    'Customer support': 35000,
    'Information technology': 17000,
    'Administration': 10000,
  },
  unit: 'USD',
  color: Colors.lightBlue,
  radarStyle: const RadarSeriesStyle(
    fillOpacity: 0.12,
    showMarkers: true,
  ),
)
```

`fromMap` preserves insertion order and produces stable ordinal
`ChartDataPoint`s whose visible labels are the category identities. A direct
constructor remains available for typed/canonical point lists, matching the
existing Polar Column model.

### Validation

- series ID is non-blank and unique within the chart;
- at least three points;
- X is a stable zero-based ordinal;
- every category label is visible, trimmed, and unique;
- every Y value is finite and non-negative;
- every series has the same category identities in the same order;
- one chart-wide unit/scale meaning is expected and documented;
- explicit radial minimum is `>= 0`, maximum is greater than minimum;
- automatic domains include zero and choose a stable non-zero fallback;
- pane sweep is exactly 360 degrees in V1;
- inner radius is zero in V1; hollow profiles belong to a separately reviewed
  polar-line/ring presentation, not a hidden Radar flag.

### Heterogeneous metrics and normalization

Radar charts often place unlike units on independent axes. That convenience can
produce identical-looking shapes from materially different scales. V1 does not
add per-axis min/max models. Applications comparing unlike metrics must first
create a normalized score (for example 0–100), preserve raw values in their own
domain, and label the chart as normalized. A future indicator-axis model may
carry both raw and normalized values only after its artifact, tooltip, and table
semantics are designed explicitly.

### Missing and changing categories

V1 rejects an absent category rather than drawing an ambiguous gap or zero.
Streaming value updates are valid when series and category identities remain
stable. Adding, removing, or reordering categories is a topology change and
uses a fresh entrance/fade transition; vertices from different categories are
never interpolated into one another.

## Public model proposal

### Series and style

- `RadarChartSeries`
- `RadarSeriesStyle`
  - `strokeWidth`, `strokePattern`, `strokeOpacity`
  - `fillColor`, `fillOpacity`, optional portable radial/linear gradient
  - `showMarkers`, marker shape/radius/fill/border
  - `showDataLabels`, formatter descriptor, label style/offset/minimum share or
    density controls where meaningful
  - optional shadow/glow using existing portable style primitives
  - `RadarAnimationMode.none`, `radial`, `fade`
- existing `showInLegend`, `showTrackingAxisLabel`, and
  `showInTrackingTooltip` series-level controls remain authoritative.

The defaults use a visible stroke, small markers, low-opacity fill, no shadow,
and theme-derived colors. Filled profiles paint in authored order; selection
and focus use a deterministic overlay pass rather than changing the data order.

### Plot configuration

Prefer a dedicated `RadarChartConfig` which reuses neutral lower-level models
without inheriting Polar Column-only composition or thresholds:

```dart
RadarChartConfig(
  pane: const PolarPaneConfig(
    startAngleDegrees: -90,
    clockwise: true,
  ),
  categoryAxis: const RadarCategoryAxisConfig(
    showLabels: true,
    showSpokes: true,
  ),
  radialAxis: const RadarNumericAxisConfig(
    minimum: 0,
    tickCount: 5,
    gridShape: RadarGridShape.polygon,
  ),
)
```

The current `PolarPaneConfig` and `PolarLabelStyle` are reusable. The current
`PolarCategoryAxisConfig` encodes column band padding, and `PolarChartConfig`
owns Polar Column composition and thresholds, so forcing Radar through them
would leak the wrong contract. Small neutral pieces can be extracted when that
reduces duplication without migrating existing documents unnecessarily.

### Grid and labels

- `RadarGridShape.polygon` and `.circle`;
- configurable major ring count/ticks;
- spokes, ring lines, outer boundary, patterns, colors, widths, and opacity;
- category label offset, maximum visible labels, style, alignment, and
  deterministic collision/fallback behavior;
- radial tick-label ray, angle offset, radial offset, formatter, and style;
- no hidden axis-specific normalization.

## Geometry and rendering

### Reuse

- `RadialPaneGeometry` for center, radius, start angle, and direction;
- `PolarTransform` for polar/cartesian conversion;
- the linear branch of `PolarNumericScale` after its Polar Column-specific
  validation messages are neutralized;
- theme, tooltip, interaction, selection, formatter, and render-cache
  foundations where their semantics already match.

### New pure geometry

- `RadarCategoryScale` or a point-axis extension that maps categories to exact
  spoke angles. Radar should not pretend each vertex is a padded category band.
- `RadarChartGeometry` resolving:
  - category/spoke angles;
  - radial ring paths for polygon and circle grids;
  - one ordered vertex list and closed path per series;
  - marker centers and label anchors;
  - bounds expanded for stroke, markers, selection, labels, and shadows;
  - nearest vertex and polygon/edge hit candidates.
- `RadarSeriesElement` owning paint, hit-test, tooltip anchors, selection,
  focus, semantics, and cached base/overlay layers.

Users provide each category once. Geometry closes the final vertex to the
first internally and never exposes a duplicate point to the controller, table,
tooltip, selection, or artifacts.

### Paint order

1. pane background;
2. radial rings and spokes;
3. optional axis/tick labels;
4. profile fills in authored series order;
5. profile strokes and markers;
6. data labels;
7. hover/focus/selection overlays;
8. tooltips and external legend widgets.

## Interaction contract

### Pointer and touch

- nearest-vertex focus within a configurable hit radius;
- profile edge/fill hit may select the series, but point selection remains the
  more precise default;
- tooltip shows category, series, exact value, and unit;
- shared-category tracking can show all opted-in series for one spoke;
- table row, legend item, chart vertex, and controller reference resolve the
  same stable `(seriesId, category/index)` identity;
- mobile browse/inspect ownership follows existing long-press configuration.

### Keyboard

- Left/Right (or configured traversal direction) changes category;
- Up/Down changes series at the same category;
- Enter toggles selection;
- Escape clears focus/selection;
- focus is visibly distinguishable without relying on fill color alone.

### Selection

V1 supports point and series scopes. Category selection across all series may
reuse the existing category-scope contract if it can preserve exact point refs;
otherwise it remains a follow-up rather than being approximated with index-only
state.

## Accessibility and equivalent data

- Chart semantics state the title, Radar family, series count, category count,
  shared radial range, and whether values are normalized.
- Focused nodes announce series, category, value, unit, and selected state.
- Large text and high contrast retain labels or use a documented density
  fallback; they never silently remove source data.
- Color is supplemented by stroke pattern/marker shape and legend text.
- Data view defaults to a compact shared-category table:

| # | Category | Allocated budget (USD) | Actual spending (USD) |
| --- | --- | ---: | ---: |
| 1 | Sales | 43,000 | 50,000 |

- A long/lossless projection remains available through existing table options
  when exact series rows are required.

## Portability and public-surface matrix

Radar is not complete until all exhaustive surfaces recognize it:

| Surface | Required work |
| --- | --- |
| Public API | exports, `ChartType.radar`, `SeriesStyle.radar`, constructors |
| Layout | resolver, family mixing validation, bounds, render branch |
| Controller | point refs, focus, selection, descriptors, identity updates |
| Artifact | `radar` series codec and `series.radar.v1` capability |
| Hydration | fail-closed model/config/style reconstruction |
| Preview | deterministic image capture and bounds |
| Table/CSV | shared category and lossless projections |
| Dart Source | direct typed configuration with compile fixtures |
| Grammar | dedicated `RadarMark<T>` / `.geomRadar(...)`, not `.geomPolar(...)` |
| Fluent/AI | generated schema plus validated builder surface |
| Workbench | Chart/Data/Split/Source and linked selection |
| Showcase | direct route, inspector, gallery, Chart Types, mobile/constrained |
| Docs | API, guide, use/don’t-use guidance, examples, pub.dev media |

Capabilities should be granular when non-default features need negotiation,
for example `series.radar.v1`, `series.radar.gradient.v1`, and a plot-level
grid/axis capability if the existing polar label capability cannot represent
the new contract without ambiguity.

## Animation contract

### Entrance

- `radial`: each vertex interpolates from the zero/minimum baseline along its
  own spoke and the closed path is rebuilt from those instantaneous vertices;
- `fade`: final geometry fades without changing represented values;
- `none`: immediate final state.

### Data updates

- stable series ID + stable category order: interpolate radial values and
  portable style properties;
- inserted/removed/reordered category: do not morph indices; use explicit
  exit/entrance or fade;
- reduced motion: render final state synchronously;
- grid and labels stay stable during ordinary value updates.

## Showcase design

Create a focused `?page=radar-charts` guide using the standard compact selector,
Workbench, full Options panel, guide link, and responsive layout.

### Authored examples

1. **Budget vs spending** — the supplied six-axis, two-series Spider reference.
2. **Capability profile** — one profile, markers, polygon grid, direct values.
3. **Product comparison** — two or three profiles with circle grid and stroke
   patterns to prove non-color differentiation.
4. **Normalized scorecard** — explicit 0–100 disclosure and formatter.
5. **High contrast** — no translucent-fill dependence, stronger outlines,
   accessible markers, and large text.
6. **Dense stress** — 12–24 categories, label-density controls, constrained
   viewport, selection, and table fallback.
7. **Playground** — deterministic seed-based values and presentation controls;
   it supplements rather than replaces authored examples.

### Options panel

Group controls consistently with the existing radial pages:

1. Data and example;
2. category/spoke labels;
3. radial scale and ticks;
4. web/grid shape and line styling;
5. profile stroke/fill/gradient/markers;
6. legend and tooltip;
7. interaction and selection;
8. motion;
9. chart theme and accessibility.

Every option must affect the public configuration used by the chart; showcase-
only approximations are not acceptable. The layout must remain usable in the
desktop inspector, tablet split view, mobile route, 200% text, and narrow
viewport.

## Explicitly deferred from V1

- independent per-category radial bounds;
- raw + normalized dual-value indicator axes;
- negative or centered/diverging Radar;
- missing vertices, gap bridging, and sparse profiles;
- partial sweeps and hollow profiles;
- Bézier/spline profiles;
- stacked Radar or total/area semantics;
- Radar + Polar Column mixed composition;
- automatic category sorting;
- drag-to-edit vertices;
- SeriesCallout lanes until radial anchor/collision behavior is specified;
- free-form annotations in polar coordinates;
- hierarchical or nested Radar.

These are not “unsupported but silently ignored.” Validation, hydration, and
source generation must reject or explicitly report them.

## Delivery sequence

| Slice | Outcome | Review surface |
| --- | --- | --- |
| 0 | Research, family boundary, register, roadmap | This document and BC-0061 |
| 1 | Public model, validation, scales, pure geometry | Focused tests + static single-profile test surface |
| 2 | Renderer, multi-series, grid, theme, labels | Direct Radar route with authored presets |
| 3 | Interaction, controller, keyboard, semantics | Linked chart/table selection and accessibility review |
| 4 | Motion and update identity | Replay/update/reduced-motion test surface |
| 5 | Artifacts, hydration, table, Source, grammar, fluent/AI, Workbench | Full Chart/Data/Split/Source workflow |
| 6 | Showcase, Gallery, Chart Types, docs, public media | Complete user-facing guide |
| 7 | Goldens, performance, full regression, release readiness | Clean package/showcase/release evidence |

## Slice 1 — Model and pure geometry

**Delivery status:** Complete on 2026-08-07. The public Radar models, strict
composition contract, layout-family resolution, deterministic category scale,
closed-profile/grid geometry, generated fluent surface, and focused regression
tests are implemented. Rendering remains intentionally deferred to Slice 2.

### Scope

- add enums/types and public exports;
- add `RadarChartSeries.fromMap` and direct constructor;
- validate category/domain/unit/alignment contracts;
- add `RadarChartConfig` and `RadarSeriesStyle` foundations;
- add category point-scale and closed-profile geometry;
- add layout resolver branch with explicit mixed-family rejection;
- add pure tests before the renderer is connected.

### Gate

The model cannot represent an ambiguous V1 chart, closure never duplicates a
source point, and geometry returns exact deterministic vertices/rings for both
clockwise directions and start angles.

## Slice 2 — Renderer and presentation

**Delivery status:** Complete on 2026-08-07. A native
`RadarSeriesElement` now paints shared polygon or circular webs, closed
multi-series fills/strokes, markers, category labels, radial labels, and
density-bounded data labels through `BravenChartPlus`. The direct Radar route,
Chart Types card, direct-route tests, and four constrained/mobile examples are
available for visual review. Gradients, shadows, and richer high-contrast
presets remain intentionally scheduled with the later presentation and
hardening slices rather than being approximated in this renderer foundation.

### Scope

- `RadarSeriesElement` and chart registration;
- polygon/circle webs, spokes, ticks, boundaries, labels;
- multi-series fills, strokes, patterns, markers, gradients, shadows;
- clipping, layout bounds, label density, theme/high contrast;
- static direct route and visual presets.

### Gate

Painted vertices equal geometry vertices; fills never escape the closed path;
labels and expanded effects fit or degrade deterministically; compact and large
text do not crash or clip silently.

## Slice 3 — Interaction and accessibility

**Delivery status:** Complete on 2026-08-07. Radar vertices now participate in
the durable focus and category-selection contracts across pointer, keyboard,
controller, and a linked exact-value matrix. Shared-category tracking resolves
every aligned profile on one spoke, tooltips aggregate opted-in profile values,
and Radar exposes chart- and vertex-level semantics. The linked matrix is a
live controller proof; portable native Data/Split projection remains Slice 5.
The standard legend also retains every opted-in profile and publishes
visibility changes through that same durable series identity.

### Scope

- vertex/fill hit testing;
- point/series focus and selection;
- shared-category tooltip/tracking;
- legend and data-table linkage;
- keyboard traversal, touch behavior, semantics, screen-reader summary;
- controller selected/focused references.

### Gate

Pointer, keyboard, table, legend, and controller select the same durable
identity. Every mouse action has a keyboard path, and the exact data remains
available independently of color and geometry.

## Slice 4 — Motion

**Delivery status:** Complete on 2026-08-07. Radar now supports radial
baseline growth, final-geometry fade, and immediate modes through the existing
portable `RadarSeriesStyle.animationMode`. Stable series/category identities
interpolate values without moving one category into another, while topology
changes reveal the final authored profiles. The web and radial scale remain
stable during value morphs. The direct Radar route exposes deterministic value
updates, entrance replay, all three modes, and a reduced-motion preview.

### Scope

- baseline-to-value radial entrance;
- fade/none modes;
- stable identity-aware value transitions;
- safe topology-change transition;
- reduced-motion and replay controls.

### Gate

Animation never overshoots the radial domain or morphs one category into
another, and reduced motion renders the final chart immediately.

## Slice 5 — Portable product contract

**Delivery status:** Complete on 2026-08-07. Radar now round-trips its series,
plot configuration, portable style, capability declarations, and durable
selection through artifact extraction, JSON, hydration, and preview. Native
shared-category table/CSV projection, deterministic direct and Grammar Dart
source, `geomRadar`, generated fluent/AI surfaces, and the standard
Chart/Data/Split/Source Workbench are covered by focused regressions.

### Scope

- artifact series/config/style codecs and capability negotiation;
- extraction/hydration validation and preview;
- shared-category and long Data/CSV projections;
- deterministic typed Dart Source with compile/round-trip fixtures;
- `RadarMark<T>` / `geomRadar`, fluent, and AI schema;
- Workbench and linked selection.

### Gate

A styled, selected multi-series Radar chart extracts, encodes, hydrates,
previews, tables, and source-generates without semantic loss. Unsupported
runtime callbacks are reported explicitly.

## Slice 6 — Showcase and documentation

**Delivery status:** Complete on 2026-08-07. The dedicated Radar guide now
connects its authored presets, deterministic playground, complete Options
inspector, linked Workbench, constrained/mobile examples, Chart Types entry,
three production-shaped Gallery examples, hosted guide, public catalog, and
pub.dev media. The public catalog now presents fourteen native chart families.
The dark capability example also drove a shared `ChartLegend` fix so a
configured legend text style is honored by the widget actually used for Radar.

### Scope

- full dedicated page and standard Options groups;
- authored examples plus deterministic stress/playground;
- Gallery and Chart Types cards;
- mobile/constrained surface;
- hosted guide, API docs, README/feature matrix, pub.dev images;
- clear “when to use / when not to use” content.

### Gate

A new user can identify the question Radar answers, build the screenshot case,
inspect exact data, customize it, select it, transport it, and find the guide
without reading implementation source.

## Slice 7 — Hardening and release gate

**Delivery status (2026-08-07):** Automated hardening is complete. The full
package suite passes with 4,693 tests and 10 intentional skips; the combined
Radar/catalog/direct-route showcase suite passes 88 tests; changed production
sources and the complete example package analyze cleanly; deterministic public
media, documentation drift checks, and the release web build pass. A dedicated
12-profile x 64-category benchmark paints in 0.892 ms average on the review
machine, comfortably inside the 16.67 ms frame budget. The publish dry-run
validates package content and reports only the expected uncommitted-worktree
warning. Desktop/network visual review passed on 2026-08-11; delivery
reconciliation against current `origin/master` remains before PR handoff.

## Slice 8 — Presentation and inspector parity

**Delivery status:** Implementation assembled on 2026-08-11 after review of the
actual public surface found that passing infrastructure and round-trip gates
did not prove the complete visual-customization contract. Portable web,
gradient, shadow, marker, and data-label styling now round-trips through the
public model, renderer, artifacts, generated Dart, fluent, and AI surfaces.
Seven stable authored presentations expose deliberate visual combinations;
the eighth Playground now provides a seeded full-property generator and timed
playback so unusual combinations can be reproduced rather than dismissed as
random noise. That generator exposed a real compact-pane failure when large
shadow and label reserves consumed the pane; layout now constrains those
reserves proportionally and a renderer regression test protects the case.
An adversarial pass on 2026-08-12 expanded the surface to eleven presentations,
including compact KPI, risk-exposure, and deliberately long-label cases, plus
three touch-first recipes that reuse the one mounted workbench rather than
creating hidden chart runtimes. It also found and fixed a native renderer defect:
polygon webs painted circular outer boundaries even though their rings and
spokes were polygonal. Regression coverage now protects polygon/circle
boundaries, all-zero automatic domains, category/profile/value semantics,
160% text scaling, compact panes, and 28 px touch hit radii. Focused automated
review, maintainer visual review, package generation drift, release-web
compilation, and package validation are complete. The mobile clean presentation
now removes legends entirely and gives Radar the full available chart height;
the opt-in axes presentation retains theme-correct legend chrome.

### Scope

- portable Radar gradient and shadow/elevation models with renderer, codec,
  hydration, source, grammar, fluent, and AI parity;
- independently configurable web rings, spokes, boundary, and radial/category
  label appearance rather than theme-only rendering;
- complete profile stroke, fill, marker, data-label, palette, and opacity
  controls in the standard inspector;
- complete legend, tooltip, interaction, and selection controls using the
  existing shared configuration models;
- authored high-contrast, comparison, normalized-scorecard, and dense-stress
  presentations plus a deterministic playground/property randomizer;
- focused visual, portability, constrained/mobile, and regression tests for
  every newly exposed property.

### Gate

Every inspector control must modify the same public portable configuration a
package user can author. The authored examples must visibly differ in more than
data shape, and gradients, shadows, web styling, label styling, tooltips,
legend behavior, selection, artifacts, and generated source must survive the
standard Radar product workflow.

### Focused verification

- model validation and copy/equality;
- geometry properties for 3, 4, 6, 12, 24, and 64 categories;
- polygon/circle grids, clockwise/counter-clockwise, start angles;
- multi-series paint order, fill opacity, markers, clipping, selected overlays;
- hit boundaries, shared tracking, keyboard, semantics, mobile long press;
- label collision, 200% text, high contrast, dark theme, constrained panes;
- entrance/update/topology/reduced-motion behavior;
- artifact capability failures, hydration, table/CSV, Source compile and
  round-trip, grammar/fluent/AI completeness;
- deterministic goldens and performance budgets.

### Repository-wide gate

- `dart format --output=none --set-exit-if-changed .`
- package and example `flutter analyze`
- focused tests, then full `flutter test`
- showcase direct-route smoke tests and release web build
- `dart pub publish --dry-run`
- live local visual review on desktop and network/mobile URLs
- documentation link and hosted-media verification
- update BC-0061 evidence and residual risk before review/PR handoff.

## Performance targets

Radar is normally small, but complexity must still be explicit:

- geometry and paint are O(series × categories);
- hit testing uses direct spoke/category candidates before nearest-point checks;
- base web/profile paths are cached separately from hover/selection overlays;
- semantics and visible labels are density-bounded without dropping source
  rows;
- the stress gate covers at least 12 series × 64 categories and repeated
  selection/resize/update without unbounded allocation or frame stalls.

## Review questions

The implementation can begin without reopening the family boundary. Product
review should confirm these deliberate choices:

1. Canonical public name `Radar`, with Spider/Spiderweb as aliases.
2. Shared-scale, non-negative, complete-category V1 rather than permissive
   independent axes.
3. Polygon grid as the Spider default and circle as an option.
4. No smoothing, partial sweep, hollow center, or mixed Polar Column in V1.
5. Dedicated Radar page with the supplied Budget vs spending example as the
   first authored review surface.
