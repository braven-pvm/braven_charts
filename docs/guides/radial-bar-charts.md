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

## Styling and labels

`RadialBarStyle` controls mark and track treatment:

```dart
const RadialBarStyle(
  cornerRadius: 8,
  opacity: 1,
  borderWidth: 1,
  trackOpacity: 0.12,
  showDataLabels: true,
)
```

Leave colors null to inherit theme- and category-derived colors. Use
`barColors` on `RadialBarChartSeries.fromMap` for category-specific mark
colors. Category labels, scale labels, grid guides, tick count, and absolute
threshold guides are configured on `RadialBarChartConfig`.

## Interaction and developer tools

Radial Bar uses the shared hit, selection, focus, keyboard, tooltip, semantics,
artifact, source, and Workbench contracts. Pointer input resolves the exact
annular mark under the pointer. Keyboard traversal follows visible track
order, Enter or Space selects, and Escape clears focus and selection.

The native Workbench exposes Chart, Data, Split, and Source modes. Its table
contains category, series, and absolute value columns; copy and CSV use the
same rows. Chart documents preserve the explicit domain, baseline, style,
selection style, pane, labels, grid, and thresholds.

V1 accepts exactly one `RadialBarChartSeries`. Grouped or stacked tracks are
deferred until their scale, table, selection, and composition semantics are
specified rather than inferred from visual similarity.

See the runnable showcase at `?page=radial-bar`.
