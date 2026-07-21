# Chart Grammar Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** A build_runner-generated fluent API and AI-schema mirror driven by one annotated surface model, plus a typed grammar-of-graphics layer (`BravenPlot` + chained facade) lowering onto the existing config API.

**Architecture:** `tool/surface_gen` (dev-only, analyzer-based) reads `@chartSurface` annotations into a `SurfaceModel` and emits checked-in generated files (fluent extensions now, AI schema in Slice 3) behind a swappable emitter interface; CI regenerates and fails on diff. The GoG layer is handwritten: typed `Mark<T>` specs lower to `BravenChartPlus` + existing configs, parity-locked by config- and artifact-equality tests; the chained `BravenChart.of()` facade only builds specs.

**Tech Stack:** Dart ≥3.9 / Flutter ≥3.35, build_runner + source_gen + analyzer (dev-only), no new runtime deps.

## Global Constraints

- Spec of record: `docs/superpowers/specs/2026-07-21-chart-grammar-design.md` (this worktree). Owner decisions and V1 scope boundaries bind every task; radial/facets/log-time/string-columns are out of scope.
- Core barrel `lib/braven_charts.dart` untouched by fluent exports; fluent surface only via new `lib/braven_charts_fluent.dart`.
- Generated files are checked in; consumers never run build_runner. CI must fail when regeneration produces a diff.
- Existing subsystems (render pipeline, artifact codecs, Source, Workbench, AI builder) are NOT modified except where a slice explicitly says so (Slice 3 swaps schema internals only).
- Verification commands from the worktree root `F:\Repositories\braven_charts-chart-grammar`: `flutter analyze lib`, full `flutter test`, `cd example; flutter analyze && flutter test` at slice gates; generator tests run via `dart test` inside `tool/surface_gen`. Baseline at lane start: record exact counts in Task 1.
- Conventional commits; trailer `Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>`; commit after every green step pair. One writer in the lane at a time. Never touch other worktrees.
- Showcase additions follow the repo's first-class rules: registered page, shared option widgets (`SliderOption` uses suffix/decimalPlaces), `ChartColorPalette` for colors, every visible control wired on every preset, widget tests.

---

## SLICE 1 — surface_gen engine, proven on 3 pilots

### Task 1: Generator package scaffold + annotations

**Files:**
- Create: `lib/src/meta/chart_surface.dart` (annotations; package-internal, NOT exported from any barrel)
- Create: `tool/surface_gen/pubspec.yaml`, `tool/surface_gen/build.yaml` export snippet doc, `tool/surface_gen/lib/surface_gen.dart` (builder factories), `tool/surface_gen/lib/src/builder.dart` (skeleton `SurfaceGenBuilder`)
- Modify: root `pubspec.yaml` (dev_dependency `surface_gen: path: tool/surface_gen`; keep build_runner ^2.4.5, add source_gen + analyzer pins compatible with the Flutter-bundled analyzer), root `build.yaml` (replace stale content: enable only surface_gen builders, scoped to `lib/src/**`)
- Test: `tool/surface_gen/test/annotation_smoke_test.dart`

**Interfaces (complete annotation contract — later tasks and all annotated classes depend on these exact names):**

```dart
// lib/src/meta/chart_surface.dart
/// Marks a public config/style/series class for surface generation.
class ChartSurface {
  const ChartSurface({
    this.presetFactories = const <String>[],   // e.g. ['tracking', 'defaultConfig']
    this.sealedVariants = const <String>[],    // subclass names for sealed owners
    this.combinedSetters = const <CombinedSetter>[],
    this.excluded = const <String>[],          // param names to force-exclude
    this.clearFlags = const <String, String>{},// paramName -> copyWith clear flag name
  });
  final List<String> presetFactories;
  final List<String> sealedVariants;
  final List<CombinedSetter> combinedSetters;
  final List<String> excluded;
  final Map<String, String> clearFlags;
}

class CombinedSetter {
  const CombinedSetter(this.name, this.params); // e.g. CombinedSetter('withVisibleRange', ['min', 'max'])
  final String name;
  final List<String> params;
}

/// Exempts a barrel-reachable config-shaped class from enforcement.
class ChartSurfaceExempt {
  const ChartSurfaceExempt(this.reason);
  final String reason;
}

const chartSurface = ChartSurface();
```

