# Pie chart implementation investigation

Status: **In progress — Slices 1–2 complete locally; live rendering review open**

This note preserves the July 2026 investigation into adding pie charts as the
first new radial chart type in Braven Charts. It records the recommended
product contract, architectural seams, affected systems, implementation
slices, and acceptance gates. It is a design input, not a statement that the
feature has shipped.

The investigation was performed against `origin/master` at `1f72470e` in the
dedicated `feature/pie-chart` worktree, then refreshed against the merged
Workbench release at `417498fe` (`v0.2.0`). The refresh confirmed that the
radial rendering seams remain unchanged. Pie table support must extend the
package-owned `ChartTableModel`/`ChartDataTable` path and preserve canonical
`ChartPointRef` identities so it works inside `BravenChartWorkbench` without a
consumer-owned parallel model.

## Executive recommendation

Implement pie as a first-class radial chart type inside `BravenChartPlus`, not
as a separate widget and not as another paint branch inside the existing
Cartesian `SeriesElement`.

The slice geometry is small and deterministic. The significant work is making
layout, interaction, legends, artifacts, tables, accessibility, documentation,
and the showcase correctly understand a chart without Cartesian axes.

The recommended architectural shape is:

- an internal Cartesian/radial layout distinction;
- a public `PieChartSeries` using the existing `ChartDataPoint` transport
  model;
- a pure pie-geometry calculator;
- a dedicated `PieSeriesElement`;
- generalized data-element contracts for cache, hit testing, tooltip,
  selection, and semantics;
- slice-aware legend and table projections; and
- built-in artifact capability `series.pie`.

## Recommended first-release boundary

### Included

- One `PieChartSeries` per chart.
- No mixing of pie and Cartesian series.
- A category label and a non-negative numeric contribution per slice.
- Stable slice ordering.
- Theme palette colors plus per-slice color overrides.
- Configurable start angle, direction, outer radius, border, and slice gap.
- Category, value, percentage, and combined data-label content.
- Inside and outside labels with deterministic collision handling.
- Slice-aware legend entries.
- Hover highlight, tooltip, tap selection, and optional explode offset.
- Existing point hover/tap callbacks using the source `ChartDataPoint`.
- Responsive layout, themes, and reduced-motion behavior.
- Keyboard navigation and assistive semantics.
- Artifact extraction, canonical JSON, hydration, save/restore, and previews.
- A native `Category | Value | Share` data-table projection with copy and CSV.
- AI/tool schema support.
- A polished showcase surface and complete public documentation.

### Deferred

- Doughnut charts, while keeping the geometry capable of an inner radius.
- Multiple rings or nested pies.
- Rose/Nightingale charts.
- Semi-circular gauges.
- Mixed radial and Cartesian series.
- Automatic small-slice grouping into `Other`.
- Gradients, image shaders, and per-slice radius mapping.
- Streaming-specific pie behavior.

## Data contract

The existing `ChartDataPoint` already transports the information needed by a
pie slice:

- `x`: stable numeric ordinal;
- `y`: slice contribution;
- `label`: displayed category;
- `pointStyle.color`: optional slice color override;
- `metadata`: host-owned slice metadata.

The explicit constructor can therefore remain structurally consistent with
other series:

```dart
PieChartSeries(
  id: 'revenue-share',
  name: 'Revenue share',
  unit: 'USD',
  points: const [
    ChartDataPoint(x: 0, y: 42, label: 'Subscriptions'),
    ChartDataPoint(x: 1, y: 31, label: 'Services'),
    ChartDataPoint(x: 2, y: 27, label: 'Hardware'),
  ],
);
```

An ergonomic convenience constructor should hide the ordinal bookkeeping:

```dart
PieChartSeries.fromMap(
  id: 'revenue-share',
  values: const {
    'Subscriptions': 42,
    'Services': 31,
    'Hardware': 27,
  },
);
```

Recommended validation policy:

- finite positive values produce visible slices;
- zero values remain in transported data but do not produce visible geometry;
- an all-zero dataset renders the configured empty state;
- negative, `NaN`, and infinite values fail validation explicitly;
- categories should be non-empty after trimming;
- duplicate labels are allowed in the explicit point API, because ordinal and
  point index remain the stable identity;
