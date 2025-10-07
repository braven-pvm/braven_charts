# Annotations and Markers Integration in BravenChart

**Date**: October 6, 2025  
**Status**: SPECIFIED  
**Related**: FR-013 in spec.md, ANNOTATION_SYSTEM_ARCHITECTURE.md

---

## Overview

This document explains how **annotations and markers** are integrated into the BravenChart widget (Layer 5), connecting the user-facing widget API to the underlying Annotation System (Layer 7).

---

## Key Distinction: Markers vs Annotations

### Data Point Markers
**Purpose**: Visual indicators on data points (part of chart styling)

```dart
BravenChart(
  chartType: ChartType.line,
  series: salesData,
  config: ChartConfig(
    showDataPointMarkers: true,
    dataPointMarkerStyle: MarkerStyle.circle(size: 6.0),
  ),
)
```

**Characteristics**:
- Applied uniformly or per-series
- Always tied to data points
- Render AS PART of the chart layer
- Configuration via `ChartConfig` or `ChartSeries`
- No user interaction (static visual)
- Automatic with data updates

**Use Cases**:
- Show all points on line chart
- Different shapes per series
- Hover markers
- Scatter plot markers

---

### Annotations
**Purpose**: Semantic overlays with labels and context

```dart
BravenChart(
  chartType: ChartType.line,
  series: salesData,
  annotations: [
    PointAnnotation(
      seriesId: 'sales',
      dataPointIndex: 42,
      label: 'Peak Sales',
      markerStyle: MarkerStyle.star(color: Colors.gold),
    ),
  ],
)
```

**Characteristics**:
- Can be at arbitrary positions
- Have labels, tooltips, and rich styling
- Render ABOVE the chart layer
- Support user interaction (drag, edit, tap)
- Managed independently from data
- Configured via `annotations` parameter

**Use Cases**:
- Mark significant events
- Highlight time periods
- Reference lines (thresholds)
- Trend analysis
- Free-text labels

---

## 5 Annotation Types

### 1. TextAnnotation
**Free-floating labels at arbitrary coordinates**

```dart
TextAnnotation(
  position: ChartPosition(x: DateTime(2024, 6, 1), y: 150000),
  text: 'Launch of Product X',
  markerStyle: MarkerStyle.pin(),
  allowDragging: true,
  allowEditing: true,
)
```

**Properties**:
- `position`: Any coordinate system (not tied to data points)
- `text`: Display text
- `markerStyle`: Optional visual marker
- `titleStyle`: Text container styling
- `allowDragging`: Enable repositioning
- `allowEditing`: In-place text editing
- `tooltipStyle`: Optional hover tooltip

**Use Cases**:
- Custom labels
- Commentary
- Free-form annotations

---

### 2. PointAnnotation
**Mark and annotate specific data points**

```dart
PointAnnotation(
  seriesId: 'AAPL',
  dataPointIndex: 25,
  label: 'Product Launch',
  markerStyle: MarkerStyle.flag(color: Colors.blue),
  snapBehavior: SnapBehavior.stickToPoint,
)
```

**Properties**:
- `seriesId`: Target data series
- `dataPointIndex`: Specific data point
- `label`: Annotation text
- `markerStyle`: Visual marker (required)
- `snapBehavior`: How to handle data updates
  - `stickToPoint`: Move with data point
  - `stickToCoordinate`: Stay at original coordinate
  - `smartSnap`: Snap to nearest point
- `visualOffset`: Offset from point
- `tooltipText`: Rich tooltip content

**Use Cases**:
- Mark peaks/troughs
- Significant events
- Data validation points
- Outliers

---

### 3. RangeAnnotation
**Highlight rectangular areas**

```dart
RangeAnnotation(
  axis: Axis.vertical,  // Time period
  start: DateTime(2020, 3, 1),
  end: DateTime(2020, 12, 31),
  label: 'COVID-19 Recession',
  style: RangeStyle.subtle(fillColor: Colors.red.withOpacity(0.1)),
  position: RangePosition.behind,  // Render behind chart
)
```

