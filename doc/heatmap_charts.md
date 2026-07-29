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
shape; long mode exposes X, Y, value, key, and explicit missing state.

Artifacts preserve cells, categorical axes, colour scale, styling, animation,
selection, and previews. Generated Dart emits typed `HeatmapDataPoint`,
`HeatmapDataPoint.missing`, `HeatmapColorScale`, and `HeatmapChartSeries`
constructors. Grammar uses `HeatmapMark<T>` / `geomHeatmap`, fluent modifiers
cover immutable presentation changes, and tool input requires explicit finite
X/Y plus either a finite measured value or `missing: true`.

## Performance behavior

The renderer builds a compact two-dimensional index for the source matrix and
materializes only visible rows and columns. Regular and sparse matrices use
bounded visible queries and indexed hit testing. Base cells, borders, and
labels remain in a retained picture; hover, press, focus, and selection paint
in a live overlay without rebuilding the matrix.

Permanent benchmarks cover labelled and styled matrices, a 250,000-cell source
culled to a small viewport, cached hits, and hover overlays. Measure on the
target platform and release build before choosing application-specific frame
budgets.

## Phase 1 boundaries

Heatmap does not aggregate raw samples into 2D histograms, estimate density,
cluster or reorder rows, render dendrograms, stream image tiles, support
irregular cell polygons, provide multiple colour axes, or implement treemap,
mosaic, vector-field, and geographic chart families. Prepare those transforms
outside the chart or track the explicitly separate Phase 2 work.

## Related documentation

- [Chart types](../docs/guides/chart-types.md)
- [Feature coverage matrix](feature_matrix.md)
- [Portable chart artifacts](chart_artifacts.md)
- [Chart Workbench](chart_workbench.md)
- [Chart family integration contract](chart_family_integration.md)
