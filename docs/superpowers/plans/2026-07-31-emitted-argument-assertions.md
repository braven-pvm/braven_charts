# Pinning Emitted Grammar Arguments — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Pin every argument the grammar source emitter writes, so deleting its writer line fails a test instead of shipping a chain that silently drops a value.

**Architecture:** Whole-argument-list equality via the existing `literalArguments(source, opening)` helper, asserted against **maximal** fixtures — one new shape per verb that sets every optional on it. Eleven whole-list assertions plus one whole-**line** assertion close all 40 survivors. Per-case deletion coverage handles the nine `expectShowcaseEmits` cases, which have no `rebuilt:` closure.

**Tech Stack:** Dart ≥3.9, Flutter; `flutter test`; `flutter analyze lib` and `flutter analyze example/lib` (never root — vendored `packages/fleather` pollutes it).

**Spec:** `docs/superpowers/specs/2026-07-31-emitted-argument-assertions-design.md`
**Register:** BC-0046 (lane `chart-grammar`)

## Global Constraints

- Worktree `F:\Repositories\braven_charts-emitted-gate`, branch `feature/grammar-emitted-argument-gate` (off `origin/master` `997b1028`). PR to master only on the owner's explicit go-ahead.
- **No production behaviour change.** This slice adds tests and fixtures only. The single permitted `lib/` change is the optional `literalArguments` empty-list guard in Task 1.1 — and that helper lives in `test/`, so `lib/` should end untouched.
- **No existing assertion weakened.** Whole-list assertions are **added alongside** existing fragment lists. Existing minimal shapes are kept — they are worth having, and a minimal-fixture list would leave conditionals unpinned.
- **Every new assertion is mutation-verified in BOTH directions**: each argument it claims to pin, deleted (must fail); and an unconditional probe argument added (must fail).
- Existing emission byte-identical; goldens unchanged; drift gates green.
- Analyze with `flutter analyze lib` **and** `flutter analyze example/lib`. Never root.
- Master has a **changed-file `dart format` gate**: run `dart run tool/check_dart_format.dart` from the repo root before committing. Its scopes include `example/test`.
- Stage with **specific `git add <paths>`** — never `git add -A`; never stage `example/windows/flutter/*` (known build cruft; `flutter test` regenerates it).
- Every commit message ends with: `Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>`
- **Mutation hygiene:** apply and revert every mutation experiment within the **same Bash invocation**, and confirm `git status --short` afterwards. Never leave the tree mutated across tool calls.
- **Line numbers shift.** Anchors below were read at `997b1028`; re-read before editing.

## Why this works, and the trap that defines it

**The round-trip proof never reads the emitted text.** The generator's own docstring says so, verified by mutation: deleting the `.grid(...)`/`.title(...)` emission produces *zero* refusals. So an emitted argument is guarded only where someone wrote an explicit assertion — that is the whole hole.

**Coverage is a property of the FIXTURE, not the assertion form.** Piloted on `.trend(`, then re-measured on the delivered shape 32 with one stated mutation set: `_emitTrend`'s **9** writer statements deleted one at a time plus **1** unconditional probe argument added — **10 of 10 caught**. The same assertion against the existing minimal shape 7 could catch at most **6 of those 9 deletions**: its emitted list is exactly `[id, of, method, name, color: Color(0xFF2196F3), lineWidth: 2.0]`, so `windowSize`, `showConfidenceBand` and `dashPattern` are never emitted by it — and the last two entries are theme-resolved values the author never set.

*(An earlier draft of this plan said "11 of 11 / 6 of 9". `_emitTrend` has 9 writer statements, so the 11 had no reproducible denominator; the numbers above are the measured ones. Always state the mutation set AND its size.)*

So **every assertion in this plan needs a fixture that sets every optional on its verb.** Anything a fixture does not emit is not pinned by it, full stop.

Maximal fixtures also avoid a second trap: a minimal trend emits `color:` and `lineWidth:` the author never set, so its expected list would contain **theme-resolved values** that a palette change breaks. Set every optional explicitly.

