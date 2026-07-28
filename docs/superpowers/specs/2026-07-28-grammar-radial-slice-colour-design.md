# Radial Slice Colour, Per-Ring Labels and Donut Centre Parity — Design

**Date:** 2026-07-28
**Status:** Approved (brainstorming). Next: implementation plan.
**Programme:** Fluent/Grammar-of-Graphics **Roadmap v2.0, Theme 1 — Universal Coverage, item 1a″** (the last radial gap; sequenced before 1b).
**Register:** BC-0032 (lane `chart-grammar`).
**Worktree/branch:** `F:\Repositories\braven_charts-slice-colour`, `feature/grammar-radial-slice-colour` (off `origin/master` `da5dae1d`).

## Goal

Every radial Workbench Grammar pane emits a faithful, round-tripping `BravenChart.of(rows)….build()` chain. The remaining offenders are **`ConcentricDonutPage`**, **`DonutChartsPage`**, and the concentric family on **`selection_showcase_page.dart`**, all of which still print *"the grammar chain was not emitted for this chart"*.

## The blockers (four, not three)

The roadmap recorded three. Design reconnaissance on 2026-07-28 — three parallel probes that **mounted the real pages**, read the live document off the workbench and ran the generator — found a fourth. Two of the three probes repeated the repo's own three-blocker claim without probing; only the one that mounted the page found it. This is the same fixtures-vs-real-page failure that produced a false acceptance claim in 1a′.

1. **No per-slice colour channel** on `PieMark`/`DonutMark`. Both pages pass `sliceColors`, which `PieChartSeries.fromMap`/`DonutChartSeries.fromMap` turn into a per-point `PointStyle(color:)`. `ChartSeries ==` compares points deeply, so `_firstRadialMismatch` refuses. Only `PolarMark` gained a colour channel (`columnColor`) in 1a′.
2. **One `dataLabels` for every ring.** `ConcentricDonutPage`'s `hierarchy` layout gives the outer ring `outside/categoryAndPercentage` and inner rings `inside/category`, but `DonutMark` carries a single config that `_lowerConcentricRings` stamps onto every ring and the emitter reverses from `donuts.first`.
3. **Ring ids must follow `'<markId>-<name>'`.** This is a hard requirement of the forward lowering (`_lowerConcentricRings` ids each ring `'$markId-$key'`), and `_concentricMarkId` is its exact inverse — not a heuristic. No page in the repo conforms.
4. **The donut centre — previously unrecorded.** `_markCenter` rebuilds a centre from `isVisible`/`label`/`valueMode`/`customValue` only, dropping `labelStyle`, `valueStyle` and `valueFormatter`. `DonutCenterContent ==` compares all three and `DonutChartSeries ==` compares `centerContent`, so the proof hard-refuses. `DonutChartsPage` sets a `valueFormatter` unconditionally, in every knob state — so it is refused **independently of `sliceColors`**. The emitter's own comment states the drop is deliberate.

`doc/chart_grammar.md` and a pinned test group both assert three blockers and that `DonutChartsPage` hits only blocker 2. Both are stale and are corrected by this slice.

## Owner decisions (settled at brainstorm)

- **Ring identity: do both.** Rename the showcase ring ids to conform **and** add a `ringIds` map so arbitrary-id charts reverse. Rationale: four independent authors in this repo chose slug ids decoupled from names and two docs teach that shape — a contract with 0/4 unprompted conformance traps real users, not just our demo pages. Renaming fixes the showcase; only the map fixes the trap.
- **Acceptance bar: an honest placeholder counts.** `DonutChartsPage` emitting a real chain with `// valueFormatter:` and `isComplete == false` satisfies "the pane emits" — the established contract for live callbacks and the state `PieChartsPage` ships in today.
- **Per-ring label carry shape: a map** (not an accessor, positional list, or a field on `ConcentricDonutConfig`). Decided on evidence, not preference — see below.

## Architecture

### A. Per-slice colour channel

`sliceColor: FieldAccessor<T, Color?>?` on **`PieMark`** and **`DonutMark`**, mirroring `PolarMark.columnColor`: a builder param on `geomPie`/`geomDonut`, a `_sliceColors<T>()` lowering helper beside `_radiusValues` that **skips null returns** (null leaves that category on the series colour — an unset accessor and an all-null accessor behave identically), and emitter reversal from `point.pointStyle?.color`.

**Colour and radius compose.** Pie/donut `fromMap` builds the *general* `PointStyle(color: sliceColor, size: radiusValue)`, whereas polar uses the narrowing `PointStyle.color(...)`. Probe-verified: a donut with both `radiusValues` and `sliceColors` re-lowers equal to the capture. The existing radius reversal reads only `.size` and is untouched.

