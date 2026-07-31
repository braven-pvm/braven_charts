# Pinning Emitted Grammar Arguments — Design

**Date:** 2026-07-31
**Status:** Approved (brainstorming). Next: implementation plan.
**Register:** BC-0046 (lane `chart-grammar`).
**Worktree/branch:** `F:\Repositories\braven_charts-emitted-gate`, `feature/grammar-emitted-argument-gate` (off `origin/master` `997b1028`).

## Goal

Every argument the grammar source emitter writes is pinned, so deleting its writer line fails a test instead of shipping a chain that silently drops a value.

## Why this is possible at all

**The round-trip proof does not read the emitted text.** The generator's own docstring says so, verified by mutation: deleting the `.grid(...)` and `.title(...)` emission produces *zero* refusals. The proof re-lowers the PLAN and compares that. The text a user copies out of the Workbench is guarded only where someone wrote an explicit assertion.

Nothing is broken today — the values are emitted correctly. The defect is that nothing would notice if they stopped being.

## The measured number

**40 of 90 argument sites are unpinned**, measured on merged master `997b1028` by *deleting each writer line and running the suite* — not by grep.

The method is sound because every gate involved is **monotone in deletions** (`contains(fragment)`, whole-list equality, and `dart analyze` error counts can only worsen as more arguments are removed). A run with all 40 blanked came back `+163: All tests passed!`, which proves each of the 40 individually. Every *pinned* verdict conversely comes from a failure message that names that argument.

| Family | Unpinned |
|---|---|
| Cartesian geometry + scatter | 12 |
| `.trend` | 8 |
| `.threshold` | 4 |
| `.band` | 3 |
| `.pointAt` | 4 |
| `GridConfig` | 5 of 6 |
| collapsed `.x(…, label:)` | 1 |
| radial `color` / polar `name`+`color` | 3 |
| **Total** | **40** |

**Corrections to this item's own filed figures**, both downward: the pre-#146 count was **51, not 54** (three sites were already pinned but grep-missed — `scatter.size`, `scatter.categoryBy`, `geom.showDataPointMarkers`), and PR #146 closed **11**, giving 40 rather than the estimated 47. #146 closed nothing outside Cartesian: annotations, grid, radial and polar are identical before and after.

## Mechanism (owner-decided, pilot-validated)

**Whole-argument-list equality** via the existing `literalArguments(source, opening)` helper, for the verbs; **per-case deletion coverage** for the nine `expectShowcaseEmits` cases, which have no `rebuilt:` closure.

The ruled-out alternative is recorded so it is not revisited: *"does the argument name appear in an assertion somewhere in `test/`"* credits **52 of 57 names (91%) over a surface that is 22% covered**. It counts `isNot(contains(...))` as coverage, credits `test/unit/models/grid_config_test.dart` — a file that never reads generated output — and is name-flat, so a `name:` pin in the pie shape credits `geomLine`'s. Building it would be worse than nothing.

### The pilot result that shapes everything

Piloted on `.trend(` (the worst survivor, 8 of 9 unpinned), and re-measured on the delivered fixture with one stated mutation set: `_emitTrend`'s **9 writer statements deleted one at a time, plus 1 unconditional probe argument added — 10 of 10 caught**. Against the **existing minimal** shape the identical assertion could catch at most **6 of those 9 deletions**: its emitted list is exactly `[id, of, method, name, color: Color(0xFF2196F3), lineWidth: 2.0]`, so `windowSize`, `showConfidenceBand` and `dashPattern` are never emitted by it. (An earlier draft said "11 of 11"; with 9 writer statements that denominator was not reproducible, so it is corrected here.)

**So coverage is a property of the FIXTURE, not of the assertion form.** A whole-list assertion pins the arguments its fixture emits and is blind to the rest. Every one of these assertions needs a fixture that sets every optional on that verb — not the nearest existing shape.

The same lever qualifies the headline justification. "Catches arguments added in future" holds for **unconditional** additions (measured: rc=1), but a *conditional* addition on a path the fixture does not exercise slips through green. The honest claim is **"catches any argument added on a path the pinned fixture exercises"** — which is again an argument for maximal fixtures.

Maximal fixtures also avoid a second trap: a minimal trend emits `color:` and `lineWidth:` the author never set, so its expected list contains **theme-resolved values** that a palette change would break. A maximal fixture sets every optional explicitly and contains none.

### Seven failure modes — five of them silent

