# Pie charts

Pie charts represent category contributions to one meaningful whole. Braven
Charts implements pie as a first-class radial series inside
`BravenChartPlus`, so it uses the same themes, callbacks, controller identity,
data tables, artifacts, previews, and hydration boundary as Cartesian charts.

Import the public package surface:

```dart
import 'package:braven_charts/braven_charts.dart';
```

## Quick start

Use `PieChartSeries.fromMap` when each category has one numeric contribution.
Map insertion order becomes stable slice order.

```dart
final series = PieChartSeries.fromMap(
  id: 'revenue-share',
  name: 'Revenue share',
  unit: 'USD',
  values: const {
    'Subscriptions': 42,
    'Services': 31,
    'Hardware': 27,
  },
);

BravenChartPlus(
  title: 'Revenue contribution',
  subtitle: 'Recurring revenue by product',
  series: [series],
  showLegend: true,
  interactionConfig: const InteractionConfig(
    tooltip: TooltipConfig(enabled: true),
  ),
)
```

The automatic slice legend shows category, formatted value, and share. Hover
or tap a slice for its tooltip. Tap a slice, legend item, or linked data-table
row to select and optionally explode it. Durable selection owns the tooltip:
it appears for all three selection paths, follows the slice when geometry or
layout changes, and hides when the selection is cleared.

## Data contract

The explicit constructor uses `ChartDataPoint` so metadata and point styles
remain available:

```dart
PieChartSeries(
  id: 'revenue-share',
  name: 'Revenue share',
  unit: 'USD',
  points: const [
    ChartDataPoint(
      x: 0,
      y: 42,
      label: 'Subscriptions',
      metadata: {'productId': 'subscriptions'},
    ),
    ChartDataPoint(x: 1, y: 31, label: 'Services'),
    ChartDataPoint(x: 2, y: 27, label: 'Hardware'),
  ],
)
```

For pie points:

- `x` is a finite, stable ordering ordinal;
- `y` is a finite, non-negative contribution;
- `label` is the required, non-empty category;
- point index is the stable identity used by `ChartPointRef`;
- `PointStyle.color` overrides the resolved palette color for that slice;
- `PointStyle.size` carries an optional raw second metric when variable slice
  radii are enabled;
- metadata is transported but not interpreted by the renderer.

Zero values remain in artifacts and data tables but do not paint a slice. An
all-zero series renders the chart's configured empty state. Negative, `NaN`,
infinite, or empty-label values fail with `ArgumentError` in release and debug
modes. Duplicate labels are allowed because labels are display text, not
identity.

## Variable slice radii

Use a variable-radius Pie when angle should compare one contribution and the
outer radius should compare a second independent, non-negative metric. Supply
one radius value for every category; partial maps fail validation instead of
quietly mixing two encodings.

```dart
final countries = PieChartSeries.fromMap(
  id: 'country-density-area',
  unit: 'people/km²',
  values: const {
    'Germany': 233,
    'Spain': 96,
    'France': 119,
  },
  radiusValues: const {
    'Germany': 357022,
    'Spain': 505990,
    'France': 551695,
  },
  sliceRadiusConfig: const PieSliceRadiusConfig(
    minimumFactor: 0.35,
    scale: PieSliceRadiusScale.area,
    label: 'Total area',
    unit: 'km²',
  ),
);
```

`y` still determines angular share. `radiusValues` determine only the outer
radius and preserve insertion-order identity. Values must be finite and
non-negative and must have exactly the same category keys as `values`.

The renderer normalizes the visible radius domain between `minimumFactor` and
the series' maximum `PieChartStyle.radiusFactor`. `PieSliceRadiusScale.area`
is the default because equal normalized changes then produce equal visible
area changes; use `linear` only when literal radius interpolation is the
intended visual encoding. When all radius values are equal, every slice uses
the full radius. Omitting both radius arguments preserves ordinary uniform Pie
geometry.

## Composition boundary

The first radial release accepts exactly one `PieChartSeries` and does not mix
pie with line, area, bar, or scatter series. Pie has no Cartesian axes,
crosshair, pan, zoom, scrollbars, normalization, or Cartesian annotations.

The package validates this boundary before rendering. Unsupported composition
fails explicitly rather than omitting a series or inventing an axis mapping.

## Slice geometry

`PieChartStyle` controls geometry shared by all slices:

