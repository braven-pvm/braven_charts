# Coordinate Space Architecture

**Date**: November 6, 2025  
**Status**: Design → Implementation  
**Purpose**: Define the proper separation of coordinate spaces to enable correct rendering, interaction, zoom/pan, and axis integration.

---

## Executive Summary

This document specifies the complete coordinate space architecture for the braven_charts interaction system. It addresses a critical architectural issue where chart elements, axes, and interactions were all operating in the same coordinate space, leading to:

- ❌ Elements drawing over axis areas
- ❌ Hit testing in wrong coordinate space
- ❌ No proper foundation for zoom/pan transforms
- ❌ Ambiguous meaning of element positions

The solution establishes **three distinct coordinate spaces** with clear transformation pipelines between them.

---

## 1. The Three Coordinate Spaces

### 1.1 Widget Space (Flutter Coordinates)

**Definition**: The coordinate system of the ChartRenderBox widget itself.

- **Origin**: Top-left corner of the widget
- **Units**: Physical pixels
- **Scope**: Entire widget including axes, labels, padding, and plot area
- **Used by**: Flutter framework, widget layout, axis rendering

**Example**:
```dart
// Widget size: 800×600
// Y-axis occupies: (0, 0) to (60, 600)
// X-axis occupies: (0, 550) to (800, 600)
// Plot area occupies: (60, 10) to (790, 550)
```

**Responsibilities**:
- Overall widget sizing and layout
- Axis label positioning
- Margin/padding calculations
- Top-level hit testing

---

### 1.2 Plot Space (Rendering Canvas)

**Definition**: The coordinate system of the data visualization area (excluding axes).

- **Origin**: Top-left corner of the plot area (relative to widget)
- **Units**: Physical pixels, relative to plot area origin
- **Scope**: Only the area where chart elements render
- **Used by**: Element rendering, spatial indexing, element hit testing

**Example**:
```dart
// Plot area in widget space: (60, 10) to (790, 550)
// Plot space coordinates: (0, 0) to (730, 540)
// 
// Element at plot (100, 200) renders at widget (160, 210)
```

**Responsibilities**:
- Chart element painting
- QuadTree spatial indexing
- Element-level hit testing
- Canvas clipping boundary

---

### 1.3 Data Space (Logical Coordinates)

**Definition**: The coordinate system of the actual data being visualized.

- **Origin**: Defined by data domain (e.g., earliest timestamp, minimum price)
- **Units**: Data values (timestamps, prices, percentages, etc.)
- **Scope**: The logical domain of the data
- **Used by**: Data input, axis tick generation, zoom/pan operations

**Example**:
```dart
// Time series data
// X: [1609459200, 1640995200] (Unix timestamps)
// Y: [100.0, 500.0] (price values)
// 
// Data point (1625097600, 250.0) represents:
//   - July 1, 2021 at price $250.00
```

**Responsibilities**:
- Data input and storage
- Axis range definition
- Zoom/pan viewport boundaries
- Tick generation

---

## 2. Transformation Pipeline

### 2.1 Forward Transform: Data → Widget

```
┌──────────────────────────────────────────────────┐
│ Data Space                                        │
│   DataPoint(x: 1625097600, y: 250.0)            │
└──────────────────────────────────────────────────┘
                      ↓
            ChartTransform.dataToPlot()
                      ↓
┌──────────────────────────────────────────────────┐
│ Plot Space                                        │
│   PlotPoint(x: 365.0, y: 270.0)                  │
└──────────────────────────────────────────────────┘
                      ↓
         ChartRenderBox.plotToWidget()
         (translate by plot area offset)
                      ↓
┌──────────────────────────────────────────────────┐
│ Widget Space                                      │
│   WidgetPoint(x: 425.0, y: 280.0)                │
└──────────────────────────────────────────────────┘
```

### 2.2 Reverse Transform: Widget → Data (for Hit Testing)

