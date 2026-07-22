# Convergence Slice 3a — `copyWith` for the 22 value-style classes Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Give the 22 immutable value-style config classes (`Bar*`/`Candlestick*Style`/`Scatter*Config`) a `copyWith` and a `@chartSurface` annotation so they enter the fluent-surface generator, hard-mode enforcement, and both drift gates — closing the coverage boundary that slices 1–2 explicitly could not reach.

**Architecture:** Each class already has a `const` all-named constructor and hand-written `==`/`hashCode`. We add (1) a `copyWith` following the established `ScatterMarkerStyle` clear-flag idiom, and (2) a `@chartSurface` annotation. `tool/surface_gen` then generates fluent extensions for them automatically. Modelling them makes the AI-mirror gate's `_builderTargetsOutsideSurfaceModel` pins stale (remove them) and makes the source-emitter gate SEE 9 pre-existing emitter gaps (pin them here for slice 3b to fix).

**Tech Stack:** Dart 3.9 / Flutter 3.35, `build_runner` + `source_gen` (dev-only `tool/surface_gen`), the opt-in `package:braven_charts/braven_charts_fluent.dart` barrel.

## Global Constraints

- Work in worktree `F:\Repositories\braven_charts-convergence`, branch `feature/grammar-convergence`. Commit per task; do NOT push or open a PR.
- Invariants every task preserves: `flutter analyze lib` clean; enforcement `missing=0` (`test/meta/surface_enforcement_test.dart`); zero golden drift; the round-trip proof ("emitted == faithful"); config- and artifact-parity; the opt-in fluent barrel stays out of the core barrel.
- After any `build_runner`, revert CR-only churn on generated files before committing: `git diff --ignore-cr-at-eol` must show zero content diff for files you didn't semantically change.
- Run the vendored-safe analyze (`flutter analyze lib`), NOT root `flutter analyze` (fails on vendored `packages/fleather`).
- `copyWith` clear-flag naming convention (avoids any `clearFlags:` annotation entry): for a nullable field `foo`, name the flag exactly `clearFoo` (PascalCase the field). The generator defaults to expecting `clear<Field>`, so this convention needs no mapping.

## The `copyWith` template (apply mechanically to every class)

For a class `X` with fields `a` (non-nullable) and `b` (nullable `T?`):

```dart
X copyWith({
  TA? a,
  TB? b,
  bool clearB = false,
}) => X(
  a: a ?? this.a,
  b: clearB ? null : (b ?? this.b),
);
```

- Non-nullable field → param typed nullable (`TA? a`), body `a: a ?? this.a`. NO clear flag.
- Nullable field (`TB? b`) → param `TB? b` PLUS `bool clearB = false`, body `b: clearB ? null : (b ?? this.b)`.
- Place `copyWith` immediately before the `operator ==` override. Preserve field order.
- `List<...>` fields follow the same rule (non-nullable list → `?? this.field`; nullable list → clear-flag form). Do not deep-copy.

Reference idiom: `lib/src/models/scatter_marker_style.dart:657-682` (`ScatterMarkerStyle.copyWith`).

---

## File Structure

- Modify: `lib/src/models/bar_chart_style.dart` — add `copyWith` + `@chartSurface` to 17 classes (Task 1).
- Modify: `lib/src/models/candlestick_chart_style.dart` — 2 classes (Task 2).
- Modify: `lib/src/models/scatter_render_config.dart` — 3 classes (Task 2).
- Create: `test/models/copywith_value_classes_test.dart` — round-trip parity tests for all 22 (Tasks 1–2 append).
- Regenerate: the fluent barrel/extensions under `lib/src/**_fluent.dart` via `dart run build_runner build` (Task 3).
- Modify: `test/meta/ai_mirror_drift_test.dart` — remove the 22 from `_builderTargetsOutsideSurfaceModel` (Task 3).
- Modify: `test/meta/source_emitter_drift_test.dart` — pin the 9 revealed emitter gaps in `_classesNotEmittedBySource`/`_propertyGaps` (Task 3).

---

### Task 1: `bar_chart_style.dart` — 17 classes

**Files:**
- Modify: `lib/src/models/bar_chart_style.dart`
- Test: `test/models/copywith_value_classes_test.dart` (create)

**Interfaces:**
- Produces: `copyWith` on all 17 bar classes + `@chartSurface`/`@ChartSurface(...)` annotations. Task 3 consumes these (regenerates fluent, reconciles gates).

