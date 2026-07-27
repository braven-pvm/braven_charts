# Grammar Multi-Series Polar + Radial Config Passthrough — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the workbench Grammar Source pane emit a faithful `BravenChart.of(rows)….build()` chain for every Polar Column presentation (standard/rose/layered/grouped/stacked/references/intervals) and for non-default `ConcentricDonutConfig` donuts.

**Architecture:** Multiple `geomPolar` marks per spec (the one-radial-geom rule relaxes for the polar family only); plot-level `PolarChartConfig` lives on `PlotSpec` and is set with `.polarConfig(...)`; per-series polar data (`columnColor`/`target`/`intervals`) becomes row-channels on `PolarMark`, and per-series/plot config objects ride the mark/spec. The source emitter reverses N `PolarColumnChartSeries` → N `geomPolar` marks + `.polarConfig(...)`, proving fidelity by re-lowering (the existing `_firstRadialMismatch` already does full-config equality; the fix is that lowering now *carries* the config so the re-lowered plot matches).

**Tech Stack:** Dart ≥3.9, Flutter; `flutter test`; `flutter analyze lib` (never root — vendored `packages/fleather` pollutes root analyze).

## Global Constraints

- Work only in worktree `F:\Repositories\braven_charts-radial-polar`, branch `feature/grammar-radial-polar` (off `origin/master` `a811dcef`). PR to master only on the owner's explicit go-ahead.
- **Marks hold functions and config objects only** — no `copyWith`, no `@chartSurface` on marks. The four config classes (`PolarChartConfig`, `PolarColumnTargetMarkerStyle`, `PolarColumnIntervalStyle`, `ConcentricDonutConfig`) are already `@chartSurface`-gated; **add no new drift-gate surface**.
- **Reuse the config emitter's literal renderers** through public seams (the 1a pattern: `emitPolarColumnStyle(writer, argument, style)` at `chart_config_dart_emitter.dart:213`). Do not reimplement any literal rendering.
- **Byte-identical invariants:** Cartesian emission, and existing pie/donut/concentric/**single-polar** emission, and every existing golden, must be unchanged. Verify with the drift gates in `test/meta/` and the existing emitter tests.
- `PlotSpec.polar` must be added to `PlotSpec` constructor, `facetCleared()`, `==`, and `hashCode`.
- **Preserve the `chart_builder.dart` NUL sentinel** in `_defaultYKey`: after editing, the file must contain exactly 1 NUL byte, 0 CRLF, no BOM. Verify with the check in Task A1 Step 6.
- Every commit message ends with the trailer:
  `Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>`
- Stage with **specific `git add <paths>`** — never `git add -A`, never stage `example/windows/flutter/*` or `.gradle/*`.
- After each task: `flutter analyze lib` clean, `flutter analyze example/lib` clean, full `flutter test` green, drift gates green.

## File Structure

- `lib/src/grammar/plot_spec.dart` — add `PlotSpec.polar` (plot-level polar config) + threading.
- `lib/src/grammar/chart_builder.dart` — `.polarConfig(...)` verb; new `geomPolar`/`geomDonut` params. (NUL sentinel.)
- `lib/src/grammar/mark.dart` — `PolarMark` (+6 fields), `DonutMark` (+`concentric`).
- `lib/src/grammar/plot_lowering.dart` — `_lowerRadial` multi-polar branch + spec-config; `_lowerPolar` new channels/preset; concentric precedence.
- `lib/src/grammar/grammar_diagnostics.dart` — repurpose `multipleRadialGeoms`; add `polarConfigOnNonPolarSpec`, `conflictingConcentricCenter`, `incompletePolarInterval`.
- `lib/src/source/chart_grammar_source_generator.dart` — new `_PolarChartPlan` + `_planPolarChart` + `_emitPolarChartBody`; `_tryEmitRadialChain` routing + proof-spec config; `_planDonut`/`_planConcentric` concentric carry; file-header matrix.
- `lib/src/source/chart_config_dart_emitter.dart` — new public seams `emitPolarChartConfig`, `emitConcentricDonutConfig`, `emitPolarTargetMarkerStyle`, `emitPolarIntervalStyle`, `emitPolarColumnColor` helper.
- Tests: `test/unit/grammar/plot_lowering_radial_test.dart` (or the existing radial lowering test file), `test/unit/grammar/grammar_diagnostics_test.dart`, `test/unit/source/chart_grammar_source_generator_test.dart`.

---

## Slice A — Multi-geom polar structural

Makes layered/grouped/stacked + custom-`PolarChartConfig` polar charts emit + round-trip. (Single-polar already emits from 1a; this adds N marks + spec config.)

### Task A1: `PlotSpec.polar` + `.polarConfig()` verb

**Files:**
- Modify: `lib/src/grammar/plot_spec.dart:41-172`
- Modify: `lib/src/grammar/chart_builder.dart` (near `xAxis`/`grid` verbs at `:649`/`:695`)
- Test: `test/unit/grammar/plot_spec_test.dart` (add), `test/unit/grammar/chart_builder_test.dart` (add)

**Interfaces:**
- Produces: `PlotSpec<T>.polar` (`final PolarChartConfig? polar`); `BravenChart<T>.polarConfig(PolarChartConfig config)` → sets `PlotSpec.polar`.

- [ ] **Step 1: Write the failing test — `PlotSpec.polar` equality + facetCleared carry**

In `test/unit/grammar/plot_spec_test.dart`:

```dart
test('polar config participates in equality and survives facetCleared', () {
  const polar = PolarChartConfig(
    composition: PolarColumnCompositionConfig(
      mode: PolarColumnCompositionMode.grouped,
    ),
  );
  final a = PlotSpec<num>(
    data: const [1],
    marks: [PolarMark<num>(category: (r) => r, value: (r) => r)],
    polar: polar,
  );
  final b = PlotSpec<num>(
    data: const [1],
    marks: [PolarMark<num>(category: (r) => r, value: (r) => r)],
  );
  expect(a == b, isFalse);
  expect(a.facetCleared().polar, same(polar));
});
```

- [ ] **Step 2: Run it — expect FAIL** (`No named parameter 'polar'`).
  Run: `flutter test test/unit/grammar/plot_spec_test.dart`

- [ ] **Step 3: Add the field + threading** in `plot_spec.dart`:
  - Constructor (`:41-54`): add `this.polar,` after `this.facet,` (or grouped with the chart-level options).
  - Field: after `grid` (`:95`), add:
    ```dart
    /// Optional plot-level polar configuration, shared across every polar mark.
    ///
    /// Null lowers to `const PolarChartConfig()`. Non-null is honored only when
    /// the spec's radial marks are all `PolarMark`s; setting it on any other
    /// spec raises `GrammarDiagnosticCode.polarConfigOnNonPolarSpec`.
    final PolarChartConfig? polar;
    ```
  - `facetCleared()` (`:121-133`): add `polar: polar,`.
  - `==` (`:141-156`): add `&& other.polar == polar`.
  - `hashCode` (`:158-172`): add `polar,` to the `Object.hash(...)` args.
  - Import `PolarChartConfig` if not already visible (check existing imports; `plot_lowering.dart` already references it, so the models are exported — confirm `plot_spec.dart` imports the config models barrel or add the import).

- [ ] **Step 4: Run it — expect PASS.**

- [ ] **Step 5: Write the failing test — `.polarConfig()` verb**

In `test/unit/grammar/chart_builder_test.dart`:

```dart
test('.polarConfig sets PlotSpec.polar', () {
  const polar = PolarChartConfig(
    pane: PolarPaneConfig(startAngleDegrees: -45),
  );
  final spec = BravenChart.of(const [1, 2, 3])
      .geomPolar(category: (r) => r, value: (r) => r)
      .polarConfig(polar)
      .toSpec();
  expect(spec.polar, same(polar));
});
```
(If the builder exposes no `toSpec()`, assert via lowering instead: build → lower → check `lowered.polarChartConfig == polar`. Confirm the builder's spec accessor name before writing; `chart_builder.dart` uses an internal `_spec`/`_copy` — check for a public test seam and match it.)

- [ ] **Step 6: Run it — expect FAIL**, then add the verb in `chart_builder.dart` beside `grid` (`:695`):
  ```dart
  /// Sets the plot-level polar configuration shared by every polar mark.
  BravenChart<T> polarConfig(PolarChartConfig config) => _copy(polar: config);
  ```
  Add `PolarChartConfig? polar` to the private `_copy(...)` signature and pass it into the `PlotSpec(...)` it builds (mirror how `_copy` threads `grid`). **After editing, verify the NUL sentinel:**
  ```bash
  python -c "import pathlib; b=pathlib.Path('lib/src/grammar/chart_builder.dart').read_bytes(); print('NUL',b.count(0),'CRLF',b.count(b'\r\n'),'BOM',b[:3]==b'\xef\xbb\xbf')"
  ```
  Expected: `NUL 1 CRLF 0 BOM False`.

- [ ] **Step 7: Run it — expect PASS**, then `flutter analyze lib` + `flutter analyze example/lib`.

- [ ] **Step 8: Commit**
  ```bash
  git add lib/src/grammar/plot_spec.dart lib/src/grammar/chart_builder.dart test/unit/grammar/plot_spec_test.dart test/unit/grammar/chart_builder_test.dart
  git commit -m "feat(grammar): add PlotSpec.polar + .polarConfig verb"
  ```

### Task A2: `_lowerRadial` multi-polar branch + diagnostics

**Files:**
- Modify: `lib/src/grammar/plot_lowering.dart:909-1008`
- Modify: `lib/src/grammar/grammar_diagnostics.dart` (enum `:87`, factory near `:318`)
- Test: `test/unit/grammar/plot_lowering_radial_test.dart`, `test/unit/grammar/grammar_diagnostics_test.dart`

**Interfaces:**
- Consumes: `PlotSpec.polar` (Task A1).
- Produces: `_lowerRadial` accepts N `PolarMark`s → N `PolarColumnChartSeries` + `polar = spec.polar ?? const PolarChartConfig()`; `GrammarSpecException.polarConfigOnNonPolarSpec()`; repurposed `multipleRadialGeoms` (fires only when >1 radial and not all polar).

- [ ] **Step 1: Add the diagnostic code + factory**

In `grammar_diagnostics.dart` enum (after `multipleRadialGeoms` `:87`):
```dart
/// `.polarConfig(...)` was set on a spec whose radial mark is not a PolarMark.
polarConfigOnNonPolarSpec,
```
Factory (after `multipleRadialGeoms` factory `:324`):
```dart
/// `.polarConfig(...)` set on a non-polar radial spec.
factory GrammarSpecException.polarConfigOnNonPolarSpec(String markId) =>
    GrammarSpecException(
      GrammarDiagnosticCode.polarConfigOnNonPolarSpec,
      'A PolarChartConfig was set, but the radial mark "$markId" is not a '
      'polar-column geom. Remove .polarConfig(...), or author the chart with '
      'geomPolar(...).',
    );
```

- [ ] **Step 2: Write the failing test — layered polar lowers to N series + carries config**

```dart
test('two polar marks lower to two PolarColumnChartSeries with the config', () {
  const polar = PolarChartConfig(
    composition: PolarColumnCompositionConfig(
      mode: PolarColumnCompositionMode.layered,
    ),
  );
  final spec = PlotSpec<_Row>(
    data: const [_Row('A', 1, 4), _Row('B', 2, 5)],
    marks: [
      PolarMark<_Row>(id: 'cap', name: 'Capacity',
          category: (r) => r.cat, value: (r) => r.a),
      PolarMark<_Row>(id: 'obs', name: 'Observed',
          category: (r) => r.cat, value: (r) => r.b),
    ],
    polar: polar,
  );
  final lowered = spec.lower();
  expect(lowered.series, hasLength(2));
  expect(lowered.series.every((s) => s is PolarColumnChartSeries), isTrue);
  expect(lowered.polarChartConfig, polar);
});
```
(Define a `_Row(this.cat, this.a, this.b)` test fixture in the test file.)

- [ ] **Step 3: Run it — expect FAIL** (throws `multipleRadialGeoms`).

- [ ] **Step 4: Implement the multi-polar branch** in `_lowerRadial` (`plot_lowering.dart:909`):

Replace the `radialIndices.length > 1` guard (`:914-918`) and the `.single` assumption with:
```dart
// Multiple radial marks are legal ONLY when every one is a polar column.
final radialMarks = [for (final i in radialIndices) spec.marks[i] as RadialMark<T>];
final allPolar = radialMarks.every((m) => m is PolarMark<T>);
if (radialIndices.length > 1 && !allPolar) {
  throw GrammarSpecException.multipleRadialGeoms(
    [for (final i in radialIndices) markIds[i]],
  );
}
```
Keep the `mixedCoordinateSystems` check but compute it against the FIRST radial mark index when multiple (a radial + Cartesian mix). Keep the Cartesian-option guards (`transposed`/`xAxis`/`yAxes`/`grid`, `:934-945`) — they run once for the whole spec.

Add the polar-config-placement guard after those:
```dart
if (spec.polar != null && !allPolar) {
  throw GrammarSpecException.polarConfigOnNonPolarSpec(markIds[radialIndices.first]);
}
```

Replace the single-mark dispatch (`:961-992`) so that when `allPolar`:
```dart
if (allPolar) {
  final series = <ChartSeries>[
    for (var k = 0; k < radialIndices.length; k++)
      _lowerPolar<T>(
        spec.marks[radialIndices[k]] as PolarMark<T>,
        markIds[radialIndices[k]],
        spec.data,
      ),
  ];
  return LoweredPlot(
    series: series,
    annotations: const <ChartAnnotation>[],
    xAxis: null,
    yAxes: const <YAxisConfig>[],
    interaction: spec.interaction ?? const InteractionConfig(),
    theme: spec.theme,
    grid: null,
    title: spec.title,
    subtitle: spec.subtitle,
    showLegend: spec.showLegend,
    concentricDonutConfig: null,
    polarChartConfig: spec.polar ?? const PolarChartConfig(),
  );
}
```
Keep the existing single-mark pie/donut/concentric path for the `!allPolar` (length == 1) case (its `markIndex = radialIndices.single` still holds because a single non-polar radial mark reaches here). Note the empty-category guard (`:950-955`) must run for each polar mark — move it into `_lowerPolar` or loop it for all polar marks before building series.

- [ ] **Step 5: Run it — expect PASS.** Add + run tests for the two diagnostics:
```dart
test('polarConfig on a pie spec throws polarConfigOnNonPolarSpec', () {
  final spec = PlotSpec<num>(
    data: const [1],
    marks: [PieMark<num>(category: (r) => r, value: (r) => r)],
    polar: const PolarChartConfig(),
  );
  expect(() => spec.lower(),
      throwsA(isA<GrammarSpecException>().having((e) => e.code, 'code',
          GrammarDiagnosticCode.polarConfigOnNonPolarSpec)));
});
test('a pie and a donut mark throw multipleRadialGeoms', () {
  final spec = PlotSpec<num>(data: const [1], marks: [
    PieMark<num>(id: 'p', category: (r) => r, value: (r) => r),
    DonutMark<num>(id: 'd', category: (r) => r, value: (r) => r),
  ]);
  expect(() => spec.lower(),
      throwsA(isA<GrammarSpecException>().having((e) => e.code, 'code',
          GrammarDiagnosticCode.multipleRadialGeoms)));
});
```

- [ ] **Step 6: Run the full suite** to confirm no radial regression: `flutter test test/unit/grammar/`. Then `flutter analyze lib`.

- [ ] **Step 7: Commit**
  ```bash
  git add lib/src/grammar/plot_lowering.dart lib/src/grammar/grammar_diagnostics.dart test/unit/grammar/plot_lowering_radial_test.dart test/unit/grammar/grammar_diagnostics_test.dart
  git commit -m "feat(grammar): lower N polar marks + polarConfigOnNonPolarSpec diagnostic"
  ```

### Task A3: Emitter — reverse N `geomPolar` + `.polarConfig(...)`

**Files:**
- Modify: `lib/src/source/chart_grammar_source_generator.dart` (`_tryEmitRadialChain:624`, `_planRadial:675`, `_planPolar:890`, `_emitRadialBody:1944`, `_emitRadialGeometry:1967`)
- Modify: `lib/src/source/chart_config_dart_emitter.dart` (new seam near `:213`)
- Test: `test/unit/source/chart_grammar_source_generator_test.dart`

**Interfaces:**
- Consumes: multi-polar lowering (A2), `PlotSpec.polar` (A1).
- Produces: a `_PolarChartPlan` (rows + shared `category` field + `List<_PolarSeriesPlan>` + `PolarChartConfig config`); `ChartConfigDartEmitter.emitPolarChartConfig(DartSourceWriter writer, String argument, PolarChartConfig config)`.

Data structures to add (private, in the generator file near `_RadialPlan`):
```dart
class _PolarSeriesPlan {
  _PolarSeriesPlan({required this.value, required this.mark});
  final _Field value;                 // per-series value field
  final PolarMark<_SourceRow> mark;   // reads category (shared) + value
}

class _PolarChartPlan {
  _PolarChartPlan({
    required this.rows,
    required this.category,
    required this.series,
    required this.config,
  });
  final List<_SourceRow> rows;
  final _Field category;              // shared category accessor
  final List<_PolarSeriesPlan> series;
  final PolarChartConfig config;      // configuration.polarChartConfig
}
```

- [ ] **Step 1: Write the failing test — layered polar emits two geomPolar + polarConfig**

```dart
test('a layered polar config emits two geomPolar marks and .polarConfig', () {
  final config = ChartConfiguration(
    series: [
      PolarColumnChartSeries.fromMap(
          id: 'cap', name: 'Capacity',
          values: {'A': 1, 'B': 2},
          polarStyle: const PolarColumnStyle(opacity: 0.32)),
      PolarColumnChartSeries.fromMap(
          id: 'obs', name: 'Observed', values: {'A': 4, 'B': 5}),
    ],
    polarChartConfig: const PolarChartConfig(
      composition: PolarColumnCompositionConfig(
          mode: PolarColumnCompositionMode.layered)),
  );
  final source = ChartGrammarSourceGenerator(configuration: config).generate();
  expect(source.code, isNotNull);
  expect('.geomPolar('.allMatches(source.code!).length, 2);
  expect(source.code, contains('.polarConfig(PolarChartConfig('));
});
```
(Match the real `ChartConfiguration`/`ChartGrammarSourceGenerator` construction used by the existing radial tests in this file — copy their harness.)

- [ ] **Step 2: Run it — expect FAIL** (blocks: "N polar series cannot be reversed").

- [ ] **Step 3: Route all-polar configs to a polar planner.** In `_tryEmitRadialChain` (`:624`), before `_planRadial`, detect all-polar and branch:
```dart
if (series.isNotEmpty && series.every((s) => s is PolarColumnChartSeries)) {
  final polarPlan = _planPolarChart(series.cast<PolarColumnChartSeries>(), block);
  if (polarPlan == null) return null;
  final spec = PlotSpec<_SourceRow>(
    data: polarPlan.rows,
    marks: [for (final s in polarPlan.series) s.mark],
    theme: configuration.theme,
    interaction: configuration.interaction,
    title: configuration.title,
    subtitle: configuration.subtitle,
    showLegend: configuration.showLegend,
    polar: polarPlan.config,     // <-- the proof re-lowers WITH the config
  );
  final LoweredPlot lowered;
  try { lowered = spec.lower(); }
  on GrammarSpecException catch (error) { /* same block() as existing */ return null; }
  final mismatch = _firstRadialMismatch(lowered);
  if (mismatch != null) { /* same block() as existing */ return null; }
  _captureKnownLimitations();
  return _emitPolarChartBody(polarPlan);
}
```
Leave the existing pie/donut/concentric/single-polar `_planRadial` path untouched below this branch. (Single polar now also flows through `_planPolarChart`, which handles length 1 identically — one series, one mark. Remove the `series.length != 1` polar guard at `:692-700` since it's superseded; the pie/donut single-only guards stay.)

- [ ] **Step 4: Implement `_planPolarChart`.** Build union-of-categories rows (first-seen order across all series), one shared `category` field, and one `value` field per series:
```dart
_PolarChartPlan? _planPolarChart(
  List<PolarColumnChartSeries> series,
  void Function(String message, {String? path}) block,
) {
  final category = _addField('category', _FieldKind.string);
  // Union of categories in first-seen order (point.label).
  final order = <String>[];
  final seen = <String>{};
  for (final s in series) {
    for (final p in s.points) {
      final key = p.label ?? '';
      if (seen.add(key)) order.add(key);
    }
  }
  final rows = _synthesiseRadialRows(order.length);
  final rowOf = {for (final (i, k) in order.indexed) k: i};
  for (final (i, key) in order.indexed) rows[i].strings[category.slot] = key;

  final plans = <_PolarSeriesPlan>[];
  for (final s in series) {
    final value = _addField('value', _FieldKind.number);
    for (final p in s.points) {
      rows[rowOf[p.label ?? '']!].numbers[value.slot] = p.y;
    }
    plans.add(_PolarSeriesPlan(
      value: value,
      mark: PolarMark<_SourceRow>(
        id: s.id,
        name: s.name,
        color: s.color,
        unit: s.unit,
        category: _string(category),
        value: _number(value),
        style: s.polarStyle,
        selectionStyle: s.selectionStyle,
        // advanced per-series fields (columnColor/target/intervals/preset)
        // are added in Slice B; here only style/selection/color/unit ride.
      ),
    ));
  }
  return _PolarChartPlan(
    rows: rows, category: category, series: plans,
    config: configuration.polarChartConfig ?? const PolarChartConfig(),
  );
}
```
Note: `_addField`/`_synthesiseRadialRows`/`_string`/`_number` are the existing helpers used by `_planPolar` (`:890`). Because every series reads its own value field and the shared category, N marks over the shared rows re-lower to N series; a series missing a union category re-lowers with that category → the round-trip proof refuses it honestly (matched-category showcase charts emit).

- [ ] **Step 5: Implement `_emitPolarChartBody`** (mirror `_emitRadialBody:1944`, looping marks + emitting `.polarConfig`):
```dart
String _emitPolarChartBody(_PolarChartPlan plan) {
  final writer = DartSourceWriter();
  _emitRowClass(writer);
  writer.writeLine();
  _emitRows(writer, plan.rows);
  writer.writeLine();
  writer.writeLine(
    'final ${options.variableName} = BravenChart.of(${options.rowsVariableName})',
  );
  writer.indented(() {
    writer.indented(() {
      for (final s in plan.series) {
        _emitPolarGeometry(writer, plan.category, s);
      }
      if (plan.config != const PolarChartConfig()) {
        writer.writeLine('.polarConfig(');
        writer.indented(() {
          _config.emitPolarChartConfig(writer, /*argument*/ null, plan.config);
        });
        writer.writeLine(')');
      }
      _emitTheme(writer);
      _emitInteraction(writer);
      _emitTitle(writer);
      _emitLegend(writer);
      writer.writeLine('.build();');
    });
  });
  return writer.toString();
}
```
`_emitPolarGeometry(writer, category, seriesPlan)` mirrors the `PolarMark` arm of `_emitRadialGeometry` (`:2035-2041`): `.geomPolar(` + `id`/`category`/`value`/`name`/`color`/`unit` + `style` via `emitPolarColumnStyle` + `selectionStyle` via `emitRadialSelectionStyle`, then `)`. (Slice B extends it.)

- [ ] **Step 6: Add the public seam** `emitPolarChartConfig` in `chart_config_dart_emitter.dart` near the other seams (`:213`). Reuse the private `_emitPolarChartConfig` (`:3078`), but that writes the config-form key `polarChartConfig:`. Refactor `_emitPolarChartConfig` to take an argument label (like `_emitPolarColumnStyleArgument:2700`): extract the body into `_emitPolarChartConfigArgument(writer, String? argument, config)` that writes `<argument>: PolarChartConfig(` when `argument != null`, else `PolarChartConfig(` (bare expression for the grammar `.polarConfig(<expr>)` form). Public seam:
```dart
/// Emits a `PolarChartConfig(...)` literal for the grammar `.polarConfig(...)`
/// form, reusing the config form's rendering so the two cannot disagree.
void emitPolarChartConfig(
  DartSourceWriter writer,
  String? argument,
  PolarChartConfig config,
) => _emitPolarChartConfigArgument(writer, argument, config);
```
Keep the config-form caller (`:265`) calling it with `argument: 'polarChartConfig'`.

- [ ] **Step 7: Run the test — expect PASS.** Then run the FULL emitter test file to prove single-polar/pie/donut/concentric emission is byte-identical:
  Run: `flutter test test/unit/source/chart_grammar_source_generator_test.dart`

- [ ] **Step 8: Run drift gates** — `flutter test test/meta/` — expect all green (the new seam reuses gated renderers; no new surface).

- [ ] **Step 9: `flutter analyze lib` + commit**
  ```bash
  git add lib/src/source/chart_grammar_source_generator.dart lib/src/source/chart_config_dart_emitter.dart test/unit/source/chart_grammar_source_generator_test.dart
  git commit -m "feat(source): reverse N polar series to geomPolar marks + .polarConfig"
  ```

---

## Slice B — Per-series advanced fields (columnColor / target / intervals / rose)

Flips standard/rose/references/intervals to emitted → all 7 presentations.

### Task B1: `PolarMark` advanced fields + `geomPolar` params + `incompletePolarInterval`

**Files:**
- Modify: `lib/src/grammar/mark.dart:1039-1078` (`PolarMark`)
- Modify: `lib/src/grammar/chart_builder.dart:508-528` (`geomPolar`)
- Modify: `lib/src/grammar/grammar_diagnostics.dart`
- Test: `test/unit/grammar/mark_test.dart`, `test/unit/grammar/grammar_diagnostics_test.dart`

**Interfaces:**
- Produces: `PolarMark` fields `columnColor: FieldAccessor<T, Color?>?`, `target: FieldAccessor<T, num?>?`, `targetMarkerStyle: PolarColumnTargetMarkerStyle?`, `intervalLow`/`intervalHigh: FieldAccessor<T, num?>?`, `intervalStyle: PolarColumnIntervalStyle?`, `preset: PolarColumnPreset` (default `standard`); `geomPolar(... rose: bool = false, columnColor, target, targetMarkerStyle, intervalLow, intervalHigh, intervalStyle)`.

- [ ] **Step 1: Write the failing test — the fields exist + equality includes them**

```dart
test('PolarMark carries advanced fields in equality', () {
  final a = PolarMark<num>(
    category: (r) => r, value: (r) => r,
    preset: PolarColumnPreset.rose,
    targetMarkerStyle: const PolarColumnTargetMarkerStyle(width: 3),
  );
  final b = PolarMark<num>(category: (r) => r, value: (r) => r);
  expect(a == b, isFalse);
  expect(a.preset, PolarColumnPreset.rose);
});
```

- [ ] **Step 2: Run — expect FAIL.**

- [ ] **Step 3: Add the fields to `PolarMark`** (`mark.dart:1039`), constructor params (all optional; `preset` defaults to `PolarColumnPreset.standard`), field declarations with doc comments, and extend `==`/`hashCode`/`toString`. Import `Color`, `PolarColumnPreset`, `PolarColumnTargetMarkerStyle`, `PolarColumnIntervalStyle` (from the models barrel already used by `mark.dart` for `PolarColumnStyle`).

- [ ] **Step 4: Run — expect PASS.**

- [ ] **Step 5: Add the `incompletePolarInterval` diagnostic** (enum + factory in `grammar_diagnostics.dart`):
```dart
/// A polar mark supplied only one of the two interval bounds.
incompletePolarInterval,
```
```dart
factory GrammarSpecException.incompletePolarInterval(String markId) =>
    GrammarSpecException(
      GrammarDiagnosticCode.incompletePolarInterval,
      'The polar mark "$markId" set only one interval bound. A polar interval '
      'needs both intervalLow and intervalHigh (or neither).',
    );
```

- [ ] **Step 6: Add the `geomPolar` params** in `chart_builder.dart:508` (pass through to `PolarMark`; map `rose: true` → `preset: PolarColumnPreset.rose`). Preserve the NUL sentinel (re-run the check from Task A1 Step 6). Write a builder test asserting `rose: true` yields `preset == rose` and that setting one interval bound throws `incompletePolarInterval` at lowering (the guard is added in B2 — for now assert the mark stores the accessors).

- [ ] **Step 7: Run tests + `flutter analyze lib` + `flutter analyze example/lib`.**

- [ ] **Step 8: Commit**
  ```bash
  git add lib/src/grammar/mark.dart lib/src/grammar/chart_builder.dart lib/src/grammar/grammar_diagnostics.dart test/unit/grammar/mark_test.dart test/unit/grammar/grammar_diagnostics_test.dart
  git commit -m "feat(grammar): PolarMark advanced fields + geomPolar params"
  ```

### Task B2: `_lowerPolar` builds columnColors/targets/intervals + preset

**Files:**
- Modify: `lib/src/grammar/plot_lowering.dart:1127-1139` (`_lowerPolar`)
- Test: `test/unit/grammar/plot_lowering_radial_test.dart`

**Interfaces:**
- Consumes: `PolarMark` advanced fields (B1).
- Produces: `_lowerPolar` builds `columnColors`/`targets`/`intervals` maps from the accessors over `data`, selects `.rose` vs `.fromMap` by `mark.preset`, passes `targetMarkerStyle`/`intervalStyle`; raises `incompletePolarInterval` when exactly one interval accessor is set.

- [ ] **Step 1: Write the failing test — targets + rose round-trip through lowering**

```dart
test('polar mark with targets + rose lowers to a rose series with targetValues', () {
  final spec = PlotSpec<_Row>(
    data: const [_Row('A', 1, 4), _Row('B', 2, 5)],
    marks: [
      PolarMark<_Row>(
        category: (r) => r.cat, value: (r) => r.a,
        target: (r) => r.b, preset: PolarColumnPreset.rose),
    ],
  );
  final s = spec.lower().series.single as PolarColumnChartSeries;
  expect(s.preset, PolarColumnPreset.rose);
  expect(s.targetValues, [4.0, 5.0]);
});
```

- [ ] **Step 2: Run — expect FAIL.**

- [ ] **Step 3: Implement.** In `_lowerPolar` (`:1127`), before building the series:
  - if exactly one of `mark.intervalLow`/`mark.intervalHigh` is non-null → `throw GrammarSpecException.incompletePolarInterval(id)`.
  - build `columnColors` = `{ for (row in data) if (mark.columnColor?.call(row) case final c?) mark.category(row).toString(): c }` (only when `mark.columnColor != null`).
  - build `targets` = `{ for (row in data) mark.category(row).toString(): mark.target!(row) }` when `mark.target != null` (values are `num?`).
  - build `intervals` = `{ for (row in data) if (both bounds non-null for row) cat: PolarColumnInterval(lower, upper) }` when both accessors set.
  - select factory: `mark.preset == PolarColumnPreset.rose ? PolarColumnChartSeries.rose(...) : PolarColumnChartSeries.fromMap(...)`, passing `columnColors`, `targets`, `targetMarkerStyle: mark.targetMarkerStyle ?? const PolarColumnTargetMarkerStyle()`, `intervals`, `intervalStyle: mark.intervalStyle ?? const PolarColumnIntervalStyle()`, plus the existing `values`/`polarStyle`/`selectionStyle`/`color`/`unit`/`name`.

- [ ] **Step 4: Run — expect PASS.** Add + run an `incompletePolarInterval` lowering test.

- [ ] **Step 5: Full radial suite + `flutter analyze lib`.**

- [ ] **Step 6: Commit**
  ```bash
  git add lib/src/grammar/plot_lowering.dart test/unit/grammar/plot_lowering_radial_test.dart
  git commit -m "feat(grammar): lower polar columnColors/targets/intervals + rose preset"
  ```

### Task B3: Emitter reverses the advanced per-series fields

**Files:**
- Modify: `lib/src/source/chart_grammar_source_generator.dart` (`_planPolarChart`, `_PolarSeriesPlan`, `_emitPolarGeometry`)
- Modify: `lib/src/source/chart_config_dart_emitter.dart` (new seams)
- Test: `test/unit/source/chart_grammar_source_generator_test.dart`

**Interfaces:**
- Produces: `ChartConfigDartEmitter.emitPolarTargetMarkerStyle(writer, style)`, `emitPolarIntervalStyle(writer, style)` (reusing the private renderers at `:2650`/`:2673`); `_PolarSeriesPlan` extended with `columnColor`/`target`/`low`/`high` `_Field?`s.

- [ ] **Step 1: Write the failing test — a references polar (targets + columnColors) emits all fields + round-trips**

```dart
test('polar with targets, targetMarkerStyle and columnColors round-trips', () {
  final config = ChartConfiguration(series: [
    PolarColumnChartSeries.fromMap(
      id: 'ref', name: 'Actual vs plan',
      values: {'A': 3, 'B': 4},
      targets: {'A': 5, 'B': 6},
      columnColors: {'A': const Color(0xFF112233)},
      targetMarkerStyle: const PolarColumnTargetMarkerStyle(width: 3)),
  ]);
  final source = ChartGrammarSourceGenerator(configuration: config).generate();
  expect(source.code, isNotNull);          // emitted, not refused
  expect(source.code, contains('target:'));
  expect(source.code, contains('columnColor:'));
  expect(source.code, contains('targetMarkerStyle: PolarColumnTargetMarkerStyle('));
});
```

- [ ] **Step 2: Run — expect FAIL** (refused: columnColors/targets not carried → proof mismatch).

- [ ] **Step 3: Extend `_planPolarChart`** to synthesise per-series `columnColor`/`target`/`low`/`high` fields when the series carries them, fill them into the shared rows (per category), reverse `preset` → `rose`, and set them on the `PolarMark`:
  - `columnColor`: from each point's `pointStyle?.color` (a `_FieldKind.color` field — reuse the existing color-field machinery the Cartesian emitter uses for per-point colors; if none exists, add `_FieldKind.color` handling mirroring `_FieldKind.number`). Accessor `_color(field)`.
  - `target`: from `series.targetValues` (aligned to the series' own category order); `_FieldKind.number` (nullable → emit 0 where null? No — target is `num?`; use a nullable number field so a category without a target stays null. If the field infra has no nullable-number, gate the whole `target` accessor on `targetValues.isNotEmpty` and only fill present categories, leaving others null via the accessor returning null). Prefer: accessor `(row) => row.targetN` where the row field is `double?`.
  - `low`/`high`: from `series.intervalLowerValues`/`intervalUpperValues` similarly.
  - Set `mark.preset = series.preset`, `mark.targetMarkerStyle = series.targetMarkerStyle`, `mark.intervalStyle = series.intervalStyle`, `mark.columnColor/target/intervalLow/intervalHigh` accessors.

  Because the proof re-lowers, any misalignment refuses rather than emits wrong — so correctness is self-checked, but aim to reproduce `_fromMap`'s exact category-ordered lists (`polar_column_chart_series.dart:815-824`).

- [ ] **Step 4: Extend `_emitPolarGeometry`** to emit `rose: true` (when `preset == rose`), `columnColor`/`target`/`intervalLow`/`intervalHigh` accessors, and `targetMarkerStyle`/`intervalStyle` via the new seams (only when non-default). Add the seams in `chart_config_dart_emitter.dart` reusing `_emitBarTargetMarkerStyle`-style private renderers already present for polar at `:2650`/`:2673` (extract them into argument-taking helpers if they are inlined in `_emitPolarColumnSeries`).

- [ ] **Step 5: Run the test — expect PASS.** Then run the full emitter test file + drift gates (`test/meta/`).

- [ ] **Step 6: `flutter analyze lib` + commit**
  ```bash
  git add lib/src/source/chart_grammar_source_generator.dart lib/src/source/chart_config_dart_emitter.dart test/unit/source/chart_grammar_source_generator_test.dart
  git commit -m "feat(source): reverse polar columnColor/target/intervals + rose"
  ```

---

## Slice C — Non-default `ConcentricDonutConfig` passthrough

### Task C1: `DonutMark.concentric` + precedence + `conflictingConcentricCenter` + lowering

**Files:**
- Modify: `lib/src/grammar/mark.dart:949-1037` (`DonutMark`)
- Modify: `lib/src/grammar/chart_builder.dart:471` (`geomDonut`)
- Modify: `lib/src/grammar/grammar_diagnostics.dart`
- Modify: `lib/src/grammar/plot_lowering.dart:961-986` (concentric branch)
- Test: `test/unit/grammar/mark_test.dart`, `test/unit/grammar/plot_lowering_radial_test.dart`, `test/unit/grammar/grammar_diagnostics_test.dart`

**Interfaces:**
- Produces: `DonutMark.concentric: ConcentricDonutConfig?`; `geomDonut(... concentric)`; `GrammarSpecException.conflictingConcentricCenter(String markId)`. Precedence: `concentric != null` supplies ringGap/order/ringWeights/legendMode/radii + its `centerContent`; `center` used only when `concentric == null`; both set → throw.

- [ ] **Step 1: Write the failing test — non-default concentric lowers with the config**

```dart
test('donut ring mark with a concentric config lowers carrying it', () {
  const cfg = ConcentricDonutConfig(ringGap: 12, order: ConcentricRingOrder.innerToOuter);
  final spec = PlotSpec<_Ring>(
    data: const [_Ring('r1', 'A', 1), _Ring('r1', 'B', 2), _Ring('r2', 'A', 3)],
    marks: [DonutMark<_Ring>(
      category: (r) => r.cat, value: (r) => r.v,
      ring: (r) => r.ring, concentric: cfg)],
  );
  final lowered = spec.lower();
  expect(lowered.concentricDonutConfig!.ringGap, 12);
  expect(lowered.concentricDonutConfig!.order, ConcentricRingOrder.innerToOuter);
});
```

- [ ] **Step 2: Run — expect FAIL.**

- [ ] **Step 3: Implement.** Add `concentric` field to `DonutMark` (+ `==`/`hashCode`). Add the diagnostic. In `chart_builder.dart:471` add the `concentric` param. In `_lowerRadial`'s concentric branch (`:967-985`), when `mark.concentric != null`:
  - if `mark.center != null` → `throw GrammarSpecException.conflictingConcentricCenter(markId)`.
  - use `mark.concentric!` as the base config for the multi-ring case (its `centerContent` authoritative); for the single-ring collapse, carry `mark.concentric!.centerContent` onto the lone series and set `concentric = mark.concentric!` (not `const ConcentricDonutConfig()`).
  - when `mark.concentric == null`, keep today's center-derived behavior exactly (byte-identical for existing concentric charts).

- [ ] **Step 4: Run — expect PASS.** Add + run the `conflictingConcentricCenter` test.

- [ ] **Step 5: Full radial suite + `flutter analyze lib` + `flutter analyze example/lib`. Preserve NUL sentinel (re-check).**

- [ ] **Step 6: Commit**
  ```bash
  git add lib/src/grammar/mark.dart lib/src/grammar/chart_builder.dart lib/src/grammar/grammar_diagnostics.dart lib/src/grammar/plot_lowering.dart test/unit/grammar/mark_test.dart test/unit/grammar/plot_lowering_radial_test.dart test/unit/grammar/grammar_diagnostics_test.dart
  git commit -m "feat(grammar): DonutMark.concentric passthrough + precedence"
  ```

### Task C2: Emitter reverses `concentric:`

**Files:**
- Modify: `lib/src/source/chart_grammar_source_generator.dart` (`_planConcentric:809`, `_emitRadialGeometry:2011` donut arm)
- Modify: `lib/src/source/chart_config_dart_emitter.dart` (public seam over `_emitConcentricDonutConfig:3033`)
- Test: `test/unit/source/chart_grammar_source_generator_test.dart`

**Interfaces:**
- Produces: `ChartConfigDartEmitter.emitConcentricDonutConfig(writer, config)`; `_planConcentric` carries `configuration.concentricDonutConfig` onto the `DonutMark.concentric`; the donut emit arm writes `concentric:` when the config is non-default.

- [ ] **Step 1: Write the failing test — non-default concentric emits + round-trips** (author a config with a non-default `ConcentricDonutConfig`; assert `source.code` is non-null and contains `concentric: ConcentricDonutConfig(`).

- [ ] **Step 2: Run — expect FAIL** (refused: "customised ConcentricDonutConfig not reproduced").

- [ ] **Step 3: Implement.** In `_planConcentric` (`:809`), set `concentric: configuration.concentricDonutConfig` on the built `DonutMark` (and drop the separate `center` when the config carries the center — mirror the precedence in C1). In `_emitRadialGeometry`'s donut arm (`:2011-2034`), emit `concentric:` via the new seam when `mark.concentric != null && mark.concentric != const ConcentricDonutConfig()`. Add the public seam reusing `_emitConcentricDonutConfig` (extract an argument-taking helper like the polar one).

- [ ] **Step 4: Run — expect PASS.** Full emitter file + drift gates.

- [ ] **Step 5: `flutter analyze lib` + commit**
  ```bash
  git add lib/src/source/chart_grammar_source_generator.dart lib/src/source/chart_config_dart_emitter.dart test/unit/source/chart_grammar_source_generator_test.dart
  git commit -m "feat(source): reverse non-default ConcentricDonutConfig"
  ```

---

## Slice D — Showcase + docs verification

### Task D1: Every polar + concentric Grammar pane emits; retire stale copy

**Files:**
- Modify: `lib/src/source/chart_grammar_source_generator.dart:34-36` (file-header matrix)
- Modify: `doc/chart_grammar.md` (radial section — move polar/concentric out of any "not emitted / deferred" note)
- Test: `test/unit/source/chart_grammar_source_generator_test.dart` (a showcase-representative test per presentation)

**Interfaces:** none produced; this is the Theme-1 acceptance gate for polar/concentric.

- [ ] **Step 1: Write the failing/asserting tests — one per presentation.** Build a `ChartConfiguration` matching each showcase presentation (standard, rose, layered, grouped, stacked, references, intervals) from `example/lib/showcase/pages/polar_column_page.dart:695-895`, and a non-default concentric donut, and assert `generate().code != null` (emitted) and the re-lowered chain reproduces the config (the generator already proves this internally; asserting non-null is the observable). Copy the exact per-series construction from the showcase (`targets`/`intervals`/`columnColors`/`.rose`/per-series `polarStyle`).

- [ ] **Step 2: Run — expect PASS** (Slices A–C should already make them emit; any red here is a real gap to fix in the relevant slice's emitter/lowering, not by loosening the test).

- [ ] **Step 3: Update the file-header matrix** (`:34-36`) to state pie/donut/concentric/polar (incl. multi-series + customised configs) all emit; remove the "customised PolarChartConfig / non-default ConcentricDonutConfig blocked" row.

- [ ] **Step 4: Update `doc/chart_grammar.md`** — move the polar/concentric lines out of any "Not emitted / deferred" section; note multi-series polar + config passthrough are supported (keep the Beta framing).

- [ ] **Step 5: Full suite + drift gates + `flutter analyze lib` + `flutter analyze example/lib`.**

- [ ] **Step 6: Commit**
  ```bash
  git add lib/src/source/chart_grammar_source_generator.dart doc/chart_grammar.md test/unit/source/chart_grammar_source_generator_test.dart
  git commit -m "test(source): all polar presentations + non-default concentric emit; retire stale copy"
  ```

---

## Final verification (before requesting PR)

- [ ] Full `flutter test` green (target: prior 3901 + the new tests, 0 failures).
- [ ] `flutter test test/meta/` — all four drift gates green (AI schema, source_emitter_drift per-series + class-aware, codec, surface_enforcement).
- [ ] `flutter analyze lib` and `flutter analyze example/lib` — "No issues found!".
- [ ] Cartesian + existing pie/donut/concentric/single-polar emission byte-identical (the existing emitter tests in `chart_grammar_source_generator_test.dart` unchanged/green).
- [ ] `chart_builder.dart` NUL sentinel intact (1 NUL, 0 CRLF, no BOM).
- [ ] Run the showcase locally (`flutter run -d chrome` in `example/`) and confirm the Polar + Concentric workbench Grammar panes render real chains — for owner browser verification.
- [ ] Rebase onto latest `origin/master`; re-run the suite.
