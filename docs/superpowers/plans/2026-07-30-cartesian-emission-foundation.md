# Cartesian Emission Foundation — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make a chart authored the normal way — `BravenChartPlus` with config objects — reversible into a `BravenChart` chain when it is Cartesian, as it already is when it is radial.

**Architecture:** Three narrow carries plus one seam fix. A new `SeriesMark<T>` sealed intermediate holds `unit` so it reaches the five Cartesian geometry marks but structurally *cannot* reach the four annotation marks. The legacy single-axis binding is reconciled on both sides — a strictly-gated proof normalisation *and* a `BravenPlot` mount change — so the emitted chain reproduces the captured **document**, not merely the same pixels. Per-point `label`/`pointKey` become accessors, `isXOrdered` a plain flag, and `segmentStyle` an honest named refusal.

**Tech Stack:** Dart ≥3.9, Flutter; `flutter test`; `flutter analyze lib` and `flutter analyze example/lib` (never root — vendored `packages/fleather` pollutes it).

**Spec:** `docs/superpowers/specs/2026-07-30-cartesian-emission-foundation-design.md`
**Register:** BC-0040 (lane `chart-grammar`)

## Global Constraints

- Worktree `F:\Repositories\braven_charts-cartesian-foundation`, branch `feature/grammar-cartesian-foundation` (off `origin/master` `4d5687a9`). PR to master only on the owner's explicit go-ahead.
- **Document-faithful, not render-faithful.** Emitted chains must reproduce the captured document and be gated by the existing `expectRoundTrip` document-equality harness — the bar every radial slice was held to.
- **No new drift-gate surface.** Marks carry plain values and functions; they have no `copyWith` and no `@chartSurface`.
- **Radial emission byte-identical**; existing goldens unchanged.
- **Never weaken an assertion.** Where this slice removes the behaviour a pinned test pins, **convert** it to a stronger positive test and say so in the report and commit body. Never delete it.
- **THE PROOF DOES NOT READ EMITTED TEXT.** The generator's docstring (`chart_grammar_source_generator.dart:1849-1859`) records this, verified by mutation — deleting the `.grid(...)`/`.title(...)` emission produces **zero** refusals. So every field this slice carries needs an explicit emitted-text assertion (`contains("unit: 'W'")`), or the chain silently drops it while all tests pass. Radial precedent: `test/unit/source/chart_grammar_source_generator_test.dart:4066, 4506, 4623, 4707`.
- `lib/src/grammar/chart_builder.dart` holds **one deliberate NUL sentinel** and is **invisible to plain ripgrep** — use `rg --text` on it. After editing verify:
  `cd /f/Repositories/braven_charts-cartesian-foundation && python -c "import pathlib; b=pathlib.Path('lib/src/grammar/chart_builder.dart').read_bytes(); print('NUL',b.count(0),'CRLF',b.count(b'\r\n'),'BOM',b[:3]==b'\xef\xbb\xbf')"` → `NUL 1 CRLF 0 BOM False`
- Master has a **changed-file `dart format` gate**: run `dart run tool/check_dart_format.dart` from the repo root before committing. Its scopes include `example/test`.
- Analyze with `flutter analyze lib` **and** `flutter analyze example/lib`. Never root.
- Stage with **specific `git add <paths>`** — never `git add -A`; never stage `example/windows/flutter/*` (known build cruft).
- Every commit message ends with: `Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>`
- **Line numbers shift.** Every anchor below was read at `4d5687a9`/`680ad247`; re-read the surrounding code before editing.

## Verified facts the plan depends on

Confirmed by reading the code at plan time — do not re-derive, but do re-locate:

- `Mark` is `sealed`, declared `mark.dart:58`, ctor `const Mark({this.id, this.name, this.color, this.yAxisId});` at `:60`.
- Subclasses: `LineMark:83`, `AreaMark:173`, `BarMark:278`, `ScatterMark:418`, `CandlestickMark:527`, `TrendMark:603`, `ThresholdMark:680`, `BandMark:742`, `PointMark:791`, `RadialMark:853` (sealed), `PieMark:876`, `DonutMark:964`, `PolarMark:1183`.
- **`RadialMark` does NOT forward `super.yAxisId`** (`:855-862` forwards only `id`/`name`/`color`) — radial has no Y axis. `SeriesMark` must therefore keep `yAxisId` optional and NOT require it.
- `RadialMark.unit` is declared at `:872` with its doc at `:870-871`.
- **All eight `geom*` verbs are SERIES verbs.** `geomLine:253`, `geomArea:290`, `geomBar:330`, **`geomPoint:376` — which constructs a `ScatterMark<T>`, not a `PointMark`** — `geomCandlestick:417`, `geomPie:452`, `geomDonut:520`, `geomPolar:572`. The annotation marks are built by separate non-geom verbs at `:630` (Trend), `:658` (Threshold), `:681` (Band), `:705` (Point).
- `_lowerPoint` returns a `PointAnnotation` (`plot_lowering.dart:945`); annotations are added at `:431`.

---

# SLICE 1 — `SeriesMark` + `unit`

