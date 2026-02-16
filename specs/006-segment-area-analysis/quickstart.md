# Quickstart: Segment & Area Data Analysis

**Feature**: `006-segment-area-analysis` | **Date**: 2026-02-14

---

## Getting Started

This feature adds region-level data analysis to braven_charts. You can query the underlying data within range annotations, visual segments, and box-select areas — and optionally display built-in summary statistics.

### Prerequisites

- braven_charts package (this feature branch)
- Existing chart with `BravenChartPlus` widget
- No additional dependencies required

---

## Usage Examples

### 1. Get Data When a Range Annotation is Tapped

```dart
BravenChartPlus(
  series: mySeries,
  annotations: [
    RangeAnnotation(
      id: 'vt1-zone',
      label: 'VT1 Zone',
      startX: 3.2,
      endX: 7.8,
      fillColor: Colors.blue.withOpacity(0.2),
    ),
  ],
  onRegionSelected: (DataRegion? region) {
    if (region == null) {
      print('Region deselected');
      return;
    }

    print('Selected: ${region.label} (${region.startX} → ${region.endX})');

    // Access filtered data per series
    for (final entry in region.seriesData.entries) {
      print('  ${entry.key}: ${entry.value.length} points');
    }
  },
)
```

### 2. Compute Summary Statistics

```dart
// Via GlobalKey
final chartKey = GlobalKey<BravenChartPlusState>();

// Later, after a region is selected:
final regions = chartKey.currentState!.selectedDataRegions;
if (regions.isNotEmpty) {
  final summaries = chartKey.currentState!.computeRegionSummaries();
  for (final summary in summaries) {
    for (final entry in summary.seriesSummaries.entries) {
      final s = entry.value;
      print('${s.seriesName}: min=${s.min}, max=${s.max}, avg=${s.average}');
    }
  }
}
```

### 3. Enable Visual Summary Overlay

```dart
BravenChartPlus(
  series: mySeries,
  annotations: myAnnotations,
  showRegionSummary: true,
  regionSummaryConfig: RegionSummaryConfig(
    metrics: {RegionMetric.min, RegionMetric.max, RegionMetric.average, RegionMetric.delta},
    valueFormatter: (value, unit) => '${value.toStringAsFixed(1)}${unit != null ? ' $unit' : ''}',
    position: RegionSummaryPosition.aboveRegion,
  ),
)
```

### 4. Box-Select for Ad-Hoc Analysis

```dart
BravenChartPlus(
  series: mySeries,
  interactionConfig: InteractionConfig(enableSelection: true),
  onRegionSelected: (DataRegion? region) {
    if (region?.source == DataRegionSource.boxSelect) {
      print('User selected X range: ${region!.startX} → ${region.endX}');
      // Compute stats for the ad-hoc selection
    }
  },
)
```

### 5. Programmatic Analysis (Without UI)

```dart
const analyzer = RegionAnalyzer();

// Filter points in a range
final filtered = analyzer.filterPointsInRange(
  myPoints,
  startX: 3.2,
  endX: 7.8,
);

// Compute summary
final summary = analyzer.computeSeriesSummary(
  filtered,
  seriesId: 'power',
  seriesName: 'Power',
  unit: 'W',
  regionStartX: 3.2,
  regionEndX: 7.8,
);

if (summary != null) {
  print('Power: avg=${summary.average}W, Δ=${summary.delta}W');
}
```

### 6. Custom Analysis Extensions

```dart
BravenChartPlus(
  series: mySeries,
  showRegionSummary: true,
  customRegionAnalysis: (DataRegion region, RegionSummary summary) {
    final powerData = region.seriesData['power'];
    if (powerData == null) return {};

    // Compute domain-specific metric
    final np = _computeNormalizedPower(powerData);
    return {'Normalized Power': '${np.toStringAsFixed(0)} W'};
  },
)
```

---

## Key Concepts

| Concept             | Description                                                                                        |
| ------------------- | -------------------------------------------------------------------------------------------------- |
| **DataRegion**      | A contiguous X-range with filtered series data. Created from annotations, segments, or box-select. |
| **RegionSummary**   | Built-in statistics (min, max, avg, etc.) for all series in a region.                              |
| **RegionAnalyzer**  | Public utility for programmatic data filtering and analysis.                                       |
| **Summary Overlay** | Opt-in visual card showing metrics above the selected region.                                      |

---

## Implementation Order (for developers)

1. **Phase 1**: `DataRegion` + `RegionAnalyzer` models and logic (can be unit tested standalone)
2. **Phase 2**: Wire callbacks into `BravenChartPlus` (widget integration)
3. **Phase 3**: Summary overlay renderer (visual component)
4. **Phase 4**: Custom analysis hook + demo page + docs