**Properties**:
- `axis`: Vertical (time range) or Horizontal (value range)
- `start`: Start value
- `end`: End value
- `label`: Annotation label
- `style`: Fill, border, opacity
- `position`: Behind or in-front of chart data
- `showBorders`: Top/bottom/left/right borders

**Use Cases**:
- Time periods (quarters, events)
- Value ranges (normal operating range)
- Confidence intervals
- Highlighted regions

---

### 4. ThresholdAnnotation
**Horizontal or vertical reference lines**

```dart
ThresholdAnnotation(
  axis: Axis.horizontal,
  value: 180.0,
  label: 'Price Target',
  style: ThresholdStyle.custom(
    lineColor: Colors.green,
    lineStyle: LineStyle.dashed,
    labelPosition: ThresholdLabelPosition.start,
  ),
)
```

**Properties**:
- `axis`: Horizontal (Y-axis value) or Vertical (X-axis value)
- `value`: Threshold value
- `label`: Label text
- `labelPosition`: Start, end, middle
- `style`: Line color, style (solid/dashed/dotted), width
- `showLabel`: Show/hide label

**Use Cases**:
- Target values
- Limits (min/max)
- Baselines
- Reference lines

---

### 5. TrendAnnotation
**Statistical overlays (regression, moving averages)**

```dart
// Linear regression
TrendAnnotation.linearRegression(
  seriesId: 'dataset1',
  label: 'Best Fit Line',
  showEquation: true,
  showRSquared: true,
)

// Moving average
TrendAnnotation.movingAverage(
  seriesId: 'AAPL',
  window: 50,
  label: '50-day MA',
  style: LineStyle.smooth(color: Colors.orange),
)
```

**Types**:
- `linearRegression`: y = mx + b
- `movingAverage`: N-day rolling average
- `polynomial`: Polynomial fit (degree 2-5)
- `exponential`: Exponential smoothing

**Properties**:
- `seriesId`: Source data series
- `type`: Regression type
- `window`: Window size (for moving average)
- `degree`: Polynomial degree
- `showEquation`: Display equation
- `showRSquared`: Display R² value
- `style`: Line styling

**Use Cases**:
- Trend analysis
- Smoothing
- Correlation
- Forecasting

---

## BravenChart Integration

### Properties

```dart
class BravenChart extends StatefulWidget {
  // ... other properties
  
  /// List of annotations to display on chart
  final List<ChartAnnotation> annotations;
  
  /// Whether annotations should be interactive
  final bool interactiveAnnotations;
  
  /// Annotation interaction callbacks
  final void Function(ChartAnnotation)? onAnnotationTap;
  final void Function(ChartAnnotation, Offset)? onAnnotationDragged;
  
  const BravenChart({
    // ... other parameters
    this.annotations = const [],
    this.interactiveAnnotations = true,
    this.onAnnotationTap,
    this.onAnnotationDragged,
  });
}
```

### Usage Patterns

#### Static Annotations
```dart
BravenChart(
  chartType: ChartType.line,
  series: data,
  annotations: [
    ThresholdAnnotation(axis: Axis.horizontal, value: 100),
    RangeAnnotation(axis: Axis.vertical, start: 0, end: 10),
  ],
)
```

#### Dynamic Annotations (via Controller)
```dart
final controller = ChartController();

BravenChart(
  chartType: ChartType.line,
  series: data,
  controller: controller,
)

// Add annotation dynamically
String annotationId = controller.addAnnotation(
  PointAnnotation(seriesId: 's1', dataPointIndex: 5, label: 'Peak'),
);

// Update annotation
controller.updateAnnotation(
  annotationId,
  PointAnnotation(seriesId: 's1', dataPointIndex: 5, label: 'Updated Peak'),
);

// Remove annotation
controller.removeAnnotation(annotationId);

// Clear all
controller.clearAnnotations();
```

#### Interactive Annotations
```dart
BravenChart(
  chartType: ChartType.line,
  series: data,
  annotations: [
    TextAnnotation(
      position: ChartPosition(x: 5, y: 100),
      text: 'Draggable Label',
      allowDragging: true,
      allowEditing: true,
    ),
  ],
  interactiveAnnotations: true,
  onAnnotationTap: (annotation) {
    print('Tapped: ${annotation.label}');
  },
  onAnnotationDragged: (annotation, newPosition) {
    print('Dragged to: $newPosition');
  },
)
```