**This slice unblocks ZERO states on its own.** Every unit-blocked state is also axis-blocked; the payoff arrives with Slice 2. Say so in the commit body so a reviewer does not read "0" as failure.

### Task 1.1: Introduce `SeriesMark<T>` and re-parent the five Cartesian marks

**Files:**
- Modify: `lib/src/grammar/mark.dart` (insert after `Mark` ends `:81`; re-parent `:83, 173, 278, 418, 527`; `RadialMark:853`)
- Test: `test/unit/grammar/radial_marks_test.dart`, `test/unit/grammar/plot_spec_test.dart`

**Interfaces:**
- Produces: `sealed class SeriesMark<T> extends Mark<T>` with `final String? unit;` — extended by `LineMark`, `AreaMark`, `BarMark`, `ScatterMark`, `CandlestickMark`, `RadialMark`.

- [ ] **Step 1: Write the failing test**

Put this in `test/unit/grammar/radial_marks_test.dart` (it already covers mark identity; match its fixture conventions and keep marks `const` where the neighbours do):

```dart
test('unit lives on SeriesMark and reaches every series mark', () {
  const line = LineMark<Fruit>(x: fruitIndex, y: fruitCount, unit: 'kg');
  const pie = PieMark<Fruit>(
      category: fruitName, value: fruitCount, unit: 'kg');
  expect(line.unit, 'kg');
  expect(pie.unit, 'kg');
  expect(line, isA<SeriesMark<Fruit>>());
  expect(pie, isA<SeriesMark<Fruit>>());
});

test('unit participates in equality for every series mark', () {
  const withUnit = AreaMark<Fruit>(x: fruitIndex, y: fruitCount, unit: 'kg');
  const without = AreaMark<Fruit>(x: fruitIndex, y: fruitCount);
  expect(withUnit == without, isFalse);
  expect(withUnit.hashCode == without.hashCode, isFalse);
});

test('annotation marks are NOT SeriesMarks and cannot carry a unit', () {
  // TrendMark/ThresholdMark/BandMark/PointMark lower to ChartAnnotations, and
  // no annotation type in this package has a unit. Keeping them off SeriesMark
  // makes "accepted then silently discarded" unrepresentable — the proof could
  // not catch it, because _sameAnnotation never reads a unit.
  const threshold = ThresholdMark<Fruit>(value: 3);
  expect(threshold, isNot(isA<SeriesMark<Fruit>>()));
});
```

- [ ] **Step 2: Run it — expect FAIL**

Run: `cd /f/Repositories/braven_charts-cartesian-foundation && flutter test test/unit/grammar/radial_marks_test.dart`
Expected: FAIL — `Undefined name 'SeriesMark'` / `No named parameter 'unit'` on `LineMark`.

- [ ] **Step 3: Add the intermediate**

Insert immediately after `Mark` closes (`:81`), moving and generalising the doc currently on `RadialMark.unit:870-871`:

```dart
/// A mark that lowers to a `ChartSeries`.
///
/// Split out from [Mark] so that [unit] — which every lowered series carries
/// (`ChartSeries.unit`) — reaches the geometry marks and CANNOT reach
/// [TrendMark]/[ThresholdMark]/[BandMark]/[PointMark], which lower to
/// `ChartAnnotation`s. No annotation type in this package has a unit, and the
/// round-trip proof compares annotations with a helper that never reads one, so
/// a unit on those marks would be accepted and silently discarded with nothing
/// able to catch it.
sealed class SeriesMark<T> extends Mark<T> {
  /// Shared identity fields plus the measure unit.
  const SeriesMark({
    super.id,
    super.name,
    super.color,
    super.yAxisId,
    this.unit,
  });

  /// Measure unit carried onto the lowered series (`ChartSeries.unit`). Null
  /// lowers to a series with no unit.
  final String? unit;
}
```

- [ ] **Step 4: Re-parent the five Cartesian marks**

For each of `LineMark:83`, `AreaMark:173`, `BarMark:278`, `ScatterMark:418`, `CandlestickMark:527`:
1. `extends Mark<T>` → `extends SeriesMark<T>`
2. add `super.unit,` to the constructor (`:85, 175, 280, 420, 529`)
3. add `other.unit == unit &&` to `==` (`:134, 232, 353, 480, 562`)
4. add `unit,` to `hashCode` (`:152, 252, 375, 502, 577`)

`Object.hash` caps at 20 positional args; the worst case here is `BarMark` 17→18, so no overflow. `ScatterMark` uses `Object.hashAll` — add `unit` to its list.

- [ ] **Step 5: Move `RadialMark` onto the intermediate — and DELETE its own field**

`RadialMark:853`: `extends Mark<T>` → `extends SeriesMark<T>`; change `this.unit,` (`:861`) to `super.unit,`; **delete the `final String? unit;` declaration at `:872`** (its doc moved to `SeriesMark` in Step 3).

Note `RadialMark` deliberately does not forward `super.yAxisId` — radial has no Y axis. Leave that as-is.

**This deletion is not optional.** Probe-verified: leaving the subclass field while `SeriesMark` also declares it **compiles silently** — the subclass field shadows the base getter and the base's storage sits dead and always null. `PieMark`/`DonutMark`/`PolarMark` need no change; their existing `super.unit` and `==`/`hashCode` entries keep working.

