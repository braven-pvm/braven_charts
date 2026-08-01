# Range Area Grammar Mark Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** `RangeAreaChartSeries` becomes grammar-authorable through `geomRangeArea(low:, high:)`, and the selection lab's Range Area family emits a faithful, round-tripping chain.

**Architecture:** A `RangeAreaMark<T>` on the existing `SeriesMark<T>` intermediate carries `x` plus nullable `low`/`high` accessors (a gap is "both null") and the range-area-native config fields. It lowers to a real `RangeAreaChartSeries`; the Grammar Source generator reverses that series back into a `.geomRangeArea(` chain, rendering its nested config literals through new public seams on `ChartConfigDartEmitter` so the config form and the grammar form cannot disagree. One arm added to `seriesWithoutAxisBinding` unblocks both the mount and the round-trip comparison at once.

**Tech Stack:** Dart ≥3.9 / Flutter. `flutter_test` + `flutter_test` widget tests. No new dependencies.

**Spec:** `docs/superpowers/specs/2026-08-01-grammar-range-area-mark-design.md`
**Register:** BC-0038 (lane `chart-grammar`).
**Worktree/branch:** `F:\Repositories\braven_charts-range-area`, `feature/grammar-range-area`.

## Global Constraints

- Work only in the worktree `F:\Repositories\braven_charts-range-area` on branch `feature/grammar-range-area`. **No PR without the owner's explicit go-ahead.**
- Stage with specific paths: `git add <path> <path>`. **Never `git add -A`.** Never stage `example/windows/flutter/*`.
- Analyze with `flutter analyze lib` **and** `flutter analyze example/lib`. **Never analyze the repo root** — the vendored `packages/fleather` pollutes it.
- Commit messages end with the trailer: `Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>`
- **Existing emission must stay byte-identical.** Any test that pins previously-emitted source is a regression signal, not a fixture to update.
- Existing goldens unchanged. Drift gates (`test/meta/`) green.
- Changed files must pass the format gate: `dart format` then `dart run tool/check_dart_format.dart`.
- **Marks get no `copyWith` and no `@chartSurface`** — that is a standing decision recorded in `mark.dart`'s docstring, not an omission.
- **Anything the mark cannot carry is refused with a NAMED reason**, never silently degraded.
- The mark deliberately does **not** carry `pathAnimation`, `fillGradient` or `isXOrdered`. The first two are roadmap 1d and are named refusals on `AreaMark` today; symmetry is the point. The third is hard-coded `true` by the `RangeAreaChartSeries` constructor, so a knob would be a lie.

---

## File Structure

**Modified — `lib/`:**

| File | Responsibility change |
|---|---|
| `lib/src/grammar/series_axis_unbinding.dart` | One `RangeAreaChartSeries()` arm. Unblocks the mount and the round-trip comparison together. |
| `lib/src/grammar/mark.dart` | New `final class RangeAreaMark<T> extends SeriesMark<T>`. |
| `lib/src/grammar/chart_builder.dart` | New `geomRangeArea(...)` verb; `_geometryIds` gains the family. |
| `lib/src/grammar/plot_lowering.dart` | `_lowerRangeArea`; four sealed-switch/`is`-chain sites; `_rangeAreaDefaults`. |
| `lib/src/grammar/facet_partition.dart` | `_axisAccessors` arm (facet range contribution). |
| `lib/src/grammar/grammar_diagnostics.dart` | Two codes + factories: `invalidRangeAreaRow`, `incompleteRangeAreaInterval`. |
| `lib/src/source/chart_config_dart_emitter.dart` | Three public seams; the `formatter` placeholder + warning. |
| `lib/src/source/chart_grammar_source_generator.dart` | Emittability gate, family word, plan/fill/emit arms. |

**Modified — tests:**

| File | Change |
|---|---|
| `test/unit/grammar/series_axis_unbinding_test.dart` | Range area moves from the null case to the unbindable list; radial-bar becomes the new null case. |
| `test/unit/grammar/chart_builder_test.dart` | Verb construction + missing-encoding. |
| `test/unit/grammar/plot_lowering_parity_test.dart` | Lowering parity, gap semantics, diagnostics. |
| `test/unit/source/chart_grammar_source_generator_test.dart` | Round-trip cases, refusal pins, **shape 44**. |
| `test/unit/source/chart_config_dart_emitter_*_test.dart` | The formatter placeholder + warning. |
| `example/test/showcase/grammar_emission_census_test.dart` | Census expectations. |

**Created:**

| File | Responsibility |
|---|---|
| `example/test/showcase/selection_showcase_range_area_grammar_test.dart` | Mounted-page acceptance for the selection lab's Range Area family. |

**Docs:** `doc/chart_grammar.md`, `doc/feature_matrix.md`, `CHANGELOG.md`.

---

### Task 1: Unblock the axis unbinding

This is the load-bearing task. Without it every later task builds a mark that closes zero panes.

**Files:**
- Modify: `lib/src/grammar/series_axis_unbinding.dart:34-60`
- Test: `test/unit/grammar/series_axis_unbinding_test.dart:120-133`

**Interfaces:**
- Consumes: nothing.
- Produces: `seriesWithoutAxisBinding(RangeAreaChartSeries)` returns the series with `yAxisId` and `yAxisConfig` null. Both callers (`BravenPlot._legacySingleAxisSeries`, `ChartGrammarSourceGenerator._withoutAxisBinding`) pick it up with no change of their own.

- [ ] **Step 1: Rewrite the existing null-case test as the new behaviour**

The current test asserts range area returns `null`, and its comment claims `copyWith` cannot clear the binding — which is already false (`range_area_chart_series.dart:245-246` has `clearYAxisId`/`clearYAxisConfig`). Replace the whole `test('returns null for a family that cannot express an unbound series', ...)` block (lines 120–133) with:

```dart
    test('returns null for a family that cannot express an unbound series', () {
      // `RadialBarChartSeries` measures against no Y axis at all — it does not
      // even take `yAxisId` — and its `copyWith` has no clear flags. It is the
      // shape the null answer exists for: both callers must keep failing closed
      // rather than one of them guessing.
      final series = RadialBarChartSeries(
        id: 'radial-bar',
        points: const <ChartDataPoint>[ChartDataPoint(x: 0, y: 1)],
      );

      expect(seriesWithoutAxisBinding(series), isNull);
    });
```

Then add the range-area fixture to the unbindable list in the FIRST test, immediately after the `CandlestickChartSeries` entry (inside the `bound` list, before the closing `];`):

```dart
        RangeAreaChartSeries(
          id: 'range',
          points: <RangeAreaDataPoint>[
            RangeAreaDataPoint(x: 0, low: 1, high: 3),
            RangeAreaDataPoint(x: 1, low: 2, high: 4),
          ],
          name: 'range series',
          color: const Color(0xFF2563EB),
          unit: 'W',
          yAxisId: 'y',
          yAxisConfig: axis,
        ),
```

Add the import for the new negative fixture at the top of the file, keeping the import block alphabetical:

```dart
import 'package:braven_charts/src/models/radial_bar_chart_series.dart';
```

The existing `range_area_chart_series.dart` / `range_area_data_point.dart` imports are already there and stay.

- [ ] **Step 2: Run the test to verify it fails**

Run: `flutter test test/unit/grammar/series_axis_unbinding_test.dart`
Expected: FAIL — the first test reports `RangeAreaChartSeries must be unbindable` (the `isNotNull` reason).

- [ ] **Step 3: Add the arm**

In `lib/src/grammar/series_axis_unbinding.dart`, add the import beside the existing two:

```dart
import '../models/range_area_chart_series.dart';
```

and add the arm to the switch, after the `CandlestickChartSeries()` arm:

```dart
  RangeAreaChartSeries() => series.copyWith(
    clearYAxisId: true,
    clearYAxisConfig: true,
  ),
```

Update the docstring at lines 34-37 so it stops naming range-area as un-unbindable:

```dart
/// The six families listed are the ones the grammar reverses — the five
/// Cartesian geometries plus range area. Every other family — radial, gauge,
/// radial bar — returns null: a family that has no `clearYAxisId` cannot be
/// unbound, and guessing is how the two callers would silently disagree.
```

- [ ] **Step 4: Run the test to verify it passes**

Run: `flutter test test/unit/grammar/series_axis_unbinding_test.dart`
Expected: PASS, 2 tests.

Note the round-trip assertion in the first test (`stripped.copyWith(yAxisId: 'y', yAxisConfig: axis) == series`) is doing real work here: `RangeAreaChartSeries.copyWith` rebuilds through the validating constructor, so this proves the rebuild survives validation and loses nothing but the binding.

- [ ] **Step 5: Commit**

