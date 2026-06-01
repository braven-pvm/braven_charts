# Baseline Area Fill — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add `baselineValue`, `aboveBaselineFillColor`, and `belowBaselineFillColor` fields to `AreaChartSeries` so the area fill is drawn between the series line and a fixed reference Y value, with independently configurable colours above and below that reference.

**Architecture:** Two isolated tasks — model layer first (new fields, value semantics), then rendering (new `_paintAreaSeriesBaseline` method that polygon-splits at crossing points). No other files change.

**Tech Stack:** Flutter/Dart, `dart:ui` Canvas/Path, `InterpolationGeometry.addPathSegments`, `_currentTransform.dataToPlot`.

---

## File map

| File | Change |
|------|--------|
| `lib/src/models/chart_series.dart` | Add 3 fields to `AreaChartSeries`; update constructor, `copyWith`, `==`, `hashCode`, `toString` |
| `lib/src/elements/series_element.dart` | Add `_paintAreaSeriesBaseline`; add early-exit branch in `_paintAreaSeries` |
| `test/unit/models/area_chart_series_baseline_test.dart` | New — unit tests for model fields |

---

## Task 1: Model layer — new fields on `AreaChartSeries`

**Files:**
- Modify: `lib/src/models/chart_series.dart:462-589`
- Create: `test/unit/models/area_chart_series_baseline_test.dart`

### Step 1: Write failing tests

- [ ] Create `test/unit/models/area_chart_series_baseline_test.dart`:

```dart
import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AreaChartSeries baseline fields', () {
    test('baselineValue defaults to null', () {
      const s = AreaChartSeries(id: 'a', points: []);
      expect(s.baselineValue, isNull);
    });

    test('aboveBaselineFillColor defaults to null', () {
      const s = AreaChartSeries(id: 'a', points: []);
      expect(s.aboveBaselineFillColor, isNull);
    });

    test('belowBaselineFillColor defaults to null', () {
      const s = AreaChartSeries(id: 'a', points: []);
      expect(s.belowBaselineFillColor, isNull);
    });

    test('copyWith preserves baselineValue when not overridden', () {
      const s = AreaChartSeries(id: 'a', points: [], baselineValue: 133.0);
      expect(s.copyWith(id: 'b').baselineValue, 133.0);
    });

    test('copyWith updates baselineValue', () {
      const s = AreaChartSeries(id: 'a', points: [], baselineValue: 133.0);
      expect(s.copyWith(baselineValue: 200.0).baselineValue, 200.0);
    });

    test('copyWith preserves aboveBaselineFillColor when not overridden', () {
      const color = Color(0xFF00FF00);
      const s = AreaChartSeries(id: 'a', points: [], aboveBaselineFillColor: color);
      expect(s.copyWith(id: 'b').aboveBaselineFillColor, color);
    });

    test('copyWith preserves belowBaselineFillColor when not overridden', () {
      const color = Color(0xFFFF0000);
      const s = AreaChartSeries(id: 'a', points: [], belowBaselineFillColor: color);
      expect(s.copyWith(id: 'b').belowBaselineFillColor, color);
    });

    test('== treats same baselineValue as equal', () {
      const a = AreaChartSeries(id: 'a', points: [], baselineValue: 133.0);
      const b = AreaChartSeries(id: 'a', points: [], baselineValue: 133.0);
      expect(a, equals(b));
    });

    test('== treats different baselineValues as not equal', () {
      const a = AreaChartSeries(id: 'a', points: [], baselineValue: 133.0);
      const b = AreaChartSeries(id: 'a', points: [], baselineValue: 200.0);
      expect(a, isNot(equals(b)));
    });

    test('null baselineValue differs from non-null in ==', () {
      const a = AreaChartSeries(id: 'a', points: []);
      const b = AreaChartSeries(id: 'a', points: [], baselineValue: 133.0);
      expect(a, isNot(equals(b)));
    });

    test('hashCode is consistent with ==', () {
      const a = AreaChartSeries(
        id: 'a',
        points: [],
        baselineValue: 133.0,
        aboveBaselineFillColor: Color(0xFF00FF00),
      );
      const b = AreaChartSeries(
        id: 'a',
        points: [],
        baselineValue: 133.0,
        aboveBaselineFillColor: Color(0xFF00FF00),
      );
      expect(a.hashCode, equals(b.hashCode));
    });

    test('== distinguishes aboveBaselineFillColor values', () {
      const a = AreaChartSeries(
        id: 'a', points: [], aboveBaselineFillColor: Color(0xFF00FF00),
      );
      const b = AreaChartSeries(
        id: 'a', points: [], aboveBaselineFillColor: Color(0xFF0000FF),
      );
      expect(a, isNot(equals(b)));
    });

    test('== distinguishes belowBaselineFillColor values', () {
      const a = AreaChartSeries(
        id: 'a', points: [], belowBaselineFillColor: Color(0xFFFF0000),
      );
      const b = AreaChartSeries(
        id: 'a', points: [], belowBaselineFillColor: Color(0xFF0000FF),
      );
      expect(a, isNot(equals(b)));
    });
  });
}
```

