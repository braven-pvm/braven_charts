# Axis System Architecture

**Date**: November 6, 2025  
**Status**: Design & Implementation  
**Purpose**: Implement proper X/Y axes with Cartesian coordinate system to enable proper zoom/pan testing and provide foundation for real chart rendering.

---

## 1. Why Axes Are Critical

### The Problem Without Axes

Without axes, we have:
- ❌ No visual feedback on what data range is visible
- ❌ No way to validate coordinate transforms are correct
- ❌ No way to test zoom/pan properly (can't see if viewport bounds work)
- ❌ No foundation for real chart types (all charts need axes)
- ❌ Arbitrary pixel coordinates instead of meaningful data values

### What Axes Provide

With proper axes:
- ✅ **Visual validation**: See exactly what data range is visible
- ✅ **Transform testing**: Axes prove coordinate conversion works correctly
- ✅ **User orientation**: Users know where they are in the data space
- ✅ **Foundation**: Required for line charts, candlestick charts, etc.
- ✅ **Real coordinates**: Time on X, price on Y, etc.

---

## 2. Architecture Overview

### 2.1 Coordinate Space Layers

```
┌─────────────────────────────────────────────────────────────┐
│ Screen Space (pixels)                                        │
│ ┌─────────────────────────────────────────────────────────┐ │
│ │ Y Axis │ Chart Plot Area                      │ Padding │ │
│ │ Labels │                                      │         │ │
│ │   50   ├──────────────────────────────────────┤         │ │
│ │        │                                      │         │ │
│ │   40   │    • DataPoint (100, 45) in data    │         │ │
│ │        │      renders at (250, 200) on screen│         │ │
│ │   30   │                                      │         │ │
│ │        │                                      │         │ │
│ │ Padding├──────────────────────────────────────┤         │ │
│ └─────────┴──────────────────────────────────────┴─────────┘ │
│            X Axis Labels: 0  20  40  60  80  100             │
└─────────────────────────────────────────────────────────────┘
     └─Data Space (meaningful values: time, price, etc.)─┘
```

### 2.2 Component Hierarchy

```
ChartRenderBox
├── ChartTransform (data ↔ screen conversion)
├── XAxis (bottom axis)
│   ├── AxisScale (maps data range → pixel range)
│   ├── TickGenerator (calculates tick positions)
│   └── AxisRenderer (paints ticks + labels)
├── YAxis (left axis)
│   ├── AxisScale (maps data range → pixel range)
│   ├── TickGenerator (calculates tick positions)
│   └── AxisRenderer (paints ticks + labels)
└── Plot Area (where chart elements render)
```

### 2.3 Layout Structure

```dart
// Screen layout
┌─────────────────────────────────┐
│ Top Padding (10px)               │
├──────┬──────────────────────────┤
│ Y    │ Plot Area                │
│ Axis │ (transformed coordinates)│
│ 60px │                          │
│      │                          │
├──────┴──────────────────────────┤
│ X Axis (40px)                   │
├─────────────────────────────────┤
│ Bottom Padding (10px)           │
└─────────────────────────────────┘
```

---

## 3. Core Components

### 3.1 AxisScale: Data ↔ Pixel Mapping

**Purpose**: Convert between data values and pixel positions.

**Example**:
```dart
// X-axis: data range [0, 100] → screen range [60, 760]
final xScale = LinearScale(
  dataMin: 0,
  dataMax: 100,
  pixelMin: 60,   // Start after Y-axis
  pixelMax: 760,  // End before right padding
);

final screenX = xScale.dataToPixel(50);  // → 410
final dataX = xScale.pixelToData(410);   // → 50
```

**Implementation**:
```dart
class LinearScale {
  final double dataMin;
  final double dataMax;
  final double pixelMin;
  final double pixelMax;
  
  double get dataRange => dataMax - dataMin;
  double get pixelRange => pixelMax - pixelMin;
  double get scale => pixelRange / dataRange;
  
  double dataToPixel(double dataValue) {
    return pixelMin + (dataValue - dataMin) * scale;
  }
  
  double pixelToData(double pixelValue) {
    return dataMin + (pixelValue - pixelMin) / scale;
  }
}
```

### 3.2 TickGenerator: Smart Tick Placement

**Purpose**: Calculate "nice" tick positions at appropriate intervals.

**Algorithm**:
```dart
class TickGenerator {
  List<Tick> generateTicks({
    required double dataMin,
    required double dataMax,
    required double pixelRange,
    int targetTickCount = 10,
  }) {
    // 1. Calculate ideal tick interval
    final dataRange = dataMax - dataMin;
    final roughInterval = dataRange / targetTickCount;
    
    // 2. Round to "nice" number (1, 2, 5, 10, 20, 50, 100, etc.)
    final niceInterval = _makeNice(roughInterval);
    
    // 3. Generate ticks at nice intervals
    final ticks = <Tick>[];
    final startTick = (dataMin / niceInterval).ceil() * niceInterval;
    
    for (double value = startTick; value <= dataMax; value += niceInterval) {
      ticks.add(Tick(value: value, label: _formatLabel(value)));
    }
    
    return ticks;
  }
  
  double _makeNice(double roughInterval) {
    // Find the power of 10
    final exponent = (log(roughInterval) / ln10).floor();
    final fraction = roughInterval / pow(10, exponent);
    
    // Round to 1, 2, or 5
    final niceFraction = fraction <= 1 ? 1.0
                       : fraction <= 2 ? 2.0
                       : fraction <= 5 ? 5.0
                       : 10.0;
    
    return niceFraction * pow(10, exponent);
  }
  
  String _formatLabel(double value) {
    // Smart formatting: "1000" → "1K", "0.001" → "0.001"
    if (value.abs() >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}K';
    }
    if (value.abs() < 0.01 && value != 0) {
      return value.toStringAsExponential(2);
    }
    return value.toStringAsFixed(value.truncate() == value ? 0 : 2);
  }
}
```

**Example**:
```
Data range: [0, 87.3]
Target ticks: 10
Rough interval: 8.73
Nice interval: 10
Generated ticks: 0, 10, 20, 30, 40, 50, 60, 70, 80
```

### 3.3 Axis Configuration

**Purpose**: Configure axis appearance and behavior.

```dart
class AxisConfig {
  final String label;              // "Time" or "Price"
  final AxisOrientation orientation; // horizontal or vertical
  final AxisPosition position;     // bottom, top, left, right
  final TextStyle labelStyle;
  final TextStyle tickLabelStyle;
  final Color axisColor;
  final Color gridColor;
  final bool showGrid;
  final bool showAxisLine;
  final bool showTickMarks;
  final double tickLength;
  final double labelPadding;
  
  const AxisConfig({
    this.label = '',
    required this.orientation,
    required this.position,
    this.labelStyle = const TextStyle(fontSize: 12, color: Colors.black),
    this.tickLabelStyle = const TextStyle(fontSize: 10, color: Colors.black54),
    this.axisColor = Colors.black,
    this.gridColor = const Color(0xFFE0E0E0),
    this.showGrid = true,
    this.showAxisLine = true,
    this.showTickMarks = true,
    this.tickLength = 6,
    this.labelPadding = 8,
  });
}

enum AxisOrientation { horizontal, vertical }
enum AxisPosition { bottom, top, left, right }
```

### 3.4 Axis Class

**Purpose**: Combine scale, ticks, and configuration.

```dart
class Axis {
  final AxisConfig config;
  late LinearScale scale;
  late List<Tick> ticks;
  
  Axis({
    required this.config,
    required double dataMin,
    required double dataMax,
  }) {
    updateDataRange(dataMin, dataMax);
  }
  
  void updateDataRange(double dataMin, double dataMax) {
    scale = LinearScale(
      dataMin: dataMin,
      dataMax: dataMax,
      pixelMin: 0,    // Will be updated in layout
      pixelMax: 100,  // Will be updated in layout
    );
    
    ticks = TickGenerator().generateTicks(
      dataMin: dataMin,
      dataMax: dataMax,
      pixelRange: scale.pixelRange,
    );
  }
  
  void updatePixelRange(double pixelMin, double pixelMax) {
    scale = LinearScale(
      dataMin: scale.dataMin,
      dataMax: scale.dataMax,
      pixelMin: pixelMin,
      pixelMax: pixelMax,
    );
  }
}

class Tick {
  final double value;
  final String label;
  
  const Tick({required this.value, required this.label});
}
```

### 3.5 AxisRenderer: Painting

**Purpose**: Draw axis line, ticks, labels, and grid.

```dart
class AxisRenderer {
  final Axis axis;
  
  AxisRenderer(this.axis);
  
  void paint(Canvas canvas, Size chartSize) {
    final config = axis.config;
    final scale = axis.scale;
    final ticks = axis.ticks;
    
    if (config.orientation == AxisOrientation.horizontal) {
      _paintHorizontalAxis(canvas, chartSize, scale, ticks, config);
    } else {
      _paintVerticalAxis(canvas, chartSize, scale, ticks, config);
    }
  }
  
  void _paintHorizontalAxis(
    Canvas canvas,
    Size chartSize,
    LinearScale scale,
    List<Tick> ticks,
    AxisConfig config,
  ) {
    final y = config.position == AxisPosition.bottom
        ? chartSize.height - 40  // Axis Y position
        : 40;
    
    // Draw axis line
    if (config.showAxisLine) {
      canvas.drawLine(
        Offset(scale.pixelMin, y),
        Offset(scale.pixelMax, y),
        Paint()
          ..color = config.axisColor
          ..strokeWidth = 1,
      );
    }
    
    // Draw ticks and labels
    for (final tick in ticks) {
      final x = scale.dataToPixel(tick.value);
      
      // Draw tick mark
      if (config.showTickMarks) {
        canvas.drawLine(
          Offset(x, y),
          Offset(x, y + config.tickLength),
          Paint()
            ..color = config.axisColor
            ..strokeWidth = 1,
        );
      }
      
      // Draw grid line
      if (config.showGrid) {
        canvas.drawLine(
          Offset(x, 0),
          Offset(x, chartSize.height - 40),
          Paint()
            ..color = config.gridColor
            ..strokeWidth = 0.5,
        );
      }
      
      // Draw tick label
      final textPainter = TextPainter(
        text: TextSpan(text: tick.label, style: config.tickLabelStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      
      textPainter.paint(
        canvas,
        Offset(x - textPainter.width / 2, y + config.tickLength + config.labelPadding),
      );
    }
    
    // Draw axis label
    if (config.label.isNotEmpty) {
      final labelPainter = TextPainter(
        text: TextSpan(text: config.label, style: config.labelStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      
      labelPainter.paint(
        canvas,
        Offset(
          chartSize.width / 2 - labelPainter.width / 2,
          chartSize.height - 15,
        ),
      );
    }
  }
  
  void _paintVerticalAxis(
    Canvas canvas,
    Size chartSize,
    LinearScale scale,
    List<Tick> ticks,
    AxisConfig config,
  ) {
    final x = config.position == AxisPosition.left
        ? 60.0  // Axis X position (leave room for labels)
        : chartSize.width - 60;
    
    // Draw axis line
    if (config.showAxisLine) {
      canvas.drawLine(
        Offset(x, scale.pixelMin),
        Offset(x, scale.pixelMax),
        Paint()
          ..color = config.axisColor
          ..strokeWidth = 1,
      );
    }
    
    // Draw ticks and labels
    for (final tick in ticks) {
      final y = scale.dataToPixel(tick.value);
      
      // Draw tick mark
      if (config.showTickMarks) {
        canvas.drawLine(
          Offset(x - config.tickLength, y),
          Offset(x, y),
          Paint()
            ..color = config.axisColor
            ..strokeWidth = 1,
        );
      }
      
      // Draw grid line
      if (config.showGrid) {
        canvas.drawLine(
          Offset(x, y),
          Offset(chartSize.width - 10, y),
          Paint()
            ..color = config.gridColor
            ..strokeWidth = 0.5,
        );
      }
      
      // Draw tick label (right-aligned)
      final textPainter = TextPainter(
        text: TextSpan(text: tick.label, style: config.tickLabelStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      
      textPainter.paint(
        canvas,
        Offset(x - textPainter.width - config.tickLength - config.labelPadding, y - textPainter.height / 2),
      );
    }
    
    // Draw axis label (rotated 90°)
    if (config.label.isNotEmpty) {
      canvas.save();
      canvas.translate(15, chartSize.height / 2);
      canvas.rotate(-pi / 2);
      
      final labelPainter = TextPainter(
        text: TextSpan(text: config.label, style: config.labelStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      
      labelPainter.paint(canvas, Offset(-labelPainter.width / 2, 0));
      canvas.restore();
    }
  }
}
```

---

## 4. Integration with ChartTransform

### 4.1 The Critical Relationship

**Before Zoom/Pan**:
```
Data Space: [0, 100] on X, [0, 50] on Y
Screen Space: [60, 760] on X, [10, 550] on Y
Axis scales map 1:1 with data space
```

**After Zoom (2x)**:
```
Data Space (viewport): [25, 75] on X, [12.5, 37.5] on Y  ← CHANGED
Screen Space: [60, 760] on X, [10, 550] on Y             ← SAME
Axis scales must update to new viewport!
```

### 4.2 Update Flow

```dart
class ChartRenderBox extends RenderBox {
  ChartTransform? _transform;
  Axis? _xAxis;
  Axis? _yAxis;
  
  void _updateAxesFromTransform() {
    if (_transform == null || _xAxis == null || _yAxis == null) return;
    
    final dataViewport = _transform!.dataViewport;
    
    // Update X-axis data range to visible viewport
    _xAxis!.updateDataRange(
      dataViewport.left,
      dataViewport.right,
    );
    
    // Update Y-axis data range to visible viewport
    // Note: Y-axis is inverted (high values at top)
    _yAxis!.updateDataRange(
      dataViewport.top,
      dataViewport.bottom,
    );
    
    // Regenerate ticks for new range
    _xAxis!.ticks = TickGenerator().generateTicks(
      dataMin: dataViewport.left,
      dataMax: dataViewport.right,
      pixelRange: _xAxis!.scale.pixelRange,
    );
    
    _yAxis!.ticks = TickGenerator().generateTicks(
      dataMin: dataViewport.top,
      dataMax: dataViewport.bottom,
      pixelRange: _yAxis!.scale.pixelRange,
    );
  }
  
  void _handleScroll(Offset screenPosition, Offset scrollDelta) {
    final zoomFactor = 1.0 + (scrollDelta.dy * -0.001);
    _transform!.zoomAroundScreenPoint(screenPosition, zoomFactor);
    
    // Update axes to reflect new viewport
    _updateAxesFromTransform();
    
    markNeedsPaint();
  }
  
  void _handlePan(Offset delta) {
    _transform!.panByScreenDelta(delta);
    
    // Update axes to reflect new viewport
    _updateAxesFromTransform();
    
    markNeedsPaint();
  }
}
```

### 4.3 Layout Calculation

```dart
@override
void performLayout() {
  size = constraints.biggest;
  
  // Define layout regions
  const yAxisWidth = 60.0;
  const xAxisHeight = 40.0;
  const padding = 10.0;
  
  // Plot area (where elements render)
  final plotArea = Rect.fromLTRB(
    yAxisWidth,
    padding,
    size.width - padding,
    size.height - xAxisHeight - padding,
  );
  
  // Update axis pixel ranges
  _xAxis?.updatePixelRange(plotArea.left, plotArea.right);
  _yAxis?.updatePixelRange(plotArea.bottom, plotArea.top); // Inverted Y
  
  // Update transform screen viewport
  _transform?.setScreenViewport(plotArea);
  
  // Update axes from current viewport
  _updateAxesFromTransform();
}
```

---

## 5. Y-Axis Inversion

### The Problem

Canvas coordinates:
- Y=0 is at **top**
- Y increases **downward**

Chart data:
- Y=0 should be at **bottom**
- Y should increase **upward**

### The Solution

```dart
class LinearScale {
  final bool invertY;
  
  LinearScale({
    required this.dataMin,
    required this.dataMax,
    required this.pixelMin,
    required this.pixelMax,
    this.invertY = false,
  });
  
  double dataToPixel(double dataValue) {
    final pixel = pixelMin + (dataValue - dataMin) * scale;
    return invertY ? pixelMax - (pixel - pixelMin) : pixel;
  }
  
  double pixelToData(double pixelValue) {
    final adjustedPixel = invertY ? pixelMax - (pixelValue - pixelMin) : pixelValue;
    return dataMin + (adjustedPixel - pixelMin) / scale;
  }
}

// Usage
_yAxis = Axis(
  config: AxisConfig(
    orientation: AxisOrientation.vertical,
    position: AxisPosition.left,
    label: 'Price',
  ),
  dataMin: 0,
  dataMax: 100,
  invertY: true,  // ← Critical for Y-axis
);
```

---

## 6. Example: Time Series Chart

### Data Setup

```dart
// Generate realistic time series data
final now = DateTime.now().millisecondsSinceEpoch / 1000; // Unix timestamp
final data = List.generate(100, (i) {
  return DataPoint(
    x: now - (100 - i) * 3600, // Hourly data going back 100 hours
    y: 50 + 20 * sin(i * 0.1) + Random().nextDouble() * 5, // Sine wave with noise
  );
});

// Data bounds
final xMin = data.first.x;
final xMax = data.last.x;
final yMin = data.map((p) => p.y).reduce(min);
final yMax = data.map((p) => p.y).reduce(max);
```

### Axis Configuration

```dart
final xAxis = Axis(
  config: AxisConfig(
    orientation: AxisOrientation.horizontal,
    position: AxisPosition.bottom,
    label: 'Time',
    tickLabelStyle: TextStyle(fontSize: 10, color: Colors.black87),
  ),
  dataMin: xMin,
  dataMax: xMax,
);

final yAxis = Axis(
  config: AxisConfig(
    orientation: AxisOrientation.vertical,
    position: AxisPosition.left,
    label: 'Price (\$)',
    tickLabelStyle: TextStyle(fontSize: 10, color: Colors.black87),
  ),
  dataMin: yMin,
  dataMax: yMax,
  invertY: true,
);
```

### Custom Formatters

```dart
// X-axis: Format timestamps as dates
String formatTimestamp(double timestamp) {
  final date = DateTime.fromMillisecondsSinceEpoch((timestamp * 1000).toInt());
  return '${date.month}/${date.day}';
}

// Y-axis: Format as currency
String formatPrice(double price) {
  return '\$${price.toStringAsFixed(2)}';
}

// Use in TickGenerator
ticks.add(Tick(
  value: value,
  label: isXAxis ? formatTimestamp(value) : formatPrice(value),
));
```

---

## 7. Testing Strategy

### 7.1 Visual Tests

```dart
testWidgets('Axes render correctly', (tester) async {
  await tester.pumpWidget(ChartWidget(
    xAxis: Axis(dataMin: 0, dataMax: 100),
    yAxis: Axis(dataMin: 0, dataMax: 50),
  ));
  
  // Find axis labels
  expect(find.text('0'), findsWidgets);
  expect(find.text('100'), findsOneWidget);
  expect(find.text('50'), findsOneWidget);
});
```

### 7.2 Transform Validation

```dart
test('Axes update after zoom', () {
  final axis = Axis(dataMin: 0, dataMax: 100);
  
  // Zoom to show [25, 75]
  axis.updateDataRange(25, 75);
  
  // Verify ticks regenerated for new range
  expect(axis.ticks.first.value, greaterThanOrEqualTo(25));
  expect(axis.ticks.last.value, lessThanOrEqualTo(75));
});
```

### 7.3 Scale Accuracy

```dart
test('LinearScale converts correctly', () {
  final scale = LinearScale(
    dataMin: 0,
    dataMax: 100,
    pixelMin: 60,
    pixelMax: 760,
  );
  
  expect(scale.dataToPixel(0), 60);
  expect(scale.dataToPixel(50), 410);
  expect(scale.dataToPixel(100), 760);
  
  expect(scale.pixelToData(60), 0);
  expect(scale.pixelToData(410), 50);
  expect(scale.pixelToData(760), 100);
});
```

---

## 8. Implementation Checklist

### Phase 1: Core Classes
- [ ] Create `LinearScale` class with data ↔ pixel conversion
- [ ] Create `TickGenerator` with nice interval algorithm
- [ ] Create `Tick` class for tick values + labels
- [ ] Create `AxisConfig` for appearance configuration
- [ ] Create `Axis` class combining scale + ticks + config

### Phase 2: Rendering
- [ ] Create `AxisRenderer` class
- [ ] Implement horizontal axis painting
- [ ] Implement vertical axis painting
- [ ] Add grid line support
- [ ] Add axis label support
- [ ] Handle Y-axis inversion

### Phase 3: Integration
- [ ] Add X/Y axes to `ChartRenderBox`
- [ ] Update `performLayout()` to reserve axis space
- [ ] Update `paint()` to render axes
- [ ] Connect axes to `ChartTransform`
- [ ] Update axes when viewport changes

### Phase 4: Testing
- [ ] Create example with time series data
- [ ] Test axis rendering
- [ ] Test tick generation
- [ ] Test zoom/pan updates
- [ ] Test label formatting
- [ ] Verify coordinate accuracy

---

## 9. Success Criteria

✅ **Functional**:
- Axes render with appropriate ticks and labels
- Ticks use "nice" intervals (1, 2, 5, 10, 20, 50, 100...)
- Labels formatted appropriately (currency, dates, etc.)
- Grid lines visible and aligned with ticks
- Y-axis correctly inverted (high values at top)
- Axes update correctly during zoom/pan

✅ **Visual**:
- Axes look clean and professional
- Labels are readable and properly aligned
- Grid lines enhance readability without clutter
- Tick spacing is visually balanced

✅ **Integration**:
- Axes accurately reflect current data viewport
- Zooming updates visible data range on axes
- Panning updates visible data range on axes
- Element positions align perfectly with axis coordinates

---

**Next Steps**: Implement Phase 1 - Core axis classes.
