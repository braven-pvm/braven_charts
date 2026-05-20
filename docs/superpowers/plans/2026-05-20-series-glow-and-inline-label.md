# Series Glow & Inline Label Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a `lineGlow` blur-halo to `LineChartSeries`/`AreaChartSeries` and a `SeriesInlineLabelConfig` that pins a styled text label to the series line at a horizontal anchor.

**Architecture:** `lineGlow` is a single `double` field — identical in mechanism to `ThresholdAnnotation.elevation`: draw a blurred wide stroke before the normal stroke. `SeriesInlineLabelConfig` follows the `DataPointLabelConfig` pattern — a new model file, a field on each series, and a `_paintSeriesInlineLabel()` method in `SeriesElement` called after markers.

**Tech Stack:** Flutter/Dart, Canvas API (`MaskFilter.blur`, `TextPainter`), existing `series_element.dart` paint pipeline.

---

## Files Changed

| File | Change |
|---|---|
| `lib/src/models/chart_series.dart` | Add `lineGlow` + `inlineLabel` to `LineChartSeries` + `AreaChartSeries` |
| `lib/src/models/series_inline_label_config.dart` | **NEW** — `SeriesLabelPosition`, `SeriesLabelBackground`, `SeriesInlineLabelConfig` |
| `lib/src/elements/series_element.dart` | Glow pass in 4 paint methods; new `_paintSeriesInlineLabel()` |
| `lib/braven_charts.dart` | Export `series_inline_label_config.dart` |
| `example/lib/showcase/pages/series_styling_page.dart` | **NEW** — showcase for glow + inline labels |
| `example/lib/showcase/showcase_app.dart` | Register `SeriesStylingPage` |
| `test/unit/models/series_inline_label_config_test.dart` | **NEW** — model unit tests |

---

## Task 1: `lineGlow` — Model + Rendering + Tests + Showcase

### Files:
- Modify: `lib/src/models/chart_series.dart`
- Modify: `lib/src/elements/series_element.dart`
- Create: `example/lib/showcase/pages/series_styling_page.dart`
- Modify: `example/lib/showcase/showcase_app.dart`

---

- [ ] **Step 1: Add `lineGlow` to `LineChartSeries`**

In `lib/src/models/chart_series.dart`, add `this.lineGlow = 0.0,` to the `LineChartSeries` constructor after `this.dataPointLabels,`, add `final double lineGlow;` to the fields, add `lineGlow: lineGlow ?? this.lineGlow,` to `copyWith`, add `other.lineGlow == lineGlow &&` to `operator ==` (before `other.dataPointLabels`), and add `lineGlow,` to the `hashCode` `Object.hashAll` list (before `dataPointLabels`).

Result — constructor becomes:
```dart
const LineChartSeries({
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
  this.showDataPointMarkers = false,
  this.dataPointMarkerRadius = 3.0,
  this.dataPointMarkerStyle = DataPointMarkerStyle.filled,
  this.dataPointMarkerBackground = Colors.white,
  this.lineGlow = 0.0,
  this.dataPointLabels,
});
```

Fields to add:
```dart
final double lineGlow;
```

copyWith param + body:
```dart
double? lineGlow,
// ...
lineGlow: lineGlow ?? this.lineGlow,
```

`operator ==` addition (before `other.dataPointLabels == dataPointLabels`):
```dart
other.lineGlow == lineGlow &&
```

`hashCode` addition (before `dataPointLabels,`):
```dart
lineGlow,
```

---

- [ ] **Step 2: Add `lineGlow` to `AreaChartSeries`**

Identical 4-location addition to `AreaChartSeries` in the same file. Add after `this.dataPointMarkerBackground = Colors.white,` in the constructor:

```dart
this.lineGlow = 0.0,
```

Add field:
```dart
final double lineGlow;
```

copyWith param + body:
```dart
double? lineGlow,
// ...
lineGlow: lineGlow ?? this.lineGlow,
```

`operator ==` (before `other.dataPointLabels == dataPointLabels`):
```dart
other.lineGlow == lineGlow &&
```

`hashCode` (before `dataPointLabels,`):
```dart
lineGlow,
```

---

- [ ] **Step 3: Glow pass in `_paintLineSeriesSingleColor`**

In `lib/src/elements/series_element.dart`, inside `_paintLineSeriesSingleColor`, add this block immediately **before** the `canvas.drawPath(_cachedPath!, paint);` line:

