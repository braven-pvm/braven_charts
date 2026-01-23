# 002-rendering-fix: Sprint Plan

## Sprint Configuration

**Sprint ID**: 002-rendering-fix  
**Duration**: 2-3 days  
**Methodology**: TDD (Red-Green-Refactor)

---

## Phase Overview

```
Phase 1: Grouped Bar Charts (5.5 hours)
├── Task 1.1: BarGroupInfo class
├── Task 1.2: SeriesElement integration
├── Task 1.3: Paint offset calculation
├── Task 1.4: Element generator update
├── Task 1.5: Unit tests
└── Task 1.6: Demo verification

Phase 2: perSeries Y-Zoom Fix (9.5 hours)
├── Task 2.1: computeAxisBounds forPainting param
├── Task 2.2: Viewport-aware bounds logic
├── Task 2.3: Paint series update
├── Task 2.4: Crosshair/tooltip bounds
├── Task 2.5: Integration tests
└── Task 2.6: Demo verification

Phase 3: Integration & Polish (3.5 hours)
├── Task 3.1: Regression testing
├── Task 3.2: Performance benchmarks
└── Task 3.3: Documentation
```

---

## Detailed Task Breakdown

### Phase 1: Grouped Bar Charts

#### Task 1.1: BarGroupInfo Class

**File**: `lib/src/models/bar_group_info.dart` (new)

```dart
/// Metadata for positioning a bar within a grouped bar chart.
@immutable
class BarGroupInfo {
  const BarGroupInfo({
    required this.index,
    required this.count,
    this.gapPixels = 2.0,
  });

  /// Zero-based index of this bar series among all bar series.
  final int index;

  /// Total number of bar series in the chart.
  final int count;

  /// Gap between adjacent bars in pixels.
  final double gapPixels;

  /// Calculates the horizontal offset for this bar within the group.
  double calculateOffset(double totalGroupWidth) {
    if (count <= 1) return 0.0;
    final barWidth = (totalGroupWidth - (gapPixels * (count - 1))) / count;
    final groupStart = -totalGroupWidth / 2;
    return groupStart + (index * (barWidth + gapPixels)) + (barWidth / 2);
  }

  /// Calculates individual bar width given total group width.
  double calculateBarWidth(double totalGroupWidth) {
    if (count <= 1) return totalGroupWidth;
    return (totalGroupWidth - (gapPixels * (count - 1))) / count;
  }
}
```

**Tests**:

- Single bar (count=1) returns zero offset
- Two bars positioned correctly
- Gap calculation accurate

---

#### Task 1.2: SeriesElement Integration

**File**: `lib/src/elements/series_element.dart`

Changes:

1. Add `BarGroupInfo? barGroupInfo` parameter to constructor
2. Store in instance field
3. Pass to `_paintBarSeries()`

---

#### Task 1.3: Paint Offset Calculation

**File**: `lib/src/elements/series_element.dart`

Modify `_paintBarSeries()`:

```dart
void _paintBarSeries(Canvas canvas, BarChartSeries series, Color baseColor) {
  // ... existing opacity/override code ...

  // Calculate base bar width (existing logic)
  double baseBarWidth = /* existing calculation */;

  // Apply grouping if multiple bar series
  double effectiveBarWidth = baseBarWidth;
  double xOffset = 0.0;

  if (barGroupInfo != null && barGroupInfo!.count > 1) {
    effectiveBarWidth = barGroupInfo!.calculateBarWidth(baseBarWidth);
    xOffset = barGroupInfo!.calculateOffset(baseBarWidth);
  }

  // Paint bars with offset
  for (final point in series.points) {
    final plotPos = _currentTransform.dataToPlot(point.x, point.y);
    final zeroY = _currentTransform.dataToPlot(point.x, 0).dy;

    final rect = Rect.fromLTRB(
      plotPos.dx + xOffset - effectiveBarWidth / 2,  // Apply offset!
      plotPos.dy,
      plotPos.dx + xOffset + effectiveBarWidth / 2,
      zeroY,
    );
    canvas.drawRect(rect, barPaint);
  }
}
```

---

#### Task 1.4: Element Generator Update

