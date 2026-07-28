# Radial Slice Colour, Per-Ring Labels and Donut Centre Parity — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make every radial Workbench Grammar pane emit a faithful, round-tripping chain — closing `ConcentricDonutPage`, `DonutChartsPage`, and the concentric family on `selection_showcase_page.dart`.

**Architecture:** Four independent carries plus a rename. `PieMark`/`DonutMark` gain a `sliceColor` accessor (mirroring `PolarMark.columnColor`); the donut centre is carried verbatim instead of reconstructed; `DonutMark` gains a `dataLabelsByRing` override map and a `ringIds` map; and the two showcase pages adopt the `'<markId>-<name>'` ring-id contract. The round-trip proof stays strict throughout — anything the marks cannot carry is refused with a named reason.

**Tech Stack:** Dart ≥3.9, Flutter; `flutter test`; `flutter analyze lib` and `flutter analyze example/lib` (never root — the vendored `packages/fleather` pollutes it).

**Spec:** `docs/superpowers/specs/2026-07-28-grammar-radial-slice-colour-design.md`
**Register:** BC-0032 (lane `chart-grammar`)

## Global Constraints

- Worktree `F:\Repositories\braven_charts-slice-colour`, branch `feature/grammar-radial-slice-colour` (off `origin/master` `da5dae1d`). PR to master only on the owner's explicit go-ahead.
- **Marks hold functions and config objects only** — no `copyWith`, no `@chartSurface` on marks. `DonutCenterContent` and `PieDataLabelConfig` are already `@chartSurface` (verified), so **add no new drift-gate surface**.
- **Byte-identical:** Cartesian, polar, pie, and uniform-label/default-centre donut and concentric emission must be unchanged. Existing goldens unchanged.
- **Never weaken an assertion to make something pass.** Where a *pinned known-gap test* must change because this slice removes the gap it pins, replace it with a stronger positive (round-trip) test and say so explicitly.
- **Acceptance is measured by mounting the real page** — read the live document off the workbench and run the generator on it. Never assert against a transcribed fixture; transcriptions carry a drift guard.
- **Field-allocation order is load-bearing:** `_synthesiseRadialRows` (`chart_grammar_source_generator.dart:1287`) sizes each row from the CURRENT slot counts. Any new `_addField` must happen BEFORE row synthesis or row writes throw `RangeError`.
- Preserve the `chart_builder.dart` NUL sentinel. After editing verify:
  `cd /f/Repositories/braven_charts-slice-colour && python -c "import pathlib; b=pathlib.Path('lib/src/grammar/chart_builder.dart').read_bytes(); print('NUL',b.count(0),'CRLF',b.count(b'\r\n'),'BOM',b[:3]==b'\xef\xbb\xbf')"` → `NUL 1 CRLF 0 BOM False`
- Stage with **specific `git add <paths>`** — never `git add -A`; never stage `example/windows/flutter/*` or `.gradle/*`.
- Every commit message ends with: `Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>`
- After each task: full `flutter test` green, `flutter analyze lib` + `flutter analyze example/lib` clean, drift gates (`flutter test test/meta/`) green.
- **Line numbers shift.** Every anchor below was read at `da5dae1d`; re-read the surrounding code before editing.

## File Structure

- `lib/src/grammar/mark.dart` — `PieMark.sliceColor`; `DonutMark.sliceColor` / `dataLabelsByRing` / `ringIds`.
- `lib/src/grammar/chart_builder.dart` — new `geomPie`/`geomDonut` params. **(NUL sentinel.)**
- `lib/src/grammar/plot_lowering.dart` — `_sliceColors` helper; `_lowerPie` (`:1368`), `_lowerDonut` (`:1388`), `_lowerConcentricRings` (`:1414`); per-ring label + explicit id resolution.
- `lib/src/grammar/grammar_diagnostics.dart` — ring-id diagnostics.
- `lib/src/source/chart_grammar_source_generator.dart` — `_RadialPlan` (`:313`), `_planPie` (`:914`), `_planDonut` (`:952`), `_planConcentric` (`:998`), `_fillRadialRows` (`:1269`), `_markCenter` (`:1326`), `_radialSeriesLossDetail` (`:1443`), `_emitDonutCenter` (`:2591`).
- `lib/src/source/chart_config_dart_emitter.dart` — `emitRadialLabelsByRing` seam; centre renderer parameterised on argument name (`_emitConcentricCenterContent` at `:3526`).
- `example/lib/showcase/pages/concentric_donut_page.dart`, `example/lib/showcase/pages/selection_showcase_page.dart` — conforming ring ids.

---

# SLICE 1 — `sliceColor` channel

### Task 1.1: `sliceColor` on `PieMark` and `DonutMark` + builder params

**Files:**
- Modify: `lib/src/grammar/mark.dart` (`PieMark`, `DonutMark`)
- Modify: `lib/src/grammar/chart_builder.dart` (`geomPie`, `geomDonut`)
- Test: `test/unit/grammar/mark_test.dart`, `test/unit/grammar/chart_builder_test.dart`

**Interfaces:**
- Produces: `PieMark.sliceColor` / `DonutMark.sliceColor`, both `final FieldAccessor<T, Color?>? sliceColor;`; builder params `sliceColor:` on `geomPie` and `geomDonut`.

- [ ] **Step 1: Write the failing test**