```dart
if (series.lineGlow > 0) {
  final glowPaint = Paint()
    ..color = baseColor.withAlpha(60)
    ..strokeWidth = effectiveStrokeWidth + series.lineGlow * 2
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..maskFilter = MaskFilter.blur(BlurStyle.normal, series.lineGlow);
  canvas.drawPath(_cachedPath!, glowPaint);
}
canvas.drawPath(_cachedPath!, paint);
```

---

- [ ] **Step 4: Glow pass in `_paintLineSeriesMultiStyle`**

Inside the `for (final region in regions)` loop, add a glow draw immediately **before** `canvas.drawPath(regionPath, paint);`:

```dart
if (series.lineGlow > 0) {
  final glowPaint = Paint()
    ..color = region.color.withAlpha(60)
    ..strokeWidth = region.strokeWidth + series.lineGlow * 2
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..maskFilter = MaskFilter.blur(BlurStyle.normal, series.lineGlow);
  canvas.drawPath(regionPath, glowPaint);
}
canvas.drawPath(regionPath, paint);
```

---

- [ ] **Step 5: Glow pass in `_paintAreaSeriesSingleColor`**

Inside `_paintAreaSeriesSingleColor`, add a glow draw immediately **before** `canvas.drawPath(linePath, linePaint);` (the stroke line draw — NOT the fill draw):

```dart
if (series.lineGlow > 0) {
  final glowPaint = Paint()
    ..color = baseColor.withAlpha(60)
    ..strokeWidth = strokeWidth + series.lineGlow * 2
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..maskFilter = MaskFilter.blur(BlurStyle.normal, series.lineGlow);
  canvas.drawPath(linePath, glowPaint);
}
canvas.drawPath(linePath, linePaint);
```

---

- [ ] **Step 6: Glow pass in `_paintAreaSeriesMultiColor`**

Inside the `for (final region in regions)` loop, add a glow draw immediately **before** `canvas.drawPath(strokePath, strokePaint);`:

```dart
if (series.lineGlow > 0) {
  final glowPaint = Paint()
    ..color = region.color.withAlpha(60)
    ..strokeWidth = region.strokeWidth + series.lineGlow * 2
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..maskFilter = MaskFilter.blur(BlurStyle.normal, series.lineGlow);
  canvas.drawPath(strokePath, glowPaint);
}
canvas.drawPath(strokePath, strokePaint);
```

---

- [ ] **Step 7: Create showcase page**

Create `example/lib/showcase/pages/series_styling_page.dart`:

```dart
// Copyright 2025 Braven Charts - Series Styling Showcase
// SPDX-License-Identifier: MIT

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';

import '../widgets/options_panel.dart';

class SeriesStylingPage extends StatefulWidget {
  const SeriesStylingPage({super.key});

  @override
  State<SeriesStylingPage> createState() => _SeriesStylingPageState();
}

class _SeriesStylingPageState extends State<SeriesStylingPage> {
  double _lineGlow = 0.0;

  static const _points = [
    ChartDataPoint(x: 0, y: 120),
    ChartDataPoint(x: 10, y: 145),
    ChartDataPoint(x: 20, y: 132),
    ChartDataPoint(x: 30, y: 168),
    ChartDataPoint(x: 40, y: 155),
    ChartDataPoint(x: 50, y: 178),
    ChartDataPoint(x: 60, y: 161),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Series Styling')),
      body: Row(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _ChartCard(
                  title: 'Line Glow',
                  subtitle: 'lineGlow controls blur-halo radius',
                  child: BravenChartPlus(
                    series: [
                      LineChartSeries(
                        id: 'power',
                        name: 'Power',
                        points: _points,
                        color: const Color(0xFF6366F1),
                        strokeWidth: 2.5,
                        lineGlow: _lineGlow,
                      ),
                    ],
                    xAxisConfig: const XAxisConfig(
                        label: 'Time (min)', min: -5, max: 65),
                    yAxis: YAxisConfig(
                        position: YAxisPosition.left,
                        label: 'W',
                        min: 100,
                        max: 200),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 260,
            child: OptionsPanel(
              title: 'Styling Options',
              children: [
                OptionSection(
                  title: 'Line Glow',
                  icon: Icons.blur_on,
                  children: [
                    SliderOption(
                      label: 'Glow Radius',
                      value: _lineGlow,
                      min: 0.0,
                      max: 12.0,
                      divisions: 12,
                      suffix: 'px',
                      decimalPlaces: 0,
                      onChanged: (v) => setState(() => _lineGlow = v),
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

---

- [ ] **Step 8: Register page in showcase_app.dart**

In `example/lib/showcase/showcase_app.dart`, add the import:
```dart
import 'pages/series_styling_page.dart';
```

And add a `NavDestination` entry to the destinations list (place it after the Data Point Labels entry):
```dart
NavDestination(
  label: 'Series Styling',
  icon: Icons.auto_awesome_outlined,
  selectedIcon: Icons.auto_awesome,
  page: const SeriesStylingPage(),
  badge: 'NEW',
),
```

---

- [ ] **Step 9: Run analyze + tests**

```
flutter analyze --no-pub
flutter test --no-pub
```

Expected: no issues, all existing tests pass.

---

- [ ] **Step 10: Commit**

```
git add lib/src/models/chart_series.dart lib/src/elements/series_element.dart example/lib/showcase/pages/series_styling_page.dart example/lib/showcase/showcase_app.dart
git commit -m "feat: add lineGlow blur-halo to LineChartSeries and AreaChartSeries"
```

---

## Task 2: `SeriesInlineLabelConfig` — Model + Series Integration + Rendering + Tests + Showcase

### Files:
- Create: `lib/src/models/series_inline_label_config.dart`
- Create: `test/unit/models/series_inline_label_config_test.dart`
- Modify: `lib/src/models/chart_series.dart`
- Modify: `lib/src/elements/series_element.dart`
- Modify: `lib/braven_charts.dart`
- Modify: `example/lib/showcase/pages/series_styling_page.dart`

---

- [ ] **Step 1: Write failing model tests**

Create `test/unit/models/series_inline_label_config_test.dart`:

```dart
import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SeriesLabelPosition', () {
    test('has left, center, right values', () {
      expect(SeriesLabelPosition.values,
          containsAll([SeriesLabelPosition.left, SeriesLabelPosition.center, SeriesLabelPosition.right]));
    });
  });

  group('SeriesLabelBackground', () {
    test('default opacity is 0.85', () {
      const bg = SeriesLabelBackground(color: Colors.white);
      expect(bg.opacity, 0.85);
    });

    test('equality', () {
      const a = SeriesLabelBackground(color: Colors.white, opacity: 0.9);
      const b = SeriesLabelBackground(color: Colors.white, opacity: 0.9);
      expect(a, equals(b));
    });

    test('inequality when color differs', () {
      const a = SeriesLabelBackground(color: Colors.white);
      const b = SeriesLabelBackground(color: Colors.black);
      expect(a, isNot(equals(b)));
    });

    test('copyWith changes color', () {
      const bg = SeriesLabelBackground(color: Colors.white, opacity: 0.9);
      final copy = bg.copyWith(color: Colors.black);
      expect(copy.color, Colors.black);
      expect(copy.opacity, 0.9);
    });
  });

  group('SeriesInlineLabelConfig', () {
    test('requires text', () {
      const config = SeriesInlineLabelConfig(text: 'Power');
      expect(config.text, 'Power');
    });

    test('default position is right', () {
      const config = SeriesInlineLabelConfig(text: 'x');
      expect(config.position, SeriesLabelPosition.right);
    });

    test('default offsetY is 0.0', () {
      const config = SeriesInlineLabelConfig(text: 'x');
      expect(config.offsetY, 0.0);
    });

    test('default color is null (inherits series color)', () {
      const config = SeriesInlineLabelConfig(text: 'x');
      expect(config.color, isNull);
    });

    test('default fontSize is 11.0', () {
      const config = SeriesInlineLabelConfig(text: 'x');
      expect(config.fontSize, 11.0);
    });

    test('default fontWeight is w500', () {
      const config = SeriesInlineLabelConfig(text: 'x');
      expect(config.fontWeight, FontWeight.w500);
    });

    test('default background is null', () {
      const config = SeriesInlineLabelConfig(text: 'x');
      expect(config.background, isNull);
    });

    test('copyWith changes text', () {
      const config = SeriesInlineLabelConfig(text: 'old');
      final copy = config.copyWith(text: 'new');
      expect(copy.text, 'new');
      expect(copy.position, config.position);
    });

    test('copyWith changes position', () {
      const config = SeriesInlineLabelConfig(text: 'x');
      final copy = config.copyWith(position: SeriesLabelPosition.center);
      expect(copy.position, SeriesLabelPosition.center);
    });

    test('equality', () {
      const a = SeriesInlineLabelConfig(text: 'Power', fontSize: 12.0);
      const b = SeriesInlineLabelConfig(text: 'Power', fontSize: 12.0);
      expect(a, equals(b));
    });

    test('inequality when text differs', () {
      const a = SeriesInlineLabelConfig(text: 'Power');
      const b = SeriesInlineLabelConfig(text: 'HR');
      expect(a, isNot(equals(b)));
    });

    test('hashCode consistent with equality', () {
      const a = SeriesInlineLabelConfig(text: 'Power', fontSize: 12.0);
      const b = SeriesInlineLabelConfig(text: 'Power', fontSize: 12.0);
      expect(a.hashCode, equals(b.hashCode));
    });
  });

  group('LineChartSeries.inlineLabel integration', () {
    test('defaults to null', () {
      const s = LineChartSeries(
        id: 'test',
        points: [],
      );
      expect(s.inlineLabel, isNull);
    });

    test('accepts SeriesInlineLabelConfig', () {
      const config = SeriesInlineLabelConfig(text: 'Power');
      const s = LineChartSeries(
        id: 'test',
        points: [],
        inlineLabel: config,
      );
      expect(s.inlineLabel, equals(config));
    });

    test('copyWith preserves inlineLabel', () {
      const config = SeriesInlineLabelConfig(text: 'Power');
      const s = LineChartSeries(id: 'test', points: [], inlineLabel: config);
      final copy = s.copyWith(strokeWidth: 3.0);
      expect(copy.inlineLabel, equals(config));
    });
  });

  group('AreaChartSeries.inlineLabel integration', () {
    test('defaults to null', () {
      const s = AreaChartSeries(id: 'test', points: []);
      expect(s.inlineLabel, isNull);
    });

    test('accepts SeriesInlineLabelConfig', () {
      const config = SeriesInlineLabelConfig(text: 'Fat Ox.');
      const s = AreaChartSeries(id: 'test', points: [], inlineLabel: config);
      expect(s.inlineLabel, equals(config));
    });
  });
}
```

---

- [ ] **Step 2: Run tests — expect failures**

```
flutter test test/unit/models/series_inline_label_config_test.dart --no-pub
```

Expected: compilation errors — `SeriesInlineLabelConfig`, `SeriesLabelPosition`, `SeriesLabelBackground` not found.

---

- [ ] **Step 3: Create `series_inline_label_config.dart`**

Create `lib/src/models/series_inline_label_config.dart`:

```dart
// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';