### Step 2: Run tests to verify they fail

- [ ] Run:
```
flutter test test/unit/models/area_chart_series_baseline_test.dart
```
Expected: compilation error — `baselineValue`, `aboveBaselineFillColor`, `belowBaselineFillColor` not defined on `AreaChartSeries`.

### Step 3: Add the three fields to `AreaChartSeries`

- [ ] In `lib/src/models/chart_series.dart`, update the `AreaChartSeries` constructor (lines 463-484) — add three new optional parameters after `inlineLabel`:

```dart
  const AreaChartSeries({
    required super.id,
    super.name,
    required super.points,
    super.color,
    super.isXOrdered = false,
    super.metadata,
    super.yAxisId,
    super.yAxisConfig,
    super.unit,
    this.interpolation = LineInterpolation.linear,
    this.strokeWidth = 2.0,
    this.tension = 0.25,
    this.fillOpacity = 0.3,
    this.showDataPointMarkers = false,
    this.dataPointMarkerRadius = 3.0,
    this.dataPointMarkerStyle = DataPointMarkerStyle.filled,
    this.dataPointMarkerBackground = Colors.white,
    this.lineGlow = 0.0,
    this.dataPointLabels,
    this.inlineLabel,
    this.baselineValue,
    this.aboveBaselineFillColor,
    this.belowBaselineFillColor,
  });
```

- [ ] Add the three field declarations after `inlineLabel` (line 498):

```dart
  final DataPointLabelConfig? dataPointLabels;
  final SeriesInlineLabelConfig? inlineLabel;
  final double? baselineValue;
  final Color? aboveBaselineFillColor;
  final Color? belowBaselineFillColor;
```

### Step 4: Update `copyWith`

- [ ] Add the three parameters to the `copyWith` signature (after `inlineLabel`):

