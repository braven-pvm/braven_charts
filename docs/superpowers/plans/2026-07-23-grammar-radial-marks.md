# Grammar Radial/Polar Marks Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make Pie / Donut / Concentric Donut / Polar Column authorable through the `BravenChart` grammar via dedicated radial geoms (`geomPie`/`geomDonut`/`geomPolar`) that lower onto the existing radial config families, closing the grammar's geometry gap.

**Architecture:** Dedicated radial geoms (the Vega-Lite `arc`-mark lineage), each carrying its own channels. Three new sealed `Mark<T>` variants (`PieMark`/`DonutMark`/`PolarMark`) grouped under a new `sealed class RadialMark<T> extends Mark<T>` intermediate. A radial spec lowers through a dedicated radial branch in `plot_lowering.dart` that builds `PieChartSeries.fromMap` / `DonutChartSeries.fromMap` / `PolarColumnChartSeries.fromMap` (plus `ConcentricDonutConfig` for a ring channel), and reuses `.build()` / `BravenPlot` — no new terminal, no coordinate-transform engine.

**Tech Stack:** Dart 3 sealed classes + exhaustive `switch`, Flutter, `flutter_test`, `golden_toolkit`, the repo's `_TolerantGoldenFileComparator`.

## Global Constraints

Copied verbatim from `docs/superpowers/specs/2026-07-23-grammar-radial-marks-design.md`. Every task's requirements implicitly include this section.

- **One radial geom per spec.** More than one radial mark → `multipleRadialGeoms`.
- **Radial XOR Cartesian.** A radial mark plus any non-radial mark → `mixedCoordinateSystems`.
- **Marks hold functions → NO `copyWith`, NO `@chartSurface`** on the radial marks (they hold `FieldAccessor` functions, so they never enter the config-drift / surface-generation gates), exactly like the Cartesian marks.
- **Grammar lives in the CORE barrel.** The radial marks are declared inside the already-exported `lib/src/grammar/mark.dart`; no new file is added to `lib/braven_charts.dart`.
- **`flutter analyze lib` and `flutter analyze example/lib` must be clean — NOT root `flutter analyze`.** Root analyze fails on the vendored `packages/fleather`; CI runs `flutter analyze lib`. (Memory: `project_fleather_vendored_analyze`.)
- **Radial goldens use the repo's tolerant comparator (`_TolerantGoldenFileComparator`) from the start** — the cross-platform anti-aliasing lesson banked from the faceting PR (#92).
- **`.build()` is reused.** A radial spec lowers to a radial `BravenChartPlus`; there is NO new terminal (unlike a hypothetical `buildFaceted`).
- **`PlotSpec` adds no config-surface classes and touches no drift gate.** Non-radial authoring is unaffected; a Cartesian spec never enters the radial branch.
- **Chart-level options on a radial spec:** `title`/`subtitle`/`legend`/`theme` are forwarded; `grid`/`xAxis`/`yAxis`/`transposed` raise `axisOptionOnRadialSpec`; a faceted radial spec would raise `facetedRadialUnsupported` (dormant — see Deviations).
- **Accessors are top-level tear-offs, never inline closures** in every test and showcase, because `Mark`/`PlotSpec` have value equality and a closure compares by identity.

---

## Sealed-Mark Resolution (READ FIRST — decides the File Structure)

`Mark<T>` in `lib/src/grammar/mark.dart` is declared `sealed class Mark<T>` (line 42). Dart requires **every direct subtype of a `sealed` class to be declared in the SAME LIBRARY.** A standalone `lib/src/grammar/radial_mark.dart` is a *different* library (its own imports, no `part` relationship), so `class PieMark<T> extends Mark<T>` written there does **not compile** — the analyzer reports *"The class 'Mark' can't be extended outside of its library because it's a sealed class."*

**Chosen resolution: declare the radial marks directly inside `mark.dart`**, adding one `sealed class RadialMark<T> extends Mark<T>` intermediate plus three `final class PieMark<T>/DonutMark<T>/PolarMark<T> extends RadialMark<T>`. This:

1. **Compiles** — same library as the sealed base, the only shape that does without introducing `part`/`part of` machinery the grammar layer does not otherwise use.
2. **Follows the established pattern** — every existing mark variant (`LineMark`, `AreaMark`, … `PointMark`) is a `final class … extends Mark<T>` declared in `mark.dart`. The radial variants join them.
3. **Makes coordinate detection a single `is RadialMark<T>` check** and reduces the exhaustive-`switch` fallout (below) to **one `case RadialMark<T>()` arm per dispatch site** instead of three.

**Consequence — the spec's literal "Create `lib/src/grammar/radial_mark.dart`" is NOT followed** (see Deviations); the marks live in `mark.dart`, which the core barrel already exports, so **no `lib/braven_charts.dart` edit is needed** for the marks.

**Exhaustive-switch fallout (adding sealed subtypes breaks every exhaustive `switch` over `Mark`).** These sites must gain a `case RadialMark<…>()` arm to compile, and are fixed in Task 1:

| Site | Line | Handling |
|---|---|---|
| `lib/src/grammar/plot_lowering.dart` — structural switch | 233 | `case RadialMark<T>():` → `throw StateError` (unreachable: `_lower` returns via `_lowerRadial` before this runs) |
| `lib/src/grammar/plot_lowering.dart` — materialization switch | 282 | same |
| `lib/src/source/chart_grammar_source_generator.dart` — `verb` switch | 1581 | `case RadialMark<_SourceRow>():` → `throw StateError` (unreachable: the family gate rejects radial series at line 1240, so a radial mark is never planned) |
| `lib/src/source/chart_grammar_source_generator.dart` — field switch | 1613 | same |
| `test/unit/grammar/plot_spec_test.dart` — `geomOf` | 50 | add `RadialMark<Sample>() => 'radial',` arm |

The `is`-based checks in `chart_builder.dart` (`_geometryIds`, lines 170-179) and the `geometryIds` set in `plot_lowering.dart` (lines 205-213) do **not** break — only `switch` exhaustiveness does — so they need no change.

---

## File Structure

| File | Create/Modify | Responsibility |
|---|---|---|
| `lib/src/grammar/mark.dart` | Modify | Add `sealed class RadialMark<T> extends Mark<T>` (holds shared `category`/`value` accessors) + `final class PieMark<T>/DonutMark<T>/PolarMark<T>`. Add imports for the style/config types they hold. |
| `lib/src/grammar/plot_spec.dart` | Modify | Add `bool get isRadial`. |
| `lib/src/grammar/grammar_diagnostics.dart` | Modify | Add 5 diagnostic codes + factories: `mixedCoordinateSystems`, `multipleRadialGeoms`, `axisOptionOnRadialSpec`, `emptyRadialCategories`, `facetedRadialUnsupported`. |
| `lib/src/grammar/plot_lowering.dart` | Modify | `LoweredPlot` gains `concentricDonutConfig`/`polarChartConfig` fields; `_lower` branches to a new `_lowerRadial` when `spec.isRadial`; the radial branch builds the config families + runs the guards. Two Cartesian switches gain the unreachable `RadialMark` arm. |
| `lib/src/grammar/chart_builder.dart` | Modify | Add `geomPie` / `geomDonut` / `geomPolar` verbs (append a radial mark). |
| `lib/src/grammar/braven_plot.dart` | Modify | Forward `concentricDonutConfig`/`polarChartConfig` from the lowered plot to `BravenChartPlus`. |
| `lib/src/source/chart_grammar_source_generator.dart` | Modify | Add the two unreachable `case RadialMark<_SourceRow>()` arms so it compiles. |
| `test/unit/grammar/plot_spec_test.dart` | Modify | Add the `geomOf` `RadialMark` arm. |
| `test/unit/grammar/radial_marks_test.dart` | Create | Const-ness + `==`/`hashCode` of the radial marks. |
| `test/unit/grammar/chart_builder_radial_test.dart` | Create | Facade `geomPie`/`geomDonut`/`geomPolar` `toSpec()` equals the hand-written `PlotSpec`. Extended per phase. |
| `test/unit/grammar/plot_lowering_radial_test.dart` | Create | Channel→series mapping (concrete values), config parity, and diagnostics. Extended per phase. |
| `test/golden/grammar_radial/grammar_radial_golden_test.dart` | Create | One tolerant-comparator golden per family, authored via the grammar. Extended per phase. |
| `example/lib/showcase/pages/chart_grammar_page.dart` | Modify | Add the `radial` preset (pie/donut/concentric/polar sub-families) + hand-built equivalents. |
| `example/test/showcase/chart_grammar_radial_preset_test.dart` | Create | Widget smoke test: the radial preset renders each family without exception. |

`lib/braven_charts.dart` is **unchanged** — `mark.dart`, `plot_lowering.dart`, `plot_spec.dart`, `chart_builder.dart`, `grammar_diagnostics.dart`, `braven_plot.dart` and every radial config family (`pie_chart_series.dart`, `donut_chart_series.dart`, `polar_column_chart_series.dart`, `concentric_donut_config.dart`, `polar_chart_config.dart`) are already exported.

---

# Phase 1 — Pie (carries the shared radial scaffolding)

Phase 1 introduces the radial mark hierarchy, coordinate detection, all 5 diagnostics, the shared `_lowerRadial` guard sequence, the `LoweredPlot`/`BravenPlot` plumbing, and the full Pie vertical slice.

## Task 1: Radial mark hierarchy + sealed-switch repair

**Files:**
- Modify: `lib/src/grammar/mark.dart` (add imports after line 20; append the new classes after line 766)
- Modify: `lib/src/grammar/plot_lowering.dart:233` and `:282` (add the unreachable `RadialMark` arm to each switch)
- Modify: `lib/src/source/chart_grammar_source_generator.dart:1581` and `:1613` (add the unreachable `RadialMark<_SourceRow>` arm to each switch)
- Modify: `test/unit/grammar/plot_spec_test.dart:50` (add the `geomOf` arm)
- Test: `test/unit/grammar/radial_marks_test.dart` (create)

**Interfaces:**
- Produces:
  - `sealed class RadialMark<T> extends Mark<T>` with `final FieldAccessor<T, Object?> category;` and `final FieldAccessor<T, num> value;`, constructed `const RadialMark({required this.category, required this.value, super.id, super.name, super.color})`.
  - `final class PieMark<T> extends RadialMark<T>` — extra fields `FieldAccessor<T, num>? radius`, `PieChartStyle? style`, `PieDataLabelConfig? dataLabels`.
  - `final class DonutMark<T> extends RadialMark<T>` — extra fields `FieldAccessor<T, num>? radius`, `FieldAccessor<T, Object?>? ring`, `DonutChartStyle? style`, `DonutCenterContent? center`, `PieDataLabelConfig? dataLabels`.
  - `final class PolarMark<T> extends RadialMark<T>` — extra field `PolarColumnStyle? style`.
- Consumes: `FieldAccessor<T, V>` from `channel.dart`; `PieChartStyle`/`PieDataLabelConfig` from `pie_chart_config.dart`; `DonutChartStyle`/`DonutCenterContent` from `donut_chart_config.dart`; `PolarColumnStyle` from `polar_column_chart_series.dart`.

- [ ] **Step 1: Write the failing test** — `test/unit/grammar/radial_marks_test.dart`:

```dart
// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class Fruit {
  const Fruit({
    required this.name,
    required this.count,
    this.mass = 0,
    this.basket = '',
  });
  final String name;
  final double count;
  final double mass;
  final String basket;
}

Object fruitName(Fruit row) => row.name;
double fruitCount(Fruit row) => row.count;
double fruitMass(Fruit row) => row.mass;
Object fruitBasket(Fruit row) => row.basket;

void main() {
  group('radial marks are const and value-equal', () {
    test('PieMark is const-constructible and value-equal', () {
      const a = PieMark<Fruit>(category: fruitName, value: fruitCount);
      const b = PieMark<Fruit>(category: fruitName, value: fruitCount);
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isA<RadialMark<Fruit>>());
      expect(a, isA<Mark<Fruit>>());
    });

    test('PieMark distinguishes its optional radius accessor', () {
      const withRadius = PieMark<Fruit>(
        category: fruitName,
        value: fruitCount,
        radius: fruitMass,
      );
      const without = PieMark<Fruit>(category: fruitName, value: fruitCount);
      expect(withRadius == without, isFalse);
    });

    test('DonutMark carries a ring accessor and center content', () {
      const mark = DonutMark<Fruit>(
        category: fruitName,
        value: fruitCount,
        ring: fruitBasket,
        center: DonutCenterContent(label: 'Total'),
      );
      expect(mark.ring, same(fruitBasket));
      expect(mark.center, const DonutCenterContent(label: 'Total'));
      expect(mark, isA<RadialMark<Fruit>>());
    });

    test('PolarMark holds a polar style', () {
      const mark = PolarMark<Fruit>(
        category: fruitName,
        value: fruitCount,
        style: PolarColumnStyle(cornerRadius: 6),
      );
      expect(mark.style, const PolarColumnStyle(cornerRadius: 6));
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/unit/grammar/radial_marks_test.dart`
Expected: FAIL — compile error, `PieMark`/`DonutMark`/`PolarMark`/`RadialMark` are not defined.

- [ ] **Step 3: Add imports to `mark.dart`** — after line 20 (`import 'channel.dart';`) add:

```dart
import '../models/donut_chart_config.dart'
    show DonutCenterContent, DonutChartStyle;
import '../models/pie_chart_config.dart'
    show PieChartStyle, PieDataLabelConfig;
import '../models/polar_column_chart_series.dart' show PolarColumnStyle;
```

- [ ] **Step 4: Append the radial mark hierarchy to `mark.dart`** — after `PointMark` (end of file, line 766):

```dart
/// A radial geometry: a whole-dataset arc mark, not a per-point Cartesian one.
///
/// Every radial variant shares two channels — [category] (the slice/column
/// identity) and [value] (its magnitude) — so they live on this sealed base.
/// A spec containing any [RadialMark] is a RADIAL spec: it lowers through the
/// radial branch of `spec.lower()`, may contain no other mark, and honors no
/// Cartesian axis/grid option. Like the Cartesian marks these hold functions,
/// so they carry no `copyWith` and no `@chartSurface`.
sealed class RadialMark<T> extends Mark<T> {
  /// Shared radial channels plus the inherited identity fields.
  const RadialMark({
    required this.category,
    required this.value,
    super.id,
    super.name,
    super.color,
  });

  /// Slice/column identity accessor. Stringified into the category label.
  final FieldAccessor<T, Object?> category;

  /// Magnitude accessor: angle-share for pie/donut, radius for polar.
  final FieldAccessor<T, num> value;
}

/// A pie: each row is a slice, [RadialMark.value] is the angle-share.
final class PieMark<T> extends RadialMark<T> {
  /// Creates a pie geometry.
  const PieMark({
    required super.category,
    required super.value,
    super.id,
    super.name,
    super.color,
    this.radius,
    this.style,
    this.dataLabels,
  });

  /// Optional second metric → variable slice radius (Nightingale). Null keeps
  /// every slice at the series radius.
  final FieldAccessor<T, num>? radius;

  /// Slice geometry/appearance. Null lowers to `const PieChartStyle()`.
  final PieChartStyle? style;

  /// Data-label configuration. Null lowers to `const PieDataLabelConfig()`.
  final PieDataLabelConfig? dataLabels;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PieMark<T> &&
          other.category == category &&
          other.value == value &&
          other.radius == radius &&
          other.id == id &&
          other.name == name &&
          other.color == color &&
          other.style == style &&
          other.dataLabels == dataLabels;

  @override
  int get hashCode => Object.hash(
    category,
    value,
    radius,
    id,
    name,
    color,
    style,
    dataLabels,
  );

  @override
  String toString() => 'PieMark(id: $id, name: $name)';
}

/// A donut. With [ring] set, rows partition into concentric `DonutChartSeries`
/// (one per distinct ring value, in first-seen order); without it, a single
/// donut.
final class DonutMark<T> extends RadialMark<T> {
  /// Creates a donut geometry.
  const DonutMark({
    required super.category,
    required super.value,
    super.id,
    super.name,
    super.color,
    this.radius,
    this.ring,
    this.style,
    this.center,
    this.dataLabels,
  });

  /// Optional second metric → variable slice radius. Null keeps a fixed radius.
  final FieldAccessor<T, num>? radius;

  /// Concentric-ring grouping channel. Absent = a single donut.
  final FieldAccessor<T, Object?>? ring;

  /// Donut geometry/appearance. Null lowers to `const DonutChartStyle()`.
  final DonutChartStyle? style;

  /// Center summary. For a single donut this is the series' center; for a
  /// concentric composition it is the shared `ConcentricDonutConfig.centerContent`.
  final DonutCenterContent? center;

  /// Data-label configuration. Null lowers to `const PieDataLabelConfig()`.
  final PieDataLabelConfig? dataLabels;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DonutMark<T> &&
          other.category == category &&
          other.value == value &&
          other.radius == radius &&
          other.ring == ring &&
          other.id == id &&
          other.name == name &&
          other.color == color &&
          other.style == style &&
          other.center == center &&
          other.dataLabels == dataLabels;

  @override
  int get hashCode => Object.hash(
    category,
    value,
    radius,
    ring,
    id,
    name,
    color,
    style,
    center,
    dataLabels,
  );

  @override
  String toString() => 'DonutMark(id: $id, name: $name)';
}

/// A polar column: [RadialMark.category] is the angular position and
/// [RadialMark.value] is the radius (magnitude).
final class PolarMark<T> extends RadialMark<T> {
  /// Creates a polar-column geometry.
  const PolarMark({
    required super.category,
    required super.value,
    super.id,
    super.name,
    super.color,
    this.style,
  });

  /// Column geometry/appearance. Null lowers to `const PolarColumnStyle()`.
  final PolarColumnStyle? style;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PolarMark<T> &&
          other.category == category &&
          other.value == value &&
          other.id == id &&
          other.name == name &&
          other.color == color &&
          other.style == style;

  @override
  int get hashCode =>
      Object.hash(category, value, id, name, color, style);

  @override
  String toString() => 'PolarMark(id: $id, name: $name)';
}
```

- [ ] **Step 5: Repair the two Cartesian switches in `plot_lowering.dart`.** In the structural switch (currently ending at line 261 with the `ThresholdMark || BandMark || PointMark` case) add, as the final arm before the closing `}`:

```dart
      case RadialMark<T>():
        // Unreachable: a radial spec returns via _lowerRadial before this
        // Cartesian switch runs. The arm exists only to keep the sealed
        // switch exhaustive.
        throw StateError('radial mark reached the Cartesian structural pass');
```

In the materialization switch (currently ending at line 309 with `case PointMark<T>()`) add, as the final arm before the closing `}`:

```dart
      case RadialMark<T>():
        throw StateError('radial mark reached the Cartesian materialization');
```

- [ ] **Step 6: Repair the two source-generator switches in `chart_grammar_source_generator.dart`.** In the `verb` switch (line 1581), add before the closing `};` (after the `PointMark` arm at 1592-1594):

```dart
      RadialMark<_SourceRow>() => throw StateError(
        'unreachable: a radial mark reached the grammar source generator; '
        'radial series are rejected by the family gate before planning',
      ),
```

In the field switch (line 1613), add before its closing `}` (after the `ThresholdMark || BandMark || PointMark` arm at 1667-1670):

```dart
        case RadialMark<_SourceRow>():
          break; // unreachable: the verb switch above already threw.
```

- [ ] **Step 7: Repair `geomOf` in `plot_spec_test.dart`.** Add before the closing `};` (after the `PointMark<Sample>() => 'point',` arm at line 59):

```dart
  RadialMark<Sample>() => 'radial',
```

- [ ] **Step 8: Run analyze + the mark test**

Run: `flutter analyze lib && flutter test test/unit/grammar/radial_marks_test.dart test/unit/grammar/plot_spec_test.dart`
Expected: analyze reports **No issues found**; both test files PASS.

- [ ] **Step 9: Commit**

```bash
git add lib/src/grammar/mark.dart lib/src/grammar/plot_lowering.dart lib/src/source/chart_grammar_source_generator.dart test/unit/grammar/plot_spec_test.dart test/unit/grammar/radial_marks_test.dart
git commit -m "feat(grammar): add sealed RadialMark hierarchy (Pie/Donut/Polar marks)"
```

---

## Task 2: Coordinate detection + `LoweredPlot`/`BravenPlot` plumbing

**Files:**
- Modify: `lib/src/grammar/plot_spec.dart` (add `isRadial` after line 103)
- Modify: `lib/src/grammar/plot_lowering.dart` (`LoweredPlot` fields + imports)
- Modify: `lib/src/grammar/braven_plot.dart` (forward the two configs + imports)
- Test: `test/unit/grammar/plot_lowering_radial_test.dart` (create)

**Interfaces:**
- Produces:
  - `bool get isRadial` on `PlotSpec<T>` → `marks.any((m) => m is RadialMark<T>)`.
  - `LoweredPlot` gains `final ConcentricDonutConfig? concentricDonutConfig;` and `final PolarChartConfig? polarChartConfig;`, both optional-named on the `const LoweredPlot(...)` constructor (default `null`).
- Consumes: `RadialMark<T>` (Task 1); `ConcentricDonutConfig` from `concentric_donut_config.dart`; `PolarChartConfig` from `polar_chart_config.dart`.

- [ ] **Step 1: Write the failing test** — `test/unit/grammar/plot_lowering_radial_test.dart`:

```dart
// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

/// Radial lowering: channel→series mapping, config parity and diagnostics.
library;

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class Fruit {
  const Fruit({
    required this.name,
    required this.count,
    this.mass = 0,
    this.basket = '',
  });
  final String name;
  final double count;
  final double mass;
  final String basket;
}

Object fruitName(Fruit row) => row.name;
double fruitCount(Fruit row) => row.count;
double fruitMass(Fruit row) => row.mass;
Object fruitBasket(Fruit row) => row.basket;
Object fruitBlank(Fruit row) => '';
double sampleX(Fruit row) => row.count;
double sampleY(Fruit row) => row.mass;

const fruits = <Fruit>[
  Fruit(name: 'Apple', count: 30, mass: 5, basket: 'A'),
  Fruit(name: 'Pear', count: 20, mass: 3, basket: 'A'),
  Fruit(name: 'Plum', count: 10, mass: 2, basket: 'B'),
];

Matcher throwsGrammarCode(GrammarDiagnosticCode code) =>
    throwsA(isA<GrammarSpecException>().having((e) => e.code, 'code', code));

void main() {
  group('lowering plumbing', () {
    test('a Cartesian spec is not radial and lowers with null radial configs',
        () {
      const spec = PlotSpec<Fruit>(
        data: fruits,
        marks: <Mark<Fruit>>[LineMark<Fruit>(x: sampleX, y: sampleY)],
      );
      expect(spec.isRadial, isFalse);
      final lowered = spec.lower();
      expect(lowered.concentricDonutConfig, isNull);
      expect(lowered.polarChartConfig, isNull);
    });

    test('a spec with a radial mark reports isRadial', () {
      const spec = PlotSpec<Fruit>(
        data: fruits,
        marks: <Mark<Fruit>>[
          PieMark<Fruit>(category: fruitName, value: fruitCount),
        ],
      );
      expect(spec.isRadial, isTrue);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/unit/grammar/plot_lowering_radial_test.dart`
Expected: FAIL — `isRadial` is not defined on `PlotSpec`, and `concentricDonutConfig`/`polarChartConfig` are not defined on `LoweredPlot`.

- [ ] **Step 3: Add `isRadial` to `PlotSpec`** — in `plot_spec.dart`, after the `showLegend` field (line 103), before `operator ==`:

```dart
  /// Whether any mark is a radial geometry.
  ///
  /// A radial spec lowers through the dedicated radial branch of
  /// `spec.lower()`; a Cartesian spec never enters it.
  bool get isRadial => marks.any((mark) => mark is RadialMark<T>);
```

