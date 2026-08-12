# Path-Field Completeness Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** `LineMark`, `AreaMark` and `RangeAreaMark` carry the path and marker fields their series already have, so configured Line/Area/Range-Area charts stop being refused for styling the grammar could express all along.

**Architecture:** Each mark gains nullable fields (null = the series default, resolved once at lowering). The Grammar emitter reverses a captured series back onto those fields **only when the captured value differs from the family default**, so a chart that sets none of them emits exactly the text it emits today. The three config objects involved already have private renderers in `ChartConfigDartEmitter`; the grammar side reaches them through new public seams rather than a second renderer.

**Tech Stack:** Dart ≥3.9 / Flutter. No new dependencies.

**Spec:** `docs/superpowers/specs/2026-08-03-grammar-path-fields-design.md`
**Register:** BC-0054 (lane `chart-grammar`).
**Worktree/branch:** `F:\Repositories\braven_charts-path-fields`, `feature/grammar-path-fields` (off master `b60ec846`).

## Global Constraints

- Work only in `F:\Repositories\braven_charts-path-fields` on `feature/grammar-path-fields`. **No PR without the owner's explicit OK.**
- Stage explicit paths: `git add <path> <path>`. **Never `git add -A`.** Never stage `example/windows/flutter/*`.
- `flutter analyze lib` **and** `cd example && flutter analyze lib`. **Never the repo root** — vendored `packages/fleather` pollutes it.
- Run `dart format` on changed files, then `dart run tool/check_dart_format.dart`. **This is a SEPARATE CI step from analyze and it is the FIRST real step of `package-quality.yml`** — a clean analyze does not imply a clean format gate. BC-0038 lost a gate cycle to exactly this.
- Commit messages end with: `Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>`
- Marks get no `copyWith` and no `@chartSurface` — standing decision, `mark.dart:50-57`.
- Existing goldens unchanged; drift gates 57/57.

### THE ONE RULE THAT WILL BITE

**Every newly carried field must be reversed through `_defaultedOrNull`, never verbatim.**

There are two conventions in `chart_grammar_source_generator.dart` and they behave differently:

- The **Line/Area** planner arms carry verbatim (`strokeWidth: series.strokeWidth`), and `series.strokeWidth` is non-nullable with default `2.0`. So every reversed line chart emits `strokeWidth: 2.0,` — pinned at `chart_grammar_source_generator_test.dart:992`.
- The **RangeArea** arm (BC-0038) uses `_defaultedOrNull(value, default)` (`:338`), so a defaulted capture becomes `null` on the mark and emits nothing.

`tension`, `lineGlow`, `dataPointMarkerRadius`, `dataPointMarkerStyle`, `dataPointMarkerBackground` and `pathAnimation` are all **non-nullable with defaults**. Carry any of them verbatim and EVERY line and area chart in the corpus starts emitting a new argument — changing existing emission and reddening every pinned whole-argument-list shape. Use `_defaultedOrNull` for all of them.

`fillGradient` and `inlineLabel` are already nullable, so they need no wrapper.

---

## File Structure

**`lib/` — modified:**

| File | Change |
|---|---|
| `lib/src/source/chart_config_dart_emitter.dart` | 3 public seams over existing private renderers |
| `lib/src/grammar/mark.dart` | new nullable fields on `LineMark`, `AreaMark`, `RangeAreaMark` (+ `==`/`hashCode`) |
| `lib/src/grammar/chart_builder.dart` | matching params on `geomLine`, `geomArea`, `geomRangeArea` |
| `lib/src/grammar/plot_lowering.dart` | `_lowerLine`, `_lowerArea`, `_lowerRangeArea` resolve null → series default |
| `lib/src/source/chart_grammar_source_generator.dart` | planner arms, `_emitGeometry` arms, and the shrinking `_firstUncarriedField` arms |

**Tests — modified/created:** `test/unit/grammar/chart_builder_test.dart`, `test/unit/grammar/plot_lowering_parity_test.dart`, `test/unit/source/chart_grammar_source_generator_test.dart`, `test/unit/source/chart_config_path_field_seams_test.dart` (new), `example/test/showcase/grammar_emission_census_test.dart`, plus a new mounted-page acceptance test.