```
┌──────────────────────────────────────────────────┐
│ Widget Space                                      │
│   PointerEvent(position: Offset(425, 280))      │
└──────────────────────────────────────────────────┘
                      ↓
         ChartRenderBox.widgetToPlot()
         (subtract plot area offset)
                      ↓
┌──────────────────────────────────────────────────┐
│ Plot Space                                        │
│   PlotPoint(x: 365.0, y: 270.0)                  │
└──────────────────────────────────────────────────┘
                      ↓
            ChartTransform.plotToData()
                      ↓
┌──────────────────────────────────────────────────┐
│ Data Space                                        │
│   DataPoint(x: 1625097600, y: 250.0)            │
└──────────────────────────────────────────────────┘
```

---

## 3. Core Components

### 3.1 ChartTransform

**Purpose**: Bidirectional conversion between Data Space and Plot Space.

**Responsibilities**:
- Convert data coordinates to plot coordinates (for rendering)
- Convert plot coordinates to data coordinates (for hit testing)
- Manage viewport (visible data range)
- Provide zoom/pan operations
- Optimize bulk transformations for series

**Interface**:
```dart
class ChartTransform {
  ChartTransform({
    required double dataXMin,
    required double dataXMax,
    required double dataYMin,
    required double dataYMax,
    required double plotWidth,
    required double plotHeight,
    bool invertY = true,  // Standard chart: Y=0 at bottom
  });

  // Core transformations
  Offset dataToPlot(double dataX, double dataY);
  Offset plotToData(double plotX, double plotY);
  
  // Optimized bulk operations
  List<Offset> dataPointsToPlot(List<Offset> dataPoints);
  
  // Viewport queries
  bool isDataPointVisible(double dataX, double dataY);
  Rect get visibleDataBounds;
  
  // Viewport manipulation
  ChartTransform zoom(double factor, Offset plotCenter);
  ChartTransform pan(double plotDx, double plotDy);
  
  // Immutable updates
  ChartTransform copyWith({
    double? dataXMin,
    double? dataXMax,
    double? dataYMin,
    double? dataYMax,
    double? plotWidth,
    double? plotHeight,
  });
}
```

**Key Design Decisions**:
1. **Immutable**: Returns new instances for zoom/pan (functional style)
2. **Inverted Y-axis by default**: Matches standard chart convention (Y=0 at bottom)
3. **Separate X/Y ranges**: Supports independent axis scaling
4. **Plot size aware**: Recalculates on layout changes

---

### 3.2 ChartRenderBox

**Purpose**: Manages layout, rendering, and Widget↔Plot coordinate conversion.

**Coordinate Space Responsibilities**:

| Space | Responsibility |
|-------|---------------|
| **Widget Space** | Overall layout, axis rendering, input events |
| **Plot Space** | Element rendering, spatial indexing, clipping |
| **Data Space** | Delegated to ChartTransform |

**Key Methods**:
```dart
class ChartRenderBox extends RenderBox {
  // Layout
  Rect _plotArea = Rect.zero;  // In widget space
  ChartTransform? _transform;
  
  @override
  void performLayout() {
    // 1. Calculate widget size
    size = constraints.constrain(...);
    
    // 2. Reserve space for axes (widget space)
    _plotArea = _calculatePlotArea(size);
    
    // 3. Update transform with new plot dimensions
    _transform = _transform?.copyWith(
      plotWidth: _plotArea.width,
      plotHeight: _plotArea.height,
    );
    
    // 4. Update axes with data ranges
    _xAxis?.updateDataRange(_transform!.dataXMin, _transform!.dataXMax);
    _xAxis?.updatePixelRange(_plotArea.left, _plotArea.right);
    
    // 5. Rebuild spatial index (plot space)
    _rebuildSpatialIndex();
  }
  
  // Coordinate conversion helpers
  Offset widgetToPlot(Offset widgetPos) {
    return widgetPos - _plotArea.topLeft;
  }
  
  Offset plotToWidget(Offset plotPos) {
    return plotPos + _plotArea.topLeft;
  }
  
  @override
  void paint(PaintingContext context, Offset offset) {
    final canvas = context.canvas;
    canvas.save();
    canvas.translate(offset.dx, offset.dy);
    
    // Paint in widget space: background, axes
    _paintBackground(canvas);
    _paintAxes(canvas);
    
    // Translate to plot space and clip
    canvas.save();
    canvas.translate(_plotArea.left, _plotArea.top);
    canvas.clipRect(Rect.fromLTWH(0, 0, _plotArea.width, _plotArea.height));
    
    // Paint elements in plot space
    _paintElements(canvas);
    
    canvas.restore();  // Exit plot space
    canvas.restore();  // Exit widget space
  }
  
  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    // Widget space hit test
    if (!size.contains(position)) return false;
    
    // Convert to plot space
    final plotPos = widgetToPlot(position);
    
    // Check if in plot bounds
    final plotBounds = Rect.fromLTWH(0, 0, _plotArea.width, _plotArea.height);
    if (!plotBounds.contains(plotPos)) {
      // Hit axis area or padding - no element interaction
      result.add(BoxHitTestEntry(this, position));
      return true;
    }
    
    // Hit test elements in plot space
    _hitTestElementsInPlot(plotPos);
    
    result.add(BoxHitTestEntry(this, position));
    return true;
  }
}
```