```bash
git add lib/src/grammar/series_axis_unbinding.dart test/unit/grammar/series_axis_unbinding_test.dart
git commit -m "feat(grammar): let a range-area series drop its axis binding

The one shared helper both BravenPlot's legacy single-axis mount and the
generator's round-trip comparison ask. Range area answered null, so a lowered
band kept a binding the captured band never had and every range-area chart
refused through a tail that names no field.

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

### Task 2: `RangeAreaMark` and the `geomRangeArea` verb

**Files:**
- Modify: `lib/src/grammar/mark.dart` (append after `CandlestickMark`, before `TrendMark` — around line 769)
- Modify: `lib/src/grammar/chart_builder.dart:221-230` (`_geometryIds`), and append the verb after `geomCandlestick` (around line 534)
- Test: `test/unit/grammar/chart_builder_test.dart`

**Interfaces:**
- Consumes: `SeriesMark<T>` (`id`, `name`, `color`, `yAxisId`, `unit`), `FieldAccessor<T, R>` from `channel.dart`.
- Produces:
  - `final class RangeAreaMark<T> extends SeriesMark<T>` with `x: FieldAccessor<T, num>`, `low`/`high: FieldAccessor<T, num?>`, `label`/`pointKey: FieldAccessor<T, String?>?`, and the nullable config fields `interpolation: LineInterpolation?`, `tension: double?`, `fillOpacity: double?`, `borderMode: RangeAreaBorderMode?`, `upperBoundaryStyle`/`lowerBoundaryStyle: RangeAreaBoundaryStyle?`, `connectGaps: bool?`, `showBoundaryMarkers: bool?`, `markerRadius: double?`, `labelConfig: RangeAreaLabelConfig?`, `hitTestMode: RangeAreaHitTestMode?`.
  - `BravenChart<T>.geomRangeArea({required FieldAccessor<T, num?> low, required FieldAccessor<T, num?> high, FieldAccessor<T, num>? x, ...})`.

**Why every config field is nullable:** null means "the `RangeAreaChartSeries` default". That is the `AreaMark` pattern and it keeps ONE source of truth for the defaults — the series class. The reversal (Task 5) sets a field to null when the captured value equals the default, so a default chart emits nothing for it.

- [ ] **Step 1: Write the failing test**

Append to `test/unit/grammar/chart_builder_test.dart`, inside the top-level `main()`'s existing group structure (add a new `group` at the end of `main()`):

```dart
  group('geomRangeArea', () {
    test('constructs a RangeAreaMark carrying every native field', () {
      final spec = BravenChart.of(_rangeRows)
          .x((row) => row.x)
          .geomRangeArea(
            id: 'band',
            low: (row) => row.low,
            high: (row) => row.high,
            name: 'Recovery',
            color: const Color(0xFF2563EB),
            unit: 'score',
            interpolation: LineInterpolation.monotone,
            tension: 0.4,
            fillOpacity: 0.22,
            borderMode: RangeAreaBorderMode.closed,
            connectGaps: true,
            showBoundaryMarkers: true,
            markerRadius: 4,
            hitTestMode: RangeAreaHitTestMode.nearestBoundary,
          )
          .toSpec();

      final mark = spec.marks.single as RangeAreaMark<_RangeRow>;
      expect(mark.id, 'band');
      expect(mark.name, 'Recovery');
      expect(mark.color, const Color(0xFF2563EB));
      expect(mark.unit, 'score');
      expect(mark.interpolation, LineInterpolation.monotone);
      expect(mark.tension, 0.4);
      expect(mark.fillOpacity, 0.22);
      expect(mark.borderMode, RangeAreaBorderMode.closed);
      expect(mark.connectGaps, isTrue);
      expect(mark.showBoundaryMarkers, isTrue);
      expect(mark.markerRadius, 4);
      expect(mark.hitTestMode, RangeAreaHitTestMode.nearestBoundary);
      expect(mark.low(_rangeRows.first), 1);
      expect(mark.high(_rangeRows.first), 3);
    });

    test('inherits the chart-wide x accessor', () {
      final spec = BravenChart.of(_rangeRows)
          .x((row) => row.x)
          .geomRangeArea(low: (row) => row.low, high: (row) => row.high)
          .toSpec();

      final mark = spec.marks.single as RangeAreaMark<_RangeRow>;
      expect(mark.x(_rangeRows.last), 1);
      // Every config field left unset stays null: null is "the series
      // default", resolved once at lowering, so the mark never carries a
      // second copy of a default that could drift from the class.
      expect(mark.interpolation, isNull);
      expect(mark.fillOpacity, isNull);
      expect(mark.labelConfig, isNull);
      expect(mark.upperBoundaryStyle, isNull);
    });

    test('a band with no x anywhere is refused by name', () {
      expect(
        () => BravenChart.of(_rangeRows)
            .geomRangeArea(low: (row) => row.low, high: (row) => row.high),
        throwsA(
          isA<GrammarSpecException>()
              .having((e) => e.code, 'code', GrammarDiagnosticCode.missingEncoding)
              .having((e) => e.message, 'message', contains('geomRangeArea')),
        ),
      );
    });

    test('a band is a geometry, so a trend may name it as its source', () {
      // `_geometryIds` (the builder) and `geometryIds` (the lowering) answer
      // the same question — "which marks lower to a series?" — and MUST agree.
      // A band lowers to a RangeAreaChartSeries, so it is a valid trend source
      // in both, and the trend is fitted over the band's midpoints exactly as a
      // hand-authored TrendAnnotation on that series would be.
      final chart = BravenChart.of(_rangeRows)
          .x((row) => row.x)
          .geomRangeArea(
            id: 'band',
            low: (row) => row.low,
            high: (row) => row.high,
          )
          .trend(of: 'band');

      expect(chart.toSpec().marks, hasLength(2));
    });
  });
```

Add the row type and fixture at the bottom of the file, beside whatever other private fixtures it holds:

```dart
class _RangeRow {
  const _RangeRow(this.x, this.low, this.high);
  final double x;
  final double? low;
  final double? high;
}

const List<_RangeRow> _rangeRows = <_RangeRow>[
  _RangeRow(0, 1, 3),
  _RangeRow(1, 2, 4),
];
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `flutter test test/unit/grammar/chart_builder_test.dart`
Expected: FAIL to COMPILE — "The method 'geomRangeArea' isn't defined" and "Undefined name 'RangeAreaMark'".

- [ ] **Step 3: Add the mark**

