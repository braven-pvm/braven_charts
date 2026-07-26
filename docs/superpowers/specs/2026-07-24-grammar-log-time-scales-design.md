# Grammar Log + Time Scale Types — Design

**Date:** 2026-07-24
**Status:** Approved (brainstorming). Next: implementation plan — **hold planning until PR #104 (scale-driven channels) merges** (it touches the same grammar files; build off the new master to avoid a parallel-branch rebase).
**Programme:** Fluent/Grammar-of-Graphics, Theme A — Breadth. **Fourth and final Breadth item** (after faceting #92, radial #99, scale-driven channels #104).

## Goal

Give an axis a real **scale type** so the grammar can express non-linear / non-numeric axes:

- **Log** — `.xLog()` / `.yLog()` → a log(base 10 by default) position mapping with decade ticks.
- **Time** — `.xTime((row) => row.date)` → a DateTime axis with calendar-nice ticks and date-formatted labels.

Today every axis is an implicit **linear numeric** scale: the value→pixel transform and every tick generator are hardcoded linear (nice-number 1/2/5×10ⁿ), and there is no scale-type concept anywhere. This is therefore a **render-pipeline feature**, unlike the prior three Breadth slices which were grammar-only.

## Feasibility basis (why this needs render work)

Verified during brainstorming:
- **No scale-type exists.** value→pixel is hardcoded linear in `coordinates/chart_transform.dart:148` (`dataToPlot`), `axis/linear_scale.dart:56` (`dataToPixel`), and `rendering/multi_axis_normalizer.dart:41` (Y `normalize`, the multi-axis path the grammar always uses). Tick generation is linear nice-number in `axis/tick_generator.dart`, `rendering/x_axis_painter.dart:342`, `rendering/multi_axis_painter.dart`.
- **The label seam is config-only.** `labelFormatter(double)→String` is honored across the whole render path (X `x_axis_painter.dart:409`, Y `multi_axis_painter.dart:507`, width measure, crosshair, transposed). It can format `10³` or a date **once positions exist**, but is not sufficient alone.
- **Time positions already work** if `x` is epoch-millis (the transform is numeric), but **calendar-nice tick spacing needs render work** — nice-number on epoch-millis lands ticks on arbitrary ms boundaries, not month/year boundaries.
- **Config passthrough is ready:** `PlotSpec.xAxis`/`yAxes` flow through `plot_lowering._lower` → `LoweredPlot` verbatim (`plot_lowering.dart:372`), so a new axis-config field reaches the renderer with no new plumbing.

## Architecture — one enum, dispatched in three layers

`AxisScaleType { linear, log, time }` (+ a `double logBase`, default 10) lands on **`XAxisConfig` and `YAxisConfig`**. Three layers consume it:

1. **Config surface (foundation).** The two new fields (`scaleType`, `logBase`) are added to both already-`@chartSurface` axis configs, so they flow through all **four drift gates** — fluent surface regen (`surface_gen`, `missing=0`), artifact codec (`test/meta/codec_drift_test.dart`), Config-source emitter (`test/meta/source_emitter_drift_test.dart`), AI schema (`test/meta/ai_mirror_drift_test.dart`). This is the wider blast radius that distinguishes this slice from the prior grammar-only ones, and is the reason for the phased build below.
2. **Render.** The value→pixel transforms and tick engines gain a scale-type branch:
   - **Log:** fraction = `(log(v) − log(min)) / (log(max) − log(min))` (base `logBase`); ticks are the powers of the base within `[min, max]` (decade ticks), optionally with 2·5 minor ticks; labels default to the value (formatter seam can render `10ⁿ`).
   - **Time:** linear on epoch-millis for position (unchanged transform), but a **calendar-nice** tick generator picks a human interval (year / quarter / month / week / day / hour / minute / second) from the visible domain, and labels are date-formatted per the chosen interval.
3. **Grammar.** Sugar verbs lower to the config (below); the full `XAxisConfig(scaleType: …)` / `YAxisConfig(scaleType: …)` passthrough remains the escape hatch.

## Config surface

Add to **both** `XAxisConfig` (`models/x_axis_config.dart`) and `YAxisConfig` (`models/y_axis_config.dart`):

```dart
/// How this axis maps data values to positions and generates ticks.
final AxisScaleType scaleType;   // default AxisScaleType.linear

/// Base for AxisScaleType.log. Ignored for other scale types.
final double logBase;            // default 10
```

`enum AxisScaleType { linear, log, time }` in a new `models/axis_scale_type.dart` (exported from the core barrel). Both configs stay `const`-constructible with the new fields defaulted, so no existing call site breaks. `copyWith`, `==`, `hashCode`, and the `@chartSurface` fluent surface extend to the two fields; the artifact codec, Config emitter, and AI schema each learn to round-trip them (drift gates enforce it).

**Mode exclusivity.** `scaleType == time` (or `log`) and X's existing `categoryAxis` (`CategoryAxisConfig`) are mutually exclusive interpretations of the X domain. Setting both raises a diagnostic at grammar lowering (see below); at the config level the category axis keeps its current precedence (documented), so the render change is additive and safe for existing charts.

## Log scale

- **Base** default 10, configurable via `logBase` (config) or the grammar verb (`.yLog(base: 2)`).
- **Non-positive values fail loud.** A log axis whose bound data includes a value ≤ 0 raises `GrammarDiagnosticCode.nonPositiveLogValue` at lowering, naming the offending value and mark — consistent with the grammar's "nothing silently dropped/defaulted" invariant. (The author filters or transforms non-positive data.)
- **Transform:** dispatched in `chart_transform.dart` (X), `multi_axis_normalizer.dart` (Y), and `linear_scale.dart` / the `Axis` wrapper. A log branch computes the fraction in log space; `logBase` only rescales, so `log10` is used internally with a base divisor.
- **Ticks:** a log-decade generator emits the powers of the base spanning `[min, max]` (e.g. 1, 10, 100, 1000), with the axis's `tickCount` bounding how many decades/minors show; degenerate domains (min==max, or < one decade) fall back to endpoints. Labels default to the plain value; a `labelFormatter` can render `10ⁿ`/superscript.

## Time scale

- **Input:** the grammar binds a `FieldAccessor<T, DateTime>` (`.xTime(...)`); lowering converts each row to `millisecondsSinceEpoch.toDouble()` for the point `x` and sets the x-axis `scaleType: time`. (Epoch-millis for realistic dates is ~1.7e12 — well inside a double's exact-integer range, so positions are exact.)
- **Ticks:** a calendar-nice generator chooses an interval from the visible millisecond span (year / quarter / month / week / day / hour / minute / second), places ticks on real calendar boundaries via `DateTime` arithmetic (not fixed-ms steps), and bounds the count by `tickCount`.
- **Labels:** **auto-derived from the chosen interval** (year → `2026`, month → `Feb 2026` / `Feb`, day → `Feb 3`, hour → `14:00`, …). Power users override via the existing `labelFormatter` seam (a `double` epoch-millis → String). No new date-format config field (keeps the config surface minimal). Timezone: millis are UTC-epoch; display uses local `DateTime` — timezone-aware display is out of scope.

## Grammar surface

New sugar verbs on `BravenChart<T>` (`chart_builder.dart`), each lowering to an axis-config `scaleType`:

```dart
// Log — x and/or y (log-log plots work: set both):
BravenChart<T> xLog({double base = 10});
BravenChart<T> yLog({String? id, double base = 10});   // id targets a declared Y axis slot

// Time — binds a DateTime field for the x axis:
BravenChart<T> xTime(FieldAccessor<T, DateTime> accessor, {String? label});
```

- `.xLog()` / `.yLog()` set the target axis's `scaleType: log` (+ `logBase: base`); they synthesize a minimal axis if none was declared, or set the field on the declared one (`.yLog(id: 'price')` targets a slot).
- `.xTime(accessor)` sets the chart's x accessor to `(row) => accessor(row).millisecondsSinceEpoch.toDouble()` and the x-axis `scaleType: time`. Marks inherit the x accessor as today.
- The full-config escape hatch (`.xAxis(XAxisConfig(scaleType: …, logBase: …))`, `.yAxis(YAxisConfig(scaleType: …))`) remains for anything the sugar doesn't cover.

**Diagnostics** (grammar layer): `nonPositiveLogValue` (log axis, value ≤ 0); `conflictingAxisMode` (a spec sets both `scaleType: time`/`log` and `categoryAxis` on the same X axis). A time axis on a non-`.xTime` numeric x is allowed (the author may already have millis) — no diagnostic.

## Parity ("emitted == faithful")

The lowered `XAxisConfig`/`YAxisConfig` (with `scaleType`/`logBase`) must equal the hand-built config, and — because these are config-surface fields — must round-trip through the artifact codec, the Config-source emitter, and the AI schema (the drift gates enforce this). The showcase preset renders the grammar-authored log/time chart beside its hand-built equivalent.

## Architecture / file structure

- **Create** `lib/src/models/axis_scale_type.dart` — the `AxisScaleType` enum (exported from the core barrel).
- **Modify** `lib/src/models/x_axis_config.dart`, `y_axis_config.dart` — add `scaleType` + `logBase` (fields, ctor, `copyWith`, `==`/`hashCode`, `@chartSurface`).
- **Modify** the mirrors so the drift gates stay green: the artifact codec (encode/decode both fields for both axes), the Config-source emitter, and the AI schema/`surfaceDefinitions`.
- **Create** the scale-aware render pieces (a log/decade tick generator + a calendar-nice date tick generator), and **modify** the transforms (`chart_transform.dart`, `multi_axis_normalizer.dart`, `linear_scale.dart`/`axis.dart`) + tick painters (`x_axis_painter.dart`, `multi_axis_painter.dart`) to dispatch on `scaleType`. Keep the linear path byte-identical when `scaleType == linear` (no regression on existing charts).
- **Modify** `lib/src/grammar/chart_builder.dart` — `xLog`/`yLog`/`xTime` verbs.
- **Modify** `lib/src/grammar/plot_lowering.dart` — the `nonPositiveLogValue` + `conflictingAxisMode` checks (structural pass), and `xTime`'s DateTime→millis lowering.
- **Modify** `lib/src/grammar/grammar_diagnostics.dart` — the two new codes + factories.
- **Showcase (deliverable):** a Log / Time preset on the Chart Grammar page (a log-y chart and a time-x chart authored via the grammar, each beside its hand-built equivalent).

## Testing

- **Config surface:** `scaleType`/`logBase` on both axes survive `copyWith`/`==`, and the **four drift gates** stay green (fluent `missing=0`, codec round-trip, Config emitter, AI schema).
- **Log render:** the value→pixel fraction matches `(log v − log min)/(log max − log min)`; decade ticks land on powers of the base; a `logBase: 2` axis uses base 2; `nonPositiveLogValue` throws on ≤ 0.
- **Time render:** DateTime→millis positions are exact; calendar-nice ticks land on real calendar boundaries (assert the tick DateTimes, e.g. month firsts); auto labels format per interval; a `labelFormatter` override wins.
- **Grammar parity:** `.xLog()`/`.yLog(base:)`/`.xTime()` lower to the expected `XAxisConfig`/`YAxisConfig` (whole-config `==` vs hand-built); `conflictingAxisMode` throws on time+category.
- **Linear regression:** every existing golden is unchanged (linear path untouched); add scale goldens (log axis, time axis) each with the repo's `_TolerantGoldenFileComparator` from the start.

## Build phasing (planning note — one lane, sequential, hold until #104 merges)

1. **Foundation** — `AxisScaleType` + `logBase` on both configs + all four drift-gate mirrors green (no rendering behavior yet; linear stays default).
2. **Log render** — transform dispatch + decade tick generator + labels + `nonPositiveLogValue`.
3. **Time render** — DateTime→millis + calendar-nice tick generator + auto date labels.
4. **Grammar wiring** — `xLog`/`yLog`/`xTime` verbs + `conflictingAxisMode` + config parity + the showcase preset.

## Invariants preserved

- Linear axes are byte-identical to today (the scale branch only activates for `log`/`time`); no existing chart or golden changes.
- `PlotSpec` stays the single description; the new config fields flow through the existing `xAxis`/`yAxes` passthrough.
- Same lowering-parity + fail-loud-diagnostic discipline as the prior slices.

## Out of scope (future)

- Symlog / other non-log non-linear scales; per-tick custom date formats beyond the interval-auto + `labelFormatter`.
- Timezone-aware time axes (display uses local `DateTime`; UTC-epoch storage).
- Ordinal/categorical time (already covered by `CategoryAxisConfig`).
- Log/time on radial or faceted axes (Cartesian axes only for this slice).