**Residue stays refused.** `PointStyle` carries four fields; the two the grammar cannot express — `scatterMarkerShape`, `scatterMarkerStyle` — plus a bare `const PointStyle()` (which the document codec round-trips as non-null while the grammar reversal yields `null`) remain honest, named refusals, each pinned by a test.

**A new honest-but-surprising refusal:** a chart mixing colour-only and size-only points. The radius field is allocated when *any* point has a size, and sizeless rows synthesise `0`, so `fromMap` produces `size: 0.0` where the capture had `null`. Correct behaviour; pinned so it is not later misread as a regression.

### B. Per-ring data labels

`dataLabelsByRing: Map<String, PieDataLabelConfig>?` on `DonutMark`, keyed by the **bare ring key** (`= DonutChartSeries.name`), with `dataLabels` as the base. Lowering resolves `mark.dataLabelsByRing?[key] ?? mark.dataLabels ?? const PieDataLabelConfig()` — **including the single-ring collapse path**, which bypasses the ring loop and would otherwise ignore the override.

The emitter projects only rings whose labels **differ from the base**, so uniform charts emit no new argument and stay byte-identical. This needs a new **unconditional** `emitRadialLabelsByRing` seam: the existing renderer early-returns on a default config, which would silently drop an override that happens to equal the default.

`DonutMark.==`/`hashCode` use `mapEquals`/`Object.hashAllUnordered`.

**Why a map:** an accessor would emit a `switch` behind no shared seam, no drift gate and no emitted-text assertion — the exact hole the emitter header documents — and function fields break the `DonutMark ==` convention. A positional list is data-order dependent (`_lowerConcentricRings` builds ring order from first-seen rows) and ambiguous against `ConcentricDonutConfig.order`. Putting it on `ConcentricDonutConfig` adds `@chartSurface`/`copyWith` drift-gate surface and creates a second authority against the series `dataLabels` the renderer actually reads.

### C. Donut centre parity

Stop reconstructing the centre. **Carry the captured `DonutCenterContent` verbatim** onto `DonutMark.center` — exactly how `dataLabels` is already carried — and replace `_emitDonutCenter` with the shared full-fidelity renderer the **concentric** path already uses (`_emitConcentricCenterContent`), parameterised on the argument name (`center:` vs `centerContent:`). That renderer emits `labelStyle` and `valueStyle` and degrades a `valueFormatter` to a `// valueFormatter:` placeholder plus a `runtimeValueOmitted` warning.

Result: `DonutChartsPage` emits with `isComplete == false` for the formatter — the acceptance bar agreed above. It also un-refuses the page's `compact`/`accent` centre presets, which set non-null `LabelStyle`s and would still refuse after a formatter-only fix.

### D. Ring identity

**D1 — conform the pages.** Rename ring ids to `'<markId>-<name>'` in `concentric_donut_page.dart` and `selection_showcase_page.dart`. The contract keys off `name`, so the conforming id includes spaces and capitals (e.g. `'revenue-Current period'`). Ids and `ringWeights` keys must move **atomically** — probe-proven that splitting them throws `ArgumentError` at `performLayout`. Near-zero user-visible risk: every display surface (legend, tooltip, semantics, CSV) renders `name`, never `id`. The selection showcase's concentric family is blocked by ids alone and sets no `ringWeights`, so its change is a clean two-line edit.

**D2 — `ringIds: Map<String, String>?` on `DonutMark`,** keyed by the bare ring key, giving the explicit per-ring id. It is consulted **only when `_concentricMarkId` returns null**, so every existing emission stays byte-identical and the default id scheme remains the one convention. A key naming an unknown ring, or a partial map that leaves some rings unnamed, raises a named diagnostic (mirroring `invalidConcentricComposition`).

**`ringWeights` keying is not ambiguous:** `ConcentricDonutConfig.ringWeights` is keyed by *stable series id*, so it always uses whatever id the ring actually lowers to — `'<markId>-<key>'` by default, or the `ringIds[key]` value when the map supplies one. There is one rule ("key by the resulting series id"), not two schemes; the docs state it that way and the unknown-key diagnostic is evaluated against the resolved ids.

### E. Truth-up

- Correct the stale three-blocker claim in `doc/chart_grammar.md` and the pinned test-group comment; retire the Known-gap section and the "Not in V1" per-point-colour bullet.
- Update the emitter's file-header fidelity matrix.
- Make `_radialSeriesLossDetail` **family-aware**: after A the reversible set is colour **and** size for pie/donut but colour-only for polar. Two test assertions key on the current wording.
- Fold both pages into the acceptance gate; update the roadmap spec to mark 1a″ delivered.

## Invariants