1. **Single-line verb forms are unreachable** (silent). `literalArguments(source, '.x(')` does not error; it returns the *next* verb's body. Proven live: a wrong list was pinned, the collapsed-form writer deleted, and the test stayed green. This matters because the collapsed `.x(…, label:)` **is one of the 40 survivors** — it needs a whole-**line** assertion instead.
2. **A verb appearing twice** (silent): only the first instance is read. Mitigation already exists in the file at `:6721` — `expect('.geomPolar('.allMatches(source).length, 1);` — and becomes mandatory on every new assertion. Note `.trend(` can in principle be written by two code paths.
3. **Empty argument list** throws `RangeError` rather than returning `[]` (loud). No verb emits one today; a one-line guard covers it.
4. **The opening token inside a string literal** poisons the slice (loud, fails closed). Pinned fixtures must not carry labels/units/names containing an opening token.
5. **Prefix collisions** (silent, latent): `indexOf` matches anywhere, so a bare `ChartConfig(` would match inside `PolarChartConfig(`. **Rule: the opening must be `.verb(`, a `name: Type(` pair, or a bare `Type(` only when no other class in `lib/` ends with that token — audited with `grep -rn "class [A-Za-z_]*<Token>\b" lib/`, never assumed.** The bare form is needed because a wrapped verb is reached at its config type (see Architecture below) and the emitter does not always precede it with an argument name: `_emitGrid` writes a bare `GridConfig(` line. Where a `name: Type(` pair is available it is always preferred (`pane: PolarPaneConfig(`). The audited exception fails *closed* in the common case: if a suffix-matching type is ever emitted alongside the plain one, `allMatches(...).length` rises above 1 and the mandatory guard reddens. Only a source emitting the suffixed type and **no** plain occurrence would slice silently.
6. **"Every optional set" is not "every path live"** (silent). An argument whose VALUE selects which model field is read leaves the other arm dead no matter how maximal the fixture is. Measured on `_emitBand`: `(isY ? annotation.startY : annotation.startX)!`, with every band/threshold fixture on `AnnotationAxis.y` — swapping only the X operands left the source-generator and drift suites green. Such arguments need a **fixture per branch**; Slice 1 added a second X-axis band shape for exactly this.
7. **Equal-valued arguments hide a cross-wire** (silent). Whole-list equality pins the emitted TEXT, so two writers whose fixture values are *equal* cannot be told apart: swapping which model field feeds which argument name leaves the list byte-identical. Measured in `_emitGrid`, whose maximal fixture is **forced** into this position — it writes a boolean only when it differs from the `true` default, so `horizontal` and `vertical` must **both** be `false` to be emitted at all. Swapping the two operands (`valueIf('horizontal', grid.vertical, …); valueIf('vertical', grid.horizontal, …);`) left the maximal shape 40 GREEN (`00:03 +1: All tests passed!`) while the **minimal** shape 11, which sets only `horizontal`, went RED. So maximality is not strictly dominant: a minimal shape that sets one of a pair is the *only* thing that can catch their cross-wire, which is a second reason the existing minimal shapes are kept rather than rewritten. Where a fixture is free to choose, give paired arguments **distinct** values.

### The assertion pins text, not API

Whole-list equality proves the emitted characters and nothing about the builder. A rename in the emitter mirrored into the expected list stays green while the Grammar pane ships a chain that does not compile — measured on `.trend(` `showConfidenceBand`. Every maximal shape therefore also calls `expectGeneratedSourceCompiles` (real `dart format` + `dart analyze` subprocesses via `tester.runAsync`), which is the only gate in the repo that resolves emitted argument names against the real fluent surface. It matters most exactly here: a maximal fixture is usually the sole emitter of its rarest arguments.

### What the pattern costs

Nested config bodies **flatten into the list**, so these assertions also pin the *config* emitter's rendering — a change there breaks them, and it partly overlaps `source_emitter_drift_test.dart`. For scatter the coupling is unavoidable: `size:`/`colorBy:`/`opacityBy:` without their encodings throws `missingChannelEncoding`. Accepted deliberately, recorded so it is not a surprise.

**Argument order is nowhere data-dependent** — every chain-verb emitter writes a fixed sequence and conditionals only add or remove. There is no `for (final entry in map.entries) namedArgument(...)` anywhere in `lib/src/source/`. So freezing order is safe. The one data-ordered emission is the synthesised `GrammarRow` class and row literals, which are **not** chain verbs and must not be whole-listed.

## Architecture

**11 whole-list assertions + 1 whole-line assertion cover 39 + 1 = all 40 survivors.** No survivor needs deletion-coverage; that stays scoped to the nine showcase cases as decided.

| Opening | Survivors covered |
|---|---|
| `.geomCandlestick(` | 1 (`timestamp`) |
| `.geomArea(` | 1 (`baseline`) |
| `.geomBar(` | 6 |
| `.geomPoint(` | 4 |
| `.trend(` | 8 |
| `.threshold(` | 4 |
| `.band(` | 3 |
| `.pointAt(` | 4 |
| `GridConfig(` | 5 |
| `.geomPie(` / `.geomDonut(` | 1 (`color`) |
| `.geomPolar(` | 2 |
| whole-**line** `.x(` | 1 (collapsed `label:`) |