In `lib/src/grammar/mark.dart`, add the imports beside the existing model imports (keeping the block's existing grouping):

```dart
import '../models/range_area_style.dart'
    show
        RangeAreaBorderMode,
        RangeAreaBoundaryStyle,
        RangeAreaHitTestMode,
        RangeAreaLabelConfig;
```

Then insert the class after `CandlestickMark` (after line 769, before the `TrendMark` docstring):

```dart
/// A filled band between paired `low`/`high` values at each `x`.
///
/// ## Gaps
///
/// [low] and [high] are `FieldAccessor<T, num?>`, not `num`, because
/// `RangeAreaDataPoint.gap` is a real point with no interval and a TOTAL
/// accessor cannot express one. Both null at a row lowers to
/// `RangeAreaDataPoint.gap`; exactly one null is an authoring error and raises
/// `GrammarDiagnosticCode.incompleteRangeAreaInterval` rather than guessing a
/// bound. This mirrors `PolarMark.intervalLow`/`intervalHigh`.
///
/// ## No channels
///
/// Deliberate, not an omission. The range-area painter reads no per-point
/// colour: it paints from the series colour, [fillOpacity], the two boundary
/// styles and the theme, and `RangeAreaScreenPoint` carries only the interval
/// geometry. A `colorBy` or size channel would be accepted and then ignored, so
/// none is offered.
///
/// ## What this mark does NOT carry
///
/// `pathAnimation` and `fillGradient` are roadmap 1d: they are named refusals on
/// [AreaMark] today and must stay symmetric across the Cartesian families rather
/// than being fixed here for one of them. `isXOrdered` is absent because
/// `RangeAreaChartSeries` hard-codes it `true` in its constructor — exactly as
/// `CandlestickChartSeries` does — so a knob would be a lie.
///
/// Every config field is nullable and null means "the `RangeAreaChartSeries`
/// default". The defaults live on the series class alone and are resolved once
/// at lowering, so the mark cannot carry a stale copy of one.
final class RangeAreaMark<T> extends SeriesMark<T> {
  /// Creates a range-area band geometry.
  const RangeAreaMark({
    required this.x,
    required this.low,
    required this.high,
    super.id,
    super.name,
    super.color,
    super.yAxisId,
    super.unit,
    this.label,
    this.pointKey,
    this.interpolation,
    this.tension,
    this.fillOpacity,
    this.borderMode,
    this.upperBoundaryStyle,
    this.lowerBoundaryStyle,
    this.connectGaps,
    this.showBoundaryMarkers,
    this.markerRadius,
    this.labelConfig,
    this.hitTestMode,
  });

  /// Horizontal position accessor. Values must be finite and strictly
  /// increasing across the data list.
  final FieldAccessor<T, num> x;

  /// Lower bound accessor. Null at a row means "no interval here" — see the
  /// class docstring.
  final FieldAccessor<T, num?> low;

  /// Upper bound accessor. Null at a row means "no interval here".
  final FieldAccessor<T, num?> high;

  /// Per-point label accessor (`ChartDataPoint.label`). Null leaves every point
  /// unlabelled; an accessor returning null — or `''`, treated the same — leaves
  /// that one point unlabelled.
  final FieldAccessor<T, String?>? label;

  /// Per-point stable identity accessor (`ChartDataPoint.pointKey`).
  ///
  /// Must be unique among the KEYED points of one series: a repeat raises
  /// `GrammarDiagnosticCode.duplicatePointKey`.
  final FieldAccessor<T, String?>? pointKey;

  /// Boundary path interpolation. Null keeps the series default.
  final LineInterpolation? interpolation;

  /// Curve tension in `[0, 1]`. Null keeps the series default.
  final double? tension;

  /// Fill opacity in `[0, 1]`. Null keeps the series default.
  final double? fillOpacity;

  /// Which boundaries are stroked. Null keeps the series default.
  final RangeAreaBorderMode? borderMode;

  /// Upper boundary stroke styling. Null keeps the series default.
  final RangeAreaBoundaryStyle? upperBoundaryStyle;

  /// Lower boundary stroke styling. Null keeps the series default.
  final RangeAreaBoundaryStyle? lowerBoundaryStyle;

  /// Whether to bridge gaps rather than break the band. Null keeps the series
  /// default.
  final bool? connectGaps;

  /// Whether to draw a marker at each boundary point. Null keeps the series
  /// default.
  final bool? showBoundaryMarkers;

  /// Boundary marker radius in logical pixels. Null keeps the series default.
  final double? markerRadius;

  /// Interval label configuration. Null keeps the series default.
  final RangeAreaLabelConfig? labelConfig;

  /// Which region is interactive. Null keeps the series default.
  final RangeAreaHitTestMode? hitTestMode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RangeAreaMark<T> &&
          other.x == x &&
          other.low == low &&
          other.high == high &&
          other.id == id &&
          other.name == name &&
          other.color == color &&
          other.yAxisId == yAxisId &&
          other.unit == unit &&
          other.label == label &&
          other.pointKey == pointKey &&
          other.interpolation == interpolation &&
          other.tension == tension &&
          other.fillOpacity == fillOpacity &&
          other.borderMode == borderMode &&
          other.upperBoundaryStyle == upperBoundaryStyle &&
          other.lowerBoundaryStyle == lowerBoundaryStyle &&
          other.connectGaps == connectGaps &&
          other.showBoundaryMarkers == showBoundaryMarkers &&
          other.markerRadius == markerRadius &&
          other.labelConfig == labelConfig &&
          other.hitTestMode == hitTestMode;

  @override
  int get hashCode => Object.hashAll(<Object?>[
    x,
    low,
    high,
    id,
    name,
    color,
    yAxisId,
    unit,
    label,
    pointKey,
    interpolation,
    tension,
    fillOpacity,
    borderMode,
    upperBoundaryStyle,
    lowerBoundaryStyle,
    connectGaps,
    showBoundaryMarkers,
    markerRadius,
    labelConfig,
    hitTestMode,
  ]);

  @override
  String toString() => 'RangeAreaMark(id: $id, name: $name)';
}
```

`Object.hashAll` rather than `Object.hash`: this mark has 22 fields and `Object.hash` takes at most 20 positional arguments.

- [ ] **Step 4: Add the verb**

In `lib/src/grammar/chart_builder.dart`, extend `_geometryIds` (lines 221–230) so the builder and the lowering agree on what a geometry is:

```dart
  Iterable<String> get _geometryIds => _marks
      .where(
        (mark) =>
            mark is LineMark<T> ||
            mark is AreaMark<T> ||
            mark is BarMark<T> ||
            mark is ScatterMark<T> ||
            mark is CandlestickMark<T> ||
            mark is RangeAreaMark<T>,
      )
      .map((mark) => mark.id!);
```

Add the imports beside the file's existing model imports:

```dart
import '../models/range_area_style.dart'
    show
        RangeAreaBorderMode,
        RangeAreaBoundaryStyle,
        RangeAreaHitTestMode,
        RangeAreaLabelConfig;
```

Then append the verb after `geomCandlestick` (after line 534):

```dart
  /// Appends a filled band between paired [low] and [high] values.
  ///
  /// [low] and [high] are NULLABLE accessors: returning null from BOTH at a row
  /// lowers that row to `RangeAreaDataPoint.gap`, which is how a break in the
  /// band is expressed. Returning null from exactly one is an authoring error
  /// (`incompleteRangeAreaInterval`) — a half-specified interval has no
  /// defensible reading.
  ///
  /// [unit] is the measure unit of this series' values (`ChartSeries.unit`),
  /// used when formatting them in tooltips and labels. It is the series' own
  /// unit, not the Y axis' — declare that on the axis.
  ///
  /// [label] names each POINT (`ChartDataPoint.label`); [pointKey] gives each
  /// point a stable identity for selection. Keys must be unique among one
  /// mark's keyed rows.
  ///
  /// Every styling argument left null keeps the `RangeAreaChartSeries` default.
  /// A band's rows must be strictly increasing in `x`; unsorted rows raise
  /// `invalidRangeAreaRow` naming the offending index.
  BravenChart<T> geomRangeArea({
    required FieldAccessor<T, num?> low,
    required FieldAccessor<T, num?> high,
    FieldAccessor<T, num>? x,
    String? id,
    String? name,
    Color? color,
    String? unit,
    FieldAccessor<T, String?>? label,
    FieldAccessor<T, String?>? pointKey,
    LineInterpolation? interpolation,
    double? tension,
    double? fillOpacity,
    RangeAreaBorderMode? borderMode,
    RangeAreaBoundaryStyle? upperBoundaryStyle,
    RangeAreaBoundaryStyle? lowerBoundaryStyle,
    bool? connectGaps,
    bool? showBoundaryMarkers,
    double? markerRadius,
    RangeAreaLabelConfig? labelConfig,
    RangeAreaHitTestMode? hitTestMode,
    String? yAxisId,
  }) => _append(
    RangeAreaMark<T>(
      id: _idFor(id),
      x: _resolveX('geomRangeArea', x),
      low: low,
      high: high,
      name: name,
      color: color,
      unit: unit,
      label: label,
      pointKey: pointKey,
      interpolation: interpolation,
      tension: tension,
      fillOpacity: fillOpacity,
      borderMode: borderMode,
      upperBoundaryStyle: upperBoundaryStyle,
      lowerBoundaryStyle: lowerBoundaryStyle,
      connectGaps: connectGaps,
      showBoundaryMarkers: showBoundaryMarkers,
      markerRadius: markerRadius,
      labelConfig: labelConfig,
      hitTestMode: hitTestMode,
      yAxisId: yAxisId,
    ),
  );
```

- [ ] **Step 5: Run the test — it will still fail, on the sealed switches**

Run: `flutter analyze lib`
Expected: FAIL — `plot_lowering.dart` and `facet_partition.dart` report non-exhaustive switches now that a new `Mark` variant exists. That is the sealed hierarchy doing its job; Task 3 closes them. Do not proceed past this step by adding `default:` arms.

- [ ] **Step 6: Commit (compiles after Task 3; commit the pair together)**

Hold this commit until Task 3, Step 5. The sealed hierarchy makes the mark and its dispatch sites one atomic change — an intermediate commit would not analyze.

---

### Task 3: Lowering, gaps and the two diagnostics

**Files:**
- Modify: `lib/src/grammar/grammar_diagnostics.dart` (enum around line 54; factories around line 287)
- Modify: `lib/src/grammar/plot_lowering.dart` — `is`-chain at 299-307, switch arms at ~360 / ~448 / ~526, defaults block at ~128, new `_lowerRangeArea`
- Modify: `lib/src/grammar/facet_partition.dart:73-106`
- Test: `test/unit/grammar/plot_lowering_parity_test.dart`

**Interfaces:**
- Consumes: `RangeAreaMark<T>` (Task 2).
- Produces:
  - `GrammarDiagnosticCode.invalidRangeAreaRow`, `GrammarDiagnosticCode.incompleteRangeAreaInterval`
  - `GrammarSpecException.invalidRangeAreaRow(String markId, int rowIndex, String reason)`
  - `GrammarSpecException.incompleteRangeAreaInterval(String markId, int rowIndex)`
  - `RangeAreaChartSeries _lowerRangeArea<T>(RangeAreaMark<T> mark, String id, YAxisConfig axis, List<T> data)`

- [ ] **Step 1: Write the failing tests**

Append a new group to `test/unit/grammar/plot_lowering_parity_test.dart`:

```dart
  group('range area lowering', () {
    test('lowers to a RangeAreaChartSeries carrying every native field', () {
      final lowered = BravenChart.of(_bandRows)
          .x((row) => row.x)
          .geomRangeArea(
            id: 'band',
            low: (row) => row.low,
            high: (row) => row.high,
            name: 'Recovery',
            color: const Color(0xFF2563EB),
            unit: 'score',
            interpolation: LineInterpolation.monotone,
            tension: 0.4,
            fillOpacity: 0.22,
            borderMode: RangeAreaBorderMode.closed,
            upperBoundaryStyle: const RangeAreaBoundaryStyle(strokeWidth: 2),
            lowerBoundaryStyle: const RangeAreaBoundaryStyle(glowRadius: 3),
            connectGaps: true,
            showBoundaryMarkers: true,
            markerRadius: 4,
            labelConfig: const RangeAreaLabelConfig(
              value: RangeAreaLabelValue.both,
            ),
            hitTestMode: RangeAreaHitTestMode.nearestBoundary,
          )
          .toSpec()
          .lower();

      final series = lowered.series.single as RangeAreaChartSeries;
      expect(series.id, 'band');
      expect(series.name, 'Recovery');
      expect(series.color, const Color(0xFF2563EB));
      expect(series.unit, 'score');
      expect(series.interpolation, LineInterpolation.monotone);
      expect(series.tension, 0.4);
      expect(series.fillOpacity, 0.22);
      expect(series.borderMode, RangeAreaBorderMode.closed);
      expect(series.upperBoundaryStyle.strokeWidth, 2);
      expect(series.lowerBoundaryStyle.glowRadius, 3);
      expect(series.connectGaps, isTrue);
      expect(series.showBoundaryMarkers, isTrue);
      expect(series.markerRadius, 4);
      expect(series.labelConfig.value, RangeAreaLabelValue.both);
      expect(series.hitTestMode, RangeAreaHitTestMode.nearestBoundary);
      expect(series.intervals.first.low, 1);
      expect(series.intervals.first.high, 3);
    });

    test('an unset field lowers to the series default, not to a copy of it', () {
      // The assertion is against a FRESHLY CONSTRUCTED series, so it tracks the
      // class rather than restating today's literals. A default that changed on
      // RangeAreaChartSeries and not in the lowering fails here.
      final reference = RangeAreaChartSeries(
        id: 'reference',
        points: <RangeAreaDataPoint>[RangeAreaDataPoint(x: 0, low: 1, high: 3)],
      );

      final lowered = BravenChart.of(_bandRows)
          .x((row) => row.x)
          .geomRangeArea(low: (row) => row.low, high: (row) => row.high)
          .toSpec()
          .lower();

      final series = lowered.series.single as RangeAreaChartSeries;
      expect(series.interpolation, reference.interpolation);
      expect(series.tension, reference.tension);
      expect(series.fillOpacity, reference.fillOpacity);
      expect(series.borderMode, reference.borderMode);
      expect(series.upperBoundaryStyle, reference.upperBoundaryStyle);
      expect(series.lowerBoundaryStyle, reference.lowerBoundaryStyle);
      expect(series.connectGaps, reference.connectGaps);
      expect(series.showBoundaryMarkers, reference.showBoundaryMarkers);
      expect(series.markerRadius, reference.markerRadius);
      expect(series.labelConfig, reference.labelConfig);
      expect(series.hitTestMode, reference.hitTestMode);
    });

    test('both bounds null lowers that row to a gap', () {
      const rows = <_BandRow>[
        _BandRow(0, 1, 3),
        _BandRow(1, null, null),
        _BandRow(2, 2, 4),
      ];

      final lowered = BravenChart.of(rows)
          .x((row) => row.x)
          .geomRangeArea(low: (row) => row.low, high: (row) => row.high)
          .toSpec()
          .lower();

      final series = lowered.series.single as RangeAreaChartSeries;
      expect(series.hasGaps, isTrue);
      expect(series.intervals.map((i) => i.isGap), <bool>[false, true, false]);
      expect(series.intervals[1].x, 2 - 1); // the gap keeps its own x
    });

    test('exactly one bound null is refused by NAME with the row index', () {
      const rows = <_BandRow>[_BandRow(0, 1, 3), _BandRow(1, 2, null)];

      expect(
        () => BravenChart.of(rows)
            .x((row) => row.x)
            .geomRangeArea(
              id: 'band',
              low: (row) => row.low,
              high: (row) => row.high,
            )
            .toSpec()
            .lower(),
        throwsA(
          isA<GrammarSpecException>()
              .having(
                (e) => e.code,
                'code',
                GrammarDiagnosticCode.incompleteRangeAreaInterval,
              )
              .having((e) => e.message, 'message', contains('Row 1'))
              .having((e) => e.message, 'message', contains('"band"')),
        ),
      );
    });

    test('unsorted rows are refused by NAME, not as a raw ArgumentError', () {
      const rows = <_BandRow>[_BandRow(1, 1, 3), _BandRow(0, 2, 4)];

      expect(
        () => BravenChart.of(rows)
            .x((row) => row.x)
            .geomRangeArea(
              id: 'band',
              low: (row) => row.low,
              high: (row) => row.high,
            )
            .toSpec()
            .lower(),
        throwsA(
          isA<GrammarSpecException>().having(
            (e) => e.code,
            'code',
            GrammarDiagnosticCode.invalidRangeAreaRow,
          ),
        ),
      );
    });

    test('high < low is refused by NAME rather than escaping as ArgumentError', () {
      const rows = <_BandRow>[_BandRow(0, 5, 1)];

      expect(
        () => BravenChart.of(rows)
            .x((row) => row.x)
            .geomRangeArea(
              id: 'band',
              low: (row) => row.low,
              high: (row) => row.high,
            )
            .toSpec()
            .lower(),
        throwsA(
          isA<GrammarSpecException>().having(
            (e) => e.code,
            'code',
            GrammarDiagnosticCode.invalidRangeAreaRow,
          ),
        ),
      );
    });

    test('per-point label and key reach the lowered points', () {
      final lowered = BravenChart.of(_bandRows)
          .x((row) => row.x)
          .geomRangeArea(
            low: (row) => row.low,
            high: (row) => row.high,
            label: (row) => 'point-${row.x.toInt()}',
            pointKey: (row) => 'key-${row.x.toInt()}',
          )
          .toSpec()
          .lower();

      final series = lowered.series.single as RangeAreaChartSeries;
      expect(series.intervals.first.label, 'point-0');
      expect(series.intervals.first.pointKey, 'key-0');
    });

    test('a duplicate point key is refused, as on every other Cartesian mark', () {
      expect(
        () => BravenChart.of(_bandRows)
            .x((row) => row.x)
            .geomRangeArea(
              id: 'band',
              low: (row) => row.low,
              high: (row) => row.high,
              pointKey: (row) => 'same',
            )
            .toSpec()
            .lower(),
        throwsA(
          isA<GrammarSpecException>().having(
            (e) => e.code,
            'code',
            GrammarDiagnosticCode.duplicatePointKey,
          ),
        ),
      );
    });
  });
```

Add the fixture at the bottom of the file:

```dart
class _BandRow {
  const _BandRow(this.x, this.low, this.high);
  final double x;
  final double? low;
  final double? high;
}

const List<_BandRow> _bandRows = <_BandRow>[
  _BandRow(0, 1, 3),
  _BandRow(1, 2, 4),
];
```

- [ ] **Step 2: Run to verify it fails**

Run: `flutter test test/unit/grammar/plot_lowering_parity_test.dart`
Expected: FAIL to compile — non-exhaustive switches plus undefined diagnostic codes.

- [ ] **Step 3: Add the diagnostics**

In `lib/src/grammar/grammar_diagnostics.dart`, add to the enum right after `invalidCandlestickRow` (line 54):

```dart
  /// A range-area row broke the band's ordering or interval invariants.
  invalidRangeAreaRow,

  /// A range-area geom supplied only one of the two interval bounds at a row.
  incompleteRangeAreaInterval,
```

and the two factories after `GrammarSpecException.invalidCandlestickRow` (after line 287):

```dart
  /// A range-area row broke the band's ordering or interval invariants.
  factory GrammarSpecException.invalidRangeAreaRow(
    String markId,
    int rowIndex,
    String reason,
  ) => GrammarSpecException(
    GrammarDiagnosticCode.invalidRangeAreaRow,
    'Row $rowIndex of the range-area mark "$markId" is not a valid interval: '
    '$reason',
  );

  /// A range-area row supplied one bound and not the other.
  factory GrammarSpecException.incompleteRangeAreaInterval(
    String markId,
    int rowIndex,
  ) => GrammarSpecException(
    GrammarDiagnosticCode.incompleteRangeAreaInterval,
    'Row $rowIndex of the range-area mark "$markId" supplied one of low/high '
    'and not the other. Return null from BOTH to express a gap, or give the '
    'row a complete interval — a half-specified interval has no defensible '
    'reading.',
  );
```

- [ ] **Step 4: Close the lowering**

In `lib/src/grammar/plot_lowering.dart`:

**(a)** Add the imports beside the existing model imports:

```dart
import '../models/range_area_chart_series.dart';
import '../models/range_area_data_point.dart';
import '../models/range_area_style.dart';
```

**(b)** Add the defaults instance beside the others (after `_scatterDefaults`, around line 140). It is `final`, not `const`, because `RangeAreaChartSeries`'s constructor has a validating body — Dart initialises a top-level `final` lazily, so this costs nothing until a band is lowered:

```dart
/// Not `const`: `RangeAreaChartSeries` validates in its constructor body. Read
/// only for its DEFAULTS, so the empty point list is deliberate.
final RangeAreaChartSeries _rangeAreaDefaults = RangeAreaChartSeries(
  id: '',
  points: const <RangeAreaDataPoint>[],
);
```

**(c)** Extend the `geometryIds` `is`-chain (lines 299–307) so it matches the builder's `_geometryIds`:

```dart
      if (spec.marks[index] is LineMark<T> ||
          spec.marks[index] is AreaMark<T> ||
          spec.marks[index] is BarMark<T> ||
          spec.marks[index] is ScatterMark<T> ||
          spec.marks[index] is CandlestickMark<T> ||
          spec.marks[index] is RangeAreaMark<T>)
```

**(d)** In the structural pass switch, add after the `CandlestickMark<T>()` arm (line 360-367):

```dart
      case RangeAreaMark<T>():
        boundAxes[index] = _bindAxis(
          mark,
          markId,
          axes,
          axesById,
          boundAxisIds,
        );
        _validatePointKeys(mark.pointKey, markId, spec.data);
```

**(e)** In the materialization switch, add after the `CandlestickMark<T>()` arm (line 448-449):

```dart
      case RangeAreaMark<T>():
        series.add(_lowerRangeArea(mark, markId, axis!, spec.data));
```

**(f)** In `_validateLogPositive`'s switch, add after the `CandlestickMark<T>()` arm (line 539-546):

```dart
    case RangeAreaMark<T>():
      if (xLog) check(mark.x);
      if (yLog) {
        // A gap positions nothing, so it cannot be non-positive. The bounds of
        // a real interval both land on the Y scale and are both checked.
        for (final row in data) {
          final low = mark.low(row);
          final high = mark.high(row);
          if (low != null && low <= 0) {
            throw GrammarSpecException.nonPositiveLogValue(markId, low);
          }
          if (high != null && high <= 0) {
            throw GrammarSpecException.nonPositiveLogValue(markId, high);
          }
        }
      }
```

The local `check` helper takes a total `FieldAccessor<T, num>`, so the nullable bounds are walked inline rather than through it.

**(g)** Add `_lowerRangeArea` after `_lowerCandlestick` (after line 1001):

```dart
/// Materializes a range-area band.
///
/// Two row shapes are legal and one is not: both bounds present is an interval,
/// both absent is a gap, exactly one present is an authoring error. The
/// constructor's own `ArgumentError`s — a non-finite bound, `high < low`, an x
/// that did not increase — are translated to `invalidRangeAreaRow` so a grammar
/// author gets a grammar diagnostic naming the row rather than a raw model
/// error, exactly as `_lowerCandlestick` does.
RangeAreaChartSeries _lowerRangeArea<T>(
  RangeAreaMark<T> mark,
  String id,
  YAxisConfig axis,
  List<T> data,
) {
  final points = <RangeAreaDataPoint>[];
  for (var index = 0; index < data.length; index++) {
    final row = data[index];
    final x = mark.x(row).toDouble();
    final low = mark.low(row);
    final high = mark.high(row);
    if ((low == null) != (high == null)) {
      throw GrammarSpecException.incompleteRangeAreaInterval(id, index);
    }
    try {
      points.add(
        low == null
            ? RangeAreaDataPoint.gap(
                x: x,
                label: _pointText(mark.label, row),
                pointKey: _pointText(mark.pointKey, row),
              )
            : RangeAreaDataPoint(
                x: x,
                low: low.toDouble(),
                high: high!.toDouble(),
                label: _pointText(mark.label, row),
                pointKey: _pointText(mark.pointKey, row),
              ),
      );
    } on ArgumentError catch (error) {
      throw GrammarSpecException.invalidRangeAreaRow(
        id,
        index,
        '${error.name ?? 'value'} ${error.message}.',
      );
    }
  }
  try {
    return RangeAreaChartSeries(
      id: id,
      name: mark.name,
      points: points,
      color: mark.color,
      unit: mark.unit,
      yAxisId: axis.id,
      yAxisConfig: axis,
      interpolation: mark.interpolation ?? _rangeAreaDefaults.interpolation,
      tension: mark.tension ?? _rangeAreaDefaults.tension,
      fillOpacity: mark.fillOpacity ?? _rangeAreaDefaults.fillOpacity,
      borderMode: mark.borderMode ?? _rangeAreaDefaults.borderMode,
      upperBoundaryStyle:
          mark.upperBoundaryStyle ?? _rangeAreaDefaults.upperBoundaryStyle,
      lowerBoundaryStyle:
          mark.lowerBoundaryStyle ?? _rangeAreaDefaults.lowerBoundaryStyle,
      connectGaps: mark.connectGaps ?? _rangeAreaDefaults.connectGaps,
      showBoundaryMarkers:
          mark.showBoundaryMarkers ?? _rangeAreaDefaults.showBoundaryMarkers,
      markerRadius: mark.markerRadius ?? _rangeAreaDefaults.markerRadius,
      labelConfig: mark.labelConfig ?? _rangeAreaDefaults.labelConfig,
      hitTestMode: mark.hitTestMode ?? _rangeAreaDefaults.hitTestMode,
    );
  } on ArgumentError catch (error) {
    // The series constructor re-validates the WHOLE band — the strictly
    // increasing x rule lives here, not on the point — so the ordering failure
    // surfaces from this call, not the loop above. `ArgumentError.name` carries
    // the offending index as `points[3].x`; the row number is recovered from it
    // so the diagnostic still names a row.
    final name = error.name ?? '';
    final match = RegExp(r'points\[(\d+)\]').firstMatch(name);
    throw GrammarSpecException.invalidRangeAreaRow(
      id,
      match == null ? 0 : int.parse(match.group(1)!),
      '$name ${error.message}.',
    );
  }
}
```

**(h)** In `lib/src/grammar/facet_partition.dart`, add an arm to `_axisAccessors`. A band's Y extent is BOTH bounds, and a gap contributes nothing — but the switch's return type is `List<FieldAccessor<T, num>>` (total accessors), which a nullable bound cannot satisfy. Wrap them so a gap reads as the band's own x-position value rather than crashing:

```dart
      RangeAreaMark<T>(:final x, :final low, :final high) =>
        axis == FacetAxis.x
            ? <FieldAccessor<T, num>>[x]
            : <FieldAccessor<T, num>>[
                // A facet's shared range is a MIN/MAX sweep, so a gap must
                // contribute a value that cannot widen it. Collapsing a gap onto
                // the other bound does exactly that; when both are null the row
                // is a gap on both sides and contributes 0-width at 0, matching
                // the placeholder `RangeAreaDataPoint.gap` itself stores.
                (row) => low(row) ?? high(row) ?? 0,
                (row) => high(row) ?? low(row) ?? 0,
              ],
```

- [ ] **Step 5: Run the tests to verify they pass**

Run: `flutter test test/unit/grammar/ && flutter analyze lib`
Expected: PASS; analyzer clean. The gap test's `expect(series.intervals[1].x, 2 - 1)` reads `1` — the gap keeps its own x.

- [ ] **Step 6: Commit Tasks 2 and 3 together**

```bash
git add lib/src/grammar/mark.dart lib/src/grammar/chart_builder.dart \
  lib/src/grammar/plot_lowering.dart lib/src/grammar/facet_partition.dart \
  lib/src/grammar/grammar_diagnostics.dart \
  test/unit/grammar/chart_builder_test.dart \
  test/unit/grammar/plot_lowering_parity_test.dart
git commit -m "feat(grammar): add the RangeAreaMark and geomRangeArea verb

low/high are nullable accessors because RangeAreaDataPoint.gap is a real point
a total accessor cannot express; both null is a gap, exactly one null is
refused by name. The mark carries range-area-native fields only — pathAnimation
and fillGradient stay named refusals on AreaMark until roadmap 1d fixes them
for every Cartesian family at once.

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

### Task 4: Public config seams

**Files:**
- Modify: `lib/src/source/chart_config_dart_emitter.dart` (public seams beside `emitBarLabelStyle`, around line 204)
- Test: `test/unit/source/chart_config_dart_emitter_range_area_test.dart` (whichever existing file covers `_emitRangeAreaOptions` — locate with `grep -rln "_emitRangeArea\|RangeAreaBoundaryStyle(" test/unit/source/`; if none covers it, create `test/unit/source/chart_config_range_area_seams_test.dart`)

**Interfaces:**
- Consumes: the existing private `_emitRangeAreaBoundaryStyle` / `_emitRangeAreaLabelConfig`.
- Produces, on `ChartConfigDartEmitter`:
  - `void emitRangeAreaBoundaryStyle(DartSourceWriter writer, String argument, RangeAreaBoundaryStyle style)`
  - `void emitRangeAreaLabelConfig(DartSourceWriter writer, RangeAreaLabelConfig config, int seriesIndex)`

The seams exist so the grammar form and the config form render the same nested literals from one body. A second hand-written renderer in the grammar generator is exactly the drift `emitBarLabelStyle` and `emitRadialStyle` were introduced to stop.

- [ ] **Step 1: Write the failing test**

```dart
// Copyright 2026 Braven Charts
// SPDX-License-Identifier: MIT

/// The range-area nested-config seams, pinned as ONE body.
///
/// The grammar geom verb and the config form take the same nested literals. Two
/// renderers would drift the first time a field landed on only one of them, and
/// nothing else in the suite compares the two forms field by field — so these
/// tests assert the seam and the config path produce IDENTICAL text.
library;

import 'package:braven_charts/src/models/range_area_style.dart';
import 'package:braven_charts/src/source/chart_config_dart_emitter.dart';
import 'package:braven_charts/src/source/dart_source_writer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('emitRangeAreaBoundaryStyle writes the argument it is given', () {
    final writer = DartSourceWriter();
    _emitter().emitRangeAreaBoundaryStyle(
      writer,
      'upperBoundaryStyle',
      const RangeAreaBoundaryStyle(strokeWidth: 2.5, glowRadius: 3),
    );

    final source = writer.toString();
    expect(source, contains('upperBoundaryStyle: RangeAreaBoundaryStyle('));
    expect(source, contains('strokeWidth: 2.5,'));
    expect(source, contains('glowRadius: 3.0,'));
  });

  test('emitRangeAreaBoundaryStyle writes NOTHING for the family default', () {
    final writer = DartSourceWriter();
    _emitter().emitRangeAreaBoundaryStyle(
      writer,
      'lowerBoundaryStyle',
      const RangeAreaBoundaryStyle(),
    );

    expect(writer.toString(), isEmpty);
  });

  test('emitRangeAreaLabelConfig writes the label body', () {
    final writer = DartSourceWriter();
    _emitter().emitRangeAreaLabelConfig(
      writer,
      const RangeAreaLabelConfig(value: RangeAreaLabelValue.both, boundaryGap: 6),
      0,
    );

    final source = writer.toString();
    expect(source, contains('labelConfig: RangeAreaLabelConfig('));
    expect(source, contains('value: RangeAreaLabelValue.both,'));
    expect(source, contains('boundaryGap: 6.0,'));
  });
}
```

`_emitter()` builds a `ChartConfigDartEmitter` over a minimal snapshot. Copy the construction helper from whichever existing `test/unit/source/chart_config_dart_emitter*_test.dart` file already builds one — do not invent a second construction path.

- [ ] **Step 2: Run to verify it fails**

Run: `flutter test test/unit/source/chart_config_range_area_seams_test.dart`
Expected: FAIL — "The method 'emitRangeAreaBoundaryStyle' isn't defined".

- [ ] **Step 3: Add the seams**

In `lib/src/source/chart_config_dart_emitter.dart`, beside `emitBarLabelStyle` (after line 205):

```dart
  /// Writes `<argument>: RangeAreaBoundaryStyle(...)` — the field body the
  /// `geomRangeArea` verb hands to its `upperBoundaryStyle:` /
  /// `lowerBoundaryStyle:` arguments, which are the config form's argument names
  /// too. Writes NOTHING for the family default (unless `includeDefaultValues`),
  /// so the caller can pass it unconditionally.
  void emitRangeAreaBoundaryStyle(
    DartSourceWriter writer,
    String argument,
    RangeAreaBoundaryStyle style,
  ) => _emitRangeAreaBoundaryStyle(writer, argument, style);

  /// Writes `labelConfig: RangeAreaLabelConfig(...)` — the same body the config
  /// form emits, including the `formatter:` placeholder and its
  /// `runtimeValueOmitted` warning. [seriesIndex] only addresses that warning's
  /// JSON path.
  void emitRangeAreaLabelConfig(
    DartSourceWriter writer,
    RangeAreaLabelConfig config,
    int seriesIndex,
  ) => _emitRangeAreaLabelConfig(writer, config, seriesIndex);
