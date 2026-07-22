# Convergence Slice 3c — Class-aware Source-emitter gate (block-scoped) + fix `CandlestickDataPoint.categoryValue`

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development or superpowers:executing-plans. Steps use checkbox (`- [ ]`) syntax.

**Goal:** Close the name-collision blind spot in the Source-emitter drift gate for the classes emitted via a dedicated in-method construction block, and fix the one real bug that blind spot currently hides (`CandlestickDataPoint.categoryValue`, silently dropped on round-trip).

**Architecture:** The existing gate (`test/meta/source_emitter_drift_test.dart`) decides `isEmitted(property)` against ONE global name set — a property dropped by class B still counts as covered if class A emits the same name. This slice adds a **class-aware** check *alongside* the existing flat-union check: it slices the emitter source into construction blocks (`writer.writeLine('<field>: <ClassName>(')` … matching `writer.writeLine('),')` in the same method) and attributes emitted names to `<ClassName>`, so a per-class gap is caught. Deliberately scoped to blocks with a **literal ClassName opener whose close is in the same method** — the robust subset. Classes emitted via `$constructor` dispatch, the parameterized `_emitRadialStyle` (Pie/Donut), `*Fields` helpers (opener in caller), and sealed-union named-constructors are OUT of scope and remain on the existing global union (documented as the residual).

**Tech Stack:** Dart test (`test/meta/`), the emitter `lib/src/source/chart_config_dart_emitter.dart`.

## Global Constraints
- Worktree `F:\Repositories\braven_charts-convergence`, branch `feature/grammar-convergence` (continues after the rebase; latest commit is the 3b plan doc). Commit per task; push only when told.
- The existing flat-union test in `source_emitter_drift_test.dart` STAYS (it guards the residual shapes). The new class-aware test is ADDITIVE.
- Zero golden drift: the `categoryValue` fix emits conditionally (`_optionalString`), so charts without it stay byte-identical.
- `flutter analyze lib` clean (vendored-safe). Enforcement `missing=0`. No build_runner needed.

## Reference facts (from recon — verify against source while implementing)
- Existing extraction (`source_emitter_drift_test.dart:131-141`): `_emitterMentions(source)` unions three regexes over the source text — field reads `\.([a-z]\w*)`, single-quoted arg literals `'([a-z]\w*)'`, pattern bindings `:\s*final\s+([a-z]\w*)`. Coverage is `mentioned.contains(property)` (`:152`). **Reuse this exact regex set**, applied to a block slice instead of the whole file.
- The emitter has 112 construction blocks opened by a literal `writer.writeLine('<field>: <ClassName>(')` (field may be `$var`, ClassName is a literal in all 112), each balanced by `writer.writeLine('),')`, nesting mirrored by `writer.indented(() { … })`.
- The ONLY non-literal-ClassName openers (leave OUT of scope): 2× `writer.writeLine('$constructor(')` (`_emitSeries`, `_emitAnnotation` dispatchers), 1× `writer.writeLine('$argument: $constructor(')` (`_emitRadialStyle` → Pie/Donut), plus named-constructor/ternary openers (`RangeAreaDataPoint.gap(`, `CartesianValueSummaryPresentation.overlay(`/`.annotation(`, `CartesianValueSummaryContent.automatic(`) and `*Fields` helpers whose opener is in the caller (`_emitYAxisFields`, `_emitAxisFields`, `_emitResolvedThemeFields`, `_emitInteractionFields`).
- **The real bug:** `_emitCandlestickPoint` (~`:557-595`) constructs `CandlestickDataPoint(` but omits `categoryValue`, while `ChartDataPoint`/`RangeAreaDataPoint` emit it. `CandlestickDataPoint.categoryValue` is `String?`.

---

### Task 1: Fix the real bug — emit `CandlestickDataPoint.categoryValue`

**Files:** `lib/src/source/chart_config_dart_emitter.dart`, `test/unit/source/chart_dart_source_generator_test.dart`

- [ ] **Step 1: Confirm the codec persists it.** Read `lib/src/artifacts/chart_series_document_codec.dart` for `CandlestickDataPoint` encode/decode — confirm `categoryValue` survives the snapshot (like `ChartDataPoint.categoryValue`). If the codec drops it, STOP and report (the fix would be emitter-correct but not round-trippable — like the divergingRole codec-gating finding). Otherwise continue.

- [ ] **Step 2: Failing round-trip test** — add to the slice-3b group (or a new "slice 3c" group) in `chart_dart_source_generator_test.dart`:
```dart
    test('emits categoryValue for a candlestick data point', () {
      final generated = _success(ChartDartSourceGenerator.generate(_snapshot(
        const CandlestickChartSeries(
          id: 'c', barWidthPercent: 0.7,
          candles: [CandlestickDataPoint(x: 0, open: 1, high: 2, low: 0, close: 1.5, categoryValue: 'Q1')],
        ),
      )));
      expect(generated.source, contains("categoryValue: 'Q1',"));
    });
```
(Adjust the `CandlestickChartSeries`/`CandlestickDataPoint` constructor args to the real required params — read the classes.)