```dart
const PieChartStyle(
  startAngleDegrees: -90,
  clockwise: true,
  radiusFactor: 0.86,
  sliceGap: 2,
  borderWidth: 1,
  borderColorMode: PieBorderColorMode.slice,
  borderLightnessShift: -0.16,
  gradient: PieGradientStyle(
    type: PieGradientType.linear,
    angleDegrees: -45,
  ),
  cornerRadius: 10,
  cornerTreatment: PieCornerTreatment.circularCenter,
  selectionExplodeOffset: 10,
)
```

- `startAngleDegrees` rotates the first slice;
- `clockwise` changes order direction;
- `radiusFactor` is a value greater than 0 and at most 1;
- `sliceGap`, `borderWidth`, and `selectionExplodeOffset` are non-negative
  logical pixels;
- a non-null `borderColor` is a fixed color shared by every slice and always
  takes precedence;
- `borderColorMode` chooses the chart-theme outline or a border derived from
  each slice;
- `borderHueShiftDegrees`, `borderSaturationShift`, and
  `borderLightnessShift` transform slice-derived borders in HSL space. Negative
  lightness creates a darker shade; a hue shift creates a related contrasting
  border. Saturation and lightness shifts use the inclusive range -1 to 1.
- `gradient` optionally applies one linear or radial light source across the
  complete Pie. Null keeps the established solid palette fill.

`sliceGap` preserves each category's angular sweep. It translates complete
wedges apart and compensates each wedge radius independently, so small and
large slices terminate on the same outer ring. Increasing the gap therefore
behaves like padding rather than sharpening the center or shrinking the
largest category inward.

`cornerTreatment` makes the meaning of `cornerRadius` explicit:

- `PieCornerTreatment.roundAll` is the compatibility default. It rounds the
  two outer corners and independently rounds each slice tip at the center;
- `PieCornerTreatment.outerOnly` rounds the outer circumference while keeping
  each slice apex sharp;
- `PieCornerTreatment.circularCenter` applies the same outer rounding and
  subtracts one uniform circular opening. The opening is derived from the
  effective corner radius and physical slice spacing, then capped against the
  smallest visible slice so variable-radius data is not erased.

The circular-center mode is still a Pie styling treatment: it does not expose
an independently sized inner radius or Donut center content. Use
`DonutChartSeries` when the hole itself carries product meaning; see the
[Donut chart guide](donut_charts.md).

## Selection presentation

Selection identity and selection presentation are independent. Controllers,
legends, tables, keyboard focus, artifacts, and callbacks keep using the same
durable point reference while the shared `RadialSelectionStyle` chooses the
spatial cue for Pie, Donut, and Concentric Donut series:

```dart
PieChartSeries.fromMap(
  id: 'revenue',
  values: const {'Subscriptions': 42, 'Services': 31, 'Hardware': 27},
  selectionStyle: const RadialSelectionStyle(
    effect: RadialSelectionEffect.lift,
    liftScale: 1.12,
    liftOffset: 8,
    backdropBlur: 1.5,
  ),
  pieStyle: const PieChartStyle(selectionExplodeOffset: 10),
)
```

- `RadialSelectionEffect.explode` is the compatibility default and uses
  `PieChartStyle.selectionExplodeOffset`;
- `RadialSelectionEffect.lift` keeps the selected category at the same angle,
  scales it around its sector centroid, pulls it radially away from the chart,
  paints it above sibling slices, and optionally blurs the unselected slices
  to create depth of field;
- `liftScale` accepts values from 1 through 1.5; 1 disables enlargement;
- `liftOffset` accepts 0 through 40 logical pixels; 0 keeps the raised slice
  centered while larger values add a separate outward movement;
- `backdropBlur` accepts a blur sigma from 0 through 20; 0 keeps the background
  crisp;
- `PieChartTheme.selectedElevation` or `PieChartStyle.selectedElevation`
  controls the accompanying shadow/glow, including color, blur, spread,
  offset, and opacity.

The lift animation follows the chart interaction duration and curve. Its
scaled and translated path is also used for hit testing, tooltip placement,
inside labels, and outside-label connectors, and the renderer reserves its
maximum configured overflow so the foreground slice is not clipped.

## Group small categories without losing source data

`RadialSliceGroupingConfig` can project several small positive categories into
one visible aggregate. The original `ChartDataPoint` list is unchanged, so
tables, copy/CSV export, artifacts, hydration, controller references, and
selection callbacks remain source-accurate.

