# Universal Coordinate Transformer - Critical Architecture Component

## Overview

The Universal Coordinate Transformer is a stateless, generic system for converting between any coordinate systems used in the BravenChart library. This solves the current problem where coordinate translations are implemented ad-hoc throughout the codebase, leading to inconsistencies, bugs, and maintenance overhead.

## Problem Statement

Currently, coordinate transformations are scattered throughout the codebase:

- Mouse events → screen coordinates → data coordinates
- Data coordinates → marker positions (with offsets)
- DataPoint indices → screen coordinates for hit detection
- Range annotations calculating area positions separately
- Tooltip positioning requiring manual coordinate adjustments

Each transformation is implemented independently, leading to:

- **Inconsistency**: Different components use different transformation logic
- **Bugs**: Coordinate mismatches between hit detection and visual positioning
- **Maintenance**: Changes require updates across multiple files
- **Complexity**: Developers must understand multiple coordinate systems

## Solution: Universal Coordinate Transformer

### Core Design Principles

1. **Stateless & Pure**: No internal state, all context passed explicitly
2. **Bidirectional**: Any coordinate system can transform to any other
3. **Contextual**: Transformations use proper context (chart bounds, series data, etc.)
4. **Extensible**: Easy to add new coordinate systems
5. **Validated**: Built-in validation for coordinate ranges and validity
6. **Performance**: Optimized for frequent transformations
7. **Type Safe**: Strong typing prevents coordinate system mismatches

## Coordinate Systems

### Primary Coordinate Systems

```dart
enum CoordinateSystem {
  /// Raw Flutter event coordinates (e.g., mouse position, touch events)
  /// Origin: Top-left of entire Flutter widget
  /// Range: 0,0 to widget.width,widget.height
  mouse,

  /// Screen pixel coordinates within the Flutter widget
  /// Origin: Top-left of widget
  /// Range: 0,0 to widget.width,widget.height
  screen,

  /// Coordinates within the chart drawing area (excluding axes, legends)
  /// Origin: Top-left of chart plot area
  /// Range: 0,0 to chartArea.width,chartArea.height
  chartArea,

  /// Logical data space coordinates (x=10.5, y=45.3)
  /// Origin: Data space origin (may be negative)
  /// Range: xAxis.min to xAxis.max, yAxis.min to yAxis.max
  data,

  /// Index-based references to specific series data points
  /// x = series index, y = data point index
  /// Range: 0 to series.length-1, 0 to series[x].data.length-1
  dataPoint,

  /// Visual marker positions (with annotation-specific offsets)
  /// For point annotations: offset upward by 50px
  /// For text annotations: at indicator circle
  /// For range annotations: at marker position with padding
  marker,

  /// Coordinates adjusted for zoom/pan transformations
  /// Applied after data→screen transformation
  /// Includes scale and translation effects
  viewport,

  /// Normalized coordinates (0.0-1.0) relative to chart bounds
  /// Origin: 0,0 = top-left of chart area
  /// Range: 0.0,0.0 to 1.0,1.0
  normalized,
}
```

### Coordinate System Relationships

```
Mouse Events
    ↓
Screen Coordinates
    ↓
Chart Area Coordinates ←→ Normalized Coordinates
    ↓                         ↑
Data Coordinates ←→ Viewport Coordinates
    ↓
DataPoint Coordinates
    ↓
Marker Coordinates
```

## Implementation Architecture

### Core Transformer Interface

```dart
abstract class CoordinateTransformer {
  /// Transform coordinates from one system to another
  Point<double> transform(
    Point<double> point,
    CoordinateSystem from,
    CoordinateSystem to,
    TransformContext context,
  );

  /// Batch transform multiple points for efficiency
  List<Point<double>> transformBatch(
    List<Point<double>> points,
    CoordinateSystem from,
    CoordinateSystem to,
    TransformContext context,
  );

  /// Check if transformation is valid
  bool canTransform(
    CoordinateSystem from,
    CoordinateSystem to,
    TransformContext context,
  );

  /// Get valid coordinate range for system
  Rectangle<double> getValidRange(
    CoordinateSystem system,
    TransformContext context,
  );
}
```

