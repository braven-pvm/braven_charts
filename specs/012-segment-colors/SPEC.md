# Feature 012: Segment Color Overrides

## Overview

Enable per-segment color and style customization for line chart series, allowing specific sections of a chart line to be rendered in different colors while maintaining smooth curve continuity for bezier/monotone interpolations.

## Status

| Aspect | Status |
|--------|--------|
| Design | ✅ Complete |
| Implementation | ✅ Complete |
| Tests | ✅ Complete |
| Documentation | ✅ Complete |

---

## 1. Problem Statement

### Current Limitation

Chart series lines are rendered with a **single color** defined at the series level:

```dart
LineChartSeries(
  id: 'power',
  color: Colors.blue,  // Entire line is blue
  points: [...],
)
```

### Required Capability

Users need to **highlight specific segments** of a line in different colors:
- Segments above a threshold (e.g., red when power > 100W)
- Categorical regions (e.g., different phases of an experiment)
- Anomaly visualization (e.g., error regions in orange)
- Time-based coloring (e.g., each day different color)

### Visual Example

```
Data Points:    P0 -------- P1 -------- P2 -------- P3 -------- P4
Default:        ═══════════════════════════════════════════════════
                              ALL BLUE

With Overrides: ════════════════════════  ════════════════════════
                     BLUE        RED            BLUE
                           (P1→P2 highlighted)
```

---

## 2. Requirements

### 2.1 Functional Requirements

| ID | Requirement | Priority |
|----|-------------|----------|
| FR-01 | Support per-segment color override | MUST |
| FR-02 | Support per-segment stroke width override | SHOULD |
| FR-03 | Color transitions must be sharp (not gradient) at data point boundaries | MUST |
| FR-04 | Work with all interpolation modes (linear, bezier, stepped, monotone) | MUST |
| FR-05 | Bezier curves must remain smooth at color transition points | MUST |
| FR-06 | Support streaming data with segment styles | SHOULD |
| FR-07 | Provide helper methods for common use cases (color by index, color by X-range) | SHOULD |

### 2.2 Performance Requirements

| ID | Requirement | Priority |
|----|-------------|----------|
| PR-01 | No performance impact when segment styles are NOT used (fast path) | MUST |
| PR-02 | Batch consecutive same-color segments into single drawPath() calls | MUST |
| PR-03 | Cache region analysis to avoid re-computation on every paint | SHOULD |
| PR-04 | Support 10,000+ points with scattered overrides at 60fps | MUST |
| PR-05 | Worst case (all different colors) must still render at 30fps minimum | SHOULD |

### 2.3 Non-Functional Requirements

| ID | Requirement | Priority |
|----|-------------|----------|
| NR-01 | API must be intuitive and follow existing patterns | MUST |
| NR-02 | No breaking changes to existing ChartDataPoint usage | MUST |
| NR-03 | Style on last point should be ignored (no segment follows it) | MUST |
| NR-04 | Null segment style means "use series/theme default" | MUST |

---

## 3. Design Decisions

### 3.1 Where to Store Segment Style

**Decision**: Store `segmentStyle` on `ChartDataPoint`

**Rationale**:
- Natural mental model: "this point starts a styled segment"
- Works seamlessly with streaming (each point carries its own style)
- No separate data structure to maintain in sync with points
- Minimal API surface (one optional field)

**Rejected Alternatives**:
1. **Map<int, SegmentStyle> on Series** - Index-based, breaks on reorder/filter
2. **List<SegmentColorOverride> with X-ranges** - Complex, harder to maintain

### 3.2 SegmentStyle vs Just Color

**Decision**: Create `SegmentStyle` class with `color` and `strokeWidth`

**Rationale**:
- Extensible for future properties (dash pattern, opacity, etc.)
- Single responsibility - styling concern is encapsulated
- Convenience constructors (`SegmentStyle.color(...)`) keep simple cases simple

### 3.3 Color Transition Type

**Decision**: Sharp transitions at data point boundaries

**Rationale**:
- Clearer visual distinction between regions
- Simpler implementation (no gradient calculation)
- User specifically requested sharp transitions
- Gradients can be added later as `SegmentStyle.transition` if needed