```dart
PieChartSeries.fromMap(
  id: 'channels',
  values: const {
    'Portal': 80,
    'Email': 8,
    'Chat': 7,
    'Events': 5,
  },
  sliceGroupingConfig: const RadialSliceGroupingConfig(
    minimumShare: 0.1,
    minimumSourceCount: 2,
    label: 'Other',
  ),
);
```

The threshold is exclusive. The aggregate appears only when at least
`minimumSourceCount` positive points qualify. Selecting the aggregate expands
to every represented `ChartPointRef`; selecting any represented table row
selects the same visible aggregate.

Grouping can be combined with variable slice radii only when the host declares
the second-metric aggregation policy:

```dart
sliceGroupingConfig: const RadialSliceGroupingConfig(
  minimumShare: 0.1,
  minimumSourceCount: 2,
  label: 'Other',
  radiusAggregation: RadialSliceRadiusAggregation.weightedMean,
),
```

Choose `sum`, arithmetic `mean`, contribution-weighted `weightedMean`,
`minimum`, or `maximum` according to the meaning of the radius measure. The
policy affects only the synthetic visible slice. Every source radius remains
unchanged in tables, copy/CSV, callbacks, artifacts, and hydration. Combining
grouping and variable radius without a policy, or supplying a policy without a
radius metric, fails validation rather than inventing semantics.

The geometry preserves an internal inner-radius seam, but nested radial charts
are not part of Pie. Variable-radius Pie is
supported through the explicit second-metric contract above; it is not an
unlabeled per-slice styling trick.

## Theme and advanced slice styling

`ChartTheme.pieChartTheme` defines reusable product-wide Pie defaults. A
`PieChartStyle` may override gradient, opacity, corner radius and treatment,
elevation, or animation for one series. Null series values continue to inherit
the chart theme.

```dart
final theme = ChartTheme.light.copyWith(
  seriesTheme: ChartTheme.light.seriesTheme.copyWith(
    colors: const [
      Color(0xFF006D77),
      Color(0xFF0A9396),
      Color(0xFF48CAE4),
      Color(0xFF023E8A),
    ],
  ),
  pieChartTheme: const PieChartTheme(
    gradient: PieGradientStyle(
      type: PieGradientType.radial,
      startLightnessShift: 0.18,
      endLightnessShift: -0.12,
    ),
    opacity: 0.88,
    cornerRadius: 12,
    cornerTreatment: PieCornerTreatment.circularCenter,
    shadow: PieElevationStyle(
      color: Color(0x401A1A1A),
      blurRadius: 8,
      offset: Offset(0, 4),
      opacity: 0.7,
    ),
    selectedElevation: PieElevationStyle(
      // Null color derives a glow independently from each selected slice.
      blurRadius: 12,
      spreadRadius: 2,
      opacity: 0.5,
    ),
    borderColorMode: PieBorderColorMode.slice,
    borderLightnessShift: -0.16,
    animationMode: PieAnimationMode.grow,
  ),
);
```

`PieGradientStyle` derives its two stops from every slice color by default, so
category identity and legend markers remain stable. The first and final stops
can instead use fixed `startColor` and `endColor` values. A linear gradient
uses `angleDegrees` (`0` points right and `90` points down); a radial gradient
blends from the shared center to the outer edge. Both lightness shifts use the
inclusive range -1 to 1. Set `PieGradientStyle(enabled: false)` on a series to
explicitly opt out of a theme gradient. Gradient style is included in artifact
JSON and restored with the Pie series.

`PieElevationStyle.color == null` derives the elevation color from its slice.
Use a dark color plus a downward offset for a shadow, or a slice-derived color
with zero offset for a glow. Blur radius, spread radius, offset, opacity, and
an optional fixed color are all configurable independently for base shadow and
selected elevation. `PieAnimationMode` supports `none`, radial `grow`, angular
`sweep`, and geometry-preserving `fade`. `MediaQuery.disableAnimationsOf` and
a zero theme duration always win over every entrance mode. A mounted chart can
replay its configured radial entrance through
`BravenChartController.replayRadialEntrance()`.

Entrance duration comes from `ChartTheme.animationTheme`. Bounded monotonic
theme curves are honored. Overshooting or reversing curves such as
`Curves.elasticOut` use a monotonic `easeOutCubic` reveal fallback so painted
geometry never advances, retreats, and flashes forward again. This safeguard
applies to Pie, Donut, and Concentric Donut entrance replays without changing
the configured curve used by other chart animations.