**Docs:** `doc/chart_grammar.md`, `CHANGELOG.md`, the roadmap's 1d section.

### The complete field list

| Mark | New fields |
|---|---|
| `LineMark` | `tension`, `dataPointMarkerRadius`, `dataPointMarkerStyle`, `dataPointMarkerBackground`, `lineGlow`, `inlineLabel`, `pathAnimation` |
| `AreaMark` | the same seven, plus `fillGradient`, `aboveBaselineFillColor`, `belowBaselineFillColor` |
| `RangeAreaMark` | `fillGradient`, `pathAnimation` |

`dataPointMarkerBackground` is in this list for a reason the spec did not have: it exists on the series (`chart_series.dart:404`, default `Colors.white`), it is in `ChartSeries.==`, and it appears **nowhere** in `chart_grammar_source_generator.dart` — so a chart differing only in it falls into the unnamed generic tail today. Carrying it closes that without a separate slice.

---

### Task 1: Public seams over the existing renderers

**Files:**
- Modify: `lib/src/source/chart_config_dart_emitter.dart` (seams beside `emitRangeAreaLabelConfig`, ~line 225)
- Test: `test/unit/source/chart_config_path_field_seams_test.dart` (create)

**Interfaces:**
- Consumes: private `_emitFillGradient` (`:1962`), `_emitPathAnimationStyle` (`:2338`), `_emitInlineLabelArgument` (`:2590`).
- Produces, on `ChartConfigDartEmitter`:
  - `void emitFillGradient(DartSourceWriter writer, AreaGradient? gradient)`
  - `void emitPathAnimationStyle(DartSourceWriter writer, PathAnimationStyle style)`
  - `void emitInlineLabel(DartSourceWriter writer, SeriesInlineLabelConfig inlineLabel)`

No seam is needed for `dataPointMarkerStyle` (an enum, written with `_enumIf`), `dataPointMarkerBackground` / the baseline fill colours (colours), or the scalars — the grammar emitter writes those directly with its own helpers.

- [ ] **Step 1: Write the failing test**

```dart
// Copyright 2026 Braven Charts
// SPDX-License-Identifier: MIT

/// The path-field seams, pinned as ONE body.
///
/// The grammar geom verbs and the config form take the same nested literals.
/// Two renderers would drift the first time a field landed on only one of them,
/// so these assert the seam and the config path produce IDENTICAL text.
library;

import 'package:braven_charts/src/models/area_gradient.dart';
import 'package:braven_charts/src/models/path_animation_style.dart';
import 'package:braven_charts/src/source/chart_config_dart_emitter.dart';
import 'package:braven_charts/src/source/dart_source_writer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('emitFillGradient writes the gradient body', () {
    final writer = DartSourceWriter();
    _emitter().emitFillGradient(
      writer,
      const AreaGradient(colors: <Color>[Color(0xFF2563EB), Color(0x002563EB)]),
    );

    final source = writer.toString();
    expect(source, contains('fillGradient: AreaGradient('));
    expect(source, contains('Color(0xFF2563EB)'));
  });

  test('emitFillGradient writes NOTHING for a null gradient', () {
    final writer = DartSourceWriter();
    _emitter().emitFillGradient(writer, null);
    expect(writer.toString(), isEmpty);
  });

  test('emitPathAnimationStyle writes NOTHING for the family default', () {
    final writer = DartSourceWriter();
    _emitter().emitPathAnimationStyle(writer, const PathAnimationStyle());
    expect(writer.toString(), isEmpty);
  });

  test('emitPathAnimationStyle writes a non-default animation', () {
    final writer = DartSourceWriter();
    _emitter().emitPathAnimationStyle(
      writer,
      const PathAnimationStyle(entranceMode: PathEntranceAnimationMode.draw),
    );

    final source = writer.toString();
    expect(source, contains('pathAnimation: PathAnimationStyle('));
    expect(source, contains('entranceMode: PathEntranceAnimationMode.draw,'));
  });

  test('emitInlineLabel writes the inline-label body', () {
    final writer = DartSourceWriter();
    _emitter().emitInlineLabel(
      writer,
      const SeriesInlineLabelConfig(show: true),
    );

    final source = writer.toString();
    expect(source, contains('inlineLabel: SeriesInlineLabelConfig('));
    expect(source, contains('show: true,'));
  });
}
```

