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

### Portable solid-arc gradients

Solid Gauge arcs can use a sweep or radial gradient without introducing a
runtime-only painter:

```dart
style: const SolidGaugeStyle(
  cornerRadius: 12,
  gradient: GaugeGradientStyle(
    type: GaugeGradientType.sweep,
    startColor: Color(0xFF22D3EE),
    endColor: Color(0xFF4F46E5),
  ),
),
```

Omit `startColor` and `endColor` to derive both stops from the active indicator
colour. `startLightnessShift` and `endLightnessShift` control that derivation.
The gradient is validated, serialized in chart artifacts, hydrated, and
included in generated Dart source.

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
  scale: GaugeScaleStyle(
    tickColor: Color(0xFF64748B),
    tickWidth: 2,
    tickLength: 14,
    labelStyle: PolarLabelStyle(
      color: Color(0xFF334155),
      fontSize: 11,
    ),
    labelOffset: 12,
  ),
  references: GaugeReferenceStyle(
    innerLineOffset: 6,
    outerLineOffset: 10,
    labelStyle: PolarLabelStyle(fontSize: 11),
    labelOffset: 12,
    showLabelPanel: true,
  ),
  center: GaugeCenterConfig(
    showMetric: true,
    showValue: true,
    showTarget: true,
    showStatus: true,
    verticalOffset: 4,
    lineSpacing: 5,
  ),
)
```

`GaugeScaleStyle` independently controls tick colour, width and length plus
numeric-label colour, size, weight, radial offset, and maximum width. Null tick
and text colours inherit the active axis theme. `labelOffset` is the
edge-to-edge gap between the tick endpoint and the nearest label edge, so
`0` keeps the two touching without drawing the text over the tick or arc.

### Dense instrument scales and segmented zones

Major ticks remain the labelled scale contract. Add unlabeled subdivisions
with `minorTicksPerInterval`, then place ticks and labels independently:

```dart
GaugeChartSeries.needle(
  id: 'revenue',
  metric: 'Revenue this month',
  unit: 'k',
  value: 80,
  minimum: 0,
  maximum: 200,
  zones: const [
    GaugeZone(from: 0, to: 100, status: 'Baseline'),
    GaugeZone(from: 100, to: 150, status: 'On plan'),
    GaugeZone(from: 150, to: 200, status: 'Ahead'),
  ],
  style: const NeedleGaugeStyle(
    needleWidth: 28,
    needleTipWidth: 2,
    pivotRadius: 14,
    pivotColor: Color(0xFFFFFFFF),
    pivotBorderColor: Color(0xFF111111),
    pivotBorderWidth: 6,
    axisThickness: 42,
  ),
)

const GaugeChartConfig(
  pane: PolarPaneConfig(
    startAngleDegrees: 180,
    sweepAngleDegrees: 180,
    clockwise: false,
  ),
  tickCount: 9,
  minorTicksPerInterval: 4,
  scale: GaugeScaleStyle(
    tickPosition: GaugeTickPosition.inside,
    tickGap: 12,
    minorTickWidth: 1,
    minorTickLength: 5,
    labelPosition: GaugeScaleLabelPosition.outside,
  ),
  zones: GaugeZoneStyle(
    gap: 5,
    cornerRadius: 2,
    opacity: 1,
  ),
)
```

`tickCount` always counts labelled major ticks. Each major interval receives
the requested minor ticks, so the example above paints 9 major and 32 minor
marks. `inside`, `centered`, and `outside` are semantic placements relative to
the rendered axis band. Inside and outside ticks can use `tickGap` for a clear
edge-to-edge rail separation; centered ticks retain the established outer-edge
split and ignore that gap.

`GaugeZoneStyle` changes only the visual presentation of operational zones.
Its gap, corner radius, opacity, border colour, and border width are portable;
the source `GaugeZone.from` and `to` values remain unchanged. Gaps are inserted
only between contiguous zones, not across genuine uncovered domain ranges.

`needleTipWidth: 0` preserves the classic pointed needle. A positive tip width
creates a tapered instrument pointer, while pivot fill and border remain
independently styleable.

`GaugeReferenceStyle` controls the shared target/threshold callout reach and
outside-label typography, offset, width, and optional panel. The target and
threshold still own their individual stroke colour, width, and dash pattern;
a null reference-label colour inherits the corresponding reference colour.
Its `labelOffset` uses the same edge-to-edge contract from the callout endpoint
to the nearest label or panel edge.

Center content supports independent typography for metric, value, target, and
status plus horizontal/vertical offsets and line spacing.

Compact and large-text layouts reserve enough of the pane to keep the value
readable. If every optional center line still cannot fit, the portable fallback
removes target, status, and metric copy in that order before reducing the value
below its readability threshold. The single semantic summary and tooltip retain
the complete metric, range, target, and active status.

For runtime-only center content, pass `gaugeCenterBuilder`. The builder receives
an immutable `GaugeCenterContext` with the metric, source value, formatted
value, domain, target, active status, and available center bounds. Runtime
widgets are intentionally not serialized; portable artifacts retain
`GaugeCenterConfig`.

## Legend

Set `showLegend: true` to display the native radial legend. A Gauge legend is
informational: it reports the metric, formatted value, and active status but
does not pretend that the single current reading is selectable.

The shared `ChartTheme.legendStyle` controls position, orientation, marker
shape and size, text size, opacity, background, border, and corner radius.
Because the Gauge contains exactly one measurement, both horizontal and
vertical orientations remain compact while the position still determines
which side of the pane owns the legend.

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

The showcase also exposes scale ticks and labels, reference callouts and
panels, center offsets, popup trigger and position, cursor following, delay,
surface, text, border, shadow, spacing, and font controls. Motion controls cover
entrance, data/theme revision, and interaction durations and curves.

## Workbench, Gallery, and mobile review

The native Workbench table contains Metric, Value, Minimum, Maximum, Progress,
Target, and Status. Chart, Data, Split, and Source modes use the same portable
document.

See the runnable desktop showcase at `?page=gauge-charts`. Its authored
examples cover Needle, Solid, Gradient, Zones, Target, Legend, Popup, partial
sweeps, accessibility, dense references, and a semicircular Instrument gauge.
They use varied 150–360 degree panes and start angles to demonstrate compact,
semicircular, broad, and complete-dial compositions. The Playground stays last
and randomizes portable data, major/minor scale geometry, zone segmentation,
needle shape, colours, gradients, labels, references, legend, popup, theme,
and motion while leaving every generated property editable in Options.

The main Gallery includes operational Needle, gradient Solid, and
high-contrast partial-sweep compositions. The mobile showcase contains four
phone-sized Needle, Solid, partial-sweep, and dense-reference examples.

## V1 boundaries

- A Gauge chart contains exactly one `GaugeChartSeries`.
- The measurement is an absolute source value inside an explicit domain.
- Durable selection is intentionally absent: the current reading is state,
  not a selected record.
- Runtime builders remain host-owned and are not serialized.
