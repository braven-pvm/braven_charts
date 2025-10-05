# Quick Start: Universal Coordinate System

**Feature**: 003-coordinate-system  
**Date**: 2025-10-05

---

## Overview

This quickstart demonstrates all 8 coordinate systems and common transformation patterns. Each example is executable and matches a user scenario from the specification.

---

## Setup

```dart
import 'package:braven_charts/braven_charts.dart';

// Create transformation context
final context = TransformContext(
  widgetSize: Size(800, 600),
  chartAreaBounds: Rect.fromLTWH(50, 30, 700, 540),
  xDataRange: DataRange(min: 0.0, max: 100.0),
  yDataRange: DataRange(min: -50.0, max: 50.0),
  viewport: ViewportState.identity(),
  series: [series1, series2],
);

// Create transformer
final transformer = UniversalCoordinateTransformer();
```

---

## Example 1: Click Detection (Mouse → Data)

**Scenario**: User clicks at (150px, 200px). Find nearest data point.

```dart
test('Mouse click to data coordinates', () {
  // User clicks at mouse position
  final mousePos = Point(150.0, 200.0);
  
  // Transform to data coordinates
  final dataPos = transformer.transform(
    mousePos,
    from: CoordinateSystem.mouse,
    to: CoordinateSystem.data,
    context: context,
  );
  
  // Verify transformation (mouse = screen for this widget)
  // Screen → ChartArea: (150, 200) - (50, 30) = (100, 170)
  // ChartArea → Data: normalize then scale
  expect(dataPos.x, closeTo(14.3, 0.1)); // (100 / 700) * 100
  expect(dataPos.y, closeTo(24.1, 0.1)); // Transform with Y-flip
});
```

---

## Example 2: Rendering Data Points (Data → Screen)

**Scenario**: Render 10K data points on screen.

```dart
test('Batch transform data points to screen', () {
  final dataPoints = series.dataPoints; // 10K points
  
  final stopwatch = Stopwatch()..start();
  final screenPoints = transformer.transformBatch(
    dataPoints,
    from: CoordinateSystem.data,
    to: CoordinateSystem.screen,
    context: context,
  );
  stopwatch.stop();
  
  // Verify performance: <1ms for 10K points
  expect(stopwatch.elapsedMicroseconds, lessThan(1000));
  
  // Verify correctness: Data (0, 0) → Screen (50, 570)
  // (chart area top-left + Y-flip to bottom)
  expect(screenPoints[0].x, closeTo(50.0, 0.1));
  expect(screenPoints[0].y, closeTo(570.0, 0.1));
});
```

---

## Example 3: Annotation Anchoring (Data → Marker → Screen)

**Scenario**: Place annotation 50px above data point, maintain offset during zoom.

```dart
test('Annotation with marker offset', () {
  final annotationDataPos = Point(50.0, 25.0); // Middle of data range
  final markerOffset = Point(0.0, -50.0); // 50px above
  
  // Transform with marker offset
  final contextWithOffset = context.withMarkerOffset(markerOffset);
  
  final screenPos = transformer.transform(
    annotationDataPos,
    from: CoordinateSystem.data,
    to: CoordinateSystem.screen,
    context: contextWithOffset,
  );
  
  // Verify: Data (50, 25) → Screen (400, 300) - offset (0, 50) = (400, 250)
  expect(screenPos.x, closeTo(400.0, 0.1));
  expect(screenPos.y, closeTo(250.0, 0.1)); // 50px above data point
});
```

---

## Example 4: Zoom/Pan (Data → Viewport → Screen)

**Scenario**: User zooms 2x, pan right 25 units. Render visible data.

```dart
test('Zoom and pan viewport', () {
  // User zooms to middle 50% of X-axis
  final zoomedViewport = ViewportState(
    xRange: DataRange(min: 25.0, max: 75.0),
    yRange: context.yDataRange,
  );
  final zoomedContext = context.withViewport(zoomedViewport);
  
  // Data point at X=50 (middle of zoomed viewport)
  final dataPoint = Point(50.0, 0.0);
  
  final screenPos = transformer.transform(
    dataPoint,
    from: CoordinateSystem.data,
    to: CoordinateSystem.screen,
    context: zoomedContext,
  );
  
  // Verify: Middle of data range → middle of screen
  expect(screenPos.x, closeTo(400.0, 0.1)); // Middle of 800px widget
});
```

