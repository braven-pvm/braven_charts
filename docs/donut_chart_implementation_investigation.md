# Donut chart implementation investigation

Status: **Slices 1–5 implemented; local 0.5.0 release candidate awaiting approval**

This note defines the proposed first-class Donut chart for Braven Charts. It
assumes the variable-radius Pie extension on `feature/donut-chart`: angle and
outer radius can already encode two complete metrics, and the geometry already
produces annular-sector paths when given a non-zero inner radius.

The product name and Dart API use **Donut**. External libraries often spell it
“doughnut”; documentation may mention that spelling only for searchability.

## Executive recommendation

Add Donut as a first-class radial category series, but reuse the established
Pie geometry, painting, interaction, labels, legend, table, artifact, and
accessibility machinery.

Donut is not a new paint system. Its defining geometry is a shared non-zero
inner radius plus optional center content. It should still be discoverable as
`ChartType.donut`, constructible as `DonutChartSeries`, and transported as a
distinct artifact type so users and older readers never have to infer the
chart type from a numeric style value.

The clean architecture is:

- introduce a small `RadialCategorySeries` base for the common validated
  category contract;
- keep `PieChartSeries` and add `DonutChartSeries` as concrete public models;
- share one pure radial-sector geometry calculator and one radial series
  element;
- keep Pie's inner radius fixed at zero;
- require Donut's inner radius to be greater than zero and less than one;
- add portable center-content configuration rather than an unserializable
  arbitrary widget in V1; and
- preserve exact source-point identity through chart, legend, table,
  controller, semantics, artifact, and preview paths.

## What Slice 1 already establishes

Variable-radius Pie is the first Donut-lane slice because it hardens the radial
geometry before an inner hole is public:

- `ChartDataPoint.y` controls angular share;
- optional `PointStyle.size` carries a raw second radius metric;
- `PieSliceRadiusConfig` labels and scales the second metric;
- area scaling is the perceptual default and linear radius is opt-in;
- every category must provide a finite, non-negative radius value;
- tooltips, semantics, tables, copy/CSV, AI input, and artifacts expose the
  second metric; and
- `series.pie.variable-radius.v1` prevents older readers from flattening the
  encoding silently.

This matches the common variable-pie model: Highcharts describes angle as the
Y dimension, radius as the Z dimension, and defaults the radius mapping to
area because it better matches human perception.

## Proposed public API

```dart
final series = DonutChartSeries.fromMap(
  id: 'registrations',
  name: '2023 Norway car registrations',
  unit: 'vehicles',
  values: const {
    'EV': 690665,
    'Hybrids': 374166,
    'Diesel': 1064793,
    'Petrol': 748196,
  },
  donutStyle: const DonutChartStyle(
    innerRadiusFactor: 0.62,
    startAngleDegrees: -90,
    sweepAngleDegrees: 360,
    sliceGap: 3,
    cornerRadius: 8,
  ),
  centerContent: const DonutCenterContent(
    label: 'Total',
    valueMode: DonutCenterValueMode.total,
  ),
  dataLabels: const PieDataLabelConfig(
    position: PieDataLabelPosition.outside,
    content: PieDataLabelContent.percentage,
  ),
);
```

Recommended models:

```dart
enum DonutCenterValueMode {
  total,
  selectedValue,
  selectedOrTotal,
  custom,
}

class DonutCenterContent {
  final bool isVisible;
  final String? label;
  final DonutCenterValueMode valueMode;
  final String? customValue;
  final LabelStyle? labelStyle;
  final LabelStyle? valueStyle;
}

class DonutChartStyle extends PieChartStyle {
  final double innerRadiusFactor;
  final double sweepAngleDegrees;
}
```

`DonutChartStyle` should reuse the existing radial fields—start angle,
direction, outer radius, gap, border, gradient, explode, opacity, corner,
shadow, selected glow, and animation—while adding only Donut-specific
geometry. The exact implementation may use inheritance or shared composition;
the public API should not force users to configure a nested “Pie style” for a
Donut.

## Geometry and validation

### Inner radius

`innerRadiusFactor` is relative to the maximum outer radius and must be finite
in `(0, 1)`. A value near one can leave too little visible ring thickness for
touch targets, labels, borders, and rounded corners, so V1 should document a
recommended product range of approximately `0.35–0.8` while validating only
the mathematical boundary.

The package should continue reserving explode, focus, border, shadow, and glow
extents before choosing the maximum outer radius. The hole must not cause a
selected outer slice to clip at a viewport edge.

### Variable outer radius with a hole