### 3.4 Bezier Continuity at Color Boundaries

**Decision**: Calculate control points using full point array, but only draw segments within color region

**Rationale**:
```
Problem: Bezier from P1→P2 needs P0 (for entry tangent) and P3 (for exit tangent)
         If P1 starts a new color, P0 is in previous color region.

Solution: When building path for Region 2 (starting at P1):
          - Use allPoints[0..n] for tangent calculations
          - Only add path segments for points within Region 2
          
Result:   Curve is mathematically continuous (smooth)
          Color changes sharply at P1
          Tangent at P1 is identical from both sides
```

### 3.5 Performance Optimization Strategy

**Decision**: Three-tier optimization

1. **Fast Path**: If no points have `segmentStyle`, use existing single-path rendering
2. **Region Batching**: Group consecutive same-style segments into single paths
3. **Caching**: Cache region analysis and paths (invalidate on data/transform change)

**Performance Characteristics**:

| Scenario | Regions | drawPath() calls | Notes |
|----------|---------|------------------|-------|
| No overrides | 1 | 1 | Fast path |
| 1 override mid-series | 3 | 3 | Before, override, after |
| 5 consecutive overrides | 3 | 3 | Batched together |
| 100 scattered overrides | ~201 | ~201 | Worst realistic case |

---

## 4. Data Model

### 4.1 SegmentStyle Class

**File**: `lib/src/models/segment_style.dart`

```dart
/// Styling override for a line segment.
///
/// When applied to a [ChartDataPoint], this style affects the segment
/// from that point to the next point in the series.
///
/// Example:
/// ```dart
/// ChartDataPoint(
///   x: 10.0,
///   y: 50.0,
///   segmentStyle: SegmentStyle(color: Colors.red, strokeWidth: 3.0),
/// )
/// ```
@immutable
class SegmentStyle {
  /// Creates a segment style with optional color and stroke width overrides.
  const SegmentStyle({
    this.color,
    this.strokeWidth,
  });

  /// Creates a segment style with only a color override.
  const SegmentStyle.color(Color this.color) : strokeWidth = null;

  /// Creates a segment style with only a stroke width override.
  const SegmentStyle.strokeWidth(double this.strokeWidth) : color = null;

  /// Color override for this segment. If null, uses series default.
  final Color? color;

  /// Stroke width override for this segment. If null, uses series default.
  final double? strokeWidth;

  /// Whether this style has any overrides.
  bool get hasOverrides => color != null || strokeWidth != null;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SegmentStyle &&
          runtimeType == other.runtimeType &&
          color == other.color &&
          strokeWidth == other.strokeWidth;

  @override
  int get hashCode => Object.hash(color, strokeWidth);

  @override
  String toString() => 'SegmentStyle(color: $color, strokeWidth: $strokeWidth)';
}
```

### 4.2 ChartDataPoint Updates

**File**: `lib/src/models/chart_data_point.dart` (modify existing)

Add `segmentStyle` field:

```dart
class ChartDataPoint {
  const ChartDataPoint({
    required this.x,
    required this.y,
    this.timestamp,
    this.label,
    this.metadata,
    this.segmentStyle,  // NEW
  });

  // ... existing fields ...

  /// Optional style override for the segment starting at this point.
  ///
  /// This affects the line segment from this point to the next point.
  /// If null, the series default style (color, stroke width) is used.
  ///
  /// Note: Setting this on the last point in a series has no effect,
  /// as there is no segment following the last point.
  final SegmentStyle? segmentStyle;

  ChartDataPoint copyWith({
    double? x,
    double? y,
    DateTime? timestamp,
    String? label,
    Map<String, dynamic>? metadata,
    SegmentStyle? segmentStyle,
    bool clearSegmentStyle = false,  // Allow explicitly clearing
  }) {
    return ChartDataPoint(
      x: x ?? this.x,
      y: y ?? this.y,
      timestamp: timestamp ?? this.timestamp,
      label: label ?? this.label,
      metadata: metadata ?? this.metadata,
      segmentStyle: clearSegmentStyle ? null : (segmentStyle ?? this.segmentStyle),
    );
  }
}
```

### 4.3 Helper Extensions

**File**: `lib/src/models/segment_style.dart` (same file, extension at bottom)

```dart
/// Extension methods for applying segment colors to LineChartSeries.
extension SegmentColorExtensions on LineChartSeries {
  /// Returns true if any point has a segment style override.
  bool get hasSegmentOverrides => points.any((p) => p.segmentStyle != null);