`_emitter()` builds a `ChartConfigDartEmitter` over a minimal snapshot. **Copy the construction helper from `test/unit/source/chart_config_range_area_seams_test.dart`** (BC-0038 added it) rather than inventing a second construction path. Fix the import paths and the `SeriesInlineLabelConfig` constructor arguments against the real classes — read them first; the field names above are the expected shape, not verified spellings.

- [ ] **Step 2: Run to verify it fails**

Run: `flutter test test/unit/source/chart_config_path_field_seams_test.dart`
Expected: FAIL — "The method 'emitFillGradient' isn't defined for the type 'ChartConfigDartEmitter'".

- [ ] **Step 3: Add the seams**

Beside `emitRangeAreaLabelConfig` (~line 225):

```dart
  /// Writes `fillGradient: AreaGradient(...)` — the field body `geomArea` and
  /// `geomRangeArea` hand to their `fillGradient:` argument, which is the config
  /// form's argument name too. Writes NOTHING for null, so the caller can pass
  /// it unconditionally.
  void emitFillGradient(DartSourceWriter writer, AreaGradient? gradient) =>
      _emitFillGradient(writer, gradient);

  /// Writes `pathAnimation: PathAnimationStyle(...)`. Writes NOTHING for the
  /// family default (unless `includeDefaultValues`).
  void emitPathAnimationStyle(
    DartSourceWriter writer,
    PathAnimationStyle style,
  ) => _emitPathAnimationStyle(writer, style);

  /// Writes `inlineLabel: SeriesInlineLabelConfig(...)`. Unconditional: the
  /// caller decides when the label is present and worth emitting.
  void emitInlineLabel(
    DartSourceWriter writer,
    SeriesInlineLabelConfig inlineLabel,
  ) => _emitInlineLabelArgument(writer, inlineLabel);
```

- [ ] **Step 4: Run to verify it passes**

Run: `flutter test test/unit/source/ && flutter analyze lib`
Expected: PASS; analyzer clean. **Every existing config-emitter test must be untouched** — adding a seam emits no new byte.

- [ ] **Step 5: Commit**

