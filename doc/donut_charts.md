# Donut charts

Donut charts show contributions to one meaningful whole around a shared,
configurable center opening. They use the same stable category identity,
selection, table, artifact, tooltip, label, legend, and variable-radius
contracts as Pie while adding annular geometry and portable center content.

[Open the live Donut showcase](https://braven-pvm.github.io/braven_charts/?page=donut-charts)

## Quick start

```dart
BravenChartPlus(
  title: 'Revenue contribution',
  showLegend: true,
  series: [
    DonutChartSeries.fromMap(
      id: 'revenue-share',
      name: 'Revenue share',
      unit: 'USD',
      values: const {
        'Subscriptions': 42,
        'Services': 31,
        'Hardware': 27,
      },
      donutStyle: const DonutChartStyle(
        innerRadiusFactor: 0.58,
        startAngleDegrees: -90,
        sweepAngleDegrees: 360,
        sliceGap: 2,
        cornerRadius: 8,
        gradient: PieGradientStyle(type: PieGradientType.radial),
      ),
      centerContent: const DonutCenterContent(
        label: 'Revenue',
        valueMode: DonutCenterValueMode.selectedOrTotal,
      ),
      dataLabels: const PieDataLabelConfig(
        position: PieDataLabelPosition.outside,
        content: PieDataLabelContent.categoryAndPercentage,
      ),
    ),
  ],
  interactionConfig: const InteractionConfig(
    tooltip: TooltipConfig(enabled: true),
    enableSelection: true,
  ),
)
```

Map insertion order becomes the stable slice order. Each category becomes the
visible label and each point index remains the durable identity used by the
chart, legend, table, controller, artifact, and restored runtime.

## Data and validation

Donut accepts exactly one `DonutChartSeries` and cannot mix with Cartesian or
Pie series. Contributions must be finite and non-negative, and category labels
must not be empty. Zero values remain in JSON and the native table but do not
paint a slice. An all-zero series uses the configured empty state.

The defining geometry is `innerRadiusFactor`. It must be greater than `0` and
less than `1`. `sweepAngleDegrees` must be greater than `0` and at most `360`.
The renderer keeps one circular inner boundary even when slices use different
outer radii.

## Geometry

`DonutChartStyle` extends the shared radial style with:

- `innerRadiusFactor`: shared center opening relative to maximum outer radius;
- `sweepAngleDegrees`: full or partial angular span;
- `startAngleDegrees` and `clockwise`: orientation and ordering;
- `radiusFactor`: chart size within the measured viewport;
- `sliceGap`: physical separation without changing category share;
- border, gradient, opacity, corner, elevation, selection, and animation
  options shared with Pie.

```dart
const DonutChartStyle(
  innerRadiusFactor: 0.66,
  startAngleDegrees: 130,
  sweepAngleDegrees: 280,
  clockwise: true,
  radiusFactor: 0.9,
  sliceGap: 3,
  cornerRadius: 10,
  cornerTreatment: PieCornerTreatment.circularCenter,
)
```

Use `PieCornerTreatment.circularCenter` when rounded outer slices must retain a
perfect circular opening. `outerOnly` keeps inner corners sharp, while
`roundAll` preserves independent rounding on every corner.

## Entrance motion

`DonutChartStyle.animationMode` overrides the shared
`ChartTheme.pieChartTheme.animationMode` for one series. The available
`PieAnimationMode` values are:

| Mode | Behavior |
| --- | --- |
| `none` | Render the final ring immediately |
| `grow` | Grow the ring radially from its shared center; this remains the compatibility default |
| `sweep` | Reveal categories in source order from `startAngleDegrees`, following `clockwise` and the configured sweep span |
| `fade` | Fade the complete final geometry into view without changing its radii |

```dart
final controller = BravenChartController();

BravenChartPlus(
  bravenChartController: controller,
  series: [
    DonutChartSeries.fromMap(
      id: 'delivery-mix',
      values: const {'Build': 46, 'Discovery': 18, 'Design': 14},
      donutStyle: const DonutChartStyle(
        innerRadiusFactor: 0.62,
        animationMode: PieAnimationMode.sweep,
      ),
    ),
  ],
);

controller.replayRadialEntrance();
```

The data-update duration and curve come from `ChartTheme.animationTheme`.
`MediaQuery.disableAnimationsOf`, `PieAnimationMode.none`, and a zero duration
always render the final frame immediately, including controller-triggered
replays. Labels wait until the entrance lifecycle completes so elastic curves
cannot flash them on and off. Entrance modes do not change source data,
selection identity, artifact content, or the native table.

## Center content

Center content is text-first and portable. It is painted into the measured
opening, included in PNG previews and artifacts, and never intercepts slice
hit testing.

| Mode | Behavior |
| --- | --- |
| `total` | Always show the sum of visible contributions |
| `selectedValue` | Show the selected slice value |
| `selectedOrTotal` | Show the selected value, otherwise the total |
| `custom` | Show `customValue` exactly as configured |

```dart
const DonutCenterContent(
  label: 'Revenue',
  valueMode: DonutCenterValueMode.selectedOrTotal,
  labelStyle: LabelStyle(
    textStyle: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
    backgroundColor: Colors.transparent,
    borderColor: Colors.transparent,
    borderWidth: 0,
    borderRadius: 0,
    padding: EdgeInsets.zero,
  ),
  valueStyle: LabelStyle(
    textStyle: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
    backgroundColor: Colors.transparent,
    borderColor: Colors.transparent,
    borderWidth: 0,
    borderRadius: 0,
    padding: EdgeInsets.zero,
  ),
)
```

Series-level `labelStyle` and `valueStyle` override
`ChartTheme.pieChartTheme.centerLabelStyle` and `centerValueStyle`. Text scales
or ellipsizes deterministically inside the available opening. When multiple
points are selected, the lowest source index supplies the selected value.

For custom status text:

```dart
const DonutCenterContent(
  label: 'Status',
  valueMode: DonutCenterValueMode.custom,
  customValue: 'On track',
)
```

## Variable outer radius

Provide one radius value for every category when angle and outer radius should
communicate separate metrics. Angular share still comes from `values`; the
second metric controls only the available annular thickness.

```dart
DonutChartSeries.fromMap(
  id: 'campaigns',
  unit: 'leads',
  values: const {'Search': 31, 'Social': 24, 'Partners': 19},
  radiusValues: const {'Search': 82, 'Social': 54, 'Partners': 68},
  sliceRadiusConfig: const RadialSliceRadiusConfig(
    minimumFactor: 0.42,
    scale: PieSliceRadiusScale.area,
    label: 'Audience reach',
    unit: 'k users',
  ),
  donutStyle: const DonutChartStyle(innerRadiusFactor: 0.32),
)
```

Radius values must be complete, finite, and non-negative. They appear in
tooltips, the native table, row copy, CSV export, AI input, and artifacts.
`area` is the perceptual default; use `linear` only when literal radial length
is the intended encoding.

## Group small categories without collapsing data

Use `RadialSliceGroupingConfig` when many small categories would make the ring
and legend noisy:

```dart
DonutChartSeries.fromMap(
  id: 'support-channels',
  unit: 'tickets',
  values: const {
    'Portal': 64,
    'Phone': 12,
    'Partners': 9,
    'Email': 6,
    'Chat': 4,
    'Events': 3,
    'Other source': 2,
  },
  sliceGroupingConfig: const RadialSliceGroupingConfig(
    minimumShare: 0.07,
    minimumSourceCount: 2,
    label: 'Other',
  ),
);
```

The renderer appends one aggregate slice after the retained categories. The
series still stores all seven source points. Tables, copy/CSV, selection
callbacks, artifacts, and hydration therefore keep their original rows and
values. The point-tap callback receives the visible aggregate point; read the
expanded originals from `BravenChartController.selectedPointRefs` or
`InteractionConfig.onSelectionChanged`.
Activating the aggregate selects all represented `ChartPointRef` values;
activating any grouped table row selects the same visible aggregate. The
controller exposes the original refs, not a synthetic index.

Grouping and variable radii are mutually exclusive until the host chooses a
defined aggregation rule for the radius metric.

## Selection and controllers

Slice, legend, data-table, keyboard, and controller selection all resolve the
same source `ChartPointRef(seriesId, pointIndex)` values. Ungrouped slices map
to one ref; a grouped slice maps to every represented ref. The selected center
value and tooltip therefore update no matter where selection began.

```dart
final controller = BravenChartController();

BravenChartPlus(
  bravenChartController: controller,
  series: [donut],
)

final revision = controller.effectiveDocumentRevision.value!;
controller.selectPoint(
  const ChartPointRef(seriesId: 'revenue-share', pointIndex: 1),
  revision: revision,
);

final selected = controller.selectedPointRefs;
```

Use arrow keys to focus slices, Enter to select, and Escape to clear when the
chart has keyboard focus. Center content contributes one non-interactive
summary semantics node; every slice keeps its own category, value, share,
ordinal, and selection semantics.

## Native data table

Extract a document and project it through `ChartTableModel` to get the package
table. Donut uses the radial `Category | Value | Radius? | Share` projection.

```dart
final snapshot = controller.extractDocument(
  const ChartDocumentExtractOptions(documentId: 'revenue-donut'),
);

if (snapshot case ChartArtifactSuccess<ChartDocumentSnapshot>()) {
  final table = ChartTableModel.fromDocument(
    snapshot.value.document,
    viewState: snapshot.value.viewState,
  );
  // ChartDataTable(model: table)
}
```

`ChartDataTable` includes dataset copy, bounded clipboard behavior, per-row
copy, CSV export, sorting, virtualization, and row activation. Pass
`selectedPointRefs` and route `onRowActivated` through the controller to keep
the row, slice, tooltip, and center synchronized.

For a complete Chart/Data/Split surface, use `BravenChartWorkbench`. Its
horizontal Split auto-fits the radial `Category | Value | Radius? | Share`
projection, preserves the mounted chart while the divider moves, and supports
pointer drag, arrow-key resizing, and Escape/double-click auto-fit reset.

## Capture, transport, and restore

```dart
final captured = await controller.extractArtifact(
  ChartArtifactExtractOptions(
    artifactId: 'revenue-donut-copy',
    createdAt: DateTime.now().toUtc(),
    includePreview: true,
    documentOptions: const ChartDocumentExtractOptions(
      documentId: 'revenue-donut',
    ),
  ),
);

if (captured case ChartArtifactSuccess<ChartArtifact>()) {
  final json = ChartArtifactJsonCodec.encode(captured.value);
  if (json case ChartArtifactSuccess<String>()) {
    final restored = ChartDocumentHydrator.hydrateJson(json.value);
  }
}
```

Donut documents declare `series.donut` and `series.donut.style.v1`.
Center content adds `series.donut.center-content.v1`; variable radius adds
`series.donut.variable-radius.v1`; source-preserving grouping adds
`series.radial.grouping.v1`. Unsupported readers fail with a capability
diagnostic instead of silently rendering a different chart.

## AI tool input

Use `chart_type: donut` and labelled points. The style object uses the same
validated public contract:

```json
{
  "chart_type": "donut",
  "title": "Revenue contribution",
  "series": [
    {
      "id": "revenue-share",
      "name": "Revenue",
      "unit": "USD",
      "data": [
        {"label": "Subscriptions", "y": 42},
        {"label": "Services", "y": 31},
        {"label": "Hardware", "y": 27}
      ]
    }
  ],
  "style": {
    "donut_inner_radius_factor": 0.58,
    "donut_sweep_angle": 360,
    "donut_center_visible": true,
    "donut_center_label": "Revenue",
    "donut_center_value_mode": "selected_or_total",
    "pie_slice_gap": 2,
    "pie_gradient_type": "radial"
  }
}
```

For a variable-radius Donut, add `radius` to every point, `radius_label` and
optional `radius_unit` to the series, then configure
`pie_radius_minimum_factor` and `pie_radius_scale`.

## Theming

Donut uses `ChartTheme.pieChartTheme` for shared radial colors, borders,
gradients, opacity, callouts, center styles, shadows, selected elevation, and
animation defaults. Series-level `DonutChartStyle`, `DonutCenterContent`, and
`PieDataLabelConfig` override theme defaults. Legend and tooltip styling use
the shared `LegendStyle` and `InteractionTheme` contracts.

## Product boundaries

- Donut is single-series and radial; it does not render Cartesian axes,
  crosshairs, scrollbars, pan, or zoom.
- The center accepts portable text configuration, not an arbitrary Widget or
  builder.
- Multiple concentric rings, drill-down, center actions,
  data-to-data morphing, per-slice staggering, spring choreography, 3D effects,
  and image shaders are not V1 features.
- Prefer bars when precise comparison matters more than part-to-whole meaning
  or when categories are too dense for readable slices.