- a pie chart accepts exactly one pie series in the first release.

Validation must not depend only on debug assertions. Hydration and runtime
construction require deterministic release-mode behavior and actionable
diagnostics.

## Current architecture impact

### Public models and convenience factories

`ChartType` and `SeriesStyle` currently enumerate line, area, bar, and scatter.
Both require a pie member, with exhaustive switches updated throughout the
package and showcase.

`BravenChartPlus.fromValues` and `BravenChartPlus.fromMap` currently accept a
`chartType` argument but always construct `LineChartSeries`. `fromJson` does
switch on the requested type. This is existing API debt that must be resolved
or clearly separated from the new pie convenience API.

The recommended direction is a `PieChartSeries.fromMap` constructor rather
than changing the existing numeric-key semantics of `BravenChartPlus.fromMap`.
The misleading `chartType` behavior in the existing factories should still be
fixed or deprecated as part of the touched public surface.

### Element conversion and rendering

`DataConverter.seriesToElements` currently converts every series into the
single Cartesian `SeriesElement`. That class owns line, area, bar, and scatter
painting, Cartesian bounds, labels, selection, and hit testing.

Adding another large paint branch there would intensify an existing
single-class concentration. Pie should instead use a `PieSeriesElement` backed
by a pure immutable geometry result.

`ChartRenderBox.performLayout` currently reserves Cartesian axis and scrollbar
space and constructs a `ChartTransform`. Its cache, tooltip, crosshair, and
event paths frequently filter for the concrete `SeriesElement` type.

Introduce an internal layout discriminator such as:

```dart
enum ChartLayoutKind { cartesian, radial }
```

The radial branch should:

- use the available content rectangle directly;
- reserve legend and outside-label space deliberately;
- calculate its radius from the shorter available dimension;
- skip axes, grid, crosshair, scrollbars, normalization, and Cartesian
  annotations;
- keep title, subtitle, loading, empty, toolbar, theme, and preview behavior;
- paint through the existing display-list cache via a generalized
  data-series-element contract.

### Pure geometry

For every visible slice:

```text
total = sum(visible values)
sweep = value / total * 2pi
midAngle = startAngle + sweep / 2
explodeOffset = distance * (cos(midAngle), sin(midAngle))
```

The geometry result should preserve:

- source point and point index;
- start, sweep, and middle angles;
- center, inner radius, outer radius, and explode offset;
- fill and border colors;
- wedge path and bounds;
- tooltip/semantics centroid;
- inside-label anchor;
- outside-label anchor and connector origin.

Use Flutter's optimized `Canvas.drawArc` when it is sufficient for painting.
Use a closed wedge `Path` where borders, clipping, or precise `Path.contains`
hit testing require it. Keep angle normalization and wraparound logic in the
pure geometry layer so it can be exhaustively unit tested.

### Labels

Labels are the most complex visual part of a production pie chart.

Recommended configuration concepts:

- visible or hidden;
- inside or outside position;
- category, value, percentage, or combined content;
- minimum share or minimum sweep before a label is eligible;
- label padding and connector styling;
- collision strategy.

Recommended outside-label algorithm:

1. Calculate each label's radial anchor at the slice mid-angle.
2. Split candidates into left and right lanes.
3. Sort each lane by desired vertical position.
4. Sweep downward with a minimum label gap.
5. Sweep upward if the lane exceeds the available bottom bound.
6. Clamp to the content rectangle.
7. Hide the lowest-priority labels if the lane still cannot fit.
8. Draw deterministic two-segment connectors from the slice to the lane.

The algorithm should be deterministic across rebuilds and independent of
pointer state to prevent visible label jitter.

### Interaction and tooltips

The existing marker search and tooltip renderer assume Cartesian
`SeriesElement` points. Pie requires a generalized data-hit result containing:

- series ID;
- point index;
- screen-space anchor;
- original data point;
- category, raw value, formatted value, total, and share;
- hover/selection state.

