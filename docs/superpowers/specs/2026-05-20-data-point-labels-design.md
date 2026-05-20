# Data Point Value Labels — Design Spec

**Date:** 2026-05-20  
**Status:** Approved

---

## Overview

When `showDataPointMarkers` is enabled on a series, the chart can optionally render a text label near each marker showing its Y-value. Labels are opt-in (`show: false` default), fully styleable, and render inside the existing marker pass so there is no extra iteration over data.

---

## API

### New class: `DataPointLabelConfig`

```dart
class DataPointLabelConfig {
  const DataPointLabelConfig({
    this.show = false,
    this.position = DataPointLabelPosition.above,
    this.offsetX = 0.0,
    this.offsetY = 0.0,
    this.labelColor,            // null → series color
    this.fontSize = 10.0,
    this.fontWeight = FontWeight.w600,
    this.showUnit = false,      // appends series.unit when true
    this.formatter,             // (ChartDataPoint) → String; overrides all
    this.background,            // null → no background pill
    this.backgroundOpacity = 0.85,
  });

  final bool show;
  final DataPointLabelPosition position;
  final double offsetX;
  final double offsetY;
  final Color? labelColor;
  final double fontSize;
  final FontWeight fontWeight;
  final bool showUnit;
  final String Function(ChartDataPoint)? formatter;
  final Color? background;
  final double backgroundOpacity;
}

enum DataPointLabelPosition { above, below, left, right }
```

### Usage on series

```dart
LineChartSeries(
  id: 'power',
  showDataPointMarkers: true,
  dataPointMarkerRadius: 4,
  dataPointLabels: DataPointLabelConfig(
    show: true,
    position: DataPointLabelPosition.above,
    // offsetX / offsetY: extra pixel nudge after position is calculated
    labelColor: null,       // null → inherits series color
    fontSize: 10.0,
    showUnit: false,        // true → "178 W" instead of "178"
    formatter: null,        // custom: (point) => '${point.y.toInt()}'
    background: null,       // null → plain text; Colors.white → white pill
    backgroundOpacity: 0.85,
  ),
)
```

`dataPointLabels` is added to both `LineChartSeries` and `AreaChartSeries`. It is `null` by default (no labels rendered, zero cost).

---

## Formatting Rules

Applied in priority order:

1. **`formatter`** — if non-null, called with the `ChartDataPoint`; return value used as-is.
2. **Auto-format + unit** — Y-value formatted via existing `MultiAxisValueFormatter` logic:
   - Integer if `y == y.roundToDouble()`
   - 2 decimal places if `|y| < 1`
   - 1 decimal place if `|y| < 100`
   - Integer otherwise
   - Appends ` ${series.unit}` when `showUnit: true` and unit is non-null/non-empty.

---

## Position Calculation

Given marker centre `(cx, cy)` and marker radius `r`:

| Position | Anchor point | Text alignment |
|---|---|---|
| `above` | `(cx + offsetX, cy - r - gap + offsetY)` | centre-bottom |
| `below` | `(cx + offsetX, cy + r + gap + offsetY)` | centre-top |
| `left`  | `(cx - r - gap + offsetX, cy + offsetY)` | right-centre |
| `right` | `(cx + r + gap + offsetX, cy + offsetY)` | left-centre |

`gap` = 2px constant between marker edge and label edge.

When `background` is set, a rounded rect (`borderRadius = height / 2`, pill shape) is drawn with `backgroundOpacity` before the text, with 4px horizontal and 2px vertical padding around the text bounds.

---

## Performance Design

All work happens inside the existing `_paintDataPointMarkers()` loop in `series_element.dart` — no extra pass over data.

**TextPainter cache** — `Map<String, TextPainter>` keyed by formatted label string, stored on `SeriesElement`. `layout()` is called only on cache miss. Cache is cleared when the series config changes (same lifecycle as the existing marker repaint guard).

**Fast paths:**
- `dataPointLabels == null` → zero-cost; entire label branch skipped.
- `dataPointLabels.show == false` → same as above.
- `background == null` → no `drawRRect` call; background branch is a single null check.
- Viewport culling is inherited for free — labels are only drawn for points that already pass the visible-range filter used by markers.

No additional `canvas.save()` / `canvas.restore()` pairs. Text drawn inline after each `drawCircle`, reusing the same `Paint` object (color updated per label).

---

## Files Changed

| File | Change |
|---|---|
| `lib/src/models/data_point_label_config.dart` | **NEW** — `DataPointLabelConfig` class and `DataPointLabelPosition` enum |
| `lib/src/models/chart_series.dart` | Add `dataPointLabels: DataPointLabelConfig?` to `LineChartSeries` and `AreaChartSeries` constructors and `copyWith` |
| `lib/src/elements/series_element.dart` | Render labels in `_paintDataPointMarkers()` with TextPainter cache |
| `lib/src/braven_charts.dart` | Export `DataPointLabelConfig` and `DataPointLabelPosition` |

---

## Showcase

Add a dedicated `DataPointLabelsPage` (or extend `TrackingPage`) in the example app demonstrating:
- Single series with `position: above`, default formatting
- `showUnit: true`
- Custom `formatter`
- `background: Colors.white` pill
- Live controls for position, fontSize, showUnit, background toggle

---

## Out of Scope

- Auto-density filtering (skip overlapping labels) — deferred; user controls point density via data
- Per-point label override via `ChartDataPoint.label` — `formatter` already covers this via `point.label`
- Scatter series labels — same pattern applies but out of scope for this iteration