```bash
git add lib/src/source/chart_config_dart_emitter.dart test/unit/source/chart_config_path_field_seams_test.dart
git commit -m "refactor(source): expose the path-field nested-config seams

fillGradient, pathAnimation and inlineLabel already had private renderers; the
grammar verbs need the same bodies. One body, two callers - the drift
emitBarLabelStyle and emitRangeAreaBoundaryStyle already exist to prevent.

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

### Task 2: `LineMark` carries the path fields

**Files:**
- Modify: `lib/src/grammar/mark.dart` (`LineMark`)
- Modify: `lib/src/grammar/chart_builder.dart` (`geomLine`)
- Modify: `lib/src/grammar/plot_lowering.dart` (`_lowerLine`)
- Test: `test/unit/grammar/chart_builder_test.dart`, `test/unit/grammar/plot_lowering_parity_test.dart`

**Interfaces:**
- Produces: `LineMark` gains `tension: double?`, `dataPointMarkerRadius: double?`, `dataPointMarkerStyle: DataPointMarkerStyle?`, `dataPointMarkerBackground: Color?`, `lineGlow: double?`, `inlineLabel: SeriesInlineLabelConfig?`, `pathAnimation: PathAnimationStyle?`; `geomLine` gains the same seven named params; `_lowerLine` resolves each `?? _lineDefaults.<field>`.

- [ ] **Step 1: Write the failing tests**

Append to `test/unit/grammar/plot_lowering_parity_test.dart`:

```dart
  group('line path fields', () {
    test('every path field lowers onto the series', () {
      final lowered = BravenChart.of(_pathRows)
          .x((row) => row.x)
          .geomLine(
            y: (row) => row.y,
            tension: 0.6,
            dataPointMarkerRadius: 4.5,
            dataPointMarkerStyle: DataPointMarkerStyle.hollow,
            dataPointMarkerBackground: const Color(0xFF0F172A),
            lineGlow: 3,
            inlineLabel: const SeriesInlineLabelConfig(show: true),
            pathAnimation: const PathAnimationStyle(
              entranceMode: PathEntranceAnimationMode.draw,
            ),
          )
          .toSpec()
          .lower();

      final series = lowered.series.single as LineChartSeries;
      expect(series.tension, 0.6);
      expect(series.dataPointMarkerRadius, 4.5);
      expect(series.dataPointMarkerStyle, DataPointMarkerStyle.hollow);
      expect(series.dataPointMarkerBackground, const Color(0xFF0F172A));
      expect(series.lineGlow, 3);
      expect(series.inlineLabel?.show, isTrue);
      expect(series.pathAnimation.entranceMode, PathEntranceAnimationMode.draw);
    });

    test('an unset path field lowers to the series default, tracked not copied', () {
      // Compared against a FRESHLY CONSTRUCTED series so this tracks the class
      // rather than restating today's literals.
      const reference = LineChartSeries(id: 'reference', points: <ChartDataPoint>[]);

      final lowered = BravenChart.of(_pathRows)
          .x((row) => row.x)
          .geomLine(y: (row) => row.y)
          .toSpec()
          .lower();

      final series = lowered.series.single as LineChartSeries;
      expect(series.tension, reference.tension);
      expect(series.dataPointMarkerRadius, reference.dataPointMarkerRadius);
      expect(series.dataPointMarkerStyle, reference.dataPointMarkerStyle);
      expect(series.dataPointMarkerBackground, reference.dataPointMarkerBackground);
      expect(series.lineGlow, reference.lineGlow);
      expect(series.inlineLabel, reference.inlineLabel);
      expect(series.pathAnimation, reference.pathAnimation);
    });
  });
```

Add the fixture at the bottom of the file if one is not already present:

```dart
class _PathRow {
  const _PathRow(this.x, this.y);
  final double x;
  final double y;
}

const List<_PathRow> _pathRows = <_PathRow>[_PathRow(0, 1), _PathRow(1, 2)];
```

- [ ] **Step 2: Run to verify it fails**

Run: `flutter test test/unit/grammar/plot_lowering_parity_test.dart`
Expected: FAIL to compile — "No named parameter with the name 'tension'".

- [ ] **Step 3: Add the fields to `LineMark`**

Add the seven fields to the constructor and as `final` declarations, following the existing style, and add every one to **both** `operator ==` and `hashCode`. `LineMark` currently has 18 fields; adding 7 makes 25, so **`hashCode` must use `Object.hashAll([...])`** — `Object.hash` takes at most 20 positional arguments. (`RangeAreaMark` already does this for the same reason.)

Add the imports `mark.dart` needs: `AreaGradient`, `PathAnimationStyle`, `SeriesInlineLabelConfig`, `DataPointMarkerStyle` — check which are already imported before adding.

Document the nullable contract once, on the first new field, and refer to it from the others:

```dart
  /// Curve tension in `[0, 1]`. Null keeps the series default.
  ///
  /// Like every config field on this mark, null means "the `LineChartSeries`
  /// default", resolved once at lowering. The defaults live on the series class
  /// alone, so the mark cannot carry a stale copy of one.
  final double? tension;