Entrance motion is independent from mounted data changes. Configure
`PieChartStyle.dataTransitionMode` with `RadialDataTransitionMode.automatic`
to interpolate values and optional radius metrics while stable categories keep
the same identity and order. Category insertion, removal, reordering, or
grouping uses a two-phase structural fade so one category never morphs into
another. Use `RadialDataTransitionMode.none` for immediate updates. Data
changes never replay the configured entrance.

Radial identity prefers a unique trimmed category label. Duplicate labels are
disambiguated by X value and then occurrence. Selection and keyboard focus are
remapped through a reorder. Reduced motion and a zero duration always apply the
final state immediately.

The renderer reserves the maximum configured explode distance, border and
focus stroke, base shadow, and selected elevation before calculating the Pie
radius. Selection therefore does not reflow the chart, and an edge-facing
slice remains inside the plot even with a large offset or glow.

## Data labels

`PieDataLabelConfig` controls eligibility, content, and placement:

```dart
const PieDataLabelConfig(
  isVisible: true,
  position: PieDataLabelPosition.outside,
  content: PieDataLabelContent.categoryAndPercentage,
  minimumShare: 0.03,
  minimumSweepDegrees: 8,
  insideOffset: 0,
  outsideOffset: 0,
  connectorLength: 14,
  connectorWidth: 1,
  collisionStrategy: PieDataLabelCollisionStrategy.shiftAndHide,
)
```

Content may be category, value, percentage, or a combined variant. Inside
labels use a balanced position within each slice's radial band and are omitted
when the text does not fit. Set the signed `insideOffset` to move them radially:
positive values move toward the outer edge and negative values move toward the
center. `0` keeps the balanced default, and the renderer clamps the resolved
anchor to the slice's inner and outer radii.
Outside labels are split into compact left and right lanes beside the painted
pie, shifted deterministically, and—under `shiftAndHide`—the lowest-priority
labels are hidden when the lane cannot fit. Set `outsideOffset` to move both
lanes outwards; `0` is tight to the pie. The renderer clamps the lanes inside
the plot. The complete legend and table remain available when a label is hidden.

### Split category and share labels

Set `secondaryContent` to paint one independent label at the opposite
placement. This is useful when the category belongs outside the pie while a
compact share badge belongs inside its slice:

```dart
dataLabels: const PieDataLabelConfig(
  position: PieDataLabelPosition.outside,
  content: PieDataLabelContent.category,
  secondaryContent: PieDataLabelContent.percentage,
  secondaryPosition: PieDataLabelPosition.inside,
  secondaryCalloutStyle: LabelStyle(
    textStyle: TextStyle(
      color: Colors.white,
      fontSize: 11,
      fontWeight: FontWeight.w700,
    ),
    backgroundColor: Color(0xD91F2937),
    borderColor: Color(0x99FFFFFF),
    borderWidth: 1,
    borderRadius: 4,
    padding: EdgeInsets.symmetric(horizontal: 5, vertical: 2),
  ),
),
```

The primary and secondary layers share the same eligibility thresholds and
numeric formatters. They can use separate `LabelStyle` values. Their positions
must differ: each slice can own at most one inside and one outside label.
Outside labels continue through the normal collision-managed connector lane;
inside labels are painted only when their measured badge fits the slice.

`minimumShare` uses the inclusive range 0–1. `minimumSweepDegrees` uses 0–360.
Outside offset, connector length, width, and label padding must be finite and
non-negative.

## Numeric formatting

Use one set of radial formatters to keep labels, legends, tooltips, and
accessibility consistent:

```dart
PieChartSeries.fromMap(
  id: 'revenue-share',
  values: const {'Subscriptions': 42, 'Services': 31},
  dataLabels: PieDataLabelConfig(
    valueFormatter: (value) => '\$${value.toStringAsFixed(1)}',
    percentageFormatter: (share) =>
        '${(share * 100).toStringAsFixed(0)}%',
  ),
  sliceRadiusConfig: PieSliceRadiusConfig(
    formatter: (value) => '${value.toStringAsFixed(0)} k users',
  ),
)
```

