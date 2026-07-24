# Grammar Scale-Driven Channels (non-scatter families) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Bind a data field to colour on `geomBar`/`geomLine`/`geomArea` and to width on `geomBar`, reusing scatter's encoding types, resolved (baked) at lowering into the per-element style slots the renderer already paints — plus a colour-ramp legend — with zero render-pipeline changes.

**Architecture:** The non-scatter families have no per-element encoding field, so the lowering computes the channel's finite domain over `spec.data`, resolves each element's colour via the reused `ScatterColorEncoding.colorFor(...)` (and bar width via a linear map into a `ScatterSizeEncoding`'s radius range, reinterpreted as a width multiplier), and writes the explicit value into `pointStyle.color`/`pointStyle.size` (bar) or `segmentStyle.color` (line/area edge). A `LegendAnnotation` carrying a `LegendColorScale` is appended to the lowered `annotations`, mirroring `braven_chart_plus._buildAutomaticColorLegends`.

**Tech Stack:** Dart ≥3.9 / Flutter ≥3.35; the grammar layer under `lib/src/grammar/`; existing config families (`BarChartSeries`/`LineChartSeries`/`AreaChartSeries`) and encodings (`ScatterColorEncoding`/`ScatterSizeEncoding`) reused unchanged.

## Global Constraints

- Work only in the worktree `F:\Repositories\braven_charts-channels` on branch `feature/grammar-scale-driven-channels`; commit there. Use specific `git add <paths>`, never `git add -A`.
- Analyze with `flutter analyze lib` (vendored-safe; the root analyze is polluted by `packages/fleather`). Run `flutter analyze example/lib` for the showcase task.
- Every golden test uses the repo's `_TolerantGoldenFileComparator` from the start (cross-platform AA tolerance 0.025–0.035), copied from an existing golden suite (e.g. `test/golden/grammar_faceting/`).
- Marks hold functions/config → **no `copyWith`, no `@chartSurface`, no drift gate**. Reused encodings are unchanged, so **no drift gate is touched**. No new `GrammarDiagnosticCode`.
- Commit messages end with: `Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>`.
- Do NOT modify any file under `lib/src/rendering/` or `lib/src/elements/` — this slice is grammar-only.

## Verified code facts (current, post-radial master)

- Scatter builder verb is **`geomPoint`** (`chart_builder.dart:316`), not `geomScatter`.
- `ScatterColorEncoding.colorFor(double? value, {required double resolvedMinimumValue, required double resolvedMaximumValue}) → Color?` (`scatter_marker_style.dart:253`). Named params. Returns null for null/non-finite/empty-colours.
- `ScatterColorEncoding` ctor: `{required List<Color> colors, ScatterColorScaleType scaleType = continuous, List<double> thresholds = const [], List<String> bandLabels = const [], double? minimumValue, double? maximumValue, String label = 'Color value', String? unit, bool showLegend = true}`. Getters: `hasValidPiecewiseConfiguration`, `effectiveBandLabels`, `format(double) → String`.
- `ScatterSizeEncoding` ctor: `{double minimumRadius = 4, double maximumRadius = 24, double minimumValue = 0, double? maximumValue, String label = 'Magnitude', String? unit, bool showLegend = true}` (`scatter_marker_style.dart:510`).
- `ChartDataPoint({required double x, required double y, ..., SegmentStyle? segmentStyle, PointStyle? pointStyle})` (`chart_data_point.dart:46`).
- `SegmentStyle.color(Color)` named ctor; `PointStyle({Color? color, double? size, ...})` — **no opacity field** (`segment_style.dart:56, 187`).
- `LegendColorScale({required String label, required List<Color> colors, required String minimumLabel, required String maximumLabel, String? midpointLabel, LegendColorScaleType type = continuous, List<String> segmentLabels = const []})` and `LegendAnnotation({String? id, LegendColorScale? colorScale, LegendStyle legendStyle = const LegendStyle(), ...})` (`chart_annotation.dart:2092, 2286`). `LegendColorScaleType { continuous, piecewise }`.
- Grammar structural/validation pass: `plot_lowering.dart:249-286` (per-mark switch; `_validateScatterChannels` called at :263 in the `ScatterMark` arm; `LineMark||AreaMark||BarMark||CandlestickMark` share an arm at :264 that only binds an axis).
- Grammar materialization loop: `plot_lowering.dart:300-336` (per-mark switch; `series.add(_lowerLine/_lowerArea/_lowerBar(...))`), returning `LoweredPlot(series: series, annotations: annotations, ...)` at :338. `annotations` is a `<ChartAnnotation>[]` accumulator (:301).
- `_xyPoints` (`:496`), `_lowerLine` (`:505`), `_lowerArea` (`:525`), `_lowerBar` (`:547`), `_validateScatterChannels` (`:378`), `_requireScale` (`:973`), `_relabelColor` (`:1007`).
- Colour legends today are synthesized at RENDER time, scatter-only (`braven_chart_plus.dart:3712 _buildAutomaticColorLegends`); it skips non-scatter series, so a grammar-emitted `LegendAnnotation` for bar/line/area never double-counts.
- Imports already in `plot_lowering.dart`: `channel.dart`, `chart_annotation.dart`, `chart_data_point.dart`, `chart_series.dart`, `scatter_marker_style.dart`, `mark.dart`. **Must ADD** `import '../models/segment_style.dart';` (for `SegmentStyle`/`PointStyle`).

## File Structure

- **Modify** `lib/src/grammar/mark.dart` — add channel fields to `LineMark`/`AreaMark`/`BarMark` (Task 1/2/3 colour; Task 4 bar size). Additive constructor params + fields + `==`/`hashCode`.
- **Modify** `lib/src/grammar/chart_builder.dart` — add channel params to `geomLine`/`geomArea`/`geomBar`.
- **Modify** `lib/src/grammar/plot_lowering.dart` — add the `segment_style.dart` import; the shared helpers (`_finiteDomain`, `_bakeChannelColors`, `_channelColorLegend`, `_addColorLegend`, `_validateColorChannel`; Task 4 adds `_bakeChannelWidths`, `_validateBarSizeChannel`, `_barSizeMultiplierDefault`); the point-builders (`_xyColorPoints`, `_barStyledPoints`); rewire `_lowerLine`/`_lowerArea`/`_lowerBar`; add validation calls to the structural pass; append the legend in the materialization loop.
- **Create** tests under `test/unit/grammar/` and goldens under `test/golden/grammar_channels_*/`.
- **Modify** `example/lib/showcase/pages/chart_grammar_page.dart` — a scale-driven-channels preset (Task 5).

---

### Task 1: geomBar colour + shared colour-baking & legend infrastructure

The foundational slice: adds the colour channel to bar (per-bar fill via `pointStyle.color`) and establishes the shared helpers Tasks 2–4 reuse.

**Files:**
- Modify: `lib/src/grammar/mark.dart` (`BarMark` — add `colorBy`/`colorEncoding`)
- Modify: `lib/src/grammar/chart_builder.dart` (`geomBar` — add `colorBy`/`colorEncoding`)
- Modify: `lib/src/grammar/plot_lowering.dart` (helpers + `_lowerBar` + validation + legend)
- Test: `test/unit/grammar/channel_bar_color_test.dart`
- Test (golden): `test/golden/grammar_channels_bar/grammar_channels_bar_golden_test.dart`

**Interfaces:**
- Consumes: `Channel<T>` (`channel.dart`), `ScatterColorEncoding.colorFor` / `.format` / `.effectiveBandLabels` / `.hasValidPiecewiseConfiguration` (`scatter_marker_style.dart`), `LegendAnnotation`/`LegendColorScale` (`chart_annotation.dart`), `PointStyle` (`segment_style.dart`), `GrammarSpecException.missingChannelEncoding`/`.orphanChannelEncoding`/`.unsupportedChannelScale`, `_requireScale`.
- Produces (reused by Tasks 2–4):
  - `({double min, double max})? _finiteDomain<T>(FieldAccessor<T, num> accessor, List<T> data)`
  - `List<Color?> _bakeChannelColors<T>(Channel<T> colorBy, ScatterColorEncoding encoding, List<T> data)`
  - `LegendAnnotation? _channelColorLegend<T>(Channel<T> colorBy, ScatterColorEncoding encoding, List<T> data)`
  - `void _addColorLegend<T>(List<ChartAnnotation> annotations, Channel<T>? colorBy, ScatterColorEncoding? colorEncoding, List<T> data)`
  - `void _validateColorChannel<T>(Channel<T>? colorBy, ScatterColorEncoding? colorEncoding, String markId)`
  - `List<ChartDataPoint> _barStyledPoints<T>(List<T> data, FieldAccessor<T,num> x, FieldAccessor<T,num> y, Channel<T>? colorBy, ScatterColorEncoding? colorEncoding, Channel<T>? sizeBy, ScatterSizeEncoding? sizeEncoding)` (Task 1 passes `sizeBy: null, sizeEncoding: null`; Task 4 wires the size args).
  - `BarMark<T>` fields `colorBy`/`colorEncoding` (Task 4 adds `sizeBy`/`sizeEncoding`).

- [ ] **Step 1: Write the failing test**

`test/unit/grammar/channel_bar_color_test.dart`:

```dart
// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

/// geomBar colour channel: value -> ramp -> per-bar pointStyle.color, + legend.
library;

import 'dart:ui';

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter_test/flutter_test.dart';

class Bar {
  const Bar(this.cat, this.value, this.heat);
  final double cat;
  final double value;
  final double heat;
}

double barCat(Bar r) => r.cat;
double barValue(Bar r) => r.value;
double barHeat(Bar r) => r.heat;

const rows = <Bar>[
  Bar(0, 10, 0), // heat min
  Bar(1, 20, 5),
  Bar(2, 15, 10), // heat max
];

const ramp = ScatterColorEncoding(
  colors: <Color>[Color(0xFF0000FF), Color(0xFFFF0000)],
  label: 'Heat',
);

Matcher throwsGrammarCode(GrammarDiagnosticCode code) =>
    throwsA(isA<GrammarSpecException>().having((e) => e.code, 'code', code));

void main() {
  test('each bar gets pointStyle.color = colorFor(heat) over the domain', () {
    final lowered = BravenChart.of(rows)
        .x(barCat)
        .y(barValue)
        .geomBar(colorBy: Channel(barHeat), colorEncoding: ramp)
        .toSpec().lower();

    final bar = lowered.series.single as BarChartSeries;
    for (var i = 0; i < rows.length; i++) {
      final expected = ramp.colorFor(
        rows[i].heat,
        resolvedMinimumValue: 0,
        resolvedMaximumValue: 10,
      );
      expect(bar.points[i].pointStyle?.color, expected,
          reason: 'bar $i colour');
    }
  });

  test('a colour channel emits a colour-ramp legend annotation', () {
    final lowered = BravenChart.of(rows)
        .x(barCat)
        .y(barValue)
        .geomBar(colorBy: Channel(barHeat, label: 'Heat'), colorEncoding: ramp)
        .toSpec().lower();

    final legend = lowered.annotations
        .whereType<LegendAnnotation>()
        .singleWhere((a) => a.colorScale != null);
    expect(legend.colorScale!.label, 'Heat');
    expect(legend.colorScale!.colors, ramp.colors);
    expect(legend.colorScale!.minimumLabel, '0');
    expect(legend.colorScale!.maximumLabel, '10');
  });

  test('colorBy without colorEncoding raises missingChannelEncoding', () {
    expect(
      () => BravenChart.of(rows)
          .x(barCat)
          .y(barValue)
          .geomBar(colorBy: Channel(barHeat))
          .toSpec().lower(),
      throwsGrammarCode(GrammarDiagnosticCode.missingChannelEncoding),
    );
  });

  test('colorEncoding without colorBy raises orphanChannelEncoding', () {
    expect(
      () => BravenChart.of(rows)
          .x(barCat)
          .y(barValue)
          .geomBar(colorEncoding: ramp)
          .toSpec().lower(),
      throwsGrammarCode(GrammarDiagnosticCode.orphanChannelEncoding),
    );
  });

  test('a non-native colour scale raises unsupportedChannelScale', () {
    expect(
      () => BravenChart.of(rows)
          .x(barCat)
          .y(barValue)
          .geomBar(
            colorBy: Channel(barHeat, scale: ChannelScale.sqrt),
            colorEncoding: ramp,
          )
          .toSpec().lower(),
      throwsGrammarCode(GrammarDiagnosticCode.unsupportedChannelScale),
    );
  });

  test('a non-finite channel value leaves that bar without a baked colour', () {
    const withNaN = <Bar>[Bar(0, 10, 0), Bar(1, 20, double.nan)];
    final lowered = BravenChart.of(withNaN)
        .x(barCat)
        .y(barValue)
        .geomBar(colorBy: Channel(barHeat), colorEncoding: ramp)
        .toSpec().lower();
    final bar = lowered.series.single as BarChartSeries;
    expect(bar.points[1].pointStyle?.color, isNull);
  });
}
```

> Note: the tests call `.toSpec().lower()` — verified as the idiom the existing grammar tests use (`chart_builder.dart:623 toSpec()` returns a `PlotSpec<T>`; `plot_lowering_*_test.dart` then calls `spec.lower()`). `lower()` returns a `LoweredPlot` with `.series` and `.annotations`.

- [ ] **Step 2: Run the test to verify it fails**

Run: `flutter test test/unit/grammar/channel_bar_color_test.dart`
Expected: FAIL — `geomBar` has no `colorBy`/`colorEncoding` params (compile error).

- [ ] **Step 3: Add the `BarMark` colour fields**

In `lib/src/grammar/mark.dart`, `BarMark<T>` (lines 237–325): add to the constructor (after `super.yAxisId,`): `this.colorBy,` and `this.colorEncoding,`. Add fields after `final FieldAccessor<T, num> y;`:

```dart
  /// Optional colour channel: each bar's fill is the ramp colour of this
  /// field's value over the data's finite domain, baked at lowering into
  /// `ChartDataPoint.pointStyle.color`. Requires [colorEncoding].
  final Channel<T>? colorBy;

  /// Colour ramp for [colorBy] (reused from scatter). Required when [colorBy]
  /// is set; inert otherwise (raises `orphanChannelEncoding`).
  final ScatterColorEncoding? colorEncoding;
```

Add both to `==` (e.g. `&& other.colorBy == colorBy && other.colorEncoding == colorEncoding`) and to `hashCode` (add `colorBy, colorEncoding` to the `Object.hash(...)` arg list).

- [ ] **Step 4: Add the `geomBar` params**

In `lib/src/grammar/chart_builder.dart`, `geomBar` (lines 278–308): add params `Channel<T>? colorBy,` and `ScatterColorEncoding? colorEncoding,` to the signature, and pass `colorBy: colorBy, colorEncoding: colorEncoding,` into the `BarMark<T>(...)`.

- [ ] **Step 5: Add the shared helpers + validation + legend + bar baking to `plot_lowering.dart`**

Add `import '../models/segment_style.dart';` in the import block (alphabetical, after `scatter_marker_style.dart` is fine — keep directives sorted).

Add the shared helpers (place them near `_relabelColor`, ~line 1007):

```dart
/// The finite [min, max] of [accessor] over [data], or null when nothing is
/// finite (in which case the channel bakes no colours and emits no legend).
({double min, double max})? _finiteDomain<T>(
  FieldAccessor<T, num> accessor,
  List<T> data,
) {
  double? lo;
  double? hi;
  for (final row in data) {
    final v = accessor(row).toDouble();
    if (!v.isFinite) continue;
    if (lo == null || v < lo) lo = v;
    if (hi == null || v > hi) hi = v;
  }
  return lo == null || hi == null ? null : (min: lo, max: hi);
}

/// Per-row baked colour for [colorBy] under [encoding]. Null where the value
/// is non-finite or the domain is empty, so that element keeps its base colour.
List<Color?> _bakeChannelColors<T>(
  Channel<T> colorBy,
  ScatterColorEncoding encoding,
  List<T> data,
) {
  final domain = _finiteDomain(colorBy.accessor, data);
  return <Color?>[
    for (final row in data)
      domain == null
          ? null
          : encoding.colorFor(
              colorBy.accessor(row).toDouble(),
              resolvedMinimumValue: domain.min,
              resolvedMaximumValue: domain.max,
            ),
  ];
}

/// A colour-ramp legend for a baked colour channel, mirroring
/// `BravenChartPlus._buildAutomaticColorLegends` (which is scatter-only, so a
/// baked non-scatter colour would otherwise carry no legend). Null when the
/// encoding hides its legend, is an invalid piecewise config, or has no finite
/// domain.
LegendAnnotation? _channelColorLegend<T>(
  Channel<T> colorBy,
  ScatterColorEncoding encoding,
  List<T> data,
) {
  if (!encoding.showLegend) return null;
  if (!encoding.hasValidPiecewiseConfiguration) return null;
  var minimum = encoding.minimumValue ?? double.infinity;
  var maximum = encoding.maximumValue ?? double.negativeInfinity;
  for (final row in data) {
    final value = colorBy.accessor(row).toDouble();
    if (!value.isFinite) continue;
    if (encoding.minimumValue == null && value < minimum) minimum = value;
    if (encoding.maximumValue == null && value > maximum) maximum = value;
  }
  if (!minimum.isFinite && maximum.isFinite) minimum = maximum;
  if (!maximum.isFinite && minimum.isFinite) maximum = minimum;
  if (!minimum.isFinite || !maximum.isFinite) return null;
  final midpoint = (minimum + maximum) / 2;
  return LegendAnnotation(
    colorScale: LegendColorScale(
      label: colorBy.label ?? encoding.label,
      colors: encoding.colors,
      type: encoding.scaleType == ScatterColorScaleType.piecewise
          ? LegendColorScaleType.piecewise
          : LegendColorScaleType.continuous,
      segmentLabels: encoding.scaleType == ScatterColorScaleType.piecewise
          ? encoding.effectiveBandLabels
          : const <String>[],
      minimumLabel: encoding.format(minimum),
      midpointLabel: minimum == maximum ? null : encoding.format(midpoint),
      maximumLabel: encoding.format(maximum),
    ),
  );
}

/// Appends a colour-ramp legend for [colorBy]/[colorEncoding] if present.
void _addColorLegend<T>(
  List<ChartAnnotation> annotations,
  Channel<T>? colorBy,
  ScatterColorEncoding? colorEncoding,
  List<T> data,
) {
  if (colorBy == null || colorEncoding == null) return;
  final legend = _channelColorLegend(colorBy, colorEncoding, data);
  if (legend != null) annotations.add(legend);
}

/// Structural validation of a non-scatter colour channel: symmetric
/// missing/orphan-encoding checks and the native-scale check (colour is linear).
void _validateColorChannel<T>(
  Channel<T>? colorBy,
  ScatterColorEncoding? colorEncoding,
  String markId,
) {
  _requireScale(markId, 'colorBy', colorBy?.scale, ChannelScale.linear);
  if (colorBy != null && colorEncoding == null) {
    throw GrammarSpecException.missingChannelEncoding(
      markId,
      'colorBy',
      'Supply colorEncoding: ScatterColorEncoding(colors: [...]). The package '
          'ships no default color ramp.',
    );
  }
  if (colorBy == null && colorEncoding != null) {
    throw GrammarSpecException.orphanChannelEncoding(
      markId,
      'colorEncoding',
      'colorBy',
    );
  }
}

/// Builds bar points, weaving a baked colour (and, in Task 4, width) into
/// `pointStyle`. A point whose channels produce nothing keeps a null pointStyle.
List<ChartDataPoint> _barStyledPoints<T>(
  List<T> data,
  FieldAccessor<T, num> x,
  FieldAccessor<T, num> y,
  Channel<T>? colorBy,
  ScatterColorEncoding? colorEncoding,
  Channel<T>? sizeBy,
  ScatterSizeEncoding? sizeEncoding,
) {
  final colors = colorBy == null
      ? null
      : _bakeChannelColors(colorBy, colorEncoding!, data);
  final widths = sizeBy == null
      ? null
      : _bakeChannelWidths(sizeBy, sizeEncoding ?? _barSizeMultiplierDefault, data);
  return <ChartDataPoint>[
    for (var i = 0; i < data.length; i++)
      ChartDataPoint(
        x: x(data[i]).toDouble(),
        y: y(data[i]).toDouble(),
        pointStyle: (colors?[i] == null && widths?[i] == null)
            ? null
            : PointStyle(color: colors?[i], size: widths?[i]),
      ),
  ];
}
```

> Task 1 does not define `_bakeChannelWidths` or `_barSizeMultiplierDefault` yet — they arrive in Task 4. To keep Task 1 compiling on its own, **in Task 1 write `_barStyledPoints` with only the colour path** (drop the `widths`/`sizeBy`/`sizeEncoding` lines and the `size:` arg), then Task 4 replaces it with the full version above. Concretely, the Task-1 body is:
> ```dart
> List<ChartDataPoint> _barStyledPoints<T>(
>   List<T> data,
>   FieldAccessor<T, num> x,
>   FieldAccessor<T, num> y,
>   Channel<T>? colorBy,
>   ScatterColorEncoding? colorEncoding,
> ) {
>   final colors = colorBy == null
>       ? null
>       : _bakeChannelColors(colorBy, colorEncoding!, data);
>   return <ChartDataPoint>[
>     for (var i = 0; i < data.length; i++)
>       ChartDataPoint(
>         x: x(data[i]).toDouble(),
>         y: y(data[i]).toDouble(),
>         pointStyle: colors?[i] == null ? null : PointStyle(color: colors![i]),
>       ),
>   ];
> }
> ```
> Task 4 widens this signature and body (and updates the `_lowerBar` call site).

Rewire `_lowerBar` (lines 547–577): replace `points: _xyPoints(data, mark.x, mark.y),` with:

```dart
    points: mark.colorBy == null
        ? _xyPoints(data, mark.x, mark.y)
        : _barStyledPoints(data, mark.x, mark.y, mark.colorBy, mark.colorEncoding),
```

In the **structural pass** (lines 264–274), split the `BarMark` out of the shared `LineMark||AreaMark||BarMark||CandlestickMark` arm so it validates its colour channel after binding:

```dart
      case LineMark<T>() || AreaMark<T>() || CandlestickMark<T>():
        boundAxes[index] = _bindAxis(mark, markId, axes, axesById, boundAxisIds);
      case BarMark<T>():
        boundAxes[index] = _bindAxis(mark, markId, axes, axesById, boundAxisIds);
        _validateColorChannel(mark.colorBy, mark.colorEncoding, markId);
```

In the **materialization loop** (lines 300–336), the `BarMark` arm appends the legend after the series:

```dart
      case BarMark<T>():
        series.add(_lowerBar(mark, markId, axis!, spec.data, transposed: spec.transposed));
        _addColorLegend(annotations, mark.colorBy, mark.colorEncoding, spec.data);
```

- [ ] **Step 6: Run the unit test to verify it passes**

Run: `flutter test test/unit/grammar/channel_bar_color_test.dart`
Expected: PASS (all 6 tests). Then `flutter analyze lib` → No issues found.

- [ ] **Step 7: Write the golden test (tolerant comparator from the start)**

`test/golden/grammar_channels_bar/grammar_channels_bar_golden_test.dart`: copy the `_TolerantGoldenFileComparator` setup from `test/golden/grammar_faceting/grammar_faceting_golden_test.dart` (the `import 'dart:typed_data';`, `const _pixelTolerance = 0.035;`, `setUp`/`tearDown` swapping the comparator, and the comparator class). Pump a `BravenPlot` built from `BravenChart.of(rows).x(barCat).y(barValue).geomBar(colorBy: Channel(barHeat, label: 'Heat'), colorEncoding: ramp)` and `matchesGoldenFile('goldens/bar_color.png')`. Use the same `rows`/`ramp` fixtures as the unit test.

- [ ] **Step 8: Generate + verify the golden**

Run: `flutter test --update-goldens test/golden/grammar_channels_bar/` then `flutter test test/golden/grammar_channels_bar/`
Expected: PASS. Visually confirm `goldens/bar_color.png` shows a blue→red bar gradient across the three bars.

- [ ] **Step 9: Commit**

```bash
git add lib/src/grammar/mark.dart lib/src/grammar/chart_builder.dart lib/src/grammar/plot_lowering.dart test/unit/grammar/channel_bar_color_test.dart test/golden/grammar_channels_bar/
git commit -m "feat(grammar): geomBar colour channel bakes per-bar pointStyle.color + legend"
```

---

### Task 2: geomLine colour (per-segment)

Colour a line by a value: the outgoing segment from point *i* takes point *i*'s channel value → `segmentStyle.color` (leading-point rule). Reuses Task 1's helpers.

**Files:**
- Modify: `lib/src/grammar/mark.dart` (`LineMark` — add `colorBy`/`colorEncoding`)
- Modify: `lib/src/grammar/chart_builder.dart` (`geomLine`)
- Modify: `lib/src/grammar/plot_lowering.dart` (`_xyColorPoints` + `_lowerLine` + structural pass + materialization legend)
- Test: `test/unit/grammar/channel_line_color_test.dart`
- Test (golden): `test/golden/grammar_channels_line/grammar_channels_line_golden_test.dart`

**Interfaces:**
- Consumes: Task 1's `_bakeChannelColors`, `_addColorLegend`, `_validateColorChannel`.
- Produces: `List<ChartDataPoint> _xyColorPoints<T>(List<T> data, FieldAccessor<T,num> x, FieldAccessor<T,num> y, Channel<T> colorBy, ScatterColorEncoding encoding)` (reused by Task 3).

- [ ] **Step 1: Write the failing test**

`test/unit/grammar/channel_line_color_test.dart`:

```dart
// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

/// geomLine colour channel: value -> ramp -> per-segment segmentStyle.color.
library;

import 'dart:ui';

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter_test/flutter_test.dart';

class P {
  const P(this.t, this.v, this.pace);
  final double t;
  final double v;
  final double pace;
}

double pt(P r) => r.t;
double pv(P r) => r.v;
double ppace(P r) => r.pace;

const rows = <P>[P(0, 5, 0), P(1, 7, 5), P(2, 6, 10)];
const ramp = ScatterColorEncoding(
  colors: <Color>[Color(0xFF00FF00), Color(0xFFFF0000)],
);

void main() {
  test('each point gets segmentStyle.color = colorFor(pace) (leading rule)', () {
    final lowered = BravenChart.of(rows)
        .x(pt)
        .y(pv)
        .geomLine(colorBy: Channel(ppace), colorEncoding: ramp)
        .toSpec().lower();

    final line = lowered.series.single as LineChartSeries;
    for (var i = 0; i < rows.length; i++) {
      final expected = ramp.colorFor(
        rows[i].pace,
        resolvedMinimumValue: 0,
        resolvedMaximumValue: 10,
      );
      expect(line.points[i].segmentStyle?.color, expected,
          reason: 'segment leaving point $i');
    }
  });

  test('a line colour channel also emits a colour legend', () {
    final lowered = BravenChart.of(rows)
        .x(pt)
        .y(pv)
        .geomLine(colorBy: Channel(ppace, label: 'Pace'), colorEncoding: ramp)
        .toSpec().lower();
    final legend = lowered.annotations
        .whereType<LegendAnnotation>()
        .singleWhere((a) => a.colorScale != null);
    expect(legend.colorScale!.label, 'Pace');
  });

  test('colorBy without colorEncoding raises missingChannelEncoding', () {
    expect(
      () => BravenChart.of(rows)
          .x(pt)
          .y(pv)
          .geomLine(colorBy: Channel(ppace))
          .toSpec().lower(),
      throwsA(isA<GrammarSpecException>().having(
          (e) => e.code, 'code', GrammarDiagnosticCode.missingChannelEncoding)),
    );
  });
}
```

- [ ] **Step 2: Run to verify it fails**

Run: `flutter test test/unit/grammar/channel_line_color_test.dart`
Expected: FAIL — `geomLine` has no `colorBy` param.

- [ ] **Step 3: Add `LineMark` colour fields**

In `mark.dart`, `LineMark<T>` (72–144): add `this.colorBy,`/`this.colorEncoding,` to the ctor, the two fields (same dartdoc pattern as Task 1's `BarMark`, but "each segment's stroke is the ramp colour of the leading point's value"), and both to `==`/`hashCode`.

- [ ] **Step 4: Add `geomLine` params**

In `chart_builder.dart`, `geomLine` (213–239): add `Channel<T>? colorBy,`/`ScatterColorEncoding? colorEncoding,` and pass them into `LineMark<T>(...)`.

- [ ] **Step 5: Add `_xyColorPoints`, rewire `_lowerLine`, validate + legend**

Add near `_xyPoints` (`plot_lowering.dart:496`):

```dart
/// Builds points whose OUTGOING segment carries a baked colour: point i's
/// `segmentStyle.color` is the ramp colour of point i's channel value (the
/// segment from i to i+1). The last point has no outgoing segment, so its
/// segmentStyle is unused; it is still set for parity with a hand-built series.
List<ChartDataPoint> _xyColorPoints<T>(
  List<T> data,
  FieldAccessor<T, num> x,
  FieldAccessor<T, num> y,
  Channel<T> colorBy,
  ScatterColorEncoding encoding,
) {
  final colors = _bakeChannelColors(colorBy, encoding, data);
  return <ChartDataPoint>[
    for (var i = 0; i < data.length; i++)
      ChartDataPoint(
        x: x(data[i]).toDouble(),
        y: y(data[i]).toDouble(),
        segmentStyle: colors[i] == null ? null : SegmentStyle.color(colors[i]!),
      ),
  ];
}
```

Rewire `_lowerLine` (505–523): replace `points: _xyPoints(data, mark.x, mark.y),` with:

```dart
    points: mark.colorBy == null
        ? _xyPoints(data, mark.x, mark.y)
        : _xyColorPoints(data, mark.x, mark.y, mark.colorBy!, mark.colorEncoding!),
```

In the structural pass, move `LineMark` out of the shared arm to validate its colour channel:

```dart
      case LineMark<T>():
        boundAxes[index] = _bindAxis(mark, markId, axes, axesById, boundAxisIds);
        _validateColorChannel(mark.colorBy, mark.colorEncoding, markId);
      case AreaMark<T>() || CandlestickMark<T>():
        boundAxes[index] = _bindAxis(mark, markId, axes, axesById, boundAxisIds);
```

(Keep the `BarMark` arm from Task 1.) In the materialization loop, the `LineMark` arm appends the legend:

```dart
      case LineMark<T>():
        series.add(_lowerLine(mark, markId, axis!, spec.data));
        _addColorLegend(annotations, mark.colorBy, mark.colorEncoding, spec.data);
```

- [ ] **Step 6: Run to verify it passes**

Run: `flutter test test/unit/grammar/channel_line_color_test.dart` → PASS. Then `flutter analyze lib` → clean.

- [ ] **Step 7: Golden**

`test/golden/grammar_channels_line/grammar_channels_line_golden_test.dart` (tolerant comparator from the start; same pattern as Task 1 Step 7). Golden `goldens/line_color.png` shows a green→red line.

- [ ] **Step 8: Generate + verify**

Run: `flutter test --update-goldens test/golden/grammar_channels_line/` then `flutter test test/golden/grammar_channels_line/` → PASS.

- [ ] **Step 9: Commit**

```bash
git add lib/src/grammar/mark.dart lib/src/grammar/chart_builder.dart lib/src/grammar/plot_lowering.dart test/unit/grammar/channel_line_color_test.dart test/golden/grammar_channels_line/
git commit -m "feat(grammar): geomLine colour channel bakes per-segment segmentStyle.color"
```

---

### Task 3: geomArea colour (edge — documented caveat)

Same per-segment mechanism as line, applied to the area's top edge. The `geomArea(colorBy:)` dartdoc MUST state this colours the EDGE, not the fill (fill-by-value is deferred render work).

**Files:**
- Modify: `lib/src/grammar/mark.dart` (`AreaMark` — add `colorBy`/`colorEncoding` with the edge caveat in the dartdoc)
- Modify: `lib/src/grammar/chart_builder.dart` (`geomArea` — param dartdoc states "edge, not fill")
- Modify: `lib/src/grammar/plot_lowering.dart` (`_lowerArea` rewire + structural pass + materialization legend)
- Test: `test/unit/grammar/channel_area_color_test.dart`
- Test (golden): `test/golden/grammar_channels_area/grammar_channels_area_golden_test.dart`

**Interfaces:**
- Consumes: Task 2's `_xyColorPoints`, Task 1's `_addColorLegend`/`_validateColorChannel`.

- [ ] **Step 1: Write the failing test**

`test/unit/grammar/channel_area_color_test.dart` — mirror Task 2's test but with `geomArea` and assert `(lowered.series.single as AreaChartSeries).points[i].segmentStyle?.color == ramp.colorFor(...)`, plus the legend assertion. (Reuse a small `P`-like fixture in-file.)

- [ ] **Step 2: Run to verify it fails**

Run: `flutter test test/unit/grammar/channel_area_color_test.dart`
Expected: FAIL — `geomArea` has no `colorBy` param.

- [ ] **Step 3: Add `AreaMark` colour fields**

In `mark.dart`, `AreaMark<T>` (147–231): add `this.colorBy,`/`this.colorEncoding,`, the two fields, and `==`/`hashCode`. Field dartdoc for `colorBy`:

```dart
  /// Optional colour channel. Colours the area's TOP EDGE per segment (the
  /// leading-point rule), NOT the fill — value-driven fill is not yet
  /// supported. Baked at lowering into `ChartDataPoint.segmentStyle.color`.
  final Channel<T>? colorBy;
```

- [ ] **Step 4: Add `geomArea` params**

In `chart_builder.dart`, `geomArea` (242–272): add `Channel<T>? colorBy,`/`ScatterColorEncoding? colorEncoding,` (dartdoc on the verb repeats the "edge, not fill" caveat) and pass into `AreaMark<T>(...)`.

- [ ] **Step 5: Rewire `_lowerArea`, validate + legend**

`_lowerArea` (525–545): replace `points: _xyPoints(data, mark.x, mark.y),` with the same colour-aware ternary as Task 2 (`_xyColorPoints`). In the structural pass move `AreaMark` to its own arm calling `_validateColorChannel`; in the materialization loop the `AreaMark` arm calls `_addColorLegend`.

- [ ] **Step 6: Run to verify it passes**

Run: `flutter test test/unit/grammar/channel_area_color_test.dart` → PASS. `flutter analyze lib` → clean.

- [ ] **Step 7–8: Golden**

`test/golden/grammar_channels_area/` (tolerant comparator). Generate with `--update-goldens`, verify `goldens/area_color.png` shows a colour-graded edge over the fill.

- [ ] **Step 9: Commit**

```bash
git add lib/src/grammar/mark.dart lib/src/grammar/chart_builder.dart lib/src/grammar/plot_lowering.dart test/unit/grammar/channel_area_color_test.dart test/golden/grammar_channels_area/
git commit -m "feat(grammar): geomArea colour channel bakes edge segmentStyle.color (fill deferred)"
```

---

### Task 4: geomBar size (width — linear multiplier)

Add the bar width channel: `sizeBy` maps a value **linearly** into a `ScatterSizeEncoding`'s `[minimumRadius, maximumRadius]` range, **reinterpreted as a width multiplier**, baked into `pointStyle.size`. Native scale is linear (naming `sqrt` raises `unsupportedChannelScale`).

**Files:**
- Modify: `lib/src/grammar/mark.dart` (`BarMark` — add `sizeBy`/`sizeEncoding`)
- Modify: `lib/src/grammar/chart_builder.dart` (`geomBar`)
- Modify: `lib/src/grammar/plot_lowering.dart` (`_bakeChannelWidths`, `_barSizeMultiplierDefault`, widen `_barStyledPoints` + `_lowerBar`, extend `_validateBarSizeChannel`)
- Test: `test/unit/grammar/channel_bar_size_test.dart`
- Test (golden): `test/golden/grammar_channels_bar_size/grammar_channels_bar_size_golden_test.dart`

**Interfaces:**
- Consumes: Task 1's `_finiteDomain`, `_barStyledPoints`, `_requireScale`.
- Produces: `List<double?> _bakeChannelWidths<T>(Channel<T> sizeBy, ScatterSizeEncoding encoding, List<T> data)`; `void _validateBarSizeChannel<T>(Channel<T>? sizeBy, ScatterSizeEncoding? sizeEncoding, String markId)`; `const ScatterSizeEncoding _barSizeMultiplierDefault`.

- [ ] **Step 1: Write the failing test**

`test/unit/grammar/channel_bar_size_test.dart`:

```dart
// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

/// geomBar size channel: value -> LINEAR map -> per-bar pointStyle.size (width).
library;

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter_test/flutter_test.dart';

class Bar {
  const Bar(this.cat, this.value, this.weight);
  final double cat;
  final double value;
  final double weight;
}

double bcat(Bar r) => r.cat;
double bval(Bar r) => r.value;
double bweight(Bar r) => r.weight;

const rows = <Bar>[Bar(0, 10, 0), Bar(1, 20, 5), Bar(2, 15, 10)];
// width multiplier range 0.5 .. 1.5
const widths = ScatterSizeEncoding(minimumRadius: 0.5, maximumRadius: 1.5);

void main() {
  test('each bar width = linear map of weight into [0.5, 1.5]', () {
    final lowered = BravenChart.of(rows)
        .x(bcat)
        .y(bval)
        .geomBar(sizeBy: Channel(bweight), sizeEncoding: widths)
        .toSpec().lower();
    final bar = lowered.series.single as BarChartSeries;
    // weight 0 -> 0.5, weight 5 -> 1.0, weight 10 -> 1.5 (LINEAR, not sqrt).
    expect(bar.points[0].pointStyle?.size, closeTo(0.5, 1e-9));
    expect(bar.points[1].pointStyle?.size, closeTo(1.0, 1e-9));
    expect(bar.points[2].pointStyle?.size, closeTo(1.5, 1e-9));
  });

  test('colour + size compose on one bar mark', () {
    const ramp = ScatterColorEncoding(colors: <int>[]) ; // placeholder, replaced below
  }, skip: 'see combined test below');

  test('a non-native size scale raises unsupportedChannelScale', () {
    expect(
      () => BravenChart.of(rows)
          .x(bcat)
          .y(bval)
          .geomBar(
            sizeBy: Channel(bweight, scale: ChannelScale.sqrt),
            sizeEncoding: widths,
          )
          .toSpec().lower(),
      throwsA(isA<GrammarSpecException>().having(
          (e) => e.code, 'code', GrammarDiagnosticCode.unsupportedChannelScale)),
    );
  });

  test('sizeEncoding without sizeBy raises orphanChannelEncoding', () {
    expect(
      () => BravenChart.of(rows)
          .x(bcat)
          .y(bval)
          .geomBar(sizeEncoding: widths)
          .toSpec().lower(),
      throwsA(isA<GrammarSpecException>().having(
          (e) => e.code, 'code', GrammarDiagnosticCode.orphanChannelEncoding)),
    );
  });

  test('sizeBy without sizeEncoding uses the bar default multiplier range', () {
    final lowered = BravenChart.of(rows)
        .x(bcat)
        .y(bval)
        .geomBar(sizeBy: Channel(bweight))
        .toSpec().lower();
    final bar = lowered.series.single as BarChartSeries;
    // default range 0.3 .. 1.0 -> weight 0 -> 0.3, weight 10 -> 1.0.
    expect(bar.points[0].pointStyle?.size, closeTo(0.3, 1e-9));
    expect(bar.points[2].pointStyle?.size, closeTo(1.0, 1e-9));
  });
}
```

> Delete the `skip`ped placeholder test; add instead a real combined test: `geomBar(colorBy: Channel(bweight), colorEncoding: <ramp>, sizeBy: Channel(bweight), sizeEncoding: widths)` and assert `points[i].pointStyle` has BOTH a non-null `color` and the expected `size`.

- [ ] **Step 2: Run to verify it fails**

Run: `flutter test test/unit/grammar/channel_bar_size_test.dart`
Expected: FAIL — `geomBar` has no `sizeBy` param.

- [ ] **Step 3: Add `BarMark` size fields**

In `mark.dart`, `BarMark<T>`: add `this.sizeBy,`/`this.sizeEncoding,`, the fields, and `==`/`hashCode`. Dartdoc for `sizeBy`:

```dart
  /// Optional size channel driving each bar's WIDTH. The value is mapped
  /// LINEARLY into [sizeEncoding]'s `[minimumRadius, maximumRadius]` range,
  /// reinterpreted as a width MULTIPLIER (scatter's sqrt/area radius mapping is
  /// wrong for width). Baked at lowering into `ChartDataPoint.pointStyle.size`.
  final Channel<T>? sizeBy;

  /// Width-multiplier range for [sizeBy] (min/max interpreted as multipliers).
  /// Defaults to 0.3..1.0 when [sizeBy] is set and this is null.
  final ScatterSizeEncoding? sizeEncoding;
```

- [ ] **Step 4: Add `geomBar` size params**

In `chart_builder.dart`, `geomBar`: add `Channel<T>? sizeBy,`/`ScatterSizeEncoding? sizeEncoding,` and pass into `BarMark<T>(...)`.

- [ ] **Step 5: Add width baking + widen `_barStyledPoints`/`_lowerBar` + validate**

Add to `plot_lowering.dart`:

```dart
/// Bar width channel default range (multipliers). A bar at the domain minimum
/// is 0.3x the base width; the maximum is full width.
const ScatterSizeEncoding _barSizeMultiplierDefault = ScatterSizeEncoding(
  minimumRadius: 0.3,
  maximumRadius: 1.0,
);

/// Per-row baked width multiplier: [sizeBy]'s value mapped LINEARLY into
/// `[encoding.minimumRadius, encoding.maximumRadius]`. Null where non-finite or
/// the domain is empty (that bar keeps its base width).
List<double?> _bakeChannelWidths<T>(
  Channel<T> sizeBy,
  ScatterSizeEncoding encoding,
  List<T> data,
) {
  final domain = _finiteDomain(sizeBy.accessor, data);
  final span = domain == null ? 0.0 : domain.max - domain.min;
  return <double?>[
    for (final row in data)
      () {
        final v = sizeBy.accessor(row).toDouble();
        if (!v.isFinite || domain == null) return null;
        final t = span <= 0 ? 0.5 : ((v - domain.min) / span).clamp(0.0, 1.0);
        return encoding.minimumRadius +
            t * (encoding.maximumRadius - encoding.minimumRadius);
      }(),
  ];
}

/// Structural validation of the bar size channel: native scale is linear, and
/// a sizeEncoding with no sizeBy is an orphan. (sizeBy without sizeEncoding is
/// allowed; it uses [_barSizeMultiplierDefault].)
void _validateBarSizeChannel<T>(
  Channel<T>? sizeBy,
  ScatterSizeEncoding? sizeEncoding,
  String markId,
) {
  _requireScale(markId, 'sizeBy', sizeBy?.scale, ChannelScale.linear);
  if (sizeBy == null && sizeEncoding != null) {
    throw GrammarSpecException.orphanChannelEncoding(
      markId,
      'sizeEncoding',
      'sizeBy',
    );
  }
}
```

Replace the Task-1 colour-only `_barStyledPoints` with the full version from Task 1 Step 5 (the one taking `sizeBy`/`sizeEncoding`). Update `_lowerBar`'s point-building to pass the size args and to use `_barStyledPoints` when EITHER channel is present:

```dart
    points: (mark.colorBy == null && mark.sizeBy == null)
        ? _xyPoints(data, mark.x, mark.y)
        : _barStyledPoints(data, mark.x, mark.y, mark.colorBy,
            mark.colorEncoding, mark.sizeBy, mark.sizeEncoding),
```

Extend the structural-pass `BarMark` arm to also validate the size channel:

```dart
      case BarMark<T>():
        boundAxes[index] = _bindAxis(mark, markId, axes, axesById, boundAxisIds);
        _validateColorChannel(mark.colorBy, mark.colorEncoding, markId);
        _validateBarSizeChannel(mark.sizeBy, mark.sizeEncoding, markId);
```

- [ ] **Step 6: Run to verify it passes**

Run: `flutter test test/unit/grammar/channel_bar_size_test.dart` → PASS. `flutter analyze lib` → clean.

- [ ] **Step 7–8: Golden**

`test/golden/grammar_channels_bar_size/` (tolerant comparator). Verify `goldens/bar_size.png` shows bars of increasing width.

- [ ] **Step 9: Commit**

```bash
git add lib/src/grammar/mark.dart lib/src/grammar/chart_builder.dart lib/src/grammar/plot_lowering.dart test/unit/grammar/channel_bar_size_test.dart test/golden/grammar_channels_bar_size/
git commit -m "feat(grammar): geomBar size channel bakes per-bar width multiplier (linear)"
```

---

### Task 5: Showcase preset + parity proof

A Chart Grammar showcase preset exercising all four new channel/family pairs, each authored through the grammar and shown beside its hand-built equivalent (the parity proof).

**Files:**
- Modify: `example/lib/showcase/pages/chart_grammar_page.dart` (a `_GrammarPreset.channels` preset following the existing preset pattern — a grammar chart, a hand-built equivalent, controls, label/icon/stageTitle/stageSubtitle/guide arms)
- Test: `example/test/showcase/chart_grammar_channels_preset_test.dart` (smoke: the preset builds and renders without throwing, following `chart_grammar_radial_preset_test.dart`)

- [ ] **Step 1: Add the preset**

Follow the radial preset added in `chart_grammar_page.dart` (the `_GrammarPreset.radial` arms) as the template. Add a `_GrammarPreset.channels` value and its arms: a grammar chart `BravenChart.of(rows).x(..).y(..).geomBar(colorBy: ..., colorEncoding: ...)` (and a segmented toggle to switch between colour-bar / colour-line / edge-colour-area / variable-width-bar), the hand-built equivalent (a `BarChartSeries`/`LineChartSeries` with the same baked `pointStyle`/`segmentStyle` + the same `LegendAnnotation`), controls, and the label/icon/stageTitle/stageSubtitle/guide switch arms.

- [ ] **Step 2: Write the smoke test**

`example/test/showcase/chart_grammar_channels_preset_test.dart` — mirror `chart_grammar_radial_preset_test.dart`: pump the page, select the channels preset, cycle the family toggle, assert no exception + the expected series types render.

- [ ] **Step 3: Run + analyze**

Run: `flutter test example/test/showcase/chart_grammar_channels_preset_test.dart` → PASS. `flutter analyze example/lib` → clean.

- [ ] **Step 4: Commit**

```bash
git add example/lib/showcase/pages/chart_grammar_page.dart example/test/showcase/chart_grammar_channels_preset_test.dart
git commit -m "feat(showcase): scale-driven channels preset with hand-built parity"
```

---

### Task 6: Full-suite gate + programme docs touch (fold-in)

- [ ] **Step 1: Full suite + analyze**

Run: `flutter analyze lib` and `flutter analyze example/lib` (both clean), then `flutter test` (report total, 0 failures, zero golden drift; drift gates 51/51 — this slice touches no config surface, so they must be unchanged).

- [ ] **Step 2: Docs (light — full docs are the deferred programme batch)**

The programme defers prose docs to an end batch. Do NOT write the full doc section here. Only: if `doc/chart_grammar.md` lists scale-driven channels as "scatter-only" or "not supported on other families", correct that one line to reflect bar/line/area colour + bar width (with the edge/multiplier caveats). Commit separately if changed:

```bash
git add doc/chart_grammar.md
git commit -m "docs(grammar): note scale-driven colour/size channels on non-scatter families"
```

---

## Self-Review

**1. Spec coverage:**
- Colour on bar/line/area → Tasks 1/2/3. Bar size(width) → Task 4. ✓
- Reuse `ScatterColorEncoding`/`ScatterSizeEncoding` → the channel params + `colorFor` reuse. ✓
- Bake at lowering into `pointStyle.color`/`segmentStyle.color`/`pointStyle.size` → `_barStyledPoints`/`_xyColorPoints`. ✓
- Colour legend built at lowering (`LegendAnnotation`+`LegendColorScale`) → `_channelColorLegend`/`_addColorLegend`, Tasks 1–3. ✓
- No new diagnostic codes (reuse missing/orphan/unsupported) → `_validateColorChannel`/`_validateBarSizeChannel`. ✓
- Two documented reinterpretations (area edge; bar multiplier/linear) → Task 3 dartdoc + Task 4 dartdoc + `_bakeChannelWidths`. ✓
- Compile-time validity (no opacity param on these geoms) → params never added. ✓
- Parity + tolerant goldens → each task's golden + the showcase parity. ✓
- No drift gate touched → Task 6 gate confirms 51/51. ✓

**2. Placeholder scan:** The Task 4 Step 1 test contains one intentionally-`skip`ped placeholder with an explicit instruction to replace it with a real combined colour+size test — the executor must delete it and write the combined test (do not ship the `skip`). No other placeholders.

**3. Type consistency:** `_bakeChannelColors`/`_channelColorLegend`/`_validateColorChannel`/`_addColorLegend`/`_finiteDomain` signatures are identical everywhere referenced. `_barStyledPoints` is introduced colour-only in Task 1 and widened (signature + call site) in Task 4 — flagged explicitly in both tasks. `colorFor` is always called with the named `resolvedMinimumValue`/`resolvedMaximumValue` params. `ScatterSizeEncoding` fields are `minimumRadius`/`maximumRadius` (not `minRadius`/`maxRadius`). Verb is `geomBar`/`geomLine`/`geomArea` (scatter's is `geomPoint`, unchanged).

**Lowering accessor (verified):** the test snippets use `chain.toSpec().lower()` — `toSpec()` (`chart_builder.dart:623`) hands back the `PlotSpec<T>`, and `spec.lower()` returns the `LoweredPlot` (matching every existing `plot_lowering_*_test.dart`). No further accessor verification needed.