```

Thread `seriesIndex` through the private renderer, so the warning added in Task 5 can address the right series. Change the signature at line 1969 to `void _emitRangeAreaLabelConfig(DartSourceWriter writer, RangeAreaLabelConfig config, int seriesIndex)`; change `_emitRangeAreaOptions`'s signature at line 1899 to take `int seriesIndex` and its call at line 1938 to `_emitRangeAreaLabelConfig(writer, series.labelConfig, seriesIndex)`; change the call site at line 602 to `_emitRangeAreaOptions(writer, series, seriesIndex)`.

- [ ] **Step 4: Run the tests to verify they pass**

Run: `flutter test test/unit/source/ && flutter analyze lib`
Expected: PASS; analyzer clean. **Existing config-emitter tests must be untouched** — threading an index changes no emitted byte.

- [ ] **Step 5: Commit**

```bash
git add lib/src/source/chart_config_dart_emitter.dart \
  test/unit/source/chart_config_range_area_seams_test.dart
git commit -m "refactor(source): expose the range-area nested-config seams

The grammar geom verb takes the same boundary-style and label-config literals
the config form does. One body, two callers — the drift emitBarLabelStyle and
emitRadialStyle already exist to prevent.

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

### Task 5: Emitter reversal

**Files:**
- Modify: `lib/src/source/chart_grammar_source_generator.dart` — `_isEmittableFamily` (~1708), `_familyWord` (~2059), `_firstUncarriedField` (~2089), `_planGeometry` (~2463), `_fillRows` (~2820), `_emitGeometry` (~3337)
- Test: `test/unit/source/chart_grammar_source_generator_test.dart`

