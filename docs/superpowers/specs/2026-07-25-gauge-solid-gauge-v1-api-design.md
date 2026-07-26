# Gauge and Solid Gauge V1 API design

## Status and scope

Approved Phase 5 contract for BC-0017, ratified by the product owner on
2026-07-25. Implementation proceeds through the staged delivery slices below;
later composition or selection expansion requires a separate decision.

Gauge answers one question: **where is one operational measurement within an
explicit range, and what status does that imply?**

V1 supports exactly one measurement in one gauge pane. It includes needle and
solid-arc presentations, zones, thresholds, a target, ticks, direct center
content, deterministic artifacts, native table output, and accessible
semantics. It does not infer categories, shares, or multiple-measurement
composition.

## Semantic boundary

Gauge is a dedicated indicator family.

- **Gauge** presents one measurement, range, target, and operational status.
- **Radial Bar** compares several categorical measurements on one angular
  numeric scale.
- **Donut** partitions one total into category shares.
- **Polar Column** compares category magnitudes on a radial numeric scale.

Gauge reuses `RadialPaneGeometry`, `PolarPaneConfig`,
`AnnularSectorGeometry`, scale/tick utilities, color helpers, and motion
timing. It does not reuse the public `RadialBarChartSeries`,
`RadialCategorySeries`, or Pie/Donut normalization contracts.

The internal layout classifier uses its existing `ChartLayoutKind.gauge`
branch. Gauge does not masquerade as `ChartLayoutKind.polarAxis`.

## Public series model

One public `GaugeChartSeries` represents the measurement. Needle and Solid
Gauge are presentation modes of that same indicator model, not different data
contracts or renderers.

The proposed authored surface is:

```dart
BravenChartPlus(
  series: [
    GaugeChartSeries.needle(
      id: 'cpu',
      metric: 'CPU utilization',
      value: 72,
      minimum: 0,
      maximum: 100,
      unit: '%',
      target: const GaugeTarget(value: 70, label: 'SLO'),
      zones: const [
        GaugeZone(
          from: 0,
          to: 60,
          status: 'Healthy',
          color: Color(0xFF16A34A),
        ),
        GaugeZone(
          from: 60,
          to: 85,
          status: 'Elevated',
          color: Color(0xFFF59E0B),
        ),
        GaugeZone(
          from: 85,
          to: 100,
          status: 'Critical',
          color: Color(0xFFDC2626),
        ),
      ],
    ),
  ],
  gaugeChartConfig: const GaugeChartConfig(),
)
```

The Solid Gauge variant changes only presentation:

```dart
GaugeChartSeries.solid(
  id: 'availability',
  metric: 'Availability',
  value: 99.93,
  minimum: 99,
  maximum: 100,
  unit: '%',
  style: const SolidGaugeStyle(),
)
```

`GaugeChartSeries` extends `ChartSeries` so existing document, Workbench,
preview, controller-read, and table surfaces can consume it. It owns exactly
one canonical `ChartDataPoint`:

```text
x = 0
y = current measurement
label = metric
point index = 0
```

The point is an internal compatibility representation, not a category. Public
authors use `metric` and `value`, not a points list. `copyWith` preserves the
concrete subtype and validates the complete indicator contract.

Required series fields:

- stable `id`;
- visible `metric`;
- finite `value`;
- finite `minimum < maximum`;
- optional `unit`;
- optional `GaugeTarget`;
- zero or more `GaugeZone` values;
- zero or more `GaugeThreshold` values;
- one `GaugeIndicatorStyle`, resolved by the `.needle` or `.solid` factory.

`normalizedProgress` is derived as
`(value - minimum) / (maximum - minimum)`. It is never stored as the source
measurement and is never described as a share.

## Zones and status

`GaugeZone` is portable operational meaning:

```dart
class GaugeZone {
  const GaugeZone({
    required this.from,
    required this.to,
    required this.status,
    this.color,
  });
}
```

Rules:

- `from` and `to` are finite, inside the series domain, and `from < to`;
- zones are declared in ascending order;
- zones cannot overlap;
- gaps are allowed and mean “no configured status”;
- `status` is required visible text;
- a shared boundary belongs to the zone that starts at that boundary;
- the final zone includes `maximum`;
- the active zone and status are always derived from the current value;
- zone color is optional and resolves through the Gauge theme when omitted.

The half-open boundary rule is therefore `[from, to)`, except the final
domain endpoint is inclusive. This avoids two statuses being active at one
value.

## Target and thresholds

Target and threshold are different concepts.

`GaugeTarget` is the one preferred or expected measurement. It has a value,
optional label, optional color, and marker width. Its value must be inside the
series domain.

`GaugeThreshold` is one additional absolute reference. Thresholds have stable
declaration order, value, optional label/color, width, and dash pattern. Their
values must be inside the series domain.

Neither target nor threshold changes the active zone. A target is not
automatically success or failure; the zone supplies status meaning.

## Presentation styles