**Annotation decisions for this file:**
- Bare `@chartSurface` (no options): BarDivergingStyle, BarMotionStyle, BarGradient, BarPatternStyle, BarBorderStyle, BarInteractionStyle, BarChartStyle, BarTrackStyle, BarLollipopStyle, BarBulletRange, BarBulletStyle, BarTargetMarkerStyle, BarErrorBarStyle, BarWaterfallConnectorStyle, BarWaterfallStyle, BarLabelCalloutStyle.
- `BarLabelStyle`: `@ChartSurface(excluded: ['formatter'])` — `formatter` is a `String Function(ChartDataPoint)?` runtime-only callback (artifact codec omits it). Include `formatter` + `clearFormatter` in `copyWith` (preserve/clear it), but exclude it from the surface. Do NOT add a `paramNotes` entry for it (a note on an excluded param fails the build).
- None of the 17 have a multi-parameter constructor assert, so NONE need `combinedSetters` in this file. (Verify while editing: all bar asserts are single-parameter.)
- Import for the annotation: `import '../meta/chart_surface.dart';` (add if absent).

- [ ] **Step 1: Write the failing round-trip test (create the file with the bar section)**

`test/models/copywith_value_classes_test.dart`:
```dart
import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('bar value-class copyWith', () {
    test('BarChartStyle copyWith replaces one field, preserves the rest', () {
      const base = BarChartStyle(cornerRadius: 2, opacity: 0.9);
      final next = base.copyWith(opacity: 0.5);
      expect(next.opacity, 0.5);
      expect(next.cornerRadius, 2);
      expect(base.copyWith(), equals(base)); // identity
    });

    test('BarChartStyle clear flag unsets a nullable nested field', () {
      const base = BarChartStyle(border: BarBorderStyle(color: Color(0xFF000000)));
      expect(base.copyWith(clearBorder: true).border, isNull);
      expect(base.copyWith().border, isNotNull); // no-op preserves
    });

    test('BarTrackStyle clear flag unsets nullable value', () {
      const base = BarTrackStyle(color: Color(0xFF112233), value: 10);
      expect(base.copyWith(clearValue: true).value, isNull);
      expect(base.copyWith(value: 20).value, 20);
    });
  });
}
```

- [ ] **Step 2: Run it, verify it fails to compile (no `copyWith` yet)**

Run: `cd F:/Repositories/braven_charts-convergence && flutter test test/models/copywith_value_classes_test.dart`
Expected: FAIL — `The method 'copyWith' isn't defined for the type 'BarChartStyle'`.

- [ ] **Step 3: Add `copyWith` + `@chartSurface` to all 17 classes**

Apply the template (see top of plan) to each class, using each field's declared nullability. Add the annotation immediately above each `class` declaration. Add the `chart_surface.dart` import.

- [ ] **Step 4: Run the bar test group + analyze**

Run: `cd F:/Repositories/braven_charts-convergence && flutter test test/models/copywith_value_classes_test.dart && flutter analyze lib`
Expected: PASS + no analyzer issues.

- [ ] **Step 5: Commit**

```bash
git add lib/src/models/bar_chart_style.dart test/models/copywith_value_classes_test.dart
git commit -m "feat(models): add copyWith + @chartSurface to the 17 Bar value-style classes"
```

---

### Task 2: `candlestick_chart_style.dart` (2) + `scatter_render_config.dart` (3)

**Files:**
- Modify: `lib/src/models/candlestick_chart_style.dart`
- Modify: `lib/src/models/scatter_render_config.dart`
- Test: `test/models/copywith_value_classes_test.dart` (append groups)

**Annotation decisions:**
- `CandlestickChartStyle`: `@ChartSurface(combinedSetters: [CombinedSetter('withBodyWidthLimits', ['minBodyWidth', 'maxBodyWidth'])])` — assert `maxBodyWidth >= minBodyWidth` couples the two. 9 nullable `Color?` fields → 9 clear flags.
- `CandlestickAnimationStyle`: bare `@chartSurface` (single-param assert only).
- `ScatterClusterConfig`: `@ChartSurface(combinedSetters: [CombinedSetter('withRadiusBounds', ['minimumRadius', 'maximumRadius'])])` — assert `minimumRadius <= maximumRadius`.
- `ScatterBinConfig`: `@ChartSurface(combinedSetters: [CombinedSetter('withOpacityBounds', ['minimumOpacity', 'maximumOpacity'])])` — assert `maximumOpacity >= minimumOpacity`.
- `ScatterDensityConfig`: `@ChartSurface(combinedSetters: [CombinedSetter('withOpacityBounds', ['minimumOpacity', 'maximumOpacity'])])` — assert `maximumOpacity >= minimumOpacity`.
- Imports: `candlestick_chart_style.dart` and `scatter_render_config.dart` each need `import '../meta/chart_surface.dart';` (add if absent). `scatter_render_config.dart` is pure-Dart today; the annotation import is fine (no Flutter dep introduced).
- All three Scatter configs have only `double`/`int`/`bool`/enum fields with defaults → NO nullable fields → NO clear flags. Candlestick has the 9 nullable colors.