**Interfaces:**
- Consumes: `RangeAreaMark` (Task 2), `_lowerRangeArea` (Task 3), the seams (Task 4), the unbinding arm (Task 1).
- Produces: a `.geomRangeArea(` chain for any captured `RangeAreaChartSeries` whose fields the mark carries; a NAMED refusal otherwise.

- [ ] **Step 1: Write the failing tests**

Append to the generator test file, in the group that holds the other round-trip shapes:

```dart
    testWidgets('a range-area band round-trips through a geomRangeArea chain', (
      tester,
    ) async {
      final generated = generateGrammar(
        await snapshotOf(tester, (controller) {
          return BravenChartPlus(
            series: <ChartSeries>[
              RangeAreaChartSeries(
                id: 'band',
                name: 'Recovery',
                color: const Color(0xFF2563EB),
                interpolation: LineInterpolation.monotone,
                fillOpacity: 0.16,
                showBoundaryMarkers: true,
                points: <RangeAreaDataPoint>[
                  RangeAreaDataPoint(x: 0, low: 42, high: 62, pointKey: 'r0'),
                  RangeAreaDataPoint(x: 1, low: 44, high: 66, pointKey: 'r1'),
                ],
              ),
            ],
            bravenChartController: controller,
          );
        }),
      );

      expect(generated.source, contains('= BravenChart.of('));
      expect(generated.source, contains('.geomRangeArea('));
      expect(generated.warnings, isEmpty);
      expect(generated.isComplete, isTrue);
    });

    testWidgets('a range-area gap survives the reversal as a gap', (
      tester,
    ) async {
      final generated = generateGrammar(
        await snapshotOf(tester, (controller) {
          return BravenChartPlus(
            series: <ChartSeries>[
              RangeAreaChartSeries(
                id: 'band',
                points: <RangeAreaDataPoint>[
                  RangeAreaDataPoint(x: 0, low: 1, high: 3),
                  RangeAreaDataPoint.gap(x: 1),
                  RangeAreaDataPoint(x: 2, low: 2, high: 4),
                ],
              ),
            ],
            bravenChartController: controller,
          );
        }),
      );

      // The proof compares the re-lowered band against the captured one, so a
      // gap that came back as an interval would BLOCK rather than emit. That
      // the chain exists at all is the assertion; the null literals confirm the
      // row shape a reader would copy.
      expect(generated.source, contains('.geomRangeArea('));
      expect(generated.source, contains('null'));
      expect(generated.warnings, isEmpty);
    });

    testWidgets('a band carrying a 1d field is refused BY NAME', (tester) async {
      final generated = generateGrammar(
        await snapshotOf(tester, (controller) {
          return BravenChartPlus(
            series: <ChartSeries>[
              RangeAreaChartSeries(
                id: 'band',
                pathAnimation: const PathAnimationStyle(
                  entranceMode: PathEntranceAnimationMode.draw,
                ),
                points: <RangeAreaDataPoint>[
                  RangeAreaDataPoint(x: 0, low: 1, high: 3),
                  RangeAreaDataPoint(x: 1, low: 2, high: 4),
                ],
              ),
            ],
            bravenChartController: controller,
          );
        }),
      );

      expect(generated.source, isNot(contains('= BravenChart.of(')));
      expect(
        generated.warnings.single.message,
        contains('a path animation'),
        reason:
            'a field the mark deliberately does not carry must be named, not '
            'dropped: ${generated.warnings.map((w) => w.message).join('\n')}',
      );
    });

    testWidgets('a band carrying a fill gradient is refused BY NAME', (
      tester,
    ) async {
      final generated = generateGrammar(
        await snapshotOf(tester, (controller) {
          return BravenChartPlus(
            series: <ChartSeries>[
              RangeAreaChartSeries(
                id: 'band',
                fillGradient: const AreaGradient(
                  colors: <Color>[Color(0xFF2563EB), Color(0x002563EB)],
                ),
                points: <RangeAreaDataPoint>[
                  RangeAreaDataPoint(x: 0, low: 1, high: 3),
                  RangeAreaDataPoint(x: 1, low: 2, high: 4),
                ],
              ),
            ],
            bravenChartController: controller,
          );
        }),
      );

      expect(generated.source, isNot(contains('= BravenChart.of(')));
      expect(generated.warnings.single.message, contains('a fill gradient'));
    });

    testWidgets('a band beside a line on a legacy single-axis chart emits', (
      tester,
    ) async {
      // The regression guard for the blocker this slice opened with. Both series
      // are unbound, so the chain must mount the LEGACY single-axis shape; a
      // range area that could not be unbound would refuse here through a tail
      // that names no field.
      final generated = generateGrammar(
        await snapshotOf(tester, (controller) {
          return BravenChartPlus(
            series: <ChartSeries>[
              RangeAreaChartSeries(
                id: 'band',
                points: <RangeAreaDataPoint>[
                  RangeAreaDataPoint(x: 0, low: 1, high: 3),
                  RangeAreaDataPoint(x: 1, low: 2, high: 4),
                ],
              ),
              LineChartSeries(
                id: 'centre',
                points: const <ChartDataPoint>[
                  ChartDataPoint(x: 0, y: 2),
                  ChartDataPoint(x: 1, y: 3),
                ],
              ),
            ],
            bravenChartController: controller,
          );
        }),
      );

      expect(generated.source, contains('.geomRangeArea('));
      expect(generated.source, contains('.geomLine('));
      expect(generated.warnings, isEmpty);
    });
```

Add any missing imports the fixtures need (`range_area_chart_series.dart` etc. come through `package:braven_charts/braven_charts.dart`, which the file already imports).

- [ ] **Step 2: Run to verify it fails**

Run: `flutter test test/unit/source/chart_grammar_source_generator_test.dart`
Expected: FAIL — the round-trip cases report no `.geomRangeArea(`; `_isEmittableFamily` still returns false so the chart is blocked as "no grammar geometry".

