# Baseline Area Fill — Implementation Spec

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a `baselineValue` option to `AreaChartSeries` that fills the region between the series line and a fixed reference Y value, with independently configurable colors for the above-baseline and below-baseline regions.

**Architecture:** Three new optional fields on the existing `AreaChartSeries` model. A new rendering method `_paintAreaSeriesBaseline` in `SeriesElement` handles polygon splitting at crossing points; no other files change.

**Tech Stack:** Flutter/Dart, `dart:ui` `Canvas`/`Path`, existing `InterpolationGeometry` and `_currentTransform` pipeline.

---

## Scope

This spec covers baseline fill rendering only. A visual threshold annotation at `baselineValue` is a separate feature, to be added later.

---

## API

Three new optional fields on `AreaChartSeries` (all `null` by default — existing charts are unaffected):

```dart
/// Activates baseline-fill mode. null = current behaviour (fill to bottom).
final double? baselineValue;

/// Fill colour for the region where the series is above [baselineValue].
/// null = series colour at [fillOpacity] (matches existing behaviour).
final Color? aboveBaselineFillColor;

/// Fill colour for the region where the series is below [baselineValue].
/// null = series colour at [fillOpacity] (matches existing behaviour).
final Color? belowBaselineFillColor;
```

All three participate in `copyWith`, `==`, `hashCode`, and `toString`.

### Usage examples

```dart
// Two colours — surplus green / deficit red:
AreaChartSeries(
  id: 'power',
  points: points,
  baselineValue: 133.0,
  aboveBaselineFillColor: Colors.green.withOpacity(0.35),
  belowBaselineFillColor: Colors.red.withOpacity(0.35),
)

// Single colour both sides (deviation shading):
AreaChartSeries(
  id: 'power',
  points: points,
  baselineValue: 133.0,
  aboveBaselineFillColor: Colors.orange.withOpacity(0.35),
  belowBaselineFillColor: Colors.orange.withOpacity(0.35),
)

// Fallback to existing fill-to-bottom behaviour:
AreaChartSeries(
  id: 'power',
  points: points,
  // baselineValue omitted
)
```

When a colour is provided its alpha channel is used directly. When `null`, the existing `fillOpacity` × series colour applies.

---

## Rendering Algorithm

`_paintAreaSeriesBaseline` is called from `_paintAreaSeries` when `baselineValue != null`, in place of the existing single/multi-colour paths.

### Step 1 — Convert baseline to plot space

```dart
final baselineY = _currentTransform.dataToPlot(0, series.baselineValue!).dy;
```

### Step 2 — Walk plot points, split at crossings

Iterate consecutive pairs `(p1, p2)` in plot space (after interpolation expansion). Maintain a `currentSegment` list and a `currentAbove` bool:

- **Same side:** append `p2` to `currentSegment`.
- **Crossing:** compute the intersection point:
  ```
  t = (baselineY - p1.dy) / (p2.dy - p1.dy)
  ix = p1.dx + t * (p2.dx - p1.dx)
  intersection = Offset(ix, baselineY)
  ```
  Close `currentSegment` at `intersection`, flush it as a closed polygon, start a new segment on the other side from `intersection`.

### Step 3 — Build and paint each polygon

For a flushed segment `[start, ...points, end]` where `start.dy == baselineY` and `end.dy == baselineY`:

```dart
final path = Path()
  ..moveTo(start.dx, baselineY)
  ..lineTo(start.dx, points.first.dy);

// add interpolated curve through points (reuse InterpolationGeometry)

path
  ..lineTo(end.dx, baselineY)
  ..close();

canvas.drawPath(path, Paint()
  ..color = isAbove ? effectiveAboveColor : effectiveBelowColor
  ..style = PaintingStyle.fill);
```

`effectiveAboveColor` = `aboveBaselineFillColor ?? series.color.withOpacity(series.fillOpacity)`  
`effectiveBelowColor` = `belowBaselineFillColor ?? series.color.withOpacity(series.fillOpacity)`

### Step 4 — Draw the series line on top

Unchanged from existing rendering — the stroke is drawn last over the fill.

### Interaction with segment-style overrides

When `baselineValue` is non-null, `_paintAreaSeriesBaseline` handles the fill entirely. Per-point `segmentStyle` overrides are ignored for the fill (the `aboveBaselineFillColor`/`belowBaselineFillColor` fields govern all fill colour). The series stroke is drawn after the fill using the single-colour path, so stroke colour overrides from `segmentStyle` are also not applied in baseline mode. This is a deliberate YAGNI simplification — combining the two features can be revisited if needed.

### Interpolation compatibility

For `linear` interpolation the walk operates directly on data plot points.  
For `bezier`, `monotone`, and `stepped`, `InterpolationGeometry` already produces a dense polyline of output points — the same walk is applied to those output points, so crossing detection works identically across all interpolation modes.

---

## Files

| File | Change |
|------|--------|
| `lib/src/models/chart_series.dart` | Add `baselineValue`, `aboveBaselineFillColor`, `belowBaselineFillColor` to `AreaChartSeries`; update constructor, `copyWith`, `==`, `hashCode`, `toString` |
| `lib/src/elements/series_element.dart` | Add `_paintAreaSeriesBaseline`; call it from the area-series dispatch when `baselineValue != null` |

No other files require changes.

---

## Testing

Unit tests in `test/unit/models/area_chart_series_baseline_test.dart`:

- `baselineValue` null → existing behaviour (model fields carry through unchanged)
- `copyWith` round-trips all three fields
- `==` / `hashCode` distinguish non-null `baselineValue` from null

Widget / golden tests are out of scope for this spec.
