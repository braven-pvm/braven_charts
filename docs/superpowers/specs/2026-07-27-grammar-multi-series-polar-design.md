# Grammar Multi-Series Polar + Radial Config Passthrough — Design

**Date:** 2026-07-27
**Status:** Approved (brainstorming). Next: implementation plan.
**Programme:** Fluent/Grammar-of-Graphics **Roadmap v2.0, Theme 1 — Universal Coverage, item 1a′** (the polar follow-up to 1a / PR #124).
**Worktree/branch:** `F:\Repositories\braven_charts-radial-polar`, `feature/grammar-radial-polar` (off `origin/master` `a811dcef`).

## Goal

Make the workbench **Grammar Source** pane emit a faithful `BravenChart.of(rows)….build()` chain for **every** Polar Column chart — including the multi-series compositions (layered / grouped / stacked) with per-series-distinct styling, the advanced per-series presentations (references / intervals / rose), and any customised plot-level `PolarChartConfig` — and for **non-default `ConcentricDonutConfig`** donut charts.

> **Delivered scope, corrected 2026-07-27 after verification against the real pages.** The polar half of that goal is met in full: all eight `PolarColumnPage` presentations emit, verified against the page's own construction. The concentric half is met as a **config passthrough** — a non-default `ConcentricDonutConfig` emits when the composition is authored the way the grammar's own lowering produces one — but **not** as a showcase claim: `ConcentricDonutPage` and `DonutChartsPage` still do **not** emit. See *Known gap* below. The original sentence "closes the last 'not emitted' radial panes" was wrong and has been removed.

Item 1a (PR #124) taught the emitter to recognise radial families and carry per-series *style* + a handful of config objects, but it deliberately deferred polar because of two **structural** blockers. This slice removes both.

## The two structural blockers (grounded)

1. **One radial geom per spec.** `_lowerRadial` takes `radialIndices.single` and throws `multipleRadialGeoms` for any `> 1` radial mark (`plot_lowering.dart:909-918`). The emitter mirrors this: `_planRadial` refuses with *"geomPolar lowers to a single … N polar series cannot be reversed to one geomPolar"* (`chart_grammar_source_generator.dart:694-701`). So a layered/grouped/stacked polar chart (2–3 `PolarColumnChartSeries`) cannot be expressed or reversed.
2. **Chart-level config discarded by lowering.** `_lowerPolar` sets `polar = const PolarChartConfig()` unconditionally (`plot_lowering.dart:989`), so even a *single-series* polar with a customised `PolarChartConfig` cannot round-trip; the emitter honestly refuses it (`chart_grammar_source_generator.dart:1057`). The same shape applies to concentric donut: only `centerContent` survives lowering (`plot_lowering.dart:968-985`), so a non-default `ConcentricDonutConfig` (`ringGap`/`order`/`ringWeights`/`legendMode`/radii) is refused by the proof (`:1043`).

## Owner decisions (settled at brainstorm)

- **Representation:** *multiple `geomPolar` marks per spec* (relax the one-radial-geom rule for the **polar family only** — pie/donut stay single; donut-multi is already concentric via the `ring` channel). Each series is its own mark with independent style/color/data; the plot-level `PolarChartConfig` lives on the spec. This is the only representation that expresses per-series-distinct styles (e.g. layered's "Capacity" at reduced opacity with labels off) and reverses cleanly from the config's `List<PolarColumnChartSeries>`.
- **Coverage:** *full 8/8 polar coverage now* — carry all six advanced per-series fields so **standard / rose / partial / layered / grouped / stacked / references / intervals** all emit, plus non-default `ConcentricDonutConfig`.

## Known gap (verified 2026-07-27) — the two donut showcase pages do not emit

Established by mounting the real pages and running the generator on the live chart documents, then isolating each cause with mutate-one-thing-at-a-time probes:

| Page | Emits? | Complete? | Why |
|---|---|---|---|
| `PolarColumnPage`, all 8 presentations | **yes** | yes | the delivered scope above |
| `PieChartsPage` | yes | **no** | honest known-limitation warning only: radial label formatter callbacks have no literal |
| `ConcentricDonutPage` | **no** | no | blockers 1 + 2 + 3 below, each independent |
| `DonutChartsPage` | **no** | no | blocker 2 (it is a single-ring donut, so 1 and 3 do not arise) |

The three blockers:

1. **Ring ids.** The page names its ring series from its own `_ringDescriptors` (`current`, `previous`, …), not the `'<markId>-<ring>'` contract the `ring:` channel reproduces.
2. **Per-slice colours.** Both pages pass `sliceColors` (`donut_charts_page.dart:487`); `DonutMark`/`PieMark` have **no** per-point colour channel — only `PolarMark` does, via `columnColor`.
3. **Per-ring data labels.** The concentric page's `hierarchy` label layout gives each ring a **different** `PieDataLabelConfig`, and one `DonutMark` carries **one** `dataLabels` for every ring it splits into.

Fixing any one leaves the page blocked on the others. Blocker 2 is the substantive one and is **owner-scoped, out of this slice**: it means adding a per-point colour channel to `PieMark`/`DonutMark`, a grammar-surface addition, not an emitter repair. Each blocker is mounted and its refusal pinned in `group('KNOWN GAP: the donut showcase pages do not emit')` in `test/unit/source/chart_grammar_source_generator_test.dart`, so closing one turns that group red and points back here.

## Grounded target inventory (what must emit)

`example/lib/showcase/pages/polar_column_page.dart` builds these presentations (`_buildSeriesList` `:695`, `_buildPolarConfig` `:616`):

| Presentation | Series | Distinguishing per-series fields | Plot config |
|---|---|---|---|
| standard | 1 | `columnColors` | `PolarChartConfig` (pane/axes) |
| rose | 1 | `columnColors`, `.rose` constructor (`preset: rose`) | area-correct radial axis |
| partial | 1 | `columnColors` | non-default **pane**: `startAngleDegrees: 150`, `sweepAngleDegrees: 240`, `innerRadiusFactor: 0.28` |
| layered | 2 | per-series `polarStyle` (opacity 0.32, labels off) | `composition: layered` |
| grouped | 3 | per-series color | `composition: grouped`, `groupInnerPadding` |
| stacked | 3 | per-series color | `composition: stacked` |
| references | 1 | `targets`, `targetMarkerStyle`, `columnColors` | `thresholds` |
| intervals | 1 | `intervals`, `intervalStyle`, `columnColors` | — |

`PolarColumnChartSeries` surface to reverse (`lib/src/models/polar_column_chart_series.dart:672-827`): `preset` (standard/rose), `polarStyle`, `selectionStyle`, `color`, `unit`, per-point `columnColors` (`fromMap` `:696` → `PointStyle.color` `:801`), `targets`→`targetValues` (`:815`) + `targetMarkerStyle`, `intervals`→`intervalLowerValues`/`intervalUpperValues` (`:819-824`) + `intervalStyle`.

## Architecture — mirror the 1a config-carry, adding the multi-mark + spec-config axes

### 1. Grammar surface

**`PolarMark<T>`** (`lib/src/grammar/mark.dart:1039`) gains per-series channels + config objects. Marks hold **functions and config objects only** — no `copyWith`, no `@chartSurface`, **no drift-gate surface** (the config classes are already `@chartSurface`-gated). New fields:

- `columnColor: FieldAccessor<T, Color?>?` — per-category column color; reverses `columnColors`/per-point `PointStyle.color`. Null → no per-column colors.
- `target: FieldAccessor<T, num?>?` — per-category absolute target; reverses `targetValues`. Null → no targets.
- `targetMarkerStyle: PolarColumnTargetMarkerStyle?` — null → default.
- `intervalLow: FieldAccessor<T, num?>?` + `intervalHigh: FieldAccessor<T, num?>?` — per-category interval endpoints; reverse `intervalLowerValues`/`intervalUpperValues`. Both null → no intervals. (An author supplying one but not the other → `incompletePolarInterval` diagnostic.)
- `intervalStyle: PolarColumnIntervalStyle?` — null → default.
- `preset: PolarColumnPreset` (standard/rose), surfaced through the builder as `rose: bool`.

`==`/`hashCode`/`toString` on `PolarMark` extended to include the new fields.

**`DonutMark<T>`** (`lib/src/grammar/mark.dart:949`) gains `concentric: ConcentricDonutConfig?`. Precedence rule (single source of truth for the center): when `concentric != null` it supplies `ringGap`/`order`/`ringWeights`/`legendMode`/radii, and its `centerContent` is authoritative; the existing `center` field is the shorthand used **only** when `concentric == null`. Setting **both** `concentric` and `center` → `conflictingConcentricCenter` diagnostic. `==`/`hashCode` extended.

**`PlotSpec<T>`** (`lib/src/grammar/plot_spec.dart:39`) gains `polar: PolarChartConfig?` — the plot-level polar config shared across the N polar marks (this is where `composition`/`pane`/`angularAxis`/`radialAxis`/`thresholds` live; one config, N marks). Null lowers to `const PolarChartConfig()`. Threaded through the constructor (`:41-54`), `facetCleared()` (`:121-133`), `==` (`:141-156`), and `hashCode` (`:158-172`). (Concentric config rides the single `DonutMark`, not the spec, because concentric is a one-mark construct; polar composition genuinely spans marks, so it is spec-level.)

**`chart_builder.dart`** (UTF-8 + the deliberate single NUL sentinel in `_defaultYKey` — must be preserved: 1 NUL, 0 CRLF, no BOM):
- `geomPolar(...)` (`:508`) gains `rose`, `columnColor`, `target`, `targetMarkerStyle`, `intervalLow`, `intervalHigh`, `intervalStyle`.
- `geomDonut(...)` (`:471`) gains `concentric`.
- New spec-level verb `polarConfig(PolarChartConfig config) => _copy(polar: config)`, matching `xAxis` (`:649`) / `grid` (`:695`).

**Core barrel** re-exports remain unchanged (the new fields ride existing exported types; `PolarColumnPreset`, `PolarColumnTargetMarkerStyle`, `PolarColumnIntervalStyle`, `ConcentricDonutConfig`, `PolarChartConfig` are already exported by the config models).

### 2. Lowering (`plot_lowering.dart`, `_lowerRadial` `:909`)

- Collect radial mark indices as today.
- **All radial marks are `PolarMark`** (count ≥ 1) → build one `PolarColumnChartSeries` per mark via an extended `_lowerPolar` (`:1127`) reading the new channels + preset + building `columnColors`/`targets`/`intervals` maps from the accessors over `spec.data`; set `polar = spec.polar ?? const PolarChartConfig()`.
- **Exactly one radial mark, pie/donut** → existing path; concentric uses `mark.concentric ?? (built from center as today)` (`:963-986`).
- **> 1 radial mark, not all polar** (two pies, pie+donut, pie+polar) → `multipleRadialGeoms` (repurposed: multiple radial marks are legal *only* when every one is a `PolarMark`).
- **`mixedCoordinateSystems`** (radial + Cartesian mark in one spec) unchanged (`:920-928`).
- `spec.polar != null` with no polar mark → new `polarConfigOnNonPolarSpec` diagnostic (mirrors `axisOptionOnRadialSpec` `:933-945`).
- The `LoweredPlot` returns `polarChartConfig: polar` and `concentricDonutConfig: concentric` as before (`:994-1007`).

### 3. Emitter — reversal + round-trip proof (`chart_grammar_source_generator.dart`)

- **`_planRadial` (`:675`):** delete the multi-polar refusal (`:694-701`); when the config carries N `PolarColumnChartSeries`, plan N `geomPolar` marks. Extend `_planPolar` (`:890`) to reverse each series' new fields: `columnColors`→`columnColor` field, `targetValues`→`target` field, `intervalLowerValues`/`intervalUpperValues`→`intervalLow`/`intervalHigh` fields, `preset`→`rose`, plus `targetMarkerStyle`/`intervalStyle`/`polarStyle`/`selectionStyle`/`color`/`unit`. Plan the spec-level `.polarConfig(...)` from `configuration.polarChartConfig`, and `concentric:` on `geomDonut` from `configuration.concentricDonutConfig`.
- **`_firstRadialMismatch` (`:1004`):** compare the **full** `PolarChartConfig` and **full** `ConcentricDonutConfig` (replacing the "default-only" checks at `:1043` and `:1057`), plus the new per-series fields. The **per-series** half is a real proof: any field the grammar fails to carry makes the re-lowered series diverge and the chart honestly refuses (never silently degrades). The two **config** comparisons are weaker by construction — the proof spec carries the captured config instance verbatim, so lowering hands it straight back — and are regression tripwires on lowering, not proofs about the emitted literal (see *Invariants* below).
- **`_emitRadialGeometry` (`:1967`):** emit N `geomPolar` + the spec-level `.polarConfig(...)` + the new params. Reuse the config emitter's literal renderers through minimal **public seams** (as 1a did with `emitRadialStyle`/etc. in `chart_config_dart_emitter.dart`), adding drift-gate-safe seams for `PolarChartConfig`, `PolarColumnTargetMarkerStyle`, `PolarColumnIntervalStyle`, and `ConcentricDonutConfig`.
- **Honest-refusal residue:** live callbacks with no literal (none currently on these types) keep the 1a `// …:` placeholder + `isComplete == false` contract. Update the file-header matrix (`:34-36`) and retire the "customised config refuses / N polar cannot be reversed" copy.

### 4. Diagnostics (`grammar_diagnostics.dart`)

- Repurpose **`multipleRadialGeoms`** — now fires only for multiple **non-polar** radial marks or mixed radial families.
- Add **`polarConfigOnNonPolarSpec`** — `.polarConfig()` set without a polar mark.
- Add **`conflictingConcentricCenter`** — `DonutMark` with both `concentric` and `center`.
- Add **`incompletePolarInterval`** — exactly one of `intervalLow`/`intervalHigh` supplied.

Every new diagnostic gets a named code, message, and a test asserting it fires.

### 5. Invariants (carried from v1 + 1a)

- **Emitted == faithful, with a stated boundary.** The proof re-lowers the reconstructed PLAN and refuses any re-lowered **series** that does not compare equal field-for-field. It does **not** prove the emitted **config literals**: `PlotSpec.polar` and `DonutMark.concentric` ride the proof spec verbatim, so lowering hands the *same instance* back (`polar = spec.polar ?? const PolarChartConfig()`) and `_firstRadialMismatch` then compares that instance to itself. That comparison is a **lowering tripwire** — it fires if lowering ever stops carrying the config, which is exactly what it did before this slice — not a check on the `.polarConfig(...)` / `geomDonut(concentric: ...)` text. The literals are covered instead by: (a) the config emitter's **shared renderer** seams, so the config and grammar forms cannot disagree; (b) `test/meta/source_emitter_drift_test.dart`, which fails on any unrendered field; and (c) **explicit per-field assertions on the emitted text** in the emitter tests. Deleting the `.polarConfig(...)` emission produces zero generator refusals — only those emitted-text assertions fail.
- **No new drift-gate surface:** marks hold functions/config-objects; the four config classes are already `@chartSurface`. New emitter seams keep `source_emitter_drift` green (per-series + class-aware, 0 gaps).
- **Cartesian + existing radial emission byte-identical:** pie/donut/concentric/**single**-polar chains and every existing golden are unchanged; the multi-polar/spec-config paths are additive.
- **`PlotSpec` equality parity:** `polar` added to `==`/`hashCode`/`facetCleared`.
- **`chart_builder.dart` NUL-sentinel integrity** preserved (1 NUL, 0 CRLF, no BOM).
- **Beta** framing unchanged.

## Decomposition (vertical slices — each ends green; full suite + `analyze lib` + drift gates)

- **Slice A — Multi-geom polar structural.** N `PolarMark` in one spec; `_lowerRadial` polar loop; spec-level `PolarChartConfig` passthrough + `.polarConfig` verb; `multipleRadialGeoms` repurpose + `polarConfigOnNonPolarSpec`; emitter reverses N `geomPolar` + `.polarConfig`. **Acceptance:** layered / grouped / stacked + custom-config polar emit + round-trip.
- **Slice B — Per-series advanced fields.** `columnColor`, `target`/`targetMarkerStyle`, `intervalLow`/`intervalHigh`/`intervalStyle`, `rose` preset; `incompletePolarInterval`. **Acceptance:** standard (columnColors) / references / intervals / rose emit → **all 8 presentations** (`partial` is `standard`'s channel set over a non-default pane, so Slice A's spec-level `PolarChartConfig` passthrough is what carries it).
- **Slice C — Non-default `ConcentricDonutConfig` passthrough.** `DonutMark.concentric` + precedence + `conflictingConcentricCenter`; emitter reverses `concentric:`; proof compares the full config. **Acceptance:** a non-default concentric donut emits + round-trips.
- **Slice D — Showcase + docs verification.** Confirm every **polar** workbench Grammar pane emits a real chain (all eight presentations, against the page's own construction) plus a non-default `ConcentricDonutConfig` authored through the grammar; record the donut-page *Known gap* above rather than implying it away; update the emitter file-header matrix and any `doc/chart_grammar.md` radial copy.

## Testing

- **Round-trip ("emitted == faithful"):** each of the 8 polar presentations + a non-default concentric donut, re-lowered through the extended `_firstRadialMismatch`, reproduces the captured **series list** exactly. Fixtures use non-default values so a no-op pass cannot masquerade as success. Because the config comparisons are passthrough tripwires rather than proofs (see *Invariants*), every emitted `PolarChartConfig` / `ConcentricDonutConfig` field additionally gets an **assertion on the emitted text**; those, plus the drift gate, are what actually pin the literals.
- **Diagnostics:** multiple non-polar radial → `multipleRadialGeoms`; `.polarConfig()` without polar mark → `polarConfigOnNonPolarSpec`; `concentric`+`center` → `conflictingConcentricCenter`; one interval bound → `incompletePolarInterval`.
- **No regression:** Cartesian + existing pie/donut/concentric/single-polar emission byte-identical; existing goldens unchanged; all four drift gates green; `PlotSpec` equality unaffected for non-radial specs.
- **Showcase:** every **polar** Grammar pane renders a faithful chain — all eight presentations mounted from `polar_column_page.dart`'s own construction — plus a non-default `ConcentricDonutConfig` authored through the grammar. The donut pages are covered by *refusal* tests instead, one per blocker in the *Known gap* above, so the gap stays visible and closing it goes red rather than unnoticed.
- **Sync guard:** the acceptance fixtures are a hand transcription of the showcase page, so `group('showcase transcription sync guard')` parses `polar_column_page.dart` and asserts the `_PolarPresentation` value list (length, names, order) against the acceptance cases, every `<String, num>` value map (contents **and** key order — the palette cycles over it), and every transcribed `_PolarPalette` swatch. Without it the gate keeps passing about a page that has moved on.

## Files

- **Modify** `lib/src/grammar/mark.dart` — `PolarMark` (+6 fields), `DonutMark` (+`concentric`).
- **Modify** `lib/src/grammar/plot_spec.dart` — `PlotSpec.polar` (constructor/`facetCleared`/`==`/`hashCode`).
- **Modify** `lib/src/grammar/chart_builder.dart` — `geomPolar`/`geomDonut` params + `.polarConfig` verb (preserve NUL sentinel).
- **Modify** `lib/src/grammar/plot_lowering.dart` — `_lowerRadial` polar loop + spec-config; `_lowerPolar` new channels/preset; concentric precedence.
- **Modify** `lib/src/grammar/grammar_diagnostics.dart` — repurpose `multipleRadialGeoms`; add 3 codes.
- **Modify** `lib/src/source/chart_grammar_source_generator.dart` — `_planRadial`/`_planPolar`, `_firstRadialMismatch`, `_emitRadialGeometry`, file-header matrix.
- **Modify** `lib/src/source/chart_config_dart_emitter.dart` — new public seams for the config literals.
- **Tests** under `test/unit/grammar/` (lowering + diagnostics) and `test/unit/source/` (emitter round-trip) + any workbench golden capturing a radial "not emitted" pane.

## Out of scope (future)

- **A per-point colour channel on `PieMark` / `DonutMark`** — blocker 2 of the *Known gap* above, and the single change that would unblock `DonutChartsPage`. Owner-scoped grammar-surface work.
- Radial faceting (`facetedRadialUnsupported` stays a guard).
- New radial mark families (radial-bar / gauge) — roadmap 1b.
- Cartesian advanced-field completeness (bar/scatter) — roadmap 1d.