```

- [ ] **Step 4: Add the verb parameters and the lowering**

`geomLine` gains the seven named params, passed straight through to `LineMark`.

`_lowerLine` resolves each against `_lineDefaults`:

```dart
  tension: mark.tension ?? _lineDefaults.tension,
  dataPointMarkerRadius:
      mark.dataPointMarkerRadius ?? _lineDefaults.dataPointMarkerRadius,
  dataPointMarkerStyle:
      mark.dataPointMarkerStyle ?? _lineDefaults.dataPointMarkerStyle,
  dataPointMarkerBackground:
      mark.dataPointMarkerBackground ?? _lineDefaults.dataPointMarkerBackground,
  lineGlow: mark.lineGlow ?? _lineDefaults.lineGlow,
  inlineLabel: mark.inlineLabel ?? _lineDefaults.inlineLabel,
  pathAnimation: mark.pathAnimation ?? _lineDefaults.pathAnimation,
```

- [ ] **Step 5: Run to verify it passes**

Run: `flutter test test/unit/grammar/ && flutter analyze lib`
Expected: PASS; analyzer clean.

- [ ] **Step 6: Commit**

```bash
git add lib/src/grammar/mark.dart lib/src/grammar/chart_builder.dart lib/src/grammar/plot_lowering.dart test/unit/grammar/plot_lowering_parity_test.dart
git commit -m "feat(grammar): LineMark carries the path and marker fields

Seven fields LineChartSeries already had. Nullable throughout - null means the
series default, resolved once at lowering, so the mark cannot carry a stale
copy. dataPointMarkerBackground is included because it appears nowhere in the
generator today, so a chart differing only in it falls to the unnamed tail.

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

### Task 3: `AreaMark` carries the path fields

Identical in shape to Task 2, over `AreaMark` / `geomArea` / `_lowerArea` / `_areaDefaults`, with three extra fields.

**Files:** same as Task 2.

**Interfaces:** `AreaMark` gains Task 2's seven plus `fillGradient: AreaGradient?`, `aboveBaselineFillColor: Color?`, `belowBaselineFillColor: Color?`.

- [ ] **Step 1: Write the failing tests**

Mirror Task 2 Step 1's two tests against `geomArea`, adding the three extra fields:

```dart
            fillGradient: const AreaGradient(
              colors: <Color>[Color(0xFF2563EB), Color(0x002563EB)],
            ),
            aboveBaselineFillColor: const Color(0xFF16A34A),
            belowBaselineFillColor: const Color(0xFFDC2626),
```

and the matching assertions, including the default-tracking test against a freshly built `AreaChartSeries`.

- [ ] **Step 2: Run to verify it fails**

Run: `flutter test test/unit/grammar/plot_lowering_parity_test.dart`
Expected: FAIL to compile — no named parameter `fillGradient` on `geomArea`.

- [ ] **Step 3: Add the fields, the verb params and the lowering**

Same shape as Task 2. `AreaMark` gains 10 fields; count the total and use `Object.hashAll` if it exceeds 20.

`fillGradient`, `aboveBaselineFillColor` and `belowBaselineFillColor` are **already nullable on the series**, so they lower as a plain pass-through (`fillGradient: mark.fillGradient`) — no `?? default` — while the seven non-nullable ones resolve against `_areaDefaults` exactly as in Task 2. Getting this backwards silently forces a null onto a non-nullable field or drops a real gradient; check each field's nullability on `AreaChartSeries` before writing the line.

- [ ] **Step 4: Run to verify it passes**

Run: `flutter test test/unit/grammar/ && flutter analyze lib`
Expected: PASS; analyzer clean.

- [ ] **Step 5: Commit**

```bash
git add lib/src/grammar/mark.dart lib/src/grammar/chart_builder.dart lib/src/grammar/plot_lowering.dart test/unit/grammar/plot_lowering_parity_test.dart
git commit -m "feat(grammar): AreaMark carries the path, marker and fill fields

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

### Task 4: `RangeAreaMark` carries `fillGradient` and `pathAnimation`

**Files:** same three `lib/` files; `_lowerRangeArea` and `_rangeAreaDefaults` already exist from BC-0038.

**Interfaces:** `RangeAreaMark` gains `fillGradient: AreaGradient?`, `pathAnimation: PathAnimationStyle?`.

- [ ] **Step 1: Write the failing test**

```dart
    test('a band carries a fill gradient and a path animation', () {
      final lowered = BravenChart.of(_bandRows)
          .x((row) => row.x)
          .geomRangeArea(
            low: (row) => row.low,
            high: (row) => row.high,
            fillGradient: const AreaGradient(
              colors: <Color>[Color(0xFF2563EB), Color(0x002563EB)],
            ),
            pathAnimation: const PathAnimationStyle(
              entranceMode: PathEntranceAnimationMode.draw,
            ),
          )
          .toSpec()
          .lower();

      final series = lowered.series.single as RangeAreaChartSeries;
      expect(series.fillGradient?.colors.first, const Color(0xFF2563EB));
      expect(series.pathAnimation.entranceMode, PathEntranceAnimationMode.draw);
    });
