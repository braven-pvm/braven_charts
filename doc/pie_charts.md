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
- metadata is transported but not interpreted by the renderer.

Zero values remain in artifacts and data tables but do not paint a slice. An
all-zero series renders the chart's configured empty state. Negative, `NaN`,
infinite, or empty-label values fail with `ArgumentError` in release and debug
modes. Duplicate labels are allowed because labels are display text, not
identity.

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

The geometry preserves an internal inner-radius seam, but doughnut, nested,
rose, and semi-circular charts are not part of this release.

## Theme and advanced slice styling

`ChartTheme.pieChartTheme` defines reusable product-wide Pie defaults. A
`PieChartStyle` may override gradient, opacity, corner radius, elevation, or
animation for one series. Null series values continue to inherit the chart
theme.

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
selected elevation. `MediaQuery.disableAnimationsOf` and a zero theme duration
always win over `PieAnimationMode.grow`.

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
  outsideOffset: 0,
  connectorLength: 14,
  connectorWidth: 1,
  collisionStrategy: PieDataLabelCollisionStrategy.shiftAndHide,
)
```

Content may be category, value, percentage, or a combined variant. Inside
labels are centered in eligible slices and omitted when the text does not fit.
Outside labels are split into compact left and right lanes beside the painted
pie, shifted deterministically, and—under `shiftAndHide`—the lowest-priority
labels are hidden when the lane cannot fit. Set `outsideOffset` to move both
lanes outwards; `0` is tight to the pie. The renderer clamps the lanes inside
the plot. The complete legend and table remain available when a label is hidden.

`minimumShare` uses the inclusive range 0–1. `minimumSweepDegrees` uses 0–360.
Outside offset, connector length, width, and label padding must be finite and
non-negative.

### Callout styling

Set `PieDataLabelConfig.calloutStyle` for one series, or
`PieChartTheme.calloutStyle` for every Pie chart in a theme. Both use the
shared `LabelStyle` model, including text, surface, border, radius, padding,
and shadow. A null callout style preserves plain label text.

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

## Capture, JSON, preview, and restore

Pie artifacts use the built-in `series.pie` capability and schema version 1.
No executable code is serialized. Older readers that do not support the
capability reject the document instead of treating it as another series type.

```dart
final captured = await controller.extractArtifact(
  ChartArtifactExtractOptions(
    artifactId: 'revenue-share-2026-07',
    includePreview: true,
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
`series.pie.style.v2`, so older readers fail closed rather than silently
dropping advanced appearance values.

## AI and tool configuration

The public tool schema accepts `chart_type: "pie"`. It requires exactly one
series, a non-empty point label, a non-negative finite `y`, and a stable
ordering `x`. Omit Cartesian axes, crosshair, pan, and zoom. Pie-specific style
keys include start angle, direction, radius, gaps, fixed or slice-derived
borders (including HSL shifts), linear/radial gradient type and stops, gradient
angle/lightness shifts, explode offset, opacity, corner radius, shadow,
selected glow, animation mode, label position/content, and label thresholds.
Use `pie_label_offset` to move outside-label lanes away from their compact
zero-offset position.

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
preview; then restore a fresh chart runtime.