```dart
  @override
  AreaChartSeries copyWith({
    String? id,
    String? name,
    List<ChartDataPoint>? points,
    Color? color,
    SeriesStyle? style,
    bool? isXOrdered,
    Map<String, dynamic>? metadata,
    List<ChartAnnotation>? annotations,
    String? yAxisId,
    YAxisConfig? yAxisConfig,
    String? unit,
    LineInterpolation? interpolation,
    double? strokeWidth,
    double? tension,
    double? fillOpacity,
    bool? showDataPointMarkers,
    double? dataPointMarkerRadius,
    DataPointMarkerStyle? dataPointMarkerStyle,
    Color? dataPointMarkerBackground,
    double? lineGlow,
    DataPointLabelConfig? dataPointLabels,
    SeriesInlineLabelConfig? inlineLabel,
    double? baselineValue,
    Color? aboveBaselineFillColor,
    Color? belowBaselineFillColor,
  }) {
    return AreaChartSeries(
      id: id ?? this.id,
      name: name ?? this.name,
      points: points ?? this.points,
      color: color ?? this.color,
      isXOrdered: isXOrdered ?? this.isXOrdered,
      metadata: metadata ?? this.metadata,
      yAxisId: yAxisId ?? this.yAxisId,
      yAxisConfig: yAxisConfig ?? this.yAxisConfig,
      unit: unit ?? this.unit,
      interpolation: interpolation ?? this.interpolation,
      strokeWidth: strokeWidth ?? this.strokeWidth,
      tension: tension ?? this.tension,
      fillOpacity: fillOpacity ?? this.fillOpacity,
      showDataPointMarkers: showDataPointMarkers ?? this.showDataPointMarkers,
      dataPointMarkerRadius:
          dataPointMarkerRadius ?? this.dataPointMarkerRadius,
      dataPointMarkerStyle:
          dataPointMarkerStyle ?? this.dataPointMarkerStyle,
      dataPointMarkerBackground:
          dataPointMarkerBackground ?? this.dataPointMarkerBackground,
      lineGlow: lineGlow ?? this.lineGlow,
      dataPointLabels: dataPointLabels ?? this.dataPointLabels,
      inlineLabel: inlineLabel ?? this.inlineLabel,
      baselineValue: baselineValue ?? this.baselineValue,
      aboveBaselineFillColor:
          aboveBaselineFillColor ?? this.aboveBaselineFillColor,
      belowBaselineFillColor:
          belowBaselineFillColor ?? this.belowBaselineFillColor,
    );
  }
```

### Step 5: Update `toString`

- [ ] Replace the `toString` override:

```dart
  @override
  String toString() =>
      'AreaChartSeries(id: $id, points: ${points.length}, interpolation: $interpolation, baselineValue: $baselineValue)';
```

### Step 6: Update `==`

- [ ] Add three new field comparisons to the `==` operator (after `other.inlineLabel == inlineLabel`):

```dart
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! AreaChartSeries) return false;
    return super == other &&
        other.interpolation == interpolation &&
        other.strokeWidth == strokeWidth &&
        other.tension == tension &&
        other.fillOpacity == fillOpacity &&
        other.showDataPointMarkers == showDataPointMarkers &&
        other.dataPointMarkerRadius == dataPointMarkerRadius &&
        other.dataPointMarkerStyle == dataPointMarkerStyle &&
        other.dataPointMarkerBackground == dataPointMarkerBackground &&
        other.lineGlow == lineGlow &&
        other.dataPointLabels == dataPointLabels &&
        other.inlineLabel == inlineLabel &&
        other.baselineValue == baselineValue &&
        other.aboveBaselineFillColor == aboveBaselineFillColor &&
        other.belowBaselineFillColor == belowBaselineFillColor;
  }
```

### Step 7: Update `hashCode`

- [ ] Add the three fields to `Object.hashAll`:

```dart
  @override
  int get hashCode => Object.hashAll([
        super.hashCode,
        interpolation,
        strokeWidth,
        tension,
        fillOpacity,
        showDataPointMarkers,
        dataPointMarkerRadius,
        dataPointMarkerStyle,
        dataPointMarkerBackground,
        lineGlow,
        dataPointLabels,
        inlineLabel,
        baselineValue,
        aboveBaselineFillColor,
        belowBaselineFillColor,
      ]);
```

### Step 8: Run tests

- [ ] Run:
```
flutter test test/unit/models/area_chart_series_baseline_test.dart
```
Expected: all 14 tests pass.

### Step 9: Run full suite to confirm no regressions

- [ ] Run:
```
flutter test
```
Expected: all tests pass.

### Step 10: Commit

- [ ] Run:
```
git add lib/src/models/chart_series.dart test/unit/models/area_chart_series_baseline_test.dart
git commit -m "feat: add baselineValue/aboveBaselineFillColor/belowBaselineFillColor to AreaChartSeries"
```

---

## Task 2: Rendering — polygon-split baseline fill