### Transform Context

```dart
class TransformContext {
  // Widget dimensions
  final Size widgetSize;
  
  // Chart area bounds
  final Rectangle<double> chartArea;
  
  // Data ranges
  final Range xDataRange;
  final Range yDataRange;
  
  // Viewport state (for zoom/pan)
  final ViewportState viewport;
  
  // Series data (for dataPoint transformations)
  final List<ChartSeries> series;
  
  // Animation state
  final double animationProgress;
  
  // Device pixel ratio for crisp rendering
  final double devicePixelRatio;
}
```

## Usage Examples

### Basic Transformations

```dart
// Mouse click → data coordinates
final transformer = UniversalCoordinateTransformer();
final context = TransformContext(/* ... chart context ... */);

final mousePoint = Point(150.0, 200.0);
final dataPoint = transformer.transform(
  mousePoint,
  CoordinateSystem.mouse,
  CoordinateSystem.data,
  context,
);

print('Clicked data point: (${dataPoint.x}, ${dataPoint.y})');
```

### Annotation Positioning

```dart
// Position point annotation marker above data point
final dataCoord = Point(10.5, 45.3);
final markerPosition = transformer.transform(
  dataCoord,
  CoordinateSystem.data,
  CoordinateSystem.marker,
  context.withMarkerOffset(Point(0, -50)), // 50px above
);
```

### Hit Testing

```dart
// Check if mouse click hits any data points
bool hitTestDataPoint(Point<double> mousePos, List<ChartSeries> series) {
  final dataPos = transformer.transform(
    mousePos,
    CoordinateSystem.mouse,
    CoordinateSystem.data,
    context,
  );
  
  for (final series in series) {
    for (final point in series.data) {
      final distance = point.distanceTo(dataPos);
      if (distance < hitTestTolerance) {
        return true;
      }
    }
  }
  return false;
}
```

## Performance Optimizations

### Transformation Caching

```dart
class CachedCoordinateTransformer extends CoordinateTransformer {
  final Map<String, TransformMatrix> _matrixCache = {};
  
  @override
  Point<double> transform(Point<double> point, /* ... */) {
    final cacheKey = _buildCacheKey(from, to, context);
    final matrix = _matrixCache[cacheKey] ??= _buildMatrix(from, to, context);
    return matrix.transform(point);
  }
}
```

### Batch Processing

```dart
// Efficient batch transformation for large datasets
final screenPoints = transformer.transformBatch(
  dataPoints,
  CoordinateSystem.data,
  CoordinateSystem.screen,
  context,
);
```

## Integration Points

### Chart Rendering

```dart
class ChartPainter extends CustomPainter {
  final CoordinateTransformer transformer;
  
  @override
  void paint(Canvas canvas, Size size) {
    final context = _buildTransformContext(size);
    
    // Transform all data points to screen coordinates
    for (final series in chartData.series) {
      final screenPoints = transformer.transformBatch(
        series.dataPoints,
        CoordinateSystem.data,
        CoordinateSystem.screen,
        context,
      );
      
      _drawSeries(canvas, screenPoints, series.style);
    }
  }
}
```

### Annotation System Integration

```dart
class AnnotationRenderer {
  void renderAnnotations(Canvas canvas, List<ChartAnnotation> annotations) {
    for (final annotation in annotations) {
      final screenPos = transformer.transform(
        annotation.position,
        annotation.coordinateSystem,
        CoordinateSystem.screen,
        context,
      );
      
      _renderAnnotation(canvas, annotation, screenPos);
    }
  }
}
```

## Validation & Error Handling

### Coordinate Validation

```dart
class CoordinateValidator {
  static ValidationResult validate(
    Point<double> point,
    CoordinateSystem system,
    TransformContext context,
  ) {
    final validRange = _getValidRange(system, context);
    
    if (!validRange.containsPoint(point)) {
      return ValidationResult.invalid(
        'Point $point outside valid range $validRange for $system'
      );
    }
    
    return ValidationResult.valid();
  }
}
```

This Universal Coordinate Transformer is absolutely critical for maintaining consistency and preventing coordinate-related bugs that plagued the previous implementation. It must be implemented from day one in the rewrite.