**One fixture per verb suffices** — verified for the two hardest. A single `.geomBar(` fixture emits all twelve arguments at once (`barWidthPercent` and `barWidthPixels` coexist, no warnings); a single `.geomPoint(` fixture emits size/colour/opacity channels with their encodings together.

Wrapped verbs open at the **config type**, not the verb: `GridConfig(`, `XAxisConfig(`, `InteractionConfig(`, `ChartTheme(` — opening at `.grid(` includes the wrapper lines in the list. These are the audited bare-`Type(` exception of failure mode 5, not a violation of it: `_emitGrid` writes the type on its own line with no preceding argument name, so no `name: Type(` pair exists to open at. Audited for `GridConfig(`: `grep -rn "class [A-Za-z_]*GridConfig\b" lib/` returns exactly one class (`lib/src/models/grid_config.dart:43`), and the only other emitted form is the config form's `grid: GridConfig(` (`chart_config_dart_emitter.dart:6443`), which would push `allMatches` to 2 and trip the mandatory guard.

### The mandatory shape

```dart
// The fixture is MAXIMAL: every optional on this verb set explicitly, so no
// theme-resolved value lands in the expected list and every conditional path is
// live. Anything this fixture does not emit is NOT pinned by this test.
final generated = generateGrammar(await snapshotOf(tester, maximalTrend));
expect(generated.warnings, isEmpty);
expect(generated.isComplete, isTrue);
// The slicer reads only the FIRST occurrence — guard the assumption.
expect('.trend('.allMatches(generated.source).length, 1);
expect(literalArguments(generated.source, '.trend('), <String>[ /* full list, in emitted order */ ]);
```

Four companions are non-negotiable, because three failure modes are silent:
1. **Maximal fixtures**, added as NEW shapes rather than by rewriting existing minimal ones — the minimal shapes are worth keeping, and a minimal-fixture list leaves conditionals unpinned.
2. **`allMatches(...).length == 1`** on every assertion.
3. **Openings are `.verb(`, `name: Type(`, or an audited bare `Type(`** (failure mode 5) — never an unaudited bare type name.
4. **Conditional arguments are pinned by making them LIVE in the fixture**, never by an optional entry in the expected list. Each test states in a comment that anything its fixture does not emit is unpinned, so a future reader cannot over-credit it.

## Invariants

- **No production behaviour changes.** This slice adds tests and fixtures only; `lib/` changes are limited to the one-line `literalArguments` empty-list guard if it is judged worth adding.
- **Existing emission byte-identical**; existing goldens unchanged; drift gates green.
- **No assertion weakened.** Existing fragment lists stay; whole-list assertions are added alongside.
- Every new assertion is **mutation-verified**: delete each argument it claims to pin and confirm it fails.

## Slices

1. **Annotation verbs** — `.trend` (8), `.threshold` (4), `.band` (3), `.pointAt` (4) = 19 survivors, the largest block, and the pilot already proved `.trend`. Four maximal fixtures, four whole-list assertions.
2. **Cartesian geometry + scatter** — `.geomBar` (6), `.geomPoint` (4), `.geomArea` (1), `.geomCandlestick` (1) = 12 survivors.
3. **Grid, axis and radial/polar tails** — `GridConfig(` (5), the whole-line `.x(…, label:)` (1), `.geomPie`/`.geomDonut` `color` (1), `.geomPolar` `name`+`color` (2) = 9 survivors.
4. **Showcase deletion coverage** — the nine `expectShowcaseEmits` cases, which have no `rebuilt:` closure and cannot use whole-list equality.

Each ends green and re-measures the survivor count, so the number falls visibly rather than being asserted.

## Testing

- Every new assertion **mutation-verified in both directions**: each argument it pins deleted (must fail), and an unconditional probe argument added (must fail).
- The final survivor count re-measured by the same deletion method, and recorded.
- No regression: full suite, example suite, drift gates, both analyzers, the changed-file format gate.

## Out of scope

- **The config emitter** — `chart_config_dart_emitter.dart` shares the hole at roughly 5× the size (652 sites, 396 names, 241 unasserted under a generous regex). Filed as **BC-0048**, to follow this item's mechanism.
- The `emitted ⊇ rebuilt` containment idea — the biggest lever, verified on one case only, and its normaliser is exactly where it could go silently vacuous. Stays a candidate behind a 5-case pilot.
- The 12 arguments no chart in the corpus emits: those need charts that set them, which the maximal fixtures in slices 1–3 provide as a side effect. Re-check at the end rather than assuming.
