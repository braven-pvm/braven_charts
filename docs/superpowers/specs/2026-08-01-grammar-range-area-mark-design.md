# Range Area Grammar Mark — Design

**Date:** 2026-08-01
**Status:** Approved (brainstorming). Next: implementation plan.
**Programme:** Fluent/Grammar-of-Graphics **Roadmap v2.0, Theme 1 — item 1b**, first family.
**Register:** BC-0038 (lane `chart-grammar`).
**Worktree/branch:** `F:\Repositories\braven_charts-range-area`, `feature/grammar-range-area` (off `origin/master` `56fddba7`).

## Goal

`RangeAreaChartSeries` becomes grammar-authorable through a `geomRangeArea(low:, high:)` verb, and the **selection lab's** Range Area family emits a faithful, round-tripping chain.

## What this delivers, stated honestly up front

**The `RangeAreaChartsPage` will still show "not emitted" after this slice, on all 7 presets.** That is measured, not feared: every band on that page carries a non-default `pathAnimation` and six of seven carry a `fillGradient` — both **named refusals on `AreaMark` today** and both roadmap **1d**. Four presets are additionally held by their companion line's `dataPointMarkerRadius`, and `confidence` by an x-domain divergence no mark can lift (see below).

What it *does* close is the **selection lab's Range Area family**, whose bands diverge only on range-area-native fields and whose centre line already emits: census `Selection [10, 10, 7] → [10, 10, 8]`, `_expectedEmitting 58 → 59`.

**Owner decision:** deliver the native-only mark and record the RangeArea page as a 1d-plus-page story, rather than carrying 1d fields on this one mark. Carrying them here would fix `pathAnimation`/`fillGradient` narrowly for one family while `LineMark`/`AreaMark` still refuse the same two — an asymmetry a user hits immediately — when 1d fixes them once for every Cartesian family.

## The blocker that makes or breaks this slice

**`seriesWithoutAxisBinding` does not handle range area, and without it nothing emits at all.**

`lib/src/grammar/series_axis_unbinding.dart` enumerates five Cartesian families and returns `null` for everything else — its docstring names range-area explicitly. The generator maps `null` to "series unchanged", so on a legacy single-axis chart (which every Range Area page state is) the *lowered* band keeps `yAxisId` + inline `yAxisConfig` while the *captured* band has neither. `_firstMismatch` then refuses **every** range-area chart, through the generic residual tail that names no field.

`BravenPlot._legacySingleAxisSeries` inherits the same gap through the same helper: it calls `seriesWithoutAxisBinding` and returns `null` for the whole plot on any family the helper cannot unbind, so a `geomRangeArea` chain would mount **multi-axis** and re-extract a document carrying `series[*].axisId` + `inlineAxis` the captured chart does not have.

**The fix is one arm, in the one shared helper** — `RangeAreaChartSeries.copyWith` already exposes `clearYAxisId`/`clearYAxisConfig`, and both callers pick it up at once. That is exactly what the file was split out to guarantee, and it is why this is a two-line change rather than two changes that could drift. It is called out here because a mark built without it would be complete, correct, and close **zero** panes.

## Architecture

### A. `RangeAreaMark<T> extends SeriesMark<T>`

`SeriesMark` (added by BC-0040) already gives `id`, `name`, `color`, `yAxisId` and `unit`. The mark declares:

- **`x: FieldAccessor<T, num>`** — required.
- **`low` / `high`: `FieldAccessor<T, num?>`** — nullable, because `RangeAreaDataPoint.gap` sets both to null and a total accessor cannot express a gap. Precedent already exists in the mark layer: `PolarMark.target`/`intervalLow`/`intervalHigh` are all `FieldAccessor<T, num?>?`. Both null for a row ⇒ `RangeAreaDataPoint.gap`; exactly one null ⇒ a named diagnostic, mirroring `incompletePolarInterval`.
- **`label` / `pointKey`** — following the Line/Area pattern; the selection lab's bands carry `pointKey` on every point.
- **Range-area-native config:** `interpolation`, `tension`, `fillOpacity`, `borderMode`, `upperBoundaryStyle`, `lowerBoundaryStyle`, `connectGaps`, `showBoundaryMarkers`, `markerRadius`, `labelConfig`, `hitTestMode`.

**Not carried, deliberately:** `pathAnimation` and `fillGradient` (roadmap 1d — they are named refusals on `AreaMark` today and must stay symmetric), and `isXOrdered` (the `RangeAreaChartSeries` constructor hard-codes it `true`, exactly as candlestick does, so exposing it would be a lie).

**No channels.** `_paintRangeAreaSeries` paints from the series colour, `fillOpacity`, the boundary styles and the theme; a grep across the whole range-area paint block for `pointStyle`/`segmentStyle`/`colorValue` returns nothing, and `RangeAreaScreenPoint` carries only `sourceIndex`/`point`/`upper`/`lower`. A `colorBy` or size channel would be inert, so it is not offered — noted in the mark's docstring so the omission reads as a decision.

### B. Plan shape — candlestick is the template

`_GeometryPlan.accessors` is still a role map, and candlestick is still the precedent for a geometry with **no single `y`**: its arm registers `open`/`high`/`low`/`close` and never writes `accessors['y']`, with `_emitGeometry` special-casing it. Range Area adds roles `low`/`high` the same way.