- [ ] **Step 4: Extend `LoweredPlot`** — in `plot_lowering.dart`, add imports after line 15 (`import '../models/y_axis_config.dart';`):

```dart
import '../models/concentric_donut_config.dart';
import '../models/polar_chart_config.dart';
```

Add the two optional parameters to the `const LoweredPlot(...)` constructor (after `this.showLegend,` on line 48):

```dart
    this.concentricDonutConfig,
    this.polarChartConfig,
```

Add the two fields after the `showLegend` field (after line 79):

```dart
  /// The concentric-donut composition config, when the lowered chart is a
  /// concentric donut. Null for every other family.
  final ConcentricDonutConfig? concentricDonutConfig;

  /// The polar pane/axis config, when the lowered chart is a polar column.
  /// Null for every other family.
  final PolarChartConfig? polarChartConfig;
```

- [ ] **Step 5: Forward the configs from `BravenPlot`** — in `braven_plot.dart`, add imports after line 9 (`import '../models/chart_series.dart';`):

```dart
import '../models/concentric_donut_config.dart';
import '../models/polar_chart_config.dart';
```

In `build`, add two arguments to the `BravenChartPlus(...)` call (after `showLegend: spec.showLegend ?? true,`):

```dart
      concentricDonutConfig:
          lowered?.concentricDonutConfig ?? const ConcentricDonutConfig(),
      polarChartConfig:
          lowered?.polarChartConfig ?? const PolarChartConfig(),
```

- [ ] **Step 6: Run analyze + the test**

Run: `flutter analyze lib && flutter test test/unit/grammar/plot_lowering_radial_test.dart`
Expected: analyze **No issues found**; the two plumbing tests PASS.

- [ ] **Step 7: Commit**

```bash
git add lib/src/grammar/plot_spec.dart lib/src/grammar/plot_lowering.dart lib/src/grammar/braven_plot.dart test/unit/grammar/plot_lowering_radial_test.dart
git commit -m "feat(grammar): PlotSpec.isRadial + LoweredPlot radial configs forwarded by BravenPlot"
```

---

## Task 3: The five radial diagnostics

**Files:**
- Modify: `lib/src/grammar/grammar_diagnostics.dart` (5 enum values + 5 factories)
- Test: `test/unit/grammar/plot_lowering_radial_test.dart` (add a `group('radial diagnostic factories')`)

**Interfaces:**
- Produces (factory signatures):
  - `GrammarSpecException.mixedCoordinateSystems(String radialMarkId, Iterable<String> otherMarkIds)`
  - `GrammarSpecException.multipleRadialGeoms(Iterable<String> radialMarkIds)`
  - `GrammarSpecException.axisOptionOnRadialSpec(String option)`
  - `GrammarSpecException.emptyRadialCategories(String markId)`
  - `GrammarSpecException.facetedRadialUnsupported(String markId)`
- Consumes: the existing `_list` helper (line 210) and the `GrammarSpecException(code, message)` primary constructor.

- [ ] **Step 1: Write the failing test** — append to `plot_lowering_radial_test.dart`'s `main()`:

```dart
  group('radial diagnostic factories', () {
    test('every radial diagnostic names its code and remedy', () {
      final mixed = GrammarSpecException.mixedCoordinateSystems('pie', ['ln']);
      expect(mixed.code, GrammarDiagnosticCode.mixedCoordinateSystems);
      expect(mixed.toString(), contains('mixedCoordinateSystems'));
      expect(mixed.message, contains('pie'));
      expect(mixed.message, contains('ln'));

      final many = GrammarSpecException.multipleRadialGeoms(['a', 'b']);
      expect(many.code, GrammarDiagnosticCode.multipleRadialGeoms);
      expect(many.message, contains('a'));
      expect(many.message, contains('b'));

      final axis = GrammarSpecException.axisOptionOnRadialSpec('grid');
      expect(axis.code, GrammarDiagnosticCode.axisOptionOnRadialSpec);
      expect(axis.message, contains('grid'));

      final empty = GrammarSpecException.emptyRadialCategories('pie');
      expect(empty.code, GrammarDiagnosticCode.emptyRadialCategories);
      expect(empty.message, contains('pie'));

      final facet = GrammarSpecException.facetedRadialUnsupported('pie');
      expect(facet.code, GrammarDiagnosticCode.facetedRadialUnsupported);
      expect(facet.message, contains('pie'));
    });
  });
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/unit/grammar/plot_lowering_radial_test.dart --plain-name 'every radial diagnostic names its code'`
Expected: FAIL — the five `GrammarDiagnosticCode` values and factories are not defined.

- [ ] **Step 3: Add the enum values** — in `grammar_diagnostics.dart`, inside `enum GrammarDiagnosticCode` after `missingEncoding,` (line 60), before the closing `}`:

```dart

  /// A radial geom was combined with a Cartesian (or reference) mark.
  mixedCoordinateSystems,

  /// A spec declared more than one radial geom.
  multipleRadialGeoms,

  /// A Cartesian axis/grid option (grid, xAxis, yAxis, transposed) was set on
  /// a radial spec.
  axisOptionOnRadialSpec,

  /// A radial geom produced no category with a visible label.
  emptyRadialCategories,

  /// A radial spec also requested faceting, which radial does not yet support.
  facetedRadialUnsupported,
```

- [ ] **Step 4: Add the factories** — in `grammar_diagnostics.dart`, after the `missingEncoding` factory (line 202), before the `code`/`message` fields:

```dart
  /// A radial geom was combined with a non-radial mark.
  factory GrammarSpecException.mixedCoordinateSystems(
    String radialMarkId,
    Iterable<String> otherMarkIds,
  ) => GrammarSpecException(
    GrammarDiagnosticCode.mixedCoordinateSystems,
    'The radial mark "$radialMarkId" cannot share a plot with the '
    'non-radial mark(s) ${_list(otherMarkIds)}. Radial and Cartesian '
    'geometries use different coordinate systems; author them as separate '
    'charts.',
  );

  /// A spec declared more than one radial geom.
  factory GrammarSpecException.multipleRadialGeoms(
    Iterable<String> radialMarkIds,
  ) => GrammarSpecException(
    GrammarDiagnosticCode.multipleRadialGeoms,
    'A plot may contain at most one radial geom, but ${_list(radialMarkIds)} '
    'are all radial. Split them into separate charts.',
  );

  /// A Cartesian axis/grid option was set on a radial spec.
  factory GrammarSpecException.axisOptionOnRadialSpec(String option) =>
      GrammarSpecException(
        GrammarDiagnosticCode.axisOptionOnRadialSpec,
        'A radial spec set "$option", but radial charts have no Cartesian '
        'axes or grid. Remove $option; use title, subtitle, legend and theme '
        'instead.',
      );

  /// A radial geom produced no category with a visible label.
  factory GrammarSpecException.emptyRadialCategories(String markId) =>
      GrammarSpecException(
        GrammarDiagnosticCode.emptyRadialCategories,
        'The radial mark "$markId" produced no category with a visible label. '
        'Its category accessor must return a non-empty value for at least one '
        'row.',
      );

  /// A radial spec also requested faceting.
  factory GrammarSpecException.facetedRadialUnsupported(String markId) =>
      GrammarSpecException(
        GrammarDiagnosticCode.facetedRadialUnsupported,
        'The radial mark "$markId" is on a faceted spec. Faceting a radial '
        'geom is not supported; author the radial chart without .facet(...).',
      );
```

- [ ] **Step 5: Run the diagnostics test**

Run: `flutter test test/unit/grammar/plot_lowering_radial_test.dart --plain-name 'every radial diagnostic names its code'`
Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add lib/src/grammar/grammar_diagnostics.dart test/unit/grammar/plot_lowering_radial_test.dart
git commit -m "feat(grammar): add the five radial diagnostic codes and factories"
```

---

## Task 4: `_lowerRadial` guard sequence + Pie lowering + `geomPie`

This is the Pie vertical slice: the shared radial branch (guards for `multipleRadialGeoms`, `mixedCoordinateSystems`, `axisOptionOnRadialSpec`, `emptyData`, `emptyRadialCategories`), the pie config builder, and the facade verb.

**Files:**
- Modify: `lib/src/grammar/plot_lowering.dart` (branch `_lower` into `_lowerRadial`; add `_lowerRadial`, `_lowerPie`, `_radialValues`, `_radiusValues`; add imports)
- Modify: `lib/src/grammar/chart_builder.dart` (add `geomPie`)
- Test: `test/unit/grammar/chart_builder_radial_test.dart` (create — facade parity)
- Test: `test/unit/grammar/plot_lowering_radial_test.dart` (add pie mapping/parity/diagnostics groups)

**Interfaces:**
- Consumes: `PieMark<T>`/`RadialMark<T>` (Task 1); `LoweredPlot.concentricDonutConfig`/`polarChartConfig` (Task 2); the 5 diagnostics (Task 3); `PlotSpec.isRadial` (Task 2); `_resolveMarkIds` (existing, line 432); `PieChartSeries.fromMap` (`pie_chart_series.dart`).
- Produces:
  - `LoweredPlot _lowerRadial<T>(PlotSpec<T> spec, List<String> markIds)`
  - `PieChartSeries _lowerPie<T>(PieMark<T> mark, String id, List<T> data)`
  - `Map<String, num> _radialValues<T>(List<T> data, FieldAccessor<T, Object?> category, FieldAccessor<T, num> value)`
  - `Map<String, num> _radiusValues<T>(List<T> data, FieldAccessor<T, Object?> category, FieldAccessor<T, num> radius)`
  - `BravenChart<T> geomPie({required FieldAccessor<T, Object?> category, required FieldAccessor<T, num> value, FieldAccessor<T, num>? radius, String? id, String? name, Color? color, PieChartStyle? style, PieDataLabelConfig? dataLabels})`

- [ ] **Step 1: Write the failing facade test** — `test/unit/grammar/chart_builder_radial_test.dart`:

```dart
// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

/// The chained facade's radial verbs equal the hand-written PlotSpec.
library;

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class Fruit {
  const Fruit({required this.name, required this.count, this.mass = 0, this.basket = ''});
  final String name;
  final double count;
  final double mass;
  final String basket;
}

Object fruitName(Fruit row) => row.name;
double fruitCount(Fruit row) => row.count;
double fruitMass(Fruit row) => row.mass;
Object fruitBasket(Fruit row) => row.basket;

const fruits = <Fruit>[
  Fruit(name: 'Apple', count: 30, mass: 5, basket: 'A'),
  Fruit(name: 'Pear', count: 20, mass: 3, basket: 'A'),
  Fruit(name: 'Plum', count: 10, mass: 2, basket: 'B'),
];