- [ ] **Step 3: Open the gate and name the family**

`_isEmittableFamily` (line 1708) — add the arm and fix the docstring, which currently says range area stays refused:

```dart
  /// Whether a grammar geometry exists that reverses [series]. Covers the five
  /// Cartesian families, range area, and the radial families the grammar lowers
  /// (pie, donut, polar-column). Radial-bar and gauge stay refused — they have
  /// no `geom*` verb and no `Mark` subtype.
  bool _isEmittableFamily(ChartSeries series) => switch (series) {
    CandlestickChartSeries() => true,
    LineChartSeries() => true,
    ScatterChartSeries() => true,
    AreaChartSeries() => true,
    BarChartSeries() => true,
    RangeAreaChartSeries() => true,
    PieChartSeries() => true,
    DonutChartSeries() => true,
    PolarColumnChartSeries() => true,
    _ => false,
  };
```

`_familyWord` (line 2059) — add `RangeAreaChartSeries() => 'range-area',` after the candlestick arm.

`_firstUncarriedField` (line 2089) — add the arm after `case CandlestickChartSeries():`. **This is what turns the 1d refusals into named ones**; without it they fall to the generic tail that names nothing:

```dart
      case RangeAreaChartSeries():
        final actual = lowered as RangeAreaChartSeries;
        // Roadmap 1d, and named rather than dropped: the mark deliberately does
        // not carry either, so a band using one must say WHICH.
        if (expected.fillGradient != actual.fillGradient) {
          return 'a fill gradient';
        }
        if (expected.pathAnimation != actual.pathAnimation) {
          return 'a path animation';
        }
```

Also update the doc-comment block at line 39 and the refusal sentence at line 581 so neither still lists range-area among the families with no grammar geometry.

- [ ] **Step 4: Plan, fill and emit**

**(a)** `_planGeometry` (line 2463) — add the arm after `case CandlestickChartSeries():`:

```dart
      case RangeAreaChartSeries():
        final low = _addField(
          _suffixed(base, 'low'),
          _FieldKind.optionalNumber,
        );
        final high = _addField(
          _suffixed(base, 'high'),
          _FieldKind.optionalNumber,
        );
        accessors
          ..['low'] = low
          ..['high'] = high;
        final label = _planPointText(series, base, 'label');
        final pointKey = _planPointText(series, base, 'pointKey');
        if (label != null) accessors['label'] = label;
        if (pointKey != null) accessors['pointKey'] = pointKey;
        return _GeometryPlan(
          series: series,
          accessors: accessors,
          mark: RangeAreaMark<_SourceRow>(
            id: id,
            name: name,
            color: color,
            unit: unit,
            yAxisId: yAxisId,
            x: x,
            low: _nullableNumber(low),
            high: _nullableNumber(high),
            label: label == null ? null : _text(label),
            pointKey: pointKey == null ? null : _text(pointKey),
            // Null when the captured value IS the family default, so a plain
            // band emits none of these. The comparisons read the defaults off a
            // freshly built series rather than restating literals here.
            interpolation: _defaultedOrNull(
              series.interpolation,
              _rangeAreaEmitDefaults.interpolation,
            ),
            tension: _defaultedOrNull(
              series.tension,
              _rangeAreaEmitDefaults.tension,
            ),
            fillOpacity: _defaultedOrNull(
              series.fillOpacity,
              _rangeAreaEmitDefaults.fillOpacity,
            ),
            borderMode: _defaultedOrNull(
              series.borderMode,
              _rangeAreaEmitDefaults.borderMode,
            ),
            upperBoundaryStyle: _defaultedOrNull(
              series.upperBoundaryStyle,
              _rangeAreaEmitDefaults.upperBoundaryStyle,
            ),
            lowerBoundaryStyle: _defaultedOrNull(
              series.lowerBoundaryStyle,
              _rangeAreaEmitDefaults.lowerBoundaryStyle,
            ),
            connectGaps: _defaultedOrNull(
              series.connectGaps,
              _rangeAreaEmitDefaults.connectGaps,
            ),
            showBoundaryMarkers: _defaultedOrNull(
              series.showBoundaryMarkers,
              _rangeAreaEmitDefaults.showBoundaryMarkers,
            ),
            markerRadius: _defaultedOrNull(
              series.markerRadius,
              _rangeAreaEmitDefaults.markerRadius,
            ),
            labelConfig: _defaultedOrNull(
              series.labelConfig,
              _rangeAreaEmitDefaults.labelConfig,
            ),
            hitTestMode: _defaultedOrNull(
              series.hitTestMode,
              _rangeAreaEmitDefaults.hitTestMode,
            ),
          ),
        );
```

Use whatever per-point-text planning helper `_planGeometry`'s line/area arms already call; the names above (`_planPointText`, `_text`) follow those arms — read lines 2509–2560 and match them exactly rather than introducing a variant.

Add the two file-level helpers near the other top-level helpers in the generator:

```dart
/// The captured value, or null when it IS the family default.
///
/// A mark field of null means "the series default", so mapping a defaulted
/// capture back to null is what keeps a plain band emitting no styling
/// arguments — and keeps the re-lowered series identical to the captured one,
/// since the lowering resolves that same default.
V? _defaultedOrNull<V>(V value, V fallback) => value == fallback ? null : value;

/// Read only for its DEFAULTS. Not `const`: the constructor validates in its
/// body.
final RangeAreaChartSeries _rangeAreaEmitDefaults = RangeAreaChartSeries(
  id: '',
  points: const <RangeAreaDataPoint>[],
);
```

**(b)** `_fillRows` (line 2820) — add the arm before `case ChartSeries():` (order matters: the `ChartSeries()` arm is the catch-all and would shadow it):

```dart
          case RangeAreaChartSeries():
            final interval = series.intervalAt(index);
            // A gap leaves BOTH slots null — that is the shape `_lowerRangeArea`
            // reads back as `RangeAreaDataPoint.gap`. The default `ChartSeries`
            // arm below would write `point.y`, which for a gap is the model's
            // zero placeholder, silently turning every gap into a real interval
            // at zero.
            row.optionalNumbers[plan.accessors['low']!.slot] = interval.low;
            row.optionalNumbers[plan.accessors['high']!.slot] = interval.high;
```

**(c)** `_emitGeometry` (line 3337) — three switches.

Verb switch, after the candlestick arm:

```dart
      RangeAreaMark<_SourceRow>() => 'geomRangeArea',
```

Accessor switch (line 3362) — a `case` BEFORE the `case _:` default, because that default writes `y:` and a band has none:

```dart
        case RangeAreaMark<_SourceRow>():
          writer.namedArgument('low', plan.accessors['low']!.accessor());
          writer.namedArgument('high', plan.accessors['high']!.accessor());
```

Family-argument switch (line 3415), after `case CandlestickMark<_SourceRow>(): break;` — emission order mirrors `_emitRangeAreaOptions` so the two forms read alike:

```dart
        case RangeAreaMark<_SourceRow>():
          if (mark.interpolation != null) {
            writer.namedArgument(
              'interpolation',
              'LineInterpolation.${mark.interpolation!.name}',
            );
          }
          _optionalNumber(writer, 'tension', mark.tension);
          _optionalNumber(writer, 'fillOpacity', mark.fillOpacity);
          if (mark.borderMode != null) {
            writer.namedArgument(
              'borderMode',
              'RangeAreaBorderMode.${mark.borderMode!.name}',
            );
          }
          if (mark.upperBoundaryStyle != null) {
            _config.emitRangeAreaBoundaryStyle(
              writer,
              'upperBoundaryStyle',
              mark.upperBoundaryStyle!,
            );
            _absorbConfigWarnings();
          }
          if (mark.lowerBoundaryStyle != null) {
            _config.emitRangeAreaBoundaryStyle(
              writer,
              'lowerBoundaryStyle',
              mark.lowerBoundaryStyle!,
            );
            _absorbConfigWarnings();
          }
          if (mark.connectGaps != null) {
            writer.namedArgument('connectGaps', '${mark.connectGaps}');
          }
          if (mark.showBoundaryMarkers != null) {
            writer.namedArgument(
              'showBoundaryMarkers',
              '${mark.showBoundaryMarkers}',
            );
          }
          _optionalNumber(writer, 'markerRadius', mark.markerRadius);
          if (mark.labelConfig != null) {
            _config.emitRangeAreaLabelConfig(writer, mark.labelConfig!, 0);
            _absorbConfigWarnings();
          }
          if (mark.hitTestMode != null) {
            writer.namedArgument(
              'hitTestMode',
              'RangeAreaHitTestMode.${mark.hitTestMode!.name}',
            );
          }
```

The `isXOrdered` switch at line 3407 needs **no** change: its `_ => false` arm already covers `RangeAreaMark`, which is correct — the series hard-codes the flag, exactly as candlestick does.

- [ ] **Step 5: Run the tests to verify they pass**

Run: `flutter test test/unit/source/chart_grammar_source_generator_test.dart && flutter analyze lib`
Expected: PASS; analyzer clean.

If the "band beside a line" case still blocks, the message names the culprit — read it rather than guessing. A generic residual tail there means the unbinding arm from Task 1 is not being reached.

- [ ] **Step 6: Verify no existing emission moved**

Run: `flutter test test/unit/source/ test/unit/grammar/`
Expected: PASS with the pre-slice counts. Any previously-pinned emitted source that changed is a regression — investigate, do not update the fixture.

- [ ] **Step 7: Commit**

```bash
git add lib/src/source/chart_grammar_source_generator.dart \
  test/unit/source/chart_grammar_source_generator_test.dart
git commit -m "feat(source): reverse a range-area band into a geomRangeArea chain

Plans low/high as optional-number row fields so a gap travels as two nulls —
the default _fillRows arm would have written the model's zero placeholder and
turned every gap into an interval at zero. fillGradient and pathAnimation are
named refusals rather than silent drops.

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

### Task 6: The label-formatter silent drop

**Files:**
- Modify: `lib/src/source/chart_config_dart_emitter.dart:1969-2032`
- Test: `test/unit/source/chart_config_range_area_seams_test.dart`

**Interfaces:**
- Consumes: `_emitRangeAreaLabelConfig`'s `seriesIndex` parameter (Task 4).
- Produces: a `// formatter:` placeholder line and one `runtimeValueOmitted` warning when `config.formatter != null`.

**Why the proof cannot catch this:** the mark carries `labelConfig` verbatim, so the round-trip comparison compares that instance against itself. And the drift gate cannot catch it either — `formatter` is omitted from the generated surface manifest (`'Omitted from this schema: formatter (callback — no JSON form)'`), so the class-aware slice never lists it as a property `RangeAreaLabelConfig` should emit. Callback fields sit in the blind spot of both mechanisms at once.

- [ ] **Step 1: Write the failing test**

Append to the seams test file:

```dart
  test('a live label formatter emits a placeholder AND warns', () {
    // Neither existing mechanism can catch this one. The grammar round-trip
    // compares the labelConfig instance against ITSELF (the mark carries it
    // verbatim), and the emitter drift gate never lists `formatter` because the
    // surface manifest omits it as a callback. So it is pinned here directly.
    final emitter = _emitter();
    final writer = DartSourceWriter();
    emitter.emitRangeAreaLabelConfig(
      writer,
      RangeAreaLabelConfig(
        value: RangeAreaLabelValue.both,
        formatter: (details) => '${details.value}',
      ),
      2,
    );

    expect(writer.toString(), contains('// formatter:'));
    final warning = emitter.warnings.singleWhere(
      (entry) => entry.path.contains('labelConfig.formatter'),
    );
    expect(warning.code, ChartSourceWarningCodes.runtimeValueOmitted);
    expect(warning.path, contains(r'$.series[2]'));
  });

  test('no formatter emits no placeholder and no warning', () {
    final emitter = _emitter();
    final writer = DartSourceWriter();
    emitter.emitRangeAreaLabelConfig(
      writer,
      const RangeAreaLabelConfig(value: RangeAreaLabelValue.both),
      0,
    );

    expect(writer.toString(), isNot(contains('// formatter:')));
    expect(emitter.warnings, isEmpty);
  });
```

Read how the existing emitter tests reach the accumulated warnings (`emitter.warnings` or the `ChartGeneratedSource.warnings` returned by a full `emit()`), and match that access path rather than adding a new accessor.

- [ ] **Step 2: Run to verify it fails**

Run: `flutter test test/unit/source/chart_config_range_area_seams_test.dart`
Expected: FAIL — no `// formatter:` in the output, and no warning recorded.

- [ ] **Step 3: Emit the placeholder**

In `_emitRangeAreaLabelConfig`, after `_numberIf(writer, 'boundaryGap', config.boundaryGap, 4);` (line 2029) and still inside the `writer.indented(() { ... })` block:

```dart
      if (config.formatter != null) {
        writer.writeLine(
          '// formatter: (details) => ..., // Supply application formatting.',
        );
        _warn(
          code: ChartSourceWarningCodes.runtimeValueOmitted,
          message:
              'A Range Area label formatter callback was omitted. Provide it from your application.',
          path: '\$.series[$seriesIndex].labelConfig.formatter',
        );
      }
```

`(details)` rather than `(point)`: `RangeAreaLabelFormatter` is `String Function(RangeAreaLabelDetails)`, so the placeholder must name what a user would actually receive.

- [ ] **Step 4: Run to verify it passes**

Run: `flutter test test/unit/source/ && flutter analyze lib`
Expected: PASS. Every other config-emitter test unchanged — a chart with no formatter emits exactly what it emitted before.

- [ ] **Step 5: Commit**

```bash
git add lib/src/source/chart_config_dart_emitter.dart \
  test/unit/source/chart_config_range_area_seams_test.dart
git commit -m "fix(source): stop dropping the Range Area label formatter silently

_emitRangeAreaLabelConfig emitted value, labels and boundaryGap and dropped
formatter with no warning. Neither guard could see it: the grammar proof
compares the labelConfig instance against itself, and the emitter drift gate
never lists formatter because the surface manifest omits callbacks. Pinned
directly instead.

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

### Task 7: Shape 44 — the whole-argument-list assertion

BC-0046 left every emitted grammar argument pinned. A new verb arrives with its own maximal-fixture whole-list assertion or it reopens the hole that slice closed.

**Files:**
- Test: `test/unit/source/chart_grammar_source_generator_test.dart` (beside shapes 36–39/42/43)

**Interfaces:**
- Consumes: everything above.
- Produces: no production code.

- [ ] **Step 1: Write the assertion**

```dart
    testWidgets(
      'shape 44: a MAXIMAL .geomRangeArea( pins its whole argument list',
      (tester) async {
        // MAXIMAL fixture for the RANGE-AREA surface: every optional
        // `_emitGeometry`'s range-area arm can write is set EXPLICITLY, so no
        // family default lands in the expected list and every conditional
        // emission path in that arm is live.
        //
        // The fixture is a HAND-WRITTEN SINGLE-BAND chart on purpose.
        // `literalArguments` slices from the FIRST occurrence of its opening
        // token, so on a two-band chart — which the selection lab, forecastFan
        // and interactionStates all are — this assertion would silently pin one
        // band and say nothing about the other. The `allMatches` guard below
        // makes that failure loud instead of invisible.
        //
        // `labelConfig.formatter` is the one field deliberately left null: its
        // emission is a comment plus a `runtimeValueOmitted` WARNING, which this
        // shape's `expect(warnings, isEmpty)` forbids by construction. It is not
        // claimed as covered here — it has its own test in the seams file.
        //
        // Deliberately NOT set: `yAxisId:` (this is a single-axis chart), and
        // `fillGradient`/`pathAnimation`, which the mark does not carry and
        // which are pinned as NAMED REFUSALS by their own cases.
        final generated = generateGrammar(
          await snapshotOf(tester, (controller) {
            return BravenChartPlus(
              series: <ChartSeries>[
                RangeAreaChartSeries(
                  id: 'band',
                  name: 'Recovery',
                  color: const Color(0xFF2563EB),
                  unit: 'score',
                  interpolation: LineInterpolation.monotone,
                  tension: 0.4,
                  fillOpacity: 0.22,
                  borderMode: RangeAreaBorderMode.closed,
                  upperBoundaryStyle: const RangeAreaBoundaryStyle(
                    visible: false,
                    color: Color(0xFF0F172A),
                    strokeWidth: 2.5,
                    dashPattern: <double>[5, 3],
                    glowRadius: 3,
                  ),
                  lowerBoundaryStyle: const RangeAreaBoundaryStyle(
                    visible: false,
                    color: Color(0xFFDB2777),
                    strokeWidth: 2,
                    dashPattern: <double>[4, 2],
                    glowRadius: 1,
                  ),
                  connectGaps: true,
                  showBoundaryMarkers: true,
                  markerRadius: 4,
                  labelConfig: const RangeAreaLabelConfig(
                    value: RangeAreaLabelValue.both,
                    boundaryGap: 6,
                    labels: DataPointLabelConfig(show: true),
                  ),
                  hitTestMode: RangeAreaHitTestMode.nearestBoundary,
                  points: <RangeAreaDataPoint>[
                    RangeAreaDataPoint(
                      x: 0,
                      low: 42,
                      high: 62,
                      label: 'day 0',
                      pointKey: 'r0',
                    ),
                    RangeAreaDataPoint(
                      x: 1,
                      low: 44,
                      high: 66,
                      label: 'day 1',
                      pointKey: 'r1',
                    ),
                  ],
                ),
              ],
              bravenChartController: controller,
            );
          }),
        );

        expect(generated.warnings, isEmpty);
        expect(generated.isComplete, isTrue);
        // MANDATORY: a second `.geomRangeArea(` would leave the assertion below
        // reading the wrong literal and pinning nothing about the other band.
        expect('.geomRangeArea('.allMatches(generated.source).length, 1);
        // No sub-assertion may open on `RangeAreaBoundaryStyle(` — it appears
        // TWICE inside this slice, so `literalArguments` would read the upper
        // style and silently say nothing about the lower.
        expect(
          'RangeAreaBoundaryStyle('.allMatches(generated.source).length,
          2,
        );
        expect(
          literalArguments(generated.source, '.geomRangeArea('),
          _expectedRangeAreaArguments,
        );

        // The list above pins the emitted TEXT; only `dart analyze` proves those
        // names exist on the real builder.
        await tester.runAsync(
          () => expectGeneratedSourceCompiles(
            generated.source,
            fixtureName: 'grammar_source_range_area_maximal',
          ),
        );
      },
    );
```

with the expected list declared beside the other shape constants:

```dart
/// Shape 44's expected argument list. Declared apart from the test only because
/// it is long; it is a whole-list equality, not a fragment set.
const List<String> _expectedRangeAreaArguments = <String>[
  "id: 'band',",
  'low: (row) => row.bandLow,',
  'high: (row) => row.bandHigh,',
  "name: 'Recovery',",
  'color: Color(0xFF2563EB),',
  "unit: 'score',",
  'label: (row) => row.bandLabel,',
  'pointKey: (row) => row.bandPointKey,',
  'interpolation: LineInterpolation.monotone,',
  'tension: 0.4,',
  'fillOpacity: 0.22,',
  'borderMode: RangeAreaBorderMode.closed,',
  'upperBoundaryStyle: RangeAreaBoundaryStyle(',
  'visible: false,',
  'color: Color(0xFF0F172A),',
  'strokeWidth: 2.5,',
  'dashPattern: [5.0, 3.0],',
  'glowRadius: 3.0,',
  '),',
  'lowerBoundaryStyle: RangeAreaBoundaryStyle(',
  'visible: false,',
  'color: Color(0xFFDB2777),',
  'strokeWidth: 2.0,',
  'dashPattern: [4.0, 2.0],',
  'glowRadius: 1.0,',
  '),',
  'connectGaps: true,',
  'showBoundaryMarkers: true,',
  'markerRadius: 4.0,',
  'labelConfig: RangeAreaLabelConfig(',
  'value: RangeAreaLabelValue.both,',
  'labels: DataPointLabelConfig(',
  'show: true,',
  '),',
  'boundaryGap: 6.0,',
  '),',
  'hitTestMode: RangeAreaHitTestMode.nearestBoundary,',
];
```

- [ ] **Step 2: Run it and reconcile against the ACTUAL emission**

Run: `flutter test test/unit/source/chart_grammar_source_generator_test.dart --plain-name 'shape 44'`

The list above is derived from the emitters' documented behaviour: synthesised field names come from `_addField(_suffixed(base, role))`, the boundary-style body from `_emitRangeAreaBoundaryStyle`, and the nested list literal from the CONFIG emitter's `_optionalNumberList` — which writes `[5.0, 3.0]`, **not** the grammar emitter's `<double>[5.0, 3.0]`. If the run disagrees:

- a **name** difference (`row.bandLow` vs `row.recoveryLow`) is the field-naming helper; take the emitted name.
- an **order** difference is the arm in Task 5, Step 4c; fix the ARM to the documented order, do not reorder the expectation.
- a **missing entry** is a writer that did not fire — find out why before touching either side.

Never rewrite the expectation to whatever came out without deciding which side is wrong. That is the exact failure mode this shape exists to prevent.

- [ ] **Step 3: Mutation-verify the assertion, both directions**

Per BC-0046's pattern, each mutation applied AND reverted inside a single shell invocation, and confirmed applied via `git diff --numstat` before the test runs.

Deletions (each must turn shape 44 red): the shared-prologue writers this fixture makes live (`id`, the `low`/`high` pair, `name`, `color`, `unit`, `label`, `pointKey`), and every statement the range-area arm reaches (`interpolation`, `tension`, `fillOpacity`, `borderMode`, the two boundary-style calls, `connectGaps`, `showBoundaryMarkers`, `markerRadius`, the `labelConfig` call, `hitTestMode`).

Addition: one unconditional `writer.namedArgument('probe', "'x'");` in the range-area arm must also turn it red.

Record the measured count — "N of N caught" with N stated — in the test's own comment. State the mutation set AND its size; a ratio with no denominator is not a result.

- [ ] **Step 4: Commit**

```bash
git add test/unit/source/chart_grammar_source_generator_test.dart
git commit -m "test(source): pin geomRangeArea's whole argument list (shape 44)