```

Reuse the `_bandRows` fixture BC-0038 added to this file.

- [ ] **Step 2: Run to verify it fails**

Run: `flutter test test/unit/grammar/plot_lowering_parity_test.dart`
Expected: FAIL to compile — no named parameter `fillGradient` on `geomRangeArea`.

- [ ] **Step 3: Implement**

Add both fields to `RangeAreaMark` (constructor, finals, `==`, the existing `hashAll`), both params to `geomRangeArea`, and in `_lowerRangeArea`:

```dart
      fillGradient: mark.fillGradient,
      pathAnimation: mark.pathAnimation ?? _rangeAreaDefaults.pathAnimation,
```

`fillGradient` is nullable on the series; `pathAnimation` is not.

- [ ] **Step 4: Run to verify it passes**

Run: `flutter test test/unit/grammar/ && flutter analyze lib`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/src/grammar/mark.dart lib/src/grammar/chart_builder.dart lib/src/grammar/plot_lowering.dart test/unit/grammar/plot_lowering_parity_test.dart
git commit -m "feat(grammar): RangeAreaMark carries fillGradient and pathAnimation

The two fields BC-0038 deliberately deferred to 1d so the Cartesian families
would gain them together rather than range area alone.

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

### Task 5: Emitter reversal — the task the byte-identical rule governs

**Files:**
- Modify: `lib/src/source/chart_grammar_source_generator.dart` — `_planGeometry` Line/Area/RangeArea arms, `_emitGeometry` Line/Area/RangeArea arms, `_firstUncarriedField` Line/Area/RangeArea arms
- Test: `test/unit/source/chart_grammar_source_generator_test.dart`

**Interfaces:**
- Consumes: the seams (Task 1) and the mark fields (Tasks 2–4).
- Produces: a captured Line/Area/Range-Area series carrying any of these fields reverses into a chain that reproduces it.

- [ ] **Step 1: Write the failing tests**

Three round-trip cases — one per family — each mounting a `BravenChartPlus` with a config-authored series carrying the new fields, asserting `contains('= BravenChart.of(')`, `warnings` empty, `isComplete` true.

Plus the guard that protects the whole slice:

```dart
    testWidgets('a chart that sets NO path field emits exactly what it emitted '
        'before this slice', (tester) async {
      // The byte-identical guard. Every new field is non-nullable on the series
      // with a default, so a verbatim reversal would make EVERY line chart in
      // the corpus start emitting `tension:`/`lineGlow:`/`pathAnimation:`.
      // `_defaultedOrNull` is what stops that, and this is what proves it.
      final generated = generateGrammar(
        await snapshotOf(
          tester,
          (controller) => BravenChart.of(rows)
              .x(sampleT)
              .geomLine(y: samplePower, name: 'Load')
              .build(bravenChartController: controller),
        ),
      );

      final args = literalArguments(generated.source, '.geomLine(');
      for (final name in const <String>[
        'tension:',
        'lineGlow:',
        'dataPointMarkerRadius:',
        'dataPointMarkerStyle:',
        'dataPointMarkerBackground:',
        'pathAnimation:',
        'inlineLabel:',
      ]) {
        expect(
          args.where((entry) => entry.startsWith(name)),
          isEmpty,
          reason: '$name must not be emitted by a chart that never set it',
        );
      }
    });
