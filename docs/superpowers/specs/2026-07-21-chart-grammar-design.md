# Chart Grammar — Generated Fluent API and Grammar-of-Graphics Layer

**Date:** 2026-07-21
**Status:** Design approved in discussion; spec pending owner review
**Lane:** `feature/chart-grammar`, branched from `master` @ `aab5734e`
**Owner decisions:** V1 = Layers 0+1+2 scoped to Cartesian; converge the AI JSON
schema mirror in V1; typed spec classes as the GoG core; typed accessors for
data; chained-DSL facade included as sugar over the spec.

## Problem

Every feature lane extends the public config surface (~490 exported
declarations, ~2,500 constructor parameters) and must then hand-update up to
four parallel mirrors of that surface: the AI tool schema
(`lib/src/ai/chart_tool_schema.dart`, 1,698 lines of JSON literals), the AI
config builder (`lib/src/ai/chart_config_builder.dart`, ~103 `_parse*`
methods), the Source emitter (`lib/src/source/chart_dart_source_generator.dart`,
89 `_emit*` methods), and the artifact codecs. These drift — the AI schema
never learned the value-summary surface. Separately, the package has no
fluent authoring layer and no declarative grammar-of-graphics entry point;
charts are authored by nesting large const constructors.

One machine-readable model of the config surface fixes both: it generates the
fluent layer automatically for every current and future property, and it
becomes the single source of truth the hand-written mirrors converge on.

## Architecture: three layers plus an engine

```text
            @chartSurface annotations on config classes
                            |
              [Layer 0] surface_gen (build_runner + analyzer)
                            |
                     SurfaceModel (in-memory)
              /             |               \
   [Layer 1] fluent   [convergence]      drift tests
   extensions          AI JSON schema     (schema/builder/
   (generated)         (generated)         emitter coverage)
                            |
   [Layer 2] BravenPlot typed spec  ──lowers to──►  BravenChartPlus + configs
        ▲                                            (unchanged, canonical)
   [facade] BravenChart.of(...) chained DSL — builds the typed spec
```

### Layer 0 — surface model and generator

- New marker annotations in `lib/src/meta/chart_surface.dart` (package-internal, not barrel-exported):
  `@chartSurface` on config/style/series classes, with optional per-class
  metadata for irregulars: `presetFactories`, `sealedVariants`,
  `combinedSetters` (assert-coupled params like axis min/max),
  `excluded` (function-typed/controller fields are auto-excluded but can be
  forced), `clearFlags` (maps `clear*` copyWith booleans).
- A dev-only generator package `tool/surface_gen/` (in-repo, path dev
  dependency; never shipped) built on `build_runner` + `source_gen` +
  `analyzer`. It resolves annotated classes into a `SurfaceModel`: classes,
  constructor parameters with types and defaults, enums, nesting, sealed
  hierarchies, tri-state `ChartStyleValue` fields, copyWith shape.
- **Enforcement:** a generator check fails the build when a class reachable
  from the public barrel matches config heuristics but carries neither
  `@chartSurface` nor `@chartSurfaceExempt`. New features therefore cannot
  bypass the model.
- **Enforcement scope — exactly what `missing=0` claims.** The rule is
  "reachable from a public entrypoint" AND "instantiable (neither `abstract`
  nor `sealed`)" AND "an instance `copyWith` is callable on it" (declared,
  inherited, or supplied by a public extension; a `static` one does not
  count). Const-ness is deliberately NOT part of it. `copyWith` is a
  PRECONDITION, not merely a detector: a public config class that declares no
  `copyWith` is not reported as missing, it is INVISIBLE — to enforcement, to
  the reader, and therefore to the fluent layer. So
  `annotated=95 exempt=3 missing=0` means **"every exported class that has a
  `copyWith` is modelled"**, not "the public config surface is fully
  modelled".
