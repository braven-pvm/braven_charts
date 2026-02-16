# Data Model: Segment & Area Data Analysis

**Feature**: `006-segment-area-analysis` | **Date**: 2026-02-14

---

## Entity Relationship Diagram

```
┌─────────────────┐       ┌─────────────────────┐
│   DataRegion    │       │    RegionSummary     │
├─────────────────┤       ├─────────────────────┤
│ id: String      │◄──────│ region: DataRegion   │
│ label: String?  │  1:1  │ seriesSummaries:     │
│ startX: double  │       │   Map<String,        │
│ endX: double    │       │   SeriesRegionSummary>│
│ source: enum    │       └─────────────────────┘
│ seriesData:     │                │
│   Map<String,   │                │ 1:N
│   List<Point>>  │                ▼
└─────────────────┘       ┌─────────────────────┐
        │                 │ SeriesRegionSummary  │
        │                 ├─────────────────────┤
        │                 │ seriesId: String     │
        │                 │ seriesName: String?  │
        │                 │ unit: String?        │
        │                 │ count: int           │
        │                 │ min: double          │
        │                 │ max: double          │
        │                 │ sum: double          │
        │                 │ average: double      │
        │                 │ range: double        │
        │                 │ stdDev: double?      │
        │                 │ firstY: double?      │
        │                 │ lastY: double?       │
        │                 │ delta: double?       │
        │                 │ duration: double     │
        │                 └─────────────────────┘
        │
        │ uses
        ▼
┌─────────────────┐       ┌─────────────────────┐
│ DataRegionSource│       │ RegionSummaryConfig  │
│ (enum)          │       ├─────────────────────┤
├─────────────────┤       │ metrics: Set<enum>   │
│ rangeAnnotation │       │ valueFormatter: Fn   │
│ segment         │       │ position: enum       │
│ boxSelect       │       └─────────────────────┘
└─────────────────┘              │
                                 │ uses
                                 ▼
                        ┌─────────────────────┐
                        │ RegionMetric (enum)  │
                        ├─────────────────────┤
                        │ min                  │
                        │ max                  │
                        │ average              │
                        │ sum                  │
                        │ count                │
                        │ range                │
                        │ stdDev               │
                        │ delta                │
                        │ firstY               │
                        │ lastY                │
                        │ duration             │
                        └─────────────────────┘
```

---

## Entities

### 1. DataRegion

A contiguous X-range of interest within a chart, representing the area covered by a range annotation, a visual segment group, or an interactive box-select.

| Field        | Type                                | Nullable | Description                                                                                                                                            |
| ------------ | ----------------------------------- | -------- | ------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `id`         | `String`                            | No       | Unique identifier. For annotations: annotation ID. For segments: `segment_{seriesId}_{startIndex}`. For box-select: generated UUID or timestamp-based. |
| `label`      | `String`                            | Yes      | Human-readable label. Set from annotation label, null for segments and box-select.                                                                     |
| `startX`     | `double`                            | No       | Inclusive start of the X-range in data coordinates.                                                                                                    |
| `endX`       | `double`                            | No       | Inclusive end of the X-range in data coordinates.                                                                                                      |
| `source`     | `DataRegionSource`                  | No       | How this region was created.                                                                                                                           |
| `seriesData` | `Map<String, List<ChartDataPoint>>` | No       | Filtered data per series. Key = series ID, Value = data points within [startX, endX]. Empty map if no data in range.                                   |

**Validation Rules**:

- `startX <= endX` (invariant)
- `seriesData` values contain only points where `startX <= point.x <= endX`
- `id` must be non-empty

**Equality**: By `id`, `startX`, `endX`, `source`. Excludes `seriesData` (derived).

**Lifecycle**: Created on selection event, dereferenced on deselection. No persistence.

---

### 2. DataRegionSource (enum)

| Value             | Description                                                |
| ----------------- | ---------------------------------------------------------- |
| `rangeAnnotation` | Created from tapping a vertical `RangeAnnotation`          |
| `segment`         | Created from tapping a point within a styled segment group |
| `boxSelect`       | Created from completing a box-select drag interaction      |

---

### 3. SeriesRegionSummary

Pre-computed statistics for a single series within a single `DataRegion`.

