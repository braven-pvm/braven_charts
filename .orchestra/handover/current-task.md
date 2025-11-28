# Current Task: #10 - Integrate Multi-Axis Painter with BravenChart

## Objective

Wire up the `MultiAxisPainter` from Task 9 into the actual `BravenChart` widget so that multiple Y-axes render visually on the chart.

## ⚠️ THIS IS AN INTEGRATION TASK + VISUAL VERIFICATION REQUIRED

**You MUST modify EXISTING files.** Creating only new files is NOT acceptable.

**You MUST provide a screenshot** showing the multi-axis rendering working.

## Context

We have built:
- `MultiAxisPainter` - A CustomPainter that renders Y-axes with colors, ticks, labels
- `YAxisConfig` - Configuration for each axis (position, color, bounds)
- `MultiAxisConfig` - Container for axes, bindings, normalization mode
- Integration in `BravenChart` - Data normalization is wired up

**What's missing**: The `MultiAxisPainter` exists but is never instantiated in the chart. The axes don't render yet.

## What Needs to Happen

1. **Modify BravenChart** (`lib/src/widgets/braven_chart.dart`)
   - Import `MultiAxisPainter`
   - Instantiate and use the painter during chart painting
   - Pass the axis configurations from `multiAxisConfig`
   - Ensure axes render at correct positions (left/right of chart content)

2. **Visual Verification**
   - Run the example app or create a test widget
   - Configure a chart with at least 2 axes (different positions, different colors)
   - Take a screenshot showing both axes rendering correctly
   - Save screenshot as `screenshots/task-010-multi-axis-integration.png`

## Integration Points

Look at `_BravenChartPainter` in `braven_chart.dart`. The painter has a `paint()` method that draws various chart elements. The `MultiAxisPainter` should be used here.

**Conceptual approach**:
```dart
// In _BravenChartPainter.paint() or similar
if (multiAxisConfig != null && multiAxisConfig!.axes.isNotEmpty) {
  final axisPainter = MultiAxisPainter(
    axes: multiAxisConfig!.axes,
    chartRect: chartRect,  // The area where chart content renders
  );
  axisPainter.paint(canvas, size);
}
```

## Positioning Guide

The `MultiAxisPainter` positions axes relative to `chartRect`:
- `left` and `outerLeft` axes render to the LEFT of `chartRect.left`
- `right` and `outerRight` axes render to the RIGHT of `chartRect.right`

Ensure `chartRect` has enough margin for the axes to be visible.

## Success Criteria

- [ ] `lib/src/widgets/braven_chart.dart` is MODIFIED (not just new files created)
- [ ] `MultiAxisPainter` is imported and instantiated
- [ ] Chart renders with at least 2 Y-axes visible
- [ ] Axes have different colors (from YAxisConfig)
- [ ] Tick marks and labels are visible
- [ ] Screenshot provided showing working multi-axis chart

## Verification

The orchestrator will check:
1. Git diff shows `braven_chart.dart` modified
2. `MultiAxisPainter` is imported and used
3. Screenshot shows multiple colored axes
4. Static analysis passes

## When Done

1. Stage changes: `git add .`
2. Take screenshot and save to `screenshots/task-010-multi-axis-integration.png`
3. Write to `completion-signal.md` with:
   - Files modified
   - Brief description of integration approach
   - Screenshot location
4. Say "ready for review"