- **Known follow-up: the `copyWith`-less config classes.** A scan of the
  export namespace (2026-07-21) for instantiable `*Config`/`*Style`-named
  classes with no `copyWith` finds 29, in six files:
  `models/bar_chart_style.dart` (`BarBorderStyle`, `BarBulletStyle`,
  `BarChartStyle`, `BarDivergingStyle`, `BarErrorBarStyle`,
  `BarInteractionStyle`, `BarLabelCalloutStyle`, `BarLabelStyle`,
  `BarLollipopStyle`, `BarMotionStyle`, `BarPatternStyle`,
  `BarTargetMarkerStyle`, `BarTrackStyle`, `BarWaterfallConnectorStyle`,
  `BarWaterfallStyle`), `models/candlestick_chart_style.dart`
  (`CandlestickAnimationStyle`, `CandlestickChartStyle`,
  `CandlestickPointStyle`), `models/scatter_marker_style.dart`
  (`ScatterCategoryStyle`, `ScatterJitterConfig`),
  `models/scatter_render_config.dart` (`ScatterBinConfig`,
  `ScatterClusterConfig`, `ScatterDensityConfig`),
  `models/chart_context_action.dart` (`ChartContextMenuConfig`,
  `ChartOverlayActionButtonConfig`), `models/chart_state_config.dart`
  (`ChartEmptyStateConfig`, `ChartLoadingConfig`,
  `ChartLoadingSkeletonStyle`) and
  `navigator/cartesian_navigator_models.dart` (`CartesianNavigatorStyle`).
  Closing the gap means ADDING `copyWith` to each — a core public-API change,
  not a generator change — so it is a deliberate follow-up, not Slice 2 work.
- Generated files are checked in under `lib/src/fluent/generated/` (and the
  schema location below), and the opt-in barrel `lib/braven_charts_fluent.dart`
  is GENERATED from that file set by a second, aggregating builder — a
  hand-written barrel cannot survive ~40 files and an unexported generated
  file is invisible dead code. CI regenerates and fails on diff.
  `build_runner` remains a dev dependency; pub consumers see plain Dart.
- **Imports are derived, never curated.** The analyzer records each type's
  defining library; the emitter maps `dart:ui`/`package:flutter/**` origins
  onto one `package:flutter/widgets.dart` import with a `show` clause naming
  exactly the types the file uses. A bare Flutter import made
  `TooltipTriggerMode` — defined by BOTH braven_charts and
  `flutter/src/widgets/raw_tooltip.dart` — an `ambiguous_import`, and a
  curated name list turns every miss into a build failure only the generator
  author can fix.
- **Named diagnostics stop bad surfaces at generation time**, not at
  `flutter analyze`: a parameter with no matching `copyWith` parameter is
  dropped and recorded (ChartTheme's four deprecated private-field-backed
  parameters); parameter-level `@Deprecated` is skipped; a "slicing copyWith"
  (base-typed `copyWith` with `copyWith`-overriding subclasses — `ChartSeries`)
  fails and must be `@ChartSurfaceExempt`; assert-coupled parameters without a
  `CombinedSetter` fail; a class the public barrel does not export fails; a
  class whose only `copyWith` is inherited and base-typed fails.
- Emitters are isolated behind one interface so output can migrate to Dart
  `augment` declarations when they ship (macros were discontinued 2025-01;
  nothing has replaced them through Dart 3.12).
- The stale `build.yaml` is replaced by a real one scoped to the generator.

### Layer 1 — generated fluent modifiers

- One namespaced extension per surface class, generated into
  `lib/src/fluent/generated/`, exported ONLY via a new opt-in barrel
  `lib/braven_charts_fluent.dart`. The core barrel is untouched.
