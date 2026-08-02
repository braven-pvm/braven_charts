# Chart grammar and the fluent surface

> ⚠️ **Beta / Work in progress.** The grammar-of-graphics and fluent authoring
> APIs are experimental and may change before a stable release. Pin a version if
> you depend on them.

Braven Charts has one configuration API — `BravenChartPlus` with
`ChartSeries`, `ChartAnnotation` and the config classes — and **two optional
authoring layers above it**. Both are additive: they change nothing about the
core API, and code that never imports them never sees them.

| Layer | What it is | Where it lives | How you get it |
| --- | --- | --- | --- |
| **Fluent modifiers** | Chained `withX` / `withoutX` / `inheritX` / `clearX` / `updateX` verbs generated over the existing config classes | `lib/src/fluent/generated/` (98 extensions, ~1160 verbs) | `import 'package:braven_charts/braven_charts_fluent.dart';` |
| **Chart grammar** | A typed grammar of graphics — data, marks, channels — that *lowers* onto those same config objects | `lib/src/grammar/` | already in `package:braven_charts/braven_charts.dart` |

They are independent. The fluent layer edits configs; the grammar describes a
chart and then produces configs. You can use either, both, or neither.

Showcase: **Chart Grammar** (`?page=chart-grammar`) — six presets authored
through the chained facade only, each inside the Chart / Data / Split / Source
workbench, with a "Compare hand-built" toggle. The *Reference lines* preset
exercises the V2.0 verbs (`.threshold` / `.grid` / `.title` / per-mark
markers) so its Grammar Source tab shows a chain, not a diagnostic.

---

## Layer 1 — the generated fluent surface

### The opt-in barrel

```dart
import 'package:braven_charts/braven_charts_fluent.dart';

final crosshair = const CrosshairConfig()
    .withMode(CrosshairMode.vertical)
    .withSnapRadius(24);
```

`braven_charts_fluent.dart` re-exports the whole core barrel plus every
generated extension, so the one import is enough.

**Why a separate barrel.** Dart extension methods are unconditional: an
extension that is in scope adds its members to *every* instance of the
extended type, including in autocomplete. Exporting ~1160 verbs from the core
barrel would push them onto every consumer of the package whether they wanted
chained modifiers or not, and would bury the constructors — which remain the
primary, complete way to build a config — under a wall of verbs. Keeping the
extensions behind their own barrel makes the surface a decision the consumer
makes once, per file.

The barrel itself is generated from the set of generated files, so a new
extension cannot go unexported. The generated files are checked in;
consumers never run `build_runner`. CI regenerates and fails on any diff.

### Verb vocabulary

Two different kinds of "unset" exist on this config surface, and one `clear`
verb would have meant opposite things in each, so they get distinct verbs:

| Verb | Applies to | Lowers to |
| --- | --- | --- |
| `withX(v)` | every modelled parameter | `copyWith(x: v)` |
| `withoutX()` | tri-state `ChartStyleValue` fields — SUPPRESS ("render nothing, do not inherit") | `copyWith(x: const ChartStyleValue<T>.none())` |
| `inheritX()` | tri-state `ChartStyleValue` fields — INHERIT (defer to the theme) | `copyWith(x: const ChartStyleValue<T>.inherit())` |
| `clearX()` | nullable parameters whose `copyWith` has a clear flag — UNSET ("back to the default") | `copyWith(clearX: true)` |
| `updateX(fn)` | non-nullable nested config parameters | `copyWith(x: fn(x))` |

The large nullable family owns the intuitive meaning of `clear`; tri-state
suppression is `without`. `withX` signatures always strip nullability, because
passing `null` through a `??`-merging `copyWith` is a silent no-op rather than
an unset. Nullable parameters whose `copyWith` cannot unset them say so in
their generated dartdoc instead of shipping a null-accepting verb.

`updateX` is what makes the layer worth importing at fleet scale — editing one
leaf without restating the enclosing config:

```dart
final interaction = const InteractionConfig()
    .updateCrosshair((c) => c.withMode(CrosshairMode.vertical))
    .updateTooltip((t) => t.withEnabled(false));
```

### What deliberately has no verb

Every chain step must produce a config that is valid *and* still connected to
the rest of the chart. Four kinds of parameter fail that test, so they are
force-excluded and documented as **construction-only**. This is the layer's
central rule: **construction is the complete path.** A constructor sees every
parameter at once and can assert across them; a mid-chain setter sees one.

- **Cross-object join keys.** `id` on every series and annotation class (as it
  already was on `YAxisConfig`). Series ids bind axes, annotations and
  artifact documents; annotation ids bind selection state. A mid-chain
  `withId` would detach the value from everything referencing it.
- **OHLC, as a unit.** `CandlestickDataPoint`'s `open`/`high`/`low`/`close` are
  assert-coupled, so no individual setter exists; they move together through
  one combined setter with required named parameters:
  `withOhlc(open: …, high: …, low: …, close: …)`. Two-member couples stay
  positional (`withRange(min, max)`); three or more take named parameters,
  because `withOhlc(1, 6, 0.5, 3)` is a tuple nobody can read at a call site.
- **Bar width.** `BarChartSeries.barWidthPercent` and `barWidthPixels` are
  coupled by an **OR**-shaped assert (`percent != null || pixels != null`) —
  the two are alternatives, not a pair. An AND-shaped `withBarWidth(a, b)`
  would be a verb whose arguments cannot both be honoured, and because
  `copyWith` merges with `??` and exposes no clear flag for these, no verb can
  select one alternative and retire the other. Set the width at construction.
- **`RangeAnnotation`'s four bounds.** Same OR shape: an `withBounds` that took
  all four silently converted an X-only band into a 2-D box.
- **Ordered, typed point lists.** `CandlestickChartSeries.points`,
  `RangeAreaChartSeries.points` and `PolarColumnChartSeries`' parallel
  category arrays. `copyWith` widens the element type to `ChartDataPoint`
  while the series requires its own point type *and* strictly increasing `x`,
  so `withPoints([...])` could only throw for anything the series would have
  rejected at construction.

`RangeAreaDataPoint`'s `low`/`high` follow the OHLC pattern rather than being
excluded: they are one value (`high >= low`) and move together through
`withInterval(low, high)`, which also keeps the inherited `y` midpoint
consistent. A gap has no verb — build one with `RangeAreaDataPoint.gap`.

Preset factories get no fluent surface either — Dart factories already chain,
because the extension applies to the factory's result:
`CrosshairConfig.tracking(...).withSnapRadius(12)` works today.