**Critical Implementation Details**:

1. **QuadTree in Plot Space**:
```dart
void _rebuildSpatialIndex() {
  _spatialIndex = QuadTree(
    bounds: Rect.fromLTWH(0, 0, _plotArea.width, _plotArea.height),
    maxElementsPerNode: 4,
    maxDepth: 8,
  );
  
  for (final element in _elements) {
    _spatialIndex!.insert(element);  // Elements have plot coordinates
  }
}
```

2. **Canvas Clipping**:
```dart
// Prevents elements from rendering over axes
canvas.clipRect(Rect.fromLTWH(0, 0, _plotArea.width, _plotArea.height));
```

3. **Plot Area Calculation**:
```dart
Rect _calculatePlotArea(Size widgetSize) {
  double leftMargin = _yAxis != null ? 60 : 10;
  double bottomMargin = _xAxis != null ? 50 : 10;
  double topMargin = 10;
  double rightMargin = 10;
  
  return Rect.fromLTRB(
    leftMargin,
    topMargin,
    widgetSize.width - rightMargin,
    widgetSize.height - bottomMargin,
  );
}
```

---

### 3.3 ChartElement

**Purpose**: Represent renderable chart elements in Plot Space.

**Coordinate Space**: All methods operate in **Plot Space**.

**Interface**:
```dart
abstract class ChartElement {
  String get id;
  ChartElementType get elementType;
  int get priority;
  
  // All coordinates in PLOT SPACE
  Rect get bounds;  // Bounding box in plot coordinates
  
  bool hitTest(Offset plotPosition);  // Hit test using plot coordinates
  
  void paint(Canvas canvas, Size plotSize);  // Paint using plot coordinates
  
  // Selection/hover state
  bool get isSelected;
  bool get isHovered;
  void onSelect();
  void onDeselect();
  void onHoverEnter();
  void onHoverExit();
}
```

**Example Implementation**:
```dart
class DatapointElement extends ChartElement {
  DatapointElement({
    required this.id,
    required this.plotCenter,  // PLOT coordinates, not data or widget!
    this.radius = 6.0,
  });
  
  final String id;
  final Offset plotCenter;  // Already transformed from data space
  final double radius;
  
  @override
  Rect get bounds => Rect.fromCircle(center: plotCenter, radius: radius);
  
  @override
  bool hitTest(Offset plotPosition) {
    // Hit test in plot space
    return (plotPosition - plotCenter).distance <= radius + 10;
  }
  
  @override
  void paint(Canvas canvas, Size plotSize) {
    // Paint in plot space (no coordinate transform needed)
    final paint = Paint()
      ..color = isSelected ? Colors.orange : Colors.blue
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(plotCenter, radius, paint);
    
    if (isSelected) {
      canvas.drawCircle(
        plotCenter,
        radius + 4,
        Paint()
          ..color = Colors.orange
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
  }
}
```

**Key Point**: Elements are **pre-transformed** from data space to plot space. They don't perform coordinate conversion during rendering.

---

## 4. Data Flow Examples

### 4.1 Initial Setup: Creating Elements from Data

