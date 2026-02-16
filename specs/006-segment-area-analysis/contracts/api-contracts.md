# API Contracts: Segment & Area Data Analysis

**Feature**: `006-segment-area-analysis` | **Date**: 2026-02-14

These contracts define the public Dart API surface for the region analysis feature. All APIs are additions — no breaking changes to existing APIs.

---

## 1. New Widget Properties on BravenChartPlus

### 1.1 onRegionSelected Callback

```dart
/// Callback signature for region selection events.
/// Receives the selected DataRegion, or null when deselected.
typedef RegionSelectedCallback = void Function(DataRegion? region);
```

```dart
BravenChartPlus(
  /// Fired when a data region is selected or deselected.
  /// Triggers on: range annotation tap, segment tap, box-select completion.
  /// Fires with null when the region is cleared.
  RegionSelectedCallback? onRegionSelected,
)
```

**Contract**:

- MUST fire when a vertical RangeAnnotation is tapped, with the annotation's X-range as the DataRegion
- MUST fire when a styled segment point is tapped, with the segment group's X-range as the DataRegion
- MUST fire when a box-select drag completes, with the drag's X-range as the DataRegion
- MUST fire with `null` when the region is cleared (tap elsewhere, new selection)
- MUST NOT fire for non-vertical annotations (horizontal range annotations, point annotations, etc.)
- Existing `onAnnotationTap` callback continues to fire as before — `onRegionSelected` is additional

### 1.2 showRegionSummary Flag

```dart
BravenChartPlus(
  /// When true, selecting a region displays a summary overlay card.
  /// Default: false.
  bool showRegionSummary = false,
)
```

### 1.3 regionSummaryConfig

```dart
BravenChartPlus(
  /// Configuration for the summary overlay card appearance and content.
  /// Only used when showRegionSummary is true.
  RegionSummaryConfig? regionSummaryConfig,
)
```

### 1.4 customRegionAnalysis Hook

```dart
/// Callback for custom analysis extensions.
/// Receives the region data and built-in summary.
/// Returns a map of custom metric names to display values.
typedef CustomRegionAnalysisCallback = Map<String, String> Function(
  DataRegion region,
  RegionSummary summary,
);
```

```dart
BravenChartPlus(
  /// Custom analysis function invoked after built-in summary computation.
  /// Results are merged into the overlay display (if enabled).
  CustomRegionAnalysisCallback? customRegionAnalysis,
)
```

---

## 2. New State Properties on BravenChartPlusState

### 2.1 selectedDataRegions Getter

```dart
class BravenChartPlusState {
  /// Returns the currently selected DataRegion(s).
  /// Empty list when nothing is selected.
  /// Computed lazily — no cost until queried.
  List<DataRegion> get selectedDataRegions;
}
```

**Contract**:

- Returns empty list when no region is selected
- Returns single-element list in V1 (single-region selection)
- Lazily computes DataRegion from current coordinator selection state
- Uses original (non-normalized) data values

### 2.2 computeRegionSummaries Method

```dart
class BravenChartPlusState {
  /// Compute summaries for the given regions, or for the current selection if null.
  /// Returns empty list if no regions to summarize.
  List<RegionSummary> computeRegionSummaries([List<DataRegion>? regions]);
}
```

**Contract**:

- If `regions` is null, uses `selectedDataRegions`
- Returns one `RegionSummary` per input region
- Each summary contains per-series `SeriesRegionSummary` for all series with data in the region
- Computation is synchronous and O(k) where k is the number of points in the region

### 2.3 Overlay Display Methods

```dart
class BravenChartPlusState {
  /// Programmatically show the summary overlay for a specific region.
  void showRegionSummaryOverlay(DataRegion region);

  /// Programmatically hide the summary overlay.
  void hideRegionSummaryOverlay();
}
```

---

## 3. RegionAnalyzer (Public Utility)

```dart
/// Stateless utility for region data analysis.
/// Can be used independently of the chart widget for programmatic queries.
class RegionAnalyzer {
  const RegionAnalyzer();

  /// Filter data points within an X-range.
  /// Uses binary search when isSorted is true (default), linear scan otherwise.
  /// Returns points where startX <= point.x <= endX.
  List<ChartDataPoint> filterPointsInRange(
    List<ChartDataPoint> points, {
    required double startX,
    required double endX,
    bool isSorted = true,
  });

  /// Compute summary statistics for a list of data points.
  /// Returns null if points is empty.
  SeriesRegionSummary? computeSeriesSummary(
    List<ChartDataPoint> points, {
    required String seriesId,
    String? seriesName,
    String? unit,
    required double regionStartX,
    required double regionEndX,
  });

  /// Build a DataRegion from a RangeAnnotation and the chart's series data.
  DataRegion regionFromAnnotation(
    RangeAnnotation annotation,
    Map<String, List<ChartDataPoint>> allSeriesData,
  );

  /// Detect contiguous segment groups in a series.
  /// Returns DataRegion for each group of consecutive points with the same SegmentStyle.
  List<DataRegion> detectSegmentGroups(
    String seriesId,
    List<ChartDataPoint> points,
  );

  /// Find which segment group (if any) contains the given point index.
  DataRegion? segmentGroupForPoint(
    String seriesId,
    List<ChartDataPoint> points,
    int pointIndex,
  );

  /// Compute a full RegionSummary for a DataRegion.
  RegionSummary computeRegionSummary(
    DataRegion region, {
    Map<String, String>? seriesNames,
    Map<String, String>? seriesUnits,
  });
}
```

**Contract**:

- All methods are pure functions — no side effects, no state
- `filterPointsInRange` with `isSorted: true` runs in O(log n + k)
- `filterPointsInRange` with `isSorted: false` runs in O(n)
- `detectSegmentGroups` groups by contiguity + value equality of `SegmentStyle`
- `computeSeriesSummary` returns null for empty input
- `computeRegionSummary` omits series with zero points from the summary map

---

## 4. Integration with Existing Callbacks

| Existing API         | Behaviour Change                                                                                                                         |
| -------------------- | ---------------------------------------------------------------------------------------------------------------------------------------- |
| `onAnnotationTap`    | No change. Continues to fire with `ChartAnnotation`. `onRegionSelected` fires additionally for vertical `RangeAnnotation`.               |
| `onSelectionChanged` | No change for point-level selection. Box-select ALSO fires `onRegionSelected` with the drag X-range.                                     |
| `onPointTap`         | No change. Continues to fire with `(ChartDataPoint, String)`. `onRegionSelected` fires additionally if the point is in a styled segment. |

---

## 5. Barrel Exports

New public types added to `lib/braven_charts.dart`:

```dart
// Models
export 'src/models/data_region.dart';           // DataRegion, DataRegionSource
export 'src/models/region_summary.dart';        // SeriesRegionSummary, RegionSummary, RegionMetric
export 'src/models/region_summary_config.dart'; // RegionSummaryConfig, RegionSummaryPosition

// Analysis
export 'src/analysis/region_analyzer.dart';     // RegionAnalyzer

// Callbacks (added to existing interaction_callbacks.dart)
// RegionSelectedCallback, CustomRegionAnalysisCallback
```