- [ ] **Step 1: Append the failing tests**

Append to `test/models/copywith_value_classes_test.dart`:
```dart
  group('candlestick + scatter value-class copyWith', () {
    test('CandlestickChartStyle clears a nullable colour, preserves others', () {
      const base = CandlestickChartStyle(
        risingBodyFillColor: Color(0xFF00FF00),
        bodyWidthFactor: 0.5,
      );
      expect(base.copyWith(clearRisingBodyFillColor: true).risingBodyFillColor, isNull);
      expect(base.copyWith(clearRisingBodyFillColor: true).bodyWidthFactor, 0.5);
      expect(base.copyWith(bodyWidthFactor: 0.6).bodyWidthFactor, 0.6);
    });

    test('ScatterClusterConfig copyWith replaces one field', () {
      const base = ScatterClusterConfig(cellSize: 40, maximumRadius: 24);
      expect(base.copyWith(cellSize: 50).cellSize, 50);
      expect(base.copyWith(cellSize: 50).maximumRadius, 24);
      expect(base.copyWith(), equals(base));
    });

    test('ScatterBinConfig + ScatterDensityConfig copyWith identity', () {
      const bin = ScatterBinConfig(cellSize: 36);
      const density = ScatterDensityConfig(bandwidth: 32);
      expect(bin.copyWith(), equals(bin));
      expect(density.copyWith(contourCount: 8).contourCount, 8);
    });
  });
```

- [ ] **Step 2: Run, verify compile failure** — Run: `flutter test test/models/copywith_value_classes_test.dart`. Expected: FAIL (no `copyWith`).

- [ ] **Step 3: Add `copyWith` + annotations to the 5 classes** per the template and the annotation decisions above.

- [ ] **Step 4: Run the tests + analyze** — Run: `flutter test test/models/copywith_value_classes_test.dart && flutter analyze lib`. Expected: PASS + clean.

- [ ] **Step 5: Commit**

```bash
git add lib/src/models/candlestick_chart_style.dart lib/src/models/scatter_render_config.dart test/models/copywith_value_classes_test.dart
git commit -m "feat(models): add copyWith + @chartSurface to candlestick + scatter value classes"
```

---

### Task 3: Regenerate fluent, reconcile both drift gates, full verify

**Files:**
- Regenerate: `lib/src/**_fluent.dart` (+ `lib/src/ai/generated/surface_definitions.dart`) via build_runner.
- Modify: `test/meta/ai_mirror_drift_test.dart` — empty out `_builderTargetsOutsideSurfaceModel` (all 22 are now modelled).
- Modify: `test/meta/source_emitter_drift_test.dart` — pin the 9 revealed emitter gaps.

**Interfaces:**
- Consumes: the 22 annotated classes from Tasks 1–2.

- [ ] **Step 1: Regenerate the surface + fluent extensions**

Run: `cd F:/Repositories/braven_charts-convergence && dart run build_runner build --delete-conflicting-outputs`
Then normalize CRLF churn: verify `git diff --ignore-cr-at-eol --stat` shows only semantically-changed generated files. Expected new/changed: fluent extensions for the 22 classes + `surface_definitions.dart` gains 22 entries.

- [ ] **Step 2: Run enforcement — expect it GREEN (all 22 now annotated)**

Run: `flutter test test/meta/surface_enforcement_test.dart`
Expected: PASS with `missing=0`. (Before Tasks 1–2 these classes had no `copyWith` so did not trip enforcement; now they have `copyWith` AND `@chartSurface`, so they stay green.)

- [ ] **Step 3: Run the AI-mirror gate — expect it to FAIL, then fix**

Run: `flutter test test/meta/ai_mirror_drift_test.dart`
Expected: FAIL — the 22 now appear in `surfaceDefinitions` but are still listed in `_builderTargetsOutsideSurfaceModel` (a pinned-but-fixed staleness). Fix: reduce `_builderTargetsOutsideSurfaceModel` to `<String>{}` (empty) — every entry was one of these 22. Re-run; expect PASS. If any of the 22 is now flagged as builder-parsed-but-undocumented, that is a REAL AI-schema gap — STOP and report it (do not silently re-pin).

- [ ] **Step 4: Run the source-emitter gate — expect it to FAIL on 9 classes, then pin them**

