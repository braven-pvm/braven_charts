# Grammar Faceting Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add `.facet(by:)` to the `BravenChart` grammar so one `PlotSpec` renders as N synchronized small-multiple panels — one per distinct value of a categorical field — laid out in a grid.

**Architecture:** `.facet(...)` sets an immutable `FacetSpec<T>` as an optional field on `PlotSpec` (faceting is part of the plot object, ggplot2-style). A distinct terminal `.buildFaceted()` returns a `BravenFacetPlot<T>` that partitions the rows, builds one facet-cleared, range-injected `PlotSpec` per distinct value, lowers each through the existing `PlotSpec.lower()` inside a `BravenPlot`, and lays the panels out in a grid wired to one shared `ChartInteractionGroupController`. The only genuinely new logic is global-range computation and the grid/strip layout; everything else is composition over primitives that already exist (`PlotSpec.lower()`, `BravenPlot`, `ChartInteractionGroupController`).

**Tech Stack:** Dart 3 / Flutter, `package:braven_charts` (grammar layer under `lib/src/grammar/`), `flutter_test`, `golden_toolkit` (existing goldens), the `braven_charts_example` showcase app.

## Global Constraints

Every task's requirements implicitly include this section. Values are copied verbatim from `docs/superpowers/specs/2026-07-23-grammar-faceting-design.md`.

