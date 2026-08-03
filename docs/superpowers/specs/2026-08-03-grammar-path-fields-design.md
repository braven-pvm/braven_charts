# Path-Field Completeness for the Cartesian Marks — Design

**Date:** 2026-08-03
**Status:** Drafted for review. Next: implementation plan.
**Programme:** Fluent/Grammar-of-Graphics **Roadmap v2.0, Theme 1 — item 1d**, first slice.
**Register:** BC-0054 (lane `chart-grammar`).
**Worktree/branch:** `F:\Repositories\braven_charts-path-fields`, `feature/grammar-path-fields` (off master `b60ec846`).

## Goal

`LineMark`, `AreaMark` and `RangeAreaMark` carry the path and marker fields their
series already have, so a configured Line/Area/Range-Area chart stops being
refused for styling the grammar could express all along.

## Measured baseline

Master `b60ec846`, census green, 2026-08-03. Whole repo **59 emitting**;
Cartesian **28 of 129** with a verdict.

States naming a slice-1 field as their FIRST blocker:

| Field | States | Where |
|---|---|---|
| a fill gradient | **9** | RangeArea 5, Line 2, Area 2 |
| a data-point marker radius | **4** | Line 2, ValueSummary 1, Workbench 1 — all `LineChartSeries` |
| a path animation | **3** | Line 1, Area 1, RangeArea 1 |
| a data-point marker style | 1 | Line (Forecast) |
| a line glow | 1 | Area (playground) |
| a split baseline fill | 1 | Area (Baseline) |
| an inline series label | **0** | — |
| a curve tension | **0** | — |

**19 states name one of these first.** That is the ceiling for this slice, not
its forecast — see *What the prediction is not* below.

## Scope

### Carried

- **`LineMark`** — `dataPointMarkerRadius`, `dataPointMarkerStyle`, `tension`,
  `lineGlow`, `inlineLabel`, `pathAnimation`
- **`AreaMark`** — the same six, plus `fillGradient`, `aboveBaselineFillColor`,
  `belowBaselineFillColor`
- **`RangeAreaMark`** — `fillGradient`, `pathAnimation`

After this slice all three marks are **field-complete** against their series for
everything `_firstUncarriedField` names, and each arm shrinks to empty exactly as
the candlestick and heatmap arms already are. Following BC-0040's precedent, a
check for a now-carried field is **deleted** rather than left dead — that is what
its `// … now carried by LineMark, so no longer in the uncarried set` comments
record.

### Why `tension` and `inlineLabel` are carried despite measuring zero

The standing bar is "carried, or **proven inert**". These two are **not** inert —
they are **masked**, which is a different thing and deserves a different answer.

- `inlineLabel`: `Area|Composition` sets one
  (`cartesian_chart_type_pages.dart:4370`/`:4391`). It measures zero only because
  `fillGradient` is checked first. Carry `fillGradient` without it and that state
  re-refuses one field later — the slice would move a blocker rather than remove
  one.
- `tension`: both authored sites pass a **slider** whose default equals the
  `0.25` series default, so the census structurally cannot see it. A user who
  moves that slider produces a chart that can. Zero here is an artefact of the
  census's default-state population, not a property of the field.

The `segmentStyle` precedent (BC-0040) refuses a field that is inert **and**
expensive — it would need a whole new row-field kind. These are one scalar and
one seam over a renderer that already exists. Cheap-and-masked is not the shape
that precedent governs.

**This is the slice's one genuinely arguable call**, so it is flagged rather than
buried: if the owner prefers the strict reading — nothing carried without a
non-zero measurement — drop `tension` only. Dropping `inlineLabel` would
knowingly leave `Area|Composition` one field short.

## Architecture

### A. Three public seams, no new renderers

Every config object here already has a private renderer in
`ChartConfigDartEmitter`:

| Object | Renderer | Seam needed |
|---|---|---|
| `AreaGradient` | `_emitFillGradient` (`:1962`) | `emitFillGradient` |
| `PathAnimationStyle` | `_emitPathAnimationStyle` (`:2338`) | `emitPathAnimationStyle` |
| `SeriesInlineLabelConfig` | `_emitInlineLabelArgument` (`:2590`) | `emitInlineLabel` |

This is exactly the pattern BC-0038 established with `emitRangeAreaBoundaryStyle`
/ `emitRangeAreaLabelConfig`: one body, two callers, so the config form and the
grammar form cannot drift. `DataPointMarkerStyle` needs checking — if it has no
renderer it is the slice's only new one.