```dart
// Step 1: User provides data points
final dataPoints = [
  DataPoint(timestamp: 1609459200, price: 150.0),
  DataPoint(timestamp: 1612137600, price: 175.0),
  DataPoint(timestamp: 1614556800, price: 160.0),
  // ... more points
];

// Step 2: Create transform with data bounds and plot size
final transform = ChartTransform(
  dataXMin: 1609459200.0,  // Jan 1, 2021
  dataXMax: 1640995200.0,  // Jan 1, 2022
  dataYMin: 100.0,
  dataYMax: 200.0,
  plotWidth: 730.0,   // From layout calculation
  plotHeight: 540.0,  // From layout calculation
  invertY: true,
);

// Step 3: Transform data to plot space and create elements
final elements = dataPoints.map((data) {
  final plotPos = transform.dataToPlot(
    data.timestamp.toDouble(),
    data.price,
  );
  
  return DatapointElement(
    id: 'point_${data.timestamp}',
    plotCenter: plotPos,  // Stored in PLOT coordinates
    radius: 6.0,
  );
}).toList();

// Step 4: Elements are now ready for rendering in plot space
// No further coordinate transformation needed during paint
```

---

### 4.2 Zoom Operation

```dart
void handleZoom(PointerScrollEvent event) {
  // Step 1: Get zoom position in widget space
  final widgetPos = event.localPosition;
  
  // Step 2: Convert to plot space
  final plotPos = widgetToPlot(widgetPos);
  
  // Step 3: Calculate zoom factor from scroll delta
  final factor = event.scrollDelta.dy > 0 ? 0.9 : 1.1;  // Zoom out/in
  
  // Step 4: Create new transform (zoomed around plot center)
  final newTransform = _transform!.zoom(factor, plotPos);
  
  // Step 5: Update axes with new data ranges
  _xAxis?.updateDataRange(newTransform.dataXMin, newTransform.dataXMax);
  _yAxis?.updateDataRange(newTransform.dataYMin, newTransform.dataYMax);
  
  // Step 6: Regenerate elements from original data with new transform
  _elements = _regenerateElementsFromData(_originalDataPoints, newTransform);
  
  // Step 7: Update transform reference
  _transform = newTransform;
  
  // Step 8: Rebuild spatial index and repaint
  _rebuildSpatialIndex();
  markNeedsPaint();
}
```

**Why Regenerate Elements?**
- Elements store plot coordinates (pre-transformed)
- When viewport changes, plot coordinates change
- Must retransform from original data space
- Performance is acceptable for typical chart sizes (<10k points)

---

### 4.3 Pan Operation

```dart
void handlePan(DragUpdateDetails details) {
  // Step 1: Pan delta is in widget space
  final widgetDelta = details.delta;
  
  // Step 2: Delta is same in plot space (both are pixels)
  final plotDelta = widgetDelta;  // No offset, just movement
  
  // Step 3: Create new transform (panned in plot space)
  final newTransform = _transform!.pan(plotDelta.dx, plotDelta.dy);
  
  // Step 4: Update axes
  _xAxis?.updateDataRange(newTransform.dataXMin, newTransform.dataXMax);
  _yAxis?.updateDataRange(newTransform.dataYMin, newTransform.dataYMax);
  
  // Step 5: Regenerate elements
  _elements = _regenerateElementsFromData(_originalDataPoints, newTransform);
  
  // Step 6: Update transform
  _transform = newTransform;
  
  // Step 7: Rebuild and repaint
  _rebuildSpatialIndex();
  markNeedsPaint();
}
```

---

### 4.4 Hit Testing

```dart
void handlePointerDown(PointerDownEvent event) {
  // Step 1: Event position is in widget space
  final widgetPos = event.localPosition;
  
  // Step 2: Convert to plot space
  final plotPos = widgetToPlot(widgetPos);
  
  // Step 3: Check if in plot bounds
  final plotBounds = Rect.fromLTWH(0, 0, _plotArea.width, _plotArea.height);
  if (!plotBounds.contains(plotPos)) {
    // Clicked on axis area - no element interaction
    return;
  }
  
  // Step 4: Query spatial index (in plot space)
  final candidates = _spatialIndex!.query(plotPos, radius: 18);
  
  // Step 5: Precise hit test (in plot space)
  final hits = candidates.where((e) => e.hitTest(plotPos)).toList();
  
  // Step 6: Select highest priority element
  if (hits.isNotEmpty) {
    hits.sort((a, b) => b.priority.compareTo(a.priority));
    final element = hits.first;
    
    // Step 7: Handle selection
    _handleElementSelected(element);
  }
}
```

