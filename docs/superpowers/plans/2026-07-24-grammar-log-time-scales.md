# Grammar Log + Time Scale Types Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add axis scale types (log10 + time/date) to the config + render + grammar so `.xLog()`/`.yLog()`/`.xTime((r)=>r.date)` produce a logarithmic axis (decade ticks) and a DateTime axis (calendar-nice ticks + date labels), while the linear path stays byte-identical.

**Architecture:** A new `AxisScaleType {linear, log, time}` enum + `logBase` land on `XAxisConfig`/`YAxisConfig` (config surface → 4 drift gates). The **single positioning class `ChartTransform`** gains `xScaleType`/`yScaleType` and a scale-aware `dataToPlot`/`plotToData` (covering series geometry AND the zoom/pan/hit-test inverse together); `scaleType` is threaded in from the axis config at three sites. Tick generation + labels + a "second front" of parallel linear math (`LinearScale`, `MultiAxisNormalizer`, domain guards, zoom/pan) are updated in lockstep. Grammar verbs lower to the config `scaleType`; `.xTime` wraps the DateTime accessor to epoch-millis.

**Tech Stack:** Dart ≥3.9 / Flutter ≥3.35; `dart:math` (`log`, `ln10`, `pow`) for log/decade math; `DateTime` calendar arithmetic for time ticks; `build_runner` (`surface_gen`) regenerates the fluent surface + `surface_definitions.dart`.

## Global Constraints

- Work only in worktree `F:\Repositories\braven_charts-scales` on branch `feature/grammar-log-time-scales`; commit there. Specific `git add <paths>`, never `git add -A`.
- Analyze with `flutter analyze lib` (vendored-safe; NOT root). `flutter analyze example/lib` for the showcase task.
- **Keep the LINEAR path byte-identical.** Gate every new branch as `scaleType == AxisScaleType.linear ? <original expression verbatim> : <new>`. No existing golden may change; the plan's final task asserts this.
- Every new golden uses the repo's `_TolerantGoldenFileComparator` from the start (tolerance 0.025–0.035), copied from an existing golden suite.
- Drift gates (`test/meta/`, 51 tests) MUST stay green; the config-surface change is what makes `build_runner` regeneration mandatory (see Task 1.5).
- Commit messages end with: `Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>`.

## Verified code facts (post-#104, from extraction — re-confirm line numbers before editing)