- [ ] **Step 1:** Write failing test `annotation_smoke_test.dart`: imports the annotations via the package path, constructs `ChartSurface(combinedSetters: [CombinedSetter('withVisibleRange', ['min','max'])])`, asserts field round-trip. Run `dart test` in tool/surface_gen → FAIL (files missing).
- [ ] **Step 2:** Create the annotation file exactly as above; scaffold tool/surface_gen pubspec (name surface_gen, publish_to: none, deps: build, source_gen, analyzer, dart_style; dev: test, build_test); builder factory returning a no-op `Builder` for now; root pubspec/build.yaml wiring.
- [ ] **Step 3:** `dart test` in tool/surface_gen green; root `flutter analyze lib` clean; `flutter pub get` resolves. Record lane baselines: full `flutter test` count and example count in the commit message body.
- [ ] **Step 4:** Commit `feat(surface-gen): scaffold generator package and chart surface annotations`

### Task 2: SurfaceModel + analyzer reader (pilot classes)

**Files:**
- Create: `tool/surface_gen/lib/src/surface_model.dart`, `tool/surface_gen/lib/src/surface_reader.dart`
- Test: `tool/surface_gen/test/surface_reader_test.dart` + fixture library `tool/surface_gen/test/fixtures/fixture_configs.dart`

**Interfaces (complete model contract):**

```dart
enum SurfaceParamKind { value, enumType, nestedConfig, triState, listValue, mapValue,
  excludedFunction, excludedController, excludedByAnnotation,
  excludedDeprecated,        // parameter-level @Deprecated
  excludedNoCopyWithParam }  // no same-named copyWith parameter (ChartTheme's shape)

class SurfaceParam {
  const SurfaceParam({required this.name, required this.dartType, required this.kind,
    required this.isRequired, required this.isNullable, this.isNamed = true, this.defaultCode,
    this.triStatePayloadType, this.clearFlag, this.enumValues = const <String>[],
    this.typeOrigins = const <String, String>{}});
  final String name; final String dartType; final SurfaceParamKind kind;
  final bool isRequired; final bool isNullable; final bool isNamed; final String? defaultCode;
  final String? triStatePayloadType; final String? clearFlag; final List<String> enumValues;
  final Map<String, String> typeOrigins;  // simple type name -> defining library URI
}

class SurfaceClass {
  const SurfaceClass({required this.name, required this.libraryUri, required this.isConstConstructible,
    required this.hasCopyWith, required this.params, this.copyWithReturnType,
    this.typeParameters = const <String>[], this.factories = const <SurfaceFactoryModel>[],
    this.assertGroups = const <List<String>>[], this.sealedVariants = const <String>[],
    this.presetFactories = const <String>[], this.combinedSetters = const <CombinedSetterModel>[],
    this.isSealed = false});
  final String name; final String libraryUri; final bool isConstConstructible; final bool hasCopyWith;
  final String? copyWithReturnType;              // != name => inherited base-typed copyWith
  final List<SurfaceParam> params;
  final List<String> typeParameters;             // declarations with bounds, e.g. 'T extends num'
  final List<SurfaceFactoryModel> factories;     // sealed owners only; drives variant helpers
  final List<List<String>> assertGroups;         // params coupled by a ctor assert
  final List<String> sealedVariants; final List<String> presetFactories;
  final List<CombinedSetterModel> combinedSetters; final bool isSealed;
}

class SurfaceFactoryModel { const SurfaceFactoryModel(this.name, this.params);
  final String name; final List<SurfaceParam> params; }

class CombinedSetterModel { const CombinedSetterModel(this.name, this.paramNames); final String name; final List<String> paramNames; }

class SurfaceModel { const SurfaceModel(this.classes); final List<SurfaceClass> classes;
  SurfaceClass byName(String name); }

abstract interface class SurfaceReader {
  Future<SurfaceModel> read(/* analyzer session over the package */);
}
```