`RadialValueFormatter` owns the complete returned text, including units and
prefixes. `percentageFormatter` receives a fractional share from `0` to `1`.
The resolved value/share text is reused across data labels, legends, tooltips,
and semantic descriptions; the radius formatter owns the optional second
metric display.

### Callout styling

Set `PieDataLabelConfig.calloutStyle` for one series, or
`PieChartTheme.calloutStyle` for every Pie chart in a theme. Both use the
shared `LabelStyle` model, including text, surface, border, radius, padding,
and shadow. `secondaryCalloutStyle` independently styles the optional second
layer. A null callout style resolves from the active Pie theme.

Tooltips remain part of the shared interaction system. Configure one chart
with a non-default `TooltipConfig.style`, or theme every chart through
`ChartTheme.interactionTheme.tooltipStyle`. The per-chart style wins when both
are set. Otherwise the interaction theme controls tooltip text, surface,
border, radius, padding, and shadow.

## Per-slice colors

Supply category colors with the convenience constructor:

```dart
PieChartSeries.fromMap(
  id: 'status',
  values: const {'Healthy': 72, 'Warning': 18, 'Critical': 10},
  sliceColors: const {
    'Healthy': Color(0xFF16A34A),
    'Warning': Color(0xFFF59E0B),
    'Critical': Color(0xFFDC2626),
  },
)
```

Unspecified slices use the series color when present, then the active
`ChartTheme` palette. Keep category text visible in labels or the legend so
color is not the only meaning.

## Legend position and appearance

Pie legends honor the shared `LegendStyle` fields, including all nine
`LegendPosition` anchors, horizontal or vertical orientation, marker shape,
marker size, spacing, background, border, opacity, and offset.

```dart
final theme = ChartTheme.light.copyWith(
  legendStyle: ChartTheme.light.legendStyle.copyWith(
    position: LegendPosition.centerRight,
    orientation: LegendOrientation.vertical,
    markerShape: LegendMarkerShape.circle,
  ),
);
```

Top and bottom anchors reserve only the legend's compact measured height and
stay aligned to the requested edge. Center-left and center-right anchors use a
compact, bounded side rail and give the remaining width to the plot. Oversized
legends scroll inside their safety bound instead of claiming a fixed fraction
of the chart. `LegendPosition.center` overlays the legend and should be
reserved for charts with deliberate empty center space.

### Custom Pie and Donut legend items

Radial legends are Flutter widgets rather than canvas-painted labels. Supply a
`radialLegendItemBuilder` when the host needs complete control over the visible
contents of each item:

```dart
BravenChartPlus(
  series: [series],
  showLegend: true,
  radialLegendItemBuilder: (context, item) {
    return AnimatedContainer(
      duration: item.animationDuration,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: item.selected
            ? item.selectionColor.withValues(alpha: 0.10)
            : Colors.transparent,
        border: Border.all(
          color: item.selected ? item.selectionColor : Colors.transparent,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 4, height: 32, color: item.color),
          const SizedBox(width: 8),
          Text('${item.category}: ${item.valueLabel} (${item.shareLabel})'),
        ],
      ),
    );
  },
)
```

The builder receives the resolved slice color, effective aggregate point,
formatted value/share helpers, visible index, selected state, and stable source
points. A grouped `Other` item therefore exposes every original point through
`sourcePointIndices` and `sourcePoints` while its `point` remains the aggregate
slice shown by the chart.

The returned widget replaces the default marker and text. Braven Charts keeps
the outer tap target, selection action, and selected/button semantics, and the
existing `LegendStyle` still controls placement, orientation, scrolling,
spacing, and the legend surface. Custom content must remain legible at large
text sizes and inside the configured horizontal band or vertical rail.

`radialLegendItemBuilder` is deliberately runtime-only: Dart widget callbacks
cannot be serialized. Artifacts retain the portable radial data, legend
visibility, and `LegendStyle`; a hydrating host binds the builder again, just
like any other runtime callback.

## Interaction and callbacks

Pie uses the existing point callbacks with the original source point and pie
series ID:

```dart
BravenChartPlus(
  bravenChartController: controller,
  series: [series],
  onPointTap: (point, seriesId) {
    openCategory(point.label!, point.metadata);
  },
  interactionConfig: InteractionConfig(
    tooltip: const TooltipConfig(enabled: true),
    onSelectionChanged: (selectedPoints) {
      // Called for direct and controller-driven selection changes.
    },
  ),
)
```

Keyboard behavior:

- arrow keys move between visible slices;
- Enter or Space selects the focused slice;
- Escape clears selection.

Pointer and legend selection use the slice offset plus its slice-derived
elevation/glow; they do not add a global accent outline that can compete with
the category color. The themed focus ring remains reserved for keyboard and
assistive focus, so focus and durable selection stay visually distinct.

Selection is renderer-neutral. Direct slice activation, a legend item, and a
revision-safe table/controller command all update the same `ChartPointRef`.
The selected tooltip anchor is recalculated from current slice geometry on
every paint, so radius, start-angle, direction, gap, responsive size, and
restored document changes cannot leave it behind.

For a host-owned table or list, capture a `ChartDocumentSnapshot`, retain its
opaque revision, and select with the same stable point reference:

```dart
controller.selectPoint(
  const ChartPointRef(seriesId: 'revenue-share', pointIndex: 1),
  revision: snapshot.revision,
);
```

Stale revisions and invalid references return a structured
`ChartArtifactFailure` without changing selection.

## Resizable Chart, Data, and Split views

Use `BravenChartWorkbench` when a Pie surface needs Chart, Data, and Split
views. It keeps one chart mounted, derives the native table from the same
effective document, and owns revision-safe row focus and selection linking.

```dart
final chartController = BravenChartController();
final workbenchController = ChartWorkbenchController();

BravenChartWorkbench(
  chartController: chartController,
  workbenchController: workbenchController,
  initialDisplayMode: ChartDisplayMode.split,
  tableRefreshPolicy: ChartTableRefreshPolicy.onDocumentRevision,
  autoFitTablePane: true,
  isSplitResizable: true,
  minimumChartPaneExtent: 360,
  minimumTablePaneExtent: 420,
  maximumAutoTablePaneExtent: 620,
  chartBuilder: (context, controller) => BravenChartPlus(
    bravenChartController: controller,
    series: [revenuePieSeries],
  ),
)
```

For a horizontal Split, `autoFitTablePane` gives the table the smallest width
that reasonably fits its current columns, subject to the configured pane
limits. The user can then drag the divider, focus it and use the arrow keys,
or press Escape/double-click to return to auto-fit. Set `splitAxis` to
`Axis.vertical` at compact breakpoints; automatic table-width fitting only
applies to horizontal splits. Caller-supplied chart and workbench controllers
remain caller-owned and must be disposed by the host.

When an application renders its own mode control, set `showModeSwitcher` to
`false` and call `workbenchController.setDisplayMode(mode)`. The chart remains
mounted in Data mode, so its controller stays attached for artifact capture,
selection, and host actions.

## Native data table

`ChartTableModel.fromDocument` recognizes a pie document and creates a native
category projection:

```text
# | Category      | Value (USD) | Share
1 | Subscriptions | 42.00       | 42.00%
2 | Services      | 31.00       | 31.00%
3 | Hardware      | 27.00       | 27.00%
```

```dart
final model = ChartTableModel.fromDocument(
  snapshot.document,
  viewState: snapshot.viewState,
);

ChartDataTable(
  model: model,
  selectedPointRefs: controller.selectedPointRefs,
  onRowActivated: (points) {
    controller.selectPoints(points, revision: snapshot.revision);
  },
)
```

The table preserves raw values for sorting and CSV, formats displayed values
to 2 decimals by default, and provides row copy, bounded dataset copy, and CSV
export. `BravenChartWorkbench` supplies revision-safe chart/table linking by
default when the same behavior is needed in a reusable surface.

Variable-radius documents add the configured second metric without changing
the category projection:

```text
# | Category | Value (people/km²) | Total area (km²) | Share
1 | Germany  | 233.00             | 357022.00        | 52.01%
```

The radius column participates in sorting, row and dataset copy, raw CSV
export, and accessible row descriptions.

## Capture, JSON, preview, and restore

Pie artifacts use the built-in `series.pie` capability and schema version 1.
No executable code is serialized. Older readers that do not support the
capability reject the document instead of treating it as another series type.