**`_fillRows`'s default arm would null-assert on a range-area plan** — it does `row.numbers[plan.accessors['y']!.slot]`. It needs its own arm, exactly as candlestick and scatter have. The `_FieldKind.optionalNumber` machinery already exists *and* the Cartesian `_synthesiseRows` already allocates its slots, so the nullable channel costs no new plumbing.

### C. Authoring-side validation

`RangeAreaChartSeries.validateConfiguration()` throws a raw `ArgumentError` for non-strictly-increasing x. Reversal is safe (a captured band is already valid), but a user authoring `geomRangeArea` over unsorted rows would get an `ArgumentError` instead of a diagnostic. Translate it to a named `invalidRangeAreaRow`, exactly as `_lowerCandlestick` does for `invalidCandlestickRow`.

### D. The label-formatter silent-drop — fixed here, not inherited

`ChartConfigDartEmitter._emitRangeAreaLabelConfig` emits `value`, `labels` and `boundaryGap` but **never `formatter`, and raises no warning**. Because the mark carries `labelConfig` verbatim, the round-trip proof compares that instance against itself — the documented passthrough caveat — so **the proof structurally cannot catch the loss**.

The **drift gate cannot catch it either**, and for a nameable reason: `formatter` is omitted from the generated surface manifest (`'Omitted from this schema: formatter (callback — no JSON form)'`), so `source_emitter_drift_test`'s class-aware slice never lists it as a property `RangeAreaLabelConfig` should emit. Callback fields sit in the blind spot of both mechanisms at once — which is what let this survive.

Fixed in this slice by emitting a `// formatter:` placeholder plus a `runtimeValueOmitted` warning, matching what data-point labels and bar labels already do. **Owner-decided:** fix rather than inherit, since the mark would otherwise ship on a known silent-drop path and the fixture would have to leave `formatter` null to keep the warning list empty — quietly hiding the gap. It touches the Config emitter (BC-0048's territory), so it is called out in the PR.

### E. The BC-0046 obligation

Every emitted grammar argument is now pinned, so `geomRangeArea` must arrive with its own **maximal-fixture whole-list assertion** (a new shape, following 36–39/42/43), or the existing gates will flag it.

Three constraints from the pattern:
- **`allMatches(...).length == 1` is mandatory**, and the fixture must be a **hand-written single-band chart** — `forecastFan`, `interactionStates` and the selection lab all mount two bands, and `literalArguments` silently reads only the first occurrence.
- The nested config literals flatten into one long list (~50 entries). That is workable, but `RangeAreaBoundaryStyle(` appears **twice** inside the slice, so no sub-assertion may open on it.
- The fixture leaves `labelConfig.formatter` null so `warnings` stays empty — with the placeholder from §D pinned by its own separate test, so the carve-out does not hide the gap.

## Invariants

- **Existing emission byte-identical**; goldens unchanged; drift gates green.
- **No new `@chartSurface`/`copyWith` surface on marks** — the mark carries accessors and existing config objects.
- Anything the mark cannot carry is refused with a **named** reason, never silently degraded.
- The emitted chain passes the generated-source compile floor (`dart format` then `dart analyze`).
- Acceptance is measured on the **mounted page**, never a transcribed fixture.

## Slices

1. **`RangeAreaMark` + lowering** — the mark on `SeriesMark`, the `geomRangeArea` verb, `_lowerRangeArea` with gap semantics and the `invalidRangeAreaRow` translation, plus the single `seriesWithoutAxisBinding` arm that unblocks both callers. Absorbs the sealed-switch sites.
2. **Emitter reversal** — `_planGeometry` arm, the `_fillRows` arm, `_emitGeometry` verb + arguments, new **public seams** over the existing private `_emitRangeArea*` renderers so the two forms cannot disagree.
3. **The formatter placeholder** — `_emitRangeAreaLabelConfig` gains the `// formatter:` placeholder and `runtimeValueOmitted` warning, pinned by its own test.
4. **Acceptance and gates** — the maximal whole-list shape; a mounted-page gate for the selection lab's Range Area family; census expectations updated (`_expectedPerPage['Selection']`, `_expectedPerFamily[cartesian]`, `_expectedEmitting`), and the `'no range-area mark'` bucket reconciled.

## Testing

- Round-trip per carried field on non-default fixtures; gap rows; a partially-gapped band.
- Named refusals pinned: half-specified interval, non-increasing x, and each 1d field the mark deliberately does not carry.
- **Mounted-page acceptance** for the selection lab's Range Area family, including the compile floor.
- The whole-list assertion, mutation-verified both directions per BC-0046's pattern.
- No regression: existing emission byte-identical, drift gates, both analyzers, the changed-file format gate.

## Out of scope (recorded, not oversights)

- **The `RangeAreaChartsPage`'s 7 presets.** Held by 1d fields (`pathAnimation`, `fillGradient` on the bands; `dataPointMarkerRadius`, `pathAnimation` on the companion lines) and, for `confidence`, by the x-domain gate: `_observedPoints` skips gaps, so the line has 19 points to the band's 20, and one row list cannot hold both. That last one is **page-shaped** — either the page emits a gap-preserving observed line, or `confidence` stays blocked whatever the grammar does.
- **Radial Bar and Gauge** — the other 1b families. Gauge still waits on BC-0034/BC-0036.
- **The config emitter's wider assertion gap** — BC-0048.