- **Verb vocabulary (owner decision, 2026-07-21).** Two distinct families of
  "unset" exist on this surface and a single `clear` meant opposite things in
  each, so they get distinct verbs:

  | verb | family | lowering |
  |---|---|---|
  | `withX(v)` | every parameter | `copyWith(x: v)` |
  | `withoutX()` | tri-state SUPPRESS ("render nothing, do not inherit") | `copyWith(x: const ChartStyleValue<T>.none())` |
  | `inheritX()` | tri-state INHERIT | `copyWith(x: const ChartStyleValue<T>.inherit())` |
  | `clearX()` | nullable UNSET ("back to the default") | `copyWith(clearX: true)` |
  | `updateX(fn)` | non-nullable nested config | `copyWith(x: fn(x))` |

  The 91-field nullable family owns the intuitive meaning of `clear`;
  tri-state suppression is `without`. `withX` signatures always strip
  nullability (a `null` through a `??`-style copyWith is a silent no-op), and
  the ~70% of nullable parameters whose `copyWith` cannot unset them say so in
  their generated dartdoc rather than shipping a null-accepting verb.
- **Nested updaters.** Every non-nullable nested-config parameter also gets
  `updateX(X Function(X current))`. This is what makes the layer worth
  importing at fleet scale: `InteractionConfig` has 6 nested configs,
  `ChartTheme` 12+, `chart_series.dart` 26 nested-typed fields — editing one
  leaf without re-stating the enclosing config is the common case.
- Assert-coupled parameters are only generated as combined setters
  (`withVisibleRange(min, max)`) per the class's `combinedSetters` metadata;
  no chain step can construct an invalid intermediate config. The generator
  DETECTS assert coupling from the constructor's initializer list and REFUSES
  to model a class whose coupled parameters lack a `CombinedSetter`.
  **Two members stay positional; three or more take REQUIRED NAMED
  parameters** — `withOhlc(1, 6, 0.5, 3)` is a tuple nobody can read at the
  call site — and the dartdoc pluralises off the member count ("as a pair" is
  a claim only a two-member setter may make).
- **An OR-shaped assert is not a combined setter.** `assert(a != null || b !=
  null)` says the two are ALTERNATIVES; modelling it as an AND-shaped
  `withBoth(a, b)` produces a verb whose arguments cannot both be honoured
  and whose "off" state is unreachable. Because `copyWith` merges with `??`
  and (on this fleet) exposes no clear flag for these parameters, no verb can
  select one alternative and retire the other, so such parameters are
  force-excluded and documented as construction-only:
  `BarChartSeries.barWidthPercent`/`barWidthPixels`, and
  `RangeAnnotation`'s four bounds (whose `withBounds` silently converted an
  X-only band into a 2-D box).
- **Cross-object JOIN KEYS get no verb.** `id` is excluded on every series and
  annotation class, as it already was on `YAxisConfig`: series ids bind axes,
  annotations and artifact documents; annotation ids bind selection state. A
  mid-chain rewrite detaches the value from everything referencing it.
- **`paramNotes` metadata** appends a caveat to a generated verb's dartdoc for
  a truth the generator can neither derive nor fix — `TextAnnotation.withText`
  type-checks on a rich annotation, stores the text, and is never drawn,
  because the reader models the public plain-text constructor while
  `copyWith` rebuilds through `_internal`. A note for an unknown or excluded
  parameter fails the build.
- **Sealed hierarchies** get one constructor helper per sealed FACTORY on the
  owning parameter, named `with<Factory><Param>` (`.overlay` on
  `presentation` → `withOverlayPresentation`), mirroring the factory
  signature verbatim including default expressions, plus the `updateX` escape
  hatch. Nothing is emitted on the sealed base itself. The
  function-typed/controller-typed exclusion rules apply to FACTORY parameters
  too: `withBuilderContent` was the fleet's only function-typed verb, and the
  config it minted is exactly the one the artifact codec refuses to serialize
  without a registered `descriptorId`. Callers reach that variant through the
  plain `withContent(...)` verb, at the constructor that documents the
  requirement.