**Files:**
- Modify: `lib/src/elements/series_element.dart:823-884`

### Background — coordinate system

Flutter plot space has Y increasing **downward**. So:
- `dy < baselineY` → the point is **above** the baseline (higher on screen)
- `dy > baselineY` → the point is **below** the baseline

The baseline Y in plot space is obtained from `_currentTransform.dataToPlot(0, series.baselineValue!).dy`. The X argument (0) doesn't affect the Y result since Y mapping is independent.

### Step 1: Write a test

There is no lightweight unit-test path for the canvas rendering, so this task is verified by running the showcase demo (see Step 5). Skip to Step 2.

### Step 2: Add `_paintAreaSeriesBaseline` to `series_element.dart`

- [ ] Insert the following method directly after `_paintAreaSeriesMultiColor` (after line 1012, before `_buildAreaRegionFillPath`):

```dart
  /// Paints an area series filled relative to a fixed [AreaChartSeries.baselineValue].
  ///
  /// Walks consecutive point pairs in plot space. When a pair crosses the
  /// baseline, the exact intersection is computed via linear interpolation and
  /// the segment is closed at that point. Each resulting polygon is painted with
  /// [AreaChartSeries.aboveBaselineFillColor] (region above the baseline) or
  /// [AreaChartSeries.belowBaselineFillColor] (region below), falling back to
  /// the series colour at [AreaChartSeries.fillOpacity] when the colour is null.
  ///
  /// The series stroke is drawn on top, identical to the single-colour path.
  /// Crossing detection uses linear interpolation between consecutive data
  /// points regardless of the chosen [LineInterpolation] mode.
  void _paintAreaSeriesBaseline(
    Canvas canvas,
    AreaChartSeries series,
    List<Offset> transformedPoints,
    Color baseColor,
    double opacity,
    double strokeWidth,
  ) {
    final baselineY =
        _currentTransform.dataToPlot(0, series.baselineValue!).dy;

    final aboveColor = series.aboveBaselineFillColor ??
        baseColor.withValues(alpha: series.fillOpacity);
    final belowColor = series.belowBaselineFillColor ??
        baseColor.withValues(alpha: series.fillOpacity);

    // Split points into contiguous above/below segments.
    // A "segment" is a list of Offsets whose first and last points lie on
    // the baseline (either as crossing intersections or original endpoints).
    final segments = <({List<Offset> points, bool isAbove})>[];
    var currentPoints = <Offset>[transformedPoints.first];
    // dy < baselineY means above (smaller Y = higher on screen).
    var currentAbove = transformedPoints.first.dy < baselineY;

    for (var i = 1; i < transformedPoints.length; i++) {
      final p1 = transformedPoints[i - 1];
      final p2 = transformedPoints[i];
      final p2Above = p2.dy < baselineY;

      if (currentAbove != p2Above) {
        // Linear interpolation to find the crossing X.
        final t = (baselineY - p1.dy) / (p2.dy - p1.dy);
        final crossing = Offset(p1.dx + t * (p2.dx - p1.dx), baselineY);
        currentPoints.add(crossing);
        segments.add((points: List.of(currentPoints), isAbove: currentAbove));
        currentPoints = [crossing, p2];
        currentAbove = p2Above;
      } else {
        currentPoints.add(p2);
      }
    }
    // Flush final segment.
    segments.add((points: List.of(currentPoints), isAbove: currentAbove));

    // Paint each segment as a closed fill polygon.
    for (final seg in segments) {
      if (seg.points.length < 2) continue;
      final first = seg.points.first;
      final last = seg.points.last;

      final path = Path();
      // Start at baseline directly below/above the first point.
      path.moveTo(first.dx, baselineY);
      // Move to the first series point (zero-length line when first is a crossing).
      path.lineTo(first.dx, first.dy);
      // Draw the interpolated curve through the segment.
      InterpolationGeometry.addPathSegments<Offset>(
        path: path,
        points: seg.points,
        interpolation: series.interpolation,
        getX: (p) => p.dx,
        getY: (p) => p.dy,
        startIndex: 1,
        endIndex: seg.points.length - 1,
        tension: series.tension,
      );
      // Close back to baseline.
      path.lineTo(last.dx, baselineY);
      path.close();

      canvas.drawPath(
        path,
        Paint()
          ..color = seg.isAbove ? aboveColor : belowColor
          ..style = PaintingStyle.fill,
      );
    }

    // Draw the series stroke on top (identical to single-colour path).
    final linePaint = Paint()
      ..color = baseColor.withValues(alpha: opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final linePath = Path()
      ..moveTo(transformedPoints.first.dx, transformedPoints.first.dy);
    InterpolationGeometry.addPathSegments<Offset>(
      path: linePath,
      points: transformedPoints,
      interpolation: series.interpolation,
      getX: (p) => p.dx,
      getY: (p) => p.dy,
      tension: series.tension,
    );

    if (series.lineGlow > 0) {
      canvas.drawPath(
        linePath,
        Paint()
          ..color = baseColor.withAlpha(60)
          ..strokeWidth = strokeWidth + series.lineGlow * 2
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, series.lineGlow),
      );
    }
    canvas.drawPath(linePath, linePaint);
  }
```