- [ ] **Step 6: Run it — expect PASS.** Then run the whole grammar suite: `flutter test test/unit/grammar/`

- [ ] **Step 7: Both analyzes + the format gate, then commit**

```bash
dart run tool/check_dart_format.dart
flutter analyze lib && flutter analyze example/lib
git add lib/src/grammar/mark.dart test/unit/grammar/radial_marks_test.dart
git commit -m "feat(grammar): add a SeriesMark intermediate carrying unit"
```

### Task 1.2: Lowering carries `unit` onto the five Cartesian series

**Files:**
- Modify: `lib/src/grammar/plot_lowering.dart` — `_lowerLine:687`, `_lowerArea:715`, `_lowerBar:745`, `_lowerScatter:791`, `_lowerCandlestick:848`
- Test: `test/unit/grammar/plot_lowering_test.dart` (or the file already covering Cartesian lowering — locate it and match conventions)

**Interfaces:**
- Consumes: `SeriesMark.unit` (Task 1.1).
- Produces: every Cartesian lowered series carries `unit: mark.unit`.

- [ ] **Step 1: Write the failing test**

```dart
test('unit lowers onto every Cartesian series family', () {
  for (final (mark, name) in <(Mark<Fruit>, String)>[
    (const LineMark<Fruit>(x: fruitIndex, y: fruitCount, unit: 'kg'), 'line'),
    (const AreaMark<Fruit>(x: fruitIndex, y: fruitCount, unit: 'kg'), 'area'),
    (const BarMark<Fruit>(x: fruitIndex, y: fruitCount, unit: 'kg'), 'bar'),
    (const ScatterMark<Fruit>(x: fruitIndex, y: fruitCount, unit: 'kg'), 'scatter'),
  ]) {
    final spec = PlotSpec<Fruit>(data: fruits, marks: [mark]);
    expect(spec.lower().series.single.unit, 'kg', reason: name);
  }
});
```

Add a candlestick case using the file's existing OHLC fixture.

- [ ] **Step 2: Run — expect FAIL** (unit is null on every family).

- [ ] **Step 3: Add the passthrough**

Add `unit: mark.unit,` beside the existing `color: mark.color,` in each series construction: `_lowerLine` (~`:704`), `_lowerArea` (~`:732`), `_lowerBar` (~`:770`), `_lowerScatter` (~`:820`), `_lowerCandlestick` (~`:889`).

**Do NOT touch `_lowerTrend:897`, `_lowerThreshold:914`, `_lowerBand:931`, `_lowerPoint:945`** — they build `ChartAnnotation`s, which have no `unit`, and after Task 1.1 their marks cannot carry one anyway.

- [ ] **Step 4: Run — expect PASS.** Then `flutter test test/unit/grammar/`.

- [ ] **Step 5: Format gate + analyzes + commit**

```bash
git add lib/src/grammar/plot_lowering.dart test/unit/grammar/plot_lowering_test.dart
git commit -m "feat(grammar): lower unit onto the Cartesian series families"
```

### Task 1.3: Builder verbs accept `unit`

**Files:**
- Modify: `lib/src/grammar/chart_builder.dart` — `geomLine:253`, `geomArea:290`, `geomBar:330`, `geomPoint:376`, `geomCandlestick:417`
- Test: `test/unit/grammar/chart_builder_test.dart`

**Interfaces:**
- Produces: `unit:` named param on all five Cartesian geom verbs, forwarded to the mark.

- [ ] **Step 1: Write the failing test**

```dart
test('the Cartesian geom verbs forward unit to their marks', () {
  final spec = BravenChart.of(samples)
      .x(sampleIndex)
      .geomLine(y: samplePower, unit: 'W')
      .toSpec();
  expect((spec.marks.single as LineMark<Sample>).unit, 'W');
});
```

Add equivalents for `geomArea`, `geomBar`, `geomPoint` and `geomCandlestick`.

- [ ] **Step 2: Run — expect FAIL** (`No named parameter 'unit'`).

- [ ] **Step 3: Add the params**

Add `String? unit,` to each of the five verbs and forward `unit: unit,` into the mark they construct. Document it the way `geomPie`'s `unit` is documented.

**`geomPoint` IS included** — it constructs a `ScatterMark<T>`, not a `PointMark` (verified). All eight `geom*` verbs are series verbs; the annotation marks come from the separate non-geom verbs at `:630`/`:658`/`:681`/`:705`, which are **not** touched.

Use `rg --text` when searching this file — its NUL sentinel makes plain ripgrep skip it silently.

- [ ] **Step 4: Run — expect PASS.**

- [ ] **Step 5: Verify the NUL sentinel**

Run the check from Global Constraints. Expected: `NUL 1 CRLF 0 BOM False`.

- [ ] **Step 6: Format gate + analyzes + commit**

```bash
git add lib/src/grammar/chart_builder.dart test/unit/grammar/chart_builder_test.dart
git commit -m "feat(grammar): accept unit on the Cartesian geom verbs"
```

### Task 1.4: Emitter reverses `unit` — and ASSERTS THE EMITTED TEXT