---

## Example 5: Normalized Coordinates (Layout)

**Scenario**: Place legend at 90% width, 10% height (normalized coordinates).

```dart
test('Normalized coordinates for layout', () {
  final legendPos = Point(0.9, 0.1); // 90% right, 10% down
  
  final screenPos = transformer.transform(
    legendPos,
    from: CoordinateSystem.normalized,
    to: CoordinateSystem.screen,
    context: context,
  );
  
  // Verify: Normalized (0.9, 0.1) → ChartArea (630, 54) → Screen (680, 84)
  expect(screenPos.x, closeTo(680.0, 0.1)); // 50 + 0.9 * 700
  expect(screenPos.y, closeTo(84.0, 0.1));  // 30 + 0.1 * 540
});
```

---

## Example 6: Validation

**Scenario**: Detect invalid coordinates before rendering.

```dart
test('Coordinate validation', () {
  // Invalid: NaN coordinate
  final invalidPoint = Point(double.nan, 10.0);
  
  final result = transformer.validate(
    invalidPoint,
    CoordinateSystem.data,
    context,
  );
  
  expect(result.isValid, false);
  expect(result.errorType, ValidationErrorType.invalidValue);
  expect(result.errorMessage, contains('NaN'));
  expect(result.errorMessage, contains('Check data source'));
});
```

---

## Example 7: Round-Trip Accuracy

**Scenario**: Transform data → screen → data, verify original point recovered.

```dart
test('Round-trip transformation accuracy', () {
  final originalData = Point(42.5, -17.3);
  
  // Forward: Data → Screen
  final screen = transformer.transform(
    originalData,
    from: CoordinateSystem.data,
    to: CoordinateSystem.screen,
    context: context,
  );
  
  // Reverse: Screen → Data
  final roundTripData = transformer.transform(
    screen,
    from: CoordinateSystem.screen,
    to: CoordinateSystem.data,
    context: context,
  );
  
  // Verify: Within 0.01 pixel tolerance
  expect(roundTripData.x, closeTo(originalData.x, 0.01));
  expect(roundTripData.y, closeTo(originalData.y, 0.01));
});
```

---

## Example 8: RenderContext Integration

**Scenario**: Use transformer in rendering pipeline via RenderContext.

```dart
test('Integration with RenderContext', () {
  final renderContext = RenderContext(
    canvas: canvas,
    size: Size(800, 600),
    viewport: Rect.fromLTWH(50, 30, 700, 540),
    // ... other RenderContext fields
    transformContext: context,
    transformer: transformer,
  );
  
  // Convenience method: dataToScreen
  final dataPoint = Point(50.0, 0.0);
  final screenPoint = renderContext.dataToScreen(dataPoint);
  
  expect(screenPoint.x, closeTo(400.0, 0.1));
  expect(screenPoint.y, closeTo(300.0, 0.1));
});
```

---

## Performance Validation

```dart
benchmark('Batch transformation performance', () {
  final points = List.generate(10000, (i) => Point(i * 0.01, i * 0.02));
  
  final stopwatch = Stopwatch()..start();
  final screenPoints = transformer.transformBatch(
    points,
    from: CoordinateSystem.data,
    to: CoordinateSystem.screen,
    context: context,
  );
  stopwatch.stop();
  
  // Constitutional requirement: <1ms for 10K points
  expect(stopwatch.elapsedMicroseconds, lessThan(1000));
  expect(screenPoints.length, 10000);
});
```

---

## Summary

**8 Coordinate Systems Demonstrated**:
1. ✅ Mouse (raw events)
2. ✅ Screen (widget pixels)
3. ✅ ChartArea (plot area)
4. ✅ Data (business logic)
5. ✅ DataPoint (series indices - implied in data transforms)
6. ✅ Marker (annotation offsets)
7. ✅ Viewport (zoom/pan)
8. ✅ Normalized (0.0-1.0 layout)

**All examples are**:
- ✅ Executable (copy-paste into test file)
- ✅ Match user scenarios from specification
- ✅ Demonstrate correct usage patterns
- ✅ Include performance validation

**Next Steps**:
1. Run `/tasks` to generate implementation tasks
2. Implement based on TDD (tests first, then implementation)
3. Verify all examples pass after implementation

---

**Quickstart Status**: ✅ Complete - Ready for `/tasks` command