- **`presetFactories` get NO fluent surface.** Dart factories already chain:
  `CrosshairConfig.tracking(...).withSnapRadius(12)` works today because the
  extension applies to the factory's result. The metadata stays in the model
  for the Slice 3 AI schema.
- Configs stay const-canonical: the fluent layer allocates only when used,
  affects no artifact/Source path, and every chain result is an ordinary
  config instance.

### Layer 2 — typed GoG spec (handwritten, parity-locked)

- `BravenPlot<T>` widget in `lib/src/grammar/`: `data: List<T>` plus
  `marks: List<Mark<T>>`, optional `coord` (cartesian, `transposed: true`),
  axes/scale hints, theme, interaction. It compiles ("lowers") to the
  existing `BravenChartPlus` + series + configs — the render pipeline, the
  artifact codecs, Source, and Workbench are untouched and receive exactly
  the objects they already understand.
- V1 marks (Cartesian only): `LineMark<T>`, `AreaMark<T>`, `BarMark<T>`,
  `ScatterMark<T>`, `CandlestickMark<T>`, plus `TrendMark<T>` lowering onto
  the existing trend-annotation statistics. Encodings are typed accessors:
  `x: (row) => value`, `y`, and mark-specific channels — `Channel<T>` for
  scatter color/size/opacity/category (the only family with scale-driven
  channels today). Channels simply do not exist on marks that cannot honor
  them: the coord×geom validity matrix is enforced by the type system.
- **Marks get NO `copyWith` in V1** (owner decision, Task 9). A `copyWith`
  would make marks config-shaped; enforcement
  (`test/meta/surface_enforcement_test.dart`) reads "instantiable, public,
  has a `copyWith`" as "must carry `@chartSurface`", and the emitter would
  then generate a fluent verb surface over the grammar layer — a SECOND
  vocabulary for the same objects, `LineMark.withStrokeWidth` sitting beside
  `LineChartSeries.withStrokeWidth`. Marks are small: modify one by
  constructing a new one, or author through the chained facade (Task 12).
  The same reasoning applies to `PlotSpec`, `Channel`, `CategoryChannel` and
  `LoweredPlot`; none of them has a `copyWith`, and `enforcement missing=0`
  holds with the grammar layer exported from the core barrel.
- Multiple marks over one data list lower to multi-series composition on the
  multi-axis path exclusively (the legacy single-axis path is never
  targeted). Each mark accepts `axis:`/`yAxisId:` hints that lower onto
  `YAxisConfig` slots.
- **Lowering contract (Task 10, `lib/src/grammar/plot_lowering.dart`).**
  `LoweredPlot lower<T>(PlotSpec<T> spec)` is total and fail-fast; the
  validation order is fixed (empty marks → empty data → mark ids → axis ids →
  transposition → each mark in spec order → unbound axes) so a spec with
  several problems always reports the same one first.
  - Mark ids default to `mark-<index>`, counting trend marks. Axis ids default
    to `axis-<index>`; an empty `yAxes` becomes one left axis, `axis-0`.
    Every series carries BOTH `yAxisId` and the matching `yAxisConfig` — that
    pair is what activates the multi-axis path.
  - **Non-finite values pass through** for line/area/bar/scatter.
    `ChartDataPoint` documents NaN/infinite coordinates and exposes `isValid`;
    the whole pipeline already skips invalid points, and that IS how a gap in
    a line is expressed. Rejecting them would make the grammar stricter than
    the API it lowers onto. Candlesticks are the exception because
    `CandlestickDataPoint` rejects them itself: those rows raise
    `invalidCandlestickRow` with the row index instead of leaking an
    `ArgumentError`.
  - **`transposed: true` requires an all-`BarMark` spec.** Transposition is
    implemented in this package by horizontal bar geometry, which transposes
    the whole plane; a mixed spec would render some geometries rotated and
    others not, so it raises `unsupportedTransposition`.
  - **Channel scales are checked, not coerced.** Each channel has exactly one
    scale the renderer implements (`size` → area/`sqrt`, `colorBy` and
    `opacityBy` → `linear`). Null selects it; the other one raises
    `unsupportedChannelScale`.
  - **Channel encodings that cannot be defaulted are required.** `colorBy`
    needs a `ScatterColorEncoding` (no default ramp exists) and `categoryBy`
    needs `categories` (no categorical palette exists); `size` and `opacityBy`
    default to their all-default encodings. A channel `label`, when set, wins
    over the template's own label.