  /// Creates a copy with segment style at specified indices.
  LineChartSeries withSegmentStyles(Map<int, SegmentStyle> overrides) {
    if (overrides.isEmpty) return this;

    final newPoints = List<ChartDataPoint>.of(points);
    for (final entry in overrides.entries) {
      final index = entry.key;
      if (index >= 0 && index < newPoints.length - 1) {
        newPoints[index] = newPoints[index].copyWith(segmentStyle: entry.value);
      }
    }
    return copyWith(points: newPoints);
  }

  /// Creates a copy with segment colors at specified indices.
  LineChartSeries withSegmentColors(Map<int, Color> colors) {
    return withSegmentStyles(
      colors.map((index, color) => MapEntry(index, SegmentStyle.color(color))),
    );
  }

  /// Creates a copy with all segments in X-range styled.
  LineChartSeries withStyleInRange(double xStart, double xEnd, SegmentStyle style) {
    final newPoints = <ChartDataPoint>[];
    for (int i = 0; i < points.length; i++) {
      final point = points[i];
      final inRange = point.x >= xStart && point.x < xEnd;
      if (inRange) {
        newPoints.add(point.copyWith(segmentStyle: style));
      } else {
        newPoints.add(point);
      }
    }
    return copyWith(points: newPoints);
  }

  /// Creates a copy with color applied where condition is true.
  LineChartSeries withColorWhere(
    bool Function(ChartDataPoint point) condition,
    Color color,
  ) {
    final newPoints = points.map((point) {
      if (condition(point)) {
        return point.copyWith(segmentStyle: SegmentStyle.color(color));
      }
      return point;
    }).toList();
    return copyWith(points: newPoints);
  }
}
```

---

## 5. Rendering Implementation

### 5.1 Color Region Analysis

```dart
/// Represents a continuous region of same-styled segments.
class _StyleRegion {
  const _StyleRegion({
    required this.startIndex,
    required this.endIndex,
    required this.color,
    required this.strokeWidth,
  });

  /// Index of first point in region (segment starts here).
  final int startIndex;

  /// Index of last point in region (segment ends here, inclusive).
  final int endIndex;

  /// Effective color for this region.
  final Color color;

  /// Effective stroke width for this region.
  final double strokeWidth;

  /// Number of segments in this region.
  int get segmentCount => endIndex - startIndex;
}