**The cost claim in BC-0054 was wrong and is retracted there.** Carrying a
config-typed *field* on a mark does not trigger `@chartSurface` enforcement:
marks have no `copyWith` and are structurally exempt (`mark.dart:50-57`), and
`AreaGradient`/`PathAnimationStyle` are already in the manifest. No surface
change, no `build_runner` diff, no drift-gate registration.

### B. Nullable means "the series default"

Every carried config field is nullable on the mark; null lowers to the series
default, resolved once in the lowering. This is `RangeAreaMark`'s stated contract
(`mark.dart:936-939`) and it keeps ONE source of truth for the defaults.

Note the wrinkle: `pathAnimation` is **non-nullable** on all three series with a
`const` default, so a nullable mark field deliberately diverges from the series
it lowers to. That is the right trade — the alternative is the mark carrying a
copy of a default that can silently go stale — and it matches how BC-0038 handled
`labelConfig`, `borderMode` and the boundary styles.

### C. The reversal maps a defaulted capture back to null

`_planGeometry` sets each field to null when the captured value equals the family
default, so a plain chart emits none of these arguments and **existing emission
stays byte-identical**. Same `_defaultedOrNull` helper BC-0038 added.

### D. Two missing checks in the Area arm, fixed as a side effect

`AreaChartSeries` has `tension` and `dataPointMarkerStyle`
(`chart_series.dart:814`, `:824`), and the Area arm of `_firstUncarriedField`
(`:2154-2174`) checks **neither** — so an area chart differing only in those two
falls into the unnamed generic tail, told its chain would differ and not told
why. Carrying both closes the gap at source.

## The ordering trap — this slice is INDIVISIBLE

Splitting it produces a slice that closes nothing while looking like progress:

- `fillGradient` is checked **before** `pathAnimation` in the RangeArea arm, and
  `range_area_charts_page.dart:402` builds a `PathAnimationStyle`
  **unconditionally for every band**. Ship `fillGradient` alone and the RangeArea
  page emits **nothing** — its 5 gradient refusals merely relabel to path-animation
  refusals.
- The same page mounts an observed `LineChartSeries` carrying
  `dataPointMarkerRadius: 3.4` on temperature / confidence / forecastFan /
  volatility (`:502-503`). So `LineMark` must gain its fields in the **same**
  slice or the page stops at 3 of 7.

## What the prediction is not

**Predicted: +12 emitting (honest range 9–17).** Cartesian 28 → ~40.

The 19 first-blocker states are a **ceiling**. `_firstMismatch` returns at the
first mismatching series and `_firstUncarriedField` at the first uncarried field
within it, so nothing in the census reveals what is queued behind. Two states in
the prediction — `ValueSummary|pinned` and `Workbench|default` — were never
traced to a full field set by the recon; if either carries a second uncarried
field, the number drops.

The round-trip proof also compares points, axes and annotations, so emptying a
chart's uncarried-field set is **necessary but not sufficient**.

**The acceptance criterion is therefore the measured delta with its composition
named, not the predicted one.** A result of +9 with all nine accounted for is a
pass; +12 that cannot be decomposed is not.

## Invariants

- **Existing emission byte-identical**; goldens unchanged; drift gates green.
- No new `@chartSurface`/`copyWith` surface on marks.
- Anything still not carried is refused with a **named** reason.
- The emitted chain passes the generated-source compile floor.
- Every newly emitted argument gets a whole-argument-list assertion (BC-0046).
- Acceptance measured on the **mounted pages**, never transcribed fixtures.

## Out of scope, recorded

- **The bar bucket (26 states).** Carrying the roadmap's three named bar fields
  moves emitting by **≤1** while converting 26 precise refusals into 26
  generic-tail ones — a diagnostic regression. `waterfallStyle`, which stands
  behind 25 of 28 BarLab presets, is not in the roadmap's list. Needs an owner
  decision before any bar code.
- **Shared-x alignment (24)** — its own design; one row list plus total accessors
  cannot express divergent x domains.
- **Heatmap `yAxisId` unset (11)** — a bucket the roadmap never had; it is the
  `seriesWithoutAxisBinding` family list again, now for heatmap.
- **The scatter cluster** — a later 1d slice; `jitter` is its cleanest win.
- **The 5 unnamed residuals** — a naming slice worth doing for its own sake.