| Field        | Type     | Nullable | Description                                                                  |
| ------------ | -------- | -------- | ---------------------------------------------------------------------------- |
| `seriesId`   | `String` | No       | The series this summary covers.                                              |
| `seriesName` | `String` | Yes      | Display name of the series (from `ChartSeries.name`).                        |
| `unit`       | `String` | Yes      | Unit label (from Y-axis config, e.g., "W", "%", "bpm").                      |
| `count`      | `int`    | No       | Number of data points in the region for this series.                         |
| `min`        | `double` | No       | Minimum Y value.                                                             |
| `max`        | `double` | No       | Maximum Y value.                                                             |
| `sum`        | `double` | No       | Sum of all Y values.                                                         |
| `average`    | `double` | No       | Arithmetic mean of Y values (`sum / count`).                                 |
| `range`      | `double` | No       | `max - min`.                                                                 |
| `stdDev`     | `double` | Yes      | Population standard deviation. Null if `count < 2`.                          |
| `firstY`     | `double` | Yes      | Y value of the first point in the region (by X order). Null if `count == 0`. |
| `lastY`      | `double` | Yes      | Y value of the last point in the region (by X order). Null if `count == 0`.  |
| `delta`      | `double` | Yes      | `lastY - firstY`. Null if `count < 2`.                                       |
| `duration`   | `double` | No       | `endX - startX` from the parent region's bounds (in data units).             |

**Validation Rules**:

- `count >= 0`
- If `count == 0`: min/max/sum/average/range are 0.0, all nullable fields are null
- If `count == 1`: stdDev and delta are null
- `average == sum / count` (when count > 0)
- All values use original (non-normalized) data

---

### 4. RegionSummary

Aggregated summary for an entire `DataRegion` across all series.

| Field             | Type                               | Nullable | Description                                                                          |
| ----------------- | ---------------------------------- | -------- | ------------------------------------------------------------------------------------ |
| `region`          | `DataRegion`                       | No       | The region these summaries cover.                                                    |
| `seriesSummaries` | `Map<String, SeriesRegionSummary>` | No       | Per-series summaries. Key = series ID. Only includes series with data in the region. |

---

### 5. RegionSummaryConfig

Configuration for the opt-in visual summary overlay.

| Field            | Type                               | Nullable | Default                          | Description                                                                  |
| ---------------- | ---------------------------------- | -------- | -------------------------------- | ---------------------------------------------------------------------------- |
| `metrics`        | `Set<RegionMetric>`                | No       | `{min, max, average}`            | Which metrics to display in the overlay card.                                |
| `valueFormatter` | `String Function(double, String?)` | Yes      | `null` (uses default formatting) | Custom formatter for metric values. Receives value and optional unit string. |
| `position`       | `RegionSummaryPosition`            | No       | `aboveRegion`                    | Where to position the overlay card relative to the region.                   |

---

### 6. RegionMetric (enum)

Selectable metrics for the summary overlay display.

| Value      | Display Label | Description        |
| ---------- | ------------- | ------------------ |
| `min`      | "Min"         | Minimum Y value    |
| `max`      | "Max"         | Maximum Y value    |
| `average`  | "Avg"         | Arithmetic mean    |
| `sum`      | "Sum"         | Total sum          |
| `count`    | "Count"       | Number of points   |
| `range`    | "Range"       | Max − Min          |
| `stdDev`   | "Std Dev"     | Standard deviation |
| `delta`    | "Δ"           | Last − First       |
| `firstY`   | "First"       | First Y value      |
| `lastY`    | "Last"        | Last Y value       |
| `duration` | "Duration"    | X-range span       |

---

### 7. RegionSummaryPosition (enum)

| Value          | Description                                                                             |
| -------------- | --------------------------------------------------------------------------------------- |
| `aboveRegion`  | Centered above the highlighted region. Falls back to `insideTop` if insufficient space. |
| `insideTop`    | Inside the region, aligned to the top.                                                  |
| `insideBottom` | Inside the region, aligned to the bottom.                                               |

---

## State Transitions

```
          ┌──────────────────────────────────────────────┐
          │                                              │
          ▼                                              │
   ┌─────────────┐  tap annotation   ┌───────────────┐  │
   │  No Region  │ ─────────────────▶│ Region Active │──┘
   │  Selected   │  tap segment      │  (DataRegion  │  deselect /
   │             │  box-select done  │   populated)  │  tap elsewhere /
   │             │◀──────────────────│               │  new selection
   └─────────────┘   clear/dismiss   └───────────────┘
                                            │
                                            │ computeRegionSummaries()
                                            ▼
                                     ┌───────────────┐
                                     │ Summary Ready │
                                     │ (RegionSummary│
                                     │  computed)    │
                                     └───────────────┘
```

- Selection is single-region only in V1. New selection replaces previous.
- Summary is computed on-demand, not automatically on selection.
- Box-select regions are transient — cleared on next interaction.