Run: `flutter test test/meta/source_emitter_drift_test.dart`
Expected: FAIL. The gate now sees these 22 modelled classes and finds the emitter does not name every property of 9 of them. Pin exactly these, each with a reason ending `— fix in slice 3b`:
- `_classesNotEmittedBySource` (emitter has NO construction site): `BarPatternStyle`, `BarMotionStyle`, `BarLabelCalloutStyle`, `BarDivergingStyle`, `BarLollipopStyle`, `BarBulletStyle`, `BarBulletRange`.
- `_propertyGaps` (emitter method exists but skips fields):
  - `BarChartStyle`: `pattern`, `motion`.
  - `BarLabelStyle`: `collisionPolicy`, `plotEdgeAware`, `collisionPadding`, `backgroundColor`, `borderColor`, `borderWidth`, `borderRadius`, `backgroundPadding`, `callout`, `showStackTotal`.

Re-run; expect PASS. These pins document REAL pre-existing silent-drift bugs (the emitter loses these on round-trip) that slice 3b will fix and un-pin. Verify the remaining 13 modelled classes are NOT flagged (the emitter already handles them fully). If the gate flags a property NOT in the list above, the emitter coverage differs from recon — STOP and report before pinning.

- [ ] **Step 5: Executing smoke test — confirm the new verbs actually run**

Run: `flutter test test/meta/` (the meta suite includes the executing smoke test that invokes generated verbs, not just compiles them). Expected: PASS — the 22 classes' `withX`/`clearX`/`updateX`/combined verbs execute without throwing. If a `combinedSetter` verb or a `clearX` verb is missing/misnamed, fix the annotation (`combinedSetters` param list or the `clearFlags`/field-name convention) and regenerate.

- [ ] **Step 6: Full suite + analyze + golden**

Run: `cd F:/Repositories/braven_charts-convergence && flutter analyze lib && flutter test`
Expected: PASS, no golden drift. Note the new total (baseline 3290 + new tests).

- [ ] **Step 7: Final CRLF normalize + commit**

Verify `git diff --ignore-cr-at-eol` is content-clean on generated files. Then:
```bash
git add -A
git commit -m "feat(fluent): model the 22 value-style classes; reconcile AI + source drift gates

- empty _builderTargetsOutsideSurfaceModel (all 22 now in the surface model)
- pin 9 source-emitter gaps revealed by modelling (BarChartStyle.pattern/motion,
  BarLabelStyle 10 fields, BarPattern/Motion/LabelCallout/Diverging/Lollipop/Bullet
  entirely un-emitted) — real silent-drift bugs for slice 3b"
```

---

## Slice 3b handoff (NOT this plan)

Modelling revealed real Source-emitter round-trip drops. Slice 3b fixes the emitter (extend `_emitBarChartStyle`, `_emitBarLabelStyle`; add `_emitBarPatternStyle`/`_emitBarMotionStyle`/`_emitBarLabelCalloutStyle`; emit `divergingStyle`/`lollipopStyle`/`bulletStyle` in `_emitBarOptions`) with round-trip parity tests, then un-pins them from `source_emitter_drift_test.dart`. Each fix is a real bug: a bar chart with a pattern fill, diverging style, lollipop, or bullet currently generates Dart Source that reconstructs a DIFFERENT chart.

### The BarLabelStyle 10-field drop (gate-visibility caveat — READ THIS)

`_emitBarLabelStyle` writes only `show, position, valueMode, color, fontSize, fontWeight, showUnit, padding`. It silently drops **all 10** of these `BarLabelStyle` fields on round-trip, and slice 3b MUST emit every one of them:

1. `collisionPolicy`
2. `plotEdgeAware`
3. `collisionPadding`
4. `backgroundColor`
5. `borderColor`
6. `borderWidth`
7. `borderRadius`
8. `backgroundPadding`
9. `callout`
10. `showStackTotal`

**Only the last 3 (`backgroundPadding`, `callout`, `showStackTotal`) are pinned in `source_emitter_drift_test.dart`.** The first 7 are just as broken but are INVISIBLE to that gate: it is a flat name-union scan, and those 7 names are emitted for OTHER classes (`collisionPolicy`/`plotEdgeAware`/`collisionPadding` for the label-config family; `backgroundColor`/`borderColor`/`borderWidth`/`borderRadius` for many styled components), so `isEmitted()` returns true and pinning them would fail the gate's own "pins still real" sub-test. This is the gate's documented name-collision blind spot. Slice 3b must fix all 10 regardless of the gate, and un-pin the 3 visible ones; truly closing the blind spot for the other 7 needs a class-aware coverage scan (a separate slice).

## Self-Review checklist (run after Tasks complete)

1. All 22 classes have `copyWith` + an annotation; enforcement `missing=0`.
2. Every nullable field has a `clear<Field>` flag; no `clearFlags:` mapping needed (convention followed).
3. The 4 `combinedSetters` classes verified; their combined verbs execute in the smoke test.
4. `_builderTargetsOutsideSurfaceModel` is empty; source-emitter gate pins exactly the 9 listed classes/props.
5. `git diff --ignore-cr-at-eol` content-clean on generated files.