- **Parity is load-bearing:** a test suite builds charts both ways
  (spec-lowered vs hand-built configs) and asserts config equality and
  artifact-document equality. The GoG layer cannot silently drift from the
  config surface it lowers to.
- Deferred to V2+ (explicitly out of scope): radial/polar marks, faceting
  (lowers to multiple widgets + `ChartInteractionGroupController`), log/time
  scale objects, scale-driven color/size on non-scatter families,
  string-column data adapters, stat reactivity unification.

### Chained facade (sugar over the spec)

- `BravenChart.of(rows)` in `lib/src/grammar/chart_builder.dart`: an
  immutable chain (`.x((r) => r.time)`, `.y(...)`, `.geomLine()`,
  `.geomPoint(size:, colorBy:)`, `.transposed()`, `.theme(...)`,
  `.interaction(...)`, `.build()`), each step returning a new builder; the
  terminal `.build()` constructs the typed spec, which lowers as above.
- The facade is the headline authoring style in docs and showcase (the
  ggplot/Cristalyse read the owner wants), but the typed spec remains the
  semantic core — the facade contains zero lowering logic of its own.
- Validation the chain cannot express at compile time (e.g. a channel a
  geom cannot honor) surfaces at `.build()` with the same diagnostic style
  as `ChartConfigBuilder` (fail-fast, named errors), never silently.

### Convergence proof — AI schema (V1) and drift tests

**RE-SCOPED 2026-07-21, after the Task 7 implementation attempt.** The
original plan above assumed `chart_tool_schema.dart` is a MIRROR of the config
classes, so that generating it from the `SurfaceModel` would be a swap. It is
not, and the difference is structural rather than a matter of effort.

#### What the AI schema actually is

`chart_tool_schema.dart` is a flat **LLM vocabulary**, keyed independently of
class structure:

- its properties are snake_case names invented for the agent protocol
  (`bar_waterfall_connector_color`, `pie_label_minimum_sweep`), consumed
  literally by `ChartConfigBuilder` as `json['bar_corner_radius']`;
- one flat `style` bag flattens dozens of nested config classes, so there is
  no function from a Dart parameter to a schema key that a generator could
  compute;
- of the 205 keys the builder reads, **21** have a same-named parameter
  anywhere in the surface model even under the most generous
  case-and-underscore-insensitive match. The other 184 land on classes the
  model cannot see, or on names the vocabulary invented;
- **22 config classes the builder constructs carry no `@chartSurface`** —
  `BarChartStyle`, `BarLabelStyle`, `BarWaterfallStyle`, `CandlestickChartStyle`,
  `ScatterDensityConfig` and 17 siblings — because none of them has a
  `copyWith`, which is the enforcement rule's definition of "config-shaped".
  Roughly half the vocabulary lowers onto them. They are enumerated and
  regression-gated in `test/meta/ai_mirror_drift_test.dart`.

The literals therefore cannot be "regenerated". Replacing them means
generating a DIFFERENT artifact and migrating every consumer to it.

#### The three options

1. **Additive (chosen for V1).** Generate a class-keyed structural `$defs`
   block alongside the untouched literals, and gate the literals against the
   parser instead of against the classes. Cost: the 1,698 literals stay
   hand-written. Benefit: an always-current, un-driftable description of the
   config surface, plus — for the first time — a machine check of the contract
   that actually matters.
