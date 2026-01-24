# Quickstart: Multi-Series Rendering Improvements

**Feature**: 002-multi-series-rendering-fix  
**Date**: 2026-01-23

## Overview

This feature fixes two critical rendering issues:

1. **Grouped Bar Charts**: Multiple bar series now render side-by-side instead of overlapping
2. **Y-Axis Zoom**: Vertical zoom works correctly with perSeries normalization and multi-axis charts

## What's New

### Grouped Bar Charts

Multiple bar series at the same X-position now automatically render adjacent to each other:

```dart
BravenChart(
  series: [
    BarChartSeries(
      id: 'duration',
      data: durationData,  // e.g., [100, 200, 150]
      color: Colors.blue,
    ),
    BarChartSeries(
      id: 'work',
      data: workData,  // e.g., [8, 12, 10]
      color: Colors.green,
    ),
  ],
  // Bars will automatically group side-by-side at each X position
)
```

**Behavior**:

- 2-10 bar series supported without visual degradation
- Minimum bar width of 4 pixels enforced for readability
- Configurable gap between bars (default: 2 pixels)
- Single bar series retains existing centered behavior

### Y-Axis Zoom with Multi-Axis

Vertical zoom now works correctly when using per-series normalization:

```dart
BravenChart(
  series: [
    LineChartSeries(id: 'duration', data: durationData, yAxisId: 'left'),
    LineChartSeries(id: 'calories', data: caloriesData, yAxisId: 'right'),
  ],
  yAxes: [
    YAxisConfig(id: 'left', position: YAxisPosition.left),
    YAxisConfig(id: 'right', position: YAxisPosition.right),
  ],
  normalizationMode: NormalizationMode.perSeries,
  // Mouse wheel zoom now affects both X and Y axes
  // Y-scrollbar edge drag zooms Y-axis only
)
```

**Behavior**:

- Mouse wheel zooms both X and Y axes proportionally
- Y-scrollbar edge drag zooms Y-axis independently
- Y-axis labels update to reflect zoomed range
- Crosshair tooltips show correct values after zoom
- Existing zoom limits (ViewportConstraints) apply

## Key Files

| File                                                | Purpose                                |
| --------------------------------------------------- | -------------------------------------- |
| `lib/src/models/bar_group_info.dart`                | Bar grouping metadata                  |
| `lib/src/elements/series_element.dart`              | Bar painting with grouping             |
| `lib/src/rendering/modules/multi_axis_manager.dart` | Viewport-aware axis bounds             |
| `lib/src/rendering/chart_render_box.dart`           | Orchestration of grouped bars and zoom |

## Testing

Run the test suite to verify functionality:

```bash
# Unit tests for bar grouping
flutter test test/unit/rendering/bar_group_info_test.dart

# Widget tests for grouped bars
flutter test test/widget/charts/grouped_bar_chart_test.dart

# Widget tests for Y-zoom
flutter test test/widget/charts/multi_axis_zoom_test.dart

# Full test suite
flutter test
```

## Demo

The FitDistributionPage demo showcases both features:

```bash
flutter run -d chrome lib/main.dart
# Navigate to Fit Distribution demo
```

## Performance

No performance regression expected:

- Bar grouping calculation: O(n) where n = series count
- No additional per-frame allocations
- 60fps maintained with 1000+ data points
