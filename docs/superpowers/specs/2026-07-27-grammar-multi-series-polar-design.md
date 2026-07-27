# Grammar Multi-Series Polar + Radial Config Passthrough — Design

**Date:** 2026-07-27
**Status:** Approved (brainstorming). Next: implementation plan.
**Programme:** Fluent/Grammar-of-Graphics **Roadmap v2.0, Theme 1 — Universal Coverage, item 1a′** (the polar follow-up to 1a / PR #124).
**Worktree/branch:** `F:\Repositories\braven_charts-radial-polar`, `feature/grammar-radial-polar` (off `origin/master` `a811dcef`).

## Goal

Make the workbench **Grammar Source** pane emit a faithful `BravenChart.of(rows)….build()` chain for **every** Polar Column chart — including the multi-series compositions (layered / grouped / stacked) with per-series-distinct styling, the advanced per-series presentations (references / intervals / rose), and any customised plot-level `PolarChartConfig` — and for **non-default `ConcentricDonutConfig`** donut charts. This closes the last "not emitted" radial panes left after item 1a.

Item 1a (PR #124) taught the emitter to recognise radial families and carry per-series *style* + a handful of config objects, but it deliberately deferred polar because of two **structural** blockers. This slice removes both.

## The two structural blockers (grounded)

1. **One radial geom per spec.** `_lowerRadial` takes `radialIndices.single` and throws `multipleRadialGeoms` for any `> 1` radial mark (`plot_lowering.dart:909-918`). The emitter mirrors this: `_planRadial` refuses with *"geomPolar lowers to a single … N polar series cannot be reversed to one geomPolar"* (`chart_grammar_source_generator.dart:694-701`). So a layered/grouped/stacked polar chart (2–3 `PolarColumnChartSeries`) cannot be expressed or reversed.
2. **Chart-level config discarded by lowering.** `_lowerPolar` sets `polar = const PolarChartConfig()` unconditionally (`plot_lowering.dart:989`), so even a *single-series* polar with a customised `PolarChartConfig` cannot round-trip; the emitter honestly refuses it (`chart_grammar_source_generator.dart:1057`). The same shape applies to concentric donut: only `centerContent` survives lowering (`plot_lowering.dart:968-985`), so a non-default `ConcentricDonutConfig` (`ringGap`/`order`/`ringWeights`/`legendMode`/radii) is refused by the proof (`:1043`).

## Owner decisions (settled at brainstorm)

- **Representation:** *multiple `geomPolar` marks per spec* (relax the one-radial-geom rule for the **polar family only** — pie/donut stay single; donut-multi is already concentric via the `ring` channel). Each series is its own mark with independent style/color/data; the plot-level `PolarChartConfig` lives on the spec. This is the only representation that expresses per-series-distinct styles (e.g. layered's "Capacity" at reduced opacity with labels off) and reverses cleanly from the config's `List<PolarColumnChartSeries>`.
- **Coverage:** *full 7/7 polar coverage now* — carry all six advanced per-series fields so **standard / rose / layered / grouped / stacked / references / intervals** all emit, plus non-default `ConcentricDonutConfig`.

## Grounded target inventory (what must emit)

`example/lib/showcase/pages/polar_column_page.dart` builds these presentations (`_buildSeriesList` `:695`, `_buildPolarConfig` `:616`):

| Presentation | Series | Distinguishing per-series fields | Plot config |
|---|---|---|---|
| standard | 1 | `columnColors` | `PolarChartConfig` (pane/axes) |
| rose | 1 | `columnColors`, `.rose` constructor (`preset: rose`) | area-correct radial axis |
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
- **`_firstRadialMismatch` (`:1004`):** compare the **full** `PolarChartConfig` and **full** `ConcentricDonutConfig` (replacing the "default-only" checks at `:1043` and `:1057`), plus the new per-series fields. This proof is the "emitted == faithful" guarantee: any field the grammar fails to carry makes the re-lowered config diverge and the chart honestly refuses (never silently degrades).
- **`_emitRadialGeometry` (`:1967`):** emit N `geomPolar` + the spec-level `.polarConfig(...)` + the new params. Reuse the config emitter's literal renderers through minimal **public seams** (as 1a did with `emitRadialStyle`/etc. in `chart_config_dart_emitter.dart`), adding drift-gate-safe seams for `PolarChartConfig`, `PolarColumnTargetMarkerStyle`, `PolarColumnIntervalStyle`, and `ConcentricDonutConfig`.
- **Honest-refusal residue:** live callbacks with no literal (none currently on these types) keep the 1a `// …:` placeholder + `isComplete == false` contract. Update the file-header matrix (`:34-36`) and retire the "customised config refuses / N polar cannot be reversed" copy.

### 4. Diagnostics (`grammar_diagnostics.dart`)

- Repurpose **`multipleRadialGeoms`** — now fires only for multiple **non-polar** radial marks or mixed radial families.
- Add **`polarConfigOnNonPolarSpec`** — `.polarConfig()` set without a polar mark.
- Add **`conflictingConcentricCenter`** — `DonutMark` with both `concentric` and `center`.
- Add **`incompletePolarInterval`** — exactly one of `intervalLow`/`intervalHigh` supplied.

Every new diagnostic gets a named code, message, and a test asserting it fires.

### 5. Invariants (carried from v1 + 1a)

- **Emitted == faithful:** the extended proof re-lowers the emitted chain and refuses anything not reproduced field-for-field.
- **No new drift-gate surface:** marks hold functions/config-objects; the four config classes are already `@chartSurface`. New emitter seams keep `source_emitter_drift` green (per-series + class-aware, 0 gaps).
- **Cartesian + existing radial emission byte-identical:** pie/donut/concentric/**single**-polar chains and every existing golden are unchanged; the multi-polar/spec-config paths are additive.
- **`PlotSpec` equality parity:** `polar` added to `==`/`hashCode`/`facetCleared`.
- **`chart_builder.dart` NUL-sentinel integrity** preserved (1 NUL, 0 CRLF, no BOM).
- **Beta** framing unchanged.

## Decomposition (vertical slices — each ends green; full suite + `analyze lib` + drift gates)

- **Slice A — Multi-geom polar structural.** N `PolarMark` in one spec; `_lowerRadial` polar loop; spec-level `PolarChartConfig` passthrough + `.polarConfig` verb; `multipleRadialGeoms` repurpose + `polarConfigOnNonPolarSpec`; emitter reverses N `geomPolar` + `.polarConfig`. **Acceptance:** layered / grouped / stacked + custom-config polar emit + round-trip.
- **Slice B — Per-series advanced fields.** `columnColor`, `target`/`targetMarkerStyle`, `intervalLow`/`intervalHigh`/`intervalStyle`, `rose` preset; `incompletePolarInterval`. **Acceptance:** standard (columnColors) / references / intervals / rose emit → **all 7 presentations**.
- **Slice C — Non-default `ConcentricDonutConfig` passthrough.** `DonutMark.concentric` + precedence + `conflictingConcentricCenter`; emitter reverses `concentric:`; proof compares the full config. **Acceptance:** a non-default concentric donut emits + round-trips.
- **Slice D — Showcase + docs verification.** Confirm every polar + concentric workbench Grammar pane emits a real chain; update the emitter file-header matrix and any `doc/chart_grammar.md` radial copy.

## Testing

- **Round-trip ("emitted == faithful"):** each of the 7 polar presentations + a non-default concentric donut, re-lowered through the extended `_firstRadialMismatch`, reproduces the captured config (series list + `PolarChartConfig` + `ConcentricDonutConfig`) exactly. Fixtures use non-default values so a no-op pass cannot masquerade as success.
- **Diagnostics:** multiple non-polar radial → `multipleRadialGeoms`; `.polarConfig()` without polar mark → `polarConfigOnNonPolarSpec`; `concentric`+`center` → `conflictingConcentricCenter`; one interval bound → `incompletePolarInterval`.
- **No regression:** Cartesian + existing pie/donut/concentric/single-polar emission byte-identical; existing goldens unchanged; all four drift gates green; `PlotSpec` equality unaffected for non-radial specs.
- **Showcase:** every polar + concentric Grammar pane renders a faithful chain (workbench tests + manual).

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

- Radial faceting (`facetedRadialUnsupported` stays a guard).
- New radial mark families (radial-bar / gauge) — roadmap 1b.
- Cartesian advanced-field completeness (bar/scatter) — roadmap 1d.