Hit testing can first reject points outside the outer radius or inside a future
inner radius, then resolve a normalized polar angle. The final wedge path may
be used for boundary-accurate confirmation, particularly with gaps and
exploded slices.

Recommended interactions:

- pointer hover highlights the slice and shows its tooltip;
- tap selects the slice and optionally applies an explode offset;
- tapping the background clears selection;
- existing point callbacks receive the source point and pie series ID;
- pan, zoom, crosshair, and scrollbars are explicitly inapplicable;
- arrow keys move between slices, Enter/Space select, and Escape clears.

### Legend

The automatic legend currently produces one item per series. Pie needs one
item per slice, derived from category, resolved slice color, value, and share.

A generalized internal legend-item model is preferable to making the legend
inspect `PieChartSeries` directly. First-release legend entries may select a
slice. Hiding individual slices should be deferred unless view state and
artifact persistence gain a stable hidden-slice identity model.

### Artifacts and previews

Add a built-in `pie` series codec and required capability `series.pie` to:

- series document encoding and decoding;
- the built-in hydrator capability and model sets;
- nested series encoding used by legend annotations;
- extraction and canonical JSON tests.

The existing point document already preserves `x`, `y`, `label`, metadata, and
point style, so no new point payload is required. Pie style properties belong
in the series style document.

No schema-version bump is required merely to add a capability-gated built-in
series type. Older readers will reject the unsupported `series.pie`
capability rather than misrendering it.

Preview capture should work through the existing revision-bound repaint
boundary once radial rendering and hydration are complete.

### Data table, copy, and CSV

The current table projects a Cartesian X column plus one or more Y-series
columns. Showing ordinal values such as `0, 1, 2` would be misleading for pie.

Pie should have an explicit projection:

| Category | Value | Share |
| --- | ---: | ---: |
| Subscriptions | 42.00 | 42.00% |

Requirements:

- preserve the ordinal and original point reference internally;
- use the point label as the category display;
- format values through the series/axis formatter contract;
- calculate share from the same validated total used for rendering;
- retain raw numeric values for sorting and CSV;
- include category, value, and share in row copy, dataset copy, and CSV;
- preserve existing clipboard limits, virtualization, theming, and semantics.

### AI and serialized configuration

Add `pie` to the tool schema and builder. The schema description must state:

- exactly one series;
- a non-empty point label for each category;
- a non-negative finite `y` contribution;
- `x` is only a stable ordering index;
- axes, crosshair, pan, and zoom are not pie features.

The tool's current global claim that every chart supports pan, zoom, crosshair,
and multiple overlaid series must be made chart-type-aware.

### Accessibility

The rendered chart currently has keyboard focus handling, but the general data
canvas does not expose a per-datum semantics structure. Pie should establish a
reusable data-element semantics seam rather than relying on color or a single
chart-level label.

Minimum behavior:

- announce category, formatted value, share, position, and selection state;
- allow keyboard traversal and activation;
- keep labels or legend text available so color is not the only cue;
- expose the data-table alternative;
- support text scaling and high-contrast themes;
- honor `MediaQuery.disableAnimationsOf`.

Example announcement:

```text
Services, 31 US dollars, 31 percent, slice 2 of 3, selected.
```

## Showcase and documentation

Pie should become a real user-facing feature showcase, not a technical lab.

At the first interactive checkpoint:

- add a dedicated Pie Charts page following the structure and quality of the
  Interaction, Annotations, and Live Stream pages;
- add pie to the Chart Types comparison page;
- demonstrate regeneration, labels, colors, selection/explode, tooltips,
  responsive layout, and the table alternative;
- run the Flutter web development app from the pie feature worktree and keep
  the review URL available before PR promotion.

Before release, update:

- root and example README feature lists;
- public API overview;
- feature coverage matrix;
- chart-type guide;
- artifact guide and compatibility notes;
- dartdoc on every public pie model and configuration field.

The current `docs/guides/chart-types.md` contains obsolete layer-oriented
architecture and should be rewritten against `BravenChartPlus` rather than
extended as if it were current.

## Implementation sequence

### Slice 1: radial foundation and public models