```

- [ ] **Step 2: Run to verify it fails**

Run: `flutter test test/unit/source/chart_grammar_source_generator_test.dart`
Expected: the three round-trip cases FAIL (the charts are refused, naming the field). The byte-identical guard PASSES already — that is correct; it is a regression guard, not a red-first test, and Step 4 is where it earns its place.

- [ ] **Step 3: Plan and emit**

In each of the three `_planGeometry` arms, add the new fields wrapped in `_defaultedOrNull` against a freshly-built defaults instance (`_lineDefaults` equivalents already exist in the generator for range area as `_rangeAreaEmitDefaults`; add `_lineEmitDefaults` / `_areaEmitDefaults` beside it in the same style if they do not exist). Nullable-on-the-series fields (`fillGradient`, `inlineLabel`, the baseline colours) pass through directly.

In each `_emitGeometry` arm, write the new arguments. Scalars through `_optionalNumber` / `_optionalColor`; the enum with an explicit `if (… != null)` writing `'DataPointMarkerStyle.${…!.name}'`; the three config objects through the Task 1 seams, each followed by `_absorbConfigWarnings()`.

Keep the emission ORDER mirroring `_emitLineOptions` / `_emitAreaOptions` so the two forms read alike.

- [ ] **Step 4: Shrink the `_firstUncarriedField` arms**

Delete the checks for every now-carried field, following BC-0040's precedent (its comments record exactly this: `// showDataPointMarkers and dataPointLabels are now carried by LineMark, so they are no longer in the uncarried set`).

After this the Line, Area and RangeArea arms are **empty**, like the candlestick and heatmap arms. Replace each body with a comment saying so and naming what still falls through to the generic tail, so the next reader does not think the arm was forgotten.

- [ ] **Step 5: Run and verify BOTH directions**

Run: `flutter test test/unit/source/ test/unit/grammar/ && flutter analyze lib`
Expected: PASS.

**If any pre-existing whole-argument-list shape (32–43) goes red, STOP.** That is the byte-identical rule being violated — a field is being carried verbatim instead of through `_defaultedOrNull`. Fix the planner arm; do NOT update the pinned expectation.

- [ ] **Step 6: Commit**

