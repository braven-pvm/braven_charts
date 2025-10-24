# Area Chart Cubic Bezier Implementation

## Overview
Area charts now support all three line interpolation styles (straight, smooth, stepped) for rendering the top edge of filled areas. This extends the cubic bezier curve implementation from line charts to area charts.

## Implementation Details

### Core Changes

#### 1. BravenChart Widget (`lib/src/widgets/braven_chart.dart`)
- **Method Updated**: `_drawAreaSeries` (line ~3559)
- **Key Change**: Replaced hardcoded `path.lineTo()` loops with `LineInterpolator` usage

**Before** (hardcoded linear interpolation):
```dart
for (int i = 0; i < screenPoints.length; i++) {
  if (i == 0) {
    path.moveTo(screenPoints[i].dx, baseline);
    path.lineTo(screenPoints[i].dx, screenPoints[i].dy);
  } else {
    path.lineTo(screenPoints[i].dx, screenPoints[i].dy);
  }
}
// Close path back to baseline
path.lineTo(screenPoints.last.dx, baseline);
path.close();
```

**After** (interpolated top edge):
```dart
// Use LineInterpolator to create smooth/stepped/straight top edge
final interpolator = LineInterpolator(lineStyle);
final topEdgePath = interpolator.interpolate(screenPoints);

// Construct area path: baseline → interpolated top edge → baseline
final path = Path();
path.moveTo(screenPoints.first.dx, baseline);
path.addPath(topEdgePath, Offset.zero); // Interpolated edge
path.lineTo(screenPoints.last.dx, baseline);
path.close();
```

**Impact**: Area charts now use the same cubic bezier algorithm (Catmull-Rom spline) as line charts for smooth curves.

#### 2. Area Chart Examples (`example/lib/screens/area_chart_screen.dart`)
All 4 example charts updated with explicit `lineStyle` parameters:

1. **Chart 1**: Solid Fill Area Chart
   - `lineStyle: LineStyle.straight`
   - Title: "Solid Fill Area Chart (Straight Lines)"
   - Demonstrates: Linear interpolation (baseline)

2. **Chart 2**: Smooth Bezier Area Chart
   - `lineStyle: LineStyle.smooth`
   - Title: "Smooth Bezier Area Chart"
   - Subtitle: "Cubic bezier curves - flowing smooth edges (Catmull-Rom spline)"
   - Demonstrates: Cubic bezier interpolation

3. **Chart 3**: Stacked Area Chart
   - `lineStyle: LineStyle.stepped`
   - Title: "Stacked Area Chart (Stepped)"
   - Demonstrates: Step function interpolation

4. **Chart 4**: Custom Baseline Area Chart
   - `lineStyle: LineStyle.smooth`
   - Title: "Custom Baseline Area Chart (Smooth Bezier)"
   - Demonstrates: Cubic bezier with custom baseline

#### 3. Line Style Comparison Lab Enhancement
**File**: `example/lib/screens/line_style_comparison_screen.dart`

**New Features Added**:
- Chart Type Selector: Toggle between Line and Area charts
- Field: `ChartType _selectedChartType = ChartType.line;`
- UI: Choice chips for Line/Area selection
- Both static and streaming modes now support area charts
- Info panel updated with guidance on chart type toggle

**User Experience**:
Users can now:
1. Select a data pattern (sine wave, random, zigzag, peaks, steps)
2. Choose chart type (line or area)
3. Switch line style (straight, smooth, stepped)
4. Toggle between static and streaming modes
5. See SAME data with different interpolations in real-time

This provides definitive proof that interpolation is applied to data points, not the data itself.

## Algorithm Details

### Catmull-Rom to Cubic Bezier Conversion
For area charts, the top edge uses the same algorithm as line charts:

**For each segment [p1, p2] with neighbors [p0, p3]:**
```dart
// Control point 1: Moves from p1 toward p2, influenced by p0
cp1 = p1 + (p2 - p0) / 6

// Control point 2: Moves from p2 toward p1, influenced by p3  
cp2 = p2 - (p3 - p1) / 6

// Cubic bezier segment
path.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, p2.dx, p2.dy);
```