**Files:**
- Modify: `lib/src/source/chart_grammar_source_generator.dart` — `_planGeometry:2282` (mark constructions at `:2310, 2330, 2379, 2408, 2431`), `_emitGeometry:3061`
- Test: `test/unit/source/chart_grammar_source_generator_test.dart`

**Interfaces:**
- Consumes: lowering + builder from 1.2/1.3.
- Produces: `unit: series.unit` on planned Cartesian marks; `unit: 'W'` in the emitted chain.

- [ ] **Step 1: Write the failing test — round-trip AND emitted text**

The second assertion is the one that matters: the proof cannot see the emitted text, so without it a missing writer line ships a chain that silently drops the unit while everything passes.

```dart
testWidgets('a Cartesian series unit round-trips AND is emitted', (tester) async {
  final snapshot = await snapshotOf(tester, (controller) => BravenChartPlus(
    controller: controller,
    yAxes: [const YAxisConfig.withId(id: 'axis-0', position: YAxisPosition.left)],
    series: [
      LineChartSeries(
        id: 'power',
        unit: 'W',
        yAxisId: 'axis-0',
        points: const [ChartDataPoint(x: 0, y: 1), ChartDataPoint(x: 1, y: 2)],
      ),
    ],
  ));
  final generated = generateGrammar(snapshot);
  expect(emittedChain(generated), isTrue);
  expect(generated.source, contains("unit: 'W'"));
});
```

Note the explicit `yAxisId`/`yAxes` — until Slice 2 lands, a single-axis chart is still refused, so this fixture must bind explicitly to isolate what Task 1.4 changes.

- [ ] **Step 2: Run — expect FAIL** (refused: "It carries a unit ('W')…").

- [ ] **Step 3: Reverse it in the plan**

Add `unit: series.unit,` to the five Cartesian mark constructions in `_planGeometry` (`:2310` Candlestick, `:2330` Line, `:2379` Scatter, `:2408` Area, `:2431` Bar). `series.unit` is already in scope.

- [ ] **Step 4: Emit it**

Add `_optionalString(writer, 'unit', mark.unit);` in `_emitGeometry` — either once near the `yAxisId` write (~`:3161`, guarded on `mark is SeriesMark`) or inside the five family cases (`:3100-3151`). Match whichever shape reads more like the surrounding code.

- [ ] **Step 5: `_firstUncarriedField` needs NO change**

Read `:1993-1996` and confirm it is a **value comparison**, not a family allowlist:

```dart
if (expected.unit != lowered.unit) {
  return "a unit ('${expected.unit}')";
```

Once the plan sets `unit` and lowering carries it, this stops firing for the carried families automatically, and still fires for any family whose mark does not carry it. **Leave it exactly as written.**

- [ ] **Step 6: Run — expect PASS.** Then run the full emitter file and confirm no existing expectation moved.

- [ ] **Step 7: Re-point the pinned test that used `unit` as its example**

`test/unit/source/chart_grammar_source_generator_test.dart:6940` — *"a series option no V1 mark carries is refused, not dropped"* — uses `LineChartSeries(unit: 'W')` and asserts the reason contains `unit`. That option is now carried, so the test would assert a behaviour this slice deliberately removed.

Re-point it at a **still-uncarried** option (`lineGlow`, `tension`, or `dataPointMarkerStyle` — see the list at `:2002-2015`), keeping the assertion that the reason is *named*. This is a fixture change, not a weakening: run it and confirm it still fails when the refusal is stubbed out.

- [ ] **Step 8: Full suite, drift gates, format gate, both analyzes, then commit**

```bash
flutter test && flutter test test/meta/
git add lib/src/source/chart_grammar_source_generator.dart test/unit/source/chart_grammar_source_generator_test.dart
git commit -m "feat(source): reverse and emit unit on the Cartesian families"
```

---

# SLICE 2 — Legacy single-axis binding (Option D, both halves)

Unblocks 4 states. **Both halves are required**: the proof normalisation alone leaves an `axisId` + `inlineAxis` delta in the document, because `BravenPlot` passes no Y axis at all and the declared axis reaches the chart *only* through each series' `yAxisConfig`.

### Task 2.1: `BravenPlot` mounts the legacy single-axis shape

**Files:**
- Modify: `lib/src/grammar/braven_plot.dart:88-116`
- Test: `test/widgets/braven_plot_test.dart`

**Interfaces:**
- Produces: when the lowered plot declares exactly one axis and no mark bound explicitly, `BravenPlot` passes `yAxis: lowered.yAxes.single` and mounts the series with their binding stripped.

- [ ] **Step 1: Write the failing test**