---

## ChartController Annotation Methods

```dart
class ChartController {
  // ==================== ANNOTATION MANAGEMENT ====================
  
  /// Add annotation to chart
  /// Returns annotation ID for later reference
  String addAnnotation(ChartAnnotation annotation);
  
  /// Remove annotation by ID
  void removeAnnotation(String annotationId);
  
  /// Update annotation by ID
  void updateAnnotation(String annotationId, ChartAnnotation updatedAnnotation);
  
  /// Get annotation by ID
  ChartAnnotation? getAnnotation(String annotationId);
  
  /// Get all annotations
  List<ChartAnnotation> getAllAnnotations();
  
  /// Clear all annotations
  void clearAnnotations();
  
  /// Find annotations at position (for hit-testing)
  List<ChartAnnotation> findAnnotationsAt(Offset position, {double tolerance = 10.0});
}
```

---

## Rendering Architecture

### Layer Stack (Bottom to Top)

1. **Background Range Annotations** (`position: RangePosition.behind`)
2. **Chart Data** (lines, areas, bars, scatter points)
3. **Data Point Markers** (if enabled via `ChartConfig`)
4. **Foreground Annotations**:
   - Threshold lines
   - Trend lines
   - Range annotations (in-front)
   - Point annotations
   - Text annotations
5. **Interactive Overlays** (hover tooltips, selection indicators)

### Performance Optimizations

- **Viewport Culling**: Only render visible annotations
- **Object Pooling**: Reuse expensive rendering objects
- **Spatial Indexing**: Fast hit-testing for interactions
- **Batch Rendering**: Group similar annotation types
- **Lazy Evaluation**: Calculate expensive properties on-demand
- **Maximum 500 annotations** before performance warning

---

## Component Structure

```
lib/src/widgets/
├── annotations/
│   ├── annotation_base.dart          # Base ChartAnnotation class
│   ├── text_annotation.dart          # TextAnnotation
│   ├── point_annotation.dart         # PointAnnotation
│   ├── range_annotation.dart         # RangeAnnotation
│   ├── threshold_annotation.dart     # ThresholdAnnotation
│   ├── trend_annotation.dart         # TrendAnnotation
│   └── annotation_styles.dart        # MarkerStyle, TitleStyle, RangeStyle, etc.
```

---

## Testing Requirements

### Unit Tests
- Annotation creation and configuration
- ChartController annotation CRUD operations
- Hit-testing accuracy
- Viewport culling logic

### Widget Tests
- Annotation rendering
- Interactive dragging
- In-place editing
- Tap detection

### Integration Tests
- BravenChart with multiple annotation types
- Real-time data + annotations
- Annotation + zooming/panning
- Performance with 500+ annotations

### Golden Tests
- Visual regression for all 5 annotation types
- Multiple annotations on same chart
- Annotation + theme variations

---

## Dependencies

**Layer 5 (Chart Widgets) → Layer 7 (Annotation System)**:
- BravenChart passes `annotations` to underlying AnnotationLayer
- AnnotationLayer handles rendering and interaction logic
- Universal Marker System provides marker rendering
- Coordinate transformations handled by Layer 2

**Related Documents**:
- `ANNOTATION_SYSTEM_ARCHITECTURE.md` - Full annotation system design
- `UNIVERSAL_MARKER_SYSTEM.md` - Marker rendering specification
- `spec.md` - Layer 5 complete specification (FR-013)

---

## Migration from Layer 7

Users migrating from direct Layer 7 usage:

### Before (Layer 7 Direct)
```dart
AnnotationLayer(
  annotations: [/* ... */],
  onAnnotationTap: /* ... */,
)
```

### After (Layer 5 via BravenChart)
```dart
BravenChart(
  chartType: ChartType.line,
  series: data,
  annotations: [/* ... */],
  onAnnotationTap: /* ... */,
)
```

**Benefits**:
- Automatic resource management
- Integrated axis handling
- Theme consistency
- Simplified API

---

**Status**: Specification Complete  
**Next Steps**: Implement annotation classes and integrate into BravenChart rendering pipeline
