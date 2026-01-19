# Coordinate System Testing Guide

## Phase 7: Interactive System Testing and Verification

### Overview
This guide documents the manual testing required to verify the complete 3-coordinate-space architecture (Widget/Plot/Data) is functioning correctly after implementation of ChartTransform integration.

**Status**: App running at http://127.0.0.1:56285/MOhJhtLE7o4=

---

## Architecture Summary

### Three Coordinate Spaces
1. **Widget Space**: Flutter coordinates (0,0 → 800,600) - entire widget including axes
2. **Plot Space**: Canvas coordinates relative to plot area (0,0 → 730,540) - data visualization only
3. **Data Space**: Logical values (X: 1000-2000, Y: 50-150) - actual time series data

### Transformation Pipeline
```
Data Coordinates → ChartTransform.dataToPlot() → Plot Coordinates → Elements
Widget Events → widgetToPlot() → Plot Space → QuadTree queries
```

---

## Test Categories

### 1. Visual Verification Tests

#### 1.1 Element Rendering
- [ ] **Series Lines**: All 3 series render correctly
  - Series 1 (blue): Sine wave oscillating around price 100
  - Series 2 (red): Linear trend from price 60 → 120
  - Series 3 (green): Stepped pattern 80-125
- [ ] **Datapoints**: All datapoint clusters visible (3 clusters)
- [ ] **Scattered Points**: 30 scattered points visible across chart
- [ ] **Annotations**: All 6 annotations visible with labels
- [ ] **Axis Labels**: "Time Series Index" (X), "Price Value" (Y)
- [ ] **Axis Ranges**: X axis shows 1000-2000, Y axis shows 50-150

#### 1.2 Plot Area Clipping
- [ ] **No Axis Overlap**: Elements do NOT render over axes
- [ ] **Clean Boundaries**: Elements clipped at plot area edges
- [ ] **Left Edge**: 60px gap for Y-axis labels
- [ ] **Bottom Edge**: 50px gap for X-axis labels
- [ ] **Top/Right Edges**: 10px margins clean

---

### 2. Hit Testing and Selection

#### 2.1 Datapoint Selection
- [ ] **Left-Click on Datapoint**: Datapoint highlights (blue outline)
- [ ] **Selection Feedback**: Visual confirmation of selection
- [ ] **Hit Testing Accuracy**: Click near datapoint (within 10px) still selects it
- [ ] **Multiple Clicks**: Can select different datapoints sequentially
- [ ] **Deselection**: Click empty area clears selection

#### 2.2 Series Selection
- [ ] **Click on Series Line**: Series highlights
- [ ] **All Points Highlight**: All datapoints in series show selection state
- [ ] **Hit Tolerance**: Can click near line (within 5-10px)

#### 2.3 Annotation Selection
- [ ] **Click on Annotation**: Annotation highlights
- [ ] **Resize Handles**: 8 resize handles appear on selection
- [ ] **Handle Positions**: Handles at corners and edges
- [ ] **Selection State**: Clear visual distinction

---

### 3. Multi-Select Operations

#### 3.1 Ctrl+Click Selection
- [ ] **Add to Selection**: Ctrl+Click adds element without deselecting others
- [ ] **Remove from Selection**: Ctrl+Click on selected element deselects it
- [ ] **Mixed Types**: Can select datapoint + annotation + series together
- [ ] **Visual Feedback**: All selected elements show highlight simultaneously

#### 3.2 Box Selection (Shift+Drag)
- [ ] **Selection Box Renders**: Dragging with Shift shows selection rectangle
- [ ] **Box in Widget Space**: Selection box coordinates handled correctly
- [ ] **Multiple Elements**: All elements within box get selected
- [ ] **Mixed Elements**: Datapoints, series points, annotations all selectable
- [ ] **Preview State**: Elements show preview highlight during drag

---

### 4. Coordinate Conversion Tests

#### 4.1 Widget → Plot Conversion
- [ ] **Hit Testing**: Clicking works correctly (widget events → plot queries)
- [ ] **Hover Effects**: Hover state updates correctly
- [ ] **Crosshair**: Mouse position shows correct coordinates
- [ ] **Edge Cases**: Mouse near plot edges handled correctly

#### 4.2 Data → Plot Conversion
- [ ] **Positioning**: Elements at correct data coordinates (e.g., point at X=1500, Y=100)
- [ ] **Scaling**: Data range 1000-2000 fills full width correctly
- [ ] **Inversion**: Y-axis inverted correctly (high values at top)
- [ ] **Annotations**: Annotation positions match data coordinates