Single-band fixture on purpose — literalArguments reads only the first
occurrence, and every real range-area chart in the corpus mounts two. The
allMatches guards make that loud rather than invisible.

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

### Task 8: Mounted-page acceptance, census, docs

Acceptance is measured on the mounted page, never a transcribed fixture. That distinction has already cost this programme one wrong claim.

**Files:**
- Create: `example/test/showcase/selection_showcase_range_area_grammar_test.dart`
- Modify: `example/test/showcase/grammar_emission_census_test.dart:363-389`
- Modify: `doc/chart_grammar.md`, `doc/feature_matrix.md`, `CHANGELOG.md`

**Interfaces:**
- Consumes: everything above.
- Produces: no production code.

- [ ] **Step 1: Write the acceptance test**

Model it on `example/test/showcase/selection_showcase_concentric_grammar_test.dart`, which already mounts `SelectionShowcasePage`, drives the real family picker, reads the live document off the chart's own controller and holds the compile floor. Copy its `_pumpFamily`, `_generateGrammar` and `_argumentLines` helpers verbatim rather than writing variants.

```dart
// Copyright 2026 Braven Charts
// SPDX-License-Identifier: MIT

/// ACCEPTANCE for the selection lab's RANGE AREA family Grammar pane.
///
/// Asserted against the PAGE, never a transcription: `SelectionShowcasePage` is
/// mounted, its range-area family is selected through the real family picker,
/// the live document is read off that chart's OWN controller, and the grammar
/// generator runs on it.
///
/// This family is the deliverable of roadmap item 1b-1. The `RangeAreaChartsPage`
/// is NOT: every band there carries a non-default `pathAnimation` and six of
/// seven a `fillGradient`, both roadmap 1d and both named refusals on `AreaMark`
/// today. This lab's bands diverge only on range-area-native fields, which is
/// exactly why it is the honest measure of what the mark closes.
library;

import 'package:braven_charts/braven_charts.dart';
import 'package:braven_charts_example/showcase/pages/selection_showcase_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../test/helpers/generated_source_compile.dart';

void main() {
  testWidgets('ACCEPTANCE: the selection lab RANGE AREA family emits a '
      'COMPLETE grammar chain', (tester) async {
    await _pumpFamily(tester, 'rangeArea');

    final chart = _liveChart(tester);
    final bands = chart.series.whereType<RangeAreaChartSeries>().toList();
    final generated = _generateGrammar(tester, chart, 'rangeAreaSelectionChart');

    // Matched on the ASSIGNMENT: a refusal diagnostic quotes the chain's own
    // entry point while explaining why it does not fit, so `BravenChart.of(`
    // alone would pass for a blocked chart.
    expect(
      generated.source,
      contains('= BravenChart.of('),
      reason:
          "the selection lab's range-area family must emit a grammar chain, "
          'but got:\n${generated.source}',
    );
    expect(
      generated.warnings,
      isEmpty,
      reason: generated.warnings.map((warning) => warning.message).join('\n'),
    );
    expect(generated.isComplete, isTrue);

    // The family is TWO bands plus a centre line, and all three must reach the
    // chain — a one-band assertion would pass on a chain that dropped the other.
    expect(bands, hasLength(2), reason: 'the family must mount two bands');
    expect('.geomRangeArea('.allMatches(generated.source).length, bands.length);
    expect(generated.source, contains('.geomLine('));
    for (final band in bands) {
      expect(generated.source, contains("id: '${band.id}',"));
      expect(generated.source, contains("name: '${band.name}',"));
    }

    // Every point in this lab is keyed — selection is expressed against those
    // keys — so a chain that dropped `pointKey:` would render identically and
    // select differently.
    expect(generated.source, contains('pointKey: (row) =>'));

    // The FLOOR. Every assertion above reads the emitted TEXT, and text
    // assertions cannot tell a chain that would compile from one that only
    // looks right.
    await tester.runAsync(
      () => expectGeneratedSourceCompiles(
        generated.source,
        fixtureName: 'showcase_selection_range_area_grammar',
      ),
    );

    expect(tester.takeException(), isNull);
  });

  testWidgets("the bands' own styling survives the reversal", (tester) async {
    await _pumpFamily(tester, 'rangeArea');

    final chart = _liveChart(tester);
    final first = chart.series.whereType<RangeAreaChartSeries>().first;
    final generated = _generateGrammar(tester, chart, 'rangeAreaSelectionChart');

    // Read off the LIVE series, so this cannot drift from the page.
    expect(
      generated.source,
      contains('interpolation: LineInterpolation.${first.interpolation.name}'),
    );
    expect(generated.source, contains('fillOpacity: ${first.fillOpacity},'));
    expect(
      generated.source,
      contains('showBoundaryMarkers: ${first.showBoundaryMarkers},'),
    );
    expect(tester.takeException(), isNull);
  });
}
```

Append the three helpers from the concentric file, with the chart key changed to `'selection-chart-rangeArea'`.

- [ ] **Step 2: Run it and confirm the expected shape**

Run: `cd example && flutter test test/showcase/selection_showcase_range_area_grammar_test.dart`
Expected: PASS.

If `fillOpacity: ${first.fillOpacity}` does not match, it is a literal-formatting difference (`0.16` vs `0.16000000000000003`); switch that assertion to the value-parsing form `_argumentLines` supports, as the concentric test's second case does. Do not weaken it to a bare `contains('fillOpacity')`.

- [ ] **Step 3: Update the census**

Run the census first and read what it reports — the numbers below are the predicted delta, and the run is the authority:

Run: `cd example && flutter test test/showcase/grammar_emission_census_test.dart`

Expected changes in `grammar_emission_census_test.dart`:
- `_expectedPerPage['Selection']`: `<int>[10, 10, 7]` → `<int>[10, 10, 8]`
- `_expectedPerFamily[_Family.cartesian]`: `<int>[27, 113]` → `<int>[28, 113]`
- `_expectedEmitting`: `58` → `59`
- `_expectedPerPage['RangeArea']` stays `<int>[7, 7, 0]`. **That is the honest number and it is not a failure** — see the acceptance test's docstring.

If the run reports a different delta, the run wins; investigate any page that moved and was not predicted here before editing a single number.

- [ ] **Step 4: Update the docs**

`doc/chart_grammar.md`:
- Line ~111–120: the paragraph explaining that `RangeAreaChartSeries.points` follows the OHLC pattern now describes a shipped verb, not a deferral. Rewrite it to document `geomRangeArea(low:, high:)`, the both-null gap rule and the one-null diagnostic.
- Line ~849: the refusal list must drop range-area and keep radial-bar and gauge.
- Add `geomRangeArea` to the verb table beside `geomCandlestick`, with a note that `pathAnimation` and `fillGradient` are not carried (roadmap 1d).

`doc/feature_matrix.md`: move Range Area from "no grammar geometry" to grammar-authorable.

`CHANGELOG.md` — under the existing `## Unreleased` → `### Added`, appended as a new bullet. **Do not touch any dated, released section.**

```markdown
- A Range Area grammar geometry: `BravenChart.geomRangeArea(low:, high:)`,
  lowering to a real `RangeAreaChartSeries` and reversed back into generated
  Dart source. `low`/`high` are nullable accessors — returning null from both
  at a row expresses a gap (`RangeAreaDataPoint.gap`); returning null from
  exactly one raises `incompleteRangeAreaInterval`. The mark carries the
  range-area-native fields (interpolation, tension, fill opacity, border mode,
  both boundary styles, gap connection, boundary markers, marker radius, label
  configuration and hit-test mode); `fillGradient` and `pathAnimation` are not
  carried and a band using either is refused by name rather than emitted
  without it.
```

Under `### Fixed`, adding the section if `## Unreleased` does not already have one:

```markdown
- The generated config source no longer drops a `RangeAreaLabelConfig.formatter`
  silently. A live formatter now emits a `// formatter:` placeholder and a
  `source_runtime_value_omitted` warning, matching how bar and data-point label
  formatters are already reported.
```

- [ ] **Step 5: Run the full gate**

```bash
flutter test
cd example && flutter test && cd ..
flutter analyze lib
cd example && flutter analyze lib && cd ..
dart format $(git diff --name-only origin/master...HEAD -- '*.dart')
dart run tool/check_dart_format.dart
flutter test test/meta/
```

Expected: root suite green with the pre-slice count plus this slice's new tests; example suite green; both analyzers clean; format gate clean; **57/57 drift gates**.

If `test/meta/source_emitter_drift_test.dart` goes red, read which slice reports the gap — the `_seriesEmitMethods` entry for `RangeAreaChartSeries` may need `_emitRangeAreaLabelConfig` listed now that the index threads through it.

- [ ] **Step 6: Commit**

```bash
git add example/test/showcase/selection_showcase_range_area_grammar_test.dart \
  example/test/showcase/grammar_emission_census_test.dart \
  doc/chart_grammar.md doc/feature_matrix.md CHANGELOG.md
git commit -m "test(showcase): accept the selection lab's Range Area grammar pane

Mounted-page acceptance, not a transcription. Census: Selection 7 -> 8
emitting, 58 -> 59 overall. RangeAreaChartsPage stays 0 of 7 and that number is
recorded rather than rounded away — its bands are held by roadmap 1d fields.

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

## Verification summary (what the PR must be able to state)

- Root suite / example suite counts, before and after.
- `flutter analyze lib` and `example/lib` clean; format gate clean; **57/57** drift gates.
- Shape 44's mutation result as **N of N with N stated** — the deletion set enumerated, not summarised.
- The census delta, measured: `Selection [10,10,7] → [10,10,8]`, `_expectedEmitting 58 → 59`.
- **`RangeAreaChartsPage` still 0 of 7, stated plainly**, with the blocking fields named (`pathAnimation`, `fillGradient`, the companion lines' `dataPointMarkerRadius`, and `confidence`'s x-domain divergence).
- That Task 6 touches BC-0048's territory (the config emitter), flagged for review.

## Self-review notes

Checked against the spec:

- §Blocker → Task 1. §A (the mark) → Task 2. §B (plan shape) → Task 5. §C (authoring validation) → Task 3. §D (formatter) → Tasks 4 + 6. §E (BC-0046 obligation) → Task 7. §Testing and §Invariants → distributed, with the full gate in Task 8, Step 5.
- **One spec item is deliberately implemented differently from how the spec first described it.** The spec's first draft said "a one-line arm in each" of `seriesWithoutAxisBinding` and `_legacySingleAxisSeries`. Reading `braven_plot.dart:320` shows the latter *calls* the former, so it is one arm in one file — the spec has been corrected and Task 1 implements the corrected version.
- Names used consistently across tasks: `RangeAreaMark`, `geomRangeArea`, `_lowerRangeArea`, `_rangeAreaDefaults` (lowering) vs `_rangeAreaEmitDefaults` (generator — a separate library, so a separate instance), `emitRangeAreaBoundaryStyle`, `emitRangeAreaLabelConfig`, `invalidRangeAreaRow`, `incompleteRangeAreaInterval`.
- Two places name a helper the implementer must confirm against the real code rather than trust from here: `_planPointText`/`_text` in Task 5 (match the line/area arms) and `_emitter()`/`emitter.warnings` in Task 4 (match the existing emitter tests). Both are called out in-step rather than left to be discovered.