Variable radius remains available on Donut. Interpret
`PieSliceRadiusConfig.minimumFactor` across the **available ring thickness**:

```text
outerFactor = innerFactor +
    normalizedRadiusFactor * (1 - innerFactor)
```

This preserves current Pie behavior when `innerFactor == 0`, guarantees every
Donut segment remains outside the hole, and avoids silently clamping small
second-metric values into invisible or inverted sectors.

### Start and end angle

Add `sweepAngleDegrees` in `(0, 360]`, defaulting to 360. Together with the
existing `startAngleDegrees` and `clockwise`, it supports full, semi-, and
quarter Donuts without an ambiguous absolute end-angle convention. Angular
shares divide the configured sweep, not an assumed full circle.

The chart center should remain stable while partial arcs are laid out. V1 can
center the full logical ring; a later `centerOffset` is safer than
auto-recentering based on the current arc and moving labels between updates.

### Paths, gaps, and corners

Pie now exposes `PieCornerTreatment.roundAll`, `outerOnly`, and
`circularCenter`. Donut should reuse this explicit geometry policy rather than
reintroducing implicit tip rounding. Its configured inner radius remains the
authoritative circular opening; the Pie-only derived circular-center gap is a
compatibility bridge, not Donut's sizing contract.

The existing `Path`-based hit test already rejects the center when an inner
radius is non-zero. Geometry tests must cover clockwise and counter-clockwise
annular sectors, wraparound, physical gaps, rounded inner and outer corners,
selection explosion, variable outer radii, and animation progress.

## Center content

The center is the major user-visible capability that Pie does not have.
Support portable text-first content in V1:

- total value;
- selected slice value;
- selected value with total fallback;
- explicit custom text;
- optional short label; and
- theme/series `LabelStyle` overrides.

Center content must update from the same durable `ChartPointRef` selection used
by slices, legends, and tables. It should be constrained to the measured hole,
scale or ellipsize deterministically, honor text scaling, and be included in
PNG previews and artifacts.

Do not accept an arbitrary `Widget` in the first release. A widget builder is
runtime code, does not survive canonical JSON, complicates the custom
`RenderBox` boundary, and could make preview/restored output diverge. A future
host overlay API can be added explicitly with runtime-binding diagnostics.

## Interaction, labels, and accessibility

Donut should inherit the mature Pie behavior:

- pointer, keyboard, legend, table, and controller selection resolve one
  source point;
- selected tooltips appear for every selection path and clear on deselection;
- tooltip anchors track current annular geometry;
- inside labels are placed at the midpoint of the visible ring thickness;
- outside labels retain compact collision-managed lanes;
- center content does not intercept slice hit testing unless a future center
  action is explicitly configured; and
- semantics announce category, formatted value, share, optional radius metric,
  ordinal, and selection state.

The center summary should be one chart-level semantics node, not repeated on
every slice. High-contrast, text scaling, reduced motion, and non-color-only
meaning remain release gates.

## Table, export, and controller behavior

Donut uses the existing native category projection:

```text
# | Category | Value | [optional radius metric] | Share
```

No center-content row is added because it is a presentation summary, not a
source datum. Table rows retain `ChartPointRef`; selection can be read or
changed through `BravenChartController` exactly as for Pie.

## Artifacts and AI

Recommended built-in capabilities:

- `series.donut`
- `series.donut.style.v1`
- `series.donut.center-content.v1` when portable center content is visible
- `series.donut.variable-radius.v1` only when the optional second metric is
  active

The document must preserve inner radius, sweep angle, center-content mode and
styles, all inherited radial appearance, raw second-metric values, and durable
selection. An older reader should reject Donut rather than decode it as Pie and
lose the hole or center meaning.

AI/tool input should add `chart_type: "donut"`,
`donut_inner_radius_factor`, `donut_sweep_angle`, and portable center-content
fields. The one-series/no-Cartesian-axis boundary remains explicit.

## First-release boundary

### Include

- one `DonutChartSeries` per chart;
- configurable inner and outer radii;
- full and partial sweeps;
- all established Pie slice styling and interaction;
- portable total/selected/custom center text;
- optional variable outer radius;
- native table/copy/CSV;
- artifacts, hydration, preview, AI schema, semantics, and controller APIs;
- Gallery, Chart Types, a dedicated Donut showcase, public docs, and pub.dev
  media.

### Defer deliberately

- arbitrary center widgets/builders;
- multiple concentric rings or nested browser-style hierarchies;
- radial-bar/progress semantics;
- drilling from a grouped or parent segment;
- image shaders and 3D effects; and
- multiple radial series in one chart.