**File**: `lib/src/rendering/chart_render_box.dart` (or element generator)

Compute bar series metadata during element creation:

```dart
// Count bar series
final barSeries = series.whereType<BarChartSeries>().toList();
final barSeriesCount = barSeries.length;
var barSeriesIndex = 0;

for (final s in series) {
  BarGroupInfo? groupInfo;
  if (s is BarChartSeries && barSeriesCount > 1) {
    groupInfo = BarGroupInfo(
      index: barSeriesIndex++,
      count: barSeriesCount,
    );
  }

  elements.add(SeriesElement(
    series: s,
    barGroupInfo: groupInfo,
    // ... other params
  ));
}
```

---

### Phase 2: perSeries Y-Zoom Fix

#### Task 2.1: computeAxisBounds forPainting Parameter

**File**: `lib/src/rendering/modules/multi_axis_manager.dart`

Add parameter to distinguish display bounds from painting bounds:

```dart
Map<String, DataRange> computeAxisBounds({
  ChartTransform? transform,
  ChartTransform? originalTransform,
  bool forceFullBounds = false,
  bool forPainting = false,  // NEW
}) {
  // When forPainting=true:
  // - Apply viewport zoom to computed bounds
  // - Series will render zoomed view correctly
}
```

---

#### Task 2.2: Viewport-Aware Bounds Logic

**File**: `lib/src/rendering/modules/multi_axis_manager.dart`

Implement zoom-aware bounds for painting:

```dart
// After computing full bounds...
if (forPainting && isViewportTransformed) {
  // Get zoom ratios from normalized transform
  final yZoomRatio = (t.dataYMax - t.dataYMin) / 1.1;  // 1.1 = full buffer range
  final yPanOffset = (t.dataYMin + 0.05) / 1.1;  // Normalized pan position

  // Apply to each axis
  final fullRange = fullMax - fullMin;
  final zoomedMin = fullMin + (yPanOffset * fullRange);
  final zoomedMax = zoomedMin + (yZoomRatio * fullRange);

  bounds[axis.id] = DataRange(min: zoomedMin, max: zoomedMax);
}
```

---

#### Task 2.3: Paint Series Update

**File**: `lib/src/rendering/chart_render_box.dart`

Use painting-aware bounds:

```dart
void _paintSeries(Canvas canvas, Size size) {
  // Use forPainting=true for series transforms
  final Map<String, DataRange>? axisBounds =
      (_multiAxisManager.isMultiAxisNormalizationActive())
          ? _computeAxisBounds(forPainting: true)  // CHANGED
          : null;

  // ... rest unchanged
}
```

---

#### Task 2.4: Crosshair/Tooltip Bounds

**File**: `lib/src/rendering/modules/crosshair_renderer.dart`

Ensure crosshair uses display bounds (not painting bounds) for value labels:

```dart
// Crosshair should show data values, not zoomed viewport values
// Verify it uses computeAxisBounds(forPainting: false)
```

---

## Verification Checklist

### Phase 1 Complete When:

- [ ] Two bar series render side-by-side
- [ ] Gap between bars is visible and consistent
- [ ] Single bar series unchanged (no regression)
- [ ] Bar width scales with series count
- [ ] All existing bar tests pass

### Phase 2 Complete When:

- [ ] Mouse wheel Y-zoom works with perSeries mode
- [ ] Scrollbar Y-zoom works with perSeries mode
- [ ] Y-axis labels show zoomed range
- [ ] Crosshair shows correct data values after zoom
- [ ] Zoom center preserved (zooms toward cursor)
- [ ] Pan works correctly after Y-zoom

### Sprint Complete When:

- [ ] `flutter analyze` passes with no issues
- [ ] All tests pass
- [ ] FitDistributionPage demo works correctly
- [ ] No performance regression (60fps maintained)

---

## Demo Verification

Use `example/lib/showcase/pages/fit_distribution_page.dart`:

1. **Bar Grouping**: Change both series to `BarChartSeries` and verify adjacent rendering
2. **Y-Zoom**: With current Line+Bar setup, verify:
   - Shift+scroll zooms both axes
   - Y scrollbar edge drag zooms vertically
   - Chart data scales with zoom
