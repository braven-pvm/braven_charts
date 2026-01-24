# Data Model: Multi-Series Rendering Improvements

**Feature**: 002-multi-series-rendering-fix  
**Date**: 2026-01-23  
**Status**: Complete

## New Entities

### BarGroupInfo

**Purpose**: Metadata for positioning a bar series within a group of bar series at the same X-position.

| Field   | Type     | Description                                           | Constraints       |
| ------- | -------- | ----------------------------------------------------- | ----------------- |
| `index` | `int`    | 0-based index of this bar series among all bar series | >= 0, < count     |
| `count` | `int`    | Total number of bar series in the chart               | >= 1              |
| `gap`   | `double` | Pixels between adjacent bars within a group           | >= 0, default 2.0 |

**Immutability**: This class is immutable (all fields final).

**Usage Context**: Created during element generation, passed to `SeriesElement`, used during `_paintBarSeries()`.

```dart
class BarGroupInfo {
  const BarGroupInfo({
    required this.index,
    required this.count,
    this.gap = 2.0,
  });

  final int index;
  final int count;
  final double gap;

  /// Calculate the X-offset for this bar within its group
  double calculateOffset(double barWidth) {
    final effectiveWidth = barWidth + gap;
    final totalWidth = effectiveWidth * count - gap;
    final startOffset = -totalWidth / 2 + barWidth / 2;
    return startOffset + index * effectiveWidth;
  }
}
```

## Modified Entities

### SeriesElement

**Change**: Add optional `barGroupInfo` field.

| Field          | Type            | Description                    | Change Type    |
| -------------- | --------------- | ------------------------------ | -------------- |
| `barGroupInfo` | `BarGroupInfo?` | Bar group positioning metadata | NEW (optional) |

**Impact**: Nullable field, backward compatible. Only populated for `BarChartSeries`.

### DataRange (existing)

**Purpose**: Represents a range of data values (min/max) for an axis.

| Field | Type     | Description                |
| ----- | -------- | -------------------------- |
| `min` | `double` | Minimum value of the range |
| `max` | `double` | Maximum value of the range |

**Usage Context**: Returned by `computeAxisBounds()`, now also supports zoomed ranges.

## Method Signature Changes

### MultiAxisManager.computeAxisBounds()

**Current Signature**:

```dart
Map<String, DataRange> computeAxisBounds({
  ChartTransform? transform,
  ChartTransform? originalTransform,
  bool forceFullBounds = false,
});
```

**New Signature**:

```dart
Map<String, DataRange> computeAxisBounds({
  ChartTransform? transform,
  ChartTransform? originalTransform,
  bool forceFullBounds = false,
  bool forPainting = false,  // NEW
});
```

**Parameter Description**:

- `forPainting`: When `true` AND viewport is zoomed, returns bounds that match the visible portion of data rather than full data bounds. Used for series rendering transforms.

## State Transitions

### Viewport Zoom State

```
INITIAL (zoom = 1.0)
    │
    ├── User mouse wheel zoom ──► ZOOMED (zoom > 1.0)
    │                                  │
    │                                  ├── Y-scrollbar edge drag ──► Y-ZOOMED
    │                                  │
    │                                  └── Reset zoom ──► INITIAL
    │
    └── Pan (no zoom change) ──► PANNED (same zoom level)
```

### Series Paint Transform (perSeries mode)

```
1. computeAxisBounds(forPainting: true) → zoomedBounds per axis
2. For each series:
   a. Get axisId from seriesToAxisMap
   b. Get bounds for axisId
   c. Create perSeriesTransform with zoomed Y bounds
   d. series.updateTransform(perSeriesTransform)
   e. series.paint(canvas, size)
```

## Validation Rules

1. **BarGroupInfo.index**: Must be >= 0 and < count
2. **BarGroupInfo.count**: Must be >= 1
3. **BarGroupInfo.gap**: Must be >= 0
4. **Bar width minimum**: Enforced at 4.0 pixels in paint method
5. **Axis bounds**: forPainting bounds must be subset of full bounds when zoomed