```dart
testWidgets('a single-axis chain mounts the legacy shape', (tester) async {
  // The chain declares one axis and no mark binds explicitly, so BravenPlot
  // should mount it the way a config author would — widget-level yAxis, series
  // unbound — otherwise the emitted chain produces a DIFFERENT document from
  // the chart it was reversed from.
  final chart = BravenChart.of(rows)
      .x((r) => r.x)
      .yAxis(const YAxisConfig.withId(id: 'y', position: YAxisPosition.left))
      .geomLine(y: (r) => r.y)
      .build();
  await tester.pumpWidget(MaterialApp(home: Scaffold(body: chart)));
  final plus = tester.widget<BravenChartPlus>(find.byType(BravenChartPlus));
  expect(plus.yAxis?.id, 'y');
  expect(plus.series.single.yAxisId, isNull);
  expect(plus.series.single.yAxisConfig, isNull);
});

testWidgets('a multi-axis chain still binds per series', (tester) async {
  final chart = BravenChart.of(rows)
      .x((r) => r.x)
      .yAxis(const YAxisConfig.withId(id: 'left', position: YAxisPosition.left))
      .yAxis(const YAxisConfig.withId(id: 'right', position: YAxisPosition.right))
      .geomLine(y: (r) => r.y, yAxisId: 'right')
      .build();
  await tester.pumpWidget(MaterialApp(home: Scaffold(body: chart)));
  final plus = tester.widget<BravenChartPlus>(find.byType(BravenChartPlus));
  expect(plus.series.single.yAxisId, 'right');
});
```

- [ ] **Step 2: Run — expect the first to FAIL** (series carries `yAxisId: 'y'`), the second to pass.

- [ ] **Step 3: Implement the seam**

In `braven_plot.dart` where it builds `BravenChartPlus` (`:88-116`), detect the legacy shape and mount it the way a config author would:

```dart
// A chain that declares exactly one axis and binds no mark to it explicitly is
// the grammar's spelling of the legacy single-axis chart. Mount it that way —
// widget-level yAxis, series unbound — so the chart this chain produces is the
// SAME DOCUMENT as the config chart it was reversed from, not merely one that
// renders the same. Without this, every reversed single-axis chart differs by
// series[*].axisId + inlineAxis and cannot be gated by document equality.
final usesLegacySingleAxis = lowered.yAxes.length == 1 &&
    spec.marks.every((mark) => mark.yAxisId == null);

final mountedSeries = usesLegacySingleAxis
    ? [for (final s in lowered.series) s.copyWith(clearYAxisId: true, clearYAxisConfig: true)]
    : lowered.series;
```

then pass `yAxis: usesLegacySingleAxis ? lowered.yAxes.single : null` and `yAxes:` accordingly. Check `ChartSeries.copyWith`'s real nullable-clear parameter names before writing this — the package uses explicit `clearX` flags for nullable fields, and the exact spelling must match. If no such clear exists on `ChartSeries.copyWith`, rebuild the series rather than adding one: this task must not widen the config surface.

Otherwise keep today's behaviour **exactly** — the multi-axis test in Step 1 is what proves you did.

- [ ] **Step 4: Run — expect PASS.** Then run the widget suite and confirm no golden moved: `flutter test test/widgets/`

- [ ] **Step 5: Update the parity assertions**

`test/unit/grammar/plot_lowering_parity_test.dart` pins `yAxisId: 'axis-0', yAxisConfig: axis` at roughly lines 118, 154, 184, 207, 236, 271, 300, 328, 355, 411, 434, 444, 452. Those that describe the **mounted** shape now describe the legacy shape. Re-read each: assertions about *lowering* are unchanged; only assertions about what reaches `BravenChartPlus` move. Do not blanket-edit — change only the ones that actually assert the mounted binding, and say in the commit body how many moved and why.

- [ ] **Step 6: Format gate + analyzes + commit**

```bash
git add lib/src/grammar/braven_plot.dart test/widgets/braven_plot_test.dart test/unit/grammar/plot_lowering_parity_test.dart
git commit -m "fix(grammar): mount the legacy single-axis shape for single-axis chains"
```

### Task 2.2: Proof normalisation — strictly gated

**Files:**
- Modify: `lib/src/source/chart_grammar_source_generator.dart:1877-1885` (`_firstMismatch`)
- Test: `test/unit/source/chart_grammar_source_generator_test.dart`

**Interfaces:**
- Consumes: the seam from 2.1.
- Produces: a single-axis config chart emits and round-trips by **document equality**.

- [ ] **Step 1: Write BOTH tests — the positive and the guard — before implementing**

The guard is the important one. A too-broad normalisation renders a *different chart*: `getEffectiveYAxes` ignores the widget-level `yAxis` once any series carries an inline config, and `getEffectiveBindings` binds an unbound series to a synthetic `'primary_axis'`, not to `axes.first`. Measured: 4,265 of 960,000 pixels differ under `normalizationMode.perSeries`.