void main() {
  group('geomPie equals the hand-written spec', () {
    test('geomPie appends a PieMark with its channels and style', () {
      final spec = BravenChart.of(fruits)
          .geomPie(
            category: fruitName,
            value: fruitCount,
            radius: fruitMass,
            name: 'Fruit',
            color: const Color(0xFF2563EB),
            style: const PieChartStyle(radiusFactor: 0.8),
          )
          .toSpec();

      expect(
        spec,
        const PlotSpec<Fruit>(
          data: fruits,
          marks: <Mark<Fruit>>[
            PieMark<Fruit>(
              id: 'mark-0',
              category: fruitName,
              value: fruitCount,
              radius: fruitMass,
              name: 'Fruit',
              color: Color(0xFF2563EB),
              style: PieChartStyle(radiusFactor: 0.8),
            ),
          ],
        ),
      );
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/unit/grammar/chart_builder_radial_test.dart`
Expected: FAIL — `geomPie` is not defined on `BravenChart`.

- [ ] **Step 3: Add `geomPie` to `chart_builder.dart`** — after `geomCandlestick` (line 370), before `trend`:

```dart
  /// Appends a pie: each row is a slice, [value] is the angle-share.
  ///
  /// A pie makes the spec RADIAL — it may contain no other mark, and honors no
  /// Cartesian axis/grid option. [radius] encodes an optional second metric as
  /// a variable slice radius. Rich styling is deferred to [style]/[dataLabels],
  /// the real config objects, exactly as the Cartesian geoms defer to config.
  BravenChart<T> geomPie({
    required FieldAccessor<T, Object?> category,
    required FieldAccessor<T, num> value,
    FieldAccessor<T, num>? radius,
    String? id,
    String? name,
    Color? color,
    PieChartStyle? style,
    PieDataLabelConfig? dataLabels,
  }) => _append(
    PieMark<T>(
      id: _idFor(id),
      category: category,
      value: value,
      radius: radius,
      name: name,
      color: color,
      style: style,
      dataLabels: dataLabels,
    ),
  );
```

Add the import for the style/config types near the other model imports (after line 18's `scatter_marker_style.dart` import block):

```dart
import '../models/pie_chart_config.dart' show PieChartStyle, PieDataLabelConfig;
```

- [ ] **Step 4: Run the facade test to verify it passes**

Run: `flutter test test/unit/grammar/chart_builder_radial_test.dart`
Expected: PASS.

- [ ] **Step 5: Write the failing lowering test** — add three groups to `plot_lowering_radial_test.dart`'s `main()`:

```dart
  group('pie channel to series mapping', () {
    test('values lower to angle-share slices in row order', () {
      final lowered = (const PlotSpec<Fruit>(
        data: fruits,
        marks: <Mark<Fruit>>[
          PieMark<Fruit>(category: fruitName, value: fruitCount),
        ],
      )).lower();

      final series = lowered.series.single as PieChartSeries;
      expect(series.id, 'mark-0');
      expect(series.points.map((p) => p.label), ['Apple', 'Pear', 'Plum']);
      expect(series.points.map((p) => p.y), [30, 20, 10]);
      expect(series.points.map((p) => p.x), [0, 1, 2]);
      expect(series.total, 60);
      // Angle-share = y / total.
      expect(series.points.first.y / series.total, 0.5);
      expect(lowered.concentricDonutConfig, isNull);
      expect(lowered.polarChartConfig, isNull);
      expect(lowered.yAxes, isEmpty);
      expect(lowered.annotations, isEmpty);
    });

    test('the radius channel lowers to variable slice radii', () {
      final lowered = (const PlotSpec<Fruit>(
        data: fruits,
        marks: <Mark<Fruit>>[
          PieMark<Fruit>(
            category: fruitName,
            value: fruitCount,
            radius: fruitMass,
          ),
        ],
      )).lower();

      final series = lowered.series.single as PieChartSeries;
      expect(series.sliceRadiusConfig, isNotNull);
      expect(series.points.map((p) => p.pointStyle?.size), [5, 3, 2]);
    });
  });

  group('pie config parity', () {
    test('a lowered pie equals the hand-built PieChartSeries.fromMap', () {
      final lowered = (const PlotSpec<Fruit>(
        data: fruits,
        marks: <Mark<Fruit>>[
          PieMark<Fruit>(
            category: fruitName,
            value: fruitCount,
            id: 'fruit',
            name: 'Fruit',
          ),
        ],
      )).lower();

      expect(
        lowered.series.single,
        PieChartSeries.fromMap(
          id: 'fruit',
          name: 'Fruit',
          values: const {'Apple': 30, 'Pear': 20, 'Plum': 10},
        ),
      );
    });

    test('the radius channel parity uses radiusValues', () {
      final lowered = (const PlotSpec<Fruit>(
        data: fruits,
        marks: <Mark<Fruit>>[
          PieMark<Fruit>(
            category: fruitName,
            value: fruitCount,
            radius: fruitMass,
            id: 'fruit',
          ),
        ],
      )).lower();

      expect(
        lowered.series.single,
        PieChartSeries.fromMap(
          id: 'fruit',
          values: const {'Apple': 30, 'Pear': 20, 'Plum': 10},
          radiusValues: const {'Apple': 5, 'Pear': 3, 'Plum': 2},
        ),
      );
    });
  });

  group('radial coordinate-system diagnostics', () {
    test('a pie plus a line raises mixedCoordinateSystems', () {
      expect(
        () => (const PlotSpec<Fruit>(
          data: fruits,
          marks: <Mark<Fruit>>[
            PieMark<Fruit>(category: fruitName, value: fruitCount),
            LineMark<Fruit>(x: sampleX, y: sampleY),
          ],
        )).lower(),
        throwsGrammarCode(GrammarDiagnosticCode.mixedCoordinateSystems),
      );
    });

    test('two pies raise multipleRadialGeoms', () {
      expect(
        () => (const PlotSpec<Fruit>(
          data: fruits,
          marks: <Mark<Fruit>>[
            PieMark<Fruit>(category: fruitName, value: fruitCount, id: 'a'),
            PieMark<Fruit>(category: fruitName, value: fruitCount, id: 'b'),
          ],
        )).lower(),
        throwsGrammarCode(GrammarDiagnosticCode.multipleRadialGeoms),
      );
    });

    test('a grid on a radial spec raises axisOptionOnRadialSpec', () {
      expect(
        () => (const PlotSpec<Fruit>(
          data: fruits,
          marks: <Mark<Fruit>>[
            PieMark<Fruit>(category: fruitName, value: fruitCount),
          ],
          grid: GridConfig(),
        )).lower(),
        throwsGrammarCode(GrammarDiagnosticCode.axisOptionOnRadialSpec),
      );
    });

    test('a transposed radial spec raises axisOptionOnRadialSpec', () {
      expect(
        () => (const PlotSpec<Fruit>(
          data: fruits,
          marks: <Mark<Fruit>>[
            PieMark<Fruit>(category: fruitName, value: fruitCount),
          ],
          transposed: true,
        )).lower(),
        throwsGrammarCode(GrammarDiagnosticCode.axisOptionOnRadialSpec),
      );
    });

    test('an xAxis on a radial spec raises axisOptionOnRadialSpec', () {
      expect(
        () => (const PlotSpec<Fruit>(
          data: fruits,
          marks: <Mark<Fruit>>[
            PieMark<Fruit>(category: fruitName, value: fruitCount),
          ],
          xAxis: XAxisConfig(label: 'x'),
        )).lower(),
        throwsGrammarCode(GrammarDiagnosticCode.axisOptionOnRadialSpec),
      );
    });

    test('all-blank category labels raise emptyRadialCategories', () {
      expect(
        () => (const PlotSpec<Fruit>(
          data: fruits,
          marks: <Mark<Fruit>>[
            PieMark<Fruit>(category: fruitBlank, value: fruitCount),
          ],
        )).lower(),
        throwsGrammarCode(GrammarDiagnosticCode.emptyRadialCategories),
      );
    });

    test('empty radial data raises emptyData (so BravenPlot can swallow it)',
        () {
      expect(
        () => (const PlotSpec<Fruit>(
          data: <Fruit>[],
          marks: <Mark<Fruit>>[
            PieMark<Fruit>(category: fruitName, value: fruitCount),
          ],
        )).lower(),
        throwsGrammarCode(GrammarDiagnosticCode.emptyData),
      );
    });

    test('a structural radial error beats the empty-data guard', () {
      // axisOptionOnRadialSpec must fire even against empty data, so BravenPlot
      // only ever swallows an otherwise well-formed empty spec.
      expect(
        () => (const PlotSpec<Fruit>(
          data: <Fruit>[],
          marks: <Mark<Fruit>>[
            PieMark<Fruit>(category: fruitName, value: fruitCount),
          ],
          grid: GridConfig(),
        )).lower(),
        throwsGrammarCode(GrammarDiagnosticCode.axisOptionOnRadialSpec),
      );
    });
  });
```

- [ ] **Step 6: Run test to verify it fails**

Run: `flutter test test/unit/grammar/plot_lowering_radial_test.dart`
Expected: FAIL — the radial specs currently fall through to the Cartesian path and throw `StateError` (from Task 1's unreachable arm) instead of building a pie / raising the radial diagnostics.

- [ ] **Step 7: Branch `_lower` into `_lowerRadial`.** In `plot_lowering.dart`, add imports after the Task 2 imports (concentric/polar), near line 15:

```dart
import '../models/pie_chart_series.dart';
import '../models/pie_chart_config.dart';
```

In `_lower<T>`, immediately after `final markIds = _resolveMarkIds(spec.marks);` (line 188), add:

```dart
  if (spec.isRadial) return _lowerRadial<T>(spec, markIds);
```

- [ ] **Step 8: Add the radial branch + pie builder.** Append to `plot_lowering.dart` (after `_lowerPoint`, before `_requireScale`, ~line 721):

```dart
/// Lowers a RADIAL spec: exactly one radial geom, no Cartesian marks, no
/// Cartesian axis/grid option. The whole dataset maps to one radial series
/// (or, for a ring channel, one per ring). Validation order is deterministic
/// and matches the Cartesian contract: every data-INDEPENDENT structural check
/// runs before the emptyData guard, so BravenPlot swallows ONLY an otherwise
/// well-formed empty spec.
LoweredPlot _lowerRadial<T>(PlotSpec<T> spec, List<String> markIds) {
  final radialIndices = <int>[
    for (var index = 0; index < spec.marks.length; index++)
      if (spec.marks[index] is RadialMark<T>) index,
  ];
  if (radialIndices.length > 1) {
    throw GrammarSpecException.multipleRadialGeoms(<String>[
      for (final index in radialIndices) markIds[index],
    ]);
  }
  final markIndex = radialIndices.single;
  if (spec.marks.length > 1) {
    throw GrammarSpecException.mixedCoordinateSystems(markIds[markIndex], <String>[
      for (var index = 0; index < spec.marks.length; index++)
        if (index != markIndex) markIds[index],
    ]);
  }

  final mark = spec.marks[markIndex] as RadialMark<T>;
  final markId = markIds[markIndex];

  // Cartesian-only options carry no meaning on a radial spec.
  if (spec.transposed) {
    throw GrammarSpecException.axisOptionOnRadialSpec('transposed');
  }
  if (spec.xAxis != null) {
    throw GrammarSpecException.axisOptionOnRadialSpec('xAxis');
  }
  if (spec.yAxes.isNotEmpty) {
    throw GrammarSpecException.axisOptionOnRadialSpec('yAxes');
  }
  if (spec.grid != null) {
    throw GrammarSpecException.axisOptionOnRadialSpec('grid');
  }

  // Data-dependent checks live below the emptyData guard.
  if (spec.data.isEmpty) throw GrammarSpecException.emptyData();

  final hasVisibleCategory = spec.data.any(
    (row) => mark.category(row).toString().trim().isNotEmpty,
  );
  if (!hasVisibleCategory) {
    throw GrammarSpecException.emptyRadialCategories(markId);
  }

  final series = <ChartSeries>[];
  ConcentricDonutConfig? concentric;
  PolarChartConfig? polar;

  if (mark is PieMark<T>) {
    series.add(_lowerPie<T>(mark, markId, spec.data));
  } else {
    // Donut and Polar branches are added in later phases; this guards the
    // not-yet-wired path with a clear error rather than silent misbehavior.
    throw StateError('Unhandled radial mark: $mark');
  }

  return LoweredPlot(
    series: series,
    annotations: const <ChartAnnotation>[],
    xAxis: null,
    yAxes: const <YAxisConfig>[],
    interaction: spec.interaction ?? const InteractionConfig(),
    theme: spec.theme,
    grid: null,
    title: spec.title,
    subtitle: spec.subtitle,
    showLegend: spec.showLegend,
    concentricDonutConfig: concentric,
    polarChartConfig: polar,
  );
}

/// Builds an insertion-ordered category→value map. Duplicate categories
/// collapse (last row wins), matching `PieChartSeries.fromMap` semantics.
Map<String, num> _radialValues<T>(
  List<T> data,
  FieldAccessor<T, Object?> category,
  FieldAccessor<T, num> value,
) {
  final result = <String, num>{};
  for (final row in data) {
    result[category(row).toString()] = value(row);
  }
  return result;
}

/// Builds the per-category second-metric radius map for a variable-radius geom.
Map<String, num> _radiusValues<T>(
  List<T> data,
  FieldAccessor<T, Object?> category,
  FieldAccessor<T, num> radius,
) {
  final result = <String, num>{};
  for (final row in data) {
    result[category(row).toString()] = radius(row);
  }
  return result;
}

PieChartSeries _lowerPie<T>(PieMark<T> mark, String id, List<T> data) =>
    PieChartSeries.fromMap(
      id: id,
      name: mark.name,
      color: mark.color,
      values: _radialValues(data, mark.category, mark.value),
      radiusValues: mark.radius == null
          ? const <String, num>{}
          : _radiusValues(data, mark.category, mark.radius!),
      pieStyle: mark.style ?? const PieChartStyle(),
      dataLabels: mark.dataLabels ?? const PieDataLabelConfig(),
    );
```

- [ ] **Step 9: Run the lowering tests to verify they pass**

Run: `flutter analyze lib && flutter test test/unit/grammar/plot_lowering_radial_test.dart test/unit/grammar/chart_builder_radial_test.dart`
Expected: analyze **No issues found**; all pie mapping/parity/diagnostics tests PASS.

- [ ] **Step 10: Run the full grammar suite to confirm no Cartesian regression**

Run: `flutter test test/unit/grammar/`
Expected: PASS (Cartesian parity, builder, plot_spec suites unaffected).

- [ ] **Step 11: Commit**

```bash
git add lib/src/grammar/plot_lowering.dart lib/src/grammar/chart_builder.dart test/unit/grammar/chart_builder_radial_test.dart test/unit/grammar/plot_lowering_radial_test.dart
git commit -m "feat(grammar): geomPie lowers to PieChartSeries with radial guards"
```

---

## Task 5: Pie golden (tolerant comparator)

**Files:**
- Test: `test/golden/grammar_radial/grammar_radial_golden_test.dart` (create)
- Create: `test/golden/grammar_radial/goldens/grammar_pie.png` (generated)

**Interfaces:**
- Consumes: `geomPie` (Task 4); `BravenChart.build()` (existing); `_TolerantGoldenFileComparator` (copied from `test/golden/pie/pie_chart_golden_test.dart`).

- [ ] **Step 1: Write the golden test** — `test/golden/grammar_radial/grammar_radial_golden_test.dart`:

```dart
import 'dart:typed_data';

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const _pixelTolerance = 0.025;

class Fruit {
  const Fruit({required this.name, required this.count, this.basket = ''});
  final String name;
  final double count;
  final String basket;
}

Object fruitName(Fruit row) => row.name;
double fruitCount(Fruit row) => row.count;
Object fruitBasket(Fruit row) => row.basket;

const _fruits = <Fruit>[
  Fruit(name: 'Apple', count: 42, basket: 'Winter'),
  Fruit(name: 'Pear', count: 31, basket: 'Winter'),
  Fruit(name: 'Plum', count: 17, basket: 'Summer'),
  Fruit(name: 'Fig', count: 10, basket: 'Summer'),
];

ChartTheme _goldenTheme() {
  final source = ChartTheme.light;
  return source.copyWith(
    typographyTheme: source.typographyTheme.copyWith(fontFamily: 'Ahem'),
    animationTheme: source.animationTheme.copyWith(
      dataUpdateDuration: Duration.zero,
      themeChangeDuration: Duration.zero,
      interactionDuration: Duration.zero,
    ),
    pieChartTheme: const PieChartTheme(animationMode: PieAnimationMode.none),
  );
}

Future<void> _pump(WidgetTester tester, Widget chart, Size size) async {
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.light(useMaterial3: true).copyWith(
        textTheme: ThemeData.light().textTheme.apply(fontFamily: 'Ahem'),
      ),
      home: Scaffold(
        body: Center(
          child: RepaintBoundary(
            key: const ValueKey('grammar-radial-surface'),
            child: ColoredBox(
              color: ChartTheme.light.backgroundColor,
              child: SizedBox.fromSize(size: size, child: chart),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

Future<void> _expectGolden(WidgetTester tester, String path) => expectLater(
  find.byKey(const ValueKey('grammar-radial-surface')),
  matchesGoldenFile(path),
);

void main() {
  late GoldenFileComparator previousComparator;

  setUp(() {
    previousComparator = goldenFileComparator;
    final local = previousComparator as LocalFileComparator;
    goldenFileComparator = _TolerantGoldenFileComparator(
      local.basedir.resolve('grammar_radial_golden_test.dart'),
      precisionTolerance: _pixelTolerance,
    );
  });

  tearDown(() => goldenFileComparator = previousComparator);

  testWidgets('grammar-authored pie', (tester) async {
    final chart = BravenChart.of(_fruits)
        .geomPie(
          category: fruitName,
          value: fruitCount,
          style: const PieChartStyle(animationMode: PieAnimationMode.none),
        )
        .title('Harvest share')
        .theme(_goldenTheme())
        .build();
    await _pump(tester, chart, const Size(560, 380));
    await _expectGolden(tester, 'goldens/grammar_pie.png');
  });
}

class _TolerantGoldenFileComparator extends LocalFileComparator {
  _TolerantGoldenFileComparator(
    super.testFile, {
    required double precisionTolerance,
  }) : precisionTolerance = precisionTolerance;

  double precisionTolerance;

  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden) async {
    final result = await GoldenFileComparator.compareLists(
      imageBytes,
      await getGoldenBytes(golden),
    );
    final passed = result.passed || result.diffPercent <= precisionTolerance;
    if (passed) {
      result.dispose();
      return true;
    }
    final error = await generateFailureOutput(result, golden, basedir);
    result.dispose();
    throw FlutterError(error);
  }
}
```

- [ ] **Step 2: Generate the golden**

Run: `flutter test test/golden/grammar_radial/grammar_radial_golden_test.dart --update-goldens`
Expected: PASS; `test/golden/grammar_radial/goldens/grammar_pie.png` is written.

- [ ] **Step 3: Re-run without update to confirm it matches**

Run: `flutter test test/golden/grammar_radial/grammar_radial_golden_test.dart`
Expected: PASS (the tolerant comparator absorbs sub-`_pixelTolerance` AA differences).

- [ ] **Step 4: Commit**

```bash
git add test/golden/grammar_radial/grammar_radial_golden_test.dart test/golden/grammar_radial/goldens/grammar_pie.png
git commit -m "test(grammar): grammar-authored pie golden with the tolerant comparator"
```

---

# Phase 2 — Donut (single ring)

Adds the `geomDonut` verb and the single-donut lowering (ring channel deferred to Phase 3).

## Task 6: `geomDonut` (single donut) + lowering

**Files:**
- Modify: `lib/src/grammar/chart_builder.dart` (add `geomDonut`; extend the pie import to add donut types)
- Modify: `lib/src/grammar/plot_lowering.dart` (add a `DonutMark` branch to `_lowerRadial`; add `_lowerDonut`; add imports)
- Test: `test/unit/grammar/chart_builder_radial_test.dart` (add a `geomDonut` group)
- Test: `test/unit/grammar/plot_lowering_radial_test.dart` (add donut mapping/parity groups)

**Interfaces:**
- Consumes: `DonutMark<T>` (Task 1); `_radialValues`/`_radiusValues` (Task 4); `DonutChartSeries.fromMap` (`donut_chart_series.dart`).
- Produces:
  - `BravenChart<T> geomDonut({required FieldAccessor<T, Object?> category, required FieldAccessor<T, num> value, FieldAccessor<T, num>? radius, FieldAccessor<T, Object?>? ring, String? id, String? name, Color? color, DonutChartStyle? style, DonutCenterContent? center, PieDataLabelConfig? dataLabels})`
  - `DonutChartSeries _lowerDonut<T>(DonutMark<T> mark, String id, List<T> data)`

- [ ] **Step 1: Write the failing facade test** — add to `chart_builder_radial_test.dart`'s `main()`:

```dart
  group('geomDonut equals the hand-written spec', () {
    test('geomDonut appends a DonutMark with its channels and center', () {
      final spec = BravenChart.of(fruits)
          .geomDonut(
            category: fruitName,
            value: fruitCount,
            name: 'Fruit',
            center: const DonutCenterContent(label: 'Total'),
            style: const DonutChartStyle(innerRadiusFactor: 0.5),
          )
          .toSpec();

      expect(
        spec,
        const PlotSpec<Fruit>(
          data: fruits,
          marks: <Mark<Fruit>>[
            DonutMark<Fruit>(
              id: 'mark-0',
              category: fruitName,
              value: fruitCount,
              name: 'Fruit',
              center: DonutCenterContent(label: 'Total'),
              style: DonutChartStyle(innerRadiusFactor: 0.5),
            ),
          ],
        ),
      );
    });
  });
```

- [ ] **Step 2: Run to verify it fails**

Run: `flutter test test/unit/grammar/chart_builder_radial_test.dart --plain-name geomDonut`
Expected: FAIL — `geomDonut` is not defined.

- [ ] **Step 3: Add `geomDonut` to `chart_builder.dart`** — after `geomPie`:

```dart
  /// Appends a donut. With [ring] set, rows partition into concentric donuts
  /// (one per distinct ring value, first-seen order); without it, a single
  /// donut. [value] is the angle-share; [radius] is an optional variable
  /// radius. Rich styling is deferred to [style]/[center]/[dataLabels].
  BravenChart<T> geomDonut({
    required FieldAccessor<T, Object?> category,
    required FieldAccessor<T, num> value,
    FieldAccessor<T, num>? radius,
    FieldAccessor<T, Object?>? ring,
    String? id,
    String? name,
    Color? color,
    DonutChartStyle? style,
    DonutCenterContent? center,
    PieDataLabelConfig? dataLabels,
  }) => _append(
    DonutMark<T>(
      id: _idFor(id),
      category: category,
      value: value,
      radius: radius,
      ring: ring,
      name: name,
      color: color,
      style: style,
      center: center,
      dataLabels: dataLabels,
    ),
  );
```

Extend the `pie_chart_config.dart` import already added in Task 4, and add the donut types import beside it:

```dart
import '../models/donut_chart_config.dart'
    show DonutCenterContent, DonutChartStyle;
```

- [ ] **Step 4: Run to verify it passes**

Run: `flutter test test/unit/grammar/chart_builder_radial_test.dart --plain-name geomDonut`
Expected: PASS.

- [ ] **Step 5: Write the failing lowering test** — add to `plot_lowering_radial_test.dart`'s `main()`:

```dart
  group('donut channel to series mapping and parity', () {
    test('a single donut lowers to one DonutChartSeries, no concentric config',
        () {
      final lowered = (const PlotSpec<Fruit>(
        data: fruits,
        marks: <Mark<Fruit>>[
          DonutMark<Fruit>(category: fruitName, value: fruitCount, id: 'fruit'),
        ],
      )).lower();

      expect(lowered.series, hasLength(1));
      final series = lowered.series.single as DonutChartSeries;
      expect(series.id, 'fruit');
      expect(series.points.map((p) => p.label), ['Apple', 'Pear', 'Plum']);
      expect(series.points.map((p) => p.y), [30, 20, 10]);
      expect(lowered.concentricDonutConfig, isNull);
      expect(lowered.polarChartConfig, isNull);
    });

    test('a lowered donut equals the hand-built DonutChartSeries.fromMap', () {
      final lowered = (const PlotSpec<Fruit>(
        data: fruits,
        marks: <Mark<Fruit>>[
          DonutMark<Fruit>(
            category: fruitName,
            value: fruitCount,
            id: 'fruit',
            center: DonutCenterContent(label: 'Total'),
          ),
        ],
      )).lower();

      expect(
        lowered.series.single,
        DonutChartSeries.fromMap(
          id: 'fruit',
          values: const {'Apple': 30, 'Pear': 20, 'Plum': 10},
          centerContent: const DonutCenterContent(label: 'Total'),
        ),
      );
    });
  });
```

- [ ] **Step 6: Run to verify it fails**

Run: `flutter test test/unit/grammar/plot_lowering_radial_test.dart --plain-name donut`
Expected: FAIL — the `DonutMark` path hits the `StateError('Unhandled radial mark')` fallback in `_lowerRadial`.

- [ ] **Step 7: Add the donut branch + builder.** In `plot_lowering.dart`, add the import near the pie import (Task 4):

```dart
import '../models/donut_chart_series.dart';
import '../models/donut_chart_config.dart';
```

In `_lowerRadial`, replace the `else` fallback block with a `DonutMark` branch before it:

```dart
  if (mark is PieMark<T>) {
    series.add(_lowerPie<T>(mark, markId, spec.data));
  } else if (mark is DonutMark<T>) {
    if (mark.ring == null) {
      series.add(_lowerDonut<T>(mark, markId, spec.data));
    } else {
      throw StateError('Concentric donut is wired in Phase 3');
    }
  } else {
    throw StateError('Unhandled radial mark: $mark');
  }
```

Append the builder (after `_lowerPie`):

```dart
DonutChartSeries _lowerDonut<T>(DonutMark<T> mark, String id, List<T> data) =>
    DonutChartSeries.fromMap(
      id: id,
      name: mark.name,
      color: mark.color,
      values: _radialValues(data, mark.category, mark.value),
      radiusValues: mark.radius == null
          ? const <String, num>{}
          : _radiusValues(data, mark.category, mark.radius!),
      donutStyle: mark.style ?? const DonutChartStyle(),
      centerContent: mark.center ?? DonutCenterContent.hidden,
      dataLabels: mark.dataLabels ?? const PieDataLabelConfig(),
    );
```

- [ ] **Step 8: Run analyze + the donut tests**

Run: `flutter analyze lib && flutter test test/unit/grammar/plot_lowering_radial_test.dart --plain-name donut`
Expected: analyze **No issues found**; donut mapping + parity PASS.

- [ ] **Step 9: Add the donut golden.** In `grammar_radial_golden_test.dart`, add a test inside `main()`:

```dart
  testWidgets('grammar-authored donut', (tester) async {
    final chart = BravenChart.of(_fruits)
        .geomDonut(
          category: fruitName,
          value: fruitCount,
          center: const DonutCenterContent(label: 'Total'),
          style: const DonutChartStyle(animationMode: PieAnimationMode.none),
        )
        .title('Harvest share')
        .theme(_goldenTheme())
        .build();
    await _pump(tester, chart, const Size(560, 380));
    await _expectGolden(tester, 'goldens/grammar_donut.png');
  });
```

- [ ] **Step 10: Generate + verify the donut golden**

Run: `flutter test test/golden/grammar_radial/grammar_radial_golden_test.dart --update-goldens && flutter test test/golden/grammar_radial/grammar_radial_golden_test.dart`
Expected: both PASS; `goldens/grammar_donut.png` written and re-matched.

- [ ] **Step 11: Commit**

```bash
git add lib/src/grammar/chart_builder.dart lib/src/grammar/plot_lowering.dart test/unit/grammar/chart_builder_radial_test.dart test/unit/grammar/plot_lowering_radial_test.dart test/golden/grammar_radial/grammar_radial_golden_test.dart test/golden/grammar_radial/goldens/grammar_donut.png
git commit -m "feat(grammar): geomDonut lowers to a single DonutChartSeries"
```

---

# Phase 3 — Concentric donut (the `ring` channel)

Adds the ring-partitioning lowering: N `DonutChartSeries` (first-seen ring order) + `ConcentricDonutConfig`. The `geomDonut(ring:)` verb already exists (Phase 2).

## Task 7: `ring` channel → concentric lowering

**Files:**
- Modify: `lib/src/grammar/plot_lowering.dart` (implement the ring branch; add `_lowerConcentricRings`)
- Test: `test/unit/grammar/plot_lowering_radial_test.dart` (add a concentric group)

**Interfaces:**
- Consumes: `DonutMark<T>.ring`/`.center` (Task 1); `_radialValues`/`_radiusValues` (Task 4); `DonutChartSeries.fromMap`; `ConcentricDonutConfig`.
- Produces: `List<DonutChartSeries> _lowerConcentricRings<T>(DonutMark<T> mark, String markId, List<T> data)`

- [ ] **Step 1: Write the failing test** — add to `plot_lowering_radial_test.dart`'s `main()`:

```dart
  group('concentric donut (ring channel)', () {
    test('rings partition rows in first-seen order with a ConcentricDonutConfig',
        () {
      final lowered = (const PlotSpec<Fruit>(
        data: fruits,
        marks: <Mark<Fruit>>[
          DonutMark<Fruit>(
            category: fruitName,
            value: fruitCount,
            ring: fruitBasket,
            id: 'fruit',
          ),
        ],
      )).lower();

      // baskets in first-seen order: A (Apple, Pear), B (Plum).
      expect(lowered.series, hasLength(2));
      expect(lowered.series.map((s) => s.id), ['fruit-A', 'fruit-B']);
      final ringA = lowered.series.first as DonutChartSeries;
      final ringB = lowered.series.last as DonutChartSeries;
      expect(ringA.points.map((p) => p.label), ['Apple', 'Pear']);
      expect(ringA.points.map((p) => p.y), [30, 20]);
      expect(ringB.points.map((p) => p.label), ['Plum']);
      expect(ringB.points.map((p) => p.y), [10]);
      expect(lowered.concentricDonutConfig, const ConcentricDonutConfig());
      expect(lowered.polarChartConfig, isNull);
    });

    test('each ring donut parity + shared center goes to the config', () {
      final lowered = (const PlotSpec<Fruit>(
        data: fruits,
        marks: <Mark<Fruit>>[
          DonutMark<Fruit>(
            category: fruitName,
            value: fruitCount,
            ring: fruitBasket,
            id: 'fruit',
            center: DonutCenterContent(label: 'All'),
          ),
        ],
      )).lower();

      expect(
        lowered.series.first,
        DonutChartSeries.fromMap(
          id: 'fruit-A',
          name: 'A',
          values: const {'Apple': 30, 'Pear': 20},
          centerContent: DonutCenterContent.hidden,
        ),
      );
      expect(
        lowered.concentricDonutConfig,
        const ConcentricDonutConfig(
          centerContent: DonutCenterContent(label: 'All'),
        ),
      );
    });

    test('a single-value ring collapses to one ring donut (not an error)', () {
      const oneBasket = <Fruit>[
        Fruit(name: 'Apple', count: 30, basket: 'A'),
        Fruit(name: 'Pear', count: 20, basket: 'A'),
      ];
      final lowered = (const PlotSpec<Fruit>(
        data: oneBasket,
        marks: <Mark<Fruit>>[
          DonutMark<Fruit>(
            category: fruitName,
            value: fruitCount,
            ring: fruitBasket,
            id: 'fruit',
          ),
        ],
      )).lower();

      expect(lowered.series, hasLength(1));
      expect(lowered.series.single.id, 'fruit-A');
      expect(lowered.concentricDonutConfig, const ConcentricDonutConfig());
    });
  });
```

- [ ] **Step 2: Run to verify it fails**

Run: `flutter test test/unit/grammar/plot_lowering_radial_test.dart --plain-name concentric`
Expected: FAIL — the ring branch throws `StateError('Concentric donut is wired in Phase 3')`.

- [ ] **Step 3: Implement the ring branch.** In `_lowerRadial`, replace the ring-branch `throw StateError('Concentric donut is wired in Phase 3');` with:

```dart
      final rings = _lowerConcentricRings<T>(mark, markId, spec.data);
      series.addAll(rings);
      concentric = mark.center == null
          ? const ConcentricDonutConfig()
          : ConcentricDonutConfig(centerContent: mark.center!);
```

Append the helper (after `_lowerDonut`):

```dart
/// Partitions [data] by the donut mark's ring accessor (first-seen order) and
/// builds one `DonutChartSeries` per ring. The shared center is carried by the
/// composition's `ConcentricDonutConfig`, so each ring donut's own center is
/// hidden.
List<DonutChartSeries> _lowerConcentricRings<T>(
  DonutMark<T> mark,
  String markId,
  List<T> data,
) {
  final order = <String>[];
  final buckets = <String, List<T>>{};
  for (final row in data) {
    final key = mark.ring!(row).toString();
    buckets.putIfAbsent(key, () {
      order.add(key);
      return <T>[];
    }).add(row);
  }
  return <DonutChartSeries>[
    for (final key in order)
      DonutChartSeries.fromMap(
        id: '$markId-$key',
        name: key,
        values: _radialValues(buckets[key]!, mark.category, mark.value),
        radiusValues: mark.radius == null
            ? const <String, num>{}
            : _radiusValues(buckets[key]!, mark.category, mark.radius!),
        donutStyle: mark.style ?? const DonutChartStyle(),
        centerContent: DonutCenterContent.hidden,
        dataLabels: mark.dataLabels ?? const PieDataLabelConfig(),
      ),
  ];
}
```

- [ ] **Step 4: Run analyze + the concentric tests**

Run: `flutter analyze lib && flutter test test/unit/grammar/plot_lowering_radial_test.dart --plain-name concentric`
Expected: analyze **No issues found**; concentric mapping/parity/collapse PASS.

- [ ] **Step 5: Add the concentric golden.** In `grammar_radial_golden_test.dart`, add:

```dart
  testWidgets('grammar-authored concentric donut', (tester) async {
    final chart = BravenChart.of(_fruits)
        .geomDonut(
          category: fruitName,
          value: fruitCount,
          ring: fruitBasket,
          style: const DonutChartStyle(animationMode: PieAnimationMode.none),
          dataLabels: const PieDataLabelConfig(isVisible: false),
        )
        .title('Harvest by season')
        .legend(true)
        .theme(_goldenTheme())
        .build();
    await _pump(tester, chart, const Size(560, 460));
    await _expectGolden(tester, 'goldens/grammar_concentric.png');
  });
```

- [ ] **Step 6: Generate + verify the concentric golden**

Run: `flutter test test/golden/grammar_radial/grammar_radial_golden_test.dart --update-goldens && flutter test test/golden/grammar_radial/grammar_radial_golden_test.dart`
Expected: both PASS; `goldens/grammar_concentric.png` written and re-matched. (This golden also proves `BravenPlot` forwards `concentricDonutConfig` to `BravenChartPlus`.)

- [ ] **Step 7: Commit**

```bash
git add lib/src/grammar/plot_lowering.dart test/unit/grammar/plot_lowering_radial_test.dart test/golden/grammar_radial/grammar_radial_golden_test.dart test/golden/grammar_radial/goldens/grammar_concentric.png
git commit -m "feat(grammar): geomDonut(ring:) lowers to concentric DonutChartSeries + ConcentricDonutConfig"
```

---

# Phase 4 — Polar column + showcase

## Task 8: `geomPolar` + lowering

**Files:**
- Modify: `lib/src/grammar/chart_builder.dart` (add `geomPolar`; add the polar-style import)
- Modify: `lib/src/grammar/plot_lowering.dart` (add a `PolarMark` branch; add `_lowerPolar`; add imports)
- Test: `test/unit/grammar/chart_builder_radial_test.dart` (add a `geomPolar` group)
- Test: `test/unit/grammar/plot_lowering_radial_test.dart` (add a polar group)

**Interfaces:**
- Consumes: `PolarMark<T>` (Task 1); `_radialValues` (Task 4); `PolarColumnChartSeries.fromMap` + `PolarColumnStyle` (`polar_column_chart_series.dart`); `PolarChartConfig` (`polar_chart_config.dart`).
- Produces:
  - `BravenChart<T> geomPolar({required FieldAccessor<T, Object?> category, required FieldAccessor<T, num> value, String? id, String? name, Color? color, PolarColumnStyle? style})`
  - `PolarColumnChartSeries _lowerPolar<T>(PolarMark<T> mark, String id, List<T> data)`

- [ ] **Step 1: Write the failing facade test** — add to `chart_builder_radial_test.dart`'s `main()`:

```dart
  group('geomPolar equals the hand-written spec', () {
    test('geomPolar appends a PolarMark with its channels and style', () {
      final spec = BravenChart.of(fruits)
          .geomPolar(
            category: fruitName,
            value: fruitCount,
            name: 'Fruit',
            style: const PolarColumnStyle(cornerRadius: 6),
          )
          .toSpec();

      expect(
        spec,
        const PlotSpec<Fruit>(
          data: fruits,
          marks: <Mark<Fruit>>[
            PolarMark<Fruit>(
              id: 'mark-0',
              category: fruitName,
              value: fruitCount,
              name: 'Fruit',
              style: PolarColumnStyle(cornerRadius: 6),
            ),
          ],
        ),
      );
    });
  });
```

- [ ] **Step 2: Run to verify it fails**

Run: `flutter test test/unit/grammar/chart_builder_radial_test.dart --plain-name geomPolar`
Expected: FAIL — `geomPolar` is not defined.

- [ ] **Step 3: Add `geomPolar` to `chart_builder.dart`** — after `geomDonut`:

```dart
  /// Appends a polar column: [category] is the angular position and [value] is
  /// the radius (magnitude) — values are NOT converted into pie shares. Rich
  /// styling (labels, gradients, shadows) is deferred to [style].
  BravenChart<T> geomPolar({
    required FieldAccessor<T, Object?> category,
    required FieldAccessor<T, num> value,
    String? id,
    String? name,
    Color? color,
    PolarColumnStyle? style,
  }) => _append(
    PolarMark<T>(
      id: _idFor(id),
      category: category,
      value: value,
      name: name,
      color: color,
      style: style,
    ),
  );
```

Add the polar-style import beside the pie/donut imports:

```dart
import '../models/polar_column_chart_series.dart' show PolarColumnStyle;
```

- [ ] **Step 4: Run to verify it passes**

Run: `flutter test test/unit/grammar/chart_builder_radial_test.dart --plain-name geomPolar`
Expected: PASS.

- [ ] **Step 5: Write the failing lowering test** — add to `plot_lowering_radial_test.dart`'s `main()`:

```dart
  group('polar column channel to series mapping and parity', () {
    test('category maps to angular position and value to radius', () {
      final lowered = (const PlotSpec<Fruit>(
        data: fruits,
        marks: <Mark<Fruit>>[
          PolarMark<Fruit>(category: fruitName, value: fruitCount, id: 'fruit'),
        ],
      )).lower();

      expect(lowered.series, hasLength(1));
      final series = lowered.series.single as PolarColumnChartSeries;
      expect(series.id, 'fruit');
      expect(series.categories, ['Apple', 'Pear', 'Plum']);
      expect(series.points.map((p) => p.x), [0, 1, 2]);
      expect(series.points.map((p) => p.y), [30, 20, 10]);
      expect(lowered.polarChartConfig, const PolarChartConfig());
      expect(lowered.concentricDonutConfig, isNull);
    });

    test('a lowered polar equals the hand-built PolarColumnChartSeries.fromMap',
        () {
      final lowered = (const PlotSpec<Fruit>(
        data: fruits,
        marks: <Mark<Fruit>>[
          PolarMark<Fruit>(
            category: fruitName,
            value: fruitCount,
            id: 'fruit',
            name: 'Fruit',
          ),
        ],
      )).lower();

      expect(
        lowered.series.single,
        PolarColumnChartSeries.fromMap(
          id: 'fruit',
          name: 'Fruit',
          values: const {'Apple': 30, 'Pear': 20, 'Plum': 10},
        ),
      );
    });
  });
```

- [ ] **Step 6: Run to verify it fails**

Run: `flutter test test/unit/grammar/plot_lowering_radial_test.dart --plain-name polar`
Expected: FAIL — the `PolarMark` path hits the `StateError('Unhandled radial mark')` fallback.

- [ ] **Step 7: Add the polar branch + builder.** In `plot_lowering.dart`, add the import beside the polar-config import (from Task 2):

```dart
import '../models/polar_column_chart_series.dart';
```

In `_lowerRadial`, add a `PolarMark` branch before the final `else`:

```dart
  } else if (mark is PolarMark<T>) {
    series.add(_lowerPolar<T>(mark, markId, spec.data));
    polar = const PolarChartConfig();
  } else {
    throw StateError('Unhandled radial mark: $mark');
  }
```

Append the builder (after `_lowerConcentricRings`):

```dart
PolarColumnChartSeries _lowerPolar<T>(
  PolarMark<T> mark,
  String id,
  List<T> data,
) => PolarColumnChartSeries.fromMap(
  id: id,
  name: mark.name,
  color: mark.color,
  values: _radialValues(data, mark.category, mark.value),
  polarStyle: mark.style ?? const PolarColumnStyle(),
);
```

- [ ] **Step 8: Run analyze + the polar tests + the whole radial + grammar suite**

Run: `flutter analyze lib && flutter test test/unit/grammar/`
Expected: analyze **No issues found**; every grammar test (Cartesian + radial) PASSES.

- [ ] **Step 9: Add the polar golden.** In `grammar_radial_golden_test.dart`, add:

```dart
  testWidgets('grammar-authored polar column', (tester) async {
    final chart = BravenChart.of(_fruits)
        .geomPolar(
          category: fruitName,
          value: fruitCount,
          style: const PolarColumnStyle(
            cornerRadius: 4,
            animationMode: PolarColumnAnimationMode.none,
          ),
        )
        .title('Harvest by fruit')
        .theme(_goldenTheme())
        .build();
    await _pump(tester, chart, const Size(560, 460));
    await _expectGolden(tester, 'goldens/grammar_polar.png');
  });
```

- [ ] **Step 10: Generate + verify the polar golden**

Run: `flutter test test/golden/grammar_radial/grammar_radial_golden_test.dart --update-goldens && flutter test test/golden/grammar_radial/grammar_radial_golden_test.dart`
Expected: both PASS; `goldens/grammar_polar.png` written and re-matched. (Proves `BravenPlot` forwards `polarChartConfig`.)

- [ ] **Step 11: Commit**

```bash
git add lib/src/grammar/chart_builder.dart lib/src/grammar/plot_lowering.dart test/unit/grammar/chart_builder_radial_test.dart test/unit/grammar/plot_lowering_radial_test.dart test/golden/grammar_radial/grammar_radial_golden_test.dart test/golden/grammar_radial/goldens/grammar_polar.png
git commit -m "feat(grammar): geomPolar lowers to PolarColumnChartSeries + PolarChartConfig"
```

---

## Task 9: Chart Grammar showcase radial preset

Adds one `radial` preset to the Chart Grammar page with a Pie / Donut / Concentric / Polar sub-family selector, each authored via the grammar with a hand-built equivalent for the "Compare hand-built" toggle.

**Files:**
- Modify: `example/lib/showcase/pages/chart_grammar_page.dart`
- Test: `example/test/showcase/chart_grammar_radial_preset_test.dart` (create)

**Interfaces:**
- Consumes: `geomPie`/`geomDonut`/`geomPolar` + `.build()` (Tasks 4/6/8); `PieChartSeries.fromMap`/`DonutChartSeries.fromMap`/`PolarColumnChartSeries.fromMap`/`ConcentricDonutConfig` for the hand-built equivalents.
- Produces: a `_GrammarPreset.radial` entry + a `_RadialFamily` enum with a segmented control.

- [ ] **Step 1: Extend the row type and data.** In `chart_grammar_page.dart`, in `class GrammarSample`, add a field to the constructor (after `this.close = 0,`):

```dart
    this.group = '',
```

and a field (after `final double close;`):

```dart
  /// The concentric-ring group for the radial preset (e.g. a season).
  final String group;
```

Add an accessor beside the others (after `double sampleClose(...)`):

```dart
Object sampleGroup(GrammarSample row) => row.group;
```

Add the radial rows constant after `candleRows`:

```dart
/// Harvest counts by fruit and season — the radial preset's rows. `zone`
/// carries the category label and `group` the concentric-ring season.
const List<GrammarSample> harvestRows = <GrammarSample>[
  GrammarSample(minute: 0, minutes: 42, zone: 'Apple', group: 'Winter'),
  GrammarSample(minute: 1, minutes: 31, zone: 'Pear', group: 'Winter'),
  GrammarSample(minute: 2, minutes: 17, zone: 'Plum', group: 'Summer'),
  GrammarSample(minute: 3, minutes: 10, zone: 'Fig', group: 'Summer'),
];
```

- [ ] **Step 2: Add the sub-family enum + state.** Below the existing `enum _GrammarPreset { ... }` region (near the file's other enums at the bottom), add:

```dart
enum _RadialFamily { pie, donut, concentric, polar }
```

In `_ChartGrammarPageState`, add a field near the other knobs (after `_thresholdWatts`):

```dart
  // Radial preset knob.
  _RadialFamily _radialFamily = _RadialFamily.pie;
```

- [ ] **Step 3: Add the four grammar builders.** In `_ChartGrammarPageState`, after `_referenceLinesChart()`:

```dart
  /// The radial preset, authored through the chained facade only. A radial
  /// geom makes the spec radial: it lowers to the rich radial config family
  /// and honors no Cartesian axis/grid option.
  BravenChart<GrammarSample> _radialChart() {
    final base = BravenChart.of(harvestRows).theme(_theme);
    return switch (_radialFamily) {
      _RadialFamily.pie => base.geomPie(
        category: sampleZone,
        value: sampleMinutes,
        name: 'Harvest',
      ).title('Harvest share'),
      _RadialFamily.donut => base.geomDonut(
        category: sampleZone,
        value: sampleMinutes,
        name: 'Harvest',
        center: const DonutCenterContent(label: 'Total'),
      ).title('Harvest share'),
      _RadialFamily.concentric => base.geomDonut(
        category: sampleZone,
        value: sampleMinutes,
        ring: sampleGroup,
        dataLabels: const PieDataLabelConfig(isVisible: false),
      ).title('Harvest by season').legend(true),
      _RadialFamily.polar => base.geomPolar(
        category: sampleZone,
        value: sampleMinutes,
        name: 'Harvest',
      ).title('Harvest by fruit'),
    };
  }
```

- [ ] **Step 4: Add the four hand-built equivalents.** After `_handBuiltReferenceLines(...)`:

```dart
  Map<String, num> _harvestValues() => <String, num>{
    for (final row in harvestRows) row.zone: row.minutes,
  };

  Widget _handBuiltRadial(BravenChartController controller) {
    switch (_radialFamily) {
      case _RadialFamily.pie:
        return BravenChartPlus(
          key: const ValueKey('chart-grammar-stage-chart'),
          bravenChartController: controller,
          theme: _theme,
          title: 'Harvest share',
          series: <ChartSeries>[
            PieChartSeries.fromMap(
              id: 'mark-0',
              name: 'Harvest',
              values: _harvestValues(),
            ),
          ],
        );
      case _RadialFamily.donut:
        return BravenChartPlus(
          key: const ValueKey('chart-grammar-stage-chart'),
          bravenChartController: controller,
          theme: _theme,
          title: 'Harvest share',
          series: <ChartSeries>[
            DonutChartSeries.fromMap(
              id: 'mark-0',
              name: 'Harvest',
              values: _harvestValues(),
              centerContent: const DonutCenterContent(label: 'Total'),
            ),
          ],
        );
      case _RadialFamily.concentric:
        final order = <String>[];
        final buckets = <String, Map<String, num>>{};
        for (final row in harvestRows) {
          buckets.putIfAbsent(row.group, () {
            order.add(row.group);
            return <String, num>{};
          })[row.zone] = row.minutes;
        }
        return BravenChartPlus(
          key: const ValueKey('chart-grammar-stage-chart'),
          bravenChartController: controller,
          theme: _theme,
          title: 'Harvest by season',
          showLegend: true,
          series: <ChartSeries>[
            for (final group in order)
              DonutChartSeries.fromMap(
                id: 'mark-0-$group',
                name: group,
                values: buckets[group]!,
                dataLabels: const PieDataLabelConfig(isVisible: false),
              ),
          ],
        );
      case _RadialFamily.polar:
        return BravenChartPlus(
          key: const ValueKey('chart-grammar-stage-chart'),
          bravenChartController: controller,
          theme: _theme,
          title: 'Harvest by fruit',
          series: <ChartSeries>[
            PolarColumnChartSeries.fromMap(
              id: 'mark-0',
              name: 'Harvest',
              values: _harvestValues(),
            ),
          ],
        );
    }
  }
```

- [ ] **Step 5: Wire the preset into the enum + every `_GrammarPreset` switch.** Add `radial` to `enum _GrammarPreset` immediately before `barTransposed` (keep `barTransposed` last per its comment):

```dart
  referenceLines,
  radial,
  // barTransposed is kept LAST: ...
  barTransposed,
```

Add a `radial` arm to each of these switches (they will fail to compile until updated):
- `_activeChart` → `_GrammarPreset.radial => _radialChart(),`
- `_buildHandBuilt` → `_GrammarPreset.radial => _handBuiltRadial(controller),`
- `extension on _GrammarPreset` `label` → `_GrammarPreset.radial => 'Radial',`
- `icon` → `_GrammarPreset.radial => Icons.pie_chart_outline,`
- `stageTitle` → `_GrammarPreset.radial => 'Radial geoms: pie, donut, concentric, polar',`
- `stageSubtitle` → `_GrammarPreset.radial => 'A radial geom makes the spec radial — one geom, no Cartesian axes',`
- `guide` → `_GrammarPreset.radial => 'Switch families with the segmented control. Each is BravenChart.of(rows).geomPie/geomDonut/geomPolar — the ring channel splits a donut into concentric rings. Turn on "Compare hand-built" to see the PieChartSeries.fromMap / ConcentricDonutConfig the chain lowers to.',`

- [ ] **Step 6: Add the sub-family control.** In `_buildOptionsChildren`, the `Preset Controls` `switch (_preset)` (currently ending with `_GrammarPreset.candlestick => const <Widget>[],`) — add a `radial` arm:

```dart
            _GrammarPreset.radial => _radialControls(),
```

Add the control builder near the other `_*Controls()` methods:

```dart
  List<Widget> _radialControls() => [
    Text(
      'Radial family',
      style: TextStyle(fontSize: 12, color: Theme.of(context).hintColor),
    ),
    const SizedBox(height: 4),
    SegmentedOption<_RadialFamily>(
      key: const ValueKey('chart-grammar-radial-family'),
      value: _radialFamily,
      options: _RadialFamily.values,
      labelBuilder: (family) => switch (family) {
        _RadialFamily.pie => 'Pie',
        _RadialFamily.donut => 'Donut',
        _RadialFamily.concentric => 'Concentric',
        _RadialFamily.polar => 'Polar',
      },
      onChanged: (family) => setState(() => _radialFamily = family),
    ),
    const SizedBox(height: 4),
    const InfoBox(
      message:
          'geomPie/geomDonut/geomPolar carry their own channels. The donut '
          'ring channel partitions rows into concentric DonutChartSeries. A '
          'radial spec honors title, legend and theme, but a grid or axis '
          'option raises axisOptionOnRadialSpec.',
    ),
  ];
```

`hasControls` returns `this != _GrammarPreset.candlestick`, so `radial` already has controls — no change needed there.

- [ ] **Step 7: Run analyze on the example**

Run: `flutter analyze example/lib`
Expected: **No issues found** (every `_GrammarPreset` switch now has a `radial` arm).

- [ ] **Step 8: Write the widget smoke test** — `example/test/showcase/chart_grammar_radial_preset_test.dart`:

```dart
import 'package:braven_charts/braven_charts.dart';
import 'package:braven_charts_example/showcase/pages/chart_grammar_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('the radial preset renders every family without exception', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: ChartGrammarPage())),
    );
    await tester.pumpAndSettle();

    // Select the radial preset.
    await tester.tap(find.byKey(const ValueKey('chart-grammar-preset-radial')));
    await tester.pumpAndSettle();

    for (final family in const ['Pie', 'Donut', 'Concentric', 'Polar']) {
      await tester.tap(find.text(family).last);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(BravenPlot), findsOneWidget);
    }
  });
}
```

(The example package `name:` in `example/pubspec.yaml` is `braven_charts_example`, matching the import above.)

- [ ] **Step 9: Run the smoke test**

Run (from the example package): `cd example && flutter test test/showcase/chart_grammar_radial_preset_test.dart`
Expected: PASS — each family renders a `BravenPlot`, no exceptions.

- [ ] **Step 10: Final full verification**

Run: `flutter analyze lib && flutter analyze example/lib && flutter test test/unit/grammar/ test/golden/grammar_radial/`
Expected: analyze **No issues found** (both); every grammar unit test and every radial golden PASS.

- [ ] **Step 11: Commit**

```bash
git add example/lib/showcase/pages/chart_grammar_page.dart example/test/showcase/chart_grammar_radial_preset_test.dart
git commit -m "feat(showcase): radial grammar preset (pie/donut/concentric/polar) with hand-built parity"
```

---

## Self-Review

### 1. Spec coverage

| Spec section / requirement | Task |
|---|---|
| Approach A — dedicated radial geoms on `BravenChart<T>` | Tasks 4/6/8 (verbs) + Task 1 (marks) |
| `geomPie` (category, value, radius?, style) | Task 4 |
| `geomDonut` (category, value, radius?, ring?, style, center) | Tasks 6 (single) + 7 (ring) |
| `geomPolar` (category, value, style) | Task 8 |
| A radial geom makes the spec radial; `.build()` reused, no new terminal | Task 2 (`isRadial`) + Task 4 (branch) + Global Constraints |
| Row→series mapping: whole dataset → one radial series; ring groups rows | Tasks 4/6/7/8 (`_radialValues`, `_lowerConcentricRings`) |
| Styling/config passthrough via real config objects | `style`/`center`/`dataLabels` params in Tasks 4/6/8 |
| Chart-level options: title/subtitle/legend/theme forwarded | Task 4 (`_lowerRadial` returns them) |
| Chart-level options: grid/xAxis/yAxis/transposed → `axisOptionOnRadialSpec` | Task 4 |
| `.facet(...)` on radial → `facetedRadialUnsupported` | Task 3 (code + factory only — see Deviations) |
| Lowering radial branch: Pie→fromMap, Donut→series, ring→N + ConcentricDonutConfig, Polar→PolarColumnChartSeries | Tasks 4/6/7/8 |
| 5 diagnostic codes + factories | Task 3 |
| Single-value ring collapses (not an error) | Task 7 (collapse test) |
| `radial_mark.dart` / sealed mechanics | Sealed-Mark Resolution (marks in `mark.dart`) |
| `mark.dart` admits radial variants | Task 1 |
| `chart_builder.dart` three geom verbs | Tasks 4/6/8 |
| `plot_lowering.dart` radial branch + coordinate detection + guards | Tasks 2/4 |
| `grammar_diagnostics.dart` new codes | Task 3 |
| `plot_spec.dart` `isRadial` helper | Task 2 |
| Core barrel exports the radial marks | Satisfied transitively (marks in already-exported `mark.dart`) — Sealed-Mark Resolution |
| Showcase radial preset | Task 9 |
| Per-family channel→series mapping tests (concrete values) | Tasks 4/6/7/8 |
| Config parity tests | Tasks 4/6/7/8 |
| Diagnostics tests (mixed, >1 radial, axis/grid, empty categories, faceted) | Tasks 3/4 |
| One golden per family, tolerant comparator from the start | Tasks 5/6/7/8 |

### 2. Placeholder scan

No `TBD`/`TODO`/"similar to Task N"/"handle edge cases". Every code step contains full code. The only `throw StateError('Concentric donut is wired in Phase 3')` and `throw StateError('Unhandled radial mark')` are **real, replaced-in-a-later-step** guards, not plan placeholders (each is explicitly replaced in a named later step, and the final `Unhandled radial mark` arm is permanent defensive code once all families are wired). The `facetedRadialUnsupported` guard has no runtime trigger — documented in Deviations, not hidden as a TODO.

### 3. Type consistency

- Mark field names (`category`, `value`, `radius`, `ring`, `style`, `center`, `dataLabels`) are identical across Task 1 declaration, Tasks 4/6/8 verbs, and the lowering. ✓
- `_radialValues`/`_radiusValues` signatures identical wherever called (Tasks 4/6/7/8). ✓
- `LoweredPlot.concentricDonutConfig`/`polarChartConfig` field names identical in Task 2, `_lowerRadial` (Task 4), the ring branch (Task 7), the polar branch (Task 8), and `BravenPlot` (Task 2). ✓
- Diagnostic factory names identical between Task 3 (definition) and Task 4 (use). ✓
- `_TolerantGoldenFileComparator` copied verbatim from the repo's pie golden; the field is a mutable `double precisionTolerance` (pie-golden variant), used identically across the four golden tests. ✓
- Showcase: `_RadialFamily` and `_GrammarPreset.radial` arm names consistent across every switch enumerated in Task 9. ✓

---

## Deviations from the spec (forced by real code)

1. **No `lib/src/grammar/radial_mark.dart`.** The spec's file structure says "Create `radial_mark.dart`", but `Mark<T>` is `sealed`, and Dart requires all direct subtypes in the same library. A standalone file cannot extend the sealed base. The radial marks are therefore declared in `mark.dart` (same library), matching the existing "all mark variants in `mark.dart`" pattern. Consequence: the core-barrel "export the radial marks" is satisfied transitively (`mark.dart` is already exported) — **no `lib/braven_charts.dart` edit**.

2. **Added a `sealed class RadialMark<T>` intermediate** not literally named in the spec (the spec says "sealed `PieMark`/`DonutMark`/`PolarMark` as variants of `Mark<T>`"). The intermediate is what makes `isRadial` a one-line check and collapses the exhaustive-`switch` fallout (across `plot_lowering.dart`, `chart_grammar_source_generator.dart`, `plot_spec_test.dart`) to a single `case RadialMark<…>()` arm per site instead of three. The concrete marks are still the three the spec names.

3. **`facetedRadialUnsupported` has no runtime trigger in this repo.** The spec assumes faceting ("the codes faceting recently added", "unlike faceting's `buildFaceted`"), but **faceting does not exist in `braven_charts-convergence`** — there is no `.facet()` verb, no facet field on `PlotSpec`, and no `buildFaceted` terminal (grep of the whole repo finds "facet" only in this spec doc). The diagnostic code + factory are added and tested at construction (Task 3), matching the existing "every diagnostic names its code" idiom, but the **lowering guard that would fire it is dormant** until faceting lands. This is consistent with the spec's own "Out of scope: Radial faceting."

4. **The plan follows the EXISTING diagnostic idiom in `grammar_diagnostics.dart`**, not a "faceting" idiom (which does not exist here): an `enum GrammarDiagnosticCode` value plus a named `factory GrammarSpecException.<name>(...)` constructor, exactly as the current 15 codes are written.

5. **`BravenPlot` and `LoweredPlot` are extended** to carry/forward `concentricDonutConfig` and `polarChartConfig`. The spec's lowering section says "Wrap in a radial `BravenChartPlus`" but does not spell out that `BravenPlot` currently forwards neither config; the plan adds that plumbing (Task 2), which is required for concentric and polar to render.

6. **Duplicate categories collapse (last row wins)** because the lowering routes through the families' `fromMap(values: Map<String,num>)`, exactly as the spec says ("`PieChartSeries.fromMap`-equivalent"). Documented on `_radialValues`. Partially-blank category labels (some blank, some visible) surface the family's own `ArgumentError`; only the ALL-blank case is converted to `emptyRadialCategories` (matching the "empty categories" name). This is a scoping choice, not a spec conflict.

---

**Plan complete and saved to `docs/superpowers/plans/2026-07-23-grammar-radial-marks.md`. Two execution options:**

**1. Subagent-Driven (recommended)** — dispatch a fresh subagent per task, review between tasks, fast iteration.

**2. Inline Execution** — execute tasks in this session using executing-plans, batch execution with checkpoints.

**Which approach?**
