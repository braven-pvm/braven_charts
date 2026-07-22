# Convergence Slice 3b — Close the Source-emitter bar-style gaps Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development or superpowers:executing-plans. Steps use checkbox (`- [ ]`) syntax.

**Goal:** Make the hand-written Source config emitter (`lib/src/source/chart_config_dart_emitter.dart`) emit the bar-chart style objects it currently drops on round-trip — so a bar chart with a pattern fill, motion, diverging style, lollipop, bullet, or a fully-configured label reproduces itself in generated Dart — then un-pin those gaps from the drift gate.

**Architecture:** Slice 3a modelled 22 value-style classes, which made the source-emitter drift gate reveal these gaps (currently pinned in `test/meta/source_emitter_drift_test.dart`). Emission is conditional-on-default (a field is written only when it differs from the class default, so charts that don't use these styles stay byte-identical). We add 7 nested-style helper emitters and wire them into 3 existing methods, add round-trip `contains` tests, then remove the pins.

**Tech Stack:** Dart 3.9 / Flutter 3.35. The document codec (`chart_series_document_codec.dart`) already persists every target field — verified — so the ONLY drop is the emitter.

## Global Constraints

- Worktree `F:\Repositories\braven_charts-convergence`, branch `feature/grammar-convergence` (continues after slice 3a `d3608d42`). Commit per task; do NOT push or open a PR.
- **Zero golden/existing-test drift:** every new emitter helper is default-gated so existing generated output is byte-identical. Existing source tests in `test/unit/source/` MUST stay green unchanged.
- `flutter analyze lib` clean (vendored-safe; NOT root `flutter analyze`). Enforcement `missing=0`.
- No build_runner needed (this slice touches no `@chartSurface` surface — only the emitter + tests). If you run it anyway, revert CR-only churn (`git diff --ignore-cr-at-eol` content-clean).

## Emitter conventions (match EXACTLY — from existing `_emit*` methods)

- Conditional helpers already in the file: `_numberIf(w, 'name', v, default)` (double/num), `_valueIf(w, 'name', v, defaultValue: d)` (bool/int), `_enumIf(w, 'name', 'EnumType', v.name, defaultName: 'case')`, `_colorIf(w, 'name', v, defaultColor)` (non-null Color w/ default), `_optionalColor(w, 'name', v)` (nullable Color), `_optionalNumber`, `_optionalString`, `_optionalNumberList`, `_fontWeightIf`.
- Literals: `DartSourceWriter.colorLiteral(c)`, `DartSourceWriter.numberLiteral(n)`, `DartSourceWriter.stringLiteral(s)`; `writer.namedArgument('name', expr)` writes `name: expr,`; enums fully-qualified (`BarFillPattern.crosshatch`).
- Nested non-null style, default-gated: open with `if (!options.includeDefaultValues && style == const X()) return;`.
- Nested nullable style: caller guards `if (parent.child != null) _emitX(writer, ...);`.
- Reference templates in-file: `_emitBarBorder` (:2219), `_emitBarInteractionStyle` (:2146), `_emitBarWaterfallStyle` (:2176, nested-in-nested), `_emitScatterCategoryStyles` (:736, List-of-objects loop).

---

## File Structure

- Modify: `lib/src/source/chart_config_dart_emitter.dart` — add 7 helper emitters; wire into `_emitBarChartStyle`, `_emitBarLabelStyle`, `_emitBarOptions` (Task 1).
- Modify: `test/unit/source/chart_dart_source_generator_test.dart` — add slice-3b round-trip `contains` tests (Task 1).
- Modify: `test/meta/source_emitter_drift_test.dart` — remove the un-pinned gaps + the comment (Task 2).

---

### Task 1: Emit the bar-style gaps + round-trip tests

**Files:**
- Modify: `lib/src/source/chart_config_dart_emitter.dart`
- Test: `test/unit/source/chart_dart_source_generator_test.dart`

**Interfaces produced (later tasks rely on these emitting):** `barStyle.pattern`, `barStyle.motion`, all 10 `labelStyle` fields, and series `divergingRole`/`divergingStyle`/`lollipopStyle`/`bulletStyle`.

- [ ] **Step 1: Write the failing round-trip tests**

Add this group to `test/unit/source/chart_dart_source_generator_test.dart` (follow the existing `_snapshot`/`_success` helpers — template case at ~:1534). Use SEPARATE series per test (constructor validation makes lollipop/bullet/track mutually exclusive).

```dart
  group('Source-emitter drift-gap fixes (Convergence slice 3b)', () {
    test('emits barStyle.pattern (BarPatternStyle)', () {
      final generated = _success(ChartDartSourceGenerator.generate(_snapshot(
        const BarChartSeries(
          id: 'b', points: [ChartDataPoint(x: 0, y: 1)],
          barStyle: BarChartStyle(
            pattern: BarPatternStyle(pattern: BarFillPattern.crosshatch, spacing: 10),
          ),
        ),
      )));
      expect(generated.source, contains('pattern: BarPatternStyle('));
      expect(generated.source, contains('pattern: BarFillPattern.crosshatch,'));
      expect(generated.source, contains('spacing: 10'));
    });

    test('emits barStyle.motion (BarMotionStyle)', () {
      final generated = _success(ChartDartSourceGenerator.generate(_snapshot(
        const BarChartSeries(
          id: 'b', points: [ChartDataPoint(x: 0, y: 1)],
          barStyle: BarChartStyle(
            motion: BarMotionStyle(order: BarAnimationOrder.centerOut, staggerFraction: 0.2),
          ),
        ),
      )));
      expect(generated.source, contains('motion: BarMotionStyle('));
      expect(generated.source, contains('order: BarAnimationOrder.centerOut,'));
      expect(generated.source, contains('staggerFraction: 0.2'));
    });

    test('emits the 10 previously-dropped labelStyle fields', () {
      final generated = _success(ChartDartSourceGenerator.generate(_snapshot(
        const BarChartSeries(
          id: 'b', points: [ChartDataPoint(x: 0, y: 1)],
          labelStyle: BarLabelStyle(
            show: true,
            collisionPolicy: BarLabelCollisionPolicy.hide,
            plotEdgeAware: false,
            collisionPadding: 5,
            backgroundColor: Color(0xFF102030),
            borderColor: Color(0xFF405060),
            borderWidth: 2,
            borderRadius: 8,
            backgroundPadding: 6,
            callout: BarLabelCalloutStyle(show: true, minimumLength: 9),
            showStackTotal: true,
          ),
        ),
      )));
      final src = generated.source;
      expect(src, contains('collisionPolicy: BarLabelCollisionPolicy.hide,'));
      expect(src, contains('plotEdgeAware: false,'));
      expect(src, contains('collisionPadding: 5'));
      expect(src, contains('backgroundColor: Color(0xFF102030),'));
      expect(src, contains('borderColor: Color(0xFF405060),'));
      expect(src, contains('borderWidth: 2'));
      expect(src, contains('borderRadius: 8'));
      expect(src, contains('backgroundPadding: 6'));
      expect(src, contains('callout: BarLabelCalloutStyle('));
      expect(src, contains('showStackTotal: true,'));
    });

    test('emits series divergingRole + divergingStyle', () {
      final generated = _success(ChartDartSourceGenerator.generate(_snapshot(
        const BarChartSeries(
          id: 'b', points: [ChartDataPoint(x: 0, y: 1)],
          divergingRole: BarDivergingRole.negative,
          divergingStyle: BarDivergingStyle(showCenterLine: false, centerLineWidth: 2),
        ),
      )));
      expect(generated.source, contains('divergingRole: BarDivergingRole.negative,'));
      expect(generated.source, contains('divergingStyle: BarDivergingStyle('));
      expect(generated.source, contains('showCenterLine: false,'));
    });

    test('emits series lollipopStyle (with nested headBorder)', () {
      final generated = _success(ChartDartSourceGenerator.generate(_snapshot(
        const BarChartSeries(
          id: 'b', points: [ChartDataPoint(x: 0, y: 1)],
          lollipopStyle: BarLollipopStyle(
            stemWidth: 4, headRadius: 9,
            headBorder: BarBorderStyle(color: Color(0xFF010203), width: 2),
          ),
        ),
      )));
      expect(generated.source, contains('lollipopStyle: BarLollipopStyle('));
      expect(generated.source, contains('stemWidth: 4'));
      expect(generated.source, contains('headBorder: BarBorderStyle('));
    });

    test('emits series bulletStyle (with BarBulletRange list)', () {
      final generated = _success(ChartDartSourceGenerator.generate(_snapshot(
        const BarChartSeries(
          id: 'b', points: [ChartDataPoint(x: 0, y: 1)],
          bulletStyle: BarBulletStyle(
            ranges: [
              BarBulletRange(endValue: 5, color: Color(0xFFAA0000), label: 'low'),
              BarBulletRange(endValue: 10, color: Color(0xFF00AA00)),
            ],
            cornerRadius: 4,
          ),
        ),
      )));
      final src = generated.source;
      expect(src, contains('bulletStyle: BarBulletStyle('));
      expect(src, contains('ranges: ['));
      expect(src, contains('BarBulletRange('));
      expect(src, contains('endValue: 5'));
      expect(src, contains('color: Color(0xFFAA0000),'));
      expect(src, contains("label: 'low',"));
    });
  });
```

- [ ] **Step 2: Run, verify failure** — Run: `cd F:/Repositories/braven_charts-convergence && flutter test test/unit/source/chart_dart_source_generator_test.dart -N "Convergence slice 3b"`. Expected: FAIL (fields not emitted). If `-N` name-filter is unsupported, run the whole file and confirm the new group fails.

- [ ] **Step 3: Add the 7 helper emitters**

Add these methods near the existing `_emitBar*` helpers (after `_emitBarWaterfallStyle`, ~:2205). Verify each field name/default against the class source while pasting.

```dart
  void _emitBarPatternStyle(DartSourceWriter writer, BarPatternStyle style) {
    writer.writeLine('pattern: BarPatternStyle(');
    writer.indented(() {
      writer.namedArgument('pattern', 'BarFillPattern.${style.pattern.name}');
      _optionalColor(writer, 'color', style.color);
      _numberIf(writer, 'spacing', style.spacing, 8);
      _numberIf(writer, 'strokeWidth', style.strokeWidth, 1.5);
      _numberIf(writer, 'opacity', style.opacity, 0.55);
    });
    writer.writeLine('),');
  }

  void _emitBarMotionStyle(DartSourceWriter writer, BarMotionStyle style) {
    if (!options.includeDefaultValues && style == const BarMotionStyle()) return;
    writer.writeLine('motion: BarMotionStyle(');
    writer.indented(() {
      _enumIf(writer, 'order', 'BarAnimationOrder', style.order.name,
          defaultName: 'together');
      _numberIf(writer, 'staggerFraction', style.staggerFraction, 0);
    });
    writer.writeLine('),');
  }

  void _emitBarLabelCalloutStyle(
      DartSourceWriter writer, BarLabelCalloutStyle style) {
    if (!options.includeDefaultValues && style == const BarLabelCalloutStyle()) {
      return;
    }
    writer.writeLine('callout: BarLabelCalloutStyle(');
    writer.indented(() {
      _valueIf(writer, 'show', style.show, defaultValue: false);
      _optionalColor(writer, 'color', style.color);
      _numberIf(writer, 'width', style.width, 1);
      _numberIf(writer, 'minimumLength', style.minimumLength, 4);
    });
    writer.writeLine('),');
  }

  void _emitBarDivergingStyle(DartSourceWriter writer, BarDivergingStyle style) {
    if (!options.includeDefaultValues && style == const BarDivergingStyle()) {
      return;
    }
    writer.writeLine('divergingStyle: BarDivergingStyle(');
    writer.indented(() {
      _valueIf(writer, 'showCenterLine', style.showCenterLine, defaultValue: true);
      _colorIf(writer, 'centerLineColor', style.centerLineColor,
          const Color(0xFF64748B));
      _numberIf(writer, 'centerLineWidth', style.centerLineWidth, 1.25);
      _numberIf(writer, 'centerLineOpacity', style.centerLineOpacity, 0.7);
    });
    writer.writeLine('),');
  }

  void _emitBarLollipopStyle(DartSourceWriter writer, BarLollipopStyle style) {
    writer.writeLine('lollipopStyle: BarLollipopStyle(');
    writer.indented(() {
      _numberIf(writer, 'stemWidth', style.stemWidth, 3);
      _numberIf(writer, 'headRadius', style.headRadius, 7);
      _optionalColor(writer, 'stemColor', style.stemColor);
      _optionalColor(writer, 'headColor', style.headColor);
      if (style.headBorder != null) {
        _emitBarBorder(writer, 'headBorder', style.headBorder!);
      }
    });
    writer.writeLine('),');
  }

  void _emitBarBulletStyle(DartSourceWriter writer, BarBulletStyle style) {
    writer.writeLine('bulletStyle: BarBulletStyle(');
    writer.indented(() {
      writer.writeLine('ranges: [');
      writer.indented(() {
        for (final range in style.ranges) {
          writer.writeLine('BarBulletRange(');
          writer.indented(() {
            writer.namedArgument(
                'endValue', DartSourceWriter.numberLiteral(range.endValue));
            writer.namedArgument(
                'color', DartSourceWriter.colorLiteral(range.color));
            _optionalString(writer, 'label', range.label);
          });
          writer.writeLine('),');
        }
      });
      writer.writeLine('],');
      _numberIf(writer, 'measureThicknessFactor', style.measureThicknessFactor, 0.45);
      _numberIf(writer, 'cornerRadius', style.cornerRadius, 3);
    });
    writer.writeLine('),');
  }
```

Notes while pasting:
- If `_optionalString` does not exist in the file, replace that line with: `if (range.label != null) writer.namedArgument('label', DartSourceWriter.stringLiteral(range.label!));`.
- `BarPatternStyle.pattern` is required (no default) → emitted unconditionally. `BarBulletRange.endValue`/`color` are required → unconditional. That is intentional and correct.

- [ ] **Step 4: Wire the helpers into the 3 existing methods**

**`_emitBarChartStyle`** (:2107): add `pattern` between the `gradient` block and the `border` block; add `motion` after the `animationMode` `_enumIf`:
```dart
      // ...after the gradient block, before the border block:
      if (style.pattern != null) {
        _emitBarPatternStyle(writer, style.pattern!);
      }
      // ...after the animationMode _enumIf (last statement in indented()):
      _emitBarMotionStyle(writer, style.motion);
```

**`_emitBarLabelStyle`** (:2264): after `_numberIf(writer, 'padding', style.padding, 4);` and BEFORE the `if (style.formatter != null)` block, insert (constructor field order):
```dart
      _enumIf(writer, 'collisionPolicy', 'BarLabelCollisionPolicy',
          style.collisionPolicy.name, defaultName: 'none');
      _valueIf(writer, 'plotEdgeAware', style.plotEdgeAware, defaultValue: true);
      _numberIf(writer, 'collisionPadding', style.collisionPadding, 2);
      _optionalColor(writer, 'backgroundColor', style.backgroundColor);
      _optionalColor(writer, 'borderColor', style.borderColor);
      _numberIf(writer, 'borderWidth', style.borderWidth, 0);
      _numberIf(writer, 'borderRadius', style.borderRadius, 4);
      _numberIf(writer, 'backgroundPadding', style.backgroundPadding, 3);
      _emitBarLabelCalloutStyle(writer, style.callout);
      _valueIf(writer, 'showStackTotal', style.showStackTotal, defaultValue: false);
```

**`_emitBarOptions`** (:2048): read the method's actual series-parameter name (e.g. `series`). Add `divergingRole` + `divergingStyle` adjacent to the existing `barStyle` emission, and `lollipopStyle` + `bulletStyle` right after the `trackStyle` emission (mirrors constructor grouping; exact position is functionally free since all are guarded/default-gated):
```dart
      _enumIf(writer, 'divergingRole', 'BarDivergingRole',
          series.divergingRole.name, defaultName: 'positive');
      _emitBarDivergingStyle(writer, series.divergingStyle);
      // ...after the trackStyle emission:
      if (series.lollipopStyle != null) {
        _emitBarLollipopStyle(writer, series.lollipopStyle!);
      }
      if (series.bulletStyle != null) {
        _emitBarBulletStyle(writer, series.bulletStyle!);
      }
```
(Use the real parameter name; if it is not `series`, substitute it.)

- [ ] **Step 5: Run the new tests + the existing source suite**

Run: `cd F:/Repositories/braven_charts-convergence && flutter test test/unit/source/ && flutter analyze lib`
Expected: the new slice-3b group PASSES; ALL existing `test/unit/source/` tests still PASS unchanged (byte-identical output for default charts — the compile test `chart_generated_source_compile_test.dart` proves the new emitted Dart formats+analyzes). If any existing test changed output, a helper is emitting on a default value — fix the gating.

- [ ] **Step 6: Commit**
```bash
git add lib/src/source/chart_config_dart_emitter.dart test/unit/source/chart_dart_source_generator_test.dart
git commit -m "fix(source): emit bar pattern/motion, full label style, diverging/lollipop/bullet series styles"
```

---

### Task 2: Un-pin the closed gaps + full verify

**Files:**
- Modify: `test/meta/source_emitter_drift_test.dart`

- [ ] **Step 1: Run the drift gate — expect it to now FAIL as STALE**

Run: `flutter test test/meta/source_emitter_drift_test.dart`
Expected: FAIL — the "pinned … are all still real" sub-tests now detect that the previously-pinned classes/props ARE emitted (stale pins). This confirms Task 1 closed them.

- [ ] **Step 2: Remove the closed pins**

In `test/meta/source_emitter_drift_test.dart`:
- From `_classesNotEmittedBySource` (:82) REMOVE the 7: `BarPatternStyle`, `BarMotionStyle`, `BarLabelCalloutStyle`, `BarDivergingStyle`, `BarLollipopStyle`, `BarBulletStyle`, `BarBulletRange`. KEEP `ChartDataTableTheme`, `StreamingConfig`, `AutoScrollConfig`, `CartesianValueSummaryTheme`.
- From `_propertyGaps` (:136) REMOVE the 9: `BarChartSeries.divergingRole`, `BarChartSeries.divergingStyle`, `BarChartSeries.lollipopStyle`, `BarChartSeries.bulletStyle`, `BarChartStyle.pattern`, `BarChartStyle.motion`, `BarLabelStyle.backgroundPadding`, `BarLabelStyle.callout`, `BarLabelStyle.showStackTotal`. KEEP `ChartTheme.cartesianValueSummaryTheme`, `MultiAxisConfig.bindings`.
- DELETE the `BarLabelStyle also drops 7 more fields…` comment block (:164-172) — those 7 fields (`collisionPolicy`, `plotEdgeAware`, `collisionPadding`, `backgroundColor`, `borderColor`, `borderWidth`, `borderRadius`) are now emitted for `BarLabelStyle`, so the blind-spot note no longer applies.

- [ ] **Step 3: Re-run the gate — expect GREEN**

Run: `flutter test test/meta/source_emitter_drift_test.dart`
Expected: PASS. The gate now reports fewer pinned classes/props and all remaining pins are still real. If it still flags a `BarLabelStyle` property as an un-emitted modelled gap, a field wasn't wired in Task 1 — go back and fix the emitter (do NOT re-pin).

- [ ] **Step 4: Full verify**

Run: `cd F:/Repositories/braven_charts-convergence && flutter analyze lib && flutter test`
Expected: PASS; report new total vs 3318; zero golden drift; enforcement `missing=0`.

- [ ] **Step 5: Commit**
```bash
git add test/meta/source_emitter_drift_test.dart
git commit -m "test(meta): un-pin the 7 bar-style classes + 9 property gaps now emitted by the source generator"
```

---

## Self-Review checklist

1. All 7 helpers added; 3 methods wired; every field mapped to the correct helper + default.
2. Existing `test/unit/source/` output byte-identical (default charts emit nothing new) — no golden drift.
3. Generated Dart for the new styles formats + analyzes (compile test green).
4. Drift gate: 7 classes + 9 props removed; the 7-field comment deleted; gate green; `ChartDataTableTheme`/`StreamingConfig`/`AutoScrollConfig`/`CartesianValueSummaryTheme` + `ChartTheme.cartesianValueSummaryTheme` + `MultiAxisConfig.bindings` still pinned (untouched).
5. `BarLabelStyle.formatter` still a comment (excluded), unchanged.
