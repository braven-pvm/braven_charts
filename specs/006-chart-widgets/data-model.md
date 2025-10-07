# Data Model: Chart Widgets with Annotations

**Feature**: 006-chart-widgets  
**Phase**: Phase 1 - Design & Contracts  
**Date**: October 6, 2025

---

## Overview

This document defines the data entities for the Chart Widgets layer (Layer 5). The layer provides user-facing widgets that wrap chart implementations, requiring minimal new entities (most reuse Layers 0-4) and focusing on configuration and control interfaces.

---

## Entity Diagram

```
┌─────────────────────────────────────────────────────────────────────┐
│                          BravenChart Widget                          │
│  ┌────────────────────┐  ┌─────────────────┐  ┌─────────────────┐  │
│  │   ChartController  │  │   AxisConfig    │  │ ChartAnnotation │  │
│  │  (programmatic)    │  │ (configuration) │  │   (overlay)     │  │
│  └────────────────────┘  └─────────────────┘  └─────────────────┘  │
└─────────────────────────────────────────────────────────────────────┘
                                  │
                         Uses (from Layer 0-4)
                                  ▼
         ┌────────────────────────────────────────────────┐
         │  ChartSeries  │  ChartDataPoint  │  ChartTheme │
         └────────────────────────────────────────────────┘
```

---

## Entity Definitions

### 1. BravenChart (Widget)

**Purpose**: Primary user-facing widget for rendering charts

**Type**: StatefulWidget (Flutter widget class)

**Properties**:

| Property | Type | Required | Default | Description |
|----------|------|----------|---------|-------------|
| `chartType` | `ChartType` | Yes | - | Type of chart (line, area, bar, scatter) |
| `series` | `List<ChartSeries>` | Yes | - | Data series to display |
| `width` | `double?` | No | Parent constraint | Chart width |
| `height` | `double?` | No | Parent constraint | Chart height |
| `theme` | `ChartTheme?` | No | Theme.of(context) | Visual theme |
| `xAxis` | `AxisConfig?` | No | AxisConfig.defaults() | X-axis configuration |
| `yAxis` | `AxisConfig?` | No | AxisConfig.defaults() | Y-axis configuration |
| `annotations` | `List<ChartAnnotation>` | No | `[]` | Static annotations |
| `controller` | `ChartController?` | No | null | Programmatic control |
| `dataStream` | `Stream<ChartDataPoint>?` | No | null | Real-time data stream |
| `title` | `String?` | No | null | Chart title |
| `subtitle` | `String?` | No | null | Chart subtitle |
| `showLegend` | `bool` | No | true | Show legend |
| `showToolbar` | `bool` | No | false | Show toolbar |
| `interactiveAnnotations` | `bool` | No | false | Enable annotation interaction |
| `loadingWidget` | `Widget?` | No | CircularProgressIndicator | Loading state widget |
| `errorWidget` | `Widget Function(Object error)?` | No | Text('Error') | Error state widget |
| `onPointTap` | `void Function(ChartDataPoint)?` | No | null | Point tap callback |
| `onPointHover` | `void Function(ChartDataPoint)?` | No | null | Point hover callback |
| `onBackgroundTap` | `void Function(Offset)?` | No | null | Background tap callback |
| `onSeriesSelected` | `void Function(String seriesId)?` | No | null | Series selection callback |
| `onAnnotationTap` | `void Function(ChartAnnotation)?` | No | null | Annotation tap callback |
| `onAnnotationDragged` | `void Function(ChartAnnotation, Offset)?` | No | null | Annotation drag callback |

**State Management**: `_BravenChartState` holds mutable state, resources, lifecycle

**Relationships**:
- **Uses** ChartSeries (Layer 0) for data
- **Uses** ChartTheme (Layer 3) for styling
- **Creates** ChartController (optional)
- **Contains** List<ChartAnnotation>
- **Configures** AxisConfig for both axes

**Validation Rules**:
- At least one series required (`series.isNotEmpty`)
- Width/height must be positive if specified
- Cannot provide both `dataStream` and static `series` updates simultaneously
- If `interactiveAnnotations = true`, annotations must have `allowDragging = true`

**Factory Constructors**:
```dart
// Simplified data input
BravenChart.fromValues({
  required ChartType chartType,
  required String seriesId,
  required List<double> yValues,
  List<double>? xValues, // Auto-generated if null
  // ... other params
});

BravenChart.fromMap({
  required ChartType chartType,
  required String seriesId,
  required Map<dynamic, double> data, // key=x, value=y
  // ... other params
});

BravenChart.fromJson({
  required ChartType chartType,
  required String json, // JSON array of {x, y} objects
  // ... other params
});
```