```dart
testWidgets('a single-axis config chart emits and round-trips', (tester) async {
  // CONVERTED from the pinned refusal test ":6980 — a single-axis config chart
  // explains the axis binding". The behaviour it pinned is what this slice
  // removes, so it becomes a positive document-equality round trip.
  await expectRoundTrip(tester, (controller) => BravenChartPlus(
    controller: controller,
    yAxis: const YAxisConfig(position: YAxisPosition.left, label: 'Power'),
    series: [
      LineChartSeries(
        id: 'power',
        points: const [ChartDataPoint(x: 0, y: 1), ChartDataPoint(x: 1, y: 2)],
      ),
    ],
  ));
});

testWidgets('a MIXED binding is still refused — the normalisation is narrow',
    (tester) async {
  // One series bound inline, one unbound. Binding the unbound one to the
  // other's axis would render a different chart, so this must NOT normalise.
  final snapshot = await snapshotOf(tester, (controller) => BravenChartPlus(
    controller: controller,
    series: [
      LineChartSeries(
        id: 'a',
        yAxisConfig: const YAxisConfig.withId(
            id: 'a-axis', position: YAxisPosition.left,
            minimum: 0, maximum: 1000),
        points: const [ChartDataPoint(x: 0, y: 1)],
      ),
      LineChartSeries(id: 'b', points: const [ChartDataPoint(x: 0, y: 900)]),
    ],
  ));
  final generated = generateGrammar(snapshot);
  expect(emittedChain(generated), isFalse);
  expect(blockedReason(generated), contains('yAxisId'));
});
```

- [ ] **Step 2: Run — expect the first to FAIL, the second to PASS** (it already refuses today).

- [ ] **Step 3: Implement the normalisation, strictly gated**

In `_firstMismatch` (`~:1877-1885`), before comparing series, detect the legacy shape and compare with the binding normalised away — **only** when every captured series is unbound:

```dart
// A chart authored through the single-axis path carries no per-series binding,
// while lowering always binds. BravenPlot now mounts that same legacy shape
// (see braven_plot.dart), so the two are the same chart and the binding is not
// a difference.
//
// The gate is deliberately narrow. "A null yAxisId binds to axes.first" is
// WRONG: getEffectiveYAxes ignores the widget-level yAxis once any series
// carries an inline config, and getEffectiveBindings binds an unbound series to
// a synthetic 'primary_axis'. A document with one series bound inline and one
// unbound is reachable, and normalising it renders a different chart (measured:
// 4265/960000 pixels differ under normalizationMode.perSeries).
final legacySingleAxis = configuration.axes.length == 1 &&
    configuration.series
        .every((s) => s.yAxisId == null && s.yAxisConfig == null);
```

Use that flag to strip `yAxisId`/`yAxisConfig` from the lowered series before the comparison.

- [ ] **Step 4: Run — expect BOTH to PASS.**

- [ ] **Step 5: Prove the gate is not over-broad**

Temporarily widen the gate to `configuration.axes.length == 1` alone (dropping the all-unbound condition), run the guard test, and **confirm it FAILS**. Then revert and confirm `git status --short` is clean. Report both results — a gate no test can catch being loosened is not a gate.

- [ ] **Step 6: Fix the now-vacuous neighbour**

`:7013` — *"grid and legend never trip the chart-option gate"* — builds single-axis charts and asserts `blockedReason` contains neither `grid` nor `legend`. Those charts now **emit**, so `blockedReason` is null and `isNot(contains(...))` passes vacuously. Give it a chart that still blocks for an unrelated reason, so it tests what its name claims.

- [ ] **Step 7: Full suite, drift gates, format gate, both analyzes, then commit**

```bash
git add lib/src/source/chart_grammar_source_generator.dart test/unit/source/chart_grammar_source_generator_test.dart
git commit -m "feat(source): reverse the legacy single-axis binding"
```

---

# SLICE 3 — Per-point metadata

Unblocks 9 more states.

### Task 3.1: `label` and `pointKey` accessors

**Files:**
- Modify: `lib/src/grammar/mark.dart` (the four Cartesian geometry marks), `lib/src/grammar/chart_builder.dart`, `lib/src/grammar/plot_lowering.dart`, `lib/src/source/chart_grammar_source_generator.dart`
- Test: `test/unit/grammar/`, `test/unit/source/chart_grammar_source_generator_test.dart`

**Interfaces:**
- Produces: `final String? Function(T)? label;` and `final String? Function(T)? pointKey;` on `LineMark`/`AreaMark`/`BarMark`/`ScatterMark`; `label:`/`pointKey:` params on their verbs; reversed from `point.label`/`point.pointKey` via the existing `_FieldKind.string` row slot.

- [ ] **Step 1: Write the failing tests**

`label` is the direct Cartesian analogue of the radial `category` channel — `PieChartSeries.fromMap` sets `label: entry.key`, which is exactly why `geomPie(category:)` round-trips.

```dart
test('label and pointKey lower onto the points', () {
  final spec = PlotSpec<Fruit>(
    data: fruits,
    marks: [
      LineMark<Fruit>(
        x: fruitIndex, y: fruitCount,
        label: (f) => f.name,
        pointKey: (f) => 'key-${f.name}',
      ),
    ],
  );
  final points = spec.lower().series.single.points;
  expect(points.first.label, fruits.first.name);
  expect(points.first.pointKey, 'key-${fruits.first.name}');
});

test('an empty pointKey lowers to null rather than throwing', () {
  // ChartDataPoint's constructor asserts a non-empty pointKey, so the accessor
  // must normalise '' to null instead of letting the assert fire.
  final spec = PlotSpec<Fruit>(
    data: fruits,
    marks: [LineMark<Fruit>(x: fruitIndex, y: fruitCount, pointKey: (f) => '')],
  );
  expect(spec.lower().series.single.points.first.pointKey, isNull);
});
```

- [ ] **Step 2: Run — expect FAIL.**

