# Convergence Slice 3e — Fix the series-emitter drops + extend the class-aware gate to cover series

> **For agentic workers:** REQUIRED SUB-SKILL: superpowers:subagent-driven-development or superpowers:executing-plans. Checkbox (`- [ ]`) steps.

**Goal:** Fix the real round-trip data-loss bugs where `_emitLineOptions`/`_emitAreaOptions` drop codec-round-tripped fields that only `_emitRangeAreaOptions` emits, and extend slice 3c's class-aware gate to cover the `$constructor`-dispatched series subclasses so this bug class can no longer hide.

**Background:** Slice 3c's class-aware gate deliberately left the series (and annotation) classes as *residual* because they are constructed via a shared `writer.writeLine('$constructor(')` opener (`_emitSeries`, `:343`) with no literal-ClassName block — so it can't attribute their fields. Adversarial verification proved that residual bucket hides **4 real bugs** (a field on the model + round-tripped by the codec, but dropped by the series emitter, and invisible to the flat-union gate via a name collision with `RangeAreaChartSeries`). This slice closes both the bugs and the hole.

**Confirmed bugs (verify each against source while fixing):**
1. `LineChartSeries.pathAnimation` — `_emitLineOptions` (`chart_config_dart_emitter.dart:1837-1874`) never emits it. Model: `chart_series.dart:351` (`PathAnimationStyle`, default `const PathAnimationStyle()`). Codec round-trips it (encode `chart_series_document_codec.dart:1065`, decode `:410`).
2. `AreaChartSeries.pathAnimation` — `_emitAreaOptions` (`:1876-1895`) never emits it. Model `chart_series.dart:711/738`.
3. `AreaChartSeries.fillGradient` — `_emitAreaOptions` never emits it. Model `chart_series.dart:724`, surface `AreaChartSeries.fillGradient`. Codec encode `:1145`, decode `:492`.
4. `ChartSeries.style` (`SeriesStyle?`, `chart_series.dart:77`) — dropped by ALL series emitters; codec round-trips it as `seriesStyle`. (minor)

**Reusable emit logic:** `_emitPathAnimationStyle` (`:1777`, currently called only at `:1689` inside `_emitRangeAreaOptions`) already emits a `PathAnimationStyle`. The `fillGradient` emission lives in `_emitRangeAreaOptions` (`:1629`). Reuse these.

## Global Constraints
- Worktree `F:\Repositories\braven_charts-convergence`, branch `feature/grammar-convergence` (after 3d `ea26c1e8`). Commit per task; do NOT push/PR.
- Conditional/default-gated emission → byte-identical for series not using these fields → zero golden drift. Existing `test/unit/source/` + `test/unit/artifacts/` tests must pass unchanged.
- `flutter analyze lib` (vendored-safe). Enforcement `missing=0`. No build_runner.

---

### Task 1: Fix the series-emitter drops

**Files:** `lib/src/source/chart_config_dart_emitter.dart`, `test/unit/source/chart_dart_source_generator_test.dart`

- [ ] **Step 1: Failing round-trip tests** — add a "slice 3e series-emitter gaps" group. Use non-default values so the fields must emit:
```dart
    test('emits LineChartSeries.pathAnimation', () {
      final g = _success(ChartDartSourceGenerator.generate(_snapshot(
        const LineChartSeries(id: 'l', points: [ChartDataPoint(x: 0, y: 1)],
          pathAnimation: PathAnimationStyle(entranceMode: PathEntranceAnimationMode.draw)),
      )));
      expect(g.source, contains('pathAnimation: PathAnimationStyle('));
      expect(g.source, contains('entranceMode: PathEntranceAnimationMode.draw,'));
    });
    test('emits AreaChartSeries.pathAnimation + fillGradient', () {
      final g = _success(ChartDartSourceGenerator.generate(_snapshot(
        const AreaChartSeries(id: 'a', points: [ChartDataPoint(x: 0, y: 1)],
          pathAnimation: PathAnimationStyle(entranceMode: PathEntranceAnimationMode.draw),
          fillGradient: AreaGradient(colors: [Color(0xFFAA0000), Color(0xFF0000AA)])),
      )));
      expect(g.source, contains('pathAnimation: PathAnimationStyle('));
      expect(g.source, contains('fillGradient: AreaGradient('));
    });
```
(Adjust to the real constructor param names/types — read `LineChartSeries`/`AreaChartSeries`/`AreaGradient`/`PathAnimationStyle`. Confirm `entranceMode`/`PathEntranceAnimationMode.draw` exist; else use any non-default field.)

- [ ] **Step 2: Run, verify fail** — `flutter test test/unit/source/chart_dart_source_generator_test.dart` → the new tests FAIL.

- [ ] **Step 3: Emit pathAnimation in the line + area emitters.** In `_emitLineOptions` and `_emitAreaOptions`, add a default-gated call reusing `_emitPathAnimationStyle` (read how `_emitRangeAreaOptions` at `:1689` calls it — replicate the same guard `if (options.includeDefaultValues || series.pathAnimation != const PathAnimationStyle())` and the same call form, with the correct series variable name). If `_emitPathAnimationStyle` hardcodes the `pathAnimation:` arg name, reuse as-is.

- [ ] **Step 4: Emit fillGradient in `_emitAreaOptions`.** Read the `_emitRangeAreaOptions` fillGradient emission (`:1629`) and replicate it for area (same `AreaGradient` shape — confirm AreaChartSeries.fillGradient and RangeArea use the same gradient type; if different, adapt). Guard on non-null / non-default.

- [ ] **Step 5: `style` (SeriesStyle) — assess and either fix or defer to the gate pin.** Read `SeriesStyle` (`chart_series.dart` around `:77`'s type). If it is a small value class with an obvious field set, add an `_emitSeriesStyle` helper and call it (default-gated) from the shared `_emitSeries` base (`:343-374`) so ALL series emit it; add a round-trip test. If SeriesStyle is large/complex enough to be its own slice, DO NOT force it — leave it un-emitted and it will be pinned in Task 2 with a reason (`SeriesStyle emission is a follow-up slice`). State which path you took and why.

- [ ] **Step 6: Run** — new tests pass; ALL existing `test/unit/source/` tests pass unchanged (default-gated → byte-identical). `flutter analyze lib` clean.

- [ ] **Step 7: Commit** — `fix(source): emit pathAnimation (line+area) and fillGradient (area) — were dropped on round-trip`.

---

### Task 2: Extend the class-aware gate to cover the series subclasses

**Files:** `test/meta/source_emitter_drift_test.dart`

The series are `$constructor`-dispatched, so 3c's block attributor skips them. Add a targeted, explicit **per-series completeness assertion** (robust: no `$constructor` parsing — an explicit method map).

- [ ] **Step 1: Add the per-series check.** Alongside the existing class-aware test:
  1. Define an explicit map `seriesEmitMethods = { 'LineChartSeries': '_emitLineOptions', 'AreaChartSeries': '_emitAreaOptions', 'ScatterChartSeries': '_emit…', 'BarChartSeries': '_emitBarOptions', 'CandlestickChartSeries': '_emit…', 'RangeAreaChartSeries': '_emitRangeAreaOptions', 'PolarColumnChartSeries': '_emit…', … }` — read the emitter's `_emitSeries` dispatch (`:343+`) to get the exact method for EVERY series subclass in `surfaceDefinitions`.
  2. **Assert the map is complete:** every modelled class whose name ends in `Series` (or is a `ChartSeries` subtype in the manifest) MUST be a key — fail if a series subclass is unmapped (this is the maintenance guard so a future series can't silently slip through).
  3. For each `(seriesClass, method)`: slice the method body (from `void <method>(` to its closing `}` at brace depth 0) PLUS the shared `_emitSeries` base block slice (the common fields all series emit), run `_emitterMentions` on the union, and assert every modelled property of `seriesClass` is named. Collect gaps.
  4. Allowlist `_seriesExpectedGaps` (`Set<String>` of `'Class.property'`) with one-line reasons for honest structural non-emits (e.g. the `style` discriminator `type:string` fields; `SeriesStyle.style` if deferred in Task 1; join-key/runtime fields). Fail on a NEW gap and on a stale allowlist entry.

- [ ] **Step 2: Run — after Task 1 the confirmed bugs must NOT appear.** `flutter test test/meta/source_emitter_drift_test.dart`. `LineChartSeries.pathAnimation`, `AreaChartSeries.pathAnimation`, `AreaChartSeries.fillGradient` must be GREEN (Task 1 fixed them). Any remaining gap → decide fix (back to Task 1) vs honest pin. Reconcile; do NOT mass-pin — if you see many gaps the method-slice is wrong.

- [ ] **Step 3: Non-vacuous proof.** Temporarily revert ONE Task-1 fix (e.g. comment out the line pathAnimation emit), confirm the per-series check FAILS naming `LineChartSeries.pathAnimation`, then restore. State the result.

- [ ] **Step 4: Update the residual list.** The series classes are no longer "residual" for the class-aware gate — move them from `_classAwareResidualClasses` to covered-by-the-per-series-check, and update the scope docstring. (Annotations remain residual unless you extend the same pattern to them — OUT of scope for this slice; note it.)

- [ ] **Step 5: Full verify** — `flutter analyze lib && flutter test`. Report total vs 3359; zero golden drift; enforcement `missing=0`. Flat-union test unchanged.

- [ ] **Step 6: Commit** — `test(meta): per-series completeness check closes the series-emitter blind spot`.

---

## Self-Review checklist
1. All 3 major bugs fixed with conditional emit (no golden drift); `style` fixed or honestly pinned with reason.
2. Per-series check covers EVERY series subclass (completeness-of-map asserted); non-vacuous proof recorded.
3. Series moved out of the residual bucket; annotations noted as the remaining residual (follow-up).
4. No mass-pinning; every gap fixed or pinned-with-reason.
5. Flat-union + existing class-aware tests unchanged and green.