---

### 2. ChartController (Controller)

**Purpose**: Programmatic control of chart data and annotations

**Type**: ChangeNotifier (extends Flutter's ChangeNotifier)

**Properties**:

| Property | Type | Access | Description |
|----------|------|--------|-------------|
| `_seriesData` | `Map<String, List<ChartDataPoint>>` | Private | Internal series data storage |
| `_annotations` | `Map<String, ChartAnnotation>` | Private | Internal annotations storage |
| `_nextAnnotationId` | `int` | Private | Auto-incrementing annotation ID |

**Methods - Data Management**:

| Method | Parameters | Returns | Description |
|--------|------------|---------|-------------|
| `addPoint` | `String seriesId, ChartDataPoint point` | `void` | Add point to series, notify listeners |
| `removeOldestPoint` | `String seriesId` | `void` | Remove oldest point (sliding window) |
| `clearSeries` | `String seriesId` | `void` | Clear all points in series |
| `getAllSeries` | - | `Map<String, List<ChartDataPoint>>` | Get copy of all series data |

**Methods - Annotation Management**:

| Method | Parameters | Returns | Description |
|--------|------------|---------|-------------|
| `addAnnotation` | `ChartAnnotation annotation` | `String` | Add annotation, return auto-generated ID |
| `removeAnnotation` | `String annotationId` | `void` | Remove annotation by ID |
| `updateAnnotation` | `String annotationId, ChartAnnotation annotation` | `void` | Update existing annotation |
| `getAnnotation` | `String annotationId` | `ChartAnnotation?` | Get annotation by ID (nullable) |
| `getAllAnnotations` | - | `List<ChartAnnotation>` | Get copy of all annotations |
| `clearAnnotations` | - | `void` | Remove all annotations |
| `findAnnotationsAt` | `Offset position` | `List<ChartAnnotation>` | Hit-test annotations at screen position |

**Lifecycle**:
- **Created**: By widget (internal) or passed by user (external)
- **Attached**: Widget subscribes in `initState()`
- **Detached**: Widget unsubscribes in `dispose()`
- **Disposed**: If created by widget, disposed with widget; if external, user responsibility

**Relationships**:
- **Observed by** BravenChart widget (listener pattern)
- **Manages** ChartDataPoint collections per series
- **Manages** ChartAnnotation collection

**Validation Rules**:
- Series ID must exist before adding points
- Annotation ID must exist before update/remove
- Point coordinates must be finite (no NaN, Infinity)

---

### 3. AxisConfig (Configuration)

**Purpose**: Comprehensive axis configuration

**Type**: Immutable value object (Dart class with const constructor)

**Properties**:

| Property | Type | Required | Default | Description |
|----------|------|----------|---------|-------------|
| **Visibility** ||||
| `showAxis` | `bool` | No | true | Show axis line |
| `showGrid` | `bool` | No | true | Show grid lines |
| `showTicks` | `bool` | No | true | Show tick marks |
| `showLabels` | `bool` | No | true | Show labels |
| **Range** ||||
| `range` | `AxisRange?` | No | null | Fixed range (null = auto-calculate) |
| `allowZoom` | `bool` | No | false | Enable zoom interaction |
| `allowPan` | `bool` | No | false | Enable pan interaction |
| **Axis Line** ||||
| `axisColor` | `Color?` | No | Theme default | Axis line color |
| `axisWidth` | `double` | No | 1.0 | Axis line width |
| `axisPosition` | `AxisPosition` | No | AxisPosition.left/bottom | Axis position (left/right/top/bottom) |
| **Grid Lines** ||||
| `gridColor` | `Color?` | No | Theme default | Grid line color |
| `gridWidth` | `double` | No | 0.5 | Grid line width |
| `gridDashPattern` | `List<double>?` | No | null | Dash pattern (null = solid) |
| `showMinorGrid` | `bool` | No | false | Show minor grid lines |
| `minorGridColor` | `Color?` | No | Theme default | Minor grid color |
| **Ticks** ||||
| `tickLength` | `double` | No | 6.0 | Tick mark length |
| `tickWidth` | `double` | No | 1.0 | Tick mark width |
| `tickColor` | `Color?` | No | Theme default | Tick color |
| `customTickPositions` | `List<double>?` | No | null | Custom tick positions (null = auto) |
| **Labels** ||||
| `label` | `String?` | No | null | Axis label text |
| `labelFormatter` | `AxisLabelFormatter?` | No | null | Custom label formatter |
| `maxLabels` | `int?` | No | null | Max number of labels (null = auto) |
| `labelRotation` | `double` | No | 0.0 | Label rotation in degrees |
| `labelOffset` | `Offset` | No | Offset.zero | Label position offset |
| `labelStyle` | `TextStyle?` | No | Theme default | Label text style |
| **Advanced** ||||
| `highlightZeroLine` | `bool` | No | false | Emphasize zero line |
| `zeroLineColor` | `Color?` | No | Theme default | Zero line color |
| `zeroLineWidth` | `double` | No | 1.5 | Zero line width |
| `logarithmic` | `bool` | No | false | Use logarithmic scale |
| `inverted` | `bool` | No | false | Invert axis direction |

**Factory Constructors**:

| Factory | Description | Configuration |
|---------|-------------|---------------|
| `AxisConfig.defaults()` | Standard axis | All components visible |
| `AxisConfig.hidden()` | No axis (sparkline) | All components hidden |
| `AxisConfig.minimal()` | Grid only | Axis line + ticks + labels hidden |
| `AxisConfig.gridOnly()` | Grid only | Axis + ticks + labels hidden |

**Methods**:
```dart
AxisConfig copyWith({...}); // Create modified copy
```

**Relationships**:
- **Used by** BravenChart for X and Y axes
- **References** ChartTheme for default colors

**Validation Rules**:
- Line widths must be positive
- Tick length must be positive
- Label rotation must be -180 to 180 degrees
- If `range` specified, min < max
- `maxLabels` must be positive if specified

---

### 4. ChartAnnotation (Base Class)

**Purpose**: Base class for all annotation types

**Type**: Abstract class (Dart sealed class pattern)

**Common Properties**:

| Property | Type | Required | Default | Description |
|----------|------|----------|---------|-------------|
| `id` | `String?` | No | Auto-generated | Unique identifier |
| `label` | `String?` | No | null | Annotation label text |
| `style` | `AnnotationStyle?` | No | Theme default | Visual styling |
| `allowDragging` | `bool` | No | false | Enable drag interaction |
| `allowEditing` | `bool` | No | false | Enable edit interaction |
| `zIndex` | `int` | No | 0 | Rendering order (higher = foreground) |

**Subtypes** (5 annotation types):

#### 4.1 TextAnnotation

**Purpose**: Free-floating text label

**Additional Properties**:

| Property | Type | Required | Default | Description |
|----------|------|----------|---------|-------------|
| `position` | `Offset` | Yes | - | Screen position (x, y in pixels) |
| `anchor` | `AnnotationAnchor` | No | topLeft | Anchor point (topLeft, center, bottomRight, etc.) |
| `backgroundColor` | `Color?` | No | null | Background fill color (null = transparent) |
| `borderColor` | `Color?` | No | null | Border color (null = no border) |

**Example**:
```dart
TextAnnotation(
  position: Offset(100, 50),
  label: 'Important Event',
  style: AnnotationStyle(fontSize: 12),
  allowDragging: true,
)
```

#### 4.2 PointAnnotation

**Purpose**: Mark specific data point

**Additional Properties**:

| Property | Type | Required | Default | Description |
|----------|------|----------|---------|-------------|
| `seriesId` | `String` | Yes | - | Target series ID |
| `dataPointIndex` | `int` | Yes | - | Index of data point in series |
| `offset` | `Offset` | No | Offset(0, -10) | Label offset from point |
| `markerShape` | `MarkerShape` | No | MarkerShape.star | Marker shape (star, circle, triangle, etc.) |
| `markerSize` | `double` | No | 12.0 | Marker size in pixels |
| `markerColor` | `Color?` | No | Theme default | Marker fill color |

**Behavior**: Moves with data point when data updates

**Example**:
```dart
PointAnnotation(
  seriesId: 'AAPL',
  dataPointIndex: 42,
  label: 'Peak Price',
  markerShape: MarkerShape.star,
)
```

#### 4.3 RangeAnnotation

**Purpose**: Highlight rectangular area (time period or value range)

**Additional Properties**:

| Property | Type | Required | Default | Description |
|----------|------|----------|---------|-------------|
| `startX` | `double` | Yes | - | Range start (X-axis value) |
| `endX` | `double` | Yes | - | Range end (X-axis value) |
| `startY` | `double?` | No | null | Range start Y (null = full Y range) |
| `endY` | `double?` | No | null | Range end Y (null = full Y range) |
| `fillColor` | `Color` | No | Semi-transparent | Fill color for range |
| `borderColor` | `Color?` | No | null | Border color (null = no border) |
| `labelPosition` | `AnnotationAnchor` | No | topCenter | Label position within range |

**Example**:
```dart
RangeAnnotation(
  startX: 1609459200000, // Jan 1, 2021
  endX: 1640995200000,   // Dec 31, 2021
  label: 'Recession Period',
  fillColor: Colors.red.withOpacity(0.2),
)
```

#### 4.4 ThresholdAnnotation

**Purpose**: Reference line (horizontal or vertical)

**Additional Properties**:

| Property | Type | Required | Default | Description |
|----------|------|----------|---------|-------------|
| `axis` | `AnnotationAxis` | Yes | - | Target axis (x or y) |
| `value` | `double` | Yes | - | Threshold value on axis |
| `lineColor` | `Color` | No | Theme default | Line color |
| `lineWidth` | `double` | No | 1.5 | Line width |
| `dashPattern` | `List<double>?` | No | null | Dash pattern (null = solid) |
| `labelPosition` | `double` | No | 0.9 | Label position along line (0.0 = start, 1.0 = end) |

**Example**:
```dart
ThresholdAnnotation(
  axis: AnnotationAxis.y,
  value: 100000,
  label: 'Sales Target',
  lineColor: Colors.green,
  dashPattern: [5, 5],
)
```

#### 4.5 TrendAnnotation

**Purpose**: Statistical overlay (regression, moving average)

**Additional Properties**:

| Property | Type | Required | Default | Description |
|----------|------|----------|---------|-------------|
| `seriesId` | `String` | Yes | - | Source series for calculation |
| `trendType` | `TrendType` | Yes | - | Type of trend (linear, polynomial, movingAverage) |
| `windowSize` | `int?` | No | null | Window size for moving average (required if type = movingAverage) |
| `degree` | `int?` | No | 2 | Polynomial degree (required if type = polynomial) |
| `lineColor` | `Color` | No | Theme default | Trend line color |
| `lineWidth` | `double` | No | 2.0 | Trend line width |
| `dashPattern` | `List<double>?` | No | null | Dash pattern (null = solid) |

**Behavior**: Automatically recalculates when source data changes

**Example**:
```dart
TrendAnnotation(
  seriesId: 'temperature',
  trendType: TrendType.movingAverage,
  windowSize: 7,
  label: '7-Day Average',
  lineColor: Colors.orange,
)
```

---

### 5. Supporting Types

#### ChartType (Enum)
```dart
enum ChartType {
  line,    // Line chart
  area,    // Area chart
  bar,     // Bar chart
  scatter, // Scatter plot
}
```

#### AxisPosition (Enum)
```dart
enum AxisPosition {
  left,   // Y-axis left side
  right,  // Y-axis right side
  top,    // X-axis top
  bottom, // X-axis bottom
}
```

#### AxisRange (Value Object)
```dart
class AxisRange {
  final double min;
  final double max;
  
  const AxisRange(this.min, this.max);
  factory AxisRange.fixed(double min, double max);
  factory AxisRange.centered(double center, double range);
}
```

#### AnnotationAxis (Enum)
```dart
enum AnnotationAxis {
  x, // Horizontal threshold
  y, // Vertical threshold
}
```

#### AnnotationAnchor (Enum)
```dart
enum AnnotationAnchor {
  topLeft, topCenter, topRight,
  centerLeft, center, centerRight,
  bottomLeft, bottomCenter, bottomRight,
}
```

#### TrendType (Enum)
```dart
enum TrendType {
  linear,         // y = mx + b
  polynomial,     // y = ax^n + bx^(n-1) + ... + c
  movingAverage,  // Simple moving average
}
```

#### MarkerShape (Enum)
```dart
enum MarkerShape {
  circle, square, triangle, diamond, cross, plus, star,
}
```

#### AnnotationStyle (Value Object)
```dart
class AnnotationStyle {
  final TextStyle? textStyle;
  final Color? backgroundColor;
  final Color? borderColor;
  final double borderWidth;
  final double padding;
  
  const AnnotationStyle({...});
}
```

#### AxisLabelFormatter (Typedef)
```dart
typedef AxisLabelFormatter = String Function(double value);
```

---

## Entity Relationships

### BravenChart → ChartController (Optional Composition)
- Widget MAY create internal controller OR accept external controller
- Widget subscribes to controller's ChangeNotifier in initState
- Widget unsubscribes in dispose
- Widget disposes internal controller, leaves external controller

### BravenChart → AxisConfig (Configuration)
- Widget has two AxisConfig instances (xAxis, yAxis)
- Immutable value objects passed to rendering layer
- Default to AxisConfig.defaults() if not specified

### BravenChart → ChartAnnotation (Collection)
- Widget contains List<ChartAnnotation>
- Static annotations from constructor OR dynamic from controller
- Controller manages annotations separately from widget's list
- Merged during rendering (widget's + controller's)

### ChartController → ChartDataPoint (Collection per Series)
- Controller stores Map<String, List<ChartDataPoint>>
- Each series ID maps to ordered list of points
- Points added/removed via controller methods

### ChartController → ChartAnnotation (Collection)
- Controller stores Map<String, ChartAnnotation>
- Auto-generated IDs if not provided
- CRUD operations notify listeners

### ChartAnnotation → ChartSeries (Reference for some types)
- PointAnnotation references seriesId + dataPointIndex
- TrendAnnotation references seriesId for calculation
- Other types independent (TextAnnotation, RangeAnnotation, ThresholdAnnotation)

---

## Data Flow

### 1. Static Chart Creation
```
User → BravenChart(chartType, series, xAxis, yAxis, annotations)
       ↓
   _BravenChartState.initState()
       ↓
   Create RenderPipeline, ObjectPools
       ↓
   build() → CustomPaint(painter: _ChartPainter)
       ↓
   _ChartPainter.paint(canvas, size)
       ↓
   Render chart layer + annotations
```

### 2. Real-Time Streaming
```
External Stream<ChartDataPoint> → BravenChart(dataStream: ...)
                                         ↓
                              _BravenChartState.initState()
                                         ↓
                              Subscribe with throttling (16ms)
                                         ↓
                              onData(point) → setState(() { add point })
                                         ↓
                              build() → Repaint with new data
```

### 3. Controller-Based Updates
```
User Code → controller.addPoint(seriesId, point)
                  ↓
            ChartController.notifyListeners()
                  ↓
            _BravenChartState.listener() → setState(() {})
                  ↓
            build() → Repaint with new data
```

### 4. Annotation Interaction
```
User Tap → GestureDetector.onTapDown(details)
              ↓
         findAnnotationsAt(details.localPosition)
              ↓
         widget.onAnnotationTap?.call(annotation)
              ↓
         User callback handles event
```

---

## Validation Rules Summary

### BravenChart
- ✅ At least one series required
- ✅ Width/height must be positive
- ✅ Cannot mix static series with dataStream
- ✅ Interactive annotations require allowDragging

### ChartController
- ✅ Series must exist before adding points
- ✅ Annotation ID must exist for update/remove
- ✅ Point coordinates must be finite

### AxisConfig
- ✅ Widths must be positive
- ✅ Rotation must be -180° to 180°
- ✅ Range min < max
- ✅ maxLabels must be positive

### ChartAnnotation
- ✅ PointAnnotation: seriesId must exist, index must be valid
- ✅ RangeAnnotation: startX < endX
- ✅ TrendAnnotation: windowSize required for moving average
- ✅ All: z-index determines rendering order

---

## Performance Considerations

### Memory
- **ChartController**: O(n) storage where n = total data points across all series
- **Annotations**: O(m) storage where m = number of annotations
- **AxisConfig**: Constant size (value object)

### Computational
- **Auto-ranging**: O(n) scan to find min/max across all series
- **Trend Calculation**: O(n) for linear regression, O(n × w) for moving average (w = window size)
- **Hit-Testing**: O(m) scan through annotations (spatial index for m > 500)

### Limits
- **Data Points**: 10,000 per series (viewport culling beyond)
- **Annotations**: 500 total (performance warning above)
- **Series**: 10 per chart (UX recommendation, not hard limit)

---

## Next Steps

Phase 1 data model complete ✅ → Continue with:
1. **contracts/**: Generate API contract files
2. **quickstart.md**: 5-minute guide
3. **Contract tests**: Failing tests for all entities