2. **Full metadata.** Add snake_case key names, nesting path and vocabulary
   grouping to `@ChartSurface` for all ~93 modelled classes AND give the 22
   unmodelled classes a `copyWith` so they can be annotated. Reproduces the
   literals exactly, at the price of encoding the whole agent protocol in
   annotations — the vocabulary's authorship moves into the model layer.
3. **Builder-AST-derived.** Generate the schema from `ChartConfigBuilder`
   itself, which is the only artifact that knows the true key set. Correct by
   construction for key NAMES; supplies no descriptions, enum lists or
   defaults, all of which are today's schema's actual value to an LLM.

Options 2 and 3 are both viable and both large. The choice is an owner
decision and is explicitly **deferred**; V1 does not prejudge it.

#### What V1 delivers

- `lib/src/ai/generated/surface_definitions.dart` — JSON-Schema `$defs` for
  every `@chartSurface` class (95 classes, ~940 properties), exposed as the
  new `ChartToolSchema.surfaceDefinitions`. Enums become enum lists, nested
  configs become `$ref`s, `ChartStyleValue<X>` becomes a
  `{value | "none" | "inherit"}` union, defaults are surfaced, and the
  exclusion kinds split by INTENT: callbacks/controllers/deprecated parameters
  are omitted with the omission stated on the class, while force-excluded and
  no-`copyWith` parameters are INCLUDED and marked `x-mutation:
  construction-only` — they are unsettable, not unconstructible.
- `createChartTool` / `modifyChartTool` / `explainDataTool` are **byte-for-byte
  unchanged**; `test/unit/ai/fixtures/pre_convergence_schema.json` still
  matches the live dump exactly.
- Task 8 hard gate (a) is now gateable, because the new member is class-keyed:
  `test/meta/ai_surface_definitions_test.dart` checks the definitions against
  two INDEPENDENT sources — the analyzer enforcement scan for the class list,
  and the generated fluent extensions for the per-parameter check.
- `test/meta/ai_mirror_drift_test.dart` gates the real contract in both
  directions, with today's holes pinned and a one-line reason each.

Deferred, pending the owner decision: deleting the 1,698 literals, and drift
test (c) for the Source emitter.

#### Named follow-up — the candlestick schema gap

Ten keys are parsed by `ChartConfigBuilder` and undiscoverable to an LLM:

```
candlestick_body_fill            candlestick_animation_mode
candlestick_body_width_factor    candlestick_animation_stagger
candlestick_border_width         candlestick_density_grouping
candlestick_wick_width           candlestick_target_group_width
candlestick_corner_radius        candlestick_minimum_points_per_group
```

Seven of them DO appear in `chart_tool_schema.dart` — but as siblings of
`properties` and `required` inside the `allOf[0].if` subschema, a position
where JSON Schema ignores unknown keywords outright. Source-present and
consumer-invisible is the same as absent. The remaining three
(`candlestick_density_grouping`, `candlestick_target_group_width`,
`candlestick_minimum_points_per_group`) never appear at all.

This is a product gap, not a cosmetic one: candlestick body fill, wick width,
corner radius, entrance animation and density grouping are all supported by
the package and cannot be requested by an agent. A second gap runs the other
way — `line_interpolation` is documented as a four-member enum but
`_parseLineSeries` hardcodes `LineInterpolation.linear` and never reads it, so
an agent that sets it gets a straight-line chart and no error.

Fixing the literals is deliberately out of scope here (it is part of the
deferred decision above); all eleven keys are pinned in the drift test so the
gaps are recorded, visible in CI, and cannot widen.

## Success criteria

1. Adding a property to an annotated config class and running the generator
   yields the fluent `withX`/`withoutX`/`inheritX`/`clearX`/`updateX` methods
   and updated AI schema with no hand edits; forgetting the annotation on a
   new config class fails CI.