enum SeriesLabelPosition { left, center, right }

class SeriesLabelBackground {
  const SeriesLabelBackground({
    required this.color,
    this.opacity = 0.85,
  });

  final Color color;
  final double opacity;

  SeriesLabelBackground copyWith({Color? color, double? opacity}) =>
      SeriesLabelBackground(
        color: color ?? this.color,
        opacity: opacity ?? this.opacity,
      );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! SeriesLabelBackground) return false;
    return other.color == color && other.opacity == opacity;
  }

  @override
  int get hashCode => Object.hash(color, opacity);

  @override
  String toString() =>
      'SeriesLabelBackground(color: $color, opacity: $opacity)';
}

class SeriesInlineLabelConfig {
  const SeriesInlineLabelConfig({
    required this.text,
    this.position = SeriesLabelPosition.right,
    this.offsetY = 0.0,
    this.color,
    this.fontSize = 11.0,
    this.fontWeight = FontWeight.w500,
    this.background,
  });

  final String text;
  final SeriesLabelPosition position;
  final double offsetY;
  final Color? color;
  final double fontSize;
  final FontWeight fontWeight;
  final SeriesLabelBackground? background;

  SeriesInlineLabelConfig copyWith({
    String? text,
    SeriesLabelPosition? position,
    double? offsetY,
    Color? color,
    double? fontSize,
    FontWeight? fontWeight,
    SeriesLabelBackground? background,
  }) =>
      SeriesInlineLabelConfig(
        text: text ?? this.text,
        position: position ?? this.position,
        offsetY: offsetY ?? this.offsetY,
        color: color ?? this.color,
        fontSize: fontSize ?? this.fontSize,
        fontWeight: fontWeight ?? this.fontWeight,
        background: background ?? this.background,
      );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! SeriesInlineLabelConfig) return false;
    return other.text == text &&
        other.position == position &&
        other.offsetY == offsetY &&
        other.color == color &&
        other.fontSize == fontSize &&
        other.fontWeight == fontWeight &&
        other.background == background;
  }

  @override
  int get hashCode =>
      Object.hashAll([text, position, offsetY, color, fontSize, fontWeight, background]);

  @override
  String toString() =>
      'SeriesInlineLabelConfig(text: $text, position: $position)';
}
```

---

- [ ] **Step 4: Export from barrel**

In `lib/braven_charts.dart`, add this line after the `data_point_label_config.dart` export:

```dart
export 'src/models/series_inline_label_config.dart';
```

---

- [ ] **Step 5: Run model tests — expect pass**

```
flutter test test/unit/models/series_inline_label_config_test.dart --no-pub
```

Expected: all tests pass (inlineLabel integration tests will still fail — `LineChartSeries` doesn't have the field yet).

---

- [ ] **Step 6: Add `inlineLabel` to `LineChartSeries`**

In `lib/src/models/chart_series.dart`, add the import at the top:

```dart
import 'series_inline_label_config.dart';
```

Then in `LineChartSeries`, add `this.inlineLabel,` to the constructor (after `this.dataPointLabels,`):

```dart
this.inlineLabel,
```

Add field:
```dart
final SeriesInlineLabelConfig? inlineLabel;
```

In `copyWith` — add param:
```dart
SeriesInlineLabelConfig? inlineLabel,
```

In `copyWith` body:
```dart
inlineLabel: inlineLabel ?? this.inlineLabel,
```

In `operator ==` (before the closing `;`):
```dart
other.inlineLabel == inlineLabel
```

In `hashCode` list (after `dataPointLabels,`):
```dart
inlineLabel,
```

---

- [ ] **Step 7: Add `inlineLabel` to `AreaChartSeries`**

Identical 5-location addition to `AreaChartSeries` — same field name, same type, same defaults.

---

- [ ] **Step 8: Run integration tests — expect pass**

```
flutter test test/unit/models/series_inline_label_config_test.dart --no-pub
```

Expected: all tests pass.

---

- [ ] **Step 9: Add `_paintSeriesInlineLabel` to `series_element.dart`**

Add this method to the `SeriesElement` class (place it after `_paintDataPointLabelText`):

```dart
void _paintSeriesInlineLabel(
  Canvas canvas,
  ChartSeries series,
  List<Offset> transformedPoints,
  Color baseColor,
) {
  final config = switch (series) {
    final LineChartSeries s => s.inlineLabel,
    final AreaChartSeries s => s.inlineLabel,
    _ => null,
  };
  if (config == null || transformedPoints.length < 2) return;

  // Determine anchor x-pixel from position
  final double anchorX = switch (config.position) {
    SeriesLabelPosition.left => transformedPoints.first.dx,
    SeriesLabelPosition.center =>
      (transformedPoints.first.dx + transformedPoints.last.dx) / 2,
    SeriesLabelPosition.right => transformedPoints.last.dx,
  };

  // Interpolate y at anchorX from transformedPoints
  double? interpolatedY;
  for (int i = 0; i < transformedPoints.length - 1; i++) {
    final a = transformedPoints[i];
    final b = transformedPoints[i + 1];
    if (anchorX >= a.dx && anchorX <= b.dx) {
      final t = (b.dx == a.dx) ? 0.0 : (anchorX - a.dx) / (b.dx - a.dx);
      interpolatedY = a.dy + t * (b.dy - a.dy);
      break;
    }
  }
  // Exact match on last point
  if (interpolatedY == null &&
      (anchorX - transformedPoints.last.dx).abs() < 1.0) {
    interpolatedY = transformedPoints.last.dy;
  }
  if (interpolatedY == null) return;

  final effectiveColor = config.color ?? baseColor;

  final tp = TextPainter(
    text: TextSpan(
      text: config.text,
      style: TextStyle(
        color: effectiveColor,
        fontSize: config.fontSize,
        fontWeight: config.fontWeight,
      ),
    ),
    textDirection: TextDirection.ltr,
    textAlign: TextAlign.left,
  )..layout();

  final double paintX = switch (config.position) {
    SeriesLabelPosition.left => anchorX,
    SeriesLabelPosition.center => anchorX - tp.width / 2,
    SeriesLabelPosition.right => anchorX - tp.width,
  };
  final double paintY = interpolatedY + config.offsetY - tp.height / 2;

  if (config.background != null) {
    const hPad = 4.0;
    const vPad = 2.0;
    final bgRect = Rect.fromLTWH(
      paintX - hPad,
      paintY - vPad,
      tp.width + hPad * 2,
      tp.height + vPad * 2,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          bgRect, Radius.circular((tp.height + vPad * 2) / 2)),
      Paint()
        ..color = config.background!.color
            .withValues(alpha: config.background!.opacity),
    );
  }

  tp.paint(canvas, Offset(paintX, paintY));
  tp.dispose();
}
```

---

- [ ] **Step 10: Call `_paintSeriesInlineLabel` in `_paintLineSeriesSingleColor`**

At the **end** of `_paintLineSeriesSingleColor`, after the `_paintDataPointMarkers` block, add:

```dart
if (series.inlineLabel != null && _cachedTransformedPoints != null &&
    _cachedTransformedPoints!.isNotEmpty) {
  _paintSeriesInlineLabel(
      canvas, series, _cachedTransformedPoints!, baseColor);
}
```

---

- [ ] **Step 11: Call `_paintSeriesInlineLabel` in `_paintLineSeriesMultiStyle`**

At the **end** of `_paintLineSeriesMultiStyle`, after the `_paintDataPointMarkers` block, add:

```dart
if (series.inlineLabel != null) {
  _paintSeriesInlineLabel(canvas, series, transformedPoints, baseColor);
}
```

---

- [ ] **Step 12: Call `_paintSeriesInlineLabel` in `_paintAreaSeriesSingleColor`**

At the **end** of `_paintAreaSeriesSingleColor`, after `canvas.drawPath(linePath, linePaint);`, add:

```dart
if (series.inlineLabel != null) {
  _paintSeriesInlineLabel(canvas, series, transformedPoints, baseColor);
}
```

---

- [ ] **Step 13: Call `_paintSeriesInlineLabel` in `_paintAreaSeriesMultiColor`**

At the **end** of `_paintAreaSeriesMultiColor`, after the region loop, add:

```dart
if (series.inlineLabel != null) {
  _paintSeriesInlineLabel(canvas, series, transformedPoints, baseColor);
}
```

---

- [ ] **Step 14: Add inline label demo to `series_styling_page.dart`**

Add a second chart card to the `ListView` in `SeriesStylingPage` and extend the options panel. Replace the `_SeriesStylingPageState` class with:

```dart
class _SeriesStylingPageState extends State<SeriesStylingPage> {
  double _lineGlow = 0.0;
  SeriesLabelPosition _labelPosition = SeriesLabelPosition.right;
  double _labelOffsetY = 0.0;
  bool _labelBackground = false;