---

## 5. Axis Integration

Axes operate in a **hybrid coordinate space**:

- **Paint in Widget Space**: Need access to full widget size for label positioning
- **Use Data Space for Ticks**: Generate ticks based on data range
- **Reference Plot Area**: Know where to draw relative to plot bounds

**Axis Interface**:
```dart
class Axis {
  Axis({
    required AxisConfig config,
    required double dataMin,
    required double dataMax,
  });
  
  // Data range (what to show)
  double dataMin;
  double dataMax;
  
  // Pixel range (where to draw in widget space)
  double pixelMin;
  double pixelMax;
  
  void updateDataRange(double min, double max);
  void updatePixelRange(double min, double max);
  
  List<Tick> get ticks;  // Generated from data range
}

class AxisRenderer {
  void paint(Canvas canvas, Size widgetSize, Rect plotArea) {
    // Canvas is in widget space
    // plotArea provides plot boundaries in widget coordinates
    
    // For horizontal axis (X):
    final y = plotArea.bottom;  // Draw at bottom of plot area
    final startX = plotArea.left;
    final endX = plotArea.right;
    
    // Draw axis line in widget space
    canvas.drawLine(
      Offset(startX, y),
      Offset(endX, y),
      Paint()..color = Colors.black,
    );
    
    // Draw ticks at data positions
    for (final tick in axis.ticks) {
      final x = axis.scale.dataToPixel(tick.value);  // Widget space X
      canvas.drawLine(
        Offset(x, y),
        Offset(x, y + 8),
        Paint()..color = Colors.black,
      );
      
      // Draw label
      _drawText(canvas, tick.label, Offset(x, y + 12));
    }
  }
}
```

**Axis Update Flow**:
```dart
// In ChartRenderBox.performLayout():

// Update axes with current transform data ranges
_xAxis?.updateDataRange(_transform!.dataXMin, _transform!.dataXMax);
_yAxis?.updateDataRange(_transform!.dataYMin, _transform!.dataYMax);

// Update axes with plot area pixel ranges (widget space)
_xAxis?.updatePixelRange(_plotArea.left, _plotArea.right);
_yAxis?.updatePixelRange(_plotArea.top, _plotArea.bottom);
```

---

## 6. Design Decisions & Rationale

### 6.1 Element Storage: Plot Coordinates vs Data Coordinates

**Decision**: Store elements in **Plot Space** (pre-transformed).

**Alternatives Considered**:

| Approach | Pros | Cons | Verdict |
|----------|------|------|---------|
| **Store Data, Transform Every Frame** | Conceptually clean, no regeneration | 60fps transform overhead, complex paint code | ❌ Too slow |
| **Store Plot, Regenerate on Zoom/Pan** | Zero paint overhead, simple rendering | Must regenerate on viewport change | ✅ **Chosen** |
| **Store Both Data + Plot** | Best performance | Memory overhead, sync complexity | ❌ Premature optimization |

**Rationale**:
- Chart interactions: pan/zoom happen ~1-2 times per second
- Rendering: happens 60 times per second
- Element creation: < 1ms for 1000 points
- **Optimize for the common case**: Rendering, not viewport changes

---

### 6.2 Coordinate Transformation Responsibility

**Decision**: ChartRenderBox handles **Plot↔Widget**, ChartTransform handles **Data↔Plot**.

**Rationale**:
- Clear separation of concerns
- ChartTransform is reusable (e.g., mini charts, thumbnails)
- ChartRenderBox manages layout-specific concerns (axes, margins)
- Easy to test independently

---

### 6.3 QuadTree Coordinate Space

**Decision**: QuadTree operates in **Plot Space**.

**Rationale**:
- Elements are in plot space → no transform during query
- Spatial queries are frequent (every pointer move)
- Plot space is stable during rendering
- Rebuild on viewport change is acceptable