## Verified facts the plan depends on

Read at plan time — do not re-derive, but do re-locate:

- `literalArguments(String source, String opening)` — `test/unit/source/chart_grammar_source_generator_test.dart:2323-2334`. It slices by **indentation**: `indent` is the column of the opening token; the body is everything after that line; the literal ends at the first line that is exactly `indent` spaces then `)`.
- **15 existing call sites**, mostly `.geomLine(`. The canonical shape is at `:3006-3013`.
- The single-occurrence guard idiom already exists at `:6589` and `:6721` — `expect('.geomPolar('.allMatches(generated.source).length, 1);` — and at `:4482`/`:4548` for value strings.
- The existing minimal trend is **shape 7**, `:3706`.
- `.geomPolar(` is asserted with `length, 2` at `:4333` — proof that multi-occurrence charts are real, and why the guard matters.

## The 40 survivors, by opening

| Opening | Count | Arguments |
|---|---|---|
| `.trend(` | 8 | `id`, `method`, `windowSize`, `name`, `color`, `showConfidenceBand`, `lineWidth`, `dashPattern` |
| `.threshold(` | 4 | `id`, `color`, `strokeWidth`, `dashPattern` |
| `.band(` | 3 | `id`, `label`, `color` |
| `.pointAt(` | 4 | `id`, `label`, `color`, `markerSize` |
| `.geomBar(` | 6 | `barWidthPercent`, `barWidthPixels`, `barGap`, `layoutMode`, `groupId`, `baselineValue` |
| `.geomPoint(` | 4 | `colorBy`, `opacityBy`, `markerRadius`, `markerShape` |
| `.geomArea(` | 1 | `baseline` |
| `.geomCandlestick(` | 1 | `timestamp` |
| `GridConfig(` | 5 | `vertical`, `horizontalColor`, `verticalColor`, `horizontalStrokeWidth`, `verticalStrokeWidth` |
| `.geomPie(` / `.geomDonut(` | 1 | `color` |
| `.geomPolar(` | 2 | `name`, `color` |
| collapsed `.x(field, label:)` | 1 | `label` — **whole-LINE, not `literalArguments`** |

## The mandatory assertion shape

Every whole-list assertion in this plan takes this form. Deviating from it reintroduces a failure mode that was measured, not theorised.