## Implementation slices

1. **Variable-radius Pie foundation — implemented**
   Model, geometry, tooltips, semantics, table/export, AI, artifacts, tests,
   docs, and the live Pie story.
2. **Donut model and annular geometry — implemented**
   Add first-class type/style, shared radial base, inner radius, partial sweep,
   validation, render/hit tests, and artifact round trips.
3. **Center content and selection — implemented**
   Add total/selected/custom modes, styling, text measurement, semantics, and
   controller/legend/table selection tests.
4. **Public product surfaces — implemented**
   Add Chart/Data/Split Donut showcase, options, capture/restore, Gallery,
   Chart Types, docs, AI examples, and pub.dev media.
5. **Release hardening — implemented locally**
   Full test/analyze, benchmarks, direct-route debug and release web checks,
   narrow/large-text/high-contrast/reduced-motion review, dartdoc, package
   dry-run, and local user approval before PR.
6. **V1.1 radial entrance motion — implemented locally**
   Preserve `grow` as the compatibility default; add deterministic angular
   `sweep` and geometry-preserving `fade`; serialize theme/series overrides;
   expose the modes to AI input; add a controller replay command; honor reduced
   motion; and make all three modes directly testable in the public Donut
   showcase.
7. **V1.1 source-preserving small-slice grouping — implemented locally**
   Project qualifying positive points into one visible aggregate while keeping
   the original series immutable; carry every source index through geometry,
   hits, semantics, legend/table/controller selection, artifacts, hydration,
   and AI input; expose a direct public showcase story. Variable-radius
   grouping remains rejected until a second-metric aggregation policy is
   explicit.
8. **Responsive Split polish — implemented locally**
   Keep radial legend item geometry invariant across selection, auto-fit the
   native table to its projection width, and expose an accessible drag/keyboard
   divider without remounting the chart or changing durable point identity.

The motion slice deliberately excludes interpolation between old and new data,
per-slice delay/stagger controls, spring physics, selection-motion redesign,
and multi-ring sequencing. Those require separate lifecycle and identity
contracts rather than additional enum values in this slice.

Release evidence for the local feature worktree at this checkpoint:

- all 1,715 package tests and all 113 showcase tests pass;
- package, showcase, focused Donut, benchmark, accessibility, and deterministic
  media analysis report no issues;
- the advanced 24-slice partial/variable-radius Donut paint benchmark averages
  1.295 ms against a 16.67 ms frame budget;
- large-text/high-contrast semantics and reduced-motion behavior have explicit
  widget coverage;
- both the GitHub Pages base-href build and root-base local release build pass,
  including Flutter's WebAssembly dry run;
- fresh Chrome sessions paint Donut wide and compact routes, Chart Types, and
  Gallery with no severe console entries;
- dartdoc generates the public library with zero warnings and zero errors;
- pub.dev dry-run validates the 7 MB archive with only the expected dirty-tree
  warning before approval/commit; and
- local `pana` awards 150/160, losing only screenshot-processing points because
  the host does not have the external WebP command-line tools installed.

## Acceptance gates

- A uniform Donut is identical to Pie except for its intentional hole and
  center content.
- Variable-radius Donut never crosses or collapses into its shared inner hole.
- Selection, tooltip, label, and center anchors remain correct after resize,
  angle, gap, radius, and data changes.
- Chart, table, legend, callbacks, controller, restored runtime, and preview all
  resolve the same source identity.
- Direct showcase routes work on first load and browser refresh.
- `flutter test`, `flutter analyze`, `flutter build web --release`, dartdoc,
  and package dry-run pass before PR.

## External implementation references

- Highcharts variable Pie API (Y controls angle, Z controls radius, area is the
  perceptual default):
  <https://api.highcharts.com/highcharts/plotOptions.variablepie.minPointSize>
- Highcharts Pie inner-size/thickness contract:
  <https://api.highcharts.com/highcharts/plotOptions.pie.innerSize>
- Syncfusion Flutter Doughnut features (inner radius, rounded corners, explode,
  partial angles, and grouping):
  <https://help.syncfusion.com/flutter/circular-charts/chart-types/doughnut-chart>
- Syncfusion Flutter circular annotations for custom center placement:
  <https://help.syncfusion.com/flutter/circular-charts/annotations>
- fl_chart section model (independent value, radius, gradient, corner, title,
  and badge placement):
  <https://pub.dev/documentation/fl_chart/latest/fl_chart/PieChartSectionData-class.html>