---

### 6.4 Canvas Clipping Strategy

**Decision**: Clip canvas to plot area during element rendering.

**Rationale**:
- Prevents elements from drawing over axes (visual correctness)
- Automatic viewport culling (GPU-level optimization)
- Simple implementation (one clip rect)
- Minimal performance impact

---

### 6.5 Transform Immutability

**Decision**: ChartTransform is **immutable** (returns new instances).

**Rationale**:
- Functional programming style (easier to reason about)
- No accidental mutation bugs
- Easy to implement undo/redo
- Matches Flutter's philosophy (e.g., TextStyle, BoxDecoration)

---

## 7. Performance Considerations

### 7.1 Element Regeneration Cost

**Scenario**: User zooms, requiring element regeneration.

**Measurements** (estimated):
- 100 points: < 0.1ms
- 1,000 points: ~1ms
- 10,000 points: ~10ms

**Acceptable because**:
- Zoom happens infrequently (~1-2 Hz)
- Target frame time: 16ms (60fps)
- 10ms leaves 6ms for rendering

**Optimization strategies** (if needed):
- Incremental regeneration (batch over multiple frames)
- Viewport culling before creation
- Web workers for data transformation (Flutter web)

---

### 7.2 Spatial Index Rebuild

**Cost**: Same as element regeneration (must reinsert all elements).

**Optimization**: Already optimized (QuadTree insertion is O(log n)).

---

### 7.3 Rendering Pipeline

**Zero-cost transformations during paint**:
- Elements already in plot coordinates
- No per-frame data→plot transformation
- Only canvas translate (GPU operation)

**Measured paint time**:
- 100 elements: < 1ms
- 1,000 elements: ~5ms
- 10,000 elements: ~20ms (may need culling)

---

## 8. Migration Path

### 8.1 Phase 1: ChartTransform Implementation

**Files to Create**:
- `lib/transforms/chart_transform.dart`

**API**:
```dart
class ChartTransform {
  // Constructor, methods as specified in section 3.1
}
```

**Tests**:
- Data→Plot conversion accuracy
- Plot→Data conversion accuracy
- Zoom operations preserve center point
- Pan operations shift viewport correctly
- Y-axis inversion works correctly

---

### 8.2 Phase 2: ChartRenderBox Integration

**Files to Modify**:
- `lib/rendering/chart_render_box.dart`

**Changes**:
1. Add `ChartTransform` field
2. Add `widgetToPlot()` and `plotToWidget()` helpers
3. Modify `performLayout()` to calculate plot area
4. Modify `_rebuildSpatialIndex()` to use plot bounds
5. Modify `paint()` to translate/clip to plot area
6. Modify `hitTest()` to convert coordinates

**Tests**:
- Plot area calculation respects axis margins
- QuadTree bounds match plot area
- Canvas clipping prevents overflow
- Coordinate conversion is correct

---

### 8.3 Phase 3: Element Refactoring

**Files to Modify**:
- `lib/elements/simulated_datapoint.dart`
- `lib/elements/simulated_series.dart`
- `lib/elements/simulated_annotation.dart`

**Changes**:
1. Constructor accepts plot coordinates (not widget coordinates)
2. Documentation clarifies coordinate space
3. No implementation changes (already use relative coords)

**Tests**:
- Elements render at correct positions
- Hit testing works in plot space
- Bounds calculation is correct

---

### 8.4 Phase 4: Example App Update

**Files to Modify**:
- `lib/main.dart`

**Changes**:
1. Define data points in data space
2. Create ChartTransform
3. Transform data to plot before creating elements
4. Pass transformed elements to chart

**Example**:
```dart
// OLD: Direct pixel coordinates
final elements = [
  SimulatedDatapoint(
    id: 'point1',
    center: Offset(100, 200),  // Widget pixels
  ),
];

// NEW: Data space → Transform → Plot space
final dataPoints = [
  DataPoint(x: 1609459200, y: 150.0),  // Data values
];

final transform = ChartTransform(
  dataXMin: 1609459200.0,
  dataXMax: 1640995200.0,
  dataYMin: 100.0,
  dataYMax: 200.0,
  plotWidth: 730.0,
  plotHeight: 540.0,
);

final elements = dataPoints.map((data) {
  final plotPos = transform.dataToPlot(data.x, data.y);
  return DatapointElement(
    id: 'point_${data.x}',
    plotCenter: plotPos,  // Plot pixels
  );
}).toList();
```