---

### 5. Interaction Features

#### 5.1 Dragging (Datapoints)
- [ ] **Click and Drag**: Can drag selected datapoint
- [ ] **Position Updates**: Datapoint follows mouse during drag
- [ ] **Release**: Datapoint stays at new position
- [ ] **Coordinate Accuracy**: Final position in plot space is correct
- [ ] **No Axis Contamination**: Dragged element stays within plot area

#### 5.2 Annotation Resize
- [ ] **Grab Handle**: Can click and drag resize handles
- [ ] **Corner Resize**: Top-left, top-right, bottom-left, bottom-right work
- [ ] **Edge Resize**: Top, right, bottom, left handles work
- [ ] **Proportional**: Resize maintains proper coordinate transformation
- [ ] **Visual Update**: Annotation size updates smoothly during drag

#### 5.3 Annotation Drag
- [ ] **Drag Annotation**: Can drag entire annotation by clicking body
- [ ] **Position Updates**: Annotation follows mouse
- [ ] **Clipping**: Stays within plot area (or handled appropriately)

---

### 6. Crosshair and Hover

#### 6.1 Crosshair Display
- [ ] **Crosshair Renders**: Vertical and horizontal lines follow mouse
- [ ] **Coordinate Labels**: Shows current mouse position
- [ ] **Data Coordinates**: Labels show data space values (time/price)
- [ ] **Update Frequency**: Smooth updates without lag

#### 6.2 Hover Effects
- [ ] **Element Hover**: Elements highlight on mouse hover
- [ ] **Hover Tolerance**: Works with hit testing tolerance
- [ ] **Hover Priority**: Closest element gets hover priority
- [ ] **Clear on Leave**: Hover state clears when mouse leaves element

---

### 7. Edge Cases and Boundary Testing

#### 7.1 Plot Area Boundaries
- [ ] **Left Boundary**: Elements at X=1000 (dataMin) render correctly
- [ ] **Right Boundary**: Elements at X=2000 (dataMax) render correctly
- [ ] **Top Boundary**: Elements at Y=150 (dataMax) render correctly
- [ ] **Bottom Boundary**: Elements at Y=50 (dataMin) render correctly

#### 7.2 Extreme Interactions
- [ ] **Rapid Clicks**: Fast clicking doesn't break selection
- [ ] **Rapid Hovers**: Quick mouse movement doesn't cause glitches
- [ ] **Multiple Selections**: Selecting many elements (10+) works
- [ ] **Deep Click**: Clicking densely packed elements works

---

### 8. Data Coordinate Verification

#### 8.1 Known Data Points
Test these specific data coordinates to verify transformation accuracy:

**Series 1 (Sine Wave)** - Should be visible:
- Point 1: X=1000, Y≈100 (starting point)
- Point 15: X=1500, Y≈100 (midpoint)
- Point 30: X=2000, Y≈100 (endpoint)

**Series 2 (Linear Trend)** - Should show clear diagonal:
- Point 1: X=1000, Y=60 (bottom-left of chart)
- Point 10: X=1500, Y=90 (middle)
- Point 20: X=2000, Y=120 (top-right)

**Series 3 (Stepped)** - Should show distinct steps:
- Steps at various heights between Y=80 and Y=125

#### 8.2 Annotation Positions
Verify annotations are at their defined data coordinates:
- Annotation "Buy Signal": Should be in left half, middle height
- Annotation "Sell Signal": Should be in right half, upper area
- Annotation "Support Level": Should span horizontally, lower area
- Annotation "Resistance Level": Should span horizontally, upper area
- Annotation "Key Event": Should be centered
- Annotation "Price Target": Should be in right section

---

### 9. Performance Testing

#### 9.1 Rendering Performance
- [ ] **Initial Load**: Chart renders in <1 second
- [ ] **Smooth Animations**: No jank during interactions
- [ ] **Resize Responsiveness**: Window resize updates smoothly

#### 9.2 Interaction Performance
- [ ] **Selection Speed**: Instant feedback (<50ms)
- [ ] **Hover Speed**: Smooth hover updates (<16ms for 60fps)
- [ ] **Drag Performance**: No lag during drag operations

---

### 10. Regression Testing

