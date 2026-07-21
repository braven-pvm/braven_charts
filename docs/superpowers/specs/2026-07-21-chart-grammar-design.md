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
  from the public barrel matches config heuristics (const ctor + copyWith)
  but carries neither `@chartSurface` nor `@chartSurfaceExempt`. New features
  therefore cannot bypass the model.
- Generated files are checked in under `lib/src/fluent/generated/` (and the
  schema location below). CI regenerates and fails on diff. `build_runner`
  remains a dev dependency; pub consumers see plain Dart.
- Emitters are isolated behind one interface so output can migrate to Dart
  `augment` declarations when they ship (macros were discontinued 2025-01;
  nothing has replaced them through Dart 3.12).
- The stale `build.yaml` is replaced by a real one scoped to the generator.

### Layer 1 — generated fluent modifiers

- One namespaced extension per surface class, generated into
  `lib/src/fluent/generated/`, exported ONLY via a new opt-in barrel
  `lib/braven_charts_fluent.dart`. The core barrel is untouched.
- Per property: `withX(value)` lowering to `copyWith`. Where clearing is
  meaningful: `clearX()` — tri-state fields lower to `ChartStyleValue.none()`,
  nullable-with-clear-flag fields use the class's `clear*` copyWith flags.
  This gives the null-vs-absent distinction a uniform public verb.
- Assert-coupled parameters are only generated as combined setters
  (`withVisibleRange(min, max)`) per the class's `combinedSetters` metadata;
  no chain step can construct an invalid intermediate config.
- Sealed hierarchies get variant helpers on the owner (e.g.
  `withOverlayPresentation(...)`, `withAnnotationPresentation(...)`).
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
- Multiple marks over one data list lower to multi-series composition on the
  multi-axis path exclusively (the legacy single-axis path is never
  targeted). Each mark accepts `axis:`/`yAxisId:` hints that lower onto
  `YAxisConfig` slots.
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

- The `chart_tool_schema.dart` public API (its exposed schema maps) is kept;
  its 1,698 lines of hand-written literals are replaced by maps generated
  from the SurfaceModel into `lib/src/ai/generated/`. Behavior gate: the
  generated schema is a superset of the previous hand-written schema for all
  overlapping definitions (snapshot-diff test at migration time), plus it
  now includes surfaces the hand-written one missed (value summary et al.).
- Drift tests generated from the SurfaceModel: (a) every surface property is
  representable in the AI schema; (b) every surface class the AI config
  builder claims to parse covers its current parameter list; (c) every
  surface class the Source emitter emits covers its current parameter list.
  (b) and (c) start as coverage warnings promoted to failures once each
  mirror migrates in follow-up lanes.

## Success criteria

1. Adding a property to an annotated config class and running the generator
   yields the fluent `withX`/`clearX` methods and updated AI schema with no
   hand edits; forgetting the annotation on a new config class fails CI.
2. The chained facade authors every showcase-representative Cartesian chart
   (line/area/bar/scatter/candlestick, multi-series, multi-axis, styled,
   with interaction config) and the result is config-equal to hand-built.
3. Spec-built charts round-trip artifacts, hydration, generated Dart Source,
   and Workbench with zero changes to those subsystems.
4. The AI schema mirror is generated, provably a superset of today's, and
   hand-edits to it are impossible (file is generated + CI-diffed).
5. Package analyze/tests stay green; no existing golden drifts; the fluent
   barrel is absent from the core barrel (opt-in only).
6. A first-class "Chart Grammar" showcase page demonstrates facade-authored
   charts side by side with their generated-Source view.

## Slices

| # | Deliverable | Gate |
|---|---|---|
| 1 | `tool/surface_gen` + annotations + SurfaceModel, proven end-to-end on 3 pilot classes (CrosshairConfig, CartesianValueSummaryStyle, LineChartSeries) with snapshot tests of emitted code | generator unit + snapshot suite green; CI regenerate-and-diff wired |
| 2 | Annotate the full surface (~90 builder-target classes incl. metadata for irregulars); fluent emission for all; `braven_charts_fluent.dart` barrel; behavior tests | full suite green; enforcement check active |
| 3 | AI schema generated + superset snapshot gate + drift tests (builder/emitter as warnings) | schema parity proven; hand-written literals deleted |
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
- Fluent: per-kind behavior tests (withX equality vs copyWith, clearX vs
  tri-state/none and clear-flags, combined setters, sealed helpers) sampled
  across families + an exhaustive generated smoke test (every generated
  method invoked once, type-checked by compilation).
- GoG: lowering parity matrix (marks × single/multi-series × multi-axis ×
  themes) asserting config + artifact equality; facade-vs-spec equivalence;
  validation diagnostics tests.
- Convergence: schema superset snapshot, drift tests, AI-lane suite green.
- Repo gates per lane convention: analyze lib, full package + example
  suites, zero existing-golden drift, publish dry-run at the end.
