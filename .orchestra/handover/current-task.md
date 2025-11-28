# Current Task: #9 - Create Multi-Axis Painter

## Objective

Create a CustomPainter that can render multiple Y-axes on a chart, each positioned and styled according to its `YAxisConfig`.

## ⚠️ TDD REQUIRED + VISUAL VERIFICATION

**You MUST write tests FIRST before implementing.** The tests will guide your implementation.

Visual verification is required - the axes must be visibly rendered with correct positioning and colors.

## Context

We now have:
- `YAxisPosition` - Defines where axes go (outerLeft, left, right, outerRight)
- `YAxisConfig` - Configuration for each axis (color, labels, bounds)
- `DataNormalizer` - Normalizes values to 0.0-1.0 range
- `NormalizationDetector` - Detects when normalization is needed
- Integration in `BravenChart` - Normalization is wired into the rendering pipeline

Now we need to actually PAINT multiple Y-axes on the canvas.

## What Needs to Be Created

### 1. Test File (FIRST!)
`test/unit/painters/multi_axis_painter_test.dart`

Write tests for:
- Paints single axis correctly
- Paints multiple axes at correct positions
- Applies axis colors from config
- Renders tick marks and labels

### 2. Implementation
`lib/src/painters/multi_axis_painter.dart`

Create a `MultiAxisPainter` class that:
- Extends `CustomPainter` (or integrates with existing pattern)
- Takes a list of `YAxisConfig` and positions them correctly
- Uses the axis color from config
- Renders tick marks (based on normalized 0.0-1.0 scale)
- Renders labels with actual values (denormalized)

### 3. Export
Add to `lib/braven_charts.dart`

## Positioning Guide

```
|outerLeft|left|     CHART AREA     |right|outerRight|
|   axis  |axis|                    | axis|   axis   |
```

- `outerLeft`: Farthest left position
- `left`: Standard left position (closer to chart)
- `right`: Standard right position (closer to chart)
- `outerRight`: Farthest right position

## Implementation Notes

1. Consider how this painter will integrate with `BravenChart`'s existing painters
2. The chart has `ChartPainter` pattern - review existing painters for consistency
3. Axis painting happens in the "frame" area around the chart content

## Success Criteria

- [ ] Tests written FIRST (at least 4 test cases)
- [ ] All tests passing
- [ ] Painter correctly positions 2-4 Y-axes
- [ ] Each axis uses its configured color
- [ ] Tick marks and labels are visible
- [ ] Export added to `lib/braven_charts.dart`

## Verification

The orchestrator will check:
1. Test file exists and was created before implementation
2. Minimum 4 test cases covering required scenarios
3. Implementation file exists with CustomPainter
4. Axes actually render at correct positions with correct colors
5. Static analysis passes

## When Done

1. Stage changes: `git add .`
2. Write to `completion-signal.md` with:
   - List of files created
   - Brief description of implementation
   - Test count and coverage
3. Say "ready for review"