- [ ] **Step 3: Add the fields, params, lowering and reversal**

Fields on the four marks (functions, so no `copyWith`/`@chartSurface`/drift-gate cost) with `==`/`hashCode` entries; params on `geomLine`/`geomArea`/`geomBar`/`geomPoint`; lowering writes them into each `ChartDataPoint`, normalising `''` → `null` for `pointKey`; the emitter plans a `_FieldKind.string` field per accessor and reverses from `point.label`/`point.pointKey`.

- [ ] **Step 4: Run — expect PASS.**

- [ ] **Step 5: Add the emitted-text assertions**

The proof cannot see the emitted text. Assert both accessors appear:

```dart
expect(generated.source, contains('label: (row) => row.label'));
expect(generated.source, contains('pointKey: (row) => row.pointKey'));
```

- [ ] **Step 6: Guard colliding keys with a named diagnostic**

`pointKey` is the stable **selection identity**, so two rows yielding the same key within one series make selection ambiguous. Raise a named diagnostic rather than letting it through — this matches how `duplicateRadialCategory` already handles the equivalent collision on the radial side, so follow that factory's shape.

```dart
test('duplicate pointKeys within one series are refused by name', () {
  final spec = PlotSpec<Fruit>(
    data: fruits, // two rows, same key
    marks: [
      LineMark<Fruit>(
        x: fruitIndex, y: fruitCount, pointKey: (f) => 'same'),
    ],
  );
  expect(
    () => spec.lower(),
    throwsA(isA<GrammarSpecException>().having(
      (e) => e.code, 'code', GrammarDiagnosticCode.duplicatePointKey)),
  );
});
```

Add `duplicatePointKey` to `GrammarDiagnosticCode` and a factory beside `duplicateRadialCategory` in `grammar_diagnostics.dart`. Place the check with the other shape-decidable validations — **above** the `emptyData` guard — matching the module's documented ordering contract, and test that `data: []` still yields `emptyData` rather than the new code.

- [ ] **Step 7: Full suite, format gate, both analyzes, commit**

```bash
git add lib/src/grammar/mark.dart lib/src/grammar/chart_builder.dart lib/src/grammar/plot_lowering.dart lib/src/source/chart_grammar_source_generator.dart test/
git commit -m "feat(grammar): carry per-point label and pointKey on the Cartesian marks"
```

### Task 3.2: `isXOrdered` flag and the `segmentStyle` named refusal

**Files:**
- Modify: `lib/src/grammar/mark.dart`, `lib/src/grammar/chart_builder.dart`, `lib/src/grammar/plot_lowering.dart`, `lib/src/source/chart_grammar_source_generator.dart`
- Test: `test/unit/grammar/`, `test/unit/source/chart_grammar_source_generator_test.dart`

**Interfaces:**
- Produces: `final bool isXOrdered;` (default `false`) on `LineMark`/`AreaMark`/`BarMark`/`ScatterMark`, an `isXOrdered:` param of the same name on their verbs, lowered onto `ChartSeries.isXOrdered`; plus a named refusal for per-point `segmentStyle`. **Use the one name `isXOrdered` at all three layers** — mark field, verb param and series field — so nothing has to remember a rename.

- [ ] **Step 1: Write the failing tests**

```dart
test('xOrdered is carried explicitly, never derived', () {
  final ordered = PlotSpec<Fruit>(
    data: fruits,
    marks: [LineMark<Fruit>(x: fruitIndex, y: fruitCount, isXOrdered: true)],
  );
  expect(ordered.lower().series.single.isXOrdered, isTrue);

  // Rows here are ALREADY sorted by x. Deriving the flag from the data would
  // flip this to true and silently change nearest-point behaviour for every
  // existing grammar chart whose rows happen to be sorted.
  final notDeclared = PlotSpec<Fruit>(
    data: fruits,
    marks: [LineMark<Fruit>(x: fruitIndex, y: fruitCount)],
  );
  expect(notDeclared.lower().series.single.isXOrdered, isFalse);
});

testWidgets('a per-point segment style is refused with a NAMED reason',
    (tester) async {
  final snapshot = await snapshotOf(tester, (controller) => BravenChartPlus(
    controller: controller,
    yAxes: [const YAxisConfig.withId(id: 'axis-0', position: YAxisPosition.left)],
    series: [
      LineChartSeries(
        id: 'forecast',
        yAxisId: 'axis-0',
        points: const [
          ChartDataPoint(x: 0, y: 1),
          ChartDataPoint(x: 1, y: 2,
              segmentStyle: SegmentStyle(dashPattern: [2, 6])),
        ],
      ),
    ],
  ));
  final generated = generateGrammar(snapshot);
  expect(emittedChain(generated), isFalse);
  expect(blockedReason(generated), contains('segment style'));
});
```

- [ ] **Step 2: Run — expect FAIL.**

- [ ] **Step 3: Implement**

`isXOrdered` as a plain `bool` on the four Cartesian marks (default `false`, matching `ChartSeries`), forwarded by the verbs and passed through lowering. A bool is not a config object, so it stays out of the drift gates. **Do not derive it from the rows.**