#### 10.1 Existing Features
- [ ] **Tooltips**: Still work on hover (if implemented)
- [ ] **Keyboard Navigation**: Tab, arrow keys work (if implemented)
- [ ] **Context Menus**: Right-click menus work (if implemented)

#### 10.2 No Regressions
- [ ] **No Console Errors**: Check browser console for errors
- [ ] **No Visual Glitches**: No rendering artifacts
- [ ] **No Coordinate Leakage**: All calculations use correct spaces

---

## Testing Checklist Progress

### Critical Path (Must Pass)
- [ ] ChartTransform unit tests (47/47 passing) ✅ VERIFIED
- [ ] Visual rendering correct (elements within plot area)
- [ ] Basic selection works (datapoint, series, annotation)
- [ ] Hit testing accurate (coordinate conversion working)
- [ ] No axis contamination (clipping functional)

### Important Features
- [ ] Multi-select (Ctrl+Click)
- [ ] Box selection (Shift+Drag)
- [ ] Drag operations
- [ ] Annotation resize
- [ ] Crosshair display

### Nice to Have
- [ ] Performance under load
- [ ] Edge case handling
- [ ] Rapid interaction stability

---

## Known Issues to Watch For

### Potential Problems
1. **Hit Testing Failures**: If elements don't select, check widget→plot conversion
2. **Axis Overlap**: If elements render over axes, check canvas clipping
3. **Wrong Positions**: If elements misplaced, check data→plot transformation
4. **QuadTree Misses**: If selection spotty, check QuadTree uses plot space

### Debug Steps
1. Open Chrome DevTools (F12)
2. Check Console for errors
3. Use Flutter DevTools (http://127.0.0.1:9102?uri=http://127.0.0.1:56285/MOhJhtLE7o4=)
4. Enable "Show Performance Overlay" in DevTools
5. Check "Repaint Rainbow" to see rendering updates

---

## Test Results Documentation

### Session Information
- **Date**: 2025-01-XX
- **Tester**: [Your Name]
- **App Version**: Phase 6 Complete (ChartTransform Integration)
- **Browser**: Chrome [version]
- **OS**: Windows

### Results Summary
```
Total Tests: [ ] / [ ]
Passed: [ ]
Failed: [ ]
Blocked: [ ]
```

### Failed Tests
(Document any failures with screenshots and reproduction steps)

---

## Completion Criteria

### Phase 7 Complete When:
- [ ] All Critical Path tests passing
- [ ] No visual regressions
- [ ] Hit testing working accurately
- [ ] Coordinate conversions validated
- [ ] Performance acceptable (<50ms interactions)
- [ ] No console errors
- [ ] Documentation complete

### Sign-Off
- [ ] Developer: Implementation complete
- [ ] Tester: All tests passing
- [ ] Reviewer: Code review complete

---

## Next Steps After Phase 7

### Future Enhancements
1. **Zoom/Pan Implementation**: Use ChartTransform.zoom() and .pan()
2. **Data Streaming**: Update with new data coordinates
3. **Animation**: Smooth transitions between data states
4. **Export**: Export with proper coordinate metadata

### Documentation Updates
1. Update coordinate_space_architecture.md with testing results
2. Create user guide for data coordinate usage
3. Document coordinate conversion helpers
4. Add examples of zoom/pan usage

---

## Appendix: Data Coordinate Reference

### Current Configuration
```dart
// Data ranges (logical values)
dataXMin: 1000  // Time series start index
dataXMax: 2000  // Time series end index  
dataYMin: 50    // Minimum price value
dataYMax: 150   // Maximum price value

// Plot dimensions (pixels)
plotWidth: 730   // 800 - 60 (left axis) - 10 (margin)
plotHeight: 540  // 600 - 50 (bottom axis) - 10 (margin)

// Transformation
ChartTransform(
  dataXMin: 1000, dataXMax: 2000,
  dataYMin: 50, dataYMax: 150,
  plotWidth: 730, plotHeight: 540,
  invertY: true,  // High values at top
)
```

### Example Conversions
```dart
// Data (1000, 100) → Plot (0, 270)  // Left side, middle height
// Data (1500, 100) → Plot (365, 270) // Center, middle height
// Data (2000, 100) → Plot (730, 270) // Right side, middle height

// Data (1500, 50) → Plot (365, 540)  // Center, bottom
// Data (1500, 150) → Plot (365, 0)   // Center, top
```

---

**END OF TESTING GUIDE**