---

## Layer 2 — the chart grammar

The grammar describes a chart as **data + geometries + encodings**, and then
compiles ("lowers") that description onto the ordinary config API. The render
pipeline, artifact codecs, generated Source and the Workbench are untouched:
they receive exactly the objects they already understand and have no idea the
grammar exists.

### The chained facade

The facade is the way most code should author a spec:

```dart
BravenChart.of(rides)
    .x(rideMinute, label: 'Elapsed (min)')
    .yAxis(YAxisConfig(
      position: YAxisPosition.left,
      label: 'Power',
      unit: 'W',
    ).copyWith(id: 'watts'))
    .yAxis(YAxisConfig(
      position: YAxisPosition.right,
      label: 'Heart rate',
      unit: 'bpm',
    ).copyWith(id: 'bpm'))
    .geomArea(
      id: 'power',
      y: ridePower,
      name: 'Power',
      yAxisId: 'watts',
      color: const Color(0xFF2563EB),
      fillOpacity: 0.18,
    )
    .trend(method: TrendType.movingAverage, windowSize: 5, name: 'Trend')
    .geomLine(
      id: 'hr',
      y: rideHeartRate,
      name: 'Heart rate',
      yAxisId: 'bpm',
      color: const Color(0xFFDC2626),
    )
    .geomPoint(
      id: 'efforts',
      yAxisId: 'watts',
      size: const Channel<Ride>(rideEffort, label: 'Effort'),
      categoryBy: const CategoryChannel<Ride>(rideZone, label: 'Zone'),
      categories: zoneStyles,
    )
    .interaction(const InteractionConfig(
      crosshair: CrosshairConfig(displayMode: CrosshairDisplayMode.tracking),
    ))
    .build()
```

Properties of the facade worth knowing:

- **It is a spec builder and nothing else.** `toSpec()` hands back the same
  `PlotSpec` you could have typed by hand; `build()` wraps that spec in a
  `BravenPlot`. There is exactly one description of what each verb means, and
  the lowering parity suite therefore covers the facade for free.
- **Every verb returns a new builder.** A chain can be branched — one shared
  base, two geometries on top — and a builder held in a field cannot be
  mutated by a caller who chains off it.
- **It fails at the offending call, not at `build()`.** A `geom*` with no
  accessor to use throws `GrammarSpecException` with
  `GrammarDiagnosticCode.missingEncoding` right there, naming the verb and the
  channel; a `trend()` with nothing to fit throws `unknownTrendSource` at its
  own call. The stack trace points at the line that is wrong.

### Accessors compare by identity

Encodings are ordinary Dart functions (`typedef FieldAccessor<T, V> = V
Function(T row)`). `Mark`, `Channel` and `PlotSpec` all have **value
equality**, but a closure compares by *identity* — so `(row) => row.power`
written twice produces two marks that are not equal. Use top-level functions
or static methods as tear-offs. They are constant expressions, which also
makes marks `const`-constructible.

### The typed spec

`PlotSpec<T>` is declarative and inert:

```dart
PlotSpec<Ride>(
  data: rides,
  marks: <Mark<Ride>>[
    LineMark<Ride>(x: rideMinute, y: ridePower, id: 'power'),
    TrendMark<Ride>(sourceMarkId: 'power'),
  ],
  yAxes: <YAxisConfig>[YAxisConfig(position: YAxisPosition.left, label: 'W')],
)
```