The public style boundary is a sealed indicator style:

```dart
sealed class GaugeIndicatorStyle {}

final class NeedleGaugeStyle extends GaugeIndicatorStyle {
  const NeedleGaugeStyle({
    this.needleLengthFactor = 0.88,
    this.needleWidth = 3,
    this.needleColor,
    this.pivotRadius = 6,
    this.pivotColor,
    this.axisThickness = 12,
    this.axisColor,
    this.axisOpacity = 0.16,
  });
}

final class SolidGaugeStyle extends GaugeIndicatorStyle {
  const SolidGaugeStyle({
    this.trackColor,
    this.trackOpacity = 0.14,
    this.cornerRadius = 8,
    this.borderColor,
    this.borderWidth = 0,
    this.opacity = 1,
  });
}
```

The series' ordinary `color` is the primary indicator color. Zone color may
replace it where the active-status treatment is enabled by chart
configuration. Per-presentation properties remain separate so a caller cannot
set a needle width on a Solid Gauge and assume it has meaning.

## Plot-level configuration

`GaugeChartConfig` owns pane and direct-display behavior:

```dart
class GaugeChartConfig {
  const GaugeChartConfig({
    this.pane = const PolarPaneConfig(
      startAngleDegrees: -135,
      sweepAngleDegrees: 270,
      innerRadiusFactor: 0.56,
      outerRadiusFactor: 0.88,
    ),
    this.tickCount = 6,
    this.showAxis = true,
    this.showTicks = true,
    this.showTickLabels = true,
    this.showZones = true,
    this.colorIndicatorByActiveZone = true,
    this.center = const GaugeCenterConfig(),
  });
}
```

`GaugeCenterConfig` is portable presentation configuration. It controls
whether metric, formatted value, target, and status are shown and carries
portable label styles. It does not contain widget builders.

`BravenChartPlus.gaugeCenterBuilder` is the optional runtime-only replacement.
It receives immutable `GaugeCenterContext` containing:

- metric and series identity;
- raw and formatted value;
- minimum, maximum, and normalized progress;
- target;
- active zone/status and effective colors.

The portable Canvas/text fallback always remains available for artifacts and
previews. A runtime builder is rebound through existing binding-descriptor
mechanisms and is never serialized.

## Composition

V1 composition is deliberately strict:

- exactly one `GaugeChartSeries`;
- exactly one `GaugeChartConfig`;
- no Cartesian, partition-radial, Polar Column, Radial Bar, Sunburst, or
  second Gauge series in the same plot;
- one series ID and one stable point identity;
- multiple measurements require a later design for pane overlap, status
  ownership, tables, labels, focus order, and semantics.

Invalid composition fails at construction and hydration. It is never
silently reduced to the first measurement.

## Geometry contract

`GaugeGeometryCalculator` is pure and deterministic. It receives the resolved
pane, explicit domain, current value, zones, target, thresholds, and active
indicator style.

Common output:

- normalized value and resolved value angle;
- full axis/track sector;
- one sector per zone;
- deterministic tick values and radial tick segments;
- target and threshold marker segments;
- value/tooltip anchor;
- center-content bounds;
- an indicator hit region suitable for hover and semantic focus.

Needle output:

- center/pivot;
- needle tip at the value angle;
- widened hit path independent of visual needle width;
- pivot geometry.

Solid Gauge output:

- background track;
- baseline-to-value annular sector;
- rounded end treatment constrained by track thickness;
- fill/border geometry.

Both modes use the same numeric transform:

```text
fraction = (value - minimum) / (maximum - minimum)
angle = pane.angleAt(fraction)
```

Full and partial sweeps, clockwise/counter-clockwise panes, non-zero and
negative domains, compact bounds, and exact min/max endpoints must produce
finite geometry.

## Interaction and controller boundary

The current measurement is data state, not selection state.

V1 therefore supports:

- pointer/touch hover or tracking for the value, target, and active status;
- one accessible focus stop for the indicator;
- table row focus and copy/export;
- controller capture, artifact, viewport, and data operations.

V1 does **not** add durable `ChartPointRef` selection, selection styling, or an
Enter-to-select interaction. A future product use case may add an explicit
indicator action callback, but the chart will not pretend that selecting the
only measurement changes its operational state.

## Native table and export

The native table contains one row:

```text
Metric | Value | Minimum | Maximum | Progress | Target | Status
```

Rules:

- `Progress` is a derived percentage of the explicit range;
- `Target` is empty when unconfigured;
- `Status` is empty when the current value is in no configured zone;
- full data copy and CSV preserve raw numeric values and stable series ID;
- display formatting uses the series formatter/unit;
- table selection chrome is disabled for Gauge V1 because durable Gauge
  selection is not part of the contract.

## Artifact and hydration contract

The portable document declares:

```text
series.gauge.v1
chart.gauge.config.v1
```

The series document type is `gauge`. It stores:

- the one canonical metric/value point;
- minimum and maximum;
- target;
- ordered zones and thresholds;
- the active indicator style discriminator and its complete style values;
- normal series ID, name, color, unit, metadata, and formatter descriptors.

Chart configuration stores `gaugeChart` with pane, ticks, axis/zone visibility,
active-zone color policy, and portable center fallback.

Extraction and hydration must:

- preserve raw value and exact domain rather than only normalized progress;
- preserve zone order, gap semantics, target, thresholds, and presentation;
- validate path-specific composition and domain failures;
- reproduce preview geometry without runtime builders;
- require runtime center rebinding only when a binding descriptor is present;
- fail as unsupported on older runtimes rather than hydrating as Radial Bar or
  Donut.

No active status is persisted independently; it is derived after hydration
from value and zones so stale status cannot disagree with the measurement.

## Motion and reduced motion

Value changes interpolate on the explicit numeric scale from the previous
measurement to the new measurement.

- needle mode rotates the pointer;
- solid mode changes the value arc;
- zones, target, ticks, pane allocation, and center layout do not replay mount
  motion for a value update;
- the center value/status update with the same resolved progress;
- reduced motion and zero-duration themes render the final value immediately.

Identity is the stable series ID. Replacing needle with solid presentation is
a fresh chart presentation, not a morph between unrelated geometry.

## Accessibility

The chart exposes one indicator summary, for example:

```text
CPU utilization, 72 percent, range 0 to 100, Elevated,
target 70 percent.
```

Requirements:

- metric, formatted value, min/max, target, and active status are available
  without relying on color;
- needle and solid modes expose equivalent semantic meaning;
- ticks and decorative zones do not create duplicate focus nodes;
- high contrast preserves zone/status differentiation with borders or
  patterns where color alone is insufficient;
- large text reserves center/outer label space rather than shrinking text
  below theme minimums;
- Canvas and runtime center-builder semantics remain mutually exclusive.

## Workbench and showcase

The dedicated Gauge page must expose:

- authored Needle, Solid, Zones, Target, Partial sweep, Accessible, Density,
  and Playground examples;
- the standard Chart/Data/Split/Source Workbench;
- searchable inspector sections with on-demand descriptions;
- the shared palette component, including clear/custom behavior;
- deterministic seeded property and data randomization with Play/Pause;
- options that visibly control every public property;
- fresh chart identity when switching authored presentations;
- desktop, tablet/touch, phone, reduced-motion, high-contrast, and large-text
  review paths.

## Delivery slices

1. **Model and geometry**
   - public series/config/style/zone/target/threshold models;
   - strict layout classification;
   - pure geometry and model/geometry tests.
2. **Renderer and semantics**
   - Gauge series element, ticks/zones/target/center fallback;
   - hit/tracking, accessibility, themes, value motion, reduced motion.
3. **Artifacts and product surfaces**
   - codecs, capabilities, hydration, generated source, table/CSV,
     Workbench, previews, and controller read operations.
4. **Showcase and release**
   - complete inspector/randomizer, mobile examples, Gallery/Chart Types,
     guide/API docs, goldens, media, web build, publish dry run, and visual
     acceptance.

Each slice remains on BC-0017's dedicated branch. No slice lands a public
model that the normal mounted runtime cannot eventually hydrate and render.

## V1 exclusions

- no multiple measurements or concentric Gauge composition;
- no pointer/arc selection state;
- no Gauge implemented as Radial Bar, Donut, or Polar Column data;
- no mixed Cartesian/radial plots;
- no drag-to-edit measurement or target;
- no arbitrary widget serialization;
- no inferred success/failure based only on target direction;
- no logarithmic, time, or categorical Gauge scale;
- no 3D, dashboard needle physics, or spring overshoot in the release gate.

## Acceptance tests

- model and zone-boundary validation, including gaps and exact endpoints;
- negative/non-zero domains and normalized progress;
- needle and solid geometry at min, middle, max, target, and thresholds;
- full/partial and clockwise/counter-clockwise panes;
- compact, normal, constrained, high-contrast, large-text, and reduced-motion
  rendering;
- tooltip/focus/semantics parity without durable selection;
- table/copy/CSV raw and formatted values;
- deterministic JSON, capability negotiation, hydration, preview, runtime
  center rebinding, and generated Dart;
- Workbench Chart/Data/Split/Source and property/randomizer coverage;
- direct-route browser, tablet/touch, and phone validation;
- real-renderer goldens and a representative warm-paint benchmark;
- full package/example tests, release web build, media capture, public-docs
  gate, and publish dry run.

## Ratification decisions

1. Use one `GaugeChartSeries` with needle and solid style variants, not
   separate data models.
2. Keep V1 at exactly one measurement per pane.
3. Derive status exclusively from ordered non-overlapping zones.
4. Keep current measurement state separate from durable chart selection.
5. Store source value/domain and derive normalized progress.
6. Use `series.gauge.v1` and `chart.gauge.config.v1` capabilities with no
   fallback to Radial Bar or Donut.