### Step 3: Wire the new method into `_paintAreaSeries`

- [ ] In `_paintAreaSeries` (lines 847-866), replace the existing `if (!hasOverrides)` block with a three-way branch — baseline mode takes priority over single/multi-colour:

```dart
    if (series.baselineValue != null) {
      _paintAreaSeriesBaseline(
        canvas,
        series,
        transformedPoints,
        baseColor,
        opacity,
        effectiveStrokeWidth,
      );
    } else if (!hasOverrides) {
      // FAST PATH: Single color for both fill and stroke
      _paintAreaSeriesSingleColor(
        canvas,
        series,
        transformedPoints,
        baseColor,
        opacity,
        effectiveStrokeWidth,
      );
    } else {
      // STYLED PATH: Multi-color fill and stroke
      _paintAreaSeriesMultiColor(
        canvas,
        series,
        transformedPoints,
        baseColor,
        opacity,
        effectiveStrokeWidth,
      );
    }
```

The data-point-markers and inline-label blocks that follow this `if/else` (lines 869-883) remain **unchanged** — they always run after the fill/stroke branch.

### Step 4: Verify the app compiles

- [ ] Run:
```
flutter analyze lib/
```
Expected: no errors.

### Step 5: Verify visually in the showcase

- [ ] Add a temporary `AreaChartSeries` with `baselineValue` to the axis slot demo page (or any existing showcase page) and run the example app:

```dart
// Paste into axis_slot_demo_page.dart or any showcase page that has an AreaChartSeries
AreaChartSeries(
  id: 'power',
  points: [
    ChartDataPoint(x: 0, y: 80),
    ChartDataPoint(x: 1, y: 150),
    ChartDataPoint(x: 2, y: 120),
    ChartDataPoint(x: 3, y: 100),
    ChartDataPoint(x: 4, y: 160),
    ChartDataPoint(x: 5, y: 90),
    ChartDataPoint(x: 6, y: 110),
  ],
  baselineValue: 120.0,
  aboveBaselineFillColor: Colors.green.withOpacity(0.35),
  belowBaselineFillColor: Colors.red.withOpacity(0.35),
),
```

Expected:
- Green fill above y=120, red fill below y=120
- Fill correctly splits at the exact crossing points — no colour bleed across the baseline
- Series stroke line drawn on top, unaffected
- Removing `baselineValue` restores the original bottom-fill behaviour

- [ ] Remove the temporary code after confirming visually.

### Step 6: Run full test suite

- [ ] Run:
```
flutter test
```
Expected: all tests pass.

### Step 7: Commit

- [ ] Run:
```
git add lib/src/elements/series_element.dart
git commit -m "feat: render AreaChartSeries fill relative to baselineValue with per-side colours"
```