  static const _points = [
    ChartDataPoint(x: 0, y: 120),
    ChartDataPoint(x: 10, y: 145),
    ChartDataPoint(x: 20, y: 132),
    ChartDataPoint(x: 30, y: 168),
    ChartDataPoint(x: 40, y: 155),
    ChartDataPoint(x: 50, y: 178),
    ChartDataPoint(x: 60, y: 161),
  ];

  static const _twoSeriesPoints = [
    ChartDataPoint(x: 0, y: 80),
    ChartDataPoint(x: 10, y: 95),
    ChartDataPoint(x: 20, y: 110),
    ChartDataPoint(x: 30, y: 98),
    ChartDataPoint(x: 40, y: 115),
    ChartDataPoint(x: 50, y: 102),
    ChartDataPoint(x: 60, y: 120),
  ];

  SeriesInlineLabelConfig _buildLabelConfig(String text, Color color) =>
      SeriesInlineLabelConfig(
        text: text,
        position: _labelPosition,
        offsetY: _labelOffsetY,
        color: color,
        background:
            _labelBackground ? const SeriesLabelBackground(color: Colors.white) : null,
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Series Styling')),
      body: Row(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _ChartCard(
                  title: 'Line Glow',
                  subtitle: 'lineGlow controls blur-halo radius',
                  child: BravenChartPlus(
                    series: [
                      LineChartSeries(
                        id: 'power',
                        name: 'Power',
                        points: _points,
                        color: const Color(0xFF6366F1),
                        strokeWidth: 2.5,
                        lineGlow: _lineGlow,
                      ),
                    ],
                    xAxisConfig: const XAxisConfig(
                        label: 'Time (min)', min: -5, max: 65),
                    yAxis: YAxisConfig(
                        position: YAxisPosition.left,
                        label: 'W',
                        min: 100,
                        max: 200),
                  ),
                ),
                const SizedBox(height: 16),
                _ChartCard(
                  title: 'Series Inline Labels',
                  subtitle: 'Label anchored to the series line',
                  child: BravenChartPlus(
                    series: [
                      LineChartSeries(
                        id: 'power',
                        name: 'Power',
                        points: _points,
                        color: const Color(0xFF6366F1),
                        strokeWidth: 2.0,
                        inlineLabel: _buildLabelConfig(
                            'Power', const Color(0xFF6366F1)),
                      ),
                      LineChartSeries(
                        id: 'hr',
                        name: 'HR',
                        points: _twoSeriesPoints,
                        color: const Color(0xFFEF4444),
                        strokeWidth: 2.0,
                        inlineLabel: _buildLabelConfig(
                            'HR', const Color(0xFFEF4444)),
                      ),
                    ],
                    xAxisConfig: const XAxisConfig(
                        label: 'Time (min)', min: -5, max: 65),
                    yAxis: YAxisConfig(
                        position: YAxisPosition.left,
                        label: 'Value',
                        min: 60,
                        max: 200),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 260,
            child: OptionsPanel(
              title: 'Styling Options',
              children: [
                OptionSection(
                  title: 'Line Glow',
                  icon: Icons.blur_on,
                  children: [
                    SliderOption(
                      label: 'Glow Radius',
                      value: _lineGlow,
                      min: 0.0,
                      max: 12.0,
                      divisions: 12,
                      suffix: 'px',
                      decimalPlaces: 0,
                      onChanged: (v) => setState(() => _lineGlow = v),
                    ),
                  ],
                ),
                OptionSection(
                  title: 'Inline Label',
                  icon: Icons.label_outline,
                  children: [
                    EnumOption<SeriesLabelPosition>(
                      label: 'Position',
                      value: _labelPosition,
                      values: SeriesLabelPosition.values,
                      labelBuilder: (p) => p.name,
                      onChanged: (v) =>
                          setState(() => _labelPosition = v),
                    ),
                    SliderOption(
                      label: 'Offset Y',
                      value: _labelOffsetY,
                      min: -40.0,
                      max: 40.0,
                      divisions: 16,
                      suffix: 'px',
                      decimalPlaces: 0,
                      onChanged: (v) =>
                          setState(() => _labelOffsetY = v),
                    ),
                    BoolOption(
                      label: 'Background Pill',
                      value: _labelBackground,
                      onChanged: (v) =>
                          setState(() => _labelBackground = v),
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
```

---

- [ ] **Step 15: Run analyze + full tests**

```
flutter analyze --no-pub
flutter test --no-pub
```

Expected: no issues, all tests pass (1155+).

---

- [ ] **Step 16: Commit**

```
git add lib/src/models/series_inline_label_config.dart lib/src/models/chart_series.dart lib/src/elements/series_element.dart lib/braven_charts.dart test/unit/models/series_inline_label_config_test.dart example/lib/showcase/pages/series_styling_page.dart
git commit -m "feat: add SeriesInlineLabelConfig — inline text label anchored to series line"
```

---

## Verification Checklist

After both tasks are complete:

1. Hot-reload showcase app → navigate to **Series Styling**
2. Glow slider: drag from 0 → 8, confirm halo grows around the line
3. Inline label: confirm "Power" and "HR" labels appear at the right edge of each series
4. Switch position to `left` → labels move to left edge
5. Switch position to `center` → labels appear mid-line
6. Offset Y slider: drag up/down, confirm label moves vertically relative to line
7. Background pill toggle: confirm white rounded-rect appears behind label text
8. `flutter analyze --no-pub` → no issues
9. `flutter test --no-pub` → all tests pass