- **Config:** `XAxisConfig` (`lib/src/models/x_axis_config.dart`, `@ChartSurface`, const ctor, `labelDisplay` enum-default pattern at field ~206, `tickCount` int? ~241, `copyWith` ~348, `==` ~431, `hashCode` ~466, `toString` ~499). `YAxisConfig` (`lib/src/models/y_axis_config.dart`, `@ChartSurface(excluded:['id'])`, **FOUR** construction sites: public ctor ~175, `_internal` const ctor ~227, `withId` factory ~261, `copyWith` ~537). Enum pattern to copy: `XAxisTickLabelCollisionPolicy` (`x_axis_config.dart:17`).
- **Codec (2 files):** `ChartAxisDocument` (`lib/src/artifacts/chart_document.dart`: param/field/`toJson` omit-if-default/`fromJson`) + `ChartAxisDocumentCodec` (`lib/src/artifacts/chart_axis_document_codec.dart`: `encodeXAxis`~15/`decodeXAxis`~83/`encodeYAxis`~156/`decodeYAxis`~196; enum via `.name`/`_enum(...)`, `_enum` helper ~254).
- **Emitter:** `_emitAxisFields` (`lib/src/source/chart_config_dart_emitter.dart` ~3405) + `_emitYAxisFields` (~3346); `_enumIf(writer,'labelDisplay','AxisLabelDisplay',axis.labelDisplay.name,defaultName:'labelWithUnit')` and `_numberIf(writer,'minHeight',axis.minHeight,0)` patterns.
- **AI schema:** `lib/src/ai/generated/surface_definitions.dart` is GENERATED (`// do not edit`); `dart run build_runner build` regenerates it + the `withScaleType`/`withLogBase` fluent verbs. `ai_mirror_drift_test.dart` keys on the flat `createChartTool` vocab (NOT surfaceDefinitions) → stays green if the flat AI vocab is left alone.
- **Positioning:** ONE `ChartTransform` per chart (`lib/src/coordinates/chart_transform.dart`; ctor ~60, `dataToPlot` ~148 linear `(v-min)/range`, `plotToData` ~181, `zoom` ~312, `pan` ~362, `copyWith` ~417, `==`/`hashCode` ~443; `@ChartSurfaceExempt`). Built at `lib/src/rendering/chart_render_box.dart:2708` (from primary `_xAxis`/`_yAxis`). Multi-axis Y = per-series `_transform.copyWith(dataYMin,dataYMax)` at `chart_render_box.dart:3928` (paint) + `:3096` (hit-test). Series geometry uses `SeriesElement._currentTransform.dataToPlot` everywhere.
- **Ticks (second front):** `LinearScale.dataToPixel` (`lib/src/axis/linear_scale.dart:56`, tick positions only, via `axis.dart`); `TickGenerator` (`lib/src/axis/tick_generator.dart:41` + `_makeNice` ~104); `x_axis_painter` value gen `generateTicks` ~469 + `_niceNum` ~638 + tick pixel `ratio` ~353 + `formatTickLabel` ~530 + `resolveTickValues`/category ~74; `multi_axis_painter` `_niceNum` ~548 + `formatTickLabel` ~506 + tick pixel via `MultiAxisNormalizer.normalize` ~246; `multi_axis_layout._formatValue` ~172 (width measure, must mirror Y label). **4 duplicated nice-number routines with different thresholds — do NOT unify.**
- **Domain:** multi-axis auto-range `lib/src/rendering/modules/multi_axis_manager.dart:597` (padding ~808-815, fallbacks 0/100); primary `lib/src/utils/data_converter.dart:141`.
- **Grammar:** `chart_builder.dart` backing fields ~85, `_copy` (??-merge, can't clear) ~143, `.x()/.y()` ~204, `.xAxis()/.yAxis()` ~602, `toSpec()` axis synthesis ~644. `plot_lowering.dart` passthrough ~369, `_resolveAxes` ~510, structural pass ~250, materialization + `_xyPoints` ~527 (all families do `mark.x(row).toDouble()`), candlestick per-row throw ~718. `grammar_diagnostics.dart` enum ~83 + factories (`invalidCandlestickRow` ~227 is the data-dependent template). `FieldAccessor<T,V>` (`channel.dart:15`); `CandlestickMark.timestamp` is already `FieldAccessor<T,DateTime>?` (`mark.dart:547`). Tests: `throwsGrammarCode` matcher re-declared per file; `chart_builder_test.dart:584` asserts `lowered.xAxis`/`yAxes`.

## File Structure

- **Create** `lib/src/models/axis_scale_type.dart` — `AxisScaleType` enum (export from core barrel `lib/braven_charts.dart`).
- **Create** `lib/src/axis/log_ticks.dart` — pure log-decade tick-value generator (unit-testable, no Flutter).
- **Create** `lib/src/axis/time_ticks.dart` — pure calendar-nice date tick generator + interval→label formatter (unit-testable).
- **Modify** the config classes, codec (2 files), emitter, `ChartTransform`, `chart_render_box` (3 plumbing sites), `LinearScale`/`axis.dart`, `MultiAxisNormalizer` callers, the tick painters, `multi_axis_manager`/`data_converter` domain guards, `chart_builder`, `plot_lowering`, `grammar_diagnostics`, and the Chart Grammar showcase page.

---

# PHASE 1 — FOUNDATION (config surface + drift gates; NO behavior)

Linear stays the default; nothing renders differently. Deliverable: the two fields exist end-to-end and all drift gates are green.

### Task 1.1: AxisScaleType enum + fields on XAxisConfig

**Files:** Create `lib/src/models/axis_scale_type.dart`; Modify `lib/src/models/x_axis_config.dart`, `lib/braven_charts.dart`; Test `test/unit/models/x_axis_config_scale_test.dart`.

**Interfaces — Produces:** `enum AxisScaleType { linear, log, time }`; `XAxisConfig.scaleType` (`AxisScaleType`, default `linear`), `XAxisConfig.logBase` (`double`, default `10`).

- [ ] **Step 1: Write the failing test**

```dart
// test/unit/models/x_axis_config_scale_test.dart
import 'package:braven_charts/braven_charts.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('XAxisConfig defaults to a linear scale, base 10', () {
    const c = XAxisConfig(label: 'x');
    expect(c.scaleType, AxisScaleType.linear);
    expect(c.logBase, 10);
  });
  test('scaleType/logBase survive copyWith and equality', () {
    const c = XAxisConfig(label: 'x');
    final log = c.copyWith(scaleType: AxisScaleType.log, logBase: 2);
    expect(log.scaleType, AxisScaleType.log);
    expect(log.logBase, 2);
    expect(log, isNot(c));
    expect(log, c.copyWith(scaleType: AxisScaleType.log, logBase: 2));
  });
}
```

- [ ] **Step 2: Run — expect FAIL** (`flutter test test/unit/models/x_axis_config_scale_test.dart`) — `AxisScaleType`/`scaleType` undefined.

- [ ] **Step 3: Create the enum**

```dart
// lib/src/models/axis_scale_type.dart
// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

/// How an axis maps data values to positions and generates ticks.
enum AxisScaleType {
  /// Values map linearly to positions (the default; unchanged behavior).
  linear,

  /// Values map on a log scale (base [XAxisConfig.logBase]); ticks are decades.
  log,

  /// Values are epoch-milliseconds; ticks land on calendar boundaries with
  /// date labels.
  time,
}
```
Add to the core barrel `lib/braven_charts.dart`: `export 'src/models/axis_scale_type.dart';` (alphabetical near the other `src/models/axis_*`/`x_axis` exports).

- [ ] **Step 4: Add the fields to XAxisConfig** (`lib/src/models/x_axis_config.dart`)

- Import the enum (`import 'axis_scale_type.dart';`).
- Constructor: add `this.scaleType = AxisScaleType.linear,` and `this.logBase = 10,` (place beside `tickCount`).
- Fields (mirror `labelDisplay` / `minorTickLength`):
```dart
  /// How this axis maps values to positions and generates ticks.
  final AxisScaleType scaleType;

  /// Base for [AxisScaleType.log]; ignored otherwise.
  final double logBase;
```
- `copyWith`: add params `AxisScaleType? scaleType,` + `double? logBase,`; body `scaleType: scaleType ?? this.scaleType,` and `logBase: logBase ?? this.logBase,` (no clear-flag — non-nullable defaulted, like `labelDisplay`).
- `==`: add `scaleType == other.scaleType && logBase == other.logBase &&`.
- `hashCode`: add `scaleType, logBase,` to the `Object.hashAll([...])`.
- `toString`: add both.

- [ ] **Step 5: Run — expect PASS.** Then `flutter analyze lib` → clean.

- [ ] **Step 6: Commit**

```bash
git add lib/src/models/axis_scale_type.dart lib/src/models/x_axis_config.dart lib/braven_charts.dart test/unit/models/x_axis_config_scale_test.dart
git commit -m "feat(axis): AxisScaleType enum + scaleType/logBase on XAxisConfig"
```

### Task 1.2: scaleType + logBase on YAxisConfig (all 4 construction sites)

**Files:** Modify `lib/src/models/y_axis_config.dart`; Test `test/unit/models/y_axis_config_scale_test.dart`.

**Interfaces — Produces:** `YAxisConfig.scaleType` / `.logBase` (same defaults), carried through the public ctor, `_internal`, `withId`, and `copyWith`.

- [ ] **Step 1: Write the failing test** — mirror Task 1.1's test for `YAxisConfig(position: YAxisPosition.left)`: default `linear`/`10`, and `copyWith(scaleType: AxisScaleType.log, logBase: 2)` round-trips + inequality. Add a case that `YAxisConfig.withId(id: 'y', position: YAxisPosition.left, scaleType: AxisScaleType.log).scaleType == AxisScaleType.log`.

- [ ] **Step 2: Run — expect FAIL.**

- [ ] **Step 3: Add the fields to ALL FOUR sites** (import `axis_scale_type.dart`):
  - **Public ctor** (~175): add `this.scaleType = AxisScaleType.linear,` + `this.logBase = 10,`.
  - **`_internal` const ctor** (~227): add both (same defaults).
  - **`withId` factory** (~261): add `AxisScaleType scaleType = AxisScaleType.linear,` + `double logBase = 10,` params and pass them to `YAxisConfig._internal(...)`.
  - **Fields** + **`copyWith`** (params + `?? this.` lines) + **`==`** + **`hashCode`** + **`toString`** — same as Task 1.1.

- [ ] **Step 4: Run — expect PASS.** `flutter analyze lib` clean.

- [ ] **Step 5: Commit**
```bash
git add lib/src/models/y_axis_config.dart test/unit/models/y_axis_config_scale_test.dart
git commit -m "feat(axis): scaleType/logBase on YAxisConfig (all four construction sites)"
```

### Task 1.3: Thread scaleType/logBase through the artifact codec (2 files)

**Files:** Modify `lib/src/artifacts/chart_document.dart` (`ChartAxisDocument`), `lib/src/artifacts/chart_axis_document_codec.dart`; Test `test/unit/artifacts/axis_scale_codec_test.dart`.

- [ ] **Step 1: Write the failing test** — encode a log `XAxisConfig` + a log `YAxisConfig`, decode, assert `scaleType`/`logBase` survive:
```dart
test('X axis scaleType/logBase round-trip through the codec', () {
  const codec = ChartAxisDocumentCodec();
  const axis = XAxisConfig(scaleType: AxisScaleType.log, logBase: 2);
  final back = codec.decodeXAxis(codec.encodeXAxis(axis));
  expect(back.scaleType, AxisScaleType.log);
  expect(back.logBase, 2);
});
// + the YAxis equivalent via encodeYAxis/decodeYAxis.
```
(Confirm the codec's public entry names via the file; if `encodeXAxis` is not public, drive it through the whole `ChartDocumentCodec` round-trip the existing codec tests use.)

- [ ] **Step 2: Run — expect FAIL** (fields dropped → `scaleType == linear`).

- [ ] **Step 3a: `ChartAxisDocument`** (`chart_document.dart`): add ctor params `this.scaleType = 'linear',` (String, enum-as-name) + `this.logBase = 10,` (double); fields `final String scaleType;` + `final double logBase;`; `toJson` omit-if-default `if (scaleType != 'linear') 'scaleType': scaleType,` + `if (logBase != 10) 'logBase': logBase,`; `fromJson` `scaleType: readOptionalString(json,'scaleType') ?? 'linear',` + `logBase: readOptionalDouble(json,'logBase') ?? 10,` (use the existing `readOptionalDouble` helper; grep it).

- [ ] **Step 3b: `ChartAxisDocumentCodec`** — in **all four** methods:
  - `encodeXAxis`/`encodeYAxis`: `scaleType: axis.scaleType.name,` + `logBase: axis.logBase,`.
  - `decodeXAxis`/`decodeYAxis`: `scaleType: _enum(document.scaleType, AxisScaleType.values),` + `logBase: document.logBase,` (import `axis_scale_type.dart`).

- [ ] **Step 4: Run — expect PASS.** `flutter analyze lib` clean.

- [ ] **Step 5: Commit**
```bash
git add lib/src/artifacts/chart_document.dart lib/src/artifacts/chart_axis_document_codec.dart test/unit/artifacts/axis_scale_codec_test.dart
git commit -m "feat(artifacts): codec round-trips axis scaleType/logBase"
```

### Task 1.4: Emit scaleType/logBase in the Config source emitter

**Files:** Modify `lib/src/source/chart_config_dart_emitter.dart` (`_emitAxisFields` ~3405 + `_emitYAxisFields` ~3346); Test `test/unit/source/axis_scale_emit_test.dart`.

- [ ] **Step 1: Write the failing test** — emit a chart whose X axis is `XAxisConfig(scaleType: AxisScaleType.log, logBase: 2)` and assert the generated source contains `scaleType: AxisScaleType.log` and `logBase: 2` (follow an existing emitter test's harness). Add the Y equivalent.

- [ ] **Step 2: Run — expect FAIL.**

- [ ] **Step 3: Add to BOTH helpers** (in `_emitAxisFields` and `_emitYAxisFields`):
```dart
    _enumIf(writer, 'scaleType', 'AxisScaleType', axis.scaleType.name,
        defaultName: 'linear');
    _numberIf(writer, 'logBase', axis.logBase, 10);
```

- [ ] **Step 4: Run — expect PASS.** `flutter analyze lib` clean.

- [ ] **Step 5: Commit**
```bash
git add lib/src/source/chart_config_dart_emitter.dart test/unit/source/axis_scale_emit_test.dart
git commit -m "feat(source): Config emitter names axis scaleType/logBase"
```

### Task 1.5: Regenerate the surface + prove all drift gates green

**Files:** Regenerated `lib/src/ai/generated/surface_definitions.dart`, the fluent barrel/extensions, the fluent smoke test (all by `build_runner`).

- [ ] **Step 1: Regenerate**
```bash
cd F:/Repositories/braven_charts-scales && dart run build_runner build --delete-conflicting-outputs
```
Expected: `surface_definitions.dart` gains `scaleType` (enum, default `linear`) + `logBase` (default 10) on `XAxisConfig`+`YAxisConfig`, and the fluent extensions gain `withScaleType`/`withLogBase`.

- [ ] **Step 2: Run the drift gates — expect all green**
```bash
flutter test test/meta/
```
Expected: `+51: All tests passed!` (surface_enforcement, codec_drift both-sided, source_emitter flat gate, ai_surface_definitions HARD GATE (a) `withScaleType`/`withLogBase`, ai_mirror unchanged). If codec_drift reports an encode/decode asymmetry, a codec side was missed (Task 1.3); if ai_surface_definitions fails the fluent-verb gate, the regen didn't run.

- [ ] **Step 3:** `flutter analyze lib` clean; `flutter test` (full) → report total, 0 failures, **zero golden drift** (nothing renders yet).

- [ ] **Step 4: Commit** (regenerated outputs are committed)
```bash
git add lib/src/ai/generated/surface_definitions.dart lib/braven_charts_fluent.dart <other regenerated files> test/fluent/
git commit -m "chore(surface): regenerate for axis scaleType/logBase; drift gates green"
```

---

# PHASE 2 — LOG RENDER (scale-aware positioning + decade ticks)

The deep phase. Every change is gated `scaleType == linear ? <original> : <log>`.

### Task 2.1: Pure log-decade tick generator

**Files:** Create `lib/src/axis/log_ticks.dart`; Test `test/unit/axis/log_ticks_test.dart`.

**Interfaces — Produces:**
```dart
/// Log helpers (base [base]) + decade tick values within a positive [min,max].
double logValue(double v, double base);          // math.log(v)/math.log(base)
double logInverse(double t, double base);         // pow(base, t)
List<double> decadeTicks(double min, double max, {double base = 10, int maxTicks = 12});
```

- [ ] **Step 1: Write the failing test**
```dart
test('decadeTicks over 1..1000 base 10 are the decades', () {
  expect(decadeTicks(1, 1000), [1, 10, 100, 1000]);
});
test('decadeTicks base 2 over 1..8 are 1,2,4,8', () {
  expect(decadeTicks(1, 8, base: 2), [1, 2, 4, 8]);
});
test('logValue/logInverse round-trip', () {
  expect(logInverse(logValue(50, 10), 10), closeTo(50, 1e-9));
});
```

- [ ] **Step 2: Run — expect FAIL.**

- [ ] **Step 3: Implement** (`dart:math`): `logValue = math.log(v)/math.log(base)`; `logInverse = math.pow(base, t).toDouble()`; `decadeTicks` = for exponent `e` from `logValue(min).floor()` to `logValue(max).ceil()`, push `pow(base,e)` when within `[min,max]`; if the count exceeds `maxTicks`, stride the exponents. (No sub-decade minors in v1 — YAGNI.)

- [ ] **Step 4: Run — expect PASS.** `flutter analyze lib` clean.

- [ ] **Step 5: Commit** — `git add lib/src/axis/log_ticks.dart test/unit/axis/log_ticks_test.dart` → `feat(axis): pure log-decade tick generator`.

### Task 2.2: Scale-aware ChartTransform (geometry + inverse)

**Files:** Modify `lib/src/coordinates/chart_transform.dart`; Test `test/unit/coordinates/chart_transform_log_test.dart`.

**Interfaces — Produces:** `ChartTransform.xScaleType` / `.yScaleType` (`AxisScaleType`, default `linear`), `.xLogBase` / `.yLogBase` (default 10); `dataToPlot`/`plotToData` honor them; `copyWith` carries them.

- [ ] **Step 1: Write the failing test**
```dart
test('a y-log transform positions the geometric midpoint at value = sqrt(min*max)', () {
  const t = ChartTransform(
    dataXMin: 0, dataXMax: 10, dataYMin: 1, dataYMax: 100,
    plotWidth: 100, plotHeight: 100, yScaleType: AxisScaleType.log);
  // value 10 is the log-midpoint of [1,100] → relativeY 0.5 → invertY → plotY 50.
  expect(t.dataToPlot(0, 10).dy, closeTo(50, 1e-6));
  // linear x is unchanged:
  expect(t.dataToPlot(5, 10).dx, closeTo(50, 1e-6));
});
test('plotToData inverts the y-log mapping', () {
  const t = ChartTransform(
    dataXMin: 0, dataXMax: 10, dataYMin: 1, dataYMax: 100,
    plotWidth: 100, plotHeight: 100, yScaleType: AxisScaleType.log);
  expect(t.plotToData(50, 50).dy, closeTo(10, 1e-6));
});
test('a linear transform is byte-identical (regression)', () {
  const t = ChartTransform(dataXMin: 0, dataXMax: 10, dataYMin: 0, dataYMax: 100,
      plotWidth: 100, plotHeight: 100);
  expect(t.dataToPlot(5, 50), const Offset(50, 50));
});
```

- [ ] **Step 2: Run — expect FAIL.**

- [ ] **Step 3: Implement** — add the four fields (ctor `:60`, `copyWith` `:417`, `==`/`hashCode` `:443`; keep the `dataXMax>dataXMin` asserts). Add a private helper and gate the fraction math:
```dart
double _relative(double v, double min, double max, AxisScaleType type, double base) {
  if (type == AxisScaleType.log) {
    final lo = logValue(min, base), hi = logValue(max, base);
    return hi == lo ? 0.5 : (logValue(v, base) - lo) / (hi - lo);
  }
  final range = max - min;             // linear — byte-identical to today
  return range == 0 ? 0.5 : (v - min) / range;
}
double _relativeInverse(double t, double min, double max, AxisScaleType type, double base) {
  if (type == AxisScaleType.log) {
    final lo = logValue(min, base), hi = logValue(max, base);
    return logInverse(lo + t * (hi - lo), base);
  }
  return min + t * (max - min);
}
```
In `dataToPlot` replace `relativeX = (dataX-dataXMin)/dataXRange` with `_relative(dataX, dataXMin, dataXMax, xScaleType, xLogBase)` and likewise `relativeY` (`yScaleType`, `yLogBase`) — **keep the rest of the method (transposed/invertY branches) verbatim**. In `plotToData`, keep the `relativeX/relativeY` pixel math, then replace `dataX = dataXMin + relativeX*dataXRange` with `_relativeInverse(relativeX, dataXMin, dataXMax, xScaleType, xLogBase)` and the Y equivalent. Import `../axis/log_ticks.dart`. (Note: `time` uses the linear arm here — epoch-millis positions linearly.) Leave `zoom`/`pan` for Task 2.5.

- [ ] **Step 4: Run — expect PASS.** `flutter analyze lib` clean. Run the full `chart_transform` test file to confirm no linear regression.

- [ ] **Step 5: Commit** — `feat(coords): scale-aware ChartTransform dataToPlot/plotToData (log; linear byte-identical)`.

### Task 2.3: Thread scaleType from axis config into the transform (3 sites)

**Files:** Modify `lib/src/rendering/chart_render_box.dart` (`:2708`, `:3928`, `:3096`); Test — a widget/golden test in Task 2.7 covers this end-to-end (this task has no isolated unit test; verify via analyze + the render smoke in 2.7). Note the axis config reaches these sites via `_xAxis`/`_yAxis` (`Axis` objects) — confirm `Axis` exposes the source `XAxisConfig`/`YAxisConfig` (grep `Axis.fromYAxisConfig`); if the `Axis` doesn't retain `scaleType`, add a `scaleType`/`logBase` passthrough on the internal `Axis`/`InternalAxisConfig` first.

- [ ] **Step 1: Primary construction (`:2708`)** — add to the `ChartTransform(...)`:
```dart
        xScaleType: _xAxis!.scaleType, xLogBase: _xAxis!.logBase,
        yScaleType: _yAxis!.scaleType, yLogBase: _yAxis!.logBase,
```
(read from whatever field on `Axis` carries the source config's scaleType — add it if missing).

- [ ] **Step 2: Per-series paint (`:3928`)** — the multi-axis `copyWith(dataYMin, dataYMax)` must also carry that axis's Y scale. Resolve the `YAxisConfig` for `axisId` (from the same map that yields `axisRange`, or a sibling map) and add `yScaleType: <cfg>.scaleType, yLogBase: <cfg>.logBase,`.

- [ ] **Step 3: Per-series hit-test (`:3096`)** — identical addition to the `copyWith` in `_ensureSeriesTransformsUpdated`.

- [ ] **Step 4:** `flutter analyze lib` clean; `flutter test` (full) — 0 failures, **zero golden drift** (all existing charts are linear → transform's linear arm → byte-identical).

- [ ] **Step 5: Commit** — `feat(render): thread per-axis scaleType into ChartTransform (primary + per-series paint/hit-test)`.

### Task 2.4: Log domain guards (min>0, log-space padding)

**Files:** Modify `lib/src/rendering/modules/multi_axis_manager.dart` (~808-815, ~683), `lib/src/utils/data_converter.dart` (~141); Test `test/unit/rendering/log_domain_test.dart`.

- [ ] **Step 1: Write the failing test** — for a log Y axis over data `[1, 1000]`, the computed padded domain must stay positive and NOT apply linear 5% padding that could push min ≤ 0 (assert `min > 0` and that min/max bracket the data). (Drive through `MultiAxisManager.computeAxisBounds` with a `YAxisConfig(scaleType: log)`.)

- [ ] **Step 2: Run — expect FAIL** (linear padding may drop min ≤ 0).

- [ ] **Step 3: Implement** — where `_paddedDataRange`/fallbacks apply (multi_axis_manager `:808-815`, `:683`; data_converter): gate on the axis `scaleType == log`. In the log arm, pad in log-space (`min = logInverse(logValue(min)-padFrac*logSpan)`, symmetric for max) and clamp `min` to a small positive floor when the data min ≤ 0 was only from a `0` fallback. Keep the linear arm verbatim.

- [ ] **Step 4: Run — expect PASS.** Full suite — zero golden drift.

- [ ] **Step 5: Commit** — `feat(render): log-space domain padding + positive floor for log axes`.

### Task 2.5: Log-aware zoom / pan

**Files:** Modify `lib/src/coordinates/chart_transform.dart` (`zoom` ~312, `pan` ~362); Test `test/unit/coordinates/chart_transform_log_interaction_test.dart`.

- [ ] **Step 1: Write the failing test** — zooming a y-log transform about a plot point keeps that point's data value fixed (a log-correct zoom); panning shifts by equal *log-space* steps. Assert the invariant (the data value under the zoom center is unchanged after `zoom`).

- [ ] **Step 2: Run — expect FAIL** (linear-space arithmetic distorts log zoom).

- [ ] **Step 3: Implement** — in `zoom`/`pan`, compute the new `dataYMin/dataYMax` in **log-space** when `yScaleType == log` (transform min/max via `logValue`, do the ratio/delta math there, invert via `logInverse`); same for X when `xScaleType == log`. Keep the linear arm verbatim (byte-identical).

- [ ] **Step 4: Run — expect PASS.** Full suite — zero golden drift.

- [ ] **Step 5: Commit** — `feat(coords): log-space zoom/pan for log axes`.

### Task 2.6: Log-decade axis ticks + labels (X and Y painters, in lockstep)

**Files:** Modify `lib/src/rendering/x_axis_painter.dart` (value gen ~469, pixel `ratio` ~353, `formatTickLabel` ~530), `lib/src/rendering/multi_axis_painter.dart` (value gen ~464, pixel via normalizer ~246, `formatTickLabel` ~506), `lib/src/rendering/multi_axis_normalizer.dart` (add a scale-aware overload), `lib/src/layout/multi_axis_layout.dart` (~172 width mirror); Test `test/unit/rendering/log_ticks_render_test.dart` + a golden in 2.7.

> **Lockstep rule:** the tick VALUES (decade), the tick PIXEL positions, and the mark positions must all use the same scale. Marks already do (Task 2.2). Here, gate each painter's value-gen on `scaleType == log ? decadeTicks(min,max,base:logBase) : <original nice-number>` and each tick-pixel `ratio`/`normalize` on the same `_relative(...)` log fraction as `ChartTransform` (extract a shared helper or replicate the formula exactly).

- [ ] **Step 1: Write the failing test** — for a log axis `[1,1000]`, `x_axis_painter` (and `multi_axis_painter`) produce tick values `[1,10,100,1000]` and their pixel positions equal the `ChartTransform` positions for those values (registration). Assert both.

- [ ] **Step 2: Run — expect FAIL.**

- [ ] **Step 3: Implement**
  - **X value gen (`x_axis_painter.generateTicks` ~469):** `if (config.scaleType == AxisScaleType.log) return decadeTicks(bounds.min, bounds.max, base: config.logBase);` else the original `_niceNum` loop verbatim. Also route `resolveTickValues`/`_candidateTickValues` (~74) so the log branch wins before the category/tickCount branches.
  - **X tick pixel (`~353`):** `final ratio = config.scaleType == AxisScaleType.log ? _logRatio(tickValue, axisBounds, config.logBase) : (axisBounds.span==0?0.0:(tickValue-axisBounds.min)/axisBounds.span);` where `_logRatio` mirrors `ChartTransform._relative`'s log arm exactly. Same at `:184` and `:399`.
  - **Y value gen (`multi_axis_painter` ~464) + pixel:** decade branch + a scale-aware `MultiAxisNormalizer.normalizeScaled(value, min, max, scaleType, base)` overload (keep the original `normalize` linear + its `range==0→0.5`/`isInfinite→0.0` edge cases verbatim for the linear arm).
  - **Labels (`formatTickLabel` X `~530` / Y `~506`, width `multi_axis_layout` `~172`):** BEFORE the numeric default, when `scaleType == log`, if no `labelFormatter` is set, format the decade plainly (the value itself, e.g. `1000`). Keep `categoryLabelFor`/`labelFormatter` precedence intact. Mirror the same label default in the width-measure path so log labels don't mis-size the Y strip.

- [ ] **Step 4: Run — expect PASS.** `flutter analyze lib` clean. Full suite — zero golden drift on linear.

- [ ] **Step 5: Commit** — `feat(render): log-decade axis ticks + labels registered with marks`.

### Task 2.7: Log render golden + linear-regression proof

**Files:** Test (golden) `test/golden/axis_scales/log_axis_golden_test.dart` (tolerant comparator from the start).

- [ ] **Step 1:** Pump a `BravenChartPlus` with a `YAxisConfig(scaleType: AxisScaleType.log)` over data spanning several decades (e.g. 1..1000); `matchesGoldenFile('goldens/log_y_axis.png')`. Generate with `--update-goldens`; visually confirm decade gridlines + a curve that straightens under log-Y.
- [ ] **Step 2:** Assert NO existing golden changed: run the full golden suite (`flutter test test/golden/`) — every pre-existing golden passes unmodified (linear byte-identical). If any linear golden moved, a scale branch leaked into the linear arm — fix before proceeding.
- [ ] **Step 3: Commit** — `test(golden): log axis render + linear-unchanged regression`.

---

# PHASE 3 — TIME RENDER (calendar-nice date ticks + labels)

Positions already work (epoch-millis is the linear arm of Task 2.2). Only tick spacing + labels are new. Time is an X concern (the DateTime axis is x); Y-time is allowed but uses the same generator if ever set.

### Task 3.1: Pure calendar-nice date tick generator + interval labels

**Files:** Create `lib/src/axis/time_ticks.dart`; Test `test/unit/axis/time_ticks_test.dart`.

**Interfaces — Produces:**
```dart
enum TimeTickInterval { second, minute, hour, day, week, month, quarter, year }
/// Ticks (epoch-millis) on real calendar boundaries within [minMillis,maxMillis].
List<double> dateTicks(double minMillis, double maxMillis, {int maxTicks = 8});
/// The interval chosen for a millis span (drives label format).
TimeTickInterval intervalFor(double minMillis, double maxMillis, {int maxTicks = 8});
/// Auto label for a tick given the chosen interval (year→'2026', month→'Feb 2026', day→'Feb 3', ...).
String dateLabel(double millis, TimeTickInterval interval);
```

- [ ] **Step 1: Write the failing test**
```dart
test('a ~3-year span ticks on year boundaries', () {
  final jan2024 = DateTime.utc(2024).millisecondsSinceEpoch.toDouble();
  final jan2027 = DateTime.utc(2027).millisecondsSinceEpoch.toDouble();
  final ticks = dateTicks(jan2024, jan2027);
  final years = ticks.map((m) =>
      DateTime.fromMillisecondsSinceEpoch(m.toInt(), isUtc: true).year);
  expect(years, containsAll([2024, 2025, 2026, 2027]));
  expect(intervalFor(jan2024, jan2027), TimeTickInterval.year);
});
test('labels format per interval', () {
  final m = DateTime.utc(2026, 2, 3).millisecondsSinceEpoch.toDouble();
  expect(dateLabel(m, TimeTickInterval.year), '2026');
  expect(dateLabel(m, TimeTickInterval.day), 'Feb 3');
});
```

- [ ] **Step 2: Run — expect FAIL.**

- [ ] **Step 3: Implement** — `intervalFor` picks the coarsest interval whose count over the span is ≤ maxTicks (span thresholds: >~2yr→year, >~2mo→month, >~2wk→week, >~2d→day, …). `dateTicks` walks real `DateTime` boundaries via calendar arithmetic (`DateTime.utc(year, month, ...)` incremented by the interval; NOT fixed-ms steps) and returns their millis. `dateLabel` maps interval→a hand-written format (no `intl` dependency: month names from a `const` list). Use UTC throughout (spec: UTC-epoch; display timezone deferred).

- [ ] **Step 4: Run — expect PASS.** `flutter analyze lib` clean.

- [ ] **Step 5: Commit** — `feat(axis): pure calendar-nice date tick generator + labels`.

### Task 3.2: Wire time ticks + labels into the painters

**Files:** Modify `lib/src/rendering/x_axis_painter.dart` (value gen + `formatTickLabel`), and the Y painters if Y-time is in scope (mirror); Test `test/unit/rendering/time_ticks_render_test.dart` + golden in 3.3.

- [ ] **Step 1: Write the failing test** — a time X axis over a multi-year millis span produces the `dateTicks` values and `formatTickLabel(tick)` returns `dateLabel(tick, intervalFor(min,max))` (when no `labelFormatter` override). Assert a tick's label is `'2026'` (year interval).

- [ ] **Step 2: Run — expect FAIL.**

- [ ] **Step 3: Implement** — in `x_axis_painter.generateTicks`: `if (config.scaleType == AxisScaleType.time) return dateTicks(bounds.min, bounds.max);` (before the linear branch; positions stay linear via Task 2.2). In `formatTickLabel` (~530): when `scaleType == time` and no `labelFormatter`, return `dateLabel(value, intervalFor(bounds.min, bounds.max))` — keep the `categoryLabelFor`→`labelFormatter` precedence so an explicit `labelFormatter` still wins. Cache `intervalFor` per paint if cheap; otherwise compute once.

- [ ] **Step 4: Run — expect PASS.** `flutter analyze lib` clean; full suite — zero golden drift.

- [ ] **Step 5: Commit** — `feat(render): calendar-nice ticks + auto date labels for time axes`.

### Task 3.3: Time render golden

**Files:** Test (golden) `test/golden/axis_scales/time_axis_golden_test.dart` (tolerant comparator).

- [ ] **Step 1:** Pump a line chart whose x is epoch-millis over ~3 years with `XAxisConfig(scaleType: AxisScaleType.time)`; golden `goldens/time_x_axis.png`; confirm year-boundary ticks with `2024/2025/2026/2027` labels. Assert no existing golden changed.
- [ ] **Step 2: Commit** — `test(golden): time axis render`.

---

# PHASE 4 — GRAMMAR WIRING (verbs + diagnostics + parity + showcase)

### Task 4.1: `.xLog()` / `.yLog({id, base})` verbs

**Files:** Modify `lib/src/grammar/chart_builder.dart`; Test `test/unit/grammar/scale_verbs_test.dart`.

**Design note (from extraction):** `_copy` is `??`-merge (can't clear) and `toSpec()` drops `.x(label:)` if `_xAxis` is already set. So store scale intent on **dedicated builder fields** `AxisScaleType _xScaleType`/`double _xLogBase` and a `Map<String,({AxisScaleType type,double base})> _yScales` (keyed by axis id / a sentinel for the default), and FOLD them into `toSpec()` — do NOT store a half-built `_xAxis`.

- [ ] **Step 1: Write the failing test**
```dart
test('.xLog() makes the synthesized x axis logarithmic, base 10', () {
  final lowered = BravenChart.of(rows).x(v).y(v).geomLine().xLog().toSpec().lower();
  expect(lowered.xAxis?.scaleType, AxisScaleType.log);
  expect(lowered.xAxis?.logBase, 10);
});
test('.yLog(base: 2) sets the default y axis log base 2 and keeps its label', () {
  final lowered = BravenChart.of(rows).x(v).y(v, label: 'P').geomLine().yLog(base: 2)
      .toSpec().lower();
  expect(lowered.yAxes.single.scaleType, AxisScaleType.log);
  expect(lowered.yAxes.single.logBase, 2);
  expect(lowered.yAxes.single.label, 'P');
});
```

- [ ] **Step 2: Run — expect FAIL.**

- [ ] **Step 3: Implement** — add the builder fields + `_copy` params; add:
```dart
BravenChart<T> xLog({double base = 10}) =>
    _copy(xScaleType: AxisScaleType.log, xLogBase: base);
BravenChart<T> yLog({String? id, double base = 10}) => _copy(
    yScales: {..._yScales, (id ?? _defaultYKey): (type: AxisScaleType.log, base: base)});
```
In `toSpec()`: when building/synthesizing the X axis, apply `_xScaleType`/`_xLogBase` (merge with any label or explicit `_xAxis` via `copyWith(scaleType:, logBase:)`); when resolving `yAxes` (or the synthesized default), apply the matching `_yScales` entry via `copyWith`. Ensure the label path still works (the extraction's flagged gotcha).

- [ ] **Step 4: Run — expect PASS.** `flutter analyze lib` clean.

- [ ] **Step 5: Commit** — `feat(grammar): xLog/yLog verbs set axis scaleType`.

### Task 4.2: `.xTime(DateTime accessor)` verb

**Files:** Modify `lib/src/grammar/chart_builder.dart`; Test `test/unit/grammar/x_time_test.dart`.

- [ ] **Step 1: Write the failing test**
```dart
test('.xTime wraps a DateTime field into epoch-millis x and a time axis', () {
  final d = DateTime.utc(2026, 1, 1);
  final rows = [Row(d)];
  final lowered = BravenChart.of(rows).xTime((r) => r.date).y((r) => 1).geomLine()
      .toSpec().lower();
  expect(lowered.xAxis?.scaleType, AxisScaleType.time);
  expect((lowered.series.single as LineChartSeries).points.single.x,
      d.millisecondsSinceEpoch.toDouble());
});
```

- [ ] **Step 2: Run — expect FAIL.**

- [ ] **Step 3: Implement**
```dart
BravenChart<T> xTime(FieldAccessor<T, DateTime> accessor, {String? label}) =>
    _copy(
      defaultX: (row) => accessor(row).millisecondsSinceEpoch,
      xLabel: label,
      xScaleType: AxisScaleType.time,
    );
```
(No lowering change — every family already does `mark.x(row).toDouble()`; the wrapped accessor returns `num` millis. `toSpec()` folds `_xScaleType == time` onto the synthesized X axis, as in Task 4.1.)

- [ ] **Step 4: Run — expect PASS.** `flutter analyze lib` clean.

- [ ] **Step 5: Commit** — `feat(grammar): xTime binds a DateTime field to a time axis`.

### Task 4.3: Diagnostics — nonPositiveLogValue + conflictingAxisMode

**Files:** Modify `lib/src/grammar/grammar_diagnostics.dart`, `lib/src/grammar/plot_lowering.dart`; Test `test/unit/grammar/scale_diagnostics_test.dart`.

- [ ] **Step 1: Write the failing test**
```dart
test('a log axis with a value <= 0 raises nonPositiveLogValue', () {
  expect(
    () => BravenChart.of([Row(0)]).x((r)=>r.v).y((r)=>r.v).geomLine().yLog()
        .toSpec().lower(),
    throwsGrammarCode(GrammarDiagnosticCode.nonPositiveLogValue));
});
test('time + category on the same x raises conflictingAxisMode', () {
  expect(
    () => BravenChart.of(rows)
        .xTime((r)=>r.date).y((r)=>1).geomLine()
        .xAxis(const XAxisConfig(categoryAxis: CategoryAxisConfig(categories: ['a'])))
        .toSpec().lower(),
    throwsGrammarCode(GrammarDiagnosticCode.conflictingAxisMode));
});
```
(Re-declare the local `throwsGrammarCode` matcher.)

- [ ] **Step 2: Run — expect FAIL.**

- [ ] **Step 3a: Diagnostics** — append two enum members + factories (mirror `invalidCandlestickRow` / `axisOptionOnRadialSpec`):
```dart
GrammarSpecException.nonPositiveLogValue(String markId, num value) => ...
  'The mark "$markId" feeds a log axis but produced the value $value. A log '
  'scale is undefined for values <= 0; filter or transform them first.';
GrammarSpecException.conflictingAxisMode(String detail) => ...
  'An axis set conflicting modes: $detail. A time or log scale cannot combine '
  'with a category axis on the same axis.';
```
- [ ] **Step 3b: `conflictingAxisMode` (structural)** — in the structural pass / right after `_resolveAxes` (`plot_lowering.dart:250`+): if an axis has `scaleType == time || log` AND (for X) `categoryAxis != null`, throw. Data-independent.
- [ ] **Step 3c: `nonPositiveLogValue` (data-dependent)** — in the materialization loop (below the `emptyData` guard, near `_xyPoints`/`:718`): for each mark whose bound X or Y axis is `scaleType == log`, if any positioned value ≤ 0, throw naming the mark + value. (Check the mark's x when the X axis is log, y when its Y axis is log.)

- [ ] **Step 4: Run — expect PASS.** `flutter analyze lib` clean.

- [ ] **Step 5: Commit** — `feat(grammar): nonPositiveLogValue + conflictingAxisMode diagnostics`.

### Task 4.4: Whole-config parity + showcase preset

**Files:** Test `test/unit/grammar/scale_parity_test.dart`; Modify `example/lib/showcase/pages/chart_grammar_page.dart` + `example/test/showcase/chart_grammar_scales_preset_test.dart`.

- [ ] **Step 1: Parity test** — `.yLog(base: 2)` lowers to `lowered.yAxes.single == YAxisConfig(position: left).copyWith(id:'axis-0', scaleType: log, logBase: 2, label: ...)` (whole-config `==` vs hand-built), and `.xTime(...)` lowers to the expected `XAxisConfig(scaleType: time, label:...)`. Run — implement any `toSpec` fold gaps until green.

- [ ] **Step 2: Showcase** — add a `_GrammarPreset.scales` preset (mirror the radial/channels presets): a log-Y chart via `.yLog()` and a time-X chart via `.xTime()`, each beside its hand-built `BravenChartPlus` equivalent (`YAxisConfig(scaleType: log)` / `XAxisConfig(scaleType: time)`). Smoke test the preset builds + renders. `flutter analyze example/lib` clean.

- [ ] **Step 3: Commit** — `feat(grammar,showcase): scale parity tests + Log/Time showcase preset`.

### Task 4.5: Full gate

- [ ] **Step 1:** `flutter analyze lib` + `flutter analyze example/lib` clean; `flutter test` (full) — report total, 0 failures, **drift gates 51/51**, **zero golden drift on every pre-existing golden** (only the new `log_y_axis`/`time_x_axis` goldens are added). If any pre-existing golden changed, the linear path was perturbed — bisect the offending phase-2/3 branch.
- [ ] **Step 2: Commit** any final touch-ups.

---

## Self-Review

**1. Spec coverage:** AxisScaleType + logBase on both configs (T1.1/1.2) → 4 drift gates (T1.3/1.4/1.5). Log transform + inverse (T2.2), threading (T2.3), domain guards (T2.4), zoom/pan (T2.5), decade ticks+labels (T2.6), golden (T2.7). Time ticks+labels (T3.1/3.2), golden (T3.3). Grammar `.xLog`/`.yLog`/`.xTime` (T4.1/4.2), diagnostics `nonPositiveLogValue`/`conflictingAxisMode` (T4.3), parity + showcase (T4.4). Linear-byte-identical asserted (T2.7 step 2, T4.5). ✓ All spec sections mapped.

**2. Placeholder scan:** No TBD/TODO. Every code step shows code or an exact edit against a quoted site. Two steps ("thread scaleType from `Axis`", T2.3; "resolve `YAxisConfig` for axisId", T2.3 step 2) depend on a grep the executor must do first — each names the exact site and the exact addition, and flags the fallback (add a passthrough on the internal `Axis` if it doesn't retain scaleType). Acceptable (a located, bounded discovery, not a vague instruction).

**3. Type consistency:** `AxisScaleType`, `scaleType`, `logBase` identical across config/codec/emitter/transform/grammar. `logValue`/`logInverse`/`decadeTicks` (T2.1) consumed by T2.2/T2.6 with matching signatures. `dateTicks`/`intervalFor`/`dateLabel`/`TimeTickInterval` (T3.1) consumed by T3.2. `ChartTransform.xScaleType/yScaleType/xLogBase/yLogBase` (T2.2) consumed at the 3 threading sites (T2.3). Grammar builder fields `_xScaleType`/`_xLogBase`/`_yScales` (T4.1) consumed by `toSpec()` and `.xTime` (T4.2).

**Load-bearing risk (call out for the executor):** the LINEAR arm of every branch (T2.2 `_relative`, T2.6 painters, T2.4 padding, T2.5 zoom/pan, `MultiAxisNormalizer.normalize`) MUST be the original expression verbatim — the four duplicated nice-number routines and the `range==0→0.5`/`isInfinite→0.0` edge cases are intentionally different and must not be unified. T2.7 step 2 and T4.5 are the regression proof.
