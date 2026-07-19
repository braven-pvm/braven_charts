# Concentric Donut charts

Concentric Donut compares two or more independent part-to-whole distributions
in one radial pane. Every ring is an ordinary `DonutChartSeries` with its own
stable ID, categories, values, formatter, total, grouping, and styling.

Use Concentric Donut when the question is “how did the composition change
between these independent groups or periods?” It is not a hierarchy and it is
not a progress chart:

- use one `DonutChartSeries` for one total;
- use two or more `DonutChartSeries` values for independent totals;
- use Sunburst for parent/child partitions;
- use Radial Bar or Gauge when an arc means `value / maximum`.

[Open the live Concentric Donut showcase](https://braven-pvm.github.io/braven_charts/?page=concentric-donut)

## Quick start

```dart
final current = DonutChartSeries.fromMap(
  id: 'current',
  name: 'Current quarter',
  unit: 'k USD',
  values: const {
    'Direct': 58,
    'Partners': 27,
    'Expansion': 15,
  },
  dataLabels: const PieDataLabelConfig(isVisible: false),
);

final previous = DonutChartSeries.fromMap(
  id: 'previous',
  name: 'Previous quarter',
  unit: 'k USD',
  values: const {
    'Direct': 49,
    'Partners': 33,
    'Expansion': 18,
  },
  dataLabels: const PieDataLabelConfig(isVisible: false),
);

BravenChartPlus(
  series: [current, previous],
  showLegend: true,
  concentricDonutConfig: const ConcentricDonutConfig(
    innerRadiusFactor: 0.28,
    outerRadiusFactor: 0.92,
    ringGap: 6,
    order: ConcentricRingOrder.outerToInner,
    ringWeights: {'current': 1.25},
    legendMode: ConcentricDonutLegendMode.groupedByRing,
    centerContent: DonutCenterContent(
      label: 'Comparison',
      valueMode: DonutCenterValueMode.custom,
      customValue: '2 periods',
    ),
  ),
)
```

Two or more Donut series activate the Concentric Donut composition. There is
no separate `ConcentricDonutSeries`: the chart-level config allocates radial
bands while every series keeps its real Donut data contract.

## Independent totals

Each ring calculates shares against its own total. In the example above,
`Direct` is `58%` of the current ring and `49%` of the previous ring. Values
are never merged or normalized across rings.

Repeated category labels do not create a relationship. Durable identity is:

```dart
ChartPointRef(seriesId: 'previous', pointIndex: 0)
```

Use stable, unique series IDs. The source series order is the default legend,
table, and keyboard traversal order.

## Composition configuration

`ConcentricDonutConfig` owns only plot-level composition:

| Property | Meaning |
| --- | --- |
| `innerRadiusFactor` | Inner boundary of the complete composition, from `0` to less than `outerRadiusFactor` |
| `outerRadiusFactor` | Outer boundary of the complete composition, greater than `innerRadiusFactor` and at most `1` |
| `ringGap` | Logical pixels between neighboring ring bands |
| `order` | Whether the first source series is outside or inside |
| `ringWeights` | Relative band thickness keyed by stable series ID; omitted IDs use `1` |
| `legendMode` | Group items by ring or show one qualified flat sequence |
| `centerContent` | One portable text fallback for the complete composition |

Ring weights affect visual thickness only. They never change a series value,
total, share, source order, or selection identity.

The allocator preserves positive ring thickness in constrained layouts. When
necessary, it reduces the effective gap before allowing a band to collapse.
Invalid factors, negative gaps, unknown weight keys, non-positive weights, or
duplicate series IDs fail validation instead of being silently normalized.

## Per-ring styling

Each `DonutChartSeries` still owns its categories and normal Donut behavior:

- start angle, sweep, and clockwise direction;
- constant-width parallel-sided slice gaps, corners, borders, gradients,
  opacity, shadows, and shared
  `RadialSelectionStyle` selection presentation;
- labels, formatters, grouping, and optional variable-radius values;
- entrance and identity-aware data transition modes.

Inside labels use the midpoint of their allocated ring band as the Concentric
baseline. `PieDataLabelConfig.insideOffset: 0` therefore centers a label
between that ring's inner and outer edges; positive and negative offsets move
outward and inward from that midpoint. Pie and single-ring Donut keep their
established label anchors.

All rings must use the same sweep and clockwise direction so the chart does
not imply a comparison across incompatible angular frames. Ring placement is
owned by `ConcentricDonutConfig`; per-series `innerRadiusFactor` and
`radiusFactor` do not manually position a ring in a multi-ring composition.

The public showcase exposes these contracts as live testing controls. Its
Options rail covers chart theme and palette, derived or fixed linear/radial
gradient stops, opacity, border policy and fixed border color, corner
treatment, slice shadow, selected elevation, label collision and connectors,
callout and tooltip surfaces, legend layout and custom item widgets, motion,
grouping, and the composition-owned ring geometry. Changes are applied to the
mounted chart; the Chart/Data/Split/Source workbench continues to represent
that same runtime and can emit its effective Dart configuration.

## Center content

A Concentric Donut has one shared center. Configure its portable fallback on
`ConcentricDonutConfig.centerContent`, not on an individual ring:

```dart
const ConcentricDonutConfig(
  centerContent: DonutCenterContent(
    valueMode: DonutCenterValueMode.selectedOrTotal,
    labelStyle: LabelStyle(
      textStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
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
  ),
)
```

Leave the text color null to inherit a contrast-safe color from the active
`ChartTheme`. Supply a color in either `TextStyle` for an explicit override.
When `label` is omitted, selected modes use the selected category; the
unselected total remains a compact value-only center. `valueFormatter` owns
the complete numeric value string when the built-in total or selection modes
are used.

For runtime Flutter content, use `BravenChartPlus.donutCenterBuilder`. The
`DonutCenterData` value contains:

- `rings`: one `DonutCenterRingSummary` per independent series;
- `selectedSeriesId`, `selectedRingIndex`, and `selectedPointIndex`;
- selected category, value, share, and grouped source points;
- the measured center diameter and package theme styles.

```dart
donutCenterBuilder: (context, center) => Column(
  mainAxisSize: MainAxisSize.min,
  children: [
    Text(
      center.hasSelection ? center.selectedCategory! : 'All periods',
      style: center.defaultLabelStyle,
    ),
    Text(center.valueLabel, style: center.defaultValueStyle),
  ],
)
```

Those effective default styles already resolve portable overrides, the chart
font family, and light/dark/high-contrast colors. Use them directly or treat
them as a starting point with `copyWith`. The builder may return any Flutter
widget; Braven Charts still owns its circular bounds, semantics, and optional
center tap target.

Runtime builders and tap callbacks are not serialized. Rebind them after
hydration; the portable `centerContent` remains available in saved previews
and runtimes without application callbacks.

## Legends and labels

`ConcentricDonutLegendMode.groupedByRing` is the default. It gives every ring
an explicit heading and keeps repeated category names unambiguous.
`ConcentricDonutLegendMode.flat` qualifies every item with its ring identity.

`radialLegendItemBuilder` receives `RadialLegendItemData`. For Concentric
Donut, the data additionally includes `ringIndex`, `ringCount`,
`ringPositionLabel`, and `ringTotal`. Braven Charts retains the tap target,
selection action, focus behavior, and assistive semantics around custom
visible content.

Slice labels remain configured independently on each ring through
`PieDataLabelConfig`. Outside labels from every ring share one collision
layout, so an inner-ring label cannot unknowingly overlap an outer-ring label.
Each label still uses its owning series formatter, callout style, color, and
outside offset.

That independence supports a clear ring hierarchy. Configure the physical
outer ring with category/share callouts, and keep the inner ring compact with
category labels inside its sectors:

```dart
final outer = DonutChartSeries.fromMap(
  id: 'current',
  values: currentValues,
  dataLabels: const PieDataLabelConfig(
    position: PieDataLabelPosition.outside,
    content: PieDataLabelContent.categoryAndPercentage,
  ),
);

final inner = DonutChartSeries.fromMap(
  id: 'previous',
  values: previousValues,
  dataLabels: const PieDataLabelConfig(
    position: PieDataLabelPosition.inside,
    content: PieDataLabelContent.category,
  ),
);
```

Any ring can also opt into Pie's dual-label mode with `secondaryContent`.
When ring order is user-configurable, construct each ring's label policy from
its resolved physical position so “outer” callouts remain on the outer ring.

## Selection, tooltips, and controller access

Slice, legend, table, keyboard, and controller activation all converge on the
same `ChartPointRef`. Controller commands require the current effective
document revision:

```dart
final controller = BravenChartController();

final revision = controller.effectiveDocumentRevision.value!;
final result = controller.selectPoint(
  const ChartPointRef(seriesId: 'previous', pointIndex: 1),
  revision: revision,
);

final selected = controller.selectedPointRefs;
controller.clearPointSelection();
```

Grouped `Other` selection expands only to source points in the owning ring.
Tooltips and semantics include the physical ring position and series name, so
identically named categories remain distinguishable.

`RadialSelectionEffect.explode` keeps the established outward-offset behavior.
`RadialSelectionEffect.lift` scales the selected sector around its centroid,
adds an independent radial offset, paints its ring above every other ring, and
can blur the complete unselected composition to create depth. Ring allocation
does not change, so selection never makes neighboring rings resize or jump.

Keyboard traversal follows configured ring order, then source point order
inside each ring. Arrow keys move focus, Enter selects the focused slice, and
Escape clears selection.

## Native table, copy, CSV, and Source

The native projection includes ring identity before category data:

```text
Ring | Category | Value | Share | optional radius metric
```

Every share uses its owning ring total. The visible table shows the series
name when available. CSV export includes both `Ring` and stable `Series ID`.
Copy row, copy data, CSV export, focus, and selection use the original source
rows even when the visible chart groups small categories into `Other`.

Use `BravenChartWorkbench` for Chart, Data, resizable Split, and generated
Source views without creating a second chart instance:

```dart
BravenChartWorkbench(
  chartController: controller,
  availableDisplayModes: const {
    ChartDisplayMode.chart,
    ChartDisplayMode.data,
    ChartDisplayMode.split,
    ChartDisplayMode.source,
  },
  isSplitResizable: true,
  autoFitTablePane: true,
  sourceOptions: const ChartDartSourceOptions(
    variableName: 'concentricDonutChart',
  ),
  chartBuilder: (context, mountedController) => BravenChartPlus(
    bravenChartController: mountedController,
    series: [current, previous],
    concentricDonutConfig: config,
  ),
)
```

Generated Source includes every Donut series plus the exact
`ConcentricDonutConfig`: inner and outer factors, gap, ring order, sorted ring
weights, legend mode, and portable center content. Runtime-only center or
formatter callbacks remain explicit rebinding boundaries rather than being
silently omitted.

## Artifacts, previews, and hydration

A multi-ring document declares `series.donut.concentric.v1`. Every ring stays
an ordinary Donut series document, while `ConcentricDonutConfig` is stored in
the chart-level configuration.

```dart
final captured = await controller.extractArtifact(
  const ChartArtifactExtractOptions(
    artifactId: 'period-comparison',
    includePreview: true,
  ),
);
```

Extraction and hydration preserve ring order, weights, independent totals,
source point order, center fallback, formatter descriptors, selected point
references, and preview geometry. JSON encoding is deterministic. A runtime
that does not support the Concentric capability returns an unsupported
capability failure; it does not flatten the rings or restore only the first.

## Accessibility and responsive behavior

The chart exposes a Concentric Donut summary with ring and slice counts. Slice
semantics include ring position, series name, category, formatted value,
formatted within-ring share, slice ordinal, and selected state. Custom legend
and center widgets remain inside package-owned semantic and interaction
shells.

Selection does not reallocate ring bands. Compact layouts preserve positive
band thickness, include selected elevation in measurement, and coordinate
outside labels across rings. Reduced-motion and zero-duration themes render
the final geometry immediately.

## Product boundaries

- Two or more real `DonutChartSeries` values are required.
- Pie, Cartesian, polar-axis, hierarchy, and gauge series cannot mix into the
  same composition.
- Totals remain independent; there is no cross-ring stacking or inferred
  category alignment.
- There is one shared center and one selection model.
- Concentric Donut has no Cartesian axes, crosshair, pan, zoom, or scrollbar.
- Use a grouped bar chart when precise cross-period comparison matters more
  than the part-to-whole pattern.