- [ ] **Step 3: Run, verify fail** — `flutter test test/unit/source/chart_dart_source_generator_test.dart` → the new test FAILS (categoryValue not emitted).

- [ ] **Step 4: Emit it.** In `_emitCandlestickPoint`, next to where the other optional point fields are emitted, add:
```dart
      _optionalString(writer, 'categoryValue', point.categoryValue);
```
(Match the emitter's local variable name for the point; confirm `_optionalString` is the helper `ChartDataPoint`'s categoryValue uses.)

- [ ] **Step 5: Run** — the new test PASSES; all existing `test/unit/source/` tests still pass unchanged (conditional emit → byte-identical for points without categoryValue). `flutter analyze lib` clean.

- [ ] **Step 6: Commit** — `git commit -m "fix(source): emit CandlestickDataPoint.categoryValue (was dropped on round-trip)"`.

---

### Task 2: Add the class-aware coverage check

**Files:** `test/meta/source_emitter_drift_test.dart`

- [ ] **Step 1: Write the block attributor + per-class assertion.** Add a new `test('...class-aware...')` (keep all existing tests). Design:
  1. Read the emitter source (same source the existing test reads).
  2. Scan for construction blocks: a line matching `writer.writeLine('...: <ClassName>(')` where `<ClassName>` is a `[A-Z]\w*` literal immediately before the trailing `(`. Track the enclosing method (a top-level `void _emit…(`/`emit…(` … `}`), and find the matching close `writer.writeLine('),')` by balancing `(`-openers/`),`-closers WITHIN the same method. If a block's close is not found within the method, SKIP it (out of scope).
  3. For each block, slice the source text from opener line to close line, run the existing `_emitterMentions` regexes on that slice, and attribute the resulting names to `<ClassName>` (union across all blocks of the same class).
  4. For each modelled class in `surfaceDefinitions` that has ≥1 attributed block, assert every modelled property is in that class's attributed name set — collecting `(class, property)` misses.
  5. Classes with NO attributed block are SKIPPED here (covered by the existing flat-union test) — collect their names into a `residualClasses` list for the diagnostic message, do not fail on them.
  6. Two reviewed allowlists mirroring the existing gate's idiom: `_classAwareExpectedGaps` (a `Set<String>` of `'Class.property'` the class-aware check tolerates) each with a one-line reason. Fail on any NEW class-aware gap not in the allowlist, and on a stale allowlist entry (a pinned gap that is now covered).

- [ ] **Step 2: Run it — expect it to surface the in-scope collision-hidden gaps.** `flutter test test/meta/source_emitter_drift_test.dart`. Expected failures name the in-scope real gaps. After Task 1, `CandlestickDataPoint.categoryValue` should NOT appear (fixed). If it still appears, Task 1's emit didn't land in an attributable block — fix Task 1. Record the exact set the check reports.

- [ ] **Step 3: Reconcile.** For each reported gap decide fix-vs-pin (the recon expects the in-scope set to be small — most of the 9 pairs are OUT of scope on `$constructor`/`_emitRadialStyle`/`*Fields`):
  - A genuine dropped field with a cheap conditional emit → FIX in the emitter (like categoryValue) and add a round-trip test.
  - A structurally-absent property (a discriminator like `series.style`, an intentionally-excluded field, a runtime callback like `BarLabelStyle.formatter` if it appears) → PIN in `_classAwareExpectedGaps` with a one-line reason.
  - If a whole class shows as a gap because its block wasn't attributed (a parser miss), do NOT pin the properties — instead exclude that class from the class-aware scope (add it to `residualClasses`) with a comment. Pinning a parser miss would hide real drift.

- [ ] **Step 4: Re-run — GREEN.** The class-aware test passes with the reconciled fixes + pins. Add a docstring at the top of the test explaining the scope (in-method literal-ClassName blocks) and the residual (dispatch/parameterized/Fields-helper/sealed-union classes stay on the flat-union test).

- [ ] **Step 5: Full verify.** `flutter analyze lib && flutter test` → report total vs 3353; zero golden drift; enforcement `missing=0`.

- [ ] **Step 6: Commit** — `git commit -m "test(meta): class-aware Source-emitter coverage for in-method construction blocks"`.

---

## Self-Review checklist
1. `categoryValue` fix: conditional emit, round-trips, no golden drift.
2. Class-aware check is ADDITIVE (flat-union test untouched); scope docstring present.
3. Every class-aware gap is either fixed or pinned-with-reason or excluded-as-parser-miss — no parser miss silently pinned.
4. Allowlist has no stale entries; the check fails on a new gap (prove by a scratch experiment if practical).
5. Residual classes (dispatch/parameterized/Fields/sealed-union) explicitly listed, not silently dropped.
