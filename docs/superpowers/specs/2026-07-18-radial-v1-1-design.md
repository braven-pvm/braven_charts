# Radial V1.1 design

## Scope

Radial V1.1 extends the existing single-series Pie and Donut implementation in
four dependency-ordered slices:

1. Donut center widget composition and center actions.
2. Shared radial numeric formatting for labels, center content, and radius
   metrics.
3. Explicit grouped-variable-radius aggregation.
4. Identity-keyed radial data transitions.

Hierarchical data, multiple concentric rings, drill-down, radial bars,
sunbursts, and polar-axis composition remain out of scope. Those features need
a separate chart-family discussion rather than additional flags on Pie or
Donut.

## 1. Donut center composition

`DonutCenterContent` remains the portable, text-first fallback stored in chart
documents and used by previews. `BravenChartPlus` gains runtime-only
`donutCenterBuilder` and `onDonutCenterTap` hooks. `HydratedChartConfiguration`
and `HydratedBravenChart` accept the same hooks so a host can rebind them after
hydration without serializing Dart callbacks.

The package owns:

- measurement against the actual Donut opening;
- circular clipping and safe padding;
- tap/focus semantics;
- the fallback text and accessible description;
- selection synchronization.

The builder owns only the visible widget inside that shell. Its immutable data
includes the series identity, total, resolved portable label/value, selected
slice and source points, share, unit, available diameter, effective text
styles, and semantic label.

When no builder is bound, the existing Canvas center text remains unchanged.
When a builder is bound, Canvas center painting and Canvas center semantics are
suppressed to prevent duplicate visuals and accessibility nodes.

## 2. Shared radial formatting

Radial formatting is component-based instead of replacing the complete label.
This preserves deterministic content assembly and accessibility while allowing
currency, units, localized percentages, and compact values.

The supported numeric slots are:

- primary slice value;
- share/percentage;
- optional radius metric;
- Donut center numeric value.

Runtime formatters use `String Function(double)`. Portable extraction accepts
one `ChartFormatterDescriptor` per series and slot. The series document stores
the descriptors and declares `series.radial.formatters.v1`. Hydration resolves
them through `ChartFormatterRegistry`; an unavailable formatter uses its safe
fallback and emits the existing `unregistered_formatter` warning.

Category labels remain source strings. `PieDataLabelContent` continues to
define which formatted components are assembled.

## 3. Grouping with variable radii

`RadialSliceGroupingConfig` gains an optional
`radiusAggregation` policy. Grouping without variable radii remains unchanged.
Combining grouping and variable radii requires a policy and declares
`series.radial.grouped-variable-radius.v1`.

Portable policies are:

- `sum` for additive second metrics;
- `mean` for an unweighted average;
- `weightedMean` using the primary contribution as weight;
- `minimum`;
- `maximum`.

The aggregate visible `Other` point carries the resolved radius value while
all original source rows, values, radii, point references, artifacts, and CSV
data remain intact. Tooltips and custom legend data expose the aggregate radius
metric.

## 4. Identity-keyed radial transitions

Entrance motion and data-update motion are separate lifecycles.

- Initial mount and explicit replay continue to use `PieAnimationMode`.
- Compatible data updates interpolate primary values and optional radius values
  through the normal geometry engine.
- Category identity is the unique category label. When labels repeat, exact
  `(label, x)` matching is used before index fallback.
- Insert/remove/reorder changes use a keyed structural cross-fade rather than
  collapsing the complete chart and replaying entrance motion.
- The incoming chart owns interaction and semantics during structural motion;
  the outgoing chart is paint-only.
- Reduced motion and zero-duration themes render the final chart immediately.

`RadialDataTransitionMode.none` disables data transitions.
`RadialDataTransitionMode.automatic` selects interpolation for compatible data
and a structural cross-fade otherwise.

## Acceptance gates

Each slice requires focused model, codec, rendering, interaction, hydration,
and showcase tests. Before review, run:

1. `dart format` on changed Dart files.
2. `flutter analyze lib`.
3. Focused radial unit/widget/golden tests.
4. Full package `flutter test`.
5. Example `flutter analyze` and `flutter test`.
6. `flutter build web --release` from `example`.
7. `dart pub publish --dry-run`.
8. Direct browser checks for Pie and Donut showcase routes.
9. `git diff --check`.

Keep the local web server available for product review. Do not commit or open a
PR until the user approves the local result.
