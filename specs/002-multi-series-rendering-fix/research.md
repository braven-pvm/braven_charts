# Research: Multi-Series Rendering Improvements

**Feature**: 002-multi-series-rendering-fix  
**Date**: 2026-01-23  
**Status**: Complete

## Research Tasks

### 1. Grouped Bar Chart Rendering Approach

**Question**: What is the best approach to render multiple bar series adjacent to each other without overlapping?

**Decision**: Pass bar series metadata (index, count) to SeriesElement during construction (Design Option A)

**Rationale**:

- Minimal architectural change to existing rendering pipeline
- No new classes required beyond simple `BarGroupInfo` data class
- Natural fit with existing element-based rendering where each series is wrapped in `SeriesElement`
- Clean separation of concerns - no global state needed
- O(n) computation where n = series count, meeting performance requirements

**Alternatives Considered**:

1. **Shared BarPositioner class** (Option B) - Matches legacy architecture and supports stacked bars, but adds coordination overhead and additional class complexity
2. **Direct calculation in paint method** - Simpler but requires global knowledge of all bar series during paint

**Implementation Pattern**:

```dart
class BarGroupInfo {
  final int index;    // 0-based index of this bar series among all bar series
  final int count;    // Total number of bar series
  final double gap;   // Pixels between bars within group
}
```

### 2. Y-Zoom with perSeries Normalization

**Question**: How to make vertical zoom work correctly when using `NormalizationMode.perSeries` with multiple Y-axes?

**Decision**: Hybrid approach combining viewport-aware axis bounds (Option C) with transform denormalization (Option D)

**Rationale**:

- Option C provides the foundation by adding a `forPainting` parameter to `computeAxisBounds()`
- Option D applies zoomed bounds correctly during series painting
- Combined approach ensures:
  - Axis labels show correct zoomed range
  - Series rendering respects zoom viewport
  - Crosshair/tooltip coordinates remain accurate

**Root Cause Analysis**:
The current issue occurs because:

1. Zoom modifies global `_transform.dataYMin/dataYMax`
2. But `computeAxisBounds(forceFullBounds: true)` ignores zoomed bounds
3. Per-series transforms receive FULL axis bounds, not zoomed bounds
4. Visual zoom doesn't happen even though scrollbar position updates

**Alternatives Considered**:

1. **Modify ChartTransform.zoom()** - Would affect all transform uses, too broad
2. **Store separate zoomed bounds per axis** - Adds state complexity
3. **Option C only** - Doesn't fully address the painting transform issue

**Implementation Pattern**:

```dart
// In MultiAxisManager.computeAxisBounds()
Map<String, DataRange> computeAxisBounds({
  bool forPainting = false,  // NEW: use zoomed bounds for series rendering
}) {
  if (forPainting && isZoomed) {
    return zoomedBounds;
  }
  return fullBounds;
}
```

### 3. Bar Width Calculation

**Question**: How to calculate appropriate bar widths when many series exist?

**Decision**: Scale bar width proportionally within group, enforce 4px minimum

**Rationale**:

- Group width is determined by data point spacing (existing `barWidth` calculation)
- Individual bar width = (groupWidth - totalGaps) / seriesCount
- Minimum 4px prevents bars from becoming invisible
- When minimum would be violated, bars overlap slightly (better than invisibility)

**Formula**:

```
effectiveBarWidth = max(4.0, (groupWidth - (count - 1) * gap) / count)
barOffset = (index - (count - 1) / 2) * (effectiveBarWidth + gap)
```

### 4. Non-Overlapping X-Values Behavior

**Question**: How should bars render when series have different X-value sets?

**Decision**: Grouping applies only where X-values match; bars at unique X-positions render centered

**Rationale**:

- Matches Excel/Google Sheets behavior
- Avoids artificial gaps where only one series has data
- Simplifies implementation - no need to track cross-series X-value presence
- Per clarification session 2026-01-23

### 5. Existing Zoom Limits

**Question**: Should new zoom limits be implemented for Y-axis?

**Decision**: Use existing ViewportConstraints zoom limits

**Rationale**:

- Existing zoom limits already work for X-axis
- Same constraints should apply to Y-axis zoom
- No new code needed for limit enforcement
- Per clarification session 2026-01-23

## Files to Modify

| File                                                | Change Type | Description                                              |
| --------------------------------------------------- | ----------- | -------------------------------------------------------- |
| `lib/src/models/bar_group_info.dart`                | CREATE      | New BarGroupInfo class                                   |
| `lib/src/elements/series_element.dart`              | UPDATE      | Accept BarGroupInfo, modify `_paintBarSeries()`          |
| `lib/src/rendering/modules/multi_axis_manager.dart` | UPDATE      | Add `forPainting` parameter to computeAxisBounds         |
| `lib/src/rendering/chart_render_box.dart`           | UPDATE      | Pass BarGroupInfo, use forPainting bounds                |
| `lib/src/braven_chart_plus.dart`                    | UPDATE      | Compute bar series index/count during element generation |

## Performance Considerations

1. **Bar grouping calculation**: O(n) where n = series count, performed once during element generation
2. **No per-frame allocations**: BarGroupInfo created with elements, not during paint
3. **Cache invalidation**: Existing triggers remain unchanged (data, transform, theme)
4. **Transform computation**: Minimal overhead for viewport-aware bounds calculation

## Risk Assessment

| Risk                                  | Likelihood | Impact | Mitigation                            |
| ------------------------------------- | ---------- | ------ | ------------------------------------- |
| Breaking single-axis charts           | Low        | High   | Comprehensive regression tests        |
| Performance degradation               | Low        | Medium | Benchmark before/after                |
| Crosshair/tooltip coordinate mismatch | Medium     | Medium | Test interactions after zoom          |
| Complex edge cases in normalization   | Medium     | Medium | Incremental implementation with tests |