2. The chained facade authors every showcase-representative Cartesian chart
   (line/area/bar/scatter/candlestick, multi-series, multi-axis, styled,
   with interaction config) and the result is config-equal to hand-built.
3. Spec-built charts round-trip artifacts, hydration, generated Dart Source,
   and Workbench with zero changes to those subsystems.
4. ~~The AI schema mirror is generated, provably a superset of today's, and
   hand-edits to it are impossible (file is generated + CI-diffed).~~
   **RE-SCOPED** (see the convergence section): the STRUCTURAL surface is
   generated and CI-diffed as `ChartToolSchema.surfaceDefinitions`; the flat
   LLM vocabulary in `createChartTool` stays hand-written and is instead
   gated against the parser that consumes it, in both directions.
5. Package analyze/tests stay green; no existing golden drifts; the fluent
   barrel is absent from the core barrel (opt-in only).
6. A first-class "Chart Grammar" showcase page demonstrates facade-authored
   charts side by side with their generated-Source view.

## Slices

| # | Deliverable | Gate |
|---|---|---|
| 1 | `tool/surface_gen` + annotations + SurfaceModel, proven end-to-end on 3 pilot classes (CrosshairConfig, CartesianValueSummaryStyle, LineChartSeries) with snapshot tests of emitted code | generator unit + snapshot suite green; CI regenerate-and-diff wired |
| 2 | Annotate the full surface (~90 builder-target classes incl. metadata for irregulars); fluent emission for all; `braven_charts_fluent.dart` barrel; behavior tests | full suite green; enforcement check active |
| 3 | Structural AI `$defs` generated ADDITIVELY (`ChartToolSchema.surfaceDefinitions`) + bidirectional schema/builder drift gate | tool literals byte-unchanged vs the frozen fixture; class+parameter gate green against two independent sources; drift pinned with reasons. Deleting the 1,698 literals is deferred — owner decision |
| 4 | `BravenPlot` spec core + lowering + parity suite; chained facade + validation diagnostics | parity matrix green (config + artifact equality) |
| 5 | Showcase "Chart Grammar" page (facade-authored presets, live Source view), docs (`doc/chart_grammar.md`), CHANGELOG; full release gates | user checkpoint; PR on approval |

## Risks and mitigations

- **Generator complexity concentrates risk** → Slice 1 is deliberately small
  (3 pilot classes, snapshot-tested emitted output) before the fleet.
- **Per-step copyWith asserts** → combined setters via metadata; audit during
  Slice 2 annotation pass.
- **Extension name collisions** (whole-extension resolution granularity) →
  one namespaced extension per class (`LineChartSeriesFluent`), opt-in barrel.
- **GoG layer scope creep** (seaborn.objects' years-long limbo is the
  cautionary tale) → V1 mark list is closed; anything else is V2 by spec.
- **Augmentations land mid-flight** → emitter interface isolates output
  format; migration is an emitter swap, not a redesign.
- **Schema behavior change for AI consumers** → superset snapshot gate plus
  the existing AI-lane tests must stay green.
- **Facade drift from spec** → facade builds the spec (no parallel lowering);
  parity tests run through both entries.

## Verification map

- Generator: unit tests on fixture classes (every irregular shape) +
  emitted-code snapshot tests + enforcement-check tests.
- Fluent: per-kind behavior tests (withX equality vs copyWith, withoutX vs
  tri-state/none, clearX vs clear-flags, combined setters, sealed helpers,
  nested updaters) sampled
  across families + an exhaustive generated smoke test (every generated
  method invoked once, type-checked by compilation).
- GoG: lowering parity matrix (marks × single/multi-series × multi-axis ×
  themes) asserting config + artifact equality; facade-vs-spec equivalence;
  validation diagnostics tests.
- Convergence: schema superset snapshot, drift tests, AI-lane suite green.
- Repo gates per lane convention: analyze lib, full package + example
  suites, zero existing-golden drift, publish dry-run at the end.