---

## 9. Testing Strategy

### 9.1 Unit Tests

**ChartTransform**:
- ✅ Linear data→plot conversion
- ✅ Linear plot→data conversion (inverse)
- ✅ Y-axis inversion
- ✅ Zoom preserves center point
- ✅ Pan shifts viewport correctly
- ✅ Edge cases (zero ranges, negative values)

**ChartRenderBox**:
- ✅ Plot area calculation with/without axes
- ✅ Widget↔Plot coordinate conversion
- ✅ QuadTree bounds match plot area
- ✅ Hit testing outside plot area returns null

---

### 9.2 Integration Tests

**Rendering**:
- ✅ Elements don't overlap axes
- ✅ Canvas clipping works correctly
- ✅ Zoom updates element positions
- ✅ Pan updates element positions

**Interaction**:
- ✅ Can select elements in plot area
- ✅ Cannot select through axis area
- ✅ Hit testing accuracy within 1px
- ✅ Box select respects plot boundaries

---

### 9.3 Visual Regression Tests

**Golden files**:
- Chart with axes (before zoom)
- Chart after 2x zoom
- Chart after pan
- Chart with elements near edges
- Empty chart (no elements)

---

## 10. Future Enhancements

### 10.1 Non-Linear Scales

**Log scale, time scale, etc.**:
```dart
abstract class AxisScale {
  double dataToPixel(double data);
  double pixelToData(double pixel);
}

class LogScale extends AxisScale {
  // Logarithmic data→pixel conversion
}
```

---

### 10.2 Multi-Axis Support

**Secondary Y-axis**:
```dart
class ChartRenderBox {
  Axis? _yAxisLeft;
  Axis? _yAxisRight;
  
  ChartTransform? _transformLeft;
  ChartTransform? _transformRight;
}
```

---

### 10.3 Viewport Culling

**Don't create elements outside viewport**:
```dart
final visibleDataPoints = dataPoints.where((data) {
  return transform.isDataPointVisible(data.x, data.y);
}).toList();
```

---

### 10.4 Streaming Data

**Incremental element updates**:
```dart
void addDataPoint(DataPoint newPoint) {
  final plotPos = _transform!.dataToPlot(newPoint.x, newPoint.y);
  final element = DatapointElement(plotCenter: plotPos);
  
  _elements.add(element);
  _spatialIndex!.insert(element);
  markNeedsPaint();
}
```

---

## 11. Appendix: Coordinate Space Quick Reference

| Operation | Input Space | Output Space | Handler |
|-----------|-------------|--------------|---------|
| Render element | Plot | Widget | Canvas translate |
| Hit test pointer | Widget | Plot | `widgetToPlot()` |
| Data → Render | Data | Plot | `ChartTransform.dataToPlot()` |
| Hit → Data | Plot | Data | `ChartTransform.plotToData()` |
| Axis ticks | Data | Data | TickGenerator |
| Axis labels | Data | Widget | AxisRenderer |
| QuadTree query | Plot | Plot | QuadTree.query() |
| Zoom center | Widget | Plot | `widgetToPlot()` |
| Pan delta | Widget | Plot | No conversion (delta is same) |

---

## 12. Summary

This architecture establishes:

✅ **Three distinct coordinate spaces** with clear boundaries  
✅ **Proper transformation pipeline** between spaces  
✅ **Performance-optimized** element storage (plot coordinates)  
✅ **Correct clipping** prevents axis contamination  
✅ **Foundation for zoom/pan** with viewport management  
✅ **Clean separation** of rendering, interaction, and data concerns  

The implementation will proceed in 4 phases over the following sessions, starting with ChartTransform and culminating in a fully functional zoom/pan system with proper coordinate space separation.

---

**Next Steps**: Begin Phase 1 implementation of ChartTransform class.
