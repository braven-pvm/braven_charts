# Gauge and Solid Gauge charts

Gauge answers one operational question: where is one measurement inside a
known numeric range? It combines an explicit domain with optional zones,
target, thresholds, status, and a direct center summary.

Use Gauge for one current measurement. Use Radial Bar when several independent
categories share a scale, and Donut when values contribute to one total.

## Needle Gauge

```dart
BravenChartPlus(
  series: [
    GaugeChartSeries.needle(
      id: 'cpu',
      metric: 'CPU utilization',
      unit: '%',
      value: 72,
      minimum: 0,
      maximum: 100,
      target: const GaugeTarget(value: 70, label: 'Target'),
      zones: const [
        GaugeZone(from: 0, to: 60, status: 'Healthy'),
        GaugeZone(from: 60, to: 85, status: 'Elevated'),
        GaugeZone(from: 85, to: 100, status: 'Critical'),
      ],
    ),
  ],
  gaugeChartConfig: const GaugeChartConfig(),
)
```

The value remains an absolute source measurement. `normalizedProgress` is
derived from `minimum`, `maximum`, and `value`; it is not stored as the data.
Zones are ordered, non-overlapping, and half-open. The last zone also owns the
exact maximum endpoint.

## Solid Gauge

Needle and Solid Gauge share the same measurement contract. Change only the
indicator style:

```dart
GaugeChartSeries.solid(
  id: 'availability',
  metric: 'Service availability',
  unit: '%',
  value: 99.94,
  minimum: 99,
  maximum: 100,
  target: const GaugeTarget(value: 99.9, label: 'SLO'),
  zones: const [
    GaugeZone(from: 99, to: 99.9, status: 'At risk'),
    GaugeZone(from: 99.9, to: 100, status: 'Healthy'),
  ],
  style: const SolidGaugeStyle(
    cornerRadius: 10,
    trackOpacity: 0.16,
  ),
)
```

This makes precise non-zero domains portable without converting the source
value to a percentage.

## Pane, ticks, and center content

`GaugeChartConfig` controls the shared radial pane and direct-display layers:

```dart
const GaugeChartConfig(
  pane: PolarPaneConfig(
    startAngleDegrees: -135,
    sweepAngleDegrees: 270,
    clockwise: true,
    innerRadiusFactor: 0.52,
    outerRadiusFactor: 0.9,
  ),
  tickCount: 6,
  showAxis: true,
  showTicks: true,
  showTickLabels: true,
  showZones: true,
  colorIndicatorByActiveZone: true,
  center: GaugeCenterConfig(
    showMetric: true,
    showValue: true,
    showTarget: true,
    showStatus: true,
  ),
)
```

For runtime-only center content, pass `gaugeCenterBuilder`. The builder receives
an immutable `GaugeCenterContext` with the metric, source value, formatted
value, domain, target, active status, and available center bounds. Runtime
widgets are intentionally not serialized; portable artifacts retain
`GaugeCenterConfig`.

## Targets and thresholds

`GaugeTarget` is the preferred reading. `GaugeThreshold` is an additional
absolute guide and may use a dash pattern. Neither reference invents status:
status always comes from the active `GaugeZone`.

```dart
thresholds: const [
  GaugeThreshold(
    value: 90,
    label: 'Limit',
    width: 2,
    dashPattern: [6, 4],
  ),
],
```

## Interaction, accessibility, and motion

Gauge uses shared hover, focus, tracking, tooltip, Workbench, table, artifact,
hydration, and generated-source infrastructure. V1 does not expose durable
Gauge selection because the current reading is state, not a selected record.

Needle and Solid variants expose equivalent semantics: metric, formatted value,
range, active status, and target. Decorative ticks and zones do not become
duplicate focus nodes. High-contrast media mode adds explicit zone boundaries,
and reduced-motion media mode applies value revisions immediately.

Stable-ID value changes interpolate from the previous reading. Switching
between authored Gauge presentations starts a fresh chart instead of morphing
unrelated geometry.

## Workbench and mobile review

The native Workbench table contains Metric, Value, Minimum, Maximum, Progress,
Target, and Status. Chart, Data, Split, and Source modes use the same portable
document.

See the runnable desktop showcase at `?page=gauge-charts`. The mobile showcase
contains four phone-sized Needle, Solid, partial-sweep, and dense-reference
examples.