```bash
git add lib/src/source/chart_grammar_source_generator.dart test/unit/source/chart_grammar_source_generator_test.dart
git commit -m "feat(source): reverse the path fields onto the Cartesian marks

Every new field is non-nullable on its series with a default, so the reversal
maps a defaulted capture back to null via _defaultedOrNull - otherwise every
line and area chart in the corpus would start emitting arguments it never set.
The Line, Area and RangeArea uncarried-field arms are now empty.

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

### Task 6: Assertions, mounted-page acceptance, census, docs

**Files:**
- Modify: `test/unit/source/chart_grammar_source_generator_test.dart` (new maximal shapes)
- Create: `example/test/showcase/range_area_charts_page_grammar_test.dart`
- Modify: `example/test/showcase/grammar_emission_census_test.dart`
- Modify: `doc/chart_grammar.md`, `CHANGELOG.md`, `docs/superpowers/specs/2026-07-26-fluent-grammar-roadmap-v2.md`

- [ ] **Step 1: Extend the maximal shapes**

BC-0046's rule: every emitted grammar argument is pinned. The existing maximal shapes for `.geomLine(` and `.geomArea(` (shapes 38 and its line sibling) must **grow** to include the new arguments, and a new maximal `.geomRangeArea(` shape must extend shape 44.

Each fixture sets every new field explicitly and non-defaulted, keeps its `allMatches(…) == 1` guard, and asserts the whole argument list.

- [ ] **Step 2: Mutation-verify**

Delete each new writer statement in turn, confirm the shape goes red, revert. Apply and revert **inside a single shell invocation**, confirming with `git diff --numstat` that the mutation was applied before running. Report **N of N with N stated and the set enumerated** — a ratio with no denominator is not a result.

- [ ] **Step 3: Mounted-page acceptance for the RangeArea page**

Model on `example/test/showcase/selection_showcase_range_area_grammar_test.dart` (BC-0038) — mount `RangeAreaChartsPage`, drive its real preset picker, read each chart's live document off its own controller, run the generator, hold the compile floor.

Assert **6 of 7 presets emit**. `confidence` must still refuse, and its refusal must name the **x-domain divergence**, not a field — it is blocked by shared-x, which this slice does not touch. Pin that explicitly so a later slice cannot quietly count it.

- [ ] **Step 4: Update the census — RUN IT FIRST**

Run: `cd example && flutter test test/showcase/grammar_emission_census_test.dart`

Read the real numbers before editing any constant. Predicted `_expectedEmitting 59 → ~71` and Cartesian `[28, 129] → [~40, 129]`, but **the run is the authority**.

**The acceptance bar is the measured delta with its composition named**, not the predicted number. Write into the census file's provenance docstring which pages moved and by how much. If the delta is smaller than predicted, identify the second blocker on each state that did not move and record it — that is the useful output, not a number that matches.

- [ ] **Step 5: Docs**

`doc/chart_grammar.md` — document the new arguments on `geomLine`/`geomArea`/`geomRangeArea`.

`CHANGELOG.md` — under the existing `## Unreleased` → `### Added` only. **Never touch a dated, released section** — that has caused two merge repairs in this lane.

The roadmap's 1d section — record what this slice delivered, the measured delta, and what remains in 1d (the bar bucket, the scatter cluster, the naming slice).

- [ ] **Step 6: Full gate**

```bash
flutter test test/unit test/widgets test/meta test/integration test/golden
flutter test test/charts test/contract test/fluent test/models test/widget test/tool
cd example && flutter test && cd ..
flutter analyze lib
cd example && flutter analyze lib && cd ..
dart format $(git diff --name-only origin/master...HEAD -- '*.dart')
dart run tool/check_dart_format.dart
flutter test test/meta/
```

**Do not run the benchmarks inside the functional suite** — CI excludes `test/benchmarks/*` and runs each file separately at `--concurrency=1` (`ba6f18a9`). Running them together flakes a different timing-thresholded benchmark most runs. To check them: `find test/benchmarks -name '*_test.dart' | while read b; do flutter test "$b" --concurrency=1; done`.

- [ ] **Step 7: Commit**

```bash
git add test/unit/source/chart_grammar_source_generator_test.dart \
  example/test/showcase/range_area_charts_page_grammar_test.dart \
  example/test/showcase/grammar_emission_census_test.dart \
  doc/chart_grammar.md CHANGELOG.md \
  docs/superpowers/specs/2026-07-26-fluent-grammar-roadmap-v2.md
git commit -m "test(showcase): accept the Range Area page's grammar panes

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

## Verification summary (what the PR must state)

- Suite counts before and after; drift gates 57/57; both analyzers and the format gate clean.
- The mutation result for each new maximal shape as **N of N with N stated**.
- **The measured census delta with its composition named**, page by page — and for any predicted state that did NOT move, the second blocker that held it.
- That `confidence` still refuses on shared-x, by design.

## Self-review notes

- Spec coverage: §Scope → Tasks 2–4; §A seams → Task 1; §B/§C nullable + `_defaultedOrNull` → Tasks 2–5; §D the missing Area-arm checks → resolved by Task 5 Step 4 (carrying the fields makes the checks moot, which is why the arm is emptied rather than extended); §ordering trap → the whole slice is one branch; §prediction-is-not-a-forecast → Task 6 Step 4.
- One field is in this plan that the spec did not list: `dataPointMarkerBackground`. Reason stated in the File Structure section — it is invisible to the generator today.
- Names used consistently: `_defaultedOrNull`, `_lineDefaults`/`_areaDefaults` (lowering) vs `_lineEmitDefaults`/`_areaEmitDefaults` (generator — separate library, separate instances), `emitFillGradient`/`emitPathAnimationStyle`/`emitInlineLabel`.
- Two places name things the implementer must verify rather than trust: the `SeriesInlineLabelConfig` constructor arguments in Task 1's test, and whether `_lineEmitDefaults`/`_areaEmitDefaults` already exist in the generator. Both are flagged in-step.
