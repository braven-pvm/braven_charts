# Series Glow & Inline Label — Design Spec

**Date:** 2026-05-20  
**Status:** Approved

---

## Overview

Two independent visual enhancements for `LineChartSeries` and `AreaChartSeries`:

1. **Line Glow** — a blur-based halo behind the series line, identical in mechanism to the existing `elevation` glow on `ThresholdAnnotation`.
2. **Series Inline Label** — a single text label anchored to the series line at a horizontal position (`left`, `center`, or `right` of the visible plot area), with a vertical offset.

---

## Feature 1: Line Glow

### API

One new field on both `LineChartSeries` and `AreaChartSeries`:

```dart
this.lineGlow = 0.0,   // 0.0 = no glow; typical range 2–8 px
```

```dart
final double lineGlow;
```

### Rendering

Before drawing the normal line path, draw the same path with a blurred paint. Exactly mirrors the `ThresholdAnnotation` pattern:

```dart
if (series.lineGlow > 0) {
  final glowPaint = Paint()
    ..color = baseColor.withAlpha(60)
    ..strokeWidth = effectiveStrokeWidth + series.lineGlow * 2
    ..style = PaintingStyle.stroke
    ..maskFilter = MaskFilter.blur(BlurStyle.normal, series.lineGlow);
  canvas.drawPath(path, glowPaint);
}
// normal line drawn on top immediately after
```

**Coverage:**
- `_paintLineSeriesSingleColor` — glow pass before the single `canvas.drawPath` call
- `_paintLineSeriesMultiStyle` — glow pass per segment, using the segment color
- `_paintAreaSeriesSingleColor` / `_paintAreaSeriesMultiColor` — glow pass on the line path only (not the fill path)

### Defaults & Constraints

- Default `0.0` → zero-cost; the `if` guard means no paint object is created.
- No upper bound enforced; values above ~12 look diffuse and are the caller's choice.
- Glow color is always the series/segment color at 24% alpha — not configurable (YAGNI).

---

## Feature 2: Series Inline Label

### New Types

**File:** `lib/src/models/series_inline_label_config.dart`

```dart
enum SeriesLabelPosition { left, center, right }

class SeriesLabelBackground {
  const SeriesLabelBackground({
    required this.color,
    this.opacity = 0.85,
  });

  final Color color;
  final double opacity;

  // copyWith, ==, hashCode, toString
}

class SeriesInlineLabelConfig {
  const SeriesInlineLabelConfig({
    required this.text,
    this.position = SeriesLabelPosition.right,
    this.offsetY = 0.0,
    this.color,              // null → series color
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

  // copyWith, ==, hashCode, toString
}
```

### Series Integration

`inlineLabel: SeriesInlineLabelConfig?` added to both `LineChartSeries` and `AreaChartSeries` constructors, field declarations, `copyWith`, `operator ==`, `hashCode`.

### Rendering

New method `_paintSeriesInlineLabel()` in `series_element.dart`, called after the line/area is painted.

**Step 1 — Anchor x-pixel:**

| `position` | x-pixel |
|---|---|
| `left` | `plotArea.left` |
| `center` | `plotArea.left + plotArea.width / 2` |
| `right` | `plotArea.right` |

**Step 2 — Interpolate y at anchor x:**

Walk `transformedPoints` to find the pair `[a, b]` where `a.dx <= anchorX <= b.dx`. Linear interpolation:

```dart
final t = (anchorX - a.dx) / (b.dx - a.dx);
final y = a.dy + t * (b.dy - a.dy);
```

If `anchorX` is outside the range of all visible points (e.g. the series doesn't reach the right edge), skip rendering.

**Step 3 — Text alignment:**

| `position` | `paintX` (text top-left x) | `TextAlign` |
|---|---|---|
| `left` | `anchorX` | left |
| `center` | `anchorX - tp.width / 2` | center |
| `right` | `anchorX - tp.width` | right |

**Step 4 — Vertical position:**

```dart
final paintY = interpolatedY + config.offsetY - tp.height / 2;
```

Label is vertically centered on the line. `offsetY` nudges up (negative) or down (positive).

**Step 5 — Background pill (optional):**

Same rounded-rect approach as `DataPointLabelConfig`:

```dart
if (config.background != null) {
  const hPad = 4.0, vPad = 2.0;
  final bgRect = Rect.fromLTWH(paintX - hPad, paintY - vPad,
      tp.width + hPad * 2, tp.height + vPad * 2);
  canvas.drawRRect(
    RRect.fromRectAndRadius(bgRect, Radius.circular((tp.height + vPad * 2) / 2)),
    Paint()..color = config.background!.color.withValues(alpha: config.background!.opacity),
  );
}
tp.paint(canvas, Offset(paintX, paintY));
```

**TextPainter:** No cache needed — one label per series, laid out once per paint cycle. Just create, layout, paint, dispose inline.

**Skip conditions:**
- `inlineLabel == null` → zero cost, entire method not called.
- Fewer than 2 visible transformed points → skip.
- Anchor x outside visible point range → skip.

### Export

`SeriesInlineLabelConfig`, `SeriesLabelPosition`, and `SeriesLabelBackground` exported from `lib/braven_charts.dart`.

---

## Files Changed

| File | Change |
|---|---|
| `lib/src/models/series_inline_label_config.dart` | **NEW** — `SeriesInlineLabelConfig`, `SeriesLabelPosition`, `SeriesLabelBackground` |
| `lib/src/models/chart_series.dart` | Add `lineGlow` + `inlineLabel` to `LineChartSeries` and `AreaChartSeries` |
| `lib/src/elements/series_element.dart` | Glow pass in line/area paint methods; `_paintSeriesInlineLabel()` |
| `lib/braven_charts.dart` | Export new model file |

---

## Out of Scope

- Glow color override — always inherits series color.
- Inline label at a specific x data-value — `left`/`center`/`right` covers the stated need.
- Multiple inline labels per series.
- Inline label for `BarChartSeries` or `ScatterChartSeries`.