```dart
final captured = await controller.extractArtifact(
  ChartArtifactExtractOptions(
    artifactId: 'revenue-share-2026-07',
    includePreview: true,
    documentOptions: ChartDocumentExtractOptions(
      documentId: 'revenue-share',
      radialFormatterDescriptors: {
        'revenue-share': RadialFormatterDocumentDescriptors(
          value: ChartFormatterDescriptor(
            id: 'braven.number.fixed',
            arguments: {
              'decimals': JsonNumberValue(1),
              'prefix': JsonStringValue(r'$'),
            },
          ).toDocument(),
          percentage: ChartFormatterDescriptor(
            id: 'braven.number.percent',
            arguments: {'decimals': JsonNumberValue(0)},
          ).toDocument(),
        ),
      },
    ),
  ),
);

if (captured case ChartArtifactSuccess<ChartArtifact>()) {
  final encoded = ChartArtifactJsonCodec.encode(captured.value);
  if (encoded case ChartArtifactSuccess<String>()) {
    await repository.save(encoded.value);
  }
}
```

Hydrate saved JSON through the validation boundary:

```dart
final restored = ChartDocumentHydrator.hydrateJson(savedJson);

final widget = switch (restored) {
  ChartArtifactSuccess<HydratedChartConfiguration>() =>
    restored.value.build(),
  ChartArtifactFailure<HydratedChartConfiguration>() =>
    Text('Unable to restore chart: ${restored.error.message}'),
};
```

Slice order, values, labels, point styles, geometry, data labels, durable
selection, theme, and optional revision-bound PNG preview round-trip through
the artifact. New encoders declare both `series.pie` and
`series.pie.style.v2` and `series.pie.corner-treatment.v1`, so older readers
fail closed rather than silently
dropping advanced appearance values.

A Pie using the second radius metric additionally requires
`series.pie.variable-radius.v1`. Uniform Pie artifacts do not require that
capability, while readers that do not understand the radius mapping reject a
variable-radius document instead of flattening it into a misleading Pie.

Source-preserving grouping declares `series.radial.grouping.v1`; grouped
variable radius adds `series.radial.grouped-variable-radius.v1`; portable
formatter descriptors add `series.radial.formatters.v1`; and automatic data
updates add `series.radial.data-transitions.v1`. A configured secondary label
layer declares `series.radial.dual-labels.v1`, so older readers fail closed
instead of silently dropping half of the label presentation.

Numeric callbacks are executable behavior and cannot be serialized. If a Pie
uses `valueFormatter`, `percentageFormatter`, or a radius formatter,
extraction fails closed unless the matching series-keyed
`RadialFormatterDocumentDescriptors` entry is supplied. The built-in registry
supports `braven.number.fixed` (`decimals`, `prefix`, and `suffix`) and
`braven.number.percent` (`decimals`). Custom stable IDs can be registered
through `ChartRuntimeBindings.formatters` and are resolved during hydration.

## AI and tool configuration

The public tool schema accepts `chart_type: "pie"`. It requires exactly one
series, a non-empty point label, a non-negative finite `y`, and a stable
ordering `x`. Omit Cartesian axes, crosshair, pan, and zoom. Pie-specific style
keys include start angle, direction, radius, gaps, fixed or slice-derived
borders (including HSL shifts), linear/radial gradient type and stops, gradient
angle/lightness shifts, explode offset, opacity, corner radius/treatment, shadow,
selected glow, animation mode, label position/content, optional
`pie_secondary_label_content` / `pie_secondary_label_position`, and label
thresholds. Secondary placement must be opposite the primary placement.
Use `pie_label_offset` to move outside-label lanes away from their compact
zero-offset position. Each Pie point may also include `radius`; when one point
uses it, every point must. Set series-level `radius_label` and `radius_unit`,
then choose `pie_radius_minimum_factor` and `pie_radius_scale` (`area` or
`linear`) in the chart style.

## Accessibility and responsive behavior

Each visible slice exposes category, formatted value, share, position, focus,
and selection state to assistive technology. Legend and data-table alternatives
keep every category available even when a compact chart hides a visual label.

The renderer honors text scaling, light/dark/high-contrast themes, visible
keyboard focus, and `MediaQuery.disableAnimationsOf`. Interactive legend and
table rows use 48 logical-pixel minimum targets in the public showcase.

## Runnable showcase

Open [Pie Charts](https://braven-pvm.github.io/braven_charts/?page=pie-charts)
to change datasets, labels, geometry, themes, and interaction; switch among
Chart, Data, and Split; change palettes, transparency, corners, elevation,
callout/tooltip styles, and legend placement; capture canonical JSON and a
preview; then restore a fresh chart runtime. Choose **Density and area** to
exercise the variable-radius model and inspect its second table column.
