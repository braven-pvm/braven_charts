# Heatmap charts

Heatmap is a native Cartesian series for encoding an independent measured
value across a two-dimensional matrix. Use it for activity grids, day/hour
temperature, calendars, service health, correlation matrices, and dense
measured fields.

Open the runnable
[Heatmap showcase](https://braven-pvm.github.io/braven_charts/?page=heatmap-charts)
to compare six configurations and inspect each one in Chart, Data, Split, and
Source modes.

## Model one cell explicitly

`HeatmapDataPoint` owns three independent channels: X and Y locate the cell;
`value` selects its colour.

```dart
final cells = <HeatmapDataPoint>[
  HeatmapDataPoint(x: 0, y: 0, value: 18, pointKey: 'mon-am'),
  HeatmapDataPoint(x: 1, y: 0, value: 24, pointKey: 'tue-am'),
  HeatmapDataPoint.missing(x: 2, y: 0, pointKey: 'wed-am'),
];

final series = HeatmapChartSeries(
  id: 'temperature',
  name: 'Temperature',
  unit: '°C',
  points: cells,
  colorScale: HeatmapColorScale.sequential(
    colors: const [
      Color(0xFFDBEAFE),
      Color(0xFFFEF3C7),
      Color(0xFFF97316),
    ],
    label: 'Temperature',
  ),
);
```

Missing cells are not zero-valued cells and do not carry NaN. They retain
their row/column identity, paint with the configured missing colour, and remain
distinguishable in tables, CSV, artifacts, and generated source. Duplicate
cell coordinates are rejected.

## Distinguish empty values from missing cells

Some matrices use a real finite value to mean an observed empty state. A
contribution calendar, for example, normally treats zero as “no contributions”
rather than missing data. Configure that presentation independently:

```dart
final contributions = HeatmapChartSeries(
  id: 'contributions',
  points: contributionCells,
  colorScale: HeatmapColorScale.sequential(
    colors: const [
      Color(0xFFBBF7D0),
      Color(0xFF15803D),
    ],
    min: 0,
    max: 12,
    label: 'Contributions',
  ),
  emptyValueStyle: const HeatmapEmptyValueStyle(
    value: 0,
    fillColor: Color(0xFFE5E7EB),
    borderColor: Color(0xFFCBD5E1),
    borderWidth: 1,
    showLabel: false,
    showInLegend: true,
    legendLabel: 'No contributions',
  ),
);
```

The match is exact and finite. A styled empty value remains part of the colour
domain, Data and Source modes, artifacts, tooltips, hit testing, and durable
selection. The style only overrides its fill, optional border, label
visibility, and optional legend swatch. Set `emptyValueStyle` to `null` to use
the ordinary colour scale for every finite value. Continue to use
`HeatmapDataPoint.missing` when no observation exists.

## Choose a colour scale

Use `HeatmapColorScale.sequential` for ordered magnitude,
`HeatmapColorScale.diverging` when a meaningful midpoint separates negative
and positive deviation, or `HeatmapColorScale.threshold` for named status
bands.

Every scale validates finite domains and deterministic colour stops. Automatic
domains come from non-missing cells. Explicit domains can clamp outliers or
leave them outside the colour interval, and `reverse` changes palette direction
without changing source values. `HeatmapColorLegend` reads the same scale as
the renderer and shows either a continuous ramp or discrete bands.

### Share one domain across small multiples

Independent Heatmaps normally resolve independent automatic domains. When
colour must remain comparable across several panels, derive one portable
continuous domain and apply it to every scale:

```dart
final domain = HeatmapSharedColorDomain.fromSeries(
  [checkout, search, reporting],
  paddingFraction: 0.05,
);

final comparablePanels = [
  for (final series in [checkout, search, reporting])
    series.copyWith(
      colorScale: domain.scaleFor(series.colorScale, showLegend: false),
    ),
];
```

Render each panel as an ordinary `BravenChartPlus`, then render one
`HeatmapColorLegend` from a representative series using the same fixed scale.
The domain excludes missing cells but retains every finite measured value,
including zero, and round-trips through JSON with source-series provenance.
Threshold scales are not accepted because their fixed semantic bands already
own comparison semantics without a continuous minimum/maximum domain.

### Filter from a continuous legend

`HeatmapValueFilter` is a portable, inclusive measured-value window. Attach it
to one series to dim excluded cells, or use `HeatmapValueFilterMode.hide` to
remove excluded cells from painting and hit testing while retaining their
source data:

```dart
final filtered = series.copyWith(
  valueFilter: const HeatmapValueFilter(
    minimumValue: 20,
    maximumValue: 80,
    mode: HeatmapValueFilterMode.dim,
    excludedOpacity: 0.14,
  ),
);

HeatmapColorLegend(
  series: filtered,
  onValueFilterChanged: (filter) {
    setState(() => series = series.copyWith(
      valueFilter: filter,
      clearValueFilter: filter == null,
    ));
  },
);
```

Use the same filter instance across small multiples when one legend should
control every panel. Filtering does not recalculate the colour domain, mutate
cells, or remove rows from tables, generated Source, and artifacts. Missing
cells remain visible through their missing-cell presentation. The interactive
legend control is available for continuous scales; threshold bands retain
their discrete semantic contract.

### Present independent colour axes in one chart

Multiple `HeatmapChartSeries` values can share one Cartesian matrix while each
series retains its own measured-value unit, colour domain, palette, and value
filter. `HeatmapColorLegendGroup` presents those scales as one compact legend
surface and routes filter changes back by series ID:

```dart
HeatmapColorLegendGroup(
  series: [latency, errorRate],
  onValueFilterChanged: (seriesId, filter) {
    updateSeriesFilter(seriesId, filter);
  },
)
```

The chart renderer still paints ordinary Heatmap series; there is no shared
scale manager or merged data model. Keyboard traversal, selection, artifacts,
generated Source, AI construction, and Workbench Data preserve series
identity. Multi-series Data mode uses a lossless long projection because one
matrix-shaped wide table cannot represent several independently measured
values without collapsing their units.

## Use categorical or numeric axes

Heatmap uses the ordinary Cartesian layout. Numeric axes accept finite cell
centres and configurable `cellWidth` and `cellHeight`. Categorical matrices
declare ordered labels on both axes:

```dart
BravenChartPlus(
  series: [series],
  xAxisConfig: const XAxisConfig(
    label: 'Day',
    categoryAxis: CategoryAxisConfig(
      categories: ['Mon', 'Tue', 'Wed'],
    ),
  ),
  yAxis: const YAxisConfig(
    label: 'Period',
    categoryAxis: CategoryAxisConfig(
      categories: ['AM', 'PM'],
    ),
  ),
)
```

Categorical coordinates are zero-based integral centres. Category order,
density, overflow, and layout measurement use the same axis contract as other
Cartesian families. The outer cell edges remain visible without adding fake
numeric padding.

### Use explicit rectangular cells

Set `HeatmapDataPoint.bounds` when a cell represents an unequal interval or
lane instead of a regular matrix slot. The representative X/Y coordinate keeps
the cell's stable Cartesian identity and must fall inside the rectangle:

```dart
HeatmapDataPoint(
  x: 1.2,
  y: 0,
  value: 74,
  bounds: HeatmapCellBounds(
    xMinimum: 0,
    xMaximum: 2.4,
    yMinimum: -0.38,
    yMaximum: 0.38,
  ),
)
```

Explicit bounds control data-domain measurement, culling, painting, hit
testing, semantics, and rectangle selection. Cells without bounds continue to
use the series `cellWidth` and `cellHeight`, so regular and irregular cells can
coexist without changing the regular-grid fast path. `gapFraction` is applied
inside the resolved rectangle; the resulting visible gap is not a hit target.

## Style cells and labels

`gapFraction` reserves space between cells. `borderColor`, `borderWidth`, and
`cornerRadius` define their outline. Set `showCellLabels` for matrices where
values remain legible; an explicit `cellLabelColor` wins, otherwise the
renderer derives black or white from the resolved fill contrast.

Labels obey the visible viewport and minimum available cell size. Dense
matrices therefore remain a colour field instead of producing thousands of
overlapping strings.

## Interaction and accessibility

Cells participate in the normal point contract. Hover or tap resolves the same
typed `HeatmapDataPoint` through tooltips, tracking, `onPointHover`,
`onPointTap`, focus, and durable selection. Keyboard arrow keys move through
rows and columns; Enter or Space activates the focused cell.

Semantics announce series, row, column, measured value, position, and selection
state. Dense matrices expose a bounded semantic surface instead of one node per
source cell, while focused and selected cells remain prioritized. Use labels,
legends, thresholds, or accompanying text when colour is material; colour
alone should not carry the meaning.

Heatmap also uses normal Cartesian zoom, pan, X/Y scrollbars, viewport
navigation, and annotations. V1 accepts exactly one Heatmap series and does not
mix it with Line, Area, Bar, Scatter, Candlestick, or Range Area.

### Rectangle selection and matrix expansion

Heatmap rectangle selection tests the rendered cell bounds, so a brush that
touches any visible part of a cell acquires that cell. The optional
`heatmapExpansion` policy can then keep the touched cells, or expand them to
complete source rows or columns:

```dart
interactionConfig: const InteractionConfig(
  enableSelection: true,
  selection: ChartSelectionConfig(
    acquisitionMode: ChartSelectionAcquisitionMode.rectangle,
    scope: ChartSelectionScope.mark,
    heatmapExpansion: HeatmapSelectionExpansion.row,
    brush: ChartSelectionBrushConfig(
      enabled: true,
      initialVisible: true,
      initialBox: ChartSelectionBrushBox(
        minimumX: 1,
        maximumX: 3,
        minimumY: 1,
        maximumY: 3,
      ),
    ),
  ),
),
```

Expansion is limited to the selected `HeatmapChartSeries`; it never selects a
similarly positioned mark in another series. Cells excluded by a hide filter
remain unavailable, while dimmed cells and explicit missing cells retain their
ordinary selectable identity. Lasso selection remains centre-based. The
renderer uses its viewport index to bound candidates before applying exact
cell-overlap tests.

Review the live policy and generated configuration in the
[Matrix selection preset](https://braven-pvm.github.io/braven_charts/?page=heatmap-charts&preset=selection).

## Motion

`HeatmapAnimationStyle` controls an opt-in cell entrance and stable-identity
value updates:

```dart
animation: const HeatmapAnimationStyle(
  entranceMode: HeatmapEntranceMode.scale,
  entranceOrder: HeatmapEntranceOrder.radial,
  entranceScale: 0.82,
  staggerFraction: 0.5,
),
```

Entrance can fade or scale in simultaneous, row, column, or radial order.
Compatible mounted updates interpolate the measured value through the active
colour scale. Coordinate changes are treated as removal and addition rather
than sliding one matrix cell into another. Reduced motion and zero-duration
themes render the final state immediately.

## Workbench, artifacts, and generated source

`BravenChartWorkbench` supports Chart, Data, Split, and Source without a
family-specific wrapper. Matrix Data mode preserves the visual row/column
shape. A Heatmap containing explicit rectangles automatically uses lossless
long mode and exposes X min/max and Y min/max alongside X, Y, value, key, and
explicit missing state.

Artifacts preserve cells, categorical axes, colour scale, empty-value styling,
ordinary cell styling, animation, selection, and previews. Generated Dart emits
typed `HeatmapDataPoint`, `HeatmapDataPoint.missing`, `HeatmapColorScale`,
`HeatmapCellBounds`, `HeatmapEmptyValueStyle`, and `HeatmapChartSeries`
constructors. Grammar uses
`HeatmapMark<T>` / `geomHeatmap`, fluent modifiers cover immutable presentation
changes, and tool input requires explicit finite X/Y plus either a finite
measured value or `missing: true`.

## Performance behavior

The renderer builds a compact two-dimensional index for the source matrix and
materializes only visible rows and columns. Regular and sparse matrices use
the existing row index; explicit rectangles opt into a separate immutable
interval-tree side index. Both paths use bounded visible queries and indexed
hit testing. Base cells, borders, and
labels remain in a retained picture; hover, press, focus, and selection paint
in a live overlay without rebuilding the matrix.

Permanent checks cover labelled and styled matrices, a filtered 10,000-cell
matrix, a 250,000-cell regular source culled to a small viewport, a bounded
10,000-cell explicit-rectangle query, cached hits, and hover overlays. Measure
on the target platform and release build before choosing application-specific
frame budgets.

### Viewport-backed matrices

When the complete regular matrix should not remain materialized,
`HeatmapTileSource` exposes an asynchronous, host-owned tile boundary and
`HeatmapViewportController` resolves only the current viewport plus bounded
overscan. The controller coalesces viewport motion, deduplicates in-flight
tile requests, rejects stale generations, retains the last usable snapshot on
current errors, and uses a deterministic tile-count LRU budget. A separate
per-viewport tile limit rejects an accidental full-domain request before any
source loads start.

The chart still receives an ordinary immutable `HeatmapChartSeries`. Explicit
full-domain X/Y axis bounds keep pan and zoom stable while resident points
change. No future, transport, or cache mutation enters `ChartRenderBox`; the
existing Heatmap index remains the only renderer-side culling path.

Workbench Data, Split, Source, CSV, capture, and previews describe the current
resident snapshot. Artifacts may additionally opt into a portable
`HeatmapViewportProviderDescriptor`: it records only a stable provider ID,
target series ID, JSON-safe arguments, and the initial viewport. The provider,
credentials, transport, cache, subscriptions, mutations, and conceptual
non-resident cells are never serialized.

Register the matching host factory explicitly when hydrating the artifact:

```dart
final bindings = ChartRuntimeBindings(
  heatmapViewportProviders: HeatmapViewportProviderRegistry(
    factories: {
      'app.telemetry.matrix.v1': (descriptor, residentTemplate) {
        return HeatmapViewportProviderRuntime(
          controller: HeatmapViewportController(
            source: telemetrySourceFor(descriptor.arguments),
          ),
        );
      },
    },
  ),
);
```

An unregistered provider fails closed with `runtime_binding_required`.
Hydration creates a fresh runtime for each mounted chart, loads the descriptor's
initial viewport, forwards later viewport changes, and disposes an owned
controller. Home or R restores that bounded initial viewport rather than
requesting the complete conceptual axis domain. Provider load failures retain
the last resident snapshot. See the `Massive matrix` preset on the Heatmap
showcase for a 24-million-cell procedural domain with resident-cell, cache, and
portable-provider diagnostics.

Image-backed tiles are a separate presentation path rather than an alternate
encoding of `HeatmapDataPoint`. The host owns acquisition and decode, while
`HeatmapRasterViewportController` owns byte-budgeted caching, generation
ordering, atomic mounted snapshots, fallback retention, and exact-once
disposal. `BravenChartPlus.heatmapRasterViewportController` borrows the
controller's immutable mounted snapshot and paints each ready
`HeatmapRasterImageResource` at its finite source-space bounds under the
ordinary Cartesian transform and plot clip. The renderer never loads, caches,
or disposes a resource. `heatmapRasterOpacity` and
`heatmapRasterFilterQuality` control only the borrowed paint presentation.
Exact cell interaction, accessibility, Workbench Data/Source, and export
remain available only from bounded canonical cells supplied alongside the
pixels. `HeatmapRasterSemanticDescriptor` turns those host aggregates into one
ordinary immutable resident `HeatmapChartSeries`; the same series is the
truthful generated-Dart and `cell` fallback surface.

Portable raster artifacts opt in with one
`HeatmapRasterViewportProviderDescriptor`. It contains provider/layer identity,
a bounded initial viewport, JSON-safe source arguments, raster presentation,
and an explicit `cell` or `hardFailure` fallback. The host registers a fresh
runtime factory through
`ChartRuntimeBindings.heatmapRasterViewportProviders`. Raster bytes, decoded
handles, caches, transports, credentials, callbacks, and mutation history do
not enter the document. See the `Raster tiles` preset for a 512-million-cell
deep-signal spectrogram whose initial viewport mounts 12 decoded tiles and
1,536 bounded semantic aggregates; pan, zoom, reset, Workbench, and portable
provider metadata all use the standard Cartesian contracts.
The complete decision boundary and implementation gates are recorded in
[`2026-08-02-heatmap-image-backed-tile-boundary-design.md`](../docs/superpowers/specs/2026-08-02-heatmap-image-backed-tile-boundary-design.md).

## Advanced analysis and hierarchy composition

Phase 2 preparation utilities can derive typed 2D histograms, density rasters,
contours, deterministic clustered order, portable dendrogram geometry, and a
shared colour domain for independently rendered small multiples without
expanding the retained Heatmap cell renderer. The clustered showcase uses
`HeatmapDendrogramData` and the standalone `HeatmapDendrogram` host widget
around the matrix.

`HeatmapDendrogramStyle` independently controls branch, leaf-baseline, and
leaf-tick colours and widths, branch caps and joins, guide visibility and tick
length, and optional presentation-only rounded elbows. It also provides
independent leaf/merge markers plus bounded leaf and original merge-distance
labels. Leaf and merge markers each support circle, square, diamond, and
triangle shapes; solid or hollow fill; and independent fill, border colour,
border width, and radius. Leaf markers terminate symmetrically at the
matrix-facing baseline (upper half for column trees, left half for row trees)
rather than relying on surrounding host layout to hide overflow. Label
density, truncation, placement, colours,
typography, and numeric precision remain deterministic and JSON-safe, so
artifacts and generated Source retain the effective host presentation.
Automatic level of detail is also part of the style contract. Configurable
screen-space thresholds suppress sub-pixel branch groups, crowded leaf guides,
leaf and merge markers, and labels as the hierarchy becomes denser. Set
`levelOfDetailMode` to `disabled` to retain every explicitly enabled element.
The standalone painter caches its branch path while the same painter and size
remain mounted; this optimization does not add hierarchy work to the core
Heatmap renderer.
`HeatmapDendrogramData` keeps one portable node anchor per accepted hierarchy
node; structural spacing can therefore remain readable while merge labels
still report the clustering algorithm's original distance. Hierarchy geometry
and accepted leaf order remain unchanged.

Markers and labels are presentation-only. Branch/node hover, selection,
and collapse remain separate contracts.

The composed hierarchy view is deliberately fixed while either dendrogram is
visible. Matrix labels and both trees use one pre-layout focus and shared
insets; hide both trees to restore ordinary Cartesian zoom, pan, and the X
scrollbar.

## Capability and verification map

Advanced transforms remain explicit data-preparation steps, and composed
views remain host owned. They all terminate in the same typed Heatmap series,
so cell focus, keyboard traversal, selection, tooltips, Workbench Data/Source,
artifacts, and generated Dart keep the canonical Heatmap behavior unless the
table below calls out a narrower contract.

| Capability | Runtime and accessibility contract | Scale evidence | Showcase preset |
| --- | --- | --- | --- |
| 2D histogram | `HeatmapHistogramData` bins raw observations into ordinary inspectable cells; empty bins are finite zero-valued cells | 50,000 observations into 8,192 bins | `2D histogram` |
| Density raster | `HeatmapDensityData` produces provenance-aware canonical cells; the renderer exposes the resident cells through normal Heatmap semantics | 2,000 weighted observations into a 768-cell raster | `Density raster` |
| Density contours | Marching Squares produces portable line overlays while the underlying raster remains the accessible matrix | Five contour levels over the 768-cell density raster | `Density contours` |
| Clustered matrix | `HeatmapClusterData` reorders typed cells; `HeatmapDendrogram` adds one labelled semantic hierarchy region without entering `ChartRenderBox` | 6,144 clustered cells, 512-leaf layout, and 120 retained hierarchy paints | `Clustered matrix` |
| Shared-domain small multiples | Independent charts share one immutable `HeatmapSharedColorDomain`; each panel retains its own focus and cell identity | Retained renderer checks cover filtering and large visible queries | `Small multiples` |
| Multiple colour axes | Independently scaled Heatmap series share the chart interaction model without conflating their measured-value domains | Retained renderer and multi-series keyboard traversal checks | `Colour axes` |
| Rectangle selection | Native selection-brush semantics select touched cells or expand to complete source rows and columns | Focused brush, renderer, zoom, pan, and scrollbar composition checks | `Matrix selection` |
| Irregular cells | Explicit rectangles retain exact cell identity and participate in the same semantics and hit-testing contract | Bounded indexed query over 10,000 explicit rectangles | `Irregular cells` |
| Calendar empty values | Finite zero cells remain selectable and independently styled; missing cells remain absent | Retained renderer checks preserve zero/missing identity | `Contribution calendar` |
| Viewport-backed matrix | Only the current immutable resident snapshot enters rendering, semantics, Workbench, and artifacts; non-resident conceptual cells are intentionally absent | 100 moving windows over a conceptual 24-million-cell source, bounded to 12,288 resident cells | `Massive matrix` |
| Image-backed raster tiles | Decoded images are controller-owned and borrowed for clipped Cartesian paint; exact data, semantics, and artifacts require a separate canonical companion | Six independently decoded tiles spanning one 96 x 48 source domain | `Raster tiles` |

The focused benchmark sources live under `test/benchmarks`, while widget-level
assistive behavior is covered by
`test/widgets/heatmap_accessibility_interaction_test.dart` and
`test/widgets/heatmap_dendrogram_test.dart`. These checks are regression
evidence, not universal frame-budget promises; profile the intended data shape
on the target device and release renderer.

## Current boundaries

The core Heatmap renderer does not aggregate raw samples, estimate density,
cluster rows or columns, or own dendrogram layout. Those remain explicit
preparation and host-composition steps. It supports axis-aligned rectangular
cells, host-owned regular-matrix tile loading and mutation, and multiple
independently scaled Heatmap series. Image-backed tiles can provide a bounded
Cartesian presentation layer, but they do not infer semantic cells from pixels
and are not yet portable-provider hydrated. Heatmap does not support arbitrary
cell polygons or implement
treemap, mosaic, vector-field, and geographic chart families.

The regression envelope currently covers deterministic clustering of a
6,144-cell matrix, layout of a 512-leaf portable hierarchy, 120 repeated
paints of that hierarchy, and a viewport-backed 24-million-cell conceptual
matrix whose mounted series remains bounded. This is not a claim that an
arbitrary massive matrix can be retained or clustered synchronously.

## Related documentation

- [Heatmap release performance audit](../docs/superpowers/plans/2026-08-03-heatmap-release-performance-audit.md)
- [Chart types](../docs/guides/chart-types.md)
- [Feature coverage matrix](feature_matrix.md)
- [Portable chart artifacts](chart_artifacts.md)
- [Chart Workbench](chart_workbench.md)
- [Chart family integration contract](chart_family_integration.md)
