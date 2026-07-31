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

Piloted on `.trend(` (the worst survivor, 8 of 9 unpinned). Against a **maximal** fixture the assertion caught **11 of 11** mutations. Against the **existing minimal** shape the identical assertion caught only **6 of 9** — `windowSize`, `showConfidenceBand` and `dashPattern` slipped through green, because a minimal trend never emits them.

**So coverage is a property of the FIXTURE, not of the assertion form.** A whole-list assertion pins the arguments its fixture emits and is blind to the rest. Every one of these assertions needs a fixture that sets every optional on that verb — not the nearest existing shape.

The same lever qualifies the headline justification. "Catches arguments added in future" holds for **unconditional** additions (measured: rc=1), but a *conditional* addition on a path the fixture does not exercise slips through green. The honest claim is **"catches any argument added on a path the pinned fixture exercises"** — which is again an argument for maximal fixtures.

Maximal fixtures also avoid a second trap: a minimal trend emits `color:` and `lineWidth:` the author never set, so its expected list contains **theme-resolved values** that a palette change would break. A maximal fixture sets every optional explicitly and contains none.

### Five failure modes — three of them silent

1. **Single-line verb forms are unreachable** (silent). `literalArguments(source, '.x(')` does not error; it returns the *next* verb's body. Proven live: a wrong list was pinned, the collapsed-form writer deleted, and the test stayed green. This matters because the collapsed `.x(…, label:)` **is one of the 40 survivors** — it needs a whole-**line** assertion instead.
2. **A verb appearing twice** (silent): only the first instance is read. Mitigation already exists in the file at `:6721` — `expect('.geomPolar('.allMatches(source).length, 1);` — and becomes mandatory on every new assertion. Note `.trend(` can in principle be written by two code paths.
3. **Empty argument list** throws `RangeError` rather than returning `[]` (loud). No verb emits one today; a one-line guard covers it.
4. **The opening token inside a string literal** poisons the slice (loud, fails closed). Pinned fixtures must not carry labels/units/names containing an opening token.
5. **Prefix collisions** (silent, latent): `indexOf` matches anywhere, so a bare `ChartConfig(` would match inside `PolarChartConfig(`. **Rule: the opening must be `.verb(` or a `name: Type(` pair**, never a bare type name.

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

Wrapped verbs open at the **config type**, not the verb: `GridConfig(`, `XAxisConfig(`, `InteractionConfig(`, `ChartTheme(` — opening at `.grid(` includes the wrapper lines in the list.

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
3. **Openings are `.verb(` or `name: Type(`** — never a bare type name.
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