For `segmentStyle`, add a named branch to the refusal detail so the reason says *"this series carries a per-point segment style, which no V1 mark carries"* instead of falling into the generic tail.

**`segmentStyle` is deliberately NOT carried.** Measured: carrying it unblocks zero states — the one censused chart using it still refuses on a marker field behind it. It would also need a new row-field kind (rows have slots for numbers, strings, stamps and colours only) and it collides with `LineMark.colorBy`, which already bakes `segmentStyle.color` per point. Revisit with 1d.

- [ ] **Step 4: Run — expect PASS.** Then add the emitted-text assertion, since the proof cannot see it:

```dart
expect(generated.source, contains('isXOrdered: true'));
```

and a byte-identity control: a chart that leaves `isXOrdered` at its `false` default must emit **no** `isXOrdered` argument at all.

- [ ] **Step 5: Full suite, drift gates, format gate, both analyzes, commit**

```bash
git add lib/src/grammar/ lib/src/source/ test/
git commit -m "feat(grammar): carry isXOrdered and name the per-point segment-style refusal"
```

---

# SLICE 4 — Mounted-page gates and the census

### Task 4.1: Line and Area acceptance gates, then re-measure

**Files:**
- Create: `example/test/showcase/line_charts_page_grammar_test.dart`, `example/test/showcase/area_charts_page_grammar_test.dart`
- Modify: `docs/superpowers/specs/2026-07-26-fluent-grammar-roadmap-v2.md`, the BC-0040 register item

- [ ] **Step 1: Write the gates**

Copy the harness from an existing radial gate — `example/test/showcase/donut_charts_page_grammar_test.dart` — which pumps the real page, reads the live document off the chart's own controller, and generates. **Mount the real page; never a transcribed fixture.**

Include the compile floor via `tester.runAsync`, as those gates do: the emitted chain must pass `dart format` and `dart analyze`. That floor caught a real defect last slice that every text assertion passed over.

Target the presets the census showed newly emitting: `Line|Interpolation` and `Area|Layered`/`Area|Selection`.

- [ ] **Step 2: Run them — expect PASS** given Slices 1–3. If one refuses, diagnose the real gap and fix it; **do not weaken the assertion**.

- [ ] **Step 3: Re-measure the census**

Re-run the emission census across the Cartesian pages and record the actual number. The design was sized on a predicted 21 of 100; report what it really is. If it differs materially, say so plainly rather than restating the prediction.

- [ ] **Step 4: Record it**

Update the roadmap's measured-position section with the new number and the remaining blocker distribution, and update BC-0040's Evidence and status. The register lives OUTSIDE git — never `git add` it. After editing:

```powershell
& 'F:\Repositories\_braven_charts_register\register.ps1' validate
& 'F:\Repositories\_braven_charts_register\register.ps1' refresh
```

- [ ] **Step 5: Full suite, example suite, drift gates, format gate, both analyzes, commit**

```bash
flutter test && (cd example && flutter test) && flutter test test/meta/
git add example/test/showcase/ docs/superpowers/specs/2026-07-26-fluent-grammar-roadmap-v2.md
git commit -m "test(showcase): gate Line and Area emission on the mounted pages"
```

---

## Final verification (before requesting a PR)

- [ ] Root `flutter test` green; `cd example && flutter test` green.
- [ ] `flutter test test/meta/` — drift gates green, `missing=0`.
- [ ] `flutter analyze lib` and `flutter analyze example/lib` — "No issues found!".
- [ ] `dart run tool/check_dart_format.dart` — passes.
- [ ] `chart_builder.dart` NUL sentinel intact (`NUL 1 CRLF 0 BOM False`).
- [ ] **Mutation check:** stub `_firstRadialMismatch` to `return null` and confirm tests FAIL; revert; confirm the tree is clean. The radial guard must stay load-bearing.
- [ ] **Over-broad-normalisation check:** widen the axis gate to drop the all-unbound condition and confirm the mixed-binding guard test FAILS; revert; confirm clean.
- [ ] Radial emission byte-identical; no pre-existing test expectation removed or loosened (`git diff origin/master..HEAD -- test/ example/test/`, every removal classified).
- [ ] Every carried field has an **emitted-text** assertion — the proof cannot see the text.
- [ ] Every emitted-text assertion is **scoped to the call it is about** — `unit:` is a `YAxisConfig` field as well as a mark field, so a whole-file `contains('unit:')` (or its negation) can be satisfied by text that says nothing about the field under test. Read the verb's own argument list (`literalArguments(source, '.geomLine(')`).
- [ ] `CHANGELOG.md` **Unreleased** records this item's public surface: `unit:` on the five Cartesian geom verbs (Slice 1), `label:`/`pointKey:`/`isXOrdered:` and the named `segmentStyle` refusal (Slice 3), plus the `SeriesMark<T>` intermediate. Slice 1 opened the entry; each later slice extends it.
- [ ] Rebase onto latest `origin/master`; re-run the suites. **Note:** `CHANGELOG.md` now overlaps master's release commit (0.16.0 moved the Unreleased body into a version section), so expect one trivial conflict there — keep this item's bullets under Unreleased.
- [ ] BC-0040 updated with the re-measured census before any status change.