/// Analyzes points to find continuous style regions.
List<_StyleRegion> _analyzeStyleRegions(
  List<ChartDataPoint> points,
  Color defaultColor,
  double defaultStrokeWidth,
) {
  if (points.length < 2) return [];

  final regions = <_StyleRegion>[];
  int regionStart = 0;

  // Get effective style for first segment
  Color currentColor = points[0].segmentStyle?.color ?? defaultColor;
  double currentWidth = points[0].segmentStyle?.strokeWidth ?? defaultStrokeWidth;

  for (int i = 1; i < points.length - 1; i++) {
    final style = points[i].segmentStyle;
    final pointColor = style?.color ?? defaultColor;
    final pointWidth = style?.strokeWidth ?? defaultStrokeWidth;

    // Check if style changed
    if (pointColor != currentColor || pointWidth != currentWidth) {
      // Close current region
      regions.add(_StyleRegion(
        startIndex: regionStart,
        endIndex: i,
        color: currentColor,
        strokeWidth: currentWidth,
      ));

      // Start new region
      regionStart = i;
      currentColor = pointColor;
      currentWidth = pointWidth;
    }
  }

  // Close final region
  regions.add(_StyleRegion(
    startIndex: regionStart,
    endIndex: points.length - 1,
    color: currentColor,
    strokeWidth: currentWidth,
  ));

  return regions;
}
```

### 5.2 SeriesElement Modifications

Key changes to `lib/src/elements/series_element.dart`:

1. Add cache fields for regions
2. Add `_hasSegmentOverrides()` fast-path check  
3. Add `_paintLineSeriesMultiStyle()` method
4. Add `_buildRegionPath()` with interpolation support
5. Extract bezier control point calculation for reuse

See Section 5 pseudocode in full spec for implementation details.

---

## 6. Implementation Checklist

### Phase 1: Data Model (Est: 1 hour)

- [ ] Create `lib/src/models/segment_style.dart`
  - [ ] SegmentStyle class with color, strokeWidth
  - [ ] Convenience constructors
  - [ ] == and hashCode
- [ ] Modify `lib/src/models/chart_data_point.dart`
  - [ ] Add segmentStyle field
  - [ ] Update copyWith() with clearSegmentStyle option
  - [ ] Update == and hashCode to include segmentStyle
- [ ] Add extension methods to segment_style.dart
  - [ ] hasSegmentOverrides getter
  - [ ] withSegmentStyles()
  - [ ] withSegmentColors()
  - [ ] withStyleInRange()
  - [ ] withColorWhere()
- [ ] Export from braven_charts.dart

### Phase 2: Rendering (Est: 3 hours)

- [ ] Add _StyleRegion class to series_element.dart
- [ ] Add _analyzeStyleRegions() function
- [ ] Add caching fields to SeriesElement
  - [ ] _cachedRegions
  - [ ] _cachedHasOverrides
- [ ] Modify paint() to branch on _hasSegmentOverrides()
- [ ] Implement _paintLineSeriesMultiStyle()
- [ ] Implement _buildRegionPath() with interpolation support
- [ ] Implement/extract _calculateBezierControlPointsForSegment()
- [ ] Implement/extract _calculateMonotoneControlPointsForSegment()
- [ ] Update cache invalidation methods

### Phase 3: Testing (Est: 2 hours)

- [ ] Unit tests for SegmentStyle
- [ ] Unit tests for ChartDataPoint.segmentStyle
- [ ] Unit tests for _analyzeStyleRegions()
- [ ] Integration tests for rendering with all interpolation types
- [ ] Performance tests for fast path and multi-color paths

### Phase 4: Documentation & Demo (Est: 1 hour)

- [ ] Add demo to example app
- [ ] Update API documentation
- [ ] Add to CHANGELOG.md

---

## 7. Test Cases

### 7.1 Region Analysis Tests

| Test Case | Points | Expected Regions |
|-----------|--------|------------------|
| No overrides | [P0, P1, P2] | 1 region (0→2) |
| Single override at P1 | [P0, P1(red), P2, P3] | 3 regions |
| Consecutive overrides | [P0, P1(red), P2(red), P3] | 3 regions (red batched) |
| All different | [P0(red), P1(blue), P2(green)] | 3 regions |

### 7.2 Visual Tests

- Bezier curve smoothness at color boundaries (golden test)
- Linear interpolation color transitions
- Stepped interpolation color transitions
- Monotone interpolation color transitions

### 7.3 Performance Benchmarks

| Scenario | Points | Overrides | Target FPS |
|----------|--------|-----------|------------|
| Fast path | 10,000 | 0 | 60 |
| Few overrides | 10,000 | 10 | 60 |
| Many overrides | 10,000 | 100 | 60 |
| Worst case | 10,000 | 5,000 | 30 |

---

## 8. Future Enhancements (Out of Scope)

- Gradient transitions between segments
- Dash patterns per segment
- Segment opacity (separate from color alpha)
- Animated segment color transitions
- Click handling per segment

---

## 9. Appendix: Bezier Math Reference

### Catmull-Rom to Bezier Conversion

Given four points P0, P1, P2, P3, the Catmull-Rom spline through P1→P2 converts to cubic Bezier with control points:

```
CP1 = P1 + (P2 - P0) * tension / 6
CP2 = P2 - (P3 - P1) * tension / 6
```

Where tension is typically 0.5 for Catmull-Rom default.

### Why This Preserves Continuity

When we split rendering at P2 (color change):
- Region 1 path ends at P2, using CP2 calculated from [P1, P2, P3]
- Region 2 path starts at P2, using same tangent direction

The curve position and tangent at P2 are identical from both sides.
Only the color changes - the geometry remains smooth.
