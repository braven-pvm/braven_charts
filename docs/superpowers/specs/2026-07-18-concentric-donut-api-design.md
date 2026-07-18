# Concentric Donut API design

## Status and scope

Approved family boundary; focused Phase 1 API design written during Phase 0.
Implementation remains out of scope until the Phase 0 regression gate passes.

Concentric Donut compares several independent part-to-whole distributions in
one radial plot. Each ring is a real `DonutChartSeries` with its own total. It
is not a hierarchy, a progress display, or a polar axis chart.

## Public composition

The chart continues to receive ordinary series through `BravenChartPlus.series`:

```dart
BravenChartPlus(
  series: [
    DonutChartSeries.fromMap(
      id: 'current',
      name: 'Current period',
      values: current,
    ),
    DonutChartSeries.fromMap(
      id: 'previous',
      name: 'Previous period',
      values: previous,
    ),
  ],
  concentricDonutConfig: const ConcentricDonutConfig(
    innerRadiusFactor: 0.32,
    ringGap: 6,
  ),
)
```

No `ConcentricDonutSeries` is introduced. A collection of rings is a chart
composition, not one series pretending to contain several datasets.

Composition validation is:

- one `DonutChartSeries` remains the existing single-Donut path;
- two or more `DonutChartSeries` values select Concentric Donut layout;
- Pie, Cartesian, polar-axis, hierarchy, and gauge series cannot mix into the
  composition;
- every series ID must be unique;
- each series independently satisfies existing Donut source validation.

## `ConcentricDonutConfig`

The provisional immutable public contract is:

```dart
class ConcentricDonutConfig {
  const ConcentricDonutConfig({
    this.innerRadiusFactor = 0.32,
    this.outerRadiusFactor = 1,
    this.ringGap = 4,
    this.order = ConcentricRingOrder.outerToInner,
    this.ringWeights = const <String, double>{},
    this.legendMode = ConcentricDonutLegendMode.groupedByRing,
    this.centerContent = const DonutCenterContent(),
  });
}
```

Required validation:

- radius factors are finite, `0 <= inner < outer <= 1`;
- ring gap is finite and non-negative;
- weight keys identify a real series exactly once;
- weights are finite and strictly positive;
- the resulting band allocation leaves positive thickness for every ring;
- document decoding reports a path-specific failure instead of silently
  normalizing invalid values.

`ringWeights` controls relative radial thickness, not the series total. Missing
IDs use weight `1`. Series list order is the stable tiebreaker and the default
legend/table order.

## Geometry ownership

The composition calculator receives one plot-level pane and allocates a
non-overlapping `[innerRadius, outerRadius]` band to each series. It then asks
the existing Donut geometry path to partition that band by category share.

Rules:

- `ConcentricDonutConfig` owns ring placement for multi-ring charts;
- per-series start angle, sweep, direction, gap, corners, gradients, grouping,
  selection offset, and labels remain series behavior;
- all rings share one plot center;
- outer selection/elevation overflow is included in plot measurement;
- choosing or hovering a slice never changes ring allocation;
- single-series Donut geometry remains controlled by its existing
  `DonutChartStyle` and is not routed through the multi-ring allocator.

The first implementation should reject incompatible per-ring pane sweeps or
directions. A later explicit synchronization policy may allow them, but the V1
must not produce rings that imply comparison while using different angular
frames.

## Center ownership

One radial plot has one center surface.

- Single Donut retains the existing series-owned portable fallback.
- Concentric Donut uses `ConcentricDonutConfig.centerContent` as its portable
  fallback.
- `donutCenterBuilder` and `onDonutCenterTap` remain runtime-only plot hooks.
- builder data adds all ring summaries and the selected ring/point identity.
- conflicting per-series center declarations are never silently selected.
- Canvas fallback and widget builder semantics remain mutually exclusive.

## Selection and controller

Existing `ChartPointRef(seriesId, pointIndex)` is the durable flat identity.

- chart slice, legend item, table row, controller command, and restored view
  state converge on the same reference;
- grouping expands visible `Other` selection only within its owning series;
- single selection remains the default, with additive selection following the
  existing interaction configuration;
- focus traversal is outer-to-inner or inner-to-outer according to configured
  ring order, then source point order within a ring;
- selection visuals and tooltip anchors are ring-local and viewport-clamped.

## Legend and labels

The default legend groups items under a series/ring heading. A flat legend is
allowed only when its item content includes unambiguous ring identity.

Custom legend builders receive:

- series ID, series name, ring index, ring radii, and ring total;
- source point identity, visible/grouped identity, category, value, and share;
- effective color/style, focus, hover, selection, and semantic state;
- callbacks supplied by the chart rather than invented by the builder.

Labels remain slice labels. Collision resolution operates across all rings so
an inner-ring label cannot unknowingly overlap an outer-ring label.

## Native table and export

The native projection adds a leading Ring column:

```text
Ring | Category | Value | Share | optional radius metric
```

Shares are calculated against the owning ring total. Copy row, copy data, and
CSV export include stable series ID in machine-oriented output even when the
visible heading uses the series name. Grouped visible slices retain every
original source row in exported full data.

## Artifact and hydration contract

The document declares `series.donut.concentric.v1` and stores the portable
composition config at chart level. Every ring remains an ordinary Donut series
document so existing point, formatter, grouping, and style codecs are reused.

Extraction and hydration must preserve:

- ring order and weights;
- each independent total and source point order;
- composition radii/gap and center fallback;
- selected/focused `ChartPointRef` values;
- formatter descriptors and runtime binding requirements;
- deterministic preview geometry.

An older runtime reports an unsupported capability. It must not flatten rings,
merge totals, or hydrate only the first series.

## V1 exclusions

- no parent-child relationship or drilldown;
- no inferred category alignment across rings;
- no progress/max semantics;
- no Pie overlay at the center;
- no cross-ring stacking;
- no mixed sweeps or directions;
- no arbitrary manual inner/outer radius per ring.

## Acceptance tests

- ring allocation for equal and weighted rings;
- compact layouts and selection overflow;
- independent totals and repeated category names;
- grouped points and selection expansion scoped by series;
- chart/legend/table/controller selection parity;
- deterministic JSON, hydration, preview, and image capture;
- center fallback and runtime builder rebinding;
- keyboard order, semantics, reduced motion, and high contrast;
- one-series Donut regression goldens remain unchanged.
