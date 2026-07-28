# Radial Bar charts

Radial Bar compares independent category values on concentric tracks. Each
category owns one ring, and its absolute value maps to an angular sweep inside
an explicit numeric domain.

This is intentionally different from the other radial families:

- Pie and Donut divide one total into angular shares.
- Concentric Donut compares several independent part-to-whole distributions.
- Polar Column places categories around the angle and maps values to radius.
- Radial Bar places categories on radius and maps values to angle.
- Gauge charts present one or a small number of indicators, usually with zones
  and a dedicated gauge axis.

Radial Bar never derives a denominator from the supplied values.

## Basic progress tracks

```dart
BravenChartPlus(
  series: [
    RadialBarChartSeries.fromMap(
      id: 'journey',
      name: 'Customer journey',
      unit: '%',
      values: const {
        'Activation': 92,
        'Retention': 78,
        'Adoption': 66,
        'Expansion': 57,
      },
      minimum: 0,
      maximum: 100,
      baseline: 0,
    ),
  ],
  radialBarChartConfig: const RadialBarChartConfig(
    thresholds: [
      RadialBarThreshold(value: 75, label: 'Target'),
    ],
  ),
)
```

Category identity follows map insertion order. The factory converts categories
to stable zero-based point ordinals, so controller references, selection,
tables, artifacts, hydration, and generated Dart source preserve the same
identity.

## Signed values

Set a domain that crosses zero and keep `baseline: 0`:

```dart
RadialBarChartSeries.fromMap(
  id: 'drivers',
  values: const {
    'Acquisition': 64,
    'Support': -36,
    'Reliability': 82,
    'Churn': -52,
  },
  minimum: -100,
  maximum: 100,
  baseline: 0,
)
```

Positive and negative marks sweep in opposite directions from the same
baseline. Baseline, minimum, maximum, values, and thresholds are absolute
values; none are normalized to shares.

## Partial panes and track geometry

`RadialBarChartConfig.pane` uses the shared `PolarPaneConfig`:

```dart
const RadialBarChartConfig(
  pane: PolarPaneConfig(
    startAngleDegrees: -135,
    sweepAngleDegrees: 270,
    clockwise: true,
    innerRadiusFactor: 0.24,
    outerRadiusFactor: 0.84,
  ),
  trackGap: 8,
  trackOrder: RadialBarTrackOrder.outerToInner,
)
```

The renderer reduces a requested physical gap when a compact pane must fit
many tracks. It never silently drops a category. Rounded ends are bounded by
the resolved track thickness.

## Marks, tracks, and gradients

`RadialBarStyle` controls mark and track treatment:

```dart
const RadialBarStyle(
  cornerRadius: 8,
  opacity: 1,
  borderWidth: 1,
  trackOpacity: 0.12,
  gradient: RadialBarGradientStyle(
    type: RadialBarGradientType.sweep,
    startLightnessShift: 0.16,
    endLightnessShift: -0.12,
  ),
  showDataLabels: true,
)
```

Leave colors null to inherit theme- and category-derived colors. Use
`barColors` on `RadialBarChartSeries.fromMap` for category-specific mark
colors. A gradient can derive both endpoints from each category color or use
fixed `startColor` and `endColor` values. Sweep gradients follow the value
arc; radial gradients shade across its thickness.

## Value labels and category labels

Value labels are series styling because they describe individual marks:

```dart
const RadialBarStyle(
  showDataLabels: true,
  dataLabels: RadialBarDataLabelConfig(
    position: RadialBarDataLabelPosition.outsideCallout,
    content: RadialBarDataLabelContent.categoryAndValue,
    colorMode: RadialBarDataLabelColorMode.fixed,
    textStyle: PolarLabelStyle(
      color: Color(0xFF172033),
      fontSize: 12,
      fontWeight: FontWeight.w600,
    ),
    offset: 8,
    showPanel: true,
    connectorLength: 18,
    connectorWidth: 1,
  ),
)
```

`insideEnd` keeps each value on its mark and supports automatic contrast
against the resolved mark paint. `outsideCallout` places values in
collision-resolved side lanes. Fixed color is useful when a label or its panel
must follow a product theme rather than the mark underneath it.

Category labels belong to `RadialBarChartConfig` because they describe the
track layout:

```dart
const RadialBarChartConfig(
  showCategoryLabels: true,
  categoryLabels: RadialBarCategoryLabelConfig(
    position: RadialBarCategoryLabelPosition.startGap,
    orientation: RadialBarCategoryLabelOrientation.followStartAngle,
    offset: 8,
    textStyle: PolarLabelStyle(
      color: Color(0xFF172033),
      fontSize: 12,
    ),
  ),
)
```

`startGap` follows the configurable pane start angle while keeping text
upright. `outsideCallout` uses category-colored connectors and thins labels
deterministically when the available lane cannot fit every category.
`legacyOnTrack` is retained for compatibility but is less resilient when text
can cross both a dark mark and a light background.

Panels, offsets, connector length, width, and color are independently
configurable for category and value labels. Under tight constraints or large
text scale, visible labels may be thinned rather than overlapped or clipped;
the underlying categories remain present in tables, export, focus traversal,
and accessibility semantics.

## Guides and thresholds

Category labels, scale labels, grid guides, tick count, and absolute threshold
guides are configured on `RadialBarChartConfig`. Threshold values use the same
explicit domain as the marks:

```dart
const RadialBarChartConfig(
  showScaleLabels: true,
  showGridLines: true,
  tickCount: 5,
  thresholds: [
    RadialBarThreshold(
      value: 75,
      label: 'Target',
      color: Color(0xFF0EA5E9),
      width: 1.5,
      dashPattern: [6, 4],
    ),
  ],
)
```

## Selection, tooltips, and legends

`RadialSelectionStyle` selects either the shared explode treatment or a
towards-viewer lift. Lift scale, offset, and backdrop blur are bounded so
invalid transforms cannot enter the renderer:

```dart
selectionStyle: const RadialSelectionStyle(
  effect: RadialSelectionEffect.lift,
  liftScale: 1.08,
  liftOffset: 6,
  backdropBlur: 1.25,
),
```

Hover and keyboard focus resolve the exact annular mark, including a complete
100% arc. Tooltips use the shared tracking configuration and theme, so their
visibility, text, panel, border, and opacity remain consistent with other
chart families.

When `showLegend` is enabled on `BravenChartPlus`, one native legend item is
generated per category track rather than one item for the whole series.
`ChartThemeData.legendStyle` controls position, orientation, marker shape and
size, text style, opacity, and panel treatment. Activating an item selects the
same category in the chart and data table. Applications may also supply the
shared radial legend item builder for richer value-card content; this does not
create a Radial-Bar-specific legend system.

## Interaction and developer tools

Radial Bar uses the shared hit, selection, focus, keyboard, tooltip, semantics,
artifact, source, and Workbench contracts. Pointer input resolves the exact
annular mark under the pointer. Keyboard traversal follows visible track
order, Enter or Space selects, and Escape clears focus and selection. A
baseline-valued category has no painted sweep but still remains accessible and
exportable.

The native Workbench exposes Chart, Data, Split, and Source modes. Its table
contains category, series, and absolute value columns; copy and CSV use the
same rows. Chart documents preserve the explicit domain, baseline, style,
selection style, pane, labels, grid, and thresholds.

The current contract accepts exactly one `RadialBarChartSeries`. Grouped or
stacked tracks are
deferred until their scale, table, selection, and composition semantics are
specified rather than inferred from visual similarity.

See the runnable showcase at `?page=radial-bar`.
