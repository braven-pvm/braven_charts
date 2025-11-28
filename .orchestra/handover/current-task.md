# Current Task: #8 - Integrate Normalizer with Chart Data Pipeline

## Objective

Wire up the `DataNormalizer` and `NormalizationDetector` so that multi-axis normalization actually works when rendering charts.

## ⚠️ THIS IS AN INTEGRATION TASK

**You MUST modify EXISTING files.** Creating only new files is NOT acceptable.

The goal is: when a chart has series with vastly different Y-ranges (e.g., Power 0-300W and Tidal Volume 0.5-4.0L), both series should render using the full chart height.

## Current State

We have built:
- `DataNormalizer` - normalizes values to 0.0-1.0 range
- `NormalizationDetector` - detects when ranges differ enough to need normalization
- `MultiAxisConfig` - configuration container with axes, bindings, mode

But they're not connected to anything yet.

## What Needs to Happen

1. **Accept multi-axis config** - The chart widget/painter needs to accept `MultiAxisConfig`
2. **Detect when to normalize** - Use `NormalizationDetector` with the series ranges
3. **Normalize during rendering** - When drawing series, normalize Y values to 0.0-1.0
4. **Preserve original values** - Original Y values must still be available for tooltips/labels

## Key Files to Modify

Look at these existing files (modify them, don't just create new ones):
- `lib/src/widgets/braven_chart.dart` - Main chart widget, contains `_BravenChartPainter`
- `lib/src/foundation/data_models/chart_series.dart` - Has `yRange` property

## Integration Points

The painter has methods like `_drawLineSeries`, `_drawAreaSeries`, etc. that convert data points to pixel positions. The normalization should happen during this conversion.

**Before normalization:**
```dart
final yPixel = chartRect.bottom - (point.y - minY) / (maxY - minY) * chartRect.height;
```

**After normalization (conceptual):**
```dart
final normalizedY = DataNormalizer.normalize(point.y, seriesMinY, seriesMaxY);
final yPixel = chartRect.bottom - normalizedY * chartRect.height;
```

## Success Criteria

When complete, the following should work:

```dart
BravenChart(
  series: [
    ChartSeries(id: 'power', points: [...]),     // Y range: 0-300
    ChartSeries(id: 'tidal', points: [...]),     // Y range: 0.5-4.0
  ],
  multiAxisConfig: MultiAxisConfig(
    axes: [
      YAxisConfig(id: 'power-axis', position: YAxisPosition.left),
      YAxisConfig(id: 'tidal-axis', position: YAxisPosition.right),
    ],
    bindings: [
      SeriesAxisBinding(seriesId: 'power', axisId: 'power-axis'),
      SeriesAxisBinding(seriesId: 'tidal', axisId: 'tidal-axis'),
    ],
    mode: NormalizationMode.always,
  ),
)
```

Both series should use the full chart height, not just power dominating while tidal is a flat line.

## Verification

The orchestrator will check:
1. Existing files are modified (git diff shows changes to existing lib/src files)
2. `DataNormalizer` is imported and called in the rendering pipeline
3. Static analysis passes

## When Done

1. Stage changes: `git add .`
2. Write to `completion-signal.md` with:
   - List of files modified
   - Brief description of changes
3. Say "ready for review"