**Edge Cases**:
- **First segment**: Uses extrapolated p0 = p1 - (p2 - p1)
- **Last segment**: Uses extrapolated p3 = p2 + (p2 - p1)

### Area Path Construction
1. Start at baseline (x=first, y=baseline)
2. Add interpolated top edge path (smooth/stepped/straight)
3. Return to baseline (x=last, y=baseline)
4. Close path
5. Fill area, then stroke top edge

## Testing

### Manual Testing Checklist
- [x] Area Chart Screen: All 4 charts render correctly
- [x] Chart 1 (straight): Linear top edge, no curves
- [x] Chart 2 (smooth): Flowing cubic bezier top edge
- [x] Chart 3 (stepped): Horizontal-then-vertical steps
- [x] Chart 4 (smooth + custom baseline): Bezier curves with custom baseline
- [ ] Line Style Comparison Lab: Area chart + all line styles (requires hot reload)
- [ ] Static mode: Switch between line styles with area chart
- [ ] Streaming mode: Real-time area chart with smooth curves

### Expected Behavior
**LineStyle.smooth on Area Charts**:
- Top edge should show smooth, flowing curves
- No sharp angles between data points
- Curves should pass through all data points
- Area fill should extend from baseline to curved top edge
- Same visual quality as line charts

**Comparison to Line Charts**:
- Identical interpolation algorithm used
- Only difference: Area charts fill below the curve
- Line charts stroke the path, area charts fill AND stroke

## Technical Notes

### Path Manipulation
- `LineInterpolator.interpolate()` returns a `Path` object
- For lines: The path is stroked directly
- For areas: The path is used as the top edge, then filled

### Performance
- Same performance characteristics as line chart interpolation
- Single pass through data points
- O(n) complexity where n = number of points
- Path construction happens on UI thread (Flutter's canvas API)

### Backward Compatibility
- Default `lineStyle` is `LineStyle.straight` (maintains existing behavior)
- Existing area charts without explicit `lineStyle` parameter unchanged
- No breaking changes to public API

## Future Enhancements

### Potential Improvements
1. **Gradient fills**: Support gradient colors in area charts with bezier edges
2. **Stacked areas**: Verify bezier curves work correctly with stacked areas
3. **Negative values**: Test bezier interpolation with areas crossing baseline
4. **Performance**: Consider caching interpolated paths for static charts

### Known Limitations
- Step interpolation may create visual artifacts with very dense data points
- Smooth interpolation requires at least 2 data points (single point renders as area to baseline)

## Related Documentation
- [Cubic Bezier Implementation](CUBIC_BEZIER_IMPLEMENTATION.md) - Original line chart implementation
- [Line Style Comparison Guide](docs/guides/line-style-comparison.md) - Interactive testing guide
- [FR-005 Spec](specs/005-chart-types/FEATURE_REQUIREMENTS.md) - Original requirements
- [Testing Guide](example/MANUAL_TESTING_GUIDE.md) - Manual testing procedures

## Verification Commands

```powershell
# Run example app
cd example
flutter run -d chrome

# Navigate to:
# 1. "Area Charts" screen → Verify all 4 examples
# 2. "Line Style Comparison Lab" → Toggle to Area chart type
# 3. Switch between line styles while viewing area chart
# 4. Enable streaming mode and observe real-time bezier curves

# Run tests
cd ..
flutter test test/charts/area_chart_test.dart
flutter test test/integration/line_interpolation_test.dart
```

## Summary
Area charts now have feature parity with line charts regarding interpolation styles. The same cubic bezier algorithm (Catmull-Rom spline) that creates smooth line charts now also creates smooth area chart edges. Users can toggle between straight, smooth (bezier), and stepped interpolation for both chart types using the same `lineStyle` parameter.

**Key Achievement**: Demonstrates that interpolation is a rendering concern, not a data concern. The same data can be visualized with different interpolation styles, proving the distinction between data points and the curves connecting them.