- **Marks hold functions and config objects only** → no `copyWith`, no `@chartSurface`, **no new drift-gate surface** (`PieDataLabelConfig` and `DonutCenterContent` are already gated).
- **Byte-identical:** Cartesian, polar, pie, and uniform-label/default-centre donut and concentric emission unchanged; existing goldens unchanged.
- **Emitted == faithful:** the round-trip proof stays strict; anything the marks cannot carry is refused with a named reason, never silently degraded. A live callback degrades to a named placeholder with `isComplete == false` — the established contract, not an exception to it.
- **Field-allocation order is load-bearing** in the emitter: `_synthesiseRadialRows` sizes rows from current slot counts, so the colour field must be allocated **before** row synthesis. `_planConcentric` is the tight one.
- **Acceptance is measured against the mounted page**, never a transcribed fixture, and hand-transcribed fixtures carry a drift guard.

## Slices (each independently testable, each ends green)

1. **`sliceColor` channel** — mark + builder + lowering (pie, donut, concentric buckets) + emitter; family-aware loss detail; convert the pinned blocker-2 test to an acceptance case; add refusals for `scatterMarkerShape`, bare `PointStyle()`, and mixed colour-only/size-only; partial-colouring and per-ring-colour cases.
2. **Donut centre parity** — carry the captured centre verbatim; swap `_emitDonutCenter` for the shared renderer. **`DonutChartsPage` DONE** (mounted-page assertion; `isComplete == false` with the formatter warning).
3. **`dataLabelsByRing`** — mark field, `geomDonut` param, both lowering paths incl. the single-ring collapse, unknown-key diagnostic, override projection, the unconditional sorted-key seam; convert the pinned blocker-3 test.
4. **Ring identity** — D1 rename (atomic with `ringWeights`) + D2 `ringIds` map and diagnostics. **`ConcentricDonutPage` and the selection showcase DONE.**
5. **Close the gap in prose** — docs, matrix, acceptance gate, roadmap; BC-0032 evidence and status.

Serialised, not parallel: slices 1, 3 and 4 all touch `mark.dart`, `plot_lowering.dart` and the two emitters.

## Testing

- **Round-trip per blocker:** a pie/donut with per-slice colours; with colours *and* variable radius; with partial colouring; a concentric chart with divergent per-ring labels; a donut with a styled centre; a concentric chart with arbitrary ring ids via `ringIds`.
- **Honest refusals, each pinned:** `scatterMarkerShape`/`scatterMarkerStyle`, bare `const PointStyle()`, mixed colour-only/size-only, unknown/partial `ringIds` keys.
- **Mounted-page acceptance:** `ConcentricDonutPage`, `DonutChartsPage` and the selection showcase's concentric family each mounted, their live documents generated, asserted to emit — with `DonutChartsPage` asserted at `isComplete == false` naming the formatter.
- **No regression:** Cartesian/polar/pie and uniform-label/default-centre radial emission byte-identical; drift gates green; the fidelity guard stays mutation-killing.

## Files

- **Modify** `lib/src/grammar/mark.dart` — `PieMark.sliceColor`; `DonutMark.sliceColor`/`dataLabelsByRing`/`ringIds`.
- **Modify** `lib/src/grammar/chart_builder.dart` — the new `geomPie`/`geomDonut` params (preserve the NUL sentinel).
- **Modify** `lib/src/grammar/plot_lowering.dart` — `_sliceColors` helper; `_lowerPie`/`_lowerDonut` (expression bodies become blocks); `_lowerConcentricRings` per-bucket colours, per-ring labels and explicit ids; the single-ring collapse path.
- **Modify** `lib/src/grammar/grammar_diagnostics.dart` — ring-id diagnostics.
- **Modify** `lib/src/source/chart_grammar_source_generator.dart` — `_RadialPlan.sliceColor`; allocation order; `_fillRadialRows` and the concentric loop; centre carry; `_planConcentric` label/id projection; family-aware loss detail; header matrix.
- **Modify** `lib/src/source/chart_config_dart_emitter.dart` — `emitRadialLabelsByRing` seam; the shared centre renderer parameterised on argument name.
- **Modify** `example/lib/showcase/pages/concentric_donut_page.dart`, `example/lib/showcase/pages/selection_showcase_page.dart` — conforming ring ids (atomic with `ringWeights`).
- **Tests** under `test/unit/grammar/` and `test/unit/source/`, plus mounted-page acceptance; `example/test/showcase/concentric_donut_page_test.dart` id assertions.
- **Docs** `doc/chart_grammar.md`, the roadmap spec, BC-0032.

## Out of scope

- Formatter binding (emitting live callbacks as literals) — a distinct, larger item spanning pie labels, donut centres and slice-radius formatters.
- Radial faceting; radial-bar/gauge/range-area marks (roadmap 1b); bar/scatter advanced fields (1c/1d).