Status: **Complete locally.**

- Add layout-kind resolution and mixed-series validation.
- Add pie series and style/config models.
- Add ergonomic category/value construction.
- Implement pure geometry and validation tests.

### Slice 2: rendering and responsive labels

Status: **Complete locally and available in the live showcase review.**

- Add `PieSeriesElement` and radial layout.
- Integrate cache invalidation and theme palette resolution.
- Add borders, gaps, explode geometry, and inside/outside labels.
- Add light, dark, high-contrast, and responsive goldens.
- At the first paintable checkpoint, add the dedicated Pie Charts showcase
  route and run the Flutter web development app for live review.

### Slice 3: interaction, legend, and accessibility

- Generalize data hits and tooltip payloads.
- Add hover, tap, selection, callbacks, and keyboard behavior.
- Add slice legend entries and data-element semantics.
- Verify reduced motion and text scaling.

### Slice 4: portability and data surfaces

- Add artifact codec/hydrator capability and round-trip tests.
- Verify restored preview capture.
- Add category/value/share table, sorting, copy, and CSV.
- Add AI schema and builder support.

### Slice 5: showcase, documentation, and release gates

- Polish the already-live Pie Charts showcase page and its Chart Types
  integration after interaction and data surfaces land.
- Complete public guides, examples, dartdoc, and feature matrix.
- Run performance, package, showcase, publish, and live web-review gates.

## Acceptance gates

- Geometry tests for one slice, multiple slices, angle wraparound, gaps,
  exploded offsets, and boundary hit testing.
- Validation tests for empty, all-zero, negative, `NaN`, and infinite data.
- Tests for stable color resolution and per-slice overrides.
- Dense-label, small-container, text-scale, and collision tests.
- Interaction tests for hover, tap, background clear, keyboard, and callbacks.
- Semantics tests for slice value, share, order, and selection announcements.
- Artifact encode/decode, canonical JSON, capability, hydration, and preview
  round trips.
- Table, sort, row copy, dataset copy, clipboard-limit, and CSV tests.
- AI builder and schema tests.
- Rendering benchmarks with labels enabled and disabled.
- `flutter analyze lib`.
- `flutter test`.
- `flutter analyze` in `example`.
- dartdoc generation.
- `dart pub publish --dry-run`.
- `git diff --check` before review readiness.

## Approved first-release decisions

The following defaults were approved before Slice 1 implementation began:

1. One pie series and no mixed Cartesian composition in the first release.
2. Strict rejection of negative and non-finite slice values.
3. Zero slices omitted; all-zero data uses the empty state.
4. Smart outside labels included in the first release.
5. Tap selects and optionally explodes a slice.
6. Slice legend entries select but do not hide slices initially.
7. Doughnut remains deferred while geometry retains an inner-radius seam.

## Research references

- Flutter arc rendering: <https://api.flutter.dev/flutter/dart-ui/Canvas/drawArc.html>
- Flutter path hit testing: <https://api.flutter.dev/flutter/dart-ui/Path/contains.html>
- Flutter semantics: <https://api.flutter.dev/flutter/widgets/Semantics-class.html>
- Flutter reduced motion: <https://api.flutter.dev/flutter/widgets/MediaQuery/disableAnimationsOf.html>
- Chart.js pie and doughnut configuration: <https://www.chartjs.org/docs/latest/charts/doughnut>
- Apache ECharts basic pie and all-zero behavior: <https://echarts.apache.org/handbook/en/how-to/chart-types/pie/basic-pie/>
- Apache ECharts rose pie: <https://echarts.apache.org/handbook/en/how-to/chart-types/pie/rose/>
- Syncfusion Flutter pie features: <https://help.syncfusion.com/flutter/circular-charts/chart-types/pie-chart>
- Syncfusion Flutter circular data labels: <https://help.syncfusion.com/flutter/circular-charts/datalabel>
- Syncfusion Flutter circular accessibility: <https://help.syncfusion.com/flutter/circular-charts/accessibility>
- `fl_chart` pie configuration: <https://pub.dev/documentation/fl_chart/latest/fl_chart/PieChartData-class.html>