- **facet-wrap only** (1-D: partition by ONE field). facet-grid (2-D matrix) is explicitly OUT of scope.
- **Scales:** `FacetScales.fixed` (default, both axes shared) | `freeX` | `freeY` | `free`.
- **Scale sharing:** a shared axis injects the *global* min/max across ALL rows (from the marks' x/y channels) as an explicit `XAxisConfig(min:,max:)` / `YAxisConfig(min:,max:)` into every panel's `PlotSpec`; a free axis injects no range override.
- **Synced interaction is active ONLY when x is shared** — i.e. `fixed` and `freeY`. Under `freeX`/`free`, panels get NO shared controller (independent interaction), documented not silently broken.
- **Panel cap: 50.** Exceeding it is a grammar diagnostic, not a silent large render.
- **Partition order:** distinct facet values in FIRST-SEEN (data) order; a **null** facet value is a valid distinct value → its own panel; value equality (`==`) partitions rows.
- **`PlotSpec` remains the single, complete description** of a chart, faceting included. Non-faceted authoring is completely unaffected (`facet == null` behaves exactly as today).
- **`FacetSpec` and `BravenFacetPlot` hold accessor functions** → like `Mark`/`PlotSpec` they have **NO `copyWith` and NO `@chartSurface`** (they never enter the config drift gates / `test/meta/surface_enforcement_test.dart`).
- **The grammar lives in the CORE barrel** `lib/braven_charts.dart` (export `FacetSpec`/`FacetScales`/`BravenFacetPlot`).
- **`.build()` on a faceted spec throws** (directing to `.buildFaceted()`); **`.buildFaceted()` on a non-faceted spec throws**; **`PlotSpec.lower()` on a faceted spec throws** (single-panel invariant).
- **Reuse only** — no new coordinate system, no render-pipeline change: `PlotSpec.lower()` per panel, `BravenPlot`, `ChartInteractionGroupController`.
- **Strip labels reuse the active `ChartTheme`'s typography** (font family + label size) — NO new theme component in v1.
- **Analyze clean with `flutter analyze lib` (NOT root** — the root analyze is polluted by the vendored `packages/fleather`; CI runs `flutter analyze lib`). Run `flutter test` for the package suite; `cd example && flutter analyze lib` / `flutter test` for the showcase.
- **Out of scope (do NOT build):** artifact capture/restore of a faceted grid (a grid is N `ChartConfiguration`s), facet-grid, per-facet independent marks / ragged grids, faceting-aware shared legends.

---

## File Structure

Each file has ONE responsibility.

| File | Create/Modify | Responsibility |
|------|---------------|----------------|
| `lib/src/grammar/facet_spec.dart` | Create | `FacetScales` enum + `FacetScalesSharing` extension + immutable `FacetSpec<T>` value (by, columns, scales, label). No copyWith. |
| `lib/src/grammar/plot_spec.dart` | Modify | Add optional `FacetSpec<T>? facet` field (single complete description) + `facetCleared()` helper; plumb through `==`/`hashCode`. |
| `lib/src/grammar/chart_builder.dart` | Modify | Add `.facet(...)` verb (sets `PlotSpec.facet`), the `.build()` guard, and the `.buildFaceted()` terminal. |
| `lib/src/grammar/grammar_diagnostics.dart` | Modify | Facet diagnostics: faceted-spec-not-lowerable, not-faceted, empty-facet-values, panel-cap-exceeded. |
| `lib/src/grammar/plot_lowering.dart` | Modify | `lower()` throws on a faceted spec (single-panel invariant). |
| `lib/src/grammar/facet_partition.dart` | Create | Pure helpers: `distinctFacetValues`, `globalRange` (+ `FacetAxis`/`FacetRange`), `autoColumns`. Unit-testable in isolation. |
| `lib/src/grammar/braven_facet_plot.dart` | Create | `BravenFacetPlot<T>` widget + `BravenFacetPanel<T>` + `resolveFacetPanels`: partition → per-facet range-injected facet-cleared `PlotSpec` → grid of `BravenPlot`s + strips → one shared controller. |
| `lib/braven_charts.dart` | Modify | Export `facet_spec.dart` and `braven_facet_plot.dart` in the Grammar block. |
| `example/lib/showcase/pages/chart_grammar_page.dart` | Modify | A `faceted` preset that renders a `BravenFacetPlot` with `FacetScales` + columns controls. |
| Tests | Create/Modify | Per task (see below). |

---

### Task 1: `FacetSpec<T>` + `FacetScales` enum

**Files:**
- Create: `lib/src/grammar/facet_spec.dart`
- Modify: `lib/braven_charts.dart` (Grammar export block, after `export 'src/grammar/channel.dart';`)
- Test: `test/unit/grammar/facet_spec_test.dart`

**Interfaces:**
- Consumes: `typedef FieldAccessor<T, V> = V Function(T row);` from `lib/src/grammar/channel.dart`.
- Produces:
  - `enum FacetScales { fixed, freeX, freeY, free }`
  - `extension FacetScalesSharing on FacetScales { bool get sharesX; bool get sharesY; bool get syncsInteraction; }` where `sharesX == (fixed || freeY)`, `sharesY == (fixed || freeX)`, `syncsInteraction == sharesX`.
  - `class FacetSpec<T> { const FacetSpec({required FieldAccessor<T, Object?> by, int? columns, FacetScales scales = FacetScales.fixed, String? label}); final FieldAccessor<T, Object?> by; final int? columns; final FacetScales scales; final String? label; }` — value equality (`by` by identity), NO copyWith.

- [ ] **Step 1: Write the failing test**

Create `test/unit/grammar/facet_spec_test.dart`:

```dart
// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

/// Value semantics and scale-sharing rules for [FacetSpec] / [FacetScales].
///
/// Like [Mark], a [FacetSpec] holds an accessor function, so it has value
/// equality (the accessor compared by IDENTITY) and NO copyWith — it never
/// enters the config surface. Accessors are top-level tear-offs so equality is
/// stable.
library;

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter_test/flutter_test.dart';

class Sample {
  const Sample({required this.zone});
  final String zone;
}

Object? sampleZone(Sample row) => row.zone;
Object? sampleOther(Sample row) => row.zone.length;

void main() {
  group('scale sharing', () {
    test('sharesX is true only for fixed and freeY', () {
      expect(FacetScales.fixed.sharesX, isTrue);
      expect(FacetScales.freeY.sharesX, isTrue);
      expect(FacetScales.freeX.sharesX, isFalse);
      expect(FacetScales.free.sharesX, isFalse);
    });

    test('sharesY is true only for fixed and freeX', () {
      expect(FacetScales.fixed.sharesY, isTrue);
      expect(FacetScales.freeX.sharesY, isTrue);
      expect(FacetScales.freeY.sharesY, isFalse);
      expect(FacetScales.free.sharesY, isFalse);
    });

    test('syncsInteraction mirrors sharesX', () {
      for (final scales in FacetScales.values) {
        expect(scales.syncsInteraction, scales.sharesX);
      }
    });
  });

  group('value semantics', () {
    test('defaults to fixed scales and null columns/label', () {
      const spec = FacetSpec<Sample>(by: sampleZone);
      expect(spec.scales, FacetScales.fixed);
      expect(spec.columns, isNull);
      expect(spec.label, isNull);
    });

    test('two facet specs over the same tear-off are equal', () {
      expect(
        const FacetSpec<Sample>(by: sampleZone, columns: 2, label: 'Zone'),
        const FacetSpec<Sample>(by: sampleZone, columns: 2, label: 'Zone'),
      );
      expect(
        const FacetSpec<Sample>(by: sampleZone, columns: 2, label: 'Zone')
            .hashCode,
        const FacetSpec<Sample>(by: sampleZone, columns: 2, label: 'Zone')
            .hashCode,
      );
    });

    test('a different accessor, columns, scales or label is not equal', () {
      expect(
        const FacetSpec<Sample>(by: sampleZone),
        isNot(const FacetSpec<Sample>(by: sampleOther)),
      );
      expect(
        const FacetSpec<Sample>(by: sampleZone, columns: 2),
        isNot(const FacetSpec<Sample>(by: sampleZone, columns: 3)),
      );
      expect(
        const FacetSpec<Sample>(by: sampleZone, scales: FacetScales.free),
        isNot(const FacetSpec<Sample>(by: sampleZone)),
      );
      expect(
        const FacetSpec<Sample>(by: sampleZone, label: 'Zone'),
        isNot(const FacetSpec<Sample>(by: sampleZone, label: 'Athlete')),
      );
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/unit/grammar/facet_spec_test.dart`
Expected: FAIL — compile error, `FacetSpec`/`FacetScales` are not defined / not exported.

- [ ] **Step 3: Write minimal implementation**

Create `lib/src/grammar/facet_spec.dart`:

```dart
// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

import 'channel.dart' show FieldAccessor;

/// How axes scale across facet panels.
///
/// | mode    | x shared | y shared |
/// |---------|----------|----------|
/// | [fixed] | yes      | yes      |
/// | [freeX] | no       | yes      |
/// | [freeY] | yes      | no       |
/// | [free]  | no       | no       |
enum FacetScales { fixed, freeX, freeY, free }

/// Which axes a [FacetScales] mode shares across panels, and whether
/// synchronized interaction is meaningful.
extension FacetScalesSharing on FacetScales {
  /// Whether the X axis carries one global range across every panel.
  bool get sharesX =>
      this == FacetScales.fixed || this == FacetScales.freeY;

  /// Whether the Y axis carries one global range across every panel.
  bool get sharesY =>
      this == FacetScales.fixed || this == FacetScales.freeX;

  /// Whether a shared crosshair-x is meaningful — it is only meaningful when
  /// x is shared, so synchronized interaction is active for [FacetScales.fixed]
  /// and [FacetScales.freeY] and OFF otherwise.
  bool get syncsInteraction => sharesX;
}

/// Immutable faceting configuration for a [PlotSpec].
///
/// Set through `BravenChart.facet(...)`; a non-faceted spec has `facet == null`
/// and behaves exactly as today. Like [Mark], this holds an accessor function,
/// so it is a grammar VALUE (value equality, the accessor compared by
/// identity) with NO `copyWith` and NO `@chartSurface` — it never enters the
/// config surface.
class FacetSpec<T> {
  /// Creates a facet configuration.
  const FacetSpec({
    required this.by,
    this.columns,
    this.scales = FacetScales.fixed,
    this.label,
  });

  /// Categorical field: one panel per distinct value, in first-seen order.
  final FieldAccessor<T, Object?> by;

  /// Grid columns. Null lays the grid out at `ceil(sqrt(panelCount))`.
  final int? columns;

  /// How the axes scale across panels.
  final FacetScales scales;

  /// Optional strip-label prefix, e.g. `'Athlete'`.
  final String? label;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FacetSpec<T> &&
          other.by == by &&
          other.columns == columns &&
          other.scales == scales &&
          other.label == label;

  @override
  int get hashCode => Object.hash(by, columns, scales, label);

  @override
  String toString() =>
      'FacetSpec(columns: $columns, scales: $scales, label: $label)';
}
```

- [ ] **Step 4: Add the barrel export**

In `lib/braven_charts.dart`, in the `// Grammar` block, add after the `braven_plot.dart` / `channel.dart` exports (anywhere inside the Grammar block) the line:

```dart
export 'src/grammar/facet_spec.dart';
```

- [ ] **Step 5: Run test to verify it passes**

Run: `flutter test test/unit/grammar/facet_spec_test.dart`
Expected: PASS — `All tests passed!`

- [ ] **Step 6: Analyze**

Run: `flutter analyze lib`
Expected: `No issues found!`

- [ ] **Step 7: Commit**

```bash
git add lib/src/grammar/facet_spec.dart lib/braven_charts.dart test/unit/grammar/facet_spec_test.dart
git commit -m "feat(grammar): add FacetSpec value type and FacetScales enum"
```

---

### Task 2: `PlotSpec.facet` field + `facetCleared()`

**Files:**
- Modify: `lib/src/grammar/plot_spec.dart`
- Test: `test/unit/grammar/plot_spec_test.dart` (add a `group`)

**Interfaces:**
- Consumes: `FacetSpec<T>` (Task 1).
- Produces:
  - `PlotSpec<T>` gains `final FacetSpec<T>? facet;` (constructor param `this.facet`, defaults null), included in `==`/`hashCode`.
  - `PlotSpec<T> facetCleared()` → a copy of the spec with `facet == null` and every other field identical.

- [ ] **Step 1: Write the failing test**

Append this `group` inside `main()` in `test/unit/grammar/plot_spec_test.dart` (the file's `Sample`/`sampleZone` tear-offs already exist; `sampleZone` returns `Object`, assignable to `FieldAccessor<Sample, Object?>`):

```dart
  group('facet field', () {
    test('facet defaults to null and a non-faceted spec is unchanged', () {
      const spec = PlotSpec<Sample>(
        data: <Sample>[],
        marks: <Mark<Sample>>[_line],
      );
      expect(spec.facet, isNull);
    });

    test('facet is carried on the spec and compared by value', () {
      const facet = FacetSpec<Sample>(by: sampleZone, columns: 2);
      const left = PlotSpec<Sample>(
        data: <Sample>[],
        marks: <Mark<Sample>>[_line],
        facet: facet,
      );
      const right = PlotSpec<Sample>(
        data: <Sample>[],
        marks: <Mark<Sample>>[_line],
        facet: facet,
      );
      expect(left, right);
      expect(left.hashCode, right.hashCode);
      expect(
        left,
        isNot(
          const PlotSpec<Sample>(
            data: <Sample>[],
            marks: <Mark<Sample>>[_line],
          ),
        ),
      );
    });

    test('facetCleared drops the facet and keeps everything else', () {
      const facet = FacetSpec<Sample>(by: sampleZone);
      const faceted = PlotSpec<Sample>(
        data: <Sample>[],
        marks: <Mark<Sample>>[_line],
        transposed: false,
        xAxis: XAxisConfig(label: 'Time'),
        facet: facet,
      );
      final cleared = faceted.facetCleared();
      expect(cleared.facet, isNull);
      expect(cleared.marks, faceted.marks);
      expect(cleared.xAxis, faceted.xAxis);
      expect(cleared, const PlotSpec<Sample>(
        data: <Sample>[],
        marks: <Mark<Sample>>[_line],
        xAxis: XAxisConfig(label: 'Time'),
      ));
    });
  });
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/unit/grammar/plot_spec_test.dart`
Expected: FAIL — `PlotSpec` has no named parameter `facet` / no method `facetCleared`.

- [ ] **Step 3: Write minimal implementation**

In `lib/src/grammar/plot_spec.dart`:

Add the import at the top (after `import 'mark.dart';`):

```dart
import 'facet_spec.dart';
```

Add the constructor parameter — change the constructor to include `this.facet` (place it last):

```dart
  const PlotSpec({
    required this.data,
    required this.marks,
    this.transposed = false,
    this.theme,
    this.interaction,
    this.xAxis,
    this.yAxes = const <YAxisConfig>[],
    this.grid,
    this.title,
    this.subtitle,
    this.showLegend,
    this.facet,
  });
```

Add the field (after the `showLegend` field, before `operator ==`):

```dart
  /// Optional faceting configuration.
  ///
  /// Null is a single-panel chart — the default, behaving exactly as before.
  /// A non-null value makes this spec a small-multiples grid; it is rendered
  /// with `BravenFacetPlot` (or `BravenChart.buildFaceted()`), and
  /// `PlotSpec.lower()` / `BravenChart.build()` reject it.
  final FacetSpec<T>? facet;

  /// A copy of this spec with [facet] cleared and everything else identical.
  ///
  /// `BravenFacetPlot` lowers each panel from a facet-cleared copy, so the
  /// per-panel lowering is exactly the single-panel lowering of the same marks.
  PlotSpec<T> facetCleared() => PlotSpec<T>(
    data: data,
    marks: marks,
    transposed: transposed,
    theme: theme,
    interaction: interaction,
    xAxis: xAxis,
    yAxes: yAxes,
    grid: grid,
    title: title,
    subtitle: subtitle,
    showLegend: showLegend,
  );
```

Extend `operator ==` — add `&& other.facet == facet` at the end of the boolean chain (after `other.showLegend == showLegend`):

```dart
          other.showLegend == showLegend &&
          other.facet == facet;
```

Extend `hashCode` — add `facet` as the final argument to `Object.hash(...)`:

```dart
  int get hashCode => Object.hash(
    Object.hashAll(data),
    Object.hashAll(marks),
    transposed,
    theme,
    interaction,
    xAxis,
    Object.hashAll(yAxes),
    grid,
    title,
    subtitle,
    showLegend,
    facet,
  );
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/unit/grammar/plot_spec_test.dart`
Expected: PASS — `All tests passed!`

- [ ] **Step 5: Run the grammar suite to prove nothing else drifted**

Run: `flutter test test/unit/grammar`
Expected: PASS — `All tests passed!` (existing parity/builder tests still green; `facet` defaults null everywhere).

- [ ] **Step 6: Analyze + commit**

```bash
flutter analyze lib
git add lib/src/grammar/plot_spec.dart test/unit/grammar/plot_spec_test.dart
git commit -m "feat(grammar): add optional PlotSpec.facet field and facetCleared()"
```
Expected analyze: `No issues found!`

---

### Task 3: `.facet(...)` verb on `BravenChart<T>`

**Files:**
- Modify: `lib/src/grammar/chart_builder.dart`
- Test: `test/unit/grammar/chart_builder_test.dart` (add a `group`)

**Interfaces:**
- Consumes: `FacetSpec<T>`, `FacetScales` (Task 1); `PlotSpec.facet` (Task 2).
- Produces: `BravenChart<T> facet(FieldAccessor<T, Object?> by, {int? columns, FacetScales scales = FacetScales.fixed, String? label})` — returns a new builder whose `toSpec().facet` is the `FacetSpec<T>` it built. (`.build()` guard + `.buildFaceted()` come in Task 7.)

- [ ] **Step 1: Write the failing test**

Append this `group` inside `main()` in `test/unit/grammar/chart_builder_test.dart` (the file's `rows`/`sampleMinute`-style tear-offs exist; use `sampleZone`, which returns `Object`, assignable to `FieldAccessor<Sample, Object?>`):

```dart
  group('.facet sets PlotSpec.facet', () {
    test('facet with defaults lands on the spec', () {
      final spec = BravenChart.of(rows)
          .x(sampleTime)
          .y(samplePower)
          .geomLine()
          .facet(sampleZone)
          .toSpec();

      expect(spec.facet, const FacetSpec<Sample>(by: sampleZone));
      expect(spec.facet!.scales, FacetScales.fixed);
    });

    test('facet carries columns, scales and label', () {
      final spec = BravenChart.of(rows)
          .x(sampleTime)
          .y(samplePower)
          .geomLine()
          .facet(sampleZone, columns: 3, scales: FacetScales.freeY, label: 'Zone')
          .toSpec();

      expect(
        spec.facet,
        const FacetSpec<Sample>(
          by: sampleZone,
          columns: 3,
          scales: FacetScales.freeY,
          label: 'Zone',
        ),
      );
    });

    test('a chain without .facet leaves the spec unfaceted', () {
      final spec = BravenChart.of(rows)
          .x(sampleTime)
          .y(samplePower)
          .geomLine()
          .toSpec();
      expect(spec.facet, isNull);
    });
  });
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/unit/grammar/chart_builder_test.dart`
Expected: FAIL — `BravenChart` has no method `facet`.

- [ ] **Step 3: Write minimal implementation**

In `lib/src/grammar/chart_builder.dart`:

Add the import (after `import 'channel.dart';`):

```dart
import 'facet_spec.dart';
```

Add `FacetSpec<T>? facet` to the private constructor `BravenChart._`, its field, and `_copy`. Concretely:

In the constructor parameter list (add before the closing `}) : `):

```dart
    FacetSpec<T>? facet,
```

In the initializer list (add `_facet = facet;` — change the current final initializer `_showLegend = showLegend;` to keep the semicolon on the new last one):

```dart
       _showLegend = showLegend,
       _facet = facet;
```

Add the field (after `final bool? _showLegend;`):

```dart
  final FacetSpec<T>? _facet;
```

In `_copy`, add the parameter (before the closing `}) => `):

```dart
    FacetSpec<T>? facet,
```

and pass it through in the `BravenChart<T>._(...)` call (after `showLegend: showLegend ?? _showLegend,`):

```dart
    facet: facet ?? _facet,
```

Add the verb (place it after the `legend` verb, before `toSpec`):

```dart
  /// Renders this chain as N synchronized small-multiple panels — one per
  /// distinct value of [by], in first-seen (data) order.
  ///
  /// [columns] fixes the grid width (null lays it out at `ceil(sqrt(N))`);
  /// [scales] controls axis sharing across panels ([FacetScales.fixed] shares
  /// both); [label] prefixes each panel's strip label. Faceting is set as an
  /// optional field on the [PlotSpec], so the spec stays the single complete
  /// description. Terminate the chain with [buildFaceted]; a faceted chain
  /// rejects the single-panel [build].
  BravenChart<T> facet(
    FieldAccessor<T, Object?> by, {
    int? columns,
    FacetScales scales = FacetScales.fixed,
    String? label,
  }) => _copy(
    facet: FacetSpec<T>(
      by: by,
      columns: columns,
      scales: scales,
      label: label,
    ),
  );
```

Pass `facet: _facet` through `toSpec()` — add it as the final argument of the `PlotSpec<T>(...)` returned by `toSpec` (after `showLegend: _showLegend,`):

```dart
      showLegend: _showLegend,
      facet: _facet,
    );
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/unit/grammar/chart_builder_test.dart`
Expected: PASS — `All tests passed!`

- [ ] **Step 5: Analyze + commit**

```bash
flutter analyze lib
git add lib/src/grammar/chart_builder.dart test/unit/grammar/chart_builder_test.dart
git commit -m "feat(grammar): add .facet() verb to BravenChart builder"
```
Expected analyze: `No issues found!`

---

### Task 4: facet diagnostics + `lower()` rejects a faceted spec

**Files:**
- Modify: `lib/src/grammar/grammar_diagnostics.dart`
- Modify: `lib/src/grammar/plot_lowering.dart`
- Test: `test/unit/grammar/plot_lowering_parity_test.dart` (add a `group`)

**Interfaces:**
- Consumes: `PlotSpec.facet` (Task 2); `FacetSpec` (Task 1).
- Produces (on `GrammarDiagnosticCode` + `GrammarSpecException`):
  - `GrammarDiagnosticCode.facetedSpecNotLowerable` + `GrammarSpecException.facetedSpecNotLowerable()` — a faceted spec handed to a single-panel path (`PlotSpec.lower()` / `BravenChart.build()`).
  - `GrammarDiagnosticCode.notFaceted` + `GrammarSpecException.notFaceted()` — `buildFaceted()` on a non-faceted spec (used in Task 7).
  - `GrammarDiagnosticCode.emptyFacetValues` + `GrammarSpecException.emptyFacetValues()` — partition produced zero panels (used in Task 6).
  - `GrammarDiagnosticCode.facetPanelCapExceeded` + `GrammarSpecException.facetPanelCapExceeded(int count, int cap)` — more than 50 panels (used in Task 6).
  - `PlotSpec.lower()` throws `facetedSpecNotLowerable` FIRST when `spec.facet != null`.

- [ ] **Step 1: Write the failing test**

Append this `group` inside `main()` in `test/unit/grammar/plot_lowering_parity_test.dart` (its `rows`, `sampleTime`, `samplePower`, `sampleZone` and `throwsGrammarCode` helper already exist):

```dart
  group('faceting rejects the single-panel lowering', () {
    test('lower() on a faceted spec throws facetedSpecNotLowerable', () {
      expect(
        () => (const PlotSpec<Sample>(
          data: rows,
          marks: <Mark<Sample>>[LineMark<Sample>(x: sampleTime, y: samplePower)],
          facet: FacetSpec<Sample>(by: sampleZone),
        )).lower(),
        throwsGrammarCode(GrammarDiagnosticCode.facetedSpecNotLowerable),
      );
    });

    test('the facet rejection beats every other diagnostic', () {
      // A faceted spec that is ALSO otherwise broken (no marks) still reports
      // the facet-path error first — the caller reached for the wrong terminal.
      expect(
        () => (const PlotSpec<Sample>(
          data: rows,
          marks: <Mark<Sample>>[],
          facet: FacetSpec<Sample>(by: sampleZone),
        )).lower(),
        throwsGrammarCode(GrammarDiagnosticCode.facetedSpecNotLowerable),
      );
    });

    test('the new diagnostics name their codes in toString', () {
      expect(
        GrammarSpecException.notFaceted().code,
        GrammarDiagnosticCode.notFaceted,
      );
      expect(
        GrammarSpecException.emptyFacetValues().code,
        GrammarDiagnosticCode.emptyFacetValues,
      );
      final capped = GrammarSpecException.facetPanelCapExceeded(64, 50);
      expect(capped.code, GrammarDiagnosticCode.facetPanelCapExceeded);
      expect(capped.message, contains('64'));
      expect(capped.message, contains('50'));
    });
  });
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/unit/grammar/plot_lowering_parity_test.dart`
Expected: FAIL — `GrammarDiagnosticCode.facetedSpecNotLowerable` and the factories are undefined.

- [ ] **Step 3: Add the diagnostic codes and factories**

In `lib/src/grammar/grammar_diagnostics.dart`:

Add four enum values to `GrammarDiagnosticCode` (after `missingEncoding,`, before the closing `}`):

```dart
  /// A faceted spec was handed to a single-panel path (`PlotSpec.lower()` /
  /// `BravenChart.build()`). Render it with `BravenChart.buildFaceted()`.
  facetedSpecNotLowerable,

  /// `buildFaceted()` was called on a spec that declared no `.facet(...)`.
  notFaceted,

  /// Faceting found no rows to partition, so there is no panel to draw.
  emptyFacetValues,

  /// Faceting produced more than the panel cap allows.
  facetPanelCapExceeded,
```

Add the factory constructors to `GrammarSpecException` (after the `missingEncoding` factory, before `/// The machine-readable diagnostic.`):

```dart
  /// A faceted spec reached a single-panel path.
  factory GrammarSpecException.facetedSpecNotLowerable() =>
      const GrammarSpecException(
        GrammarDiagnosticCode.facetedSpecNotLowerable,
        'This PlotSpec is faceted. A single-panel lowering (PlotSpec.lower / '
        'BravenChart.build) renders exactly one panel, but a faceted spec is N '
        'panels. Render it with BravenChart.buildFaceted() or BravenFacetPlot.',
      );

  /// `buildFaceted()` was called on a non-faceted spec.
  factory GrammarSpecException.notFaceted() => const GrammarSpecException(
    GrammarDiagnosticCode.notFaceted,
    'buildFaceted() needs a faceted spec, but this chain called no '
    '.facet(...). Add .facet(by: ...), or render it with .build().',
  );

  /// Faceting partitioned zero rows into zero panels.
  factory GrammarSpecException.emptyFacetValues() => const GrammarSpecException(
    GrammarDiagnosticCode.emptyFacetValues,
    'Faceting found no rows to partition, so there is no panel to draw. Pass '
    'the rows the facet accessor reads to PlotSpec.data.',
  );

  /// Faceting produced more panels than the cap allows.
  factory GrammarSpecException.facetPanelCapExceeded(int count, int cap) =>
      GrammarSpecException(
        GrammarDiagnosticCode.facetPanelCapExceeded,
        'Faceting produced $count panels, over the cap of $cap. A grid this '
        'large is a chart-authoring error, not a render — facet by a coarser '
        'field or pre-aggregate the rows.',
      );
```

- [ ] **Step 4: Make `lower()` reject a faceted spec**

In `lib/src/grammar/plot_lowering.dart`, add the guard as the FIRST line of `_lower<T>` (before `if (spec.marks.isEmpty) throw GrammarSpecException.emptyMarks();`):

```dart
LoweredPlot _lower<T>(PlotSpec<T> spec) {
  if (spec.facet != null) throw GrammarSpecException.facetedSpecNotLowerable();
  if (spec.marks.isEmpty) throw GrammarSpecException.emptyMarks();
```

- [ ] **Step 5: Run test to verify it passes**

Run: `flutter test test/unit/grammar/plot_lowering_parity_test.dart`
Expected: PASS — `All tests passed!`

- [ ] **Step 6: Analyze + commit**

```bash
flutter analyze lib
git add lib/src/grammar/grammar_diagnostics.dart lib/src/grammar/plot_lowering.dart test/unit/grammar/plot_lowering_parity_test.dart
git commit -m "feat(grammar): facet diagnostics and lower() single-panel guard"
```
Expected analyze: `No issues found!`

---

### Task 5: `facet_partition.dart` pure helpers

**Files:**
- Create: `lib/src/grammar/facet_partition.dart`
- Test: `test/unit/grammar/facet_partition_test.dart`

**Interfaces:**
- Consumes: `FieldAccessor` (channel.dart); `PlotSpec`, and the sealed `Mark` variants (`LineMark`/`AreaMark`/`BarMark`/`ScatterMark`/`CandlestickMark`/`TrendMark`/`ThresholdMark`/`BandMark`/`PointMark`) from `mark.dart`.
- Produces (top-level, internal — NOT barrel-exported; tests import the `src/` path):
  - `List<Object?> distinctFacetValues<T>(List<T> rows, FieldAccessor<T, Object?> by)` — first-seen order, includes null once.
  - `enum FacetAxis { x, y }`
  - `class FacetRange { const FacetRange(this.min, this.max); final double min; final double max; }`
  - `FacetRange? globalRange<T>(PlotSpec<T> spec, List<T> rows, FacetAxis axis)` — min/max over all geometry marks' x (or y) accessors, skipping non-finite; null when nothing finite.
  - `int autoColumns(int panelCount)` — `panelCount <= 1 ? 1 : ceil(sqrt(panelCount))`.

- [ ] **Step 1: Write the failing test**

Create `test/unit/grammar/facet_partition_test.dart`:

```dart
// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

/// Pure partition/range/layout helpers behind faceting.
///
/// These are the only genuinely new computations faceting adds; everything
/// downstream is unchanged `PlotSpec.lower()`. They are tested in isolation,
/// out of the widget.
library;

import 'package:braven_charts/braven_charts.dart';
import 'package:braven_charts/src/grammar/facet_partition.dart';
import 'package:flutter_test/flutter_test.dart';

class Sample {
  const Sample({
    required this.time,
    required this.power,
    required this.zone,
    this.open = 0,
    this.high = 0,
    this.low = 0,
    this.close = 0,
  });
  final double time;
  final double power;
  final Object? zone;
  final double open;
  final double high;
  final double low;
  final double close;
}

double sampleTime(Sample row) => row.time;
double samplePower(Sample row) => row.power;
Object? sampleZone(Sample row) => row.zone;
double sampleOpen(Sample row) => row.open;
double sampleHigh(Sample row) => row.high;
double sampleLow(Sample row) => row.low;
double sampleClose(Sample row) => row.close;

const rows = <Sample>[
  Sample(time: 0, power: 180, zone: 'easy'),
  Sample(time: 1, power: 260, zone: 'hard'),
  Sample(time: 2, power: 220, zone: 'easy'),
  Sample(time: 3, power: 300, zone: null),
];

void main() {
  group('distinctFacetValues', () {
    test('returns first-seen order and dedups, including a null value', () {
      expect(distinctFacetValues(rows, sampleZone), <Object?>['easy', 'hard', null]);
    });

    test('an empty row list yields no values', () {
      expect(distinctFacetValues(const <Sample>[], sampleZone), isEmpty);
    });
  });

  group('globalRange', () {
    test('spans the min/max of the y accessor across ALL rows', () {
      const spec = PlotSpec<Sample>(
        data: rows,
        marks: <Mark<Sample>>[LineMark<Sample>(x: sampleTime, y: samplePower)],
      );
      final range = globalRange(spec, rows, FacetAxis.y);
      expect(range, isNotNull);
      expect(range!.min, 180);
      expect(range.max, 300);
    });

    test('spans the min/max of the x accessor', () {
      const spec = PlotSpec<Sample>(
        data: rows,
        marks: <Mark<Sample>>[LineMark<Sample>(x: sampleTime, y: samplePower)],
      );
      final range = globalRange(spec, rows, FacetAxis.x)!;
      expect(range.min, 0);
      expect(range.max, 3);
    });

    test('candlestick y-range spans low..high across rows', () {
      const candles = <Sample>[
        Sample(time: 0, power: 0, zone: 'a', open: 10, high: 14, low: 9, close: 12),
        Sample(time: 1, power: 0, zone: 'a', open: 12, high: 18, low: 8, close: 15),
      ];
      const spec = PlotSpec<Sample>(
        data: candles,
        marks: <Mark<Sample>>[
          CandlestickMark<Sample>(
            x: sampleTime,
            open: sampleOpen,
            high: sampleHigh,
            low: sampleLow,
            close: sampleClose,
          ),
        ],
      );
      final range = globalRange(spec, candles, FacetAxis.y)!;
      expect(range.min, 8);
      expect(range.max, 18);
    });

    test('reference-only marks contribute no range (null)', () {
      const spec = PlotSpec<Sample>(
        data: rows,
        marks: <Mark<Sample>>[ThresholdMark<Sample>(value: 250)],
      );
      expect(globalRange(spec, rows, FacetAxis.y), isNull);
    });

    test('non-finite values are skipped', () {
      const gapped = <Sample>[
        Sample(time: 0, power: 180, zone: 'a'),
        Sample(time: 1, power: double.nan, zone: 'a'),
        Sample(time: 2, power: 260, zone: 'a'),
      ];
      const spec = PlotSpec<Sample>(
        data: gapped,
        marks: <Mark<Sample>>[LineMark<Sample>(x: sampleTime, y: samplePower)],
      );
      final range = globalRange(spec, gapped, FacetAxis.y)!;
      expect(range.min, 180);
      expect(range.max, 260);
    });
  });

  group('autoColumns', () {
    test('is ceil(sqrt(n)), and never less than one', () {
      expect(autoColumns(1), 1);
      expect(autoColumns(2), 2);
      expect(autoColumns(3), 2);
      expect(autoColumns(4), 2);
      expect(autoColumns(5), 3);
      expect(autoColumns(9), 3);
      expect(autoColumns(10), 4);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/unit/grammar/facet_partition_test.dart`
Expected: FAIL — `facet_partition.dart` does not exist / symbols undefined.

- [ ] **Step 3: Write minimal implementation**

Create `lib/src/grammar/facet_partition.dart`:

```dart
// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

import 'dart:math' as math;

import 'channel.dart' show FieldAccessor;
import 'mark.dart';
import 'plot_spec.dart';

/// Distinct facet values from [rows] via [by], in FIRST-SEEN (data) order.
///
/// A null value is a valid distinct value and appears once, in the position it
/// was first seen. Deduplication is by `==` (works for String/enum/num/bool).
List<Object?> distinctFacetValues<T>(
  List<T> rows,
  FieldAccessor<T, Object?> by,
) {
  final seen = <Object?>{};
  final ordered = <Object?>[];
  for (final row in rows) {
    final value = by(row);
    if (seen.add(value)) ordered.add(value);
  }
  return ordered;
}

/// Which Cartesian axis a [globalRange] spans.
enum FacetAxis { x, y }

/// A finite `[min, max]` extent computed across the full dataset.
class FacetRange {
  /// Creates a range.
  const FacetRange(this.min, this.max);

  /// Lower bound.
  final double min;

  /// Upper bound.
  final double max;

  @override
  String toString() => 'FacetRange($min, $max)';
}

/// The global min/max of [spec]'s geometry marks along [axis] over [rows].
///
/// Reuses the marks' own position accessors: the [FacetAxis.x] range is the
/// extent of every geometry's `x`; the [FacetAxis.y] range is the extent of
/// every geometry's `y` (a candlestick contributes `open`/`high`/`low`/`close`,
/// so the shared price axis spans the wicks). Reference/derived marks
/// (threshold, band, point, trend) contribute nothing. Non-finite accessor
/// output is skipped, exactly as the point families carry it through. Returns
/// null when nothing finite was found.
FacetRange? globalRange<T>(PlotSpec<T> spec, List<T> rows, FacetAxis axis) {
  double? lo;
  double? hi;
  for (final mark in spec.marks) {
    for (final accessor in _axisAccessors(mark, axis)) {
      for (final row in rows) {
        final value = accessor(row).toDouble();
        if (!value.isFinite) continue;
        if (lo == null || value < lo) lo = value;
        if (hi == null || value > hi) hi = value;
      }
    }
  }
  if (lo == null || hi == null) return null;
  return FacetRange(lo, hi);
}

/// The position accessors of [mark] that contribute to [axis].
List<FieldAccessor<T, num>> _axisAccessors<T>(Mark<T> mark, FacetAxis axis) =>
    switch (mark) {
      LineMark<T>(:final x, :final y) => <FieldAccessor<T, num>>[
        axis == FacetAxis.x ? x : y,
      ],
      AreaMark<T>(:final x, :final y) => <FieldAccessor<T, num>>[
        axis == FacetAxis.x ? x : y,
      ],
      BarMark<T>(:final x, :final y) => <FieldAccessor<T, num>>[
        axis == FacetAxis.x ? x : y,
      ],
      ScatterMark<T>(:final x, :final y) => <FieldAccessor<T, num>>[
        axis == FacetAxis.x ? x : y,
      ],
      CandlestickMark<T>(
        :final x,
        :final open,
        :final high,
        :final low,
        :final close,
      ) =>
        axis == FacetAxis.x
            ? <FieldAccessor<T, num>>[x]
            : <FieldAccessor<T, num>>[open, high, low, close],
      TrendMark<T>() ||
      ThresholdMark<T>() ||
      BandMark<T>() ||
      PointMark<T>() => const <Never>[],
    };

/// The auto grid width for [panelCount] panels: `ceil(sqrt(n))`, min 1.
int autoColumns(int panelCount) =>
    panelCount <= 1 ? 1 : math.sqrt(panelCount).ceil();
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/unit/grammar/facet_partition_test.dart`
Expected: PASS — `All tests passed!`

- [ ] **Step 5: Analyze + commit**

```bash
flutter analyze lib
git add lib/src/grammar/facet_partition.dart test/unit/grammar/facet_partition_test.dart
git commit -m "feat(grammar): pure facet partition, global-range and grid helpers"
```
Expected analyze: `No issues found!`

---

### Task 6: `BravenFacetPlot<T>` widget

**Files:**
- Create: `lib/src/grammar/braven_facet_plot.dart`
- Modify: `lib/braven_charts.dart` (Grammar export block)
- Test: `test/unit/grammar/facet_resolution_test.dart` (pure `resolveFacetPanels`)
- Test: `test/widgets/braven_facet_plot_test.dart` (widget renders N panels + strips + columns)

**Interfaces:**
- Consumes: `PlotSpec`, `PlotSpec.facetCleared()` (Task 2); `FacetSpec`, `FacetScalesSharing` (Task 1); `distinctFacetValues`, `globalRange`, `FacetAxis`, `FacetRange`, `autoColumns` (Task 5); `GrammarSpecException.emptyMarks/emptyFacetValues/facetPanelCapExceeded/notFaceted` (Task 4); `BravenPlot<T>` (`braven_plot.dart`); `ChartInteractionGroupController` (`../controllers/chart_interaction_group_controller.dart`); `ChartEmptyStateConfig` (`../models/chart_state_config.dart`); `ChartTheme` + `TypographyTheme` fields (`../models/chart_theme.dart`); `XAxisConfig`/`YAxisConfig`/`YAxisPosition`.
- Produces:
  - `const int facetPanelCap = 50;`
  - `class BravenFacetPanel<T> { const BravenFacetPanel({required Object? value, required String label, required PlotSpec<T> spec}); final Object? value; final String label; final PlotSpec<T> spec; }` — `spec` is facet-cleared and range-injected; NO copyWith.
  - `List<BravenFacetPanel<T>> resolveFacetPanels<T>(PlotSpec<T> spec)` — validates (`emptyMarks`, `notFaceted`, `emptyFacetValues`, `facetPanelCapExceeded`) then returns one panel per distinct value with subset data + injected ranges.
  - `class BravenFacetPlot<T> extends StatefulWidget { const BravenFacetPlot(PlotSpec<T> spec, {Key? key, ChartEmptyStateConfig emptyStateConfig}); final PlotSpec<T> spec; final ChartEmptyStateConfig emptyStateConfig; }` — the State owns the shared `ChartInteractionGroupController` (created only when `scales.syncsInteraction`).

> **Deviation (report to orchestrator):** the spec calls `BravenFacetPlot` a *StatelessWidget*. A shared `ChartInteractionGroupController` must be created once and DISPOSED; a stateless widget cannot own that lifecycle without leaking. `BravenFacetPlot` is therefore a **StatefulWidget** whose `State` creates the controller in `initState` and disposes it in `dispose`. Everything else matches the spec.

- [ ] **Step 1: Write the failing pure-resolution test**

Create `test/unit/grammar/facet_resolution_test.dart`:

```dart
// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

/// `resolveFacetPanels` composition: partition → subset → injected ranges.
library;

import 'package:braven_charts/braven_charts.dart';
import 'package:braven_charts/src/grammar/braven_facet_plot.dart';
import 'package:flutter_test/flutter_test.dart';

class Sample {
  const Sample({required this.time, required this.power, required this.zone});
  final double time;
  final double power;
  final Object? zone;
}

double sampleTime(Sample row) => row.time;
double samplePower(Sample row) => row.power;
Object? sampleZone(Sample row) => row.zone;

const rows = <Sample>[
  Sample(time: 0, power: 180, zone: 'easy'),
  Sample(time: 1, power: 260, zone: 'hard'),
  Sample(time: 2, power: 220, zone: 'easy'),
];

Matcher throwsGrammarCode(GrammarDiagnosticCode code) =>
    throwsA(isA<GrammarSpecException>().having((e) => e.code, 'code', code));

void main() {
  test('one panel per distinct value in first-seen order, with subset data', () {
    const spec = PlotSpec<Sample>(
      data: rows,
      marks: <Mark<Sample>>[LineMark<Sample>(x: sampleTime, y: samplePower)],
      facet: FacetSpec<Sample>(by: sampleZone),
    );
    final panels = resolveFacetPanels(spec);
    expect(panels.map((p) => p.value), <Object?>['easy', 'hard']);
    expect(panels.first.spec.data, <Sample>[rows[0], rows[2]]);
    expect(panels.last.spec.data, <Sample>[rows[1]]);
    // Each panel spec is facet-cleared so BravenPlot can lower it.
    expect(panels.every((p) => p.spec.facet == null), isTrue);
  });

  test('fixed scales inject the same global x and y range into every panel', () {
    const spec = PlotSpec<Sample>(
      data: rows,
      marks: <Mark<Sample>>[LineMark<Sample>(x: sampleTime, y: samplePower)],
      facet: FacetSpec<Sample>(by: sampleZone),
    );
    for (final panel in resolveFacetPanels(spec)) {
      expect(panel.spec.xAxis?.min, 0);
      expect(panel.spec.xAxis?.max, 2);
      expect(panel.spec.yAxes.single.min, 180);
      expect(panel.spec.yAxes.single.max, 260);
    }
  });

  test('freeY leaves y unbounded and keeps x shared', () {
    const spec = PlotSpec<Sample>(
      data: rows,
      marks: <Mark<Sample>>[LineMark<Sample>(x: sampleTime, y: samplePower)],
      facet: FacetSpec<Sample>(by: sampleZone, scales: FacetScales.freeY),
    );
    final panel = resolveFacetPanels(spec).first;
    expect(panel.spec.xAxis?.min, 0);
    expect(panel.spec.yAxes, isEmpty);
  });

  test('free leaves both axes to auto-scale each subset', () {
    const spec = PlotSpec<Sample>(
      data: rows,
      marks: <Mark<Sample>>[LineMark<Sample>(x: sampleTime, y: samplePower)],
      facet: FacetSpec<Sample>(by: sampleZone, scales: FacetScales.free),
    );
    final panel = resolveFacetPanels(spec).first;
    expect(panel.spec.xAxis, isNull);
    expect(panel.spec.yAxes, isEmpty);
  });

  test('the label prefixes the strip when provided', () {
    const spec = PlotSpec<Sample>(
      data: rows,
      marks: <Mark<Sample>>[LineMark<Sample>(x: sampleTime, y: samplePower)],
      facet: FacetSpec<Sample>(by: sampleZone, label: 'Zone'),
    );
    expect(resolveFacetPanels(spec).map((p) => p.label),
        <String>['Zone: easy', 'Zone: hard']);
  });

  test('no facet, empty rows and the panel cap are diagnostics', () {
    expect(
      () => resolveFacetPanels(const PlotSpec<Sample>(
        data: rows,
        marks: <Mark<Sample>>[LineMark<Sample>(x: sampleTime, y: samplePower)],
      )),
      throwsGrammarCode(GrammarDiagnosticCode.notFaceted),
    );
    expect(
      () => resolveFacetPanels(const PlotSpec<Sample>(
        data: <Sample>[],
        marks: <Mark<Sample>>[LineMark<Sample>(x: sampleTime, y: samplePower)],
        facet: FacetSpec<Sample>(by: sampleZone),
      )),
      throwsGrammarCode(GrammarDiagnosticCode.emptyFacetValues),
    );
    final many = <Sample>[
      for (var i = 0; i < facetPanelCap + 1; i++)
        Sample(time: i.toDouble(), power: 1, zone: 'z$i'),
    ];
    expect(
      () => resolveFacetPanels(PlotSpec<Sample>(
        data: many,
        marks: const <Mark<Sample>>[
          LineMark<Sample>(x: sampleTime, y: samplePower),
        ],
        facet: const FacetSpec<Sample>(by: sampleZone),
      )),
      throwsGrammarCode(GrammarDiagnosticCode.facetPanelCapExceeded),
    );
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/unit/grammar/facet_resolution_test.dart`
Expected: FAIL — `braven_facet_plot.dart` does not exist / `resolveFacetPanels` undefined.

- [ ] **Step 3: Write the widget + resolution implementation**

Create `lib/src/grammar/braven_facet_plot.dart`:

```dart
// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

import 'package:flutter/widgets.dart';

import '../controllers/chart_interaction_group_controller.dart';
import '../models/chart_state_config.dart';
import '../models/chart_theme.dart';
import '../models/x_axis_config.dart';
import '../models/y_axis_config.dart';
import '../models/y_axis_position.dart';
import 'braven_plot.dart';
import 'facet_partition.dart';
import 'facet_spec.dart';
import 'grammar_diagnostics.dart';
import 'plot_spec.dart';

/// Default maximum number of facet panels. Exceeding it is a grammar
/// diagnostic, not a silent large render.
const int facetPanelCap = 50;

/// One resolved facet panel: a strip label over a facet-cleared, range-injected
/// [PlotSpec] ready to be lowered by a [BravenPlot].
class BravenFacetPanel<T> {
  /// Creates a resolved panel.
  const BravenFacetPanel({
    required this.value,
    required this.label,
    required this.spec,
  });

  /// The distinct facet value this panel is for (may be null).
  final Object? value;

  /// The strip label shown above the panel.
  final String label;

  /// The single-panel spec (facet cleared, ranges injected, subset data).
  final PlotSpec<T> spec;
}

/// Partitions [spec] into one [BravenFacetPanel] per distinct facet value.
///
/// Validates the faceting up front: [GrammarDiagnosticCode.notFaceted] when the
/// spec is not faceted, [GrammarDiagnosticCode.emptyMarks] when it has no marks,
/// [GrammarDiagnosticCode.emptyFacetValues] when the partition is empty, and
/// [GrammarDiagnosticCode.facetPanelCapExceeded] over [facetPanelCap]. Then, for
/// each value (first-seen order), builds a facet-cleared copy over the row
/// subset with the shared axis ranges injected per [FacetScales].
List<BravenFacetPanel<T>> resolveFacetPanels<T>(PlotSpec<T> spec) {
  final facet = spec.facet;
  if (facet == null) throw GrammarSpecException.notFaceted();
  if (spec.marks.isEmpty) throw GrammarSpecException.emptyMarks();

  final values = distinctFacetValues(spec.data, facet.by);
  if (values.isEmpty) throw GrammarSpecException.emptyFacetValues();
  if (values.length > facetPanelCap) {
    throw GrammarSpecException.facetPanelCapExceeded(
      values.length,
      facetPanelCap,
    );
  }

  final xRange = facet.scales.sharesX
      ? globalRange(spec, spec.data, FacetAxis.x)
      : null;
  final yRange = facet.scales.sharesY
      ? globalRange(spec, spec.data, FacetAxis.y)
      : null;

  final base = spec.facetCleared();
  return <BravenFacetPanel<T>>[
    for (final value in values)
      BravenFacetPanel<T>(
        value: value,
        label: facet.label == null ? '$value' : '${facet.label}: $value',
        spec: _injectPanel<T>(
          base,
          <T>[for (final row in spec.data) if (facet.by(row) == value) row],
          xRange,
          yRange,
        ),
      ),
  ];
}

/// Builds one panel spec from [base]: subset [data] plus any shared axis range.
///
/// A range is injected only when it is a real interval (`min < max`); a
/// degenerate range (all-equal values) is left to auto-scale rather than trip
/// the axis config's `min < max` assert. For a shared Y axis with no declared
/// axes, a single default left axis carrying the range is synthesized (it
/// lowers to `axis-0` exactly as the empty-yAxes default does).
PlotSpec<T> _injectPanel<T>(
  PlotSpec<T> base,
  List<T> data,
  FacetRange? xRange,
  FacetRange? yRange,
) {
  final injectX = xRange != null && xRange.min < xRange.max;
  final injectY = yRange != null && yRange.min < yRange.max;
  final xAxis = injectX
      ? (base.xAxis ?? const XAxisConfig()).copyWith(
          min: xRange.min,
          max: xRange.max,
        )
      : base.xAxis;
  final yAxes = injectY
      ? (base.yAxes.isEmpty
            ? <YAxisConfig>[
                YAxisConfig(
                  position: YAxisPosition.left,
                  min: yRange.min,
                  max: yRange.max,
                ),
              ]
            : <YAxisConfig>[
                for (final axis in base.yAxes)
                  axis.copyWith(min: yRange.min, max: yRange.max),
              ])
      : base.yAxes;
  return PlotSpec<T>(
    data: data,
    marks: base.marks,
    transposed: base.transposed,
    theme: base.theme,
    interaction: base.interaction,
    xAxis: xAxis,
    yAxes: yAxes,
    grid: base.grid,
    title: base.title,
    subtitle: base.subtitle,
    showLegend: base.showLegend,
  );
}

/// Renders a faceted [PlotSpec] as a grid of synchronized small-multiple
/// panels — one [BravenPlot] per distinct facet value.
///
/// Each panel is a strip label (the facet value, prefixed by
/// [FacetSpec.label]) above a [BravenPlot] over the panel's facet-cleared,
/// range-injected spec. Synchronized interaction is active only when x is
/// shared ([FacetScales.fixed]/[FacetScales.freeY]): every panel is handed the
/// SAME [ChartInteractionGroupController]; under [FacetScales.freeX]/[free] the
/// panels get no shared controller and interact independently.
class BravenFacetPlot<T> extends StatefulWidget {
  /// Renders [spec], which must be faceted (`spec.facet != null`).
  const BravenFacetPlot(
    this.spec, {
    super.key,
    this.emptyStateConfig = const ChartEmptyStateConfig(),
  });

  /// The faceted specification this widget renders.
  final PlotSpec<T> spec;

  /// Presentation used when a panel's row subset is empty.
  final ChartEmptyStateConfig emptyStateConfig;

  @override
  State<BravenFacetPlot<T>> createState() => _BravenFacetPlotState<T>();
}

class _BravenFacetPlotState<T> extends State<BravenFacetPlot<T>> {
  ChartInteractionGroupController? _syncController;

  bool get _syncs => widget.spec.facet?.scales.syncsInteraction ?? false;

  @override
  void initState() {
    super.initState();
    if (_syncs) _syncController = ChartInteractionGroupController();
  }

  @override
  void didUpdateWidget(covariant BravenFacetPlot<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    final wantsSync = _syncs;
    final hasSync = _syncController != null;
    if (wantsSync && !hasSync) {
      _syncController = ChartInteractionGroupController();
    } else if (!wantsSync && hasSync) {
      _syncController!.dispose();
      _syncController = null;
    }
  }

  @override
  void dispose() {
    _syncController?.dispose();
    super.dispose();
  }

  TextStyle _stripStyle() {
    final typography = (widget.spec.theme ?? ChartTheme.light).typographyTheme;
    return TextStyle(
      fontFamily: typography.fontFamily,
      fontSize: typography.baseFontSize * typography.labelMultiplier,
      fontWeight: FontWeight.w600,
    );
  }

  Widget _panelCell(BravenFacetPanel<T> panel, TextStyle stripStyle) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: <Widget>[
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Text(
          panel.label,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: stripStyle,
        ),
      ),
      Expanded(
        child: BravenPlot<T>(
          panel.spec,
          interactionGroupController: _syncController,
          emptyStateConfig: widget.emptyStateConfig,
        ),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final panels = resolveFacetPanels<T>(widget.spec);
    final columns = widget.spec.facet!.columns ?? autoColumns(panels.length);
    final stripStyle = _stripStyle();

    final gridRows = <Widget>[];
    for (var start = 0; start < panels.length; start += columns) {
      final cells = <Widget>[
        for (var column = 0; column < columns; column++)
          Expanded(
            child: (start + column) < panels.length
                ? _panelCell(panels[start + column], stripStyle)
                : const SizedBox.shrink(),
          ),
      ];
      gridRows.add(
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: cells,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: gridRows,
    );
  }
}
```

- [ ] **Step 4: Run the resolution test to verify it passes**

Run: `flutter test test/unit/grammar/facet_resolution_test.dart`
Expected: PASS — `All tests passed!`

- [ ] **Step 5: Add the barrel export**

In `lib/braven_charts.dart`, in the `// Grammar` block, add:

```dart
export 'src/grammar/braven_facet_plot.dart';
```

- [ ] **Step 6: Write the failing widget test**

Create `test/widgets/braven_facet_plot_test.dart`:

```dart
// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

/// Widget-level behaviour of [BravenFacetPlot]: N panels, strips, columns.
///
/// The per-panel lowering is proven by the config-parity suite; this file
/// proves the grid mounts one BravenPlot per facet value with the right strips.
library;

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class Row {
  const Row({required this.t, required this.power, required this.zone});
  final double t;
  final double power;
  final Object? zone;
}

double rowT(Row row) => row.t;
double rowPower(Row row) => row.power;
Object? rowZone(Row row) => row.zone;

const rows = <Row>[
  Row(t: 0, power: 180, zone: 'easy'),
  Row(t: 1, power: 260, zone: 'hard'),
  Row(t: 2, power: 220, zone: 'easy'),
  Row(t: 3, power: 300, zone: 'max'),
];

Widget host(Widget child) => MaterialApp(
  home: Scaffold(
    body: Center(child: SizedBox(width: 800, height: 600, child: child)),
  ),
);

void main() {
  testWidgets('renders one BravenPlot per distinct facet value', (tester) async {
    await tester.pumpWidget(
      host(
        const BravenFacetPlot<Row>(
          PlotSpec<Row>(
            data: rows,
            marks: <Mark<Row>>[LineMark<Row>(x: rowT, y: rowPower)],
            facet: FacetSpec<Row>(by: rowZone),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(BravenPlot<Row>), findsNWidgets(3));
  });

  testWidgets('strip labels are the facet values, prefixed by label', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        const BravenFacetPlot<Row>(
          PlotSpec<Row>(
            data: rows,
            marks: <Mark<Row>>[LineMark<Row>(x: rowT, y: rowPower)],
            facet: FacetSpec<Row>(by: rowZone, label: 'Zone'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Zone: easy'), findsOneWidget);
    expect(find.text('Zone: hard'), findsOneWidget);
    expect(find.text('Zone: max'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('an explicit columns override is respected', (tester) async {
    await tester.pumpWidget(
      host(
        const BravenFacetPlot<Row>(
          PlotSpec<Row>(
            data: rows,
            marks: <Mark<Row>>[LineMark<Row>(x: rowT, y: rowPower)],
            facet: FacetSpec<Row>(by: rowZone, columns: 3),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 3 panels, 3 columns → a single grid row of 3 panels.
    expect(find.byType(BravenPlot<Row>), findsNWidgets(3));
    expect(tester.takeException(), isNull);
  });

  testWidgets('the panel cap surfaces as a diagnostic from build', (
    tester,
  ) async {
    final many = <Row>[
      for (var i = 0; i < 51; i++) Row(t: i.toDouble(), power: 1, zone: 'z$i'),
    ];
    await tester.pumpWidget(
      host(
        BravenFacetPlot<Row>(
          PlotSpec<Row>(
            data: many,
            marks: const <Mark<Row>>[LineMark<Row>(x: rowT, y: rowPower)],
            facet: const FacetSpec<Row>(by: rowZone),
          ),
        ),
      ),
    );

    expect(
      tester.takeException(),
      isA<GrammarSpecException>().having(
        (e) => e.code,
        'code',
        GrammarDiagnosticCode.facetPanelCapExceeded,
      ),
    );
  });
}
```

- [ ] **Step 7: Run the widget test to verify it passes**

Run: `flutter test test/widgets/braven_facet_plot_test.dart`
Expected: PASS — `All tests passed!`

- [ ] **Step 8: Analyze + commit**

```bash
flutter analyze lib
git add lib/src/grammar/braven_facet_plot.dart lib/braven_charts.dart test/unit/grammar/facet_resolution_test.dart test/widgets/braven_facet_plot_test.dart
git commit -m "feat(grammar): BravenFacetPlot grid widget and panel resolution"
```
Expected analyze: `No issues found!`

---

### Task 7: `.build()` guard + `.buildFaceted()` terminal

**Files:**
- Modify: `lib/src/grammar/chart_builder.dart`
- Test: `test/unit/grammar/chart_builder_test.dart` (add a `group`)

**Interfaces:**
- Consumes: `BravenFacetPlot<T>` (Task 6); `GrammarSpecException.facetedSpecNotLowerable/notFaceted` (Task 4); `ChartEmptyStateConfig`.
- Produces:
  - `BravenChart<T>.build(...)` now throws `facetedSpecNotLowerable` when `toSpec().facet != null` (before constructing the `BravenPlot`).
  - `BravenFacetPlot<T> buildFaceted({Key? key, ChartEmptyStateConfig emptyStateConfig = const ChartEmptyStateConfig()})` — throws `notFaceted` when `toSpec().facet == null`.

> **Deviation (report to orchestrator):** the spec's API sketch says `buildFaceted` takes "the same host-facing params `build()` exposes" (which include `bravenChartController` and `interactionGroupController`). A facet grid is N charts, so a single per-chart `BravenChartController` and a host interaction group do NOT apply in v1 (artifact capture of a grid is explicitly out of scope; the grid owns its OWN sync controller). `buildFaceted` therefore exposes only `key` + `emptyStateConfig`.

- [ ] **Step 1: Write the failing test**

Append this `group` inside `main()` in `test/unit/grammar/chart_builder_test.dart`:

```dart
  group('faceted terminals', () {
    Matcher throwsCode(GrammarDiagnosticCode code) =>
        throwsA(isA<GrammarSpecException>().having((e) => e.code, 'code', code));

    test('.build() on a faceted chain throws, directing to buildFaceted', () {
      expect(
        () => BravenChart.of(rows)
            .x(sampleTime)
            .y(samplePower)
            .geomLine()
            .facet(sampleZone)
            .build(),
        throwsCode(GrammarDiagnosticCode.facetedSpecNotLowerable),
      );
    });

    test('.buildFaceted() on a non-faceted chain throws', () {
      expect(
        () => BravenChart.of(rows)
            .x(sampleTime)
            .y(samplePower)
            .geomLine()
            .buildFaceted(),
        throwsCode(GrammarDiagnosticCode.notFaceted),
      );
    });

    test('.buildFaceted() returns a BravenFacetPlot over the faceted spec', () {
      final widget = BravenChart.of(rows)
          .x(sampleTime)
          .y(samplePower)
          .geomLine()
          .facet(sampleZone, columns: 2, label: 'Zone')
          .buildFaceted();
      expect(widget, isA<BravenFacetPlot<Sample>>());
      expect(widget.spec.facet, isNotNull);
      expect(widget.spec.facet!.columns, 2);
    });

    test('.build() on a non-faceted chain still returns a BravenPlot', () {
      final widget = BravenChart.of(rows)
          .x(sampleTime)
          .y(samplePower)
          .geomLine()
          .build();
      expect(widget, isA<BravenPlot<Sample>>());
    });
  });
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/unit/grammar/chart_builder_test.dart`
Expected: FAIL — `BravenChart` has no method `buildFaceted`, and `.build()` does not throw.

- [ ] **Step 3: Write minimal implementation**

In `lib/src/grammar/chart_builder.dart`:

Add the import (after `import 'braven_plot.dart';`):

```dart
import 'braven_facet_plot.dart';
```

Replace the existing `build(...)` method body so it guards on a faceted spec:

```dart
  /// Renders this chain as a single panel.
  ///
  /// The host-facing parameters are the ones [BravenPlot] exposes; everything
  /// about the chart itself comes from the chain. A faceted chain is rejected
  /// here with [GrammarDiagnosticCode.facetedSpecNotLowerable] — render it with
  /// [buildFaceted] instead.
  BravenPlot<T> build({
    Key? key,
    BravenChartController? bravenChartController,
    ChartInteractionGroupController? interactionGroupController,
    ChartEmptyStateConfig emptyStateConfig = const ChartEmptyStateConfig(),
  }) {
    final spec = toSpec();
    if (spec.facet != null) {
      throw GrammarSpecException.facetedSpecNotLowerable();
    }
    return BravenPlot<T>(
      spec,
      key: key,
      bravenChartController: bravenChartController,
      interactionGroupController: interactionGroupController,
      emptyStateConfig: emptyStateConfig,
    );
  }

  /// Renders this chain as a grid of synchronized small-multiple panels.
  ///
  /// Requires a faceted chain (`.facet(...)`); a non-faceted chain is rejected
  /// with [GrammarDiagnosticCode.notFaceted]. The grid owns its own shared
  /// interaction controller, so — unlike [build] — no per-chart controller is
  /// exposed here (a facet grid is N charts).
  BravenFacetPlot<T> buildFaceted({
    Key? key,
    ChartEmptyStateConfig emptyStateConfig = const ChartEmptyStateConfig(),
  }) {
    final spec = toSpec();
    if (spec.facet == null) throw GrammarSpecException.notFaceted();
    return BravenFacetPlot<T>(
      spec,
      key: key,
      emptyStateConfig: emptyStateConfig,
    );
  }
```

(`GrammarSpecException` and `ChartEmptyStateConfig` are already imported in this file via `grammar_diagnostics.dart` and `../models/chart_state_config.dart`.)

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/unit/grammar/chart_builder_test.dart`
Expected: PASS — `All tests passed!`

- [ ] **Step 5: Analyze + commit**

```bash
flutter analyze lib
git add lib/src/grammar/chart_builder.dart test/unit/grammar/chart_builder_test.dart
git commit -m "feat(grammar): .build() facet guard and .buildFaceted() terminal"
```
Expected analyze: `No issues found!`

---

### Task 8: Config parity — panel lowering == standalone spec lowering

**Files:**
- Test: `test/unit/grammar/facet_lowering_parity_test.dart`

**Interfaces:**
- Consumes: `resolveFacetPanels` (Task 6); `PlotSpec.lower()` (existing); `LineChartSeries`, `YAxisConfig`, `XAxisConfig`, `ChartDataPoint` (existing config surface). Barrel exports of `FacetSpec`/`FacetScales`/`BravenFacetPlot` are in place (Tasks 1 & 6).
- Produces: the "emitted == faithful" proof — each panel's lowered `BravenChartPlus` config equals a hand-written standalone `PlotSpec` (same marks + injected range) lowered directly.

- [ ] **Step 1: Write the failing test**

Create `test/unit/grammar/facet_lowering_parity_test.dart`:

```dart
// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

/// Faceting is pure composition: a panel's lowered config equals the config of
/// the equivalent STANDALONE spec (the same marks, the same injected range, the
/// panel's own row subset). The standalone side is written by hand — deriving
/// it from the facet resolution would make this tautological.
library;

import 'package:braven_charts/braven_charts.dart';
import 'package:braven_charts/src/grammar/braven_facet_plot.dart';
import 'package:flutter_test/flutter_test.dart';

class Sample {
  const Sample({required this.time, required this.power, required this.zone});
  final double time;
  final double power;
  final Object? zone;
}

double sampleTime(Sample row) => row.time;
double samplePower(Sample row) => row.power;
Object? sampleZone(Sample row) => row.zone;

const rows = <Sample>[
  Sample(time: 0, power: 180, zone: 'easy'),
  Sample(time: 1, power: 260, zone: 'hard'),
  Sample(time: 2, power: 220, zone: 'easy'),
];

void main() {
  test('a fixed-scale panel lowers to the standalone spec it equals', () {
    const faceted = PlotSpec<Sample>(
      data: rows,
      marks: <Mark<Sample>>[LineMark<Sample>(x: sampleTime, y: samplePower)],
      facet: FacetSpec<Sample>(by: sampleZone),
    );
    // The 'easy' panel: rows 0 and 2, global x-range [0, 2], y-range [180, 260].
    final panel = resolveFacetPanels(faceted).first;
    final panelLowered = panel.spec.lower();

    // Hand-written standalone equivalent — the subset, the injected range.
    final standalone = PlotSpec<Sample>(
      data: const <Sample>[
        Sample(time: 0, power: 180, zone: 'easy'),
        Sample(time: 2, power: 220, zone: 'easy'),
      ],
      marks: const <Mark<Sample>>[
        LineMark<Sample>(x: sampleTime, y: samplePower),
      ],
      xAxis: const XAxisConfig(min: 0, max: 2),
      yAxes: <YAxisConfig>[
        YAxisConfig(position: YAxisPosition.left, min: 180, max: 260),
      ],
    );
    final standaloneLowered = standalone.lower();

    expect(panelLowered.series, standaloneLowered.series);
    expect(panelLowered.yAxes, standaloneLowered.yAxes);
    expect(panelLowered.xAxis, standaloneLowered.xAxis);
    expect(panelLowered.annotations, standaloneLowered.annotations);
  });

  test('a free-scale panel lowers with no injected range', () {
    const faceted = PlotSpec<Sample>(
      data: rows,
      marks: <Mark<Sample>>[LineMark<Sample>(x: sampleTime, y: samplePower)],
      facet: FacetSpec<Sample>(by: sampleZone, scales: FacetScales.free),
    );
    final panel = resolveFacetPanels(faceted).first;
    final lowered = panel.spec.lower();

    expect(lowered.xAxis, isNull);
    // The synthesized default axis carries no bounds under free scaling.
    expect(lowered.yAxes.single.min, isNull);
    expect(lowered.yAxes.single.max, isNull);
    // Same series the standalone subset produces.
    final standalone = const PlotSpec<Sample>(
      data: <Sample>[
        Sample(time: 0, power: 180, zone: 'easy'),
        Sample(time: 2, power: 220, zone: 'easy'),
      ],
      marks: <Mark<Sample>>[LineMark<Sample>(x: sampleTime, y: samplePower)],
    ).lower();
    expect(lowered.series, standalone.series);
  });
}
```

- [ ] **Step 2: Run test to verify it fails, then passes**

Run: `flutter test test/unit/grammar/facet_lowering_parity_test.dart`
Expected: PASS immediately — every symbol it needs already exists (this task adds no lib code; it PROVES the composition). If it FAILS, the failure is a real parity defect in Task 6's `_injectPanel` (e.g. a range injected onto the wrong axis) — fix `_injectPanel`, not the test.

- [ ] **Step 3: Run the whole grammar + widget grammar suite**

Run: `flutter test test/unit/grammar test/widgets/braven_facet_plot_test.dart`
Expected: PASS — `All tests passed!`

- [ ] **Step 4: Commit**

```bash
git add test/unit/grammar/facet_lowering_parity_test.dart
git commit -m "test(grammar): facet panel config-parity with standalone specs"
```

---

### Task 9: Synced-interaction + golden tests

**Files:**
- Modify: `test/widgets/braven_facet_plot_test.dart` (add a synced-interaction `group`)
- Test: `test/golden/grammar_faceting/grammar_faceting_golden_test.dart`

**Interfaces:**
- Consumes: `BravenFacetPlot`, `BravenPlot` (panels), `ChartInteractionGroupController`, `InteractionConfig`/`CrosshairConfig`/`CrosshairDisplayMode`, and `ChartRenderBox` (`package:braven_charts/src/rendering/chart_render_box.dart`) for the pointer drive — the same idiom `test/widgets/braven_plot_test.dart` uses.
- Produces: proof that under `fixed`/`freeY` all panels share ONE non-null controller and a driven crosshair-x reflects on it, while under `freeX`/`free` panels are independent (null controller); plus one representative golden.

- [ ] **Step 1: Write the failing synced-interaction test**

Append to `test/widgets/braven_facet_plot_test.dart` — add the import at the top:

```dart
import 'package:braven_charts/src/rendering/chart_render_box.dart';
import 'package:flutter/gestures.dart';
```

and append this `group` inside `main()`:

```dart
  group('synchronized interaction', () {
    List<BravenPlot<Row>> panelPlots(WidgetTester tester) =>
        tester.widgetList<BravenPlot<Row>>(find.byType(BravenPlot<Row>)).toList();

    testWidgets('fixed scales wire every panel to ONE shared controller', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          const BravenFacetPlot<Row>(
            PlotSpec<Row>(
              data: rows,
              marks: <Mark<Row>>[LineMark<Row>(x: rowT, y: rowPower)],
              facet: FacetSpec<Row>(by: rowZone),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final controllers =
          panelPlots(tester).map((p) => p.interactionGroupController).toSet();
      expect(controllers, hasLength(1));
      expect(controllers.single, isNotNull);
    });

    testWidgets('freeX / free leave the panels independent (no controller)', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          const BravenFacetPlot<Row>(
            PlotSpec<Row>(
              data: rows,
              marks: <Mark<Row>>[LineMark<Row>(x: rowT, y: rowPower)],
              facet: FacetSpec<Row>(by: rowZone, scales: FacetScales.free),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        panelPlots(tester).every((p) => p.interactionGroupController == null),
        isTrue,
      );
    });

    testWidgets('a crosshair-x driven on one panel reflects on the shared '
        'controller', (tester) async {
      await tester.pumpWidget(
        host(
          const BravenFacetPlot<Row>(
            PlotSpec<Row>(
              data: rows,
              marks: <Mark<Row>>[LineMark<Row>(x: rowT, y: rowPower)],
              facet: FacetSpec<Row>(by: rowZone),
              interaction: InteractionConfig(
                crosshair: CrosshairConfig(
                  displayMode: CrosshairDisplayMode.tracking,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final controller = panelPlots(tester).first.interactionGroupController!;
      final renderFinder = find.byWidgetPredicate(
        (widget) => widget.runtimeType.toString() == '_ChartRenderWidget',
      );
      final renderBox = tester.firstRenderObject<ChartRenderBox>(renderFinder);
      const dataX = 1.0;
      final local = renderBox.plotToWidget(
        renderBox.transform!.dataToPlot(
          dataX,
          (renderBox.transform!.dataYMin + renderBox.transform!.dataYMax) / 2,
        ),
      );
      final pointer = await tester.createGesture(kind: PointerDeviceKind.mouse);
      addTearDown(pointer.removePointer);
      await pointer.addPointer(location: Offset.zero);
      await pointer.moveTo(tester.getTopLeft(renderFinder.first) + local);
      await tester.pump();

      expect(controller.cursorX, closeTo(dataX, 0.0001));
    });
  });
```

- [ ] **Step 2: Run the synced-interaction test**

Run: `flutter test test/widgets/braven_facet_plot_test.dart`
Expected: PASS — `All tests passed!`. (No lib change needed: the controller wiring was implemented in Task 6. If the "driven crosshair" case fails, verify the panels' `interaction` reaches each `BravenPlot` — it does, via the panel spec.)

- [ ] **Step 3: Write the golden test**

Create `test/golden/grammar_faceting/grammar_faceting_golden_test.dart`:

```dart
// Copyright 2026 Braven Charts contributors
// SPDX-License-Identifier: MIT

/// One representative faceted chart: 4 panels, fixed scales, strip labels.
library;

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class Row {
  const Row({required this.t, required this.power, required this.zone});
  final double t;
  final double power;
  final Object? zone;
}

double rowT(Row row) => row.t;
double rowPower(Row row) => row.power;
Object? rowZone(Row row) => row.zone;

const rows = <Row>[
  Row(t: 0, power: 180, zone: 'A'),
  Row(t: 1, power: 210, zone: 'A'),
  Row(t: 2, power: 240, zone: 'B'),
  Row(t: 3, power: 220, zone: 'B'),
  Row(t: 4, power: 260, zone: 'C'),
  Row(t: 5, power: 300, zone: 'C'),
  Row(t: 6, power: 280, zone: 'D'),
  Row(t: 7, power: 320, zone: 'D'),
];

void main() {
  testWidgets('faceted line, 4 panels, fixed scales', (tester) async {
    tester.view.physicalSize = const Size(720, 540);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: RepaintBoundary(
            key: const ValueKey('grammar-faceting-golden'),
            child: BravenFacetPlot<Row>(
              const PlotSpec<Row>(
                data: rows,
                marks: <Mark<Row>>[
                  LineMark<Row>(
                    x: rowT,
                    y: rowPower,
                    color: Color(0xFF2563EB),
                  ),
                ],
                facet: FacetSpec<Row>(
                  by: rowZone,
                  columns: 2,
                  label: 'Zone',
                ),
                theme: null,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    await expectLater(
      find.byKey(const ValueKey('grammar-faceting-golden')),
      matchesGoldenFile('goldens/grammar_faceting_fixed.png'),
    );
  });
}
```

- [ ] **Step 4: Generate the golden baseline and verify**

Run: `flutter test --update-goldens test/golden/grammar_faceting/grammar_faceting_golden_test.dart`
Expected: PASS — the baseline `test/golden/grammar_faceting/goldens/grammar_faceting_fixed.png` is written.

Then run without the flag to confirm it matches:

Run: `flutter test test/golden/grammar_faceting/grammar_faceting_golden_test.dart`
Expected: PASS — `All tests passed!`

- [ ] **Step 5: Analyze + commit**

```bash
flutter analyze lib
git add test/widgets/braven_facet_plot_test.dart test/golden/grammar_faceting/grammar_faceting_golden_test.dart test/golden/grammar_faceting/goldens/grammar_faceting_fixed.png
git commit -m "test(grammar): faceting synced-interaction and golden coverage"
```
Expected analyze: `No issues found!`

---

### Task 10: Chart Grammar showcase — a faceting preset

**Files:**
- Modify: `example/lib/showcase/pages/chart_grammar_page.dart`
- Test: `example/test/showcase/chart_grammar_faceting_test.dart`

**Interfaces:**
- Consumes: `BravenChart.of(...).facet(...).buildFaceted()` (Tasks 3 & 7); `BravenFacetPlot`, `FacetScales` (Tasks 1 & 6); the page's existing `GrammarSample`/`sampleMinute`/`samplePower`/`sampleZone`/`rideRows`, `_theme`, `_interaction`, `ChartCard`, `SegmentedOption`, `SliderOption`, `InfoBox`, `OptionSection`.
- Produces: a `faceted` preset that renders a `BravenFacetPlot` directly (NOT inside the single-document workbench — a facet grid is N configs, so it cannot round-trip the one-document workbench; that mirrors the "artifact capture is out of scope" invariant), with `FacetScales` and columns controls.

> **Design note (report to orchestrator):** the existing presets each render inside a `BravenChartWorkbench` that extracts ONE `ChartDocument`. A facet grid is N documents, so the faceted preset's stage renders the `BravenFacetPlot` directly in a `ChartCard` and does not offer the workbench / "Compare hand-built" affordances. The hardcoded `presets` sweep in `example/test/showcase/chart_grammar_page_test.dart` does NOT include `faceted`, so those workbench-shaped sweeps are unaffected; the new behaviour is covered by the new test file below.

- [ ] **Step 1: Write the failing showcase test**

Create `example/test/showcase/chart_grammar_faceting_test.dart`:

```dart
// Copyright 2026 Braven Charts - Chart Grammar faceting preset tests
// SPDX-License-Identifier: MIT

import 'package:braven_charts/braven_charts.dart';
import 'package:braven_charts_example/showcase/pages/chart_grammar_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget subject() =>
      const MaterialApp(home: Scaffold(body: ChartGrammarPage()));

  Future<void> pumpPage(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1440, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(subject());
    await tester.pumpAndSettle();
  }

  Future<void> selectFaceted(WidgetTester tester) async {
    await tester.tap(find.byKey(const ValueKey('chart-grammar-preset-faceted')));
    await tester.pumpAndSettle();
  }

  testWidgets('the faceting preset renders a BravenFacetPlot of panels', (
    tester,
  ) async {
    await pumpPage(tester);
    await selectFaceted(tester);

    expect(find.byType(BravenFacetPlot<GrammarSample>), findsOneWidget);
    // rideRows carry three zones — Endurance, Tempo, Threshold.
    expect(
      find.byType(BravenPlot<GrammarSample>),
      findsNWidgets(3),
    );
    expect(find.text('Zone: Endurance'), findsOneWidget);
    expect(find.text('Zone: Tempo'), findsOneWidget);
    expect(find.text('Zone: Threshold'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the scales control drives the facet spec', (tester) async {
    await pumpPage(tester);
    await selectFaceted(tester);

    BravenFacetPlot<GrammarSample> facetPlot() =>
        tester.widget<BravenFacetPlot<GrammarSample>>(
          find.byType(BravenFacetPlot<GrammarSample>),
        );

    expect(facetPlot().spec.facet!.scales, FacetScales.fixed);

    final scales = find.byKey(const ValueKey('chart-grammar-facet-scales'));
    await tester.tap(find.descendant(of: scales, matching: find.text('free')));
    await tester.pumpAndSettle();

    expect(facetPlot().spec.facet!.scales, FacetScales.free);
    expect(tester.takeException(), isNull);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd example && flutter test test/showcase/chart_grammar_faceting_test.dart`
Expected: FAIL — no `faceted` preset chip exists / `BravenFacetPlot` not mounted.

- [ ] **Step 3: Add the faceting preset to the page**

In `example/lib/showcase/pages/chart_grammar_page.dart`:

(a) Add the enum value — in `enum _GrammarPreset`, insert `faceted` immediately BEFORE `barTransposed` (barTransposed must remain last, per its documented comment):

```dart
enum _GrammarPreset {
  lineTrend,
  multiAxis,
  scatterChannels,
  candlestick,
  referenceLines,
  faceted,
  // barTransposed is kept LAST: BravenChartPlus retains exiting horizontal bars
  // through a cross-fade, and unioning those with a non-bar chart's entering
  // series trips its all-horizontal bounds check. Keeping the transposed preset
  // terminal means the page (and the preset-sweep tests) never animate FROM a
  // just-shown horizontal-bar chart INTO a Cartesian one.
  barTransposed,
}
```

(b) Add the two state fields (with the other preset knobs, after `_thresholdWatts`):

```dart
  // Faceting knobs.
  FacetScales _facetScales = FacetScales.fixed;
  double _facetColumns = 2;
```

(c) Add the faceted chart builder (after `_referenceLinesChart()`):

```dart
  /// One metric faceted across a categorical field — small multiples.
  ///
  /// `.facet(sampleZone)` partitions the ride into one panel per training
  /// zone, in first-seen order. `fixed` scales share both axes so the panels
  /// are directly comparable; `freeY` frees the vertical scale per panel;
  /// `freeX`/`free` also free the horizontal scale, at which point the shared
  /// crosshair is no longer meaningful and the panels interact independently.
  BravenChart<GrammarSample> _facetedChart() => BravenChart.of(rideRows)
      .x(sampleMinute, label: 'Elapsed (min)')
      .y(samplePower, label: 'Power (W)')
      .geomLine(
        name: 'Power',
        color: const Color(0xFF2563EB),
        strokeWidth: 2.2,
        interpolation: LineInterpolation.monotone,
      )
      .facet(
        sampleZone,
        scales: _facetScales,
        columns: _facetColumns.round(),
        label: 'Zone',
      )
      .theme(_theme)
      .interaction(_interaction);
```

(d) Add the `faceted` case to `_activeChart` (needed for exhaustiveness; the faceted stage uses `.buildFaceted()`, not this, but the switch must cover every value):

```dart
    _GrammarPreset.faceted => _facetedChart(),
```

(e) Add the `faceted` case to `_buildHandBuilt` (unreachable — the faceted preset renders its grid directly, bypassing the workbench and the compare toggle — but the switch must be exhaustive):

```dart
    // Unreachable: the faceted preset renders its BravenFacetPlot grid directly
    // (a facet grid is N configs, so there is no single hand-built equivalent
    // and no workbench round-trip).
    _GrammarPreset.faceted => const SizedBox.shrink(),
```

(f) Branch the stage so the faceted preset renders the grid directly. Replace `_buildStage()`'s `child:` so it chooses the facet card for the faceted preset:

```dart
  Widget _buildStage() {
    return ListenableBuilder(
      listenable: _optionsController,
      builder: (context, _) {
        return ChartCard(
          title: _preset.stageTitle,
          subtitle: _preset == _GrammarPreset.faceted
              ? _preset.stageSubtitle
              : _compareHandBuilt
                  ? 'Hand-built BravenChartPlus — the config the spec lowers to'
                  : _preset.stageSubtitle,
          padding: const EdgeInsets.fromLTRB(8, 12, 16, 8),
          child: _preset == _GrammarPreset.faceted
              ? _buildFacetStage()
              : _buildWorkbench(),
        );
      },
    );
  }

  /// The faceted preset renders its grid directly: a facet grid is N configs,
  /// so it does not round-trip the single-document workbench.
  Widget _buildFacetStage() => _facetedChart().buildFaceted(
    key: const ValueKey('chart-grammar-facet-plot'),
  );
```

(g) Add the faceted case to the Preset Controls switch in `_buildOptionsChildren` (the `switch (_preset)` that builds preset controls), alongside the others:

```dart
            _GrammarPreset.faceted => _facetControls(),
```

(h) Add the controls builder (with the other `_*Controls()` methods):

```dart
  List<Widget> _facetControls() => [
    Text(
      'Scales',
      style: TextStyle(fontSize: 12, color: Theme.of(context).hintColor),
    ),
    const SizedBox(height: 4),
    SegmentedOption<FacetScales>(
      key: const ValueKey('chart-grammar-facet-scales'),
      value: _facetScales,
      options: const <FacetScales>[
        FacetScales.fixed,
        FacetScales.freeX,
        FacetScales.freeY,
        FacetScales.free,
      ],
      labelBuilder: (scales) => switch (scales) {
        FacetScales.fixed => 'fixed',
        FacetScales.freeX => 'freeX',
        FacetScales.freeY => 'freeY',
        FacetScales.free => 'free',
      },
      onChanged: (scales) => setState(() => _facetScales = scales),
    ),
    const SizedBox(height: 8),
    SliderOption(
      key: const ValueKey('chart-grammar-facet-columns'),
      label: 'Columns',
      value: _facetColumns,
      min: 1,
      max: 3,
      divisions: 2,
      decimalPlaces: 0,
      onChanged: (value) => setState(() => _facetColumns = value),
    ),
    const InfoBox(
      message:
          'Faceting partitions the ride by training zone — one panel per zone, '
          'in first-seen order. fixed shares both axes so the panels are '
          'directly comparable; freeY frees the vertical scale; freeX / free '
          'free the horizontal scale too, and a shared crosshair only makes '
          'sense when x is shared, so under those the panels interact '
          'independently.',
    ),
  ];
```

(i) Add the `faceted` cases to the `_GrammarPreset` extension switches — `label`, `icon`, `stageTitle`, `stageSubtitle`, `guide` (each is an exhaustive `switch (this)`):

```dart
  // in label:
    _GrammarPreset.faceted => 'Faceting',
  // in icon:
    _GrammarPreset.faceted => Icons.grid_view,
  // in stageTitle:
    _GrammarPreset.faceted => 'One metric across small-multiple panels',
  // in stageSubtitle:
    _GrammarPreset.faceted =>
      'Partition by a categorical field; fixed / free scales and synced x',
  // in guide:
    _GrammarPreset.faceted =>
      'Switch the Scales control: fixed shares both axes so the panels are '
          'directly comparable, freeY frees the vertical scale per panel, and '
          'freeX / free free the horizontal scale — at which point the shared '
          'crosshair is turned off because it is only meaningful when x is '
          'shared. Drag Columns to relayout the grid.',
```

(`hasControls` needs no change: it returns `this != _GrammarPreset.candlestick`, so `faceted` already reports true.)

(j) Ensure `FacetScales` / `BravenFacetPlot` are in scope — they are exported by `package:braven_charts/braven_charts.dart`, which the page already imports. No new import needed.

- [ ] **Step 4: Run the showcase test to verify it passes**

Run: `cd example && flutter test test/showcase/chart_grammar_faceting_test.dart`
Expected: PASS — `All tests passed!`

- [ ] **Step 5: Prove the existing grammar-page sweep still passes**

Run: `cd example && flutter test test/showcase/chart_grammar_page_test.dart`
Expected: PASS — `All tests passed!` (the hardcoded `presets` list excludes `faceted`, so the workbench-shaped sweeps are unaffected; the extra chip does not break the `findsOneWidget` assertions on the other chips).

- [ ] **Step 6: Analyze + commit**

```bash
cd example && flutter analyze lib
cd .. && git add example/lib/showcase/pages/chart_grammar_page.dart example/test/showcase/chart_grammar_faceting_test.dart
git commit -m "feat(showcase): faceting preset on the Chart Grammar page"
```
Expected analyze: `No issues found!`

---

## Final verification (run after Task 10)

- [ ] **Package suite:** `flutter test` → `All tests passed!`
- [ ] **Package analyze:** `flutter analyze lib` → `No issues found!`
- [ ] **Showcase suite:** `cd example && flutter test` → `All tests passed!`
- [ ] **Showcase analyze:** `cd example && flutter analyze lib` → `No issues found!`

---

## Self-Review

**1. Spec coverage — every spec section maps to a task:**

| Spec section / requirement | Task(s) |
|---|---|
| API surface — `FacetScales` enum | 1 |
| API surface — `FacetSpec<T>` grammar value (no copyWith/@chartSurface) | 1 |
| API surface — `.facet(by, columns, scales, label)` verb | 3 |
| API surface — `.buildFaceted()` terminal | 7 |
| Approach B — facet as optional `PlotSpec` field | 2 |
| Approach B — `.build()` guard on a faceted spec | 7 |
| Approach B — `PlotSpec.lower()` throws on a faceted spec | 4 |
| Approach B — per-panel path lowers `spec.facetCleared()` | 2 (helper) + 6 (use) |
| Semantics — partition, first-seen order, null value, `==` | 5 (`distinctFacetValues`) |
| Semantics — 50-panel cap diagnostic | 4 (code) + 6 (enforcement) |
| Semantics — scale sharing / global range injection | 5 (`globalRange`) + 6 (`_injectPanel`) |
| Semantics — synced interaction active only when x shared | 1 (`syncsInteraction`) + 6 (controller wiring) |
| Semantics — layout (auto columns, grid, strips) | 5 (`autoColumns`) + 6 (grid + strip) |
| Architecture — `facet_spec.dart` | 1 |
| Architecture — `plot_spec.dart` (`facet` + `facetCleared`) | 2 |
| Architecture — `plot_lowering.dart` guard | 4 |
| Architecture — `chart_builder.dart` (`.facet`/`.build` guard/`.buildFaceted`) | 3 + 7 |
| Architecture — `braven_facet_plot.dart` | 6 |
| Architecture — `facet_partition.dart` | 5 |
| Architecture — `grammar_diagnostics.dart` | 4 |
| Architecture — core barrel exports | 1 (facet_spec) + 6 (braven_facet_plot) |
| Showcase deliverable — faceting example on the Chart Grammar page | 10 |
| Testing — unit (partition/range/columns) | 5 |
| Testing — widget (N panels, strips, columns, cap) | 6 |
| Testing — synced interaction (shared vs independent) | 9 |
| Testing — parity (panel == standalone) | 8 |
| Testing — diagnostics (build/buildFaceted/lower/zero/cap) | 3, 4, 6, 7 |
| Testing — golden (4 panels, fixed, strips) | 9 |
| Invariant — no config-surface classes / no copyWith | 1, 6 (asserted structurally; surface-enforcement stays green) |
| Out of scope — artifact capture / facet-grid / ragged / shared legend | Not built (documented in Task 10 note + Global Constraints) |

No spec requirement is left without a task.

**2. Placeholder scan:** every code step contains complete, compilable code; every run step names an exact command and expected output. The one `SizedBox.shrink()` in Task 10(e) is real, documented dead-safe code for an unreachable exhaustive-switch arm, not a placeholder. No "TBD" / "similar to Task N" / "handle edge cases" remain.

**3. Type consistency (names/signatures identical across tasks):**
- `FacetScales.{fixed,freeX,freeY,free}`, `FacetScalesSharing.{sharesX,sharesY,syncsInteraction}` — defined Task 1, used Tasks 5/6/9/10 unchanged.
- `FacetSpec<T>({by, columns, scales, label})` — Task 1; constructed identically in Tasks 3, 5, 6, 8, 10.
- `PlotSpec.facet` / `PlotSpec.facetCleared()` — Task 2; used in Tasks 4, 6, 7.
- `resolveFacetPanels<T>(PlotSpec<T>) → List<BravenFacetPanel<T>>`, `BravenFacetPanel<T>{value,label,spec}`, `facetPanelCap` — Task 6; used in Tasks 6, 8.
- `distinctFacetValues`, `globalRange`, `FacetAxis`, `FacetRange`, `autoColumns` — Task 5; used in Task 6.
- Diagnostic codes `facetedSpecNotLowerable` / `notFaceted` / `emptyFacetValues` / `facetPanelCapExceeded` — Task 4; referenced by name in Tasks 4, 6, 7, 9.
- `BravenFacetPlot<T>(spec, {key, emptyStateConfig})` — Task 6; constructed in Tasks 7, 9, 10.

No naming drift found.