```dart
testWidgets('shape NN: a MAXIMAL <verb> pins its whole argument list',
    (tester) async {
  // MAXIMAL fixture: every optional on this verb is set EXPLICITLY, so no
  // theme-resolved value lands in the expected list. Anything this fixture
  // does not emit is NOT pinned by this test — a whole-list assertion pins
  // what its fixture emits and is blind to the rest. State the mutation set
  // MEASURED for this shape, with its size, so a reader can reproduce it
  // (e.g. "9 writer-statement deletions + 1 unconditional probe: 10 of 10").
  final generated = generateGrammar(await snapshotOf(tester, /* fixture */));
  expect(generated.warnings, isEmpty);
  expect(generated.isComplete, isTrue);
  // The slicer reads only the FIRST occurrence of the opening token.
  expect('<opening>'.allMatches(generated.source).length, 1);
  expect(literalArguments(generated.source, '<opening>'), <String>[
    /* the complete list, in emitted order */
  ]);
  // MANDATORY. The list above pins emitted TEXT and nothing more; only
  // `dart analyze` against the real package proves those argument NAMES exist
  // on the builder. Without it, renaming an argument in the emitter and
  // mirroring the rename into the list above stays green while the Grammar
  // pane ships a chain that does not compile — measured on `.trend(`
  // `showConfidenceBand`: green without this gate, RED with it. Maximal
  // fixtures are usually the ONLY emitters of their rarest arguments, so
  // without this line those names are compiled by nothing in the repo.
  await tester.runAsync(
    () => expectGeneratedSourceCompiles(
      generated.source,
      fixtureName: 'grammar_source_<verb>_maximal',
    ),
  );
});
```

### Six failure modes — three silent. Respect all of them.

1. **SILENT — single-line verb forms are unreachable.** `literalArguments(source, '.x(')` does not error; it returns the **next** verb's body. Measured by pinning that wrong list, deleting the collapsed-form writer, and watching the test stay green. The collapsed `.x(…, label:)` **is** a survivor, so it gets a whole-**line** assertion (Task 3.2).
2. **SILENT — a verb appearing twice**: only the first is read. `expect('<opening>'.allMatches(source).length, 1);` is **mandatory on every assertion**.
3. **LOUD — an empty argument list** throws `RangeError` rather than returning `[]`. Guarded in Task 1.1.
4. **LOUD (fails closed) — the opening token inside a string literal** poisons the slice. Fixtures must not carry labels/units/names containing an opening token.
5. **SILENT/latent — prefix collisions.** `indexOf` matches anywhere, so a bare `ChartConfig(` matches inside `PolarChartConfig(`. **Openings must be `.verb(` or `name: Type(` — never a bare type name.** Wrapped verbs open at the **config type** (`GridConfig(`, `XAxisConfig(`, `InteractionConfig(`, `ChartTheme(`); opening at `.grid(` includes the wrapper lines.
6. **SILENT — "every optional set" ≠ "every path live".** An argument whose VALUE selects which model field is read leaves the other arm dead however many optionals the fixture sets. `_emitBand` is the measured case: `(isY ? annotation.startY : annotation.startX)!` — with every `.band(`/`.threshold(` fixture on `AnnotationAxis.y`, swapping only the X operands left the source-generator and drift suites green at `+190: All tests passed!`. Such an argument needs a **second fixture per branch** (Slice 1 added `shape 34b` for the X band), never one more optional on the first. Before writing a fixture, read its emitter for `? :` and `if (x == …)` on an argument VALUE — candidates in later slices include `layoutMode`, `markerShape` and the axis arguments.

**Order is safe to freeze** — every chain-verb emitter writes a fixed sequence and conditionals only add or remove; there is no `for (final entry in map.entries) namedArgument(...)` anywhere in `lib/src/source/`. **But the synthesised `GrammarRow` class and row literals ARE data-ordered — never whole-list those.**

**Accepted cost:** nested config bodies flatten into the list, so these assertions also pin `chart_config_dart_emitter` rendering. For scatter it is unavoidable — `size:`/`colorBy:`/`opacityBy:` without their encodings throws `missingChannelEncoding`.

---

# SLICE 1 — Annotation verbs (19 survivors, the largest block)

### Task 1.1: Guard the helper's empty-list `RangeError`

**Files:**
- Modify: `test/unit/source/chart_grammar_source_generator_test.dart:2323-2334`

**Interfaces:**
- Produces: `literalArguments` returns `const <String>[]` for an empty argument list instead of throwing.

- [ ] **Step 1: Write the failing test**

Put this beside the helper:

```dart
test('literalArguments returns an empty list for a verb with no arguments', () {
  // For `Verb(\n)` the computed bodyStart is one past end, and substring throws
  // RangeError. No verb emits an empty list today, but a config emitter that
  // drops the one field that differed would produce one, and a RangeError deep
  // inside a helper is a worse diagnostic than an empty list.
  const source = 'final chart = BravenChart.of(rows)\n'
      '    .verb(\n'
      '    )\n'
      '    .build();';
  expect(literalArguments(source, '.verb('), isEmpty);
});
```

- [ ] **Step 2: Run it — expect FAIL**

Run: `cd /f/Repositories/braven_charts-emitted-gate && flutter test test/unit/source/chart_grammar_source_generator_test.dart --plain-name 'literalArguments returns an empty list'`
Expected: FAIL with `RangeError (end): Invalid value: Not in inclusive range`.

- [ ] **Step 3: Add the guard**

In `literalArguments`, after `end` is computed and its `expect` passes:

```dart
  if (end < bodyStart) return const <String>[];
```

- [ ] **Step 4: Run it — expect PASS.** Then run the whole file to confirm the 15 existing call sites are unaffected.

Run: `flutter test test/unit/source/chart_grammar_source_generator_test.dart`

- [ ] **Step 5: Format gate, analyzes, commit**

```bash
dart run tool/check_dart_format.dart
flutter analyze lib && flutter analyze example/lib
git add test/unit/source/chart_grammar_source_generator_test.dart
git commit -m "test(source): make literalArguments return empty rather than throw"
```

### Task 1.2: Maximal `.trend(` — 8 survivors

**Files:**
- Modify: `test/unit/source/chart_grammar_source_generator_test.dart` (new shape beside shape 7 at `:3706`)

**Interfaces:**
- Consumes: `literalArguments` (Task 1.1), the file's existing `snapshotOf` / `generateGrammar` / `emittedChain` helpers.
- Produces: the pattern every later task copies.

- [ ] **Step 1: Write the failing test**

This fixture and expected list are **pilot-verified** — it caught 11 of 11 mutations.

```dart
testWidgets('shape 32: a MAXIMAL .trend( pins its whole argument list',
    (tester) async {
  // MAXIMAL: every optional on .trend( is set EXPLICITLY. Shape 7 above is the
  // minimal trend and stays — but the identical assertion against it catches
  // only 6 of 9 deletions, because a minimal trend never emits windowSize,
  // showConfidenceBand or dashPattern. Anything this fixture does not emit is
  // NOT pinned here.
  final generated = generateGrammar(
    await snapshotOf(
      tester,
      (controller) => BravenChart.of(rows)
          .x((row) => row.x)
          .geomLine(y: (row) => row.y, name: 'Power')
          .trend(
            of: 'mark-0',
            method: TrendType.movingAverage,
            windowSize: 3,
            id: 'fit',
            name: 'Trend',
            color: const Color(0xFF16A34A),
            showConfidenceBand: true,
            lineWidth: 1.5,
            dashPattern: const <double>[4, 2],
          )
          .build(bravenChartController: controller),
    ),
  );
  expect(generated.warnings, isEmpty);
  expect(generated.isComplete, isTrue);
  expect('.trend('.allMatches(generated.source).length, 1);
  expect(literalArguments(generated.source, '.trend('), <String>[
    "id: 'fit',",
    "of: 'mark-0',",
    'method: TrendType.movingAverage,',
    'windowSize: 3,',
    "name: 'Trend',",
    'color: Color(0xFF16A34A),',
    'showConfidenceBand: true,',
    'lineWidth: 1.5,',
    'dashPattern: <double>[4.0, 2.0],',
  ]);
});
```

Match the file's existing fixture conventions for `rows`/`snapshotOf` — read shape 7 at `:3706` and the canonical call site at `:3006` first. If the emitted order differs from the list above, **fix the list to the real order**, never the emitter.

- [ ] **Step 2: Run it.** If it fails, the failure message prints the actual list — correct the expectation to match reality and re-run until green.

- [ ] **Step 3: MUTATION-VERIFY, deletion direction — this is the point of the task**

For each of the 8 survivors (`id`, `method`, `windowSize`, `name`, `color`, `showConfidenceBand`, `lineWidth`, `dashPattern`), delete its `writer.namedArgument(...)` line in `_emitTrend` (`lib/src/source/chart_grammar_source_generator.dart:3546-3567`), run this test, and confirm it FAILS. Apply and revert **within one Bash invocation**:

```bash
cd /f/Repositories/braven_charts-emitted-gate && \
  cp lib/src/source/chart_grammar_source_generator.dart /tmp/gen.bak && \
  sed -i "/namedArgument('windowSize'/d" lib/src/source/chart_grammar_source_generator.dart && \
  flutter test test/unit/source/chart_grammar_source_generator_test.dart --plain-name 'shape 32'; \
  cp /tmp/gen.bak lib/src/source/chart_grammar_source_generator.dart && rm /tmp/gen.bak && git status --short
```

Report any argument whose deletion leaves the test green — that is a hole the assertion did not close.

- [ ] **Step 4: MUTATION-VERIFY, addition direction**

Add an unconditional `writer.namedArgument('probe', "'x'");` to `_emitTrend` and confirm the test FAILS (`which longer than expected`). Revert in the same invocation.

This is the property that justified choosing whole-list equality over fragment lists — verify it rather than assuming it. Note the honest limit: it catches additions **on a path the fixture exercises**; a conditional add on a dead path slips through (measured).

- [ ] **Step 5: Full suite, format gate, analyzes, commit**

```bash
flutter test && dart run tool/check_dart_format.dart
git add test/unit/source/chart_grammar_source_generator_test.dart
git commit -m "test(source): pin the whole .trend( argument list on a maximal fixture"
```

### Task 1.3: Maximal `.threshold(`, `.band(`, `.pointAt(` — 11 survivors

**Files:**
- Modify: `test/unit/source/chart_grammar_source_generator_test.dart`

**Interfaces:**
- Consumes: the pattern from Task 1.2.

- [ ] **Step 1: Read the three emitters and write down their emission order**

`_emitThreshold`, `_emitBand`, `_emitPoint` — `lib/src/source/chart_grammar_source_generator.dart:3569-3629`. Note which arguments are conditional; the fixture must make **every** one live.

- [ ] **Step 2: Write the three tests**

One per verb, each following the mandatory shape at the top of this plan. Here is `.threshold(` in full; `.band(` and `.pointAt(` take the identical shape with their own fixture and list.

```dart
testWidgets('shape 33: a MAXIMAL .threshold( pins its whole argument list',
    (tester) async {
  // MAXIMAL: every optional on .threshold( is set EXPLICITLY, so no
  // theme-resolved value lands in the expected list and every conditional
  // path is live. Anything this fixture does not emit is NOT pinned here.
  final generated = generateGrammar(
    await snapshotOf(
      tester,
      (controller) => BravenChart.of(rows)
          .x((row) => row.x)
          .geomLine(y: (row) => row.y)
          .threshold(
            value: 250,
            id: 'ftp',
            axis: ThresholdAxis.y,
            label: 'FTP',
            color: const Color(0xFFDC2626),
            strokeWidth: 2.5,
            dashPattern: const <double>[6, 3],
          )
          .build(bravenChartController: controller),
    ),
  );
  expect(generated.warnings, isEmpty);
  expect(generated.isComplete, isTrue);
  expect('.threshold('.allMatches(generated.source).length, 1);
  expect(literalArguments(generated.source, '.threshold('), <String>[
    "id: 'ftp',",
    'value: 250.0,',
    'axis: ThresholdAxis.y,',
    "label: 'FTP',",
    'color: Color(0xFFDC2626),',
    'strokeWidth: 2.5,',
    'dashPattern: <double>[6.0, 3.0],',
  ]);
});
```

Survivors each fixture must make live: `.threshold(` → `id`, `color`, `strokeWidth`, `dashPattern`; `.band(` → `id`, `label`, `color`; `.pointAt(` → `id`, `label`, `color`, `markerSize`. Check each verb's real parameter names and enum types on `BravenChart` before writing its fixture — the names above are from the emitter, and the builder's may differ.

- [ ] **Step 3: Run them**, correcting each expected list to the real emitted order.

- [ ] **Step 4: MUTATION-VERIFY both directions for all 11 arguments**, exactly as Task 1.2 Steps 3–4. Report any that slip.

- [ ] **Step 5: Re-measure the survivor count**

Delete all remaining survivors' writer lines at once, run the package suite, and record the new count. Slice 1 should have taken 40 → 21. Revert in the same invocation and confirm `git status --short` is clean.

- [ ] **Step 6: Full suite, format gate, analyzes, commit**

```bash
git add test/unit/source/chart_grammar_source_generator_test.dart
git commit -m "test(source): pin the whole .threshold(/.band(/.pointAt( argument lists"
```

---

# SLICE 2 — Cartesian geometry and scatter (12 survivors)

### Task 2.1: Maximal `.geomBar(` — 6 survivors

**Files:**
- Modify: `test/unit/source/chart_grammar_source_generator_test.dart`

- [ ] **Step 1: Write the failing test**

Verified during recon: a single `.geomBar(` fixture emits all twelve arguments at once — `barWidthPercent` and `barWidthPixels` **coexist**, no mutual exclusion, no warnings.

```dart
testWidgets('shape 36: a MAXIMAL .geomBar( pins its whole argument list',
    (tester) async {
  // MAXIMAL: every optional on .geomBar( is set EXPLICITLY. Recon verified one
  // fixture emits all twelve arguments together — barWidthPercent and
  // barWidthPixels are NOT mutually exclusive. Anything this fixture does not
  // emit is NOT pinned here.
  final generated = generateGrammar(
    await snapshotOf(
      tester,
      (controller) => BravenChart.of(rows)
          .x((row) => row.x)
          .geomBar(
            y: (row) => row.y,
            name: 'Output',
            color: const Color(0xFF2563EB),
            unit: 'W',
            isXOrdered: true,
            barWidthPercent: 0.6,
            barWidthPixels: 12,
            barGap: 4,
            layoutMode: BarLayoutMode.grouped,
            groupId: 'g1',
            baselineValue: 10,
          )
          .build(bravenChartController: controller),
    ),
  );
  expect(generated.warnings, isEmpty);
  expect(generated.isComplete, isTrue);
  expect('.geomBar('.allMatches(generated.source).length, 1);
  expect(literalArguments(generated.source, '.geomBar('), <String>[
    "id: 'mark-0',",
    'y: (row) => row.mark0,',
    "name: 'Output',",
    'color: Color(0xFF2563EB),',
    "unit: 'W',",
    'isXOrdered: true,',
    'barWidthPercent: 0.6,',
    'barWidthPixels: 12.0,',
    'barGap: 4.0,',
    'layoutMode: BarLayoutMode.grouped,',
    "groupId: 'g1',",
    'baselineValue: 10.0,',
  ]);
});
```

Confirm the real parameter names, enum type and emitted order against `_emitGeometry`'s bar arm and the `geomBar` signature before running — correct the expectation to reality, never the emitter.

- [ ] **Step 2: Run it**, correcting the expected list to reality.

- [ ] **Step 3: MUTATION-VERIFY both directions** for the 6 survivors, in `_emitGeometry`'s bar arm.

- [ ] **Step 4: Full suite, format gate, analyzes, commit**

```bash
git add test/unit/source/chart_grammar_source_generator_test.dart
git commit -m "test(source): pin the whole .geomBar( argument list on a maximal fixture"
```

### Task 2.2: Maximal `.geomPoint(`, `.geomArea(`, `.geomCandlestick(` — 6 survivors

**Files:**
- Modify: `test/unit/source/chart_grammar_source_generator_test.dart`

- [ ] **Step 1: Write the three tests**

`.geomPoint(` (survivors `colorBy`, `opacityBy`, `markerRadius`, `markerShape`) — verified during recon that one fixture emits size/sizeEncoding/colorBy/colorEncoding/opacityBy/opacityEncoding/markerRadius/markerShape together with `warnings` empty. **The channels must carry their encodings**: `size:`/`colorBy:`/`opacityBy:` without them throws `GrammarSpecException(missingChannelEncoding)`. Expect nested encoding bodies to flatten into the list — that is the accepted cost, and it means this assertion also pins the config emitter's rendering.

`.geomArea(` — survivor `baseline`. `.geomCandlestick(` — survivor `timestamp`, which is conditional on the plan carrying a stamp, so the fixture must supply timestamps.

- [ ] **Step 2: Run them**, correcting each expected list to reality.

- [ ] **Step 3: MUTATION-VERIFY both directions** for all 6 survivors.

- [ ] **Step 4: Re-measure.** Slice 2 should have taken 21 → 9. Record it.

- [ ] **Step 5: Full suite, format gate, analyzes, commit**

```bash
git add test/unit/source/chart_grammar_source_generator_test.dart
git commit -m "test(source): pin the whole .geomPoint(/.geomArea(/.geomCandlestick( lists"
```

---

# SLICE 3 — Grid, axis, radial and polar tails (9 survivors)

### Task 3.1: Maximal `GridConfig(` — 5 survivors

**Files:**
- Modify: `test/unit/source/chart_grammar_source_generator_test.dart`

- [ ] **Step 1: Write the failing test**

**Open at `GridConfig(`, not `.grid(`** — measured: opening at `.grid(` returns the wrapper lines (`GridConfig(`, …, `),`) while opening at `GridConfig(` returns the clean field list. This also honours failure mode 5: the opening is a `Type(` reached via the wrapper, and `GridConfig(` has no prefix collision (unlike a bare `ChartConfig(`).

Survivors to make live: `vertical`, `horizontalColor`, `verticalColor`, `horizontalStrokeWidth`, `verticalStrokeWidth`. `horizontal` is already pinned — include it in the list anyway, since this is whole-list equality.

- [ ] **Step 2: Run it**, correcting the expected list to reality.

- [ ] **Step 3: MUTATION-VERIFY both directions** for the 5 survivors in `_emitGrid`.

- [ ] **Step 4: Format gate, analyzes, commit**

```bash
git add test/unit/source/chart_grammar_source_generator_test.dart
git commit -m "test(source): pin the whole GridConfig( field list on a maximal fixture"
```

### Task 3.2: The collapsed `.x(field, label:)` — whole-LINE, not `literalArguments`

**Files:**
- Modify: `test/unit/source/chart_grammar_source_generator_test.dart`

**Interfaces:**
- Produces: the whole-line assertion form, for any single-line verb.

- [ ] **Step 1: Write the failing test**

`literalArguments` **cannot** read this form — measured: `literalArguments(source, '.x(')` silently returns the *next* verb's body, and a test pinned that way stayed green when the collapsed-form writer was deleted. Pin the trimmed line instead:

```dart
testWidgets('shape NN: the collapsed .x(field, label:) form is pinned by LINE',
    (tester) async {
  // literalArguments CANNOT read a single-line verb: it returns the NEXT
  // verb's body, and a test written that way stays green when this writer is
  // deleted (measured). Single-line verbs are pinned by their whole LINE.
  final generated = generateGrammar(await snapshotOf(tester, /* fixture with an x label */));
  expect(generated.warnings, isEmpty);
  final xLine = generated.source
      .split('\n')
      .map((line) => line.trim())
      .firstWhere((line) => line.startsWith('.x('));
  expect(xLine, ".x((row) => row.x, label: 'Elapsed')");
});
```

`split('\n')` avoids needing a `dart:convert` import the file may not carry. Confirm the exact emitted text — including whether the line ends in a trailing character — before pinning it.

- [ ] **Step 2: Run it**, correcting the expected line to reality.

- [ ] **Step 3: MUTATION-VERIFY** — delete the collapsed-form writer at `chart_grammar_source_generator.dart:3304-3309` and confirm this test FAILS. This is the mutation that a `literalArguments`-based test does **not** catch, so it is the whole justification for the different form.

- [ ] **Step 4: Format gate, analyzes, commit**

```bash
git add test/unit/source/chart_grammar_source_generator_test.dart
git commit -m "test(source): pin the collapsed .x(field, label:) form by whole line"
```

### Task 3.3: Radial and polar tails — 3 survivors

**Files:**
- Modify: `test/unit/source/chart_grammar_source_generator_test.dart`

- [ ] **Step 1: Write the two tests**

`.geomPie(`/`.geomDonut(` — survivor `color` (the series colour, `chart_grammar_source_generator.dart:3037`). `.geomPolar(` — survivors `name` (`:2971`) and `color` (`:2972`).

Both must set `allMatches(...).length == 1`; note `.geomPolar(` is asserted with `length, 2` at `:4333`, so a multi-series polar fixture would break the slicer — use a **single**-series fixture here.

- [ ] **Step 2: Run them**, correcting each expected list to reality.

- [ ] **Step 3: MUTATION-VERIFY both directions** for all 3 survivors.

- [ ] **Step 4: Re-measure.** Slice 3 should have taken 9 → 0 for the verb surface. Record it, and state plainly if anything remains.

- [ ] **Step 5: Full suite, format gate, analyzes, commit**

```bash
git add test/unit/source/chart_grammar_source_generator_test.dart
git commit -m "test(source): pin the radial and polar series colour and name arguments"
```

---

# SLICE 4 — Showcase deletion coverage

### Task 4.1: Per-case deletion coverage for the nine `expectShowcaseEmits` cases

**Files:**
- Modify: `test/unit/source/chart_grammar_source_generator_test.dart` (the `expectShowcaseEmits` harness)

**Interfaces:**
- Produces: each showcase case fails if an argument its own emitted chain contains is deleted.

- [ ] **Step 1: Read the harness**

Find `expectShowcaseEmits` and read what it asserts today. These cases have **no `rebuilt:` closure**, so whole-list equality does not apply — they need the deletion-coverage form instead.

- [ ] **Step 2: Write the failing test for ONE case first**

For a single showcase case, assert that its emitted source contains the arguments that case's chart actually sets. Derive the list from the real emitted output, not from the page source. Confirm it passes, then confirm it FAILS when one of those writer lines is deleted.

- [ ] **Step 3: Extend to the remaining eight**, each verified the same way.

- [ ] **Step 4: MUTATION-VERIFY across the set** — pick three arguments spanning different verbs, delete each, and confirm at least one showcase case fails for each.

- [ ] **Step 5: Full suite, example suite, format gate, analyzes, commit**

```bash
flutter test && (cd example && flutter test)
git add test/unit/source/chart_grammar_source_generator_test.dart
git commit -m "test(source): give the showcase emission cases deletion coverage"
```

### Task 4.2: Final re-measure and record

**Files:**
- Modify: `docs/superpowers/specs/2026-07-31-emitted-argument-assertions-design.md`, the BC-0046 register item

- [ ] **Step 1: Re-measure the survivor count by the same deletion method**

Blank every argument site the emitter writes, run the package and example suites, and record which sites survive. The method is valid because every gate involved is **monotone in deletions** — a green run with N blanked proves each of the N individually.

- [ ] **Step 2: Record the real number**

Update the spec's measured-number section and BC-0046's Evidence with the final count. **If any survivors remain, say which and why** — do not round to zero. The register lives OUTSIDE git: edit in place, run `validate` then `refresh`, never `git add` it.

```powershell
& 'F:\Repositories\_braven_charts_register\register.ps1' validate
& 'F:\Repositories\_braven_charts_register\register.ps1' refresh
```

- [ ] **Step 3: Commit**

```bash
git add docs/superpowers/specs/2026-07-31-emitted-argument-assertions-design.md
git commit -m "docs: record the measured survivor count after pinning"
```

---

## Final verification (before requesting a PR)

- [ ] Root `flutter test` green; `cd example && flutter test` green.
- [ ] `flutter test test/meta/` — drift gates green, `missing=0`.
- [ ] `flutter analyze lib` and `flutter analyze example/lib` — "No issues found!".
- [ ] `dart run tool/check_dart_format.dart` — passes.
- [ ] **`lib/` is untouched** — `git diff origin/master..HEAD -- lib/` is empty. This slice adds tests and fixtures only.
- [ ] **Every new assertion mutation-verified in both directions**, with the results reported per argument.
- [ ] No existing assertion weakened — `git diff origin/master..HEAD -- test/` with every removed line classified.
- [ ] Final survivor count re-measured and recorded, with any remainder named.
- [ ] Rebase onto latest `origin/master`; re-run the suites.