In `test/unit/grammar/mark_test.dart` (match the file's existing fixture/tear-off conventions — read a neighbouring test first):

```dart
test('sliceColor participates in PieMark and DonutMark equality', () {
  Color? red(Sample r) => const Color(0xFFFF0000);
  final pieA = PieMark<Sample>(
    category: sampleZone, value: samplePower, sliceColor: red);
  final pieB = PieMark<Sample>(category: sampleZone, value: samplePower);
  expect(pieA == pieB, isFalse);
  expect(pieB.sliceColor, isNull);

  final donutA = DonutMark<Sample>(
    category: sampleZone, value: samplePower, sliceColor: red);
  final donutB = DonutMark<Sample>(category: sampleZone, value: samplePower);
  expect(donutA == donutB, isFalse);
  expect(donutB.sliceColor, isNull);
});
```

- [ ] **Step 2: Run it — expect FAIL**

Run: `cd /f/Repositories/braven_charts-slice-colour && flutter test test/unit/grammar/mark_test.dart`
Expected: FAIL — `No named parameter with the name 'sliceColor'`.

- [ ] **Step 3: Add the field to both marks**

In `mark.dart`, add to `PieMark`'s constructor and `DonutMark`'s constructor `this.sliceColor,` and declare on each, copying the doc shape from `PolarMark.columnColor`:

```dart
/// Per-slice color override, keyed by the row's category. Returning null for a
/// row leaves that slice on the series color, which is what an unset accessor
/// does for every row.
final FieldAccessor<T, Color?>? sliceColor;
```

Add `other.sliceColor == sliceColor` to each `==` and `sliceColor` to each `hashCode`.

- [ ] **Step 4: Run it — expect PASS**

- [ ] **Step 5: Add the builder params + a builder test**

In `chart_builder.dart`, add `FieldAccessor<T, Color?>? sliceColor,` to `geomPie` and `geomDonut` and forward `sliceColor: sliceColor,`. Document it the way `geomPolar`'s `columnColor` is documented.

```dart
test('.geomPie / .geomDonut accept sliceColor', () {
  Color? red(Sample r) => const Color(0xFFFF0000);
  final pie = BravenChart.of(samples)
      .geomPie(category: sampleZone, value: samplePower, sliceColor: red)
      .toSpec();
  expect((pie.marks.single as PieMark<Sample>).sliceColor, isNotNull);
});
```

- [ ] **Step 6: Verify the NUL sentinel**

Run: `python -c "import pathlib; b=pathlib.Path('lib/src/grammar/chart_builder.dart').read_bytes(); print('NUL',b.count(0),'CRLF',b.count(b'\r\n'),'BOM',b[:3]==b'\xef\xbb\xbf')"`
Expected: `NUL 1 CRLF 0 BOM False`

- [ ] **Step 7: Full suite + both analyzes, then commit**

```bash
git add lib/src/grammar/mark.dart lib/src/grammar/chart_builder.dart test/unit/grammar/mark_test.dart test/unit/grammar/chart_builder_test.dart
git commit -m "feat(grammar): add sliceColor channel to PieMark and DonutMark"
```

### Task 1.2: Lowering builds `sliceColors`

**Files:**
- Modify: `lib/src/grammar/plot_lowering.dart` — new `_sliceColors`; `_lowerPie:1368`, `_lowerDonut:1388`, `_lowerConcentricRings:1414`
- Test: `test/unit/grammar/plot_lowering_radial_test.dart`

**Interfaces:**
- Consumes: `PieMark.sliceColor`, `DonutMark.sliceColor` (Task 1.1).
- Produces: `Map<String, Color> _sliceColors<T>(List<T> data, FieldAccessor<T, Object?> category, FieldAccessor<T, Color?> sliceColor)` — **skips null returns**.

- [ ] **Step 1: Write the failing test**

```dart
test('sliceColor lowers to per-point PointStyle colours, skipping nulls', () {
  final spec = PlotSpec<Fruit>(
    data: const [Fruit('apple', 3), Fruit('pear', 5)],
    marks: [
      PieMark<Fruit>(
        category: fruitName,
        value: fruitCount,
        sliceColor: (f) => f.name == 'apple' ? const Color(0xFF112233) : null,
      ),
    ],
  );
  final series = spec.lower().series.single as PieChartSeries;
  expect(series.points[0].pointStyle?.color, const Color(0xFF112233));
  expect(series.points[1].pointStyle, isNull);
});

test('sliceColor and radius compose on one point', () {
  final spec = PlotSpec<Fruit>(
    data: const [Fruit('apple', 3)],
    marks: [
      DonutMark<Fruit>(
        category: fruitName,
        value: fruitCount,
        radius: (f) => 10,
        sliceColor: (f) => const Color(0xFF445566),
      ),
    ],
  );
  final series = spec.lower().series.single as DonutChartSeries;
  expect(series.points.single.pointStyle?.color, const Color(0xFF445566));
  expect(series.points.single.pointStyle?.size, 10.0);
});
```

- [ ] **Step 2: Run — expect FAIL** (colour is null / `pointStyle` is null).

- [ ] **Step 3: Add the helper beside `_radiusValues` (`:1356`)**

```dart
/// Builds the per-category slice-colour map. A null return SKIPS the category
/// (leaving it on the series colour), so an unset accessor and an all-null
/// accessor produce the same series.
Map<String, Color> _sliceColors<T>(
  List<T> data,
  FieldAccessor<T, Object?> category,
  FieldAccessor<T, Color?> sliceColor,
) {
  final result = <String, Color>{};
  for (final row in data) {
    final color = sliceColor(row);
    if (color != null) result[category(row).toString()] = color;
  }
  return result;
}
```

- [ ] **Step 4: Wire it into all three lowering sites**

`_lowerPie` and `_lowerDonut` are expression-bodied (`=>`); convert each to a block body so the map is computed once, then pass `sliceColors:`. Example for `_lowerPie`:

```dart
PieChartSeries _lowerPie<T>(PieMark<T> mark, String id, List<T> data) {
  final sliceColors = mark.sliceColor == null
      ? const <String, Color>{}
      : _sliceColors(data, mark.category, mark.sliceColor!);
  return PieChartSeries.fromMap(
    id: id,
    name: mark.name,
    color: mark.color,
    unit: mark.unit,
    values: _radialValues(data, mark.category, mark.value),
    radiusValues: mark.radius == null
        ? const <String, num>{}
        : _radiusValues(data, mark.category, mark.radius!),
    sliceColors: sliceColors,
    sliceRadiusConfig: mark.sliceRadiusConfig,
    sliceGroupingConfig: mark.sliceGroupingConfig,
    pieStyle: mark.style ?? const PieChartStyle(),
    selectionStyle: mark.selectionStyle ?? const RadialSelectionStyle(),
    dataLabels: mark.dataLabels ?? const PieDataLabelConfig(),
  );
}
```

Do the same for `_lowerDonut`. In `_lowerConcentricRings` (`:1428-1445`), compute per bucket exactly as `radiusValues` already is:

```dart
sliceColors: mark.sliceColor == null
    ? const <String, Color>{}
    : _sliceColors(buckets[key]!, mark.category, mark.sliceColor!),
```

- [ ] **Step 5: Run — expect PASS.** Add a concentric per-ring-colour test and run it.

- [ ] **Step 6: Full suite + analyzes, then commit**

```bash
git add lib/src/grammar/plot_lowering.dart test/unit/grammar/plot_lowering_radial_test.dart
git commit -m "feat(grammar): lower sliceColor to per-slice point colours"
```

### Task 1.3: Emitter reverses `sliceColor` + family-aware refusal wording

**Files:**
- Modify: `lib/src/source/chart_grammar_source_generator.dart` — `_RadialPlan:313`, `_planPie:914`, `_planDonut:952`, `_planConcentric:998`, `_fillRadialRows:1269`, `_radialSeriesLossDetail:1443`, the radial emit arm
- Test: `test/unit/source/chart_grammar_source_generator_test.dart`

**Interfaces:**
- Consumes: lowering from Task 1.2.
- Produces: `_RadialPlan.sliceColor` (`_Field?`); emitted `sliceColor: (row) => row.sliceColor` after `radius:`/`ring:`.

- [ ] **Step 1: Write the failing round-trip test**

Copy the harness from a neighbouring radial round-trip test in this file. Assert a pie with `sliceColors` now emits, contains `sliceColor:`, and round-trips.

```dart
testWidgets('a pie with per-slice colours emits and round-trips',
    (tester) async {
  final snapshot = await snapshotOf(tester, (controller) => BravenChartPlus(
    controller: controller,
    series: [
      PieChartSeries.fromMap(
        id: 'pie',
        values: const {'A': 3, 'B': 5},
        sliceColors: const {'A': Color(0xFF112233)},
      ),
    ],
  ));
  final generated = generateGrammar(snapshot);
  expect(emittedChain(generated), isTrue);
  expect(generated.source, contains('sliceColor:'));
});
```

- [ ] **Step 2: Run — expect FAIL** (refused: the series carries a per-point colour the mark does not).

- [ ] **Step 3: Add the plan slot + allocate BEFORE row synthesis**

Add to `_RadialPlan`: `this.sliceColor,` and `final _Field? sliceColor;`.

Add a helper beside `_radialRadiusField` (`:1261`):

```dart
/// A slice-colour field when ANY point across [seriesList] carries a colour
/// override, or null otherwise.
_Field? _radialSliceColorField(List<ChartSeries> seriesList) {
  final hasColor = seriesList.any(
    (series) => series.points.any((point) => point.pointStyle?.color != null),
  );
  return hasColor ? _addField('sliceColor', _FieldKind.color) : null;
}
```

In `_planPie`, `_planDonut` and `_planConcentric`, call it **immediately after `_radialRadiusField` and BEFORE `_synthesiseRadialRows`** — rows are sized from the current slot counts, so allocating after throws `RangeError`. `_planConcentric` is the tight one: its field allocations sit at `:1008-1013`, its `_synthesiseRadialRows` right after.

- [ ] **Step 4: Fill the slot in both row-fill paths**

Extend `_fillRadialRows` with a `_Field? sliceColor` parameter and write through (null included):

```dart
if (sliceColor != null) {
  rows[index].colors[sliceColor.slot] = point.pointStyle?.color;
}
```

`_planConcentric` has its own inline fill loop — add the same write there.

- [ ] **Step 5: Wire the mark + emission**

Pass `sliceColor: sliceColor == null ? null : _color(sliceColor)` into the `PieMark`/`DonutMark` the plan builds, and emit it in the radial geometry arm after `radius:`/`ring:`:

```dart
if (plan.sliceColor != null) {
  writer.namedArgument('sliceColor', plan.sliceColor!.accessor());
}
```

- [ ] **Step 6: Run — expect PASS.** Then run the whole emitter file and confirm no existing expectation moved.

- [ ] **Step 7: Make `_radialSeriesLossDetail` family-aware**

It is shared by polar and pie/donut but their reversible sets now differ (pie/donut reverse colour **and** size; polar reverses colour only). Give it the captured series and branch:

```dart
String _radialSeriesLossDetail(ChartSeries expected, ChartSeries lowered) {
  final perPoint = expected is PolarColumnChartSeries
      ? 'a per-point style beyond a colour override'
      : 'a per-point style beyond a colour and size override';
  return 'It carries a series option the radial marks do not carry — the '
      'category, value, optional radius, concentric ring, donut center, unit, '
      'series style, selection style, data labels, (pie/donut) per-slice '
      'colours and the slice-radius and grouping configs and (polar) the '
      'preset, per-category column colours, targets and intervals round-trip, '
      'but series metadata, $perPoint, and an all-null polar interval list do '
      'not.';
}
```

Two existing test assertions key on the current wording — find them (`grep -n "beyond a colour override" test/`) and update them to the family-correct phrasing. **This is a wording change, not a weakening: keep asserting that the reason is named.**

- [ ] **Step 8: Add the three refusal tests + the pinned-gap conversion**

Add refusals (each must assert `emittedChain == false` AND the named reason):

Helpers already in this file: `snapshotOf` (`:1826`), `generateGrammar` (`:1848`), `emittedChain` (`:2029`), `blockedReason` (`:2033`).

```dart
testWidgets('a donut point whose pointStyle sets a scatter marker is refused',
    (tester) async {
  final snapshot = await snapshotOf(tester, (controller) => BravenChartPlus(
    controller: controller,
    series: [
      DonutChartSeries(
        id: 'donut',
        points: const [
          ChartDataPoint(x: 0, y: 3, label: 'A',
              pointStyle: PointStyle(color: Color(0xFF112233))),
          ChartDataPoint(x: 1, y: 5, label: 'B',
              pointStyle: PointStyle(
                  color: Color(0xFF445566),
                  scatterMarkerShape: ScatterMarkerShape.square)),
        ],
      ),
    ],
  ));
  final generated = generateGrammar(snapshot);
  expect(emittedChain(generated), isFalse);
  expect(blockedReason(generated), contains('per-point style'));
});

testWidgets('a donut point carrying a bare const PointStyle() is refused',
    (tester) async {
  // The document codec writes `pointStyle: {}` and decodes it back to a
  // NON-NULL const PointStyle(), while the grammar reversal yields null. The
  // asymmetry is real, so it must stay an honest refusal rather than emit a
  // chain that silently drops it.
  final snapshot = await snapshotOf(tester, (controller) => BravenChartPlus(
    controller: controller,
    series: [
      DonutChartSeries(
        id: 'donut',
        points: const [
          ChartDataPoint(x: 0, y: 3, label: 'A', pointStyle: PointStyle()),
          ChartDataPoint(x: 1, y: 5, label: 'B'),
        ],
      ),
    ],
  ));
  final generated = generateGrammar(snapshot);
  expect(emittedChain(generated), isFalse);
  expect(blockedReason(generated), contains('per-point style'));
});

testWidgets('a donut mixing colour-only and size-only points is refused',
    (tester) async {
  // A carries size only, B colour only. `_radialRadiusField` allocates the
  // radius field on ANY size and `_fillRadialRows` synthesises 0 for sizeless
  // rows, so B re-lowers with `size: 0.0` where the capture had null. That is
  // CORRECT behaviour — pinned here so a later reader does not mistake it for a
  // regression and "fix" it by loosening the proof.
  final snapshot = await snapshotOf(tester, (controller) => BravenChartPlus(
    controller: controller,
    series: [
      DonutChartSeries(
        id: 'donut',
        points: const [
          ChartDataPoint(x: 0, y: 3, label: 'A',
              pointStyle: PointStyle(size: 10)),
          ChartDataPoint(x: 1, y: 5, label: 'B',
              pointStyle: PointStyle(color: Color(0xFF112233))),
        ],
      ),
    ],
  ));
  final generated = generateGrammar(snapshot);
  expect(emittedChain(generated), isFalse);
});
```

Run each and confirm the refusal reason is the one you expect — if a message differs from the assertion, fix the ASSERTION to the real message, never the message to suit the test.

Then find the pinned known-gap test asserting "blocker 2: per-slice colours are refused" (`grep -n "blocker 2" test/unit/source/chart_grammar_source_generator_test.dart`) and **convert it to an acceptance test** that asserts the same chart now emits and round-trips. Do not delete it silently — the replacement must be strictly stronger, and note the conversion in the commit body.

- [ ] **Step 9: Full suite + drift gates + both analyzes, then commit**

```bash
git add lib/src/source/chart_grammar_source_generator.dart test/unit/source/chart_grammar_source_generator_test.dart
git commit -m "feat(source): reverse per-slice colours on pie and donut"
```

---

# SLICE 2 — Donut centre parity (`DonutChartsPage` DONE)

### Task 2.1: Carry the centre verbatim + shared full-fidelity renderer

**Files:**
- Modify: `lib/src/source/chart_grammar_source_generator.dart` — `_markCenter:1326`, `_planDonut:952`, `_emitDonutCenter:2591`
- Modify: `lib/src/source/chart_config_dart_emitter.dart` — parameterise `_emitConcentricCenterContent:3526` on the argument name and expose a seam
- Test: `test/unit/source/chart_grammar_source_generator_test.dart`

**Interfaces:**
- Produces: `ChartConfigDartEmitter.emitDonutCenterContent(DartSourceWriter writer, String argument, DonutCenterContent center)` — emits `<argument>: DonutCenterContent(...)` with `labelStyle`, `valueStyle`, and a `// valueFormatter:` placeholder + `runtimeValueOmitted` warning.

- [ ] **Step 1: Write the failing test**

```dart
testWidgets('a donut with a styled centre and a formatter emits, incomplete',
    (tester) async {
  final snapshot = await snapshotOf(tester, (controller) => BravenChartPlus(
    controller: controller,
    series: [
      DonutChartSeries.fromMap(
        id: 'donut',
        values: const {'A': 3, 'B': 5},
        centerContent: DonutCenterContent(
          label: 'Total',
          labelStyle: const LabelStyle(fontSize: 13),
          valueFormatter: (value) => value.toStringAsFixed(1),
        ),
      ),
    ],
  ));
  final generated = generateGrammar(snapshot);
  expect(emittedChain(generated), isTrue);
  expect(generated.source, contains('labelStyle:'));
  expect(generated.source, contains('// valueFormatter:'));
  expect(generated.isComplete, isFalse);
});
```

- [ ] **Step 2: Run — expect FAIL** (refused: the reconstructed centre differs).

- [ ] **Step 3: Carry the centre verbatim**

`_markCenter` currently rebuilds a centre from four fields, dropping `labelStyle`/`valueStyle`/`valueFormatter`. Change it to return the **captured object unchanged** when it differs from the no-op:

```dart
/// The centre to carry on the mark, or null when the captured centre is the
/// [noOp] the lowering restores for a mark that carries none. The captured
/// object is carried VERBATIM — styles and formatter included — so the proof
/// compares like with like; the formatter is a live callback and degrades to an
/// honest placeholder at emission, not at capture.
DonutCenterContent? _markCenter(
  DonutCenterContent captured,
  DonutCenterContent noOp,
) => captured == noOp ? null : captured;
```

Update its doc comment (the old one claims the drop is deliberate) and the `_planDonut`/`_planConcentric` comments that reference it.

- [ ] **Step 4: Replace `_emitDonutCenter` with the shared renderer**

In `chart_config_dart_emitter.dart`, extract the body of `_emitConcentricCenterContent` into a helper taking the argument name, then expose:

```dart
/// Emits `<argument>: DonutCenterContent(...)` for the grammar `center:` form,
/// reusing the config form's rendering so the two cannot disagree. A live
/// `valueFormatter` has no literal form and is emitted as an honest placeholder
/// with a `runtimeValueOmitted` warning.
void emitDonutCenterContent(
  DartSourceWriter writer,
  String argument,
  DonutCenterContent center,
) => _emitCenterContentArgument(writer, argument, center);
```

Keep the existing config-form caller passing `'centerContent'`. In the generator, delete `_emitDonutCenter` and call `_config.emitDonutCenterContent(writer, 'center', plan.center!)`, then `_absorbConfigWarnings()` so the omission warning propagates.

- [ ] **Step 5: Run — expect PASS.** Run the whole emitter file; a default/hidden centre must still emit nothing (byte-identical).

- [ ] **Step 6: Add the mounted-page acceptance test**

Mount the REAL `DonutChartsPage`, pull the document off the chart's own controller, and generate. Copy the mounting harness from the polar acceptance group added in item 1a′ (`grep -n "ACCEPTANCE GATE" test/unit/source/chart_grammar_source_generator_test.dart`).

```dart
testWidgets('ACCEPTANCE: the real DonutChartsPage emits', (tester) async {
  // Mount DonutChartsPage, read the live BravenChartPlus document, generate.
  expect(emittedChain(generated), isTrue);
  // A live centre formatter has no literal form: the chain is emitted with an
  // honest placeholder and is deliberately incomplete.
  expect(generated.isComplete, isFalse);
  expect(warningCodes(generated), contains(ChartSourceWarningCodes.runtimeValueOmitted));
});
```

If it does not emit, diagnose the real gap and fix it — do **not** weaken the assertion.

- [ ] **Step 7: Full suite + drift gates + both analyzes, then commit**

```bash
git add lib/src/source/chart_grammar_source_generator.dart lib/src/source/chart_config_dart_emitter.dart test/unit/source/chart_grammar_source_generator_test.dart
git commit -m "fix(source): carry the donut centre verbatim so styled centres emit"
```

---

# SLICE 3 — `dataLabelsByRing`

### Task 3.1: `DonutMark.dataLabelsByRing` + builder param

**Files:**
- Modify: `lib/src/grammar/mark.dart` (`DonutMark`), `lib/src/grammar/chart_builder.dart` (`geomDonut`)
- Test: `test/unit/grammar/mark_test.dart`

**Interfaces:**
- Produces: `final Map<String, PieDataLabelConfig>? dataLabelsByRing;` on `DonutMark`; `dataLabelsByRing:` on `geomDonut`.

- [ ] **Step 1: Write the failing test**

```dart
test('dataLabelsByRing participates in DonutMark equality', () {
  final a = DonutMark<Sample>(
    category: sampleZone, value: samplePower, ring: sampleRing,
    dataLabelsByRing: const {'outer': PieDataLabelConfig(showValues: true)},
  );
  final b = DonutMark<Sample>(
    category: sampleZone, value: samplePower, ring: sampleRing);
  expect(a == b, isFalse);
  expect(b.dataLabelsByRing, isNull);
});
```

- [ ] **Step 2: Run — expect FAIL.**

- [ ] **Step 3: Add the field**

```dart
/// Per-ring data-label overrides, keyed by the BARE ring key (the value the
/// `ring` accessor returns, which becomes each ring series' name). A ring with
/// no entry uses [dataLabels]; [dataLabels] itself remains the base for every
/// ring. Null means every ring shares [dataLabels].
final Map<String, PieDataLabelConfig>? dataLabelsByRing;
```

Use `mapEquals(other.dataLabelsByRing, dataLabelsByRing)` in `==` (import `package:flutter/foundation.dart` if not already) and `dataLabelsByRing == null ? null : Object.hashAllUnordered(dataLabelsByRing!.entries.map((e) => Object.hash(e.key, e.value)))` in `hashCode`.

- [ ] **Step 4: Run — expect PASS.** Add the `geomDonut` param + a builder test, then re-verify the NUL sentinel (Global Constraints).

- [ ] **Step 5: Full suite + analyzes, then commit**

```bash
git add lib/src/grammar/mark.dart lib/src/grammar/chart_builder.dart test/unit/grammar/mark_test.dart test/unit/grammar/chart_builder_test.dart
git commit -m "feat(grammar): add per-ring data-label overrides to DonutMark"
```

### Task 3.2: Lowering resolves per-ring labels (both paths)

**Files:**
- Modify: `lib/src/grammar/plot_lowering.dart` — `_lowerConcentricRings:1414` and the single-ring collapse path in `_lowerRadial`
- Test: `test/unit/grammar/plot_lowering_radial_test.dart`

**Interfaces:**
- Consumes: `DonutMark.dataLabelsByRing` (Task 3.1).
- Produces: resolution rule `mark.dataLabelsByRing?[key] ?? mark.dataLabels ?? const PieDataLabelConfig()` applied on **both** paths.

- [ ] **Step 1: Write the failing tests**

```dart
test('per-ring label overrides reach each ring; unlisted rings use the base',
    () {
  const outer = PieDataLabelConfig(showValues: true);
  final spec = PlotSpec<Ringed>(
    data: const [Ringed('outer', 'A', 3), Ringed('inner', 'B', 5)],
    marks: [
      DonutMark<Ringed>(
        category: ringedName, value: ringedValue, ring: ringedRing,
        dataLabels: const PieDataLabelConfig(),
        dataLabelsByRing: const {'outer': outer},
      ),
    ],
  );
  final rings = spec.lower().series.cast<DonutChartSeries>();
  expect(rings.firstWhere((r) => r.name == 'outer').dataLabels, outer);
  expect(rings.firstWhere((r) => r.name == 'inner').dataLabels,
      const PieDataLabelConfig());
});

test('a single-ring collapse still honours its override', () {
  // One distinct ring key only. This path bypasses the ring loop, so it is a
  // separate regression risk.
  const only = PieDataLabelConfig(showValues: true);
  final spec = PlotSpec<Ringed>(
    data: const [Ringed('solo', 'A', 3)],
    marks: [
      DonutMark<Ringed>(
        category: ringedName, value: ringedValue, ring: ringedRing,
        dataLabelsByRing: const {'solo': only},
      ),
    ],
  );
  expect((spec.lower().series.single as DonutChartSeries).dataLabels, only);
});
```

- [ ] **Step 2: Run — expect FAIL** (both return the base config).

- [ ] **Step 3: Implement on both paths**

In `_lowerConcentricRings`, replace `dataLabels: mark.dataLabels ?? const PieDataLabelConfig(),` with:

```dart
dataLabels: mark.dataLabelsByRing?[key] ??
    mark.dataLabels ??
    const PieDataLabelConfig(),
```

Then find the single-ring collapse in `_lowerRadial` (it calls `rings.single.copyWith(...)`) and make it resolve the same way for its lone ring key.

- [ ] **Step 4: Run — expect PASS.**

- [ ] **Step 5: Add the unknown-key diagnostic**

A `dataLabelsByRing` key naming no actual ring is an authoring error that would otherwise be silently inert. Add a `GrammarDiagnosticCode` + factory mirroring `invalidConcentricComposition`, raise it from `_lowerConcentricRings` after bucketing, and test it.

- [ ] **Step 6: Full suite + analyzes, then commit**

```bash
git add lib/src/grammar/plot_lowering.dart lib/src/grammar/grammar_diagnostics.dart test/unit/grammar/plot_lowering_radial_test.dart
git commit -m "feat(grammar): resolve per-ring data labels on both concentric paths"
```

### Task 3.3: Emitter projects per-ring overrides

**Files:**
- Modify: `lib/src/source/chart_grammar_source_generator.dart` — `_planConcentric:998` and the donut emit arm
- Modify: `lib/src/source/chart_config_dart_emitter.dart` — new `emitRadialLabelsByRing` seam
- Test: `test/unit/source/chart_grammar_source_generator_test.dart`

**Interfaces:**
- Produces: `ChartConfigDartEmitter.emitRadialLabelsByRing(DartSourceWriter writer, Map<String, PieDataLabelConfig> byRing)` — **unconditional** (writes every entry given), sorted by key for stable output.

- [ ] **Step 1: Write the failing test** — a concentric chart whose rings carry different `dataLabels` emits `dataLabelsByRing:` and round-trips; a uniform-label concentric chart emits **no** `dataLabelsByRing:` (byte-identical guard).

- [ ] **Step 2: Run — expect FAIL** (the divergent chart is refused; the emitter reverses from `donuts.first`).

- [ ] **Step 3: Project the overrides in `_planConcentric`**

Keep `dataLabels: donuts.first.dataLabels` as the base and build the override map from rings that differ:

```dart
final base = donuts.first.dataLabels;
final byRing = <String, PieDataLabelConfig>{
  for (final donut in donuts)
    if (donut.dataLabels != base) (donut.name ?? ''): donut.dataLabels,
};
```

Pass `dataLabelsByRing: byRing.isEmpty ? null : byRing` onto the `DonutMark`. An empty map must stay null so uniform charts emit nothing new.

- [ ] **Step 4: Add the seam and emit it**

The existing `_emitRadialLabels` early-returns on a default config, which would silently drop an override that equals the default. The new seam must be **unconditional**:

```dart
/// Emits `dataLabelsByRing: {...}` for the grammar form. Unlike the single
/// `dataLabels:` renderer this writes EVERY entry it is given, including one
/// that equals the family default — inside an override map, "equal to default"
/// is meaningful and dropping it would change the chart. Keys are sorted so the
/// emitted source is stable across runs.
void emitRadialLabelsByRing(
  DartSourceWriter writer,
  Map<String, PieDataLabelConfig> byRing,
) {
  if (byRing.isEmpty) return;
  final keys = byRing.keys.toList()..sort();
  writer.writeLine('dataLabelsByRing: {');
  writer.indented(() {
    for (final key in keys) {
      writer.writeLine('${DartSourceWriter.stringLiteral(key)}: '
          'PieDataLabelConfig(');
      writer.indented(() {
        // Reuse the SAME per-field renderer the `dataLabels:` form uses, but
        // unconditionally — do not route through the early-returning wrapper.
        _emitRadialLabelFields(writer, byRing[key]!);
      });
      writer.writeLine('),');
    }
  });
  writer.writeLine('},');
}
```

`_emitRadialLabelFields` is the per-field body of the existing `_emitRadialLabels`; extract it so both the conditional single-config renderer and this unconditional map renderer share one implementation and cannot disagree. Read `_emitRadialLabels` first and keep its field order and formatting exactly.

Emit it in the donut arm after `dataLabels:`.

- [ ] **Step 5: Run — expect PASS**, then run the whole emitter file and confirm uniform concentric output is unchanged.

- [ ] **Step 6: Convert the pinned blocker-3 test**

Find the pinned known-gap test for "rings with DIFFERENT dataLabels are refused" and convert it to an acceptance/round-trip test. Note the conversion in the commit body.

- [ ] **Step 7: Full suite + drift gates + analyzes, then commit**

```bash
git add lib/src/source/chart_grammar_source_generator.dart lib/src/source/chart_config_dart_emitter.dart test/unit/source/chart_grammar_source_generator_test.dart
git commit -m "feat(source): reverse per-ring data-label overrides"
```

---

# SLICE 4 — Ring identity

### Task 4.1: Conform the showcase ring ids (D1)

**Files:**
- Modify: `example/lib/showcase/pages/concentric_donut_page.dart` (ring ids **and** `ringWeights` keys)
- Modify: `example/lib/showcase/pages/selection_showcase_page.dart` (concentric family ids)
- Modify: `example/test/showcase/concentric_donut_page_test.dart` (~12 assertions)
- Modify: the 3 doc sites teaching the old shape (`doc/concentric_donut_charts.md`, `docs/guides/chart-types.md`, and the API card that mirrors them — `grep -rn "current'" doc/ docs/` to locate)

**Interfaces:** none produced; this aligns authored data with the existing contract.

- [ ] **Step 1: Read the current ids and their `ringWeights` keys together**

Run: `grep -n "id:\|ringWeights\|name:" example/lib/showcase/pages/concentric_donut_page.dart | head -40`

The contract keys off **name**, so the conforming id is `'<markId>-<name>'` — including spaces and capitals, e.g. `'revenue-Current period'`.

- [ ] **Step 2: Change ids and `ringWeights` keys ATOMICALLY**

They must move in one edit. Splitting them throws `ArgumentError` at `performLayout` because `ringWeights` is keyed by stable series id — probe-proven. Choose one `markId` prefix for the page's composition and apply it to every ring.

- [ ] **Step 3: Run the page's own tests — expect FAIL on the id assertions**

Run: `flutter test example/test/showcase/concentric_donut_page_test.dart`

- [ ] **Step 4: Update the ~12 id assertions to the new ids.** These pin authored data, so updating them tracks an intentional data change — **not** a weakening. Do not touch any assertion about behaviour.

- [ ] **Step 5: Do the same two-line change in `selection_showcase_page.dart`.** Its concentric family sets no `ringWeights`, so there is no atomic-rename risk there.

- [ ] **Step 6: Update the 3 doc sites** so they teach the conforming shape.

- [ ] **Step 7: Full suite (package + example) + both analyzes, then commit**

```bash
git add example/lib/showcase/pages/concentric_donut_page.dart example/lib/showcase/pages/selection_showcase_page.dart example/test/showcase/concentric_donut_page_test.dart doc/concentric_donut_charts.md docs/guides/chart-types.md
git commit -m "refactor(showcase): conform concentric ring ids to the grammar contract"
```

### Task 4.2: `DonutMark.ringIds` for arbitrary ids (D2)

**Files:**
- Modify: `lib/src/grammar/mark.dart`, `lib/src/grammar/chart_builder.dart`, `lib/src/grammar/plot_lowering.dart`, `lib/src/grammar/grammar_diagnostics.dart`
- Modify: `lib/src/source/chart_grammar_source_generator.dart` — `_concentricMarkId:1301`, `_planConcentric:998`
- Test: `test/unit/grammar/plot_lowering_radial_test.dart`, `test/unit/source/chart_grammar_source_generator_test.dart`

**Interfaces:**
- Produces: `final Map<String, String>? ringIds;` on `DonutMark`, keyed by the bare ring key; `ringIds:` on `geomDonut`. Lowering uses `mark.ringIds?[key] ?? '$markId-$key'`. The emitter consults it **only when `_concentricMarkId` returns null**.

- [ ] **Step 1: Write the failing lowering test**

```dart
test('ringIds supplies explicit per-ring series ids', () {
  final spec = PlotSpec<Ringed>(
    data: const [Ringed('outer', 'A', 3), Ringed('inner', 'B', 5)],
    marks: [
      DonutMark<Ringed>(
        id: 'revenue',
        category: ringedName, value: ringedValue, ring: ringedRing,
        ringIds: const {'outer': 'current', 'inner': 'previous'},
      ),
    ],
  );
  final ids = spec.lower().series.map((s) => s.id).toList();
  expect(ids, ['current', 'previous']);
});
```

- [ ] **Step 2: Run — expect FAIL** (ids are `revenue-outer` / `revenue-inner`).

- [ ] **Step 3: Add the field, the builder param, and the lowering rule**

In `_lowerConcentricRings`, replace `id: '$markId-$key',` with `id: mark.ringIds?[key] ?? '$markId-$key',`. Document on the field that `ConcentricDonutConfig.ringWeights` keys by the **resulting** series id — one rule, whichever scheme produced it.

- [ ] **Step 4: Run — expect PASS.**

- [ ] **Step 5: Add two diagnostics + tests**

A `ringIds` key naming no actual ring, and a **partial** map that leaves some rings unnamed (ambiguous — half conforming ids, half generated), each raise a named `GrammarSpecException`. Place them with the other shape-decidable checks **above** the `emptyData` guard, matching the module's ordering contract, and test that `data: []` still yields the shape diagnostic.

- [ ] **Step 6: Teach the emitter the fallback**

In `_planConcentric`, when `_concentricMarkId(donuts)` returns null, instead of blocking, synthesise a markId and build `ringIds` from the captured series ids, then let the round-trip proof verify. Existing conforming charts must take the original path unchanged, so **emission for them stays byte-identical**.

- [ ] **Step 7: Write the emitter round-trip test** — a concentric chart with arbitrary (non-conforming) ids emits `ringIds:` and round-trips.

- [ ] **Step 8: Full suite + drift gates + analyzes, then commit**

```bash
git add lib/src/grammar/mark.dart lib/src/grammar/chart_builder.dart lib/src/grammar/plot_lowering.dart lib/src/grammar/grammar_diagnostics.dart lib/src/source/chart_grammar_source_generator.dart test/unit/grammar/plot_lowering_radial_test.dart test/unit/source/chart_grammar_source_generator_test.dart
git commit -m "feat(grammar): carry explicit concentric ring ids"
```

### Task 4.3: Mounted-page acceptance for both concentric pages

**Files:**
- Modify: `test/unit/source/chart_grammar_source_generator_test.dart`

- [ ] **Step 1: Write the acceptance tests**

Mount the REAL `ConcentricDonutPage` and the REAL `selection_showcase_page.dart` concentric family, read each live document off its controller, generate, and assert each emits. Use the same mounting harness as the polar acceptance group and Task 2.1.

- [ ] **Step 2: Run — expect PASS** given Slices 1–3 and Tasks 4.1–4.2. If either refuses, diagnose the real gap and fix it; **do not weaken the assertion**.

- [ ] **Step 3: Add a drift guard for any hand-transcribed fixture** introduced here, matching the polar guard added in 1a′ (`grep -n "expectShowcaseKnobsMatchPage" test/unit/source/chart_grammar_source_generator_test.dart`).

- [ ] **Step 4: Full suite + drift gates + analyzes, then commit**

```bash
git add test/unit/source/chart_grammar_source_generator_test.dart
git commit -m "test(source): both concentric showcase pages emit, asserted on the mounted pages"
```

---

# SLICE 5 — Close the gap in prose

### Task 5.1: Retire the known-gap copy, update the gate, roadmap and register

**Files:**
- Modify: `doc/chart_grammar.md` (Known-gap section; the "Not in V1" per-point-colour bullet; the validation-order list if the new diagnostics belong in it)
- Modify: `lib/src/source/chart_grammar_source_generator.dart` (file-header fidelity matrix)
- Modify: `test/unit/source/chart_grammar_source_generator_test.dart` (the pinned test-group comment asserting three blockers)
- Modify: `docs/superpowers/specs/2026-07-26-fluent-grammar-roadmap-v2.md` (mark 1a″ delivered; update the coverage matrix rows for Pie/Donut/Concentric)
- Modify: `F:\Repositories\_braven_charts_register\items\BC-0032-*.md` (evidence, status, history)

- [ ] **Step 1: Correct the stale blocker count**

`doc/chart_grammar.md` and the pinned test-group comment both assert **three** blockers and that `DonutChartsPage` hits only blocker 2. There were **four** — the donut centre was unrecorded. Correct both, then delete the Known-gap section entirely now that the gaps are closed.

- [ ] **Step 2: Update the emitter file-header fidelity matrix** so its rows match the new reality (pie/donut per-slice colour and per-ring labels now reverse; the centre reverses with an honest formatter placeholder).

- [ ] **Step 3: Fold both pages into the acceptance gate wording** — the gate should now claim polar 8/8, pie, donut, and concentric, each verified against the mounted page.

- [ ] **Step 4: Update the roadmap** — mark 1a″ delivered with the real-page results, and correct the coverage-matrix rows.

- [ ] **Step 5: Update BC-0032** — set `status`, `updated`, evidence and a History entry. Then:

```powershell
& 'F:\Repositories\_braven_charts_register\register.ps1' validate
& 'F:\Repositories\_braven_charts_register\register.ps1' refresh
```

- [ ] **Step 6: Full suite + drift gates + both analyzes, then commit**

```bash
git add doc/chart_grammar.md lib/src/source/chart_grammar_source_generator.dart test/unit/source/chart_grammar_source_generator_test.dart docs/superpowers/specs/2026-07-26-fluent-grammar-roadmap-v2.md
git commit -m "docs: close the radial known-gap section and update the parity gate"
```

---

## Final verification (before requesting a PR)

- [ ] Full `flutter test` green (baseline at branch point: 4023 passed / 8 skipped / 0 failed — expect more, zero failures).
- [ ] `flutter test test/meta/` — all drift gates green, `missing=0`.
- [ ] `flutter analyze lib` and `flutter analyze example/lib` — "No issues found!".
- [ ] Cartesian, polar, pie, and uniform-label/default-centre radial emission byte-identical; no pre-existing test expectation removed or loosened (`git diff origin/master..HEAD -- test/` — every removal classified).
- [ ] **Mutation check:** stub `_firstRadialMismatch` to `return null` and confirm tests FAIL; revert and confirm the tree is clean.
- [ ] `chart_builder.dart` NUL sentinel intact (`NUL 1 CRLF 0 BOM False`).
- [ ] `ConcentricDonutPage`, `DonutChartsPage` and the selection showcase's concentric family all emit, asserted on the mounted pages.
- [ ] Rebase onto latest `origin/master`; re-run the suite.
- [ ] BC-0032 updated with evidence before any status change to `Review Needed`.