`Mark<T>` is a **sealed** hierarchy, so a `switch` that misses a variant does
not compile — every dispatch site is checked when a variant is added. The table
below is the **Cartesian** half of that hierarchy; the sealed `RadialMark<T>`
subtree — `PieMark<T>`, `DonutMark<T>` and `PolarMark<T>` — lowers to the radial
series families and is covered under [Radial geometries](#radial-geometries). A
spec holds one half or the other, never both (`mixedCoordinateSystems`). Within
the Cartesian half the first six lower to a series and the last four to
annotations:

| Mark | Lowers to |
| --- | --- |
| `LineMark<T>` | `LineChartSeries` |
| `AreaMark<T>` | `AreaChartSeries` |
| `BarMark<T>` | `BarChartSeries` |
| `ScatterMark<T>` | `ScatterChartSeries` |
| `CandlestickMark<T>` | `CandlestickChartSeries` |
| `RangeAreaMark<T>` *(V2.0)* | `RangeAreaChartSeries` — see [Bands](#bands-geomrangearea) |
| `TrendMark<T>` | `TrendAnnotation` bound to its source series |
| `ThresholdMark<T>` *(V2.0)* | `ThresholdAnnotation` — a reference line at a value |
| `BandMark<T>` *(V2.0)* | `RangeAnnotation` — a 1-D shaded band |
| `PointMark<T>` *(V2.0)* | `PointAnnotation` — a marker on one series' point |

Like `TrendMark`, the three V2.0 reference marks produce no geometry of their
own — they append an annotation — and carry no `copyWith`.

**Channels exist only where they can be honoured.** `Channel<T>` (quantitative)
and `CategoryChannel<T>` (categorical) are constructor parameters of
`ScatterMark`; `geomBar`, `geomLine` and `geomArea` additionally carry a
`colorBy` colour channel and `geomBar` a `sizeBy` width channel, baked at
lowering, while `size`, `opacityBy` and `categoryBy` remain scatter-only. The
coordinate × geometry validity matrix is therefore a compile-time property, not
a runtime throw.

A channel says *which field to read*; the matching `Scatter*Encoding` says how
the scale is configured:

| Channel | Template | Required? |
| --- | --- | --- |
| `size` | `sizeEncoding` | optional — defaults to `ScatterSizeEncoding()` |
| `opacityBy` | `opacityEncoding` | optional — defaults to `ScatterOpacityEncoding()` |
| `colorBy` | `colorEncoding` | **required** — no default colour ramp exists |
| `categoryBy` | `categories` | **required** — no categorical palette exists |

A channel without its required template raises `missingChannelEncoding` rather
than inventing design surface the rest of the library does not have. Each
channel also has exactly one scale the renderer implements — `size` → `sqrt`
(marker *area* is proportional to the value, the perceptually correct
mapping), `colorBy` and `opacityBy` → `linear`. Leaving `Channel.scale` null
selects it; naming the other one raises `unsupportedChannelScale` instead of
silently rendering a different mapping than the one that was asked for.

### Marks have no `copyWith`

This is a decision, not an omission. The package's surface enforcement
(`test/meta/surface_enforcement_test.dart`) reads "instantiable, public, has a
`copyWith`" as "must carry `@chartSurface`" — so a `copyWith` on `LineMark`
would generate a fluent verb surface *over the grammar layer*, giving
`LineMark.withStrokeWidth` sitting beside `LineChartSeries.withStrokeWidth`: a
second vocabulary for the same objects. Marks are small. Modify one by
constructing a new one, or author through the chained facade. The same
reasoning covers `PlotSpec`, `Channel`, `CategoryChannel` and `LoweredPlot`.

### V2.0 verbs — reference marks, chart-level options, per-mark markers

Three additions in V2.0 let the grammar author — *and* round-trip-emit — the
three most common charts V1 could only diagnose. None changes the render
pipeline or a config class; each is a mark/`PlotSpec` field that lowers onto
config the pipeline already understood.

**Reference annotation marks.** Non-trend annotations now have chain verbs.
Each appends a mark that lowers to an annotation, not a series:

```dart
// A reference line at a value on one axis → ThresholdAnnotation.
BravenChart<T> threshold({
  required double value,
  AnnotationAxis axis = AnnotationAxis.y,
  String? id, String? label, Color? color,
  double? strokeWidth, List<double>? dashPattern,
});

// A 1-D shaded band between two values on one axis → RangeAnnotation
// (an X band or a Y band, never a 2-D box).
BravenChart<T> band({
  required double start,
  required double end,
  AnnotationAxis axis = AnnotationAxis.y,
  String? id, String? label, Color? color,
});

// A marker on one existing series' data point → PointAnnotation.
// This is NOT the scatter geometry: it annotates ONE point of a geometry
// already in the chain.
BravenChart<T> pointAt({
  required String seriesId,
  required int dataPointIndex,
  String? id, String? label, Color? color,
  double? markerSize, MarkerShape? markerShape,
});
```

**Chart-level options.** `PlotSpec` now carries a grid, a title/subtitle and
legend visibility, and `BravenPlot` forwards them to `BravenChartPlus`. A
`null` grid or `showLegend` reproduces the chart default (`const GridConfig()`
and a shown legend), so a V1 spec is unchanged:

```dart
BravenChart<T> grid(GridConfig grid);
BravenChart<T> title(String title, {String? subtitle});
BravenChart<T> legend(bool show);
```

**Per-mark data-point markers and inline labels.** `geomLine` and `geomArea`
gained `showDataPointMarkers` and `dataPointLabels`; `geomBar` gained
`labelStyle` (a bar is its own mark, so it has no per-point marker toggle).
Each defaults to unset and lowers to the matching `ChartSeries` field:

```dart
// on geomLine / geomArea:
bool? showDataPointMarkers,          // → *ChartSeries.showDataPointMarkers
DataPointLabelConfig? dataPointLabels, // → *ChartSeries.dataPointLabels
// on geomBar:
BarLabelStyle? labelStyle,           // → BarChartSeries.labelStyle
```

#### Bands: `geomRangeArea`

A filled band between paired bounds, lowering to `RangeAreaChartSeries`. It sits
beside `geomCandlestick` as the second Cartesian geometry with **no single `y`**:

```dart
BravenChart<T> geomRangeArea({
  required FieldAccessor<T, num?> low,
  required FieldAccessor<T, num?> high,
  FieldAccessor<T, num>? x,            // defaults to the chart-wide .x
  String? id, String? name, Color? color, String? unit, String? yAxisId,
  FieldAccessor<T, String?>? label,
  FieldAccessor<T, String?>? pointKey,
  // Every styling argument left null keeps the RangeAreaChartSeries default:
  LineInterpolation? interpolation, double? tension, double? fillOpacity,
  RangeAreaBorderMode? borderMode,
  RangeAreaBoundaryStyle? upperBoundaryStyle,
  RangeAreaBoundaryStyle? lowerBoundaryStyle,
  bool? connectGaps, bool? showBoundaryMarkers, double? markerRadius,
  RangeAreaLabelConfig? labelConfig,
  RangeAreaHitTestMode? hitTestMode,
});
```

- **`low` and `high` are NULLABLE accessors**, unlike every other Cartesian
  encoding. `RangeAreaDataPoint.gap` is a real point with no interval, and a
  total `FieldAccessor<T, num>` cannot express one. Returning null from **both**
  at a row lowers it to `RangeAreaDataPoint.gap`; returning null from exactly
  **one** raises `incompleteRangeAreaInterval` naming the row, because a
  half-specified interval has no defensible reading. This mirrors
  `PolarMark.intervalLow` / `intervalHigh`.
- **A band's rows must be strictly increasing in `x`, and `high >= low`.** Those
  are `RangeAreaChartSeries`' own invariants; the lowering translates its raw
  `ArgumentError`s into `invalidRangeAreaRow` naming the offending row, exactly
  as `geomCandlestick` does with `invalidCandlestickRow`.
- **No channels.** Deliberate: the range-area painter reads no per-point colour
  — it paints from the series colour, `fillOpacity`, the two boundary styles and
  the theme — so a `colorBy` or size channel would be accepted and then ignored.
- **`pathAnimation` and `fillGradient` are not carried**, matching `AreaMark`;
  both are deferred to the same roadmap item that fixes them for every Cartesian
  family at once. A captured band using either is refused **by name** rather than
  emitted without it. `isXOrdered` is absent because `RangeAreaChartSeries`
  hard-codes it `true` in its constructor, exactly as `CandlestickChartSeries`
  does, so a knob would be a lie.

#### Radial geometries

Pie, donut, concentric donut and polar column are grammar geometries, not a
config-only corner. A radial spec holds radial marks *only* — mixing one with a
Cartesian mark is `mixedCoordinateSystems`, and Cartesian options (`transposed`
/ `xAxis` / `yAxes` / `grid`) on a radial spec are `axisOptionOnRadialSpec`:

```dart
BravenChart<T> geomPie({required category, required value, ...});

// `ring:` turns a donut into a CONCENTRIC composition — one series per ring
// key, each ring computing its shares against its own total. `concentric:`
// carries the whole ConcentricDonutConfig (radii, ring gap, order, weights,
// legend mode and the center); `center:` is the shorthand for the center
// alone, and a mark that sets both is refused by name
// (`conflictingConcentricCenter`).
BravenChart<T> geomDonut({
  required category, required value,
  FieldAccessor<T, Object?>? ring,
  DonutCenterContent? center,
  ConcentricDonutConfig? concentric,
  ...
});

// Polar is the ONE radial family that may appear several times in a spec: a
// layered / grouped / stacked composition is N series over one category
// domain, so it is N marks. `rose: true` selects the area-correct preset, and
// the four per-category channels are nullable — a category with no target
// draws no marker, which a synthesised 0 would not preserve.
BravenChart<T> geomPolar({
  required category, required value,
  bool rose = false,
  FieldAccessor<T, Color?>? columnColor,
  FieldAccessor<T, num?>? target,
  PolarColumnTargetMarkerStyle? targetMarkerStyle,
  FieldAccessor<T, num?>? intervalLow,
  FieldAccessor<T, num?>? intervalHigh,
  PolarColumnIntervalStyle? intervalStyle,
  ...
});

// The plot-level polar configuration — pane, angular/radial axes, the
// composition mode and thresholds — is ONE object shared by the N marks, so it
// lives on the spec. Setting it without a polar mark is
// `polarConfigOnNonPolarSpec`.
BravenChart<T> polarConfig(PolarChartConfig config);
```

### Rendering: `BravenPlot`

```dart
BravenPlot<Ride>(spec, bravenChartController: controller)
```

`BravenPlot` is a thin, stateless adapter. It lowers the spec and hands the
resulting series, annotations and axis configs to `BravenChartPlus`. It owns
no rendering, no interaction and no state of its own.

It deliberately exposes **no widget-level `yAxis`**: the lowering attaches both
`yAxisId` and `yAxisConfig` to every series, which is what selects the
multi-axis path. Passing a widget-level `yAxis` would re-enter the legacy
single-axis path and silently change how the chart scales.

---

## Lowering

```dart
final lowered = spec.lower();   // LoweredPlot
```

`lower()` is an **extension method** — `extension PlotSpecLowering<T> on
PlotSpec<T>` — not a top-level function. There is no `lower<T>(spec)`: the
package does not export a bare generic verb into a host's namespace.

`LoweredPlot` carries `series`, `annotations`, `xAxis`, `yAxes`, `interaction`
and `theme`, all ordinary members of the existing config API.

### Ids

- A mark without an explicit `id` becomes **`mark-<index>`**, using its
  position in `PlotSpec.marks` and counting trend marks. That id becomes the
  series (or annotation) id, which is what axes, annotations and artifact
  documents bind to — so it is deterministic rather than generated, and a
  hand-written equivalent can spell it out.
- An axis with an empty id becomes **`axis-<index>`**. An empty `yAxes` list
  becomes one default left axis, `axis-0`.
- Every series carries **both** `yAxisId` and the matching `yAxisConfig`. That
  pair is what activates the multi-axis path; the legacy single-axis path is
  never targeted.

Explicit axis ids are set the production way, with
`YAxisConfig(...).copyWith(id: 'watts')` — `YAxisConfig.withId` is
`@visibleForTesting`.

### Axis labels: `.x` / `.y` vs an explicit axis

`.x(accessor, label: …)` and `.y(accessor, label: …)` are a shorthand for the
common single-axis case: the label names the axis **only when the chain
configures none explicitly**.

- `.x(…, label: 'Elapsed')` with no `.xAxis(…)` → `XAxisConfig(label: 'Elapsed')`.
- `.x(…, label: 'Elapsed').xAxis(const XAxisConfig(label: 'Time', unit: 's'))`
  → the explicit config wins, verbatim.
- `.y(…, label: 'Power')` with no `.yAxis(…)` → one left axis labelled `Power`.
- Any `.yAxis(…)` declaration suppresses the `.y` label entirely; declaration
  order is axis order, and marks bind to slots through `yAxisId`.

**Explicit configuration always wins.** The shorthand never merges into it.

### Validation order

`lower()` is total and fail-fast, and the order is fixed so a spec with
several problems always reports the same one first. Every **data-independent**
check runs *above* the `emptyData` guard, so an authoring error still surfaces
against a momentarily-empty dataset — which is exactly what lets `BravenPlot`
swallow `emptyData` alone and render an empty state (see *Empty data is a
state* below).

Shared prologue:

1. a faceted spec handed to `lower()` → `facetedSpecNotLowerable`
2. empty `marks` → `emptyMarks`
3. mark ids (duplicates) → `duplicateMarkId`
4. `.polarConfig(...)` on a spec holding no radial mark →
   `polarConfigOnNonPolarSpec`

A radial spec then branches (below). A **Cartesian** spec continues:

5. axis ids (duplicates) → `duplicateAxisId`
6. a time/log x axis that also declares category slots → `conflictingAxisMode`
7. transposition → `unsupportedTransposition`
8. each mark, in spec order → `unknownAxisId`, `unknownTrendSource`,
   `invalidTrendWindow`, `missingChannelEncoding`, `orphanChannelEncoding`,
   `unsupportedChannelScale`
9. unbound axes → `unboundAxis`
10. empty `data` → `emptyData`
11. materialization, per row → `invalidCandlestickRow`, `nonPositiveLogValue`

A **radial** spec continues instead:

5. several radial marks that are not all `geomPolar` → `multipleRadialGeoms`
6. any non-radial mark alongside them → `mixedCoordinateSystems`
7. `transposed` / `xAxis` / `yAxes` / `grid` → `axisOptionOnRadialSpec`
8. `.polarConfig(...)` on a pie/donut spec → `polarConfigOnNonPolarSpec`
9. `geomDonut` setting both `concentric` and `center` →
   `conflictingConcentricCenter`
10. `concentric:` with no `ring:` → `concentricConfigOnRinglessDonut`; then the
    config-only half of the concentric contract (pane radii, ring gap, ring
    weight magnitudes) → `invalidConcentricComposition`
11. a non-empty `dataLabelsByRing:` with no `ring:`, then a non-empty
    `ringIds:` with no `ring:` → `perRingOverrideOnRinglessDonut` (an EMPTY map
    is a no-op, here and on the ringed path)
12. the shape-decidable half of the polar composition contract, in this fixed
    order: the config-only half — everything `PolarChartConfig.validate()`
    enforces, i.e. pane geometry, radial-axis bounds, the grouped sub-band
    padding, per-threshold finiteness and dash-pair parity, and the stacked
    zero baseline → `invalidPolarComposition`; clashing mark units →
    `invalidPolarComposition`; a grouped/stacked mode with fewer than two
    `geomPolar` marks → `invalidPolarComposition`; exactly one of
    `intervalLow`/`intervalHigh` → `incompletePolarInterval`; clashing `rose`
    presets → `invalidPolarComposition`
13. empty `data` → `emptyData`
14. every radial mark whose rows carry no visible category →
    `emptyRadialCategories`
15. then, per family. The ring-map guards read the BUCKET KEYS, so they run as
    soon as the rows are partitioned and BEFORE any ring series is built — a
    chart that is wrong both ways reports the mis-keyed map, not the rows:
    - **concentric donut** (`geomDonut` with `ring:`): bucket the rows by ring;
      a `dataLabelsByRing:` and then a `ringIds:` key naming a ring the rows
      never produce → `unknownRingKey`; a `ringIds:` that names only SOME of
      the rings the rows produce → `partialRingIds`; then ring materialization
      → `duplicateRadialCategory`; then the row-dependent half of the
      concentric contract (ring weights and ids against the ids the rings
      actually lowered to) → `invalidConcentricComposition`
    - **polar**: column materialization → `duplicateRadialCategory`; then the
      row-dependent half of the polar contract → `invalidPolarComposition`
    - **pie / ring-less donut**: materialization → `duplicateRadialCategory`

`facetedRadialUnsupported` is raised earlier still, by `BravenFacetPlot`: a
radial spec cannot be faceted at all.

Every diagnostic carries a machine-readable `GrammarDiagnosticCode` alongside
its sentence, so a facade or a tool can react without string matching.

Three rules worth calling out:

- **`transposed: true` requires an all-`BarMark` spec.** Transposition is
  implemented in this package by horizontal bar geometry, which transposes the
  whole plane. A mixed spec would render some geometries rotated and others
  not, so it raises `unsupportedTransposition`. Bars therefore carry no
  orientation of their own; transposition is a whole-chart operation, spelled
  `.transposed()` on the chain.
- **Non-finite values pass through** for line/area/bar/scatter.
  `ChartDataPoint` documents NaN/infinite coordinates and exposes `isValid`,
  the pipeline already skips invalid points, and that *is* how a gap in a line
  is expressed — rejecting them would make the grammar stricter than the API
  it lowers onto. Candlesticks and range-area bands are the exceptions, because
  `CandlestickDataPoint` and `RangeAreaDataPoint` reject them themselves: those
  rows raise `invalidCandlestickRow` / `invalidRangeAreaRow` with the row index
  instead of leaking an `ArgumentError` from deeper in the pipeline.
- **A candle is a unit.** `geomCandlestick` requires `open`, `high`, `low` and
  `close` together; there is no per-channel candlestick geometry to compose,
  and rows must be strictly ordered on x.
- **A band is a unit too, but its gap is a row shape.** `geomRangeArea` requires
  `low` and `high` together, and rows must be strictly ordered on x. Unlike a
  candle, its bounds are *nullable*: both null is a gap
  (`RangeAreaDataPoint.gap`), exactly one null raises
  `incompleteRangeAreaInterval`. See
  [Bands: `geomRangeArea`](#bands-geomrangearea).

### Empty data is a state, not a mistake

An empty `data` list is a runtime *state* — a filter cleared, a fetch returned
nothing — so it must not throw out of a widget's `build`. `BravenPlot`
therefore handles exactly `GrammarDiagnosticCode.emptyData` by building the
chart with no series, which is how every other entry point in this package
reaches the standard empty state; configure the presentation through
`emptyStateConfig`.

Every *other* diagnostic — an empty `marks` list, an unknown trend source, a
channel without its encoding — is an authoring mistake and still surfaces from
`build`. Calling `spec.lower()` directly always throws on empty data; it is
the widget that has an empty-state contract, not the lowering.

---

## The lowering guarantee

> A spec-built chart and the hand-written chart it lowers to **are the same
> chart**.

That is enforced at two levels, and both are load-bearing test suites rather
than prose:

| Evidence | What it asserts |
| --- | --- |
| `test/unit/grammar/plot_lowering_parity_test.dart` | The lowered `ChartSeries`, `ChartAnnotation`s and axis configs are **equal** to the hand-written ones, per shape. |
| `test/widgets/braven_plot_artifact_parity_test.dart` | Mounting both charts and extracting a chart document through the ordinary `BravenChartController.extractDocument` path produces **identical JSON**, across all six shapes. |

Because a chart *document* is what feeds transport, hydration, the native data
table, generated Dart Source, comparison and the AI surface, artifact-document
equality means **nothing downstream can tell a spec-built chart from a
hand-built one**. No id normalization is needed in that suite: the lowering's
`mark-<index>` / `axis-<index>` ids are deterministic and the hand-built
charts spell those same ids out. If that stops being true, the suite goes red
— a feature, not a nuisance.

The Chart Grammar showcase page demonstrates the same thing interactively: the
Source tab renders ordinary `BravenChartPlus` Dart with real `ChartSeries`
constructions and no trace of the spec, and the "Compare hand-built" toggle
swaps the widget without changing the picture.

---

## Grammar source emission

The Workbench Source pane reads one chart in **two forms**, chosen with the
`Config` / `Grammar` toggle:

| Form | What it writes | Generator |
| --- | --- | --- |
| **Config** | The `BravenChartPlus` this chart *is* | `ChartDartSourceGenerator` |
| **Grammar** | A `BravenChart.of(rows)…` chain that *rebuilds* it | `ChartGrammarSourceGenerator` |

Both read the **same captured chart document**, so switching form never
re-extracts the chart — the pane re-emits from the snapshot it already holds,
and "stale" keeps meaning "the chart moved on since this snapshot". Both
render through `ChartCodeBlock`, and the config form keeps its original
`chart-source-code` / `chart-source-dark-window` keys unchanged.

The toggle is a **package** feature, not a showcase one: every
`BravenChartWorkbench` consumer gets both forms on every chart.
`grammarSourceOptions` names what the chain is called
(`ChartGrammarSourceOptions(variableName:, rowClassName:, rowsVariableName:)`),
and `initialSourceForm` chooses which form the pane opens on.

### The synthesised row type — the caveat that matters

A chart document stores **materialised points per series**. The grammar takes
the opposite shape: **one row list plus one total accessor per channel**. The
two cannot be bridged by renaming fields, so the generator **synthesises a row
class**:

```dart
class GrammarRow {
  const GrammarRow({
    required this.x,
    required this.power,
    required this.heartRate,
  });

  final double x;
  final double power;
  final double heartRate;
}

final List<GrammarRow> rows = <GrammarRow>[
  GrammarRow(x: 0.0, power: 168.0, heartRate: 112.0),
  // …
];

final chart = BravenChart.of(rows)
    .x((row) => row.x, label: 'Elapsed')
    .yAxis(YAxisConfig.withId(id: 'watts', position: YAxisPosition.left, …))
    .yAxis(YAxisConfig.withId(id: 'bpm', position: YAxisPosition.right, …))
    .geomArea(id: 'power', y: (row) => row.power, name: 'Power', …)
    .geomLine(id: 'hr', y: (row) => row.heartRate, name: 'Heart rate', …)
    .theme(ChartTheme.light)
    .build();
```

Field names derive from each series' `name` (falling back to its `id`),
lower-camel-cased into a valid, non-keyword Dart identifier and de-duplicated
with a numeric suffix. A candlestick series contributes
`<base>Open` / `<base>High` / `<base>Low` / `<base>Close` (plus
`<base>Timestamp` when its candles carry one); a scatter series contributes
`<base>Size` / `<base>Color` / `<base>Opacity` / `<base>Category` for whichever
channels it populates.

**`GrammarRow` is not — and can never be — your row type.** A document keeps
the numbers a chart was built from, never the objects they were read out of.
That is the honest limit of this direction. The Chart Grammar showcase page
surfaces the generated chain through the workbench Source tab's Grammar form,
whose synthesised `GrammarRow` stands in for the author's own type — and that
substitution is exactly the contrast that makes the limit visible.

Every synthesised field is **non-nullable and required**. That follows from the
x-alignment rule below rather than being a style choice: accessors are
`num Function(T)`, so they are total, so a field that has no value at some row
cannot exist.

### The x-alignment rule

**Every series must have exactly one point at every x of one shared, ordered
domain**, compared element-wise for equality against the first series.

`BravenChart.of(rows)` hands *every* mark the same rows and reads each through
a total accessor. A "union of x values with nullable fields" form is therefore
not expressible: if a series has no point at some x, its accessor still has to
return a `num`, and inventing one would draw a chart the document does not
describe. Anything else is diagnosed, naming the series that disagree. (`NaN`
never compares equal, so a non-finite x — the way a gap is expressed — is
diagnosed rather than silently treated as a shared row key.)

### Fidelity: the round-trip proof

Before emitting anything, the generator **builds the spec it is about to
write**, lowers it with the real `PlotSpecLowering`, and compares the resulting
`ChartSeries`, `ChartAnnotation`s and axis configs to the ones the document
hydrated to. So *"a chain was emitted"* already means *"this chain rebuilds
this chart"* — the emitter never has to enumerate every option a V1 mark
happens not to carry.

### Fidelity matrix

A chain that renders a **different** chart is worse than no chain, so nothing
is degraded silently. Each unsupported case emits a **named diagnostic and no
code**, in the same comment-header style the config emitter uses for
runtime-only bindings.

| Case | Outcome |
| --- | --- |
| A radial family — pie, donut, concentric donut or polar column | **EMITTED** *(V2.0)* as `geomPie` / `geomDonut(ring:)` / `geomPolar`, carrying the series style, unit, selection and slice configs. A layered/grouped/stacked polar composition emits **one `geomPolar` per series** over a shared category field; a customised `PolarChartConfig` emits as `.polarConfig(...)` and a non-default `ConcentricDonutConfig` as `geomDonut(concentric: ...)`. Narrowed by the **Blocked** radial rows that follow — read them together before reading this row as "every radial chart emits". |
| A radial family with no grammar geometry — radial bar, gauge | **Blocked**, naming each series and its family: no mark reverses it. |
| A range-area band | **EMITTED** *(V2.0)* as `geomRangeArea(low:, high:)`, carrying the interval bounds, the per-point label and key, and the range-area-native styling (interpolation, tension, fill opacity, border mode, both boundary styles, gap connection, boundary markers, marker radius, label config and hit-test mode). A gap row travels as two `null` bounds and comes back a gap. A band carrying `fillGradient` or `pathAnimation` is **Blocked** naming that field — the mark does not carry either, matching `AreaMark`. |
| A concentric composition whose ring series ids do not follow `'<markId>-<ring>'` | **EMITTED** *(V2.0)* as `geomDonut(ringIds: {...})` — an explicit ring-key→series-id map, so a composition that chose its ids independently of its ring names keeps them. The emitter consults it **only when the `'<markId>-<ring>'` pattern fails** to recover a markId, so a conforming composition takes the original path and emits exactly the text it emitted before. The map is keyed by the BARE ring key and is ALL OR NOTHING: naming some rings and not others raises `partialRingIds`, a key naming no ring raises `unknownRingKey`, and a non-empty map with no `ring:` raises `perRingOverrideOnRinglessDonut`. |
| A concentric composition whose rings are **unnamed or share a name** | **Blocked**, naming each series and its name: the ring key *is* the series name, so no `ring:` channel could bucket those rows apart — every row would fall into one ring. |
| A pie or donut carrying **per-slice colours** (`sliceColors`, i.e. a per-point `PointStyle.color`) | **EMITTED** *(V2.0)* as a `sliceColor:` row channel. `PieMark`/`DonutMark` carry one of their own, mirroring `PolarMark.columnColor`; a concentric composition resolves it **per ring bucket**, so the same category may take a different colour in each ring. |
| A donut **centre** setting `labelStyle` or `valueStyle` | **EMITTED** *(V2.0)* as `center: DonutCenterContent(...)`. `DonutMark.center` carries the captured centre VERBATIM, and the argument is written by the same renderer the config form's `centerContent:` uses, so both styles survive. |
| A donut **centre** setting `valueFormatter` | **Emitted with a `// valueFormatter:` placeholder and a warning** (`isComplete == false`), exactly as every other runtime callback is — a live closure has no literal form. |
| A concentric composition whose rings carry **different `dataLabels`** | **EMITTED** *(V2.0)* as `geomDonut(dataLabelsByRing: {...})`. Ring 0's config is the base the mark's `dataLabels:` carries, and only the rings that DIFFER from it are projected into the override map — so a uniform composition emits exactly what it did before. Inside the map an entry equal to the family default is a real override and IS written, unlike the single `dataLabels:` argument which elides one. The map is keyed by the BARE ring key; a key naming no ring raises `unknownRingKey`, and a non-empty map with no `ring:` raises `perRingOverrideOnRinglessDonut`. A per-ring `valueFormatter` emits a `// valueFormatter:` placeholder and a warning naming the ring (`isComplete == false`). |
| Polar series whose category domains differ | **Blocked**, naming the series that disagree: N `geomPolar` marks read ONE row list, so every polar series needs one value at every category of the shared domain, in the same order. |
| Series whose x domains differ | **Blocked**, naming the series that set the domain and the ones that disagree. |
| A partially populated scatter channel | **Blocked**, naming the channel and the populated/total counts: a `Channel` accessor is total. |
| Mixed bar orientations | **Blocked**: `.transposed()` is a whole-chart operation, so a transposed chain may contain horizontal bar marks only. |
| A `TrendAnnotation`, `ThresholdAnnotation`, a clean 1-D `RangeAnnotation` or a `PointAnnotation` | **EMITTED** *(V2.0)* as `.trend(of:)` / `.threshold(...)` / `.band(...)` / `.pointAt(...)` — the reference-mark verbs. |
| Any OTHER annotation (text, pin, chord, error-bar, legend), a 2-D or half-open range, or ANY series-level annotation | **Blocked and LISTED**, never dropped. |
| A grid, a title/subtitle, or a legend toggle | **EMITTED** *(V2.0)* as `.grid(...)` / `.title(...)` / `.legend(...)`. `PlotSpec` now carries them and `BravenPlot` forwards them; a *default* grid or a shown legend carries nothing, reproducing the chart default. A subtitle with **no** title is the one gated corner — the verb only attaches a subtitle to a title. |
| A chart-level option `BravenPlot` still does not forward — `legendStyle`, `showToolbar`, `interactiveAnnotations`, `maxAxesPerSide`, `axisSwapMode`, `normalizationMode`, width/height, background | **Blocked**, naming each one. `BravenPlot` passes series, annotations, the X axis, interaction, the theme, and now the grid, title, subtitle and legend visibility. |
| Anything else the reconstructed chain would not reproduce exactly | **Blocked** by the round-trip proof, naming the series, annotation or axis that differs — and, where it can be pinned down cheaply, the specific option a V1 mark cannot carry (e.g. a fill gradient, a curve tension, an inline series label — `showDataPointMarkers` and inline data-point labels are **carried** as of V2.0) or the single-axis binding a config-authored chart leaves implicit. |
| A runtime interaction binding | **Emitted with a warning**, exactly as the config form does. |
| Data above `maxInlinePoints` | **Emitted with a placeholder row list and a warning**, exactly as the config form does. |
| A host-owned theme reference | **Emitted without `.theme(...)`**, with a warning naming the reference. |

`test/unit/source/chart_grammar_source_generator_test.dart` is the evidence:
seven shapes (single line, shared-x multi-series, multi-axis, scatter with
channels, candlestick, transposed bars, trend) each **compile** through
`dart format` + `dart analyze` and each **rebuild a document equal to the
original**, and one test per matrix row asserts the diagnostic text.

### Sharing one emitter

The chain hands the same `XAxisConfig`, `YAxisConfig`, `ChartTheme`,
`InteractionConfig` and scatter encodings to its verbs that `BravenChartPlus`
takes. Rather than fork a second set of literal writers that would drift, the
config emitter lives in a non-exported `chart_config_dart_emitter.dart` and
exposes a narrow seam of **field-level** writers (never the enclosing
`name: Type(` header, which differs between the forms). Its own output is
unchanged.

---

## Added in V2.0

Several families of authoring — the charts V1 could only diagnose — now
round-trip. Each is a `Mark`/`PlotSpec` field lowering onto config the pipeline
already understood (details under *V2.0 verbs* above):

- **Non-trend reference annotation marks.** `.threshold(value:)`,
  `.band(start:, end:)` and `.pointAt(seriesId:, dataPointIndex:)` lower to
  `ThresholdAnnotation` / `RangeAnnotation` / `PointAnnotation`.
- **Chart-level grid, title/subtitle and legend.** `.grid(...)`, `.title(...)`
  and `.legend(...)` are carried on `PlotSpec` and forwarded by `BravenPlot`.
- **Per-mark data-point markers and inline labels.** `showDataPointMarkers`
  and `dataPointLabels` on `geomLine`/`geomArea`, and `labelStyle` on `geomBar`.
- **Range-area bands.** `geomRangeArea(low:, high:)` lowers to
  `RangeAreaChartSeries` and reverses back out of a captured chart. Its bounds
  are nullable so a gap has a row shape; `pathAnimation` and `fillGradient` stay
  named refusals, as on `AreaMark`. Verified on the MOUNTED page —
  `example/test/showcase/selection_showcase_range_area_grammar_test.dart` pumps
  the selection lab, selects its Range Area family through the real picker and
  runs the generator on the live document, which emits a complete, warning-free
  chain for both bands and the centre line. The `RangeAreaChartsPage`'s seven
  presets still refuse, and by name: every band there carries a non-default
  `pathAnimation` and six of seven a `fillGradient`.
- **Radial geometries.** `geomPie`, `geomDonut` (with the `ring:` channel for a
  concentric composition and `concentric:` for its configuration) and
  `geomPolar`, plus the spec-level `.polarConfig(...)`. Multi-series polar
  compositions and customised `PolarChartConfig` / `ConcentricDonutConfig`
  round-trip.

  Stated precisely, because the showcase is the evidence:

  - **Every radial Workbench Grammar pane whose family HAS a geometry emits a
    real chain** instead of a diagnostic — pie, donut, concentric donut and
    polar column. (Radial bar and gauge have no `geom*` verb at all; their
    panes still show a named diagnostic.)
  - **Polar: all eight showcase presentations** (standard, rose, partial,
    layered, grouped, stacked, references, intervals), each verified against
    `polar_column_page.dart`'s own `_buildSeriesList` / `_buildPolarConfig`
    construction at that presentation's authored knob values.
  - **Pie, donut and concentric: verified on the MOUNTED page.** Each test
    pumps the real page, reads the live document off the chart's own controller
    and runs the generator on it, so there is no fixture to drift —
    `pie_charts_page_grammar_test.dart`, `donut_charts_page_grammar_test.dart`,
    `concentric_donut_page_grammar_test.dart` and
    `selection_showcase_concentric_grammar_test.dart`, all under
    `example/test/showcase/`. `concentric_donut_page.dart` and the selection
    lab's concentric family emit **complete, warning-free** chains;
    `pie_charts_page.dart` and `donut_charts_page.dart` emit with
    `isComplete == false`, because of live formatter callbacks that have no
    literal form — the established contract for runtime values, not a
    degradation. The counts differ and each gate pins its own whole warning
    set: the pie carries **one** `runtimeValueOmitted`, covering the two
    radial label formatters it binds; the donut carries **two** — one for the
    `valueFormatter` on its centre and one covering the two radial label
    formatters — leaving three placeholder comments in the chain.
  - **All four mounted-page gates COMPILE the chain they assert on**, through
    the same `dart format` + `dart analyze` harness
    (`test/helpers/generated_source_compile.dart`) the polar gate uses. That is
    the floor, not a nicety: every other assertion in those tests reads the
    emitted *text*, and `contains` cannot tell a chain that would compile from
    one that only looks right. It caught a real defect the text assertions had
    all passed over — the emitted preamble imports
    `package:braven_charts/braven_charts.dart` and
    `package:flutter/material.dart` unprefixed, and `TooltipTriggerMode` is
    declared in both, so every chain that emitted a non-default tooltip trigger
    mode was `ambiguous_import`. The material import now carries `hide` for the
    ambiguous names the body actually uses, in **both** source forms;
    `test/unit/source/generated_import_ambiguity_test.dart` re-derives that
    list from the analyzer so a future collision fails a test instead of
    reaching a user as unpasteable source.
  - **A non-default `ConcentricDonutConfig` emits** — radii, ring gap, order,
    legend mode, per-ring weights and center all survive to
    `geomDonut(concentric: ...)`. Ring series ids following
    `'<markId>-<ring>'` are no longer required — a composition that ids its
    rings independently emits `ringIds:` instead — and rings that carry
    DIFFERENT `dataLabels` emit as `dataLabelsByRing:`.
  - **The concentric preconditions are a SET, not one.** This paragraph used to
    say the one remaining precondition was that no ring carry a centre of its
    own. That was false. `DonutMark` holds ONE `style`, ONE `selectionStyle`,
    ONE `unit`, ONE `sliceRadiusConfig` and ONE `sliceGroupingConfig` for the
    WHOLE composition, and `_lowerConcentricRings`
    (`lib/src/grammar/plot_lowering.dart:1524`) stamps each of them onto every
    ring — and, unlike the single-donut `_lowerDonut` beside it, never passes
    `mark.color` at all. So a concentric composition emits only when every
    ring:
    - shares one `donutStyle`,
    - shares one `selectionStyle`,
    - shares one `unit`,
    - shares one `sliceRadiusConfig`,
    - shares one `sliceGroupingConfig`,
    - carries **no** series `color` of its own,
    - carries no centre of its own, and
    - has a distinct, non-empty name.

    Two clarifications the list alone would not give. On the five shared
    configs it is DIVERGENCE that is refused, not a non-default value: rings
    that all carry the same non-default `donutStyle` emit, and the style is
    carried through. The series `color` is different in kind — no ring may
    carry one *even when every ring carries the same one*, because the ring
    path never reads `mark.color`; a single, non-concentric donut's series
    colour DOES emit.

    Only the ring centre and the ring name are refused BY NAME. The five
    config divergences and the ring colour arrive as the round-trip proof's
    catch-all sentence, whose own round-trip list states that `unit`, the
    series style, the selection style and the slice-radius and grouping
    configs round-trip — true of a conforming composition, and actively
    misleading to the author who just tripped one of them. That is a gap worth
    closing: a precondition a user can reach deserves a reason of its own.

    Pinned matched-pair style in the `fidelity matrix diagnostics` group of
    `test/unit/source/chart_grammar_source_generator_test.dart` — the
    divergent-`donutStyle` refusal sits beside a control proving the SHARED
    non-default style emits and is carried, the other four divergences are
    refused together, and the ring-colour refusal sits beside the
    single-donut control that emits.

  What stays refused in the radial families is narrow, and mostly named: a
  radial-bar or gauge chart (no grammar geometry at all), a concentric
  composition whose rings are unnamed or share a name (the ring key
  *is* the series name), a concentric composition whose rings disagree on
  `donutStyle` / `selectionStyle` / `unit` / `sliceRadiusConfig` /
  `sliceGroupingConfig` or in which any ring carries a series `color` or a
  centre of its own, and a per-point `PointStyle` carrying more than a colour
  and a size. Of those, everything except the five ring-config divergences and
  the ring colour is refused with a reason of its own; those six are the
  catch-all cases described above.
  `concentric_donut_page.dart`'s live `donutCenterBuilder` is a widget
  builder the capture layer does not model at all; the emitted chain carries
  the portable `ConcentricDonutConfig.centerContent` that builder's own doc
  names as the artifact fallback — a capture-layer limitation shared with the
  config form, not a grammar one, and pinned in that page's test.

## Not in V1 (still deferred)

Deferred deliberately, so the V1 mark list stays closed:

- **The radial families with no geometry.** Radial bar and gauge have no
  `geom*` verb; author them with their config APIs. (Pie, Donut,
  Concentric Donut and Polar Column ARE grammar geometries as of V2.0 — see
  *Radial geometries* above; Range Area is Cartesian and IS one — see
  *Bands: `geomRangeArea`* above.) Faceting a radial spec is refused by name
  (`facetedRadialUnsupported`).
- **Faceting / small multiples.** These lower to *multiple* widgets plus a
  `ChartInteractionGroupController`, which is a different shape from
  "one spec, one chart".
- **Log and time scale objects.** Axis scaling stays in `XAxisConfig` /
  `YAxisConfig`.
- **String-column data adapters.** The grammar reads typed rows through typed
  accessors; there is no `data['column']` form.
- **Opacity channels and value-driven area fill on non-scatter families.**
  Colour channels now bake onto `geomBar`/`geomLine`/`geomArea` (area colours
  the top *edge*, not the fill) and `geomBar` carries a linear `sizeBy` width
  multiplier; opacity on non-scatter families and value-driven area *fill*
  remain deferred.
- **The remaining chart-level options.** `legendStyle`, the toolbar toggle,
  `interactiveAnnotations`, `maxAxesPerSide`, the axis-swap / normalization
  knobs, width/height and background live on `BravenChartPlus`, not on
  `PlotSpec` / `BravenPlot`. (The grid, title/subtitle and legend toggle ARE
  carried as of V2.0 — see above.)
- **Grammar-source emission of config-authored single-axis charts.** The
  Workbench Grammar form reproduces charts document-for-document; a chart on the
  widget-level `yAxis:` path (a series whose `yAxisId` is unset) is diagnosed
  rather than emitted, because the grammar always binds every series to an
  explicit axis.
- **Stat reactivity unification.** `TrendMark` lowers onto the existing trend
  annotation statistics; the grammar adds no new statistics of its own.

---

## See also

- [Public API overview](api_reference.md)
- [Chart Workbench](chart_workbench.md) — the Chart / Data / Split / Source
  chrome the showcase page renders every preset inside
- [Portable chart artifacts](chart_artifacts.md) — the documents the parity
  suite compares
