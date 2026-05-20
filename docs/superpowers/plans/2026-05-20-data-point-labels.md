# DataPointLabelConfig Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add opt-in text labels to data point markers on `LineChartSeries` and `AreaChartSeries`, showing Y-values with configurable position, style, and formatting.

**Architecture:** A new immutable `DataPointLabelConfig` class and `DataPointLabelPosition` enum live in the models layer. `LineChartSeries`/`AreaChartSeries` get a nullable `dataPointLabels` field. All rendering happens inside the existing `_paintDataPointMarkers()` loop in `SeriesElement` — no extra data pass. A `Map<String, TextPainter>` cache on `SeriesElement` avoids re-layout on every frame.

**Tech Stack:** Flutter/Dart, `dart:ui` for painting primitives, `package:flutter/painting.dart` for `TextPainter`/`TextStyle`/`TextSpan`.

---

## File Structure

| File | Action | Responsibility |
|------|--------|----------------|
| `lib/src/models/data_point_label_config.dart` | **CREATE** | `DataPointLabelConfig` class + `DataPointLabelPosition` enum + `_autoFormatLabelValue()` static helper |
| `lib/src/models/chart_series.dart` | **MODIFY** | Add `dataPointLabels: DataPointLabelConfig?` to `LineChartSeries` and `AreaChartSeries` |
| `lib/src/elements/series_element.dart` | **MODIFY** | TextPainter cache, `_paintDataPointLabel()` method, call from `_paintDataPointMarkers()` |
| `lib/braven_charts.dart` | **MODIFY** | Export `DataPointLabelConfig` and `DataPointLabelPosition` |
| `example/lib/showcase/pages/data_point_labels_page.dart` | **CREATE** | Showcase page with live controls |
| `example/lib/showcase/showcase_app.dart` | **MODIFY** | Wire in new showcase page |
| `test/unit/models/data_point_label_config_test.dart` | **CREATE** | Unit tests for model + formatter |

---

## Task 1: Create `DataPointLabelConfig` model

**Files:**
- Create: `lib/src/models/data_point_label_config.dart`
- Create: `test/unit/models/data_point_label_config_test.dart`

- [ ] **Step 1: Write the failing test**

Create `test/unit/models/data_point_label_config_test.dart`:

```dart
library;

import 'package:braven_charts/src/models/data_point_label_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DataPointLabelPosition', () {
    test('has four values', () {
      expect(DataPointLabelPosition.values.length, 4);
      expect(DataPointLabelPosition.values, containsAll([
        DataPointLabelPosition.above,
        DataPointLabelPosition.below,
        DataPointLabelPosition.left,
        DataPointLabelPosition.right,
      ]));
    });
  });

  group('DataPointLabelConfig', () {
    group('defaults', () {
      test('show is false', () {
        const config = DataPointLabelConfig();
        expect(config.show, isFalse);
      });
      test('position is above', () {
        const config = DataPointLabelConfig();
        expect(config.position, DataPointLabelPosition.above);
      });
      test('offsets are zero', () {
        const config = DataPointLabelConfig();
        expect(config.offsetX, 0.0);
        expect(config.offsetY, 0.0);
      });
      test('labelColor is null (inherits series color)', () {
        const config = DataPointLabelConfig();
        expect(config.labelColor, isNull);
      });
      test('fontSize is 10.0', () {
        const config = DataPointLabelConfig();
        expect(config.fontSize, 10.0);
      });
      test('fontWeight is w600', () {
        const config = DataPointLabelConfig();
        expect(config.fontWeight, FontWeight.w600);
      });
      test('showUnit is false', () {
        const config = DataPointLabelConfig();
        expect(config.showUnit, isFalse);
      });
      test('formatter is null', () {
        const config = DataPointLabelConfig();
        expect(config.formatter, isNull);
      });
      test('background is null', () {
        const config = DataPointLabelConfig();
        expect(config.background, isNull);
      });
      test('backgroundOpacity is 0.85', () {
        const config = DataPointLabelConfig();
        expect(config.backgroundOpacity, 0.85);
      });
    });

    group('copyWith', () {
      test('copies all fields when nothing overridden', () {
        const original = DataPointLabelConfig(
          show: true,
          position: DataPointLabelPosition.right,
          offsetX: 2.0,
          offsetY: -1.0,
          labelColor: Colors.red,
          fontSize: 12.0,
          fontWeight: FontWeight.bold,
          showUnit: true,
          background: Colors.white,
          backgroundOpacity: 0.9,
        );
        final copy = original.copyWith();
        expect(copy.show, isTrue);
        expect(copy.position, DataPointLabelPosition.right);
        expect(copy.offsetX, 2.0);
        expect(copy.offsetY, -1.0);
        expect(copy.labelColor, Colors.red);
        expect(copy.fontSize, 12.0);
        expect(copy.fontWeight, FontWeight.bold);
        expect(copy.showUnit, isTrue);
        expect(copy.background, Colors.white);
        expect(copy.backgroundOpacity, 0.9);
      });

      test('overrides specific fields', () {
        const original = DataPointLabelConfig(show: false);
        final copy = original.copyWith(show: true, fontSize: 14.0);
        expect(copy.show, isTrue);
        expect(copy.fontSize, 14.0);
        expect(copy.position, DataPointLabelPosition.above); // unchanged
      });
    });

    group('equality', () {
      test('equal instances are equal', () {
        const a = DataPointLabelConfig(show: true, fontSize: 12.0);
        const b = DataPointLabelConfig(show: true, fontSize: 12.0);
        expect(a, equals(b));
        expect(a.hashCode, equals(b.hashCode));
      });

      test('different show values are not equal', () {
        const a = DataPointLabelConfig(show: true);
        const b = DataPointLabelConfig(show: false);
        expect(a, isNot(equals(b)));
      });
    });

    group('autoFormatLabelValue', () {
      test('formats whole number as integer', () {
        expect(DataPointLabelConfig.autoFormatLabelValue(5.0, null), '5');
        expect(DataPointLabelConfig.autoFormatLabelValue(100.0, null), '100');
        expect(DataPointLabelConfig.autoFormatLabelValue(-5.0, null), '-5');
      });
      test('formats |y| < 1 with 2 decimal places', () {
        expect(DataPointLabelConfig.autoFormatLabelValue(0.123, null), '0.12');
        expect(DataPointLabelConfig.autoFormatLabelValue(-0.75, null), '-0.75');
      });
      test('formats 1 <= |y| < 100 with 1 decimal place', () {
        expect(DataPointLabelConfig.autoFormatLabelValue(12.56, null), '12.6');
        expect(DataPointLabelConfig.autoFormatLabelValue(99.94, null), '99.9');
      });
      test('formats |y| >= 100 non-integer as integer', () {
        expect(DataPointLabelConfig.autoFormatLabelValue(150.7, null), '151');
      });
      test('appends unit when provided', () {
        expect(DataPointLabelConfig.autoFormatLabelValue(5.0, 'W'), '5 W');
        expect(DataPointLabelConfig.autoFormatLabelValue(12.3, 'bpm'), '12.3 bpm');
      });
      test('no unit when unit is empty string', () {
        expect(DataPointLabelConfig.autoFormatLabelValue(5.0, ''), '5');
      });
    });
  });
}
```