Classification rules the reader implements (test each): function-typed param → `excludedFunction`; type implements/extends Listenable or ends in `Controller` → `excludedController`; `ChartStyleValue<X>` → `triState` with payload X; enum type → `enumType` with values; type annotated `@chartSurface` elsewhere → `nestedConfig`; `List<...>`/`Map<...>` → listValue/mapValue; else `value`. Default expressions captured as SOURCE CODE strings (from the parameter's defaultValueCode), never evaluated.

- [ ] **Step 1:** Write fixtures: a mini config family exercising every rule (const class with enum + nested + tri-state + function param + controller param + clear-flag copyWith + assert pair + a sealed hierarchy + a preset factory). Write failing reader tests asserting the produced SurfaceModel classifies every param exactly (exhaustive expectations, not spot checks).
- [ ] **Step 2:** Run → FAIL. **Step 3:** Implement reader on analyzer element model (resolve fixture library via build_test's `resolveSources`). **Step 4:** Green. **Step 5:** Commit `feat(surface-gen): SurfaceModel and analyzer-based surface reader`

### Task 3: Fluent emitter + pilot generation

**Files:**
- Create: `tool/surface_gen/lib/src/emitter.dart` (interface), `tool/surface_gen/lib/src/fluent_emitter.dart`, `tool/surface_gen/lib/src/builder.dart` (real builder: read → emit → dart_style format)
- Create (generated, checked in): `lib/src/fluent/generated/models/interaction_config_fluent.dart`, `lib/src/fluent/generated/models/cartesian_value_summary_style_fluent.dart`, `lib/src/fluent/generated/models/chart_series_fluent.dart` — the capture-group build extension preserves source subdirectories and maps one generated file per SOURCE file (collision-proof for same-named files in different dirs; a source file with several annotated classes yields several extensions in its one file, e.g. `interaction_config_fluent.dart` once InteractionConfig joins CrosshairConfig in Task 5)
- Create: `lib/braven_charts_fluent.dart` (barrel: exports core barrel + the generated files)
- Modify: `lib/src/models/interaction_config.dart`, `lib/src/models/cartesian_value_summary_style.dart`, `lib/src/models/chart_series.dart` — add `@chartSurface` (with metadata where needed) to the 3 pilot classes ONLY
- Test: `tool/surface_gen/test/fluent_emitter_snapshot_test.dart`, `test/fluent/fluent_pilot_behavior_test.dart`

**Interfaces:**

```dart
abstract interface class SurfaceEmitter {
  String get outputSuffix;                            // '_fluent.dart'
  String emit(SurfaceClass cls, SurfaceModel model);  // one class
  String? emitLibrary(SurfaceModel model);            // whole file — what the builder calls
}
```

`emitLibrary` is ON the interface: the builder is the only production caller
and it emits whole libraries, so an interface describing only per-class
emission would be bypassed in production — exactly the insurance the
"swappable emitter" is meant to buy. Slice 3's `AiSchemaEmitter` is
whole-library by nature.

Emission rules (each snapshot-tested): extension named `<ClassName>Fluent` on
the class (type parameters re-declared for generic classes:
`extension FooFluent<T extends num> on Foo<T>`); per non-excluded param
`ClassName withParamName(Type value) => copyWith(paramName: value);` with
nullability STRIPPED from the signature; nullable-with-clearFlag →
additionally `ClassName clearParamName() => copyWith(clearParamName: true);`
(flag name DERIVED from the copyWith signature, metadata is an override);
nullable WITHOUT a clear flag → the dartdoc says so ("No clear verb: this
class's copyWith cannot unset [X]") rather than shipping `withX(T?)`;
triState → `withX(Payload value)`, **`withoutX()`** (suppress → `.none()`),
`inheritX()` (→ `.inherit()`); non-nullable nestedConfig → additionally
`updateX(X Function(X current) update) => copyWith(x: update(x))`; sealed
nested param → one `with<Factory><Param>` helper per sealed factory,
signature mirroring the factory verbatim with defaults; combinedSetters
replace their individual params entirely and take NON-nullable types;
`is`-prefixed bools drop the prefix (`isXOrdered` → `withXOrdered`);
`presetFactories` get NO surface (Dart factories already chain); every
generated file starts with `// GENERATED by surface_gen — do not edit.` and
resolves types through the barrel plus a `show`-limited
`package:flutter/widgets.dart` derived from the analyzer's type origins (no
`ignore_for_file` lines — the output is lint-clean).

- [ ] **Step 1:** Snapshot tests first: expected emitted source for the three pilots as heredoc strings (write what SHOULD be generated — this is the API design artifact), compared to emitter output normalized by dart_style. Run → FAIL.
- [ ] **Step 2:** Implement emitter + builder; run `dart run build_runner build --delete-conflicting-outputs` at repo root; commit the three generated files + barrel.
- [ ] **Step 3:** Behavior tests: `const CrosshairConfig().withMode(CrosshairMode.vertical) == CrosshairConfig(mode: CrosshairMode.vertical)`; tri-state `style.withBackgroundColor(c)` / `.clearBackgroundColor()` / `.inheritBackgroundColor()` round the three states; `LineChartSeries` chain of 3 modifiers equals single copyWith; chains do not mutate the receiver.
- [ ] **Step 4:** `flutter analyze lib` clean (generated code lint-clean); full `flutter test` green. **Step 5:** Commit `feat(fluent): generated fluent extensions for pilot classes with opt-in barrel`

### Task 4: Enforcement + CI regeneration gate

**Files:**
- Create: `tool/surface_gen/lib/src/enforcement.dart` + `tool/surface_gen/test/enforcement_test.dart`
- Create: `test/meta/surface_enforcement_test.dart` (package-level: runs the check against the real barrel)
- Modify: `.github/workflows/package-quality.yml` (after `flutter pub get`, before analyze: `dart run build_runner build --delete-conflicting-outputs` then `git diff --exit-code -- lib/src/fluent/generated lib/src/ai/generated` with an explanatory failure message)

Enforcement rule (from spec): every class reachable from `lib/braven_charts.dart` with a const unnamed constructor AND an instance `copyWith` method must carry `@chartSurface` or `@ChartSurfaceExempt(reason)`. In Slice 1 the check runs in REPORT mode: it asserts the three pilots are annotated and emits the full un-annotated list as a skip-with-message (promoted to hard failure in Task 6 when the fleet is annotated).

- [ ] Steps: failing enforcement unit tests (fixture: annotated passes, exempt passes, bare config fails, non-config class ignored) → implement → package-level test green in report mode → CI workflow edit → commit `feat(surface-gen): enforcement check and CI regeneration gate`

**SLICE 1 GATE:** generator suite green; pilots' fluent API compiles + behaves; CI regenerates cleanly; full package suite at baseline + new tests. Independent review before Slice 2 (overseer dispatches).

### Task 4b: Engine review fixups (post-review, before the fleet)

The independent review proved empirically that the Task 2–4 engine emitted
uncompilable code once real fleet classes were annotated. Fixed in
`fix(surface-gen): engine review fixups`; the behavioural contract is recorded
in the spec (verb vocabulary, nested updaters, sealed rule, `presetFactories`)
and in the library dartdocs of `surface_reader.dart` / `fluent_emitter.dart`.
What Task 5/6 must know:

- `clearFlags` metadata is now an OVERRIDE — the reader derives `clearFoo`
  from the class's own `copyWith` signature. Do not hand-transcribe the 119
  flags.
- `combinedSetters` metadata is now MANDATORY wherever the constructor
  asserts a relationship between two or more parameters; the reader refuses
  to model the class otherwise, with a named diagnostic that suggests the
  exact `CombinedSetter(...)` literal. The audit tool
  `dart run tool/surface_gen/bin/assert_audit.dart lib/src` lists them; the
  config-shaped ones as of this lane are:

  | class | coupled parameters |
  |---|---|
  | `CandlestickChartStyle` | maxBodyWidth, minBodyWidth |
  | `ChartOverlayActionButtonConfig` | buttonSize, iconSize |
  | `ChordAnnotation` | endIndex, startIndex |
  | `ErrorBarDatum` | xNegative, xPositive · yNegative, yPositive |
  | `ErrorBarDatum.symmetric` | x, y |
  | `LegendAnnotation` | categoryScale, colorScale, opacityScale, sizeScale |
  | `RangeAnnotation` | endX, startX · endY, startY · startX, startY |
  | `TextAnnotation._internal` | richTextDelta, text |
  | `TrendAnnotation` | trendType, windowSize |
  | `BarChartSeries` | barWidthPercent, barWidthPixels · maxWidth, minWidth |
  | `ScatterColorEncoding` | maximumValue, minimumValue |
  | `ScatterOpacityEncoding` | maximumOpacity, minimumOpacity · maximumValue, minimumValue |
  | `ScatterSizeEncoding` | maximumRadius, minimumRadius · maximumValue, minimumValue |
  | `ScatterBinConfig` | maximumOpacity, minimumOpacity |
  | `ScatterClusterConfig` | maximumRadius, minimumRadius |
  | `ScatterDensityConfig` | maximumOpacity, minimumOpacity |
  | `XAxisConfig` | max, min · maxHeight, minHeight |
  | `YAxisConfig` | max, min · maxWidth, minWidth |
  | `GridStyle` | minorColor, minorWidth, showMinor |
  | `DataRange` | max, min |
  | `BarGroupInfo` | count, index |
  | `ChartXViewport` | max, min |
  | `LinearScale` | dataMax, dataMin · pixelMax, pixelMin |
  | `ChartTransform` | dataXMax, dataXMin · dataYMax, dataYMin |
  | `ChartDataTable` | errorMessage, isLoading, model |
  | `ElementData` | dataPoints, dataRect |
  | `CandlestickProjection` | sourceEndIndexExclusive, sourceStartIndex |

  (The last eight are internal/render types unlikely to be annotated; listed
  for completeness — 38 multi-parameter asserts across 28 constructors.)
- `ChartSeries` carries `@ChartSurfaceExempt` (slicing base `copyWith`); only
  the concrete series types are modelled. Any other class whose `copyWith` is
  inherited and base-typed must be exempted or given a real `copyWith`.
- Annotating a class the public barrel does not export FAILS the build.
- `lib/braven_charts_fluent.dart` is GENERATED — never hand-edit it, and add
  it to any CI regenerate-and-diff path list.
- Task 6's exhaustive smoke test must call `withoutX`, not `clearX`, for
  tri-state fields.

---

## SLICE 2 — full surface annotation + fluent fleet

### Task 5: Annotate series, axes, interaction configs (~40 classes)

**Files:** Modify `lib/src/models/chart_series.dart`, `x_axis_config.dart`, `y_axis_config.dart`, `category_axis_config.dart`, `interaction_config.dart`, `cartesian_value_summary_config.dart`, scatter/candlestick/bar model files; regenerate `lib/src/fluent/generated/*` (the fluent barrel regenerates itself).
**Metadata obligations:** the `CombinedSetter` checklist in Task 4b — every coupled pair is a hard build failure until covered; YAxisConfig annotated on its const `_internal` pathway (reader selects it automatically); ScatterChartSeries needs NO `clearFlags` (derived from `copyWith`); CartesianValueSummaryConfig `sealedVariants` on the Presentation/Content sealed bases (callbacks and controllers are auto-excluded, so `excluded:` is only for genuinely internal params).
**Proven ahead of time:** a scratch copy with 30 of the hardest fleet classes annotated (ChartTheme, InteractionConfig/TooltipConfig/CrosshairStyle/TooltipStyle, Scatter/Area/Bar/Candlestick/Pie series, X/YAxisConfig, AutoScroll/Streaming, PathAnimationStyle, PolarChartConfig, AnnotationTheme/SeriesTheme/AxisStyle/GridStyle, Candlestick/ChartDataPoint, CartesianValueSummaryConfig + both sealed bases, ScatterMarkerStyle + its 3 encodings, LegendStyle) generated 21 files and analyzed clean.

- [ ] Steps: annotate file-by-file, regenerate, extend `test/fluent/fluent_behavior_matrix_test.dart` (per class: one withX equality case, every clearX/tri-state verb, combined setters, one 3-step chain) → analyze + full suite green → commit per file group (3 commits max) `feat(fluent): annotate <group> surface`

### Task 6: Annotate styles/themes/annotations/radial remainder (~50 classes) + enforcement promotion

**Files:** remaining models+theming files (Pie/Donut/Polar/Radial styles, ChartTheme + 13 component themes, AnnotationStyle + concrete annotations, TooltipStyle, CartesianNavigatorStyle, etc.); regenerate; `test/meta/surface_enforcement_test.dart` flips report mode → hard assertion (zero unannotated, zero unexempted); exhaustive smoke test `test/fluent/fluent_smoke_generated_test.dart` (generated by the same builder: invokes every generated method once with a type-appropriate literal — compilation is the assertion).

- [ ] Steps: annotate → regenerate → smoke-generation emitter addition → enforcement promoted → full gates (analyze, package suite, example suite untouched-but-run) → commit `feat(fluent): complete generated fluent surface with enforcement`

**SLICE 2 GATE:** enforcement hard; whole-surface fluent barrel compiles; suite green.

---

## SLICE 3 — AI schema convergence

### Task 7: AiSchemaEmitter + superset gate + swap

**Files:**
- Create: `tool/surface_gen/lib/src/ai_schema_emitter.dart` (+ snapshot tests), generated `lib/src/ai/generated/chart_tool_schema_generated.dart`
- Modify: `lib/src/ai/chart_tool_schema.dart` — public members (`createChartTool`, `modifyChartTool`, any exposed maps) become getters returning the generated maps; delete the hand-written literals.
- Test: `test/unit/ai/chart_tool_schema_superset_test.dart` — SNAPSHOT the pre-change schema maps (capture in Step 1 to a fixture JSON before any swap), then assert generated ⊇ snapshot for all overlapping definition paths, and assert value-summary/navigator surfaces (the known drift) are now present.

- [ ] Steps: capture fixture snapshot FIRST (from current master schema at runtime, dumped to `test/unit/ai/fixtures/pre_convergence_schema.json`) → emitter snapshot tests (schema shape rules: enums as enum lists, nested configs as $defs refs, tri-state as {value|none|inherit} union, function/controller params omitted, defaults annotated) → implement → swap internals → superset test green + ENTIRE existing AI-lane suite green (`test/unit/ai/`) → full gates → commit `feat(ai): generate tool schema from surface model with superset gate`

### Task 8: Drift tests for the remaining mirrors

**Files:** Create `test/meta/mirror_drift_test.dart` — from the SurfaceModel (exposed via a generated manifest `lib/src/meta/generated/surface_manifest.dart`: class name → param names list): (a) hard: every surface class present in AI schema; (b) warning-mode (expect+skip pattern printing the gap list): AI builder `_parse*` coverage per class param list; (c) warning-mode: Source emitter `_emit*` coverage. Manifest emitter added to surface_gen.

- [ ] Steps: manifest emitter snapshot test → implement → drift tests (a) hard-green, (b)/(c) reporting real current gaps as skips with counts → commit `feat(surface-gen): surface manifest and mirror drift detection`

**SLICE 3 GATE:** schema generated + superset-proven; AI tests green; drift visibility live. Independent review (overseer dispatches).

---

## SLICE 4 — GoG spec core + facade

### Task 9: Spec model (marks, channels, plot spec — no lowering)

**Files:** Create `lib/src/grammar/mark.dart`, `lib/src/grammar/channel.dart`, `lib/src/grammar/plot_spec.dart`; export from core barrel under a `// Grammar` section. Test `test/unit/grammar/plot_spec_test.dart`.

**Interfaces (complete public contract):**

```dart
typedef FieldAccessor<T, V> = V Function(T row);

class Channel<T> {
  const Channel(this.accessor, {this.label, this.scale});
  final FieldAccessor<T, num> accessor; final String? label; final ChannelScale? scale;
}
class CategoryChannel<T> {
  const CategoryChannel(this.accessor, {this.label});
  final FieldAccessor<T, Object> accessor; final String? label;
}
enum ChannelScale { linear, sqrt }   // scatter size semantics available today

sealed class Mark<T> { const Mark({this.id, this.name, this.color, this.yAxisId});
  final String? id; final String? name; final Color? color; final String? yAxisId; }

final class LineMark<T> extends Mark<T> { const LineMark({required this.x, required this.y,
  super.id, super.name, super.color, super.yAxisId, this.strokeWidth, this.dashPattern, this.interpolation});
  final FieldAccessor<T, num> x; final FieldAccessor<T, num> y;
  final double? strokeWidth; final List<double>? dashPattern; final LineInterpolation? interpolation; }
final class AreaMark<T> extends Mark<T> { /* x, y, + baseline?, opacity? — same pattern */ }
final class BarMark<T> extends Mark<T> { /* x, y, + layout hints available on BarChartSeries */ }
final class ScatterMark<T> extends Mark<T> { /* x, y, + size/colorBy/opacityBy Channel<T>?, categoryBy CategoryChannel<T>?, markerShape? */ }
final class CandlestickMark<T> extends Mark<T> { /* x, open, high, low, close accessors, + timestamp? */ }
final class TrendMark<T> extends Mark<T> { /* sourceMarkId, method (linear/loess), band? — lowers to trend annotation */ }

class PlotSpec<T> { const PlotSpec({required this.data, required this.marks, this.transposed = false,
  this.theme, this.interaction, this.xAxis, this.yAxes = const <YAxisConfig>[]});
  final List<T> data; final List<Mark<T>> marks; final bool transposed; final ChartTheme? theme;
  final InteractionConfig? interaction; final XAxisConfig? xAxis; final List<YAxisConfig> yAxes; }
```

- [ ] Steps: failing model tests (const-ness, equality where valuable, exhaustive sealed switch guard) → implement → green → commit `feat(grammar): typed mark and plot spec model`

### Task 10: Lowering + config-equality parity

**Files:** Create `lib/src/grammar/plot_lowering.dart` (`LoweredPlot lower<T>(PlotSpec<T> spec)` where `LoweredPlot{List<ChartSeries> series; List<ChartAnnotation> annotations; XAxisConfig? xAxis; List<YAxisConfig> yAxes; InteractionConfig interaction; ChartTheme? theme}`), diagnostics `lib/src/grammar/grammar_diagnostics.dart` (`GrammarSpecException` with named codes, fail-fast style matching `ChartConfigBuilder`). Test `test/unit/grammar/plot_lowering_parity_test.dart`.

Lowering rules (each parity-tested against a hand-built equivalent): mark → family series with materialized `ChartDataPoint`s (scatter channels → magnitude/colorValue/opacityValue/categoryValue + encodings constructed with matching scale types; candlestick accessors → CandlestickDataPoint); mark ids default `mark-<index>`; multi-mark → multi-series with multi-axis path ONLY (never the legacy single-axis path — every lowered chart supplies explicit `yAxes`, defaulting to one `YAxisConfig` when unspecified); TrendMark → trend annotation referencing the lowered source series id; validation: TrendMark unknown sourceMarkId, duplicate mark ids, empty marks, empty data → named GrammarSpecException codes.

- [ ] Steps: parity tests FIRST (≥12 cases: each mark family solo, multi-series mixed, multi-axis with yAxisId, transposed, scatter full channels, trend, each validation error) → implement lowering → green → commit `feat(grammar): plot lowering with config-equality parity`

### Task 11: BravenPlot widget + artifact-equality + Workbench/Source proof

**Files:** Create `lib/src/grammar/braven_plot.dart` (`class BravenPlot<T> extends StatelessWidget` building `BravenChartPlus` from `lower(spec)`; passes through controller/workbench-relevant params it must expose: `bravenChartController`, `interactionGroupController`, key). Tests `test/widgets/braven_plot_test.dart` + artifact-equality additions to the parity suite (extract artifact document from a spec-built chart and a hand-built chart via the existing extractor; assert document equality) + one Workbench mode round-trip and one generated-Source compile case reusing existing harnesses.

- [ ] Steps: failing widget/parity tests → implement → green + full suite → commit `feat(grammar): BravenPlot widget with artifact parity`

### Task 12: Chained facade

**Files:** Create `lib/src/grammar/chart_builder.dart`. Test `test/unit/grammar/chart_builder_test.dart`.

**Interfaces (complete facade contract):**

```dart
final class BravenChart<T> {
  static BravenChart<T> of<T>(List<T> rows);
  BravenChart<T> x(FieldAccessor<T, num> accessor, {String? label});      // default X for subsequent geoms
  BravenChart<T> y(FieldAccessor<T, num> accessor, {String? label});      // default Y
  BravenChart<T> geomLine({FieldAccessor<T, num>? x, y, String? name, Color? color, double? strokeWidth, List<double>? dashPattern, LineInterpolation? interpolation, String? yAxisId});
  BravenChart<T> geomArea({...same defaulting...});
  BravenChart<T> geomBar({...});
  BravenChart<T> geomPoint({FieldAccessor<T, num>? x, y, Channel<T>? size, colorBy, opacityBy, CategoryChannel<T>? categoryBy, SeriesMarkerShape? shape, double? opacity, String? name, String? yAxisId});
  BravenChart<T> geomCandlestick({required FieldAccessor<T, num> open, high, low, close, FieldAccessor<T, num>? x});
  BravenChart<T> trend({String? of, TrendMethod method = TrendMethod.linear});
  BravenChart<T> transposed();
  BravenChart<T> theme(ChartTheme theme);
  BravenChart<T> interaction(InteractionConfig config);
  BravenChart<T> xAxis(XAxisConfig config);
  BravenChart<T> yAxis(YAxisConfig config);                                // repeatable
  PlotSpec<T> toSpec();                                                    // for tests/tools
  Widget build({Key? key});                                                // BravenPlot(spec)
}
```

Immutable: every method returns a new instance; `geom*` without explicit accessors uses the chain's defaults or throws `GrammarSpecException.missingEncoding` at that call (fail-fast, not at build).

- [ ] Steps: failing tests (facade-built `toSpec()` equals hand-built PlotSpec across all geoms; default x/y inheritance; missing-encoding error; immutability; `build()` widget pumps and paints) → implement (zero lowering logic — only spec construction) → green → commit `feat(grammar): chained BravenChart facade`

**SLICE 4 GATE:** parity matrix green (config + artifact); facade equivalence proven; full gates. Independent review (overseer dispatches).

---

## SLICE 5 — showcase, docs, release gates

### Task 13: "Chart Grammar" showcase page — USER CHECKPOINT

**Files:** Create `example/lib/showcase/pages/chart_grammar_page.dart`; modify `example/lib/showcase/showcase_app.dart` (NavDestination after Tracking & Value Display; label 'Chart Grammar', slug 'chart-grammar', icon Icons.auto_awesome_motion or similar); test `example/test/showcase/chart_grammar_page_test.dart`; `example/README.md` row.

Content: presets authored ONLY through the chained facade (Line+Trend, Multi-axis, Scatter channels, Candlestick, Bar transposed), each shown in a Workbench (Chart/Data/Split/Source) so the Source tab proves spec-built charts emit ordinary config Dart; an authoring-code card showing the exact facade chain for the active preset (const string, kept adjacent to the preset definition — a comment marks them as paired); options: preset picker + StandardChartOptions + a "compare hand-built" toggle that swaps in the hand-built equivalent chart and asserts-by-eye identical rendering. All controls wired on all presets per repo rule.

- [ ] Steps: failing page tests → implement → example gates green → commit `feat(showcase): chart grammar page` → **launch `flutter run -d chrome --web-port 8090` for the user checkpoint.**

### Task 14: Docs + CHANGELOG + release gates

**Files:** Create `doc/chart_grammar.md` (guide: fluent layer, tri-state verbs, spec classes, facade, lowering guarantees, v2 deferrals); modify `README.md` doc index, `doc/feature_matrix.md`, `CHANGELOG.md` Unreleased (fluent barrel, @chartSurface engine, generated AI schema, BravenPlot/BravenChart).

- [ ] Steps: docs → full release gates (analyze lib; full package suite; example suite; `flutter test test/golden/` zero drift; `dart pub publish --dry-run` — confirm tool/surface_gen and generated headers don't break packaging; verify `braven_charts_fluent.dart` present in the archive) → commit `feat(docs): chart grammar guide and changelog` → **final user checkpoint → PR on approval.**

**LANE DONE per spec success criteria 1–6.**
