# Chart grammar and the fluent surface

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

Showcase: **Chart Grammar** (`?page=chart-grammar`) — five presets authored
through the chained facade only, each inside the Chart / Data / Split / Source
workbench, with a "Compare hand-built" toggle.

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
not compile — every dispatch site is checked when a variant is added. The V1
marks are Cartesian only:

| Mark | Lowers to |
| --- | --- |
| `LineMark<T>` | `LineChartSeries` |
| `AreaMark<T>` | `AreaChartSeries` |
| `BarMark<T>` | `BarChartSeries` |
| `ScatterMark<T>` | `ScatterChartSeries` |
| `CandlestickMark<T>` | `CandlestickChartSeries` |
| `TrendMark<T>` | `TrendAnnotation` bound to its source series |

**Channels exist only where they can be honoured.** `Channel<T>` (quantitative)
and `CategoryChannel<T>` (categorical) are constructor parameters of
`ScatterMark` and of no other mark, because scatter is the only family in this
package with scale-driven encodings today. The coordinate × geometry validity
matrix is therefore a compile-time property, not a runtime throw.

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
several problems always reports the same one first:

1. empty `marks` → `emptyMarks`
2. empty `data` → `emptyData`
3. mark ids (duplicates) → `duplicateMarkId`
4. axis ids (duplicates) → `duplicateAxisId`
5. transposition → `unsupportedTransposition`
6. each mark, in spec order → `unknownAxisId`, `unknownTrendSource`,
   `invalidTrendWindow`, `missingChannelEncoding`, `unsupportedChannelScale`,
   `invalidCandlestickRow`
7. unbound axes → `unboundAxis`

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
  it lowers onto. Candlesticks are the exception, because
  `CandlestickDataPoint` rejects them itself: those rows raise
  `invalidCandlestickRow` with the row index instead of leaking an
  `ArgumentError` from deeper in the pipeline.
- **A candle is a unit.** `geomCandlestick` requires `open`, `high`, `low` and
  `close` together; there is no per-channel candlestick geometry to compose,
  and rows must be strictly ordered on x.

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

## Not in V1

Deferred deliberately, so the V1 mark list is closed:

- **Radial and polar marks.** Pie, Donut, Concentric Donut and Polar Column
  have no grammar geometry; author them with their config APIs.
- **Faceting / small multiples.** These lower to *multiple* widgets plus a
  `ChartInteractionGroupController`, which is a different shape from
  "one spec, one chart".
- **Log and time scale objects.** Axis scaling stays in `XAxisConfig` /
  `YAxisConfig`.
- **String-column data adapters.** The grammar reads typed rows through typed
  accessors; there is no `data['column']` form.
- **Scale-driven channels on non-scatter families.** Colour/size/opacity
  channels exist only on `ScatterMark`, because scatter is the only family the
  render pipeline scales today.
- **Stat reactivity unification.** `TrendMark` lowers onto the existing trend
  annotation statistics; the grammar adds no new statistics of its own.

---

## See also

- [Public API overview](api_reference.md)
- [Chart Workbench](chart_workbench.md) — the Chart / Data / Split / Source
  chrome the showcase page renders every preset inside
- [Portable chart artifacts](chart_artifacts.md) — the documents the parity
  suite compares