- [ ] **Step 2: Run test — expect compile error (file doesn't exist yet)**

```
flutter test test/unit/models/data_point_label_config_test.dart
```

Expected: Error — `data_point_label_config.dart` not found.

- [ ] **Step 3: Create `lib/src/models/data_point_label_config.dart`**

```dart
// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

import 'dart:ui' show Color;

import 'package:flutter/painting.dart' show FontWeight;

import 'chart_data_point.dart';

/// Position of a data-point label relative to its marker.
enum DataPointLabelPosition { above, below, left, right }

/// Configuration for optional text labels rendered next to data point markers.
///
/// Attach to [LineChartSeries.dataPointLabels] or [AreaChartSeries.dataPointLabels].
/// Labels are hidden by default — set [show] to true to enable.
///
/// Example:
/// ```dart
/// LineChartSeries(
///   id: 'power',
///   showDataPointMarkers: true,
///   dataPointLabels: DataPointLabelConfig(
///     show: true,
///     position: DataPointLabelPosition.above,
///     showUnit: true,
///   ),
/// )
/// ```
class DataPointLabelConfig {
  const DataPointLabelConfig({
    this.show = false,
    this.position = DataPointLabelPosition.above,
    this.offsetX = 0.0,
    this.offsetY = 0.0,
    this.labelColor,
    this.fontSize = 10.0,
    this.fontWeight = FontWeight.w600,
    this.showUnit = false,
    this.formatter,
    this.background,
    this.backgroundOpacity = 0.85,
  });

  /// Whether to render labels. Default false — zero-cost when false.
  final bool show;

  /// Where to place the label relative to the marker centre.
  final DataPointLabelPosition position;

  /// Extra horizontal pixel nudge applied after [position] is calculated.
  final double offsetX;

  /// Extra vertical pixel nudge applied after [position] is calculated.
  final double offsetY;

  /// Label text color. Null inherits the series color.
  final Color? labelColor;

  /// Font size in logical pixels. Default 10.
  final double fontSize;

  /// Font weight. Default [FontWeight.w600].
  final FontWeight fontWeight;

  /// When true, appends the series unit (e.g. "178 W" instead of "178").
  final bool showUnit;

  /// Custom formatter. When set, overrides all auto-format logic.
  /// Receives the full [ChartDataPoint] so callers can use `point.label`.
  final String Function(ChartDataPoint)? formatter;

  /// Background pill color. Null → plain text with no background.
  final Color? background;

  /// Opacity applied to [background]. Range 0–1. Default 0.85.
  final double backgroundOpacity;

  /// Formats [y] using the spec rules.  
  /// - Whole number → no decimal places  
  /// - |y| < 1 → 2 decimal places  
  /// - 1 ≤ |y| < 100 → 1 decimal place  
  /// - |y| ≥ 100 → 0 decimal places (rounded)
  static String autoFormatLabelValue(double y, String? unit) {
    final String numStr;
    if (y == y.roundToDouble()) {
      numStr = y.toStringAsFixed(0);
    } else if (y.abs() < 1.0) {
      numStr = y.toStringAsFixed(2);
    } else if (y.abs() < 100.0) {
      numStr = y.toStringAsFixed(1);
    } else {
      numStr = y.toStringAsFixed(0);
    }
    if (unit != null && unit.isNotEmpty) return '$numStr $unit';
    return numStr;
  }

  DataPointLabelConfig copyWith({
    bool? show,
    DataPointLabelPosition? position,
    double? offsetX,
    double? offsetY,
    Color? labelColor,
    double? fontSize,
    FontWeight? fontWeight,
    bool? showUnit,
    String Function(ChartDataPoint)? formatter,
    Color? background,
    double? backgroundOpacity,
  }) {
    return DataPointLabelConfig(
      show: show ?? this.show,
      position: position ?? this.position,
      offsetX: offsetX ?? this.offsetX,
      offsetY: offsetY ?? this.offsetY,
      labelColor: labelColor ?? this.labelColor,
      fontSize: fontSize ?? this.fontSize,
      fontWeight: fontWeight ?? this.fontWeight,
      showUnit: showUnit ?? this.showUnit,
      formatter: formatter ?? this.formatter,
      background: background ?? this.background,
      backgroundOpacity: backgroundOpacity ?? this.backgroundOpacity,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DataPointLabelConfig &&
        other.show == show &&
        other.position == position &&
        other.offsetX == offsetX &&
        other.offsetY == offsetY &&
        other.labelColor == labelColor &&
        other.fontSize == fontSize &&
        other.fontWeight == fontWeight &&
        other.showUnit == showUnit &&
        other.formatter == formatter &&
        other.background == background &&
        other.backgroundOpacity == backgroundOpacity;
  }

  @override
  int get hashCode => Object.hash(
        show,
        position,
        offsetX,
        offsetY,
        labelColor,
        fontSize,
        fontWeight,
        showUnit,
        formatter,
        background,
        backgroundOpacity,
      );

  @override
  String toString() =>
      'DataPointLabelConfig(show: $show, position: $position, '
      'fontSize: $fontSize, showUnit: $showUnit)';
}
```

- [ ] **Step 4: Run tests — expect PASS**

```
flutter test test/unit/models/data_point_label_config_test.dart
```

Expected: All tests pass.

- [ ] **Step 5: Commit**

```
git add lib/src/models/data_point_label_config.dart test/unit/models/data_point_label_config_test.dart
git commit -m "feat: add DataPointLabelConfig model and DataPointLabelPosition enum"
```

---

## Task 2: Add `dataPointLabels` to `LineChartSeries` and `AreaChartSeries`

**Files:**
- Modify: `lib/src/models/chart_series.dart`
- Modify: `test/unit/models/data_point_label_config_test.dart` (add series integration test)

- [ ] **Step 1: Write failing test — add to `data_point_label_config_test.dart`**

Append a new group at the bottom of `main()`:

```dart
  group('LineChartSeries.dataPointLabels', () {
    test('defaults to null', () {
      final s = LineChartSeries(
        id: 'test',
        points: const [ChartDataPoint(x: 1, y: 1)],
      );
      expect(s.dataPointLabels, isNull);
    });

    test('can be set', () {
      final s = LineChartSeries(
        id: 'test',
        points: const [ChartDataPoint(x: 1, y: 1)],
        dataPointLabels: const DataPointLabelConfig(show: true),
      );
      expect(s.dataPointLabels, isNotNull);
      expect(s.dataPointLabels!.show, isTrue);
    });

    test('copyWith preserves dataPointLabels when not overridden', () {
      final s = LineChartSeries(
        id: 'test',
        points: const [ChartDataPoint(x: 1, y: 1)],
        dataPointLabels: const DataPointLabelConfig(show: true),
      );
      final copy = s.copyWith(id: 'test2');
      expect(copy.dataPointLabels, isNotNull);
      expect(copy.dataPointLabels!.show, isTrue);
    });

    test('copyWith can override dataPointLabels', () {
      final s = LineChartSeries(
        id: 'test',
        points: const [ChartDataPoint(x: 1, y: 1)],
        dataPointLabels: const DataPointLabelConfig(show: false),
      );
      final copy = s.copyWith(
        dataPointLabels: const DataPointLabelConfig(show: true),
      );
      expect(copy.dataPointLabels!.show, isTrue);
    });
  });

  group('AreaChartSeries.dataPointLabels', () {
    test('defaults to null', () {
      final s = AreaChartSeries(
        id: 'test',
        points: const [ChartDataPoint(x: 1, y: 1)],
      );
      expect(s.dataPointLabels, isNull);
    });

    test('can be set and copyWith preserves it', () {
      final s = AreaChartSeries(
        id: 'test',
        points: const [ChartDataPoint(x: 1, y: 1)],
        dataPointLabels: const DataPointLabelConfig(show: true, fontSize: 12),
      );
      final copy = s.copyWith();
      expect(copy.dataPointLabels!.fontSize, 12.0);
    });
  });
```

Also add the missing imports at the top of the test file:

```dart
import 'package:braven_charts/src/models/chart_data_point.dart';
import 'package:braven_charts/src/models/chart_series.dart';
```

- [ ] **Step 2: Run — expect failure**

```
flutter test test/unit/models/data_point_label_config_test.dart
```

Expected: Compile error — `LineChartSeries` has no `dataPointLabels` parameter.

- [ ] **Step 3: Add `dataPointLabels` to `LineChartSeries` in `chart_series.dart`**

In the `LineChartSeries` class (`lib/src/models/chart_series.dart`):

Add to constructor parameter list after `dataPointMarkerRadius`:
```dart
    this.dataPointLabels,
```

Add field declaration after `dataPointMarkerRadius`:
```dart
  final DataPointLabelConfig? dataPointLabels;
```

Add `dataPointLabels` import at top of file (after existing imports):
```dart
import 'data_point_label_config.dart';
```

Update `LineChartSeries.copyWith` — add parameter:
```dart
    DataPointLabelConfig? dataPointLabels,
```

Update `LineChartSeries.copyWith` body — add to constructor call:
```dart
      dataPointLabels: dataPointLabels ?? this.dataPointLabels,
```

Update `LineChartSeries` constructor in `copyWith` return — the full updated `copyWith` return body should be:
```dart
    return LineChartSeries(
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
      showDataPointMarkers: showDataPointMarkers ?? this.showDataPointMarkers,
      dataPointMarkerRadius: dataPointMarkerRadius ?? this.dataPointMarkerRadius,
      dataPointLabels: dataPointLabels ?? this.dataPointLabels,
    );
```

Note: `LineChartSeries` does not override `==` or `hashCode` (it inherits `ChartSeries` versions which don't include subclass fields). No change needed there — this is consistent with existing `strokeWidth`, `interpolation`, etc. fields.

- [ ] **Step 4: Add `dataPointLabels` to `AreaChartSeries` in `chart_series.dart`**

Same pattern as above. In `AreaChartSeries`:

Add to constructor after `dataPointMarkerRadius`:
```dart
    this.dataPointLabels,
```

Add field declaration after `dataPointMarkerRadius`:
```dart
  final DataPointLabelConfig? dataPointLabels;
```

Update `AreaChartSeries.copyWith` parameter list — add:
```dart
    DataPointLabelConfig? dataPointLabels,
```

Update `AreaChartSeries.copyWith` return body — add:
```dart
      dataPointLabels: dataPointLabels ?? this.dataPointLabels,
```

Full updated return:
```dart
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
      dataPointMarkerRadius: dataPointMarkerRadius ?? this.dataPointMarkerRadius,
      dataPointLabels: dataPointLabels ?? this.dataPointLabels,
    );
```

- [ ] **Step 5: Run tests — expect PASS**

```
flutter test test/unit/models/data_point_label_config_test.dart
```

Expected: All tests pass.

- [ ] **Step 6: Run full test suite — expect no regressions**

```
flutter test
```

Expected: All tests pass (or same failures as before this task).

- [ ] **Step 7: Commit**

```
git add lib/src/models/chart_series.dart lib/src/models/data_point_label_config.dart test/unit/models/data_point_label_config_test.dart
git commit -m "feat: add dataPointLabels field to LineChartSeries and AreaChartSeries"
```

---

## Task 3: Export from barrel

**Files:**
- Modify: `lib/braven_charts.dart`

- [ ] **Step 1: Add export to `lib/braven_charts.dart`**

In the `# Models` section (after the `export 'src/models/chart_data_point.dart';` line), add:

```dart
export 'src/models/data_point_label_config.dart';
```

- [ ] **Step 2: Verify — no `flutter analyze` issues**

```
flutter analyze lib/braven_charts.dart
```

Expected: No issues.

- [ ] **Step 3: Commit**

```
git add lib/braven_charts.dart
git commit -m "feat: export DataPointLabelConfig and DataPointLabelPosition from barrel"
```

---

## Task 4: Implement rendering in `SeriesElement`

**Files:**
- Modify: `lib/src/elements/series_element.dart`

This task adds the label painting entirely inside `_paintDataPointMarkers()`. No new test here — rendering code is covered by visual verification in Task 6 (the showcase page). The existing unit tests continue to pass.

- [ ] **Step 1: Add `package:flutter/painting.dart` import**

At the top of `lib/src/elements/series_element.dart`, after the existing `import 'dart:ui';`, add:

```dart
import 'package:flutter/painting.dart'
    show
        FontWeight,
        TextAlign,
        TextDirection,
        TextPainter,
        TextSpan,
        TextStyle;
```

Also add the import for the new model:
```dart
import '../models/data_point_label_config.dart';
```

- [ ] **Step 2: Add TextPainter cache field to `SeriesElement`**

After the existing cache fields (around line 285 — after `bool? _cachedHasSegmentOverrides;`), add:

```dart
  // TextPainter cache for data-point labels — keyed by formatted text string
  final Map<String, TextPainter> _labelPainterCache = {};
```

- [ ] **Step 3: Clear label cache in `_invalidateAllCaches()`**

In `_invalidateAllCaches()` (around line 261), add the cache clear:

```dart
  void _invalidateAllCaches() {
    _cachedPath = null;
    _cachedTransformedPoints = null;
    _cachedOriginalIndices = null;
    _cachedHasSegmentOverrides = null;
    _labelPainterCache.clear();
  }
```

Also clear the label painter cache in `updateSeries()` unconditionally (since config changes don't change point count):

```dart
  void updateSeries(ChartSeries newSeries, {bool skipBoundsComputation = true}) {
    final pointCountChanged = newSeries.points.length != series.points.length;
    series = newSeries;
    if (!skipBoundsComputation) _computeBounds();
    if (pointCountChanged) _invalidateAllCaches();
    // Always clear label cache — label config may have changed
    _labelPainterCache.clear();
  }
```

- [ ] **Step 4: Add `_paintDataPointLabel()` private method**

Add this method to `SeriesElement`, just before `_paintDataPointMarkers()` (around line 1113):

```dart
  /// Renders a single data-point label near its marker.
  ///
  /// Anchor positions per spec:
  /// - above: centre-bottom of text at (cx+offsetX, cy-r-gap+offsetY)
  /// - below: centre-top of text at (cx+offsetX, cy+r+gap+offsetY)
  /// - left:  right-centre of text at (cx-r-gap+offsetX, cy+offsetY)
  /// - right: left-centre of text at (cx+r+gap+offsetX, cy+offsetY)
  void _paintDataPointLabel(
    Canvas canvas,
    Offset markerCenter,
    double markerRadius,
    ChartDataPoint point,
    Color seriesColor,
    DataPointLabelConfig config,
    String? unit,
  ) {
    // Build label string
    final text = config.formatter != null
        ? config.formatter!(point)
        : DataPointLabelConfig.autoFormatLabelValue(
            point.y,
            config.showUnit ? unit : null,
          );

    // Get or create (and cache) the TextPainter
    final tp = _labelPainterCache.putIfAbsent(text, () {
      final painter = TextPainter(
        text: TextSpan(
          text: text,
          style: TextStyle(
            color: config.labelColor ?? seriesColor,
            fontSize: config.fontSize,
            fontWeight: config.fontWeight,
          ),
        ),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.left,
      );
      painter.layout();
      return painter;
    });

    // Calculate top-left paint position from spec anchor table
    const gap = 2.0;
    final double paintX;
    final double paintY;
    switch (config.position) {
      case DataPointLabelPosition.above:
        paintX = markerCenter.dx + config.offsetX - tp.width / 2;
        paintY = markerCenter.dy - markerRadius - gap + config.offsetY - tp.height;
        break;
      case DataPointLabelPosition.below:
        paintX = markerCenter.dx + config.offsetX - tp.width / 2;
        paintY = markerCenter.dy + markerRadius + gap + config.offsetY;
        break;
      case DataPointLabelPosition.left:
        paintX = markerCenter.dx - markerRadius - gap + config.offsetX - tp.width;
        paintY = markerCenter.dy + config.offsetY - tp.height / 2;
        break;
      case DataPointLabelPosition.right:
        paintX = markerCenter.dx + markerRadius + gap + config.offsetX;
        paintY = markerCenter.dy + config.offsetY - tp.height / 2;
        break;
    }
    final paintOrigin = Offset(paintX, paintY);

    // Draw background pill if configured
    if (config.background != null) {
      const hPad = 4.0;
      const vPad = 2.0;
      final bgRect = Rect.fromLTWH(
        paintX - hPad,
        paintY - vPad,
        tp.width + hPad * 2,
        tp.height + vPad * 2,
      );
      final rrect = RRect.fromRectAndRadius(
        bgRect,
        Radius.circular((tp.height + vPad * 2) / 2),
      );
      canvas.drawRRect(
        rrect,
        Paint()
          ..color = config.background!.withValues(alpha: config.backgroundOpacity),
      );
    }

    tp.paint(canvas, paintOrigin);
  }
```

- [ ] **Step 5: Resolve `dataPointLabels` in `_paintDataPointMarkers()` and call `_paintDataPointLabel()`**

Replace the existing `_paintDataPointMarkers()` method with this updated version:

```dart
  /// Paint markers using PRE-TRANSFORMED points (no redundant dataToPlot calls!)
  ///
  /// [originalIndices] maps each position in [transformedPoints] to its original
  /// index in [series.points]. This is required for correct hover matching when
  /// zoomed/panned (viewport culling changes visible point indices).
  void _paintDataPointMarkers(
    Canvas canvas,
    List<Offset> transformedPoints,
    List<int>? originalIndices,
    double radius,
    Color baseColor,
  ) {
    // Check if any marker in this series is hovered
    final hoveredMarker = coordinator?.hoveredMarker;
    final isThisSeriesHovered = hoveredMarker?.seriesId == series.id;

    // Resolve label config once — null means zero-cost skip
    final DataPointLabelConfig? labelConfig = switch (series) {
      LineChartSeries s => s.dataPointLabels,
      AreaChartSeries s => s.dataPointLabels,
      _ => null,
    };
    final bool paintLabels = labelConfig != null && labelConfig.show;

    // Paint setup
    final normalPaint = Paint()
      ..color = baseColor
      ..style = PaintingStyle.fill;

    final hoverPaint = Paint()
      ..color = baseColor
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = baseColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    for (int i = 0; i < transformedPoints.length; i++) {
      final plotPos = transformedPoints[i];
      // Use original index for hover comparison (handles viewport culling)
      final originalIndex = originalIndices?[i] ?? i;

      if (isThisSeriesHovered && originalIndex == hoveredMarker!.markerIndex) {
        // Paint highlighted marker (larger with border)
        canvas.drawCircle(plotPos, radius * 1.5, hoverPaint);
        canvas.drawCircle(plotPos, radius * 1.5, borderPaint);
      } else {
        // Paint normal marker
        canvas.drawCircle(plotPos, radius, normalPaint);
      }

      // Draw label after marker so it renders on top
      if (paintLabels) {
        final point = series.points[originalIndex];
        _paintDataPointLabel(
          canvas,
          plotPos,
          radius,
          point,
          baseColor,
          labelConfig,
          series.unit,
        );
      }
    }
  }
```

- [ ] **Step 6: Run analyze**

```
flutter analyze lib/src/elements/series_element.dart
```

Expected: No issues.

- [ ] **Step 7: Run full test suite**

```
flutter test
```

Expected: All tests pass.

- [ ] **Step 8: Commit**

```
git add lib/src/elements/series_element.dart
git commit -m "feat: render data-point labels in SeriesElement with TextPainter cache"
```

---

## Task 5: Create showcase page

**Files:**
- Create: `example/lib/showcase/pages/data_point_labels_page.dart`

- [ ] **Step 1: Create the file**

```dart
// Copyright 2025 Braven Charts - Data Point Labels Showcase
// SPDX-License-Identifier: MIT

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';

import '../widgets/options_panel.dart';

/// Showcase page demonstrating data-point label rendering.
class DataPointLabelsPage extends StatefulWidget {
  const DataPointLabelsPage({super.key});

  @override
  State<DataPointLabelsPage> createState() => _DataPointLabelsPageState();
}

class _DataPointLabelsPageState extends State<DataPointLabelsPage> {
  DataPointLabelPosition _position = DataPointLabelPosition.above;
  double _fontSize = 10.0;
  bool _showUnit = false;
  bool _showBackground = false;
  bool _customFormatter = false;

  static const _points = [
    ChartDataPoint(x: 0, y: 3.4),
    ChartDataPoint(x: 10, y: 7.2),
    ChartDataPoint(x: 20, y: 12.8),
    ChartDataPoint(x: 30, y: 18.5),
    ChartDataPoint(x: 40, y: 22.1),
    ChartDataPoint(x: 50, y: 16.7),
    ChartDataPoint(x: 60, y: 9.3),
  ];

  static const _hrPoints = [
    ChartDataPoint(x: 0, y: 128),
    ChartDataPoint(x: 10, y: 145),
    ChartDataPoint(x: 20, y: 158),
    ChartDataPoint(x: 30, y: 171),
    ChartDataPoint(x: 40, y: 164),
    ChartDataPoint(x: 50, y: 152),
    ChartDataPoint(x: 60, y: 138),
  ];

  DataPointLabelConfig _buildConfig() => DataPointLabelConfig(
        show: true,
        position: _position,
        fontSize: _fontSize,
        showUnit: _showUnit,
        formatter: _customFormatter
            ? (p) => '${p.y.toStringAsFixed(1)}!'
            : null,
        background: _showBackground ? Colors.white : null,
        backgroundOpacity: 0.88,
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Data Point Labels')),
      body: Row(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Chart 1 — live controls chart
                _ChartCard(
                  title: 'Configurable Labels',
                  subtitle: 'Position, font size, unit and background all live',
                  child: BravenChartPlus(
                    series: [
                      LineChartSeries(
                        id: 'lactate',
                        name: 'Lactate',
                        points: _points,
                        color: const Color(0xFF6366F1),
                        strokeWidth: 2.0,
                        showDataPointMarkers: true,
                        dataPointMarkerRadius: 4.0,
                        unit: 'mmol/L',
                        dataPointLabels: _buildConfig(),
                      ),
                    ],
                    xAxisConfig: const XAxisConfig(
                      label: 'Time (min)',
                      min: -5,
                      max: 65,
                    ),
                    yAxis: YAxisConfig(
                      label: 'Lactate',
                      unit: 'mmol/L',
                      min: 0,
                      max: 28,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Chart 2 — custom formatter on integer values
                _ChartCard(
                  title: 'Integer Values + Background Pill',
                  subtitle: 'HR series — values format as integers, white pill',
                  child: BravenChartPlus(
                    series: [
                      LineChartSeries(
                        id: 'hr',
                        name: 'Heart Rate',
                        points: _hrPoints,
                        color: const Color(0xFFEF4444),
                        strokeWidth: 2.0,
                        showDataPointMarkers: true,
                        dataPointMarkerRadius: 4.0,
                        unit: 'bpm',
                        dataPointLabels: const DataPointLabelConfig(
                          show: true,
                          position: DataPointLabelPosition.above,
                          showUnit: true,
                          background: Colors.white,
                          backgroundOpacity: 0.9,
                          fontSize: 9.0,
                        ),
                      ),
                    ],
                    xAxisConfig: const XAxisConfig(
                      label: 'Time (min)',
                      min: -5,
                      max: 65,
                    ),
                    yAxis: YAxisConfig(
                      label: 'HR',
                      unit: 'bpm',
                      min: 100,
                      max: 200,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Chart 3 — area series
                _ChartCard(
                  title: 'Area Series Labels',
                  subtitle: 'Labels on AreaChartSeries, position: below',
                  child: BravenChartPlus(
                    series: [
                      AreaChartSeries(
                        id: 'fat',
                        name: 'Fat Oxidation',
                        points: _points,
                        color: const Color(0xFF10B981),
                        strokeWidth: 2.0,
                        fillOpacity: 0.18,
                        showDataPointMarkers: true,
                        dataPointMarkerRadius: 4.0,
                        unit: 'g/min',
                        dataPointLabels: const DataPointLabelConfig(
                          show: true,
                          position: DataPointLabelPosition.below,
                          labelColor: Color(0xFF065F46),
                          fontSize: 9.5,
                        ),
                      ),
                    ],
                    xAxisConfig: const XAxisConfig(
                      label: 'Intensity',
                      min: -5,
                      max: 65,
                    ),
                    yAxis: YAxisConfig(
                      label: 'g/min',
                      min: 0,
                      max: 30,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Options panel
          SizedBox(
            width: 260,
            child: OptionsPanel(
              title: 'Label Options',
              children: [
                OptionSection(
                  title: 'Chart 1 Controls',
                  icon: Icons.tune,
                  children: [
                    EnumOption<DataPointLabelPosition>(
                      label: 'Position',
                      value: _position,
                      values: DataPointLabelPosition.values,
                      labelBuilder: (p) => p.name,
                      onChanged: (v) => setState(() => _position = v),
                    ),
                    SliderOption(
                      label: 'Font Size',
                      value: _fontSize,
                      min: 7.0,
                      max: 16.0,
                      divisions: 9,
                      suffix: 'px',
                      decimalPlaces: 0,
                      onChanged: (v) => setState(() => _fontSize = v),
                    ),
                    BoolOption(
                      label: 'Show Unit',
                      value: _showUnit,
                      onChanged: (v) => setState(() => _showUnit = v),
                    ),
                    BoolOption(
                      label: 'Background Pill',
                      value: _showBackground,
                      onChanged: (v) => setState(() => _showBackground = v),
                    ),
                    BoolOption(
                      label: 'Custom Formatter',
                      subtitle: 'y.toStringAsFixed(1) + "!"',
                      value: _customFormatter,
                      onChanged: (v) => setState(() => _customFormatter = v),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: theme.textTheme.titleMedium),
            const SizedBox(height: 2),
            Text(subtitle,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.outline)),
            const SizedBox(height: 12),
            SizedBox(height: 220, child: child),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Commit**

```
git add example/lib/showcase/pages/data_point_labels_page.dart
git commit -m "feat: add DataPointLabelsPage showcase"
```

---

## Task 6: Wire showcase page into navigation

**Files:**
- Modify: `example/lib/showcase/showcase_app.dart`

- [ ] **Step 1: Add import to `showcase_app.dart`**

After the existing `import 'pages/axis_render_range_page.dart';` line, add:

```dart
import 'pages/data_point_labels_page.dart';
```

- [ ] **Step 2: Add `NavDestination` entry**

In the `_destinations` list in `_ShowcaseHomeState`, after the Render Range entry (or after Lactate Threshold — near related features), add:

```dart
    const NavDestination(
      label: 'Point Labels',
      icon: Icons.label_outline,
      selectedIcon: Icons.label,
      page: DataPointLabelsPage(),
      badge: 'NEW',
    ),
```

- [ ] **Step 3: Hot-reload and visual verify**

Start the showcase app:
```
cd example && flutter run
```

Check:
1. "Point Labels" entry appears in the navigation rail/bottom bar with NEW badge.
2. Navigating to it shows three charts — each with visible labels on the markers.
3. Changing Position in the options panel repositions labels on Chart 1 immediately.
4. Changing Font Size slider updates font live.
5. Toggling Show Unit adds "mmol/L" suffix.
6. Toggling Background Pill adds a white pill behind each label.
7. Toggling Custom Formatter changes format to `"<value>!"`.
8. Chart 2 (HR) shows integer labels with pill by default.
9. Chart 3 (Area) shows labels below each marker in dark green.
10. `showDataPointMarkers: false` (on a series without that flag) shows no labels (no regression).
11. `flutter analyze` — no issues.

- [ ] **Step 4: Run full test suite**

```
flutter test
```

Expected: All tests pass.

- [ ] **Step 5: Commit**

```
git add example/lib/showcase/showcase_app.dart
git commit -m "feat: wire DataPointLabelsPage into showcase navigation"
```

---

## Self-Review

**Spec coverage check:**

| Spec requirement | Task covering it |
|---|---|
| `DataPointLabelConfig` class with all fields | Task 1 |
| `DataPointLabelPosition` enum (above/below/left/right) | Task 1 |
| `dataPointLabels` on `LineChartSeries` | Task 2 |
| `dataPointLabels` on `AreaChartSeries` | Task 2 |
| Priority order: formatter → auto-format | Task 4 |
| Auto-format rules (integer/2dp/1dp/integer) | Task 1 (`autoFormatLabelValue`) |
| `showUnit` appends series unit | Task 4 |
| Position calculation with gap=2px | Task 4 |
| Background pill with border-radius = height/2 | Task 4 |
| 4px H / 2px V pill padding | Task 4 |
| TextPainter cache keyed by string | Task 4 |
| Fast path: null config = zero cost | Task 4 (switch on `paintLabels`) |
| Fast path: show=false = zero cost | Task 4 |
| Viewport culling inherited (uses `originalIndices`) | Task 4 |
| No extra canvas.save/restore pairs | Task 4 |
| Export from barrel | Task 3 |
| Showcase page with live controls | Task 5 + 6 |

**Placeholder scan:** None found.

**Type consistency check:**
- `DataPointLabelConfig.autoFormatLabelValue` — referenced in Task 1 test and Task 4 rendering. Name is consistent.
- `DataPointLabelPosition` values — `above`, `below`, `left`, `right` used consistently in Tasks 1, 4, 5.
- `series.unit` passed as the `unit` argument to `_paintDataPointLabel` — consistent with `ChartSeries.unit: String?`.
- `config.labelColor ?? seriesColor` — `labelColor` is `Color?`, `seriesColor` is `Color` from `dart:ui`. Consistent.
